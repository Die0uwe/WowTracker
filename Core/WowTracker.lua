-- ============================================================================
-- DelveTracker — Core v17.0 (Slayer Alliance Edition)
-- Retail 12.0.5 / Build 67314 (Midnight)
-- Rebuilt: 2026-06-07
-- Changes v17.0:
--   [NEW] Breedte 760px (was 420px) — ruimer, professioneler
--   [NEW] Event ticker bovenaan — scrollende balk met live events + klok
--   [FIX] GetMoney() schrijft naar characters[key].money + PLAYER_MONEY event
--   [FIX] Slayer Alliance donker paars thema consistent
--   [FIX] Scaling via +/- knoppen — SCALE_STEP 0.05, traag genoeg
--   [FIX] Scrollbar Tab2 correct verankerd
--   [FIX] Tab3 PluginArea correct verankerd
--   [FIX] MenuUtil.CreateContextMenu (UIDropDownMenu weg in 12.x)
--   [FIX] UserInfo bovenaan plugin lijst (gepind)
--   [FIX] Positie murloc + main window opgeslagen in DB
-- ============================================================================
local addonName, addonTable = ...

-- Database
DelveTrackerDB          = DelveTrackerDB or {}
DelveTrackerDB.characters   = DelveTrackerDB.characters or {}
DelveTrackerDB.PluginStates = DelveTrackerDB.PluginStates or {}

-- Core API
DelveTracker = { Plugins = {}, Version = "2.7.0-12.0.5.67314" }
function DelveTracker:RegisterPlugin(name, func)
    self.Plugins[name] = func
end

-- Kleuren & font
local SA_GOLD   = "|cffccaa00"
local SA_PURPLE = "|cffa335ee"
local SA_BLUE   = "|cff00ccff"
local SA_GREY   = "|cff887799"
local C_2002    = "Fonts\\2002.ttf"

-- Layout
local UI_W       = 760
local UI_H       = 580
local TICKER_H   = 20
local HEADER_H   = 70
local TAB_BAR_H  = 28
local FOOTER_H   = 58
local SCALE_STEP = 0.05

-- ── MAIN FRAME ────────────────────────────────────────────────────────────
local UI = CreateFrame("Frame", "DelveTrackerFrame", UIParent, "BackdropTemplate")
UI:SetSize(UI_W, UI_H)
UI:SetPoint("CENTER")
UI:Hide()
UI:SetMovable(true)
UI:EnableMouse(true)
UI:RegisterForDrag("LeftButton")
UI:SetClampedToScreen(true)
UI:SetFrameStrata("MEDIUM")
UI:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
UI:SetBackdropColor(0.05, 0.03, 0.08, 0.97)
UI:SetBackdropBorderColor(0.35, 0.10, 0.55, 1)
UI:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then self:StartMoving() end
end)
UI:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local pt,_,rpt,x,y = self:GetPoint()
    DelveTrackerDB.mainPos = {pt=pt,rpt=rpt,x=x,y=y}
end)

-- Tabs
local Tab1 = CreateFrame("Frame","DT_Tab1",UI); Tab1:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab2 = CreateFrame("Frame","DT_Tab2",UI); Tab2:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab3 = CreateFrame("Frame","DT_Tab3",UI); Tab3:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab4 = CreateFrame("Frame","DT_Tab4",UI); Tab4:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab5 = CreateFrame("Frame","DT_Tab5",UI); Tab5:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab6 = CreateFrame("Frame","DT_Tab6",UI); Tab6:SetFrameLevel(UI:GetFrameLevel()+1)
local CONTENT_Y = -(TICKER_H + HEADER_H + TAB_BAR_H)
local CONTENT_BOT = FOOTER_H
for _,t in ipairs({Tab1,Tab2,Tab3,Tab4,Tab5,Tab6}) do
    t:SetPoint("TOPLEFT",UI,"TOPLEFT",1,CONTENT_Y)
    t:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-1,CONTENT_BOT)
    t:Hide()
end

-- ── EVENT TICKER ─────────────────────────────────────────────────────────
local TickerBG = UI:CreateTexture(nil,"BACKGROUND")
TickerBG:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-1)
TickerBG:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-1)
TickerBG:SetHeight(TICKER_H)
TickerBG:SetColorTexture(0.04,0.02,0.07,1)

local TickerLine = UI:CreateTexture(nil,"OVERLAY")
TickerLine:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-TICKER_H)
TickerLine:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-TICKER_H)
TickerLine:SetHeight(1)
TickerLine:SetColorTexture(0.45,0.10,0.70,0.8)

local TickerClock = UI:CreateFontString(nil,"OVERLAY")
TickerClock:SetFont(C_2002,10,"OUTLINE")
-- Verankerd aan de ticker achtergrond, niet aan UI hoogte midden
TickerClock:SetPoint("RIGHT",TickerBG,"RIGHT",-6,0)
TickerClock:SetTextColor(0.80,0.65,1.0,1)

local TickerClip = CreateFrame("Button",nil,UI)
TickerClip:SetPoint("TOPLEFT",UI,"TOPLEFT",4,-1)
TickerClip:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-78,-1)
TickerClip:SetHeight(TICKER_H)
TickerClip:SetClipsChildren(true)
-- Ticker instellingen in DB
DelveTrackerDB.tickerShow = DelveTrackerDB.tickerShow or {
    events=true, guild=true, prey=true, time=true,
}
-- Klik op ticker opent selectiemenu
TickerClip:SetScript("OnClick", function(self)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    local ts = DelveTrackerDB.tickerShow
    MenuUtil.CreateContextMenu(self, function(_, root)
        root:CreateTitle(SA_PURPLE.."Ticker inhoud|r")
        local function ToggleItem(key, label)
            local checked = ts[key] ~= false
            root:CreateCheckbox(label, function() return ts[key]~=false end,
                function() ts[key] = not (ts[key]~=false); tickerDirty=true end)
        end
        ToggleItem("events",  "World Events (actief + aankomend)")
        ToggleItem("prey",    "Prey Hunt status")
        ToggleItem("guild",   "Guild online teller")
        ToggleItem("time",    "Server tijd")
        root:CreateDivider()
        root:CreateButton("Alles aan", function()
            for k in pairs(ts) do ts[k]=true end; tickerDirty=true
        end)
        root:CreateButton("Alles uit", function()
            for k in pairs(ts) do ts[k]=false end; tickerDirty=true
        end)
    end)
end)

local TickerScroll = CreateFrame("Frame",nil,TickerClip)
TickerScroll:SetHeight(TICKER_H)
TickerScroll:SetWidth(6000)
TickerScroll:SetPoint("LEFT",TickerClip,"LEFT",0,0)

local TickerText = TickerScroll:CreateFontString(nil,"OVERLAY")
TickerText:SetFont(C_2002,10,"OUTLINE")
TickerText:SetPoint("LEFT",TickerScroll,"LEFT",0,0)
TickerText:SetJustifyH("LEFT")
TickerText:SetTextColor(0.75,0.55,1.0,1)

local tickerOffset=0; local tickerSpeed=38; local tickerWidth=0
local tickerClipW=0;  local tickerLastT=0;  local tickerDirty=true

local function FormatHMS(s)
    s=math.floor(s or 0)
    return string.format("%02d:%02d:%02d",math.floor(s/3600),math.floor((s%3600)/60),s%60)
end

local function BuildTickerStr()
    local ts = DelveTrackerDB and DelveTrackerDB.tickerShow or {}
    local parts = {}

    -- World Events
    if ts.events ~= false and addonTable and addonTable.DT_events then
        local ev = addonTable.DT_events:GetVisibleEvents()
        if ev then
            local list={}
            for _,e in pairs(ev) do table.insert(list,e) end
            table.sort(list,function(a,b)
                if a.isActive~=b.isActive then return a.isActive end
                return (a.timeRemaining or 0)<(b.timeRemaining or 0)
            end)
            for _,e in ipairs(list) do
                local t=FormatHMS(e.timeRemaining)
                if e.isActive then
                    table.insert(parts,"|cff44cc66⬤ "..e.name.."|r  "..SA_GREY.."ACTIEF · "..t.." rem|r")
                else
                    table.insert(parts,"|cffccaa00◎ "..e.name.."|r  "..SA_GREY.."over "..t.."|r")
                end
            end
        end
    end

    -- Prey Hunt status
    if ts.prey ~= false then
        local ok,qid = pcall(C_QuestLog.GetActivePreyQuest)
        if ok and qid and qid ~= 0 then
            local info = C_QuestLog.GetQuestInfo and C_QuestLog.GetQuestInfo(qid)
            local qname = info and info.title or ("Quest #"..qid)
            table.insert(parts,"|cffff4444🎯 Prey Hunt: "..qname.."|r")
        end
    end

    -- Guild online teller
    if ts.guild ~= false and IsInGuild() then
        local online = 0
        local total  = GetNumGuildMembers()
        for i=1,total do
            local _,_,_,_,_,_,_,_,connected = GetGuildRosterInfo(i)
            if connected then online = online + 1 end
        end
        table.insert(parts,"|cff00ff88👥 Guild online: "..online.."|r")
    end

    -- Server tijd
    if ts.time ~= false then
        local h,m = GetGameTime()
        table.insert(parts,SA_GOLD.."🕐 Server: "..string.format("%02d:%02d",h,m).."|r")
    end

    if #parts == 0 then
        return SA_GREY.."WowTracker v2.7.5 · Slayer Alliance · Midnight 12.0.5 · Klik ticker voor instellingen|r"
    end
    return table.concat(parts,"   |cff2a1040◆|r   ")
end

C_Timer.NewTicker(0.02,function()
    if not UI:IsShown() then return end
    local now=GetTime(); local dt=now-tickerLastT; tickerLastT=now
    -- Klok
    if math.floor(now)~=math.floor(now-dt) then
        TickerClock:SetText(string.format(SA_GOLD.."%s|r",date("%H:%M:%S")))
    end
    -- Tekst elke 5s
    if tickerDirty or (math.floor(now/5)~=math.floor((now-dt)/5)) then
        TickerText:SetText(BuildTickerStr())
        C_Timer.After(0.01,function()
            tickerWidth=TickerText:GetStringWidth()+60
            tickerClipW=TickerClip:GetWidth()
        end)
        tickerDirty=false
    end
    -- Scroll
    if tickerWidth>0 and tickerClipW>0 then
        tickerOffset=tickerOffset+tickerSpeed*0.02
        if tickerOffset>tickerWidth then tickerOffset=-tickerClipW end
        TickerScroll:SetPoint("LEFT",TickerClip,"LEFT",-tickerOffset,0)
    end
end)

-- ── HEADER ────────────────────────────────────────────────────────────────
local HdrBG = UI:CreateTexture(nil,"BACKGROUND")
HdrBG:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-TICKER_H)
HdrBG:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-TICKER_H)
HdrBG:SetHeight(HEADER_H)
HdrBG:SetColorTexture(0.08,0.04,0.12,1)

local HdrLine = UI:CreateTexture(nil,"OVERLAY")
HdrLine:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-(TICKER_H+HEADER_H))
HdrLine:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-(TICKER_H+HEADER_H))
HdrLine:SetHeight(1)
HdrLine:SetColorTexture(0.45,0.10,0.70,0.8)

UI.logo = UI:CreateTexture(nil,"OVERLAY")
UI.logo:SetSize(56,56)
UI.logo:SetPoint("TOPLEFT",UI,"TOPLEFT",10,-(TICKER_H+7))
UI.logo:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")

UI.title = UI:CreateFontString(nil,"OVERLAY")
UI.title:SetFont(C_2002,16,"OUTLINE")
UI.title:SetPoint("TOPLEFT",UI.logo,"TOPRIGHT",10,-2)
UI.title:SetText(SA_PURPLE.."SLAYER ALLIANCE|r")

UI.versionTxt = UI:CreateFontString(nil,"OVERLAY")
UI.versionTxt:SetFont(C_2002,9,"")
UI.versionTxt:SetPoint("TOPLEFT",UI.title,"BOTTOMLEFT",0,-3)
UI.versionTxt:SetText(SA_GREY.."DelveTracker v2.7.0 · Midnight 12.0.5|r")

