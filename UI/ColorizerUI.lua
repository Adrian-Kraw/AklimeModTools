-- UI/ColorizerUI.lua
local L = AklimeModL or {}
-- Sub color UI for the colorizer.
-- Swatch button is round and shows the current color.
-- The followClassColor checkbox switches to the class color and the swatch then shows the class icon.
-- There is no lock button.

-- ============================================================
-- Class icon atlas (WoW has 13 classes)
-- ============================================================
local classIconAtlas = {
    DEATHKNIGHT = "classicon-deathknight",
    DEMONHUNTER = "classicon-demonhunter",
    DRUID       = "classicon-druid",
    EVOKER      = "classicon-evoker",
    HUNTER      = "classicon-hunter",
    MAGE        = "classicon-mage",
    MONK        = "classicon-monk",
    PALADIN     = "classicon-paladin",
    PRIEST      = "classicon-priest",
    ROGUE       = "classicon-rogue",
    SHAMAN      = "classicon-shaman",
    WARLOCK     = "classicon-warlock",
    WARRIOR     = "classicon-warrior",
}

local playerClass = select(2, UnitClass("player"))

-- ============================================================
-- Swatch helper
-- ============================================================
local function SetSwatchFromDB(colorPicker, skinKey, colorKey)
    if not colorPicker or not colorPicker.swatch then return end
    local db = AklimeModDB.colorizer[skinKey]
    local co = db and db.colors and db.colors[colorKey]
    if co and co.followClassColor then
        -- Show class icon instead of color
        local atlas = classIconAtlas[playerClass]
        if atlas then
            colorPicker.swatch:SetAtlas(atlas)
        else
            colorPicker.swatch:SetColorTexture(1, 1, 1, 1)
        end
    else
        -- Show the stored color
        colorPicker.swatch:SetAtlas(nil)  -- reset atlas
        if co then
            colorPicker.swatch:SetColorTexture(co.r, co.g, co.b, 1)
        else
            colorPicker.swatch:SetColorTexture(0.28, 0.28, 0.28, 1)
        end
    end
end

-- ============================================================
-- Global color row initializer
-- ============================================================
do
    local C = AklimeMod_Colorizer
    function C.ApplyGlobalColor(r, g, b, a)
        AklimeModDB.colorizer.__globalColor = { r=r, g=g, b=b, a=a }
        for _, group in ipairs(C.groupOrder) do
            for _, key in ipairs(group.keys) do
                local skinDB = AklimeModDB.colorizer[key]
                if skinDB and skinDB.colors then
                    for ck in pairs(skinDB.colors) do
                        local co = skinDB.colors[ck]
                        co.r = r; co.g = g; co.b = b; co.a = a
                        co.followClassColor = false
                    end
                end
            end
        end
        for _, group in ipairs(C.groupOrder) do
            for _, key in ipairs(group.keys) do
                if C:IsEnabled(key) then
                    local skin = C.skins[key]
                    if skin then pcall(function() skin:apply() end) end
                end
            end
        end
    end
end

local function globalColorInitializer(button, node)
    local C = AklimeMod_Colorizer
    if button.name then button.name:SetText(L["color_apply_global"]) end
    if button.followClassColor then button.followClassColor:Hide() end

    local function getColor()
        return AklimeModDB.colorizer.__globalColor or { r=0.28, g=0.28, b=0.28, a=1 }
    end

    local function refreshSwatch()
        local co = getColor()
        if button.colorPicker and button.colorPicker.swatch then
            button.colorPicker.swatch:SetAtlas(nil)
            button.colorPicker.swatch:SetColorTexture(co.r, co.g, co.b, 1)
        end
    end
    refreshSwatch()

    if button.colorPicker then
        button.colorPicker:SetEnabled(true)
        button.colorPicker:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["color_global_title"] or "Set Global Color", 1, 1, 1)
            GameTooltip:AddLine(L["color_global_desc"]  or "Sets this color for all color slots of all skins", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        button.colorPicker:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.colorPicker:SetScript("OnClick", function()
            local co = getColor()
            local oldR, oldG, oldB, oldA = co.r, co.g, co.b, co.a
            local function onChange()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                C.ApplyGlobalColor(nr, ng, nb, na)
                refreshSwatch()
            end
            ColorPickerFrame:Hide()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc  = onChange,
                opacityFunc = onChange,
                cancelFunc  = function()
                    C.ApplyGlobalColor(oldR, oldG, oldB, oldA)
                    refreshSwatch()
                end,
                hasOpacity = true,
                opacity    = co.a or 1,
                r = co.r, g = co.g, b = co.b,
            })
        end)
    end
