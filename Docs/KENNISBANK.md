# WowTracker Kennisbank — v3.0.8
> Volledig archief van geverifieerde feiten, bugs, lessen en beslissingen
> Bijgewerkt: 2026-06-08

---

---
name: wow-oudedoos
description: >
  De Oude Doos — Centrale Kennisbank voor Project WowTracker (Retail 12.0.5 Midnight).
  Bevat het COMPLETE archief van geverifieerde feiten, API-data, mapIDs, questIDs,
  spellIDs, bronlinks, debugging-lessen, en historische beslissingen voor WowTracker
  en alle sub-plugins. Bijgewerkt t/m v3.0.8 (2026-06-08).

  Gebruik ALTIJD deze skill ALS EERSTE STAP bij: mapID opzoeken, questID valideren,
  spellID controleren, currency ID checken, zone coördinaten opzoeken, API-gedrag
  verifiëren, bekende bugs checken, NPC database raadplegen, prey data opzoeken,
  zone routing valideren, Midnight content data, addon bronnen checken,
  "wat was ook alweer X", "klopt deze ID", "welke mapID is Y", "bestaat API Z nog",
  "wat hebben we eerder geleerd over X", historische sessie-lessen raadplegen.

  Alle andere WoW skills raadplegen deze skill EERST voordat ze zelf onderzoek doen.
  Goedkoper, sneller, en betrouwbaarder dan opnieuw zoeken.
---

# De Oude Doos — WowTracker Centrale Kennisbank
## Versie: v3.0.8 · Bijgewerkt: 2026-06-08

## Gebruik

Dit is het **totaalarchief** van alles wat het team heeft geleerd, geverifieerd,
gedebugd en besloten tijdens de ontwikkeling van Project WowTracker.

**Elke skill leest dit EERST.** Alleen als het antwoord hier niet staat, ga je
elders zoeken (web, wowhead, github).

### Hoe te navigeren

| Vraag | Lees |
|---|---|
| Map/zone IDs, portalen, routing | `references/maps-and-zones.md` |
| Quest IDs, NPC database, prey data | `references/prey-database.md` |
| Spell IDs, aura's, affix data | `references/spells-and-auras.md` |
| Currency IDs, reward systemen | `references/currencies-and-rewards.md` |
| Blizzard API calls, events, gedrag | `references/blizzard-api.md` |
| Bekende bugs, fouten, regressions | `references/known-bugs.md` |
| Kompas wiskunde, hoekberekening | `references/compass-math.md` |
| Addon bronnen, referentie addons | `references/addon-sources.md` |
| Historische sessie-beslissingen | `references/session-history.md` |

---

## Kritieke Harde Regels (altijd van kracht)

```
VERBODEN in Midnight 12.0.5:
  OptionsSliderTemplate   → stille crash, blokkeert hele bestand
  Fonts\FRIZQT__.TTF      → bestaat niet meer → gebruik Fonts\2002.ttf
  UIDropDownMenu_* / EasyMenu → MenuUtil.CreateContextMenu()
  getglobal()             → _G["naam"]
  OnTooltipSetItem        → TooltipDataProcessor.AddTooltipPostCall
  GetCurrencyInfo(id)     → C_CurrencyInfo.GetCurrencyInfo(id)
  GetSpellInfo(id)        → C_Spell.GetSpellInfo(id)
  OnUpdate polling        → C_Timer.NewTicker(interval, fn)
  InterfaceOptionsFrame_OpenToCategory → Settings.OpenToCategory()
  SetAtlas() zonder validatie → altijd C_Texture.GetAtlasInfo() eerst

ALTIJD VERPLICHT:
  local addonName, addonTable = ...   bovenaan elk bestand
  frame:SetClampedToScreen(true)      alle verplaatsbare frames
  InCombatLockdown() guard            alle drag/move functies
  C_Timer.NewTicker(0.02, ...)        50 FPS animaties
  C_Map.GetWorldPosFromMapPos()       cross-zone coördinaten
  pcall() om alle C_* calls           crash-safe API aanroepen
```

---

## Race Icon Systeem (KRITIEK — geverifieerd v3.0.8)

```lua
-- UnitRace() geeft TWO returns:
local displayName, raceTag = UnitRace("player")
-- raceTag = "BloodElf", "ZandalariTroll", "Scourge" (CamelCase, geen spaties)

-- Gender ALTIJD als getal:
d.gender = UnitSex("player")  -- 2=male, 3=female

-- SetAtlas ALTIJD valideren:
local atlas = "raceicon128-"..shortName.."-"..gStr
if C_Texture.GetAtlasInfo(atlas) then texture:SetAtlas(atlas) end

-- BEKENDE UITZONDERINGEN:
["Scourge"] = "scourge"        -- Undead/Forsaken (NIET "undead")
["HighmountainTauren"] = "highmountain"  -- (NIET "highmountaintauren")
["ZandalariTroll"] = "zandalari"         -- (NIET "zandalaritroll")
["Haranir"] = "AlliedRace-Crest-Haranir" -- geen raceicon128 in 12.0.5
```

---

## Kompas Formule (HEILIG — nooit wijzigen)

```lua
local angle = math.atan2(dx, -dy)           -- dx = tx-px, dy = ty-py
local relative = angle - GetPlayerFacing()
relative = relative % (math.pi * 2)
needle:SetRotation(-relative + needleOffset)
```

Compass_Arrow.tga moet punt OMHOOG (North) hebben.

---

## Slayer Alliance Visuele Identiteit

| Element | Waarde |
|---|---|
| Primair neon | `\|cffa335ee` (Paars) |
| Secundair neon | `\|cff00ccff` (Blauw) |
| Gold accent | `\|cffccaa00` |
| Font | `Fonts\\2002.ttf` + `OUTLINE` |
| Media pad | `Interface\\AddOns\\WowTracker\\Media\\` |
| Addon map | `WowTracker` (NIET DelveTracker) |
| SavedVariables | `DelveTrackerDB` (→ WowTrackerDB bij v4.0) |
| Frame strata | `MEDIUM` (HUD) / `HIGH` (Registry) |

---

## WowTracker Bestandsstructuur (v3.0.8)

```
WowTracker/
  Core/WowTracker.lua       (2482 regels — main UI + 6 tabs)
  Plugins/
    Charmory/               3D armory popup
    ClothCounter/           Stof tracker warband-breed
    CombatAnnouncer/        Combat tekst
    ContentManager/         Content kalender
    CustomAFK/              AFK scherm
    Debugger/               In-game log + DB viewer
    Events/                 World events + Abundance scanner
    Exchangebot/            Currency exchange
    HelpGuide/              Help scherm
    Lockout/                Raid/dungeon lockouts
    MailAttach/             Mail attachment helper
    Media/                  Zone media manager
    Overlay/                UI overlay
    PreyTracker/            Prey Hunt kompas HUD
    QuickSet/               Bounty delve tracker
    Registry/               XL karakter index (1320×750)
    SkinNRare/              Skin & rare tracker
    SystemTools/            Memory + reload tools
    TooltipExtra/           Extra tooltip info
    UserInfo/               Karakter info (3448 regels)
  Media/
    Banners/, Headers/, Icons/, Avatars/
    MijnIcoon.tga, MijnIcoon2.tga, kelsey.tga
    Dieouwe.tga, UCdieouwe.tga, AMT.tga
    Compass_Arrow.tga, Background_Ring.tga
    Shield.tga, Smoke_BG.tga
  WowTracker.toc, WowTracker.xml
```


---

# Bekende Bugs (excerpts)

# Bekende Bugs, Fouten & Regressions — DelveTracker

## KRITIEKE Stille Crashes (12.0.5)

### OptionsSliderTemplate
```
BUG:    Gebruik van OptionsSliderTemplate in CreateFrame()
EFFECT: Stille Lua crash — het HELE bestand laadt niet
        Slash commands werken niet, tickers starten niet, geen error output
FIX:    Handmatige Slider met SetThumbTexture:
        local sl = CreateFrame("Slider", nil, parent)
        sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
GEVONDEN: V1/V2 DT_prey_ui.lua — veroorzaakte volledige UI-blackout
```

### Fonts\FRIZQT__.TTF
```
BUG:    Font path "Fonts\\FRIZQT__.TTF" in SetFont()
EFFECT: Tekst onzichtbaar, geen Lua error output
FIX:    Gebruik altijd "Fonts\\2002.ttf"
GEVONDEN: Meerdere versies DT_prey_ui.lua
```

