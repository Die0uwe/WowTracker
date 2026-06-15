-- ===================================================================
-- WowTracker — DT_MinimapIcon.lua
-- Copyright (C) 2026 DieOuwe · GPL-3.0
-- https://github.com/Die0uwe/WowTracker · discord.gg/y8Pu5qsEbQ
-- ===================================================================
-- Minimap icon via LibDBIcon-1.0
-- Pinnt aan de minimap ring (of ElvUI/andere addon container)
-- Links-klik  = open/sluit WowTracker hoofdvenster
-- Rechts-klik = context menu (admin panel, reload, hide)
-- Icon wisselt automatisch mee bij WTTheme.SetActiveTheme()
-- ===================================================================

local addonName, addonTable = ...

-- ── Wacht tot libs beschikbaar zijn ─────────────────────────────
local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local LDI = LibStub and LibStub("LibDBIcon-1.0", true)

if not LDB or not LDI then
    -- Geen libs → stille fallback, MBtn blijft primaire launcher
    return
end

-- ── Default icon (fallback als WTTheme nog niet geladen is) ──────
local DEFAULT_ICON = "Interface\\AddOns\\WowTracker\\Media\\MijnIcoon_minimap.tga"

local function GetCurrentIcon()
    if WTTheme and WTTheme.GetIcon then
        return WTTheme.GetIcon("theme")
    end
    return DEFAULT_ICON
end

-- ── DataBroker object ─────────────────────────────────────────────
local dataObj = LDB:NewDataObject("WowTracker", {
    type  = "launcher",
    label = "WowTracker",
    icon  = GetCurrentIcon(),

    OnClick = function(_, mouseBtn)
        if mouseBtn == "LeftButton" then
            local frame = DelveTrackerFrame
            if frame then
                if frame:IsShown() then
                    frame:Hide()
                else
                    frame:Show()
                end
            end
        elseif mouseBtn == "RightButton" then
            if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
            MenuUtil.CreateContextMenu(_, function(_, root)
                root:CreateTitle((WTTheme and WTTheme.c.purple or "|cffbf00ff") .. "WowTracker|r")
                root:CreateButton("Open / Sluit",
                    function()
                        local f = DelveTrackerFrame
                        if f then
                            if f:IsShown() then f:Hide() else f:Show() end
                        end
                    end)
                root:CreateDivider()
                root:CreateButton("Reload UI",
                    function() ReloadUI() end)
                root:CreateDivider()
                root:CreateButton("Verberg minimap knop",
                    function()
                        LDI:Hide("WowTracker")
                        if DelveTrackerDB then
                            DelveTrackerDB.minimapIcon = DelveTrackerDB.minimapIcon or {}
                            DelveTrackerDB.minimapIcon.hide = true
                        end
                        print((WTTheme and WTTheme.c.purple or "|cffbf00ff") ..
                            "[WowTracker]|r Minimap knop verborgen. /wt minimap om te herstellen.")
                    end)
            end)
        end
    end,

    OnTooltipShow = function(tip)
        tip:AddLine((WTTheme and WTTheme.c.purple or "|cffbf00ff") .. "WowTracker|r " ..
                    (WTTheme and WTTheme.c.grey   or "|cff887799") .. "Slayer Alliance Edition|r")
        tip:AddLine((WTTheme and WTTheme.c.blue   or "|cff00dfff") ..
                    "Links-klik|r: open / sluit", 1, 1, 1)
        tip:AddLine((WTTheme and WTTheme.c.blue   or "|cff00dfff") ..
                    "Rechts-klik|r: opties", 0.7, 0.7, 0.7)
        tip:AddLine((WTTheme and WTTheme.c.blue   or "|cff00dfff") ..
                    "Slepen|r: herplaatsen op de ring", 0.7, 0.7, 0.7)
        -- Warband samenvatting
        if DelveTrackerDB and DelveTrackerDB.characters then
            local count = 0
            for _ in pairs(DelveTrackerDB.characters) do count = count + 1 end
            if count > 0 then
                tip:AddLine(" ")
                tip:AddLine(string.format(
                    (WTTheme and WTTheme.c.gold   or "|cffccaa00") .. "%d karakter(s) in warband|r", count),
                    1, 1, 1)
            end
        end
    end,
})

-- ── Registreer op de minimap ──────────────────────────────────────
local function InitMinimap()
    -- DB init
    DelveTrackerDB = DelveTrackerDB or {}
    DelveTrackerDB.minimapIcon = DelveTrackerDB.minimapIcon or {
        hide         = false,
        minimapPos   = 220,
    }
    LDI:Register("WowTracker", dataObj, DelveTrackerDB.minimapIcon)

    -- MBtn verbergen zodra LibDBIcon knop actief is
    -- (MBtn blijft bestaan maar is niet nodig naast minimap knop)
    -- Commentaar: MBtn blijft als backup, niets forceren
end

-- ── Live icon update bij theme wissel ────────────────────────────
local function OnThemeChanged()
    local newIcon = GetCurrentIcon()
    if dataObj.icon ~= newIcon then
        dataObj.icon = newIcon
        -- LibDBIcon vernieuwen
        if LDI.GetMinimapButton then
            local btn = LDI:GetMinimapButton("WowTracker")
            if btn and btn.icon then
                btn.icon:SetTexture(newIcon)
            end
        end
    end
end

-- ── Slash: /wt minimap ───────────────────────────────────────────
local origSlash = SlashCmdList["WTMAIN"]
if origSlash then
    SlashCmdList["WTMAIN"] = function(msg)
        local cmd = (msg or ""):lower():match("^%s*(%a*)")
        if cmd == "minimap" then
            local db = DelveTrackerDB and DelveTrackerDB.minimapIcon or {}
            if db.hide then
                LDI:Show("WowTracker")
                db.hide = false
                print("|cffbf00ff[WowTracker]|r Minimap knop hersteld.")
            else
                LDI:Hide("WowTracker")
                db.hide = true
                print("|cffbf00ff[WowTracker]|r Minimap knop verborgen. /wt minimap om te herstellen.")
            end
        else
            origSlash(msg)
        end
    end
end

-- ── Events ───────────────────────────────────────────────────────
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitMinimap()
        -- Registreer voor live theme reload
        if WTTheme and WTTheme.Register then
            WTTheme.Register(OnThemeChanged, "DT_MinimapIcon")
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ===================================================================
--[[
  File    : DT_MinimapIcon.lua
  Version : 2.1.0   Created : 2026-06-14   Updated : 2026-06-14 23:30
  Status  : Updated — WTTheme.GetIcon() integratie, live icon reload
  Notes   : LibDBIcon integratie. Valt silent terug als libs ontbreken.
            Icon wisselt mee met actief WTTheme via Register() callback.
            /wt minimap toggle. MBtn blijft als backup launcher.
  Author  : DieOuwe · www.dieouwe.nl · discord.gg/y8Pu5qsEbQ
]]
-- ===================================================================
