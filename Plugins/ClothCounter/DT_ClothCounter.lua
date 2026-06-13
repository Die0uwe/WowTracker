-- =========================================================================
-- DT_ClothWidget v14.5.1 — WARBAND EDITION
-- World of Warcraft: Midnight 12.0.5 / build 67314
-- =========================================================================
-- .toc requirements:
--   ## SavedVariables: ClothWarbandDB
--   ## SavedVariablesPerCharacter: ClothCharDB
--
-- Commands: /cbud  or  /cloth
--   /cbud           — toggle main widget
--   /cbud archive   — toggle archive window
--   /cbud reset     — reset session (with confirmation)
--   /cbud scan      — manually re-scan profession cooldowns
--   /cbud clear     — wipe all warband data (with confirmation)
--   /cbud help      — show command reference
-- =========================================================================

local ADDON_NAME = ...   -- echte addon-mapnaam ("WowTracker") via vararg
local VERSION    = "14.5.1"  -- Removed Bright Linen Bolt (no cooldown)

local CLOTH_DATA = {
    { name="Bright Linen", id=236963, color={0.95,0.88,0.55},
      tiers={[236963]=2,[236965]=3}, extra={} },
    { name="Sunfire Silk",  id=237015, color={1.0,0.50,0.20},
      tiers={[237015]=2,[237016]=3}, extra={} },
    { name="Arcanoweave",   id=237018, color={0.65,0.40,1.0},
      tiers={[237018]=2,[237017]=3}, extra={} },
}

-- Central item→cloth lookup (built once, no duplicate matches possible)
local ITEM_LOOKUP = {}
-- BUG FIX: process tiers BEFORE registering f.id as tier=1.
-- Original code registered f.id as tier=1 first, then the
-- "first entry wins" guard blocked the correct tier=2 (Silver)
-- overwrite → Silver items were counted in total but never in t2.
for _,f in ipairs(CLOTH_DATA) do
    -- 1. Explicit tiers always take priority (no guard — overwrite allowed)
    if f.tiers then
        for itemID,tier in pairs(f.tiers) do
            ITEM_LOOKUP[itemID] = { cloth=f.name, tier=tier }
        end
    end
    -- 2. Extra items: secondary fallback (guard kept)
    if f.extra then
        for itemID,tier in pairs(f.extra) do
            if not ITEM_LOOKUP[itemID] then
                ITEM_LOOKUP[itemID] = { cloth=f.name, tier=tier }
            end
        end
    end
    -- 3. f.id as tier=1 fallback only if not already in tiers/extra
    if not ITEM_LOOKUP[f.id] then
        ITEM_LOOKUP[f.id] = { cloth=f.name, tier=1 }
    end
end

local TAILOR_COOLDOWNS = {
    -- Midnight 12.0.5 recipe IDs — verified in-game build 67314
    -- Bright Linen Bolt has NO cooldown — not tracked
    { name="Sunfire Silk Bolt",  recipeID=1228060, cloth="Sunfire Silk",
      color={1.0,0.50,0.20},  duration=86400 },
    { name="Arcanoweave Bolt",   recipeID=1227926, cloth="Arcanoweave",
      color={0.65,0.40,1.0},  duration=86400 },
}

-- ── Drop source data (Midnight 12.0.5) ───────────────────────────────────
-- Midnight zones: Eversong Woods · Zul'Aman · Harandar · Voidstorm
-- ALL three cloth types drop from humanoid mobs across ALL zones.
-- Sunfire Silk and Arcanoweave require 20 KP in Nimble Needlework first.
-- Sorted highest drop rate first. Source: Method.gg farming guide.
-- ─────────────────────────────────────────────────────────────────────────
local CLOTH_SOURCES = {
    ["Bright Linen"] = {
        -- Best solo: any Delve (Grudge Pit = fastest reset in Harandar)
        -- Best group: Zul'Aman Broken Throne — ~200-300 per 30 min
        { type="Delve",      zone="Harandar",           rate="★★★", detail="The Grudge Pit — fastest reset, smallest delve" },
        { type="Open World", zone="Zul'Aman",           rate="★★★", detail="Broken Throne SW — Twilight Blade Cultists" },
        { type="Delve",      zone="Voidstorm",          rate="★★",  detail="Shadowguard Point — larger pulls" },
        { type="Open World", zone="Eversong Woods",     rate="★★",  detail="Humanoid circuit — relaxed farm" },
        { type="Dungeon",    zone="Any Midnight dungeon",rate="★",   detail="All humanoid trash packs" },
    },
    ["Sunfire Silk"] = {
        -- Requires: 20 KP in Nimble Needlework (Tailoring specialisation)
        { type="Delve",      zone="Harandar",           rate="★★★", detail="The Grudge Pit — same circuit as Bright Linen" },
        { type="Open World", zone="Zul'Aman",           rate="★★★", detail="Broken Throne SW — same group farm spot" },
        { type="Delve",      zone="Voidstorm",          rate="★★",  detail="Shadowguard Point — mixed cloth drop" },
        { type="Open World", zone="Harandar",           rate="★★",  detail="Humanoid clusters — Harandar jungle area" },
        { type="Dungeon",    zone="Den of Nalorakk",    rate="★",   detail="Zul'Aman dungeon — humanoid trash" },
    },
    ["Arcanoweave"] = {
        -- Requires: 20 KP in Nimble Needlework (Tailoring specialisation)
        { type="Delve",      zone="Harandar",           rate="★★★", detail="The Grudge Pit — same circuit, all cloth" },
        { type="Open World", zone="Zul'Aman",           rate="★★★", detail="Broken Throne SW — same group farm spot" },
        { type="Open World", zone="Voidstorm",          rate="★★",  detail="Void-touched humanoids near Howling Ridge" },
        { type="Delve",      zone="Eversong Woods",     rate="★★",  detail="Any Eversong delve — humanoid enemies" },
        { type="Dungeon",    zone="Maisara Caverns",    rate="★",   detail="Zul'Aman dungeon — M+ Season 1 rotation" },
    },
}

local CLOTH_SOURCE_COLORS = {
    Delve       = { r=0.40, g=0.80, b=1.00 },
    Dungeon     = { r=1.00, g=0.70, b=0.20 },
    ["Open World"] = { r=0.40, g=1.00, b=0.50 },
}

local QUAL_S  = "|cffc0c0c0[**]|r"
local QUAL_G  = "|cffffd700[***]|r"
local DIVIDER = "|cff3377cc" .. string.rep("-",26) .. "|r"

local T_BOX_W    = 790
local T_HEADER_H = 50     -- taller header for bigger char name
local T_ROW_H    = 50     -- taller rows to fit 33px icon
local T_BAR_H    = 28     -- slightly taller bars
local T_LABEL_X  = 10
local T_BAR_X    = 260    -- pushed right to make room for 33px icon + wider label
local T_BOX_PAD  = 10
local T_BOX_GAP  = 12

-- ── Helpers ──────────────────────────────────────────────────────────────
local function GetSafeIcon(id)
    local _,_,_,_,icon = GetItemInfoInstant(id); return icon or 134400
end
local function FormatTime(s)
    if not s or s<=0 then return "|cff00ee88Ready|r" end
    local h=math.floor(s/3600); local m=math.floor((s%3600)/60); local ss=math.floor(s%60)
    if h>0 then return string.format("%dh %02dm",h,m)
    elseif m>0 then return string.format("%dm %02ds",m,ss)
    else return string.format("%ds",ss) end
end
local function GetDate()
    local t=date("*t")
    return string.format("%04d-%02d-%02d %02d:%02d",t.year,t.month,t.day,t.hour,t.min)
end
local function GetCharKey()
    -- Use GetNormalizedRealmName() for consistency with WowTrackerDB.characters keys
    -- (GetRealmName() can differ on connected realms, causing duplicate entries)
    return (UnitName("player") or "Unknown").."-"..(GetNormalizedRealmName() or GetRealmName() or "Unknown")
end
local function GetShortName(k) return k and k:match("^([^%-]+)") or k or "?" end

-- ── Session ───────────────────────────────────────────────────────────────
local session = { startTime=0, currentZone="", counts={} }
local function ResetSession()
    session.startTime   = GetTime()
    session.currentZone = GetRealZoneText() or "World"
    for _,f in ipairs(CLOTH_DATA) do session.counts[f.name]={total=0,t2=0,t3=0} end
end

-- ── Database ──────────────────────────────────────────────────────────────
local function InitDB()
    ClothWarbandDB        = ClothWarbandDB or {}
    ClothWarbandDB.runs   = ClothWarbandDB.runs   or {}
    ClothWarbandDB.totals = ClothWarbandDB.totals or {}
    ClothWarbandDB.chars  = ClothWarbandDB.chars  or {}
    ClothWarbandDB.pos    = ClothWarbandDB.pos    or {x=0,y=-150}
    ClothWarbandDB.scale  = ClothWarbandDB.scale  or 1.0
    for _,f in ipairs(CLOTH_DATA) do
        ClothWarbandDB.totals[f.name] = ClothWarbandDB.totals[f.name] or 0
    end
    ClothCharDB              = ClothCharDB or {}
    ClothCharDB.hasTailoring = ClothCharDB.hasTailoring or false
    ClothCharDB.cooldowns    = ClothCharDB.cooldowns    or {}
    ClothCharDB.knownRecipes = ClothCharDB.knownRecipes or {}
    local key = GetCharKey()
    if not ClothWarbandDB.chars[key] then
        ClothWarbandDB.chars[key] = {name=UnitName("player") or "?",
            hasTailoring=false, cooldowns={}, knownRecipes={}}
    end
    ClothWarbandDB.chars[key].hasTailoring = ClothCharDB.hasTailoring
    ClothWarbandDB.chars[key].knownRecipes = ClothWarbandDB.chars[key].knownRecipes or {}
    ClothWarbandDB.chars[key].cooldowns    = ClothWarbandDB.chars[key].cooldowns    or {}
