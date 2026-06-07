-------------------------------------------------
-- MAJESTIC TRACKER
-- Retail 12.0.5 Midnight Edition
-- FIXED VERSION — Audit Build 2025-05-16 (v7 MBT-sourced coords + item fix)
-- Architect: Dieouwe
--
-- FIXES APPLIED (Build 2025-05-09):
--   [FIX-1] Removed orphaned first modelFrame declaration (line 138)
--   [FIX-2] Corrected Netherscythe (Northern Rift) y-coordinate: 79.14 → 22.50
--   [FIX-3] Row offset formula: -55-(i*48) → -(HEADER_SPACE+5)-((i-1)*ROW_HEIGHT)
--   [FIX-4] StatusBar width: 700 → 760 + explicit frame parent anchor
--   [FIX-5] Harandar mapID verification comment added
--   [FIX-6] Typo "COMBAD" → "COMBAT" + explicit parent references throughout
--
-- LOGO LAYOUT (Build 2025-05-11):
--   [LOGO-FIX-1] headerImg layer: BACKGROUND → ARTWORK (renders above backdrop)
--   [LOGO-FIX-2] Size: 700×40 → 160×70 (square brand mark format)
--   [LOGO-FIX-3] Anchor: TOP/CENTER → TOPLEFT (10, -7) (left-aligned)
--   [LOGO-FIX-4] Alpha: 0.9 → 1.0 (full opacity, logo must be sharp)
--   [LOGO-FIX-5] Added logoLine separator (1px, purple, 160px wide under logo)
--   [LOGO-FIX-6] Title text reinstated to RIGHT of logo (TOPRIGHT anchor)
--   [LOGO-FIX-7] Added subTitle (zone/edition) and versionTag below title
--   [LOGO-FIX-8] HEADER_SPACE: 60 → 85 (accommodates 70px logo height)
--
-- COORDINATE AUDIT (Build 2025-05-11):
--   [COORD-FIX-1] Gloomclaw  (Eversong, #2395): x 42.18→42.00 / y 78.44→79.94
--                 Source: /way #2395 42.00 79.94 + Wowhead comment "/way 42 80"
--   [COORD-FIX-2] Silverscale (Zul'Aman, #2437): x 48.12→48.00 / y 54.03→54.00
--                 Source: /way #2437 48.00 54.00
--   [COORD-FIX-3] Lumenfin   (Harandar, #2413): x 66.20→66.63 / y 48.20→47.83
--                 Source: wow-professions.com (authoritative) + Wowhead comment <66.2,48.2>
--   [COORD-FIX-4] Umbrafang  (Voidstorm, #2405): x 54.00→54.15 / y 65.00→65.27
--                 Source: wow-professions.com 54.15 65.27
--   [COORD-FIX-5] Netherscythe (Grand, #2405): x 45.82→43.13 / y 22.50→82.81
--                 !! MAJOR: y=22.50 (north) was wrong. Lure is SOUTH of Locus Point.
--                 Source: wow-professions.com 43.13 82.81 + Method "south of Locus Point"
--
-- TOMTOM FIX (Build 2025-05-16):
--   [TT-1] Replaced SlashCmd with TomTom:AddWaypoint(mapID, x/100, y/100) — no string truncation
--   [TT-2] C_SuperTrack.SetSuperTrackedUserWaypoint(true) after Blizzard waypoint
--   [TT-3] TomTom UID stored in MajesticTracker_TomTomUID for targeted cleanup
--
-- MBT COORDINATE SYNC (Build 2025-05-16 v7):
--   Source: MajesticBeastTracker v2.0.2 Core.lua (23K+ downloads, authoritative)
--   All waypoints now stored as 0-1 internally (×100 for display).
--   [MBT-1] Eversong:  41.95 / 80.05  (was 42.00 / 79.94)
--   [MBT-2] Zul'Aman:  47.69 / 53.25  (was 48.00 / 54.00  ← ΔY=0.75 noticeable)
--   [MBT-3] Harandar:  66.28 / 47.91  (was 66.63 / 47.83)
--   [MBT-4] Voidstorm: 54.60 / 65.80  (was 54.15 / 65.27  ← ΔY=0.53 noticeable)
--   [MBT-5] Grand:     43.25 / 82.75  (was 43.13 / 82.81)
--   Added recipeID to each entry (from MBT Core.lua)
--   Item use: type=item + resolved itemName (MBT pattern: RequestLoadItemDataByID
--   + 1s ticker; we use hardcoded lureName for immediate resolution)
--
-- LURE MACRO FIX (Build 2025-05-16 v6):
--   [FIX-1] lureName added to all rareData entries (hardcoded, no cache lookup)
--   [FIX-2/3] type=macro + /use lureName replaces type=item + "item:ID"
--            ROOT CAUSE: UseItemByName(C) only accepts names, not "item:ID" strings.
--            "item:238654" as attribute → UseItemByName("item:238654") → item not
--            found in bags → silent fail. "/use Majestic Harandar Lure" → macro
--            engine → UseItemByName("Majestic Harandar Lure") → WORKS.
--
-- LURE PLACEMENT FIX (Build 2025-05-16):
--   [LP-1] SecureActionButton attributes set at SHOW time, NOT on OnEnter.
--          Root cause of popup not placing: OnLeave fires before MouseUp — the OS
--          delivers MouseLeave before MouseUp when cursor moves 1px during click.
--          Disarming on OnLeave cleared the attribute before the click was processed.
--   [LP-2] OnEnter/OnLeave now VISUAL ONLY — tooltip + glow — no attribute changes.
--   [LP-3] Main-frame lure buttons: attribute set at creation time (same pattern).
--
-- SIXTH SENSE POPUP (Build 2025-05-16):
--   [SS-1] SIXTH_SENSE_IDS = {1239120, 1239121}
--   [SS-2] C_UnitAuras, C_SuperTrack added to localized API
--   [SS-3] popupFrame: amber alert panel, DIALOG strata, draggable via title handle
--   [FIX-A] Title-bar drag handle replaces whole-frame drag (fixes click-steal)
--   [FIX-B] RegisterForClicks(AnyUp) explicit on popupLureBtn
--   [FIX-C] Bag-count guard: shows NO LURE warning, blocks silent fail
--   [SS-4] GetLureForCurrentZone(): quest-state + proximity fallback (Voidstorm)
--   [SS-5] C_Timer.NewTicker 50ms pulse animation
--   [SS-6] UNIT_AURA + ZONE_CHANGED_NEW_AREA events
--   [SS-7] OnEvent: aura path direct, data path throttled
--   [SS-8] /snrpop debug toggle
-------------------------------------------------

-------------------------------------------------
-- LOCALIZED API — prevents global lookup overhead
-------------------------------------------------

local CreateFrame        = CreateFrame
local UIParent           = UIParent
local C_Map              = C_Map
local C_Item             = C_Item
local C_Timer            = C_Timer
local C_QuestLog         = C_QuestLog
local C_UnitAuras        = C_UnitAuras    -- [SS-2]
local C_SuperTrack       = C_SuperTrack   -- [TT-2]
local UiMapPoint         = UiMapPoint
local InCombatLockdown   = InCombatLockdown
local UIParentLoadAddOn  = UIParentLoadAddOn
local CallbackRegistryMixin = CallbackRegistryMixin
local CreateFromMixins   = CreateFromMixins
local ipairs             = ipairs
local table              = table
local string             = string
local pcall              = pcall

-------------------------------------------------
-- CALLBACK REGISTRY (Modern 12.0.x pattern)
-------------------------------------------------

local EventRegistry = CreateFromMixins(CallbackRegistryMixin)

EventRegistry:OnLoad()

EventRegistry:GenerateCallbackEvents({
    "WaypointCreated",
    "RareSelected",
})

-------------------------------------------------
-- RETAIL VERIFIED RARE DATA
--
-- COORDINATE SYSTEM REFERENCE:
--   x = percentage from west edge (0 = far west, 100 = far east)
--   y = percentage from north edge (0 = far north, 100 = far south)
--   → Northern locations have LOW y values (< 35)
--   → Southern locations have HIGH y values (> 65)
--   → Eastern locations have HIGH x values (> 65)
--
-- TO VERIFY A mapID IN-GAME:
--   /dump C_Map.GetMapInfo(XXXX)
--   should return a table with the zone name.
-------------------------------------------------

-------------------------------------------------
-- RARE DATA — Sourced from MajesticBeastTracker v2.0.2 Core.lua
-- Coordinates stored as 0-100 (MBT stores 0-1; we multiply by 100).
-- All IDs cross-verified: npcID, itemID, recipeID, questID.
-- recipeID = Skinning profession recipe for crafting the lure.
-------------------------------------------------

local rareData = {

    -- [MBT-1] Eversong Woods — Gloomclaw
    -- MBT: x=0.4195, y=0.8005  (×100: 41.95, 80.05)
    -- Reagents: Arcane Wyrmfish ×8, Lynxfish ×8
    {
        name      = "Gloomclaw (Eversong)",
        id        = 88545,
        npcID     = 245688,
        lureID    = 238652,
        lureName  = "Majestic Eversong Lure",
        recipeID  = 1225943,
        map       = 2395,
        x         = 41.95,
        y         = 80.05,
        hint      = "Portal: Silvermoon -> South Woods"
    },

    -- [MBT-2] Zul'Aman — Silverscale
    -- MBT: x=0.4769, y=0.5325  (×100: 47.69, 53.25)
    -- Note: Under the large bridge. Look for a small lake.
    -- Reagents: Gore Guppy ×8
    {
        name      = "Silverscale (Zul'Aman)",
        id        = 88526,
        npcID     = 245699,
        lureID    = 238653,
        lureName  = "Majestic Zul'Aman Lure",
        recipeID  = 1225944,
        map       = 2437,
        x         = 47.69,
        y         = 53.25,
        hint      = "Portal: Silvermoon -> North Pass (under bridge)"
    },

    -- [MBT-3] Harandar — Lumenfin
    -- MBT: x=0.6628, y=0.4791  (×100: 66.28, 47.91)
    -- Near the giant mushroom strider and waterfall (dark blue mushroom area)
    -- Reagents: Fungalskin Pike ×8, Tender Lumifin ×8
    {
        name      = "Lumenfin (Harandar)",
        id        = 88531,
        npcID     = 245690,
        lureID    = 238654,
        lureName  = "Majestic Harandar Lure",
        recipeID  = 1225945,
        map       = 2413,
        x         = 66.28,
        y         = 47.91,
        hint      = "Midnight Capital -> East Harbor (mushroom waterfall)"
    },

    -- [MBT-4] Voidstorm — Umbrafang
    -- MBT: x=0.5460, y=0.6580  (×100: 54.60, 65.80)
    -- Ravine north of main hub: The Howling Ridge
    -- Reagents: Ominous Octopus ×4
    {
        name      = "Umbrafang (Voidstorm)",
        id        = 88532,
        npcID     = 247096,
        lureID    = 238655,
        lureName  = "Majestic Voidstorm Lure",
        recipeID  = 1225946,
        map       = 2405,
        x         = 54.60,
        y         = 65.80,
        hint      = "Void Portal -> The Howling Ridge"
    },

    -- [MBT-5] Voidstorm — Netherscythe (Grand Beast)
    -- MBT: x=0.4325, y=0.8275  (×100: 43.25, 82.75)
    -- South of Locus Point — HIGH y value = deep south ✓
    -- Reagents: Null Voidfish ×4
    {
        name      = "Netherscythe (Grand)",
        id        = 88524,
        npcID     = 247101,
        lureID    = 238656,
        lureName  = "Grand Beast Lure",
        recipeID  = 1225948,
        map       = 2405,
        x         = 43.25,
        y         = 82.75,
        hint      = "Void Portal -> South of Locus Point"
    },
}

-------------------------------------------------
-- DYNAMIC SIZE CONSTANTS
-- All frame dimensions derive from these values
-- so changing #rareData automatically resizes the UI.
-------------------------------------------------

local ROW_HEIGHT   = 48   -- height of each rare row in pixels
local HEADER_SPACE = 85   -- [LOGO-FIX] increased 60→85 for taller left-aligned logo block
local FOOTER_SPACE = 100  -- reserved pixels for the status bar area
local TOTAL_HEIGHT = HEADER_SPACE + (#rareData * ROW_HEIGHT) + FOOTER_SPACE

-------------------------------------------------
-- MAIN FRAME
-------------------------------------------------

local frame = CreateFrame(
    "Frame",
    "MajesticTrackerFrame",
    UIParent,
    "BackdropTemplate"
)

frame:SetSize(800, TOTAL_HEIGHT)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:SetToplevel(true)
frame:SetFrameStrata("HIGH")
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-------------------------------------------------
-- [FIX-1] BACKDROP — must be set BEFORE modelFrame
-- calls frame:GetBackdrop(). In the original code
-- the first modelFrame (line 138) called GetBackdrop()
-- before the backdrop was defined → returned nil.
-- The entire first modelFrame block was orphaned and
-- is now removed. Backdrop is set here, first.
-------------------------------------------------

frame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile     = true,
    tileSize = 32,
    edgeSize = 2,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 }
})

frame:SetBackdropColor(0.01, 0.01, 0.02, 0.98)
frame:SetBackdropBorderColor(0.3, 0, 0.5, 1)

-------------------------------------------------
-- MODEL FRAME (single declaration — FIX-1 removes duplicate)
-- Now correctly created AFTER backdrop is set on frame,
-- so frame:GetBackdrop() returns the full backdrop table.
-------------------------------------------------

local modelFrame = CreateFrame(
    "Frame",
    nil,
    frame,
    "BackdropTemplate"
)

modelFrame:SetSize(320, TOTAL_HEIGHT - 20)
modelFrame:SetPoint("LEFT", frame, "RIGHT", 5, 0)
modelFrame:SetBackdrop(frame:GetBackdrop())  -- now returns valid backdrop ✓
modelFrame:SetBackdropColor(0, 0, 0, 0.95)
modelFrame:SetBackdropBorderColor(0.3, 0, 0.5, 1)

-------------------------------------------------
-- PLAYER MODEL
-------------------------------------------------

local model = CreateFrame("PlayerModel", nil, modelFrame)
model:SetAllPoints()

-------------------------------------------------
-- TITLE & HEADER IMAGE
-- [LOGO-FIX] New layout: logo anchored TOPLEFT at 160x70px (was 700x40 centered).
--   The logo image now acts as a proper brand mark on the left side,
--   large enough to read at any UI scale.
-- Title FontStrings sit to the RIGHT of the logo for a clean two-column header.
-------------------------------------------------

-- Main logo texture — large, left-anchored
local headerImg = frame:CreateTexture(nil, "ARTWORK")
headerImg:SetSize(160, 70)                                        -- [LOGO-FIX] was 700x40
headerImg:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -7)          -- [LOGO-FIX] was TOP/CENTER
headerImg:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\AMT")
headerImg:SetAlpha(1.0)                                           -- [LOGO-FIX] was 0.9; full opacity

-- Subtle separator line under the logo to anchor it visually
local logoLine = frame:CreateTexture(nil, "BACKGROUND")
logoLine:SetSize(160, 1)
logoLine:SetPoint("TOPLEFT", headerImg, "BOTTOMLEFT", 0, -2)
logoLine:SetColorTexture(0.4, 0.1, 0.8, 0.4)

-- Primary addon title — to the right of the logo
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", headerImg, "TOPRIGHT", 16, -10)
title:SetTextColor(0.78, 0.61, 1.0)
title:SetText("MAJESTIC TRACKER")

-- Subtitle — zone context line below the title
local subTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
subTitle:SetTextColor(0.35, 0.22, 0.56)
subTitle:SetText("Rare Beast Waypoints  ·  Midnight 12.0.5")

-- Version tag — smallest line, same column
local versionTag = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionTag:SetPoint("TOPLEFT", subTitle, "BOTTOMLEFT", 0, -3)
versionTag:SetTextColor(0.22, 0.14, 0.36)
versionTag:SetText("Build 2025-05-16 v7  ·  Dieouwe")

-------------------------------------------------
-- STATUS BAR
-- [FIX-4] Width corrected: 700 → 760 (800px frame - 40px side margins)
-- [FIX-4] Explicit parent frame reference added to SetPoint
-------------------------------------------------

local statusBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")

statusBg:SetSize(760, 34)  -- FIX-4: was 700, corrected to 760
statusBg:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)  -- FIX-4: explicit parent

statusBg:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
statusBg:SetBackdropColor(0.05, 0, 0.1, 0.5)
statusBg:SetBackdropBorderColor(0.2, 0, 0.4, 1)

local statusText = statusBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statusText:SetPoint("CENTER")
statusText:SetScale(1.1)
statusText:SetTextColor(0.8, 0.6, 1)
statusText:SetText("Select a Rare...")

-------------------------------------------------
-- WORLD MAP OPENER (Taint-safe for 12.0.5)
-------------------------------------------------

local function OpenWorldMap(mapID)
    -- [FIX-6] Guard against combat taint; corrected error message typo.
    if InCombatLockdown() then
        print("|cFFFF0000Majestic Tracker: Cannot open map during combat.|r")
        return
    end

    -- Ensure the Blizzard_WorldMap addon is loaded
    if not WorldMapFrame then
        pcall(UIParentLoadAddOn, "Blizzard_WorldMap")
    end

    if WorldMapFrame then
        WorldMapFrame:Show()
        -- SetMapID is the correct modern (12.0.x) API.
        -- SyncScrollContainer / RefreshOverlayFrames are NOT used here —
        -- they are internal and often nil, causing errors.
        if WorldMapFrame.SetMapID and mapID then
            WorldMapFrame:SetMapID(mapID)
        end
    end
end

-------------------------------------------------
-- NAVIGATION HANDLER
-- Sets a TomTom waypoint (if available) and a
-- Blizzard User Waypoint, then updates the model.
-------------------------------------------------

local function SetNavigation(data)

    -------------------------------------------------
    -- TOMTOM WAYPOINT
    -- TomTom's /way slash command expects:
    --   mapID x y label
    -- where x and y are 0-100 percentage coordinates.
    -------------------------------------------------

    -- [TT-1] Direct TomTom API — no string truncation, no re-parse
    if TomTom and TomTom.RemoveWaypoint and MajesticTracker_TomTomUID then
        pcall(TomTom.RemoveWaypoint, TomTom, MajesticTracker_TomTomUID)
        MajesticTracker_TomTomUID = nil
    end
    if TomTom and TomTom.AddWaypoint then
        MajesticTracker_TomTomUID = TomTom:AddWaypoint(
            data.map, data.x / 100, data.y / 100,
            { title = data.name, persistent = false, minimap = true, world = true }
        )
    elseif SlashCmdList["TOMTOM_WAY"] then
        -- Older TomTom fallback (4 decimal precision)
        SlashCmdList["TOMTOM_WAY"](string.format("%d %.4f %.4f %s", data.map, data.x, data.y, data.name))
    end

    -- [TT-2] Blizzard waypoint + SuperTrack sync
    if UiMapPoint and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(data.map, data.x / 100, data.y / 100)
        C_Map.SetUserWaypoint(point)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)  -- [TT-2] sync arrow to pin
        end
    end

    -------------------------------------------------
    -- STATUS BAR UPDATE
    -------------------------------------------------

    statusText:SetText(
        "Fastest route: |cFFC79CFF" .. data.hint .. "|r"
    )

    -------------------------------------------------
    -- PLAYER MODEL UPDATE
    -- SetCreature is wrapped in pcall in case the
    -- npcID is not yet cached by the client.
    -------------------------------------------------

    model:ClearModel()

    local success = pcall(function()
        model:SetCreature(data.npcID)
    end)

    if success then
        C_Timer.After(0.03, function()
            if not model:IsShown() then return end

            model:SetCamDistanceScale(1)
            model:SetPortraitZoom(0)
            model:SetPosition(0, 0, 0)
            model:SetRotation(0.6)

            -- Scale down larger creatures (npcID >= 247096)
            if data.npcID >= 247096 then
                model:SetScale(0.7)
            else
                model:SetScale(1)
            end
        end)
    end

    -------------------------------------------------
    -- CALLBACK EVENT (CallbackRegistryMixin pattern)
    -------------------------------------------------

    EventRegistry:TriggerEvent("WaypointCreated", data)
