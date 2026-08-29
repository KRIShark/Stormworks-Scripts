--==============================================================
-- NAVIGATION DISPLAY COMPUTER
-- Dynamic Stormworks monitor display
--
-- INPUT:
-- Combined NAV DATA + monitor touch composite
--
-- OUTPUT:
-- Video
--==============================================================


--==============================================================
-- SETTINGS
--==============================================================

DEFAULT_RANGE = 2000

rangeOptions = {
    250,
    500,
    1000,
    2000,
    5000,
    10000,
    20000
}

rangeIndex = 4

page = 1

lastTouch = false


--==============================================================
-- HELPERS
--==============================================================

function clamp(v, minV, maxV)

    if v < minV then
        return minV
    end

    if v > maxV then
        return maxV
    end

    return v
end


function inside(px, py, x, y, w, h)

    return
        px >= x and
        px <= x + w and
        py >= y and
        py <= y + h

end


function formatDistance(d)

    if d >= 10000 then

        return
            string.format(
                "%.0fK",
                d / 1000
            )

    elseif d >= 1000 then

        return
            string.format(
                "%.1fK",
                d / 1000
            )

    else

        return
            string.format(
                "%.0f",
                d
            )

    end

end


--==============================================================
-- INPUT
--==============================================================

function onTick()

    ------------------------------------------------------------
    -- NAVIGATION COMPOSITE
    ------------------------------------------------------------

    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)

    targetX = input.getNumber(3)
    targetY = input.getNumber(4)

    heading = input.getNumber(5)
    bearing = input.getNumber(6)

    distance = input.getNumber(7)

    headingError =
        input.getNumber(8)

    speed =
        input.getNumber(9)

    steering =
        input.getNumber(10)

    throttle =
        input.getNumber(11)

    deltaX =
        input.getNumber(12)

    deltaY =
        input.getNumber(13)


    ------------------------------------------------------------
    -- NAVIGATION BOOL DATA
    ------------------------------------------------------------

    apActive =
        input.getBool(1)

    targetReached =
        input.getBool(2)

    arriving =
        input.getBool(3)

    emergency =
        input.getBool(4)


    ------------------------------------------------------------
    -- MONITOR TOUCH
    ------------------------------------------------------------

    monitorWidth =
        input.getNumber(21)

    monitorHeight =
        input.getNumber(22)

    touchX =
        input.getNumber(23)

    touchY =
        input.getNumber(24)

    touch =
        input.getBool(21)


    ------------------------------------------------------------
    -- TOUCH EDGE
    ------------------------------------------------------------

    newTouch =
        touch and
        not lastTouch


    ------------------------------------------------------------
    -- TOUCH CONTROLS
    ------------------------------------------------------------

    if newTouch then

        -- These regions are calculated again
        -- using monitor dimensions.

        buttonHeight =
            math.max(
                10,
                monitorHeight * 0.12
            )

        buttonY =
            monitorHeight -
            buttonHeight


        --------------------------------------------------------
        -- RANGE DOWN
        --------------------------------------------------------

        if inside(
            touchX,
            touchY,
            0,
            buttonY,
            monitorWidth * 0.25,
            buttonHeight
        )
        then

            rangeIndex =
                math.max(
                    1,
                    rangeIndex - 1
                )

        end


        --------------------------------------------------------
        -- PAGE
        --------------------------------------------------------

        if inside(
            touchX,
            touchY,
            monitorWidth * 0.375,
            buttonY,
            monitorWidth * 0.25,
            buttonHeight
        )
        then

            page = page + 1

            if page > 2 then

                page = 1

            end

        end


        --------------------------------------------------------
        -- RANGE UP
        --------------------------------------------------------

        if inside(
            touchX,
            touchY,
            monitorWidth * 0.75,
            buttonY,
            monitorWidth * 0.25,
            buttonHeight
        )
        then

            rangeIndex =
                math.min(
                    #rangeOptions,
                    rangeIndex + 1
                )

        end

    end


    lastTouch = touch


    displayRange =
        rangeOptions[
            rangeIndex
        ]

end


--==============================================================
-- AIRCRAFT SYMBOL
--==============================================================

function drawAircraft(cx, cy, scale)

    screen.drawLine(
        cx - 8 * scale,
        cy,
        cx - 2 * scale,
        cy
    )

    screen.drawLine(
        cx + 2 * scale,
        cy,
        cx + 8 * scale,
        cy
    )

    screen.drawLine(
        cx,
        cy - 4 * scale,
        cx,
        cy + 6 * scale
    )

    screen.drawLine(
        cx - 3 * scale,
        cy + 5 * scale,
        cx + 3 * scale,
        cy + 5 * scale
    )

end


--==============================================================
-- WAYPOINT SYMBOL
--==============================================================

function drawWaypoint(x, y, scale)

    r =
        4 * scale

    screen.drawCircle(
        x,
        y,
        r
    )

    screen.drawLine(
        x - r - 2,
        y,
        x + r + 2,
        y
    )

    screen.drawLine(
        x,
        y - r - 2,
        x,
        y + r + 2
    )

