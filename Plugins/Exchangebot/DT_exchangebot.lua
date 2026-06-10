-- ============================================================
-- DelveTracker Plugin: DT_ExchangeBot v19.0
-- Author   : DelveTracker
-- Command  : /cbot  |  /cureset
-- Interface: 120005 (WoW Midnight 12.0.5.67314)
--
-- Features : Class-colored theme . 4-col card layout . hover glow
--            Prey Hunts . Void Assaults & Ritual Sites . Voidforge (12.0.5)
--            Warbound currency transfer . Scale ±/Reset . Portrait
--            Collapsible sections . Status bar . Slash commands
--
-- CHANGELOG v19.0
--   !! Header grid RESTORED to v18 original (slots 1-6 unchanged) !!
--   !! extraFrames RESTORED to v18: left=3377, right=3378           !!
--
--   NEW subsections added under MIDNIGHT (research: Wowhead/Bnet/IcyVeins):
--   + PREY HUNTS sub - Remnant of Anguish (3392, confirmed wowhead.com/currency=3392)
--       Prey-system currency; already in MIDNIGHT flat list -> moved to dedicated sub
--   + VOID ASSAULTS & RITUAL SITES sub - Field Accolade (3405, wowhead.com/currency=3405)
--       Shared currency from both Void Assaults (Eversong/Zul'Aman) and Ritual Sites
--       Spend at Maren Silverwing / Rae'ana in Silvermoon Bazaar for gear + cosmetics
--   + VOIDFORGE sub - Nebulous Voidcore (3418, wowhead.com/currency=3418)
--       Patch 12.0.5 bonus-roll currency; buy from Decimus for gold/Marl/Dawncrests
--
--   + subDefaults updated for 3 new subsections
--   + Section ordering reviewed & comments expanded
--   + All locals confirmed - no global leaks
-- ============================================================

if not DelveTracker then return end

-- WTTheme: centraal kleurensysteem (Fase 3 - T04b)
local function TH()
    return WTTheme or {
        bg={main={r=0.04,g=0.02,b=0.08,a=0.97},card={r=0.06,g=0.03,b=0.10,a=0.95},
            row={r=0.05,g=0.02,b=0.08,a=0.90}},
        border={main={r=0.35,g=0.08,b=0.55,a=1},card={r=0.20,g=0.05,b=0.35,a=0.8},
               active={r=0.55,g=0.15,b=0.85,a=1}},
        c={gold="|cffccaa00",purple="|cffbf00ff",blue="|cff00dfff",
           grey="|cff887799",green="|cff44ff88",red="|cffff5555"}
    }
end


DelveTracker:RegisterPlugin("ExchangeBot", function() end)

-- ============================================================
-- 0. CLASS COLOR  (resolved fresh each login)
-- ============================================================
local _, classFile = UnitClass("player")
local cc = RAID_CLASS_COLORS[classFile] or { r=0.55, g=0.2, b=1.0, colorStr="ff8833ff" }

-- ============================================================
-- 1. MAIN FRAME
-- ============================================================
local EB = CreateFrame("Frame", "DT_ExchangeFrame", UIParent, "BackdropTemplate")
EB:SetSize(820, 940)
EB:SetPoint("CENTER")
EB:SetFrameStrata("HIGH")
EB:SetMovable(true)
EB:EnableMouse(true)
EB:RegisterForDrag("LeftButton")
EB:SetClampedToScreen(true)    -- Phase 2: ClampedToScreen (12.0.x standard)
EB:Hide()
EB:SetScript("OnDragStart", EB.StartMoving)
EB:SetScript("OnDragStop",  EB.StopMovingOrSizing)

-- Thin invisible edge so backdrop border works
EB:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
EB:SetBackdropBorderColor(0, 0, 0, 0)

-- Background: near-black vertical gradient
local bg = EB:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
bg:SetGradient("VERTICAL",
    CreateColor(0.07, 0.07, 0.10, 0.97),
    CreateColor(0.02, 0.02, 0.04, 0.99)
)

-- Utility: build a coloured texture stripe (border lines)
local function MakeLine(parent, layer, h, w, r, g, b, a)
    local t = parent:CreateTexture(nil, layer)
    if h then t:SetHeight(h) else t:SetWidth(w) end
    t:SetColorTexture(r, g, b, a)
    return t
end

-- Purple border lines (top/bottom bright, sides dimmer)
local bTop = MakeLine(EB, "OVERLAY", 2, nil, 0.55, 0, 0.9, 1)
bTop:SetPoint("TOPLEFT", 1, -1); bTop:SetPoint("TOPRIGHT", -1, -1)
local bBot = MakeLine(EB, "OVERLAY", 2, nil, 0.55, 0, 0.9, 1)
bBot:SetPoint("BOTTOMLEFT", 1, 1); bBot:SetPoint("BOTTOMRIGHT", -1, 1)
local bL = MakeLine(EB, "OVERLAY", nil, 2, 0.35, 0, 0.65, 0.9)
bL:SetPoint("TOPLEFT", 1, -1); bL:SetPoint("BOTTOMLEFT", 1, 1)
local bR = MakeLine(EB, "OVERLAY", nil, 2, 0.35, 0, 0.65, 0.9)
bR:SetPoint("TOPRIGHT", -1, -1); bR:SetPoint("BOTTOMRIGHT", -1, 1)

-- Subtle class-color inner glow along top
local glowTop = EB:CreateTexture(nil, "BORDER")
glowTop:SetPoint("TOPLEFT", 3, -3); glowTop:SetPoint("TOPRIGHT", -3, -3)
glowTop:SetHeight(2)
glowTop:SetColorTexture(cc.r, cc.g, cc.b, 0.35)

-- ============================================================
-- 2. CLOSE BUTTON
-- ============================================================
local closeBtn = CreateFrame("Button", nil, EB, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function() EB:Hide() end)

-- ============================================================
-- 3. HEADER BAR - Live time / date / zone (1-second ticker)
-- ============================================================
EB.worldInfo = EB:CreateFontString(nil, "OVERLAY")
EB.worldInfo:SetPoint("TOP", 0, -10)

C_Timer.NewTicker(1, function()
    if EB:IsShown() then
        EB.worldInfo:SetText(string.format(
            "|cff%02x%02x%02x%s|r  -  |cffffffff%s|r  -  |cff00ff88%s|r",
            cc.r * 255, cc.g * 255, cc.b * 255,
            BetterDate("%H:%M:%S", time()),
            BetterDate("%d/%m/%Y", time()),
            GetMinimapZoneText()
        ))
    end
end)

-- ============================================================
-- 4. PORTRAIT + CHARACTER INFO
-- ============================================================
local portrait = CreateFrame("PlayerModel", nil, EB)
portrait:SetSize(90, 90)
portrait:SetPoint("TOPLEFT", 16, -22)
portrait:SetPortraitZoom(1)

-- Phase 2: GameFontNormalLarge for high readability
EB.headerText = EB:CreateFontString(nil, "OVERLAY")
EB.headerText:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
EB.headerText:SetTextColor(0.85, 0.85, 0.85, 1)
EB.headerText:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 12, -5)

