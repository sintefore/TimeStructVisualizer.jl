
# As in TimeStruct, the last value is reused if the profile has fewer values than periods
strat_profile(profile, i) = profile
strat_profile(profile::StrategicProfile, i) = profile.vals[min(i, end)]

node_profile(profile, node) = strat_profile(profile, TimeStruct._strat_per(node))
function node_profile(profile::StrategicStochasticProfile, node)
    sp_vals = profile.vals[min(TimeStruct._strat_per(node), end)]
    return sp_vals[min(TimeStruct._branch(node), end)]
end

rep_profile(profile, i) = profile
rep_profile(profile::RepresentativeProfile, i) = profile.vals[min(i, end)]

scen_profile(profile, i) = profile
scen_profile(profile::ScenarioProfile, i) = profile.vals[min(i, end)]

# Row (in units of leaf heights) for each node in a strategic tree, where each
# node is placed on the same row as its first child, and the number of leaves
# below each node
function tree_rows(ts::TwoLevelTree)
    children = Dict(node => [c for c in ts.nodes if c.parent == node] for node in ts.nodes)
    nleaves = Dict{Any,Int}()
    count_leaves(node) = get!(nleaves, node) do
        isempty(children[node]) ? 1 : sum(count_leaves, children[node])
    end
    rows = Dict{Any,Int}()
    function place(node, row)
        rows[node] = row
        for c in children[node]
            place(c, row)
            row += count_leaves(c)
        end
    end
    row = 0
    for node in ts.nodes
        if isnothing(node.parent)
            place(node, row)
            row += count_leaves(node)
        end
    end
    return rows, nleaves
end

display_val(value) = value
display_val(value::AbstractFloat) = round(value, digits = 1)

format_prob(p) = string(round(p, digits = 3))

default_palette() = [Luxor.julia_red, Luxor.julia_green, Luxor.julia_blue]

"""
    DrawStyle(; kwargs...)

Visual settings used by [`draw`](@ref). All lengths are in drawing units (pixels).

Keyword arguments:
- `palette`: colors for, in order, operational time lines, strategic periods and
  the markers/values of operational periods.
- `label_color`: color of duration labels.
- `frame_color`: color of the frames around representative periods.
- `fontsize`: font size of all labels.
- `margin`: space between the edge of the drawing and the time structure.
- `gap`: horizontal space between adjacent strategic or representative periods.
- `label_offset`: distance between a line or marker and its label.
- `frame_padding`: space between a representative period frame and its content.
- `marker_radius`: largest radius of the markers at the start of each operational period.
- `node_size`: side length of the squares marking strategic periods and nodes.
- `branch_length`: horizontal length of the branches leading to each operational scenario.
- `tick`: length of the ticks at the end of time lines and duration axes.

Only used by the `:nested` layout:
- `cell_color`: color of operational periods when no profile is given.
- `value_colors`: colors for the lowest and highest profile value.
- `cell_separator`: width of the white line between operational periods.
- `band_gap`: space between nested blocks, such as scenarios and representative periods.
- `legend_width`: width of the color legend for profile values.
"""
Base.@kwdef struct DrawStyle
    palette::Vector = default_palette()
    label_color = colorant"black"
    frame_color = colorant"gray70"
    fontsize::Float64 = 10
    margin::Float64 = 20
    gap::Float64 = 20
    label_offset::Float64 = 4
    frame_padding::Float64 = 8
    marker_radius::Float64 = 4
    node_size::Float64 = 14
    branch_length::Float64 = 50
    tick::Float64 = 6
    cell_color = colorant"gray85"
    value_colors = (colorant"#deebf7", colorant"#08519c")
    cell_separator::Float64 = 1
    band_gap::Float64 = 3
    legend_width::Float64 = 200
end

timeline_color(s::DrawStyle) = s.palette[1]
strategic_color(s::DrawStyle) = s.palette[2]
period_color(s::DrawStyle) = s.palette[3]

# Height needed for a label placed above or below a line
label_height(s::DrawStyle) = s.label_offset + s.fontsize

# Options shared by all levels of the time structure
struct DrawOptions
    showdur::Bool
    showprob::Bool
    layout::Symbol
    style::DrawStyle
    # Lowest and highest profile value, used for the colors in the :nested layout
    value_range::Union{Nothing,Tuple}