## Locatie & Kompas Bugs

### Cross-Zone FracToYards (V3.5 → V3.6)
```
BUG:    WorldAngle() gebruikte FracToYards subtractie cross-zone
        FracToYards(mapA) - FracToYards(mapB) = garbage
        Elke map heeft eigen lokale oorsprong (0,0)
EFFECT: Naald wees verkeerde richting bij cross-zone hunts
        Bijv. speler in Silvermoon → naald wijst willekeurig bij Voidstorm hunt
FIX:    C_Map.GetWorldPosFromMapPos() voor continent world-space coords
        Beide punten in zelfde coördinatenstelsel → correcte delta
DATUM:  Gecorrigeerd V3.6, 2026-06-02
```

### Zul'Aman mapID 2394 vs 2437 (V3.5 → V3.6)
```
BUG:    PREY_DB had mapID=2394 voor alle Zul'Aman NPCs
        GetNextWaypointForMap() geeft waypoints op 2437, niet 2394
        TryCandidate vergelijkt cand.mapID — match faalde altijd
EFFECT: Zul'Aman hunts: Tier 1 waypoints nooit gevonden
        Altijd Tier 3 (zone entry) → minder accurate richting
FIX:    PREY_DB Zul'Aman entries: mapID=2437
        2394 = outdoor fly-through zone
        2437 = echte Midnight prey combat zone
DATUM:  Gecorrigeerd V3.6, 2026-06-02
```

### POI String Matching "prey" (V3.5 → V3.6)
```
BUG:    CollectWaypointCandidates gebruikte title:find("prey")
        om world quests te identificeren als prey quests
EFFECT: Elke willekeurige quest met "prey" in naam werd als waypoint ingevoegd
        found=true → Tier 3 (zone entry) nooit bereikt
        Valse waypoints → naald wijst verkeerde richting
FIX:    questID range check: poi.questID >= 91095 and poi.questID <= 91400
DATUM:  Gecorrigeerd V3.6, 2026-06-02
```

### Zone Naam uit Player Location (V3.1 fix)
```
BUG:    prey.zoneName = C_Map.GetMapInfo(playerMapID).name
        Speler staat bij Astalor's Table in Silvermoon bij acceptatie
EFFECT: zoneName = "Silvermoon City" in plaats van "Voidstorm" etc.
FIX:    prey.zoneName = PREY_DB[questID].zone (uit contract, niet player)
DATUM:  Gecorrigeerd V3.1
```

### Widget shownState Check (V3.5 fix)
```
BUG:    if wi.shownState ~= 0 then  -- semantisch onduidelijk
CORRECT: if wi.shownState == WIDGET_SHOWN then  -- WIDGET_SHOWN = 1
         shownState=0 = geen hunt, shownState=1 = hunt actief
DATUM:  Gecorrigeerd V3.5
```

### GetActivePreyQuest() als Placeholder (vroeg V3.x)
```
BUG:    API werd ten onrechte vervangen door custom quest scanner
        omdat het als "placeholder" werd beschouwd
EFFECT: Prey detectie werkte niet in-game (productie failure)
FIX:    C_QuestLog.GetActivePreyQuest() is ECHTE Blizzard API
        Geverifieerd via WindTools/World-Quest-Tracker broncode
LES:    Nooit Blizzard API vervangen zonder verificatie
```

## Bekende Conflictpatronen

| Patroon | Oorzaak | Signaal |
|---------|---------|---------|
| Naald → verkeerde zone | FracToYards cross-zone delta fout | angleSource = "zone_entry[X]" vanuit verkeerde zone |
| Zul'Aman Tier 1 altijd nil | mapID=2394 i.p.v. 2437 | T1_waypoints=0 bij Zul'Aman hunt |
| Valse POI waypoints | string matching "prey" | POI_worldq met vreemde mapID |
| WindTools spam | Dubbele SuperTrack aanroep | Chat spam "Start tracking Prey" |
| Waypoint nil Cold/Warm | Game design (intentioneel) | progressState < 2 |
| PREY_DB miss | questID niet in tabel | dbEntry=nil, npcName="Unknown Prey" |
| Slider crash | OptionsSliderTemplate | Stille crash, geen slash commands |
| Tekst onzichtbaar | FRIZQT font | Geen error, tekst simpelweg weg |

## NPC Locatie Verificaties (specifiek)

```
Executor Kaenius = VOIDSTORM (mapID 2405) — NIET Harandar, NIET Silvermoon
                   Eerder incorrect geclassificeerd in debug sessies
```

## Plugin Versie Historie (DelveTracker Prey)

```
V1:   OptionsSliderTemplate → stille crash
V2:   Stille crash opgelost, basis kompas
V3:   Naald fix (race condition), Engels, 120px naald
V3.1: Correcte PREY_DB (91095-91269), zone uit contract niet player
V3.2: Cross-map TryCandidate (WorldAngle via FracToYards)
V3.3: Zone-center fallback Tier 3
V3.4: Volledige quest lifecycle events, affix detectie
V3.5: ZONE_ENTRY echte coördinaten, shownState fix, dual quest scan
      Silvermoon portaal-routing, worldPosCache, windTools check
V3.6: WorldAngle fix (GetWorldPosFromMapPos), Zul'Aman mapID 2437,
      POI range filter, worldPosCache clear op zone change
V4 (UI): Settings panel, scaling, ticker, badge grid, difficulty badge in ring
```

## Race Icon Bugs (v3.0.x fixes)

### Undead/Forsaken toont rode vraagteken (OPGELOST v3.0.7)
```
BUG:    RACE_ICON_MAP had ["Undead"] = "undead"
        Atlas in 12.x heet raceicon128-scourge-*, NIET raceicon128-undead-*
        UnitRace("player") geeft ("Undead", "Scourge") — tweede return is "Scourge"
EFFECT: Alle Undead/Forsaken karakters toonden rode ? in Roster
FIX:    RACE_ICON_MAP: ["Scourge"]="scourge", ["Undead"]="scourge", ["Forsaken"]="scourge"
        DT_SetRaceIcon() met C_Texture.GetAtlasInfo() validatie voor SetAtlas aanroep
GEVONDEN: v3.0.7 sessie 2026-06-08
```

### HighmountainTauren toont rode vraagteken (OPGELOST v3.0.8)
```
BUG:    RACE_ICON_MAP had ["HighmountainTauren"] = "highmountaintauren"
        Atlas heet raceicon128-highmountain-*, NIET highmountaintauren
EFFECT: Highmountain Tauren karakters toonden rode ? in Roster
FIX:    RACE_ICON_MAP: ["HighmountainTauren"] = "highmountain"
GEVONDEN: v3.0.8 sessie 2026-06-08
```

### SetAtlas zonder GetAtlasInfo validatie = stille mislukking
```
BUG:    texture:SetAtlas("atlas-naam") aanroepen zonder validatie
        Als de atlas niet bestaat: geen error, texture blijft leeg
EFFECT: Rode vraagtekens bij alle rassen zonder exacte atlas match
FIX:    Altijd valideren:
        if C_Texture.GetAtlasInfo(atlasName) then texture:SetAtlas(atlasName) end
        EXACT zoals PB Constants.lua C:SetRaceIcon() doet
BRON:   ProfessionBuddy Constants.lua v3.5.1 SetRaceIcon implementatie
```

### Gender als string vs getal mismatch
```
BUG:    d.gender opgeslagen als "male"/"female" string
        C:SetRaceIcon() vergelijking doet (gender == 3) — string geeft altijd false
EFFECT: Alle vrouwelijke karakters kregen male atlas → foute portrait
FIX:    d.gender = UnitSex("player")  -- getal: 2=male, 3=female
        DB auto-migratie bij PLAYER_LOGIN: "male"→2, "female"→3
BRON:   ProfessionBuddy Scanner.lua regel 280
```

## Addon Map Naam vs Media Paden

### DelveTracker paden na hernoemen naar WowTracker
```
BUG:    Na hernoemen addon map DelveTracker→WowTracker bleven paden fout
        Code: "Interface\AddOns\DelveTracker\Media\MijnIcoon.tga"
        Map:  Interface/AddOns/WowTracker/
EFFECT: Alle textures (murloc, kelsey, dieouwe, logo) onzichtbaar
FIX:    Alle 21 occurrences vervangen: DelveTracker\Media → WowTracker\Media
        Verificatie: grep -r "DelveTracker\\Media" → moet 0 teruggeven
DATUM:  Opgelost v3.0.x sessie 2026-06-08
```

