-- ColorizerSkins_Windows.lua: window and panel skin definitions for the colorizer.

local C  = AklimeMod_Colorizer
local D  = C.defaults
local NS = C.NS
local NSr = C.NSr

local function T(tex,r,g,b,a) if tex then tex:SetDesaturation(1); tex:SetVertexColor(r,g,b,a or 1) end end
local function R(tex) if tex then C.Restore(tex) end end
local function col(k,ck) return C:GetColor(k,ck) end

local function SkinNS(frame,r,g,b,a) if frame then NS(frame,r,g,b,a) end end
local function RestoreNS(frame) if frame then NSr(frame) end end
local function SkinSB(frame,r,g,b,a) if frame then C.SkinBorder(frame,r,g,b,a) end end
local function RB(frame) if frame then C.RestoreBorder(frame) end end

local function SkinScrollBar(frame,r,g,b,a)
    if not frame or not frame.ScrollBar then return end
    local sb = frame.ScrollBar
    for _,tex in pairs({
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Begin,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Middle,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.End,
        sb.Back and sb.Back.Texture,
        sb.Forward and sb.Forward.Texture,
    }) do T(tex,r,g,b,a) end
end
local function RestoreScrollBar(frame)
    if not frame or not frame.ScrollBar then return end
    local sb = frame.ScrollBar
    for _,tex in pairs({
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Begin,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.Middle,
        sb.Track and sb.Track.Thumb and sb.Track.Thumb.End,
        sb.Back and sb.Back.Texture,
        sb.Forward and sb.Forward.Texture,
    }) do R(tex) end
end

local function SkinBox(box,r,g,b,a)
    if not box then return end
    T(box.Left,r,g,b,a); T(box.Middle,r,g,b,a); T(box.Right,r,g,b,a)
end
local function RestoreBox(box)
    if not box then return end
    R(box.Left); R(box.Middle); R(box.Right)
end

local function SkinTabs(tab,r,g,b,a)
    if not tab then return end
    if tab.TabSystem then
        for _,t in pairs({ tab.TabSystem:GetChildren() }) do
            T(t.Left,r,g,b,a); T(t.Middle,r,g,b,a); T(t.Right,r,g,b,a)
        end
    else
        T(tab.Left,r,g,b,a); T(tab.Middle,r,g,b,a); T(tab.Right,r,g,b,a)
    end
end

local WL = C.WhenLoaded

local DM = D.main; local DG = D.background; local DR = D.borders
local DC = D.controls; local DT = D.tabs

local function wc(extra)
    local t = {
        main       = { label="Main",        r=DM.r, g=DM.g, b=DM.b, a=1, order=1 },
        background = { label="Background", r=DG.r, g=DG.g, b=DG.b, a=1, order=2 },
        borders    = { label="Borders",      r=DR.r, g=DR.g, b=DR.b, a=1, order=3 },
        controls   = { label="Controls",   r=DC.r, g=DC.g, b=DC.b, a=1, order=4 },
        tabs       = { label="Tabs",       r=DT.r, g=DT.g, b=DT.b, a=1, order=5 },
    }
    if extra then for k,v in pairs(extra) do t[k]=v end end
    return t
end

-- ========================================================
-- Achievement Frame
-- ========================================================
C:Register("winAchieve", {
    label = "Erfolge", group = "Windows",
    colors = {
        main     = { label="Main",     r=DM.r,g=DM.g,b=DM.b,a=1,order=1 },
        controls = { label="Controls", r=DC.r,g=DC.g,b=DC.b,a=1,order=2 },
        tabs     = { label="Tabs",     r=DT.r,g=DT.g,b=DT.b,a=1,order=3 },
    },
    apply = function(self)
        WL("Blizzard_AchievementUI", function()
            local mr,mg,mb,ma=col("winAchieve","main")
            local cr,cg,cb,ca=col("winAchieve","controls")
            local tr,tg,tb,ta=col("winAchieve","tabs")
            SkinNS(AchievementFrameCategories,mr,mg,mb,ma)
            for _,tex in pairs({
                AchievementFrameMetalBorderRight,AchievementFrameMetalBorderBottomRight,
                AchievementFrameMetalBorderBottom,AchievementFrameMetalBorderBottomLeft,
                AchievementFrameMetalBorderLeft,AchievementFrameMetalBorderTopLeft,
                AchievementFrameMetalBorderTop,AchievementFrameMetalBorderTopRight,
                AchievementFrame.Header.Left,AchievementFrame.Header.Right,
                AchievementFrameCategoriesBG,AchievementFrame.Header.PointBorder,
            }) do T(tex,mr,mg,mb,ma) end
            for _,tab in pairs({AchievementFrameTab1,AchievementFrameTab2,AchievementFrameTab3}) do SkinTabs(tab,tr,tg,tb,ta) end
            for _,f in pairs({AchievementFrameCategories,AchievementFrameAchievements,AchievementFrameStats}) do SkinScrollBar(f,cr,cg,cb,ca) end
            SkinBox(AchievementFrame.SearchBox,cr,cg,cb,ca)
            T(AchievementFrameFilterDropdown and AchievementFrameFilterDropdown.Background,cr,cg,cb,ca)
            T(AchievementFrameSummaryCategoriesStatusBarLeft,cr,cg,cb,ca)
            T(AchievementFrameSummaryCategoriesStatusBarMiddle,cr,cg,cb,ca)
            T(AchievementFrameSummaryCategoriesStatusBarRight,cr,cg,cb,ca)
            for i=1,11 do
                for _,region in ipairs({"Left","Middle","Right"}) do
                    T(_G["AchievementFrameSummaryCategoriesCategory"..i..region],cr,cg,cb,ca)
                end
            end
        end)
    end,
    remove = function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_AchievementUI") then return end
        RestoreNS(AchievementFrameCategories)
        for _,tex in pairs({
            AchievementFrameMetalBorderRight,AchievementFrameMetalBorderBottomRight,
            AchievementFrameMetalBorderBottom,AchievementFrameMetalBorderBottomLeft,
            AchievementFrameMetalBorderLeft,AchievementFrameMetalBorderTopLeft,
            AchievementFrameMetalBorderTop,AchievementFrameMetalBorderTopRight,
            AchievementFrame.Header.Left,AchievementFrame.Header.Right,
            AchievementFrameCategoriesBG,AchievementFrame.Header.PointBorder,
            AchievementFrameSummaryCategoriesStatusBarLeft,
            AchievementFrameSummaryCategoriesStatusBarMiddle,
            AchievementFrameSummaryCategoriesStatusBarRight,
        }) do R(tex) end
        for i=1,11 do for _,r2 in ipairs({"Left","Middle","Right"}) do R(_G["AchievementFrameSummaryCategoriesCategory"..i..r2]) end end
        for _,f in pairs({AchievementFrameCategories,AchievementFrameAchievements,AchievementFrameStats}) do RestoreScrollBar(f) end
        R(AchievementFrameFilterDropdown and AchievementFrameFilterDropdown.Background)
        RestoreBox(AchievementFrame.SearchBox)
        for _,tab in pairs({AchievementFrameTab1,AchievementFrameTab2,AchievementFrameTab3}) do SkinTabs(tab,1,1,1,1) end
    end,
})

-- ========================================================
-- AddOn List
-- ========================================================
C:Register("winAddonList", {
    label="AddOn List", group="Windows",
    colors={
        main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},
        borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=2},
        background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=3},
        controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4},
    },
    apply=function(self)
        local mr,mg,mb,ma=col("winAddonList","main")
        local ir,ig,ib,ia=col("winAddonList","borders")
        local br,bg2,bb,ba=col("winAddonList","background")
        local cr,cg,cb,ca=col("winAddonList","controls")
        SkinNS(AddonList,mr,mg,mb,ma); SkinNS(AddonListInset,ir,ig,ib,ia)
        T(AddonListBg,br,bg2,bb,ba)
        T(AddonList.Dropdown and AddonList.Dropdown.Background,cr,cg,cb,ca)
        SkinBox(AddonList.SearchBox,cr,cg,cb,ca)
        SkinScrollBar(AddonList,cr,cg,cb,ca)
    end,
    remove=function(self)
        RestoreNS(AddonList); RestoreNS(AddonListInset); R(AddonListBg)
        R(AddonList.Dropdown and AddonList.Dropdown.Background)
        RestoreBox(AddonList.SearchBox); RestoreScrollBar(AddonList)
    end,
})

-- ========================================================
-- Allied Races
-- ========================================================
C:Register("winAlliedRaces", {
    label="Allied Races", group="Windows",
    colors={
        main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},
        background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},
        controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3},
    },
    apply=function(self)
        WL("Blizzard_AlliedRacesUI", function()
            local mr,mg,mb,ma=col("winAlliedRaces","main")
            local br,bg2,bb,ba=col("winAlliedRaces","background")
            local cr,cg,cb,ca=col("winAlliedRaces","controls")
            SkinNS(AlliedRacesFrame,mr,mg,mb,ma); T(AlliedRacesFrameBg,br,bg2,bb,ba)
            SkinScrollBar(AlliedRacesFrame.RaceInfoFrame and AlliedRacesFrame.RaceInfoFrame.ScrollFrame,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_AlliedRacesUI") then return end
        RestoreNS(AlliedRacesFrame); R(AlliedRacesFrameBg)
    end,
})

-- ========================================================
-- Auction House
-- ========================================================
C:Register("winAH", {
    label="Auction House", group="Windows",
    colors=wc({
        gold_border  ={label="Gold Border",  r=1.0, g=0.843,b=0.0,  a=1,order=6},
        silver_border={label="Silver Border",r=0.753,g=0.753,b=0.753,a=1,order=7},
    }),
    apply=function(self)
        WL("Blizzard_AuctionHouseUI", function()
            local mr,mg,mb,ma=col("winAH","main"); local br,bg2,bb,ba=col("winAH","background")
            local ir,ig,ib,ia=col("winAH","borders"); local gr,gg,gb,ga=col("winAH","gold_border")
            local sr,sg,sb,sa=col("winAH","silver_border"); local cr,cg,cb,ca=col("winAH","controls")
            local tr,tg,tb,ta=col("winAH","tabs")
            SkinNS(AuctionHouseFrame,mr,mg,mb,ma); T(AuctionHouseFrameBg,br,bg2,bb,ba)
            for _,v in pairs({AuctionHouseFrame.MoneyFrameBorder:GetRegions()}) do
                if v:IsObjectType("Texture") and not v:GetName() then T(v,br,bg2,bb,ba) end
            end
            for _,f in pairs({
                AuctionHouseFrame.CategoriesList,AuctionHouseFrame.BrowseResultsFrame.ItemList,
                AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay,AuctionHouseFrame.CommoditiesBuyFrame.ItemList,
                AuctionHouseFrame.ItemSellFrame,AuctionHouseFrame.ItemSellList,
                AuctionHouseFrameAuctionsFrame.SummaryList,AuctionHouseFrameAuctionsFrame.AllAuctionsList,
                AuctionHouseFrameAuctionsFrame.BidsList,AuctionHouseFrame.CommoditiesSellFrame,
                AuctionHouseFrame.CommoditiesSellList,AuctionHouseFrame.MoneyFrameInset,
                AuctionHouseFrame.ItemBuyFrame.ItemDisplay,AuctionHouseFrame.ItemBuyFrame.ItemList,
            }) do SkinNS(f,ir,ig,ib,ia) end
            for _,tex in pairs({AuctionHouseFrameLeft,AuctionHouseFrameMiddle,AuctionHouseFrameRight}) do T(tex,ir,ig,ib,ia) end
            for _,tex in pairs({AuctionHouseFrameGoldLeft,AuctionHouseFrameGoldMiddle,AuctionHouseFrameGoldRight,
                AuctionHouseFrameAuctionsFrameGoldLeft,AuctionHouseFrameAuctionsFrameGoldMiddle,AuctionHouseFrameAuctionsFrameGoldRight}) do T(tex,gr,gg,gb,ga) end
            for _,tex in pairs({AuctionHouseFrameSilverLeft,AuctionHouseFrameSilverMiddle,AuctionHouseFrameSilverRight,
                AuctionHouseFrameAuctionsFrameSilverLeft,AuctionHouseFrameAuctionsFrameSilverMiddle,AuctionHouseFrameAuctionsFrameSilverRight}) do T(tex,sr,sg,sb,sa) end
            for _,f in pairs({AuctionHouseFrame.CategoriesList,AuctionHouseFrame.BrowseResultsFrame.ItemList,
                AuctionHouseFrame.ItemSellList,AuctionHouseFrameAuctionsFrame.SummaryList,
                AuctionHouseFrameAuctionsFrame.AllAuctionsList,AuctionHouseFrameAuctionsFrame.BidsList,
                AuctionHouseFrame.CommoditiesSellList,AuctionHouseFrame.CommoditiesBuyFrame.ItemList,
                AuctionHouseFrame.ItemBuyFrame.ItemList}) do SkinScrollBar(f,cr,cg,cb,ca) end
            SkinBox(AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchBox,cr,cg,cb,ca)
            for _,tab in pairs({AuctionHouseFrameBuyTab,AuctionHouseFrameSellTab,AuctionHouseFrameAuctionsTab,
                AuctionHouseFrameAuctionsFrameAuctionsTab,AuctionHouseFrameAuctionsFrameBidsTab}) do SkinTabs(tab,tr,tg,tb,ta) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_AuctionHouseUI") then return end
        RestoreNS(AuctionHouseFrame); R(AuctionHouseFrameBg)
    end,
})

-- ========================================================
-- Azerite Respec
-- ========================================================
C:Register("winAzeriteRespec", {
    label="Azerite Reforging", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1}},
    apply=function(self)
        WL("Blizzard_AzeriteRespecUI", function()
            local mr,mg,mb,ma=col("winAzeriteRespec","main")
            SkinNS(AzeriteRespecFrame,mr,mg,mb,ma)
            T(AzeriteRespecFrame.ButtonFrame and AzeriteRespecFrame.ButtonFrame.ButtonBorder,mr,mg,mb,ma)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_AzeriteRespecUI") then return end
        RestoreNS(AzeriteRespecFrame)
    end,
})

