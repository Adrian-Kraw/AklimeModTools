-- Modules/DataCollector.lua
-- Collects all character data, instance lockouts and currencies on login.
-- Everything is stored under AklimeModDB.tracker in a stable shared structure
-- that the character tracker UI reads from.

-- ============================================================
-- Tracked currency IDs, resolved through C_CurrencyInfo.
-- ============================================================
local CURRENCY_IDS = {
    81, 515, 2588, 3363, 241,
    391, 416,
    402, 697, 738, 752, 776, 777, 789,
    823, 824, 994, 1101, 1129, 1149, 1155, 1166,
    1220, 1226, 1273, 1275, 1299, 1314, 1342, 1501, 1508, 1533,
    1710, 1580, 1560, 1587, 1716, 1717, 1718, 1721, 1719, 1755, 1803,
    1754, 1191, 1602, 1792, 1822, 1767, 1828, 1810, 1813, 1816,
    1819, 1820, 1885, 1906, 1931, 1977, 1979, 2009, 2000,
    2003, 2245, 2123, 2797, 2118, 2122,
    2533, 2594, 2650, 2651, 2777, 2796,
    2706, 2707, 2708, 2709,
    2657, 2912, 2806, 2807, 2809, 2812, 2778,
    3089, 2803, 2815, 3056, 3008, 2813, 2914, 2915, 2916, 2917,
    3100, 3090, 3218, 3220, 3226, 3116, 3107, 3108, 3109, 3110,
    3149, 3278, 3303, 3356, 3269, 3284, 3286, 3288, 3290, 3141,
    3319, 3316, 3376, 3377, 3379, 3385, 3392, 3400, 3373, 3393, 3405,
    3256, 3257, 3258, 3259, 3260, 3261, 3262, 3263, 3264, 3265, 3266,
    3028, 3310, 3212, 3378, 3383, 3341, 3343, 3345, 3347, 3418,
    3442, 3443, 3444, 3445, 3446, 3448, 3465, 3509,
}

-- ============================================================
-- EJ cache: name (normalized) + EJ ID maps to expansion (0-11)
-- Global so it can be debugged via /dump AklimeMod_InstExpCache.
-- The expansion comes from the tier index, not from the tier name. Tier names
-- are localized and inconsistently spelled, so any name table goes stale on
-- the next rename.
-- ============================================================
local MAX_EXPANSION = 11

-- The journal abbreviates articles that the lockout API spells out. EJ has
-- "Terrasse d. endlosen Fruehlings" where GetSavedInstanceInfo returns
-- "Terrasse des Endlosen Fruehlings", so comparing the spelling fails.
-- Both sides are reduced to their significant words instead. Articles drop
-- out, and so does every byte that is not an ASCII letter or digit. That
-- covers typographic apostrophes as well as umlauts, which fall out on both
-- sides alike and therefore do not affect the comparison.
local NAME_ARTICLES = {
    ["d"]   = true, ["die"] = true, ["der"] = true, ["das"] = true,
    ["des"] = true, ["dem"] = true, ["den"] = true,
}

local function NormName(name)
    if not name then return "" end
    local key = ""
    for word in string.gmatch(string.lower(name), "%S+") do
        local clean = string.gsub(word, "[^%w]", "")
        if clean ~= "" and not NAME_ARTICLES[clean] then
            key = key .. clean
        end
    end
    return key
end

-- An instance can sit in more than one tier. Terrasse der Magister is listed
-- under The Burning Crusade and again under Midnight. Tiers run oldest first
-- and the first one wins, so the instance keeps its original expansion.
local instanceIDByName = {}
local instanceIconCache  = {}

local function CacheInstance(instID, name, exp)
    local key = name and NormName(name) or ""
    if key ~= "" and AklimeMod_InstExpCache[key] == nil then
        AklimeMod_InstExpCache[key] = exp
    end
    if key ~= "" and instanceIDByName[key] == nil then
        instanceIDByName[key] = instID
    end
    if AklimeMod_InstExpCache[instID] == nil then
        AklimeMod_InstExpCache[instID] = exp
    end
end

