# CHANGELOG — WowTracker (Slayer Alliance Edition)

## [v2.9.7] — 2026-06-08
### Fixed
- Delves kolom 2: exact zelfde structuur als kolom 1 (font, icon grootte, kleur, iLvl badge)
- Guild tab: Kelsey kleiner (140px), guildnaam groter (26pt)
- Roster: 4→3 kolommen zodat kaartjes passen binnen UI breedte
- Currency tiles kleiner (68→56px)
- Bountiful tab kleur: oranje→SA blauw

### Added
- Bounty Nemesis: Abundance info blok onder Required Items
  - Toont actieve zone, timer, Shard of Dundun count
  - Groen als actief, grijs als geen Abundant Harvest

---

## [v2.9.6] — 2026-06-08
### Changed
- Roster kaartjes: race portrait groot (52×52px) als hoofdicoon
- Spec icoon (18×18px) in rechtsonder hoek van race portrait (ProfBuddy stijl)
- Kaartje hoogte 130px voor meer ruimte

---

## [v2.9.5] — 2026-06-08
### Added
- Abundance Scanner v2.0 — correcte API geverifieerd:
  - `GetDelvesForMap()` als primaire bron
  - `GetAreaPOISecondsLeft()` voor exacte timer in seconden
  - `IsAreaPOITimed()` onderscheid Abundant Harvest vs gewone abundance
  - Scant alle 6 Midnight mapIDs
  - Throttle 30 seconden
  - `DT_FormatAbundanceTime()` helper
- Roster v2.0: race portrait + klasse + spec iconen per kaartje
- Profession iconen onderaan roster kaartjes (max 4, met tooltip)
- Volledige RACE_ICON_MAP voor alle rassen

---

## [v2.9.4] — 2026-06-08
### Fixed
- DieOuwe texture correct gespiegeld: `SetTexCoord(1,0,0,1)` (was 8-arg variant)
- Admin panel overlappende Reload/Wipe/Del knoppen verwijderd
- Delves kolom 2: delve progress en tooltips toegevoegd

---

## [v2.9.3] — 2026-06-08
### Added
- Header knoppen op één lijn: B · 🌐 · 🎨 · ⚙ · X (alle 22×22px)
- Thema selector (🎨): SA Dark / ProfBuddy Paars / MailVault Blauw / Nacht Zwart
- Taal selector (🌐): NL / EN / DE / FR / ES
- Abundance in scrollende ticker

### Fixed
- Armory standalone (/charmory): altijd gecentreerd op scherm
- Delves kolom 2: OnEnter/OnLeave/OnClick tooltips

---

## [v2.9.2] — 2026-06-08
### Fixed
- Guild tab images: Kelsey centraal, DieOuwe gespiegeld rechtsonder, logo watermark

---

## [v2.9.1] — 2026-06-08
### Fixed
- Charmory standalone: /charmory werkt weer correct
- Armory shield: BACKGROUND laag -2, achter gear/model/tekst
- Debug knop buiten interface
- Currency filter: zoekt op currency naam (niet karakter)

### Added
- Volledige currency lijst alle expansies (Midnight + War Within + DF + SL + PvP)
- Professions scan in ScanDelves(): data.professions[] in DB
- Roster kaartjes: profession iconen (max 4)

---

## [v2.9.0] — 2026-06-08 (Sprint A)
### Added
- Delves tab: 2-koloms layout
- Zoekbalk met live letter-suggesties dropdown
- Guild tab: naam/MOTD gecentreerd
- Roster: race icoon + spec icoon op kaartjes
- Header B knop: uniform uitgelijndt met tandwiel/X

---

## [v2.8.9] — 2026-06-08
### Fixed
- Admin panel: actie knoppen anchor-based (geen overlap meer)
- Stale opt.afkBtn op Y=-638 verwijderd

### Added
- Currency tab filter/zoekbalk rechtsboven (OnTextChanged)
- Currency tiles: C_CurrencyInfo live iconen, tooltip, dimmen bij 0

---

## [v2.8.8] — 2026-06-07
### Added
- Abundance integratie: DT_GetAbundanceData() public API
- GuildRoster pre-fetch bij PLAYER_LOGIN (MOTD sneller)
- Header knoppen uniform (22×22px)

### Fixed
- DT_prey_ui.lua backslash bug
- Charmory close knop werkt in Tab5

---

## [v2.8.7] — 2026-06-07
### Added
- Roster ProfessionBuddy-stijl kaartjes (4 kolommen)
- Currency grid kaarten met live iconen
- Currency filter zoekbalk
- DT_MailAttach.lua v1.0: Quick Attach bij mailbox (MAIL_SHOW)
- Footer knoppen: Cloth · Skin · Prey · Debug

### Fixed
- Armory shield: BACKGROUND laag, achter tekst
- Admin Reload/Wipe knoppen: niet meer overlappend

---

## [v2.8.x] — 2026-06-07
### Added
- Armory Tab5 embedded: model links (420px), stats rechts
- WT_UpdateCurrency hersteld
- DT_ArmoryStatsPanel: Karakter / Stats / Currencies / Delves / Goud
- ScanDelves: gear scan, specID, race, faction

---

## [v2.7.0-v2.8.0] — 2026-06-02 t/m 2026-06-06
### Initial v2.9.x series
- Core Engine met 6 tabs (Guild/Delves/Bounty/Roster/Armory/Currency)
- EventBus, Plugin Manifest API
- Prey Tracker kompas V3.x (confirmed working in-game)
- Registry XL 1320×750 frame
- Murloc minimap button met context menu

---

*Maintained by DieOuwe — Slayer Alliance, Sporeggar-EU*
