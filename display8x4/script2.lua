local output = {}
local input = {}

function output.setBool(index, value)
    print("output.setBool called with index:", index, "and value:", value)
end

function input.getBool(index)
    return true
end

-- below is the code for stormworks logic script

on = true
reset = false

data = {
    {false, true, false, true, true, false, false, true},
    {false, true, true, true, true, true, true, false},
    {false, false, true, false, false, false, false, false},
    {true, true, false, true, false, false, true, false},
}

-- Tick function that will be executed every logic tick
function onTick()
    on = input.getBool(1)             -- Read the first number from the script's composite input
    reset = input.getBool(2)
    
    -- Set output 1
    output.setBool( 1, data[1][1])
    
    -- Set output 2
    output.setBool( 2, data[1][2])
    
    -- Set output 3
    output.setBool( 3, data[1][3])
    
    -- Set output 4
    output.setBool( 4, data[1][4])
    
    -- Set output 5
    output.setBool( 5, data[1][5])
    
    -- Set output 6
    output.setBool( 6, data[1][6])
    
    -- Set output 7
    output.setBool( 7, data[1][7])
    
    -- Set output 8
    output.setBool( 8, data[1][8])
    
    -- Set output 9
    output.setBool( 9, data[2][1])
    
    -- Set output 10
    output.setBool( 10, data[2][2])
    
    -- Set output 11
    output.setBool( 11, data[2][3])
    
    -- Set output 12
    output.setBool( 12, data[2][4])
    
    -- Set output 13
    output.setBool( 13, data[2][5])
    
    -- Set output 14
    output.setBool( 14, data[2][6])
    
    -- Set output 15
    output.setBool( 15, data[2][7])
    
    -- Set output 16
    output.setBool( 16, data[2][8])
    
    -- Set output 17
    output.setBool( 17, data[3][1])
    
    -- Set output 18
    output.setBool( 18, data[3][2])
    
    -- Set output 19
    output.setBool( 19, data[3][3])
    
    -- Set output 20
    output.setBool( 20, data[3][4])
    
    -- Set output 21
    output.setBool( 21, data[3][5])
    
    -- Set output 22
    output.setBool( 22, data[3][6])
    
    -- Set output 23
    output.setBool( 23, data[3][7])
    
    -- Set output 24
    output.setBool( 24, data[3][8])
    
    -- Set output 25
    output.setBool( 25, data[4][1])
    
    -- Set output 26
    output.setBool( 26, data[4][2])
    
    -- Set output 27
    output.setBool( 27, data[4][3])
    
    -- Set output 28
    output.setBool( 28, data[4][4])
    
    -- Set output 29
    output.setBool( 29, data[4][5])
    
    -- Set output 30
    output.setBool( 30, data[4][6])
    
    -- Set output 31
    output.setBool( 31, data[4][7])
    
    -- Set output 32
    output.setBool( 32, data[4][8])
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
    w = screen.getWidth()                  -- Get the screen's width and height
    h = screen.getHeight()                    
    screen.setColor(0, 255, 0)             -- Set draw color to green
    screen.drawCircleF(w / 2, h / 2, 30)   -- Draw a 30px radius circle in the center of the screen
end

-- end of stormworks logic script

onTick()