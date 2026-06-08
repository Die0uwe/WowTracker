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

    -- Abundance delve modifier
    if ts.events ~= false then
        local abData = DT_GetAbundanceData and DT_GetAbundanceData()
        if abData and abData.active then
            local chipTxt = SA_GOLD.."✦ Abundance ACTIEF|r  "..SA_GREY.."(Shard of Dundun beschikbaar)|r"
            if abData.timedEvents and #abData.timedEvents > 0 then
                local ev = abData.timedEvents[1]
                local rem = ev.timeRemaining and math.floor(ev.timeRemaining/60) or 0
                chipTxt = SA_GOLD.."✦ Abundance: "..rem.."min|r  "..SA_GREY.."Chip vendor actief|r"
            end
            table.insert(parts, chipTxt)
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

-- Header knoppen: X · Tandwiel · [Theme] [Lang] — rechtsboven op één lijn
local HDR_BTN_Y = -(TICKER_H + math.floor(HEADER_H/2) - 11)
local HDR_BTN_SZ = 22

-- X Sluiten
UI.close = CreateFrame("Button",nil,UI,"UIPanelCloseButton")
UI.close:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.close:SetPoint("TOPRIGHT",UI,"TOPRIGHT",2,HDR_BTN_Y)

-- Tandwiel (Settings)
UI.settingsBtn = CreateFrame("Button",nil,UI,"BackdropTemplate")
UI.settingsBtn:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.settingsBtn:SetPoint("RIGHT",UI.close,"LEFT",-3,0)
UI.settingsBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
UI.settingsBtn:SetBackdropColor(0.08,0.04,0.14,0.9)
UI.settingsBtn:SetBackdropBorderColor(0.40,0.10,0.65,0.8)
local sIco=UI.settingsBtn:CreateFontString(nil,"OVERLAY")
sIco:SetFont(C_2002,14,"OUTLINE"); sIco:SetPoint("CENTER")
sIco:SetText(SA_PURPLE.."⚙|r")
UI.settingsBtn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.25,1.0,1) end)
UI.settingsBtn:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.40,0.10,0.65,0.8) end)

-- Theme knop
UI.themeBtn = CreateFrame("Button",nil,UI,"BackdropTemplate")
UI.themeBtn:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.themeBtn:SetPoint("RIGHT",UI.settingsBtn,"LEFT",-3,0)
UI.themeBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
UI.themeBtn:SetBackdropColor(0.08,0.04,0.14,0.9)
UI.themeBtn:SetBackdropBorderColor(0.40,0.10,0.65,0.8)
local tIco=UI.themeBtn:CreateFontString(nil,"OVERLAY")
tIco:SetFont(C_2002,11,"OUTLINE"); tIco:SetPoint("CENTER")
tIco:SetText("|cff44aaff🎨|r")
UI.themeBtn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.25,1.0,1) end)
UI.themeBtn:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.40,0.10,0.65,0.8) end)
UI.themeBtn:SetScript("OnClick",function(self)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    local themes = {
        {name="SA Dark (standaard)", r=0.04,g=0.02,b=0.08, border={0.25,0.07,0.40}},
        {name="ProfBuddy Paars",     r=0.06,g=0.02,b=0.12, border={0.45,0.10,0.70}},
        {name="MailVault Blauw",     r=0.02,g=0.04,b=0.12, border={0.10,0.25,0.60}},
        {name="Nacht Zwart",         r=0.02,g=0.02,b=0.04, border={0.20,0.20,0.20}},
    }
    MenuUtil.CreateContextMenu(self,function(_,root)
        root:CreateTitle(SA_PURPLE.."Thema kiezen|r")
        for _,t in ipairs(themes) do
            local th=t
            root:CreateButton(th.name,function()
                DelveTrackerDB.theme={bg={th.r,th.g,th.b}, border=th.border, name=th.name}
                UI:SetBackdropColor(th.r,th.g,th.b,0.97)
                UI:SetBackdropBorderColor(th.border[1],th.border[2],th.border[3],1)
                print(SA_PURPLE.."[WowTracker] Thema: "..th.name.."|r")
            end)
        end
    end)
end)

