-- targeting.lua  ─────────────────────────────────────────────────────────
-- • Inputs (numbers)
--     1–24 :  intercept points (x,y,z) for radar targets 0–7
--        25 :  current turret-yaw angle  (turns, −∞…∞)
-- • Inputs (bools)
--     none
--
-- • Outputs
--   numbers:
--        1 :  yaw_velocity        (velocity-pivot, deg / sec  ≈ -5 … +5)
--        2 :  pitch_target_turns  (robotic-pivot, −1 … +1 → −90° … +90°)
--   bools :
--        1 :  fire                (true when target locked)
--
-- Logic
--   – If **no target** → continuous scan:
--         yaw_velocity  =  +0.6  deg/s   (CW sweep)
--         pitch_target  = +15°   (0.166 turns)
--         fire = false
--   – If **target(s) present**
--         pick closest
--         compute desired yaw/pitch
--         yaw_velocity depends on yaw error
--             |err|  >30° ⇒  0.40
--             |err| 10-30° ⇒ 0.25
--             |err|  2-10° ⇒ 0.10
--             |err| < 2° ⇒ 0.05
--             sign = − turn right, + turn left
--         pitch_target_turns = clamp(desired_pitch / 90, −1…+1)
--         fire = true  when |yaw_err|<0.5°  **and**
--                        |pitch_err|<0.5°   (pitch_err estimated)
--   – Simple first-order smoothing prevents jerk.
-------------------------------------------------------------------------]]

--------------------------------------------------------------------------]
-- Tuning constants
local NUM_TGT               = 8      -- radar contacts
local CH_PER_TGT            = 3      -- x,y,z per target
local YAW_INPUT_CH          = 25     -- current yaw angle (turns)
local IDLE_YAW_SPEED        = 0.6    -- deg/s while scanning
local IDLE_PITCH_DEG        = 15     -- idle barrel elevation
local SMOOTH_ALPHA          = 0.12   -- [0..1] low-pass factor

-- yaw speed bands (deg/s)
local SPEED_BAND = {
  {th=30, spd=0.40},
  {th=10, spd=0.25},
  {th= 2, spd=0.10},
  {th= 0, spd=0.05},
}

-- state (smoothed targets)
local s_yaw_target_deg   = 0
local s_pitch_target_deg = IDLE_PITCH_DEG

--  ── math helpers ──────────────────────────────────────────────────────
local function to_deg(rad) return rad*180/math.pi end

local function atan2(y,x)
  if     x>0 then return math.atan(y/x)
  elseif x<0 and y>=0 then return math.atan(y/x)+math.pi
  elseif x<0 and y< 0 then return math.atan(y/x)-math.pi
  elseif x==0 and y>0 then return  math.pi/2
  elseif x==0 and y<0 then return -math.pi/2
  else   return 0 end
end

local function norm_ang(d)
  while d>180 do d=d-360 end
  while d<-180 do d=d+360 end
  return d
end

local function choose_speed(err_deg)
  local a = math.abs(err_deg)
  for _,b in ipairs(SPEED_BAND) do
    if a> b.th then return b.spd*(err_deg<0 and -1 or 1) end
  end
  return 0
end

--  ── main tick ─────────────────────────────────────────────────────────
function onTick()
  -- current yaw in degrees
  local yaw_cur_deg = input.getNumber(YAW_INPUT_CH)*360

  -- find closest target
  local best_d2 = math.huge
  local tx,ty,tz = nil,nil,nil
  for id=0,NUM_TGT-1 do
    local base = id*CH_PER_TGT
    local x = input.getNumber(base+1)
    local y = input.getNumber(base+2)
    local z = input.getNumber(base+3)
    if x~=0 or y~=0 or z~=0 then
      local d2 = x*x + y*y + z*z
      if d2<best_d2 then best_d2,tx,ty,tz = d2,x,y,z end
    end
  end

  local yaw_des_deg, pitch_des_deg, fire=false

  if best_d2 == math.huge then
    -- ─── idle scan ────────────────────────────────────────────────────
    yaw_des_deg   = yaw_cur_deg + 5   -- arbitrary large step; smoothed later
    pitch_des_deg = IDLE_PITCH_DEG
    fire = false
  else
    -- ─── target acquired ─────────────────────────────────────────────
    yaw_des_deg = to_deg(atan2(ty,tx))
    local horiz = math.sqrt(tx*tx + ty*ty)
    pitch_des_deg = to_deg(atan2(tz, horiz))

    local yaw_err   = math.abs(norm_ang(yaw_des_deg   - yaw_cur_deg))
    local pitch_err = math.abs(norm_ang(pitch_des_deg - s_pitch_target_deg))
    fire = (yaw_err <0.5 and pitch_err<0.5)
  end

  -- ─── low-pass smoothing of desired angles ──────────────────────────
  s_yaw_target_deg   = s_yaw_target_deg   + SMOOTH_ALPHA*norm_ang(yaw_des_deg   - s_yaw_target_deg)
  s_pitch_target_deg = s_pitch_target_deg + SMOOTH_ALPHA*norm_ang(pitch_des_deg - s_pitch_target_deg)

  -- ─── compute yaw speed based on error ──────────────────────────────
  local yaw_err_deg = norm_ang(s_yaw_target_deg - yaw_cur_deg)
  local yaw_speed   = choose_speed(yaw_err_deg)
  if best_d2 == math.huge then yaw_speed = (yaw_speed>=0) and  IDLE_YAW_SPEED or -IDLE_YAW_SPEED end

  -- ─── pitch target for robotic pivot (turns) ────────────────────────
  local pitch_target_turns = math.max(-1, math.min(1, s_pitch_target_deg/90))

  -- ─── outputs ────────────────────────────────────────────────────────
  output.setNumber(1, yaw_speed)              -- velocity pivot (yaw)
  output.setNumber(2, pitch_target_turns)     -- robotic pivot (pitch)
  output.setBool  (1, fire)                   -- fire signal
end