UI.charInfo = UI:CreateFontString(nil,"OVERLAY")
UI.charInfo:SetFont(C_2002,11,"OUTLINE")
UI.charInfo:SetPoint("TOPLEFT",UI.versionTxt,"BOTTOMLEFT",0,-4)
UI.charInfo:SetPoint("RIGHT",UI,"RIGHT",-120,0)
UI.charInfo:SetJustifyH("LEFT")
UI.charInfo:SetText(SA_GREY.."Laden...|r")

UI.close = CreateFrame("Button",nil,UI,"UIPanelCloseButton")
UI.close:SetSize(22,22)
UI.close:SetPoint("TOPRIGHT",UI,"TOPRIGHT",2,-(TICKER_H+6))

UI.settingsBtn = CreateFrame("Button",nil,UI)
UI.settingsBtn:SetSize(22,22)
UI.settingsBtn:SetPoint("RIGHT",UI.close,"LEFT",-2,0)
UI.settingsBtn:SetSize(22,22)
UI.settingsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
UI.settingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")

-- ── TABS ──────────────────────────────────────────────────────────────────
local TAB_Y = -(TICKER_H+HEADER_H)
local tabBtns={}; local activeTabID=2

local tabDefs={
    {id=1,label="GUILD",   col=SA_GOLD},
    {id=2,label="DELVES",  col=SA_BLUE},
    {id=3,label="BOUNTY",  col=SA_PURPLE},
    {id=4,label="ROSTER",  col="|cff00ff88"},
    {id=5,label="ARMORY",  col="|cffff9900"},
    {id=6,label="CURRENCY",col="|cffccaa00"},
}
local TAB_W = math.floor((UI_W-2)/#tabDefs)

local function StyleTabBtn(btn,active)
    if active then
        btn:SetBackdropColor(0.12,0.05,0.20,1)
        btn:SetBackdropBorderColor(0.60,0.15,0.90,1)
        btn.glow:SetAlpha(1)
    else
        btn:SetBackdropColor(0.06,0.03,0.10,1)
        btn:SetBackdropBorderColor(0.20,0.05,0.30,0.7)
        btn.glow:SetAlpha(0)
    end
end

-- Forward declare alle tab-update functies (gedefinieerd later in het bestand)
local UpdateCharacterList
local WT_UpdateRoster
local WT_ShowArmory
local WT_UpdateCurrency
local WT_UpdateGuildOnline
local ScanDelves

local function ShowTab(id)
    UI:Show(); activeTabID=id
    Tab1:Hide(); Tab2:Hide(); Tab3:Hide(); Tab4:Hide(); Tab5:Hide(); Tab6:Hide()
    -- Verberg armory frame als Tab5 verlaten wordt
    local armFrame = _G["DT_ArmoryFrame"]
    if armFrame and Tab5.armoryEmbedded then armFrame:Hide() end

    if id==1 then
        Tab1:Show()
        if IsInGuild() then
            GuildRoster()
            local gName = GetGuildInfo("player")
            Tab1.guildName:SetText(SA_GOLD..(gName or "Slayer Alliance").."|r")
            local motd = GetGuildRosterMOTD() or ""
            Tab1.motdText:SetText(motd~="" and (SA_GREY..motd.."|r") or SA_GREY.."Laden...|r")
        else
            Tab1.guildName:SetText(SA_GREY.."Geen guild|r")
            Tab1.motdText:SetText(SA_GREY.."Geen guild lid.|r")
        end
        WT_UpdateGuildOnline()

    elseif id==2 then
        Tab2:Show()
        if UpdateCharacterList then UpdateCharacterList() end

    elseif id==3 then
        Tab3:Show()
        Tab3.PluginArea:Show()
        -- QuickSet: geef volledige Tab3 breedte mee
        -- QuickSet bouwt tiles in een scrollframe — het vult de breedte van de container
        if not Tab3.quickWrap then
            Tab3.quickWrap = CreateFrame("Frame",nil,Tab3.PluginArea)
            Tab3.quickWrap:SetPoint("TOPLEFT",Tab3.PluginArea,"TOPLEFT",0,0)
            Tab3.quickWrap:SetPoint("BOTTOMRIGHT",Tab3.PluginArea,"BOTTOMRIGHT",0,0)
        end
        if Tab3.quickWrap._dtBuilt == nil then
            local qpF = DelveTracker.Plugins["QuickSet"]
            if qpF and DelveTrackerDB.PluginStates["QuickSet"]~=false then
                pcall(qpF,"Tab3",Tab3.quickWrap)
            end
        end

    elseif id==4 then
        Tab4:Show()
        ScanDelves()  -- zorg dat data vers is
        WT_UpdateRoster()

    elseif id==5 then
        -- ARMORY — open Charmory popup voor huidig karakter
        Tab5:Show()
        WT_ShowArmory()

    elseif id==6 then
        Tab6:Show()
        ScanDelves()  -- zorg dat data vers is
        WT_UpdateCurrency()
    end

    for _,b in ipairs(tabBtns) do StyleTabBtn(b,b._id==id) end
end

for i,def in ipairs(tabDefs) do
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(TAB_W,TAB_BAR_H)
    b:SetPoint("TOPLEFT",UI,"TOPLEFT",1+(i-1)*TAB_W,TAB_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b._id=def.id
    b.glow=b:CreateTexture(nil,"OVERLAY")
    b.glow:SetHeight(2)
    b.glow:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1)
    b.glow:SetPoint("TOPRIGHT",b,"TOPRIGHT",-1,-1)
    b.glow:SetColorTexture(0.70,0.25,1.0,1)
    b.glow:SetAlpha(0)
    b.lbl=b:CreateFontString(nil,"OVERLAY")
    b.lbl:SetFont(C_2002,11,"OUTLINE")
    b.lbl:SetPoint("CENTER")
    b.lbl:SetText(def.col..def.label.."|r")
    StyleTabBtn(b,i==activeTabID)
    b:SetScript("OnClick",function() ShowTab(def.id) end)
    b:SetScript("OnEnter",function(self) if self._id~=activeTabID then self:SetBackdropBorderColor(0.50,0.15,0.75,1) end end)
    b:SetScript("OnLeave",function(self) StyleTabBtn(self,self._id==activeTabID) end)
    tabBtns[i]=b
end

local TabLine=UI:CreateTexture(nil,"OVERLAY")
TabLine:SetPoint("TOPLEFT",UI,"TOPLEFT",1,TAB_Y-TAB_BAR_H)
TabLine:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,TAB_Y-TAB_BAR_H)
TabLine:SetHeight(1)
TabLine:SetColorTexture(0.25,0.07,0.40,0.8)

-- ── TAB 1: GUILD ──────────────────────────────────────────────────────────
-- Links: guild info + MOTD + Kelsey image
-- Rechts: online leden lijst (260px breed)

local GUILD_RIGHT_W = 260
local GUILD_LEFT_W  = UI_W - 2 - GUILD_RIGHT_W

-- ── LINKER KOLOM ──────────────────────────────────────────────────────────
-- Guild tab gecentreerd in de linker kolom
Tab1.guildName=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.guildName:SetFont(C_2002,20,"OUTLINE")
Tab1.guildName:SetJustifyH("CENTER")
Tab1.guildName:SetPoint("TOP",Tab1,"TOPLEFT",GUILD_LEFT_W/2,-18)
Tab1.guildName:SetWidth(GUILD_LEFT_W-20)
Tab1.guildName:SetText(SA_GOLD.."Slayer Alliance|r")

Tab1.motdLabel=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.motdLabel:SetFont(C_2002,9,"OUTLINE")
Tab1.motdLabel:SetJustifyH("CENTER")
Tab1.motdLabel:SetPoint("TOP",Tab1.guildName,"BOTTOM",0,-12)
Tab1.motdLabel:SetText(SA_PURPLE.."─── Bericht van de dag ───|r")

Tab1.motdText=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.motdText:SetFont(C_2002,11,"")
Tab1.motdText:SetPoint("TOP",Tab1.motdLabel,"BOTTOM",0,-8)
Tab1.motdText:SetWidth(GUILD_LEFT_W-50)
Tab1.motdText:SetJustifyH("CENTER")
Tab1.motdText:SetWordWrap(true)
Tab1.motdText:SetTextColor(0.85,0.85,0.85,1)
Tab1.motdText:SetText(SA_GREY.."Laden...|r")

-- Kelsey image linksonder
Tab1.img=Tab1:CreateTexture(nil,"ARTWORK")
Tab1.img:SetSize(140,140)
Tab1.img:SetPoint("BOTTOMLEFT",Tab1,"BOTTOMLEFT",14,8)
Tab1.img:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\kelsey.tga")
Tab1.img:SetAlpha(0.80)

-- DieOuwe watermark achtergrond midden-links
Tab1.dieouwe=Tab1:CreateTexture(nil,"BACKGROUND")
Tab1.dieouwe:SetSize(160,260)
Tab1.dieouwe:SetPoint("BOTTOM",Tab1,"BOTTOM",-(GUILD_RIGHT_W/2),-10)
Tab1.dieouwe:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\Dieouwe.tga")
Tab1.dieouwe:SetAlpha(0.20)

-- Logo watermark
Tab1.logoWM=Tab1:CreateTexture(nil,"BACKGROUND")
Tab1.logoWM:SetSize(100,100)
Tab1.logoWM:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMRIGHT",-GUILD_RIGHT_W-10,8)
Tab1.logoWM:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")
Tab1.logoWM:SetAlpha(0.10)

-- ── RECHTER KOLOM: GUILD ONLINE LEDEN ─────────────────────────────────────
-- Verticale scheidingslijn
Tab1.divLine=Tab1:CreateTexture(nil,"OVERLAY")
Tab1.divLine:SetSize(1,600)
Tab1.divLine:SetPoint("TOPRIGHT",Tab1,"TOPRIGHT",-GUILD_RIGHT_W,0)
Tab1.divLine:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMRIGHT",-GUILD_RIGHT_W,0)
Tab1.divLine:SetColorTexture(0.30,0.07,0.50,0.5)

-- Header online panel
Tab1.onlineHdr=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.onlineHdr:SetFont(C_2002,10,"OUTLINE")
Tab1.onlineHdr:SetPoint("TOPRIGHT",Tab1,"TOPRIGHT",-8,-8)
Tab1.onlineHdr:SetText(SA_PURPLE.."Online|r")

Tab1.onlineCount=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.onlineCount:SetFont(C_2002,10,"")
Tab1.onlineCount:SetPoint("RIGHT",Tab1.onlineHdr,"LEFT",-4,0)
Tab1.onlineCount:SetTextColor(0.6,0.4,0.9,1)
Tab1.onlineCount:SetText("")

-- Scroll frame voor online leden
Tab1.onlineScroll=CreateFrame("ScrollFrame",nil,Tab1,"UIPanelScrollFrameTemplate")
Tab1.onlineScroll:SetPoint("TOPRIGHT",Tab1,"TOPRIGHT",-20,-26)
Tab1.onlineScroll:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMRIGHT",-20,8)
Tab1.onlineScroll:SetWidth(GUILD_RIGHT_W-22)
Tab1.onlineScroll.content=CreateFrame("Frame",nil,Tab1.onlineScroll)
Tab1.onlineScroll.content:SetSize(GUILD_RIGHT_W-40,1)
Tab1.onlineScroll:SetScrollChild(Tab1.onlineScroll.content)
Tab1.onlineScroll.content.rows={}

-- ── TAB 2: DELVES — 2 kolommen + zoek met suggesties ─────────────────────
local searchBox=CreateFrame("EditBox","DT_SearchBox",Tab2,"SearchBoxTemplate")
searchBox:SetSize(UI_W-60,24)
searchBox:SetPoint("TOPLEFT",Tab2,"TOPLEFT",10,-6)
searchBox:SetAutoFocus(false)

