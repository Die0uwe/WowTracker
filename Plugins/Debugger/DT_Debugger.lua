-- =====================================================================
--  DT_Debugger.lua  v3.0  —  DelveTracker Debug Console
--  Loaded last via WowTracker.xml
--
--  [v3.0] Global error capture: ALLE Lua errors met stack+locals (BugSack-stijl)
--  [v3.0] Export = volledig error rapport + debug log
--  [v2.0] Scroll: alle 200 entries zichtbaar (was: 30)
--  [v2.0] Export knop: EditBox popup met volledige log (Ctrl+A, Ctrl+C)
--
--  /dtdebug              → toggle debug panel
--  /dtdebug log          → show full error log
--  /dtdebug db           → print DB health to chat
--  /dtdebug plugins      → list all registered plugins
--  /dtdebug mem          → addon memory usage
--  /dtdebug scan         → re-run weekly scan + refresh
--  /dtdebug clear        → wipe error log
--  /dtdebug errors       → print last 10 errors to chat
-- =====================================================================

if not DelveTracker then
    print("|cffff4444[DT_Debugger]:|r DelveTracker core not loaded — debugger disabled.")
    return
end

-- ─────────────────────────────────────────────────────────────────────
-- Internal log store
-- ─────────────────────────────────────────────────────────────────────
local DBG            = {}
DBG.log              = {}       -- {time, sev, src, msg}
DBG.maxEntries       = 200
DBG.errorCount       = 0
DBG.warnCount        = 0
DBG.sessionStart     = GetTime()

local SEV_COLOR = {
    ERR  = "|cffff4444",
    WARN = "|cffffff44",
    INFO = "|cff44aaff",
    OK   = "|cff44ff88",
    SYS  = "|cffaaaaaa",
}
local SEV_LABEL = {
    ERR  = "ERR",
    WARN = "WRN",
    INFO = "INF",
    OK   = " OK",
    SYS  = "SYS",
}

-- ─────────────────────────────────────────────────────────────────────
-- DBG.Log(sev, src, msg)
-- ─────────────────────────────────────────────────────────────────────
function DBG.Log(sev, src, msg)
    sev = sev or "INFO"
    if sev == "ERR"  then DBG.errorCount = DBG.errorCount + 1 end
    if sev == "WARN" then DBG.warnCount  = DBG.warnCount  + 1 end
    table.insert(DBG.log, 1, {
        time = date("%H:%M:%S"),
        sev  = sev,
        src  = src  or "?",
        msg  = tostring(msg or ""),
    })
    while #DBG.log > DBG.maxEntries do
        table.remove(DBG.log)
    end
    if DBG.frame and DBG.frame:IsShown() then
        DBG._RefreshLog()
    end
end

-- ─────────────────────────────────────────────────────────────────────
-- GLOBAL ERROR CAPTURE — BugSack-stijl (v3.0)
-- Vangt ALLE Lua errors (van elke addon) via seterrorhandler chain.
-- Bewaart message + volledige stack + locals, met dedup teller (Nx).
-- Chained: bestaande handler (bijv. !BugGrabber) blijft gewoon werken.
-- ─────────────────────────────────────────────────────────────────────
DBG.errors = {}
local MAX_ERRORS = 50

local function CaptureError(msg)
    msg = tostring(msg or "?")
    -- Dedup: zelfde message = teller omhoog
    for _, e in ipairs(DBG.errors) do
        if e.msg == msg then
            e.count = e.count + 1
            e.time  = date("%H:%M:%S")
            DBG.Log("ERR", "LuaError", e.count.."x "..msg:sub(1, 110))
            return
        end
    end
    if #DBG.errors >= MAX_ERRORS then table.remove(DBG.errors, 1) end
    table.insert(DBG.errors, {
        msg    = msg,
        stack  = (debugstack  and debugstack(4))  or "",
        locals = (debuglocals and debuglocals(4)) or "",
        count  = 1,
        time   = date("%H:%M:%S"),
    })
    DBG.Log("ERR", "LuaError", msg:sub(1, 110))
end

