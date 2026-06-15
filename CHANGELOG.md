# CHANGELOG — WowTracker (Slayer Alliance Edition)

## [v3.5.5] — 2026-06-15

### Feature
- **[DT_Abundance.lua]** Nieuw plugin — Abundance tegel uitgesplitst uit DT_QuickSet
  - Live refresh elke 60 sec via C_Timer.NewTicker
  - Shard of Dundun count, timer, zone, map ID, POI ID
  - Hergebruikt frame bij refresh (geen dubbele frames)
  - Skill: wow-addon-architect

### Feature
- **[Core/DT_Theme.lua]** Theme Engine v2.0
  - 3 nieuwe premium themes: Titan Bronze, Void Reborn, Emerald Elven
  - B/X/Murloc icon callbacks via WTTheme.Register()
  - BlendMode ADD → BLEND fix (murloc niet meer transparant)
  - 45 nieuwe TGA icons (8 themes × 5 slots) correct benoemd
  - Skill: wow-theme-artist

### Feature
- **[Core/WowTracker.lua]** Header knoppen 22px → 32px
  - iconTex 18px → 28px
  - Cleanup DB knop naast Combat alert in admin panel
  - Skill: wow-addon-architect

### Feature
- **[Plugins/MinimapIcon/DT_MinimapIcon.lua]** Nieuw — LibDBIcon minimap knop
  - Live icon update bij theme-wissel
  - /wt minimap toggle

### Open Actiepunten
- [ ] Void (basic) theme verwijderen uit themes lijst
- [ ] WowTracker-Themes repo updaten met nieuwe premium themes
- [ ] i18n strings voor Abundance toevoegen

## [v3.2.0] — 2026-06-10
### Added
- Sprint A-01: Gnome Dieouwe voeten op de grond (y=0 anker)
- Sprint A-02: Roster kaarten 10% kleiner + horizontaal gecentreerd
- Sprint A-03: Taal systeem persistent — ApplyLanguage() + PLAYER_LOGIN restore
- Sprint A-04: Armory 3D model achter stats/items (FrameLevel fix)
- Sprint A-05: TOC Interface 120007 — klaar voor patch 12.0.7 (16 juni 2026)
- Sprint B-01: Roster kaart tooltip uitgebreid — spec, delves, goud, professions
- Sprint B-02: Currency tab naam-filter + auto-suggest dropdown
- Sprint B-03: WTTheme live callback voor main UI frame
- Sprint C-01: Guild online panel — klik=/who, tooltip met zone, klaskleur
- Sprint C-02: Ticker uitgebreid — Abundance + Warband goud toggle items
- Sprint D: TH_bg/TH_border helpers in Core, 16 hardcoded kleuren → WTTheme tokens
- wow-theme-artist skill aangemaakt (Pixel Voidwhisper)
- wow-i18n-specialist skill aangemaakt

### Fixed
- SkinNRare StyleButton crash: btn:SetFont() → btn:GetFontString():SetFont()
- Murloc button onzichtbaar: SA backdrop fallback altijd zichtbaar
- UI auto-show bij PLAYER_ENTERING_WORLD geblokkeerd
- deploy.sh in repo voor correcte ZIP builds

---
## [v3.1.0-hotfix3] — 2026-06-09
### Fixed
- Debugger wit scherm: GameFontHighlightSmall geeft witte tekst in 12.0.5 — alle fontstrings vervangen door directe Fonts\2002.ttf + SetTextColor in Debugger, Charmory, CombatAnnouncer, CustomAFK, Events, Exchangebot, HelpGuide, QuickSet, Registry, SkinNRare, SystemTools, UserInfo (37 instances totaal)
- TH() nil crash: TH() stond vóór de if-not-DelveTracker guard in Debugger, Exchangebot, Lockout, MailAttach, QuickSet — verplaatst naar na de guard
- Roster crash (lijn 1214): pairs() op Button frame gaf functions als 'c' — vervangen door ipairs() met directe Hide check
- TOC versie gebumpt naar v3.1.0
- BossToast upvalue: bossToast lokaal in closure gereset bij elke RefreshDelves() — opgeslagen als scN.bossToast
- Lua parse error in strat strings: Unicode em-dash en echte newlines in string literals — vervangen door ASCII en \n escapes

### Added
- deploy.sh in repo root — bouwt altijd correcte WowTracker/ ZIP zonder rommelmappen

### Files Changed
| Bestand | Type |
|---------|------|
| Core/WowTracker.lua | fix roster crash, fix ticker toast positie |
| Plugins/Debugger/DT_Debugger.lua | fix wit scherm, fix TH() guard, SA styling |
| Plugins/QuickSet/DT_QuickSet.lua | fix GameFont, TH() guard, BossToast upvalue, strat strings |
| Plugins/Exchangebot/DT_exchangebot.lua | fix GameFont, TH() guard |
| Plugins/Lockout/DT_Lockout.lua | fix TH() guard |
| Plugins/MailAttach/DT_MailAttach.lua | fix TH() guard |
| Plugins/[9 plugins] | fix GameFont 37x |
| deploy.sh | nieuw — deployment helper |
| WowTracker.toc | versie v3.1.0 |

