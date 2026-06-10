-- ============================================================================
-- DelveTracker - Prey Tracker HUD V4
-- Retail 12.0.5 / Build 67314 (Midnight)
-- File: Plugins/DT_prey_ui.lua
-- ============================================================================
-- V4 CHANGES:
--   1. SETTINGS PANEL - [S] knop opent een volledig settings popup (apart frame,
--      niet embedded in compass). Bevat: Scale, Opacity, Needle Offset + 4
--      toggles (Auto-show, Combat fade, Ticker, Affix badges). Alles saved in
--      DelveTrackerDB.preySettings. Scale en opacity schalen het HELE frame.
--
--   2. SCALING - SetScale() op PreyUI schaalt alles: ring, naald, bar, tekst.
--      Alle textures/bars zijn kinderen van PreyUI, dus meteen mee. Settings
--      panel staat BUITEN PreyUI (op UIParent) zodat het zelf niet meeschaalt.
--
--   3. TICKER - ActionText hints te lang? Dan scrollt een horizontale marquee
--      via accumulated pixel offset op een ClipFrame. Reset automatisch.
--      Uitschakelbaar via settings toggle.
--
--   4. BADGE GRID - Affix/vignette badges wrappen nu. WoW heeft geen flexbox,
--      dus we bouwen 4 vaste badge-FontStrings die per tick aan/uit gaan. Max
--      twee rijen van twee. Unicode emojis verwijderd (WoW font crash).
--
--   5. DIFFICULTY BADGE - Kleine gekleurde label in de ring ONDER de naam.
--      EnemyText toont alleen naam (geen difficulty dubbeling meer).
--
--   6. RING + NAALD + BAR - Identiek aan V3 qua TGA-paden en fallback logica.
--      Enige wijziging: afmetingen licht bijgesteld voor een compactere ring.
-- ============================================================================
local addonName, addonTable = ...

local MEDIA = "Interface\\AddOns\\WowTracker\\Media\\"
local function M(f) return MEDIA..f end
local math_pi  = math.pi
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_sin = math.sin
local math_cos = math.cos

-- ============================================================================
-- SAVED SETTINGS - defaults + load/save helpers
-- Stored in DelveTrackerDB.preySettings
-- ============================================================================
local SETTINGS_DEFAULTS = {
    scale        = 1.0,
    alpha        = 1.0,
    needleOffset = 0,
    autoShow     = true,
    combatFade   = true,
    tickerOn     = true,
    affixBadges  = true,
}

local S = {}  -- active settings table, populated on PLAYER_LOGIN

local function LoadSettings()
    if not DelveTrackerDB then DelveTrackerDB = {} end
    if not DelveTrackerDB.preySettings then DelveTrackerDB.preySettings = {} end
    local db = DelveTrackerDB.preySettings
    for k, v in pairs(SETTINGS_DEFAULTS) do
        S[k] = (db[k] ~= nil) and db[k] or v
    end
    -- Backwards compat: import old preyNeedleOffset if no new setting yet
    if db.needleOffset == nil and DelveTrackerDB.preyNeedleOffset then
        S.needleOffset = DelveTrackerDB.preyNeedleOffset
    end
end

local function SaveSettings()
    if not DelveTrackerDB then DelveTrackerDB = {} end
    DelveTrackerDB.preySettings = {}
    for k, v in pairs(S) do DelveTrackerDB.preySettings[k] = v end
    -- Keep legacy key in sync
    DelveTrackerDB.preyNeedleOffset = S.needleOffset
end

-- ============================================================================
-- COLORS
-- ============================================================================
local C_RED   = "|cffdd3300"
local C_DIST  = "|cffffff00"
local C_GREY  = "|cffaaaaaa"
local C_WHITE = "|cffffffff"
local C_NRM   = "|cff44ff88"
local C_HARD  = "|cffff9900"
local C_NIGHT = "|cffff2200"
local C_TRAP  = "|cffffcc00"
local C_ANG   = "|cffff6600"
local C_COLD  = "|cff66bbff"
local C_WARM  = "|cffff9900"
local C_HOT   = "|cffff4400"
local C_FINAL = "|cffff0000"
local C_DIM   = "|cff555555"
local C_ECHO  = "|cffcc44ff"
local C_WARN  = "|cffff3333"

local STATE_COL = { [0]=C_COLD, [1]=C_WARM, [2]=C_HOT,  [3]=C_FINAL }
local STATE_LBL = { [0]="COLD", [1]="WARM",  [2]="HOT",  [3]="FINAL" }

-- ============================================================================
-- LAYOUT CONSTANTS (base size - scale applied via SetScale)
-- ============================================================================
local UI_W      = 420
local CALIB_H   = 28
local RING_PAD  = 8
local RING_SIZE = 300
local ARROW_SZ  = 120
local GAP_INFO  = 14
local GAP_VIGN  = 4
local GAP_BAR   = 10
local BAR_W     = 340
local BAR_H     = 80
local BAR_IH    = 20
local BAR_IX    = 47
local BAR_IY    = 36
local BAR_TW    = 247
local BOT_PAD   = 14
local TITLE_W   = 300
local TITLE_H   = 75
local BADGE_H   = 16   -- affix badge row height
local BADGE_GAP = 4    -- badge row gap

-- Badge row: 2 rows of up to 2 badges each
local BADGE_ROWS = 2
local BADGE_COLS = 2

local RING_Y  = -(CALIB_H + RING_PAD)
local RING_CY = RING_Y - RING_SIZE / 2
local SEP_Y   = RING_Y - RING_SIZE - GAP_INFO

-- Total frame height (BADGE_ROWS rows + gaps below sep)
local UI_H = CALIB_H + RING_PAD + RING_SIZE + GAP_INFO
           + (BADGE_H * BADGE_ROWS) + (BADGE_GAP * BADGE_ROWS)
           + GAP_VIGN + 16         -- InfoText line
           + GAP_BAR + BAR_H
           + 22 + BOT_PAD

-- ============================================================================
-- MAIN COMPASS FRAME
-- ============================================================================
local PreyUI = CreateFrame("Frame", "DT_PreyUI", UIParent, "BackdropTemplate")
PreyUI:SetSize(UI_W, UI_H)
PreyUI:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
PreyUI:SetMovable(true)
PreyUI:EnableMouse(true)
PreyUI:RegisterForDrag("LeftButton")
PreyUI:SetClampedToScreen(true)
PreyUI:SetFrameStrata("MEDIUM")
PreyUI:Hide()

PreyUI:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=8, edgeSize=16,
    insets={left=5,right=5,top=5,bottom=5},
})
PreyUI:SetBackdropColor(0,0,0,0.9)
PreyUI:SetBackdropBorderColor(0.45,0.03,0.03,0.95)

