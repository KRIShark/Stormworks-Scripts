# Component-mod Lua

Component modding is a third Stormworks scripting environment, distinct from both vehicle microcontrollers and addon/server Lua. It was introduced in the v1.15.0 Components, Physics, Gameplay Modding major update. Use it only when the user is creating or changing a custom vehicle component.

Component mods can define meshes, physics/component configuration and Lua behavior. They operate close to the simulation and can easily destabilize physics or performance. Work from a copy, validate incrementally, and expect game updates to affect undocumented fields.

## Runtime boundary

Typical callbacks in the v1.15.0 component Lua API are:

```lua
function onAddToSimulation() end
function onRemoveFromSimulation() end
function onParse() end
function onTick(tick_time) end
function onRender() end
```

- `onAddToSimulation`: component becomes active in simulation; acquire runtime state.
- `onRemoveFromSimulation`: component leaves simulation; stop effects/bridges and release transient state.
- `onParse`: component save/load parsing work.
- `onTick(tick_time)`: bounded simulation logic. `tick_time` is usually 1; treat it as elapsed ticks.
- `onRender`: rendering only. Do not move simulation logic into the render callback.

Do not emit `server.*`, `screen.*`, `input.getNumber`, or microcontroller callbacks here.

## API families

Use the maintained intellisense source for exact signatures and return values.

### Parser

```lua
parser.parseBool(id, value)
parser.parseNumber(id, value)
parser.parseString(id, value)
```

Validate parse success and provide safe defaults. Treat authored configuration text as untrusted input.

### Matrix

The component environment documents identity, translation, X/Y/Z rotations, multiply, transpose, position, distance, `rotationToFaceXZ`, and homogeneous vector multiplication. Note that the typed component reference spells the latter `matrix.multiplyxyzw`; do not substitute the addon's differently cased spelling without verifying the current API.

### Logic slots

```lua
component.getInputLogicSlotBool(index)
component.setOutputLogicSlotBool(index, value)
component.getInputLogicSlotFloat(index)
component.setOutputLogicSlotFloat(index, value)
component.getInputLogicSlotComposite(index)
component.setOutputLogicSlotComposite(index, composite)
```

Logic slot indexes belong to the component definition, not microcontroller composite channel numbers. Define a slot manifest with direction, type and meaning. Validate composite shapes and fill all required output fields every tick.

### Mechanical torque slots

The API can inspect connections, apply momentum, create/destroy bridges, and set bridge factor/ratio. These operations directly affect drivetrain simulation:

- guard zero/negative/invalid mass, RPS and ratios;
- clamp control factors;
- create each bridge once, destroy it in lifecycle cleanup;
- avoid abrupt nonphysical energy creation;
- test stall, disconnect, reverse and extreme RPS cases.

### Fluid systems

The API can resolve flow through slots, resolve flow between slots, transfer volume, set/get fluid type and volume, set/get capacity, and query pressure. A filter and transfer index can affect which fluid moves.

Preserve mass/volume intentionally. Bound transfer by source inventory, destination capacity and valid flow. Define one-way direction, accepted fluid types, pressure response and mixed-fluid behavior. Test empty/full, gas/liquid, wrong fluid, reversed connection and unload/reload.

### Electricity

Functions inspect electrical connection, add/remove charge and read the charge factor. Do not create charge without a modeled source or consume negative charge. Clamp storage and make the component's power model visible in its tooltip/configuration.

### Heat and effects

Heater APIs define a sphere or oriented box, temperature and factor. SFX APIs play once/loop, update and stop channels. Ensure looped audio is stopped in `onRemoveFromSimulation`; cap range, volume and update work.

### Rendering

The component API can render component mesh variants, lights and lasers. Rendering belongs in `onRender`. Avoid allocating large tables or doing physics queries per frame. Keep transforms local and verify mirrored components because mirror behavior has received fixes in later updates.

### Physics and projectiles

Available domains include impulses, raycasts, linear/angular velocity, velocity at a point, projectile spawning, submergence and wind velocity.

Physics code must be bounded and stable:

- multiply continuous forces by elapsed time as the API semantics require;
- cap impulses and validate direction vectors;
- avoid feedback that adds energy each tick without damping;
- transform local offsets/directions correctly;
- handle missing raycast hits;
- gate projectile spawning by user intent, cooldown and Search and Destroy/DLC rules where required.

### Debugging

`debug.log(message)` is documented for component mods. It is not proof that a same-named facility exists in vehicle microcontroller Lua. Rate-limit logs; per-tick output can become the performance problem.

## Component development workflow

1. Confirm the installed game version and read the official component-modding page.
2. Start from the closest official/example component definition rather than inventing undocumented XML fields.
3. Add the typed `intellisense.lua` to the editor workspace, but do not ship it as runtime logic.
4. Define slots and static configuration before Lua behavior.
5. Implement lifecycle cleanup before adding physics, effects or bridges.
6. Test one API family at a time with conservative limits.
7. Test mirrored placement, separate physics bodies, damage, save/load, unload/reload, multiplayer and game restart.
8. Recheck patch notes after every game update.

## Delivery checklist

- State target game version and DLC requirements.
- List every file and its destination relative to the mod folder.
- Provide a slot table and configuration schema.
- Explain physical assumptions and limits.
- Include install, remove and rollback instructions.
- Keep original user files and backups intact.
- Warn that multiplayer participants may need matching mods/configuration.
- Do not promise Workshop or server compatibility without an actual test.

## Direct references

- Official Geometa component-modding page: https://geometa.co.uk/wiki/stormworks/view/component_modding
- Official v1.15.0 update announcement: https://store.steampowered.com/news/app/573090/view/534354183830114758
- Maintained typed component API and setup instructions: https://github.com/Cuh4/StormworksModLuaDocumentation
- Exact current intellisense source: https://github.com/Cuh4/StormworksModLuaDocumentation/blob/main/docs/intellisense.lua
- Official issue tracker for current defects: https://geometa.co.uk/support/stormworks/