end

-- ============================================================
-- Sub color row initializer
-- ============================================================
local function subColorInitializer(button, node)
    if button.followClassColor then button.followClassColor:Show() end
    local d  = node:GetData()
    local C  = AklimeMod_Colorizer

    if button.name then button.name:SetText(d.colorLabel or "") end

    local function getEntry()
        local db = AklimeModDB.colorizer[d.skinKey]
        return db and db.colors and db.colors[d.colorKey]
    end

    -- Set swatch initially
    SetSwatchFromDB(button.colorPicker, d.skinKey, d.colorKey)

    -- followClassColor Checkbox
    local entry = getEntry()
    if button.followClassColor then
        button.followClassColor:SetChecked(entry and entry.followClassColor or false)
        -- Tooltip
        button.followClassColor:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["color_use_class"]      or "Use Class Color", 1, 1, 1)
            GameTooltip:AddLine(L["color_use_class_desc"] or "When active: swatch shows your class icon", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        button.followClassColor:SetScript("OnLeave", function() GameTooltip:Hide() end)

        button.followClassColor:SetScript("OnClick", function(self)
            local e = getEntry()
            if not e then return end
            e.followClassColor = self:GetChecked()
            -- Update swatch
            SetSwatchFromDB(button.colorPicker, d.skinKey, d.colorKey)
            -- Disable ColorPicker when class color is active
            if button.colorPicker then
                button.colorPicker:SetEnabled(not e.followClassColor)
            end
            -- Reapply skin
            if C:IsEnabled(d.skinKey) then
                local skin = C.skins[d.skinKey]
                if skin then pcall(function() skin:apply() end) end
            end
        end)

        -- Disable ColorPicker initially when followClassColor is active
        if button.colorPicker and entry and entry.followClassColor then
            button.colorPicker:SetEnabled(false)
        elseif button.colorPicker then
            button.colorPicker:SetEnabled(true)
        end
    end

    -- ColorPicker Tooltip
    if button.colorPicker then
        button.colorPicker:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(L["color_choose"] or "Choose Color", 1, 1, 1)
            GameTooltip:Show()
        end)
        button.colorPicker:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- ColorPicker click opens the WoW ColorPickerFrame
        button.colorPicker:SetScript("OnClick", function()
            local e = getEntry()
            if not e or e.followClassColor then return end

            local oldR, oldG, oldB, oldA = e.r, e.g, e.b, e.a

            local function onChange()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                e.r, e.g, e.b, e.a = nr, ng, nb, na
                SetSwatchFromDB(button.colorPicker, d.skinKey, d.colorKey)
                -- Live-Update
                if C:IsEnabled(d.skinKey) then
                    local skin = C.skins[d.skinKey]
                    if skin then pcall(function() skin:apply() end) end
                end
            end

            ColorPickerFrame:Hide()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc  = onChange,
                opacityFunc = onChange,
                cancelFunc  = function()
                    e.r, e.g, e.b, e.a = oldR, oldG, oldB, oldA
                    SetSwatchFromDB(button.colorPicker, d.skinKey, d.colorKey)
                    if C:IsEnabled(d.skinKey) then
                        local skin = C.skins[d.skinKey]
                        if skin then pcall(function() skin:apply() end) end
                    end
                end,
                hasOpacity = true,
                opacity    = e.a or 1,
                r = e.r, g = e.g, b = e.b,
            })
        end)
    end
end

