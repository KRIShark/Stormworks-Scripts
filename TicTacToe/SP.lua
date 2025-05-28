-- Global state
board = {0,0,0, 0,0,0, 0,0,0}
currentPlayer = property.getNumber("Current Player")
popup = false
popupText = ""
winner = 0
wasPressed = false -- for touch edge detection
touchX, touchY, touchClicked = 0, 0, false

function checkWin(board)
    local winLines = {
        {1,2,3}, {4,5,6}, {7,8,9},
        {1,4,7}, {2,5,8}, {3,6,9},
        {1,5,9}, {3,5,7}
    }
    for i,line in ipairs(winLines) do
        local a,b,c = board[line[1]], board[line[2]], board[line[3]]
        if a ~= 0 and a == b and b == c then
            return a
        end
    end
    -- Draw?
    for i=1,9 do if board[i]==0 then return 0 end end
    return 3
end

function resetGame()
    for i=1,9 do board[i]=0 end
    currentPlayer = 1
    popup = false
    popupText = ""
    winner = 0
end

function onTick()
    -- Read touch input (composite)
    local inputX = input.getNumber(3)
    local inputY = input.getNumber(4)
    local isPressed = input.getBool(1)
    
    touchClicked = false
    if isPressed and not wasPressed then
        touchX = inputX
        touchY = inputY
        touchClicked = true
    end
    wasPressed = isPressed
    
    -- Only handle logic here, no drawing
    if touchClicked then
        local w, h = 96, 96 -- Default for 3x3, will match draw if screen changed
        local cellSize = math.min(w, h) / 3
        if popup then
            resetGame()
        else
            local cx = math.floor(touchX / cellSize)
            local cy = math.floor(touchY / cellSize)
            local idx = cy * 3 + cx + 1
            if cx >= 0 and cx < 3 and cy >= 0 and cy < 3 and idx >= 1 and idx <= 9 and board[idx] == 0 then
                board[idx] = currentPlayer
                winner = checkWin(board)
                if winner > 0 then
                    if winner == 1 then
                        popupText = "X wins!"
                    elseif winner == 2 then
                        popupText = "O wins!"
                    else
                        popupText = "Draw!"
                    end
                    popup = true
                else
                    currentPlayer = 3 - currentPlayer
                end
            end
        end
    end
end

function drawTikTakTo(w, h, board)
    local cellSize = math.min(w, h) / 3
    -- Draw grid
    screen.setColor(255, 255, 255)
    for i = 1, 2 do
        screen.drawLine(i * cellSize, 0, i * cellSize, h)
        screen.drawLine(0, i * cellSize, w, i * cellSize)
    end

    -- Draw cells
    for y = 0, 2 do
        for x = 0, 2 do
            local idx = y * 3 + x + 1
            local val = board[idx]
            local cx = x * cellSize + cellSize / 2
            local cy = y * cellSize + cellSize / 2
            if val == 1 then
                screen.setColor(255, 0, 0)
                screen.drawLine(cx - cellSize/4, cy - cellSize/4, cx + cellSize/4, cy + cellSize/4)
                screen.drawLine(cx - cellSize/4, cy + cellSize/4, cx + cellSize/4, cy - cellSize/4)
            elseif val == 2 then
                screen.setColor(0, 0, 255)
                screen.drawCircle(cx, cy, cellSize/4)
            end
        end
    end
end

function onDraw()
    local w = screen.getWidth()
    local h = screen.getHeight()
    drawTikTakTo(w, h, board)
    if popup then
        -- Draw popup
        screen.setColor(0,0,0,180)
        screen.drawRectF(w/2-60, h/2-25, 120, 50)
        screen.setColor(255,255,255)
        screen.drawRect(w/2-60, h/2-25, 120, 50)
        screen.drawTextBox(w/2-55, h/2-20, 110, 40, popupText, 0, 0)
        screen.drawText(w/2-35, h/2+10, "Click to reset")
    end
end
