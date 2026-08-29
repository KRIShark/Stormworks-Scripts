# Vehicle microcontroller Lua

This environment is the Lua Script logic block inside a vehicle microcontroller. It is not addon/server Lua and has no `server.*` or `g_savedata`.

The API summary below is based on the help text extracted from Stormworks v1.15.20. Verify against the help panel in the user's installed version when an exact limit or signature matters.

## Execution model

```lua
function onTick()
    -- Read inputs, update state, write outputs.
end

function onDraw()
    -- Draw the current state to a connected video output.
end

function httpReply(port, request_body, response_body)
    -- Receive the response to async.httpGet.
end
```

- `onTick()` runs once per logic tick. Normal logic runs at about 60 ticks per second.
- `onDraw()` runs when the Lua video is rendered by a monitor. It can run multiple times per logic tick when connected to multiple monitors. Screen width/height are those of the monitor currently being rendered.
- Input/output functions have no effect in `onDraw`; screen drawing functions have no effect in `onTick`. Read inputs into deliberate globals in `onTick`, then draw those snapshots.
- Globals survive between callbacks while the vehicle remains spawned. The Lua environment starts fresh after despawn/respawn, so globals are not durable storage.
- The code executes in a sandbox with a small global/library surface. Do not assume ordinary desktop Lua facilities.
- The official help warns of a maximum execution time of 1000 ms, but code far below that can still harm simulation performance. Keep per-tick work bounded.
- The in-game Lua editor commonly enforces a 4096-character source limit. Confirm the current counter. External tools can combine/minify readable source, but the final pasted script must fit.

## Available core surface

### Composite I/O

Indexes are 1 through 32. Numeric and Boolean channels are separate, so both may use the same index.

```lua
local n = input.getNumber(index)
local b = input.getBool(index)
output.setNumber(index, value)
output.setBool(index, value)
```

Read each input once near the start of `onTick`. Write outputs explicitly every tick. Do not rely on an old output value remaining safe.

### Microcontroller properties

Labels are case-sensitive and must exactly match property components in the microcontroller.

```lua
local gain = property.getNumber("Gain")
local enabled = property.getBool("Enabled")
local title = property.getText("Title")
```

Read properties in `onTick` or at initialization. A default zero/false/empty result can be indistinguishable from a missing/misspelled label, so document every property.

### Drawing

```lua
screen.setColor(r, g, b)             -- each 0..255
screen.setColor(r, g, b, a)          -- optional alpha 0..255
screen.drawClear()
screen.drawLine(x1, y1, x2, y2)
screen.drawCircle(x, y, radius)
screen.drawCircleF(x, y, radius)
screen.drawRect(x, y, width, height)
screen.drawRectF(x, y, width, height)
screen.drawTriangle(x1, y1, x2, y2, x3, y3)
screen.drawTriangleF(x1, y1, x2, y2, x3, y3)
screen.drawText(x, y, text)
screen.drawTextBox(x, y, w, h, text, h_align, v_align)
screen.drawMap(map_x, map_y, zoom)
local w = screen.getWidth()
local h = screen.getHeight()
```

The built-in text glyph is 4 pixels wide by 5 pixels tall. `drawTextBox` alignment parameters range from -1 through 1. Design in normalized coordinates or compute layout from `w` and `h`; do not assume one monitor resolution.

Map palette functions, with optional alpha, are:

```lua
screen.setMapColorOcean(r,g,b,a)
screen.setMapColorShallows(r,g,b,a)
screen.setMapColorLand(r,g,b,a)
screen.setMapColorGrass(r,g,b,a)
screen.setMapColorSand(r,g,b,a)
screen.setMapColorSnow(r,g,b,a)
screen.setMapColorRock(r,g,b,a)
screen.setMapColorGravel(r,g,b,a)
```

These colors do not apply to the Moon map according to the v1.15.20 help text.

### Map coordinate conversion

```lua
local world_x, world_y = map.screenToMap(
    map_x, map_y, zoom, screen_w, screen_h, pixel_x, pixel_y)

local pixel_x, pixel_y = map.mapToScreen(
    map_x, map_y, zoom, screen_w, screen_h, world_x, world_y)
```

Use exactly the same center, zoom and screen dimensions for drawing and hit testing. Clamp zoom to the documented range, 0.1 through 50.

### Loopback HTTP telemetry

The vehicle Lua API can send an HTTP GET request to localhost on a port. The request body/path must begin with `/`.

```lua
async.httpGet(8080, "/telemetry?rps=" .. tostring(engine_rps))

function httpReply(port, request_body, response_body)
    last_reply = response_body
end
```

This is not general internet access. A service must be listening on the same machine. Requests are asynchronous; correlate replies with request data, rate-limit calls, handle missing/late replies, and never put control-loop safety behind HTTP.

### Lua language/library subset

The official help lists global `pairs`, `ipairs`, `next`, `tostring`, and `tonumber`, plus selected `math`, `table`, and `string` libraries. Treat Lua 5.3 syntax as a guide but verify functions in the Stormworks sandbox. Do not emit `require("screen")`; Stormworks API tables are already globals, and ordinary module loading is unavailable in a pasted microcontroller unless an external build tool replaces it before export.

Common unavailable assumptions include `io`, `os`, `package`, filesystem access, sockets, native modules, and `print`. Do not assume `debug`, `load`, `dofile`, metatable tricks, or a complete `utf8` library.

## Touchscreen input contract

The monitor's composite output uses these standard channels:

| Namespace | Channel | Meaning |
| --- | ---: | --- |
| Number | 1 | monitor resolution X |
| Number | 2 | monitor resolution Y |
| Number | 3 | input 1 X |
| Number | 4 | input 1 Y |
| Number | 5 | input 2 X |
| Number | 6 | input 2 Y |
| Boolean | 1 | input 1 pressed |
| Boolean | 2 | input 2 pressed |

