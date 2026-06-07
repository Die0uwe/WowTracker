-- =====================================================
-- DelveTracker Plugin: Charmory v43.5 (SCALABLE LOOK)
-- =====================================================

if DelveTracker then
    DelveTracker:RegisterPlugin("Charmory", function() end)

    local Armory = CreateFrame("Frame", "DT_ArmoryFrame", UIParent, "BackdropTemplate")
    Armory:SetSize(420, 550)
    Armory:SetFrameStrata("DIALOG")
    Armory:SetToplevel(true)
    Armory:Hide()

    -- =====================================================
    -- SCHAAL FUNCTIE & PIJLTJES
    -- =====================================================
    local function UpdateScale(delta)
        local currentScale = Armory:GetScale()
        local newScale = currentScale + delta
        if newScale < 0.5 then newScale = 0.5 end
        if newScale > 1.5 then newScale = 1.5 end
        Armory:SetScale(newScale)
    end

    -- Knop Groter (+)
    Armory.btnPlus = CreateFrame("Button", nil, Armory)
    Armory.btnPlus:SetSize(20, 20)
    Armory.btnPlus:SetPoint("TOPRIGHT", Armory, "TOPRIGHT", -55, -6)
    Armory.btnPlus:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    Armory.btnPlus:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    Armory.btnPlus:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    Armory.btnPlus:SetScript("OnClick", function() UpdateScale(0.05) end)

    -- Knop Kleiner (-)
    Armory.btnMinus = CreateFrame("Button", nil, Armory)
    Armory.btnMinus:SetSize(20, 20)
    Armory.btnMinus:SetPoint("RIGHT", Armory.btnPlus, "LEFT", -2, 0)
    Armory.btnMinus:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    Armory.btnMinus:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    Armory.btnMinus:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    Armory.btnMinus:SetScript("OnClick", function() UpdateScale(-0.05) end)
    -- =====================================================

    Armory:SetMovable(true); Armory:EnableMouse(true); Armory:RegisterForDrag("LeftButton")
    Armory:SetClampedToScreen(true)

    local function ResetArmoryPosition()
        -- Embedded in Tab5: nooit verplaatsen
        if Armory._embedded then return end
        -- Standalone: altijd gecentreerd op scherm, nooit buiten beeld
        Armory:SetParent(UIParent)
        Armory:SetMovable(true)
        Armory:EnableMouse(true)
        Armory:SetFrameStrata("DIALOG")
        Armory:ClearAllPoints()
        -- Gecentreerd links van scherm midden — altijd zichtbaar
        Armory:SetPoint("CENTER", UIParent, "CENTER", -250, 20)
    end

    Armory:SetScript("OnDragStart", Armory.StartMoving)
    Armory:SetScript("OnDragStop", Armory.StopMovingOrSizing)

    Armory:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    Armory:SetBackdropColor(0, 0, 0, 0.9); Armory:SetBackdropBorderColor(0, 0, 0, 1)

    -- Shield: BACKGROUND laag -2, tot aan gold bar, achter gear+model+tekst
    Armory.bgShield = Armory:CreateTexture(nil, "BACKGROUND", nil, -2)
    Armory.bgShield:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\Shield.tga")
    -- Grootte: vult het model gebied van top tot boven de gold bar
    Armory.bgShield:SetSize(360, 440)
    Armory.bgShield:SetPoint("TOP", Armory, "TOP", 0, -30)
    Armory.bgShield:SetAlpha(0.55)

    Armory.closeBtn = CreateFrame("Button", nil, Armory, "UIPanelCloseButton")
    Armory.closeBtn:SetPoint("TOPRIGHT", Armory, "TOPRIGHT", -2, -2)
    Armory.closeBtn:SetScript("OnClick", function() Armory:Hide() end)

    local function CreateStatBox(yOff)
        local f = CreateFrame("Frame", nil, Armory, "BackdropTemplate")
        f:SetSize(380, 28); f:SetPoint("BOTTOM", 0, yOff)
        f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"}); f:SetBackdropColor(0, 0, 0, 0.4) 
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.text:SetPoint("CENTER")
        return f
    end
    Armory.statPrimary = CreateStatBox(85)
    Armory.statSecondary = CreateStatBox(55)

    Armory.header = Armory:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge3")
    Armory.header:SetPoint("TOP", 0, -35); Armory.header:SetScale(1.1)
    Armory.guildStr = Armory:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    Armory.guildStr:SetPoint("TOP", Armory.header, "BOTTOM", 0, -4)
    Armory.model = CreateFrame("PlayerModel", nil, Armory)
    Armory.model:SetSize(280, 320); Armory.model:SetPoint("CENTER", 0, 40)

    Armory.goldFrame = CreateFrame("Frame", nil, Armory, "BackdropTemplate")
    Armory.goldFrame:SetSize(335, 26); Armory.goldFrame:SetPoint("BOTTOMLEFT", 15, 15)
    Armory.goldFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    Armory.goldFrame:SetBackdropColor(0, 0, 0, 0.9); Armory.goldFrame:SetBackdropBorderColor(1, 0.82, 0, 0.4)
    Armory.goldText = Armory.goldFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); Armory.goldText:SetPoint("CENTER")
    
    local slotsPos = {
        {"HeadSlot", "LEFT", 12, 170}, {"NeckSlot", "LEFT", 12, 125}, {"ShoulderSlot", "LEFT", 12, 80},
        {"BackSlot", "LEFT", 12, 35}, {"ChestSlot", "LEFT", 12, -10}, {"WristSlot", "LEFT", 12, -55},
        {"HandsSlot", "RIGHT", -12, 170}, {"WaistSlot", "RIGHT", -12, 125}, {"LegsSlot", "RIGHT", -12, 80},
        {"FeetSlot", "RIGHT", -12, 35}, {"Finger0Slot", "RIGHT", -12, -10}, {"Finger1Slot", "RIGHT", -12, -55},
        {"Trinket0Slot", "RIGHT", -12, -115}, {"Trinket1Slot", "RIGHT", -12, -160}, 
        {"MainHandSlot", "BOTTOM", -45, 125}, {"SecondaryHandSlot", "BOTTOM", 45, 125} 
    }
    Armory.buttons = {}
    for _, info in ipairs(slotsPos) do
        local b = CreateFrame("Button", nil, Armory, "BackdropTemplate")
        b:SetSize(42, 42); b:SetPoint(info[2], Armory, info[2], info[3], info[4])
        b.icon = b:CreateTexture(nil, "BACKGROUND"); b.icon:SetAllPoints(); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        b.ilvl = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmallOutline"); b.ilvl:SetPoint("BOTTOMRIGHT", -1, 2)
        b:SetScript("OnEnter", function(self) if self.link then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.link); GameTooltip:Show() end end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        Armory.buttons[info[1]] = b
    end

    -- ── STATS PANEL (rechts naast model in Tab5) ─────────────────────────
    local StatsPanel = CreateFrame("Frame", "DT_ArmoryStatsPanel", Armory, "BackdropTemplate")
    StatsPanel:SetSize(480, 500)
    StatsPanel:SetPoint("TOPLEFT", Armory, "TOPRIGHT", 4, 0)
    StatsPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    StatsPanel:SetBackdropColor(0.04, 0.02, 0.08, 0.96)
    StatsPanel:SetBackdropBorderColor(0.20, 0.50, 0.80, 0.8)
    StatsPanel:Hide()

    -- Sectie header helper
    local C_2002 = "Fonts\\2002.ttf"
    local function SecHdr(txt, yOff)
        local f = StatsPanel:CreateFontString(nil,"OVERLAY")
        f:SetFont(C_2002, 10, "OUTLINE")
        f:SetPoint("TOPLEFT", 10, yOff)
        f:SetTextColor(0.60, 0.40, 1.0, 1)
        f:SetText(txt)
        return f
    end
    local function StatRow(lbl, yOff)
        local l = StatsPanel:CreateFontString(nil,"OVERLAY")
        l:SetFont(C_2002, 11, "")
        l:SetPoint("TOPLEFT", 10, yOff)
        l:SetTextColor(0.70, 0.70, 0.80, 1)
        l:SetText(lbl)
        local v = StatsPanel:CreateFontString(nil,"OVERLAY")
        v:SetFont(C_2002, 11, "OUTLINE")
        v:SetPoint("TOPRIGHT", -10, yOff)
        v:SetTextColor(1.0, 1.0, 1.0, 1)
        return l, v
    end

    -- Bouw stat rijen
    SecHdr("── KARAKTER ──", -12)
    local _,  vClass  = StatRow("Klasse",  -26)
    local _,  vSpec   = StatRow("Spec",    -42)
    local _,  vLevel  = StatRow("Level",   -58)
    local _,  vIlvl   = StatRow("iLvl",    -74)
    local _,  vGuild  = StatRow("Guild",   -90)

    SecHdr("── STATS ──", -114)
    local _,  vStam   = StatRow("Stamina",  -128)
    local _,  vStr    = StatRow("Strength", -144)
    local _,  vAgi    = StatRow("Agility",  -160)
    local _,  vInt    = StatRow("Intellect",-176)
    local _,  vArmor  = StatRow("Armor",    -192)

    SecHdr("── CURRENCIES ──", -216)
    local _,  vKeys   = StatRow("Coffer Keys",   -230)
    local _,  vShards = StatRow("Key Shards",    -246)
    local _,  vDundun = StatRow("Shard of Dundun",-262)
    local _,  vMana   = StatRow("Dawnlight Manaflux",-278)

    SecHdr("── DELVES DEZE WEEK ──", -302)
    local _,  vD4     = StatRow("Threshold 4",  -316)
    local _,  vD8     = StatRow("Threshold 8",  -332)
    local _,  vD12    = StatRow("Threshold 12", -348)

    SecHdr("── GOUD ──", -372)
    local _,  vGold   = StatRow("Totaal",  -386)

    StatsPanel.Fill = function(data)
        if not data then StatsPanel:Hide(); return end
        StatsPanel:Show()

        -- Karakter
        local clr = RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class] or {r=1,g=1,b=1}
        vClass:SetText(string.format("|cff%02x%02x%02x%s|r",
            math.floor((clr.r or 1)*255), math.floor((clr.g or 1)*255), math.floor((clr.b or 1)*255),
            data.class or "?"))
        vSpec:SetText("|cffccddff"..(data.spec or "?").."|r")
        vLevel:SetText("|cffffffff"..(data.level or "?").."|r")
        vIlvl:SetText("|cff00ff00"..(data.ilvl or 0).."|r")
        vGuild:SetText("|cff00ccff"..(data.guild or "Geen Guild").."|r")

        -- Stats (alleen als huidig karakter)
        if data.stats then
            vStam:SetText("|cffffffff"..(data.stats.stamina or 0).."|r")
            vStr:SetText("|cffffffff"..(data.stats.str or 0).."|r")
            vAgi:SetText("|cffffffff"..(data.stats.agi or 0).."|r")
            vInt:SetText("|cffffffff"..(data.stats.int or 0).."|r")
            vArmor:SetText("|cffffffff"..(data.stats.armor or 0).."|r")
        else
            for _, v in ipairs({vStam,vStr,vAgi,vInt,vArmor}) do v:SetText("|cff554466—|r") end
        end

        -- Currencies
        local cur = data.currencies or {}
        local function cv(id) return tostring(cur[id] or 0) end
        vKeys:SetText("|cff00ccff"..cv(3028).."|r")
        vShards:SetText("|cffffee00"..cv(3310).."|r")
        local dv = cur[3376] or 0
        vDundun:SetText((dv>0 and "|cff44cc66" or "|cffff5555")..dv.."|r")
        local mv = cur[3378] or 0
        vMana:SetText((mv>0 and "|cffa335ee" or "|cff887799")..mv.."|r")

        -- Delves
        if data.delves then
            local thresholds = {4,8,12}
            local targets = {vD4,vD8,vD12}
            for i,v in ipairs(data.delves) do
                if targets[i] then
                    local col = v.p >= v.t and "|cff44cc66" or "|cffff5555"
                    targets[i]:SetText(col..v.p.."/"..v.t.."|r")
                end
            end
            for i=#data.delves+1,3 do
                if targets[i] then targets[i]:SetText("|cff554466—|r") end
            end
        else
            for _,v in ipairs({vD4,vD8,vD12}) do v:SetText("|cff554466—|r") end
        end

        -- Gold
        vGold:SetText("|cffccaa00"..math.floor((data.money or 0)/10000).."g|r")
    end

    function DT_Armory_ShowCharacter(data)
        if not data then return end
        ResetArmoryPosition(); Armory:Show()
        StatsPanel.Fill(data)
        
        if data.stats then
            local mainStat = data.stats.str or data.stats.agi or data.stats.int or 0
            Armory.statPrimary.text:SetText(string.format("Stamina: |cffffffff%s|r  -  Main: |cffffffff%s|r", data.stats.stamina or 0, mainStat))
            Armory.statSecondary.text:SetText(string.format("Armor: |cffffffff%s|r  -  iLvl: |cffffffff%.1f|r", data.stats.armor or 0, data.avgIlvl or 0))
        end

        local function FillGear()
            local allLoaded = true
            if data.gear then
                for slot, btn in pairs(Armory.buttons) do
                    local g = data.gear[slot]
                    if g then
                        local itemName, _, q, _, _, _, _, _, _, tex = GetItemInfo(g.link)
                        if tex then
                            btn.icon:SetTexture(tex); btn.link = g.link; btn:SetAlpha(1); btn.ilvl:SetText(g.ilvl or "")
                            local r, g, b = GetItemQualityColor(q or 1); btn:SetBackdropBorderColor(r, g, b, 1)
                        else
                            allLoaded = false
                            if C_Item then
                                if C_Item.RequestLoadItemData then
                                    pcall(C_Item.RequestLoadItemData, g.link)
                                elseif C_Item.RequestLoadItemDataByID then
                                    local itemID = GetItemInfoInstant and GetItemInfoInstant(g.link)
                                    if itemID then pcall(C_Item.RequestLoadItemDataByID, itemID) end
                                end
                            end
                            btn:SetAlpha(0.1)
                        end
                    else
                        local _, slotTexture = GetInventorySlotInfo(slot)
                        btn.icon:SetTexture(slotTexture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
                        btn.link = nil; btn:SetAlpha(0.3); btn.ilvl:SetText(""); btn:SetBackdropBorderColor(0,0,0,0.8)
                    end
                end
            end
            if not allLoaded then C_Timer.After(0.2, FillGear) end
        end

        local clr = RAID_CLASS_COLORS[data.class] or {r=1, g=1, b=1}
        Armory.header:SetText(string.format("|cff%02x%02x%02x%s|r", clr.r*255, clr.g*255, clr.b*255, data.name))
        Armory.guildStr:SetText("|cff00ccff<"..(data.guild or "Geen Guild")..">|r")
        Armory.goldText:SetText(GetCoinTextureString(data.money or 0))

        if data.name == UnitName("player") then Armory.model:SetUnit("player") else Armory.model:SetDisplayInfo(385) end
        Armory.model:SetAnimation(4); FillGear()
    end

    SLASH_CHARMORY1 = "/charmory"
SLASH_CHARMORY2 = "/armory"
    SlashCmdList["CHARMORY"] = function()
    Armory._standaloneMode = true
    Armory._embedded = false
    -- Herstel StatsPanel parent naar Armory
    local sp = _G["DT_ArmoryStatsPanel"]
    if sp then
        sp:SetParent(Armory)
        sp:ClearAllPoints()
        sp:SetPoint("TOPLEFT", Armory, "TOPRIGHT", 4, 0)
        sp:SetSize(420, Armory:GetHeight() or 500)
        sp:Show()
    end
    -- Zorg dat close knop zichtbaar is
    if Armory.closeBtn then Armory.closeBtn:Show() end 
        local name, realm = UnitName("player"), GetNormalizedRealmName()
        local key = name.."-"..realm
        if not DelveTrackerDB.characters then DelveTrackerDB.characters = {} end
        if not DelveTrackerDB.characters[key] then DelveTrackerDB.characters[key] = { gear = {}, stats = {} } end
        local charData = DelveTrackerDB.characters[key]
        charData.name, charData.class, charData.money = name, select(2, UnitClass("player")), GetMoney()
        charData.guild = GetGuildInfo("player") or "Geen Guild"
        charData.avgIlvl = select(2, GetAverageItemLevel())
        charData.stats = { stamina = UnitStat("player", 3), str = UnitStat("player", 1), agi = UnitStat("player", 2), int = UnitStat("player", 4), armor = select(2, UnitArmor("player")) }

        local slots = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"}
        charData.gear = charData.gear or {}
        for _, s in ipairs(slots) do
            local link = GetInventoryItemLink("player", GetInventorySlotInfo(s))
            if link then charData.gear[s] = { link = link, ilvl = C_Item.GetDetailedItemLevelInfo(link) } else charData.gear[s] = nil end
        end
        DT_Armory_ShowCharacter(charData) 
    end
end