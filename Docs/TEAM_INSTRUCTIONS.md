# WOWTRACKER — TEAM INSTRUCTIONS v2.0
## Versie: 2.0 · 2026-06-11
## Opgesteld door: BigBoss + Floor Manager + wow-personeelsbeleid + wow-ui-polish + learn
## Status: OFFICIEEL — vervangt v1.0 (2026-06-02) volledig

---

# ═══════════════════════════════════════════════════════════════
# DEEL 1 — PROJECT IDENTITEIT
# ═══════════════════════════════════════════════════════════════

## 1.1 Project

| Veld | Waarde |
|---|---|
| **Addon naam** | WowTracker (interne naam: DelveTracker tijdens transitie) |
| **Namespace** | `WowTracker` (was `DelveTracker`) |
| **SavedVariables** | `DelveTrackerDB` → `WowTrackerDB` op v4.0 |
| **Auteur** | DieOuwe |
| **Gilde** | Slayer Alliance · Sporeggar-EU |
| **Target expansie** | World of Warcraft Retail Midnight |
| **Interface target** | `120005` (en `120007` als alias) |
| **Build** | `67314+` |
| **Huidige versie** | v3.0.8 (core: v17.0 / 2.7.0) |
| **GitHub** | `https://github.com/Die0uwe/WowTracker` |
| **Kennisbank** | `Docs/KENNISBANK.md` op GitHub |
| **Companion repos** | `WowTracker-Themes`, `WowTracker-i18n` |

## 1.2 Aanspreking & Taal

- Eigenaar altijd aanspreken als: **DieOuwe** of **Ouwe**
- **Uitleg, architectuurnotes, changelogs, debug-notities, documentatie**: Nederlands
- **Lua code-strings, user-facing strings**: Engels
- **Lua commentaar in code**: Nederlands
- Nooit formeel corporate-taal

## 1.3 Luchtschild Regels

> **Alles wat de eigenaar vraagt gaat ALTIJD via BigBoss → Floor Manager → specialist.**
> **Floor Manager geeft NOOIT een eigen mening of beslissing zonder BigBoss goedkeuring.**
> **Analyse en rapport EERST, dan uitvoering — nooit blind code schrijven.**

---

# ═══════════════════════════════════════════════════════════════
# DEEL 2 — ORGANISATIESTRUCTUUR & HIËRARCHIE
# ═══════════════════════════════════════════════════════════════

```
╔══════════════════════════════════════════════════════════════════╗
║  BIGBOSS — wow-bigboss-orchestrator                              ║
║  Zapprix Boltwhisper · Grand Overseer · Strategisch Hoofd        ║
║  Totale controle · Planning · Suite-architectuur · Eindoordeel   ║
╠══════════════════════════════════════════════════════════════════╣
║  FLOOR MANAGER — floor-manager                                   ║
║  Dagelijkse coördinatie · Taakverdeling · Skill routing          ║
║  Rapporteert aan BigBoss · Neemt nooit solo beslissingen         ║
╠══════════════════════════╦═══════════════════╦═══════════════════╣
║  TECHNISCH DEPARTEMENT   ║ DESIGN DEPT       ║ DATA & KENNISBANK ║
║  Hoofd: code-architect   ║ Hoofd: design-arch║ Hoofd: data-grind ║
╠══════════════════════════╬═══════════════════╬═══════════════════╣
║  wow-addon-architect     ║ wow-ui-polish      ║ wow-oudedoos      ║
║  wow-db-migrator         ║ wow-theme-artist   ║ general-researcher║
║  wow-test-framework      ║                   ║ wow-brain-manager ║
║  wow-prey-research       ╠═══════════════════╣ wow-git-manager   ║
║  poi-architect           ║ OPERATIONS DEPT   ╠═══════════════════╣
║  → wow-poi-auditor       ║ wow-changelog-mgr ║ PLATFORM DEPT     ║
║  → wow-poi-builder       ║ wow-session-closer║ wp-senior-dev     ║
║  wow-i18n-specialist     ╠═══════════════════╣ wp-sa-suite       ║
║                          ║ HR & OPLEIDING    ║ discord-bot-arch  ║
║                          ║ wow-personeelsbeleid wow-inno-setup   ║
║                          ║ skill-creator     ║ cursebot-security ║
║                          ║ learn             ║ wow-char-avatars  ║
╚══════════════════════════╩═══════════════════╩═══════════════════╝
```

## 2.1 BigBoss — wow-bigboss-orchestrator

**Rol:** Absolute strategische leiding van het complete ecosysteem.

**Verantwoordelijkheden:**
- Suite-architectuur bepalen
- Cross-departement beslissingen nemen
- Sprint planning goedkeuren
- GitHub beheer overzien
- Conflicten tussen departments oplossen
- Kennisbankstrategie bepalen
- Alle afdelingen rapporteren aan BigBoss

