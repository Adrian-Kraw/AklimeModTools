-- UI/NewsPanel.lua
-- News tab of the settings window. Shows the most important changes of the
-- installed version as cards and prints a one time chat hint after an update.
-- The entries are hardcoded and replaced per release. RELEASE_NOTES.md is not
-- packaged, so the game cannot read it.

local L = AklimeModL or {}

local ADDON_NAME      = "AklimeModTools"
local NEWS_HINT_DELAY = 3    -- Chat history restores old messages right after login

-- Layout in pixels
local TOP_OFFSET      = 40   -- Room for the header of the right panel
local SCROLLBAR_SPACE = 26
local PANEL_PAD       = 12
local HEADER_TOP      = 6
local HEADER_LINE_Y   = 34
local HEADER_HEIGHT   = 48
local CARD_GAP        = 12
local CARD_PAD        = 14
local TITLE_GAP       = 10
local LINE_GAP        = 6
local BULLET_INDENT   = 14
local BULLET_SIZE     = 4
local TAG_HEIGHT      = 18
local TAG_PAD_X       = 8
local TAG_ALPHA       = 0.85

-- Same categories as in RELEASE_NOTES.md
local TAG_COLORS = {
    new     = { r = 0.20, g = 0.62, b = 0.25 },
    fixed   = { r = 0.20, g = 0.45, b = 0.80 },
    changed = { r = 0.75, g = 0.52, b = 0.12 },
}

-- Hardcoded highlights of the installed version, replaced per release.
-- title, text and where are locale keys, where is optional. Every line of
-- text becomes one bullet. tag is a key of TAG_COLORS.
local NEWS_ENTRIES = {
    { title = "mod_action_bar_compact", tag = "new",   text = "news_action_bars", where = "news_action_bars_where" },
    { title = "cat_news",               tag = "new",   text = "news_news" },
    { title = "mod_gear_check",         tag = "fixed", text = "news_gear_check" },
    { title = "mod_chat_history",       tag = "fixed", text = "news_chat_history" },
}

-- Same rounded look as the category buttons on the left
local CARD_BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

local panel = nil

local function GetInstalledVersion()
    return C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
end

-- ============================================================
-- Cards
-- ============================================================
local function ApplyCardTheme(card)
    local c = AklimeMod_RowColors
    local bg     = (c and c.bg)     or AklimeMod_Theme.rowBg
    local border = (c and c.border) or AklimeMod_Theme.rowBorder
    card:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    card:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
end

local function CreateTag(card, tagKey)
    local color = TAG_COLORS[tagKey]
    local tag = CreateFrame("Frame", nil, card)
    tag:SetHeight(TAG_HEIGHT)
    tag:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -CARD_PAD + 1)

    local bg = tag:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(color.r, color.g, color.b, TAG_ALPHA)

    local label = tag:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(L["news_tag_" .. tagKey] or tagKey)
    tag:SetWidth(label:GetStringWidth() + TAG_PAD_X * 2)
end

local function CreateCard(parent, entry)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop(CARD_BACKDROP)

    if TAG_COLORS[entry.tag] then CreateTag(card, entry.tag) end

    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    card.title:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -CARD_PAD)
    card.title:SetText(L[entry.title] or entry.title)

    local accent = AklimeMod_Theme.accent
    card.lines = {}
    for text in (L[entry.text] or ""):gmatch("[^\n]+") do
        local bullet = card:CreateTexture(nil, "OVERLAY")
        bullet:SetSize(BULLET_SIZE, BULLET_SIZE)
        bullet:SetColorTexture(accent.r, accent.g, accent.b, accent.a)

        local fs = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        card.lines[#card.lines + 1] = { bullet = bullet, text = fs }
    end

    if entry.where and L[entry.where] then
        card.where = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        card.where:SetJustifyH("LEFT")
        card.where:SetText(L[entry.where])
    end
    return card
end

-- Positions the content of a card for the given width and returns the card
-- height. Wrapped text only reports its real height once its width is set.
local function LayoutCard(card, width)
    local textWidth = width - CARD_PAD * 2 - BULLET_INDENT
    local y = CARD_PAD + card.title:GetStringHeight() + TITLE_GAP

    for i, line in ipairs(card.lines) do
        if i > 1 then y = y + LINE_GAP end
        line.text:SetWidth(textWidth)
        line.text:ClearAllPoints()
        line.text:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD + BULLET_INDENT, -y)
        -- Centered on the first text line, not on the whole wrapped block
        local _, fontHeight = line.text:GetFont()
        line.bullet:ClearAllPoints()
        line.bullet:SetPoint("CENTER", line.text, "TOPLEFT", -BULLET_INDENT / 2, -fontHeight / 2)
        y = y + line.text:GetStringHeight()
    end

    if card.where then
        y = y + TITLE_GAP
        card.where:SetWidth(width - CARD_PAD * 2)
        card.where:ClearAllPoints()
        card.where:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -y)
        y = y + card.where:GetStringHeight()
    end

    local height = y + CARD_PAD
    card:SetHeight(height)
    return height
end

-- ============================================================
-- Panel
-- ============================================================
local function Layout()
    local width = panel.scroll:GetWidth()
    if not width or width <= 0 then return end

    local cardWidth = width - PANEL_PAD * 2
    local y = HEADER_HEIGHT
    panel.content:SetWidth(width)
    for _, card in ipairs(panel.cards) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", panel.content, "TOPLEFT", PANEL_PAD, -y)
        card:SetWidth(cardWidth)
        y = y + LayoutCard(card, cardWidth) + CARD_GAP
    end
    panel.content:SetHeight(y)
end

local function CreatePanel(parent)
    panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)
    panel:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     4, -TOP_OFFSET)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -SCROLLBAR_SPACE, PANEL_PAD)
    scroll.scrollBarHideable = true

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    panel.scroll, panel.content = scroll, content

    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", content, "TOP", 0, -HEADER_TOP)
    header:SetText(string.format(L["news_header"], GetInstalledVersion() or ""))

    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  content, "TOPLEFT",  PANEL_PAD,  -HEADER_LINE_Y)
    line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PANEL_PAD, -HEADER_LINE_Y)
    AklimeMod_RegisterThemeLine(line)

    panel.cards = {}
    for _, entry in ipairs(NEWS_ENTRIES) do
        panel.cards[#panel.cards + 1] = CreateCard(content, entry)
    end

    -- Colors may have changed through the colorizer since the last visit
    panel:SetScript("OnShow", function()
        for _, card in ipairs(panel.cards) do ApplyCardTheme(card) end
        Layout()
    end)
    scroll:HookScript("OnSizeChanged", Layout)
end

-- ============================================================
-- API
-- ============================================================
AklimeMod_NewsPanel = {}

function AklimeMod_NewsPanel.Get(parent)
    if not panel then CreatePanel(parent) end
    return panel
end

-- Prints the hint once per installed version
function AklimeMod_ShowNewsHint()
    local version = GetInstalledVersion()
    if not version or AklimeModDB.newsSeenVersion == version then return end
    AklimeModDB.newsSeenVersion = version
    C_Timer.After(NEWS_HINT_DELAY, function()
        print("|cFFFFD100Aklime Mod Tools:|r " .. string.format(L["news_hint"], version))
    end)
end
