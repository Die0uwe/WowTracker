-- =====================================================
-- DelveTracker - Version DT v16.9 (ULTIMATE MASTER CORE)
-- =====================================================

DelveTrackerDB = DelveTrackerDB or {}
DelveTrackerDB.characters = DelveTrackerDB.characters or {}
DelveTrackerDB.PluginStates = DelveTrackerDB.PluginStates or {}
DelveTracker = { Plugins = {}, Version = "2.6.1-12.0.5.67314" }

local SA_GOLD, SA_PURPLE, SA_BLUE = "|cffccaa00", "|cffa335ee", "|cff00ccff"

-- PLUGIN API
function DelveTracker:RegisterPlugin(name, func)
    self.Plugins[name] = func
end

-- UI MAIN WINDOW
local UI = CreateFrame("Frame", "DelveTrackerFrame", UIParent, "BackdropTemplate")
UI:SetSize(420, 550); UI:SetPoint("CENTER"); UI:Hide()
UI:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
UI:SetBackdropColor(0, 0, 0, 0.95); UI:SetBackdropBorderColor(0, 0, 0, 1)
UI:SetMovable(true); UI:EnableMouse(true); UI:RegisterForDrag("LeftButton")
UI:SetScript("OnDragStart", UI.StartMoving); UI:SetScript("OnDragStop", UI.StopMovingOrSizing)

-- TABS DEFINITION
local Tab1 = CreateFrame("Frame", "DT_Tab1", UI); Tab1:SetAllPoints(); Tab1:Show()
local Tab2 = CreateFrame("Frame", "DT_Tab2", UI); Tab2:SetAllPoints(); Tab2:Hide()
local Tab3 = CreateFrame("Frame", "DT_Tab3", UI); Tab3:SetAllPoints(); Tab3:Hide()

-- DATA LOGIC
local function CheckWeeklyReset()
    local currentWeek = GetServerTime() / (60 * 60 * 24 * 7)
    if not DelveTrackerDB.lastResetWeek or math.floor(currentWeek) > math.floor(DelveTrackerDB.lastResetWeek) then
        DelveTrackerDB.lastResetWeek = currentWeek
        if DelveTrackerDB.characters then
            for _, d in pairs(DelveTrackerDB.characters) do d.delves = {}; d.totalDone = 0 end
        end
    end
end

local function ScanDelves()
    CheckWeeklyReset()
    local name, realm = UnitName("player"), GetNormalizedRealmName()
    if not name or not realm then return end
    local key = name .. "-" .. realm
    DelveTrackerDB.characters = DelveTrackerDB.characters or {}
    DelveTrackerDB.characters[key] = DelveTrackerDB.characters[key] or {}
    local d = DelveTrackerDB.characters[key]
    local _, class = UnitClass("player"); local faction = UnitFactionGroup("player") 
    local specIndex = GetSpecialization and GetSpecialization()
    local specName = specIndex and select(2, GetSpecializationInfo(specIndex)) or "No spec"
    local _, ilvl = GetAverageItemLevel()
    d.class, d.faction, d.spec, d.ilvl, d.level = class, faction, specName, math.floor(ilvl or 0), UnitLevel("player")
    local acts
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities and Enum and Enum.WeeklyRewardChestThresholdType then
        local ok, result = pcall(C_WeeklyRewards.GetActivities, Enum.WeeklyRewardChestThresholdType.World)
        if ok then acts = result end
    end
    if acts then
        d.delves = {}; d.totalDone = 0
        for _, act in ipairs(acts) do table.insert(d.delves, {p = act.progress, t = act.threshold}); if act.progress > d.totalDone then d.totalDone = act.progress end end
    end
end

