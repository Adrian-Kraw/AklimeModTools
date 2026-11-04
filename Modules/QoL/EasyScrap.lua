-- Modules/QoL/EasyScrap.lua
-- Makes the scrapping machine easier and more automatic.
-- A list below the machine shows every scrappable item of the bags.
-- A click puts an item into the machine. Fill loads up to nine items at once
-- and the machine is filled again by itself after every finished scrap run.
-- The idea comes from the addon Easy Scrap, rebuilt in the look of this addon.

local L = AklimeModL or {}

local MACHINE_ADDON   = "Blizzard_ScrappingMachineUI"
local MACHINE_SLOTS   = 9
local LAST_BAG        = NUM_BAG_SLOTS or 4
local FILL_STEP_DELAY = 0.1   -- Pause between two items so the machine can take each one
local REFILL_FALLBACK = 0.6   -- Backup in case the bag update arrives before the machine is empty
local REFRESH_DEBOUNCE = 0.2

-- Layout in pixels
local PANEL_HEIGHT    = 300
local PANEL_GAP       = 4
local PANEL_PAD       = 10
local SCROLLBAR_SPACE = 26
local TITLE_TOP       = 8
local SEARCH_TOP      = 32
local SEARCH_HEIGHT   = 20
local LIST_TOP        = 58
local FOOTER_HEIGHT   = 34
local FOOTER_BUTTON_WIDTH  = 80
local FOOTER_BUTTON_HEIGHT = 22
local BUTTON_SIZE     = 36
local BUTTON_GAP      = 4
local ICON_INSET      = 1
local BADGE_FONT      = "Fonts\\FRIZQT__.TTF"
local BADGE_FONT_SIZE = 11
local IGNORED_ALPHA   = 0.35
local IN_MACHINE_TINT = { r = 0.10, g = 0.90, b = 0.20, a = 0.40 }
local HINT_COLOR      = { r = 0.7, g = 0.7, b = 0.7 }

-- Same rounded look as the cards in the news tab
local PANEL_BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}
local BUTTON_BACKDROP = {
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
}

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.easyScrap then return AklimeModDB.easyScrap end
    return {}
end

local function SlotKey(bag, slot)
    return bag .. ":" .. slot
end

-- ============================================================
-- State
-- ============================================================
local M = {}
AklimeMod_EasyScrap = M

local panel          = nil
local searchBox      = nil
local searchHint     = nil
local content        = nil
local countText      = nil
local emptyText      = nil
local itemButtons    = {}
local allItems       = {}   -- every scrappable bag item
local visibleItems   = {}   -- allItems after the search
local searchText     = ""
local scrappableCache = {}  -- itemID -> true or false
local pendingLoads   = {}   -- itemID -> true while the item data is requested
local fillQueue      = {}
local fillToken      = 0
local refillPending  = false
local refreshQueued  = false
local setupDone      = false

-- ============================================================
-- Scrappable check
-- ============================================================
-- nil means the item data is not loaded yet, the caller asks again later.
local function IsScrappable(itemID)
    local cached = scrappableCache[itemID]
    if cached ~= nil then return cached end

    if not C_Item.IsItemDataCachedByID(itemID) then
        pendingLoads[itemID] = true
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end

    local data = C_TooltipInfo.GetItemByID(itemID)
    local result = false
    if data then
        for _, line in ipairs(data.lines) do
            if line.leftText == ITEM_SCRAPABLE then
                result = true
                break
            end
        end
    end
    scrappableCache[itemID] = result
    return result
end

