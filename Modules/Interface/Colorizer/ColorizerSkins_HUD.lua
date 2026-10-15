-- ColorizerSkins_HUD.lua: HUD and chat skin definitions for the colorizer.

local C = AklimeMod_Colorizer
local D = C.defaults
local NS, NSr = C.NS, C.NSr
local WL = C.WhenLoaded
local function T(tex,r,g,b,a) if tex then tex:SetDesaturation(1); tex:SetVertexColor(r,g,b,a or 1) end end
local function R(tex) if tex then C.Restore(tex) end end
local function col(k,ck) return C:GetColor(k,ck) end

-- ============================================================
-- Buff Frame
-- ============================================================
C:Register("buffFrame", {
    label  = "Buff Frame",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("buffFrame","main")
        for _,widget in pairs({ BuffFrame.AuraContainer:GetChildren() }) do
            if widget.Icon then
                widget.Icon:SetTexCoord(0.135,0.865,0.135,0.865)
                C.IconBorderColor(C.IconBorder(widget, widget.Icon, 2), mr,mg,mb,ma)
            end
        end
    end,
    remove = function(self)
        for _,widget in pairs({ BuffFrame.AuraContainer:GetChildren() }) do
            if widget.Icon then
                widget.Icon:SetTexCoord(0,1,0,1)
                if widget.border then widget.border:Hide() end
            end
        end
    end,
})

