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
-- ABUNDANCE INTEGRATIE — DelveAbundance module
-- Detecteert "Abundance" delve modifier + timed events via C_AreaPoiInfo
-- Gebaseerd op DelveAbundance.lua (upload van DieOuwe, 2026-06-07)
-- ============================================================================
local DT_AbundanceData = {
    active = false,
    timedEvents = {},
    lastMapID = nil,
}

local function IsAbundancePOI(info)
    if not info then return false end
    local atlas = info.atlasName and info.atlasName:lower() or ""
    local desc  = info.description and info.description:lower() or ""
    return atlas:find("abundance") ~= nil or desc:find("abundance") ~= nil
end

local function ScanAbundance(mapID)
    DT_AbundanceData.active = false
    DT_AbundanceData.timedEvents = {}
    DT_AbundanceData.lastMapID = mapID
    if not mapID or not C_AreaPoiInfo then return end
    local poiIDs = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
    if not poiIDs then return end
    for _,poiID in ipairs(poiIDs) do
        local info = C_AreaPoiInfo.GetAreaPOIInfo(poiID)
        if info and IsAbundancePOI(info) then
            DT_AbundanceData.active = true
            if info.timeRemaining and info.timeRemaining > 0 then
                table.insert(DT_AbundanceData.timedEvents, {
                    poiID=poiID, name=info.name, atlas=info.atlasName,
                    timeRemaining=info.timeRemaining, endTime=info.endTime,
                })
            end
        end
    end
end

-- Hook in op bestaande event frame van DT_events
local _abFrame = CreateFrame("Frame")
_abFrame:RegisterEvent("AREA_POIS_UPDATED")
_abFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
_abFrame:SetScript("OnEvent",function()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if mapID then ScanAbundance(mapID) end
end)

-- Public API voor andere plugins (bijv. QuickSet tile indicator)
function DT_GetAbundanceData()
    return DT_AbundanceData
end

-- Scan direct bij laden
C_Timer.After(3.0, function()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if mapID then ScanAbundance(mapID) end
end)
