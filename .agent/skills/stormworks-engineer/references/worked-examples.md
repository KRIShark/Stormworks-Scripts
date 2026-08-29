# Worked patterns

These examples demonstrate structure and failure handling. Adapt channel maps, units, signs, component settings and API signatures to the user's installed version. Do not present them as universal drop-in controllers without the accompanying wiring contract.

## Example 1: Microcontroller RPS governor with start/fault behavior

Purpose: hold a requested RPS with PI control, crank below the start threshold, and stop on over-temperature or invalid input.

### Wiring

| Namespace | Channel | Name | Unit/range | Connection |
| --- | ---: | --- | --- | --- |
| Boolean in | 1 | Enable | Boolean | Key/button |
| Boolean in | 2 | Reset fault | momentary | Push button |
| Number in | 1 | Target RPS | RPS | Throttle/keypad/controller |
| Number in | 2 | Measured RPS | RPS | Engine sensor |
| Number in | 3 | Temperature | C | Engine temperature |
| Number out | 1 | Throttle | 0..1 | Engine air/throttle path |
| Boolean out | 1 | Starter | Boolean | Starter motor |
| Boolean out | 2 | Fault | Boolean | Alarm/indicator |

### Properties

| Type | Exact label | Suggested initial value |
| --- | --- | ---: |
| Number | Kp | 0.08 |
| Number | Ki | 0.02 |
| Number | Start RPS | 2.5 |
| Number | Max Temp | 105 |
| Number | Crank Throttle | 0.25 |

Suggested values are starting points, not verified universal tuning.

```lua
local DT = 1 / 60
local integral = 0
local fault = false
local previous_reset = false

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function valid(x)
    return x == x and math.abs(x) < 1e300
end

function onTick()
    local enabled = input.getBool(1)
    local reset = input.getBool(2)
    local target = input.getNumber(1)
    local rps = input.getNumber(2)
    local temperature = input.getNumber(3)

    local kp = property.getNumber("Kp")
    local ki = property.getNumber("Ki")
    local start_rps = property.getNumber("Start RPS")
    local max_temp = property.getNumber("Max Temp")
    local crank_throttle = property.getNumber("Crank Throttle")

    if reset and not previous_reset and temperature < max_temp then
        fault = false
    end
    previous_reset = reset

    if not valid(rps) or not valid(temperature) or temperature >= max_temp then
        fault = true
    end

    local throttle = 0
    local starter = false

    if enabled and not fault then
        target = math.max(0, target)
        if rps < start_rps then
            starter = true
            throttle = clamp(crank_throttle, 0, 1)
            integral = 0
        else
            local error = target - rps
            local candidate = integral + error * DT
            local raw = kp * error + ki * candidate
            throttle = clamp(raw, 0, 1)

            -- Conditional integration limits windup at saturation.
            if raw == throttle or
               (raw > 1 and error < 0) or
               (raw < 0 and error > 0) then
                integral = clamp(candidate, -100, 100)
            end
        end
    else
        integral = 0
    end

    output.setNumber(1, throttle)
    output.setBool(1, starter)
    output.setBool(2, fault)
end
```

Test with the clutch disconnected. Confirm positive throttle increases RPS, starter disengages above threshold, throttle stays in 0..1, disable drives both outputs safe, and fault latches at the temperature limit. Add minimum running throttle, cooling control and clutch state only after the base test.

## Example 2: Touch button and resolution-independent status display

This separates event processing in `onTick` from idempotent rendering in `onDraw`.

### Wiring

Connect the touch monitor's composite output to the Lua block's composite input. Connect Lua video to the monitor. Use Boolean output 1 as the toggled command.

```lua
local enabled = false
local pressed_last = false
local touch_x, touch_y = 0, 0

local function inside(px, py, x, y, w, h)
    return px >= x and py >= y and px < x + w and py < y + h
end

function onTick()
    local screen_w = input.getNumber(1)
    local screen_h = input.getNumber(2)
    touch_x = input.getNumber(3)
    touch_y = input.getNumber(4)
    local pressed = input.getBool(1)
    local clicked = pressed and not pressed_last

    local button_x = 2
    local button_y = math.max(2, screen_h - 14)
    local button_w = math.max(20, screen_w - 4)
    local button_h = 12

    if clicked and inside(touch_x, touch_y,
                          button_x, button_y, button_w, button_h) then
        enabled = not enabled
    end

    pressed_last = pressed
    output.setBool(1, enabled)
end


function onDraw()
    local w, h = screen.getWidth(), screen.getHeight()
    screen.setColor(5, 8, 12)
    screen.drawClear()

    screen.setColor(230, 235, 240)
    screen.drawTextBox(2, 2, w - 4, math.max(5, h - 18),
        enabled and "SYSTEM ENABLED" or "SYSTEM DISABLED", 0, 0)

    local y = math.max(2, h - 14)
    if enabled then
        screen.setColor(30, 150, 70)
    else
        screen.setColor(150, 40, 40)
    end
    screen.drawRectF(2, y, math.max(20, w - 4), 12)
    screen.setColor(255, 255, 255)
    screen.drawTextBox(2, y, math.max(20, w - 4), 12,
        enabled and "TURN OFF" or "TURN ON", 0, 0)
end
```

