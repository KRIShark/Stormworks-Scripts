# Source index and freshness policy

Research baseline: 29 August 2026. Latest verified public game version in this research: v1.15.20, released 15 August 2026. Always re-check the current version before answering patch-sensitive questions.

## Source priority

1. Installed game: Lua help panels, component tooltips, Select-mode channel descriptions and default addon source matching the user's exact build.
2. Official Geometa/Steam sources: release notes, Geometa wiki and issue tracker.
3. Versioned extraction of the in-game help: useful because it preserves exact historical APIs.
4. Maintained typed documentation and focused empirical research.
5. General community wiki, Workshop guides and forum posts.

Use a lower tier when the higher tier does not cover a subject, but label empirical/community values. If two sources conflict, prefer the one matching the user's game version and verify in game.

## Official game and updates

- Main game page and feature description:
  https://store.steampowered.com/app/573090/Stormworks_Build_and_Rescue/
- DLC catalog (Search and Destroy, Industrial Frontier, Space):
  https://store.steampowered.com/dlc/573090/Stormworks_Build_and_Rescue/
- Official Steam news hub:
  https://store.steampowered.com/news/app/573090
- Official Steam Workshop:
  https://steamcommunity.com/app/573090/workshop/
- Official Geometa issue tracker:
  https://geometa.co.uk/support/stormworks/
- Official Geometa wiki index:
  https://geometa.co.uk/wiki/stormworks
- Official component-modding page:
  https://geometa.co.uk/wiki/stormworks/view/component_modding
- Official dedicated-server page:
  https://geometa.co.uk/wiki/stormworks/view/dedicated_servers
- Official asset-modding page:
  https://geometa.co.uk/wiki/stormworks/view/asset_modding

### Important recent releases

- v1.15.0 Components, Physics, Gameplay Modding:
  https://store.steampowered.com/news/app/573090/view/534354183830114758
- v1.15.10 Microcontroller Layers:
  https://store.steampowered.com/news/app/573090/view/507351614918492485
- v1.15.12 Armour:
  https://steamcommunity.com/games/573090/announcements/detail/517489783702815254
- v1.15.19 Small Train Wheels:
  https://store.steampowered.com/news/app/573090/view/545650698257171606
- v1.15.20 hotfix record (secondary SteamDB mirror; verify against Steam news):
  https://steamdb.info/patchnotes/24749959/
- Full patch list mirror:
  https://steamdb.info/app/573090/patchnotes/

Do not infer that an API changed merely because the game version advanced. Compare extracted help files or official patch notes.

## Versioned in-game Lua documentation

The `gcrtnst/sw-luadocs` repository contains documentation extracted from the game. Choose the directory matching the user's version:

- Repository: https://github.com/gcrtnst/sw-luadocs
- All versions: https://github.com/gcrtnst/sw-luadocs/tree/main/data
- v1.15.20 documentation folder:
  https://github.com/gcrtnst/sw-luadocs/tree/main/data/v1.15.20/markdown

### Vehicle microcontroller Lua

- Complete vehicle help/API:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/vehicle_help.md

This is the most useful single source for `onTick`, `onDraw`, composite I/O, properties, all screen primitives, map conversion, monitor touch channels, the sandbox, loopback HTTP and multiplayer/state warnings.

### Addon/server Lua

- General rules and built-in commands:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_general.md
- Callbacks:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_callbacks.md
- Addon/location/component discovery and spawning:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_addon.md
- Players, objects, characters, creatures and equipment:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_objects.md
- Vehicles and vehicle components:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_vehicles.md
- Game/world/weather/resources/wildlife:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_game.md
- Chat, map and UI:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_ui.md
- AI and teams:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_ai.md
- Matrix API:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_matrices.md
- HTTP, properties, administration and miscellaneous APIs:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_misc.md
- Officially extracted examples:
  https://github.com/gcrtnst/sw-luadocs/blob/main/data/v1.15.20/markdown/addon_examples.md

## Navigable API portals

These are easier to browse/search than raw extracted help, but confirm freshness:

- Stormworks documentation home: https://stormworks.uk/
- Microcontroller introduction: https://stormworks.uk/api/microcontroller/intro/
- Microcontroller callbacks: https://stormworks.uk/api/microcontroller/callbacks/
- Microcontroller functions: https://stormworks.uk/api/microcontroller/functions/
- Microcontroller editor introduction: https://stormworks.uk/getting-started/gs-mc-editor/
- Lua editor introduction: https://stormworks.uk/getting-started/gs-lua-editor/
- Addon commands: https://stormworks.uk/api/addon/commands/
- Addon matrices: https://stormworks.uk/api/addon/matrices/

## Typed API sources and editor support

