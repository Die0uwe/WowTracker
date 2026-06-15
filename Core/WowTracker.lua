-- ============================================================================
-- DelveTracker — Core v17.0 (Slayer Alliance Edition)
-- Retail 12.0.5 / Build 67314 (Midnight)
-- Rebuilt: 2026-06-07
-- Changes v17.0:
--   [NEW] Breedte 760px (was 420px) — ruimer, professioneler
--   [NEW] Event ticker bovenaan — scrollende balk met live events + klok
--   [FIX] GetMoney() schrijft naar characters[key].money + PLAYER_MONEY event
--   [FIX] Slayer Alliance donker paars thema consistent
--   [FIX] Scaling via +/- knoppen — SCALE_STEP 0.05, traag genoeg
--   [FIX] Scrollbar Tab2 correct verankerd
--   [FIX] Tab3 PluginArea correct verankerd
--   [FIX] MenuUtil.CreateContextMenu (UIDropDownMenu weg in 12.x)
--   [FIX] UserInfo bovenaan plugin lijst (gepind)
--   [FIX] Positie murloc + main window opgeslagen in DB
-- ============================================================================
local addonName, addonTable = ...

-- Database
DelveTrackerDB          = DelveTrackerDB or {}
DelveTrackerDB.characters   = DelveTrackerDB.characters or {}
DelveTrackerDB.PluginStates = DelveTrackerDB.PluginStates or {}

-- Core API
DelveTracker = { Plugins = {}, Version = "2.7.0-12.0.5.67314" }
function DelveTracker:RegisterPlugin(name, func)
    self.Plugins[name] = func
end

-- Kleuren & font
local SA_GOLD   = "|cffccaa00"
local SA_PURPLE = "|cffa335ee"
local SA_BLUE   = "|cff00ccff"
local SA_GREY   = "|cff887799"
local C_2002    = "Fonts\\2002.ttf"
local WT_VERSION = "3.5.4"   -- v3.5.4: 3D model achter tegels + TGA header icons

-- ════════════════════════════════════════════════════════════════════
-- TAAL / LANGUAGE SYSTEEM v3.2.0 (Fase 3.1 — VOLLEDIG)
-- Bovenaan zodat WT_T() overal beschikbaar is. Statische labels worden
-- ververst door WT_ApplyLanguage; dynamische teksten (tooltips, status)
-- roepen WT_T() aan op bouw-moment → automatisch juiste taal.
-- ════════════════════════════════════════════════════════════════════
local WT_LANG = {
["Nederlands"] = {
    TAB_GUILD="GUILD", TAB_DELVES="DELVES", TAB_BOUNTY="BOUNTY",
    TAB_ROSTER="ROSTER", TAB_ARMORY="ARMORY", TAB_CURRENCY="VALUTA",
    MOTD_LABEL="─── Bericht van de dag ───", NO_GUILD="Geen guild",
    NO_GUILD_MEMBER="Geen guild lid.", NO_MOTD="Geen MOTD ingesteld.",
    LOADING="Laden...", ONLINE_HDR="Online leden",
    TICKER_TITLE="Ticker inhoud", TICK_EVENTS="World Events (actief + aankomend)",
    TICK_PREY="Prey Hunt status", TICK_GUILD="Guild online teller",
    TICK_TIME="Server tijd", ALL_ON="Alles aan", ALL_OFF="Alles uit",
    THEME_TITLE="Thema kiezen", LANG_TITLE="Taal / Language",
    THEME_SET="Thema", LANG_SET="Taal",
    ROSTER_HDR="Karakter Index", ROSTER_HINT="(klik = Armory)",
    CUR_HDR="Warband Currencies", CUR_HINT="(alle karakters)",
    CUR_FILTER="Filter currency naam...", NONE_ON_CHAR="Geen op dit karakter",
    ARMORY_LOADING="Armory laadt... gebruik /charmory eenmalig",
    SCALE="Schaal", ADMIN_TITLE="WowTracker Admin",
    UI_SCALE="UI schaal", MURLOC_SCALE="Murloc schaal",
    COMBAT_ALERT="Combat alert", ON="AAN", OFF="UIT",
    PLUGINS="Plugins", PLUGINS_HINT="(uit = verborgen na /reload)",
    CHARS="chars", WARBAND_GOLD="warband gold", LVL="Lvl",
    -- QuickSet (Bounty tab) v3.2.1
    QS_BOUNTIFUL="Bountiful Delve", QS_NEMESIS="Nemesis Delve", QS_DELVE="Delve",
    QS_AB_ACTIVE="Abundant Harvest actief: ", QS_REMAINING="Resterend: ",
    QS_SHARD="Shard of Dundun: ", QS_VENDOR="Chip vendor: ",
    QS_FARM="Farm route: doe de Nemesis delve in de actieve zone",
    QS_AB_INACTIVE=" (Abundance niet actief)",
    QS_OPEN_MAP="open wereldkaart met pin.", QS_POI_404="Live delve POI niet gevonden; ID fallback.",
    QS_STORY="Story: ", QS_COMPLETED=" voltooid", QS_ACH_DONE="Achievement voltooid!",
    QS_COFFERS="Coffers: ", QS_OPENED=" geopend",
    QS_NEM_DEAD="Nemesis verslagen!", QS_NEM_ACTIVE="Nemesis actief",
    QS_BEACON="Beacon of Hope vereist", QS_BENEFITS="Bountiful voordelen:",
    QS_BEN1=" + Bountiful Coffer (extra loot)", QS_BEN2=" + Extra Valeera XP",
    QS_DONE="Klaar", QS_LOADING="Laden...", QS_WB_REP="Warband Reputatie",
    QS_MAX="MAX level bereikt!", QS_TIP="Tip: Bountiful Delves geven bonus Valeera XP!",
    QS_LEVEL="Level %d / %d", QS_NA="Niet beschikbaar", QS_NORMAL="Normal",
    QS_REQ_ITEMS="Benodigde Items", QS_AB_DELVE="Abundance Delve",
    QS_AB_ON="Abundance Actief: ",
    CM_CHARACTER="KARAKTER", CM_CLASS="Klasse", CM_SPEC="Spec",
    CM_LEVEL="Level", CM_ILVL="iLvl", CM_GUILD="Guild",
    CM_STATS="STATS", CM_STAMINA="Stamina", CM_STRENGTH="Kracht",
    CM_AGILITY="Behendigheid", CM_INTELLECT="Intellect", CM_ARMOR="Pantser",
    CM_CURRENCIES="VALUTA", CM_DELVES_WEEK="DELVES DEZE WEEK",
    CM_GOLD="GOUD", CM_TOTAL="Totaal",
    GE_HDR="Aankomende guild events", GE_TODAY="vandaag", GE_NONE="Geen geplande events",
    -- i18n ronde 3 (Registry/Lockout/HelpGuide) v3.3.0
    RG_TITLE="KARAKTER INDEX",
    LK_RAID="Raid Lockouts", LK_NONE="-- geen actieve lockouts --",
    LK_PROF="Professies", LK_SEC="Secundair",
    HG_TITLE="Help Gids", HG_BASIC="BASISBEDIENING:", HG_TABS="TABS:",
    HG_SLASH="SLASH COMMANDS:", HG_DISCORD="DISCORD:",
    HG_B1="Klik de Murloc om de tracker te openen.",
    HG_B2="Rechtermuisklik + sleep om te verplaatsen.",
    HG_B3="Tandwiel bovenaan voor instellingen.",
    HG_T1="Guild — gilde info + MOTD + online leden",
    HG_T2="Delves — warband karakter lijst + voortgang",
    HG_T3="Bounty — Nemesis/Bountiful/Normal delve tracker",
    HG_T4="Roster — karakter index (klik = Armory)",
    HG_T5="Armory — 3D model + gear + stats",
    HG_T6="Currency — alle currencies per karakter",
    HG_S1="Open/sluit tracker", HG_S2="Tab direct openen",
    HG_S3="Roster/Armory/Currency", HG_S4="Prey Tracker HUD",
    HG_S5="Registry XL", HG_S6="ClothCounter", HG_S7="SkinNRare",
    HG_S8="Lockout scanner", HG_S9="Exchange Bot", HG_S10="AFK scherm",
    HG_S11="Debug console", HG_S12="Dit scherm",
    HG_S13="Geheugengebruik", HG_S14="UI herladen",
    -- Murloc / Minimap tooltips v3.5.5
    MURL_TOOLTIP="Links: open/sluit · Rechts: menu · Sleep: verplaats",
    MMAP_CHARS="Karakters:", MMAP_GOLD="Warband gold:",
    MMAP_LEFT="Links", MMAP_LEFT_ACT="Open/sluit WowTracker",
    MMAP_RIGHT="Rechts", MMAP_RIGHT_ACT="Admin panel",
    MMAP_LOADED="Minimap icon geladen via LibDBIcon.",
    -- DB backup/restore tooltips
    DB_BACKUP_TITLE="Database Backup",
    DB_BACKUP_INFO="Kopieert de volledige DB naar WowTrackerDB_Backup.",
    DB_BACKUP_PATH="Bestand: WTF/Account/.../SavedVariables.lua",
    DB_BACKUP_LAST="Laatste backup: ",
    DB_BACKUP_NONE="Nog geen backup aanwezig.",
    DB_RESTORE_TITLE="Database Restore",
    DB_RESTORE_INFO="Herstelt DB vanuit de laatste backup.",
    DB_RESTORE_WARN="Overschrijft huidige data! Vereist bevestiging.",
    DB_RESTORE_FROM="Backup van: ",
    DB_NO_BACKUP="Geen backup beschikbaar.",
    DB_NO_DB="Geen database.",
    DB_NO_ORPHAN="Geen orphaned of dubbele entries gevonden.",
    DB_WIPED="DB gewist. /reload om te herladen.",
    -- SystemTools
    SYS_TITLE="System & Combat Tools",
    SYS_SCROLL="Scroll met muiswiel voor meer opties.",
    SYS_MURLOC_RESET="Murloc positie gereset.",
    -- PreyTracker strings
    PT_SETTINGS="Prey Tracker Instellingen",
    PT_OPEN_SET="Klik om instellingenpaneel te openen",
    PT_CMD_CAL="/prey cal  — naaldoffset instellen",
    PT_RESET_OFFSET="Reset naaldoffset naar 0°",
    PT_RESET_DEFAULTS="Reset alles naar standaard",
    PT_ENABLED="Prey Tracker ingeschakeld",
    PT_POS_RESET="Positie gereset.",
    -- SkinNRare
    SNR_LURE_TIP="Hover = preview · Klik = plaatsingsmodus",
    SNR_LURE_CLICK="Klik om lure plaatsingsmodus te starten.",
    SNR_LURE_PLACE="Klik dan op de grond om te plaatsen.",
    -- MailAttach
    MA_NO_ITEMS="Geen items gevonden",
},
["English"] = {
    TAB_GUILD="GUILD", TAB_DELVES="DELVES", TAB_BOUNTY="BOUNTY",
    TAB_ROSTER="ROSTER", TAB_ARMORY="ARMORY", TAB_CURRENCY="CURRENCY",
    MOTD_LABEL="─── Message of the Day ───", NO_GUILD="Not in a guild",
    NO_GUILD_MEMBER="Not a guild member.", NO_MOTD="No MOTD set.",
    LOADING="Loading...", ONLINE_HDR="Online members",
    TICKER_TITLE="Ticker content", TICK_EVENTS="World Events (active + upcoming)",
    TICK_PREY="Prey Hunt status", TICK_GUILD="Guild online counter",
    TICK_TIME="Server time", ALL_ON="All on", ALL_OFF="All off",
    THEME_TITLE="Choose theme", LANG_TITLE="Taal / Language",
    THEME_SET="Theme", LANG_SET="Language",
    ROSTER_HDR="Character Index", ROSTER_HINT="(click = Armory)",
    CUR_HDR="Warband Currencies", CUR_HINT="(all characters)",
    CUR_FILTER="Filter currency name...", NONE_ON_CHAR="None on this character",
    ARMORY_LOADING="Armory loading... use /charmory once",
    SCALE="Scale", ADMIN_TITLE="WowTracker Admin",
    UI_SCALE="UI scale", MURLOC_SCALE="Murloc scale",
    COMBAT_ALERT="Combat alert", ON="ON", OFF="OFF",
    PLUGINS="Plugins", PLUGINS_HINT="(off = hidden after /reload)",
    CHARS="chars", WARBAND_GOLD="warband gold", LVL="Lvl",
    QS_BOUNTIFUL="Bountiful Delve", QS_NEMESIS="Nemesis Delve", QS_DELVE="Delve",
    QS_AB_ACTIVE="Abundant Harvest active: ", QS_REMAINING="Remaining: ",
    QS_SHARD="Shard of Dundun: ", QS_VENDOR="Chip vendor: ",
    QS_FARM="Farm route: do the Nemesis delve in the active zone",
    QS_AB_INACTIVE=" (Abundance not active)",
    QS_OPEN_MAP="open world map with pin.", QS_POI_404="Live delve POI not found; using ID fallback.",
    QS_STORY="Story: ", QS_COMPLETED=" completed", QS_ACH_DONE="Achievement completed!",
    QS_COFFERS="Coffers: ", QS_OPENED=" opened",
    QS_NEM_DEAD="Nemesis defeated!", QS_NEM_ACTIVE="Nemesis active",
    QS_BEACON="Beacon of Hope required", QS_BENEFITS="Bountiful benefits:",
    QS_BEN1=" + Bountiful Coffer (extra loot)", QS_BEN2=" + Extra Valeera XP",
    QS_DONE="Done", QS_LOADING="Loading...", QS_WB_REP="Warband Reputation",
    QS_MAX="MAX level reached!", QS_TIP="Tip: Bountiful Delves give bonus Valeera XP!",
    QS_LEVEL="Level %d / %d", QS_NA="Not available", QS_NORMAL="Normal",
    QS_REQ_ITEMS="Required Items", QS_AB_DELVE="Abundance Delve",
    QS_AB_ON="Abundance Active: ",
    CM_CHARACTER="CHARACTER", CM_CLASS="Class", CM_SPEC="Spec",
    CM_LEVEL="Level", CM_ILVL="iLvl", CM_GUILD="Guild",
    CM_STATS="STATS", CM_STAMINA="Stamina", CM_STRENGTH="Strength",
    CM_AGILITY="Agility", CM_INTELLECT="Intellect", CM_ARMOR="Armor",
    CM_CURRENCIES="CURRENCIES", CM_DELVES_WEEK="DELVES THIS WEEK",
    CM_GOLD="GOLD", CM_TOTAL="Total",
    GE_HDR="Upcoming guild events", GE_TODAY="today", GE_NONE="No scheduled events",
    RG_TITLE="CHARACTER INDEX",
    LK_RAID="Raid Lockouts", LK_NONE="-- no active lockouts --",
    LK_PROF="Professions", LK_SEC="Secondary",
    HG_TITLE="Help Guide", HG_BASIC="BASIC CONTROLS:", HG_TABS="TABS:",
    HG_SLASH="SLASH COMMANDS:", HG_DISCORD="DISCORD:",
    HG_B1="Click the Murloc to open the tracker.",
    HG_B2="Right-click + drag to move.",
    HG_B3="Gear icon at the top for settings.",
    HG_T1="Guild — guild info + MOTD + online members",
    HG_T2="Delves — warband character list + progress",
    HG_T3="Bounty — Nemesis/Bountiful/Normal delve tracker",
    HG_T4="Roster — character index (click = Armory)",
    HG_T5="Armory — 3D model + gear + stats",
    HG_T6="Currency — all currencies per character",
    HG_S1="Open/close tracker", HG_S2="Open tab directly",
    HG_S3="Roster/Armory/Currency", HG_S4="Prey Tracker HUD",
    HG_S5="Registry XL", HG_S6="ClothCounter", HG_S7="SkinNRare",
    HG_S8="Lockout scanner", HG_S9="Exchange Bot", HG_S10="AFK screen",
    HG_S11="Debug console", HG_S12="This screen",
    HG_S13="Memory usage", HG_S14="Reload UI",
    -- Murloc / Minimap tooltips v3.5.5
    MURL_TOOLTIP="Left: open/close · Right: menu · Drag: move",
    MMAP_CHARS="Characters:", MMAP_GOLD="Warband gold:",
    MMAP_LEFT="Left", MMAP_LEFT_ACT="Open/close WowTracker",
    MMAP_RIGHT="Right", MMAP_RIGHT_ACT="Admin panel",
    MMAP_LOADED="Minimap icon loaded via LibDBIcon.",
    -- DB backup/restore tooltips
    DB_BACKUP_TITLE="Database Backup",
    DB_BACKUP_INFO="Copies the full DB to WowTrackerDB_Backup.",
    DB_BACKUP_PATH="File: WTF/Account/.../SavedVariables.lua",
    DB_BACKUP_LAST="Last backup: ",
    DB_BACKUP_NONE="No backup available yet.",
    DB_RESTORE_TITLE="Database Restore",
    DB_RESTORE_INFO="Restores DB from the last backup.",
    DB_RESTORE_WARN="Overwrites current data! Requires confirmation.",
    DB_RESTORE_FROM="Backup from: ",
    DB_NO_BACKUP="No backup available.",
    DB_NO_DB="No database found.",
    DB_NO_ORPHAN="No orphaned or duplicate entries found.",
    DB_WIPED="Database wiped. /reload to apply.",
    -- SystemTools
    SYS_TITLE="System & Combat Tools",
    SYS_SCROLL="Scroll with mouse wheel for more options.",
    SYS_MURLOC_RESET="Murloc position reset.",
    -- PreyTracker strings
    PT_SETTINGS="Prey Tracker Settings",
    PT_OPEN_SET="Click to open settings panel",
    PT_CMD_CAL="/prey cal  — needle offset only",
    PT_RESET_OFFSET="Reset needle offset to 0°",
    PT_RESET_DEFAULTS="Reset all settings to default",
    PT_ENABLED="Prey Tracker enabled",
    PT_POS_RESET="Position reset.",
    -- SkinNRare
    SNR_LURE_TIP="Hover to preview · Click to enter placement mode",
    SNR_LURE_CLICK="Click to enter lure placement mode.",
    SNR_LURE_PLACE="Then click the ground to place.",
    -- MailAttach
    MA_NO_ITEMS="No items found",
},
["Deutsch"] = {
    TAB_GUILD="GILDE", TAB_DELVES="TIEFEN", TAB_BOUNTY="KOPFGELD",
    TAB_ROSTER="KADER", TAB_ARMORY="KAMMER", TAB_CURRENCY="WÄHRUNG",
    MOTD_LABEL="─── Nachricht des Tages ───", NO_GUILD="Keine Gilde",
    NO_GUILD_MEMBER="Kein Gildenmitglied.", NO_MOTD="Keine MOTD gesetzt.",
    LOADING="Laden...", ONLINE_HDR="Online Mitglieder",
    TICKER_TITLE="Ticker Inhalt", TICK_EVENTS="Weltereignisse (aktiv + kommend)",
    TICK_PREY="Prey Hunt Status", TICK_GUILD="Gilde online Zähler",
    TICK_TIME="Serverzeit", ALL_ON="Alles an", ALL_OFF="Alles aus",
    THEME_TITLE="Thema wählen", LANG_TITLE="Taal / Language",
    THEME_SET="Thema", LANG_SET="Sprache",
    ROSTER_HDR="Charakter-Index", ROSTER_HINT="(Klick = Kammer)",
    CUR_HDR="Kriegsmeute Währungen", CUR_HINT="(alle Charaktere)",
    CUR_FILTER="Währungsname filtern...", NONE_ON_CHAR="Keine auf diesem Charakter",
    ARMORY_LOADING="Kammer lädt... nutze /charmory einmal",
    SCALE="Skalierung", ADMIN_TITLE="WowTracker Admin",
    UI_SCALE="UI Skalierung", MURLOC_SCALE="Murloc Skalierung",
    COMBAT_ALERT="Kampf-Alarm", ON="AN", OFF="AUS",
    PLUGINS="Plugins", PLUGINS_HINT="(aus = versteckt nach /reload)",
    CHARS="Chars", WARBAND_GOLD="Kriegsmeute Gold", LVL="Stufe",
    QS_BOUNTIFUL="Ergiebige Tiefe", QS_NEMESIS="Nemesis Tiefe", QS_DELVE="Tiefe",
    QS_AB_ACTIVE="Reiche Ernte aktiv: ", QS_REMAINING="Verbleibend: ",
    QS_SHARD="Splitter von Dundun: ", QS_VENDOR="Chip Händler: ",
    QS_FARM="Farmroute: mache die Nemesis-Tiefe in der aktiven Zone",
    QS_AB_INACTIVE=" (Abundance nicht aktiv)",
    QS_OPEN_MAP="Weltkarte mit Pin öffnen.", QS_POI_404="Live Tiefen-POI nicht gefunden; ID Fallback.",
    QS_STORY="Story: ", QS_COMPLETED=" abgeschlossen", QS_ACH_DONE="Erfolg abgeschlossen!",
    QS_COFFERS="Truhen: ", QS_OPENED=" geöffnet",
    QS_NEM_DEAD="Nemesis besiegt!", QS_NEM_ACTIVE="Nemesis aktiv",
    QS_BEACON="Leuchtfeuer der Hoffnung nötig", QS_BENEFITS="Ergiebige Vorteile:",
    QS_BEN1=" + Ergiebige Truhe (Extra-Beute)", QS_BEN2=" + Extra Valeera EP",
    QS_DONE="Fertig", QS_LOADING="Laden...", QS_WB_REP="Kriegsmeute Ruf",
    QS_MAX="MAX Stufe erreicht!", QS_TIP="Tipp: Ergiebige Tiefen geben Bonus Valeera EP!",
    QS_LEVEL="Stufe %d / %d", QS_NA="Nicht verfügbar", QS_NORMAL="Normal",
    QS_REQ_ITEMS="Benötigte Items", QS_AB_DELVE="Abundance Tiefe",
    QS_AB_ON="Abundance Aktiv: ",
    CM_CHARACTER="CHARAKTER", CM_CLASS="Klasse", CM_SPEC="Spez",
    CM_LEVEL="Stufe", CM_ILVL="GS", CM_GUILD="Gilde",
    CM_STATS="WERTE", CM_STAMINA="Ausdauer", CM_STRENGTH="Stärke",
    CM_AGILITY="Beweglichkeit", CM_INTELLECT="Intelligenz", CM_ARMOR="Rüstung",
    CM_CURRENCIES="WÄHRUNGEN", CM_DELVES_WEEK="TIEFEN DIESE WOCHE",
    CM_GOLD="GOLD", CM_TOTAL="Gesamt",
    GE_HDR="Kommende Gildenevents", GE_TODAY="heute", GE_NONE="Keine geplanten Events",
    RG_TITLE="CHARAKTER-INDEX",
    LK_RAID="Schlachtzug-Sperren", LK_NONE="-- keine aktiven Sperren --",
    LK_PROF="Berufe", LK_SEC="Sekundär",
    HG_TITLE="Hilfe", HG_BASIC="GRUNDSTEUERUNG:", HG_TABS="TABS:",
    HG_SLASH="SLASH-BEFEHLE:", HG_DISCORD="DISCORD:",
    HG_B1="Klicke den Murloc um den Tracker zu öffnen.",
    HG_B2="Rechtsklick + ziehen zum Verschieben.",
    HG_B3="Zahnrad oben für Einstellungen.",
    HG_T1="Gilde — Gildeninfo + MOTD + Online-Mitglieder",
    HG_T2="Tiefen — Kriegsmeute Charakterliste + Fortschritt",
    HG_T3="Kopfgeld — Nemesis/Ergiebig/Normal Tiefen-Tracker",
    HG_T4="Kader — Charakter-Index (Klick = Kammer)",
    HG_T5="Kammer — 3D-Modell + Ausrüstung + Werte",
    HG_T6="Währung — alle Währungen pro Charakter",
    HG_S1="Tracker öffnen/schließen", HG_S2="Tab direkt öffnen",
    HG_S3="Kader/Kammer/Währung", HG_S4="Prey Tracker HUD",
    HG_S5="Registry XL", HG_S6="ClothCounter", HG_S7="SkinNRare",
    HG_S8="Sperren-Scanner", HG_S9="Exchange Bot", HG_S10="AFK-Bildschirm",
    HG_S11="Debug-Konsole", HG_S12="Dieser Bildschirm",
    HG_S13="Speichernutzung", HG_S14="UI neu laden",
    -- Murloc / Minimap tooltips v3.5.5
    MURL_TOOLTIP="Links: öffnen/schließen · Rechts: Menü · Ziehen: verschieben",
    MMAP_CHARS="Charaktere:", MMAP_GOLD="Kriegsmeute Gold:",
    MMAP_LEFT="Links", MMAP_LEFT_ACT="WowTracker öffnen/schließen",
    MMAP_RIGHT="Rechts", MMAP_RIGHT_ACT="Admin-Panel",
    MMAP_LOADED="Minimap-Icon über LibDBIcon geladen.",
    DB_BACKUP_TITLE="Datenbank Backup", DB_BACKUP_INFO="Kopiert die vollständige DB.",
    DB_BACKUP_LAST="Letztes Backup: ", DB_BACKUP_NONE="Noch kein Backup vorhanden.",
    DB_RESTORE_TITLE="Datenbank Wiederherstellen", DB_RESTORE_INFO="Stellt DB wieder her.",
    DB_RESTORE_WARN="Überschreibt Daten! Bestätigung nötig.", DB_RESTORE_FROM="Backup vom: ",
    DB_NO_BACKUP="Kein Backup.", DB_NO_DB="Keine Datenbank.", DB_NO_ORPHAN="Keine Duplikate.",
    DB_WIPED="DB gelöscht. /reload.", SYS_TITLE="System- & Kampf-Tools",
    SYS_SCROLL="Mausrad scrollen für mehr.", SYS_MURLOC_RESET="Murloc-Position zurückgesetzt.",
    PT_SETTINGS="Prey Tracker Einstellungen", PT_OPEN_SET="Klicken um Einstellungen zu öffnen",
    PT_CMD_CAL="/prey cal — Nadel-Offset", PT_RESET_OFFSET="Nadel-Offset zurücksetzen",
    PT_RESET_DEFAULTS="Einstellungen zurücksetzen", PT_ENABLED="Prey Tracker aktiviert",
    PT_POS_RESET="Position zurückgesetzt.", SNR_LURE_TIP="Hover = Vorschau · Klick = Platzierung",
    SNR_LURE_CLICK="Lockmittel platzieren.", SNR_LURE_PLACE="Auf Boden klicken.",
    MA_NO_ITEMS="Keine Gegenstände gefunden",
},
["Français"] = {
    TAB_GUILD="GUILDE", TAB_DELVES="GOUFFRES", TAB_BOUNTY="PRIME",
    TAB_ROSTER="EFFECTIF", TAB_ARMORY="ARSENAL", TAB_CURRENCY="MONNAIE",
    MOTD_LABEL="─── Message du Jour ───", NO_GUILD="Sans guilde",
    NO_GUILD_MEMBER="Pas membre de guilde.", NO_MOTD="Aucun MOTD défini.",
    LOADING="Chargement...", ONLINE_HDR="Membres en ligne",
    TICKER_TITLE="Contenu du ticker", TICK_EVENTS="Événements (actifs + à venir)",
    TICK_PREY="Statut Prey Hunt", TICK_GUILD="Compteur guilde en ligne",
    TICK_TIME="Heure serveur", ALL_ON="Tout activer", ALL_OFF="Tout désactiver",
    THEME_TITLE="Choisir un thème", LANG_TITLE="Taal / Language",
    THEME_SET="Thème", LANG_SET="Langue",
    ROSTER_HDR="Index des personnages", ROSTER_HINT="(clic = Arsenal)",
    CUR_HDR="Monnaies du Bataillon", CUR_HINT="(tous les personnages)",
    CUR_FILTER="Filtrer le nom...", NONE_ON_CHAR="Aucune sur ce personnage",
    ARMORY_LOADING="Arsenal en chargement... utilisez /charmory une fois",
    SCALE="Échelle", ADMIN_TITLE="WowTracker Admin",
    UI_SCALE="Échelle UI", MURLOC_SCALE="Échelle Murloc",
    COMBAT_ALERT="Alerte combat", ON="OUI", OFF="NON",
    PLUGINS="Plugins", PLUGINS_HINT="(off = caché après /reload)",
    CHARS="persos", WARBAND_GOLD="or du bataillon", LVL="Niv",
    QS_BOUNTIFUL="Gouffre abondant", QS_NEMESIS="Gouffre Némésis", QS_DELVE="Gouffre",
    QS_AB_ACTIVE="Récolte abondante active : ", QS_REMAINING="Restant : ",
    QS_SHARD="Éclat de Dundun : ", QS_VENDOR="Vendeur de jetons : ",
    QS_FARM="Route de farm : faites le gouffre Némésis dans la zone active",
    QS_AB_INACTIVE=" (Abundance inactif)",
    QS_OPEN_MAP="ouvrir la carte avec repère.", QS_POI_404="POI introuvable ; repli sur ID.",
    QS_STORY="Histoire : ", QS_COMPLETED=" terminé", QS_ACH_DONE="Haut fait terminé !",
    QS_COFFERS="Coffres : ", QS_OPENED=" ouverts",
    QS_NEM_DEAD="Némésis vaincu !", QS_NEM_ACTIVE="Némésis actif",
    QS_BEACON="Balise d'espoir requise", QS_BENEFITS="Avantages abondants :",
    QS_BEN1=" + Coffre abondant (butin extra)", QS_BEN2=" + XP Valeera extra",
    QS_DONE="Fini", QS_LOADING="Chargement...", QS_WB_REP="Réputation du Bataillon",
    QS_MAX="Niveau MAX atteint !", QS_TIP="Astuce : les gouffres abondants donnent du XP Valeera bonus !",
    QS_LEVEL="Niveau %d / %d", QS_NA="Indisponible", QS_NORMAL="Normal",
    QS_REQ_ITEMS="Objets requis", QS_AB_DELVE="Gouffre Abundance",
    QS_AB_ON="Abundance actif : ",
    CM_CHARACTER="PERSONNAGE", CM_CLASS="Classe", CM_SPEC="Spé",
    CM_LEVEL="Niveau", CM_ILVL="iLvl", CM_GUILD="Guilde",
    CM_STATS="STATS", CM_STAMINA="Endurance", CM_STRENGTH="Force",
    CM_AGILITY="Agilité", CM_INTELLECT="Intelligence", CM_ARMOR="Armure",
    CM_CURRENCIES="MONNAIES", CM_DELVES_WEEK="GOUFFRES CETTE SEMAINE",
    CM_GOLD="OR", CM_TOTAL="Total",
    GE_HDR="Événements de guilde à venir", GE_TODAY="aujourd'hui", GE_NONE="Aucun événement prévu",
    RG_TITLE="INDEX DES PERSONNAGES",
    LK_RAID="Verrouillages de raid", LK_NONE="-- aucun verrouillage actif --",
    LK_PROF="Métiers", LK_SEC="Secondaires",
    HG_TITLE="Guide", HG_BASIC="COMMANDES DE BASE :", HG_TABS="ONGLETS :",
    HG_SLASH="COMMANDES SLASH :", HG_DISCORD="DISCORD :",
    HG_B1="Cliquez sur le Murloc pour ouvrir le tracker.",
    HG_B2="Clic droit + glisser pour déplacer.",
    HG_B3="Engrenage en haut pour les réglages.",
    HG_T1="Guilde — infos guilde + MOTD + membres en ligne",
    HG_T2="Gouffres — liste des personnages + progression",
    HG_T3="Prime — tracker Némésis/Abondant/Normal",
    HG_T4="Effectif — index des personnages (clic = Arsenal)",
    HG_T5="Arsenal — modèle 3D + équipement + stats",
    HG_T6="Monnaie — toutes les monnaies par personnage",
    HG_S1="Ouvrir/fermer le tracker", HG_S2="Ouvrir un onglet",
    HG_S3="Effectif/Arsenal/Monnaie", HG_S4="Prey Tracker HUD",
    HG_S5="Registry XL", HG_S6="ClothCounter", HG_S7="SkinNRare",
    HG_S8="Scanner de verrouillages", HG_S9="Exchange Bot", HG_S10="Écran AFK",
    HG_S11="Console de debug", HG_S12="Cet écran",
    HG_S13="Utilisation mémoire", HG_S14="Recharger l\'UI",
},
["Español"] = {
    TAB_GUILD="HERMANDAD", TAB_DELVES="SIMAS", TAB_BOUNTY="RECOMPENSA",
    TAB_ROSTER="PLANTILLA", TAB_ARMORY="ARMERÍA", TAB_CURRENCY="MONEDA",
    MOTD_LABEL="─── Mensaje del Día ───", NO_GUILD="Sin hermandad",
    NO_GUILD_MEMBER="No es miembro.", NO_MOTD="Sin MOTD.",
    LOADING="Cargando...", ONLINE_HDR="Miembros en línea",
    TICKER_TITLE="Contenido del ticker", TICK_EVENTS="Eventos (activos + próximos)",
    TICK_PREY="Estado Prey Hunt", TICK_GUILD="Contador hermandad",
    TICK_TIME="Hora del servidor", ALL_ON="Todo sí", ALL_OFF="Todo no",
    THEME_TITLE="Elegir tema", LANG_TITLE="Taal / Language",
    THEME_SET="Tema", LANG_SET="Idioma",
    ROSTER_HDR="Índice de personajes", ROSTER_HINT="(clic = Armería)",
    CUR_HDR="Monedas de la Banda", CUR_HINT="(todos los personajes)",
    CUR_FILTER="Filtrar nombre...", NONE_ON_CHAR="Ninguna en este personaje",
    ARMORY_LOADING="Armería cargando... usa /charmory una vez",
    SCALE="Escala", ADMIN_TITLE="WowTracker Admin",
    UI_SCALE="Escala UI", MURLOC_SCALE="Escala Murloc",
    COMBAT_ALERT="Alerta de combate", ON="SÍ", OFF="NO",
    PLUGINS="Plugins", PLUGINS_HINT="(off = oculto tras /reload)",
    CHARS="pjs", WARBAND_GOLD="oro de banda", LVL="Nv",
    QS_BOUNTIFUL="Sima abundante", QS_NEMESIS="Sima Némesis", QS_DELVE="Sima",
    QS_AB_ACTIVE="Cosecha abundante activa: ", QS_REMAINING="Restante: ",
    QS_SHARD="Fragmento de Dundun: ", QS_VENDOR="Vendedor de fichas: ",
    QS_FARM="Ruta: haz la sima Némesis en la zona activa",
    QS_AB_INACTIVE=" (Abundance inactivo)",
    QS_OPEN_MAP="abrir mapa con marcador.", QS_POI_404="POI no encontrado; usando ID.",
    QS_STORY="Historia: ", QS_COMPLETED=" completado", QS_ACH_DONE="¡Logro completado!",
    QS_COFFERS="Cofres: ", QS_OPENED=" abiertos",
    QS_NEM_DEAD="¡Némesis derrotado!", QS_NEM_ACTIVE="Némesis activo",
    QS_BEACON="Faro de esperanza requerido", QS_BENEFITS="Beneficios abundantes:",
    QS_BEN1=" + Cofre abundante (botín extra)", QS_BEN2=" + XP Valeera extra",
    QS_DONE="Hecho", QS_LOADING="Cargando...", QS_WB_REP="Reputación de la Banda",
    QS_MAX="¡Nivel MÁX alcanzado!", QS_TIP="Consejo: ¡las simas abundantes dan XP Valeera extra!",
    QS_LEVEL="Nivel %d / %d", QS_NA="No disponible", QS_NORMAL="Normal",
    QS_REQ_ITEMS="Objetos requeridos", QS_AB_DELVE="Sima Abundance",
    QS_AB_ON="Abundance activo: ",
    CM_CHARACTER="PERSONAJE", CM_CLASS="Clase", CM_SPEC="Espec",
    CM_LEVEL="Nivel", CM_ILVL="iLvl", CM_GUILD="Hermandad",
    CM_STATS="ESTADÍSTICAS", CM_STAMINA="Aguante", CM_STRENGTH="Fuerza",
    CM_AGILITY="Agilidad", CM_INTELLECT="Intelecto", CM_ARMOR="Armadura",
    CM_CURRENCIES="MONEDAS", CM_DELVES_WEEK="SIMAS ESTA SEMANA",
    CM_GOLD="ORO", CM_TOTAL="Total",
    GE_HDR="Próximos eventos de hermandad", GE_TODAY="hoy", GE_NONE="Sin eventos programados",
    RG_TITLE="ÍNDICE DE PERSONAJES",
    LK_RAID="Bloqueos de banda", LK_NONE="-- sin bloqueos activos --",
    LK_PROF="Profesiones", LK_SEC="Secundarias",
    HG_TITLE="Guía de ayuda", HG_BASIC="CONTROLES BÁSICOS:", HG_TABS="PESTAÑAS:",
    HG_SLASH="COMANDOS SLASH:", HG_DISCORD="DISCORD:",
    HG_B1="Haz clic en el Múrloc para abrir el rastreador.",
    HG_B2="Clic derecho + arrastrar para mover.",
    HG_B3="Engranaje arriba para ajustes.",
    HG_T1="Hermandad — info + MOTD + miembros en línea",
    HG_T2="Simas — lista de personajes + progreso",
    HG_T3="Recompensa — rastreador Némesis/Abundante/Normal",
    HG_T4="Plantilla — índice de personajes (clic = Armería)",
    HG_T5="Armería — modelo 3D + equipo + estadísticas",
    HG_T6="Moneda — todas las monedas por personaje",
    HG_S1="Abrir/cerrar rastreador", HG_S2="Abrir pestaña directa",
    HG_S3="Plantilla/Armería/Moneda", HG_S4="Prey Tracker HUD",
    HG_S5="Registry XL", HG_S6="ClothCounter", HG_S7="SkinNRare",
    HG_S8="Escáner de bloqueos", HG_S9="Exchange Bot", HG_S10="Pantalla AFK",
    HG_S11="Consola de debug", HG_S12="Esta pantalla",
    HG_S13="Uso de memoria", HG_S14="Recargar UI",
},
}
local _WT_T = WT_LANG["Nederlands"]

