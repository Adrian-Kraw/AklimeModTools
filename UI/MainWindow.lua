-- UI/MainWindow.lua: main window, insets and row initializers.
-- Flat dark theme with a near black panel, thin warm borders and a gold accent.

-- ============================================================
-- Theme
-- ============================================================
-- Central color values. The colorizer skin "Aklime Mod Tools" uses this
-- table as the default when it is reset.
AklimeMod_Theme = {
    windowBg     = { r = 0.03, g = 0.03, b = 0.03, a = 0.95 },
    -- Tint of the stone background texture (#1D1D1D)
    windowTexTint = { r = 0.114, g = 0.114, b = 0.114, a = 1 },
    windowBorder = { r = 0.85, g = 0.68, b = 0.15, a = 0.9  },
    panelBg      = { r = 0.05, g = 0.05, b = 0.05, a = 0.85 },
    panelBorder  = { r = 0.55, g = 0.45, b = 0.12, a = 0.9  },
    accent       = { r = 1.00, g = 0.82, b = 0.00, a = 1.0  },
    -- Default colors of the list boxes, must match the values in
    -- AklimeMod_Templates.xml
    rowBg        = { r = 0.08, g = 0.075, b = 0.06, a = 1.0 },
    rowBorder    = { r = 0.50, g = 0.40,  b = 0.12, a = 0.7 },
    -- Separator lines under headings and in separators
    line         = { r = 0.85, g = 0.68,  b = 0.15, a = 0.6 },
    -- Selection highlight of the category buttons
    selection    = { r = 0.40, g = 0.30,  b = 0.11, a = 1.0 },
}

-- Override for boxes, lines and selection, set by the colorizer skin.
-- nil = default colors from AklimeMod_Theme.
AklimeMod_RowColors = nil

-- Colors the theme textures of a list row (boxes, separator line, selection).
-- Called by all row initializers so that freshly recycled frames also
-- always get the currently active color.
function AklimeMod_ApplyRowTheme(button)
    local c = AklimeMod_RowColors
    local bg     = (c and c.bg)        or AklimeMod_Theme.rowBg
    local border = (c and c.border)    or AklimeMod_Theme.rowBorder
    local line   = (c and c.line)      or AklimeMod_Theme.line
    local sel    = (c and c.selection) or AklimeMod_Theme.selection
    -- Category buttons: rounded backdrop, fill depending on selection
    if button._isCategory and button.SetBackdropColor then
        local fill = button._selected and sel or bg
        button:SetBackdropColor(fill.r, fill.g, fill.b, fill.a)
        button:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
        return
    end
    if button.borderFill      then button.borderFill:SetVertexColor(border.r, border.g, border.b, border.a) end
    if button.bg              then button.bg:SetVertexColor(bg.r, bg.g, bg.b, bg.a) end
    if button.background      then button.background:SetVertexColor(bg.r, bg.g, bg.b, bg.a) end
    if button.lineBottom      then button.lineBottom:SetVertexColor(line.r, line.g, line.b, line.a) end
    if button.selectedTexture then button.selectedTexture:SetVertexColor(sel.r, sel.g, sel.b, sel.a) end
    -- Inner button of an action row
    if button.button and button.button._styled then AklimeMod_StyleActionButton(button.button) end
end

-- Turns the inner frame of an action row into a rounded button
-- in the theme look (same technique as the category buttons on the left).
local ACTION_BACKDROP = {
    bgFile   = WHITE8X8,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

function AklimeMod_StyleActionButton(btn)
    if not btn or not btn.SetBackdrop then return end
    if not btn._styled then
        btn._styled = true
        btn:SetBackdrop(ACTION_BACKDROP)
        btn:SetScript("OnEnter", function(self)
            local a = AklimeMod_Theme.accent
            self:SetBackdropBorderColor(a.r, a.g, a.b, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            local c = AklimeMod_RowColors
            local border = (c and c.border) or AklimeMod_Theme.rowBorder
            self:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
        end)
    end
    local c = AklimeMod_RowColors
    local bg     = (c and c.bg)     or AklimeMod_Theme.rowBg
    local border = (c and c.border) or AklimeMod_Theme.rowBorder
    btn:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    btn:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
end

-- Register static separator lines (panel title, dashboard) for the theme.
-- They are colored immediately and updated on every theme change.
local themeLines = {}
function AklimeMod_RegisterThemeLine(tex)
    themeLines[#themeLines + 1] = tex
    local line = (AklimeMod_RowColors and AklimeMod_RowColors.line) or AklimeMod_Theme.line
    tex:SetColorTexture(line.r, line.g, line.b, line.a)
end

function AklimeMod_RefreshThemeLines()
    local line = (AklimeMod_RowColors and AklimeMod_RowColors.line) or AklimeMod_Theme.line
    for _, tex in ipairs(themeLines) do
        tex:SetColorTexture(line.r, line.g, line.b, line.a)
    end
end

local WHITE8X8 = "Interface\\BUTTONS\\WHITE8X8"
local FLAT_BACKDROP = {
    bgFile   = WHITE8X8,
    edgeFile = WHITE8X8,
    edgeSize = 1,
}

local function ApplyFlatStyle(target, bg, border)
    target:SetBackdrop(FLAT_BACKDROP)
    target:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    target:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
end

local ACCENT  = AklimeMod_Theme.accent
local PBORDER = AklimeMod_Theme.panelBorder

-- ============================================================
-- Main Window
-- ============================================================
local frame = AklimeModFrame

frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetResizeBounds(700, 400)
table.insert(UISpecialFrames, frame:GetName())

ApplyFlatStyle(frame, AklimeMod_Theme.windowBg, AklimeMod_Theme.windowBorder)

-- Stone background like the old portrait frame (its built in Bg texture),
-- untinted. The background color slider in the colorizer skin
-- "Aklime Mod Tools" tints this texture.
frame.bgTexture = frame:CreateTexture(nil, "BACKGROUND")
frame.bgTexture:SetPoint("TOPLEFT", 1, -1)
frame.bgTexture:SetPoint("BOTTOMRIGHT", -1, 1)
frame.bgTexture:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
frame.bgTexture:SetHorizTile(true)
frame.bgTexture:SetVertTile(true)
frame.bgTexture:SetVertexColor(
    AklimeMod_Theme.windowTexTint.r, AklimeMod_Theme.windowTexTint.g,
    AklimeMod_Theme.windowTexTint.b, AklimeMod_Theme.windowTexTint.a)

-- Drag on the entire window background (there is no title bar anymore)
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then self:StartMoving(); self:SetAlpha(0.75) end
end)
frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing(); self:SetAlpha(1)
end)

-- Close button as a flat red box top right (like in the character tracker)
local CLOSE_RED = { r = 0.38, g = 0.06, b = 0.06, a = 0.95 }
frame.closeButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
frame.closeButton:SetSize(26, 26)
frame.closeButton:SetPoint("TOPRIGHT", -10, -10)
ApplyFlatStyle(frame.closeButton, CLOSE_RED, AklimeMod_Theme.panelBorder)
frame.closeButton.text = frame.closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.closeButton.text:SetPoint("CENTER", 0, 0)
frame.closeButton.text:SetText("X")
frame.closeButton:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
end)
frame.closeButton:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(PBORDER.r, PBORDER.g, PBORDER.b, PBORDER.a)
end)
frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