end

# Layout helpers

function inset(bbox; left = 0, top = 0, right = 0, bottom = 0)
    return BoundingBox(
        boxtopleft(bbox) + (left, top),
        boxbottomright(bbox) + (-right, -bottom),
    )
end

# Split `len` into parts proportional to `weights` separated by `gap`, returning
# the start and size of each part
function split_length(len, weights, gap)
    sizes = max(0, len - (length(weights) - 1) * gap) .* weights ./ sum(weights)
    starts = cumsum([0; sizes[1:end-1] .+ gap])
    return zip(starts, sizes)
end

# Split `bbox` into columns with widths proportional to `weights` (or `n` columns
# of equal width) separated by `gap`
function split_columns(bbox, weights::AbstractVector, gap = 0)
    tl = boxtopleft(bbox)
    return [
        BoundingBox(tl + (x, 0), tl + (x + w, boxheight(bbox))) for
        (x, w) in split_length(boxwidth(bbox), weights, gap)
    ]
end
split_columns(bbox, n::Integer, gap = 0) = split_columns(bbox, ones(n), gap)

# Split `bbox` into rows with heights proportional to `weights` (or `n` rows of
# equal height) separated by `gap`
function split_rows(bbox, weights::AbstractVector, gap = 0)
    tl = boxtopleft(bbox)
    return [
        BoundingBox(tl + (0, y), tl + (boxwidth(bbox), y + h)) for
        (y, h) in split_length(boxheight(bbox), weights, gap)
    ]
end
split_rows(bbox, n::Integer, gap = 0) = split_rows(bbox, ones(n), gap)

# Point where the parent structure connects to the content of `bbox`
entry_point(bbox, opt) = opt.layout == :top ? boxtopleft(bbox) : boxmiddleleft(bbox)

# Drawing primitives

function label(str, pt, color; halign = :center, valign = :bottom)
    sethue(color)
    text(string(str), pt, halign = halign, valign = valign)
end

function dashed_line(p1, p2, color)
    sethue(color)
    setdash("dash")
    line(p1, p2, :stroke)
    setdash("solid")
end

function strategic_node(center, s::DrawStyle)
    sethue(strategic_color(s))
    box(center, s.node_size, s.node_size, action = :fill)
end

# Horizontal axis along the bottom of `bbox` labelled with the duration
function duration_axis(bbox, dur, s::DrawStyle)
    left, right = boxbottomleft(bbox), boxbottomright(bbox)
    sethue(strategic_color(s))
    line(left, right, :stroke)
    line(left, left + (0, -s.tick), :stroke)
    label(dur, midpoint(left, right) + (0, -s.label_offset), s.label_color)
end

# Operational periods as a time line from `start`, where `scale` is the drawing
# length per unit of duration. Durations are shown above and profile values below
# the middle of each period.
function draw_timeline(ts::SimpleTimes, start, scale, profile, opt)
    s = opt.style
    total = TimeStruct._total_duration(ts) * scale
    stop = start + (total, 0)

    sethue(timeline_color(s))
    line(start, stop, :stroke)
    line(stop + (0, -s.tick / 2), stop + (0, s.tick / 2), :stroke)

    # Shrink markers when there are many periods so that they stay separated
    r = min(s.marker_radius, total / (4 * length(ts)))
    x = 0.0
    for t in ts
        len = duration(t) * scale
        sethue(period_color(s))
        circle(start + (x, 0), r, :fill)
        mid = start + (x + len / 2, 0)
        if opt.showdur
            label(duration(t), mid + (0, -s.label_offset), s.label_color)
        end
        if !isnothing(profile)
            label(
                display_val(profile[t]),
                mid + (0, s.label_offset),
                period_color(s),
                valign = :top,
            )
        end
        x += len
    end
end

function _draw(ts::SimpleTimes, bbox, profile, opt)
    start = boxmiddleleft(bbox)
    entry = entry_point(bbox, opt)
    if entry != start
        dashed_line(entry, start, timeline_color(opt.style))
    end
    draw_timeline(ts, start, boxwidth(bbox) / TimeStruct._total_duration(ts), profile, opt)
end

