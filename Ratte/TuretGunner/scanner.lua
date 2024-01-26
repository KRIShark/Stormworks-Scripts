dist = 0
laser_x = 1
laser_y = 1
max_dist = 1000

x_index = 0
y_index = 0

incrise = 0.1

w = 10
h = 10

points = {}

index = 0

-- Tick function that will be executed every logic tick
function onTick()
    dist = input.getNumber(1)			 -- gun L Loaded

    if laser_x > -1 then
        laser_x = laser_x - incrise  -- Decrease countdown
    end

    if laser_x < -1 then
        laser_x = 1
        laser_y = laser_y - incrise
    end

    if laser_y < -1 then
        laser_y = 1
        points = {}
        index = 0
    end

    output.setNumber(1, laser_x)
    output.setNumber(2, laser_y)

    -- Map laser_x and laser_y to screen coordinates
    x_index = math.floor((laser_x + 1) / 2 * (w - 1))
    y_index = math.floor((laser_y + 1) / 2 * (h - 1))

    points[index] = {
        ["x"] = x_index,
        ["y"] = y_index,
        ["dist"] = dist
    }

    index = index + 1
    
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
    w = screen.getWidth()				  -- Get the screen's width and height
    h = screen.getHeight()	

    for i = 0, #points do
        valide_green_value = points[i]["dist"] / max_dist * 255
        screen.setColor(0, valide_green_value, 0)
        screen.drawRectF(points[i]["x"], points[i]["y"], 1,1)
    end

    -- valide_green_value = dist / max_dist * 255

    -- screen.setColor(0, valide_green_value, 0)
    -- screen.drawRectF(x_index, y_index, 1, 1)
end

    -- Returns true if the point (x, y) is inside the rectangle at (rectX, rectY) with width rectW and height rectH
function isPointInRectangle(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end