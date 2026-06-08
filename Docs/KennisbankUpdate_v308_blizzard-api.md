# Blizzard API Reference — Midnight 12.0.5 (geverifieerd)

## Prey Hunt API

```lua
-- Actieve prey quest
C_QuestLog.GetActivePreyQuest()                  -- → questID of nil

-- Afstand
C_QuestLog.GetDistanceSqToQuest(questID)         -- → number (yards²) of nil

-- Waypoints — ALTIJD multi-map proben!
C_QuestLog.GetNextWaypoint(questID)              -- → (mapID, x, y) — geeft ook mapID!
C_QuestLog.GetNextWaypointForMap(questID, mapID) -- → (x, y) per map of nil

-- Kaart & positie
C_Map.GetBestMapForUnit("player")                -- → mapID
C_Map.GetPlayerMapPosition(mapID, "player")      -- → {x, y} of nil
C_Map.GetMapInfo(mapID)                          -- → {name, parentMapID, ...}
C_Map.GetMapChildrenInfo(parentMapID)            -- → array van child map info
C_Map.GetMapWorldSize(mapID)                     -- → (width, height) in yards
C_Map.GetWorldPosFromMapPos(mapID, vector2D)     -- → (wx, wy) continent world-space

-- Spelerrichting
GetPlayerFacing()                                -- → float 0-2π (0=Noord, CCW)

-- SuperTrack (extra waypoint bron)
C_SuperTrack.GetSuperTrackedQuestID()            -- → questID of nil
C_SuperTrack.SetSuperTrackedQuestID(id)          -- → void
C_SuperTrack.GetNextWaypointForMap(mapID)        -- → (x, y) of nil

-- World quest locatie
C_TaskQuest.GetQuestLocation(questID, mapID)     -- → (x, y) of nil

-- Quest POIs op kaart
C_QuestLog.GetQuestsOnMap(mapID)                 -- → array van {questID, x, y}

-- Quest metadata
C_QuestLog.GetTitleForQuestID(questID)           -- → string of nil
C_QuestLog.GetQuestTagInfo(questID)              -- → {tagName, ...} of nil
C_QuestLog.IsWorldQuest(questID)                 -- → boolean
C_QuestLog.AddQuestWatch(questID)                -- → void
C_QuestLog.AddWorldQuestWatch(questID, type)     -- → void
```

## Widget API (ProgressState)

```lua
-- progressState: 0=Cold, 1=Warm, 2=Hot, 3=Final
-- Blizzard geeft ALLEEN stage-transities, GEEN echte percentages

local ok, setID = pcall(C_UIWidgetManager.GetPowerBarWidgetSetID)
local ok2, widgets = pcall(C_UIWidgetManager.GetAllWidgetsBySetID, setID)
local PREY_TYPE = Enum.UIWidgetVisualizationType.PreyHuntProgress
for _, info in ipairs(widgets) do
    if info.widgetType == PREY_TYPE then widgetID = info.widgetID end
end
local ok3, wi = pcall(
    C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo, widgetID)

-- CORRECT shownState check:
local WIDGET_SHOWN = 1  -- Enum.WidgetShownState.Shown
if wi.shownState == WIDGET_SHOWN then  -- NIET ~= 0
    local ps = wi.progressState  -- 0/1/2/3
end
```

## Vignette API

```lua
C_VignetteInfo.GetVignettes()                    -- → array van GUIDs
C_VignetteInfo.GetVignetteInfo(guid)             -- → {vignetteID, name, ...}
C_VignetteInfo.GetVignettePosition(guid, mapID)  -- → {x, y} of nil (preferred!)

-- Prey vignette IDs:
VIGNETTE_TRAP    = 7667   -- disarmable trap (atlas: "Vehicle-Trap-Gold")
VIGNETTE_ANGUISH = 7443   -- Coalesced Anguish mob (atlas: "poi-prey")
```

## Aura API

```lua
C_UnitAuras.GetPlayerAuraBySpellID(spellID)      -- → auraData of nil
-- Gebruik via pcall:
local ok, a = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
local hasAura = ok and a ~= nil
```

## Tooltip API (Midnight 12.x)

```lua
-- VERBODEN (verwijderd in 12.x):
-- frame:HookScript("OnTooltipSetItem", ...)

-- CORRECT:
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    -- tooltip verwerking hier
end)
```

## UI Events (Prey-relevant)