-- Vertaling ophalen (fallback NL → key zelf)
function WT_T(key)
    return (_WT_T and _WT_T[key]) or WT_LANG["Nederlands"][key] or key
end

-- Interne setter — WT_ApplyLanguage (verderop) gebruikt deze
function WT_SetLangTable(lang)
    _WT_T = WT_LANG[lang] or WT_LANG["Nederlands"]
    return _WT_T
end

-- Layout
local UI_W       = 760
local UI_H       = 580
local TICKER_H   = 20
local HEADER_H   = 70
local TAB_BAR_H  = 28
local FOOTER_H   = 58
local SCALE_STEP = 0.05

-- ── MAIN FRAME ────────────────────────────────────────────────────────────
local UI = CreateFrame("Frame", "DelveTrackerFrame", UIParent, "BackdropTemplate")
UI:SetSize(UI_W, UI_H)
UI:SetPoint("CENTER")
UI:Hide()
UI:SetMovable(true)
UI:EnableMouse(true)
UI:RegisterForDrag("LeftButton")
UI:SetClampedToScreen(true)
UI:SetFrameStrata("MEDIUM")
UI:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
UI:SetBackdropColor(0.05, 0.03, 0.08, 0.97)
UI:SetBackdropBorderColor(0.35, 0.10, 0.55, 1)
UI:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then self:StartMoving() end
end)
UI:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local pt,_,rpt,x,y = self:GetPoint()
    DelveTrackerDB.mainPos = {pt=pt,rpt=rpt,x=x,y=y}
end)

-- Tabs
local Tab1 = CreateFrame("Frame","DT_Tab1",UI); Tab1:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab2 = CreateFrame("Frame","DT_Tab2",UI); Tab2:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab3 = CreateFrame("Frame","DT_Tab3",UI); Tab3:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab4 = CreateFrame("Frame","DT_Tab4",UI); Tab4:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab5 = CreateFrame("Frame","DT_Tab5",UI); Tab5:SetFrameLevel(UI:GetFrameLevel()+1)
local Tab6 = CreateFrame("Frame","DT_Tab6",UI); Tab6:SetFrameLevel(UI:GetFrameLevel()+1)
local CONTENT_Y = -(TICKER_H + HEADER_H + TAB_BAR_H)
local CONTENT_BOT = FOOTER_H
for _,t in ipairs({Tab1,Tab2,Tab3,Tab4,Tab5,Tab6}) do
    t:SetPoint("TOPLEFT",UI,"TOPLEFT",1,CONTENT_Y)
    t:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-1,CONTENT_BOT)
    t:Hide()
end

-- ── EVENT TICKER ─────────────────────────────────────────────────────────
local TickerBG = UI:CreateTexture(nil,"BACKGROUND")
TickerBG:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-1)
TickerBG:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-1)
TickerBG:SetHeight(TICKER_H)
TickerBG:SetColorTexture(0.04,0.02,0.07,1)

local TickerLine = UI:CreateTexture(nil,"OVERLAY")
TickerLine:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-TICKER_H)
TickerLine:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-TICKER_H)
TickerLine:SetHeight(1)
TickerLine:SetColorTexture(0.45,0.10,0.70,0.8)

local TickerClock = UI:CreateFontString(nil,"OVERLAY")
TickerClock:SetFont(C_2002,10,"OUTLINE")
-- Verankerd aan de ticker achtergrond, niet aan UI hoogte midden
TickerClock:SetPoint("RIGHT",TickerBG,"RIGHT",-6,0)
TickerClock:SetTextColor(0.80,0.65,1.0,1)

local TickerClip = CreateFrame("Button",nil,UI)
TickerClip:SetPoint("TOPLEFT",UI,"TOPLEFT",4,-1)
TickerClip:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-78,-1)
TickerClip:SetHeight(TICKER_H)
TickerClip:SetClipsChildren(true)
-- Ticker instellingen in DB
DelveTrackerDB.tickerShow = DelveTrackerDB.tickerShow or {
    events=true, guild=true, prey=true, time=true,
}
-- Klik op ticker opent selectiemenu
TickerClip:SetScript("OnClick", function(self)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    -- v3.1.9 FIX: defaults van file-load overleven het laden van de échte
    -- SavedVariables niet (WoW vervangt de global bij ADDON_LOADED).
    -- Dus HIER nil-safe initialiseren, op het moment van gebruik.
    DelveTrackerDB = DelveTrackerDB or {}
    DelveTrackerDB.tickerShow = DelveTrackerDB.tickerShow or {
        events=true, guild=true, prey=true, time=true,
    }
    local ts = DelveTrackerDB.tickerShow
    MenuUtil.CreateContextMenu(self, function(_, root)
        root:CreateTitle(SA_PURPLE..WT_T("TICKER_TITLE").."|r")
        local function ToggleItem(key, label)
            local checked = ts[key] ~= false
            root:CreateCheckbox(label, function() return ts[key]~=false end,
                function() ts[key] = not (ts[key]~=false); tickerDirty=true end)
        end
        ToggleItem("events",  WT_T("TICK_EVENTS"))
        ToggleItem("prey",    WT_T("TICK_PREY"))
        ToggleItem("guild",   WT_T("TICK_GUILD"))
        ToggleItem("time",    WT_T("TICK_TIME"))
        root:CreateDivider()
        root:CreateButton(WT_T("ALL_ON"), function()
            for k in pairs(ts) do ts[k]=true end; tickerDirty=true
        end)
        root:CreateButton(WT_T("ALL_OFF"), function()
            for k in pairs(ts) do ts[k]=false end; tickerDirty=true
        end)
    end)
end)

local TickerScroll = CreateFrame("Frame",nil,TickerClip)
TickerScroll:SetHeight(TICKER_H)
TickerScroll:SetWidth(6000)
TickerScroll:SetPoint("LEFT",TickerClip,"LEFT",0,0)

local TickerText = TickerScroll:CreateFontString(nil,"OVERLAY")
TickerText:SetFont(C_2002,10,"OUTLINE")
TickerText:SetPoint("LEFT",TickerScroll,"LEFT",0,0)
TickerText:SetJustifyH("LEFT")
TickerText:SetTextColor(0.75,0.55,1.0,1)

local tickerOffset=0; local tickerSpeed=38; local tickerWidth=0
local tickerClipW=0;  local tickerLastT=0;  local tickerDirty=true

local function FormatHMS(s)
    s=math.floor(s or 0)
    return string.format("%02d:%02d:%02d",math.floor(s/3600),math.floor((s%3600)/60),s%60)
end

local function BuildTickerStr()
    local ts = DelveTrackerDB and DelveTrackerDB.tickerShow or {}
    local parts = {}

    -- World Events
    if ts.events ~= false and addonTable and addonTable.DT_events then
        local ev = addonTable.DT_events:GetVisibleEvents()
        if ev then
            local list={}
            for _,e in pairs(ev) do table.insert(list,e) end
            table.sort(list,function(a,b)
                if a.isActive~=b.isActive then return a.isActive end
                return (a.timeRemaining or 0)<(b.timeRemaining or 0)
            end)
            for _,e in ipairs(list) do
                local t=FormatHMS(e.timeRemaining)
                if e.isActive then
                    table.insert(parts,"|cff44cc66⬤ "..e.name.."|r  "..SA_GREY.."ACTIEF · "..t.." rem|r")
                else
                    table.insert(parts,"|cffccaa00◎ "..e.name.."|r  "..SA_GREY.."over "..t.."|r")
                end
            end
        end
    end

    -- Guild calendar events (Fase 3.3 — eerstvolgende 2)
    if ts.guild ~= false and DT_GetGuildEvents then
        local gev = DT_GetGuildEvents()
        if gev and #gev > 0 then
            local today = date("%Y-%m-%d")
            for i = 1, math.min(2, #gev) do
                local e = gev[i]
                local when = (e.date == today) and (WT_T("GE_TODAY").." "..e.time)
                    or (e.date:sub(9,10).."-"..e.date:sub(6,7).." "..e.time)
                table.insert(parts, SA_PURPLE.."[G] "..e.title.."|r  "..SA_GREY..when.."|r")
            end
        end
    end

    -- Prey Hunt status
    if ts.prey ~= false then
        local ok,qid = pcall(C_QuestLog.GetActivePreyQuest)
        if ok and qid and qid ~= 0 then
            local info = C_QuestLog.GetQuestInfo and C_QuestLog.GetQuestInfo(qid)
            local qname = info and info.title or ("Quest #"..qid)
            table.insert(parts,"|cffff4444🎯 Prey Hunt: "..qname.."|r")
        end
    end

    -- Abundance delve modifier
    if ts.events ~= false then
        local abData = DT_GetAbundanceData and DT_GetAbundanceData()
        if abData and abData.active then
            local chipTxt = SA_GOLD.."✦ Abundance ACTIEF|r  "..SA_GREY.."(Shard of Dundun beschikbaar)|r"
            if abData.timedEvents and #abData.timedEvents > 0 then
                local ev = abData.timedEvents[1]
                local rem = ev.timeRemaining and math.floor(ev.timeRemaining/60) or 0
                chipTxt = SA_GOLD.."✦ Abundance: "..rem.."min|r  "..SA_GREY.."Chip vendor actief|r"
            end
            table.insert(parts, chipTxt)
        end
    end

    -- Guild online teller
    if ts.guild ~= false and IsInGuild() then
        local online = 0
        local total  = GetNumGuildMembers()
        for i=1,total do
            local _,_,_,_,_,_,_,_,connected = GetGuildRosterInfo(i)
            if connected then online = online + 1 end
        end
        table.insert(parts,"|cff00ff88👥 Guild online: "..online.."|r")
    end

    -- Server tijd
    if ts.time ~= false then
        local h,m = GetGameTime()
        table.insert(parts,SA_GOLD.."🕐 Server: "..string.format("%02d:%02d",h,m).."|r")
    end

    if #parts == 0 then
        return SA_GREY.."WowTracker v2.7.5 · Slayer Alliance · Midnight 12.0.5 · Klik ticker voor instellingen|r"
    end
    return table.concat(parts,"   |cff2a1040◆|r   ")
end

C_Timer.NewTicker(0.02,function()
    if not UI:IsShown() then return end
    local now=GetTime(); local dt=now-tickerLastT; tickerLastT=now
    -- Klok
    if math.floor(now)~=math.floor(now-dt) then
        TickerClock:SetText(string.format(SA_GOLD.."%s|r",date("%H:%M:%S")))
    end
    -- Tekst elke 5s
    if tickerDirty or (math.floor(now/5)~=math.floor((now-dt)/5)) then
        TickerText:SetText(BuildTickerStr())
        C_Timer.After(0.01,function()
            tickerWidth=TickerText:GetStringWidth()+60
            tickerClipW=TickerClip:GetWidth()
        end)
        tickerDirty=false
    end
    -- Scroll
    if tickerWidth>0 and tickerClipW>0 then
        tickerOffset=tickerOffset+tickerSpeed*0.02
        if tickerOffset>tickerWidth then tickerOffset=-tickerClipW end
        TickerScroll:SetPoint("LEFT",TickerClip,"LEFT",-tickerOffset,0)
    end
end)

-- ── HEADER ────────────────────────────────────────────────────────────────
local HdrBG = UI:CreateTexture(nil,"BACKGROUND")
HdrBG:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-TICKER_H)
HdrBG:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-TICKER_H)
HdrBG:SetHeight(HEADER_H)
HdrBG:SetColorTexture(0.08,0.04,0.12,1)

local HdrLine = UI:CreateTexture(nil,"OVERLAY")
HdrLine:SetPoint("TOPLEFT",UI,"TOPLEFT",1,-(TICKER_H+HEADER_H))
HdrLine:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,-(TICKER_H+HEADER_H))
HdrLine:SetHeight(1)
HdrLine:SetColorTexture(0.45,0.10,0.70,0.8)

UI.logo = UI:CreateTexture(nil,"OVERLAY")
UI.logo:SetSize(56,56)
UI.logo:SetPoint("TOPLEFT",UI,"TOPLEFT",10,-(TICKER_H+7))
UI.logo:SetTexture("Interface\\AddOns\\WowTracker\\Media\\MijnIcoon.tga")
UI.logo:SetBlendMode("ADD")   -- zwarte achtergrond transparant