# Scenarios are drawn below each other, branching off a dashed vertical line
# with the probability shown on each branch
function _draw(ts::OperationalScenarios, bbox, profile, opt)
    s = opt.style
    entry = entry_point(bbox, opt)
    timelines = inset(bbox, left = s.branch_length)
    # Same scale for all scenarios so that their durations can be compared
    scale = boxwidth(timelines) / TimeStruct._total_duration(ts)

    starts = [boxmiddleleft(row) for row in split_rows(timelines, ts.len)]
    trunk_top = Point(entry.x, min(entry.y, first(starts).y))
    trunk_bottom = Point(entry.x, max(entry.y, last(starts).y))
    dashed_line(trunk_top, trunk_bottom, timeline_color(s))

    for (i, start) in enumerate(starts)
        branch = Point(entry.x, start.y)
        dashed_line(branch, start, timeline_color(s))
        if opt.showprob
            label(
                format_prob(ts.probability[i]),
                midpoint(branch, start) + (0, -s.label_offset),
                timeline_color(s),
            )
        end
        draw_timeline(ts.scenarios[i], start, scale, scen_profile(profile, i), opt)
    end
end

# Representative periods are drawn side by side in dotted frames, with the share
# of the duration they represent in the upper right corner
function _draw(ts::RepresentativePeriods, bbox, profile, opt)
    s = opt.style
    p = s.frame_padding
    for (i, frame) in enumerate(split_columns(bbox, ts.len, s.gap))
        sethue(s.frame_color)
        setdash("dot")
        box(frame, :stroke)
        setdash("solid")
        if opt.showprob
            label(
                "share $(format_prob(ts.period_share[i]))",
                boxtopright(frame) + (-p, p),
                s.frame_color,
                halign = :right,
                valign = :top,
            )
        end
        # In the :top layout, the content connects to the top edge of the frame
        top = opt.layout == :top ? 0 : p
        content = inset(frame, left = p, top = top, right = p, bottom = p)
        _draw(ts.rep_periods[i], content, rep_profile(profile, i), opt)
    end
end

function _draw(ts::TwoLevel, bbox, profile, opt)
    s = opt.style
    # Strategic periods take up contiguous columns, with a gap to the right of
    # the operational time structure in each column
    for (i, col) in enumerate(split_columns(bbox, ts.len))
        sp_profile = strat_profile(profile, i)
        if opt.layout == :middle
            # Node to the left, optionally with a duration axis at the bottom
            axis = opt.showdur ? label_height(s) + s.label_offset : 0
            content = inset(col, left = s.node_size, right = s.gap, bottom = axis)
            node = boxmiddleleft(inset(col, bottom = axis))
            _draw(ts.operational[i], content, sp_profile, opt)
            sethue(strategic_color(s))
            line(node, boxmiddleleft(content), :stroke)
            strategic_node(node, s)
            opt.showdur && duration_axis(col, ts.duration[i], s)
        else
            # Strategic periods as a line along the top with the operational
            # time structures hanging below
            node = boxtopleft(col) + (0, max(s.node_size / 2, label_height(s)))
            content = BoundingBox(node, boxbottomright(col) + (-s.gap, 0))
            _draw(ts.operational[i], content, sp_profile, opt)
            sethue(strategic_color(s))
            line(node, Point(boxtopright(col).x, node.y), :stroke)
            strategic_node(node, s)
            if opt.showdur
                label(
                    ts.duration[i],
                    Point(boxtopcenter(col).x, node.y - s.label_offset),
                    s.label_color,
                )
            end
        end
    end
end

