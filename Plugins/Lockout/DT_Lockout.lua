-- ============================================================
-- WowTracker Plugin Wrapper — Lockout v1.9.0
-- ============================================================
local addonName, addonTable = ...
local _lkWrap = CreateFrame("Frame")
_lkWrap:RegisterEvent("ADDON_LOADED")
_lkWrap:SetScript("OnEvent", function(self, event, name)
    if name ~= "WowTracker" then return end
    self:UnregisterAllEvents()
    if not WowTracker then return end
    WowTracker:RegisterPlugin({
        id       = "lockout",
        name     = "Lockout",
        version  = "1.9.0",
        category = "Tracking",
        icon     = "🔒",
        enabled  = true,
        scan = function(charKey, charData, db)
            charData.lockouts = charData.lockouts or {}
            local num = GetNumSavedInstances and GetNumSavedInstances() or 0
            for i = 1, num do
                local n,_,reset,diff,_,_,_,_,_,maxBoss,_,defeatedBosses = GetSavedInstanceInfo(i)
                if n then
                    charData.lockouts[n] = { diff=diff, reset=reset, bosses=defeatedBosses, maxBosses=maxBoss }
                end
            end
        end,
        buildUI = function(cf)
            -- Build lockout display from WowTrackerDB
            local db = WowTrackerDB
            if not db then return end
            local key = (UnitName("player") or "?").."-"..(GetNormalizedRealmName() or "?")
            local char = db.characters and db.characters[key]
            local lockouts = char and char.lockouts or {}
            local title = cf:CreateFontString(nil,"OVERLAY"); title:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
            title:SetPoint("TOPLEFT",14,-10); title:SetText("|cffccaa00Weekly Lockouts — "..key.."|r")
            local y = -38
            local count = 0
            for name, data in pairs(lockouts) do
                count = count + 1
                local row = cf:CreateFontString(nil,"OVERLAY"); row:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
                row:SetPoint("TOPLEFT",20,y)
                local timeLeft = data.reset and (data.reset - GetServerTime()) or 0
                local h = math.floor(timeLeft/3600)
                row:SetText(string.format("|cff00dfff%s|r  |cff666666Diff:%d  Bosses:%d/%d  Reset: %dh|r",
                    name, data.diff or 0, data.bosses or 0, data.maxBosses or 0, h))
                y = y - 20
            end
            if count == 0 then
                local none = cf:CreateFontString(nil,"OVERLAY"); none:SetFont("Fonts\\2002.ttf",12,"OUTLINE")
                none:SetPoint("CENTER"); none:SetText("|cff888888Geen actieve lockouts|r")
            end
        end,
        onEnable=function() end, onDisable=function() end,
    })
end)
-- ============================================================
-- =====================================================
-- DelveTracker Plugin: Lockout v1.9.0
-- Shows: M+ key/best + Raid Lockouts + Professions
-- Fix: Cooking/Fishing via expliciete slot uitpak
-- =====================================================

if not DelveTracker then return end

DT_TooltipModules = DT_TooltipModules or {}

-- =====================================================
-- 1. CONSTANTEN
-- =====================================================

local DIFF_LABEL = {
    [1]  = "N",
    [2]  = "H",
    [8]  = "M",
    [14] = "N",
    [15] = "H",
    [16] = "M",
    [17] = "LFR",
    [23] = "M",
    [24] = "TW",
    [33] = "TW",
}

local DUNDUN_ID   = 3376
local MANAFLUX_ID = 3378

-- Midnight profession knowledge currency IDs
local PROF_KNOWLEDGE = {
    [25229] = { total = 3156, weekly = 3194 },  -- Jewelcrafting   ✓
    [45357] = { total = 3155, weekly = 3195 },  -- Inscription     ✓
    -- Vul aan na /dtprof op andere alts:
    -- Alchemy        total=3150  weekly=3189
    -- Blacksmithing  total=3151  weekly=3199
    -- Enchanting     total=3152  weekly=3198
    -- Engineering    total=3153  weekly=3197
    -- Herbalism      total=3154  weekly=3196
    -- Leatherworking total=3157  weekly=3193
    -- Mining         total=3158  weekly=3192
    -- Skinning       total=3159  weekly=3191
    -- Tailoring      total=3160  weekly=3190
}