PreyUI:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then self:StartMoving() end
end)
PreyUI:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    if not DelveTrackerDB then DelveTrackerDB = {} end
    local pt, _, rpt, x, y = self:GetPoint()
    DelveTrackerDB.preyPos = { pt=pt, rpt=rpt, x=x, y=y }
end)

-- Apply scale to the compass frame (NOT to the settings panel)
local function ApplyScale(sc)
    sc = math_max(0.5, math_min(2.0, sc))
    S.scale = sc
    PreyUI:SetScale(sc)
end

-- Apply alpha/opacity - ALLEEN op de achtergrond (backdrop), NIET op tekst/images.
-- SetAlpha() op het hele frame schaalt ook kinderframes (tekst, naald, ring) mee,
-- wat ongewenst is. In plaats daarvan passen we alleen de backdrop-kleur alpha aan.
local BASE_BG_R, BASE_BG_G, BASE_BG_B = 0, 0, 0
local BASE_BD_R, BASE_BD_G, BASE_BD_B = 0.45, 0.03, 0.03
local function ApplyAlpha(al)
    al = math_max(0.1, math_min(1.0, al))
    S.alpha = al
    -- Backdrop achtergrond alpha instellen (alleen background, geen tekst/images)
    PreyUI:SetBackdropColor(BASE_BG_R, BASE_BG_G, BASE_BG_B, al * 0.9)
    PreyUI:SetBackdropBorderColor(BASE_BD_R, BASE_BD_G, BASE_BD_B, al * 0.95)
end

-- ============================================================================
-- TITLE IMAGE
-- ============================================================================
local TitleImg = PreyUI:CreateTexture(nil,"OVERLAY")
TitleImg:SetSize(TITLE_W, TITLE_H)
TitleImg:SetPoint("BOTTOM", PreyUI, "TOP", 0, -14)
TitleImg:SetTexture(M("Title_PreyTracker"))

local TitleTxt = PreyUI:CreateFontString(nil,"OVERLAY")
TitleTxt:SetFont("Fonts\\2002.ttf",16,"OUTLINE")
TitleTxt:SetPoint("BOTTOM", PreyUI, "TOP", 0, 8)
TitleTxt:SetJustifyH("CENTER")
TitleTxt:SetText(C_RED.."[ HUNTING PREY ]|r")
TitleTxt:Hide()

C_Timer.After(0.1, function()
    if not TitleImg:GetTexture() then TitleImg:Hide(); TitleTxt:Show() end
end)

-- ============================================================================
-- COMBAT FADE - respects S.alpha and S.combatFade
-- ============================================================================
local FADE_S    = 0.05
local tgtAlpha  = 1.0
local curAlpha  = 1.0

-- COMBAT FADE - alleen op backdrop, NIET op tekst/naald/ring.
-- GetOutCombatAlpha/GetInCombatAlpha retourneren een backdrop-multiplier (0..1).
-- StepFade past SetBackdropColor alpha aan - tekst en images blijven volledig zichtbaar.
local function GetOutCombatAlpha() return S.alpha or 1.0 end
local function GetInCombatAlpha()
    if not S.combatFade then return S.alpha or 1.0 end
    return (S.alpha or 1.0) * 0.4
end

local function ApplyBackdropAlpha(al)
    PreyUI:SetBackdropColor(BASE_BG_R, BASE_BG_G, BASE_BG_B, al * 0.9)
    PreyUI:SetBackdropBorderColor(BASE_BD_R, BASE_BD_G, BASE_BD_B, al * 0.95)
end

local function StepFade()
    if not PreyUI:IsShown() then return end
    if math_abs(curAlpha-tgtAlpha) <= FADE_S then
        curAlpha = tgtAlpha; ApplyBackdropAlpha(curAlpha); return
    end
    curAlpha = curAlpha + (tgtAlpha > curAlpha and FADE_S or -FADE_S)
    ApplyBackdropAlpha(curAlpha)
    C_Timer.After(0.02, StepFade)
end

local FadeEvtFrame = CreateFrame("Frame")
FadeEvtFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
FadeEvtFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
FadeEvtFrame:SetScript("OnEvent", function(_,ev)
    tgtAlpha = (ev=="PLAYER_REGEN_DISABLED") and GetInCombatAlpha() or GetOutCombatAlpha()
    StepFade()
end)
PreyUI:HookScript("OnShow", function()
    curAlpha = InCombatLockdown() and GetInCombatAlpha() or GetOutCombatAlpha()
    tgtAlpha = curAlpha; ApplyBackdropAlpha(curAlpha)
end)

-- ============================================================================
-- GEAR BUTTON ([S]) - top-left, opens settings panel
-- ============================================================================
local GearBtn = CreateFrame("Button", nil, PreyUI)
GearBtn:SetSize(22, 22)
GearBtn:SetPoint("TOPLEFT", PreyUI, "TOPLEFT", 8, -3)
GearBtn:SetFrameStrata("DIALOG")
local GearBG = GearBtn:CreateTexture(nil,"BACKGROUND")
GearBG:SetAllPoints()
GearBG:SetColorTexture(0.15,0.05,0.05,0.9)
local GearTxt = GearBtn:CreateFontString(nil,"OVERLAY")
GearTxt:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
GearTxt:SetPoint("CENTER")
GearTxt:SetText(C_DIM.."S|r")

GearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self,"ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetText("Prey Tracker Settings",1,1,1,1,true)
    GameTooltip:AddLine("|cffaaaaaa Click to open settings panel|r",1,1,1,true)
    GameTooltip:AddLine("|cffaaaaaa /prey cal  - needle offset only|r",1,1,1,true)
    GameTooltip:Show()
end)
GearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================================
-- CALIBRATION BAR (now inside settings panel, but keep strip for divider)
-- ============================================================================
local CalibDiv = PreyUI:CreateTexture(nil,"ARTWORK")
CalibDiv:SetSize(UI_W-40, 1)
CalibDiv:SetPoint("TOP", PreyUI, "TOP", 0, -(CALIB_H+2))
CalibDiv:SetColorTexture(0.3,0.05,0.05,0.5)

-- ============================================================================
-- COMPASS RING
-- ============================================================================
local RingTex = PreyUI:CreateTexture(nil,"ARTWORK")
RingTex:SetSize(RING_SIZE, RING_SIZE)
RingTex:SetPoint("TOP", PreyUI, "TOP", 0, RING_Y)
RingTex:SetTexture(M("Background_Ring"))
C_Timer.After(0.1, function()
    if not RingTex:GetTexture() then
        RingTex:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        RingTex:SetVertexColor(0.65,0.05,0.0,1.0)
    end
end)

