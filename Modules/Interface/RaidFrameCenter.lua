-- Modules/Interface/RaidFrameCenter.lua
-- Centers raid frames horizontally. The Y position is kept.
-- The MT frame sticks out to the left and is ignored when centering.
--
-- The container is protected, so a plain SetPoint from addon code is refused
-- during combat. For that case a secure snippet does the move: it runs inside
-- the client's own restricted environment, where moving the frame is allowed.
-- Out of combat the normal path is used, it also keeps the values the snippet
-- cannot measure itself up to date.

AklimeMod_Defaults = AklimeMod_Defaults or {}
AklimeMod_Defaults.raidFrameCenter = { enabled = true, offsetX = 0 }

local function GetDB()
    if AklimeModDB and AklimeModDB.raidFrameCenter then return AklimeModDB.raidFrameCenter end
    return AklimeMod_Defaults.raidFrameCenter
end

local function IsInEditMode()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return true end
    if C_EditMode and C_EditMode.IsEditModeActive and C_EditMode.IsEditModeActive() then return true end
    return false
end

local savedY    = nil
local hasModified = false
local lastWidth = 0
local lastMtOffset = 0

-- Puts the container back where Edit Mode placed it. These are the same points
-- EditModeSystemMixin:ApplySystemAnchor sets. That function is not called
-- because it also runs Edit Mode's action bar layout, which addon code would
-- taint. The container is no managed frame, so the points are the whole job.
-- Moving it is protected in combat, PLAYER_REGEN_ENABLED finishes a pending
-- request.
local restorePending = false

local function RestorePosition()
    local c      = CompactRaidFrameContainer
    local info   = c and c.systemInfo
    local anchor = info and info.anchorInfo
    if not anchor then return end
    -- Edit Mode positions the frame itself while it is open
    if IsInEditMode() then return end
    if InCombatLockdown() then
        restorePending = true
        return
    end
    restorePending = false

    local scale = c:GetScale()
    c:ClearAllPoints()
    c:SetPoint(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.offsetX / scale, anchor.offsetY / scale)
    local anchor2 = info.anchorInfo2
    if anchor2 then
        c:SetPoint(anchor2.point, anchor2.relativeTo, anchor2.relativePoint, anchor2.offsetX / scale, anchor2.offsetY / scale)
    end

    -- Measure again from the Edit Mode position when switched on later
    savedY       = nil
    hasModified  = false
    lastWidth    = 0
    lastMtOffset = 0
end

-- ============================================================
-- Secure driver (combat)
-- ============================================================
-- The snippet recomputes the position from the container's own width. Scale,
-- MT offset, Y position and the user offset cannot be measured in the
-- restricted environment, they are handed over as attributes out of combat.
--
-- The state driver is the only way to start the snippet during combat.
-- Setting an attribute from insecure code does not work there, SetAttribute
-- on a secure handler is protected in combat.
local driver = nil

local UPDATE_SNIPPET = [[
    local c = self:GetFrameRef("container")
    local p = self:GetFrameRef("uiparent")
    if not c or not p then return end

    -- Never guess the Y position. Without it the frame would jump to the top
    -- edge of the screen.
    local y = self:GetAttribute("posY")
    if not y then return end

    local width = (c:GetWidth() or 0) * (self:GetAttribute("scale") or 1)
    if width <= 0 then return end

    local mt = self:GetAttribute("mtOffset") or 0
    local x  = (p:GetWidth() - (width - mt)) / 2 + (self:GetAttribute("offsetX") or 0) - mt

    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
]]

local function EnsureDriver()
    if driver then return driver end
    if InCombatLockdown() then return nil end

    local c = CompactRaidFrameContainer
    if not c then return nil end

    driver = CreateFrame("Frame", "AklimeMod_RaidCenterDriver", UIParent, "SecureHandlerStateTemplate")
    driver:SetFrameRef("container", c)
    driver:SetFrameRef("uiparent", UIParent)
    driver:SetAttribute("updatePosition", UPDATE_SNIPPET)
    driver:SetAttribute("_onstate-akmraid", [[ self:RunAttribute("updatePosition") ]])

    return driver
end

local driverArmed = false

