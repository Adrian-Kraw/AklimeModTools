-- Modules/CharacterTracker.lua
-- Character tracker: shows raids and currencies per character.
-- Fully dynamic, with a hover tooltip on character names.

local L = AklimeModL or {}

-- ============================================================
-- Hidden and do-not-track currencies that must not be shown.
-- ============================================================
local HIDDEN_CURRENCY_IDS = {
    [2409]=true, [2410]=true, [2411]=true, [2412]=true,  -- DNT Crest Fragments
    [2413]=true,  -- 10.1 Professions - S2 Spark (Hidden)
    [2774]=true,  -- 10.2 Professions - S3 Spark (Hidden)
    [2800]=true,  -- 10.2.6 Professions - S4 Spark (Hidden)
    [3010]=true,  -- 10.2.6 Rewards - S4 Dinar (Hidden)
    [3023]=true,  -- 11.0 Professions - S1 Spark (Hidden)
    [3132]=true,  -- 11.1 Professions - S2 Spark (Hidden)
    [1889]=true,  -- Adventure Campaign Progress
    [2045]=true,  -- Dragon Glyph Embers (intern)
}

-- All currency IDs tracked by the addon.
local TRACKED_CURRENCY_IDS = {
    -- Season
    3310, 2803, 3378, 3418, 3028, 3356, 3383, 3341, 3343, 3345, 3347, 3212,
    3442, 3443, 3444, 3445, 3446, 3465, 3509,
    -- Dungeon & Raid
    1166,
    -- Player vs. Player
    391, 2123, 1792, 1602,
    -- Miscellaneous
    2588, 402, 81, 3363, 515, 2032,
    -- Midnight
    3373, 3405, 3393, 3316, 3385, 3376, 3392, 3379, 3377, 3400, 3448,
    3256, 3257, 3258, 3260, 3261, 3262, 3263, 3264, 3265, 3266,
    -- The War Within
    3220, 3055, 3093, 3089, 3090, 3056, 3218, 3226, 2815, 3303, 3149,
    -- Dragonflight
    2118, 2657, 2594, 2650, 2122, 2777, 2003,
    -- Shadowlands
    1754, 1979, 1885, 1820, 1931, 2009, 1819, 1813, 1828, 1906, 1767, 1977, 1816, 1904,
    -- Battle for Azeroth
    1717, 1716, 1803, 1299, 1560, 1755, 1721, 1710, 1580, 1719,
    -- Legion
    1149, 1533, 1342, 1275, 1226, 1220, 1273, 1155, 1508,
    -- Warlords of Draenor
    994, 823, 824, 1101, 1129,
    -- Mists of Pandaria
    738, 752, 776, 777, 789, 697,
    -- Cataclysm
    416,
    -- Wrath of the Lich King
    241,
    -- The Burning Crusade
    1704,
}

-- ============================================================
-- Difficulty
-- ============================================================
local function GetDiffLabel(inst, diff)
    if not inst.Raid then return nil end
    if diff == 3  then return "10N"  end
    if diff == 4  then return "25N"  end
    if diff == 5  then return "10H"  end
    if diff == 6  then return "25H"  end
    if diff == 7  then return "LFR"  end
    if diff == 14 then return "N"    end
    if diff == 15 then return "H"    end
    if diff == 16 then return "M"    end
    if diff == 17 then return "LFR"  end
    return nil
end

local DIFF_ORDER = { 17, 3, 4, 5, 6, 7, 14, 15, 16 }
local DIFF_COLOR = {
    [17]={r=0.25,g=0.75,b=1.0 }, [7]={r=0.25,g=0.75,b=1.0 },
    [14]={r=0.12,g=0.93,b=0.12}, [3]={r=0.12,g=0.93,b=0.12}, [4]={r=0.12,g=0.93,b=0.12},
    [15]={r=0.0, g=0.44,b=0.87}, [5]={r=0.0, g=0.44,b=0.87}, [6]={r=0.0, g=0.44,b=0.87},
    [16]={r=0.64,g=0.21,b=0.93},
}

local EXP_NAMES = {
    [0]  = "Classic",
    [1]  = "The Burning Crusade",
    [2]  = "Wrath of the Lich King",
    [3]  = "Cataclysm",
    [4]  = "Mists of Pandaria",
    [5]  = "Warlords of Draenor",
    [6]  = "Legion",
    [7]  = "Battle for Azeroth",
    [8]  = "Shadowlands",
    [9]  = "Dragonflight",
    [10] = "The War Within",
    [11] = "Midnight",
    [12] = L["curr_cat_misc"]   or "Miscellaneous",
    [13] = L["curr_cat_pvp"]    or "Player vs. Player",
    [14] = L["curr_cat_raids"]  or "Dungeons & Raids",
    [15] = L["curr_cat_season"] or "Season",
}

-- expansionLevel is stored directly as 0 to 11, so no mapping is needed.
-- This only guards against old or invalid stored values.
local function NormalizeExpansion(exp)
    if not exp then return 0 end
    if exp >= 0 and exp <= 11 then return exp end
    return 0
end

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.savedInstances
end
local function IsRaidExpEnabled(exp)
    local db = GetDB()
    return not (db and db.raidExps and db.raidExps[exp] == false)
end
local function IsCurrencyEnabled(id)
    local db = GetDB()
    return not (db and db.currencies and db.currencies[id] == false)
end

local function GetToonDB()
    if AklimeModDB and AklimeModDB.tracker and AklimeModDB.tracker.Toons then
        return AklimeModDB.tracker.Toons
    end
    return nil
end

local function GetInstanceDB()
    if AklimeModDB and AklimeModDB.tracker and AklimeModDB.tracker.Instances then
        return AklimeModDB.tracker.Instances
    end
    return nil
end

local function GetDataDB()
    local toons = GetToonDB()
    if not toons then return nil end
    return { Toons = toons, Instances = GetInstanceDB() or {} }
end

-- Timestamp of the last weekly reset, derived from the client's countdown
-- to the next reset. Lets us detect vault data collected before the reset,
-- which is stale once a new week has started.
local function GetLastWeeklyReset()
    if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then return nil end
    local ok, secs = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
    if not ok or not secs or secs <= 0 then return nil end
    return time() + secs - 604800
end

-- ============================================================
-- Helpers
-- ============================================================
local function ShortName(full)
    return full:match("^(.-)%s*%-") or full
end

local function ClassCol(lclass)
    if not lclass then return 1, 0.82, 0 end
    -- RAID_CLASS_COLORS requires an uppercase English key (e.g. "WARRIOR")
    local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[lclass:upper()]
    if ci then return ci.r, ci.g, ci.b end
    return 1, 0.82, 0
end

-- Get class color from toon data (Class = uppercase English, LClass = localized)
local function ToonClassCol(toon)
    if not toon then return 1, 0.82, 0 end
    -- Class is uppercase English (WARRIOR, EVOKER etc.) -- use directly with RAID_CLASS_COLORS
    if toon.Class then
        local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[toon.Class:upper()]
        if ci then return ci.r, ci.g, ci.b end
    end
    -- Fallback to LClass (works on English clients)
    if toon.LClass then
        local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[toon.LClass:upper()]
        if ci then return ci.r, ci.g, ci.b end
    end
    return 1, 0.82, 0