function _draw(ts::TwoLevelTree, bbox, profile, opt)
    s = opt.style
    node_rows, _ = tree_rows(ts)
    nleaves = maximum(values(node_rows)) + 1

    for (sp, col) in enumerate(split_columns(bbox, ts.len))
        nodes = [node for node in ts.nodes if TimeStruct._strat_per(node) == sp]

        if opt.layout == :middle
            # Nodes spread evenly over the height, with the operational time
            # structure of each node getting the height of one leaf
            axis = opt.showdur ? label_height(s) + s.label_offset : 0
            area = inset(col, bottom = axis)
            h = boxheight(area) / nleaves
            for (node, row) in zip(nodes, split_rows(area, length(nodes)))
                center = boxmiddleleft(row)
                content = BoundingBox(
                    center + (s.node_size, -h / 2),
                    Point(boxtopright(col).x - s.gap, center.y + h / 2),
                )
                _draw(node.operational, content, node_profile(profile, node), opt)
                sethue(strategic_color(s))
                line(center, boxmiddleleft(content), :stroke)
                strategic_node(center, s)
            end
            if opt.showdur
                duration_axis(col, join(unique(duration_strat.(nodes)), "/"), s)
            end
        else
            # Each node gets one row for each leaf below it and is connected to
            # its parent through the gap between the columns
            top = max(s.node_size / 2, label_height(s))
            h = (boxheight(col) - top) / nleaves
            row_y(node) = boxtopleft(col).y + top + h * node_rows[node]
            for node in nodes
                center = Point(boxtopleft(col).x, row_y(node))
                content =
                    BoundingBox(center, Point(boxtopright(col).x - s.gap, center.y + h))
                _draw(node.operational, content, node_profile(profile, node), opt)

                sethue(strategic_color(s))
                line(center, Point(boxtopright(col).x, center.y), :stroke)
                if !isnothing(node.parent) && node_rows[node] != node_rows[node.parent]
                    elbow = center + (-s.gap / 2, 0)
                    line(Point(elbow.x, row_y(node.parent)), elbow, :stroke)
                    line(elbow, center, :stroke)
                end
                strategic_node(center, s)

                if opt.showprob
                    label(
                        format_prob(probability_branch(node)),
                        center + (s.node_size / 2 + s.label_offset, -s.label_offset),
                        strategic_color(s),
                        halign = :left,
                    )
                end
                if opt.showdur
                    label(
                        duration_strat(node),
                        Point(boxtopcenter(col).x, center.y - s.label_offset),
                        s.label_color,
                    )
                end
            end
        end
    end
end

"""
    draw(ts::TimeStructure; kwargs...)

Draw the time structure `ts`. The drawing is shown with `preview()` and also
saved to `filename` if given.

Keyword arguments:
- `layout`: `:middle` connects each level at the middle of the level below it,
  `:top` shows strategic periods along the top with the rest hanging below.
  `:nested` draws each level as blocks nested inside its parent, with widths
  proportional to duration and scenario heights proportional to probability,
  which works better for large and complex time structures.
- `showdur`: show the duration of operational and strategic periods.
- `showprob`: show probabilities of scenarios and strategic nodes, and the
  share of representative periods.
- `profile`: a `TimeProfile` whose values are shown below each operational period,
  or as colors in the `:nested` layout.
- `width`, `height`: size of the drawing.
- `palette`: colors for operational time lines, strategic periods and operational periods.
- `style`: a [`DrawStyle`](@ref) with all visual settings, overrides `palette`.
"""
function draw(
    ts::TimeStructure;
    filename = nothing,
    showdur = false,
    showprob = false,
    profile = nothing,
    layout = :middle,
    width = 800,
    height = 600,
    palette = default_palette(),
    style = DrawStyle(palette = palette),
)

    if layout ∉ (:middle, :top, :nested)
        throw(ArgumentError("Unknown layout :$layout, must be :middle, :top or :nested"))
    end

    if isnothing(filename)
        Drawing(width, height, :svg)
    else
        Drawing(width, height, filename)
    end

    render(ts, width, height; showdur, showprob, profile, layout, style)
    finish()
    preview()
end

# Draw `ts` on the current drawing, which has the origin at the center
function render(ts, width, height; showdur, showprob, profile, layout, style)
    background("white")
    origin()
    fontsize(style.fontsize)
    m = style.margin
    bbox = BoundingBox(
        Point(-width / 2 + m, -height / 2 + m),
        Point(width / 2 - m, height / 2 - m),
    )
    if layout == :nested
        value_range = isnothing(profile) ? nothing : extrema(profile[t] for t in ts)
        opt = DrawOptions(showdur, showprob, layout, style, value_range)
        if !isnothing(value_range)
            legend = inset(bbox, top = boxheight(bbox) - style.fontsize)
            color_legend(legend, opt)
            bbox = inset(bbox, bottom = style.fontsize + style.gap)
        end
        _nested(ts, bbox, profile, opt)
    else
        _draw(ts, bbox, profile, DrawOptions(showdur, showprob, layout, style, nothing))
    end
end