Typed stubs are excellent for discovering names and return types, but the user's installed help remains final authority.

- Microcontroller typed API:
  https://github.com/Cuh4/StormworksMCLuaDocumentation
- Addon typed API:
  https://github.com/Cuh4/StormworksAddonLuaDocumentation
- Component-mod typed API:
  https://github.com/Cuh4/StormworksModLuaDocumentation
- Exact component-mod intellisense file:
  https://github.com/Cuh4/StormworksModLuaDocumentation/blob/main/docs/intellisense.lua
- Lua language server extension:
  https://marketplace.visualstudio.com/items?itemName=sumneko.lua
- Lua 5.3 language manual:
  https://www.lua.org/manual/5.3/

The Lua manual documents the language, not Stormworks' allowed library subset.

## Current community technical references

The current independent wiki is useful for construction and measured behavior; its catalog is still developing.

- Directory: https://swwiki.net/index.php/Category:StormWiki_Directory
- Technical category: https://swwiki.net/index.php/Category:Stormworks_Technical_Information
- Microcontrollers and logic blocks: https://swwiki.net/index.php/Microcontrollers_%26_Logic
- Units: https://swwiki.net/index.php/Units_of_Measurement
- Engine overview: https://swwiki.net/index.php/Engines
- Modular engines: https://swwiki.net/index.php/Modular_engine
- Weapons: https://swwiki.net/index.php/Weapons

### Specialist empirical documentation

- Radar noise, range/FOV, update cadence and coordinate conversion:
  https://github.com/LaurinMeier/Stormworks-Radar-Documentation

Treat measured formulas as version-sensitive. Reproduce a small in-game test before relying on them for high-precision guidance.

### Complete generated component catalog

For exact part names, mass, cost, dimensions, descriptions, nodes and categories, prefer the catalog generated from Stormworks definition XML instead of a hand-maintained list:

- Generated documentation, one Markdown file per component:
  https://github.com/gcrtnst/sw-compdocs/tree/main/sw_compdocs
- Generated CSV containing all components:
  https://github.com/gcrtnst/sw-compdocs/blob/main/sw_compdocs.csv
- Catalog repository:
  https://github.com/gcrtnst/sw-compdocs
- Generator source and instructions:
  https://github.com/gcrtnst/sw-compdocs-gen

The checked-in catalog may not match the user's build. To generate an exact local catalog, the tool reads the installation's `rom/data/definitions` directory and can output Markdown or CSV. Prefer that route when the user asks for every component or precise current values. Do not redistribute proprietary game definition files; generate derived documentation from the user's own installation and respect the tool/game licenses.

## Development tools

- Pony IDE: https://lua.flaffipony.rocks/
- LifeBoatAPI VS Code extension:
  https://marketplace.visualstudio.com/items?itemName=NameousChangey.lifeboatapi
- LifeBoatAPI extension source/issues:
  https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
- Stormworks CLI: https://github.com/Chromatischer/stormworks-cli
- SSSWTool addon builder: https://github.com/Avril112113/SSSWTool
- Stormworks Lua extraction workflow:
  https://github.com/Rene-Sackers/StormworksLuaExtract
- Noir addon framework: https://github.com/cuhHub/Noir

Check tool release dates, supported game version, licenses and open issues before recommending installation. External builders may offer `require`, modules and minification that do not exist in the native pasted runtime.

## Local canonical examples

When Stormworks is installed, these local sources often provide the closest version match:

- User data root on Windows: `%APPDATA%\Stormworks\data`
- User microcontrollers: `%APPDATA%\Stormworks\data\microprocessors`
- User addons: `%APPDATA%\Stormworks\data\missions`
- Default addons: `<SteamLibrary>\steamapps\common\Stormworks\rom\data\missions`

Open the Lua help inside the vehicle/Add-on Editor. For addon techniques, inspect default addon scripts from the installation. Copy to user data before changing anything.

## Search strategy for unknown APIs

1. Search the matching version folder for the desired verb/noun, such as `VehicleBattery`, `MapObject`, `AIState` or `fluid`.
2. Read the entire function entry, including overloads, enum tables, return values and success flag.
3. Search newer/older version folders to identify when it changed.
4. Search official patch notes for the function/component.
5. Search the issue tracker for current defects, but do not treat an open feature request as an implemented API.
6. If still uncertain, produce a minimal in-game probe and label the result that needs verification.

## Citation behavior

When answering with research:

- link directly to the exact API category or update, not only a homepage;
- identify official, extracted-official, typed-community or empirical-community status;
- include game version/date for patch-sensitive values;
- avoid quoting large sections; summarize and point to the source;
- clearly distinguish a documented fact from an engineering inference.
