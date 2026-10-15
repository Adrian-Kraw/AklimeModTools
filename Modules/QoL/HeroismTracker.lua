-- Modules/QoL/HeroismTracker.lua
-- Shows "HT AKTIV" on screen when Heroism / Bloodlust /
-- Drums or the related exhaustion debuff is active.
-- Position freely movable, is saved.

-- ============================================================
-- Spell-IDs
-- ============================================================

-- Active haste buffs (40 seconds)
local L = AklimeModL or {}

local BUFF_IDS = {
    [2825]    = true, -- Bloodlust
    [32182]   = true, -- Heroism
    [80353]   = true, -- Time Warp
    [90355]   = true, -- Ancient Hysteria
    [160452]  = true, -- Netherwinds
    [264667]  = true, -- Primal Rage
    [390386]  = true, -- Fury of the Aspects (Evoker)
    [466904]  = true, -- Harrier's Cry (Hunter Marksmanship, since 11.1)
    [178207]  = true, -- Drums of Wrath (WoD)
    [230935]  = true, -- Drums of the Mountain (Legion)
    [256740]  = true, -- Drums of the Maelstrom (BfA)
    [309658]  = true, -- Drums of Deadly Ferocity (SL)
    [381301]  = true, -- Drums of Fury (DF)
    [424258]  = true, -- Thundering Drums (TWW)
    [424261]  = true, -- Void-touched Drums (TWW)
    [1243972] = true, -- Void Drum (Midnight)
}

-- Exhaustion debuffs of the lust sources. In instanced combat Blizzard
-- locks the haste buffs themselves (Secret Values), but the exhaustion
-- stays readable (verified in game). It appears at the same moment as the
-- buff and always lasts 600 seconds, from which the buff end can be derived
-- exactly, no matter who cast the lust and which aura ID the buff has.
local SATED_IDS = {
    [57723]  = true, -- Exhaustion (Heroism, Drums)
    [57724]  = true, -- Sated (Bloodlust)
    [80354]  = true, -- Temporal Displacement (Time Warp)
    [264689] = true, -- Fatigued (Primal Rage)
    [390435] = true, -- Exhaustion (Fury of the Aspects)
}

local BUFF_DURATION  = 40  -- lust buffs always last 40 seconds
local SATED_DURATION = 600 -- exhaustion always lasts 10 minutes


-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.heroismTracker then return AklimeModDB.heroismTracker end
    return {}
end

-- ============================================================
-- Aura check
-- ============================================================
-- issecretvalue only exists since 12.0
local issecretvalue = issecretvalue or function() return false end

