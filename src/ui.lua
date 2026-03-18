local ui = rom.ImGui
local uiCol = rom.ImGuiCol

local Discovery = Core.Discovery

-- =============================================================================
-- LOCALIZATION (delegates to FirstHammer module if installed)
-- =============================================================================

local hasLocalizedLabels = false

local function BuildLocalizedLabels()
    local hammerMod = Discovery.getHammerModule()
    if not hammerMod then return end
    local hammerData = hammerMod.public.hammerData
    for _, data in pairs(hammerData) do
        data.labels = {}
        for i, internalString in ipairs(data.values) do
            if internalString == "" then
                data.labels[i] = "None (Random)"
            else
                local localizedName = GetDisplayName({ Text = internalString })
                data.labels[i] = localizedName or internalString
            end
        end
    end
    hasLocalizedLabels = true
end

-- =============================================================================
-- THEME
-- =============================================================================

local colors = {
    text          = {0.92, 0.90, 0.95, 1.0},
    textDisabled  = {0.45, 0.40, 0.55, 1.0},
    info          = {0.90, 0.75, 0.20, 1.0},
    warning       = {0.85, 0.20, 0.25, 1.0},
    success       = {0.30, 0.85, 0.55, 1.0},
    error         = {0.90, 0.35, 0.50, 1.0},
    mixed         = {0.30, 0.70, 0.90, 1.0},

    windowBg      = {0.08, 0.06, 0.12, 0.95},
    childBg       = {0.10, 0.08, 0.15, 0.90},
    header        = {0.28, 0.18, 0.45, 1.0},
    headerHover   = {0.38, 0.25, 0.58, 1.0},
    headerActive  = {0.45, 0.30, 0.65, 1.0},
    button        = {0.30, 0.20, 0.48, 1.0},
    buttonHover   = {0.40, 0.28, 0.60, 1.0},
    buttonActive  = {0.50, 0.35, 0.70, 1.0},
    frameBg       = {0.14, 0.10, 0.22, 1.0},
    frameBgHover  = {0.20, 0.15, 0.30, 1.0},
    frameBgActive = {0.25, 0.18, 0.38, 1.0},
    checkMark     = {0.75, 0.55, 1.00, 1.0},
    tab           = {0.18, 0.12, 0.28, 1.0},
    tabHover      = {0.35, 0.22, 0.52, 1.0},
    tabActive     = {0.40, 0.28, 0.60, 1.0},
    separator     = {0.30, 0.20, 0.45, 0.6},
    border        = {0.25, 0.18, 0.38, 0.5},
}

local ImGuiTreeNodeFlags = {
    DefaultOpen = 32,
}

local function DrawColoredText(color, text)
    ui.TextColored(color[1], color[2], color[3], color[4], text)
end

local function PushTextColor(color)
    ui.PushStyleColor(uiCol.Text, color[1], color[2], color[3], color[4])
end

local THEME_COLOR_COUNT = 20
local function PushTheme()
    local push = ui.PushStyleColor
    push(uiCol.Text,            table.unpack(colors.text))
    push(uiCol.TextDisabled,    table.unpack(colors.textDisabled))
    push(uiCol.WindowBg,        table.unpack(colors.windowBg))
    push(uiCol.ChildBg,         table.unpack(colors.childBg))
    push(uiCol.Header,          table.unpack(colors.header))
    push(uiCol.HeaderHovered,   table.unpack(colors.headerHover))
    push(uiCol.HeaderActive,    table.unpack(colors.headerActive))
    push(uiCol.Button,          table.unpack(colors.button))
    push(uiCol.ButtonHovered,   table.unpack(colors.buttonHover))
    push(uiCol.ButtonActive,    table.unpack(colors.buttonActive))
    push(uiCol.FrameBg,         table.unpack(colors.frameBg))
    push(uiCol.FrameBgHovered,  table.unpack(colors.frameBgHover))
    push(uiCol.FrameBgActive,   table.unpack(colors.frameBgActive))
    push(uiCol.CheckMark,       table.unpack(colors.checkMark))
    push(uiCol.Tab,             table.unpack(colors.tab))
    push(uiCol.TabHovered,      table.unpack(colors.tabHover))
    push(uiCol.TabActive,       table.unpack(colors.tabActive))
    push(uiCol.Separator,       table.unpack(colors.separator))
    push(uiCol.Border,          table.unpack(colors.border))
    push(uiCol.TitleBgActive,   table.unpack(colors.header))
