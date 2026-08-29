radar_target = {}
radar_target.__index = radar_target

local TAU = math.pi * 2  -- Full turn (2π)

function radar_target:new(distance, azimuth_turns, elevation_turns, time_since_detection)
    local obj = {
        distance = distance,                         -- Distance to the target in meters
        azimuth_turns = azimuth_turns,               -- Azimuth angle in turns (0-1)
        elevation_turns = elevation_turns,           -- Elevation angle in turns (0-1)
        time_since_detection = time_since_detection, -- Time since last detection
        position = { x = 0, y = 0, z = 0 }            -- Cartesian position (to be calculated)
    }
    setmetatable(obj, self)
    return obj
end

-- Converts from spherical to Cartesian coordinates, using radar rotation
function radar_target:calculate_position(radar_rotation_turns)
    local azimuth_world_turns = (self.azimuth_turns + radar_rotation_turns) % 1.0
    local azimuth_rad = azimuth_world_turns * TAU
    local elevation_rad = self.elevation_turns * TAU

    local r = self.distance
    local cos_el = math.cos(elevation_rad)

    self.position.x = r * cos_el * math.cos(azimuth_rad)
    self.position.y = r * cos_el * math.sin(azimuth_rad)
    self.position.z = r * math.sin(elevation_rad)
end

-- Optional: to print out position
function radar_target:get_position()
    return self.position.x, self.position.y, self.position.z
end


-- Global target tracking: targets[target_id] = { list of last 5 radar_target objects }
targets = {}

-- Constants
-- Number of tracked targets
NUM_TARGETS = 8

-- Max history length per target
MAX_HISTORY = 5

-- Tick
FUTURE_MS = 500
TICK_DURATION = 1 / 30 -- Stormworks logic tick is ~30Hz


-- intercept

-- Vector math utilities
function vector_dot_product(vec1, vec2)
    return vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z
end

function vector_magnitude_squared(vec)
    return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z
end

function vector_scale(vec, scalar)
    return { x = vec.x * scalar, y = vec.y * scalar, z = vec.z * scalar }
end

function vector_add(vec1, vec2)
    return { x = vec1.x + vec2.x, y = vec1.y + vec2.y, z = vec1.z + vec2.z }
end

function vector_subtract(vec1, vec2)
    return { x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z }
end

-- Calculates the intercept point where the gun should aim to hit a moving target
-- Inputs:
--   gun_position (table with x, y, z)
--   target_current_position (table with x, y, z)
--   target_velocity (table with x, y, z)
--   projectile_speed (number in m/s)
-- Outputs:
--   aim_position (table with x, y, z) and time_to_intercept (seconds), or nil if impossible
function calculate_intercept_point(gun_position, target_current_position, target_velocity, projectile_speed)
    -- Vector from gun to target
    local relative_position = vector_subtract(target_current_position, gun_position)

    -- Coefficients for quadratic equation
    local a = vector_magnitude_squared(target_velocity) - projectile_speed * projectile_speed
    local b = 2 * vector_dot_product(relative_position, target_velocity)
    local c = vector_magnitude_squared(relative_position)

    -- Solve quadratic for time
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return nil, nil  -- No real solution: can't hit the target
    end

    local sqrt_discriminant = math.sqrt(discriminant)
    local time_solution_1 = (-b + sqrt_discriminant) / (2 * a)
    local time_solution_2 = (-b - sqrt_discriminant) / (2 * a)

    -- Choose the smallest positive time
    local time_to_intercept = math.huge
    if time_solution_1 > 0 then time_to_intercept = time_solution_1 end
    if time_solution_2 > 0 and time_solution_2 < time_to_intercept then
        time_to_intercept = time_solution_2
    end

    if time_to_intercept == math.huge then
        return nil, nil  -- No valid future intercept
    end

    -- Calculate where the target will be at that time
    local aim_position = vector_add(target_current_position, vector_scale(target_velocity, time_to_intercept))
    return aim_position, time_to_intercept
end


-- Called every logic tick
function onTick()
    local radar_rotation = input.getNumber(33) -- assuming radar rotation is on number channel 33

    for target_id = 0, NUM_TARGETS - 1 do
        if input.getBool(target_id + 1) then
            local base = target_id * 4
            local distance = input.getNumber(base + 1)
            local azimuth = input.getNumber(base + 2)
            local elevation = input.getNumber(base + 3)
            local time_since_detection = input.getNumber(base + 4)

            -- Create target object
            local target = radar_target:new(distance, azimuth, elevation, time_since_detection)
            target:calculate_position(radar_rotation)

            -- Init list if not yet
            if not targets[target_id] then
                targets[target_id] = {}
            end

            -- Add to history
            table.insert(targets[target_id], target)

            -- Trim to last 5
            if #targets[target_id] > MAX_HISTORY then
                table.remove(targets[target_id], 1)
            end
        end
    end
end


-- Draw function that will be executed when this script renders to a screen
function onDraw()
	w = screen.getWidth()				  -- Get the screen's width and height
	h = screen.getHeight()					
	screen.setColor(0, 255, 0)			 -- Set draw color to green
	screen.drawCircleF(w / 2, h / 2, 30)   -- Draw a 30px radius circle in the center of the screen
end