local function UpdateDriverValues(scale, mtOffset)
    local d = EnsureDriver()
    if not d then return end
    d:SetAttribute("scale",    scale)
    d:SetAttribute("mtOffset", mtOffset)
    d:SetAttribute("offsetX",  GetDB().offsetX or 0)
    d:SetAttribute("posY",     savedY)

    -- Register only once the snippet has everything it needs. Registering
    -- evaluates the condition right away and runs the snippet immediately,
    -- so doing it earlier would move the container with unknown values.
    if not driverArmed and savedY then
        driverArmed = true
        -- One state per group count. The value is never read, it only has to
        -- change so the snippet runs when a group appears or disappears.
        RegisterStateDriver(d, "akmraid",
            "[@raid36,exists] 8; [@raid31,exists] 7; [@raid26,exists] 6; [@raid21,exists] 5; " ..
            "[@raid16,exists] 4; [@raid11,exists] 3; [@raid6,exists] 2; [@raid1,exists] 1; 0")
    end
end

-- The snippet does not know the toggle. Once armed, the driver kept centering
-- on every group change after the feature was switched off. Unregistering is
-- protected in combat, PLAYER_REGEN_ENABLED finishes a pending request.
local disarmPending = false

local function DisarmDriver()
    if not driver or not driverArmed then
        disarmPending = false
        return
    end
    if InCombatLockdown() then
        disarmPending = true
        return
    end
    UnregisterStateDriver(driver, "akmraid")
    driverArmed   = false
    disarmPending = false
end

local function RepositionContainer()
    if IsInEditMode() then return end
    if not GetDB().enabled then return end

    local c = CompactRaidFrameContainer
    if not c or not c:IsShown() then return end

    -- CompactRaidFrameContainer:IsProtected() is true, verified in game via
    -- /akmraid. A SetPoint from here is refused during combat, the state
    -- driver and its snippet take over for that.
    if InCombatLockdown() then return end

    if savedY == nil then
        local _, _, _, _, y = c:GetPoint(1)
        savedY = y or (c:GetTop() - GetScreenHeight())
    end
    if savedY == nil then return end

    if not IsInRaid() then
        hasModified  = false
        lastWidth    = 0
        lastMtOffset = 0
        return
    end

    -- The container resizes itself to its content, so its own width is the
    -- truth. Counting groups and multiplying by one group width ignored the
    -- frame size set in Edit Mode and fell back to a guessed 220 whenever the
    -- group frames were not found.
    --
    -- GetWidth and GetLeft are in the frame's own coordinate space. The anchor
    -- offset below is in UIParent units, so everything is converted.
    local scale = c:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width = (c:GetWidth() or 0) * scale
    if width <= 0 then return end

    -- The MT frames stick out to the left and are not part of the centering
    local mtOffset = 0
    local g1 = _G["CompactRaidGroup1"]
    if g1 and g1:IsShown() and g1:GetLeft() and c:GetLeft() then
        local off = (g1:GetLeft() - c:GetLeft()) * scale
        if off > 10 then mtOffset = off end
    end

    -- Only reposition when the width OR the MT offset has changed
    if width == lastWidth and mtOffset == lastMtOffset and hasModified then return end
    lastWidth    = width
    lastMtOffset = mtOffset

    local groupsWidth = width - mtOffset
    local groupsX     = (UIParent:GetWidth() - groupsWidth) / 2 + (GetDB().offsetX or 0)
    local targetX     = groupsX - mtOffset

    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", UIParent, "TOPLEFT", targetX, savedY)
    hasModified = true

    -- Keep the snippet supplied for the next fight
    UpdateDriverValues(scale, mtOffset)
end

local pendingTimer = nil
local function RequestReposition()
    if IsInEditMode() then return end
    if pendingTimer then pendingTimer:Cancel(); pendingTimer = nil end
    pendingTimer = C_Timer.NewTimer(0.4, function()
        pendingTimer = nil
        RepositionContainer()
    end)
end

-- Roster events alone are not enough when a party turns into a raid: the
-- container is still hidden or its groups are not laid out yet when the single
-- debounced attempt runs, and nothing tries again afterwards. Reacting to the
-- frame itself covers both, it appears and it resizes once the groups are in.
local containerHooked = false