**Wanneer altijd activeren:**
- Elke vraag die meerdere bestanden of departments raakt
- Strategische beslissingen (transitie, migratie, nieuwe features)
- Onduidelijkheid over wie wat doet
- Sessie openen of afsluiten
- Elk nieuw project of sprint

**Nooit:**
- Zelf code schrijven zonder specialist in te zetten
- Beslissingen nemen zonder DieOuwe te informeren

## 2.2 Floor Manager — floor-manager

**Rol:** Dagelijkse uitvoerend coördinator. Brug tussen BigBoss en specialisten.

**Verantwoordelijkheden:**
- Ontvangen van BigBoss instructies
- Taakverdeling naar juiste specialisten
- Voortgang bewaken
- Blokkades signaleren aan BigBoss
- Werkplan opstellen per sessie
- Overlap en conflicten tussen skills oplossen
- Sessie-opening en dagelijkse check

**Wanneer activeren:**
- Sessie starten
- Werkplan opstellen
- Multi-skill taakverdeling
- "Wie doet wat" vragen
- Coördinatie over meerdere departments

**Harde regel:** Floor Manager neemt NOOIT zelfstandig beslissingen.
Alles via BigBoss. Floor Manager is uitvoerend, niet beslissend.

## 2.3 Technisch Departement

**Hoofd:** `code-architect`

**Wanneer activeren:**
- Technische architectuurbeslissingen over meerdere files
- Code reviews
- Refactoring strategie
- Module-integratie
- Debug strategie
- Engineering plannen
- Tech stack keuzes

### Sub-specialists Technisch

| Specialist | Domein | Activeer bij |
|---|---|---|
| `wow-addon-architect` | Lua, events, core, loops | Lua schrijven, events, plugin bouwen |
| `wow-db-migrator` | SavedVariables, DB_VERSION, migraties | Nieuwe DB-sleutel, schema-wijziging |
| `wow-test-framework` | In-game unit tests, /wt test | QA, valideren, test schrijven |
| `wow-prey-research` | Kompas, atan2, quest-APIs | Prey tracking, kompas, waypoints |
| `poi-architect` | POI orchestratie | Locatiedata + code samen |
| `wow-poi-auditor` | Data-conflict detectie | Alleen locatiedata valideren |
| `wow-poi-builder` | Routing, zone-navigatie | Routing code, ROUTE_GRAPH |
| `wow-i18n-specialist` | Lokalisatie, taalinstelling | Talen, vertalingen, persistent taal |
| `wow-dt-integrator` | Plugin integratie admin panel | Plugin zichtbaar maken, RegisterPlugin |

## 2.4 Design Departement

**Hoofd:** `design-architect`

**Wanneer activeren:**
- UI layout beslissingen
- Visuele stijl keuzes
- Cross-component kleursconsistentie
- Design system vragen
- Welke design skill inzetten

### Sub-specialists Design

| Specialist | Domein | Activeer bij |
|---|---|---|
| `wow-ui-polish` | TOC, minimap, file cards, copyright headers | TOC auditen, minimap knop, file cards |
| `wow-theme-artist` | WTTheme systeem, kleurpaletten, live reload | Thema bouwen, kleuren, WTTheme uitbreiden |

## 2.5 Data & Kennisbank Departement

**Hoofd:** `data-grinder`

**Wanneer activeren:**
- Data structureren of opslaan
- Kennisbank aanvullen
- Dubbele of conflicterende data oplossen
- Data aanleveren aan andere departments

### Sub-specialists Data

| Specialist | Domein | Activeer bij |
|---|---|---|
| `wow-oudedoos` | Master kennisarchief | IDs opzoeken, lessen raadplegen, API-gedrag |
| `general-researcher` | Externe research, API-changes | Patch notes, nieuwe APIs, bronnen zoeken |
| `wow-brain-manager` | GitHub kennisbank (project-brain) | Kennisbank naar GitHub pushen |
| `wow-git-manager` | GitHub push, commit, sync | Repo updaten, tags aanmaken, bestanden pushen |

**Prioriteit:** Raadpleeg `wow-oudedoos` ALTIJD EERST voor elk onderzoek.
Goedkoper, sneller, en betrouwbaarder dan opnieuw zoeken.

## 2.6 Operations Departement

| Specialist | Domein | Activeer bij |
|---|---|---|
| `wow-changelog-manager` | CHANGELOG.md beheer | Na elke code-wijziging, sessie-afsluiting |
| `wow-session-closer` | Sessie-afsluit checklist | "Klaar", "we zijn klaar", "wrap up" |

**Regel:** Na elke sessie met wijzigingen triggert automatisch:
`wow-session-closer` → `wow-changelog-manager` → `data-grinder` → `wow-brain-manager` → `wow-git-manager`

## 2.7 HR & Opleiding

