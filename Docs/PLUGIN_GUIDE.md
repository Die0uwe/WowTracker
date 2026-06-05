# WowTracker — Plugin Development Guide

## Een nieuwe plugin bouwen

### 1. Map aanmaken
```
Plugins/MijnPlugin/DT_MijnPlugin.lua
```

### 2. Plugin registreren
```lua
local addonName, addonTable = ...

-- Wacht tot de core geladen is
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "WowTracker" then return end
    self:UnregisterAllEvents()

    WowTracker:RegisterPlugin({
        id       = "mijn_plugin",
        name     = "Mijn Plugin",
        version  = "1.0",
        category = "Utility",
        icon     = "🔧",
        enabled  = true,

        scan = function()
            -- Scan logica — wordt centraal aangeroepen
            WowTrackerDB.plugins.mijn_plugin = WowTrackerDB.plugins.mijn_plugin or {}
            -- ... data verzamelen ...
        end,

        events = { "PLAYER_ENTERING_WORLD" },

        buildUI = function(contentFrame)
            -- Bouw UI in de meegegeven contentFrame
            local label = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOPLEFT", 10, -10)
            label:SetText("Hallo WowTracker!")
        end,

        onEnable  = function() print("[MijnPlugin] Ingeschakeld") end,
        onDisable = function() print("[MijnPlugin] Uitgeschakeld") end,
    })
end)
```

### 3. TOC toevoegen
Voeg toe aan `WowTracker.toc`:
```
Plugins\MijnPlugin\DT_MijnPlugin.lua
```

## Categorieën

| Categorie | Gebruik |
|---|---|
| `Tracking` | Data bijhouden (lockouts, currencies, voortgang) |
| `Warband` | Account-brede features (cloth, charmory) |
| `HUD` | In-world overlays (prey kompas, overlay) |
| `Utility` | Tools (AFK, system info, tooltips) |

## Database conventies

Sla plugin data op onder `WowTrackerDB.plugins.jouw_id`:
```lua
WowTrackerDB.plugins.mijn_plugin = {
    lastScan = GetServerTime(),
    data     = { ... }
}
```

Sla karakter-specifieke data op onder `WowTrackerDB.characters[charKey].mijn_plugin`:
```lua
local charKey = UnitName("player").."-"..GetNormalizedRealmName()
WowTrackerDB.characters[charKey].mijn_plugin = { ... }
```
