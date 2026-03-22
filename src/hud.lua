-- =============================================================================
-- HUD SYSTEM: Mod Mark Display
-- =============================================================================
-- Manages the modpack hash display on the HUD.
-- Hash logic lives in hash.lua (Core.Hash).

local Hash = Core.Hash

-- =============================================================================
-- HUD MARK
-- =============================================================================

local _, initBoolHash = Hash.GetConfigHash()
local currentHash = config.ModEnabled and initBoolHash or ""
local displayedHash = nil

ScreenData.HUD.ComponentData.ModpackMark = {
    RightOffset = 20,
    Y = 250,
    TextArgs = {
        Text = "",
        Font = "MonospaceTypewriterBold",
        FontSize = 18,
        Color = Core.Theme.colors.text,
        ShadowRed = 0.1, ShadowBlue = 0.1, ShadowGreen = 0.1,
        OutlineColor = { 0.113, 0.113, 0.113, 1 }, OutlineThickness = 2,
        ShadowAlpha = 1.0, ShadowBlur = 1, ShadowOffset = { 0, 4 },
        Justification = "Right",
        VerticalJustification = "Top",
        DataProperties = { OpacityWithOwner = true },
    },
}

local function UpdateModMark()
    if not HUDScreen or not HUDScreen.Components.ModpackMark then return end
    if currentHash == displayedHash then return end

    if currentHash == "" then
        ModifyTextBox({ Id = HUDScreen.Components.ModpackMark.Id, ClearText = true })
    else
        ModifyTextBox({ Id = HUDScreen.Components.ModpackMark.Id, Text = currentHash })
    end
    displayedHash = currentHash
end

modutil.mod.Path.Wrap("ShowHealthUI", function(base)
    base()
    if config.ModEnabled then
        displayedHash = nil
        UpdateModMark()
    end
end)

-- =============================================================================
-- PUBLIC API (attached to Core global)
-- =============================================================================

Core.GetConfigHash = Hash.GetConfigHash
Core.ApplyConfigHash = Hash.ApplyConfigHash

function Core.UpdateHash()
    local _, boolHash = Hash.GetConfigHash()
    currentHash = boolHash
    UpdateModMark()
end

function Core.SetModMarker(enabled)
    if enabled then
        local _, boolHash = Hash.GetConfigHash()
        currentHash = boolHash
    else
        currentHash = ""
    end
    displayedHash = nil
    UpdateModMark()
end