-- REFRESH FUNCTION FOR TAB 2 (FIXED)
local function UpdateCharacterList()
    ScanDelves()
    local myKey = (UnitName("player") or "Unknown") .. "-" .. (GetNormalizedRealmName() or "Unknown")
    local d = DelveTrackerDB.characters and DelveTrackerDB.characters[myKey]
    if not (DT_Scroll and DT_Scroll.content) then return end
    if d then 
        local c = RAID_CLASS_COLORS[d.class] or {r=1, g=1, b=1}
        UI.charInfo:SetText(string.format("|cff%02x%02x%02x%s|r (|cffffffffLvl %s|r)\n%s %s - |cff00ff00iLvl %d|r", math.floor(c.r*255 + 0.5), math.floor(c.g*255 + 0.5), math.floor(c.b*255 + 0.5), UnitName("player"), d.level or "??", d.spec or "??", d.class or "", d.ilvl or 0)) 
    end
    
    local filter = (DT_SearchBox and DT_SearchBox:GetText() or ""):lower()
    local sorted = {}
    for k in pairs(DelveTrackerDB.characters or {}) do if filter == "" or k:lower():find(filter, 1, true) then table.insert(sorted, k) end end
    table.sort(sorted)
    
    -- Clear or hide existing rows
    if not DT_Scroll.content.rows then DT_Scroll.content.rows = {} end
    for _, row in pairs(DT_Scroll.content.rows) do row:Hide() end
    
    for i, key in ipairs(sorted) do
        local data = DelveTrackerDB.characters[key]
        local r = DT_Scroll.content.rows[i] or CreateFrame("Button", nil, DT_Scroll.content, "BackdropTemplate")
        r:SetSize(360, 70); r:SetPoint("TOPLEFT", 0, (i-1) * -75); r:Show()
        r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); r:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        r.fLet = r.fLet or r:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); r.fLet:SetPoint("LEFT", 10, 0); r.fLet:SetScale(1.4); r.fLet:SetText((data.faction == "Horde") and "|cffff0000H|r" or "|cff0070ffA|r")
        r.cIcon = r.cIcon or r:CreateTexture(nil, "OVERLAY"); r.cIcon:SetSize(32, 32); r.cIcon:SetPoint("LEFT", r.fLet, "RIGHT", 15, 0)
        if data.class then r.cIcon:SetTexture("Interface\\Icons\\ClassIcon_"..data.class) end
        
        r.txt = r.txt or r:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); r.txt:SetPoint("LEFT", r.cIcon, "RIGHT", 15, 0); r.txt:SetJustifyH("LEFT")
        local status = ""
        if data.delves then for _, v in ipairs(data.delves) do status = status .. string.format("[%s%d/%d|r] ", (v.p >= v.t and "|cff00ff00" or "|cffff4444"), v.p, v.t) end end
        r.txt:SetText(SA_GOLD..(key:match("([^-]+)") or key).."\n".."|cffffffff"..status)
        
        r:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.2, 0.2, 0.8); GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(SA_GOLD..(key:match("([^-]+)") or key))
            for pN, pF in pairs(DelveTracker.Plugins) do if DelveTrackerDB.PluginStates[pN] ~= false then pcall(pF, "Tooltip", data, key) end end
            GameTooltip:Show() end)
        r:SetScript("OnLeave", function(self) self:SetBackdropColor(0.1, 0.1, 0.1, 0.6); GameTooltip:Hide() end)
        r:SetScript("OnClick", function(self) if DT_Armory_ShowCharacter then data.name = key:match("([^-]+)") or key; DT_Armory_ShowCharacter(data); PlaySound(852) end end)
        DT_Scroll.content.rows[i] = r
    end
    DT_Scroll.content:SetHeight(#sorted * 75)
end

-- TAB SWITCHER
local function ShowTab(id)
    UI:Show()
    Tab1:Hide(); Tab2:Hide(); Tab3:Hide()
    if id == 1 then 
        Tab1:Show()
        if IsInGuild() then
            local gName = GetGuildInfo("player"); local motd = GetGuildRosterMOTD()
            Tab1.t:SetText(SA_GOLD..(gName or "Slayer Alliance").."\n\n"..SA_PURPLE.."MOTD:\n|cffffffff"..(motd ~= "" and motd or "No MOTD set."))
        end
    elseif id == 2 then 
        Tab2:Show()
        UpdateCharacterList()
    elseif id == 3 then 
        Tab3:Show()
        -- Refresh Tab 3 Plugins
        for pN, pF in pairs(DelveTracker.Plugins) do 
            if DelveTrackerDB.PluginStates and DelveTrackerDB.PluginStates[pN] ~= false then 
                pcall(pF, "Tab3", Tab3.PluginArea) 
            end 
        end
    end
end

-- ==========================================
-- SLASH COMMANDS
-- ==========================================
SLASH_DTAB11 = "/dt1"; SLASH_DTAB12 = "/tb1"
SlashCmdList["DTAB1"] = function() ShowTab(1) end
SLASH_DTAB21 = "/dt2"; SLASH_DTAB22 = "/tb2"
SlashCmdList["DTAB2"] = function() ShowTab(2) end
SLASH_DTAB31 = "/dt3"; SLASH_DTAB32 = "/tb3"
SlashCmdList["DTAB3"] = function() ShowTab(3) end
SLASH_DTMAIN1 = "/dt"; SLASH_DTMAIN2 = "/delves"
SlashCmdList["DTMAIN"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "1" or msg == "guild" then ShowTab(1)
    elseif msg == "2" or msg == "delves" then ShowTab(2)
    elseif msg == "3" or msg == "bounty" or msg == "plugins" then ShowTab(3)
    elseif msg == "afk" and DT_CustomAFK_Frame then DT_CustomAFK_Frame:Show()
    elseif UI:IsShown() then UI:Hide() else ShowTab(2) end
end
SLASH_DTRELOAD1 = "/dtreload"
SlashCmdList["DTRELOAD"] = function() ReloadUI() end
SLASH_DTMEM1 = "/dtmem"
SlashCmdList["DTMEM"] = function()
    if C_AddOns and C_AddOns.UpdateAddOnMemoryUsage then C_AddOns.UpdateAddOnMemoryUsage()
    elseif UpdateAddOnMemoryUsage then UpdateAddOnMemoryUsage() end
    local mem = (C_AddOns and C_AddOns.GetAddOnMemoryUsage and C_AddOns.GetAddOnMemoryUsage("DelveTracker"))
             or (GetAddOnMemoryUsage and GetAddOnMemoryUsage("DelveTracker")) or 0
    print(string.format("|cff00ff00DelveTracker|r memory: %.1f KB", mem or 0))
end
SLASH_DTCOMBAT1 = "/dtcombat"
SlashCmdList["DTCOMBAT"] = function()
    DelveTrackerDB.enableCombatAlert = not DelveTrackerDB.enableCombatAlert
    print("|cff00ff00DelveTracker|r combat alert: " .. (DelveTrackerDB.enableCombatAlert and "ON" or "OFF"))
end

-- UI HEADER & LOGO
UI.header = UI:CreateTexture(nil, "OVERLAY")
UI.header:SetHeight(90); UI.header:SetPoint("TOPLEFT", 1, -1); UI.header:SetPoint("TOPRIGHT", -1, -1); UI.header:SetColorTexture(0.12, 0.12, 0.12, 1)
UI.logo = UI:CreateTexture(nil, "OVERLAY"); UI.logo:SetSize(32, 32); UI.logo:SetPoint("TOPLEFT", 12, -10); UI.logo:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")
UI.title = UI:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); UI.title:SetPoint("LEFT", UI.logo, "RIGHT", 10, 0); UI.title:SetText(SA_PURPLE.."SLAYER ALLIANCE")
UI.charInfo = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium"); UI.charInfo:SetPoint("TOPLEFT", UI.logo, "BOTTOMLEFT", 0, -8); UI.charInfo:SetPoint("RIGHT", UI, -15, 0); UI.charInfo:SetJustifyH("LEFT")
UI.close = CreateFrame("Button", nil, UI, "UIPanelCloseButton"); UI.close:SetPoint("TOPRIGHT", 2, 2)
UI.settingsBtn = CreateFrame("Button", nil, UI); UI.settingsBtn:SetSize(20, 20); UI.settingsBtn:SetPoint("RIGHT", UI.close, "LEFT", -2, 0); UI.settingsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")

-- DISCORD
UI.dcLabel = UI:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); UI.dcLabel:SetPoint("BOTTOM", UI, 0, 85); UI.dcLabel:SetText(SA_GOLD.."CTRL+C to copy Discord link:")
local dBox = CreateFrame("EditBox", nil, UI, "BackdropTemplate"); dBox:SetSize(300, 25); dBox:SetPoint("TOP", UI.dcLabel, "BOTTOM", 0, -5)
dBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1}); dBox:SetBackdropColor(0,0,0,1); dBox:SetBackdropBorderColor(0.3,0.3,0.3,1); dBox:SetJustifyH("CENTER")
dBox:SetFontObject("ChatFontNormal"); dBox:SetText("https://slayeralliance.com/discord"); dBox:SetAutoFocus(false); dBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

