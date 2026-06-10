-- ============================================================================
-- DelveTracker - Prey Tracker Logic V3.5
-- Retail 12.0.5 / Build 67314 (Midnight)
-- File: Plugins/DT_preytracker.lua
-- ============================================================================
-- MULTI-SKILL CONSENSUS (wow-prey-research + learn + wow-addon-architect):
--
-- VERIFIED FACTS (cross-referenced Preydator/Preybreaker/World-Quest-Tracker):
--
--   1. Blizzard ONLY exposes 4 stage transitions (Cold/Warm/Hot/Final).
--      No real percentages - ever. progressState 0-3 is all we get.
--
--   2. GetNextWaypointForMap returns nil at Cold(0) and Warm(1).
--      This is INTENTIONAL game design - the target location is hidden.
--
--   3. widget.shownState must be checked against Enum.WidgetShownState.Shown
--      (value = 1), not just "!= 0". shownState=0 means widget hidden (no hunt).
--
--   4. TWO quest ID layers exist simultaneously:
--      a) Contract quest  (91115) = C_QuestLog.GetActivePreyQuest() result
--      b) Prey world quest in zone = detected via C_QuestLog.GetQuestsOnMap()
--      The world quest MAY have waypoints at earlier stages than the contract.
--
--   5. Affixes are detectable via C_UnitAuras (UNIT_AURA event):
--      Echo of Predation  = spellID 1245792 (Nightmare only, stalking spirit)
--      Bloody Command     = spellID 1245779 (Nightmare only, kill anything)
--      Torment            = spellID 1245570 (Hard+, stacking damage taken)
--      Seeping Gore       = spellID 1282499 (Hard+, gore puddles)
--
--   6. Ambush detection: UNIT_COMBAT + UNIT_TARGET events fire on ambush.
--      Preybreaker uses locale-independent quest/task/widget refresh signals.
--
--   7. Blood Mist trail appears after ambush. No direct API - only visual.
--      Track via progressState jump after QUEST_LOG_UPDATE post-ambush.
--
-- THREE-TIER COMPASS (unchanged, proven correct):
--   T1: Blizzard waypoint API     (works at Hot=2, Final=3)
--   T2: Distance trilateration    (in-zone, needs movement samples)
--   T3: Zone entry point          (always - Cold/Warm, cross-map)
-- ============================================================================
local addonName, addonTable = ...

local PreyFrame = CreateFrame("Frame")

local math_sqrt  = math.sqrt
local math_atan2 = math.atan2
local math_pi    = math.pi
local math_abs   = math.abs
local math_max   = math.max
local math_min   = math.min
local TWO_PI     = math_pi * 2
local GetTime    = GetTime

local C_Map_GetBestMapForUnit          = C_Map.GetBestMapForUnit
local C_Map_GetPlayerMapPosition       = C_Map.GetPlayerMapPosition
local C_Map_GetMapInfo                 = C_Map.GetMapInfo
local C_Map_GetMapWorldSize            = C_Map.GetMapWorldSize
local C_QuestLog_GetActivePreyQuest    = C_QuestLog.GetActivePreyQuest
local C_QuestLog_GetDistanceSqToQuest  = C_QuestLog.GetDistanceSqToQuest
local C_QuestLog_GetNextWaypointForMap = C_QuestLog.GetNextWaypointForMap
local C_QuestLog_GetNextWaypoint       = C_QuestLog.GetNextWaypoint
local C_QuestLog_GetTitleForQuestID    = C_QuestLog.GetTitleForQuestID
local C_QuestLog_GetQuestTagInfo       = C_QuestLog.GetQuestTagInfo
local C_QuestLog_IsWorldQuest          = C_QuestLog.IsWorldQuest
local C_QuestLog_AddQuestWatch         = C_QuestLog.AddQuestWatch
local C_QuestLog_AddWorldQuestWatch    = C_QuestLog.AddWorldQuestWatch
local C_QuestLog_GetQuestsOnMap        = C_QuestLog.GetQuestsOnMap
local C_VignetteInfo_GetVignettes      = C_VignetteInfo.GetVignettes
local C_VignetteInfo_GetVignetteInfo   = C_VignetteInfo.GetVignetteInfo
local C_VignetteInfo_GetVignettePos    = C_VignetteInfo.GetVignettePosition
local C_UnitAuras_GetAura              = C_UnitAuras.GetPlayerAuraBySpellID
local C_SuperTrack_GetQuestID          = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
local C_SuperTrack_SetQuestID          = C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID
local C_SuperTrack_GetNextWP           = C_SuperTrack and C_SuperTrack.GetNextWaypointForMap
local _GetPlayerFacing                 = GetPlayerFacing

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local VIGNETTE_TRAP    = 7667   -- disarmable trap
local VIGNETTE_ANGUISH = 7443   -- Coalesced Anguish mob

-- Affix spell IDs (verified via wowhead.com, June 2026)
local SPELL_ECHO_OF_PREDATION = 1245792  -- Nightmare: stalking spirit aura
local SPELL_BLOODY_COMMAND    = 1245779  -- Nightmare: kill anything debuff
local SPELL_TORMENT           = 1245570  -- Hard+: stacking damage taken
local SPELL_SEEPING_GORE      = 1282499  -- Hard+: gore puddles

local AUTOTRACK_CD = 3.0
-- Alle Midnight zone mapIDs (inclusief sub-zones en Silvermoon stad)
-- 2393=Eversong Woods, 2394=Zul'Aman, 2395=Eversong sub, 2405=Voidstorm Bazaar
-- 2413=Harandar, 2424=Voidstorm alt, 2437=Zul'Aman sub, 2444=Silvermoon City
-- 2536=The Bazaar / Sunfury Spire area
local MIDNIGHT_MAPS = { 2393, 2394, 2395, 2405, 2413, 2424, 2437, 2444, 2536 }

