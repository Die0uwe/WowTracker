-- 1. INITIALISATIE & DATABASE
if not DT_CustomAFK_Settings then DT_CustomAFK_Settings = {} end
if not DT_CustomAFK_Settings.lootHistory then DT_CustomAFK_Settings.lootHistory = {} end
if not DT_CustomAFK_Settings.guildHistory then DT_CustomAFK_Settings.guildHistory = {} end

local defaultSettings = {
    ["L1"]      = 1, 
    ["MID_TOP"] = 1, 
    ["L2"]      = 2,
    ["SIDE_L"]  = 1, 
    ["B1"]      = 3, 
    ["B2"]      = 4,
    ["B3"]      = 6, 
    ["B4"]      = 7, 
    ["B5"]      = 8,
}

local availableIcons = {
    "Interface\\AddOns\\WowTracker\\Media\\Dieouwe.tga",
    "Interface\\AddOns\\WowTracker\\Media\\MijnIcoon.tga",
    "Interface\\AddOns\\WowTracker\\Media\\UCdieouwe.tga",
    "Interface\\AddOns\\WowTracker\\Media\\Shield.tga",
    "Interface\\AddOns\\WowTracker\\Media\\sword.tga",
    "Interface\\AddOns\\WowTracker\\Media\\sinkhole.tga",
    "Interface\\AddOns\\WowTracker\\Media\\site9.tga",
    "Interface\\AddOns\\WowTracker\\Media\\thelostnether.tga",
    "Interface\\AddOns\\WowTracker\\Media\\kelsey.tga",
}

-- 2. EVENT MONITOR (LOOT & GUILD)
local monitor = CreateFrame("Frame")
monitor:RegisterEvent("CHAT_MSG_LOOT")
monitor:RegisterEvent("CHAT_MSG_GUILD")

monitor:SetScript("OnEvent", function(_, event, msg, sender)
    local timestamp = "|cff888888["..date("%H:%M").."]|r "
    if event == "CHAT_MSG_LOOT" then
        local itemLink = msg:match("(|Hitem.-|h%[.-%]|h)")
        if itemLink then 
            local _, _, _, _, icon = GetItemInfoInstant(itemLink)
            local iconStr = icon and ("|T" .. icon .. ":20:20:0:0:64:64:4:60:4:60|t ") or ""
            table.insert(DT_CustomAFK_Settings.lootHistory, 1, { link = itemLink, display = timestamp .. iconStr .. itemLink }) 
        end
        if #DT_CustomAFK_Settings.lootHistory > 12 then table.remove(DT_CustomAFK_Settings.lootHistory, 13) end
    elseif event == "CHAT_MSG_GUILD" then
        local name = Ambiguate(sender, "none")
        table.insert(DT_CustomAFK_Settings.guildHistory, 1, timestamp .. "|cff00ff00" .. name .. ":|r " .. msg)
        if #DT_CustomAFK_Settings.guildHistory > 15 then table.remove(DT_CustomAFK_Settings.guildHistory, 16) end
    end
    if DT_RefreshAllSlots then DT_RefreshAllSlots() end
end)

-- 3. TOOLTIP FUNCTIES
local function OnItemEnter(self)
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end
end
local function OnItemLeave() GameTooltip:Hide() end

-- --- NIEUW/TERUGGEZET: RANDOM STATS LOGICA ---
local function GetSafeStat(id)
    local stat = GetStatistic(id)
    return (stat and stat ~= "--") and stat or "0"
end

local randomStatPool = {
    { label = "Creatures Killed", id = 11 }, { label = "Total Deaths", id = 60 },
    { label = "Quests Completed", id = 98 }, { label = "Total Delves", id = 19144 },
    { label = "Gold Earned", id = 333 }, { label = "Elevator Deaths", id = 1088 },
    { label = "Times Jumped", id = 151 }, { label = "Daily Quests Done", id = 97 },
    { label = "Items Looted", id = 1147 }, { label = "Dungeons Completed", id = 321 },
}