-- Secondary profs: show rank but no knowledge
local SECONDARY = {
    [2550]   = true,   -- Cooking   ✓
    [131474] = true,   -- Fishing   ✓
}

-- Gefilterde profs: bestaan niet in Midnight
local FILTER_PROFS = {
    [794] = true,   -- Archaeology ✓
}

-- =====================================================
-- 2. HELPERS
-- =====================================================

local function KeyColor(level)
    if level >= 10 then return "|cffffff00"
    elseif level >= 7  then return "|cff00ff00"
    else                    return "|cff00ccff" end
end

local function RankColor(rank, maxRank)
    if maxRank == 0 then return "|cffaaaaaa" end
    if rank >= maxRank            then return "|cff00ff00"
    elseif rank >= maxRank * 0.75 then return "|cffffff00"
    else                               return "|cffff6644" end
end

local function WeeklyColor(earned, max)
    if max == 0 then return "|cffaaaaaa" end
    local pct = earned / max
    if pct >= 1.0     then return "|cff00ff00"
    elseif pct >= 0.5 then return "|cffffff00"
    else                   return "|cffff4444" end
end

local function Divider()
    GameTooltip:AddLine("|cff333333---------------------------------------|r")
end

-- =====================================================
-- 3. SCANNER
-- =====================================================

local LockoutScanner = CreateFrame("Frame", "DT_LockoutScannerFrame")

local function DT_GetChallengeMapName(mapID)
    if not mapID then return "Unknown" end
    if C_ChallengeMode and C_ChallengeMode.GetMapInfo then
        local ok, info = pcall(C_ChallengeMode.GetMapInfo, mapID)
        if ok then
            if type(info) == "table" then
                return info.name or info.mapName or info.shortName or "Unknown"
            elseif type(info) == "string" then
                return info
            end
        end
    end
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
        if ok and name then return name end
    end
    return "Unknown"
end

