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
