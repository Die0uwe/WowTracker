# WowTracker — CHANGELOG

Alle noemenswaardige wijzigingen worden hier gedocumenteerd.
Format gebaseerd op [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased] — WowTracker v1.0.0
### Gepland
- Centrale Plugin Bus (EventBus)
- Unified Shell UI (CurseBot-stijl sidebar)
- Plugin Control Panel
- WowTrackerDB v1 met migratie-runner
- Plugin Manifest API

---

## [0.9.x] — DelveTracker Slayer Alliance Edition
### Stabiel (per 2026-06-05)
- `DelveTracker.lua` v16.9 / v2.6.1 — Core stabiel, MenuUtil correct
- `DT_preytracker.lua` V3.5 — 3-tier kompas, affix detectie, 50FPS ticker
- `DT_prey_ui.lua` V4 — Settings panel, calibratie slider, kompas HUD
- `DT_Registry.lua` v8.1 — XL 1320×750 frame, currency scanner
- `DT_Lockout.lua` v1.9 — Weekly lockout stabiel
- Alle overige DT_ plugins — actief en functioneel

### Technische Mijlpalen
- Kompasformule `math.atan2(dx, -dy)` in-game gevalideerd
- `OptionsSliderTemplate` verwijderd (silent crash fix)
- `Fonts\FRIZQT__.TTF` vervangen door `Fonts\2002.ttf`
- MenuUtil.CreateContextMenu() geïmplementeerd (vervangt UIDropDownMenu)

---

*Auteur: DieOuwe · Slayer Alliance · Sporeggar-EU*