local function ScanAll()
    if not DelveTrackerDB then return end
    DelveTrackerDB.characters = DelveTrackerDB.characters or {}

    local charKey = (UnitName("player") or "Unknown") .. "-" .. (GetNormalizedRealmName() or GetRealmName() or "Unknown")
    local char = DelveTrackerDB.characters[charKey] or {}
    DelveTrackerDB.characters[charKey] = char

    -- ── 3a. Raid lockouts ────────────────────────────────────────────────
    char.lockouts = {}
    local numSaved = GetNumSavedInstances()
    for i = 1, numSaved do
        local name, _, reset, difficulty, locked, extended,
              _, isRaid, _, difficultyName,
              numEncounters, encounterProgress = GetSavedInstanceInfo(i)
        if locked and isRaid then
            table.insert(char.lockouts, {
                name              = name,
                diff              = DIFF_LABEL[difficulty] or difficultyName or "?",
                numEncounters     = numEncounters     or 0,
                encounterProgress = encounterProgress or 0,
                reset             = reset             or 0,
                extended          = extended          or false,
            })
        end
    end

    -- ── 3b. Mythic+ key ──────────────────────────────────────────────────
    char.mythicKey = nil
    local ok1, keyLevel = pcall(function()
        return C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and
               C_MythicPlus.GetOwnedKeystoneLevel()
    end)
    if ok1 and keyLevel and keyLevel > 0 then
        local mapName = "Unknown"
        local ok2, mapID = pcall(function()
            return C_MythicPlus.GetOwnedKeystoneChallengeMapID and
                   C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        end)
        if ok2 and mapID then
            mapName = DT_GetChallengeMapName(mapID)
        end
        char.mythicKey = { level = keyLevel, mapName = mapName }
    end

    -- ── 3c. M+ weekly best ───────────────────────────────────────────────
    char.mythicBest = nil
    if C_MythicPlus and C_MythicPlus.GetWeeklyBestForSeason then
        local ok4, result = pcall(C_MythicPlus.GetWeeklyBestForSeason)
        if ok4 and result and type(result) == "table" and result.level and result.level > 0 then
            local bestMapName = "Unknown"
            if result.mapChallengeModeID then
                bestMapName = DT_GetChallengeMapName(result.mapChallengeModeID)
            end
            char.mythicBest = { level = result.level, mapName = bestMapName }
        end
    end

    -- ── 3d. RaiderIO score (optioneel) ───────────────────────────────────
    char.rioScore = nil
    if RaiderIO and RaiderIO.GetProfile then
        local ok6, profile = pcall(RaiderIO.GetProfile,
            UnitName("player"), (GetNormalizedRealmName() or GetRealmName()), "CURRENT")
        if ok6 and profile and profile.mythicKeystoneProfile then
            char.rioScore = profile.mythicKeystoneProfile.currentScore or 0
        end
    end

    -- ── 3e. Professions ─────────────────────────────────────────────────────
    -- GetProfessions() geeft terug: prof1, prof2, archaeology, fishing, cooking
    -- Een nil slot (bv. Archaeology niet geleerd) stopt ipairs vroegtijdig.
    -- Expliciete uitpak garandeert dat fishing en cooking altijd bereikt worden.
    char.professions = {}

    local p1, p2, p3, p4, p5, p6 = GetProfessions()
    local profSlots = {}
    if p1 then table.insert(profSlots, p1) end
    if p2 then table.insert(profSlots, p2) end
    if p3 then table.insert(profSlots, p3) end
    if p4 then table.insert(profSlots, p4) end
    if p5 then table.insert(profSlots, p5) end
    if p6 then table.insert(profSlots, p6) end

    for _, idx in ipairs(profSlots) do
        local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(idx)
        if name and skillLine and not FILTER_PROFS[skillLine] then
            local knowledgeTotal   = nil
            local knowledgeEarned  = nil
            local knowledgeWeekMax = nil
            local isSecondary      = SECONDARY[skillLine] or false

            if not isSecondary then
                local ids = PROF_KNOWLEDGE[skillLine]
                if ids then
                    local okT, infoT = pcall(C_CurrencyInfo.GetCurrencyInfo, ids.total)
                    if okT and infoT then
                        knowledgeTotal = infoT.quantity or 0
                    end
                    local okW, infoW = pcall(C_CurrencyInfo.GetCurrencyInfo, ids.weekly)
                    if okW and infoW then
                        knowledgeWeekMax = infoW.maxQuantity or 0
                        knowledgeEarned  = math.max(0, knowledgeWeekMax - (infoW.quantity or 0))
                    end
                end
            end

            table.insert(char.professions, {
                name             = name,
                rank             = rank             or 0,
                maxRank          = maxRank          or 0,
                skillLine        = skillLine,
                isSecondary      = isSecondary,
                knowledgeTotal   = knowledgeTotal,
                knowledgeEarned  = knowledgeEarned,
                knowledgeWeekMax = knowledgeWeekMax,
            })
        end
    end

    -- ── 3f. Currencies: Dundun + Manaflux (alleen opslaan voor Registry) ─
    char.currencies = char.currencies or {}
    local okD, infoD = pcall(C_CurrencyInfo.GetCurrencyInfo, DUNDUN_ID)
    if okD and infoD then char.currencies[DUNDUN_ID] = infoD.quantity or 0 end
    local okM, infoM = pcall(C_CurrencyInfo.GetCurrencyInfo, MANAFLUX_ID)
    if okM and infoM then char.currencies[MANAFLUX_ID] = infoM.quantity or 0 end
end

local function ScanDelayed()
    C_Timer.After(0.75, ScanAll)
end

LockoutScanner:RegisterEvent("PLAYER_ENTERING_WORLD")
LockoutScanner:RegisterEvent("UPDATE_INSTANCE_INFO")
LockoutScanner:RegisterEvent("CHALLENGE_MODE_COMPLETED")
LockoutScanner:RegisterEvent("CHALLENGE_MODE_RESET")
LockoutScanner:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
LockoutScanner:SetScript("OnEvent", ScanDelayed)

-- =====================================================
-- 4. TOOLTIP MODULE
-- =====================================================