end

-------------------------------------------------
-- BUTTON STYLE HELPER
-- Applies a consistent dark glow style to buttons.
-------------------------------------------------

local function StyleButton(btn, r, g, b)
    btn:SetNormalFontObject("GameFontNormalLarge")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.05, 0.15, 1)

    local glow = btn:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    glow:SetBlendMode("ADD")
    glow:SetPoint("TOPLEFT", -1, 1)
    glow:SetPoint("BOTTOMRIGHT", 1, -1)
    glow:SetVertexColor(r, g, b, 0.5)
    glow:Hide()

    btn:SetScript("OnEnter", function() glow:Show() end)
    btn:SetScript("OnLeave", function() glow:Hide() end)
end

-------------------------------------------------
-- UPDATE TABLE — collects references for UpdateRareData()
-------------------------------------------------

local updateFrames = {}

-------------------------------------------------
-- BUTTON LOOP
-- [FIX-3] Corrected offset formula:
--   OLD: local offset = -55 - (i * 48)
--        → row 1 at y=-103 (43px dead gap after 60px header)
--   NEW: local offset = -(HEADER_SPACE + 5) - ((i-1) * ROW_HEIGHT)
--        → row 1 at y=-65 (5px breathing room after header)
--        → rows are evenly spaced by exactly ROW_HEIGHT
-------------------------------------------------