EB.goldText = EB:CreateFontString(nil, "OVERLAY")
EB.goldText:SetPoint("TOPRIGHT", -50, -42)

-- ============================================================
-- 5. HEADER GRID  (6 quick-view currency/item slots)
--
--    Slot layout: [ 1 | 2 | 3 ] | [ 4 | 5 | 6 ]
--    IDs > 100000 = item  -> GetItemInfoInstant + GetItemCount
--    IDs <= 100000 = currency -> C_CurrencyInfo.GetCurrencyInfo
--
--    RESTORED to v18 original - new 12.0.5 currencies live in dataset subs.
--    DO NOT change slots without updating the extraFrames section too.
-- ============================================================
local gridIDs = {
    3028,   -- Restored Coffer Key    (slot 1)
    3310,   -- Coffer Key Shards      (slot 2)
    3376,   -- Shard of Dundun        (slot 3)
    253342, -- (item)                 (slot 4)
    252415, -- (item)                 (slot 5)
    244193, -- (item)                 (slot 6)
}
EB.gridFrames = {}

local gridContainer = CreateFrame("Frame", nil, EB)
gridContainer:SetSize(410, 45)
gridContainer:SetPoint("TOPLEFT", EB.headerText, "BOTTOMLEFT", 0, -8)

for i = 1, 6 do
    local xPos = (i <= 3) and ((i-1)*45) or ((i-4)*45 + 170)
    local f = CreateFrame("Frame", nil, gridContainer)
    f:SetSize(40, 40)
    f:SetPoint("LEFT", xPos, 0)

    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetPoint("TOPLEFT", 1, -1)
    f.tex:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Thin purple border around each icon
    local gT  = f:CreateTexture(nil, "OVERLAY"); gT:SetHeight(1)
    gT:SetPoint("TOPLEFT", 0, 0); gT:SetPoint("TOPRIGHT", 0, 0)
    gT:SetColorTexture(0.5, 0, 0.8, 0.8)
    local gB  = f:CreateTexture(nil, "OVERLAY"); gB:SetHeight(1)
    gB:SetPoint("BOTTOMLEFT", 0, 0); gB:SetPoint("BOTTOMRIGHT", 0, 0)
    gB:SetColorTexture(0.5, 0, 0.8, 0.8)
    local gLf = f:CreateTexture(nil, "OVERLAY"); gLf:SetWidth(1)
    gLf:SetPoint("TOPLEFT", 0, 0); gLf:SetPoint("BOTTOMLEFT", 0, 0)
    gLf:SetColorTexture(0.5, 0, 0.8, 0.6)
    local gRt = f:CreateTexture(nil, "OVERLAY"); gRt:SetWidth(1)
    gRt:SetPoint("TOPRIGHT", 0, 0); gRt:SetPoint("BOTTOMRIGHT", 0, 0)
    gRt:SetColorTexture(0.5, 0, 0.8, 0.6)

    f.qty = f:CreateFontString(nil, "OVERLAY")
    f.qty:SetPoint("BOTTOMRIGHT", -2, 2)

    local capturedI = i
    f:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        if gridIDs[capturedI] > 100000 then
            GameTooltip:SetItemByID(gridIDs[capturedI])
        else
            GameTooltip:SetCurrencyByID(gridIDs[capturedI])
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)
    EB.gridFrames[i] = { frame = f, id = gridIDs[i] }

    -- Visual separator between group 1 (slots 1-3) and group 2 (slots 4-6)
    if i == 3 then
        local sep = gridContainer:CreateTexture(nil, "OVERLAY")
        sep:SetSize(1, 32)
        sep:SetPoint("LEFT", 148, 0)
        sep:SetColorTexture(0.5, 0, 0.8, 0.6)
    end
end

-- ============================================================
-- 6. EXTRA HEADER ICONS - Unalloyed Abundance + Dawnlight Manaflux
--    Anchored BELOW goldText so they never overlap portrait.
--    RESTORED to v18 original: { 3377, 3378 }
--    Phase 2: icons effectively 1.5x via SetSize(33,33) vs default 22
-- ============================================================
local extraIDs = {
    3377,   -- Unalloyed Abundance  (left)  - RESTORED v18 original
    3378,   -- Dawnlight Manaflux   (right) - RESTORED v18 original
}
EB.extraFrames = {}

