-- ChatInteraction.lua
-- C button on the chat (movable, size like the contacts icon)
-- Links clickable with a dedicated popup window

AklimeMod_Defaults = AklimeMod_Defaults or {}
AklimeMod_Defaults.chatInteraction = {
    copyPaste  = false,
    clickLinks = false,
    btnLocked  = false,
    btnX = nil, btnY = nil,
}

local function GetDB()
    if AklimeModDB and AklimeModDB.chatInteraction then return AklimeModDB.chatInteraction end
    return AklimeMod_Defaults.chatInteraction
end

-- ============================================================
-- Chat copy window
-- ============================================================
local copyFrame = nil

local function GetOrCreateCopyFrame()
    if copyFrame then return copyFrame end

    local f = CreateFrame("Frame", "AklimeMod_ChatCopyFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 340)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:Hide()
    tinsert(UISpecialFrames, "AklimeMod_ChatCopyFrame")

    -- Background: slightly transparent, dark tone
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile=true, tileSize=32, edgeSize=26,
        insets={left=8, right=8, top=8, bottom=8},
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
    f:SetBackdropBorderColor(1, 0.82, 0, 1)

    -- Title bar (drag area)
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT"); titleBar:SetPoint("TOPRIGHT"); titleBar:SetHeight(32)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function() f:StartMoving() end)
    titleBar:SetScript("OnMouseUp",   function() f:StopMovingOrSizing() end)

    -- Divider below the title
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 0.82, 0, 0.4)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -32)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -32)

    -- Title text
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("|cFFFFD100Chat|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ScrollFrame
    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",     12, -38)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 46)
    f.scrollFrame = sf

    -- EditBox
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:SetFontObject(ChatFontNormal)
    eb:SetTextColor(0.9, 0.9, 0.9, 1)
    eb:SetAutoFocus(false)
    eb:EnableMouse(true)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)
    f.editBox = eb

    -- Divider above the buttons
    local divider2 = f:CreateTexture(nil, "ARTWORK")
    divider2:SetColorTexture(1, 0.82, 0, 0.4)
    divider2:SetHeight(1)
    divider2:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  10, 42)
    divider2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 42)

    -- Buttons centered at the bottom
    local btnAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnAll:SetSize(140, 26)
    btnAll:SetPoint("BOTTOM", f, "BOTTOM", -76, 12)
    btnAll:SetText(AklimeModL["chat_copy_select_all"] or "Select All")
    btnAll:SetScript("OnClick", function() eb:SetFocus(); eb:HighlightText() end)

    local btnClose = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnClose:SetSize(110, 26)
    btnClose:SetPoint("BOTTOM", f, "BOTTOM", 76, 12)
    btnClose:SetText(AklimeModL["chat_copy_close"] or "Close")
    btnClose:SetScript("OnClick", function() f:Hide() end)

    copyFrame = f
    return f
end

local function CleanChatMessage(msg)
    if type(msg) ~= "string" then return nil end

    local ok, clean = pcall(function()
        return msg:gsub("|c%x%x%x%x%x%x%x%x","")
                  :gsub("|r","")
                  :gsub("|H[^|]+|h%[([^%]]+)%]|h","%1")
                  :gsub("|T[^|]+|t","")
                  :gsub("|4[^;]+;","")
    end)

    if ok then return clean end
    return nil
end

local function OpenChatCopy(chatIdx, url)
    local f = GetOrCreateCopyFrame()
    f.editBox:SetText("")

    if url then
        -- URL mode: small, URL highlighted
        f:SetHeight(100)
        f.editBox:SetWidth(f.scrollFrame:GetWidth())
        f.editBox:Insert(url)
        f.editBox:HighlightText()
        f.editBox:SetFocus()
    else
        f:SetHeight(320)
        local cf = _G["ChatFrame"..(chatIdx or 1)]
        if not cf then return end

        -- Set the width before inserting, otherwise WoW computes line breaks
        -- with the wrong width and clicks land on the wrong line.
        f.editBox:SetWidth(f.scrollFrame:GetWidth())

        local maxLines = cf:GetNumMessages() or 0
        local startLine = math.max(1, maxLines - 300)
        local inserted = false
        for i = startLine, maxLines do
            local ok, msg = pcall(cf.GetMessageInfo, cf, i)
            msg = ok and CleanChatMessage(msg) or nil
            if msg and msg ~= "" then
                f.editBox:Insert((inserted and "\n" or "") .. msg)
                inserted = true
            end
        end

        -- Scroll to the bottom so the newest messages are visible.
        -- Wait one frame because GetVerticalScrollRange is only current after render.
        C_Timer.After(0, function()
            f.scrollFrame:SetVerticalScroll(f.scrollFrame:GetVerticalScrollRange())
        end)
    end
    f:Show()
end

-- ============================================================
-- C button: movable, size like the contacts icon (~32x32)
-- ============================================================
local chatBtn = nil

local BTN_BORDER_DEFAULT = { 0.6, 0.5, 0.2, 1 }
local BTN_HOVER_DEFAULT  = { 1, 0.82, 0, 1 }
local BTN_TEXT_DEFAULT   = { 1, 0.82, 0, 1 }

-- Uses the Colorizer skin "chatCopyBtn" when active, otherwise the default color.
local function GetBtnColor(colorKey, default)
    local C = AklimeMod_Colorizer
    if C and C:IsEnabled("chatCopyBtn") then return C:GetColor("chatCopyBtn", colorKey) end
    return unpack(default)
end

local function ApplyBtnColors(btn, hovered)
    if hovered then
        btn:SetBackdropBorderColor(GetBtnColor("highlight", BTN_HOVER_DEFAULT))
    else
        btn:SetBackdropBorderColor(GetBtnColor("border", BTN_BORDER_DEFAULT))
    end
    btn.label:SetTextColor(GetBtnColor("text", BTN_TEXT_DEFAULT))
