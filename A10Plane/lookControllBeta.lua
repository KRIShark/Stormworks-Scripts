-- Tilt sensors
local tilt_F = 0 -- Pitch
local tilt_L = 0 -- Roll

-- Mouse inputs
local look_X = 0 -- Roll control: Left(-) / Right(+)
local look_Y = 0 -- Pitch control: Down(-) / Up(+)

-- Current roll, pitch, and user input values
local currentRoll = 0
local currentPitch = 0
local userInputRoll = 0
local userInputPitch = 0

-- Control sensitivity, stabilization, and max roll settings
local mouseSensitivity = property.getNumber("mouseSensitivity")
local stabilizationMultiplier = property.getNumber("stabilizationMultiplier")
local maxRollAngle = property.getNumber("maxRollAngle") -- Maximum roll angle in degrees
local rollCorrectionSpeed = property.getNumber("rollCorrectionSpeed") -- Speed of roll correction

-- Flag for overroll warning
local isOverrolled = false

function onTick()
    -- Read tilt sensor and mouse input values
    tilt_F = input.getNumber(1)
    tilt_L = input.getNumber(2)
    look_X = input.getNumber(3)
    look_Y = input.getNumber(4)
    
    -- Interpret mouse inputs as 0 if within the threshold
    if math.abs(look_X) < 0.02 then look_X = 0 end
    if math.abs(look_Y) < 0.02 then look_Y = 0 end

    -- Store user input for visualization
    userInputRoll = look_X
    userInputPitch = look_Y

    -- Calculate stabilization adjustments
    local stabilRoll = -tilt_L * stabilizationMultiplier
    local stabilPitch = tilt_F * stabilizationMultiplier

    -- Apply stabilization and user input
    currentRoll = stabilRoll + look_X * mouseSensitivity
    currentPitch = stabilPitch + look_Y * mouseSensitivity

    -- Check for overroll and apply correction if necessary
    isOverrolled = false
    if currentRoll > maxRollAngle then
        currentRoll = currentRoll - rollCorrectionSpeed
        isOverrolled = true
    elseif currentRoll < -maxRollAngle then
        currentRoll = currentRoll + rollCorrectionSpeed
        isOverrolled = true
    end

    -- Ensure correction does not exceed limits and goes in the correct direction
    if currentRoll > maxRollAngle then
        currentRoll = maxRollAngle
    elseif currentRoll < -maxRollAngle then
        currentRoll = -maxRollAngle
    end

    -- Apply roll and pitch adjustments
    SetRollPitch(currentRoll, currentPitch)
end

-- Set Roll and Pitch function
function SetRollPitch(roll, pitch)
    output.setNumber(1, roll)
    output.setNumber(2, pitch)
end

-- Visualization on Monitor (as provided earlier)

-- Visualization on Monitor
function onDraw()
    local width = screen.getWidth()
    local height = screen.getHeight()

    -- Draw horizontal and vertical lines
    screen.setColor(255, 255, 255) -- White color
    screen.drawLine(width / 2, 0, width / 2, height) -- Vertical line
    screen.drawLine(0, height / 2, width, height / 2) -- Horizontal line

    -- Draw red dot for current course (always in the middle)
    screen.setColor(255, 0, 0) -- Red color
    screen.drawCircleF(width / 2, height / 2, 1) -- Small filled circle for current course

    -- Draw blue circle for user input course change
    if userInputRoll ~= 0 or userInputPitch ~= 0 then
        local blueDotX = width / 2 + userInputRoll * 50 -- Relative position based on input
        local blueDotY = height / 2 + userInputPitch * 50
        screen.setColor(0, 0, 255) -- Blue color
        screen.drawCircle(blueDotX, blueDotY, 5) -- Circle for user input direction
    end

    -- Display overroll warning
    if isOverrolled then
        screen.setColor(255, 0, 0) -- Red color for warning
        screen.drawText(width / 2 - 50, 20, "OVERROLL WARNING")
    end
end