UI.title = UI:CreateFontString(nil,"OVERLAY")
UI.title:SetFont(C_2002,16,"OUTLINE")
UI.title:SetPoint("TOPLEFT",UI.logo,"TOPRIGHT",10,-2)
UI.title:SetText(SA_PURPLE.."SLAYER ALLIANCE|r")

UI.versionTxt = UI:CreateFontString(nil,"OVERLAY")
UI.versionTxt:SetFont(C_2002,9,"")
UI.versionTxt:SetPoint("TOPLEFT",UI.title,"BOTTOMLEFT",0,-3)
UI.versionTxt:SetText(SA_GREY.."WowTracker v"..WT_VERSION.." · Midnight 12.0.5|r")

UI.charInfo = UI:CreateFontString(nil,"OVERLAY")
UI.charInfo:SetFont(C_2002,11,"OUTLINE")
UI.charInfo:SetPoint("TOPLEFT",UI.versionTxt,"BOTTOMLEFT",0,-4)
UI.charInfo:SetPoint("RIGHT",UI,"RIGHT",-120,0)
UI.charInfo:SetJustifyH("LEFT")
UI.charInfo:SetText(SA_GREY..WT_T("LOADING").."|r")

-- v3.2.6: charInfo daadwerkelijk vullen (bleef altijd op "Laden..." staan)
function WT_UpdateCharInfo()
    if not UI.charInfo then return end
    local name = UnitName("player") or "?"
    local level = UnitLevel("player") or 0
    local _, classFile = UnitClass("player")
    local col = (classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
    local cname = col and string.format("|cff%02x%02x%02x%s|r",
        col.r*255, col.g*255, col.b*255, name) or ("|cffffffff"..name.."|r")
    local specName = ""
    if GetSpecialization and GetSpecializationInfo then
        local si = GetSpecialization()
        if si then
            local _, sn = GetSpecializationInfo(si)
            if sn then specName = " · "..sn end
        end
    end
    local ilvl = ""
    if GetAverageItemLevel then
        local ok, avg = pcall(GetAverageItemLevel)
        if ok and avg and avg > 0 then
            ilvl = "  "..SA_BLUE.."iLvl "..math.floor(avg).."|r"
        end
    end
    UI.charInfo:SetText(cname..SA_GREY.." · "..WT_T("LVL").." "..level..specName.."|r"..ilvl)
end

-- ── WARBAND STATS (herbouw v3.0.7 — Fase 1.2) ────────────────────────────
-- Totaal karakters + totaal goud (K/M suffix), rechts in de header
UI.warbandStats = UI:CreateFontString(nil,"OVERLAY")
UI.warbandStats:SetFont(C_2002,11,"OUTLINE")
-- v3.1.7: onder de knoppenrij — stond achter de header-knoppen (onleesbaar)
UI.warbandStats:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-10,-(TICKER_H+58))
UI.warbandStats:SetJustifyH("RIGHT")
UI.warbandStats:SetText("")

-- Goud formatter: 950 → "950g" · 45600 → "45.6K" · 1230000 → "1.23M"
local function WT_FmtGold(gold)
    if gold >= 1000000 then
        return string.format("%.2fM", gold/1000000)
    elseif gold >= 1000 then
        return string.format("%.1fK", gold/1000)
    end
    return tostring(gold).."g"
end

function WT_UpdateWarbandStats()
    if not (DelveTrackerDB and DelveTrackerDB.characters) then return end
    local chars, copper = 0, 0
    for _,d in pairs(DelveTrackerDB.characters) do
        if type(d)=="table" then
            chars = chars + 1
            copper = copper + (tonumber(d.money) or 0)
        end
    end
    local gold = math.floor(copper/10000)
    UI.warbandStats:SetText(
        SA_BLUE..chars.."|r"..SA_GREY.." "..WT_T("CHARS").."  ·  |r"
        ..SA_GOLD..WT_FmtGold(gold).."|r"..SA_GREY.." "..WT_T("WARBAND_GOLD").."|r")
end

-- Header knoppen: X · Tandwiel · [Theme] [Lang] — rechtsboven op één lijn
local HDR_BTN_Y = -(TICKER_H + math.floor(HEADER_H/2) - 16)
local HDR_BTN_SZ = 32

-- X Sluiten
UI.close = CreateFrame("Button",nil,UI,"UIPanelCloseButton")
UI.close:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.close:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-5,HDR_BTN_Y)   -- v3.1.7: 5px van rand

-- Tandwiel (Settings)
UI.settingsBtn = CreateFrame("Button",nil,UI,"BackdropTemplate")
UI.settingsBtn:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.settingsBtn:SetPoint("RIGHT",UI.close,"LEFT",-3,0)
UI.settingsBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
UI.settingsBtn:SetBackdropColor(0.08,0.04,0.14,0.9)
UI.settingsBtn:SetBackdropBorderColor(0.40,0.10,0.65,0.8)
-- v3.5.3: TGA icon via WTTheme.GetIcon
UI.settingsBtn.iconTex = UI.settingsBtn:CreateTexture(nil,"ARTWORK")
UI.settingsBtn.iconTex:SetSize(28,28); UI.settingsBtn.iconTex:SetPoint("CENTER")
local function ApplySettingsIcon()
    local path = WTTheme and WTTheme.GetIcon and WTTheme.GetIcon("admin")
    if path then
        UI.settingsBtn.iconTex:SetTexture(path)
        UI.settingsBtn.iconTex:SetBlendMode("ADD")
    else
        UI.settingsBtn.iconTex:SetColorTexture(0.75,0.25,1.0,0.8)
    end
end
ApplySettingsIcon()
if WTTheme and WTTheme.Register then WTTheme.Register(ApplySettingsIcon) end
UI.settingsBtn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.25,1.0,1) end)
UI.settingsBtn:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.40,0.10,0.65,0.8) end)

-- Theme knop
UI.themeBtn = CreateFrame("Button",nil,UI,"BackdropTemplate")
UI.themeBtn:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.themeBtn:SetPoint("RIGHT",UI.settingsBtn,"LEFT",-3,0)
UI.themeBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
UI.themeBtn:SetBackdropColor(0.08,0.04,0.14,0.9)
UI.themeBtn:SetBackdropBorderColor(0.40,0.10,0.65,0.8)
-- v3.5.3: TGA icon via WTTheme.GetIcon
UI.themeBtn.iconTex = UI.themeBtn:CreateTexture(nil,"ARTWORK")
UI.themeBtn.iconTex:SetSize(28,28); UI.themeBtn.iconTex:SetPoint("CENTER")
local function ApplyThemeIcon()
    local path = WTTheme and WTTheme.GetIcon and WTTheme.GetIcon("theme")
    if path then
        UI.themeBtn.iconTex:SetTexture(path)
        UI.themeBtn.iconTex:SetBlendMode("ADD")
    else
        UI.themeBtn.iconTex:SetColorTexture(0.27,0.67,1.0,0.8)
    end
end
ApplyThemeIcon()
if WTTheme and WTTheme.Register then WTTheme.Register(ApplyThemeIcon) end
UI.themeBtn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.25,1.0,1) end)
UI.themeBtn:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.40,0.10,0.65,0.8) end)
UI.themeBtn:SetScript("OnClick",function(self)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    MenuUtil.CreateContextMenu(self,function(_,root)
        root:CreateTitle(SA_PURPLE..WT_T("THEME_TITLE").."|r")
        -- Gebruik WTTheme themes als die beschikbaar is
        if WTTheme and WTTheme.GetThemeNames then
            local names = WTTheme.GetThemeNames()
            local active = WTTheme.GetActive and WTTheme.GetActive() or ""
            for _,name in ipairs(names) do
                local n = name
                local mark = (n == active) and "|cff44ff44✓ |r" or "  "
                root:CreateButton(mark..n, function()
                    WTTheme.SetActiveTheme(n)  -- triggert Register callback + slaat op
                    print(SA_PURPLE.."[WowTracker] Thema: "..n.."|r")
                end)
            end
        else
            -- Fallback: oud inline systeem als WTTheme niet laadt
            local themes = {
                {name="SA Dark (standaard)", r=0.04,g=0.02,b=0.08, border={0.25,0.07,0.40}},
                {name="ProfBuddy Paars",     r=0.06,g=0.02,b=0.12, border={0.45,0.10,0.70}},
                {name="MailVault Blauw",     r=0.02,g=0.04,b=0.12, border={0.10,0.25,0.60}},
                {name="Nacht Zwart",         r=0.02,g=0.02,b=0.04, border={0.20,0.20,0.20}},
            }
            for _,t in ipairs(themes) do
                local th=t
                root:CreateButton(th.name,function()
                    DelveTrackerDB.theme={bg={th.r,th.g,th.b}, border=th.border, name=th.name}
                    UI:SetBackdropColor(th.r,th.g,th.b,0.97)
                    UI:SetBackdropBorderColor(th.border[1],th.border[2],th.border[3],1)
                    print(SA_PURPLE.."[WowTracker] Thema: "..th.name.."|r")
                end)
            end
        end
    end)
end)

-- Taal knop
UI.langBtn = CreateFrame("Button",nil,UI,"BackdropTemplate")
UI.langBtn:SetSize(HDR_BTN_SZ,HDR_BTN_SZ)
UI.langBtn:SetPoint("RIGHT",UI.themeBtn,"LEFT",-3,0)
UI.langBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
UI.langBtn:SetBackdropColor(0.08,0.04,0.14,0.9)
UI.langBtn:SetBackdropBorderColor(0.40,0.10,0.65,0.8)
-- v3.5.3: TGA icon via WTTheme.GetIcon
UI.langBtn.iconTex = UI.langBtn:CreateTexture(nil,"ARTWORK")
UI.langBtn.iconTex:SetSize(28,28); UI.langBtn.iconTex:SetPoint("CENTER")
local function ApplyLangIcon()
    local path = WTTheme and WTTheme.GetIcon and WTTheme.GetIcon("language")
    if path then
        UI.langBtn.iconTex:SetTexture(path)
        UI.langBtn.iconTex:SetBlendMode("ADD")
    else
        UI.langBtn.iconTex:SetColorTexture(0.27,1.0,0.67,0.8)
    end
end
ApplyLangIcon()
if WTTheme and WTTheme.Register then WTTheme.Register(ApplyLangIcon) end
UI.langBtn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.25,1.0,1) end)
UI.langBtn:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.40,0.10,0.65,0.8) end)
-- Expose als global referentie voor andere plugins (Registry B knop)
DelveTrackerFrame.langBtn  = UI.langBtn
DelveTrackerFrame.themeBtn = UI.themeBtn

-- ── WTTHEME LIVE RELOAD ────────────────────────────────────────────────────
-- Registreer callback zodat WTTheme.SetActiveTheme() automatisch het
-- hoofdframe bijwerkt. Werkt ook bij reload via admin panel later.
if WTTheme and WTTheme.Register then
    WTTheme.Register(function()
        local bg  = WTTheme.bg.main
        local bdr = WTTheme.border.main
        if bg  then UI:SetBackdropColor(bg.r,  bg.g,  bg.b,  bg.a  or 0.97) end
        if bdr then UI:SetBackdropBorderColor(bdr.r, bdr.g, bdr.b, bdr.a or 1) end
        -- Ticker achtergrond meeschaalt met theme
        if TickerBG then
            local h = WTTheme.bg.header
            if h then TickerBG:SetColorTexture(h.r, h.g, h.b, h.a or 1) end
        end
        -- Tab knoppen meekleuren (live theme switch)
        local cardBg  = WTTheme.bg.card
        local cardBdr = WTTheme.border.main
        if tabBtns and cardBg and cardBdr then
            for _,b in ipairs(tabBtns) do
                if b and b.SetBackdropColor then
                    b:SetBackdropColor(cardBg.r, cardBg.g, cardBg.b, cardBg.a or 0.95)
                    b:SetBackdropBorderColor(cardBdr.r, cardBdr.g, cardBdr.b, 0.8)
                end
            end
        end
    end)
end

UI.langBtn:SetScript("OnClick",function(self)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    local langs = {"Nederlands","English","Deutsch","Français","Español"}
    MenuUtil.CreateContextMenu(self,function(_,root)
        root:CreateTitle(SA_BLUE..WT_T("LANG_TITLE").."|r")
        local active = (DelveTrackerDB and DelveTrackerDB.language) or "Nederlands"
        for _,lang in ipairs(langs) do
            local l=lang
            local mark = (l == active) and "|cff44ff44✓ |r" or "  "
            root:CreateButton(mark..l,function()
                DelveTrackerDB.language=l
                if WT_ApplyLanguage then WT_ApplyLanguage(l) end   -- DIRECT toepassen
                print(SA_PURPLE.."[WowTracker] Taal: "..l.."|r")
            end)
        end
    end)
end)

-- ── TABS ──────────────────────────────────────────────────────────────────
local TAB_Y = -(TICKER_H+HEADER_H)
local tabBtns={}; local activeTabID=2