end

local function PopTheme()
    ui.PopStyleColor(THEME_COLOR_COUNT)
end

-- =============================================================================
-- STAGING TABLE (performance cache — avoids Chalk reads in render loop)
-- =============================================================================
-- Plain Lua tables mirroring each module's Chalk config.
-- UI reads/writes go through staging. Chalk is only touched in event handlers.

local staging = {
    ModEnabled    = config.ModEnabled == true,  -- snapshot once
    HammerEnabled = false,
    FirstHammers  = {},
    modules       = {},  -- [module.id] = bool
}

-- Profile staging: plain copies of config.Profiles
local profileStaging = {}

local function ShallowCopy(src, dst)
    for k, v in pairs(src) do dst[k] = v end
end

--- Snapshot all Chalk configs into staging (called at init and after profile load).
local function SnapshotToStaging()
    staging.ModEnabled = config.ModEnabled == true

    -- Boolean modules
    for _, m in ipairs(Discovery.modules) do
        staging.modules[m.id] = Discovery.isModuleEnabled(m)
    end

    -- Hammers
    local hammerMod = Discovery.getHammerModule()
    if hammerMod then
        staging.HammerEnabled = hammerMod.public.config.Enabled == true
        ShallowCopy(hammerMod.public.config.FirstHammers, staging.FirstHammers)
    end

    -- Profiles
    for i, p in ipairs(config.Profiles) do
        profileStaging[i] = {
            Name    = p.Name or "",
            Hash    = p.Hash or "",
            Tooltip = p.Tooltip or "",
        }
    end
end

-- Initialize staging from current configs
SnapshotToStaging()

-- =============================================================================
-- CACHED DISPLAY DATA (rebuilt on dirty flag, never per-frame)
-- =============================================================================

local NUM_PROFILES = 10

local slotLabels = {}
local slotOccupied = {}
local slotLabelsDirty = true

local cachedHash = nil
local cachedBoolHash = nil

local selectedProfileSlot = 1
local selectedProfileCombo = 0
local importHashBuffer = ""
local importFeedback = nil
local importFeedbackColor = nil
local importFeedbackTime = nil
local excludeHammers = false

-- Bug fix status cache
local bugFixStatusText = ""
local bugFixStatusColor = colors.textDisabled
local bugFixStatusDirty = true

local FEEDBACK_DURATION = 2.0
local function SetImportFeedback(text, color)
    importFeedback = text
    importFeedbackColor = color
    importFeedbackTime = os.clock()
end

local function InvalidateHash()
    cachedHash = nil
    cachedBoolHash = nil
end

local function GetCachedHash()
    if not cachedHash then
        cachedHash, cachedBoolHash = Core.GetConfigHash(staging)
    end
    return cachedHash, cachedBoolHash
end

local function RebuildSlotLabels()
    for i, p in ipairs(profileStaging) do
        local hasName = p.Name ~= ""
        slotOccupied[i] = hasName
        if hasName then
            slotLabels[i] = i .. ": " .. p.Name
        else
            slotLabels[i] = i .. ": (empty)"
        end
    end
    slotLabelsDirty = false
end

local function RebuildBugFixStatus()
    local modules = Discovery.byCategory["BugFixes"] or {}
    if #modules == 0 then
        bugFixStatusText = "N/A"
        bugFixStatusColor = colors.textDisabled
        bugFixStatusDirty = false
        return
    end
    local hasEnabled = false
    local hasDisabled = false
    for _, m in ipairs(modules) do
        if staging.modules[m.id] then hasEnabled = true else hasDisabled = true end
    end
    if hasEnabled and not hasDisabled then
        bugFixStatusText = "All Enabled"
        bugFixStatusColor = colors.success
    elseif hasDisabled and not hasEnabled then
        bugFixStatusText = "All Disabled"
        bugFixStatusColor = colors.error
    else
        bugFixStatusText = "Mixed Configuration"
        bugFixStatusColor = colors.mixed
    end
    bugFixStatusDirty = false
end

-- =============================================================================
-- TOGGLE HELPERS (event handlers — OK to touch Chalk here)
-- =============================================================================

