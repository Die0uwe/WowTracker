-- ============================================================================
-- DT_Theme.lua - WowTracker Centraal Theme Systeem
-- Retail 12.0.7 / Midnight (Interface 120007)
-- v1.0.0 - 2026-06-09
--
-- MOET als EERSTE worden geladen in WowTracker.xml (voor alle plugins)
-- Alle DT_ files refereren: WTTheme.c.gold, WTTheme.c.purple etc.
--
-- Gebruik:
--   WTTheme.c.gold    -> color string  "|cffccaa00"
--   WTTheme.r.gold    -> {r,g,b} table {r=0.80,g=0.67,b=0.00}
--   WTTheme.Apply(frame, "border") -> zet backdrop border kleur
--   WTTheme.SetActiveTheme("Midnight Dark") -> wissel theme
-- ============================================================================

local addonName, addonTable = ...

-- ============================================================================
-- THEME DEFINITIES
-- ============================================================================
local THEMES = {

    -- -- Slayer Alliance (default) ------------------------------------------
    ["Slayer Alliance"] = {
        -- Kleur strings (gebruik in FontString:SetText)
        c = {
            gold      = "|cffccaa00",
            purple    = "|cffbf00ff",
            blue      = "|cff00dfff",
            grey      = "|cff887799",
            green     = "|cff44ff88",
            red       = "|cffff5555",
            orange    = "|cffff8800",
            white     = "|cffffffff",
        },
        -- RGB tables (gebruik in SetBackdropColor / SetColorTexture)
        r = {
            gold      = {r=0.80, g=0.67, b=0.00},
            purple    = {r=0.75, g=0.00, b=1.00},
            blue      = {r=0.00, g=0.87, b=1.00},
            grey      = {r=0.53, g=0.47, b=0.60},
            green     = {r=0.27, g=1.00, b=0.53},
            red       = {r=1.00, g=0.33, b=0.33},
            orange    = {r=1.00, g=0.53, b=0.00},
            white     = {r=1.00, g=1.00, b=1.00},
        },
        -- Achtergrond kleuren (SetBackdropColor)
        bg = {
            main      = {r=0.04, g=0.02, b=0.06, a=0.97},  -- hoofd frame
            header    = {r=0.08, g=0.04, b=0.12, a=1.00},  -- header balk
            card      = {r=0.06, g=0.03, b=0.09, a=0.95},  -- kaartjes
            cardHover = {r=0.12, g=0.05, b=0.18, a=0.95},  -- hover state
            row       = {r=0.05, g=0.02, b=0.08, a=0.90},  -- list rows
            rowHover  = {r=0.10, g=0.04, b=0.14, a=0.90},
            input     = {r=0.04, g=0.02, b=0.06, a=1.00},  -- editboxen
            bountyNem = {r=0.12, g=0.02, b=0.18, a=0.95},  -- Nemesis tile
            bountyBou = {r=0.10, g=0.04, b=0.14, a=0.95},  -- Bountiful tile
            bountyNor = {r=0.03, g=0.07, b=0.18, a=0.94},  -- Normal tile
        },
        -- Border kleuren (SetBackdropBorderColor)
        border = {
            main      = {r=0.45, g=0.05, b=0.75, a=0.90},  -- hoofd frame
            card      = {r=0.30, g=0.05, b=0.50, a=0.70},  -- kaartjes
            active    = {r=0.60, g=0.15, b=0.90, a=1.00},  -- actief/geselecteerd
            subtle    = {r=0.15, g=0.05, b=0.25, a=0.50},  -- subtiel
            nemesis   = {r=0.60, g=0.10, b=0.80, a=1.00},  -- Nemesis tab
            bountiful = {r=0.45, g=0.10, b=0.65, a=1.00},  -- Bountiful tab
            normal    = {r=0.10, g=0.20, b=0.50, a=1.00},  -- Normal tab
        },
        -- Tab kleuren (active/inactive)
        tab = {
            active_bg     = {r=0.12, g=0.05, b=0.20, a=1.00},
            active_border = {r=0.60, g=0.15, b=0.90, a=1.00},
            inactive_bg   = {r=0.06, g=0.03, b=0.10, a=1.00},
            inactive_border = {r=0.20, g=0.05, b=0.30, a=0.70},
        },
        -- Font
        font = "Fonts\\2002.ttf",
    },

    -- -- Midnight Dark (alternatief) ----------------------------------------
    ["Midnight Dark"] = {
        c = {
            gold      = "|cffccaa00",
            purple    = "|cff8866cc",
            blue      = "|cff4488ff",
            grey      = "|cff778899",
            green     = "|cff44cc66",
            red       = "|cffcc4444",
            orange    = "|cffcc7700",
            white     = "|cffffffff",
        },
        r = {
            gold      = {r=0.80, g=0.67, b=0.00},
            purple    = {r=0.53, g=0.40, b=0.80},
            blue      = {r=0.27, g=0.53, b=1.00},
            grey      = {r=0.47, g=0.53, b=0.60},
            green     = {r=0.27, g=0.80, b=0.40},
            red       = {r=0.80, g=0.27, b=0.27},
            orange    = {r=0.80, g=0.47, b=0.00},
            white     = {r=1.00, g=1.00, b=1.00},
        },
        bg = {
            main      = {r=0.03, g=0.03, b=0.05, a=0.97},
            header    = {r=0.06, g=0.06, b=0.10, a=1.00},
            card      = {r=0.05, g=0.05, b=0.08, a=0.95},
            cardHover = {r=0.08, g=0.08, b=0.14, a=0.95},
            row       = {r=0.04, g=0.04, b=0.07, a=0.90},
            rowHover  = {r=0.08, g=0.08, b=0.12, a=0.90},
            input     = {r=0.04, g=0.04, b=0.06, a=1.00},
            bountyNem = {r=0.08, g=0.04, b=0.12, a=0.95},
            bountyBou = {r=0.06, g=0.04, b=0.10, a=0.95},
            bountyNor = {r=0.03, g=0.05, b=0.10, a=0.94},
        },
        border = {
            main      = {r=0.30, g=0.25, b=0.55, a=0.80},
            card      = {r=0.20, g=0.18, b=0.35, a=0.60},
            active    = {r=0.40, g=0.35, b=0.70, a=1.00},
            subtle    = {r=0.12, g=0.10, b=0.20, a=0.40},
            nemesis   = {r=0.40, g=0.20, b=0.60, a=1.00},
            bountiful = {r=0.30, g=0.20, b=0.50, a=1.00},
            normal    = {r=0.15, g=0.20, b=0.40, a=1.00},
        },
        tab = {
            active_bg     = {r=0.08, g=0.08, b=0.14, a=1.00},
            active_border = {r=0.40, g=0.35, b=0.70, a=1.00},
            inactive_bg   = {r=0.04, g=0.04, b=0.08, a=1.00},
            inactive_border = {r=0.15, g=0.12, b=0.25, a=0.60},
        },
        font = "Fonts\\2002.ttf",
    },

    -- -- Horde Red ----------------------------------------------------------
    ["Horde Red"] = {
        c = {
            gold      = "|cffccaa00",
            purple    = "|cffcc3300",
            blue      = "|cffff8844",
            grey      = "|cff997766",
            green     = "|cff88cc44",
            red       = "|cffff2200",
            orange    = "|cffff6600",
            white     = "|cffffffff",
        },
        r = {
            gold      = {r=0.80, g=0.67, b=0.00},
            purple    = {r=0.80, g=0.20, b=0.00},
            blue      = {r=1.00, g=0.53, b=0.27},
            grey      = {r=0.60, g=0.47, b=0.40},
            green     = {r=0.53, g=0.80, b=0.27},
            red       = {r=1.00, g=0.13, b=0.00},
            orange    = {r=1.00, g=0.40, b=0.00},
            white     = {r=1.00, g=1.00, b=1.00},
        },
        bg = {
            main      = {r=0.08, g=0.02, b=0.02, a=0.97},
            header    = {r=0.14, g=0.03, b=0.03, a=1.00},
            card      = {r=0.10, g=0.02, b=0.02, a=0.95},
            cardHover = {r=0.18, g=0.04, b=0.04, a=0.95},
            row       = {r=0.08, g=0.02, b=0.02, a=0.90},
            rowHover  = {r=0.16, g=0.04, b=0.04, a=0.90},
            input     = {r=0.08, g=0.02, b=0.02, a=1.00},
            bountyNem = {r=0.18, g=0.03, b=0.03, a=0.95},
            bountyBou = {r=0.14, g=0.04, b=0.02, a=0.95},
            bountyNor = {r=0.06, g=0.04, b=0.10, a=0.94},
        },
        border = {
            main      = {r=0.70, g=0.10, b=0.05, a=0.90},
            card      = {r=0.50, g=0.08, b=0.04, a=0.70},
            active    = {r=0.90, g=0.15, b=0.05, a=1.00},
            subtle    = {r=0.25, g=0.05, b=0.03, a=0.50},
            nemesis   = {r=0.80, g=0.10, b=0.05, a=1.00},
            bountiful = {r=0.65, g=0.10, b=0.05, a=1.00},
            normal    = {r=0.20, g=0.15, b=0.40, a=1.00},
        },
        tab = {
            active_bg     = {r=0.18, g=0.04, b=0.02, a=1.00},
            active_border = {r=0.90, g=0.15, b=0.05, a=1.00},
            inactive_bg   = {r=0.08, g=0.02, b=0.02, a=1.00},
            inactive_border = {r=0.30, g=0.06, b=0.03, a=0.70},
        },
        font = "Fonts\\2002.ttf",
    },
}