local _origErrHandler = geterrorhandler and geterrorhandler() or nil
if seterrorhandler then
    seterrorhandler(function(msg)
        pcall(CaptureError, msg)
        if _origErrHandler then return _origErrHandler(msg) end
    end)
end

-- ─────────────────────────────────────────────────────────────────────
-- Wrap plugin calls so errors are captured without crashing
-- ─────────────────────────────────────────────────────────────────────
local _origPluginDispatch = nil
local function _SafeDispatch(pluginName, func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        DBG.Log("ERR", pluginName, tostring(err))
    end
    return ok
end

-- Patch the core's plugin iteration to capture errors
-- (hooks into the OnEvent handler's plugin loop)
local _origOnEvent = nil
do
    local frame = _G["DelveTrackerFrame"]
    if frame then
        local existingScript = frame:GetScript("OnEvent")
        if existingScript then
            _origOnEvent = existingScript
            frame:SetScript("OnEvent", function(self, event, ...)
                local ok, err = pcall(_origOnEvent, self, event, ...)
                if not ok then
                    DBG.Log("ERR", "Core:OnEvent["..tostring(event).."]", tostring(err))
                end
            end)
            DBG.Log("SYS", "Debugger", "OnEvent hook installed")
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────
-- DB health helpers
-- ─────────────────────────────────────────────────────────────────────
local function GetDBStats()
    local stats = {}
    if not DelveTrackerDB then
        return { error = "DelveTrackerDB is nil" }
    end
    stats.charCount      = 0
    stats.charWithDelves = 0
    stats.charWithGear   = 0
    stats.charWithLockout = 0
    local chars = DelveTrackerDB.characters or {}
    for _, d in pairs(chars) do
        stats.charCount = stats.charCount + 1
        if d.delves and #d.delves > 0     then stats.charWithDelves  = stats.charWithDelves  + 1 end
        if d.gear                          then stats.charWithGear    = stats.charWithGear    + 1 end
        if d.lockouts and #d.lockouts > 0  then stats.charWithLockout = stats.charWithLockout + 1 end
    end
    stats.pluginStates = DelveTrackerDB.PluginStates or {}
    stats.pluginCount  = 0
    for _ in pairs(DelveTracker.Plugins) do stats.pluginCount = stats.pluginCount + 1 end
    return stats
end

local function GetMemoryKB()
    if C_AddOns and C_AddOns.UpdateAddOnMemoryUsage then
        C_AddOns.UpdateAddOnMemoryUsage()
        return C_AddOns.GetAddOnMemoryUsage("WowTracker") or 0
    elseif UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
        return GetAddOnMemoryUsage and GetAddOnMemoryUsage("WowTracker") or 0
    end
    return 0
end

-- ─────────────────────────────────────────────────────────────────────
-- Debug UI
-- ─────────────────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 640, 500

local DBG_frame = CreateFrame("Frame", "DT_DebugFrame", UIParent, "BackdropTemplate")
DBG_frame:SetSize(PANEL_W, PANEL_H)
DBG_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
DBG_frame:SetFrameStrata("DIALOG")
DBG_frame:SetMovable(true)
DBG_frame:EnableMouse(true)
DBG_frame:RegisterForDrag("LeftButton")
DBG_frame:SetScript("OnDragStart", DBG_frame.StartMoving)
DBG_frame:SetScript("OnDragStop",  DBG_frame.StopMovingOrSizing)
DBG_frame:Hide()
DBG.frame = DBG_frame

DBG_frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
DBG_frame:SetBackdropColor(0.04, 0.04, 0.06, 0.97)
DBG_frame:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
    -- ── WTTHEME KOPPELING (Fase 3.2 ronde 2 · v3.2.8) ──
    if WTTheme and WTTheme.Register then
        local function _applyTheme()
            local bg  = WTTheme.bg and WTTheme.bg.main
            local bdr = WTTheme.border and WTTheme.border.main
            if bg then DBG_frame:SetBackdropColor(bg.r, bg.g, bg.b, math.max(bg.a or 0.97, 0.95)) end
            -- border blijft debug-groen (functioneel kenmerk)
        end
        WTTheme.Register(_applyTheme)
        _applyTheme()
    end

-- Header bar
local hdr = DBG_frame:CreateTexture(nil, "BACKGROUND")
hdr:SetPoint("TOPLEFT", 1, -1); hdr:SetPoint("TOPRIGHT", -1, -1); hdr:SetHeight(28)
hdr:SetColorTexture(0.06, 0.14, 0.06, 1)

-- Title
local title = DBG_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", 10, -8)
title:SetText("|cff44ff44DT Debug Console|r  |cff888888v3.0  —  WoW 12.0.5.67314|r")

-- Close button
local closeBtn = CreateFrame("Button", nil, DBG_frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)

-- Uptime / error count bar
local statusBar = DBG_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusBar:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -8, -6)
statusBar:SetJustifyH("RIGHT")
DBG.statusBar = statusBar

-- Tab buttons
local TAB_NAMES = { "Log", "Plugins", "DB", "Memory" }
local TAB_FRAMES = {}
local activeTab = 1

local function ShowTabFrame(id)
    for i, f in ipairs(TAB_FRAMES) do
        if f then f:SetShown(i == id) end
    end
    activeTab = id
    DBG._UpdateStatusBar()
end

local tabBtns = {}
for i, name in ipairs(TAB_NAMES) do
    local b = CreateFrame("Button", nil, DBG_frame, "BackdropTemplate")
    b:SetSize(80, 22)
    b:SetPoint("TOPLEFT", 8 + (i-1) * 85, -32)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    b:SetBackdropColor(0.1, 0.1, 0.1, 1)
    b:SetBackdropBorderColor(0.2, 0.5, 0.2, 1)
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("CENTER"); t:SetText(name)
    b:SetScript("OnClick", function() ShowTabFrame(i) end)
    tabBtns[i] = b
end

-- Separator line
local sep = DBG_frame:CreateTexture(nil, "BACKGROUND")
sep:SetPoint("TOPLEFT", 0, -58); sep:SetPoint("TOPRIGHT", 0, -58); sep:SetHeight(1)
sep:SetColorTexture(0.2, 0.5, 0.2, 0.6)

-- ─────────────────────────────────────────────────────────────────────
-- TAB 1: LOG
-- ─────────────────────────────────────────────────────────────────────
local logFrame = CreateFrame("Frame", nil, DBG_frame)
logFrame:SetPoint("TOPLEFT", 0, -62); logFrame:SetPoint("BOTTOMRIGHT", 0, 36)
TAB_FRAMES[1] = logFrame

local logScroll = CreateFrame("ScrollFrame", "DT_DebugLogScroll", logFrame, "UIPanelScrollFrameTemplate")
logScroll:SetPoint("TOPLEFT", 4, -2); logScroll:SetPoint("BOTTOMRIGHT", -26, 2)
local logContent = CreateFrame("Frame", nil, logScroll)
logContent:SetSize(PANEL_W - 40, 1)
logScroll:SetScrollChild(logContent)

local LOG_LINES = {}
local LOG_LINE_H = 13
local MAX_VISIBLE = 200   -- alle 200 entries tonen, niet alleen 30

for i = 1, 30 do   -- pre-alloceer eerste 30 voor snelle start
    local fs = logContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 4, -(i-1) * LOG_LINE_H)
    fs:SetWidth(PANEL_W - 50)
    fs:SetHeight(LOG_LINE_H)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)        -- 1 log entry = exact 1 regel (geen overlap)
    fs:SetNonSpaceWrap(false)
    fs:SetFont("Fonts\\2002.ttf", 10)
    LOG_LINES[i] = fs