local function HookContainer()
    if containerHooked then return end
    local c = CompactRaidFrameContainer
    if not c then return end
    containerHooked = true

    c:HookScript("OnShow", function()
        -- The container was hidden, so the cached layout tells us nothing
        hasModified  = false
        lastWidth    = 0
        lastMtOffset = 0
        RequestReposition()
    end)

    -- This runs inside Blizzard's layout call. Nothing protected may be
    -- touched here, the timer inside RequestReposition keeps it out of that
    -- call stack, and during combat it exits on its own.
    c:HookScript("OnSizeChanged", function()
        RequestReposition()
    end)
end

local f = CreateFrame("Frame", "AklimeMod_RaidFrameCenter")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_ROLES_ASSIGNED")
f:RegisterEvent("RAID_ROSTER_UPDATE")

f:SetScript("OnEvent", function(_, event)
    if IsInEditMode() then return end

    if event == "PLAYER_ENTERING_WORLD" then
        HookContainer()
        C_Timer.After(2.0, function()
            if IsInEditMode() then return end
            HookContainer()
            savedY       = nil
            hasModified  = false
            lastWidth    = 0
            lastMtOffset = 0
            RepositionContainer()
        end)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Finish a switch off that happened during combat
        if not GetDB().enabled then
            if disarmPending  then DisarmDriver()    end
            if restorePending then RestorePosition() end
        end
        disarmPending  = false
        restorePending = false
        C_Timer.After(0.2, RepositionContainer)
        return
    end

    if IsInRaid() then
        RequestReposition()
    end
end)

if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        C_Timer.After(0.5, function()
            savedY       = nil
            hasModified  = false
            lastWidth    = 0
            lastMtOffset = 0
            RepositionContainer()
        end)
    end)
end

-- Debug: /akmraid
SLASH_AKMRAID1 = "/akmraid"
SlashCmdList["AKMRAID"] = function()
    local c = CompactRaidFrameContainer
    if not c then
        print("|cFFFF4444Aklime Mod Tools:|r kein CompactRaidFrameContainer.")
        return
    end
    local scale = c:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width = (c:GetWidth() or 0) * scale
    local left  = (c:GetLeft() or 0) * scale
    print(string.format(
        "|cFFFFD100Aklime Mod Tools Raid:|r aktiv=%s sichtbar=%s schlachtzug=%s",
        tostring(GetDB().enabled), tostring(c:IsShown()), tostring(IsInRaid())))
    print(string.format(
        "  Kampf=%s  geschuetzt=%s  Secure-Treiber=%s",
        tostring(InCombatLockdown()), tostring(c:IsProtected()),
        driver and (driverArmed and "aktiv" or "abgemeldet") or "fehlt"))
    if driver then
        print(string.format(
            "  Treiberwerte: skalierung=%s mt=%s versatz=%s y=%s",
            tostring(driver:GetAttribute("scale")),   tostring(driver:GetAttribute("mtOffset")),
            tostring(driver:GetAttribute("offsetX")), tostring(driver:GetAttribute("posY"))))
    end
    print(string.format(
        "  Breite=%.1f  links=%.1f  Bildschirm=%.1f  MT=%.1f  Skalierung=%.3f",
        width, left, UIParent:GetWidth(), lastMtOffset, scale))
    print(string.format(
        "  Mitte Rahmen=%.1f  Mitte Bildschirm=%.1f  Versatz=%d  gesetzt=%s",
        left + width / 2, UIParent:GetWidth() / 2, GetDB().offsetX or 0, tostring(hasModified)))
end

AklimeMod_RaidFrameCenter = {
    IsEnabled  = function() return GetDB().enabled end,
    SetEnabled = function(v)
        GetDB().enabled = v
        if v then
            RepositionContainer()
        else
            DisarmDriver()
            RestorePosition()
        end
    end,
    SetOffsetX = function(x) GetDB().offsetX = x; lastWidth = 0; RepositionContainer() end,
    GetOffsetX = function() return GetDB().offsetX or 0 end,
    Update     = function() lastWidth = 0; lastMtOffset = 0; hasModified = false; RepositionContainer() end,
}

-- Hook SetMainTank/ClearMainTank directly
if SetMainTank then
    hooksecurefunc("SetMainTank", function() RequestReposition() end)
end
if ClearMainTank then
    hooksecurefunc("ClearMainTank", function() RequestReposition() end)
end

C_Timer.After(3.0, function()
    if IsInEditMode() then return end
    HookContainer()
    RepositionContainer()
end)