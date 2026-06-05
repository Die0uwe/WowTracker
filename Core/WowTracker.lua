-- ============================================================================
-- WowTracker — Core Engine v1.0.0
-- Retail 12.0.5 / Build 67314 (Midnight) / Interface: 120005
-- Replaces: DelveTracker.lua v16.9
-- Author: DieOuwe · Slayer Alliance · Sporeggar-EU
-- ============================================================================
local ADDON_NAME, WT = ...

WowTracker = WowTracker or {}
local WT_CORE = WowTracker

WT_CORE.Version  = "1.0.0"
WT_CORE.Build    = "12.0.5.67314"
WT_CORE.Plugins  = {}
WT_CORE.Events   = {}
WT_CORE.DevMode  = false

local C_PURPLE = "|cffbf00ff"
local C_BLUE   = "|cff00dfff"
local C_GOLD   = "|cffccaa00"
local C_RED    = "|cffff4444"
local C_RESET  = "|r"

local MEDIA    = "Interface\\AddOns\\WowTracker\\Media\\"
local FONT     = "Fonts\\2002.ttf"

local SHELL_W   = 920
local SHELL_H   = 640
local SIDEBAR_W = 165
local HEADER_H  = 58
local FOOTER_H  = 26

-- ============================================================================
-- DB BOOTSTRAP + MIGRATIONS
-- ============================================================================
local DB_VERSION = 1
local migrations = {
    [1] = function(db)
        db.plugins  = db.plugins  or {}
        db.settings = db.settings or {}
        db.settings.scale = db.settings.scale or db.scale or 1.0
    end,
}

local function InitDB()
    WowTrackerDB = WowTrackerDB or {}
    local db = WowTrackerDB
    if DelveTrackerDB and not db._migrated then
        db.characters   = DelveTrackerDB.characters   or {}
        db.PluginStates = DelveTrackerDB.PluginStates or {}
        db._migrated    = true
    end
    db.version      = db.version      or 0
    db.characters   = db.characters   or {}
    db.PluginStates = db.PluginStates or {}
    db.plugins      = db.plugins      or {}
    db.settings     = db.settings     or { shellPos=nil, mbtnPos=nil, scale=1.0, activeTab=nil }
    return db
end

local function RunMigrations(db)
    for v = (db.version + 1), DB_VERSION do
        if migrations[v] then
            local ok, err = pcall(migrations[v], db)
            if ok then db.version = v
            else print(C_RED.."[WowTracker] Migration v"..v.." failed: "..tostring(err)..C_RESET) end
        end
    end
end

-- ============================================================================
-- CENTRAL EVENT BUS
-- ============================================================================
local EventBus = CreateFrame("Frame", "WowTrackerEventBus", UIParent)

function WT_CORE:On(event, callback)
    if not self.Events[event] then
        self.Events[event] = {}
        EventBus:RegisterEvent(event)
    end
    table.insert(self.Events[event], callback)
end

EventBus:SetScript("OnEvent", function(self, event, ...)
    local cbs = WowTracker.Events[event]
    if not cbs then return end
    for i = 1, #cbs do
        local ok, err = pcall(cbs[i], event, ...)
        if not ok then
            print(C_RED.."[WowTracker:Bus] "..event..": "..tostring(err)..C_RESET)
        end
    end
end)

-- ============================================================================
-- PLUGIN MANIFEST API
-- ============================================================================
function WT_CORE:RegisterPlugin(d)
    assert(type(d)=="table" and type(d.id)=="string" and type(d.name)=="string",
        "[WowTracker] RegisterPlugin: id + name required")
    self.Plugins[d.id] = d
    WowTrackerDB = WowTrackerDB or {}
    WowTrackerDB.PluginStates = WowTrackerDB.PluginStates or {}
    if WowTrackerDB.PluginStates[d.id] == nil then
        WowTrackerDB.PluginStates[d.id] = (d.enabled ~= false)
    end
    if d.events then
        for _, ev in ipairs(d.events) do
            self:On(ev, function(event, ...)
                if not self:IsPluginEnabled(d.id) then return end
                if d.onEvent then pcall(d.onEvent, event, ...) end
            end)
        end
    end
end

function WT_CORE:IsPluginEnabled(id)
    return WowTrackerDB and WowTrackerDB.PluginStates[id] ~= false
end

