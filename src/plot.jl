
strat_profile(profile, i) = profile
strat_profile(profile::StrategicProfile, i) = profile.vals[i]

rep_profile(profile, i) = profile
rep_profile(profile::RepresentativeProfile, i) = profile.vals[i]

scen_profile(profile, i) = profile
scen_profile(profile::ScenarioProfile, i) = profile.vals[i]



function _draw(ts::SimpleTimes, bbox = BoundingBox(), dur = nothing;
    showdur = false,  showprob = false, profile = nothing, layout = :middle)

    len = length(ts)

    w = boxwidth(bbox)
    h = boxheight(bbox)

    if isnothing(dur)
        dur = TimeStruct._total_duration(ts)
    end

    if layout == :middle
        start = boxmiddleleft(bbox)
    elseif layout == :top
        start = boxtopleft(bbox) + (0,h/2)
    end

    # Draw a line across the box according to total duration
    setcolor(Luxor.julia_red)
    line(start, start + (w * TimeStruct._total_duration(ts) / dur, 0), :stroke)

    if layout == :top
        setdash("dash")
        setcolor(Luxor.julia_red)
        line(boxtopleft(bbox), start, :stroke)
        setdash("solid")
    end

    # Add circles at intervals relative to duration
    r = max(3, min(5, h / 10, 0.2 * w / len))
    duracc = 0
    for t in ts
        #period.op = t.op
        setcolor(Luxor.julia_blue)
        center = start + (r + (w - 2*r) * duracc / dur, 0)
        circle(center, r, :fill)
        duracc += duration(t)

        if showdur
            sethue("black")
            text("$(duration(t))", center + (3*r,-r) , halign=:center,   valign = :bottom)
        end

        if !isnothing(profile)
            sethue("blue")
            text("$(round(profile[t], digits=1))", center + (3*r,r) , halign=:center,   valign = :top)
        end

    end
end

function _draw(ts::RepresentativePeriods, bbox = BoundingBox();
    showdur = false, showprob = false, profile = nothing, layout = :middle)

    n = length(ts.rep_periods)
    w = boxwidth(bbox)
    rbox = BoundingBox(bbox[1] + (20,0), Point(bbox[1].x + w / n, bbox[2].y ))
    for (i, rp) in enumerate(ts.rep_periods)
         # Translated and scaled bounding box
         tbox = rbox + ((i-1) * w / n, 0)
         setdash("dot")
         setgrey(0.7)
         box(tbox*1.05, :stroke)
         setdash("solid")
         _draw(rp, tbox; showdur = showdur, profile = rep_profile(profile, i), layout = layout)
    end

end

function _draw(ts::OperationalScenarios, bbox = BoundingBox();
    showdur = false,  showprob = false, profile = nothing, layout = :middle)

    n = length(ts.scenarios)
    h = boxheight(bbox)
    sbox = BoundingBox(bbox[1] + (50,0), Point(bbox[2].x, bbox[1].y + h /n ))

    for (i, sc) in enumerate(ts.scenarios)
        # Translated bounding box
        tbox = sbox + (0, (i-1) * h / n)

        # Draw a line to the midpoint of the smaller BoundingBox
        setdash("dash")
        setcolor(Luxor.julia_red)
        pt2 = boxmiddleleft(tbox)
        if layout == :middle
            pt1 =boxmiddleleft(bbox)
        elseif layout == :top
            pt1 =boxtopleft(bbox)
        else
            error("Unknown layout for operational scenarios")
        end
        line(pt1, pt2, :stroke)
        if showprob
            text("$(round(ts.probability[i],digits=3))", midpoint(pt1,pt2) + (5,0), halign=:left,   valign = :bottom)
        end

        setdash("solid")
        _draw(sc, tbox, TimeStruct._total_duration(ts); showdur = showdur, profile = scen_profile(profile, i), layout = :middle)
    end
end

