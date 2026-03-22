-- =============================================================================
-- STRICT APPEND-ONLY REGISTRY
-- =============================================================================
-- New modules MUST be added to the bottom of their respective lists.
-- DO NOT reorder or delete existing entries.

local MODULE_ORDER = {
    -- Run Modifiers
    { modName = "adamant-ForceMedea",              category = "RunModifiers",  categoryLabel = "Run Modifiers" },
    { modName = "adamant-ForceArachne",            category = "RunModifiers" },
    { modName = "adamant-DisableArachnePity",      category = "RunModifiers" },
    { modName = "adamant-PreventEchoScam",         category = "RunModifiers" },
    { modName = "adamant-DisableSeleneBeforeBoon", category = "RunModifiers" },
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
    { modName = "adamant-KBMEscape",               category = "QoLSettings" },
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

local SPECIAL_MODULES = {
    { modName = "adamant-FirstHammer" },
}

-- Special modules (not in boolean hash, handled separately)
-- Each must expose definition.tabLabel for the sidebar.
-- Append only, never reorder — hash payload order depends on this.
Core.MODULE_ORDER = MODULE_ORDER
Core.SPECIAL_MODULES = SPECIAL_MODULES