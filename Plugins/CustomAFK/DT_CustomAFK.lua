if not DT_CustomAFK_Settings then DT_CustomAFK_Settings = {} end

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


DT_CustomAFK_Frame = CreateFrame("Frame", "DT_CustomAFK_Frame", WorldFrame, "BackdropTemplate")
local f = DT_CustomAFK_Frame
f:SetAllPoints(WorldFrame)
f:SetFrameStrata("FULLSCREEN_DIALOG")
f:SetPropagateKeyboardInput(true)
f:SetAlpha(0)
f:Hide()
f.Slots = {}

tinsert(UISpecialFrames, "DT_CustomAFK_Frame")

-- =========================
-- UTILS
-- =========================
local function ToggleMinimap(show)
    if not Minimap then return end
    if show then Minimap:Show() else Minimap:Hide() end
end

-- =========================
-- FADE IN / OUT
-- =========================
local function FadeIn()
    f:Show()
    UIFrameFadeIn(f, 0.5, 0, 1)
    UIParent:Hide()
    ToggleMinimap(false)
    if ObjectiveTrackerFrame then ObjectiveTrackerFrame:Hide() end
end

function FadeOut()
    if f.InGridMode then return end
    
    -- Stop de extra bewegings-monitor
    f:SetScript("OnUpdate", nil)
    MouselookStop()
    
    UIFrameFadeOut(f, 0.3, f:GetAlpha(), 0)
    UIParent:Show()
    ToggleMinimap(true)
    if ObjectiveTrackerFrame then ObjectiveTrackerFrame:Show() end
    
    C_Timer.After(0.3, function()
        if not f.InGridMode then f:Hide() end
    end)
end

-- =========================
-- AFK START LOGICA
-- =========================
local function StartAFK()
    f.InGridMode = false
    f.startTime = GetTime()
    f.oldX, f.oldY = GetCursorPosition() -- Voor muis-detectie
    
    FadeIn()
    
    -- Monitor voor handmatige AFK (/afk)
    f:SetScript("OnUpdate", function(self, elapsed)
        if (GetTime() > (f.startTime or 0) + 1.2) then
            local curX, curY = GetCursorPosition()
            -- Stop als muis beweegt
            if (math.abs(curX - (f.oldX or 0)) > 20 or math.abs(curY - (f.oldY or 0)) > 20) then
                FadeOut()
            end
        end
    end)
    
    -- 3D Model setup
    f.model:SetUnit("player")
    f.model:SetAnimation(69)
    f.model:SetRotation(0.05)

    if DT_RefreshAllSlots then DT_RefreshAllSlots() end
end

-- =========================
-- AFK TRIGGER (FLAG & HANDMATIG)
-- =========================
f:RegisterEvent("PLAYER_FLAGS_CHANGED")
f:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" then
        if UnitIsAFK("player") then
            if not f:IsShown() then StartAFK() end
        else
            if f:IsShown() and not f.InGridMode then FadeOut() end
        end
    end
end)

-- Stop ook bij elke toetsaanslag (voor de zekerheid bij handmatig AFK)
f:SetScript("OnKeyDown", function(_, key)
    if f:IsShown() and not f.InGridMode and (GetTime() > (f.startTime or 0) + 1) then
        FadeOut()
    end
end)

-- =========================
-- COMMANDS & LAYOUT
-- =========================
SlashCmdList["DTAFK"] = function()
    if f:IsShown() then FadeOut() else StartAFK() end
end
SLASH_DTAFK1 = "/dtafk"

local function CreateSlot(id, width, height, x, y, r, g, b)
    local slot = CreateFrame("Frame", nil, f, "BackdropTemplate")
    slot:SetSize(width, height)
    slot:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
    slot.gridBG = slot:CreateTexture(nil, "BACKGROUND")
    slot.gridBG:SetAllPoints(); slot.gridBG:SetColorTexture(r, g, b, 0.3); slot.gridBG:Hide()
    slot.gridBorder = CreateFrame("Frame", nil, slot, "BackdropTemplate")
    slot.gridBorder:SetAllPoints(slot)
    slot.gridBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    slot.gridBorder:SetBackdropBorderColor(1, 1, 1, 0.8); slot.gridBorder:Hide()
    slot.txt = slot:CreateFontString(nil, "OVERLAY")
    slot.txt:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
    slot.txt:SetTextColor(0.85, 0.85, 0.85, 1)
    if id == "MID_TOP" then slot.txt:SetPoint("TOP", slot, "TOP", 0, -20)
    else slot.txt:SetPoint("CENTER", 0, 0) end
    slot.ID_txt = slot:CreateFontString(nil, "OVERLAY")
    slot.ID_txt:SetFont("Fonts\\2002.ttf", 10, "")
    slot.ID_txt:SetTextColor(0.85, 0.85, 0.85, 1)
    slot.ID_txt:SetPoint("BOTTOM", slot, "BOTTOM", 0, 4); slot.ID_txt:SetText("ID: " .. id); slot.ID_txt:Hide()
    f.Slots[id] = slot
    return slot
end

local sw, sh = GetScreenWidth(), GetScreenHeight()
local col, row = sw / 5, 100
local headRow, mH = 140, sh - 140 - 100

CreateSlot("L1", col, headRow, 0, 0, 0, 1, 0)
CreateSlot("MID_TOP", col * 3, headRow, col, 0, 1, 1, 1)
CreateSlot("L2", col, headRow, col * 4, 0, 0, 1, 0)
CreateSlot("SIDE_L", col * 2, mH, 0, headRow, 1, 1, 0)
local modelSlot = CreateSlot("MODEL", col * 2, mH, col * 3, headRow, 1, 1, 0)
f.model = CreateFrame("PlayerModel", nil, modelSlot); f.model:SetAllPoints()
for i = 1, 5 do CreateSlot("B" .. i, col, row, col * (i - 1), sh - row, 1, 0, 0) end

SlashCmdList["DTGRID"] = function()
    f.InGridMode = not f.InGridMode
    if f.InGridMode then f:Show(); f:SetAlpha(1); UIParent:Hide() else f.InGridMode = false; FadeOut() end
    for _, s in pairs(f.Slots) do
        if f.InGridMode then s.gridBorder:Show(); s.gridBG:Show(); s.ID_txt:Show()
        else s.gridBorder:Hide(); s.gridBG:Hide(); s.ID_txt:Hide() end
    end
end
SLASH_DTGRID1 = "/dtgrid"