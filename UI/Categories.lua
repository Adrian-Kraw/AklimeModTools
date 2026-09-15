-- UI/Categories.lua

local L = AklimeModL or {}

local RSV = function() return AklimeMod_RightScrollView end
local LSV = function() return AklimeMod_LeftScrollView  end

local function newDP() return CreateTreeDataProvider() end

-- ============================================================
-- Shared helpers
-- ============================================================
-- Search filter state (global search across all categories)
local currentSearchFilter = ""
local dummyNode = setmetatable({}, { __index = function() return function() end end })
local lastCategoryFn = nil

local function addModule(dp, name, getEnabled, setEnabled)
    if currentSearchFilter ~= "" and not name:lower():find(currentSearchFilter, 1, true) then
        return dummyNode
    end
    local node = dp:Insert({
        Template   = "AklimeMod_ModuleHeaderTemplate",
        name       = name,
        getEnabled = getEnabled,
        setEnabled = setEnabled,
    })
    -- Expanded in search mode so subentries are directly visible
    node:SetCollapsed(currentSearchFilter == "")
    return node
end

local function addToggle(node, name, getVal, setVal)
    node:Insert({
        Template = "AklimeMod_ToggleTemplate",
        name     = name,
        getVal   = getVal,
        setVal   = setVal,
    })
end

-- options: list of { value = ..., label = ... }
local function addDropdown(node, name, options, getVal, setVal)
    node:Insert({
        Template = "AklimeMod_DropdownTemplate",
        name     = name,
        options  = options,
        getVal   = getVal,
        setVal   = setVal,
    })
end

local INFO_LINE_H = 14  -- GameFontHighlightSmall line height (px)

local function addInfo(node, text)
    local height = 24
    if type(text) == "string" and text ~= "" then
        local lines = 1
        for _ in text:gmatch("\n") do lines = lines + 1 end
        height = math.max(24, lines * INFO_LINE_H + 8)
    end
    node:Insert({
        Template = "AklimeMod_InfoTextTemplate",
        text     = text,
        extent   = height,
    })
end

local function addSlider(node, label, min, max, step, getVal, setVal, formatFn)
    node:Insert({
        Template = "AklimeMod_SliderTemplate",
        label    = label,
        sliderMin  = min,
        sliderMax  = max,
        sliderStep = step or 1,
        getVal   = getVal,
        setVal   = setVal,
        formatFn = formatFn,
    })
end

-- confirm = true: a yes/no dialog appears before execution
local function addAction(node, label, onClick, extent, confirm)
    node:Insert({
        Template = "AklimeMod_ActionButtonTemplate",
        label    = label,
        onClick  = onClick,
        extent   = extent,
        confirm  = confirm,
    })
end

-- ============================================================
-- Custom Panel (Dashboard)
-- ============================================================
local dashboardPanel     = nil
local currentCustomPanel = nil

local function HideCustomPanel()
    if currentCustomPanel then currentCustomPanel:Hide(); currentCustomPanel = nil end
end

local function ShowCustomPanel(panel)
    HideCustomPanel()
    local ri = AklimeModFrame.rightInset
    if ri and ri.scrollBox then ri.scrollBox:Hide() end
    if ri and ri.scrollBar then ri.scrollBar:Hide() end
    panel:Show()
    currentCustomPanel = panel
end

local function ShowScrollView()
    HideCustomPanel()
    local ri = AklimeModFrame.rightInset
    if ri and ri.scrollBox then ri.scrollBox:Show() end
    if ri and ri.scrollBar then ri.scrollBar:Show() end
end

-- ============================================================
-- Right Factory for QoL / general modules
-- (Interface / Colorizer has its own factory in ColorizerUI.lua)
-- ============================================================
local reloadBtns = nil

local function actionInitializer(frame, node)
    local data = node:GetData()
    if data.label == "RELOAD_BUTTONS" then
        -- Special row with its own /rl and /nl buttons, the centered
        -- default button is not needed here
        if frame.button then frame.button:Hide() end
        if not reloadBtns then
            local lbl1 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lbl1:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -8); lbl1:SetText(L["reload_label_rl"])
            local b1 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b1:SetSize(80, 26); b1:SetPoint("LEFT", lbl1, "RIGHT", 10, 0); b1:SetText("/rl")
            b1:SetScript("OnClick", function() if AklimeModDB.reloadUI.enabled then ReloadUI() end end)
            local lbl2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lbl2:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -42); lbl2:SetText(L["reload_label_nl"])
            local b2 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b2:SetSize(80, 26); b2:SetPoint("LEFT", lbl2, "RIGHT", 10, 0); b2:SetText("/nl")
            b2:SetScript("OnClick", function() if AklimeModDB.reloadUI.enabled then ReloadUI() end end)
            reloadBtns = { b1, b2 }
        end
        return
    end
    local btn = frame.button
    if not btn then return end
    btn:Show()
    AklimeMod_StyleActionButton(btn)
    btn.label:SetText(data.label or "")
    btn:SetWidth(math.max(180, btn.label:GetStringWidth() + 44))
    btn:SetScript("OnClick", function(self)
        if not data.onClick then return end
        if data.confirm then
            AklimeMod_Confirm(data.label, data.onClick)
        else
            data.onClick(self)
        end
    end)
end

local function moduleHeaderInitializer(button, node)
    local data = node:GetData()
    AklimeMod_ApplyRowTheme(button)
    -- Remove leftovers from the pool predecessor, an early return skips the reset
    button._refreshCheckbox = nil
    if not data or type(data.getEnabled) ~= "function" then return end

    if button.name then button.name:SetText(data.name or "") end

    local function isEnabled() return data.getEnabled() end

    local function updateVisuals()
        local enabled = isEnabled()
        local collapsed = node:IsCollapsed()
        if not enabled then
            if not collapsed then node:SetCollapsed(true) end
            if button.Right          then button.Right:SetAlpha(0.25) end
            if button.HighlightRight then button.HighlightRight:SetAlpha(0) end
        else
            local atlas = collapsed and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded"
            if button.Right          then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize); button.Right:SetAlpha(1) end
            if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize); button.HighlightRight:SetAlpha(1) end
        end
    end

    if not button.enableButton then return end
    button.enableButton:SetChecked(isEnabled())
    updateVisuals()

    button._refreshCheckbox = function()
        button.enableButton:SetChecked(isEnabled())
        updateVisuals()
    end

    button:SetScript("PreClick", function(self, mouseButton)
        if not node:GetData() or type(node:GetData().getEnabled) ~= "function" then return end
        if (mouseButton == "LeftButton" or mouseButton == nil) and not isEnabled() then
            node:SetCollapsed(true)
        end
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if not node:GetData() or type(node:GetData().getEnabled) ~= "function" then return end
        if not isEnabled() then
            node:SetCollapsed(true)
            updateVisuals()
            return
        end
        node:ToggleCollapsed()
        updateVisuals()
    end)

    button.enableButton:SetScript("OnClick", function(self)
        data.setEnabled(self:GetChecked())
        updateVisuals()
    end)
end

local function toggleInitializer(button, node)
    local data = node:GetData()
    button._refreshCheckbox = function() button.toggle:SetChecked(data.getVal()) end
    if button.name then button.name:SetText(data.name or "") end
    local disabled = data.isDisabled and data.isDisabled()
    button.toggle:SetChecked(data.getVal())
    if disabled then
        button.toggle:Disable()
        button.toggle:SetAlpha(0.35)
        if button.name then button.name:SetTextColor(0.4, 0.4, 0.4, 1) end
    else
        button.toggle:Enable()
        button.toggle:SetAlpha(1.0)
        if button.name then button.name:SetTextColor(1, 0.82, 0, 1) end
    end
    button.toggle:SetScript("OnClick", function(self)
        if data.isDisabled and data.isDisabled() then
            self:SetChecked(not self:GetChecked()); return
        end
        data.setVal(self:GetChecked())
        -- Mirror the state from the DB, radio options stay consistent this way
        self:SetChecked(data.getVal())
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        -- Do nothing, the toggle handles itself
    end)
end

local function ColorToHex(r, g, b)
    local function byte(v)
        v = tonumber(v) or 0
        if v < 0 then v = 0 elseif v > 1 then v = 1 end
        return math.floor(v * 255 + 0.5)
    end
    return string.format("#%02X%02X%02X", byte(r), byte(g), byte(b))
end

local function mouseColorInitializer(button, node)
    if not AklimeMod_MouseEffects then return end
    local data = node:GetData()
    local isTrail = data.mouseTrailColor == true
    local label = isTrail and L["color_trail"] or L["color_ring"]
    local classKey = isTrail and "trailClassColor" or "classColor"
    local getColor = isTrail and AklimeMod_MouseEffects.GetTrailColor or AklimeMod_MouseEffects.GetCustomColor
    local setColor = isTrail and AklimeMod_MouseEffects.SetTrailColor or AklimeMod_MouseEffects.SetCustomColor

    local function refresh()
        local r, g, b = getColor()
        local hex = ColorToHex(r, g, b)
        if button.name then button.name:SetText(label .. "  |cFFAAAAAA" .. hex .. "|r") end
        if button.colorPicker and button.colorPicker.swatch then
            button.colorPicker.swatch:SetAtlas(nil)
            button.colorPicker.swatch:SetColorTexture(r, g, b, 1)
        end
        if button.followClassColor then
            button.followClassColor:SetChecked(AklimeMod_MouseEffects.Get(classKey))
        end
    end

    refresh()

    if button.followClassColor then
        button.followClassColor:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["color_use_class"], 1, 1, 1)
            GameTooltip:Show()
        end)
        button.followClassColor:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.followClassColor:SetScript("OnClick", function(self)
            AklimeMod_MouseEffects.Set(classKey, self:GetChecked())
            refresh()
        end)
    end

    if button.colorPicker then
        button.colorPicker:SetScript("OnEnter", function(self)
            local r, g, b = getColor()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["color_choose"], 1, 1, 1)
            GameTooltip:AddLine(ColorToHex(r, g, b), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        button.colorPicker:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.colorPicker:SetScript("OnClick", function()
            local oldR, oldG, oldB, oldA = getColor()
            local function onChange()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or oldA
                setColor(r, g, b, a)
                refresh()
            end
            ColorPickerFrame:Hide()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = onChange,
                opacityFunc = onChange,
                cancelFunc = function()
                    setColor(oldR, oldG, oldB, oldA)
                    refresh()
                end,
                hasOpacity = true,
                opacity = oldA or 0.9,
                r = oldR, g = oldG, b = oldB,
            })
        end)
    end
end

local function dropdownInitializer(frame, node)
    local data = node:GetData()
    if frame.name then frame.name:SetText(data.name or "") end
    if not frame.dropdown then return end
    -- Runs again for recycled rows, so the generator always reads this node
    frame.dropdown:SetupMenu(function(_, rootDescription)
        for _, option in ipairs(data.options) do
            rootDescription:CreateRadio(option.label,
                function() return data.getVal() == option.value end,
                function() data.setVal(option.value) end
            )
        end
    end)
end