## Admin Panel Crashes

### Admin panel veroorzaakte nil crash op ShowTab (OPGELOST v3.0.6)
```
BUG:    Admin panel code stond TUSSEN forward declares en functie definities
        WT_UpdateGuildOnline was forward declared maar nog nil
        ShowTab(1) riep WT_UpdateGuildOnline() aan → crash
ERROR:  attempt to call a nil value (L417 in geïnstalleerde file)
FIX:    Admin panel verplaatst naar NA alle WT_* functie definities
        Volgorde: forward declares → functies → admin panel → murloc → events
DATUM:  Opgelost v3.0.6 sessie 2026-06-08
```


---

# Blizzard API (excerpts)

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


---

# Sessie Geschiedenis (laatste)

# Sessie Historie & Geleerde Lessen — Project WowTracker

## 2026-06-02 — Prey Tracker V3.6 Hotfix

**Probleem:** Na herstel van NPC locaties ging het opnieuw fout — NPC's startten
in verkeerde zones.

**Root causes gevonden (BigBoss + POI Auditor):**

1. `WorldAngle()` gebruikte `FracToYards` subtractie cross-zone — elke map heeft
   eigen lokale oorsprong, dx/dy garbage cross-zone. Fix: `GetWorldPosFromMapPos()`.

2. Zul'Aman PREY_DB had `mapID=2394` maar waypoints komen op `mapID=2437` (echte
   combat zone). 2394 = outdoor fly-through zone.

3. POI world quest filter gebruikte `title:lower():find("prey")` — matcht willekeurige
   quests, injecteert valse waypoints. Fix: questID range 91095-91400.

**Lessen:**
- Cross-zone coördinaten vereisen `C_Map.GetWorldPosFromMapPos()`, nooit FracToYards subtractie
- Blizzard zonekaarten hebben elk hun eigen lokale coordinaatoorsprong
- String matching op quest titels is altijd gevaarlijk — gebruik ID ranges
- `worldPosCache` clearen bij `ZONE_CHANGED_NEW_AREA` (verouderde coords na teleport)
- DT_prey_ui.lua was CORRECT — alleen DT_preytracker.lua had de fouten

---

## 2026-05-31 — Prey Tracker V3.5 (Zone Entry & Silvermoon Routing)

**Probleem:** Kompas wees verkeerde kant op vanuit Silvermoon City.

**Lessen:**
- Silvermoon (2444, 2536) heeft eigen routing-logica: wijst naar Eversong portaalplaza
- Zul'Aman heeft GEEN portaal vanuit Silvermoon — speler moet vliegen via Eversong
- Zone naam moet altijd uit CONTRACT (PREY_DB), nooit uit `C_Map.GetMapInfo(playerMapID)`
- `widget.shownState == 1` is semantisch correcter dan `~= 0`
- Dual quest ID lagen bevestigd: contract quest ≠ prey world quest in zone

---

## 2026-05-xx — Prey Tracker V3.x Rebuild (API Verificatie)

**Probleem:** Prey detectie werkte niet in productie. `GetActivePreyQuest()` was
vervangen door custom quest scanner omdat het als "placeholder" werd beschouwd.

**Lessen:**
- `C_QuestLog.GetActivePreyQuest()` is ECHTE Blizzard API — niet vervangen!
- Verificeer altijd API's via WindTools/World-Quest-Tracker broncode
- WindTools' `PreyHunt.lua` implementeert GEEN kompas — alleen stage tracking
- Compass is custom werk zonder directe referentie-implementatie om te kopiëren
- Geverifieerd via: WindTools GitHub + World-Quest-Tracker GitHub

---

## Fundamentele Principes (uit alle sessies)

```
1. LIVE API > STATIC DATABASE altijd
   Prioriteit: Live Blizzard API > Runtime logica > Widget data > Static DB
   Static data = FALLBACK, nooit authoritatief voor locatie

2. Cross-zone coördinaten vereisen continent world-space
   GetWorldPosFromMapPos() = enige correcte methode voor cross-zone deltas
   FracToYards subtractie = alleen correct als pMapID == tMapID

3. Nooit string matching op Blizzard content
   Quest titels, NPC namen → altijd ID-based checks
   String matching = valse positieven → verkeerde data → verkeerde richting

4. Blizzard game design vs. bugs onderscheiden
   Geen waypoint bij Cold/Warm = INTENTIONEEL game design
   Niet proberen te "fixen" via workarounds — Tier 3 is de juiste aanpak

5. Zone naam uit contract, nooit uit player location
   Speler staat in Silvermoon bij acceptatie → player location = misleidend

6. Stille crashes in WoW Lua zijn de gevaarlijkste
   OptionsSliderTemplate, FRIZQT font → geen error, gewoon niets werkt
   Altijd testen met /console scriptErrors 1

7. Regressions: terug naar laatste werkende staat als baseline
   DieOuwe's voorkeur: working state herstellen > experimenteren
   Bewaar altijd backup voor grote wijzigingen

8. naaldrichting formule is heilig
   math.atan2(-dx, dy) met facingCW = TWO_PI - facingCCW
   Elke alternatieve formulering breekt de richting in-game
   In-game test = enige ground truth
```

## Technische Schulden & Openstaande Items

```
- Globale lekkages in DT_Registry.lua:
    DT_Registry_Update, DT_TooltipModules, DT_Armory_ShowCharacter
  → Moet naar addonTable namespace

- PREY_DB Zul'Aman coördinaten (zone entry) zijn benaderd, niet datamined
  → Valideren via in-game /way coördinaten

- WowTracker namespace migratie gepland:
  DelveTracker → WowTracker
  DelveTrackerDB → WowTrackerDB (via wow-db-migrator)
```

---

## Sessie 2026-06-08 — v3.0.0 t/m v3.0.8 (Grote WowTracker Rename Sessie)

### Wat is bereikt
- Volledige rename van DelveTracker → WowTracker afgerond
- 21 media paden gecorrigeerd over 8 lua files
- Race icon systeem volledig herbouwd op PBRoster methode
- Admin panel hersteld uit v2.8.9 + uitgebreid met thema/taal
- Warband stats in header (totaal chars + totaal gold)
- WowTracker Community banner gepusht naar GitHub
- Currency icons 33px + muiswiel horizontaal scrollen

### Race Icon Systeem — Geleerde Lessen

**KRITIEK: UnitRace() geeft twee returns**
```lua
local displayName, raceTag = UnitRace("player")
-- displayName = "Blood Elf" (met spaties)
-- raceTag     = "BloodElf"  (CamelCase, geen spaties) ← GEBRUIK DIT
```

**KRITIEK: Undead atlas heet "scourge" niet "undead"**
```
UnitRace("player") op Undead/Forsaken geeft raceTag = "Scourge"
Atlas: raceicon128-scourge-male/female
NOOIT: raceicon128-undead-* want die bestaat niet
```

**KRITIEK: SetAtlas altijd valideren**
```lua
-- GOED (PB methode):
if C_Texture.GetAtlasInfo(atlasName) then
    texture:SetAtlas(atlasName)
end
-- FOUT: texture:SetAtlas(atlasName) blind aanroepen
```

**KRITIEK: Gender als getal opslaan**
```lua
-- GOED:
d.gender = UnitSex("player")  -- 2=male, 3=female
-- FOUT:
d.gender = "male"  -- string vergelijking met == 3 geeft altijd false
```

**Correcte atlas namen (geverifieerd 2026-06-08):**
```
scourge         → Undead/Forsaken (NIET "undead")
highmountain    → Highmountain Tauren (NIET "highmountaintauren")
zandalari       → Zandalari Troll
lightforged     → Lightforged Draenei
darkirondwarf   → Dark Iron Dwarf
kultiran        → Kul Tiran
magharorc       → Mag'har Orc
```

**Haranir fallback:**
```lua
DT_AlliedRaceCrest["Harronir"] = "AlliedRace-Crest-Haranir"
DT_AlliedRaceCrest["Haranir"]  = "AlliedRace-Crest-Haranir"
-- raceicon128 bestaat nog niet voor Haranir in 12.0.5
```