for i, data in ipairs(rareData) do

    -- [FIX-3] Corrected offset: rows now start 5px below the header area
    local offset = -(HEADER_SPACE + 5) - ((i - 1) * ROW_HEIGHT)

    -------------------------------------------------
    -- TRACK BUTTON — triggers TomTom + Blizzard waypoint
    -------------------------------------------------

    local btnTrack = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnTrack:SetSize(100, 34)
    btnTrack:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, offset)
    btnTrack:SetText("TRACK")
    StyleButton(btnTrack, 0.4, 0.6, 1)
    btnTrack:SetScript("OnClick", function()
        SetNavigation(data)
    end)

    -------------------------------------------------
    -- MAP BUTTON — opens the Blizzard WorldMap to the zone
    -------------------------------------------------

    local btnMap = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnMap:SetSize(80, 34)
    btnMap:SetPoint("LEFT", btnTrack, "RIGHT", 10, 0)
    btnMap:SetText("MAP")
    StyleButton(btnMap, 0.6, 0, 1)
    btnMap:SetScript("OnClick", function()
        OpenWorldMap(data.map)
    end)

    -------------------------------------------------
    -- RARE NAME TEXT
    -------------------------------------------------

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("LEFT", btnMap, "RIGHT", 15, 0)
    text:SetScale(1.05)
    text:SetTextColor(0.7, 0.5, 1)
    text:SetText(data.name)

    -------------------------------------------------
    -- LURE ITEM BUTTON (SecureActionButtonTemplate)
    -- Attributes are only set outside combat to avoid taint.
    -------------------------------------------------

    -- [LP-3] Attribute set at creation — no hover-arm race condition
    local lureBtn = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
    lureBtn:SetSize(54, 54)
    lureBtn:SetPoint("LEFT", btnMap, "RIGHT", 360, 0)

    -- [MBT pattern] type=item + lureName (full resolved name).
    -- Matches MBT v2.0.2 LureIcons.lua proven pattern.
    if not InCombatLockdown() then
        lureBtn:SetAttribute("type", "item")
        lureBtn:SetAttribute("item", data.lureName)
    end

    local icon = lureBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(C_Item.GetItemIconByID(data.lureID))

    -- Glow border (visual only — no attribute logic)
    local lureGlow = lureBtn:CreateTexture(nil, "OVERLAY")
    lureGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    lureGlow:SetBlendMode("ADD")
    lureGlow:SetPoint("TOPLEFT",     lureBtn, "TOPLEFT",     -3,  3)
    lureGlow:SetPoint("BOTTOMRIGHT", lureBtn, "BOTTOMRIGHT",  3, -3)
    lureGlow:SetVertexColor(1, 0.65, 0.1)
    lureGlow:SetAlpha(0)

    -- [LP-2] OnEnter: VISUAL ONLY — tooltip + glow. No SetAttribute.
    lureBtn:SetScript("OnEnter", function(self)
        lureGlow:SetAlpha(0.85)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(data.lureID)
        GameTooltip:AddLine("|cFF00FFFFHover to preview · Click to enter placement mode|r")
        GameTooltip:Show()
    end)

    -- [LP-2] OnLeave: VISUAL ONLY — hide glow + tooltip.
    lureBtn:SetScript("OnLeave", function()
        lureGlow:SetAlpha(0)
        GameTooltip:Hide()
    end)

    -------------------------------------------------
    -- ITEM COUNT TEXT
    -------------------------------------------------

    local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countText:SetPoint("LEFT", lureBtn, "RIGHT", 10, 0)
    countText:SetScale(1.15)
    countText:SetTextColor(0.8, 0.8, 1)

    -------------------------------------------------
    -- REGISTER FOR UPDATES
    -------------------------------------------------

    table.insert(updateFrames, {
        text  = text,
        count = countText,
        data  = data,
    })
