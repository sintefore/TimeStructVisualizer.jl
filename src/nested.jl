
# Nested layout, where each level of the time structure is drawn as blocks inside
# the block of its parent, similar to icicle (partition) diagrams for hierarchies.
# Time runs from left to right with widths proportional to duration, heights of
# operational scenarios are proportional to their probability, and the strategic
# tree is drawn with each node spanning the rows of the leaves below it. Profile
# values are shown as colors, as in heat maps of time series, which keeps the
# drawing readable for structures with many periods.

as_color(c::Colorant) = c
as_color(c::Tuple) = RGB(c...)
as_color(c) = parse(Colorant, c)

# Black or white, whichever is more readable on `background`
contrast_color(background) =
    Lab(as_color(background)).l > 55 ? colorant"black" : colorant"white"

function value_color(value, opt)
    lo, hi = opt.value_range
    f = hi > lo ? (value - lo) / (hi - lo) : 0.5
    c_lo, c_hi = Lab.(as_color.(opt.style.value_colors))
    return weighted_color_mean(f, c_hi, c_lo)
end

header_height(s::DrawStyle) = s.fontsize + 2 * s.label_offset

# Split a block into a header with a label and the area below it for the content
function split_header(bbox, s::DrawStyle)
    h = header_height(s)
    header = BoundingBox(boxtopleft(bbox), boxtopright(bbox) + (0, h))
    return header, inset(bbox, top = h + s.band_gap)
end

function filled_box(bbox, color)
    sethue(as_color(color))
    box(bbox, :fill)
end

# Write the first of the `candidates` that fits inside `bbox` at its center, or
# nothing if none fits
function fitted_label(bbox, s::DrawStyle, color, candidates...)
    boxheight(bbox) < s.fontsize && return
    for str in string.(candidates)
        if textextents(str)[3] + 2 * s.label_offset <= boxwidth(bbox)
            label(str, boxmiddlecenter(bbox), color, valign = :middle)
            return
        end
    end
end

# Block with a header in `color` labelled with the first fitting candidate,
# returning the area for the content
function header_block(bbox, s::DrawStyle, color, candidates...)
    header, content = split_header(bbox, s)
    filled_box(header, color)
    fitted_label(header, s, contrast_color(color), candidates...)
    return content
end

# Gradient from the lowest to the highest profile value, centered in `bbox`
function color_legend(bbox, opt)
    s = opt.style
    lo, hi = opt.value_range
    bar = BoundingBox(
        boxmiddlecenter(bbox) + (-s.legend_width / 2, -s.fontsize / 2),
        boxmiddlecenter(bbox) + (s.legend_width / 2, s.fontsize / 2),
    )
    nsteps = max(1, round(Int, s.legend_width))
    for (i, cell) in enumerate(split_columns(bar, nsteps))
        filled_box(cell, value_color(lo + (hi - lo) * (i - 1) / max(1, nsteps - 1), opt))
    end
    label(display_val(lo), boxmiddleleft(bar) + (-s.label_offset, 0), s.label_color,
        halign = :right, valign = :middle)
    label(display_val(hi), boxmiddleright(bar) + (s.label_offset, 0), s.label_color,
        halign = :left, valign = :middle)
end

# Operational periods as cells, where `scale` is the drawing length per unit of
# duration. Cells show the profile value, or the duration if requested.
function _nested(ts::SimpleTimes, bbox, profile, opt,
    scale = boxwidth(bbox) / TimeStruct._total_duration(ts))
    s = opt.style
    x = boxtopleft(bbox).x
    for t in ts
        len = duration(t) * scale
        # Only separate cells that are wide enough to be read individually, so
        # that many narrow cells are not washed out by the separators. Unseparated
        # cells overlap by half a pixel to hide anti-aliasing seams between them.
        sep = len >= s.fontsize ? s.cell_separator / 2 : -0.25
        cell = BoundingBox(Point(x + sep, boxtopleft(bbox).y), Point(x + len - sep, boxbottomleft(bbox).y))
        x += len

        color = isnothing(profile) ? s.cell_color : value_color(profile[t], opt)
        filled_box(cell, color)
        if !isnothing(profile)
            fitted_label(cell, s, contrast_color(color), display_val(profile[t]))
        elseif opt.showdur
            fitted_label(cell, s, contrast_color(color), duration(t))
        end
    end