end

-- ── Save run ──────────────────────────────────────────────────────────────
local function SaveRun()
    if not ClothWarbandDB then return end
    local tot=0
    for _,f in ipairs(CLOTH_DATA) do tot=tot+session.counts[f.name].total end
    if tot==0 then return end
    local dur=math.max(0,math.floor(GetTime()-session.startTime))
    local entry={zone=session.currentZone,date=GetDate(),duration=dur,char=GetCharKey(),data={}}
    for _,f in ipairs(CLOTH_DATA) do
        local d=session.counts[f.name]
        entry.data[f.name]={total=d.total,t2=d.t2,t3=d.t3}
        ClothWarbandDB.totals[f.name]=(ClothWarbandDB.totals[f.name] or 0)+d.total
    end
    table.insert(ClothWarbandDB.runs,1,entry)
    while #ClothWarbandDB.runs>200 do table.remove(ClothWarbandDB.runs) end
    print(string.format("|cffb58cffClothWidget:|r Saved — |cffffff00%d|r cloth from |cffcc99ff%s|r (%s)",
        tot,session.currentZone,FormatTime(dur)))
end

-- ── UI helpers ────────────────────────────────────────────────────────────
local function ApplyWindowStyle(f,r,g,b)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\ChatFrame\\ChatFrameBackground",edgeSize=2})
    -- v3.2.8 (Fase 3.2): bg uit WTTheme indien beschikbaar
    local bg = WTTheme and WTTheme.bg and WTTheme.bg.main
    if bg then
        f:SetBackdropColor(bg.r, bg.g, bg.b, math.max(bg.a or 0.97, 0.95))
    else
        f:SetBackdropColor(0.03,0.01,0.07,0.97)
    end
    f:SetBackdropBorderColor(r or 0.5,g or 0.22,b or 0.85,1)
end
local function MakeHeaderStripe(parent,h)
    local s=parent:CreateTexture(nil,"BACKGROUND")
    s:SetPoint("TOPLEFT",2,-2); s:SetPoint("TOPRIGHT",-2,-2)
    s:SetHeight(h or 38); s:SetColorTexture(0.10,0.04,0.20,0.98)
    local l=parent:CreateTexture(nil,"ARTWORK")
    l:SetPoint("TOPLEFT",2,-(h or 38)-2); l:SetPoint("TOPRIGHT",-2,-(h or 38)-2)
    l:SetHeight(1); l:SetColorTexture(0.55,0.28,0.90,0.7)
end
local function MakeTitle(parent,text,x,y,size)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetFont("Fonts\\2002.ttf",size or 12,"OUTLINE")
    t:SetPoint("TOPLEFT",x or 12,y or -12); t:SetText(text)
    t:SetShadowOffset(1,-1); t:SetShadowColor(0,0,0,1); return t
end
local function StyleButton(btn,text)
    if not btn.SetBackdrop then Mixin(btn,BackdropTemplateMixin) end
    btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    btn:SetBackdropColor(0.10,0.04,0.18,1)
    btn:SetBackdropBorderColor(0.45,0.22,0.75,0.9)
    btn:SetText(text or "")
    local fs=btn:GetFontString()
    if fs then fs:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); fs:SetTextColor(0.85,0.72,1,1) end
    btn:SetScript("OnEnter",function(s)
        s:SetBackdropColor(0.20,0.08,0.32,1); s:SetBackdropBorderColor(0.80,0.50,1.0,1) end)
    btn:SetScript("OnLeave",function(s)
        s:SetBackdropColor(0.10,0.04,0.18,1); s:SetBackdropBorderColor(0.45,0.22,0.75,0.9) end)
end
local function MakeCloseBtn(parent,onClose)
    local btn=CreateFrame("Button",nil,parent,"BackdropTemplate")
    btn:SetSize(22,22); btn:SetPoint("TOPRIGHT",-6,-8)
    if not btn.SetBackdrop then Mixin(btn,BackdropTemplateMixin) end
    btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    btn:SetBackdropColor(0.22,0.04,0.04,1); btn:SetBackdropBorderColor(0.65,0.18,0.18,1)
    btn:SetText("X")
    local fs=btn:GetFontString()
    if fs then fs:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); fs:SetTextColor(1,0.50,0.50,1) end
    btn:SetScript("OnEnter",function(s)
        s:SetBackdropColor(0.50,0.08,0.08,1); s:SetBackdropBorderColor(1,0.30,0.30,1) end)
    btn:SetScript("OnLeave",function(s)
        s:SetBackdropColor(0.22,0.04,0.04,1); s:SetBackdropBorderColor(0.65,0.18,0.18,1) end)
    btn:SetScript("OnClick",onClose or function() parent:Hide() end)
    return btn
end

-- ── Progress bar ──────────────────────────────────────────────────────────
local function CreateProgressBar(parent,w,h)
    local con=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    con:SetSize(w,h)
    if not con.SetBackdrop then Mixin(con,BackdropTemplateMixin) end
    con:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    con:SetBackdropColor(0.05,0.02,0.10,1)
    con:SetBackdropBorderColor(0.28,0.12,0.48,0.9)
    con._maxW=w-2
    local fill=con:CreateTexture(nil,"ARTWORK")
    fill:SetPoint("TOPLEFT",1,-1); fill:SetPoint("BOTTOMLEFT",1,1)
    fill:SetWidth(1); con.fill=fill
    local shine=con:CreateTexture(nil,"OVERLAY")
    shine:SetPoint("TOPLEFT",1,-1); shine:SetPoint("TOPRIGHT",-1,-1)
    shine:SetHeight(math.max(2,math.floor((h-2)/2))); shine:SetColorTexture(1,1,1,0.07)
    local lbl=con:CreateFontString(nil,"OVERLAY")
    lbl:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); lbl:SetPoint("CENTER",0,0)
    lbl:SetTextColor(1,1,1,1); con.label=lbl
    function con:SetCooldown(rem,dur,name)
        if rem and rem>0 then
            local pct=math.min(rem/(dur or 86400),1)
            self.fill:SetWidth(math.max(1,math.floor(self._maxW*pct)))
            self.fill:SetColorTexture(0.45,0.12,0.88,0.90)
            self.label:SetText("|cffcc99ff"..(name or "").."|r  |cffff9966"..FormatTime(rem).."|r")
        else
            self.fill:SetWidth(self._maxW); self.fill:SetColorTexture(0.12,0.78,0.35,0.88)
            self.label:SetText("|cff00ee88"..(name or "").."  [READY]|r")
        end
    end
    function con:SetNotLearned(name)
        self.fill:SetWidth(self._maxW); self.fill:SetColorTexture(0.14,0.14,0.18,0.55)
        self.label:SetText("|cff666677"..(name or "").."  — Not Learned|r")
    end
    function con:SetUnscanned(name)
        self.fill:SetWidth(self._maxW); self.fill:SetColorTexture(0.10,0.10,0.14,0.35)
        self.label:SetText("|cff555566"..(name or "").."  — Open Professions to scan|r")
    end
    return con
end

-- ── Main widget ───────────────────────────────────────────────────────────
local F=CreateFrame("Frame","ClothWidgetFrame",UIParent,"BackdropTemplate")
-- v3.2.8: live themawissel — beide ClothCounter vensters restylen
if WTTheme and WTTheme.Register then
    WTTheme.Register(function()
        if F then ApplyWindowStyle(F) end
        if Archive then ApplyWindowStyle(Archive) end
    end)
end
F:SetSize(458,195); F:SetPoint("CENTER",0,-150); F:Hide()
F:SetMovable(true); F:EnableMouse(true); F:RegisterForDrag("LeftButton")
F:SetScript("OnDragStart",F.StartMoving)
F:SetScript("OnDragStop",function(s)
    s:StopMovingOrSizing(); local _,_,_,x,y=s:GetPoint()
    if ClothWarbandDB then ClothWarbandDB.pos={x=x,y=y} end end)
F:SetFrameStrata("MEDIUM")
ApplyWindowStyle(F,0.50,0.22,0.88)
MakeHeaderStripe(F,38)
MakeTitle(F,"|cffaa55ffCLOTH|r |cffddbbffCOUNTER|r  |cff554477| Warband|r",12,-11,13)
MakeCloseBtn(F,function() F:Hide() end)

local function MakeTopBtn(parent,text,w,side,rel,ox,oy)
    local btn=CreateFrame("Button",nil,parent,"BackdropTemplate")
    btn:SetSize(w,22); btn:SetPoint(side,rel,ox,oy); StyleButton(btn,text); return btn
end
-- Buttons: positioned from the right, no overlap
F.archiveBtn=MakeTopBtn(F,"ARCHIVE",80,"TOPRIGHT",F,-34,-9)
F.saveBtn   =MakeTopBtn(F,"SAVE",   70,"RIGHT",F.archiveBtn,-84,0)
F.resetBtn  =MakeTopBtn(F,"RESET",  60,"RIGHT",F.saveBtn,-74,0)

-- Compact transparency toggle button (eye icon area, bottom-left of header)
F.compactBtn=CreateFrame("Button",nil,F,"BackdropTemplate")
F.compactBtn:SetSize(20,20); F.compactBtn:SetPoint("BOTTOMRIGHT",-6,6)
if not F.compactBtn.SetBackdrop then Mixin(F.compactBtn,BackdropTemplateMixin) end
F.compactBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
    edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