-- ========================================================
-- Bank Frame
-- ========================================================
C:Register("winBank", {
    label="Bank", group="Windows", colors=wc(),
    apply=function(self)
        local mr,mg,mb,ma=col("winBank","main"); local br,bg2,bb,ba=col("winBank","background")
        local ir,ig,ib,ia=col("winBank","borders"); local cr,cg,cb,ca=col("winBank","controls")
        local tr,tg,tb,ta=col("winBank","tabs")
        SkinNS(BankFrame,mr,mg,mb,ma); T(BankFrameBg,br,bg2,bb,ba)
        for _,f in pairs({BankSlotsFrame,ReagentBankFrame,BankPanel}) do SkinNS(f,ir,ig,ib,ia) end
        SkinBox(BankItemSearchBox,cr,cg,cb,ca); SkinTabs(BankFrame,tr,tg,tb,ta)
        for _,v in pairs({BankPanel:GetChildren()}) do
            if type(v)=="table" and v.Border and v.Border:GetObjectType()=="Texture" then T(v.Border,tr,tg,tb,ta) end
        end
        for i=7,13 do
            local f=_G["ContainerFrame"..i]
            if f then
                f.Bg.TopSection:SetVertexColor(br,bg2,bb,ba); f.Bg.BottomEdge:SetVertexColor(br,bg2,bb,ba)
                f.Bg.BottomLeft:SetColorTexture(br,bg2,bb,ba); f.Bg.BottomRight:SetColorTexture(br,bg2,bb,ba)
                SkinNS(f,mr,mg,mb,ma)
            end
        end
    end,
    remove=function(self)
        RestoreNS(BankFrame); R(BankFrameBg)
        for _,f in pairs({BankSlotsFrame,ReagentBankFrame,BankPanel}) do RestoreNS(f) end
        RestoreBox(BankItemSearchBox)
        for i=7,13 do RestoreNS(_G["ContainerFrame"..i]) end
    end,
})

-- ========================================================
-- Calendar
-- ========================================================
C:Register("winCalendar", {
    label="Calendar", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=2}},
    apply=function(self)
        WL("Blizzard_Calendar", function()
            local mr,mg,mb,ma=col("winCalendar","main"); local cr,cg,cb,ca=col("winCalendar","controls")
            for _,tex in pairs({
                CalendarFrameTopLeftTexture,CalendarFrameTopMiddleTexture,CalendarFrameTopRightTexture,
                CalendarFrameRightTopTexture,CalendarFrameRightMiddleTexture,CalendarFrameRightBottomTexture,
                CalendarFrameBottomRightTexture,CalendarFrameBottomMiddleTexture,CalendarFrameBottomLeftTexture,
                CalendarFrameLeftBottomTexture,CalendarFrameLeftMiddleTexture,CalendarFrameLeftTopTexture,
                CalendarViewHolidayFrame.Header.LeftBG,CalendarViewHolidayFrame.Header.CenterBG,CalendarViewHolidayFrame.Header.RightBG,
            }) do T(tex,mr,mg,mb,ma) end
            SkinSB(CalendarViewHolidayFrame,mr,mg,mb,ma)
            T(CalendarFrame.FilterButton and CalendarFrame.FilterButton.Background,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_Calendar") then return end
        for _,tex in pairs({
            CalendarFrameTopLeftTexture,CalendarFrameTopMiddleTexture,CalendarFrameTopRightTexture,
            CalendarFrameRightTopTexture,CalendarFrameRightMiddleTexture,CalendarFrameRightBottomTexture,
            CalendarFrameBottomRightTexture,CalendarFrameBottomMiddleTexture,CalendarFrameBottomLeftTexture,
            CalendarFrameLeftBottomTexture,CalendarFrameLeftMiddleTexture,CalendarFrameLeftTopTexture,
            CalendarViewHolidayFrame.Header.LeftBG,CalendarViewHolidayFrame.Header.CenterBG,CalendarViewHolidayFrame.Header.RightBG,
        }) do R(tex) end
        C.RestoreBorder(CalendarViewHolidayFrame)
        R(CalendarFrame.FilterButton and CalendarFrame.FilterButton.Background)
    end,
})

-- ========================================================
-- Channel Frame (Blizzard_Communities)
-- ========================================================
C:Register("winChannel", {
    label="Chat Channels", group="Windows",
    colors={
        main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},
        background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},
        borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},
        controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4},
    },
    apply=function(self)
        WL("Blizzard_Communities", function()
            local mr,mg,mb,ma=col("winChannel","main"); local br,bg2,bb,ba=col("winChannel","background")
            local ir,ig,ib,ia=col("winChannel","borders"); local cr,cg,cb,ca=col("winChannel","controls")
            SkinNS(ChannelFrame,mr,mg,mb,ma)
            for _,tex in pairs({CreateChannelPopup.Header.LeftBG,CreateChannelPopup.Header.CenterBG,CreateChannelPopup.Header.RightBG,
                CreateChannelPopup.Name.Left,CreateChannelPopup.Name.Middle,CreateChannelPopup.Name.Right,
                CreateChannelPopup.Password.Left,CreateChannelPopup.Password.Middle,CreateChannelPopup.Password.Right}) do T(tex,mr,mg,mb,ma) end
            SkinSB(CreateChannelPopup.BG,mr,mg,mb,ma)
            T(ChannelFrameBg,br,bg2,bb,ba)
            for _,f in pairs({ChannelFrame.RightInset,ChannelFrame.LeftInset,ChannelFrameInset}) do SkinNS(f,ir,ig,ib,ia) end
            SkinScrollBar(ChannelFrame.ChannelRoster,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_Communities") then return end
        RestoreNS(ChannelFrame); R(ChannelFrameBg)
        for _,f in pairs({ChannelFrame.RightInset,ChannelFrame.LeftInset,ChannelFrameInset}) do RestoreNS(f) end
    end,
})

-- ========================================================
-- Character Frame
-- ========================================================
C:Register("winCharacter", {
    label="Character Info", group="Windows",
    colors={
        main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},
        background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2,followClassColor=true},
        borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},
        controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4},
        tabs={label="Tabs",r=DT.r,g=DT.g,b=DT.b,a=1,order=5},
    },
    apply=function(self)
        local mr,mg,mb,ma=col("winCharacter","main"); local br,bg2,bb,ba=col("winCharacter","background")
        local ir,ig,ib,ia=col("winCharacter","borders"); local cr,cg,cb,ca=col("winCharacter","controls")
        local tr,tg,tb,ta=col("winCharacter","tabs")
        for _,f in pairs({CharacterFrame,CurrencyTransferLog,CurrencyTransferMenu}) do SkinNS(f,mr,mg,mb,ma) end
        for _,tex in pairs({
            CharacterStatsPane.ClassBackground,
            PaperDollInnerBorderTop,PaperDollInnerBorderTopRight,PaperDollInnerBorderRight,
            PaperDollInnerBorderBottom,PaperDollInnerBorderBottomRight,PaperDollInnerBorderBottomLeft,
            PaperDollInnerBorderLeft,PaperDollInnerBorderTopLeft,CharacterFrameInset.Bg,
            CharacterTrinket0SlotFrame,CharacterTrinket1SlotFrame,CharacterFinger0SlotFrame,CharacterFinger1SlotFrame,
            CharacterFeetSlotFrame,CharacterLegsSlotFrame,CharacterWaistSlotFrame,CharacterHandsSlotFrame,
            CharacterWristSlotFrame,CharacterSecondaryHandSlotFrame,CharacterMainHandSlotFrame,
            CharacterTabardSlotFrame,CharacterShirtSlotFrame,CharacterChestSlotFrame,CharacterBackSlotFrame,
            CharacterShoulderSlotFrame,CharacterNeckSlotFrame,CharacterHeadSlotFrame,CharacterFrame.Background,
        }) do T(tex,mr,mg,mb,ma) end
        SkinSB(TokenFramePopup,mr,mg,mb,ma)
        for _,tex in pairs({CharacterFrameBg,CurrencyTransferLogBg,CurrencyTransferMenuBg,CharacterFrameInset.Bg}) do T(tex,br,bg2,bb,ba) end
        for _,f in pairs({CharacterFrameInset,CharacterFrameInsetRight,CurrencyTransferLogInset,CurrencyTransferMenuInset}) do SkinNS(f,ir,ig,ib,ia) end
        for _,f in pairs({PaperDollFrame.TitleManagerPane,PaperDollFrame.EquipmentManagerPane,ReputationFrame,TokenFrame,CurrencyTransferLog}) do SkinScrollBar(f,cr,cg,cb,ca) end
        T(ReputationFrame.filterDropdown and ReputationFrame.filterDropdown.Background,cr,cg,cb,ca)
        T(TokenFrame.filterDropdown and TokenFrame.filterDropdown.Background,cr,cg,cb,ca)
        for _,tab in pairs({CharacterFrameTab1,CharacterFrameTab2,CharacterFrameTab3}) do SkinTabs(tab,tr,tg,tb,ta) end
    end,
    remove=function(self)
        for _,f in pairs({CharacterFrame,CurrencyTransferLog,CurrencyTransferMenu}) do RestoreNS(f) end
        for _,tex in pairs({CharacterFrameBg,CurrencyTransferLogBg,CurrencyTransferMenuBg,CharacterFrameInset.Bg,
            CharacterStatsPane.ClassBackground,CharacterFrame.Background,
            PaperDollInnerBorderTop,PaperDollInnerBorderTopRight,PaperDollInnerBorderRight,
            PaperDollInnerBorderBottom,PaperDollInnerBorderBottomRight,PaperDollInnerBorderBottomLeft,
            PaperDollInnerBorderLeft,PaperDollInnerBorderTopLeft,
            CharacterTrinket0SlotFrame,CharacterTrinket1SlotFrame,CharacterFinger0SlotFrame,CharacterFinger1SlotFrame,
            CharacterFeetSlotFrame,CharacterLegsSlotFrame,CharacterWaistSlotFrame,CharacterHandsSlotFrame,
            CharacterWristSlotFrame,CharacterSecondaryHandSlotFrame,CharacterMainHandSlotFrame,
            CharacterTabardSlotFrame,CharacterShirtSlotFrame,CharacterChestSlotFrame,CharacterBackSlotFrame,
            CharacterShoulderSlotFrame,CharacterNeckSlotFrame,CharacterHeadSlotFrame,
        }) do R(tex) end
        C.RestoreBorder(TokenFramePopup)
        for _,f in pairs({CharacterFrameInset,CharacterFrameInsetRight,CurrencyTransferLogInset,CurrencyTransferMenuInset}) do RestoreNS(f) end
        for _,f in pairs({PaperDollFrame.TitleManagerPane,PaperDollFrame.EquipmentManagerPane,ReputationFrame,TokenFrame,CurrencyTransferLog}) do RestoreScrollBar(f) end
        R(ReputationFrame.filterDropdown and ReputationFrame.filterDropdown.Background)
        R(TokenFrame.filterDropdown and TokenFrame.filterDropdown.Background)
        for _,tab in pairs({CharacterFrameTab1,CharacterFrameTab2,CharacterFrameTab3}) do SkinTabs(tab,1,1,1,1) end
    end,
})

