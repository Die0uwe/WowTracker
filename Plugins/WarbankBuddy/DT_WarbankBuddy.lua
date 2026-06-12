-- =====================================================
-- WarBankBuddy V0.5 - Universal (ElvUI + Blizzard)
-- Compatible: WoW 12.0.5 / The War Within (Build 67314)
-- =====================================================
-- FIXES applied vs V0.2:
--  [BUG-1] pairs(B.BankFrame.buttons) -> nil crash  (line ~139)
--           Added explicit nil guard before iteration
--  [BUG-2] GameTooltip:HookScript("OnTooltipSetItem") missing script
--           OnTooltipSetItem removed in 10.0.2 -> replaced with
--           TooltipDataProcessor.AddTooltipPostCall (TWW-native)
--  [BUG-3] InterfaceOptionsCheckButtonTemplate deprecated (10.0+)
--           Replaced with manual checkbox widget (textures)
--  [BUG-4] Bank bag loop "for bag = -1, 11" included player bags 0-4
--           Explicit table now only contains valid bank bag IDs
--  [BUG-5] _G["ContainerFrame"..-1.."Item"..slot] = invalid global name
--           Main bank (-1) uses BankFrameItem<N> naming; handled separately
--  [BUG-6] No real Warbank (account bank tab) support
--           Added C_Container scan for Enum.BagIndex.AccountBankTab_1..5
--  [BUG-7] E:GetModule("Bags") unguarded – crashes when module absent
--           Wrapped in pcall; all ElvUI paths individually nil-guarded
--  [BUG-8] GetItemInfo -> may be nil in TWW; added C_Item.GetItemInfo fallback
--  [BUG-9] PLAYER_ACCOUNT_BANK_SLOT_CHANGED does NOT exist in WoW 12.0.5
--           Removed. Warbank updates flow through BAG_UPDATE_DELAYED.
--           All RegisterEvent calls wrapped in pcall for future-proofing.
--  [BUG-10] PLAYERBANKBAGSLOTS_CHANGED added for bank-bag purchase detection
-- =====================================================

local addonName = ...
local WBB = CreateFrame("Frame", "WarBankBuddyFrame", UIParent, "BackdropTemplate")

-- TWW expansion ID used to colour-flag current-expansion items
local TWW_EXPANSION_ID = 12

-- ─────────────────────────────────────────────────────────────────────────────
-- Bank bag ID tables  (BUG-4 fix: no longer iterates 0-11 blindly)
-- ─────────────────────────────────────────────────────────────────────────────
local BANK_MAIN_BAGID   = -1                  -- 28 fixed main-bank slots
local BANK_BAG_IDS      = {5,6,7,8,9,10,11}  -- purchased bank bags
-- Warbank (account bank) tabs: AccountBankTab_1 … _5 = BagIndex 13-17
local WARBANK_BAG_IDS   = {}
for i = 1, 5 do
    local key = "AccountBankTab_" .. i
    -- Use the enum if available, fall back to the known numeric value
    local bagID = (Enum and Enum.BagIndex and Enum.BagIndex[key]) or (12 + i)
    WARBANK_BAG_IDS[i] = bagID
end

-- ─────────────────────────────────────────────────────────────────────────────
-- SavedVariables defaults
-- ─────────────────────────────────────────────────────────────────────────────
local defaults = {
    glow             = true,
    overlay          = true,
    highlightWarbank = true,
}