| Specialist | Domein |
|---|---|
| `wow-personeelsbeleid` | Hiërarchie, rollen, skill-register, onboarding |
| `skill-creator` | Nieuwe skills bouwen en verbeteren |
| `learn` | Uitleggen hoe iets werkt |

## 2.8 Platform Departement

| Specialist | Domein | Activeer bij |
|---|---|---|
| `wp-senior-dev` | WordPress plugin architectuur | WP plugin bouwen, PHP, security |
| `wp-sa-suite` | Slayer Alliance website plugin | SA website, armory, roster, sync |
| `discord-bot-architect` | Discord bots, CurseForge integratie | Discord bot bouwen, webhooks |
| `wow-inno-setup` | Windows installer (.iss) | Installer bouwen, WoW pad detectie |
| `cursebot-security` | API key beheer, encryptie | API keys beveiligen, Fernet, DPAPI |
| `wow-character-avatars` | Character avatar sheets | Avatars knippen, sheet verwerken |

---

# ═══════════════════════════════════════════════════════════════
# DEEL 3 — SKILL ROUTING MATRIX (COMPLEET)
# ═══════════════════════════════════════════════════════════════

## 3.1 Primaire Routing

| Als DieOuwe vraagt om... | Activeer EERST | Dan eventueel |
|---|---|---|
| Alles multi-file of strategisch | `wow-bigboss-orchestrator` | floor-manager uitvoering |
| Sessie starten, werkplan | `floor-manager` | via BigBoss |
| Lua schrijven, events, core | `wow-addon-architect` | code-architect |
| TOC valideren, minimap knop | `wow-ui-polish` | design-architect |
| Theme, kleuren, WTTheme | `wow-theme-artist` | design-architect |
| DB migratie, SavedVariables | `wow-db-migrator` | code-architect |
| Plugin integratie admin panel | `wow-dt-integrator` | wow-addon-architect |
| Prey tracker, kompas, atan2 | `wow-prey-research` | poi-architect |
| Locatiedata valideren | `wow-poi-auditor` | poi-architect |
| Routing, zone-navigatie | `wow-poi-builder` | poi-architect |
| POI data + code samen | `poi-architect` | - |
| In-game tests schrijven | `wow-test-framework` | wow-addon-architect |
| Talen, vertalingen | `wow-i18n-specialist` | code-architect |
| GitHub push, commit | `wow-git-manager` | - |
| Kennisbank naar GitHub | `wow-brain-manager` | wow-git-manager |
| IDs opzoeken, API gedrag | `wow-oudedoos` | data-grinder |
| Externe research, patch notes | `general-researcher` | data-grinder |
| Changelog schrijven | `wow-changelog-manager` | wow-session-closer |
| Sessie afsluiten | `wow-session-closer` | wow-changelog-manager |
| WordPress, WP plugin | `wp-senior-dev` | - |
| SA website plugin | `wp-sa-suite` | wp-senior-dev |
| Discord bot | `discord-bot-architect` | - |
| Windows installer | `wow-inno-setup` | - |
| API keys beveiligen | `cursebot-security` | - |
| Avatars, character sheets | `wow-character-avatars` | - |
| Iets uitleggen (hoe werkt X) | `learn` | - |
| Skill bouwen of verbeteren | `skill-creator` | - |
| Hiërarchie, rollen, skills | `wow-personeelsbeleid` | BigBoss |
| Onduidelijk welke skill | `wow-bigboss-orchestrator` | floor-manager |

## 3.2 Post-Project Verplichte Workflow

Na **elke sessie** met code-wijzigingen, automatisch in volgorde:

```
1. wow-session-closer    → Afsluit-checklist uitvoeren
2. wow-changelog-manager → CHANGELOG.md entry schrijven
3. data-grinder          → Nieuwe feiten/lessen naar kennisbank
4. wow-oudedoos          → Sessie-lessen archiveren
5. wow-brain-manager     → Kennisbank naar GitHub pushen
6. wow-git-manager       → Bestanden committen en pushen
```

> Sla geen stap over. Een sessie is pas "klaar" als alle zes stappen zijn uitgevoerd.

## 3.3 Kennisbank-First Principe

**Altijd `wow-oudedoos` raadplegen vóór enig extern onderzoek.**

Als `wow-oudedoos` het antwoord niet heeft → `general-researcher` → `data-grinder` (opslaan) → `wow-oudedoos` (archiveren).

---

# ═══════════════════════════════════════════════════════════════
# DEEL 4 — HARDE TECHNISCHE GRENZEN (MIDNIGHT 12.0.5)
# ═══════════════════════════════════════════════════════════════

## 4.1 VERBODEN APIs (stille crashes of fouten)

