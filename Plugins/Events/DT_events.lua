-- ============================================================================
-- DelveTracker - Pure Standalone Event Tracker (Locaties, Timers & Filters)
-- ============================================================================
local addonName, addonTable = ...

addonTable.DT_events = {}

-- 1. Gebruikersinstellingen (Koppel dit in je core add-on aan je SavedVariables)
addonTable.DT_events.Settings = {
    expansions = {
        Midnight = true,
        TWW = true,
        DF = true,
    },
    events = {
        TheaterTroupe = true,
        AwakeningMachine = true,
        StormarionAssault = true,
        BigDig = true,
    }
}

-- 2. De schone Database met alle events en hun expansie-stempel
local EventDatabase = {
    -- Midnight Expansie
    StormarionAssault = {
        name = "Stormarion Assault",
        expansion = "Midnight",
        interval = 10800,      -- Elke 3 uur
        duration = 1800,       -- Duurt 30 minuten
        startTimestamp = 1735686000,
        mapID = 2300,          -- Midnight Zone
    },
    
    -- The War Within (TWW) Expansie
    TheaterTroupe = {
        name = "Theater Troupe",
        expansion = "TWW",
        interval = 3600,       -- Elk uur
        duration = 900,        -- Duurt 15 minuten
        startTimestamp = 1724784000, 
        mapID = 2248,          -- Isle of Dorn
    },
    AwakeningMachine = {
        name = "Awakening the Machine",
        expansion = "TWW",
        interval = 7200,       -- Elke 2 uur
        duration = 1200,       -- Duurt 20 minuten
        startTimestamp = 1724787600,
        mapID = 2214,          -- The Ringing Deeps
    },
    
    -- Dragonflight (DF) Expansie
    BigDig = {
        name = "The Big Dig",
        expansion = "DF",
        interval = 3600,       -- Elk uur
        duration = 900,        -- Duurt 15 minuten
        startTimestamp = 1701826200,
        mapID = 2024,          -- Azure Span
    }
}

-- 3. Core Logica om de status te berekenen
function addonTable.DT_events:GetStatus(eventKey)
    local data = EventDatabase[eventKey]
    if not data then return nil end

    -- Controleer of de expansie óf het specifieke event is uitgevinkt
    local settings = addonTable.DT_events.Settings
    if not settings.expansions[data.expansion] or not settings.events[eventKey] then
        return nil -- Geef niks terug als het gefilterd is
    end

    local serverTime = GetServerTime()
    local timePassed = serverTime - data.startTimestamp
    local currentPeriod = timePassed % data.interval

    local mapInfo = C_Map.GetMapInfo(data.mapID)
    local zoneName = mapInfo and mapInfo.name or "Unknown Zone"

    local status = {
        name = data.name,
        expansion = data.expansion,
        location = zoneName,
        isActive = false,
        timeRemaining = 0
    }

    if currentPeriod < data.duration then
        status.isActive = true
        status.timeRemaining = data.duration - currentPeriod
    else
        status.isActive = false
        status.timeRemaining = data.interval - currentPeriod
    end

    return status
end

-- 4. Functie om ALLE actieve (niet-gefilterde) events op te halen voor je UI
function addonTable.DT_events:GetVisibleEvents()
    local visibleEvents = {}
    for key, _ in pairs(EventDatabase) do
        local status = self:GetStatus(key)
        if status then
            visibleEvents[key] = status
        end
    end
    return visibleEvents
end
-- ============================================================================
-- ABUNDANCE SCANNER v2.0 — geverifieerde API (2026-06-07)
-- Bronnen: warcraft.wiki.gg, EverythingDelves (Wheelbarrel00), Waxus tracker
-- ============================================================================
-- HOE HET WERKT:
-- Abundance roteert elke 8 uur over 4 caves (één per Midnight zone)
-- API flow:
--   1. C_AreaPoiInfo.GetDelvesForMap(mapID) → delve POI IDs
--   2. C_AreaPoiInfo.GetAreaPOIInfo([mapID], poiID) → info incl atlasName
--   3. C_AreaPoiInfo.GetAreaPOISecondsLeft(poiID) → exacte timer in seconden
--   4. C_AreaPoiInfo.IsAreaPOITimed(poiID) → is het getimed (Abundant Harvest)?
-- Abundant Harvest = atlasName:find("abundance") = ACTIEVE cave met Dundun vendor
-- Shard of Dundun (ID 3376) = vereiste key voor Abundant Harvest
-- ============================================================================

local DT_AbundanceData = {
    active       = false,   -- is er een Abundant Harvest actief?
    zone         = nil,     -- naam van de actieve zone/delve
    atlas        = nil,     -- atlasName van de actieve POI
    secondsLeft  = 0,       -- exacte seconden over (via GetAreaPOISecondsLeft)
    poiID        = nil,     -- actieve POI ID
    mapID        = nil,     -- map waarop gescand is
    shards       = 0,       -- Shard of Dundun beschikbaar
    lastScan     = 0,
}

local ABUNDANCE_MAPS = {2393, 2395, 2437, 2405, 2413, 2444}  -- alle Midnight mapIDs

