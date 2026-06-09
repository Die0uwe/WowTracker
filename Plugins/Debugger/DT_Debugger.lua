-- =====================================================================
--  DT_Debugger.lua  v1.0  —  DelveTracker Debug Console
--  Loaded last via DelveTracker.xml
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

-- WTTheme: centraal kleurensysteem (Fase 3 — T04b)
local function TH()
    return WTTheme or {
        bg={main={r=0.04,g=0.02,b=0.08,a=0.97},card={r=0.06,g=0.03,b=0.10,a=0.95},
            row={r=0.05,g=0.02,b=0.08,a=0.90}},
        border={main={r=0.35,g=0.08,b=0.55,a=1},card={r=0.20,g=0.05,b=0.35,a=0.8},
               active={r=0.55,g=0.15,b=0.85,a=1}},
        c={gold="|cffccaa00",purple="|cffbf00ff",blue="|cff00dfff",
           grey="|cff887799",green="|cff44ff88",red="|cffff5555"}
    }
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
        return C_AddOns.GetAddOnMemoryUsage("DelveTracker") or 0
    elseif UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
        return GetAddOnMemoryUsage and GetAddOnMemoryUsage("DelveTracker") or 0
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
do local _b=TH().bg.main; DBG_frame:SetBackdropColor(_b.r,_b.g,_b.b,_b.a) end
DBG_frame:SetBackdropBorderColor(0.45, 0.08, 0.70, 1)  -- SA purple border

-- Header bar
local hdr = DBG_frame:CreateTexture(nil, "BACKGROUND")
hdr:SetPoint("TOPLEFT", 1, -1); hdr:SetPoint("TOPRIGHT", -1, -1); hdr:SetHeight(28)
hdr:SetColorTexture(0.05, 0.02, 0.09, 1)  -- SA dark header

-- Title
local title = DBG_frame:CreateFontString(nil, "OVERLAY")
title:SetPoint("TOPLEFT", 10, -8)
title:SetFont("Fonts\\2002.ttf", 11, "OUTLINE")
title:SetText("|cff44ff44DT Debug Console|r  |cff888888v1.0  —  WoW 12.0.5.67314|r")

-- Close button
local closeBtn = CreateFrame("Button", nil, DBG_frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)

-- Uptime / error count bar
local statusBar = DBG_frame:CreateFontString(nil, "OVERLAY")
statusBar:SetFont("Fonts\\2002.ttf", 9, "")
statusBar:SetTextColor(0.75, 0.75, 0.75, 1)
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
    b:SetBackdropBorderColor(0.35, 0.08, 0.55, 0.9)
    local t = b:CreateFontString(nil, "OVERLAY")
    t:SetPoint("CENTER")
    t:SetFont("Fonts\\2002.ttf", 10, "OUTLINE")
    t:SetTextColor(0.80, 0.95, 0.80, 1)
    t:SetText(name)
    b:SetScript("OnClick", function() ShowTabFrame(i) end)
    tabBtns[i] = b
end

-- Separator line
local sep = DBG_frame:CreateTexture(nil, "BACKGROUND")
sep:SetPoint("TOPLEFT", 0, -58); sep:SetPoint("TOPRIGHT", 0, -58); sep:SetHeight(1)
sep:SetColorTexture(0.35, 0.08, 0.55, 0.6)  -- SA purple sep

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
local MAX_VISIBLE = 30

for i = 1, MAX_VISIBLE do
    local fs = logContent:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("TOPLEFT", 4, -(i-1) * LOG_LINE_H)
    fs:SetWidth(PANEL_W - 50)
    fs:SetJustifyH("LEFT")
    fs:SetFont("Fonts\\2002.ttf", 10, "")
    fs:SetTextColor(0.85, 0.85, 0.85, 1)  -- explicit kleur zodat het nooit wit-op-wit is
    LOG_LINES[i] = fs
end

function DBG._RefreshLog()
    local count = math.min(#DBG.log, MAX_VISIBLE)
    for i = 1, MAX_VISIBLE do
        local entry = DBG.log[i]
        if entry then
            local sc = SEV_COLOR[entry.sev] or SEV_COLOR.INFO
            local sl = SEV_LABEL[entry.sev] or "   "
            LOG_LINES[i]:SetText(string.format(
                "|cff666666[%s]|r %s%s|r  |cff88aaff%-14s|r  %s",
                entry.time, sc, sl, entry.src, entry.msg
            ))
        else
            LOG_LINES[i]:SetText("")
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
            r = plugContent:CreateFontString(nil, "OVERLAY")
            r:SetPoint("TOPLEFT", 6, -(i-1) * 16)
            r:SetWidth(PANEL_W - 60)
            r:SetJustifyH("LEFT")
            r:SetFont("Fonts\\2002.ttf", 10, "")
            r:SetTextColor(0.85, 0.85, 0.85, 1)
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

local dbText = dbFrame:CreateFontString(nil, "OVERLAY")
dbText:SetPoint("TOPLEFT", 10, -8)
dbText:SetWidth(PANEL_W - 20)
dbText:SetJustifyH("LEFT")
dbText:SetFont("Fonts\\2002.ttf", 11, "")
dbText:SetTextColor(0.85, 0.85, 0.85, 1)

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

local memText = memFrame:CreateFontString(nil, "OVERLAY")
memText:SetPoint("TOPLEFT", 10, -8)
memText:SetWidth(PANEL_W - 20)
memText:SetJustifyH("LEFT")
memText:SetFont("Fonts\\2002.ttf", 11, "")
memText:SetTextColor(0.85, 0.85, 0.85, 1)

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
    local t = b:CreateFontString(nil, "OVERLAY")
    t:SetPoint("CENTER")
    t:SetFont("Fonts\\2002.ttf", 10, "")
    t:SetTextColor(0.85, 0.95, 0.85, 1)
    t:SetText(label)
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

-- Error counter badge (bottom right)
local errBadge = DBG_frame:CreateFontString(nil, "OVERLAY")
errBadge:SetFont("Fonts\\2002.ttf", 10, "")
errBadge:SetTextColor(0.85, 0.85, 0.85, 1)
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
    DBG.Log("OK",  "Debugger",  "DT_Debugger v1.0 loaded — /dtdebug for panel")
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