-- Version number bottom left
local version = C_AddOns.GetAddOnMetadata("AklimeModTools", "Version") or ""
frame.versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.versionText:SetPoint("BOTTOMLEFT", 14, 10)
frame.versionText:SetText(version ~= "" and ("v" .. version) or "")

-- Round addon portrait top left, sticks out slightly over the window
-- corner like the old portrait frame
frame.portrait = frame:CreateTexture(nil, "OVERLAY", nil, 2)
frame.portrait:SetSize(52, 52)
frame.portrait:SetPoint("TOPLEFT", -10, 10)
frame.portrait:SetTexture("Interface\\AddOns\\AklimeModTools\\Assets\\icon")

local portraitMask = frame:CreateMaskTexture()
portraitMask:SetAtlas("CircleMaskScalable")
portraitMask:SetAllPoints(frame.portrait)
frame.portrait:AddMaskTexture(portraitMask)

-- Golden ring around the portrait
frame.portraitRing = frame:CreateTexture(nil, "OVERLAY", nil, 3)
frame.portraitRing:SetSize(58, 58)
frame.portraitRing:SetPoint("CENTER", frame.portrait, "CENTER", 0, 0)
frame.portraitRing:SetAtlas("talents-node-choiceflyout-circle-yellow")

-- Window title centered at the top with separator bar (like the old design)
frame.titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.titleText:SetPoint("TOP", frame, "TOP", 0, -13)
frame.titleText:SetText("Aklime Mod Tools")
frame.titleText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, ACCENT.a)