-- TAB 1 (GUILD)
Tab1.t = Tab1:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); Tab1.t:SetPoint("TOP", 0, -110); Tab1.t:SetWidth(380)
Tab1.img = Tab1:CreateTexture(nil, "ARTWORK"); Tab1.img:SetSize(180, 180); Tab1.img:SetPoint("TOP", Tab1.t, "BOTTOM", 0, -25); Tab1.img:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\kelsey.tga")

-- TAB 2 (LIST) - FIXED: DT_Scroll.content is now correctly accessible
local searchBox = CreateFrame("EditBox", "DT_SearchBox", Tab2, "SearchBoxTemplate"); searchBox:SetSize(360, 25); searchBox:SetPoint("TOPLEFT", 30, -95); searchBox:SetAutoFocus(false)
local scroll = CreateFrame("ScrollFrame", "DT_Scroll", Tab2, "UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT", 10, -125); scroll:SetPoint("BOTTOMRIGHT", -30, 115)
scroll.content = CreateFrame("Frame", nil, scroll); scroll.content:SetSize(360, 1); scroll:SetScrollChild(scroll.content); scroll.content.rows = {}
searchBox:SetScript("OnTextChanged", function(self) SearchBoxTemplate_OnTextChanged(self); UpdateCharacterList() end)