function _draw(ts::TwoLevel, bbox = BoundingBox();
    showdur = false, showprob = false, profile = nothing, layout = :middle)

    padding = 20

    n = length(ts.operational)
    w = boxwidth(bbox)-2*padding

    topleft = boxtopleft(bbox) + (padding, padding)
    bottomright = boxbottomleft(bbox) + (padding + w/n, -padding)
    tbox = BoundingBox(topleft, bottomright)
    for (i, sp) in enumerate(ts.operational)
        # Bounding box for strategic level
        setcolor(Luxor.julia_green)
        if layout == :middle

            bm = boxmiddleleft(tbox)
            box(bm, 15, 15, action=:fill)
            line(bm, bm  + (15,0), :stroke)
            subbox = BoundingBox(boxtopleft(tbox + (15,0)), boxbottomright(tbox) + (-padding,0))
            if showdur
                line(boxbottomleft(tbox), boxbottomright(tbox), :stroke)
                line(boxbottomleft(tbox), boxbottomleft(tbox) + (0,-10), :stroke)
                sethue("black")
                text("$(ts.duration[i])", midpoint(boxbottomleft(tbox), boxbottomright(tbox)) + (0,-5) , halign=:center,   valign = :bottom)
            end
        elseif layout == :top
            # Top band for strategic periods with operation time structures below
            top_h = 40
            # Bounding box to hold operational time structure
            subbox = BoundingBox(tbox[1] + (0,top_h), tbox[2] + (-padding,0))
            # Box at top + line
            pt1 = boxtopleft(subbox) + (0, -top_h / 4)
            box(pt1 , top_h / 2, top_h /2, action=:fill)
            pt1 = boxtopleft(subbox) + (0,-top_h/4)
            pt2 = pt1 + (w / n , 0)
            line(pt1, pt2, :stroke)
            if showdur
                sethue("black")
                text("$(ts.duration[i])", midpoint(pt1 + (0,-5), pt2 + (0,-5)), halign=:center,   valign = :bottom)
            end
        else
            error("Unknown layout")
        end
        _draw(sp, subbox; showdur = showdur, showprob = showprob, profile = strat_profile(profile, i), layout = layout)
        tbox = tbox + (w / n, 0)
    end
end

function _draw(ts::TwoLevelTree, bbox = BoundingBox();
    showdur = false, showprob = false, profile = nothing, layout = :middle)

    padding = 20

    n = ts.len
    w = boxwidth(bbox)-2*padding
    h = (boxheight(bbox) - 2 * padding) / length(TimeStruct.leaves(ts))
    topleft = boxtopleft(bbox) + (padding, padding)
    bottomright = boxbottomleft(bbox) + (padding + w/n, -padding)
    tbox = BoundingBox(topleft, bottomright)
    anchor = Dict()

    for sp in 1:n
        nodes = [n for n in ts.nodes if TimeStruct._strat_per(n) == sp]
        brs = length(nodes)

        if layout == :middle
            hsub = boxheight(tbox)/(brs+1)
            bm = boxtopleft(tbox) + (0, hsub)
            for (br,n) in enumerate(nodes)
                setcolor(Luxor.julia_green)
                box(bm, 15, 15, action=:fill)
                line(bm, bm  + (15,0), :stroke)
                subbox = BoundingBox(bm + (15,0) + (0,-h/2), bm + (boxwidth(tbox),h/2) + (-padding, 0))
                _draw(n.strat_node.operational, subbox; showdur = showdur, showprob = showprob, profile = profile, layout = layout)
                bm = bm + (0, hsub)
            end
            if showdur
                setcolor(Luxor.julia_green)
                line(boxbottomleft(tbox), boxbottomright(tbox), :stroke)
                line(boxbottomleft(tbox), boxbottomleft(tbox) + (0,-10), :stroke)
                sethue("black")
                text("todo", midpoint(boxbottomleft(tbox), boxbottomright(tbox)) + (0,-5) , halign=:center,   valign = :bottom)
            end
        elseif layout == :top
            bm = boxtopleft(tbox)
            offset = - 12
            prev_parent = ts.root
            for (br,node) in enumerate(nodes)
                setcolor(Luxor.julia_green)
                box(bm, 15, 15, action=:fill)
                if showprob
                    sethue(Luxor.julia_green)
                    text("$(round(probability(node),digits=3))", bm + (20, -5), halign=:left,   valign = :bottom)
                end

                line(bm, bm  + (w / n, 0), :stroke)
                anchor[node] = bm  + (w / n + offset, 0)
                if sp > 1 && br > 1 && node.parent == prev_parent
                    line(bm + (offset,0), bm, :stroke)
                    line(bm + (offset,0), anchor[node.parent], :stroke)
                end
                subbox = BoundingBox(bm + (0,7.5), bm + (boxwidth(tbox),h) + (-padding, 0))
                _draw(node.operational, subbox; showdur = showdur, showprob = showprob, profile = profile, layout = layout)

                prev_parent = node.parent
                bm = bm + (0, h * max(1,TimeStruct.nchildren(node, ts)))
            end
        end
        tbox = tbox + (w / n, 0)
    end

end


function draw(ts::TimeStructure; filename = nothing, showdur = false, showprob = false, profile = nothing,
    layout = :middle, width=800, height= 600)

    if isnothing(filename)
        Drawing(width, height, :svg)
    else
        Drawing(width, height, filename)
    end

    background("white")
    origin()
    _draw(ts; showdur = showdur, showprob = showprob, profile = profile, layout = layout)
    finish()
    preview()
end
