-- Modules/Interface/Colorizer/ColorizerCore.lua
-- Shared base: registry, cache, helpers, init

AklimeMod_Colorizer = AklimeMod_Colorizer or {}
local C = AklimeMod_Colorizer

C.skins      = C.skins      or {}
C.groupOrder = C.groupOrder or {}

-- Default colors used as the base theme for every skin.
C.defaults = {
    main       = { r=0.28, g=0.28, b=0.28, a=1 },
    background = { r=0.55, g=0.55, b=0.55, a=1 },
    borders    = { r=0.20, g=0.20, b=0.20, a=1 },
    controls   = { r=0.50, g=0.50, b=0.50, a=1 },
    tabs       = { r=0.18, g=0.18, b=0.18, a=1 },
}

-- Class colors (all 13 WoW classes)
C.classColors = {
    DEATHKNIGHT = {r=0.77,g=0.12,b=0.23},
    DEMONHUNTER = {r=0.64,g=0.19,b=0.79},
    DRUID       = {r=1.00,g=0.49,b=0.04},
    EVOKER      = {r=0.20,g=0.58,b=0.50},
    HUNTER      = {r=0.67,g=0.83,b=0.45},
    MAGE        = {r=0.25,g=0.78,b=0.92},
    MONK        = {r=0.00,g=1.00,b=0.60},
    PALADIN     = {r=0.96,g=0.55,b=0.73},
    PRIEST      = {r=1.00,g=1.00,b=1.00},
    ROGUE       = {r=1.00,g=0.96,b=0.41},
    SHAMAN      = {r=0.00,g=0.44,b=0.87},
    WARLOCK     = {r=0.53,g=0.53,b=0.90},
    WARRIOR     = {r=0.78,g=0.61,b=0.43},
}

-- Midnight hands out some unit data as secret values, e.g. the class of a
-- target in restricted situations. A secret cannot be used as a table key or
-- in a boolean test. It counts as unknown here and the caller keeps its
-- current color.
local REACTION_FRIENDLY = { r = 0, g = 1, b = 0 }
local REACTION_HOSTILE  = { r = 1, g = 0, b = 0 }

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

function C.GetUnitClassColor(unit)
    local _, class = UnitClass(unit)
    if not class or IsSecret(class) then return nil end
    return C.classColors[class]
end

-- Class color if known, otherwise green or red by reaction
function C.GetUnitClassOrReactionColor(unit)
    local cc = C.GetUnitClassColor(unit)
    if cc then return cc end
    local friendly = UnitIsFriend(unit, "player")
    if IsSecret(friendly) then return nil end
    return friendly and REACTION_FRIENDLY or REACTION_HOSTILE
end

-- ============================================================
-- Skin-Registry
-- ============================================================
function C:Register(key, def)
    def.key = key
    self.skins[key] = def
end

-- ============================================================
-- Original-Cache 
-- ============================================================
local origCache = {}

local function CacheTex(tex)
    if not tex or origCache[tex] then return end
    local r,g,b,a = tex:GetVertexColor()
    local d = (tex.GetDesaturation and tex:GetDesaturation()) or 0
    origCache[tex] = { r=r or 1, g=g or 1, b=b or 1, a=a or 1, d=d }
end

function C.Tint(tex, r, g, b, a)
    if not tex then return end
    CacheTex(tex)
    tex:SetDesaturation(1)
    tex:SetVertexColor(r, g, b, a or 1)
end

function C.TintAll(list, r, g, b, a)
    for _, tex in pairs(list) do C.Tint(tex, r, g, b, a) end
end

function C.TintRGBA(tex, col)
    if not tex or not col then return end
    C.Tint(tex, col[1], col[2], col[3], col[4] or 1)
end

function C.TintAllRGBA(list, col)
    for _, tex in pairs(list) do C.TintRGBA(tex, col) end
end

function C.Restore(tex)
    if not tex then return end
    local o = origCache[tex]
    if o then
        tex:SetDesaturation(o.d)
        tex:SetVertexColor(o.r, o.g, o.b, o.a)
    else
        tex:SetDesaturation(0)
        tex:SetVertexColor(1, 1, 1, 1)
    end
end

function C.RestoreAll(list)
    for _, tex in pairs(list) do C.Restore(tex) end
end

-- Alpha preserving (for chat background etc.)
function C.TintAlpha(tex, r, g, b)
    if not tex then return end
    CacheTex(tex)
    tex:SetDesaturation(1)
    tex:SetVertexColor(r, g, b, tex:GetAlpha())
end

function C.RestoreAlpha(tex)
    if not tex then return end
    local o = origCache[tex]
    if o then
        tex:SetDesaturation(o.d)
        tex:SetVertexColor(o.r, o.g, o.b, tex:GetAlpha())
    else
        tex:SetDesaturation(0)
        tex:SetVertexColor(0, 0, 0, tex:GetAlpha())
    end
end