local function InitDB()
    WarBankBuddyDB = WarBankBuddyDB or {}
    for k, v in pairs(defaults) do
        if WarBankBuddyDB[k] == nil then
            WarBankBuddyDB[k] = v
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Safe wrapper for GetItemInfo (BUG-8 fix)
-- TWW moved many globals into C_* namespaces.
-- ─────────────────────────────────────────────────────────────────────────────
local function SafeGetItemInfo(itemID)
    -- C_Item.GetItemInfo is the TWW-preferred call; fall back to global
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemID)
    end
    return GetItemInfo(itemID)   -- still present in 12.0.5 via compatibility shim
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Main frame: UI setup
-- ─────────────────────────────────────────────────────────────────────────────
WBB:SetSize(400, 460)
WBB:SetPoint("CENTER")
WBB:SetFrameStrata("HIGH")
WBB:SetMovable(true)
WBB:EnableMouse(true)
WBB:RegisterForDrag("LeftButton")
WBB:SetScript("OnDragStart", WBB.StartMoving)
WBB:SetScript("OnDragStop",  WBB.StopMovingOrSizing)
WBB:Hide()

WBB:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
WBB:SetBackdropColor(0.02, 0.01, 0.05, 0.92)
WBB:SetBackdropBorderColor(0.6, 0.2, 1, 1)

-- Close button
WBB.closeBtn = CreateFrame("Button", nil, WBB, "UIPanelCloseButton")
WBB.closeBtn:SetPoint("TOPRIGHT", -5, -5)

-- Title
WBB.Title = WBB:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
WBB.Title:SetPoint("TOPLEFT", 20, -20)
WBB.Title:SetText("|cff8800ffWarBank|r|cff00aaffBuddy|r |cff888888v0.5|r")

-- Version/status label
WBB.Status = WBB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
WBB.Status:SetPoint("TOPLEFT", 20, -44)
WBB.Status:SetText("|cff888888WoW 12.0.5 build 67314|r")

-- ─────────────────────────────────────────────────────────────────────────────
-- Checkbox widget factory  (BUG-3 fix: no InterfaceOptionsCheckButtonTemplate)
-- InterfaceOptionsCheckButtonTemplate is deprecated since 10.0.0.
-- Building the checkbox manually with raw textures is version-proof.
-- ─────────────────────────────────────────────────────────────────────────────
local function CreateSetting(name, label, yOff)
    local f = CreateFrame("Frame", nil, WBB)
    f:SetSize(360, 30)
    f:SetPoint("TOPLEFT", 20, yOff)

    -- Manual checkbox (replaces InterfaceOptionsCheckButtonTemplate)
    local cb = CreateFrame("CheckButton", nil, f)
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", 0, 0)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")

    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    lbl:SetText(label)

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("RIGHT", -10, 0)

    local function UpdateIcon()
        icon:SetTexture(cb:GetChecked()
            and "Interface\\RAIDFRAME\\ReadyCheck-Ready"
             or "Interface\\RAIDFRAME\\ReadyCheck-NotReady")
    end

    cb:SetScript("OnClick", function(self)
        WarBankBuddyDB[name] = self:GetChecked()
        UpdateIcon()
    end)

    -- Returns cb, icon, and an init helper
    return cb, icon, UpdateIcon
end

WBB.cbGlow,     WBB.iconGlow,     WBB.initGlow     = CreateSetting("glow",             "Item Glow",              -80)
WBB.cbOverlay,  WBB.iconOverlay,  WBB.initOverlay  = CreateSetting("overlay",          "Item Overlay",          -120)
WBB.cbWarbank,  WBB.iconWarbank,  WBB.initWarbank  = CreateSetting("highlightWarbank", "Highlight Warbank Items",-160)

-- Legend
local legend = WBB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
legend:SetPoint("TOPLEFT", 20, -210)
legend:SetText("|cff00ff00Green glow|r = older expansion    |cff8800ffPurple glow|r = TWW item")

-- ─────────────────────────────────────────────────────────────────────────────
-- Item expansion – async (handles uncached items properly)
-- ─────────────────────────────────────────────────────────────────────────────
local function GetItemExpansion(itemID, callback)
    if not itemID or itemID == 0 then return end
    local item = Item:CreateFromItemID(itemID)
    if item:IsItemDataCached() then
        local expacID = select(15, SafeGetItemInfo(itemID))
        callback(expacID)
    else
        item:ContinueOnItemLoad(function()
            local expacID = select(15, SafeGetItemInfo(itemID))
            callback(expacID)
        end)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Visual application
