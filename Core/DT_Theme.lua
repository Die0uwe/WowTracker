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

-- ── Alliance Blue (Blue/White) - voorheen "Crystal" - icon sheet rij 5 ──
THEMES["Alliance Blue"] = {
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


-- ── Titan Bronze (Premium) ─────────────────────────────────────────────────
THEMES["Titan Bronze"] = {
    bg = {
        main      = {r=0.09, g=0.07, b=0.04, a=0.98},
        header    = {r=0.14, g=0.10, b=0.05, a=1.00},
        card      = {r=0.11, g=0.08, b=0.04, a=0.95},
        cardHover = {r=0.20, g=0.15, b=0.07, a=0.95},
        row       = {r=0.10, g=0.07, b=0.04, a=0.90},
        rowHover  = {r=0.18, g=0.13, b=0.06, a=0.90},
        input     = {r=0.09, g=0.07, b=0.04, a=1.00},
        bountyNem = {r=0.18, g=0.10, b=0.04, a=0.95},
        bountyBou = {r=0.14, g=0.10, b=0.05, a=0.95},
        bountyNor = {r=0.08, g=0.08, b=0.10, a=0.94},
    },
    border = {
        main      = {r=0.72, g=0.52, b=0.22, a=0.90},
        card      = {r=0.55, g=0.38, b=0.14, a=0.75},
        active    = {r=0.95, g=0.78, b=0.38, a=1.00},
        subtle    = {r=0.32, g=0.22, b=0.08, a=0.52},
        nemesis   = {r=0.90, g=0.55, b=0.15, a=1.00},
        bountiful = {r=0.78, g=0.58, b=0.18, a=1.00},
        normal    = {r=0.45, g=0.40, b=0.55, a=1.00},
    },
    tab = {
        active_bg     = {r=0.20, g=0.14, b=0.06, a=1.00},
        active_border = {r=0.95, g=0.78, b=0.38, a=1.00},
        inactive_bg   = {r=0.09, g=0.07, b=0.04, a=1.00},
        inactive_border = {r=0.45, g=0.30, b=0.10, a=0.70},
    },
    c = {
        gold   = "|cffddaa44",
        purple = "|cffcc9922",
        blue   = "|cffe8c060",
        grey   = "|cff998866",
        green  = "|cff88aa44",
        red    = "|cffcc5522",
        orange = "|cffff8833",
        white  = "|cffffffff",
    },
    r = {
        gold   = {r=0.87, g=0.67, b=0.27},
        purple = {r=0.80, g=0.60, b=0.13},
        blue   = {r=0.91, g=0.75, b=0.38},
        grey   = {r=0.60, g=0.53, b=0.40},
        green  = {r=0.53, g=0.67, b=0.27},
        red    = {r=0.80, g=0.33, b=0.13},
        white  = {r=1.00, g=1.00, b=1.00},
    },
    stripe = {r=0.91, g=0.72, b=0.30, a=1.0},
    font   = "Fonts\\2002.ttf",
}

-- ── Void Reborn (Premium) ──────────────────────────────────────────────────
THEMES["Void Reborn"] = {
    bg = {
        main      = {r=0.02, g=0.00, b=0.07, a=0.99},
        header    = {r=0.04, g=0.01, b=0.10, a=1.00},
        card      = {r=0.03, g=0.01, b=0.09, a=0.97},
        cardHover = {r=0.08, g=0.02, b=0.18, a=0.97},
        row       = {r=0.02, g=0.01, b=0.08, a=0.90},
        rowHover  = {r=0.07, g=0.02, b=0.16, a=0.90},
        input     = {r=0.02, g=0.00, b=0.07, a=1.00},
        bountyNem = {r=0.08, g=0.01, b=0.16, a=0.95},
        bountyBou = {r=0.06, g=0.01, b=0.13, a=0.95},
        bountyNor = {r=0.03, g=0.02, b=0.12, a=0.94},
    },
    border = {
        main      = {r=0.45, g=0.12, b=0.80, a=0.90},
        card      = {r=0.28, g=0.07, b=0.55, a=0.72},
        active    = {r=0.82, g=0.30, b=1.00, a=1.00},
        subtle    = {r=0.14, g=0.04, b=0.28, a=0.52},
        nemesis   = {r=0.70, g=0.10, b=0.90, a=1.00},
        bountiful = {r=0.50, g=0.10, b=0.75, a=1.00},
        normal    = {r=0.28, g=0.15, b=0.65, a=1.00},
    },
    tab = {
        active_bg     = {r=0.08, g=0.02, b=0.18, a=1.00},
        active_border = {r=0.82, g=0.30, b=1.00, a=1.00},
        inactive_bg   = {r=0.03, g=0.01, b=0.09, a=1.00},
        inactive_border = {r=0.28, g=0.08, b=0.50, a=0.65},
    },
    c = {
        gold   = "|cffaa55ff",
        purple = "|cffcc44ff",
        blue   = "|cff7766ff",
        grey   = "|cff445566",
        green  = "|cff3344aa",
        red    = "|cffaa2288",
        orange = "|cff8833cc",
        white  = "|cffffffff",
    },
    r = {
        gold   = {r=0.67, g=0.33, b=1.00},
        purple = {r=0.80, g=0.27, b=1.00},
        blue   = {r=0.47, g=0.40, b=1.00},
        grey   = {r=0.27, g=0.33, b=0.40},
        green  = {r=0.20, g=0.27, b=0.67},
        red    = {r=0.67, g=0.13, b=0.53},
        white  = {r=1.00, g=1.00, b=1.00},
    },
    stripe = {r=0.80, g=0.27, b=1.00, a=1.0},
    font   = "Fonts\\2002.ttf",
}

-- ── Emerald Elven (Premium) ────────────────────────────────────────────────
THEMES["Emerald Elven"] = {
    bg = {
        main      = {r=0.02, g=0.08, b=0.05, a=0.98},
        header    = {r=0.03, g=0.11, b=0.07, a=1.00},
        card      = {r=0.03, g=0.09, b=0.06, a=0.95},
        cardHover = {r=0.05, g=0.18, b=0.11, a=0.95},
        row       = {r=0.02, g=0.08, b=0.05, a=0.90},
        rowHover  = {r=0.05, g=0.16, b=0.10, a=0.90},
        input     = {r=0.02, g=0.08, b=0.05, a=1.00},
        bountyNem = {r=0.04, g=0.14, b=0.08, a=0.95},
        bountyBou = {r=0.03, g=0.12, b=0.07, a=0.95},
        bountyNor = {r=0.02, g=0.08, b=0.10, a=0.94},
    },
    border = {
        main      = {r=0.22, g=0.80, b=0.52, a=0.90},
        card      = {r=0.14, g=0.58, b=0.36, a=0.72},
        active    = {r=0.40, g=1.00, b=0.70, a=1.00},
        subtle    = {r=0.07, g=0.30, b=0.18, a=0.52},
        nemesis   = {r=0.20, g=0.90, b=0.55, a=1.00},
        bountiful = {r=0.18, g=0.78, b=0.48, a=1.00},
        normal    = {r=0.15, g=0.58, b=0.60, a=1.00},
    },
    tab = {
        active_bg     = {r=0.05, g=0.18, b=0.11, a=1.00},
        active_border = {r=0.40, g=1.00, b=0.70, a=1.00},
        inactive_bg   = {r=0.02, g=0.08, b=0.05, a=1.00},
        inactive_border = {r=0.12, g=0.42, b=0.25, a=0.65},
    },
    c = {
        gold   = "|cff55ffaa",
        purple = "|cff44dd88",
        blue   = "|cff88ffcc",
        grey   = "|cff5599aa",
        green  = "|cff33ff77",
        red    = "|cffff4455",
        orange = "|cff99dd44",
        white  = "|cffffffff",
    },
    r = {
        gold   = {r=0.33, g=1.00, b=0.67},
        purple = {r=0.27, g=0.87, b=0.53},
        blue   = {r=0.53, g=1.00, b=0.80},
        grey   = {r=0.33, g=0.60, b=0.67},
        green  = {r=0.20, g=1.00, b=0.47},
        red    = {r=1.00, g=0.27, b=0.33},
        white  = {r=1.00, g=1.00, b=1.00},
    },
    stripe = {r=0.27, g=0.95, b=0.60, a=1.0},
    font   = "Fonts\\2002.ttf",
}

-- ============================================================================
-- ICON REGISTRY — per theme, per icon slot
-- Pad: Interface\AddOns\WowTracker\Media\Icons\
-- Formaten beschikbaar: 256px (source), 32px, 28px, 20px
-- ============================================================================
local MEDIA = "Interface\\AddOns\\WowTracker\\Media\\Icons\\"

-- Icon slots die beschikbaar zijn per theme:
--   Knoppen (20px): theme, admin, language, roster, close
--   Tegels  (28px): cloth, skin, prey, vault, warbank, debug
--
-- Naamgeving bestanden: icon_{slot}_{theme}.tga
-- Voorbeeld: icon_theme_slayer_alliance.tga

local ICON_THEME_MAP = {
    ["Slayer Alliance"] = "slayer_alliance_v2",
    ["Midnight Dark"]   = "midnight_dark",
    ["Horde Red"]       = "horde_red",
    ["Industrial"]      = "industrial_v3",
    ["Elven"]           = "elven_v3",
    ["Void"]            = "void",
    ["Scrollwork"]      = "scrollwork_v3",
    ["Alliance Blue"]   = "alliance_blue_v3",
    ["Titan Bronze"]    = "titan_bronze",
    ["Void Reborn"]     = "void_reborn",
    ["Emerald Elven"]   = "elven_v3",
}

-- Knop-icon slots (bovenste 5 knoppen)
-- blank1/blank2 worden gebruikt als roster en close placeholder
local BUTTON_ICONS = {
    theme    = "theme",    -- Maan/ster icon
    admin    = "admin",    -- Sleutel icon
    language = "language", -- Globe icon
    roster   = "blank1",   -- Silhouetten (blank1 slot)
    close    = "blank2",   -- Sluiten (blank2 slot)
}

-- Tegel-icon slots (onderste linktegels)
-- vault wordt voor meerdere dingen hergebruikt
local TILE_ICONS = {
    cloth   = "blank1",   -- Cloth counter
    skin    = "theme",    -- Skin tracker (maan/stijl)
    prey    = "admin",    -- Prey tracker (sleutel/target)
    vault   = "vault",    -- Vault / Warbank
    warbank = "vault",    -- Warbank (zelfde icon)
    debug   = "language", -- Debug (globe/netwerk)
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
    if DelveTrackerDB then
        DelveTrackerDB.activeTheme = name
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

-- -- Icon pad ophalen per theme + slot ------------------------------------
-- Gebruik: WTTheme.GetIcon("theme")      → knop-icon pad (20px folder)
--          WTTheme.GetIcon("vault", true) → tegel-icon pad (28px folder)
function WTTheme.GetIcon(slot, isTile)
    local themeKey = ICON_THEME_MAP[_activeTheme] or "slayer_alliance_v2"
    local folder   = isTile and (MEDIA .. "28px\\") or (MEDIA .. "20px\\")
    local slotMap  = isTile and TILE_ICONS or BUTTON_ICONS
    local iconName = slotMap[slot]
    if not iconName then return nil end
    return folder .. "icon_" .. iconName .. "_" .. themeKey .. ".tga"
end

-- -- Helper: texture op een frame zetten via icon slot --------------------
-- Gebruik: WTTheme.ApplyIcon(myTexture, "theme")
--          WTTheme.ApplyIcon(myTexture, "vault", true)  -- tegel variant
function WTTheme.ApplyIcon(texture, slot, isTile)
    if not texture or not texture.SetTexture then return end
    local path = WTTheme.GetIcon(slot, isTile)
    if path then
        texture:SetTexture(path)
    end
end

-- -- Initialisatie: laad DB theme bij login --------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Herstel opgeslagen theme
        if DelveTrackerDB and DelveTrackerDB.activeTheme then
            local saved = DelveTrackerDB.activeTheme
            -- Migratie: "Crystal" → "Alliance Blue" (hernoeming v1.1.0)
            if saved == "Crystal" then
                saved = "Alliance Blue"
                DelveTrackerDB.activeTheme = "Alliance Blue"
            end
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

-- ============================================================================
-- EXTRA ICON CALLBACKS — B knop (DT_RegistryOpenBtn) + X knop (close)
-- Volledig additief — geen bestaande code gewijzigd
-- DT_Registry.lua en WowTracker.lua worden NIET aangeraakt
-- ============================================================================

-- Helper: zet icon op B, X en murloc via globale frame referenties
local function ApplyBXIcons()
    -- ── B knop (DT_RegistryOpenBtn) ──────────────────────────────────────
    local bBtn = _G["DT_RegistryOpenBtn"]
    if bBtn then
        -- Formaat gelijkstellen aan de andere header knoppen (32px)
        bBtn:SetSize(32, 32)
        -- Verberg de "B" tekst
        if bBtn.t then bBtn.t:SetText("") end
        -- Icon texture aanmaken (eenmalig)
        if not bBtn._wtIconTex then
            bBtn._wtIconTex = bBtn:CreateTexture(nil, "OVERLAY")
            bBtn._wtIconTex:SetPoint("CENTER")
        end
        bBtn._wtIconTex:SetSize(28, 28)
        bBtn._wtIconTex:SetBlendMode("BLEND")
        local path = WTTheme.GetIcon("roster")
        if path then bBtn._wtIconTex:SetTexture(path) end
    end

    -- ── X knop (DelveTrackerFrame.close) ─────────────────────────────────
    local dFrame = _G["DelveTrackerFrame"]
    local xBtn   = dFrame and dFrame.close
    if xBtn then
        -- Verberg de Blizzard standaard X texture
        local norm = xBtn:GetNormalTexture()
        if norm then norm:SetAlpha(0) end
        local push = xBtn:GetPushedTexture()
        if push then push:SetAlpha(0) end
        -- Icon texture aanmaken (eenmalig)
        if not xBtn._wtIconTex then
            xBtn._wtIconTex = xBtn:CreateTexture(nil, "OVERLAY")
            xBtn._wtIconTex:SetPoint("CENTER")
        end
        xBtn._wtIconTex:SetSize(28, 28)
        xBtn._wtIconTex:SetBlendMode("BLEND")
        local path = WTTheme.GetIcon("close")
        if path then xBtn._wtIconTex:SetTexture(path) end
    end

    -- ── Murloc knop (DT_MurlocBtn) ───────────────────────────────────────
    -- BlendMode "ADD" in WowTracker.lua maakt donkere pixels transparant
    -- Hier overschrijven met "BLEND" voor correcte weergave
    local mBtn = _G["DT_MurlocBtn"]
    if mBtn and mBtn.tex then
        mBtn.tex:SetBlendMode("BLEND")
    end
end

-- Registreer voor live theme-wissel
WTTheme.Register(ApplyBXIcons, "BXIcons")

-- Initieel laden: wacht 2 sec zodat DT_Registry zijn knop heeft aangemaakt
C_Timer.After(2, ApplyBXIcons)

--[[
  File    : DT_Theme.lua
  Version : 1.2.0   Created : 2026-06-09   Updated : 2026-06-15 00:00
  Status  : Updated - Titan Bronze, Void Reborn, Emerald Elven themes toegevoegd
  Changes : - THEMES["Crystal"] hernoemd naar THEMES["Alliance Blue"]
            - SavedVariables migratie "Crystal" → "Alliance Blue"
            - ICON_THEME_MAP toegevoegd (8 themes → bestandsnaam mapping)
            - WTTheme.GetIcon(slot, isTile) toegevoegd
            - WTTheme.ApplyIcon(texture, slot, isTile) toegevoegd
            - BUTTON_ICONS en TILE_ICONS slot-mapping toegevoegd
  Author  : DieOuwe . www.dieouwe.nl . discord.gg/y8Pu5qsEbQ
]]