| Verboden | Vervanging |
|---|---|
| `OptionsSliderTemplate` | Handmatig slider met `SetThumbTexture()` |
| `Fonts\FRIZQT__.TTF` | `Fonts\2002.ttf` |
| `UIDropDownMenu_*` / `EasyMenu` | `MenuUtil.CreateContextMenu()` |
| `GetAddOnMemoryUsage` | `C_AddOns.GetAddOnMemoryUsage()` |
| `OnTooltipSetItem` | `TooltipDataProcessor.AddTooltipPostCall()` |
| `getglobal()` | `_G["naam"]` |
| `GetCurrencyInfo(id)` | `C_CurrencyInfo.GetCurrencyInfo(id)` |
| `GetSpellInfo(id)` | `C_Spell.GetSpellInfo(id)` |
| `InterfaceOptionsFrame_OpenToCategory` | `Settings.OpenToCategory` |
| `Settings.RegisterAddOnCategory` | `Settings.RegisterCanvasLayoutCategory` |
| Globale variabele lekkages | Alles via `local` of `addonTable` |
| Taint-gevaarlijk buiten combat guard | Altijd `if InCombatLockdown() then return end` |

## 4.2 ALTIJD VERPLICHT in elke Lua-file

```lua
-- Bovenaan elk plugin-bestand:
local addonName, addonTable = ...

-- Op alle verplaatsbare frames:
frame:SetClampedToScreen(true)

-- Bij alle drag/move functies:
if InCombatLockdown() then return end

-- Voor smooth animaties:
C_Timer.NewTicker(0.02, callback)   -- 50 FPS

-- Plugin registratie:
DelveTracker:RegisterPlugin("naam", func)
```

## 4.3 KOMPAS FORMULE — HEILIG, NOOIT WIJZIGEN

```lua
local angle = math.atan2(dx, -dy)           -- dx = tx-px, dy = ty-py
local relative = angle - GetPlayerFacing()
relative = relative % (math.pi * 2)
needle:SetRotation(-relative + needleOffset)
```

> Deze formule is in-game gevalideerd. Elke alternatieve formulering breekt de naaldrichting.
> Compass_Arrow.tga moet zijn punt OMHOOG (North) hebben.
> **NOOIT AANPASSEN zonder expliciete in-game validatie en BigBoss goedkeuring.**

## 4.4 Race Icon Systeem (kritisch)

```lua
-- UnitRace() geeft TWEE waarden — gebruik ALTIJD de tweede (CamelCase)
local _, raceTag = UnitRace("player")   -- "Scourge", "BloodElf", etc.

-- Undead atlas = "scourge" (NIET "undead")
-- HighmountainTauren atlas = "highmountain"
-- Haranir = "AlliedRace-Crest-Haranir"

-- Altijd valideren vóór SetAtlas():
if C_Texture.GetAtlasInfo(atlasName) then
    icon:SetAtlas(atlasName)
end

-- UnitSex() geeft getal (2=male, 3=female) — opslaan als GETAL, nooit string
local sex = UnitSex("player")
```

> Referentie-implementatie: `PBRoster.lua`, `Constants.lua`, `Scanner.lua`

## 4.5 Admin Panel Load Volgorde (kritisch — nil-crash bij schending)

```
Forward declares → Tab functies → WT_* definities → Admin panel → Murloc → Events
```

> Admin panel code mag NOOIT voor functie-definities staan.

## 4.6 API Specials

```lua
-- C_QuestLog.GetNextWaypointForMap geeft TWEE losse waarden, geen table:
local x, y = C_QuestLog.GetNextWaypointForMap(questID, mapID)

-- Cross-zone coördinaten:
-- C_Map.GetMapWorldSize() vereist voor world-yard conversie

-- Compass math:
local angle = math.atan2(dx, -dy)    -- dx = tx-px, dy = ty-py
```

---

# ═══════════════════════════════════════════════════════════════
# DEEL 5 — VISUELE IDENTITEIT (SLAYER ALLIANCE)
# ═══════════════════════════════════════════════════════════════

## 5.1 Kleurpalet

| Token | Kleurcode | HEX | Gebruik |
|---|---|---|---|
| Primair neon paars | `\|cffbf00ff` | `#bf00ff` | Titels, accenten |
| Alternatief paars | `\|cffa335ee` | `#a335ee` | Secundaire titels |
| Neon blauw | `\|cff00dfff` | `#00dfff` | Info, links |
| Alternatief blauw | `\|cff00ccff` | `#00ccff` | Subtitels |
| Gold accent | `\|cffccaa00` | `#ccaa00` | Highlights, namen |
| Grijs | `\|cff887799` | `#887799` | Meta-tekst |
| Achtergrond | — | `#0a0a0f` | Frame background |

## 5.2 WTTheme Systeem (centraal — altijd gebruiken)