function WT_CORE:EnablePlugin(id)
    if WowTrackerDB then WowTrackerDB.PluginStates[id] = true end
    local p = self.Plugins[id]
    if p and p.onEnable then pcall(p.onEnable) end
    self:RefreshShellSidebar()
end

function WT_CORE:DisablePlugin(id)
    if WowTrackerDB then WowTrackerDB.PluginStates[id] = false end
    local p = self.Plugins[id]
    if p and p.onDisable then pcall(p.onDisable) end
    self:RefreshShellSidebar()
end

-- Legacy compat: DelveTracker:RegisterPlugin(name, func)
DelveTracker = DelveTracker or {}
DelveTracker.Plugins = {}
function DelveTracker:RegisterPlugin(name, func)
    DelveTracker.Plugins[name] = func
    WT_CORE:RegisterPlugin({
        id="legacy_"..name:lower():gsub("%s+","_"), name=name,
        version="legacy", category="Utility", icon="🔧", enabled=true,
        _legacyFunc=func,
    })
end

-- ============================================================================
-- CENTRAL SCANNER POOL
-- ============================================================================
local SCAN_THROTTLE = 2.0
local lastScan      = 0

local function GetCharKey()
    local n = UnitName("player")
    local r = GetNormalizedRealmName() or GetRealmName() or "Unknown"
    return n and (n.."-"..r) or nil
end

local function RunScanners()
    local now = GetTime()
    if (now - lastScan) < SCAN_THROTTLE then return end
    lastScan = now
    local db  = WowTrackerDB; if not db then return end
    local key = GetCharKey();  if not key then return end
    db.characters      = db.characters or {}
    db.characters[key] = db.characters[key] or {}
    local char = db.characters[key]

    -- Core delve scan
    local ok, err = pcall(WT_CORE.ScanCoreData, WT_CORE, char, key)
    if not ok then print(C_RED.."[WowTracker:Scanner] Core: "..tostring(err)..C_RESET) end

    -- Plugin scans
    for id, p in pairs(WT_CORE.Plugins) do
        if WT_CORE:IsPluginEnabled(id) and p.scan then
            local pOk, pErr = pcall(p.scan, key, char, db)
            if not pOk then
                print(C_RED.."[WowTracker:Scanner] "..id..": "..tostring(pErr)..C_RESET)
            end
        end
    end
end

function WT_CORE:ScanCoreData(char, key)
    local db = WowTrackerDB
    local week = GetServerTime() / 604800
    if not db.lastResetWeek or math.floor(week) > math.floor(db.lastResetWeek) then
        db.lastResetWeek = week
        for _, d in pairs(db.characters or {}) do d.delves={}; d.totalDone=0 end
    end
    local _, class = UnitClass("player")
    local si = GetSpecialization and GetSpecialization()
    local sn = si and select(2, GetSpecializationInfo(si)) or "No spec"
    local _, ilvl = GetAverageItemLevel()
    char.class=class; char.faction=UnitFactionGroup("player"); char.spec=sn
    char.ilvl=math.floor(ilvl or 0); char.level=UnitLevel("player"); char.money=GetMoney()
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities and Enum and Enum.WeeklyRewardChestThresholdType then
        local aOk, acts = pcall(C_WeeklyRewards.GetActivities, Enum.WeeklyRewardChestThresholdType.World)
        if aOk and acts then
            char.delves={}; char.totalDone=0
            for _, a in ipairs(acts) do
                table.insert(char.delves, {p=a.progress, t=a.threshold})
                if a.progress > char.totalDone then char.totalDone=a.progress end
            end
        end
    end
end

WT_CORE:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(1, RunScanners) end)
WT_CORE:On("WEEKLY_REWARDS_UPDATE", RunScanners)
WT_CORE:On("BAG_UPDATE_DELAYED",    RunScanners)
WT_CORE:On("PLAYER_MONEY",          RunScanners)

-- ============================================================================
-- SHELL UI — sidebar + content
-- ============================================================================
local Shell       = nil
local ContentArea = nil
local SidebarBtns = {}
local activeTab   = nil

local CAT_ORDER = {
    { label="━ TRACKING ━", category="Tracking" },
    { label="━ WARBAND ━",  category="Warband"  },
    { label="━ HUD ━",      category="HUD"      },
    { label="━ UTILITY ━",  category="Utility"  },
}

local function ClearContent()
    if not ContentArea then return end
    for _, c in ipairs({ContentArea:GetChildren()}) do c:Hide(); c:SetParent(UIParent) end
    for _, r in ipairs({ContentArea:GetRegions()}) do r:Hide() end