for i, eid in ipairs(extraIDs) do
    local ef = CreateFrame("Frame", nil, EB)
    ef:SetSize(33, 33)
    ef:SetPoint("TOPRIGHT", EB.goldText, "BOTTOMRIGHT", -(i-1)*38, -9)

    ef.tex = ef:CreateTexture(nil, "ARTWORK")
    ef.tex:SetPoint("TOPLEFT", 1, -1)
    ef.tex:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Phase 2: icons scaled to 1.5x equivalent via SetSize (33px vs 22px default)
    local eT  = ef:CreateTexture(nil, "OVERLAY"); eT:SetHeight(1)
    eT:SetPoint("TOPLEFT", 0, 0); eT:SetPoint("TOPRIGHT", 0, 0)
    eT:SetColorTexture(0.5, 0, 0.8, 0.7)
    local eB  = ef:CreateTexture(nil, "OVERLAY"); eB:SetHeight(1)
    eB:SetPoint("BOTTOMLEFT", 0, 0); eB:SetPoint("BOTTOMRIGHT", 0, 0)
    eB:SetColorTexture(0.5, 0, 0.8, 0.7)
    local eLf = ef:CreateTexture(nil, "OVERLAY"); eLf:SetWidth(1)
    eLf:SetPoint("TOPLEFT", 0, 0); eLf:SetPoint("BOTTOMLEFT", 0, 0)
    eLf:SetColorTexture(0.5, 0, 0.8, 0.5)
    local eRt = ef:CreateTexture(nil, "OVERLAY"); eRt:SetWidth(1)
    eRt:SetPoint("TOPRIGHT", 0, 0); eRt:SetPoint("BOTTOMRIGHT", 0, 0)
    eRt:SetColorTexture(0.5, 0, 0.8, 0.5)

    ef.qty = ef:CreateFontString(nil, "OVERLAY")
    ef.qty:SetPoint("BOTTOMRIGHT", -2, 2)

    local cid = eid
    ef:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_LEFT")
        GameTooltip:SetCurrencyByID(cid)
        GameTooltip:Show()
    end)
    ef:SetScript("OnLeave", GameTooltip_Hide)
    EB.extraFrames[i] = { frame = ef, id = eid }
end