table.insert(DT_TooltipModules, function(data, charKey)

    -- ── 4a. Mythic+ ──────────────────────────────────────────────────────
    Divider()
    GameTooltip:AddLine("|cff3399ff|TInterface\\Icons\\Achievement_Dungeon_GloryoftheRaider:14:14:0:0|t  Mythic+|r")

    if data.mythicKey then
        local kc = KeyColor(data.mythicKey.level)
        GameTooltip:AddDoubleLine(
            "  Keystone:",
            string.format("%s+%d|r  |cffdddddd%s|r", kc, data.mythicKey.level, data.mythicKey.mapName),
            1,1,1, 1,1,1)
    else
        GameTooltip:AddDoubleLine("  Keystone:", "|cffaaaaaa-- no key --|r", 1,1,1, 1,1,1)
    end

    if data.mythicBest and data.mythicBest.level > 0 then
        local bc = KeyColor(data.mythicBest.level)
        GameTooltip:AddDoubleLine(
            "  Highest:",
            string.format("%s+%d|r  |cffdddddd%s|r", bc, data.mythicBest.level, data.mythicBest.mapName),
            1,1,1, 1,1,1)
    else
        GameTooltip:AddDoubleLine("  Highest:", "|cffaaaaaa-- no run --|r", 1,1,1, 1,1,1)
    end

    if data.rioScore and data.rioScore > 0 then
        local sc
        if     data.rioScore >= 2000 then sc = "|cffffff00"
        elseif data.rioScore >= 1500 then sc = "|cff00ff00"
        elseif data.rioScore >= 1000 then sc = "|cff00ccff"
        else                              sc = "|cffaaaaaa" end
        GameTooltip:AddDoubleLine("  Rio Score:",
            string.format("%s%.0f|r", sc, data.rioScore), 1,1,1, 1,1,1)
    end

    -- ── 4b. Raid Lockouts ────────────────────────────────────────────────
    Divider()
    GameTooltip:AddLine("|cffccaa00|TInterface\\Icons\\Achievement_Raid_NaxxramasWing:14:14:0:0|t  Raid Lockouts|r")

    local lockouts = data.lockouts
    if lockouts and #lockouts > 0 then
        for _, l in ipairs(lockouts) do
            local allDead   = l.numEncounters > 0 and (l.encounterProgress >= l.numEncounters)
            local bossColor = allDead and "|cff00ff00" or "|cffff6644"
            local extStr    = l.extended and " |cff00ccff[Ext]|r" or ""
            local nameStr   = string.format("  |cffdddddd%s|r |cffaaaaaa[%s]|r%s",
                l.name, l.diff, extStr)
            local bossStr   = string.format("%s%d/%d|r",
                bossColor, l.encounterProgress, l.numEncounters)
            GameTooltip:AddDoubleLine(nameStr, bossStr, 1,1,1, 1,1,1)
        end
    else
        GameTooltip:AddLine("  |cffaaaaaa-- no active lockouts --|r")
    end

    -- ── 4c. Professions ─────────────────────────────────────────────────────
    local profs = data.professions
    if profs and #profs > 0 then
        local primary   = {}
        local secondary = {}
        for _, p in ipairs(profs) do
            if p.isSecondary then table.insert(secondary, p)
            else                  table.insert(primary, p) end
        end

        if #primary > 0 then
            Divider()
            GameTooltip:AddLine("|cffa335ee|TInterface\\Icons\\Trade_BlackSmithing:14:14:0:0|t  Professions  |cffaaaaaa(Midnight)|r|r")
            for _, p in ipairs(primary) do
                local rc      = RankColor(p.rank, p.maxRank)
                local nameStr = string.format("  |cffdddddd%s|r", p.name)
                local rankStr = p.maxRank > 0
                    and string.format("%s%d|r|cffaaaaaa/%d|r", rc, p.rank, p.maxRank)
                    or  string.format("|cffaaaaaa%d|r", p.rank)
                GameTooltip:AddDoubleLine(nameStr, rankStr, 1,1,1, 1,1,1)

                if p.knowledgeTotal ~= nil or p.knowledgeEarned ~= nil then
                    local leftStr, rightStr = "", ""
                    if p.knowledgeTotal ~= nil then
                        leftStr = string.format("    |cffaaaaaaKnowledge:|r  |cff00ccff%d|r", p.knowledgeTotal)
                    end
                    if p.knowledgeEarned ~= nil and p.knowledgeWeekMax and p.knowledgeWeekMax > 0 then
                        local wc = WeeklyColor(p.knowledgeEarned, p.knowledgeWeekMax)
                        rightStr = string.format("week %s%d/%d|r", wc, p.knowledgeEarned, p.knowledgeWeekMax)
                    end
                    if leftStr ~= "" or rightStr ~= "" then
                        GameTooltip:AddDoubleLine(leftStr, rightStr, 1,1,1, 1,1,1)
                    end
                end
            end
        end

        if #secondary > 0 then
            Divider()
            GameTooltip:AddLine("|cffddaa44|TInterface\\Icons\\INV_Misc_Food_15:14:14:0:0|t  Secondary|r")
            for _, p in ipairs(secondary) do
                local rc      = RankColor(p.rank, p.maxRank)
                local nameStr = string.format("  |cffdddddd%s|r", p.name)
                local rankStr = p.maxRank > 0
                    and string.format("%s%d|r|cffaaaaaa/%d|r", rc, p.rank, p.maxRank)
                    or  string.format("|cffaaaaaa%d|r", p.rank)
                GameTooltip:AddDoubleLine(nameStr, rankStr, 1,1,1, 1,1,1)
            end
        end
    end

    -- Dundun and Manaflux are shown by Registry.lua, not here

end)

