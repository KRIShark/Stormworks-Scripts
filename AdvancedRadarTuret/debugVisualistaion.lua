-- 3D_Visualizer.lua
-- =====================================================================
-- Reads N pre‐computed intercept points (X,Y,Z) from input channels each tick,
-- and renders them as colored circles in a 3D projection on the monitor.
-- =====================================================================

-- === CONFIGURATION ===
local NUM_TARGETS      = 8     -- how many contacts (adjust if needed)
local INPUTS_PER_TARGET = 3    -- channels per target: X, Y, Z
-- Visualization parameters
local FOCAL_LENGTH     = 300   -- camera focal length
local CAMERA_Z_OFFSET  = -500  -- shift the camera back along Z
local POINT_RADIUS     = 6     -- radius of each dot
-- Predefined RGB colors for each target
local COLORS = {
  {255,  50,  50},  -- red
  { 50, 255,  50},  -- green
  { 50,  50, 255},  -- blue
  {255, 255,  50},  -- yellow
  {255,  50, 255},  -- magenta
  { 50, 255, 255},  -- cyan
  {255, 125,   0},  -- orange
  {125,   0, 255},  -- purple
}

-- buffer to hold the most recent points
local points = {}
for i=1,NUM_TARGETS do
  points[i] = { x=0, y=0, z=0 }
end

-- =====================================================================
-- onTick: read the XYZ inputs for each target
-- =====================================================================
function onTick()
  for i=1,NUM_TARGETS do
    local base = (i-1)*INPUTS_PER_TARGET
    points[i].x = input.getNumber(base + 1)
    points[i].y = input.getNumber(base + 2)
    points[i].z = input.getNumber(base + 3)
  end
end

-- =====================================================================
-- projectPoint: simple pinhole camera projection
--   world point (x,y,z) → screen u,v
--   returns nil if point is behind or too close to camera
-- =====================================================================
local function projectPoint(pt, w, h)
  -- shift camera along Z
  local zc = pt.z - CAMERA_Z_OFFSET
  if zc <= 0.1 then return nil end
  local u = (pt.x * FOCAL_LENGTH) / zc + w*0.5
  local v = (pt.y * FOCAL_LENGTH) / zc + h*0.5
  return u, v
end

-- =====================================================================
-- onDraw: render all targets as colored circles
-- =====================================================================
function onDraw()
  local w,h = screen.getWidth(), screen.getHeight()
  for i=1,NUM_TARGETS do
    local p = points[i]
    -- skip zero‐points if desired: uncomment next line
    -- if p.x==0 and p.y==0 and p.z==0 then goto continue end

    local u,v = projectPoint(p, w, h)
    if u and v then
      local col = COLORS[i] or {255,255,255}
      screen.setColor(col[1], col[2], col[3])
      screen.drawCircle(u, v, POINT_RADIUS)
    end

    ::continue::
  end

  -- reset color
  screen.setColor(255,255,255)
end