The monitor composite resolution used for touch calculations must correspond to the monitor being drawn. For one Lua output driving differently sized monitors, use separate controllers or a deliberate input/display ownership rule.

## Example 3: Microcontroller waypoint display and steering error

Assumed candidate convention: GPS uses map X/Y, compass heading is in turns, and `math.atan(dx, dy)` yields a north-zero bearing after calibration. Because compass signs vary with interpretation/orientation, verify north/east before connecting the steering output.

### Wiring

| Namespace | Channel | Name |
| --- | ---: | --- |
| Number in | 1 | Current GPS X |
| Number in | 2 | Current GPS Y |
| Number in | 3 | Current heading turns |
| Number in | 4 | Target X |
| Number in | 5 | Target Y |
| Number in | 6 | Map zoom |
| Number out | 1 | Signed heading error turns |

```lua
local TAU = math.pi * 2
local current_x, current_y = 0, 0
local target_x, target_y = 0, 0
local zoom = 2
local distance = 0
local error_turns = 0

local function wrapTurns(x)
    return (x + 0.5) % 1 - 0.5
end

function onTick()
    current_x = input.getNumber(1)
    current_y = input.getNumber(2)
    local heading_turns = input.getNumber(3)
    target_x = input.getNumber(4)
    target_y = input.getNumber(5)
    zoom = math.max(0.1, math.min(50, input.getNumber(6)))

    local dx = target_x - current_x
    local dy = target_y - current_y
    distance = math.sqrt(dx * dx + dy * dy)
    local bearing_turns = math.atan(dx, dy) / TAU
    error_turns = wrapTurns(bearing_turns - heading_turns)
    output.setNumber(1, error_turns)
end

function onDraw()
    local w, h = screen.getWidth(), screen.getHeight()
    screen.drawMap(current_x, current_y, zoom)
    local px, py = map.mapToScreen(current_x, current_y, zoom,
                                   w, h, target_x, target_y)
    screen.setColor(255, 70, 30)
    screen.drawCircle(px, py, 3)
    screen.drawLine(px - 4, py, px + 4, py)
    screen.drawLine(px, py - 4, px, py + 4)
    screen.setColor(255, 255, 255)
    screen.drawText(2, 2, "D " .. tostring(math.floor(distance)))
end
```

Do not directly send the full heading error to a rudder. Apply a calibrated sign, gain, clamp, yaw-rate damping and low-speed policy.

## Example 4: Addon command with persistent setting and per-player help

This demonstrates authorization, parsing, persistence and join-time messaging without announcing too early in `onCreate`.

```lua
local SCHEMA_VERSION = 1

local function initialize()
    g_savedata = g_savedata or {}
    g_savedata.schema_version = g_savedata.schema_version or SCHEMA_VERSION
    g_savedata.alert_radius = g_savedata.alert_radius or 1000
end

local function tell(peer_id, message)
    server.announce("Range Alert", message, peer_id)
end

function onCreate(is_world_create)
    initialize()
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
    tell(peer_id, "Use ?alert_radius to view the current radius")
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth,
                         command, arg1)
    if command ~= "?alert_radius" then return end

    if arg1 == nil then
        tell(peer_id, "Alert radius: " .. tostring(g_savedata.alert_radius))
        return
    end

    if not is_admin then
        tell(peer_id, "Admin permission required to change it")
        return
    end

    local radius = tonumber(arg1)
    if not radius or radius < 10 or radius > 100000 then
        tell(peer_id, "Usage: ?alert_radius <10..100000>")
        return
    end

    g_savedata.alert_radius = radius
    tell(peer_id, "Alert radius set to " .. tostring(radius))
end
```

For a mature addon, migrate older schema versions instead of merely assigning the current number.

## Example 5: Addon vehicle lifecycle registry

Use events rather than scanning every vehicle every tick.

```lua
local function initialize()
    g_savedata = g_savedata or {}
    g_savedata.vehicles = g_savedata.vehicles or {}
end

function onCreate(is_world_create)
    initialize()
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost, group_id)
    g_savedata.vehicles[vehicle_id] = {
        group_id = group_id,
        owner_peer_id = peer_id,
        loaded = false,
        spawned_x = x,
        spawned_y = y,
        spawned_z = z
    }
end

function onVehicleLoad(vehicle_id)
    local record = g_savedata.vehicles[vehicle_id]
    if record then
        record.loaded = true
        -- Physics/component operations can now be queued or applied.
    end
end

function onVehicleUnload(vehicle_id)
    local record = g_savedata.vehicles[vehicle_id]
    if record then record.loaded = false end
end

function onVehicleDespawn(vehicle_id, peer_id)
    g_savedata.vehicles[vehicle_id] = nil
end
```

If the addon should track only its own scripted vehicles, do not register all player spawns. Mark ownership when spawning an addon location/component and reconcile it in `onSpawnAddonComponent`.
