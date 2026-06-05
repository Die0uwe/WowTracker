-- ============================================================
-- WowTracker Plugin Wrapper — Charmory v1.x
-- ============================================================
local addonName, addonTable = ...
local _cmWrap = CreateFrame("Frame")
_cmWrap:RegisterEvent("ADDON_LOADED")
_cmWrap:SetScript("OnEvent", function(self, event, name)
    if name ~= "WowTracker" then return end
    self:UnregisterAllEvents()
    if not WowTracker then return end
    WowTracker:RegisterPlugin({
        id       = "charmory",
        name     = "Charmory",
        version  = "1.0",
        category = "Warband",
        icon     = "👥",
        enabled  = true,
        buildUI = function(cf)
            local db = WowTrackerDB; if not db then return end
            local title = cf:CreateFontString(nil,"OVERLAY"); title:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
            title:SetPoint("TOPLEFT",14,-8); title:SetText("|cffccaa00👥 Charmory — Account Overzicht|r")
            local scroll = CreateFrame("ScrollFrame",nil,cf,"UIPanelScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT",10,-36); scroll:SetPoint("BOTTOMRIGHT",-28,-4)
            local content = CreateFrame("Frame",nil,scroll); content:SetSize(700,1); scroll:SetScrollChild(content)
            local y = 0
            local chars = {}
            for k in pairs(db.characters or {}) do table.insert(chars,k) end; table.sort(chars)
            for _, key in ipairs(chars) do
                local d = db.characters[key]
                local cname = key:match("([^-]+)") or key
                local realm = key:match("-(.+)") or ""
                local cc = d.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[d.class]
                local r_h = cc and math.floor(cc.r*255) or 255
                local g_h = cc and math.floor(cc.g*255) or 255
                local b_h = cc and math.floor(cc.b*255) or 255
                local row = content:CreateFontString(nil,"OVERLAY"); row:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
                row:SetPoint("TOPLEFT",4,y)
                local fac = d.faction=="Horde" and "|cffff4444H|r" or "|cff0077ffA|r"
                row:SetText(string.format(
                    "%s  |cff%02x%02x%02x%-16s|r  |cff888888%s  %s|r  |cff00ff00iLvl %d|r  |cff666666Lvl %d|r  |cff555566%s|r",
                    fac, r_h, g_h, b_h, cname, d.spec or "?", d.class or "?",
                    d.ilvl or 0, d.level or 0, realm
                ))
                y = y - 22
            end
            if #chars == 0 then
                local none = content:CreateFontString(nil,"OVERLAY"); none:SetFont("Fonts\\2002.ttf",12,"OUTLINE")
                none:SetPoint("TOPLEFT",14,-20); none:SetText("|cff888888Log in op je characters om data te laden|r")
            end
            content:SetHeight(math.max(math.abs(y)+20, 100))
        end,
        onEnable=function() end, onDisable=function() end,
    })
end)
-- ============================================================
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
        Armory:ClearAllPoints()
        if DelveTrackerFrame and DelveTrackerFrame:IsShown() then
            Armory:SetPoint("TOPLEFT", DelveTrackerFrame, "TOPRIGHT", 2, 0)
        else
            Armory:SetPoint("CENTER", UIParent, "CENTER")
        end
    end

    Armory:SetScript("OnDragStart", Armory.StartMoving)
    Armory:SetScript("OnDragStop", Armory.StopMovingOrSizing)

    Armory:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    Armory:SetBackdropColor(0, 0, 0, 0.9); Armory:SetBackdropBorderColor(0, 0, 0, 1)

    Armory.bgShield = Armory:CreateTexture(nil, "ARTWORK")
    Armory.bgShield:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\Shield.tga")
    Armory.bgShield:SetSize(315, 412); Armory.bgShield:SetPoint("TOP", Armory, "TOP", 0, -25)

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

    function DT_Armory_ShowCharacter(data)
        if not data then return end
        ResetArmoryPosition(); Armory:Show()
        
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
    SlashCmdList["CHARMORY"] = function() 
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