-- Silvermoon stad sub-zones (speler neemt contract hier aan bij Astalor's Table)
-- Als player in Silvermoon is, wijst Tier 3 naar de POORT/PORTAAL naar de hunt-zone
local SILVERMOON_MAPS = { [2444]=true, [2536]=true }

local DIFF_COLOR = {
    Normal    = "|cff44ff88",
    Hard      = "|cffff9900",
    Nightmare = "|cffff2200",
}
local STATE_PROGRESS = { [0]=0.05, [1]=0.35, [2]=0.70, [3]=1.0 }
local STATE_STAGE    = { [0]=1,    [1]=2,    [2]=3,    [3]=4    }

-- ============================================================================
-- ZONE ENTRY POINTS (Tier 3 fallback)
-- Real portal/hub arrival coordinates, verified via:
--   - gamerhour.net portal guide
--   - icy-veins skyriding glyph coordinates
--   - wow-professions.com profession treasure locations
-- mapIDs: 2393=Eversong, 2394=Zul'Aman, 2405=Voidstorm, 2413=Harandar
-- ============================================================================
-- ZONE ENTRY POINTS - Tier 3 kompas fallback
-- Wanneer speler buiten de hunt-zone is, wijst de naald naar het portaal/hub
-- in de hunt-zone zodat je weet WELKE KANT OP te gaan.
--
-- SILVERMOON (speler staat hier bij Astalor's Table):
--   Portalen vanuit Silvermoon gaan naar Eversong Woods -> Harandar, Voidstorm, Zul'Aman
--   Portaal coördinaten in Eversong/Silvermoon zijn bij de portal plaza
--
-- FIX v3.6: Silvermoon sub-zones (2444, 2536) krijgen eigen entries die wijzen naar
--   de portaalzone (Eversong Woods 2393) als doorgang naar de hunt-zones.
--   Dit voorkomt dat de naald direct naar Voidstorm (2405) wijst terwijl je in
--   Silvermoon staat - in plaats daarvan wijst hij naar de portaalrichting in Eversong.
local ZONE_ENTRY = {
    -- EVERSONG WOODS (hoofd-zone, portaal hub naar alle andere zones)
    [2393] = { fx=0.50, fy=0.60, name="Eversong Woods" },  -- Faro'shan / centraal hub
    [2395] = { fx=0.50, fy=0.60, name="Eversong Woods" },  -- continent sub-map alias

    -- ZUL'AMAN (fly via Eversong 2393->2394, geen portaal vanuit Silvermoon)
    [2394] = { fx=0.32, fy=0.80, name="Zul'Aman"       },  -- SW entry
    [2437] = { fx=0.32, fy=0.80, name="Zul'Aman"       },  -- continent sub-map

    -- VOIDSTORM (portaal beschikbaar vanuit Eversong portal plaza)
    [2405] = { fx=0.50, fy=0.28, name="Voidstorm"      },  -- Howling Ridge base camp
    [2424] = { fx=0.50, fy=0.28, name="Voidstorm"      },  -- Voidstorm alt map

    -- HARANDAR (portaal beschikbaar vanuit Eversong portal plaza)
    [2413] = { fx=0.50, fy=0.38, name="Harandar"       },  -- The Den hub

    -- SILVERMOON STAD SUB-ZONES (speler accepteert quest bij Astalor's Table)
    -- Als de HUNT in Eversong is -> wijst naar Eversong hub (deur van stad)
    -- Als de HUNT elders is -> ook Eversong hub, want portalen zijn in Eversong Woods
    -- We slaan Silvermoon zelf op als "wijst naar Eversong uitgang" coördinaten
    [2444] = { fx=0.55, fy=0.75, name="Eversong (portaal)" }, -- Silvermoon City -> Eversong exit
    [2536] = { fx=0.55, fy=0.75, name="Eversong (portaal)" }, -- Sunfury Spire area -> Eversong exit
}

-- PORTAAL OVERRIDE: Als speler in Silvermoon is en hunt in Voidstorm/Harandar/Zul'Aman,
-- wijst de naald naar de Eversong Woods portaalplaza (2393) als doorgang.
-- De portaalplaza in Eversong heeft de portalen naar alle Tier 3+ zones.
local PORTAL_PLAZA = { mapID=2393, fx=0.50, fy=0.45 }  -- Eversong portal plaza coördinaten
local NON_EVERSONG_HUNT = { [2394]=true, [2405]=true, [2413]=true, [2424]=true, [2437]=true }

-- ============================================================================
-- PREY NPC DATABASE - 90 quest IDs (30 NPCs x 3 difficulties)
-- Source: wowhead.com questIDs 91095-91269, verified 12.0.5.67314 (June 2026)
-- Zone from contract, NOT player location - player may be in Silvermoon
-- ============================================================================
local PREY_DB = {
    -- EVERSONG WOODS ---------------------------------------------------------
    [91095]={name="Magister Sunbreaker",        zone="Eversong Woods",mapID=2393},
    [91096]={name="Magistrix Emberlash",         zone="Eversong Woods",mapID=2393},
    [91097]={name="Senior Tinker Ozwold",        zone="Eversong Woods",mapID=2393},
    [91098]={name="L-N-0R the Recycler",         zone="Eversong Woods",mapID=2393},
    [91099]={name="Mordril Shadowfell",           zone="Eversong Woods",mapID=2393},
    [91100]={name="Deliah Gloomsong",             zone="Eversong Woods",mapID=2393},
    [91101]={name="Phaseblade Talasha",           zone="Eversong Woods",mapID=2393},
    [91102]={name="Nexus-Edge Hadim",             zone="Eversong Woods",mapID=2393},
    [91210]={name="Magister Sunbreaker",          zone="Eversong Woods",mapID=2393},
    [91211]={name="Magister Sunbreaker",          zone="Eversong Woods",mapID=2393},
    [91212]={name="Magistrix Emberlash",          zone="Eversong Woods",mapID=2393},
    [91213]={name="Magistrix Emberlash",          zone="Eversong Woods",mapID=2393},
    [91214]={name="Senior Tinker Ozwold",         zone="Eversong Woods",mapID=2393},
    [91215]={name="Senior Tinker Ozwold",         zone="Eversong Woods",mapID=2393},
    [91216]={name="L-N-0R the Recycler",          zone="Eversong Woods",mapID=2393},
    [91217]={name="L-N-0R the Recycler",          zone="Eversong Woods",mapID=2393},
    [91218]={name="Mordril Shadowfell",            zone="Eversong Woods",mapID=2393},
    [91219]={name="Mordril Shadowfell",            zone="Eversong Woods",mapID=2393},
    [91220]={name="Deliah Gloomsong",              zone="Eversong Woods",mapID=2393},
    [91221]={name="Deliah Gloomsong",              zone="Eversong Woods",mapID=2393},
    [91222]={name="Phaseblade Talasha",            zone="Eversong Woods",mapID=2393},
    [91223]={name="Phaseblade Talasha",            zone="Eversong Woods",mapID=2393},
    [91224]={name="Nexus-Edge Hadim",              zone="Eversong Woods",mapID=2393},
    [91225]={name="Nexus-Edge Hadim",              zone="Eversong Woods",mapID=2393},
    -- ZUL'AMAN ---------------------------------------------------------------
    [91103]={name="Jo'zolo the Breaker",          zone="Zul'Aman",      mapID=2394},
    [91104]={name="Zadu, Fist of Nalorakk",       zone="Zul'Aman",      mapID=2394},
    [91105]={name="The Talon of Jan'alai",         zone="Zul'Aman",      mapID=2394},
    [91106]={name="The Wing of Akil'zon",          zone="Zul'Aman",      mapID=2394},
    [91226]={name="Jo'zolo the Breaker",          zone="Zul'Aman",      mapID=2394},
    [91227]={name="Jo'zolo the Breaker",          zone="Zul'Aman",      mapID=2394},
    [91228]={name="Zadu, Fist of Nalorakk",       zone="Zul'Aman",      mapID=2394},
    [91229]={name="Zadu, Fist of Nalorakk",       zone="Zul'Aman",      mapID=2394},
    [91230]={name="The Talon of Jan'alai",         zone="Zul'Aman",      mapID=2394},
    [91231]={name="The Talon of Jan'alai",         zone="Zul'Aman",      mapID=2394},
    [91232]={name="The Wing of Akil'zon",          zone="Zul'Aman",      mapID=2394},
    [91233]={name="The Wing of Akil'zon",          zone="Zul'Aman",      mapID=2394},
    -- HARANDAR ---------------------------------------------------------------
    [91107]={name="Ranger Swiftglade",            zone="Harandar",      mapID=2413},
    [91108]={name="Lieutenant Blazewing",          zone="Harandar",      mapID=2413},
    [91109]={name="Petyoll the Razorleaf",         zone="Harandar",      mapID=2413},
    [91110]={name="Lamyne of the Undercroft",      zone="Harandar",      mapID=2413},
    [91111]={name="High Vindicator Vureem",        zone="Harandar",      mapID=2413},
    [91112]={name="Crusader Luxia Maxwell",        zone="Harandar",      mapID=2413},
    [91234]={name="Ranger Swiftglade",            zone="Harandar",      mapID=2413},
    [91235]={name="Ranger Swiftglade",            zone="Harandar",      mapID=2413},
    [91236]={name="Lieutenant Blazewing",          zone="Harandar",      mapID=2413},
    [91237]={name="Lieutenant Blazewing",          zone="Harandar",      mapID=2413},
    [91238]={name="Petyoll the Razorleaf",         zone="Harandar",      mapID=2413},
    [91239]={name="Petyoll the Razorleaf",         zone="Harandar",      mapID=2413},
    [91240]={name="Lamyne of the Undercroft",      zone="Harandar",      mapID=2413},
    [91241]={name="Lamyne of the Undercroft",      zone="Harandar",      mapID=2413},
    [91242]={name="High Vindicator Vureem",        zone="Harandar",      mapID=2413},
    [91243]={name="Crusader Luxia Maxwell",        zone="Harandar",      mapID=2413},
    [91256]={name="High Vindicator Vureem",        zone="Harandar",      mapID=2413},
    [91257]={name="Crusader Luxia Maxwell",        zone="Harandar",      mapID=2413},
    -- VOIDSTORM --------------------------------------------------------------
    [91113]={name="Praetor Singularis",           zone="Voidstorm",     mapID=2405},
    [91114]={name="Consul Nebulor",                zone="Voidstorm",     mapID=2405},
    [91115]={name="Executor Kaenius",              zone="Voidstorm",     mapID=2405},
    [91116]={name="Imperator Enigmalia",           zone="Voidstorm",     mapID=2405},
    [91117]={name="Knight-Errant Bloodshatter",    zone="Voidstorm",     mapID=2405},
    [91118]={name="Vylenna the Defector",          zone="Voidstorm",     mapID=2405},
    [91119]={name="Lost Theldrin",                 zone="Voidstorm",     mapID=2405},
    [91120]={name="Neydra the Starving",           zone="Voidstorm",     mapID=2405},
    [91121]={name="Thornspeaker Edgath",           zone="Voidstorm",     mapID=2405},
    [91122]={name="Thorn-Witch Liset",             zone="Voidstorm",     mapID=2405},
    [91123]={name="Grothoz, the Burning Shadow",   zone="Voidstorm",     mapID=2405},
    [91124]={name="Dengzag, the Darkened Blaze",   zone="Voidstorm",     mapID=2405},
    [91244]={name="Praetor Singularis",           zone="Voidstorm",     mapID=2405},
    [91245]={name="Consul Nebulor",                zone="Voidstorm",     mapID=2405},
    [91246]={name="Executor Kaenius",              zone="Voidstorm",     mapID=2405},
    [91247]={name="Imperator Enigmalia",           zone="Voidstorm",     mapID=2405},
    [91248]={name="Knight-Errant Bloodshatter",    zone="Voidstorm",     mapID=2405},
    [91249]={name="Vylenna the Defector",          zone="Voidstorm",     mapID=2405},
    [91250]={name="Lost Theldrin",                 zone="Voidstorm",     mapID=2405},
    [91251]={name="Neydra the Starving",           zone="Voidstorm",     mapID=2405},
    [91252]={name="Thornspeaker Edgath",           zone="Voidstorm",     mapID=2405},
    [91253]={name="Thorn-Witch Liset",             zone="Voidstorm",     mapID=2405},
    [91254]={name="Grothoz, the Burning Shadow",   zone="Voidstorm",     mapID=2405},
    [91255]={name="Dengzag, the Darkened Blaze",   zone="Voidstorm",     mapID=2405},
    [91258]={name="Praetor Singularis",           zone="Voidstorm",     mapID=2405},
    [91259]={name="Consul Nebulor",                zone="Voidstorm",     mapID=2405},
    [91260]={name="Executor Kaenius",              zone="Voidstorm",     mapID=2405},
    [91261]={name="Imperator Enigmalia",           zone="Voidstorm",     mapID=2405},
    [91262]={name="Knight-Errant Bloodshatter",    zone="Voidstorm",     mapID=2405},
    [91263]={name="Vylenna the Defector",          zone="Voidstorm",     mapID=2405},
    [91264]={name="Lost Theldrin",                 zone="Voidstorm",     mapID=2405},
    [91265]={name="Neydra the Starving",           zone="Voidstorm",     mapID=2405},
    [91266]={name="Thornspeaker Edgath",           zone="Voidstorm",     mapID=2405},
    [91267]={name="Thorn-Witch Liset",             zone="Voidstorm",     mapID=2405},
    [91268]={name="Grothoz, the Burning Shadow",   zone="Voidstorm",     mapID=2405},
    [91269]={name="Dengzag, the Darkened Blaze",   zone="Voidstorm",     mapID=2405},
}

-- ============================================================================
-- SHARED DATA CONTAINER
-- ============================================================================
addonTable.DT_preytracker = {
    active=false, isTesting=false, questID=nil,
    enemyName="", zoneName="", difficulty="Normal", diffColor="|cff44ff88",
    distance=0, angle=0, angleReady=false, angleSource="none",
    needleOffset=0, progressState=0, progress=0.05, stage=1,
    -- Trap/vignette
    trapMode=false, trapAngle=0, nearbyTraps=0, nearbyAnguish=0,
    -- Affix detection (new in V3.5)
    affix_echo=false, affix_bloody=false, affix_torment=false, affix_gore=false,
    preyWidgetID=nil, lastAngleTime=0,
}

-- ============================================================================
-- HELPERS
-- ============================================================================
local function NormAngle(a)
    a = a % TWO_PI; if a < 0 then a = a + TWO_PI end; return a
end

local function PosXY(pos)
    if not pos then return nil, nil end
    if pos.x and pos.y then return pos.x, pos.y end
    if pos.GetXY then return pos:GetXY() end
    return nil, nil
end

-- Compass angle from normalized delta + player CCW facing
-- dx/dy must be in the same coordinate space (either both fractions or both yards)
local function CalcAngle(dx, dy, facingCCW, offset)
    if not dx or not dy or not facingCCW then return nil end
    if dx == 0 and dy == 0 then return nil end
    -- WoW Y-axis grows downward -> negate dx in atan2 to correct east/west
    local targetCW = NormAngle(math_atan2(-dx, dy))
    local facingCW = NormAngle(TWO_PI - facingCCW)
    return NormAngle(targetCW - facingCW + (offset or 0))
end

-- ============================================================================
-- WORLD-YARD COORDINATE SYSTEM
-- All Midnight zones on same Quel'Thalas continent -> yards are comparable.
-- C_Map.GetMapWorldSize(mapID) -> (width, height) in yards.
-- Convert both player and target to yards -> cross-map direction works.
-- ============================================================================
local worldSizeCache = {}

local function GetMapSize(mapID)
    if worldSizeCache[mapID] then return worldSizeCache[mapID].w, worldSizeCache[mapID].h end
    local ok, w, h = pcall(C_Map_GetMapWorldSize, mapID)
    if ok and w and w > 0 then worldSizeCache[mapID]={w=w,h=h}; return w, h end
    return nil, nil
end

local function FracToYards(mapID, fx, fy)
    local w, h = GetMapSize(mapID)
    if not w then return nil, nil end
    return fx*w, fy*h
end

-- Cross-map angle: player on pMapID, target on tMapID
local function WorldAngle(pMapID, pFx, pFy, tMapID, tFx, tFy, facing, offset)
    local pwx, pwy = FracToYards(pMapID, pFx, pFy)
    if not pwx then return nil end
    local twx, twy = FracToYards(tMapID, tFx, tFy)
    if not twx then return nil end
    local dx, dy = twx-pwx, twy-pwy
    local d = math_sqrt(dx*dx+dy*dy)
    if d < 0.5 then return nil end
    return CalcAngle(dx/d, dy/d, facing, offset)
end

-- ============================================================================
-- TIER 1: BLIZZARD WAYPOINT CANDIDATES (Hot/Final stages)
-- ============================================================================
local function BuildMapList(currentMapID)
    local seen, list = {}, {}
    local function add(mid)
        if mid and not seen[mid] then seen[mid]=true; list[#list+1]=mid end
    end
    add(currentMapID)
    if currentMapID and C_Map_GetMapInfo then
        local ok, info = pcall(C_Map_GetMapInfo, currentMapID)
        if ok and info and info.parentMapID then
            add(info.parentMapID)
            local ok2, ch = pcall(C_Map.GetMapChildrenInfo, info.parentMapID)
            if ok2 and ch then for _, c in ipairs(ch) do add(c.mapID) end end
        end
    end
    for _, mid in ipairs(MIDNIGHT_MAPS) do add(mid) end
    return list
end

local function CollectWaypointCandidates(questID, currentMapID, superID)
    local results = {}
    local function add(mapID, x, y, src)
        if mapID and x and y and type(x)=="number" and type(y)=="number"
            and x > 0 and x < 1 and y > 0 and y < 1 then
            results[#results+1]={mapID=mapID, x=x, y=y, src=src}
            return true
        end
        return false
    end
    -- Source 1: GetNextWaypoint - returns mapID, most complete source
    if C_QuestLog_GetNextWaypoint then
        local ok, wm, wx, wy = pcall(C_QuestLog_GetNextWaypoint, questID)
        if ok then add(wm, wx, wy, "GetNextWaypoint") end
    end
    local maps = BuildMapList(currentMapID)
    for _, mapID in ipairs(maps) do
        -- Source 2: GetNextWaypointForMap (per-map probe)
        local ok, wx, wy = pcall(C_QuestLog_GetNextWaypointForMap, questID, mapID)
        if ok then add(mapID, wx, wy, "GNWFM["..mapID.."]") end
        -- Source 3: SuperTrack waypoint
        if superID == questID and C_SuperTrack_GetNextWP then
            local ok2, sx, sy = pcall(C_SuperTrack_GetNextWP, mapID)
            if ok2 then add(mapID, sx, sy, "ST["..mapID.."]") end
        end
        -- Source 4: TaskQuest location (world quest fallback)
        if C_TaskQuest and C_TaskQuest.GetQuestLocation then
            local ok3, tx, ty = pcall(C_TaskQuest.GetQuestLocation, questID, mapID)
            if ok3 then add(mapID, tx, ty, "TQ["..mapID.."]") end
        end
        -- Source 5: QuestsOnMap POI - scans for BOTH contract quest AND
        --           any prey world quest active in this zone (dual-quest-layer fix)
        if C_QuestLog_GetQuestsOnMap then
            local ok4, pois = pcall(C_QuestLog_GetQuestsOnMap, mapID)
            if ok4 and pois then
                for _, poi in ipairs(pois) do
                    -- Match contract questID directly
                    if poi.questID == questID and poi.x and poi.y then
                        add(mapID, poi.x, poi.y, "POI_contract["..mapID.."]")
                    end
                    -- Also check if it looks like a prey world quest (title check)
                    if poi.questID ~= questID and poi.x and poi.y then
                        local t = C_QuestLog_GetTitleForQuestID(poi.questID)
                        if t and t:lower():find("prey") then
                            add(mapID, poi.x, poi.y, "POI_worldq["..mapID.."]")
                        end
                    end
                end
            end
        end
    end
    return results
end

local function TryCandidate(prey, cand, pMapID, pFx, pFy, facing)
    if not pFx or not pFy then return false end
    local angle = WorldAngle(pMapID, pFx, pFy, cand.mapID, cand.x, cand.y, facing, prey.needleOffset)
    if not angle then return false end
    prey.angle=angle; prey.angleReady=true
    prey.angleSource=cand.src..(cand.mapID ~= pMapID and "[x]" or "")
    prey.lastAngleTime=GetTime()
    return true
end

-- ============================================================================
-- TIER 2: DISTANCE TRILATERATION (in-zone, needs >=3 movement samples)
-- ============================================================================
local bearQuestID, bearMapID = nil, nil
local bearSamples = {}

local function ClearBear()
    for i = #bearSamples, 1, -1 do bearSamples[i] = nil end
end

local function AddBearSample(questID, mapID, px, py, dist)
    if not questID or not mapID or not px or not dist or dist <= 0 then return end
    local w, h = GetMapSize(mapID)
    if not w then return end
    if bearQuestID ~= questID or bearMapID ~= mapID then
        bearQuestID, bearMapID = questID, mapID; ClearBear()
    end
    local wx, wy = px*w, py*h
    local now = GetTime()
    local last = bearSamples[#bearSamples]
    if last then
        local moved = math_sqrt((wx-last.x)^2+(wy-last.y)^2)
        if moved < 3 and math_abs(dist-last.d) < 1 and (now-last.t) < 1.5 then return end
    end
    bearSamples[#bearSamples+1]={x=wx,y=wy,d=dist,t=now}
    local cutoff=now-45; local i=1
    while i <= #bearSamples do
        if bearSamples[i].t < cutoff then table.remove(bearSamples,i) else i=i+1 end
    end
    while #bearSamples > 8 do table.remove(bearSamples,1) end
end

local function TryTrilateration(prey, facing)
    if #bearSamples < 3 then return false end
    local base = bearSamples[1]
    local aa,ab,bb,ac,bc,used = 0,0,0,0,0,0
    for i = 2, #bearSamples do
        local s=bearSamples[i]
        local a=2*(s.x-base.x); local b=2*(s.y-base.y)
        local c=base.d^2-s.d^2+s.x^2+s.y^2-base.x^2-base.y^2
        if math_abs(a)+math_abs(b) > 6 then
            aa=aa+a*a; ab=ab+a*b; bb=bb+b*b; ac=ac+a*c; bc=bc+b*c; used=used+1
        end
    end
    if used < 2 then return false end
    local det=aa*bb-ab*ab
    if math_abs(det) < 0.0001 then return false end
    local tx=(ac*bb-bc*ab)/det; local ty=(aa*bc-ab*ac)/det
    local cur=bearSamples[#bearSamples]
    local dx,dy=tx-cur.x, ty-cur.y
    local d=math_sqrt(dx*dx+dy*dy)
    if d < 1 or math_abs(d-cur.d) > math_max(60,cur.d*0.5) then return false end
    local angle=CalcAngle(dx/d, dy/d, facing, prey.needleOffset)
    if not angle then return false end
    prey.angle=angle; prey.angleReady=true; prey.angleSource="trilat"
    prey.lastAngleTime=GetTime(); return true
end

-- ============================================================================
-- TIER 3: ZONE ENTRY POINT (Cold/Warm - always available)
-- Uses real portal/hub arrival coordinates from ZONE_ENTRY table.
-- If already in hunt zone: keep last valid angle for 5 seconds.
-- ============================================================================
-- TIER 3: ZONE ENTRY POINT (Cold/Warm - always available)
-- FIX v3.6: Silvermoon-speler wordt nu via portaalplaza (Eversong 2393) gerouted,
-- niet direct naar de hunt-zone. Dit voorkomt verkeerde richting vanuit Silvermoon stad.
local function TryZoneEntry(prey, huntMapID, pMapID, pFx, pFy, facing)
    if huntMapID == pMapID then
        -- Al in de hunt-zone: bewaar hoek kort
        if prey.angleReady and (GetTime()-prey.lastAngleTime) <= 5.0 then
            return true
        end
        return false
    end

    -- Silvermoon check: speler in Silvermoon stad, hunt in andere zone
    -- -> Wijs naar Eversong portaalplaza als eerste stap
    if SILVERMOON_MAPS[pMapID] and NON_EVERSONG_HUNT[huntMapID] then
        if not pFx then return false end
        local angle = WorldAngle(pMapID, pFx, pFy,
            PORTAL_PLAZA.mapID, PORTAL_PLAZA.fx, PORTAL_PLAZA.fy,
            facing, prey.needleOffset)
        if not angle then return false end
        prey.angle=angle; prey.angleReady=true
        prey.angleSource="silvermoon_portal->"..tostring(huntMapID)
        prey.lastAngleTime=GetTime()
        return true
    end

    -- Silvermoon check: speler in Silvermoon, hunt IN Eversong
    -- -> Wijs naar Eversong hub (uitgang van stad)
    if SILVERMOON_MAPS[pMapID] and not NON_EVERSONG_HUNT[huntMapID] then
        if not pFx then return false end
        local entry = ZONE_ENTRY[pMapID]  -- Silvermoon exit coördinaten
        if not entry then return false end
        local angle = WorldAngle(pMapID, pFx, pFy,
            2393, entry.fx, entry.fy,
            facing, prey.needleOffset)
        if not angle then return false end
        prey.angle=angle; prey.angleReady=true
        prey.angleSource="silvermoon_exit->eversong"
        prey.lastAngleTime=GetTime()
        return true
    end

    -- Normaal geval: niet in Silvermoon, gebruik hunt-zone entry
    local entry = ZONE_ENTRY[huntMapID]
    if not entry or not pFx then return false end
    local angle = WorldAngle(pMapID, pFx, pFy, huntMapID, entry.fx, entry.fy, facing, prey.needleOffset)
    if not angle then return false end
    prey.angle=angle; prey.angleReady=true
    prey.angleSource="zone_entry["..tostring(huntMapID).."]"
    prey.lastAngleTime=GetTime()
    return true
end

-- ============================================================================
-- AFFIX DETECTION (new in V3.5)
-- Uses C_UnitAuras.GetPlayerAuraBySpellID - synchronous, no polling overhead.
-- Called once per compass tick (not every frame - already throttled by ticker).
-- ============================================================================
local function ScanAffixes(prey)
    if not C_UnitAuras_GetAura then
        prey.affix_echo=false; prey.affix_bloody=false
        prey.affix_torment=false; prey.affix_gore=false
        return
    end
    -- HARMFUL auras (debuffs on player)
    local function hasSpell(spellID)
        local ok, a = pcall(C_UnitAuras_GetAura, spellID)
        return ok and a ~= nil
    end
    prey.affix_echo    = hasSpell(SPELL_ECHO_OF_PREDATION)
    prey.affix_bloody  = hasSpell(SPELL_BLOODY_COMMAND)
    prey.affix_torment = hasSpell(SPELL_TORMENT)
    prey.affix_gore    = hasSpell(SPELL_SEEPING_GORE)
end

-- ============================================================================
-- VIGNETTE SCAN
-- ============================================================================
local function ScanVignettes(prey, mapID, px, py, facing)
    prey.nearbyTraps=0; prey.nearbyAnguish=0; prey.trapMode=false; prey.trapAngle=0
    local ok, ids = pcall(C_VignetteInfo_GetVignettes)
    if not ok or not ids then return end
    local firstTrap = nil
    for _, guid in ipairs(ids) do
        local ok2, info = pcall(C_VignetteInfo_GetVignetteInfo, guid)
        if ok2 and info then
            if info.vignetteID == VIGNETTE_TRAP then
                prey.nearbyTraps = prey.nearbyTraps + 1
                if not firstTrap and px and py and facing then
                    local tx, ty
                    if C_VignetteInfo_GetVignettePos then
                        local ok3, vp = pcall(C_VignetteInfo_GetVignettePos, guid, mapID)
                        if ok3 then tx, ty = PosXY(vp) end
                    end
                    if tx and ty then
                        firstTrap = CalcAngle(tx-px, ty-py, facing, prey.needleOffset)
                    end
                end
            elseif info.vignetteID == VIGNETTE_ANGUISH then
                prey.nearbyAnguish = prey.nearbyAnguish + 1
            end
        end
    end
    if prey.nearbyTraps > 0 and firstTrap and prey.progressState >= 1 then
        prey.trapMode=true; prey.trapAngle=firstTrap
    end
end

-- ============================================================================
-- WIDGET SCANNER
-- FIX v3.5: correct shownState check using Enum.WidgetShownState.Shown (=1)
-- Previous versions checked ~= 0 which is equivalent, but documenting intent.
-- ============================================================================
local WIDGET_SHOWN = 1  -- Enum.WidgetShownState.Shown

local function ScanWidget()
    local prey = addonTable.DT_preytracker
    if prey.preyWidgetID then return prey.preyWidgetID end
    if not C_UIWidgetManager or not C_UIWidgetManager.GetPowerBarWidgetSetID then return nil end
    local ok, setID = pcall(C_UIWidgetManager.GetPowerBarWidgetSetID)
    if not ok or not setID then return nil end
    local ok2, ws = pcall(C_UIWidgetManager.GetAllWidgetsBySetID, setID)
    if not ok2 or not ws then return nil end
    local PT = Enum.UIWidgetVisualizationType.PreyHuntProgress
    for _, info in ipairs(ws) do
        if info.widgetType == PT then prey.preyWidgetID=info.widgetID; return info.widgetID end
    end
    return nil
end

-- ============================================================================
-- AUTO-SUPERTRACK
-- ============================================================================
local lastAutoTrack = 0

-- WindTools detectie: als WindTools PreyHunt module actief is, skip onze SuperTrack
-- om spam te voorkomen (WindTools "Start tracking Prey" flood).
-- FIX v3.6: Controleer op WindTools presence via _G["WindTools"]
local function WindToolsPreyActive()
    local WT = _G["WindTools"]
    if not WT then return false end
    -- WindTools heeft een PreyHunt sub-module
    if WT.PreyHunt and WT.PreyHunt.tracking then return true end
    return false
end

local function TryAutoTrack(questID)
    if not C_SuperTrack_SetQuestID then return end
    -- Skip als WindTools al de prey supertrackt - voorkomt "Start tracking" spam
    if WindToolsPreyActive() then return end
    local now = GetTime()
    if (now-lastAutoTrack) < AUTOTRACK_CD then return end
    lastAutoTrack = now
    local cur = C_SuperTrack_GetQuestID and C_SuperTrack_GetQuestID()
    if cur == questID then return end
    pcall(function()
        if C_QuestLog_IsWorldQuest and C_QuestLog_IsWorldQuest(questID) then
            C_QuestLog_AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
        else C_QuestLog_AddQuestWatch(questID) end
        C_SuperTrack_SetQuestID(questID)
    end)
end

local function ResetPreyState()
    local prey = addonTable.DT_preytracker
    prey.active=false; prey.questID=nil; prey.distance=0
    prey.angleReady=false; prey.angleSource="none"; prey.angle=0
    prey.nearbyTraps=0; prey.nearbyAnguish=0; prey.trapMode=false
    prey.progressState=0; prey.progress=0.05; prey.stage=1
    prey.affix_echo=false; prey.affix_bloody=false
    prey.affix_torment=false; prey.affix_gore=false
    prey.preyWidgetID=nil
    ClearBear()
end

-- ============================================================================
-- MAIN UPDATE - called every ticker tick from DT_prey_ui.lua (50 FPS)
-- ============================================================================
function PreyFrame:UpdateCompass()
    local prey = addonTable.DT_preytracker
    if prey.isTesting then return end

    local ok1, questID = pcall(C_QuestLog_GetActivePreyQuest)
    if not ok1 or not questID or questID == 0 then
        ResetPreyState(); return
    end
    if prey.questID ~= questID then ClearBear(); prey.angleReady=false; prey.preyWidgetID=nil end
    prey.active=true; prey.questID=questID

    -- Name + zone from DB (zone is from CONTRACT, not current player location)
    local dbEntry = PREY_DB[questID]
    local rawTitle = C_QuestLog_GetTitleForQuestID(questID)
    if dbEntry then
        prey.enemyName=dbEntry.name; prey.zoneName=dbEntry.zone
    else
        local n=(rawTitle or "Unknown Prey")
            :gsub("%s*%(Nightmare%)%s*",""):gsub("%s*%(Hard%)%s*","")
            :gsub("%s*%(Normal%)%s*",""):gsub("^[Pp]rey:%s*","")
        prey.enemyName=n:match("^%s*(.-)%s*$") or n; prey.zoneName=""
    end

    -- Difficulty
    prey.difficulty="Normal"
    if rawTitle then
        local tl=rawTitle:lower()
        if tl:find("nightmare") then prey.difficulty="Nightmare"
        elseif tl:find("hard")  then prey.difficulty="Hard" end
    end
    if C_QuestLog_GetQuestTagInfo then
        local ok2, tag=pcall(C_QuestLog_GetQuestTagInfo, questID)
        if ok2 and tag then
            local tl=(tag.tagName or ""):lower()
            if tl:find("nightmare") then prey.difficulty="Nightmare"
            elseif tl:find("hard")  then prey.difficulty="Hard" end
        end
    end
    prey.diffColor=DIFF_COLOR[prey.difficulty] or DIFF_COLOR.Normal

    -- Progress state via widget (FIX: check shownState == WIDGET_SHOWN)
    local wID = ScanWidget()
    if wID and C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo then
        local ok3, wi = pcall(C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo, wID)
        if ok3 and wi and wi.shownState == WIDGET_SHOWN then
            local ps=wi.progressState or 0
            prey.progressState=ps; prey.progress=STATE_PROGRESS[ps] or 0.05
            prey.stage=STATE_STAGE[ps] or 1
        end
    end

    -- Distance
    local ok4, dSq = pcall(C_QuestLog_GetDistanceSqToQuest, questID)
    prey.distance = (ok4 and dSq and dSq > 0) and math_sqrt(dSq) or 0

    -- === COMPASS - THREE-TIER PRIORITY SYSTEM ===
    -- Facing read EVERY TICK -> needle rotates as player turns/walks
    local pMapID = C_Map_GetBestMapForUnit("player")
    local facing = _GetPlayerFacing()

    if pMapID and facing then
        local playerPos = C_Map_GetPlayerMapPosition(pMapID, "player")
        local px, py = PosXY(playerPos)

        TryAutoTrack(questID)
        local superID = C_SuperTrack_GetQuestID and C_SuperTrack_GetQuestID()
        local candidates = CollectWaypointCandidates(questID, pMapID, superID)

        local found = false

        -- TIER 1: Blizzard API waypoints (Hot/Final; sometimes earlier via POI)
        for _, cand in ipairs(candidates) do
            if px and TryCandidate(prey, cand, pMapID, px, py, facing) then
                found=true; break
            end
        end

        -- TIER 2: Distance trilateration (in-zone, needs movement)
        if not found and px then
            AddBearSample(questID, pMapID, px, py, prey.distance)
            if TryTrilateration(prey, facing) then found=true end
        end

        -- TIER 3: Zone entry point (Cold/Warm - always available cross-map)
        if not found then
            local huntMapID = dbEntry and dbEntry.mapID
            if huntMapID and px then
                if TryZoneEntry(prey, huntMapID, pMapID, px, py, facing) then
                    found=true
                end
            end
        end

        if not found and prey.angleReady and (GetTime()-prey.lastAngleTime) > 5.0 then
            prey.angleReady=false
        end

        -- Vignette + affix scans
        ScanVignettes(prey, pMapID, px, py, facing)
        ScanAffixes(prey)
    else
        if prey.angleReady and (GetTime()-prey.lastAngleTime) > 5.0 then
            prey.angleReady=false
        end
    end
end

-- ============================================================================
-- EVENTS - full lifecycle (added QUEST_ACCEPTED, QUEST_TURNED_IN, QUEST_REMOVED,
--          SUPER_TRACKING_CHANGED, UNIT_AURA from Preydator analysis)
-- ============================================================================
PreyFrame:RegisterEvent("PLAYER_LOGIN")
PreyFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        if addonTable.LoadNeedleOffset then addonTable.LoadNeedleOffset() end
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self:RegisterEvent("QUEST_LOG_UPDATE")
        self:RegisterEvent("QUEST_ACCEPTED")
        self:RegisterEvent("QUEST_TURNED_IN")
        self:RegisterEvent("QUEST_REMOVED")
        self:RegisterEvent("SUPER_TRACKING_CHANGED")
        self:RegisterEvent("UPDATE_UI_WIDGET")
        self:RegisterEvent("UPDATE_ALL_UI_WIDGETS")
        self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
        self:RegisterEvent("UNIT_AURA")
        C_Timer.After(2.0, function() self:UpdateCompass() end)

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        addonTable.DT_preytracker.preyWidgetID=nil; ClearBear(); self:UpdateCompass()

    elseif event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED" then
        -- Hunt complete or abandoned - if it was the active prey quest, reset
        local prey = addonTable.DT_preytracker
        if prey.questID and prey.questID == arg1 then ResetPreyState() end

    elseif event == "QUEST_ACCEPTED" or event == "SUPER_TRACKING_CHANGED" then
        self:UpdateCompass()

    elseif event == "UNIT_AURA" then
        -- Only rescan affixes when player auras change (unit = "player")
        if arg1 == "player" then
            local prey = addonTable.DT_preytracker
            if prey.active and not prey.isTesting then ScanAffixes(prey) end
        end

    elseif event == "QUEST_LOG_UPDATE" or event == "UPDATE_UI_WIDGET"
        or event == "UPDATE_ALL_UI_WIDGETS" or event == "VIGNETTE_MINIMAP_UPDATED" then
        self:UpdateCompass()
    end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================
addonTable.UpdateCompassLogic = function() PreyFrame:UpdateCompass() end

addonTable.SaveNeedleOffset = function(offset)
    addonTable.DT_preytracker.needleOffset = offset or 0
    if DelveTrackerDB then DelveTrackerDB.preyNeedleOffset = offset or 0 end
end

addonTable.LoadNeedleOffset = function()
    if DelveTrackerDB and DelveTrackerDB.preyNeedleOffset then
        addonTable.DT_preytracker.needleOffset = DelveTrackerDB.preyNeedleOffset
    end
end

addonTable.PreyDebugInfo = function()
    local prey = addonTable.DT_preytracker
    if not prey then print("|cffcc3300[Prey]|r No state."); return end
    local pMap = C_Map_GetBestMapForUnit("player")
    local facing = _GetPlayerFacing()
    local db = PREY_DB[prey.questID]
    local src = prey.angleSource or "none"
    local tier = src:find("zone_entry") and "|cffaaaaaa T3:ZoneEntry|r"
              or src:find("trilat")     and "|cffffff00 T2:Trilaterate|r"
              or src ~= "none"          and "|cff00ff88 T1:Waypoint|r"
              or "|cffff4444 NONE|r"
    print("|cff00dfff[PreyDebug v3.5]|r -------------------------")
    print(string.format(" quest=|cffff9900%s|r  name=|cffffff00%s|r",
        tostring(prey.questID), tostring(prey.enemyName)))
    print(string.format(" zone=|cff00dfff%s|r  diff=|cffff9900%s|r  ps=%d  stage=%d",
        tostring(prey.zoneName), tostring(prey.difficulty),
        prey.progressState or 0, prey.stage or 1))
    print(string.format(" playerMap=%s  huntMap=%s  dist=|cffffff00%.0f|r yd",
        tostring(pMap), tostring(db and db.mapID), prey.distance or 0))
    print(string.format(" angleReady=%s  tier=%s  angle=%.1f  facing=%.1f",
        tostring(prey.angleReady), tier,
        (prey.angle or 0)*180/math_pi, (facing or 0)*180/math_pi))
    print(string.format(" offset=%.1f  trilat_samples=%d",
        (prey.needleOffset or 0)*180/math_pi, #bearSamples))
    -- Affix status
    local affixes = {}
    if prey.affix_echo    then affixes[#affixes+1]="|cffff2200Echo|r"     end
    if prey.affix_bloody  then affixes[#affixes+1]="|cffff2200Bloody|r"   end
    if prey.affix_torment then affixes[#affixes+1]="|cffff9900Torment|r"  end
    if prey.affix_gore    then affixes[#affixes+1]="|cffff9900Gore|r"     end
    print(" affixes="..(#affixes > 0 and table.concat(affixes," ") or "|cffaaaaaa none|r"))
    -- Waypoint candidates
    if prey.questID and pMap then
        local super = C_SuperTrack_GetQuestID and C_SuperTrack_GetQuestID()
        local cands = CollectWaypointCandidates(prey.questID, pMap, super)
        print(string.format(" T1_waypoints=%d", #cands))
        for i=1, math_min(#cands,4) do
            local c=cands[i]
            print(string.format("   [%d] %s  map=%s  x=%.3f y=%.3f", i, c.src, c.mapID, c.x, c.y))
        end
        if #cands == 0 then
            local ps = prey.progressState or 0
            print(string.format("|cffff9900 T1 nil - stage=%d (%s)|r", ps,
                ps < 2 and "expected at Cold/Warm" or "UNEXPECTED"))
        end
    end
    print("|cff00dfff[PreyDebug]|r -------------------------")
end