-- Suggestie dropdown
local DT_SuggestDrop=CreateFrame("Frame","DT_DelvesSuggest",Tab2,"BackdropTemplate")
DT_SuggestDrop:SetFrameLevel(Tab2:GetFrameLevel()+20)
DT_SuggestDrop:SetWidth(280)
DT_SuggestDrop:SetPoint("TOPLEFT",searchBox,"BOTTOMLEFT",0,-1)
DT_SuggestDrop:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
DT_SuggestDrop:SetBackdropColor(0.06,0.03,0.10,0.98)
DT_SuggestDrop:SetBackdropBorderColor(0.45,0.12,0.70,1)
DT_SuggestDrop:Hide()
DT_SuggestDrop.btns={}

local function RefreshSuggest(filter)
    for _,b in ipairs(DT_SuggestDrop.btns) do b:Hide() end
    if not filter or filter=="" then DT_SuggestDrop:Hide(); return end
    local matches={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        local short=k:match("([^-]+)") or k
        if short:lower():find(filter:lower(),1,true) then
            table.insert(matches,{key=k,short=short})
        end
    end
    if #matches==0 then DT_SuggestDrop:Hide(); return end
    table.sort(matches,function(a,b) return a.short<b.short end)
    local BH=22; local cnt=math.min(#matches,8)
    for i=1,cnt do
        local m=matches[i]
        if not DT_SuggestDrop.btns[i] then
            local sb=CreateFrame("Button",nil,DT_SuggestDrop)
            sb:SetHeight(BH)
            sb:SetPoint("TOPLEFT",1,-(BH*(i-1)+1))
            sb:SetPoint("TOPRIGHT",-1,-(BH*(i-1)+1))
            sb.t=sb:CreateFontString(nil,"OVERLAY")
            sb.t:SetFont(C_2002,11,"")
            sb.t:SetPoint("LEFT",6,0)
            sb:SetScript("OnClick",function(self)
                searchBox:SetText(self._short)
                DT_SuggestDrop:Hide()
                if UpdateCharacterList then UpdateCharacterList() end
            end)
            table.insert(DT_SuggestDrop.btns,sb)
        end
        local sb=DT_SuggestDrop.btns[i]
        local data=DelveTrackerDB.characters[m.key] or {}
        local cc=RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}
        sb.t:SetText(string.format("|cff%02x%02x%02x%s|r  "..SA_GREY.."%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            m.short, data.class or "??"))
        sb._short=m.short; sb:Show()
    end
    DT_SuggestDrop:SetHeight(cnt*BH+2); DT_SuggestDrop:Show()
end

searchBox:SetScript("OnTextChanged",function(self)
    SearchBoxTemplate_OnTextChanged(self)
    RefreshSuggest(self:GetText())
    if UpdateCharacterList then UpdateCharacterList() end
end)
searchBox:SetScript("OnEditFocusLost",function()
    C_Timer.After(0.15,function() DT_SuggestDrop:Hide() end)
end)

-- 2-KOLOMS layout — linker + rechter scroll
local COL_W=math.floor((UI_W-50)/2)
local scroll=CreateFrame("ScrollFrame","DT_Scroll",Tab2,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",Tab2,"TOPLEFT",1,-34)
scroll:SetPoint("BOTTOMLEFT",Tab2,"BOTTOMLEFT",1,4)
scroll:SetWidth(COL_W+2)
scroll.content=CreateFrame("Frame",nil,scroll)
scroll.content:SetSize(COL_W,1)
scroll:SetScrollChild(scroll.content)
scroll.content.rows={}

local scroll2=CreateFrame("ScrollFrame","DT_Scroll2",Tab2,"UIPanelScrollFrameTemplate")
scroll2:SetPoint("TOPLEFT",Tab2,"TOPLEFT",COL_W+8,-34)
scroll2:SetPoint("BOTTOMRIGHT",Tab2,"BOTTOMRIGHT",-22,4)
scroll2.content=CreateFrame("Frame",nil,scroll2)
scroll2.content:SetSize(COL_W,1)
scroll2:SetScrollChild(scroll2.content)
scroll2.content.rows={}

-- ── TAB 3: BOUNTY — volle breedte ────────────────────────────────────────
Tab3.PluginArea=CreateFrame("Frame","DT_BountyArea",Tab3)
Tab3.PluginArea:SetPoint("TOPLEFT",Tab3,"TOPLEFT",0,0)
Tab3.PluginArea:SetPoint("BOTTOMRIGHT",Tab3,"BOTTOMRIGHT",0,0)
Tab3.bg=Tab3:CreateTexture(nil,"BACKGROUND")
Tab3.bg:SetAllPoints()
Tab3.bg:SetColorTexture(0.05,0.02,0.08,0.6)

-- Bounty fallback: toon QuickSet frame direct als het bestaat
-- QuickSet maakt zijn eigen frame (DT_QuickSetFrame) — zet het als child van Tab3
Tab3.PluginArea:SetScript("OnShow", function(self)
    C_Timer.After(0.1, function()
        local qf = _G["DT_QuickSetFrame"]
        if qf then
            qf:SetParent(self)
            qf:ClearAllPoints()
            qf:SetPoint("TOPLEFT",self,"TOPLEFT",0,0)
            qf:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",0,0)
            qf:Show()
        end
    end)
end)

-- ── TAB 4: ROSTER ─────────────────────────────────────────────────────────
Tab4.PluginArea=CreateFrame("Frame","DT_RosterArea",Tab4)
Tab4.PluginArea:SetPoint("TOPLEFT",Tab4,"TOPLEFT",0,0)
Tab4.PluginArea:SetPoint("BOTTOMRIGHT",Tab4,"BOTTOMRIGHT",0,0)
-- Header label
Tab4.hdr=Tab4:CreateFontString(nil,"OVERLAY")
Tab4.hdr:SetFont(C_2002,13,"OUTLINE")
Tab4.hdr:SetPoint("TOPLEFT",Tab4,"TOPLEFT",12,-10)
Tab4.hdr:SetText(SA_PURPLE.."Karakter Index|r  "..SA_GREY.."(klik = Armory)|r")
-- Scroll voor roster
Tab4.scroll=CreateFrame("ScrollFrame",nil,Tab4,"UIPanelScrollFrameTemplate")
Tab4.scroll:SetPoint("TOPLEFT",Tab4,"TOPLEFT",1,-32)
Tab4.scroll:SetPoint("BOTTOMRIGHT",Tab4,"BOTTOMRIGHT",-22,4)
Tab4.scroll.content=CreateFrame("Frame",nil,Tab4.scroll)
Tab4.scroll.content:SetSize(UI_W-40,1)
Tab4.scroll:SetScrollChild(Tab4.scroll.content)
Tab4.scroll.content.rows={}  -- initialiseer rows tabel

-- ── TAB 5: ARMORY/CHARMORY ────────────────────────────────────────────────
Tab5.PluginArea=CreateFrame("Frame","DT_ArmoryArea",Tab5)
Tab5.PluginArea:SetPoint("TOPLEFT",Tab5,"TOPLEFT",0,0)
Tab5.PluginArea:SetPoint("BOTTOMRIGHT",Tab5,"BOTTOMRIGHT",0,0)

-- ── TAB 6: CURRENCY ───────────────────────────────────────────────────────
Tab6.PluginArea=CreateFrame("Frame","DT_CurrencyArea",Tab6)
Tab6.PluginArea:SetPoint("TOPLEFT",Tab6,"TOPLEFT",0,0)
Tab6.PluginArea:SetPoint("BOTTOMRIGHT",Tab6,"BOTTOMRIGHT",0,0)
-- Currency header
Tab6.hdr=Tab6:CreateFontString(nil,"OVERLAY")
Tab6.hdr:SetFont(C_2002,12,"OUTLINE")
Tab6.hdr:SetPoint("TOPLEFT",Tab6,"TOPLEFT",8,-8)
Tab6.hdr:SetText(SA_GOLD.."Warband Currencies|r  "..SA_GREY.."(alle karakters)|r")

-- Zoekbalk / filter
Tab6.searchBox=CreateFrame("EditBox",nil,Tab6,"BackdropTemplate")
Tab6.searchBox:SetSize(200,20)
Tab6.searchBox:SetPoint("TOPRIGHT",Tab6,"TOPRIGHT",-24,-8)
Tab6.searchBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
Tab6.searchBox:SetBackdropColor(0.04,0.02,0.08,0.95)
Tab6.searchBox:SetBackdropBorderColor(0.30,0.08,0.50,0.8)
Tab6.searchBox:SetFontObject("ChatFontNormal")
Tab6.searchBox:SetText("Filter karakter...")
Tab6.searchBox:SetAutoFocus(false)
Tab6.searchBox:SetScript("OnEditFocusGained",function(s)
    if s:GetText()=="Filter karakter..." then s:SetText("") end
end)
Tab6.searchBox:SetScript("OnEditFocusLost",function(s)
    if s:GetText()=="" then s:SetText("Filter karakter...") end
end)
Tab6.searchBox:SetScript("OnTextChanged",function()
    if WT_UpdateCurrency then WT_UpdateCurrency() end
end)
Tab6.searchBox:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)

-- Scroll
Tab6.scroll=CreateFrame("ScrollFrame",nil,Tab6,"UIPanelScrollFrameTemplate")
Tab6.scroll:SetPoint("TOPLEFT",Tab6,"TOPLEFT",1,-32)
Tab6.scroll:SetPoint("BOTTOMRIGHT",Tab6,"BOTTOMRIGHT",-22,4)
Tab6.scroll.content=CreateFrame("Frame",nil,Tab6.scroll)
Tab6.scroll.content:SetSize(UI_W-40,1)
Tab6.scroll:SetScrollChild(Tab6.scroll.content)
Tab6.scroll.content.crows={}

-- ============================================================================
-- WT_UpdateRoster — Tab4: zelfde karakter lijst als Tab2 maar zonder zoekbalk
-- ============================================================================
-- Roster ProfessionBuddy-stijl: kaartjes per karakter
local ROSTER_CARD_W = 170
local ROSTER_CARD_H = 80
local ROSTER_COLS   = 4  -- 4 naast elkaar bij 760px breed: 4*170 + 3*10 = 710px
local ROSTER_GAP    = 10

WT_UpdateRoster = function()
    if not (Tab4.scroll and Tab4.scroll.content) then return end

    -- Verberg oude kaartjes
    for _,row in pairs(Tab4.scroll.content.rows or {}) do
        if type(row)=="table" then for _,c in pairs(row) do if c.Hide then c:Hide() end end
        elseif row.Hide then row:Hide() end
    end
    Tab4.scroll.content.rows = {}

    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        table.insert(sorted,k)
    end
    table.sort(sorted)

    for i,key in ipairs(sorted) do
        local data=DelveTrackerDB.characters[key]
        local shortName=key:match("([^-]+)") or key
        local cc=RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}

        -- Grid positie
        local col = (i-1) % ROSTER_COLS
        local row = math.floor((i-1) / ROSTER_COLS)
        local xPos = col * (ROSTER_CARD_W + ROSTER_GAP)
        local yPos = -(row * (ROSTER_CARD_H + ROSTER_GAP))

        local card = Tab4.scroll.content.rows[i]
        if not card then
            card = CreateFrame("Button",nil,Tab4.scroll.content,"BackdropTemplate")
            card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        end
        card:SetSize(ROSTER_CARD_W,ROSTER_CARD_H)
        card:SetPoint("TOPLEFT",xPos,yPos)

        -- Klasse kleur border
        card:SetBackdropColor(
            cc.r*0.08, cc.g*0.08, cc.b*0.08, 0.95)
        card:SetBackdropBorderColor(cc.r*0.7,cc.g*0.7,cc.b*0.7,1)
        card:Show()

        -- Klasse icoon linksboven
        card.cIcon=card.cIcon or card:CreateTexture(nil,"ARTWORK")
        card.cIcon:SetSize(28,28)
        card.cIcon:SetPoint("TOPLEFT",4,-4)
        local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
        if coords then
            card.cIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
            card.cIcon:SetTexCoord(unpack(coords))
        end

        -- Race icoon naast klasse icoon
        card.rIcon=card.rIcon or card:CreateTexture(nil,"ARTWORK")
        card.rIcon:SetSize(20,20)
        card.rIcon:SetPoint("TOPLEFT",card.cIcon,"TOPRIGHT",2,0)
        -- Race icon via SetPortraitToTexture patroon (12.x)
        local raceKey=(data.race or ""):gsub("%s+",""):lower()
        local fac=((data.faction or ""):lower()=="horde") and "horde" or "alliance"
        card.rIcon:SetTexture("Interface\\Icons\\Achievement_Character_"..raceKey.."_"..fac)
        card.rIcon:SetTexCoord(0.08,0.92,0.08,0.92)

        -- Spec icoon rechtsboven (als spec ID beschikbaar)
        card.sIcon=card.sIcon or card:CreateTexture(nil,"ARTWORK")
        card.sIcon:SetSize(20,20)
        card.sIcon:SetPoint("TOPRIGHT",-2,-2)
        if data.specID then
            local _,_,_,specIconID=GetSpecializationInfoByID(data.specID)
            if specIconID then card.sIcon:SetTexture(specIconID) end
        end
        card.sIcon:SetTexCoord(0.08,0.92,0.08,0.92)

        -- iLvl rechts groot
        card.ilvlTxt=card.ilvlTxt or card:CreateFontString(nil,"OVERLAY")
        card.ilvlTxt:SetFont(C_2002,20,"OUTLINE")
        card.ilvlTxt:SetPoint("TOPRIGHT",-4,-4)
        card.ilvlTxt:SetText("|cff00ff00"..(data.ilvl or 0).."|r")

        -- Naam
        card.nm=card.nm or card:CreateFontString(nil,"OVERLAY")
        card.nm:SetFont(C_2002,12,"OUTLINE")
        card.nm:SetPoint("TOPLEFT",36,-6)
        card.nm:SetText(string.format("|cff%02x%02x%02x%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            shortName))

        -- Spec
        card.sp=card.sp or card:CreateFontString(nil,"OVERLAY")
        card.sp:SetFont(C_2002,9,"")
        card.sp:SetPoint("TOPLEFT",36,-20)
        card.sp:SetText(SA_GREY..(data.spec or "??").."|r")

        -- Delve progress
        card.prgr=card.prgr or card:CreateFontString(nil,"OVERLAY")
        card.prgr:SetFont(C_2002,9,"OUTLINE")
        card.prgr:SetPoint("BOTTOMLEFT",4,20)
        local st=""
        if data.delves then
            for _,v in ipairs(data.delves) do
                st=st..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r "
            end
        end
        card.prgr:SetText(st~="" and st or SA_GREY.."—|r")

        -- Gold onderaan
        card.gld=card.gld or card:CreateFontString(nil,"OVERLAY")
        card.gld:SetFont(C_2002,10,"OUTLINE")
        card.gld:SetPoint("BOTTOMRIGHT",-4,4)
        card.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        -- Faction dot
        card.fac=card.fac or card:CreateTexture(nil,"OVERLAY")
        card.fac:SetSize(8,8)
        card.fac:SetPoint("BOTTOMLEFT",4,6)
        if data.faction=="Horde" then
            card.fac:SetColorTexture(0.8,0.1,0.1,1)
        else
            card.fac:SetColorTexture(0.1,0.4,0.9,1)
        end

        -- Hover + click
        card:SetScript("OnEnter",function(self)
            self:SetBackdropBorderColor(1.0,0.85,0,1)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(SA_GOLD..shortName)
            for pN,pF in pairs(DelveTracker.Plugins) do
                if DelveTrackerDB.PluginStates[pN]~=false then
                    pcall(pF,"Tooltip",data,key)
                end
            end
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave",function(self)
            self:SetBackdropBorderColor(cc.r*0.7,cc.g*0.7,cc.b*0.7,1)
            GameTooltip:Hide()
        end)
        card:SetScript("OnClick",function()
            if DT_Armory_ShowCharacter then
                data.name=shortName; DT_Armory_ShowCharacter(data); PlaySound(852)
            end
        end)

        Tab4.scroll.content.rows[i]=card
    end

    local totalRows = math.ceil(#sorted / ROSTER_COLS)
    Tab4.scroll.content:SetHeight(totalRows*(ROSTER_CARD_H+ROSTER_GAP)+ROSTER_GAP)
    Tab4.scroll.content:SetWidth(ROSTER_COLS*(ROSTER_CARD_W+ROSTER_GAP)-ROSTER_GAP)
end


WT_ShowArmory = function()
    local armFrame = _G["DT_ArmoryFrame"]
    if not armFrame then
        if not Tab5.loadTxt then
            Tab5.loadTxt=Tab5:CreateFontString(nil,"OVERLAY")
            Tab5.loadTxt:SetFont(C_2002,12,"")
            Tab5.loadTxt:SetPoint("CENTER")
            Tab5.loadTxt:SetText(SA_GREY.."Armory laadt... gebruik /charmory eenmalig|r")
        end
        return
    end

    -- Embed in Tab5: model links (420px), stats rechts
    if not Tab5.armoryEmbedded then
        Tab5.armoryEmbedded = true
        armFrame._embedded = true  -- voorkomt dat ResetArmoryPosition het verplaatst

        armFrame:SetParent(Tab5)
        armFrame:ClearAllPoints()
        armFrame:SetPoint("TOPLEFT",Tab5,"TOPLEFT",0,0)
        armFrame:SetSize(420, Tab5:GetHeight() or 404)
        armFrame:SetMovable(false)
        armFrame:SetFrameStrata("MEDIUM")
        armFrame:SetFrameLevel(Tab5:GetFrameLevel()+2)

        -- Verberg UI controls die niet passen in embedded modus
        if armFrame.closeBtn  then armFrame.closeBtn:Hide()  end
        if armFrame.btnPlus   then armFrame.btnPlus:Hide()   end
        if armFrame.btnMinus  then armFrame.btnMinus:Hide()  end

        -- Stats panel rechts
        local sp = _G["DT_ArmoryStatsPanel"]
        if sp then
            sp:SetParent(Tab5)
            sp:ClearAllPoints()
            sp:SetPoint("TOPLEFT",Tab5,"TOPLEFT",422,0)
            sp:SetPoint("BOTTOMRIGHT",Tab5,"BOTTOMRIGHT",0,0)
        end
    end

    -- Zorg dat armory zichtbaar is
    armFrame:Show()
    local sp = _G["DT_ArmoryStatsPanel"]
    if sp then sp:Show() end

    -- Haal verse data op voor huidig karakter
    local myKey=(UnitName("player") or "?").."-"..(GetNormalizedRealmName() or "?")
    local data=DelveTrackerDB.characters and DelveTrackerDB.characters[myKey]
    if data then
        if UnitStat then
            data.stats = {
                stamina = UnitStat("player",3),
                str     = UnitStat("player",1),
                agi     = UnitStat("player",2),
                int     = UnitStat("player",4),
                armor   = select(2,UnitArmor("player")),
            }
        end
        data.name  = UnitName("player") or data.name
        data.guild = GetGuildInfo("player") or data.guild or "Geen Guild"
        if DT_Armory_ShowCharacter then
            pcall(DT_Armory_ShowCharacter,data)
        end
    end
end

WT_UpdateGuildOnline = function()
    if not (Tab1.onlineScroll and Tab1.onlineScroll.content) then return end

    -- Verberg oude rijen
    for _,row in pairs(Tab1.onlineScroll.content.rows or {}) do row:Hide() end

    if not IsInGuild() then return end

    -- Bouw lijst van online leden
    local online = {}
    local total  = GetNumGuildMembers()
    for i=1,total do
        local name,rank,_,level,class,zone,_,_,connected = GetGuildRosterInfo(i)
        if connected and name then
            local shortName = name:match("([^-]+)") or name
            table.insert(online, {
                name=shortName, rank=rank, level=level,
                class=class or "WARRIOR", zone=zone or ""
            })
        end
    end

    -- Sorteer op naam
    table.sort(online, function(a,b) return a.name < b.name end)

    -- Update teller
    Tab1.onlineCount:SetText(SA_GOLD..#online.."|r  "..SA_GREY.."online|r")

    local ROW_H = 22
    local ROW_W = Tab1.onlineScroll:GetWidth() - 4

    for i,member in ipairs(online) do
        local r = Tab1.onlineScroll.content.rows[i]
        if not r then
            r = CreateFrame("Frame",nil,Tab1.onlineScroll.content)
        end
        r:SetSize(ROW_W, ROW_H)
        r:SetPoint("TOPLEFT",0,-(i-1)*ROW_H)
        r:Show()

        -- Status dot
        r.dot = r.dot or r:CreateTexture(nil,"OVERLAY")
        r.dot:SetSize(6,6)
        r.dot:SetPoint("LEFT",2,0)
        r.dot:SetColorTexture(0.20,0.90,0.40,1)  -- groen = online

        -- Naam in klasse kleur
        r.nm = r.nm or r:CreateFontString(nil,"OVERLAY")
        r.nm:SetFont(C_2002,11,"")
        r.nm:SetPoint("LEFT",12,0)
        local cc = RAID_CLASS_COLORS[member.class] or {r=0.8,g=0.8,b=0.8}
        r.nm:SetText(string.format("|cff%02x%02x%02x%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            member.name))

        -- Level rechts
        r.lvl = r.lvl or r:CreateFontString(nil,"OVERLAY")
        r.lvl:SetFont(C_2002,9,"")
        r.lvl:SetPoint("RIGHT",0,0)
        r.lvl:SetText(SA_GREY..(member.level or "").."|r")

        Tab1.onlineScroll.content.rows[i] = r
    end
    Tab1.onlineScroll.content:SetHeight(#online * ROW_H + 4)
end

-- ============================================================================
-- WT_UpdateCurrency — Tab6: currency overzicht alle karakters
-- ============================================================================
local CURRENCY_IDS = {
    {id=3028, name="Restored Coffer Keys",  col="|cff00ccff"},
    {id=3310, name="Coffer Key Shards",     col="|cffffee00"},
    {id=3376, name="Shard of Dundun",       col="|cff44cc66"},
    {id=3378, name="Dawnlight Manaflux",    col="|cffa335ee"},
}

-- Currency grid constanten
local CUR_DEFS = {
    {id=3028, label="Keys",     icon="Interface\\Icons\\inv_misc_key_03",         col="|cff00ccff"},
    {id=3310, label="Shards",   icon="Interface\\Icons\\inv_misc_key_14",         col="|cffffee00"},
    {id=3376, label="Dundun",   icon="Interface\\Icons\\inv_jewelcrafting_gem_31",col="|cff44cc66"},
    {id=3378, label="Manaflux", icon="Interface\\Icons\\inv_misc_gem_amethyst_02",col="|cffa335ee"},
}
local CUR_CARD_W = 90
local CUR_CARD_H = 60
local CUR_CARD_GAP = 6
local CUR_ROW_H = 34  -- karakter naamrij
local CUR_ROW_GAP = 4

WT_UpdateCurrency = function()
    if not (Tab6.scroll and Tab6.scroll.content) then return end

    -- Filter van zoekbalk
    local filter = ""
    if Tab6.searchBox then
        local t = Tab6.searchBox:GetText() or ""
        if t ~= "Filter karakter..." then filter = t:lower() end
    end

    -- Verberg alle oude frames
    for k,v in pairs(Tab6.scroll.content.crows or {}) do
        if type(v)=="table" then
            for _,c in pairs(v) do if type(c)=="table" or type(c)=="userdata" then
                if c.Hide then c:Hide() end
            end end
        elseif type(v)=="userdata" and v.Hide then v:Hide() end
    end
    Tab6.scroll.content.crows = {}

    -- Currency definities — gebruik C_CurrencyInfo voor live iconen
    local function getCurInfo(id)
        if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
            local ok,info = pcall(C_CurrencyInfo.GetCurrencyInfo,id)
            if ok and info then return info.iconFileID, info.name end
        end
        return nil, tostring(id)
    end

    local CUR_DEFS = {
        {id=3028, label="Coffer Keys",       col="|cff00ccff"},
        {id=3310, label="Key Shards",         col="|cffffee00"},
        {id=3376, label="Shard of Dundun",    col="|cff44cc66"},
        {id=3378, label="Dawnlight Manaflux", col="|cffa335ee"},
    }

    -- Haal live iconen op (eenmalig)
    for _,def in ipairs(CUR_DEFS) do
        if not def.iconID then
            def.iconID, def.liveName = getCurInfo(def.id)
            if def.liveName and def.liveName ~= tostring(def.id) then
                def.label = def.liveName
            end
        end
    end

    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        if filter=="" or k:lower():find(filter,1,true) then
            table.insert(sorted,k)
        end
    end
    table.sort(sorted)

    local TILE_W = 68
    local TILE_H = 72
    local TILE_G = 6
    local COLS   = math.floor((UI_W-46) / (TILE_W+TILE_G))
    local ROW_H  = 30  -- karakter naam rij
    local yOff   = -4

    for ci,key in ipairs(sorted) do
        local data = DelveTrackerDB.characters[key]
        local cur  = data.currencies or {}
        local shortName = key:match("([^-]+)") or key
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}

        -- Karakter naam header rij
        local nameRow = CreateFrame("Frame",nil,Tab6.scroll.content,"BackdropTemplate")
        nameRow:SetSize(UI_W-46, ROW_H)
        nameRow:SetPoint("TOPLEFT",0,yOff)
        nameRow:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        nameRow:SetBackdropColor(0.10,0.05,0.16,0.9)
        nameRow:SetBackdropBorderColor(0.40,0.10,0.60,0.7)
        nameRow:Show()

        local nm=nameRow:CreateFontString(nil,"OVERLAY")
        nm:SetFont(C_2002,12,"OUTLINE")
        nm:SetPoint("LEFT",8,0)
        nm:SetText(string.format("|cff%02x%02x%02x%s|r  "..SA_GREY.."%s · iLvl %d|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            shortName, data.spec or "??", data.ilvl or 0))

        local gld=nameRow:CreateFontString(nil,"OVERLAY")
        gld:SetFont(C_2002,11,"OUTLINE")
        gld:SetPoint("RIGHT",-8,0)
        gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        Tab6.scroll.content.crows["nr_"..ci] = nameRow
        yOff = yOff - ROW_H - 2

        -- Currency tiles: 4 naast elkaar
        local cards = {}
        for j,def in ipairs(CUR_DEFS) do
            local val = cur[def.id] or 0
            local xPos = (j-1)*(TILE_W+TILE_G) + 4

            local card = CreateFrame("Button",nil,Tab6.scroll.content,"BackdropTemplate")
            card:SetSize(TILE_W,TILE_H)
            card:SetPoint("TOPLEFT",xPos,yOff)
            card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
            card:SetBackdropColor(0.07,0.03,0.12,(val>0 and 0.95 or 0.6))
            card:SetBackdropBorderColor(
                val>0 and 0.50 or 0.15,
                0.05,
                val>0 and 0.75 or 0.25,
                val>0 and 1.0 or 0.5)
            card:Show()

            -- Icoon groot (46x46 centered)
            card.ico=card:CreateTexture(nil,"ARTWORK")
            card.ico:SetSize(44,44)
            card.ico:SetPoint("TOP",card,"TOP",0,-4)
            if def.iconID then
                card.ico:SetTexture(def.iconID)
            end
            card.ico:SetTexCoord(0.08,0.92,0.08,0.92)
            -- Dimmen als 0
            card.ico:SetAlpha(val>0 and 1.0 or 0.35)

            -- Waarde getal onderaan icoon
            card.valTxt=card:CreateFontString(nil,"OVERLAY")
            card.valTxt:SetFont(C_2002,14,"OUTLINE")
            card.valTxt:SetPoint("BOTTOM",card,"BOTTOM",0,4)
            card.valTxt:SetText(def.col..val.."|r")

            -- Tooltip bij hover
            card:SetScript("OnEnter",function(self)
                self:SetBackdropBorderColor(0.85,0.70,0.10,1)
                GameTooltip:SetOwner(self,"ANCHOR_TOP")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(def.col..def.label.."|r")
                GameTooltip:AddLine(SA_GREY..shortName..": ".."|cffffffff"..val.."|r")
                if val==0 then
                    GameTooltip:AddLine("|cffff5555Geen op dit karakter|r")
                end
                GameTooltip:Show()
            end)
            card:SetScript("OnLeave",function(self)
                self:SetBackdropBorderColor(val>0 and 0.50 or 0.15, 0.05, val>0 and 0.75 or 0.25, val>0 and 1.0 or 0.5)
                GameTooltip:Hide()
            end)

            table.insert(cards,card)
        end

        Tab6.scroll.content.crows["cards_"..ci] = cards
        yOff = yOff - TILE_H - TILE_G
    end

    Tab6.scroll.content:SetHeight(-yOff + 10)
end


-- ── GUILD ROSTER UPDATE EVENT ─────────────────────────────────────────────
-- GUILD_ROSTER_UPDATE vuurt nadat GuildRoster() data opgehaald heeft
local guildEventFrame = CreateFrame("Frame")
guildEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
guildEventFrame:SetScript("OnEvent", function()
    if not Tab1:IsShown() then return end
    -- MOTD nu beschikbaar
    local motd = GetGuildRosterMOTD() or ""
    if Tab1.motdText then
        Tab1.motdText:SetText(motd ~= "" and (SA_GREY..motd.."|r") or SA_GREY.."Geen MOTD ingesteld.|r")
    end
    WT_UpdateGuildOnline()
end)

-- ── FOOTER ────────────────────────────────────────────────────────────────
local FtrBG=UI:CreateTexture(nil,"BACKGROUND")
FtrBG:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",1,1)
FtrBG:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-1,1)
FtrBG:SetHeight(FOOTER_H)
FtrBG:SetColorTexture(0.04,0.02,0.07,1)

local FtrLine=UI:CreateTexture(nil,"OVERLAY")
FtrLine:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",1,FOOTER_H)
FtrLine:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-1,FOOTER_H)
FtrLine:SetHeight(1)
FtrLine:SetColorTexture(0.30,0.07,0.50,0.6)

local dcLbl=UI:CreateFontString(nil,"OVERLAY")
dcLbl:SetFont(C_2002,9,"OUTLINE")
dcLbl:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",14,FOOTER_H-18)
dcLbl:SetTextColor(0.60,0.45,0.80,1)
dcLbl:SetText(SA_GOLD.."CTRL+C — Discord:|r")

local dBox=CreateFrame("EditBox",nil,UI,"BackdropTemplate")
dBox:SetSize(280,20)
dBox:SetPoint("LEFT",dcLbl,"RIGHT",6,0)
dBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
dBox:SetBackdropColor(0,0,0,0.9)
dBox:SetBackdropBorderColor(0.25,0.07,0.40,1)
dBox:SetFontObject("ChatFontNormal")
dBox:SetText("https://slayeralliance.com/discord")
dBox:SetAutoFocus(false)
dBox:SetJustifyH("LEFT")
dBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)

-- Scale +/- knoppen (traag: 0.05 stap)
local scaleValTxt=UI:CreateFontString(nil,"OVERLAY")
scaleValTxt:SetFont(C_2002,9,"OUTLINE")
scaleValTxt:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-70,10)
scaleValTxt:SetText("1.00")
scaleValTxt:SetTextColor(0.75,0.55,1,1)

local scaleLbl=UI:CreateFontString(nil,"OVERLAY")
scaleLbl:SetFont(C_2002,9,"")
scaleLbl:SetPoint("BOTTOM",scaleValTxt,"TOP",0,2)
scaleLbl:SetText(SA_GREY.."Schaal|r")

local function MakeScaleBtn(lbl,xOff,fn)
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(26,20)
    b:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",xOff,8)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.08,0.04,0.14,1)
    b:SetBackdropBorderColor(0.30,0.08,0.50,1)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,13,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText(SA_PURPLE..lbl.."|r")
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.30,0.08,0.50,1) end)
    return b
end
MakeScaleBtn("+",-36,function()
    local c=DelveTrackerDB.mainScale or 1.0
    local n=math.min(2.0,math.floor((c+SCALE_STEP)*100+0.5)/100)
    DelveTrackerDB.mainScale=n; UI:SetScale(n)
    scaleValTxt:SetText(string.format("%.2f",n))
end)
MakeScaleBtn("-",-8,function()
    local c=DelveTrackerDB.mainScale or 1.0
    local n=math.max(0.5,math.floor((c-SCALE_STEP)*100+0.5)/100)
    DelveTrackerDB.mainScale=n; UI:SetScale(n)
    scaleValTxt:SetText(string.format("%.2f",n))
end)

-- Snelknoppen links in footer — breed genoeg dat ze binnen 760px vallen
-- Layout: [Cloth][Skin][Prey] links · [Debug] rechts naast schaal knoppen
local BTN_W = 72
local BTN_H = 22
local BTN_Y = 8  -- van onderkant

local function MakePluginBtn(lbl, col, xOff, fn)
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(BTN_W,BTN_H)
    b:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",xOff,BTN_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.06,0.03,0.10,0.95)
    b:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText(col..lbl.."|r")
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.28,0.08,0.45,0.9) end)
    return b
end

-- Links: Cloth | Skin | Prey (4px gap ertussen)
local GAP = 4
MakePluginBtn("🧵 Cloth","|cff44aaff", 4, function()
    if SlashCmdList["CBUDGET"] then SlashCmdList["CBUDGET"]("")
    elseif SlashCmdList["CBUD"] then SlashCmdList["CBUD"]("") end
end)
MakePluginBtn("🐾 Skin","|cff44cc66", 4+BTN_W+GAP, function()
    if SlashCmdList["MAJESTICTRACKER"] then SlashCmdList["MAJESTICTRACKER"]("")
    elseif SlashCmdList["SNR"] then SlashCmdList["SNR"]("") end
end)
MakePluginBtn("🎯 Prey+","|cffff6644", 4+(BTN_W+GAP)*2, function()
    if SlashCmdList["DTPREY"] then SlashCmdList["DTPREY"]("") end
end)

-- Rechts: Debug naast de +/- schaal knoppen
local function MakeDebugBtn()
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(BTN_W,BTN_H)
    b:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-80,BTN_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.06,0.03,0.10,0.95)
    b:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText("|cff887799🐛 Debug|r")
    b:SetScript("OnClick",function()
        local f=_G["DT_DebugFrame"]
        if f then if f:IsShown() then f:Hide() else f:Show() end
        elseif SlashCmdList["DTDEBUG"] then SlashCmdList["DTDEBUG"]("") end
    end)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.28,0.08,0.45,0.9) end)