### Admin Panel — Volgorde Kritiek
```
CORRECT volgorde in WowTracker.lua:
  1. local vars + UI frame setup
  2. Forward declares (local WT_UpdateGuildOnline etc)
  3. Tab definities + ShowTab functie
  4. Tab content (Tab1..Tab6)
  5. WT_UpdateRoster / WT_UpdateCurrency / WT_UpdateGuildOnline DEFINITIES
  6. Admin panel (HIER, niet eerder)
  7. Murloc button
  8. Slash commands
  9. Events

FOUT: Admin panel voor de functie definities → nil crash
```

### Header Warband Stats
```lua
-- UpdateWarbandStats telt alle chars + gold
-- Wordt aangeroepen na elke ScanDelves()
-- Gold formatting: K/M suffix voor leesbaarheid
-- Aangemaakt als addonTable.UpdateWarbandStats
```

### ProfessionBuddy Referentie Bestanden (geanalyseerd)
```
PBRoster.lua    → SetRaceIcon aanroep + kaartje layout
Constants.lua   → C:SetRaceIcon() implementatie (3-staps fallback)
Scanner.lua     → d.gender = UnitSex(), d.race = select(2,UnitRace())
```

### Commits deze sessie
```
v3.0.0  Race icon SetAtlas PBRoster methode
v3.0.1  DT_SetRaceIcon exact Constants.lua v3.5.1
v3.0.2  DB cleanup lege entries
v3.0.3  Gender als getal exact PB Scanner
v3.0.4  DB auto-migratie gender+race bij login
v3.0.5  Admin panel terug via Settings API
v3.0.6  Admin panel na functie definities (nil crash fix)
v3.0.7  Undead icon fix + volledig admin panel
v3.0.8  Header warband stats + thema/taal admin + HighmountainTauren fix
```


---

## Midnight 12.0.5 Protected/Removed APIs (sessie 2026-06-12)

### GuildRoster() EN C_GuildInfo.GuildRoster() — BEIDE weg/onbetrouwbaar
```
BUG:    GuildRoster() = nil (verwijderd); C_GuildInfo.GuildRoster() gaf ook nil-call
FIX:    WT_RequestGuildRoster() safe wrapper met type()=="function" checks
        GUILD_ROSTER_UPDATE vuurt sowieso periodiek — request is best-effort
```

### GetGuildRosterMOTD() is PROTECTED (ADDON_ACTION_BLOCKED + taint)
```
BUG:    Directe call → ADDON_ACTION_BLOCKED, Lua Taint: WowTracker
FIX:    GUILD_MOTD event levert motd als payload → cache → WT_GetMOTD()
        Eventueel C_GuildInfo.GetGuildRosterMOTD() met type-check (niet protected)
```

### Frames zijn Lua tables — Hide-loop valkuil
```
BUG:    type(row)=="table" matcht óók op Button frames → pairs() itereert
        frame-internals (functions zoals OnBackdropLoaded) → index crash
FIX:    Test EERST type(row.Hide)=="function" (= frame), dán pas table-iteratie
```

### Hardcoded "DelveTracker" ADDON_LOADED checks (map heet WowTracker)
```
BUG:    DT_ClothCounter: local ADDON_NAME="DelveTracker" → InitDB nooit gedraaid
        DT_userinfo regel 3380: arg1=="DelveTracker" → init nooit
        DT_Debugger: GetAddOnMemoryUsage("DelveTracker") → altijd 0.0 KB
FIX:    local ADDON_NAME = ... (vararg = echte mapnaam) of beide namen accepteren
```

### Scan-regel herbevestigd: UnitRace tweede return
```
BUG:    Core regel 1793: d.race = UnitRace("player") — EERSTE return (localized)
FIX:    local _, raceTag = UnitRace("player"); d.race = raceTag
        d.sex = UnitSex("player") (getal) + d.gender alias
        DT_SetRaceIcon() herbouwd in Core (was verloren bij ZIP-sync 9738d33)
```

### Debugger v3.0 — BugSack-stijl error capture
```
NIEUW:  seterrorhandler chain vangt ALLE Lua errors: msg + debugstack(4) +
        debuglocals(4) + dedup teller. Export = error rapport + debug log.
        Chained met bestaande handler (!BugGrabber blijft werken).
```

## Currency IDs — DataStore geverifieerd (sessie 2026-06-12)
```
BRON:   DataStore_Currencies Enum.lua (changelog t/m 12.0)
FOUT WAS: 2803 stond als Resonance Crystals → is Undercoin
          2815 stond als Valorstones → is Resonance Crystals (Valorstones=3008)
          Harbinger Crests 2778-2781 → correct: 2914-2917
          Dragon Isles Supplies 2245 → correct: 2003 (2245=Flightstones)
KEY IDS:  Valorstones=3008 · Undercoin=2803 · ResonanceCrystals=2815
          Harbinger Crests W/C/R/G = 2914/2915/2916/2917
          Undermine Crests = 3107-3110 · Ethereal Crests = 3284/3286/3288/3290
          Flightstones=2245 · Honor=1792 · Conquest=1602 · TimewarpedBadge=1166
```

## Race Atlas — extra uitzonderingen (sessie 2026-06-12)
```
LightforgedDraenei → "lightforged"  (NIET lightforgeddraenei)
DarkIronDwarf      → "darkiron"     (NIET darkirondwarf)
MagharOrc          → "maghar"       (NIET magharorc)
PATROON: allied races strippen vaak het basis-ras suffix uit de atlas naam.
DT_SetRaceIcon probeert nu kandidaten: map → raw lowercase → suffix-gestript,
elk gevalideerd met C_Texture.GetAtlasInfo, voor raceicon128- én raceicon-.
```

## Debugger log overlap (OPGELOST v3.0.1)
```
BUG:    Lange log regels wrapten over volgende regel heen → onleesbaar
FIX:    SetWordWrap(false) + SetHeight(LOG_LINE_H) + SetNonSpaceWrap(false)
        op elke log FontString — 1 entry = exact 1 regel
```

---

## Race Atlas — DEFINITIEF (Constants.lua v3.5.1, TextureAtlasViewer-geverifieerd)
```
BRON: ProfessionBuddy Constants.lua + PBRoster.lua (geüpload 2026-06-12)
LET OP — eerdere aannames GECORRIGEERD:
  DarkIronDwarf = "darkirondwarf"  ✓ MET dwarf-suffix (NIET "darkiron")
  MagharOrc     = "magharorc"      ✓ MET orc-suffix  (NIET "maghar")
  LightforgedDraenei = "lightforged"  ✓ ZONDER draenei-suffix
  → suffix-strip is GEEN betrouwbaar patroon; gebruik de expliciete tabel!
MIDNIGHT: UnitRace 2e return = "Harronir" (DUBBELE r!) · raceID=86
  raceicon128-harronir bestaat NIET → fallback AlliedRace-Crest-Haranir
EARTHEN: "Earthen" én "EarthenDwarf" (DB dump variant) → beide "earthen"
KETEN: raceicon128-* → raceicon-* → AlliedRace-Crest-* → SetTexture(134400)
GENDER: (gender==3) and "female" or "male" — getal uit UnitSex()
Dynamische fallback gsub: [%s'%-]+ (spaties, apostrofes, koppeltekens)
WoW Lua heeft GEEN :trim() methode — crasht met attempt to call nil!
```

## DataStore_Agenda — bruikbare APIs (data-grinder analyse 2026-06-12)
```
KALENDER (voor DT_events guild events!):
  C_DateAndTime.GetCurrentCalendarTime() → {month, year, monthDay, ...}
  C_Calendar.SetAbsMonth(month, year)    → VERPLICHT vóór elke scan (op login!)
  C_Calendar.GetMonthInfo(offset)        → {month, year, numDays}
  C_Calendar.GetNumDayEvents(monthOffset, day)
  C_Calendar.GetDayEvent(monthOffset, day, i) → info:
    .calendarType  "GUILD_EVENT"/"GUILD_ANNOUNCEMENT"/"PLAYER"/"HOLIDAY"/
                   "RAID_LOCKOUT"/"RAID_RESET" (kan nil zijn — filteren!)
    .title .eventType .inviteStatus .startTime.hour/.minute
VALKUILEN:
  - Blizzard_Calendar is LoD — functies geven nil zonder geladen kalender
  - CALENDAR_UPDATE_EVENT_LIST: tijdens eigen scan UNregisteren
    (SetAbsMonth triggert het event → infinite loop)
WEEKLY RESET (Cleanup.lua patroon — voor delves weekly!):
  GetCVar("portal") → regio · EU=woensdag(3), US=dinsdag(2), CN/KR/TW=do(4)
  Reset uur ~6:00 · datum-vergelijking via "%Y-%m-%d" strings
LOCKOUTS (voor DT_Lockout):
  GetNumSavedInstances() + GetSavedInstanceInfo(i) → reset>0 filteren
  RAID_INSTANCE_WELCOME → RequestRaidInfo() · UPDATE_INSTANCE_INFO → scan
SERVER TIJD: GetGameTime() per-seconde pollen tot minuut wisselt →
  exacte client-server gap via difftime (ItemCooldowns.lua patroon)
```

