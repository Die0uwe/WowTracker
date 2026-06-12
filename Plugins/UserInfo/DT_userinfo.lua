-- ================================================================
--  DT_userinfo.lua  v8.1.0  —  Character Dashboard · Midnight Edition
--  Compatible with: Retail 12.0.5.67314 (Midnight)
--  Loaded via DelveTracker.xml after DelveTracker.lua
--  Storage: DelveTrackerDB.UserInfo + DelveTrackerDB.characters
--
--  v8.1.0 — Layout & Scroll Audit vs v8.0.0
--  ──────────────────────────────────────────
--  [SCROLL-1] SCROLLBAR_W = 20 constant added to layout block.
--             All ScrollFrame panels now subtract this from content
--             width so text never runs behind the scrollbar thumb.
--
--  [SCROLL-2] Currency panel (pCurrency) → UIPanelScrollFrameTemplate.
--             Root cause: CUR_DISPLAY contains 13 currencies × 28 px
--             + 3 dividers × 10 px = ~394 px content inside a 300 px
--             panel; Conquest and Honor rows were fully invisible.
--             Fix: wrap rows in DT_CurScroll ScrollFrame; mouse-wheel
--             scrolls 28 px/tick (= one row). Content height computed
--             dynamically before rows are built.
--
--  [SCROLL-3] Warband character grid (wbScroll) →
--             UIPanelScrollFrameTemplate ("DT_WbCharScroll").
--             Previously used a bare CreateFrame("ScrollFrame") with
--             no template — the scrollbar was invisible and could not
--             be dragged. charW reduced from 237 → 232 px to leave
--             SCROLLBAR_W room; wbContent width reduced accordingly.
--
--  [SCROLL-4] Warband reputation panel (wbRepScroll) →
--             UIPanelScrollFrameTemplate ("DT_WbRepScroll").
--             Same invisible-scrollbar issue as wbScroll. Mouse-wheel
--             added (17 px/tick = one rep line). repW and wbRepContent
--             width both reduced by SCROLLBAR_W.
--
--  [SCROLL-5] WBH.wblvl width guard: 200 → 160 px.
--             "Warband Level 99" rendered at ~234 px (GameFontHighlight)
--             which overflowed its 200 px SetWidth guard. Clamped to
--             160 px; right-aligned text truncates cleanly.
--
--  v8.0.0 — Midnight Architecture Upgrade vs v7.0.1
--  ─────────────────────────────────────────────────
--  [UPG-1]  Wide Mode    : FW 820 → 1025 (+25%), FH 610 → 650
--  [UPG-2]  Wider column : LCOL 210 → 262; PANELW 290 → 366
--  [UPG-3]  Readability  : FS() font GameFontHighlightSmall → GameFontHighlight
--  [UPG-4]  Panel titles : GameFontNormal → GameFontNormalLarge
--  [UPG-5]  Currency icons: 18px → 27px (1.5× per spec)
--  [UPG-6]  Affix icons  : 36px → 54px (1.5×)
--  [UPG-7]  Season icons : 22px → 33px (1.5×)
--  [UPG-8]  Rank nodes   : NODE_W 26 → 30 (easier to click)
--  [UPG-9]  Gear slots   : SLOT_SIZE 50 → 60 (more visible)
--  [UPG-10] Warband cards: WB_CARD_H 38 → 46 (roomier text)
--  [UPG-11] Row & bar    : ROW_H 20 → 22, BAR_H 6 → 8
--  [UPG-12] Tab buttons  : 94×24 → 120×26 (better hit area)
--
--  [FIX-1]  C_QuestLog.GetQuestInfo(questID) → GetTitleForQuestID
--           (was nil in 12.0.5 — questID ≠ log index)
--  [FIX-2]  Warband characters: scrollable grid, all chars visible
--  [FIX-3]  Vault button: InCombatLockdown() guard added
--  [FIX-4]  GetTotalAchievementPoints() →
--           C_AchievementInfo.GetTotalAchievementPoints() with fallback
--  [FIX-5]  AbbreviateNumbers() → AbbreviateLargeNumbers() (12.0.x rename)
--           with safe fallback wrapper Abbrev()
--  [FIX-6]  Dungeon/Raid bar widths now correctly stored (was discarded _)
--  [FIX-7]  startY upvalue explicitly documented in PvP do..end block
--
--  [SEC-1]  All global variable leaks localised
--           SLASH_ commands remain global (required by WoW API)
--  [OPT-1]  Long lines broken into readable segments throughout
--  [OPT-2]  All inline comments translated to English
-- ================================================================

if not DelveTrackerDB then
    print("|cffff4444[DT_userinfo]:|r DelveTrackerDB not found. Load DelveTracker first.")
    return
end

-- ================================================================
--  PHASE 1 — _W12 API COMPATIBILITY NAMESPACE
--  Wraps every Midnight-era API change behind safe pcall guards.
--  Reason: Blizzard restructured C_PvP, C_MythicPlus, C_QuestLog
--  significantly between 11.x → 12.0.5 (confirmed via Wowhead /
--  Blue Tracker API changelog for build 67314).
-- ================================================================
local _W12 = (function()

    -- Map panel slot index → PvP bracket enum value
    local BRACKET_MAP = { [1]=0, [2]=1, [3]=2, [4]=4, [5]=7 }

    local function GetRatedBracket(n)
        local e = BRACKET_MAP[n]
        if not e then return nil end
        local ok, info = pcall(C_PvP.GetRatedBracketInfo, e)
        return (ok and info) or nil
    end

    local function GetLifetimeHK()
        local ok, s = pcall(GetStatistic, 584)
        if ok and s and s ~= UNKNOWN then
            return tonumber((tostring(s):gsub("[,%.]", ""))) or 0
        end
        return 0
    end

    local function GetNumScores()
        return C_PvP.GetNumScoreEntries and C_PvP.GetNumScoreEntries() or 0
    end

    local function GetScoreInfo(i)
        return C_PvP.GetScoreInfo and C_PvP.GetScoreInfo(i) or nil
    end

    -- [UPG] C_MythicPlus.GetAffixInfo preferred; C_ChallengeMode fallback
    local function GetAffixInfo(id)
        if C_MythicPlus and C_MythicPlus.GetAffixInfo then
            return C_MythicPlus.GetAffixInfo(id)
        end
        if C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
            return C_ChallengeMode.GetAffixInfo(id)
        end
        return nil, nil, nil
    end

    local function GetWarModeBonus()
        if C_PvP and C_PvP.GetWarModeRewardBonus then
            return C_PvP.GetWarModeRewardBonus()
        end
        if GetWarModeRewardBonus then return GetWarModeRewardBonus() end
        return 0
    end

    local function IsInArena()
        if C_PvP and C_PvP.IsInArena then return C_PvP.IsInArena() end
        if IsActiveBattlefieldArena then return IsActiveBattlefieldArena() end
        return false
    end

    local function GetMatchWinner()
        if C_PvP and C_PvP.GetActiveMatchWinner then
            return C_PvP.GetActiveMatchWinner()
        end
        if GetBattlefieldWinner then
            local w = GetBattlefieldWinner()
            if w == nil then return nil end
            return w == 1 and "Alliance" or "Horde"
        end
        return nil
    end

    local function GetSeasonBest(mid)
        if C_MythicPlus and C_MythicPlus.GetSeasonBestForMap then
            local b = C_MythicPlus.GetSeasonBestForMap(mid)
            if b and b.level and b.level > 0 then return b.level end
        end
        if C_MythicPlus and C_MythicPlus.GetSeasonBestAffixScoreInfoForMap then
            local info = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mid)
            if info then
                for _, r in ipairs(info) do
                    if r.level and r.level > 0 then return r.level end
                end
            end
        end
        return 0
    end

    local function GetItemStats(link, out)
        if C_Item and C_Item.GetItemStats then
            return C_Item.GetItemStats(link, out)
        elseif GetItemStats then
            return GetItemStats(link, out)
        end
    end

    -- [FIX-5] GetMastery: multiple API paths for 12.0.x compatibility
    local function GetMastery()
        if GetMasteryEffect then
            local ok, v = pcall(GetMasteryEffect); if ok and v then return v end
        end
        if GetMastery then
            local ok, v = pcall(GetMastery); if ok and v then return v end
        end
        if C_PlayerInfo and C_PlayerInfo.GetMastery then
            local ok, v = pcall(C_PlayerInfo.GetMastery); if ok and v then return v end
        end
        return nil
    end

    -- [FIX-1] GetQuestInfo(index) expects a log-index, NOT a questID.
    -- In 12.0.5, passing a questID returns nil.
    -- Correct API: C_QuestLog.GetTitleForQuestID(questID).
    local function GetQuestTitleByID(id)
        if C_QuestLog.GetTitleForQuestID then
            local t = C_QuestLog.GetTitleForQuestID(id)
            if t then return t end
        end
        -- Fallback: resolve questID → log index → title
        if C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetInfo then
            local idx = C_QuestLog.GetLogIndexForQuestID(id)
            if idx then
                local info = C_QuestLog.GetInfo(idx)
                if info then return info.title end
            end
        end
        return nil
    end

    return {
        GetRatedBracket    = GetRatedBracket,
        GetLifetimeHK      = GetLifetimeHK,
        GetNumScores       = GetNumScores,
        GetScoreInfo       = GetScoreInfo,
        GetAffixInfo       = GetAffixInfo,
        GetWarModeBonus    = GetWarModeBonus,
        IsInArena          = IsInArena,
        GetMatchWinner     = GetMatchWinner,
        GetSeasonBest      = GetSeasonBest,
        GetItemStats       = GetItemStats,
        GetMastery         = GetMastery,
        GetQuestTitleByID  = GetQuestTitleByID,
    }
end)()

-- ================================================================
--  [FIX-5] AbbreviateLargeNumbers compatibility wrapper
--  Blizzard renamed AbbreviateNumbers → AbbreviateLargeNumbers in 12.x.
--  This local wrapper tries both, then falls back to tostring().
-- ================================================================
local function Abbrev(n)
    if AbbreviateLargeNumbers then
        local ok, s = pcall(AbbreviateLargeNumbers, n)
        if ok and s then return s end
    end
    if AbbreviateNumbers then
        local ok, s = pcall(AbbreviateNumbers, n)
        if ok and s then return s end
    end
    return tostring(n)
end

-- [FIX-4] Achievement points: C_AchievementInfo is the 12.0.x standard
local function GetAchievPoints()
    if C_AchievementInfo and C_AchievementInfo.GetTotalAchievementPoints then
        local ok, pts = pcall(C_AchievementInfo.GetTotalAchievementPoints)
        if ok and pts then return pts end
    end
    -- Legacy fallback
    if GetTotalAchievementPoints then
        local ok, pts = pcall(GetTotalAchievementPoints)
        if ok and pts then return pts end
    end
    return 0
end

-- ================================================================
--  DATABASE ACCESSOR
-- ================================================================
local function DB()
    DelveTrackerDB.UserInfo = DelveTrackerDB.UserInfo or {
        lang            = "en",
        bgStats         = {},
        amStats         = {},
        tgStats         = {},
        ddStats         = {},
        kills           = 0,
        deaths          = 0,
        sessionKB       = 0,
        honorEarned     = 0,
        preyWeekly      = 0,
        ritualRunsWeek  = 0,
        ritualHighestTier = 0,
        voidforgeUnlocked = false,
        voidforgeRollsWeek = 0,
        uiScale = 1.0,
    }
    return DelveTrackerDB.UserInfo
end

-- ================================================================
--  LOCALE TABLE  (English)
-- ================================================================
local L = {
    TITLE         = "CHARACTER DASHBOARD",
    EDITION       = "Midnight Edition",
    BTN_UPDATE    = "UPDATE",
    BTN_VAULT     = "OPEN VAULT",
    RESET_IN      = "Reset: ",
    LOCKED        = "locked",
    NO_GUILD      = "No guild",
    TAB_OVERVIEW  = "Overview",
    TAB_GEAR      = "Gear",
    TAB_PVP       = "PvP",
    TAB_WARBAND   = "Warband",
    TAB_SEASON    = "Season",
    ROLE_TANK     = "Tank",
    ROLE_HEALER   = "Healer",
    ROLE_DAMAGE   = "Damage",
    LBL_LIFETIME  = "Lifetime stats",
    LBL_UNRATED   = "Unrated (addon tracked)",
    LBL_BRACKET_BLITZ = "BG Blitz (8v8)",
    LBL_BRACKET_RBG   = "Rated BG (10v10)",
    LBL_BRACKET_SS    = "Solo Shuffle",
    ENCH_ALL_OK   = "✦ All enchants present",
    ENCH_MISSING  = "✕ Missing: ",
    BLAS_ACTIVE   = "◈ Blasphemite active",
    BLAS_INACTIVE = "◈ Blasphemite inactive",
    NO_ALTS       = "Login with alts to track them",
    ACTIVE_CHAR   = " ← active",
    EMPTY_SLOT    = "— empty —",
    CHAT_UPDATED  = "Data refreshed — ",
    STAND = {
        "Hated","Hostile","Unfriendly","Neutral",
        "Friendly","Honored","Revered","Exalted",
    },
    SLOT_NAMES = {
        "Head","Neck","Shoulders","Back","Chest","Wrists",
        "Hands","Waist","Legs","Feet",
        "Ring 1","Ring 2","Trinket 1","Trinket 2",
        "Main Hand","Off Hand",
    },
}

local function SetLocale(lang) DB().lang = "en" end

-- ================================================================
--  SEASON DATA
-- ================================================================
local SEASON = {
    PREY_FACTION_ID    = 2764,
    PREY_MAX_WEEKLY    = 4,
    PREY_RANKS         = 8,
    PREY_XP_PER_RANK   = 4000,
    PREY_RANK_REWARDS  = {
        [1] = "Cosmetic: Prey transmog access",
        [2] = "Mount: Hunted Drider",
        [3] = "Pet: Bloodscent Sprite",
        [4] = "Housing: Hunter's Trophy",
        [5] = "Cosmetic: Void-Stalker outfit",
        [6] = "Mount: Shadow Wraith",
        [7] = "Pet: Astalor Fledgling",
        [8] = "Title: Preyseeker + mount",
    },
    RITUAL_FACTION_ID = 2810,
    RITUAL_RANKS      = 8,
    RITUAL_MAX_TIER   = 5,
    RITUAL_RANK_REWARDS = {
        [1] = "Void transmog: weapons",
        [2] = "Housing: Void crystal",
        [3] = "Housing + Voidlight Marl",
        [4] = "Pet: Void-Infused Mindbreaker Fry",
        [5] = "Cosmetic: Void Tier 2",
        [6] = "Pet: Void-Scarred Eaglet",
        [7] = "Dark Obelisk housing item",
        [8] = "Mount: Corrupted Void creature",
    },
}

-- [v8.1] MIDNIGHT_REPS is now dynamically discovered from the WoW API.
-- GetNumFactions() / GetFactionInfo() returns actual in-game names and IDs.
-- Factions are filtered by factionID range and sorted by recency.
local MIDNIGHT_REPS = {}  -- kept for API compatibility; populated dynamically

-- Midnight enchant IDs → display names
-- [FIX-12 v8.1] Midnight 12.0.x enchant names — verified via NextTier.pro, Icy Veins, Method.gg
-- NOTE: IDs 7400-7452 are placeholders; verify exact IDs in-game or via Wowhead Looter.
-- REMOVED enchant slots in Midnight: Neck(2), Wrists(9), Cloak/Back(15)
-- NEW enchant slots in Midnight: Helm(1) returns, Shoulders(3) return
local ENCHANT_NAMES = {
    -- Weapon enchants
    [7400] = "Devouring Banding",              -- DPS weapon
    [7401] = "Arcanoweave Lining",             -- Healer weapon (primary stat buff for party)
    [7402] = "Worldsoul Aegis",               -- Tank weapon (defensive proc)
    -- Chest enchants (primary-stat based)
    [7410] = "Mark of the Magister",    -- Int + Max Mana
    [7411] = "Enchant Chest - Mark of the Worldsoul",   -- Universal primary stat
    [7412] = "Mark of Nalorakk",        -- Str + Stamina
    [7413] = "Mark of the Rootwarden",  -- Agi + Speed
    -- Helm enchants (role + on-kill proc)
    [7420] = "Emp. Blessing of Speed",  -- DPS: Speed + Vigor
    [7421] = "Enchant Helm - Blessing of Speed",             -- Budget Speed
    [7422] = "Emp. Hex of Leeching",    -- Healer: Leech + heal
    [7423] = "Enchant Helm - Hex of Leeching",               -- Budget Leech
    [7424] = "Emp. Rune of Avoidance",  -- Tank: Avoidance + speed
    [7425] = "Enchant Helm - Rune of Avoidance",             -- Budget Avoidance
    -- Shoulder enchants (NEW in Midnight)
    [7430] = "Amirdrassil's Grace",  -- All roles
    -- Boots enchants (tertiary stat)
    [7440] = "Farstrider's Hunt",     -- Speed + Stamina (DPS)
    [7441] = "Shaladrassil's Roots",  -- Leech + Stamina (Healer)
    [7442] = "Lynx's Dexterity",      -- Avoidance + Stamina (Tank)
    -- Ring enchants
    [7450] = "Nature's Fury",           -- Haste / Vers
    [7451] = "Eyes of the Eagle",       -- Crit Strike Effectiveness
    [7452] = "Amani Mastery",           -- Mastery
    -- Actual Midnight IDs detected in-game (add more as you find them)
    [7958] = "Helm Enchant (12.x)",           -- update name when Wowhead confirms
    [8028] = "Shoulders Enchant (12.x)",       -- update name when Wowhead confirms
    [7994] = "Ring Enchant (12.x)",
    [8020] = "Ring Enchant B (12.x)",
    [7800] = "Blessing of Speed",
    [7801] = "Hex of Leeching",
    [7802] = "Rune of Avoidance",
    [7803] = "Amirdrassil's Grace",
    [7810] = "Mark of the Magister",
    [7811] = "Mark of Nalorakk",
    [7812] = "Mark of the Rootwarden",
    [7820] = "Farstrider's Hunt",
    [7821] = "Shaladrassil's Roots",
    [7822] = "Lynx's Dexterity",
    [7830] = "Nature's Fury",
    [7831] = "Eyes of the Eagle",
    [7832] = "Amani Mastery",
    [7840] = "Devouring Banding",
    [7841] = "Arcanoweave Lining",
    [7842] = "Worldsoul Aegis",
    -- Legacy TWW enchants (kept for backward detection only)
    [6625] = "Algari Finesse: Crit (TWW)",
    [6626] = "Algari Finesse: Haste (TWW)",
    [6627] = "Algari Finesse: Mastery (TWW)",
    [6628] = "Algari Finesse: Vers (TWW)",
    [6652] = "Shadowflame Wreathe (TWW)",
    [6657] = "Dreaming Devotion (TWW)",
}

-- Currency IDs for Midnight Season 1
local CUR = {
    RESTORED_COFFER_KEY  = 3028,
    COFFER_KEY_SHARDS    = 3310,
    DELVERS_JOURNEY      = 3318,
    SHARD_OF_DUNDUN      = 3376,
    UNALLOYED_ABUNDANCE  = 3377,
    DAWNLIGHT_MANAFLUX   = 3378,
    BRIMMING_ARCANA      = 3379,
    LUMINOUS_DUST        = 3385,
    REMNANT_OF_ANGUISH   = 3392,
    VOIDLIGHT_MARL       = 3316,
    ADVENTURER_DAWNCREST = 3383,
    VETERAN_DAWNCREST    = 3341,
    CHAMPION_DAWNCREST   = 3343,
    HERO_DAWNCREST       = 3345,
    MYTH_DAWNCREST       = 3347,
    VALORSTONES          = 3008,
    UNDERCOIN            = 2803,
    KEJ                  = 3034,
    CONQUEST             = 1792,
    HONOR                = 1901,
}

-- Currency panel display order (nil = horizontal divider)
local CUR_DISPLAY = {
    { CUR.ADVENTURER_DAWNCREST, "Adventurer Dawncrest", 0.67, 0.67, 0.67 },
    { CUR.VETERAN_DAWNCREST,    "Veteran Dawncrest",    1.0,  0.87, 0.27 },
    { CUR.CHAMPION_DAWNCREST,   "Champion Dawncrest",   0.0,  0.44, 0.87 },
    { CUR.HERO_DAWNCREST,       "Hero Dawncrest",       0.8,  0.53, 1.0  },
    { CUR.MYTH_DAWNCREST,       "Myth Dawncrest",       0.0,  0.8,  1.0  },
    nil,
    { CUR.VALORSTONES,          "Valorstones",          1.0,  0.6,  0.13 },
    { CUR.SHARD_OF_DUNDUN,      "Shard of Dundun",      1.0,  0.84, 0.0  },
    { CUR.DAWNLIGHT_MANAFLUX,   "Dawnlight Manaflux",   0.27, 0.87, 0.8  },
    nil,
    { CUR.RESTORED_COFFER_KEY,  "Restored Coffer Key",  0.27, 0.87, 0.8  },
    { CUR.COFFER_KEY_SHARDS,    "Coffer Key Shards",    1.0,  0.87, 0.27 },
    nil,
    { CUR.CONQUEST,             "Conquest",             1.0,  0.33, 0.13 },
    { CUR.HONOR,                "Honor",                0.4,  0.67, 1.0  },
}