end

local function ShowPluginContent(id)
    ClearContent()
    activeTab = id
    if Shell and Shell.contentTitle then
        local p = WT_CORE.Plugins[id]
        Shell.contentTitle:SetText(p and ((p.icon and p.icon.." " or "")..(p.name or id)) or id)
    end
    local p = WT_CORE.Plugins[id]
    if p and p.buildUI then
        local cf = CreateFrame("Frame", nil, ContentArea)
        cf:SetPoint("TOPLEFT", 0, -34); cf:SetPoint("BOTTOMRIGHT", 0, 0)
        local ok, err = pcall(p.buildUI, cf)
        if not ok then
            local el = cf:CreateFontString(nil,"OVERLAY"); el:SetFont(FONT,11,"OUTLINE")
            el:SetPoint("CENTER"); el:SetText(C_RED.."UI error:\n"..tostring(err)..C_RESET)
        end
    else
        local lbl = ContentArea:CreateFontString(nil,"OVERLAY"); lbl:SetFont(FONT,13,"OUTLINE")
        lbl:SetPoint("CENTER"); lbl:SetText(C_BLUE..(p and p.name or id)..C_RESET.."\n|cff888888Geen UI beschikbaar|r")
    end
    for bid, btn in pairs(SidebarBtns) do
        if bid == id then
            btn:SetBackdropColor(0.18, 0.04, 0.32, 1.0); btn.label:SetTextColor(0.87, 0.55, 1.0)
        else
            btn:SetBackdropColor(0.0, 0.0, 0.0, 0.0); btn.label:SetTextColor(0.75, 0.75, 0.75)
        end
    end
    if WowTrackerDB then
        WowTrackerDB.settings = WowTrackerDB.settings or {}
        WowTrackerDB.settings.activeTab = id
    end
end

local function ShowDashboard()
    ClearContent()
    activeTab = "__dashboard"
    if Shell and Shell.contentTitle then Shell.contentTitle:SetText("⚡ Dashboard") end

    local f = CreateFrame("Frame", nil, ContentArea); f:SetAllPoints()

    local bigLogo = f:CreateTexture(nil, "ARTWORK")
    bigLogo:SetSize(120, 120); bigLogo:SetPoint("TOP", f, "TOP", 0, -25)
    bigLogo:SetTexture(MEDIA.."Icons\\WowTracker_Icon_128.png"); bigLogo:SetAlpha(0.9)

    local greet = f:CreateFontString(nil,"OVERLAY"); greet:SetFont(FONT,16,"OUTLINE")
    greet:SetPoint("TOP", bigLogo,"BOTTOM",0,-10)
    greet:SetText(C_GOLD.."Welkom, "..(UnitName("player") or "Avonturier")..C_RESET)

    local total, active = 0, 0
    for id in pairs(WT_CORE.Plugins) do total=total+1; if WT_CORE:IsPluginEnabled(id) then active=active+1 end end
    local stats = f:CreateFontString(nil,"OVERLAY"); stats:SetFont(FONT,11,"OUTLINE")
    stats:SetPoint("TOP",greet,"BOTTOM",0,-10)
    stats:SetText(string.format("|cff888888Plugins actief:|r %s%d/%d|r   |cff888888Build:|r |cff666666%s|r",C_BLUE,active,total,WT_CORE.Build))

    local disc = f:CreateFontString(nil,"OVERLAY"); disc:SetFont(FONT,10,"OUTLINE")
    disc:SetPoint("BOTTOM",f,"BOTTOM",0,12)
    disc:SetText(C_GOLD.."discord.gg/y8Pu5qsEbQ  ·  slayeralliance.com"..C_RESET)

    -- Quick shortcuts grid
    local shortcuts = {
        {"🎯 Prey Tracker","prey_tracker"},{"📦 Cloth Counter","cloth_counter"},
        {"💰 Registry","registry"},{"🔒 Lockout","lockout"},
    }
    local cols = 2
    for i, s in ipairs(shortcuts) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        btn:SetSize(175, 32)
        btn:SetPoint("TOP", f, "TOP", (col==0 and -92 or 92), -230 - row*40)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
        btn:SetBackdropColor(0.08, 0.03, 0.14, 1.0)
        btn:SetBackdropBorderColor(0.30, 0.0, 0.60, 0.5)
        local lbl = btn:CreateFontString(nil,"OVERLAY"); lbl:SetFont(FONT,11,"OUTLINE"); lbl:SetPoint("CENTER"); lbl:SetText(s[1])
        local lid = s[2]
        btn:SetScript("OnClick", function() if WT_CORE.Plugins[lid] then ShowPluginContent(lid) end end)
        btn:SetScript("OnEnter", function(b) b:SetBackdropColor(0.18,0.06,0.28,1.0) end)
        btn:SetScript("OnLeave", function(b) b:SetBackdropColor(0.08,0.03,0.14,1.0) end)
    end
