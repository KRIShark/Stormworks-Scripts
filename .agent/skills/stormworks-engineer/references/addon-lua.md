# Addon and server Lua

Addon Lua creates missions, custom game modes, server utilities, world events, AI, UI, and scripted vehicle/object behavior. It runs in the world/server context and uses `server.*`; it cannot call microcontroller `input`, `output`, or `screen` APIs.

This reference targets the API extracted from Stormworks v1.15.20. Confirm exact signatures in the installed game's Addon Editor help or the matching versioned documentation before generating code that mutates a live world.

## Execution and persistence

The core callbacks are:

```lua
function onCreate(is_world_create) end
function onTick(game_ticks) end
function onDestroy() end
```

- `onCreate` runs when the script initializes on world creation or load. `is_world_create` is true only for the first creation of that world.
- `onTick(game_ticks)` runs every game tick. `game_ticks` is normally 1 but can be about 400 when sleeping; use it for timers.
- `onDestroy` runs when the world exits.
- Only values reachable from the global table `g_savedata` are serialized to the save's `lua_data.xml`. Ordinary globals reset when scripts reload.
- Default game command `?reload_scripts` autosaves and live-reloads active scripts and mission locations. Make initialization idempotent and preserve/migrate old `g_savedata`.

The official help cautions that `server.announce` inside `onCreate` often runs before a client has connected. Announce to a joining player in `onPlayerJoin` or defer it.

## Persisted schema pattern

```lua
local SCHEMA_VERSION = 2

local function initializeSavedata()
    g_savedata = g_savedata or {}
    g_savedata.schema_version = g_savedata.schema_version or 1
    g_savedata.vehicles = g_savedata.vehicles or {}
    g_savedata.players = g_savedata.players or {}
    g_savedata.next_task_id = g_savedata.next_task_id or 1

    if g_savedata.schema_version < 2 then
        g_savedata.settings = g_savedata.settings or { enabled = true }
        g_savedata.schema_version = 2
    end
end

function onCreate(is_world_create)
    initializeSavedata()
    if is_world_create then
        -- One-time world generation only.
    end
end
```

Do not blindly replace `g_savedata` on reload. Avoid persisting values that contain ephemeral assumptions, such as a vehicle being loaded. Persist identifiers and desired state, then rebuild runtime caches.

## Time model

Use ticks as the durable unit and convert to seconds with the normal 60-tick rate:

```lua
local TICKS_PER_SECOND = 60

function onTick(game_ticks)
    g_savedata.elapsed_ticks = (g_savedata.elapsed_ticks or 0) + game_ticks
    while g_savedata.elapsed_ticks >= 5 * TICKS_PER_SECOND do
        g_savedata.elapsed_ticks = g_savedata.elapsed_ticks - 5 * TICKS_PER_SECOND
        -- Five seconds of game time elapsed.
    end
end
```

Use `while`, not only `if`, when every missed period must be processed. Use a single `if` and discard/cap backlog when replaying hundreds of missed jobs would stall the server. State the chosen catch-up policy.

## Callback catalog

Only implement callbacks the addon needs. Exact parameter lists are in the versioned source.

### Players and chat

- `onCustomCommand`: chat commands beginning with `?`; receives full message, peer, admin/auth flags, command and arguments.
- `onChatMessage`
- `onPlayerJoin`, `onPlayerLeave`, `onPlayerRespawn`, `onPlayerDie`
- `onToggleMap`
- `onPlayerSit`, `onPlayerUnsit`

### Characters, creatures and equipment

- `onCharacterSit`, `onCharacterUnsit`, `onCharacterPickup`
- `onCreatureSit`, `onCreatureUnsit`, `onCreaturePickup`
- `onEquipmentPickup`, `onEquipmentDrop`
- `onObjectLoad`, `onObjectUnload`

### Vehicles and addon components

- `onGroupSpawn`
- `onVehicleSpawn`, `onVehicleDespawn`, `onVehicleLoad`, `onVehicleUnload`, `onVehicleTeleport`
- `onVehicleDamaged`; repair produces a negative damage amount and `body_index == 0` identifies the main body.
- `onButtonPress`
- `onSpawnAddonComponent`; receives a spawned object/vehicle ID, component name, type string and addon index.