end

-------------------------------------------------
-- UPDATE FUNCTION
-- Called on PLAYER_ENTERING_WORLD, BAG_UPDATE_DELAYED,
-- and QUEST_LOG_UPDATE (throttled to 0.1s).
-------------------------------------------------

local function UpdateRareData()
    for _, info in ipairs(updateFrames) do

        local completed = C_QuestLog.IsQuestFlaggedCompleted(info.data.id)

        if completed then
            -- Green + [OK] suffix for defeated rares
            info.text:SetTextColor(0.2, 1, 0.6)
            info.text:SetText(info.data.name .. " [OK]")
        else
            -- Default purple for active rares
            info.text:SetTextColor(0.7, 0.5, 1)
            info.text:SetText(info.data.name)
        end

        -- Item count in bags (returns 0 if not owned)
        info.count:SetText(C_Item.GetItemCount(info.data.lureID))
    end
end


-------------------------------------------------
-- SIXTH SENSE POPUP SYSTEM
-- Spell 1239120 (Wowhead) / 1239121 (in-game screenshot)
-- Nature debuff · 100yd radius · NOT active mounted
-------------------------------------------------

local SIXTH_SENSE_IDS       = { 1239120, 1239121 }
MajesticTracker_TomTomUID   = nil   -- [TT-3] module-scoped UID