-- Default factory for QoL and other categories
function AklimeMod_RightFactory(factory, node)
    local d = node:GetData()
    local t = d.Template
    if t == "AklimeMod_ModuleHeaderTemplate" then
        factory(t, moduleHeaderInitializer)
    elseif t == "AklimeMod_DropdownTemplate" then
        factory(t, dropdownInitializer)
    elseif t == "AklimeMod_ToggleTemplate" and d.name then
        -- normal toggle (QoL etc.), has .name instead of .toggleLabel
        factory(t, toggleInitializer)
    elseif t == "AklimeMod_SubColorTemplate" and (d.mouseRingColor or d.mouseTrailColor) then
        factory(t, mouseColorInitializer)
    elseif t == "AklimeMod_InfoTextTemplate" then
        factory(t, function(frame, nd)
            local data = nd:GetData()
            local text = data.text
            if type(text) == "function" then text = text() end
            if frame.info then frame.info:SetText(text or "") end
        end)
    elseif t == "AklimeMod_SliderTemplate" then
        factory(t, function(frame, nd)
            local data = nd:GetData()
            if frame.label     then frame.label:SetText(data.label or "") end
            if not frame.slider then return end
            frame.slider:SetMinMaxValues(data.sliderMin or 0, data.sliderMax or 100)
            frame.slider:SetValueStep(data.sliderStep or 1)
            frame.slider:SetObeyStepOnDrag(true)
            local fmt = data.formatFn or tostring
            local function refresh(val)
                if frame.valueText then frame.valueText:SetText(fmt(val)) end
            end
            frame.slider:SetValue(data.getVal())
            refresh(data.getVal())
            frame.slider:SetScript("OnValueChanged", function(_, val, byUser)
                if not byUser then return end
                data.setVal(val)
                refresh(val)
            end)
        end)
    elseif t == "AklimeMod_ActionButtonTemplate" then
        factory(t, actionInitializer)
    elseif t == "AklimeMod_SeparatorTemplate" then
        factory(t, function(frame, nd)
            local data = nd:GetData()
            AklimeMod_ApplyRowTheme(frame)
            if frame.label then
                frame.label:SetText(data.label or "")
                if data.centered then
                    frame.label:SetFont(GameFontNormalLarge:GetFont())
                    frame.label:SetTextColor(1, 0.82, 0, 1)
                    frame.label:SetJustifyH("CENTER")
                    frame.label:ClearAllPoints()
                    frame.label:SetPoint("LEFT",  frame, "LEFT",  0, 0)
                    frame.label:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
                else
                    frame.label:SetFont(GameFontNormalLarge:GetFont())
                    frame.label:SetTextColor(1, 0.82, 0, 1)
                    frame.label:SetJustifyH("LEFT")
                    frame.label:ClearAllPoints()
                    frame.label:SetPoint("LEFT", frame, "LEFT", 8, 0)
                end
            end
        end)
    end
end

-- ============================================================
-- Dashboard
-- ============================================================
local function GetOrCreateDashboard(parent)
    if dashboardPanel then return dashboardPanel end
    dashboardPanel = CreateFrame("Frame", nil, parent)
    dashboardPanel:SetAllPoints(parent)
    -- Content lives in a child frame so it is clipped at the panel edge
    -- when the window is shrunk instead of sticking out
    dashboardPanel:SetClipsChildren(true)
    dashboardPanel:Hide()

    local content = CreateFrame("Frame", nil, dashboardPanel)
    content:SetAllPoints(dashboardPanel)

    local function Label(text, offsetY, font, r, g, b)
        local fs = content:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 20, offsetY)
        fs:SetTextColor(r or 0.9, g or 0.9, b or 0.9, 1)
        fs:SetText(text)
        return fs
    end
    local function Separator(offsetY)
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  content, "TOPLEFT",  16, offsetY)
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, offsetY)
        AklimeMod_RegisterThemeLine(line)
    end

    local y = -40
    Label("|cFFFFD100" .. L["dash_contact"] .. "|r", y, "GameFontNormalLarge"); y = y - 28
    Separator(y); y = y - 18
    Label("|cFF00CCFFIngame:|r", y); y = y - 22
    Label("  Yodabär-Blackmoore", y); y = y - 22
    Label("  Aklime-Blackmoore", y); y = y - 22
    Label("  Sattarnna-Un'Goro", y); y = y - 30
    Separator(y); y = y - 18
    Label("|cFFFFD100" .. L["dash_commands"] .. "|r", y, "GameFontNormalLarge"); y = y - 28
    Separator(y); y = y - 18
    local cmds = AklimeMod_Commands or {
        { cmd="/akm",      desc=L["dash_cmd_open"] },
        { cmd="/akm help", desc=L["dash_cmd_help"] },
    }
    for _, e in ipairs(cmds) do
        local row = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 20, y)
        row:SetText("|cFF00CCFF" .. e.cmd .. "|r - " .. e.desc)
        y = y - 22
    end
    return dashboardPanel
end

local function BuildDashboardContent()
    lastCategoryFn = BuildDashboardContent
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Dashboard")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    RSV():SetDataProvider(newDP())

    -- Always rebuild the dashboard panel so the commands list is current
    if dashboardPanel then dashboardPanel:Hide(); dashboardPanel = nil end
    ShowCustomPanel(GetOrCreateDashboard(AklimeModFrame.rightInset))
end

-- ============================================================
-- Search
-- ============================================================
local currentBuildFn = nil
-- BuildGlobalSearch and AklimeMod_InitSearch follow after the add*Nodes definitions

-- ============================================================
-- Interface tab: Elite/Rare + colorizer tree
-- ============================================================

