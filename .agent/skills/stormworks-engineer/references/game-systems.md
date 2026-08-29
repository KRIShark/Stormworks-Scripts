# Stormworks game and vehicle systems

Use this reference for gameplay questions and when Lua is only one part of a vehicle. Values and balance change; verify component tooltips in the user's installed version before asserting an exact numeric specification.

## Mental model

Stormworks: Build and Rescue is a block-based physics sandbox centered on designing, programming, spawning, and operating vehicles. The base game supports custom and career play, missions, multiplayer/co-op, Workshop sharing, severe weather, fire/damage, rescue work, and land/sea/air/submersible vehicles. Vehicles are not a single machine: they are interacting physical bodies and networks.

Treat a build as these coupled layers:

1. Structure and sealed volumes: hull, frames, mass distribution, buoyancy, drag, control surfaces, physics bodies, sub-bodies, pivots, and collision.
2. Mechanical power: engine or motor RPS, torque/inertia behavior, clutches, gearboxes, shafts, generators, propellers, wheels, tracks, rotors, ducted fans, and pumps.
3. Fluids and gases: tanks/custom tanks, ports, pipes, pumps, valves, filters/manifolds, fuel, air, exhaust, coolant, water, steam, gases, pressure, and temperature.
4. Electricity: generation, batteries, distribution, starters, motors, pumps, sensors, lights, radios, displays, and logic consumers.
5. Logic and data: Boolean, number, composite, video, and audio connections; microcontroller properties and Lua.
6. Control and HMI: seats, throttles, buttons, keypads, instrument panels, monitors, HUDs, cameras, audio, and warnings.
7. Mission/world integration: workbenches, cost, range, fuel, repair, rescue equipment, cargo, environment, multiplayer, and addon rules.

A symptom in one layer may originate in another. Low propeller thrust can be caused by engine air/fuel/cooling, clutch engagement, gearbox direction, electric starvation, propeller collective, an inappropriate propulsor, or the propulsor being out of its medium.

## Important units and conventions

The game uses metric-looking units but not all internal quantities map cleanly to real-world SI.

| Quantity | Practical convention |
| --- | --- |
| Builder voxel | 0.25 m per side; four blocks are one metre |
| Linear speed | Usually m/s; multiply by 3.6 for km/h and about 1.94384 for knots |
| Distance | metres |
| Rotational speed | RPS (rotations per second), not RPM; `RPM = RPS * 60` |
| Fluid volume | litres; one fully enclosed voxel is geometrically 15.625 L |
| Fluid flow | commonly L/s |
| Temperature | degrees Celsius |
| Navigation angles | many vehicle sensors use turns/revolutions rather than radians or degrees; inspect tooltip |
| World transform | addon matrices use X/Z as the horizontal plane and Y as vertical |
| Map/GPS naming | vehicle GPS/map APIs often present horizontal coordinates as X/Y even though addon world matrices call the second horizontal axis Z |
| Logic time | commonly 60 logic ticks per second under normal simulation; addon `game_ticks` accounts for sleep acceleration |
| Electricity/mass/torque | game-specific behavior; avoid claiming SI equivalence without a current measured source |

Do not conflate Stormworks' torque sensor reading with physical torque. The community technical reference describes it as closer to system resistance/inertia. Use RPS, generator output, acceleration under load, fuel rate, and controlled experiments for drivetrain diagnosis.

## Vehicle editor and nodes

The vehicle editor places components and connects networks. Node colors may change with colorblind settings; identify by type, not color alone.

### External microcontroller node types

- On/off: one Boolean signal.
- Number: one numeric signal.
- Composite: 32 numeric plus 32 Boolean channels on one connection. The number and Boolean channel spaces are independent.
- Video: camera or Lua-generated video stream.
- Audio: microphone/audio stream.

As of the v1.15.10 microcontroller layers update, logic nodes can be layered on the component face, reducing connector footprint. Do not assume an older screenshot's one-node-per-position limitation.

### Internal logic families

The microcontroller editor contains these major logic groups. Exact names should follow the installed game:

- Arithmetic: absolute value, add, subtract, multiply, divide, clamp, equality with epsilon, constants, delta, modulo, and arithmetic function blocks with one/multiple variables.
- Boolean: AND, NAND, OR, NOR, XOR, NOT, constant on, Boolean expression blocks.
- State/control: pulse/toggle conversion, push-to-toggle, SR/JK memory, blinkers, capacitors, comparisons, threshold/switch/junction, memory register, counters, timers, and PID controllers.
- Composite/data: numeric and Boolean read/write, binary encoding/decoding, composite switchbox, video switchbox, audio switchbox.
- Properties: numeric, Boolean, text, slider/dropdown-style configuration where supported, exposed to Lua by exact label.
- Lua: custom processing and video drawing.