local RingCenter = CreateFrame("Frame", nil, PreyUI)
RingCenter:SetSize(2, 2)
RingCenter:SetPoint("TOP", PreyUI, "TOP", 0, RING_CY)

-- ============================================================================
-- COMPASS NEEDLE (identical V3 logic - TGA + fallback, no race condition)
-- ============================================================================
local ArrowTex = PreyUI:CreateTexture(nil,"OVERLAY")
ArrowTex:SetSize(ARROW_SZ, ARROW_SZ)
ArrowTex:SetPoint("CENTER", RingCenter, "CENTER", 0, 0)
ArrowTex:SetTexture(M("Compass_Arrow"))
ArrowTex:Hide()

local FbHead = PreyUI:CreateTexture(nil,"OVERLAY")
FbHead:SetSize(5, 60)
FbHead:SetColorTexture(0.9,0.15,0.0,1.0)
FbHead:SetPoint("CENTER", RingCenter, "CENTER", 0, 30)
FbHead:Hide()

local FbTail = PreyUI:CreateTexture(nil,"OVERLAY")
FbTail:SetSize(8, 25)
FbTail:SetColorTexture(0.45,0.0,0.0,0.85)
FbTail:SetPoint("CENTER", RingCenter, "CENTER", 0, -12)
FbTail:Hide()

local needlePath = "none"
C_Timer.After(0.15, function()
    needlePath = ArrowTex:GetTexture() and "tga" or "fallback"
end)

local CenterPin = PreyUI:CreateTexture(nil,"OVERLAY")
CenterPin:SetSize(12, 12)
CenterPin:SetPoint("CENTER", RingCenter, "CENTER", 0, 0)
CenterPin:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Background")
CenterPin:SetVertexColor(0.65,0.0,0.0,1.0)
CenterPin:Hide()

local function RotateNeedle(angle)
    if needlePath == "tga" then
        ArrowTex:SetRotation(angle)
    elseif needlePath == "fallback" then
        local hd, td = 30, 12
        local sinA, cosA = math_sin(angle), math_cos(angle)
        FbHead:ClearAllPoints()
        FbHead:SetPoint("CENTER", RingCenter, "CENTER", hd*sinA, hd*cosA)
        FbHead:SetRotation(angle)
        FbTail:ClearAllPoints()
        FbTail:SetPoint("CENTER", RingCenter, "CENTER", -td*sinA, -td*cosA)
        FbTail:SetRotation(angle)
    end
end

local function SetNeedleVisible(show)
    if show then
        if needlePath == "tga" then
            ArrowTex:Show(); FbHead:Hide(); FbTail:Hide()
        elseif needlePath == "fallback" then
            ArrowTex:Hide(); FbHead:Show(); FbTail:Show()
        end
        CenterPin:Show()
    else
        ArrowTex:Hide(); FbHead:Hide(); FbTail:Hide(); CenterPin:Hide()
    end
end

-- ============================================================================
-- RING TEXT - StateText, DistText, EnemyText, DiffBadge, NoAngleTxt
-- ============================================================================
local StateText = PreyUI:CreateFontString(nil,"OVERLAY")
StateText:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
StateText:SetPoint("CENTER", RingCenter, "CENTER", 0, 58)
StateText:SetJustifyH("CENTER")

local DistText = PreyUI:CreateFontString(nil,"OVERLAY")
DistText:SetFont("Fonts\\2002.ttf",26,"OUTLINE")
DistText:SetPoint("CENTER", RingCenter, "CENTER", 0, -18)
DistText:SetJustifyH("CENTER")
DistText:SetWidth(RING_SIZE-60)

local EnemyText = PreyUI:CreateFontString(nil,"OVERLAY")
EnemyText:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
EnemyText:SetPoint("TOP", DistText, "BOTTOM", 0, -3)
EnemyText:SetJustifyH("CENTER")
EnemyText:SetWidth(RING_SIZE-60)

-- Difficulty badge: small colored label below enemy name (inside ring)
local DiffBadge = PreyUI:CreateFontString(nil,"OVERLAY")
DiffBadge:SetFont("Fonts\\2002.ttf",10,"OUTLINE")
DiffBadge:SetPoint("TOP", EnemyText, "BOTTOM", 0, -3)
DiffBadge:SetJustifyH("CENTER")
DiffBadge:SetWidth(RING_SIZE-80)

local TrapModeTxt = PreyUI:CreateFontString(nil,"OVERLAY")
TrapModeTxt:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
TrapModeTxt:SetPoint("CENTER", RingCenter, "CENTER", 0, 40)
TrapModeTxt:SetJustifyH("CENTER")
TrapModeTxt:Hide()

local NoAngleTxt = PreyUI:CreateFontString(nil,"OVERLAY")
NoAngleTxt:SetFont("Fonts\\2002.ttf",10,"OUTLINE")
NoAngleTxt:SetPoint("CENTER", RingCenter, "CENTER", 0, 0)
NoAngleTxt:SetJustifyH("CENTER")
NoAngleTxt:SetWidth(RING_SIZE-60)
NoAngleTxt:Hide()

-- ============================================================================
-- INFO STRIP - separator, badge grid (4 badges max), InfoText
-- ============================================================================
local Sep1 = PreyUI:CreateTexture(nil,"ARTWORK")
Sep1:SetSize(UI_W-40, 1)
Sep1:SetPoint("TOP", PreyUI, "TOP", 0, SEP_Y)
Sep1:SetColorTexture(0.5,0.05,0.05,0.7)

-- Badge grid: 4 FontStrings arranged 2x2
-- Positions: TL, TR (row 1), BL, BR (row 2)
-- We calculate positions manually since WoW has no flexbox
local BADGE_SLOT_W = (UI_W - 40) / 2 - 4
local BadgeFrames = {}
for i = 1, 4 do
    local b = PreyUI:CreateFontString(nil, "OVERLAY")
    b:SetFont("Fonts\\2002.ttf", 11, "OUTLINE")
    b:SetWidth(BADGE_SLOT_W)
    b:SetHeight(BADGE_H)
    b:SetJustifyH("CENTER")
    local col = ((i-1) % 2)      -- 0=left, 1=right
    local row = math.floor((i-1) / 2)  -- 0=top, 1=bottom
    local xOff = col == 0 and -(BADGE_SLOT_W/2 + 2) or (BADGE_SLOT_W/2 + 2)
    local yOff = -(8 + row * (BADGE_H + BADGE_GAP))
    b:SetPoint("TOP", Sep1, "BOTTOM", xOff, yOff)
    b:Hide()
    BadgeFrames[i] = b
end