-- Taal knop
UI.langBtn = CreateFrame("Button",nil,UI,"BackdropTemplate")
UI.langBtn:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.langBtn:SetPoint("RIGHT",UI.themeBtn,"LEFT",-3,0)
UI.langBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
UI.langBtn:SetBackdropColor(0.08,0.04,0.14,0.9)
UI.langBtn:SetBackdropBorderColor(0.40,0.10,0.65,0.8)
local lIco=UI.langBtn:CreateFontString(nil,"OVERLAY")
lIco:SetFont(C_2002,9,"OUTLINE"); lIco:SetPoint("CENTER")
lIco:SetText("|cff44ffaa🌐|r")
UI.langBtn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.25,1.0,1) end)
UI.langBtn:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.40,0.10,0.65,0.8) end)
-- Expose als global referentie voor andere plugins (Registry B knop)
DelveTrackerFrame.langBtn  = UI.langBtn
DelveTrackerFrame.themeBtn = UI.themeBtn

UI.langBtn:SetScript("OnClick",function(self)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    local langs = {"Nederlands","English","Deutsch","Français","Español"}
    MenuUtil.CreateContextMenu(self,function(_,root)
        root:CreateTitle(SA_BLUE.."Taal / Language|r")
        for _,lang in ipairs(langs) do
            local l=lang
            root:CreateButton(l,function()
                DelveTrackerDB.language=l
                print(SA_PURPLE.."[WowTracker] Taal: "..l.." (herlaad UI voor effect)|r")
            end)
        end
    end)
end)

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
Tab1.guildName:SetFont(C_2002,26,"OUTLINE")  -- was 20, nu groter
Tab1.guildName:SetJustifyH("CENTER")
Tab1.guildName:SetPoint("TOP",Tab1,"TOPLEFT",GUILD_LEFT_W/2,-14)
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
Tab1.motdText:SetWidth(GUILD_LEFT_W-60)
Tab1.motdText:SetJustifyH("CENTER")
Tab1.motdText:SetWordWrap(true)
Tab1.motdText:SetTextColor(0.85,0.85,0.85,1)
Tab1.motdText:SetText(SA_GREY.."Laden...|r")
-- MOTD hoogte begrenzen — max tot halverwege de tab (Kelsey staat onderin)
Tab1.motdText:SetMaxLines(4)

-- ── GUILD TAB IMAGES ─────────────────────────────────────────────────────
-- Layout:
--   Kelsey: groot centraal als feature image (ARTWORK, hoge alpha)
--   DieOuwe: klein, rechtsonder linker kolom, gespiegeld, wijst naar binnen
--   Logo: subtiel watermark linksonder

-- Kelsey kleiner — minder ruimte innemen zodat tekst beter past
Tab1.img=Tab1:CreateTexture(nil,"ARTWORK")
Tab1.img:SetSize(140,140)  -- was 220, nu kleiner
Tab1.img:SetPoint("BOTTOMLEFT",Tab1,"BOTTOMLEFT",20,30)
Tab1.img:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\kelsey.tga")
Tab1.img:SetAlpha(0.90)

-- DieOuwe: klein, rechterhoek van linker kolom, gespiegeld (wijst naar binnen)
Tab1.dieouwe=Tab1:CreateTexture(nil,"ARTWORK")
Tab1.dieouwe:SetSize(80,138)  -- proportioneel kleiner
Tab1.dieouwe:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMLEFT",GUILD_LEFT_W-4,8)
Tab1.dieouwe:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\Dieouwe.tga")
Tab1.dieouwe:SetAlpha(0.75)
-- Horizontaal spiegelen (4-arg): left=1,right=0,top=0,bottom=1
-- Origineel kijkt rechts → gespiegeld kijkt naar links (naar binnen)
Tab1.dieouwe:SetTexCoord(1,0,0,1)

-- Logo watermark links midden — subtiel
Tab1.logoWM=Tab1:CreateTexture(nil,"BACKGROUND")
Tab1.logoWM:SetSize(90,90)
Tab1.logoWM:SetPoint("BOTTOMLEFT",Tab1,"BOTTOMLEFT",8,8)
Tab1.logoWM:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")
Tab1.logoWM:SetAlpha(0.12)

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

