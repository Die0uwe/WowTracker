-- =====================================================================
--  DT_Debugger.lua  v2.0  -  DelveTracker Debug Console
--  Full revamp: werkende scroll, export/copy, BugSack-stijl
-- =====================================================================

if not DelveTracker then
    print("|cffff4444[DT_Debugger]:|r DelveTracker core not loaded - debugger disabled.")
    return
end

local addonName, addonTable = ...

-- ─── Theme helper ────────────────────────────────────────────────────
local function TH()
    return WTTheme or {
        bg={main={r=0.04,g=0.02,b=0.08,a=0.97},card={r=0.06,g=0.03,b=0.10,a=0.95}},
        border={main={r=0.35,g=0.08,b=0.55,a=1},card={r=0.20,g=0.05,b=0.35,a=0.8},
               active={r=0.55,g=0.15,b=0.85,a=1}},
        c={gold="|cffccaa00",purple="|cffbf00ff",blue="|cff00dfff",
           grey="|cff887799",green="|cff44ff88",red="|cffff5555"}
    }
end
local C_2002 = "Fonts\\2002.ttf"
local SA_PURPLE = "|cffbf00ff"; local SA_BLUE = "|cff00dfff"; local SA_GOLD = "|cffccaa00"
local SA_GREY = "|cff887799"; local SA_GREEN = "|cff44ff88"; local SA_RED = "|cffff4444"

-- ─── Log store ───────────────────────────────────────────────────────
local DBG           = {}
DBG.log             = {}
DBG.maxEntries      = 500
DBG.errorCount      = 0
DBG.warnCount       = 0
DBG.sessionStart    = GetTime()

local SEV_COLOR = {
    ERR  = "|cffff4444", WARN = "|cffffff44",
    INFO = "|cff44aaff", OK   = "|cff44ff88", SYS  = "|cffaaaaaa",
}
local SEV_LABEL = {
    ERR = "ERR", WARN = "WRN", INFO = "INF", OK = " OK", SYS = "SYS",
}

-- ─── DBG.Log ─────────────────────────────────────────────────────────
function DBG.Log(sev, src, msg)
    sev = sev or "INFO"
    if sev == "ERR"  then DBG.errorCount = DBG.errorCount + 1 end
    if sev == "WARN" then DBG.warnCount  = DBG.warnCount  + 1 end
    table.insert(DBG.log, 1, {
        time = date("%H:%M:%S"),
        sev  = sev,
        src  = src or "?",
        msg  = tostring(msg or ""),
    })
    while #DBG.log > DBG.maxEntries do table.remove(DBG.log) end
    if DBG.frame and DBG.frame:IsShown() then DBG._RefreshLog() end
end

-- ─── OnEvent hook ────────────────────────────────────────────────────
do
    local frame = _G["DelveTrackerFrame"]
    if frame then
        local existingScript = frame:GetScript("OnEvent")
        if existingScript then
            frame:SetScript("OnEvent", function(self, event, ...)
                local ok, err = pcall(existingScript, self, event, ...)
                if not ok then
                    DBG.Log("ERR", "Core:OnEvent["..tostring(event).."]", tostring(err))
                end
            end)
            DBG.Log("SYS", "Debugger", "OnEvent hook installed")
        end
    end
end

-- ─── DB + memory helpers ─────────────────────────────────────────────
local function GetDBStats()
    if not DelveTrackerDB then return { error = "DelveTrackerDB is nil" } end
    local s = { charCount=0, charWithDelves=0, charWithGear=0, charWithLockout=0 }
    for _, d in pairs(DelveTrackerDB.characters or {}) do
        s.charCount = s.charCount + 1
        if d.delves   and #d.delves > 0  then s.charWithDelves  = s.charWithDelves  + 1 end
        if d.gear                         then s.charWithGear    = s.charWithGear    + 1 end
        if d.lockouts and #d.lockouts > 0 then s.charWithLockout = s.charWithLockout + 1 end
    end
    s.pluginStates = DelveTrackerDB.PluginStates or {}
    s.pluginCount  = 0
    for _ in pairs(DelveTracker.Plugins) do s.pluginCount = s.pluginCount + 1 end
    return s