-- InfoText anchors below badge grid row 2
local InfoText = PreyUI:CreateFontString(nil,"OVERLAY")
InfoText:SetFont("Fonts\\2002.ttf",12,"OUTLINE")
InfoText:SetPoint("TOP", Sep1, "BOTTOM", 0, -(8 + BADGE_ROWS*(BADGE_H+BADGE_GAP) + GAP_VIGN))
InfoText:SetJustifyH("CENTER")
InfoText:SetWidth(UI_W-20)

local Sep2 = PreyUI:CreateTexture(nil,"ARTWORK")
Sep2:SetSize(UI_W-40, 1)
Sep2:SetPoint("TOP", InfoText, "BOTTOM", 0, -(GAP_BAR-4))
Sep2:SetColorTexture(0.5,0.05,0.05,0.45)

-- ============================================================================
-- PROGRESS BAR (identical to V3 - original TGA preserved)
-- ============================================================================
local BarFrame = CreateFrame("Frame", nil, PreyUI)
BarFrame:SetSize(BAR_W, BAR_H)
BarFrame:SetPoint("TOP", InfoText, "BOTTOM", 0, -GAP_BAR)

local BarBGTex = PreyUI:CreateTexture(nil,"ARTWORK")
BarBGTex:SetSize(BAR_W, BAR_H)
BarBGTex:SetPoint("CENTER", BarFrame, "CENTER", 0, 0)
BarBGTex:SetTexture(M("ProgressBar_BG"))
C_Timer.After(0.1, function()
    if not BarBGTex:GetTexture() then BarBGTex:SetColorTexture(0.08,0.02,0.02,0.95) end
end)

local PreyBar = CreateFrame("StatusBar", nil, BarFrame)
PreyBar:SetSize(BAR_TW, BAR_IH)
PreyBar:SetPoint("TOPLEFT", BarFrame, "TOPLEFT", BAR_IX, -BAR_IY)
PreyBar:SetMinMaxValues(0, 1)
PreyBar:SetValue(0)
PreyBar:SetStatusBarTexture(M("ProgressBar_Fill"))
C_Timer.After(0.1, function()
    local st = PreyBar:GetStatusBarTexture()
    if st and not st:GetTexture() then
        PreyBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        PreyBar:SetStatusBarColor(0.8,0,0,1)
    end
end)

local DripTex = PreyUI:CreateTexture(nil,"ARTWORK")
DripTex:SetSize(BAR_W, 50)
DripTex:SetPoint("TOP", BarFrame, "BOTTOM", 0, 8)
DripTex:SetTexture(M("ProgressBar_Fill"))
DripTex:SetTexCoord(0,1,0.5,1)

local BarPctTxt = PreyUI:CreateFontString(nil,"OVERLAY")
BarPctTxt:SetFont("Fonts\\2002.ttf",12,"OUTLINE")
BarPctTxt:SetPoint("CENTER", BarFrame, "CENTER", 0, -(BAR_IY-BAR_H/2)-BAR_IH/2)
BarPctTxt:SetJustifyH("CENTER")
BarPctTxt:SetText(C_GREY.."Hunt Progress  0%|r")

-- ============================================================================
-- ACTION TICKER (scrolling hints at bottom)
-- Uses a ClipFrame to mask overflow. Ticker scrolls if text is too wide.
-- Controlled by S.tickerOn. Static fallback when disabled or short text.
-- ============================================================================
local TICKER_H   = 18
local TICKER_SPD = 40   -- pixels per second

local TickerClip = CreateFrame("Frame", nil, PreyUI)
TickerClip:SetSize(UI_W - 30, TICKER_H)
TickerClip:SetPoint("BOTTOM", PreyUI, "BOTTOM", 0, BOT_PAD)
TickerClip:SetClipsChildren(true)

local TickerTxt = TickerClip:CreateFontString(nil,"OVERLAY")
TickerTxt:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
TickerTxt:SetJustifyH("LEFT")
TickerTxt:SetPoint("LEFT", TickerClip, "LEFT", 0, 0)

-- Ticker state
local tickerText  = ""
local tickerOffset = 0
local tickerWidth  = 0
local TICKER_PAD  = 60   -- gap between end and restart

local function UpdateTickerText(text)
    if text == tickerText then return end
    tickerText   = text
    tickerOffset = 0
    TickerTxt:SetText(text)
    TickerTxt:ClearAllPoints()
    TickerTxt:SetPoint("LEFT", TickerClip, "LEFT", 0, 0)
    -- Measure width next frame after text is set
    C_Timer.After(0.05, function()
        tickerWidth = TickerTxt:GetStringWidth()
    end)
end

-- Called every ticker tick (0.02s = 50 FPS). Scrolls text if wider than frame.
local function StepTicker()
    if not S.tickerOn then return end
    local clipW = TickerClip:GetWidth()
    if tickerWidth <= clipW then
        -- Text fits: center it statically
        if tickerOffset ~= 0 then
            tickerOffset = 0
            TickerTxt:ClearAllPoints()
            TickerTxt:SetPoint("CENTER", TickerClip, "CENTER", 0, 0)
        end
        return
    end
    -- Scroll: move left by SPD * dt. dt ~ 0.02
    tickerOffset = tickerOffset + TICKER_SPD * 0.02
    local totalWidth = tickerWidth + TICKER_PAD
    if tickerOffset >= totalWidth then tickerOffset = 0 end
    TickerTxt:ClearAllPoints()
    TickerTxt:SetPoint("LEFT", TickerClip, "LEFT", -tickerOffset, 0)
end

-- ============================================================================
-- SETTINGS PANEL - separate frame on UIParent (not child of PreyUI)
-- This frame does NOT scale with the compass. It's always full-size.
-- ============================================================================
local SETT_W, SETT_H = 340, 322
local SettPanel = CreateFrame("Frame", "DT_PreySettingsPanel", UIParent, "BackdropTemplate")
SettPanel:SetSize(SETT_W, SETT_H)
SettPanel:SetFrameStrata("DIALOG")
SettPanel:SetClampedToScreen(true)
SettPanel:SetMovable(true)
SettPanel:EnableMouse(true)
SettPanel:RegisterForDrag("LeftButton")
SettPanel:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then self:StartMoving() end
end)
SettPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
SettPanel:Hide()

SettPanel:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=8, edgeSize=16,
    insets={left=5,right=5,top=5,bottom=5},
})
SettPanel:SetBackdropColor(0.04,0.0,0.0,0.97)
SettPanel:SetBackdropBorderColor(0.6,0.05,0.05,1.0)

-- Position settings panel to the right of the compass when opened
local function OpenSettings()
    if InCombatLockdown() then
        print("|cffcc3300[PreyTracker]|r Settings not available in combat.")
        return
    end
    if SettPanel:IsShown() then
        SettPanel:Hide()
        GearTxt:SetText(C_DIM.."S|r")
        return
    end
    -- Position next to compass
    SettPanel:ClearAllPoints()
    SettPanel:SetPoint("TOPLEFT", PreyUI, "TOPRIGHT", 10, 0)
    SettPanel:Show()
    GearTxt:SetText("|cffff9900S|r")
