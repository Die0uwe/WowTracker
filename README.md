<p align="center">
  <img src="Media/Banner.png" alt="WowTracker Banner" width="600"/>
</p>

<h1 align="center">WowTracker — Slayer Alliance Edition</h1>

<p align="center">
  <img src="https://img.shields.io/badge/WoW-Retail%2012.0.5%20Midnight-8a2be2?style=for-the-badge&logo=data:image/png;base64,iVBORw0KGgo=" alt="WoW Version"/>
  <img src="https://img.shields.io/badge/Interface-120005-bf00ff?style=for-the-badge" alt="Interface"/>
  <img src="https://img.shields.io/badge/Status-Active%20Development-00dfff?style=for-the-badge" alt="Status"/>
  <img src="https://img.shields.io/badge/Guild-Slayer%20Alliance-ccaa00?style=for-the-badge" alt="Guild"/>
</p>

---

## 🎯 Wat is WowTracker?

**WowTracker** is een complete World of Warcraft addon suite voor **Retail 12.0.5 (Midnight)**, gebouwd door [DieOuwe](https://dieouwe.nl) voor de guild **Slayer Alliance** op Sporeggar-EU.

Voorheen bekend als **DelveTracker (Slayer Alliance Edition)** — nu uitgegroeid tot een volwaardige multi-plugin suite met unified interface, centrale database en één consistent visueel thema.

---

## ✨ Features

### Core Systeem
- **Centrale Plugin Bus** — één EventBus, alle plugins op één lijn
- **Plugin Control Panel** — elke plugin aan/uit via UI
- **Centrale Database** — `WowTrackerDB` met versie-migraties
- **Unified Shell UI** — CurseBot-geïnspireerde sidebar interface

### Ingebouwde Plugins
| Plugin | Categorie | Beschrijving |
|---|---|---|
| 🎯 **Prey Tracker** | HUD | Kompas-naald HUD naar actieve Prey Hunt quests (Midnight) |
| 📦 **Cloth Counter** | Warband | Warband-breed bijhouden van tailoring materials |
| 🔒 **Lockout** | Tracking | Weekly lockout status alle characters |
| 💰 **Registry** | Tracking | Currency scanner + XL character registry |
| 👥 **Charmory** | Warband | Account-breed karakter overzicht (iLvl, spec, stats) |
| ⚔️ **Combat Announcer** | Utility | Raid/party combat meldingen |
| 🔍 **Tooltip Extra** | Utility | Extra informatie in tooltips |
| 📋 **Content Manager** | Tracking | Content voortgang bijhouden |
| 🔧 **System Tools** | Utility | Addon geheugen, FPS, systeem info |
| 💤 **Custom AFK** | Utility | Aangepast AFK scherm |
| ❓ **Help Guide** | Utility | In-game documentatie |

---

## 🚀 Installatie

### Via CurseForge (aanbevolen)
Zoek op CurseForge naar **"WowTracker Slayer Alliance"** of gebruik de CurseForge client.

### Handmatig
```
1. Download de nieuwste release als .zip
2. Pak uit naar: World of Warcraft/_retail_/Interface/AddOns/
3. Map moet heten: WowTracker
4. Herstart WoW of typ /reload
```

---

## 🎮 Slash Commands

| Command | Actie |
|---|---|
| `/wt` | Open WowTracker hoofdvenster |
| `/wt prey` | Open Prey Tracker HUD |
| `/wt cloth` | Open Cloth Counter |
| `/wt registry` | Open XL Registry |
| `/wt lockout` | Open Lockout overzicht |
| `/wt test [plugin]` | Test een plugin met fake data |
| `/wt debug` | Debug informatie |

---

## 🏗️ Architectuur

```
WowTracker/
├── Core/
│   └── WowTracker.lua          # Core engine, EventBus, Plugin API
├── Plugins/
│   ├── PreyTracker/            # Midnight Prey Hunt kompas HUD
│   ├── ClothCounter/           # Warband tailoring tracker
│   ├── Registry/               # Currency scanner + registry
│   ├── Lockout/                # Weekly lockout tracker
│   ├── Charmory/               # Account-breed karakter overzicht
│   └── [overige plugins]/
├── Media/                      # Texturen, fonts, iconen
├── Docs/                       # Documentatie
├── WowTracker.toc              # Addon manifest
└── WowTracker.xml              # Frame definities
```

---

## 🎨 Visuele Identiteit

WowTracker gebruikt de **Slayer Alliance kleurstijl**:
- **Neon Paars** `#bf00ff` — primaire accentkleur
- **Neon Blauw** `#00dfff` — secundaire accentkleur  
- **Gold** `#ccaa00` — headers en titels
- **Dark Background** `#0a0a0f` — achtergrond frames
- **Font** `Fonts\2002.ttf` — alle addon tekst

---

## 📋 Ontwikkeling

### Versie Status
| Versie | Status | Interface |
|---|---|---|
| v1.0.0 | 🔄 In ontwikkeling | 120005 |
| v0.9.x (DelveTracker) | ✅ Stabiel | 120005 |

### Bijdragen
Dit is een persoonlijk guild-project. Suggesties via [GitHub Issues](https://github.com/Die0uwe/WowTracker/issues).

---

## 📜 Changelog

Zie [CHANGELOG.md](CHANGELOG.md) voor de volledige versiehistorie.

---

## 👤 Auteur

**DieOuwe** · [dieouwe.nl](https://dieouwe.nl) · [Slayer Alliance](https://slayeralliance.com)  
Guild: Slayer Alliance · Realm: Sporeggar-EU

---

<p align="center">
  <em>Gebouwd met ❤️ voor de Slayer Alliance · WoW Midnight 12.0.5</em>
</p>
