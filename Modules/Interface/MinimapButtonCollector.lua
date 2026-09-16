-- Modules/Interface/MinimapButtonCollector.lua
-- Collects all addon minimap buttons and hides them.
-- Click: expand to the left.

local L = AklimeModL or {}

-- ============================================================
-- Ignore list
-- ============================================================
local IGNORE = {
    MiniMapTrackingFrame=true, MiniMapMeetingStoneFrame=true,
    MiniMapMailFrame=true, MiniMapBattlefieldFrame=true,
    MiniMapWorldMapButton=true, MiniMapPing=true,
    MinimapBackdrop=true, MinimapZoomIn=true, MinimapZoomOut=true,
    MinimapZoneTextButton=true, MiniMapInstanceDifficulty=true,
    GuildInstanceDifficulty=true, MiniMapVoiceChatFrame=true,
    MiniMapRecordingButton=true, QueueStatusMinimapButton=true,
    QueueStatusButton=true, TimeManagerClockButton=true,
    GameTimeFrame=true, GarrisonMinimapButton=true,
    MiniMapLFGFrame=true, AklimeMod_MMCollector=true,
}

-- ============================================================
-- Housing detection
-- ============================================================
local function IsHousingInstance()
    local inInst, instType = IsInInstance()
    if not inInst then return false end
    local normal = { party=true, raid=true, pvp=true, arena=true, scenario=true }
    return not normal[instType or ""]
end

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.minimapCollector
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

local function IncludeOwn()
    local db = GetDB()
    return db and db.includeOwn
end

local function IsLocked()
    local db = GetDB()
    return db and db.locked
end

local function GetAngle()
    local db = GetDB()
    return db and db.angle or -45
end

local function SetAngle(a)
    local db = GetDB()
    if db then db.angle = a end
end

-- ============================================================
-- State
-- ============================================================
local collectorBtn    = nil
local isOpen          = false
local storedButtons   = {}
local expandedButtons = {}
local suppressHook    = false  -- Prevents a hook loop during restore

local RADIUS  = 99
local BTN_SIZE = 32
local SPACING  = 36

-- ============================================================
-- Collector Position
-- ============================================================
local function UpdateCollectorPos()
    if not collectorBtn then return end
    local a = math.rad(GetAngle())
    collectorBtn:ClearAllPoints()
    collectorBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(a) * RADIUS,
        math.sin(a) * RADIUS)
end

-- ============================================================
-- Button detection
-- ============================================================
local function IsAddonButton(frame)
    if not frame then return false end

    -- Must be a button
    local ok, isBtn = pcall(function() return frame:IsObjectType("Button") end)
    if not ok or not isBtn then return false end

    -- Must have a name
    local name = frame:GetName()
    if not name or name == "" then return false end

    -- Known ignore list
    if IGNORE[name] then return false end
    if frame == collectorBtn then return false end

    -- Filter out known non-addon button patterns
    local lname = name:lower()
    if lname:find("handynotes", 1, true) then return false end
    if lname:find("tomtom",     1, true) then return false end
    if lname:find("ttminimapbutton", 1, true) then return false end
    -- Numbered map pins such as "HandyNotesPin12". A plain substring match on
    -- "pin" or "arrow" also caught real buttons like ProfessionShoppingList
    -- and FollowTheArrow.
    if lname:find("pin%d+$") then return false end

    -- The addon's own button
    if name == "AklimeModMinimapBtn" and not IncludeOwn() then return false end

    -- Size must match (real addon buttons are 15-45px)
    local ok2, w = pcall(function() return frame:GetWidth() end)
    local ok3, h = pcall(function() return frame:GetHeight() end)
    if not ok2 or not w or w < 15 or w > 50 then return false end
    if not ok3 or not h or h < 15 or h > 50 then return false end

    -- Must have a texture (otherwise it is an invisible helper frame)
    local ok4, regions = pcall(function() return { frame:GetRegions() } end)
    if ok4 and type(regions) == "table" then
        local hasTexture = false
        for _, r in ipairs(regions) do
            local ok5, t = pcall(function() return r:GetObjectType() end)
            if ok5 and t == "Texture" then
                local ok6, shown = pcall(function() return r:IsShown() end)
                if ok6 and shown then
                    hasTexture = true
                    break
                end
            end
        end
        if not hasTexture then return false end
    end

    return true
end

