# Currencies & Rewards — Midnight 12.0.5 (geverifieerd)

## Midnight Currency IDs

| ID   | Naam                    | Bron / Systeem                              |
|------|-------------------------|---------------------------------------------|
| 3028 | Restored Coffer Keys    | Delves, Great Vault thresholds              |
| 3310 | Coffer Key Shards       | Delve rewards                               |
| 3376 | Shard of Dundun         | Midnight end-game content                   |
| 3378 | Dawnlight Manaflux      | Midnight crafting systeem                   |
| 3383 | Dawncrest 1             | Gear upgrade (tier 1)                       |
| 3341 | Dawncrest 2             | Gear upgrade (tier 2)                       |
| 3343 | Dawncrest 3             | Gear upgrade (tier 3)                       |
| 3345 | Dawncrest 4             | Gear upgrade (tier 4)                       |
| 3347 | Dawncrest 5             | Gear upgrade (tier 5)                       |
| 3377 | Extra currency 1        | —                                           |
| 2803 | Extra currency 2        | —                                           |
| 3392 | Remnant of Anguish      | Prey Hunts — warband-transferable seizoen   |
| 3405 | Field Accolade          | Void Assaults + Ritual Sites (gedeeld)      |
| 3418 | Nebulous Voidcore       | Voidforge patch 12.0.5 bonus-roll           |

## Spend Locations (Silvermoon Bazaar)

```
3405 Field Accolade  → Maren Silverwing / Rae'ana (gear + cosmetics)
3418 Nebulous Voidcore → Decimus (gold / Marl / Dawncrests)
```

## Prey Hunt Rewards

```
- Remnant of Anguish (ID: 3392) — warband-transferable seizoenscurrency
- Dawncrests (gear upgrade currency)
- Restored Coffer Key Shards → Bountiful Delves (Prey = beste bron)
- Anguish Runes (3 types) → exchange bij Construct V'anore
- Voidcore components (Nightmare only) → Voidforge bonus-roll
- Great Vault World Activities credit
- Preyseeker mounts:
    Hubris        = currency only
    Pride         = Hard difficulty achievement
    Nightmare     = seasonal achievement (Nightmare diff)
```

## Profession Knowledge IDs (Midnight)

| SkillLine ID | Professie      | Total Currency | Weekly Currency |
|-------------|----------------|----------------|-----------------|
| 25229       | Jewelcrafting  | 3156           | 3194            |
| 45357       | Inscription    | 3155           | 3195            |
| (alchemy)   | Alchemy        | 3150           | 3189            |
| (BS)        | Blacksmithing  | 3151           | 3199            |
| (enchant)   | Enchanting     | 3152           | 3198            |
| (engineer)  | Engineering    | 3153           | 3197            |
| (herb)      | Herbalism      | 3154           | 3196            |
| (LW)        | Leatherworking | 3157           | 3193            |
| (mining)    | Mining         | 3158           | 3192            |
| (skinning)  | Skinning       | 3159           | 3191            |
| (tailoring) | Tailoring      | 3160           | 3190            |

**Niet in Midnight:**
- 794 = Archaeology (verwijderd)
- 2550 = Cooking (secondary, geen knowledge)
- 131474 = Fishing (secondary, geen knowledge)

## Tailoring Item IDs (Midnight Crafting)

| Item ID | Naam            | Tier          |
|---------|-----------------|---------------|
| 236963  | Bright Linen T2 | —             |
| 236965  | Bright Linen T3 | —             |
| 237015  | Sunfire Silk T2 | —             |
| 237016  | Sunfire Silk T3 | —             |
| 237018  | Arcanoweave T2  | —             |
| 237017  | Arcanoweave T3  | —             |

**Recipe IDs:**
- Sunfire Silk Bolt: 1228060
- Arcanoweave Bolt: 1227926

## Lockout Difficulty IDs

| ID | Label          |
|----|----------------|
| 1  | Normal         |
| 2  | Heroic         |
| 8  | Mythic         |
| 14 | Normal Legacy  |
| 15 | Heroic Legacy  |
| 16 | Mythic Legacy  |
| 17 | LFR            |
| 23 | Mythic         |
| 24 | Timewalking    |
| 33 | Timewalking    |

## Warband Bank Bag IDs

```
Warband Bank: Bag IDs 12–16 (NIET -1 t/m 11!)
Items moeten eerst naar player bags 0–4 voor tradeskill processing.
```

---

## WowTracker Currency Tab (28 currencies, v3.0.x)

### Geïmplementeerd in WT_UpdateCurrency (gesorteerd nieuw→oud)

**Midnight (12.x):**
| ID   | Naam                      |
|------|---------------------------|
| 3028 | Restored Coffer Keys      |
| 3310 | Coffer Key Shards         |
| 3376 | Shard of Dundun           |
| 3378 | Dawnlight Manaflux        |
| 3399 | Unalloyed Abundance       |
| 3403 | Midnight Reputation Token |
| 3390 | Amani Favor               |

**War Within (11.x):**
| ID   | Naam                      |
|------|---------------------------|
| 2803 | Resonance Crystals        |
| 2778 | Weathered Harbinger Crest |
| 2779 | Carved Harbinger Crest    |
| 2780 | Runed Harbinger Crest     |
| 2781 | Gilded Harbinger Crest    |
| 2815 | Valorstones               |

**⚠ BEKENDE BUG:** ID 2778 stond twee keer in de originele lijst
(Weathered Harbinger Crest EN Undercoin). seenIDs dedup-check lost dit op.

**Dragonflight/Shadowlands/BfA/PvP:** zie code CUR_DEFS_ALL

### UI Details
- Tiles: 44×52px frame, 33px icon (SetSize(33,33))
- Horizontale scroll per karakter rij (ScrollFrame)
- ◀ ▶ pijl knoppen + muiswiel (EnableMouseWheel + OnMouseWheel)
- Live icons via C_CurrencyInfo.GetCurrencyInfo(id).iconFileID
- Filter op naam of expansie via zoekbalk