end

function DBG._RefreshLog()
    local count = math.min(#DBG.log, MAX_VISIBLE)
    -- Maak ontbrekende FontStrings aan (pool uitbreiden tot count)
    for i = #LOG_LINES + 1, count do
        local fs = logContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 4, -(i-1) * LOG_LINE_H)
        fs:SetWidth(PANEL_W - 50)
        fs:SetHeight(LOG_LINE_H)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)    -- 1 log entry = exact 1 regel (geen overlap)
        fs:SetNonSpaceWrap(false)
        fs:SetFont("Fonts\\2002.ttf", 10)
        LOG_LINES[i] = fs
    end
    -- Tekst instellen
    for i = 1, math.max(#LOG_LINES, count) do
        local fs = LOG_LINES[i]
        if not fs then break end
        local entry = DBG.log[i]
        if entry then
            local sc = SEV_COLOR[entry.sev] or SEV_COLOR.INFO
            local sl = SEV_LABEL[entry.sev] or "   "
            fs:SetText(string.format(
                "|cff666666[%s]|r %s%s|r  |cff88aaff%-14s|r  %s",
                entry.time, sc, sl, entry.src, entry.msg
            ))
        else
            fs:SetText("")
        end
    end
    logContent:SetHeight(count * LOG_LINE_H + 4)
    DBG._UpdateStatusBar()
end

-- ─────────────────────────────────────────────────────────────────────
-- TAB 2: PLUGINS
-- ─────────────────────────────────────────────────────────────────────
local plugFrame = CreateFrame("Frame", nil, DBG_frame)
plugFrame:SetPoint("TOPLEFT", 0, -62); plugFrame:SetPoint("BOTTOMRIGHT", 0, 36)
TAB_FRAMES[2] = plugFrame

local plugScroll = CreateFrame("ScrollFrame", nil, plugFrame, "UIPanelScrollFrameTemplate")
plugScroll:SetPoint("TOPLEFT", 4, -2); plugScroll:SetPoint("BOTTOMRIGHT", -26, 2)
local plugContent = CreateFrame("Frame", nil, plugScroll)
plugContent:SetSize(PANEL_W - 40, 1); plugScroll:SetScrollChild(plugContent)

local PLUG_ROWS = {}

function DBG._RefreshPlugins()
    local states = (DelveTrackerDB and DelveTrackerDB.PluginStates) or {}
    local names = {}
    for n in pairs(DelveTracker.Plugins) do table.insert(names, n) end
    table.sort(names)

    for i, name in ipairs(names) do
        local r = PLUG_ROWS[i]
        if not r then
            r = plugContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            r:SetPoint("TOPLEFT", 6, -(i-1) * 16)
            r:SetWidth(PANEL_W - 60)
            r:SetJustifyH("LEFT")
            PLUG_ROWS[i] = r
        end
        local enabled = states[name] ~= false
        local ec = enabled and "|cff44ff44" or "|cffff4444"
        local el = enabled and " ON " or "OFF "
        r:SetText(string.format("%s[%s]|r  |cffdddddd%s|r", ec, el, name))
    end
    for i = #names + 1, #PLUG_ROWS do
        if PLUG_ROWS[i] then PLUG_ROWS[i]:SetText("") end
    end
    plugContent:SetHeight(#names * 16 + 8)
end

-- ─────────────────────────────────────────────────────────────────────
-- TAB 3: DB HEALTH
-- ─────────────────────────────────────────────────────────────────────
local dbFrame = CreateFrame("Frame", nil, DBG_frame)
dbFrame:SetPoint("TOPLEFT", 0, -62); dbFrame:SetPoint("BOTTOMRIGHT", 0, 36)
TAB_FRAMES[3] = dbFrame

local dbText = dbFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
dbText:SetPoint("TOPLEFT", 10, -8)
dbText:SetWidth(PANEL_W - 20)
dbText:SetJustifyH("LEFT")
dbText:SetFont("Fonts\\2002.ttf", 11)

function DBG._RefreshDB()
    local s = GetDBStats()
    if s.error then
        dbText:SetText("|cffff4444" .. s.error .. "|r")
        return
    end
    local lines = {
        string.format("|cff44ff88Characters in DB:|r  %d", s.charCount),
        string.format("|cff44ff88  → with delves:|r   %d", s.charWithDelves),
        string.format("|cff44ff88  → with gear:|r     %d", s.charWithGear),
        string.format("|cff44ff88  → with lockouts:|r %d", s.charWithLockout),
        "",
        string.format("|cff44aaff Plugins registered:|r %d", s.pluginCount),
        string.format("|cff44aaff SavedVar keys (root):|r %d",
            (function() local n=0; for _ in pairs(DelveTrackerDB) do n=n+1 end; return n end)()),
        "",
        "|cffaaaaaa  Root keys in DelveTrackerDB:|r",
    }
    for k in pairs(DelveTrackerDB) do
        local vtype = type(DelveTrackerDB[k])
        local extra = ""
        if vtype == "table" then
            local n = 0; for _ in pairs(DelveTrackerDB[k]) do n=n+1 end
            extra = string.format("  |cff888888{%d entries}|r", n)
        end
        table.insert(lines, string.format("    |cffdddddd%s|r  |cff666666[%s]|r%s", k, vtype, extra))
    end
    dbText:SetText(table.concat(lines, "\n"))
end

-- ─────────────────────────────────────────────────────────────────────
-- TAB 4: MEMORY
-- ─────────────────────────────────────────────────────────────────────
local memFrame = CreateFrame("Frame", nil, DBG_frame)
memFrame:SetPoint("TOPLEFT", 0, -62); memFrame:SetPoint("BOTTOMRIGHT", 0, 36)
TAB_FRAMES[4] = memFrame

local memText = memFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
memText:SetPoint("TOPLEFT", 10, -8)
memText:SetWidth(PANEL_W - 20)
memText:SetJustifyH("LEFT")
memText:SetFont("Fonts\\2002.ttf", 11)

local _memHistory = {}
local _memTimer = nil

function DBG._RefreshMem()
    local kb = GetMemoryKB()
    table.insert(_memHistory, 1, string.format("[%s]  %.1f KB", date("%H:%M:%S"), kb))
    while #_memHistory > 15 do table.remove(_memHistory) end

    local upSec = math.floor(GetTime() - DBG.sessionStart)
    local upStr = string.format("%dm %02ds", math.floor(upSec/60), upSec % 60)
    local lines = {
        string.format("|cff44ff88Current memory:|r  |cffdddddd%.1f KB|r", kb),
        string.format("|cff44aaff Uptime:|r          %s", upStr),
        string.format("|cffffff44Errors logged:|r   %d", DBG.errorCount),
        string.format("|cffffff44Warnings logged:|r %d", DBG.warnCount),
        "",
        "|cffaaaaaa Memory history:|r",
    }
    for _, h in ipairs(_memHistory) do
        table.insert(lines, "  |cff888888" .. h .. "|r")
    end
    memText:SetText(table.concat(lines, "\n"))
end

-- ─────────────────────────────────────────────────────────────────────
-- Bottom toolbar
-- ─────────────────────────────────────────────────────────────────────
local function MakeToolBtn(label, xOff, onClick)
    local b = CreateFrame("Button", nil, DBG_frame, "BackdropTemplate")
    b:SetSize(90, 22); b:SetPoint("BOTTOMLEFT", xOff, 8)
    b:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    b:SetBackdropColor(0.08, 0.12, 0.08, 1)
    b:SetBackdropBorderColor(0.25, 0.5, 0.25, 1)
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("CENTER"); t:SetText(label)
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.4, 0.9, 0.4, 1) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.25, 0.5, 0.25, 1) end)
    return b