end

local function BuildShell()
    if Shell then return end

    Shell = CreateFrame("Frame","WowTrackerShell",UIParent,"BackdropTemplate")
    Shell:SetSize(SHELL_W, SHELL_H); Shell:SetPoint("CENTER"); Shell:Hide()
    Shell:SetMovable(true); Shell:EnableMouse(true); Shell:RegisterForDrag("LeftButton")
    Shell:SetClampedToScreen(true); Shell:SetFrameStrata("DIALOG"); Shell:SetToplevel(true)
    Shell:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
    Shell:SetBackdropColor(0.04,0.03,0.08,0.98); Shell:SetBackdropBorderColor(0.45,0.0,0.85,0.8)
    Shell:SetScript("OnDragStart", function(s) if not InCombatLockdown() then s:StartMoving() end end)
    Shell:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        if WowTrackerDB then local p={s:GetPoint()}; WowTrackerDB.settings=WowTrackerDB.settings or {}; WowTrackerDB.settings.shellPos=p end
    end)

    -- Header bg
    local hbg = Shell:CreateTexture(nil,"BACKGROUND",nil,1)
    hbg:SetHeight(HEADER_H); hbg:SetPoint("TOPLEFT",1,-1); hbg:SetPoint("TOPRIGHT",-1,-1)
    hbg:SetColorTexture(0.07,0.03,0.14,1.0)
    local hbrd = Shell:CreateTexture(nil,"BORDER")
    hbrd:SetHeight(1); hbrd:SetPoint("BOTTOMLEFT",hbg); hbrd:SetPoint("BOTTOMRIGHT",hbg)
    hbrd:SetColorTexture(0.55,0.0,1.0,0.7)

    -- Logo + title
    Shell.logo = Shell:CreateTexture(nil,"ARTWORK"); Shell.logo:SetSize(40,40); Shell.logo:SetPoint("TOPLEFT",10,-9)
    Shell.logo:SetTexture(MEDIA.."Icons\\WowTracker_Icon_64.png")
    Shell.title = Shell:CreateFontString(nil,"OVERLAY"); Shell.title:SetFont(FONT,20,"OUTLINE")
    Shell.title:SetPoint("LEFT",Shell.logo,"RIGHT",10,2)
    Shell.title:SetText(C_PURPLE.."Wow"..C_BLUE.."Tracker"..C_RESET.."  "..C_GOLD.."Slayer Alliance Edition"..C_RESET)
    Shell.ver = Shell:CreateFontString(nil,"OVERLAY"); Shell.ver:SetFont(FONT,10,"OUTLINE")
    Shell.ver:SetPoint("BOTTOMLEFT",Shell.logo,"BOTTOMRIGHT",10,0)
    Shell.ver:SetText("|cff555566v"..WT_CORE.Version.." · Midnight 12.0.5|r")

    -- Content title (below header, inside content area)
    Shell.contentTitle = Shell:CreateFontString(nil,"OVERLAY"); Shell.contentTitle:SetFont(FONT,13,"OUTLINE")
    Shell.contentTitle:SetText(""); Shell.contentTitle:SetPoint("TOPLEFT",SIDEBAR_W+14,-HEADER_H-10)

    -- Close button
    Shell.closeBtn = CreateFrame("Button",nil,Shell,"UIPanelCloseButton"); Shell.closeBtn:SetPoint("TOPRIGHT",2,2)

    -- Sidebar
    local sb = CreateFrame("Frame","WowTrackerSidebar",Shell,"BackdropTemplate")
    sb:SetWidth(SIDEBAR_W); sb:SetPoint("TOPLEFT",0,-HEADER_H); sb:SetPoint("BOTTOMLEFT",0,FOOTER_H)
    sb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); sb:SetBackdropColor(0.06,0.03,0.11,1.0)
    local sbbrd = sb:CreateTexture(nil,"BORDER"); sbbrd:SetWidth(1)
    sbbrd:SetPoint("TOPRIGHT",sb); sbbrd:SetPoint("BOTTOMRIGHT",sb); sbbrd:SetColorTexture(0.35,0.0,0.65,0.5)
    Shell.sidebar = sb

    -- Content area
    ContentArea = CreateFrame("Frame","WowTrackerContent",Shell)
    ContentArea:SetPoint("TOPLEFT",sb,"TOPRIGHT",0,0); ContentArea:SetPoint("BOTTOMRIGHT",Shell,-1,FOOTER_H)
    Shell.contentArea = ContentArea

    -- Footer
    local fbg = Shell:CreateTexture(nil,"BACKGROUND",nil,1)
    fbg:SetHeight(FOOTER_H); fbg:SetPoint("BOTTOMLEFT",1,1); fbg:SetPoint("BOTTOMRIGHT",-1,1)
    fbg:SetColorTexture(0.04,0.02,0.08,1.0)
    local fbrd = Shell:CreateTexture(nil,"BORDER"); fbrd:SetHeight(1)
    fbrd:SetPoint("TOPLEFT",fbg); fbrd:SetPoint("TOPRIGHT",fbg); fbrd:SetColorTexture(0.35,0.0,0.65,0.4)
    Shell.footerMem = Shell:CreateFontString(nil,"OVERLAY"); Shell.footerMem:SetFont(FONT,10,"OUTLINE")
    Shell.footerMem:SetPoint("BOTTOMLEFT",14,7); Shell.footerMem:SetText("|cff444455WowTracker geladen|r")

    -- Memory ticker
    C_Timer.NewTicker(2.0, function()
        if not Shell or not Shell:IsShown() then return end
        local ok, mem = pcall(C_AddOns.GetAddOnMemoryUsage, ADDON_NAME)
        if ok and mem then Shell.footerMem:SetText(string.format("|cff446655Geheugen: %.1f KB|r",mem)) end
    end)

    WT_CORE.Shell = Shell
