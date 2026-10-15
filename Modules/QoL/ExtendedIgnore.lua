-- Modules/QoL/ExtendedIgnore.lua
-- Extended ignore list beyond WoW's 50-entry limit.
-- Hides chat messages from ignored players.
-- Management: /akm ignore  or  right-click on a player

local L = AklimeModL or {}

local M = {}
AklimeMod_ExtendedIgnore = M

local CHAT_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",  "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
}

local GOLD   = { 0.80, 0.65, 0.10, 1 }
local GOLD_D = { 0.80, 0.65, 0.10, 0.5 }
local BG     = { 0.07, 0.07, 0.08, 0.96 }
local PAD    = 10
local ROW_H  = 22

-- ============================================================
-- DB
-- ============================================================

local function GetDB()
    if AklimeModDB and AklimeModDB.extendedIgnore then return AklimeModDB.extendedIgnore end
    return {}
end

-- ============================================================
-- Lookup cache (name and name-realm)
-- ============================================================

local cache = {}

local function RebuildCache()
    wipe(cache)
    for k in pairs(GetDB().players or {}) do
        cache[k] = true
        local short = k:match("^(.-)%-") or k
        cache[short] = true
    end
end

local function IsIgnoredLocal(name)
    return name ~= nil and cache[name] == true
end

-- ============================================================
-- Chat filter
-- ============================================================

local filtersHooked = false

local function FilterFunc(_, _, _, author)
    if not GetDB().enabled then return false end
    return author ~= nil and IsIgnoredLocal(author)
end

local function HookFilters()
    if filtersHooked then return end
    filtersHooked = true
    for _, event in ipairs(CHAT_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, FilterFunc)
    end
end

-- ============================================================
-- API
-- ============================================================

function M:IsEnabled()    return GetDB().enabled == true end
function M:SetEnabled(v)  GetDB().enabled = v and true or false; if v then HookFilters() end end

function M:Add(name)
    if not name or name == "" then return false end
    local db = GetDB()
    db.players = db.players or {}
    if db.players[name] then return false end
    db.players[name] = true
    RebuildCache()
    return true
end

function M:Remove(name)
    local db = GetDB()
    if not db.players then return end
    if db.players[name] then
        db.players[name] = nil
        RebuildCache()
        return
    end
    -- Fallback: short-name comparison
    local short = name:match("^(.-)%-") or name
    for k in pairs(db.players) do
        if (k:match("^(.-)%-") or k) == short then
            db.players[k] = nil
            RebuildCache()
            return
        end
    end
end

function M:IsIgnored(name) return IsIgnoredLocal(name) end

function M:GetCount()
    local n = 0
    for _ in pairs(GetDB().players or {}) do n = n + 1 end
    return n
end

function M:GetList()
    local list = {}
    for k in pairs(GetDB().players or {}) do table.insert(list, k) end
    table.sort(list)
    return list
end

function M:ClearAll()
    GetDB().players = {}
    RebuildCache()
end

-- ============================================================
-- Context menu
-- ============================================================

local menuHooked = false

local function GetUnitFromCtx(ctx)
    local unit = ctx and ctx.unit
    if unit and UnitExists(unit) then return unit end
    -- Fallback for unit menus without an explicit context
    for _, u in ipairs({ "target", "mouseover" }) do
        if UnitExists(u) then return u end
    end
    return nil
end

local function AddContextEntry(owner, root, ctx)
    if not GetDB().enabled then return end
    local unit = GetUnitFromCtx(ctx)
    if not unit or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end

    local name, realm = UnitName(unit)
    if not name then return end
    realm = (realm and realm ~= "") and realm or nil
    local key   = realm and (name .. "-" .. realm) or name
    local label = name   -- display without realm

    root:CreateDivider()
    root:CreateTitle("Aklime Mod Tools")
    if M:IsIgnored(key) or M:IsIgnored(name) then
        root:CreateButton(L["ignore_menu_remove"], function()
            M:Remove(key)
            M:Remove(name)
            print("|cFFFFD100Aklime Mod Tools:|r " .. string.format(L["msg_ignore_removed"], label))
        end)
    else
        root:CreateButton(L["ignore_menu_add"], function()
            M:Add(key)
            print("|cFFFFD100Aklime Mod Tools:|r " .. string.format(L["msg_ignore_added"], label))
        end)
    end
end

local function HookContextMenus()
    if menuHooked then return end
    if not Menu or not Menu.ModifyMenu then return end
    menuHooked = true
    for _, menu in ipairs({
        "MENU_UNIT_PLAYER",
        "MENU_UNIT_PARTY",
        "MENU_UNIT_RAID_PLAYER",
        "MENU_UNIT_TARGET",
    }) do
        Menu.ModifyMenu(menu, AddContextEntry)
    end
end

-- ============================================================
-- Management window
-- ============================================================

local winFrame, winContent, winScroll, winEditBg, winEditBox, winEmptyLbl
local winRows = {}