-- =====================================================
-- 5. SLASH COMMANDS
-- =====================================================

SLASH_DTLOCKOUT1 = "/dtlockout"
SlashCmdList["DTLOCKOUT"] = function()
    ScanAll()
    local charKey = (UnitName("player") or "Unknown") .. "-" .. (GetNormalizedRealmName() or GetRealmName() or "Unknown")
    local char    = DelveTrackerDB and DelveTrackerDB.characters
                    and DelveTrackerDB.characters[charKey]
    if not char then
        print("|cffa335ee[DT Lockout]|r No character data found.")
        return
    end
    local numLock  = char.lockouts and #char.lockouts or 0
    local keyStr   = char.mythicKey
        and string.format("+%d %s", char.mythicKey.level, char.mythicKey.mapName)
        or "no key"
    local bestStr  = (char.mythicBest and char.mythicBest.level > 0)
        and string.format("+%d %s", char.mythicBest.level, char.mythicBest.mapName)
        or "no run"
    local cTab     = char.currencies or {}
    local dundun   = cTab[DUNDUN_ID]   or 0
    local manaflux = cTab[MANAFLUX_ID] or 0
    print(string.format(
        "|cffa335ee[DT Lockout]|r %d lockout(s)  |  Key: %s  |  Best: %s  |  Dundun: %d  |  Manaflux: %d",
        numLock, keyStr, bestStr, dundun, manaflux))
end

SLASH_DTPROF1 = "/dtprof"
SlashCmdList["DTPROF"] = function()
    print("|cffa335ee[DT Prof]|r Professions of |cffdddddd" .. UnitName("player") .. "|r:")
    local p1, p2, p3, p4, p5, p6 = GetProfessions()
    local profSlots = {}
    if p1 then table.insert(profSlots, p1) end
    if p2 then table.insert(profSlots, p2) end
    if p3 then table.insert(profSlots, p3) end
    if p4 then table.insert(profSlots, p4) end
    if p5 then table.insert(profSlots, p5) end
    if p6 then table.insert(profSlots, p6) end
    for _, idx in ipairs(profSlots) do
        local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(idx)
        if name then
            local filtered = FILTER_PROFS[skillLine] and "|cffff0000[gefilterd]|r" or ""
            local sec      = SECONDARY[skillLine]    and "|cffaaaaaa[secondary]|r" or ""
            local known    = PROF_KNOWLEDGE[skillLine]
                and "|cff00ff00[knowledge actief]|r"
                or  (SECONDARY[skillLine] or FILTER_PROFS[skillLine])
                    and "" or "|cffff4444[voeg toe aan PROF_KNOWLEDGE]|r"
            print(string.format(
                "  |cffdddddd%s|r  skillLine=|cffffff00%d|r  rank=%d/%d  %s%s%s",
                name, skillLine or 0, rank or 0, maxRank or 0, filtered, sec, known))
        end
    end
    local okD, infoD = pcall(C_CurrencyInfo.GetCurrencyInfo, DUNDUN_ID)
    local okM, infoM = pcall(C_CurrencyInfo.GetCurrencyInfo, MANAFLUX_ID)
    if okD and infoD then
        print(string.format("|cffa335ee[DT Prof]|r Shard of Dundun (3376):    |cff00ccff%d|r", infoD.quantity or 0))
    end
    if okM and infoM then
        print(string.format("|cffa335ee[DT Prof]|r Dawnlight Manaflux (3378): |cff00ccff%d|r", infoM.quantity or 0))
    end
end