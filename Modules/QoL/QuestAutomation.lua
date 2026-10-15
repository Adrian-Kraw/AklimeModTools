-- Modules/QoL/QuestAutomation.lua
-- Automatically accept and turn in quests during NPC dialog.
-- Modifier key configurable. Filters for daily/trivial/warband quests.
-- Wowhead URL button in the quest right-click menu.
-- NPC ignore list via right-click on the target.

local L = AklimeModL or {}

local function GetDB()
    if AklimeModDB and AklimeModDB.questAutomation then return AklimeModDB.questAutomation end
    return { enabled = false }
end

-- ============================================================
-- Helpers
-- ============================================================

local function GetNPCIDFromGUID(guid)
    if not guid then return nil end
    local ok, t, _, _, _, _, npcID = pcall(strsplit, "-", guid)
    if not ok then return nil end
    if t == "Creature" or t == "Vehicle" then return tonumber(npcID) end
    return nil
end

local function IsModifierHeld(modifier)
    if modifier == "SHIFT" then return IsShiftKeyDown()   end
    if modifier == "CTRL"  then return IsControlKeyDown() end
    if modifier == "ALT"   then return IsAltKeyDown()     end
    return false
end

local function ShouldAutoQuest()
    local db = GetDB()
    if not db.enabled then return false end
    local mod = db.modifier or "NONE"
    if mod == "SHIFT" or mod == "CTRL" or mod == "ALT" then
        return IsModifierHeld(mod)
    end
    -- NONE: always automatic, unless Shift is held (legacy protection)
    return not IsShiftKeyDown()
end

local function IsNPCIgnored()
    local db = GetDB()
    if not db.ignoredNPCs then return false end
    local npcID = GetNPCIDFromGUID(UnitGUID("npc"))
    return npcID ~= nil and db.ignoredNPCs[npcID] ~= nil
end

local function IsDaily(questID, frequency)
    if frequency and frequency > 0 then return true end
    if not (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification) then return false end
    local c = C_QuestInfoSystem.GetQuestClassification(questID)
    return c == Enum.QuestClassification.Recurring or c == Enum.QuestClassification.Calling
end

local function IsWeekly(questID)
    if not (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification) then return false end
    return C_QuestInfoSystem.GetQuestClassification(questID) == Enum.QuestClassification.Weekly
end

local function ShouldFilterQuest(questID, isTrivial, frequency)
    local db = GetDB()
    local daily = IsDaily(questID, frequency)
    if daily     and not db.acceptDailies then return true end
    if not daily and not db.acceptNormal  then return true end
    if db.ignoreTrivial and isTrivial then return true end
    if db.ignoreWarband
        and C_QuestLog
        and C_QuestLog.IsQuestFlaggedCompletedOnAccount
        and C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID)
    then return true end
    return false
end

-- ============================================================
-- Event-Handler
-- ============================================================

local acceptQuestIDs = {}

local function OnGossipShow()
    if not ShouldAutoQuest() then return end
    if IsNPCIgnored() then return end


    local hasActive    = C_GossipInfo.GetNumActiveQuests() > 0
    local available    = C_GossipInfo.GetAvailableQuests()
    local hasAvailable = #available > 0

    -- Turn in completed active quests
    if hasActive then
        for _, quest in pairs(C_GossipInfo.GetActiveQuests()) do
            if quest.isComplete then
                C_GossipInfo.SelectActiveQuest(quest.questID)
            end
        end
    end

    -- Accept available quests
    if hasAvailable then
        for _, quest in pairs(available) do
            if not ShouldFilterQuest(quest.questID, quest.isTrivial, quest.frequency) then
                C_GossipInfo.SelectAvailableQuest(quest.questID)
            end
        end
        return
    end

end

local function OnQuestGreeting()
    if not ShouldAutoQuest() then return end
    if IsNPCIgnored() then return end
    for i = 1, GetNumAvailableQuests() do
        if not (GetDB().ignoreTrivial and IsAvailableQuestTrivial(i)) then
            SelectAvailableQuest(i)
        end
    end
    for i = 1, GetNumActiveQuests() do
        if select(2, GetActiveTitle(i)) then SelectActiveQuest(i) end
    end