local popupFrame = CreateFrame("Frame","MajesticSixthSensePopup",UIParent,"BackdropTemplate")
popupFrame:SetSize(218, 192)
popupFrame:SetPoint("CENTER", UIParent, "CENTER", 320, 90)
popupFrame:SetFrameStrata("DIALOG")
popupFrame:SetToplevel(true)
popupFrame:SetClampedToScreen(true)
popupFrame:SetMovable(true)
popupFrame:EnableMouse(true)
-- [FIX-A] Do NOT register drag on the whole frame — that steals
-- LeftButton clicks from child SecureActionButtons.
-- Drag is handled exclusively by the dedicated title handle below.
popupFrame:Hide()

-- [FIX-A] Title-bar drag handle (top 26px strip only)
-- Only this region moves the popup. Clicking the lure button below
-- goes directly to the SecureActionButtonTemplate, no interference.
local popupTitleHandle = CreateFrame("Frame", nil, popupFrame)
popupTitleHandle:SetHeight(26)
popupTitleHandle:SetPoint("TOPLEFT",  popupFrame, "TOPLEFT",  0,  0)
popupTitleHandle:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", 0,  0)
popupTitleHandle:EnableMouse(true)
popupTitleHandle:RegisterForDrag("LeftButton")
popupTitleHandle:SetScript("OnDragStart", function() popupFrame:StartMoving() end)
popupTitleHandle:SetScript("OnDragStop",  function() popupFrame:StopMovingOrSizing() end)

