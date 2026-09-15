-- Modules/Interface/ActionBarCompact.lua
-- Closes the gaps that empty slots leave on action bars 1 to 8. Each bar is
-- aligned on its own to the left, the center or the right. Every row of a bar
-- is compressed separately. The bar keeps its size and position.
--
-- With "Always Show Buttons" off Blizzard hides an empty button but keeps its
-- container as a spacer. That spacer is the gap. Only the buttons move here,
-- the containers stay where Edit Mode put them. Every button stays anchored to
-- its own container and only gets an offset, so offset 0 is always the
-- original layout. Actions stay in their slots, key bindings do not change.
--
-- Action buttons are protected. All moves run in one secure snippet. Out of
-- combat it is started with SecureHandlerExecute. In combat a state driver
-- starts it whenever the main bar pages (forms, stealth, vehicles). A small
-- secure watcher on every button starts it when Blizzard shows or hides that
-- button. That covers dragging and dropping actions in combat, where the grid
-- appears and disappears. Positions and slot orders cannot be measured in the
-- restricted environment, they are handed over as attributes out of combat.

local BUTTONS_PER_BAR = 12
local RELAYOUT_DELAY  = 0.05
local EDIT_MODE_EXIT_DELAY = 0.5
local STATE_NAME      = "akmbars"

local MODE_OFF    = "off"
local MODE_LEFT   = "left"
local MODE_CENTER = "center"
local MODE_RIGHT  = "right"
local MODES = { MODE_OFF, MODE_LEFT, MODE_CENTER, MODE_RIGHT }

-- Share of the free slots placed before the first button
local ALIGN_FACTOR = {
    [MODE_LEFT]   = 0,
    [MODE_CENTER] = 0.5,
    [MODE_RIGHT]  = 1,
}