end

local function GetMemoryKB()
    if C_AddOns and C_AddOns.UpdateAddOnMemoryUsage then
        C_AddOns.UpdateAddOnMemoryUsage()
        return C_AddOns.GetAddOnMemoryUsage("DelveTracker") or
               C_AddOns.GetAddOnMemoryUsage("WowTracker") or 0
    end
    return 0
end

-- ─── Export helper: zet log naar clipboard via EditBox trick ─────────
local function ExportToClipboard(lines)
    -- Maak een tijdelijke EditBox aan (BugSack methode)
    local eb = CreateFrame("EditBox", "DT_ExportBox", UIParent)
    eb:SetSize(1, 1)
    eb:SetPoint("CENTER", UIParent, "CENTER", 0, -9999)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal)
    eb:SetAutoFocus(true)
    eb:Show()
    eb:SetText(table.concat(lines, "\n"))
    eb:HighlightText()
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus(); self:Hide(); self:SetParent(nil)
    end)
    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus(); self:Hide(); self:SetParent(nil)
    end)
    -- Gebruik native clipboard als beschikbaar
    if eb.SetText then
        local txt = table.concat(lines, "\n")
        -- Probeer C_Clipboard
        if C_Clipboard and C_Clipboard.SetText then
            C_Clipboard.SetText(txt)
            DBG.Log("OK", "Export", "Log gekopieerd naar clipboard ("..#lines.." regels)")
            eb:Hide()
        else
            DBG.Log("INFO", "Export", "Selecteer alle tekst (Ctrl+A) en kopieer (Ctrl+C)")
        end
    end
end

-- ─── Panel constants ─────────────────────────────────────────────────
local PANEL_W, PANEL_H = 640, 520
local LINE_H    = 14
local MAX_LINES = 300  -- max regels in scroll buffer

-- ─── Hoofdframe ──────────────────────────────────────────────────────
local DBG_frame = CreateFrame("Frame","DT_DebugFrame",UIParent,"BackdropTemplate")
DBG_frame:SetSize(PANEL_W, PANEL_H)
DBG_frame:SetPoint("CENTER")
DBG_frame:SetFrameStrata("DIALOG")
DBG_frame:SetFrameLevel(200)
DBG_frame:SetMovable(true)
DBG_frame:EnableMouse(true)
DBG_frame:SetClampedToScreen(true)
DBG_frame:RegisterForDrag("LeftButton")
DBG_frame:SetScript("OnDragStart", DBG_frame.StartMoving)
DBG_frame:SetScript("OnDragStop",  DBG_frame.StopMovingOrSizing)
DBG_frame:Hide()
DBG.frame = DBG_frame

do local b=TH().bg.main
   DBG_frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
   DBG_frame:SetBackdropColor(b.r,b.g,b.b,b.a)
   DBG_frame:SetBackdropBorderColor(0.45,0.08,0.70,1)
end

-- Header
local hdr = DBG_frame:CreateTexture(nil,"BACKGROUND")
hdr:SetPoint("TOPLEFT",1,-1); hdr:SetPoint("TOPRIGHT",-1,-1); hdr:SetHeight(28)
hdr:SetColorTexture(0.05,0.02,0.09,1)

local title = DBG_frame:CreateFontString(nil,"OVERLAY")
title:SetPoint("TOPLEFT",10,-8); title:SetFont(C_2002,11,"OUTLINE")
title:SetText(SA_GREEN.."DT Debug Console|r  "..SA_GREY.."v2.0  WoW 12.0.5.67314|r")

local closeBtn = CreateFrame("Button",nil,DBG_frame,"UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT",-2,-2)

local statusBar = DBG_frame:CreateFontString(nil,"OVERLAY")
statusBar:SetFont(C_2002,9,""); statusBar:SetTextColor(0.75,0.75,0.75,1)
statusBar:SetPoint("TOPRIGHT",closeBtn,"TOPLEFT",-8,-6); statusBar:SetJustifyH("RIGHT")
DBG.statusBar = statusBar

-- ─── TAB KNOPPEN ─────────────────────────────────────────────────────
local TAB_NAMES  = {"Log","Plugins","DB","Memory"}
local TAB_FRAMES = {}
local activeTab  = 1

local function ShowTabFrame(id)
    for i,f in ipairs(TAB_FRAMES) do if f then f:SetShown(i==id) end end
    activeTab = id
    DBG._UpdateStatusBar()
    if id==1 then DBG._RefreshLog()
    elseif id==2 then DBG._RefreshPlugins()
    elseif id==3 then DBG._RefreshDB()
    elseif id==4 then DBG._RefreshMem() end
end

local tabBtns = {}
for i,name in ipairs(TAB_NAMES) do
    local b = CreateFrame("Button",nil,DBG_frame,"BackdropTemplate")
    b:SetSize(80,22); b:SetPoint("TOPLEFT",8+(i-1)*85,-32)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.10,0.05,0.15,1); b:SetBackdropBorderColor(0.35,0.08,0.55,0.9)
    local t = b:CreateFontString(nil,"OVERLAY")
    t:SetPoint("CENTER"); t:SetFont(C_2002,10,"OUTLINE"); t:SetTextColor(0.80,0.95,0.80,1)
    t:SetText(name)
    b:SetScript("OnClick",function() ShowTabFrame(i) end)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.55,0.15,0.85,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.35,0.08,0.55,0.9) end)
    tabBtns[i] = b