F.compactBtn:SetBackdropColor(0.12,0.05,0.22,1)
F.compactBtn:SetBackdropBorderColor(0.45,0.22,0.75,0.8)
F.compactBtn:SetText("◎")
local cfs=F.compactBtn:GetFontString()
if cfs then cfs:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); cfs:SetTextColor(0.70,0.55,1,1) end
F.compactBtn:SetScript("OnEnter",function(s)
    s:SetBackdropColor(0.22,0.08,0.38,1); s:SetBackdropBorderColor(0.80,0.50,1.0,1)
    GameTooltip:SetOwner(s,"ANCHOR_BOTTOM"); GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffcc99ffCompact mode|r")
    GameTooltip:AddLine("|cff888888Hides chrome — shows only cloth tiles|r",1,1,1)
    GameTooltip:Show()
end)
F.compactBtn:SetScript("OnLeave",function(s)
    s:SetBackdropColor(0.12,0.05,0.22,1); s:SetBackdropBorderColor(0.45,0.22,0.75,0.8)
    GameTooltip:Hide()
end)

-- Elements to hide in compact mode
local compactHide = {}  -- filled after they are created
F._compact = false
local function ApplyCompactMode(on)
    F._compact = on
    for _,el in ipairs(compactHide) do
        if on then el:Hide() else el:Show() end
    end
    if on then
        F:SetBackdropColor(0,0,0,0); F:SetBackdropBorderColor(0,0,0,0)
        F.compactBtn:SetBackdropColor(0.05,0.02,0.10,0.6)
        F.compactBtn:SetBackdropBorderColor(0.35,0.18,0.60,0.6)
        local cfs2=F.compactBtn:GetFontString()
        if cfs2 then cfs2:SetTextColor(0.55,0.40,0.80,0.8) end
    else
        ApplyWindowStyle(F,0.50,0.22,0.88)
        F.compactBtn:SetBackdropColor(0.12,0.05,0.22,1)
        F.compactBtn:SetBackdropBorderColor(0.45,0.22,0.75,0.8)
        local cfs2=F.compactBtn:GetFontString()
        if cfs2 then cfs2:SetTextColor(0.70,0.55,1,1) end
    end
end
F.compactBtn:SetScript("OnClick",function() ApplyCompactMode(not F._compact) end)

