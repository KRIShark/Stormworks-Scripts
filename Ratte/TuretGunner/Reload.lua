gun_left_loaded = false
gun_right_loaded = false

-- Tick function that will be executed every logic tick
function onTick()
    gun_left_loaded = input.getBool(1)			 -- gun L Loaded
    gun_right_loaded = input.getBool(2)
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
    w = screen.getWidth()				  -- Get the screen's width and height
    h = screen.getHeight()					
    screen.setColor(255, 255, 255)			 -- Set draw color to green
    screen.drawRect(0, 0, 10, 10)
    
    screen.drawRect(w-10, 0, 10, 10)

    if gun_left_loaded then
        screen.setColor(0, 255, 0)
        screen.drawRectF(1, 1, 8, 8)
    end

    if gun_right_loaded then
        screen.setColor(0, 255, 0)
        screen.drawRectF(w-9, 1, 8, 8)
    end

    -- Drow a box on the top center of the screen
    screen.drawRectF(w / 2 - 10, 0, 20, 20)

    if isPointInRectangle(w / 2 - 10, 0, 20, 20) then
        output.setBool(1, true)
    end
end

    -- Returns true if the point (x, y) is inside the rectangle at (rectX, rectY) with width rectW and height rectH
function isPointInRectangle(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end