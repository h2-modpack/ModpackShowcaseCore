-- =============================================================================
-- MODULE DISCOVERY
-- =============================================================================
-- Discovers installed adamant-* standalone modules by checking rom.mods.
-- Order is fixed for hash compatibility — matches the original modules/init.lua.
-- DO NOT reorder entries — it will break existing config hashes / profiles.
--
-- Each entry: { modName = "adamant-XXX", category = "...", categoryLabel = "..." }
-- The module's public.definition provides id, name, group, tooltip, default, etc.

local Discovery = {}

-- -------------------------------------------------------------------------
-- CANONICAL ORDER (hash-stable — append only, never reorder)
-- -------------------------------------------------------------------------

local MODULE_ORDER = {
    -- Run Modifiers
    { modName = "adamant-ForceMedea",              category = "RunModifiers",  categoryLabel = "Run Modifiers" },
    { modName = "adamant-ForceArachne",            category = "RunModifiers" },
    { modName = "adamant-DisableArachnePity",      category = "RunModifiers" },
    { modName = "adamant-PreventEchoScam",         category = "RunModifiers" },
    { modName = "adamant-DisableSeleneBeforeBoon",  category = "RunModifiers" },
    { modName = "adamant-RTAMode",                 category = "RunModifiers" },
    { modName = "adamant-SkipGemBossReward",       category = "RunModifiers" },
    { modName = "adamant-EscalatingFigLeaf",       category = "RunModifiers" },
    { modName = "adamant-SurfaceStructure",        category = "RunModifiers" },
    { modName = "adamant-CharybdisBehavior",       category = "RunModifiers" },

    -- QoL
    { modName = "adamant-ShowLocation",            category = "QoLSettings",   categoryLabel = "QoL" },
    { modName = "adamant-SkipDialogue",            category = "QoLSettings" },
    { modName = "adamant-SkipRunEndCutscene",      category = "QoLSettings" },
    { modName = "adamant-SkipDeathCutscene",       category = "QoLSettings" },
    { modName = "adamant-SpawnLocation",           category = "QoLSettings" },
    { modName = "adamant-KBMEscape",              category = "QoLSettings" },
    { modName = "adamant-VictoryScreen",           category = "QoLSettings" },
    { modName = "adamant-SpeedrunTimer",           category = "QoLSettings" },

    -- Bug Fixes
    { modName = "adamant-CorrosionFix",            category = "BugFixes",      categoryLabel = "Bug Fixes" },
    { modName = "adamant-GGGFix",                  category = "BugFixes" },
    { modName = "adamant-BraidFix",                category = "BugFixes" },
    { modName = "adamant-MiniBossEncounterFix",    category = "BugFixes" },
    { modName = "adamant-ExtraDoseFix",            category = "BugFixes" },
    { modName = "adamant-PoseidonWavesFix",        category = "BugFixes" },
    { modName = "adamant-TidalRingFix",            category = "BugFixes" },
    { modName = "adamant-ShimmeringFix",           category = "BugFixes" },
    { modName = "adamant-StagedOmegaFix",          category = "BugFixes" },
    { modName = "adamant-OmegaCastFix",            category = "BugFixes" },
    { modName = "adamant-CardioTorchFix",          category = "BugFixes" },
    { modName = "adamant-FamiliarDelayFix",        category = "BugFixes" },
    { modName = "adamant-SufferingFix",            category = "BugFixes" },
    { modName = "adamant-SeleneFix",               category = "BugFixes" },
    { modName = "adamant-ETFix",                   category = "BugFixes" },
    { modName = "adamant-SecondStageChanneling",   category = "BugFixes" },
}

-- Special modules (not in boolean hash, handled separately)
local SPECIAL_MODULES = {
    { modName = "adamant-FirstHammer" },
}

-- -------------------------------------------------------------------------
-- DISCOVERY STATE
-- -------------------------------------------------------------------------

-- Populated by Discovery.run()
Discovery.modules = {}          -- ordered list of discovered boolean modules
Discovery.modulesById = {}      -- id -> module entry
Discovery.specials = {}         -- discovered special modules (keyed by modName)

Discovery.categories = {}       -- ordered list of { key, label }
Discovery.byCategory = {}       -- category key -> ordered list of modules
Discovery.categoryLayouts = {}  -- category key -> UI layout (groups)

-- -------------------------------------------------------------------------
-- DISCOVERY
-- -------------------------------------------------------------------------

function Discovery.run()
    local mods = rom.mods

    -- Track category discovery order
    local categorySet = {}
    local categoryLabels = {}

    for _, entry in ipairs(MODULE_ORDER) do
        local mod = mods[entry.modName]
        if mod and mod.public and mod.public.definition then
            local def = mod.public.definition
            local module = {
                modName    = entry.modName,
                mod        = mod,
                definition = def,
                id         = def.id,
                name       = def.name,
                category   = entry.category,
                group      = def.group or "General",
                tooltip    = def.tooltip or "",
                default    = def.default,
            }

            table.insert(Discovery.modules, module)
            Discovery.modulesById[def.id] = module

            -- Category tracking
            local cat = entry.category
            if not categorySet[cat] then
                categorySet[cat] = true
                table.insert(Discovery.categories, {
                    key = cat,
                    label = entry.categoryLabel or categoryLabels[cat] or cat,
                })
            end
            if entry.categoryLabel then
                categoryLabels[cat] = entry.categoryLabel
            end

            Discovery.byCategory[cat] = Discovery.byCategory[cat] or {}
            table.insert(Discovery.byCategory[cat], module)
        end
    end

    -- Discover special modules
    for _, entry in ipairs(SPECIAL_MODULES) do
        local mod = mods[entry.modName]
        if mod and mod.public and mod.public.definition then
            Discovery.specials[entry.modName] = {
                modName    = entry.modName,
                mod        = mod,
                definition = mod.public.definition,
            }
        end
    end

    -- Build UI layouts
    for _, cat in ipairs(Discovery.categories) do
        Discovery.categoryLayouts[cat.key] = Discovery.buildLayout(cat.key)
    end
end

-- -------------------------------------------------------------------------
-- LAYOUT BUILDER
-- -------------------------------------------------------------------------

function Discovery.buildLayout(category)
    local mods = Discovery.byCategory[category] or {}
    local groupOrder = {}
    local groups = {}

    for _, m in ipairs(mods) do
        local g = m.group
        if not groups[g] then
            groups[g] = { Header = g, Items = {} }
            table.insert(groupOrder, g)
        end
        table.insert(groups[g].Items, {
            Key       = m.id,
            ModName   = m.modName,
            Name      = m.name,
            Tooltip   = m.tooltip,
        })
    end

    local layout = {}
    for _, g in ipairs(groupOrder) do
        table.insert(layout, groups[g])
    end
    return layout
end

-- -------------------------------------------------------------------------
-- MODULE STATE ACCESS
-- -------------------------------------------------------------------------

--- Read a module's current Enabled state from its own config.
function Discovery.isModuleEnabled(module)
    return module.mod.public.config.Enabled == true
end

--- Write a module's Enabled state and call enable/disable.
function Discovery.setModuleEnabled(module, enabled)
    module.mod.public.config.Enabled = enabled
    if enabled then
        module.definition.enable()
    else
        module.definition.disable()
    end
end

--- Get the FirstHammer module reference (or nil if not installed).
function Discovery.getHammerModule()
    local entry = Discovery.specials["adamant-FirstHammer"]
    if entry then return entry.mod end
    return nil
end

Core.Discovery = Discovery