local function ToggleModule(module, enabled)
    -- Update staging
    staging.modules[module.id] = enabled
    -- Write to Chalk + call enable/disable
    Discovery.setModuleEnabled(module, enabled)
    if module.definition.dataMutation then
        SetupRunData()
    end
    InvalidateHash()
    bugFixStatusDirty = true
    Core.UpdateHash()
end

local function ToggleHammer(hammerMod, enabled)
    staging.HammerEnabled = enabled
    hammerMod.public.config.Enabled = enabled
    if enabled then
        hammerMod.public.definition.enable()
    else
        hammerMod.public.definition.disable()
    end
    InvalidateHash()
    Core.UpdateHash()
end

local function SetHammerChoice(weaponKey, value)
    staging.FirstHammers[weaponKey] = value
    local hammerMod = Discovery.getHammerModule()
    if hammerMod then
        hammerMod.public.config.FirstHammers[weaponKey] = value
    end
    InvalidateHash()
    Core.UpdateHash()
end

--- Load a profile hash: decode, apply to all module configs, re-snapshot.
local function LoadProfile(hash)
    if Core.ApplyConfigHash(hash) then
        SetupRunData()
        SnapshotToStaging()
        InvalidateHash()
        bugFixStatusDirty = true
        slotLabelsDirty = true
        Core.UpdateHash()
        return true
    end
    return false
end

local function SetBugFixes(flag)
    local modules = Discovery.byCategory["BugFixes"] or {}
    for _, m in ipairs(modules) do
        staging.modules[m.id] = flag
        Discovery.setModuleEnabled(m, flag)
    end
    SetupRunData()
    InvalidateHash()
    bugFixStatusDirty = true
    Core.UpdateHash()
end

-- =============================================================================
-- DEFAULT PROFILES
-- =============================================================================

local defaultProfiles = {
    { Name = "AnyFear",  Hash = "1AfB0V.3", Tooltip = "RTA Disabled. Arachne Pity Disabled" },
    { Name = "HighFear", Hash = "1AfB0t.3", Tooltip = "RTA Disabled. Arachne Spawn Forced" },
    { Name = "RTA",      Hash = "1AfB20.3", Tooltip = "RTA Enabled. Arachne Pity Enabled. Medea/Arachne Spawns Not Forced" },
}

-- =============================================================================
-- HAMMER UI (delegates to FirstHammer module)
-- =============================================================================

local function DrawHammerDropdown(weaponKey, displayLabel)
    local hammerMod = Discovery.getHammerModule()
    if not hammerMod then return end

    if not hasLocalizedLabels then BuildLocalizedLabels() end

    local data = hammerMod.public.hammerData[weaponKey]
    if not data then return end

    -- Read from staging, not Chalk
    local currentId = staging.FirstHammers[weaponKey] or ""
    local currentIndex = 1
    for i, val in ipairs(data.values) do
        if val == currentId then
            currentIndex = i
            break
        end
    end

    local currentPreview = data.labels[currentIndex] or "None (Random)"

    ui.PushID(weaponKey)
    ui.Text(displayLabel)
    ui.SameLine()
    local winW = ui.GetWindowWidth()
    ui.SetCursorPosX(winW * 0.25)
    ui.PushItemWidth(winW * 0.4)
    if ui.BeginCombo("##HammerCombo", currentPreview) then
        for i, txt in ipairs(data.labels) do
            local isSelected = (i == currentIndex)
            if ui.Selectable(txt, isSelected) then
                if i ~= currentIndex then
                    SetHammerChoice(weaponKey, data.values[i])
                end
            end
        end
        ui.EndCombo()
    end
    ui.PopItemWidth()
    ui.PopID()
end

-- =============================================================================
-- GENERIC TAB CONTENT RENDERER
-- =============================================================================

local function DrawCheckboxGroup(layoutData, category)
    local modules = Discovery.byCategory[category] or {}
    local moduleMap = {}
    for _, m in ipairs(modules) do moduleMap[m.id] = m end

    for _, group in ipairs(layoutData) do
        PushTextColor(colors.info)
        local collapsingHeader = ui.CollapsingHeader(group.Header, ImGuiTreeNodeFlags.DefaultOpen)
        ui.PopStyleColor()
        if collapsingHeader then
            ui.Indent()
            for _, itemData in ipairs(group.Items) do
                local m = moduleMap[itemData.Key]
                if m then
                    -- Read from staging, not Chalk
                    local currentVal = staging.modules[m.id] or false
                    local val, chg = ui.Checkbox(itemData.Name, currentVal)
                    if chg then
                        ToggleModule(m, val)
                    end
                    if ui.IsItemHovered() and itemData.Tooltip and itemData.Tooltip ~= "" then
                        ui.SetTooltip(itemData.Tooltip)
                    end
                end
            end
            ui.Unindent()
        end
        ui.Spacing()
    end