local function BuildInstanceExpCache()
    AklimeMod_InstExpCache = {}  -- global, debuggable via /dump
    local numTiers = EJ_GetNumTiers and EJ_GetNumTiers() or 0
    -- EJ tiers run oldest first, so the index maps straight to the expansion:
    -- tier 1 = Classic = 0, tier 12 = Midnight = 11.
    -- Trailing tiers without an expansion of their own, such as the current
    -- season, exceed MAX_EXPANSION and are skipped. Their instances already
    -- carry an entry from their real expansion tier.
    for tier = 1, numTiers do
        local exp = tier - 1
        if exp <= MAX_EXPANSION then
            EJ_SelectTier(tier)
            for i = 1, 500 do
                local instID, name = EJ_GetInstanceByIndex(i, true)
                if not instID then break end
                CacheInstance(instID, name, exp)
            end
            for i = 1, 500 do
                local instID, name = EJ_GetInstanceByIndex(i, false)
                if not instID then break end
                CacheInstance(instID, name, exp)
            end
        end
    end
end

local function HasInstanceExpCache()
    return AklimeMod_InstExpCache ~= nil and next(AklimeMod_InstExpCache) ~= nil
end

-- Returns the expansion for an instance name, or nil when the cache cannot
-- answer. nil must never be written as 0, that would pin the instance to
-- Classic in the saved variables even after the cache is available.
local function ResolveExpansion(name)
    if not name or not HasInstanceExpCache() then return nil end
    local exp = AklimeMod_InstExpCache[NormName(name)]
    if type(exp) == "number" then return exp end
    return nil
end

-- Journal icon of an instance by its lockout name, nil while the journal cache
-- cannot answer. Used by the tracker to put a picture next to raid names.
function AklimeMod_GetInstanceIcon(name)
    if not name or not EJ_GetInstanceInfo then return nil end
    local key = NormName(name)
    local cached = instanceIconCache[key]
    if cached ~= nil then return cached or nil end

    local instID = instanceIDByName[key]
    if not instID then return nil end

    local ok, _, _, _, smallIcon, _, icon = pcall(EJ_GetInstanceInfo, instID)
    local result = ok and (icon or smallIcon) or nil
    if result == 0 then result = nil end
    instanceIconCache[key] = result or false
    return result
end

-- ============================================================
-- DB access
-- ============================================================
local function GetTrackerDB()
    if not AklimeModDB then return nil end
    AklimeModDB.tracker = AklimeModDB.tracker or {}
    AklimeModDB.tracker.Toons     = AklimeModDB.tracker.Toons     or {}
    AklimeModDB.tracker.Instances = AklimeModDB.tracker.Instances or {}
    return AklimeModDB.tracker
end

-- ============================================================
-- Re-resolve the expansion of every stored instance.
-- An instance entry is only touched while the logged in character holds a
-- lockout on it, so a value written before the cache existed would survive
-- forever. This runs once per login, right after the cache is built.
-- ============================================================
local function RefreshInstanceExpansions()
    local db = GetTrackerDB()
    if not db or not db.Instances then return end
    for name, inst in pairs(db.Instances) do
        local exp = ResolveExpansion(name)
        if exp then inst.Expansion = exp end
    end
end

-- ============================================================
-- Warband bank money. Account wide, so it is stored once next to the
-- characters and not per character. The client only knows the amount while
-- the bank is viewable, outside of that a read would return 0 and wipe the
-- stored value.
-- ============================================================
local function CollectWarbandMoney()
    if not C_Bank or not C_Bank.FetchDepositedMoney or not Enum or not Enum.BankType then return end
    if not BankFrame or not BankFrame:IsShown() then return end

    local bankType = Enum.BankType.Account
    if not bankType then return end

    if C_Bank.CanViewBank then
        local okView, canView = pcall(C_Bank.CanViewBank, bankType)
        if not okView or not canView then return end
    end

    local ok, amount = pcall(C_Bank.FetchDepositedMoney, bankType)
    if not ok or type(amount) ~= "number" then return end
    if issecretvalue and issecretvalue(amount) then return end

    local db = GetTrackerDB()
    if not db then return end
    db.WarbandMoney   = amount
    db.WarbandMoneyAt = time()
end

-- ============================================================
-- Build the character key in the form "Name - Realm".
-- ============================================================
local function GetToonKey()
    local name  = UnitName("player")
    local realm = GetRealmName()
    if name and realm then
        return name .. " - " .. realm
    end
    return nil
end

