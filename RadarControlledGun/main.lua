targets = {}


-- Tick function that will be executed every logic tick
function onTick()
    value = input.getNumber(1)			 -- Read the first number from the script's composite input

    for i = 1, 8 do
        targets[i] = input.getBool(i)
    end

    for i = 4, 32 do
        targets[i] = getTargetsData(i)
    end

    -- Do something with the closest target

    local closestTargetData = findClosestTarget(targets)

    local lastClosestTargetData ={ } 
    -- Do something with the closest target data
    if closestTargetData then
        -- Now you can use closestTargetData for further processing

        lastClosestTargetData = closestTargetData
    end

    if lastClosestTargetData then
        output.setNumber(1, lastClosestTargetData["Distance"]) -- Example: Output the closest target's distance
        output.setNumber(2, lastClosestTargetData["Angle"]) -- Output the closest target's angle
        output.setNumber(3, lastClosestTargetData["ElevationAngle"]) -- Output the closest target's elevation angle
        output.setNumber(4, lastClosestTargetData["AzimuthAngle"]) -- Output the closest target's azimuth angle
        output.setNumber(5, lastClosestTargetData["TimeSinceDetected"]) -- Output the closest target's time since detected
    end

end

function getTargetsData(startindex)
    data = {
        ["Distance"] = input.getNumber(startindex),
        ["Angle"] = input.getNumber(startindex + 1),
        ["ElevationAngle"] = input.getNumber(startindex + 2),
        ["AzimuthAngle"] = input.getNumber(startindex + 3),
        ["TimeSinceDatected"] = input.getNumber(startindex + 3)
    }
    return data
end

function findClosestTarget(targets)
    local closestDistance = math.huge
    local closestTargetData = nil

    for i = 1, #targets do
        if targets[i] then
            local targetData = getTargetsData(3 + (i - 1) * 4) -- Assuming each target's data is stored in blocks of 4 starting from index 4
            if targetData["Distance"] < closestDistance and targetData["Distance"] > property.getNumber("minDistance") then
                closestDistance = targetData["Distance"]
                closestTargetData = targetData
            end
        end
    end

    return closestTargetData
end

function onDraw()
	-- Example that draws a red circle in the center of the screen with a radius of 20 pixels
	width = screen.getWidth()
	height = screen.getHeight()
    
    if targets then
        -- Loop through the targets and print the index and target data
        for i, target in ipairs(targets) do
            if target then
                screen.setText(1, 3 * i, "Distance")
                screen.setText(10, 3 * i, target[i]["Distance"])
            end
        end
    end
    
    
end