-- ============================================================
-- Helper functions for tinting and restoring frame textures.
-- ============================================================

-- NineSlice
function C.NS(frame, r, g, b, a)
    if not frame or not frame.NineSlice then return end
    C.TintAll({
        frame.NineSlice.TopEdge,         frame.NineSlice.BottomEdge,
        frame.NineSlice.TopRightCorner,  frame.NineSlice.TopLeftCorner,
        frame.NineSlice.RightEdge,       frame.NineSlice.LeftEdge,
        frame.NineSlice.BottomRightCorner, frame.NineSlice.BottomLeftCorner,
    }, r, g, b, a)
end

function C.NSr(frame)
    if not frame or not frame.NineSlice then return end
    C.RestoreAll({
        frame.NineSlice.TopEdge,         frame.NineSlice.BottomEdge,
        frame.NineSlice.TopRightCorner,  frame.NineSlice.TopLeftCorner,
        frame.NineSlice.RightEdge,       frame.NineSlice.LeftEdge,
        frame.NineSlice.BottomRightCorner, frame.NineSlice.BottomLeftCorner,
    })
end

-- Border around an aura icon, built from four plain textures.
--
-- A backdrop frame cannot be used here: the size of an aura icon is a secret
-- value in 12.0, an anchored frame inherits that, and Blizzard's Backdrop code
-- multiplies the width when laying out its pieces. That throws once per resize.
-- Textures get their length from their anchors in C and need no size math.
function C.IconBorder(widget, anchor, inset, thickness)
    local existing = widget.border
    if existing and existing.edges then return existing end
    if existing then existing:Hide() end   -- backdrop border from an older version

    local i = inset or 2
    local t = thickness or 1

    local f = CreateFrame("Frame", nil, widget)
    f:SetAllPoints(widget)

    local top = f:CreateTexture(nil, "OVERLAY")
    top:SetPoint("BOTTOMLEFT",  anchor, "TOPLEFT",  -i, i)
    top:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT",  i, i)
    top:SetHeight(t)

    local bottom = f:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("TOPLEFT",  anchor, "BOTTOMLEFT",  -i, -i)
    bottom:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT",  i, -i)
    bottom:SetHeight(t)

    local left = f:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPRIGHT",    anchor, "TOPLEFT",    -i,  i)
    left:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMLEFT", -i, -i)
    left:SetWidth(t)

    local right = f:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPLEFT",    anchor, "TOPRIGHT",    i,  i)
    right:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT", i, -i)
    right:SetWidth(t)

    f.edges = { top, bottom, left, right }
    widget.border = f
    return f
end

function C.IconBorderColor(border, r, g, b, a)
    if not border or not border.edges then return end
    for _, edge in ipairs(border.edges) do
        edge:SetColorTexture(r, g, b, a)
    end
    border:Show()
end

-- SkinBox (EditBox Left/Middle/Right)
function C.SkinBox(box, r, g, b, a)
    if not box then return end
    C.TintAll({ box.Left, box.Middle, box.Right }, r, g, b, a)
end

-- SkinTabs supports TabSystem and direct Left/Middle/Right
function C.SkinTabs(tab, r, g, b, a)
    if not tab then return end
    if tab.TabSystem then
        for _, t in pairs({ tab.TabSystem:GetChildren() }) do
            C.TintAll({ t.Left, t.Middle, t.Right }, r, g, b, a)
        end
    else
        C.TintAll({ tab.Left, tab.Middle, tab.Right }, r, g, b, a)
    end
end

function C.RestoreTabs(tab)
    if not tab then return end
    if tab.TabSystem then
        for _, t in pairs({ tab.TabSystem:GetChildren() }) do
            C.RestoreAll({ t.Left, t.Middle, t.Right })
        end
    else
        C.RestoreAll({ tab.Left, tab.Middle, tab.Right })
    end
end

-- SkinScrollBarOf
function C.SkinScrollBar(frame, r, g, b, a)
    if not frame or not frame.ScrollBar then return end
    local sb = frame.ScrollBar
    C.TintAll({
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Begin,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Middle,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.End,
        sb.Back and sb.Back.Texture,
        sb.Forward and sb.Forward.Texture,
    }, r, g, b, a)
end

function C.RestoreScrollBar(frame)
    if not frame or not frame.ScrollBar then return end
    local sb = frame.ScrollBar
    C.RestoreAll({
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Begin,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Middle,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.End,
        sb.Back and sb.Back.Texture,
        sb.Forward and sb.Forward.Texture,
    })
end