-- ============================================================
-- Cooldown Viewer
-- ============================================================
C:Register("cooldownViewer", {
    label  = "Cooldown Viewer",
    group  = "HUD",
    colors = { bar_border_color = { label="Bar Border", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("cooldownViewer","bar_border_color")
        if not BuffBarCooldownViewer then return end
        for _,tex in pairs({ BuffBarCooldownViewer:GetRegions() }) do
            if tex and tex.GetDebugName and tex:GetObjectType()=="Texture" then
                local name = tex:GetDebugName() or ""
                if not name:match("Icon") and tex:GetDrawLayer()=="BACKGROUND" then
                    T(tex, mr,mg,mb,ma)
                end
            end
        end
    end,
    remove = function(self)
        if not BuffBarCooldownViewer then return end
        for _,tex in pairs({ BuffBarCooldownViewer:GetRegions() }) do
            if tex and tex.GetDebugName and tex:GetObjectType()=="Texture" then
                local name = tex:GetDebugName() or ""
                if not name:match("Icon") and tex:GetDrawLayer()=="BACKGROUND" then R(tex) end
            end
        end
    end,
})

-- ============================================================
-- Minimap
-- ============================================================
C:Register("minimap", {
    label  = "Minimap",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply  = function(self) T(MinimapCompassTexture, col("minimap","main")) end,
    remove = function(self) R(MinimapCompassTexture) end,
})

-- ============================================================
-- Objective Tracker
-- ============================================================
local trackerFrames = {
    "AdventureObjectiveTracker","MonthlyActivitiesObjectiveTracker","ObjectiveTrackerFrame",
    "WorldQuestObjectiveTracker","BonusObjectiveTracker","QuestObjectiveTracker",
    "ScenarioObjectiveTracker","AchievementObjectiveTracker","CampaignQuestObjectiveTracker",
    "ProfessionsRecipeTracker","InitiativeTasksObjectiveTracker",
}
C:Register("objectiveTracker", {
    label  = "Objective Tracker",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("objectiveTracker","main")
        for _,name in ipairs(trackerFrames) do
            local f = _G[name]
            if f and f.Header and f.Header.Background then T(f.Header.Background, mr,mg,mb,ma) end
        end
    end,
    remove = function(self)
        for _,name in ipairs(trackerFrames) do
            local f = _G[name]
            if f and f.Header and f.Header.Background then R(f.Header.Background) end
        end
    end,
})

-- ============================================================
-- Tooltips
-- ============================================================
C:Register("tooltips", {
    label  = "Tooltips",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("tooltips","main")
        for _,tip in pairs({ GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ItemRefTooltip }) do
            NS(tip, mr,mg,mb,ma)
        end
    end,
    remove = function(self)
        for _,tip in pairs({ GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ItemRefTooltip }) do NSr(tip) end
    end,
})

-- ============================================================
-- Chat frame skin.
-- ============================================================
local function skinChatBorderOf(frameName, bordersColor, desaturation)
    -- SkinBorderOf for chat (border texture set)
    local frame = type(frameName)=="string" and _G[frameName] or frameName
    if not frame then return end
    local border = frame.Border
    if not border then return end
    for _,tex in pairs({
        border.TopEdge, border.TopRightCorner, border.RightEdge,
        border.BottomRightCorner, border.BottomEdge, border.BottomLeftCorner,
        border.LeftEdge, border.TopLeftCorner,
    }) do
        if tex then
            tex:SetDesaturation(desaturation)
            tex:SetVertexColor(bordersColor[1],bordersColor[2],bordersColor[3],bordersColor[4])
        end
    end
end

local function applyToChatFrame(chatFrameName, mc, bgc, boc, cc, tc, des)
    for _,tex in pairs({
        _G[chatFrameName.."EditBoxLeft"], _G[chatFrameName.."EditBoxMid"], _G[chatFrameName.."EditBoxRight"],
        _G[chatFrameName.."EditBoxFocusLeft"], _G[chatFrameName.."EditBoxFocusMid"], _G[chatFrameName.."EditBoxFocusRight"],
    }) do if tex then tex:SetDesaturation(des); tex:SetVertexColor(mc[1],mc[2],mc[3],mc[4]) end end
    for _,tex in pairs({
        _G[chatFrameName.."Background"], _G[chatFrameName.."ButtonFrameBackground"],
    }) do
        if tex then
            local oldAlpha = tex:GetAlpha()
            tex:SetDesaturation(des); tex:SetVertexColor(bgc[1],bgc[2],bgc[3],oldAlpha)
        end
    end
    skinChatBorderOf(chatFrameName, boc, des)
    skinChatBorderOf(chatFrameName.."ButtonFrame", boc, des)
    -- ScrollBar
    local cf = _G[chatFrameName]
    if cf and cf.ScrollBar then
        for _,tex in pairs({
            cf.ScrollBar.Track and cf.ScrollBar.Track.Thumb and cf.ScrollBar.Track.Thumb.Begin,
            cf.ScrollBar.Track and cf.ScrollBar.Track.Thumb and cf.ScrollBar.Track.Thumb.Middle,
            cf.ScrollBar.Track and cf.ScrollBar.Track.Thumb and cf.ScrollBar.Track.Thumb.End,
            cf.ScrollBar.Back and cf.ScrollBar.Back.Texture,
            cf.ScrollBar.Forward and cf.ScrollBar.Forward.Texture,
        }) do if tex then tex:SetDesaturation(des); tex:SetVertexColor(cc[1],cc[2],cc[3],cc[4]) end end
    end
    if cf and cf.ScrollToBottomButton then
        local stb = cf.ScrollToBottomButton:GetNormalTexture()
        if stb then stb:SetDesaturation(des); stb:SetVertexColor(cc[1],cc[2],cc[3],cc[4]) end
    end
    -- Tab: inactive, active and hover textures (otherwise the
    -- currently active tab stays uncolored)
    local tab = _G[chatFrameName.."Tab"]
    if tab then
        for _,tex in pairs({
            tab.Left, tab.Middle, tab.Right,
            tab.ActiveLeft, tab.ActiveMiddle, tab.ActiveRight,
            tab.HighlightLeft, tab.HighlightMiddle, tab.HighlightRight,
        }) do
            if tex then tex:SetDesaturation(des); tex:SetVertexColor(tc[1],tc[2],tc[3],tc[4]) end
        end
    end
end

C:Register("chatFrame", {
    label  = "Chat Frame",
    group  = "HUD",
    colors = {
        main             = { label="Main",                r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1, order=1 },
        background       = { label="Background",           r=0.1,          g=0.1,          b=0.1,          a=1, order=2 },
        borders          = { label="Borders",             r=0.2,          g=0.2,          b=0.2,          a=0.6, order=3 },
        controls         = { label="Controls",            r=D.controls.r, g=D.controls.g, b=D.controls.b, a=1, order=4 },
        tabs             = { label="Tabs",                r=D.tabs.r,     g=D.tabs.g,     b=D.tabs.b,     a=1, order=5 },
        btn_normal_color = { label="Button Normal",       r=0.5,          g=0.5,          b=0.5,          a=1, order=6 },
        btn_highlight    = { label="Button Highlight",    r=1,            g=1,            b=1,            a=1, order=7 },
        btn_pushed       = { label="Button Pressed",      r=0.3,          g=0.3,          b=0.3,          a=1, order=8 },
    },
    apply = function(self)
        local mc  = {col("chatFrame","main")}
        local bgc = {col("chatFrame","background")}
        local boc = {col("chatFrame","borders")}
        local cc  = {col("chatFrame","controls")}
        local tc  = {col("chatFrame","tabs")}
        local nc  = {col("chatFrame","btn_normal_color")}
        local hc  = {col("chatFrame","btn_highlight")}
        local pc  = {col("chatFrame","btn_pushed")}

        for i=1,NUM_CHAT_WINDOWS do
            applyToChatFrame("ChatFrame"..i, mc, bgc, boc, cc, tc, 1)
        end

        local normalTextures = { QuickJoinToastButton.FriendsButton, ChatFrameChannelButton.Icon }
        local highlightTextures, pushedTextures = {}, {}
        for _,btn in pairs({ QuickJoinToastButton, ChatFrameChannelButton, ChatFrameMenuButton }) do
            table.insert(normalTextures, btn:GetNormalTexture())
            table.insert(highlightTextures, btn:GetHighlightTexture())
            table.insert(pushedTextures, btn:GetPushedTexture())
        end
        for _,tex in pairs(normalTextures)    do if tex then tex:SetDesaturation(1); tex:SetVertexColor(nc[1],nc[2],nc[3],nc[4]) end end
        for _,tex in pairs(highlightTextures) do if tex then tex:SetDesaturation(1); tex:SetVertexColor(hc[1],hc[2],hc[3],hc[4]) end end
        for _,tex in pairs(pushedTextures)    do if tex then tex:SetDesaturation(1); tex:SetVertexColor(pc[1],pc[2],pc[3],pc[4]) end end
    end,
    remove = function(self)
        local white = {1,1,1,1}; local black = {0,0,0,1}
        for i=1,NUM_CHAT_WINDOWS do
            applyToChatFrame("ChatFrame"..i, white, black, white, white, white, 0)
        end
        for _,btn in pairs({ QuickJoinToastButton, ChatFrameChannelButton, ChatFrameMenuButton }) do
            for _,tex in pairs({ btn:GetNormalTexture(), btn:GetHighlightTexture(), btn:GetPushedTexture() }) do
                if tex then tex:SetDesaturation(0); tex:SetVertexColor(1,1,1,1) end
            end
        end
        R(QuickJoinToastButton.FriendsButton); R(ChatFrameChannelButton.Icon)
    end,
})

-- ============================================================
-- Status Bar 1
-- ============================================================
C:Register("statusBar1", {
    label  = "Status Bar 1",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply  = function(self) T(MainStatusTrackingBarContainer and MainStatusTrackingBarContainer.BarFrameTexture, col("statusBar1","main")) end,
    remove = function(self) R(MainStatusTrackingBarContainer and MainStatusTrackingBarContainer.BarFrameTexture) end,
})

-- ============================================================
-- Status Bar 2
-- ============================================================
C:Register("statusBar2", {
    label  = "Status Bar 2",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply  = function(self) T(SecondaryStatusTrackingBarContainer and SecondaryStatusTrackingBarContainer.BarFrameTexture, col("statusBar2","main")) end,
    remove = function(self) R(SecondaryStatusTrackingBarContainer and SecondaryStatusTrackingBarContainer.BarFrameTexture) end,
})

-- ============================================================
-- Mirror Timer Container
-- ============================================================
C:Register("mirrorTimer", {
    label  = "Mirror Timer",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("mirrorTimer","main")
        if MirrorTimerContainer then
            for _,child in pairs({ MirrorTimerContainer:GetChildren() }) do
                if child.Border then T(child.Border, mr,mg,mb,ma) end
            end
        end
    end,
    remove = function(self)
        if MirrorTimerContainer then
            for _,child in pairs({ MirrorTimerContainer:GetChildren() }) do
                if child.Border then R(child.Border) end
            end
        end
    end,
})

-- ============================================================
-- Spell Flyout
-- ============================================================
C:Register("spellFlyout", {
    label  = "Spell Flyout",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    toggles = {
        follow_parent_color = { label="Use Parent Button Color", default=true },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("spellFlyout","main")
        local followParent = C:GetToggle("spellFlyout","follow_parent_color")
        local function applyColor(r,g,b,a)
            for _,tex in pairs({
                SpellFlyout.Background.Start, SpellFlyout.Background.VerticalMiddle,
                SpellFlyout.Background.HorizontalMiddle, SpellFlyout.Background.End,
            }) do T(tex, r,g,b,a) end
            local i=1
            while true do
                local t = _G["SpellFlyoutPopupButton"..i.."NormalTexture"]
                if not t then break end
                T(t, r,g,b,a); i=i+1
            end
        end
        hooksecurefunc(SpellFlyout, "OnSizeChanged", function()
            if followParent then
                local parent = SpellFlyout:GetParent()
                if parent then
                    local name = parent:GetName()
                    if name then
                        local tex = _G[name.."NormalTexture"]
                        if tex then
                            local r,g,b,a = tex:GetVertexColor()
                            applyColor(r,g,b,a); return
                        end
                    end
                end
            end
            applyColor(mr,mg,mb,ma)
        end)
    end,
    remove = function(self)
        for _,tex in pairs({
            SpellFlyout.Background.Start, SpellFlyout.Background.VerticalMiddle,
            SpellFlyout.Background.HorizontalMiddle, SpellFlyout.Background.End,
        }) do R(tex) end
        local i=1
        while true do
            local t = _G["SpellFlyoutPopupButton"..i.."NormalTexture"]
            if not t then break end
            R(t); i=i+1
        end
    end,
})

-- ============================================================
-- Pop-up dialog skin.
-- ============================================================
C:Register("popupDialogs", {
    label  = "Pop-up Dialogs",
    group  = "HUD",
    colors = {
        main          = { label="Main",             r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1,   order=1 },
        gold_border   = { label="Gold Border",      r=1.0,          g=0.843,        b=0.0,          a=1,   order=3.1 },
        silver_border = { label="Silver Border",    r=0.753,        g=0.753,        b=0.753,        a=1,   order=3.2 },
        copper_border = { label="Copper Border",    r=0.722,        g=0.451,        b=0.200,        a=1,   order=3.3 },
        controls      = { label="Controls",         r=D.controls.r, g=D.controls.g, b=D.controls.b, a=1,   order=4 },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("popupDialogs","main")
        local gr,gg,gb,ga = col("popupDialogs","gold_border")
        local sr,sg,sb,sa = col("popupDialogs","silver_border")
        local cr2,cg2,cb2,ca2 = col("popupDialogs","copper_border")
        local cr,cg,cb,ca = col("popupDialogs","controls")

        for _,f in pairs({ LFGDungeonReadyDialog,LFGDungeonReadyStatus,LFGListInviteDialog,LFGInvitePopup,LFDRoleCheckPopup,PVPReadyDialog,RolePollPopup,ReadyStatus }) do
            C.SkinBorder(f, mr,mg,mb,ma)
        end
        for _,tex in pairs({ StaticPopup1.BG.Top,StaticPopup2.BG.Top,StaticPopup3.BG.Top,StaticPopup4.BG.Top }) do
            T(tex, mr,mg,mb,ma)
        end
        for i=1,4 do
            for _,tex in pairs({
                _G["StaticPopup"..i.."MoneyInputFrameGoldLeft"],_G["StaticPopup"..i.."MoneyInputFrameGoldMiddle"],_G["StaticPopup"..i.."MoneyInputFrameGoldRight"],
            }) do T(tex, gr,gg,gb,ga) end
            for _,tex in pairs({
                _G["StaticPopup"..i.."MoneyInputFrameSilverLeft"],_G["StaticPopup"..i.."MoneyInputFrameSilverMiddle"],_G["StaticPopup"..i.."MoneyInputFrameSilverRight"],
            }) do T(tex, sr,sg,sb,sa) end
            for _,tex in pairs({
                _G["StaticPopup"..i.."MoneyInputFrameCopperLeft"],_G["StaticPopup"..i.."MoneyInputFrameCopperMiddle"],_G["StaticPopup"..i.."MoneyInputFrameCopperRight"],
            }) do T(tex, cr2,cg2,cb2,ca2) end
            for _,tex in pairs({
                _G["StaticPopup"..i.."EditBoxLeft"],_G["StaticPopup"..i.."EditBoxMid"],_G["StaticPopup"..i.."EditBoxRight"],
            }) do T(tex, cr,cg,cb,ca) end
            local sp = _G["StaticPopup"..i]
            if sp and sp.Dropdown and sp.Dropdown.Background then T(sp.Dropdown.Background, cr,cg,cb,ca) end
        end
    end,
    remove = function(self)
        for _,f in pairs({ LFGDungeonReadyDialog,LFGDungeonReadyStatus,LFGListInviteDialog,LFGInvitePopup,LFDRoleCheckPopup,PVPReadyDialog,RolePollPopup,ReadyStatus }) do
            C.RestoreBorder(f)
        end
        for _,tex in pairs({ StaticPopup1.BG.Top,StaticPopup2.BG.Top,StaticPopup3.BG.Top,StaticPopup4.BG.Top }) do R(tex) end
        for i=1,4 do
            for _,suffix in ipairs({ "Gold","Silver","Copper" }) do
                for _,part in ipairs({ "Left","Middle","Right" }) do
                    R(_G["StaticPopup"..i.."MoneyInputFrame"..suffix..part])
                end
            end
            for _,tex in pairs({
                _G["StaticPopup"..i.."EditBoxLeft"],_G["StaticPopup"..i.."EditBoxMid"],_G["StaticPopup"..i.."EditBoxRight"],
            }) do R(tex) end
            local sp = _G["StaticPopup"..i]
            if sp and sp.Dropdown and sp.Dropdown.Background then R(sp.Dropdown.Background) end
        end
    end,
})

-- ============================================================
-- Compact Raid Frame Manager
-- ============================================================
C:Register("compactRaidFrameManager", {
    label  = "Raid Frame Manager",
    group  = "HUD",
    colors = {
        main     = { label="Main",     r=D.main.r,     g=D.main.g,     b=D.main.b,     a=1, order=1 },
        controls = { label="Controls", r=D.controls.r, g=D.controls.g, b=D.controls.b, a=1, order=2 },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("compactRaidFrameManager","main")
        local cr,cg,cb,ca = col("compactRaidFrameManager","controls")
        for _,tex in pairs({
            _G["CompactRaidFrameManagerBG-leads"],    _G["CompactRaidFrameManagerBG-assists"],
            _G["CompactRaidFrameManagerBG-regulars"], _G["CompactRaidFrameManagerBG-party-leads"],
            _G["CompactRaidFrameManagerBG-party-regulars"],
        }) do T(tex, mr,mg,mb,ma) end
        for _,tex in pairs({
            CompactRaidFrameManagerDisplayFrameModeControlDropdown and CompactRaidFrameManagerDisplayFrameModeControlDropdown.Background,
            CompactRaidFrameManagerDisplayFrameRestrictPingsDropdown and CompactRaidFrameManagerDisplayFrameRestrictPingsDropdown.Background,
        }) do T(tex, cr,cg,cb,ca) end
    end,
    remove = function(self)
        for _,name in ipairs({ "leads","assists","regulars","party-leads","party-regulars" }) do
            R(_G["CompactRaidFrameManagerBG-"..name])
        end
        R(CompactRaidFrameManagerDisplayFrameModeControlDropdown and CompactRaidFrameManagerDisplayFrameModeControlDropdown.Background)
        R(CompactRaidFrameManagerDisplayFrameRestrictPingsDropdown and CompactRaidFrameManagerDisplayFrameRestrictPingsDropdown.Background)
    end,
})

-- ============================================================
-- Menu Style (right-click menu)
-- ============================================================
C:Register("menuStyle", {
    label  = "Context Menu",
    group  = "HUD",
    colors = { main = { label="Main", r=D.main.r, g=D.main.g, b=D.main.b, a=1, order=1 } },
    apply = function(self)
        local mr,mg,mb,ma = col("menuStyle","main")
        if MenuStyle1Mixin then
            hooksecurefunc(MenuStyle1Mixin, "Generate", function(self2)
                for _,v in pairs({ self2:GetRegions() }) do
                    if v:IsObjectType("Texture") then
                        v:SetDesaturation(1); v:SetVertexColor(mr,mg,mb,ma)
                    end
                end
            end)
        end
    end,
    remove = function(self) end, -- Hook cannot be undone
})

-- ============================================================
-- Group order
-- ============================================================
table.insert(AklimeMod_Colorizer.groupOrder, {
    label = "HUD",
    keys  = { "buffFrame","cooldownViewer","minimap","objectiveTracker","tooltips","chatFrame",
              "statusBar1","statusBar2","mirrorTimer","spellFlyout","popupDialogs",
              "compactRaidFrameManager","menuStyle" },
})