-- Inventory slot ordering (slotID, slotNameIndex)
local GEAR_SLOTS_DEF = {
    {1,1},{2,2},{3,3},{15,4},{5,5},{9,6},{10,7},{6,8},
    {7,9},{8,10},{11,11},{12,12},{13,13},{14,14},{16,15},{17,16},
}

-- ================================================================
--  [v8.1] _G81 NAMESPACE  -- all v8.1 data in ONE new top-level local
--  Prevents exceeding Lua's 200-local-per-chunk limit.
-- ================================================================
local _G81 = {}

_G81.SPEC_DATA = {
    [250]={nm="Blood DK",        r="TANK",p="str",prio={"Haste","Mastery","Vers","Crit"}},
    [251]={nm="Frost DK",        r="DAM", p="str",prio={"Haste","Crit","Mastery","Vers"}},
    [252]={nm="Unholy DK",       r="DAM", p="str",prio={"Haste","Crit","Mastery","Vers"}},
    [577]={nm="Havoc DH",        r="DAM", p="agi",prio={"Haste","Crit","Vers","Mastery"}},
    [581]={nm="Vengeance DH",    r="TANK",p="agi",prio={"Vers","Mastery","Haste","Crit"}},
    [102]={nm="Balance Druid",   r="DAM", p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [103]={nm="Feral Druid",     r="DAM", p="agi",prio={"Haste","Crit","Mastery","Vers"}},
    [104]={nm="Guardian Druid",  r="TANK",p="agi",prio={"Mastery","Haste","Vers","Crit"}},
    [105]={nm="Resto Druid",     r="HEAL",p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [1467]={nm="Devastation",    r="DAM", p="int",prio={"Mastery","Crit","Haste","Vers"}},
    [1468]={nm="Preservation",   r="HEAL",p="int",prio={"Mastery","Haste","Crit","Vers"}},
    [1473]={nm="Augmentation",   r="DAM", p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [253]={nm="Beast Mastery",   r="DAM", p="agi",prio={"Haste","Crit","Mastery","Vers"}},
    [254]={nm="Marksmanship",    r="DAM", p="agi",prio={"Haste","Mastery","Crit","Vers"}},
    [255]={nm="Survival",        r="DAM", p="agi",prio={"Haste","Crit","Vers","Mastery"}},
    [62]= {nm="Arcane Mage",     r="DAM", p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [63]= {nm="Fire Mage",       r="DAM", p="int",prio={"Crit","Haste","Mastery","Vers"}},
    [64]= {nm="Frost Mage",      r="DAM", p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [268]={nm="Brewmaster",      r="TANK",p="agi",prio={"Haste","Mastery","Crit","Vers"}},
    [269]={nm="Windwalker",      r="DAM", p="agi",prio={"Haste","Crit","Mastery","Vers"}},
    [270]={nm="Mistweaver",      r="HEAL",p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [65]= {nm="Holy Paladin",    r="HEAL",p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [66]= {nm="Protection Pal.", r="TANK",p="str",prio={"Mastery","Haste","Vers","Crit"}},
    [70]= {nm="Retribution",     r="DAM", p="str",prio={"Haste","Crit","Vers","Mastery"}},
    [256]={nm="Discipline",      r="HEAL",p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [257]={nm="Holy Priest",     r="HEAL",p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [258]={nm="Shadow Priest",   r="DAM", p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [259]={nm="Assassination",   r="DAM", p="agi",prio={"Haste","Crit","Mastery","Vers"}},
    [260]={nm="Outlaw",          r="DAM", p="agi",prio={"Haste","Crit","Mastery","Vers"}},
    [261]={nm="Subtlety",        r="DAM", p="agi",prio={"Crit","Haste","Mastery","Vers"}},
    [262]={nm="Elemental",       r="DAM", p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [263]={nm="Enhancement",     r="DAM", p="agi",prio={"Haste","Crit","Mastery","Vers"}},
    [264]={nm="Resto Shaman",    r="HEAL",p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [265]={nm="Affliction",      r="DAM", p="int",prio={"Haste","Mastery","Crit","Vers"}},
    [266]={nm="Demonology",      r="DAM", p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [267]={nm="Destruction",     r="DAM", p="int",prio={"Haste","Crit","Mastery","Vers"}},
    [71]= {nm="Arms",            r="DAM", p="str",prio={"Haste","Crit","Mastery","Vers"}},
    [72]= {nm="Fury",            r="DAM", p="str",prio={"Haste","Crit","Mastery","Vers"}},
    [73]= {nm="Protection War.", r="TANK",p="str",prio={"Vers","Mastery","Haste","Crit"}},
}

_G81.ENCH_RECS = {
    helm    ={DAM={"Emp. Blessing of Speed","Speed+Vigor proc"},
              HEAL={"Emp. Hex of Leeching","Leech+heal proc"},
              TANK={"Emp. Rune of Avoidance","Avoidance+speed proc"}},
    shoulders={ALL={"Amirdrassil's Grace","All roles"}},
    chest   ={int={"Mark of the Magister","Int + Max Mana"},
              str={"Mark of Nalorakk","Str + Stamina"},
              agi={"Mark of the Rootwarden","Agi + Speed"}},
    boots   ={DAM={"Farstrider's Hunt","Speed + Stamina"},
              HEAL={"Shaladrassil's Roots","Leech + Stamina"},
              TANK={"Lynx's Dexterity","Avoidance + Stamina"}},
    ring    ={Haste={"Nature's Fury","Haste"},
              Crit={"Eyes of the Eagle","Crit Effectiveness"},
              Mastery={"Amani Mastery","Mastery"},
              Vers={"Nature's Fury","Vers"}},
    weapon  ={DAM={"Devouring Banding","Damage + stat proc"},
              HEAL={"Arcanoweave Lining","Primary stat party buff"},
              TANK={"Worldsoul Aegis","Defensive proc"}},
    legs    ={int={"Arcanoweave Spellthread","Tailoring -- Int+Mana"},
              str={"Blood Knight's Armor Kit","LW -- Str+Armor"},
              agi={"Forest Hunter's Armor Kit","LW -- Agi/Str+Stam"}},
}

_G81.GEM_RECS = {
    meta={name="Indecipherable Eversong Diamond",note="Primary stat (always x1)"},
    secondary={
        Haste  ={name="Flawless Quick Amethyst",    note="Haste+Crit dual-stat"},
        Crit   ={name="Flawless Quick Amethyst",    note="Haste+Crit dual-stat"},
        Mastery={name="Flawless Masterful Amethyst", note="Haste+Mastery dual-stat"},
        Vers   ={name="Flawless Versatile Peridot",  note="Vers+Haste dual-stat"},
    },
}

-- [FIX-10] Midnight 12.0.x: Cloak/Wrists/Neck removed; Helm/Shoulders added
_G81.ENCH_SLOTS_12={[1]=true,[3]=true,[5]=true,[8]=true,[11]=true,[12]=true,[16]=true,[17]=true}
_G81.LEG_SLOTS   ={[7]=true}
_G81.SLOT_TYPE   ={[1]="helm",[3]="shoulders",[5]="chest",[8]="boots",[11]="ring",[12]="ring",[16]="weapon",[17]="weapon",[7]="legs"}

function _G81:GetSpecEntry()
    local si=GetSpecialization(); if not si then return nil end
    local id=GetSpecializationInfo(si); return id and self.SPEC_DATA[id] or nil
end
function _G81:GetEnchantRec(slotID,sd)
    if not sd then return nil end
    local st=self.SLOT_TYPE[slotID]; if not st then return nil end
    local r=self.ENCH_RECS[st]; if not r then return nil end
    if st=="chest" or st=="legs" then return r[sd.p]
    elseif st=="ring" then return r[sd.prio and sd.prio[1] or "Haste"]
    else return r[sd.r] or r["ALL"] end
end
function _G81:GetGemRec(sd)
    local top=sd and sd.prio and sd.prio[1] or "Haste"
    return self.GEM_RECS.secondary[top] or self.GEM_RECS.secondary["Haste"]
end

_G81.spFS=nil; _G81.prioPills={}; _G81.recRows={}; _G81.REC={}
_G81.PL = ParseLink  -- store upvalue ref so method can reach it

function _G81:RefreshGearRecs()
    local sd    = self:GetSpecEntry()
    local SCOL  = {Haste="ffdd44",Crit="ff5544",Mastery="4dc8ff",Vers="44ee66"}

    -- ── Spec priority strip ───────────────────────────────────────────────────
    if self.spFS then
        if sd then
            self.spFS:SetText("|cff4dc8ff"..sd.nm.."|r  |cff4a6a9a| Priority:|r")
            for i = 1, 4 do
                local st = sd.prio[i]
                if self.prioPills[i] then
                    self.prioPills[i]:SetText(st and
                        ("|cff"..(SCOL[st] or "aaaaaa")..(i==1 and "> " or "").."#"..i.." "..st.."|r")
                        or "")
                end
            end
        else
            self.spFS:SetText("|cff4a6a9a(Open spellbook to detect spec)|r")
            for i = 1, 4 do if self.prioPills[i] then self.prioPills[i]:SetText("") end end
        end
    end

    -- ── Recommendation label (multi-line, single FontString) ─────────────────
    if not self.recLabel then return end

    local SLOT_DEFS = {
        {1,"Helm    "},{3,"Shoulder"},{5,"Chest   "},{8,"Boots   "},
        {11,"Ring 1  "},{12,"Ring 2  "},{16,"MainHand"},{7,"Legs*   "},
    }
    local lines = {}
    for _, def in ipairs(SLOT_DEFS) do
        local sid   = def[1]
        local sname = def[2]
        local link  = GetInventoryItemLink("player", sid)
        local eID   = link and self.PL and self.PL(link) or nil
        local rec   = self:GetEnchantRec(sid, sd)
        local rname = rec and rec[1] or "?"
        local icon, col, txt

        if not link then
            icon = "|cff4a6a9a-|r"; col = "4a6a9a"; txt = "—"
        elseif self.LEG_SLOTS[sid] then
            if eID then icon="|cff44ee66ok|r"; col="44ee66"; txt=rname
            else         icon="|cffffdd44>>|r"; col="ffdd44"; txt=rname end
        elseif self.ENCH_SLOTS_12[sid] then
            if eID then
                local kn = ENCHANT_NAMES[eID]
                icon="|cff44ee66ok|r"; col="aaddbb"
                txt = kn or ("Enchanted #"..eID)
            else
                icon="|cffff5544!!|r"; col="ffdd44"; txt=rname
            end
        else
            icon="|cff4a6a9a-|r"; col="4a6a9a"; txt="N/A"
        end
        lines[#lines+1] = icon.." |cff4a6a9a"..sname.."|r |cff"..col..txt.."|r"
    end
    self.recLabel:SetText(table.concat(lines, "|n"))

    -- ── Gem recommendations ───────────────────────────────────────────────────
    if self.REC.gem1 then
        local gr = sd and self:GetGemRec(sd)
        self.REC.gem1:SetText("|cff4a6a9aMeta:  |r|cffffdd44"..self.GEM_RECS.meta.name.."|r")
        self.REC.gem2:SetText("|cff4a6a9aSecnd: |r|cff4dc8ff"..(gr and gr.name or "Flawless Quick Amethyst").."|r")
    end
end

-- ================================================================
--  PHASE 2 — LAYOUT CONSTANTS
--  [UPG-1] Wide Mode: FW 820 → 1025 (+25%)
--  [UPG-2] Height bump: FH 610 → 650
--  All derived dimensions are auto-calculated from FW/FH.
-- ================================================================
local FW          = 1025          -- [UPG-1] was 820
local FH          = 650           -- [UPG-1] was 610
local LCOL        = 262           -- [UPG-2] was 210; left character column
local PANELH      = 210           -- top-row panel height (was 200)
local WEEKLY_H    = 300           -- weekly/currency panel height (was 282)
local CUR_PANEL_H = 280           -- currency panel height (was 260)
local PGAP        = 8             -- gap between panels
local PAD         = 14            -- inner padding
local ROW_H       = 22            -- [UPG-11] text row height (was 20)
local BAR_H       = 8             -- [UPG-11] progress bar height (was 6)
local NODE_W      = 30            -- [UPG-8] rank track node (was 26)
local SLOT_SIZE   = 60            -- [UPG-9] gear slot icon (was 50)
local SLOT_PAD    = 8             -- gear slot spacing (was 6)
-- [FIX-SCROLL] Width reserved for UIPanelScrollFrameTemplate scrollbar.
-- All ScrollFrame panels must subtract this from their content width
-- to prevent text from being hidden behind the scrollbar thumb.
local SCROLLBAR_W = 20

-- Panel width: auto-calculated to fill the two-column layout
local PANELW = math.floor((FW - LCOL - 14) / 2) - PGAP   -- → 366

-- ================================================================
--  COLOR HELPERS  (local — no global pollution)
-- ================================================================
local function CC(h, t)    return "|cff" .. h .. t .. "|r" end
local function Blue(t)     return CC("4dc8ff", t) end
local function Green(t)    return CC("44ee66", t) end
local function Yellow(t)   return CC("ffdd44", t) end
local function Gold(t)     return CC("ffd700", t) end
local function Red(t)      return CC("ff5544", t) end
local function Purple(t)   return CC("cc88ff", t) end
local function Orange(t)   return CC("ff9922", t) end
local function Dim(t)      return CC("4a6a9a", t) end
local function Teal(t)     return CC("44ddcc", t) end

-- Item quality colors (index 0–6)
local QCOLOR = {
    [0]="9d9d9d",[1]="ffffff",[2]="1eff00",
    [3]="0070dd",[4]="a335ee",[5]="ff8000",[6]="00ccff",
}
local function QC(q) return QCOLOR[q] or "ffffff" end

-- ================================================================
--  UTILITY FUNCTIONS
-- ================================================================
local function ServerTime()
    local t = C_DateAndTime.GetCurrentCalendarTime()
    return string.format("%02d:%02d", t.hour, t.minute)
end

local function ResetIn()
    local s = C_DateAndTime.GetSecondsUntilWeeklyReset()
    if not s or s <= 0 then return Green("Now!") end
    local d = math.floor(s / 86400)
    local h = math.floor((s % 86400) / 3600)
    local m = math.floor((s % 3600) / 60)
    return d > 0 and Yellow(d .. "d " .. h .. "h") or Red(h .. "h " .. m .. "m")
end

local function ColorProg(cur, max)
    if not cur or not max or max == 0 then return Yellow((cur or "?") .. "/??") end
    if cur >= max              then return Green(cur .. "/" .. max)
    elseif cur >= max * 0.5   then return Yellow(cur .. "/" .. max)
    else                           return Red(cur .. "/" .. max) end
end

local function GetCur(id)
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if not ok or not info then return 0, 0 end
    return info.quantity or 0, info.maxQuantity or 0
end

local function SafeGet(fn, ...) local ok, v = pcall(fn, ...); return ok and v or nil end

local function SafeFmt(val, fmt, color)
    if val == nil then return Dim("—") end
    local ok, r = pcall(string.format, fmt, val)
    if not ok then r = Abbrev(val) end
    return color and color(r) or r
end

local function SafeBar(bW, cur, max)
    if not cur or not max or max == 0 then return 0 end
    local ok, w = pcall(function()
        return math.min(bW, bW * (cur / max))
    end)
    return ok and w or 0
end

local function ParseLink(link)
    if not link then return nil, {} end
    local data = link:match("item:([^|]+)")
    if not data then return nil, {} end
    local parts = {}
    for p in (data .. ":"):gmatch("([^:]*):") do
        parts[#parts + 1] = tonumber(p) or 0
    end
    local eID = (parts[2] and parts[2] > 0) and parts[2] or nil
    local gems = {}
    for i = 3, 6 do
        if parts[i] and parts[i] > 0 then gems[#gems + 1] = parts[i] end
    end
    return eID, gems
end

local function GemColor(id)
    local _, _, _, _, _, _, sub = GetItemInfo(id)
    if sub then
        if sub:find("Red")    or sub:find("Crimson")   then return "ff4466" end
        if sub:find("Blue")   or sub:find("Sapphire")  then return "4488ff" end
        if sub:find("Green")  or sub:find("Emerald")   then return "44dd66" end
        if sub:find("Yellow") or sub:find("Topaz")     then return "ffdd44" end
        if sub:find("Purple") or sub:find("Amethyst")  then return "cc44ff" end
        if sub:find("Orange")                           then return "ff9922" end
        if sub:find("Meta")                             then return "44ddcc" end
    end
    return "aabbcc"
end

-- ================================================================
--  UI BUILDER HELPERS
-- ================================================================

-- BuildRankTrack: horizontal rank-progress strip with hover tooltips
local function BuildRankTrack(parent, x, y, count, rewards)
    local nodes  = {}
    local avail  = parent:GetWidth() - (x * 2)
    local nW     = math.min(NODE_W, math.floor(avail / count) - 3)

    for i = 1, count do
        local n = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        n:SetSize(nW, nW)
        n:SetPoint("TOPLEFT", parent, "TOPLEFT", x + (i - 1) * (nW + 3), y)
        n:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        -- [UPG-8] node font size scales with node width
        n.fs = n:CreateFontString(nil, "OVERLAY")
        n.fs:SetFont("Fonts\\2002.ttf", nW > 26 and 10 or 8, "OUTLINE")
        n.fs:SetPoint("CENTER", n, "CENTER", 0, 1)
        n.fs:SetText(tostring(i))

        if rewards and rewards[i] then
            n:EnableMouse(true)
            n.reward = rewards[i]
            n.rank   = i
            n:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(CC("ffdd44", "Rank " .. self.rank), 1, 1, 1)
                GameTooltip:AddLine(self.reward, 1, 0.82, 0, true)
                GameTooltip:Show()
            end)
            n:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        nodes[i] = n
    end

    local function Update(rank)
        for i, n in ipairs(nodes) do
            if i < rank then
                n:SetBackdropColor(0.03, 0.12, 0.05, 1)
                n:SetBackdropBorderColor(0.1, 0.4, 0.15, 1)
                n.fs:SetTextColor(0.27, 0.93, 0.4, 1)
            elseif i == rank then
                n:SetBackdropColor(0.04, 0.1, 0.2, 1)
                n:SetBackdropBorderColor(0.15, 0.45, 0.8, 1)
                n.fs:SetTextColor(0.3, 0.78, 1, 1)
            else
                n:SetBackdropColor(0.02, 0.03, 0.07, 1)
                n:SetBackdropBorderColor(0.06, 0.1, 0.2, 0.8)
                n.fs:SetTextColor(0.16, 0.23, 0.35, 1)
            end
        end
    end

    Update(1)
    return nodes, Update
end

-- MakePanel: standard dark backdrop panel
local function MakePanel(parent, x, y, w, h)
    local p = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    p:SetSize(w, h)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    p:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    p:SetBackdropColor(0.01, 0.015, 0.05, 1)
    p:SetBackdropBorderColor(0.10, 0.20, 0.42, 0.7)
    return p
end

-- PanelTitle: [UPG-4] now uses GameFontNormalLarge for better readability
local function PanelTitle(panel, text, y)
    local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y or -PAD + 2)
    t:SetText(text)
    return t
end

-- FS: [UPG-3] GameFontHighlightSmall → GameFontHighlight for legibility
local function FS(parent, yOff, width, xOff)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont("Fonts\\2002.ttf", 13, "")
    f:SetTextColor(1, 1, 1, 1)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff or PAD, yOff)
    f:SetWidth(width or (parent:GetWidth() - PAD * 2))
    f:SetJustifyH("LEFT")
    return f
end

-- SFS: small sub-header font string (section labels, axis captions)
local function SFS(parent, yOff, xOff)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont("Fonts\\2002.ttf", 9, "")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff or PAD, yOff)
    f:SetWidth(parent:GetWidth() - PAD * 2)
    f:SetJustifyH("LEFT")
    f:SetTextColor(0.2, 0.3, 0.5, 1)
    return f
end

-- Bar: horizontal progress bar; returns (fillTexture, barWidth)
local function Bar(parent, yOff, r, g, b, xOff)
    local x  = xOff or PAD
    local bW = parent:GetWidth() - (x * 2) - 2
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(bW, BAR_H)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, yOff)
    bg:SetColorTexture(0.04, 0.06, 0.13, 1)
    local fill = parent:CreateTexture(nil, "ARTWORK")
    fill:SetSize(0, BAR_H)
    fill:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    fill:SetColorTexture(r, g, b, 1)
    return fill, bW
end

-- Div: horizontal separator line
local function Div(parent, yOff)
    local d = parent:CreateTexture(nil, "BACKGROUND")
    d:SetHeight(1)
    d:SetPoint("TOPLEFT",  parent, "TOPLEFT",  PAD, yOff)
    d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, yOff)
    d:SetColorTexture(0.08, 0.15, 0.30, 1)
end

-- MakeCurrencyRow: icon + label + right-aligned value
-- [UPG-5] iconSize 18 → 27 (1.5×)
local function MakeCurrencyRow(parent, y, id, label, r, g, b)
    local rowH    = 24          -- slightly taller for bigger icons
    local iconSz  = 27          -- [UPG-5] was 18
    local xOff    = PAD

    local iconF = parent:CreateTexture(nil, "ARTWORK")
    iconF:SetSize(iconSz, iconSz)
    iconF:SetPoint("TOPLEFT", parent, "TOPLEFT",
        xOff, y + math.floor((rowH - iconSz) / 2))

    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok and info and info.iconFileID then
        iconF:SetTexture(info.iconFileID)
    else
        iconF:SetColorTexture(r, g, b, 0.6)
    end

    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\2002.ttf", 10, "")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff + iconSz + 5, y)
    lbl:SetHeight(rowH)
    lbl:SetTextColor(0.29, 0.42, 0.6, 1)
    lbl:SetText(label)
    lbl:SetWidth(parent:GetWidth() - xOff - iconSz - 5 - 50)

    local val = parent:CreateFontString(nil, "OVERLAY")
    val:SetFont("Fonts\\2002.ttf", 11, "OUTLINE")
    val:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, y)
    val:SetHeight(rowH)
    val:SetJustifyH("RIGHT")
    val:SetTextColor(r, g, b, 1)

    -- Row divider
    local dv = parent:CreateTexture(nil, "BACKGROUND")
    dv:SetHeight(1)
    dv:SetPoint("BOTTOMLEFT",  parent, "TOPLEFT",  PAD, y + 1)
    dv:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", -PAD, y + 1)
    dv:SetColorTexture(0.05, 0.1, 0.2, 1)

    return val, iconF
end

-- ================================================================
--  MAIN FRAME
--  [UPG-1] Size 820×610 → 1025×650
--  [SEC-1] ClampedToScreen ensures the frame never goes off-screen
-- ================================================================
local frame = CreateFrame("Frame", "DT_UserInfoFrame", UIParent, "BackdropTemplate")
frame:SetSize(FW, FH)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)       -- [SEC-1] prevent off-screen drift
frame:SetFrameStrata("DIALOG")
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
frame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile     = true, tileSize = 16, edgeSize = 1,
    insets   = { left=2, right=2, top=2, bottom=2 },
})
frame:SetBackdropColor(0.01, 0.015, 0.05, 0.97)
frame:SetBackdropBorderColor(0.12, 0.22, 0.45, 0.9)
frame:Hide()

-- Header decorations
local accent = frame:CreateTexture(nil, "OVERLAY")
accent:SetSize(FW - 4, 2)
accent:SetPoint("TOP", frame, "TOP", 0, -2)
accent:SetColorTexture(0.3, 0.78, 1, 0.35)

local hdrBG = frame:CreateTexture(nil, "BACKGROUND")
hdrBG:SetSize(FW - 4, 38)
hdrBG:SetPoint("TOP", frame, "TOP", 0, -4)
hdrBG:SetColorTexture(0.03, 0.07, 0.16, 1)

-- [UPG-4] Header title uses GameFontNormalLarge
local hdrT = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
hdrT:SetPoint("LEFT", hdrBG, "LEFT", 12, 0)

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
closeBtn:SetFrameLevel(frame:GetFrameLevel() + 20)

-- ================================================================
--  TAB SYSTEM
--  [UPG-12] Button size 94×24 → 120×26; step 97 → 126
-- ================================================================
local tabBtns, tabFrames = {}, {}
local activeTab = 1

local function ShowTab(idx)
    activeTab = idx
    for i, tf in ipairs(tabFrames) do tf:SetShown(i == idx) end
    for i, tb in ipairs(tabBtns) do
        local on = (i == idx)
        local cv = on and {0, 0.5, 0.9} or {0.05, 0.1, 0.2}
        for _, p in ipairs({"Left","Right","Middle"}) do
            if tb[p] then tb[p]:SetVertexColor(cv[1], cv[2], cv[3]) end
        end
        tb:GetFontString():SetTextColor(
            on and 0.3  or 0.29,
            on and 0.78 or 0.42,
            on and 1.0  or 0.6
        )
    end
end

for i = 1, 5 do
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btn:SetSize(120, 26)                              -- [UPG-12] was 94×24
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 + (i - 1) * 126, -40)
    btn:SetFrameLevel(frame:GetFrameLevel() + 15)
    tabBtns[i] = btn

    local tf = CreateFrame("Frame", nil, frame)
    tf:SetPoint("TOPLEFT",     frame, "TOPLEFT",     4, -70)
    tf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    tabFrames[i] = tf
end

-- ================================================================
--  TAB 1: OVERVIEW
-- ================================================================
local OV = tabFrames[1]

-- Left column: 3D character model
local modelBox = MakePanel(OV, 0, 0, LCOL, 248)
local model    = CreateFrame("PlayerModel", nil, modelBox)
model:SetPoint("TOPLEFT",     modelBox, "TOPLEFT",     2, -2)
model:SetPoint("BOTTOMRIGHT", modelBox, "BOTTOMRIGHT", -2, 2)
model:SetFrameLevel(modelBox:GetFrameLevel() + 1)
model:SetCamera(0); model:SetPortraitZoom(0)

-- Spin model on hover
modelBox:EnableMouse(true)
modelBox:SetScript("OnEnter", function()
    model:SetScript("OnUpdate", function(self, e)
        self:SetFacing(self:GetFacing() + e * 0.5)
    end)
end)
modelBox:SetScript("OnLeave", function()
    model:SetScript("OnUpdate", nil)
    model:SetFacing(0.6)
end)

-- Info lines below the model
local infoBox = MakePanel(OV, 0, -252, LCOL, FH - 70 - 252 - 44)
local IL      = {}
local function ILine(y) return FS(infoBox, y, LCOL - PAD * 2) end
IL.name   = ILine(-PAD)
IL.spec   = ILine(-(PAD + ROW_H))
IL.ilvl   = ILine(-(PAD + ROW_H * 2))
IL.guild  = ILine(-(PAD + ROW_H * 3))
IL.zone   = ILine(-(PAD + ROW_H * 4))
IL.gold   = ILine(-(PAD + ROW_H * 5))
IL.time   = ILine(-(PAD + ROW_H * 6))
IL.reset  = ILine(-(PAD + ROW_H * 7))
IL.achiev = ILine(-(PAD + ROW_H * 8))
IL.profA  = ILine(-(PAD + ROW_H * 9))
IL.profB  = ILine(-(PAD + ROW_H * 10))

-- Right area: four data panels in a 2×2 grid
local RX     = LCOL + PGAP
local startY = -(PAD + ROW_H + 6)   -- shared top offset for panel content

local pCombat   = MakePanel(OV, RX,               0,            PANELW, PANELH)
local pMythic   = MakePanel(OV, RX + PANELW + PGAP, 0,          PANELW, PANELH)
local pWeekly   = MakePanel(OV, RX,               -(PANELH + PGAP), PANELW, WEEKLY_H)
local pCurrency = MakePanel(OV, RX + PANELW + PGAP, -(PANELH + PGAP), PANELW, WEEKLY_H)

-- Convenience helper: full-width row in a panel
local function SR(p, y) return FS(p, y, PANELW - PAD * 2) end

-- Combat Stats panel
local CS = {}
CS.haste   = SR(pCombat, startY)
CS.crit    = SR(pCombat, startY - ROW_H)
CS.mastery = SR(pCombat, startY - ROW_H * 2)
CS.vers    = SR(pCombat, startY - ROW_H * 3)
CS.leech   = SR(pCombat, startY - ROW_H * 4)
Div(pCombat, startY - ROW_H * 5 + 2)
CS.speed   = SR(pCombat, startY - ROW_H * 5 - 8)
CS.hp      = SR(pCombat, startY - ROW_H * 6 - 8)
CS.stam    = SR(pCombat, startY - ROW_H * 7 - 8)

-- Mythic+ panel: affix icons [UPG-6] 36 → 54px
local affixFrames = {}
for i = 1, 4 do
    local af  = CreateFrame("Frame", nil, pMythic)
    local afSz = 54                                   -- [UPG-6] was 36
    af:SetSize(afSz, afSz)
    af:SetPoint("TOPLEFT", pMythic, "TOPLEFT",
        PAD + (i - 1) * (afSz + 6), -(PAD + ROW_H + 6))

    local abg = af:CreateTexture(nil, "BACKGROUND")
    abg:SetAllPoints(); abg:SetColorTexture(0.04, 0.07, 0.16, 1)

    local abd = af:CreateTexture(nil, "BORDER")
    abd:SetPoint("TOPLEFT", -1, 1); abd:SetPoint("BOTTOMRIGHT", 1, -1)
    abd:SetColorTexture(0.10, 0.20, 0.42, 0.8)

    af.tex = af:CreateTexture(nil, "ARTWORK"); af.tex:SetAllPoints()
    af:EnableMouse(true)
    af:SetScript("OnEnter", function(self)
        if self.affixID then
            local n, d = _W12.GetAffixInfo(self.affixID)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(n or "?", 1, 1, 1)
            if d then GameTooltip:AddLine(d, 1, 0.82, 0, true) end
            GameTooltip:Show()
        end
    end)
    af:SetScript("OnLeave", function() GameTooltip:Hide() end)
    affixFrames[i] = af
end

-- Mythic+ stat rows below affix icons
local afY = startY - 54 - 10     -- offset below the 54px icons
local MK  = {}
MK.rating = SR(pMythic, afY)
MK.best   = SR(pMythic, afY - ROW_H)
Div(pMythic, afY - ROW_H * 2 + 2)
MK.v1 = SR(pMythic, afY - ROW_H * 2 - 8)
MK.v2 = SR(pMythic, afY - ROW_H * 3 - 8)
MK.v3 = SR(pMythic, afY - ROW_H * 4 - 8)

-- Weekly Progress panel
local WK = {}
WK.del    = SR(pWeekly, startY)
WK.delBar, WK.delBW = Bar(pWeekly, startY - ROW_H + 2, 0, 0.67, 0.27)

WK.dung   = SR(pWeekly, startY - ROW_H - BAR_H - 4)
WK.dungBar, WK.dungBW = Bar(pWeekly, startY - ROW_H * 2 - BAR_H + 2, 0.8, 0.73, 0)  -- [FIX-6] was _

WK.raid   = SR(pWeekly, startY - ROW_H * 2 - BAR_H * 2 - 4)
WK.raidBar, WK.raidBW = Bar(pWeekly, startY - ROW_H * 3 - BAR_H * 2, 0.53, 0.20, 0.8)  -- [FIX-6] was _

Div(pWeekly, startY - ROW_H * 3 - BAR_H * 2 - 10)
WK.reset = SR(pWeekly, startY - ROW_H * 3 - BAR_H * 2 - 20)

-- World Vault 3×3 grid (Raid/M+/World × Slot 1/2/3)
do
    local vaultDivY = startY - ROW_H * 4 - BAR_H * 2 - 20
    Div(pWeekly, vaultDivY + 8)
    local vHdr = SFS(pWeekly, vaultDivY)
    vHdr:SetText(Dim("── World Vault  (Raid · M+ · World  ×  Slot 1 · 2 · 3) ──"))

    local ROW_TYPES = {
        { label="Raid",  r=0.53, g=0.20, b=0.80, lockR=0.18, lockG=0.08, lockB=0.28 },
        { label="M+",    r=0.85, g=0.55, b=0.00, lockR=0.22, lockG=0.15, lockB=0.03 },
        { label="World", r=0.10, g=0.67, b=0.90, lockR=0.04, lockG=0.18, lockB=0.28 },
    }
    local LBYW = 28; local CGAP = 4; local RGAP = 5; local CH = 32
    local CW   = math.floor((PANELW - PAD * 2 - LBYW - CGAP * 2) / 3)
    local GRID = {}

    for ri = 1, 3 do
        local ry = vaultDivY - ROW_H - 4 - (ri - 1) * (CH + RGAP)
        local rt = ROW_TYPES[ri]

        local lbl = pWeekly:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\2002.ttf", 9, "OUTLINE")
        lbl:SetPoint("TOPLEFT", pWeekly, "TOPLEFT", PAD, ry)
        lbl:SetSize(LBYW, CH); lbl:SetJustifyH("LEFT"); lbl:SetJustifyV("TOP")
        lbl:SetTextColor(rt.r, rt.g, rt.b, 0.75); lbl:SetText(rt.label)

        GRID[ri] = {}
        for si = 1, 3 do
            local cx = PAD + LBYW + CGAP + (si - 1) * (CW + CGAP)
            local vc = CreateFrame("Frame", nil, pWeekly, "BackdropTemplate")
            vc:SetSize(CW, CH)
            vc:SetPoint("TOPLEFT", pWeekly, "TOPLEFT", cx, ry)
            vc:SetBackdrop({
                bgFile="Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1,
            })
            vc:SetBackdropColor(0.02, 0.03, 0.09, 1)
            vc:SetBackdropBorderColor(rt.lockR, rt.lockG, rt.lockB, 0.5)

            local snFS = vc:CreateFontString(nil, "OVERLAY")
            snFS:SetFont("Fonts\\2002.ttf", 7, "")
            snFS:SetPoint("BOTTOMRIGHT", vc, "BOTTOMRIGHT", -3, 2)
            snFS:SetTextColor(0.25, 0.30, 0.42, 1); snFS:SetText(tostring(si))

            local mainFS = vc:CreateFontString(nil, "OVERLAY")
            mainFS:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
            mainFS:SetPoint("TOP", vc, "TOP", 0, -3)
            mainFS:SetWidth(CW - 6); mainFS:SetJustifyH("CENTER")
            mainFS:SetText(Dim("--"))

            local subFS = vc:CreateFontString(nil, "OVERLAY")
            subFS:SetFont("Fonts\\2002.ttf", 8, "")
            subFS:SetPoint("BOTTOMLEFT", vc, "BOTTOMLEFT", 3, 2)
            subFS:SetWidth(CW - 14); subFS:SetJustifyH("LEFT")
            subFS:SetText(Dim("locked")); subFS:SetTextColor(0.22, 0.28, 0.40, 1)

            GRID[ri][si] = { frame=vc, mainFS=mainFS, subFS=subFS, rt=rt }
        end
    end
    WK.vaultGrid = GRID
end

-- ================================================================
--  [FIX-SCROLL] Currency panel — ScrollFrame wrapper
--  Problem: CUR_DISPLAY contains ~13 currencies × 28 px + 3 dividers
--  × 10 px ≈ 394 px of content inside a WEEKLY_H = 300 px panel.
--  Without a scroll frame the bottom rows (Conquest, Honor) are
--  fully hidden and cannot be seen or scrolled to.
--  Fix: wrap all currency rows in UIPanelScrollFrameTemplate so the
--  built-in scrollbar appears and all rows are reachable.
-- ================================================================
local CY_ROWS = {}
do
    -- Scroll frame fills the area below the panel title
    local curScroll = CreateFrame("ScrollFrame",
        "DT_CurScroll", pCurrency, "UIPanelScrollFrameTemplate")
    curScroll:SetPoint("TOPLEFT",
        pCurrency, "TOPLEFT", 0, -(PAD + ROW_H + 4))
    curScroll:SetPoint("BOTTOMRIGHT",
        pCurrency, "BOTTOMRIGHT", -(SCROLLBAR_W + 4), PAD)

    -- Mouse-wheel support: 28 px per tick = one currency row
    curScroll:EnableMouseWheel(true)
    curScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local mx  = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * 28)))
    end)

    -- Content frame: width accounts for the scrollbar column
    local curContent = CreateFrame("Frame", nil, curScroll)
    curContent:SetWidth(PANELW - SCROLLBAR_W - PAD)
    curScroll:SetScrollChild(curContent)

    -- Pre-calculate total content height so the scroll range is correct
    local totalCurH = 0
    for _, cdef in ipairs(CUR_DISPLAY) do
        totalCurH = totalCurH + (cdef == nil and 10 or 28)
    end
    curContent:SetHeight(totalCurH + 8)

    -- Build rows inside the content frame.
    -- curY is a positive offset from the top of curContent;
    -- MakeCurrencyRow expects a negative y (TOPLEFT anchor), so pass -curY.
    local curY = 0
    for _, cdef in ipairs(CUR_DISPLAY) do
        if cdef == nil then
            -- Divider line drawn directly on curContent
            local d = curContent:CreateTexture(nil, "BACKGROUND")
            d:SetHeight(1)
            d:SetPoint("TOPLEFT",  curContent, "TOPLEFT",  PAD, -(curY + 5))
            d:SetPoint("TOPRIGHT", curContent, "TOPRIGHT", -PAD, -(curY + 5))
            d:SetColorTexture(0.08, 0.15, 0.30, 1)
            curY = curY + 10
        else
            local val = MakeCurrencyRow(
                curContent, -curY,
                cdef[1], cdef[2], cdef[3], cdef[4], cdef[5])
            CY_ROWS[#CY_ROWS + 1] = { id = cdef[1], val = val }
            curY = curY + 28
        end
    end
end

-- ================================================================
--  TAB 2: GEAR
-- ================================================================
local GR        = tabFrames[2]
local gearPanel = MakePanel(GR, 0, 0, FW - 8, FH - 70 - 44)
PanelTitle(gearPanel,
    Blue("Equipment") ..
    Dim("  —  hover = tooltip · dots = gems · border = quality"))

-- [ADD-6 v8.1] Spec priority strip (do..end = no new top-level locals)
do
    local STRIP_H = 36
    local sp = CreateFrame("Frame", nil, gearPanel, "BackdropTemplate")
    sp:SetPoint("BOTTOMLEFT",  gearPanel, "BOTTOMLEFT",  1, STRIP_H + 2)
    sp:SetPoint("BOTTOMRIGHT", gearPanel, "BOTTOMRIGHT", -1, 2)
    sp:SetHeight(STRIP_H)
    sp:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    sp:SetBackdropColor(0.02, 0.04, 0.14, 1)
    sp:SetBackdropBorderColor(0.10, 0.20, 0.42, 0.7)
    _G81.spFS = sp:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    _G81.spFS:SetPoint("LEFT", sp, "LEFT", 10, 0)
    _G81.spFS:SetWidth(220)
    _G81.spFS:SetText("|cff4a6a9a(Loading spec...)|r")
    for i = 1, 4 do
        local p = sp:CreateFontString(nil, "OVERLAY")
        p:SetFont("Fonts\\2002.ttf", 10, "OUTLINE")
        p:SetPoint("LEFT", sp, "LEFT", 230 + (i-1)*76, 0)
        p:SetWidth(74); p:SetJustifyH("LEFT")
        p:SetTextColor(0.29, 0.42, 0.6, 1)
        _G81.prioPills[i] = p
    end
    local note = sp:CreateFontString(nil, "OVERLAY")
    note:SetFont("Fonts\\2002.ttf", 8, "")
    note:SetPoint("RIGHT", sp, "RIGHT", -8, 0)
    note:SetTextColor(0.2, 0.3, 0.5, 1)
    note:SetText("Sim at Raidbots for precise weights")
end

local gearSlotBtns = {}
local smryY = -(SLOT_SIZE * 2 + 24 * 2 + PAD + ROW_H + SLOT_PAD + 10)

local gearDetailH = 102
local gearDetail  = MakePanel(GR, 0, smryY - gearDetailH - 4, math.floor((FW-8-8)/2), gearDetailH)
local GD = {}
GD.title = gearDetail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
GD.title:SetPoint("TOPLEFT", gearDetail, "TOPLEFT", PAD, -PAD)
GD.title:SetText(Dim("← hover a slot for details"))

local gDW = math.floor((math.floor((FW-8-8)/2) - 28) / 2)  -- 2-col layout in halfW
GD.ilvl    = FS(gearDetail, -(PAD + ROW_H + 2), gDW)
GD.enchant = FS(gearDetail, -(PAD + ROW_H + 2), gDW + 10)
GD.enchant:SetPoint("TOPLEFT", gearDetail, "TOPLEFT",
    PAD + gDW + 8, -(PAD + ROW_H + 2))
GD.gem1  = FS(gearDetail, -(PAD + ROW_H * 2 + 2), gDW)
GD.gem2  = FS(gearDetail, -(PAD + ROW_H * 2 + 2), gDW)
GD.gem2:SetPoint("TOPLEFT", gearDetail, "TOPLEFT",
    PAD + gDW + 8, -(PAD + ROW_H * 2 + 2))
GD.stat1 = FS(gearDetail, -(PAD + ROW_H + 2), gDW)
GD.stat1:SetPoint("TOPLEFT", gearDetail, "TOPLEFT",
    PAD + (gDW + 8) * 2, -(PAD + ROW_H + 2))
GD.stat2 = FS(gearDetail, -(PAD + ROW_H * 2 + 2), gDW)
GD.stat2:SetPoint("TOPLEFT", gearDetail, "TOPLEFT",
    PAD + (gDW + 8) * 2, -(PAD + ROW_H * 2 + 2))
-- GD.stat3/stat4 removed: no room in half-width gearDetail panel (v8.1)

-- UpdateGearDetail: fills stat lines when hovering a gear slot
local function UpdateGearDetail(slotID, slotName)
    local link = GetInventoryItemLink("player", slotID)
    local name, _, quality, ilvl, _, _, subType = GetItemInfo(link or "")
    if not name then
        GD.title:SetText(Dim(slotName .. "  — empty"))
        GD.ilvl:SetText(""); GD.enchant:SetText("")
        GD.gem1:SetText(""); GD.gem2:SetText("")
        GD.stat1:SetText(""); GD.stat2:SetText("")
        return
    end

    local qc = QC(quality or 0)
    GD.title:SetText(Dim(slotName .. "  ·  ") .. CC(qc, name))
    GD.ilvl:SetText(
        Dim("ilvl: ") .. CC(qc, tostring(ilvl or "?")) ..
        "  " .. Dim(subType or ""))

    -- [FIX-10 v8.1] _G81.ENCH_SLOTS_12 replaces old enchSlots
    local enchID, gems = ParseLink(link)

    if enchID then
        GD.enchant:SetText(
            Green("✦ ") ..
            (ENCHANT_NAMES[enchID] or Dim("ID:") .. Yellow(tostring(enchID))))
    elseif _G81.ENCH_SLOTS_12[slotID] then
        GD.enchant:SetText(Red("X No enchant!"))
    elseif _G81.LEG_SLOTS[slotID] then
        GD.enchant:SetText(Dim("via Tailoring / LW kit"))
    else
        GD.enchant:SetText(Dim("—"))
    end

    GD.gem1:SetText(gems[1] and
        Purple("◆ ") .. (GetItemInfo(gems[1]) or "?") or Dim("No gems"))
    GD.gem2:SetText(gems[2] and
        Purple("◆ ") .. (GetItemInfo(gems[2]) or "?") or "")

    local stats = {}
    _W12.GetItemStats(link, stats)
    local SNAMES = {
        ITEM_MOD_HASTE_RATING_SHORT="Haste",
        ITEM_MOD_CRIT_RATING_SHORT="Crit",
        ITEM_MOD_MASTERY_RATING_SHORT="Mastery",
        ITEM_MOD_VERSATILITY="Vers",
        ITEM_MOD_STAMINA_SHORT="Stam",
        ITEM_MOD_INTELLECT_SHORT="Int",
        ITEM_MOD_STRENGTH_SHORT="Str",
        ITEM_MOD_AGILITY_SHORT="Agi",
    }
    local sd = {}
    for k, v in pairs(stats) do
        local n = SNAMES[k] or k:match("ITEM_MOD_(%a+)") or k
        sd[#sd + 1] = { n, Abbrev(v) }
    end
    table.sort(sd, function(a, b) return a[1] < b[1] end)
    -- stat3/stat4 removed (no room in halfW) — show top 2 stats only
    local sl = { GD.stat1, GD.stat2 }
    for i = 1, 2 do
        sl[i]:SetText(sd[i] and Dim(sd[i][1] .. ": ") .. Yellow(sd[i][2]) or "")
    end
end

-- Gear summary panel
local gearSummary = MakePanel(GR, 0, smryY, math.floor((FW-8-8)/2), 90) -- [v8.1] left half only
PanelTitle(gearSummary,
    Dim("Summary  ·  ") .. Green("✦ Enchants") ..
    Dim("  &  ") .. Purple("◆ Gems"))

local smryW = math.floor((math.floor((FW-8-8)/2) - 28) / 3)  -- [v8.1] fits left-half panel
local GS    = {}
GS.enchMiss = FS(gearSummary, -(PAD + ROW_H), smryW)
GS.gemMiss  = FS(gearSummary, -(PAD + ROW_H), smryW)
GS.gemMiss:SetPoint("TOPLEFT", gearSummary, "TOPLEFT",
    PAD + smryW + 10, -(PAD + ROW_H))
GS.gemBonus = FS(gearSummary, -(PAD + ROW_H), smryW)
GS.gemBonus:SetPoint("TOPLEFT", gearSummary, "TOPLEFT",
    PAD + (smryW + 10) * 2, -(PAD + ROW_H))
GS.detail = FS(gearSummary, -(PAD + ROW_H * 2 + 4), math.floor((FW-8-8)/2) - PAD * 2)

-- [v8.1 FIXED] Recommendation panel — single multi-line FontString, reliable
do
    local recH   = 230
    local recW   = math.floor((FW - 8 - 8) / 2)
    local rp     = MakePanel(GR, recW + 12, smryY, recW - 4, recH)
    PanelTitle(rp, "|cff4dc8ffEnchant & Gem Recommendations|r")

    -- Single FontString for all slot rows (multi-line, reliable)
    _G81.recLabel = rp:CreateFontString(nil, "OVERLAY")
    _G81.recLabel:SetFont("Fonts\\2002.ttf", 9, "")
    _G81.recLabel:SetPoint("TOPLEFT",  rp, "TOPLEFT",  10, -(14 + 20))
    _G81.recLabel:SetPoint("TOPRIGHT", rp, "TOPRIGHT", -6, -(14 + 20))
    _G81.recLabel:SetJustifyH("LEFT")
    _G81.recLabel:SetJustifyV("TOP")
    _G81.recLabel:SetSpacing(4)
    _G81.recLabel:SetText("|cff4a6a9aLoading...|r")

    -- Gem row FontStrings
    _G81.REC.gem1 = rp:CreateFontString(nil, "OVERLAY")
    _G81.REC.gem1:SetFont("Fonts\\2002.ttf", 9, "")
    _G81.REC.gem1:SetPoint("BOTTOMLEFT", rp, "BOTTOMLEFT", 10, 36)
    _G81.REC.gem1:SetWidth(recW - 16)
    _G81.REC.gem1:SetJustifyH("LEFT")

    _G81.REC.gem2 = rp:CreateFontString(nil, "OVERLAY")
    _G81.REC.gem2:SetFont("Fonts\\2002.ttf", 9, "")
    _G81.REC.gem2:SetPoint("BOTTOMLEFT", rp, "BOTTOMLEFT", 10, 20)
    _G81.REC.gem2:SetWidth(recW - 16)
    _G81.REC.gem2:SetJustifyH("LEFT")

    _G81.REC.disc = rp:CreateFontString(nil, "OVERLAY")
    _G81.REC.disc:SetFont("Fonts\\2002.ttf", 8, "")
    _G81.REC.disc:SetPoint("BOTTOMLEFT", rp, "BOTTOMLEFT", 10, 6)
    _G81.REC.disc:SetWidth(recW - 16)
    _G81.REC.disc:SetJustifyH("LEFT")
    _G81.REC.disc:SetTextColor(0.2, 0.3, 0.5, 1)
    _G81.REC.disc:SetText("* Legs: Tailoring / LW kit  |  Sim: Raidbots")
end

-- Build 16 gear slot buttons in a 8×2 grid
for row = 0, 1 do
    for col = 0, 7 do
        local idx     = row * 8 + col + 1
        local sdef    = GEAR_SLOTS_DEF[idx]
        if not sdef then break end

        local slotID      = sdef[1]
        local slotNameIdx = sdef[2]
        local slotName    = (L.SLOT_NAMES and L.SLOT_NAMES[slotNameIdx]) or "Slot"

        local btn = CreateFrame("Button", nil, gearPanel)
        btn:SetSize(SLOT_SIZE, SLOT_SIZE)
        btn:SetPoint("TOPLEFT", gearPanel, "TOPLEFT",
            PAD + col * (SLOT_SIZE + SLOT_PAD),
            -(PAD + ROW_H + row * (SLOT_SIZE + 26)))

        local sbg = btn:CreateTexture(nil, "BACKGROUND")
        sbg:SetAllPoints(); sbg:SetColorTexture(0.04, 0.07, 0.16, 1)

        local sbd = btn:CreateTexture(nil, "BORDER")
        sbd:SetPoint("TOPLEFT", -1, 1); sbd:SetPoint("BOTTOMRIGHT", 1, -1)
        sbd:SetColorTexture(0.10, 0.20, 0.42, 0.8)

        local stex = btn:CreateTexture(nil, "ARTWORK")
        stex:SetAllPoints()

        local ilvlFS = btn:CreateFontString(nil, "OVERLAY")
        ilvlFS:SetFont("Fonts\\2002.ttf", 10, "OUTLINE")
        ilvlFS:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)

        local nameFS = gearPanel:CreateFontString(nil, "OVERLAY")
        nameFS:SetFont("Fonts\\2002.ttf", 9, "")
        nameFS:SetPoint("TOP", btn, "BOTTOM", 0, -2)
        nameFS:SetText(Dim(slotName))
        nameFS:SetWidth(SLOT_SIZE + 4)
        nameFS:SetJustifyH("CENTER")

        -- Enchant indicator dot (top-left)
        local enchDot = btn:CreateTexture(nil, "OVERLAY")
        enchDot:SetSize(7, 7)
        enchDot:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        enchDot:SetColorTexture(0.1, 0.1, 0.1, 0)

        -- Up to 3 gem indicator dots (bottom row)
        local gemDots = {}
        for g = 1, 3 do
            local gd = btn:CreateTexture(nil, "OVERLAY")
            gd:SetSize(7, 7)
            gd:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2 + (g - 1) * 10, 2)
            gd:SetColorTexture(0.1, 0.1, 0.1, 0)
            gemDots[g] = gd
        end

        btn.slotID   = slotID
        btn.tex      = stex
        btn.ilvlFS   = ilvlFS
        btn.gemDots  = gemDots
        btn.kader    = sbd
        btn.enchDot  = enchDot
        btn.slotName = slotName

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetInventoryItem("player", self.slotID)
            GameTooltip:Show()
            self.kader:SetColorTexture(0.3, 0.78, 1, 1)
            UpdateGearDetail(self.slotID, self.slotName)
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self.kader:SetColorTexture(0.10, 0.20, 0.42, 0.8)
        end)

        gearSlotBtns[slotID] = btn
    end