-- ============================================================
-- Collect the player's currency amounts.
-- ============================================================
local function CollectCurrencies(toon)
    toon.currency = toon.currency or {}
    for _, id in ipairs(CURRENCY_IDS) do
        if C_CurrencyInfo then
            local ok, data = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and data and data.discovered then
                toon.currency[id] = toon.currency[id] or {}
                toon.currency[id].amount = data.quantity
                if data.maxQuantity and data.maxQuantity > 0 then
                    toon.currency[id].totalMax = data.maxQuantity
                end
                if data.quantityEarnedThisWeek and data.quantityEarnedThisWeek > 0 then
                    toon.currency[id].earnedThisWeek = data.quantityEarnedThisWeek
                end
            elseif ok and data and not data.discovered then
                toon.currency[id] = nil
            end
        end
    end
end

-- ============================================================
-- Collect saved instance lockouts from the Blizzard API.
-- ============================================================
local function CollectInstances(db, toonKey)
    local numSaved = GetNumSavedInstances()
    if not numSaved or numSaved == 0 then return end

    -- UPDATE_INSTANCE_INFO fires on login before the delayed cache build, so
    -- the cache has to be available here too.
    if not HasInstanceExpCache() then BuildInstanceExpCache() end

    for i = 1, numSaved do
        local name, id, expires, diff, locked, extended, mostsig, isRaid, players, diffName, numBosses, bossesKilled =
            GetSavedInstanceInfo(i)
        if name and expires and expires > 0 then
            -- Create/update instance entry
            if not db.Instances[name] then
                db.Instances[name] = {
                    Raid = isRaid,
                    Show = "saved",
                }
            end
            local inst = db.Instances[name]
            inst.Raid = isRaid

            -- LFDID from link (correct extraction: skip the GUID)
            local link = GetSavedInstanceChatLink(i) or ""
            local lid  = link:match("instancelock:[^:]+:(%d+):")
            if lid then
                inst.LFDID = tonumber(lid)
            end

            -- Expansion by name only. LFDID comes from the instancelock link
            -- and is a map ID, while the cache is keyed by journal instance ID,
            -- so that fallback could only ever hit an unrelated instance.
            local exp = ResolveExpansion(name)
            if exp then inst.Expansion = exp end

            -- Character entry
            inst[toonKey]       = inst[toonKey] or {}
            inst[toonKey][diff] = inst[toonKey][diff] or {}
            local save = inst[toonKey][diff]
            save.Expires  = time() + expires
            save.Locked   = locked
            save.Extended = extended
            save.Link     = link ~= "" and link or nil
            save.ID       = id or -1
            -- Boss kills directly from the API (more reliable than link decoding)
            save.Total    = numBosses    or 0
            save.Killed   = bossesKilled or 0
            -- Per boss status
            save.bosses = {}
            for j = 1, (numBosses or 0) do
                local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                if bossName then
                    save.bosses[j] = { name = bossName, killed = isKilled }
                end
            end
        end
    end

    -- Clean up expired entries for this character
    for instName, inst in pairs(db.Instances) do
        if inst[toonKey] then
            for d, save in pairs(inst[toonKey]) do
                if type(d) == "number" and save.Expires and save.Expires < time() then
                    inst[toonKey][d] = nil
                end
            end
            if not next(inst[toonKey]) then
                inst[toonKey] = nil
            end
        end
    end
end