local function ScanAllMinimapButtons()
    local found, seen = {}, {}
    for _, child in ipairs({Minimap:GetChildren()}) do
        if IsAddonButton(child) then
            local name = child:GetName()
            if name and not seen[name] then
                seen[name] = true
                found[#found + 1] = child
            end
        end
    end
    return found
end

-- ============================================================
-- Hide / restore
-- ============================================================
local function StoreAndHideAll()
    -- Hide already known buttons directly, WITHOUT showing them first.
    -- btn:Show() would trigger the buttons' own OnShow handlers,
    -- which can change the minimap position.
    suppressHook = true
    for _, btn in ipairs(storedButtons) do
        btn:Hide()
    end
    suppressHook = false

    -- Only look for NEW visible buttons that are not yet known.
    local seen = {}
    for _, btn in ipairs(storedButtons) do
        local name = btn:GetName()
        if name then seen[name] = true end
    end

    for _, btn in ipairs(ScanAllMinimapButtons()) do
        local name = btn:GetName()
        if name and not seen[name] then
            seen[name] = true

            if not btn._mmc_origPoint then
                local p1, p2, p3, p4, p5 = btn:GetPoint()
                btn._mmc_origPoint  = { p1, p2, p3, p4, p5 }
                btn._mmc_origParent = btn:GetParent()
            end

            btn:Hide()

            if not btn._mmc_hooked then
                btn._mmc_hooked = true
                hooksecurefunc(btn, "Show", function(self)
                    if IsEnabled() and not isOpen and not suppressHook then
                        self:Hide()
                    end
                end)
            end

            storedButtons[#storedButtons + 1] = btn
        end
    end
end

local function RestoreAll()
    suppressHook = true
    for _, btn in ipairs(storedButtons) do
        btn:ClearAllPoints()
        local p = btn._mmc_origPoint
        if p and p[1] then
            btn:SetParent(btn._mmc_origParent or Minimap)
            btn:SetPoint(p[1], p[2], p[3], p[4] or 0, p[5] or 0)
        end
        btn:Show()
    end
    suppressHook = false
    storedButtons = {}
end

-- ============================================================
-- Late buttons
-- ============================================================
-- The scans run a few seconds after loading. LibDBIcon reports buttons that
-- addons create later through a callback. It positions a new button with a
-- short delay, collecting right away would store an empty anchor.
local LATE_BUTTON_DELAY = 1
local lateCallbackOwner = {}
local lateHooked        = false

local function HookLateButtons()
    if lateHooked then return end
    local dbIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not dbIcon or not dbIcon.RegisterCallback then return end
    lateHooked = true
    dbIcon.RegisterCallback(lateCallbackOwner, "LibDBIcon_IconCreated", function()
        C_Timer.After(LATE_BUTTON_DELAY, function()
            -- While expanded a scan would hide the open buttons
            if IsEnabled() and collectorBtn and not isOpen then StoreAndHideAll() end
        end)
    end)
end

-- ============================================================
-- Expand / collapse
-- ============================================================
local CollectorClose  -- forward declaration
local closeDetector = CreateFrame("Frame")
local mouseWasDown = false

local function PositionBtn(btn, i)
    -- Save original parent and position (only once)
    if not btn._mmc_openParent then
        btn._mmc_openParent = btn:GetParent()
    end
    btn:SetParent(UIParent)
    btn:SetFrameStrata("HIGH")
    btn:ClearAllPoints()
    btn:SetPoint("RIGHT", collectorBtn, "LEFT", -(SPACING * (i - 1)), 0)
end

local function RestoreBtn(btn)
    -- Restore parent and anchor
    local origParent = btn._mmc_openParent or btn._mmc_origParent or Minimap
    btn:SetParent(origParent)
    local p = btn._mmc_origPoint
    if p and p[1] then
        btn:ClearAllPoints()
        btn:SetPoint(p[1], p[2], p[3], p[4] or 0, p[5] or 0)
    end
    btn._mmc_openParent = nil
end

local function CollectorOpen()
    if not collectorBtn then return end
    isOpen = true
    expandedButtons = {}
    for i, btn in ipairs(storedButtons) do
        PositionBtn(btn, i)
        btn:Show()
        C_Timer.After(0, function()
            if isOpen then PositionBtn(btn, i) end
        end)
        expandedButtons[#expandedButtons + 1] = btn
    end

    -- Click anywhere to collapse
    -- Wait until a mouse button is pressed AND released, then close
    C_Timer.After(0.15, function()
        if not isOpen then return end
        mouseWasDown = false
        closeDetector:SetScript("OnUpdate", function()
            if not isOpen then
                closeDetector:SetScript("OnUpdate", nil)
                return
            end
            local down = IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
            if down then
                mouseWasDown = true
            elseif mouseWasDown then
                mouseWasDown = false
                closeDetector:SetScript("OnUpdate", nil)
                if CollectorClose then CollectorClose() end
            end
        end)
    end)
end

CollectorClose = function()
    if not collectorBtn then return end
    isOpen = false
    mouseWasDown = false
    closeDetector:SetScript("OnUpdate", nil)
    suppressHook = true
    for _, btn in ipairs(expandedButtons) do
        RestoreBtn(btn)
        btn:Hide()
    end
    suppressHook = false
    expandedButtons = {}
end

-- ============================================================
-- Create the collector button
-- ============================================================
local function CreateCollector()
    if collectorBtn then return end

    local btn = CreateFrame("Button", "AklimeMod_MMCollector", Minimap)
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFixedFrameStrata(true)
    btn:SetFrameLevel(8)
    btn:SetFixedFrameLevel(true)
    btn:RegisterForClicks("AnyUp")
    btn:RegisterForDrag("LeftButton")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(26, 26)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture("Interface\\Minimap\\Tracking\\None")

    local mask = btn:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)

    btn:SetScript("OnDragStart", function(self)
        if IsLocked() then return end
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale  = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            SetAngle(math.deg(math.atan2(cy - my, cx - mx)))
            UpdateCollectorPos()
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(_, b)
        if b == "LeftButton" then
            if isOpen then CollectorClose() else CollectorOpen() end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["mmc_title"] or "Aklime Mod Tools Button Collector", 1, 0.82, 0, 1)
        GameTooltip:AddLine(
            isOpen and (L["mmc_click_collapse"] or "Click: Collapse")
                    or string.format(L["mmc_click_expand"] or "Click: Expand %d Button(s)", #storedButtons),
            0.7, 0.7, 0.7)
        GameTooltip:AddLine(L["minimap_drag"] or "Drag: Change position", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    collectorBtn = btn
    UpdateCollectorPos()
end

-- ============================================================
-- Events
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        if IsEnabled() then
            C_Timer.After(3.0, function()
                CreateCollector()
                StoreAndHideAll()
                HookLateButtons()
            end)
        end
        -- Safety: in case the button already exists but is disabled
        C_Timer.After(0.1, function()
            if collectorBtn and not IsEnabled() then
                collectorBtn:Hide()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if IsEnabled() then
            C_Timer.After(3.0, function()
                if isOpen then CollectorClose() end
                if not collectorBtn then CreateCollector() end
                StoreAndHideAll()
                HookLateButtons()
            end)
        else
            if collectorBtn then collectorBtn:Hide() end
        end
    end
end)

-- ============================================================
-- Debug slash: /akmmmc        -> status + angle
--              /akmmmc X Y    -> set angle from screen coordinates
-- ============================================================
SLASH_AKM_MMC1 = "/akmmmc"
SlashCmdList["AKM_MMC"] = function(input)
    local x, y = input:match("^(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
    if x and y then
        -- Compute angle from X/Y offset
        local angle = math.deg(math.atan2(tonumber(y), tonumber(x)))
        SetAngle(angle)
        UpdateCollectorPos()
        print(string.format("|cFFFFD100Aklime Mod Tools MMC:|r Winkel gesetzt: %.1f°", angle))
    else
        local db = GetDB()
        print(string.format(
            "|cFFFFD100Aklime Mod Tools MMC:|r Winkel: %.1f° | Buttons: %d | Offen: %s",
            GetAngle(), #storedButtons, tostring(isOpen)
        ))
        print("  Tipp: /akmmmc X Y — z.B. /akmmmc -80 60")
    end
end

-- ============================================================
-- API
-- ============================================================
AklimeMod_MinimapCollector = {
    IsEnabled     = function() return IsEnabled() end,
    IsLocked      = function() return IsLocked() end,
    SetLocked     = function(v)
        local db = GetDB()
        if db then db.locked = v end
    end,
    IncludeOwn    = function() return IncludeOwn() end,
    SetEnabled    = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if v then
            CreateCollector()
            if collectorBtn then collectorBtn:Show() end
            C_Timer.After(0.5, StoreAndHideAll)
            HookLateButtons()
        else
            if isOpen then CollectorClose() end
            RestoreAll()
            if collectorBtn then collectorBtn:Hide() end
        end
    end,
    SetIncludeOwn = function(v)
        local db = GetDB()
        if db then db.includeOwn = v end
        if IsEnabled() then
            if isOpen then CollectorClose() end
            if not v then
                -- Remove the addon's own button from the list and move it back to its original position
                suppressHook = true
                for i, btn in ipairs(storedButtons) do
                    if btn:GetName() == "AklimeModMinimapBtn" then
                        btn:ClearAllPoints()
                        local p = btn._mmc_origPoint
                        if p and p[1] then
                            btn:SetParent(btn._mmc_origParent or Minimap)
                            btn:SetPoint(p[1], p[2], p[3], p[4] or 0, p[5] or 0)
                        end
                        btn:Show()
                        table.remove(storedButtons, i)
                        break
                    end
                end
                suppressHook = false
            end
            StoreAndHideAll()
        end
    end,
}