-- ============================================================
-- Equipment sets
-- ============================================================
local function BuildEquipmentSetLookup()
    local lookup = {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        for _, location in pairs(C_EquipmentSet.GetItemLocations(setID) or {}) do
            -- Values of 1 and below mean an empty or ignored slot
            if type(location) == "number" and location > 1 then
                local data = EquipmentManager_GetLocationData(location)
                if data and data.isBags then lookup[SlotKey(data.bag, data.slot)] = true end
            end
        end
    end
    return lookup
end

-- ============================================================
-- Machine
-- ============================================================
-- Returns key -> machine slot index and the number of items in the machine
local function GetMachineLookup()
    local lookup, count = {}, 0
    for index = 0, MACHINE_SLOTS - 1 do
        local location = C_ScrappingMachineUI.GetCurrentPendingScrapItemLocationByIndex(index)
        if location then
            local bag, slot = location:GetBagAndSlot()
            lookup[SlotKey(bag, slot)] = index
            count = count + 1
        end
    end
    return lookup, count
end

local function ToggleInMachine(item)
    local lookup = GetMachineLookup()
    local index = lookup[SlotKey(item.bag, item.slot)]
    if index then
        C_ScrappingMachineUI.RemoveItemToScrap(index)
    else
        C_Container.UseContainerItem(item.bag, item.slot)
    end
end

-- ============================================================
-- Bag scan
-- ============================================================
local function GetItemLevel(item, link)
    local location = ItemLocation:CreateFromBagAndSlot(item.bag, item.slot)
    local level = C_Item.GetCurrentItemLevel(location)
    if level and level > 0 then return level end
    return C_Item.GetDetailedItemLevelInfo(link) or 0
end

local function SortItems(a, b)
    if a.itemLevel ~= b.itemLevel then return a.itemLevel < b.itemLevel end
    if a.name ~= b.name then return a.name < b.name end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end

local function ScanBags()
    local items = {}
    local setLookup = GetDB().skipEquipmentSets and BuildEquipmentSetLookup() or {}

    for bag = 0, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and IsScrappable(info.itemID)
            and not setLookup[SlotKey(bag, slot)] then
                local item = {
                    bag     = bag,
                    slot    = slot,
                    itemID  = info.itemID,
                    icon    = info.iconFileID,
                    quality = info.quality or 1,
                    name    = C_Item.GetItemNameByID(info.itemID) or "",
                }
                item.itemLevel = GetItemLevel(item, info.hyperlink)
                items[#items + 1] = item
            end
        end
    end

    table.sort(items, SortItems)
    allItems = items
end

local function ApplySearch()
    visibleItems = {}
    for _, item in ipairs(allItems) do
        if searchText == "" or item.name:lower():find(searchText, 1, true) then
            visibleItems[#visibleItems + 1] = item
        end
    end
end

-- ============================================================
-- Fill
-- ============================================================
local function StepFill(token)
    if token ~= fillToken then return end
    local item = table.remove(fillQueue, 1)
    if not item then return end
    C_Container.UseContainerItem(item.bag, item.slot)
    C_Timer.After(FILL_STEP_DELAY, function() StepFill(token) end)
end

local function StopFill()
    fillToken = fillToken + 1
    fillQueue = {}
    refillPending = false
end

local RefreshList

local function FillMachine()
    RefreshList()
    local ignored = GetDB().ignored or {}
    local lookup, count = GetMachineLookup()

    fillQueue = {}
    for _, item in ipairs(visibleItems) do
        if count + #fillQueue >= MACHINE_SLOTS then break end
        if not ignored[item.itemID] and not lookup[SlotKey(item.bag, item.slot)] then
            fillQueue[#fillQueue + 1] = item
        end
    end

    fillToken = fillToken + 1
    StepFill(fillToken)
end

local function TryRefill()
    if not refillPending then return end
    local _, count = GetMachineLookup()
    if count > 0 then return end
    refillPending = false
    if GetDB().autoRefill then FillMachine() end
end

-- ============================================================
-- Panel theme
-- ============================================================
local function ApplyTheme()
    local colors = AklimeMod_RowColors
    local bg     = (colors and colors.bg)     or AklimeMod_Theme.rowBg
    local border = (colors and colors.border) or AklimeMod_Theme.rowBorder
    panel:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    panel:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    local accent = AklimeMod_Theme.accent
    panel.title:SetTextColor(accent.r, accent.g, accent.b, accent.a)
end

-- ============================================================
-- Item buttons
-- ============================================================
local function ShowItemTooltip(button)
    local item = button.item
    if not item then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(item.bag, item.slot)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["es_hint_click"] or "Left click: add or remove",
        HINT_COLOR.r, HINT_COLOR.g, HINT_COLOR.b)
    GameTooltip:AddLine(L["es_hint_ignore"] or "Right click: ignore or stop ignoring",
        HINT_COLOR.r, HINT_COLOR.g, HINT_COLOR.b)
    GameTooltip:Show()
end

local function OnItemClick(button, mouseButton)
    local item = button.item
    if not item then return end
    if mouseButton == "RightButton" then
        local db = GetDB()
        if not db.ignored then return end
        db.ignored[item.itemID] = (not db.ignored[item.itemID]) or nil
        M:UpdateList()
    else
        ToggleInMachine(item)
    end
end

local function CreateItemButton()
    local button = CreateFrame("Button", nil, content, "BackdropTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetBackdrop(BUTTON_BACKDROP)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
    button.icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.tint = button:CreateTexture(nil, "OVERLAY")
    button.tint:SetAllPoints(button.icon)
    button.tint:SetColorTexture(IN_MACHINE_TINT.r, IN_MACHINE_TINT.g, IN_MACHINE_TINT.b, IN_MACHINE_TINT.a)
    button.tint:Hide()

    button.level = button:CreateFontString(nil, "OVERLAY")
    button.level:SetFont(BADGE_FONT, BADGE_FONT_SIZE, "OUTLINE")
    button.level:SetPoint("BOTTOMRIGHT", -2, 2)

    button:SetHighlightTexture("Interface\\BUTTONS\\ButtonHilight-Square", "ADD")
    button:SetScript("OnClick", OnItemClick)
    button:SetScript("OnEnter", ShowItemTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function UpdateItemButton(button, item, inMachine, ignored)
    ignored = ignored == true
    button.item = item
    button.icon:SetTexture(item.icon)
    button.icon:SetDesaturated(ignored)
    button:SetAlpha(ignored and IGNORED_ALPHA or 1)
    button.tint:SetShown(inMachine)

    local r, g, b, hex = C_Item.GetItemQualityColor(item.quality)
    button:SetBackdropBorderColor(r, g, b, 1)
    button.level:SetText(hex and ("|c" .. hex .. item.itemLevel .. "|r") or tostring(item.itemLevel))
    button:Show()
end

-- ============================================================
-- List
-- ============================================================
local function LayoutList()
    local lookup, machineCount = GetMachineLookup()
    local ignored = GetDB().ignored or {}
    local width = content:GetWidth()
    local columns = math.max(1, math.floor((width + BUTTON_GAP) / (BUTTON_SIZE + BUTTON_GAP)))

    for index, item in ipairs(visibleItems) do
        local button = itemButtons[index]
        if not button then
            button = CreateItemButton()
            itemButtons[index] = button
        end
        local column = (index - 1) % columns
        local row    = math.floor((index - 1) / columns)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", content, "TOPLEFT",
            column * (BUTTON_SIZE + BUTTON_GAP), -row * (BUTTON_SIZE + BUTTON_GAP))
        UpdateItemButton(button, item, lookup[SlotKey(item.bag, item.slot)] ~= nil, ignored[item.itemID])
    end
    for index = #visibleItems + 1, #itemButtons do
        itemButtons[index].item = nil
        itemButtons[index]:Hide()
    end

    local rows = math.ceil(#visibleItems / columns)
    content:SetHeight(math.max(1, rows * (BUTTON_SIZE + BUTTON_GAP)))
    emptyText:SetShown(#visibleItems == 0)
    countText:SetText(string.format(
        L["es_count"] or "%d items (%d/%d)",
        #visibleItems, machineCount, MACHINE_SLOTS))
end

-- Rescans the bags and redraws the list
RefreshList = function()
    if not panel or not panel:IsShown() then return end
    ScanBags()
    ApplySearch()
    LayoutList()
end

local function QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(REFRESH_DEBOUNCE, function()
        refreshQueued = false
        RefreshList()
    end)
end

-- Redraws without a new bag scan, used when only the machine or the ignore list changed
function M:UpdateList()
    if panel and panel:IsShown() then LayoutList() end
end

-- ============================================================
-- Panel
-- ============================================================
local function CreateFooterButton(label, anchor, offsetX)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(FOOTER_BUTTON_WIDTH, FOOTER_BUTTON_HEIGHT)
    button:SetPoint(anchor, panel, anchor, offsetX, (FOOTER_HEIGHT - FOOTER_BUTTON_HEIGHT) / 2 - PANEL_PAD / 2)
    button:SetText(label)
    return button
end

local function CreateSearchBox()
    searchBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    searchBox:SetHeight(SEARCH_HEIGHT)
    searchBox:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PAD + 6, -SEARCH_TOP)
    searchBox:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PANEL_PAD - 2, -SEARCH_TOP)
    searchBox:SetAutoFocus(false)

    searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    searchHint:SetPoint("LEFT", 2, 0)
    searchHint:SetText(L["es_search"] or "Search...")

    searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText():lower()
        searchHint:SetShown(searchText == "")
        ApplySearch()
        LayoutList()
    end)
    searchBox:SetScript("OnEscapePressed", searchBox.ClearFocus)
    searchBox:SetScript("OnEnterPressed", searchBox.ClearFocus)
end

local function BuildPanel()
    if panel then return end

    panel = CreateFrame("Frame", "AklimeMod_EasyScrapPanel", ScrappingMachineFrame, "BackdropTemplate")
    panel:SetPoint("TOP", ScrappingMachineFrame, "BOTTOM", 0, -PANEL_GAP)
    panel:SetSize(ScrappingMachineFrame:GetWidth(), PANEL_HEIGHT)
    panel:SetBackdrop(PANEL_BACKDROP)

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOP", 0, -TITLE_TOP)
    panel.title:SetText(L["mod_easy_scrap"] or "Easier Scrap")

    CreateSearchBox()

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PAD, -LIST_TOP)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PANEL_PAD - SCROLLBAR_SPACE, FOOTER_HEIGHT + PANEL_PAD / 2)

    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(panel:GetWidth() - 2 * PANEL_PAD - SCROLLBAR_SPACE)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", scroll, "CENTER")
    emptyText:SetWidth(content:GetWidth())
    emptyText:SetJustifyH("CENTER")
    emptyText:SetText(L["es_empty"] or "No scrappable items in your bags")

    local fillButton = CreateFooterButton(L["es_fill"] or "Fill", "BOTTOMLEFT", PANEL_PAD)
    fillButton:SetScript("OnClick", FillMachine)

    local clearButton = CreateFooterButton(L["es_clear"] or "Clear", "BOTTOMLEFT", PANEL_PAD + FOOTER_BUTTON_WIDTH + BUTTON_GAP)
    clearButton:SetScript("OnClick", function()
        StopFill()
        C_ScrappingMachineUI.RemoveAllScrapItems()
    end)

    countText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")

local function RegisterRuntimeEvents()
    eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:RegisterEvent("SCRAPPING_MACHINE_PENDING_ITEM_CHANGED")
    eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

local function UnregisterRuntimeEvents()
    eventFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:UnregisterEvent("SCRAPPING_MACHINE_PENDING_ITEM_CHANGED")
    eventFrame:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
    eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

local function OnMachineShow()
    if not GetDB().enabled then return end
    BuildPanel()
    panel:Show()
    ApplyTheme()
    RegisterRuntimeEvents()
    RefreshList()
end

local function OnMachineHide()
    StopFill()
    UnregisterRuntimeEvents()
    if panel then panel:Hide() end
end

local function OnScrapCastSucceeded(spellID)
    -- The client hides spell ids in restricted situations
    if issecretvalue and issecretvalue(spellID) then return end
    if spellID ~= C_ScrappingMachineUI.GetScrapSpellID() then return end
    if not GetDB().autoRefill then return end
    refillPending = true
    C_Timer.After(REFILL_FALLBACK, TryRefill)
end

local function OnItemDataLoaded(itemID, success)
    if not pendingLoads[itemID] then return end
    pendingLoads[itemID] = nil
    -- A failed load would be requested again forever, so it counts as not scrappable
    if not success then scrappableCache[itemID] = false end
    QueueRefresh()
end

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
    if event == "BAG_UPDATE_DELAYED" then
        RefreshList()
        TryRefill()
    elseif event == "SCRAPPING_MACHINE_PENDING_ITEM_CHANGED" then
        M:UpdateList()
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        OnItemDataLoaded(arg1, arg2)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnScrapCastSucceeded(arg3)
    end
end)

-- ============================================================
-- Setup
-- ============================================================
-- The machine window is load on demand, so the hooks wait until it exists
local function Setup()
    if setupDone or not ScrappingMachineFrame then return end
    setupDone = true
    ScrappingMachineFrame:HookScript("OnShow", OnMachineShow)
    ScrappingMachineFrame:HookScript("OnHide", OnMachineHide)
    if ScrappingMachineFrame:IsShown() then OnMachineShow() end
end

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == MACHINE_ADDON then
        Setup()
    elseif addonName == "AklimeModTools" and C_AddOns.IsAddOnLoaded(MACHINE_ADDON) then
        Setup()
    end
end)

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled()
    return GetDB().enabled == true
end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    if v then
        if ScrappingMachineFrame and ScrappingMachineFrame:IsShown() then OnMachineShow() end
    else
        OnMachineHide()
    end
end

function M:IsSkipEquipmentSets()
    return GetDB().skipEquipmentSets == true
end

function M:SetSkipEquipmentSets(v)
    GetDB().skipEquipmentSets = v and true or false
    RefreshList()
end

function M:IsAutoRefill()
    return GetDB().autoRefill == true
end

function M:SetAutoRefill(v)
    GetDB().autoRefill = v and true or false
end