-- ============================================================
-- Weekly Vault (Great Vault)
-- The numeric values of Enum.WeeklyRewardChestThresholdType change between
-- patches, so the categories are read from the enum by name.
-- ============================================================
local function GetVaultTypes()
    local threshold = Enum and Enum.WeeklyRewardChestThresholdType
    if not threshold then return nil end

    local types = {}
    if threshold.Raid then
        types[#types+1] = { key = "raid", typeID = threshold.Raid }
    end
    -- "Activities" is the current name of the former "MythicPlus" category
    local dungeonID = threshold.Activities or threshold.MythicPlus
    if dungeonID then
        types[#types+1] = { key = "dungeon", typeID = dungeonID }
    end
    if threshold.World then
        types[#types+1] = { key = "world", typeID = threshold.World }
    end

    return types
end

-- Item level of the reward behind one vault slot, nil while the game cannot say
local function GetSlotItemLevel(activityID)
    if not activityID or not C_WeeklyRewards.GetExampleRewardItemHyperlinks then return nil end
    local ok, link = pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, activityID)
    if not ok or not link then return nil end
    if not C_Item or not C_Item.GetDetailedItemLevelInfo then return nil end
    local ok2, ilvl = pcall(C_Item.GetDetailedItemLevelInfo, link)
    if ok2 and type(ilvl) == "number" and ilvl > 0 then return ilvl end
    return nil
end

local function CollectWeeklyVault(toon)
    if not C_WeeklyRewards then return end
    local vaultTypes = GetVaultTypes()
    if not vaultTypes then return end

    toon.weeklyVault = toon.weeklyVault or {}
    local vault = toon.weeklyVault
    vault.slots = vault.slots or {}

    for _, vt in ipairs(vaultTypes) do
        local ok, activities = pcall(C_WeeklyRewards.GetActivities, vt.typeID)
        if ok and activities then
            table.sort(activities, function(a, b) return (a.index or 0) < (b.index or 0) end)
            local slots, details = 0, {}
            for i, act in ipairs(activities) do
                local done = act.progress and act.threshold and act.progress >= act.threshold
                if done then slots = slots + 1 end
                -- level is the key level, the raid difficulty or the delve tier
                details[i] = {
                    done  = done and true or false,
                    level = done and act.level or nil,
                    ilvl  = done and GetSlotItemLevel(act.id) or nil,
                }
            end
            vault[vt.key]       = slots
            vault.slots[vt.key] = details
        else
            vault[vt.key] = vault[vt.key] or 0
        end
    end

    local ok2, hasRewards = pcall(C_WeeklyRewards.HasAvailableRewards)
    vault.hasRewards = ok2 and hasRewards == true or false
    -- Stamp for the tracker, data from before the weekly reset is stale
    vault.collected  = time()
end

-- ============================================================
-- Mythic keystone in the bags. The stamp lets the tracker drop the entry
-- at the weekly reset, when the game replaces the key.
-- ============================================================
local function CollectKeystone(toon)
    if not C_MythicPlus or not C_MythicPlus.GetOwnedKeystoneLevel then return end
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
        and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    if level and level > 0 and mapID then
        local key = toon.keystone
        if key and key.mapID == mapID and key.level == level then
            key.collected = time()
        else
            toon.keystone = { mapID = mapID, level = level, collected = time() }
        end
    else
        toon.keystone = nil
    end
end

-- ============================================================
-- Main collection function (call on login)
-- ============================================================
local function CollectToonData()
    local db = GetTrackerDB()
    if not db then return end

    local toonKey = GetToonKey()
    if not toonKey then return end

    -- Create toon entry
    db.Toons[toonKey] = db.Toons[toonKey] or {}
    local t = db.Toons[toonKey]

    -- Basic character info.
    local lclass, class = UnitClass("player")
    t.LClass = lclass
    t.Class  = class
    t.Level  = UnitLevel("player")

    local IL, ILe = GetAverageItemLevel()
    if IL and tonumber(IL) and tonumber(IL) > 0 then
        t.IL  = tonumber(IL)
        t.ILe = tonumber(ILe)
    end

    local faction = UnitFactionGroup("player")
    t.Faction = faction

    local lrace = UnitRace("player")
    t.Race = lrace

    local zone = GetRealZoneText()
    if zone and #zone > 0 then t.Zone = zone end

    t.Money    = GetMoney()
    t.LastSeen = time()
    t.MaxXP    = UnitXPMax("player")
    -- GUID for unique mapping on currency transfers
    t.GUID     = UnitGUID("player")

    -- Resting state
    t.isResting = IsResting()

    -- Collect currencies
    CollectCurrencies(t)

    -- Collect weekly vault
    CollectWeeklyVault(t)

    -- Collect the keystone from the bags
    CollectKeystone(t)

    -- Collect instances
    CollectInstances(db, toonKey)
end

-- ============================================================
-- Weekly reset: remove expired instances from the DB
-- ============================================================
local function CleanExpiredInstances()
    local db = GetTrackerDB()
    if not db or not db.Instances then return end
    local now = time()
    for instName, inst in pairs(db.Instances) do
        for key, val in pairs(inst) do
            if type(val) == "table" and type(key) == "string" and key:find(" - ") then
                -- Character entry
                for diff, save in pairs(val) do
                    if type(diff) == "number" and save.Expires and save.Expires > 0
                    and save.Expires < now then
                        val[diff] = nil
                    end
                end
                if not next(val) then inst[key] = nil end
            end
        end
    end
end

-- ============================================================
-- Track instance entries (for the 10/h limit display)
-- Tracks instance entries for the per hour limit display. Each entry is
-- stored with a timestamp and pruned once it is older than one hour.
-- ============================================================
local function TrackInstanceEntry()
    local db = GetTrackerDB()
    if not db then return end

    local instName, instType, diff = GetInstanceInfo()
    if not instName or not instType
    or instType == "none" or instType == "pvp" or instType == "arena" then
        return
    end

    db.instanceHistory = db.instanceHistory or {}
    local now = time()

    -- Store each entry separately (the same instance counts multiple times)
    db.instanceHistory[#db.instanceHistory + 1] = { t = now, name = instName }

    -- Remove entries older than 1 hour
    local cutoff  = now - 3600
    local cleaned = {}
    for _, e in ipairs(db.instanceHistory) do
        if e.t >= cutoff then cleaned[#cleaned + 1] = e end
    end
    db.instanceHistory = cleaned
end

-- ============================================================
-- Currency transfer between your own characters (account currencies)
-- On transfer the balance of the source character changes without it being
-- logged in. After every transfer the real balances of all characters are
-- fetched from the server and written into the tracker DB.
-- ============================================================

local function NormRealm(realm)
    return (realm or ""):gsub("[%s%-']", ""):lower()
end

-- Finds the toon key for an account currency entry.
-- Order: GUID (unique), full name with realm, unique short name.
local function FindToonKey(db, entry)
    if entry.characterGUID then
        for key, toon in pairs(db.Toons) do
            if toon.GUID == entry.characterGUID then return key end
        end
    end
    local full = entry.fullCharacterName
    if full and full ~= "" then
        local n, r = full:match("^([^%-]+)%-(.+)$")
        if n and r then
            local rNorm = NormRealm(r)
            for key in pairs(db.Toons) do
                local kn, kr = key:match("^(.-)%s*%-%s*(.+)$")
                if kn == n and NormRealm(kr) == rNorm then return key end
            end
        end
    end
    if entry.characterName then
        local found, count = nil, 0
        for key in pairs(db.Toons) do
            local kn = key:match("^(.-)%s*%-")
            if kn == entry.characterName then
                found = key
                count = count + 1
            end
        end
        if count == 1 then return found end
    end
    return nil
end

local function SyncCurrencyFromAccountData(currencyID)
    local db = GetTrackerDB()
    if not db or not C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters then return end
    local ok, list = pcall(C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters, currencyID)
    if not ok or type(list) ~= "table" then return end

    -- The logged in character is never included in the account data and is
    -- maintained separately via CollectCurrencies, so it is excluded here.
    local currentKey = GetToonKey()
    local seen = {}
    for _, entry in ipairs(list) do
        local key = FindToonKey(db, entry)
        if key and type(entry.quantity) == "number" then
            seen[key] = true
            local toon = db.Toons[key]
            toon.currency = toon.currency or {}
            toon.currency[currencyID] = toon.currency[currencyID] or {}
            toon.currency[currencyID].amount = entry.quantity
        end
    end

    -- The API only returns characters with a balance > 0. A tracked character
    -- that had this currency but is no longer listed now has 0 (e.g. the
    -- source character after transferring away). Only reconcile when the
    -- account data is reported as ready, otherwise do not wrongly zero it.
    local ready = (not C_CurrencyInfo.IsAccountCharacterCurrencyDataReady)
        or C_CurrencyInfo.IsAccountCharacterCurrencyDataReady()
    if ready then
        for key, toon in pairs(db.Toons) do
            if key ~= currentKey and not seen[key]
            and toon.currency and toon.currency[currencyID]
            and (toon.currency[currencyID].amount or 0) > 0 then
                toon.currency[currencyID].amount = 0
            end
        end
    end

    if AklimeModCTFrame and AklimeModCTFrame:IsShown() and AklimeMod_CT_Refresh then
        AklimeMod_CT_Refresh()
    end
end

-- Currencies with a pending server reconciliation after a transfer
local currencySyncPending = {}

-- Request fresh account data from the server (without argument, fetches all
-- currencies). The response comes asynchronously via the RECEIVED event. The
-- timer fallback reconciles in case this event does not fire.
local function RequestAccountCurrencyData()
    pcall(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters)
    C_Timer.After(2, function()
        for cid in pairs(currencySyncPending) do
            SyncCurrencyFromAccountData(cid)
            currencySyncPending[cid] = nil
        end
    end)
end

-- Own character: update the currency balance on every change (bundled)
local ownCurrencyDirty = false
local function CollectOwnCurrenciesSoon()
    if ownCurrencyDirty then return end
    ownCurrencyDirty = true
    C_Timer.After(1, function()
        ownCurrencyDirty = false
        local db = GetTrackerDB()
        local toonKey = GetToonKey()
        if db and toonKey and db.Toons[toonKey] then
            CollectCurrencies(db.Toons[toonKey])
        end
    end)
end

-- ============================================================
-- Event-Frame
-- ============================================================
local eventFrame = CreateFrame("Frame")
local keystoneDirty = false

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
eventFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- Transfer events: pcall in case an event is missing in this client version
pcall(eventFrame.RegisterEvent, eventFrame, "CURRENCY_TRANSFER_LOG_UPDATE")
pcall(eventFrame.RegisterEvent, eventFrame, "ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")
-- Warband bank: only readable while the bank is open
pcall(eventFrame.RegisterEvent, eventFrame, "BANKFRAME_OPENED")
pcall(eventFrame.RegisterEvent, eventFrame, "BANK_TABS_CHANGED")
-- Keystone: a new key arrives after a completed run, bag changes cover the rest
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if event == "PLAYER_ENTERING_WORLD" then
            CleanExpiredInstances()
            -- EJ cache + toon data after a longer delay
            C_Timer.After(3, function()
                BuildInstanceExpCache()
                RefreshInstanceExpansions()
                CollectToonData()
            end)
        else
            -- ZONE_CHANGED_NEW_AREA: count instance entry
            -- Delay: GetInstanceInfo() is not yet stable on a zone change
            C_Timer.After(2, TrackInstanceEntry)
        end

    elseif event == "PLAYER_MONEY" then
        local db = GetTrackerDB()
        if not db then return end
        local toonKey = GetToonKey()
        if toonKey and db.Toons[toonKey] then
            db.Toons[toonKey].Money = GetMoney()
        end
        -- Deposit and withdrawal at the bank also change the player's money
        CollectWarbandMoney()

    elseif event == "BANKFRAME_OPENED" or event == "BANK_TABS_CHANGED" then
        C_Timer.After(0.3, CollectWarbandMoney)

    elseif event == "UPDATE_INSTANCE_INFO" then
        -- Update instances and clean up expired ones
        local db = GetTrackerDB()
        if not db then return end
        local toonKey = GetToonKey()
        if toonKey then
            CollectInstances(db, toonKey)
        end
        CleanExpiredInstances()

    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "BAG_UPDATE_DELAYED" then
        -- Bag events come in bursts, one read per second is enough
        if keystoneDirty then return end
        keystoneDirty = true
        C_Timer.After(1, function()
            keystoneDirty = false
            local db = GetTrackerDB()
            local toonKey = GetToonKey()
            if db and toonKey and db.Toons[toonKey] then
                CollectKeystone(db.Toons[toonKey])
            end
        end)

    elseif event == "WEEKLY_REWARDS_UPDATE" then
        C_Timer.After(0.3, function()
            local db = GetTrackerDB()
            if not db then return end
            local toonKey = GetToonKey()
            if toonKey and db.Toons[toonKey] then
                CollectWeeklyVault(db.Toons[toonKey])
                if AklimeModCTFrame and AklimeModCTFrame:IsShown() then
                    AklimeMod_CT_Refresh()
                end
            end
        end)

    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        -- Own character: keep the balance current (looting, spending, transfer)
        CollectOwnCurrenciesSoon()

    elseif event == "CURRENCY_TRANSFER_LOG_UPDATE" then
        -- A transfer was booked: determine the affected currencies from the
        -- log and request fresh account data (response is asynchronous)
        if C_CurrencyInfo.FetchCurrencyTransferTransactions then
            local ok, txs = pcall(C_CurrencyInfo.FetchCurrencyTransferTransactions)
            if ok and type(txs) == "table" then
                for _, tx in ipairs(txs) do
                    if tx and tx.currencyType then
                        currencySyncPending[tx.currencyType] = true
                    end
                end
            end
        end
        if C_CurrencyInfo.RequestCurrencyDataForAccountCharacters then
            RequestAccountCurrencyData()
        else
            -- No request API: reconcile directly with the cache
            for cid in pairs(currencySyncPending) do
                SyncCurrencyFromAccountData(cid)
                currencySyncPending[cid] = nil
            end
        end

    elseif event == "ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED" then
        -- Fresh account data has arrived: reconcile all flagged currencies
        -- (event has no payload, so always via the pending list)
        for cid in pairs(currencySyncPending) do
            SyncCurrencyFromAccountData(cid)
            currencySyncPending[cid] = nil
        end
    end
end)