end

function WT_CORE:RefreshShellSidebar()
    if not Shell then return end
    for _, btn in pairs(SidebarBtns) do btn:Hide() end
    SidebarBtns = {}
    for _, child in ipairs({Shell.sidebar:GetChildren()}) do child:Hide() end
    for _, region in ipairs({Shell.sidebar:GetRegions()}) do region:Hide() end

    local y = -8

    -- Dashboard button
    local db_btn = CreateFrame("Button",nil,Shell.sidebar,"BackdropTemplate")
    db_btn:SetSize(SIDEBAR_W-4,30); db_btn:SetPoint("TOPLEFT",Shell.sidebar,2,y)
    db_btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); db_btn:SetBackdropColor(0,0,0,0)
    db_btn.label = db_btn:CreateFontString(nil,"OVERLAY"); db_btn.label:SetFont(FONT,11,"OUTLINE")
    db_btn.label:SetPoint("LEFT",10,0); db_btn.label:SetText("⚡ Dashboard"); db_btn.label:SetTextColor(0.75,0.75,0.75)
    db_btn:SetScript("OnClick", ShowDashboard)
    db_btn:SetScript("OnEnter",function(s) s:SetBackdropColor(0.12,0.03,0.22,1.0) end)
    db_btn:SetScript("OnLeave",function(s) s:SetBackdropColor(0,0,0,0) end)
    SidebarBtns["__dashboard"] = db_btn
    y = y - 34

    -- Group by category
    local bycat = {}
    for id, p in pairs(self.Plugins) do
        local c = p.category or "Utility"; bycat[c]=bycat[c] or {}; table.insert(bycat[c],{id=id,p=p})
    end
    for _, g in pairs(bycat) do table.sort(g,function(a,b) return (a.p.name or a.id) < (b.p.name or b.id) end) end

    for _, catInfo in ipairs(CAT_ORDER) do
        local items = bycat[catInfo.category]
        if items and #items > 0 then
            local div = Shell.sidebar:CreateFontString(nil,"OVERLAY"); div:SetFont(FONT,8,"OUTLINE")
            div:SetPoint("TOPLEFT",Shell.sidebar,8,y); div:SetText("|cff443355"..catInfo.label.."|r"); y=y-16
            for _, item in ipairs(items) do
                local id, p = item.id, item.p
                local en = self:IsPluginEnabled(id)
                local btn = CreateFrame("Button",nil,Shell.sidebar,"BackdropTemplate")
                btn:SetSize(SIDEBAR_W-4,26); btn:SetPoint("TOPLEFT",Shell.sidebar,2,y)
                btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); btn:SetBackdropColor(0,0,0,0)
                btn.label = btn:CreateFontString(nil,"OVERLAY"); btn.label:SetFont(FONT,11,"OUTLINE")
                btn.label:SetPoint("LEFT",10,0); btn.label:SetText((p.icon and p.icon.." " or "")..(p.name or id))
                btn.label:SetTextColor(en and 0.80 or 0.38, 0.80, en and 0.80 or 0.38)
                btn.dot = btn:CreateFontString(nil,"OVERLAY"); btn.dot:SetFont(FONT,8,"OUTLINE")
                btn.dot:SetPoint("RIGHT",-5,0); btn.dot:SetText(en and "|cff44cc44●|r" or "|cff552222●|r")
                local cid = id
                btn:SetScript("OnClick",function() if WT_CORE:IsPluginEnabled(cid) then ShowPluginContent(cid) end end)
                btn:SetScript("OnEnter",function(s)
                    s:SetBackdropColor(0.12,0.03,0.22,1.0)
                    GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(p.name or cid)
                    GameTooltip:AddLine(en and "|cff44cc44Actief|r" or "|cffcc4444Uitgeschakeld|r"); GameTooltip:Show()
                end)
                btn:SetScript("OnLeave",function(s) s:SetBackdropColor(0,0,0,0); GameTooltip:Hide() end)
                SidebarBtns[id] = btn; y=y-28
            end
            y=y-4
        end
    end

    -- Settings button pinned to bottom
    local sbtn = CreateFrame("Button",nil,Shell.sidebar,"BackdropTemplate")
    sbtn:SetSize(SIDEBAR_W-4,26); sbtn:SetPoint("BOTTOMLEFT",Shell.sidebar,2,4)
    sbtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    sbtn:SetBackdropColor(0.07,0.02,0.12,1.0); sbtn:SetBackdropBorderColor(0.25,0.0,0.50,0.5)
    local slbl = sbtn:CreateFontString(nil,"OVERLAY"); slbl:SetFont(FONT,11,"OUTLINE"); slbl:SetPoint("CENTER")
    slbl:SetText("⚙ Instellingen"); slbl:SetTextColor(0.55,0.55,0.55)
    sbtn:SetScript("OnClick",function() if WT_CORE.SettingsPanel then Settings.OpenToCategory(WT_CORE.SettingsPanel:GetID()) end end)