-- TAB 3 (PLUGIN CONTAINER)
Tab3.PluginArea = CreateFrame("Frame", nil, Tab3); Tab3.PluginArea:SetPoint("TOPLEFT", 10, -100); Tab3.PluginArea:SetPoint("BOTTOMRIGHT", -10, 115)

-- ADMIN PANEL (DIEOUWE)
local opt = CreateFrame("Frame", "DelveTrackerOptions"); opt.name = "DelveTracker"; local category = Settings.RegisterCanvasLayoutCategory(opt, opt.name); Settings.RegisterAddOnCategory(category)
UI.settingsBtn:SetScript("OnClick", function() Settings.OpenToCategory(category:GetID()) end)
opt.img = opt:CreateTexture(nil, "ARTWORK"); opt.img:SetSize(120, 200); opt.img:SetPoint("TOPLEFT", 15, -40); opt.img:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\Dieouwe.tga")
opt.saTitle = opt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); opt.saTitle:SetPoint("TOPLEFT", 150, -20); opt.saTitle:SetText(SA_PURPLE.."DIEOUWE - CONFIG")

local function AddSlider(label, minV, maxV, step, y, dbKey, func)
    -- OptionsSliderTemplate deprecated 10.0 / fragile in 12.0.5 → manual build
    local s = CreateFrame("Slider", "DT_Slider_"..dbKey, opt)
    s:SetPoint("TOPLEFT", 150, y); s:SetSize(180, 16)
    s:SetOrientation("HORIZONTAL"); s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step); s:SetObeyStepOnDrag(true)
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local bg = s:CreateTexture(nil,"BACKGROUND"); bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background"); bg:SetAllPoints()
    local lbl = s:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); lbl:SetPoint("BOTTOM",s,"TOP",0,2); lbl:SetText(label)
    local val = s:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); val:SetPoint("TOP",s,"BOTTOM",0,-2)
    local init = DelveTrackerDB[dbKey] or 1; s:SetValue(init); val:SetText(tostring(init))
    s:SetScript("OnValueChanged", function(self, v) v=math.floor(v*10)/10; func(v); DelveTrackerDB[dbKey]=v; val:SetText(tostring(v)) end)
end
AddSlider("UI Scale", 0.5, 2.0, 0.1, -80, "scale", function(v) UI:SetScale(v) end)
AddSlider("Murloc Scale", 0.5, 2.0, 0.1, -130, "mScale", function(v) if _G["DT_MurlocBtn"] then _G["DT_MurlocBtn"]:SetScale(v) end end)

opt.pScroll = CreateFrame("ScrollFrame", "DT_PluginScroll", opt, "UIPanelScrollFrameTemplate"); opt.pScroll:SetSize(300, 150); opt.pScroll:SetPoint("TOPLEFT", 150, -200)
local pContent = CreateFrame("Frame", nil, opt.pScroll); pContent:SetSize(280, 1); opt.pScroll:SetScrollChild(pContent); pContent.rows = {}

