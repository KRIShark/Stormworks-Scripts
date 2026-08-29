# Engineering and control patterns

Use these patterns after establishing the exact I/O contract. Stormworks component behavior changes; formulas are reliable only when their input units and signs match the installed component tooltip.

## Universal control-system checklist

For every closed loop identify:

- controlled variable: heading, altitude, depth, speed, RPS, temperature, pressure, position, charge, etc.;
- setpoint and its units;
- measured value, validity, resolution, noise and update cadence;
- signed error definition;
- actuator command range, dead zone, rate, authority and saturation;
- plant delay/inertia and external disturbances;
- enable/manual/fault modes;
- what happens at startup, sensor loss, power loss, saturation, respawn and unload.

Build in this order: manual actuator test, sensor display, signed proportional control, damping, integral only if steady-state error remains, mode transitions, safety and tuning.

## Normalization and unit conversions

```lua
local TAU = math.pi * 2

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function wrapTurns(x)
    return (x + 0.5) % 1 - 0.5
end

local function wrapRadians(x)
    return (x + math.pi) % TAU - math.pi
end

local function lerp(a, b, t)
    return a + (b - a) * t
end
```

Conversions:

- `degrees = turns * 360`
- `radians = turns * 2*pi`
- `km/h = m/s * 3.6`
- `knots = m/s * 1.943844`
- `RPM = RPS * 60`
- `seconds = ticks / 60` under normal time; addon code should accumulate `game_ticks`

Convert at the boundary and keep one internal unit per quantity. Put the unit in the variable name when ambiguity is likely: `heading_turns`, `yaw_rad_s`, `speed_mps`.

## Sign and orientation calibration

Do not tune around an unknown sign. Perform controlled tests:

1. Place the vehicle facing map north and read compass/physics orientation.
2. Rotate about 90 degrees to the right and record which values increase/decrease.
3. Command a small positive actuator value and observe the physical direction.
4. Move north/east/up and observe GPS/altitude axes.
5. Record sensor mounting orientation and body relationship.

Then define named sign constants, for example `YAW_SENSOR_SIGN` and `RUDDER_SIGN`. If a loop diverges instantly, recheck signs before lowering gains.

## PID and PD control

### Discrete controller

For a normal microcontroller tick, `dt` is approximately `1/60`. Use this structure conceptually:

```text
error = wrapped_or_linear(setpoint - measurement)
integral = clamp(integral + error * dt, integral_min, integral_max)
derivative = (error - previous_error) / dt
command = clamp(kp*error + ki*integral + kd*derivative, out_min, out_max)
```

Practical improvements:

- Use wrapped error for cyclic angles.
- Reset/freeze integral when disabled, sensor invalid, actuator saturated in the error direction, or mode changes make old integral irrelevant.
- Derivative on measurement reduces derivative kick after setpoint steps: `d = -(measurement - previous_measurement)/dt`.
- Low-pass noisy derivative: `d_filtered = d_filtered + alpha*(d-d_filtered)`.
- Apply output rate limiting for slow pivots/throttles.
- Blend manual and automatic modes without a command jump (bumpless transfer).
- If the actuator has deadband, compensate carefully after the controller, not by inflating integral.

### Tuning

1. Set I and D to zero.
2. Raise P until response is firm but not continuously oscillating.
3. Add D/damping to reduce overshoot and motion-rate sensitivity.
4. Add a small I only for persistent bias such as wind, trim or load.
5. Test saturation, large setpoint changes, zero speed, high speed, full/empty fuel, and rough conditions.

One gain set rarely suits every speed. Aircraft/boat control may need gain scheduling by airspeed/water speed or dynamic pressure proxy. Clamp scheduling inputs and provide a low-speed fallback.

## State machines

Use explicit modes instead of interdependent Booleans:

```text
OFF -> STARTING -> RUNNING -> STOPPING
                    |  |
                    |  +-> DEGRADED
                    +----> FAULT
```

For each transition define trigger, guard, actions, timeout and recovery. Examples:

- `OFF -> STARTING`: enable rising edge and no latched fault.
- `STARTING -> RUNNING`: RPS above threshold for a confirmation interval.
- `STARTING -> FAULT`: timeout, over-temperature or invalid sensor.
- `RUNNING -> DEGRADED`: generator or secondary sensor loss.
- `FAULT -> OFF`: explicit reset after cause is safe.

Outputs should derive primarily from the current state. This prevents combinations such as starter on, clutch fully engaged and emergency stop active simultaneously.

## Filtering and validity

### Exponential smoothing

```lua
filtered = filtered + alpha * (measurement - filtered)
```

