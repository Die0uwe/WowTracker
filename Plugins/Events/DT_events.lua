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