local function UpdatePluginList()
    DelveTrackerDB.PluginStates = DelveTrackerDB.PluginStates or {}
    local names = {}; for name in pairs(DelveTracker.Plugins) do table.insert(names, name) end; table.sort(names)
    for i, name in ipairs(names) do
        local r = pContent.rows[i] or CreateFrame("Frame", nil, pContent, "BackdropTemplate")
        r:SetSize(270, 30); r:SetPoint("TOPLEFT", 0, (i-1) * -35); r:Show(); r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); r:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        r.t = r.t or r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.t:SetPoint("LEFT", 5, 0); r.t:SetText(name)
        r.btn = r.btn or CreateFrame("Button", nil, r, "BackdropTemplate"); r.btn:SetSize(45, 18); r.btn:SetPoint("RIGHT", -5, 0); r.btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
        r.btn.t = r.btn.t or r.btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.btn.t:SetPoint("CENTER")
        local function Refresh() local en = DelveTrackerDB.PluginStates[name] ~= false; r.btn:SetBackdropColor(en and 0 or 0.7, en and 0.7 or 0, 0, 1); r.btn.t:SetText(en and "ON" or "OFF") end
        r.btn:SetScript("OnClick", function() DelveTrackerDB.PluginStates[name] = not (DelveTrackerDB.PluginStates[name] ~= false); Refresh() end)
        Refresh(); pContent.rows[i] = r
    end
end
opt:SetScript("OnShow", UpdatePluginList)

-- TAB BUTTONS
local function CreateTabBtn(txt, x, id)
    local b = CreateFrame("Button", nil, UI, "BackdropTemplate"); b:SetSize(125, 30); b:SetPoint("BOTTOMLEFT", x, 15); b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    b:SetBackdropColor(0.1, 0.1, 0.1, 1); b:SetBackdropBorderColor(0.3, 0.3, 0.3, 1); b.t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.t:SetPoint("CENTER"); b.t:SetText(txt); b:SetScript("OnClick", function() ShowTab(id) end)
end
CreateTabBtn("GUILD", 15, 1); CreateTabBtn("DELVES", 145, 2); CreateTabBtn("BOUNTY", 275, 3)

-- MURLOC BUTTON
local MBtn = CreateFrame("Button", "DT_MurlocBtn", UIParent); MBtn:SetSize(55, 55); MBtn:SetPoint("CENTER"); MBtn:SetMovable(true); MBtn:EnableMouse(true); MBtn:RegisterForDrag("RightButton")
MBtn.tex = MBtn:CreateTexture(nil, "ARTWORK"); MBtn.tex:SetAllPoints(); MBtn.tex:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\MijnIcoon.tga")
-- UIDropDownMenuTemplate REMOVED in TWW 12.0.5 → MenuUtil.CreateContextMenu
-- menuFrame and menuList removed; menu rebuilt inline via MenuUtil
local function DT_OpenMurlocMenu(owner)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, root)
            root:CreateTitle(SA_PURPLE.."DelveTracker v2.6")
            root:CreateButton("Open Settings",   function() Settings.OpenToCategory(category:GetID()) end)
            root:CreateButton("Reset Position",  function() MBtn:ClearAllPoints(); MBtn:SetPoint("CENTER") end)
            root:CreateButton("Close UI",        function() UI:Hide() end)
        end)
    end
end
MBtn:SetScript("OnClick", function(self, btn) if btn == "LeftButton" then PlaySound(6449); if UI:IsShown() then UI:Hide() else ShowTab(2) end else DT_OpenMurlocMenu(self) end end)
MBtn:SetScript("OnDragStart", MBtn.StartMoving); MBtn:SetScript("OnDragStop", MBtn.StopMovingOrSizing)

-- FINAL INIT
UI:RegisterEvent("PLAYER_ENTERING_WORLD"); UI:RegisterEvent("WEEKLY_REWARDS_UPDATE")
UI:SetScript("OnEvent", function()
    DelveTrackerDB.characters = DelveTrackerDB.characters or {}
    DelveTrackerDB.PluginStates = DelveTrackerDB.PluginStates or {}
    if DelveTrackerDB.scale then UI:SetScale(DelveTrackerDB.scale) end
    if DelveTrackerDB.mScale then MBtn:SetScale(DelveTrackerDB.mScale) end
    UpdateCharacterList()
end)