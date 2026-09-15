-- Modules/QoL/ChatHistory.lua
-- Stores the chat history across sessions in SavedVariables
-- and restores it on the next login.
--
-- Storage location:
--   WTF/Account/<Account>/SavedVariables/AklimeMod.lua
--   AklimeModDB.chatHistory.messages.f1  (ChatFrame1)
--   AklimeModDB.chatHistory.messages.f2  (ChatFrame2) etc.
--
-- Format per entry: { t = "message text", r = 1, g = 1, b = 1 }

local M = {}
AklimeMod_ChatHistory = M

local MAX_DEFAULT    = 100
local MAX_MSG_LENGTH = 400   -- A single message is truncated to 400 characters
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
                    local key  = "f" .. idx
                    db.messages      = db.messages or {}
                    db.messages[key] = db.messages[key] or {}
                    local hist = db.messages[key]
                    table.insert(hist, { t = t, r = r or 1, g = g or 1, b = b or 1 })
                    local max = db.maxMessages or MAX_DEFAULT
                    while #hist > max do table.remove(hist, 1) end
                end)
            end
        end
    end
end

-- ============================================================
-- Restore history on login
-- ============================================================
function M:RestoreHistory()
    local db = GetDB()
    if not db.enabled or not db.messages then return end
    restoring = true
    for i = 1, NUM_CHAT_WINDOWS do
        local hist  = db.messages["f" .. i]
        local frame = _G["ChatFrame" .. i]
        if hist and frame then
            for _, msg in ipairs(hist) do
                frame:AddMessage(msg.t, msg.r, msg.g, msg.b)
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
    if db.messages then db.messages = {} end
end

function M:ClearActive()
    local frame = SELECTED_CHAT_FRAME or FCF_GetCurrentChatFrame() or ChatFrame1
    if not frame then return end
    frame:Clear()
    local db = GetDB()
    if not db.messages then return end
    for i = 1, NUM_CHAT_WINDOWS do
        if _G["ChatFrame" .. i] == frame then
            db.messages["f" .. i] = nil
            break
        end
    end
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
    if event ~= "PLAYER_LOGIN" then return end
    if not GetDB().enabled then return end
    M:HookFrames()
    -- Wait briefly until all chat frames are initialized
    C_Timer.After(0.5, function()
        M:RestoreHistory()
    end)
end)