-- ============================================================================
-- EXTRA THEMES - Industrial, Elven, Void (icon sheet 2026-06-10)
-- ============================================================================
THEMES["Industrial"] = {
    bg = {
        main      = {r=0.12, g=0.07, b=0.03, a=0.97},
        header    = {r=0.18, g=0.10, b=0.04, a=1.00},
        card      = {r=0.15, g=0.09, b=0.04, a=0.95},
        cardHover = {r=0.22, g=0.13, b=0.06, a=0.95},
        row       = {r=0.14, g=0.08, b=0.04, a=0.90},
    },
    border = {
        main   = {r=0.75, g=0.45, b=0.15, a=0.90},
        card   = {r=0.55, g=0.32, b=0.10, a=0.75},
        active = {r=0.95, g=0.65, b=0.25, a=1.00},
        subtle = {r=0.35, g=0.20, b=0.05, a=0.50},
    },
    c = {
        gold    = "|cffe8a040",
        purple  = "|cffcb8030",
        blue    = "|cffcc8833",
        grey    = "|cff887766",
        green   = "|cffaa7733",
        red     = "|cffdd4422",
    },
    stripe = {r=0.85, g=0.50, b=0.15, a=1.0},
    font   = "Fonts\\2002.ttf",
}

THEMES["Elven"] = {
    bg = {
        main      = {r=0.03, g=0.10, b=0.05, a=0.97},
        header    = {r=0.04, g=0.14, b=0.07, a=1.00},
        card      = {r=0.04, g=0.12, b=0.06, a=0.95},
        cardHover = {r=0.07, g=0.18, b=0.09, a=0.95},
        row       = {r=0.03, g=0.10, b=0.05, a=0.90},
    },
    border = {
        main   = {r=0.45, g=0.75, b=0.45, a=0.90},
        card   = {r=0.30, g=0.55, b=0.30, a=0.75},
        active = {r=0.70, g=0.95, b=0.70, a=1.00},
        subtle = {r=0.15, g=0.35, b=0.15, a=0.50},
    },
    c = {
        gold   = "|cff99cc55",
        purple = "|cff55bb55",
        blue   = "|cff88ddaa",
        grey   = "|cff667766",
        green  = "|cff44cc66",
        red    = "|cffcc5544",
    },
    stripe = {r=0.35, g=0.85, b=0.45, a=1.0},
    font   = "Fonts\\2002.ttf",
}

