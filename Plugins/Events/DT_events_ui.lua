local addonName, addonTable = ...

-- WTTheme: centraal kleurensysteem (Fase 3 — T04b)
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


--------------------------------------------------
-- FRAME UI
--------------------------------------------------
local EventsUI = CreateFrame("Frame", "DT_EventsUI", UIParent, "BackdropTemplate")

EventsUI:SetSize(500, 300)
EventsUI:SetPoint("TOP", UIParent, "TOP", 0, -120)

EventsUI:SetFrameStrata("DIALOG")
EventsUI:SetClampedToScreen(true)

EventsUI:SetMovable(true)
EventsUI:EnableMouse(true)
EventsUI:RegisterForDrag("LeftButton")

EventsUI:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then
        self:StartMoving()
    end
end)

EventsUI:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

EventsUI:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})

EventsUI:Hide()

--------------------------------------------------
-- TITLE
--------------------------------------------------
local Title = EventsUI:CreateFontString(nil, "OVERLAY")
Title:SetFont("Fonts\\2002.ttf", 14, "OUTLINE")
Title:SetTextColor(0.85, 0.85, 0.85, 1)
Title:SetPoint("TOP", 0, -12)
Title:SetText("DelveTracker Events")

--------------------------------------------------
-- CLOSE BUTTON
--------------------------------------------------
local CloseButton = CreateFrame("Button", nil, EventsUI, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", -5, -5)

--------------------------------------------------
-- SCROLLFRAME
--------------------------------------------------
local ScrollFrame = CreateFrame(
    "ScrollFrame",
    nil,
    EventsUI,
    "UIPanelScrollFrameTemplate"
)

ScrollFrame:SetPoint("TOPLEFT", 15, -45)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)

local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetSize(1, 1)

ScrollFrame:SetScrollChild(Content)

--------------------------------------------------
-- DATA / ROWS
--------------------------------------------------
local Rows = {}

local function FormatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    return string.format("%02d:%02d:%02d", h, m, s)
end

for i = 1, 10 do
    local row = CreateFrame("Frame", nil, Content)
    row:SetSize(460, 24)

    if i == 1 then
        row:SetPoint("TOPLEFT", 0, 0)
    else
        row:SetPoint("TOPLEFT", Rows[i - 1], "BOTTOMLEFT", 0, -4)
    end

    row.Text = row:CreateFontString(nil, "OVERLAY")
    row.Text:SetFont("Fonts\\2002.ttf", 12, "")
    row.Text:SetTextColor(0.85, 0.85, 0.85, 1)
    row.Text:SetAllPoints()
    row.Text:SetJustifyH("LEFT")

    Rows[i] = row
end

--------------------------------------------------
-- REFRESH EVENTS
--------------------------------------------------
local function RefreshEvents()
    if not addonTable or not addonTable.DT_events then return end

    local events = addonTable.DT_events:GetVisibleEvents()
    if not events then return end

    local index = 1

    for _, eventData in pairs(events) do
        local row = Rows[index]
        if not row then break end

        local color = eventData.isActive and "|cff00ff00" or "|cffffcc00"

        row.Text:SetText(string.format(
            "%s%s|r |cff888888[%s]|r |cff66ccff%s|r %s",
            color,
            eventData.name,
            eventData.expansion,
            eventData.location,
            FormatTime(eventData.timeRemaining)
        ))

        row:Show()
        index = index + 1
    end

    for i = index, #Rows do
        Rows[i]:Hide()
    end
end

--------------------------------------------------
-- SLASH COMMAND (TOGGLE OPEN / CLOSE)
--------------------------------------------------
SLASH_DTEVENTS1 = "/dtevents"

SlashCmdList.DTEVENTS = function()
    if not EventsUI then return end

    if EventsUI:IsShown() then
        EventsUI:Hide()
    else
        EventsUI:Show()
        RefreshEvents()
    end
end

--------------------------------------------------
-- AUTO UPDATE (SAFE TICKER)
--------------------------------------------------
local EventFrame = CreateFrame("Frame")

local ticker

EventFrame:RegisterEvent("PLAYER_LOGIN")

EventFrame:SetScript("OnEvent", function()
    RefreshEvents()

    if ticker then
        ticker:Cancel()
    end

    ticker = C_Timer.NewTicker(1, function()
        if EventsUI:IsShown() then
            RefreshEvents()
        end
    end)
end)