popupFrame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile=true, tileSize=32, edgeSize=2,
    insets={left=0,right=0,top=0,bottom=0}
})
popupFrame:SetBackdropColor(0.05, 0.01, 0.00, 0.97)
popupFrame:SetBackdropBorderColor(0.90, 0.55, 0.05, 1)

-- Corner accents
local function _C(a,ox,oy)
    local c=popupFrame:CreateTexture(nil,"OVERLAY")
    c:SetSize(7,7); c:SetPoint(a,popupFrame,a,ox,oy)
    c:SetColorTexture(0.90,0.55,0.05,0.65)
end
_C("TOPLEFT",2,-2) _C("TOPRIGHT",-2,-2) _C("BOTTOMLEFT",2,2) _C("BOTTOMRIGHT",-2,2)

-- Close
local popupClose = CreateFrame("Button",nil,popupFrame,"UIPanelCloseButton")
popupClose:SetSize(18,18)
popupClose:SetPoint("TOPRIGHT",popupFrame,"TOPRIGHT",-2,-2)
popupClose:SetScript("OnClick", function() popupFrame:Hide() end)

-- Header
local popupHeader = popupFrame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
popupHeader:SetPoint("TOP",popupFrame,"TOP",0,-12)
popupHeader:SetTextColor(1.0,0.65,0.05)
popupHeader:SetText("⚠  SIXTH SENSE")

-- Zone line
local popupZoneLine = popupFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
popupZoneLine:SetPoint("TOP",popupHeader,"BOTTOM",0,-5)
popupZoneLine:SetTextColor(0.75,0.50,1.0)
popupZoneLine:SetText("")

-------------------------------------------------
-- LURE BUTTON
-- [LP-1] Attribute set in ShowSixthSensePopup() — NOT on OnEnter.
-- [LP-2] OnEnter/OnLeave are VISUAL ONLY (glow + tooltip).
-------------------------------------------------

local popupLureBtn = CreateFrame(
    "Button","MajesticSixthSenseLureBtn",popupFrame,"SecureActionButtonTemplate"
)
popupLureBtn:SetSize(84, 84)
popupLureBtn:SetPoint("CENTER",popupFrame,"CENTER",0,4)
popupLureBtn._lureID = nil
-- [FIX-B] Explicit click registration — required for reliable secure
-- action firing in 12.0.x even when template sets defaults.
popupLureBtn:RegisterForClicks("AnyUp", "AnyDown")

