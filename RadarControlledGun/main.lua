-- Tick function that will be executed every logic tick
function onTick()
    value = input.getNumber(1)			 -- Read the first number from the script's composite input

    -- Create an array named "targets" of booleans
    local targets = {}

    for i = 1, 8 do
        targets[i] = input.getBool(i)
    end

    for i = 4, 32 do
        targets[i] = getTargetsData(i)
    end

    -- Do something with the closest target

    local closestTargetData = findClosestTarget(targets)

    -- Do something with the closest target data
    if closestTargetData then
        -- Now you can use closestTargetData for further processing
        output.setNumber(1, closestTargetData["Distance"]) -- Example: Output the closest target's distance
        output.setNumber(2, closestTargetData["Angle"]) -- Output the closest target's angle
        output.setNumber(3, closestTargetData["ElevationAngle"]) -- Output the closest target's elevation angle
        output.setNumber(4, closestTargetData["AzimuthAngle"]) -- Output the closest target's azimuth angle
        output.setNumber(5, closestTargetData["TimeSinceDetected"]) -- Output the closest target's time since detected
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
            if targetData["Distance"] < closestDistance then
                closestDistance = targetData["Distance"]
                closestTargetData = targetData
            end
        end
    end

    return closestTargetData
end