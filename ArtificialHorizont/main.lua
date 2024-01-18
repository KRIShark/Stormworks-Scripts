local pitch = 0
local roll = 0

function onTick()
    pitch = input.getNumber(2) -- Assuming pitch is on input 2
    roll = input.getNumber(3)  -- Assuming roll is on input 3
end

function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()
    local centerX = w / 2
    local centerY = h / 2

    -- Calculate horizon line position
    local horizonY = centerY - (pitch * 20) -- The number 20 scales the pitch value

    -- Draw the horizon line
    screen.setColor(255, 255, 255) -- White color for the horizon
    screen.drawLine(0, horizonY, w, horizonY)

    -- Draw roll indicator
    screen.setColor(255, 255, 255) -- White color for the roll indicator
    screen.drawLine(centerX - 10, centerY, centerX + 10, centerY) -- Simple static line for roll
    
    -- Optional: Add more HUD elements as needed
end