end
MakeDebugBtn()

-- ── DATA ──────────────────────────────────────────────────────────────────
local function CheckWeeklyReset()
    local cw=GetServerTime()/(60*60*24*7)
    if not DelveTrackerDB.lastResetWeek or math.floor(cw)>math.floor(DelveTrackerDB.lastResetWeek) then
        DelveTrackerDB.lastResetWeek=cw
        if DelveTrackerDB.characters then
            for _,d in pairs(DelveTrackerDB.characters) do d.delves={}; d.totalDone=0 end
        end
    end
end

ScanDelves = function()
    CheckWeeklyReset()
    local name=UnitName("player"); local realm=GetNormalizedRealmName()
    if not name or not realm then return end
    local key=name.."-"..realm
    DelveTrackerDB.characters=DelveTrackerDB.characters or {}
    DelveTrackerDB.characters[key]=DelveTrackerDB.characters[key] or {}
    local d=DelveTrackerDB.characters[key]
    local _,class=UnitClass("player")
    local si=GetSpecialization and GetSpecialization()
    d.class   = class
    d.faction = UnitFactionGroup("player")
    d.spec    = si and select(2,GetSpecializationInfo(si)) or "No spec"
    local _,ilvl=GetAverageItemLevel()
    d.ilvl    = math.floor(ilvl or 0)
    d.level   = UnitLevel("player")
    d.money   = GetMoney() or 0   -- FIX: nu echt geschreven
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities and Enum and Enum.WeeklyRewardChestThresholdType then
        local ok,acts=pcall(C_WeeklyRewards.GetActivities,Enum.WeeklyRewardChestThresholdType.World)
        if ok and acts then
            d.delves={}; d.totalDone=0
            for _,a in ipairs(acts) do
                table.insert(d.delves,{p=a.progress,t=a.threshold})
                if a.progress>d.totalDone then d.totalDone=a.progress end
            end
        end
    end
    -- Scan gear voor huidig karakter
    d.guild   = GetGuildInfo("player") or d.guild or "Geen Guild"
    d.avgIlvl = select(2, GetAverageItemLevel()) or 0
    if UnitStat then
        d.stats = {
            stamina = UnitStat("player",3),
            str     = UnitStat("player",1),
            agi     = UnitStat("player",2),
            int     = UnitStat("player",4),
            armor   = select(2, UnitArmor and UnitArmor("player") or 0,0),
        }
    end
    local GEAR_SLOTS = {"HeadSlot","NeckSlot","ShoulderSlot","BackSlot","ChestSlot",
        "WristSlot","HandsSlot","WaistSlot","LegsSlot","FeetSlot",
        "Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot",
        "MainHandSlot","SecondaryHandSlot"}
    d.gear = d.gear or {}
    for _,s in ipairs(GEAR_SLOTS) do
        local link = GetInventoryItemLink("player", GetInventorySlotInfo(s))
        if link then
            local ilvl = C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
            d.gear[s] = {link=link, ilvl=ilvl or 0}
        else
            d.gear[s] = nil
        end
    end