end

GearBtn:SetScript("OnClick", OpenSettings)

-- Header
local SHdr = SettPanel:CreateFontString(nil,"OVERLAY")
SHdr:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
SHdr:SetPoint("TOP", SettPanel, "TOP", 0, -12)
SHdr:SetJustifyH("CENTER")
SHdr:SetText("|cffcc4444PREY TRACKER SETTINGS|r")

local SHdrDiv = SettPanel:CreateTexture(nil,"ARTWORK")
SHdrDiv:SetSize(SETT_W-20, 1)
SHdrDiv:SetPoint("TOP", SettPanel, "TOP", 0, -28)
SHdrDiv:SetColorTexture(0.5,0.05,0.05,0.7)

-- Close button
local SCloseBtn = CreateFrame("Button", nil, SettPanel)
SCloseBtn:SetSize(20, 20)
SCloseBtn:SetPoint("TOPRIGHT", SettPanel, "TOPRIGHT", -8, -6)
SCloseBtn:SetFrameStrata("DIALOG")
local SCloseTxt = SCloseBtn:CreateFontString(nil,"OVERLAY")
SCloseTxt:SetFont("Fonts\\2002.ttf",14,"OUTLINE")
SCloseTxt:SetPoint("CENTER")
SCloseTxt:SetText("|cff888888x|r")
SCloseBtn:SetScript("OnClick", function()
    SettPanel:Hide()
    GearTxt:SetText(C_DIM.."S|r")
end)

-- Helper to create a labeled slider row (NO OptionsSliderTemplate - removed in 12.x)
-- Volledig handmatige implementatie: achtergrond + thumb via SetThumbTexture
local function MakeSlider(parent, name, globalName, yOff, min, max, step, fmt)
    local lbl = parent:CreateFontString(nil,"OVERLAY")
    lbl:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, yOff)
    lbl:SetText(C_GREY..name.."|r")
    lbl:SetWidth(90)
    lbl:SetJustifyH("LEFT")

    -- Achtergrond track (handmatig, geen template)
    local track = parent:CreateTexture(nil,"ARTWORK")
    track:SetSize(170, 4)
    track:SetPoint("TOPLEFT", parent, "TOPLEFT", 110, yOff+10)
    track:SetColorTexture(0.25, 0.06, 0.06, 0.9)

    local sl = CreateFrame("Slider", globalName, parent)
    sl:SetSize(170, 16)
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", 110, yOff+4)
    sl:SetMinMaxValues(min, max)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    sl:GetThumbTexture():SetSize(14, 14)
    sl:SetValue(min)
    sl:EnableMouseWheel(true)
    sl:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetValue()
        local mn, mx = self:GetMinMaxValues()
        self:SetValue(math_max(mn, math_min(mx, cur + delta * step)))
    end)

    local val = parent:CreateFontString(nil,"OVERLAY")
    val:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
    val:SetPoint("TOPLEFT", parent, "TOPLEFT", 286, yOff)
    val:SetWidth(40)
    val:SetJustifyH("LEFT")
    val:SetText(C_WHITE.."-|r")

    return sl, val, lbl
end

-- Scale slider
local ScaleSl, ScaleVal = MakeSlider(SettPanel, "Scale", "DT_PreyScaleSl",
    -38, 50, 200, 5, "%d%%")
ScaleSl:SetScript("OnValueChanged", function(self, v)
    local pct = math.floor(v + 0.5)
    ScaleVal:SetText(C_WHITE..pct.."%|r")
    ApplyScale(pct / 100.0)
    SaveSettings()
end)

-- Opacity slider
local AlphaSl, AlphaVal = MakeSlider(SettPanel, "Opacity", "DT_PreyAlphaSl",
    -64, 10, 100, 5, "%d%%")
AlphaSl:SetScript("OnValueChanged", function(self, v)
    local pct = math.floor(v + 0.5)
    AlphaVal:SetText(C_WHITE..pct.."%|r")
    ApplyAlpha(pct / 100.0)   -- past alleen backdrop alpha aan
    if not InCombatLockdown() then
        tgtAlpha = S.alpha; curAlpha = S.alpha
        -- ApplyAlpha zet al de backdrop - geen SetAlpha() op het hele frame nodig
    end
    SaveSettings()
end)

-- Needle offset slider
local OffsetSl, OffsetVal = MakeSlider(SettPanel, "Needle offset", "DT_PreyOffsetSl",
    -90, -180, 180, 1, "%+d")
OffsetSl:SetScript("OnValueChanged", function(self, v)
    local deg = math.floor(v + 0.5)
    OffsetVal:SetText(string.format(C_WHITE.."%+d|r", deg))
    local rad = deg * math_pi / 180.0
    S.needleOffset = rad
    if addonTable.SaveNeedleOffset then
        addonTable.SaveNeedleOffset(rad)
    elseif addonTable.DT_preytracker then
        addonTable.DT_preytracker.needleOffset = rad
    end
    SaveSettings()
end)

-- Offset reset button
local OffReset = CreateFrame("Button", nil, SettPanel)
OffReset:SetSize(34, 16)
OffReset:SetPoint("TOPLEFT", SettPanel, "TOPLEFT", 286, -90)
OffReset:SetFrameStrata("DIALOG")
local OffResetBG = OffReset:CreateTexture(nil,"BACKGROUND")
OffResetBG:SetAllPoints(); OffResetBG:SetColorTexture(0.18,0.06,0.06,0.95)
local OffResetTxt = OffReset:CreateFontString(nil,"OVERLAY")
OffResetTxt:SetFont("Fonts\\2002.ttf",10,"OUTLINE")
OffResetTxt:SetPoint("CENTER"); OffResetTxt:SetText(C_GREY.."  0  |r")
OffReset:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self,"ANCHOR_BOTTOM")
    GameTooltip:SetText("Reset needle offset to 0",1,1,1); GameTooltip:Show()
end)
OffReset:SetScript("OnLeave", function() GameTooltip:Hide() end)
OffReset:SetScript("OnClick", function() OffsetSl:SetValue(0) end)

-- Divider before toggles
local SDiv2 = SettPanel:CreateTexture(nil,"ARTWORK")
SDiv2:SetSize(SETT_W-20, 1)
SDiv2:SetPoint("TOP", SettPanel, "TOP", 0, -112)
SDiv2:SetColorTexture(0.3,0.04,0.04,0.5)