-- SkinBorderOf supports frame.Border, frame.BorderTopMiddle, frame.TopLeftTex
function C.SkinBorder(frame, r, g, b, a)
    if not frame then return end
    local textures = {}
    if type(frame) == "table" then
        if frame.Border then
            textures = {
                frame.Border.TopEdge,    frame.Border.TopRightCorner,
                frame.Border.RightEdge,  frame.Border.BottomRightCorner,
                frame.Border.BottomEdge, frame.Border.BottomLeftCorner,
                frame.Border.LeftEdge,   frame.Border.TopLeftCorner,
            }
        elseif frame.TopLeftTex then
            textures = {
                frame.TopLeftTex,    frame.TopTex,    frame.TopRightTex,
                frame.RightTex,      frame.BottomRightTex, frame.BottomTex,
                frame.BottomLeftTex, frame.LeftTex,
            }
        elseif frame.TopEdge then
            textures = {
                frame.TopEdge,    frame.TopRightCorner, frame.RightEdge,
                frame.BottomRightCorner, frame.BottomEdge, frame.BottomLeftCorner,
                frame.LeftEdge,   frame.TopLeftCorner,
            }
        end
    end
    C.TintAll(textures, r, g, b, a)
end

function C.RestoreBorder(frame)
    if not frame then return end
    local textures = {}
    if type(frame) == "table" then
        if frame.Border then
            textures = {
                frame.Border.TopEdge,    frame.Border.TopRightCorner,
                frame.Border.RightEdge,  frame.Border.BottomRightCorner,
                frame.Border.BottomEdge, frame.Border.BottomLeftCorner,
                frame.Border.LeftEdge,   frame.Border.TopLeftCorner,
            }
        elseif frame.TopLeftTex then
            textures = {
                frame.TopLeftTex,    frame.TopTex,    frame.TopRightTex,
                frame.RightTex,      frame.BottomRightTex, frame.BottomTex,
                frame.BottomLeftTex, frame.LeftTex,
            }
        end
    end
    C.RestoreAll(textures)
end

-- LoadOnDemand helper: applies the function immediately if the addon is loaded,
-- otherwise registers an ADDON_LOADED event
function C.WhenLoaded(addonName, fn)
    if C_AddOns.IsAddOnLoaded(addonName) then
        fn()
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, _, name)
            if name == addonName then
                fn()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end

-- ============================================================
-- DB access
-- ============================================================
function C:GetColor(skinKey, colorKey)
    local db = AklimeModDB.colorizer[skinKey]
    local co = db and db.colors and db.colors[colorKey]
    if co and co.followClassColor then
        local class = select(2, UnitClass("player"))
        local cc = C.classColors[class]
        if cc then return cc.r, cc.g, cc.b, 1 end
    end
    if co then return co.r, co.g, co.b, co.a end
    -- Fall back to the skin default
    local skin = self.skins[skinKey]
    if skin and skin.colors and skin.colors[colorKey] then
        local d = skin.colors[colorKey]
        return d.r, d.g, d.b, d.a
    end
    return 0.28, 0.28, 0.28, 1
end

-- Returns the color as an array {r,g,b,a} (for TintAllRGBA)
function C:GetColorArr(skinKey, colorKey)
    local r,g,b,a = self:GetColor(skinKey, colorKey)
    return {r,g,b,a}
end

function C:GetToggle(skinKey, toggleKey)
    local db = AklimeModDB.colorizer[skinKey]
    if db and db.toggles and db.toggles[toggleKey] ~= nil then
        return db.toggles[toggleKey]
    end
    local skin = self.skins[skinKey]
    if skin and skin.toggles and skin.toggles[toggleKey] then
        return skin.toggles[toggleKey].default
    end
    return false
end

function C:IsEnabled(skinKey)
    local db = AklimeModDB.colorizer[skinKey]
    return db and db.enabled == true
end

-- ============================================================
-- DB initialization
-- ============================================================
function C:InitDB()
    AklimeModDB.colorizer = AklimeModDB.colorizer or {}
    local db = AklimeModDB.colorizer
    if not db.__globalColor then
        db.__globalColor = { r = 0.28, g = 0.28, b = 0.28, a = 1 }
    end
    for key, skin in pairs(self.skins) do
        db[key] = db[key] or {}
        local skdb = db[key]
        if skdb.enabled == nil then skdb.enabled = false end
        skdb.colors  = skdb.colors  or {}
        skdb.toggles = skdb.toggles or {}
        if skin.colors then
            for ck, cd in pairs(skin.colors) do
                skdb.colors[ck] = skdb.colors[ck] or {}
                local co = skdb.colors[ck]
                if co.r              == nil then co.r              = cd.r   end
                if co.g              == nil then co.g              = cd.g   end
                if co.b              == nil then co.b              = cd.b   end
                if co.a              == nil then co.a              = cd.a   end
                if co.followClassColor == nil then co.followClassColor = cd.followClassColor or false end
            end
        end
        if skin.toggles then
            for tk, td in pairs(skin.toggles) do
                if skdb.toggles[tk] == nil then skdb.toggles[tk] = td.default end
            end
        end
    end
end

function C:Init()
    self:InitDB()
    for key, skin in pairs(self.skins) do
        if self:IsEnabled(key) then
            pcall(function() skin:apply() end)
        end
    end
end