Spawned is not the same as loaded. Many physics/component operations require `onVehicleLoad`. Track both lifecycle states and tolerate events after manual deletion or workbench return.

### World events

- `onFireExtinguished`
- `onForestFireSpawned`, `onForestFireExtinguished`
- `onTornado`, `onMeteor`, `onTsunami`, `onWhirlpool`, `onVolcano`
- `onOilSpill`, `onClearOilSpill`

### HTTP

- `httpReply(port, request, reply)` handles `server.httpGet` responses.

Full callback signatures: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_callbacks.md

## Player identity and authorization

- Single-player normally uses `peer_id == 0`.
- Many UI/announcement APIs accept `peer_id == -1` for all connected peers; verify each signature.
- A peer ID identifies the current connection, not a permanent person. Store persistent player data under Steam ID when available, and map the current peer on join.
- `is_admin` authorizes administrative chat commands. `is_auth` permits workbench use. They are different privileges.
- Parse command arguments explicitly because chat arguments are strings. Validate ranges before mutation.
- Resolve player targets by unambiguous ID. Never kick, ban, teleport or alter admin/auth state based on a guessed partial name.

Safe command pattern:

```lua
local function tell(peer_id, message)
    server.announce("My Addon", message, peer_id)
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth, command, arg1)
    if command ~= "?myaddon" then return end
    if not is_admin then
        tell(peer_id, "Admin permission required")
        return
    end

    local value = tonumber(arg1)
    if not value or value < 0 or value > 100 then
        tell(peer_id, "Usage: ?myaddon <0..100>")
        return
    end

    g_savedata.setting = value
    tell(peer_id, "Setting changed to " .. tostring(value))
end
```

Built-in commands include `?reload_scripts`, `?kick`, `?ban`, `?add_admin`, `?remove_admin`, `?add_auth`, `?remove_auth`, and dedicated-server `?save`. Do not shadow them accidentally.

## Server API domains

The extracted API is divided into stable conceptual groups. Load the linked page when using a domain; do not rely on a remembered signature.

### Addon structure and spawning

Use addon/location/component lookup functions to discover addon indices and spawn authored locations. Components may be zones, objects, characters, vehicles, flares, fires, loot, buttons, animals, ice, or other current types. Prefer tags/names deliberately set in the Addon Editor.

Key tasks include:

- get the current or named addon/location index;
- inspect location/component metadata;
- spawn a complete addon location or a particular component;
- capture every spawned ID in `onSpawnAddonComponent`;
- associate vehicles with group IDs;
- despawn owned items during mission cleanup.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_addon.md

### Players, objects and characters

Functions cover player lists/names/positions, player character IDs, object position/data, spawning/despawning characters/animals/equipment/objects, seating, health/revive/kill, fire data and object simulation state.

Many getters return a result plus `is_success`. Use both:

```lua
local transform, ok = server.getPlayerPos(peer_id)
if not ok then return end
local x, y, z = matrix.position(transform)
```

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_objects.md

### Vehicles

Functions cover spawning/despawning and group handling, transforms, simulation/local state, editable/invulnerable state, damage/repair, components, dials/tanks/seats/buttons/keypads/hoppers/batteries/weapons, ropes, position/teleportation, group cost, vehicle data and named/voxel component access.

Component operations often have overloads by component name or voxel coordinate. Names are easier but must be unique and exactly match the vehicle component label. When ambiguity matters, use the voxel overload and document coordinates.

Do not assume a just-spawned vehicle is physics-ready. Queue operations until `onVehicleLoad(vehicle_id)`. On unload, stop high-frequency polling and keep only desired state.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_vehicles.md

### Game and world

Functions cover time/date/weather, game settings, currency/research, tiles/zones, ocean/weather/disaster controls, explosions/oil spills, transform lookup, world inventory/resources, wildlife, audio mood and environment state.

World mutations can affect all players and saves. Require explicit administrative intent and provide a reversible or bounded operation where possible.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_game.md

### UI, map and chat

Functions cover announcements, notifications, map objects/labels/lines, world popups, screen popups and removal. Allocate stable UI IDs with the API, store ownership per addon/per peer, and remove stale elements on cleanup.

