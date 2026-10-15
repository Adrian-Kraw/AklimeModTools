-- Modules/QoL/Summons.lua
-- Automatically accepts summon requests.

local L = AklimeModL or {}

local M = {}
AklimeMod_Summons = M

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.summons then return AklimeModDB.summons end
    return {}
end

-- Seconds to wait before accepting. 0 accepts right away.
local DELAY_MIN, DELAY_MAX = 0, 10

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled() return GetDB().enabled == true end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
end

function M:GetDelay()
    local d = GetDB().delay
    if type(d) ~= "number" then return DELAY_MIN end
    return math.max(DELAY_MIN, math.min(DELAY_MAX, d))
end

function M:SetDelay(v)
    GetDB().delay = math.max(DELAY_MIN, math.min(DELAY_MAX, tonumber(v) or DELAY_MIN))
end

-- ============================================================
-- Accept
-- ============================================================
-- ConfirmSummon() was moved to C_SummonInfo.ConfirmSummon() in patch 8.1.0
-- and the old global no longer exists. C_SummonRequest.Accept is kept as
-- a fallback in case a future patch renames it again.
local function Accept(summoner, area)
    if C_SummonInfo and C_SummonInfo.ConfirmSummon then
        C_SummonInfo.ConfirmSummon()
    elseif C_SummonRequest and C_SummonRequest.Accept then
        C_SummonRequest.Accept()
    elseif ConfirmSummon then
        ConfirmSummon()
    end
    StaticPopup_Hide("CONFIRM_SUMMON")

    print("|cFFFFD100Aklime Mod Tools:|r " .. string.format(L["msg_summon_accepted"], summoner, area))
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CONFIRM_SUMMON")
eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event ~= "CONFIRM_SUMMON" then return end
    if not GetDB().enabled then return end

    -- summoner/area come as event args or via the new C_SummonRequest API.
    local summoner = (type(arg1) == "string" and arg1 ~= "") and arg1
                  or (C_SummonRequest and C_SummonRequest.GetSummonerName and C_SummonRequest.GetSummonerName())
                  or (GetSummonConfirmSummoner and GetSummonConfirmSummoner())
                  or "?"
    local area     = (type(arg2) == "string" and arg2 ~= "") and arg2
                  or (C_SummonRequest and C_SummonRequest.GetSummonAreaName and C_SummonRequest.GetSummonAreaName())
                  or (GetSummonConfirmAreaName and GetSummonConfirmAreaName())
                  or "?"

    local delay = M:GetDelay()
    if delay <= 0 then
        Accept(summoner, area)
        return
    end

    -- With a delay the player can still answer the dialog themselves, so only
    -- accept when it is still open
    C_Timer.After(delay, function()
        if not GetDB().enabled then return end
        if StaticPopup_Visible and not StaticPopup_Visible("CONFIRM_SUMMON") then return end
        Accept(summoner, area)
    end)
end)