-- ============================================================
-- 7. FULL DATASET
-- ============================================================
-- Each section:
--   name    = display name (string)
--   icon    = texture path (string or nil)
--   isOpen  = initial collapsed state (bool)
--   color   = { r, g, b } section accent
--   items   = array of { id, name } (flat currency list)
--   sub     = array of subsections { name, isOpen, items }
--
-- Transfer state flags from C_CurrencyInfo.GetCurrencyInfo():
--   isAccountTransferable = true  -> Warbound; right-click to send to alt
--   isAccountTransferred  = true  -> Already account-wide (no send needed)
-- ============================================================
local datasets = {

    -- ---------------------------------------------------------
    -- MIDNIGHT  (Expansion 12.0.x - current patch tier)
    -- ---------------------------------------------------------
    {
        name   = "MIDNIGHT",
        icon   = "Interface\\Icons\\Spell_Arcane_Blast",
        isOpen = true,
        color  = { r=0.65, g=0.20, b=1.00 },
        items  = {
            { id=3379, name="Brimming Arcana"    },
            { id=3385, name="Luminous Dust"      },
            { id=3376, name="Shard of Dundun"    },
            { id=3377, name="Unalloyed Abundance"},
            { id=3316, name="Voidlight Marl"     },
            { id=2803, name="Undercoin"          },
            { id=3378, name="Dawnlight Manaflux" },
        },
        sub = {
            -- -- SEASON 1 CRESTS ------------------------------
            {
                name   = "SEASON 1",
                isOpen = false,
                items  = {
                    { id=3383, name="Adventurer Dawncrest" },
                    { id=3341, name="Veteran Dawncrest"    },
                    { id=3343, name="Champion Dawncrest"   },
                    { id=3345, name="Hero Dawncrest"       },
                    { id=3347, name="Myth Dawncrest"       },
                },
            },
            -- -- PREY . RITUAL SITES . VOIDFORGE (12.0.5) ------
            -- Samengevoegd: drie kleine subsecties gecombineerd.
            -- Sources: wowhead.com/currency=3392 / 3405 / 3418
            --
            --  3392  Remnant of Anguish   -> Prey Hunts (Astalor's Sanctum)
            --         Verdien via Normal/Hard/Nightmare Prey Hunts
            --         Spend bij Construct V'anore voor mounts & cosmetics
            --
            --  3405  Field Accolade       -> Void Assaults + Ritual Sites
            --         Shared currency voor beide 12.0.5 outdoor-systemen
            --         Spend bij Maren Silverwing / Rae'ana (Silvermoon Bazaar)
            --
            --  3418  Nebulous Voidcore    -> Voidforge (bonus-roll)
            --         2/week van Decimus (Howling Ridge, Voidstorm)
            --         Kosten: 1 core (M+ / Delves / Prey) of 2 (Raid)
            {
                name   = "PREY . RITUAL SITES . VOIDFORGE",
                isOpen = false,
                items  = {
                    { id=3392, name="Remnant of Anguish" },   -- Prey Hunts currency
                    { id=3405, name="Field Accolade"     },   -- Void Assaults + Ritual Sites
                    { id=3418, name="Nebulous Voidcore"  },   -- Voidforge bonus-roll
                },
            },
        },
    },

    -- ---------------------------------------------------------
    -- THE WAR WITHIN  (10.x / 11.x legacy currencies still active)
    -- ---------------------------------------------------------
    {
        name   = "THE WAR WITHIN",
        icon   = "Interface\\Icons\\Achievement_Quests_Completed_WarsongGulch01",
        isOpen = false,
        color  = { r=0.20, g=0.70, b=1.00 },
        items  = {
            { id=3034, name="Kej"                },
            { id=2815, name="Resonance Crystals" },
            { id=3363, name="Community Coupons"  },
            { id=3310, name="Coffer Key Shards"  },
            { id=3028, name="Restored Coffer Key"},
        },
        sub = {
            {
                name   = "CRESTS / UPGRADES",
                isOpen = false,
                items  = {
                    { id=3008, name="Valorstones"     },
                    { id=2807, name="Weathered Crest" },
                    { id=2808, name="Drake's Crest"   },
                    { id=2809, name="Wyrm's Crest"    },
                    { id=2810, name="Gilded Crest"    },
                },
            },
        },
    },

    -- ---------------------------------------------------------
    -- DUNGEON & RAID
    -- ---------------------------------------------------------
    {
        name   = "DUNGEON & RAID",
        icon   = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider",
        isOpen = false,
        color  = { r=0.20, g=0.90, b=0.40 },
        items  = {
            { id=1166, name="Timewarped Badge" },
            { id=3313, name="Gallagio Loyalty" },
            { id=3314, name="Raid Speed"       },
            { id=3315, name="Gallagio Renown"  },
            { id=3317, name="Delves Renown"    },
            { id=3318, name="Delver's Journey" },
        },
    },

    -- ---------------------------------------------------------
    -- PROFESSION MOXIES
    -- ---------------------------------------------------------
    {
        name   = "PROFESSION MOXIES",
        icon   = "Interface\\Icons\\INV_Misc_Wrench_01",
        isOpen = false,
        color  = { r=0.30, g=1.00, b=0.50 },
        items  = {
            { id=3257, name="Artisan Alchemist's Moxie"      },
            { id=3258, name="Artisan Enchanter's Moxie"      },
            { id=3259, name="Artisan Engineer's Moxie"       },
            { id=3260, name="Artisan Inscriptionist's Moxie" },
            { id=3261, name="Artisan Jeweler's Moxie"        },
            { id=3262, name="Artisan Blacksmith's Moxie"     },
            { id=3263, name="Artisan Leatherworker's Moxie"  },
            { id=3264, name="Artisan Tailor's Moxie"         },
            { id=3265, name="Artisan Skinner's Moxie"        },
            { id=3266, name="Artisan Herbalist's Moxie"      },
            { id=3267, name="Artisan Miner's Moxie"          },
        },
        sub = {
            {
                name   = "PROFESSION KNOWLEDGE",
                isOpen = false,
                items  = {
                    { id=2785, name="Alchemy Knowledge"        },
                    { id=2786, name="Blacksmithing Knowledge"  },
                    { id=2787, name="Enchanting Knowledge"     },
                    { id=2788, name="Engineering Knowledge"    },
                    { id=2790, name="Inscription Knowledge"    },
                    { id=2791, name="Jewelcrafting Knowledge"  },
                    { id=2792, name="Leatherworking Knowledge" },
                    { id=2793, name="Mining Knowledge"         },
                    { id=2794, name="Skinning Knowledge"       },
                    { id=2795, name="Tailoring Knowledge"      },
                },
            },
        },
    },

    -- ---------------------------------------------------------
    -- PvP
    -- ---------------------------------------------------------
    {
        name   = "PvP",
        icon   = "Interface\\Icons\\Achievement_PVP_A_01",
        isOpen = false,
        color  = { r=1.00, g=0.20, b=0.20 },
        items  = {
            { id=1792, name="Honor"         },
            { id=1602, name="Conquest"      },
            { id=2123, name="Bloody Tokens" },
        },
    },

    -- ---------------------------------------------------------
    -- EVENTS & MISC
    -- ---------------------------------------------------------
    {
        name   = "EVENTS & MISC",
        icon   = "Interface\\Icons\\INV_Misc_Ticket_Darkmoon_01",
        isOpen = false,
        color  = { r=1.00, g=0.70, b=0.00 },
        items  = {
            { id=515,  name="Darkmoon Prize Ticket" },
            { id=2032, name="Trader's Tender"       },
            { id=2777, name="Artisan's Mettle"      },
        },
    },

    -- ---------------------------------------------------------
    -- LEGACY  (all sub-sections closed by default)
    -- ---------------------------------------------------------
    {
        name   = "LEGACY",
        icon   = "Interface\\Icons\\Achievement_Quests_Completed_Daily",
        isOpen = false,
        color  = { r=0.65, g=0.45, b=0.20 },
        sub = {
            {
                name   = "DRAGONFLIGHT",
                isOpen = false,
                items  = {
                    { id=2003, name="Dragon Isles Supplies" },
                    { id=2118, name="Elemental Overflow"    },
                    { id=2122, name="Storm Sigil"           },
                    { id=2245, name="Flightstones"          },
                    { id=2594, name="Paracausal Flakes"     },
                },
            },
            {
                name   = "SHADOWLANDS",
                isOpen = false,
                items  = {
                    { id=1828, name="Soul Ash"          },
                    { id=1906, name="Soul Cinders"      },
                    { id=1767, name="Stygia"            },
                    { id=1885, name="Grateful Offering" },
                    { id=1977, name="Cosmic Flux"       },
                    { id=1813, name="Reservoir Anima"   },
                },
            },
            {
                name   = "BATTLE FOR AZEROTH",
                isOpen = false,
                items  = {
                    { id=1560, name="War Resources"            },
                    { id=1717, name="7th Legion Service Medal" },
                    { id=1716, name="Honorbound Service Medal" },
                    { id=1718, name="Titan Residuum"           },
                    { id=1710, name="Seafarer's Dubloon"       },
                },
            },
            {
                name   = "LEGION",
                isOpen = false,
                items  = {
                    { id=1220, name="Order Resources"      },
                    { id=1155, name="Ancient Mana"         },
                    { id=1226, name="Nethershard"          },
                    { id=1275, name="Curious Coin"         },
                    { id=1508, name="Veiled Argunite"      },
                    { id=1533, name="Wakening Essence"     },
                },
            },
            {
                name   = "WARLORDS OF DRAENOR",
                isOpen = false,
                items  = {
                    { id=823,  name="Apexis Crystal"     },
                    { id=824,  name="Garrison Resources" },
                    { id=980,  name="Dingy Iron Coins"   },
                },
            },
            {
                name   = "MISTS OF PANDARIA",
                isOpen = false,
                items  = {
                    { id=777, name="Timeless Coin"                },
                    { id=776, name="Warforged Seal"               },
                    { id=738, name="Lesser Charm of Good Fortune" },
                    { id=697, name="Elder Charm of Good Fortune"  },
                },
            },
        },
    },
}

-- ============================================================
-- 8. SCROLL FRAME
-- ============================================================
local scrollFrame = CreateFrame("ScrollFrame", "DT_EB_Scroll", EB, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",     10, -130)
scrollFrame:SetPoint("BOTTOMRIGHT", -30,  45)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(760, 1)
scrollFrame:SetScrollChild(content)

-- ============================================================
-- 9. CURRENCY TRANSFER HELPERS
-- ============================================================

-- Status bar at bottom of frame (auto-clears after 5 s)
local statusBar = EB:CreateFontString(nil, "OVERLAY")
statusBar:SetFont("Fonts\\2002.ttf",10,"")
statusBar:SetTextColor(0.85,0.85,0.85,1)
statusBar:SetPoint("BOTTOM", 0, 47)
statusBar:SetText("")

local function ShowStatus(msg, r, g, b)
    statusBar:SetText(string.format("|cff%02x%02x%02x%s|r",
        math.floor((r or 1)*255),
        math.floor((g or 1)*255),
        math.floor((b or 0)*255), msg))
    C_Timer.After(5, function() statusBar:SetText("") end)
end

-- Open Blizzard Currency tab with fallbacks for different client builds
local function OpenTokenFrame()
    if ToggleCharacter then
        ToggleCharacter("TokenFrame")
        return
    end
    if TokenFrame and ShowUIPanel then
        ShowUIPanel(TokenFrame)
        return
    end
    if CharacterFrame then
        if not CharacterFrame:IsShown() then ShowUIPanel(CharacterFrame) end
        C_Timer.After(0.08, function()
            if CharacterFrame_ShowSubFrame then
                CharacterFrame_ShowSubFrame("TokenFrame")
            end
        end)
    end
end

-- Resolve transfer state from C_CurrencyInfo (12.0.x compatible)
local function GetTransferState(id)
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    if not info then return "unknown", 0 end
    if info.isAccountTransferred  then return "account-wide", info.quantity end
    if info.isAccountTransferable then return "transferable",  info.quantity end
    return "none", info.quantity
end

-- Right-click handler: open Currency tab or show informational status
local function OpenCurrencyTransfer(id, name)
    local state, qty = GetTransferState(id)

    if state == "account-wide" then
        ShowStatus(name .. " is account-wide - already visible on all characters.", 0.9, 0.8, 0.1)
        return
    end
    if state == "none" then
        ShowStatus(name .. " is not transferable between characters.", 1, 0.3, 0.3)
        print(string.format("|cffff5555[ExchangeBot]|r %s cannot be transferred.", name))
        return
    end
    -- transferable: open Currency tab
    OpenTokenFrame()
    ShowStatus("Currency tab opened - right-click  " .. name .. "  to choose an alt.", 0.3, 1, 0.5)
    print(string.format("|cff9966ff[ExchangeBot]|r Currency tab opened -> right-click |cffffffff%s|r (you have %d).", name, qty))
end

-- ============================================================
-- 10. BUILD ENGINE  (4-column card grid + collapsible sections)
-- ============================================================
local pool = {}

-- Tag each item with its parent section colour (for card theming)
local function TagColor(items, color)
    for _, item in ipairs(items) do item._color = color end
    return items
end

-- Draw a row of currency cards; centres an incomplete final row
local function DrawCards(items, xOff, cols, startY)
    if not items or #items == 0 then return startY end
    local y  = startY
    local cw = math.floor((750 - xOff - 20) / cols)

    for i, item in ipairs(items) do
        local row  = math.floor((i-1) / cols)
        local colI = (i-1) % cols

        -- Centre incomplete final row
        local firstOnRow = row * cols + 1
        local countOnRow = math.min(cols, #items - firstOnRow + 1)
        local offsetX    = math.floor((cols - countOnRow) * cw / 2)
        local xPos       = xOff + offsetX + colI * cw

        local key = string.format("C_%d_%d_%d", item.id, xOff, i)
        local f   = pool[key]
        if not f then
            f = CreateFrame("Frame", nil, content, "BackdropTemplate")
            -- Glow layer (tinted per section colour, brightens on hover)
            f.glow = f:CreateTexture(nil, "BACKGROUND")
            f.glow:SetAllPoints()
            -- Currency icon (trimmed tex coords to remove border)
            f.icon = f:CreateTexture(nil, "ARTWORK")
            f.icon:SetSize(32, 32)
            f.icon:SetPoint("LEFT", 6, 0)
            f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            -- Quantity: large outlined font for readability
            f.qty = f:CreateFontString(nil, "OVERLAY")
            f.qty:SetPoint("TOPLEFT", 44, -4)
            f.qty:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
            -- Currency name: smaller clean label
            f.cname = f:CreateFontString(nil, "OVERLAY")
            f.cname:SetPoint("TOPLEFT", 44, -20)
            f.cname:SetFont("Fonts\\ARIALN.TTF", 11, "")
            pool[key] = f
        end

        f:SetSize(cw - 10, 54)
        f:SetPoint("TOPLEFT", xPos, y - (row * 62))
        f:Show()

        local info   = C_CurrencyInfo.GetCurrencyInfo(item.id)
        local sc     = item._color or { r=0.5, g=0.5, b=0.5 }
        local qty    = info and info.quantity   or 0
        local iconID = info and info.iconFileID or 134400
        local state  = GetTransferState(item.id)
        local canXfer = (state == "transferable")

        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        do local _b=TH().bg.main; f:SetBackdropColor(_b.r,_b.g,_b.b,_b.a) end
        f.glow:SetColorTexture(sc.r, sc.g, sc.b, 0.05)
        f.icon:SetTexture(iconID)
        f.qty:SetText(string.format("|cff00ff88%d|r", qty))
        f.cname:SetText(string.format("|cff%02x%02x%02x%s|r",
            sc.r*210, sc.g*210, sc.b*210, item.name))
        f.cname:SetWidth(cw - 54)
        f.cname:SetJustifyH("LEFT")

        -- Capture locals for closures
        local capturedID    = item.id
        local capturedName  = item.name
        local capturedState = state

        f:SetScript("OnEnter", function(s)
            s:SetBackdropColor(sc.r*0.28, sc.g*0.28, sc.b*0.28, 0.92)
            s.glow:SetColorTexture(sc.r, sc.g, sc.b, 0.20)
            s:SetScale(1.03)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:SetCurrencyByID(capturedID)
            if canXfer then
                GameTooltip:AddLine("|cff55ff55Right-click: Transfer to alt|r")
            elseif capturedState == "account-wide" then
                GameTooltip:AddLine("|cffffcc00Account-wide - on all characters|r")
            else
                GameTooltip:AddLine("|cffff5555Not transferable|r")
            end
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function(s)
            s:SetBackdropColor(0.07, 0.07, 0.09, 0.88)
            s.glow:SetColorTexture(sc.r, sc.g, sc.b, 0.05)
            s:SetScale(1.0)
            GameTooltip_Hide()
        end)
        f:SetScript("OnMouseDown", function(_, btn)
            if btn == "RightButton" then
                OpenCurrencyTransfer(capturedID, capturedName)
            end
        end)

        if i == #items then
            y = y - (math.ceil(#items / cols) * 62) - 8
        end
    end
    return y
end

-- Main build function: re-renders entire scroll content
local function Build()
    for _, f in pairs(pool) do f:Hide() end
    local y = -12

    for _, sec in ipairs(datasets) do
        -- -- Section header ----------------------------------
        local hk = "H_" .. sec.name
        local h  = pool[hk]
        if not h then
            h = CreateFrame("Button", nil, content, "BackdropTemplate")
            h:SetSize(750, 34)
            h.bg    = h:CreateTexture(nil, "BACKGROUND"); h.bg:SetAllPoints()
            h.tline = h:CreateTexture(nil, "OVERLAY");   h.tline:SetHeight(2)
            h.tline:SetPoint("TOPLEFT"); h.tline:SetPoint("TOPRIGHT")
            h.bline = h:CreateTexture(nil, "OVERLAY");   h.bline:SetHeight(1)
            h.bline:SetPoint("BOTTOMLEFT"); h.bline:SetPoint("BOTTOMRIGHT")
            h.arrow = h:CreateFontString(nil, "OVERLAY")
            h.arrow:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
            h.arrow:SetTextColor(0.85, 0.85, 0.85, 1)
            h.arrow:SetPoint("LEFT", 8, 0)
            h.label = h:CreateFontString(nil, "OVERLAY")
            h.label:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
            h.label:SetTextColor(0.85, 0.85, 0.85, 1)
            h.label:SetPoint("LEFT", 22, 0)
            pool[hk] = h
        end
        h:SetPoint("TOPLEFT", 5, y); h:Show()
        h.bg:SetColorTexture(0, 0, 0, 0.58)
        h.tline:SetColorTexture(sec.color.r, sec.color.g, sec.color.b, 0.70)
        h.bline:SetColorTexture(sec.color.r*0.35, sec.color.g*0.35, sec.color.b*0.35, 0.45)
        h.arrow:SetText(sec.isOpen and "|cff888888v|r" or "|cff888888▸|r")

        local iconStr = sec.icon and string.format("|T%s:20:20:2:0|t ", sec.icon) or "  "
        h.label:SetText(string.format("%s|cff%02x%02x%02x%s|r",
            iconStr,
            sec.color.r*255, sec.color.g*255, sec.color.b*255,
            sec.name))
        h:SetScript("OnClick", function() sec.isOpen = not sec.isOpen; Build() end)
        y = y - 40

        if sec.isOpen then
            -- Flat items (no subsection)
            if sec.items then
                y = DrawCards(TagColor(sec.items, sec.color), 15, 4, y)
                y = y - 4
            end
            -- Subsections
            if sec.sub then
                for _, sub in ipairs(sec.sub) do
                    -- -- Sub-section header --------------------
                    local sk = "S_" .. sec.name .. "_" .. sub.name
                    local sh = pool[sk]
                    if not sh then
                        sh = CreateFrame("Button", nil, content, "BackdropTemplate")
                        sh:SetSize(720, 26)
                        sh.bg    = sh:CreateTexture(nil, "BACKGROUND"); sh.bg:SetAllPoints()
                        sh.tline = sh:CreateTexture(nil, "OVERLAY");    sh.tline:SetHeight(1)
                        sh.tline:SetPoint("TOPLEFT"); sh.tline:SetPoint("TOPRIGHT")
                        sh.bline = sh:CreateTexture(nil, "OVERLAY");    sh.bline:SetHeight(1)
                        sh.bline:SetPoint("BOTTOMLEFT"); sh.bline:SetPoint("BOTTOMRIGHT")
                        sh.arrow = sh:CreateFontString(nil, "OVERLAY")
                        sh.arrow:SetFont("Fonts\\2002.ttf", 12, "")
                        sh.arrow:SetTextColor(0.85, 0.85, 0.85, 1)
                        sh.arrow:SetPoint("LEFT", 8, 0)
                        sh.label = sh:CreateFontString(nil, "OVERLAY")
                        sh.label:SetFont("Fonts\\2002.ttf", 12, "")
                        sh.label:SetTextColor(0.85, 0.85, 0.85, 1)
                        sh.label:SetPoint("LEFT", 22, 0)
                        pool[sk] = sh
                    end
                    sh:SetPoint("TOPLEFT", 30, y); sh:Show()
                    sh.bg:SetColorTexture(0, 0, 0, 0.35)
                    sh.tline:SetColorTexture(sec.color.r*0.6, sec.color.g*0.6, sec.color.b*0.6, 0.65)
                    sh.bline:SetColorTexture(sec.color.r*0.25, sec.color.g*0.25, sec.color.b*0.25, 0.35)
                    sh.arrow:SetText(sub.isOpen and "|cff666666v|r" or "|cff666666▸|r")
                    sh.label:SetText(string.format("|cff%02x%02x%02x%s|r",
                        sec.color.r*180, sec.color.g*180, sec.color.b*180, sub.name))
                    sh:SetScript("OnClick", function() sub.isOpen = not sub.isOpen; Build() end)
                    y = y - 30

                    if sub.isOpen then
                        y = DrawCards(TagColor(sub.items, sec.color), 46, 4, y)
                        y = y - 4
                    end
                end
            end
        end
        y = y - 8
    end
    content:SetHeight(math.abs(y) + 60)
end

-- ============================================================
-- 11. CUSTOM DARK BUTTON FACTORY
--     Avoids UIPanelButtonTemplate's forced bronze/red look.
-- ============================================================
local function MakeDarkButton(parent, w, h, label, onClick, tooltipText)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.06, 0.04, 0.10, 0.95)
    btn:SetBackdropBorderColor(0.30, 0.10, 0.50, 0.85)

    local txt = btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont("Fonts\\2002.ttf", 12, "")
    txt:SetTextColor(0.85, 0.85, 0.85, 1)
    txt:SetAllPoints(); txt:SetJustifyH("CENTER"); txt:SetJustifyV("MIDDLE")
    txt:SetText("|cffaa88cc" .. label .. "|r")
    btn._txt = txt

    btn:SetScript("OnEnter", function(s)
        s:SetBackdropColor(0.14, 0.08, 0.22, 0.98)
        s:SetBackdropBorderColor(0.60, 0.20, 0.90, 1)
        s._txt:SetText("|cffddaaff" .. label .. "|r")
        if tooltipText then
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(tooltipText, 0.8, 0.6, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(s)
        s:SetBackdropColor(0.06, 0.04, 0.10, 0.95)
        s:SetBackdropBorderColor(0.30, 0.10, 0.50, 0.85)
        s._txt:SetText("|cffaa88cc" .. label .. "|r")
        GameTooltip_Hide()
    end)
    btn:SetScript("OnMouseDown", function(s)
        s:SetBackdropColor(0.04, 0.02, 0.08, 0.98)
        s:SetBackdropBorderColor(0.80, 0.30, 1.0, 1)
    end)
    btn:SetScript("OnMouseUp", function(s)
        s:SetBackdropColor(0.06, 0.04, 0.10, 0.95)
        s:SetBackdropBorderColor(0.30, 0.10, 0.50, 0.85)
        onClick(s)
    end)
    return btn
end

-- ============================================================
-- 12. SCALE CONTROLS   -   [ - ]  1.00x  [ + ]  [Reset]
-- ============================================================
local curScale  = 1.0
local scaleStep = 0.05

local function ApplyScale(v)
    curScale = math.max(0.5, math.min(2.0, math.floor(v * 20 + 0.5) / 20))
    EB:SetScale(curScale)
    EB.scaleLabel:SetText(string.format("%.2fx", curScale))
end

local scDown = MakeDarkButton(EB, 26, 20, "  -  ",
    function() ApplyScale(curScale - scaleStep) end, "Scale down")
scDown:SetPoint("BOTTOMLEFT", 12, 12)

EB.scaleLabel = EB:CreateFontString(nil, "OVERLAY")
EB.scaleLabel:SetFont("Fonts\\2002.ttf",10,"")
EB.scaleLabel:SetTextColor(0.85,0.85,0.85,1)
EB.scaleLabel:SetPoint("BOTTOMLEFT", 42, 15)
EB.scaleLabel:SetWidth(50); EB.scaleLabel:SetJustifyH("CENTER")
EB.scaleLabel:SetText("|cff8866aa1.00x|r")

local scUp = MakeDarkButton(EB, 26, 20, "  +  ",
    function() ApplyScale(curScale + scaleStep) end, "Scale up")
scUp:SetPoint("BOTTOMLEFT", 96, 12)

local scReset = MakeDarkButton(EB, 48, 20, "Reset",
    function() ApplyScale(1.0) end, "Reset scale to 1.00x")
scReset:SetPoint("BOTTOMLEFT", 126, 12)

local verLabel = EB:CreateFontString(nil, "OVERLAY")
verLabel:SetFont("Fonts\\2002.ttf",9,"")
verLabel:SetTextColor(0.85,0.85,0.85,1)
verLabel:SetPoint("BOTTOMLEFT", 185, 15)
verLabel:SetText("|cff28183aExchangeBot v19.0|r")

-- ============================================================
-- 13. CURRENCY TRANSFER BUTTON  (bottom-right)
-- ============================================================
local wbBtn = MakeDarkButton(EB, 160, 20,
    "  Currency Transfer",
    function()
        OpenTokenFrame()
        ShowStatus("Currency tab opened - right-click any Warbound currency to transfer.", 0.5, 0.9, 1)
    end,
    "Opens Character -> Currency tab.\nRight-click a Warbound currency to send it to an alt.")
wbBtn:SetPoint("BOTTOMRIGHT", -14, 12)
wbBtn._txt:SetText("|TInterface\\GossipFrame\\BankerGossipIcon:13:13:0:0|t  |cffaa88ccCurrency Transfer|r")

-- ============================================================
-- 14. ON SHOW - refresh all dynamic data
-- ============================================================
local function RefreshGrid()
    for _, gd in ipairs(EB.gridFrames) do
        local id        = gd.id
        local icon, qty = 134400, 0
        if id > 100000 then
            icon = select(5, GetItemInfoInstant(id)) or 134400
            qty  = GetItemCount(id, true) or 0
        else
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            icon = info and info.iconFileID or 134400
            qty  = info and info.quantity   or 0
        end
        gd.frame.tex:SetTexture(icon)
        gd.frame.qty:SetText(qty)
    end
end

EB:SetScript("OnShow", function()
    local _, cf = UnitClass("player")
    local nc = RAID_CLASS_COLORS[cf] or cc

    glowTop:SetColorTexture(nc.r * 0.55, nc.g * 0.15, nc.b, 0.28)
    portrait:SetUnit("player"); portrait:SetPortraitZoom(1)

    RefreshGrid()
    EB:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    EB:SetScript("OnEvent", function(_, evt)
        if evt == "GET_ITEM_INFO_RECEIVED" then RefreshGrid() end
    end)

    for _, ed in ipairs(EB.extraFrames) do
        local info = C_CurrencyInfo.GetCurrencyInfo(ed.id)
        ed.frame.tex:SetTexture(info and info.iconFileID or 134400)
        ed.frame.qty:SetText(info and info.quantity or 0)
    end

    EB.headerText:SetText(string.format(
        "|c%s%s|r\n|cffffffffiLvl %.1f|r",
        nc.colorStr, UnitName("player"),
        select(2, GetAverageItemLevel())
    ))
    EB.goldText:SetText(GetCoinTextureString(GetMoney()))
    Build()
end)

-- ============================================================
-- 15. SLASH COMMANDS
-- ============================================================
-- Default open/closed states (used by /cureset)
-- Default open/closed per sectie (gebruikt door /cureset).
-- Alleen MIDNIGHT staat standaard open; alle andere secties gesloten.
local defaults = {
    ["MIDNIGHT"]          = true,
    ["THE WAR WITHIN"]    = false,
    ["DUNGEON & RAID"]    = false,
    ["PROFESSION MOXIES"] = false,
    ["PvP"]               = false,
    ["EVENTS & MISC"]     = false,
    ["LEGACY"]            = false,
}
-- subDefaults: used by /cureset to restore initial open/closed states.
-- Alle subsecties standaard gesloten; alleen op expliciete request openen.
local subDefaults = {
    ["SEASON 1"]                     = false,
    ["PREY . RITUAL SITES . VOIDFORGE"] = false,
    ["CRESTS / UPGRADES"]            = false,
    ["PROFESSION KNOWLEDGE"]         = false,
    -- LEGACY subs: allemaal gesloten (niet vermeld = false)
}

local function ResetToDefaults()
    ApplyScale(1.0)
    for _, sec in ipairs(datasets) do
        sec.isOpen = (defaults[sec.name] == true)
        if sec.sub then
            for _, sub in ipairs(sec.sub) do
                sub.isOpen = (subDefaults[sub.name] == true)
            end
        end
    end
    if EB:IsShown() then Build() end
    print("|cff9966ff[ExchangeBot]|r Settings reset to defaults.")
end

-- /cbot - toggle panel
SLASH_CBOT1 = "/cbot"
SlashCmdList["CBOT"] = function()
    if EB:IsShown() then EB:Hide() else EB:Show() end
end

-- /cureset - reset scale + all section states to defaults
SLASH_CURESET1 = "/cureset"
SlashCmdList["CURESET"] = function()
    ResetToDefaults()
    if not EB:IsShown() then EB:Show() end
end