local tabDefs={
    {id=1,label="GUILD",   col=SA_GOLD},
    {id=2,label="DELVES",  col=SA_BLUE},
    {id=3,label="BOUNTY",  col=SA_PURPLE},
    {id=4,label="ROSTER",  col="|cff00ff88"},
    {id=5,label="ARMORY",  col="|cffff9900"},
    {id=6,label="CURRENCY",col="|cffccaa00"},
}
local TAB_W = math.floor((UI_W-2)/#tabDefs)

local function StyleTabBtn(btn,active)
    if active then
        btn:SetBackdropColor(0.12,0.05,0.20,1)
        btn:SetBackdropBorderColor(0.60,0.15,0.90,1)
        btn.glow:SetAlpha(1)
    else
        btn:SetBackdropColor(0.06,0.03,0.10,1)
        btn:SetBackdropBorderColor(0.20,0.05,0.30,0.7)
        btn.glow:SetAlpha(0)
    end
end

-- Forward declare alle tab-update functies (gedefinieerd later in het bestand)
local UpdateCharacterList
-- ── FRAME POOLS (Fase 4.1 · v3.3.2) ──────────────────────────────────────
-- Blizzard-patroon: één pool per type, AcquireFrame/ReleaseAll i.p.v.
-- steeds nieuwe frames aanmaken + garbage genereren.
-- v3.3.6 FIX: aparte init per tab zodat parents correct zijn
local rosterCardPool    -- Tab4.scroll.content parent
local currNameRowPool   -- Tab6.scroll.content parent
local currTilePool      -- Tab6.scroll.content parent (SetParent bij acquire)
local currScrollPool    -- Tab6.scroll.content parent
local currArrowPool     -- Tab6.scroll.content parent

-- ═══════════════════════════════════════════════════════════════════════
-- WT_MakeSAScrollbar (v3.4.0) — centrale SA-kleur scrollbar helper
-- Gebruik: WT_MakeSAScrollbar(scrollFrame, parentFrame)
-- Verbergt de Blizzard-standaard scrollbar en plaatst een SA-gekleurde
-- thumb (neon paars) + baan (donker paars) rechts van het scroll-frame.
-- ═══════════════════════════════════════════════════════════════════════
function WT_MakeSAScrollbar(sf, parent)
    local SB_W = 8
    -- v3.4.2: fallback op sf:GetParent() als parent nil is
    parent = parent or sf:GetParent()
    -- Verberg Blizzard-standaard scrollbar (UIPanelScrollFrameTemplate)
    if sf.ScrollBar then sf.ScrollBar:Hide() end

    -- Baan (donker paars)
    local track = parent:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SB_W)
    track:SetPoint("TOPLEFT",    sf, "TOPRIGHT",    2, 0)
    track:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 2, 0)
    track:SetColorTexture(0.18, 0.06, 0.30, 0.75)

    -- Thumb (neon paars)
    local thumb = CreateFrame("Button", nil, parent, "BackdropTemplate")
    thumb:SetWidth(SB_W)
    thumb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
                       edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    thumb:SetBackdropColor(0.48, 0.00, 0.80, 0.9)
    thumb:SetBackdropBorderColor(0.70, 0.20, 1.00, 1)

    local function UpdateThumb()
        local child = sf:GetScrollChild()
        local total = child and child:GetHeight() or 0
        local vis   = sf:GetHeight()
        if total <= vis or vis <= 0 then thumb:Hide(); return end
        thumb:Show()
        local trackH  = track:GetHeight()
        local thumbH  = math.max(20, trackH * (vis / total))
        thumb:SetHeight(thumbH)
        local maxScroll = total - vis
        local scrolled  = sf:GetVerticalScroll()
        local yPos = maxScroll > 0 and -(scrolled / maxScroll) * (trackH - thumbH) or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, yPos)
    end
    sf:HookScript("OnScrollRangeChanged", UpdateThumb)
    sf:HookScript("OnVerticalScroll",     UpdateThumb)

    -- Muis-wiel (scroll 3 rijen per tik)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, d)
        sf:SetVerticalScroll(math.max(0,
            math.min(sf:GetVerticalScrollRange(), sf:GetVerticalScroll() - d * 30)))
    end)

    -- Drag op thumb
    thumb:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        local startY     = select(2, GetCursorPosition())
        local startScroll= sf:GetVerticalScroll()
        local child2     = sf:GetScrollChild()
        local total2     = child2 and child2:GetHeight() or 0
        local vis2       = sf:GetHeight()
        local trackH2    = track:GetHeight()
        self:SetScript("OnUpdate", function()
            local dy = startY - select(2, GetCursorPosition())
            local pxPerScroll = (total2 - vis2) / math.max(1, trackH2 - self:GetHeight())
            sf:SetVerticalScroll(math.min(total2 - vis2,
                math.max(0, startScroll + dy * pxPerScroll)))
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    return track, thumb, UpdateThumb
end

local rosterPoolsReady  = false
local currPoolsReady    = false

local function InitRosterPools(parent)
    if rosterPoolsReady then return end
    rosterCardPool = CreateFramePool("Button", parent, "BackdropTemplate",
        function(_, f) f:ClearAllPoints(); f:Hide() end)
    rosterPoolsReady = true
end

local function InitCurrPools(parent)
    if currPoolsReady then return end
    currNameRowPool = CreateFramePool("Frame", parent, "BackdropTemplate",
        function(_, f) f:ClearAllPoints(); f:Hide() end)
    currTilePool = CreateFramePool("Button", parent, "BackdropTemplate",
        function(_, f) f:ClearAllPoints(); f:Hide() end)
    currScrollPool = CreateFramePool("ScrollFrame", parent, nil,
        function(_, f) f:ClearAllPoints(); f:Hide() end)
    currArrowPool = CreateFramePool("Button", parent, "BackdropTemplate",
        function(_, f) f:ClearAllPoints(); f:Hide() end)
    currPoolsReady = true
end

-- Legacy alias voor bestaande aanroepen op PLAYER_LOGIN
local function InitPools(parent)
    InitRosterPools(parent)
end

local WT_UpdateRoster
local WT_ShowArmory
local WT_UpdateCurrency
local WT_UpdateGuildOnline
local ScanDelves

-- Safe wrapper: guild roster request API verschilt per build.
-- GUILD_ROSTER_UPDATE vuurt sowieso periodiek — request is best-effort.
local function WT_RequestGuildRoster()
    if C_GuildInfo and type(C_GuildInfo.GuildRoster)=="function" then
        C_GuildInfo.GuildRoster()
    elseif type(GuildRoster)=="function" then
        GuildRoster()
    end
end

-- ── GUILD MOTD — TAINT-VRIJ ───────────────────────────────────────────────
-- GetGuildRosterMOTD() is PROTECTED in Midnight 12.0.5 (ADDON_ACTION_BLOCKED).
-- Taint-vrije route: GUILD_MOTD event levert de tekst als payload (cache).
local _cachedMOTD = ""
local function WT_SetCachedMOTD(m) _cachedMOTD = m or "" end
local function WT_GetMOTD()
    if C_GuildInfo and type(C_GuildInfo.GetGuildRosterMOTD)=="function" then
        -- v3.2.9: pcall — mocht deze route ooit protected/secret gedrag
        -- vertonen, dan geen error maar gewoon cache-fallback
        local ok, m = pcall(C_GuildInfo.GetGuildRosterMOTD)
        if ok and type(m)=="string" and m ~= "" then _cachedMOTD = m end
    end
    return _cachedMOTD
end

local function ShowTab(id)
    UI:Show(); activeTabID=id
    Tab1:Hide(); Tab2:Hide(); Tab3:Hide(); Tab4:Hide(); Tab5:Hide(); Tab6:Hide()
    -- Verberg armory frame als Tab5 verlaten wordt
    local armFrame = _G["DT_ArmoryFrame"]
    if armFrame and Tab5.armoryEmbedded then armFrame:Hide() end

    if id==1 then
        Tab1:Show()
        if IsInGuild() then
            WT_RequestGuildRoster()
            local gName = GetGuildInfo("player")
            Tab1.guildName:SetText(SA_GOLD..(gName or "Slayer Alliance").."|r")
            local motd = WT_GetMOTD()
            Tab1.motdText:SetText(motd~="" and (SA_GREY..motd.."|r") or SA_GREY..WT_T("LOADING").."|r")
            -- v3.2.9 OPTIE A: het GUILD_MOTD event kan uitblijven (race /
            -- addon-conflict) — herpoging na 1s, en na 3s nette melding
            -- i.p.v. eeuwig "Laden..."
            if motd == "" and C_Timer and C_Timer.After then
                C_Timer.After(1.0, function()
                    if not (Tab1:IsShown() and Tab1.motdText) then return end
                    local fresh = WT_GetMOTD()
                    if fresh ~= "" then
                        Tab1.motdText:SetText(SA_GREY..fresh.."|r")
                    end
                end)
                C_Timer.After(3.0, function()
                    if not (Tab1:IsShown() and Tab1.motdText) then return end
                    local fresh = WT_GetMOTD()
                    Tab1.motdText:SetText(fresh ~= "" and (SA_GREY..fresh.."|r")
                        or SA_GREY..WT_T("NO_MOTD").."|r")
                end)
            end
        else
            Tab1.guildName:SetText(SA_GREY..WT_T("NO_GUILD").."|r")
            Tab1.motdText:SetText(SA_GREY..WT_T("NO_GUILD_MEMBER").."|r")
        end
        WT_UpdateGuildOnline()

    elseif id==2 then
        Tab2:Show()
        if UpdateCharacterList then UpdateCharacterList() end

    elseif id==3 then
        Tab3:Show()
        Tab3.PluginArea:Show()
        -- QuickSet: geef volledige Tab3 breedte mee
        -- QuickSet bouwt tiles in een scrollframe — het vult de breedte van de container
        if not Tab3.quickWrap then
            Tab3.quickWrap = CreateFrame("Frame",nil,Tab3.PluginArea)
            Tab3.quickWrap:SetPoint("TOPLEFT",Tab3.PluginArea,"TOPLEFT",0,0)
            Tab3.quickWrap:SetPoint("BOTTOMRIGHT",Tab3.PluginArea,"BOTTOMRIGHT",0,0)
        end
        if Tab3.quickWrap._dtBuilt == nil then
            local qpF = DelveTracker.Plugins["QuickSet"]
            if qpF and DelveTrackerDB.PluginStates["QuickSet"]~=false then
                pcall(qpF,"Tab3",Tab3.quickWrap)
            end
        end

    elseif id==4 then
        Tab4:Show()
        ScanDelves()  -- zorg dat data vers is
        WT_UpdateRoster()

    elseif id==5 then
        -- ARMORY — open Charmory popup voor huidig karakter
        Tab5:Show()
        WT_ShowArmory()

    elseif id==6 then
        Tab6:Show()
        ScanDelves()  -- zorg dat data vers is
        WT_UpdateCurrency()
    end

    for _,b in ipairs(tabBtns) do StyleTabBtn(b,b._id==id) end
end

for i,def in ipairs(tabDefs) do
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(TAB_W,TAB_BAR_H)
    b:SetPoint("TOPLEFT",UI,"TOPLEFT",1+(i-1)*TAB_W,TAB_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b._id=def.id
    b.glow=b:CreateTexture(nil,"OVERLAY")
    b.glow:SetHeight(2)
    b.glow:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1)
    b.glow:SetPoint("TOPRIGHT",b,"TOPRIGHT",-1,-1)
    b.glow:SetColorTexture(0.70,0.25,1.0,1)
    b.glow:SetAlpha(0)
    b.lbl=b:CreateFontString(nil,"OVERLAY")
    b.lbl:SetFont(C_2002,11,"OUTLINE")
    b.lbl:SetPoint("CENTER")
    b.lbl:SetText(def.col..def.label.."|r")
    StyleTabBtn(b,i==activeTabID)
    b:SetScript("OnClick",function() ShowTab(def.id) end)
    b:SetScript("OnEnter",function(self) if self._id~=activeTabID then self:SetBackdropBorderColor(0.50,0.15,0.75,1) end end)
    b:SetScript("OnLeave",function(self) StyleTabBtn(self,self._id==activeTabID) end)
    tabBtns[i]=b
end

-- (taalsysteem verplaatst naar boven — v3.2.0)
function WT_ApplyLanguage(lang)
    lang = lang or (DelveTrackerDB and DelveTrackerDB.language) or "Nederlands"
    -- v3.2.0: tabel staat bovenaan — via setter (upvalue daar)
    WT_SetLangTable(lang)
    -- Tab labels
    local tabKeys = {"TAB_GUILD","TAB_DELVES","TAB_BOUNTY","TAB_ROSTER","TAB_ARMORY","TAB_CURRENCY"}
    for i, b in ipairs(tabBtns) do
        if b and b.lbl and tabKeys[i] then
            local def = tabDefs[i]
            local col = def and def.col or "|cffffffff"
            b.lbl:SetText(col .. WT_T(tabKeys[i]) .. "|r")
        end
    end
    -- Statische labels (v3.2.0 — VOLLEDIG)
    if Tab1 and Tab1.motdLabel then
        Tab1.motdLabel:SetText(SA_PURPLE..WT_T("MOTD_LABEL").."|r")
    end
    if Tab4 and Tab4.hdr then
        Tab4.hdr:SetText(SA_PURPLE..WT_T("ROSTER_HDR").."|r  "..SA_GREY..WT_T("ROSTER_HINT").."|r")
    end
    if Tab6 and Tab6.hdr then
        Tab6.hdr:SetText(SA_GOLD..WT_T("CUR_HDR").."|r  "..SA_GREY..WT_T("CUR_HINT").."|r")
    end
    -- Filter placeholder alleen vervangen als hij placeholder toont
    if Tab6 and Tab6.searchBox and Tab6.searchBox._isPlaceholder then
        Tab6.searchBox:SetText(WT_T("CUR_FILTER"))
    end
    if UI.scaleLbl then
        UI.scaleLbl:SetText(SA_GREY..WT_T("SCALE").."|r")
    end
    -- Warband stats hertekenen in nieuwe taal
    if WT_UpdateWarbandStats then WT_UpdateWarbandStats() end
end

local TabLine=UI:CreateTexture(nil,"OVERLAY")
TabLine:SetPoint("TOPLEFT",UI,"TOPLEFT",1,TAB_Y-TAB_BAR_H)
TabLine:SetPoint("TOPRIGHT",UI,"TOPRIGHT",-1,TAB_Y-TAB_BAR_H)
TabLine:SetHeight(1)
TabLine:SetColorTexture(0.25,0.07,0.40,0.8)

-- ── TAB 1: GUILD ──────────────────────────────────────────────────────────
-- Links: guild info + MOTD + Kelsey image
-- Rechts: online leden lijst (260px breed)

local GUILD_RIGHT_W = 260
local GUILD_LEFT_W  = UI_W - 2 - GUILD_RIGHT_W

-- ── LINKER KOLOM ──────────────────────────────────────────────────────────
-- Guild tab gecentreerd in de linker kolom
Tab1.guildName=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.guildName:SetFont(C_2002,26,"OUTLINE")  -- was 20, nu groter
Tab1.guildName:SetJustifyH("CENTER")
Tab1.guildName:SetPoint("TOP",Tab1,"TOPLEFT",GUILD_LEFT_W/2,-14)
Tab1.guildName:SetWidth(GUILD_LEFT_W-20)
Tab1.guildName:SetText(SA_GOLD.."Slayer Alliance|r")

Tab1.motdLabel=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.motdLabel:SetFont(C_2002,9,"OUTLINE")
Tab1.motdLabel:SetJustifyH("CENTER")
Tab1.motdLabel:SetPoint("TOP",Tab1.guildName,"BOTTOM",0,-12)
Tab1.motdLabel:SetText(SA_PURPLE.."─── Bericht van de dag ───|r")

Tab1.motdText=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.motdText:SetFont(C_2002,11,"")
Tab1.motdText:SetPoint("TOP",Tab1.motdLabel,"BOTTOM",0,-8)
Tab1.motdText:SetWidth(GUILD_LEFT_W-60)
Tab1.motdText:SetJustifyH("CENTER")
Tab1.motdText:SetWordWrap(true)
Tab1.motdText:SetTextColor(0.85,0.85,0.85,1)
Tab1.motdText:SetText(SA_GREY..WT_T("LOADING").."|r")
-- MOTD hoogte begrenzen — max tot halverwege de tab (Kelsey staat onderin)
Tab1.motdText:SetMaxLines(4)

-- ── GUILD CALENDAR EVENTS LIJST (Fase 3.3 · v3.2.3) ──────────────────────
Tab1.geHdr=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.geHdr:SetFont(C_2002,9,"OUTLINE")
Tab1.geHdr:SetJustifyH("CENTER")
Tab1.geHdr:SetPoint("TOP",Tab1.motdText,"BOTTOM",0,-14)
Tab1.geHdr:SetText("")

Tab1.geRows = {}
for i = 1, 4 do
    local r = Tab1:CreateFontString(nil,"OVERLAY")
    r:SetFont(C_2002,10,"")
    r:SetJustifyH("CENTER")
    r:SetWidth(GUILD_LEFT_W-50)
    r:SetWordWrap(false)
    r:SetPoint("TOP",Tab1.geHdr,"BOTTOM",0,-6-(i-1)*14)
    r:SetText("")
    Tab1.geRows[i] = r
end

function WT_UpdateGuildEventsList()
    if not (Tab1 and Tab1.geHdr) then return end
    local gev = DT_GetGuildEvents and DT_GetGuildEvents()
    if not gev or #gev == 0 then
        Tab1.geHdr:SetText(SA_PURPLE.."─── "..WT_T("GE_HDR").." ───|r")
        Tab1.geRows[1]:SetText(SA_GREY..WT_T("GE_NONE").."|r")
        for i = 2, 4 do Tab1.geRows[i]:SetText("") end
        return
    end
    Tab1.geHdr:SetText(SA_PURPLE.."─── "..WT_T("GE_HDR").." ───|r")
    local today = date("%Y-%m-%d")
    for i = 1, 4 do
        local e = gev[i]
        if e then
            local when = (e.date == today) and (SA_GOLD..WT_T("GE_TODAY").." "..e.time.."|r")
                or (SA_BLUE..e.date:sub(9,10).."-"..e.date:sub(6,7).." "..e.time.."|r")
            Tab1.geRows[i]:SetText(when.."  |cffffffff"..e.title.."|r")
        else
            Tab1.geRows[i]:SetText("")
        end
    end
end

-- ── GUILD TAB IMAGES ─────────────────────────────────────────────────────
-- Layout:
--   Kelsey: groot centraal als feature image (ARTWORK, hoge alpha)
--   DieOuwe: klein, rechtsonder linker kolom, gespiegeld, wijst naar binnen
--   Logo: subtiel watermark linksonder

-- Kelsey: 66x66 rechtsonder de online-users kolom (v3.3.9)
Tab1.img=Tab1:CreateTexture(nil,"ARTWORK")
Tab1.img:SetSize(66,66)
Tab1.img:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMRIGHT",-4,8)
Tab1.img:SetTexture("Interface\\AddOns\\WowTracker\\Media\\kelsey.tga")
Tab1.img:SetAlpha(0.85)

-- DieOuwe: klein, rechterhoek van linker kolom, gespiegeld (wijst naar binnen)
Tab1.dieouwe=Tab1:CreateTexture(nil,"ARTWORK")
Tab1.dieouwe:SetSize(80,138)  -- proportioneel kleiner
Tab1.dieouwe:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMLEFT",GUILD_LEFT_W-4,8)
Tab1.dieouwe:SetTexture("Interface\\AddOns\\WowTracker\\Media\\Dieouwe.tga")
Tab1.dieouwe:SetAlpha(0.75)
-- Horizontaal spiegelen (4-arg): left=1,right=0,top=0,bottom=1
-- Origineel kijkt rechts → gespiegeld kijkt naar links (naar binnen)
Tab1.dieouwe:SetTexCoord(1,0,0,1)

-- Logo watermark links midden — subtiel
Tab1.logoWM=Tab1:CreateTexture(nil,"BACKGROUND")
Tab1.logoWM:SetSize(90,90)
Tab1.logoWM:SetPoint("BOTTOMLEFT",Tab1,"BOTTOMLEFT",8,8)
Tab1.logoWM:SetTexture("Interface\\AddOns\\WowTracker\\Media\\MijnIcoon.tga")
Tab1.logoWM:SetAlpha(0.12)

-- ── RECHTER KOLOM: GUILD ONLINE LEDEN ─────────────────────────────────────
-- Verticale scheidingslijn
Tab1.divLine=Tab1:CreateTexture(nil,"OVERLAY")
Tab1.divLine:SetSize(1,600)
Tab1.divLine:SetPoint("TOPRIGHT",Tab1,"TOPRIGHT",-GUILD_RIGHT_W,0)
Tab1.divLine:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMRIGHT",-GUILD_RIGHT_W,0)
Tab1.divLine:SetColorTexture(0.30,0.07,0.50,0.5)

-- Header online panel
Tab1.onlineHdr=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.onlineHdr:SetFont(C_2002,10,"OUTLINE")
Tab1.onlineHdr:SetPoint("TOPRIGHT",Tab1,"TOPRIGHT",-8,-8)
Tab1.onlineHdr:SetText(SA_PURPLE.."Online|r")

Tab1.onlineCount=Tab1:CreateFontString(nil,"OVERLAY")
Tab1.onlineCount:SetFont(C_2002,10,"")
Tab1.onlineCount:SetPoint("RIGHT",Tab1.onlineHdr,"LEFT",-4,0)
Tab1.onlineCount:SetTextColor(0.6,0.4,0.9,1)
Tab1.onlineCount:SetText("")

-- Scroll frame voor online leden
-- v3.3.9: handmatige scrollbar met SA-kleuren (geen UIPanelScrollFrameTemplate)
local _SBW = 8  -- v3.4.2: local (SB_W was per abuis verwijderd)
Tab1.onlineScroll=CreateFrame("ScrollFrame",nil,Tab1)
Tab1.onlineScroll:SetPoint("TOPRIGHT",Tab1,"TOPRIGHT",-(_SBW+6),-26)
Tab1.onlineScroll:SetPoint("BOTTOMRIGHT",Tab1,"BOTTOMRIGHT",-(_SBW+6),76)
Tab1.onlineScroll:SetWidth(GUILD_RIGHT_W-_SBW-10)
Tab1.onlineScroll.content=CreateFrame("Frame",nil,Tab1.onlineScroll)
Tab1.onlineScroll.content:SetSize(GUILD_RIGHT_W-_SBW-24,1)
Tab1.onlineScroll:SetScrollChild(Tab1.onlineScroll.content)
Tab1.onlineScroll.content.rows={}

-- Centrale SA-scrollbar helper (v3.4.0 refactor)
WT_MakeSAScrollbar(Tab1.onlineScroll, Tab1)

-- ── TAB 2: DELVES — 2 kolommen + zoek met suggesties ─────────────────────
local searchBox=CreateFrame("EditBox","DT_SearchBox",Tab2,"SearchBoxTemplate")
searchBox:SetSize(UI_W-60,24)
searchBox:SetPoint("TOPLEFT",Tab2,"TOPLEFT",10,-6)
searchBox:SetAutoFocus(false)

-- Suggestie dropdown
local DT_SuggestDrop=CreateFrame("Frame","DT_DelvesSuggest",Tab2,"BackdropTemplate")
DT_SuggestDrop:SetFrameLevel(Tab2:GetFrameLevel()+20)
DT_SuggestDrop:SetWidth(280)
DT_SuggestDrop:SetPoint("TOPLEFT",searchBox,"BOTTOMLEFT",0,-1)
DT_SuggestDrop:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
DT_SuggestDrop:SetBackdropColor(0.06,0.03,0.10,0.98)
DT_SuggestDrop:SetBackdropBorderColor(0.45,0.12,0.70,1)
DT_SuggestDrop:Hide()
DT_SuggestDrop.btns={}

local function RefreshSuggest(filter)
    for _,b in ipairs(DT_SuggestDrop.btns) do b:Hide() end
    if not filter or filter=="" then DT_SuggestDrop:Hide(); return end
    local matches={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        local short=k:match("([^-]+)") or k
        if short:lower():find(filter:lower(),1,true) then
            table.insert(matches,{key=k,short=short})
        end
    end
    if #matches==0 then DT_SuggestDrop:Hide(); return end
    table.sort(matches,function(a,b) return a.short<b.short end)
    local BH=22; local cnt=math.min(#matches,8)
    for i=1,cnt do
        local m=matches[i]
        if not DT_SuggestDrop.btns[i] then
            local sb=CreateFrame("Button",nil,DT_SuggestDrop)
            sb:SetHeight(BH)
            sb:SetPoint("TOPLEFT",1,-(BH*(i-1)+1))
            sb:SetPoint("TOPRIGHT",-1,-(BH*(i-1)+1))
            sb.t=sb:CreateFontString(nil,"OVERLAY")
            sb.t:SetFont(C_2002,11,"")
            sb.t:SetPoint("LEFT",6,0)
            sb:SetScript("OnClick",function(self)
                searchBox:SetText(self._short)
                DT_SuggestDrop:Hide()
                if UpdateCharacterList then UpdateCharacterList() end
            end)
            table.insert(DT_SuggestDrop.btns,sb)
        end
        local sb=DT_SuggestDrop.btns[i]
        local data=DelveTrackerDB.characters[m.key] or {}
        local cc=RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}
        sb.t:SetText(string.format("|cff%02x%02x%02x%s|r  "..SA_GREY.."%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            m.short, data.class or "??"))
        sb._short=m.short; sb:Show()
    end
    DT_SuggestDrop:SetHeight(cnt*BH+2); DT_SuggestDrop:Show()
end

searchBox:SetScript("OnTextChanged",function(self)
    SearchBoxTemplate_OnTextChanged(self)
    RefreshSuggest(self:GetText())
    if UpdateCharacterList then UpdateCharacterList() end
end)
searchBox:SetScript("OnEditFocusLost",function()
    C_Timer.After(0.15,function() DT_SuggestDrop:Hide() end)
end)

-- 1 scroller over volledige breedte, 2-koloms tegel layout
local COL_W=math.floor((UI_W-50)/2)
local scroll=CreateFrame("ScrollFrame","DT_Scroll",Tab2)
scroll:SetPoint("TOPLEFT",Tab2,"TOPLEFT",1,-34)
scroll:SetPoint("BOTTOMRIGHT",Tab2,"BOTTOMRIGHT",-12,4)
scroll.content=CreateFrame("Frame",nil,scroll)
scroll.content:SetSize(UI_W-46,1)
scroll:SetScrollChild(scroll.content)
scroll.content.rows={}
WT_MakeSAScrollbar(scroll, Tab2)
-- DT_Scroll2 alias zodat kolom 2 code nog werkt
local scroll2_alias = scroll  -- zelfde scroller, kolom 2 gebruikt xPos offset

-- ── TAB 3: BOUNTY — volle breedte ────────────────────────────────────────
Tab3.PluginArea=CreateFrame("Frame","DT_BountyArea",Tab3)
Tab3.PluginArea:SetPoint("TOPLEFT",Tab3,"TOPLEFT",0,0)
Tab3.PluginArea:SetPoint("BOTTOMRIGHT",Tab3,"BOTTOMRIGHT",0,0)
-- QuickSet legt zijn content in Tab3.PluginArea centraal
Tab3.bg=Tab3:CreateTexture(nil,"BACKGROUND")
Tab3.bg:SetAllPoints()
Tab3.bg:SetColorTexture(0.05,0.02,0.08,0.6)

-- Bounty fallback: toon QuickSet frame direct als het bestaat
-- QuickSet maakt zijn eigen frame (DT_QuickSetFrame) — zet het als child van Tab3
Tab3.PluginArea:SetScript("OnShow", function(self)
    C_Timer.After(0.1, function()
        local qf = _G["DT_QuickSetFrame"]
        if qf then
            qf:SetParent(self)
            qf:ClearAllPoints()
            qf:SetPoint("TOPLEFT",self,"TOPLEFT",0,0)
            qf:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",0,0)
            qf:Show()
        end
    end)
end)

-- ── TAB 4: ROSTER ─────────────────────────────────────────────────────────
Tab4.PluginArea=CreateFrame("Frame","DT_RosterArea",Tab4)
Tab4.PluginArea:SetPoint("TOPLEFT",Tab4,"TOPLEFT",0,0)
Tab4.PluginArea:SetPoint("BOTTOMRIGHT",Tab4,"BOTTOMRIGHT",0,0)
-- Header label
Tab4.hdr=Tab4:CreateFontString(nil,"OVERLAY")
Tab4.hdr:SetFont(C_2002,13,"OUTLINE")
Tab4.hdr:SetPoint("TOPLEFT",Tab4,"TOPLEFT",12,-10)
Tab4.hdr:SetText(SA_PURPLE..WT_T("ROSTER_HDR").."|r  "..SA_GREY..WT_T("ROSTER_HINT").."|r")
-- Scroll voor roster
Tab4.scroll=CreateFrame("ScrollFrame",nil,Tab4)
Tab4.scroll:SetPoint("TOPLEFT",Tab4,"TOPLEFT",1,-32)
Tab4.scroll:SetPoint("BOTTOMRIGHT",Tab4,"BOTTOMRIGHT",-12,4)
Tab4.scroll.content=CreateFrame("Frame",nil,Tab4.scroll)
Tab4.scroll.content:SetSize(UI_W-40,1)
Tab4.scroll:SetScrollChild(Tab4.scroll.content)
Tab4.scroll.content.rows={}
WT_MakeSAScrollbar(Tab4.scroll, Tab4)

-- ── TAB 5: ARMORY/CHARMORY ────────────────────────────────────────────────
Tab5.PluginArea=CreateFrame("Frame","DT_ArmoryArea",Tab5)
Tab5.PluginArea:SetPoint("TOPLEFT",Tab5,"TOPLEFT",0,0)
Tab5.PluginArea:SetPoint("BOTTOMRIGHT",Tab5,"BOTTOMRIGHT",0,0)

-- ── TAB 6: CURRENCY ───────────────────────────────────────────────────────
Tab6.PluginArea=CreateFrame("Frame","DT_CurrencyArea",Tab6)
Tab6.PluginArea:SetPoint("TOPLEFT",Tab6,"TOPLEFT",0,0)
Tab6.PluginArea:SetPoint("BOTTOMRIGHT",Tab6,"BOTTOMRIGHT",0,0)
-- Currency header
Tab6.hdr=Tab6:CreateFontString(nil,"OVERLAY")
Tab6.hdr:SetFont(C_2002,12,"OUTLINE")
Tab6.hdr:SetPoint("TOPLEFT",Tab6,"TOPLEFT",8,-8)
Tab6.hdr:SetText(SA_GOLD..WT_T("CUR_HDR").."|r  "..SA_GREY..WT_T("CUR_HINT").."|r")

-- Zoekbalk / filter
Tab6.searchBox=CreateFrame("EditBox",nil,Tab6,"BackdropTemplate")
Tab6.searchBox:SetSize(200,20)
Tab6.searchBox:SetPoint("TOPRIGHT",Tab6,"TOPRIGHT",-24,-8)
Tab6.searchBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
Tab6.searchBox:SetBackdropColor(0.04,0.02,0.08,0.95)
Tab6.searchBox:SetBackdropBorderColor(0.30,0.08,0.50,0.8)
Tab6.searchBox:SetFontObject("ChatFontNormal")
Tab6.searchBox:SetText(WT_T("CUR_FILTER")); Tab6.searchBox._isPlaceholder=true
Tab6.searchBox:SetAutoFocus(false)
Tab6.searchBox:SetScript("OnEditFocusGained",function(s)
    if s._isPlaceholder then s:SetText(""); s._isPlaceholder=false end
end)
Tab6.searchBox:SetScript("OnEditFocusLost",function(s)
    if s:GetText()=="" then s:SetText(WT_T("CUR_FILTER")); s._isPlaceholder=true end
end)
Tab6.searchBox:SetScript("OnTextChanged",function()
    if WT_UpdateCurrency then WT_UpdateCurrency() end
end)
Tab6.searchBox:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)

-- Scroll
Tab6.scroll=CreateFrame("ScrollFrame",nil,Tab6)
Tab6.scroll:SetPoint("TOPLEFT",Tab6,"TOPLEFT",1,-32)
Tab6.scroll:SetPoint("BOTTOMRIGHT",Tab6,"BOTTOMRIGHT",-12,4)
Tab6.scroll.content=CreateFrame("Frame",nil,Tab6.scroll)
Tab6.scroll.content:SetSize(UI_W-40,1)
Tab6.scroll:SetScrollChild(Tab6.scroll.content)
Tab6.scroll.content.crows={}
WT_MakeSAScrollbar(Tab6.scroll, Tab6)

-- ============================================================================
-- WT_UpdateRoster — Tab4: zelfde karakter lijst als Tab2 maar zonder zoekbalk
-- ============================================================================
-- Roster ProfessionBuddy-stijl: kaartjes per karakter v2.0
-- Race portrait + spec icoon + iLvl groot + professions onderaan
local ROSTER_CARD_W = 230  -- 3 cols * 230 + 2*8 = 706px
local ROSTER_CARD_H = 130  -- hoger voor profession rij + spec in hoek
local ROSTER_COLS   = 3  -- 3 cols past binnen 760px UI
local ROSTER_GAP    = 8

-- Race icon lookup (Achievement_Character_{race}_{faction})
-- ── DYNAMISCHE RACE DATA (gids DieOuwe §3/§4, v3.1.9) ───────────────────
-- C_CreatureInfo.GetRaceInfo(id) → {raceName (localized), clientFileString}
-- Hiermee bouwen we een reverse-lookup: localized naam → clientFile.
-- Repareert OUDE DB-entries ("Undead"→"Scourge") zonder her-inloggen!
local WT_RACE_IDS = {1,2,3,4,5,6,7,8,9,10,11,22,24,25,26,27,28,29,30,31,32,34,35,36,37}
local WT_RaceData = nil

local function WT_BuildRaceData()
    if WT_RaceData then return end
    WT_RaceData = { byLocalized = {}, byID = {} }
    if not (C_CreatureInfo and C_CreatureInfo.GetRaceInfo) then return end
    for _, id in ipairs(WT_RACE_IDS) do
        local ok, info = pcall(C_CreatureInfo.GetRaceInfo, id)
        if ok and info and info.raceName then
            local clientFile = info.clientFileString
            if not clientFile and Enum and Enum.Race then
                for k, v in pairs(Enum.Race) do
                    if v == id then clientFile = k; break end
                end
            end
            if clientFile then
                WT_RaceData.byID[id] = clientFile
                -- localized naam zonder spaties als sleutel ("Night Elf"→"NightElf")
                WT_RaceData.byLocalized[info.raceName:gsub("%s+","")] = clientFile
            end
        end
    end
end

-- ── RACE ATLAS SYSTEEM — EXACT overgenomen uit Constants.lua v3.5.1 ─────
-- (referentie: ProfessionBuddy, alle namen BEVESTIGD via TextureAtlasViewer
--  in WoW 12.0.5 Build 67314, tenzij anders aangegeven)
local RaceIconShortName = {
    -- ── Vanilla / TBC / Cata / MoP (basis rassen) ───────────
    ["Human"]              = "human",
    ["Orc"]                = "orc",
    ["Dwarf"]              = "dwarf",
    ["NightElf"]           = "nightelf",
    ["Scourge"]            = "scourge",    -- UnitRace 2e return voor Undead/Forsaken
    ["Undead"]             = "scourge",    -- defensieve alias
    ["Tauren"]             = "tauren",
    ["Gnome"]              = "gnome",
    ["Troll"]              = "troll",
    ["BloodElf"]           = "bloodelf",
    ["Draenei"]            = "draenei",
    ["Goblin"]             = "goblin",
    ["Worgen"]             = "worgen",
    ["Pandaren"]           = "pandaren",
    -- ── BfA Allied Races (8.0) — ALLE BEVESTIGD ✓ ──────────
    ["Nightborne"]         = "nightborne",
    ["HighmountainTauren"] = "highmountain",
    ["VoidElf"]            = "voidelf",
    ["LightforgedDraenei"] = "lightforged",
    ["ZandalariTroll"]     = "zandalari",
    ["KulTiran"]           = "kultiran",
    ["DarkIronDwarf"]      = "darkirondwarf",   -- ✓ WEL met dwarf-suffix!
    ["MagharOrc"]          = "magharorc",       -- ✓ WEL met orc-suffix!
    ["Mechagnome"]         = "mechagnome",
    ["Vulpera"]            = "vulpera",
    -- ── Dragonflight (10.0) ─────────────────────────────────
    ["Dracthyr"]           = "dracthyr",
    -- ── The War Within (11.0) ───────────────────────────────
    ["Earthen"]            = "earthen",
    ["EarthenDwarf"]       = "earthen",
    -- ── Midnight (12.x) — UnitRace 2e return = "Harronir" (dubbele r!) ──
    ["Harronir"]           = "haranir",
    ["Haranir"]            = "haranir",
}

local AlliedRaceCrestFallback = {
    ["Harronir"] = "AlliedRace-Crest-Haranir",  -- raceID=86, Midnight allied race
    ["Haranir"]  = "AlliedRace-Crest-Haranir",
}

-- DT_SetRaceIcon — fallback-keten (Constants.lua v3.5.1):
--   1. raceicon128-{naam}-{gender}  → volledig portret (alle rassen)
--   2. raceicon-{naam}-{gender}     → 64px portret (basis rassen)
--   2.5 AlliedRace-Crest-*          → nieuwe rassen zonder raceicon128
--   3. SetTexture(134400)           → vraagteken-icoon
local function DT_SetRaceIcon(texture, raceName, gender)
    if not texture then return false end

    local rName = raceName or "Human"
    local gStr  = (tonumber(gender) == 3) and "female" or "male"

    -- ── STAP 0 (v3.1.8, gids DieOuwe): officiële GetRaceAtlas API ──
    -- GetRaceAtlas(clientFileString, gender, isFullBody) genereert de
    -- atlas naam dynamisch — toekomstbestendig voor nieuwe rassen.
    -- Altijd valideren met GetAtlasInfo vóór gebruik.
    if GetRaceAtlas then
        local okA, dynAtlas = pcall(GetRaceAtlas, rName, gStr, true)
        if okA and dynAtlas and C_Texture and C_Texture.GetAtlasInfo
           and C_Texture.GetAtlasInfo(dynAtlas) then
            texture:SetAtlas(dynAtlas)
            texture:SetTexCoord(0,1,0,1)
            return true
        end
    end

    local shortName = RaceIconShortName[rName]
    if not shortName then
        -- Dynamische fallback voor onbekende toekomstige rassen
        shortName = rName:lower():gsub("[%s'%-]+", "")
    end

    local atlas128 = "raceicon128-" .. shortName .. "-" .. gStr
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas128) then
        texture:SetAtlas(atlas128)
        texture:SetTexCoord(0,1,0,1)
        return true
    end

    local atlas64 = "raceicon-" .. shortName .. "-" .. gStr
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas64) then
        texture:SetAtlas(atlas64)
        texture:SetTexCoord(0,1,0,1)
        return true
    end

    local crestAtlas = AlliedRaceCrestFallback[rName]
    if crestAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(crestAtlas) then
        texture:SetAtlas(crestAtlas)
        texture:SetTexCoord(0,1,0,1)
        return true
    end

    texture:SetTexture(134400)   -- vraagteken (beter zichtbaar dan blanco)
    texture:SetTexCoord(0.08,0.92,0.08,0.92)
    return false
end

WT_UpdateRoster = function()
    if not (Tab4.scroll and Tab4.scroll.content) then return end

    -- v3.3.2: CreateFramePool ReleaseAll (geen garbage, hergebruik)
    InitRosterPools(Tab4.scroll.content)
    rosterCardPool:ReleaseAll()

    -- v3.4.6: sorteer op klasse (WoW volgorde) → daarna naam
    local CLASS_ORDER = {
        WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,
        DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,
        MONK=10,DRUID=11,DEMONHUNTER=12,EVOKER=13,
    }
    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        table.insert(sorted,k)
    end
    table.sort(sorted, function(a, b)
        local da = DelveTrackerDB.characters[a]
        local db_ = DelveTrackerDB.characters[b]
        -- nil-safe: ontbrekende class → orde 99 (achteraan)
        local ca = da and da.class
        local cb = db_ and db_.class
        local oa = (ca and CLASS_ORDER[ca]) or 99
        local ob = (cb and CLASS_ORDER[cb]) or 99
        if oa ~= ob then return oa < ob end
        return a < b
    end)

    local visIdx = 0  -- v3.4.5: telt alleen zichtbare (niet-orphan) cards
    for _,key in ipairs(sorted) do
        local data=DelveTrackerDB.characters[key]
        -- skip orphaned entries zonder bruikbare data
        if not (data.class or data.level or data.race or (data.money and data.money > 0)) then
            -- orphan: geen kaartje, geen positie
        else
        visIdx = visIdx + 1
        local shortName=key:match("([^-]+)") or key
        local cc=RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}

        local col = (visIdx-1) % ROSTER_COLS
        local row = math.floor((visIdx-1) / ROSTER_COLS)
        -- v3.4.6: grid centrerend — bereken offset zodat 3-koloms grid
        -- horizontaal gecentreerd staat in het scroll-frame
        local _gridW  = ROSTER_COLS * ROSTER_CARD_W + (ROSTER_COLS-1) * ROSTER_GAP
        local _frameW = Tab4.scroll:GetWidth()
        local _xOff   = math.floor((_frameW > 0 and (_frameW - _gridW) or 0) / 2)
        local xPos = _xOff + col * (ROSTER_CARD_W + ROSTER_GAP)
        local yPos = -(row * (ROSTER_CARD_H + ROSTER_GAP) + ROSTER_GAP)

        -- v3.3.2: pool acquire
        local card = rosterCardPool:Acquire()
        if not card.backdrop_set then
            card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
            card.backdrop_set = true
        end
        card:SetSize(ROSTER_CARD_W, ROSTER_CARD_H)
        card:SetPoint("TOPLEFT",xPos,yPos)
        card:SetBackdropColor(cc.r*0.10, cc.g*0.10, cc.b*0.10, 0.95)
        card:SetBackdropBorderColor(cc.r*0.65, cc.g*0.65, cc.b*0.65, 0.9)
        card:Show()

        -- ── Race portrait groot linksboven (52x52) ───────────────────
        -- Spec icoon klein in hoek rechtsonder van race portrait
        -- Layout zelfde als ProfessionBuddy: groot race links, tekst rechts
        card.rIcon = card.rIcon or card:CreateTexture(nil,"ARTWORK")
        card.rIcon:SetSize(52,52)
        card.rIcon:SetPoint("TOPLEFT",4,-4)
        local raceTag = data.race or ""
        local facKey  = (data.faction=="Horde") and "horde" or "alliance"
        -- Klasse kleur achtergrond (altijd zichtbaar)
        if not card.rIconBg then
            card.rIconBg=card:CreateTexture(nil,"BACKGROUND")
            card.rIconBg:SetSize(52,52)
            card.rIconBg:SetPoint("TOPLEFT",4,-4)
        end
        card.rIconBg:SetColorTexture(cc.r*0.25,cc.g*0.25,cc.b*0.25,0.95)

        -- ── RACE PORTRAIT — via DT_SetRaceIcon (Constants.lua v3.5.1 patroon) ──
        -- v3.1.7: race onbekend (char nog niet ingelogd sinds scan-fix)
        -- → CLASS-icoon als nette fallback i.p.v. leeg vakje
        local gotIcon = false
        if raceTag ~= "" then
            gotIcon = DT_SetRaceIcon(card.rIcon, raceTag, data.gender or data.sex)
        end
        if not gotIcon then
            -- v3.1.8: moderne GetClassAtlas eerst (gids DieOuwe), dan legacy
            local clsAtlas = GetClassAtlas and data.class and GetClassAtlas(data.class)
            if clsAtlas and C_Texture and C_Texture.GetAtlasInfo
               and C_Texture.GetAtlasInfo(clsAtlas) then
                card.rIcon:SetAtlas(clsAtlas)
                card.rIcon:SetTexCoord(0,1,0,1)
            else
                local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
                if coords then
                    card.rIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                    card.rIcon:SetTexCoord(unpack(coords))
                else
                    card.rIcon:SetTexture(134400)
                    card.rIcon:SetTexCoord(0.08,0.92,0.08,0.92)
                end
            end
        end
        card.rIcon:SetAlpha(1.0)

        -- ── Spec icoon klein in rechtsonder hoek van race portrait (18x18) ──
        card.sIcon = card.sIcon or card:CreateTexture(nil,"OVERLAY")
        card.sIcon:SetSize(18,18)
        -- BOTTOMRIGHT van race portrait, -1px overlap voor hoek-effect
        card.sIcon:SetPoint("BOTTOMRIGHT",card.rIcon,"BOTTOMRIGHT",1,1)
        -- Spec icon: 4e return value van GetSpecializationInfoByID
        if data.specID and GetSpecializationInfoByID then
            local ok,_,_,_,sicon = pcall(GetSpecializationInfoByID, data.specID)
            if ok and sicon and sicon~=0 then
                card.sIcon:SetTexture(sicon)
                card.sIcon:SetTexCoord(0.08,0.92,0.08,0.92)
            else
                -- Fallback: klasse icoon
                local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
                if coords then
                    card.sIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                    card.sIcon:SetTexCoord(unpack(coords))
                end
            end
        elseif data.class then
            local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
            if coords then
                card.sIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                card.sIcon:SetTexCoord(unpack(coords))
            end
        end
        card.sIcon:SetTexCoord(0.08,0.92,0.08,0.92)

        -- ── Spec icoon border (kleine donkere rand voor leesbaarheid) ──
        card.sIconBorder = card.sIconBorder or card:CreateTexture(nil,"ARTWORK")
        card.sIconBorder:SetSize(20,20)
        card.sIconBorder:SetPoint("CENTER",card.sIcon,"CENTER",0,0)
        card.sIconBorder:SetColorTexture(0,0,0,0.6)
        card.sIconBorder:SetDrawLayer("ARTWORK",-1)

        -- ── Naam (klasse kleur) rechts van race portrait ──────────────
        card.nm = card.nm or card:CreateFontString(nil,"OVERLAY")
        card.nm:SetFont(C_2002,12,"OUTLINE")
        card.nm:SetPoint("TOPLEFT",card.rIcon,"TOPRIGHT",6,-2)
        card.nm:SetText(string.format("|cff%02x%02x%02x%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255), shortName))

        -- ── Lvl + iLvl rechts van portrait, onder naam ────────────────
        card.sp = card.sp or card:CreateFontString(nil,"OVERLAY")
        card.sp:SetFont(C_2002,9,"")
        card.sp:SetPoint("TOPLEFT",card.nm,"BOTTOMLEFT",0,-1)
        card.sp:SetText(SA_GREY..WT_T("LVL").." "..(data.level or "?").." · "..(data.spec or "??").."|r")

        -- ── iLvl groot rechtsboven kaartje ────────────────────────────
        card.ilvlTxt = card.ilvlTxt or card:CreateFontString(nil,"OVERLAY")
        card.ilvlTxt:SetFont(C_2002,16,"OUTLINE")
        card.ilvlTxt:SetPoint("TOPRIGHT",-4,-4)
        local ilvl = data.ilvl or 0
        local ilvlCol = ilvl>=270 and "|cffff8800" or ilvl>=250 and "|cff00ff00" or "|cffffffff"
        card.ilvlTxt:SetText(ilvlCol..ilvl.." ilv|r")

        -- ── Delve progress ────────────────────────────────────────────
        card.prgr = card.prgr or card:CreateFontString(nil,"OVERLAY")
        card.prgr:SetFont(C_2002,9,"OUTLINE")
        card.prgr:SetPoint("TOPLEFT",card.sp,"BOTTOMLEFT",0,-3)
        local st=""
        if data.delves then
            for _,v in ipairs(data.delves) do
                st=st..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r "
            end
        end
        card.prgr:SetText(st~="" and st or SA_GREY.."—|r")

        -- ── Gold onderaan rechts ──────────────────────────────────────
        card.gld = card.gld or card:CreateFontString(nil,"OVERLAY")
        card.gld:SetFont(C_2002,10,"OUTLINE")
        card.gld:SetPoint("BOTTOMRIGHT",-4,4)
        card.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        -- ── Faction dot linksonder ────────────────────────────────────
        card.fac = card.fac or card:CreateTexture(nil,"OVERLAY")
        card.fac:SetSize(8,8)
        card.fac:SetPoint("BOTTOMLEFT",4,6)
        if data.faction=="Horde" then card.fac:SetColorTexture(0.8,0.1,0.1,1)
        else card.fac:SetColorTexture(0.1,0.4,0.9,1) end

        -- ── Professions iconen onderaan (v3.1.6: POOL-hergebruik) ─────
        -- Voorheen: elke refresh nieuwe textures/buttons (alleen Hide op
        -- de oude) → texture-leak. Nu: vaste pool van 4 per kaart.
        if not card.profPool then
            card.profPool = {}
            for pi = 1, 4 do
                local px = 4+(pi-1)*20
                local pico = card:CreateTexture(nil,"OVERLAY")
                pico:SetSize(18,18)
                pico:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",px,20)
                pico:SetTexCoord(0.08,0.92,0.08,0.92)
                local pb = CreateFrame("Button",nil,card)
                pb:SetSize(18,18)
                pb:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",px,20)
                pb:SetScript("OnEnter",function(s)
                    if not s._prof then return end
                    GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
                    GameTooltip:SetText(SA_GOLD..(s._prof.name or "?"))
                    GameTooltip:AddLine(SA_GREY..(s._rank or 0).."/"..(s._max or 0).."|r")
                    GameTooltip:Show()
                end)
                pb:SetScript("OnLeave",function() GameTooltip:Hide() end)
                card.profPool[pi] = {ico=pico, btn=pb}
            end
        end
        for pi = 1, 4 do
            local slot = card.profPool[pi]
            local prof = data.professions and data.professions[pi]
            if prof then
                if prof.icon then slot.ico:SetTexture(prof.icon) end
                slot.btn._prof = prof
                slot.btn._rank = prof.rank or 0
                slot.btn._max  = prof.maxRank or 0
                slot.ico:Show(); slot.btn:Show()
            else
                slot.btn._prof = nil
                slot.ico:Hide(); slot.btn:Hide()
            end
        end

        -- ── Hover + click ─────────────────────────────────────────────
        local sn,d=shortName,data
        card:SetScript("OnEnter",function(self)
            self:SetBackdropBorderColor(1.0,0.85,0.0,1)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(SA_GOLD..sn)
            GameTooltip:AddLine(SA_GREY..(d.class or "?").." · "..(d.spec or "??").."|r")
            GameTooltip:AddLine(SA_GREY.."iLvl "..(d.ilvl or 0).."|r")
            if d.guild and d.guild~="Geen Guild" then
                GameTooltip:AddLine(SA_BLUE..d.guild.."|r")
            end
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave",function(self)
            self:SetBackdropBorderColor(cc.r*0.65,cc.g*0.65,cc.b*0.65,0.9)
            GameTooltip:Hide()
        end)
        card:SetScript("OnClick",function()
            if DT_Armory_ShowCharacter then
                d.name=sn; DT_Armory_ShowCharacter(d); PlaySound(852)
            end
        end)

        Tab4.scroll.content.rows[visIdx]=card
        end  -- else data-check
    end

    local totalRows = math.ceil(visIdx / ROSTER_COLS)
    Tab4.scroll.content:SetHeight(totalRows*(ROSTER_CARD_H+ROSTER_GAP)+ROSTER_GAP)
    Tab4.scroll.content:SetWidth(ROSTER_COLS*(ROSTER_CARD_W+ROSTER_GAP)-ROSTER_GAP)
end


WT_ShowArmory = function()
    local armFrame = _G["DT_ArmoryFrame"]
    if not armFrame then
        if not Tab5.loadTxt then
            Tab5.loadTxt=Tab5:CreateFontString(nil,"OVERLAY")
            Tab5.loadTxt:SetFont(C_2002,12,"")
            Tab5.loadTxt:SetPoint("CENTER")
            Tab5.loadTxt:SetText(SA_GREY..WT_T("ARMORY_LOADING").."|r")
        end
        return
    end

    -- Embed in Tab5: model links (420px), stats rechts
    if not Tab5.armoryEmbedded then
        Tab5.armoryEmbedded = true
        armFrame._embedded = true  -- voorkomt dat ResetArmoryPosition het verplaatst

        armFrame:SetParent(Tab5)
        armFrame:ClearAllPoints()
        armFrame:SetPoint("TOPLEFT",Tab5,"TOPLEFT",0,0)
        armFrame:SetSize(420, Tab5:GetHeight() or 404)
        armFrame:SetMovable(false)
        armFrame:SetFrameStrata("MEDIUM")
        armFrame:SetFrameLevel(Tab5:GetFrameLevel()+2)

        -- CloseBtn zichtbaar houden maar repositioneren
        if armFrame.closeBtn then
            armFrame.closeBtn:ClearAllPoints()
            armFrame.closeBtn:SetPoint("TOPRIGHT",armFrame,"TOPRIGHT",0,0)
            armFrame.closeBtn:Show()
            -- Close embedded: ga terug naar vorige tab
            armFrame.closeBtn:SetScript("OnClick",function()
                armFrame:Hide()
                if _G["DT_ArmoryStatsPanel"] then _G["DT_ArmoryStatsPanel"]:Hide() end
                Tab5.armoryEmbedded = nil
                armFrame._embedded = nil
                ShowTab(4)  -- terug naar Roster
            end)
        end
        if armFrame.btnPlus  then armFrame.btnPlus:Hide()  end
        if armFrame.btnMinus then armFrame.btnMinus:Hide() end

        -- Stats panel rechts
        local sp = _G["DT_ArmoryStatsPanel"]
        if sp then
            sp:SetParent(Tab5)
            sp:ClearAllPoints()
            sp:SetPoint("TOPLEFT",Tab5,"TOPLEFT",422,0)
            sp:SetPoint("BOTTOMRIGHT",Tab5,"BOTTOMRIGHT",0,0)
        end
    end

    -- Zorg dat armory zichtbaar is
    armFrame:Show()
    local sp = _G["DT_ArmoryStatsPanel"]
    if sp then sp:Show() end

    -- Haal verse data op voor huidig karakter
    local myKey=(UnitName("player") or "?").."-"..(GetNormalizedRealmName() or "?")
    local data=DelveTrackerDB.characters and DelveTrackerDB.characters[myKey]
    if data then
        if UnitStat then
            data.stats = {
                stamina = UnitStat("player",3),
                str     = UnitStat("player",1),
                agi     = UnitStat("player",2),
                int     = UnitStat("player",4),
                armor   = select(2,UnitArmor("player")),
            }
        end
        data.name  = UnitName("player") or data.name
        data.guild = GetGuildInfo("player") or data.guild or "Geen Guild"
        if DT_Armory_ShowCharacter then
            pcall(DT_Armory_ShowCharacter,data)
        end
    end
end

WT_UpdateGuildOnline = function()
    if not (Tab1.onlineScroll and Tab1.onlineScroll.content) then return end

    -- Verberg oude rijen
    for _,row in pairs(Tab1.onlineScroll.content.rows or {}) do row:Hide() end

    if not IsInGuild() then return end

    -- Bouw lijst van online leden
    -- v3.1.4: 11e return = classFileName ("WARRIOR") — VEREIST voor
    -- RAID_CLASS_COLORS en class-iconen. 5e return is de localized
    -- display naam ("Warrior") en matcht NIET als kleur-key!
    local online = {}
    local total  = GetNumGuildMembers()
    local myRealm = GetRealmName and GetRealmName() or ""
    for i=1,total do
        local name,rank,_,level,_,zone,_,_,connected,_,classFile = GetGuildRosterInfo(i)
        if connected and name then
            local shortName = name:match("([^-]+)") or name
            -- Warband match: staat dit lid in onze eigen DB? (race-portret!)
            local dbKey = name:find("-") and name or (shortName.."-"..myRealm)
            local own = DelveTrackerDB.characters and
                (DelveTrackerDB.characters[dbKey] or DelveTrackerDB.characters[name])
            table.insert(online, {
                name=shortName, rank=rank, level=level,
                class=classFile or "WARRIOR", zone=zone or "",
                own=own
            })
        end
    end

    -- Sorteer op naam
    table.sort(online, function(a,b) return a.name < b.name end)

    -- Update teller
    Tab1.onlineCount:SetText(SA_GOLD..#online.."|r  "..SA_GREY.."online|r")

    local ROW_H = 22
    local ROW_W = Tab1.onlineScroll:GetWidth() - 4

    for i,member in ipairs(online) do
        local r = Tab1.onlineScroll.content.rows[i]
        if not r then
            r = CreateFrame("Frame",nil,Tab1.onlineScroll.content)
        end
        r:SetSize(ROW_W, ROW_H)
        r:SetPoint("TOPLEFT",0,-(i-1)*ROW_H)
        r:Show()

        -- Status dot
        r.dot = r.dot or r:CreateTexture(nil,"OVERLAY")
        r.dot:SetSize(6,6)
        r.dot:SetPoint("LEFT",2,0)
        r.dot:SetColorTexture(0.20,0.90,0.40,1)  -- groen = online

        -- v3.1.4 (Fase 2.3): karakter-icoon — race-portret voor eigen
        -- warband chars (DT_SetRaceIcon), anders class-icoon
        r.pic = r.pic or r:CreateTexture(nil,"ARTWORK")
        r.pic:SetSize(16,16)
        r.pic:SetPoint("LEFT",11,0)
        local own = member.own
        local gotPortrait = false
        if own and own.race then
            gotPortrait = DT_SetRaceIcon(r.pic, own.race, own.gender or own.sex)
        end
        if not gotPortrait then
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.class]
            if coords then
                r.pic:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                r.pic:SetTexCoord(unpack(coords))
            else
                r.pic:SetTexture(134400)
                r.pic:SetTexCoord(0.08,0.92,0.08,0.92)
            end
        end

        -- Naam in klasse kleur
        r.nm = r.nm or r:CreateFontString(nil,"OVERLAY")
        r.nm:SetFont(C_2002,11,"")
        r.nm:SetPoint("LEFT",30,0)
        local cc = RAID_CLASS_COLORS[member.class] or {r=0.8,g=0.8,b=0.8}
        r.nm:SetText(string.format("|cff%02x%02x%02x%s|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            member.name))

        -- Level rechts
        r.lvl = r.lvl or r:CreateFontString(nil,"OVERLAY")
        r.lvl:SetFont(C_2002,9,"")
        r.lvl:SetPoint("RIGHT",0,0)
        r.lvl:SetText(SA_GREY..(member.level or "").."|r")

        Tab1.onlineScroll.content.rows[i] = r
    end
    Tab1.onlineScroll.content:SetHeight(#online * ROW_H + 4)
end

-- ============================================================================
-- WT_UpdateCurrency — Tab6: currency overzicht alle karakters
-- ============================================================================
local CURRENCY_IDS = {
    {id=3028, name="Restored Coffer Keys",  col="|cff00ccff"},
    {id=3310, name="Coffer Key Shards",     col="|cffffee00"},
    {id=3376, name="Shard of Dundun",       col="|cff44cc66"},
    {id=3378, name="Dawnlight Manaflux",    col="|cffa335ee"},
}

-- Currency grid constanten
local CUR_DEFS = {
    {id=3028, label="Keys",     icon="Interface\\Icons\\inv_misc_key_03",         col="|cff00ccff"},
    {id=3310, label="Shards",   icon="Interface\\Icons\\inv_misc_key_14",         col="|cffffee00"},
    {id=3376, label="Dundun",   icon="Interface\\Icons\\inv_jewelcrafting_gem_31",col="|cff44cc66"},
    {id=3378, label="Manaflux", icon="Interface\\Icons\\inv_misc_gem_amethyst_02",col="|cffa335ee"},
}
local CUR_CARD_W = 90
local CUR_CARD_H = 60
local CUR_CARD_GAP = 6
local CUR_ROW_H = 34  -- karakter naamrij
local CUR_ROW_GAP = 4

WT_UpdateCurrency = function()
    if not (Tab6.scroll and Tab6.scroll.content) then return end

    -- Filter van zoekbalk
    local filter = ""
    if Tab6.searchBox then
        local t = Tab6.searchBox:GetText() or ""
        if t ~= "Filter karakter..." then filter = t:lower() end
    end

    -- v3.3.6: pool ReleaseAll — nul garbage (aparte init voor juiste parent)
    InitCurrPools(Tab6.scroll.content)
    currNameRowPool:ReleaseAll()
    currTilePool:ReleaseAll()
    currScrollPool:ReleaseAll()
    currArrowPool:ReleaseAll()

    -- Currency definities — alle expansies van nieuw naar oud
    -- Filter op naam als zoekbalk gevuld
    local curFilter = ""
    if Tab6.searchBox then
        local t = Tab6.searchBox:GetText() or ""
        if t ~= "Filter currency naam..." then curFilter = t:lower() end
    end

    local function getCurInfo(id)
        if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
            local ok,info = pcall(C_CurrencyInfo.GetCurrencyInfo,id)
            -- Alleen geldig als er ECHT een naam en icoon is — anders blanco tegel
            if ok and info and info.name and info.name ~= "" and info.iconFileID and info.iconFileID > 0 then
                return info.iconFileID, info.name
            end
        end
        return nil, tostring(id)
    end

    -- Volledige lijst alle currencies — gesorteerd op relevantie
    -- Volledige lijst alle currencies — IDs geverifieerd via DataStore Enum
    -- (sessie 2026-06-12) · gesorteerd nieuw → oud per expansie
    local CUR_DEFS_ALL = {
        -- ── MIDNIGHT 12.x — DELVES & KEYS (was al goed) ─────────────
        {id=3028, label="Restored Coffer Key",  col="|cff00ccff", expac="Midnight"},
        {id=3310, label="Coffer Key Shards",    col="|cffffee00", expac="Midnight"},
        {id=3376, label="Shard of Dundun",      col="|cff44cc66", expac="Midnight"},
        {id=3378, label="Dawnlight Manaflux",   col="|cff27e0dc", expac="Midnight"},
        -- ── MIDNIGHT 12.x — NA MANAFLUX: Dawncrest + rest Midnight ──
        -- Adventurer → Myth (laag → hoog)
        {id=3383, label="Adventurer Dawncrest", col="|cffaaaaaa", expac="Midnight"},
        {id=3341, label="Veteran Dawncrest",    col="|cfffff027", expac="Midnight"},
        {id=3343, label="Champion Dawncrest",   col="|cff0071e0", expac="Midnight"},
        {id=3345, label="Hero Dawncrest",       col="|cffcc88ff", expac="Midnight"},
        {id=3347, label="Myth Dawncrest",       col="|cff00ccff", expac="Midnight"},
        {id=3008, label="Valorstones",          col="|cffff9900", expac="Midnight"},
        {id=3377, label="Unalloyed Abundance",  col="|cff55ff55", expac="Midnight"},
        {id=3316, label="Voidlight Marl",       col="|cff8866cc", expac="Midnight"},
        {id=3379, label="Brimming Arcana",      col="|cffcc66ff", expac="Midnight"},
        {id=3385, label="Luminous Dust",        col="|cffffee88", expac="Midnight"},
        {id=3392, label="Remnant of Anguish",   col="|cffcc3333", expac="Midnight"},
        {id=3318, label="Delver's Journey",     col="|cff44aaff", expac="Midnight"},
        {id=2803, label="Undercoin",            col="|cff665588", expac="Midnight"},
        -- ── THE WAR WITHIN 11.2 (DataStore) ─────────────────────────
        {id=3284, label="Weathered Ethereal Crest",    col="|cff99aa77", expac="War Within"},
        {id=3286, label="Carved Ethereal Crest",       col="|cff88bb55", expac="War Within"},
        {id=3288, label="Runed Ethereal Crest",        col="|cff77cc44", expac="War Within"},
        {id=3290, label="Gilded Ethereal Crest",       col="|cffccaa00", expac="War Within"},
        -- ── THE WAR WITHIN 11.1 (DataStore) ─────────────────────────
        {id=3107, label="Weathered Undermine Crest",   col="|cff99aa77", expac="War Within"},
        {id=3108, label="Carved Undermine Crest",      col="|cff88bb55", expac="War Within"},
        {id=3109, label="Runed Undermine Crest",       col="|cff77cc44", expac="War Within"},
        {id=3110, label="Gilded Undermine Crest",      col="|cffccaa00", expac="War Within"},
        -- ── THE WAR WITHIN 11.0 (DataStore) ─────────────────────────
        {id=3008, label="Valorstones",                 col="|cff4488cc", expac="War Within"},
        {id=2803, label="Undercoin",                   col="|cff665588", expac="War Within"},
        {id=2815, label="Resonance Crystals",          col="|cff88ddff", expac="War Within"},
        {id=2914, label="Weathered Harbinger Crest",   col="|cff99aa77", expac="War Within"},
        {id=2915, label="Carved Harbinger Crest",      col="|cff88bb55", expac="War Within"},
        {id=2916, label="Runed Harbinger Crest",       col="|cff77cc44", expac="War Within"},
        {id=2917, label="Gilded Harbinger Crest",      col="|cffccaa00", expac="War Within"},
        {id=3055, label="Mereldar Derby Mark",         col="|cffdd88dd", expac="War Within"},
        {id=3056, label="Kej",                         col="|cff88dd88", expac="War Within"},
        {id=3089, label="Residual Memories",           col="|cffaa99ff", expac="War Within"},
        {id=3093, label="Nerub-ar Finery",             col="|cff8888dd", expac="War Within"},
        {id=3100, label="Bronze Celebration Token",    col="|cffcc8844", expac="War Within"},
        -- ── DRAGONFLIGHT (DataStore) ─────────────────────────────────
        {id=2245, label="Flightstones",                col="|cff55aa88", expac="Dragonflight"},
        {id=2003, label="Dragon Isles Supplies",       col="|cff44aa99", expac="Dragonflight"},
        {id=2118, label="Elemental Overflow",          col="|cffff7733", expac="Dragonflight"},
        {id=2122, label="Storm Sigil",                 col="|cff66aaff", expac="Dragonflight"},
        {id=2594, label="Paracausal Flakes",           col="|cffccbb66", expac="Dragonflight"},
        {id=2588, label="Riders of Azeroth Badge",     col="|cff77cc99", expac="Dragonflight"},
        {id=2706, label="Whelpling's Dreaming Crest",  col="|cff99aa77", expac="Dragonflight"},
        {id=2707, label="Drake's Dreaming Crest",      col="|cff88bb55", expac="Dragonflight"},
        {id=2708, label="Wyrm's Dreaming Crest",       col="|cff77cc44", expac="Dragonflight"},
        {id=2709, label="Aspect's Dreaming Crest",     col="|cffccaa00", expac="Dragonflight"},
        {id=2650, label="Emerald Dewdrop",             col="|cff55dd88", expac="Dragonflight"},
        {id=2777, label="Dream Infusion",              col="|cffaaffcc", expac="Dragonflight"},
        {id=2657, label="Mysterious Fragment",         col="|cff9988bb", expac="Dragonflight"},
        -- ── SHADOWLANDS (DataStore) ──────────────────────────────────
        {id=1813, label="Reservoir Anima",             col="|cff66ccff", expac="Shadowlands"},
        {id=1810, label="Redeemed Soul",               col="|cffaaddff", expac="Shadowlands"},
        {id=1828, label="Soul Ash",                    col="|cff7788cc", expac="Shadowlands"},
        {id=1906, label="Soul Cinders",                col="|cff4455dd", expac="Shadowlands"},
        {id=1767, label="Stygia",                      col="|cff2244aa", expac="Shadowlands"},
        {id=1977, label="Stygian Ember",               col="|cff5566bb", expac="Shadowlands"},
        {id=1904, label="Tower Knowledge",             col="|cff8899dd", expac="Shadowlands"},
        {id=1931, label="Cataloged Research",          col="|cff77aacc", expac="Shadowlands"},
        {id=1979, label="Cyphers of the First Ones",   col="|cffbbaa88", expac="Shadowlands"},
        {id=2009, label="Cosmic Flux",                 col="|cffcc99ee", expac="Shadowlands"},
        -- ── BATTLE FOR AZEROTH (DataStore) ───────────────────────────
        {id=1560, label="War Resources",               col="|cffcc4400", expac="BfA"},
        {id=1580, label="Seals of Wartorn Fate",       col="|cffddbb44", expac="BfA"},
        {id=1710, label="Seafarer's Dubloon",          col="|cff77bbcc", expac="BfA"},
        {id=1565, label="Rich Azerite Fragment",       col="|cffff8800", expac="BfA"},
        {id=1755, label="Coalescing Visions",          col="|cff8866bb", expac="BfA"},
        {id=1718, label="Titan Residuum",              col="|cffaaaacc", expac="BfA"},
        -- ── LEGION (DataStore) ───────────────────────────────────────
        {id=1220, label="Order Resources",             col="|cff88aa66", expac="Legion"},
        {id=1342, label="Legionfall War Supplies",     col="|cff99cc55", expac="Legion"},
        {id=1226, label="Nethershard",                 col="|cffbb66dd", expac="Legion"},
        {id=1273, label="Seal of Broken Fate",         col="|cffddbb44", expac="Legion"},
        {id=1155, label="Ancient Mana",                col="|cff66ccee", expac="Legion"},
        {id=1508, label="Veiled Argunite",             col="|cffcc88ff", expac="Legion"},
        -- ── WARLORDS OF DRAENOR (DataStore) ──────────────────────────
        {id=824,  label="Garrison Resources",          col="|cffaa8855", expac="WoD"},
        {id=823,  label="Apexis Crystal",              col="|cffeebb44", expac="WoD"},
        {id=1101, label="Oil",                         col="|cff445566", expac="WoD"},
        -- ── MISTS OF PANDARIA (DataStore) ────────────────────────────
        {id=777,  label="Timeless Coin",               col="|cffddcc77", expac="MoP"},
        {id=402,  label="Ironpaw Token",               col="|cffcc9955", expac="MoP"},
        -- ── PvP & MISC (DataStore) ───────────────────────────────────
        {id=1792, label="Honor",                       col="|cffaaffaa", expac="PvP"},
        {id=1602, label="Conquest",                    col="|cffff4444", expac="PvP"},
        {id=1166, label="Timewarped Badge",            col="|cff77aadd", expac="Misc"},
        {id=515,  label="Darkmoon Prize Ticket",       col="|cffcc77cc", expac="Misc"},
    }

    -- Filter op naam als curFilter gevuld
    local CUR_DEFS = {}
    local seenIDs = {}
    for _,def in ipairs(CUR_DEFS_ALL) do
        if not seenIDs[def.id] then
            if curFilter == "" or def.label:lower():find(curFilter,1,true) or (def.expac and def.expac:lower():find(curFilter,1,true)) then
                -- Check of karakter echt iets heeft
                table.insert(CUR_DEFS, def)
                seenIDs[def.id] = true
            end
        end
    end

    -- Haal live iconen op (eenmalig) en FILTER blanco currencies eruit:
    -- als C_CurrencyInfo geen info/icoon geeft bestaat de currency niet
    -- (meer) op deze client → niet tonen i.p.v. blanco tegel
    local validDefs = {}
    for _,def in ipairs(CUR_DEFS) do
        if def.iconID == nil and def.checked ~= true then
            def.iconID, def.liveName = getCurInfo(def.id)
            def.checked = true
            if def.liveName and def.liveName ~= tostring(def.id) then
                def.label = def.liveName
            end
        end
        if def.iconID then
            table.insert(validDefs, def)
        end
    end
    CUR_DEFS = validDefs

    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        if filter=="" or k:lower():find(filter,1,true) then
            table.insert(sorted,k)
        end
    end
    table.sort(sorted)

    local TILE_W = 48  -- compacter: meer tiles zichtbaar
    local TILE_H = 46  -- icoon 22px (2x kleiner dan voorheen) + waarde
    local TILE_G = 4
    local COLS   = math.floor((UI_W-46) / (TILE_W+TILE_G))
    local ROW_H  = 30  -- karakter naam rij
    local yOff   = -4

    for ci,key in ipairs(sorted) do
        local data = DelveTrackerDB.characters[key]
        local cur  = data.currencies or {}
        local shortName = key:match("([^-]+)") or key
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}

        -- Karakter naam header rij (v3.3.2: pool)
        local nameRow = currNameRowPool:Acquire()
        if not nameRow.backdrop_set then
            nameRow:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
            nameRow.backdrop_set = true
        end
        nameRow:SetSize(UI_W-46, ROW_H)
        nameRow:SetPoint("TOPLEFT",0,yOff)
        nameRow:SetBackdropColor(0.10,0.05,0.16,0.9)
        nameRow:SetBackdropBorderColor(0.40,0.10,0.60,0.7)
        nameRow:Show()

        -- v3.3.7: hergebruik bestaande FontStrings op gepoold frame
        if not nameRow.nm then
            nameRow.nm=nameRow:CreateFontString(nil,"OVERLAY")
            nameRow.nm:SetFont(C_2002,12,"OUTLINE")
            nameRow.nm:SetPoint("LEFT",8,0)
        end
        nameRow.nm:SetText(string.format("|cff%02x%02x%02x%s|r  "..SA_GREY.."%s · iLvl %d|r",
            math.floor(cc.r*255),math.floor(cc.g*255),math.floor(cc.b*255),
            shortName, data.spec or "??", data.ilvl or 0))
        if not nameRow.gld then
            nameRow.gld=nameRow:CreateFontString(nil,"OVERLAY")
            nameRow.gld:SetFont(C_2002,11,"OUTLINE")
            nameRow.gld:SetPoint("RIGHT",-8,0)
        end
        nameRow.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        -- (pool beheert levensduur)
        yOff = yOff - ROW_H - 2

        -- Horizontale ScrollFrame voor currency tiles (v3.3.2: pool)
        local hScrollW = UI_W - 48
        local hScroll = currScrollPool:Acquire()
        hScroll:SetSize(hScrollW - 36, TILE_H)
        hScroll:SetPoint("TOPLEFT",18,yOff)

        -- Scroll child hergebruiken of aanmaken (v3.3.7: explicit Show)
        hScroll:Show()
        if not hScroll.hContent then
            hScroll.hContent = CreateFrame("Frame",nil,hScroll)
        end
        local hContent = hScroll.hContent
        local totalTileW = #CUR_DEFS*(TILE_W+TILE_G)
        hContent:SetSize(totalTileW, TILE_H)
        hContent:Show()
        hScroll:SetScrollChild(hContent)

        -- Linker/rechter pijl knoppen (v3.3.2: pool)
        local function MakeArrow(dir)
            local b=currArrowPool:Acquire()
            if not b.backdrop_set then
                b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
                b.backdrop_set = true
            end
            local _ = nil -- dummy om Lua-stijl consistent te houden
            b:SetSize(16,TILE_H)
            b:SetBackdropColor(0.08,0.04,0.12,0.9)
            b:SetBackdropBorderColor(0.30,0.08,0.50,0.8)
            local t=b:CreateFontString(nil,"OVERLAY")
            t:SetFont(C_2002,12,"OUTLINE"); t:SetPoint("CENTER")
            t:SetText(dir=="left" and SA_GREY.."◀|r" or SA_GREY.."▶|r")
            b:SetScript("OnClick",function()
                local cur=hScroll:GetHorizontalScroll()
                local step=TILE_W+TILE_G
                if dir=="left" then
                    hScroll:SetHorizontalScroll(math.max(0,cur-step))
                else
                    hScroll:SetHorizontalScroll(math.min(totalTileW-hScrollW,cur+step))
                end
            end)
            return b
        end

        -- Pijlen naast de hscroll
        local ARROW_W = 18
        local lArrow = MakeArrow("left")
        lArrow:SetSize(ARROW_W, TILE_H)
        lArrow:SetPoint("TOPLEFT",0,yOff)
        lArrow:Show()
        local rArrow = MakeArrow("right")
        rArrow:SetSize(ARROW_W, TILE_H)
        rArrow:SetPoint("TOPLEFT",hScrollW-ARROW_W,yOff)
        rArrow:Show()

        -- Tiles in de horizontale scroll content
        local cards = {}
        for j,def in ipairs(CUR_DEFS) do
            local val = cur[def.id] or 0
            local xPos = (j-1)*(TILE_W+TILE_G)

            -- v3.3.2: tile uit pool
            local card = currTilePool:Acquire()
            card:SetParent(hContent)
            if not card.backdrop_set then
                card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
                card.backdrop_set = true
            end
            card:SetSize(TILE_W,TILE_H)
            card:SetPoint("TOPLEFT",xPos,0)
            card:SetBackdropColor(0.07,0.03,0.12,(val>0 and 0.95 or 0.55))
            card:SetBackdropBorderColor(
                val>0 and 0.50 or 0.15, 0.05,
                val>0 and 0.75 or 0.25,
                val>0 and 1.0  or 0.4)
            card:Show()

            -- Icoon (hergebruik op gepoold frame)
            if not card.ico then
                card.ico=card:CreateTexture(nil,"ARTWORK")
                card.ico:SetSize(22, 22)
                card.ico:SetPoint("TOP",card,"TOP",0,-3)
                card.ico:SetTexCoord(0.08,0.92,0.08,0.92)
            end
            card.ico:SetTexture(def.iconID or 134400)
            card.ico:SetAlpha(val>0 and 1.0 or 0.3)
            card.ico:Show()

            -- Waarde (hergebruik op gepoold frame)
            if not card.valTxt then
                card.valTxt=card:CreateFontString(nil,"OVERLAY")
                card.valTxt:SetFont(C_2002,12,"OUTLINE")
                card.valTxt:SetPoint("BOTTOM",card,"BOTTOM",0,3)
            end
            card.valTxt:SetText((val>0 and def.col or SA_GREY)..val.."|r")

            -- Tooltip
            local lbl,vl,sn=def.label,val,shortName
            card:SetScript("OnEnter",function(self)
                self:SetBackdropBorderColor(0.85,0.70,0.10,1)
                GameTooltip:SetOwner(self,"ANCHOR_TOP")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(def.col..lbl.."|r")
                GameTooltip:AddLine(SA_GREY..sn..": |cffffffff"..vl.."|r")
                if def.expac then GameTooltip:AddLine(SA_GREY..def.expac.."|r") end
                if vl==0 then GameTooltip:AddLine("|cffff5555"..WT_T("NONE_ON_CHAR").."|r") end
                GameTooltip:Show()
            end)
            card:SetScript("OnLeave",function(self)
                self:SetBackdropBorderColor(
                    vl>0 and 0.50 or 0.15, 0.05,
                    vl>0 and 0.75 or 0.25, vl>0 and 1.0 or 0.4)
                GameTooltip:Hide()
            end)
            table.insert(cards,card)
        end

        Tab6.scroll.content.crows["hs_"..ci]    = hScroll
        Tab6.scroll.content.crows["la_"..ci]    = lArrow
        Tab6.scroll.content.crows["ra_"..ci]    = rArrow
        Tab6.scroll.content.crows["cards_"..ci] = cards
        yOff = yOff - TILE_H - TILE_G
    end

    Tab6.scroll.content:SetHeight(-yOff + 10)
end


-- ── GUILD ROSTER UPDATE EVENT ─────────────────────────────────────────────
-- GUILD_ROSTER_UPDATE vuurt nadat GuildRoster() data opgehaald heeft
-- GUILD_MOTD vuurt met de motd-tekst als argument (taint-vrij)
local guildEventFrame = CreateFrame("Frame")
guildEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
guildEventFrame:RegisterEvent("GUILD_MOTD")
guildEventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "GUILD_MOTD" then
        WT_SetCachedMOTD(arg1)
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- v3.2.9 OPTIE B: roster-update als extra MOTD-trigger — vult de
        -- cache OOK als de tab dicht is, zodat hij klaar staat bij openen
        WT_GetMOTD()
    end
    if not Tab1:IsShown() then return end
    -- MOTD via cache (nooit protected call)
    local motd = WT_GetMOTD()
    if Tab1.motdText then
        Tab1.motdText:SetText(motd ~= "" and (SA_GREY..motd.."|r") or SA_GREY..WT_T("NO_MOTD").."|r")
    end
    WT_UpdateGuildOnline()
end)

-- ── FOOTER ────────────────────────────────────────────────────────────────
local FtrBG=UI:CreateTexture(nil,"BACKGROUND")
FtrBG:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",1,1)
FtrBG:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-1,1)
FtrBG:SetHeight(FOOTER_H)
FtrBG:SetColorTexture(0.04,0.02,0.07,1)

local FtrLine=UI:CreateTexture(nil,"OVERLAY")
FtrLine:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",1,FOOTER_H)
FtrLine:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-1,FOOTER_H)
FtrLine:SetHeight(1)
FtrLine:SetColorTexture(0.30,0.07,0.50,0.6)

local dcLbl=UI:CreateFontString(nil,"OVERLAY")
dcLbl:SetFont(C_2002,9,"OUTLINE")
dcLbl:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",14,FOOTER_H-18)
dcLbl:SetTextColor(0.60,0.45,0.80,1)
dcLbl:SetText(SA_GOLD.."CTRL+C — Discord:|r")

local dBox=CreateFrame("EditBox",nil,UI,"BackdropTemplate")
dBox:SetSize(280,20)
dBox:SetPoint("LEFT",dcLbl,"RIGHT",6,0)
dBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
dBox:SetBackdropColor(0,0,0,0.9)
dBox:SetBackdropBorderColor(0.25,0.07,0.40,1)
dBox:SetFontObject("ChatFontNormal")
dBox:SetText("https://slayeralliance.com/discord")
dBox:SetAutoFocus(false)
dBox:SetJustifyH("LEFT")
dBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)