end

local function GetBossKills(save)
    if not save then return 0 end
    -- Direct from API (DataCollector stores save.Killed)
    if save.Killed and save.Killed > 0 then return save.Killed end
    -- Fallback: link bitmask (older stored data)
    if save.Link then
        local bits = save.Link:match(":(%d+)\124h")
        bits = bits and tonumber(bits)
        if bits and bits > 1 then  -- > 1 because isExtended (0/1) does not count
            local k = 0
            while bits > 0 do
                if bit.band(bits, 1) > 0 then k = k + 1 end
                bits = bit.rshift(bits, 1)
            end
            return k
        end
    end
    return 0
end

local function GetBossTotal(save)
    -- Direct from API (DataCollector: numBosses from GetSavedInstanceInfo)
    if save and save.Total and save.Total > 0 then return save.Total end
    -- Fallback: Anzahl gespeicherter Bosse
    if save and save.bosses then
        local n = #save.bosses
        if n > 0 then return n end
    end
    return 0
end

-- Manual expansion assignment, since C_CurrencyInfo.expansionID is often nil.
-- Every tracked currency ID must be mapped here.
local CURRENCY_EXP = {}
local function SetExp(exp, ids)
    for _, id in ipairs(ids) do CURRENCY_EXP[id] = exp end
end
-- Season (15) -- crest currencies + season currencies
SetExp(15, {3310,2803,3378,3418,3028,3356,3383,3341,3343,3345,3347,3212,
            3442,3443,3444,3445,3446,3465,3509})
-- Dungeon & Raid (14)
SetExp(14, {1166})
-- Player vs. Player (13)
SetExp(13, {391,2123,1792,1602})
-- Miscellaneous (12)
SetExp(12, {2588,402,81,3363,515,2032})
-- Midnight (11) -- content + profession currencies
SetExp(11, {3373,3405,3393,3316,3385,3376,3392,3379,3377,3400,3448,
            3256,3257,3258,3260,3261,3262,3263,3264,3265,3266})
-- The War Within (10)
SetExp(10, {3220,3055,3093,3089,3090,3056,3218,3226,2815,3303,3149})
-- Dragonflight (9)
SetExp(9,  {2118,2657,2594,2650,2122,2777,2003})
-- Shadowlands (8)
SetExp(8,  {1754,1979,1885,1820,1931,2009,1819,1813,1828,1906,1767,1977,1816,1904})
-- Battle for Azeroth (7)
SetExp(7,  {1717,1716,1803,1299,1560,1755,1721,1710,1580,1719})
-- Legion (6)
SetExp(6,  {1149,1533,1342,1275,1226,1220,1273,1155,1508})
-- Warlords of Draenor (5)
SetExp(5,  {994,823,824,1101,1129})
-- Mists of Pandaria (4)
SetExp(4,  {738,752,776,777,789,697})
-- Cataclysm (3)
SetExp(3,  {416})
-- Wrath of the Lich King (2)
SetExp(2,  {241})
-- The Burning Crusade (1)
SetExp(1,  {1704})

local currInfoCache = {}
local function GetCurrInfo(id)
    local cached = currInfoCache[id]
    if cached ~= nil then return cached or nil end
    if C_CurrencyInfo then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and info and info.name and info.name ~= "" then
            -- Expansion from manual table
            -- If not mapped, return nil (do not display)
            local exp = CURRENCY_EXP[id]
            if exp == nil then
                currInfoCache[id] = false  -- false = known but do not display
                return nil
            end
            currInfoCache[id] = {
                name = info.name,
                exp  = exp,
                icon = info.iconFileID,
            }
            return currInfoCache[id]
        end
    end
    return nil
end

local function FormatAmount(a)
    if not a or a == 0 then return nil end
    if a >= 1000000 then return string.format("%.1fM", a/1000000) end
    if a >= 1000    then return string.format("%.1fk", a/1000) end
    return tostring(a)
end

-- Money down to the copper, split into its three parts so they can be put in
-- columns of their own. The gold panel shows exact amounts, currencies keep
-- the short form above.
local GOLD_COIN_COL   = "|cFFFFD100"
local SILVER_COIN_COL = "|cFFCCCCCC"
local COPPER_COIN_COL = "|cFFCC6633"

local function SplitMoney(copper)
    copper = copper or 0
    local gold = math.floor(copper / 10000)
    local goldStr = BreakUpLargeNumbers and BreakUpLargeNumbers(gold) or tostring(gold)
    return goldStr .. "g",
           math.floor((copper % 10000) / 100) .. "s",
           (copper % 100) .. "c"
end

local function FormatMoney(copper)
    local gold, silver, rest = SplitMoney(copper)
    return GOLD_COIN_COL .. gold .. "|r " ..
           SILVER_COIN_COL .. silver .. "|r " ..
           COPPER_COIN_COL .. rest .. "|r"
end

-- Sort key: lowercase + umlaut normalization so A-Z works for both DE and EN names.
-- Lua's < operator compares bytes; UTF-8 umlauts (C3 xx) sort after z without this.
local function SortKey(s)
    if not s then return "" end
    s = s:lower()
    s = s:gsub("\195\164", "a")   -- ä
    s = s:gsub("\195\182", "o")   -- ö
    s = s:gsub("\195\188", "u")   -- ü
    s = s:gsub("\195\159", "ss")  -- ß
    s = s:gsub("\195\132", "a")   -- Ä
    s = s:gsub("\195\150", "o")   -- Ö
    s = s:gsub("\195\156", "u")   -- Ü
    return s
end

