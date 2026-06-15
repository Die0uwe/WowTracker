-- ===================================================================
-- WowTracker — DT_Abundance.lua
-- Copyright (C) 2026 DieOuwe · GPL-3.0
-- https://github.com/Die0uwe/WowTracker · discord.gg/y8Pu5qsEbQ
-- ===================================================================
-- Abundance tegel plugin voor Bounty tab (Tab3 / Nemesis subtab)
-- Data engine zit in DT_events.lua (DT_GetAbundanceData public API)
-- Container wordt aangeleverd door DT_QuickSet via DT_BuildAbundanceFrame()
-- ===================================================================

local addonName, addonTable = ...

-- ===================================================================
-- CONSTANTEN
-- ===================================================================
local FONT      = "Fonts\\2002.ttf"
local SA_GREY   = "|cff887799"
local SA_GREEN  = "|cff44cc66"
local SA_GOLD   = "|cffccaa00"
local SA_ORANGE = "|cffff8800"

-- ===================================================================
-- ABUNDANCE FRAME BUILDER
-- Wordt aangeroepen door DT_QuickSet:
--   DT_BuildAbundanceFrame(parentScroll, scrollWidth, yOffset)
-- Geeft het frame terug zodat QuickSet de hoogte kan berekenen
-- ===================================================================
function DT_BuildAbundanceFrame(parentScroll, scrollWidth, yOffset)
    if not parentScroll then return nil end

    -- Hergebruik bestaand frame (bij refresh)
    if parentScroll._abundanceFrame then
        parentScroll._abundanceFrame:SetPoint("TOPLEFT", 0, -yOffset)
        DT_RefreshAbundanceFrame(parentScroll._abundanceFrame)
        parentScroll._abundanceFrame:Show()
        return parentScroll._abundanceFrame
    end

    -- ── Frame aanmaken ─────────────────────────────────────────────
    local abf = CreateFrame("Frame", nil, parentScroll, "BackdropTemplate")
    abf:SetSize(scrollWidth, 68)
    abf:SetPoint("TOPLEFT", 0, -yOffset)
    abf:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    abf:SetBackdropColor(0.04, 0.08, 0.04, 0.95)
    abf:SetBackdropBorderColor(0.20, 0.65, 0.20, 0.9)

    -- Groene stripe links
    local stripe = abf:CreateTexture(nil, "ARTWORK")
    stripe:SetSize(4, 64)
    stripe:SetPoint("LEFT", 1, 0)
    stripe:SetColorTexture(0.20, 0.80, 0.20, 1)
    abf.stripe = stripe

    -- Checkbox indicator links van titel
    local checkbox = abf:CreateFontString(nil, "OVERLAY")
    checkbox:SetFont(FONT, 10, "OUTLINE")
    checkbox:SetPoint("TOPLEFT", 10, -6)
    checkbox:SetText(SA_GREY .. "[+]|r")
    abf.checkbox = checkbox

    -- Titel
    local title = abf:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 11, "OUTLINE")
    title:SetPoint("TOPLEFT", 28, -6)
    title:SetText(SA_GREY .. "Abundance|r")
    abf.title = title

    -- Timer (rechts)
    local timer = abf:CreateFontString(nil, "OVERLAY")
    timer:SetFont(FONT, 10, "OUTLINE")
    timer:SetPoint("TOPRIGHT", -8, -6)
    timer:SetText("")
    abf.timer = timer

    -- Info regel 1
    local info = abf:CreateFontString(nil, "OVERLAY")
    info:SetFont(FONT, 10, "")
    info:SetPoint("TOPLEFT", 10, -22)
    info:SetWidth(scrollWidth - 20)
    info:SetText(SA_GREY .. "Laden...|r")
    abf.info = info

    -- Info regel 2 (shard count)
    local info2 = abf:CreateFontString(nil, "OVERLAY")
    info2:SetFont(FONT, 10, "")
    info2:SetPoint("TOPLEFT", 10, -38)
    info2:SetWidth(scrollWidth - 20)
    info2:SetText("")
    abf.info2 = info2

    -- Sla op voor hergebruik
    parentScroll._abundanceFrame = abf

    -- Vul met data
    DT_RefreshAbundanceFrame(abf)

    -- Live refresh via C_Timer elke 60 seconden
    abf._ticker = C_Timer.NewTicker(60, function()
        if abf:IsShown() then
            DT_RefreshAbundanceFrame(abf)
        end
    end)

    return abf