-- ─────────────────────────────────────────────────────────────────────────────
local function ApplyVisuals(button, itemID, expacID)
    if not button then return end

    -- Always reset first
    if button.wbbGlow    then button.wbbGlow:Hide()    end
    if button.wbbOverlay then button.wbbOverlay:Hide() end

    if not itemID or not WarBankBuddyDB then return end

    local r, g, b = 0.1, 1.0, 0.1           -- default green (old expansion)
    if expacID == TWW_EXPANSION_ID then
        r, g, b = 0.8, 0.0, 1.0             -- purple for TWW items
    end

    if WarBankBuddyDB.glow then
        if not button.wbbGlow then
            button.wbbGlow = button:CreateTexture(nil, "OVERLAY", nil, 7)
            button.wbbGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            button.wbbGlow:SetBlendMode("ADD")
            button.wbbGlow:SetAllPoints()
        end
        button.wbbGlow:SetVertexColor(r, g, b, 1)
        button.wbbGlow:Show()
    end

    if WarBankBuddyDB.overlay then
        if not button.wbbOverlay then
            button.wbbOverlay = button:CreateTexture(nil, "OVERLAY", nil, 6)
            button.wbbOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
            button.wbbOverlay:SetBlendMode("ADD")
            button.wbbOverlay:SetAllPoints()
        end
        button.wbbOverlay:SetVertexColor(r, g, b, 0.3)
        button.wbbOverlay:Show()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Button lookup helper  (BUG-5 fix)
-- Blizzard uses different global naming conventions per bag type:
--   Main bank (-1)  -> BankFrameItem<slot>
--   Bank bags (5-11)-> ContainerFrame<bagID>Item<slot>
--   Warbank tabs    -> AccountBankPanel<tab>Item<slot>  (TWW)
-- ─────────────────────────────────────────────────────────────────────────────
local function GetBankButton(bagID, slot)
    if bagID == BANK_MAIN_BAGID then
        return _G["BankFrameItem" .. slot]
    elseif bagID >= 5 and bagID <= 11 then
        return _G["ContainerFrame" .. bagID .. "Item" .. slot]
    elseif bagID >= 13 and bagID <= 17 then
        local tabIdx = bagID - 12   -- 1 … 5
        -- TWW account bank panel naming (try both known patterns)
        return _G["AccountBankPanel" .. tabIdx .. "Item" .. slot]
            or _G["AccountBankPanelContainer" .. tabIdx .. "Item" .. slot]
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Scan: ElvUI bank  (BUG-1 + BUG-7 fix)
-- ─────────────────────────────────────────────────────────────────────────────
local function ScanElvUIBank()
    local ElvUI = _G["ElvUI"]
    if not ElvUI then return end

    local E = ElvUI[1]
    if not E then return end

    -- BUG-7: GetModule can error if module not loaded; use pcall
    local ok, B = pcall(function() return E:GetModule("Bags") end)
    if not ok or not B then return end

    -- Helper: scan any ElvUI bank-style frame
    local function ScanElvFrame(frame)
        if not frame or not frame:IsShown() then return end
        local buttons = frame.buttons          -- BUG-1: was nil -> crash
        if not buttons then return end         -- ← nil guard added here

        for _, btn in pairs(buttons) do
            if btn then
                local parent = btn:GetParent()
                local bagID  = parent and parent:GetID()
                local slotID = btn:GetID()

                if bagID and slotID then
                    local itemID = C_Container.GetContainerItemID(bagID, slotID)
                    if itemID and itemID > 0 then
                        GetItemExpansion(itemID, function(expacID)
                            ApplyVisuals(btn, itemID, expacID)
                        end)
                    else
                        ApplyVisuals(btn, nil)
                    end
                end
            end
        end
    end

    ScanElvFrame(B.BankFrame)
    -- Warbank frame – ElvUI may name this differently; try common names
    ScanElvFrame(B.WarbankFrame or B.AccountBankFrame or B.WarBankFrame)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Scan: Blizzard main bank  (BUG-4 + BUG-5 fix)