-- Scale +/- knoppen (traag: 0.05 stap)
local scaleValTxt=UI:CreateFontString(nil,"OVERLAY")
scaleValTxt:SetFont(C_2002,9,"OUTLINE")
scaleValTxt:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-70,10)
scaleValTxt:SetText("1.00")
scaleValTxt:SetTextColor(0.75,0.55,1,1)

local scaleLbl=UI:CreateFontString(nil,"OVERLAY")
UI.scaleLbl=scaleLbl   -- v3.2.0: bereikbaar voor WT_ApplyLanguage
scaleLbl:SetFont(C_2002,9,"")
scaleLbl:SetPoint("BOTTOM",scaleValTxt,"TOP",0,2)
scaleLbl:SetText(SA_GREY..WT_T("SCALE").."|r")

local function MakeScaleBtn(lbl,xOff,fn)
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(26,20)
    b:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",xOff,8)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.08,0.04,0.14,1)
    b:SetBackdropBorderColor(0.30,0.08,0.50,1)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,13,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText(SA_PURPLE..lbl.."|r")
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.30,0.08,0.50,1) end)
    return b
end
MakeScaleBtn("+",-36,function()
    local c=DelveTrackerDB.mainScale or 1.0
    local n=math.min(2.0,math.floor((c+SCALE_STEP)*100+0.5)/100)
    DelveTrackerDB.mainScale=n; UI:SetScale(n)
    scaleValTxt:SetText(string.format("%.2f",n))
end)
MakeScaleBtn("-",-8,function()
    local c=DelveTrackerDB.mainScale or 1.0
    local n=math.max(0.5,math.floor((c-SCALE_STEP)*100+0.5)/100)
    DelveTrackerDB.mainScale=n; UI:SetScale(n)
    scaleValTxt:SetText(string.format("%.2f",n))
end)