end

MakeToolBtn("Refresh", 8,   function() DBG._RefreshAll() end)
MakeToolBtn("Clr Log", 103, function()
    DBG.log = {}; DBG.errorCount = 0; DBG.warnCount = 0
    DBG._RefreshLog()
    DBG.Log("SYS", "Debugger", "Log cleared by user")
end)
MakeToolBtn("DB Scan", 198, function()
    C_Timer.After(0.1, function()
        if UpdateCharacterList then UpdateCharacterList() end
        DBG._RefreshDB()
        DBG.Log("INFO", "Debugger", "DB scan triggered")
    end)
end)
MakeToolBtn("Mem Snap", 293, function() DBG._RefreshMem() end)
MakeToolBtn("Export",   388, function()
    local out = {}
    -- ── DEEL 1: ERROR RAPPORT (BugSack-stijl) ──
    out[#out+1] = "=== WOWTRACKER ERROR REPORT — "..date("%Y-%m-%d %H:%M:%S").." ==="
    out[#out+1] = "Build: WoW 12.0.5.67314 · Addon: WowTracker"
    out[#out+1] = ""
    if #DBG.errors == 0 then
        out[#out+1] = "(geen Lua errors gevangen deze sessie)"
    else
        for i, e in ipairs(DBG.errors) do
            out[#out+1] = string.format("[%d] %dx  %s", i, e.count, e.msg)
            if e.stack and e.stack ~= "" then
                out[#out+1] = "Stack:"
                out[#out+1] = e.stack
            end
            if e.locals and e.locals ~= "" then
                out[#out+1] = "Locals:"
                out[#out+1] = e.locals
            end
            out[#out+1] = string.rep("-", 60)
        end
    end
    -- ── DEEL 2: DEBUG LOG ──
    out[#out+1] = ""
    out[#out+1] = "=== DEBUG LOG ==="
    for i = #DBG.log, 1, -1 do
        local e = DBG.log[i]
        if e then
            out[#out+1] = string.format("[%s] %-4s  %-16s  %s",
                e.time, e.sev, e.src, e.msg)
        end
    end
    local txt = table.concat(out, "\n")
    -- Vul export-frame in en toon
    if DT_DBG_ExportEdit then
        DT_DBG_ExportEdit:SetText(txt)
        DT_DBG_ExportEdit:HighlightText()
    end
    if DT_DBG_ExportFrame then
        DT_DBG_ExportFrame:Show()
        if DT_DBG_ExportEdit then DT_DBG_ExportEdit:SetFocus() end
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- Export popup frame — EditBox met volledige log tekst
-- Ctrl+A → Ctrl+C om te kopiëren
-- ─────────────────────────────────────────────────────────────────────
local expF = CreateFrame("Frame", "DT_DBG_ExportFrame", UIParent, "BackdropTemplate")
expF:SetSize(640, 420)
expF:SetPoint("CENTER", UIParent, "CENTER", 20, 20)
expF:SetFrameStrata("TOOLTIP")
expF:SetMovable(true); expF:EnableMouse(true)
expF:RegisterForDrag("LeftButton")
expF:SetScript("OnDragStart", expF.StartMoving)
expF:SetScript("OnDragStop",  expF.StopMovingOrSizing)
expF:SetClampedToScreen(true)
expF:Hide()
DT_DBG_ExportFrame = expF

expF:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
expF:SetBackdropColor(0.03, 0.06, 0.03, 0.98)
expF:SetBackdropBorderColor(0.25, 0.75, 0.25, 1)

local expHdr = expF:CreateTexture(nil, "BACKGROUND")
expHdr:SetPoint("TOPLEFT",1,-1); expHdr:SetPoint("TOPRIGHT",-1,-1); expHdr:SetHeight(26)
expHdr:SetColorTexture(0.05, 0.12, 0.05, 1)

local expTitle = expF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
expTitle:SetPoint("TOPLEFT", 10, -7)
expTitle:SetText("|cff44ff44DT Debug Export|r  |cff888888Ctrl+A → Ctrl+C om te kopiëren|r")

local expClose = CreateFrame("Button", nil, expF, "UIPanelCloseButton")
expClose:SetPoint("TOPRIGHT", -2, -2)

local expScroll = CreateFrame("ScrollFrame", nil, expF, "UIPanelScrollFrameTemplate")
expScroll:SetPoint("TOPLEFT", 4, -30)
expScroll:SetPoint("BOTTOMRIGHT", -26, 8)

local expEdit = CreateFrame("EditBox", "DT_DBG_ExportEdit", expScroll)
expEdit:SetMultiLine(true)
expEdit:SetFontObject("GameFontHighlightSmall")
expEdit:SetWidth(600)
expEdit:SetAutoFocus(false)
expEdit:SetScript("OnEscapePressed", function() expF:Hide() end)
expScroll:SetScrollChild(expEdit)
DT_DBG_ExportEdit = expEdit

-- Error counter badge (bottom right)
local errBadge = DBG_frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
errBadge:SetPoint("BOTTOMRIGHT", -8, 12)
errBadge:SetJustifyH("RIGHT")
DBG.errBadge = errBadge

-- ─────────────────────────────────────────────────────────────────────
-- Master refresh
-- ─────────────────────────────────────────────────────────────────────
function DBG._UpdateStatusBar()
    local upSec = math.floor(GetTime() - DBG.sessionStart)
    statusBar:SetText(string.format(
        "|cff888888up %dm%02ds  |r|cffffff44err:%d  wrn:%d|r",
        math.floor(upSec/60), upSec % 60, DBG.errorCount, DBG.warnCount
    ))
    if DBG.errBadge then
        if DBG.errorCount > 0 then
            errBadge:SetText("|cffff4444" .. DBG.errorCount .. " error(s) captured|r")
        else
            errBadge:SetText("|cff44ff44no errors|r")
        end
    end
end

function DBG._RefreshAll()
    DBG._RefreshLog()
    DBG._RefreshPlugins()
    DBG._RefreshDB()
    DBG._RefreshMem()
    DBG._UpdateStatusBar()
end

-- Auto-refresh active tab every 5 seconds while panel is shown
local refreshTimer = CreateFrame("Frame")
local _elapsed = 0
refreshTimer:SetScript("OnUpdate", function(_, dt)
    _elapsed = _elapsed + dt
    if _elapsed >= 5 then
        _elapsed = 0
        if DBG_frame:IsShown() then DBG._UpdateStatusBar() end
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- Show / toggle
-- ─────────────────────────────────────────────────────────────────────
function DBG.Toggle()
    if DBG_frame:IsShown() then
        DBG_frame:Hide()
    else
        DBG_frame:Show()
        DBG._RefreshAll()
        ShowTabFrame(1)
    end
end

-- ─────────────────────────────────────────────────────────────────────
-- Slash command: /dtdebug [subcommand]
-- ─────────────────────────────────────────────────────────────────────
SLASH_DTDEBUG1 = "/dtdebug"
SlashCmdList["DTDEBUG"] = function(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "" then
        DBG.Toggle()

    elseif msg == "log" then
        -- Show last 15 entries in chat
        print("|cff44ff44[DT Debug]|r  Last " .. math.min(15, #DBG.log) .. " log entries:")
        for i = math.min(15, #DBG.log), 1, -1 do
            local e = DBG.log[i]
            if e then
                local sc = SEV_COLOR[e.sev] or SEV_COLOR.INFO
                local sl = SEV_LABEL[e.sev] or "   "
                print(string.format("  |cff666666[%s]|r %s%s|r  |cff88aaff%s|r  %s",
                    e.time, sc, sl, e.src, e.msg))
            end
        end

    elseif msg == "errors" then
        local errors = {}
        for _, e in ipairs(DBG.log) do
            if e.sev == "ERR" then table.insert(errors, e) end
        end
        if #errors == 0 then
            print("|cff44ff44[DT Debug]|r  No errors in log.")
        else
            print("|cff44ff44[DT Debug]|r  " .. #errors .. " error(s) in log (last 10):")
            for i = 1, math.min(10, #errors) do
                local e = errors[i]
                print(string.format("  |cffff4444[%s] %s|r  %s", e.time, e.src, e.msg))
            end
        end

    elseif msg == "db" then
        local s = GetDBStats()
        if s.error then print("|cffff4444[DT Debug] DB ERROR:|r " .. s.error); return end
        print("|cff44ff44[DT Debug]|r  DB Health:")
        print("  Characters: " .. s.charCount)
        print("  → with delves: "  .. s.charWithDelves)
        print("  → with gear: "    .. s.charWithGear)
        print("  → with lockouts: " .. s.charWithLockout)
        print("  Plugins registered: " .. s.pluginCount)

    elseif msg == "plugins" then
        local states = (DelveTrackerDB and DelveTrackerDB.PluginStates) or {}
        print("|cff44ff44[DT Debug]|r  Registered plugins:")
        local names = {}
        for n in pairs(DelveTracker.Plugins) do table.insert(names, n) end
        table.sort(names)
        for _, n in ipairs(names) do
            local en = states[n] ~= false
            print("  " .. (en and "|cff44ff44ON |r" or "|cffff4444OFF|r") .. "  " .. n)
        end

    elseif msg == "mem" then
        local kb = GetMemoryKB()
        print(string.format("|cff44ff44[DT Debug]|r  DelveTracker memory: |cffdddddd%.1f KB|r", kb))

    elseif msg == "scan" then
        C_Timer.After(0.15, function()
            if _G["UpdateCharacterList"] then
                local ok, err = pcall(_G["UpdateCharacterList"])
                if not ok then DBG.Log("ERR", "scan", err) end
            end
            DBG.Log("INFO", "Debugger", "Manual scan complete")
            if DBG_frame:IsShown() then DBG._RefreshAll() end
        end)
        print("|cff44ff44[DT Debug]|r  Scan triggered — check panel or /dtdebug log")

    elseif msg == "clear" then
        DBG.log = {}; DBG.errorCount = 0; DBG.warnCount = 0
        DBG._RefreshLog()
        print("|cff44ff44[DT Debug]|r  Log cleared.")

    elseif msg == "help" then
        print("|cff44ff44[DT Debug]|r  Commands:")
        print("  /dtdebug           — toggle debug panel")
        print("  /dtdebug log       — print last 15 log entries")
        print("  /dtdebug errors    — print captured errors")
        print("  /dtdebug db        — DB health summary")
        print("  /dtdebug plugins   — plugin registry")
        print("  /dtdebug mem       — memory usage")
        print("  /dtdebug scan      — re-run character scan")
        print("  /dtdebug clear     — wipe log")
    else
        print("|cff44ff44[DT Debug]|r  Unknown command. Type /dtdebug help for usage.")
    end
end

-- ─────────────────────────────────────────────────────────────────────
-- Startup log entries
-- ─────────────────────────────────────────────────────────────────────
C_Timer.After(1.0, function()
    DBG.Log("OK",  "Debugger",  "DT_Debugger v3.0 loaded — global error capture actief — /dtdebug voor panel · Export knop beschikbaar")
    DBG.Log("SYS", "Build",     "WoW 12.0.5 build 67314  ·  TOC 120005")
    DBG.Log("SYS", "Version",   "DelveTracker " .. (DelveTracker.Version or "?"))

    -- Log all already-registered plugins
    local names = {}
    for n in pairs(DelveTracker.Plugins) do table.insert(names, n) end
    table.sort(names)
    DBG.Log("OK", "Plugins", #names .. " plugin(s) registered: " .. table.concat(names, ", "))

    -- Log DB character count
    local charCount = 0
    if DelveTrackerDB and DelveTrackerDB.characters then
        for _ in pairs(DelveTrackerDB.characters) do charCount = charCount + 1 end
    end
    DBG.Log("INFO", "DB", charCount .. " character(s) in DelveTrackerDB")

    -- Memory baseline
    local kb = GetMemoryKB()
    DBG.Log("SYS", "Memory", string.format("Baseline: %.1f KB", kb))
    table.insert(_memHistory, 1, string.format("[%s]  %.1f KB  (baseline)", date("%H:%M:%S"), kb))
end)


-- ============================================================================
-- DELVETRACKER PLUGIN REGISTRATIE — Debugger
-- ============================================================================
local _dtInt_DBG = CreateFrame("Frame")
_dtInt_DBG:RegisterEvent("PLAYER_LOGIN")
_dtInt_DBG:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if not (DelveTracker and DelveTracker.RegisterPlugin) then return end
    DelveTracker:RegisterPlugin("Debugger", function() end)
    -- Plugin registratie klaar — geen auto-show
end)
