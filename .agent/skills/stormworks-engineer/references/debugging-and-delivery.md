# Debugging, review, tools, and delivery

Use this reference when diagnosing a broken creation, reviewing Lua, interpreting a screenshot, or packaging a complete solution.

## Triage order

Ask for or inspect:

1. Exact game version and DLCs.
2. Runtime: microcontroller, addon/server or component mod.
3. Exact error text and when it occurs.
4. Complete Lua source, not only the suspected function.
5. Microcontroller node list and composite channel map.
6. Screenshots of component tooltips/Select settings and logic wiring.
7. Expected versus observed values, including units and signs.
8. Minimal reproduction steps and whether single-player/multiplayer differs.

Then isolate the layer:

| Layer | High-value check |
| --- | --- |
| Syntax/runtime | Wrong API mode, unsupported function, unmatched `end`, nil/global typo, character limit |
| Signal | Wrong Boolean/number namespace, wrong channel, disconnected node, source not powered |
| State | Toggle retriggering while held, uninitialized global, stale output, respawn/reset, old `g_savedata` schema |
| Math | Turns/degrees/radians mismatch, axis/sign inversion, divide by zero, angle wrap, NaN, saturation |
| Control | Actuator reversed, no authority, gain too high, integral windup, sample/update delay |
| Mechanical | Clutch/gearbox direction, stalled engine, propulsor command, separate physics body |
| Fluid/thermal | Wrong fluid, blocked port/filter, pump power/direction, exhaust, pressure, cooling |
| Addon lifecycle | Spawned but not loaded, wrong ID/group, success flag ignored, unloaded object, peer ambiguity |
| Multiplayer | Local non-determinism, authority/permission, unsynchronized internal microcontroller state |

Do not jump to PID tuning until the raw sensor and manual actuator tests pass.

## Microcontroller debugging

Stormworks vehicle Lua has no normal console. Add temporary observability:

- route raw input and intermediate values to spare numeric outputs/dials;
- route validity/mode/faults to Boolean outputs/indicator lights;
- display channel values, state and command on a small monitor;
- add an integer fault code instead of only one generic fault Boolean;
- freeze/cycle through tracked values with touch buttons;
- use localhost `async.httpGet` only for optional telemetry, never as the controller's safety path.

Use a diagnostic mode property so debug output can be disabled. Remove high-frequency HTTP or heavy drawing after diagnosis.

### Binary isolation

1. Replace the actuator command with a safe constant to prove wiring/direction.
2. Display raw sensor value to prove input and unit.
3. Replace the controller with proportional-only logic.
4. Reintroduce filtering, state, I/D terms and automation one at a time.

### Static review checks

- Every `function`, `if`, `for`, `while` and `do` has the correct `end`.
- `onTick`, `onDraw`, and `httpReply` are top-level functions.
- Only supported globals/libraries are used.
- Every channel index is 1..32 and matches the correct namespace.
- Property labels are exact and case-sensitive.
- `onDraw` does not advance state or call input/output APIs.
- Critical outputs are written on all paths.
- Tables/history have hard bounds.
- Final pasted code fits the current editor limit.

## Addon debugging

- Use `?reload_scripts` for controlled live reload; remember it autosaves.
- Send short, rate-limited diagnostics with `server.announce` to the initiating/admin peer rather than all players.
- Prefer `debug.log` only when documented in the current addon API/toolchain; verify rather than inventing it.
- Log lifecycle transitions: create, spawn, load, unload, despawn and migration.
- Check both values from getters returning `is_success`.
- Print or persist the exact vehicle/object/group/peer IDs involved.
- Use default official addons from the installation as examples for complex API usage.

When a getter fails, do not keep operating on the stale ID. Remove/reconcile it after confirming the object's lifecycle.

## Component-mod debugging

- Begin with a component that only logs add/remove/tick/render lifecycle.
- Add one logic slot, then one resource/physics feature at a time.
- Rate-limit `debug.log`.
- Disable impulses, bridges, projectiles, heaters and looped sounds during parser/config diagnosis.
- Verify mirrored placement and cleanup after every feature.
- Keep a known-good unmodified component and mod backup for rollback.

## Reviewing user XML and files

Stormworks stores user content under `%APPDATA%\Stormworks\data` on typical Windows installations. Common subfolders include `vehicles`, `microprocessors`, `missions` and saves, depending on content/version.

- Never directly overwrite the only copy.
- Preserve unknown XML attributes/elements and ordering as much as the editing method permits.
- Prefer editing in the game UI when possible.
- If direct XML editing is necessary, duplicate the exact target first and state the backup location.
- Validate well-formed XML and compare before/after changes.
- Do not claim that XML hacks are supported or multiplayer-safe.