end

UpdateCharacterList = function()
    ScanDelves()
    local myKey=(UnitName("player") or "?").."-"..(GetNormalizedRealmName() or "?")
    local d=DelveTrackerDB.characters and DelveTrackerDB.characters[myKey]
    if d then
        local c=RAID_CLASS_COLORS[d.class] or {r=1,g=1,b=1}
        UI.charInfo:SetText(string.format(
            "|cff%02x%02x%02x%s|r  |cffffffffLvl %d|r  ·  %s %s  ·  |cff00ff00iLvl %d|r  ·  "..SA_GOLD.."%dg|r",
            math.floor(c.r*255+0.5),math.floor(c.g*255+0.5),math.floor(c.b*255+0.5),
            UnitName("player") or "?",d.level or 0,d.spec or "??",d.class or "",d.ilvl or 0,
            math.floor((d.money or 0)/10000)
        ))
    end
    if not (DT_Scroll and DT_Scroll.content) then return end
    local filter=(DT_SearchBox and DT_SearchBox:GetText() or ""):lower()
    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        if filter=="" or k:lower():find(filter,1,true) then table.insert(sorted,k) end
    end
    table.sort(sorted)
    for _,row in pairs(DT_Scroll.content.rows) do row:Hide() end
    local ROW_H=60; local ROW_W=UI_W-46
    for i,key in ipairs(sorted) do
        local data=DelveTrackerDB.characters[key]
        local r=DT_Scroll.content.rows[i]
        if not r then
            r=CreateFrame("Button",nil,DT_Scroll.content,"BackdropTemplate")
            r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        end
        r:SetSize(ROW_W,ROW_H)
        r:SetPoint("TOPLEFT",0,-(i-1)*(ROW_H+3))
        r:SetBackdropColor(0.08,0.04,0.12,0.8)
        r:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
        r:Show()
        -- Faction
        r.fLet=r.fLet or r:CreateFontString(nil,"OVERLAY")
        r.fLet:SetFont(C_2002,14,"OUTLINE")
        r.fLet:SetPoint("LEFT",8,0)
        r.fLet:SetText(data.faction=="Horde" and "|cffff4444H|r" or "|cff4488ffA|r")
        -- Klasse icon
        r.cIcon=r.cIcon or r:CreateTexture(nil,"OVERLAY")
        r.cIcon:SetSize(36,36); r.cIcon:SetPoint("LEFT",r.fLet,"RIGHT",8,0)
        if data.class then
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class]
            if coords then
                r.cIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                r.cIcon:SetTexCoord(unpack(coords))
            end
        end
        -- Naam
        r.nm=r.nm or r:CreateFontString(nil,"OVERLAY")
        r.nm:SetFont(C_2002,12,"OUTLINE")
        r.nm:SetPoint("LEFT",r.cIcon,"RIGHT",10,8)
        r.nm:SetText(SA_GOLD..(key:match("([^-]+)") or key).."|r")
        -- Spec
        r.sp=r.sp or r:CreateFontString(nil,"OVERLAY")
        r.sp:SetFont(C_2002,9,"")
        r.sp:SetPoint("LEFT",r.cIcon,"RIGHT",10,-4)
        r.sp:SetText(SA_GREY..(data.spec or "??").." · iLvl "..(data.ilvl or 0).."|r")
        -- Delve progress
        r.prgr=r.prgr or r:CreateFontString(nil,"OVERLAY")
        r.prgr:SetFont(C_2002,10,"OUTLINE")
        r.prgr:SetPoint("LEFT",r.cIcon,"RIGHT",10,-17)
        local st=""
        if data.delves then
            for _,v in ipairs(data.delves) do
                st=st..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r  "
            end
        end
        r.prgr:SetText(st~="" and st or SA_GREY.."—|r")
        -- Gold
        r.gld=r.gld or r:CreateFontString(nil,"OVERLAY")
        r.gld:SetFont(C_2002,11,"OUTLINE")
        r.gld:SetPoint("RIGHT",-10,0)
        r.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")
        -- iLvl badge
        r.ilv=r.ilv or r:CreateFontString(nil,"OVERLAY")
        r.ilv:SetFont(C_2002,10,"OUTLINE")
        r.ilv:SetPoint("RIGHT",r.gld,"LEFT",-12,0)
        r.ilv:SetText("|cff00ff00"..  (data.ilvl or 0).."|r")
        -- Events
        local shortName=key:match("([^-]+)") or key
        r:SetScript("OnEnter",function(self)
            self:SetBackdropColor(0.14,0.07,0.22,1)
            self:SetBackdropBorderColor(0.50,0.15,0.80,1)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(SA_GOLD..shortName)
            for pN,pF in pairs(DelveTracker.Plugins) do
                if DelveTrackerDB.PluginStates[pN]~=false then pcall(pF,"Tooltip",data,key) end
            end
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave",function(self)
            self:SetBackdropColor(0.08,0.04,0.12,0.8)
            self:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
            GameTooltip:Hide()
        end)
        r:SetScript("OnClick",function()
            if DT_Armory_ShowCharacter then
                data.name=shortName; DT_Armory_ShowCharacter(data); PlaySound(852)
            end
        end)
        DT_Scroll.content.rows[i]=r
    end
    -- Verdeel over 2 kolommen
    local half=math.ceil(#sorted/2)
    DT_Scroll.content:SetHeight(half*(ROW_H+3))
    -- Kolom 2 content opbouwen (DT_Scroll2 als aanwezig)
    if _G["DT_Scroll2"] then
        local s2=_G["DT_Scroll2"]
        if not s2.content.rows then s2.content.rows={} end
        for _,r in pairs(s2.content.rows) do r:Hide() end
        local ri2=0
        for j=half+1,#sorted do
            ri2=ri2+1
            local key2=sorted[j]
            local data2=DelveTrackerDB.characters[key2]
            local shortName2=key2:match("([^-]+)") or key2
            local cc2=RAID_CLASS_COLORS and RAID_CLASS_COLORS[data2.class or ""] or {r=0.8,g=0.8,b=0.8}
            local r2=s2.content.rows[ri2]
            if not r2 then
                r2=CreateFrame("Button",nil,s2.content,"BackdropTemplate")
                r2:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
            end
            local ROW_W2=s2.content:GetWidth() or COL_W
            r2:SetSize(ROW_W2,ROW_H)
            r2:SetPoint("TOPLEFT",0,-(ri2-1)*(ROW_H+3))
            r2:SetBackdropColor(0.08,0.04,0.12,0.8)
            r2:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
            r2:Show()
            -- Vul zelfde velden als kolom 1
            r2.fLet=r2.fLet or r2:CreateFontString(nil,"OVERLAY")
            r2.fLet:SetFont(C_2002,12,"OUTLINE"); r2.fLet:SetPoint("LEFT",6,0)
            r2.fLet:SetText(data2.faction=="Horde" and "|cffff4444H|r" or "|cff4488ffA|r")
            r2.cIcon=r2.cIcon or r2:CreateTexture(nil,"OVERLAY")
            r2.cIcon:SetSize(30,30); r2.cIcon:SetPoint("LEFT",r2.fLet,"RIGHT",4,0)
            local coords2=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data2.class or ""]
            if coords2 then r2.cIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes"); r2.cIcon:SetTexCoord(unpack(coords2)) end
            r2.nm=r2.nm or r2:CreateFontString(nil,"OVERLAY")
            r2.nm:SetFont(C_2002,11,"OUTLINE"); r2.nm:SetPoint("LEFT",r2.cIcon,"RIGHT",6,6)
            r2.nm:SetText(string.format("|cff%02x%02x%02x%s|r",math.floor(cc2.r*255),math.floor(cc2.g*255),math.floor(cc2.b*255),shortName2))
            r2.sp=r2.sp or r2:CreateFontString(nil,"OVERLAY")
            r2.sp:SetFont(C_2002,9,""); r2.sp:SetPoint("LEFT",r2.cIcon,"RIGHT",6,-6)
            r2.sp:SetText(SA_GREY..(data2.spec or "??").." · iLvl "..(data2.ilvl or 0).."|r")
            r2.gld=r2.gld or r2:CreateFontString(nil,"OVERLAY")
            r2.gld:SetFont(C_2002,10,"OUTLINE"); r2.gld:SetPoint("RIGHT",-6,0)
            r2.gld:SetText(SA_GOLD..math.floor((data2.money or 0)/10000).."g|r")
            s2.content.rows[ri2]=r2
        end
        s2.content:SetHeight(ri2*(ROW_H+3))
    end