F.rows={}
for i,f in ipairs(CLOTH_DATA) do
    local col=f.color
    local b=CreateFrame("Button",nil,F)
    b:SetSize(138,86); b:SetPoint("TOPLEFT",8+(i-1)*148,-48)
    local bg=b:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints()
    bg:SetColorTexture(col[1]*0.08,col[2]*0.05,col[3]*0.12,0.80)
    local brd=CreateFrame("Frame",nil,b,"BackdropTemplate"); brd:SetAllPoints()
    if not brd.SetBackdrop then Mixin(brd,BackdropTemplateMixin) end
    brd:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    brd:SetBackdropColor(0,0,0,0)
    brd:SetBackdropBorderColor(col[1]*0.55,col[2]*0.35,col[3]*0.80,0.55)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetSize(52,52)
    b.icon:SetPoint("TOPLEFT",5,-5); b.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    b.nameTxt=b:CreateFontString(nil,"OVERLAY")
    b.nameTxt:SetFont("Fonts\\2002.ttf",9,"OUTLINE")
    b.nameTxt:SetPoint("TOPLEFT",b.icon,"TOPRIGHT",6,-3)
    b.nameTxt:SetTextColor(col[1],col[2],col[3],0.90); b.nameTxt:SetText(f.name)
    b.txt=b:CreateFontString(nil,"OVERLAY","GameFontNormalHugeOutline")
    b.txt:SetPoint("TOPLEFT",b.icon,"TOPRIGHT",6,-14); b.txt:SetTextColor(1,1,1,1)
    b.cph=b:CreateFontString(nil,"OVERLAY")
    b.cph:SetFont("Fonts\\2002.ttf",10,"OUTLINE")
    b.cph:SetPoint("TOPLEFT",b.txt,"BOTTOMLEFT",0,-2); b.cph:SetTextColor(0.65,0.65,0.88,1)
    b.wbTxt=b:CreateFontString(nil,"OVERLAY")
    b.wbTxt:SetFont("Fonts\\2002.ttf",9,"OUTLINE")
    b.wbTxt:SetPoint("BOTTOMLEFT",5,4)
    b.wbTxt:SetTextColor(col[1]*0.7,col[2]*0.6,col[3]*0.9,0.80)
    b:SetScript("OnEnter",function(s)
        GameTooltip:SetOwner(s,"ANCHOR_TOP"); GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffcc99ff"..f.name.."|r")
        local d=session.counts[f.name] or {total=0,t2=0,t3=0}
        local wb=ClothWarbandDB and (ClothWarbandDB.totals[f.name] or 0) or 0
        -- Session breakdown (Silver + Gold)
        GameTooltip:AddDoubleLine(QUAL_S.." Silver (session):","|cffc8c8ff"..d.t2.."|r",1,1,1,1,1,1)
        GameTooltip:AddDoubleLine(QUAL_G.." Gold (session):",  "|cffc8c8ff"..d.t3.."|r",1,1,1,1,1,1)
        GameTooltip:AddLine(DIVIDER)
        GameTooltip:AddDoubleLine("Session total:","|cffffff00"..d.total.."|r",1,1,1,1,1,1)
        -- Warband Silver/Gold totals from all saved runs
        local wb_t2, wb_t3 = 0, 0
        if ClothWarbandDB and ClothWarbandDB.runs then
            for _, run in ipairs(ClothWarbandDB.runs) do
                local rd = run.data and run.data[f.name]
                if rd and type(rd) == "table" then
                    wb_t2 = wb_t2 + (rd.t2 or 0)
                    wb_t3 = wb_t3 + (rd.t3 or 0)
                end
            end
        end
        GameTooltip:AddLine(DIVIDER)
        GameTooltip:AddDoubleLine("|cffaa66ffWarband saved:|r",  "|cff00ee88"..wb.."|r",1,1,1,1,1,1)
        GameTooltip:AddDoubleLine("  "..QUAL_S.." Silver (saved):","|cffc8c8ff"..wb_t2.."|r",1,1,1,1,1,1)
        GameTooltip:AddDoubleLine("  "..QUAL_G.." Gold (saved):",  "|cffc8c8ff"..wb_t3.."|r",1,1,1,1,1,1)
        GameTooltip:AddDoubleLine("|cffaa66ffWarband incl. session:|r",
            "|cff00ffaa"..(wb+d.total).."|r",1,1,1,1,1,1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    F.rows[f.name]=b
end

F.tTime=F:CreateFontString(nil,"OVERLAY")
F.tTime:SetFont("Fonts\\2002.ttf",10,"OUTLINE")
F.tTime:SetPoint("BOTTOM",0,7); F.tTime:SetTextColor(0.68,0.58,0.90,1)
local botLine=F:CreateTexture(nil,"ARTWORK")
botLine:SetPoint("BOTTOMLEFT",2,22); botLine:SetPoint("BOTTOMRIGHT",-2,22)
botLine:SetHeight(1); botLine:SetColorTexture(0.38,0.18,0.65,0.45)

-- ── Scale helper ─────────────────────────────────────────────────────────
local Archive

local function ApplyScale(delta)
    local cur = ClothWarbandDB and ClothWarbandDB.scale or 1.0
    local new = math.max(0.5, math.min(2.0, cur + delta))
    new = math.floor(new * 10 + 0.5) / 10
    if ClothWarbandDB then ClothWarbandDB.scale = new end
    F:SetScale(new); if Archive then Archive:SetScale(new) end
    -- update both scale labels
    if F.scaleLbl then
        F.scaleLbl:SetText(string.format("|cff554466%.1fx|r",new))
    end
    if Archive.aScaleLbl then
        Archive.aScaleLbl:SetText(string.format("|cff554466%.1fx|r",new))
    end
end

-- Scale buttons: small [-] and [+] in bottom-left corner
-- Scale button factory — all anchored via fixed BOTTOMLEFT offsets from F
local function MakeScaleBtn(text, xOffset)
    local b = CreateFrame("Button",nil,F,"BackdropTemplate")
    b:SetSize(20,18)
    b:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", xOffset, 4)
    if not b.SetBackdrop then Mixin(b,BackdropTemplateMixin) end
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.10,0.04,0.18,1)
    b:SetBackdropBorderColor(0.38,0.18,0.65,0.8)
    b:SetText(text)
    local fs=b:GetFontString()
    if fs then fs:SetFont("Fonts\\2002.ttf",11,"OUTLINE"); fs:SetTextColor(0.75,0.60,1,1) end
    b:SetScript("OnEnter",function(s)
        s:SetBackdropColor(0.20,0.08,0.32,1)
        s:SetBackdropBorderColor(0.70,0.40,1.0,1)
        GameTooltip:SetOwner(s,"ANCHOR_TOP"); GameTooltip:ClearLines()
        local sc = ClothWarbandDB and ClothWarbandDB.scale or 1.0
        GameTooltip:AddLine("|cffcc99ffScale: "..string.format("%.1f",sc).."x|r")
        GameTooltip:AddLine("|cff888888Click - or + to resize  (0.5 – 2.0)|r",1,1,1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function(s)
        s:SetBackdropColor(0.10,0.04,0.18,1)
        s:SetBackdropBorderColor(0.38,0.18,0.65,0.8)
        GameTooltip:Hide()
    end)
    return b
end

-- Layout (left to right): [-] [1.0x] [+]   spaced 22px apart from x=6
F.scaleMinus = MakeScaleBtn("-", 6)
F.scalePlus  = MakeScaleBtn("+", 52)
F.scaleMinus:SetScript("OnClick",function() ApplyScale(-0.1) end)
F.scalePlus:SetScript("OnClick", function() ApplyScale( 0.1) end)

-- Scale label centred between the two buttons
F.scaleLbl = F:CreateFontString(nil,"OVERLAY")
F.scaleLbl:SetFont("Fonts\\2002.ttf",8,"OUTLINE")
F.scaleLbl:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 28, 7)
F.scaleLbl:SetTextColor(0.55,0.45,0.80,1)

-- Register elements hidden in compact mode (after all are created)
-- We do this after rows are built; compactHide filled here:
compactHide = { F.archiveBtn, F.saveBtn, F.resetBtn, F.tTime }
-- Also hide row chrome (name label, /h, WB text) but keep icon+count visible
for _,f in ipairs(CLOTH_DATA) do
    local row=F.rows[f.name]
    if row then
        table.insert(compactHide, row.nameTxt)
        table.insert(compactHide, row.cph)
        table.insert(compactHide, row.wbTxt)
    end
end

function F:UpdateUI()
    if not session.counts then return end
    local elapsed=GetTime()-session.startTime
    local hrs=elapsed/3600; local m=math.floor(elapsed/60); local s=math.floor(elapsed%60)
    F.tTime:SetText(string.format("|cffaa66ff%s|r  |cff777788%02d:%02d|r",session.currentZone,m,s))
    if F.scaleLbl then
        local sc=ClothWarbandDB and ClothWarbandDB.scale or 1.0
        F.scaleLbl:SetText(string.format("|cff554466%.1fx|r",sc))
    end
    for _,f in ipairs(CLOTH_DATA) do
        local d=session.counts[f.name] or {total=0,t2=0,t3=0}
        local row=F.rows[f.name]; if not row then break end
        row.icon:SetTexture(GetSafeIcon(f.id)); row.txt:SetText(d.total)
        row.cph:SetText(string.format("|cff8888bb%d|r/h",
            math.floor(hrs>0 and d.total/hrs or 0)))
        local wb=ClothWarbandDB and (ClothWarbandDB.totals[f.name] or 0) or 0
        row.wbTxt:SetText("WB: "..(wb+d.total))
    end
end
F.saveBtn:SetScript("OnClick",function() SaveRun(); ResetSession(); F:UpdateUI() end)
F.resetBtn:SetScript("OnClick",function() StaticPopup_Show("CLOTHWIDGET_CONFIRM_RESET") end)

-- ── Archive window ────────────────────────────────────────────────────────
-- Forward-declare scanning functions so the Scan button closure
-- (defined inside the Archive header) can reference them.
-- The actual implementations follow later in the file.
local ScanTailoringProfession, ScanCooldowns

Archive=CreateFrame("Frame","ClothArchiveFrame",UIParent,"BackdropTemplate")
Archive:SetSize(850,610); Archive:SetPoint("CENTER"); Archive:Hide()
Archive:SetMovable(true); Archive:EnableMouse(true); Archive:RegisterForDrag("LeftButton")
Archive:SetScript("OnDragStart",Archive.StartMoving)
Archive:SetScript("OnDragStop",Archive.StopMovingOrSizing)
Archive:SetFrameStrata("DIALOG")
ApplyWindowStyle(Archive,0.55,0.25,0.92)
MakeHeaderStripe(Archive,40)
MakeTitle(Archive,"|cffaa55ffCLOTH|r |cffddbbffARCHIVE|r  |cff554477| Warband Statistics|r",14,-13,13)
MakeCloseBtn(Archive,function() Archive:Hide() end)

-- ── Scale buttons on Archive (mirror of main widget) ─────────────────────
local function MakeAScaleBtn(text, xOff)
    local b=CreateFrame("Button",nil,Archive,"BackdropTemplate")
    b:SetSize(20,18); b:SetPoint("TOPRIGHT",Archive,"TOPRIGHT",xOff,-8)
    if not b.SetBackdrop then Mixin(b,BackdropTemplateMixin) end
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.10,0.04,0.18,1); b:SetBackdropBorderColor(0.38,0.18,0.65,0.8)
    b:SetText(text)
    local fs=b:GetFontString()
    if fs then fs:SetFont("Fonts\\2002.ttf",11,"OUTLINE"); fs:SetTextColor(0.75,0.60,1,1) end
    b:SetScript("OnEnter",function(s)
        s:SetBackdropColor(0.20,0.08,0.32,1); s:SetBackdropBorderColor(0.70,0.40,1.0,1)
        GameTooltip:SetOwner(s,"ANCHOR_BOTTOM"); GameTooltip:ClearLines()
        local sc=ClothWarbandDB and ClothWarbandDB.scale or 1.0
        GameTooltip:AddLine("|cffcc99ffScale: "..string.format("%.1f",sc).."x|r")
        GameTooltip:AddLine("|cff888888Range 0.5 – 2.0  (applies to both windows)|r",1,1,1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function(s)
        s:SetBackdropColor(0.10,0.04,0.18,1); s:SetBackdropBorderColor(0.38,0.18,0.65,0.8)
        GameTooltip:Hide()
    end)
    return b
end
-- Layout (right→left, inside the X button at -6):  [X](-6) [-48][lbl][-70][+](-92)
Archive.aScalePlus  = MakeAScaleBtn("+", -46)
Archive.aScaleMinus = MakeAScaleBtn("-", -92)
Archive.aScaleLbl   = Archive:CreateFontString(nil,"OVERLAY")
Archive.aScaleLbl:SetFont("Fonts\\2002.ttf",8,"OUTLINE")
Archive.aScaleLbl:SetPoint("TOPRIGHT",Archive,"TOPRIGHT",-67,-12)
Archive.aScaleLbl:SetTextColor(0.55,0.45,0.80,1)
local function RefreshArchiveScaleLbl()
    local sc=ClothWarbandDB and ClothWarbandDB.scale or 1.0
    Archive.aScaleLbl:SetText(string.format("|cff554466%.1fx|r",sc))
end
Archive.aScalePlus:SetScript("OnClick",function()
    ApplyScale(0.1); RefreshArchiveScaleLbl()
end)
Archive.aScaleMinus:SetScript("OnClick",function()
    ApplyScale(-0.1); RefreshArchiveScaleLbl()
end)
C_Timer.After(0.1, RefreshArchiveScaleLbl)

Archive.tabRuns=CreateFrame("Button",nil,Archive,"BackdropTemplate")
Archive.tabRuns:SetSize(120,24); Archive.tabRuns:SetPoint("TOPLEFT",14,-50)
StyleButton(Archive.tabRuns,"HISTORY")
Archive.tabStats=CreateFrame("Button",nil,Archive,"BackdropTemplate")
Archive.tabStats:SetSize(120,24); Archive.tabStats:SetPoint("LEFT",Archive.tabRuns,"RIGHT",5,0)
StyleButton(Archive.tabStats,"TOTALS")
Archive.tabTailors=CreateFrame("Button",nil,Archive,"BackdropTemplate")
Archive.tabTailors:SetSize(120,24); Archive.tabTailors:SetPoint("LEFT",Archive.tabStats,"RIGHT",5,0)
StyleButton(Archive.tabTailors,"TAILORS")

local tabRule=Archive:CreateTexture(nil,"ARTWORK")
tabRule:SetPoint("TOPLEFT",14,-78); tabRule:SetPoint("TOPRIGHT",-14,-78)
tabRule:SetHeight(1); tabRule:SetColorTexture(0.20,0.45,0.90,0.45)

Archive.scroll=CreateFrame("ScrollFrame",nil,Archive,"UIPanelScrollFrameTemplate")
Archive.scroll:SetPoint("TOPLEFT",14,-82); Archive.scroll:SetPoint("BOTTOMRIGHT",-28,8)
Archive.content=CreateFrame("Frame",nil,Archive.scroll)
Archive.content:SetSize(790,1); Archive.scroll:SetScrollChild(Archive.content)

    WT_MakeSAScrollbar(Archive.scroll, Archive)

Archive.tailorOuter=CreateFrame("Frame",nil,Archive)
Archive.tailorOuter:SetPoint("TOPLEFT",14,-82); Archive.tailorOuter:SetPoint("BOTTOMRIGHT",-14,8)
Archive.tailorOuter:Hide()

-- Static non-scrolling header bar with "Open Tailoring" button
Archive.tailorHeader=CreateFrame("Frame",nil,Archive.tailorOuter,"BackdropTemplate")
Archive.tailorHeader:SetHeight(36)
Archive.tailorHeader:SetPoint("TOPLEFT",0,0); Archive.tailorHeader:SetPoint("TOPRIGHT",0,0)
if not Archive.tailorHeader.SetBackdrop then Mixin(Archive.tailorHeader,BackdropTemplateMixin) end
Archive.tailorHeader:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
    edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
Archive.tailorHeader:SetBackdropColor(0.07,0.03,0.14,0.95)
Archive.tailorHeader:SetBackdropBorderColor(0.35,0.16,0.60,0.55)

local thTitle=Archive.tailorHeader:CreateFontString(nil,"OVERLAY")
thTitle:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
thTitle:SetPoint("LEFT",10,0)
thTitle:SetText("|cffb58cff| TAILOR COOLDOWNS|r")

-- Open Tailoring button
-- Scan button (left of Open Tailoring)
Archive.tailorScanBtn=CreateFrame("Button",nil,Archive.tailorHeader,"BackdropTemplate")
Archive.tailorScanBtn:SetSize(110,24)
Archive.tailorScanBtn:SetPoint("RIGHT",-154,0)
StyleButton(Archive.tailorScanBtn,"Scan Cooldowns")
Archive.tailorScanBtn:SetScript("OnClick",function()
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) then
        print("|cffb58cffClothWidget:|r Tailoring not open — open your profession window first, then scan.")
        return
    end
    ScanTailoringProfession(); ScanCooldowns()
    if currentTab=="tailors" and Archive:IsShown() then BuildTailorTab() end
    print("|cffb58cffClothWidget:|r Cooldowns scanned.")
end)
Archive.tailorScanBtn:SetScript("OnEnter",function(s)
    GameTooltip:SetOwner(s,"ANCHOR_BOTTOM"); GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffcc99ffScan Cooldowns|r")
    GameTooltip:AddLine("|cff888888Reads your Tailoring cooldowns directly.|r",1,1,1)
    GameTooltip:AddLine("|cffaaaaff Requires Tailoring window to be open.|r",1,1,1)
    GameTooltip:Show()
end)
Archive.tailorScanBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)