end

local function OnQuestDetail()
    if not ShouldAutoQuest() then return end
    if IsNPCIgnored() then return end
    local id = GetQuestID()
    if id then
        acceptQuestIDs[id] = true
        C_QuestLog.RequestLoadQuestByID(id)
    end
end

local function OnQuestDataLoadResult(questID)
    if not questID or not acceptQuestIDs[questID] then return end
    if not GetDB().enabled then return end
    acceptQuestIDs[questID] = nil
    if IsNPCIgnored() then return end
    local db = GetDB()
    local daily = IsDaily(questID, nil)
    if daily     and not db.acceptDailies then return end
    if not daily and not db.acceptNormal  then return end
    if db.ignoreTrivial and C_QuestLog.IsQuestTrivial and C_QuestLog.IsQuestTrivial(questID) then return end
    if db.ignoreWarband and C_QuestLog.IsQuestFlaggedCompletedOnAccount and C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then return end
    AcceptQuest()
    if QuestFrame and QuestFrame:IsShown() then QuestFrame:Hide() end
end

local function OnQuestProgress()
    if ShouldAutoQuest() and IsQuestCompletable() then CompleteQuest() end
end

local function ShouldAutoTurnIn(questID)
    local db = GetDB()
    if not db.autoTurnIn then return false end
    if db.ignoreDailiesTurnIn  and IsDaily(questID, nil) then return false end
    if db.ignoreWeekliesTurnIn and IsWeekly(questID)     then return false end
    return true
end

local function OnQuestComplete()
    if not ShouldAutoQuest() then return end
    if GetNumQuestChoices() > 1 then return end
    if not ShouldAutoTurnIn(GetQuestID()) then return end
    GetQuestReward(1)
end

-- ============================================================
-- Wowhead link in the quest context menu
-- ============================================================

local menuHooked = false

local function ShowCopyDialog(url)
    if not StaticPopupDialogs["AKLIMEMOD_COPY_URL"] then
        StaticPopupDialogs["AKLIMEMOD_COPY_URL"] = {
            text     = L["quest_copy_label"],
            button1  = OKAY,
            hasEditBox   = true,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnShow = function(self, data)
                local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
                if eb then
                    eb:SetAutoFocus(true)
                    eb:SetText(data or "")
                    eb:HighlightText()
                    eb:SetCursorPosition(0)
                end
            end,
            OnAccept = function() end,
            EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        }
    end
    StaticPopup_Show("AKLIMEMOD_COPY_URL", nil, nil, url)
end

local function GetQuestIDFromContext(owner, ctx)
    if ctx and (ctx.questID or ctx.questId) then return ctx.questID or ctx.questId end
    if owner then
        if owner.questID then return owner.questID end
        if owner.GetQuestID then
            local ok, id = pcall(owner.GetQuestID, owner)
            if ok and id then return id end
        end
        if owner.questLogIndex and C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(owner.questLogIndex)
            if info and info.questID then return info.questID end
        end
    end
    return nil
end

local function HookMenus()
    if menuHooked then return end
    if not Menu or not Menu.ModifyMenu then return end
    menuHooked = true

    local function AddWowheadEntry(owner, root, ctx)
        if not GetDB().wowheadLink then return end
        local qid
        if owner.GetName and owner:GetName() == "ObjectiveTrackerFrame" then
            local foci = GetMouseFoci()
            if foci and foci[1] and foci[1].GetParent then
                local parent = foci[1]:GetParent()
                if parent.poiQuestID then qid = parent.poiQuestID
                else return end
            end
        else
            qid = GetQuestIDFromContext(owner, ctx)
        end
        if not qid then return end
        root:CreateDivider()
        root:CreateButton(L["quest_copy_wowhead"], function()
            ShowCopyDialog(("https://www.wowhead.com/quest=%d"):format(qid))
        end)
    end

    Menu.ModifyMenu("MENU_QUEST_MAP_LOG_TITLE",     AddWowheadEntry)
    Menu.ModifyMenu("MENU_QUEST_OBJECTIVE_TRACKER", AddWowheadEntry)

    -- NPC ignore list via right-click on the target
    Menu.ModifyMenu("MENU_UNIT_TARGET", function(owner, root, ctx)
        if not GetDB().enabled then return end
        if not UnitExists("target") or UnitPlayerControlled("target") then return end
        local guid = UnitGUID("target")
        local npcID = GetNPCIDFromGUID(guid)
        if not npcID then return end
        local name = UnitName("target")
        if not name then return end
        local db = GetDB()
        db.ignoredNPCs = db.ignoredNPCs or {}
        root:CreateDivider()
        root:CreateTitle("Aklime Mod Tools")
        if db.ignoredNPCs[npcID] then
            root:CreateButton(L["quest_npc_ignore_remove"], function()
                db.ignoredNPCs[npcID] = nil
            end)
        else
            root:CreateButton(L["quest_npc_ignore_add"], function()
                db.ignoredNPCs[npcID] = name
            end)
        end
    end)