end

-- ================================================================
--  TAB 3: PVP
--  [FIX-7] startY is an upvalue from the outer scope (line ~424).
--          Documented explicitly here to avoid confusion.
-- ================================================================
local pvpPanels  = {}
local pvpLines   = {}
local ssRounds
local pvpLifetime
local pvpBGLines, pvpAMLines = {}, {}
local PT, PT2, PT3, PS
local pvpInst, pvpTot

do  -- PvP layout block (auto-releases internal locals on exit)
    local PV_OUTER = tabFrames[3]
    local pvScroll = CreateFrame(
        "ScrollFrame", "DT_PvpScroll", PV_OUTER, "UIPanelScrollFrameTemplate")
    pvScroll:SetPoint("TOPLEFT",     PV_OUTER, "TOPLEFT",     0, 0)
    pvScroll:SetPoint("BOTTOMRIGHT", PV_OUTER, "BOTTOMRIGHT", -20, 0)

    local PV = CreateFrame("Frame", nil, pvScroll)
    PV:SetSize(FW - 30, 860)
    pvScroll:SetScrollChild(PV)

    PV_OUTER:EnableMouseWheel(true)
    PV_OUTER:SetScript("OnMouseWheel", function(self, delta)
        local cur = pvScroll:GetVerticalScroll()
        local mx  = pvScroll:GetVerticalScrollRange()
        pvScroll:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * 50)))
    end)

    local pvW    = FW - 30
    local pvpH   = 180   -- was 150; 6 rows × ROW_H(22) + startY(42) = 174 → 180 with margin
    local pvpBW  = math.floor((pvW - PGAP * 2) / 3)

    -- Section 1: Rated bracket panels (3 across top)
    for i = 1, 3 do
        local p = MakePanel(PV, (i - 1) * (pvpBW + PGAP), 0, pvpBW, pvpH)
        pvpPanels[i] = p
        pvpLines[i] = {
            rating  = FS(p, startY,              pvpBW - PAD * 2),
            wl      = FS(p, startY - ROW_H,      pvpBW - PAD * 2),
            winpct  = FS(p, startY - ROW_H * 2,  pvpBW - PAD * 2),
            weekwl  = FS(p, startY - ROW_H * 3,  pvpBW - PAD * 2),
            highest = FS(p, startY - ROW_H * 4,  pvpBW - PAD * 2),
            tier    = FS(p, startY - ROW_H * 5,  pvpBW - PAD * 2),
        }
    end

    -- Solo Shuffle + Rated BG side by side (row 2)
    local pvpBW2 = math.floor((pvW - PGAP) / 2)
    for i = 4, 5 do
        local xi = (i - 4) * (pvpBW2 + PGAP)
        local p  = MakePanel(PV, xi, -(pvpH + PGAP), pvpBW2, pvpH)
        pvpPanels[i] = p
        pvpLines[i] = {
            rating  = FS(p, startY,              pvpBW2 - PAD * 2),
            wl      = FS(p, startY - ROW_H,      pvpBW2 - PAD * 2),
            winpct  = FS(p, startY - ROW_H * 2,  pvpBW2 - PAD * 2),
            weekwl  = FS(p, startY - ROW_H * 3,  pvpBW2 - PAD * 2),
            highest = FS(p, startY - ROW_H * 4,  pvpBW2 - PAD * 2),
            tier    = FS(p, startY - ROW_H * 5,  pvpBW2 - PAD * 2),
        }
    end
    ssRounds = FS(pvpPanels[4], startY - ROW_H * 6, pvpBW2 - PAD * 2)

    -- Section 2: Lifetime Stats + Status cards
    local pvSec2Y = -(pvpH * 2 + PGAP * 2 + PGAP)
    pvpLifetime   = MakePanel(PV, 0, pvSec2Y, pvW, 125)

    do  -- Stat cards
        local lW   = math.floor((pvW - PAD * 2 - PGAP * 3) / 4)
        local LT   = {}
        local lbls = { "Lifetime HK","Dishon. Kills","Session KB","Honor Earned" }
        local cols = { "ff5544","4a6890","ff9922","66aaff" }

        for i = 1, 4 do
            local x    = PAD + (i - 1) * (lW + PGAP)
            local card = pvpLifetime:CreateTexture(nil, "BACKGROUND")
            card:SetSize(lW, 58)
            card:SetPoint("TOPLEFT", pvpLifetime, "TOPLEFT", x, -(PAD + ROW_H))
            card:SetColorTexture(0.03, 0.06, 0.14, 1)

            LT[i] = {
                num = pvpLifetime:CreateFontString(nil, "OVERLAY"),
                lbl = pvpLifetime:CreateFontString(nil, "OVERLAY"),
            }
            LT[i].num:SetFont("Fonts\\2002.ttf", 18, "OUTLINE")
            LT[i].num:SetPoint("TOPLEFT", pvpLifetime, "TOPLEFT",
                x + 6, -(PAD + ROW_H + 4))
            LT[i].num:SetWidth(lW - 10)
            local rr = tonumber("0x" .. cols[i]:sub(1,2)) / 255
            local rg = tonumber("0x" .. cols[i]:sub(3,4)) / 255
            local rb = tonumber("0x" .. cols[i]:sub(5,6)) / 255
            LT[i].num:SetTextColor(rr, rg, rb, 1)

            LT[i].lbl:SetFont("Fonts\\2002.ttf", 9, "")
            LT[i].lbl:SetPoint("BOTTOMLEFT", pvpLifetime, "TOPLEFT",
                x + 6, -(PAD + ROW_H + 62))
            LT[i].lbl:SetWidth(lW - 10)
            LT[i].lbl:SetTextColor(0.29, 0.42, 0.6, 1)
            LT[i].lbl:SetText(lbls[i])
        end
        pvpLifetime.LT = LT
    end

    local psY  = -(PAD + ROW_H + 72)
    local psW  = math.floor((pvW - PAD * 2) / 4)
    PS = {}
    PS.hlvl  = FS(pvpLifetime, psY, psW)
    PS.wm    = FS(pvpLifetime, psY, psW)
    PS.wm:SetPoint("TOPLEFT", pvpLifetime, "TOPLEFT", PAD + psW, psY)
    PS.title = FS(pvpLifetime, psY, psW * 2)
    PS.title:SetPoint("TOPLEFT", pvpLifetime, "TOPLEFT", PAD + psW * 2, psY)

    -- Section 3: Unrated map tracking (two columns)
    local pvSec3Y   = pvSec2Y - 133   -- was -128; lifetime h=125 + PGAP=8
    pvpInst         = MakePanel(PV, 0, pvSec3Y, pvW, 218)
    local instColW  = math.floor((pvW - PAD * 3) / 2)

    local bgHdr = pvpInst:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bgHdr:SetPoint("TOPLEFT", pvpInst, "TOPLEFT", PAD, -PAD + 2)
    bgHdr:SetText(Green("Battlegrounds & Training Grounds"))

    local amHdr = pvpInst:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    amHdr:SetPoint("TOPLEFT", pvpInst, "TOPLEFT", PAD + instColW + PAD, -PAD + 2)
    amHdr:SetText(Teal("Arena Maps & Decor Duels"))

    local colDiv = pvpInst:CreateTexture(nil, "BACKGROUND")
    colDiv:SetWidth(1)
    colDiv:SetPoint("TOPLEFT",    pvpInst, "TOPLEFT",
        PAD + instColW + math.floor(PAD / 2), -PAD)
    colDiv:SetPoint("BOTTOMLEFT", pvpInst, "BOTTOMLEFT",
        PAD + instColW + math.floor(PAD / 2), PAD)
    colDiv:SetColorTexture(0.10, 0.20, 0.40, 0.5)

    for i = 1, 8 do
        local ly = -(PAD + ROW_H + 4 + (i - 1) * ROW_H)
        pvpBGLines[i] = FS(pvpInst, ly, instColW)
        pvpAMLines[i] = FS(pvpInst, ly, instColW)
        pvpAMLines[i]:SetPoint("TOPLEFT", pvpInst, "TOPLEFT",
            PAD + instColW + PAD, ly)
    end

    -- Section 4: Season Totals
    local pvSec4Y = pvSec3Y - 226
    pvpTot        = MakePanel(PV, 0, pvSec4Y, pvW, 100)  -- was 90
    local totW    = math.floor((pvW - PAD * 2) / 4)

    PT = {
        kills  = FS(pvpTot, startY, totW),
        deaths = FS(pvpTot, startY, totW),
        kd     = FS(pvpTot, startY, totW),
        honor  = FS(pvpTot, startY, totW),
    }
    PT.deaths:SetPoint("TOPLEFT", pvpTot, "TOPLEFT", PAD + totW,     startY)
    PT.kd:SetPoint(    "TOPLEFT", pvpTot, "TOPLEFT", PAD + totW * 2, startY)
    PT.honor:SetPoint( "TOPLEFT", pvpTot, "TOPLEFT", PAD + totW * 3, startY)

    PT2 = {
        bgGames  = FS(pvpTot, startY - ROW_H, totW),
        bgWins   = FS(pvpTot, startY - ROW_H, totW),
        bgWinPct = FS(pvpTot, startY - ROW_H, totW),
        bgKB     = FS(pvpTot, startY - ROW_H, totW),
    }
    PT2.bgWins:SetPoint(  "TOPLEFT", pvpTot, "TOPLEFT", PAD + totW,     startY - ROW_H)
    PT2.bgWinPct:SetPoint("TOPLEFT", pvpTot, "TOPLEFT", PAD + totW * 2, startY - ROW_H)
    PT2.bgKB:SetPoint(    "TOPLEFT", pvpTot, "TOPLEFT", PAD + totW * 3, startY - ROW_H)

    PT3 = {
        arGames  = FS(pvpTot, startY - ROW_H * 2, totW),
        arWins   = FS(pvpTot, startY - ROW_H * 2, totW),
        arWinPct = FS(pvpTot, startY - ROW_H * 2, totW),
        session  = FS(pvpTot, startY - ROW_H * 2, totW),
    }
    PT3.arWins:SetPoint(  "TOPLEFT", pvpTot, "TOPLEFT", PAD + totW,     startY - ROW_H * 2)
    PT3.arWinPct:SetPoint("TOPLEFT", pvpTot, "TOPLEFT", PAD + totW * 2, startY - ROW_H * 2)
    PT3.session:SetPoint( "TOPLEFT", pvpTot, "TOPLEFT", PAD + totW * 3, startY - ROW_H * 2)

    PV:SetHeight(math.abs(pvSec4Y) + 100)
