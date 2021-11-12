
struct TimeStructPlot <: TimeStruct.TimeStructure end
mutable struct PlotPeriod <: TimeStruct.TimePeriod{TimeStructPlot}
    op
    sp
    sc
    branch
end
TimeStruct.strat_per(p::PlotPeriod) = p.sp
TimeStruct.opscen(p::PlotPeriod) = p.sc
TimeStruct.branch(p::PlotPeriod) = p.branch

PlotPeriod() = PlotPeriod(1,1,1,1)

function _draw(ts::SimpleTimes, bbox = BoundingBox(), period = PlotPeriod(), dur = nothing; 
    showdur = false, profile = nothing, layout = :middle)

    len = length(ts)

    w = boxwidth(bbox)
    h = boxheight(bbox)

    if isnothing(dur)
        dur = duration(ts)
    end

    if layout == :middle
        start = boxmiddleleft(bbox) 
    elseif layout == :top
        start = boxtopleft(bbox) + (0,40)
    end

    # Draw a line across the box according to total duration
    setcolor(Luxor.julia_red)
    l = line(start, start + (w * duration(ts) / dur,0), :stroke)

    if layout == :top
        setdash("dash")
        setcolor(Luxor.julia_red)
        line(boxtopleft(bbox), start, :stroke)
        setdash("solid")
    end

    # Add circles at intervals relative to duration
    r = min(5, h / 20, 0.2 * w / len)
    duracc = 0
    for (i,t) in enumerate(ts)

        period.op = t.op
        setcolor(Luxor.julia_blue)
        center = start + (r + (w - 2*r) * duracc / dur, 0)
        circle(center, r, :fill)
        duracc += duration(t)

        if showdur
            sethue("white")
            text("$(duration(t))", center + (3*r,-r) , halign=:center,   valign = :bottom)
        end
         
        if !isnothing(profile)
            sethue("yellow")
            text("$(profile[period])", center + (3*r,r) , halign=:center,   valign = :top)
        end

    end
end

function _draw(ts::OperationalScenarios, bbox = BoundingBox(), period = PlotPeriod(); 
    showdur = false, profile = nothing, layout = :middle)

    n = length(ts.scenarios)
    h = boxheight(bbox)
    w = boxwidth(bbox)
    sbox = BoundingBox(bbox[1] + (50,0), Point(bbox[2].x, bbox[1].y + h /n ))

    for (i, sc) in enumerate(ts.scenarios)
        period.sc = i
        # Translated bounding box
        tbox = sbox + (0, (i-1) * h / n)
        # Draw a line to the midpoint of the smaller BoundingBox
        setdash("dash")
        setcolor(Luxor.julia_red)
        if layout == :middle
            line(boxmiddleleft(bbox), boxmiddleleft(tbox), :stroke)
        elseif layout == :top
            line(boxtopleft(bbox), boxmiddleleft(tbox), :stroke)
        else
            error("Unknown layout for operational scenarios")
        end
        setdash("solid")
    
        _draw(sc, tbox, period, duration(ts); showdur = showdur, profile = profile, layout = :middle)
    end
end

function _draw(ts::TwoLevel, bbox = BoundingBox(), period = PlotPeriod(); 
    showdur = false, profile = nothing, layout = :middle)

    n = length(ts.operational)
    h = boxheight(bbox)
    w = boxwidth(bbox)
    
    sbox = BoundingBox(bbox[1]+(40,40), Point(bbox[1].x + w / n, bbox[2].y))
    for (i, sp) in enumerate(ts.operational)
        period.sp = i
        tbox = sbox + ((i-1) * w / n, 0)
        setcolor(Luxor.julia_green)
        if layout == :middle
            bm = boxmiddleleft(tbox)
            box(bm + (-15,0), 15, 15, action=:fill)
            line(bm + (-15,0), bm, :stroke)
            if showdur
                l = line(boxbottomleft(tbox), boxbottomright(tbox), :stroke)
                sethue("white")
                text("$(ts.duration[i])", midpoint(boxbottomleft(tbox), boxbottomright(tbox)) + (0,-5) , halign=:center,   valign = :bottom)
            end
        elseif layout == :top
            offset = (0,-10)
            bm = boxtopleft(tbox) + offset
            box(bm , 15, 15, action=:fill)
            pt1 = boxtopleft(tbox) + offset
            pt2 = boxtopright(tbox) + offset + (40,0) 
            line(pt1, pt2, :stroke)
            if showdur
                sethue("white")
                text("$(ts.duration[i])", midpoint(pt1 + (0,-5),pt2 + (0,-5)) , halign=:center,   valign = :bottom)
            end
        else
            error("Unknown layout")
        end
        
        _draw(sp, tbox, period; showdur = showdur, profile = profile, layout = layout)
    end
end

function _draw(ts::TwoLevelTree, bbox = BoundingBox())
    #TODO
end


function draw(ts::TimeStructure; showdur = false, profile = nothing, layout = :middle)
    Drawing(600, 400, :svg)
    origin()
    _draw(ts; showdur = showdur, profile = profile, layout = layout)
    finish()
    preview()
end
