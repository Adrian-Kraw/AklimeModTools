-- ColorizerSkins_UnitFrames.lua: unit frame skin definitions for the colorizer.

local C = AklimeMod_Colorizer
local D = C.defaults
local function T(tex,r,g,b,a) if tex then tex:SetDesaturation(1); tex:SetVertexColor(r,g,b,a or 1) end end
local function R(tex) if tex then C.Restore(tex) end end
local function col(k,ck) return C:GetColor(k,ck) end
local function rgb(c) return c[1],c[2],c[3],c[4] end -- for arrays

-- ============================================================
-- Player Frame
-- ============================================================
local classPowerBars = {
    PALADIN = function(c,d)
        for _,tex in pairs({ PaladinPowerBarFrame.Background, PaladinPowerBarFrame.ActiveTexture }) do
            if tex then tex:SetDesaturation(d); tex:SetVertexColor(c[1],c[2],c[3],c[4]) end
        end
    end,
    DEATHKNIGHT = function(c,d)
        if not RuneFrame then return end
        for i=1,6 do
            for _,tex in pairs({ RuneFrame["Rune"..i].BG_Active, RuneFrame["Rune"..i].BG_Inactive }) do
                if tex then tex:SetDesaturation(d); tex:SetVertexColor(c[1],c[2],c[3],c[4]) end
            end
        end
    end,
    WARLOCK = function(c,d)
        if not WarlockPowerFrame then return end
        for _,shard in pairs({ WarlockPowerFrame:GetChildren() }) do
            if shard.Background then shard.Background:SetDesaturation(d); shard.Background:SetVertexColor(c[1],c[2],c[3],c[4]) end
        end
    end,
}