local function GetSelectedChars()
    local db   = GetDB()
    local trackerDB = GetDataDB()
    if not trackerDB then return {} end
    local sel = {}
    if db and db.chars then
        for name, on in pairs(db.chars) do
            if on and trackerDB.Toons[name] then sel[#sel+1] = name end
        end
    end
    table.sort(sel)
    return sel
end

local function BuildRaids(sel)
    local trackerDB = GetDataDB()
    if not trackerDB or not trackerDB.Instances then return {} end
    local byExp = {}
    for instName, inst in pairs(trackerDB.Instances) do
        -- Only real raids (maxPlayers > 5), no dungeons, no random instances
        if inst.Raid and not inst.Random and inst.Show ~= "never"
        and IsRaidExpEnabled(NormalizeExpansion(inst.Expansion or 0)) then
            local exp   = NormalizeExpansion(inst.Expansion or 0)
            local diffs = {}
            local hasSave = false
            for _, ch in ipairs(sel) do
                if inst[ch] then
                    for diff, save in pairs(inst[ch]) do
                        if type(diff) == "number" and save and save.Expires and save.Expires > 0 then
                            if not diffs[diff] then diffs[diff] = {} end
                            diffs[diff][ch] = save
                            hasSave = true
                        end
                    end
                end
            end
            if hasSave then
                if not byExp[exp] then byExp[exp] = {} end
                byExp[exp][#byExp[exp]+1] = {
                    name      = instName,
                    lfdid     = inst.LFDID,
                    recLevel  = inst.RecLevel or 0,
                    diffs     = diffs,
                    inst      = inst,
                    worldBoss = inst.WorldBoss ~= nil,
                }
            end
        end
    end
    for _, raids in pairs(byExp) do
        table.sort(raids, function(a,b)
            -- World bosses go last
            if a.worldBoss ~= b.worldBoss then return not a.worldBoss end
            return (a.recLevel or 0) > (b.recLevel or 0)
        end)
    end
    return byExp
end

local function BuildCurrencies(sel)
    local trackerDB = GetDataDB()
    if not trackerDB then return {} end

    -- IDs where at least 1 character has amount > 0
    local present = {}
    for _, ch in ipairs(sel) do
        local toon = trackerDB.Toons[ch]
        if toon and toon.currency then
            for id, data in pairs(toon.currency) do
                if type(id) == "number" and data.amount and data.amount > 0
                and not HIDDEN_CURRENCY_IDS[id] then
                    present[id] = true
                end
            end
        end
    end

    local siSet = {}
    for _, id in ipairs(TRACKED_CURRENCY_IDS) do siSet[id] = true end

    local result = {}
    for id in pairs(present) do
        if IsCurrencyEnabled(id) then
            local info = GetCurrInfo(id)
            if info then
                local nameLower = info.name:lower()
                -- Only filter obviously internal/hidden ones
                if not nameLower:find("%(hidden%)") and not nameLower:find("dnt")
                and not nameLower:find("personal tracker") then
                    result[#result+1] = { id=id, exp=info.exp, name=info.name, icon=info.icon }
                end
            end
        end
    end

    table.sort(result, function(a, b)
        if a.exp ~= b.exp then return a.exp > b.exp end
        return SortKey(a.name) < SortKey(b.name)
    end)
    return result
end

-- ============================================================
-- Layout constants
-- ============================================================
local ROW_H = 16
local LAB_W = 260   -- Enough room for raid names
local COL_W = 68
local PAD   = 6

-- ============================================================
-- Gold overview panel
-- ============================================================
local GOLD_ROW_H   = 14
local GOLD_NAME_W  = 104
-- Each coin gets its own column, so gold, silver and copper line up no matter
-- how long the name or the amount in the row above is
local GOLD_G_W     = 66
local GOLD_S_W     = 28
local GOLD_C_W     = 28
local GOLD_PART_GAP = 4
local GOLD_AMT_W   = GOLD_G_W + GOLD_S_W + GOLD_C_W + GOLD_PART_GAP * 2
local GOLD_COIN_W    = { GOLD_G_W, GOLD_S_W, GOLD_C_W }
local GOLD_COIN_COLS = { GOLD_COIN_COL, SILVER_COIN_COL, COPPER_COIN_COL }
local GOLD_COL_W   = GOLD_NAME_W + GOLD_AMT_W + 6
local GOLD_COL_GAP = 18
local GOLD_PAD     = 14
local GOLD_HEAD_H  = 58
local GOLD_HEAD_H_BANK = 74   -- header grows by the warband bank line

local goldPanel = nil
local goldRows  = {}

local function GoldRow(index)
    local row = goldRows[index]
    if row then return row end

    row = {}
    row.left = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.left:SetSize(GOLD_NAME_W, GOLD_ROW_H)
    row.left:SetJustifyH("LEFT")
    row.left:SetWordWrap(false)

    row.coins = {}
    for i, width in ipairs(GOLD_COIN_W) do
        local fs = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetSize(width, GOLD_ROW_H)
        fs:SetJustifyH("RIGHT")
        fs:SetWordWrap(false)
        row.coins[i] = fs
    end

    row.line = goldPanel:CreateTexture(nil, "ARTWORK")
    row.line:SetHeight(1)
    row.line:SetColorTexture(0.5, 0.42, 0.18, 0.6)
    row.line:Hide()

    goldRows[index] = row
    return row
end

-- Richest realm first, inside a realm the richest character first
local function CollectGold()
    local trackerDB = GetDataDB()
    if not trackerDB or not trackerDB.Toons then return nil end

    local byRealm, order = {}, {}
    local total, charCount = 0, 0

    for fullName, toon in pairs(trackerDB.Toons) do
        local realmName = fullName:match("%-(.+)$") or "?"
        local realm = byRealm[realmName]
        if not realm then
            realm = { name = realmName, total = 0, chars = {} }
            byRealm[realmName] = realm
            order[#order + 1] = realm
        end
        local money = toon.Money or 0
        realm.total = realm.total + money
        realm.chars[#realm.chars + 1] = { name = ShortName(fullName), money = money, toon = toon }
        total = total + money
        charCount = charCount + 1
    end

    table.sort(order, function(a, b)
        if a.total ~= b.total then return a.total > b.total end
        return SortKey(a.name) < SortKey(b.name)
    end)
    for _, realm in ipairs(order) do
        table.sort(realm.chars, function(a, b)
            if a.money ~= b.money then return a.money > b.money end
            return SortKey(a.name) < SortKey(b.name)
        end)
    end

    return order, total, charCount
end

-- One block per realm, kept together in a column: header, characters, spacer
local function BuildGoldBlocks(order)
    local blocks, lineCount = {}, 0
    for _, realm in ipairs(order) do
        local block = { { header = true, left = realm.name, money = realm.total } }
        for _, char in ipairs(realm.chars) do
            local r, g, b = ToonClassCol(char.toon)
            block[#block + 1] = {
                left  = string.format("|cFF%02x%02x%02x%s|r", r * 255, g * 255, b * 255, char.name),
                money = char.money,
            }
        end
        block[#block + 1] = { spacer = true }
        blocks[#blocks + 1] = block
        lineCount = lineCount + #block
    end
    return blocks, lineCount
end

-- Rows per column so that width and height end up roughly equal
local function GoldRowsPerColumn(lineCount, headHeight)
    local byScreen = math.floor((UIParent:GetHeight() * 0.75 - headHeight) / GOLD_ROW_H)
    local square   = math.ceil(math.sqrt(lineCount * (GOLD_COL_W + GOLD_COL_GAP) / GOLD_ROW_H))
    return math.max(8, math.min(square, math.max(10, byScreen)))
end

-- Warband bank, collected by the DataCollector while the bank is open
local function GetWarbandGold()
    local tracker = AklimeModDB and AklimeModDB.tracker
    local money   = tracker and tracker.WarbandMoney
    if type(money) ~= "number" or money <= 0 then return 0 end
    return money
end

local function UpdateGoldPanel()
    local order, total, charCount = CollectGold()
    if not order or #order == 0 then return false end

    local warband = GetWarbandGold()
    local headH   = warband > 0 and GOLD_HEAD_H_BANK or GOLD_HEAD_H

    local blocks, lineCount = BuildGoldBlocks(order)
    local rowsPerCol = GoldRowsPerColumn(lineCount, headH)

    local columns, current = {}, {}
    for _, block in ipairs(blocks) do
        if #current > 0 and #current + #block > rowsPerCol then
            columns[#columns + 1] = current
            current = {}
        end
        for _, line in ipairs(block) do current[#current + 1] = line end
    end
    if #current > 0 then columns[#columns + 1] = current end

    local used, maxRows = 0, 0
    for colIndex, col in ipairs(columns) do
        local x = GOLD_PAD + (colIndex - 1) * (GOLD_COL_W + GOLD_COL_GAP)
        for rowIndex, line in ipairs(col) do
            used = used + 1
            local row = GoldRow(used)
            local y = -(headH + (rowIndex - 1) * GOLD_ROW_H)

            row.left:ClearAllPoints()
            row.left:SetPoint("TOPLEFT", goldPanel, "TOPLEFT", x, y)

            local coinX = x + GOLD_NAME_W + 6
            for i, fs in ipairs(row.coins) do
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", goldPanel, "TOPLEFT", coinX, y)
                coinX = coinX + GOLD_COIN_W[i] + GOLD_PART_GAP
                fs:Show()
            end

            if line.spacer then
                row.left:SetText("")
                for _, fs in ipairs(row.coins) do fs:SetText("") end
                row.line:Hide()
            else
                if line.header then
                    row.left:SetText("|cFFFFFFFF" .. line.left .. "|r")
                    row.line:ClearAllPoints()
                    row.line:SetPoint("TOPLEFT",  goldPanel, "TOPLEFT", x, y - GOLD_ROW_H + 2)
                    row.line:SetPoint("TOPRIGHT", goldPanel, "TOPLEFT", x + GOLD_COL_W, y - GOLD_ROW_H + 2)
                    row.line:Show()
                else
                    row.left:SetText(line.left)
                    row.line:Hide()
                end
                local gold, silver, rest = SplitMoney(line.money)
                row.coins[1]:SetText(GOLD_COIN_COLS[1] .. gold .. "|r")
                row.coins[2]:SetText(GOLD_COIN_COLS[2] .. silver .. "|r")
                row.coins[3]:SetText(GOLD_COIN_COLS[3] .. rest .. "|r")
            end

            row.left:Show()
        end
        if #col > maxRows then maxRows = #col end
    end

    for i = used + 1, #goldRows do
        goldRows[i].left:Hide()
        for _, fs in ipairs(goldRows[i].coins) do fs:Hide() end
        goldRows[i].line:Hide()
    end

    goldPanel.total:SetText(FormatMoney(total + warband))
    goldPanel.sub:SetText(string.format(L["ct_gold_chars"] or "%d characters on %d realms",
        charCount, #order))

    if warband > 0 then
        goldPanel.bank:SetText((L["ct_warband_bank"] or "Warband Bank") ..
            ": " .. FormatMoney(warband))
        goldPanel.bank:Show()
    else
        goldPanel.bank:Hide()
    end

    local width  = GOLD_PAD * 2 + #columns * GOLD_COL_W + (#columns - 1) * GOLD_COL_GAP
    local height = headH + maxRows * GOLD_ROW_H + GOLD_PAD
    goldPanel:SetSize(math.max(width, 260), height)
    return true
end

local function EnsureGoldPanel(anchor)
    if goldPanel then return end

    goldPanel = CreateFrame("Frame", "AklimeModCTGoldPanel", anchor, "BackdropTemplate")
    goldPanel:SetFrameStrata("TOOLTIP")
    goldPanel:SetClampedToScreen(true)
    goldPanel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    goldPanel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 14,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    goldPanel:SetBackdropColor(0.04, 0.04, 0.04, 0.96)
    goldPanel:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)

    goldPanel.title = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldPanel.title:SetPoint("TOPLEFT", GOLD_PAD, -12)
    goldPanel.title:SetText("|cFFFFD100" .. (L["ct_gold_overview"] or "Gold Overview") .. "|r")

    goldPanel.sub = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    goldPanel.sub:SetPoint("TOPLEFT", GOLD_PAD, -32)

    goldPanel.bank = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldPanel.bank:SetPoint("TOPLEFT", GOLD_PAD, -48)
    goldPanel.bank:Hide()

    -- Total of every character, the headline number of this panel
    goldPanel.total = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    goldPanel.total:SetPoint("TOPRIGHT", -GOLD_PAD, -12)
    goldPanel.total:SetJustifyH("RIGHT")

    goldPanel.totalLabel = goldPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    goldPanel.totalLabel:SetPoint("TOPRIGHT", -GOLD_PAD, -34)
    goldPanel.totalLabel:SetJustifyH("RIGHT")
    goldPanel.totalLabel:SetText(L["ct_grand_total"] or "Total Gold")

    goldPanel:Hide()
end

-- ============================================================
-- UI
-- ============================================================
local mainFrame    = nil
local contentFrame = nil
local view         = "main"

local function ClearContent()
    if not contentFrame then return end
    for _, c in ipairs({contentFrame:GetChildren()}) do c:SetParent(nil); c:Hide() end
    for _, r in ipairs({contentFrame:GetRegions()})  do r:Hide() end
end

local function CreateUI()
    if mainFrame then return end

    mainFrame = CreateFrame("Frame", "AklimeModCTFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(960, 640)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left=3, right=3, top=3, bottom=3 },
    })
    mainFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    mainFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    mainFrame:Hide()

    -- ESC closes
    table.insert(UISpecialFrames, "AklimeModCTFrame")

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -10)
    title:SetText(NORMAL_FONT_COLOR_CODE .. (L["ct_title"] or "Character Tracker") .. FONT_COLOR_CODE_CLOSE)

    -- Gold summary top left
    local goldBtn = CreateFrame("Button", nil, mainFrame)
    goldBtn:SetSize(120, 28)
    goldBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -4)
    local goldLabel = goldBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    goldLabel:SetAllPoints(goldBtn)
    goldLabel:SetJustifyH("LEFT")
    goldLabel:SetText("|cFFFFD100" .. (L["ct_gold_overview"] or "Gold Overview") .. "|r")

    mainFrame.goldBtn   = goldBtn
    mainFrame.goldLabel = goldLabel

    -- Instance timer to the right of the gold label
    local instBtn = CreateFrame("Button", nil, mainFrame)
    instBtn:SetSize(150, 28)
    instBtn:SetPoint("LEFT", goldBtn, "RIGHT", 4, 0)
    local instLabel = instBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instLabel:SetAllPoints(instBtn)
    instLabel:SetJustifyH("LEFT")

    -- Dynamic label: shows count of recent instances (own tracking)
    local function GetInstHistory()
        return AklimeModDB and AklimeModDB.tracker and AklimeModDB.tracker.instanceHistory or {}
    end
    local function CountRecentInst()
        local now, cnt = time(), 0
        for _, e in ipairs(GetInstHistory()) do
            if type(e) == "table" and e.t and now - e.t < 3600 then cnt = cnt + 1 end
        end
        return cnt
    end
    local function UpdateInstLabel()
        local cnt = CountRecentInst()
        if cnt > 0 then
            local color = cnt >= 8 and "|cFFFF4444" or cnt >= 5 and "|cFFFFD100" or "|cFF00FF00"
            instLabel:SetText(color .. cnt .. "/10|r " .. (L["ct_inst_word"] or "Instances"))
        else
            instLabel:SetText("|cFFAAAAAA0/10 " .. (L["ct_inst_word"] or "Instances") .. "|r")
        end
    end
    UpdateInstLabel()
    mainFrame.UpdateInstLabel = UpdateInstLabel

    instBtn:SetScript("OnEnter", function(self)
        UpdateInstLabel()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cFFFFD100" .. (L["ct_inst_recent"] or "Recent Instances") .. "|r")
        GameTooltip:AddLine(" ")

        local history = GetInstHistory()
        local now     = time()
        local recent  = {}
        for _, e in ipairs(history) do
            if type(e) == "table" and e.t and now - e.t < 3600 then
                recent[#recent+1] = e
            end
        end
        -- Oldest entry first
        table.sort(recent, function(a, b) return a.t < b.t end)

        if #recent > 0 then
            for _, e in ipairs(recent) do
                local remaining = e.t + 3600 - now
                local m = math.floor(remaining / 60)
                local s = remaining % 60
                local timeStr = "|cFFFF4444" .. string.format(L["ct_inst_time"] or "%d min. %d sec.", m, s) .. "|r"
                GameTooltip:AddDoubleLine(timeStr, e.name or "?", 1,1,1, 0.8,0.8,0.8)
            end
            GameTooltip:AddLine(" ")
            if #recent >= 10 then
                local freeIn = recent[1].t + 3600 - now
                local m = math.floor(freeIn / 60)
                GameTooltip:AddLine(string.format(L["ct_inst_next_free"] or "Next slot free in: |cFF00FF00%d min.|r", m))
            else
                GameTooltip:AddLine(string.format(L["ct_inst_avail"] or "Still |cFF00FF00%d|r instances available", 10 - #recent))
            end
        else
            GameTooltip:AddLine(L["ct_inst_none"] or "No recent instances.", 0.6,0.6,0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["ct_inst_limit"] or "Limit: 10 instances per hour (account)", 0.5,0.5,0.5)
        GameTooltip:Show()
    end)
    instBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    goldBtn:SetScript("OnEnter", function(self)
        EnsureGoldPanel(self)
        if UpdateGoldPanel() then goldPanel:Show() end
    end)
    goldBtn:SetScript("OnLeave", function()
        if goldPanel then goldPanel:Hide() end
    end)

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    local charBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    charBtn:SetSize(110, 20)
    charBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -28, -8)
    charBtn:SetText(L["ct_btn_chars"] or "Characters")
    charBtn:SetScript("OnClick", function()
        if view == "main" then
            view = "chars"
            charBtn:SetText(L["ct_btn_overview"] or "Overview")
            AklimeMod_CT_ShowChars()
        else
            view = "main"
            charBtn:SetText(L["ct_btn_chars"] or "Characters")
            AklimeMod_CT_Refresh()
        end
    end)

    local scroll = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     6, -34)
    scroll:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -24, 6)

    contentFrame = CreateFrame("Frame", nil, scroll)
    contentFrame:SetWidth(920)
    contentFrame:SetHeight(1000)
    scroll:SetScrollChild(contentFrame)
end

-- Row
local function MkRow(parent, y, even)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(ROW_H)
    f:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -y)
    f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(even and 0.09 or 0.06, even and 0.09 or 0.06, even and 0.09 or 0.06, 0.7)
    return f
end

local function MkHdr(parent, y)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(ROW_H)
    f:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -y)
    f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    return f
end

local function MkTxt(parent, text, x, w, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
    fs:SetPoint("LEFT", parent, "LEFT", x, 0)
    fs:SetWidth(w)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

-- Character header button with a hover tooltip.
local function MkCharHeader(parent, y, colX, sel, trackerDB)
    local hRow = MkHdr(parent, y)
    MkTxt(hRow, NORMAL_FONT_COLOR_CODE .. (L["ct_name"] or "Name") .. FONT_COLOR_CODE_CLOSE,
        8, LAB_W - 4, "GameFontNormalSmall", "LEFT")
    for i, name in ipairs(sel) do
        local toon = trackerDB.Toons[name]
        local label = ShortName(name)
        local r, g, b = ToonClassCol(toon)

        -- Invisible button over the column for hover tooltip
        local btn = CreateFrame("Button", nil, hRow)
        btn:SetSize(COL_W, ROW_H)
        btn:SetPoint("LEFT", hRow, "LEFT", colX + (i-1)*COL_W, 0)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints(btn)
        fs:SetJustifyH("CENTER")
        fs:SetText(string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, label))

        -- Tooltip with character info.
        local n = name
        btn:SetScript("OnEnter", function(self)
            local t = trackerDB.Toons[n]
            if not t then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:ClearLines()
            local tr, tg, tb = ToonClassCol(t)
            GameTooltip:AddLine(string.format("|cFF%02x%02x%02x%s|r", tr*255, tg*255, tb*255, n))
            if t.Class then
                -- First letter uppercase, rest lowercase
                local class = t.Class:sub(1,1):upper() .. t.Class:sub(2):lower()
                GameTooltip:AddLine(class, 0.8, 0.8, 0.8)
            end
            if t.Level then
                GameTooltip:AddDoubleLine("Level", tostring(t.Level), 0.8,0.8,0.8, 1,0.82,0)
            end
            if t.IL then
                GameTooltip:AddDoubleLine(L["ct_item_level"] or "Item Level", string.format("%.1f", t.IL), 0.8,0.8,0.8, 1,0.82,0)
            end
            if t.Money and t.Money > 0 then
                local gold   = math.floor(t.Money / 10000)
                local silver = math.floor((t.Money % 10000) / 100)
                local copper = t.Money % 100
                local goldStr = string.format("|cFFFFD100%dg|r |cFFCCCCCC%ds|r |cFFCC6633%dc|r",
                    gold, silver, copper)
                GameTooltip:AddDoubleLine("Gold", goldStr, 0.8,0.8,0.8, 1,1,1)
            end
            if t.LastSeen then
                local d = date("%d.%m.%Y %H:%M", t.LastSeen)
                GameTooltip:AddDoubleLine(L["ct_last_seen"] or "Last seen", d, 0.8,0.8,0.8, 0.7,0.7,0.7)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return hRow
end

-- ============================================================
-- Main view
-- ============================================================
function AklimeMod_CT_Refresh()
    CreateUI()
    ClearContent()
    view = "main"
    if mainFrame and mainFrame.charBtn then mainFrame.charBtn:SetText(L["ct_btn_chars"] or "Characters") end

    local trackerDB = GetDataDB()
    if not trackerDB then
        local fs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", contentFrame, "CENTER")
        fs:SetText(L["ct_no_data"] or "No data. Log in with your characters.")
        fs:SetTextColor(0.7, 0.7, 0.7, 1)
        contentFrame:Show(); return
    end

    local sel = GetSelectedChars()
    if #sel == 0 then
        local fs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", contentFrame, "CENTER")
        fs:SetText(L["ct_no_chars"] or "No characters selected.\nClick 'Characters'.")
        fs:SetTextColor(0.7, 0.7, 0.7, 1)
        contentFrame:Show(); return
    end

    -- Adjust window width
    local totalW = LAB_W + PAD + #sel * COL_W + 40
    mainFrame:SetWidth(math.max(700, totalW))
    contentFrame:SetWidth(math.max(660, totalW - 40))

    local colX = LAB_W + PAD
    local y    = 4

    -- Character header with hover tooltip
    MkCharHeader(contentFrame, y, colX, sel, trackerDB)
    y = y + ROW_H

    -- ── Great Vault ───────────────────────────────────────────
    local hasVaultData = false
    for _, ch in ipairs(sel) do
        local toon = trackerDB.Toons[ch]
        if toon and toon.weeklyVault then hasVaultData = true; break end
    end

    if hasVaultData then
        y = y + 4
        local vHdr = MkHdr(contentFrame, y)
        local vFs = vHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        vFs:SetPoint("LEFT", vHdr, "LEFT", 8, 0)
        vFs:SetText(NORMAL_FONT_COLOR_CODE .. (L["vault_header"] or "Great Vault") .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        local VAULT_ROWS = {
            { key = "raid",    label = L["vault_raids"]    or "Raids"            },
            { key = "dungeon", label = L["vault_dungeons"] or "Dungeons"         },
            { key = "world",   label = L["vault_world"]    or "World Activities" },
        }
        for ri, vr in ipairs(VAULT_ROWS) do
            local row = MkRow(contentFrame, y, ri%2==0)
            MkTxt(row, NORMAL_FONT_COLOR_CODE .. vr.label .. FONT_COLOR_CODE_CLOSE,
                8, LAB_W - 4, "GameFontNormalSmall", "LEFT")
            for ci, ch in ipairs(sel) do
                local toon = trackerDB.Toons[ch]
                local vault = toon and toon.weeklyVault
                local slots = vault and vault[vr.key]
                local txt
                if slots == nil then
                    txt = GRAY_FONT_COLOR_CODE .. "-" .. FONT_COLOR_CODE_CLOSE
                elseif slots >= 3 then
                    txt = GREEN_FONT_COLOR_CODE .. "3/3" .. FONT_COLOR_CODE_CLOSE
                elseif slots > 0 then
                    txt = NORMAL_FONT_COLOR_CODE .. slots .. "/3" .. FONT_COLOR_CODE_CLOSE
                else
                    txt = GRAY_FONT_COLOR_CODE .. "0/3" .. FONT_COLOR_CODE_CLOSE
                end
                MkTxt(row, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
            end
            y = y + ROW_H
        end

        -- Fourth row: open = reward available but not yet collected.
        -- If the character has not logged in since the last reset, the stored
        -- hasRewards flag is stale (it reflects the state before the reset).
        -- In that case, fall back to the last known per-category completion:
        -- completing at least one activity guarantees a vault reward for the
        -- new week, so this can be deduced without the character logging in.
        local lastReset = GetLastWeeklyReset()
        local rewardRow = MkRow(contentFrame, y, false)
        MkTxt(rewardRow, NORMAL_FONT_COLOR_CODE .. (L["vault_reward"] or "Reward") .. FONT_COLOR_CODE_CLOSE,
            8, LAB_W - 4, "GameFontNormalSmall", "LEFT")
        for ci, ch in ipairs(sel) do
            local toon = trackerDB.Toons[ch]
            local vault = toon and toon.weeklyVault
            local staleSinceReset = vault and lastReset and (not toon.LastSeen or toon.LastSeen < lastReset)
            local hasOpenReward
            if staleSinceReset then
                hasOpenReward = (vault.raid and vault.raid > 0)
                    or (vault.dungeon and vault.dungeon > 0)
                    or (vault.world and vault.world > 0)
            else
                hasOpenReward = vault and vault.hasRewards
            end
            local txt
            if hasOpenReward then
                txt = GREEN_FONT_COLOR_CODE .. (L["vault_open"] or "Open") .. FONT_COLOR_CODE_CLOSE
            else
                txt = GRAY_FONT_COLOR_CODE .. "-" .. FONT_COLOR_CODE_CLOSE
            end
            MkTxt(rewardRow, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
        end
        y = y + ROW_H
    end

    -- ── Raids ─────────────────────────────────────────────────
    local raidsByExp = BuildRaids(sel)
    local expIDs = {}
    for e in pairs(raidsByExp) do expIDs[#expIDs+1] = e end
    table.sort(expIDs, function(a,b) return a > b end)

    if #expIDs > 0 then
        y = y + 4
        local raidHdr = MkHdr(contentFrame, y)
        local secFs = raidHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        secFs:SetPoint("LEFT", raidHdr, "LEFT", 8, 0)
        secFs:SetText(NORMAL_FONT_COLOR_CODE .. (L["ct_sec_raids"] or "Raids") .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        for _, exp in ipairs(expIDs) do
            -- Divider + expansion header (same style as realm)
            y = y + 4
            local sep = contentFrame:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -y)
            sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -y)
            sep:SetColorTexture(0.4, 0.35, 0.1, 0.7)
            y = y + 2
            local expHdr = MkHdr(contentFrame, y)
            local expFs  = expHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            expFs:SetPoint("LEFT", expHdr, "LEFT", 8, 0)
            expFs:SetText(NORMAL_FONT_COLOR_CODE .. (EXP_NAMES[exp] or ("Expansion "..exp)) .. FONT_COLOR_CODE_CLOSE)
            y = y + ROW_H + 2

            for ri, raid in ipairs(raidsByExp[exp]) do
                local activeDiffs = {}
                for _, d in ipairs(DIFF_ORDER) do
                    if raid.diffs[d] then activeDiffs[#activeDiffs+1] = d end
                end

                for _, diff in ipairs(activeDiffs) do
                    local diffLabel = GetDiffLabel(raid.inst, diff) or ("D"..diff)
                    local dc        = DIFF_COLOR[diff] or {r=1,g=1,b=1}
                    local dcHex     = string.format("|cFF%02x%02x%02x", dc.r*255, dc.g*255, dc.b*255)

                    -- Name: append abbreviation when multiple difficulties exist
                    local displayName = raid.name
                    if #activeDiffs > 1 then
                        displayName = raid.name .. " " .. dcHex .. "[" .. diffLabel .. "]" .. FONT_COLOR_CODE_CLOSE
                    end

                    local row = MkRow(contentFrame, y, ri%2==0)

                    local anySaved = false
                    for _, ch in ipairs(sel) do
                        if raid.diffs[diff] and raid.diffs[diff][ch] then anySaved = true; break end
                    end

                    MkTxt(row,
                        (anySaved and NORMAL_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE)
                        .. displayName .. FONT_COLOR_CODE_CLOSE,
                        8, LAB_W - 4, "GameFontNormalSmall", "LEFT")

                    for ci, ch in ipairs(sel) do
                        local save = raid.diffs[diff] and raid.diffs[diff][ch]
                        local txt  = ""
                        if save then
                            local killed = GetBossKills(save)
                            local total  = GetBossTotal(save)

                            if total > 0 then
                                txt = dcHex .. killed .. "/" .. total .. FONT_COLOR_CODE_CLOSE
                            else
                                txt = dcHex .. (killed > 0 and tostring(killed) or "L") .. FONT_COLOR_CODE_CLOSE
                            end

                            -- Hover button for boss list
                            local btn = CreateFrame("Button", nil, row)
                            btn:SetSize(COL_W, ROW_H)
                            btn:SetPoint("LEFT", row, "LEFT", colX + (ci-1)*COL_W, 0)
                            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                            fs:SetAllPoints(btn)
                            fs:SetJustifyH("CENTER")
                            fs:SetText(txt)

                            local saveRef = save
                            local raidName = raid.name
                            local charName = ch
                            local diffLabel2 = diffLabel
                            local dc2 = dc
                            btn:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                                GameTooltip:ClearLines()
                                -- Header
                                GameTooltip:AddLine(NORMAL_FONT_COLOR_CODE .. raidName .. FONT_COLOR_CODE_CLOSE
                                    .. "  " .. string.format("|cFF%02x%02x%02x%s|r",
                                        dc2.r*255, dc2.g*255, dc2.b*255, diffLabel2))
                                local toon = trackerDB and trackerDB.Toons and trackerDB.Toons[charName]
                                if toon then
                                    local r, g, b = ToonClassCol(toon)
                                    GameTooltip:AddLine(string.format("|cFF%02x%02x%02x%s|r",
                                        r*255, g*255, b*255, ShortName(charName)))
                                end
                                -- Verbleibende Zeit
                                if saveRef.Expires and saveRef.Expires > time() then
                                    local secs = saveRef.Expires - time()
                                    local h = math.floor(secs / 3600)
                                    local m = math.floor((secs % 3600) / 60)
                                    GameTooltip:AddDoubleLine(L["ct_raid_expires"] or "Time remaining:",
                                        string.format("%d Std. %d Min.", h, m),
                                        0.8,0.8,0.8, 1,0.82,0)
                                end
                                GameTooltip:AddLine(" ")
                                -- Boss list from stored save.bosses (from DataCollector)
                                if saveRef.bosses and #saveRef.bosses > 0 then
                                    for _, boss in ipairs(saveRef.bosses) do
                                        if boss.killed then
                                            GameTooltip:AddDoubleLine(boss.name, L["ct_boss_killed"] or "Defeated", 1,1,1, 1,0.2,0.2)
                                        else
                                            GameTooltip:AddDoubleLine(boss.name, L["ct_boss_avail"] or "Available", 1,1,1, 0.2,1,0.2)
                                        end
                                    end
                                elseif saveRef.Link then
                                    -- Fallback: boss names via LFG API
                                    local lid = saveRef.Link:match("instancelock:[^:]+:(%d+):")
                                    lid = lid and tonumber(lid)
                                    if lid then
                                        local ok2, bossCount = pcall(GetLFGDungeonNumEncounters, lid)
                                        if ok2 and bossCount and bossCount > 0 then
                                            for bi = 1, bossCount do
                                                local bossName = GetLFGDungeonEncounterInfo(lid, bi)
                                                if bossName then
                                                    GameTooltip:AddLine(bossName, 0.8, 0.8, 0.8)
                                                end
                                            end
                                        end
                                    end
                                end
                                GameTooltip:Show()
                            end)
                            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        else
                            MkTxt(row, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
                        end
                    end
                    y = y + ROW_H
                end
            end
        end
    end

    -- ── Currencies ───────────────────────────────────────────
    local currencies = BuildCurrencies(sel)
    if #currencies > 0 then
        y = y + 4
        local wHdr = MkHdr(contentFrame, y)
        local wFs  = wHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wFs:SetPoint("LEFT", wHdr, "LEFT", 8, 0)
        wFs:SetText(NORMAL_FONT_COLOR_CODE .. (L["ct_sec_currencies"] or "Currencies") .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        local lastExp = -999  -- sentinel that never matches
        for ri, ce in ipairs(currencies) do
            if ce.exp ~= lastExp then
                lastExp = ce.exp
                -- Divider
                y = y + 4
                local sep = contentFrame:CreateTexture(nil, "ARTWORK")
                sep:SetHeight(1)
                sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -y)
                sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -y)
                sep:SetColorTexture(0.4, 0.35, 0.1, 0.7)
                y = y + 2
                -- Expansion header (same style as realm header)
                local eHdr = MkHdr(contentFrame, y)
                local eFs  = eHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                eFs:SetPoint("LEFT", eHdr, "LEFT", 8, 0)
                eFs:SetText(NORMAL_FONT_COLOR_CODE .. (EXP_NAMES[ce.exp] or ("Expansion "..ce.exp)) .. FONT_COLOR_CODE_CLOSE)
                y = y + ROW_H + 2
            end

            local row = MkRow(contentFrame, y, ri%2==0)
            -- Icon + Name
            local iconStr = ce.icon and ("|T" .. ce.icon .. ":14:14:0:0|t ") or ""
            MkTxt(row, iconStr .. NORMAL_FONT_COLOR_CODE .. ce.name .. FONT_COLOR_CODE_CLOSE,
                8, LAB_W - 4, "GameFontNormalSmall", "LEFT")

            for ci, ch in ipairs(sel) do
                local toon = trackerDB.Toons[ch]
                local amt  = toon and toon.currency and toon.currency[ce.id]
                           and toon.currency[ce.id].amount
                local txt
                if amt and amt > 0 then
                    txt = GREEN_FONT_COLOR_CODE .. FormatAmount(amt) .. FONT_COLOR_CODE_CLOSE
                else
                    txt = GRAY_FONT_COLOR_CODE .. "-" .. FONT_COLOR_CODE_CLOSE
                end

                -- Hover button: show all characters for this currency
                local btn = CreateFrame("Button", nil, row)
                btn:SetSize(COL_W, ROW_H)
                btn:SetPoint("LEFT", row, "LEFT", colX + (ci-1)*COL_W, 0)
                local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetAllPoints(btn); fs:SetJustifyH("CENTER"); fs:SetText(txt)

                local ceid = ce.id
                local ceicon = ce.icon
                local cename = ce.name
                local allSel = sel
                btn:SetScript("OnEnter", function(self)
                    local db2 = GetDataDB()
                    if not db2 then return end
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:ClearLines()
                    local iStr = ceicon and ("|T"..ceicon..":14:14|t ") or ""
                    GameTooltip:AddLine(iStr .. NORMAL_FONT_COLOR_CODE .. cename .. FONT_COLOR_CODE_CLOSE)
                    GameTooltip:AddLine(" ")
                    local total = 0
                    for _, charName in ipairs(allSel) do
                        local t = db2.Toons[charName]
                        local a = t and t.currency and t.currency[ceid] and t.currency[ceid].amount
                        if a and a > 0 then
                            local r2,g2,b2 = ToonClassCol(t)
                            local nameStr = string.format("|cFF%02x%02x%02x%s|r", r2*255,g2*255,b2*255, ShortName(charName))
                            GameTooltip:AddDoubleLine(nameStr,
                                GREEN_FONT_COLOR_CODE .. FormatAmount(a) .. FONT_COLOR_CODE_CLOSE,
                                1,1,1, 1,1,1)
                            total = total + a
                        end
                    end
                    if total > 0 then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddDoubleLine(
                            "|cFFFFFFFF" .. (L["ct_currency_total"] or "Total") .. "|r",
                            "|cFFFFD100" .. FormatAmount(total) .. FONT_COLOR_CODE_CLOSE,
                            1,1,1, 1,1,1)
                    end
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            y = y + ROW_H
        end
    end

    y = y + 12
    contentFrame:SetHeight(y)
    contentFrame:Show()
end

-- ============================================================
-- Character selection
-- ============================================================
function AklimeMod_CT_ShowChars()
    CreateUI()
    ClearContent()
    view = "chars"
    if mainFrame and mainFrame.charBtn then mainFrame.charBtn:SetText(L["ct_btn_overview"] or "Overview") end

    local trackerDB = GetDataDB()
    local myDB = GetDB()
    if not trackerDB or not trackerDB.Toons or not myDB then
        contentFrame:Show(); return
    end
    myDB.chars = myDB.chars or {}

    local toons = {}
    for name, data in pairs(trackerDB.Toons) do
        toons[#toons+1] = { name=name, data=data }
    end
    table.sort(toons, function(a, b)
        local ra = a.name:match("%-(.+)$") or ""
        local rb = b.name:match("%-(.+)$") or ""
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)

    local y = 10
    local hdr = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -y)
    hdr:SetWidth(contentFrame:GetWidth() - 16)
    hdr:SetText(NORMAL_FONT_COLOR_CODE .. (L["ct_char_hint"] or "Selecting a character sets the checkmark. Checked characters are shown in the overview.") .. FONT_COLOR_CODE_CLOSE)
    y = y + 30

    local chdr = MkHdr(contentFrame, y)
    MkTxt(chdr, L["ct_col_char"] or "Character", 36, 200, "GameFontNormal")
    MkTxt(chdr, L["ct_col_class"] or "Class",   240, 130, "GameFontNormal")
    MkTxt(chdr, "Level",    375,  50, "GameFontNormal")
    MkTxt(chdr, "iLvl",     430,  55, "GameFontNormal")
    y = y + ROW_H + 2

    local lastRealm = nil
    for ri, entry in ipairs(toons) do
        local name  = entry.name
        local data  = entry.data
        local realm = name:match("%-(.+)$") or ""

        -- Realm header BEFORE the characters of this realm
        if realm ~= lastRealm then
            lastRealm = realm
            -- Divider
            y = y + 4
            local sep = contentFrame:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -y)
            sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -y)
            sep:SetColorTexture(0.4, 0.35, 0.1, 0.7)
            y = y + 2
            -- Realm name
            local rHdr = MkHdr(contentFrame, y)
            local rFs = rHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rFs:SetPoint("LEFT", rHdr, "LEFT", 8, 0)
            rFs:SetText(NORMAL_FONT_COLOR_CODE .. (realm ~= "" and realm or "?") .. FONT_COLOR_CODE_CLOSE)
            y = y + ROW_H + 2
        end

        local row = MkRow(contentFrame, y, ri%2==0)

        -- Selection highlight (greenish when selected)
        local selBg = row:CreateTexture(nil, "BACKGROUND")
        selBg:SetAllPoints()
        selBg:SetColorTexture(0.08, 0.35, 0.08, 0.45)
        selBg:SetShown(myDB.chars[name] == true)

        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", row, "LEFT", 8, 0)
        cb:SetChecked(myDB.chars[name] == true)
        local n = name
        local function toggleChar()
            local newVal = not (myDB.chars[n] == true)
            myDB.chars[n] = newVal and true or nil
            cb:SetChecked(newVal)
            selBg:SetShown(newVal)
        end
        cb:SetScript("OnClick", function(self)
            myDB.chars[n] = self:GetChecked() and true or nil
            selBg:SetShown(self:GetChecked())
        end)
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(_, btn)
            if btn == "LeftButton" then toggleChar() end
        end)

        local dispName = ShortName(name)
        local r, g, b = ToonClassCol(data)
        MkTxt(row, string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, dispName),
            36, 200, "GameFontNormalSmall")
        -- Class: first letter uppercase
        local classDisp = data.Class and (data.Class:sub(1,1):upper() .. data.Class:sub(2):lower()) or "-"
        MkTxt(row, classDisp, 240, 130, "GameFontNormalSmall")
        MkTxt(row, tostring(data.Level or "-"), 375, 50, "GameFontNormalSmall")
        MkTxt(row, data.IL and string.format("%.0f", data.IL) or "-", 430, 55, "GameFontNormalSmall")

        -- Delete button
        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(60, 16)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn:SetText(L["ct_btn_delete"] or "Delete")
        delBtn:GetFontString():SetTextColor(1, 0.3, 0.3)
        local delName = name
        delBtn:SetScript("OnClick", function()
            -- Remove from selection and from tracker DB
            if myDB.chars then myDB.chars[delName] = nil end
            local tdb = AklimeModDB and AklimeModDB.tracker
            if tdb then
                if tdb.Toons then tdb.Toons[delName] = nil end
                if tdb.Instances then
                    for _, inst in pairs(tdb.Instances) do
                        inst[delName] = nil
                    end
                end
            end
            AklimeMod_CT_ShowChars()
        end)
        y = y + ROW_H
    end

    y = y + 8
    local btnAll = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btnAll:SetSize(130, 22); btnAll:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -y)
    btnAll:SetText(L["ct_btn_select_all"] or "Select all")
    btnAll:SetScript("OnClick", function()
        for _, e in ipairs(toons) do myDB.chars[e.name] = true end
        AklimeMod_CT_ShowChars()
    end)

    local btnNone = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btnNone:SetSize(130, 22); btnNone:SetPoint("LEFT", btnAll, "RIGHT", 6, 0)
    btnNone:SetText(L["ct_btn_deselect_all"] or "Deselect all")
    btnNone:SetScript("OnClick", function()
        myDB.chars = {}; AklimeMod_CT_ShowChars()
    end)

    local btnOK = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btnOK:SetSize(110, 22); btnOK:SetPoint("LEFT", btnNone, "RIGHT", 6, 0)
    btnOK:SetText(L["ct_btn_apply"] or "Apply")
    btnOK:SetScript("OnClick", function()
        view = "main"; AklimeMod_CT_Refresh()
    end)

    y = y + 30
    contentFrame:SetHeight(y + 10)
    contentFrame:Show()
end

-- ============================================================
-- Toggle
-- ============================================================
function AklimeMod_CT_Toggle()
    CreateUI()
    if mainFrame:IsShown() then mainFrame:Hide()
    else AklimeMod_CT_Refresh(); mainFrame:Show() end
end