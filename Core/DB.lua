-- Core/DB.lua
-- Note: the Colorizer DB is populated by ColorizerCore.lua:InitDB().
-- This file holds only the remaining addon settings.

AklimeModDB = AklimeModDB or {}

local function def(t, k, v)
    if t[k] == nil then t[k] = v end
end

function AklimeMod_InitDB()
    local db = AklimeModDB
    def(db, "minimapAngle", 220)

    db.autoRepair = db.autoRepair or {}
    def(db.autoRepair, "enabled",  false)
    def(db.autoRepair, "useGuild", true)
    def(db.autoRepair, "useGold",  true)

    db.eliteFrame = db.eliteFrame or {}
    def(db.eliteFrame, "enabled", false)

    db.rareFrame = db.rareFrame or {}
    def(db.rareFrame, "enabled", false)

    db.raidFrameCenter = db.raidFrameCenter or {}
    def(db.raidFrameCenter, "enabled", false)
    def(db.raidFrameCenter, "offsetX",  0)

    db.chatInteraction = db.chatInteraction or {}
    def(db.chatInteraction, "copyPaste",  false)
    def(db.chatInteraction, "clickLinks", false)
    def(db.chatInteraction, "btnLocked",  false)

    db.dungeonEye = db.dungeonEye or {}
    def(db.dungeonEye, "enabled", false)
    def(db.dungeonEye, "locked",  false)

    db.reloadUI = db.reloadUI or {}
    def(db.reloadUI, "enabled", false)

    db.easyDelete = db.easyDelete or {}
    def(db.easyDelete, "skipDelete",     false)
    def(db.easyDelete, "skipConfirm",    false)
    def(db.easyDelete, "skipUnlearn",    false)
    def(db.easyDelete, "skipUnderstood", false)

    db.buyConfirm = db.buyConfirm or {}
    def(db.buyConfirm, "enabled", false)
    def(db.buyConfirm, "refundEnabled", false)
    def(db.buyConfirm, "noRefundEnabled", false)

    db.manaWarning = db.manaWarning or {}
    def(db.manaWarning, "enabled", false)

    db.autoSellJunk = db.autoSellJunk or {}
    def(db.autoSellJunk, "enabled", false)

    db.leaveServiceChannel = db.leaveServiceChannel or {}
    def(db.leaveServiceChannel, "enabled", false)
    def(db.leaveServiceChannel, "repaired", false)

    db.mapCoords = db.mapCoords or {}
    def(db.mapCoords, "enabled", false)  -- Default: on

    db.drinkReminder = db.drinkReminder or {}
    def(db.drinkReminder, "enabled",           false)
    def(db.drinkReminder, "intervalMinutes",   60)
    def(db.drinkReminder, "disableInInstance", true)

    db.clock24h = db.clock24h or {}
    def(db.clock24h, "enabled", false)

    db.preyPercent = db.preyPercent or {}
    def(db.preyPercent, "enabled", false)
    def(db.preyPercent, "x", 0)
    def(db.preyPercent, "y", 120)

    db.savedInstances = db.savedInstances or {}
    db.savedInstances.chars      = db.savedInstances.chars      or {}
    db.savedInstances.raids      = db.savedInstances.raids      or {}
    db.savedInstances.currencies = db.savedInstances.currencies or {}
    db.savedInstances.raidExps   = db.savedInstances.raidExps   or {}

    db.hideMacroNames = db.hideMacroNames or {}
    def(db.hideMacroNames, "enabled", false)

    db.hideMicroNotifications = db.hideMicroNotifications or {}
    def(db.hideMicroNotifications, "enabled", false)

    db.damageMeterCollapseDown = db.damageMeterCollapseDown or {}
    def(db.damageMeterCollapseDown, "enabled", false)
    db.damageMeterCollapseDown.windows = db.damageMeterCollapseDown.windows or {}

    db.minimapCollector = db.minimapCollector or {}
    def(db.minimapCollector, "enabled",     false)
    def(db.minimapCollector, "includeOwn",  false)
    def(db.minimapCollector, "angle",       143)
    def(db.minimapCollector, "locked",      false)

    db.minimapHider = db.minimapHider or {}
    def(db.minimapHider, "enabled", false)
    def(db.minimapHider, "tracking", false)
    def(db.minimapHider, "zoneInfo", false)
    def(db.minimapHider, "clock", false)
    def(db.minimapHider, "calendar", false)
    def(db.minimapHider, "mail", false)
    def(db.minimapHider, "addonCompartment", false)

    db.mouseEffects = db.mouseEffects or {}
    def(db.mouseEffects, "enabled", false)
    def(db.mouseEffects, "trail", false)
    def(db.mouseEffects, "classColor", true)
    db.mouseEffects.customColor = db.mouseEffects.customColor or { r = 1, g = 0.82, b = 0, a = 0.9 }
    def(db.mouseEffects, "trailClassColor", true)
    db.mouseEffects.customTrailColor = db.mouseEffects.customTrailColor or { r = 1, g = 0.82, b = 0, a = 0.85 }
    def(db.mouseEffects, "hideDot",  false)
    def(db.mouseEffects, "hideRing", false)
    def(db.mouseEffects, "onlyCombat", false)
    def(db.mouseEffects, "onlyRightClick", false)
    def(db.mouseEffects, "trailOnlyCombat", false)
    def(db.mouseEffects, "size", 76)
    def(db.mouseEffects, "trailPreset", "medium")

    db.merchant = db.merchant or {}
    def(db.merchant, "enabled", false)

    db.chatLearnFilter = db.chatLearnFilter or {}
    def(db.chatLearnFilter, "enabled",          false)
    def(db.chatLearnFilter, "hideTalentBubble", false)

    db.chatIcons = db.chatIcons or {}
    def(db.chatIcons, "enabled",    false)
    def(db.chatIcons, "itemLevel",  false)
    def(db.chatIcons, "showSlot",   false)

    db.chatFade = db.chatFade or {}
    def(db.chatFade, "enabled",      false)
    def(db.chatFade, "timeVisible",  30)
    def(db.chatFade, "fadeDuration", 3)

    db.friendsListDecor = db.friendsListDecor or {}
    def(db.friendsListDecor, "enabled",      false)
    def(db.friendsListDecor, "showLocation", true)
    def(db.friendsListDecor, "hideOwnRealm", true)

    db.chatFontSize = db.chatFontSize or {}
    def(db.chatFontSize, "enabled", false)
    def(db.chatFontSize, "size", 16)
    db.chatFontSize.appliedChars = db.chatFontSize.appliedChars or {}

    db.pvpChatBlock = db.pvpChatBlock or {}
    def(db.pvpChatBlock, "enabled", false)

    db.pvpNameplateColor = db.pvpNameplateColor or {}
    def(db.pvpNameplateColor, "enabled", false)

    db.savedInstances = db.savedInstances or {}
    db.savedInstances.chars = db.savedInstances.chars or {}

    db.questTracker = db.questTracker or {}
    def(db.questTracker, "showQuestCount",      false)
    def(db.questTracker, "questCountOffsetX",   0)
    def(db.questTracker, "questCountOffsetY",   0)
    def(db.questTracker, "minimizeButtonOnly",  false)
    def(db.questTracker, "minimizeButtonAnchor","TOPRIGHT")
    def(db.questTracker, "rememberState",       false)
    -- questTracker.collapsed: no default, set on the first state change

    db.blockRequests = db.blockRequests or {}
    def(db.blockRequests, "blockDuels",      false)
    def(db.blockRequests, "blockPetBattles", false)

    db.readyCheck = db.readyCheck or {}
    def(db.readyCheck, "enabled", false)
    def(db.readyCheck, "delay",   3)

    db.skipCinematic = db.skipCinematic or {}
    def(db.skipCinematic, "enabled", false)

    db.questAutomation = db.questAutomation or {}
    def(db.questAutomation, "enabled",        false)
    def(db.questAutomation, "modifier",       "NONE")
    def(db.questAutomation, "acceptNormal",   true)
    def(db.questAutomation, "acceptDailies",  false)
    def(db.questAutomation, "ignoreTrivial",  false)
    def(db.questAutomation, "ignoreWarband",  false)
    def(db.questAutomation, "wowheadLink",           false)
    def(db.questAutomation, "autoTurnIn",            false)
    def(db.questAutomation, "ignoreDailiesTurnIn",   false)
    def(db.questAutomation, "ignoreWeekliesTurnIn",  false)
    db.questAutomation.ignoredNPCs = db.questAutomation.ignoredNPCs or {}

    db.heroismTracker = db.heroismTracker or {}
    def(db.heroismTracker, "enabled",  false)
    def(db.heroismTracker, "locked",   true)
    def(db.heroismTracker, "fontSizeSlider", 20)

    db.deathSound = db.deathSound or {}
    def(db.deathSound, "enabled", false)

    db.talentReminder = db.talentReminder or {}
    def(db.talentReminder, "enabled", false)

    db.summons = db.summons or {}
    def(db.summons, "enabled", false)
    def(db.summons, "delay",   0)   -- 0 = accept right away

    db.chatHistory = db.chatHistory or {}
    def(db.chatHistory, "enabled",     false)
    def(db.chatHistory, "maxMessages", 100)
    db.chatHistory.messages = db.chatHistory.messages or {}

    db.extendedIgnore = db.extendedIgnore or {}
    def(db.extendedIgnore, "enabled", false)
    db.extendedIgnore.players = db.extendedIgnore.players or {}

    db.groupInvites = db.groupInvites or {}
    def(db.groupInvites, "block",             false)
    def(db.groupInvites, "blockExceptGuild",  false)
    def(db.groupInvites, "blockExceptFriend", false)
    def(db.groupInvites, "autoAccept",        false)
    def(db.groupInvites, "guildOnly",         false)
    def(db.groupInvites, "friendOnly",        false)

    db.mailbox = db.mailbox or {}
    def(db.mailbox, "enabled",                false)
    def(db.mailbox, "rememberLastRecipient",  false)
    def(db.mailbox, "lastSent",               "")
    db.mailbox.contacts = db.mailbox.contacts or {}

    db.todoList = db.todoList or {}
    db.todoList.items = db.todoList.items or {}

    db.gearCheck = db.gearCheck or {}
    def(db.gearCheck, "enabled", false)

    db.combatTooltip = db.combatTooltip or {}
    def(db.combatTooltip, "enabled",    false)
    def(db.combatTooltip, "allowAuras", false)

    db.bnetToastMover = db.bnetToastMover or {}
    def(db.bnetToastMover, "enabled", false)
    def(db.bnetToastMover, "locked",  true)

    db.actionBarCompact = db.actionBarCompact or {}
    def(db.actionBarCompact, "enabled", false)
    for i = 1, 8 do
        def(db.actionBarCompact, "bar" .. i, "off")
    end

    db.interfaceFade = db.interfaceFade or {}
    for i = 1, 3 do
        local k = "mode" .. i
        db.interfaceFade[k] = db.interfaceFade[k] or {}
        def(db.interfaceFade[k], "enabled", false)
        def(db.interfaceFade[k], "alpha",   60)
    end
    def(db.interfaceFade.mode1, "moveDelay", 1)
    def(db.interfaceFade.mode1, "idleDelay", 5)
    def(db.interfaceFade.mode1, "chatDelay", 5)
    def(db.interfaceFade.mode2, "moveDelay", 1)
    def(db.interfaceFade.mode2, "idleDelay", 5)
    def(db.interfaceFade.mode2, "chatDelay", 5)
    def(db.interfaceFade.mode3, "moveDelay", 1)
    def(db.interfaceFade.mode3, "idleDelay", 5)
    def(db.interfaceFade.mode3, "chatDelay", 5)
    for _, mk in ipairs({ "mode1", "mode2", "mode3" }) do
        db.interfaceFade[mk].exclude = db.interfaceFade[mk].exclude or {}
        local ex = db.interfaceFade[mk].exclude
        def(ex, "chat",        false)
        def(ex, "minimap",     false)
        def(ex, "objectives",  false)
        def(ex, "microMenu",   false)
        def(ex, "bags",        false)
        def(ex, "actionBars",  false)
        def(ex, "unitFrames",  false)
        def(ex, "buffs",       false)
        def(ex, "repBar",      false)
        def(ex, "damageMeter", false)
    end

    db.playedTime = db.playedTime or {}
    db.playedTime.chars = db.playedTime.chars or {}
    def(db.playedTime, "enabled", false)

    -- Colorizer: populated by AklimeMod_Colorizer:InitDB() (ColorizerCore.lua)
    db.colorizer = db.colorizer or {}
end