Archive.openTailorBtn=CreateFrame("Button",nil,Archive.tailorHeader,"BackdropTemplate")
Archive.openTailorBtn:SetSize(140,24)
Archive.openTailorBtn:SetPoint("RIGHT",-6,0)
StyleButton(Archive.openTailorBtn,"Open Tailoring")
Archive.openTailorBtn:SetScript("OnClick",function()
    -- FIX: CastSpellByName is unreliable for professions in 12.0.5.
    -- C_TradeSkillUI.OpenTradeSkill(skillLineID) is the correct Midnight API.
    -- GetProfessionInfo() returns: name, icon, skillLevel, maxSkillLevel,
    --   numAbilities, spelloffset, skillLineID, rankModifier, isAlt, altExpansionID, unused
    -- So the 7th return value is the skillLineID we need.
    local p1,p2=GetProfessions()
    for _,pi in ipairs({p1,p2}) do
        if pi then
            local nm,_,_,_,_,_,skillLineID=GetProfessionInfo(pi)
            if nm and (nm:lower():find("tailoring") or nm:lower():find("naaikunst") or nm:lower():find("kleermakerij")) then
                if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill and skillLineID then
                    C_TradeSkillUI.OpenTradeSkill(skillLineID)
                else
                    -- Fallback: open general professions panel
                    ToggleCharacter("ProfessionsFrame")
                end
                return
            end
        end
    end
    print("|cffb58cffClothWidget:|r No Tailoring profession found on this character.")
end)
Archive.openTailorBtn:SetScript("OnEnter",function(s)
    GameTooltip:SetOwner(s,"ANCHOR_BOTTOM"); GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffcc99ffOpen Tailoring|r")
    GameTooltip:AddLine("|cff888888Opens your Tailoring profession window|r",1,1,1)
    GameTooltip:Show()
end)
Archive.openTailorBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)

-- Sub-hint under button
local thSub=Archive.tailorHeader:CreateFontString(nil,"OVERLAY")
thSub:SetFont("Fonts\\2002.ttf",8,"OUTLINE")
thSub:SetPoint("BOTTOMLEFT",10,4)
thSub:SetTextColor(0.40,0.35,0.58,1)
thSub:SetText("Click Scan Cooldowns after opening Professions, or use /cbud scan. Open Tailoring opens the profession window.")

Archive.tailorScroll=CreateFrame("ScrollFrame",nil,Archive.tailorOuter,"UIPanelScrollFrameTemplate")
Archive.tailorScroll:SetPoint("TOPLEFT",0,-38); Archive.tailorScroll:SetPoint("BOTTOMRIGHT",-20,0)
Archive.tailorContent=CreateFrame("Frame",nil,Archive.tailorScroll)
Archive.tailorContent:SetSize(796,1); Archive.tailorScroll:SetScrollChild(Archive.tailorContent)

local currentTab="runs"
-- FIX: SetParent(nil) risks dangling references to locally-cached frames.
-- Use a safe re-parent to a hidden holder frame instead (frame pool pattern).
local _trashFrame = CreateFrame("Frame"); _trashFrame:Hide()
local function ClearContent()
    for _,ch in ipairs({Archive.content:GetChildren()}) do
        ch:Hide(); ch:SetParent(_trashFrame)
    end
    for _,r in ipairs({Archive.content:GetRegions()}) do r:Hide() end
    Archive.content:SetHeight(1)
    for _,ch in ipairs({Archive.tailorContent:GetChildren()}) do
        ch:Hide(); ch:SetParent(_trashFrame)
    end
    for _,r in ipairs({Archive.tailorContent:GetRegions()}) do r:Hide() end
    Archive.tailorContent:SetHeight(1)
end
local function SetActiveTab(tab)
    for _,t in ipairs({Archive.tabRuns,Archive.tabStats,Archive.tabTailors}) do
        StyleButton(t,t:GetText() or "") end
    if tab then
        tab:SetBackdropColor(0.22,0.08,0.38,1); tab:SetBackdropBorderColor(0.85,0.55,1.0,1)
        local fs=tab:GetFontString(); if fs then fs:SetTextColor(1,0.92,1,1) end
    end
end

