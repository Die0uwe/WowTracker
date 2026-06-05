# WowTracker — Architectuurdocument v1.0

## Plugin System

Elke plugin registreert zich via de centrale Plugin API:

```lua
WowTracker:RegisterPlugin({
    id       = "cloth_counter",
    name     = "Cloth Counter",
    version  = "2.0",
    category = "Warband",        -- Warband / Tracking / HUD / Utility
    icon     = "📦",
    enabled  = true,
    scan     = MyClothScan,      -- centraal aangeroepen door de scanner pool
    events   = {"BAG_UPDATE"},   -- plugin-specifieke extra events
    buildUI  = MyClothUI,        -- bouwt content in de shell content-area
    onEnable = function() end,
    onDisable= function() end,
})
```

## EventBus

Één centrale EventBus vervangt alle losse frame:RegisterEvent() calls:

```lua
WowTracker:On("PLAYER_LOGIN", function(event, ...)
    -- plugin-specifieke login logica
end)
```

## Database Structuur (WowTrackerDB v1)

```lua
WowTrackerDB = {
    version  = 1,
    settings = {
        shellPos = { x=0, y=0 },
        plugins  = { cloth=true, prey=true, ... }
    },
    characters = {
        ["Naam-Realm"] = {
            class, spec, ilvl, level, faction,
            currencies = { [3028]=42, ... },
            delves     = { ... },
            cloth      = { bolts=42, ... },
        }
    },
    plugins = {
        cloth    = { ... },
        prey     = { needleOffset=0.0, ... },
        lockout  = { ... },
        registry = { ... },
    }
}
```

## Kompas Formule (HEILIG — NOOIT WIJZIGEN)

```lua
local angle    = math.atan2(dx, -dy)
local relative = angle - GetPlayerFacing()
relative       = relative % (math.pi * 2)
needle:SetRotation(-relative + needleOffset)
```

Compass_Arrow.tga wijst OMHOOG (North). Elke andere formulering breekt de richting.

## Bekende Midnight 12.0.5 Beperkingen

| Verboden | Vervanging |
|---|---|
| `OptionsSliderTemplate` | `CreateFrame("Slider")` + handmatige thumb |
| `Fonts\FRIZQT__.TTF` | `Fonts\2002.ttf` |
| `UIDropDownMenu_*` | `MenuUtil.CreateContextMenu()` |
| `GetCurrencyInfo(id)` | `C_CurrencyInfo.GetCurrencyInfo(id)` |
| `GetSpellInfo(id)` | `C_Spell.GetSpellInfo(id)` |
| `getglobal()` | `_G["naam"]` |
