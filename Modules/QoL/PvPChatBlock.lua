-- Modules/QoL/PvPChatBlock.lua
-- Blocks Enter (open chat) in PvP instances (arena + battleground, rated + unrated).
-- In the same places the chat bubbles are turned off.
-- Toggle via the minimap radial menu button.

-- Battlegrounds use the raid setting, arenas the party setting
local CHAT_BUBBLE_CVARS = { "chatBubbles", "chatBubblesParty", "chatBubblesRaid" }
local BUBBLES_OFF       = "0"

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.pvpChatBlock
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- ============================================================
-- Detect a PvP instance
-- ============================================================
local function IsInPvPInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "pvp" or instanceType == "arena")
end

-- ============================================================
-- Chat bubbles
-- The old values are saved in the DB, so a /reload inside the instance
-- cannot leave the bubbles switched off for good.
-- ============================================================
local function HideBubbles()
    local db = GetDB()
    if not db or db.savedBubbles then return end
    db.savedBubbles = {}
    for _, cvar in ipairs(CHAT_BUBBLE_CVARS) do
        db.savedBubbles[cvar] = GetCVar(cvar)
        SetCVar(cvar, BUBBLES_OFF)
    end
end

local function RestoreBubbles()
    local db = GetDB()
    if not db or not db.savedBubbles then return end
    for cvar, value in pairs(db.savedBubbles) do
        SetCVar(cvar, value)
    end
    db.savedBubbles = nil
end

-- ============================================================
-- Chat block
-- ============================================================
local blocked = false
local hooked  = false

local function Block()
    if blocked then return end
    blocked = true

    -- ChatFrame1EditBox is the main input
    -- We hook OnKeyDown to intercept Enter
    if not hooked and ChatFrame1EditBox then
        hooked = true
        hooksecurefunc(ChatFrame1EditBox, "Show", function(self)
            if IsEnabled() and IsInPvPInstance() then
                self:Hide()
            end
        end)
    end

    -- Hide all chat frame edit boxes if currently open
    for i = 1, 50 do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox and editBox:IsShown() then
            editBox:Hide()
        end
        if not _G["ChatFrame" .. i] then break end
    end

    HideBubbles()
end

local function Unblock()
    blocked = false
    -- Hook stays but IsEnabled() returns false, so Show() is not blocked
    RestoreBubbles()
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
local registered = false

local function OnEvent(self, event)
    if not IsEnabled() then
        Unblock()
        return
    end

    if IsInPvPInstance() then
        Block()
    else
        Unblock()
    end
end

local function RegisterEvents()
    if registered then return end
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:SetScript("OnEvent", OnEvent)
    registered = true
end

local function UnregisterEvents()
    if not registered then return end
    eventFrame:UnregisterAllEvents()
    eventFrame:SetScript("OnEvent", nil)
    registered = false
end

-- ============================================================
-- Hide Chat Only (right-click on the radial menu button)
-- Hides all chat frames and their tabs by redirecting Show to Hide.
-- Not tied to the PvP block above, not saved, resets on /reload.
-- ============================================================
local chatHidden = false

local function ToggleChatHide()
    chatHidden = not chatHidden
    for i = 1, NUM_CHAT_WINDOWS do
        for _, suffix in ipairs({ "", "Tab" }) do
            local f = _G["ChatFrame" .. i .. suffix]
            if f then
                if chatHidden then f.akmWasVisible = f:IsVisible() end
                f.akmOrigShow = f.akmOrigShow or f.Show
                f.Show = chatHidden and f.Hide or f.akmOrigShow
                if f.akmWasVisible then f:Show() end
            end
        end
    end
    return chatHidden
end

-- ============================================================
-- Public API
-- ============================================================
AklimeMod_PvPChatBlock = {}

function AklimeMod_PvPChatBlock.ToggleChatHide()
    return ToggleChatHide()
end

function AklimeMod_PvPChatBlock.IsEnabled()
    return IsEnabled()
end

function AklimeMod_PvPChatBlock.Toggle()
    local db = GetDB()
    if not db then return end
    db.enabled = not db.enabled
    if db.enabled then
        RegisterEvents()
        if IsInPvPInstance() then Block() end
    else
        UnregisterEvents()
        Unblock()
    end
    return db.enabled
end

function AklimeMod_PvPChatBlock.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then
        RegisterEvents()
        if IsInPvPInstance() then Block() end
    else
        UnregisterEvents()
        Unblock()
    end
end

function AklimeMod_PvPChatBlock.Init()
    if IsEnabled() then
        RegisterEvents()
    end
    -- Bubbles left switched off by a crash or a disabled module come back here
    if not (IsEnabled() and IsInPvPInstance()) then
        RestoreBubbles()
    end
end