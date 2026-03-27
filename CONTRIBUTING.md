# Contributing to adamant-ModpackShowcaseCore

Thin coordinator showcasing the h2-modpack architecture. Owns pack identity, config, and default profiles — delegates all orchestration to `adamant-ModpackFramework`.

## Architecture

```
src/
  main.lua    -- ENVY wiring, config, def, Framework.init call
config.lua    -- Chalk config schema (ModEnabled, DebugMode, Profiles)
```

The coordinator has no other source files. All discovery, hashing, HUD, and UI logic lives in [adamant-ModpackFramework](https://github.com/h2-modpack/ModpackFramework). See its CONTRIBUTING.md for architecture, key systems, and guidelines.

## What the coordinator owns

**`packId`** — `"h2-modpack"`. Discovery filter: only modules with `definition.modpack = "h2-modpack"` are picked up by Framework.

**`windowTitle`** — `"Speedrun Modpack"`. Displayed as the ImGui window title.

**`def.defaultProfiles`** — Shipped presets. To add or update a preset, edit `def` in `src/main.lua`. Get the hash string from the Profiles tab export field in-game.

**`config.lua`** — Chalk schema: `ModEnabled`, `DebugMode`, `Profiles` array. The Profiles array length determines `def.NUM_PROFILES` and must match the number of slots rendered in the UI.

## No tests

Tests live in `adamant-ModpackFramework`. Run them from there:

```bash
cd adamant-ModpackFramework
lua5.1 tests/all.lua
```
