-- Modules/QoL/ManaWarning.lua
-- Sends a group warning at 30% (Low Mana) and 10% (OOM) mana.
--
-- Strategy:
--   Primary: UNIT_POWER_UPDATE + UnitPower("player"). Exact thresholds,
--   in and out of combat. Each threshold fires once and is only re-armed
--   when mana is 5 points above the threshold. This prevents
--   chat spam when mana hovers right around the threshold.
--
--   Fallback: in instanced combat Blizzard can lock the mana values
--   (Secret Values, 12.0). Then Blizzard's own signals take over:
--   COMBAT_TEXT_UPDATE "MANA_LOW" for Low and the "not enough mana"
--   spell fail in UIErrorsFrame for OOM, once each per combat.

-- ============================================================
-- Constants
-- ============================================================
local L = AklimeModL or {}

local THRESHOLD_LOW = 30
local THRESHOLD_OOM = 10
-- A threshold is only re-armed when mana is this many points above it
local REARM_MARGIN  = 5

local MSG_LOW = "BEWARE, I'M LOW ON MANA!"
local MSG_OOM = "OUT OF MANA - BELOW 10%"

-- issecretvalue exists only since 12.0
local issecretvalue = issecretvalue or function() return false end

-- ============================================================
-- DB / Toggle
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.manaWarning
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- ============================================================
-- Channel
-- ============================================================
local INSTANCE_CAT = LE_PARTY_CATEGORY_INSTANCE or 2

local function GetChatChannel()
    if IsInGroup(INSTANCE_CAT) then return "INSTANCE_CHAT" end
    if IsInRaid()              then return "RAID"           end
    if IsInGroup()             then return "PARTY"          end
    return nil
end

-- The global SendChatMessage only exists as a deprecation fallback and is
-- tied to the loadDeprecationFallbacks CVar. C_ChatInfo is the current API.
local function SendChat(msg, ch)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(msg, ch)
    else
        SendChatMessage(msg, ch)
    end
end

-- Returns true if a message was actually sent (solo: false).
local function Send(msg)
    local ch = GetChatChannel()
    if not ch then return false end
    SendChat(msg, ch)
    return true
end

-- For the UIErrorsFrame hook: sending from inside Blizzard's own call gets
-- the message blocked. One frame later the call stack is ours again.
local function SendSoon(msg)
    C_Timer.After(0, function() Send(msg) end)
end

-- ============================================================
-- State
-- ============================================================
-- Threshold path: once per drop below the threshold
local firedLow, firedOOM = false, false
-- Fallback path: once per low phase
local fallbackLowFired, fallbackOOMFired = false, false

-- Blizzard's signals repeat every ~10 sec as long as the state
-- persists. A longer gap between two signals means mana recovered
-- in between, so re-arm.
local FALLBACK_REARM_GAP = 15
local lastFallbackLow, lastFallbackOOM = 0, 0

local function ResetAll()
    firedLow, firedOOM = false, false
    fallbackLowFired, fallbackOOMFired = false, false
    lastFallbackLow, lastFallbackOOM = 0, 0
end

-- ============================================================
-- Read mana
-- ============================================================
-- nil = not evaluable (not a mana user or values locked).
local function GetManaPercent()
    if UnitPowerType("player") ~= Enum.PowerType.Mana then return nil end
    local cur = UnitPower("player", Enum.PowerType.Mana)
    local max = UnitPowerMax("player", Enum.PowerType.Mana)
    if issecretvalue(cur) or issecretvalue(max) then return nil end
    if not max or max == 0 then return nil end
    return cur / max * 100
end

-- ============================================================
-- Threshold logic (primary path)
-- ============================================================
local function CheckThresholds()
    if not IsEnabled() then return end
    local pct = GetManaPercent()
    if not pct then return end

    -- Rearm: only re-arms well above the threshold
    if pct >= THRESHOLD_LOW + REARM_MARGIN then firedLow = false end
    if pct >= THRESHOLD_OOM + REARM_MARGIN then firedOOM = false end

    if pct <= THRESHOLD_OOM then
        -- Set both flags so the 30% message does not also fire
        if not firedOOM and Send(MSG_OOM) then
            firedOOM = true
            firedLow = true
        end
    elseif pct <= THRESHOLD_LOW then
        if not firedLow and Send(MSG_LOW) then
            firedLow = true
        end
    end