-- ── History tab ───────────────────────────────────────────────────────────
local function BuildHistoryTab()
    currentTab="runs"; ClearContent()
    Archive.tailorOuter:Hide(); Archive.scroll:Show()
    if not ClothWarbandDB or not ClothWarbandDB.runs or #ClothWarbandDB.runs==0 then
        local e=Archive.content:CreateFontString(nil,"OVERLAY")
        e:SetFont("Fonts\\2002.ttf",11,"OUTLINE"); e:SetPoint("CENTER")
        e:SetText("|cff665577No runs saved yet — go farm!|r")
        Archive.content:SetHeight(40); return
    end
    local ch=Archive.content:CreateFontString(nil,"OVERLAY")
    ch:SetFont("Fonts\\2002.ttf",8,"OUTLINE"); ch:SetPoint("TOPLEFT",8,-5)
    ch:SetTextColor(0.50,0.42,0.72,1)
    ch:SetText(string.format("%-26s  %-16s  %-10s  %-10s  %-10s  %-10s  %-7s  Alt",
        "Zone","Date","Duration",CLOTH_DATA[1].name,CLOTH_DATA[2].name,CLOTH_DATA[3].name,"Total"))
    local hl=Archive.content:CreateTexture(nil,"ARTWORK")
    hl:SetPoint("TOPLEFT",0,-19); hl:SetPoint("TOPRIGHT",0,-19)
    hl:SetHeight(1); hl:SetColorTexture(0.20,0.45,0.90,0.55)
    local y=-24
    for idx,run in ipairs(ClothWarbandDB.runs) do
        local even=(idx%2==0)
        local row=CreateFrame("Button",nil,Archive.content,"BackdropTemplate")
        row:SetSize(780,44); row:SetPoint("TOPLEFT",0,y)
        if not row.SetBackdrop then Mixin(row,BackdropTemplateMixin) end
        row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        row:SetBackdropColor(even and 0.08 or 0.05,even and 0.03 or 0.02,
            even and 0.15 or 0.09,0.88)
        row:SetBackdropBorderColor(0.28,0.12,0.45,0.38)
        local zt=row:CreateFontString(nil,"OVERLAY","GameFontNormalOutline")
        zt:SetPoint("TOPLEFT",8,-5); zt:SetText("|cffcc99ff"..(run.zone or "?").."|r")
        zt:SetWidth(190); zt:SetJustifyH("LEFT")
        local st=row:CreateFontString(nil,"OVERLAY")
        st:SetFont("Fonts\\2002.ttf",7,"OUTLINE"); st:SetPoint("BOTTOMLEFT",8,5)
        st:SetTextColor(0.45,0.40,0.65,1)
        st:SetText((run.date or "?").."  ["..
            (run.duration and FormatTime(run.duration) or "?").."]  @"..GetShortName(run.char))
        local cx=268; local rTot=0
        for _,f in ipairs(CLOTH_DATA) do
            local d=run.data and run.data[f.name]
            local cnt=d and (type(d)=="table" and (d.total or 0) or d) or 0
            rTot=rTot+cnt
            local ct=row:CreateFontString(nil,"OVERLAY"); ct:SetFont("Fonts\\2002.ttf",12,"OUTLINE")
            ct:SetPoint("LEFT",cx,3)
            ct:SetText(string.format("|T%d:16:16|t |cffffff00%d|r",GetSafeIcon(f.id),cnt))
            ct:SetWidth(132); cx=cx+132
        end
        local badge=CreateFrame("Frame",nil,row,"BackdropTemplate")
        badge:SetSize(52,20); badge:SetPoint("RIGHT",-8,0)
        if not badge.SetBackdrop then Mixin(badge,BackdropTemplateMixin) end
        badge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        badge:SetBackdropColor(0.14,0.05,0.26,1); badge:SetBackdropBorderColor(0.45,0.22,0.75,0.80)
        local bt=badge:CreateFontString(nil,"OVERLAY"); bt:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
        bt:SetPoint("CENTER"); bt:SetText("|cffffff00"..rTot.."|r")
        local runTotal=rTot
        row:SetScript("OnEnter",function(s)
            GameTooltip:SetOwner(s,"ANCHOR_LEFT"); GameTooltip:ClearLines()
            GameTooltip:AddLine("|cffcc99ff"..(run.zone or "?").."|r")
            if run.date then GameTooltip:AddLine("|cff888888"..run.date.."|r") end
            if run.duration then GameTooltip:AddDoubleLine("Duration:",
                "|cffaaaaff"..FormatTime(run.duration).."|r",1,1,1,1,1,1) end
            if run.char then GameTooltip:AddDoubleLine("Character:",
                "|cff88ccff"..run.char.."|r",1,1,1,1,1,1) end
            GameTooltip:AddLine(DIVIDER)
            for _,f in ipairs(CLOTH_DATA) do
                local d=run.data and run.data[f.name]
                local cnt=d and (type(d)=="table" and (d.total or 0) or d) or 0
                local t2=d and type(d)=="table" and (d.t2 or 0) or 0
                local t3=d and type(d)=="table" and (d.t3 or 0) or 0
                GameTooltip:AddLine("|T"..GetSafeIcon(f.id)..":14:14|t |cffeeeeee"..f.name.."|r")
                GameTooltip:AddDoubleLine("  Total:","|cffffff00"..cnt.."|r",1,1,1,1,1,1)
                if t2>0 then GameTooltip:AddDoubleLine("  "..QUAL_S.." Silver:",t2,1,1,1,.8,.8,1) end
                if t3>0 then GameTooltip:AddDoubleLine("  "..QUAL_G.." Gold:",t3,1,1,1,1,.8,.2) end
            end
            GameTooltip:AddLine(DIVIDER)
            GameTooltip:AddDoubleLine("Run total:","|cffaa66ff"..runTotal.."|r",1,1,1,1,1,1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        y=y-48
    end
    Archive.content:SetHeight(math.abs(y)+10)
end

-- ── Totals tab ────────────────────────────────────────────────────────────
local function BuildTotalsTab()
    currentTab="stats"; ClearContent()
    Archive.tailorOuter:Hide(); Archive.scroll:Show()
    if not ClothWarbandDB or not ClothWarbandDB.totals then return end
    -- Ensure all cloth keys exist (safe against partially-initialised DB)
    for _,f in ipairs(CLOTH_DATA) do
        ClothWarbandDB.totals[f.name] = ClothWarbandDB.totals[f.name] or 0
    end
    local hdr=Archive.content:CreateFontString(nil,"OVERLAY")
    hdr:SetFont("Fonts\\2002.ttf",12,"OUTLINE"); hdr:SetPoint("TOPLEFT",8,-10)
    hdr:SetText("|cffb58cff| WARBAND TOTALS|r")
    local y=-40
    for ci,f in ipairs(CLOTH_DATA) do
        local col=f.color
        local saved=ClothWarbandDB.totals[f.name] or 0
        local sessCnt=session.counts[f.name] and session.counts[f.name].total or 0
        local grand=saved+sessCnt
        local numRuns=#(ClothWarbandDB.runs or {})
        local avg=numRuns>0 and math.floor(grand/numRuns) or 0
        local box=CreateFrame("Frame",nil,Archive.content,"BackdropTemplate")
        box:SetSize(242,76); box:SetPoint("TOPLEFT",(ci-1)*256,y)
        if not box.SetBackdrop then Mixin(box,BackdropTemplateMixin) end
        box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        box:SetBackdropColor(col[1]*.10,col[2]*.06,col[3]*.16,0.95)
        box:SetBackdropBorderColor(col[1]*.70,col[2]*.40,col[3]*.90,0.80)
        local ico=box:CreateTexture(nil,"ARTWORK"); ico:SetSize(50,50)
        ico:SetPoint("LEFT",8,0); ico:SetTexCoord(0.08,0.92,0.08,0.92)
        ico:SetTexture(GetSafeIcon(f.id))
        local nT=box:CreateFontString(nil,"OVERLAY"); nT:SetFont("Fonts\\2002.ttf",10,"OUTLINE")
        nT:SetPoint("TOPLEFT",66,-8); nT:SetTextColor(col[1],col[2],col[3],1); nT:SetText(f.name)
        local gT=box:CreateFontString(nil,"OVERLAY","GameFontNormalHugeOutline")
        gT:SetPoint("TOPLEFT",66,-22); gT:SetText("|cffffff00"..grand.."|r")
        local aT=box:CreateFontString(nil,"OVERLAY"); aT:SetFont("Fonts\\2002.ttf",8,"OUTLINE")
        aT:SetPoint("BOTTOMLEFT",66,6); aT:SetTextColor(0.58,0.55,0.78,1)
        aT:SetText(string.format("~%d/run  (%d runs)",avg,numRuns))
        -- BUG FIX: Totals boxes had no tooltip. Add Silver/Gold warband breakdown.
        box:EnableMouse(true)
        local fCap = f  -- capture loop variable
        box:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cffcc99ff"..fCap.name.."|r  |cff888888Warband Totals|r")
            GameTooltip:AddLine(DIVIDER)
            -- Compute t2/t3 totals from all saved runs
            local wb_t2, wb_t3 = 0, 0
            for _, run in ipairs(ClothWarbandDB.runs or {}) do
                local d = run.data and run.data[fCap.name]
                if d and type(d) == "table" then
                    wb_t2 = wb_t2 + (d.t2 or 0)
                    wb_t3 = wb_t3 + (d.t3 or 0)
                end
            end
            -- Add current session counts
            local sess = session.counts[fCap.name] or {total=0,t2=0,t3=0}
            local tot_t2 = wb_t2 + sess.t2
            local tot_t3 = wb_t3 + sess.t3
            GameTooltip:AddDoubleLine(QUAL_S.." Silver (all runs):",
                "|cffc8c8ff"..tot_t2.."|r",1,1,1,1,1,1)
            GameTooltip:AddDoubleLine(QUAL_G.." Gold (all runs):",
                "|cffc8c8ff"..tot_t3.."|r",1,1,1,1,1,1)
            GameTooltip:AddLine(DIVIDER)
            GameTooltip:AddDoubleLine("Session this run:",
                "|cffffff00"..sess.total.."|r",1,1,1,1,1,1)
            GameTooltip:AddDoubleLine("  "..QUAL_S.." Silver:",
                "|cffc8c8ff"..sess.t2.."|r",1,1,1,1,1,1)
            GameTooltip:AddDoubleLine("  "..QUAL_G.." Gold:",
                "|cffc8c8ff"..sess.t3.."|r",1,1,1,1,1,1)
            GameTooltip:AddLine(DIVIDER)
            GameTooltip:AddDoubleLine("|cffaa66ffWarband total (incl. session):|r",
                "|cff00ffaa"..grand.."|r",1,1,1,1,1,1)
            if numRuns > 0 then
                GameTooltip:AddDoubleLine("Avg per run:",
                    "|cffaaaaff"..avg.."|r",1,1,1,1,1,1)
            end
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    y=y-92
    local div=Archive.content:CreateTexture(nil,"ARTWORK")
    div:SetPoint("TOPLEFT",4,y+4); div:SetPoint("TOPRIGHT",-4,y+4)
    div:SetHeight(1); div:SetColorTexture(0.20,0.45,0.90,0.55)
    y=y-10
    local cHdr=Archive.content:CreateFontString(nil,"OVERLAY")
    cHdr:SetFont("Fonts\\2002.ttf",11,"OUTLINE"); cHdr:SetPoint("TOPLEFT",8,y)
    cHdr:SetText("|cffb58cff| PER CHARACTER|r"); y=y-28
    local charStats={}; local charOrder={}
    for _,run in ipairs(ClothWarbandDB.runs or {}) do
        local c=run.char or "?"
        if not charStats[c] then
            charStats[c]={runs=0,data={}}
            for _,f in ipairs(CLOTH_DATA) do charStats[c].data[f.name]={total=0,t2=0,t3=0} end
            table.insert(charOrder,c)
        end
        charStats[c].runs=charStats[c].runs+1
        for _,f in ipairs(CLOTH_DATA) do
            local d=run.data and run.data[f.name]
            local cnt=d and (type(d)=="table" and (d.total or 0) or d) or 0
            local q2 =d and type(d)=="table" and (d.t2 or 0) or 0
            local q3 =d and type(d)=="table" and (d.t3 or 0) or 0
            charStats[c].data[f.name].total=charStats[c].data[f.name].total+cnt
            charStats[c].data[f.name].t2   =charStats[c].data[f.name].t2+q2
            charStats[c].data[f.name].t3   =charStats[c].data[f.name].t3+q3
        end
    end
    if #charOrder==0 then
        local e=Archive.content:CreateFontString(nil,"OVERLAY")
        e:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); e:SetPoint("TOPLEFT",8,y)
        e:SetText("|cff554466No per-character data found.|r"); y=y-24
    end
    for _,charKey in ipairs(charOrder) do
        local cs=charStats[charKey]; local sN=GetShortName(charKey)
        local isMe=(charKey==GetCharKey()); local cTot=0
        local cBox=CreateFrame("Frame",nil,Archive.content,"BackdropTemplate")
        cBox:SetSize(775,52); cBox:SetPoint("TOPLEFT",0,y)
        if not cBox.SetBackdrop then Mixin(cBox,BackdropTemplateMixin) end
        cBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        cBox:SetBackdropColor(isMe and .10 or .06,isMe and .04 or .02,isMe and .18 or .11,.90)
        cBox:SetBackdropBorderColor(isMe and .50 or .30,isMe and .25 or .14,
            isMe and .85 or .52,isMe and .80 or .45)
        local cnT=cBox:CreateFontString(nil,"OVERLAY"); cnT:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
        cnT:SetPoint("LEFT",10,6)
        cnT:SetText((isMe and "|cff00ee88" or "|cff88ccff")..sN.."|r"); cnT:SetWidth(140)
        local crT=cBox:CreateFontString(nil,"OVERLAY"); crT:SetFont("Fonts\\2002.ttf",7,"OUTLINE")
        crT:SetPoint("BOTTOMLEFT",10,6); crT:SetText("|cff554466"..cs.runs.." run(s)|r")
        local cx=158
        for _,f in ipairs(CLOTH_DATA) do
            local fd=cs.data[f.name] or {total=0,t2=0,t3=0}
            local cnt=type(fd)=="table" and (fd.total or 0) or (fd or 0)
            cTot=cTot+cnt
            local ctT=cBox:CreateFontString(nil,"OVERLAY"); ctT:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
            ctT:SetPoint("LEFT",cx,5)
            ctT:SetText(string.format("|T%d:18:18|t |cffffff00%d|r",GetSafeIcon(f.id),cnt))
            cx=cx+176
        end
        local sT=cBox:CreateFontString(nil,"OVERLAY"); sT:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
        sT:SetPoint("RIGHT",-10,0); sT:SetText("|cffaa66ff"..cTot.."|r")
        -- Drop source tooltip per character
        cBox:EnableMouse(true)
        local capCS = cs  -- capture loop variable
        local capSN = sN
        cBox:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            local col = isMe and "|cff00ee88" or "|cff88ccff"
            GameTooltip:AddLine(col..capSN.."|r  |cff888888drop sources (best first)|r")
            -- Per cloth: show totals (Silver/Gold) then best sources
            for _,f in ipairs(CLOTH_DATA) do
                local fd  = capCS.data[f.name] or {total=0,t2=0,t3=0}
                local cnt = type(fd)=="table" and (fd.total or 0) or (fd or 0)
                local q2  = type(fd)=="table" and (fd.t2 or 0) or 0
                local q3  = type(fd)=="table" and (fd.t3 or 0) or 0
                if cnt > 0 then
                    GameTooltip:AddLine(DIVIDER)
                    GameTooltip:AddLine("|T"..GetSafeIcon(f.id)..":14:14|t |cffeeeeee"..f.name.."|r")
                    GameTooltip:AddDoubleLine("  Total farmed:","|cffffff00"..cnt.."|r",1,1,1,1,1,1)
                    if q2 > 0 then GameTooltip:AddDoubleLine("    "..QUAL_S.." Silver:","|cffc8c8ff"..q2.."|r",1,1,1,1,1,1) end
                    if q3 > 0 then GameTooltip:AddDoubleLine("    "..QUAL_G.." Gold:",  "|cffc8c8ff"..q3.."|r",1,1,1,1,1,1) end
                end
                local sources = CLOTH_SOURCES and CLOTH_SOURCES[f.name]
                if sources and cnt > 0 then
                    for _, src in ipairs(sources) do
                        local sc = CLOTH_SOURCE_COLORS[src.type] or {r=1,g=1,b=1}
                        local typeColor = string.format("|cff%02x%02x%02x",
                            math.floor(sc.r*255), math.floor(sc.g*255), math.floor(sc.b*255))
                        GameTooltip:AddDoubleLine(
                            "  "..typeColor..src.type.."|r  "..src.rate,
                            "|cffaaaaff"..src.zone.."|r",1,1,1,1,1,1)
                        GameTooltip:AddLine("    |cff666666"..src.detail.."|r",1,1,1)
                    end
                end
            end
            if cTot == 0 then
                GameTooltip:AddLine("|cff666666No cloth farmed yet on this character.|r",1,1,1)
            end
            GameTooltip:Show()
        end)
        cBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
        y=y-58
    end
    Archive.content:SetHeight(math.abs(y)+20)