-- true = buff active, false = no buff, nil = values locked (Secret).
-- On true expirationTime is also returned if readable.
-- Note: in instanced combat Blizzard locks individual auras completely.
-- The per ID query returns nil for locked auras (denies them),
-- so an active lust buff can be invisible here.
local function CheckAuras()
    -- GetPlayerAuraBySpellID: the spell ID is passed as a parameter,
    -- no access to protected fields of the return table is needed.
    -- UnitBuff and aura.spellId are not accessible in TWW.
    local secretSeen = false
    for spellID in pairs(BUFF_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if issecretvalue(aura) then
            secretSeen = true
        elseif aura then
            local expires = aura.expirationTime
            if issecretvalue(expires) then expires = nil end
            return true, expires
        end
    end
    if secretSeen then return nil end
    return false
end

-- Derives the buff end from the exhaustion (GetTime based).
-- Exhaustion appears together with the buff and lasts 600 seconds:
-- buff end = exhaustion end - 600 + 40.
-- nil when no readable exhaustion is active.
local function GetBuffEndFromSated()
    for spellID in pairs(SATED_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if not issecretvalue(aura) and aura then
            local expires = aura.expirationTime
            if not issecretvalue(expires) and type(expires) == "number" and expires > 0 then
                return expires - SATED_DURATION + BUFF_DURATION
            end
        end
    end
    return nil
end

-- ============================================================
-- Frame
-- ============================================================
local M = {}
AklimeMod_HeroismTracker = M

local frame = nil

local function SavePosition()
    local db = GetDB()
    local x, y = frame:GetCenter()
    local scale = frame:GetEffectiveScale()
    db.x = x * scale
    db.y = y * scale
end

local function ApplyPosition()
    local db = GetDB()
    frame:ClearAllPoints()
    if db.x and db.y then
        local scale = frame:GetEffectiveScale()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x / scale, db.y / scale)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
end

-- Up to this GetTime() point the buff counts as reliably active.
-- Set by the last readable aura or the exhaustion derivation.
-- Carries the display through phases where the aura data is locked.
local forcedUntil = 0

local function UpdateDisplay()
    if not frame then return end
    local db = GetDB()
    if not db.enabled then
        frame:Hide()
        return
    end
    -- Re-apply on every update: the frame's actual mouse state can drift
    -- from the DB flag (observed in combat), so enforce it continuously
    -- instead of trusting a single EnableMouse call from BuildFrame/SetLocked.
    frame:EnableMouse(db.locked == false)
    local now = GetTime()
    local active, expires = CheckAuras()
    if active then
        if expires and expires > now then forcedUntil = expires end
        frame:Show()
        return
    end
    -- No direct hit: derive the buff end from the exhaustion.
    -- Covers buffs locked in combat and unknown aura IDs,
    -- regardless of who cast the lust.
    local satedEnd = GetBuffEndFromSated()
    if satedEnd and satedEnd > now then
        forcedUntil = satedEnd
        frame:Show()
        return
    end
    if active == false then
        -- Values readable, no buff, no fresh exhaustion: definitely off
        forcedUntil = 0
        frame:Hide()
        return
    end
    -- Values locked: last reliable knowledge decides
    if now < forcedUntil then
        frame:Show()
    else
        frame:Hide()
    end
end

local function SliderToPx(v)
    -- 0 = 18px (default), 100 = 72px (huge)
    return math.floor(18 + v * 0.54)
end

local function ApplyFontSize()
    if not frame then return end
    local px = SliderToPx(GetDB().fontSizeSlider or 20)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
    -- Width generously sized so OUTLINE is not cut off
    frame:SetSize(px * 10, px * 2)
end

local function BuildFrame()
    if frame then return end

    frame = CreateFrame("Frame", "AklimeMod_HeroismTrackerFrame", UIParent)
    frame:SetSize(200, 48)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", SliderToPx(GetDB().fontSizeSlider or 20), "OUTLINE")
    text:SetAllPoints(frame)
    text:SetText(L["ht_active"])
    text:SetTextColor(1, 1, 1, 1)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    frame.text = text

    -- Drag: RegisterForDrag would block frame:Show() in combat (InCombatLockdown).
    -- OnMouseDown/OnMouseUp achieve the same without this restriction.
    frame:SetMovable(true)
    frame:EnableMouse(GetDB().locked == false)
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not M:IsLocked() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    -- Tooltip when not locked
    frame:SetScript("OnEnter", function(self)
        if not GetDB().locked then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("HT-Tracker", 1, 0.82, 0)
            GameTooltip:AddLine(L["ht_drag"], 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ApplyFontSize()
    ApplyPosition()
    frame:Hide()
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled() return GetDB().enabled == true end
-- nil and true count as locked. Only explicit false = unlocked.
function M:IsLocked()  return GetDB().locked ~= false end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    if v then
        BuildFrame()
        UpdateDisplay()
    elseif frame then
        frame:Hide()
    end
end

function M:SetLocked(v)
    GetDB().locked = v ~= false  -- false stays false, nil/true becomes true
    -- EnableMouse is not a protected call on this plain, non-secure frame,
    -- so it can be applied immediately even during combat.
    if frame then
        frame:EnableMouse(GetDB().locked == false)
    end
end

function M:GetFontSizeSlider() return GetDB().fontSizeSlider or 20 end
function M:SetFontSizeSlider(v)
    GetDB().fontSizeSlider = v
    ApplyFontSize()
end

function M:ShowPreview()
    BuildFrame()
    frame:Show()
end

function M:HidePreview()
    UpdateDisplay()
end

-- ============================================================
-- Events
-- ============================================================

-- Ticker runs only during combat and polls UpdateDisplay every second.
-- Fallback in case UNIT_AURA does not fire reliably.
local combatTicker = nil

local eventFrame = CreateFrame("Frame")
-- RegisterUnitEvent guarantees UNIT_AURA delivery for the player unit.
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        local db = GetDB()
        -- Clean up the old ticker: after a zone change the combat state is
        -- reset, a stale ticker would otherwise keep running.
        if combatTicker then combatTicker:Cancel(); combatTicker = nil end
        if db.enabled then
            BuildFrame()
            UpdateDisplay()
            -- Reconnect or instance entry in the middle of combat:
            -- PLAYER_REGEN_DISABLED does not fire again, start the ticker manually.
            if UnitAffectingCombat("player") then
                combatTicker = C_Timer.NewTicker(1, function()
                    if GetDB().enabled then UpdateDisplay() end
                end)
            end
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if GetDB().enabled then
            -- Check immediately (e.g. drums before the pull)
            C_Timer.After(0, UpdateDisplay)
            -- Ticker as fallback in case UNIT_AURA does not arrive
            if not combatTicker then
                combatTicker = C_Timer.NewTicker(1, function()
                    if GetDB().enabled then UpdateDisplay() end
                end)
            end
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if combatTicker then combatTicker:Cancel(); combatTicker = nil end
        C_Timer.After(0, UpdateDisplay)
        return
    end

    if event == "UNIT_AURA" then
        -- Immediate reaction, also outside of combat (e.g. preview).
        if GetDB().enabled then C_Timer.After(0, UpdateDisplay) end
    end
end)

-- ============================================================
-- Debug
-- ============================================================
SLASH_AKM_HT1 = "/akht"
SlashCmdList["AKM_HT"] = function(input)
    local cmd = strtrim(input or ""):lower()

    -- "/akht buffs": list all active buffs with spell ID,
    -- to identify unknown lust variants
    if cmd == "buffs" then
        print("|cFFFFD100Aklime Mod Tools HT:|r Active buffs:")
        local found = false
        for i = 1, 60 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            found = true
            if issecretvalue(aura) then
                print("  [secret]")
            else
                local name = aura.name
                local sid  = aura.spellId
                if issecretvalue(name) then name = "[secret]" end
                if issecretvalue(sid)  then sid  = "[secret]" end
                print(string.format("  %s = %s", tostring(name), tostring(sid)))
            end
        end
        if not found then print("  (none)") end
        return
    end

    local db = GetDB()
    print(string.format(
        "|cFFFFD100Aklime Mod Tools HT:|r Module: %s | Frame: %s | Combat: %s | Locked (DB): %s | Mouse enabled (frame): %s",
        db.enabled and "|cFF00FF00active|r" or "|cFFFF4444inactive|r",
        (frame and frame:IsShown()) and "|cFF00FF00shown|r" or "hidden",
        UnitAffectingCombat("player") and "yes" or "no",
        M:IsLocked() and "yes" or "no",
        (frame and frame:IsMouseEnabled()) and "|cFFFF4444YES|r" or "no"
    ))

    local foundBuff, buffSecret = nil, false
    for spellID in pairs(BUFF_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if issecretvalue(aura) then
            buffSecret = true
        elseif aura then
            foundBuff = spellID
            break
        end
    end
    local foundSated, satedSecret = nil, false
    for spellID in pairs(SATED_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if issecretvalue(aura) then
            satedSecret = true
        elseif aura then
            foundSated = spellID
            break
        end
    end

    local buffText = "|cFFFF4444none|r"
    if foundBuff then
        buffText = "|cFF00FF00" .. foundBuff .. "|r"
    elseif buffSecret then
        buffText = "|cFFFF8800SECRET|r"
    end
    local satedText = "no"
    if foundSated then
        satedText = "|cFFFF4444" .. foundSated .. "|r"
    elseif satedSecret then
        satedText = "|cFFFF8800SECRET|r"
    end

    -- Buff end derived from the exhaustion
    local derivedText = "no"
    local satedEnd = GetBuffEndFromSated()
    if satedEnd then
        local remain = satedEnd - GetTime()
        if remain > 0 then
            derivedText = string.format("|cFF00FF00%.0fs left|r", remain)
        else
            derivedText = "expired"
        end
    end

    print(string.format(
        "  HT buff: %s | Exhaustion: %s | Derived buff: %s | Ticker: %s",
        buffText,
        satedText,
        derivedText,
        combatTicker and "running" or "off"
    ))
end