local titleLine = frame:CreateTexture(nil, "ARTWORK")
titleLine:SetHeight(1)
titleLine:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -38)
titleLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -38)
AklimeMod_RegisterThemeLine(titleLine)

frame.resizeHandle = CreateFrame("Button", nil, frame)
frame.resizeHandle:SetPoint("BOTTOMRIGHT", -1, 1)
frame.resizeHandle:SetSize(26, 26)
frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
frame.resizeHandle:SetScript("OnMouseDown", function(_, b)
    if b == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
end)
frame.resizeHandle:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

-- ============================================================
-- Left Inset (category list)
-- ============================================================
frame.leftInset = CreateFrame("Frame", nil, frame, "BackdropTemplate")
frame.leftInset:SetPoint("TOPLEFT", 12, -46)
frame.leftInset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 250, 30)
ApplyFlatStyle(frame.leftInset, AklimeMod_Theme.panelBg, AklimeMod_Theme.panelBorder)

frame.leftInset.scrollBox = CreateFrame("Frame", nil, frame.leftInset, "WowScrollBoxList")
frame.leftInset.scrollBox:SetPoint("TOPLEFT",     frame.leftInset, "TOPLEFT",     4, -4)
frame.leftInset.scrollBox:SetPoint("BOTTOMRIGHT", frame.leftInset, "BOTTOMRIGHT", -4, 4)

frame.leftInset.scrollBar = CreateFrame("EventFrame", nil, frame.leftInset, "MinimalScrollBar")
frame.leftInset.scrollBar:SetPoint("TOPLEFT",    frame.leftInset, "TOPRIGHT",    7, 0)
frame.leftInset.scrollBar:SetPoint("BOTTOMLEFT", frame.leftInset, "BOTTOMRIGHT", 7, 0)
frame.leftInset.scrollBar:Hide()

AklimeMod_LeftScrollView = CreateScrollBoxListLinearView()
AklimeMod_LeftScrollView:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(
    frame.leftInset.scrollBox,
    frame.leftInset.scrollBar,
    AklimeMod_LeftScrollView
)

-- ============================================================
-- Search bar (top right in the window)
-- ============================================================
local searchBox = CreateFrame("EditBox", "AklimeModSearchBox", frame, "SearchBoxTemplate")
searchBox:SetSize(220, 26)
searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -46, -10)
searchBox:SetAutoFocus(false)
searchBox:SetMaxLetters(64)

-- Placeholder-Text
local function updateSearchPlaceholder()
    if searchBox:GetText() == "" then
        searchBox.Instructions:Show()
    else
        searchBox.Instructions:Hide()
    end
end
searchBox:HookScript("OnTextChanged", updateSearchPlaceholder)
searchBox:HookScript("OnEditFocusGained", function() searchBox.Instructions:Hide() end)
searchBox:HookScript("OnEditFocusLost", updateSearchPlaceholder)

if searchBox.Instructions then
    searchBox.Instructions:SetText(AklimeModL and AklimeModL["search_placeholder"] or "Search...")
end

-- Global reference so Categories.lua can access it
AklimeModSearchBox = searchBox

-- ============================================================
-- Right Inset (content)
-- ============================================================
frame.rightInset = CreateFrame("Frame", nil, frame, "BackdropTemplate")
frame.rightInset:SetPoint("TOPRIGHT",   frame,           "TOPRIGHT",   -12, -46)
frame.rightInset:SetPoint("BOTTOMLEFT", frame.leftInset, "BOTTOMRIGHT",  8,   0)
ApplyFlatStyle(frame.rightInset, AklimeMod_Theme.panelBg, AklimeMod_Theme.panelBorder)

