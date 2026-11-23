-- Modules/Interface/HUDFader.lua
-- Two independent modes: resting zones (mode1) and open world (mode2).
-- Both can be active at the same time. The final alpha is the maximum of all active modes.
-- Combat: immediately full alpha, visible the whole time.
-- Instances: no mode applies.

local M = {}
AklimeMod_HUDFader = M

-- ============================================================
-- UI elements (SetAlpha fade)
-- ============================================================
local ELEMENTS = {
    { key = "actionBars", frames = function()
        local f = {}
        for _, n in ipairs({ "MainActionBar","MultiBarBottomLeft","MultiBarBottomRight",
            "MultiBarRight","MultiBarLeft","MultiBar5","MultiBar6","MultiBar7",
            "StanceBar","PetActionBar" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        return f
    end },
    { key = "microMenu", frames = function()
        local f = {}
        for _, n in ipairs({ "CharacterMicroButton","ProfessionMicroButton",
            "PlayerSpellsMicroButton","AchievementMicroButton","QuestLogMicroButton",
            "GuildMicroButton","LFDMicroButton","CollectionsMicroButton",
            "EJMicroButton","StoreMicroButton","MainMenuMicroButton",
            "HousingMicroButton" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        if MicroButtonAndBagsBar then f[#f+1] = MicroButtonAndBagsBar end
        return f
    end },
    { key = "bags", frames = function()
        local f = {}
        for _, n in ipairs({ "MainMenuBarBackpackButton","CharacterBag0Slot",
            "CharacterBag1Slot","CharacterBag2Slot","CharacterBag3Slot","BagsBar" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        return f
    end },
    { key = "minimap", frames = function()
        -- Minimap inherits the alpha of MinimapCluster automatically.
        local f = MinimapCluster and {MinimapCluster} or {}
        -- The queue eye hangs on the micro menu container and not on the cluster. It fades together with the minimap.
        if QueueStatusButton then f[#f+1] = QueueStatusButton end
        return f
    end },
    { key = "buffs",        frames = function() return BuffFrame             and {BuffFrame}             or {} end },
    { key = "debuffs",      frames = function() return DebuffFrame           and {DebuffFrame}           or {} end },
    { key = "playerFrame",  frames = function() return PlayerFrame           and {PlayerFrame}           or {} end },
    { key = "targetFrame",  frames = function() return TargetFrame           and {TargetFrame}           or {} end },
    { key = "focusFrame",   frames = function() return FocusFrame            and {FocusFrame}            or {} end },
    { key = "partyFrame",   frames = function() return CompactPartyFrame     and {CompactPartyFrame}     or {} end },
    { key = "objectives",   frames = function() return ObjectiveTrackerFrame and {ObjectiveTrackerFrame} or {} end },
    { key = "repBar",       frames = function() return StatusTrackingBarManager and {StatusTrackingBarManager} or {} end },
    { key = "expansionBtn", frames = function()
        local f = {}
        for _, n in ipairs({ "ExpansionLandingPageMinimapButton", "GarrisonLandingPageMinimapButton" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        return f
    end },
    { key = "socialBtn",   frames = function() return QuickJoinToastButton and {QuickJoinToastButton} or {} end },
    { key = "chatCopyBtn", frames = function()
        local b = _G["AklimeMod_ChatCopyBtn"]
        return b and {b} or {}
    end },
    { key = "damageMeter", frames = function()
        local f = {}
        if DamageMeter then f[#f+1] = DamageMeter end
        for i = 1, 5 do
            local sw = _G["DamageMeterSessionWindow" .. i]
            if sw then f[#f+1] = sw end
        end
        return f
    end },
    -- The housing menu at the top of the screen. It comes from a load on demand addon, so it may not exist yet.
    { key = "housingMenu", frames = function() return HousingControlsFrame and {HousingControlsFrame} or {} end },
}

local CHAT_EVENTS = {
    "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_EMOTE","CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER","CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD","CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL","CHAT_MSG_INSTANCE_CHAT","CHAT_MSG_INSTANCE_CHAT_LEADER",
}

-- Battle.net whispers. They are registered apart, so a client without these events cannot break the loading.
local BN_CHAT_EVENTS = {
    "CHAT_MSG_BN_WHISPER","CHAT_MSG_BN_WHISPER_INFORM",
}

local MOVE_ACTIVATE_DELAY = 2
local IDLE_DELAY          = 12
local CHAT_SHOW_DURATION  = 15

-- ============================================================
-- Fade-Engine
-- ============================================================
local fadeTargets = {}
local FADE_SPEED  = 1.5
local OnClusterFadeDone  -- Set in the minimap section, called when the minimap cluster has finished a fade

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, elapsed)
    for frame, target in pairs(fadeTargets) do
        local cur = frame:GetAlpha()
        if math.abs(cur - target) < 0.01 then
            frame:SetAlpha(target)
            fadeTargets[frame] = nil
            if frame == MinimapCluster and OnClusterFadeDone then OnClusterFadeDone(target) end
        else
            local step = FADE_SPEED * elapsed
            frame:SetAlpha(cur + (target > cur and step or -step))
        end
    end
end)

local function FadeTo(frame, alpha)
    if not frame then return end
    fadeTargets[frame] = math.max(0, math.min(1, alpha))
end

-- Finishes all running fades at once, so a frame that was set back to full alpha does not fade down in view
local function CompleteFades()
    for frame, target in pairs(fadeTargets) do
        frame:SetAlpha(target)
        fadeTargets[frame] = nil
    end
end

-- ============================================================
-- Minimap overlays
-- Nameless MinimapCluster children (player arrow, quest blobs,
-- merchant icons) ignore the parent alpha. Solution: Hide() + OnShow hook.
-- ============================================================
local minimapIdleActive  = false
local hookedOverlays     = {}
local currentHidden      = {}  -- Set: every part hidden while the minimap is faded
local minimapShowHooked  = false  -- One-time: hooksecurefunc on Minimap.Show in housing
local clusterLayoutHooked = false  -- One-time: hooksecurefunc on MinimapCluster.Layout
local idleClusterWidth, idleClusterHeight = nil, nil  -- Size of the cluster before its parts were hidden

-- The game can draw the map of a cave late or not at all while the minimap is dimmed or faded out. So the minimap
-- is shown at full alpha at once when the area changes and fades back after a moment. When the player goes in again
-- soon after coming out, this is not enough alone. The zoom step of RedrawMinimapZoom is needed as well.
local MINIMAP_AREA_HOLD   = 2  -- Seconds
local MINIMAP_AREA_EVENTS = {
    ZONE_CHANGED = true, ZONE_CHANGED_INDOORS = true, ZONE_CHANGED_NEW_AREA = true, MINIMAP_UPDATE_ZOOM = true,
}
local minimapHeldUntil = 0
-- The area changed while the minimap was faded out. It then comes back at full alpha for a moment.
local minimapChangedWhileFaded = false
local wasIndoors       = false

-- When the player goes into a cave again soon after coming out, the game draws the map a few seconds late. A zoom
-- step for one frame right after the entry makes it draw at once. The circle is still empty at that moment, so the
-- step is not seen. A later step would be seen, because the map is already drawn by then. A test without the full
-- alpha of the hold did not draw the map, so both are used.
local REDRAW_QUIET     = 0.5  -- Seconds after the zoom step in which its own zoom events are ignored
local redrawQuietUntil = 0

-- The arrow of the player ignores the alpha, so it stays visible when the minimap has faded out. Hiding the part
-- that holds the minimap would hide the arrow too, but then the game draws no map for the next cave. So once the
-- minimap has faded out, that part is scaled down instead. Nothing is hidden or shown, and the map stays intact.
local MINIMAP_HIDDEN_SCALE = 0.001
local minimapHolder, minimapHolderScale = nil, 1

-- True for the part of the cluster that holds the minimap. The minimap is not a direct child of the cluster,
-- it sits in one of the nameless parts.
local function IsMinimapAncestor(part)
    local parent = Minimap and Minimap.GetParent and Minimap:GetParent()
    while parent and parent ~= MinimapCluster do
        if parent == part then return true end
        parent = parent:GetParent()
    end
    return false
end

-- The game shows and hides some parts of the minimap by itself, for example the layers of a cave or a tunnel when
-- the area changes. While the minimap is faded, the addon keeps all parts hidden but follows what the game wants.
-- Otherwise a layer that the game hid meanwhile would be shown again with the minimap, and the map stays black.
local isHidingOverlay = false  -- True while the addon hides a part itself, so the hook does not take it for the game

local function HideOverlay(part)
    isHidingOverlay = true
    part:Hide()
    isHidingOverlay = false
end

local function HookOverlay(part)
    if hookedOverlays[part] then return end
    hookedOverlays[part] = true
    part:HookScript("OnShow", function(self)
        if minimapIdleActive then
            currentHidden[self] = true
            HideOverlay(self)
        end
    end)
    local function OnGameHides(self)
        if minimapIdleActive and not isHidingOverlay then currentHidden[self] = nil end
    end
    hooksecurefunc(part, "Hide", OnGameHides)
    if part.SetShown then
        hooksecurefunc(part, "SetShown", function(self, shown)
            if not shown then OnGameHides(self) end
        end)
    end
end

local function HideMinimapOverlays()
    if minimapIdleActive then return end  -- already hidden, no second wipe
    minimapIdleActive = true
    idleClusterWidth, idleClusterHeight = nil, nil
    minimapHolder = nil
    wipe(currentHidden)
    if not MinimapCluster then return end
    local inInst, instType = IsInInstance()
    local inHousing = inInst and (instType == "interior" or instType == "neighborhood")

    if inHousing then
        -- In housing the Minimap ignores the parent alpha of MinimapCluster.
        -- Hide the Minimap directly so the arrow and all children disappear.
        -- Do not touch MinimapCluster children (prevents a layout reflow).
        if not Minimap then return end
        if not minimapShowHooked then
            minimapShowHooked = true
            hooksecurefunc(Minimap, "Show", function(self)
                if minimapIdleActive then self:Hide() end
            end)
        end
        Minimap:Hide()
        return
    end

    -- Blizzard lays out the cluster again for many reasons, for example when the interface is shown. The cluster
    -- sizes itself from its shown parts. With all of them hidden it would shrink to nothing, the minimap would sit
    -- half off screen and the quest tracker below it would move up. So the cluster keeps its size meanwhile.
    idleClusterWidth, idleClusterHeight = MinimapCluster:GetSize()
    if not clusterLayoutHooked and MinimapCluster.Layout then
        clusterLayoutHooked = true
        hooksecurefunc(MinimapCluster, "Layout", function(self)
            if minimapIdleActive and idleClusterWidth then self:SetSize(idleClusterWidth, idleClusterHeight) end
        end)
    end

    for _, child in ipairs({ MinimapCluster:GetChildren() }) do
        local name = child:GetName()
        if (not name or name == "") and IsMinimapAncestor(child) then
            -- Scaled down when the fade is done, see OnClusterFadeDone
            minimapHolder, minimapHolderScale = child, child:GetScale()
        elseif not name or name == "" then
            HookOverlay(child)
            local ok, shown = pcall(function() return child:IsShown() end)
            if ok and shown then
                currentHidden[child] = true
                HideOverlay(child)
            end
        end
    end
end

local function ShowMinimapOverlays()
    if not minimapIdleActive then return end  -- already visible
    minimapIdleActive = false
    if minimapHolder then
        minimapHolder:SetScale(minimapHolderScale)
        minimapHolder = nil
    end
    -- In housing the Minimap was hidden directly, show it again.
    if Minimap and not Minimap:IsShown() then
        Minimap:Show()
    end
    for child in pairs(currentHidden) do
        pcall(function() child:Show() end)
    end
    wipe(currentHidden)
    -- MinimapCluster is a layout frame that sizes itself from its shown children. A layout that ran
    -- while they were hidden, for example when the interface was hidden and shown again, left it too small.
    -- Showing a child does not start a new layout, so it is requested here.
    if MinimapCluster and MinimapCluster.MarkDirty then MinimapCluster:MarkDirty() end
end

-- The minimap has faded out completely. Now the arrow goes too, which ignores the alpha.
OnClusterFadeDone = function(alpha)
    if alpha == 0 and minimapIdleActive and minimapHolder then
        minimapHolder:SetScale(MINIMAP_HIDDEN_SCALE)
    end
end

-- ============================================================
-- Helpers
-- ============================================================
-- Every chat window counts, also hidden tabs and temporary windows such as whisper tabs.
-- A tab that is hidden while the interface fades would otherwise appear at full alpha when selected.
-- Blizzard numbers temporary windows above MaxChatWindows, so the range must reach past that number.
local TEMPORARY_CHAT_WINDOW_ALLOWANCE = 40
local MAX_CHAT_FRAMES = (Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or 10) + TEMPORARY_CHAT_WINDOW_ALLOWANCE

local function GetChatFrames()
    local f = {}
    for i = 1, MAX_CHAT_FRAMES do
        local cf = _G["ChatFrame" .. i]
        if cf then f[#f+1] = cf end
    end
    if GeneralDockManager then f[#f+1] = GeneralDockManager end
    return f
end

-- True while the player types in a chat input box. The chat must not fade away under the text.
local function IsTyping()
    for i = 1, MAX_CHAT_FRAMES do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox and editBox:HasFocus() then return true end
    end
    return false
end

-- True while the mouse is over a shown chat window or the tab bar. The chat then shows, like for a new message.
local function IsMouseOverChat()
    for _, frame in ipairs(GetChatFrames()) do
        if frame:IsShown() and frame:IsMouseOver() then return true end
    end
    return false
end

local function CancelTimer(t)
    if t then t:Cancel() end
    return nil
end

-- ============================================================
-- Unified Alpha
-- Each mode reports its desired alpha (nil = not active).
-- Final alpha = maximum of all reported values.
-- No modes active: full alpha (1.0).
-- ============================================================
local modeAlphas = {}
local inCombat   = false
-- True when an update was skipped because the player hid the whole interface
local updateSkippedWhileHidden = false
-- The chat stays visible until this time, set after the player stopped typing or pointed at it
local chatHoldUntil = 0
-- Defined further down, because the modes need it before that place
local StartChatHold

-- Mapping: ELEMENTS key -> DB exclude key
local EXCLUDE_KEY = {
    actionBars  = "actionBars",
    microMenu   = "microMenu",
    bags        = "bags",
    minimap     = "minimap",
    objectives  = "objectives",
    playerFrame = "unitFrames",
    targetFrame = "unitFrames",
    focusFrame  = "unitFrames",
    partyFrame  = "unitFrames",
    chatCopyBtn = "chat",
    socialBtn   = "chat",
    buffs       = "buffs",
    debuffs     = "buffs",
    repBar      = "repBar",
    damageMeter = "damageMeter",
    housingMenu = "housingMenu",
}

-- Returns true if the excludeKey is marked as an exception in an active mode
local function IsExcluded(excludeKey)
    if not excludeKey then return false end
    for dbKey in pairs(modeAlphas) do
        local db = AklimeModDB and AklimeModDB.interfaceFade and AklimeModDB.interfaceFade[dbKey]
        if db and db.exclude and db.exclude[excludeKey] then return true end
    end
    return false
end

-- Returns true if an active mode has the hover option on
local function IsHoverRevealOn()
    for dbKey in pairs(modeAlphas) do
        local db = AklimeModDB and AklimeModDB.interfaceFade and AklimeModDB.interfaceFade[dbKey]
        if db and db.hoverReveal then return true end
    end
    return false
end

-- True while the open bar of the button collector hangs on the minimap. The minimap stays visible meanwhile,
-- because the bar would jump away with the minimap when the minimap is scaled down.
local function IsMinimapInUse()
    local collector = AklimeMod_MinimapCollector
    return collector and collector.IsOpen and collector.IsOpen() or false
end

-- The longest chat delay of the active modes
local function GetChatHoldDuration()
    local duration = nil
    for dbKey in pairs(modeAlphas) do
        local db = AklimeModDB and AklimeModDB.interfaceFade and AklimeModDB.interfaceFade[dbKey]
        local delay = db and db.chatDelay
        if delay and (duration == nil or delay > duration) then duration = delay end
    end
    return duration or CHAT_SHOW_DURATION
end

-- True while the mouse is over a shown frame of this element
local function IsMouseOverElement(element)
    local ok, frames = pcall(element.frames)
    if not ok or not frames then return false end
    for _, f in ipairs(frames) do
        if f:IsShown() then
            local okOver, isOver = pcall(f.IsMouseOver, f)
            if okOver and isOver then return true end
        end
    end
    return false
end

-- Keys of the interface elements under the mouse. The chat counts as an element of its own.
local function GetHoveredKeys()
    local hovered = {}
    for _, el in ipairs(ELEMENTS) do
        if IsMouseOverElement(el) then hovered[el.key] = true end
    end
    if IsMouseOverChat() then hovered.chat = true end
    return hovered
end

local ApplyUnified

-- Puts the minimap at full alpha at once, not faded in, and keeps it there for a moment. The game sees the full
-- alpha in the same frame, which it needs to draw the map when the area changes and after the minimap was shown.
local function BeginMinimapHold()
    minimapHeldUntil = GetTime() + MINIMAP_AREA_HOLD
    fadeTargets[MinimapCluster] = nil
    MinimapCluster:SetAlpha(1.0)
    C_Timer.After(MINIMAP_AREA_HOLD + 0.1, function()
        if GetTime() >= minimapHeldUntil then ApplyUnified() end
    end)
end

function ApplyUnified(alphaOnly)
    if inCombat then return end
    -- The Hide Interface key (Alt+Z by default) hides UIParent. Nothing is touched meanwhile.
    -- The update is made up for as soon as the interface is back.
    if not UIParent:IsShown() then
        updateSkippedWhileHidden = true
        return
    end
    local maxAlpha = nil
    for _, a in pairs(modeAlphas) do
        if maxAlpha == nil or a > maxAlpha then maxAlpha = a end
    end
    if maxAlpha == nil then maxAlpha = 1.0 end

    -- With the hover option, an element under the mouse is shown while the rest stays faded
    local hovered = IsHoverRevealOn() and GetHoveredKeys() or {}

    -- If the area changed while the minimap was faded out, it comes back at full alpha for a moment, so the game
    -- draws the map of the new area. Otherwise it fades in as usual.
    if minimapIdleActive and minimapChangedWhileFaded and not alphaOnly and MinimapCluster
        and (maxAlpha > 0 or IsExcluded("minimap") or hovered.minimap) then
        minimapChangedWhileFaded = false
        BeginMinimapHold()
    end
    local minimapHeld = GetTime() < minimapHeldUntil
    local minimapInUse = IsMinimapInUse()

    for _, el in ipairs(ELEMENTS) do
        local keepFull = hovered[el.key] or (el.key == "minimap" and (minimapHeld or minimapInUse))
        local alpha = (IsExcluded(EXCLUDE_KEY[el.key]) or keepFull) and 1.0 or maxAlpha
        local ok, frames = pcall(el.frames)
        if ok and frames then
            for _, f in ipairs(frames) do FadeTo(f, alpha) end
        end
    end
    -- The chat stays visible while the player types or points at it, and for the chat delay afterwards
    local chatAlpha = (IsExcluded("chat") or IsTyping() or hovered.chat or GetTime() < chatHoldUntil) and 1.0 or maxAlpha
    for _, cf in ipairs(GetChatFrames()) do FadeTo(cf, chatAlpha) end

    -- Showing or hiding the minimap parts changes the size of the minimap cluster. Right after the interface
    -- came back, Blizzard is still busy with its own layout. So these parts are left to the next update.
    if alphaOnly then return end

    if maxAlpha == 0 and not IsExcluded("minimap") and not hovered.minimap and not minimapHeld and not minimapInUse then
        HideMinimapOverlays()
    else
        if Minimap then Minimap:SetAlpha(1.0) end
        ShowMinimapOverlays()
    end
end

local function GoFullAll()
    wipe(modeAlphas)
    if Minimap then Minimap:SetAlpha(1.0) end
    ShowMinimapOverlays()
    for _, el in ipairs(ELEMENTS) do
        for _, f in ipairs(el.frames()) do FadeTo(f, 1.0) end
    end
    for _, cf in ipairs(GetChatFrames()) do FadeTo(cf, 1.0) end
end

-- Shows the minimap at full alpha for a moment. The alpha is set at once and not faded in, so the game sees it
-- in the same frame in which it switches the map.
local function HoldMinimapVisible()
    if not MinimapCluster then return end
    -- No mode is active, for example in combat. The minimap may still be on its way to full alpha, for example
    -- when the combat started while it was faded out. It is set to full alpha at once, the game needs it now.
    if not next(modeAlphas) then
        if MinimapCluster:GetAlpha() < 0.99 then
            fadeTargets[MinimapCluster] = nil
            MinimapCluster:SetAlpha(1.0)
        end
        return
    end
    -- Nothing to do while it is fully visible anyway, for example under the mouse or as an exception
    if GetTime() >= minimapHeldUntil and MinimapCluster:GetAlpha() >= 0.99 and not minimapIdleActive then return end
    BeginMinimapHold()
    ApplyUnified()
end

-- The zoom step belongs to the fading. It is not done while all modes are switched off.
local function IsAnyModeEnabled()
    local db = AklimeModDB and AklimeModDB.interfaceFade
    if not db then return false end
    return (db.mode1 and db.mode1.enabled == true) or (db.mode2 and db.mode2.enabled == true)
        or (db.mode3 and db.mode3.enabled == true) or false
end

-- Moves the zoom one step and back one frame later, so the game draws the map of the cave at once
local function RedrawMinimapZoom()
    if not Minimap or not Minimap.GetZoom or not Minimap.SetZoom or not Minimap.GetZoomLevels then return end
    local zoom, levels = Minimap:GetZoom(), Minimap:GetZoomLevels()
    if levels < 2 then return end
    redrawQuietUntil = GetTime() + REDRAW_QUIET
    Minimap:SetZoom(zoom < levels - 1 and zoom + 1 or zoom - 1)
    C_Timer.After(0, function() Minimap:SetZoom(zoom) end)
end

-- Housing hides the minimap in its own way, see HideMinimapOverlays. No hold and no zoom step there.
local function IsInHousing()
    local inInst, instType = IsInInstance()
    return inInst and (instType == "interior" or instType == "neighborhood")
end

local function OnMinimapAreaEvent(event)
    if GetTime() < redrawQuietUntil then return end
    local indoors = IsIndoors and IsIndoors() and true or false
    local changed = indoors ~= wasIndoors
    wasIndoors = indoors
    -- Subzone changes in the open world are frequent. They only count when the player went in or out.
    if event == "ZONE_CHANGED" and not changed then return end
    if IsInHousing() then return end
    -- Faded out: nothing to see yet. The minimap draws the new area when it comes back, see ApplyUnified.
    if minimapIdleActive then
        minimapChangedWhileFaded = true
        return
    end
    HoldMinimapVisible()
    -- Only when going in. Further events inside a building do not need the zoom step.
    if indoors and changed and IsAnyModeEnabled() then C_Timer.After(0, RedrawMinimapZoom) end
end

-- ============================================================
-- Mode factory
-- dbKey:     key in AklimeModDB.interfaceFade (e.g. "mode1")
-- zoneCheck: function() -> bool  (true = mode applies in this zone)
-- ============================================================
local function CreateMode(dbKey, zoneCheck)
    local mode      = {}
    local state     = "idle"
    local moveTimer = nil
    local idleTimer = nil
    local chatTimer = nil

    local function getDB()
        return AklimeModDB and AklimeModDB.interfaceFade and AklimeModDB.interfaceFade[dbKey]
    end

    local function isEnabled()
        local db = getDB()
        return db and db.enabled == true
    end

    local function getActiveAlpha()
        local db = getDB()
        return (db and db.alpha or 60) / 100
    end

    local function setAlpha(a)
        modeAlphas[dbKey] = a
        ApplyUnified()
    end

    local function clearAlpha()
        modeAlphas[dbKey] = nil
        ApplyUnified()
    end

    local function goIdle()
        state = "idle"
        setAlpha(0)
    end

    local function goActive()
        state = "active"
        chatTimer = CancelTimer(chatTimer)
        setAlpha(getActiveAlpha())
    end

    local function startIdleCountdown()
        idleTimer = CancelTimer(idleTimer)
        local db = getDB()
        local delay = (db and db.idleDelay) or IDLE_DELAY
        idleTimer = C_Timer.NewTimer(delay, function()
            idleTimer = nil
            if isEnabled() and zoneCheck() and not inCombat then
                goIdle()
            end
        end)
    end

    function mode:OnChatEvent()
        if not isEnabled() or inCombat or not zoneCheck() then return end
        if state ~= "idle" then return end
        chatTimer = CancelTimer(chatTimer)
        -- The shared hold keeps the chat visible even if another update runs before the time is over
        StartChatHold()
        for _, cf in ipairs(GetChatFrames()) do FadeTo(cf, 1.0) end
        local db = getDB()
        local delay = (db and db.chatDelay) or CHAT_SHOW_DURATION
        chatTimer = C_Timer.NewTimer(delay, function()
            chatTimer = nil
            if isEnabled() and zoneCheck() and not inCombat then
                ApplyUnified()
            end
        end)
    end

    function mode:OnEnteringWorld()
        if not isEnabled() then return end
        C_Timer.After(2, function()
            if isEnabled() and zoneCheck() and not inCombat and state == "idle" then
                goIdle()
            end
        end)
    end

    function mode:OnCombatStart()
        moveTimer = CancelTimer(moveTimer)
        idleTimer = CancelTimer(idleTimer)
        chatTimer = CancelTimer(chatTimer)
        clearAlpha()
    end

    function mode:OnCombatEnd()
        if not isEnabled() then return end
        if zoneCheck() then
            startIdleCountdown()
        end
    end

    function mode:OnStartedMoving()
        if not isEnabled() or inCombat then return end
        idleTimer = CancelTimer(idleTimer)
        moveTimer = CancelTimer(moveTimer)
        local db = getDB()
        local delay = (db and db.moveDelay) or MOVE_ACTIVATE_DELAY
        if delay == 0 then
            if zoneCheck() then goActive() end
            return
        end
        moveTimer = C_Timer.NewTimer(delay, function()
            moveTimer = nil
            if isEnabled() and zoneCheck() and not inCombat then
                goActive()
            end
        end)
    end

    function mode:OnStoppedMoving()
        moveTimer = CancelTimer(moveTimer)
        if not isEnabled() or inCombat then return end
        if zoneCheck() and state == "active" then
            startIdleCountdown()
        end
    end

    function mode:OnZoneChanged()
        if not isEnabled() then return end
        if not zoneCheck() then
            moveTimer = CancelTimer(moveTimer)
            idleTimer = CancelTimer(idleTimer)
            chatTimer = CancelTimer(chatTimer)
            state = "idle"
            clearAlpha()
            return
        end
        -- Still in a zone of this mode. While the interface is shown, the running idle
        -- timer must stay, otherwise frequent zone events would cancel it and the
        -- interface would never fade after the set time.
        if state == "idle" and not inCombat then
            moveTimer = CancelTimer(moveTimer)
            idleTimer = CancelTimer(idleTimer)
            chatTimer = CancelTimer(chatTimer)
            goIdle()
            startIdleCountdown()
        end
    end

    function mode:SetEnabled(v)
        local db = getDB()
        if db then db.enabled = v end
        if v then
            if zoneCheck() and not inCombat then
                state = "idle"
                goIdle()
                startIdleCountdown()
            end
        else
            moveTimer = CancelTimer(moveTimer)
            idleTimer = CancelTimer(idleTimer)
            chatTimer = CancelTimer(chatTimer)
            state = "idle"
            clearAlpha()
        end
    end

    function mode:IsEnabled()
        return isEnabled()
    end

    function mode:ApplyAlpha()
        if not isEnabled() or state ~= "active" then return end
        setAlpha(getActiveAlpha())
    end

    return mode
end

-- ============================================================
-- Modes
-- ============================================================
local Mode1 = CreateMode("mode1", function()
    return IsResting() and not IsInInstance()
end)

local Mode2 = CreateMode("mode2", function()
    return not IsResting() and not IsInInstance()
end)

-- Housing: instance type "neighborhood" is housing-exclusive.
-- Applies to Alliance and Horde, all languages, exterior and interior.
local Mode3 = CreateMode("mode3", function()
    local inInst, instType = IsInInstance()
    return inInst and (instType == "neighborhood" or instType == "interior")
end)

local ALL_MODES = { Mode1, Mode2, Mode3 }

-- ============================================================
-- Events
-- ============================================================
local isChatEvent = {}
for _, ev in ipairs(CHAT_EVENTS) do isChatEvent[ev] = true end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_STARTED_MOVING")
ef:RegisterEvent("PLAYER_STOPPED_MOVING")
ef:RegisterEvent("PLAYER_REGEN_DISABLED")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")
ef:RegisterEvent("PLAYER_FLAGS_CHANGED")
ef:RegisterEvent("ZONE_CHANGED_INDOORS")
ef:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- Only used to keep the minimap visible when the area changes, pcall in case an event is missing in this client
pcall(ef.RegisterEvent, ef, "ZONE_CHANGED")
pcall(ef.RegisterEvent, ef, "MINIMAP_UPDATE_ZOOM")
for _, ev in ipairs(CHAT_EVENTS) do ef:RegisterEvent(ev) end
for _, ev in ipairs(BN_CHAT_EVENTS) do
    isChatEvent[ev] = true
    pcall(ef.RegisterEvent, ef, ev)
end

ef:SetScript("OnEvent", function(_, event)
    if isChatEvent[event] then
        for _, m in ipairs(ALL_MODES) do m:OnChatEvent() end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        inCombat = false
        -- Reset the minimap idle state before Show() is called.
        -- Otherwise the hooksecurefunc hook would hide the Minimap again immediately.
        minimapChangedWhileFaded = false
        ShowMinimapOverlays()
        if Minimap then Minimap:SetAlpha(1.0) end
        wasIndoors = IsIndoors and IsIndoors() and true or false
        for _, m in ipairs(ALL_MODES) do m:OnEnteringWorld() end

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        for _, m in ipairs(ALL_MODES) do m:OnCombatStart() end
        GoFullAll()

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        for _, m in ipairs(ALL_MODES) do m:OnCombatEnd() end

    elseif event == "PLAYER_STARTED_MOVING" then
        for _, m in ipairs(ALL_MODES) do m:OnStartedMoving() end

    elseif event == "PLAYER_STOPPED_MOVING" then
        for _, m in ipairs(ALL_MODES) do m:OnStoppedMoving() end

    elseif event == "PLAYER_FLAGS_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA" then
        for _, m in ipairs(ALL_MODES) do m:OnZoneChanged() end
    end

    -- After the modes, because a zone change can make a mode fade the minimap out
    if MINIMAP_AREA_EVENTS[event] then OnMinimapAreaEvent(event) end
end)

-- ============================================================
-- Chat windows created later and typing
-- Whisper windows are created later and start at full alpha. They get the faded alpha right away.
-- Typing starts or ends when an input box gains or loses focus. The chat is then shown or faded again.
-- Without any wish from a mode there is nothing to fade, so the interface stays untouched.
-- ============================================================
local hookedEditBoxes = {}

local function OnChatChanged()
    if next(modeAlphas) then ApplyUnified() end
end

-- Keeps the chat visible for the chat delay. The timer applies the faded alpha again when the time is over.
local chatHoldTimer = nil
function StartChatHold()
    if not next(modeAlphas) then return end
    local duration = GetChatHoldDuration()
    chatHoldUntil = GetTime() + duration
    chatHoldTimer = CancelTimer(chatHoldTimer)
    chatHoldTimer = C_Timer.NewTimer(duration, function()
        chatHoldTimer = nil
        chatHoldUntil = 0
        ApplyUnified()
    end)
end

local function OnChatInputClosed()
    StartChatHold()
    OnChatChanged()
end

-- An undocked chat tab hangs on UIParent and not on its chat window, so it does not fade with the window.
-- Blizzard sets the alpha of a tab by itself, for example when the mouse enters or leaves the window.
-- So the tab gets the alpha Blizzard wants times the alpha of its window.
local chatFrameOfTab = {}
local alphaWantedByBlizzard = {}
local isSettingTabAlpha = false

local function ApplyTabAlpha(tab)
    local chatFrame = chatFrameOfTab[tab]
    local alpha = alphaWantedByBlizzard[tab]
    if not chatFrame.isDocked then alpha = alpha * chatFrame:GetAlpha() end
    isSettingTabAlpha = true
    tab:SetAlpha(alpha)
    isSettingTabAlpha = false
end

local function HookChatTabs()
    for i = 1, MAX_CHAT_FRAMES do
        local chatFrame = _G["ChatFrame" .. i]
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if chatFrame and tab and not chatFrameOfTab[tab] then
            chatFrameOfTab[tab] = chatFrame
            alphaWantedByBlizzard[tab] = tab:GetAlpha()
            hooksecurefunc(tab, "SetAlpha", function(_, alpha)
                if isSettingTabAlpha then return end
                alphaWantedByBlizzard[tab] = alpha
                ApplyTabAlpha(tab)
            end)
            hooksecurefunc(chatFrame, "SetAlpha", function() ApplyTabAlpha(tab) end)
        end
    end
end

local function HookEditBoxes()
    for i = 1, MAX_CHAT_FRAMES do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox and not hookedEditBoxes[editBox] then
            hookedEditBoxes[editBox] = true
            editBox:HookScript("OnEditFocusGained", OnChatChanged)
            editBox:HookScript("OnEditFocusLost", OnChatInputClosed)
        end
    end
end

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function()
    HookEditBoxes()
    HookChatTabs()
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        HookEditBoxes()
        HookChatTabs()
        OnChatChanged()
    end)
end)

-- The mouse position is polled instead of hooked, so elements created later need no extra hook.
-- Only a change of the elements under the mouse triggers a new calculation.
local HOVER_CHECK_INTERVAL = 0.1
local hoverElapsed = 0
local lastHoverSignature = ""
local wasOverChat = false
local wasMinimapInUse = false
-- Blizzard sets the alpha of its managed frames, such as the objective tracker, back to 1 when the interface
-- is shown again. The faded alpha is set again at once, so these frames do not stay bright.
local interfaceWasShown = true
local function OnInterfaceShown()
    if not updateSkippedWhileHidden and not next(modeAlphas) then return end
    -- The minimap parts follow in the next check, when Blizzard has finished its layout
    updateSkippedWhileHidden = true
    hoverElapsed = 0
    ApplyUnified(true)
    CompleteFades()
end
local hoverFrame = CreateFrame("Frame")

-- Joins the hovered keys in a fixed order, so equal states give equal text.
local function GetHoverSignature()
    local hovered = GetHoveredKeys()
    local parts = {}
    for _, el in ipairs(ELEMENTS) do
        if hovered[el.key] then parts[#parts + 1] = el.key end
    end
    if hovered.chat then parts[#parts + 1] = "chat" end
    return table.concat(parts, ",")
end

hoverFrame:SetScript("OnUpdate", function(_, elapsed)
    -- Checked in every frame, so the faded alpha is back before the first frame of the shown interface is drawn
    local interfaceShown = UIParent:IsShown()
    if interfaceShown and not interfaceWasShown then OnInterfaceShown() end
    interfaceWasShown = interfaceShown
    hoverElapsed = hoverElapsed + elapsed
    if hoverElapsed < HOVER_CHECK_INTERVAL then return end
    hoverElapsed = 0
    if updateSkippedWhileHidden and UIParent:IsShown() then
        updateSkippedWhileHidden = false
        ApplyUnified()
    end
    -- Opening or closing the bar of the collector shows or fades the minimap, also without the hover option
    local minimapInUse = IsMinimapInUse()
    if minimapInUse ~= wasMinimapInUse then
        wasMinimapInUse = minimapInUse
        ApplyUnified()
    end
    if not next(modeAlphas) or not IsHoverRevealOn() then
        lastHoverSignature = ""
        wasOverChat = false
        return
    end
    -- The chat stays visible for the chat delay after the mouse left it
    local overChat = IsMouseOverChat()
    if wasOverChat and not overChat then StartChatHold() end
    wasOverChat = overChat
    local signature = GetHoverSignature()
    if signature ~= lastHoverSignature then
        lastHoverSignature = signature
        ApplyUnified()
    end
end)

-- ============================================================
-- Housing menu
-- The menu belongs to the load on demand addon Blizzard_HousingControls. It can be created after the
-- last fade and would then stay visible until the next change. So it is faded as soon as it appears.
-- ============================================================
local HOUSING_CONTROLS_ADDON = "Blizzard_HousingControls"
local housingFrame = CreateFrame("Frame")
housingFrame:RegisterEvent("ADDON_LOADED")
for _, ev in ipairs({ "HOUSE_PLOT_ENTERED", "HOUSE_EDITOR_AVAILABILITY_CHANGED" }) do
    pcall(housingFrame.RegisterEvent, housingFrame, ev)
end
housingFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon ~= HOUSING_CONTROLS_ADDON then return end
    if next(modeAlphas) then ApplyUnified() end
end)

-- ============================================================
-- Debug
-- ============================================================
SLASH_AKMHUD1 = "/akmhud"
SlashCmdList["AKMHUD"] = function(input)
    if input == "zone" then
        print("|cFFFFD100HUDFader Zone:|r " .. (GetRealZoneText() or "?") ..
              " / Sub: " .. (GetSubZoneText() or "?"))
        local inInst, instType = IsInInstance()
        print("  IsInInstance: " .. tostring(inInst) .. "  Type: " .. tostring(instType))
        return
    end
    local function scanFrame(label, frame)
        if not frame then print("  " .. label .. ": not found"); return end
        print(string.format("|cFFFFD100%s|r  alpha=%.2f", label, frame:GetAlpha()))
        local count = 0
        -- Addons like Questie put hundreds of numbered frames on the minimap. They are counted per name, not listed.
        local groups = {}
        for _, child in ipairs({ frame:GetChildren() }) do
            count = count + 1
            local name   = child:GetName()
            local prefix = name and name:match("^(%D+)%d+$")
            if prefix then
                groups[prefix] = groups[prefix] or { shown = 0, hidden = 0 }
                local group = groups[prefix]
                if child:IsShown() then group.shown = group.shown + 1 else group.hidden = group.hidden + 1 end
            else
                local shown = child:IsShown() and "SHOWN" or "hidden"
                local alpha = string.format("%.2f", child:GetAlpha())
                local okW, w = pcall(function() return child:GetWidth() end)
                local okH, h = pcall(function() return child:GetHeight() end)
                local size  = (okW and okH) and string.format("%dx%d", w, h) or "?"
                print(string.format("  [%d] %-45s %s  alpha=%s  size=%s", count, name or "(no name)", shown, alpha, size))
            end
        end
        for prefix, group in pairs(groups) do
            print(string.format("  %s...  %d SHOWN, %d hidden", prefix, group.shown, group.hidden))
        end
        print(string.format("  Total: %d children", count))
    end
    scanFrame("MinimapCluster", MinimapCluster)
    scanFrame("Minimap",        Minimap)
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled()    return Mode1:IsEnabled() end
function M:SetEnabled(v)  Mode1:SetEnabled(v) end
function M:ApplyAlpha()   Mode1:ApplyAlpha() end

function M:IsEnabled2()   return Mode2:IsEnabled() end
function M:SetEnabled2(v) Mode2:SetEnabled(v) end
function M:ApplyAlpha2()  Mode2:ApplyAlpha() end

function M:IsEnabled3()   return Mode3:IsEnabled() end
function M:SetEnabled3(v) Mode3:SetEnabled(v) end
function M:ApplyAlpha3()  Mode3:ApplyAlpha() end

function M:Refresh()      ApplyUnified() end