local currentRandomStatText = "Loading..."
local statTimer = CreateFrame("Frame")
local lastStatUpdate = 0
statTimer:SetScript("OnUpdate", function(self, elapsed)
    lastStatUpdate = lastStatUpdate + elapsed
    if lastStatUpdate > 8 then
        local data = randomStatPool[math.random(#randomStatPool)]
        currentRandomStatText = "|cff00ccff" .. data.label .. "|r\n|cffffffff" .. GetSafeStat(data.id) .. "|r"
        if DT_RefreshAllSlots then DT_RefreshAllSlots() end
        lastStatUpdate = 0
    end
end)
-- --------------------------------------------

-- 4. STATS DATA DEFINITIES
local availableStats = {
    { name = "Empty", func = function() return "" end },
    { name = "Time & Date", func = function() return "|cffffffff"..date("%H:%M:%S").."|r\n|cffaaaaaa"..date("%A %d %b").."|r" end },
    { name = "Delve Vault", func = function() 
        local activities = {}
        if C_WeeklyRewards and C_WeeklyRewards.GetActivities and Enum and Enum.WeeklyRewardChestThresholdType then
            local ok, result = pcall(C_WeeklyRewards.GetActivities, Enum.WeeklyRewardChestThresholdType.World)
            if ok and result then activities = result end
        end
        local str = ""
        for i, act in ipairs(activities) do
            local prog = math.min(act.progress, act.threshold)
            local color = (act.progress >= act.threshold) and "|cff00ff00" or "|cffffffff"
            str = str .. color .. prog .. "/" .. act.threshold .. "|r "
        end
        return str ~= "" and str or "0/2 0/4 0/8"
    end },
    { name = "Bountiful Keys", func = function()
        local info
        if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
            local ok, result = pcall(C_CurrencyInfo.GetCurrencyInfo, 3028)
            if ok then info = result end
        end
        return "|cffffffff" .. (info and info.quantity or 0) .. "|r"
    end },
    { name = "Random Stat", func = function() return currentRandomStatText end }, -- TERUGGEKOPPELD
    { name = "Current Gold", func = function() return GetMoneyString(GetMoney(), true) end },
    { name = "Location", func = function() return GetMinimapZoneText() end },
    { name = "FPS & Latency", func = function() return math.floor(GetFramerate()) .. " fps - " .. select(4, GetNetStats()) .. "ms" end },
}

local sideOptions = {
    { name = "Recent Loot" },
    { name = "Guild Chat" },
}

-- 5. REFRESH SLOT LOGICA
local function RefreshSlot(id)
    if not DT_CustomAFK_Frame or not DT_CustomAFK_Frame.Slots then return end
    local slot = DT_CustomAFK_Frame.Slots[id]
    if not slot or id == "MODEL" then return end
    local idx = DT_CustomAFK_Settings[id] or 1
    
    if id == "MID_TOP" then
        local nameWithTitle = UnitPVPName("player") or UnitName("player")
        local factionGroup = UnitFactionGroup("player") or "Neutral"
        local _, classFile = UnitClass("player")
        local race, class = UnitRace("player"), UnitClass("player")
        local ilvl = math.floor(select(2, GetAverageItemLevel()))
        local fIcon = "|TInterface\\Icons\\pvpcurrency-honor-"..string.lower(factionGroup or "neutral")..":28:28:0:0|t"
        local cIcon = "|TInterface\\TargetingFrame\\UI-Classes-Circles:28:28:0:0:256:256:" .. (CLASS_ICON_TCOORDS[classFile][1]*256) .. ":" .. (CLASS_ICON_TCOORDS[classFile][2]*256) .. ":" .. (CLASS_ICON_TCOORDS[classFile][3]*256) .. ":" .. (CLASS_ICON_TCOORDS[classFile][4]*256) .. "|t"
        slot.txt:SetFont("Fonts\\2002.ttf", 22, "OUTLINE")
        slot.txt:SetText(fIcon .. " |cffffd100" .. nameWithTitle .. "|r " .. cIcon .. "\n|cffaaaaaa" .. race .. " " .. class .. "|r\n|cffffffffLevel: " .. UnitLevel("player") .. "  -  " .. ilvl .. " Item Level|r")
        return
    end

    if id == "SIDE_L" then
        local opt = sideOptions[idx] or sideOptions[1]
        slot.txt:SetJustifyH("LEFT")
        slot.txt:SetJustifyV("TOP")
        slot.txt:SetWordWrap(true)
        slot.txt:SetWidth(slot:GetWidth() - 25)
        
        if not slot.itemButtons then slot.itemButtons = {} end

        if opt.name == "Recent Loot" then
            slot.txt:SetFont("Fonts\\2002.ttf", 18, "OUTLINE")
            local fullText = "|cffccaa00Recent Loot|r\n\n"
            for i=1, 12 do
                if not slot.itemButtons[i] then
                    slot.itemButtons[i] = CreateFrame("Button", nil, slot)
                    slot.itemButtons[i]:SetFrameLevel(slot:GetFrameLevel() + 10)
                end
                local data = DT_CustomAFK_Settings.lootHistory[i]
                if data then
                    fullText = fullText .. data.display .. "\n"
                    slot.itemButtons[i].link = data.link
                    slot.itemButtons[i]:SetSize(slot:GetWidth() - 20, 22)
                    slot.itemButtons[i]:SetPoint("TOPLEFT", slot.txt, "TOPLEFT", 0, -22 * (i+1))
                    slot.itemButtons[i]:SetScript("OnEnter", OnItemEnter)
                    slot.itemButtons[i]:SetScript("OnLeave", OnItemLeave)
                    slot.itemButtons[i]:Show()
                else slot.itemButtons[i]:Hide() end
            end
            slot.txt:SetText(fullText)
        else
            slot.txt:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
            if slot.itemButtons then for _, b in pairs(slot.itemButtons) do b:Hide() end end
            local chatContent = #DT_CustomAFK_Settings.guildHistory > 0 and table.concat(DT_CustomAFK_Settings.guildHistory, "\n") or "No messages"
            slot.txt:SetText("|cffccaa00Guild Chat|r\n\n" .. chatContent)
        end
        return
    end

    if id == "L1" then
        if not slot.img then slot.img = slot:CreateTexture(nil, "OVERLAY"); slot.img:SetSize(110, 110); slot.img:SetPoint("CENTER") end
        slot.img:SetTexture(availableIcons[idx] or availableIcons[1]); slot.txt:SetText("")
    else
        local stat = availableStats[idx]
        if stat then
            slot.txt:SetFontObject("GameFontNormalHuge")
            slot.txt:SetText("|cffccaa00" .. stat.name .. "|r\n|cffffffff" .. stat.func() .. "|r")
        end
    end
end

function DT_RefreshAllSlots()
    if not DT_CustomAFK_Frame or not DT_CustomAFK_Frame.Slots then return end
    for id in pairs(DT_CustomAFK_Frame.Slots) do RefreshSlot(id) end
end

-- 6. GRID CONTROL (KNOP IN B3)
local function SetupGridButton()
    if not DT_CustomAFK_Frame or not DT_CustomAFK_Frame.Slots["B3"] then return end
    local b3 = DT_CustomAFK_Frame.Slots["B3"]
    if not b3.CloseBtn then
        b3.CloseBtn = CreateFrame("Button", nil, b3, "UIPanelButtonTemplate")
        b3.CloseBtn:SetSize(75, 22)
        b3.CloseBtn:SetPoint("BOTTOMRIGHT", b3, "BOTTOMRIGHT", -5, 5)
        b3.CloseBtn:SetFrameLevel(b3:GetFrameLevel() + 50)
        b3.CloseBtn:SetText("|cffff0000CLOSE|r")
        b3.CloseBtn:SetScript("OnClick", function() 
            DT_CustomAFK_Frame:Hide()
            b3.CloseBtn:Hide()
        end)
    end
    b3.CloseBtn:Show()
end

SLASH_DELVETRACKERAFK1 = "/dtafkpanel"
SlashCmdList["DELVETRACKERAFK"] = function()
    if DT_CustomAFK_Frame then DT_CustomAFK_Frame:Show() end
    if SetupGridButton then SetupGridButton() end
end

-- 7. STARTUP
C_Timer.After(2.0, function()
    if DT_CustomAFK_Frame and DT_CustomAFK_Frame.Slots then
        for k, v in pairs(defaultSettings) do
            if DT_CustomAFK_Settings[k] == nil then DT_CustomAFK_Settings[k] = v end
        end
        for id, slot in pairs(DT_CustomAFK_Frame.Slots) do
            slot:EnableMouseWheel(true)
            slot:SetScript("OnMouseWheel", function(_, delta)
                if id == "MID_TOP" or id == "MODEL" then return end
                local cur = DT_CustomAFK_Settings[id] or 1
                local maxPool = (id == "L1") and #availableIcons or (id == "SIDE_L") and #sideOptions or #availableStats
                if delta > 0 then cur = cur - 1 else cur = cur + 1 end
                if cur < 1 then cur = maxPool elseif cur > maxPool then cur = 1 end
                DT_CustomAFK_Settings[id] = cur
                RefreshSlot(id)
            end)
        end
        DT_RefreshAllSlots()
    end
end)