end

-- ============================================================
-- Blizzard strings (localized)
-- ============================================================
local S_OUT_OF_MANA = nil

local function CacheStrings()
    S_OUT_OF_MANA = OUT_OF_MANA or ""
end

-- ============================================================
-- UIErrorsFrame hook (fallback for OOM when values are locked)
-- ============================================================
local uiHooked = false

local function HookUIErrors()
    if uiHooked then return end
    if not UIErrorsFrame then return end

    hooksecurefunc(UIErrorsFrame, "AddMessage", function(_, text)
        if not IsEnabled() then return end
        if type(text) ~= "string" then return end
        if S_OUT_OF_MANA == "" then return end
        -- Only step in when the threshold path cannot read the values
        if GetManaPercent() ~= nil then return end

        local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if clean:find(S_OUT_OF_MANA, 1, true) then
            local now = GetTime()
            -- Long gap since the last OOM fail: mana recovered, rearm
            if fallbackOOMFired and (now - lastFallbackOOM) > FALLBACK_REARM_GAP then
                fallbackOOMFired = false
            end
            lastFallbackOOM = now
            if not fallbackOOMFired then
                fallbackOOMFired = true
                -- Also set the low fallback and threshold flags so no
                -- redundant 30% warning follows right after
                fallbackLowFired = true
                lastFallbackLow = now
                firedOOM = true
                firedLow = true
                SendSoon(MSG_OOM)
            end
        end
    end)

    uiHooked = true
end

-- ============================================================
-- Events
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        frame:UnregisterEvent("ADDON_LOADED")
        frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        frame:RegisterEvent("COMBAT_TEXT_UPDATE")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        CacheStrings()
        HookUIErrors()

    elseif event == "UNIT_POWER_UPDATE" then
        if arg2 == "MANA" then
            CheckThresholds()
        end

    elseif event == "COMBAT_TEXT_UPDATE" then
        -- Fallback for low mana: Blizzard fires MANA_LOW itself, every
        -- ~10 sec as long as mana is low.
        -- Only step in when the threshold path cannot read the values.
        if arg1 == "MANA_LOW" and IsEnabled() then
            if GetManaPercent() == nil then
                local now = GetTime()
                -- Long gap since the last MANA_LOW: mana recovered, rearm
                if fallbackLowFired and (now - lastFallbackLow) > FALLBACK_REARM_GAP then
                    fallbackLowFired = false
                end
                lastFallbackLow = now
                if not fallbackLowFired then
                    fallbackLowFired = true
                    firedLow = true
                    Send(MSG_LOW)
                end
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- End of combat is always a safe reset for the fallback path
        fallbackLowFired = false
        fallbackOOMFired = false
        -- If the values are readable again now: check the state
        CheckThresholds()

    elseif event == "PLAYER_ENTERING_WORLD" then
        CacheStrings()
        HookUIErrors()
        ResetAll()
    end
end)

-- ============================================================
-- Debug
-- ============================================================
SLASH_AKM_MANA1 = "/akmana"
SlashCmdList["AKM_MANA"] = function(input)
    local cmd = strtrim(input or ""):lower()

    if cmd == "test" then
        local ch = GetChatChannel()
        if not ch then
            print("|cFFFF4444Aklime Mod Tools:|r " .. L["msg_mana_solo"])
            return
        end
        SendChat(MSG_LOW, ch)
        SendChat(MSG_OOM, ch)
    else
        local ch = GetChatChannel() or "nil (Solo)"
        local pct = GetManaPercent()
        print(string.format(
            "|cFFFFD100Aklime Mod Tools Mana:|r Channel: %s | Module: %s | Mana: %s",
            ch,
            IsEnabled() and "|cFF00FF00active|r" or "|cFFFF4444inactive|r",
            pct and string.format("%.1f%%", pct) or "unreadable"
        ))
        print(string.format(
            "  firedLow: %s | firedOOM: %s | fallbackLow: %s | fallbackOOM: %s",
            tostring(firedLow), tostring(firedOOM),
            tostring(fallbackLowFired), tostring(fallbackOOMFired)
        ))
    end
end

-- ============================================================
-- API (Categories.lua)
-- ============================================================
AklimeMod_ManaWarning = {
    IsEnabled  = function() return IsEnabled() end,
    SetEnabled = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if not v then ResetAll() end
    end,
}