Prefer ordinary blocks for a tiny, transparent safety interlock. Prefer Lua for stateful algorithms, channel-heavy protocols, navigation, displays, filtering, and reusable math. Hybrid designs often work best: external hard safety logic and memory registers around a Lua controller.

## Component and subsystem map

This is a functional map, not a frozen item-name catalog. The in-game parts browser and component tooltips are authoritative for the installed version.

### Structure and physics

- Blocks, wedges, pyramids, windows, doors, hatches, pivots, robotic pivots, sliders/pistons, tracks, handles, ladders, seats, and decorative parts.
- Physics flood-fills determine enclosed buoyant spaces. A visually closed hull can leak if geometry or doors do not seal the volume.
- Separate bodies joined through pivots, sliders, connectors, or ropes behave differently from a rigid body. Sensors report from their own body/orientation.
- Centre of mass, centre of buoyancy/lift, thrust line, and control-surface moment arms determine stability.
- Large flat surfaces increase aerodynamic/hydrodynamic drag. More engine power may hide, not solve, bad geometry.

### Mechanical power and propulsion

- Prefabricated diesel engines: simple fuel, air, exhaust, coolant and throttle integration; easy but less configurable.
- Modular engines: crankshafts, cylinders, manifolds, clutches, flywheels, belt accessories, starters, cooling. Require an ECU and careful AFR/temperature/RPS control.
- Electric motors: immediate torque, battery/generator dependent, useful for starting and hybrid drive.
- Jet/turbine systems: compressors, combustion, turbines, exhaust and jet fuel; spool dynamics and layout matter.
- Steam power: heat source, boiler/steam path, turbines or pistons, condenser/water loop; may be heated electrically, by fuel/coal, or nuclear systems depending on design/DLC.
- Rocket/space-grade propulsion: Space DLC mechanics, vacuum/atmosphere and propellant constraints.
- Output components: marine propellers, aircraft propellers, helicopter rotors, ducted fans, wheels, tracks, train wheels, water jets, jet exhausts and rocket nozzles.
- Transmission: clutches, gearboxes, shaft connections, flywheels and generators. Gearbox arrow direction matters; ratio interpretation changes with orientation.

For every drivetrain, record idle RPS, operating RPS, stall behavior, clutch curve, gear ratios, generator load, propulsor command range, and maximum temperature.

### Fluids, pressure, and thermal systems

- Use separate, clearly identified networks for incompatible fluids.
- Confirm port direction and component filters. A pump cannot correct a disconnected or incorrectly filtered network.
- Engines need fuel, air, exhaust path, and adequate cooling. Custom tanks need a sealed volume and correct ports.
- Gas/liquid behavior, pressure, cavitation-like limitations, pumps, relief paths, and temperature changed significantly in past updates; test the installed version.
- Cooling performance depends on flow, radiator/heat exchanger environment, temperature gradient, and heat generation. More pumps can add load without fixing a poor loop.
- Steam systems require controlled heat, water inventory, pressure/temperature management, and a return/condensing plan.

### Electricity

- Batteries store charge; generators/alternators replenish it; motors and powered components consume it.
- A connected electrical network can still brown out under starter, motor, pump, radar, or lighting load.
- Add master isolation, essential/nonessential buses, battery and generation telemetry, low-voltage load shedding, and a manual backup when reliability matters.
- Starter logic should disengage after the engine sustains itself. Prevent simultaneous starter and high-clutch load.

### Sensors and data producers

Common sensor families include GPS, compass, tilt, altimeter, linear speed, angular/physics sensors, RPS/torque, temperature, fluid level/flow/pressure, battery/electrical, clock, wind, radiation, radar, sonar, laser distance, cameras, microphones, radio receivers, transponders, touch monitors, and instrument panels.

Their outputs are not interchangeable:

- A compass often outputs turns with wraparound, not degrees.
- A radar usually reports local polar data and target-valid flags through composite channels; range, azimuth and elevation alone are not world coordinates.
- A physics sensor exposes a documented composite layout and is orientation-sensitive.
- Touch monitor output includes resolution and touch coordinates through composite data.
- Camera/video is a video signal, not numeric pixels available to ordinary Lua.