end

local sep = DBG_frame:CreateTexture(nil,"BACKGROUND")
sep:SetPoint("TOPLEFT",0,-58); sep:SetPoint("TOPRIGHT",0,-58); sep:SetHeight(1)
sep:SetColorTexture(0.35,0.08,0.55,0.6)

-- ─── TAB 1: LOG (werkende scroll + export) ───────────────────────────
local logFrame = CreateFrame("Frame",nil,DBG_frame)
logFrame:SetPoint("TOPLEFT",0,-62); logFrame:SetPoint("BOTTOMRIGHT",0,36)
TAB_FRAMES[1] = logFrame

-- ScrollFrame met UIPanelScrollFrameTemplate
local logScroll = CreateFrame("ScrollFrame","DT_DBG_LogScroll",logFrame,"UIPanelScrollFrameTemplate")
logScroll:SetPoint("TOPLEFT",4,-2); logScroll:SetPoint("BOTTOMRIGHT",-24,2)

-- ScrollChild: MUST be sized to TOTAL content height, not just visible
local logContent = CreateFrame("Frame",nil,logScroll)
logContent:SetWidth(PANEL_W - 44)
logContent:SetHeight(1)  -- wordt dynamisch gezet
logScroll:SetScrollChild(logContent)

-- Pre-alloceer log line fontstrings (pool voor MAX_LINES)
local LOG_LINES = {}
for i = 1, MAX_LINES do
    local fs = logContent:CreateFontString(nil,"OVERLAY")
    fs:SetFont(C_2002, 11, "")
    fs:SetPoint("TOPLEFT", 4, -(i-1) * LINE_H)
    fs:SetWidth(PANEL_W - 60)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(0.85,0.85,0.85,1)
    fs:SetText("")
    LOG_LINES[i] = fs
end