end

-- ===================================================================
-- ABUNDANCE DATA REFRESH
-- Leest DT_GetAbundanceData() en vult het frame
-- ===================================================================
function DT_RefreshAbundanceFrame(abf)
    if not abf then return end

    local abData = DT_GetAbundanceData and DT_GetAbundanceData()

    if abData and abData.active then
        -- ACTIEF
        abf:SetBackdropBorderColor(0.30, 0.90, 0.30, 1)
        abf.stripe:SetColorTexture(0.20, 0.90, 0.20, 1)
        abf.checkbox:SetText(SA_GREEN .. "[★]|r")
        abf.title:SetText(SA_GREEN .. "Abundance Actief: |r|cffffffff" ..
                         (abData.zone or "?") .. "|r")

        -- Timer
        local timeStr = ""
        if abData.secondsLeft and abData.secondsLeft > 0 then
            local h = math.floor(abData.secondsLeft / 3600)
            local m = math.floor((abData.secondsLeft % 3600) / 60)
            if h > 0 then
                timeStr = string.format(SA_ORANGE .. "%dh %dm|r", h, m)
            else
                timeStr = string.format(SA_ORANGE .. "%dm|r", m)
            end
        end
        abf.timer:SetText(timeStr)

        -- Shard of Dundun info
        local shards    = abData.shards or 0
        local shardCol  = shards > 0 and SA_GREEN or "|cffff5555"
        abf.info:SetText(
            SA_GREY .. "Shard of Dundun: |r" .. shardCol .. shards .. "|r  " ..
            SA_GREY .. "Chip vendor: |r|cff00ccffChel the Chip|r"
        )

        -- Map info
        abf.info2:SetText(
            SA_GREY .. "Map ID: |r|cff00dfff" ..
            tostring(abData.mapID or "?") .. "|r  " ..
            SA_GREY .. "POI: |r|cff00dfff" ..
            tostring(abData.poiID or "?") .. "|r"
        )
    else
        -- INACTIEF
        abf:SetBackdropBorderColor(0.20, 0.40, 0.20, 0.6)
        abf.stripe:SetColorTexture(0.20, 0.40, 0.20, 0.7)
        abf.checkbox:SetText(SA_GREY .. "[ ]|r")
        abf.title:SetText(SA_GREY .. "Abundance|r")
        abf.timer:SetText("")
        abf.info:SetText(SA_GREY .. "Geen actieve Abundant Harvest in Quel'Thalas|r")
        abf.info2:SetText("")
    end
end

-- ===================================================================
-- REGISTREER ALS PLUGIN
-- ===================================================================
if DelveTracker and DelveTracker.RegisterPlugin then
    DelveTracker:RegisterPlugin("Abundance", function(mode, container)
        -- Plugin init callback (geen eigen tab — werkt via QuickSet container)
    end)
end

-- ===================================================================
--[[
  File    : DT_Abundance.lua
  Version : 1.0.0   Created : 2026-06-15   Updated : 2026-06-15
  Status  : New — Abundance tegel uitgesplitst uit DT_QuickSet.lua
  Notes   : Data via DT_GetAbundanceData() uit DT_events.lua
            UI container aangeleverd door DT_QuickSet via DT_BuildAbundanceFrame()
            Live refresh elke 60 sec via C_Timer.NewTicker
            Hergebruikt bestaand frame bij refresh (geen dubbele frames)
  Author  : DieOuwe · www.dieouwe.nl · discord.gg/y8Pu5qsEbQ
]]
-- ===================================================================