end


--==============================================================
-- COMPASS ARC
--==============================================================

function drawCompass(w, h)

    cx = w / 2

    tapeHeight =
        math.max(
            12,
            h * 0.14
        )


    ------------------------------------------------------------
    -- BLACK STRIP
    ------------------------------------------------------------

    screen.setColor(
        3,
        8,
        12
    )

    screen.drawRectF(
        0,
        0,
        w,
        tapeHeight
    )


    ------------------------------------------------------------
    -- SCALE
    ------------------------------------------------------------

    pixelsPerDegree =
        w / 90


    for offset = -50, 50, 10 do

        x =
            cx +
            offset *
            pixelsPerDegree

        if x >= 0 and x <= w then

            value =
                (
                    heading +
                    offset
                )
                %
                360

            screen.setColor(
                220,
                230,
                230
            )

            screen.drawLine(
                x,
                tapeHeight - 4,
                x,
                tapeHeight
            )

            label =
                string.format(
                    "%02d",
                    math.floor(
                        value / 10
                    )
                )

            screen.drawText(
                x - 5,
                2,
                label
            )

        end

    end


    ------------------------------------------------------------
    -- CURRENT HEADING POINTER
    ------------------------------------------------------------

    screen.setColor(
        255,
        255,
        255
    )

    screen.drawTriangleF(
        cx,
        tapeHeight,
        cx - 3,
        tapeHeight - 5,
        cx + 3,
        tapeHeight - 5
    )


    ------------------------------------------------------------
    -- CURRENT HEADING NUMBER
    ------------------------------------------------------------

    headingText =
        string.format(
            "%03.0f",
            heading
        )

    screen.setColor(
        0,
        255,
        255
    )

    screen.drawTextBox(
        cx - 15,
        tapeHeight + 1,
        30,
        7,
        headingText,
        0,
        0
    )

end


--==============================================================
-- NAVIGATION DISPLAY
--==============================================================

function drawNav(w, h)

    cx = w / 2

    top =
        math.max(
            18,
            h * 0.18
        )

    bottomBar =
        math.max(
            12,
            h * 0.13
        )

    usableHeight =
        h -
        top -
        bottomBar

    cy =
        top +
        usableHeight * 0.55


    ------------------------------------------------------------
    -- SCALE
    ------------------------------------------------------------

    mapRadius =
        math.min(
            w * 0.42,
            usableHeight * 0.45
        )

    pixelsPerMeter =
        mapRadius /
        displayRange


    ------------------------------------------------------------
    -- RANGE RINGS
    ------------------------------------------------------------

    screen.setColor(
        50,
        70,
        75
    )

    screen.drawCircle(
        cx,
        cy,
        mapRadius
    )

    screen.drawCircle(
        cx,
        cy,
        mapRadius * 0.5
    )


    ------------------------------------------------------------
    -- ROTATE TARGET RELATIVE TO HEADING
    ------------------------------------------------------------

    angle =
        math.rad(
            heading
        )

    localX =
        deltaX *
        math.cos(angle)
        -
        deltaY *
        math.sin(angle)

    localY =
        deltaX *
        math.sin(angle)
        +
        deltaY *
        math.cos(angle)


    waypointX =
        cx +
        localX *
        pixelsPerMeter

    waypointY =
        cy -
        localY *
        pixelsPerMeter


    ------------------------------------------------------------
    -- LIMIT OFF-SCREEN WAYPOINT
    ------------------------------------------------------------

    dxScreen =
        waypointX - cx

    dyScreen =
        waypointY - cy

    screenDistance =
        math.sqrt(
            dxScreen * dxScreen +
            dyScreen * dyScreen
        )


    if screenDistance > mapRadius then

        factor =
            mapRadius /
            screenDistance

        waypointX =
            cx +
            dxScreen *
            factor

        waypointY =
            cy +
            dyScreen *
            factor

    end


    ------------------------------------------------------------
    -- ROUTE LINE
    ------------------------------------------------------------

    screen.setColor(
        255,
        0,
        255
    )

    screen.drawLine(
        cx,
        cy,
        waypointX,
        waypointY
    )


    ------------------------------------------------------------
    -- WAYPOINT
    ------------------------------------------------------------

    scale =
        math.max(
            0.7,
            math.min(
                w,
                h
            )
            /
            96
        )

    screen.setColor(
        255,
        0,
        255
    )

    drawWaypoint(
        waypointX,
        waypointY,
        scale
    )


    ------------------------------------------------------------
    -- AIRCRAFT
    ------------------------------------------------------------

    screen.setColor(
        255,
        255,
        0
    )

    drawAircraft(
        cx,
        cy,
        scale
    )


    ------------------------------------------------------------
    -- RANGE LABEL
    ------------------------------------------------------------

    screen.setColor(
        0,
        255,
        255
    )

    screen.drawText(
        2,
        top + 2,
        formatDistance(
            displayRange
        )
    )


    ------------------------------------------------------------
    -- AP STATUS
    ------------------------------------------------------------

    if emergency then

        screen.setColor(
            255,
            120,
            0
        )

        status =
            "EMERG"

    elseif targetReached then

        screen.setColor(
            0,
            255,
            0
        )

        status =
            "WPT"

    elseif apActive then

        screen.setColor(
            0,
            255,
            0
        )

        status =
            "AP"

    else

        screen.setColor(
            255,
            180,
            0
        )

        status =
            "MAN"

    end

    screen.drawText(
        2,
        2,
        status
    )


    ------------------------------------------------------------
    -- BEARING
    ------------------------------------------------------------

    screen.setColor(
        0,
        255,
        255
    )

    screen.drawText(
        w - 24,
        top + 2,
        string.format(
            "%03.0f",
            bearing
        )
    )


    ------------------------------------------------------------
    -- DATA
    ------------------------------------------------------------

    screen.setColor(
        220,
        230,
        230
    )

    screen.drawText(
        2,
        h - bottomBar + 1,
        "DST"
    )

    screen.setColor(
        0,
        255,
        255
    )

    screen.drawText(
        2,
        h - bottomBar + 7,
        formatDistance(
            distance
        )
    )


    screen.setColor(
        220,
        230,
        230
    )

    screen.drawTextBox(
        w * 0.35,
        h - bottomBar + 1,
        w * 0.3,
        6,
        "SPD",
        0,
        0
    )

    screen.setColor(
        0,
        255,
        0
    )

    screen.drawTextBox(
        w * 0.35,
        h - bottomBar + 7,
        w * 0.3,
        6,
        string.format(
            "%.1f",
            speed
        ),
        0,
        0
    )


    screen.setColor(
        220,
        230,
        230
    )

    screen.drawText(
        w - 25,
        h - bottomBar + 1,
        "ERR"
    )

    screen.setColor(
        0,
        255,
        255
    )

    screen.drawText(
        w - 25,
        h - bottomBar + 7,
        string.format(
            "%+.0f",
            headingError
        )
    )


    ------------------------------------------------------------
    -- COMPASS
    ------------------------------------------------------------

    drawCompass(
        w,
        h
    )