-- Helper to create a checkbox toggle row
local function MakeToggle(parent, label, yOff, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, yOff)
    local lbl = parent:CreateFontString(nil,"OVERLAY")
    lbl:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
    lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    lbl:SetText(C_GREY..label.."|r")
    cb:SetScript("OnClick", function(self)
        onChange(self:GetChecked())
        SaveSettings()
    end)
    return cb
end

local AutoShowCB = MakeToggle(SettPanel, "Auto-show on hunt start", -122, function(v)
    S.autoShow = v
end)

local CombatCB = MakeToggle(SettPanel, "Fade in combat", -146, function(v)
    S.combatFade = v
end)

local TickerCB = MakeToggle(SettPanel, "Scroll long action hints", -170, function(v)
    S.tickerOn = v
    if not v then
        tickerOffset = 0
        TickerTxt:ClearAllPoints()
        TickerTxt:SetPoint("CENTER", TickerClip, "CENTER", 0, 0)
    end
end)

local BadgeCB = MakeToggle(SettPanel, "Show affix badges", -194, function(v)
    S.affixBadges = v
    if not v then for _, b in ipairs(BadgeFrames) do b:Hide() end end
end)

-- Divider before buttons
local SDiv3 = SettPanel:CreateTexture(nil,"ARTWORK")
SDiv3:SetSize(SETT_W-20, 1)
SDiv3:SetPoint("BOTTOM", SettPanel, "BOTTOM", 0, 40)
SDiv3:SetColorTexture(0.3,0.04,0.04,0.5)

-- Reset all button
local SResetBtn = CreateFrame("Button", nil, SettPanel)
SResetBtn:SetSize(100, 22)
SResetBtn:SetPoint("BOTTOMLEFT", SettPanel, "BOTTOMLEFT", 14, 10)
SResetBtn:SetFrameStrata("DIALOG")
local SResetBG = SResetBtn:CreateTexture(nil,"BACKGROUND")
SResetBG:SetAllPoints(); SResetBG:SetColorTexture(0.15,0.04,0.04,0.95)
local SResetTxt = SResetBtn:CreateFontString(nil,"OVERLAY")
SResetTxt:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
SResetTxt:SetPoint("CENTER"); SResetTxt:SetText(C_GREY.."Reset Defaults|r")

SResetBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP")
    GameTooltip:SetText("Reset all settings to default",1,1,1); GameTooltip:Show()
end)
SResetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================================
-- PREY TRACKER AAN/UIT TOGGLE in settings panel
-- ============================================================================
local EnableCB = MakeToggle(SettPanel, "Prey Tracker ingeschakeld", -218, function(v)
    if v then
        if addonTable.PreyTrackerEnable then addonTable.PreyTrackerEnable() end
    else
        if addonTable.PreyTrackerDisable then addonTable.PreyTrackerDisable() end
    end
    if not DelveTrackerDB then DelveTrackerDB = {} end
    DelveTrackerDB.preyEnabled = v
end)

-- Sync enable checkbox op OpenSettings
local _origOpenSettings = OpenSettings
OpenSettings = function()
    _origOpenSettings()
    if SettPanel:IsShown() then
        local enabled = DelveTrackerDB and (DelveTrackerDB.preyEnabled ~= false) or true
        EnableCB:SetChecked(enabled)
    end
end

-- Close panel button
local SCloseBtn2 = CreateFrame("Button", nil, SettPanel)
SCloseBtn2:SetSize(80, 22)
SCloseBtn2:SetPoint("BOTTOMRIGHT", SettPanel, "BOTTOMRIGHT", -14, 10)
SCloseBtn2:SetFrameStrata("DIALOG")
local SCl2BG = SCloseBtn2:CreateTexture(nil,"BACKGROUND")
SCl2BG:SetAllPoints(); SCl2BG:SetColorTexture(0.25,0.08,0.08,0.95)
local SCl2Txt = SCloseBtn2:CreateFontString(nil,"OVERLAY")
SCl2Txt:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
SCl2Txt:SetPoint("CENTER"); SCl2Txt:SetText("|cffcc4444Close|r")
SCloseBtn2:SetScript("OnClick", function()
    SettPanel:Hide()
    GearTxt:SetText(C_DIM.."S|r")
end)

-- Apply all settings values to the sliders and checkboxes
local function SyncSettingsUI()
    local sc  = math.floor((S.scale  or 1.0) * 100 + 0.5)
    local al  = math.floor((S.alpha  or 1.0) * 100 + 0.5)
    local off = math.floor((S.needleOffset or 0) * 180.0 / math_pi + 0.5)
    ScaleSl:SetValue(sc)
    ScaleVal:SetText(C_WHITE..sc.."%|r")
    AlphaSl:SetValue(al)
    AlphaVal:SetText(C_WHITE..al.."%|r")
    OffsetSl:SetValue(off)
    OffsetVal:SetText(string.format(C_WHITE.."%+d|r", off))
    AutoShowCB:SetChecked(S.autoShow ~= false)
    CombatCB:SetChecked(S.combatFade ~= false)
    TickerCB:SetChecked(S.tickerOn ~= false)
    BadgeCB:SetChecked(S.affixBadges ~= false)
end

-- Reset defaults handler
SResetBtn:SetScript("OnClick", function()
    for k, v in pairs(SETTINGS_DEFAULTS) do S[k] = v end
    SaveSettings()
    SyncSettingsUI()
    ApplyScale(S.scale)
    ApplyAlpha(S.alpha); tgtAlpha = S.alpha; curAlpha = S.alpha
    if addonTable.SaveNeedleOffset then addonTable.SaveNeedleOffset(0) end
    if addonTable.DT_preytracker then addonTable.DT_preytracker.needleOffset = 0 end
    print("|cff00dfff[PreyTracker]|r Settings reset to defaults.")
end)

-- ============================================================================
-- AUTO-SHOW
-- ============================================================================
local lastAutoCheck = 0
local function CheckAutoShow()
    local now = GetTime()
    if (now - lastAutoCheck) < 2.0 then return end
    lastAutoCheck = now
    local prey = addonTable.DT_preytracker
    if not prey or prey.isTesting then return end
    -- BUG-T03: respect admin panel plugin toggle
    if DelveTrackerDB and DelveTrackerDB.PluginStates and
       DelveTrackerDB.PluginStates["PreyTracker"] == false then
        if PreyUI:IsShown() then PreyUI:Hide() end
        return
    end
    if not S.autoShow then return end
    local ok, qid = pcall(C_QuestLog.GetActivePreyQuest)
    if ok and qid and qid ~= 0 then
        if not PreyUI:IsShown() then PreyUI:Show() end
    else
        if PreyUI:IsShown() and not prey.active then PreyUI:Hide() end
    end
end