-- ========================================================
-- Class Trainer
-- ========================================================
C:Register("winTrainer", {
    label="Class Trainer", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_TrainerUI", function()
            local mr,mg,mb,ma=col("winTrainer","main"); local br,bg2,bb,ba=col("winTrainer","background")
            local ir,ig,ib,ia=col("winTrainer","borders"); local cr,cg,cb,ca=col("winTrainer","controls")
            SkinNS(ClassTrainerFrame,mr,mg,mb,ma); T(ClassTrainerFrameBg,br,bg2,bb,ba)
            for _,f in pairs({ClassTrainerFrameInset,ClassTrainerFrameBottomInset}) do SkinNS(f,ir,ig,ib,ia) end
            SkinScrollBar(ClassTrainerFrame,cr,cg,cb,ca)
            T(ClassTrainerFrame.FilterDropdown and ClassTrainerFrame.FilterDropdown.Background,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_TrainerUI") then return end
        RestoreNS(ClassTrainerFrame); R(ClassTrainerFrameBg)
        for _,f in pairs({ClassTrainerFrameInset,ClassTrainerFrameBottomInset}) do RestoreNS(f) end
    end,
})

-- ========================================================
-- Click Binding
-- ========================================================
C:Register("winClickBind", {
    label="Key Bindings", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_ClickBindingUI", function()
            local mr,mg,mb,ma=col("winClickBind","main"); local br,bg2,bb,ba=col("winClickBind","background")
            local ir,ig,ib,ia=col("winClickBind","borders"); local cr,cg,cb,ca=col("winClickBind","controls")
            for _,f in pairs({ClickBindingFrame,ClickBindingFrame.TutorialFrame}) do SkinNS(f,mr,mg,mb,ma) end
            T(ClickBindingFrameBg,br,bg2,bb,ba); SkinNS(ClickBindingFrame.ScrollBoxBackground,ir,ig,ib,ia)
            SkinScrollBar(ClickBindingFrame,cr,cg,cb,ca)
            T(ClickBindingFrame.MouseoverCastKeyDropdown and ClickBindingFrame.MouseoverCastKeyDropdown.Background,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ClickBindingUI") then return end
        RestoreNS(ClickBindingFrame); R(ClickBindingFrameBg)
    end,
})

-- ========================================================
-- Collections Journal
-- ========================================================
C:Register("winCollections", {
    label="Warband Collections", group="Windows", colors=wc(),
    apply=function(self)
        WL("Blizzard_Collections", function()
            local mr,mg,mb,ma=col("winCollections","main"); local br,bg2,bb,ba=col("winCollections","background")
            local ir,ig,ib,ia=col("winCollections","borders"); local cr,cg,cb,ca=col("winCollections","controls")
            local tr,tg,tb,ta=col("winCollections","tabs")
            SkinNS(CollectionsJournal,mr,mg,mb,ma); T(CollectionsJournalBg,br,bg2,bb,ba)
            for _,f in pairs({
                MountJournal.LeftInset,MountJournal.RightInset,MountJournal.BottomLeftInset,
                PetJournal.LeftInset,PetJournal.RightInset,PetJournalPetCardInset,
                ToyBox.iconsFrame,HeirloomsJournal.iconsFrame,WardrobeCollectionFrame.ItemsCollectionFrame,
                WardrobeCollectionFrame.SetsTransmogFrame,WardrobeCollectionFrame.SetsCollectionFrame.RightInset,
                WardrobeCollectionFrame.SetsCollectionFrame.LeftInset,WarbandSceneJournal.IconsFrame,
            }) do SkinNS(f,ir,ig,ib,ia) end
            T(WardrobeCollectionFrame.progressBar.border,ir,ig,ib,ia)
            T(HeirloomsJournal.progressBar.border,ir,ig,ib,ia)
            T(ToyBox.progressBar.border,ir,ig,ib,ia)
            T(MountJournalSummonRandomFavoriteButtonBorder,ir,ig,ib,ia)
            T(PetJournalSummonRandomFavoritePetButtonBorder,ir,ig,ib,ia)
            T(PetJournalHealPetButtonBorder,ir,ig,ib,ia)
            for _,f in pairs({MountJournal,PetJournal,WardrobeCollectionFrame.SetsCollectionFrame.ListContainer}) do SkinScrollBar(f,cr,cg,cb,ca) end
            for _,box in pairs({WardrobeCollectionFrameSearchBox,HeirloomsJournalSearchBox,ToyBox.searchBox,PetJournalSearchBox,MountJournalSearchBox}) do SkinBox(box,cr,cg,cb,ca) end
            T(MountJournal.FilterDropdown and MountJournal.FilterDropdown.Background,cr,cg,cb,ca)
            T(PetJournal.FilterDropdown and PetJournal.FilterDropdown.Background,cr,cg,cb,ca)
            for _,tab in pairs({CollectionsJournalTab1,CollectionsJournalTab2,CollectionsJournalTab3,CollectionsJournalTab4,CollectionsJournalTab5,CollectionsJournalTab6,WardrobeCollectionFrameTab1,WardrobeCollectionFrameTab2}) do SkinTabs(tab,tr,tg,tb,ta) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then return end
        RestoreNS(CollectionsJournal); R(CollectionsJournalBg)
    end,
})

-- ========================================================
-- Color Picker
-- ========================================================
C:Register("winColorPicker", {
    label="Color Picker", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=2}},
    apply=function(self)
        local mr,mg,mb,ma=col("winColorPicker","main"); local cr,cg,cb,ca=col("winColorPicker","controls")
        SkinSB(ColorPickerFrame,mr,mg,mb,ma)
        for _,tex in pairs({ColorPickerFrame.Header.LeftBG,ColorPickerFrame.Header.CenterBG,ColorPickerFrame.Header.RightBG}) do T(tex,mr,mg,mb,ma) end
        for _,tex in pairs({ColorPickerFrame.Content.HexBox.Left,ColorPickerFrame.Content.HexBox.Middle,ColorPickerFrame.Content.HexBox.Right}) do T(tex,cr,cg,cb,ca) end
    end,
    remove=function(self)
        RB(ColorPickerFrame)
        R(ColorPickerFrame.Header.LeftBG); R(ColorPickerFrame.Header.CenterBG); R(ColorPickerFrame.Header.RightBG)
        R(ColorPickerFrame.Content.HexBox.Left); R(ColorPickerFrame.Content.HexBox.Middle); R(ColorPickerFrame.Content.HexBox.Right)
    end,
})

-- ========================================================
-- Cooldown Viewer Settings
-- ========================================================
C:Register("winCooldownSettings", {
    label="Cooldown Viewer Settings", group="Windows", colors=wc(),
    apply=function(self)
        local mr,mg,mb,ma=col("winCooldownSettings","main"); local br,bg2,bb,ba=col("winCooldownSettings","background")
        local ir,ig,ib,ia=col("winCooldownSettings","borders"); local cr,cg,cb,ca=col("winCooldownSettings","controls")
        local tr,tg,tb,ta=col("winCooldownSettings","tabs")
        SkinNS(CooldownViewerSettings,mr,mg,mb,ma); T(CooldownViewerSettingsBg,br,bg2,bb,ba)
        SkinNS(CooldownViewerSettingsInset,ir,ig,ib,ia)
        SkinBox(CooldownViewerSettings.SearchBox,cr,cg,cb,ca)
        SkinScrollBar(CooldownViewerSettings.CooldownScroll,cr,cg,cb,ca)
        T(CooldownViewerSettings.SpellsTab and CooldownViewerSettings.SpellsTab.Background,tr,tg,tb,ta)
        T(CooldownViewerSettings.AurasTab and CooldownViewerSettings.AurasTab.Background,tr,tg,tb,ta)
    end,
    remove=function(self)
        RestoreNS(CooldownViewerSettings); R(CooldownViewerSettingsBg); RestoreNS(CooldownViewerSettingsInset)
    end,
})

-- ========================================================
-- Damage Meter
-- ========================================================
C:Register("winDamageMeter", {
    label="Damage Meter", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3}},
    apply=function(self)
        local mr,mg,mb,ma=col("winDamageMeter","main"); local ir,ig,ib,ia=col("winDamageMeter","borders")
        local cr,cg,cb,ca=col("winDamageMeter","controls")
        if not DamageMeter then return end
        local function skinWindow(index)
            local sw=_G["DamageMeterSessionWindow"..index]
            if not sw then return end
            T(sw.Header,mr,mg,mb,ma)
            T(sw.SourceWindow and sw.SourceWindow.Background,ir,ig,ib,ia)
            SkinScrollBar(sw,cr,cg,cb,ca); SkinScrollBar(sw.SourceWindow,cr,cg,cb,ca)
        end
        local maxCount=DamageMeterMixin and DamageMeterMixin:GetMaxSessionWindowCount() or 5
        for i=1,maxCount do skinWindow(i) end
        hooksecurefunc(DamageMeter,"SetupSessionWindow",function(_,_,idx) skinWindow(idx) end)
    end,
    remove=function(self)
        if not DamageMeter then return end
        local maxCount=DamageMeterMixin and DamageMeterMixin:GetMaxSessionWindowCount() or 5
        for i=1,maxCount do
            local sw=_G["DamageMeterSessionWindow"..i]
            if sw then R(sw.Header); R(sw.SourceWindow and sw.SourceWindow.Background); RestoreScrollBar(sw); RestoreScrollBar(sw.SourceWindow) end
        end
    end,
})

-- ========================================================
-- Delves Companion
-- ========================================================
C:Register("winDelves", {
    label="Delve Companion", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3}},
    apply=function(self)
        local mr,mg,mb,ma=col("winDelves","main"); local br,bg2,bb,ba=col("winDelves","background")
        local cr,cg,cb,ca=col("winDelves","controls")
        SkinSB(DelvesCompanionConfigurationFrame,mr,mg,mb,ma)
        SkinNS(DelvesCompanionAbilityListFrame,mr,mg,mb,ma)
        T(DelvesCompanionAbilityListFrameBg,br,bg2,bb,ba)
        T(DelvesCompanionAbilityListFrame.DelvesCompanionRoleDropdown and DelvesCompanionAbilityListFrame.DelvesCompanionRoleDropdown.Background,cr,cg,cb,ca)
    end,
    remove=function(self)
        RB(DelvesCompanionConfigurationFrame); RestoreNS(DelvesCompanionAbilityListFrame); R(DelvesCompanionAbilityListFrameBg)
    end,
})

-- ========================================================
-- Delves Difficulty Picker
-- ========================================================
C:Register("winDelvesDiff", {
    label="Delve Difficulty", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=2}},
    apply=function(self)
        WL("Blizzard_DelvesDifficultyPicker", function()
            local mr,mg,mb,ma=col("winDelvesDiff","main"); local cr,cg,cb,ca=col("winDelvesDiff","controls")
            SkinSB(DelvesDifficultyPickerFrame,mr,mg,mb,ma)
            T(DelvesDifficultyPickerFrame.Dropdown and DelvesDifficultyPickerFrame.Dropdown.Background,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_DelvesDifficultyPicker") then return end
        RB(DelvesDifficultyPickerFrame)
    end,
})

-- ========================================================
-- Dressing Room
-- ========================================================
C:Register("winDressup", {
    label="Dressing Room", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=2},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        local mr,mg,mb,ma=col("winDressup","main"); local ir,ig,ib,ia=col("winDressup","borders")
        local br,bg2,bb,ba=col("winDressup","background"); local cr,cg,cb,ca=col("winDressup","controls")
        SkinNS(DressUpFrame,mr,mg,mb,ma)
        for _,v in pairs({DressUpFrame.CustomSetDetailsPanel:GetRegions()}) do
            if v:GetDrawLayer()=="OVERLAY" then T(v,mr,mg,mb,ma) end
        end
        SkinNS(DressUpFrameInset,ir,ig,ib,ia); T(DressUpFrameBg,br,bg2,bb,ba)
        T(DressUpFrameCustomSetDropdown and DressUpFrameCustomSetDropdown.Background,cr,cg,cb,ca)
    end,
    remove=function(self) RestoreNS(DressUpFrame); RestoreNS(DressUpFrameInset); R(DressUpFrameBg) end,
})