local popupIcon = popupLureBtn:CreateTexture(nil,"ARTWORK")
popupIcon:SetAllPoints()
popupIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

-- Static dim (removed on hover)
local popupDim = popupLureBtn:CreateTexture(nil,"OVERLAY")
popupDim:SetAllPoints()
popupDim:SetColorTexture(0,0,0,0.40)

-- Pulse glow ring
local popupGlow = popupLureBtn:CreateTexture(nil,"OVERLAY")
popupGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
popupGlow:SetBlendMode("ADD")
popupGlow:SetPoint("TOPLEFT",    popupLureBtn,"TOPLEFT",    -5, 5)
popupGlow:SetPoint("BOTTOMRIGHT",popupLureBtn,"BOTTOMRIGHT", 5,-5)
popupGlow:SetVertexColor(1.0,0.55,0.08)
popupGlow:SetAlpha(0.55)

-- Labels
local popupIdleLabel  = popupFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
popupIdleLabel:SetPoint("TOP",popupLureBtn,"BOTTOM",0,-6)
popupIdleLabel:SetTextColor(0.55,0.38,0.70)
popupIdleLabel:SetText("CLICK TO PLACE LURE")

local popupHintLine = popupFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
popupHintLine:SetPoint("TOP",popupIdleLabel,"BOTTOM",0,-4)
popupHintLine:SetTextColor(0.38,0.25,0.58)
popupHintLine:SetText("")

-------------------------------------------------
-- PULSE ANIMATION
-------------------------------------------------

local _pTicker,_pVal,_pDir = nil, 0.35, 1

local function StartPulse()
    if _pTicker then return end
    _pTicker = C_Timer.NewTicker(0.05, function()
        _pVal = _pVal + 0.055 * _pDir
        if _pVal >= 0.90 then _pVal=0.90; _pDir=-1
        elseif _pVal <= 0.20 then _pVal=0.20; _pDir=1 end
        popupGlow:SetAlpha(_pVal)
    end)
end

local function StopPulse()
    if _pTicker then _pTicker:Cancel(); _pTicker=nil end
    popupGlow:SetAlpha(0.55)
end

-------------------------------------------------
-- [LP-2] HOVER: VISUAL ONLY — no attribute changes
-------------------------------------------------

-- [MBT pattern] PreClick: block item use on right-click (close popup)
popupLureBtn:SetScript("PreClick", function(self, button)
    if InCombatLockdown() then return end
    if button == "RightButton" then
        self:SetAttribute("type", nil)  -- block item use
    end
end)

-- [MBT pattern] PostClick: restore type=item + handle right-click close
popupLureBtn:SetScript("PostClick", function(self, button)
    if not InCombatLockdown() then
        self:SetAttribute("type", "item")  -- always restore
    end
    if button == "RightButton" then
        local now = GetTime()
        if (now - (self._lastClose or 0)) > 0.3 then
            self._lastClose = now
            HideSixthSensePopup()  -- right-click = close popup
        end
    end
end)

popupLureBtn:SetScript("OnEnter", function(self)
    popupDim:SetAlpha(0)
    popupGlow:SetVertexColor(1.0,0.85,0.15)
    if self._lureID then
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self._lureID)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FFFFClick to enter lure placement mode.|r")
        GameTooltip:AddLine("|cFFAAAAAAAA Then click the ground to place.|r")
        GameTooltip:Show()
    end
end)

popupLureBtn:SetScript("OnLeave", function(self)
    popupDim:SetAlpha(0.40)
    popupGlow:SetVertexColor(1.0,0.55,0.08)
    GameTooltip:Hide()
end)

-------------------------------------------------
-- ZONE RESOLVER
-- Voidstorm (2405): quest state → proximity
-------------------------------------------------