-- ============================================================================
-- BADGE DATA - defines content for each badge slot
-- Returns up to 4 badge strings (nil = slot unused)
-- ============================================================================
local function GetBadgeData(prey)
    if not S.affixBadges then return {}, 0 end
    local items = {}
    local traps = prey.nearbyTraps   or 0
    local angus  = prey.nearbyAnguish or 0
    if traps > 0 then
        items[#items+1] = string.format(C_TRAP.."[!] %d Trap|r", traps)
    end
    if angus > 0 then
        items[#items+1] = string.format(C_ANG.."[x] %d Anguish|r", angus)
    end
    if prey.affix_echo    then items[#items+1] = C_ECHO.."Echo|r"    end
    if prey.affix_bloody  then items[#items+1] = C_WARN.."Bloody|r"  end
    if prey.affix_torment then items[#items+1] = C_HARD.."Torment|r" end
    if prey.affix_gore    then items[#items+1] = C_HARD.."Gore|r"    end
    return items, #items
end

-- ============================================================================
-- REFRESH HUD - reads addonTable.DT_preytracker, updates all visuals
-- ============================================================================
local function RefreshPreyUI()
    local prey = addonTable.DT_preytracker
    if not prey or not prey.active then
        DistText:SetText(C_GREY.."-- yd|r")
        EnemyText:SetText(C_GREY.."No active hunt|r")
        DiffBadge:SetText("")
        StateText:SetText("")
        InfoText:SetText(C_GREY.."Start a hunt at Astalor's Table|r")
        PreyBar:SetValue(0)
        BarPctTxt:SetText(C_GREY.."Hunt Progress  0%|r")
        UpdateTickerText("|cffaaaaaa-|r")
        TrapModeTxt:Hide(); NoAngleTxt:Hide()
        SetNeedleVisible(false)
        for _, b in ipairs(BadgeFrames) do b:Hide() end
        return
    end

    -- NEEDLE
    if prey.trapMode then
        SetNeedleVisible(true); NoAngleTxt:Hide()
        RotateNeedle(prey.trapAngle or 0)
        TrapModeTxt:SetText(C_TRAP.."[!] Trap nearby|r"); TrapModeTxt:Show()
        if needlePath=="tga" then ArrowTex:SetVertexColor(1.0,0.85,0.0,1.0) end
    elseif prey.angleReady then
        SetNeedleVisible(true); NoAngleTxt:Hide(); TrapModeTxt:Hide()
        RotateNeedle(prey.angle or 0)
        if needlePath=="tga" then ArrowTex:SetVertexColor(1.0,1.0,1.0,1.0) end
    else
        SetNeedleVisible(false); TrapModeTxt:Hide()
        local ps = prey.progressState or 0
        if ps == 0 then
            NoAngleTxt:SetText(C_COLD.."Go to the zone\n|r"..C_GREY.."Needle appears in zone|r")
        else
            NoAngleTxt:SetText(C_GREY.."Walk a few steps\nfor direction|r")
        end
        NoAngleTxt:Show()
    end

    -- STATE
    local ps  = prey.progressState or 0
    local stc = STATE_COL[ps] or C_GREY
    local stl = STATE_LBL[ps] or "COLD"
    StateText:SetText(stc.."[ "..stl.." ]|r")

    -- DISTANCE
    local dist = prey.distance or 0
    if dist >= 1 then
        DistText:SetText(string.format(C_DIST.."%.0f yd|r", dist))
    elseif dist > 0 then
        DistText:SetText(C_HOT.."< 1 yd|r")
    else
        DistText:SetText(C_GREY.."-- yd|r")
    end

    -- ENEMY NAME (name only, no difficulty)
    local clr   = prey.diffColor or C_NRM
    local diff  = prey.difficulty or "Normal"
    local ename = prey.enemyName or "Unknown Prey"
    EnemyText:SetText(clr..ename.."|r")

    -- DIFFICULTY BADGE (small, below name, in ring)
    local diffBadgeStr
    if diff == "Nightmare" then
        diffBadgeStr = "|cffff2200[ NIGHTMARE ]|r"
    elseif diff == "Hard" then
        diffBadgeStr = "|cffff9900[ HARD ]|r"
    else
        diffBadgeStr = "|cff44ff88[ NORMAL ]|r"
    end
    DiffBadge:SetText(diffBadgeStr)

    -- BADGE GRID
    local badges, nBadges = GetBadgeData(prey)
    for i = 1, 4 do
        if badges[i] then
            BadgeFrames[i]:SetText(badges[i])
            BadgeFrames[i]:Show()
        else
            BadgeFrames[i]:Hide()
        end
    end

    -- INFO LINE (stage + zone, no difficulty - it's in badge)
    local zoneStr = prey.zoneName and (C_GREY.."  "..prey.zoneName.."|r") or ""
    InfoText:SetText(string.format(C_GREY.."Stage %d|r"..zoneStr, prey.stage or 1))

    -- PROGRESS BAR
    local prog = math_max(0, math_min(1, prey.progress or 0))
    PreyBar:SetValue(prog)
    local pct = math.floor(prog * 100)
    BarPctTxt:SetText(string.format(C_WHITE.."%d%%|r  "..C_GREY.."Hunt Progress|r", pct))

    -- ACTION TICKER - build hints list then set ticker
    local hints = {}
    if ps == 0 then
        hints[#hints+1] = C_COLD.."Go to "..(prey.zoneName or "the zone").."|r"
        hints[#hints+1] = C_GREY.."Warm up - world quests, rares, traps|r"
    elseif ps == 1 then
        hints[#hints+1] = C_WARM.."Follow the needle|r"
        if (prey.nearbyTraps or 0) > 0   then hints[#hints+1] = C_TRAP.."Disarm traps!|r"  end
        if (prey.nearbyAnguish or 0) > 0 then hints[#hints+1] = C_ANG.."Kill Anguish!|r"  end
    elseif ps == 2 then
        hints[#hints+1] = C_HOT.."Crystal found - close in!|r"
        if (prey.nearbyTraps or 0) > 0   then hints[#hints+1] = C_TRAP.."Bring traps|r"   end
        if (prey.nearbyAnguish or 0) > 0 then hints[#hints+1] = C_ANG.."Avoid Anguish|r"  end
    elseif ps == 3 then
        hints[#hints+1] = C_FINAL.."BOSS LOCATED - Attack!|r"
    end
    if prey.affix_echo   then hints[#hints+1] = C_ECHO.."KITE the Echo!|r"           end
    if prey.affix_bloody then hints[#hints+1] = C_WARN.."KILL anything! (Bloody)|r" end
    if #hints == 0 then hints[#hints+1] = C_GREY.."Follow the needle|r" end

    -- Join with separator. If tickerOn, scroll; otherwise show static
    local sep = S.tickerOn and "   |cff444444.|r   " or "   "
    UpdateTickerText(table.concat(hints, sep))
end

-- ============================================================================
-- TEST MODE
-- ============================================================================
local testAngle = 0
local testProg  = 0

local function ToggleTest()
    local prey = addonTable.DT_preytracker
    if not prey.isTesting then
        prey.isTesting=true; prey.active=true; prey.questID=99999
        prey.enemyName="Deliah Gloomsong"; prey.zoneName="Voidstorm"
        prey.difficulty="Nightmare"; prey.diffColor=C_NIGHT
        prey.distance=137; prey.stage=2; prey.progressState=2; prey.progress=0
        prey.nearbyTraps=1; prey.nearbyAnguish=1
        prey.affix_echo=true; prey.affix_bloody=false
        prey.affix_torment=true; prey.affix_gore=false
        prey.angleReady=true; prey.angle=0; prey.trapMode=false
        testAngle=0; testProg=0
        print("|cff00dfff[PreyTracker]|r Test mode |cff00ff88ON|r.")
    else
        prey.isTesting=false; prey.active=false
        prey.angle=0; prey.angleReady=false; prey.progress=0
        testAngle=0; testProg=0
        print("|cffcc3300[PreyTracker]|r Test mode |cffff2200OFF|r.")
        if addonTable.UpdateCompassLogic then addonTable.UpdateCompassLogic() end
    end
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================
SLASH_DTPREY1 = "/prey"

-- Centrale enable/disable helpers (ook bruikbaar door andere modules)
local function PreyTrackerEnable()
    if PreyUI:IsShown() then return end
    PreyUI:Show(); RefreshPreyUI()
    print("|cff00dfff[PreyTracker]|r |cff00ff88Ingeschakeld|r.")
end

local function PreyTrackerDisable()
    if not PreyUI:IsShown() then return end
    addonTable.DT_preytracker.isTesting = false
    PreyUI:Hide(); SettPanel:Hide()
    GearTxt:SetText(C_DIM.."S|r")
    print("|cffcc3300[PreyTracker]|r |cffff2200Uitgeschakeld|r.")
end

-- Exporteer voor settings toggle (DelveTracker core kan dit aanroepen)
addonTable.PreyTrackerEnable  = PreyTrackerEnable
addonTable.PreyTrackerDisable = PreyTrackerDisable

SlashCmdList["DTPREY"] = function(msg)
    msg = strtrim(string.lower(msg or ""))
    -- /pton en /ptoff als directe commando's worden afgevangen door WoW
    -- via SLASH_DTPREY2/3, maar ook als sub-commando ondersteund:
    if msg == "on" or msg == "enable" then
        PreyTrackerEnable()
    elseif msg == "off" or msg == "disable" then
        PreyTrackerDisable()
    elseif msg == "test" then
        if not PreyUI:IsShown() then PreyUI:Show() end
        ToggleTest(); RefreshPreyUI()
    elseif msg == "debug" then
        if addonTable.PreyDebugInfo then addonTable.PreyDebugInfo()
        else print("|cffcc3300[PreyTracker]|r Debug unavailable.") end
    elseif msg == "reset" then
        PreyUI:ClearAllPoints()
        PreyUI:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
        print("|cff00dfff[PreyTracker]|r Positie gereset.")
    elseif msg == "cal" or msg == "calib" then
        OpenSettings()
    elseif msg == "settings" or msg == "set" then
        OpenSettings()
    elseif msg == "help" or msg == "?" then
        print("|cff00dfff[PreyTracker]|r Commands:")
        print("  |cffffffff/prey|r          - toggle aan/uit")
        print("  |cffffffff/pton|r          - zet prey tracker AAN")
        print("  |cffffffff/ptoff|r         - zet prey tracker UIT")
        print("  |cffffffff/prey test|r     - test modus (naald draait)")
        print("  |cffffffff/prey debug|r    - debug info in chat")
        print("  |cffffffff/prey settings|r - open instellingen")
        print("  |cffffffff/prey reset|r    - reset frame positie")
    elseif PreyUI:IsShown() then
        PreyTrackerDisable()
    else
        PreyTrackerEnable()
    end
end

-- /pton en /ptoff als eigen slash commands
SLASH_DTPREYOFF1 = "/ptoff"
SlashCmdList["DTPREYOFF"] = function() PreyTrackerDisable() end

SLASH_DTPREYON1 = "/pton"
SlashCmdList["DTPREYON"] = function() PreyTrackerEnable() end

-- ============================================================================
-- EVENTS + 50 FPS MAIN TICKER
-- ============================================================================
PreyUI:RegisterEvent("PLAYER_LOGIN")
PreyUI:RegisterEvent("QUEST_LOG_UPDATE")
PreyUI:RegisterEvent("ZONE_CHANGED_NEW_AREA")
PreyUI:RegisterEvent("UPDATE_UI_WIDGET")
PreyUI:RegisterEvent("UPDATE_ALL_UI_WIDGETS")

PreyUI:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        LoadSettings()
        SyncSettingsUI()
        ApplyScale(S.scale)
        ApplyAlpha(S.alpha)
        curAlpha = S.alpha; tgtAlpha = S.alpha
        -- Notify tracker of saved needle offset
        if addonTable.SaveNeedleOffset then
            addonTable.SaveNeedleOffset(S.needleOffset)
        elseif addonTable.DT_preytracker then
            addonTable.DT_preytracker.needleOffset = S.needleOffset
        end
        -- Restore saved position
        if DelveTrackerDB and DelveTrackerDB.preyPos then
            local p = DelveTrackerDB.preyPos
            PreyUI:ClearAllPoints()
            PreyUI:SetPoint(p.pt or "CENTER", UIParent, p.rpt or "CENTER",
                p.x or 0, p.y or 40)
        end

        C_Timer.NewTicker(0.02, function()
            CheckAutoShow()
            if not PreyUI:IsShown() then return end
            local prey = addonTable.DT_preytracker
            if not prey then return end
            if prey.isTesting then
                testAngle = testAngle + 0.035
                testProg  = testProg  + 0.0008
                if testAngle >= math_pi*2 then testAngle = 0  end
                if testProg  > 1.0        then testProg  = 0.0 end
                prey.angle=testAngle; prey.angleReady=true; prey.progress=testProg
            else
                if addonTable.UpdateCompassLogic then addonTable.UpdateCompassLogic() end
            end
            RefreshPreyUI()
            StepTicker()
        end)

        C_Timer.After(2.0, CheckAutoShow)

    elseif event == "QUEST_LOG_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UPDATE_UI_WIDGET" or event == "UPDATE_ALL_UI_WIDGETS" then
        lastAutoCheck = 0
        CheckAutoShow()
    end
end)