-- ========================================================
-- Encounter Journal
-- ========================================================
C:Register("winEJ", {
    label="Adventure Guide", group="Windows", colors=wc(),
    apply=function(self)
        WL("Blizzard_EncounterJournal", function()
            local mr,mg,mb,ma=col("winEJ","main"); local br,bg2,bb,ba=col("winEJ","background")
            local ir,ig,ib,ia=col("winEJ","borders"); local cr,cg,cb,ca=col("winEJ","controls")
            local tr,tg,tb,ta=col("winEJ","tabs")
            SkinNS(EncounterJournal,mr,mg,mb,ma); T(EncounterJournalBg,br,bg2,bb,ba)
            SkinNS(EncounterJournalInset,ir,ig,ib,ia)
            T(EncounterJournalNavBarInsetBottomBorder,ir,ig,ib,ia)
            T(EncounterJournalNavBarInsetRightBorder,ir,ig,ib,ia)
            T(EncounterJournalNavBarInsetLeftBorder,ir,ig,ib,ia)
            T(EncounterJournalMonthlyActivitiesFrame.Divider,ir,ig,ib,ia)
            T(EncounterJournalMonthlyActivitiesFrame.DividerVertical,ir,ig,ib,ia)
            for _,tex in pairs({EncounterJournalNavBar.overlay:GetRegions()}) do T(tex,ir,ig,ib,ia) end
            for _,f in pairs({EncounterJournalJourneysFrame,EncounterJournalMonthlyActivitiesFrame,
                EncounterJournalInstanceSelect,EncounterJournal.LootJournalItems.ItemSetsFrame,
                EncounterJournalEncounterFrameInfo.LootContainer,
                EncounterJournalEncounterFrameInfoDetailsScrollFrame,
                EncounterJournalEncounterFrameInfoOverviewScrollFrame}) do SkinScrollBar(f,cr,cg,cb,ca) end
            SkinBox(EncounterJournalSearchBox,cr,cg,cb,ca)
            T(EncounterJournalEncounterFrameInfoDifficulty and EncounterJournalEncounterFrameInfoDifficulty.Background,cr,cg,cb,ca)
            for _,tab in pairs({EncounterJournalJourneysTab,EncounterJournalMonthlyActivitiesTab,
                EncounterJournalSuggestTab,EncounterJournalDungeonTab,EncounterJournalRaidTab,
                EncounterJournalLootJournalTab,EncounterJournal.TutorialsTab}) do SkinTabs(tab,tr,tg,tb,ta) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then return end
        RestoreNS(EncounterJournal); R(EncounterJournalBg); RestoreNS(EncounterJournalInset)
    end,
})

-- ========================================================
-- Event Trace
-- ========================================================
C:Register("winEventLog", {
    label="Event Log", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_EventTrace", function()
            local mr,mg,mb,ma=col("winEventLog","main"); local br,bg2,bb,ba=col("winEventLog","background")
            local ir,ig,ib,ia=col("winEventLog","borders"); local cr,cg,cb,ca=col("winEventLog","controls")
            SkinNS(EventTrace,mr,mg,mb,ma); T(EventTraceBg,br,bg2,bb,ba); SkinNS(EventTraceInset,ir,ig,ib,ia)
            SkinScrollBar(EventTrace.Log and EventTrace.Log.Events,cr,cg,cb,ca)
            SkinScrollBar(EventTrace.Log and EventTrace.Log.Search,cr,cg,cb,ca)
            SkinBox(EventTrace.Log and EventTrace.Log.Bar and EventTrace.Log.Bar.SearchBox,cr,cg,cb,ca)
            T(EventTrace.SubtitleBar and EventTrace.SubtitleBar.OptionsDropdown and EventTrace.SubtitleBar.OptionsDropdown.Background,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_EventTrace") then return end
        RestoreNS(EventTrace); R(EventTraceBg); RestoreNS(EventTraceInset)
    end,
})

-- ========================================================
-- Flight Map
-- ========================================================
C:Register("winFlightMap", {
    label="Flight Map", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1}},
    apply=function(self)
        WL("Blizzard_FlightMap", function()
            local mr,mg,mb,ma=col("winFlightMap","main")
            SkinNS(FlightMapFrame and FlightMapFrame.BorderFrame,mr,mg,mb,ma)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_FlightMap") then return end
        RestoreNS(FlightMapFrame and FlightMapFrame.BorderFrame)
    end,
})

-- ========================================================
-- Friends Frame
-- ========================================================
C:Register("winFriends", {
    label="Social", group="Windows", colors=wc(),
    toggles={updateBgOnlineStatus={label="Color Background by Online Status",default=true}},
    apply=function(self)
        local mr,mg,mb,ma=col("winFriends","main"); local br,bg2,bb,ba=col("winFriends","background")
        local ir,ig,ib,ia=col("winFriends","borders"); local cr,cg,cb,ca=col("winFriends","controls")
        local tr,tg,tb,ta=col("winFriends","tabs")
        SkinNS(FriendsFrame,mr,mg,mb,ma)
        for _,f in pairs({FriendsFrameBattlenetFrame.BroadcastFrame,RecruitAFriendRewardsFrame,RaidInfoFrame.Border}) do SkinSB(f,mr,mg,mb,ma) end
        for _,tex in pairs({RaidInfoFrame.Header.LeftBG,RaidInfoFrame.Header.CenterBG,RaidInfoFrame.Header.RightBG}) do T(tex,mr,mg,mb,ma) end
        for _,tex in pairs({FriendsFrameBg,RaidInfoDetailHeader,RaidInfoDetailFooter,RecruitAFriendFrame.RecruitList.Header.Background}) do T(tex,br,bg2,bb,ba) end
        for _,f in pairs({FriendsFrameInset,WhoFrameListInset,WhoFrameEditBoxInset,RecruitAFriendFrame.RecruitList.ScrollFrameInset,RecruitAFriendFrame.RewardClaiming.Inset}) do SkinNS(f,ir,ig,ib,ia) end
        SkinSB(FriendsFrameBattlenetFrame.BroadcastFrame.EditBox,ir,ig,ib,ia)
        for _,tex in pairs({WhoFrameColumnHeader1Left,WhoFrameColumnHeader1Middle,WhoFrameColumnHeader1Right,
            WhoFrameColumnHeader2Left,WhoFrameColumnHeader2Middle,WhoFrameColumnHeader2Right,
            WhoFrameColumnHeader3Left,WhoFrameColumnHeader3Middle,WhoFrameColumnHeader3Right,
            WhoFrameColumnHeader4Left,WhoFrameColumnHeader4Middle,WhoFrameColumnHeader4Right,
            RaidInfoInstanceLabelLeft,RaidInfoInstanceLabelMiddle,RaidInfoInstanceLabelRight,
            RaidInfoIDLabelLeft,RaidInfoIDLabelMiddle,RaidInfoIDLabelRight}) do T(tex,ir,ig,ib,ia) end
        for _,f in pairs({FriendsListFrame,IgnoreListFrame,RecruitAFriendFrame.RecruitList,WhoFrame,QuickJoinFrame,RaidInfoFrame}) do SkinScrollBar(f,cr,cg,cb,ca) end
        T(FriendsFrameStatusDropdown and FriendsFrameStatusDropdown.Background,cr,cg,cb,ca)
        T(WhoFrameDropdown and WhoFrameDropdown.Background,cr,cg,cb,ca)
        for _,tab in pairs({FriendsFrameTab1,FriendsFrameTab2,FriendsFrameTab3,FriendsFrameTab4,FriendsTabHeaderTab1,FriendsTabHeaderTab2,FriendsTabHeaderTab3}) do SkinTabs(tab,tr,tg,tb,ta) end
        if C:GetToggle("winFriends","updateBgOnlineStatus") then
            local function updateBG()
                local bnetAFK,bnetDND=select(5,BNGetInfo())
                local c=bnetAFK and {1,1,0,1} or bnetDND and {1,0,0,1} or {0,1,0,1}
                FriendsFrameBg:SetVertexColor(c[1],c[2],c[3],c[4])
            end
            -- No hooksecurefunc on BNGetInfo (would cause a stack overflow)
            -- Instead: event on status change
            if not AklimeMod_FriendsFrame_BNFrame then
                AklimeMod_FriendsFrame_BNFrame = CreateFrame("Frame")
                AklimeMod_FriendsFrame_BNFrame:RegisterEvent("BN_INFO_CHANGED")
                AklimeMod_FriendsFrame_BNFrame:SetScript("OnEvent", function()
                    if AklimeMod_FriendsFrame_BGCallback then
                        AklimeMod_FriendsFrame_BGCallback()
                    end
                end)
            end
            AklimeMod_FriendsFrame_BGCallback = updateBG
            updateBG()
        end
    end,
    remove=function(self)
        RestoreNS(FriendsFrame); R(FriendsFrameBg)
        for _,f in pairs({FriendsFrameInset,WhoFrameListInset,WhoFrameEditBoxInset}) do RestoreNS(f) end
        for _,tex in pairs({RaidInfoFrame.Header.LeftBG,RaidInfoFrame.Header.CenterBG,RaidInfoFrame.Header.RightBG,RaidInfoDetailHeader,RaidInfoDetailFooter}) do R(tex) end
        for _,tex in pairs({WhoFrameColumnHeader1Left,WhoFrameColumnHeader1Middle,WhoFrameColumnHeader1Right,
            WhoFrameColumnHeader2Left,WhoFrameColumnHeader2Middle,WhoFrameColumnHeader2Right,
            WhoFrameColumnHeader3Left,WhoFrameColumnHeader3Middle,WhoFrameColumnHeader3Right,
            WhoFrameColumnHeader4Left,WhoFrameColumnHeader4Middle,WhoFrameColumnHeader4Right,
            RaidInfoInstanceLabelLeft,RaidInfoInstanceLabelMiddle,RaidInfoInstanceLabelRight,
            RaidInfoIDLabelLeft,RaidInfoIDLabelMiddle,RaidInfoIDLabelRight}) do R(tex) end
        R(FriendsFrameStatusDropdown and FriendsFrameStatusDropdown.Background)
        R(WhoFrameDropdown and WhoFrameDropdown.Background)
        for _,tab in pairs({FriendsFrameTab1,FriendsFrameTab2,FriendsFrameTab3,FriendsFrameTab4,FriendsTabHeaderTab1,FriendsTabHeaderTab2,FriendsTabHeaderTab3}) do SkinTabs(tab,1,1,1,1) end
        -- Disable event callback
        AklimeMod_FriendsFrame_BGCallback = nil
    end,
})

-- ========================================================
-- Game Menu
-- ========================================================
-- The menu buttons come from a frame pool and are rebuilt on every
-- open, so tinting is handled as a separate function plus hook.
local function EachGameMenuButton(fn)
    local gm = GameMenuFrame
    if not gm then return end
    if gm.buttonPool then
        for btn in gm.buttonPool:EnumerateActive() do fn(btn) end
    else
        for _,child in pairs({ gm:GetChildren() }) do
            if child.GetNormalTexture then fn(child) end
        end
    end
end

local function TintGameMenuButtons(r,g,b,a,des)
    EachGameMenuButton(function(btn)
        for _,tex in pairs({
            btn.Left, btn.Center, btn.Right,
            btn:GetNormalTexture(), btn:GetHighlightTexture(),
            btn:GetPushedTexture(), btn:GetDisabledTexture(),
        }) do
            if tex then tex:SetDesaturation(des); tex:SetVertexColor(r,g,b,a) end
        end
    end)
end

-- Handle buttons depending on the toggle. The default leaves Blizzard's red
-- original texture with gradient and gold trim. When coloring is enabled,
-- the texture is desaturated and tinted with the chosen color.
local function ApplyGameMenuButtons()
    if C:GetToggle("winGameMenu", "colorButtons") then
        local r,g,b,a = col("winGameMenu","buttons")
        TintGameMenuButtons(r,g,b,a,1)
    else
        TintGameMenuButtons(1,1,1,1,0)
    end
end

C:Register("winGameMenu", {
    label="Game Menu", group="Windows",
    colors={
        main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},
        background={label="Background",r=0,g=0,b=0,a=0.7,order=2},
        buttons={label="Buttons",r=0.85,g=0.18,b=0.15,a=1,order=3},
    },
    toggles={colorButtons={label="Color Buttons",default=false}},
    apply=function(self)
        local mr,mg,mb,ma = col("winGameMenu","main")
        local br,bg2,bb,ba = col("winGameMenu","background")
        SkinSB(GameMenuFrame, mr,mg,mb,ma)
        for _,tex in pairs({GameMenuFrame.Header.LeftBG,GameMenuFrame.Header.CenterBG,GameMenuFrame.Header.RightBG}) do
            T(tex, mr,mg,mb,ma)
        end
        local bg = GameMenuFrame.Border and GameMenuFrame.Border.Bg
        if bg then
            -- Cache original texture on first apply
            if not self._bgOrigTex then
                self._bgOrigTex = bg:GetTexture()
            end
            bg:SetDesaturation(1)
            bg:SetColorTexture(br, bg2, bb, ba)
            bg:SetVertexColor(br, bg2, bb, ba)
        end
        -- Leave buttons native or tint them per toggle, also after every
        -- menu rebuild via the hook.
        ApplyGameMenuButtons()
        if not self._btnHook and GameMenuFrame then
            self._btnHook = true
            local function refresh()
                if C:IsEnabled("winGameMenu") then ApplyGameMenuButtons() end
            end
            if type(GameMenuFrame.InitButtons) == "function" then
                hooksecurefunc(GameMenuFrame, "InitButtons", refresh)
            else
                GameMenuFrame:HookScript("OnShow", refresh)
            end
        end
    end,
    remove=function(self)
        RB(GameMenuFrame)
        R(GameMenuFrame.Header.LeftBG)
        R(GameMenuFrame.Header.CenterBG)
        R(GameMenuFrame.Header.RightBG)
        TintGameMenuButtons(1,1,1,1,0)
        local bg = GameMenuFrame.Border and GameMenuFrame.Border.Bg
        if bg then
            bg:SetDesaturation(0)
            bg:SetVertexColor(1, 1, 1, 1)
            -- Restore original Blizzard texture
            if self._bgOrigTex then
                bg:SetTexture(self._bgOrigTex)
            else
                bg:SetColorTexture(0, 0, 0, 0)
            end
        end
    end,
})

-- ========================================================
-- Gossip
-- ========================================================
C:Register("winGossip", {
    label="Gossip", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        local mr,mg,mb,ma=col("winGossip","main"); local br,bg2,bb,ba=col("winGossip","background")
        local ir,ig,ib,ia=col("winGossip","borders"); local cr,cg,cb,ca=col("winGossip","controls")
        SkinNS(GossipFrame,mr,mg,mb,ma); T(GossipFrameBg,br,bg2,bb,ba)
        SkinNS(GossipFrameInset,ir,ig,ib,ia); SkinScrollBar(GossipFrame.GreetingPanel,cr,cg,cb,ca)
    end,
    remove=function(self)
        RestoreNS(GossipFrame); R(GossipFrameBg); RestoreNS(GossipFrameInset)
    end,
})

