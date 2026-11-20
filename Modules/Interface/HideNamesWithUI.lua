-- Modules/Interface/HideNamesWithUI.lua
-- Hides the names of all players and NPCs while the interface is hidden
-- (Alt+Z by default) and shows them again with the interface.
-- The original CVar values are kept in the DB, so they are restored even if
-- the game was closed while the interface was hidden.

local L = AklimeModL or {}

local HIDDEN_VALUE = "0"

-- CVars that are missing in the client are skipped, GetCVar returns nil for them
local NAME_CVARS = {
    "UnitNameOwn",
    "UnitNameNPC",
    "UnitNameNonCombatCreatureName",
    "UnitNameHostleNPC",
    "UnitNameInteractiveNPC",
    "UnitNameFriendlySpecialNPCName",
    "UnitNameFriendlyPlayerName",
    "UnitNameFriendlyPetName",
    "UnitNameFriendlyGuardianName",
    "UnitNameFriendlyTotemName",
    "UnitNameFriendlyMinionName",
    "UnitNameEnemyPlayerName",
    "UnitNameEnemyPetName",
    "UnitNameEnemyGuardianName",
    "UnitNameEnemyTotemName",
    "UnitNameEnemyMinionName",
    -- Nameplates show a name too. Friendly NPCs have a switch of their own, a
    -- plate that stays on there carries the name and the interact icon.
    "nameplateShowAll",
    "nameplateShowEnemies",
    "nameplateShowFriends",
    "nameplateShowFriendlyNpcs",
    "nameplateShowFriendlyPets",
    "nameplateShowFriendlyGuardians",
    "nameplateShowFriendlyTotems",
    "nameplateShowFriendlyMinions",
    "nameplateShowEnemyPets",
    "nameplateShowEnemyGuardians",
    "nameplateShowEnemyTotems",
    "nameplateShowEnemyMinions",
    "nameplateShowEnemyMinus",
    -- Found in a client dump while the interface was hidden: they were still on.
    -- Plates of friendly players, the name forced onto plates, titles, guild
    -- lines and the own last name.
    "nameplateShowFriendlyPlayers",
    "nameplateForceShowUnitName",
    "UnitNameGuildTitle",
    "UnitNamePlayerGuild",
    "UnitNamePlayerPVPTitle",
    "UnitSurnameOwn",
    "UnitNameFocused",
    -- Icon and name above the NPC or object the interact key would use. They
    -- hang in the world like nameplates, so hiding the interface leaves them.
    "SoftTargetIconInteract",
    "SoftTargetIconGameObject",
    "SoftTargetLowPriorityIcons",
    "SoftTargetIconEnemy",
    "SoftTargetIconFriend",
    "SoftTargetNameplateInteract",
    "SoftTargetNameplateEnemy",
    "SoftTargetNameplateFriend",
}

local function GetDB()
    return AklimeModDB and AklimeModDB.hideNamesWithUI
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- CVars the game did not turn off right after we asked, filled by HideNames
local refused = {}

local function IsOff(name)
    return tonumber(GetCVar(name)) == tonumber(HIDDEN_VALUE)
end

-- saved is only set while the names are hidden
local function HideNames()
    local db = GetDB()
    if not db or db.saved then return end

    wipe(refused)
    local saved = {}
    for _, name in ipairs(NAME_CVARS) do
        local value = GetCVar(name)
        if value ~= nil then
            saved[name] = value
            SetCVar(name, HIDDEN_VALUE)
            if not IsOff(name) then refused[name] = true end
        end
    end
    db.saved = saved
end

-- The chat is not visible while the interface is hidden, so a problem is
-- written when it returns: which settings the game refused and which were
-- switched on again meanwhile. Nothing is written when all went well.
local function PrintReport(saved)
    local notAccepted, switchedOn = {}, {}
    for name in pairs(saved) do
        if refused[name] then
            notAccepted[#notAccepted + 1] = name
        elseif not IsOff(name) then
            switchedOn[#switchedOn + 1] = name .. "=" .. tostring(GetCVar(name))
        end
    end
    table.sort(notAccepted)
    table.sort(switchedOn)

    local prefix = "|cFFFFD100Aklime Mod Tools:|r "
    if #notAccepted > 0 then
        print(prefix .. (L["names_report_refused"] or "The game did not accept: %s"):format(table.concat(notAccepted, ", ")))
    end
    if #switchedOn > 0 then
        print(prefix .. (L["names_report_reset"] or "Switched on again meanwhile: %s"):format(table.concat(switchedOn, ", ")))
    end
end

local function RestoreNames(showReport)
    local db = GetDB()
    if not db or not db.saved then return end

    if showReport then PrintReport(db.saved) end
    for name, value in pairs(db.saved) do
        SetCVar(name, value)
    end
    db.saved = nil
end

UIParent:HookScript("OnHide", function()
    if IsEnabled() then HideNames() end
end)
UIParent:HookScript("OnShow", function() RestoreNames(true) end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    -- The last session ended while the interface was hidden
    if UIParent:IsShown() then RestoreNames(false) end
end)

AklimeMod_HideNamesWithUI = {
    IsEnabled  = function() return IsEnabled() end,
    SetEnabled = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if not v then
            RestoreNames(false)
        elseif not UIParent:IsShown() then
            HideNames()
        end
    end,
}
