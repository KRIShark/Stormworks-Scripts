-- radar.lua
-- =====================================================================
-- Reads up to eight radar contacts each tick, tracks each as an object
-- with a five-sample history, estimates target velocity, solves the
-- intercept point for a 1000 m/s projectile, and writes (x,y,z) aim
-- coordinates for each target into output channels 1–24.
-- =====================================================================

-- === CONFIGURATION CONSTANTS ===
local NUM_RADAR_CONTACTS     = 8     -- how many targets radar can report
local CHANNELS_PER_CONTACT   = 4     -- numeric inputs per contact: dist/az/el/age
local OUTPUTS_PER_CONTACT    = 3     -- numeric outputs per contact: aimX/aimY/aimZ
local SAMPLES_TO_KEEP        = 5     -- length of position history
local TICK_DURATION_SECONDS  = 1/30  -- logic tick duration (~30 Hz)
local PROJECTILE_SPEED_MPS   = 1000  -- muzzle velocity in meters/second

-- === VECTOR MATH UTILITIES ===
local function vectorSubtract(a,b)
  return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end
local function vectorAdd(a,b)
  return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end
local function vectorScale(v,s)
  return { x = v.x * s, y = v.y * s, z = v.z * s }
end
local function vectorDot(a,b)
  return a.x*b.x + a.y*b.y + a.z*b.z
end
local function vectorMagnitudeSquared(v)
  return v.x*v.x + v.y*v.y + v.z*v.z
end

-- =====================================================================
-- Solve first-order intercept: find point where projectile and moving
-- target meet.  Returns a point {x,y,z} or nil if no solution.
--   targetPosition = latest target position relative to gun pivot
--   targetVelocity = estimated velocity vector (m/s)
-- =====================================================================
local function solveInterceptPoint(targetPosition, targetVelocity)
  local r_x = targetPosition.x
  local r_y = targetPosition.y
  local r_z = targetPosition.z

  -- Quadratic coefficients: (v_t^2 − v_p^2) t^2 + 2(r·v_t) t + r^2 = 0
  local a = vectorMagnitudeSquared(targetVelocity) - PROJECTILE_SPEED_MPS^2
  local b = 2 * vectorDot(targetPosition, targetVelocity)
  local c = vectorMagnitudeSquared(targetPosition)

  local discriminant = b*b - 4*a*c
  if discriminant < 0 then
    return nil
  end

  local sqrtDiscriminant = math.sqrt(discriminant)
  local t1 = (-b + sqrtDiscriminant) / (2*a)
  local t2 = (-b - sqrtDiscriminant) / (2*a)

  -- choose smallest positive time solution
  local interceptTime = math.huge
  if t1 > 0 then interceptTime = t1 end
  if t2 > 0 and t2 < interceptTime then interceptTime = t2 end
  if interceptTime == math.huge then
    return nil
  end

  -- compute aim point = p + v * t
  return vectorAdd(targetPosition, vectorScale(targetVelocity, interceptTime))
end

-- =====================================================================
-- RadarContact class prototype:
--   .history[]   = list of past positions {x,y,z}, up to five
--   .cachedX/Y/Z = last valid aim output
--   :updateSample( distance, azTurns, elTurns )
--   :estimateVelocity()
--   :computeAimPoint()
-- =====================================================================
local RadarContact = {
  history = nil,
  cachedX = 0,
  cachedY = 0,
  cachedZ = 0
}

-- Append a new sample (distance, azimuth, elevation) to history
function RadarContact:updateSample(distanceMeters, azimuthTurns, elevationTurns)
  -- convert from turns→radians
  local azimuthRadians   = azimuthTurns   * 2 * math.pi
  local elevationRadians = elevationTurns * 2 * math.pi
  local cosEl = math.cos(elevationRadians)

  -- spherical→Cartesian around gun pivot at (0,0,0)
  local x = distanceMeters * cosEl * math.cos(azimuthRadians)
  local y = distanceMeters * cosEl * math.sin(azimuthRadians)
  local z = distanceMeters * math.sin(elevationRadians)

  -- store into history, truncate oldest if exceeding SAMPLES_TO_KEEP
  table.insert(self.history, { x=x, y=y, z=z })
  if #self.history > SAMPLES_TO_KEEP then
    table.remove(self.history, 1)
  end
end

-- Estimate velocity vector from last two samples
function RadarContact:estimateVelocity()
  if #self.history < 2 then
    return nil
  end
  local p1 = self.history[#self.history-1]
  local p2 = self.history[#self.history]
  return {
    x = (p2.x - p1.x) / TICK_DURATION_SECONDS,
    y = (p2.y - p1.y) / TICK_DURATION_SECONDS,
    z = (p2.z - p1.z) / TICK_DURATION_SECONDS
  }
end

-- Compute and cache intercept aim point; return (x,y,z)
function RadarContact:computeAimPoint()
  local velocity = self:estimateVelocity()
  if velocity then
    local latestPos = self.history[#self.history]
    local aimPoint = solveInterceptPoint(latestPos, velocity)
    if aimPoint then
      self.cachedX = aimPoint.x
      self.cachedY = aimPoint.y
      self.cachedZ = aimPoint.z
    end
  end
  return self.cachedX, self.cachedY, self.cachedZ
end

-- =====================================================================
-- Instantiate eight RadarContact objects
-- =====================================================================
local radarContacts = {}
for i = 0, NUM_RADAR_CONTACTS-1 do
  local contactInstance = {
    history  = {},
    cachedX  = 0,
    cachedY  = 0,
    cachedZ  = 0,
    updateSample     = RadarContact.updateSample,
    estimateVelocity = RadarContact.estimateVelocity,
    computeAimPoint  = RadarContact.computeAimPoint
  }
  radarContacts[i] = contactInstance
end

-- =====================================================================
-- onTick: read inputs, update each contact, output aim points
-- =====================================================================
function onTick()
  for id = 0, NUM_RADAR_CONTACTS-1 do
    local detectedFlag = input.getBool(id + 1)
    local inputBase    = id * CHANNELS_PER_CONTACT
    local outputBase   = id * CHANNELS_PER_CONTACT + 1
    local contact      = radarContacts[id]

    if detectedFlag then
      -- read raw radar data
      local distanceMeters   = input.getNumber(inputBase + 1)
      local azimuthInTurns   = input.getNumber(inputBase + 2)
      local elevationInTurns = input.getNumber(inputBase + 3)

      -- update history and compute intercept
      contact:updateSample(distanceMeters, azimuthInTurns, elevationInTurns)
      local aimX, aimY, aimZ = contact:computeAimPoint()

      -- write to outputs
      output.setNumber(outputBase + 0, aimX)
      output.setNumber(outputBase + 1, aimY)
      output.setNumber(outputBase + 2, aimZ)
    else
      -- no detection: reset history and outputs
      contact.history = {}
      contact.cachedX, contact.cachedY, contact.cachedZ = 0, 0, 0
      output.setNumber(outputBase + 0, 0)
      output.setNumber(outputBase + 1, 0)
      output.setNumber(outputBase + 2, 0)
    end
  end
end

-- =====================================================================
-- onDraw: For debugging
-- =====================================================================
function onDraw()
	-- Example that draws a red circle in the center of the screen with a radius of 20 pixels
	width = screen.getWidth()
	height = screen.getHeight()
    screen.drawRectF(10, 10, 20, 20)
end