## Currency tab v3.0.9d (sessie 2026-06-12)
```
ICONS: 22px (2x kleiner), tile 48x46
BLANCO FIX: getCurInfo eist info.name~="" EN iconFileID>0, anders wordt
  de currency volledig overgeslagen (bestaat niet op deze client).
  Midnight IDs 3399/3403/3390 waren ongeverifieerd → filteren zichzelf nu.
TAAL: langBtn past WT_ApplyLanguage DIRECT toe (geen reload) + ✓ markering
THEME: Register callback kleurt nu ook tabBtns live mee
DB-MIGRATIE HERBOUWD (was verloren): gender string→getal,
  race spaties strippen op PLAYER_LOGIN
```

## Admin Panel herbouwd — v3.1.0 (sessie 2026-06-12, Fase 1 punt 1)
```
LOCATIE: Core/WowTracker.lua, NA alle WT_* definities, VÓÓR events blok
  (kennisbank load-volgorde regel — nil-crash bij schending)
OPEN VIA: ⚙ header knop of /wtadmin
PARENT: UIParent + DIALOG strata (schaalt niet mee met HUD)
SLIDERS: 100% handmatig (track frame + thumb texture + cursor drag,
  GetCursorPosition()/GetEffectiveScale(), stappen 0.05) —
  OptionsSliderTemplate blijft VERBODEN in 12.x
SECTIES: UI schaal · Murloc schaal · Thema (WTTheme grid, goud=actief) ·
  Taal (5, live via WT_ApplyLanguage) · Combat alert · Plugins on/off
PLUGINS: leest DelveTracker.Plugins (gesorteerd), toggle schrijft
  PluginStates[naam] — default aan (~= false patroon)
SCOPE LES: MBtn local op regel 2078 — panel MOET daarna staan om de
  murloc-slider closure te laten werken
```

## Warband Stats Header — v3.1.1 (Fase 1.2, sessie 2026-06-12)
```
UI.warbandStats FontString rechtsboven (TOPRIGHT -14, onder knoppenrij)
WT_FmtGold: 950→"950g" · 45600→"45.6K" · 1230000→"1.23M"
WT_UpdateWarbandStats(): telt characters + sommeert money (copper/10000)
UPDATE: na ScanDelves() in PLAYER_LOGIN/PLAYER_MONEY/PLAYER_ENTERING_WORLD/
  WEEKLY_REWARDS_UPDATE — volgorde belangrijk: eerst scan, dan stats,
  anders telt het huidige karakter de OUDE money waarde
```

## Plugin registratie compleet — v3.1.2 (Fase 2.1, sessie 2026-06-12)
```
7 plugins kregen noop-registratie (Lockout patroon, append aan file-einde):
  Events · PreyTracker · ContentManager · CustomAFK · Overlay ·
  WarbankBuddy · Theme
PATROON: eventframe op PLAYER_LOGIN → UnregisterAllEvents →
  guard (DelveTracker and DelveTracker.RegisterPlugin) →
  DelveTracker:RegisterPlugin("Naam", function() end)
ui-files (events_ui, prey_ui) liften mee onder de hoofdplugin.
TOTAAL: 22 plugins zichtbaar in admin panel (was 15).
```

## Bounty subtabs — v3.1.3 (Fase 2.2, sessie 2026-06-12)
```
ROOT CAUSE LAYOUT: tiles staan in 2-koloms grid van TILE_H*1.4 (70px),
  maar drie Y-berekeningen rekenden met TILE_H (50) per tile-COUNT:
  · Nemesis ITEMS_Y → Required Items header OVERLAPTE tile bij iN=1 (11px)
  · scB/scNr SetHeight → veel te hoge scroll-gebieden (lege ruimte)
FIX: GridHeight(n) = ceil(n/2) * (floor(TILE_H*1.4) + TILE_G) — rijen!
KLEUR: Bountiful tile gekalmeerd — backdrop neutraal donker
  (0.07,0.04,0.02), border/glow zachter oranje; stripe+badge dragen
  de herkenning. Intensiteit nu gelijk aan Nemesis/Normal.
```

## Guild online lijst — v3.1.4 (Fase 2.3, sessie 2026-06-12)
```
BUG GEVONDEN: GetGuildRosterInfo 5e return = localized display naam
  ("Warrior") — matcht NIET als RAID_CLASS_COLORS key! De 11e return
  is de classFileName ("WARRIOR"). Namen vielen daardoor terug op grijs.
NIEUW: 16px icoon per online lid vóór de naam —
  · eigen warband char (match op "Naam-Realm" in characters DB):
    race-portret via DT_SetRaceIcon (hergebruik!)
  · anders: class-icoon via Icons-Classes + CLASS_ICON_TCOORDS[classFile]
  · vangnet: 134400 vraagteken
Naam schuift van x=12 naar x=30. DT_SetRaceIcon is file-level local
vóór deze functie gedefinieerd → in scope.
```

## Abundance chip op Nemesis tile — v3.1.5 (Fase 2.4, sessie 2026-06-12)
```
BADGE: t.badge (rechts op tile, bij Nemesis voorheen transparant) wordt
  groen "CHIP <shards>" als DT_GetAbundanceData().active — hergebruik
  van bestaande badge-elementen, nul nieuwe frames.
TOOLTIP: Nemesis tooltip toont nu zone + resterende tijd
  (DT_FormatAbundanceTime) + Shard of Dundun count + vendor
  "Chel the Chip" + farm route hint. Inactief: vendor-regel met notitie.
DATA: DT_GetAbundanceData (DT_events.lua) → {active, zone, secondsLeft,
  shards} — globaal, guard met "and" check (plugin kan uit staan).
```

## Roster professions — v3.1.6 (Fase 2.5, sessie 2026-06-12)
```
BESTOND AL maar met 2 bugs:
BUG 1 — LUA VALKUIL: ipairs({prof1,prof2,arch,fish,cook}) stopt bij de
  EERSTE nil. Karakter zonder primary profession verloor cooking/fishing
  in de scan. FIX: pairs over een keyed table {p1=,p2=,a=,f=,c=}.
BUG 2 — TEXTURE LEAK: elke roster-refresh maakte NIEUWE textures+buttons
  (oude alleen Hide — textures zijn niet verwijderbaar in WoW). Bij 46
  kaarten × refresh stapelden duizenden zombie-objecten op.
  FIX: vaste profPool van 4 slots per kaart, eenmalig aangemaakt,
  per refresh alleen SetTexture/Show/Hide. Tooltip via slot._prof.
LES: ipairs over een array-literal met mogelijk-nil waarden is ALTIJD
  fout — geldt overal in de codebase.
```

## UI/persistentie fixes — v3.1.7 (sessie 2026-06-12)
```
MURLOC RESET ROOT CAUSE: save via GetPoint() (anchor-afhankelijke x,y)
  maar restore via CENTER/UIParent → ANDER referentiekader → verspringen.
  FIX: save in center-relatieve UIParent-coördinaten met scale-correctie:
  x = GetCenter()*effScaleRatio - UIParent:GetCenter()
THEME RELOAD: login-restore roept nu WTTheme.SetActiveTheme(GetActive())
  aan → triggert ALLE Register-callbacks (tabs/plugins), niet alleen
  de main frame kleuren. WTTheme.bg/border zijn metatable-dynamisch ✓
HEADER: close-knop stond op +2 (BUITEN de rand) → -5 (5px marge),
  hele knoppenrij hangt aan close en schuift mee.
WARBANDSTATS: stond op knoppenrij-hoogte ACHTER de B/theme/lang knoppen
  → verplaatst naar TOPRIGHT -(TICKER_H+58), onder de knoppen.
ROSTER LEGE VAKJES: race nil/"" (char niet ingelogd sinds scan-fix)
  → CLASS-icoon fallback i.p.v. leeg/vraagteken.
WARBANK KNOP: footer, links van Debug, toggle via SlashCmdList
  ["WARBANKBUDDY"] — frame-onafhankelijk, werkt ook als plugin laat laadt.
```

