board = {0,0,0, 0,0,0, 0,0,0}
player = 1 -- always X
computer = 2 -- always O
popup = false
popupText = ""
winner = 0
wasPressed = false
touchX, touchY, touchClicked = 0, 0, false

function checkWin(b)
    local winLines = {
        {1,2,3}, {4,5,6}, {7,8,9},
        {1,4,7}, {2,5,8}, {3,6,9},
        {1,5,9}, {3,5,7}
    }
    for i,line in ipairs(winLines) do
        local a,b1,c = b[line[1]], b[line[2]], b[line[3]]
        if a ~= 0 and a == b1 and b1 == c then
            return a
        end
    end
    for i=1,9 do if b[i]==0 then return 0 end end
    return 3 -- draw
end

function resetGame()
    for i=1,9 do board[i]=0 end
    popup = false
    popupText = ""
    winner = 0
end

-- Minimax (no recursion! iterative and simple for 3x3)
function bestMove()
    local bestScore = -1000
    local move = -1
    for i=1,9 do
        if board[i] == 0 then
            board[i] = computer
            local score = minimax(board, 0, false)
            board[i] = 0
            if score > bestScore then
                bestScore = score
                move = i
            end
        end
    end
    return move
end

function minimax(b, depth, isMaximizing)
    local result = checkWin(b)
    if result == computer then return 10 - depth end
    if result == player then return depth - 10 end
    if result == 3 then return 0 end

    if isMaximizing then
        local bestScore = -1000
        for i=1,9 do
            if b[i] == 0 then
                b[i] = computer
                local score = minimax(b, depth+1, false)
                b[i] = 0
                if score > bestScore then bestScore = score end
            end
        end
        return bestScore
    else
        local bestScore = 1000
        for i=1,9 do
            if b[i] == 0 then
                b[i] = player
                local score = minimax(b, depth+1, true)
                b[i] = 0
                if score < bestScore then bestScore = score end
            end
        end
        return bestScore
    end
end

function computerMove()
    local move = bestMove()
    if move > 0 then
        board[move] = computer
    end
end

function onTick()
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

    if touchClicked then
        local w, h = 96, 96
        local cellSize = math.min(w, h) / 3
        if popup then
            resetGame()
        else
            local cx = math.floor(touchX / cellSize)
            local cy = math.floor(touchY / cellSize)
            local idx = cy * 3 + cx + 1
            if cx >= 0 and cx < 3 and cy >= 0 and cy < 3 and idx >= 1 and idx <= 9 and board[idx] == 0 then
                board[idx] = player
                winner = checkWin(board)
                if winner == 0 then
                    computerMove()
                    winner = checkWin(board)
                end
                if winner > 0 then
                    if winner == player then
                        popupText = "You win!"
                    elseif winner == computer then
                        popupText = "Computer wins!"
                    else
                        popupText = "Draw!"
                    end
                    popup = true
                end
            end
        end
    end
end

function drawTikTakTo(w, h, board)
    local cellSize = math.min(w, h) / 3
    screen.setColor(255, 255, 255)
    for i = 1, 2 do
        screen.drawLine(i * cellSize, 0, i * cellSize, h)
        screen.drawLine(0, i * cellSize, w, i * cellSize)
    end
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
        screen.setColor(0,0,0,180)
        screen.drawRectF(w/2-60, h/2-25, 120, 50)
        screen.setColor(255,255,255)
        screen.drawRect(w/2-60, h/2-25, 120, 50)
        screen.drawTextBox(w/2-55, h/2-20, 110, 40, popupText, 0, 0)
        screen.drawText(w/2-35, h/2+10, "Click to reset")
    end
end