THEMES["Void"] = {
    bg = {
        main      = {r=0.02, g=0.01, b=0.06, a=0.99},
        header    = {r=0.03, g=0.01, b=0.08, a=1.00},
        card      = {r=0.03, g=0.01, b=0.07, a=0.97},
        cardHover = {r=0.06, g=0.02, b=0.12, a=0.97},
        row       = {r=0.03, g=0.01, b=0.06, a=0.90},
    },
    border = {
        main   = {r=0.20, g=0.10, b=0.45, a=0.85},
        card   = {r=0.12, g=0.06, b=0.30, a=0.70},
        active = {r=0.55, g=0.35, b=0.90, a=1.00},
        subtle = {r=0.08, g=0.04, b=0.20, a=0.50},
    },
    c = {
        gold   = "|cff9966cc",
        purple = "|cff8855ee",
        blue   = "|cff6677ee",
        grey   = "|cff556677",
        green  = "|cff4455aa",
        red    = "|cff994488",
    },
    stripe = {r=0.40, g=0.15, b=0.85, a=1.0},
    font   = "Fonts\\2002.ttf",
}

-- ── Scrollwork (Red/Brass) - icon sheet rij 4 ─────────────────────────────
THEMES["Scrollwork"] = {
    bg = {
        main      = {r=0.10, g=0.02, b=0.02, a=0.97},
        header    = {r=0.15, g=0.03, b=0.03, a=1.00},
        card      = {r=0.12, g=0.03, b=0.03, a=0.95},
        cardHover = {r=0.18, g=0.05, b=0.05, a=0.95},
        row       = {r=0.10, g=0.02, b=0.02, a=0.90},
    },
    border = {
        main   = {r=0.70, g=0.45, b=0.10, a=0.90},  -- messing/brass
        card   = {r=0.50, g=0.30, b=0.08, a=0.75},
        active = {r=0.95, g=0.65, b=0.15, a=1.00},  -- gold highlight
        subtle = {r=0.30, g=0.15, b=0.04, a=0.50},
    },
    c = {
        gold   = "|cffcc8822",
        purple = "|cffff4433",
        blue   = "|cffdd7744",
        grey   = "|cff997766",
        green  = "|cffaa6633",
        red    = "|cffff3322",
    },
    stripe = {r=0.85, g=0.30, b=0.10, a=1.0},
    font   = "Fonts\\2002.ttf",
}

