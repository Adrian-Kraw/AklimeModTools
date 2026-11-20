-- AklimeMod.lua — Entry Point

local L = AklimeModL or {}

local RADIUS = 99
local menuOpen = false
local menuHosted = false  -- Layout of the open menu, set when it opens
local menuButtons = {}

-- ============================================================
-- Minimap Button
-- ============================================================
local minimapBtn = CreateFrame("Button", "AklimeModMinimapBtn", Minimap)
minimapBtn:SetSize(36, 36)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFixedFrameStrata(true)
minimapBtn:SetFrameLevel(8)
minimapBtn:SetFixedFrameLevel(true)
minimapBtn:RegisterForClicks("AnyUp")
minimapBtn:RegisterForDrag("LeftButton")

local btnIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
btnIcon:SetSize(30, 30)
btnIcon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
btnIcon:SetTexture("Interface\\AddOns\\AklimeModTools\\Assets\\icon")

local mask = minimapBtn:CreateMaskTexture()
mask:SetAllPoints(btnIcon)
mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
btnIcon:AddMaskTexture(mask)

local btnRing = minimapBtn:CreateTexture(nil, "OVERLAY")
btnRing:SetSize(36, 36)
btnRing:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
btnRing:SetAtlas("talents-node-choiceflyout-circle-yellow")

local function UpdateMinimapPos()
    local angle = math.rad(AklimeModDB.minimapAngle or -139.6)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * RADIUS,
        math.sin(angle) * RADIUS)
end

-- Spread table defined once, used by both call sites
local SPREADS   = { -37, -22, -7, 7, 22, 39 }
local OUTER_R   = 135

-- While the button sits in the bar of a Minimap Button Collector (ours or one
-- of another addon), the menu is a row in the middle of the screen. Collectors
-- arrange their buttons in many ways, so a menu hanging on the button would
-- often be covered by the bar.
local MENU_BUTTON_SIZE = 30
local MENU_FRAME_LEVEL = 9
local HOST_MENU_SIZE   = 40
local HOST_MENU_GAP    = 8   -- Between two buttons of the row

-- The menu buttons change their parent between the two layouts, so parent,
-- size, strata and level are all set here
local function ApplyMenuPositions(angle)
    for i, mb in ipairs(menuButtons) do
        local a = angle + math.rad(SPREADS[i])
        mb:SetParent(Minimap)
        mb:SetSize(MENU_BUTTON_SIZE, MENU_BUTTON_SIZE)
        mb:SetFrameStrata("MEDIUM")
        mb:SetFrameLevel(MENU_FRAME_LEVEL)
        mb:ClearAllPoints()
        mb:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(a) * OUTER_R,
            math.sin(a) * OUTER_R)
    end
end