## Dynamische race/class atlassen — v3.1.8 (gids DieOuwe, sessie 2026-06-12)
```
NIEUWE OFFICIËLE APIs (gids "Karaktericonen WoW 12.0.5"):
  GetRaceAtlas(clientFileString, gender, isFullBody)
    → genereert atlas naam dynamisch ("raceicon-human-male")
    → clientFileString = raceTag (2e return UnitRace), gender = "male"/"female"
    → NU STAP 0 in DT_SetRaceIcon (pcall + GetAtlasInfo validatie),
      geverifieerde tabel blijft als fallback-keten
  GetClassAtlas(classFile) → "classicon-warrior" — moderne class iconen,
    nu eerste keuze in roster class-fallback (legacy Icons-Classes erna)
  C_CreatureInfo.GetRaceInfo(raceID) / GetFactionInfo(raceID)
  UnitRace("player") → 3 RETURNS: localizedName, raceTag, raceID
    → raceID wordt nu OOK opgeslagen in de scan (d.raceID)
  C_GameData.GetPlayableRaces() BESTAAT NIET (publieke API) — niet gebruiken
  DisplayID's: ALLEEN voor DressUpModel:SetDisplayInfo, NOOIT SetTexture
RACE IDs 12.0.5: 1-11,22,24,25,26-32,34,35,36(Dracthyr),37(Haranir)
GIF-VALIDATIE: portretten, warband stats, Warbank knop, VALUTA taal — alle
  v3.1.7 fixes bevestigd werkend. "Tome"-icoon = 134400 vraagteken van
  v3.1.6; v3.1.7+ class-fallback vervangt dat.
```

## SavedVariables init-timing valkuil — v3.1.9 (sessie 2026-06-12)
```
BUG: DelveTrackerDB.tickerShow defaults op FILE-LOAD niveau gezet
  (regel 108). SavedVariables laden pas bij ADDON_LOADED — WoW vervangt
  dan de hele global. Mist de saved DB die key → nil → crash bij gebruik
  ("attempt to index upvalue 'ts'"). Zelfde patroon op regel 20-22
  (characters/PluginStates).
REGEL (herbevestigd): file-load DB-defaults zijn ALLEEN placeholder.
  Init ALTIJD óók op PLAYER_LOGIN (of nil-safe op de use-site).
FIX: ticker OnClick init nil-safe op use-site + PLAYER_LOGIN init voor
  characters / PluginStates / tickerShow.

## Race reverse-lookup migratie — v3.1.9 (gids DieOuwe §3/§4)
WT_BuildRaceData(): C_CreatureInfo.GetRaceInfo over de 25 raceIDs →
  byLocalized["NightElf"]="NightElf", byLocalized["Undead"]="Scourge",
  clientFileString uit info (Enum.Race reverse als vangnet).
MIGRATIE: oude DB localized namen → echte clientFile + raceID aangevuld.
  Repareert ALLE karakters zonder her-inloggen. Draait op PLAYER_LOGIN
  vóór de eerste roster-render.
```

## Brain-sync 2026-06-12
Volledige analyses gepusht naar Die0uwe/project-brain:
- docs/knowledge/midnight-security-model.md (secret values, pooling,
  macrotext 255, forbidden widgets, C_RestrictedActions)
- docs/knowledge/race-icons-definitief.md (geconsolideerd: Constants v3.5.x
  + 2 gidsen; GetRaceAtlas keten; C_GameData bestaat NIET)
Stappenplan: Fase 1+2 ✅ · Fase 4 (Midnight compliance) toegevoegd.

## Volledige i18n Core — v3.2.0 (Fase 3.1, sessie 2026-06-12)
```
ARCHITECTUUR: WT_LANG (5 talen × ~35 sleutels) + WT_T() + WT_SetLangTable
  staan nu BOVENAAN de file (na C_2002) zodat WT_T() overal bruikbaar is.
  WT_ApplyLanguage blijft ná tabBtns (heeft die upvalues nodig).
PATROON: statische labels → ververst door WT_ApplyLanguage;
  dynamische teksten (tooltips, menu's, status) → WT_T() op bouw-moment
  (menu's en tooltips bouwen bij elke open → automatisch juiste taal).
33 STRINGS omgezet: tabs, MOTD, guild teksten, roster/currency headers,
  ticker menu (titel+4 items+alles aan/uit), thema/taal menu titels,
  filter placeholder, Lvl, armory, tooltip "geen op dit karakter",
  schaal, warband stats, admin panel (titel/labels/sliders/AAN-UIT).
SCOPE LESSEN:
  · Lua functies zien alleen locals die VÓÓR de definitie staan —
    scaleLbl (footer, regel ~2050) onbereikbaar voor ApplyLanguage
    (regel ~750) → opgelost via UI.scaleLbl referentie.
  · Filter placeholder: tekstvergelijking vervangt door _isPlaceholder
    flag — taalwissel-proof (oude tekst matcht anders nooit meer).
  · Admin panel labels: refresh bij ToggleAdminPanel (elegant — panel
    is gesloten tijdens taalwissel).
RONDE 2 (open): plugin-strings (QuickSet tooltips, Registry, Lockout
  etc.) — zelfde patroon, per plugin.
```

## i18n Ronde 2: QuickSet — v3.2.1 (sessie 2026-06-12)
```
PATROON PLUGIN-VERTALING (template voor alle plugins):
  1. Sleutels met plugin-prefix (QS_*) toevoegen aan WT_LANG in Core
     (5 talen) — centrale tabel, geen aparte bestanden per plugin
  2. In de plugin: local function T(key) return WT_T and WT_T(key) or key end
     (guard: core laadt eerst, maar veilig bij losse load)
  3. Strings vervangen door T("KEY") — tooltips bouwen bij hover →
     automatisch actuele taal, geen refresh-code nodig
QUICKSET: 37 strings omgezet (tile types, delve tooltips, abundance blok,
  story/coffers, nemesis status, benefits, Valeera header, subtabs,
  Required Items). Eigennamen (Valeera, Chel the Chip, delve namen)
  blijven onvertaald — namen zijn geen UI-tekst.
VOLGENDE PLUGINS (zelfde patroon): Registry, Lockout, HelpGuide,
  ClothCounter, ExchangeBot, SkinNRare, MailAttach, Debugger.
```

## Armory i18n + Guild Calendar — v3.2.2 (sessie 2026-06-12)
```
ARMORY (Charmory): frame bouwt op FILE-LOAD (vóór taal-restore op login)
  → labels via I18N_LABELS registry + refresh in StatsPanel.Fill()
  (elke open = actuele taal). SecHdr/StatRow nemen nu SLEUTELS;
  onbekende sleutels ("Coffer Keys", "Threshold 4") vallen via WT_T
  transparant terug op de key zelf — eigennamen blijven ongemoeid.
GUILD CALENDAR SCANNER (Fase 3.3, DataStore_Agenda patroon):
  · C_AddOns.LoadAddOn("Blizzard_Calendar") op PLAYER_LOGIN (LoD!)
  · C_Timer.After(8) eerste scan — kalender moet initialiseren
  · SetAbsMonth vóór scan · event UNregistered tijdens scan (loop!)
  · Scant maand 0+1, filtert GUILD_EVENT/GUILD_ANNOUNCEMENT,
    alleen toekomstig, gesorteerd
  · API: DT_GetGuildEvents() → {date,time,title,eventType,inviteStatus}
  · Re-scan gedebounced (2s) op CALENDAR_UPDATE_EVENT_LIST
  VOLGENDE STAP: weergave in Events tab + ticker (UI-integratie).
```