end

-- ── Tailors tab ───────────────────────────────────────────────────────────
local activeCooldownBars={}

local function BuildTailorTab()
    currentTab="tailors"; ClearContent()
    Archive.scroll:Hide(); Archive.tailorOuter:Show()
    activeCooldownBars={}
    local tc=Archive.tailorContent
    local charKey=GetCharKey()
    local y=0

    y=0  -- header is now in the static tailorHeader bar above the scroll

    local function BuildCharBox(charData,charName,isActive)
        local hasTailoring=charData.hasTailoring
        if not isActive and not hasTailoring then return end
        local knownRecipes=charData.knownRecipes or {}
        local cooldowns=charData.cooldowns or {}
        local everScanned=next(knownRecipes)~=nil
        local rowCount=0
        if hasTailoring then
            if everScanned then
                for _,cd in ipairs(TAILOR_COOLDOWNS) do
                    if knownRecipes[cd.name] then rowCount=rowCount+1 end
                end
            else
                rowCount=#TAILOR_COOLDOWNS
            end
        end
        local boxH=T_HEADER_H+rowCount*T_ROW_H+T_BOX_PAD
        local box=CreateFrame("Frame",nil,tc,"BackdropTemplate")
        box:SetSize(T_BOX_W,boxH); box:SetPoint("TOPLEFT",0,y)
        if not box.SetBackdrop then Mixin(box,BackdropTemplateMixin) end
        box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        if isActive then
            box:SetBackdropColor(0.09,0.04,0.17,0.95)
            box:SetBackdropBorderColor(0.55,0.28,0.90,0.80)
        else
            box:SetBackdropColor(0.05,0.02,0.10,0.88)
            box:SetBackdropBorderColor(0.30,0.14,0.52,0.55)
        end
        local nT=box:CreateFontString(nil,"OVERLAY"); nT:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
        nT:SetPoint("TOPLEFT",T_LABEL_X,-10)
        nT:SetText((isActive and "|cff00ee88" or "|cff88ccff")..charName.."|r"..
            (isActive and "  |cff33cc66[Active]|r" or ""))
        local tT=box:CreateFontString(nil,"OVERLAY"); tT:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
        tT:SetPoint("TOPRIGHT",-T_LABEL_X,-13)
        tT:SetText(hasTailoring and "|cff00ee88Tailoring|r" or "|cffff6644No Tailoring|r")
        local rule=box:CreateTexture(nil,"ARTWORK")
        rule:SetPoint("TOPLEFT",4,-(T_HEADER_H-2)); rule:SetPoint("TOPRIGHT",-4,-(T_HEADER_H-2))
        rule:SetHeight(1); rule:SetColorTexture(0.25,0.12,0.50,0.50)
        if not hasTailoring then y=y-boxH-T_BOX_GAP; return end
        local ri=0
        for _,cd in ipairs(TAILOR_COOLDOWNS) do
            local known=(not everScanned) or knownRecipes[cd.name]
            if known then
                local col=cd.color or {0.5,0.3,1.0}
                local rowTop=-(T_HEADER_H+ri*T_ROW_H)
                local cdIcon=GetSafeIcon(CLOTH_DATA[1].id)
                for _,f in ipairs(CLOTH_DATA) do if f.name==cd.cloth then cdIcon=GetSafeIcon(f.id); break end end
                -- Icon: fixed TOPLEFT anchor, 20px extra indent, centred in row height
                local icoX = T_LABEL_X + 20
                local icoY = rowTop - math.floor((T_ROW_H - 33) / 2)
                local ico=box:CreateTexture(nil,"ARTWORK")
                ico:SetSize(33,33)
                ico:SetPoint("TOPLEFT", box, "TOPLEFT", icoX, icoY)
                ico:SetTexture(cdIcon); ico:SetTexCoord(0.08,0.92,0.08,0.92)
                -- Label anchored to RIGHT of icon — always on same line
                local lbl=box:CreateFontString(nil,"OVERLAY"); lbl:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
                lbl:SetPoint("LEFT", ico, "RIGHT", 8, 0)
                lbl:SetTextColor(col[1],col[2],col[3],1.0)
                lbl:SetText(cd.name); lbl:SetWidth(200)
                local barY=rowTop-math.floor((T_ROW_H-T_BAR_H)/2)
                local barW=T_BOX_W-T_BAR_X-6
                local bar=CreateProgressBar(box,barW,T_BAR_H)
                bar:SetPoint("TOPLEFT",box,"TOPLEFT",T_BAR_X,barY)
                if not everScanned then
                    bar:SetUnscanned(cd.name)
                elseif isActive then
                    local cdDat=ClothCharDB and ClothCharDB.cooldowns and ClothCharDB.cooldowns[cd.name]
                    local rem=(cdDat and cdDat.expires) and math.max(0,cdDat.expires-time()) or 0
                    bar:SetCooldown(rem,(cdDat and cdDat.duration) or cd.duration,cd.name)
                    table.insert(activeCooldownBars,{bar=bar,cdName=cd.name,
                        duration=(cdDat and cdDat.duration) or cd.duration})
                else
                    local cdDat=cooldowns[cd.name]
                    local rem=(cdDat and cdDat.expires) and math.max(0,cdDat.expires-time()) or 0
                    bar:SetCooldown(rem,(cdDat and cdDat.duration) or cd.duration,cd.name)
                end
                ri=ri+1
            end
        end
        y=y-boxH-T_BOX_GAP
    end

    BuildCharBox({
        hasTailoring=ClothCharDB and ClothCharDB.hasTailoring or false,
        knownRecipes=ClothCharDB and ClothCharDB.knownRecipes or {},
        cooldowns   =ClothCharDB and ClothCharDB.cooldowns    or {},
    },UnitName("player") or "?",true)

    if ClothWarbandDB and ClothWarbandDB.chars then
        local hasOthers=false
        for ck,_ in pairs(ClothWarbandDB.chars) do
            if ck~=charKey then hasOthers=true; break end
        end
        if hasOthers then
            local oH=tc:CreateFontString(nil,"OVERLAY")
            oH:SetFont("Fonts\\2002.ttf",13,"OUTLINE"); oH:SetPoint("TOPLEFT",0,y)
            oH:SetText("|cffb58cff| OTHER CHARACTERS|r  |cff554466(data from previous sessions)|r")
            y=y-26
            for ck,charData in pairs(ClothWarbandDB.chars) do
                if ck~=charKey then
                    charData.knownRecipes=charData.knownRecipes or {}
                    charData.cooldowns=charData.cooldowns or {}
                    BuildCharBox(charData,GetShortName(ck),false)
                end
            end
        end
    end
    tc:SetHeight(math.abs(y)+20)