end

function WT_CORE:ShowShell(pluginID)
    if not Shell then BuildShell() end
    Shell:Show(); self:RefreshShellSidebar()
    if pluginID and self.Plugins[pluginID] then ShowPluginContent(pluginID)
    else
        local saved = WowTrackerDB and WowTrackerDB.settings and WowTrackerDB.settings.activeTab
        if saved and self.Plugins[saved] then ShowPluginContent(saved) else ShowDashboard() end
    end
end
function WT_CORE:HideShell() if Shell then Shell:Hide() end end
function WT_CORE:ToggleShell() if Shell and Shell:IsShown() then self:HideShell() else self:ShowShell() end end

-- ============================================================================
-- SETTINGS PANEL (Blizzard Settings integration)
-- ============================================================================
local function BuildSettingsPanel()
    local opt = CreateFrame("Frame","WowTrackerOptions"); opt.name = "WowTracker"
    opt.img = opt:CreateTexture(nil,"ARTWORK"); opt.img:SetSize(80,80); opt.img:SetPoint("TOPLEFT",15,-15)
    opt.img:SetTexture(MEDIA.."Icons\\WowTracker_Icon_128.png")
    opt.ttl = opt:CreateFontString(nil,"OVERLAY"); opt.ttl:SetFont(FONT,16,"OUTLINE")
    opt.ttl:SetPoint("TOPLEFT",108,-18)
    opt.ttl:SetText(C_PURPLE.."WowTracker"..C_RESET.."  "..C_GOLD.."Slayer Alliance"..C_RESET)
    opt.sub = opt:CreateFontString(nil,"OVERLAY"); opt.sub:SetFont(FONT,10,"OUTLINE")
    opt.sub:SetPoint("TOPLEFT",108,-42); opt.sub:SetText("|cff555566v"..WT_CORE.Version.."  ·  Interface 120005  ·  Midnight 12.0.5|r")
    opt.ph = opt:CreateFontString(nil,"OVERLAY"); opt.ph:SetFont(FONT,12,"OUTLINE")
    opt.ph:SetPoint("TOPLEFT",15,-118); opt.ph:SetText(C_GOLD.."Plugin Beheer"..C_RESET.."  |cff555566(toggle aan/uit)|r")

    local scroll = CreateFrame("ScrollFrame","WT_CfgScroll",opt,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",15,-140); scroll:SetPoint("BOTTOMRIGHT",-30,20)
    local content = CreateFrame("Frame",nil,scroll); content:SetSize(480,1); scroll:SetScrollChild(content)
    local rows = {}

    opt:SetScript("OnShow", function()
        WowTrackerDB = WowTrackerDB or {}; WowTrackerDB.PluginStates = WowTrackerDB.PluginStates or {}
        local ids = {}; for id in pairs(WT_CORE.Plugins) do table.insert(ids,id) end; table.sort(ids)
        for i, id in ipairs(ids) do
            local p = WT_CORE.Plugins[id]
            local r = rows[i]
            if not r then
                r = CreateFrame("Frame",nil,content,"BackdropTemplate"); r:SetSize(470,30)
                r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
                r.nm = r:CreateFontString(nil,"OVERLAY"); r.nm:SetFont(FONT,11,"OUTLINE"); r.nm:SetPoint("LEFT",8,0)
                r.vr = r:CreateFontString(nil,"OVERLAY"); r.vr:SetFont(FONT,9,"OUTLINE"); r.vr:SetPoint("LEFT",210,0)
                r.ct = r:CreateFontString(nil,"OVERLAY"); r.ct:SetFont(FONT,9,"OUTLINE"); r.ct:SetPoint("RIGHT",-68,0)
                r.tb = CreateFrame("Button",nil,r,"BackdropTemplate"); r.tb:SetSize(52,20); r.tb:SetPoint("RIGHT",-4,0)
                r.tb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
                r.tb.lbl = r.tb:CreateFontString(nil,"OVERLAY"); r.tb.lbl:SetFont(FONT,10,"OUTLINE"); r.tb.lbl:SetPoint("CENTER")
                rows[i] = r
            end
            r:SetPoint("TOPLEFT",0,(i-1)*-34); r:Show()
            local en = WT_CORE:IsPluginEnabled(id)
            r:SetBackdropColor(0.06,0.02,0.10,en and 1 or 0.4); r:SetBackdropBorderColor(en and 0.30 or 0.12,0,en and 0.55 or 0.22,0.5)
            r.nm:SetText((p.icon and p.icon.." " or "")..(p.name or id)); r.nm:SetTextColor(en and 0.88 or 0.45, 0.88, en and 0.88 or 0.45)
            r.vr:SetText("|cff444466v"..(p.version or "?").."|r"); r.ct:SetText("|cff553377"..(p.category or "").."  |r")
            local function RefRow()
                local e = WT_CORE:IsPluginEnabled(id)
                r.tb:SetBackdropColor(e and 0 or 0.45, e and 0.45 or 0, 0, 1)
                r.tb.lbl:SetText(e and "|cff44ff44ON|r" or "|cffff4444OFF|r")
            end
            r.tb:SetScript("OnClick",function()
                if WT_CORE:IsPluginEnabled(id) then WT_CORE:DisablePlugin(id) else WT_CORE:EnablePlugin(id) end
                RefRow()
            end)
            RefRow()
        end
        content:SetHeight(#ids * 34 + 10)
    end)

    local cat = Settings.RegisterCanvasLayoutCategory(opt, opt.name)
    Settings.RegisterAddOnCategory(cat)
    WT_CORE.SettingsPanel = cat
end

-- ============================================================================
-- MINIMAP BUTTON
-- ============================================================================
local MBtn = CreateFrame("Button","WowTrackerMBtn",UIParent)
MBtn:SetSize(52,52); MBtn:SetPoint("CENTER"); MBtn:SetMovable(true); MBtn:EnableMouse(true)
MBtn:RegisterForDrag("RightButton"); MBtn:SetClampedToScreen(true); MBtn:SetFrameStrata("MEDIUM")
MBtn.tex = MBtn:CreateTexture(nil,"ARTWORK"); MBtn.tex:SetAllPoints()
MBtn.tex:SetTexture(MEDIA.."Icons\\WowTracker_Icon_64.png")
MBtn.ring = MBtn:CreateTexture(nil,"OVERLAY"); MBtn.ring:SetAllPoints()
MBtn.ring:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn"); MBtn.ring:SetVertexColor(0.55,0.0,1.0,0.55)
MBtn:SetScript("OnDragStart", MBtn.StartMoving)
MBtn:SetScript("OnDragStop",function(s)
    s:StopMovingOrSizing()
    if WowTrackerDB then local p={s:GetPoint()}; WowTrackerDB.settings=WowTrackerDB.settings or {}; WowTrackerDB.settings.mbtnPos=p end
end)
MBtn:SetScript("OnClick",function(self,btn)
    if btn=="LeftButton" then PlaySound(6449); WT_CORE:ToggleShell()
    elseif btn=="RightButton" then
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(self,function(_,root)
                root:CreateTitle(C_PURPLE.."WowTracker v"..WT_CORE.Version)
                root:CreateButton("Open WowTracker",function() WT_CORE:ShowShell() end)
                root:CreateButton("Instellingen",function() if WT_CORE.SettingsPanel then Settings.OpenToCategory(WT_CORE.SettingsPanel:GetID()) end end)
                root:CreateDivider()
                root:CreateButton("Reset positie",function() MBtn:ClearAllPoints(); MBtn:SetPoint("CENTER") end)
                root:CreateButton("Sluit",function() WT_CORE:HideShell() end)
            end)
        end
    end
end)
MBtn:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(C_PURPLE.."WowTracker"..C_RESET)
    GameTooltip:AddLine("|cff888888Slayer Alliance Edition|r")
    GameTooltip:AddLine(C_BLUE.."Links:|r open/sluit   "..C_BLUE.."Rechts:|r menu"); GameTooltip:Show()
end)
MBtn:SetScript("OnLeave",function() GameTooltip:Hide() end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================
SLASH_WOWTRACKER1="/wt"; SLASH_WOWTRACKER2="/wowtracker"
SlashCmdList["WOWTRACKER"]=function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""
    if msg=="" then WT_CORE:ToggleShell()
    elseif msg=="dev" then WT_CORE.DevMode=not WT_CORE.DevMode; print("[WowTracker] DevMode: "..(WT_CORE.DevMode and "|cff44ff44ON|r" or "|cffff4444OFF|r"))
    elseif msg=="scan" then RunScanners(); print("[WowTracker] Scan uitgevoerd.")
    elseif msg=="mem" then local ok,mem=pcall(C_AddOns.GetAddOnMemoryUsage,ADDON_NAME); if ok then print(string.format("[WowTracker] Geheugen: %.1f KB",mem)) end
    elseif msg=="reload" then ReloadUI()
    elseif msg:sub(1,4)=="test" then
        local pid=msg:sub(6); local p=WT_CORE.Plugins[pid]
        if p and p.test then pcall(p.test) elseif pid~="" then print("[WowTracker] Geen test voor: "..pid) end
    else
        if WT_CORE.Plugins[msg] then WT_CORE:ShowShell(msg)
        else
            print(C_GOLD.."WowTracker v"..WT_CORE.Version..C_RESET); print("/wt · /wt <id> · /wt scan · /wt mem · /wt test <id> · /wt dev · /wt reload")
        end
    end
end
SLASH_DELVETRACKER1="/dt"
SlashCmdList["DELVETRACKER"]=function(msg) SlashCmdList["WOWTRACKER"](msg or "") end

-- ============================================================================
-- INIT
-- ============================================================================
WT_CORE:On("ADDON_LOADED",function(event,name)
    if name~=ADDON_NAME then return end
    local db=InitDB(); RunMigrations(db)
    if db.settings and db.settings.mbtnPos then
        local p=db.settings.mbtnPos
        if type(p)=="table" and p[1] then
            pcall(function() MBtn:ClearAllPoints(); MBtn:SetPoint(p[1],UIParent,p[2] or "CENTER",p[3] or 0,p[4] or 0) end)
        end
    end
    BuildSettingsPanel()
    print(C_PURPLE.."Wow"..C_BLUE.."Tracker"..C_RESET.." v"..WT_CORE.Version.."  |cff555566Slayer Alliance · Midnight 12.0.5|r  —  |cff666666/wt|r")
end)
WT_CORE:On("PLAYER_LOGIN",function() C_Timer.After(2,RunScanners) end)

-- ============================================================================
-- EOF — WowTracker Core v1.0.0
-- DieOuwe · www.dieouwe.nl · discord.gg/y8Pu5qsEbQ
-- ============================================================================
