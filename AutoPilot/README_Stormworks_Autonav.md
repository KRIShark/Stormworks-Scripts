# Stormworks Autonav System

A two-part Stormworks navigation and autopilot setup built around **one control microcontroller** and **one display microcontroller**.

The control microcontroller handles all vehicle guidance logic. The display microcontroller receives navigation data over a composite bus, receives touchscreen input from the monitor, and outputs video.

---

# 1. System Architecture

```text
                CONTROL MICROCONTROLLER
             GPS / AP / Navigation Logic
                         |
                         |
                    COMPOSITE DATA
                         |
                         v
                DISPLAY MICROCONTROLLER
              Airbus-style NAV Display
                         |
              +----------+----------+
              |                     |
        Monitor Touch           Video Output
              ^                     |
              |                     v
          MONITOR <-----------------+
```

The two controllers are intentionally separated:

- **Control MC** = vehicle logic and autopilot
- **Display MC** = navigation display and touchscreen UI

This keeps the control system independent from screen size, screen layout, or later UI changes.

---

# 2. Control Microcontroller

The control controller performs:

- GPS delta calculation
- Target distance
- Target bearing
- Current heading conversion
- Heading error wrapping
- Steering command
- Steering smoothing
- Automatic throttle
- Slowdown near target
- Arrival detection
- Manual/autopilot selection
- Navigation data output for the display

## Inputs

```text
NUMBER
1 GPS X
2 GPS Y
3 Target X
4 Target Y
5 Compass
6 Speed
7 Manual Steering
8 Manual Throttle

BOOL
1 Autopilot Enable
2 Emergency Cancel
```

## Direct control outputs

```text
NUMBER
1 Steering
2 Throttle

BOOL
1 Target Reached
2 Autopilot Active
3 Arriving
4 Emergency Cancel
```

---

# 3. Navigation Data Composite Bus

The display should not recalculate navigation logic. The control controller sends the processed navigation state over a composite connection.

## Number channels

```text
1  GPS X
2  GPS Y
3  Target X
4  Target Y
5  Heading degrees
6  Bearing degrees
7  Distance metres
8  Heading Error degrees
9  Speed
10 Steering Command
11 Throttle Command
12 Target Delta X
13 Target Delta Y
```

## Boolean channels

```text
1 Autopilot Active
2 Target Reached
3 Arriving
4 Emergency Cancel
```

---

# 4. Display Microcontroller

The display controller only handles presentation and touch input.

It receives:

```text
NAV DATA COMPOSITE
MONITOR TOUCH COMPOSITE
```

and outputs:

```text
VIDEO
```

The display is designed to scale dynamically using:

```lua
w = screen.getWidth()
h = screen.getHeight()
```

so the layout does not depend on one fixed Stormworks monitor resolution.

---

# 5. Display Composite Layout

Because the navigation bus and the monitor touch composite both use low-numbered channels, remap the touch channels before sending them into the Lua block.

Recommended internal Lua channel map:

## Navigation data

```text
Number 1  GPS X
Number 2  GPS Y
Number 3  Target X
Number 4  Target Y
Number 5  Heading
Number 6  Bearing
Number 7  Distance
Number 8  Heading Error
Number 9  Speed
Number 10 Steering
Number 11 Throttle
Number 12 Delta X
Number 13 Delta Y
```

## Touch data

```text
Number 21 Screen Width
Number 22 Screen Height
Number 23 Touch X
Number 24 Touch Y
Number 25 Touch 2 X
Number 26 Touch 2 Y

Bool 21 Touch 1
Bool 22 Touch 2
```

## Navigation booleans

```text
Bool 1 AP Active
Bool 2 Target Reached
Bool 3 Arriving
Bool 4 Emergency
```

---

# 6. Display MC Wiring

```text
                DISPLAY MICROCONTROLLER

 NAV DATA COMPOSITE
         |
         v
 +----------------+
 | Composite Read |
 +----------------+
         |
         | Navigation channels
         |
         v
 +----------------+
 | Composite Write|
 | CH 1 ... 13    |
 +----------------+
         |
         +-------------------+
                             |
                             v
                         LUA BLOCK
                             |
                             +-------- VIDEO --------> Monitor
                             ^
                             |
         +-------------------+
         |
 +----------------+
 | Composite Write|
 | CH 21 ... 26   |
 +----------------+
         ^
         |
 +----------------+
 | Composite Read |
 +----------------+
         ^
         |
 MONITOR TOUCH COMPOSITE
```

Boolean touch remapping:

```text
Monitor BOOL 1
      |
      v
Display Lua BOOL 21
```

This prevents channel collisions between navigation data and monitor touch data.

---

# 7. Full Vehicle Data Flow