local function GetLureForCurrentZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end
    local cands = {}
    for _,d in ipairs(rareData) do
        if d.map == mapID then table.insert(cands,d) end
    end
    if #cands == 0 then return nil end
    if #cands == 1 then return cands[1] end
    -- prefer uncompleted
    local undone = {}
    for _,c in ipairs(cands) do
        if not C_QuestLog.IsQuestFlaggedCompleted(c.id) then table.insert(undone,c) end
    end
    if #undone == 1 then return undone[1] end
    local pool = (#undone>0) and undone or cands
    -- proximity
    local pos = C_Map.GetPlayerMapPosition(mapID,"player")
    if pos then
        local px,py = pos:GetXY()
        if px and py then
            px,py = px*100, py*100
            local best,bd = nil, math.huge
            for _,c in ipairs(pool) do
                local d=(c.x-px)^2+(c.y-py)^2
                if d<bd then bd=d; best=c end
            end
            if best then return best end
        end
    end
    return pool[1]
end

-------------------------------------------------
-- [LP-1] SHOW: attributes set HERE — before any click
-------------------------------------------------

local function ShowSixthSensePopup()
    local data = GetLureForCurrentZone()
    -- Debug fallback: if no zone match (/snrpop from wrong zone), use first undone
    if not data then
        for _,d in ipairs(rareData) do
            if not C_QuestLog.IsQuestFlaggedCompleted(d.id) then data=d; break end
        end
    end
    if not data then return end

    popupLureBtn._lureID = data.lureID

    -- [FIX-C] Bag-count guard
    local lureCount = C_Item.GetItemCount(data.lureID)
    local haslure   = (lureCount and lureCount > 0)

    -- [MBT pattern] type=item + resolved item name (proven by MBT v2.0.2).
    -- MBT: SetAttribute("type","item") + SetAttribute("item", itemName)
    -- where itemName is the full name from C_Item.GetItemNameByID (not "item:ID").
    -- We use hardcoded lureName for immediate resolution (no ticker needed).
    if not InCombatLockdown() then
        if haslure then
            popupLureBtn:SetAttribute("type", "item")
            popupLureBtn:SetAttribute("item", data.lureName)
        else
            popupLureBtn:SetAttribute("type", nil)
            popupLureBtn:SetAttribute("item", nil)
        end
    end

    local tex = C_Item.GetItemIconByID(data.lureID)
    popupIcon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    popupZoneLine:SetText(data.name)

    -- [FIX-C] Show count or "NO LURE" warning in hint line
    if haslure then
        popupIdleLabel:SetTextColor(0.55, 0.38, 0.70)
        popupIdleLabel:SetText("CLICK TO PLACE LURE  (x" .. lureCount .. ")")
        popupHintLine:SetText(data.hint)
        popupDim:SetAlpha(0.40)
    else
        popupIdleLabel:SetTextColor(1, 0.2, 0.2)
        popupIdleLabel:SetText("NO LURE IN BAGS !")
        popupHintLine:SetText("Craft or buy: " .. (C_Item.GetItemNameByID(data.lureID) or "Lure"))
        popupDim:SetAlpha(0.70)  -- extra dim = visually disabled
    end

    popupFrame:Show()
    StartPulse()
    SetNavigation(data)  -- sync main-frame model + status bar
end

local function HideSixthSensePopup()
    StopPulse()
    popupFrame:Hide()
end

-------------------------------------------------
-- AURA CHECK
-------------------------------------------------

local function CheckSixthSense(unit)
    if unit ~= "player" then return end
    local has = false
    for _,id in ipairs(SIXTH_SENSE_IDS) do
        if C_UnitAuras.GetPlayerAuraBySpellID(id) then has=true; break end
    end
    if has then
        if not popupFrame:IsShown() then ShowSixthSensePopup() end
    else
        if popupFrame:IsShown() then HideSixthSensePopup() end
    end
end

-------------------------------------------------
-- EVENT FRAME
-------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")              -- [SS-6]
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- [SS-6]

-------------------------------------------------
-- THROTTLED EVENT HANDLER (0.1s debounce)
-- Prevents spam-updating on rapid bag changes.
-------------------------------------------------

local updatePending = false

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    -- [SS-7] Aura path: direct, no debounce
    if event == "UNIT_AURA" then
        CheckSixthSense(arg1); return
    end
    -- [SS-7] Zone change: re-check aura + fall through to data refresh
    if event == "ZONE_CHANGED_NEW_AREA" then
        CheckSixthSense("player")
    end
    -- Data path: throttled
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.1, function()
        UpdateRareData(); updatePending = false
    end)
end)

-------------------------------------------------
-- SLASH COMMANDS
-- /snr or /mt — toggles the tracker frame
-------------------------------------------------

SLASH_MAJESTICTRACKER1 = "/snr"
SLASH_MAJESTICTRACKER2 = "/mt"

SlashCmdList["MAJESTICTRACKER"] = function()
    if InCombatLockdown() then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

-- [SS-8] /snrpop — force-toggle popup for testing
SLASH_MAJESTICPOPUP1 = "/snrpop"
SlashCmdList["MAJESTICPOPUP"] = function()
    if InCombatLockdown() then return end
    if popupFrame:IsShown() then HideSixthSensePopup() else ShowSixthSensePopup() end
end

-------------------------------------------------
-- CLOSE BUTTON
-------------------------------------------------

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

-------------------------------------------------
-- START HIDDEN
-------------------------------------------------

frame:Hide()

-------------------------------------------------
-- INITIAL DATA POPULATE
-------------------------------------------------

UpdateRareData()

-------------------------------------------------
-- LOAD CONFIRMATION
-------------------------------------------------

print("|cFFC79CFFMajestic Tracker v7 — MBT coords + type=item fix + PreClick guard (12.0.5).|r")

-- ============================================================================
-- DELVETRACKER PLUGIN REGISTRATIE — SkinNRare
-- ============================================================================
local _dtInt_SNR = CreateFrame("Frame")
_dtInt_SNR:RegisterEvent("PLAYER_LOGIN")
_dtInt_SNR:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if not (DelveTracker and DelveTracker.RegisterPlugin) then return end
    DelveTracker:RegisterPlugin("SkinNRare", function() end)
    local enabled = DelveTrackerDB and DelveTrackerDB.PluginStates["SkinNRare"] ~= false
    if frame then if enabled then frame:Show() else frame:Hide() end end
    local opt = _G["DelveTrackerOptions"]
    if opt then opt:HookScript("OnShow", function()
        local en = DelveTrackerDB and DelveTrackerDB.PluginStates["SkinNRare"] ~= false
        if frame then if en then frame:Show() else frame:Hide() end end
    end) end
end)
