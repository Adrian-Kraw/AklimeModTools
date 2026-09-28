-- Modules/QoL/SkipCinematic.lua
-- Automatically skip cutscenes and cinematics.

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
local function StopRunningCinematic(canBeCancelled)
    if canBeCancelled then
        if StopCinematic then StopCinematic() end
    elseif CanCancelScene and CanCancelScene() and CancelScene then
        CancelScene()
    end
end

eventFrame:SetScript("OnEvent", function(_, event, canBeCancelled)
    if not GetDB().enabled then return end
    if event == "CINEMATIC_START" then
        StopRunningCinematic(canBeCancelled)
    elseif event == "PLAY_MOVIE" then
        if MovieFrame and MovieFrame.StopMovie then
            MovieFrame:StopMovie()
        end
    end
end)

AklimeMod_SkipCinematic = {
    IsEnabled  = function() return GetDB().enabled == true end,
    SetEnabled = function(v) GetDB().enabled = v and true or false end,
}