-- ========================================================
-- Guild Bank
-- ========================================================
C:Register("winGuildBank", {
    label="Guild Bank", group="Windows",
    colors=wc({emblem={label="Emblem",r=1.0,g=0.843,b=0.0,a=1,order=0.1}}),
    apply=function(self)
        WL("Blizzard_GuildBankUI", function()
            local mr,mg,mb,ma=col("winGuildBank","main"); local br,bg2,bb,ba=col("winGuildBank","background")
            local ir,ig,ib,ia=col("winGuildBank","borders"); local cr,cg,cb,ca=col("winGuildBank","controls")
            local tr,tg,tb,ta=col("winGuildBank","tabs"); local er,eg,eb,ea=col("winGuildBank","emblem")
            for _,tex in pairs({GuildBankFrame.Emblem.Left,GuildBankFrame.Emblem.Right}) do T(tex,er,eg,eb,ea) end
            for _,tex in pairs({GuildBankFrame.TopLeftCorner,GuildBankFrame.LeftBorder,GuildBankFrame.BotLeftCorner,GuildBankFrame.BottomBorder,GuildBankFrame.BotRightCorner,GuildBankFrame.RightBorder,GuildBankFrame.TopRightCorner,GuildBankFrame.TopBorder}) do T(tex,mr,mg,mb,ma) end
            T(GuildBankFrame.RedMarbleBG,br,bg2,bb,ba)
            for _,tex in pairs({GuildBankFrameTopLeftOuter,GuildBankFrameTopOuter,GuildBankFrameTopRightOuter,GuildBankFrameRightOuter,GuildBankFrameBottomRightOuter,GuildBankFrameBottomOuter,GuildBankFrameBottomLeftOuter,GuildBankFrameLeftOuter,
                GuildBankFrameTopLeftInner,GuildBankFrameTopInner,GuildBankFrameTopRightInner,GuildBankFrameRightInner,GuildBankFrameBottomRightInner,GuildBankFrameBottomInner,GuildBankFrameBottomLeftInner,GuildBankFrameLeftInner}) do T(tex,ir,ig,ib,ia) end
            SkinBox(GuildItemSearchBox,cr,cg,cb,ca)
            SkinScrollBar(GuildBankFrame.Log,cr,cg,cb,ca); SkinScrollBar(GuildBankInfoScrollFrame,cr,cg,cb,ca)
            for _,tab in pairs({GuildBankFrameTab1,GuildBankFrameTab2,GuildBankFrameTab3,GuildBankFrameTab4}) do SkinTabs(tab,tr,tg,tb,ta) end
            local i=0; while true do i=i+1; local tab=_G["GuildBankTab"..i]; if not tab then break end
                for _,v in pairs({tab:GetRegions()}) do if type(v)=="table" and v.GetObjectType and v:GetObjectType()=="Texture" then T(v,tr,tg,tb,ta) end end
            end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_GuildBankUI") then return end
        for _,tex in pairs({GuildBankFrame.TopLeftCorner,GuildBankFrame.TopBorder,GuildBankFrame.RedMarbleBG}) do R(tex) end
    end,
})

-- ========================================================
-- Housing Dashboard
-- ========================================================
C:Register("winHousing", {
    label="Housing Dashboard", group="Windows", colors=wc(),
    apply=function(self)
        WL("Blizzard_HousingDashboard", function()
            local mr,mg,mb,ma=col("winHousing","main"); local br,bg2,bb,ba=col("winHousing","background")
            local cr,cg,cb,ca=col("winHousing","controls")
            SkinNS(HousingDashboardFrame,mr,mg,mb,ma); T(HousingDashboardFrameBg,br,bg2,bb,ba)
            SkinBox(HousingDashboardFrame.CatalogContent and HousingDashboardFrame.CatalogContent.SearchBox,cr,cg,cb,ca)
            SkinScrollBar(HousingDashboardFrame.CatalogContent and HousingDashboardFrame.CatalogContent.OptionsContainer,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_HousingDashboard") then return end
        RestoreNS(HousingDashboardFrame); R(HousingDashboardFrameBg)
    end,
})

-- ========================================================
-- Housing Model Preview
-- ========================================================
C:Register("winHousingPreview", {
    label="Housing Preview", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1}},
    apply=function(self)
        WL("Blizzard_HousingModelPreview", function()
            local mr,mg,mb,ma=col("winHousingPreview","main")
            SkinNS(HousingModelPreviewFrame,mr,mg,mb,ma)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_HousingModelPreview") then return end
        RestoreNS(HousingModelPreviewFrame)
    end,
})

-- ========================================================
-- Inspect Frame
-- ========================================================
C:Register("winInspect", {
    label="Inspect", group="Windows", colors=wc(),
    toggles={follow_unit_class={label="Adjust Background Color by Class",default=true}},
    apply=function(self)
        WL("Blizzard_InspectUI", function()
            local mr,mg,mb,ma=col("winInspect","main"); local br,bg2,bb,ba=col("winInspect","background")
            local ir,ig,ib,ia=col("winInspect","borders"); local tr,tg,tb,ta=col("winInspect","tabs")
            SkinNS(InspectFrame,mr,mg,mb,ma); T(InspectFrameInset and InspectFrameInset.Bg,mr,mg,mb,ma)
            T(InspectFrameBg,br,bg2,bb,ba); SkinNS(InspectFrameInset,ir,ig,ib,ia)
            for _,tex in pairs({InspectModelFrameBorderBottom,InspectModelFrameBorderBottomRight,InspectModelFrameBorderBottomLeft,
                InspectModelFrameBorderTop,InspectModelFrameBorderTopLeft,InspectModelFrameBorderTopRight,
                InspectModelFrameBorderLeft,InspectModelFrameBorderRight,
                InspectTrinket0SlotFrame,InspectTrinket1SlotFrame,InspectFinger0SlotFrame,InspectFinger1SlotFrame,
                InspectFeetSlotFrame,InspectLegsSlotFrame,InspectWaistSlotFrame,InspectHandsSlotFrame,
                InspectWristSlotFrame,InspectSecondaryHandSlotFrame,InspectMainHandSlotFrame,
                InspectTabardSlotFrame,InspectShirtSlotFrame,InspectChestSlotFrame,InspectBackSlotFrame,
                InspectShoulderSlotFrame,InspectNeckSlotFrame,InspectHeadSlotFrame}) do T(tex,ir,ig,ib,ia) end
            for _,tab in pairs({InspectFrameTab1,InspectFrameTab2,InspectFrameTab3,InspectPaperDollItemsFrame and InspectPaperDollItemsFrame.InspectTalents}) do SkinTabs(tab,tr,tg,tb,ta) end
            if C:GetToggle("winInspect","follow_unit_class") then
                local function updateBg()
                    local unit=INSPECTED_UNIT or "target"
                    local cc=C.GetUnitClassColor(unit)
                    if cc then T(InspectFrameBg,cc.r,cc.g,cc.b) end
                end
                hooksecurefunc("InspectFrame_Show",updateBg); updateBg()
            end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then return end
        RestoreNS(InspectFrame); RestoreNS(InspectFrameInset); R(InspectFrameBg)
    end,
})

-- ========================================================
-- Islands Queue
-- ========================================================
C:Register("winIslandsQueue", {
    label="Island Queue", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1}},
    apply=function(self)
        WL("Blizzard_IslandsQueueUI", function()
            local mr,mg,mb,ma=col("winIslandsQueue","main")
            SkinNS(IslandsQueueFrame,mr,mg,mb,ma)
            T(IslandsQueueFrame.ArtOverlayFrame and IslandsQueueFrame.ArtOverlayFrame.PortraitFrame,mr,mg,mb,ma)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_IslandsQueueUI") then return end
        RestoreNS(IslandsQueueFrame)
    end,
})

-- ========================================================
-- Item Interaction
-- ========================================================
C:Register("winItemInteraction", {
    label="Item Interaction", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3}},
    apply=function(self)
        WL("Blizzard_ItemInteractionUI", function()
            local mr,mg,mb,ma=col("winItemInteraction","main"); local br,bg2,bb,ba=col("winItemInteraction","background")
            local ir,ig,ib,ia=col("winItemInteraction","borders")
            SkinNS(ItemInteractionFrame,mr,mg,mb,ma); T(ItemInteractionFrameBg,br,bg2,bb,ba)
            SkinNS(ItemInteractionFrame.Inset,ir,ig,ib,ia)
            T(ItemInteractionFrame.ButtonFrame and ItemInteractionFrame.ButtonFrame.ButtonBorder,ir,ig,ib,ia)
            T(ItemInteractionFrameMiddle,ir,ig,ib,ia); T(ItemInteractionFrameLeft,ir,ig,ib,ia); T(ItemInteractionFrameRight,ir,ig,ib,ia)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ItemInteractionUI") then return end
        RestoreNS(ItemInteractionFrame); R(ItemInteractionFrameBg); RestoreNS(ItemInteractionFrame.Inset)
    end,
})

-- ========================================================
-- Item Socketing
-- ========================================================
C:Register("winItemSocket", {
    label="Socket Gem", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_ItemSocketingUI", function()
            local mr,mg,mb,ma=col("winItemSocket","main"); local br,bg2,bb,ba=col("winItemSocket","background")
            local ir,ig,ib,ia=col("winItemSocket","borders"); local cr,cg,cb,ca=col("winItemSocket","controls")
            SkinNS(ItemSocketingFrame,mr,mg,mb,ma)
            for _,tex in pairs({ItemSocketingFrame["ParchmentFrame-Top"],ItemSocketingFrame["ParchmentFrame-Right"],ItemSocketingFrame["ParchmentFrame-Left"],ItemSocketingFrame["ParchmentFrame-Bottom"]}) do T(tex,br,bg2,bb,ba) end
            for _,tex in pairs({ItemSocketingFrame.TopRightNub,ItemSocketingFrame.TopLeftNub,ItemSocketingFrame.MiddleRightNub,ItemSocketingFrame.MiddleLeftNub,ItemSocketingFrame.BottomRightNub,ItemSocketingFrame.BottomLeftNub,ItemSocketingFrame["SocketFrame-Left"],ItemSocketingFrame["SocketFrame-Right"]}) do T(tex,ir,ig,ib,ia) end
            SkinScrollBar(ItemSocketingScrollFrame,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ItemSocketingUI") then return end
        RestoreNS(ItemSocketingFrame)
    end,
})

-- ========================================================
-- Item Text Frame
-- ========================================================
C:Register("winBook", {
    label="Book", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        local mr,mg,mb,ma=col("winBook","main"); local br,bg2,bb,ba=col("winBook","background")
        local ir,ig,ib,ia=col("winBook","borders"); local cr,cg,cb,ca=col("winBook","controls")
        SkinNS(ItemTextFrame,mr,mg,mb,ma); T(ItemTextFrameBg,br,bg2,bb,ba)
        SkinNS(ItemTextFrameInset,ir,ig,ib,ia); SkinScrollBar(ItemTextScrollFrame,cr,cg,cb,ca)
    end,
    remove=function(self)
        RestoreNS(ItemTextFrame); R(ItemTextFrameBg); RestoreNS(ItemTextFrameInset); RestoreScrollBar(ItemTextScrollFrame)
    end,
})

-- ========================================================
-- Item Upgrade
-- ========================================================
C:Register("winItemUpgrade", {
    label="Item Upgrade", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_ItemUpgradeUI", function()
            local mr,mg,mb,ma=col("winItemUpgrade","main"); local br,bg2,bb,ba=col("winItemUpgrade","background")
            local ir,ig,ib,ia=col("winItemUpgrade","borders"); local cr,cg,cb,ca=col("winItemUpgrade","controls")
            SkinNS(ItemUpgradeFrame,mr,mg,mb,ma)
            for _,tex in pairs({ItemUpgradeFrame.BottomBG,ItemUpgradeFrame.TopBG}) do T(tex,br,bg2,bb,ba) end
            T(ItemUpgradeFrame.UpgradeItemButton and ItemUpgradeFrame.UpgradeItemButton.ButtonFrame,ir,ig,ib,ia)
            T(ItemUpgradeFramePlayerCurrenciesBorderLeft,ir,ig,ib,ia)
            T(ItemUpgradeFramePlayerCurrenciesBorderMiddle,ir,ig,ib,ia)
            T(ItemUpgradeFramePlayerCurrenciesBorderRight,ir,ig,ib,ia)
            T(ItemUpgradeFrame.ItemInfo and ItemUpgradeFrame.ItemInfo.Dropdown and ItemUpgradeFrame.ItemInfo.Dropdown.Background,cr,cg,cb,ca)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ItemUpgradeUI") then return end
        RestoreNS(ItemUpgradeFrame); R(ItemUpgradeFrame.BottomBG); R(ItemUpgradeFrame.TopBG)
    end,
})

-- ========================================================
-- Loot Frame
-- ========================================================
C:Register("winLoot", {
    label="Loot", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3}},
    apply=function(self)
        local mr,mg,mb,ma=col("winLoot","main"); local br,bg2,bb,ba=col("winLoot","background")
        local cr,cg,cb,ca=col("winLoot","controls")
        for _,f in pairs({LootFrame,GroupLootHistoryFrame}) do SkinNS(f,mr,mg,mb,ma) end
        for _,tex in pairs({LootFrameBg.TopSection,LootFrameBg.BottomEdge,GroupLootHistoryFrameBg.TopSection,GroupLootHistoryFrameBg.BottomEdge}) do T(tex,br,bg2,bb,ba) end
        for _,tex in pairs({LootFrameBg.BottomRight,LootFrameBg.BottomLeft,GroupLootHistoryFrameBg.BottomLeft,GroupLootHistoryFrameBg.BottomRight}) do
            if tex then tex:SetDesaturation(1); tex:SetColorTexture(br,bg2,bb,ba) end
        end
        for _,f in pairs({LootFrame,GroupLootHistoryFrame}) do SkinScrollBar(f,cr,cg,cb,ca) end
        T(GroupLootHistoryFrame.EncounterDropdown and GroupLootHistoryFrame.EncounterDropdown.Background,cr,cg,cb,ca)
    end,
    remove=function(self) RestoreNS(LootFrame); RestoreNS(GroupLootHistoryFrame) end,
})

