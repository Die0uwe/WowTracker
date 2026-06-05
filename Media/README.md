# WowTracker — Media Assets

Centrale mediamap voor het WowTracker project.
Alle skills en plugins verwijzen naar dit bestand voor asset-paden.

---

## 📁 Mapstructuur

```
Media/
├── Icons/          Addon iconen (vierkant, meerdere groottes)
├── Avatars/        Cirkel-gecropte avatars (transparant PNG)
├── Banners/        Brede banners voor GitHub, CurseForge, Discord
├── Headers/        Compacte headers voor in-game UI en web
├── Backgrounds/    Achtergrond texturen voor de addon UI
├── UI/             In-game UI elementen (buttons, frames, borders)
├── Compass/        Kompas-specifieke assets (naald, ring)
└── Textures/       Algemene WoW .tga texturen voor in-game gebruik
```

---

## 🖼️ Beschikbare Assets

### Icons (vierkant)
| Bestand | Afmeting | Gebruik |
|---|---|---|
| `Icons/WowTracker_Original.png` | 740×694 px | Master bron |
| `Icons/WowTracker_Icon_512.png` | 512×512 px | CurseForge project icon |
| `Icons/WowTracker_Icon_256.png` | 256×256 px | Discord server icon |
| `Icons/WowTracker_Icon_128.png` | 128×128 px | GitHub profile / minimap |
| `Icons/WowTracker_Icon_64.png`  | 64×64 px   | Favicon, kleine toepassingen |
| `Icons/WowTracker_Icon_32.png`  | 32×32 px   | Favicon, tab icon |

### Avatars (cirkel, transparante achtergrond)
| Bestand | Afmeting | Gebruik |
|---|---|---|
| `Avatars/WowTracker_Avatar_256.png` | 256×256 px | Discord bot avatar, forum |
| `Avatars/WowTracker_Avatar_128.png` | 128×128 px | Compacte avatar, CurseBot UI |

### Banners
| Bestand | Afmeting | Gebruik |
|---|---|---|
| `Banners/WowTracker_Banner_1280x640.png` | 1280×640 px | GitHub social preview, Discord |

### Headers
| Bestand | Afmeting | Gebruik |
|---|---|---|
| `Headers/WowTracker_Header_800x200.png` | 800×200 px | README header, web |

---

## 🎮 In-Game Asset Paden (Lua)

```lua
-- Addon base pad
local MEDIA = "Interface\\AddOns\\WowTracker\\Media\\"

-- Icons
local icon_128 = MEDIA .. "Icons\\WowTracker_Icon_128"

-- Compass assets (bestaande TGA bestanden)
local compass_arrow = MEDIA .. "Compass\\Compass_Arrow"
local compass_ring  = MEDIA .. "Compass\\Background_Ring"

-- UI elementen
local progress_bg   = MEDIA .. "UI\\ProgressBar_BG"
local progress_fill = MEDIA .. "UI\\ProgressBar_Fill"
```

> ⚠️ WoW vereist .tga formaat voor in-game texturen.
> PNG bestanden zijn voor GitHub, CurseForge en externe tools.

---

## 🎨 Slayer Alliance Kleurenpalet

| Naam | Hex | WoW kleurcode | Gebruik |
|---|---|---|---|
| Neon Paars | `#bf00ff` | `\|cffbf00ff` | Primaire accent |
| Neon Blauw | `#00dfff` | `\|cff00dfff` | Secundaire accent |
| Gold | `#ccaa00` | `\|cffccaa00` | Headers, titels |
| Dark BG | `#0a0a0f` | `0.04, 0.04, 0.06, 0.96` | Frame achtergronden |
| Sidebar BG | `#0f0a1a` | `0.06, 0.04, 0.10, 1.0` | Sidebar kleur |

---

## 📋 Asset Toevoegen — Protocol

1. Plaats het origineel in de juiste submap
2. Voeg een rij toe aan de tabel hierboven
3. Vermeld: bestandsnaam, afmeting, gebruik
4. Commit met prefix `assets:` bv. `assets: add PreyTracker compass arrow TGA`