## Guild events weergave — v3.2.3 (Fase 3.3 compleet, sessie 2026-06-12)
```
TICKER: onder ts.guild — eerstvolgende 2 events als
  [G] Titel · vandaag 20:00 / DD-MM HH:MM (GE_TODAY vertaald, 5 talen)
GUILD TAB: header "Aankomende guild events" + 4 regels onder de MOTD
  (Tab1.geHdr + geRows pool van 4 — eenmalig aangemaakt).
  WT_UpdateGuildEventsList() global — ververst bij guild-events
  in core én door de scanner zelf na elke scan (pcall guard).
KETEN: PLAYER_LOGIN → LoadAddOn(Blizzard_Calendar) → 8s delay →
  ScanGuildCalendar → WT_UpdateGuildEventsList → ticker pakt het mee
  bij eerstvolgende rebuild. GE_* sleutels in alle 5 talen.
```

## Secret values IN HET WILD — v3.2.4 (sessie 2026-06-13)
```
EERSTE ECHTE secret-value crash gevangen (3x):
  "attempt to index local 'msg' (a secret string value, while
   execution tainted by 'WowTracker')" — CHAT_MSG_LOOT payload!
BEVESTIGT het Midnight-model uit de analyse-PDF: CHAT_MSG_* payloads
  zijn secret strings op tainted paths — msg:match/gmatch crasht.
STANDAARD GUARD (verplicht in ELKE chat-event handler):
  if issecretvalue and (issecretvalue(msg) or issecretvalue(sender))
      then return end
  if type(msg) ~= "string" then return end
GEFIXT: ContentManager (loot+guild chat), ClothCounter (loot gmatch).
AUDIT-REGEL: elke nieuwe CHAT_MSG/COMBAT_LOG handler krijgt deze guard.
ARMORY i18n NALEVERING: labels verversen nu óók op Armory OnShow
  (HookScript) — Fill alleen was niet genoeg als het paneel al open
  stond of zonder her-selectie getest werd. Na taalwissel: venster
  her-openen of karakter aanklikken.
```

## Weekly reset + versie-constante — v3.2.5 (Fase 3.4 + 4.5, sessie 2026-06-13)
```
WEEKLY RESET (3.4): oude implementatie = GetServerTime()/epoch-week →
  wisselt DONDERDAG 00:00 UTC, niet de regionale reset! Nu Cleanup.lua
  patroon: GetCVar("portal") → EU=wo(3) · US=di(2) · CN/KR/TW=do(4),
  reset-uur 6:00, next-reset als "YYYY-MM-DD" in DelveTrackerDB.WeeklyReset
  {day, hour, nextReset}. Schrikkeljaar + maand/jaar-overflow afgedekt.
  Oude lastResetWeek wordt opgeruimd (nil).
VERSIE (4.5): WT_VERSION = "3.2.5" bovenin Core — header, contextmenu
  en admin panel (2 plekken) lezen hem; TOC ## Version gelijkgetrokken.
  Release-procedure: ALLEEN WT_VERSION + TOC bijwerken.
```

## charInfo + Vault knop — v3.2.6 (sessie 2026-06-13)
```
CHARINFO: stond sinds creatie permanent op "Laden..." — werd nooit
  geüpdatet. WT_UpdateCharInfo(): naam in klassekleur (classFile key!) +
  Lvl + spec (GetSpecialization/Info) + iLvl (GetAverageItemLevel,
  pcall). Draait na ScanDelves in het event-blok.
VAULT KNOP: footer, links van Warbank. Great Vault = LoD addon
  Blizzard_WeeklyRewards → C_AddOns.LoadAddOn + WeeklyRewardsFrame
  via ShowUIPanel/HideUIPanel. InCombatLockdown guard (panel-show
  in combat = taint-risico).
VERSIE-PROCEDURE WERKT: alleen WT_VERSION + TOC bump → 3.2.6.
  (Screenshot "v2.7.0" was een oude build — header toont nu live versie.)
```

## WTTheme uitrol start — v3.2.7 (Fase 3.2, sessie 2026-06-13)
```
PATROON (template voor alle plugins met eigen frame):
  if WTTheme and WTTheme.Register then
      local function ApplyXTheme()
          local bg  = WTTheme.bg and WTTheme.bg.main
          local bdr = WTTheme.border and WTTheme.border.main
          if bg then frame:SetBackdropColor(bg.r,bg.g,bg.b, max(bg.a,0.9)) end
          if bdr then frame:SetBackdropBorderColor(bdr.r,bdr.g,bdr.b, 0.7) end
      end
      WTTheme.Register(ApplyXTheme)   -- live bij themawissel
      ApplyXTheme()                   -- direct op actief thema
  end
  Hardcoded kleuren erboven BLIJVEN als startwaarde — zonder WTTheme
  verandert niets (veilig degraderen).
GEKOPPELD: Registry (DT_RegistryFrame), Charmory (DT_ArmoryFrame).
GEEN EIGEN FRAME (kleuren al mee via core PluginArea): Lockout, QuickSet.
NOG TE KOPPELEN: ClothCounter (F), Debugger, SkinNRare, ExchangeBot,
  MailAttach, HelpGuide — zelfde template, volgende ronde.
```

## WTTheme uitrol COMPLEET — v3.2.8 (Fase 3.2 ronde 2, sessie 2026-06-13)
```
ALLE plugin-popups gekoppeld (live themawissel):
  Registry · Charmory (v3.2.7) + ClothCounter (F+Archive via
  ApplyWindowStyle) · Debugger · SkinNRare · ExchangeBot · MailAttach ·
  HelpGuide (v3.2.8)
BEWUSTE UITZONDERINGEN (functionele kenmerken behouden):
  · Debugger border blijft GROEN (debug-identiteit)
  · MailAttach border blijft GOUD
  · ExchangeBot border was onzichtbaar → nu subtiel theme (0.6 alpha)
CLOTHCOUNTER PATROON: theme-lezing IN de bestaande ApplyWindowStyle
  helper (bg-fallback behouden) + één Register-callback die F én
  Archive herstylet — geen duplicatie.
FASE 3.2 = AFGEROND. Alle frames volgen het actieve thema.
```

## MOTD race-condition opgelost — v3.2.9 (sessie 2026-06-13)
```
PROBLEEM: tab open vóór GUILD_MOTD event → "Laden..." bleef hangen
  zonder herpoging (event kan uitblijven: race, addon-conflict, hik).
DRIE-LAAGS FIX:
  A) Tab-open herpogingen: C_Timer.After 1s (stille retry) + 3s
     (laatste poging, anders NO_MOTD i.p.v. eeuwig "Laden...")
  B) GUILD_ROSTER_UPDATE vult de cache OOK met tab dicht —
     MOTD staat klaar vóór de gebruiker de tab opent
  C) WT_GetMOTD: pcall om C_GuildInfo.GetGuildRosterMOTD —
     toekomstbestendig tegen protected/secret gedrag
LES: event-afhankelijke UI altijd voorzien van timeout + herpoging;
  "wachten op één event" is een single point of failure.
```

## i18n Ronde 3 compleet — v3.3.0 (sessie 2026-06-13)
```
REGISTRY: "SLAYER ALLIANCE - CHARACTER INDEX" → titel-suffix via RG_TITLE.
  "B"-knop = navigatie-symbool — bewust NIET vertaald (geen taal).
LOCKOUT: 4 strings — "Raid Lockouts", "no active lockouts",
  "Professions (Midnight)", "Secondary". Mythic+ = eigennaam onvertaald.
  Divider-lijn = decoratie onvertaald.
HELPGUIDE: titel + VOLLEDIGE body (17 sleutels: 4 sectie-headers,
  3 basic-control regels, 6 tab-beschrijvingen, 14 slash-beschrijvingen).
  Slash commands zelf (/wt, /crew, etc.) altijd EN — zijn commando's.
  OnShow-hook herbouwt de body bij elk openen → taalwissel werkt direct.
SCOPE VALKUIL (gevangen): guard T() geplaatst MID in DIFF_LABEL tabel
  → Lua parse-error "no viable alternative at input local". Guard ALTIJD
  vóór de eerste tabel-definitie in het bestand plaatsen.
I18N TOTAAL (alle rondes):
  Core: 33 strings (v3.2.0) · QuickSet: 37 (v3.2.1) · Charmory: 16 (v3.2.2)
  Registry: 1 · Lockout: 4 · HelpGuide: 18 (v3.3.0)
  TOTAAL: ~109 strings in 5 talen (NL/EN/DE/FR/ES)
```