| Event                    | Gebruik                                        |
|--------------------------|------------------------------------------------|
| `PLAYER_LOGIN`           | Initialisatie, eerste check                    |
| `PLAYER_ENTERING_WORLD`  | Na laadscherm, herinitialisatie                |
| `ZONE_CHANGED_NEW_AREA`  | Mapwisseling → clear caches, herinitialiseer   |
| `QUEST_LOG_UPDATE`       | Prey quest gewijzigd                           |
| `QUEST_ACCEPTED`         | Contract geaccepteerd                          |
| `QUEST_TURNED_IN`        | Hunt voltooid → reset state (check arg1!)      |
| `QUEST_REMOVED`          | Hunt abandoned → reset state (check arg1!)     |
| `SUPER_TRACKING_CHANGED` | Nieuwe waypoint bron                           |
| `UPDATE_UI_WIDGET`       | ProgressState gewijzigd                        |
| `UPDATE_ALL_UI_WIDGETS`  | Bulk widget update                             |
| `VIGNETTE_MINIMAP_UPDATED`| Nieuwe trap/anguish vignette                  |
| `UNIT_AURA`              | Affix detectie (check: arg1 == "player")       |
| `PLAYER_REGEN_DISABLED`  | Combat fade activeren                          |
| `PLAYER_REGEN_ENABLED`   | Combat fade deactiveren                        |

## Cross-Zone Coördinaten (V3.6 fix)

```lua
-- FOUT (V3.5 en eerder): FracToYards cross-zone subtractie
-- Elke map heeft lokale oorsprong (0,0) → dx/dy was garbage cross-zone

-- CORRECT (V3.6): continent world-space via GetWorldPosFromMapPos
local function GetWorldPos(mapID, fx, fy)
    if C_Map.GetWorldPosFromMapPos then
        local vec = CreateVector2D and CreateVector2D(fx, fy)
        if vec then
            local ok, wx, wy = pcall(C_Map.GetWorldPosFromMapPos, mapID, vec)
            if ok and wx and wy then return wx, wy end
        end
    end
    -- Fallback: FracToYards (correct als pMapID == tMapID)
    local w, h = C_Map.GetMapWorldSize(mapID)
    if not w then return nil, nil end
    return fx*w, fy*h
end
-- Gebruik GetWorldPos voor BEIDE punten → correcte cross-zone delta
```

## Verboden API's (12.0.5)

```lua
-- VERWIJDERD / GEWIJZIGD in Midnight:
OptionsSliderTemplate     -- verwijderd → stille crash hele bestand
Fonts\FRIZQT__.TTF        -- verwijderd → gebruik Fonts\2002.ttf
UIDropDownMenu_*          -- legacy → MenuUtil.CreateContextMenu()
EasyMenu()                -- legacy → MenuUtil
getglobal("naam")         -- legacy → _G["naam"]
GetAddOnMemoryUsage()     -- niet beschikbaar zonder wrapper
GetCurrencyInfo(id)       -- → C_CurrencyInfo.GetCurrencyInfo(id)
GetSpellInfo(id)          -- → C_Spell.GetSpellInfo(id)
CastSpellByName()         -- vereist SecureActionButton wrapper
OnTooltipSetItem          -- verwijderd → TooltipDataProcessor
frame:OnUpdate(...)       -- polling → C_Timer.NewTicker(interval, fn)
StaticPopup .editBox      -- lowercase → .EditBox (PascalCase in 12.x)
```

---

## Race & Gender API (geverifieerd 2026-06-08)

### UnitRace()
```lua
local displayName, raceTag = UnitRace("player")
-- displayName: "Blood Elf", "Zandalari Troll" (met spaties, voor UI)
-- raceTag:     "BloodElf", "ZandalariTroll"   (CamelCase, voor atlas lookup)
-- ALTIJD raceTag gebruiken voor atlas namen
```

### UnitSex()
```lua
local gender = UnitSex("player")
-- 1 = unknown/neutral
-- 2 = male
-- 3 = female
-- OPSLAAN ALS GETAL, niet als string
-- Vergelijking: (gender == 3) and "female" or "male"
```

### C_Texture.GetAtlasInfo() — Validatie voor SetAtlas
```lua
-- ALTIJD valideren voor SetAtlas aanroep
if C_Texture and C_Texture.GetAtlasInfo then
    if C_Texture.GetAtlasInfo(atlasName) then
        texture:SetAtlas(atlasName)
        return true
    end
end
-- Geen validatie = stille mislukking (lege texture, geen error)
```

### Race Icon Atlas Namen (12.0.5 geverifieerd)
```
Formaat: raceicon128-{shortName}-{gender}
         raceicon-{shortName}-{gender}     (fallback 64px)

Correcte shortNames:
  human, orc, dwarf, nightelf, scourge (NIET undead!),
  tauren, gnome, troll, bloodelf, draenei, goblin, worgen,
  pandaren, nightborne, highmountain (NIET highmountaintauren!),
  voidelf, lightforged, zandalari (NIET zandalaritroll!),
  kultiran, darkirondwarf, magharorc, mechagnome, vulpera,
  dracthyr, earthen

Haranir/Harronir: gebruik AlliedRace-Crest-Haranir (geen raceicon128 in 12.0.5)
```

### Settings API (12.x admin panels)
```lua
-- Registreer addon settings panel
local panel = CreateFrame("Frame", "MyAddonOptions")
panel.name = "MyAddon"
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

-- Open programmatisch
Settings.OpenToCategory(category:GetID())

-- NOOIT: InterfaceOptionsFrame_OpenToCategory() → verwijderd in 12.x
-- NOOIT: OptionsSliderTemplate → stille crash in 12.x
```