-- ============================================================
-- Color-all row: sets all color slots of ONE skin to
-- the same color (like the global color, but only one skin)
-- ============================================================
local function skinAllColorInitializer(button, node)
    local d = node:GetData()
    local C = AklimeMod_Colorizer

    if button.followClassColor then button.followClassColor:Hide() end
    if button.name then button.name:SetText(d.colorLabel or "") end

    local function getColors()
        local db = AklimeModDB.colorizer[d.skinKey]
        return db and db.colors
    end

    local function refreshSwatch()
        local colors = getColors()
        local co = colors and colors.main
        if button.colorPicker and button.colorPicker.swatch and co then
            button.colorPicker.swatch:SetAtlas(nil)
            button.colorPicker.swatch:SetColorTexture(co.r, co.g, co.b, 1)
        end
    end
    refreshSwatch()

    local function applySkin()
        if C:IsEnabled(d.skinKey) then
            local skin = C.skins[d.skinKey]
            if skin then pcall(function() skin:apply() end) end
        end
    end

    local function setAll(r, g, b, a)
        local colors = getColors()
        local skin = C.skins[d.skinKey]
        if not colors or not skin or not skin.colors then return end
        for ck in pairs(skin.colors) do
            colors[ck] = { r = r, g = g, b = b, a = a, followClassColor = false }
        end
        applySkin()
        refreshSwatch()
    end

    if button.colorPicker then
        button.colorPicker:SetEnabled(true)
        button.colorPicker:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(d.colorLabel or "", 1, 1, 1)
            GameTooltip:AddLine(L["color_global_desc"] or "Sets this color for all color slots", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        button.colorPicker:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.colorPicker:SetScript("OnClick", function()
            local colors = getColors()
            if not colors then return end
            -- Snapshot for cancel: restores the individual colors
            local snapshot = {}
            for ck, co in pairs(colors) do
                snapshot[ck] = { r = co.r, g = co.g, b = co.b, a = co.a, followClassColor = co.followClassColor }
            end
            local start = colors.main or { r = 0.28, g = 0.28, b = 0.28, a = 1 }
            local function onChange()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                setAll(nr, ng, nb, na)
            end
            ColorPickerFrame:Hide()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc  = onChange,
                opacityFunc = onChange,
                cancelFunc  = function()
                    local cur = getColors()
                    if cur then
                        for ck, co in pairs(snapshot) do cur[ck] = co end
                    end
                    applySkin()
                    refreshSwatch()
                end,
                hasOpacity = true,
                opacity    = start.a or 1,
                r = start.r, g = start.g, b = start.b,
            })
        end)
    end
end

-- ============================================================
-- Skin-Header Initializer
-- ============================================================
local function skinHeaderInitializer(button, node)
    local d = node:GetData()
    local C = AklimeMod_Colorizer

    AklimeMod_ApplyRowTheme(button)
    if button.name then button.name:SetText(d.name or "") end
    button.enableButton:SetChecked(C:IsEnabled(d.skinKey))

    local function isEnabled() return C:IsEnabled(d.skinKey) end

    local function updateVisuals()
        local enabled = isEnabled()
        local collapsed = node:IsCollapsed()
        if button.name then
            if enabled then
                button.name:SetTextColor(GameFontNormalLeft:GetTextColor())
            else
                button.name:SetTextColor(0.5, 0.5, 0.5, 1)
            end
        end
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
    updateVisuals()

    -- For AklimeMod_RefreshRightToggles: update checkbox and visuals
    -- when a master toggle (group / all) changes the skin status.
    button._refreshCheckbox = function()
        button.enableButton:SetChecked(C:IsEnabled(d.skinKey))
        updateVisuals()
    end

    button:SetScript("PreClick", function(self, mouseButton)
        if not isEnabled() then
            node:SetCollapsed(true)
        end
    end)

    button:SetScript("OnClick", function()
        if not isEnabled() then
            node:SetCollapsed(true)
            updateVisuals()
            return
        end
        node:ToggleCollapsed()
        updateVisuals()
    end)

    button.enableButton:SetScript("OnClick", function(self)
        local v = self:GetChecked()
        AklimeModDB.colorizer[d.skinKey].enabled = v
        local skin = C.skins[d.skinKey]
        if skin then
            if v then
                pcall(function() skin:apply() end)
            else
                pcall(function() skin:remove() end)
            end
        end
        if not v then node:SetCollapsed(true) end
        updateVisuals()
    end)
end

-- ============================================================
-- Toggle initializer (skin internal toggles)
-- ============================================================
local function skinToggleInitializer(button, node)
    local d  = node:GetData()
    local C  = AklimeMod_Colorizer
    if button.name then button.name:SetText(d.toggleLabel or "") end
    local db = AklimeModDB.colorizer[d.skinKey]
    if button.toggle then
        -- Recycled frames can carry a _refreshCheckbox from the previous
        -- occupant, so always set it fresh here.
        button._refreshCheckbox = function()
            button.toggle:SetChecked(db and db.toggles and db.toggles[d.toggleKey] or false)
        end
        button.toggle:SetChecked(db and db.toggles and db.toggles[d.toggleKey] or false)
        button.toggle:SetScript("OnClick", function(self)
            if db and db.toggles then db.toggles[d.toggleKey] = self:GetChecked() end
            if C:IsEnabled(d.skinKey) then
                local skin = C.skins[d.skinKey]
                if skin then
                    pcall(function() skin:remove() end)
                    pcall(function() skin:apply()  end)
                end
            end
        end)
    end
end