end

# Scenarios below each other with heights proportional to their probability, all
# with the same time scale so that their durations can be compared
function _nested(ts::OperationalScenarios, bbox, profile, opt)
    s = opt.style
    probs = ts.probability[1:ts.len]
    content = bbox
    if opt.showprob
        gutter = maximum(textextents(format_prob(p))[3] for p in probs) + 2 * s.label_offset
        content = inset(bbox, left = gutter)
    end
    scale = boxwidth(content) / TimeStruct._total_duration(ts)
    for (i, row) in enumerate(split_rows(content, probs, s.band_gap))
        _nested(ts.scenarios[i], row, scen_profile(profile, i), opt, scale)
        if opt.showprob && boxheight(row) >= s.fontsize
            label(format_prob(probs[i]), boxmiddleleft(row) + (-s.label_offset, 0),
                timeline_color(s), halign = :right, valign = :middle)
        end
    end
end

# Representative periods side by side with widths proportional to the share of
# the duration they represent
function _nested(ts::RepresentativePeriods, bbox, profile, opt)
    s = opt.style
    shares = ts.period_share[1:ts.len]
    for (i, col) in enumerate(split_columns(bbox, shares, s.band_gap))
        name = "rp$i"
        content = header_block(col, s, s.frame_color,
            opt.showprob ? "$name · $(format_prob(shares[i]))" : name, name, i)
        _nested(ts.rep_periods[i], content, rep_profile(profile, i), opt)
    end
end

# Strategic periods side by side with widths proportional to their duration
function _nested(ts::TwoLevel, bbox, profile, opt)
    s = opt.style
    durations = ts.duration[1:ts.len]
    for (i, col) in enumerate(split_columns(bbox, durations, s.band_gap))
        name = "sp$i"
        content = header_block(col, s, strategic_color(s),
            opt.showdur ? "$name · $(durations[i])" : name, name, i)
        _nested(ts.operational[i], content, strat_profile(profile, i), opt)
    end
end

# Scenario tree with the stages as columns, where each node spans the rows of the
# leaves below it and is connected to its parent through the gap between columns
function _nested(ts::TwoLevelTree, bbox, profile, opt)
    s = opt.style
    rows, nleaves = tree_rows(ts)
    total_leaves = sum(nleaves[node] for node in ts.nodes if isnothing(node.parent))
    stage_nodes = [[n for n in ts.nodes if TimeStruct._strat_per(n) == sp] for sp = 1:ts.len]
    stages = split_columns(bbox, [duration_strat(first(nodes)) for nodes in stage_nodes], s.gap)
    h = boxheight(bbox) / total_leaves

    for (sp, nodes) in enumerate(stage_nodes), node in nodes
        col = stages[sp]
        top = boxtopleft(col).y + rows[node] * h
        block = BoundingBox(
            Point(boxtopleft(col).x, top),
            Point(boxtopright(col).x, top + nleaves[node] * h - s.band_gap),
        )
        name = "sp$sp-$(TimeStruct._branch(node))"
        content = header_block(block, s, strategic_color(s),
            opt.showprob ? "$name · $(format_prob(probability_branch(node)))" : name, name)
        _nested(node.operational, content, node_profile(profile, node), opt)

        if !isnothing(node.parent)
            y = top + header_height(s) / 2
            sethue(as_color(strategic_color(s)))
            line(Point(boxtopright(stages[sp-1]).x, y), Point(boxtopleft(col).x, y), :stroke)
        end
    end
end