end

-- ── ADMIN PANEL ───────────────────────────────────────────────────────────
-- Volledig gesectioned, geen overlappende absolute Y-offsets
-- Gebruikt anchor-chaining: elk element anchor op het vorige
-- ============================================================================
local opt=CreateFrame("Frame","DelveTrackerOptions")
opt.name="DelveTracker"
local category=Settings.RegisterCanvasLayoutCategory(opt,opt.name)
Settings.RegisterAddOnCategory(category)
UI.settingsBtn:SetScript("OnClick",function() Settings.OpenToCategory(category:GetID()) end)

-- ── HEADER (vaste posities — geen anchor chain) ──────────────────────────
opt.logo=opt:CreateTexture(nil,"ARTWORK")
opt.logo:SetSize(40,40)
opt.logo:SetPoint("TOPLEFT",16,-16)
opt.logo:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")

opt.tit=opt:CreateFontString(nil,"OVERLAY")
opt.tit:SetFont(C_2002,15,"OUTLINE")
opt.tit:SetPoint("TOPLEFT",62,-18)
opt.tit:SetText(SA_PURPLE.."WowTracker|r  "..SA_GREY.."v2.7.8|r")

opt.sub=opt:CreateFontString(nil,"OVERLAY")
opt.sub:SetFont(C_2002,9,"")
opt.sub:SetPoint("TOPLEFT",62,-38)
opt.sub:SetText(SA_GREY.."Slayer Alliance · Midnight 12.0.5.67314|r")

opt.charImg=opt:CreateTexture(nil,"ARTWORK")
opt.charImg:SetSize(60,105)
opt.charImg:SetPoint("TOPRIGHT",-14,-4)
opt.charImg:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\Dieouwe.tga")
opt.charImg:SetAlpha(0.85)

-- Lijn Y=60
opt.hdrLine=opt:CreateTexture(nil,"OVERLAY")
opt.hdrLine:SetHeight(1)
opt.hdrLine:SetPoint("TOPLEFT",8,-60)
opt.hdrLine:SetPoint("TOPRIGHT",-8,-60)
opt.hdrLine:SetColorTexture(0.35,0.10,0.55,0.7)