local function RefreshWin()
    for _, row in ipairs(winRows) do row:Hide() end
    winRows = {}

    local list = M:GetList()

    for i, name in ipairs(list) do
        local row = CreateFrame("Frame", nil, winContent)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  winContent, "TOPLEFT",  0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", winContent, "TOPRIGHT", 0, -(i - 1) * ROW_H)

        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0)

        -- Remove button
        local removeBtn = CreateFrame("Button", nil, row)
        removeBtn:SetSize(16, 16)
        removeBtn:SetPoint("RIGHT", -4, 0)

        local rbBg = removeBtn:CreateTexture(nil, "BACKGROUND")
        rbBg:SetAllPoints()
        rbBg:SetColorTexture(0.55, 0.12, 0.12, 1)
        local rbLbl = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rbLbl:SetAllPoints()
        rbLbl:SetText("x")

        local cap = name
        removeBtn:SetScript("OnClick", function()
            M:Remove(cap)
            RefreshWin()
        end)

        -- Name
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT",  row,       "LEFT",  4,  0)
        lbl:SetPoint("RIGHT", removeBtn, "LEFT",  -4, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        lbl:SetText(name)

        row:EnableMouse(true)
        row:SetScript("OnEnter", function() hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.08) end)
        row:SetScript("OnLeave", function() hl:SetColorTexture(1, 1, 1, 0) end)

        table.insert(winRows, row)
    end

    winContent:SetHeight(math.max(#list * ROW_H, 1))
    if winEmptyLbl then winEmptyLbl:SetShown(#list == 0) end

    C_Timer.After(0, function()
        local sb = _G["AklimeModIgnoreScrollScrollBar"]
        if sb and winScroll then sb:SetShown(winScroll:GetVerticalScrollRange() > 0) end
    end)
end

local function BuildWin()
    if winFrame then return end

    winFrame = CreateFrame("Frame", "AklimeModIgnoreFrame", UIParent, "BackdropTemplate")
    winFrame:SetSize(300, 380)
    winFrame:SetPoint("CENTER")
    winFrame:SetMovable(true)
    winFrame:EnableMouse(true)
    winFrame:RegisterForDrag("LeftButton")
    winFrame:SetScript("OnDragStart", winFrame.StartMoving)
    winFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left, top = self:GetLeft(), self:GetTop()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end)
    winFrame:SetFrameStrata("DIALOG")
    winFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    winFrame:SetBackdropColor(BG[1], BG[2], BG[3], BG[4])
    winFrame:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], GOLD[4])
    winFrame:Hide()

    tinsert(UISpecialFrames, "AklimeModIgnoreFrame")

    -- Title
    local title = winFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -13)
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    title:SetText(L["ignore_title"])

    local titleSep = winFrame:CreateTexture(nil, "ARTWORK")
    titleSep:SetHeight(1)
    titleSep:SetColorTexture(GOLD_D[1], GOLD_D[2], GOLD_D[3], GOLD_D[4])
    titleSep:SetPoint("TOPLEFT",  winFrame, "TOPLEFT",  8, -32)
    titleSep:SetPoint("TOPRIGHT", winFrame, "TOPRIGHT", -8, -32)

    local closeBtn = CreateFrame("Button", nil, winFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() winFrame:Hide() end)

    -- ScrollFrame
    winScroll = CreateFrame("ScrollFrame", "AklimeModIgnoreScroll", winFrame, "UIPanelScrollFrameTemplate")
    winScroll:SetPoint("TOPLEFT",     winFrame, "TOPLEFT",      PAD,        -36)
    winScroll:SetPoint("BOTTOMRIGHT", winFrame, "BOTTOMRIGHT", -PAD - 16,    58)

    winContent = CreateFrame("Frame", nil, winScroll)
    winContent:SetWidth(300 - PAD * 2 - 20)
    winContent:SetHeight(1)
    winScroll:SetScrollChild(winContent)

    winEmptyLbl = winContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    winEmptyLbl:SetPoint("TOP", 0, -24)
    winEmptyLbl:SetText(L["ignore_empty"])
    winEmptyLbl:Hide()

    -- Divider
    local inputSep = winFrame:CreateTexture(nil, "ARTWORK")
    inputSep:SetHeight(1)
    inputSep:SetColorTexture(GOLD_D[1], GOLD_D[2], GOLD_D[3], GOLD_D[4])
    inputSep:SetPoint("BOTTOMLEFT",  winFrame, "BOTTOMLEFT",   8, 54)
    inputSep:SetPoint("BOTTOMRIGHT", winFrame, "BOTTOMRIGHT", -8, 54)

    -- Input field
    winEditBg = CreateFrame("Frame", nil, winFrame, "BackdropTemplate")
    winEditBg:SetHeight(26)
    winEditBg:SetPoint("BOTTOMLEFT",  winFrame, "BOTTOMLEFT",   PAD, 26)
    winEditBg:SetPoint("BOTTOMRIGHT", winFrame, "BOTTOMRIGHT", -PAD, 26)
    winEditBg:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    winEditBg:SetBackdropColor(0.04, 0.04, 0.05, 1)
    winEditBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)

    winEditBox = CreateFrame("EditBox", nil, winEditBg)
    winEditBox:SetPoint("TOPLEFT",     5, -4)
    winEditBox:SetPoint("BOTTOMRIGHT", -5, 4)
    winEditBox:SetAutoFocus(false)
    winEditBox:SetFontObject(GameFontNormal)
    winEditBox:SetMaxLetters(100)
    winEditBox:SetScript("OnEditFocusGained", function()
        winEditBg:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    end)
    winEditBox:SetScript("OnEditFocusLost", function()
        winEditBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
    end)
    winEditBox:SetScript("OnEnterPressed", function(self)
        local name = strtrim(self:GetText() or "")
        if name ~= "" then
            if M:Add(name) then
                RefreshWin()
            else
                print("|cFFFFD100Aklime Mod Tools:|r " .. string.format(L["msg_ignore_exists"], name))
            end
        end
        self:SetText("")
        self:ClearFocus()
    end)
    winEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    local hint = winFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 8)
    hint:SetText(L["ignore_hint"])
end

function M:ToggleWindow()
    BuildWin()
    if winFrame:IsShown() then
        winFrame:Hide()
    else
        RefreshWin()
        winFrame:Show()
    end
end

-- ============================================================
-- Init
-- ============================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    RebuildCache()
    if GetDB().enabled then HookFilters() end
    HookContextMenus()
end)