end

-- =============================================================================
-- MAIN WINDOW
-- =============================================================================

local function DrawMainWindow()
    -- Read from staging, not Chalk
    local val, chg = ui.Checkbox("Enable Mod", staging.ModEnabled)
    if chg then
        staging.ModEnabled = val
        config.ModEnabled = val  -- write to Chalk once (event handler)
        if not val then
            -- Disable all: update staging + Chalk
            for _, m in ipairs(Discovery.modules) do
                if staging.modules[m.id] then
                    m.definition.disable()
                end
                -- Keep staging.modules as-is so re-enable restores previous state
            end
            local hammerMod = Discovery.getHammerModule()
            if hammerMod and staging.HammerEnabled then
                hammerMod.public.definition.disable()
            end
        else
            -- Re-enable from staging state
            for _, m in ipairs(Discovery.modules) do
                if staging.modules[m.id] then
                    m.definition.enable()
                end
            end
            local hammerMod = Discovery.getHammerModule()
            if hammerMod and staging.HammerEnabled then
                hammerMod.public.definition.enable()
            end
        end
        SetupRunData()
        Core.SetModMarker(val)
    end
    if ui.IsItemHovered() then ui.SetTooltip("Toggle the entire modpack on or off.") end

    if not staging.ModEnabled then
        ui.Separator()
        DrawColoredText(colors.warning, "Mod is currently disabled. All changes have been reverted.")
        return
    end

    ui.Spacing()
    ui.Separator()

    ui.BeginChild("TabContentRegion", 0, 0, false)

    local winW = ui.GetWindowWidth()
    local hammerMod = Discovery.getHammerModule()
    local categories = Discovery.categories

    if ui.BeginTabBar("ModpackTabs") then
        -- TAB: QUICK SETUP
        if ui.BeginTabItem("Quick Setup") then
            ui.Spacing()
            DrawColoredText(colors.info, "Select a profile to automatically configure the modpack:")
            ui.Spacing()

            if slotLabelsDirty then RebuildSlotLabels() end

            local comboPreview = "Select..."
            if selectedProfileCombo > 0 and selectedProfileCombo <= NUM_PROFILES and slotOccupied[selectedProfileCombo] then
                comboPreview = slotLabels[selectedProfileCombo]
            end

            ui.PushItemWidth(winW * 0.45)
            if ui.BeginCombo("Profile", comboPreview) then
                for i = 1, NUM_PROFILES do
                    if slotOccupied[i] then
                        ui.PushID(i)
                        if ui.Selectable(slotLabels[i], i == selectedProfileCombo) then
                            selectedProfileCombo = i
                        end
                        if ui.IsItemHovered() then
                            local tip = profileStaging[i].Tooltip
                            if tip ~= "" then ui.SetTooltip(tip) end
                        end
                        ui.PopID()
                    end
                end
                ui.EndCombo()
            end
            ui.PopItemWidth()

            ui.SameLine()
            local sel = selectedProfileCombo
            if sel > 0 and sel <= NUM_PROFILES then
                local hash = profileStaging[sel].Hash
                if hash ~= "" then
                    if ui.Button("Load") then LoadProfile(hash) end
                end
            end

            ui.Separator()
            ui.Spacing()

            -- Bug fix bulk toggles
            if Discovery.byCategory["BugFixes"] then
                DrawColoredText(colors.info, "Toggle all bug fixes at once. Go to the Bug Fixes tab for individual control.")
                if bugFixStatusDirty then RebuildBugFixStatus() end
                DrawColoredText(colors.text, "Current Status: ")
                ui.SameLine()
                DrawColoredText(bugFixStatusColor, bugFixStatusText)
                ui.Spacing()

                if ui.Button("Enable All") then SetBugFixes(true) end
                ui.SameLine()
                if ui.Button("Disable All") then SetBugFixes(false) end

                ui.Separator()
                ui.Spacing()
            end

            -- Quick hammer select
            if hammerMod then
                DrawColoredText(colors.info, "Quick Hammer Select for your current aspect.")
                ui.Spacing()

                local currentWeapon = hammerMod.public.GetEquippedAspect()
                local weaponNameLabel = hammerMod.public.aspectLabels[currentWeapon] or "Unknown Weapon"

                if hammerMod.public.hammerData[currentWeapon] then
                    DrawHammerDropdown(currentWeapon, "Equipped: " .. weaponNameLabel)
                end
            end

            ui.EndTabItem()
        end

        -- TAB: HAMMERS
        if hammerMod and ui.BeginTabItem("Hammers") then
            ui.Spacing()

            -- Read from staging, not Chalk
            local hVal, hChg = ui.Checkbox("Enable First Hammer", staging.HammerEnabled)
            if hChg then
                ToggleHammer(hammerMod, hVal)
            end
            if ui.IsItemHovered() then
                ui.SetTooltip(hammerMod.public.definition.tooltip)
            end

            ui.Spacing()
            DrawColoredText(colors.info, "Select the guaranteed first hammer for each aspect.")
            ui.Spacing()

            for _, weaponKey in ipairs(hammerMod.public.weaponDrawOrder) do
                local weaponDisplayName = hammerMod.public.weaponLabels[weaponKey] or weaponKey

                if ui.CollapsingHeader(weaponDisplayName) then
                    ui.Indent()
                    local aspects = hammerMod.public.WeaponAspectMapping[weaponKey]
                    if aspects then
                        for _, aspectKey in ipairs(aspects) do
                            local aspectDisplayName = hammerMod.public.aspectLabels[aspectKey] or aspectKey
                            DrawHammerDropdown(aspectKey, aspectDisplayName)
                        end
                    end
                    ui.Unindent()
                end
            end
            ui.Spacing()
            ui.EndTabItem()
        end

        -- DYNAMIC CATEGORY TABS
        for _, cat in ipairs(categories) do
            if ui.BeginTabItem(cat.label) then
                ui.Spacing()
                DrawCheckboxGroup(Discovery.categoryLayouts[cat.key], cat.key)
                ui.EndTabItem()
            end
        end

        -- TAB: PROFILES
        if ui.BeginTabItem("Profiles") then
            ui.Spacing()

            -- Export / Import
            PushTextColor(colors.info)
            ui.CollapsingHeader("Export / Import", ImGuiTreeNodeFlags.DefaultOpen)
            ui.PopStyleColor()
            ui.Indent()

            -- Read cached hash (computed from staging, not Chalk)
            local currentHash, boolHash = GetCachedHash()
            ui.Text("Current Hash:")
            ui.SameLine()
            DrawColoredText(colors.success, boolHash)
            local hammerPayload = string.sub(currentHash, #boolHash + 1)
            if hammerPayload ~= "" then
                ui.SameLine()
                DrawColoredText(colors.textDisabled, hammerPayload)
            end
            ui.SameLine()
            if ui.Button("Copy") then
                ui.SetClipboardText(excludeHammers and boolHash or currentHash)
                SetImportFeedback("Copied to clipboard!", colors.success)
            end
            ui.SameLine()
            local exVal, exChg = ui.Checkbox("Exclude Hammers", excludeHammers)
            if exChg then excludeHammers = exVal end

            ui.Spacing()
            ui.Text("Import Hash:")
            ui.SameLine()
            ui.PushItemWidth(winW * 0.4)
            local newText, changed = ui.InputText("##ImportHash", importHashBuffer, 256)
            if changed then importHashBuffer = newText end
            ui.PopItemWidth()
            ui.SameLine()
            if ui.Button("Paste") then
                local clip = ui.GetClipboardText()
                if clip then importHashBuffer = clip end
            end
            ui.SameLine()
            if ui.Button("Import") then
                if LoadProfile(importHashBuffer) then
                    SetImportFeedback("Imported successfully!", colors.success)
                else
                    SetImportFeedback("Invalid hash.", colors.error)
                end
            end
            if importFeedback then
                if os.clock() - importFeedbackTime > FEEDBACK_DURATION then
                    importFeedback = nil
                else
                    ui.SameLine()
                    DrawColoredText(importFeedbackColor, importFeedback)
                end
            end

            ui.Unindent()
            ui.Spacing()
            ui.Separator()
            ui.Spacing()

            -- Profile Slot Selector
            PushTextColor(colors.info)
            ui.CollapsingHeader("Saved Profiles", ImGuiTreeNodeFlags.DefaultOpen)
            ui.PopStyleColor()
            ui.Indent()

            if slotLabelsDirty then RebuildSlotLabels() end

            ui.PushItemWidth(winW * 0.3)
            if ui.BeginCombo("Slot", slotLabels[selectedProfileSlot]) then
                for i, label in ipairs(slotLabels) do
                    if ui.Selectable(label, i == selectedProfileSlot) then
                        selectedProfileSlot = i
                    end
                end
                ui.EndCombo()
            end
            ui.PopItemWidth()

            ui.Spacing()

            -- Read from profileStaging, not Chalk
            local ps = profileStaging[selectedProfileSlot]
            local hasData = ps.Hash ~= ""

            ui.Text("Name:")
            ui.SameLine()
            ui.PushItemWidth(winW * 0.2)
            local newName, nameChanged = ui.InputText("##SlotName", ps.Name, 64)
            if nameChanged then
                ps.Name = newName
                config.Profiles[selectedProfileSlot].Name = newName  -- write to Chalk
                slotLabelsDirty = true
            end
            ui.PopItemWidth()

            ui.Text("Tooltip:")
            ui.SameLine()
            ui.PushItemWidth(winW * 0.8)
            local newTooltip, tooltipChanged = ui.InputText("##SlotTooltip", ps.Tooltip, 256)
            if tooltipChanged then
                ps.Tooltip = newTooltip
                config.Profiles[selectedProfileSlot].Tooltip = newTooltip  -- write to Chalk
            end
            ui.PopItemWidth()

            if hasData then
                ui.Text("Hash:")
                ui.SameLine()
                DrawColoredText(colors.textDisabled, ps.Hash)
            end

            ui.Spacing()

            if ui.Button("Save Current") then
                local h = GetCachedHash()
                ps.Hash = h
                config.Profiles[selectedProfileSlot].Hash = h  -- write to Chalk
                if ps.Name == "" then
                    ps.Name = "Profile " .. selectedProfileSlot
                    config.Profiles[selectedProfileSlot].Name = ps.Name
                end
                slotLabelsDirty = true
            end

            if hasData then
                ui.SameLine()
                if ui.Button("Load") then LoadProfile(ps.Hash) end
                ui.SameLine()
                if ui.Button("Clear") then
                    ps.Name = ""
                    ps.Hash = ""
                    ps.Tooltip = ""
                    local cp = config.Profiles[selectedProfileSlot]
                    cp.Name = ""
                    cp.Hash = ""
                    cp.Tooltip = ""
                    slotLabelsDirty = true
                end
                if ui.IsItemHovered() then
                    ui.SetTooltip("Permanently clears this profile slot.")
                end
            end

            ui.Unindent()
            ui.Spacing()
            ui.Separator()
            ui.Spacing()

            if ui.Button("Restore Default Profiles") then
                for i = 1, NUM_PROFILES do
                    local d = defaultProfiles[i]
                    local cp = config.Profiles[i]  -- Chalk write
                    if d then
                        profileStaging[i] = { Name = d.Name, Hash = d.Hash, Tooltip = d.Tooltip }
                        cp.Name = d.Name
                        cp.Hash = d.Hash
                        cp.Tooltip = d.Tooltip
                    else
                        profileStaging[i] = { Name = "", Hash = "", Tooltip = "" }
                        cp.Name = ""
                        cp.Hash = ""
                        cp.Tooltip = ""
                    end
                end
                slotLabelsDirty = true
            end
            if ui.IsItemHovered() then
                ui.SetTooltip("Overwrites ALL profile slots with the shipped defaults. Custom profiles will be lost.")
            end

            ui.Spacing()
            ui.EndTabItem()
        end

        ui.EndTabBar()
    end

    ui.EndChild()
end

-- =============================================================================
-- REGISTRATION
-- =============================================================================

local showModWindow = false

rom.gui.add_imgui(function()
    if showModWindow then
        PushTheme()
        if ui.Begin("Speedrun Modpack", true) then
            DrawMainWindow()
            ui.End()
        else
            showModWindow = false
        end
        PopTheme()
    end
end)

rom.gui.add_to_menu_bar(function()
    if ui.BeginMenu("Modpack") then
        if ui.MenuItem("Toggle Mod Menu") then
            showModWindow = not showModWindow
        end
        ui.EndMenu()
    end
end)