-- ── UI SCHAAL Y=70 ────────────────────────────────────────────────────────
opt.scaleHdr=opt:CreateFontString(nil,"OVERLAY")
opt.scaleHdr:SetFont(C_2002,10,"OUTLINE")
opt.scaleHdr:SetPoint("TOPLEFT",8,-70)
opt.scaleHdr:SetText(SA_PURPLE.."UI SCHAAL|r")

local function MakeSlider(parent,lbl,minV,maxV,step,dbKey,fn,y)
    local l=parent:CreateFontString(nil,"OVERLAY")
    l:SetFont(C_2002,10,"")
    l:SetPoint("TOPLEFT",8,y)
    l:SetText(SA_GREY..lbl.."|r")

    local s=CreateFrame("Slider","DT_Slider_"..dbKey,parent)
    s:SetSize(260,14)
    s:SetPoint("TOPLEFT",8,y-14)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(minV,maxV)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local bg=s:CreateTexture(nil,"BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background"); bg:SetAllPoints()

    local vt=s:CreateFontString(nil,"OVERLAY")
    vt:SetFont(C_2002,10,"")
    vt:SetPoint("LEFT",s,"RIGHT",6,0)
    vt:SetTextColor(0.8,0.6,1,1)

    local init=DelveTrackerDB[dbKey] or 1.0
    s:SetValue(init); vt:SetText(string.format("%.2f",init))
    s:SetScript("OnValueChanged",function(_,v)
        v=math.floor(v*100+0.5)/100
        DelveTrackerDB[dbKey]=v
        vt:SetText(string.format("%.2f",v))
        fn(v)
    end)
end

MakeSlider(opt,"Main window scale",0.5,2.0,0.05,"scale",
    function(v) UI:SetScale(v) end,-82)
MakeSlider(opt,"Murloc button scale",0.5,2.0,0.05,"mScale",
    function(v) if _G["DT_MurlocBtn"] then _G["DT_MurlocBtn"]:SetScale(v) end end,-114)

-- Lijn Y=145
opt.scaleLine=opt:CreateTexture(nil,"OVERLAY")
opt.scaleLine:SetHeight(1)
opt.scaleLine:SetPoint("TOPLEFT",8,-145)
opt.scaleLine:SetPoint("TOPRIGHT",-8,-145)
opt.scaleLine:SetColorTexture(0.20,0.05,0.35,0.5)

-- ── PLUGINS Y=155 ─────────────────────────────────────────────────────────
opt.plbl=opt:CreateFontString(nil,"OVERLAY")
opt.plbl:SetFont(C_2002,10,"OUTLINE")
opt.plbl:SetPoint("TOPLEFT",8,-155)
opt.plbl:SetText(SA_PURPLE.."PLUGINS|r  "..SA_GREY.."(toggle = direct effect)|r")

opt.pScroll=CreateFrame("ScrollFrame","DT_PluginScroll",opt,"UIPanelScrollFrameTemplate")
opt.pScroll:SetSize(550,310)
opt.pScroll:SetPoint("TOPLEFT",8,-170)
local pContent=CreateFrame("Frame",nil,opt.pScroll)
pContent:SetSize(500,1); opt.pScroll:SetScrollChild(pContent); pContent.rows={}

local function UpdatePluginList()
    DelveTrackerDB.PluginStates=DelveTrackerDB.PluginStates or {}
    local names={}
    for n in pairs(DelveTracker.Plugins) do table.insert(names,n) end
    table.sort(names,function(a,b)
        if a=="UserInfo" then return true end
        if b=="UserInfo" then return false end
        return a<b
    end)
    for i,name in ipairs(names) do
        local r=pContent.rows[i]
        if not r then
            r=CreateFrame("Frame",nil,pContent,"BackdropTemplate")
            r:SetSize(498,28)
            r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        end
        r:SetPoint("TOPLEFT",0,(i-1)*-31)
        local pinned=(name=="UserInfo")
        r:SetBackdropColor(pinned and 0.12 or 0.07, 0.04, pinned and 0.18 or 0.11, 0.9)
        r:SetBackdropBorderColor(pinned and 0.55 or 0.18, 0.05, pinned and 0.85 or 0.28, 1)
        r:Show()

        r.t=r.t or r:CreateFontString(nil,"OVERLAY")
        r.t:SetFont(C_2002,11,"")
        r.t:SetPoint("LEFT",8,0)
        r.t:SetText((pinned and SA_PURPLE or SA_GREY)..name.."|r")

        -- Beschrijving
        r.desc=r.desc or r:CreateFontString(nil,"OVERLAY")
        r.desc:SetFont(C_2002,9,"")
        r.desc:SetPoint("LEFT",r.t,"RIGHT",10,0)
        local descs={
            UserInfo="Karakter armory & model viewer",
            PreyTracker="Kompas HUD voor Prey Hunts",
            ClothCounter="Stof tracker warband-breed",
            SkinNRare="Rare beast waypoints",
            Registry="XL karakter index (/crew)",
            Lockout="Raid & dungeon lockouts",
            ExchangeBot="Currency exchange",
            Debugger="In-game log & DB viewer",
            CombatAnnounce="Combat tekst aankondigingen",
            HelpGuide="Help scherm (/dthelp)",
            Charmory="Armory popup",
            QuickSet="Bounty delve tracker",
            Media="Zone media manager",
            CustomAFK="AFK scherm",
        }
        r.desc:SetText(SA_GREY..(descs[name] or "").."|r")

        r.btn=r.btn or CreateFrame("Button",nil,r,"BackdropTemplate")
        r.btn:SetSize(52,20); r.btn:SetPoint("RIGHT",-5,0)
        r.btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        r.btn.t=r.btn.t or r.btn:CreateFontString(nil,"OVERLAY")
        r.btn.t:SetFont(C_2002,10,"OUTLINE"); r.btn.t:SetPoint("CENTER")

        local function Rfsh()
            local en=DelveTrackerDB.PluginStates[name]~=false
            r.btn:SetBackdropColor(en and 0.04 or 0.22,en and 0.16 or 0.04,0.04,1)
            r.btn:SetBackdropBorderColor(en and 0.10 or 0.55,en and 0.55 or 0.10,0.05,1)
            r.btn.t:SetText(en and "|cff44cc66ON|r" or "|cffcc4444OFF|r")
        end
        r.btn:SetScript("OnClick",function()
            DelveTrackerDB.PluginStates[name]=not(DelveTrackerDB.PluginStates[name]~=false); Rfsh()
        end)
        Rfsh(); pContent.rows[i]=r
    end
    pContent:SetHeight(#names*31+4)
end
opt:SetScript("OnShow",UpdatePluginList)

-- Lijn Y=490 (170 start + 310 hoogte + 10 gap)
-- ─────────────────────────────────────────────────────────────────────────
-- EXTRA OPTIES — verankerd ONDER de scrolllijst, nooit erin
-- pScroll start Y=-170, hoogte=310px → eindigt bij Y=-480
-- Extra opties: Y=-492 (12px marge)
-- ─────────────────────────────────────────────────────────────────────────
opt.plugLine=opt:CreateTexture(nil,"OVERLAY")
opt.plugLine:SetHeight(1)
opt.plugLine:SetPoint("TOPLEFT",opt.pScroll,"BOTTOMLEFT",0,-8)
opt.plugLine:SetWidth(540)
opt.plugLine:SetColorTexture(0.20,0.05,0.35,0.5)

opt.extraHdr=opt:CreateFontString(nil,"OVERLAY")
opt.extraHdr:SetFont(C_2002,10,"OUTLINE")
opt.extraHdr:SetPoint("TOPLEFT",opt.plugLine,"BOTTOMLEFT",0,-8)
opt.extraHdr:SetText(SA_PURPLE.."EXTRA OPTIES|r")

local function MakeOptBtn(lbl,anchorFrame,fn)
    local b=CreateFrame("Button",nil,opt,"BackdropTemplate")
    b:SetSize(280,24)
    b:SetPoint("TOPLEFT",anchorFrame,"BOTTOMLEFT",0,-4)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.08,0.04,0.12,0.9)
    b:SetBackdropBorderColor(0.25,0.07,0.40,1)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"")
    t:SetPoint("LEFT",8,0)
    t:SetText(SA_GREY..lbl.."|r")
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.55,0.15,0.85,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.25,0.07,0.40,1) end)
    return b  -- teruggeven voor anchoring
end

local eb1=MakeOptBtn("⚙  Combat Announcer (/cset)",opt.extraHdr,function()
    if SlashCmdList["CSET"] then SlashCmdList["CSET"]("")
    elseif SlashCmdList["DTCSET"] then SlashCmdList["DTCSET"]("") end
end)
local eb2=MakeOptBtn("⊞  AFK Screen layout (/dtgrid)",eb1,function()
    if SlashCmdList["DTGRID"] then SlashCmdList["DTGRID"]("") end
end)
local eb3=MakeOptBtn("▶  Preview AFK scherm (/dtafk)",eb2,function()
    if SlashCmdList["DTAFK"] then SlashCmdList["DTAFK"]("") end
end)
MakeOptBtn("⚠  Wipe Character DB",eb3,function()
    if DelveTrackerDB then
        DelveTrackerDB.characters={}
        print(SA_PURPLE.."[WowTracker]|r DB gewist.|r")
    end
end)

-- ─────────────────────────────────────────────────────────────────────────
-- ACTIE KNOPPEN: Reload UI | Wipe DB | Del Char
-- NAAST Extra opties (rechter kolom van het admin panel)
-- ─────────────────────────────────────────────────────────────────────────
local function MakeActionBtn(lbl,col,x,anchorFrame,fn)
    local b=CreateFrame("Button",nil,opt,"BackdropTemplate")
    b:SetSize(120,26)
    b:SetPoint("TOPLEFT",anchorFrame,"TOPRIGHT",x,0)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(col[1],col[2],col[3],0.9)
    b:SetBackdropBorderColor(col[1]+0.2,col[2]+0.1,col[3]+0.1,1)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText(lbl)
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s)
        s:SetBackdropBorderColor(1,0.9,0.2,1)
    end)
    b:SetScript("OnLeave",function(s)
        s:SetBackdropBorderColor(col[1]+0.2,col[2]+0.1,col[3]+0.1,1)
    end)
    return b
end

-- Reload UI
local abReload=MakeActionBtn("|cffffffff⟳  Reload UI|r",{0.08,0.12,0.20},12,opt.extraHdr,
    function() ReloadUI() end)
-- Wipe DB
local abWipe=MakeActionBtn("|cffff6644⚠  Wipe DB|r",{0.20,0.05,0.05},0,abReload,
    function()
        if DelveTrackerDB then
            DelveTrackerDB.characters={}
            print(SA_PURPLE.."[WowTracker]|r "..SA_GREY.."Character DB gewist.|r")
        end
    end)
-- Del Char (huidig karakter)
MakeActionBtn("|cffccaa00✕  Del Char|r",{0.15,0.10,0.02},0,abWipe,
    function()
        local key=(UnitName("player") or "?").."-"..(GetNormalizedRealmName() or "?")
        if DelveTrackerDB and DelveTrackerDB.characters then
            DelveTrackerDB.characters[key]=nil
            print(SA_PURPLE.."[WowTracker]|r "..SA_GREY..key.." verwijderd.|r")
        end
    end)

-- [stale afkBtn verwijderd]