-- DIALOG lies above the collector bars. The menu belongs to the screen here,
-- not to the minimap, so it is a child of UIParent and keeps its size.
local function ApplyHostedMenuPositions()
    local step   = HOST_MENU_SIZE + HOST_MENU_GAP
    local firstX = -(#menuButtons - 1) * step / 2
    for i, mb in ipairs(menuButtons) do
        mb:SetParent(UIParent)
        mb:SetSize(HOST_MENU_SIZE, HOST_MENU_SIZE)
        mb:SetFrameStrata("DIALOG")
        mb:SetFrameLevel(MENU_FRAME_LEVEL)
        mb:ClearAllPoints()
        mb:SetPoint("CENTER", UIParent, "CENTER", firstX + (i - 1) * step, 0)
    end
end

-- True while the button sits in a collector bar, either in our own Minimap
-- Button Collector or in one of another addon. Other collectors take the button
-- with SetParent or by anchoring it to their bar, so both are checked. This way
-- no collector has to be known by name.
local function IsButtonHosted()
    local collector = AklimeMod_MinimapCollector
    if collector and collector.HostsOwnButton() then return true end
    if minimapBtn:GetParent() ~= Minimap then return true end
    for i = 1, minimapBtn:GetNumPoints() do
        local _, relativeTo = minimapBtn:GetPoint(i)
        if relativeTo and relativeTo ~= Minimap then return true end
    end
    return false
end

minimapBtn:SetScript("OnDragStart", function(self)
    -- In the collector bar the button stays put. The saved angle belongs to
    -- its place on the minimap, a drag here would move the menu arc away from it.
    if IsButtonHosted() then return end
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale  = Minimap:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        AklimeModDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMinimapPos()
        if menuOpen then
            ApplyMenuPositions(math.rad(AklimeModDB.minimapAngle))
        end
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- ============================================================
-- Radial menu
-- ============================================================
local MENU_ITEMS = {
    {   -- top: PvP Chat Block
        icon    = "Interface\\Icons\\achievement_pvp_a_14",
        tooltip = L["menu_pvp_block"] or "Block PvP Chat",
        tooltipLeft  = L["menu_pvp_block_left"]  or "Left-click: Disable Chat in PvP",
        tooltipRight = L["menu_pvp_block_right"] or "Right-click: Hide Chat Only",
        onClick = function()
            if not AklimeMod_PvPChatBlock then return end
            local now = AklimeMod_PvPChatBlock.Toggle()
            if now then
                print("|cFFFFD100Aklime Mod Tools:|r |cFF00FF00" .. (L["menu_pvp_on"]  or "Chat block activated")   .. "|r")
            else
                print("|cFFFFD100Aklime Mod Tools:|r |cFFFF4444" .. (L["menu_pvp_off"] or "Chat block deactivated") .. "|r")
            end
        end,
        onRightClick = function()
            if not AklimeMod_PvPChatBlock then return end
            local hidden = AklimeMod_PvPChatBlock.ToggleChatHide()
            if hidden then
                print("|cFFFFD100Aklime Mod Tools:|r |cFF00FF00" .. (L["menu_pvp_chathide_on"]  or "Hide Chat Only activated")   .. "|r")
            else
                print("|cFFFFD100Aklime Mod Tools:|r |cFFFF4444" .. (L["menu_pvp_chathide_off"] or "Hide Chat Only deactivated") .. "|r")
            end
        end,
    },
    {   -- top-center: Vault
        icon    = "Interface\\Icons\\inv_cape_special_treasure_c_01",
        tooltip = L["menu_vault"] or "Weekly Vault",
        onClick = function()
            C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
            if WeeklyRewardsFrame:IsShown() then WeeklyRewardsFrame:Hide()
            else WeeklyRewardsFrame:Show() end
            -- ESC should close the window
            if not tContains(UISpecialFrames, "WeeklyRewardsFrame") then
                tinsert(UISpecialFrames, "WeeklyRewardsFrame")
            end
        end,
    },
    {   -- center: ToDo
        icon    = C_Item.GetItemIconByID(32620) or "Interface\\Icons\\INV_Misc_Note_01",
        tooltip = L["menu_todo"] or "ToDo List",
        onClick = function()
            if AklimeMod_TodoList then AklimeMod_TodoList:Toggle() end
        end,
    },
    {   -- bottom-center: Character Tracker
        icon    = C_Item.GetItemIconByID(272339) or "Interface\\GossipFrame\\DailyActiveQuestIcon",
        tooltip = L["menu_char_tracker"] or "Character Tracker",
        onClick = function() AklimeMod_CT_Toggle() end,
    },
    {   -- bottom-center: Played Time
        icon    = C_Item.GetItemIconByID(162690) or "Interface\\Icons\\Achievement_BG_returnxflags_def_WSG",
        tooltip = L["menu_played_time"] or "Played Time",
        onClick = function()
            if AklimeMod_PlayedTime then AklimeMod_PlayedTime:Toggle() end
        end,
    },
    {   -- bottom: Settings
        icon    = "Interface\\Icons\\trade_engineering",
        tooltip = L["menu_settings"] or "AklimeMod Settings",
        onClick = function() AklimeMod_OpenSettings() end,
    },
}

local function CloseMenu()
    for _, mb in ipairs(menuButtons) do mb:Hide() end
    menuOpen = false
end

local function CreateMenuButton(item)
    local btn = CreateFrame("Button", nil, Minimap, "BackdropTemplate")
    btn:SetSize(MENU_BUTTON_SIZE, MENU_BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(MENU_FRAME_LEVEL)
    btn:RegisterForClicks("AnyUp")
    btn:Hide()

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10, insets={left=2,right=2,top=2,bottom=2},
    })
    btn:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    btn:SetBackdropBorderColor(0.8, 0.65, 0.1, 1)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT",     btn, "TOPLEFT",      3, -3)
    tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3,  3)
    if item.atlas then
        tex:SetAtlas(item.atlas)
    else
        tex:SetTexture(item.icon)
    end

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetAlpha(0.3)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
        -- In the row a tooltip on the left would cover the neighbour button
        GameTooltip:SetOwner(self, menuHosted and "ANCHOR_TOP" or "ANCHOR_LEFT")
        GameTooltip:SetText(item.tooltip, 1, 0.82, 0, 1)
        if item.tooltipLeft then
            GameTooltip:AddLine(item.tooltipLeft, 0.7, 0.7, 0.7)
        end
        if item.tooltipRight then
            GameTooltip:AddLine(item.tooltipRight, 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.8, 0.65, 0.1, 1)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function(self, button)
        CloseMenu()
        if button == "RightButton" and item.onRightClick then
            item.onRightClick()
        else
            item.onClick()
        end
    end)

    return btn
