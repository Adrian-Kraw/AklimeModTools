-- Core/Commands.lua
-- Central registry of all /akm slash commands.
-- Dashboard and /akm help use this list as the single source.

local L = AklimeModL or {}

AklimeMod_Commands = {
    { cmd = "/akm",         desc = L["dash_cmd_open"]  or "Open / close addon"                 },
    { cmd = "/akm help",    desc = L["dash_cmd_help"]  or "Show all commands in chat"           },
    { cmd = "/akm todo",    desc = L["cmd_todo"]       or "Open / close ToDo list"              },
    { cmd = "/akm ignore",  desc = L["cmd_ignore"]     or "Open / close extended ignore list"   },
    { cmd = "/akm played",  desc = L["cmd_played"]     or "Show played time for all characters" },
}

-- /akm help — prints all commands in chat
local function PrintHelp()
    print("|cFFFFD100" .. (L["cmd_header"] or "AklimeMod Commands:") .. "|r")
    for _, e in ipairs(AklimeMod_Commands) do
        print("|cFF00CCFF" .. e.cmd .. "|r - " .. e.desc)
    end
end

-- Hook into the existing /akm slash handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, arg1)
    if arg1 ~= "AklimeModTools" then return end

    local origSlash = SlashCmdList["AKLIMEMOD"]
    SlashCmdList["AKLIMEMOD"] = function(input)
        local cmd = strtrim(input or ""):lower()
        if cmd == "help" then
            PrintHelp()
        elseif cmd == "todo" then
            if AklimeMod_TodoList then AklimeMod_TodoList:Toggle() end
        elseif cmd == "ignore" then
            if AklimeMod_ExtendedIgnore then AklimeMod_ExtendedIgnore:ToggleWindow() end
        elseif cmd == "played" then
            if AklimeMod_PlayedTime then AklimeMod_PlayedTime:Print() end
        elseif origSlash then
            origSlash(input)
        end
    end
end)