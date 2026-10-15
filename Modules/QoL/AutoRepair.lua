-- Modules/QoL/AutoRepair.lua

local L = AklimeModL

-- The global GetCoinTextureString was removed, the function lives in C_CurrencyInfo now
local function FormatCost(copper)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    end
    return GetCoinTextureString(copper)
end

local repairFrame = CreateFrame("Frame")
repairFrame:RegisterEvent("MERCHANT_SHOW")
repairFrame:SetScript("OnEvent", function()
    if not AklimeModDB or not AklimeModDB.autoRepair.enabled then return end
    if not CanMerchantRepair() then return end

    local cost = GetRepairAllCost()
    if not cost or cost == 0 then return end

    if AklimeModDB.autoRepair.useGuild then
        local gw = GetGuildBankWithdrawMoney()
        if IsInGuild() and gw and (gw == -1 or gw >= cost) then
            RepairAllItems(1)
            print("|cFF00CCFFAklime Mod Tools:|r " .. L["msg_repair_guild"] .. FormatCost(cost))
            return
        end
    end

    if AklimeModDB.autoRepair.useGold then
        if GetMoney() >= cost then
            RepairAllItems()
            print("|cFF00CCFFAklime Mod Tools:|r " .. L["msg_repair_gold"] .. FormatCost(cost))
        else
            print("|cFFFF4444Aklime Mod Tools:|r " .. L["msg_repair_no_gold"])
        end
    end
end)