-- Action bar gap compression, one alignment dropdown per bar
local function addActionBarCompactNode(dp)
    local M = AklimeMod_ActionBarCompact
    if not M then return end
    local node = addModule(dp, L["mod_action_bar_compact"],
        function() return M:IsEnabled() end,
        function(v) M:SetEnabled(v) end
    )
    addInfo(node, L["info_action_bar_compact"])
    local options = {}
    for _, mode in ipairs(M.MODES) do
        options[#options + 1] = { value = mode, label = L["abc_mode_" .. mode] }
    end
    for barIndex = 1, M.NUM_BARS do
        addDropdown(node, string.format(L["dropdown_action_bar"], barIndex), options,
            function() return M:GetMode(barIndex) end,
            function(v) M:SetMode(barIndex, v) end
        )
    end
end

-- Only the non colorizer modules (usable for global search)
local function addInterfaceNodes(dp)
    local eliteNode = addModule(dp, L["mod_elite_frame"],
        function() return AklimeModDB.eliteFrame.enabled end,
        function(v)
            AklimeModDB.eliteFrame.enabled = v
            if v and AklimeModDB.eliteFrame.style then AklimeMod_ApplyEliteFrame()
            else AklimeMod_RemoveEliteFrame() end
        end
    )
    local eliteStyles = {
        { key="silver",     label=L["elite_silver"]      },
        { key="silverWing", label=L["elite_silver_wing"] },
        { key="gold",       label=L["elite_gold"]        },
        { key="goldWing",   label=L["elite_gold_wing"]   },
    }
    for _, s in ipairs(eliteStyles) do
        local key = s.key
        addToggle(eliteNode, s.label,
            function() return AklimeModDB.eliteFrame.style == key end,
            function(v)
                if v then
                    AklimeModDB.eliteFrame.style = key
                    if AklimeModDB.eliteFrame.enabled then AklimeMod_ApplyEliteFrame(key) end
                else
                    AklimeModDB.eliteFrame.style = nil; AklimeMod_RemoveEliteFrame()
                end
                AklimeMod_RefreshRightToggles()
            end
        )
    end

    local rareNode = addModule(dp, L["mod_rare_enemies"],
        function() return AklimeModDB.rareFrame.enabled end,
        function(v) AklimeModDB.rareFrame.enabled = v; AklimeMod_UpdateRareFrame() end
    )
    addToggle(rareNode, L["toggle_star_silver"],
        function() return AklimeModDB.rareFrame.enabled end,
        function(v) AklimeModDB.rareFrame.enabled = v; AklimeMod_UpdateRareFrame() end
    )

    local dungeonEyeNode = addModule(dp, L["mod_dungeon_eye"],
        function() return AklimeMod_DungeonEye.IsEnabled() end,
        function(v) AklimeMod_DungeonEye.SetEnabled(v) end
    )
    addToggle(dungeonEyeNode, L["toggle_lock_minimap"],
        function() return AklimeMod_DungeonEye.IsLocked() end,
        function(v) AklimeMod_DungeonEye.SetLocked(v) end
    )

    local raidCenterNode = addModule(dp, L["mod_raid_center"],
        function() return AklimeMod_RaidFrameCenter.IsEnabled() end,
        function(v) AklimeMod_RaidFrameCenter.SetEnabled(v) end
    )
    addInfo(raidCenterNode, L["info_raid_center_short"])

    local hideMacroNode = addModule(dp, L["mod_hide_macro"],
        function() return AklimeMod_HideMacroNames.IsEnabled() end,
        function(v) AklimeMod_HideMacroNames.SetEnabled(v) end
    )
    addInfo(hideMacroNode, L["info_hide_macro_short"])

    local dmCollapseNode = addModule(dp, L["mod_dm_collapse"],
        function() return AklimeMod_DamageMeterCollapseDown.IsEnabled() end,
        function(v) AklimeMod_DamageMeterCollapseDown.SetEnabled(v) end
    )
    addInfo(dmCollapseNode, L["info_dm_collapse_short"])

    if AklimeMod_MinimapCollector then
        local mmNode = addModule(dp, L["mod_mm_collector"],
            function() return AklimeMod_MinimapCollector.IsEnabled() end,
            function(v) AklimeMod_MinimapCollector.SetEnabled(v) end
        )
        addToggle(mmNode, L["toggle_include_own"],
            function() return AklimeMod_MinimapCollector.IncludeOwn() end,
            function(v) AklimeMod_MinimapCollector.SetIncludeOwn(v) end
        )
    end

    if AklimeMod_MinimapElementHider then
        local hideNode = addModule(dp, L["mod_mm_hider"],
            function() return AklimeMod_MinimapElementHider.IsEnabled() end,
            function(v) AklimeMod_MinimapElementHider.SetEnabled(v) end
        )
        for _, kv in ipairs({
            { L["toggle_mm_tracking"], "tracking" }, { L["toggle_mm_zone"], "zoneInfo" },
            { L["toggle_mm_clock"], "clock" }, { L["toggle_mm_calendar"], "calendar" },
            { L["toggle_mm_mail"], "mail" }, { L["toggle_mm_compartment"], "addonCompartment" },
        }) do
            local lbl, key = kv[1], kv[2]
            addToggle(hideNode, lbl,
                function() return AklimeMod_MinimapElementHider.Get(key) end,
                function(v) AklimeMod_MinimapElementHider.Set(key, v) end
            )
        end
    end

    if AklimeMod_MouseEffects then
        local mouseNode = addModule(dp, L["mod_mouse_effects"],
            function() return AklimeMod_MouseEffects.IsEnabled() end,
            function(v) AklimeMod_MouseEffects.SetEnabled(v) end
        )
        addInfo(mouseNode, L["info_mouse_effects"])
    end

    if AklimeMod_GearCheck then
        local gcNode = addModule(dp, L["mod_gear_check"],
            function() return AklimeMod_GearCheck.IsEnabled() end,
            function(v) AklimeMod_GearCheck.SetEnabled(v) end
        )
        addInfo(gcNode, L["info_gear_check"])
    end

    if AklimeMod_CombatTooltip then
        local ttNode = addModule(dp, L["mod_combat_tooltip"],
            function() return AklimeMod_CombatTooltip:IsEnabled() end,
            function(v) AklimeMod_CombatTooltip:SetEnabled(v) end
        )
        addInfo(ttNode, L["info_combat_tooltip"])
        addToggle(ttNode, L["tog_ct_allow_auras"],
            function() return AklimeMod_CombatTooltip:AllowsAuras() end,
            function(v) AklimeMod_CombatTooltip:SetAllowAuras(v) end
        )
    end

    if AklimeMod_BNetToastMover then
        local toastNode = addModule(dp, L["mod_bnet_toast_mover"],
            function() return AklimeMod_BNetToastMover:IsEnabled() end,
            function(v) AklimeMod_BNetToastMover:SetEnabled(v) end
        )
        addToggle(toastNode, L["toggle_lock_position"],
            function() return AklimeMod_BNetToastMover:IsLocked() end,
            function(v) AklimeMod_BNetToastMover:SetLocked(v) end
        )
        addAction(toastNode, L["action_preview"], function()
            if AklimeMod_BNetToastMover.previewing then
                AklimeMod_BNetToastMover.previewing = false
                AklimeMod_BNetToastMover:HidePreview()
            else
                AklimeMod_BNetToastMover.previewing = true
                AklimeMod_BNetToastMover:ShowPreview()
            end
        end)
        addInfo(toastNode, L["info_bnet_toast_mover"])
    end

    addActionBarCompactNode(dp)

    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_hud_fading"], centered = true })
    end
    do
        local fade = AklimeModDB.interfaceFade
        for i = 1, 3 do
            local k = "mode" .. i
            local setEnabled
            if i == 1 then
                setEnabled = function(v) if AklimeMod_HUDFader then AklimeMod_HUDFader:SetEnabled(v) end end
            elseif i == 2 then
                setEnabled = function(v) if AklimeMod_HUDFader then AklimeMod_HUDFader:SetEnabled2(v) end end
            elseif i == 3 then
                setEnabled = function(v) if AklimeMod_HUDFader then AklimeMod_HUDFader:SetEnabled3(v) end end
            else
                setEnabled = function(v) fade[k].enabled = v end
            end
            local modeName
            if i == 1 then modeName = L["mod_hud_chill"]
            elseif i == 2 then modeName = L["mod_hud_openworld"]
            elseif i == 3 then modeName = L["mod_hud_housing"]
            else modeName = "Mode " .. i
            end
            local modeNode = addModule(dp, modeName,
                function() return fade[k].enabled end,
                setEnabled
            )
            addSlider(modeNode, L["slider_transparency"], 0, 100, 1,
                function() return fade[k].alpha end,
                function(v)
                    fade[k].alpha = v
                    if i == 1 and AklimeMod_HUDFader then AklimeMod_HUDFader:ApplyAlpha() end
                    if i == 2 and AklimeMod_HUDFader then AklimeMod_HUDFader:ApplyAlpha2() end
                    if i == 3 and AklimeMod_HUDFader then AklimeMod_HUDFader:ApplyAlpha3() end
                end,
                function(v) return v .. "%" end
            )
            if i == 1 or i == 2 or i == 3 then
                addSlider(modeNode, L["slider_move_delay"], 0, 10, 1,
                    function() return fade[k].moveDelay end,
                    function(v) fade[k].moveDelay = v end,
                    function(v) return v == 0 and L["fmt_instant"] or v .. " s" end
                )
                addSlider(modeNode, L["slider_idle_delay"], 5, 60, 1,
                    function() return fade[k].idleDelay end,
                    function(v) fade[k].idleDelay = v end,
                    function(v) return v .. " s" end
                )
                addSlider(modeNode, L["slider_chat_delay"], 5, 60, 1,
                    function() return fade[k].chatDelay end,
                    function(v) fade[k].chatDelay = v end,
                    function(v) return v .. " s" end
                )
                addInfo(modeNode, L["info_always_visible"])
                local ex = fade[k].exclude
                local function refresh() if AklimeMod_HUDFader then AklimeMod_HUDFader:Refresh() end end
                addToggle(modeNode, L["toggle_chat"],          function() return ex.chat        end, function(v) ex.chat        = v; refresh() end)
                addToggle(modeNode, L["toggle_minimap"],       function() return ex.minimap     end, function(v) ex.minimap     = v; refresh() end)
                addToggle(modeNode, L["toggle_objectives"],    function() return ex.objectives  end, function(v) ex.objectives  = v; refresh() end)
                addToggle(modeNode, L["toggle_micromenu"],     function() return ex.microMenu   end, function(v) ex.microMenu   = v; refresh() end)
                addToggle(modeNode, L["toggle_bags"],          function() return ex.bags        end, function(v) ex.bags        = v; refresh() end)
                addToggle(modeNode, L["toggle_action_bars"],   function() return ex.actionBars  end, function(v) ex.actionBars  = v; refresh() end)
                addToggle(modeNode, L["toggle_unit_frames"],   function() return ex.unitFrames  end, function(v) ex.unitFrames  = v; refresh() end)
                addToggle(modeNode, L["toggle_buffs"],         function() return ex.buffs       end, function(v) ex.buffs       = v; refresh() end)
                addToggle(modeNode, L["toggle_rep_bar"],       function() return ex.repBar      end, function(v) ex.repBar      = v; refresh() end)
                addToggle(modeNode, L["toggle_damage_meter"],  function() return ex.damageMeter end, function(v) ex.damageMeter = v; refresh() end)
            end
        end
    end
end

local function BuildInterfaceContent(filter)
    lastCategoryFn = BuildInterfaceContent
    AklimeMod_SetRightHeader("Interface")
    ShowScrollView()
    currentBuildFn = BuildInterfaceContent

    -- Switch the factory to the colorizer factory
    RSV():SetElementFactory(AklimeMod_ColorizerRightFactory, function() end)

    local dp = CreateTreeDataProvider()

    -- Extended factory (Elite + Rare support)
    local function extendedFactory(factory, node)
        local d = node:GetData()
        if d.Template == "AklimeMod_ModuleHeaderTemplate" then
            factory(d.Template, moduleHeaderInitializer)
        elseif d.Template == "AklimeMod_DropdownTemplate" then
            factory(d.Template, dropdownInitializer)
        elseif d.Template == "AklimeMod_ToggleTemplate" and d.name then
            factory(d.Template, toggleInitializer)
        elseif d.Template == "AklimeMod_SubColorTemplate" and (d.mouseRingColor or d.mouseTrailColor) then
            factory(d.Template, mouseColorInitializer)
        else
            -- All colorizer templates
            AklimeMod_ColorizerRightFactory(factory, node)
        end
    end
    RSV():SetElementFactory(extendedFactory, function() end)

    local dp3 = CreateTreeDataProvider()

    -- Elite Frame
    local eliteNode3 = addModule(dp3, L["mod_elite_frame"],
        function() return AklimeModDB.eliteFrame.enabled end,
        function(v)
            AklimeModDB.eliteFrame.enabled = v
            if v and AklimeModDB.eliteFrame.style then AklimeMod_ApplyEliteFrame()
            else AklimeMod_RemoveEliteFrame() end
        end
    )
    local eliteStyles = {
        { key="silver",     label=L["elite_silver"]      },
        { key="silverWing", label=L["elite_silver_wing"] },
        { key="gold",       label=L["elite_gold"]        },
        { key="goldWing",   label=L["elite_gold_wing"]   },
    }
    for _, s in ipairs(eliteStyles) do
        local key = s.key
        addToggle(eliteNode3, s.label,
            function() return AklimeModDB.eliteFrame.style == key end,
            function(v)
                if v then
                    AklimeModDB.eliteFrame.style = key
                    if AklimeModDB.eliteFrame.enabled then AklimeMod_ApplyEliteFrame(key) end
                else
                    AklimeModDB.eliteFrame.style = nil; AklimeMod_RemoveEliteFrame()
                end
                -- Update sibling checks directly instead of collapsing and
                -- re-expanding the section
                AklimeMod_RefreshRightToggles()
            end
        )
    end

    -- Rare enemies
    local rareNode = addModule(dp3, L["mod_rare_enemies"],
        function() return AklimeModDB.rareFrame.enabled end,
        function(v) AklimeModDB.rareFrame.enabled = v; AklimeMod_UpdateRareFrame() end
    )
    addToggle(rareNode, L["toggle_star_silver"],
        function() return AklimeModDB.rareFrame.enabled end,
        function(v) AklimeModDB.rareFrame.enabled = v; AklimeMod_UpdateRareFrame() end
    )

    -- Dungeon Eye
    local dungeonEyeNode = addModule(dp3, L["mod_dungeon_eye"],
        function() return AklimeMod_DungeonEye.IsEnabled() end,
        function(v) AklimeMod_DungeonEye.SetEnabled(v) end
    )
    addToggle(dungeonEyeNode, L["toggle_lock_minimap"],
        function() return AklimeMod_DungeonEye.IsLocked() end,
        function(v) AklimeMod_DungeonEye.SetLocked(v) end
    )
    addInfo(dungeonEyeNode, L["info_dungeon_eye"])

    -- Raid frame centering
    local raidCenterNode = addModule(dp3, L["mod_raid_center"],
        function() return AklimeMod_RaidFrameCenter.IsEnabled() end,
        function(v) AklimeMod_RaidFrameCenter.SetEnabled(v) end
    )
    addInfo(raidCenterNode, L["info_raid_center"])

    local hideMacroNode = addModule(dp3, L["mod_hide_macro"],
        function() return AklimeMod_HideMacroNames.IsEnabled() end,
        function(v) AklimeMod_HideMacroNames.SetEnabled(v) end
    )
    addInfo(hideMacroNode, L["info_hide_macro"])

    local dmCollapseNode = addModule(dp3, L["mod_dm_collapse"],
        function() return AklimeMod_DamageMeterCollapseDown.IsEnabled() end,
        function(v) AklimeMod_DamageMeterCollapseDown.SetEnabled(v) end
    )
    addInfo(dmCollapseNode, L["info_dm_collapse"])

    if AklimeMod_MinimapCollector then
        local mmCollectorNode = addModule(dp3, L["mod_mm_collector"],
            function()
                if not AklimeMod_MinimapCollector then return false end
                return AklimeMod_MinimapCollector.IsEnabled()
            end,
            function(v)
                if not AklimeMod_MinimapCollector then return end
                AklimeMod_MinimapCollector.SetEnabled(v)
            end
        )
        addInfo(mmCollectorNode, L["info_mm_collector"])
        addToggle(mmCollectorNode, L["toggle_include_own"],
            function()
                if not AklimeMod_MinimapCollector then return false end
                return AklimeMod_MinimapCollector.IncludeOwn()
            end,
            function(v)
                if not AklimeMod_MinimapCollector then return end
                AklimeMod_MinimapCollector.SetIncludeOwn(v)
            end
        )
    end

    if AklimeMod_MinimapElementHider then
        local hideNode = addModule(dp3, L["mod_mm_hider"],
            function() return AklimeMod_MinimapElementHider.IsEnabled() end,
            function(v) AklimeMod_MinimapElementHider.SetEnabled(v) end
        )
        addToggle(hideNode, L["toggle_mm_tracking"],
            function() return AklimeMod_MinimapElementHider.Get("tracking") end,
            function(v) AklimeMod_MinimapElementHider.Set("tracking", v) end
        )
        addToggle(hideNode, L["toggle_mm_zone"],
            function() return AklimeMod_MinimapElementHider.Get("zoneInfo") end,
            function(v) AklimeMod_MinimapElementHider.Set("zoneInfo", v) end
        )
        addToggle(hideNode, L["toggle_mm_clock"],
            function() return AklimeMod_MinimapElementHider.Get("clock") end,
            function(v) AklimeMod_MinimapElementHider.Set("clock", v) end
        )
        addToggle(hideNode, L["toggle_mm_calendar"],
            function() return AklimeMod_MinimapElementHider.Get("calendar") end,
            function(v) AklimeMod_MinimapElementHider.Set("calendar", v) end
        )
        addToggle(hideNode, L["toggle_mm_mail"],
            function() return AklimeMod_MinimapElementHider.Get("mail") end,
            function(v) AklimeMod_MinimapElementHider.Set("mail", v) end
        )
        addToggle(hideNode, L["toggle_mm_compartment"],
            function() return AklimeMod_MinimapElementHider.Get("addonCompartment") end,
            function(v) AklimeMod_MinimapElementHider.Set("addonCompartment", v) end
        )
    end

    if AklimeMod_MouseEffects then
        local mouseNode = addModule(dp3, L["mod_mouse_effects"],
            function() return AklimeMod_MouseEffects.IsEnabled() end,
            function(v) AklimeMod_MouseEffects.SetEnabled(v) end
        )
        addToggle(mouseNode, L["toggle_trail"],
            function() return AklimeMod_MouseEffects.Get("trail") end,
            function(v) AklimeMod_MouseEffects.Set("trail", v) end
        )
        addToggle(mouseNode, L["toggle_class_color"],
            function() return AklimeMod_MouseEffects.Get("classColor") end,
            function(v) AklimeMod_MouseEffects.Set("classColor", v) end
        )
        addToggle(mouseNode, L["toggle_trail_class"],
            function() return AklimeMod_MouseEffects.Get("trailClassColor") end,
            function(v) AklimeMod_MouseEffects.Set("trailClassColor", v) end
        )
        addToggle(mouseNode, L["toggle_hide_dot"],
            function() return AklimeMod_MouseEffects.Get("hideDot") end,
            function(v) AklimeMod_MouseEffects.Set("hideDot", v) end
        )
        addToggle(mouseNode, L["toggle_hide_ring"],
            function() return AklimeMod_MouseEffects.Get("hideRing") end,
            function(v) AklimeMod_MouseEffects.Set("hideRing", v) end
        )
        addToggle(mouseNode, L["toggle_ring_combat"],
            function() return AklimeMod_MouseEffects.Get("onlyCombat") end,
            function(v) AklimeMod_MouseEffects.Set("onlyCombat", v) end
        )
        addToggle(mouseNode, L["toggle_ring_rightclick"],
            function() return AklimeMod_MouseEffects.Get("onlyRightClick") end,
            function(v) AklimeMod_MouseEffects.Set("onlyRightClick", v) end
        )
        addToggle(mouseNode, L["toggle_trail_combat"],
            function() return AklimeMod_MouseEffects.Get("trailOnlyCombat") end,
            function(v) AklimeMod_MouseEffects.Set("trailOnlyCombat", v) end
        )
        addSlider(mouseNode, L["slider_ring_size"], 40, 150, 2,
            function() return AklimeMod_MouseEffects.GetSize() end,
            function(v) AklimeMod_MouseEffects.SetSize(v) end,
            function(v) return v .. " px" end
        )
        mouseNode:Insert({
            Template = "AklimeMod_SubColorTemplate",
            mouseRingColor = true,
        })
        mouseNode:Insert({
            Template = "AklimeMod_SubColorTemplate",
            mouseTrailColor = true,
        })
        local trailPresets = { "low", "medium", "high", "ultra" }
        local trailLabels  = { L["trail_low"], L["trail_medium"], L["trail_high"], L["trail_ultra"] }
        local trailIndex   = { low = 1, medium = 2, high = 3, ultra = 4 }
        addSlider(mouseNode, L["slider_trail_density"], 1, 4, 1,
            function() return trailIndex[AklimeMod_MouseEffects.GetTrailPreset()] or 2 end,
            function(v) AklimeMod_MouseEffects.SetTrailPreset(trailPresets[v]) end,
            function(v) return trailLabels[v] or "" end
        )
    end

    if AklimeMod_GearCheck then
        local gcNode = addModule(dp3, L["mod_gear_check"],
            function() return AklimeMod_GearCheck.IsEnabled() end,
            function(v) AklimeMod_GearCheck.SetEnabled(v) end
        )
        addInfo(gcNode, L["info_gear_check"])
    end

    if AklimeMod_CombatTooltip then
        local ttNode = addModule(dp3, L["mod_combat_tooltip"],
            function() return AklimeMod_CombatTooltip:IsEnabled() end,
            function(v) AklimeMod_CombatTooltip:SetEnabled(v) end
        )
        addInfo(ttNode, L["info_combat_tooltip"])
        addToggle(ttNode, L["tog_ct_allow_auras"],
            function() return AklimeMod_CombatTooltip:AllowsAuras() end,
            function(v) AklimeMod_CombatTooltip:SetAllowAuras(v) end
        )
    end

    dp3:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_move_ui"], centered = true })

    if AklimeMod_BNetToastMover then
        local toastNode = addModule(dp3, L["mod_bnet_toast_mover"],
            function() return AklimeMod_BNetToastMover:IsEnabled() end,
            function(v) AklimeMod_BNetToastMover:SetEnabled(v) end
        )
        addToggle(toastNode, L["toggle_lock_position"],
            function() return AklimeMod_BNetToastMover:IsLocked() end,
            function(v) AklimeMod_BNetToastMover:SetLocked(v) end
        )
        addAction(toastNode, L["action_preview"], function()
            if AklimeMod_BNetToastMover.previewing then
                AklimeMod_BNetToastMover.previewing = false
                AklimeMod_BNetToastMover:HidePreview()
            else
                AklimeMod_BNetToastMover.previewing = true
                AklimeMod_BNetToastMover:ShowPreview()
            end
        end)
        addInfo(toastNode, L["info_bnet_toast_mover"])
    end

    addActionBarCompactNode(dp3)

    dp3:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_hud_fading"], centered = true })
    do
        local fade = AklimeModDB.interfaceFade
        for i = 1, 3 do
            local k = "mode" .. i
            local setEnabled
            if i == 1 then
                setEnabled = function(v) if AklimeMod_HUDFader then AklimeMod_HUDFader:SetEnabled(v) end end
            elseif i == 2 then
                setEnabled = function(v) if AklimeMod_HUDFader then AklimeMod_HUDFader:SetEnabled2(v) end end
            elseif i == 3 then
                setEnabled = function(v) if AklimeMod_HUDFader then AklimeMod_HUDFader:SetEnabled3(v) end end
            else
                setEnabled = function(v) fade[k].enabled = v end
            end
            local modeName
            if i == 1 then modeName = L["mod_hud_chill"]
            elseif i == 2 then modeName = L["mod_hud_openworld"]
            elseif i == 3 then modeName = L["mod_hud_housing"]
            else modeName = "Mode " .. i
            end
            local modeNode = addModule(dp3, modeName,
                function() return fade[k].enabled end,
                setEnabled
            )
            addSlider(modeNode, L["slider_transparency"], 0, 100, 1,
                function() return fade[k].alpha end,
                function(v)
                    fade[k].alpha = v
                    if i == 1 and AklimeMod_HUDFader then AklimeMod_HUDFader:ApplyAlpha() end
                    if i == 2 and AklimeMod_HUDFader then AklimeMod_HUDFader:ApplyAlpha2() end
                    if i == 3 and AklimeMod_HUDFader then AklimeMod_HUDFader:ApplyAlpha3() end
                end,
                function(v) return v .. "%" end
            )
            if i == 1 or i == 2 or i == 3 then
                addSlider(modeNode, L["slider_move_delay"], 0, 10, 1,
                    function() return fade[k].moveDelay end,
                    function(v) fade[k].moveDelay = v end,
                    function(v) return v == 0 and L["fmt_instant"] or v .. " s" end
                )
                addSlider(modeNode, L["slider_idle_delay"], 5, 60, 1,
                    function() return fade[k].idleDelay end,
                    function(v) fade[k].idleDelay = v end,
                    function(v) return v .. " s" end
                )
                addSlider(modeNode, L["slider_chat_delay"], 5, 60, 1,
                    function() return fade[k].chatDelay end,
                    function(v) fade[k].chatDelay = v end,
                    function(v) return v .. " s" end
                )
                addInfo(modeNode, L["info_always_visible"])
                local ex = fade[k].exclude
                local function refresh() if AklimeMod_HUDFader then AklimeMod_HUDFader:Refresh() end end
                addToggle(modeNode, L["toggle_chat"],         function() return ex.chat        end, function(v) ex.chat        = v; refresh() end)
                addToggle(modeNode, L["toggle_minimap"],      function() return ex.minimap     end, function(v) ex.minimap     = v; refresh() end)
                addToggle(modeNode, L["toggle_objectives"],   function() return ex.objectives  end, function(v) ex.objectives  = v; refresh() end)
                addToggle(modeNode, L["toggle_micromenu"],    function() return ex.microMenu   end, function(v) ex.microMenu   = v; refresh() end)
                addToggle(modeNode, L["toggle_bags"],         function() return ex.bags        end, function(v) ex.bags        = v; refresh() end)
                addToggle(modeNode, L["toggle_action_bars"],  function() return ex.actionBars  end, function(v) ex.actionBars  = v; refresh() end)
                addToggle(modeNode, L["toggle_unit_frames"],  function() return ex.unitFrames  end, function(v) ex.unitFrames  = v; refresh() end)
                addToggle(modeNode, L["toggle_buffs"],        function() return ex.buffs       end, function(v) ex.buffs       = v; refresh() end)
                addToggle(modeNode, L["toggle_rep_bar"],      function() return ex.repBar      end, function(v) ex.repBar      = v; refresh() end)
                addToggle(modeNode, L["toggle_damage_meter"], function() return ex.damageMeter end, function(v) ex.damageMeter = v; refresh() end)
            end
        end
    end

    -- Insert colorizer nodes directly into dp3
    local function insertColorizerNodes(targetDP, searchFilter)
        local C = AklimeMod_Colorizer

        targetDP:Insert({
            Template = "AklimeMod_SeparatorTemplate",
            label    = L["sec_colorizer"],
            centered = true,
        })

        -- Master toggle: all skins on/off
        local function AllEnabled()
            for _, group in ipairs(C.groupOrder) do
                for _, key in ipairs(group.keys) do
                    if not C:IsEnabled(key) then return false end
                end
            end
            return true
        end

        local function SetAll(v)
            for _, group in ipairs(C.groupOrder) do
                for _, key in ipairs(group.keys) do
                    AklimeModDB.colorizer[key] = AklimeModDB.colorizer[key] or {}
                    AklimeModDB.colorizer[key].enabled = v
                    local skin = C.skins[key]
                    if skin then
                        if v then pcall(function() skin:apply() end)
                        else      pcall(function() skin:remove() end) end
                    end
                end
            end
            -- Only update visible checkboxes. A complete rebuild would
            -- collapse all expanded sections again.
            AklimeMod_RefreshRightToggles()
        end

        local allNode = targetDP:Insert({
            Template   = "AklimeMod_ModuleHeaderTemplate",
            name       = L["mod_colorizer_all"],
            getEnabled = AllEnabled,
            setEnabled = SetAll,
        })
        allNode:SetCollapsed(true)
        allNode:Insert({
            Template      = "AklimeMod_SubColorTemplate",
            isGlobalColor = true,
        })
        allNode:Insert({
            Template = "AklimeMod_ActionButtonTemplate",
            label    = L["action_restore_default"],
            onClick  = function()
                local d = AklimeMod_Colorizer.defaults.main
                AklimeMod_Colorizer.ApplyGlobalColor(d.r, d.g, d.b, d.a)
                if AklimeMod_BuildInterfaceContent then AklimeMod_BuildInterfaceContent() end
            end,
        })

        for _, group in ipairs(C.groupOrder) do
            local groupHasMatch = true
            if searchFilter and searchFilter ~= "" then
                groupHasMatch = false
                if group.label:lower():find(searchFilter, 1, true) then groupHasMatch = true end
                if not groupHasMatch then
                    for _, key in ipairs(group.keys) do
                        local skin = C.skins[key]
                        if skin and skin.label:lower():find(searchFilter, 1, true) then
                            groupHasMatch = true; break
                        end
                    end
                end
            end

            if groupHasMatch then
                targetDP:Insert({
                    Template = "AklimeMod_SeparatorTemplate",
                    label    = group.label,
                    sublabel = true,
                })

                -- Group master toggle
                local grpKeys = group.keys
                local function GroupAllEnabled()
                    for _, key in ipairs(grpKeys) do
                        if not C:IsEnabled(key) then return false end
                    end
                    return true
                end
                local function SetGroup(v)
                    for _, key in ipairs(grpKeys) do
                        AklimeModDB.colorizer[key] = AklimeModDB.colorizer[key] or {}
                        AklimeModDB.colorizer[key].enabled = v
                        local skin = C.skins[key]
                        if skin then
                            if v then pcall(function() skin:apply() end)
                            else      pcall(function() skin:remove() end) end
                        end
                    end
                    AklimeMod_RefreshRightToggles()
                end
                targetDP:Insert({
                    Template   = "AklimeMod_ModuleHeaderTemplate",
                    name       = string.format(L["colorizer_group_toggle"], group.label),
                    getEnabled = GroupAllEnabled,
                    setEnabled = SetGroup,
                })

                for _, key in ipairs(group.keys) do
                    local skin = C.skins[key]
                    if skin then
                        local skinMatches = true
                        if searchFilter and searchFilter ~= "" then
                            skinMatches = skin.label:lower():find(searchFilter, 1, true)
                                or group.label:lower():find(searchFilter, 1, true)
                        end
                        if skinMatches then
                            local headerNode = targetDP:Insert({
                                Template = "AklimeMod_SkinHeaderTemplate",
                                skinKey  = key,
                                name     = skin.label,
                            })
                            headerNode:SetCollapsed(true)

                            -- Toggles
                            if skin.toggles then
                                for tk, td in pairs(skin.toggles) do
                                    headerNode:Insert({
                                        Template    = "AklimeMod_ToggleTemplate",
                                        skinKey     = key,
                                        toggleKey   = tk,
                                        toggleLabel = td.label or tk,
                                    })
                                end
                            end

                            -- Colors (sorted)
                            if skin.colors then
                                local sortedColors = {}
                                for ck, cd in pairs(skin.colors) do
                                    table.insert(sortedColors, { key=ck, def=cd, order=cd.order or 99 })
                                end
                                table.sort(sortedColors, function(a,b) return a.order < b.order end)
                                for _, entry in ipairs(sortedColors) do
                                    headerNode:Insert({
                                        Template   = "AklimeMod_SubColorTemplate",
                                        skinKey    = key,
                                        colorKey   = entry.key,
                                        colorLabel = entry.def.label or entry.key,
                                    })
                                end
                            end

                            -- Only for the own window skin: color everything at
                            -- once and reset all colors to default
                            if key == "winAklimeMod" then
                                headerNode:Insert({
                                    Template     = "AklimeMod_SubColorTemplate",
                                    skinKey      = key,
                                    skinAllColor = true,
                                    colorLabel   = L["color_all_skin"] or "Color everything",
                                })
                                headerNode:Insert({
                                    Template = "AklimeMod_ActionButtonTemplate",
                                    label    = L["action_restore_default"],
                                    onClick  = function()
                                        local skdb = AklimeModDB.colorizer[key]
                                        if skdb and skin.colors then
                                            for ck, cd in pairs(skin.colors) do
                                                skdb.colors[ck] = { r=cd.r, g=cd.g, b=cd.b, a=cd.a, followClassColor=false }
                                            end
                                        end
                                        if C:IsEnabled(key) then
                                            pcall(function() skin:apply() end)
                                        else
                                            pcall(function() skin:remove() end)
                                        end
                                        -- Rebuild so the color swatches show the default
                                        if AklimeMod_BuildInterfaceContent then AklimeMod_BuildInterfaceContent() end
                                    end,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    insertColorizerNodes(dp3, filter)
    RSV():SetDataProvider(dp3)
end
AklimeMod_BuildInterfaceContent = BuildInterfaceContent

-- ============================================================
-- Quality of Life
-- ============================================================
local function addQoLNodes(dp)

    -- ============================================================
    -- Chat and Social
    -- ============================================================
    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_chat_social"], centered = true })
    end

    local chatNode = addModule(dp, L["mod_chat_interaction"],
        function()
            return AklimeMod_ChatInteraction.IsCopyPasteEnabled()
                or AklimeMod_ChatInteraction.IsClickLinksEnabled()
        end,
        function(v)
            AklimeMod_ChatInteraction.SetCopyPasteEnabled(v)
            AklimeMod_ChatInteraction.SetClickLinksEnabled(v)
        end
    )
    chatNode:Insert({
        Template = "AklimeMod_ToggleTemplate",
        name     = L["toggle_copy_chat"],
        getVal   = function() return AklimeMod_ChatInteraction.IsCopyPasteEnabled() end,
        setVal   = function(v)
            AklimeMod_ChatInteraction.SetCopyPasteEnabled(v)
            chatNode:SetCollapsed(true)
            chatNode:SetCollapsed(false)
        end,
    })
    chatNode:Insert({
        Template     = "AklimeMod_ToggleTemplate",
        name         = L["toggle_lock_cbtn"],
        getVal       = function() return AklimeMod_ChatInteraction.IsBtnLocked() end,
        setVal       = function(v) AklimeMod_ChatInteraction.SetBtnLocked(v) end,
        isDisabled   = function() return not AklimeMod_ChatInteraction.IsCopyPasteEnabled() end,
    })
    chatNode:Insert({
        Template = "AklimeMod_ToggleTemplate",
        name     = L["toggle_links_clickable"],
        getVal   = function() return AklimeMod_ChatInteraction.IsClickLinksEnabled() end,
        setVal   = function(v) AklimeMod_ChatInteraction.SetClickLinksEnabled(v) end,
    })
    addInfo(chatNode, L["info_chat_interaction"])

    if AklimeMod_ChatFade then
        local chatFadeNode = addModule(dp, L["mod_chat_fade"],
            function() return AklimeMod_ChatFade.IsEnabled() end,
            function(v) AklimeMod_ChatFade.SetEnabled(v) end
        )
        addInfo(chatFadeNode, L["info_fade_visible"])
        for _, opt in ipairs({
            { label = L["toggle_chat_15s"],  val = 15  },
            { label = L["toggle_chat_30s"],  val = 30  },
            { label = L["toggle_chat_60s"],  val = 60  },
            { label = L["toggle_chat_120s"], val = 120 },
        }) do
            local v = opt.val
            addToggle(chatFadeNode, opt.label,
                function() return AklimeMod_ChatFade.GetTimeVisible() == v end,
                function(on) if on then AklimeMod_ChatFade.SetTimeVisible(v); AklimeMod_RefreshRightToggles() end end
            )
        end
        addInfo(chatFadeNode, L["info_fade_duration"])
        for _, opt in ipairs({
            { label = L["toggle_fade_1s"], val = 1 },
            { label = L["toggle_fade_3s"], val = 3 },
            { label = L["toggle_fade_5s"], val = 5 },
        }) do
            local v = opt.val
            addToggle(chatFadeNode, opt.label,
                function() return AklimeMod_ChatFade.GetFadeDuration() == v end,
                function(on) if on then AklimeMod_ChatFade.SetFadeDuration(v); AklimeMod_RefreshRightToggles() end end
            )
        end
    end

    if AklimeMod_ChatHistory then
        local chatHistNode = addModule(dp, L["mod_chat_history"],
            function() return AklimeMod_ChatHistory:IsEnabled() end,
            function(v) AklimeMod_ChatHistory:SetEnabled(v) end
        )
        addSlider(chatHistNode, L["slider_max_messages"], 50, 500, 50,
            function() return AklimeMod_ChatHistory:GetMaxMessages() end,
            function(v) AklimeMod_ChatHistory:SetMaxMessages(v) end,
            tostring
        )
        addInfo(chatHistNode, L["info_chat_history"])
        addAction(chatHistNode, L["action_clear_all_windows"], function()
            AklimeMod_ChatHistory:ClearAll()
        end, nil, true)
        addAction(chatHistNode, L["action_clear_active"], function()
            AklimeMod_ChatHistory:ClearActive()
        end, nil, true)
    end

    if AklimeMod_ExtendedIgnore then
        local ignoreNode = addModule(dp, L["mod_ext_ignore"],
            function() return AklimeMod_ExtendedIgnore:IsEnabled() end,
            function(v) AklimeMod_ExtendedIgnore:SetEnabled(v) end
        )
        addInfo(ignoreNode, L["info_ext_ignore"])
        addAction(ignoreNode, L["action_open_ignore"], function()
            AklimeMod_ExtendedIgnore:ToggleWindow()
        end)
        addAction(ignoreNode, L["action_remove_all"], function()
            AklimeMod_ExtendedIgnore:ClearAll()
            print("|cFFFFD100Aklime Mod Tools:|r " .. L["msg_ignore_cleared"])
        end, nil, true)
    end

    local leaveServiceNode = addModule(dp, L["mod_leave_channel"],
        function() return AklimeMod_LeaveServiceChannel.IsEnabled() end,
        function(v) AklimeMod_LeaveServiceChannel.SetEnabled(v) end
    )
    addInfo(leaveServiceNode, L["info_leave_channel"])

    if AklimeMod_BlockRequests then
        local blockDuelNode = addModule(dp, L["mod_block_duel"],
            function() return AklimeMod_BlockRequests:IsDuelBlocked() end,
            function(v) AklimeMod_BlockRequests:SetBlockDuels(v) end
        )
        addInfo(blockDuelNode, L["info_block_duel"])

        local blockPetNode = addModule(dp, L["mod_block_petbattle"],
            function() return AklimeMod_BlockRequests:IsPetBattleBlocked() end,
            function(v) AklimeMod_BlockRequests:SetBlockPetBattles(v) end
        )
        addInfo(blockPetNode, L["info_block_petbattle"])
    end

    if AklimeMod_GroupInvites then
        local blockInviteNode = addModule(dp, L["mod_block_invite"],
            function() return AklimeMod_GroupInvites:IsBlockEnabled() end,
            function(v) AklimeMod_GroupInvites:SetBlock(v) end
        )
        addToggle(blockInviteNode, L["toggle_guild_exception"],
            function() return AklimeMod_GroupInvites:IsBlockExceptGuild() end,
            function(v) AklimeMod_GroupInvites:SetBlockExceptGuild(v) end
        )
        addToggle(blockInviteNode, L["toggle_friend_exception"],
            function() return AklimeMod_GroupInvites:IsBlockExceptFriend() end,
            function(v) AklimeMod_GroupInvites:SetBlockExceptFriend(v) end
        )
        addInfo(blockInviteNode, L["info_block_invite"])

        local autoAcceptNode = addModule(dp, L["mod_auto_invite"],
            function() return AklimeMod_GroupInvites:IsAutoAcceptEnabled() end,
            function(v) AklimeMod_GroupInvites:SetAutoAccept(v) end
        )
        addToggle(autoAcceptNode, L["toggle_guild_only"],
            function() return AklimeMod_GroupInvites:IsGuildOnly() end,
            function(v) AklimeMod_GroupInvites:SetGuildOnly(v) end
        )
        addToggle(autoAcceptNode, L["toggle_friend_only"],
            function() return AklimeMod_GroupInvites:IsFriendOnly() end,
            function(v) AklimeMod_GroupInvites:SetFriendOnly(v) end
        )
        addInfo(autoAcceptNode, L["info_auto_invite"])
    end

    if AklimeMod_Summons then
        local summonsNode = addModule(dp, L["mod_auto_summon"],
            function() return AklimeMod_Summons:IsEnabled() end,
            function(v) AklimeMod_Summons:SetEnabled(v) end
        )
        addSlider(summonsNode, L["slider_delay"], 0, 10, 1,
            function() return AklimeMod_Summons:GetDelay() end,
            function(v) AklimeMod_Summons:SetDelay(v) end,
            function(v)
                if v <= 0 then return L["fmt_instant"] end
                return v .. L["fmt_sec"]
            end
        )
        addInfo(summonsNode, L["info_auto_summon"])
    end

    if AklimeMod_FriendsListDecor then
        local friendsNode = addModule(dp, L["mod_friends_decor"],
            function() return AklimeMod_FriendsListDecor:IsEnabled() end,
            function(v) AklimeMod_FriendsListDecor:SetEnabled(v) end
        )
        addToggle(friendsNode, L["toggle_show_location"],
            function() return AklimeMod_FriendsListDecor:Get("showLocation") end,
            function(v) AklimeMod_FriendsListDecor:Set("showLocation", v) end
        )
        addToggle(friendsNode, L["toggle_hide_own_realm"],
            function() return AklimeMod_FriendsListDecor:Get("hideOwnRealm") end,
            function(v) AklimeMod_FriendsListDecor:Set("hideOwnRealm", v) end
        )
        addInfo(friendsNode, L["info_friends_decor"])
    end

    if AklimeMod_ChatFontSize then
        local chatSizeNode = addModule(dp, L["mod_chat_font_size"],
            function() return AklimeMod_ChatFontSize.IsEnabled() end,
            function(v) AklimeMod_ChatFontSize.SetEnabled(v) end
        )
        for _, size in ipairs(AklimeMod_ChatFontSize.GetSizes()) do
            addToggle(chatSizeNode, size .. "pt",
                function() return AklimeMod_ChatFontSize.GetSize() == size end,
                function(on) if on then AklimeMod_ChatFontSize.SetSize(size); AklimeMod_RefreshRightToggles() end end
            )
        end
        addInfo(chatSizeNode, L["info_chat_font_size"])
    end

    -- ============================================================
    -- General
    -- ============================================================
    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_general"], centered = true })
    end

    local vaultNode = addModule(dp, L["mod_weekly_vault"],
        function() return true end,
        function(v) end
    )
    addInfo(vaultNode, L["info_weekly_vault"])
    addAction(vaultNode, L["action_open_vault"], function()
        C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
        if WeeklyRewardsFrame:IsShown() then
            WeeklyRewardsFrame:Hide()
        else
            WeeklyRewardsFrame:Show()
        end
    end)

    if AklimeMod_ReadyCheck then
        local rcNode = addModule(dp, L["mod_ready_check"],
            function() return AklimeMod_ReadyCheck.IsEnabled() end,
            function(v) AklimeMod_ReadyCheck.SetEnabled(v) end
        )
        addSlider(rcNode, L["slider_delay"], 1, 6, 1,
            function() return AklimeMod_ReadyCheck.GetDelay() end,
            function(v) AklimeMod_ReadyCheck.SetDelay(v) end,
            function(v) return v .. L["fmt_sec"] end
        )
        addInfo(rcNode, L["info_ready_check"])
    end

    if AklimeMod_SkipCinematic then
        local scNode = addModule(dp, L["mod_skip_cinematic"],
            function() return AklimeMod_SkipCinematic.IsEnabled() end,
            function(v) AklimeMod_SkipCinematic.SetEnabled(v) end
        )
        addInfo(scNode, L["info_skip_cinematic"])
    end

    local repairNode = addModule(dp, L["mod_auto_repair"],
        function() return AklimeModDB.autoRepair.enabled end,
        function(v) AklimeModDB.autoRepair.enabled = v end
    )
    addToggle(repairNode, L["toggle_guild_repair"],
        function() return AklimeModDB.autoRepair.useGuild end,
        function(v) AklimeModDB.autoRepair.useGuild = v end
    )
    addToggle(repairNode, L["toggle_gold_repair"],
        function() return AklimeModDB.autoRepair.useGold end,
        function(v) AklimeModDB.autoRepair.useGold = v end
    )

    local reloadNode = addModule(dp, L["mod_reload_ui"],
        function() return AklimeModDB.reloadUI.enabled end,
        function(v)
            AklimeModDB.reloadUI.enabled = v
        end
    )
    addInfo(reloadNode, L["info_reload_ui"])
    -- Special row needs space for two command buttons stacked vertically
    addAction(reloadNode, "RELOAD_BUTTONS", nil, 70)

    local deleteNode
    local function easyDeleteMainEnabled()
        local db = AklimeModDB.easyDelete
        return db.skipDelete == true or db.skipConfirm == true
            or db.skipUnlearn == true or db.skipUnderstood == true
    end
    local function refreshDeleteNode()
        deleteNode:SetCollapsed(true); deleteNode:SetCollapsed(false)
    end
    deleteNode = addModule(dp, L["mod_easy_delete"],
        easyDeleteMainEnabled,
        function(v)
            AklimeModDB.easyDelete.skipDelete     = v
            AklimeModDB.easyDelete.skipConfirm    = v
            AklimeModDB.easyDelete.skipUnlearn    = v
            AklimeModDB.easyDelete.skipUnderstood = v
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, L["toggle_no_delete"],
        function() return AklimeModDB.easyDelete.skipDelete == true end,
        function(v)
            AklimeModDB.easyDelete.skipDelete = v
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, L["toggle_no_confirm"],
        function() return AklimeModDB.easyDelete.skipConfirm == true end,
        function(v)
            AklimeModDB.easyDelete.skipConfirm = v
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, L["toggle_no_unlearn"],
        function() return AklimeModDB.easyDelete.skipUnlearn == true end,
        function(v)
            AklimeModDB.easyDelete.skipUnlearn = v
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, L["toggle_no_understood"],
        function() return AklimeModDB.easyDelete.skipUnderstood == true end,
        function(v)
            AklimeModDB.easyDelete.skipUnderstood = v
            refreshDeleteNode()
        end
    )

    if AklimeMod_BuyConfirm then
        local buyNode = addModule(dp, L["mod_buy_confirm"],
            function() return AklimeMod_BuyConfirm.IsEnabled() end,
            function(v) AklimeMod_BuyConfirm.SetEnabled(v) end
        )
        addInfo(buyNode, L["info_buy_confirm"])

        local sellNode = addModule(dp, L["mod_sell_confirm"],
            function() return AklimeMod_BuyConfirm.IsRefundEnabled() end,
            function(v) AklimeMod_BuyConfirm.SetRefundEnabled(v) end
        )
        addInfo(sellNode, L["info_sell_confirm"])

        local noRefundNode = addModule(dp, L["mod_no_refund_confirm"],
            function() return AklimeMod_BuyConfirm.IsNoRefundEnabled() end,
            function(v) AklimeMod_BuyConfirm.SetNoRefundEnabled(v) end
        )
        addInfo(noRefundNode, L["info_no_refund_confirm"])
    end

    local sellJunkNode = addModule(dp, L["mod_auto_sell"],
        function() return AklimeMod_AutoSellJunk.IsEnabled() end,
        function(v) AklimeMod_AutoSellJunk.SetEnabled(v) end
    )
    addInfo(sellJunkNode, L["info_auto_sell"])

    local preyPctNode = addModule(dp, L["mod_prey_percent"],
        function() return AklimeMod_PreyPercent and AklimeMod_PreyPercent.IsEnabled() end,
        function(v)
            if AklimeMod_PreyPercent then AklimeMod_PreyPercent.SetEnabled(v) end
        end
    )
    addInfo(preyPctNode, L["info_prey_percent"])

    local clock24hNode = addModule(dp, L["mod_clock24h"],
        function() return AklimeMod_Clock24h.IsEnabled() end,
        function(v) AklimeMod_Clock24h.SetEnabled(v) end
    )
    addInfo(clock24hNode, L["info_clock24h"])

    local mapCoordsNode = addModule(dp, L["mod_map_coords"],
        function() return AklimeMod_MapCoords.IsEnabled() end,
        function(v) AklimeMod_MapCoords.SetEnabled(v) end
    )
    addInfo(mapCoordsNode, L["info_map_coords"])

    local microNotifNode = addModule(dp, L["mod_hide_micro_notify"],
        function() return AklimeMod_HideMicroNotifications.IsEnabled() end,
        function(v) AklimeMod_HideMicroNotifications.SetEnabled(v) end
    )
    addInfo(microNotifNode, L["info_hide_micro_notify"])

    if AklimeMod_ChatLearnFilter then
        local learnNode = addModule(dp, L["mod_learn_filter"],
            function() return AklimeMod_ChatLearnFilter:IsEnabled() end,
            function(v) AklimeMod_ChatLearnFilter:SetEnabled(v) end
        )
        addToggle(learnNode, L["toggle_hide_talent_bubble"],
            function() return AklimeMod_ChatLearnFilter:IsBubbleEnabled() end,
            function(v) AklimeMod_ChatLearnFilter:SetBubbleEnabled(v) end
        )
        addInfo(learnNode, L["info_learn_filter"])
    end

    if AklimeMod_ChatIcons then
        local chatIconsNode = addModule(dp, L["mod_chat_icons"],
            function() return AklimeMod_ChatIcons:IsEnabled() end,
            function(v) AklimeMod_ChatIcons:SetEnabled(v) end
        )
        addInfo(chatIconsNode, L["info_chat_icons"])
    end

    if AklimeMod_ChatIcons then
        local itemLevelNode = addModule(dp, L["mod_item_level"],
            function() return AklimeMod_ChatIcons:IsItemLevelEnabled() end,
            function(v) AklimeMod_ChatIcons:SetItemLevelEnabled(v) end
        )
        addToggle(itemLevelNode, L["toggle_show_slot"],
            function() return AklimeMod_ChatIcons:IsShowSlotEnabled() end,
            function(v) AklimeMod_ChatIcons:SetShowSlotEnabled(v) end
        )
        addInfo(itemLevelNode, L["info_item_level"])
    end

    if AklimeMod_Mailbox then
        local mailboxNode = addModule(dp, L["mod_mailbox"],
            function() return AklimeMod_Mailbox:IsEnabled() end,
            function(v) AklimeMod_Mailbox:SetEnabled(v) end
        )
        addToggle(mailboxNode, L["toggle_remember_recipient"],
            function() return AklimeMod_Mailbox:IsRememberLastRecipient() end,
            function(v) AklimeMod_Mailbox:SetRememberLastRecipient(v) end
        )
        addInfo(mailboxNode, L["info_mailbox"])
        addAction(mailboxNode, L["action_clear_contacts"], function()
            AklimeMod_Mailbox:ClearContacts()
        end, nil, true)
    end

    if AklimeMod_Merchant then
        local merchantNode = addModule(dp, L["mod_merchant"],
            function() return AklimeMod_Merchant:IsEnabled() end,
            function(v)
                if v then
                    AklimeMod_Merchant:Enable()
                    AklimeModDB.merchant.enabled = true
                else
                    AklimeMod_Merchant:Disable()
                    AklimeModDB.merchant.enabled = false
                end
            end
        )
        addInfo(merchantNode, L["info_merchant"])
    end

    -- ============================================================
    -- Gameplay
    -- ============================================================
    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_gameplay"], centered = true })
    end

    local manaNode = addModule(dp, L["mod_mana_warning"],
        function() return AklimeMod_ManaWarning.IsEnabled() end,
        function(v) AklimeMod_ManaWarning.SetEnabled(v) end
    )
    addInfo(manaNode, L["info_mana_warning"])

    if AklimeMod_HeroismTracker then
        local htNode = addModule(dp, L["mod_heroism_tracker"],
            function() return AklimeMod_HeroismTracker:IsEnabled() end,
            function(v) AklimeMod_HeroismTracker:SetEnabled(v) end
        )
        addToggle(htNode, L["toggle_lock_position"],
            function() return AklimeMod_HeroismTracker:IsLocked() end,
            function(v) AklimeMod_HeroismTracker:SetLocked(v) end
        )
        addSlider(htNode, L["slider_font_size"], 0, 100, 1,
            function() return AklimeMod_HeroismTracker:GetFontSizeSlider() end,
            function(v) AklimeMod_HeroismTracker:SetFontSizeSlider(v) end,
            function(v) return v == 0 and L["fmt_default"] or tostring(v) end
        )
        addAction(htNode, L["action_preview"], function()
            if AklimeMod_HeroismTracker.previewing then
                AklimeMod_HeroismTracker.previewing = false
                AklimeMod_HeroismTracker:HidePreview()
            else
                AklimeMod_HeroismTracker.previewing = true
                AklimeMod_HeroismTracker:ShowPreview()
            end
        end)
        addInfo(htNode, L["info_heroism_tracker"])
    end

    if AklimeMod_DeathSound then
        local deathNode = addModule(dp, L["mod_death_sound"],
            function() return AklimeMod_DeathSound:IsEnabled() end,
            function(v) AklimeMod_DeathSound:SetEnabled(v) end
        )
        addInfo(deathNode, L["info_death_sound"])
    end

    if AklimeMod_TalentReminder then
        local talentNode = addModule(dp, L["mod_talent_reminder"],
            function() return AklimeMod_TalentReminder:IsEnabled() end,
            function(v) AklimeMod_TalentReminder:SetEnabled(v) end
        )
        addInfo(talentNode, L["info_talent_reminder"])
    end

    -- ============================================================
    -- Quest
    -- ============================================================
    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_quest"], centered = true })
    end

    if AklimeMod_QuestAutomation then
        local autoQuestNode = addModule(dp, L["mod_auto_quest"],
            function() return AklimeMod_QuestAutomation:IsEnabled() end,
            function(v) AklimeMod_QuestAutomation:SetEnabled(v) end
        )
        addToggle(autoQuestNode, L["toggle_normal_quests"],
            function() return AklimeMod_QuestAutomation:IsAcceptNormal() end,
            function(v) AklimeMod_QuestAutomation:SetAcceptNormal(v) end
        )
        addToggle(autoQuestNode, L["toggle_daily_quests"],
            function() return AklimeMod_QuestAutomation:IsAcceptDailies() end,
            function(v) AklimeMod_QuestAutomation:SetAcceptDailies(v) end
        )
        addToggle(autoQuestNode, L["toggle_trivial_quests"],
            function() return AklimeMod_QuestAutomation:IsIgnoreTrivial() end,
            function(v) AklimeMod_QuestAutomation:SetIgnoreTrivial(v) end
        )
        addToggle(autoQuestNode, L["toggle_warband_quests"],
            function() return AklimeMod_QuestAutomation:IsIgnoreWarband() end,
            function(v) AklimeMod_QuestAutomation:SetIgnoreWarband(v) end
        )
        addToggle(autoQuestNode, L["toggle_auto_turnin"],
            function() return AklimeMod_QuestAutomation:IsAutoTurnIn() end,
            function(v) AklimeMod_QuestAutomation:SetAutoTurnIn(v) end
        )
        addToggle(autoQuestNode, L["toggle_skip_daily_turnin"],
            function() return AklimeMod_QuestAutomation:IsIgnoreDailiesTurnIn() end,
            function(v) AklimeMod_QuestAutomation:SetIgnoreDailiesTurnIn(v) end
        )
        addToggle(autoQuestNode, L["toggle_skip_weekly_turnin"],
            function() return AklimeMod_QuestAutomation:IsIgnoreWeekliesTurnIn() end,
            function(v) AklimeMod_QuestAutomation:SetIgnoreWeekliesTurnIn(v) end
        )
        addInfo(autoQuestNode, L["info_auto_quest"])
        addInfo(autoQuestNode, L["info_modifier"])
        for _, opt in ipairs({
            { label = L["modifier_none"],  val = "NONE"  },
            { label = L["modifier_shift"], val = "SHIFT" },
            { label = L["modifier_ctrl"],  val = "CTRL"  },
            { label = L["modifier_alt"],   val = "ALT"   },
        }) do
            local v = opt.val
            addToggle(autoQuestNode, opt.label,
                function() return AklimeMod_QuestAutomation:GetModifier() == v end,
                function(on) if on then AklimeMod_QuestAutomation:SetModifier(v); AklimeMod_RefreshRightToggles() end end
            )
        end
        addAction(autoQuestNode, L["action_clear_ignore"], function()
            AklimeMod_QuestAutomation:ClearIgnoredNPCs()
        end, nil, true)
    end

    if AklimeMod_QuestAutomation then
        local wowheadNode = addModule(dp, L["mod_wowhead_url"],
            function() return AklimeMod_QuestAutomation:IsWowheadLink() end,
            function(v) AklimeMod_QuestAutomation:SetWowheadLink(v) end
        )
        addInfo(wowheadNode, L["info_wowhead_url"])
    end

    if AklimeMod_QuestTracker then
        local trackerNode = addModule(dp, L["mod_quest_tracker"],
            function()
                return AklimeMod_QuestTracker:IsShowQuestCountEnabled()
                    or AklimeMod_QuestTracker:IsMinimizeButtonOnly()
                    or AklimeMod_QuestTracker:IsRememberStateEnabled()
            end,
            function(v)
                AklimeMod_QuestTracker:SetShowQuestCount(v)
                AklimeMod_QuestTracker:SetMinimizeButtonOnly(v)
                AklimeMod_QuestTracker:SetRememberState(v)
            end
        )
        addToggle(trackerNode, L["toggle_quest_count"],
            function() return AklimeMod_QuestTracker:IsShowQuestCountEnabled() end,
            function(v) AklimeMod_QuestTracker:SetShowQuestCount(v) end
        )
        addToggle(trackerNode, L["toggle_minimize_only"],
            function() return AklimeMod_QuestTracker:IsMinimizeButtonOnly() end,
            function(v) AklimeMod_QuestTracker:SetMinimizeButtonOnly(v) end
        )
        addToggle(trackerNode, L["toggle_remember_state"],
            function() return AklimeMod_QuestTracker:IsRememberStateEnabled() end,
            function(v) AklimeMod_QuestTracker:SetRememberState(v) end
        )
        addInfo(trackerNode, L["info_quest_tracker"])
    end

    -- ============================================================
    -- Health
    -- ============================================================
    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_health"], centered = true })
    end

    local drinkNode = addModule(dp, L["mod_drink_reminder"],
        function() return AklimeMod_DrinkReminder.IsEnabled() end,
        function(v) AklimeMod_DrinkReminder.SetEnabled(v) end
    )
    addInfo(drinkNode, L["info_drink_reminder"])
    addToggle(drinkNode, L["toggle_no_instance"],
        function() return AklimeMod_DrinkReminder.GetDisableInInstance() end,
        function(v) AklimeMod_DrinkReminder.SetDisableInInstance(v) end
    )
    addInfo(drinkNode, L["info_interval"])
    for _, opt in ipairs({
        { label = L["toggle_drink_30m"], minutes = 30  },
        { label = L["toggle_drink_1h"],  minutes = 60  },
        { label = L["toggle_drink_2h"],  minutes = 120 },
    }) do
        local m = opt.minutes
        addToggle(drinkNode, opt.label,
            function() return AklimeMod_DrinkReminder.GetInterval() == m end,
            function(v) if v then AklimeMod_DrinkReminder.SetInterval(m); AklimeMod_RefreshRightToggles() end end
        )
    end
    addAction(drinkNode, L["action_test_now"], function()
        AklimeMod_DrinkReminder.ShowNow()
    end)

    -- ============================================================
    -- Playtime
    -- ============================================================
    if currentSearchFilter == "" then
        dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = L["sec_playtime"], centered = true })
    end

    if AklimeMod_PlayedTime then
        local playedNode = addModule(dp, L["mod_played_time"],
            function() return AklimeModDB.playedTime.enabled end,
            function(v) AklimeModDB.playedTime.enabled = v end
        )
        addInfo(playedNode, L["info_played_time"])
        addAction(playedNode, L["action_delete_char"], function(anchor)
            local chars = AklimeMod_PlayedTime:GetSavedChars()
            local menu = MenuUtil.CreateContextMenu(anchor or UIParent, function(owner, rootDescription)
                if #chars == 0 then
                    rootDescription:CreateTitle(L["played_no_data"])
                    return
                end
                -- Fill by column, maximum 20 characters per column
                local columns = math.ceil(#chars / 20)
                if columns > 1 then
                    rootDescription:SetGridMode(MenuConstants.VerticalGridDirection, columns)
                end
                for _, rec in ipairs(chars) do
                    local key     = rec.key
                    local display = rec.display
                    rootDescription:CreateButton(rec.colorized or display, function()
                        AklimeMod_Confirm(display, function()
                            AklimeMod_PlayedTime:DeleteChar(key)
                        end)
                    end)
                end
            end)
            -- Center the menu on the screen. Second attempt one frame later
            -- in case the menu repositions itself during layout.
            local function centerMenu()
                local m = menu
                if (not m or not m.SetPoint) and Menu and Menu.GetManager then
                    local mgr = Menu.GetManager()
                    m = mgr and mgr.GetOpenMenu and mgr:GetOpenMenu()
                end
                if m and m.ClearAllPoints and m.SetPoint then
                    m:ClearAllPoints()
                    m:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                end
            end
            centerMenu()
            C_Timer.After(0, centerMenu)
        end)
        addAction(playedNode, L["action_delete_all"], function()
            AklimeMod_PlayedTime:DeleteAll()
        end, nil, true)
    end

end  -- addQoLNodes

local function BuildQoLContent()
    lastCategoryFn = BuildQoLContent
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Quality of Life")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    local dp = newDP()
    addQoLNodes(dp)
    RSV():SetDataProvider(dp)
end
AklimeMod_BuildQoLContent = BuildQoLContent  -- global fuer Module

-- ============================================================
-- PvP
-- ============================================================
local function addPvPNodes(dp)
    local npNode = addModule(dp, L["mod_nameplate_color"],
        function() return AklimeMod_PvPNameplateColor and AklimeMod_PvPNameplateColor.IsEnabled() end,
        function(v)
            if AklimeMod_PvPNameplateColor then AklimeMod_PvPNameplateColor.SetEnabled(v) end
        end
    )
    addInfo(npNode, L["info_nameplate_color"])

    local chatBlockNode = addModule(dp, L["mod_pvp_chat_block"],
        function() return AklimeMod_PvPChatBlock and AklimeMod_PvPChatBlock.IsEnabled() end,
        function(v)
            if AklimeMod_PvPChatBlock then AklimeMod_PvPChatBlock.SetEnabled(v) end
        end
    )
    addInfo(chatBlockNode, L["info_pvp_chat"])
end

local function BuildPvPContent()
    lastCategoryFn = BuildPvPContent
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("PvP")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    local dp = newDP()
    addPvPNodes(dp)
    RSV():SetDataProvider(dp)
end
AklimeMod_BuildPvPContent = BuildPvPContent

local function BuildEmpty(header)
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader(header)
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    RSV():SetDataProvider(newDP())
end

-- ============================================================
-- Collecting
-- ============================================================
local function BuildCollectingContent()
    lastCategoryFn = BuildCollectingContent
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader(L["cat_collecting"])
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    local dp = newDP()

    -- ── Currencies ────────────────────────────────────────────
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = L["sec_currencies"],
        centered = true,
    })

    local ALL_CURR_EXP = {
        {15,L["curr_cat_season"]},{14,L["curr_cat_raids"]},{13,L["curr_cat_pvp"]},
        {12,L["curr_cat_misc"]},{11,"Midnight"},{10,"The War Within"},{9,"Dragonflight"},
        {8,"Shadowlands"},{7,"Battle for Azeroth"},{6,"Legion"},
        {5,"Warlords of Draenor"},{4,"Mists of Pandaria"},{3,"Cataclysm"},{2,"WotLK"},
        {1,"TBC"},{0,"Classic"},
    }
    local CURR_BY_EXP = {}
    for _, ce in ipairs({
        -- Season (Morgenlicht- und Nebelwappen + season currencies)
        {id=3310,exp=15},{id=2803,exp=15},{id=3378,exp=15},{id=3418,exp=15},
        {id=3028,exp=15},{id=3356,exp=15},{id=3383,exp=15},{id=3341,exp=15},
        {id=3343,exp=15},{id=3345,exp=15},{id=3347,exp=15},{id=3212,exp=15},
        {id=3442,exp=15},{id=3443,exp=15},{id=3444,exp=15},{id=3445,exp=15},
        {id=3446,exp=15},{id=3465,exp=15},{id=3509,exp=15},
        -- Dungeon & Raid
        {id=1166,exp=14},
        -- Player vs Player
        {id=391,exp=13},{id=2123,exp=13},{id=1792,exp=13},{id=1602,exp=13},
        -- Miscellaneous
        {id=2588,exp=12},{id=402,exp=12},{id=81,exp=12},
        {id=3363,exp=12},{id=515,exp=12},{id=2032,exp=12},
        -- Midnight (content + artisan's acuity profession currencies)
        {id=3373,exp=11},{id=3405,exp=11},{id=3393,exp=11},{id=3316,exp=11},
        {id=3385,exp=11},{id=3376,exp=11},{id=3392,exp=11},{id=3379,exp=11},
        {id=3377,exp=11},{id=3400,exp=11},{id=3448,exp=11},
        {id=3256,exp=11},{id=3257,exp=11},{id=3258,exp=11},{id=3260,exp=11},
        {id=3261,exp=11},{id=3262,exp=11},{id=3263,exp=11},{id=3264,exp=11},
        {id=3265,exp=11},{id=3266,exp=11},
        -- The War Within
        {id=3220,exp=10},{id=3055,exp=10},{id=3093,exp=10},{id=3089,exp=10},
        {id=3090,exp=10},{id=3056,exp=10},{id=3218,exp=10},{id=3226,exp=10},
        {id=2815,exp=10},{id=3303,exp=10},{id=3149,exp=10},
        -- Dragonflight
        {id=2118,exp=9},{id=2657,exp=9},{id=2594,exp=9},{id=2650,exp=9},
        {id=2122,exp=9},{id=2777,exp=9},{id=2003,exp=9},
        -- Shadowlands
        {id=1754,exp=8},{id=1979,exp=8},{id=1885,exp=8},{id=1820,exp=8},
        {id=1931,exp=8},{id=2009,exp=8},{id=1819,exp=8},{id=1813,exp=8},
        {id=1828,exp=8},{id=1906,exp=8},{id=1767,exp=8},{id=1977,exp=8},
        {id=1816,exp=8},{id=1904,exp=8},
        -- Battle for Azeroth
        {id=1717,exp=7},{id=1716,exp=7},{id=1803,exp=7},{id=1299,exp=7},{id=1560,exp=7},
        {id=1755,exp=7},{id=1721,exp=7},{id=1710,exp=7},{id=1580,exp=7},
        {id=1719,exp=7},
        -- Legion
        {id=1149,exp=6},{id=1533,exp=6},{id=1342,exp=6},{id=1275,exp=6},
        {id=1226,exp=6},{id=1220,exp=6},{id=1273,exp=6},{id=1155,exp=6},
        {id=1508,exp=6},
        -- Warlords of Draenor
        {id=994,exp=5},{id=823,exp=5},{id=824,exp=5},
        {id=1101,exp=5},{id=1129,exp=5},
        -- Mists of Pandaria
        {id=738,exp=4},{id=752,exp=4},{id=776,exp=4},
        {id=777,exp=4},{id=789,exp=4},{id=697,exp=4},
        -- Cataclysm
        {id=416,exp=3},
        -- Wrath of the Lich King
        {id=241,exp=2},
        -- The Burning Crusade
        {id=1704,exp=1},
    }) do
        if not CURR_BY_EXP[ce.exp] then CURR_BY_EXP[ce.exp] = {} end
        CURR_BY_EXP[ce.exp][#CURR_BY_EXP[ce.exp]+1] = ce.id
    end

    local function GetCurrNameLocal(id)
        if C_CurrencyInfo then
            local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and info and info.name ~= "" then
                local icon = info.iconFileID
                local iconStr = icon and ("|T" .. icon .. ":14:14:0:0|t ") or ""
                return iconStr .. info.name, info.name
            end
        end
        return "ID:" .. id, "ID:" .. id
    end

    -- Umlaut-normalized sort key for A-Z on DE client as well
    local function CurrSortKey(s)
        if not s then return "" end
        s = s:lower()
        s = s:gsub("\195\164", "a")  -- ä
        s = s:gsub("\195\182", "o")  -- ö
        s = s:gsub("\195\188", "u")  -- ü
        s = s:gsub("\195\159", "ss") -- ß
        s = s:gsub("\195\132", "a")  -- Ä
        s = s:gsub("\195\150", "o")  -- Ö
        s = s:gsub("\195\156", "u")  -- Ü
        return s
    end

    for _, pair in ipairs(ALL_CURR_EXP) do
        local exp, expLabel = pair[1], pair[2]
        local ids = CURR_BY_EXP[exp]
        if ids then
            dp:Insert({
                Template = "AklimeMod_InfoTextTemplate",
                text     = "|cFF888888" .. expLabel .. "|r",
            })
            -- Sort currencies within expansion A-Z (by raw name, umlaut-normalized)
            local sorted = {}
            for _, id in ipairs(ids) do
                local display, raw = GetCurrNameLocal(id)
                sorted[#sorted+1] = { id = id, name = display, sortKey = CurrSortKey(raw) }
            end
            table.sort(sorted, function(a, b) return a.sortKey < b.sortKey end)

            for _, entry in ipairs(sorted) do
                local cid  = entry.id
                local name = entry.name
                dp:Insert({
                    Template = "AklimeMod_ToggleTemplate",
                    name     = name,
                    getVal   = function()
                        local db = AklimeModDB and AklimeModDB.savedInstances
                        return not (db and db.currencies and db.currencies[cid] == false)
                    end,
                    setVal   = function(v)
                        local db = AklimeModDB and AklimeModDB.savedInstances
                        if db then
                            db.currencies = db.currencies or {}
                            if v then
                                db.currencies[cid] = nil
                            else
                                db.currencies[cid] = false
                            end
                        end
                        local ctFrame = _G["AklimeModCTFrame"]
                        if ctFrame and ctFrame:IsShown() then
                            AklimeMod_CT_Refresh()
                        end
                    end,
                })
            end
        end
    end

    RSV():SetDataProvider(dp)
end

-- ============================================================
-- Global search (must come after all add*Nodes functions)
-- ============================================================
local function BuildGlobalSearch(filter)
    currentBuildFn = nil
    AklimeMod_SetRightHeader(string.format(L["search_header"], filter))
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)

    local dp = newDP()
    currentSearchFilter = filter:lower()

    dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = "Quality of Life", centered = true })
    addQoLNodes(dp)

    dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = "Interface", centered = true })
    addInterfaceNodes(dp)

    dp:Insert({ Template = "AklimeMod_SeparatorTemplate", label = "PvP", centered = true })
    addPvPNodes(dp)

    currentSearchFilter = ""
    RSV():SetDataProvider(dp)