-- ── Crystal (Blue/White) - icon sheet rij 5 ──────────────────────────────
THEMES["Crystal"] = {
    bg = {
        main      = {r=0.03, g=0.05, b=0.12, a=0.97},
        header    = {r=0.04, g=0.07, b=0.16, a=1.00},
        card      = {r=0.04, g=0.06, b=0.14, a=0.95},
        cardHover = {r=0.07, g=0.10, b=0.20, a=0.95},
        row       = {r=0.03, g=0.05, b=0.12, a=0.90},
    },
    border = {
        main   = {r=0.35, g=0.65, b=0.95, a=0.90},  -- ijsblauw
        card   = {r=0.20, g=0.45, b=0.75, a=0.75},
        active = {r=0.65, g=0.88, b=1.00, a=1.00},  -- kristal wit-blauw
        subtle = {r=0.10, g=0.25, b=0.50, a=0.50},
    },
    c = {
        gold   = "|cff88ccff",
        purple = "|cff5599ee",
        blue   = "|cffaaddff",
        grey   = "|cff6688aa",
        green  = "|cff55aacc",
        red    = "|cff3366cc",
    },
    stripe = {r=0.45, g=0.75, b=1.00, a=1.0},
    font   = "Fonts\\2002.ttf",
}

-- ============================================================================
-- WTTheme PUBLIC API
-- ============================================================================
WTTheme = {}

-- Actief theme (geladen uit DB of default)
local _activeTheme = "Slayer Alliance"

-- Geregistreerde frames voor live reload
local _registeredFrames = {}

-- -- Intern: theme ophalen --------------------------------------------------
local function GetTheme()
    return THEMES[_activeTheme] or THEMES["Slayer Alliance"]
end

-- -- Kleur strings ----------------------------------------------------------
WTTheme.c = setmetatable({}, {
    __index = function(_, k)
        return GetTheme().c[k] or "|cffffffff"
    end
})

-- -- RGB tables ------------------------------------------------------------
WTTheme.r = setmetatable({}, {
    __index = function(_, k)
        return GetTheme().r[k] or {r=1,g=1,b=1}
    end
})

-- -- Background tables -----------------------------------------------------
WTTheme.bg = setmetatable({}, {
    __index = function(_, k)
        return GetTheme().bg[k] or {r=0,g=0,b=0,a=0.95}
    end
})