end

local function UpdateActiveCooldownBars()
    if currentTab~="tailors" or not Archive:IsShown() then return end
    for _,entry in ipairs(activeCooldownBars) do
        local cdDat=ClothCharDB and ClothCharDB.cooldowns and ClothCharDB.cooldowns[entry.cdName]
        local rem=(cdDat and cdDat.expires) and math.max(0,cdDat.expires-time()) or 0
        entry.bar:SetCooldown(rem,entry.duration,entry.cdName)
    end
end

Archive.tabRuns:SetScript("OnClick",function() SetActiveTab(Archive.tabRuns); BuildHistoryTab() end)
Archive.tabStats:SetScript("OnClick",function() SetActiveTab(Archive.tabStats); BuildTotalsTab() end)
Archive.tabTailors:SetScript("OnClick",function() SetActiveTab(Archive.tabTailors); BuildTailorTab() end)
F.archiveBtn:SetScript("OnClick",function()
    if Archive:IsShown() then Archive:Hide()
    else SetActiveTab(Archive.tabRuns); BuildHistoryTab(); Archive:Show() end
end)

-- ── Profession scanning ───────────────────────────────────────────────────
ScanTailoringProfession = function()
    local has=false; local p1,p2=GetProfessions()
    for _,pi in ipairs({p1,p2}) do
        if pi then
            local n=GetProfessionInfo(pi)
            if n and (n:lower():find("tailoring") or n:lower():find("kleermakerij")) then
                has=true end
        end
    end
    if ClothCharDB then ClothCharDB.hasTailoring=has end
    local key=GetCharKey()
    if ClothWarbandDB and ClothWarbandDB.chars[key] then
        ClothWarbandDB.chars[key].hasTailoring=has end
end

ScanCooldowns = function()
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) then return end
    local recipes=C_TradeSkillUI.GetAllRecipeIDs(); if not recipes then return end
    local key=GetCharKey()
    ClothCharDB.knownRecipes=ClothCharDB.knownRecipes or {}
    local wbc=ClothWarbandDB and ClothWarbandDB.chars[key]
    if wbc then wbc.knownRecipes=wbc.knownRecipes or {}; wbc.cooldowns=wbc.cooldowns or {} end
    for _,rid in ipairs(recipes) do
        local info=C_TradeSkillUI.GetRecipeInfo(rid)
        if info and info.name then
            for _,cd in ipairs(TAILOR_COOLDOWNS) do
                if info.name:find(cd.name,1,true) or rid==cd.recipeID then
                    ClothCharDB.knownRecipes[cd.name]=true
                    if wbc then wbc.knownRecipes[cd.name]=true end
                    local rem=C_TradeSkillUI.GetRecipeCooldown(rid)
                    if rem then
                        local exp=time()+math.max(0,math.floor(rem))
                        local entry={expires=exp,duration=cd.duration}
                        ClothCharDB.cooldowns[cd.name]=entry
                        if wbc then wbc.cooldowns[cd.name]=entry end
                    end
                end
            end
        end
    end
end

-- ── StaticPopup pre-registration (load time, not per-click) ─────────────
StaticPopupDialogs["CLOTHWIDGET_CONFIRM_RESET"] = {
    text    = "Reset current session without saving?",
    button1 = "Reset", button2 = "Cancel",
    OnAccept = function() ResetSession(); if F and F:IsShown() then F:UpdateUI() end end,
    timeout=0, whileDead=true, hideOnEscape=true,
}
StaticPopupDialogs["CLOTHWIDGET_CLEAR_ALL"] = {
    text    = "Wipe ALL warband cloth data? This cannot be undone.",
    button1 = "Wipe All", button2 = "Cancel",
    OnAccept = function()
        ClothWarbandDB.runs={}; ClothWarbandDB.totals={}
        for _,f in ipairs(CLOTH_DATA) do ClothWarbandDB.totals[f.name]=0 end
        ResetSession(); if F and F:IsShown() then F:UpdateUI() end
        print("|cffb58cffClothWidget:|r All data wiped.")
    end,
    timeout=0, whileDead=true, hideOnEscape=true,
}

-- ── Events ────────────────────────────────────────────────────────────────
local evtFrame=CreateFrame("Frame","ClothEvtFrame")
evtFrame:RegisterEvent("ADDON_LOADED"); evtFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
evtFrame:RegisterEvent("CHAT_MSG_LOOT"); evtFrame:RegisterEvent("TRADE_SKILL_SHOW")
evtFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
evtFrame:SetScript("OnEvent",function(self,event,...)
    if event=="ADDON_LOADED" and ...==ADDON_NAME then
        InitDB(); ResetSession()
        local sc = ClothWarbandDB.scale or 1.0
        F:SetScale(sc); if Archive then Archive:SetScale(sc) end
        if ClothWarbandDB.pos then
            F:ClearAllPoints(); F:SetPoint("CENTER",ClothWarbandDB.pos.x,ClothWarbandDB.pos.y) end
        F:UpdateUI()
    elseif event=="PLAYER_ENTERING_WORLD" then
        C_Timer.After(3,ScanTailoringProfession)
    elseif event=="TRADE_SKILL_SHOW" then
        C_Timer.After(0.5,function()
            ScanTailoringProfession(); ScanCooldowns()
            if currentTab=="tailors" and Archive:IsShown() then BuildTailorTab() end
        end)
    elseif event=="ZONE_CHANGED_NEW_AREA" then
        local nz=GetRealZoneText() or ""
        if session.currentZone~="" and session.currentZone~=nz then
            local hd=false
            for _,f in ipairs(CLOTH_DATA) do
                local c = session.counts[f.name]   -- nil-safe: init kan gemist zijn
                if c and c.total and c.total>0 then hd=true; break end end
            if hd then SaveRun() end; ResetSession()
        else session.currentZone=nz end
        if F:IsShown() then F:UpdateUI() end
    elseif event=="CHAT_MSG_LOOT" then
        local msg=...
        -- SECRET-AWARE GUARD (Midnight 12.x): loot-berichten kunnen
        -- secret strings zijn op tainted paths — gmatch crasht dan
        if issecretvalue and issecretvalue(msg) then return end
        if type(msg) ~= "string" then return end
        local changed=false
        for link in msg:gmatch("|Hitem:(%d+):.-|h") do
            local id=tonumber(link)
            if id then
                local qty=tonumber(msg:match("x(%d+)%.?%s*$")) or 1
                local entry=ITEM_LOOKUP[id]
                if entry then
                    local d=session.counts[entry.cloth]
                    if d then
                        if     entry.tier==3 then d.t3=d.t3+qty
                        elseif entry.tier==2 then d.t2=d.t2+qty end
                        d.total=d.total+qty; changed=true
                    end
                end
            end
        end
        if changed and F:IsShown() then F:UpdateUI() end
    end
end)

C_Timer.NewTicker(1,function()
    if F:IsShown() then F:UpdateUI() end; UpdateActiveCooldownBars()
end)

-- ── Slash commands ────────────────────────────────────────────────────────
SLASH_CBUD1="/cbud"; SLASH_CBUD2="/cloth"
SlashCmdList["CBUD"]=function(msg)
    local cmd=(msg or ""):lower():match("^%s*(.-)%s*$")
    if cmd=="archive" then
        if Archive:IsShown() then Archive:Hide()
        else SetActiveTab(Archive.tabRuns); BuildHistoryTab(); Archive:Show() end
    elseif cmd=="reset" then
        StaticPopup_Show("CLOTHWIDGET_CONFIRM_RESET")
    elseif cmd=="scan" then
        ScanTailoringProfession(); ScanCooldowns()
        print("|cffb58cffClothWidget:|r Cooldowns scanned.")
        if currentTab=="tailors" and Archive:IsShown() then BuildTailorTab() end
    elseif cmd=="clear" then
        StaticPopup_Show("CLOTHWIDGET_CLEAR_ALL")
    elseif cmd=="help" then
        print("|cffb58cffClothWidget|r v"..VERSION.." commands:")
        print("  |cffddbbff/cbud|r           — toggle main widget")
        print("  |cffddbbff/cbud archive|r   — toggle archive window")
        print("  |cffddbbff/cbud reset|r     — reset session (confirmation)")
        print("  |cffddbbff/cbud scan|r      — manually scan profession cooldowns")
        print("  |cffddbbff/cbud clear|r     — wipe all data (confirmation)")
        print("  |cffddbbff/cbud help|r      — this help list")
    else
        if F:IsShown() then F:Hide() else F:Show() end
    end
end

print(string.format("|cffb58cffClothWidget v%s|r loaded — type |cffddbbff/cbud|r to open",VERSION))

-- ============================================================================
-- DELVETRACKER PLUGIN REGISTRATIE — ClothCounter
-- ============================================================================
local _dtInt_Cloth = CreateFrame("Frame")
_dtInt_Cloth:RegisterEvent("PLAYER_LOGIN")
_dtInt_Cloth:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if not (DelveTracker and DelveTracker.RegisterPlugin) then return end
    DelveTracker:RegisterPlugin("ClothCounter", function() end)
    -- Plugin registratie alleen — niet automatisch tonen bij login
    -- Gebruiker opent via slash command of murloc menu
end)