```text
 GPS X -------\
 GPS Y --------\
 Target X ------\
 Target Y -------\
 Compass ---------> [ NAV COMPUTER ]
 Speed -----------/       |
 Manual Steering-/        |
 Manual Throttle-/        |
 AP Enable ------/        |
                         |
             +-----------+-----------+
             |                       |
             v                       v
          Steering               NAV DATA
          Throttle             COMPOSITE BUS
                                     |
                                     |
                                     v
                           [ DISPLAY COMPUTER ]
                                     ^
                                     |
                              TOUCH COMPOSITE
                                     |
                                  MONITOR
                                     ^
                                     |
                                   VIDEO
```

---

# 8. Navigation Display Concept

The main display follows a simplified Airbus-inspired navigation-display style.

```text
                07   08   09
             |    |  ^ |    |
                  <> BRG
+--------------------------------+
| AP                         084 |
|                                |
|                O WP            |
|               /                |
|              /                 |
|             /                  |
|            -+-                 |
|             |                  |
|             |                  |
|                                |
|--------------------------------|
| DST         SPD            ERR |
| 1.2KM       18.3           +12 |
+--------------------------------+
```

Suggested display language:

```text
WHITE
Heading scale / labels

CYAN
Selected target bearing
Navigation information

MAGENTA
Active route to waypoint

GREEN
Active autopilot / valid active values

YELLOW
Ownship symbol

AMBER
Manual / inactive / warning state
```

The aim is not a pixel-perfect Airbus reproduction. It is a compact Stormworks-friendly navigation display using recognizable aviation display conventions.

---

# 9. Dynamic Screen Behaviour

The display scales from the actual screen size.

Example:

```lua
cx = w / 2
cy = h * 0.55

mapRadius = math.min(
    w * 0.42,
    h * 0.35
)
```

Touch regions are also relative to monitor width and height rather than fixed pixel coordinates.

Example bottom bar:

```text
+------------------------------------------+
|                                          |
|               NAV DISPLAY                |
|                                          |
|                                          |
|------------------------------------------|
|  RNG-       |       DATA       |   RNG+  |
+------------------------------------------+
```

The screen should therefore remain usable on different monitor sizes, although extremely small monitors may need a dedicated compact layout later.

---

# 10. Display Pages

Current planned pages:

## NAV

Primary navigation display with:

- heading tape
- aircraft symbol
- waypoint
- route line
- AP state
- bearing
- distance
- speed
- heading error
- range control

## DATA

Diagnostic page showing values such as:

```text
HDG   084
BRG   096
DST   1.2K
SPD   18.3
STR   +0.24
```

---

# 11. Touch Controls

Initial touchscreen controls:

```text
RNG-   decrease display range
DATA   switch to data page
NAV    switch back to navigation page
RNG+   increase display range
```

Recommended range options:

```text
250 m
500 m
1 km
2 km
5 km
10 km
20 km
```

The touch controller should use a rising-edge check so holding a button does not repeatedly trigger it every game tick.

Conceptually:

```lua
newTouch = touch and not lastTouch
lastTouch = touch
```

---

# 12. Future Bidirectional Bus

A useful later upgrade is a second composite connection from the display back to the control controller.

```text
CONTROL MC  -------- NAV DATA --------> DISPLAY MC
CONTROL MC  <----- DISPLAY COMMANDS --- DISPLAY MC
```

Possible display commands:

```text
AP toggle
Next waypoint
Previous waypoint
Direct-to
Stop
Hold
Waypoint select
Cruise speed select
Arrival radius select
```

This keeps display commands separate from the navigation-data bus.

---

# 13. Recommended Development Order

```text
1. Build and test Control MC
2. Verify bearing orientation
3. Verify steering sign
4. Verify target arrival detection
5. Connect NAV DATA composite
6. Build Display MC channel remapping
7. Verify NAV page values
8. Verify touch input
9. Test several monitor sizes
10. Add bidirectional display commands
11. Add waypoint sequencing
12. Add route planning / advanced AP modes
```

---

# 14. Important Calibration Notes

Stormworks vehicle wiring can reverse expected steering or heading directions depending on sensor/component orientation.

Keep separate settings for:

```lua
COMPASS_SIGN = 1
STEERING_SIGN = 1
```

If heading is reversed:

```lua
COMPASS_SIGN = -1
```

If only the vehicle steering response is reversed:

```lua
STEERING_SIGN = -1
```

Do not invert both unless both behaviours are actually reversed.

---

# 15. Project Goal

The final system should behave like a small integrated navigation suite:

```text
Sensors / GPS
      |
      v
Navigation + Autopilot Computer
      |
      +------ Vehicle Control
      |
      +------ Navigation Data Bus
                    |
                    v
             Navigation Display
                    ^
                    |
                Touchscreen
```

This structure is intentionally modular so additional displays, waypoint controllers, route computers, radar pages, or other avionics can be added later without rewriting the core autopilot.
