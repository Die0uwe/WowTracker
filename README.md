# WowTracker — Slayer Alliance Edition

> **WoW: Midnight · Interface 120005 · Build 67314**  
> Multi-plugin warband tracker for World of Warcraft Midnight (12.0.5)

[![Version](https://img.shields.io/badge/version-v2.9.7-a335ee?style=flat-square)](https://github.com/Die0uwe/WowTracker)
[![WoW](https://img.shields.io/badge/WoW-Midnight%2012.0.5-00ccff?style=flat-square)](https://worldofwarcraft.com)
[![Guild](https://img.shields.io/badge/Guild-Slayer%20Alliance-ccaa00?style=flat-square)](https://slayeralliance.com)
[![Themes](https://img.shields.io/badge/Themes-fork%20welcome-44cc66?style=flat-square)](https://github.com/Die0uwe/WowTracker-Themes)
[![i18n](https://img.shields.io/badge/i18n-fork%20welcome-44cc66?style=flat-square)](https://github.com/Die0uwe/WowTracker-i18n)

---

## Features

### Main Interface
- **6-tab UI** — Guild · Delves · Bounty · Roster · Armory · Currency
- **Scrolling event ticker** bovenaan met live klok, world events, Prey Hunt en Abundance
- **Theme selector** (🎨) — SA Dark · ProfBuddy Purple · MailVault Blue · Night Black
- **Language selector** (🌐) — NL · EN · DE · FR · ES
- **Registry B button** — XL karakter index popup
- **Scale knoppen** (+/−) — UI schaal 0.5× tot 2.0×

### Tab 1 — Guild
- Gilde naam en MOTD gecentreerd
- Live online leden lijst rechts met klasse kleur en level
- Guild emblem · Kelsey · DieOuwe afbeeldingen

### Tab 2 — Delves
- **2-koloms layout** — warband karakters alphabetisch verdeeld
- Live zoekbalk met **letter-suggesties dropdown**
- Per karakter: faction · klasse icoon · naam · spec · iLvl · delve voortgang (0/2 0/4 0/8) · gold
- Klik → opent Charmory Armory

### Tab 3 — Bounty
- **Nemesis** subtab: actieve Nemesis delve + Required Items
- **Abundance info blok**: actieve zone · timer (7h 12m) · Shard of Dundun count
- **Bountiful** subtab: live bountiful detectie via C_AreaPoiInfo
- **Normal** subtab: alle normale delves

### Tab 4 — Roster
- **ProfessionBuddy-stijl kaartjes** (3 kolommen)
- Per kaartje: groot race portrait (52×52) + spec icoon in hoek
- Naam in klasse kleur · Lvl · Spec · iLvl · delve voortgang · gold · profession iconen

### Tab 5 — Armory
- **3D model viewer** links (Charmory)
- **Stats panel** rechts: Karakter · Stats · Currencies · Delves · Goud
- `/charmory` of `/armory` voor standalone popup
- Gear slots met iLvl badges · gold/token count

### Tab 6 — Currency
- Warband currency overzicht per karakter
- Live iconen via `C_CurrencyInfo.GetCurrencyInfo()`
- **Filter op currency naam** of expansie
- Expansies: Midnight → The War Within → Dragonflight → Shadowlands → PvP

---

## Plugins (20+)

| Plugin | Slash | Beschrijving |
|--------|-------|--------------|
| **Charmory** | `/charmory` `/armory` | 3D karakter armory + stats |
| **ClothCounter** | `/cbud` `/cloth` | Stof tracker warband-breed |
| **CombatAnnouncer** | `/cset` | Combat tekst aankondigingen |
| **ContentManager** | — | Content kalender |
| **CustomAFK** | `/dtafk` `/dtgrid` | AFK scherm layout |
| **Debugger** | `/dtdebug` | In-game log & DB viewer |
| **Events** | — | World events + Abundance scanner |
| **ExchangeBot** | `/cbot` | Currency exchange tool |
| **HelpGuide** | `/dthelp` | Dit help scherm |
| **Lockout** | `/dtlockout` | Raid & dungeon lockouts |
| **MailAttach** | `/dtmail` | Quick Attach bij mailbox |
| **Media** | — | Zone media manager |
| **Overlay** | — | UI overlay systeem |
| **PreyTracker** | `/prey` `/pton` `/ptoff` | Prey Hunt kompas HUD |
| **QuickSet** | — | Bounty delve tracker |
| **Registry** | `/crew` | XL karakter index |
| **SkinNRare** | `/snr` `/mt` | Skin & rare tracker |
| **SystemTools** | `/wt-mem` `/wt-reload` | Systeem tools |
| **TooltipExtra** | — | Extra tooltip informatie |
| **UserInfo** | — | Karakter armory & model viewer |

---

## Slash Commands

```
/wt  /dt  /delves          Open/sluit de tracker
/wt1 .. /wt6               Spring direct naar tab
/prey  /pton  /ptoff        Prey Tracker kompas HUD
/crew                       Registry XL karakter index
/charmory  /armory          3D karakter armory
/cbud  /cloth               ClothCounter
/snr  /mt                   SkinNRare tracker
/dtlockout                  Lockout scanner
/cbot                       ExchangeBot
/dtafk  /dtgrid             AFK scherm
/dtdebug                    Debug console
/dthelp                     Help scherm
/dtmail                     Mail Attach panel
/wt-reload                  UI herladen
/wt-mem                     Geheugengebruik
```

---

## Installation

1. Download de [laatste release](https://github.com/Die0uwe/WowTracker/releases)
2. Pak uit in `World of Warcraft/_retail_/Interface/AddOns/`
3. Zorg dat de map `WowTracker/` heet
4. Log in → `/reload`

**Media folder** (`WowTracker/Media/`) bevat custom TGA bestanden — **niet overschrijven** bij update tenzij expliciet aangegeven.

---

## Community & Customization

### 🎨 Maak je eigen guild theme
Fork **[WowTracker-Themes](https://github.com/Die0uwe/WowTracker-Themes)**  
Kopieer `themes/template.lua`, pas kleuren aan, stuur een PR!

### 🌐 Voeg een vertaling toe
Fork **[WowTracker-i18n](https://github.com/Die0uwe/WowTracker-i18n)**  
Kopieer `locales/enUS.lua`, vertaal naar jouw taal, stuur een PR!

---

## Technical

| Eigenschap | Waarde |
|-----------|--------|
| Interface | `## Interface: 120005` |
| Build | `67314` |
| Expansie | Midnight (12.0.5) |
| Lua | 5.1 compatible |
| Bestanden | 23 Lua · 1 TOC · 1 XML |
| Code | ~16.000 regels |
| Afhankelijkheden | Geen externe libs vereist |

### Kritieke API's (Midnight 12.x)
- `C_AreaPoiInfo.GetDelvesForMap()` — abundance & bountiful detectie
- `C_AreaPoiInfo.GetAreaPOISecondsLeft()` — exacte event timer
- `C_CurrencyInfo.GetCurrencyInfo()` — live currency iconen
- `GetSpecializationInfoByID()` — spec iconen
- `MenuUtil.CreateContextMenu()` — context menus (vervangt UIDropDownMenu)
- `C_Container.*` — bag API (Midnight)

### Verboden in Midnight 12.x
- ~~`OptionsSliderTemplate`~~ → `CreateFrame("Slider")` + `SetThumbTexture()`
- ~~`Fonts\FRIZQT__.TTF`~~ → `Fonts2.ttf`
- ~~`UIDropDownMenu_*`~~ → `MenuUtil.CreateContextMenu()`
- ~~`GetAddOnMemoryUsage`~~ → `C_AddOns.GetAddOnMemoryUsage()`

---

## Links

- 🏰 **Slayer Alliance**: [slayeralliance.com](https://slayeralliance.com)
- 💬 **Discord**: [slayeralliance.com/discord](https://slayeralliance.com/discord)
- 🎨 **Themes**: [WowTracker-Themes](https://github.com/Die0uwe/WowTracker-Themes)
- 🌐 **i18n**: [WowTracker-i18n](https://github.com/Die0uwe/WowTracker-i18n)
- 📦 **CurseForge**: [Die0uwe](https://www.curseforge.com/members/dieouwe)

---

*WowTracker is gebouwd door DieOuwe voor Slayer Alliance — Sporeggar EU*  
*Midnight ready · Updated 2026-06-08*