Separate "pressed", "just pressed", "held", and "just released". A button action usually belongs on the rising edge:

```lua
local previous_press = false
local touch_x, touch_y, pressed, clicked = 0, 0, false, false

local function inside(px, py, x, y, w, h)
    return px >= x and py >= y and px < x + w and py < y + h
end

function onTick()
    touch_x = input.getNumber(3)
    touch_y = input.getNumber(4)
    pressed = input.getBool(1)
    clicked = pressed and not previous_press

    if clicked and inside(touch_x, touch_y, 2, 2, 28, 10) then
        -- one action per press
    end

    previous_press = pressed
end
```

Using coordinates without the pressed Boolean can create false touches at `(0,0)`. For multi-monitor setups, confirm which monitor's touch composite feeds the controller and whether a single Lua video output is being drawn at multiple dimensions.

## Recommended program shape

Use readable source during development:

```lua
-- Channel manifest
local IN_ENABLE = 1          -- Boolean 1
local IN_MEASUREMENT = 1     -- Number 1
local OUT_COMMAND = 1        -- Number 1

-- Deliberate state shared with onDraw
local command = 0
local measurement = 0
local status = "OFF"

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function valid(x)
    return x == x and math.abs(x) < 1e300
end

function onTick()
    local enable = input.getBool(IN_ENABLE)
    measurement = input.getNumber(IN_MEASUREMENT)

    if not enable or not valid(measurement) then
        command = 0
        status = valid(measurement) and "OFF" or "SENSOR"
    else
        command = clamp(measurement, -1, 1)
        status = "RUN"
    end

    output.setNumber(OUT_COMMAND, command)
end

function onDraw()
    local w, h = screen.getWidth(), screen.getHeight()
    screen.setColor(8, 12, 18)
    screen.drawClear()
    screen.setColor(230, 240, 255)
    screen.drawText(2, 2, status)
    screen.drawTextBox(2, 10, w - 4, h - 12,
        string.format("IN %.2f\nOUT %.2f", measurement, command), -1, -1)
end
```

If `string.format` is not supported in the user's version/toolchain, replace it with rounded numeric concatenation. Verify the final code in game.

## Channel-manifest template

Provide a table like this with every generated controller:

| Namespace | Channel | Name | Unit/range | Source or destination | Fail value |
| --- | ---: | --- | --- | --- | --- |
| Boolean in | 1 | Enable | false/true | Key button | false |
| Number in | 1 | Measured RPS | RPS, >=0 | Engine crankshaft | 0 |
| Number out | 1 | Throttle | 0..1 | Engine throttle | 0 |

For packed composite protocols, reserve ranges by subsystem and define a protocol version channel. Never silently reuse a channel.

## State and reliability

- Explicitly initialize state; first-tick input may be zero before connected devices settle.
- Add startup grace only where safe. A grace period must not suppress a real emergency.
- Distinguish sensor zero from unavailable zero when the device provides a validity Boolean.
- Use timeouts for radar/radio/remote commands. On timeout, hold, decay, stop, or hand back to manual according to risk.
- Avoid unbounded tables for tracks/history. Use fixed arrays/ring buffers and cap target counts.
- Do not use `#table` or `ipairs` on sparse channel/track tables. Use `pairs` or an explicit count.
- Avoid random decisions in multiplayer; the official help warns that randomness can cause desync.
- For durable state, place critical memory outside Lua in logic memory registers, or accept reset-on-respawn behavior.

## Numeric and angular helpers

Stormworks commonly expresses headings and sensor angles in turns. Convert only after confirming the sensor tooltip:

```lua
local TAU = math.pi * 2

local function turnsToRadians(turns)
    return turns * TAU
end

local function wrapTurns(turns)
    return (turns + 0.5) % 1 - 0.5
end

local function wrapRadians(radians)
    return (radians + math.pi) % TAU - math.pi
end
```

Use the shortest signed heading error: `wrapTurns(target - current)`. If the vehicle steers the wrong way, first verify sensor/actuator sign and mounting orientation; do not immediately negate random terms in the controller.

## Display design rules

- Clear the full screen before drawing a frame unless a deliberate persistence effect is wanted.
- Set color before every logical group; color state persists within the draw call.
- Keep essential state readable on small monitors. Use text sparingly because the font is fixed and tiny.
- Clip or bounds-check manually; primitives can draw outside the intended panel.
- Store control state in `onTick`; `onDraw` should be idempotent for the same snapshot.
- Use map conversion APIs for markers and touch selection instead of hand-derived map scaling.
- For camera overlays, route camera video and Lua/video switch or composition according to actual component capabilities; Lua does not read camera pixels.

## Character-budget strategy

1. Build and test descriptive source outside the game.
2. Remove dead features and duplicated logic before golfing identifiers.
3. Reuse small helpers only when they actually save final characters.
4. Minify with a Stormworks-aware tool; generic minifiers may alter semantics.
5. Count the final exported string and paste-test it in the in-game editor.
6. Keep the readable source as the canonical version. Never maintain only the minified output.

## Exact API source

- Extracted v1.15.20 vehicle help: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/vehicle_help.md
- Versioned documentation archive: https://github.com/gcrtnst/sw-luadocs/tree/main/data
- Current microcontroller documentation portal: https://stormworks.uk/api/microcontroller/intro/
- Current function index: https://stormworks.uk/api/microcontroller/functions/
- Lua 5.3 manual for language semantics, subject to sandbox limits: https://www.lua.org/manual/5.3/