-- ============================================================
-- Separator Initializer
-- ============================================================
local function separatorInitializer(frame, node)
    local data = node:GetData()
    AklimeMod_ApplyRowTheme(frame)
    if not frame.label then return end
    frame.label:SetText(data.label or "")
    if data.centered then
        frame.label:SetFont(GameFontNormalLarge:GetFont())
        frame.label:SetTextColor(1, 0.82, 0, 1)
        frame.label:SetJustifyH("CENTER")
        frame.label:ClearAllPoints()
        frame.label:SetPoint("LEFT",  frame, "LEFT",  0, 0)
        frame.label:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    elseif data.sublabel then
        -- Sub heading: same position, but more readable
        frame.label:SetFont(GameFontHighlight:GetFont())
        frame.label:SetTextColor(0.75, 0.75, 0.75, 1)
        frame.label:SetJustifyH("LEFT")
        frame.label:ClearAllPoints()
        frame.label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    else
        frame.label:SetFont(GameFontNormalLarge:GetFont())
        frame.label:SetTextColor(1, 0.82, 0, 1)
        frame.label:SetJustifyH("LEFT")
        frame.label:ClearAllPoints()
        frame.label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    end
end

-- ============================================================
-- Element factory (extended, also supports module headers for Elite/Rare)
-- ============================================================
function AklimeMod_ColorizerRightFactory(factory, node)
    local d = node:GetData()
    local t = d.Template
    if t == "AklimeMod_SkinHeaderTemplate" then
        factory(t, skinHeaderInitializer)
    elseif t == "AklimeMod_SubColorTemplate" and d.isGlobalColor then
        factory(t, globalColorInitializer)
    elseif t == "AklimeMod_SubColorTemplate" and d.skinAllColor then
        factory(t, skinAllColorInitializer)
    elseif t == "AklimeMod_SubColorTemplate" then
        factory(t, subColorInitializer)
    elseif t == "AklimeMod_ToggleTemplate" and d.toggleKey then
        factory(t, skinToggleInitializer)
    elseif t == "AklimeMod_ToggleTemplate" then
        -- Normal toggle for Elite/Rare
        factory(t, function(btn, nd)
            local data = nd:GetData()
            btn._refreshCheckbox = function() btn.toggle:SetChecked(data.getVal()) end
            if btn.name then btn.name:SetText(data.name or "") end
            btn.toggle:SetChecked(data.getVal())
            btn.toggle:SetScript("OnClick", function(self)
                data.setVal(self:GetChecked())
                self:SetChecked(data.getVal())
            end)
        end)
    elseif t == "AklimeMod_ModuleHeaderTemplate" then
        factory(t, function(button, nd)
            local data = nd:GetData()
            AklimeMod_ApplyRowTheme(button)
            if button.name then button.name:SetText(data.name or "") end
            button.enableButton:SetChecked(data.getEnabled())

            local function isEnabled() return data.getEnabled() end

            local function updateVisuals()
                local enabled = isEnabled()
                local collapsed = nd:IsCollapsed()
                if not enabled then
                    if not collapsed then nd:SetCollapsed(true) end
                    if button.Right          then button.Right:SetAlpha(0.25) end
                    if button.HighlightRight then button.HighlightRight:SetAlpha(0) end
                else
                    local atlas = collapsed and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded"
                    if button.Right          then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize); button.Right:SetAlpha(1) end
                    if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize); button.HighlightRight:SetAlpha(1) end
                end
            end
            updateVisuals()

            button._refreshCheckbox = function()
                button.enableButton:SetChecked(data.getEnabled())
                updateVisuals()
            end

            button:SetScript("PreClick", function(self, mouseButton)
                if not isEnabled() then nd:SetCollapsed(true) end
            end)
            button:SetScript("OnClick", function()
                if not isEnabled() then nd:SetCollapsed(true); updateVisuals(); return end
                nd:ToggleCollapsed(); updateVisuals()
            end)
            button.enableButton:SetScript("OnClick", function(self)
                data.setEnabled(self:GetChecked()); updateVisuals()
            end)
        end)
    elseif t == "AklimeMod_SeparatorTemplate" then
        factory(t, separatorInitializer)
    elseif t == "AklimeMod_InfoTextTemplate" then
        factory(t, function(frame, nd)
            if frame.info then frame.info:SetText(nd:GetData().text or "") end
        end)
    elseif t == "AklimeMod_ActionButtonTemplate" then
        factory(t, function(frame, nd)
            local data = nd:GetData()
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
        end)
    elseif t == "AklimeMod_SliderTemplate" then
        factory(t, AklimeMod_SliderInitializer)
    end
end