-- ========================================================
-- Macro Frame
-- ========================================================
C:Register("winMacro", {
    label="Macros", group="Windows", colors=wc(),
    apply=function(self)
        WL("Blizzard_MacroUI", function()
            local mr,mg,mb,ma=col("winMacro","main"); local br,bg2,bb,ba=col("winMacro","background")
            local ir,ig,ib,ia=col("winMacro","borders"); local cr,cg,cb,ca=col("winMacro","controls")
            local tr,tg,tb,ta=col("winMacro","tabs")
            SkinNS(MacroFrame,mr,mg,mb,ma)
            SkinSB(MacroPopupFrame and MacroPopupFrame.BorderBox,mr,mg,mb,ma)
            local ignore={["MacroFramePortrait"]=true,["MacroFrameBg"]=true}
            for _,v in pairs({MacroFrame:GetRegions()}) do
                if v:IsObjectType("texture") and not ignore[v:GetName()] then T(v,mr,mg,mb,ma) end
            end
            T(MacroFrameBg,br,bg2,bb,ba)
            for _,f in pairs({MacroFrameInset,MacroFrameTextBackground}) do SkinNS(f,ir,ig,ib,ia) end
            for _,f in pairs({MacroFrame.MacroSelector,MacroPopupFrame and MacroPopupFrame.IconSelector,MacroFrameScrollFrame}) do SkinScrollBar(f,cr,cg,cb,ca) end
            for _,tab in pairs({MacroFrameTab1,MacroFrameTab2}) do SkinTabs(tab,tr,tg,tb,ta) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_MacroUI") then return end
        RestoreNS(MacroFrame); R(MacroFrameBg)
        for _,f in pairs({MacroFrameInset,MacroFrameTextBackground}) do RestoreNS(f) end
    end,
})

-- ========================================================
-- Mail Frame
-- ========================================================
C:Register("winMail", {
    label="Mail", group="Windows",
    colors=wc({gold_border={label="Gold Border",r=1.0,g=0.843,b=0.0,a=1,order=6},silver_border={label="Silver Border",r=0.753,g=0.753,b=0.753,a=1,order=7},copper_border={label="Copper Border",r=0.722,g=0.451,b=0.200,a=1,order=8}}),
    apply=function(self)
        local mr,mg,mb,ma=col("winMail","main"); local br,bg2,bb,ba=col("winMail","background")
        local ir,ig,ib,ia=col("winMail","borders"); local cr,cg,cb,ca=col("winMail","controls")
        local tr,tg,tb,ta=col("winMail","tabs"); local gr,gg,gb,ga=col("winMail","gold_border")
        local sr,sg,sb,sa=col("winMail","silver_border"); local cor,cog,cob,coa=col("winMail","copper_border")
        for _,f in pairs({MailFrame,OpenMailFrame}) do SkinNS(f,mr,mg,mb,ma) end
        T(OpenMailHorizontalBarLeft,mr,mg,mb,ma); T(SendMailHorizontalBarLeft,mr,mg,mb,ma)
        for _,f in pairs({SendMailFrame,OpenMailFrame}) do
            for _,v in pairs({f:GetRegions()}) do
                if v:IsObjectType("Texture") and v:GetDebugName():match("%d") then T(v,mr,mg,mb,ma) end
            end
        end
        T(MailFrameBg,br,bg2,bb,ba); T(OpenMailFrameBg,br,bg2,bb,ba)
        for _,f in pairs({MailFrameInset,OpenMailFrameInset,SendMailMoneyInset}) do SkinNS(f,ir,ig,ib,ia) end
        for _,tex in pairs({SendMailNameEditBoxLeft,SendMailNameEditBoxMiddle,SendMailNameEditBoxRight,SendMailSubjectEditBoxLeft,SendMailSubjectEditBoxMiddle,SendMailSubjectEditBoxRight,SendMailMoneyBgLeft,SendMailMoneyBgMiddle,SendMailMoneyBgRight}) do T(tex,ir,ig,ib,ia) end
        for _,tex in pairs({SendMailMoneyGoldLeft,SendMailMoneyGoldMiddle,SendMailMoneyGoldRight}) do T(tex,gr,gg,gb,ga) end
        for _,tex in pairs({SendMailMoneySilverLeft,SendMailMoneySilverMiddle,SendMailMoneySilverRight}) do T(tex,sr,sg,sb,sa) end
        for _,tex in pairs({SendMailMoneyCopperLeft,SendMailMoneyCopperMiddle,SendMailMoneyCopperRight}) do T(tex,cor,cog,cob,coa) end
        SkinScrollBar(OpenMailScrollFrame,cr,cg,cb,ca); SkinScrollBar(SendMailScrollFrame,cr,cg,cb,ca)
        for _,tab in pairs({MailFrameTab1,MailFrameTab2}) do SkinTabs(tab,tr,tg,tb,ta) end
    end,
    remove=function(self)
        for _,f in pairs({MailFrame,OpenMailFrame}) do RestoreNS(f) end
        R(MailFrameBg); R(OpenMailFrameBg)
        for _,f in pairs({MailFrameInset,OpenMailFrameInset,SendMailMoneyInset}) do RestoreNS(f) end
        for _,tab in pairs({MailFrameTab1,MailFrameTab2}) do SkinTabs(tab,1,1,1,1) end
    end,
})

-- ========================================================
-- Merchant Frame
-- ========================================================
C:Register("winMerchant", {
    label="Merchant", group="Windows", colors=wc(),
    apply=function(self)
        local mr,mg,mb,ma=col("winMerchant","main"); local br,bg2,bb,ba=col("winMerchant","background")
        local ir,ig,ib,ia=col("winMerchant","borders"); local cr,cg,cb,ca=col("winMerchant","controls")
        local tr,tg,tb,ta=col("winMerchant","tabs")
        SkinNS(MerchantFrame,mr,mg,mb,ma)
        T(MerchantFrameBg,br,bg2,bb,ba); T(MerchantMoneyInset and MerchantMoneyInset.Bg,br,bg2,bb,ba)
        for _,f in pairs({MerchantFrameInset,MerchantMoneyInset}) do SkinNS(f,ir,ig,ib,ia) end
        for _,tex in pairs({MerchantFrameBottomRightBorder,MerchantFrameBottomLeftBorder,MerchantMoneyBgLeft,MerchantMoneyBgMiddle,MerchantMoneyBgRight}) do T(tex,ir,ig,ib,ia) end
        T(MerchantFrame.FilterDropdown and MerchantFrame.FilterDropdown.Background,cr,cg,cb,ca)
        for _,tab in pairs({MerchantFrameTab1,MerchantFrameTab2}) do SkinTabs(tab,tr,tg,tb,ta) end
    end,
    remove=function(self)
        RestoreNS(MerchantFrame); R(MerchantFrameBg)
        for _,f in pairs({MerchantFrameInset,MerchantMoneyInset}) do RestoreNS(f) end
        for _,tab in pairs({MerchantFrameTab1,MerchantFrameTab2}) do SkinTabs(tab,1,1,1,1) end
    end,
})

-- ========================================================
-- Order Hall Mission
-- ========================================================
C:Register("winOrderHall", {
    label="Order Hall Missions", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3},corner_textures={label="Corner Textures",r=0.8,g=0.8,b=0.8,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_GarrisonUI", function()
            local mr,mg,mb,ma=col("winOrderHall","main"); local ir,ig,ib,ia=col("winOrderHall","borders")
            local cr,cg,cb,ca=col("winOrderHall","controls"); local er,eg,eb,ea=col("winOrderHall","corner_textures")
            for _,tex in pairs({OrderHallMissionFrame.Top,OrderHallMissionFrame.Right,OrderHallMissionFrame.Bottom,OrderHallMissionFrame.Left}) do T(tex,mr,mg,mb,ma) end
            for _,tex in pairs({OrderHallMissionFrame.TopBorder,OrderHallMissionFrame.TopRightCorner,OrderHallMissionFrame.RightBorder,OrderHallMissionFrame.BotRightCorner,OrderHallMissionFrame.BottomBorder,OrderHallMissionFrame.BotLeftCorner,OrderHallMissionFrame.LeftBorder}) do T(tex,ir,ig,ib,ia) end
            SkinScrollBar(AdventureMapQuestChoiceDialog and AdventureMapQuestChoiceDialog.Details,cr,cg,cb,ca)
            for _,tex in pairs({OrderHallMissionFrame.GarrCorners.TopRightGarrCorner,OrderHallMissionFrame.GarrCorners.BottomRightGarrCorner,OrderHallMissionFrame.GarrCorners.BottomLeftGarrCorner}) do T(tex,er,eg,eb,ea) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_GarrisonUI") then return end
    end,
})

-- ========================================================
-- PVE Frame
-- ========================================================
C:Register("winPVE", {
    label="Group Finder", group="Windows",
    colors=wc({filligree={label="Filigree Overlay",r=0,g=0,b=0,a=1,order=6}}),
    apply=function(self)
        local mr,mg,mb,ma=col("winPVE","main"); local br,bg2,bb,ba=col("winPVE","background")
        local ir,ig,ib,ia=col("winPVE","borders"); local cr,cg,cb,ca=col("winPVE","controls")
        local tr,tg,tb,ta=col("winPVE","tabs"); local fr,fg,fb,fa=col("winPVE","filligree")
        SkinNS(PVEFrame,mr,mg,mb,ma)
        for _,v in pairs({LFGListApplicationDialog,LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.AutoCompleteFrame}) do SkinSB(v,mr,mg,mb,ma) end
        for _,tex in pairs({PVEFrameBg,PVEFrameLeftInset and PVEFrameLeftInset.Bg,PVEFrame.TopTileStreaks}) do T(tex,br,bg2,bb,ba) end
        for _,f in pairs({PVEFrameLeftInset,LFDParentFrameInset,RaidFinderFrameRoleInset,RaidFinderFrameBottomInset,
            LFGListFrame.CategorySelection and LFGListFrame.CategorySelection.Inset,
            LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.ResultsInset,
            LFGListFrame.EntryCreation and LFGListFrame.EntryCreation.Inset,
            LFGListFrame.ApplicationViewer and LFGListFrame.ApplicationViewer.Inset}) do SkinNS(f,ir,ig,ib,ia) end
        for _,tex in pairs({LFDParentFrameRoleBackground,PVEFrameBRCorner,PVEFrameTRCorner,PVEFrameBLCorner,PVEFrameTLCorner,PVEFrameBottomLine,PVEFrameLLVert,PVEFrameRLVert,PVEFrameTopLine,LFGListFrame.ApplicationViewer and LFGListFrame.ApplicationViewer.InfoBackground}) do T(tex,ir,ig,ib,ia) end
        if RaidFinderFrameRoleBackground then RaidFinderFrameRoleBackground:Hide() end
        for _,v in pairs({LFGListApplicationDialogDescription,LFGListCreationDescription}) do SkinSB(v,ir,ig,ib,ia) end
        T(LFDQueueFrameTypeDropdown and LFDQueueFrameTypeDropdown.Background,cr,cg,cb,ca)
        T(RaidFinderQueueFrameSelectionDropdown and RaidFinderQueueFrameSelectionDropdown.Background,cr,cg,cb,ca)
        T(LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.FilterButton and LFGListFrame.SearchPanel.FilterButton.Background,cr,cg,cb,ca)
        SkinBox(LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.SearchBox,cr,cg,cb,ca)
        SkinBox(LFGListFrame.EntryCreation and LFGListFrame.EntryCreation.Name,cr,cg,cb,ca)
        for _,f in pairs({LFGListFrame.SearchPanel,LFGListFrame.ApplicationViewer}) do SkinScrollBar(f,cr,cg,cb,ca) end
        for _,tab in pairs({PVEFrameTab1,PVEFrameTab2,PVEFrameTab3,PVEFrameTab4}) do SkinTabs(tab,tr,tg,tb,ta) end
        for _,tex in pairs({PVEFrameTopFiligree,PVEFrameBottomFiligree}) do T(tex,fr,fg,fb,fa) end
        WL("Blizzard_PVPUI", function()
            for _,f in pairs({HonorFrame and HonorFrame.Inset,ConquestFrame and ConquestFrame.Inset,PVPQueueFrame and PVPQueueFrame.HonorInset}) do SkinNS(f,ir,ig,ib,ia) end
            T(HonorFrameTypeDropdown and HonorFrameTypeDropdown.Background,cr,cg,cb,ca)
        end)
        WL("Blizzard_ChallengesUI", function()
            SkinNS(ChallengesFrameInset,ir,ig,ib,ia)
        end)
    end,
    remove=function(self)
        RestoreNS(PVEFrame); R(PVEFrameBg)
        if RaidFinderFrameRoleBackground then RaidFinderFrameRoleBackground:Show() end
        for _,tab in pairs({PVEFrameTab1,PVEFrameTab2,PVEFrameTab3,PVEFrameTab4}) do SkinTabs(tab,1,1,1,1) end
    end,
})

-- ========================================================
-- Player Spells Frame
-- ========================================================
C:Register("winSpellbook", {
    label="Talents & Spellbook", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3},tabs={label="Tabs",r=DT.r,g=DT.g,b=DT.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_PlayerSpells", function()
            local mr,mg,mb,ma=col("winSpellbook","main"); local br,bg2,bb,ba=col("winSpellbook","background")
            local cr,cg,cb,ca=col("winSpellbook","controls"); local tr,tg,tb,ta=col("winSpellbook","tabs")
            for _,f in pairs({PlayerSpellsFrame,HeroTalentsSelectionDialog}) do SkinNS(f,mr,mg,mb,ma) end
            for _,f in pairs({ClassTalentLoadoutImportDialog,ClassTalentLoadoutEditDialog,ClassTalentLoadoutCreateDialog}) do SkinSB(f,mr,mg,mb,ma) end
            for _,tex in pairs({PlayerSpellsFrameBg,PlayerSpellsFrame.SpecFrame and PlayerSpellsFrame.SpecFrame.BlackBG,PlayerSpellsFrame.SpecFrame and PlayerSpellsFrame.SpecFrame.Background,PlayerSpellsFrame.TalentsFrame and PlayerSpellsFrame.TalentsFrame.BottomBar}) do T(tex,br,bg2,bb,ba) end
            T(PlayerSpellsFrame.TalentsFrame and PlayerSpellsFrame.TalentsFrame.LoadSystem and PlayerSpellsFrame.TalentsFrame.LoadSystem.Dropdown and PlayerSpellsFrame.TalentsFrame.LoadSystem.Dropdown.Background,cr,cg,cb,ca)
            for _,box in pairs({PlayerSpellsFrame.TalentsFrame and PlayerSpellsFrame.TalentsFrame.SearchBox,PlayerSpellsFrame.SpellBookFrame and PlayerSpellsFrame.SpellBookFrame.SearchBox}) do SkinBox(box,cr,cg,cb,ca) end
            for _,tabSystem in pairs({PlayerSpellsFrame.TabSystem,PlayerSpellsFrame.SpellBookFrame and PlayerSpellsFrame.SpellBookFrame.CategoryTabSystem}) do
                if tabSystem then
                    for _,tab in pairs({tabSystem:GetChildren()}) do T(tab.Left,tr,tg,tb,ta); T(tab.Middle,tr,tg,tb,ta); T(tab.Right,tr,tg,tb,ta) end
                end
            end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_PlayerSpells") then return end
        RestoreNS(PlayerSpellsFrame); R(PlayerSpellsFrameBg)
    end,
})

-- ========================================================
-- Professions Book
-- ========================================================
C:Register("winProfessionsBook", {
    label="Profession Book", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3}},
    apply=function(self)
        WL("Blizzard_ProfessionsBook", function()
            local mr,mg,mb,ma=col("winProfessionsBook","main"); local br,bg2,bb,ba=col("winProfessionsBook","background")
            local ir,ig,ib,ia=col("winProfessionsBook","borders")
            SkinNS(ProfessionsBookFrame,mr,mg,mb,ma); T(ProfessionsBookFrameBg,br,bg2,bb,ba)
            SkinNS(ProfessionsBookFrameInset,ir,ig,ib,ia)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ProfessionsBook") then return end
        RestoreNS(ProfessionsBookFrame); R(ProfessionsBookFrameBg); RestoreNS(ProfessionsBookFrameInset)
    end,
})