`peer_id == -1` can target all peers for many UI calls, but per-peer IDs and visibility still need consistent lifecycle management. Recreate player-specific UI on join when necessary.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_ui.md

### AI

Functions control AI state, targets and AI teams for characters/vehicles. A target transform is not interchangeable with a target object/vehicle ID. Define ownership, friendly teams, acquisition/clear rules and behavior after a target despawns.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_ai.md

### HTTP, admin and properties

Addon main-menu properties include checkbox/slider configuration. HTTP requests use `server.httpGet`. Administrative APIs can kick/ban, grant/revoke admin/auth and save dedicated servers.

Do not execute an administrative action without explicit authorization. Rate-limit HTTP, include request correlation, and treat external response text as untrusted input.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_misc.md

## Matrix and coordinate model

Stormworks addon transforms are 4x4 matrices represented by 16 numeric entries. Translation occupies the documented X, Y, Z fields; Y is vertical, while X/Z form the horizontal world plane.

Verified matrix functions include:

```lua
matrix.identity()
matrix.translation(x, y, z)
matrix.rotationX(radians)
matrix.rotationY(radians)
matrix.rotationZ(radians)
matrix.multiply(a, b)
matrix.invert(a)
matrix.transpose(a)
matrix.position(transform)
matrix.distance(a, b)
matrix.multiplyXYZW(transform, x, y, z, w)
matrix.rotationToFaceXZ(x, z)
```

Matrix multiplication order matters. To apply a local offset to an existing world transform, verify the order with a known 2 m test offset instead of guessing. Use `w=1` to transform a point and `w=0` to transform a direction when using homogeneous-coordinate multiplication.

Source: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_matrices.md

## Ownership and cleanup model

Track everything the addon creates:

```lua
g_savedata.spawned = g_savedata.spawned or {
    vehicles = {},
    objects = {},
    groups = {},
    ui = {}
}
```

Each entry should record ID, kind, owning mission/task, desired state, spawned/loaded status and cleanup policy. Remove entries on despawn callbacks. Before destructive cleanup, verify the ID still belongs to the addon and mission instance; numeric IDs may be invalid after deletion/reload.

## Performance model

- Never scan every world object every tick. Maintain event-driven registries.
- Stagger expensive polls across ticks and vehicles.
- Use squared distance for threshold comparisons when an exact distance is unnecessary.
- Cap table sizes and purge despawned entries.
- Cache addon/location/component indices after initialization, but invalidate appropriately after script reload.
- Do not create/remove UI every tick if updating only text or position is enough.
- Decide how to handle large `game_ticks`: catch up, aggregate, or skip, depending on mission semantics.
- Avoid `#` and `ipairs` on sparse ID-keyed tables; the official help explicitly warns about non-contiguous tables.

## Addon development locations

Typical Windows paths are:

- User addons/missions: `%APPDATA%\Stormworks\data\missions`
- User vehicles and microcontrollers live under `%APPDATA%\Stormworks\data`
- Default game addons: `<SteamLibrary>\steamapps\common\Stormworks\rom\data\missions`

Paths can differ by Steam library and OS. Copy a default addon into the user mission directory before editing; never alter the installed canonical copy. Back up the user data directory first.

## Test matrix

Test at minimum:

1. New world and existing-world load.
2. `?reload_scripts` with pre-existing `g_savedata`.
3. No players, one player, later join, and disconnect/reconnect.
4. Admin and non-admin command attempts.
5. Spawn -> load -> unload -> load -> despawn lifecycle.
6. Missing/deleted objects and getters returning failure.
7. Sleeping/high `game_ticks` behavior.
8. Multiplayer UI visibility and per-peer cleanup.
9. Save/reload schema migration.
10. Addon disable/removal cleanup expectations.

## Direct API references

- v1.15.20 general rules: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_general.md
- v1.15.20 callbacks: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_callbacks.md
- v1.15.20 examples: https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_examples.md
- Maintained typed addon API: https://github.com/Cuh4/StormworksAddonLuaDocumentation
- Documentation portal: https://stormworks.uk/api/addon/commands/