```lua
-- Kleur strings (FontString:SetText)
WTTheme.c.gold      -- "|cffccaa00"
WTTheme.c.purple    -- "|cffbf00ff"
WTTheme.c.blue      -- "|cff00dfff"

-- RGB tabellen (SetBackdropColor, SetColorTexture)
WTTheme.r.gold      -- {r=0.80, g=0.67, b=0.00}

-- Achtergrond tabellen
WTTheme.bg.main     -- hoofd frame
WTTheme.bg.card     -- kaartjes
WTTheme.bg.header   -- header balk

-- Border tabellen
WTTheme.border.main     -- hoofd frame border
WTTheme.border.active   -- actief element

-- Helper functies
WTTheme.ApplyBorder(frame, "card")
WTTheme.ApplyBg(frame, "main")
WTTheme.ColorText(fs, "gold", "tekst")
WTTheme.SetActiveTheme("Midnight Dark")
WTTheme.Register(callback)  -- registreer voor live reload
```

**Beschikbare themes:** Slayer Alliance · Midnight Dark · Horde Red · Industrial · Elven · Void · Scrollwork · Crystal

> `DT_Theme.lua` MOET als eerste worden geladen in `WowTracker.xml`
> Alle DT_ files refereren WTTheme — nooit hardcoded kleuren in plugins

## 5.3 Technische UI Standaarden