## Fase 4.3: Midnight Security Diagnostiek in Debugger — v3.3.1 (sessie 2026-06-13)
```
NIEUWE KNOP: "Security" in de Debugger toolbar (6e knop, xOff 483)
DIAGNOSTIEK (7 checks, output in log-venster):
  1. issecretvalue/scrubsecretvalues/issecurevariable: aanwezig?
  2. C_RestrictedActions.GetAddOnRestrictionState → restriction-state
  3. C_RestrictedActions.IsAddOnRestrictionActive → JA/NEE
  4. InCombatLockdown() → combat-staat
  5. macrotext-limiet reminder (255 tekens, SecureActionButtonTemplate)
  6. IsForbidden(testFrame) → frame forbidden-status
  7. issecurevariable(DelveTrackerDB, "characters") → taint-check DB
  + C_AddOns.GetAddOnInfo reason → addon-restrict reden
ALLE calls via pcall — diagnostiek crasht nooit de Debugger zelf.
GEBRUIK: /dtdebug → Security knop → log toont Midnight-staat in groen/rood.
  Als "IsAddOnRestrictionActive = JA" verschijnt → ALERT: Blizzard beperkt
  de addon → voor actie contact BigBoss + code-architect.
```

## i18n Ronde 3 compleet — v3.3.0 (sessie 2026-06-13)
```
Registry: "CHARACTER INDEX" → T("RG_TITLE") (5 talen)
  "SLAYER ALLIANCE" = eigennaam → NIET vertaald
Lockout: Raid Lockouts · no active lockouts · Professions · Secondary
  (4 strings, 5 talen); "Mythic+" = eigennaam → NIET vertaald
HelpGuide: header "Help Guide" + volledige body (4 sectie-headers +
  6 tab-beschrijvingen + 14 slash-omschrijvingen) = 25 strings, 5 talen
  Slash commands zelf (/wt, /crew...) NIET vertaald (technische waarden)
  HookScript OnShow: body herbouwen bij elk openen → actuele taal direct
SCOPE-LES: T() guard + HookScript OnShow voor frames die op file-load
  bouwen (vóór taal-restore) — zelfde patroon als Charmory I18N_LABELS
```

## Security tab Debugger — v3.3.1 (Fase 4.3, sessie 2026-06-13)
```
/dtdebug → tab "Security": 6 secties
1. C_RestrictedActions: GetAddOnRestrictionState("WowTracker") +
   IsAddOnRestrictionActive → groen=OK, rood=restricted
2. Secret Value API: issecretvalue, scrubsecretvalues, issecurevariable,
   issecurevalue → aanwezig of niet
3. Taint Status: issecurevariable check op SlashCmdList/UIParent/
   GameTooltip/ChatFrame1 → tainted globals direct zichtbaar
4. Combat Lockdown: InCombatLockdown live waarde
5. Secure Templates: SecureActionButtonTemplate, SecureHandlerStateTemplate
6. Midnight API Check: C_RestrictedActions, MenuUtil.CreateContextMenu,
   C_AddOns.GetAddOnMemoryUsage, Settings.RegisterCanvasLayoutCategory
Alles via pcall — crash in de diagnostiek zelf onmogelijk.
```

## CreateFramePool uitrol — v3.3.2 (Fase 4.1, sessie 2026-06-13)
```
POOLS: 5 pools (Blizzard-patroon: één pool per widget-type, eenmalig
  aangemaakt via InitPools op PLAYER_LOGIN):
  · rosterCardPool    (Button + BackdropTemplate — roster kaartjes)
  · currNameRowPool   (Frame — karakter-header rijen)
  · currTilePool      (Button — currency tiles)
  · currScrollPool    (ScrollFrame — horizontale scroll per karakter)
  · currArrowPool     (Button — pijl-knoppen)
ReleaseAll() i.p.v. verberg-loops + wipe + nil → geen garbage,
  geen GC-spike, hergebruik van bestaande widget-objecten.
PATROON: SetBackdrop 1x bewaard via card.backdrop_set flag —
  niet elke refresh herhalen (nul overhead).
HSCROLL: hContent als sub-frame op de ScrollFrame (1x aangemaken,
  hergebruikt via hScroll.hContent), SetParent van tiles op hContent
  bij elke acquire.
```

## Fase 4.2 COMBAT_LOG secret-audit — v3.3.4 (sessie 2026-06-13)
```
VOLLEDIGE AUDIT RESULTATEN (alle plugins + Core):
  COMBAT_LOG_EVENT_UNFILTERED: NIET gebruikt in WowTracker — veilig
  CombatAnnouncer: alleen PLAYER_REGEN_DISABLED/ENABLED — geen payloads
  TooltipExtra: geen combat events — veilig
  WarbankBuddy: geen combat events — veilig
  ExchangeBot: Python-grep gaf false positive (CHAT_MSG = 0) — veilig

UNIT_AURA (RISICO: LAAG — unitID is normaal geen secret):
  · SkinNRare: issecretvalue guard + type check toegevoegd
  · PreyTracker: issecretvalue guard + type check toegevoegd
  REDEN: defensief consistent beleid — toekomstige Blizzard-wijzigingen
  kunnen unitID wel secret maken op bepaalde paths.

CHAT_MSG (reeds gefixt v3.2.4):
  · ContentManager: ✓ guard
  · ClothCounter: ✓ guard

CONCLUSIE: WowTracker gebruikt geen COMBAT_LOG_EVENT_UNFILTERED.
  Alle event-payloads beveiligd. Fase 4.2 AFGEROND.
```

## GROTE SESSIE 2026-06-13 — v3.2.0 t/m v3.5.2 (33 releases)

### i18n (Fase 3.1) COMPLEET
WT_LANG 5 talen bovenaan Core · WT_T() patroon · 5 plugins vertaald ·
I18N_LABELS registry voor frames die op file-load bouwen · HelpGuide OnShow

### WTTheme (Fase 3.2) COMPLEET
Alle popups gekoppeld · functionele borders bewaard (Debugger=groen, Mail=goud)
ClothCounter: theme-check in ApplyWindowStyle helper

### Guild Calendar (Fase 3.3) COMPLEET
LoD Blizzard_Calendar · SetAbsMonth verplicht · event UNregistered tijdens scan
DT_GetGuildEvents() API · Guild tab lijst + ticker [G]-regels · 5 talen

### Weekly Reset (Fase 3.4) COMPLEET
GetCVar("portal") regionaal · EU=wo(3) 6:00 · WeeklyReset{day,hour,nextReset}

### CreateFramePool (Fase 4.1) COMPLEET
5 pools · aparte Roster/Currency init · Show() na Acquire · child-reuse guards

### Secret Audit (Fase 4.2) COMPLEET
CHAT_MSG guards aanwezig · UNIT_AURA defensief · COMBAT_LOG niet gebruikt

### Security Debugger Tab (Fase 4.3) COMPLEET
6 secties · C_RestrictedActions niet publiek 12.x · err:0 wrn:0 bevestigd

### WT_MakeSAScrollbar (v3.4.0) COMPLEET
Centrale helper · alle 15+ scrollframes uitgerold · parent-fallback

### Roster
Klasse-sortering (CLASS_ORDER) · gecentreerd grid (visIdx) · orphan filter ·
/wt cleanup · DB-duplicate fix (spatie realm)

### Currency Tab
Volledige Midnight set · Dawncrest 5-tiers · correcte volgorde

### Overig
MOTD race-condition (timer 1s/3s + roster-trigger) · charInfo gevuld ·
Vault knop · Kelsey 66×66 · Debugger-titel live · DB Backup/Restore v3.5.x

### KRITIEKE LESSEN
```
goto/::label:: = VERBODEN in WoW Lua 5.1 → altijd if/else
Python LF in Lua string = CRASH → binary fix of handmatig escapen
Pool parent = PER TAB (niet gedeeld!)
hScroll:Show() + hContent:Show() VERPLICHT na Acquire
rows[visIdx] na for _,key (niet rows[i])
C_RestrictedActions methods zijn NIET publiek in Midnight 12.x
```

### DB Backup/Restore (v3.5.0-3.5.2)
TOC: WowTrackerDB + WowTrackerDB_Backup toegevoegd als v4.0 bridge
Admin panel: 💾 Backup + ↩ Restore knoppen · 2-staps bevestiging
Restore schrijft naar DelveTrackerDB + WowTrackerDB simultaneaously
/wt-dbbackup + /wt-dbrestore slash commands

### v4.0 status
WowTrackerDB staat klaar in TOC · backup-bridge aanwezig · 180 refs te renamen