-- -- Border tables ---------------------------------------------------------
WTTheme.border = setmetatable({}, {
    __index = function(_, k)
        return GetTheme().border[k] or {r=0.3,g=0.1,b=0.5,a=0.8}
    end
})

-- -- Tab tables ------------------------------------------------------------
WTTheme.tab = setmetatable({}, {
    __index = function(_, k)
        return GetTheme().tab[k] or {r=0.06,g=0.03,b=0.10,a=1}
    end
})

-- -- Font ------------------------------------------------------------------
function WTTheme.Font()
    return GetTheme().font or "Fonts\\2002.ttf"
end

-- -- Actief theme naam -----------------------------------------------------
function WTTheme.GetActive()
    return _activeTheme
end

-- -- Alle beschikbare themes -----------------------------------------------
function WTTheme.GetThemeNames()
    local names = {}
    for k in pairs(THEMES) do table.insert(names, k) end
    table.sort(names)
    return names
end

-- -- Theme wisselen --------------------------------------------------------
function WTTheme.SetActiveTheme(name)
    if not THEMES[name] then return false end
    _activeTheme = name
    -- Opslaan in DB
    if WowTrackerDB then
        WowTrackerDB.activeTheme = name
    end
    -- Live reload alle geregistreerde frames
    for _, callback in ipairs(_registeredFrames) do
        pcall(callback)
    end
    return true
end

-- -- Frame registreren voor live theme reload ------------------------------
function WTTheme.Register(callback)
    if type(callback) == "function" then
        table.insert(_registeredFrames, callback)
    end
end

-- -- Helper: backdrop border snel zetten -----------------------------------
function WTTheme.ApplyBorder(frame, borderKey)
    local b = WTTheme.border[borderKey or "card"]
    if frame and frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(b.r, b.g, b.b, b.a or 1)
    end
end

-- -- Helper: backdrop background snel zetten -------------------------------
function WTTheme.ApplyBg(frame, bgKey)
    local b = WTTheme.bg[bgKey or "card"]
    if frame and frame.SetBackdropColor then
        frame:SetBackdropColor(b.r, b.g, b.b, b.a or 0.95)
    end
end

-- -- Helper: FontString kleur snel zetten ----------------------------------
function WTTheme.ColorText(fs, colorKey, text)
    if fs and fs.SetText then
        fs:SetText((WTTheme.c[colorKey] or "|cffffffff") .. (text or "") .. "|r")
    end
end

-- -- Initialisatie: laad DB theme bij login --------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Herstel opgeslagen theme
        if WowTrackerDB and WowTrackerDB.activeTheme then
            local saved = WowTrackerDB.activeTheme
            if THEMES[saved] then
                _activeTheme = saved
            end
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- ============================================================================
-- LEGACY COMPATIBILITEIT
-- Oude code gebruikt SA_GOLD, SA_PURPLE, SA_BLUE - blijven werken
-- maar zijn nu dynamisch (wisselen mee met theme)
-- NOTE: core WowTracker.lua definieert deze als locals - die blijven static.
-- Plugins die WTTheme gebruiken moeten WTTheme.c.gold etc gebruiken.
-- ============================================================================

-- ============================================================================
-- File card
-- ============================================================================
--[[
  File    : DT_Theme.lua
  Version : 1.0.0   Created : 2026-06-09   Updated : 2026-06-09
  Status  : New - Centraal theme systeem voor WowTracker suite
  Author  : DieOuwe . www.dieouwe.nl . discord.gg/y8Pu5qsEbQ
]]


-- ════════════════════════════════════════════════════════════════════
-- PLUGIN REGISTRATIE (wow-dt-integrator · Fase 2.1 · 2026-06-12)
-- Noop-registratie: maakt de plugin zichtbaar in het admin panel
-- (aan/uit toggle via PluginStates). Patroon identiek aan DT_Lockout.
-- ════════════════════════════════════════════════════════════════════
local _dtIntReg = CreateFrame("Frame")
_dtIntReg:RegisterEvent("PLAYER_LOGIN")
_dtIntReg:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if not (DelveTracker and DelveTracker.RegisterPlugin) then return end
    DelveTracker:RegisterPlugin("Theme", function() end)
end)