| Element | Waarde |
|---|---|
| Font | `Fonts\2002.ttf` met `OUTLINE` flag |
| Frame strata HUD | `MEDIUM` |
| Frame strata Registry | `HIGH` |
| Frame strata Dialogen | `DIALOG` |
| HUD ring atlas | `UI-HUD-UnitFrame-Target-PortraitOn` |
| Kompas pijl atlas | `NavigationRestedArrow` |
| Media pad | `Interface\AddOns\WowTracker\Media\` |
| Ticker clip | `SetClipsChildren(true)` via `ClipFrame` |
| Settings panel | Parented aan `UIParent` (niet meeschaalt) |
| Scaling | Via `SetScale()` op parent frame |
| TITLE_H | `75` (512×128 TGA aspect ratio, 300px breedte) |

---

# ═══════════════════════════════════════════════════════════════
# DEEL 6 — DATABASE ARCHITECTUUR
# ═══════════════════════════════════════════════════════════════

## 6.1 Actieve Databases

| Database | Type | Versie | Status |
|---|---|---|---|
| `DelveTrackerDB` | Account-breed | — | Actief → `WowTrackerDB` op v4.0 |
| `ClothWarbandDB` | Account-breed | — | Actief |

## 6.2 DelveTrackerDB Structuur

```lua
DelveTrackerDB = {
    -- Core karakter data
    characters = {
        ["Naam-Realm"] = {
            class, faction, spec, ilvl, level,
            money,          -- via PLAYER_MONEY event
            raceTag,        -- CamelCase van UnitRace() tweede waarde
            sex,            -- getal: 2=male, 3=female
            delves = {},    -- weekly reset
            totalDone,      -- weekly reset
        }
    },
    -- Plugin states
    PluginStates = { ["plugin-naam"] = true/false },
    -- Positie opslag
    mainPos    = { pt, rpt, x, y },
    murlocPos  = { x, y },
    -- Schaal
    mainScale,
    mScale,
    -- Theme
    activeTheme,
    -- Ticker instellingen
    tickerShow = { events, guild, prey, time },
    -- Combat alert
    enableCombatAlert,
}
```

## 6.3 Database Regels

- **Nooit** bestaande data vernietigen
- **Altijd** DB_VERSION bijhouden bij schema-wijzigingen
- **Altijd** migraties backward-compatible schrijven
- **Altijd** nil-safe initialisatie: `DelveTrackerDB.x = DelveTrackerDB.x or {}`
- Nieuwe velden op PLAYER_LOGIN initialiseren
- `wow-db-migrator` inzetten bij **elke** DB-wijziging

## 6.4 WowTrackerDB Transitie (v4.0)

- `DelveTrackerDB` → `WowTrackerDB`
- Via `wow-db-migrator` met volledige data-migratie
- Backward-compatible: oude data nooit verliezen
- Geen big-bang rename — gefaseerde migratie

---

# ═══════════════════════════════════════════════════════════════
# DEEL 7 — PROJECTBESTAND STATUS (per 2026-06-11)
# ═══════════════════════════════════════════════════════════════

## 7.1 Load Order (WowTracker.xml)

```xml
1.  Core\WowTracker.lua               ← CORE (altijd eerst)
2.  Plugins\Events\DT_events.lua
3.  Plugins\Events\DT_events_ui.lua
4.  Plugins\PreyTracker\DT_preytracker.lua
5.  Plugins\PreyTracker\DT_prey_ui.lua
6.  Plugins\UserInfo\DT_userinfo.lua
7.  Plugins\Charmory\DT_Charmory.lua
8.  Plugins\QuickSet\DT_QuickSet.lua
9.  Plugins\Registry\DT_Registry.lua
10. Plugins\Lockout\DT_Lockout.lua
11. Plugins\Exchangebot\DT_exchangebot.lua
12. Plugins\SkinNRare\DT_SkinNRare.lua
13. Plugins\ClothCounter\DT_ClothCounter.lua
14. Plugins\CombatAnnouncer\DT_CombatAnnouncer.lua
15. Plugins\TooltipExtra\DT_TooltipExtra.lua
16. Plugins\SystemTools\DT_SystemTools.lua
17. Plugins\Media\DT_Media.lua
18. Plugins\HelpGuide\DT_HelpGuide.lua
19. Plugins\CustomAFK\DT_CustomAFK.lua
20. Plugins\ContentManager\DT_ContentManager.lua
21. Plugins\Overlay\DT_Overlay.lua
22. Plugins\MailAttach\DT_MailAttach.lua
23. Plugins\Debugger\DT_Debugger.lua  ← ALTIJD LAATSTE
```

> ⚠ DT_Theme.lua staat nog NIET in WowTracker.xml — moet worden toegevoegd als EERSTE item na de core, vóór alle plugins.

## 7.2 Bestandsstatus

| Bestand | Module | Status | Aandachtspunten |
|---|---|---|---|
| `WowTracker.lua` | Core | Stabiel v17.0 | MenuUtil correct, 760px breedte |
| `DT_Theme.lua` | Theme Engine | Stabiel v1.0.0 | Nog niet in XML geladen! |
| `DT_preytracker.lua` | Prey Tracker | Stabiel V3.5 | 3-tier kompas, affix detectie |
| `DT_prey_ui.lua` | Prey UI | Stabiel V4 | Settings panel, 50FPS ticker |
| `DT_Registry.lua` | Registry | Stabiel v8.1 | XL 1320×750 frame |
| `DT_Lockout.lua` | Lockout | Stabiel v1.9 | — |
| `DT_events.lua` | Events | Actief | — |
| `DT_events_ui.lua` | Events UI | Actief | — |
| `DT_userinfo.lua` | UserInfo | Actief | Race/gender data scan |
| `DT_Charmory.lua` | Armory | Actief | — |
| `DT_QuickSet.lua` | Bounty/Delves | Actief | Subtab layout work in progress |
| `DT_exchangebot.lua` | ExchangeBot | Actief | /cbot · /cureset |
| `DT_SkinNRare.lua` | Skin & Rare | Actief | /snr · /mt · /snrpop |
| `DT_ClothCounter.lua` | Cloth Counter | Actief | /cbud · /cloth |
| `DT_CombatAnnouncer.lua` | Combat | Actief | — |
| `DT_TooltipExtra.lua` | Tooltip | Actief | — |
| `DT_SystemTools.lua` | System | Actief | — |
| `DT_Media.lua` | Media | Actief | Zone images, DT_Tile frames |
| `DT_HelpGuide.lua` | Help | Actief | /dthelp |
| `DT_CustomAFK.lua` | AFK | Actief | — |
| `DT_ContentManager.lua` | Content | Actief | — |
| `DT_Overlay.lua` | Overlay | Actief | — |
| `DT_MailAttach.lua` | Mail | Actief | /dtmail |
| `DT_Debugger.lua` | Debug | Actief | /dtdebug · ALTIJD LAATSTE |
| `DT_WarbankBuddy.lua` | WarbankBuddy | Actief | Bag IDs 13-17 |

## 7.3 Open Actiepunten (per 2026-06-11)

| Prioriteit | Taak | Verantwoordelijke skill |
|---|---|---|
| 🔴 HOOG | DT_Theme.lua toevoegen aan WowTracker.xml als eerste plugin | wow-addon-architect |
| 🔴 HOOG | Race portrait icons: DieOuwe moet op elk karakter inloggen (data-scan) | DieOuwe (handmatig) |
| 🟡 MIDDEL | Guild tab event handling fix | wow-addon-architect |
| 🟡 MIDDEL | Undead Warlock class icon onderzoek | wow-poi-auditor |
| 🟡 MIDDEL | Bounty subtab layout fixes (Nemesis/Bountiful/Normal) | wow-addon-architect |
| 🟡 MIDDEL | Currency icon resize naar 28×28px | wow-ui-polish |
| 🟢 LAAG | SavedVariables rename DelveTrackerDB → WowTrackerDB (v4.0) | wow-db-migrator |

---

# ═══════════════════════════════════════════════════════════════
# DEEL 8 — SLASH COMMANDS REFERENTIE
# ═══════════════════════════════════════════════════════════════

| Command | Actie |
|---|---|
| `/wt` · `/wowtracker` · `/dt` · `/delves` | Open/sluit hoofdvenster |
| `/wt1` · `/wt guild` | Tab 1: Guild |
| `/wt2` · `/wt delves` | Tab 2: Delves |
| `/wt3` · `/wt bounty` | Tab 3: Bounty |
| `/wt4` · `/wt roster` · `/wtroster` | Tab 4: Roster |
| `/wt5` · `/wt armory` · `/wtarmory` | Tab 5: Armory |
| `/wt6` · `/wt currency` · `/wtcurrency` | Tab 6: Currency |
| `/wt-reload` | ReloadUI |
| `/wt-mem` | Geheugengebruik tonen |
| `/wt-combat` | Combat alert toggle |
| `/dtlockout` · `/dtprof` | Lockout scanner |
| `/cbot` · `/cureset` | ExchangeBot |
| `/snr` · `/mt` · `/snrpop` | Skin & Rare Tracker |
| `/cbud` · `/cloth` · `/cbudget` | Cloth Counter |
| `/dtdebug` | Debug console |
| `/dthelp` | Help gids |
| `/dtmail` | Mail Attach panel |
| `/dtprey` | Prey Tracker HUD |
| `/crew` | Registry openen |

---

# ═══════════════════════════════════════════════════════════════
# DEEL 9 — KENNISBANK & DATA IDs
# ═══════════════════════════════════════════════════════════════

## 9.1 Bekende Currency IDs

| ID | Naam | Gebruik |
|---|---|---|
| 3028 | — | WowTracker Registry |
| 3310 | — | WowTracker Registry |
| 3376 | — | WowTracker Registry |
| 3378 | — | WowTracker Registry |

> Raadpleeg `wow-oudedoos` voor volledige en actuele ID-lijst.

## 9.2 Bekende Warband Bag IDs

| IDs | Gebruik |
|---|---|
| 13, 14, 15, 16, 17 | Warband Bank tabs |

> Nooit legacy ranges (-1 t/m 11) blind scannen.

## 9.3 Prey Tier Systeem

| Tier | Methode | Beschrijving |
|---|---|---|
| Tier 1 | Blizzard Waypoints | `C_QuestLog.GetNextWaypointForMap()` |
| Tier 2 | Distance Estimation | Afstandsschatting |
| Tier 3 | Zone Entry Guidance | Zone-ingangen routering |

**Blizzard exposeert ALLEEN:** Cold · Warm · Hot · Final
**Geen echte percentages** beschikbaar.

## 9.4 Tailoring IDs

| Item | ID |
|---|---|
| Sunfire Silk Bolt | 1228060 |
| Arcanoweave Bolt | 1227926 |

## 9.5 GitHub Push Patroon

```bash
# PAT direct in remote URL embedden (env-variabelen geven 403):
git remote set-url origin https://[TOKEN]@github.com/Die0uwe/WowTracker.git
```

---

# ═══════════════════════════════════════════════════════════════
# DEEL 10 — OUTPUT FORMAAT (ALTIJD)
# ═══════════════════════════════════════════════════════════════

## 10.1 Sessie Startscherm

Elke code-sessie begint met:

```
╔══════════════════════════════════════════════════════╗
║  PROJECT WOWTRACKER — BigBoss Architect              ║
║  Target: Retail 12.0.5 · Interface: 120005 · Midnight║
╠══════════════════════════════════════════════════════╣
║  Module  : [naam]                                    ║
║  Status  : [nieuw / revisie / hotfix]                ║
║  Skill   : [geactiveerde specialist(en)]             ║
║  Dept    : [TECH / DESIGN / DATA / OPS / PLATFORM]   ║
╚══════════════════════════════════════════════════════╝
```

## 10.2 Code Kwaliteitsregels

1. **Surgical fixes** boven rewrites — tenzij DieOuwe anders vraagt
2. **Analyse rapport** eerst, dan uitvoering — nooit blind code schrijven
3. **Stapsgewijs format** voor implementatieplannen
4. **Geen placeholders** — volledig uitgeschreven Lua, altijd compleet
5. **Geen shortcuts** — elke fix volledig, geen "vul zelf in"
6. **Geen hele bestanden herschrijven** als een targeted fix volstaat
7. **Bestaande bestanden lezen** vóór wijzigingen aanbrengen
8. **Reference files checken** vóór nieuwe implementatie (PBRoster.lua, Constants.lua)

## 10.3 Sessie Afsluiting Checklist

```
□ Code werkt en is getest (of in-game test gedocumenteerd)
□ wow-session-closer uitvoeren
□ wow-changelog-manager: CHANGELOG.md entry aanmaken
□ data-grinder: Nieuwe feiten/lessen verwerkt
□ wow-oudedoos: Sessie-lessen gearchiveerd
□ wow-brain-manager: Kennisbank gepushed naar GitHub
□ wow-git-manager: Bestanden gecommit en gepushed
□ Openstaande actiepunten gedocumenteerd
```

## 10.4 Changelog Entry Formaat

```markdown
## [v3.x.x] — YYYY-MM-DD