-- 1 scroller over volledige breedte, 2-koloms tegel layout
local COL_W=math.floor((UI_W-50)/2)
local scroll=CreateFrame("ScrollFrame","DT_Scroll",Tab2,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",Tab2,"TOPLEFT",1,-34)
scroll:SetPoint("BOTTOMRIGHT",Tab2,"BOTTOMRIGHT",-22,4)
scroll.content=CreateFrame("Frame",nil,scroll)
scroll.content:SetSize(UI_W-46,1)
scroll:SetScrollChild(scroll.content)
scroll.content.rows={}
-- DT_Scroll2 alias zodat kolom 2 code nog werkt
local scroll2_alias = scroll  -- zelfde scroller, kolom 2 gebruikt xPos offset

-- ── TAB 3: BOUNTY — volle breedte ────────────────────────────────────────
Tab3.PluginArea=CreateFrame("Frame","DT_BountyArea",Tab3)
Tab3.PluginArea:SetPoint("TOPLEFT",Tab3,"TOPLEFT",0,0)
Tab3.PluginArea:SetPoint("BOTTOMRIGHT",Tab3,"BOTTOMRIGHT",0,0)
-- QuickSet legt zijn content in Tab3.PluginArea centraal
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
Tab6.searchBox:SetText("Filter currency naam...")
Tab6.searchBox:SetAutoFocus(false)
Tab6.searchBox:SetScript("OnEditFocusGained",function(s)
    if s:GetText()=="Filter currency naam..." then s:SetText("") end
end)
Tab6.searchBox:SetScript("OnEditFocusLost",function(s)
    if s:GetText()=="" then s:SetText("Filter currency naam...") end
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
-- Roster ProfessionBuddy-stijl: kaartjes per karakter v2.0
-- Race portrait + spec icoon + iLvl groot + professions onderaan
local ROSTER_CARD_W = 230  -- 3 cols * 230 + 2*8 = 706px
local ROSTER_CARD_H = 130  -- hoger voor profession rij + spec in hoek
local ROSTER_COLS   = 3  -- 3 cols past binnen 760px UI
local ROSTER_GAP    = 8

-- Race icon lookup (Achievement_Character_{race}_{faction})
local RACE_ICON_MAP = {
    ["Human"]       = "human",
    ["Dwarf"]       = "dwarf",
    ["NightElf"]    = "nightelf",
    ["Gnome"]       = "gnome",
    ["Draenei"]     = "draenei",
    ["Worgen"]      = "worgen",
    ["Pandaren"]    = "pandaren",
    ["VoidElf"]     = "voidelf",
    ["LightforgedDraenei"] = "lightforgeddraenei",
    ["DarkIronDwarf"] = "darkirondwarf",
    ["KulTiran"]    = "kultiran",
    ["Mechagnome"]  = "mechagnome",
    ["Orc"]         = "orc",
    ["Undead"]      = "undead",
    ["Tauren"]      = "tauren",
    ["Troll"]       = "troll",
    ["BloodElf"]    = "bloodelf",
    ["Goblin"]      = "goblin",
    ["Nightborne"]  = "nightborne",
    ["HighmountainTauren"] = "highmountaintauren",
    ["MagharOrc"]   = "magharorc",
    ["ZandalariTroll"] = "zandalaritroll",
    ["Vulpera"]     = "vulpera",
    ["Dracthyr"]    = "dracthyr",
    ["Haranir"]     = "haranir",
}

WT_UpdateRoster = function()
    if not (Tab4.scroll and Tab4.scroll.content) then return end

    -- Verberg oude kaartjes
    for _,row in pairs(Tab4.scroll.content.rows or {}) do
        if type(row)=="table" then for _,c in pairs(row) do if c and c.Hide then c:Hide() end end
        elseif row and row.Hide then row:Hide() end
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

        local col = (i-1) % ROSTER_COLS
        local row = math.floor((i-1) / ROSTER_COLS)
        local xPos = col * (ROSTER_CARD_W + ROSTER_GAP)
        local yPos = -(row * (ROSTER_CARD_H + ROSTER_GAP))

        local card = Tab4.scroll.content.rows[i]
        if not card then
            card = CreateFrame("Button",nil,Tab4.scroll.content,"BackdropTemplate")
            card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        end
        card:SetSize(ROSTER_CARD_W, ROSTER_CARD_H)
        card:SetPoint("TOPLEFT",xPos,yPos)
        card:SetBackdropColor(cc.r*0.10, cc.g*0.10, cc.b*0.10, 0.95)
        card:SetBackdropBorderColor(cc.r*0.65, cc.g*0.65, cc.b*0.65, 0.9)
        card:Show()

        -- ── Race portrait groot linksboven (52x52) ───────────────────
        -- Spec icoon klein in hoek rechtsonder van race portrait
        -- Layout zelfde als ProfessionBuddy: groot race links, tekst rechts
        card.rIcon = card.rIcon or card:CreateTexture(nil,"ARTWORK")
        card.rIcon:SetSize(52,52)
        card.rIcon:SetPoint("TOPLEFT",4,-4)
        local raceKey = RACE_ICON_MAP[data.race or ""] or (data.race or ""):lower():gsub("%s","")
        local facKey  = ((data.faction or ""):lower()=="horde") and "horde" or "alliance"
        -- Primair: Achievement icon (Midnight 12.x)
        local raceIconPath = "Interface\\Icons\\Achievement_Character_"..raceKey.."_"..facKey
        card.rIcon:SetTexture(raceIconPath)
        card.rIcon:SetTexCoord(0.08,0.92,0.08,0.92)
        -- Fallback: als texture leeg is, gebruik klasse kleur als achtergrond
        card.rIcon:SetAlpha(1.0)
        if not card.rIconBg then
            card.rIconBg=card:CreateTexture(nil,"BACKGROUND")
            card.rIconBg:SetSize(52,52)
            card.rIconBg:SetPoint("TOPLEFT",4,-4)
            card.rIconBg:SetColorTexture(cc.r*0.3,cc.g*0.3,cc.b*0.3,0.8)
        end

        -- ── Spec icoon klein in rechtsonder hoek van race portrait (18x18) ──
        card.sIcon = card.sIcon or card:CreateTexture(nil,"OVERLAY")
        card.sIcon:SetSize(18,18)
        -- BOTTOMRIGHT van race portrait, -1px overlap voor hoek-effect
        card.sIcon:SetPoint("BOTTOMRIGHT",card.rIcon,"BOTTOMRIGHT",1,1)
        if data.specID then
            local ok, sid, sname, sdesc, sicon = pcall(GetSpecializationInfoByID, data.specID)
            if ok and sicon then
                card.sIcon:SetTexture(sicon)
            elseif data.class then
                -- Fallback: klasse icoon als spec niet beschikbaar
                local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
                if coords then
                    card.sIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                    card.sIcon:SetTexCoord(unpack(coords))
                end
            end
        end
        card.sIcon:SetTexCoord(0.08,0.92,0.08,0.92)

        -- ── Spec icoon border (kleine donkere rand voor leesbaarheid) ──
        card.sIconBorder = card.sIconBorder or card:CreateTexture(nil,"ARTWORK")
        card.sIconBorder:SetSize(20,20)
        card.sIconBorder:SetPoint("CENTER",card.sIcon,"CENTER",0,0)
        card.sIconBorder:SetColorTexture(0,0,0,0.6)
        card.sIconBorder:SetDrawLayer("ARTWORK",-1)

        -- ── Naam (klasse kleur) rechts van race portrait ──────────────
        card.nm = card.nm or card:CreateFontString(nil,"OVERLAY")
        card.nm:SetFont(C_2002,12,"OUTLINE")
        card.nm:SetPoint("TOPLEFT",card.rIcon,"TOPRIGHT",6,-2)
        card.nm:SetText(string.format("|cff%02x%02x%02x%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255), shortName))

        -- ── Lvl + iLvl rechts van portrait, onder naam ────────────────
        card.sp = card.sp or card:CreateFontString(nil,"OVERLAY")
        card.sp:SetFont(C_2002,9,"")
        card.sp:SetPoint("TOPLEFT",card.nm,"BOTTOMLEFT",0,-1)
        card.sp:SetText(SA_GREY.."Lvl "..(data.level or "?").." · "..(data.spec or "??").."|r")

        -- ── iLvl groot rechtsboven kaartje ────────────────────────────
        card.ilvlTxt = card.ilvlTxt or card:CreateFontString(nil,"OVERLAY")
        card.ilvlTxt:SetFont(C_2002,16,"OUTLINE")
        card.ilvlTxt:SetPoint("TOPRIGHT",-4,-4)
        local ilvl = data.ilvl or 0
        local ilvlCol = ilvl>=270 and "|cffff8800" or ilvl>=250 and "|cff00ff00" or "|cffffffff"
        card.ilvlTxt:SetText(ilvlCol..ilvl.." ilv|r")

        -- ── Delve progress ────────────────────────────────────────────
        card.prgr = card.prgr or card:CreateFontString(nil,"OVERLAY")
        card.prgr:SetFont(C_2002,9,"OUTLINE")
        card.prgr:SetPoint("TOPLEFT",card.sp,"BOTTOMLEFT",0,-3)
        local st=""
        if data.delves then
            for _,v in ipairs(data.delves) do
                st=st..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r "
            end
        end
        card.prgr:SetText(st~="" and st or SA_GREY.."—|r")

        -- ── Gold onderaan rechts ──────────────────────────────────────
        card.gld = card.gld or card:CreateFontString(nil,"OVERLAY")
        card.gld:SetFont(C_2002,10,"OUTLINE")
        card.gld:SetPoint("BOTTOMRIGHT",-4,4)
        card.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        -- ── Faction dot linksonder ────────────────────────────────────
        card.fac = card.fac or card:CreateTexture(nil,"OVERLAY")
        card.fac:SetSize(8,8)
        card.fac:SetPoint("BOTTOMLEFT",4,6)
        if data.faction=="Horde" then card.fac:SetColorTexture(0.8,0.1,0.1,1)
        else card.fac:SetColorTexture(0.1,0.4,0.9,1) end

        -- ── Professions iconen onderaan ───────────────────────────────
        if not card.profRow then card.profRow={} end
        for _,p in ipairs(card.profRow) do if p and p.Hide then p:Hide() end end
        card.profRow={}
        if data.professions and #data.professions>0 then
            for pi,prof in ipairs(data.professions) do
                if pi>4 then break end
                local px = 4+(pi-1)*20
                local pico=card:CreateTexture(nil,"OVERLAY")
                pico:SetSize(18,18)
                pico:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",px,20)
                if prof.icon then pico:SetTexture(prof.icon) end
                pico:SetTexCoord(0.08,0.92,0.08,0.92)
                pico:Show()
                -- Profession tekst tooltip knopje
                local pb=CreateFrame("Button",nil,card)
                pb:SetSize(18,18)
                pb:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",px,20)
                pb._prof=prof
                pb._rank=prof.rank or 0
                pb._max=prof.maxRank or 0
                pb:SetScript("OnEnter",function(s)
                    GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
                    GameTooltip:SetText(SA_GOLD..(s._prof.name or "?"))
                    GameTooltip:AddLine(SA_GREY..s._rank.."/"..s._max.."|r")
                    GameTooltip:Show()
                end)
                pb:SetScript("OnLeave",function() GameTooltip:Hide() end)
                table.insert(card.profRow,pico)
                table.insert(card.profRow,pb)
            end
        end

        -- ── Hover + click ─────────────────────────────────────────────
        local sn,d=shortName,data
        card:SetScript("OnEnter",function(self)
            self:SetBackdropBorderColor(1.0,0.85,0.0,1)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(SA_GOLD..sn)
            GameTooltip:AddLine(SA_GREY..(d.class or "?").." · "..(d.spec or "??").."|r")
            GameTooltip:AddLine(SA_GREY.."iLvl "..(d.ilvl or 0).."|r")
            if d.guild and d.guild~="Geen Guild" then
                GameTooltip:AddLine(SA_BLUE..d.guild.."|r")
            end
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave",function(self)
            self:SetBackdropBorderColor(cc.r*0.65,cc.g*0.65,cc.b*0.65,0.9)
            GameTooltip:Hide()
        end)
        card:SetScript("OnClick",function()
            if DT_Armory_ShowCharacter then
                d.name=sn; DT_Armory_ShowCharacter(d); PlaySound(852)
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

        -- CloseBtn zichtbaar houden maar repositioneren
        if armFrame.closeBtn then
            armFrame.closeBtn:ClearAllPoints()
            armFrame.closeBtn:SetPoint("TOPRIGHT",armFrame,"TOPRIGHT",0,0)
            armFrame.closeBtn:Show()
            -- Close embedded: ga terug naar vorige tab
            armFrame.closeBtn:SetScript("OnClick",function()
                armFrame:Hide()
                if _G["DT_ArmoryStatsPanel"] then _G["DT_ArmoryStatsPanel"]:Hide() end
                Tab5.armoryEmbedded = nil
                armFrame._embedded = nil
                ShowTab(4)  -- terug naar Roster
            end)
        end
        if armFrame.btnPlus  then armFrame.btnPlus:Hide()  end
        if armFrame.btnMinus then armFrame.btnMinus:Hide() end

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

    -- Verberg alle oude frames (veilig: check elk element apart)
    for k,v in pairs(Tab6.scroll.content.crows or {}) do
        if type(v)=="table" then
            -- cards_N is een table van frames
            for _,c in ipairs(v) do
                if type(c)=="userdata" and c.Hide then c:Hide() end
            end
        elseif type(v)=="userdata" and v.Hide then
            v:Hide()
        end
    end
    Tab6.scroll.content.crows = {}

    -- Currency definities — alle expansies van nieuw naar oud
    -- Filter op naam als zoekbalk gevuld
    local curFilter = ""
    if Tab6.searchBox then
        local t = Tab6.searchBox:GetText() or ""
        if t ~= "Filter currency naam..." then curFilter = t:lower() end
    end

    local function getCurInfo(id)
        if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
            local ok,info = pcall(C_CurrencyInfo.GetCurrencyInfo,id)
            if ok and info then return info.iconFileID, info.name end
        end
        return nil, tostring(id)
    end

    -- Volledige lijst alle currencies — gesorteerd op relevantie
    local CUR_DEFS_ALL = {
        -- ── MIDNIGHT (12.x) ──────────────────────────────────────────
        {id=3028, label="Restored Coffer Keys",       col="|cff00ccff", expac="Midnight"},
        {id=3310, label="Coffer Key Shards",           col="|cffffee00", expac="Midnight"},
        {id=3376, label="Shard of Dundun",             col="|cff44cc66", expac="Midnight"},
        {id=3378, label="Dawnlight Manaflux",          col="|cffa335ee", expac="Midnight"},
        {id=3399, label="Unalloyed Abundance",         col="|cff55ff55", expac="Midnight"},
        {id=3403, label="Midnight Reputation Token",   col="|cff00aaff", expac="Midnight"},
        {id=3390, label="Amani Favor",                 col="|cffff8800", expac="Midnight"},
        -- ── THE WAR WITHIN (11.x) ────────────────────────────────────
        {id=2803, label="Resonance Crystals",          col="|cff88ddff", expac="War Within"},
        {id=2778, label="Weathered Harbinger Crest",   col="|cff99aa77", expac="War Within"},
        {id=2779, label="Carved Harbinger Crest",      col="|cff88bb55", expac="War Within"},
        {id=2780, label="Runed Harbinger Crest",       col="|cff77cc44", expac="War Within"},
        {id=2781, label="Gilded Harbinger Crest",      col="|cffccaa00", expac="War Within"},
        {id=2815, label="Valorstones",                 col="|cff4488cc", expac="War Within"},
        {id=2778, label="Undercoin",                   col="|cff665588", expac="War Within"},
        -- ── DRAGONFLIGHT (10.x) ──────────────────────────────────────
        {id=2245, label="Dragon Isles Supplies",       col="|cff55aa88", expac="Dragonflight"},
        {id=2123, label="Valor",                       col="|cff4488dd", expac="Dragonflight"},
        {id=2119, label="Conquest",                    col="|cffdd4444", expac="Dragonflight"},
        {id=2032, label="Primal Chaos",                col="|cffff6600", expac="Dragonflight"},
        {id=2003, label="Dragon Isles Renown",         col="|cff55cc88", expac="Dragonflight"},
        -- ── SHADOWLANDS ──────────────────────────────────────────────
        {id=1885, label="Anima",                       col="|cff8855ff", expac="Shadowlands"},
        {id=1906, label="Soul Cinders",                col="|cff4455dd", expac="Shadowlands"},
        {id=1767, label="Stygia",                      col="|cff2244aa", expac="Shadowlands"},
        {id=1828, label="Grateful Offering",           col="|cffddaa22", expac="Shadowlands"},
        -- ── BATTLE FOR AZEROTH ───────────────────────────────────────
        {id=1560, label="War Resources",               col="|cffcc4400", expac="BfA"},
        {id=1159, label="Azerite",                     col="|cffff8800", expac="BfA"},
        -- ── PvP ──────────────────────────────────────────────────────
        {id=1792, label="Honor",                       col="|cffaaffaa", expac="PvP"},
        {id=1602, label="Conquest",                    col="|cffff4444", expac="PvP"},
    }

    -- Filter op naam als curFilter gevuld
    local CUR_DEFS = {}
    local seenIDs = {}
    for _,def in ipairs(CUR_DEFS_ALL) do
        if not seenIDs[def.id] then
            if curFilter == "" or def.label:lower():find(curFilter,1,true) or (def.expac and def.expac:lower():find(curFilter,1,true)) then
                -- Check of karakter echt iets heeft
                table.insert(CUR_DEFS, def)
                seenIDs[def.id] = true
            end
        end
    end

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

    local TILE_W = 56  -- kleiner voor meer tiles zichtbaar
    local TILE_H = 60
    local TILE_G = 4
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
-- Debug knop rechtsonder naast +/- knoppen, BOVEN de discord box
local function MakeDebugBtn()
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(BTN_W,BTN_H)
    -- Rechts naast de +/- schaal knoppen (schaal eindigt op -8, debug er net links van)
    b:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-52-BTN_W,BTN_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.06,0.03,0.10,0.95)
    b:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText("|cff887799Debug|r")
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

    -- Scan beroepen (professions) voor huidig karakter
    d.professions = {}
    local prof1, prof2, arch, fish, cook = GetProfessions()
    for _,profIndex in ipairs({prof1, prof2, arch, fish, cook}) do
        if profIndex then
            local name, icon, rank, maxRank, numSpells, spelloffset, skillLine, rankMod, specializationIndex = GetProfessionInfo(profIndex)
            if name then
                table.insert(d.professions, {
                    name    = name,
                    icon    = icon,
                    rank    = rank or 0,
                    maxRank = maxRank or 0,
                    skillLine = skillLine,
                })
            end
        end
    end
    -- Spec ID opslaan voor spec iconen
    local specIndex = GetSpecialization()
    if specIndex then
        local specID = GetSpecializationInfo(specIndex)
        d.specID = specID
    end
    d.race = UnitRace("player") or d.race
    d.faction = UnitFactionGroup("player") or d.faction
end

UpdateCharacterList = function()
    -- Herlaad suggesties
    if DT_SuggestDrop then DT_SuggestDrop:Hide() end
    if not (DT_Scroll and DT_Scroll.content) then return end
    local filter=(DT_SearchBox and DT_SearchBox:GetText() or ""):lower()
    if filter=="🔍 zoek karakter..." then filter="" end
    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        if filter=="" or k:lower():find(filter,1,true) then
            table.insert(sorted,k)
        end
    end
    table.sort(sorted)

    -- Verberg alle oude rijen
    for _,row in pairs(DT_Scroll.content.rows) do row:Hide() end
    DT_Scroll.content.rows = {}

    local ROW_H = 60
    local COLS  = 2
    local COL   = math.floor((UI_W-50)/2)
    local GAP   = 4

    for i,key in ipairs(sorted) do
        local data = DelveTrackerDB.characters[key]
        local shortName = key:match("([^-]+)") or key
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}

        -- 2-koloms: col 0=links, col 1=rechts
        local col = (i-1) % COLS
        local row = math.floor((i-1) / COLS)
        local xPos = col * (COL + GAP)
        local yPos = -(row * (ROW_H + 3))

        local r = DT_Scroll.content.rows[i]
        if not r then
            r = CreateFrame("Button",nil,DT_Scroll.content,"BackdropTemplate")
            r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        end
        r:SetSize(COL, ROW_H)
        r:SetPoint("TOPLEFT", xPos, yPos)
        r:SetBackdropColor(0.08,0.04,0.12,0.8)
        r:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
        r:Show()

        -- Faction
        r.fLet = r.fLet or r:CreateFontString(nil,"OVERLAY")
        r.fLet:SetFont(C_2002,14,"OUTLINE")
        r.fLet:SetPoint("LEFT",8,0)
        r.fLet:SetText(data.faction=="Horde" and "|cffff4444H|r" or "|cff4488ffA|r")

        -- Klasse icon
        r.cIcon = r.cIcon or r:CreateTexture(nil,"OVERLAY")
        r.cIcon:SetSize(36,36)
        r.cIcon:SetPoint("LEFT",r.fLet,"RIGHT",8,0)
        local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
        if coords then
            r.cIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
            r.cIcon:SetTexCoord(unpack(coords))
        end

        -- Naam
        r.nm = r.nm or r:CreateFontString(nil,"OVERLAY")
        r.nm:SetFont(C_2002,12,"OUTLINE")
        r.nm:SetPoint("LEFT",r.cIcon,"RIGHT",10,8)
        r.nm:SetText(SA_GOLD..shortName.."|r")

        -- Spec
        r.sp = r.sp or r:CreateFontString(nil,"OVERLAY")
        r.sp:SetFont(C_2002,9,"")
        r.sp:SetPoint("LEFT",r.cIcon,"RIGHT",10,-4)
        r.sp:SetText(SA_GREY..(data.spec or "??").." · iLvl "..(data.ilvl or 0).."|r")

        -- Delve progress
        r.prgr = r.prgr or r:CreateFontString(nil,"OVERLAY")
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
        r.gld = r.gld or r:CreateFontString(nil,"OVERLAY")
        r.gld:SetFont(C_2002,11,"OUTLINE")
        r.gld:SetPoint("RIGHT",-10,0)
        r.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        -- iLvl badge
        r.ilv = r.ilv or r:CreateFontString(nil,"OVERLAY")
        r.ilv:SetFont(C_2002,10,"OUTLINE")
        r.ilv:SetPoint("RIGHT",r.gld,"LEFT",-12,0)
        r.ilv:SetText("|cff00ff00"..(data.ilvl or 0).."|r")

        -- Tooltip — zelfde voor beide kolommen
        local sn,d = shortName,data
        r:SetScript("OnEnter",function(self)
            self:SetBackdropColor(0.14,0.07,0.22,1)
            self:SetBackdropBorderColor(0.50,0.15,0.80,1)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(SA_GOLD..sn)
            GameTooltip:AddLine(SA_GREY..(d.class or "?").." · "..(d.spec or "??").."|r")
            if d.delves then
                local ds=""
                for _,v in ipairs(d.delves) do
                    ds=ds..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r  "
                end
                if ds~="" then GameTooltip:AddLine(ds) end
            end
            GameTooltip:AddLine(SA_GOLD..math.floor((d.money or 0)/10000).."g|r")
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave",function(self)
            self:SetBackdropColor(0.08,0.04,0.12,0.8)
            self:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
            GameTooltip:Hide()
        end)
        r:SetScript("OnClick",function()
            if DT_Armory_ShowCharacter then
                d.name=sn; DT_Armory_ShowCharacter(d); PlaySound(852)
            end
        end)

        DT_Scroll.content.rows[i] = r
    end

    -- Hoogte: aantal rijen * (ROW_H+3)
    local nRows = math.ceil(#sorted / COLS)
    DT_Scroll.content:SetHeight(nRows*(ROW_H+3)+4)
end