-- ── MURLOC ────────────────────────────────────────────────────────────────
local MBtn=CreateFrame("Button","DT_MurlocBtn",UIParent)
MBtn:SetSize(58,58); MBtn:SetPoint("CENTER"); MBtn:SetMovable(true)
MBtn:EnableMouse(true); MBtn:RegisterForDrag("RightButton"); MBtn:SetClampedToScreen(true)
MBtn:SetClampedToScreen(true)
-- Achtergrond ring (donker paars)
MBtn.ring=MBtn:CreateTexture(nil,"BACKGROUND")
MBtn.ring:SetAllPoints()
MBtn.ring:SetColorTexture(0,0,0,0)  -- volledig transparant
-- Logo texture
MBtn.tex=MBtn:CreateTexture(nil,"ARTWORK")
MBtn.tex:SetAllPoints()
MBtn.tex:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")
-- Hover tooltip
MBtn:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffa335eeSlayer Alliance|r  |cff887799DelveTracker v2.7.0|r")
    GameTooltip:AddLine("|cff44aacc[Links]|r  |cff887799Open/Sluit tracker|r")
    GameTooltip:AddLine("|cff44aacc[Rechts]|r  |cff887799Menu|r")
    GameTooltip:AddLine("|cff44aacc[R-drag]|r  |cff887799Verplaats knop|r")
    GameTooltip:Show()
end)
MBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)
local function DT_OpenMurlocMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(SA_PURPLE.."Slayer Alliance|r  "..SA_GREY.."v2.7.0|r")

        -- ── CHARACTERS ───────────────────────────────────
        root:CreateTitle(SA_GOLD.."Characters|r")
        root:CreateButton("|cffffffff⚔  Delves|r  "..SA_GREY.."(lijstoverzicht)|r",
            function() ShowTab(2) end)
        root:CreateButton("|cffffffff📖  Registry|r  "..SA_GREY.."(XL karakter index)|r",
            function()
                local reg = _G["DT_RegistryFrame"]
                if reg then if reg:IsShown() then reg:Hide() else reg:Show() end
                else print(SA_GREY.."[DT] Registry niet geladen|r") end
            end)
        root:CreateButton("|cffffffff🏛  Armory|r  "..SA_GREY.."(huidige karakter)|r",
            function()
                local myKey = (UnitName("player") or "?").."-"..(GetNormalizedRealmName() or "?")
                local data  = DelveTrackerDB.characters and DelveTrackerDB.characters[myKey]
                if DT_Armory_ShowCharacter and data then
                    data.name = UnitName("player"); DT_Armory_ShowCharacter(data)
                else print(SA_GREY.."[DT] Armory niet beschikbaar of geen data|r") end
            end)
        root:CreateButton("|cffffffff👥  Guild|r  "..SA_GREY.."(guild tab)|r",
            function() ShowTab(1) end)

        -- ── TRACKERS ──────────────────────────────────────
        root:CreateTitle(SA_BLUE.."Trackers|r")
        root:CreateButton("|cffffffff🎯  Prey Tracker|r  "..SA_GREY.."(/prey toggle)|r",
            function()
                if addonTable.PreyTrackerEnable and addonTable.PreyTrackerDisable then
                    local PreyUI = _G["DT_PreyUI"]
                    if PreyUI and PreyUI:IsShown() then
                        addonTable.PreyTrackerDisable()
                    else
                        addonTable.PreyTrackerEnable()
                    end
                else
                    if SlashCmdList["DTPREY"] then SlashCmdList["DTPREY"]("") end
                end
            end)
        root:CreateButton("|cffffffff📦  Bounty|r  "..SA_GREY.."(delve bounty tab)|r",
            function() ShowTab(3) end)
        root:CreateButton("|cffffffff🗓  Events|r  "..SA_GREY.."(/dtevents toggle)|r",
            function()
                if SlashCmdList["DTEVENTS"] then SlashCmdList["DTEVENTS"]()
                else print(SA_GREY.."[DT] Events module niet geladen|r") end
            end)
        root:CreateButton("|cffffffff🧵  Cloth Counter|r  "..SA_GREY.."(/cbud toggle)|r",
            function()
                if SlashCmdList["CBUDGET"] then SlashCmdList["CBUDGET"]("")
                else print(SA_GREY.."[DT] ClothCounter niet geladen|r") end
            end)
        root:CreateButton("|cffffffff🐾  Skin & Rare|r  "..SA_GREY.."(Majestic Tracker)|r",
            function()
                local f = _G["MajesticTrackerFrame"]
                if f then if f:IsShown() then f:Hide() else f:Show() end
                else print(SA_GREY.."[DT] SkinNRare niet geladen|r") end
            end)
        root:CreateButton("|cffffffff🔒  Lockout|r  "..SA_GREY.."(/dtlockout toggle)|r",
            function()
                if SlashCmdList["DTLOCKOUT"] then SlashCmdList["DTLOCKOUT"]()
                else print(SA_GREY.."[DT] Lockout niet geladen|r") end
            end)

        -- ── SETTINGS ──────────────────────────────────────
        root:CreateTitle(SA_PURPLE.."Settings|r")
        root:CreateButton("|cffffffff⚙  Admin Panel|r  "..SA_GREY.."(alle instellingen)|r",
            function() Settings.OpenToCategory(category:GetID()) end)
        root:CreateButton("|cffffffff🔧  Debug Console|r  "..SA_GREY.."(/dtdebug toggle)|r",
            function()
                local f = _G["DT_DebugFrame"]
                if f then if f:IsShown() then f:Hide() else f:Show() end
                else print(SA_GREY.."[DT] Debugger niet geladen|r") end
            end)
        root:CreateButton("|cffffffff💬  Exchange Bot|r  "..SA_GREY.."(/cbot toggle)|r",
            function()
                local f = _G["DT_ExchangeFrame"]
                if f then if f:IsShown() then f:Hide() else f:Show() end
                else print(SA_GREY.."[DT] ExchangeBot niet geladen|r") end
            end)

        -- ── SYSTEEM ───────────────────────────────────────
        root:CreateTitle(SA_GREY.."Systeem|r")
        root:CreateButton("Herpositioneer Murloc",
            function() MBtn:ClearAllPoints(); MBtn:SetPoint("CENTER") end)
        root:CreateButton("Reload UI",
            function() ReloadUI() end)
        root:CreateButton("Sluit venster",
            function() UI:Hide() end)
    end)
end
MBtn:SetScript("OnClick",function(self,btn)
    if btn=="LeftButton" then
        PlaySound(6449)
        if UI:IsShown() then UI:Hide() else ShowTab(activeTabID) end
    else DT_OpenMurlocMenu(self) end
end)
MBtn:SetScript("OnDragStart",MBtn.StartMoving)
MBtn:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    local _,_,_,x,y=self:GetPoint(); DelveTrackerDB.murlocPos={x=x,y=y}
end)

-- ── SLASH COMMANDS ────────────────────────────────────────────────────────
-- WowTracker slash commands — /wt als hoofd prefix (geen conflict met andere addons)
-- Oude /dt commands blijven werken als alias voor backward compatibility
SLASH_WTMAIN1="/wt";     SLASH_WTMAIN2="/wowtracker"; SLASH_WTMAIN3="/dt"; SLASH_WTMAIN4="/delves"
SLASH_WTAB11="/wt1";    SLASH_WTAB12="/wt guild";  SLASH_WTAB13="/dt1"; SLASH_WTAB14="/tb1"
SLASH_WTAB21="/wt2";    SLASH_WTAB22="/wt delves"; SLASH_WTAB23="/dt2"; SLASH_WTAB24="/tb2"
SLASH_WTAB31="/wt3";    SLASH_WTAB32="/wt bounty"; SLASH_WTAB33="/dt3"; SLASH_WTAB34="/tb3"
SLASH_WTAB41="/wt4";    SLASH_WTAB42="/wt roster";   SLASH_WTAB43="/wtroster"
SLASH_WTAB51="/wt5";    SLASH_WTAB52="/wt armory";   SLASH_WTAB53="/wtarmory"
SLASH_WTAB61="/wt6";    SLASH_WTAB62="/wt currency"; SLASH_WTAB63="/wtcurrency"
SLASH_WTRELOAD1="/wt-reload"; SLASH_WTMEM1="/wt-mem"; SLASH_WTCOMBAT1="/wt-combat"
-- Legacy aliases
SLASH_DTRELOAD1="/dtreload"; SLASH_DTMEM1="/dtmem"; SLASH_DTCOMBAT1="/dtcombat"

SlashCmdList["WTMAIN"]=function(msg)
    msg=(msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    if     msg=="1" or msg=="guild"   then ShowTab(1)
    elseif msg=="2" or msg=="delves"  then ShowTab(2)
    elseif msg=="3" or msg=="bounty"  then ShowTab(3)
    elseif msg=="afk" and DT_CustomAFK_Frame then DT_CustomAFK_Frame:Show()
    elseif UI:IsShown() then UI:Hide()
    else ShowTab(activeTabID) end
end
SlashCmdList["WTAB1"]=function() ShowTab(1) end
SlashCmdList["WTAB2"]=function() ShowTab(2) end
SlashCmdList["WTAB3"]=function() ShowTab(3) end
SlashCmdList["WTAB4"]=function() ShowTab(4) end
SlashCmdList["WTAB5"]=function() ShowTab(5) end
SlashCmdList["WTAB6"]=function() ShowTab(6) end
SlashCmdList["WTRELOAD"]=function() ReloadUI() end
SlashCmdList["WTMEM"]=function()
    if C_AddOns and C_AddOns.UpdateAddOnMemoryUsage then C_AddOns.UpdateAddOnMemoryUsage() end
    local m=(C_AddOns and C_AddOns.GetAddOnMemoryUsage and C_AddOns.GetAddOnMemoryUsage("DelveTracker")) or 0
    print(string.format(SA_PURPLE.."[DelveTracker]|r Geheugen: %.1f KB",m))
end
SlashCmdList["WTCOMBAT"]=function()
    DelveTrackerDB.enableCombatAlert=not DelveTrackerDB.enableCombatAlert
    print(SA_PURPLE.."[DelveTracker]|r Combat alert: "
        ..(DelveTrackerDB.enableCombatAlert and "|cff44cc66AAN|r" or "|cffcc4444UIT|r"))
end

-- ── EVENTS ────────────────────────────────────────────────────────────────
UI:RegisterEvent("PLAYER_LOGIN")
UI:RegisterEvent("PLAYER_ENTERING_WORLD")
UI:RegisterEvent("WEEKLY_REWARDS_UPDATE")
UI:RegisterEvent("PLAYER_MONEY")

UI:SetScript("OnEvent",function(self,event)
    DelveTrackerDB.characters=DelveTrackerDB.characters or {}
    DelveTrackerDB.PluginStates=DelveTrackerDB.PluginStates or {}
    if event=="PLAYER_LOGIN" then
        if DelveTrackerDB.mainScale then
            UI:SetScale(DelveTrackerDB.mainScale)
            scaleValTxt:SetText(string.format("%.2f",DelveTrackerDB.mainScale))
        end
        if DelveTrackerDB.mScale then MBtn:SetScale(DelveTrackerDB.mScale) end
        if DelveTrackerDB.murlocPos then
            local p=DelveTrackerDB.murlocPos
            MBtn:ClearAllPoints(); MBtn:SetPoint("CENTER",UIParent,"CENTER",p.x or 0,p.y or 0)
        end
        if DelveTrackerDB.mainPos then
            local p=DelveTrackerDB.mainPos
            UI:ClearAllPoints(); UI:SetPoint(p.pt or "CENTER",UIParent,p.rpt or "CENTER",p.x or 0,p.y or 0)
        end
        tickerLastT=GetTime(); tickerDirty=true
        TickerClock:SetText(string.format(SA_GOLD.."%s|r",date("%H:%M:%S")))
    end
    if event=="PLAYER_ENTERING_WORLD" or event=="WEEKLY_REWARDS_UPDATE"
    or event=="PLAYER_MONEY" or event=="PLAYER_LOGIN" then
        ScanDelves()
        if Tab2:IsShown() then UpdateCharacterList() end
        tickerDirty=true
        if event=="PLAYER_LOGIN" and IsInGuild() then GuildRoster() end
    end
end)

-- ============================================================================
-- FILE CARD — DelveTracker.lua | v17.0 | 2026-06-07
-- Role  : Core UI — main frame 760px, event ticker, scaling, tabs, plugin API
-- Status: Production · Retail 12.0.5.67314 Midnight
-- Author: DieOuwe · Slayer Alliance · slayeralliance.com
-- ============================================================================