end

-- ============================================================
-- API
-- ============================================================

local M = {}
AklimeMod_QuestAutomation = M

function M:IsEnabled()              return GetDB().enabled              == true end
function M:GetModifier()            return GetDB().modifier             or "NONE" end
function M:IsAcceptNormal()         return GetDB().acceptNormal         ~= false end
function M:IsAcceptDailies()        return GetDB().acceptDailies        == true end
function M:IsIgnoreTrivial()        return GetDB().ignoreTrivial        == true end
function M:IsIgnoreWarband()        return GetDB().ignoreWarband        == true end
function M:IsWowheadLink()          return GetDB().wowheadLink          == true end
function M:IsAutoTurnIn()           return GetDB().autoTurnIn           == true end
function M:IsIgnoreDailiesTurnIn()  return GetDB().ignoreDailiesTurnIn  == true end
function M:IsIgnoreWeekliesTurnIn() return GetDB().ignoreWeekliesTurnIn == true end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    HookMenus()
end

function M:SetModifier(v)              GetDB().modifier             = v end
function M:SetAcceptNormal(v)          GetDB().acceptNormal         = v and true or false end
function M:SetAcceptDailies(v)         GetDB().acceptDailies        = v and true or false end
function M:SetIgnoreTrivial(v)         GetDB().ignoreTrivial        = v and true or false end
function M:SetIgnoreWarband(v)         GetDB().ignoreWarband        = v and true or false end
function M:SetAutoTurnIn(v)            GetDB().autoTurnIn           = v and true or false end
function M:SetIgnoreDailiesTurnIn(v)   GetDB().ignoreDailiesTurnIn  = v and true or false end
function M:SetIgnoreWeekliesTurnIn(v)  GetDB().ignoreWeekliesTurnIn = v and true or false end

function M:SetWowheadLink(v)
    GetDB().wowheadLink = v and true or false
    HookMenus()
end

function M:GetIgnoredNPCs()        return GetDB().ignoredNPCs or {} end
function M:ClearIgnoredNPCs()      GetDB().ignoredNPCs = {} end

-- ============================================================
-- Init
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, _, _)
    local db = GetDB()
    if db.enabled or db.wowheadLink then HookMenus() end
    self:UnregisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("GOSSIP_SHOW")
    self:RegisterEvent("QUEST_GREETING")
    self:RegisterEvent("QUEST_DETAIL")
    self:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    self:RegisterEvent("QUEST_PROGRESS")
    self:RegisterEvent("QUEST_COMPLETE")
    self:SetScript("OnEvent", function(_, event, arg1)
        if     event == "GOSSIP_SHOW"            then OnGossipShow()
        elseif event == "QUEST_GREETING"          then OnQuestGreeting()
        elseif event == "QUEST_DETAIL"            then OnQuestDetail()
        elseif event == "QUEST_DATA_LOAD_RESULT"  then OnQuestDataLoadResult(arg1)
        elseif event == "QUEST_PROGRESS"          then OnQuestProgress()
        elseif event == "QUEST_COMPLETE"          then OnQuestComplete()
        end
    end)
end)