-- ========================================================
-- Professions Customer Orders
-- ========================================================
C:Register("winCraftingOrders", {
    label="Crafting Orders", group="Windows",
    colors=wc({gold_border={label="Gold Border",r=1.0,g=0.843,b=0.0,a=1,order=6},silver_border={label="Silver Border",r=0.753,g=0.753,b=0.753,a=1,order=7}}),
    apply=function(self)
        WL("Blizzard_ProfessionsCustomerOrders", function()
            local mr,mg,mb,ma=col("winCraftingOrders","main"); local br,bg2,bb,ba=col("winCraftingOrders","background")
            local ir,ig,ib,ia=col("winCraftingOrders","borders"); local cr,cg,cb,ca=col("winCraftingOrders","controls")
            local tr,tg,tb,ta=col("winCraftingOrders","tabs")
            for _,f in pairs({ProfessionsCustomerOrdersFrame,ProfessionsCustomerOrdersFrame.MoneyFrameInset}) do SkinNS(f,mr,mg,mb,ma) end
            T(ProfessionsCustomerOrdersFrameBg,br,bg2,bb,ba)
            for _,f in pairs({ProfessionsCustomerOrdersFrame.BrowseOrders and ProfessionsCustomerOrdersFrame.BrowseOrders.CategoryList,ProfessionsCustomerOrdersFrame.BrowseOrders and ProfessionsCustomerOrdersFrame.BrowseOrders.RecipeList,ProfessionsCustomerOrdersFrame.Form and ProfessionsCustomerOrdersFrame.Form.CurrentListings and ProfessionsCustomerOrdersFrame.Form.CurrentListings.OrderList,ProfessionsCustomerOrdersFrame.MyOrdersPage and ProfessionsCustomerOrdersFrame.MyOrdersPage.OrderList}) do SkinNS(f,ir,ig,ib,ia) end
            for _,tab in pairs({ProfessionsCustomerOrdersFrameBrowseTab,ProfessionsCustomerOrdersFrameOrdersTab}) do SkinTabs(tab,tr,tg,tb,ta) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ProfessionsCustomerOrders") then return end
        RestoreNS(ProfessionsCustomerOrdersFrame); R(ProfessionsCustomerOrdersFrameBg)
    end,
})

-- ========================================================
-- Professions Frame
-- ========================================================
C:Register("winProfessions", {
    label="Professions", group="Windows", colors=wc(),
    apply=function(self)
        WL("Blizzard_Professions", function()
            local mr,mg,mb,ma=col("winProfessions","main"); local br,bg2,bb,ba=col("winProfessions","background")
            local ir,ig,ib,ia=col("winProfessions","borders"); local cr,cg,cb,ca=col("winProfessions","controls")
            local tr,tg,tb,ta=col("winProfessions","tabs")
            for _,f in pairs({ProfessionsFrame,ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm and ProfessionsFrame.CraftingPage.SchematicForm.QualityDialog}) do SkinNS(f,mr,mg,mb,ma) end
            T(ProfessionsFrameBg,br,bg2,bb,ba)
            for _,f in pairs({ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm,ProfessionsFrame.OrdersPage and ProfessionsFrame.OrdersPage.BrowseFrame and ProfessionsFrame.OrdersPage.BrowseFrame.OrderList}) do SkinNS(f,ir,ig,ib,ia) end
            SkinTabs(ProfessionsFrame,tr,tg,tb,ta)
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_Professions") then return end
        RestoreNS(ProfessionsFrame); R(ProfessionsFrameBg)
    end,
})

-- ========================================================
-- Quest Frame
-- ========================================================
C:Register("winQuest", {
    label="Quest", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        local mr,mg,mb,ma=col("winQuest","main"); local br,bg2,bb,ba=col("winQuest","background")
        local ir,ig,ib,ia=col("winQuest","borders"); local cr,cg,cb,ca=col("winQuest","controls")
        SkinNS(QuestFrame,mr,mg,mb,ma)
        -- QuestModelScene only when present (not always loaded)
        if QuestModelScene then
            T(QuestModelScene.TopBarBg,mr,mg,mb,ma)
            T(QuestModelScene.Border,mr,mg,mb,ma)
            T(QuestModelScene.ModelNameDivider,mr,mg,mb,ma)
            T(QuestModelScene.ModelNameBackground,mr,mg,mb,ma)
        end
        T(QuestFrameBg,br,bg2,bb,ba)
        SkinNS(QuestFrameInset,ir,ig,ib,ia)
        -- ScrollBars: QuestFrame itself has a ScrollBar since 12.0.1
        SkinScrollBar(QuestFrame,cr,cg,cb,ca)
        SkinScrollBar(QuestDetailScrollFrame,cr,cg,cb,ca)
        SkinScrollBar(QuestNPCModelTextScrollFrame,cr,cg,cb,ca)
        -- Hook to preserve tinting when the frame opens
        if not C._questHooked then
            C._questHooked = true
            hooksecurefunc("QuestFrameGreetingPanel_Show", function()
                SkinNS(QuestFrame,col("winQuest","main"))
            end)
        end
    end,
    remove=function(self)
        RestoreNS(QuestFrame); R(QuestFrameBg); RestoreNS(QuestFrameInset)
        RestoreScrollBar(QuestFrame)
    end,
})

-- ========================================================
-- Ready Check
-- ========================================================
C:Register("winReadyCheck", {
    label="Ready Check", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1}},
    apply=function(self)
        local mr,mg,mb,ma=col("winReadyCheck","main")
        SkinNS(ReadyCheckListenerFrame,mr,mg,mb,ma)
    end,
    remove=function(self) RestoreNS(ReadyCheckListenerFrame) end,
})

-- ========================================================
-- Scrapping Machine
-- ========================================================
C:Register("winScrap", {
    label="Scrapping Machine", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=4}},
    apply=function(self)
        WL("Blizzard_ScrappingMachineUI", function()
            local mr,mg,mb,ma=col("winScrap","main"); local br,bg2,bb,ba=col("winScrap","background")
            local ir,ig,ib,ia=col("winScrap","borders"); local cr,cg,cb,ca=col("winScrap","controls")
            SkinNS(ScrappingMachineFrame,mr,mg,mb,ma); T(ScrappingMachineFrameBg,br,bg2,bb,ba)
            SkinNS(ScrappingMachineFrameInset,ir,ig,ib,ia)
            for _,v in pairs({ScrappingMachineFrame.ItemSlots:GetRegions()}) do
                if v:IsObjectType("Texture") then T(v,cr,cg,cb,ca) end
            end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_ScrappingMachineUI") then return end
        RestoreNS(ScrappingMachineFrame); R(ScrappingMachineFrameBg); RestoreNS(ScrappingMachineFrameInset)
    end,
})

-- ========================================================
-- Settings Panel
-- ========================================================
C:Register("winSettings", {
    label="Settings", group="Windows", colors=wc(),
    apply=function(self)
        local mr,mg,mb,ma=col("winSettings","main"); local br,bg2,bb,ba=col("winSettings","background")
        local ir,ig,ib,ia=col("winSettings","borders"); local cr,cg,cb,ca=col("winSettings","controls")
        local tr,tg,tb,ta=col("winSettings","tabs")
        for _,f in pairs({SettingsPanel,PingSystemTutorial}) do SkinNS(f,mr,mg,mb,ma) end
        SkinSB(QuickKeybindFrame and QuickKeybindFrame.BG,mr,mg,mb,ma)
        T(QuickKeybindFrame and QuickKeybindFrame.Header and QuickKeybindFrame.Header.LeftBG,mr,mg,mb,ma)
        T(QuickKeybindFrame and QuickKeybindFrame.Header and QuickKeybindFrame.Header.CenterBG,mr,mg,mb,ma)
        T(QuickKeybindFrame and QuickKeybindFrame.Header and QuickKeybindFrame.Header.RightBG,mr,mg,mb,ma)
        for _,tex in pairs({SettingsPanel.Bg.TopSection,SettingsPanel.Bg.BottomEdge,PingSystemTutorialBg}) do T(tex,br,bg2,bb,ba) end
        SettingsPanel.Bg.BottomRight:SetColorTexture(br,bg2,bb,ba)
        SettingsPanel.Bg.BottomLeft:SetColorTexture(br,bg2,bb,ba)
        SkinNS(PingSystemTutorialInset,ir,ig,ib,ia)
        for _,v in pairs({SettingsPanel:GetRegions()}) do if v:IsObjectType("Texture") then T(v,ir,ig,ib,ia) end end
        SkinBox(SettingsPanel.SearchBox,cr,cg,cb,ca)
        SkinScrollBar(SettingsPanel.Container and SettingsPanel.Container.SettingsList,cr,cg,cb,ca)
        for _,tab in pairs({SettingsPanel.GameTab,SettingsPanel.AddOnsTab}) do SkinTabs(tab,tr,tg,tb,ta) end
    end,
    remove=function(self)
        RestoreNS(SettingsPanel); RestoreNS(PingSystemTutorial)
        R(SettingsPanel.Bg.TopSection); R(SettingsPanel.Bg.BottomEdge)
    end,
})

-- ========================================================
-- Stable Frame
-- ========================================================
C:Register("winStable", {
    label="Stable", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3}},
    apply=function(self)
        local mr,mg,mb,ma=col("winStable","main"); local ir,ig,ib,ia=col("winStable","borders")
        local cr,cg,cb,ca=col("winStable","controls")
        SkinNS(StableFrame,mr,mg,mb,ma)
        for _,f in pairs({StableFrame.StabledPetList and StableFrame.StabledPetList.Inset,StableFrame.PetModelScene and StableFrame.PetModelScene.Inset}) do SkinNS(f,ir,ig,ib,ia) end
        SkinSB(StableFrame.StabledPetList and StableFrame.StabledPetList.ListCounter,ir,ig,ib,ia)
        T(StableFrame.StabledPetList and StableFrame.StabledPetList.FilterBar and StableFrame.StabledPetList.FilterBar.FilterDropdown and StableFrame.StabledPetList.FilterBar.FilterDropdown.Background,cr,cg,cb,ca)
        SkinBox(StableFrame.StabledPetList and StableFrame.StabledPetList.FilterBar and StableFrame.StabledPetList.FilterBar.SearchBox,cr,cg,cb,ca)
        SkinScrollBar(StableFrame.StabledPetList,cr,cg,cb,ca)
    end,
    remove=function(self) RestoreNS(StableFrame) end,
})

-- ========================================================
-- Stopwatch
-- ========================================================
C:Register("winStopwatch", {
    label="Stopwatch", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1}},
    apply=function(self)
        WL("Blizzard_TimeManager", function()
            local mr,mg,mb,ma=col("winStopwatch","main")
            for _,v in pairs({StopwatchFrame:GetRegions()}) do
                if v:IsObjectType("Texture") then T(v,mr,mg,mb,ma) end
            end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_TimeManager") then return end
        for _,v in pairs({StopwatchFrame:GetRegions()}) do if v:IsObjectType("Texture") then R(v) end end
    end,
})

-- ========================================================
-- Trade Frame
-- ========================================================
C:Register("winTrade", {
    label="Trade", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},borders={label="Borders",r=DR.r,g=DR.g,b=DR.b,a=1,order=3}},
    toggles={follow_unit_class={label="Recipient Background by Class",default=true}},
    apply=function(self)
        local mr,mg,mb,ma=col("winTrade","main"); local br,bg2,bb,ba=col("winTrade","background")
        local ir,ig,ib,ia=col("winTrade","borders")
        SkinNS(TradeFrame,mr,mg,mb,ma)
        T(TradeFrame.RecipientOverlay and TradeFrame.RecipientOverlay.portraitFrame,mr,mg,mb,ma)
        T(TradeRecipientLeftBorder,mr,mg,mb,ma); T(TradeRecipientBotLeftCorner,mr,mg,mb,ma)
        T(TradeFrameBg,br,bg2,bb,ba); T(TradeRecipientBG,br,bg2,bb,ba)
        if C:GetToggle("winTrade","follow_unit_class") then
            local cc=C.GetUnitClassColor("NPC")
            if cc then T(TradeRecipientBG,cc.r,cc.g,cc.b) end
        end
        for _,f in pairs({TradeFrameInset,TradePlayerItemsInset,TradePlayerEnchantInset,TradePlayerInputMoneyInset,TradeRecipientItemsInset,TradeRecipientEnchantInset,TradeRecipientMoneyInset}) do SkinNS(f,ir,ig,ib,ia) end
    end,
    remove=function(self)
        RestoreNS(TradeFrame); R(TradeFrameBg); R(TradeRecipientBG)
        for _,f in pairs({TradeFrameInset,TradePlayerItemsInset,TradePlayerEnchantInset,TradePlayerInputMoneyInset}) do RestoreNS(f) end
    end,
})

