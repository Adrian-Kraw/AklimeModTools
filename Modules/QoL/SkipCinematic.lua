-- Modules/QoL/SkipCinematic.lua
-- Automatically skip cutscenes and cinematics.

local L = AklimeModL or {}

local CHAT_PREFIX = "|cFFFFD100Aklime Mod Tools:|r "

local function GetDB()
    if AklimeModDB and AklimeModDB.skipCinematic then return AklimeModDB.skipCinematic end
    return { enabled = false }
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CINEMATIC_START")
eventFrame:RegisterEvent("PLAY_MOVIE")
-- Cancels a running cinematic the same way the game does in
-- CinematicFrame_CancelCinematic. The global CancelCinematic is gone in 12.x.
-- Blizzard's third case, leaving the vehicle, is left out on purpose. It would
-- eject the player, and that is not what skipping a cutscene should do.
-- Returns true when something was actually stopped
local function StopRunningCinematic(canBeCancelled)
    if canBeCancelled then
        if StopCinematic then
            StopCinematic()
            return true
        end
    elseif CanCancelScene and CanCancelScene() and CancelScene then
        CancelScene()
        return true
    end
    return false
end

local function PrintSkipped()
    print(CHAT_PREFIX .. (L["skip_cinematic_done"] or "A cutscene was skipped!"))
end

eventFrame:SetScript("OnEvent", function(_, event, canBeCancelled)
    if not GetDB().enabled then return end
    if event == "CINEMATIC_START" then
        if StopRunningCinematic(canBeCancelled) then PrintSkipped() end
    elseif event == "PLAY_MOVIE" then
        if MovieFrame and MovieFrame.StopMovie then
            MovieFrame:StopMovie()
            PrintSkipped()
        end
    end
end)

AklimeMod_SkipCinematic = {
    IsEnabled  = function() return GetDB().enabled == true end,
    SetEnabled = function(v) GetDB().enabled = v and true or false end,
}