local rightHeader = frame.rightInset:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rightHeader:SetPoint("TOPLEFT",  frame.rightInset, "TOPLEFT",   12, -10)
rightHeader:SetPoint("TOPRIGHT", frame.rightInset, "TOPRIGHT",  -12, -10)
rightHeader:SetJustifyH("CENTER")
rightHeader:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, ACCENT.a)

local rightHeaderLine = frame.rightInset:CreateTexture(nil, "ARTWORK")
rightHeaderLine:SetHeight(1)
rightHeaderLine:SetPoint("TOPLEFT",  frame.rightInset, "TOPLEFT",   6, -32)
rightHeaderLine:SetPoint("TOPRIGHT", frame.rightInset, "TOPRIGHT",  -6, -32)
AklimeMod_RegisterThemeLine(rightHeaderLine)

function AklimeMod_SetRightHeader(text) rightHeader:SetText(text) end

frame.rightInset.scrollBox = CreateFrame("Frame", nil, frame.rightInset, "WowScrollBoxList")
frame.rightInset.scrollBox:SetPoint("TOPLEFT",     frame.rightInset, "TOPLEFT",     4, -36)
-- Leave space on the right for the inner scroll bar
frame.rightInset.scrollBox:SetPoint("BOTTOMRIGHT", frame.rightInset, "BOTTOMRIGHT", -22,  4)

-- ScrollBar sits inside the panel instead of next to it, otherwise it sticks out of the window
frame.rightInset.scrollBar = CreateFrame("EventFrame", nil, frame.rightInset, "MinimalScrollBar")
frame.rightInset.scrollBar:SetPoint("TOPRIGHT",    frame.rightInset, "TOPRIGHT",    -6, -38)
frame.rightInset.scrollBar:SetPoint("BOTTOMRIGHT", frame.rightInset, "BOTTOMRIGHT", -6,   6)
frame.rightInset.scrollBar:SetHideIfUnscrollable(true)

AklimeMod_RightScrollView = CreateScrollBoxListTreeListView()
AklimeMod_RightScrollView:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(
    frame.rightInset.scrollBox,
    frame.rightInset.scrollBar,
    AklimeMod_RightScrollView
)

local TEMPLATE_EXTENTS = {
    AklimeMod_ToggleTemplate       = 32,
    AklimeMod_SliderTemplate       = 52,
    AklimeMod_ModuleHeaderTemplate = 32,
    AklimeMod_SkinHeaderTemplate   = 32,
    AklimeMod_InfoTextTemplate     = 24,
    AklimeMod_ActionButtonTemplate = 46,
    AklimeMod_SeparatorTemplate    = 50,
    AklimeMod_SubColorTemplate     = 32,
    AklimeMod_DropdownTemplate     = 32,
}

AklimeMod_RightScrollView:SetElementExtentCalculator(function(index, node)
    local data = node:GetData()
    if data and data.extent then return data.extent end
    return (data and data.Template and TEMPLATE_EXTENTS[data.Template]) or 32
end)

-- ============================================================
-- Shared row initializers.
-- ============================================================
local function headerInitializer(button, node)
    local data = node:GetData()
    AklimeMod_ApplyRowTheme(button)
    button._refreshCheckbox = function() button.enableButton:SetChecked(data.getEnabled()) end
    button.name:SetText(data.name)
    button:SetScript("OnClick", function() node:ToggleCollapsed() end)
    button.enableButton:SetScript("OnClick", function(self)
        data.setEnabled(self:GetChecked())
    end)
    button.enableButton:SetChecked(data.getEnabled())
end

local function toggleInitializer(button, node)
    local data = node:GetData()
    button._refreshCheckbox = function() button.toggle:SetChecked(data.getVal()) end
    button.name:SetText(data.name)
    button.toggle:SetScript("OnClick", function(self)
        data.setVal(self:GetChecked())
        -- Always mirror the state from the DB: radio options can thus not
        -- be deselected and the check never shows a stale state.
        self:SetChecked(data.getVal())
    end)
    button.toggle:SetChecked(data.getVal())
