-- Modules/QoL/TalentReminder.lua
-- Shows a popup when entering an instance: "Do the talents fit?"
-- Only on a real entry, not on login or reload.

local L = AklimeModL or {}

local function GetDB()
    if AklimeModDB and AklimeModDB.talentReminder then return AklimeModDB.talentReminder end
    return {}
end

-- ============================================================
-- Open the talent window
-- ============================================================
local function OpenTalents()
    C_AddOns.LoadAddOn("Blizzard_PlayerSpells")
    if PlayerSpellsFrame then
        if PlayerSpellsFrame:IsShown() then
            HideUIPanel(PlayerSpellsFrame)
        else
            ShowUIPanel(PlayerSpellsFrame)
        end
    end
end

-- ============================================================
-- Popup
-- ============================================================
StaticPopupDialogs["AKLIMEMOD_TALENT_REMINDER"] = {
    text         = L["talent_popup_text"],
    button1      = L["talent_popup_ok"],
    button2      = L["talent_popup_open"],
    OnAccept     = function() end,
    OnCancel     = function() OpenTalents() end,
    timeout      = 0,
    whileDead    = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ============================================================
-- API
-- ============================================================
local M = {}
AklimeMod_TalentReminder = M

function M:IsEnabled() return GetDB().enabled == true end
function M:SetEnabled(v) GetDB().enabled = v and true or false end

-- ============================================================
-- Event
-- ============================================================
local wasInInstance = false

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, _, isLogin, isReload)
    local inInstance = IsInInstance()

    if not isLogin and not isReload and inInstance and not wasInInstance then
        if GetDB().enabled then
            local name = GetInstanceInfo() or L["talent_popup_instance"]
            StaticPopup_Show("AKLIMEMOD_TALENT_REMINDER", name)
        end
    end

    if not inInstance then
        StaticPopup_Hide("AKLIMEMOD_TALENT_REMINDER")
    end

    wasInInstance = inInstance
end)