end  -- End PvP layout block

-- ================================================================
--  TAB 4: WARBAND
--  [FIX-2] Scrollable character grid; [UPG-10] taller cards
-- ================================================================
local WBT = tabFrames[4]

local wbHdr = MakePanel(WBT, 0, 0, FW - 8, 58)
local WBH   = {
    btag  = FS(wbHdr, -PAD),
    realm = FS(wbHdr, -(PAD + ROW_H)),
    -- [FIX-SCROLL] Width guard: "Warband Level 99" ≈ 18 chars at
    -- GameFontHighlight ≈ 216 px. Clamped to 160 px (right-aligned)
    -- so long text truncates instead of overflowing past the left edge.
    wblvl = FS(wbHdr, -PAD, 160),
}
WBH.wblvl:SetPoint("TOPRIGHT", wbHdr, "TOPRIGHT", -PAD, -PAD)
WBH.wblvl:SetJustifyH("RIGHT")

local WB_CARD_H      = 46         -- [UPG-10] was 38
local WB_COLS        = 4
local WB_ROWS_VISIBLE = 3
local WB_STRIP_H     = WB_ROWS_VISIBLE * (WB_CARD_H + PGAP) + PAD + ROW_H + 4

-- [FIX-SCROLL] charW now accounts for SCROLLBAR_W so card text does
-- not run under the scrollbar thumb (was 237 px → now 232 px).
local charW = math.floor(
    (FW - 8 - PAD * 2 - SCROLLBAR_W - PGAP * (WB_COLS - 1)) / WB_COLS)

