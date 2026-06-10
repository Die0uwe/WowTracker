-- ============================================================================
-- DelveTracker - Pure Standalone Event Tracker (Locaties, Timers & Filters)
-- ============================================================================
local addonName, addonTable = ...

-- WTTheme: centraal kleurensysteem (Fase 3 - T04b)
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

    -- Controleer of de expansie of het specifieke event is uitgevinkt
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
-- ABUNDANCE SCANNER v2.0 - geverifieerde API (2026-06-07)
-- Bronnen: warcraft.wiki.gg, EverythingDelves (Wheelbarrel00), Waxus tracker
-- ============================================================================
-- HOE HET WERKT:
-- Abundance roteert elke 8 uur over 4 caves (één per Midnight zone)
-- API flow:
--   1. C_AreaPoiInfo.GetDelvesForMap(mapID) -> delve POI IDs
--   2. C_AreaPoiInfo.GetAreaPOIInfo([mapID], poiID) -> info incl atlasName
--   3. C_AreaPoiInfo.GetAreaPOISecondsLeft(poiID) -> exacte timer in seconden
--   4. C_AreaPoiInfo.IsAreaPOITimed(poiID) -> is het getimed (Abundant Harvest)?
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

-- Alle Midnight mapIDs waar Abundance actief kan zijn
-- Abundance roteert elke 8 uur over 4 caves: Eversong, Zul'Aman, Harandar, Voidstorm
-- Silvermoon en Sunfury Spire zijn hubs maar kunnen ook abundance events hebben
-- S3-05: Abundance roteert ALLEEN over 4 cave locaties (geverifieerd via Wowhead)
-- Silvermoon en Sunfury Spire zijn hubs - geen abundance caves
-- Cave locaties: Watha'nan Crypts (Eversong), Loaknit Den (Zul'Aman),
--               Floaret Grotto (Harandar), Abundant Voidburrow (Voidstorm)
local ABUNDANCE_MAPS = {
    2393,  -- Eversong Woods outdoor (Watha'nan Crypts: /way 56.78 65.79)
    2395,  -- Eversong Woods alt zone
    2437,  -- Zul'Aman combat zone (Loaknit Den: /way 31.62 26.14)
    2413,  -- Harandar (Floaret Grotto: /way 66.14 61.69)
    2405,  -- Voidstorm (Abundant Voidburrow: /way 38.82 53.31)
    2394,  -- Eversong fly-through (zekerheidshalve)
    -- 2444 Silvermoon: GEEN abundance cave (enkel hub) - verwijderd
    -- 2536 Sunfury Spire: GEEN abundance cave - verwijderd
}

local function IsAbundancePOI(info)
    if not info then return false end
    local atlas = (info.atlasName or ""):lower()
    local name  = (info.name      or ""):lower()
    local desc  = (info.description or ""):lower()
    return atlas:find("abundance") or name:find("abundance") or desc:find("abundant")
end

-- ScanAbundanceOnMap: geeft true terug als gevonden, false als niet
-- Schrijft NOOIT active=false - dat doet ScanAllMidnightMaps pas na alle maps
local function ScanAbundanceOnMap(mapID)
    if not (mapID and C_AreaPoiInfo) then return false end

    -- Probeer beide API's: GetDelvesForMap is specifieker
    local poiIDs = nil
    if C_AreaPoiInfo.GetDelvesForMap then
        local ok, result = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
        if ok and result and #result > 0 then poiIDs = result end
    end
    if not poiIDs or #poiIDs == 0 then
        local ok, result = pcall(C_AreaPoiInfo.GetAreaPOIForMap, mapID)
        if ok then poiIDs = result end
    end
    if not poiIDs then return false end

    for _,poiID in ipairs(poiIDs) do
        local info
        local ok1, r1 = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
        if ok1 and r1 then info = r1
        else
            local ok2, r2 = pcall(C_AreaPoiInfo.GetAreaPOIInfo, poiID)
            if ok2 then info = r2 end
        end

        if info and IsAbundancePOI(info) then
            local secsLeft = 0
            if C_AreaPoiInfo.GetAreaPOISecondsLeft then
                local ok3, secs = pcall(C_AreaPoiInfo.GetAreaPOISecondsLeft, poiID)
                if ok3 and secs and secs > 0 then secsLeft = secs end
            end
            if secsLeft == 0 and info.timeRemaining then secsLeft = info.timeRemaining end

            local isTimed = false
            if C_AreaPoiInfo.IsAreaPOITimed then
                local ok4, timed = pcall(C_AreaPoiInfo.IsAreaPOITimed, poiID)
                if ok4 then isTimed = timed end
            end

            DT_AbundanceData.active      = true
            DT_AbundanceData.zone        = info.name or "?"
            DT_AbundanceData.atlas       = info.atlasName or ""
            DT_AbundanceData.secondsLeft = secsLeft
            DT_AbundanceData.poiID       = poiID
            DT_AbundanceData.mapID       = mapID
            DT_AbundanceData.isTimed     = isTimed
            DT_AbundanceData.lastScan    = GetTime()

            if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                local cok, cinfo = pcall(C_CurrencyInfo.GetCurrencyInfo, 3376)
                if cok and cinfo then DT_AbundanceData.shards = cinfo.quantity or 0 end
            end
            return true  -- gevonden - stop zoeken
        end
    end
    return false  -- niet gevonden op deze map, maar active NIET overschrijven
end

local function ScanAllMidnightMaps()
    -- Reset eerst
    DT_AbundanceData.active = false
    DT_AbundanceData.lastScan = GetTime()

    -- Scan huidige map eerst (snelste pad)
    local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if currentMap and ScanAbundanceOnMap(currentMap) then return end

    -- Scan alle bekende Midnight maps
    -- Abundance kan actief zijn in: Eversong, Zul'Aman, Harandar, Voidstorm, Silvermoon
    for _,mapID in ipairs(ABUNDANCE_MAPS) do
        if mapID ~= currentMap then
            if ScanAbundanceOnMap(mapID) then return end
        end
    end
    -- Geen abundance gevonden op alle maps
    DT_AbundanceData.active = false
end

local _abFrame = CreateFrame("Frame")
_abFrame:RegisterEvent("AREA_POIS_UPDATED")
_abFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
_abFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
_abFrame:RegisterEvent("WORLD_STATE_TIMER_START")  -- S3-05: ook bij timer events
_abFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")     -- fallback re-scan
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
--   GetSpecializationInfoByID(specID) -> id,name,desc,iconID,role
-- RACE ICONS:
--   "Interface\\Icons\Achievement_Character_{race}_{faction}"
-- ABUNDANCE POI:
--   C_AreaPoiInfo.GetAreaPOIForMap(mapID) -> {poiID,...}
--   C_AreaPoiInfo.GetAreaPOIInfo(poiID) -> {atlasName,description,timeRemaining,...}
--   Chip vendor: POI atlas "delve-abundance" of description:find("abundance")
-- CURRENCY IDs (geverifieerd Midnight):
--   3028 = Restored Coffer Keys
--   3310 = Coffer Key Shards
--   3376 = Shard of Dundun (Abundance beloning)
--   3378 = Dawnlight Manaflux
-- ============================================================================