`alpha` near 1 follows quickly; near 0 smooths heavily. A fixed per-tick alpha changes behavior if the update cadence changes. For variable elapsed seconds `dt`, use `alpha = 1 - exp(-dt/tau)` if `math.exp` is available.

### Median/outlier and track gating

- Reject values outside physical bounds.
- Compare innovation `abs(measurement - prediction)` to a speed/noise-dependent gate.
- Require several valid samples before declaring a track/sensor healthy.
- Keep last valid value only for a bounded timeout, then enter a defined loss mode.
- Do not average wrapped angles linearly across the -0.5/0.5 turn boundary; average unit vectors or unwrap first.

### Invalid values

Reject NaN (`x ~= x`), implausibly large magnitudes, negative distances where impossible, and divisors near zero. If one sensor is invalid, decide whether to stop, degrade, substitute, or hand over to manual control.

## Navigation and guidance

### Position and bearing

For map-plane positions, let `dx = target_x - current_x` and `dy = target_y - current_y`. Distance is:

```lua
distance = math.sqrt(dx*dx + dy*dy)
```

The correct `atan` argument order and compass sign must be verified with the installed Lua and sensor orientation. Lua 5.3 defines two-argument `math.atan(y, x)`, while many Stormworks examples alias/map axes differently. Calibrate north/east before fixing:

```lua
target_bearing_turns = math.atan(dx, dy) / (math.pi * 2) -- candidate convention
heading_error_turns = wrapTurns(target_bearing_turns - heading_turns)
```

If east/west is mirrored, correct the documented sensor/sign transform, not the wrapped-error function.

### Waypoint steering

- Slow as distance shrinks to prevent orbiting.
- Use a waypoint acceptance radius and hysteresis.
- Limit turn command at low speed where rudder/steering authority differs.
- For boats/aircraft, use cross-track error to a route leg rather than always pointing directly at the endpoint.
- Include manual override, route cancel, target-loss behavior and arrival mode.

### Altitude/depth hold

Cascade loops when possible:

```text
altitude error -> desired vertical speed -> pitch/collective/ballast command
```

The inner rate loop damps motion; the outer position loop can stay slower. Clamp desired vertical speed and actuator output. Depth sign and pressure/altimeter reference must be verified.

### Attitude hold

Use roll/pitch/yaw error plus measured angular rate. At low forward speed, control surfaces may have no authority; rotors/thrusters need separate mixing. Limit combined axis commands so one saturated axis does not starve the others.

## Radar and sonar

Modern radar commonly emits repeated target records through composite data. A common current layout per target is distance, azimuth, elevation and time-since-detection in four number channels, plus a validity Boolean. Verify the exact component tooltip, mode and target count before coding.

### Polar to local Cartesian

If azimuth/elevation are in turns and the radar frame defines forward as local Y, right as local X and up as local Z, a common conversion is:

```lua
local az = azimuth_turns * TAU
local el = elevation_turns * TAU
local horizontal = math.cos(el) * distance
local right = math.sin(az) * horizontal
local forward = math.cos(az) * horizontal
local up = math.sin(el) * distance
```

The axes and signs are mounting-dependent. Transform the local vector using the vehicle's right/forward/up basis and add the radar world position. Test a stationary target directly ahead, right, above and behind.

### Tracking

For each valid detection:

1. Convert to a consistent coordinate frame.
2. Predict existing tracks to current time.
3. Associate by gated distance/bearing; do not assume radar slot order is identity.
4. Smooth/update position and estimate velocity.
5. Increment hit confidence and reset age.
6. Age unmatched tracks and delete after a bounded timeout.

Use fixed maximum track counts. A track needs a stable internal ID independent of the sensor's output slot.

### Measured radar behavior

Community measurements document angular and distance noise, range/FOV tradeoffs and update cadence. These are empirical, patch-sensitive findings, not guaranteed API contracts. The referenced study reports approximately +/-0.001 turns angular noise, +/-1% range noise, and slower position updates at large configured range. Verify on the user's version before using its formulas for fire control or tight guidance.

Reference: https://github.com/LaurinMeier/Stormworks-Radar-Documentation

### Fire control

Separate detection/tracking, target selection, lead solution, stabilization, weapon constraints and firing authorization. Validate muzzle velocity/drag against the current weapon. Require Search and Destroy DLC for functional weapons. Never fire merely because a target record exists; require validity, identification, range/elevation constraints, clear authorization and timeout.

## Engine and drivetrain control

### Prefabricated engine controller

Minimum modes: off, cranking, running and fault. Inputs usually include enable, RPS, temperature, battery/generator and desired power. Outputs include starter, engine throttle, clutch and possibly pumps/fans.

