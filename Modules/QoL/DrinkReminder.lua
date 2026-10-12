-- Modules/QoL/DrinkReminder.lua
-- Periodically reminds you to drink/stretch.
-- Own frame at the top center, styled like the Blizzard AlertFrame.

local L = AklimeModL or {}

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.drinkReminder
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

local function IsInInstanceNow()
    local inInst, instanceType = IsInInstance()
    if not inInst then return false end
    -- Housing does not count as an instance: the reminder should appear there too.
    if instanceType == "interior" or instanceType == "neighborhood" then return false end
    return true
end

-- ============================================================
-- Custom frame, styled like the Blizzard AlertFrame, top center
-- ============================================================
local alertFrame = nil

local function CreateAlertFrame()
    if alertFrame then return end

    local f = CreateFrame("Frame", "AklimeMod_DrinkAlert", UIParent, "BackdropTemplate")
    f:SetSize(310, 70)
    f:SetPoint("TOP", UIParent, "TOP", 0, -180)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.10, 0.20, 0.92)
    f:SetBackdropBorderColor(0.85, 0.65, 0.10, 1)
    f:Hide()

    -- Black background for the icon area
    local iconBg = f:CreateTexture(nil, "BACKGROUND")
    iconBg:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    iconBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    iconBg:SetWidth(72)
    iconBg:SetColorTexture(0, 0, 0, 1)

    -- Golden divider
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", 73, -4)
    divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 73, 4)
    divider:SetWidth(2)
    divider:SetColorTexture(0.85, 0.65, 0.10, 1)

    -- Icon, round with a portrait mask
    local iconFrame = CreateFrame("Frame", nil, f)
    iconFrame:SetSize(60, 60)
    iconFrame:SetPoint("LEFT", f, "LEFT", 6, 0)

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconFrame)
    icon:SetTexture(132797)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Round mask
    local mask = iconFrame:CreateMaskTexture()
    mask:SetAllPoints(iconFrame)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    icon:AddMaskTexture(mask)

    -- Icon border (square gold like AlertFrame)
    local iconBorder = iconFrame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetSize(70, 70)
    iconBorder:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    iconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
    iconBorder:SetVertexColor(0.9, 0.75, 0.35, 1)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -8)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    title:SetText(L["drink_title"] or "Drink something! Stretch!")
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetJustifyH("LEFT")

    -- Description
    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -4)
    desc:SetText(L["drink_desc"] or "Time for a short break.")
    desc:SetTextColor(0.9, 0.9, 0.9, 1)
    desc:SetJustifyH("LEFT")

    -- "Got it!" button directly below the frame.
    -- Child of the alert frame so it shares its strata and always sits above other windows.
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(110, 24)
    btn:SetPoint("TOP", f, "BOTTOM", 0, -4)
    btn:SetText(L["drink_btn"] or "Got it!")
    btn:SetScript("OnClick", function()
        f:Hide()
        btn:Hide()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    btn:Hide()
    f.btn = btn

    f:SetScript("OnShow", function()
        btn:Show()
        PlaySound(SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST)
    end)
    f:SetScript("OnHide", function()
        btn:Hide()
    end)

    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then f:Hide() end
    end)

    alertFrame = f
end

-- ============================================================
-- Ticker + instance logic
-- ============================================================
local ticker       = nil
local alertPending = false

local function ShowAlert()
    if not IsEnabled() then return end
    local db = GetDB()
    if db.disableInInstance and IsInInstanceNow() then
        alertPending = true
        return
    end
    alertPending = false
    if not alertFrame then CreateAlertFrame() end
    alertFrame:Show()
end

local function TryShowAlert()
    if not IsEnabled() then return end
    local db = GetDB()
    if db.disableInInstance and IsInInstanceNow() then
        alertPending = true
        return
    end
    ShowAlert()
end

local function UpdateTicker()
    if ticker then ticker:Cancel(); ticker = nil end
    alertPending = false
    local db = GetDB()
    if not db or not db.enabled then return end
    local interval = (db.intervalMinutes or 60) * 60
    ticker = C_Timer.NewTicker(interval, TryShowAlert)
end

-- ============================================================
-- Events
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(_, event, arg1, isLogin, isReload)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        CreateAlertFrame()
        UpdateTicker()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if alertPending and not IsInInstanceNow() then
            C_Timer.After(2.0, function()
                if alertPending then ShowAlert() end
            end)
        end
        if not ticker then UpdateTicker() end
    end
end)

-- ============================================================
-- API
-- ============================================================
AklimeMod_DrinkReminder = {
    IsEnabled            = function() return IsEnabled() end,
    SetEnabled           = function(v)
        local db = GetDB(); if db then db.enabled = v end
        UpdateTicker()
    end,
    GetInterval          = function()
        local db = GetDB(); return db and db.intervalMinutes or 60
    end,
    SetInterval          = function(m)
        local db = GetDB(); if db then db.intervalMinutes = m end
        UpdateTicker()
        -- The caller in Categories.lua handles the checkbox sync.
        -- No category rebuild: that would collapse all sections.
    end,
    GetDisableInInstance = function()
        local db = GetDB(); return db and db.disableInInstance
    end,
    SetDisableInInstance = function(v)
        local db = GetDB(); if db then db.disableInInstance = v end
    end,
    ShowNow              = function() ShowAlert() end,
}