-- Snelknoppen links in footer — breed genoeg dat ze binnen 760px vallen
-- Layout: [Cloth][Skin][Prey] links · [Debug] rechts naast schaal knoppen
local BTN_W = 72
local BTN_H = 22
local BTN_Y = 8  -- van onderkant

local function MakePluginBtn(lbl, col, xOff, fn)
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(BTN_W,BTN_H)
    b:SetPoint("BOTTOMLEFT",UI,"BOTTOMLEFT",xOff,BTN_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.06,0.03,0.10,0.95)
    b:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText(col..lbl.."|r")
    b:SetScript("OnClick",fn)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.28,0.08,0.45,0.9) end)
    return b
end

-- Links: Cloth | Skin | Prey (4px gap ertussen)
local GAP = 4
MakePluginBtn("🧵 Cloth","|cff44aaff", 4, function()
    if SlashCmdList["CBUDGET"] then SlashCmdList["CBUDGET"]("")
    elseif SlashCmdList["CBUD"] then SlashCmdList["CBUD"]("") end
end)
MakePluginBtn("🐾 Skin","|cff44cc66", 4+BTN_W+GAP, function()
    if SlashCmdList["MAJESTICTRACKER"] then SlashCmdList["MAJESTICTRACKER"]("")
    elseif SlashCmdList["SNR"] then SlashCmdList["SNR"]("") end
end)
MakePluginBtn("🎯 Prey+","|cffff6644", 4+(BTN_W+GAP)*2, function()
    if SlashCmdList["DTPREY"] then SlashCmdList["DTPREY"]("") end
end)

-- Rechts: Debug naast de +/- schaal knoppen
-- Debug knop rechtsonder naast +/- knoppen, BOVEN de discord box
local function MakeDebugBtn()
    local b=CreateFrame("Button",nil,UI,"BackdropTemplate")
    b:SetSize(BTN_W,BTN_H)
    -- Rechts naast de +/- schaal knoppen (schaal eindigt op -8, debug er net links van)
    b:SetPoint("BOTTOMRIGHT",UI,"BOTTOMRIGHT",-52-BTN_W,BTN_Y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.06,0.03,0.10,0.95)
    b:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local t=b:CreateFontString(nil,"OVERLAY")
    t:SetFont(C_2002,10,"OUTLINE")
    t:SetPoint("CENTER")
    t:SetText("|cff887799Debug|r")
    b:SetScript("OnClick",function()
        local f=_G["DT_DebugFrame"]
        if f then if f:IsShown() then f:Hide() else f:Show() end
        elseif SlashCmdList["DTDEBUG"] then SlashCmdList["DTDEBUG"]("") end
    end)

    -- v3.1.7: WARBANK knop links van Debug (Fase 2.x verzoek DieOuwe)
    local wb=CreateFrame("Button",nil,UI,"BackdropTemplate")
    wb:SetSize(BTN_W,BTN_H)
    wb:SetPoint("RIGHT",b,"LEFT",-4,0)
    wb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    wb:SetBackdropColor(0.06,0.03,0.10,0.95)
    wb:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local wt=wb:CreateFontString(nil,"OVERLAY")
    wt:SetFont(C_2002,10,"OUTLINE")
    wt:SetPoint("CENTER")
    wt:SetText(SA_GOLD.."Warbank|r")
    wb:SetScript("OnClick",function()
        local f=_G["ClothWidgetFrame"] and _G["DT_WarbankFrame"] or nil
        -- WarbankBuddy frame heet WBB intern; toggle via slash (altijd aanwezig)
        if SlashCmdList["WARBANKBUDDY"] then SlashCmdList["WARBANKBUDDY"]("")
        else print(SA_PURPLE.."[WowTracker]|r WarbankBuddy plugin niet geladen") end
    end)
    wb:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.70,0.10,1) end)
    wb:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.28,0.08,0.45,0.9) end)

    -- v3.2.6: VAULT knop — opent de Great Vault (Blizzard_WeeklyRewards LoD)
    local vb=CreateFrame("Button",nil,UI,"BackdropTemplate")
    vb:SetSize(BTN_W,BTN_H)
    vb:SetPoint("RIGHT",wb,"LEFT",-4,0)
    vb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    vb:SetBackdropColor(0.06,0.03,0.10,0.95)
    vb:SetBackdropBorderColor(0.28,0.08,0.45,0.9)
    local vt=vb:CreateFontString(nil,"OVERLAY")
    vt:SetFont(C_2002,10,"OUTLINE")
    vt:SetPoint("CENTER")
    vt:SetText(SA_BLUE.."Vault|r")
    vb:SetScript("OnClick",function()
        if InCombatLockdown() then return end
        if C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_WeeklyRewards")
        end
        local f = _G["WeeklyRewardsFrame"]
        if f then
            if f:IsShown() then HideUIPanel(f) else ShowUIPanel(f) end
        end
    end)
    vb:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.10,0.70,0.95,1) end)
    vb:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.28,0.08,0.45,0.9) end)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(0.28,0.08,0.45,0.9) end)