end

local function CreateChatBtn()
    if chatBtn then return chatBtn end

    local btn = CreateFrame("Button", "AklimeMod_ChatCopyBtn", UIParent, "BackdropTemplate")
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetToplevel(true)

    -- Restore position or default next to the chat
    local db = GetDB()
    if db.btnX and db.btnY then
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", db.btnX, db.btnY)
    else
        btn:SetPoint("BOTTOMLEFT", ChatFrame1, "BOTTOMRIGHT", 4, 0)
    end

    -- Appearance: like the contacts icon
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets={left=2,right=2,top=2,bottom=2},
    })
    btn:SetBackdropColor(0.08, 0.08, 0.08, 0.9)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
    tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetAllPoints()
    label:SetText("C")
    btn.label = label
    ApplyBtnColors(btn, false)
    tex:Hide()  -- Text instead of texture

    -- Drag
    btn:SetScript("OnDragStart", function(self)
        if not GetDB().copyPaste then return end
        if GetDB().btnLocked then return end
        self:StartMoving()
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x = self:GetLeft()
        local y = self:GetBottom()
        GetDB().btnX = x
        GetDB().btnY = y
        -- Re-anchor so the position stays saved
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    end)

    -- Highlight
    btn:SetScript("OnEnter", function(self)
        ApplyBtnColors(self, true)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cFFFFD100" .. AklimeModL["mod_chat_interaction"] .. "|r", 1, 1, 1)
        GameTooltip:AddLine(AklimeModL["chat_copy_tip_click"], 0.7,0.7,0.7)
        GameTooltip:AddLine(AklimeModL["chat_copy_tip_drag"], 0.7,0.7,0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        ApplyBtnColors(self, false)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function()
        if copyFrame and copyFrame:IsShown() then
            copyFrame:Hide()
        else
            -- Which ChatFrame is currently active (visible)?
            local idx = 1
            for i = 1, NUM_CHAT_WINDOWS do
                local cf = _G["ChatFrame"..i]
                if cf and cf:IsShown() then idx = i; break end
            end
            OpenChatCopy(idx)
        end
    end)

    chatBtn = btn
    return btn
end

local function UpdateChatBtn()
    if not chatBtn then return end
    if GetDB().copyPaste then chatBtn:Show() else chatBtn:Hide() end
end

-- ============================================================
-- URL detection and clickable links
-- ============================================================
local URL_PATTERNS = {
    "^(%a[%w+.-]+://%S+)",
    "%f[%S](%a[%w+.-]+://%S+)",
    "^(www%.[-%w_%%]+%.%a%a+%S*)",
    "%f[%S](www%.[-%w_%%]+%.%a%a+%S*)",
    "(%S+@[%w_.-%%]+%.%a%a+)",
}

local function FormatURL(url)
    return "|cff4db8ff|Hurl:"..url.."|h["..url.."]|h|r"
end

local function MakeClickable(_, _, msg, ...)
    if not GetDB().clickLinks then return false, msg, ... end

    local ok, newMsg = pcall(function()
        if type(msg) ~= "string" then return msg end
        for _, p in ipairs(URL_PATTERNS) do
            if msg:find(p) then
                msg = msg:gsub(p, FormatURL("%1"))
            end
        end
        return msg
    end)

    if ok then
        msg = newMsg
    end
    return false, msg, ...
end

-- A URL click opens the copy window with the URL.
-- hooksecurefunc instead of direct replacement, so no taint is placed on ItemRefTooltip.
hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(self, link)
    if link and link:sub(1, 3) == "url" then
        OpenChatCopy(nil, link:sub(5))
    end
end)

local CHAT_TYPES = {
    "SAY","YELL","PARTY","PARTY_LEADER","RAID","RAID_LEADER","RAID_WARNING",
    "GUILD","OFFICER","WHISPER","WHISPER_INFORM","CHANNEL","EMOTE","SYSTEM",
    "BN_WHISPER","BN_WHISPER_INFORM","BATTLEGROUND","BATTLEGROUND_LEADER",
}
local filtersOn = false
local function RegisterFilters()
    if filtersOn then return end
    for _, t in ipairs(CHAT_TYPES) do ChatFrame_AddMessageEventFilter("CHAT_MSG_"..t, MakeClickable) end
    filtersOn = true
end
local function UnregisterFilters()
    if not filtersOn then return end
    for _, t in ipairs(CHAT_TYPES) do ChatFrame_RemoveMessageEventFilter("CHAT_MSG_"..t, MakeClickable) end
    filtersOn = false
end

-- ============================================================
-- Init
-- ============================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    -- Create the C button (but only show it when enabled)
    CreateChatBtn()
    UpdateChatBtn()
    -- Links
    if GetDB().clickLinks then RegisterFilters() end
end)

-- ============================================================
-- API
-- ============================================================
AklimeMod_ChatInteraction = {
    IsCopyPasteEnabled  = function() return GetDB().copyPaste end,
    SetCopyPasteEnabled = function(v)
        GetDB().copyPaste = v
        CreateChatBtn()
        UpdateChatBtn()
    end,
    IsClickLinksEnabled  = function() return GetDB().clickLinks end,
    SetClickLinksEnabled = function(v)
        GetDB().clickLinks = v
        if v then RegisterFilters() else UnregisterFilters() end
    end,
    RefreshBtnColors = function()
        if chatBtn then ApplyBtnColors(chatBtn, false) end
    end,
    IsBtnLocked  = function() return GetDB().btnLocked end,
    SetBtnLocked = function(v) GetDB().btnLocked = v end,
}