local wbCharsOuter = MakePanel(WBT, 0, -62, FW - 8, WB_STRIP_H)
PanelTitle(wbCharsOuter,
    Blue("Characters") ..
    Dim("  (auto-sync via DelveTrackerDB  ·  sorted by iLvl)"))

-- [FIX-SCROLL] Inner scroll frame — UIPanelScrollFrameTemplate gives
-- the user a visible, draggable scrollbar (previously invisible).
-- BOTTOMRIGHT offset = -(PAD + SCROLLBAR_W) to leave room for the bar.
local wbScroll = CreateFrame(
    "ScrollFrame", "DT_WbCharScroll", wbCharsOuter,
    "UIPanelScrollFrameTemplate")
wbScroll:SetPoint("TOPLEFT",     wbCharsOuter, "TOPLEFT",     PAD, -(PAD + ROW_H))
wbScroll:SetPoint("BOTTOMRIGHT", wbCharsOuter, "BOTTOMRIGHT", -(PAD + SCROLLBAR_W), PAD)

-- Content frame: height is set dynamically in RefreshWarband.
-- Width shrunk by SCROLLBAR_W to stay clear of the scrollbar.
local wbContent = CreateFrame("Frame", nil, wbScroll)
wbContent:SetWidth(FW - 8 - PAD * 2 - SCROLLBAR_W)
wbContent:SetHeight(WB_STRIP_H)
wbScroll:SetScrollChild(wbContent)
wbScroll:EnableMouseWheel(true)
wbScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll()
    local mx  = self:GetVerticalScrollRange()
    self:SetVerticalScroll(
        math.max(0, math.min(mx, cur - delta * (WB_CARD_H + PGAP))))
end)

-- Pre-allocate a pool of card frames (max 80 characters)
local WB_POOL_SIZE = 80
local wbPool = {}
for pi = 1, WB_POOL_SIZE do
    local col = (pi - 1) % WB_COLS
    local row = math.floor((pi - 1) / WB_COLS)
    local cf  = CreateFrame("Frame", nil, wbContent, "BackdropTemplate")
    cf:SetSize(charW, WB_CARD_H)
    cf:SetPoint("TOPLEFT", wbContent, "TOPLEFT",
        col * (charW + PGAP), -(row * (WB_CARD_H + PGAP)))
    cf:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    cf:SetBackdropColor(0.02, 0.04, 0.12, 1)
    cf:SetBackdropBorderColor(0.10, 0.20, 0.42, 0.7)

    -- [UPG-3] Both font strings use GameFontHighlight for better legibility
    cf.nameFS = cf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cf.nameFS:SetPoint("TOPLEFT", cf, "TOPLEFT", 4, -4)
    cf.nameFS:SetWidth(charW - 8); cf.nameFS:SetJustifyH("LEFT")

    cf.specFS = cf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cf.specFS:SetPoint("TOPLEFT", cf, "TOPLEFT", 4, -4 - ROW_H)
    cf.specFS:SetWidth(charW - 8); cf.specFS:SetJustifyH("LEFT")

    cf:Hide()
    wbPool[pi] = cf
end

-- Account Totals + Reputations (side by side)
local wbAccW  = math.floor((FW - 8 - PGAP) / 2)
local wbMidY  = -(62 + WB_STRIP_H + PGAP)
local wbAcc   = MakePanel(WBT, 0, wbMidY, wbAccW, 175)
PanelTitle(wbAcc, Gold("Account Totals"))
-- [FIX-SCROLL] ScrollFrame inside wbAcc — same pattern as wbRepScroll.
-- wbAccScroll/wbAccContent wrapped in do..end: saves 3 main-chunk locals
-- (Lua 5.1 hard limit = 200 per chunk).
local WA = {}
do
    local wbAccScroll = CreateFrame(
        "ScrollFrame", "DT_WbAccScroll", wbAcc, "UIPanelScrollFrameTemplate")
    wbAccScroll:SetPoint("TOPLEFT",     wbAcc, "TOPLEFT",     0, -(14 + 20))
    wbAccScroll:SetPoint("BOTTOMRIGHT", wbAcc, "BOTTOMRIGHT", -(SCROLLBAR_W + 4), 6)
    wbAccScroll:EnableMouseWheel(true)
    wbAccScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local mx  = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * ROW_H)))
    end)
    local wbAccContent  = CreateFrame("Frame", nil, wbAccScroll)
    local wbAccContentW = wbAccW - 8 - SCROLLBAR_W
    wbAccContent:SetSize(wbAccContentW, 7 * ROW_H + 4)
    wbAccScroll:SetScrollChild(wbAccContent)
    WA.wbgold  = FS(wbAccContent, startY,              wbAccContentW - PAD)
    WA.achiev  = FS(wbAccContent, startY - ROW_H,      wbAccContentW - PAD)
    WA.pets    = FS(wbAccContent, startY - ROW_H * 2,  wbAccContentW - PAD)
    WA.mounts  = FS(wbAccContent, startY - ROW_H * 3,  wbAccContentW - PAD)
    WA.toys    = FS(wbAccContent, startY - ROW_H * 4,  wbAccContentW - PAD)
    WA.dundun  = FS(wbAccContent, startY - ROW_H * 5,  wbAccContentW - PAD)
    WA.manaflux= FS(wbAccContent, startY - ROW_H * 6,  wbAccContentW - PAD)
end

local wbRep     = MakePanel(WBT, wbAccW + PGAP, wbMidY, FW - 8 - wbAccW - PGAP, 175)
-- [FIX-SCROLL] ScrollFrame inside wbRep — add UIPanelScrollFrameTemplate
-- so the scrollbar is visible when the reputation list is longer than
-- the visible area. BOTTOMRIGHT is inset -(SCROLLBAR_W+4) on the right
-- so the scrollbar sits inside the panel border cleanly.
local wbRepScroll = CreateFrame(
    "ScrollFrame", "DT_WbRepScroll", wbRep, "UIPanelScrollFrameTemplate")
wbRepScroll:SetPoint("TOPLEFT",     wbRep, "TOPLEFT",     0, -(14 + 20))
wbRepScroll:SetPoint("BOTTOMRIGHT", wbRep, "BOTTOMRIGHT", -(SCROLLBAR_W + 4), 6)
-- Mouse-wheel: 17 px per tick = one rep line
wbRepScroll:EnableMouseWheel(true)
wbRepScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll()
    local mx  = self:GetVerticalScrollRange()
    self:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * 17)))
end)
-- [FIX-SCROLL] Content width shrunk by SCROLLBAR_W so text does not
-- run under the scrollbar thumb (was FW-8-wbAccW-PGAP-8).
local wbRepContent = CreateFrame("Frame", nil, wbRepScroll)
wbRepContent:SetSize(FW - 8 - wbAccW - PGAP - 8 - SCROLLBAR_W, 1)
wbRepScroll:SetScrollChild(wbRepContent)
PanelTitle(wbRep, Purple("Midnight Reputations") .. Dim(" (warband)"))
-- [v8.1] rep lines inside scrollable content frame — 12 rows × 18px
local repLines = {}
-- [FIX-SCROLL] repW reduced by SCROLLBAR_W to prevent text clipping
local repW = FW - 8 - wbAccW - PGAP - 12 - SCROLLBAR_W
for i = 1, 12 do
    local rl = wbRepContent:CreateFontString(nil, "OVERLAY")
    rl:SetFont("Fonts\\2002.ttf", 13, "")
    rl:SetPoint("TOPLEFT", wbRepContent, "TOPLEFT", 4, -(i-1)*18)
    rl:SetWidth(repW)
    rl:SetJustifyH("LEFT")
    repLines[i] = rl
end
-- Set content height to fit all lines
wbRepContent:SetHeight(12 * 18 + 4)

-- Weekly Overview (full width, below account panels)
local wbWeek = MakePanel(WBT, 0, wbMidY - 183, FW - 8, 105)
PanelTitle(wbWeek, Teal("Weekly Overview — All Characters"))
local wwW = math.floor((FW - PAD * 3) / 4)
local WW  = {
    del   = FS(wbWeek, startY, wwW),
    mplus = FS(wbWeek, startY, wwW),
    vault = FS(wbWeek, startY, wwW),
    chars = FS(wbWeek, startY, wwW),
}
WW.mplus:SetPoint("TOPLEFT", wbWeek, "TOPLEFT", PAD + wwW + 8, startY)
WW.vault:SetPoint("TOPLEFT", wbWeek, "TOPLEFT", PAD + (wwW + 8) * 2, startY)
WW.chars:SetPoint("TOPLEFT", wbWeek, "TOPLEFT", PAD + (wwW + 8) * 3, startY)

-- ================================================================
--  TAB 5: SEASON
--  [UPG-7] Season panel icons 22px → 33px (1.5×)
-- ================================================================
local SZ_OUTER = tabFrames[5]
local szScroll = CreateFrame(
    "ScrollFrame", "DT_SzScroll", SZ_OUTER, "UIPanelScrollFrameTemplate")
szScroll:SetPoint("TOPLEFT",     SZ_OUTER, "TOPLEFT",     0, 0)
szScroll:SetPoint("BOTTOMRIGHT", SZ_OUTER, "BOTTOMRIGHT", -20, 0)

local SZ = CreateFrame("Frame", nil, szScroll)
SZ:SetSize(FW - 30, 940)
szScroll:SetScrollChild(SZ)

SZ_OUTER:EnableMouseWheel(true)
SZ_OUTER:SetScript("OnMouseWheel", function(self, delta)
    local cur = szScroll:GetVerticalScroll()
    local mx  = szScroll:GetVerticalScrollRange()
    szScroll:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * 40)))
end)

local szW    = FW - 30
local PGAP_SZ = 8
local szPH   = { DJ=248, PR=238, RS=198, VF=95, SUM=90 }

-- Helper: create a season section panel with a coloured icon
-- [UPG-7] iconSize 22 → 33
local function MakeSeasonPanelWithIcon(parent, y, h,
        iconFileOrColor, titleText, titleColor)
    local p     = MakePanel(parent, 0, y, szW, h)
    local iconF = p:CreateTexture(nil, "ARTWORK")
    local iconSz = 33                              -- [UPG-7] was 22

    iconF:SetSize(iconSz, iconSz)
    iconF:SetPoint("TOPLEFT", p, "TOPLEFT", PAD, -PAD + 2)

    if type(iconFileOrColor) == "number" then
        iconF:SetTexture(iconFileOrColor)
    else
        iconF:SetColorTexture(
            iconFileOrColor[1], iconFileOrColor[2], iconFileOrColor[3], 0.7)
    end

    -- [UPG-4] Section title uses GameFontNormalLarge
    local t = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("LEFT", iconF, "RIGHT", 6, 0)
    t:SetText(CC(titleColor, titleText))

    local rankFS = p:CreateFontString(nil, "OVERLAY")
    rankFS:SetFont("Fonts\\2002.ttf", 12, "OUTLINE")
    rankFS:SetPoint("TOPRIGHT", p, "TOPRIGHT", -PAD, -PAD + 3)
    rankFS:SetTextColor(1, 1, 1, 0.5)

    p.rankFS = rankFS
    p.iconF  = iconF
    return p
end

local yOff = 0

local pDelve = MakeSeasonPanelWithIcon(SZ, yOff, szPH.DJ,
    {0.27,0.87,0.8}, "Delver's Journey — Season 1", "44ddcc")
yOff = yOff - szPH.DJ - PGAP_SZ

local pPrey = MakeSeasonPanelWithIcon(SZ, yOff, szPH.PR,
    {0.8,0.2,0.2}, "Prey: Season 1  ·  Faction 2764  ·  Remnant of Anguish (3392)", "ff5544")
yOff = yOff - szPH.PR - PGAP_SZ

local pRitual = MakeSeasonPanelWithIcon(SZ, yOff, szPH.RS,
    {0.53,0.2,0.8}, "Ritual Sites — 12.0.5  ·  Voidlight Marl (3316)", "cc88ff")
yOff = yOff - szPH.RS - PGAP_SZ

local pVoidforge = MakeSeasonPanelWithIcon(SZ, yOff, szPH.VF,
    {1.0,0.6,0.13}, "Voidforge — Patch 12.0.5  ·  Decimus", "ff9922")
yOff = yOff - szPH.VF - PGAP_SZ

local pSzSum = MakeSeasonPanelWithIcon(SZ, yOff, szPH.SUM,
    {0.3,0.5,0.8}, "World Vault — combined", "4dc8ff")
SZ:SetHeight(math.abs(yOff) + szPH.SUM + 20)

-- Delver's Journey content
SFS(pDelve, -(PAD + ROW_H + 2)):SetText(
    Dim("Season rank  ·  hover nodes for rewards"))
local _, updateDelveRank = BuildRankTrack(pDelve, PAD, -(PAD + ROW_H * 2 + 4), 10, {
    "Dirigible: Lantern Wing", "Dirigible: Exhaust",
    "Dirigible: Front Lantern", "Dirigible: Zeppelin",
    "Dirigible: Brown Paint",  "Toy: Trusty Hat",
    "3× Coffer Keys/week",     "Title: Spelunker",
    "Cosmetic: Delver armor set", "Mount: Bountiful Coffer Gyrocraft",
})
local DJ = {}
local djNodeBottom = -(PAD + ROW_H * 2 + NODE_W + 8)
DJ.xpLabel = FS(pDelve, djNodeBottom, szW - PAD * 2)
DJ.xpBar, DJ.xpBW = Bar(pDelve, djNodeBottom - ROW_H, 0, 0.67, 0.5)
Div(pDelve, djNodeBottom - ROW_H - BAR_H - 8)
local dOff = djNodeBottom - ROW_H - BAR_H - 20
SFS(pDelve, dOff):SetText(Dim("Weekly Bountiful Delves"))
DJ.weekly   = FS(pDelve, dOff - ROW_H + 2)
DJ.delBar, DJ.delBW = Bar(pDelve, dOff - ROW_H * 2 + 4, 0, 0.67, 0.27)
DJ.vault    = FS(pDelve, dOff - ROW_H * 2 - 4)
DJ.coffKeys = FS(pDelve, dOff - ROW_H * 3 - 4)
DJ.zekvir   = FS(pDelve, dOff - ROW_H * 4 - 4)
DJ.seasonXP = FS(pDelve, dOff - ROW_H * 5 - 4)

-- Prey section content
SFS(pPrey, -(PAD + ROW_H + 2)):SetText(
    Dim("Preyseeker's Journey  ·  hover nodes for rewards"))
local _, updatePreyRank = BuildRankTrack(
    pPrey, PAD, -(PAD + ROW_H * 2 + 4),
    SEASON.PREY_RANKS, SEASON.PREY_RANK_REWARDS)
local PR = {}
local prNodeBottom = -(PAD + ROW_H * 2 + NODE_W + 8)
PR.xpLabel = FS(pPrey, prNodeBottom, szW - PAD * 2)
PR.xpBar, PR.xpBW = Bar(pPrey, prNodeBottom - ROW_H, 0.8, 0.34, 0.1)
Div(pPrey, prNodeBottom - ROW_H - BAR_H - 8)

local prOff    = prNodeBottom - ROW_H - BAR_H - 20
local huntCircles = {}
for i = 1, 4 do
    local hc = CreateFrame("Frame", nil, pPrey, "BackdropTemplate")
    hc:SetSize(34, 34)
    hc:SetPoint("TOPLEFT", pPrey, "TOPLEFT", PAD + (i - 1) * 42, prOff - 4)
    hc:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    hc:SetBackdropColor(0.02, 0.03, 0.07, 1)
    hc:SetBackdropBorderColor(0.06, 0.10, 0.20, 0.8)
    hc.numFS = hc:CreateFontString(nil, "OVERLAY")
    hc.numFS:SetFont("Fonts\\2002.ttf", 11, "OUTLINE")
    hc.numFS:SetPoint("CENTER", hc, "CENTER", 0, 0)
    hc.numFS:SetText(Dim(tostring(i)))
    huntCircles[i] = hc
end

local pr2col = math.floor(szW / 2)
PR.huntLabel = FS(pPrey, prOff - 38, pr2col - PAD - 30, PAD + 4 * 42 + 8)
PR.extraHunt = FS(pPrey, prOff - 38 - ROW_H, pr2col - PAD - 30, PAD + 4 * 42 + 8)
PR.diffNorm  = FS(pPrey, prOff - 4, pr2col, pr2col)
PR.diffHard  = FS(pPrey, prOff - 4 - ROW_H, pr2col, pr2col)
PR.diffNM    = FS(pPrey, prOff - 4 - ROW_H * 2, pr2col, pr2col)
PR.currency  = FS(pPrey, prOff - 4 - ROW_H * 3, pr2col, pr2col)

-- Ritual Sites section content
SFS(pRitual, -(PAD + ROW_H + 2)):SetText(
    Dim("Renown Track (8 ranks)  ·  hover nodes for rewards"))
local _, updateRitualRank = BuildRankTrack(
    pRitual, PAD, -(PAD + ROW_H * 2 + 4),
    SEASON.RITUAL_RANKS, SEASON.RITUAL_RANK_REWARDS)
local RS = {}
local rsNodeBottom = -(PAD + ROW_H * 2 + NODE_W + 8)
RS.xpLabel = FS(pRitual, rsNodeBottom, szW - PAD * 2)
RS.xpBar, RS.xpBW = Bar(pRitual, rsNodeBottom - ROW_H, 0.53, 0.20, 0.8)
Div(pRitual, rsNodeBottom - ROW_H - BAR_H - 8)

local rsOff  = rsNodeBottom - ROW_H - BAR_H - 20
local tierW  = math.floor((szW - PAD * 2 - PGAP_SZ * 4) / 5)
local tierBoxes = {}
for i = 1, 5 do
    local tb = CreateFrame("Frame", nil, pRitual, "BackdropTemplate")
    tb:SetSize(tierW, 36)
    tb:SetPoint("TOPLEFT", pRitual, "TOPLEFT",
        PAD + (i - 1) * (tierW + PGAP_SZ), rsOff - 4)
    tb:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    tb:SetBackdropColor(0.02, 0.03, 0.07, 1)
    tb:SetBackdropBorderColor(0.06, 0.10, 0.20, 0.8)
    tb.tierFS   = tb:CreateFontString(nil, "OVERLAY")
    tb.tierFS:SetFont("Fonts\\2002.ttf", 12, "OUTLINE")
    tb.tierFS:SetPoint("TOP",    tb, "TOP",    0, -4)
    tb.tierFS:SetText(Dim("T" .. i))
    tb.statusFS = tb:CreateFontString(nil, "OVERLAY")
    tb.statusFS:SetFont("Fonts\\2002.ttf", 8, "")
    tb.statusFS:SetPoint("BOTTOM", tb, "BOTTOM", 0, 3)
    tb.statusFS:SetText(Dim("—"))
    tierBoxes[i] = tb
end

local szCol3 = math.floor(szW / 3)
RS.runsWeek = FS(pRitual, rsOff - 44, szCol3)
RS.highTier = FS(pRitual, rsOff - 44, szCol3)
RS.highTier:SetPoint("TOPLEFT", pRitual, "TOPLEFT", PAD + szCol3 + 8, rsOff - 44)
RS.fa       = FS(pRitual, rsOff - 44, szCol3)
RS.fa:SetPoint("TOPLEFT", pRitual, "TOPLEFT", PAD + (szCol3 + 8) * 2, rsOff - 44)
RS.dp       = FS(pRitual, rsOff - 44 - ROW_H, szCol3)

