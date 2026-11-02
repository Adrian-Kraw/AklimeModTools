-- Modules/QoL/ChatHistory.lua
-- Stores the chat history across sessions in SavedVariables
-- and restores it on the next login.
--
-- Storage location:
--   WTF/Account/<Account>/SavedVariables/AklimeMod.lua
--   AklimeModDB.chatHistory.messages["Name-Realm"].f1  (ChatFrame1)
--   AklimeModDB.chatHistory.messages["Name-Realm"].f2  (ChatFrame2) etc.
--
-- Format per entry: { t = "message text", r = 1, g = 1, b = 1 }

local M = {}
AklimeMod_ChatHistory = M

local MAX_DEFAULT    = 100
local MAX_MSG_LENGTH = 400   -- A single message is truncated to 400 characters
local EXPIRE_SECONDS = 30 * 24 * 60 * 60   -- History of inactive characters is deleted after 30 days
local restoring      = false
local hooked         = {}

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.chatHistory then
        return AklimeModDB.chatHistory
    end
    return {}
end

local function GetCharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

-- Returns db[field][charKey], created on demand. Field is "messages" or "signatures".
local function GetCharStore(db, field)
    db[field] = db[field] or {}
    local key = GetCharKey()
    db[field][key] = db[field][key] or {}
    return db[field][key]
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled()
    return GetDB().enabled == true
end

function M:GetMaxMessages()
    return GetDB().maxMessages or MAX_DEFAULT
end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    if v then self:HookFrames() end
end

function M:SetMaxMessages(v)
    GetDB().maxMessages = v
end

-- ============================================================
-- Hooks (set once per frame)
-- ============================================================
function M:HookFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        if not hooked[i] then
            local frame = _G["ChatFrame" .. i]
            if frame and frame.AddMessage then
                hooked[i] = true
                local idx = i
                hooksecurefunc(frame, "AddMessage", function(_, text, r, g, b)
                    if restoring then return end
                    local db = GetDB()
                    if not db.enabled then return end
                    -- Secret messages cannot be measured or saved, the chat still shows them
                    if issecretvalue and issecretvalue(text) then return end
                    -- Truncate overly long messages (e.g. item link spam in trade chat)
                    local t = text
                    if #t > MAX_MSG_LENGTH then
                        t = t:sub(1, MAX_MSG_LENGTH) .. "..."
                    end
                    local store = GetCharStore(db, "messages")
                    local key   = "f" .. idx
                    store[key]  = store[key] or {}
                    local hist  = store[key]
                    table.insert(hist, { t = t, r = r or 1, g = g or 1, b = b or 1 })
                    local max = db.maxMessages or MAX_DEFAULT
                    while #hist > max do table.remove(hist, 1) end
                end)
            end
        end
    end
end

-- ============================================================
-- Frame signature
-- ============================================================
-- Chat tab indices can shift (tabs moved, deleted or recreated). The signature
-- (tab name plus message groups and channels) makes sure saved history is only
-- restored into the tab it was recorded from, so tabs never get mixed.
local function SortedKeys(list)
    local keys = {}
    for _, v in pairs(list or {}) do keys[#keys + 1] = tostring(v) end
    table.sort(keys)
    return table.concat(keys, ",")
end

local function GetFrameSignature(frame)
    local name = frame.name or (GetChatWindowInfo and GetChatWindowInfo(frame:GetID())) or ""
    return name .. "|" .. SortedKeys(frame.messageTypeList) .. "|" .. SortedKeys(frame.channelList)
end

function M:SaveSignatures()
    local db = GetDB()
    if not db.enabled then return end
    local signatures = {}
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then signatures["f" .. i] = GetFrameSignature(frame) end
    end
    db.signatures = db.signatures or {}
    db.signatures[GetCharKey()] = signatures
end

-- Drops the old account wide format and characters not seen for 30 days
function M:PruneHistory()
    local db = GetDB()
    db.lastSeen = db.lastSeen or {}
    for _, field in ipairs({ "messages", "signatures" }) do
        for key in pairs(db[field] or {}) do
            local isOldFormat = key:match("^f%d+$") ~= nil
            local lastSeen    = db.lastSeen[key]
            local isExpired   = lastSeen and (time() - lastSeen) > EXPIRE_SECONDS
            if isOldFormat or isExpired then db[field][key] = nil end
        end
    end
    for key, lastSeen in pairs(db.lastSeen) do
        if (time() - lastSeen) > EXPIRE_SECONDS then db.lastSeen[key] = nil end
    end
    db.lastSeen[GetCharKey()] = time()
end

-- ============================================================
-- Restore history on login
-- ============================================================
function M:RestoreHistory()
    local db = GetDB()
    if not db.enabled then return end
    local messages   = GetCharStore(db, "messages")
    local signatures = GetCharStore(db, "signatures")
    restoring = true
    for i = 1, NUM_CHAT_WINDOWS do
        local key   = "f" .. i
        local hist  = messages[key]
        local frame = _G["ChatFrame" .. i]
        if hist and frame then
            -- Without a matching signature the tab changed, so the history is dropped
            if signatures[key] == GetFrameSignature(frame) then
                for _, msg in ipairs(hist) do
                    frame:AddMessage(msg.t, msg.r, msg.g, msg.b)
                end
            else
                messages[key] = nil
            end
        end
    end
    restoring = false
end

-- ============================================================
-- Clear
-- ============================================================
function M:ClearAll()
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then frame:Clear() end
    end
    local db = GetDB()
    if db.messages then db.messages[GetCharKey()] = {} end
end

function M:ClearActive()
    local frame = SELECTED_CHAT_FRAME or FCF_GetCurrentChatFrame() or ChatFrame1
    if not frame then return end
    frame:Clear()
    local db = GetDB()
    if not db.messages then return end
    local store = GetCharStore(db, "messages")
    for i = 1, NUM_CHAT_WINDOWS do
        if _G["ChatFrame" .. i] == frame then
            store["f" .. i] = nil
            break
        end
    end
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
        M:SaveSignatures()
        return
    end
    if event ~= "PLAYER_LOGIN" then return end
    if not GetDB().enabled then return end
    M:PruneHistory()
    M:HookFrames()
    -- Wait briefly until all chat frames are initialized
    C_Timer.After(0.5, function()
        M:RestoreHistory()
    end)
end)