end

function AklimeMod_InitSearch()
    local sb = _G["AklimeModSearchBox"]
    if not sb then return end
    sb:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        if not userInput then
            -- X button or programmatic clear: restore category
            if text == "" and lastCategoryFn then
                lastCategoryFn()
            end
            return
        end
        if text ~= "" then
            BuildGlobalSearch(text)
        elseif lastCategoryFn then
            lastCategoryFn()
        end
    end)
    sb:SetScript("OnEscapePressed", function(self)
        self:SetText(""); self:ClearFocus()
        if lastCategoryFn then lastCategoryFn() end
    end)
end

-- ============================================================
-- Left category buttons
-- ============================================================
local categories = {
    { order=1, name="Dashboard",       callback=BuildDashboardContent                        },
    { order=2, name="Interface",       callback=BuildInterfaceContent                        },
    { order=3, name="Quality of Life", callback=BuildQoLContent                              },
    { order=4, name=L["cat_collecting"], callback=BuildCollectingContent                      },
    { order=5, name="PvP",             callback=function() AklimeMod_BuildPvPContent() end   },
}

local function SetSelected(clickedButton)
    LSV():FindFrameByPredicate(function(btn)
        btn._selected = false
        AklimeMod_ApplyRowTheme(btn)
        if btn.name then btn.name:SetTextColor(1, 1, 1, 1) end
    end)
    clickedButton._selected = true
    AklimeMod_ApplyRowTheme(clickedButton)
    -- Bright text on the deep amber selection
    if clickedButton.name then clickedButton.name:SetTextColor(1, 0.89, 0.62, 1) end
end

-- Rounded box: the tooltip border provides the rounded corners,
-- fill and border color come from AklimeMod_ApplyRowTheme
local CATEGORY_BACKDROP = {
    bgFile   = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function LeftInitializer(button, data)
    if not button._isCategory then
        button._isCategory = true
        button:SetBackdrop(CATEGORY_BACKDROP)
        button:SetScript("OnEnter", function(self)
            local a = AklimeMod_Theme and AklimeMod_Theme.accent
            if a then self:SetBackdropBorderColor(a.r, a.g, a.b, 1) end
        end)
        button:SetScript("OnLeave", function(self)
            AklimeMod_ApplyRowTheme(self)
        end)
    end
    AklimeMod_ApplyRowTheme(button)
    button.name:SetText(data.name)
    button:SetScript("OnClick", function(self)
        if self._selected then return end
        SetSelected(self)
        data.callback()
    end)
    if data.order == 1 then SetSelected(button); data.callback() end
end

LSV():SetElementInitializer("AklimeMod_CategoryButtonTemplate", LeftInitializer)

function AklimeMod_BuildLeftPanel()
    local dp = CreateDataProvider()
    for _, cat in ipairs(categories) do dp:Insert(cat) end
    LSV():SetDataProvider(dp)
end