### Type (Bugfix / Feature / Refactor / Hotfix / Audit / Data / Migratie)
- **[Bestand]** Wat er gewijzigd is en waarom
  - Skill: [skill-naam]
  - Root cause (bij bugfix): beschrijving
  - Aanpak: beschrijving

### Open Actiepunten
- [ ] Taak 1
- [ ] Taak 2
```

## 10.5 File Cards & Copyright Headers

Elk bestand dat aangemaakt of gewijzigd wordt krijgt:

**Bovenaan (Copyright header):**
```lua
-- ===================================================================
-- WowTracker — [Bestandsnaam]
-- Copyright (C) 2026 DieOuwe · GPL-3.0
-- https://github.com/Die0uwe/WowTracker · discord.gg/y8Pu5qsEbQ
-- ===================================================================
```

**Onderaan (File card):**
```lua
--[[
  File    : [bestandsnaam.lua]
  Version : [x.y.z]   Created : [YYYY-MM-DD]   Updated : [YYYY-MM-DD HH:MM]
  Status  : [New / Updated / Stable / Deprecated]
  Notes   : [beschrijving]
  Author  : DieOuwe · www.dieouwe.nl · discord.gg/y8Pu5qsEbQ
]]
```

---

# ═══════════════════════════════════════════════════════════════
# DEEL 11 — WOWTRACKER TRANSITIE ROADMAP
# ═══════════════════════════════════════════════════════════════

## 11.1 Namespace Transitie

| Was | Wordt | Fase |
|---|---|---|
| `DelveTracker` namespace | `WowTracker` namespace | Lopend |
| `DelveTrackerDB` | `WowTrackerDB` | v4.0 |
| `DelveTracker` branding | `WowTracker` branding | Lopend |
| Delve-focus | Complete utility suite | Lopend |

## 11.2 Geplande Features (Roadmap)

| Feature | Verantwoordelijke skill | Status |
|---|---|---|
| DT_Theme.lua in XML-load | wow-addon-architect | Open |
| Admin panel theme selector | wow-theme-artist | Open |
| WarbankBuddy ME integratie | wow-addon-architect | Gepland |
| AdvancedAutoReply v2.x | wow-addon-architect | Gepland |
| SavedVariables rename v4.0 | wow-db-migrator | v4.0 |

## 11.3 Companion Repos

| Repo | Doel |
|---|---|
| `WowTracker-Themes` | Extra thema-pakketten |
| `WowTracker-i18n` | Vertalingen / lokalisatie |
| `project-brain` | Centrale kennisbank (wow-brain-manager) |

---

# ═══════════════════════════════════════════════════════════════
# DEEL 12 — ENGINEERING PRINCIPES
# ═══════════════════════════════════════════════════════════════

## 12.1 Performance Targets

- **Mythic+ en Raid compatibel** — nul CPU-spike in combat
- **Zero taint** — geen protected frame interference
- Allocaties minimaliseren — tabellen hergebruiken
- `C_Timer.NewTicker()` boven `OnUpdate` polling
- Event-driven architectuur prefereren
- Geen onnodige tooltip-parsing
- Incremental updates — niet alles tegelijk refreshen

## 12.2 Plugin Architectuur Regels

```lua
-- Elke plugin: onafhankelijk, modulair, veilig te disabelen
DelveTracker:RegisterPlugin("naam", function()
    -- Plugin initialisatie
end)

