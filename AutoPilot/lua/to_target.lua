--==============================================================
-- NAV / AUTOPILOT CONTROL COMPUTER
-- No display logic in this controller
--==============================================================

--==============================================================
-- TUNING
--==============================================================

ARRIVAL_RADIUS = 25
SLOWDOWN_DISTANCE = 500

STEERING_GAIN = 4.5
STEERING_SMOOTHING = 0.18

CRUISE_THROTTLE = 1.0
APPROACH_THROTTLE = 0.25

HEADING_DEADZONE = 1.0

-- If heading runs backwards, change this to -1
COMPASS_SIGN = 1

-- If steering itself runs backwards, change this to -1
STEERING_SIGN = 1


--==============================================================
-- MEMORY
--==============================================================

smoothSteering = 0


--==============================================================
-- FUNCTIONS
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


function wrapTurns(v)

    return (v + 0.5) % 1 - 0.5

end


function wrapDegrees(v)

    return (v % 360 + 360) % 360

end


--==============================================================
-- MAIN LOGIC
--==============================================================

function onTick()

    ------------------------------------------------------------
    -- INPUTS
    ------------------------------------------------------------

    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)

    targetX = input.getNumber(3)
    targetY = input.getNumber(4)

    compass = input.getNumber(5) * COMPASS_SIGN

    speed = input.getNumber(6)

    manualSteering = input.getNumber(7)
    manualThrottle = input.getNumber(8)

    apRequested = input.getBool(1)
    emergencyCancel = input.getBool(2)


    ------------------------------------------------------------
    -- TARGET VECTOR
    ------------------------------------------------------------

    deltaX = targetX - gpsX
    deltaY = targetY - gpsY


    ------------------------------------------------------------
    -- DISTANCE
    ------------------------------------------------------------

    distance =
        math.sqrt(
            deltaX * deltaX +
            deltaY * deltaY
        )


    ------------------------------------------------------------
    -- TARGET BEARING
    ------------------------------------------------------------

    bearingRad =
        math.atan(
            deltaX,
            deltaY
        )

    bearingDeg =
        wrapDegrees(
            math.deg(bearingRad)
        )


    ------------------------------------------------------------
    -- CURRENT HEADING
    ------------------------------------------------------------

    headingTurns = compass

    headingDeg =
        wrapDegrees(
            headingTurns * 360
        )


    ------------------------------------------------------------
    -- HEADING ERROR
    ------------------------------------------------------------

    targetTurns =
        bearingDeg / 360

    headingErrorTurns =
        wrapTurns(
            targetTurns -
            headingTurns
        )

    headingErrorDeg =
        headingErrorTurns * 360


    ------------------------------------------------------------
    -- NAVIGATION STATES
    ------------------------------------------------------------

    targetReached =
        distance <= ARRIVAL_RADIUS

    arriving =
        distance <= SLOWDOWN_DISTANCE
        and not targetReached

    autopilotActive =
        apRequested
        and not emergencyCancel
        and not targetReached


    ------------------------------------------------------------
    -- STEERING
    ------------------------------------------------------------

    wantedSteering =
        headingErrorTurns *
        STEERING_GAIN

    wantedSteering =
        clamp(
            wantedSteering,
            -1,
            1
        )


    -- heading deadzone

    if math.abs(headingErrorDeg) < HEADING_DEADZONE then

        wantedSteering = 0

    end


    wantedSteering =
        wantedSteering *
        STEERING_SIGN


    ------------------------------------------------------------
    -- STEERING SMOOTHING
    ------------------------------------------------------------

    smoothSteering =
        smoothSteering +
        (
            wantedSteering -
            smoothSteering
        )
        *
        STEERING_SMOOTHING


    ------------------------------------------------------------
    -- AUTOMATIC THROTTLE
    ------------------------------------------------------------

    if targetReached then

        autoThrottle = 0

    elseif distance >= SLOWDOWN_DISTANCE then

        autoThrottle =
            CRUISE_THROTTLE

    else

        ratio =
            distance /
            SLOWDOWN_DISTANCE

        autoThrottle =
            APPROACH_THROTTLE +
            (
                CRUISE_THROTTLE -
                APPROACH_THROTTLE
            )
            *
            ratio

    end


    autoThrottle =
        clamp(
            autoThrottle,
            0,
            1
        )


    ------------------------------------------------------------
    -- AUTO / MANUAL SELECTION
    ------------------------------------------------------------

    if autopilotActive then

        steeringOut =
            smoothSteering

        throttleOut =
            autoThrottle

    else

        steeringOut =
            manualSteering

        throttleOut =
            manualThrottle

    end


    ------------------------------------------------------------
    -- CONTROL OUTPUTS
    ------------------------------------------------------------

    output.setNumber(
        1,
        steeringOut
    )

    output.setNumber(
        2,
        throttleOut
    )


    ------------------------------------------------------------
    -- NAV DATA COMPOSITE
    ------------------------------------------------------------

    output.setNumber(3, gpsX)
    output.setNumber(4, gpsY)

    output.setNumber(5, targetX)
    output.setNumber(6, targetY)

    output.setNumber(7, headingDeg)
    output.setNumber(8, bearingDeg)

    output.setNumber(9, distance)

    output.setNumber(
        10,
        headingErrorDeg
    )

    output.setNumber(
        11,
        speed
    )

    output.setNumber(
        12,
        steeringOut
    )

    output.setNumber(
        13,
        throttleOut
    )

    output.setNumber(
        14,
        deltaX
    )

    output.setNumber(
        15,
        deltaY
    )


    ------------------------------------------------------------
    -- BOOLEAN OUTPUTS
    ------------------------------------------------------------

    output.setBool(
        1,
        targetReached
    )

    output.setBool(
        2,
        autopilotActive
    )

    output.setBool(
        3,
        arriving
    )

    output.setBool(
        4,
        emergencyCancel
    )

end