end
MakeDebugBtn()

-- ── DATA ──────────────────────────────────────────────────────────────────
-- ── WEEKLY RESET v3.2.5 (Fase 3.4 — DataStore Cleanup.lua patroon) ────
-- Oude versie gebruikte epoch-weken (wisselt do 00:00 UTC) — FOUT voor
-- regionale resets. Nu: GetCVar("portal") → EU=woensdag(3) 6:00,
-- US=dinsdag(2), CN/KR/TW=donderdag(4). Next-reset als datum in DB.
local WR_DAYS_PER_MONTH = {31,28,31,30,31,30,31,31,30,31,30,31}

local function WT_GetWeeklyResetDay()
    local region = GetCVar and GetCVar("portal")
    if region == "EU" then return 3
    elseif region == "CN" or region == "KR" or region == "TW" then return 4 end
    return 2  -- US/default: dinsdag
end

local function WT_NextWeeklyReset(resetDay, resetHour)
    local year  = tonumber(date("%Y"))
    local month = tonumber(date("%m"))
    local day   = tonumber(date("%d"))
    local wd    = tonumber(date("%w"))
    local add
    if wd < resetDay then add = resetDay - wd
    elseif wd > resetDay then add = resetDay - wd + 7
    else add = (tonumber(date("%H")) >= resetHour) and 7 or 0 end
    if add == 0 then return date("%Y-%m-%d") end
    -- schrikkeljaar
    WR_DAYS_PER_MONTH[2] = ((year%4==0) and (year%100~=0 or year%400==0)) and 29 or 28
    local nd = day + add
    if nd <= WR_DAYS_PER_MONTH[month] then
        return string.format("%04d-%02d-%02d", year, month, nd)
    end
    if month <= 11 then
        return string.format("%04d-%02d-%02d", year, month+1, nd - WR_DAYS_PER_MONTH[month])
    end
    return string.format("%04d-%02d-%02d", year+1, 1, nd - WR_DAYS_PER_MONTH[month])
end

local function CheckWeeklyReset()
    DelveTrackerDB.WeeklyReset = DelveTrackerDB.WeeklyReset or {}
    local wr = DelveTrackerDB.WeeklyReset
    local resetDay, resetHour = WT_GetWeeklyResetDay(), 6
    DelveTrackerDB.lastResetWeek = nil   -- oude epoch-week opruimen

    if not wr.nextReset then
        wr.day, wr.hour, wr.nextReset = resetDay, resetHour, WT_NextWeeklyReset(resetDay, resetHour)
        return
    end
    local today = date("%Y-%m-%d")
    if today < wr.nextReset then return end
    if today == wr.nextReset and tonumber(date("%H")) < (wr.hour or 6) then return end
    -- ── RESET: weekly velden wissen ──
    if DelveTrackerDB.characters then
        for _,d in pairs(DelveTrackerDB.characters) do d.delves={}; d.totalDone=0 end
    end
    wr.day, wr.hour, wr.nextReset = resetDay, resetHour, WT_NextWeeklyReset(resetDay, resetHour)
end

ScanDelves = function()
    CheckWeeklyReset()
    local name=UnitName("player"); local realm=GetNormalizedRealmName()
    if not name or not realm then return end
    local key=name.."-"..realm
    DelveTrackerDB.characters=DelveTrackerDB.characters or {}
    DelveTrackerDB.characters[key]=DelveTrackerDB.characters[key] or {}
    local d=DelveTrackerDB.characters[key]
    local _,class=UnitClass("player")
    local si=GetSpecialization and GetSpecialization()
    d.class   = class
    d.faction = UnitFactionGroup("player")
    d.spec    = si and select(2,GetSpecializationInfo(si)) or "No spec"
    local _,ilvl=GetAverageItemLevel()
    d.ilvl    = math.floor(ilvl or 0)
    d.level   = UnitLevel("player")
    d.money   = GetMoney() or 0   -- FIX: nu echt geschreven
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities and Enum and Enum.WeeklyRewardChestThresholdType then
        local ok,acts=pcall(C_WeeklyRewards.GetActivities,Enum.WeeklyRewardChestThresholdType.World)
        if ok and acts then
            d.delves={}; d.totalDone=0
            for _,a in ipairs(acts) do
                table.insert(d.delves,{p=a.progress,t=a.threshold})
                if a.progress>d.totalDone then d.totalDone=a.progress end
            end
        end
    end
    -- Scan gear voor huidig karakter
    d.guild   = GetGuildInfo("player") or d.guild or "Geen Guild"
    d.avgIlvl = select(2, GetAverageItemLevel()) or 0
    if UnitStat then
        d.stats = {
            stamina = UnitStat("player",3),
            str     = UnitStat("player",1),
            agi     = UnitStat("player",2),
            int     = UnitStat("player",4),
            armor   = select(2, UnitArmor and UnitArmor("player") or 0,0),
        }
    end
    local GEAR_SLOTS = {"HeadSlot","NeckSlot","ShoulderSlot","BackSlot","ChestSlot",
        "WristSlot","HandsSlot","WaistSlot","LegsSlot","FeetSlot",
        "Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot",
        "MainHandSlot","SecondaryHandSlot"}
    d.gear = d.gear or {}
    for _,s in ipairs(GEAR_SLOTS) do
        local link = GetInventoryItemLink("player", GetInventorySlotInfo(s))
        if link then
            local ilvl = C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
            d.gear[s] = {link=link, ilvl=ilvl or 0}
        else
            d.gear[s] = nil
        end
    end

    -- Scan beroepen (professions) voor huidig karakter
    d.professions = {}
    local prof1, prof2, arch, fish, cook = GetProfessions()
    -- v3.1.6: GEEN ipairs over {prof1,...} — ipairs stopt bij de eerste
    -- nil! Karakter zonder primary prof verloor zo cooking/fishing.
    for _,profIndex in pairs({p1=prof1, p2=prof2, a=arch, f=fish, c=cook}) do
        if profIndex then
            local name, icon, rank, maxRank, numSpells, spelloffset, skillLine, rankMod, specializationIndex = GetProfessionInfo(profIndex)
            if name then
                table.insert(d.professions, {
                    name    = name,
                    icon    = icon,
                    rank    = rank or 0,
                    maxRank = maxRank or 0,
                    skillLine = skillLine,
                })
            end
        end
    end
    -- Spec ID opslaan voor spec iconen
    local specIndex = GetSpecialization()
    if specIndex then
        local specID = GetSpecializationInfo(specIndex)
        d.specID = specID
    end
    -- KENNISBANK REGEL: UnitRace() geeft TWEE waarden — gebruik ALTIJD de
    -- tweede (CamelCase raceTag: "Scourge", "BloodElf", "NightElf", ...)
    local _, raceTag, raceID = UnitRace("player")
    d.race = raceTag or d.race
    d.raceID = raceID or d.raceID   -- v3.1.8: voor C_CreatureInfo routes
    -- UnitSex() geeft getal: 2=male, 3=female — opslaan als GETAL
    d.sex = UnitSex("player") or d.sex
    d.gender = d.sex   -- alias conform kennisbank veldnaam
    d.faction = UnitFactionGroup("player") or d.faction
end

UpdateCharacterList = function()
    -- Herlaad suggesties
    if DT_SuggestDrop then DT_SuggestDrop:Hide() end
    if not (DT_Scroll and DT_Scroll.content) then return end
    local filter=(DT_SearchBox and DT_SearchBox:GetText() or ""):lower()
    if filter=="🔍 zoek karakter..." then filter="" end
    local sorted={}
    for k in pairs(DelveTrackerDB.characters or {}) do
        if filter=="" or k:lower():find(filter,1,true) then
            table.insert(sorted,k)
        end
    end
    table.sort(sorted)

    -- Verberg alle oude rijen
    for _,row in pairs(DT_Scroll.content.rows) do row:Hide() end
    DT_Scroll.content.rows = {}

    local ROW_H = 60
    local COLS  = 2
    local COL   = math.floor((UI_W-50)/2)
    local GAP   = 4

    for i,key in ipairs(sorted) do
        local data = DelveTrackerDB.characters[key]
        local shortName = key:match("([^-]+)") or key
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class or ""] or {r=0.8,g=0.8,b=0.8}

        -- 2-koloms: col 0=links, col 1=rechts
        local col = (i-1) % COLS
        local row = math.floor((i-1) / COLS)
        local xPos = col * (COL + GAP)
        local yPos = -(row * (ROW_H + 3))

        local r = DT_Scroll.content.rows[i]
        if not r then
            r = CreateFrame("Button",nil,DT_Scroll.content,"BackdropTemplate")
            r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        end
        r:SetSize(COL, ROW_H)
        r:SetPoint("TOPLEFT", xPos, yPos)
        r:SetBackdropColor(0.08,0.04,0.12,0.8)
        r:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
        r:Show()

        -- Faction
        r.fLet = r.fLet or r:CreateFontString(nil,"OVERLAY")
        r.fLet:SetFont(C_2002,14,"OUTLINE")
        r.fLet:SetPoint("LEFT",8,0)
        r.fLet:SetText(data.faction=="Horde" and "|cffff4444H|r" or "|cff4488ffA|r")

        -- Klasse icon
        r.cIcon = r.cIcon or r:CreateTexture(nil,"OVERLAY")
        r.cIcon:SetSize(36,36)
        r.cIcon:SetPoint("LEFT",r.fLet,"RIGHT",8,0)
        local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[data.class or ""]
        if coords then
            r.cIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
            r.cIcon:SetTexCoord(unpack(coords))
        end

        -- Naam
        r.nm = r.nm or r:CreateFontString(nil,"OVERLAY")
        r.nm:SetFont(C_2002,12,"OUTLINE")
        r.nm:SetPoint("LEFT",r.cIcon,"RIGHT",10,8)
        r.nm:SetText(SA_GOLD..shortName.."|r")

        -- Spec
        r.sp = r.sp or r:CreateFontString(nil,"OVERLAY")
        r.sp:SetFont(C_2002,9,"")
        r.sp:SetPoint("LEFT",r.cIcon,"RIGHT",10,-4)
        r.sp:SetText(SA_GREY..(data.spec or "??").." · iLvl "..(data.ilvl or 0).."|r")

        -- Delve progress
        r.prgr = r.prgr or r:CreateFontString(nil,"OVERLAY")
        r.prgr:SetFont(C_2002,10,"OUTLINE")
        r.prgr:SetPoint("LEFT",r.cIcon,"RIGHT",10,-17)
        local st=""
        if data.delves then
            for _,v in ipairs(data.delves) do
                st=st..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r  "
            end
        end
        r.prgr:SetText(st~="" and st or SA_GREY.."—|r")

        -- Gold
        r.gld = r.gld or r:CreateFontString(nil,"OVERLAY")
        r.gld:SetFont(C_2002,11,"OUTLINE")
        r.gld:SetPoint("RIGHT",-10,0)
        r.gld:SetText(SA_GOLD..math.floor((data.money or 0)/10000).."g|r")

        -- iLvl badge
        r.ilv = r.ilv or r:CreateFontString(nil,"OVERLAY")
        r.ilv:SetFont(C_2002,10,"OUTLINE")
        r.ilv:SetPoint("RIGHT",r.gld,"LEFT",-12,0)
        r.ilv:SetText("|cff00ff00"..(data.ilvl or 0).."|r")

        -- Tooltip — zelfde voor beide kolommen
        local sn,d = shortName,data
        r:SetScript("OnEnter",function(self)
            self:SetBackdropColor(0.14,0.07,0.22,1)
            self:SetBackdropBorderColor(0.50,0.15,0.80,1)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(SA_GOLD..sn)
            GameTooltip:AddLine(SA_GREY..(d.class or "?").." · "..(d.spec or "??").."|r")
            if d.delves then
                local ds=""
                for _,v in ipairs(d.delves) do
                    ds=ds..(v.p>=v.t and "|cff44cc66" or "|cffff5555")..v.p.."/"..v.t.."|r  "
                end
                if ds~="" then GameTooltip:AddLine(ds) end
            end
            GameTooltip:AddLine(SA_GOLD..math.floor((d.money or 0)/10000).."g|r")
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave",function(self)
            self:SetBackdropColor(0.08,0.04,0.12,0.8)
            self:SetBackdropBorderColor(0.20,0.06,0.32,0.7)
            GameTooltip:Hide()
        end)
        r:SetScript("OnClick",function()
            if DT_Armory_ShowCharacter then
                d.name=sn; DT_Armory_ShowCharacter(d); PlaySound(852)
            end
        end)

        DT_Scroll.content.rows[i] = r
    end

    -- Hoogte: aantal rijen * (ROW_H+3)
    local nRows = math.ceil(#sorted / COLS)
    DT_Scroll.content:SetHeight(nRows*(ROW_H+3)+4)
end

-- ============================================================================
-- MURLOC MINIMAP BUTTON — volledig origineel menu (4 secties)
-- Klik links: toggle UI · Rechts: volledig context menu · R-drag: verplaats
-- ============================================================================
-- ── Murloc Button — exact origineel zoals het was ───────────────────────
local MBtn = CreateFrame("Button","DT_MurlocBtn",UIParent)
MBtn:SetSize(55,55)
MBtn:SetPoint("CENTER")
MBtn:SetMovable(true)
MBtn:EnableMouse(true)
MBtn:RegisterForDrag("RightButton")
MBtn:SetFrameStrata("HIGH")
MBtn:SetClampedToScreen(true)

MBtn.tex = MBtn:CreateTexture(nil,"ARTWORK")
MBtn.tex:SetAllPoints()
-- v3.5.4: minimap gebruikt 64x64 icon (MijnIcoon_minimap.tga) — scherpere weergave
MBtn.tex:SetTexture("Interface\\AddOns\\WowTracker\\Media\\MijnIcoon_minimap.tga")
MBtn.tex:SetBlendMode("ADD")   -- zwarte achtergrond transparant

-- Context menu via MenuUtil (UIDropDownMenu verwijderd in 12.x)
local function DT_OpenMurlocMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(SA_PURPLE.."WowTracker|r  "..SA_GREY.."v"..WT_VERSION.."|r")

        root:CreateTitle(SA_GOLD.."Characters|r")
        root:CreateButton("|cffffffff⚔  Delves|r",       function() UI:Show(); ShowTab(2) end)
        root:CreateButton("|cffffffff📖  Registry|r",     function()
            local r=_G["DT_RegistryFrame"]
            if r then if r:IsShown() then r:Hide() else r:Show() end end
        end)
        root:CreateButton("|cffffffff🏛  Armory|r",       function() UI:Show(); ShowTab(5) end)
        root:CreateButton("|cffffffff👥  Guild|r",        function() UI:Show(); ShowTab(1) end)

        root:CreateTitle(SA_BLUE.."Trackers|r")
        root:CreateButton("|cffffffff🎯  Prey Tracker|r", function()
            if SlashCmdList["DTPREY"] then SlashCmdList["DTPREY"]("") end
        end)
        root:CreateButton("|cffffffff📦  Bounty|r",       function() UI:Show(); ShowTab(3) end)
        root:CreateButton("|cffffffff📋  Roster|r",       function() UI:Show(); ShowTab(4) end)
        root:CreateButton("|cffffffff💰  Currency|r",     function() UI:Show(); ShowTab(6) end)
        root:CreateButton("|cffffffff🧵  Cloth Counter|r",function()
            if SlashCmdList["CBUDGET"] then SlashCmdList["CBUDGET"]("")
            elseif SlashCmdList["CBUD"] then SlashCmdList["CBUD"]("") end
        end)
        root:CreateButton("|cffffffff🐾  Skin & Rare|r",  function()
            if SlashCmdList["SNR"] then SlashCmdList["SNR"]("") end
        end)
        root:CreateButton("|cffffffff🔒  Lockout|r",      function()
            if SlashCmdList["DTLOCKOUT"] then SlashCmdList["DTLOCKOUT"]() end
        end)

        root:CreateTitle(SA_PURPLE.."Settings|r")
        root:CreateButton("|cffffffff⚙  Admin Panel|r",  function()
            local opt=_G["DelveTrackerOptions"]
            if opt then if opt:IsShown() then opt:Hide() else opt:Show() end end
        end)
        root:CreateButton("|cffffffff🔧  Debug|r",        function()
            local f=_G["DT_DebugFrame"]
            if f then if f:IsShown() then f:Hide() else f:Show() end
            elseif SlashCmdList["DTDEBUG"] then SlashCmdList["DTDEBUG"]("") end
        end)
        root:CreateButton("|cffffffff💬  ExchangeBot|r",  function()
            if SlashCmdList["CBOT"] then SlashCmdList["CBOT"]("") end
        end)
        root:CreateButton("|cffffffff📬  Mail Attach|r",  function()
            if SlashCmdList["DTMAIL"] then SlashCmdList["DTMAIL"]("") end
        end)

        root:CreateTitle(SA_GREY.."Systeem|r")
        root:CreateButton("Herpositioneer venster",        function() UI:ClearAllPoints(); UI:SetPoint("CENTER") end)
        root:CreateButton("Reset Murloc positie",          function() MBtn:ClearAllPoints(); MBtn:SetPoint("CENTER") end)
        root:CreateButton("Reload UI", function()
            if not InCombatLockdown() then ReloadUI()
            else print("|cffbf00ff[WowTracker]|r Kan niet reloaden in combat.") end
        end)
        root:CreateButton("Sluit venster",                 function() UI:Hide() end)
    end)
end

MBtn:SetScript("OnClick", function(self,btn)
    if btn=="LeftButton" then
        PlaySound(6449)
        if UI:IsShown() then UI:Hide()
        else ShowTab(activeTabID or 2) end
    else
        DT_OpenMurlocMenu(self)
    end
end)

MBtn:SetScript("OnDragStart", MBtn.StartMoving)
MBtn:SetScript("OnDragStop",  function(self)
    self:StopMovingOrSizing()
    -- v3.1.7: save in CENTER-relatieve UIParent coördinaten — restore
    -- gebruikt CENTER/UIParent, dus save MOET hetzelfde referentiekader
    -- hebben (GetPoint gaf anchor-afhankelijke x,y → versprong na reload)
    if DelveTrackerDB then
        local s  = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local cx, cy = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if cx and px then
            DelveTrackerDB.murlocPos = {x = cx*s - px, y = cy*s - py}
        end
    end
end)

MBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP")
    GameTooltip:SetText(SA_PURPLE.."WowTracker|r")
    GameTooltip:AddLine(SA_GREY..WT_T("MURL_TOOLTIP").."|r")
    GameTooltip:Show()
end)
MBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================
SLASH_WTMAIN1="/wt"; SLASH_WTMAIN2="/wowtracker"; SLASH_WTMAIN3="/dt"; SLASH_WTMAIN4="/delves"
SLASH_WTAB11="/wt1"; SLASH_WTAB12="/wt guild";    SLASH_WTAB13="/dt1"; SLASH_WTAB14="/tb1"
SLASH_WTAB21="/wt2"; SLASH_WTAB22="/wt delves";   SLASH_WTAB23="/dt2"; SLASH_WTAB24="/tb2"
SLASH_WTAB31="/wt3"; SLASH_WTAB32="/wt bounty";   SLASH_WTAB33="/dt3"; SLASH_WTAB34="/tb3"
SLASH_WTAB41="/wt4"; SLASH_WTAB42="/wt roster";   SLASH_WTAB43="/wtroster"
SLASH_WTAB51="/wt5"; SLASH_WTAB52="/wt armory";   SLASH_WTAB53="/wtarmory"
SLASH_WTAB61="/wt6"; SLASH_WTAB62="/wt currency"; SLASH_WTAB63="/wtcurrency"
SLASH_WTRELOAD1="/wt-reload"
SLASH_WTCLEAN1 = "/wt-cleanup"; SLASH_WTCLEAN2 = "/wt cleanup"
SlashCmdList["WTCLEAN"] = function()
    if not DelveTrackerDB or not DelveTrackerDB.characters then
        print("|cffbf00ffWowTracker|r: Geen database."); return
    end
    local removed = 0
    -- 1) Orphaned entries (geen class/level/race/gold)
    for key, data in pairs(DelveTrackerDB.characters) do
        if not data.class and not data.level and not data.race
           and (not data.money or data.money == 0) then
            DelveTrackerDB.characters[key] = nil
            removed = removed + 1
            print("|cffbf00ffWowTracker|r: Orphan verwijderd: |cffccaa00"..key.."|r")
        end
    end
    -- 2) Dubbele realm-naam keys (spatie vs geen spatie, bijv. "Defias Brotherhood" vs "DefiasBrotherhood")
    local seen = {}
    for key, data in pairs(DelveTrackerDB.characters) do
        local name, realm = key:match("^(.+)-(.+)$")
        if name and realm then
            local normKey = name.."-"..realm:gsub("%s+","")
            if seen[normKey] then
                -- Houd de entry met MEER data (level > 0)
                local oldData = DelveTrackerDB.characters[seen[normKey]]
                local keepOld = (oldData.level or 0) >= (data.level or 0)
                if not keepOld then
                    DelveTrackerDB.characters[seen[normKey]] = nil
                    seen[normKey] = key
                else
                    DelveTrackerDB.characters[key] = nil
                end
                removed = removed + 1
                print("|cffbf00ffWowTracker|r: Duplicaat verwijderd: |cffccaa00"..key.."|r")
            else
                seen[normKey] = key
            end
        end
    end
    if removed == 0 then
        print("|cffbf00ffWowTracker|r: Geen orphaned of dubbele entries gevonden.")
    else
        print("|cffbf00ffWowTracker|r: "..removed.." entr(y/ies) verwijderd — /reload om roster te verversen.")
    end
end

SLASH_WTMEM1="/wt-mem"; SLASH_WTCOMBAT1="/wt-combat"