-- ─────────────────────────────────────────────────────────────────────────────
local function ScanBlizzardMainBank()
    if not BankFrame or not BankFrame:IsShown() then return end

    -- Main 28 slots (bag -1)
    local numMain = C_Container.GetContainerNumSlots(BANK_MAIN_BAGID) or 0
    for slot = 1, numMain do
        local itemID = C_Container.GetContainerItemID(BANK_MAIN_BAGID, slot)
        local btn    = _G["BankFrameItem" .. slot]   -- BUG-5 fix: was ContainerFrame-1Item<slot>
        if btn then
            if itemID and itemID > 0 then
                GetItemExpansion(itemID, function(expacID)
                    ApplyVisuals(btn, itemID, expacID)
                end)
            else
                ApplyVisuals(btn, nil)
            end
        end
    end

    -- Purchased bank bags (5–11)
    for _, bagID in ipairs(BANK_BAG_IDS) do
        local numSlots = C_Container.GetContainerNumSlots(bagID) or 0
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bagID, slot)
            local btn    = GetBankButton(bagID, slot)
            if btn then
                if itemID and itemID > 0 then
                    GetItemExpansion(itemID, function(expacID)
                        ApplyVisuals(btn, itemID, expacID)
                    end)
                else
                    ApplyVisuals(btn, nil)
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Scan: Warbank / account bank tabs  (BUG-6: new feature for TWW)
-- ─────────────────────────────────────────────────────────────────────────────
local function ScanWarbankTabs()
    if not WarBankBuddyDB or not WarBankBuddyDB.highlightWarbank then return end

    for _, bagID in ipairs(WARBANK_BAG_IDS) do
        local numSlots = C_Container.GetContainerNumSlots(bagID) or 0
        if numSlots > 0 then
            for slot = 1, numSlots do
                local itemID = C_Container.GetContainerItemID(bagID, slot)
                local btn    = GetBankButton(bagID, slot)
                if btn then
                    if itemID and itemID > 0 then
                        GetItemExpansion(itemID, function(expacID)
                            ApplyVisuals(btn, itemID, expacID)
                        end)
                    else
                        ApplyVisuals(btn, nil)
                    end
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Master scan (deferred 0.1 s to let the frame settle first)
-- ─────────────────────────────────────────────────────────────────────────────
local function ScanBank()
    ScanElvUIBank()
    ScanBlizzardMainBank()
    ScanWarbankTabs()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Tooltip hook  (BUG-2 fix)
-- OnTooltipSetItem was REMOVED in patch 10.0.2.
-- TWW uses TooltipDataProcessor.AddTooltipPostCall.
-- ─────────────────────────────────────────────────────────────────────────────
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    -- ✅ TWW / modern Retail path (10.0.2 +)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip ~= GameTooltip then return end
        local itemID = data and data.id
        if not itemID or itemID == 0 then return end
        local expacID = select(15, SafeGetItemInfo(itemID))
        if expacID == TWW_EXPANSION_ID then
            tooltip:AddLine("|cff8800ffWarBank|r |cff00aaffTWW item|r")
            tooltip:Show()
        end
    end)
