-- =====================================================
-- DelveTracker Plugin: Registry v8.1.0
-- Focus: Integrated Currency Scanner & DB Sync
-- =====================================================

if DelveTracker then
    -- 1. PLUGIN REGISTRATION
    DelveTracker:RegisterPlugin("Registry", function(mode, data, key)
        if mode == "Tooltip" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00Click to open the XL Registry|r")
        end
    end)

    -- 2. CURRENCY SCANNER (Schrijft naar de database)
    local function ScanAndSyncCurrencies()
-- v3.3.0 (i18n ronde 3): vertaal-helper
local function T(key)
    if WT_T then return WT_T(key) end
    return key
end

        if not DelveTrackerDB then return end
        DelveTrackerDB.characters = DelveTrackerDB.characters or {}

        local charKey = (UnitName("player") or "Unknown").."-"..(GetNormalizedRealmName() or GetRealmName() or "Unknown")
        DelveTrackerDB.characters[charKey] = DelveTrackerDB.characters[charKey] or {}

        DelveTrackerDB.characters[charKey].currencies = DelveTrackerDB.characters[charKey].currencies or {}

        -- 3028 = Restored Coffer Keys
        -- 3310 = Coffer Key Shards
        -- 3376 = Shard of Dundun
        -- 3378 = Dawnlight Manaflux
        local ids = {3028, 3310, 3376, 3378}
        for _, id in ipairs(ids) do
            local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and info then
                DelveTrackerDB.characters[charKey].currencies[id] = info.quantity
            end
        end
    end

    -- 3. THE XL FRAME
    local Registry = CreateFrame("Frame", "DT_RegistryFrame", UIParent, "BackdropTemplate")
    Registry:SetSize(1320, 750); Registry:SetPoint("CENTER"); Registry:Hide()
    Registry:SetMovable(true); Registry:EnableMouse(true); Registry:RegisterForDrag("LeftButton")
    Registry:SetScript("OnDragStart", Registry.StartMoving); Registry:SetScript("OnDragStop", Registry.StopMovingOrSizing)
    Registry:SetClampedToScreen(true); Registry:SetFrameStrata("HIGH"); Registry:SetToplevel(true)

    Registry:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    Registry:SetBackdropColor(0, 0, 0, 0.96); Registry:SetBackdropBorderColor(0.3, 0.1, 0.5, 0.5)

    -- ── WTTHEME KOPPELING (Fase 3.2 · v3.2.7) ────────────────────────────
    -- Register-callback werkt ALLEEN kleuren bij — bovenstaande hardcoded
    -- waarden blijven de startwaarde, dus zonder WTTheme verandert niets.
    if WTTheme and WTTheme.Register then
        local function ApplyRegistryTheme()
            local bg  = WTTheme.bg and WTTheme.bg.main
            local bdr = WTTheme.border and WTTheme.border.main
            if bg then
                Registry:SetBackdropColor(bg.r, bg.g, bg.b, math.max(bg.a or 0.96, 0.94))
            end
            if bdr then
                Registry:SetBackdropBorderColor(bdr.r, bdr.g, bdr.b, 0.7)
            end
        end
        WTTheme.Register(ApplyRegistryTheme)
        ApplyRegistryTheme()   -- direct toepassen op huidig actief thema
    end

    -- Media & Decoratie
    Registry.iconDecor = Registry:CreateTexture(nil, "ARTWORK", nil, 0)
    Registry.iconDecor:SetSize(350, 350); Registry.iconDecor:SetPoint("CENTER", 0, -40)
    Registry.iconDecor:SetTexture("Interface\\AddOns\\WowTracker\\Media\\MijnIcoon.tga")
    Registry.iconDecor:SetAlpha(0.35)

    Registry.dwarfDecor = Registry:CreateTexture(nil, "BACKGROUND", nil, 2)
    Registry.dwarfDecor:SetSize(170, 280); Registry.dwarfDecor:SetPoint("BOTTOMRIGHT", -20, 35)
    Registry.dwarfDecor:SetTexture("Interface\\AddOns\\WowTracker\\Media\\Dieouwe.tga")
    Registry.dwarfDecor:SetAlpha(0.4); Registry.dwarfDecor:SetTexCoord(1, 0, 0, 1)

    Registry.header = Registry:CreateTexture(nil, "OVERLAY")
    Registry.header:SetHeight(45); Registry.header:SetPoint("TOPLEFT", 1, -1); Registry.header:SetPoint("TOPRIGHT", -1, -1)
    Registry.header:SetColorTexture(0.1, 0.08, 0.12, 1)

    Registry.title = Registry:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    Registry.title:SetPoint("LEFT", Registry.header, "LEFT", 25, 0)
    Registry.title:SetText("|cffa335eeSLAYER ALLIANCE|r - "..T("RG_TITLE"))

    Registry.close = CreateFrame("Button", nil, Registry, "UIPanelCloseButton")
    Registry.close:SetPoint("TOPRIGHT", 2, 2)

    local content = CreateFrame("Frame", nil, Registry)
    content:SetPoint("TOPLEFT", 30, -70); content:SetPoint("BOTTOMRIGHT", -30, 30)

    local headers = {}
    local function GetClassGroup(idx)
        if not headers[idx] then
            local f = CreateFrame("Frame", nil, content, "BackdropTemplate")
            f:SetSize(175, 310)
            f.icon = f:CreateTexture(nil, "ARTWORK"); f.icon:SetSize(50, 50); f.icon:SetPoint("TOP", 0, 0)
            f.line = f:CreateTexture(nil, "BACKGROUND"); f.line:SetSize(150, 2); f.line:SetPoint("TOP", f.icon, "BOTTOM", 0, -8)
            f.line:SetColorTexture(0.3, 0.3, 0.3, 0.4)
            f.chars = {}
            for j = 1, 10 do
                local b = CreateFrame("Button", nil, f, "BackdropTemplate")
                b:SetSize(165, 24); b:SetPoint("TOP", f.line, "BOTTOM", 0, -((j-1)*26) - 10)
                b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"}); b:SetBackdropColor(1, 1, 1, 0.03)
                b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.text:SetPoint("CENTER")
                f.chars[j] = b
            end
            headers[idx] = f
        end
        return headers[idx]
    end

    -- =====================================================
    -- TOOLTIP BUILDER
    -- =====================================================

    DT_TooltipModules = DT_TooltipModules or {}

    local function BuildCharTooltip(self, data, shortName, cls, c)
        self:SetBackdropColor(c.r, c.g, c.b, 0.2)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:SetScale(1.25)

        -- === BASIS INFO ===
        GameTooltip:AddLine(shortName, c.r, c.g, c.b)
        GameTooltip:AddLine(string.format("Level %d %s %s", data.level or 0, data.spec or "??", cls), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("iLvl:", "|cff00ff00"..(data.ilvl or 0).."|r", 1,1,1, 1,1,1)

        -- === WEEKLY DELVE PROGRESS ===
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffccaa00Weekly Progress:|r")
        local hasDelves = false
        if data.delves and #data.delves > 0 then
            for _, v in ipairs(data.delves) do
                local color = (v.p >= v.t) and "|cff00ff00" or "|cffff4444"
                GameTooltip:AddDoubleLine("Threshold "..v.t..":", color..v.p.." / "..v.t.."|r")
                hasDelves = true
            end
        end
        if not hasDelves then GameTooltip:AddLine("|cffffffffNo delves completed.|r") end

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total Delves:", "|cffa335ee"..(data.totalDone or 0).."|r")

        -- === GOLD ===
        if data.money then
            GameTooltip:AddDoubleLine("Gold:", "|cffffee00"..math.floor(data.money / 10000).."g|r", 1,1,1, 1,1,1)
        end

        -- === CURRENCIES ===
        local cTab = data.currencies or data.Currencies or data
        local kVal = (type(cTab) == "table" and (cTab[3028] or (cTab["3028"] and (cTab["3028"].amount or cTab["3028"])))) or 0
        local sVal = (type(cTab) == "table" and (cTab[3310] or (cTab["3310"] and (cTab["3310"].amount or cTab["3310"])))) or 0
        local dVal = (type(cTab) == "table" and (cTab[3376] or (cTab["3376"] and (cTab["3376"].amount or cTab["3376"])))) or 0
        local mVal = (type(cTab) == "table" and (cTab[3378] or (cTab["3378"] and (cTab["3378"].amount or cTab["3378"])))) or 0

        GameTooltip:AddDoubleLine("Restored Coffer Keys:", "|cff00ccff"..kVal.."|r", 1,1,1, 1,1,1)
        GameTooltip:AddDoubleLine("Coffer Key Shards:",    "|cffffee00"..sVal.."|r", 1,1,1, 1,1,1)

        -- Dundun direct onder coffer keys: rood = 0, groen = 1+
        local dc = dVal > 0 and "|cff00ff00" or "|cffff4444"
        GameTooltip:AddDoubleLine("Shard of Dundun:",    dc..dVal.."|r", 1,1,1, 1,1,1)

        -- Manaflux onder Dundun: geel = 0, groen = 1+
        local mc = mVal > 0 and "|cff00ff00" or "|cffffff00"
        GameTooltip:AddDoubleLine("Dawnlight Manaflux:", mc..mVal.."|r", 1,1,1, 1,1,1)

        -- =====================================================
        -- PLUGIN HOOK: extra tooltip modules (lockouts, etc.)
        -- =====================================================
        if #DT_TooltipModules > 0 then
            for _, moduleFn in ipairs(DT_TooltipModules) do
                local ok, err = pcall(moduleFn, data, data.fullKey)
                if not ok then
                    GameTooltip:AddLine("|cffff0000[DT module error]|r", 1, 0, 0)
                end
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffccaa00Click for Armory|r")
        GameTooltip:Show()
    end

    function DT_Registry_Update()
        if not DelveTrackerDB or not DelveTrackerDB.characters then return end
        ScanAndSyncCurrencies()

        for _, h in ipairs(headers) do h:Hide(); for _, b in ipairs(h.chars) do b:Hide() end end

        local grouped = {}
        local classOrder = {}
        for key, data in pairs(DelveTrackerDB.characters) do
            local cls = data.class or "UNKNOWN"
            if not grouped[cls] then grouped[cls] = {}; table.insert(classOrder, cls) end
            if #grouped[cls] < 10 then data.fullKey = key; table.insert(grouped[cls], data) end
        end
        table.sort(classOrder)

        local col, row = 0, 0
        for i, cls in ipairs(classOrder) do
            local group = GetClassGroup(i)
            group:SetPoint("TOPLEFT", col * 182, -(row * 330))
            local coords = CLASS_ICON_TCOORDS[cls]
            if coords then group.icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes"); group.icon:SetTexCoord(unpack(coords)) end
            local c = RAID_CLASS_COLORS[cls] or {r=1, g=1, b=1}
            group.line:SetColorTexture(c.r, c.g, c.b, 0.3)

            local chars = grouped[cls]
            table.sort(chars, function(a,b) return a.fullKey < b.fullKey end)

            for j, data in ipairs(chars) do
                local btn = group.chars[j]
                local shortName = data.fullKey:match("([^-]+)") or data.fullKey
                btn.text:SetText(shortName); btn:Show()

                btn:SetScript("OnEnter", function(self)
                    BuildCharTooltip(self, data, shortName, cls, c)
                end)

                btn:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(1, 1, 1, 0.03)
                    GameTooltip:Hide()
                    GameTooltip:SetScale(1.0)
                end)

                btn:SetScript("OnClick", function()
                    data.name = shortName
                    if DT_Armory_ShowCharacter then DT_Armory_ShowCharacter(data) end
                end)
            end
            group:Show()

            -- Kolom layout:
            -- Rij 0 (boven): kolom 0 t/m 6  → alle 7 plaatsen vol
            -- Rij 1+ (onder): kolom 3 overslaan → 0,1,2 vol | 3 leeg | 4,5 vol | 6 leeg (kabouter)
            col = col + 1
            if col >= 7 then col = 0; row = row + 1 end
            if row >= 1 and col == 3 then col = 4 end
        end
    end

    -- Event handling
    Registry:RegisterEvent("PLAYER_ENTERING_WORLD")
    Registry:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    Registry:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "CURRENCY_DISPLAY_UPDATE" then
            ScanAndSyncCurrencies()
        end
    end)

    Registry:SetScript("OnShow", function(self) self:Raise(); DT_Registry_Update() end)

    C_Timer.After(1, function()
        if DelveTrackerFrame then
            local bookBtn = CreateFrame("Button", "DT_RegistryOpenBtn", DelveTrackerFrame, "BackdropTemplate")
            bookBtn:SetSize(22, 22)
            -- Verankerd aan UI.langBtn als dat bestaat, anders vaste positie
            local langBtn = _G["DelveTrackerFrame"] and DelveTrackerFrame.langBtn
            if langBtn then
                bookBtn:SetPoint("RIGHT", langBtn, "LEFT", -3, 0)
            else
                bookBtn:SetPoint("TOPRIGHT", DelveTrackerFrame, "TOPRIGHT", -98, -22)
            end
            bookBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
            bookBtn:SetBackdropColor(0.08,0.04,0.14,0.95)
            bookBtn:SetBackdropBorderColor(0.45,0.12,0.70,0.9)
            bookBtn.t = bookBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); bookBtn.t:SetPoint("CENTER"); bookBtn.t:SetText("|cffa335eeB|r")
            bookBtn:SetScript("OnClick", function() if Registry:IsShown() then Registry:Hide() else Registry:Show() end end)
        end
    end)

    SLASH_DTCREW1 = "/crew"
    SlashCmdList["DTCREW"] = function() if Registry:IsShown() then Registry:Hide() else Registry:Show() end end
end