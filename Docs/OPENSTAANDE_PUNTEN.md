# OPENSTAANDE PUNTEN — Besloten maar (nog) niet doorgevoerd
## BigBoss chat-analyse · 2026-06-12 · basis: alle projectsessies

## ✅ Vandaag afgehandeld (v3.0.9c/d)
- Race portraits definitief (Constants.lua v3.5.1, alle rassen)
- Currency IDs DataStore-geverifieerd (71), icons 2x kleiner (22px), blanco gefilterd
- Taal: live toepassen bij klik + herstel op login (geen reload nodig)
- Theme: live switch (main frame + ticker + tab buttons), herstel op login
- DB auto-migratie herbouwd (gender string→getal, race spaties weg)
- GuildRoster/MOTD taint-vrij · Debugger v3.0 BugSack-capture
- ADDON_NAME fixes (ClothCounter/userinfo/Debugger)

## Status update 2026-06-12 (avond): FASE 1 + FASE 2 VOLLEDIG AFGEROND
v3.1.0 admin panel · v3.1.1 warband stats · v3.1.2 plugins (22) ·
v3.1.3 bounty subtabs · v3.1.4 guild images · v3.1.5 abundance chip ·
v3.1.6 professions · v3.1.7 zes UI-fixes · v3.1.8/9 race definitief +
reverse-lookup migratie + tickerShow init-fix

## [AFGEROND] FASE 1 — Verloren bij regressie, herbouwen (besloten in v3.0.7 sessie)
| # | Taak | Skill | Notitie |
|---|---|---|---|
| 1 | Admin panel herstel (v2.8.9 basis) + theme/taal selectors | wow-addon-architect | Zat in v3.0.7, NIET in huidige core |
| 2 | Warband stats header (totaal chars + totaal gold K/M) | wow-addon-architect | Zat in v3.0.7 |
| 3 | Murloc button + context menu (4 secties) | wow-addon-architect | Verifiëren of aanwezig |
| 4 | Dieouwe texture flip SetTexCoord(1,0,0,0,1,1,0,1) | wow-ui-polish | Verifiëren |

## 🟡 FASE 2 — Besloten, nooit gebouwd
| # | Taak | Skill | Bron |
|---|---|---|---|
| 5 | 8 plugins registreren (Events, PreyTracker, ContentMgr, CustomAFK, Overlay, WarbankBuddy, Theme, Media) | wow-dt-integrator | Audit 2026-06-01: 15/23 geregistreerd |
| 6 | Bounty subtabs verfijnen (Nemesis opruimen, Bountiful condities, Normal stijl) | wow-ui-polish | Sprint B |
| 7 | Guild tab: char images bij online leden | wow-addon-architect | Sprint 2026-06-08 |
| 8 | Abundance chip indicator in Bounty Nemesis tile | wow-addon-architect | Sprint B |
| 9 | Professions als kleine iconen op roster kaartje | wow-addon-architect | Sprint B |

## 🟢 FASE 3 — Architectuur (Sprint C besluit)
| # | Taak | Skill |
|---|---|---|
| 10 | Locales/ structuur: enUS.lua + nlNL.lua, alle strings via L["key"] (WT_LANG → files) | wow-i18n-specialist |
| 11 | WTTheme uitrol per plugin (Registry→QuickSet→Lockout→rest), Register callbacks | wow-theme-artist |
| 12 | Guild events uit C_Calendar in DT_events (DataStore_Agenda patroon, kennisbank) | wow-addon-architect |
| 13 | Weekly reset via GetCVar("portal") patroon voor delves | wow-db-migrator |
| 14 | SavedVariables rename DelveTrackerDB→WowTrackerDB | wow-db-migrator (v4.0) |

## Werkwijze
E�n fase-item per sessie · analyse eerst · in-game test vóór volgende item ·
elke sessie eindigt met kennisbank-update + push.


---

# FASE 4 — NIEUW (Midnight Security Compliance, bron: 12.0.5 analyse-PDF)
Toegevoegd 2026-06-12 · zie project-brain: midnight-security-model.md

| # | Taak | Skill | Prio |
|---|---|---|---|
| 4.1 | CreateFramePool refactor: roster cards + currency tiles | wow-addon-architect | MIDDEL |
| 4.2 | Secret-aware audit (issecretvalue) bij combat-data weergave | wow-poi-auditor | MIDDEL |
| 4.3 | C_RestrictedActions diagnostiek in Debugger | wow-addon-architect | LAAG |
| 4.4 | Mixin/template refactor grote frames | code-architect | LAAG |
| 4.5 | versionTxt hardcoded "v2.7.0" naar centrale versie-constante | wow-ui-polish | LAAG |

# ADVIES VOLGENDE STAPPEN (BigBoss, 2026-06-12)
1. Fase 3.1 Locales/ — grootste gebruikerswaarde
2. Fase 3.3 Guild events C_Calendar — kennis ligt klaar in kennisbank
3. Fase 4.1 pooling — meenemen tijdens 3.x werk
4. Fase 3.4 weekly reset + rest 4.x daarna