---
## [v3.1.0] — 2026-06-09
### Added
- S3-02: Ticker toast config panel — slide-in paneel boven UI bij klik op ticker, SA dark stijl, 4 toggle knoppen (Events/Prey/Guild/Tijd), alles aan/uit
- S3-04: Boss Tactics knop in Nemesis tab — draggable popup met volledige Nullaeus strat, T8 en T11 tabs, geverifieerde mechanics (Method.gg + ConquestCapped)
- S3-02: TickerToast lazy-init systeem — herbruikbaar component, sluit via X of tweede klik

### Fixed
- S3-01: Guild MOTD async laden — C_GuildInfo.GuildRoster() + GUILD_ROSTER_UPDATE event + C_Timer.After(1.5) fallback, geen "Laden..." meer
- S3-03: Nemesis Required Items header verwijderd — was onjuist en te generiek
- S3-03: Nemesis items (Beacon of Hope, Trovehunter's Bounty, LOOT RAID-R Mini) gecentreerd in scroll area
- S3-05: Abundance scanner — Silvermoon en Sunfury Spire verwijderd (geen abundance caves), correcte cave namen per mapID
- S3-05: Abundance zone namen — Watha'nan Crypts / Loaknit Den / Floaret Grotto / Abundant Voidburrow
- S3-05: Abundance events uitgebreid — WORLD_STATE_TIMER_START + DISPLAY_SIZE_CHANGED toegevoegd
- S3-07: Abundance blok compacter (60px → 52px), cleaner 2-rij layout, Shard of Dundun prominent
- T04b: WTTheme TH() helper op alle 18 plugins (PreyTracker uitgesloten)
- T04c: Admin thema knoppen koppelen aan WTTheme.SetActiveTheme()
- T04d: Bounty tiles gecentreerd via xPad berekening
- Undead atlas — geverifieerd raceicon128-Undead-male/female via /wt-racedbg
- Vault knop verplaatst van admin panel naar main UI header
- Admin panel heringedeeld — logo + titel links, DieOuwe rechts, vault.tga banner
- Gnome Dieouwe SetTexCoord — horizontaal gespiegeld (1,0, 0,0, 1,1, 0,1), rechtop

### Research
- S3-06: Altoholic/BeniKUI/ElvUI — delve tracking via C_AreaPoiInfo.GetDelvesForMap, geen abundance specifieke API, eigen implementatie is state-of-the-art
- Abundance zones geverifieerd: 4 caves, roteert elke 8u (Wowhead storyline 5810)
- Nullaeus boss mechanics volledig gedocumenteerd (beide moeilijkheden)

### Files Changed
| Bestand | Type | Sprint |
|---------|------|--------|
| Core/WowTracker.lua | fix+feat | S3-01, S3-02, T04c, vault, admin, gnome |
| Plugins/QuickSet/DT_QuickSet.lua | fix+feat | S3-03, S3-04, S3-05, S3-07, T04b, T04d |
| Plugins/Events/DT_events.lua | fix | S3-05 abundance maps |
| Plugins/ClothCounter/DT_ClothCounter.lua | feat | T04b WTTheme |
| Plugins/SkinNRare/DT_SkinNRare.lua | feat | T04b WTTheme |
| Plugins/[15 plugins] | feat | T04b TH() helper |
| Core/DT_Theme.lua | feat | T04a centraal theme systeem |

---
## [v3.0.7] — 2026-06-08
### Fixed
- Undead/Forsaken race icon: atlas heet `raceicon128-scourge-*` niet `undead`
  Scourge + Undead + Forsaken mappen nu allemaal correct naar `scourge`
- Admin panel volledig hersteld uit v2.8.9:
  Header logo + titel + DieOuwe image
  UI Scale + Murloc Scale sliders
  Plugin on/off lijst met scroll
  Extra opties sectie

## [v3.0.6] — 2026-06-08
### Fixed
- Admin panel verplaatst naar na alle functie definities
  Was: admin panel stond voor functies → WT_UpdateGuildOnline nil crash op L417

## [v3.0.5] — 2026-06-08
### Added
- Admin panel terug via Settings.RegisterCanvasLayoutCategory
  ⚙ knop → WoW Settings → WowTracker

## [v3.0.4] — 2026-06-08
### Fixed
- DB auto-migratie bij PLAYER_LOGIN:
  gender string ("male"/"female") → getal (2/3)
  race met spaties ("Blood Elf") → CamelCase ("BloodElf")

## [v3.0.3] — 2026-06-08
### Fixed
- Gender opgeslagen als getal (UnitSex() = 2 of 3) exact PB Scanner
- DT_SetRaceIcon: gender check `== 3` i.p.v. `== "female"`

## [v3.0.2] — 2026-06-08
### Fixed
- DB cleanup bij login: lege/duplicate karakter entries verwijderd

## [v3.0.1] — 2026-06-08
### Added
- DT_SetRaceIcon() exact PBRoster Constants.lua v3.5.1
  RaceIconShortName tabel alle rassen inclusief Midnight
  3-staps fallback: raceicon128 → raceicon → AlliedRace-Crest

## [v3.0.0] — 2026-06-08
### Added
- Race icon via SetAtlas: PBRoster methode
  UnitRace() 2e return = CamelCase, UnitSex() = getal
- WowTracker Community banner gepusht naar GitHub
  Media/Banners/WowTracker_Banner_1280x640.png
  Media/Banners/WowTracker_Banner_1920x480.png
  Media/Headers/WowTracker_Header_800x200.png

---

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