else
    -- ⚠️  Fallback for pre-10.0.2 (should not normally be reached on 12.0.5)
    pcall(function()
        GameTooltip:HookScript("OnTooltipSetItem", function(self)
            local _, itemLink = self:GetItem()
            if not itemLink then return end
            local itemID = tonumber(itemLink:match("item:(%d+)"))
            if not itemID then return end
            local expacID = select(15, SafeGetItemInfo(itemID))
            if expacID == TWW_EXPANSION_ID then
                self:AddLine("|cff8800ffWarBank|r |cff00aaffTWW item|r")
                self:Show()
            end
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Event registration  (BUG-9/10 fix)
--
-- ❌ REMOVED: "PLAYER_ACCOUNT_BANK_SLOT_CHANGED" - this event does NOT exist
--    in any version of WoW retail including 12.0.5.  Registering it causes:
--    "Attempt to register unknown event" Lua error on every load.
--
-- ✅ Warband bank slot changes propagate through BAG_UPDATE_DELAYED, which
--    already fires for ALL container updates (player bags, bank, warbank tabs).
--
-- ✅ All RegisterEvent calls wrapped in pcall so a future API rename cannot
--    crash the addon entirely - it will silently skip the unknown event.
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")

local function SafeRegisterEvent(frame, event)
    local ok, err = pcall(function() frame:RegisterEvent(event) end)
    if not ok then
        -- Silently skip; /wbb debug will report missing events if needed
        -- (avoids "Attempt to register unknown event" crash)
        WBB._skippedEvents = WBB._skippedEvents or {}
        WBB._skippedEvents[event] = err
    end
end

-- ✅ Events confirmed present in WoW 12.0.5 build 67314
SafeRegisterEvent(eventFrame, "ADDON_LOADED")
SafeRegisterEvent(eventFrame, "BANKFRAME_OPENED")          -- character bank opened
SafeRegisterEvent(eventFrame, "PLAYERBANKSLOTS_CHANGED")   -- bank slot item change
SafeRegisterEvent(eventFrame, "PLAYERBANKBAGSLOTS_CHANGED")-- bank bag purchased/changed (BUG-10)
SafeRegisterEvent(eventFrame, "BAG_UPDATE_DELAYED")        -- covers ALL bags incl. warbank tabs

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()

        -- Restore checkbox states
        WBB.cbGlow:SetChecked(WarBankBuddyDB.glow)
        WBB.cbOverlay:SetChecked(WarBankBuddyDB.overlay)
        WBB.cbWarbank:SetChecked(WarBankBuddyDB.highlightWarbank)

        -- Restore icon states
        WBB.initGlow()
        WBB.initOverlay()
        WBB.initWarbank()

    else
        -- Delay slightly so the bank frame has time to fully render
        C_Timer.After(0.15, ScanBank)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Slash commands
-- ─────────────────────────────────────────────────────────────────────────────
SLASH_WARBANKBUDDY1 = "/wbb"
SlashCmdList["WARBANKBUDDY"] = function(msg)
    msg = msg and strtrim(msg):lower() or ""

    if msg == "scan" then
        ScanBank()
        print("|cff8800ffWarBankBuddy|r: Manual scan triggered.")
    elseif msg == "reset" then
        WarBankBuddyDB = nil
        print("|cff8800ffWarBankBuddy|r: Settings reset. Reload UI to apply.")
    elseif msg == "debug" then
        print("|cff8800ffWarBankBuddy|r: DB =", WarBankBuddyDB and "loaded" or "nil")
        print("  glow:", tostring(WarBankBuddyDB and WarBankBuddyDB.glow))
        print("  overlay:", tostring(WarBankBuddyDB and WarBankBuddyDB.overlay))
        print("  warbank:", tostring(WarBankBuddyDB and WarBankBuddyDB.highlightWarbank))
        print("  ElvUI:", _G["ElvUI"] and "present" or "absent")
        print("  TooltipDP:", TooltipDataProcessor and "present" or "absent (fallback active)")
        if WBB._skippedEvents then
            for ev, err in pairs(WBB._skippedEvents) do
                print("  |cffff4444SKIPPED event:|r", ev, "->", err)
            end
        else
            print("  All events: |cff00ff00registered OK|r")
        end
    else
        if WBB:IsShown() then WBB:Hide() else WBB:Show() end
    end
end


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
    DelveTracker:RegisterPlugin("WarbankBuddy", function() end)
end)