-- ========================================================
-- Transmog Frame
-- ========================================================
C:Register("winTransmog", {
    label="Transmogrification", group="Windows", colors=wc(),
    apply=function(self)
        WL("Blizzard_Transmog", function()
            local mr,mg,mb,ma=col("winTransmog","main"); local br,bg2,bb,ba=col("winTransmog","background")
            local ir,ig,ib,ia=col("winTransmog","borders"); local cr,cg,cb,ca=col("winTransmog","controls")
            local tr,tg,tb,ta=col("winTransmog","tabs")
            SkinNS(TransmogFrame,mr,mg,mb,ma); T(TransmogFrameBg,br,bg2,bb,ba)
            T(TransmogFrame.WardrobeCollection and TransmogFrame.WardrobeCollection.TabContent and TransmogFrame.WardrobeCollection.TabContent.Border,ir,ig,ib,ia)
            SkinScrollBar(TransmogFrame.OutfitCollection and TransmogFrame.OutfitCollection.OutfitList,cr,cg,cb,ca)
            for _,tab in pairs({TransmogFrame.WardrobeCollection and TransmogFrame.WardrobeCollection.TabHeaders and TransmogFrame.WardrobeCollection.TabHeaders:GetChildren() or {}}) do
                T(tab.Left,tr,tg,tb,ta); T(tab.Middle,tr,tg,tb,ta); T(tab.Right,tr,tg,tb,ta)
            end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_Transmog") then return end
        RestoreNS(TransmogFrame); R(TransmogFrameBg)
    end,
})

-- ========================================================
-- World Map Frame
-- ========================================================
C:Register("winMap", {
    label="World Map & Quest Log", group="Windows", colors=wc(),
    apply=function(self)
        local mr,mg,mb,ma=col("winMap","main"); local br,bg2,bb,ba=col("winMap","background")
        local ir,ig,ib,ia=col("winMap","borders"); local cr,cg,cb,ca=col("winMap","controls")
        local tr,tg,tb,ta=col("winMap","tabs")
        SkinNS(WorldMapFrame.BorderFrame,mr,mg,mb,ma)
        for _,v in pairs({QuestMapFrame.QuestsFrame.DetailsFrame.ShareButton:GetRegions()}) do
            if v:IsObjectType("Texture") and v:GetDebugName():match("%d") then T(v,mr,mg,mb,ma) end
        end
        T(WorldMapFrameBg,br,bg2,bb,ba)
        for _,tex in pairs({WorldMapFrame.NavBar:GetRegions()}) do T(tex,ir,ig,ib,ia) end
        for _,tex in pairs({WorldMapFrame.NavBar.overlay:GetRegions()}) do T(tex,ir,ig,ib,ia) end
        for _,f in pairs({QuestScrollFrame,QuestMapFrame.EventsFrame,MapLegendScrollFrame,QuestMapDetailsScrollFrame}) do SkinScrollBar(f,cr,cg,cb,ca) end
        SkinBox(QuestScrollFrame and QuestScrollFrame.SearchBox,cr,cg,cb,ca)
        T(QuestMapFrame.QuestsTab and QuestMapFrame.QuestsTab.Background,tr,tg,tb,ta)
        T(QuestMapFrame.EventsTab and QuestMapFrame.EventsTab.Background,tr,tg,tb,ta)
        T(QuestMapFrame.MapLegendTab and QuestMapFrame.MapLegendTab.Background,tr,tg,tb,ta)
    end,
    remove=function(self) RestoreNS(WorldMapFrame.BorderFrame); R(WorldMapFrameBg) end,
})

-- ========================================================
-- Bags (Container Frame)
-- ========================================================
C:Register("winBags", {
    label="Bags", group="Windows",
    colors={main={label="Main",r=DM.r,g=DM.g,b=DM.b,a=1,order=1},background={label="Background",r=DG.r,g=DG.g,b=DG.b,a=1,order=2},controls={label="Controls",r=DC.r,g=DC.g,b=DC.b,a=1,order=3}},
    apply=function(self)
        local mr,mg,mb,ma=col("winBags","main"); local br,bg2,bb,ba=col("winBags","background")
        local cr,cg,cb,ca=col("winBags","controls")
        SkinNS(ContainerFrameCombinedBags,mr,mg,mb,ma)
        ContainerFrameCombinedBags.Bg.TopSection:SetDesaturation(1); ContainerFrameCombinedBags.Bg.TopSection:SetVertexColor(br,bg2,bb,ba)
        ContainerFrameCombinedBags.Bg.BottomEdge:SetDesaturation(1); ContainerFrameCombinedBags.Bg.BottomEdge:SetVertexColor(br,bg2,bb,ba)
        ContainerFrameCombinedBags.Bg.BottomLeft:SetColorTexture(br,bg2,bb,ba)
        ContainerFrameCombinedBags.Bg.BottomRight:SetColorTexture(br,bg2,bb,ba)
        T(ContainerFrameCombinedBags.MoneyFrame and ContainerFrameCombinedBags.MoneyFrame.Border and ContainerFrameCombinedBags.MoneyFrame.Border.Left,cr,cg,cb,ca)
        T(ContainerFrameCombinedBags.MoneyFrame and ContainerFrameCombinedBags.MoneyFrame.Border and ContainerFrameCombinedBags.MoneyFrame.Border.Middle,cr,cg,cb,ca)
        T(ContainerFrameCombinedBags.MoneyFrame and ContainerFrameCombinedBags.MoneyFrame.Border and ContainerFrameCombinedBags.MoneyFrame.Border.Right,cr,cg,cb,ca)
        T(BagItemSearchBox and BagItemSearchBox.Left,cr,cg,cb,ca); T(BagItemSearchBox and BagItemSearchBox.Middle,cr,cg,cb,ca); T(BagItemSearchBox and BagItemSearchBox.Right,cr,cg,cb,ca)
        for bag_num=1,6 do
            local container=_G["ContainerFrame"..bag_num]
            if container then
                SkinNS(container,mr,mg,mb,ma)
                container.Bg.TopSection:SetDesaturation(1); container.Bg.TopSection:SetVertexColor(br,bg2,bb,ba)
                container.Bg.BottomEdge:SetDesaturation(1); container.Bg.BottomEdge:SetVertexColor(br,bg2,bb,ba)
                container.Bg.BottomLeft:SetColorTexture(br,bg2,bb,ba)
                container.Bg.BottomRight:SetColorTexture(br,bg2,bb,ba)
            end
        end
    end,
    remove=function(self)
        RestoreNS(ContainerFrameCombinedBags)
        for bag_num=1,6 do RestoreNS(_G["ContainerFrame"..bag_num]) end
    end,
})

-- ========================================================
-- Communities Frame
-- ========================================================
C:Register("winCommunities", {
    label="Communities", group="Windows",
    colors=wc({filligree={label="Filigree",r=1,g=1,b=1,a=1,order=6}}),
    apply=function(self)
        WL("Blizzard_Communities", function()
            local mr,mg,mb,ma=col("winCommunities","main"); local br,bg2,bb,ba=col("winCommunities","background")
            local ir,ig,ib,ia=col("winCommunities","borders"); local cr,cg,cb,ca=col("winCommunities","controls")
            local tr,tg,tb,ta=col("winCommunities","tabs"); local fr,fg,fb,fa=col("winCommunities","filligree")
            SkinNS(CommunitiesFrame,mr,mg,mb,ma)
            T(CommunitiesFrameBg,br,bg2,bb,ba)
            for _,f in pairs({CommunitiesFrameInset,CommunitiesFrame.MemberList and CommunitiesFrame.MemberList.InsetFrame,CommunitiesFrame.Chat and CommunitiesFrame.Chat.InsetFrame,CommunitiesFrameCommunitiesList and CommunitiesFrameCommunitiesList.InsetFrame}) do SkinNS(f,ir,ig,ib,ia) end
            for _,f in pairs({CommunitiesFrameCommunitiesList,CommunitiesFrame.Chat,CommunitiesFrame.MemberList}) do SkinScrollBar(f,cr,cg,cb,ca) end
            T(CommunitiesFrame.ChatEditBox and CommunitiesFrame.ChatEditBox.Left,cr,cg,cb,ca)
            T(CommunitiesFrame.ChatEditBox and CommunitiesFrame.ChatEditBox.Mid,cr,cg,cb,ca)
            T(CommunitiesFrame.ChatEditBox and CommunitiesFrame.ChatEditBox.Right,cr,cg,cb,ca)
            T(CommunitiesFrame.StreamDropdown and CommunitiesFrame.StreamDropdown.Background,cr,cg,cb,ca)
            for _,tex in pairs({CommunitiesFrameCommunitiesList.TopFiligree,CommunitiesFrameCommunitiesList.BottomFiligree}) do T(tex,fr,fg,fb,fa) end
        end)
    end,
    remove=function(self)
        if not C_AddOns.IsAddOnLoaded("Blizzard_Communities") then return end
        RestoreNS(CommunitiesFrame); R(CommunitiesFrameBg)
    end,
})


-- ========================================================
-- AklimeMod itself (color own window)
-- ========================================================
C:Register("winAklimeMod", {
    label  = "Aklime Mod Tools",
    group  = "Addons",
    colors = {
        main       = { label="Frame",          r=DM.r, g=DM.g,  b=DM.b,  a=1,   order=1 },
        -- Default #1D1D1D, dark tint of the stone texture
        background = { label="Background",     r=0.114, g=0.114, b=0.114, a=1,  order=2 },
        borders    = { label="Inset Borders",  r=DR.r, g=DR.g,  b=DR.b,  a=1,   order=3 },
        -- Defaults match AklimeMod_Theme (rowBg, rowBorder, line, selection)
        boxBg      = { label="Box Background", r=0.08, g=0.075, b=0.06,  a=1,   order=4 },
        boxBorder  = { label="Box Borders",    r=0.50, g=0.40,  b=0.12,  a=0.7, order=5 },
        lines      = { label="Lines",          r=0.85, g=0.68,  b=0.15,  a=0.6, order=6 },
        selection  = { label="Selection",      r=0.74, g=0.56,  b=0.12,  a=1,   order=7 },
        ring       = { label="Portrait Ring",  r=1,    g=0.82,  b=0,     a=1,   order=8 },
        controls   = { label="Controls",       r=DC.r, g=DC.g,  b=DC.b,  a=1,   order=9 },
    },
    apply = function(self)
        local mr,mg,mb,ma = col("winAklimeMod","main")
        local br,bg2,bb,ba = col("winAklimeMod","background")
        local ir,ig,ib,ia = col("winAklimeMod","borders")
        local cr,cg,cb,ca = col("winAklimeMod","controls")
        local frame = AklimeModFrame
        if not frame or not frame.SetBackdropBorderColor then return end
        -- Window: border (main) and background
        frame:SetBackdropBorderColor(mr,mg,mb,ma)
        frame:SetBackdropColor(br,bg2,bb,ba)
        -- Left and right panel: border color
        frame.leftInset:SetBackdropBorderColor(ir,ig,ib,ia)
        frame.rightInset:SetBackdropBorderColor(ir,ig,ib,ia)
        -- List boxes, dividers and category selection
        local g1r,g1g,g1b,g1a = col("winAklimeMod","boxBg")
        local g2r,g2g,g2b,g2a = col("winAklimeMod","boxBorder")
        local l1r,l1g,l1b,l1a = col("winAklimeMod","lines")
        local s1r,s1g,s1b,s1a = col("winAklimeMod","selection")
        AklimeMod_RowColors = {
            bg        = { r=g1r, g=g1g, b=g1b, a=g1a },
            border    = { r=g2r, g=g2g, b=g2b, a=g2a },
            line      = { r=l1r, g=l1g, b=l1b, a=l1a },
            selection = { r=s1r, g=s1g, b=s1b, a=s1a },
        }
        if AklimeMod_RefreshRowTheme then AklimeMod_RefreshRowTheme() end
        -- Portrait ring
        local rr,rg2,rb,ra = col("winAklimeMod","ring")
        if frame.portraitRing then
            frame.portraitRing:SetDesaturated(true)
            frame.portraitRing:SetVertexColor(rr,rg2,rb,ra)
        end
        -- Stone texture: tint follows the background color, multiplicative
        -- on the natural texture (white = untinted)
        if frame.bgTexture then
            frame.bgTexture:SetVertexColor(br,bg2,bb,ba)
        end
        -- Search box
        SkinBox(AklimeModSearchBox, cr,cg,cb,ca)
        -- Scroll bar of the right panel
        SkinScrollBar(frame.rightInset, cr,cg,cb,ca)
    end,
    remove = function(self)
        local frame = AklimeModFrame
        if not frame or not frame.SetBackdropBorderColor then return end
        -- Restore theme default colors
        local T = AklimeMod_Theme
        if T then
            frame:SetBackdropBorderColor(T.windowBorder.r, T.windowBorder.g, T.windowBorder.b, T.windowBorder.a)
            frame:SetBackdropColor(T.windowBg.r, T.windowBg.g, T.windowBg.b, T.windowBg.a)
            frame.leftInset:SetBackdropBorderColor(T.panelBorder.r, T.panelBorder.g, T.panelBorder.b, T.panelBorder.a)
            frame.rightInset:SetBackdropBorderColor(T.panelBorder.r, T.panelBorder.g, T.panelBorder.b, T.panelBorder.a)
            if frame.bgTexture then
                frame.bgTexture:SetVertexColor(T.windowTexTint.r, T.windowTexTint.g, T.windowTexTint.b, T.windowTexTint.a)
            end
        end
        if frame.portraitRing then
            frame.portraitRing:SetDesaturated(false)
            frame.portraitRing:SetVertexColor(1, 1, 1, 1)
        end
        AklimeMod_RowColors = nil
        if AklimeMod_RefreshRowTheme then AklimeMod_RefreshRowTheme() end
        RestoreBox(AklimeModSearchBox)
        RestoreScrollBar(frame.rightInset)
    end,
})

-- ========================================================
-- Elite Frame (colors the elite dragon on the player frame,
-- visible only when the elite frame module is active)
-- ========================================================
C:Register("eliteFrame", {
    label  = "Elite Frame",
    group  = "Addons",
    colors = {
        main = { label="Frame", r=DM.r, g=DM.g, b=DM.b, a=1, order=1 },
    },
    -- Actual tinting happens in AklimeMod_ApplyEliteFrame,
    -- which reads the skin state itself. Just re-apply here.
    apply = function(self)
        if AklimeMod_ApplyEliteFrame then AklimeMod_ApplyEliteFrame() end
    end,
    remove = function(self)
        if AklimeMod_ApplyEliteFrame then AklimeMod_ApplyEliteFrame() end
    end,
})

-- ========================================================
-- Group order
-- ========================================================
-- At position 1: Addons appear directly below "Enable all / Disable all"
table.insert(AklimeMod_Colorizer.groupOrder, 1, {
    label = "Addons",
    keys  = { "winAklimeMod", "eliteFrame" },
})

table.insert(AklimeMod_Colorizer.groupOrder, {
    label = "Windows",
    keys  = {
        "winAchieve","winAddonList","winAlliedRaces","winAH","winAzeriteRespec",
        "winBank","winCalendar","winChannel","winCharacter","winTrainer",
        "winClickBind","winCollections","winColorPicker","winCommunities",
        "winBags","winCooldownSettings","winDamageMeter","winDelves","winDelvesDiff",
        "winDressup","winEJ","winEventLog","winFlightMap","winFriends",
        "winGameMenu","winGossip","winGuildBank","winHousing","winHousingPreview",
        "winInspect","winIslandsQueue","winItemInteraction","winItemSocket",
        "winBook","winItemUpgrade","winLoot","winMacro","winMail","winMerchant",
        "winOrderHall","winPVE","winSpellbook","winProfessionsBook",
        "winCraftingOrders","winProfessions","winQuest","winReadyCheck",
        "winScrap","winSettings","winStable","winStopwatch","winTrade",
        "winTransmog","winMap",
    },
})