C:Register("playerFrame", {
    label  = "Player Frame",
    group  = "Unit Frames",
    colors = {
        main            = { label="Main",             r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1, order=1 },
        corner_icon     = { label="Corner Icon",      r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1, order=2, followClassColor=true },
        class_power_bar = { label="Class Power Bar",  r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1, order=3 },
        cast_bar        = { label="Cast Bar",         r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1, order=4 },
    },
    toggles = {
        hide_pulsing_resting = { label="Hide Rest Animation", default=true },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("playerFrame","main")
        local cr,cg,cb,ca = col("playerFrame","corner_icon")
        local pr,pg,pb,pa = col("playerFrame","class_power_bar")
        local br,bg2,bb,ba = col("playerFrame","cast_bar")
        local class = select(2, UnitClass("player"))

        if C:GetToggle("playerFrame","hide_pulsing_resting") then
            hooksecurefunc("PlayerFrame_UpdateStatus", function()
                if IsResting() then
                    PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:Hide()
                end
            end)
            if IsResting() then
                PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:Hide()
            end
        end

        for _,tex in pairs({
            PlayerFrame.PlayerFrameContainer.FrameTexture,
            PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
            PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
            PlayerFrameGroupIndicatorLeft, PlayerFrameGroupIndicatorMiddle, PlayerFrameGroupIndicatorRight,
        }) do T(tex, mr,mg,mb,ma) end

        if classPowerBars[class] then classPowerBars[class]({pr,pg,pb,pa}, 1) end

        local ci = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon
        T(ci, cr,cg,cb,ca)

        for _,tex in pairs({ PlayerCastingBarFrame.Border, PlayerCastingBarFrame.Background }) do
            T(tex, br,bg2,bb,ba)
        end
    end,
    remove = function(self)
        if IsResting() then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:Show()
        end
        for _,tex in pairs({
            PlayerFrame.PlayerFrameContainer.FrameTexture,
            PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
            PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
            PlayerFrameGroupIndicatorLeft, PlayerFrameGroupIndicatorMiddle, PlayerFrameGroupIndicatorRight,
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon,
            PlayerCastingBarFrame.Border, PlayerCastingBarFrame.Background,
        }) do R(tex) end
        local class = select(2, UnitClass("player"))
        if classPowerBars[class] then classPowerBars[class]({1,1,1,1}, 0) end
    end,
})

-- ============================================================
-- Target Frame
-- ============================================================
local targetSkinnedWidgets = {}
C:Register("targetFrame", {
    label  = "Target Frame",
    group  = "Unit Frames",
    colors = {
        main       = { label="Main",          r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 },
        cast_bar   = { label="Cast Bar",      r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=2 },
        buff_border= { label="Buff Border",   r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=3 },
    },
    toggles = {
        follow_unit_class = { label="Color by Class / Reaction", default=false },
        show_buff_border  = { label="Show Buff Border",                  default=true  },
    },
    apply = function(self)
        local mr,mg,mb,ma   = col("targetFrame","main")
        local cr,cg,cb,ca   = col("targetFrame","cast_bar")
        local bbr,bbg,bbb,bba = col("targetFrame","buff_border")

        if C:GetToggle("targetFrame","follow_unit_class") then
            local function upd()
                local cc = C.GetUnitClassOrReactionColor("target")
                if cc then T(TargetFrame.TargetFrameContainer.FrameTexture, cc.r, cc.g, cc.b) end
            end
            hooksecurefunc("TargetFrame_Update", upd); upd()
        else
            T(TargetFrame.TargetFrameContainer.FrameTexture, mr,mg,mb,ma)
        end

        for _,tex in pairs({ TargetFrameSpellBar.Border, TargetFrameSpellBar.Background }) do
            T(tex, cr,cg,cb,ca)
        end

        if C:GetToggle("targetFrame","show_buff_border") then
            local buffPool = TargetFrame.auraPools:GetPool("TargetBuffFrameTemplate")
            local function updateBorders()
                for widget in buffPool:EnumerateActive() do
                    if not targetSkinnedWidgets[widget] then
                        widget.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
                        C.IconBorderColor(C.IconBorder(widget, widget, 2), bbr,bbg,bbb,bba)
                        targetSkinnedWidgets[widget] = true
                    end
                end
            end
            hooksecurefunc(TargetFrame, "UpdateAuras", updateBorders); updateBorders()
        end
    end,
    remove = function(self)
        R(TargetFrame.TargetFrameContainer.FrameTexture)
        R(TargetFrameSpellBar.Border); R(TargetFrameSpellBar.Background)
        for widget in pairs(targetSkinnedWidgets) do
            widget.Icon:SetTexCoord(0,1,0,1)
            if widget.border then widget.border:Hide() end
        end
        targetSkinnedWidgets = {}
    end,
})

-- ============================================================
-- Target of Target
-- ============================================================
C:Register("targetOfTarget", {
    label  = "Target of Target",
    group  = "Unit Frames",
    colors = {
        main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 },
    },
    toggles = {
        follow_unit_class = { label="Color by Class / Reaction", default=false },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("targetOfTarget","main")
        if C:GetToggle("targetOfTarget","follow_unit_class") then
            local function upd()
                local cc = C.GetUnitClassOrReactionColor("targettarget")
                if cc then T(TargetFrameToT.FrameTexture, cc.r,cc.g,cc.b) end
            end
            hooksecurefunc("TargetFrame_Update", upd); upd()
        else
            T(TargetFrameToT.FrameTexture, mr,mg,mb,ma)
        end
    end,
    remove = function(self) R(TargetFrameToT.FrameTexture) end,
})

-- ============================================================
-- Focus Frame
-- ============================================================
local focusSkinnedWidgets = {}
C:Register("focusFrame", {
    label  = "Focus Frame",
    group  = "Unit Frames",
    colors = {
        main        = { label="Main",        r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 },
        cast_bar    = { label="Cast Bar",    r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=2 },
        buff_border = { label="Buff Border", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=3 },
    },
    toggles = {
        follow_unit_class = { label="Color by Class / Reaction", default=false },
        show_buff_border  = { label="Show Buff Border",                  default=true  },
    },
    apply = function(self)
        local mr,mg,mb,ma     = col("focusFrame","main")
        local cr,cg,cb,ca     = col("focusFrame","cast_bar")
        local bbr,bbg,bbb,bba = col("focusFrame","buff_border")

        if C:GetToggle("focusFrame","follow_unit_class") then
            local function upd()
                local cc = C.GetUnitClassOrReactionColor("focus")
                if cc then T(FocusFrame.TargetFrameContainer.FrameTexture, cc.r,cc.g,cc.b) end
            end
            hooksecurefunc("FocusFrame_Update", upd); upd()
        else
            T(FocusFrame.TargetFrameContainer.FrameTexture, mr,mg,mb,ma)
        end

        for _,tex in pairs({ FocusFrameSpellBar.Border, FocusFrameSpellBar.Background }) do
            T(tex, cr,cg,cb,ca)
        end

        if C:GetToggle("focusFrame","show_buff_border") then
            local buffPool = FocusFrame.auraPools:GetPool("TargetBuffFrameTemplate")
            local function updateBorders()
                for widget in buffPool:EnumerateActive() do
                    if not focusSkinnedWidgets[widget] then
                        widget.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
                        C.IconBorderColor(C.IconBorder(widget, widget, 2), bbr,bbg,bbb,bba)
                        focusSkinnedWidgets[widget] = true
                    end
                end
            end
            hooksecurefunc(FocusFrame, "UpdateAuras", updateBorders); updateBorders()
        end
    end,
    remove = function(self)
        R(FocusFrame.TargetFrameContainer.FrameTexture)
        R(FocusFrameSpellBar.Border); R(FocusFrameSpellBar.Background)
        for widget in pairs(focusSkinnedWidgets) do
            widget.Icon:SetTexCoord(0,1,0,1)
            if widget.border then widget.border:Hide() end
        end
        focusSkinnedWidgets = {}
    end,
})

-- ============================================================
-- Focus of Target
-- ============================================================
C:Register("focusFrameToT", {
    label  = "Target of Focus Frame",
    group  = "Unit Frames",
    colors = {
        main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 },
    },
    toggles = {
        follow_unit_class = { label="Color by Class / Reaction", default=false },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("focusFrameToT","main")
        if C:GetToggle("focusFrameToT","follow_unit_class") then
            local function upd()
                local cc = C.GetUnitClassOrReactionColor("focustarget")
                if cc then T(FocusFrameToT.FrameTexture, cc.r,cc.g,cc.b) end
            end
            local function onFocusChanged() upd() end
            hooksecurefunc("FocusFrame_Update", onFocusChanged); upd()
        else
            T(FocusFrameToT.FrameTexture, mr,mg,mb,ma)
        end
    end,
    remove = function(self) R(FocusFrameToT.FrameTexture) end,
})

-- ============================================================
-- Pet Frame
-- ============================================================
C:Register("petFrame", {
    label  = "Pet Frame",
    group  = "Unit Frames",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply  = function(self) T(PetFrameTexture, col("petFrame","main")) end,
    remove = function(self) R(PetFrameTexture) end,
})

-- ============================================================
-- Party Frame
-- ============================================================
C:Register("partyFrame", {
    label  = "Party Frame",
    group  = "Unit Frames",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("partyFrame","main")
        for i=1,4 do T(PartyFrame["MemberFrame"..i] and PartyFrame["MemberFrame"..i].Texture, mr,mg,mb,ma) end
    end,
    remove = function(self)
        for i=1,4 do R(PartyFrame["MemberFrame"..i] and PartyFrame["MemberFrame"..i].Texture) end
    end,
})

-- ============================================================
-- Boss Frames
-- ============================================================
C:Register("bossFrames", {
    label  = "Boss Frames",
    group  = "Unit Frames",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("bossFrames","main")
        for i=1,5 do
            local f = _G["Boss"..i.."TargetFrame"]
            if f then T(f.TargetFrameContainer.FrameTexture, mr,mg,mb,ma) end
        end
    end,
    remove = function(self)
        for i=1,5 do
            local f = _G["Boss"..i.."TargetFrame"]
            if f then R(f.TargetFrameContainer.FrameTexture) end
        end
    end,
})

-- ============================================================
-- Compact Party Frame
-- ============================================================
C:Register("compactPartyFrame", {
    label  = "Compact Party Frame",
    group  = "Unit Frames",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("compactPartyFrame","main")
        for _,tex in pairs({
            CompactPartyFrameBorderFrameBorderRight, CompactPartyFrameBorderFrameBorderLeft,
            CompactPartyFrameBorderFrameBorderTop,   CompactPartyFrameBorderFrameBorderBottom,
            CompactPartyFrameBorderFrameBorderTopRight,    CompactPartyFrameBorderFrameBorderBottomRight,
            CompactPartyFrameBorderFrameBorderTopLeft,     CompactPartyFrameBorderFrameBorderBottomLeft,
        }) do T(tex, mr,mg,mb,ma) end
        for i=1,5 do
            for _,tex in pairs({
                _G["CompactPartyFrameMember"..i.."HorizBottomBorder"], _G["CompactPartyFrameMember"..i.."HorizTopBorder"],
                _G["CompactPartyFrameMember"..i.."VertRightBorder"],  _G["CompactPartyFrameMember"..i.."VertLeftBorder"],
            }) do T(tex, mr,mg,mb,ma) end
        end
    end,
    remove = function(self)
        for _,tex in pairs({
            CompactPartyFrameBorderFrameBorderRight, CompactPartyFrameBorderFrameBorderLeft,
            CompactPartyFrameBorderFrameBorderTop,   CompactPartyFrameBorderFrameBorderBottom,
            CompactPartyFrameBorderFrameBorderTopRight, CompactPartyFrameBorderFrameBorderBottomRight,
            CompactPartyFrameBorderFrameBorderTopLeft,  CompactPartyFrameBorderFrameBorderBottomLeft,
        }) do R(tex) end
        for i=1,5 do
            for _,tex in pairs({
                _G["CompactPartyFrameMember"..i.."HorizBottomBorder"], _G["CompactPartyFrameMember"..i.."HorizTopBorder"],
                _G["CompactPartyFrameMember"..i.."VertRightBorder"],   _G["CompactPartyFrameMember"..i.."VertLeftBorder"],
            }) do R(tex) end
        end
    end,
})

-- ============================================================
-- Compact Raid Group
-- ============================================================
local function skinRaidGroup(i, mr,mg,mb,ma)
    local pfx = "CompactRaidGroup"..i
    for _,sfx in ipairs({ "BorderFrameBorderLeft","BorderFrameBorderRight","BorderFrameBorderTop","BorderFrameBorderBottom",
        "BorderFrameBorderTopRight","BorderFrameBorderBottomRight","BorderFrameBorderTopLeft","BorderFrameBorderBottomLeft" }) do
        T(_G[pfx..sfx], mr,mg,mb,ma)
    end
    -- Disabled: could overwrite debuff type indicators (magic/poison/curse/disease).
    -- for n=1,5 do
    --     for _,sfx in ipairs({ "HorizBottomBorder","HorizTopBorder","VertRightBorder","VertLeftBorder" }) do
    --         T(_G[pfx.."Member"..n..sfx], mr,mg,mb,ma)
    --     end
    -- end
end
local function restoreRaidGroup(i)
    local pfx = "CompactRaidGroup"..i
    for _,sfx in ipairs({ "BorderFrameBorderLeft","BorderFrameBorderRight","BorderFrameBorderTop","BorderFrameBorderBottom",
        "BorderFrameBorderTopRight","BorderFrameBorderBottomRight","BorderFrameBorderTopLeft","BorderFrameBorderBottomLeft" }) do
        R(_G[pfx..sfx])
    end
    -- Also restore member borders in case they are still tinted from older versions.
    for n=1,5 do
        for _,sfx in ipairs({ "HorizBottomBorder","HorizTopBorder","VertRightBorder","VertLeftBorder" }) do
            R(_G[pfx.."Member"..n..sfx])
        end
    end
end

C:Register("compactRaidGroup", {
    label  = "Compact Raid Group",
    group  = "Unit Frames",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("compactRaidGroup","main")
        for i=1,NUM_RAID_GROUPS do pcall(skinRaidGroup, i, mr,mg,mb,ma) end
    end,
    remove = function(self)
        for i=1,NUM_RAID_GROUPS do pcall(restoreRaidGroup, i) end
    end,
})

-- ============================================================
-- Group order
-- ============================================================
table.insert(AklimeMod_Colorizer.groupOrder, {
    label = "Unit Frames",
    keys  = { "playerFrame","targetFrame","targetOfTarget","focusFrame","focusFrameToT",
              "petFrame","partyFrame","bossFrames","compactPartyFrame","compactRaidGroup" },
})