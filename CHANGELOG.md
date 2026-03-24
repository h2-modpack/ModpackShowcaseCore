# Changelog

## [Unreleased]

### Added
- Initial release of adamant-Modpack_Core coordinator
- Module discovery system — scans `rom.mods` for installed `adamant-*` modules in canonical `MODULE_ORDER`
- `discovery_registry.lua` — flat ordered list of mod names; append-only to preserve hash stability
- Unified ImGui UI with per-category tabs, group headers, tooltips, and inline options
- Config hash system (`hash.lua`) — base62 encoding, 30-bit chunks, format `<bool_hash>.<special_hash>`
- Profile management — save/load/import/export named profiles
- HUD mod marker — displays current bool hash on the in-game HUD
- Special module support — sidebar tabs, `stateSchema`-driven hashing, `DrawTab`/`DrawQuickContent` contract
- Quick Setup tab — bulk bug fix toggle, per-module quick access snippets
- `enforce-discovery-order.yml` CI — prevents reordering or removing existing `MODULE_ORDER` entries
- Luacheck linting on push/PR
- Unit tests for hash encoding/decoding, base62, chunk boundaries, and round-trips (LuaUnit, Lua 5.1)
- Branch protection on `main` requiring CI pass


[Unreleased]:

