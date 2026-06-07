# WowTracker — Changelog

## v2.7.0 — 2026-06-07

### Core (WowTracker.lua — voorheen DelveTracker.lua)
- **[NEW]** Breedte vergroot van 420px naar 760px — ruimer, professioneler
- **[NEW]** Event ticker bovenaan — scrollende balk met live world events + live klok
- **[NEW]** Murloc rechtermuisklik menu uitgebreid naar 4 secties: Characters · Trackers · Settings · Systeem
- **[NEW]** Scaling via +/− knoppen in footer (stap 0.05 — traag genoeg voor controle)
- **[NEW]** Positie murloc button en hoofdscherm opgeslagen in DelveTrackerDB
- **[FIX]** GetMoney() — goud nu correct geschreven naar `characters[key].money`
- **[FIX]** PLAYER_MONEY event geregistreerd voor live goud updates
- **[FIX]** UserInfo gepind bovenaan plugin lijst in admin panel
- **[FIX]** Race conditions in DT_SystemTools en DT_HelpGuide (DelveTrackerOptions op load-time)
- **[FIX]** MenuUtil.CreateContextMenu — UIDropDownMenu volledig vervangen
- **[FIX]** Slayer Alliance donker paars thema consistent door hele UI
- **[FIX]** DieOuwe karakter image (Dieouwe.tga) verwerkt in admin panel en guild tab
- **[FIX]** Logo watermark in guild tab rechtsonder

### FRIZQT__.TTF — 67 crashes gefixt
- DT_ClothCounter.lua — 33×
- DT_userinfo.lua — 26×
- DT_Debugger.lua — 3×
- DT_ContentManager.lua — 3×
- DT_CombatAnnouncer.lua — 1×
- DT_QuickSet.lua — 1×

### RegisterPlugin toegevoegd (5 plugins nu zichtbaar in admin panel)
- DT_ClothCounter.lua
- DT_SkinNRare.lua
- DT_CustomAFK.lua
- DT_Debugger.lua
- DT_Lockout.lua

### Prey Tracker (DT_prey_ui.lua)
- **[FIX]** AutoShow verbergt niet meer automatisch — `/prey` toggle werkt altijd, quest of niet
- **[FIX]** CheckAutoShow gebruikt alleen live `GetActivePreyQuest()` API — geen stale `prey.active` check

### Structuur
- **[NEW]** Naam: DelveTracker → WowTracker
- **[NEW]** TOC versie 2.7.0 · Interface 120005
- **[NEW]** XML load volgorde geoptimaliseerd met commentaar secties
- **[NEW]** Media plugin toegevoegd als eigen Plugins/Media/DT_Media.lua

---

## v2.6.1 — 2026-06-01 (DelveTracker)

### DT_preytracker.lua — V3.6
- Cross-zone coordinate conversie via `C_Map.GetWorldPosFromMapPos()`
- Zul'Aman mapID gecorrigeerd: 2437 (was 2394 — outdoor fly-through)
- POI world quest filtering op questID range 91095–91400
- `worldPosCache` cleared op ZONE_CHANGED_NEW_AREA

### DT_Registry.lua — v8.1
- XL frame 1320×750 · karakter index gegroepeerd per klasse
- Currency tooltip: Restored Coffer Keys · Coffer Key Shards · Shard of Dundun · Dawnlight Manaflux
- DT_TooltipModules plugin hook systeem

---

## v2.6.0 — 2026-05-31 (DelveTracker)

### Initiële release WowTracker repo
- Core DelveTracker suite gemigreerd
- 22 plugins geïntegreerd
- Midnight 12.0.5 compatibiliteit

---

*WowTracker wordt actief ontwikkeld door DieOuwe · Slayer Alliance · Sporeggar-EU*  
*Zie README.md voor volledige feature beschrijving en installatie instructies.*
