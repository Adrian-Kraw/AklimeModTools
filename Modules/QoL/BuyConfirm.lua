-- Modules/QoL/BuyConfirm.lua
-- Automatically accept purchase confirmation dialogs.

local M = {}
AklimeMod_BuyConfirm = M

local function GetDB()
    if AklimeModDB and AklimeModDB.buyConfirm then return AklimeModDB.buyConfirm end
    return {}
end

local AUTO_CONFIRM = {
    CONFIRM_PURCHASE_TOKEN_ITEM         = true,
    CONFIRM_PURCHASE_NONREFUNDABLE_ITEM = true,
    CONFIRM_HIGH_COST_ITEM              = true,  -- expensive purchase ("for the following amount")
}

-- Resale/refund of refundable items (separate hook)
local REFUND_CONFIRM = {
    CONFIRM_REFUND_TOKEN_ITEM = true,
}

-- Warning that an action ends an item's refund window. Several different
-- dialogs share the same END_REFUND text, one per action.
local NO_REFUND_CONFIRM = {
    EQUIP_BIND_REFUNDABLE          = true,  -- equipping
    -- Using is left out on purpose. Its OnAccept calls the protected
    -- C_Item.ConfirmNoRefundOnUse, which Blizzard blocks for addon code.
    REFUNDABLE_SOCKET              = true,  -- socketing
    CONFIRM_MAIL_ITEM_UNREFUNDABLE = true,  -- sending by mail
}

local ADDON_NAME = "AklimeModTools"

-- Blizzard blocks the confirmation when it rates the call path as unsafe.
-- The event fires during the call, so this flag tells us whether it went through.
local wasBlocked = false
local blockWatcher = CreateFrame("Frame")
blockWatcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
blockWatcher:SetScript("OnEvent", function(_, _, addon)
    if addon == ADDON_NAME then wasBlocked = true end
end)

local function TryAccept(popup, idx, which)
    if not popup:IsShown() or popup.which ~= which then return end

    -- Call the dialog's OnAccept directly (internally identical to a Button1 click).
    local dialog = StaticPopupDialogs and StaticPopupDialogs[which]
    if dialog and dialog.OnAccept then
        wasBlocked = false
        dialog.OnAccept(popup, popup.data, popup.data2)
        -- Keep the dialog open when the call was blocked. Otherwise it
        -- closes and the action is lost without the player noticing.
        if not wasBlocked then StaticPopup_Hide(which) end
        return
    end

    -- Fallback: click Button1.
    local btn = popup.button1 or _G["StaticPopup" .. idx .. "Button1"]
    if btn and btn:IsEnabled() then
        btn:Click()
    end
end

local hooked = false
local function Setup()
    if hooked then return end
    hooked = true

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup then
            local idx = i
            -- HookScript("OnShow") instead of hooksecurefunc(popup, "Show", ...).
            -- Fires at the widget level regardless of how the frame becomes visible.
            popup:HookScript("OnShow", function(self)
                if not self.which then return end
                local db = GetDB()
                local active = (AUTO_CONFIRM[self.which] and db.enabled)
                    or (REFUND_CONFIRM[self.which] and db.refundEnabled)
                    or (NO_REFUND_CONFIRM[self.which] and db.noRefundEnabled)
                if not active then return end
                local which = self.which

                local elapsed = 0
                local ticker
                ticker = C_Timer.NewTicker(0.1, function()
                    elapsed = elapsed + 0.1
                    if elapsed > 10 then ticker:Cancel(); return end
                    if not popup:IsShown() or popup.which ~= which then ticker:Cancel(); return end

                    local btn = popup.button1 or _G["StaticPopup" .. idx .. "Button1"]
                    if btn and btn:IsEnabled() then
                        ticker:Cancel()
                        TryAccept(popup, idx, which)
                    end
                end)
            end)
        end
    end
end

-- Debug: /akmbuydebug
SLASH_AKMBUYDEBUG1 = "/akmbuydebug"
SlashCmdList["AKMBUYDEBUG"] = function()
    local found = false
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() then
            found = true
            local btn2 = _G["StaticPopup" .. i .. "Button1"]
            print(string.format("|cFFFFD100AklimeMod:|r StaticPopup%d which=%s data=%s data2=%s",
                i, tostring(popup.which), tostring(popup.data), tostring(popup.data2)))
            if btn2 then
                print(string.format("  button1: enabled=%s shown=%s",
                    tostring(btn2:IsEnabled()), tostring(btn2:IsShown())))
            end
            local dialog = StaticPopupDialogs and StaticPopupDialogs[popup.which]
            print(string.format("  OnAccept=%s", dialog and tostring(dialog.OnAccept) or "kein Dialog"))
        end
    end
    if not found then
        print("|cFFFFD100AklimeMod:|r Kein StaticPopup offen.")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    Setup()
end)

function M.IsEnabled() return GetDB().enabled == true end
function M.SetEnabled(v) GetDB().enabled = v and true or false end
function M.IsRefundEnabled() return GetDB().refundEnabled == true end
function M.SetRefundEnabled(v) GetDB().refundEnabled = v and true or false end
function M.IsNoRefundEnabled() return GetDB().noRefundEnabled == true end
function M.SetNoRefundEnabled(v) GetDB().noRefundEnabled = v and true or false end