- Crank with clutch released and safe throttle.
- Stop starter after sustained running RPS; add restart hysteresis.
- Engage clutch gradually or according to RPS/load.
- Reduce load/throttle and alarm before over-temperature shutdown if mission safety permits.
- Avoid rapid start/stop chatter with timers and hysteresis.

### Modular engine ECU

Coordinate air manifold, fuel manifold, starter, clutch, cooling and target RPS/power. Read cylinder/manifold telemetry where available. Exact optimal air:fuel ratio and temperature behavior are patch-sensitive; do not hardcode an old community value as universal.

Useful controller layers:

1. State machine for off/crank/run/cooldown/fault.
2. Air/throttle loop for target RPS or requested power.
3. Fuel command derived from measured air/desired mixture with clamps.
4. Idle governor to prevent stalls.
5. Temperature/load limiting.
6. Clutch/load ramp and gearbox command.

Validate naturally aspirated and pumped air separately. More air can increase power and heat and changes mixture calculation.

### Gearboxes and clutches

- Gearbox orientation changes which side receives the selected multiplication/reduction; bench-test the arrow direction with known RPS.
- A modular clutch's transmitted behavior is nonlinear; the community technical reference describes an `x^3` relationship and suggests cube-root compensation where linear feel is wanted.
- Shift only when conditions are safe: speed/RPS window, unloaded or reduced clutch, debounce and hysteresis.
- For generators, choose gear ratio to place generator RPS in a useful band without stalling the engine.

## Aircraft and rotorcraft

- Fixed-wing: establish centre of mass, lift and thrust alignment; tune roll/pitch/yaw at several airspeeds. Use coordinated-turn/yaw damping if required.
- Helicopter: separate rotor RPS governor from collective; use cyclic for pitch/roll and yaw control for torque reaction. Start with manual hover trim.
- VTOL: use a mode/state machine for hover, transition and forward flight. Schedule control mixing; do not abruptly switch actuator sets.
- Autopilot must disengage cleanly on manual override and invalid attitude/altitude inputs.

## Boats and submarines

- Boat steering effectiveness depends on speed and propulsor/rudder placement. Add yaw-rate damping and low-speed differential thrust if available.
- Stabilizers should not fight manual turn commands; bias target roll based on turn state when appropriate.
- Ballast systems need fill/empty rate, pump pressure, tank capacity and a neutral-buoyancy trim strategy.
- Depth hold works better as depth -> vertical-speed -> ballast/planes/thrusters. Add surface/bottom limits and flood/emergency-blow behavior.
- Sonar bearing/range behavior and passive/active modes differ; verify channel map and DLC/component settings.

## Ground vehicles and trains

- Convert steering/throttle into left/right commands with saturation-aware mixing.
- Reduce steering sensitivity with speed and include brake/reverse state logic.
- Wheel slip requires comparing driven-wheel or RPS-derived speed with measured vehicle speed; filter both.
- Track and train wheel mechanics are component- and patch-sensitive. Test gearing, wheel contact, braking and articulation under load.

## Power management

Create a power budget with average and peak loads. At runtime track battery charge, generator output/proxy, engine/motor state and critical consumers.

Suggested priority:

1. Control computer and essential sensors.
2. Flight/steering/ballast actuators.
3. Navigation and safety lighting/communications.
4. Mission equipment.
5. Comfort/decorative loads.

Use low-charge warnings, automatic generation start if appropriate, and staged load shedding with hysteresis. Never oscillate a heavy load on/off at the threshold every tick.

## Composite and radio protocols

Define a versioned packet/channel manifest:

| Field | Number/Boolean channel | Unit/range | Update rate | Timeout/default |
| --- | --- | --- | --- | --- |
| Protocol version | Number 1 | integer | every tick | reject unknown |
| Sequence | Number 2 | integer | every packet | detect stale |
| Command | Number 3 | -1..1 | every tick | 0 after timeout |
| Valid | Boolean 1 | Boolean | every tick | false |

For radio, also define frequency, transmit enable, addressing, sender ID, checksum/validation if needed, duplicate handling and failsafe. Do not trust a received command solely because a signal exists; validate origin/protocol where the design permits.

## Safety architecture

Keep independent hard limits outside complex automation where practical:

- emergency stop/master cutoff;
- over-temperature/over-speed trip;
- manual clutch/throttle/steering fallback;
- actuator clamps and rate limits;
- sensor timeout/validity;
- watchdog heartbeat between controllers;
- latched fault with explicit reset;
- alarms that distinguish warning, degraded and shutdown.

The safe state depends on the vehicle. Zero throttle may be safe for a docked boat but unsafe for a hovering helicopter; define the context-specific fallback.