end

-- Synchronizes all visible checkboxes with their getters.
-- Each initializer stores _refreshCheckbox on the frame for this.
-- Runs synchronously and only over the actually displayed frames,
-- so that after a radio click two checks are never set at once
-- and no recycled frames get wrong states.
-- Collect first, then run: a refresh callback may collapse sections
-- (colorizer), which changes the frame list of the ScrollBox.
function AklimeMod_RefreshRightToggles()
    local scrollBox = frame.rightInset and frame.rightInset.scrollBox
    if not scrollBox or not scrollBox.ForEachFrame then return end
    local pending = {}
    scrollBox:ForEachFrame(function(button)
        if button._refreshCheckbox then pending[#pending + 1] = button._refreshCheckbox end
    end)
    for _, refresh in ipairs(pending) do refresh() end
end

-- Recolors all visible list rows on both sides and the static
-- lines. Called by the colorizer skin after setting
-- AklimeMod_RowColors.
function AklimeMod_RefreshRowTheme()
    local function refreshAll(scrollBox)
        if scrollBox and scrollBox.ForEachFrame then
            scrollBox:ForEachFrame(AklimeMod_ApplyRowTheme)
        end
    end
    refreshAll(frame.leftInset and frame.leftInset.scrollBox)
    refreshAll(frame.rightInset and frame.rightInset.scrollBox)
    AklimeMod_RefreshThemeLines()
end


local function sliderInitializer(frame, node)
    local data = node:GetData()
    if frame.label then frame.label:SetText(data.label or "") end
    local s = frame.slider
    if s then
        -- Remove the old callback before range/value are changed.
        -- Otherwise the recycled callback from the previous node fires on
        -- SetMinMaxValues clamping and writes the wrong value into the DB.
        s:SetScript("OnValueChanged", nil)
        s:SetMinMaxValues(data.sliderMin or 0, data.sliderMax or 100)
        s:SetValueStep(data.sliderStep or 1)
        s:SetObeyStepOnDrag(true)
        local cur = data.getVal and data.getVal() or 0
        s:SetValue(cur)
        local actual = math.floor(s:GetValue() + 0.5)
        -- If the stored value was outside the slider range, correct it.
        if actual ~= cur and data.setVal then data.setVal(actual) end
        if frame.valueText then
            frame.valueText:SetText(data.formatFn and data.formatFn(actual) or tostring(actual))
        end
        s:SetScript("OnValueChanged", function(_, value)
            local v = math.floor(value + 0.5)
            if data.setVal then data.setVal(v) end
            if frame.valueText then
                frame.valueText:SetText(data.formatFn and data.formatFn(v) or tostring(v))
            end
        end)
    end
end
-- Global so ColorizerUI.lua can use the same initializer
AklimeMod_SliderInitializer = sliderInitializer

function AklimeMod_RightFactory(factory, node)
    local data = node:GetData()
    if data.Template == "AklimeMod_ToggleTemplate" then
        factory(data.Template, toggleInitializer)
    elseif data.Template == "AklimeMod_SliderTemplate" then
        factory(data.Template, sliderInitializer)
    else
        factory(data.Template, headerInitializer)
    end
end

-- ============================================================
-- Confirmation dialog for destructive actions
-- ============================================================
StaticPopupDialogs["AKLIMEMOD_CONFIRM"] = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data then data() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Shows "Are you sure?" with Yes / No and runs fn only on Yes.
function AklimeMod_Confirm(actionLabel, fn)
    local L = AklimeModL or {}
    local text = (L["confirm_action"] or "Are you sure you want to do this?")
        .. "\n|cFFFFD100" .. (actionLabel or "") .. "|r"
    local popup = StaticPopup_Show("AKLIMEMOD_CONFIRM", text)
    if popup then popup.data = fn end
end

-- ============================================================
-- Open / toggle
-- ============================================================
function AklimeMod_OpenSettings()
    if InCombatLockdown() then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end