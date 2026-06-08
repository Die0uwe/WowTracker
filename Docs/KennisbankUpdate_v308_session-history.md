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
