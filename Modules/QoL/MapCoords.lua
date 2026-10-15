-- Modules/QoL/MapCoords.lua
-- Shows mouse and player coordinates at the bottom center of the world map.
-- Format: "Mouse: X / Y - Player: X / Y"

local L = AklimeModL or {}

local function GetDB()
    return AklimeModDB and AklimeModDB.mapCoords
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- ============================================================
-- Coordinate text frame
-- ============================================================
local coordFrame = nil

local function CreateCoordFrame()
    if coordFrame then return end

    local f = CreateFrame("Frame", "AklimeMod_MapCoords", WorldMapFrame)
    f:SetSize(300, 16)
    f:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM", 0, 6)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(100)

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetAllPoints(f)
    text:SetJustifyH("CENTER")
    text:SetTextColor(1, 1, 1, 1)
    f.text = text

    f:Hide()
    coordFrame = f
end

-- ============================================================
-- Read coordinates
-- ============================================================
local function fmt(x, y)
    if not x or not y then return "n/a" end
    return string.format("%.1f / %.1f", x * 100, y * 100)
end

local function UpdateCoords()
    if not coordFrame or not coordFrame:IsShown() then return end

    -- Mouse coordinates via GetNormalizedCursorPosition
    local cursorX, cursorY
    local nx, ny = WorldMapFrame:GetNormalizedCursorPosition()
    if nx and ny and nx > 0 and ny > 0 and nx < 1 and ny < 1 then
        cursorX, cursorY = nx, ny
    end

    -- Player coordinates
    local playerX, playerY
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
        if ok and pos then
            playerX, playerY = pos:GetXY()
            if playerX == 0 and playerY == 0 then
                playerX, playerY = nil, nil
            end
        end
    end

    coordFrame.text:SetText(string.format(
        "|cFFFFFFFF%s|r %s  |cFFFFFFFF-  %s|r %s",
        L["coords_mouse"], fmt(cursorX, cursorY),
        L["coords_player"], fmt(playerX, playerY)
    ))
end

-- ============================================================
-- Events + OnUpdate
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        CreateCoordFrame()

        -- Show when the world map is opened
        hooksecurefunc(WorldMapFrame, "Show", function()
            if IsEnabled() and coordFrame then
                coordFrame:Show()
            end
        end)
        hooksecurefunc(WorldMapFrame, "Hide", function()
            if coordFrame then coordFrame:Hide() end
        end)

        -- OnUpdate for real-time coordinates
        coordFrame:SetScript("OnUpdate", UpdateCoords)
    end
end)

-- ============================================================
-- API
-- ============================================================
AklimeMod_MapCoords = {
    IsEnabled  = function() return IsEnabled() end,
    SetEnabled = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if coordFrame then
            if v and WorldMapFrame:IsShown() then
                coordFrame:Show()
            elseif not v then
                coordFrame:Hide()
            end
        end
    end,
}