-- Same order as the bar numbers in Edit Mode
local BARS = {
    { frame = "MainActionBar",       prefix = "ActionButton"              },
    { frame = "MultiBarBottomLeft",  prefix = "MultiBarBottomLeftButton"  },
    { frame = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton" },
    { frame = "MultiBarRight",       prefix = "MultiBarRightButton"       },
    { frame = "MultiBarLeft",        prefix = "MultiBarLeftButton"        },
    { frame = "MultiBar5",           prefix = "MultiBar5Button"           },
    { frame = "MultiBar6",           prefix = "MultiBar6Button"           },
    { frame = "MultiBar7",           prefix = "MultiBar7Button"           },
}

-- One value per page source. The value is never read. It only has to change
-- so the snippet runs when the main bar pages.
local PAGE_STATES = "[vehicleui] vehicle; [overridebar] override; [possessbar] possess; [shapeshift] shapeshift; "
    .. "[bonusbar:5] bonus5; [bonusbar:4] bonus4; [bonusbar:3] bonus3; [bonusbar:2] bonus2; [bonusbar:1] bonus1; "
    .. "[actionbar:2] page2; [actionbar:3] page3; [actionbar:4] page4; [actionbar:5] page5; [actionbar:6] page6; page1"

local function GetDB()
    if AklimeModDB and AklimeModDB.actionBarCompact then return AklimeModDB.actionBarCompact end
    return {}
end

local function IsInEditMode()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return true end
    if C_EditMode and C_EditMode.IsEditModeActive and C_EditMode.IsEditModeActive() then return true end
    return false
end

-- ============================================================
-- Secure snippet
-- ============================================================
-- Lays out one bar, the bar number comes in as argument
local LAYOUT_BAR_SNIPPET = [[
    local n = ...
    -- Never guess. Until the values from out of combat are there, nothing moves.
    if not n or not self:GetAttribute("measured") then return end
    local bar    = "b" .. n
    local perBar = self:GetAttribute("buttonsPerBar")

    -- Same page lookup as Blizzard's CalculateAction. Bars 2 to 8 carry a
    -- fixed page, only the main bar follows forms, stealth and vehicles.
    local page = self:GetAttribute(bar .. "page")
    if not page then
        page = GetActionBarPage()
        if HasVehicleActionBar() then
            page = GetVehicleBarIndex()
        elseif HasOverrideActionBar() then
            page = GetOverrideBarIndex()
        elseif HasTempShapeshiftActionBar() then
            page = GetTempShapeshiftBarIndex()
        elseif HasBonusActionBar() and GetActionBarPage() == 1 then
            page = GetBonusBarIndex()
        end
    end
    self:SetAttribute(bar .. "curpage", page)

    -- "Always Show Buttons" or a dragged action shows the grid. The gaps
    -- are wanted then, so the bar keeps its original layout.
    local align = self:GetAttribute(bar .. "align")
    for i = 1, perBar do
        local btn = self:GetFrameRef(bar .. "btn" .. i)
        if btn and (btn:GetAttribute("showgrid") or 0) > 0 then align = nil end
    end

    if align or self:GetAttribute(bar .. "applied") then
        for i = 1, perBar do
            local btn = self:GetFrameRef(bar .. "btn" .. i)
            if btn then
                btn:ClearAllPoints()
                btn:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
            end
        end
        self:SetAttribute(bar .. "applied", nil)
    end

    if not align then return end

    for r = 1, self:GetAttribute(bar .. "lines") or 0 do
        local line  = bar .. "l" .. r
        local slots = self:GetAttribute(line .. "n") or 0
        local dx    = self:GetAttribute(line .. "dx") or 0
        local dy    = self:GetAttribute(line .. "dy") or 0

        local filled = 0
        for j = 1, slots do
            local i   = self:GetAttribute(line .. "s" .. j)
            local btn = self:GetFrameRef(bar .. "btn" .. i)
            if btn and not btn:GetAttribute("statehidden") and HasAction(i + (page - 1) * perBar) then
                filled = filled + 1
            end
        end

        -- The offset is the distance from the button's own slot to its
        -- target slot, measured in slot steps of this row
        local target = (slots - filled) * align
        for j = 1, slots do
            local i   = self:GetAttribute(line .. "s" .. j)
            local btn = self:GetFrameRef(bar .. "btn" .. i)
            if btn and not btn:GetAttribute("statehidden") and HasAction(i + (page - 1) * perBar) then
                local shift = target - (j - 1)
                btn:ClearAllPoints()
                btn:SetPoint("CENTER", "$parent", "CENTER", shift * dx, shift * dy)
                target = target + 1
            end
        end
    end
    self:SetAttribute(bar .. "applied", true)
]]

local LAYOUT_ALL_SNIPPET = [[
    for n = 1, self:GetAttribute("numBars") do
        self:RunAttribute("layoutBar", n)
    end
]]

-- Runs on a button watcher. The layout itself runs in the driver's environment.
local WATCH_SNIPPET = [[
    local d = self:GetFrameRef("driver")
    if d then d:RunAttribute("layoutBar", self:GetAttribute("barIndex")) end
]]

local driver      = nil
local driverArmed = false

-- A child frame follows the visibility of its button. Its show and hide
-- snippets therefore run in combat whenever Blizzard shows or hides the button.
local function CreateWatcher(btn, barIndex)
    local watcher = CreateFrame("Frame", nil, btn, "SecureHandlerShowHideTemplate")
    watcher:SetFrameRef("driver", driver)
    watcher:SetAttribute("barIndex", barIndex)
    watcher:SetAttribute("_onshow", WATCH_SNIPPET)
    watcher:SetAttribute("_onhide", WATCH_SNIPPET)
end

local function EnsureDriver()
    if driver then return driver end
    if InCombatLockdown() then return nil end

    driver = CreateFrame("Frame", "AklimeMod_ActionBarCompactDriver", UIParent, "SecureHandlerStateTemplate")
    driver:SetAttribute("numBars", #BARS)
    driver:SetAttribute("buttonsPerBar", BUTTONS_PER_BAR)
    driver:SetAttribute("layoutBar", LAYOUT_BAR_SNIPPET)
    driver:SetAttribute("layout", LAYOUT_ALL_SNIPPET)
    driver:SetAttribute("_onstate-" .. STATE_NAME, [[ self:RunAttribute("layout") ]])
    for n, def in ipairs(BARS) do
        for i = 1, BUTTONS_PER_BAR do
            local btn = _G[def.prefix .. i]
            if btn then
                driver:SetFrameRef("b" .. n .. "btn" .. i, btn)
                CreateWatcher(btn, n)
            end
        end
    end

    return driver
end

-- ============================================================
-- Measuring (out of combat)
-- ============================================================
local function GetAlign(barIndex)
    local db = GetDB()
    if not db.enabled or IsInEditMode() then return nil end
    return ALIGN_FACTOR[db["bar" .. barIndex]]
end

-- Groups the shown containers of a bar into rows. A vertical bar lays its rows
-- out as columns, there left means top.
local function CollectLines(def, horizontal)
    local lines, byKey = {}, {}
    for i = 1, BUTTONS_PER_BAR do
        local btn = _G[def.prefix .. i]
        local con = btn and btn.container
        local x, y
        if con and con:IsShown() then x, y = con:GetCenter() end
        if x and y then
            local key = math.floor((horizontal and y or x) + 0.5)
            local line = byKey[key]
            if not line then
                line = {}
                byKey[key] = line
                lines[#lines + 1] = line
            end
            -- Offsets are applied in the button's scale, centers come in the container's
            line[#line + 1] = { index = i, x = x, y = y, scale = con:GetEffectiveScale() / btn:GetEffectiveScale() }
        end
    end

    for _, line in ipairs(lines) do
        table.sort(line, function(a, b)
            if horizontal then return a.x < b.x end
            return a.y > b.y
        end)
    end
    return lines
end

local function WriteLine(d, key, line)
    local first, last = line[1], line[#line]
    local steps = math.max(#line - 1, 1)
    d:SetAttribute(key .. "n",  #line)
    d:SetAttribute(key .. "dx", (last.x - first.x) / steps * first.scale)
    d:SetAttribute(key .. "dy", (last.y - first.y) / steps * first.scale)
    for j, slot in ipairs(line) do
        d:SetAttribute(key .. "s" .. j, slot.index)
    end
end

local function MeasureBar(d, barIndex, def)
    local bar   = _G[def.frame]
    local key   = "b" .. barIndex
    local lines = bar and CollectLines(def, bar.isHorizontal ~= false) or {}

    d:SetAttribute(key .. "page",  bar and bar:GetAttribute("actionpage"))
    d:SetAttribute(key .. "align", GetAlign(barIndex))
    d:SetAttribute(key .. "lines", #lines)
    for r, line in ipairs(lines) do
        WriteLine(d, key .. "l" .. r, line)
    end
end

local function UpdateStateDriver(d)
    local wanted = GetDB().enabled == true
    if wanted and not driverArmed then
        -- Registering runs the snippet right away, so this happens only after
        -- all attributes are written
        RegisterStateDriver(d, STATE_NAME, PAGE_STATES)
        driverArmed = true
    elseif not wanted and driverArmed then
        UnregisterStateDriver(d, STATE_NAME)
        driverArmed = false
    end
end

local function ApplyLayout()
    -- In combat the state driver and the button watchers take over,
    -- PLAYER_REGEN_ENABLED catches up on everything else
    if InCombatLockdown() then return end
    if not driver and not GetDB().enabled then return end

    local d = EnsureDriver()
    if not d then return end

    for barIndex, def in ipairs(BARS) do
        MeasureBar(d, barIndex, def)
    end
    d:SetAttribute("measured", true)
    SecureHandlerExecute(d, [[ self:RunAttribute("layout") ]])
    UpdateStateDriver(d)
end

local pendingTimer = nil

-- The hooks below fire inside Blizzard's layout calls. The timer keeps the
-- secure execution out of that call stack and merges bursts into one pass.
local function RequestLayout()
    if InCombatLockdown() then return end
    if not driver and not GetDB().enabled then return end
    if pendingTimer then return end
    pendingTimer = C_Timer.NewTimer(RELAYOUT_DELAY, function()
        pendingTimer = nil
        ApplyLayout()
    end)
end

-- ============================================================
-- Hooks and events
-- ============================================================
-- UpdateShownButtons runs when a slot changes or the grid shows and hides.
-- UpdateGridLayout runs when Edit Mode changes rows, padding or orientation.
for _, def in ipairs(BARS) do
    local bar = _G[def.frame]
    if bar then
        if bar.UpdateShownButtons then hooksecurefunc(bar, "UpdateShownButtons", RequestLayout) end
        if bar.UpdateGridLayout   then hooksecurefunc(bar, "UpdateGridLayout",   RequestLayout) end
    end
end

if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", RequestLayout)
    -- The Edit Mode frame can still count as shown right after the call.
    -- Measuring then would keep the original layout.
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        C_Timer.After(EDIT_MODE_EXIT_DELAY, RequestLayout)
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", RequestLayout)

-- Debug: /akmbars
SLASH_AKMBARS1 = "/akmbars"
SlashCmdList["AKMBARS"] = function()
    print(string.format(
        "|cFFFFD100Aklime Mod Tools Leisten:|r aktiv=%s kampf=%s bearbeitungsmodus=%s treiber=%s",
        tostring(GetDB().enabled), tostring(InCombatLockdown()), tostring(IsInEditMode()),
        driver and (driverArmed and "aktiv" or "vorhanden") or "fehlt"))
    if not driver then return end

    for barIndex, def in ipairs(BARS) do
        local key  = "b" .. barIndex
        local page = driver:GetAttribute(key .. "curpage")
        -- Compares the page from the snippet with the slot Blizzard uses. Any
        -- difference means the page lookup is wrong for the current state.
        local mismatches = 0
        -- Grid reasons as Blizzard bit flags: 1 Always Show Buttons, 2 dragging, 4 spell collection
        local grid = 0
        for i = 1, BUTTONS_PER_BAR do
            local btn = _G[def.prefix .. i]
            if btn and btn.action and page and btn.action ~= i + (page - 1) * BUTTONS_PER_BAR then
                mismatches = mismatches + 1
            end
            if btn then grid = bit.bor(grid, btn:GetAttribute("showgrid") or 0) end
        end
        print(string.format(
            "  Leiste %d: ausrichtung=%s reihen=%s seite=%s abweichungen=%d gestaucht=%s raster=%d",
            barIndex, tostring(driver:GetAttribute(key .. "align")), tostring(driver:GetAttribute(key .. "lines")),
            tostring(page), mismatches, tostring(driver:GetAttribute(key .. "applied")), grid))
    end
end

-- ============================================================
-- API
-- ============================================================
AklimeMod_ActionBarCompact = {
    NUM_BARS = #BARS,
    MODES    = MODES,
}

function AklimeMod_ActionBarCompact:IsEnabled()
    return GetDB().enabled == true
end

function AklimeMod_ActionBarCompact:SetEnabled(v)
    GetDB().enabled = v and true or false
    RequestLayout()
end

function AklimeMod_ActionBarCompact:GetMode(barIndex)
    return GetDB()["bar" .. barIndex] or MODE_OFF
end

function AklimeMod_ActionBarCompact:SetMode(barIndex, mode)
    GetDB()["bar" .. barIndex] = mode
    RequestLayout()
end
