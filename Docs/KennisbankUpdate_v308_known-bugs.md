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