Always inspect the component's Select-mode tooltip for channels, ranges, units, orientation, FOV, sweep mode and power requirements.

### Actuators and interfaces

- Throttles, key switches, buttons, keypads, seats and instrument panels accept player control.
- Pivots, robotic pivots, sliders, pistons, winches, anchors, magnets/connectors, doors, valves, pumps, clutches, gearboxes and propulsors execute control outputs.
- Monitors and HUDs display video. Lua can draw primitives and text over its own video output; video switchboxes can select sources.
- Radios, antennas, speakers, sirens, microphones and transponders support communication/identification. A protocol must define frequency, channels, packet cadence, ownership and timeout behavior.

### Mission and utility equipment

Rescue and logistics may require fire extinguishers/hoses/pumps, medical equipment, ropes/winches/connectors, beacons, cargo containers, hoppers, cranes, lights, navigation equipment, diving/submersible systems, repair tools and fuel/resource transfer. Design for the mission, not only for top speed.

## DLC boundaries

Do not assume DLC ownership.

| Content | What it gates or adds |
| --- | --- |
| Base game | Vehicle building, rescue simulation, Lua microcontrollers, missions/addons, core engines/sensors/logic |
| Search and Destroy | Functional vehicle weapons, explosives, handheld weapons and related mission content |
| Industrial Frontier | Large arid biome, mining/refining, road/rail expansion, animals and associated industrial systems |
| Space | Space/vacuum mechanics, Moon location and space-grade components/equipment |

Offer a base-game alternative when possible, or explicitly mark a design as DLC-dependent.

## Design workflow

1. Define mission, payload, crew, range/endurance, maximum sea state/wind, operating altitude/depth, desired speed, and DLC.
2. Budget mass, fuel/energy, engine power, cooling, reserve buoyancy/lift, and control authority.
3. Build one working resource path at a time: engine on a test stand, then transmission, then propulsor.
4. Add manual control and instruments before automation.
5. Create an I/O manifest and name every composite channel.
6. Add safety states: off, start, run, degraded, fault, emergency/manual.
7. Test static, low-speed and limit conditions. Change one parameter at a time.
8. Test respawn, unload/reload, loss of power/sensor, multiplayer, and high `game_ticks` for addons.

## Frequent non-Lua failure patterns

| Symptom | First checks |
| --- | --- |
| Engine cranks but will not run | Fuel type/path, air, exhaust, throttle/AFR, starter RPS, clutch unloaded |
| Engine overheats | Coolant flow direction, pump power, heat exchanger exposure, flow restriction, RPS/load |
| Low thrust | RPS under load, clutch curve, gearbox direction/ratio, propulsor command, medium and placement |
| Battery drains | Generator RPS/load, electrical connections, starter stuck on, pumps/radars/motors, capacity |
| Boat lists or capsizes | Centre of mass, asymmetric fuel/payload, centre of buoyancy, free-surface effect, thrust line |
| Aircraft oscillates | Sensor sign/orientation, insufficient damping, control authority, saturation, PID gains and tick scaling |
| Submarine cannot hold depth | Buoyancy trim, ballast flow/pressure, vertical speed damping, depth sensor reference |
| Logic value seems frozen | Wrong node/channel type, unpowered source, stale output not overwritten, controller not spawned/loaded |
| Monitor blank | Video wiring, monitor power/on input, Lua errors, draw color/coordinates, `onDraw` connection |
| Addon controls spawned vehicle inconsistently | Vehicle not loaded, wrong group/vehicle ID, component name mismatch, success flag ignored |

## Direct references

- Base game: https://store.steampowered.com/app/573090/Stormworks_Build_and_Rescue/
- DLC catalog: https://store.steampowered.com/dlc/573090/Stormworks_Build_and_Rescue/
- Current community technical directory: https://swwiki.net/index.php/Category:Stormworks_Technical_Information
- Current logic guide: https://swwiki.net/index.php/Microcontrollers_%26_Logic
- Units reference: https://swwiki.net/index.php/Units_of_Measurement
- Engine overview: https://swwiki.net/index.php/Engines
- Modular engine reference: https://swwiki.net/index.php/Modular_engine
- Weapons/DLC reference: https://swwiki.net/index.php/Weapons
- Generated all-component catalog: https://github.com/gcrtnst/sw-compdocs/tree/main/sw_compdocs
- Generated all-component CSV: https://github.com/gcrtnst/sw-compdocs/blob/main/sw_compdocs.csv
- Generator for the user's exact installed definitions: https://github.com/gcrtnst/sw-compdocs-gen