local function IsAbundancePOI(info)
    if not info then return false end
    local atlas = (info.atlasName or ""):lower()
    local name  = (info.name      or ""):lower()
    local desc  = (info.description or ""):lower()
    return atlas:find("abundance") or name:find("abundance") or desc:find("abundant")
end

local function ScanAbundanceOnMap(mapID)
    if not (mapID and C_AreaPoiInfo) then return end

    -- Primair: GetDelvesForMap voor delve-specifieke POIs
    local poiIDs = nil
    if C_AreaPoiInfo.GetDelvesForMap then
        poiIDs = C_AreaPoiInfo.GetDelvesForMap(mapID)
    end
    -- Fallback: alle area POIs
    if not poiIDs or #poiIDs == 0 then
        poiIDs = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
    end
    if not poiIDs then return end

    for _,poiID in ipairs(poiIDs) do
        -- GetAreaPOIInfo accepteert optioneel mapID als eerste arg
        local info
        if C_AreaPoiInfo.GetAreaPOIInfo then
            local ok, result = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
            if not ok or not result then
                ok, result = pcall(C_AreaPoiInfo.GetAreaPOIInfo, poiID)
            end
            info = result
        end

        if info and IsAbundancePOI(info) then
            -- Haal exacte timer op
            local secsLeft = 0
            if C_AreaPoiInfo.GetAreaPOISecondsLeft then
                local ok2, secs = pcall(C_AreaPoiInfo.GetAreaPOISecondsLeft, poiID)
                if ok2 and secs and secs > 0 then secsLeft = secs end
            elseif info.timeRemaining then
                secsLeft = info.timeRemaining
            end

            -- Check of het getimed is (= Abundant Harvest, niet gewone abundance)
            local isTimed = false
            if C_AreaPoiInfo.IsAreaPOITimed then
                local ok3, timed = pcall(C_AreaPoiInfo.IsAreaPOITimed, poiID)
                if ok3 then isTimed = timed end
            end

            DT_AbundanceData.active      = true
            DT_AbundanceData.zone        = info.name or "?"
            DT_AbundanceData.atlas       = info.atlasName or ""
            DT_AbundanceData.secondsLeft = secsLeft
            DT_AbundanceData.poiID       = poiID
            DT_AbundanceData.mapID       = mapID
            DT_AbundanceData.isTimed     = isTimed
            DT_AbundanceData.lastScan    = GetTime()

            -- Shard of Dundun count (ID 3376)
            if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                local cok, cinfo = pcall(C_CurrencyInfo.GetCurrencyInfo, 3376)
                if cok and cinfo then DT_AbundanceData.shards = cinfo.quantity or 0 end
            end
            return  -- eerste abundance gevonden — stop
        end
    end
    -- Niets gevonden op deze map
    DT_AbundanceData.active = false
end

local function ScanAllMidnightMaps()
    DT_AbundanceData.active = false
    -- Scan eerst huidige map
    local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if currentMap then ScanAbundanceOnMap(currentMap) end
    if DT_AbundanceData.active then return end
    -- Dan alle andere Midnight maps
    for _,mapID in ipairs(ABUNDANCE_MAPS) do
        if mapID ~= currentMap then
            ScanAbundanceOnMap(mapID)
            if DT_AbundanceData.active then return end
        end
    end
end

local _abFrame = CreateFrame("Frame")
_abFrame:RegisterEvent("AREA_POIS_UPDATED")
_abFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
_abFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
_abFrame:SetScript("OnEvent", function(self, event)
    -- Throttle: max 1x per 30 sec
    if GetTime() - DT_AbundanceData.lastScan < 30 and event ~= "PLAYER_ENTERING_WORLD" then return end
    ScanAllMidnightMaps()
end)

-- Public API
function DT_GetAbundanceData()
    return DT_AbundanceData
end

function DT_FormatAbundanceTime(seconds)
    if not seconds or seconds <= 0 then return "?" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if h > 0 then return string.format("%dh %dm", h, m)
    else return string.format("%dm", m) end
end

-- Initiële scan na 4 seconden (DB moet geladen zijn)
C_Timer.After(4.0, ScanAllMidnightMaps)

-- ============================================================================
-- KENNISBANK REFERENTIE (data-grinder archief voor oudedoos)
-- ============================================================================
-- CLASS ICONS (12.x):
--   Texture: "Interface\\WorldStateFrame\Icons-Classes"
--   Coords via: CLASS_ICON_TCOORDS["DEATHKNIGHT"] etc.
-- SPEC ICONS:
--   GetSpecializationInfoByID(specID) → id,name,desc,iconID,role
-- RACE ICONS:
--   "Interface\\Icons\Achievement_Character_{race}_{faction}"
-- ABUNDANCE POI:
--   C_AreaPoiInfo.GetAreaPOIForMap(mapID) → {poiID,...}
--   C_AreaPoiInfo.GetAreaPOIInfo(poiID) → {atlasName,description,timeRemaining,...}
--   Chip vendor: POI atlas "delve-abundance" of description:find("abundance")
-- CURRENCY IDs (geverifieerd Midnight):
--   3028 = Restored Coffer Keys
--   3310 = Coffer Key Shards
--   3376 = Shard of Dundun (Abundance beloning)
--   3378 = Dawnlight Manaflux
-- ============================================================================