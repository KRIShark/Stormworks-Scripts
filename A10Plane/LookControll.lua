-- https://chat.openai.com/c/5e6c4975-ae86-424f-a8c9-32673f1b59ef

roll = 0
pitch = 0

function onTick()
    local tilt_F = input.getNumber(1) -- minus L plus R
    local tilt_L = input.getNumber(2) -- minus dow plus up
    local look_X = input.getNumber(3) -- look left - / look right +
    local look_Y = input.getNumber(4) -- look up + / look down -

    -- Adjust pitch based on mouse input (look_Y)
    pitch = -look_Y * 0.5 -- You can adjust the pitch sensitivity by changing the multiplier

    -- Adjust roll based on mouse input (look_X)
    roll = look_X * 0.5 -- You can adjust the roll sensitivity by changing the multiplier

    -- Apply stabilizer to roll and pitch based on tilt sensors
    local multyplyStabilizator = 2
    roll = roll + tilt_L * multyplyStabilizator
    pitch = pitch - tilt_F * multyplyStabilizator

    SetRollPitch(roll, pitch)
end

-- Roll Left (-) / Roll Right (+) / Pitch Down (-) / Pitch Up (+)
function SetRollPitch(roll, pitch)
    output.setNumber(1, roll)
    output.setNumber(2, pitch)
end

-- ----------------------------------------------------------------------------------------------

-- Tilt sensors
local tilt_F = 0 -- Pitch
local tilt_L = 0 -- Roll

-- Mouse inputs
local look_X = 0 -- Roll control: Left(-) / Right(+)
local look_Y = 0 -- Pitch control: Down(-) / Up(+)

-- Control sensitivity and stabilization settings
local mouseSensitivity = property.getNumber("mouseSensitivity")
local stabilizationMultiplier = property.getNumber("stabilizationMultiplier")

function onTick()
    -- Read tilt sensor and mouse input values
    tilt_F = input.getNumber(1) -- minus L plus R
    tilt_L = input.getNumber(2) -- minus down plus up
    look_X = input.getNumber(3) -- look left(-), look right(+)
    look_Y = input.getNumber(4) -- look up(+), look down(-)
    
    -- Calculate stabilization adjustments
    local stabilRoll = -tilt_L * stabilizationMultiplier
    local stabilPitch = tilt_F * stabilizationMultiplier

    -- Adjust roll and pitch based on mouse input
    local rollAdjust = look_X * mouseSensitivity
    local pitchAdjust = look_Y * mouseSensitivity

    -- Combine stabilization and manual control
    local roll = stabilRoll + rollAdjust
    local pitch = stabilPitch + pitchAdjust

    -- Apply roll and pitch adjustments
    SetRollPitch(roll, pitch)
end

-- Set Roll and Pitch function
function SetRollPitch(roll, pitch)
    output.setNumber(1, roll)
    output.setNumber(2, pitch)
end