-- Voidforge section
local VF   = {}
local szCol3b = math.floor(szW / 3)
VF.status = FS(pVoidforge, startY, szCol3b)
VF.cores  = FS(pVoidforge, startY, szCol3b)
VF.cores:SetPoint("TOPLEFT", pVoidforge, "TOPLEFT", PAD + szCol3b + 8, startY)
VF.rolls  = FS(pVoidforge, startY, szCol3b)
VF.rolls:SetPoint("TOPLEFT", pVoidforge, "TOPLEFT", PAD + (szCol3b + 8) * 2, startY)
VF.detail = FS(pVoidforge, startY - ROW_H, szW - PAD * 2)

-- Season Summary strip
local SUM  = {}
local sumW = math.floor((szW - PAD * 3) / 4)
SUM.world     = FS(pSzSum, startY, sumW)
SUM.djRank    = FS(pSzSum, startY, sumW)
SUM.djRank:SetPoint("TOPLEFT", pSzSum, "TOPLEFT", PAD + sumW + 8, startY)
SUM.preyRank  = FS(pSzSum, startY, sumW)
SUM.preyRank:SetPoint("TOPLEFT", pSzSum, "TOPLEFT", PAD + (sumW + 8) * 2, startY)
SUM.rsRank    = FS(pSzSum, startY, sumW)
SUM.rsRank:SetPoint("TOPLEFT", pSzSum, "TOPLEFT", PAD + (sumW + 8) * 3, startY)
SUM.worldBar, SUM.worldBW = Bar(pSzSum, startY - ROW_H + 2, 0.3, 0.78, 1)
SUM.reset = FS(pSzSum, startY - ROW_H - BAR_H - 4, szW - PAD * 2)

-- ================================================================
--  FOOTER
-- ================================================================
local footerBG = frame:CreateTexture(nil, "BACKGROUND")
footerBG:SetSize(FW - 4, 40)
footerBG:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
footerBG:SetColorTexture(0.03, 0.07, 0.16, 1)

local footerAccent = frame:CreateTexture(nil, "OVERLAY")
footerAccent:SetSize(FW - 4, 1)
footerAccent:SetPoint("TOP", footerBG, "TOP", 0, 0)
footerAccent:SetColorTexture(0.12, 0.22, 0.45, 0.7)

-- StyleBtn: applies Midnight blue tint to UIPanelButton parts
local function StyleBtn(btn)
    btn:SetFrameLevel(frame:GetFrameLevel() + 15)
    for _, p in ipairs({"Left","Right","Middle"}) do
        if btn[p] then btn[p]:SetVertexColor(0.1, 0.4, 0.9) end
    end
end

-- ================================================================
--  SCALE CONTROL  ◄ [100%] ►  — saved per account in DB
--  ApplyScale forward-declared so event handlers can reach it.
--  Constants + widgets in do..end: saves 6 main-chunk locals.
-- ================================================================
local ApplyScale  -- forward declaration
do
    local SCALE_MIN  = 0.7
    local SCALE_MAX  = 1.5
    local SCALE_STEP = 0.05

    local scaleLabel = frame:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont("Fonts\\2002.ttf", 11, "")
    scaleLabel:SetTextColor(0.55, 0.75, 1, 1)
    scaleLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 80, 12)
    scaleLabel:SetWidth(52)
    scaleLabel:SetJustifyH("CENTER")

    ApplyScale = function(s)
        s = math.max(SCALE_MIN, math.min(SCALE_MAX, s))
        s = math.floor(s * 20 + 0.5) / 20
        DB().uiScale = s
        frame:SetScale(s)
        scaleLabel:SetText(string.format("%d%%", math.floor(s * 100 + 0.5)))
    end

    local scaleDown = CreateFrame("Button", "DT_ScaleDown", frame, "UIPanelButtonTemplate")
    scaleDown:SetSize(26, 22)
    scaleDown:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 9)
    scaleDown:SetText("◄")
    StyleBtn(scaleDown)
    scaleDown:SetScript("OnClick", function()
        ApplyScale((DB().uiScale or 1.0) - SCALE_STEP)
    end)

    local scaleUp = CreateFrame("Button", "DT_ScaleUp", frame, "UIPanelButtonTemplate")
    scaleUp:SetSize(26, 22)
    scaleUp:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 136, 9)
    scaleUp:SetText("►")
    StyleBtn(scaleUp)
    scaleUp:SetScript("OnClick", function()
        ApplyScale((DB().uiScale or 1.0) + SCALE_STEP)
    end)
end

local updateBtn = CreateFrame(
    "Button", "DT_UpdateBtn", frame, "UIPanelButtonTemplate")
updateBtn:SetSize(110, 24)
updateBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)
StyleBtn(updateBtn)

local vaultBtn = CreateFrame(
    "Button", "DT_VaultBtn", frame, "UIPanelButtonTemplate")
vaultBtn:SetSize(110, 24)
vaultBtn:SetPoint("RIGHT", updateBtn, "LEFT", -4, 0)
StyleBtn(vaultBtn)

-- [UPG-4] Footer text slightly larger
local footerFS = frame:CreateFontString(nil, "OVERLAY")
footerFS:SetFont("Fonts\\2002.ttf", 9, "")
footerFS:SetPoint("CENTER", footerBG, "CENTER", 0, 0)
footerFS:SetTextColor(0.29, 0.42, 0.6, 1)

-- ================================================================
--  PANEL TITLES  (called on load and locale change)
-- ================================================================
local function ApplyPanelTitles()
    hdrT:SetText(
        Blue(L["TITLE"] or "CHARACTER DASHBOARD") ..
        Dim("  ·  " .. (L["EDITION"] or "Midnight Edition") .. "  ·  v8.1.0"))

    local keys = { "TAB_OVERVIEW","TAB_GEAR","TAB_PVP","TAB_WARBAND","TAB_SEASON" }
    for i, k in ipairs(keys) do tabBtns[i]:SetText(L[k] or k) end

    PanelTitle(pCombat,   Blue("Combat Stats"))
    PanelTitle(pMythic,   Orange("Mythic+"))
    PanelTitle(pWeekly,   Blue("Weekly Progress"))
    PanelTitle(pCurrency, Gold("Currency — Midnight"))
    PanelTitle(gearPanel,
        Blue("Equipment") ..
        Dim("  —  hover = tooltip · dots = gems · border = quality"))
    PanelTitle(gearSummary,
        Dim("Summary  ·  ") .. Green("✦ Enchants") ..
        Dim("  &  ") .. Purple("◆ Gems"))

    local btitles = {
        {1,"Arena 2v2","ff5544"}, {2,"Arena 3v3","cc88ff"},
        {3,"BG Blitz (8v8)","44ddcc"}, {4,"Solo Shuffle","ffdd44"},
        {5,"Rated BG (10v10)","66aaff"},
    }
    for _, bt in ipairs(btitles) do
        PanelTitle(pvpPanels[bt[1]], CC(bt[3], bt[2]))
    end
    PanelTitle(pvpLifetime, Dim("Lifetime Stats  ·  Season KB  ·  Honor"))
    PanelTitle(pvpInst,     Dim(""))   -- headers are FontStrings already inside
    PanelTitle(pvpTot,      Dim("Season Totals"))
    PanelTitle(wbAcc,   Gold("Account Totals"))
    PanelTitle(wbRep,   Purple("Midnight Reputations") .. Dim(" (warband)"))
    PanelTitle(wbWeek,  Teal("Weekly Overview — All Characters"))

    updateBtn:SetText(L["BTN_UPDATE"] or "UPDATE")
    vaultBtn:SetText(L["BTN_VAULT"]   or "OPEN VAULT")
end

-- ================================================================
--  WEEKLY DATA CACHE
-- ================================================================
local weeklyCache = {}

