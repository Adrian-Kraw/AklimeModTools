-- Modules/QoL/ReadyCheck.lua
-- Automatically accept ready checks with a visible countdown.

local function GetDB()
    if AklimeModDB and AklimeModDB.readyCheck then return AklimeModDB.readyCheck end
    return { enabled = false }
end

local countdown  = 0
local timerFrame = CreateFrame("Frame")

local function GetYesButton()
    return _G["ReadyCheckFrameYesButton"]
end

local function StopTimer()
    timerFrame:SetScript("OnUpdate", nil)
    countdown = 0
    local btn = GetYesButton()
    if btn then btn:SetText(READY) end
end

-- True once the player has clicked Ready or Not Ready on their own
local function HasAnswered()
    local status = GetReadyCheckStatus and GetReadyCheckStatus("player")
    return status == "ready" or status == "notready"
end

local function StartTimer(delay)
    countdown = delay
    timerFrame:SetScript("OnUpdate", function(_, elapsed)
        if not GetDB().enabled then StopTimer(); return end
        countdown = countdown - elapsed
        local btn = GetYesButton()
        if btn then
            btn:SetFormattedText("%s  %.1f", READY, math.max(countdown, 0))
        end
        if countdown <= 0 then
            StopTimer()
            -- A decision made by hand is never overridden
            if HasAnswered() then return end
            ConfirmReadyCheck(1)
            if ReadyCheckFrame then ReadyCheckFrame:Hide() end
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_FINISHED")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "READY_CHECK_CONFIRM" then
        -- The player answered by hand, so the countdown must not run on
        if unit and UnitIsUnit(unit, "player") then StopTimer() end
    elseif event == "READY_CHECK" then
        if GetDB().enabled then
            StartTimer(GetDB().delay or 3)
        end
    elseif event == "READY_CHECK_FINISHED" then
        StopTimer()
    end
end)

AklimeMod_ReadyCheck = {
    IsEnabled  = function() return GetDB().enabled == true end,
    SetEnabled = function(v) GetDB().enabled = v and true or false end,
    GetDelay   = function() return GetDB().delay or 3 end,
    SetDelay   = function(v) GetDB().delay = v end,
}