end

-- The arc follows the place where the button really sits. The saved angle can
-- differ from it, for example after the collector put the button back.
local function GetButtonAngle()
    local mapX, mapY = Minimap:GetCenter()
    local btnX, btnY = minimapBtn:GetCenter()
    if not (mapX and btnX) then
        return math.rad(AklimeModDB.minimapAngle or -139.6)
    end
    return math.atan2(btnY - mapY, btnX - mapX)
end

local function PositionMenuButtons()
    menuHosted = IsButtonHosted()
    if menuHosted then
        ApplyHostedMenuPositions()
    else
        ApplyMenuPositions(GetButtonAngle())
    end
end

-- The row in the middle of the screen has no link to the button anymore. A
-- collector can close its bar and hide the button while the row is open, so
-- the row closes with a click anywhere outside of it. Closing it when the button
-- hides would not work, bars that close when the mouse leaves would take the
-- row away before a choice is made.
local clickAwayWatcher = CreateFrame("Frame")

local function WatchClickAway()
    local mouseWasDown = false
    clickAwayWatcher:SetScript("OnUpdate", function()
        if not menuOpen then
            clickAwayWatcher:SetScript("OnUpdate", nil)
            return
        end
        if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
            mouseWasDown = true
        elseif mouseWasDown then
            mouseWasDown = false
            if not AklimeMod_IsMouseOverMenu() then CloseMenu() end
        end
    end)
end

local function ToggleMenu()
    if menuOpen then
        CloseMenu()
        return
    end
    menuOpen = true
    PositionMenuButtons()
    for _, mb in ipairs(menuButtons) do mb:Show() end
    if menuHosted then WatchClickAway() end
end

-- Used by the Minimap Button Collector, which closes its bar with a click
-- anywhere except on the addon button and its menu
function AklimeMod_CloseRadialMenu()
    CloseMenu()
end

function AklimeMod_IsMouseOverMenu()
    if minimapBtn:IsMouseOver() then return true end
    for _, mb in ipairs(menuButtons) do
        if mb:IsShown() and mb:IsMouseOver() then return true end
    end
    return false
end

minimapBtn:SetScript("OnClick", function(_, b)
    if b == "LeftButton" then ToggleMenu() end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Aklime Mod Tools", 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["minimap_click"] or "Click: Open / close menu", 0.7, 0.7, 0.7)
    GameTooltip:AddLine(L["minimap_drag"]  or "Drag: Change position",   0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================
-- Slash Commands
-- ============================================================
SLASH_AKLIMEMOD1, SLASH_AKLIMEMOD2 = "/akm", "/aklimemod"
SlashCmdList["AKLIMEMOD"] = function() AklimeMod_OpenSettings() end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, arg1)

    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        AklimeMod_InitDB()
        if AklimeMod_Colorizer then AklimeMod_Colorizer:Init() end
        UpdateMinimapPos()
        AklimeMod_BuildLeftPanel()
        AklimeMod_InitSearch()
        -- Always register. The function checks the DB status itself.
        -- WoW does not reliably unregister slash commands via nil.
        SLASH_AKM_RL1, SLASH_AKM_RL2 = "/rl", "/nl"
        SlashCmdList["AKM_RL"] = function()
            if AklimeModDB and AklimeModDB.reloadUI and AklimeModDB.reloadUI.enabled then
                ReloadUI()
            end
        end
        for _, item in ipairs(MENU_ITEMS) do
            table.insert(menuButtons, CreateMenuButton(item))
        end

    elseif event == "PLAYER_LOGIN" then
        -- SavedVariables are guaranteed to be loaded now
        if AklimeMod_PreyPercent then AklimeMod_PreyPercent.Init() end
        if AklimeMod_PvPChatBlock then AklimeMod_PvPChatBlock.Init() end
        if AklimeMod_PvPNameplateColor then AklimeMod_PvPNameplateColor.Init() end
        AklimeMod_ShowNewsHint()

    elseif event == "PLAYER_TARGET_CHANGED" then
        AklimeMod_UpdateRareFrame()

    elseif event == "PLAYER_ENTERING_WORLD" then
        if AklimeModDB and AklimeModDB.eliteFrame and AklimeModDB.eliteFrame.enabled then
            C_Timer.After(0.5, function()
                AklimeMod_ApplyEliteFrame(AklimeModDB.eliteFrame.style)
            end)
        end
    end
end)