local function GetWeeklyData()
    local E  = Enum.WeeklyRewardChestThresholdType or {}
    local MP = E.MythicPlus or 1
    local WD = E.World      or 0
    local RD = E.Raid       or 2

    local wA = C_WeeklyRewards.GetActivities(WD)
    local wCur, wMax = 0, 8
    if wA then
        for _, a in ipairs(wA) do
            wCur = math.max(wCur, a.progress  or 0)
            wMax = math.max(wMax, a.threshold or 8)
        end
    end

    local mA = C_WeeklyRewards.GetActivities(MP)
    local mCur, mMax = 0, 8
    if mA then
        for _, a in ipairs(mA) do
            local ok,  p = pcall(function() return a.progress  or 0 end)
            local ok2, t = pcall(function() return a.threshold or 8 end)
            if ok  then mCur = math.max(mCur, p) end
            if ok2 then mMax = math.max(mMax, t) end
        end
    end

    local rA = C_WeeklyRewards.GetActivities(RD)
    local rCur, rMax = 0, 9
    if rA then
        for _, a in ipairs(rA) do
            local ok,  p = pcall(function() return a.progress  or 0 end)
            local ok2, t = pcall(function() return a.threshold or 9 end)
            if ok  then rCur = math.max(rCur, p) end
            if ok2 then rMax = math.max(rMax, t) end
        end
    end

    local rw = C_WeeklyRewards.GetRewards and C_WeeklyRewards.GetRewards() or {}
    local vs = {}
    for _, r in ipairs(rw or {}) do
        if r.level and r.level > 0 then vs[#vs + 1] = r.level end
    end
    table.sort(vs, function(a, b) return a > b end)

    local function ExtractSlots(activities)
        local slots = {
            { level=0, progress=0, threshold=0 },
            { level=0, progress=0, threshold=0 },
            { level=0, progress=0, threshold=0 },
        }
        if not activities then return slots end
        local idx = 0
        for _, a in ipairs(activities) do
            local si = (a.index ~= nil)
                and math.min(3, math.max(1, a.index))
                or (idx + 1)
            idx = idx + 1
            if idx > 3 then break end
            slots[si] = {
                level    = a.level    or 0,
                progress = a.progress or 0,
                threshold= a.threshold or 0,
                unlocked = (a.progress or 0) >= (a.threshold or 1),
            }
        end
        return slots
    end

    local vaultSlots = { ExtractSlots(rA), ExtractSlots(mA), ExtractSlots(wA) }
    weeklyCache = {
        wCur=wCur, wMax=wMax,
        mCur=mCur, mMax=mMax,
        rCur=rCur, rMax=rMax,
        vs=vs, vaultSlots=vaultSlots,
    }
    return weeklyCache
end

-- SaveCharSnapshot: persist current character's data for Warband view
local function SaveCharSnapshot(wd)
    if not DelveTrackerDB then return end
    DelveTrackerDB.characters = DelveTrackerDB.characters or {}

    local key = (UnitName("player") or "Unknown") ..
                "-" ..
                (GetNormalizedRealmName() or "Unknown")
    local d = DelveTrackerDB.characters[key] or {}
    DelveTrackerDB.characters[key] = d

    -- [FIX-4] Use C_ClassColor for class hex in 12.0.x
    local classFile = select(2, UnitClass("player"))
    local cc        = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if not cc and C_ClassColor and C_ClassColor.GetClassColor then
        local co = C_ClassColor.GetClassColor(classFile)
        if co then cc = { r=co.r, g=co.g, b=co.b } end
    end
    d.classHex = cc
        and string.format("%02x%02x%02x",
            cc.r * 255, cc.g * 255, cc.b * 255)
        or "ffffff"

    d.mplus     = wd.mCur or 0
    d.raid      = wd.rCur or 0
    d.vaultOpen = (wd.vs and #wd.vs > 0)
    d.v1ilvl    = (wd.vs and wd.vs[1]) or 0
    d.lastSeen  = time()
    d.realm     = GetRealmName()

    -- Cache a selection of key currencies for cross-character totals
    d.currencies = d.currencies or {}
    local ids = {
        CUR.RESTORED_COFFER_KEY, CUR.COFFER_KEY_SHARDS,
        CUR.SHARD_OF_DUNDUN,     CUR.DAWNLIGHT_MANAFLUX,
        CUR.REMNANT_OF_ANGUISH,  CUR.VOIDLIGHT_MARL,
        CUR.VALORSTONES,         CUR.MYTH_DAWNCREST,
        CUR.HERO_DAWNCREST,      CUR.BRIMMING_ARCANA,
    }
    for _, id in ipairs(ids) do
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and info then d.currencies[id] = info.quantity or 0 end
    end
end

-- ================================================================
--  REFRESH FUNCTIONS
-- ================================================================

local function RefreshCharacter()
    model:SetUnit("player")
    model:SetCamera(0); model:SetPortraitZoom(0)
    model:SetPosition(0, -0.5, 0); model:SetFacing(0.55)

    local specName, roleStr = "Unknown", Dim("?")
    local si = GetSpecialization()
    if si then
        local _, sn, _, _, role = GetSpecializationInfo(si)
        specName = sn or specName
        if     role == "TANK"   then roleStr = Orange(L["ROLE_TANK"]   or "Tank")
        elseif role == "HEALER" then roleStr = Green(L["ROLE_HEALER"]  or "Healer")
        else                         roleStr = Red(L["ROLE_DAMAGE"]    or "Damage") end
    end

    local avg, eq = 0, 0
    pcall(function() avg, eq = GetAverageItemLevel() end)

    local guild = GetGuildInfo("player") or Dim(L["NO_GUILD"] or "No guild")
    local p1, p2 = GetProfessions()

    local function ProfText(pid)
        if not pid then return Dim("—") end
        local pn, _, rk, mx = GetProfessionInfo(pid)
        return (pn or "?") .. Dim(" " .. rk .. "/" .. mx)
    end

    IL.name:SetText(Blue(UnitName("player")))
    IL.spec:SetText(specName .. "  " .. roleStr)
    IL.ilvl:SetText(
        Dim("iLvl: ") .. Blue(math.floor(eq) .. "") ..
        Dim(" (bag " .. math.floor(avg) .. ")"))
    IL.guild:SetText(Dim("Guild: ") .. Teal(guild))
    IL.zone:SetText(Dim("Zone: ") .. (GetRealZoneText() or GetZoneText() or "Unknown"))
    IL.gold:SetText(Dim("Gold: ") .. Gold(GetCoinTextureString(GetMoney())))
    IL.time:SetText(Dim("Time: ") .. Green(ServerTime()))
    IL.reset:SetText(Dim("Reset: ") .. ResetIn())
    -- [FIX-4] C_AchievementInfo.GetTotalAchievementPoints()
    IL.achiev:SetText(Dim("Achiev: ") .. Purple(GetAchievPoints() .. " pt"))
    IL.profA:SetText(Dim("Prof 1: ") .. ProfText(p1))
    IL.profB:SetText(Dim("Prof 2: ") .. ProfText(p2))

    footerFS:SetText(
        Dim("Server time: ") .. Green(ServerTime()) ..
        "  ·  " .. Dim("/cdb [tab]"))
end

local function RefreshCombat()
    CS.haste:SetText(  Dim("Haste:   ") .. SafeFmt(SafeGet(GetHaste),            "%.2f%%", Green))
    CS.crit:SetText(   Dim("Crit:    ") .. SafeFmt(SafeGet(GetCritChance),       "%.2f%%", Yellow))
    CS.mastery:SetText(Dim("Mastery: ") .. SafeFmt(_W12.GetMastery(),            "%.2f%%", Blue))
    CS.vers:SetText(   Dim("Vers:    ") ..
        SafeFmt(SafeGet(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE), "%.2f%%", Teal))
    CS.leech:SetText(  Dim("Leech:   ") ..
        SafeFmt(SafeGet(GetCombatRatingBonus, CR_LIFESTEAL),               "%.2f%%", Purple))

    local ok, cur, run = pcall(GetUnitSpeed, "player")
    if ok and cur and run then
        CS.speed:SetText(Dim("Speed:   ") .. Yellow(Abbrev(cur) .. " / " .. Abbrev(run)))
    else
        CS.speed:SetText(Dim("Speed:   ") .. Dim("—"))
    end

    CS.hp:SetText(Dim("HP:      ") ..
        Green(BreakUpLargeNumbers(UnitHealth("player"))) ..
        Dim("/" .. BreakUpLargeNumbers(UnitHealthMax("player"))))

    local ok2, _, stam = pcall(UnitStat, "player", 3)
    CS.stam:SetText(Dim("Stamina: ") .. (ok2 and stam and Abbrev(stam) or Dim("—")))
end

local function RefreshMythic()
    local aff = C_MythicPlus.GetCurrentAffixes()
    for i, af in ipairs(affixFrames) do
        if aff and aff[i] then
            local _, _, fid = _W12.GetAffixInfo(aff[i].id)
            af.tex:SetTexture(fid)
            af.affixID = aff[i].id
            af:Show()
        else
            af.tex:SetTexture(nil)
            af.affixID = nil
            af:Hide()
        end
    end

    local score = C_ChallengeMode.GetOverallDungeonScore()
    MK.rating:SetText(Orange(score or 0) .. "  " .. Dim("Overall Score"))

    local bL, bM = 0, ""
    local maps   = C_ChallengeMode.GetMapTable()
    if maps then
        for _, mid in ipairs(maps) do
            local lvl = _W12.GetSeasonBest(mid)
            if lvl and lvl > bL then
                bL = lvl
                local mi = C_ChallengeMode.GetMapInfo(mid)
                bM = mi and mi.name or "?"
            end
        end
    end
    MK.best:SetText(Dim("Best: ") .. Yellow("+" .. bL .. "  " .. bM))

    local wd = weeklyCache
    local vl = { MK.v1, MK.v2, MK.v3 }
    for i = 1, 3 do
        if wd.vs and wd.vs[i] then
            local c = i == 1 and Green or (i == 2 and Yellow or Orange)
            vl[i]:SetText(Dim("Vault " .. i .. ": ") .. c(wd.vs[i] .. " ilvl"))
        else
            vl[i]:SetText(Dim("Vault " .. i .. ": " .. (L["LOCKED"] or "locked")))
        end
    end
end

local function RefreshWeekly()
    local wd = weeklyCache
    local bW = WK.delBW    -- all three bars share the same parent width

    WK.del:SetText(ColorProg(wd.wCur, wd.wMax) .. "  " .. Dim("Delves / Prey / Ritual"))
    WK.delBar:SetWidth(SafeBar(bW, wd.wCur, wd.wMax))

    WK.dung:SetText(ColorProg(wd.mCur, wd.mMax) .. "  " .. Dim("M+ Dungeons"))
    WK.dungBar:SetWidth(SafeBar(bW, wd.mCur, wd.mMax))   -- [FIX-6] now bW is correct

    WK.raid:SetText(ColorProg(wd.rCur, wd.rMax) .. "  " .. Dim("Raid bosses"))
    WK.raidBar:SetWidth(SafeBar(bW, wd.rCur, wd.rMax))   -- [FIX-6] now bW is correct

    WK.reset:SetText(Dim("Reset: ") .. ResetIn())

    -- World Vault grid
    local grid  = WK.vaultGrid
    if grid then
        local slots = wd.vaultSlots or { {},{},{} }
        local DEF   = { level=0, progress=0, threshold=0, unlocked=false }
        for ri = 1, 3 do
            local rtSlots = slots[ri] or {}
            for si = 1, 3 do
                local card = grid[ri] and grid[ri][si]
                if card then
                    local s  = rtSlots[si] or DEF
                    local rt = card.rt
                    if s.unlocked and s.level > 0 then
                        card.frame:SetBackdropColor(0.03, 0.07, 0.16, 1)
                        card.frame:SetBackdropBorderColor(rt.r, rt.g, rt.b, 0.75)
                        card.mainFS:SetText(CC(
                            string.format("%02x%02x%02x",
                                math.floor(rt.r*255),
                                math.floor(rt.g*255),
                                math.floor(rt.b*255)),
                            tostring(s.level)))
                        card.subFS:SetText(Green("✓"))
                        card.subFS:SetTextColor(0.20, 0.82, 0.35, 1)
                    elseif s.threshold > 0 then
                        card.frame:SetBackdropColor(0.02, 0.04, 0.10, 1)
                        card.frame:SetBackdropBorderColor(rt.lockR, rt.lockG, rt.lockB, 0.5)
                        card.mainFS:SetText(Yellow(s.progress .. "/" .. s.threshold))
                        card.subFS:SetText(Dim("locked"))
                        card.subFS:SetTextColor(0.22, 0.28, 0.40, 1)
                    else
                        card.frame:SetBackdropColor(0.01, 0.02, 0.06, 1)
                        card.frame:SetBackdropBorderColor(0.06, 0.09, 0.18, 0.3)
                        card.mainFS:SetText(Dim("--"))
                        card.subFS:SetText(Dim("—"))
                        card.subFS:SetTextColor(0.22, 0.28, 0.40, 1)
                    end
                end
            end
        end
    end
end

local function RefreshCurrency()
    for _, row in ipairs(CY_ROWS) do
        local qty = GetCur(row.id)
        row.val:SetText(type(qty) == "number" and Abbrev(qty) or "0")
    end
end

local function RefreshGear()
    local enchMissing, gemOK  = {}, 0
    local blasActive, detailBuf = false, {}
    -- [FIX-10 v8.1] ENCH_SLOTS_12 replaces old enchSlots (Midnight-correct)
    local slotNames = L.SLOT_NAMES or {}

    for _, sdef in ipairs(GEAR_SLOTS_DEF) do
        local sid     = sdef[1]
        local nameIdx = sdef[2]
        local btn     = gearSlotBtns[sid]
        if not btn then break end

        local slotName = slotNames[nameIdx] or "Slot"
        local tex      = GetInventoryItemTexture("player", sid)
        local link     = GetInventoryItemLink("player", sid)
        local name, _, quality, ilvl = GetItemInfo(link or "")

        if tex and link then
            btn.tex:SetTexture(tex)
            btn.ilvlFS:SetText(CC(QC(quality or 0), tostring(ilvl or "")))
            if quality then
                local qr, qg, qb = GetItemQualityColor(quality)
                btn.kader:SetColorTexture(qr, qg, qb, 0.9)
            end

            local enchID, gems = ParseLink(link)
            if _G81.ENCH_SLOTS_12[sid] then
                if enchID then
                    btn.enchDot:SetColorTexture(0.27, 0.87, 0.13, 1)
                else
                    enchMissing[#enchMissing + 1] = slotName
                    btn.enchDot:SetColorTexture(1, 0.2, 0.13, 1)
                end
            else
                btn.enchDot:SetColorTexture(0.1, 0.1, 0.1, 0)
            end

            for g = 1, 3 do
                if gems[g] then
                    local gc  = GemColor(gems[g])
                    local gnm = GetItemInfo(gems[g])
                    if gnm and gnm:find("Blasphemite") then blasActive = true end
                    local hr = tonumber("0x" .. gc:sub(1,2)) / 255
                    local hg = tonumber("0x" .. gc:sub(3,4)) / 255
                    local hb = tonumber("0x" .. gc:sub(5,6)) / 255
                    btn.gemDots[g]:SetColorTexture(hr, hg, hb, 1)
                    gemOK = gemOK + 1
                else
                    btn.gemDots[g]:SetColorTexture(0.1, 0.1, 0.1, 0)
                end
            end

            if enchID then
                detailBuf[#detailBuf + 1] =
                    Dim(slotName .. ": ") ..
                    Green(ENCHANT_NAMES[enchID] or Dim("ID:") .. Yellow(tostring(enchID)))
            end
        else
            btn.tex:SetTexture(nil)
            btn.ilvlFS:SetText("")
            btn.enchDot:SetColorTexture(0.1, 0.1, 0.1, 0)
            for g = 1, 3 do btn.gemDots[g]:SetColorTexture(0.1, 0.1, 0.1, 0) end
            btn.kader:SetColorTexture(0.10, 0.20, 0.42, 0.8)
        end
    end

    GS.enchMiss:SetText(
        #enchMissing == 0
        and Green(L["ENCH_ALL_OK"] or "✦ All enchants present")
        or  Red((L["ENCH_MISSING"] or "✕ Missing: ") ..
                table.concat(enchMissing, ", ")))

    GS.gemMiss:SetText(Purple("◆ Gems: ") .. gemOK .. " socketed")
    GS.gemBonus:SetText(blasActive
        and Teal(L["BLAS_ACTIVE"]   or "◈ Blasphemite active")
        or  Dim(L["BLAS_INACTIVE"] or "◈ Blasphemite inactive"))
    GS.detail:SetText(table.concat(detailBuf, "  ·  "))
    -- [ADD-8 v8.1] Update spec strip + recommendation panel
    _G81:RefreshGearRecs()
end

local function RefreshPvP()
    local brackets = { 1, 2, 5, 4, 3 }
    for panelIdx, bracketNum in ipairs(brackets) do
        local lines = pvpLines[panelIdx]
        if lines then
            local info    = _W12.GetRatedBracket(bracketNum)
            local rating  = info and info.rating        or 0
            local sPlayed = info and info.seasonPlayed  or 0
            local sWon    = info and info.seasonWon     or 0
            local wPlayed = info and info.weeklyPlayed  or 0
            local wWon    = info and info.weeklyWon     or 0
            local lastR   = info and info.lastSeasonRating or 0
            local tier    = info and info.tier

            local lost   = sPlayed - sWon
            local winpct = "0%"
            if sPlayed > 0 then
                local ok, r = pcall(string.format,
                    "%.1f%%", (sWon / sPlayed) * 100)
                winpct = ok and r or "?"
            end

            lines.rating:SetText( Dim("Rating: ") .. Orange(rating))
            lines.wl:SetText(     Dim("W/L: ")    .. Green(sWon) .. "/" .. Red(lost))
            lines.winpct:SetText( Dim("Win%: ")   .. Yellow(winpct))
            lines.weekwl:SetText( Dim("Week: ")   .. Green(wWon) .. "/" .. Red(wPlayed - wWon))
            lines.highest:SetText(Dim("Highest: ") .. Yellow(math.max(rating, lastR)))
            lines.tier:SetText(   Dim("Tier: ")   .. Purple(tier and tier.name or Dim("Unranked")))

            if panelIdx == 4 and ssRounds then
                ssRounds:SetText(Dim("Rounds/week: ") .. Yellow((wPlayed * 6) .. " approx"))
            end
        end
    end

    local ltHK = _W12.GetLifetimeHK()
    local sv   = DB()

    if pvpLifetime.LT then
        local LT = pvpLifetime.LT
        local function ColorNum(n, col)
            return CC(col, Abbrev(n))
        end
        LT[1].num:SetText(ColorNum(ltHK,                          "ff5544"))
        LT[2].num:SetText(ColorNum(0,                             "4a6890"))
        LT[3].num:SetText(ColorNum(sv.kills or 0,                 "ff9922"))
        LT[4].num:SetText(ColorNum(sv.honorEarned or GetCur(CUR.HONOR), "66aaff"))
        for i = 1, 4 do LT[i].num:SetJustifyH("LEFT") end
    end

    -- Fill map-tracking columns
    local function FillMapLines(lines, statTable)
        local entries = {}
        for nm, data in pairs(statTable) do
            entries[#entries + 1] = { nm, data }
        end
        table.sort(entries, function(a, b)
            return (a[2].played or 0) > (b[2].played or 0)
        end)
        for i = 1, 8 do
            local e = entries[i]
            if e then
                local d      = e[2]
                local played = d.played or 0
                local won    = d.won    or 0
                local wp     = played > 0
                    and string.format("%.0f%%", (won / played) * 100)
                    or "0%"
                lines[i]:SetText(
                    Yellow(e[1]:sub(1, 20)) .. "  " ..
                    Dim(played) .. "  " ..
                    Green(won) .. "/" .. Red(played - won) ..
                    " (" .. wp .. ")")
            else
                lines[i]:SetText("")
            end
        end
    end

    FillMapLines(pvpBGLines, sv.bgStats or {})
    FillMapLines(pvpAMLines, sv.amStats or {})

    sv.kills  = sv.kills  or 0
    sv.deaths = sv.deaths or 0
    local kd  = sv.deaths > 0
        and string.format("%.2f", sv.kills / sv.deaths)
        or (sv.kills .. ".0")

    PT.kills:SetText( Dim("HK: ")     .. Red(BreakUpLargeNumbers(sv.kills)))
    PT.deaths:SetText(Dim("Deaths: ") .. Dim(BreakUpLargeNumbers(sv.deaths)))
    PT.kd:SetText(    Dim("K/D: ")    .. Yellow(kd))
    PT.honor:SetText( Dim("Honor: ")  .. Blue(BreakUpLargeNumbers(GetCur(CUR.HONOR))))

    -- BG totals
    local totBGGames, totBGWins, totBGKB = 0, 0, 0
    for _, d in pairs(sv.bgStats or {}) do
        totBGGames = totBGGames + (d.played or 0)
        totBGWins  = totBGWins  + (d.won    or 0)
        totBGKB    = totBGKB    + (d.kb     or 0)
    end
    local bgWP    = totBGGames > 0
        and string.format("%.1f%%", (totBGWins / totBGGames) * 100) or "0%"
    local bgAvgKB = totBGGames > 0
        and string.format("%.1f", totBGKB / totBGGames) or "0"

    if PT2 then
        PT2.bgGames:SetText( Dim("BG Games: ") .. Teal(totBGGames))
        PT2.bgWins:SetText(  Dim("BG Wins: ")  .. Green(totBGWins)  .. "/" .. Red(totBGGames - totBGWins))
        PT2.bgWinPct:SetText(Dim("BG Win%: ")  .. Yellow(bgWP))
        PT2.bgKB:SetText(    Dim("Avg KB: ")   .. Orange(bgAvgKB .. "/game"))
    end

    -- Arena totals
    local totArGames, totArWins = 0, 0
    for _, d in pairs(sv.amStats or {}) do
        totArGames = totArGames + (d.played or 0)
        totArWins  = totArWins  + (d.won    or 0)
    end
    local arWP = totArGames > 0
        and string.format("%.1f%%", (totArWins / totArGames) * 100) or "0%"

    if PT3 then
        PT3.arGames:SetText( Dim("Skirmish: ")  .. Teal(totArGames))
        PT3.arWins:SetText(  Dim("Wins: ")      .. Green(totArWins) .. "/" .. Red(totArGames - totArWins))
        PT3.arWinPct:SetText(Dim("Win%: ")      .. Yellow(arWP))
        PT3.session:SetText( Dim("Session KB: ") .. Orange(sv.sessionKB or 0))
    end

    PS.hlvl:SetText( Dim("Honor Lvl: ") .. Blue(UnitHonorLevel("player") or 0))
    PS.wm:SetText(   Dim("War Mode: ")  ..
        (C_PvP.IsWarModeActive()
            and Green("On +" .. _W12.GetWarModeBonus() .. "%")
            or  Red("Off")))
    PS.title:SetText(Dim("Title: ") .. Purple(UnitPVPName("player") or "None"))
end

local function RefreshWarband()
    -- Retrieve BattleTag
    local bnetTag
    if C_BattleNet and C_BattleNet.GetMyAccountInfo then
        local ok, info = pcall(C_BattleNet.GetMyAccountInfo)
        if ok and info then bnetTag = info.battleTag end
    end
    if not bnetTag then
        local ok, _, t = pcall(BNGetInfo)
        if ok and t then bnetTag = t end
    end
    WBH.btag:SetText(Blue(bnetTag or "Unknown"))
    WBH.realm:SetText(Dim(GetRealmName()))
    WBH.wblvl:SetText(Dim("Warband Level  ") .. Blue("?"))

    -- Build and sort character list by item level (desc)
    local chars    = DelveTrackerDB.characters or {}
    local charList = {}
    for key, data in pairs(chars) do
        if data.class or data.ilvl then
            charList[#charList + 1] = { key=key, data=data }
        end
    end
    table.sort(charList, function(a, b)
        return (a.data.ilvl or 0) > (b.data.ilvl or 0)
    end)

    -- [FIX-2] Fill pool for all characters
    local myKey   = (UnitName("player") or "") .. "-" .. (GetNormalizedRealmName() or "")
    local numChars = #charList

    local numRows  = math.ceil(numChars / WB_COLS)
    local contentH = math.max(WB_STRIP_H - PAD - ROW_H,
                               numRows * (WB_CARD_H + PGAP))
    wbContent:SetHeight(contentH)

    for pi = 1, WB_POOL_SIZE do
        local cf    = wbPool[pi]
        local entry = charList[pi]
        if entry then
            local col = (pi - 1) % WB_COLS
            local row = math.floor((pi - 1) / WB_COLS)
            cf:SetPoint("TOPLEFT", wbContent, "TOPLEFT",
                col * (charW + PGAP), -(row * (WB_CARD_H + PGAP)))

            local d    = entry.data
            local isMe = (entry.key == myKey)
            local hx   = d.classHex or "ffffff"
            local nm   = entry.key:match("([^-]+)") or entry.key

            cf.nameFS:SetText(
                CC(hx, nm) .. (isMe and Dim(" ← active") or ""))

            local st = (d.spec or "?") .. "  " .. Dim((d.ilvl or 0) .. " ilvl")
            if d.mplus   and d.mplus   > 0 then st = st .. "  " .. Dim("M+:" .. d.mplus) end
            if d.totalDone and d.totalDone > 0 then st = st .. "  " .. Dim("D:" .. d.totalDone) end
            cf.specFS:SetText(st)

            cf:SetBackdropBorderColor(
                isMe and 0.3  or 0.10,
                isMe and 0.78 or 0.20,
                isMe and 1.0  or 0.42,
                0.8)
            cf:Show()
        else
            cf:Hide()
        end
    end

    -- Account Totals
    -- [FIX-4] Use GetAchievPoints() wrapper for C_AchievementInfo
    WA.wbgold:SetText( Dim("Gold:         ") .. Gold(GetCoinTextureString(GetMoney())))
    WA.achiev:SetText( Dim("Achievements: ") .. Purple(GetAchievPoints() .. " pt"))
    WA.pets:SetText(   Dim("Pets:         ") ..
        Teal(C_PetJournal.GetNumPets and C_PetJournal.GetNumPets() or 0))
    WA.mounts:SetText( Dim("Mounts:       ") ..
        Orange(C_MountJournal.GetNumDisplayedMounts
            and C_MountJournal.GetNumDisplayedMounts() or 0))
    WA.toys:SetText(   Dim("Toys:         ") ..
        Green(C_ToyBox.GetNumLearnedDisplayedToys
            and C_ToyBox.GetNumLearnedDisplayedToys() or 0))

    local totDun, totMaf = 0, 0
    for _, e in ipairs(charList) do
        local cur = e.data.currencies or {}
        totDun = totDun + (cur[CUR.SHARD_OF_DUNDUN]   or 0)
        totMaf = totMaf + (cur[CUR.DAWNLIGHT_MANAFLUX] or 0)
    end
    WA.dundun:SetText(  Dim("Shard of Dundun:    ")    .. Gold(totDun)  ..
        (numChars > 1 and Dim("  (all chars)") or ""))
    WA.manaflux:SetText(Dim("Dawnlight Manaflux: ")    .. Teal(totMaf) ..
        (numChars > 1 and Dim("  (all chars)") or ""))

    -- [v8.1] Midnight Reputations — direct ID lookup (GetNumFactions=0 in Midnight 12.x)
    -- Old rep API removed: we call C_MajorFactions/C_Reputation directly with verified IDs.
    -- Faction IDs confirmed via Wowhead (March 2026):
    --   2696=Amani Tribe  2699=The Singularity  2704=Hara'ti
    --   2710=Silvermoon Court  2770=Slayer's Duellum
    do
        -- Static config: verified IDs, colors, priorities
        local FACTIONS = {
            -- Renown track (C_MajorFactions): pri=1 main, pri=2 sub
            {id=2696, name="Amani Tribe",       col="ff9922", pri=1, mode="renown"},
            {id=2699, name="The Singularity",   col="cc88ff", pri=1, mode="renown"},
            {id=2704, name="Hara'ti",           col="44ee66", pri=1, mode="renown"},
            {id=2710, name="Silvermoon Court",  col="ffd700", pri=1, mode="renown"},
            -- Ritual Sites (12.0.5) — scan IDs 2775-2810 to auto-find
            -- Slayer's Duellum: classic standing (not Renown)
            {id=2770, name="Slayer's Duellum",  col="ff4444", pri=1, mode="standing"},
            -- Sub-factions — scan IDs 2711-2730 to auto-find (after Silvermoon Court=2710)
        }

        -- Hardcoded Midnight sub-faction IDs (confirmed via Wowhead March 2026)
        --   2712=Blood Knights  2713=Farstriders  2714=Magisters  2715=Shades of the Row
        -- Ritual Sites: scan 2775-2810 (added in 12.0.5, ID not yet confirmed)
        local SUB_HARDCODED = {
            {id=2712, name="Blood Knights",     col="cc2222", pri=2, mode="standing"},
            {id=2713, name="Farstriders",       col="44aa44", pri=2, mode="standing"},
            {id=2714, name="Magisters",         col="4488ff", pri=2, mode="standing"},
            {id=2715, name="Shades of the Row", col="aa44bb", pri=2, mode="standing"},
        }
        local knownIDs = {}
        for _,f in ipairs(FACTIONS) do knownIDs[f.id] = true end
        for _, sub in ipairs(SUB_HARDCODED) do
            if not knownIDs[sub.id] then
                knownIDs[sub.id] = true
                FACTIONS[#FACTIONS+1] = sub
            end
        end

        -- Ritual Sites: scan 2775-2810 (12.0.5 addition, ID unknown)
        local RITUAL_NAMES = {["Ritual Sites"]=true}
        for fid = 2775, 2810 do
            if not knownIDs[fid] then
                if C_MajorFactions and C_MajorFactions.GetMajorFactionRenownInfo then
                    local ok, info = pcall(C_MajorFactions.GetMajorFactionRenownInfo, fid)
                    if ok and info and info.name and RITUAL_NAMES[info.name] then
                        knownIDs[fid]=true
                        FACTIONS[#FACTIONS+1]={id=fid,name=info.name,col="44ddcc",pri=1,mode="renown"}
                    end
                end
                if not knownIDs[fid] and C_Reputation and C_Reputation.GetFactionDataByID then
                    local ok2,data=pcall(C_Reputation.GetFactionDataByID,fid)
                    if ok2 and data and RITUAL_NAMES[data.name] then
                        knownIDs[fid]=true
                        FACTIONS[#FACTIONS+1]={id=fid,name=data.name,col="44ddcc",pri=1,mode="renown"}
                    end
                end
            end
        end

        -- Deduplicate by name: if two IDs share the same in-game faction name,
        -- keep only the first occurrence (lowest ID wins after prior ordering).
        -- Root cause: hardcoded ID 2714 may share a display name with 2715 in 12.0.x.
        do
            local seenNames, dedup = {}, {}
            for _, f in ipairs(FACTIONS) do
                local key = f.name:lower()
                if not seenNames[key] then
                    seenNames[key] = true
                    dedup[#dedup+1] = f
                end
            end
            FACTIONS = dedup
        end

        -- Sort: pri 1 first, then by ID
        table.sort(FACTIONS, function(a,b)
            if a.pri ~= b.pri then return a.pri < b.pri end
            return a.id < b.id
        end)

        -- Standard standings for classic rep factions
        local STAND = {"Hated","Hostile","Unfriendly","Neutral",
                       "Friendly","Honored","Revered","Exalted"}
        -- Midnight sub-faction standings (6 social ranks, confirmed order):
        -- Interloper → Gossip → Guest → Socialite → Host → VIP
        -- WoW maps these to reaction 3-8 (Unfriendly=Interloper to Exalted=VIP)
        local MIDNIGHT_SUB_STAND = {
            [1]="Interloper", [2]="Interloper", [3]="Interloper",
            [4]="Gossip",     [5]="Guest",      [6]="Socialite",
            [7]="Host",       [8]="VIP",
        }
        local MIDNIGHT_SUB_FACS = {
            ["Blood Knights"]=true, ["Farstriders"]=true,
            ["Magisters"]=true,     ["Shades of the Row"]=true,
        }

        -- Render each faction
        for i = 1, 12 do
            if repLines[i] then
                local fac = FACTIONS[i]
                if fac then
                    local right = ""
                    local dispName = fac.name

                    if fac.mode == "renown" then
                        -- Renown faction: try multiple field names (API varies by patch)
                        local rnwLevel, rnwXP, rnwMax = 0, 0, 2500
                        if C_MajorFactions and C_MajorFactions.GetMajorFactionRenownInfo then
                            local ok, info = pcall(C_MajorFactions.GetMajorFactionRenownInfo, fac.id)
                            if ok and info then
                                rnwLevel = info.renownLevel or 0
                                rnwMax   = info.renownRewardThreshold or 2500
                                -- Try multiple field names for current XP (API changed in 12.x)
                                rnwXP = info.currentRenownXP
                                    or info.renownCurrentXP
                                    or info.currentXP
                                    or info.xp
                                    or info.currentStanding
                                    or 0
                                if info.name and info.name ~= "" then
                                    dispName = info.name
                                end
                            end
                        end
                        right = "|cff44ee66Renown "..rnwLevel.."|r"
                        if rnwLevel >= 20 then
                            right = right .. Dim("  (MAX)")
                        elseif rnwXP and rnwXP > 0 then
                            local pct = math.floor(100 * rnwXP / rnwMax)
                            right = right .. Dim("  "..rnwXP.."/"..rnwMax.." ("..pct.."%)")
                        end
                        -- else: show just "Renown N" — no XP noise when 0

                    else
                        -- Classic standing faction
                        local standID, earned, bot, top = 4, 0, 0, 0
                        -- Try GetFactionInfoByID first (sometimes returns better data)
                        local ok0, nm0,_,sid0,b0,t0,e0 = pcall(GetFactionInfoByID, fac.id)
                        if ok0 and nm0 and sid0 then
                            standID=sid0; bot=b0 or 0; top=t0 or 0; earned=e0 or 0
                        end
                        -- Then try C_Reputation (may have more fields)
                        if C_Reputation and C_Reputation.GetFactionDataByID then
                            local ok, data = pcall(C_Reputation.GetFactionDataByID, fac.id)
                            if ok and data then
                                -- Only override if GetFactionInfoByID gave reaction=4 (default)
                                if standID == 4 or not ok0 then
                                    standID = data.reaction or standID
                                    earned  = data.currentStanding or earned
                                    bot     = data.currentReactionThreshold or bot
                                    top     = data.nextReactionThreshold or top
                                end
                                if data.name and data.name ~= "" then dispName = data.name end
                            end
                        end
                        -- Use Midnight sub-faction names where applicable
                        local standTable = MIDNIGHT_SUB_FACS[fac.name] and MIDNIGHT_SUB_STAND or STAND
                        local s   = standTable[standID] or "Unknown"
                        local prog = ""
                        if top > bot and top > 0 then
                            local c2 = math.max(0, earned - bot)
                            local m2 = top - bot
                            if m2 > 0 then
                                prog = Dim(string.format("  %d/%d", c2, m2))
                            end
                        end
                        right = "|cffaaaacc"..s.."|r"..prog
                    end

                    local indent = fac.pri == 2 and Dim("  ") or ""
                    repLines[i]:SetText(indent.."|cff"..fac.col..dispName.."|r  "..right)
                else
                    repLines[i]:SetText("")
                end
            end
        end

        -- Emergency fallback: show debug if ALL factions return nothing
        local anyFound = false
        for i=1,#FACTIONS do if FACTIONS[i] then anyFound=true; break end end
        if not anyFound and repLines[1] then
            repLines[1]:SetText(Dim("IDs loaded: "..#FACTIONS..
                "  MajFac="..tostring(C_MajorFactions~=nil)..
                "  CRep="..tostring(C_Reputation~=nil)))
        end
    end


    -- Weekly Overview totals
    local totDel, totMplus, totVault = 0, 0, 0
    for _, e in ipairs(charList) do
        local d = e.data
        totDel   = totDel   + (d.totalDone or 0)
        totMplus = totMplus + (d.mplus     or 0)
        if d.vaultOpen then totVault = totVault + 1 end
    end
    WW.del:SetText(  Dim("Delves: ")    .. Green(totDel))
    WW.mplus:SetText(Dim("M+ keys: ")   .. Orange(totMplus))
    WW.vault:SetText(Dim("Vault open: ") .. Purple(totVault .. "/" .. numChars))
    WW.chars:SetText(Dim("Chars: ")     .. Blue(numChars))
end

local function RefreshSeason()
    local wd = weeklyCache
    local sv = DB()

    -- ── Delver's Journey ────────────────────────────────────────
    local djRank, djXP, djMaxXP = 1, 0, 4000
    if C_DelvesUI and C_DelvesUI.GetDelvesFactionForSeason then
        local fID = C_DelvesUI.GetDelvesFactionForSeason()
        if fID and fID > 0 then
            local info = C_MajorFactions
                and C_MajorFactions.GetMajorFactionRenownInfo
                and C_MajorFactions.GetMajorFactionRenownInfo(fID)
            if info then
                djRank   = info.renownLevel         or 1
                djXP     = info.currentRenownXP     or 0
                djMaxXP  = info.renownRewardThreshold or 4000
            end
        end
    end
    updateDelveRank(djRank)
    pDelve.rankFS:SetText(CC("44ee66", "Rank " .. djRank))
    DJ.xpLabel:SetText(
        Dim("Rank " .. djRank .. "  ·  ") ..
        Yellow(djXP .. " / " .. djMaxXP .. " XP") ..
        Dim("  ·  Total: ") .. Teal(djXP + (djRank - 1) * 4000))
    DJ.xpBar:SetWidth(SafeBar(DJ.xpBW, djXP, djMaxXP))
    DJ.weekly:SetText(ColorProg(wd.wCur, wd.wMax) .. "  " .. Dim("Bountiful Delves"))
    DJ.delBar:SetWidth(SafeBar(DJ.delBW, wd.wCur, wd.wMax))
    DJ.vault:SetText(Dim("Vault slot 1: ") ..
        (wd.vs and wd.vs[1] and Green(wd.vs[1] .. " ilvl") or Dim("locked")))
    DJ.coffKeys:SetText(
        Dim("Restored Coffer Keys: ") .. Teal(GetCur(CUR.RESTORED_COFFER_KEY)) ..
        "  " .. Dim("Shards: ") .. Yellow(GetCur(CUR.COFFER_KEY_SHARDS)))
    local ok_sc, sc = pcall(function()
        return C_ChallengeMode
            and C_ChallengeMode.GetOverallDungeonScore
            and C_ChallengeMode.GetOverallDungeonScore()
    end)
    DJ.zekvir:SetText(Dim("M+ Score: ") .. Orange((ok_sc and sc) or 0))
    DJ.seasonXP:SetText(Dim("Season total: ") .. Yellow(djXP + (djRank - 1) * 4000) .. " XP")

    -- ── Prey ────────────────────────────────────────────────────
    local preyRank, preyXP, preyMaxXP = 1, 0, SEASON.PREY_XP_PER_RANK
    local mIPrey = C_MajorFactions
        and C_MajorFactions.GetMajorFactionRenownInfo
        and C_MajorFactions.GetMajorFactionRenownInfo(SEASON.PREY_FACTION_ID)

    if mIPrey and mIPrey.renownLevel and mIPrey.renownLevel > 0 then
        preyRank   = math.min(SEASON.PREY_RANKS, mIPrey.renownLevel)
        preyXP     = mIPrey.currentRenownXP     or 0
        preyMaxXP  = mIPrey.renownRewardThreshold or SEASON.PREY_XP_PER_RANK
    else
        local preyData = C_Reputation
            and C_Reputation.GetFactionDataByID
            and C_Reputation.GetFactionDataByID(SEASON.PREY_FACTION_ID)
        if preyData then
            local st = preyData.currentStanding or 0
            if st > SEASON.PREY_RANKS then
                preyRank = math.min(SEASON.PREY_RANKS,
                    math.floor(st / SEASON.PREY_XP_PER_RANK) + 1)
                preyXP   = st % SEASON.PREY_XP_PER_RANK
            else
                preyRank = math.max(1, st)
            end
        end
    end
    updatePreyRank(preyRank)
    pPrey.rankFS:SetText(CC("ff5544", "Rank " .. preyRank))
    PR.xpLabel:SetText(
        Dim("Rank " .. preyRank .. "  ·  ") ..
        Yellow(preyXP .. " / " .. preyMaxXP .. " XP"))
    PR.xpBar:SetWidth(SafeBar(PR.xpBW, preyXP, preyMaxXP))

    local wH = math.min(sv.preyWeekly or 0, SEASON.PREY_MAX_WEEKLY)
    local eH = math.max(0, (sv.preyWeekly or 0) - SEASON.PREY_MAX_WEEKLY)
    for i, hc in ipairs(huntCircles) do
        if i <= wH then
            hc:SetBackdropColor(0.03, 0.12, 0.05, 1)
            hc:SetBackdropBorderColor(0.1, 0.4, 0.15, 1)
            hc.numFS:SetText(Green("✓"))
        else
            hc:SetBackdropColor(0.02, 0.03, 0.07, 1)
            hc:SetBackdropBorderColor(0.06, 0.10, 0.20, 0.8)
            hc.numFS:SetText(Dim(tostring(i)))
        end
    end
    PR.huntLabel:SetText(ColorProg(wH, SEASON.PREY_MAX_WEEKLY) .. "  " .. Dim("hunts completed"))
    PR.extraHunt:SetText(eH > 0
        and Dim("Extra: ") .. Yellow(eH .. " × +50 pt")
        or  Dim("Extra hunts: —"))
    PR.diffNorm:SetText( Dim("Normal:    ") .. Yellow("→ see in-game"))
    PR.diffHard:SetText( Dim("Hard:      ") .. Yellow("→ see in-game"))
    PR.diffNM:SetText(   Dim("Nightmare: ") .. Red("Hardest"))
    PR.currency:SetText( Dim("Remnant of Anguish (3392): ") ..
        Orange(GetCur(CUR.REMNANT_OF_ANGUISH)))

    -- ── Ritual Sites ────────────────────────────────────────────
    local rsRank, rsXP, rsMaxXP = 1, 0, 2000
    local rsData = C_Reputation
        and C_Reputation.GetFactionDataByID
        and C_Reputation.GetFactionDataByID(SEASON.RITUAL_FACTION_ID)
    if rsData then
        local rM = C_MajorFactions
            and C_MajorFactions.GetMajorFactionRenownInfo
            and C_MajorFactions.GetMajorFactionRenownInfo(SEASON.RITUAL_FACTION_ID)
        if rM and rM.renownLevel then
            rsRank  = rM.renownLevel
            rsXP    = rM.currentRenownXP      or 0
            rsMaxXP = rM.renownRewardThreshold or 2000
        else
            pcall(function()
                local st = rsData.currentStanding or 0
                rsRank   = math.floor(st / 2000) + 1
                rsXP     = st % 2000
            end)
        end
    end
    rsRank = math.min(rsRank, SEASON.RITUAL_RANKS)
    updateRitualRank(rsRank)
    pRitual.rankFS:SetText(CC("cc88ff", "Rank " .. rsRank))
    RS.xpLabel:SetText(
        Dim("Rank " .. rsRank .. "  ·  ") ..
        Yellow(rsXP .. " / " .. rsMaxXP .. " XP"))
    RS.xpBar:SetWidth(SafeBar(RS.xpBW, rsXP, rsMaxXP))

    local hT = sv.ritualHighestTier or 0
    for i, tb in ipairs(tierBoxes) do
        if i <= hT then
            tb:SetBackdropColor(0.03, 0.12, 0.05, 1)
            tb:SetBackdropBorderColor(0.1, 0.4, 0.15, 1)
            tb.tierFS:SetText(Green("T" .. i))
            tb.statusFS:SetText(Green("✓"))
        elseif i == hT + 1 then
            tb:SetBackdropColor(0.04, 0.10, 0.20, 1)
            tb:SetBackdropBorderColor(0.15, 0.45, 0.80, 1)
            tb.tierFS:SetText(Blue("T" .. i))
            tb.statusFS:SetText(Blue("►"))
        else
            tb:SetBackdropColor(0.02, 0.03, 0.07, 1)
            tb:SetBackdropBorderColor(0.06, 0.10, 0.20, 0.8)
            tb.tierFS:SetText(Dim("T" .. i))
            tb.statusFS:SetText(Dim("  "))
        end
    end
    RS.runsWeek:SetText(Dim("Runs this week: ") .. Yellow(sv.ritualRunsWeek or 0))
    RS.highTier:SetText(Dim("Highest tier: ") .. Purple("T" .. (hT > 0 and hT or "—")))
    RS.fa:SetText(Dim("Voidlight Marl (3316): ") .. Yellow(GetCur(CUR.VOIDLIGHT_MARL)))
    RS.dp:SetText(Dim("Brimming Arcana (3379): ") .. Teal(GetCur(CUR.BRIMMING_ARCANA)))

    -- ── Voidforge ───────────────────────────────────────────────
    sv.voidforgeUnlocked = sv.voidforgeUnlocked or false
    VF.status:SetText(Dim("Voidforge: ") ..
        (sv.voidforgeUnlocked and Green("✓ Unlocked") or Yellow("→ In progress")))
    VF.cores:SetText( Dim("Bonus rolls this week: ") ..
        Yellow(sv.voidforgeRollsWeek or 0) .. " / 2")
    VF.rolls:SetText( Dim("Decor Duels: ") ..
        Purple(#(sv.ddStats or {}) .. " maps tracked"))
    VF.detail:SetText(
        Dim("Unlocked via: Mythic+ · Raids · Bountiful Delves · Prey Hunts (Nightmare)"))

    -- ── Season Summary ──────────────────────────────────────────
    SUM.world:SetText(    Dim("World Vault: ") ..
        ColorProg(wd.wCur, wd.wMax))
    SUM.worldBar:SetWidth(SafeBar(SUM.worldBW, wd.wCur, wd.wMax))
    SUM.djRank:SetText(   Teal("DJ: Rank " .. djRank))
    SUM.preyRank:SetText( Red("Prey: Rank " .. preyRank))
    SUM.rsRank:SetText(   Purple("Ritual: Rank " .. rsRank))
    SUM.reset:SetText(    Dim("Reset in: ") .. ResetIn())
end

local function RefreshAll()
    local wd = GetWeeklyData()
    RefreshCharacter()
    RefreshCombat()
    RefreshMythic()
    RefreshWeekly()
    RefreshCurrency()
    SaveCharSnapshot(wd)
end

-- ================================================================
--  TAB BUTTON CLICK HANDLERS
-- ================================================================
tabBtns[1]:SetScript("OnClick", function() ShowTab(1); RefreshAll() end)
tabBtns[2]:SetScript("OnClick", function() ShowTab(2); RefreshGear() end)
tabBtns[3]:SetScript("OnClick", function() ShowTab(3); RefreshPvP() end)
tabBtns[4]:SetScript("OnClick", function() ShowTab(4); RefreshWarband() end)
tabBtns[5]:SetScript("OnClick", function() ShowTab(5); RefreshSeason() end)

updateBtn:SetScript("OnClick", function()
    RefreshAll()
    if activeTab == 2 then RefreshGear()
    elseif activeTab == 3 then RefreshPvP()
    elseif activeTab == 4 then RefreshWarband()
    elseif activeTab == 5 then RefreshSeason()
    end
    print(CC("4dc8ff", "[CharDashboard]: ") ..
        (L["CHAT_UPDATED"] or "Data refreshed — ") .. ServerTime())
end)

-- [FIX-3] Vault button: guard against InCombatLockdown to prevent taint
vaultBtn:SetScript("OnClick", function()
    if InCombatLockdown() then
        print(CC("ff9922", "[CharDashboard]") ..
            Dim(": Cannot open Vault during combat."))
        return
    end
    if not WeeklyRewardsFrame then
        local ok2 = C_AddOns and C_AddOns.LoadAddOn and
                    C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
    end
    if WeeklyRewards_ShowUI then
        WeeklyRewards_ShowUI()
    elseif WeeklyRewardsFrame then
        WeeklyRewardsFrame:Show()
    end
end)

-- ================================================================
--  PVP EVENT TRACKER
-- ================================================================
local pvpEvt = CreateFrame("Frame")
pvpEvt:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
pvpEvt:RegisterEvent("PVP_MATCH_COMPLETE")
pvpEvt:RegisterEvent("PLAYER_ENTERING_WORLD")

local currentBGName = nil
local isDecorDuels  = false

pvpEvt:SetScript("OnEvent", function(self, event)
    local sv = DB()
    sv.kills    = sv.kills   or 0
    sv.bgStats  = sv.bgStats or {}
    sv.amStats  = sv.amStats or {}
    sv.tgStats  = sv.tgStats or {}
    sv.ddStats  = sv.ddStats or {}

    if event == "UPDATE_BATTLEFIELD_SCORE" then
        local zoneName = GetZoneText()
        currentBGName  = zoneName
        isDecorDuels   = (zoneName and
            (zoneName:find("Silvermoon") or zoneName:find("Decor"))) or false

        local pN = UnitName("player")
        for i = 1, _W12.GetNumScores() do
            local scoreInfo = _W12.GetScoreInfo(i)
            local name      = scoreInfo and scoreInfo.name
            local kb        = scoreInfo and scoreInfo.honorableKills
            if name and (name == pN or name:find("^" .. pN .. "-")) then
                local nKB = kb or 0
                if nKB > (sv.sessionKB or 0) then
                    sv.kills    = sv.kills + (nKB - (sv.sessionKB or 0))
                    sv.sessionKB = nKB
                end
                break
            end
        end

    elseif event == "PVP_MATCH_COMPLETE" then
        sv.sessionKB    = 0
        local mapName   = currentBGName or GetZoneText()
        local isArena   = _W12.IsInArena()
        local faction   = UnitFactionGroup("player")
        local winner    = _W12.GetMatchWinner()
        local won       = winner ~= nil and winner == faction

        local pN2, fKB = UnitName("player"), 0
        for i = 1, _W12.GetNumScores() do
            local si   = _W12.GetScoreInfo(i)
            local name = si and si.name
            local kb   = si and si.honorableKills
            if name and (name == pN2 or name:find("^" .. pN2 .. "-")) then
                fKB = kb or 0; break
            end
        end

        local store = isDecorDuels and sv.ddStats
                   or (isArena      and sv.amStats or sv.bgStats)
        store[mapName] = store[mapName] or { played=0, won=0, kb=0 }
        store[mapName].played = store[mapName].played + 1
        if won then store[mapName].won = store[mapName].won + 1 end
        store[mapName].kb = (store[mapName].kb or 0) + fKB

        currentBGName = nil
        isDecorDuels  = false
        if frame:IsShown() and activeTab == 3 then RefreshPvP() end

    elseif event == "PLAYER_ENTERING_WORLD" then
        sv.sessionKB = 0
    end
end)

-- [FIX-1] Prey quest tracking — use GetQuestTitleByID (12.0.5 compatible)
local preyEvt = CreateFrame("Frame")
preyEvt:RegisterEvent("QUEST_TURNED_IN")
preyEvt:SetScript("OnEvent", function(self, event, questID)
    if event == "QUEST_TURNED_IN" then
        local qName = _W12.GetQuestTitleByID(questID)
        if qName and (
            qName:find("Prey") or
            qName:find("Hunt") or
            qName:find("Preyseeker")) then
            DB().preyWeekly = (DB().preyWeekly or 0) + 1
            if frame:IsShown() and activeTab == 5 then RefreshSeason() end
        end
    end
end)

-- Ritual scenario tracker
local ritualEvt = CreateFrame("Frame")
ritualEvt:RegisterEvent("SCENARIO_COMPLETED")
ritualEvt:SetScript("OnEvent", function(self, event)
    if event == "SCENARIO_COMPLETED" then
        local sv = DB()
        sv.ritualRunsWeek = (sv.ritualRunsWeek or 0) + 1
        local info = C_Scenario.GetScenarioInfo
            and C_Scenario.GetScenarioInfo() or nil
        if info and info.currentStage then
            sv.ritualHighestTier = math.max(
                sv.ritualHighestTier or 0,
                math.min(info.currentStage, SEASON.RITUAL_MAX_TIER))
        end
        if frame:IsShown() and activeTab == 5 then RefreshSeason() end
    end
end)

-- ================================================================
--  MAIN FRAME EVENT HANDLER
-- ================================================================
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == "WowTracker" or arg1 == "DelveTracker") then
        SetLocale("en"); ApplyPanelTitles()
        ApplyScale(DB().uiScale or 1.0)

    elseif event == "PLAYER_ENTERING_WORLD" then
        SetLocale("en"); ApplyPanelTitles()
        ApplyScale(DB().uiScale or 1.0)
        local wd = GetWeeklyData()
        SaveCharSnapshot(wd)
        if arg1 or frame:IsShown() then
            RefreshAll()
            if activeTab == 5 then RefreshSeason() end
        end

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if frame:IsShown() then
            RefreshCharacter(); RefreshCombat()
            if activeTab == 2 then RefreshGear() end
        end

    elseif event == "PLAYER_LEVEL_UP" then
        if frame:IsShown() then RefreshAll() end

    elseif event == "PLAYER_MONEY" then
        if frame:IsShown() then
            IL.gold:SetText(Dim("Gold: ") .. Gold(GetCoinTextureString(GetMoney())))
        end
    end
end)

-- ================================================================
--  SLASH COMMANDS  (global keys required by WoW API)
-- ================================================================
SLASH_DTUSER1 = "/userinfo"
SLASH_DTUSER2 = "/chardash"
SLASH_DTUSER3 = "/cdb"

SlashCmdList["DTUSER"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "gear" or msg == "g" then
        ShowTab(2); if frame:IsShown() then RefreshGear() end
    elseif msg == "pvp" then
        ShowTab(3); if frame:IsShown() then RefreshPvP() end
    elseif msg == "warband" or msg == "wb" then
        ShowTab(4); if frame:IsShown() then RefreshWarband() end
    elseif msg == "season" or msg == "s" then
        ShowTab(5); if frame:IsShown() then RefreshSeason() end
    elseif frame:IsShown() then
        frame:Hide()
    else
        SetLocale("en"); ApplyPanelTitles()
        ShowTab(1); RefreshAll(); frame:Show()
    end
end

-- ================================================================
--  PLUGIN REGISTRATION  (DelveTracker tooltip integration)
-- ================================================================
if DelveTracker then
    DelveTracker:RegisterPlugin("UserInfo", function(mode)
        if mode == "Tooltip" then
            GameTooltip:AddLine("|cff00ccffCharDashboard: /cdb|r")
        end
    end)
end

-- ================================================================
--  INITIAL RENDER
-- ================================================================
ShowTab(1)