end


--==============================================================
-- DATA PAGE
--==============================================================

function drawData(w, h)

    screen.setColor(
        0,
        255,
        255
    )

    screen.drawTextBox(
        0,
        2,
        w,
        7,
        "NAV DATA",
        0,
        0
    )


    screen.setColor(
        220,
        230,
        230
    )

    screen.drawText(
        3,
        14,
        "HDG"
    )

    screen.drawText(
        3,
        22,
        "BRG"
    )

    screen.drawText(
        3,
        30,
        "DST"
    )

    screen.drawText(
        3,
        38,
        "SPD"
    )

    screen.drawText(
        3,
        46,
        "STR"
    )


    screen.setColor(
        0,
        255,
        255
    )

    valueX =
        w * 0.45

    screen.drawText(
        valueX,
        14,
        string.format(
            "%03.0f",
            heading
        )
    )

    screen.drawText(
        valueX,
        22,
        string.format(
            "%03.0f",
            bearing
        )
    )

    screen.drawText(
        valueX,
        30,
        formatDistance(
            distance
        )
    )

    screen.drawText(
        valueX,
        38,
        string.format(
            "%.1f",
            speed
        )
    )

    screen.drawText(
        valueX,
        46,
        string.format(
            "%+.2f",
            steering
        )
    )

end


--==============================================================
-- TOUCH BAR
--==============================================================

function drawTouchBar(w, h)

    buttonHeight =
        math.max(
            10,
            h * 0.12
        )

    y =
        h -
        buttonHeight


    screen.setColor(
        3,
        8,
        12
    )

    screen.drawRectF(
        0,
        y,
        w,
        buttonHeight
    )


    screen.setColor(
        0,
        255,
        255
    )


    screen.drawTextBox(
        0,
        y,
        w * 0.25,
        buttonHeight,
        "RNG-",
        0,
        0
    )


    screen.drawTextBox(
        w * 0.375,
        y,
        w * 0.25,
        buttonHeight,
        page == 1
            and "DATA"
            or "NAV",
        0,
        0
    )


    screen.drawTextBox(
        w * 0.75,
        y,
        w * 0.25,
        buttonHeight,
        "RNG+",
        0,
        0
    )

end


--==============================================================
-- DRAW
--==============================================================

function onDraw()

    w =
        screen.getWidth()

    h =
        screen.getHeight()


    ------------------------------------------------------------
    -- BACKGROUND
    ------------------------------------------------------------

    screen.setColor(
        0,
        0,
        0
    )

    screen.drawClear()


    ------------------------------------------------------------
    -- PAGE
    ------------------------------------------------------------

    if page == 1 then

        drawNav(
            w,
            h
        )

    else

        drawData(
            w,
            h
        )

    end


    ------------------------------------------------------------
    -- TOUCH CONTROLS
    ------------------------------------------------------------

    drawTouchBar(
        w,
        h
    )

end