function DBG._RefreshLog()
    local count = math.min(#DBG.log, MAX_LINES)
    for i = 1, count do
        local e = DBG.log[i]
        if e then
            local sc = SEV_COLOR[e.sev] or SEV_COLOR.INFO
            local sl = SEV_LABEL[e.sev] or "   "
            LOG_LINES[i]:SetText(string.format(
                "|cff555555[%s]|r %s%-3s|r  "..SA_BLUE.."%-16s|r  %s",
                e.time, sc, sl, e.src:sub(1,16), e.msg
            ))
        else
            LOG_LINES[i]:SetText("")
        end
    end
    -- Verberg ongebruikte lijnen
    for i = count+1, MAX_LINES do LOG_LINES[i]:SetText("") end
    -- KRITIEK: stel content height in op totaal aantal regels
    logContent:SetHeight(math.max(count * LINE_H + 8, logScroll:GetHeight()))
    DBG._UpdateStatusBar()
end

-- ─── TAB 2: PLUGINS ──────────────────────────────────────────────────
local plugFrame = CreateFrame("Frame",nil,DBG_frame)
plugFrame:SetPoint("TOPLEFT",0,-62); plugFrame:SetPoint("BOTTOMRIGHT",0,36)
TAB_FRAMES[2] = plugFrame

local plugScroll = CreateFrame("ScrollFrame",nil,plugFrame,"UIPanelScrollFrameTemplate")
plugScroll:SetPoint("TOPLEFT",4,-2); plugScroll:SetPoint("BOTTOMRIGHT",-24,2)
local plugContent = CreateFrame("Frame",nil,plugScroll)
plugContent:SetWidth(PANEL_W-44); plugContent:SetHeight(1)
plugScroll:SetScrollChild(plugContent)

local PLUG_ROWS = {}
function DBG._RefreshPlugins()
    local states = (DelveTrackerDB and DelveTrackerDB.PluginStates) or {}
    local names = {}
    for n in pairs(DelveTracker.Plugins) do table.insert(names,n) end
    table.sort(names)
    for i,name in ipairs(names) do
        local r = PLUG_ROWS[i]
        if not r then
            r = plugContent:CreateFontString(nil,"OVERLAY")
            r:SetPoint("TOPLEFT",6,-(i-1)*18)
            r:SetWidth(PANEL_W-60); r:SetJustifyH("LEFT")
            r:SetFont(C_2002,11,""); r:SetTextColor(0.85,0.85,0.85,1)
            PLUG_ROWS[i] = r
        end
        local en = states[name] ~= false
        local ec = en and SA_GREEN or SA_RED
        r:SetText(string.format("%s[%s]|r  |cffdddddd%s|r", ec, en and " ON " or "OFF ", name))
    end
    for i=#names+1,#PLUG_ROWS do if PLUG_ROWS[i] then PLUG_ROWS[i]:SetText("") end end
    plugContent:SetHeight(math.max(#names*18+8, plugScroll:GetHeight()))
end

-- ─── TAB 3: DB ───────────────────────────────────────────────────────
local dbFrame = CreateFrame("Frame",nil,DBG_frame)
dbFrame:SetPoint("TOPLEFT",0,-62); dbFrame:SetPoint("BOTTOMRIGHT",0,36)
TAB_FRAMES[3] = dbFrame

local dbScroll = CreateFrame("ScrollFrame",nil,dbFrame,"UIPanelScrollFrameTemplate")
dbScroll:SetPoint("TOPLEFT",4,-2); dbScroll:SetPoint("BOTTOMRIGHT",-24,2)
local dbContent = CreateFrame("Frame",nil,dbScroll)
dbContent:SetWidth(PANEL_W-44); dbContent:SetHeight(1)
dbScroll:SetScrollChild(dbContent)

local dbText = dbContent:CreateFontString(nil,"OVERLAY")
dbText:SetPoint("TOPLEFT",4,-4); dbText:SetWidth(PANEL_W-52)
dbText:SetJustifyH("LEFT"); dbText:SetFont(C_2002,11,""); dbText:SetTextColor(0.85,0.85,0.85,1)

function DBG._RefreshDB()
    local s = GetDBStats()
    if s.error then dbText:SetText(SA_RED..s.error.."|r"); return end
    local lines = {
        SA_GREEN.."Characters in DB:|r  "..s.charCount,
        SA_GREEN.."  -> with delves:|r   "..s.charWithDelves,
        SA_GREEN.."  -> with gear:|r     "..s.charWithGear,
        SA_GREEN.."  -> with lockouts:|r "..s.charWithLockout,
        "",
        SA_BLUE.."Plugins registered:|r "..s.pluginCount,
        SA_BLUE.."SavedVar keys (root):|r "..(function() local n=0; for _ in pairs(DelveTrackerDB) do n=n+1 end; return n end)(),
        "",SA_GREY.."Root keys in DelveTrackerDB:|r",
    }
    local keys={}; for k in pairs(DelveTrackerDB) do table.insert(keys,k) end; table.sort(keys)
    for _,k in ipairs(keys) do
        local v = DelveTrackerDB[k]
        local vt = type(v)
        local extra = ""
        if vt=="table" then
            local n=0; for _ in pairs(v) do n=n+1 end
            extra = string.format("  "..SA_GREY.."{%d entries}|r",n)
        end
        table.insert(lines,string.format("    |cffdddddd%s|r  |cff666666[%s]|r%s",k,vt,extra))
    end
    dbText:SetText(table.concat(lines,"\n"))
    local lh = select(2, dbText:GetFont()) or 11
    dbContent:SetHeight(math.max(#lines*lh+12, dbScroll:GetHeight()))
end

-- ─── TAB 4: MEMORY ───────────────────────────────────────────────────
local memFrame = CreateFrame("Frame",nil,DBG_frame)
memFrame:SetPoint("TOPLEFT",0,-62); memFrame:SetPoint("BOTTOMRIGHT",0,36)
TAB_FRAMES[4] = memFrame

local memText = memFrame:CreateFontString(nil,"OVERLAY")
memText:SetPoint("TOPLEFT",10,-8); memText:SetWidth(PANEL_W-20)
memText:SetJustifyH("LEFT"); memText:SetFont(C_2002,11,""); memText:SetTextColor(0.85,0.85,0.85,1)

local _memHistory = {}
function DBG._RefreshMem()
    local kb = GetMemoryKB()
    table.insert(_memHistory,1,string.format("[%s]  %.1f KB",date("%H:%M:%S"),kb))
    while #_memHistory>20 do table.remove(_memHistory) end
    local up = math.floor(GetTime()-DBG.sessionStart)
    local lines = {
        SA_GREEN.."Current memory:|r  |cffdddddd"..string.format("%.1f KB",kb).."|r",
        SA_BLUE.."Uptime:|r          "..string.format("%dm %02ds",math.floor(up/60),up%60),
        "|cffffff44Errors:|r          "..DBG.errorCount,
        "|cffffff44Warnings:|r        "..DBG.warnCount,
        "",SA_GREY.."Memory snapshots:|r",
    }
    for _,h in ipairs(_memHistory) do table.insert(lines,"  "..SA_GREY..h.."|r") end
    memText:SetText(table.concat(lines,"\n"))
end

-- ─── Bottom toolbar ──────────────────────────────────────────────────
local ERR_BADGE = DBG_frame:CreateFontString(nil,"OVERLAY")
ERR_BADGE:SetFont(C_2002,10,""); ERR_BADGE:SetTextColor(0.85,0.85,0.85,1)
ERR_BADGE:SetPoint("BOTTOMRIGHT",-8,12); ERR_BADGE:SetJustifyH("RIGHT")
DBG.errBadge = ERR_BADGE

local function MakeBtn(lbl, x, onClick)
    local b = CreateFrame("Button",nil,DBG_frame,"BackdropTemplate")
    b:SetSize(88,22); b:SetPoint("BOTTOMLEFT",x,8)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.06,0.10,0.06,1); b:SetBackdropBorderColor(0.25,0.55,0.25,1)
    local t = b:CreateFontString(nil,"OVERLAY"); t:SetPoint("CENTER")
    t:SetFont(C_2002,10,""); t:SetTextColor(0.85,0.95,0.85,1); t:SetText(lbl)
    b:SetScript("OnClick",onClick)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.4,0.9,0.4,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.25,0.55,0.25,1) end)
    return b
end

MakeBtn("Refresh",   8,   function() DBG._RefreshAll() end)
MakeBtn("Clr Log",   101, function()
    DBG.log={}; DBG.errorCount=0; DBG.warnCount=0
    DBG._RefreshLog()
    DBG.Log("SYS","Debugger","Log cleared")
end)
MakeBtn("DB Scan",   194, function()
    C_Timer.After(0.1,function()
        if UpdateCharacterList then pcall(UpdateCharacterList) end
        DBG._RefreshDB()
        DBG.Log("INFO","Debugger","DB scan triggered")
    end)
end)
MakeBtn("Mem Snap",  287, function() DBG._RefreshMem() end)

-- Export knop (nieuw v2.0 - BugSack stijl)
local exportBtn = MakeBtn("[ Copy Log ]", 380, function()
    local lines = {"-- WowTracker Debug Export -- "..date("%Y-%m-%d %H:%M:%S")}
    for i = math.min(#DBG.log,200), 1, -1 do
        local e = DBG.log[i]
        if e then
            table.insert(lines, string.format("[%s] %-4s  %-20s  %s",
                e.time, e.sev, e.src, e.msg))
        end
    end
    ExportToClipboard(lines)
end)
exportBtn:SetWidth(110)
do
    local eb = exportBtn:GetFontString()
    if eb then eb:SetText("[ Copy Log ]") end
end

-- ─── Status bar update ───────────────────────────────────────────────
function DBG._UpdateStatusBar()
    local up = math.floor(GetTime()-DBG.sessionStart)
    statusBar:SetText(string.format(
        SA_GREY.."up %dm%02ds  |r|cffffff44err:%d  wrn:%d|r",
        math.floor(up/60), up%60, DBG.errorCount, DBG.warnCount
    ))
    if DBG.errorCount > 0 then
        ERR_BADGE:SetText(SA_RED..DBG.errorCount.." error(s) captured|r")
    else
        ERR_BADGE:SetText(SA_GREEN.."no errors|r")
    end
end

function DBG._RefreshAll()
    if activeTab==1 then DBG._RefreshLog()
    elseif activeTab==2 then DBG._RefreshPlugins()
    elseif activeTab==3 then DBG._RefreshDB()
    elseif activeTab==4 then DBG._RefreshMem() end
    DBG._UpdateStatusBar()
end

-- Auto-refresh elke 5 sec
local _el=0
local refreshFrame = CreateFrame("Frame")
refreshFrame:SetScript("OnUpdate",function(_,dt)
    _el=_el+dt
    if _el>=5 then _el=0; if DBG_frame:IsShown() then DBG._UpdateStatusBar() end end
end)

-- ─── Toggle ──────────────────────────────────────────────────────────
function DBG.Toggle()
    if DBG_frame:IsShown() then
        DBG_frame:Hide()
    else
        DBG_frame:Show()
        DBG._RefreshAll()
        ShowTabFrame(activeTab)
    end
end

-- ─── Slash commands ──────────────────────────────────────────────────
SLASH_DTDEBUG1 = "/dtdebug"
SLASH_DTDEBUG2 = "/wt-debug"
SlashCmdList["DTDEBUG"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg=="" then DBG.Toggle()
    elseif msg=="log" then
        print(SA_GREEN.."[DT Debug]|r  Laatste "..math.min(15,#DBG.log).." entries:")
        for i=math.min(15,#DBG.log),1,-1 do
            local e=DBG.log[i]; if e then
                print(string.format("  "..SA_GREY.."[%s]|r %s%-3s|r  "..SA_BLUE.."%-16s|r  %s",
                    e.time,(SEV_COLOR[e.sev] or ""),SEV_LABEL[e.sev] or "?",e.src,e.msg))
            end
        end
    elseif msg=="errors" then
        local errs={}
        for _,e in ipairs(DBG.log) do if e.sev=="ERR" then table.insert(errs,e) end end
        if #errs==0 then print(SA_GREEN.."[DT Debug]|r  Geen errors.")
        else
            print(SA_GREEN.."[DT Debug]|r  "..#errs.." error(s) (laatste 10):")
            for i=1,math.min(10,#errs) do
                local e=errs[i]
                print(string.format("  "..SA_RED.."[%s] %s|r  %s",e.time,e.src,e.msg))
            end
        end
    elseif msg=="db" then
        local s=GetDBStats()
        if s.error then print(SA_RED.."[DT Debug] DB ERROR:|r "..s.error); return end
        print(SA_GREEN.."[DT Debug]|r  DB Health:")
        print("  Characters: "..s.charCount.."  |  Plugins: "..s.pluginCount)
        print("  -> delves: "..s.charWithDelves.."  gear: "..s.charWithGear.."  lockouts: "..s.charWithLockout)
    elseif msg=="plugins" then
        local states=(DelveTrackerDB and DelveTrackerDB.PluginStates) or {}
        print(SA_GREEN.."[DT Debug]|r  Plugins:")
        local names={}; for n in pairs(DelveTracker.Plugins) do table.insert(names,n) end
        table.sort(names)
        for _,n in ipairs(names) do
            local en=states[n]~=false
            print("  "..(en and SA_GREEN.."ON |r" or SA_RED.."OFF|r").."  "..n)
        end
    elseif msg=="mem" then
        print(string.format(SA_GREEN.."[DT Debug]|r  Memory: "..SA_BLUE.."%.1f KB|r",GetMemoryKB()))
    elseif msg=="scan" then
        C_Timer.After(0.15,function()
            if UpdateCharacterList then pcall(UpdateCharacterList) end
            DBG.Log("INFO","Debugger","Manual scan complete")
            if DBG_frame:IsShown() then DBG._RefreshAll() end
        end)
        print(SA_GREEN.."[DT Debug]|r  Scan gestart")
    elseif msg=="clear" then
        DBG.log={}; DBG.errorCount=0; DBG.warnCount=0
        DBG._RefreshLog()
        print(SA_GREEN.."[DT Debug]|r  Log gewist.")
    elseif msg=="copy" then
        local lines={"-- WowTracker Debug Export -- "..date("%Y-%m-%d %H:%M:%S")}
        for i=math.min(#DBG.log,200),1,-1 do
            local e=DBG.log[i]; if e then
                table.insert(lines,string.format("[%s] %-4s  %-20s  %s",e.time,e.sev,e.src,e.msg))
            end
        end
        ExportToClipboard(lines)
    else
        print(SA_GREEN.."[DT Debug]|r  Commando's: log / errors / db / plugins / mem / scan / clear / copy")
    end
end

-- ─── Startup log ─────────────────────────────────────────────────────
C_Timer.After(1.0, function()
    DBG.Log("OK",  "Debugger", "DT_Debugger v2.0 geladen - /dtdebug")
    DBG.Log("SYS", "Build",    "WoW 12.0.5 build 67314  .  TOC 120005")
    DBG.Log("SYS", "Version",  "WowTracker "..(DelveTracker.Version or "?"))
    local names={}; for n in pairs(DelveTracker.Plugins) do table.insert(names,n) end
    table.sort(names)
    DBG.Log("OK", "Plugins", #names.." plugin(s): "..table.concat(names,", "))
    local cc=0; if DelveTrackerDB and DelveTrackerDB.characters then
        for _ in pairs(DelveTrackerDB.characters) do cc=cc+1 end
    end
    DBG.Log("INFO", "DB", cc.." karakter(s) in DelveTrackerDB")
    DBG.Log("SYS",  "Memory", string.format("Baseline: %.1f KB",GetMemoryKB()))
    table.insert(_memHistory,1,string.format("[%s]  %.1f KB  (baseline)",date("%H:%M:%S"),GetMemoryKB()))
end)

-- ─── Plugin registratie ──────────────────────────────────────────────
local _reg = CreateFrame("Frame")
_reg:RegisterEvent("PLAYER_LOGIN")
_reg:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if DelveTracker and DelveTracker.RegisterPlugin then
        DelveTracker:RegisterPlugin("Debugger", function() end)
    end
end)