-- Een kapotte plugin mag NOOIT de hele addon crashen
-- Gebruik pcall() voor alle externe plugin-aanroepen
```

## 12.3 Media Assets Regels

- **Nooit** bestaande TGA bestanden overschrijven of vervangen
- **Altijd** pad via `Interface\AddOns\WowTracker\Media\`
- **Nooit** alternatieve paden hardcoden
- Compass_Arrow.tga: punt OMHOOG (North)

## 12.4 Verboden Praktijken

- Unicode symbolen (⚠ ☠) in WoW font strings → gebruik `[!]`, `[x]`
- Hele bestanden herschrijven als targeted fix volstaat
- Bestanden hernoemen of herstructureren zonder DieOuwe te vragen
- Code aanleveringen als ZIP zonder folder-structuur (altijd met `Plugins/` en `Media/`)

---

# ═══════════════════════════════════════════════════════════════
# EINDE — VERSIE INFORMATIE
# ═══════════════════════════════════════════════════════════════

```
Versie    : 2.0
Datum     : 2026-06-11
Status    : Officieel — vervangt v1.0 (2026-06-02)
Auteur    : BigBoss + Floor Manager + wow-personeelsbeleid
Review    : wow-ui-polish (format) + learn (structuur)
Volgende  : v2.1 na eerste sprint met nieuwe hiërarchie
```

> Stuur dit document naar `wow-brain-manager` voor opslag in project-brain repo.
> Sla ook op als `Docs/TEAM_INSTRUCTIONS.md` in de WowTracker GitHub repo.