SlashCmdList["WTMAIN"]=function(msg)
    msg=(msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    if     msg=="1" or msg=="guild"    then ShowTab(1)
    elseif msg=="2" or msg=="delves"   then ShowTab(2)
    elseif msg=="3" or msg=="bounty"   then ShowTab(3)
    elseif msg=="4" or msg=="roster"   then ShowTab(4)
    elseif msg=="5" or msg=="armory"   then ShowTab(5)
    elseif msg=="6" or msg=="currency" then ShowTab(6)
    elseif UI:IsShown() then UI:Hide()
    else ShowTab(activeTabID or 1) end
end
SlashCmdList["WTAB1"]=function() UI:Show(); ShowTab(1) end
SlashCmdList["WTAB2"]=function() UI:Show(); ShowTab(2) end
SlashCmdList["WTAB3"]=function() UI:Show(); ShowTab(3) end
SlashCmdList["WTAB4"]=function() UI:Show(); ShowTab(4) end
SlashCmdList["WTAB5"]=function() UI:Show(); ShowTab(5) end
SlashCmdList["WTAB6"]=function() UI:Show(); ShowTab(6) end
SlashCmdList["WTRELOAD"]=function()
    if not InCombatLockdown() then ReloadUI()
    else print("|cffbf00ff[WowTracker]|r Kan niet reloaden in combat.") end
end
SlashCmdList["WTMEM"]=function()
    if C_AddOns and C_AddOns.UpdateAddOnMemoryUsage then C_AddOns.UpdateAddOnMemoryUsage() end
    local m=(C_AddOns and C_AddOns.GetAddOnMemoryUsage and C_AddOns.GetAddOnMemoryUsage("WowTracker")) or 0
    print(string.format(SA_PURPLE.."[WowTracker]|r Geheugen: %.1f KB",m))
end
SlashCmdList["WTCOMBAT"]=function()
    DelveTrackerDB.enableCombatAlert=not DelveTrackerDB.enableCombatAlert
    print(SA_PURPLE.."[WowTracker]|r Combat alert: "
        ..(DelveTrackerDB.enableCombatAlert and "|cff44cc66AAN|r" or "|cffcc4444UIT|r"))
end

-- ============================================================================
-- DB BACKUP SYSTEEM (v4.0.0)
-- WoW Lua sandbox staat geen schijf-I/O toe, maar wel extra SavedVariables.
-- WowTrackerDB_Backup wordt gedeclareerd in de TOC en opgeslagen in de WTF-map.
-- De gebruiker kan het WTF/Account/.../SavedVariables.lua bestand als backup
-- kopiëren of hernoemen buiten het spel.
-- ============================================================================
local function WT_DeepCopy(orig, seen)
    seen = seen or {}
    if type(orig) ~= "table" then return orig end
    if seen[orig] then return seen[orig] end
    local copy = {}
    seen[orig] = copy
    for k, v in pairs(orig) do
        copy[WT_DeepCopy(k, seen)] = WT_DeepCopy(v, seen)
    end
    return setmetatable(copy, getmetatable(orig))
end

local function WT_DBBackup()
    -- v3.5.1: lees van WowTrackerDB als die al actief is (v4.0+), anders DelveTrackerDB
    local source = WowTrackerDB or DelveTrackerDB
    if not source then
        print(SA_PURPLE.."[WowTracker]|r Geen database gevonden."); return
    end
    WowTrackerDB_Backup = WT_DeepCopy(source)
    WowTrackerDB_Backup._backup_time    = date("%Y-%m-%d %H:%M:%S")
    WowTrackerDB_Backup._backup_chars   = 0
    for _ in pairs(source.characters or {}) do
        WowTrackerDB_Backup._backup_chars = WowTrackerDB_Backup._backup_chars + 1
    end
    WowTrackerDB_Backup._backup_version = WT_VERSION
    local dbName = WowTrackerDB and "WowTrackerDB" or "DelveTrackerDB"
    print(SA_PURPLE.."[WowTracker]|r "..SA_GOLD.."Backup succesvol!|r "
        ..SA_GREY..WowTrackerDB_Backup._backup_chars.." chars · "
        ..WowTrackerDB_Backup._backup_time.."|r")
    print(SA_GREY.."Bron: "..dbName.." → WowTrackerDB_Backup (WTF-map)|r")
end

-- Aparte state variabele voor restore bevestiging (local function kan geen fields hebben in Lua)
local WT_DBRestore_confirmed = false
local function WT_DBRestore()
    if not WowTrackerDB_Backup then
        print(SA_PURPLE.."[WowTracker]|r ".."|cffff4444Geen backup gevonden.|r"); return
    end
    local t = WowTrackerDB_Backup._backup_time or "?"
    local c = WowTrackerDB_Backup._backup_chars or "?"
    local v = WowTrackerDB_Backup._backup_version or "?"
    -- Stateful bevestiging via aparte variabele
    if not WT_DBRestore_confirmed then
        WT_DBRestore_confirmed = true
        print(SA_PURPLE.."[WowTracker]|r "..SA_GOLD.."Bevestig restore:|r "
            ..SA_GREY.."Backup van "..t.." · "..c.." chars · v"..v.."|r")
        print("|cffff4444Huidige data wordt OVERSCHREVEN. "
            .."Typ /wt-dbrestore opnieuw om te bevestigen.|r")
        C_Timer.After(30, function() WT_DBRestore_confirmed = false end)
        return
    end
    WT_DBRestore_confirmed = false
    local restored = WT_DeepCopy(WowTrackerDB_Backup)
    -- Metadata-velden opruimen uit de restore-kopie
    restored._backup_time    = nil
    restored._backup_chars   = nil
    restored._backup_version = nil
    -- v3.5.1: schrijf naar BEIDE DB-namen (huidige + toekomstige v4.0)
    -- → na v4.0 rename is WowTrackerDB al gevuld; geen extra migratiestap nodig
    DelveTrackerDB = restored
    WowTrackerDB   = WT_DeepCopy(restored)   -- v4.0 klaar-zetten
    print(SA_PURPLE.."[WowTracker]|r "..SA_GOLD.."Restore geslaagd!|r "
        ..SA_GREY..c.." chars terug uit backup van "..t.."|r")
    print(SA_GREY.."Geschreven naar: DelveTrackerDB + WowTrackerDB (v4.0 ready)|r")
    C_Timer.After(1.5, function() if not InCombatLockdown() then ReloadUI() end end)
end

SLASH_WTBACKUP1  = "/wt-dbbackup"
SLASH_WTRESTORE1 = "/wt-dbrestore"
SlashCmdList["WTBACKUP"]  = WT_DBBackup
SlashCmdList["WTRESTORE"] = WT_DBRestore

-- ============================================================================
-- ADMIN PANEL — herbouw v3.0.7 functionaliteit (sessie 2026-06-12)
-- KENNISBANK REGELS:
--   · Parented aan UIParent (schaalt NIET mee met HUD)
--   · Handmatige sliders met SetThumbTexture (OptionsSliderTemplate = verboden)
--   · Staat NA alle WT_* definities, VÓÓR events (load-volgorde regel)
-- Open via: ⚙ knop in header of /wtadmin
-- ============================================================================
local AP = CreateFrame("Frame", "DT_AdminPanel", UIParent, "BackdropTemplate")
AP:SetSize(440, 570)
AP:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
AP:SetFrameStrata("DIALOG")
AP:SetMovable(true); AP:EnableMouse(true)
AP:RegisterForDrag("LeftButton")
AP:SetScript("OnDragStart", AP.StartMoving)
AP:SetScript("OnDragStop",  AP.StopMovingOrSizing)
AP:SetClampedToScreen(true)
AP:Hide()
AP:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
AP:SetBackdropColor(0.04, 0.02, 0.08, 0.98)
AP:SetBackdropBorderColor(0.40, 0.10, 0.65, 1)

local apTitle = AP:CreateFontString(nil, "OVERLAY")
apTitle:SetFont(C_2002, 15, "OUTLINE")
apTitle:SetPoint("TOP", 0, -10)
apTitle:SetText(SA_PURPLE.."WowTracker Admin|r  "..SA_GREY.."v"..WT_VERSION.."|r")

local apClose = CreateFrame("Button", nil, AP, "UIPanelCloseButton")
apClose:SetPoint("TOPRIGHT", -2, -2)

-- ── Handmatige slider helper (geen OptionsSliderTemplate!) ──────────────
local function MakeSlider(parent, y, label, minV, maxV, getV, setV)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(C_2002, 11, "OUTLINE")
    lbl:SetPoint("TOPLEFT", 16, y)
    lbl:SetText(SA_BLUE..label.."|r")

    local valTxt = parent:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(C_2002, 11, "OUTLINE")
    valTxt:SetPoint("TOPRIGHT", -16, y)
    valTxt:SetText(string.format("%.2f", getV()))

    local track = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    track:SetSize(408, 10)
    track:SetPoint("TOPLEFT", 16, y - 16)
    track:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    track:SetBackdropColor(0.10, 0.05, 0.16, 1)
    track:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
    track:EnableMouse(true)

    local thumb = track:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 18)
    thumb:SetColorTexture(0.75, 0.20, 1.0, 1)

    local function Position()
        local v = getV()
        local pct = (v - minV) / (maxV - minV)
        pct = math.max(0, math.min(1, pct))
        thumb:SetPoint("CENTER", track, "LEFT", 7 + pct * (408 - 14), 0)
        valTxt:SetText(string.format("%.2f", v))
    end
    Position()

    local dragging = false
    local function FromCursor()
        local cx = GetCursorPosition() / track:GetEffectiveScale()
        local left = track:GetLeft() or 0
        local pct = math.max(0, math.min(1, (cx - left - 7) / (408 - 14)))
        local v = minV + pct * (maxV - minV)
        v = math.floor(v * 20 + 0.5) / 20   -- stappen van 0.05
        setV(v); Position()
    end
    track:SetScript("OnMouseDown", function() dragging = true; FromCursor() end)
    track:SetScript("OnMouseUp",   function() dragging = false end)
    track:SetScript("OnUpdate",    function() if dragging then FromCursor() end end)

    return Position   -- refresh functie
end

-- ── Sectie: sliders ─────────────────────────────────────────────────────
local refreshUIScale = MakeSlider(AP, -42, WT_T("UI_SCALE"), 0.5, 2.0,
    function() return DelveTrackerDB.mainScale or 1.0 end,
    function(v) DelveTrackerDB.mainScale = v; UI:SetScale(v) end)

local refreshMScale = MakeSlider(AP, -86, WT_T("MURLOC_SCALE"), 0.5, 2.0,
    function() return DelveTrackerDB.mScale or 1.0 end,
    function(v) DelveTrackerDB.mScale = v; if MBtn then MBtn:SetScale(v) end end)

-- ── Sectie: thema ───────────────────────────────────────────────────────
local thLbl = AP:CreateFontString(nil, "OVERLAY")
thLbl:SetFont(C_2002, 11, "OUTLINE")
thLbl:SetPoint("TOPLEFT", 16, -132)
thLbl:SetText(SA_BLUE..WT_T("THEME_SET").."|r")

local apThemeBtns = {}
local function RefreshThemeBtns()
    local active = (WTTheme and WTTheme.GetActive and WTTheme.GetActive()) or ""
    for name, b in pairs(apThemeBtns) do
        if name == active then
            b:SetBackdropBorderColor(0.85, 0.70, 0.10, 1)
        else
            b:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
        end
    end
end
do
    local names = (WTTheme and WTTheme.GetThemeNames and WTTheme.GetThemeNames()) or {}
    local bx, by = 16, -148
    for i, name in ipairs(names) do
        local n = name
        local b = CreateFrame("Button", nil, AP, "BackdropTemplate")
        b:SetSize(98, 22)
        b:SetPoint("TOPLEFT", bx, by)
        b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
        b:SetBackdropColor(0.08, 0.04, 0.14, 0.95)
        b:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
        local t = b:CreateFontString(nil, "OVERLAY")
        t:SetFont(C_2002, 9, "OUTLINE"); t:SetPoint("CENTER")
        t:SetText("|cffffffff"..n.."|r")
        b:SetScript("OnClick", function()
            if WTTheme and WTTheme.SetActiveTheme then
                WTTheme.SetActiveTheme(n)
                RefreshThemeBtns()
                print(SA_PURPLE.."[WowTracker] Thema: "..n.."|r")
            end
        end)
        apThemeBtns[n] = b
        bx = bx + 102
        if i % 4 == 0 then bx = 16; by = by - 26 end
    end
end

-- ── Sectie: taal ────────────────────────────────────────────────────────
local taLbl = AP:CreateFontString(nil, "OVERLAY")
taLbl:SetFont(C_2002, 11, "OUTLINE")
taLbl:SetPoint("TOPLEFT", 16, -208)
taLbl:SetText(SA_BLUE..WT_T("LANG_TITLE").."|r")

local apLangBtns = {}
local function RefreshLangBtns()
    local active = (DelveTrackerDB and DelveTrackerDB.language) or "Nederlands"
    for name, b in pairs(apLangBtns) do
        if name == active then
            b:SetBackdropBorderColor(0.85, 0.70, 0.10, 1)
        else
            b:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
        end
    end
end
do
    local langs = {"Nederlands","English","Deutsch","Français","Español"}
    local bx = 16
    for _, lang in ipairs(langs) do
        local l = lang
        local b = CreateFrame("Button", nil, AP, "BackdropTemplate")
        b:SetSize(78, 22)
        b:SetPoint("TOPLEFT", bx, -224)
        b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
        b:SetBackdropColor(0.08, 0.04, 0.14, 0.95)
        b:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
        local t = b:CreateFontString(nil, "OVERLAY")
        t:SetFont(C_2002, 9, "OUTLINE"); t:SetPoint("CENTER")
        t:SetText("|cffffffff"..l.."|r")
        b:SetScript("OnClick", function()
            DelveTrackerDB.language = l
            if WT_ApplyLanguage then WT_ApplyLanguage(l) end
            RefreshLangBtns()
            print(SA_PURPLE.."[WowTracker] Taal: "..l.."|r")
        end)
        apLangBtns[l] = b
        bx = bx + 82
    end
end

-- ── Sectie: combat alert toggle ─────────────────────────────────────────
local caBtn = CreateFrame("Button", nil, AP, "BackdropTemplate")
caBtn:SetSize(200, 22)
caBtn:SetPoint("TOPLEFT", 16, -262)
caBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
caBtn:SetBackdropColor(0.08, 0.04, 0.14, 0.95)
caBtn:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
local caTxt = caBtn:CreateFontString(nil, "OVERLAY")
caTxt:SetFont(C_2002, 10, "OUTLINE"); caTxt:SetPoint("CENTER")
local function RefreshCA()
    caTxt:SetText(WT_T("COMBAT_ALERT")..": "..(DelveTrackerDB.enableCombatAlert and "|cff44cc66"..WT_T("ON").."|r" or "|cffcc4444"..WT_T("OFF").."|r"))
end
caBtn:SetScript("OnClick", function()
    DelveTrackerDB.enableCombatAlert = not DelveTrackerDB.enableCombatAlert
    RefreshCA()
end)

-- ── Cleanup DB knop (naast combat alert) ─────────────────────────────────
local cleanBtn = CreateFrame("Button", nil, AP, "BackdropTemplate")
cleanBtn:SetSize(180, 22)
cleanBtn:SetPoint("LEFT", caBtn, "RIGHT", 8, 0)
cleanBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
cleanBtn:SetBackdropColor(0.08, 0.04, 0.14, 0.95)
cleanBtn:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
local cleanTxt = cleanBtn:CreateFontString(nil, "OVERLAY")
cleanTxt:SetFont(C_2002, 10, "OUTLINE"); cleanTxt:SetPoint("CENTER")
cleanTxt:SetText("|cffccaa00Cleanup DB|r")
cleanBtn:SetScript("OnClick", function()
    if SlashCmdList["WTCLEAN"] then SlashCmdList["WTCLEAN"]() end
end)
cleanBtn:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
cleanBtn:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(0.30,0.08,0.50,0.8) end)

-- ── Sectie: plugins on/off ──────────────────────────────────────────────
-- ── Backup / Restore knoppen ────────────────────────────────────────────
local function MakeAPBtn(lbl, col, x, y, w, fn)
    local b = CreateFrame("Button", nil, AP, "BackdropTemplate")
    b:SetSize(w, 22)
    b:SetPoint("TOPLEFT", x, y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
                   edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.08, 0.04, 0.14, 0.95)
    b:SetBackdropBorderColor(0.30, 0.08, 0.50, 0.8)
    local t = b:CreateFontString(nil, "OVERLAY")
    t:SetFont(C_2002, 10, "OUTLINE")
    t:SetPoint("CENTER")
    t:SetText(col..lbl.."|r")
    b:SetScript("OnClick", fn)
    b:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(0.70,0.25,1.0,1) end)
    b:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(0.30,0.08,0.50,0.8) end)
    return b
end

local backupBtn = MakeAPBtn("💾  DB Backup", SA_BLUE, 16, -293, 196, function()
    WT_DBBackup()
end)
backupBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0.10, 0.70, 0.95, 1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(SA_GOLD..WT_T("DB_BACKUP_TITLE"))
    GameTooltip:AddLine(SA_GREY..WT_T("DB_BACKUP_INFO").."|r")
    GameTooltip:AddLine(SA_GREY..WT_T("DB_BACKUP_PATH").."|r")
    if WowTrackerDB_Backup then
        GameTooltip:AddLine(SA_GOLD..WT_T("DB_BACKUP_LAST")
            ..SA_GREY..(WowTrackerDB_Backup._backup_time or "?").."|r")
    else
        GameTooltip:AddLine("|cffff5555"..WT_T("DB_BACKUP_NONE").."|r")
    end
    GameTooltip:Show()
end)
backupBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0.30,0.08,0.50,0.8)
    GameTooltip:Hide()
end)

local restoreBtn = MakeAPBtn("↩  Restore", "|cffff8844", 220, -293, 190, function()
    WT_DBRestore()
end)
restoreBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0.95, 0.50, 0.10, 1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("|cffff8844"..WT_T("DB_RESTORE_TITLE"))
    GameTooltip:AddLine(SA_GREY..WT_T("DB_RESTORE_INFO").."|r")
    GameTooltip:AddLine("|cffff4444"..WT_T("DB_RESTORE_WARN").."|r")
    if WowTrackerDB_Backup then
        GameTooltip:AddLine(SA_GOLD..WT_T("DB_RESTORE_FROM")
            ..SA_GREY..(WowTrackerDB_Backup._backup_time or "?")
            .." · "..(WowTrackerDB_Backup._backup_chars or "?").." chars|r")
    else
        GameTooltip:AddLine("|cffff5555"..WT_T("DB_NO_BACKUP").."|r")
    end
    GameTooltip:Show()
end)
restoreBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0.30,0.08,0.50,0.8)
    GameTooltip:Hide()
end)

local plLbl = AP:CreateFontString(nil, "OVERLAY")
plLbl:SetFont(C_2002, 11, "OUTLINE")
plLbl:SetPoint("TOPLEFT", 16, -328)
plLbl:SetText(SA_BLUE..WT_T("PLUGINS").."|r  "..SA_GREY..WT_T("PLUGINS_HINT").."|r")

local plugScroll = CreateFrame("ScrollFrame", nil, AP)
plugScroll:SetPoint("TOPLEFT", 16, -344)
plugScroll:SetPoint("BOTTOMRIGHT", -22, 14)
local plugContent = CreateFrame("Frame", nil, plugScroll)
plugContent:SetSize(380, 10)
plugScroll:SetScrollChild(plugContent)
WT_MakeSAScrollbar(plugScroll, AP)

local plugRows = {}
local function RefreshPluginList()
    for _, r in ipairs(plugRows) do r:Hide() end
    local names = {}
    for n in pairs(DelveTracker.Plugins or {}) do table.insert(names, n) end
    table.sort(names)
    for i, n in ipairs(names) do
        local row = plugRows[i]
        if not row then
            row = CreateFrame("Button", nil, plugContent, "BackdropTemplate")
            row:SetSize(380, 20)
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
            row.txt = row:CreateFontString(nil, "OVERLAY")
            row.txt:SetFont(C_2002, 10, "OUTLINE")
            row.txt:SetPoint("LEFT", 6, 0)
            row.st = row:CreateFontString(nil, "OVERLAY")
            row.st:SetFont(C_2002, 10, "OUTLINE")
            row.st:SetPoint("RIGHT", -6, 0)
            plugRows[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -(i-1)*22)
        local enabled = DelveTrackerDB.PluginStates[n] ~= false
        row:SetBackdropColor(0.07, 0.03, 0.12, 0.9)
        row:SetBackdropBorderColor(enabled and 0.30 or 0.15, 0.08, enabled and 0.50 or 0.20, 0.8)
        row.txt:SetText((enabled and "|cffffffff" or SA_GREY)..n.."|r")
        row.st:SetText(enabled and "|cff44cc66"..WT_T("ON").."|r" or "|cffcc4444"..WT_T("OFF").."|r")
        row:SetScript("OnClick", function()
            DelveTrackerDB.PluginStates[n] = not (DelveTrackerDB.PluginStates[n] ~= false)
            RefreshPluginList()
        end)
        row:Show()
    end
    plugContent:SetHeight(#names * 22 + 4)
end

-- ── Open/close koppeling ────────────────────────────────────────────────
local function ToggleAdminPanel()
    if AP:IsShown() then AP:Hide() return end
    -- v3.2.0: labels in actuele taal bij elk openen
    thLbl:SetText(SA_BLUE..WT_T("THEME_SET").."|r")
    taLbl:SetText(SA_BLUE..WT_T("LANG_TITLE").."|r")
    plLbl:SetText(SA_BLUE..WT_T("PLUGINS").."|r  "..SA_GREY..WT_T("PLUGINS_HINT").."|r")
    apTitle:SetText(SA_PURPLE..WT_T("ADMIN_TITLE").."|r  "..SA_GREY.."v"..WT_VERSION.."|r")
    refreshUIScale(); refreshMScale()
    RefreshThemeBtns(); RefreshLangBtns(); RefreshCA(); RefreshPluginList()
    AP:Show()
end
UI.settingsBtn:SetScript("OnClick", ToggleAdminPanel)

SLASH_WTADMIN1 = "/wtadmin"
SlashCmdList["WTADMIN"] = ToggleAdminPanel

-- ============================================================================
-- EVENTS
-- ============================================================================
UI:RegisterEvent("PLAYER_LOGIN")
UI:RegisterEvent("PLAYER_ENTERING_WORLD")
UI:RegisterEvent("WEEKLY_REWARDS_UPDATE")
UI:RegisterEvent("PLAYER_MONEY")
UI:RegisterEvent("GUILD_ROSTER_UPDATE")

UI:SetScript("OnEvent",function(self,event)
    DelveTrackerDB.characters    = DelveTrackerDB.characters    or {}
    DelveTrackerDB.PluginStates  = DelveTrackerDB.PluginStates  or {}
    if event=="PLAYER_LOGIN" then
        -- Herstel schaal
        if DelveTrackerDB.mainScale then
            UI:SetScale(DelveTrackerDB.mainScale)
            scaleValTxt:SetText(string.format("%.2f",DelveTrackerDB.mainScale))
        end
        -- Herstel murloc schaal
        if DelveTrackerDB.mScale then MBtn:SetScale(DelveTrackerDB.mScale) end
        -- Herstel murloc positie
        -- Murloc positie herstel
        if DelveTrackerDB.murlocPos then
            local p=DelveTrackerDB.murlocPos
            MBtn:ClearAllPoints()
            MBtn:SetPoint("CENTER",UIParent,"CENTER",p.x or 0,p.y or 0)
        end
        if DelveTrackerDB.mScale then MBtn:SetScale(DelveTrackerDB.mScale) end
        -- Herstel UI positie
        if DelveTrackerDB.mainPos then
            local p=DelveTrackerDB.mainPos
            UI:ClearAllPoints()
            UI:SetPoint(p.pt or "CENTER",UIParent,p.rpt or "CENTER",p.x or 0,p.y or 0)
        end
        -- Herstel thema via WTTheme (primair systeem)
        -- v3.1.7: SetActiveTheme her-aanroepen triggert óók alle
        -- Register-callbacks (tab buttons, plugins) — consistent herstel
        if WTTheme and WTTheme.SetActiveTheme and WTTheme.GetActive then
            WTTheme.SetActiveTheme(WTTheme.GetActive())
        end
        if WTTheme and WTTheme.bg then
            local bg  = WTTheme.bg.main
            local bdr = WTTheme.border.main
            if bg  then UI:SetBackdropColor(bg.r,  bg.g,  bg.b,  bg.a  or 0.97) end
            if bdr then UI:SetBackdropBorderColor(bdr.r, bdr.g, bdr.b, bdr.a or 1) end
        elseif DelveTrackerDB.theme then
            -- Fallback: oud inline systeem (voor spelers die upgraden)
            local t=DelveTrackerDB.theme
            if t.bg then UI:SetBackdropColor(t.bg[1],t.bg[2],t.bg[3],t.bg[4] or 0.97) end
            if t.border then UI:SetBackdropBorderColor(t.border[1],t.border[2],t.border[3],1) end
        end
        -- Nil-safe veld-init (kennisbank: nieuwe velden op PLAYER_LOGIN —
        -- file-load defaults overleven het laden van SavedVariables NIET)
        DelveTrackerDB.characters   = DelveTrackerDB.characters or {}
        DelveTrackerDB.PluginStates = DelveTrackerDB.PluginStates or {}
        DelveTrackerDB.tickerShow = DelveTrackerDB.tickerShow or {
            events=true, guild=true, prey=true, time=true,
        }
        -- Herstel taalinstelling
        if DelveTrackerDB.language then
            WT_ApplyLanguage(DelveTrackerDB.language)
        end
        -- ── DB AUTO-MIGRATIE (herbouw v3.0.7 + v3.1.9 gids-upgrade) ──
        -- Oude entries: gender als string → getal; race met spaties → zonder;
        -- localized rasnaam → clientFileString via C_CreatureInfo reverse-lookup
        -- ("Undead"→"Scourge") — repareert ALLE chars zonder her-inloggen
        WT_BuildRaceData()
        for _,cdata in pairs(DelveTrackerDB.characters or {}) do
            if type(cdata)=="table" then
                if type(cdata.gender)=="string" then
                    cdata.gender = (cdata.gender=="female" or cdata.gender=="3") and 3 or 2
                end
                if type(cdata.sex)=="string" then
                    cdata.sex = (cdata.sex=="female" or cdata.sex=="3") and 3 or 2
                end
                if type(cdata.race)=="string" and cdata.race:find("%s") then
                    cdata.race = cdata.race:gsub("%s+","")
                end
                -- v3.1.9: localized naam → echte clientFile (gids reverse-lookup)
                if type(cdata.race)=="string" and WT_RaceData then
                    local cf = WT_RaceData.byLocalized[cdata.race]
                    if cf and cf ~= cdata.race then cdata.race = cf end
                end
                -- raceID aanvullen als we hem via clientFile kunnen vinden
                if not cdata.raceID and cdata.race and WT_RaceData then
                    for id, cf in pairs(WT_RaceData.byID) do
                        if cf == cdata.race then cdata.raceID = id; break end
                    end
                end
            end
        end
        tickerLastT=GetTime(); tickerDirty=true
        TickerClock:SetText(string.format(SA_GOLD.."%s|r",date("%H:%M:%S")))
        -- Pre-fetch guild data
        if IsInGuild() then WT_RequestGuildRoster() end
    end
    if event=="GUILD_ROSTER_UPDATE" then
        if Tab1:IsShown() then
            local gName=GetGuildInfo("player")
            if gName and Tab1.guildName then Tab1.guildName:SetText(SA_GOLD..gName.."|r") end
            WT_UpdateGuildOnline()
            if WT_UpdateGuildEventsList then WT_UpdateGuildEventsList() end
        end
    end
    if event=="PLAYER_ENTERING_WORLD" or event=="WEEKLY_REWARDS_UPDATE"
    or event=="PLAYER_MONEY" or event=="PLAYER_LOGIN" then
        InitRosterPools(Tab4.scroll.content)
        InitCurrPools(Tab6.scroll.content)
        ScanDelves()
        if WT_UpdateWarbandStats then WT_UpdateWarbandStats() end
        if WT_UpdateCharInfo then WT_UpdateCharInfo() end
        if Tab2:IsShown() then UpdateCharacterList() end
        tickerDirty=true
        if event=="PLAYER_LOGIN" and IsInGuild() then WT_RequestGuildRoster() end
    end
end)
