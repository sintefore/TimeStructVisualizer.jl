function _draw(ts::SimpleTimes, bbox = BoundingBox(), dur = nothing)
    len = length(ts)

    w = boxwidth(bbox)
    h = boxheight(bbox)

    if isnothing(dur)
        dur = duration(ts)
    end

    # Draw a line across the middle of the boxwidth
    setcolor(Luxor.julia_red)
    mid = midpoint(bbox)
    l = line(Point(bbox[1].x, mid.y),
            Point(bbox[1].x + w * duration(ts) / dur, mid.y), :stroke)
    

    # Add circles at intervals relative to duration
    setcolor(Luxor.julia_blue)
    r = min(5, h / 20, 0.2 * w / len)
    duracc = 0
    for (i,t) in enumerate(ts)
        println(duracc, " ", dur)
        circle(Point(bbox[1].x + r + (w - 2*r) * duracc / dur, mid.y), r, :fill)
        duracc += duration(t)
    end
end

function _draw(ts::OperationalScenarios, bbox = BoundingBox() )

    n = length(ts.scenarios)
    h = boxheight(bbox)
    w = boxwidth(bbox)
    sbox = BoundingBox(bbox[1] + (50,0), Point(bbox[2].x, bbox[1].y + h /n ))

    for (i, sc) in enumerate(ts.scenarios)
        # Translated bounding box
        tbox = sbox + (0, (i-1) * h / n)
        # Draw a line to the midpoint of the smaller BoundingBox
        setdash("dash")
        setcolor(Luxor.julia_red)
        line(boxmiddleleft(bbox), boxmiddleleft(tbox), :stroke)
        setdash("solid")
    
        _draw(sc, tbox, duration(ts))
    end
end

function _draw(ts::TwoLevel, bbox = BoundingBox() )

    n = length(ts.operational)
    h = boxheight(bbox)
    w = boxwidth(bbox)
    
    sbox = BoundingBox(bbox[1]+(40,0), Point(bbox[1].x + w / n, bbox[2].y))
    for (i, sp) in enumerate(ts.operational)
        tbox = sbox + ((i-1) * w / n, 0)
        bm = boxmiddleleft(tbox) 
        setcolor(Luxor.julia_green)
        box(bm + (-15,0), 15, 15, action=:fill)
        line(bm + (-15,0), bm, :stroke)
        _draw(sp, tbox)
    end
end

function _draw(ts::TwoLevelTree, bbox = BoundingBox())
    #TODO
end


function draw(ts::TimeStructure)
    Drawing(600, 400,:svg)
    origin()
    _draw(ts)
    finish()
    preview()
end