Default addons are commonly under `<SteamLibrary>\steamapps\common\Stormworks\rom\data\missions`. Copy them to the user missions directory before modification.

## Development tool options

These are optional community tools. Check their latest release/activity and inspect code before installation; tool support can lag the game.

### Pony IDE

Browser/offline editor and simulator for vehicle and addon Lua, with monitor/touch simulation, documentation, code history and minification.

https://lua.flaffipony.rocks/

Useful for a fast single-file controller. Simulation does not reproduce every physics or multiplayer behavior; paste-test in game.

### LifeBoatAPI VS Code extension

Provides project scaffolding, combining, minimization, type hints, simulation/debugging and optional libraries for microcontroller Lua.

https://marketplace.visualstudio.com/items?itemName=NameousChangey.lifeboatapi

Repository/issues: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension

`require(...)` in its source is a build-tool feature. Do not paste unresolved `require` calls into the in-game Lua block.

### Stormworks CLI

Standalone Lua-oriented CLI/TUI for microcontroller build, simulation and export:

https://github.com/Chromatischer/stormworks-cli

Check documented Lua/runtime dependencies and current Stormworks compatibility.

### SSSWTool

Addon-oriented multi-file builder with combining, watch mode, optional tracing and generated intellisense:

https://github.com/Avril112113/SSSWTool

Its build actions execute outside a sandbox with the user's normal permissions. Never run untrusted build actions.

### Typed API documentation

- Addon Lua: https://github.com/Cuh4/StormworksAddonLuaDocumentation
- Microcontroller Lua: https://github.com/Cuh4/StormworksMCLuaDocumentation
- Component-mod Lua: https://github.com/Cuh4/StormworksModLuaDocumentation
- Extracted in-game versioned help: https://github.com/gcrtnst/sw-luadocs

Use typed files for autocomplete, not as runtime dependencies.

### Frameworks

Noir is an optional addon Lua framework with services/events and structured project patterns:

https://github.com/cuhHub/Noir

Use a framework only when its lifecycle and abstraction provide clear value. For a small addon, plain documented callbacks may be easier to audit and keep current.

## Verification harnesses

### Pure-function tests

Extract math that does not touch Stormworks globals—wrap, clamp, PID step, polar conversion, association, state transitions—and test it with ordinary Lua 5.3. Test boundary cases and invariants, not only one happy example.

Examples:

- wrapped angle is always in `[-0.5, 0.5)` turns;
- output remains within actuator limits;
- zero/near-zero divisor takes a defined path;
- disabled state always outputs the safe command;
- target age never becomes negative;
- old saved schema migrates without deleting user state.

### API shims

For microcontrollers, a local harness can mock:

```text
input.getNumber/getBool
output.setNumber/setBool
property.getNumber/getBool/getText
screen.getWidth/getHeight and draw calls
```

For addons, mock only the server calls exercised by the unit under test and model failure returns. A mock proves program logic, not Stormworks physics/API integration.

### In-game acceptance test

Provide numbered steps with observable results. Example:

1. Spawn with controller disabled: actuator output/dial reads 0.
2. Enable at rest: state shows STARTING; starter Boolean becomes true.
3. Raise sensor above threshold: starter turns off and state becomes RUNNING.
4. Disconnect sensor: within the documented timeout, state becomes SENSOR FAULT and output takes the defined fallback.
5. Despawn/respawn: state starts from the documented initial state.

## Complete response format

For a build or new script, prefer:

1. Environment and assumptions.
2. Required components.
3. Wiring and composite channel table.
4. Property table.
5. Full Lua source.
6. Builder/setup steps.
7. Calibration/tuning values.
8. Test procedure and expected values.
9. Known limits, DLC and multiplayer notes.
10. Direct links to exact API/help pages.

For a bug diagnosis, prefer:

1. Most likely root cause with evidence.
2. Minimal correction.
3. Corrected complete code if requested.
4. Two or three targeted verification checks.
5. Any remaining assumption that needs a screenshot/value.

## Quality gate before delivery

- Runtime APIs do not cross environments.
- Code and wiring tables agree exactly.
- Units, ranges, axes and signs are declared.
- Startup, disabled, fault and sensor-loss behavior are defined.
- Character/tick/performance limits are addressed.
- Multiplayer and respawn/load behavior are addressed when relevant.
- Version-sensitive facts are cited or clearly marked for verification.
- External tools are optional and linked directly.
- Destructive/admin operations require explicit authorization.
