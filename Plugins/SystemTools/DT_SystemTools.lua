-- =====================================================
-- DelveTracker Plugin: System Tools v2.3 (Full Suite)
-- =====================================================

if DelveTracker then

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

    DelveTracker:RegisterPlugin("SystemTools", function() end)

    local opt = _G["DelveTrackerOptions"]
    if not opt then
        -- DelveTrackerOptions nog niet beschikbaar op load-time; wacht op PLAYER_LOGIN
        local _stWait = CreateFrame("Frame")
        _stWait:RegisterEvent("PLAYER_LOGIN")
        _stWait:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            opt = _G["DelveTrackerOptions"]
        end)
        if not opt then return end
    end

    -- 1. The Rail Container
    local rail = CreateFrame("ScrollFrame", "DT_SystemRail", opt, "UIPanelScrollFrameTemplate")
    rail:SetSize(350, 45)
    rail:SetPoint("TOPLEFT", 130, -380)
    _G[rail:GetName().."ScrollBar"]:Hide()

    rail.bg = rail:CreateTexture(nil, "BACKGROUND")
    rail.bg:SetAllPoints()
    rail.bg:SetColorTexture(0, 0, 0, 0.5)

    -- Tooltip Configuration
    rail:EnableMouse(true)
    rail:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("System & Combat Tools", 1, 1, 1)
        GameTooltip:AddLine("Scroll with mouse wheel for more options.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    rail:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local railContent = CreateFrame("Frame", nil, rail)
    railContent:SetSize(1300, 45) 
    rail:SetScrollChild(railContent)

    -- Button Constructor
    local function CreateRailBtn(text, x, color, func)
        local b = CreateFrame("Button", nil, railContent, "BackdropTemplate")
        b:SetSize(100, 26)
        b:SetPoint("LEFT", x, 0)
        b:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        b:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        local r, g = (color == "red" and 0.6 or 0), (color == "green" and 0.6 or 0)
        b:SetBackdropBorderColor(r, g, 0, 1)
        b.t = b:CreateFontString(nil, "OVERLAY")
        b.t:SetFont("Fonts\\2002.ttf", 10, "")
        b.t:SetTextColor(0.85, 0.85, 0.85, 1)
        b.t:SetPoint("CENTER")
        b.t:SetText(text)
        b:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
        b:SetScript("OnLeave", function(self) self:SetBackdropColor(0.1, 0.1, 0.1, 0.9) end)
        b:SetScript("OnClick", func)
        return b
    end

    -- --- GROUP 1: SYSTEM ---
    CreateRailBtn("Reload UI", 5, "red", function() ReloadUI() end)
    CreateRailBtn("Wipe DB", 115, "red", function() StaticPopup_Show("DT_CONF_WIPE") end)
    CreateRailBtn("Del Char", 225, "red", function() 
        local key = (UnitName("player") or "Unknown").."-"..(GetNormalizedRealmName() or "Unknown")
        if DelveTrackerDB and DelveTrackerDB.characters then
            DelveTrackerDB.characters[key] = nil
            print("|cff00ff00DT:|r Character removed. UI Reload recommended.")
        end
    end)
    CreateRailBtn("Reset Murloc", 335, "green", function()
        if _G["DT_MurlocBtn"] then
            _G["DT_MurlocBtn"]:ClearAllPoints()
            _G["DT_MurlocBtn"]:SetPoint("CENTER")
            print("|cff00ff00DT:|r Murloc position reset.")
        end
    end)

    -- --- GROUP 2: COMBAT ---
    CreateRailBtn("Edit Position", 445, "green", function()
        if DT_CombatAlertFrame then
            if not DT_CombatAlertFrame:IsMouseEnabled() then
                DT_CombatAlertFrame:EnableMouse(true)
                DT_CombatAlertFrame:RegisterForDrag("LeftButton")
                DT_CombatAlertFrame:SetScript("OnDragStart", DT_CombatAlertFrame.StartMoving)
                DT_CombatAlertFrame:SetScript("OnDragStop", function(self)
                    self:StopMovingOrSizing()
                    local point, _, relPoint, x, y = self:GetPoint()
                    DelveTrackerDB.CA_Anchor = {point, relPoint, x, y}
                end)
                DT_CombatAlertFrame.bg:SetColorTexture(0, 1, 0, 0.3)
                DT_CombatAlertFrame:Show()
                print("|cff00ff00DT:|r Drag mode ON.")
            else
                DT_CombatAlertFrame:EnableMouse(false)
                DT_CombatAlertFrame.bg:SetColorTexture(0, 0, 0, 0)
                DT_CombatAlertFrame:Hide()
                print("|cff00ff00DT:|r Position locked.")
            end
        end
    end)

    CreateRailBtn("Edit Texts", 555, "green", function() StaticPopup_Show("DT_EDIT_CA_START") end)
    CreateRailBtn("Test Alert", 665, "green", function()
        if DT_CombatAlertFrame and DT_CombatAlertFrame.PlayAnim then DT_CombatAlertFrame.PlayAnim(true) end
    end)

    -- Mouse wheel scrolling
    rail:EnableMouseWheel(true)
    rail:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetHorizontalScroll()
        local new = math.max(0, math.min(cur - (delta * 30), 500))
        self:SetHorizontalScroll(new)
    end)

    -- --- POPUP DIALOGS ---
    StaticPopupDialogs["DT_EDIT_CA_START"] = {
        text = "Step 1: Text when STARTING combat:",
        button1 = "Next", button2 = "Cancel",
        hasEditBox = 1,
        OnAccept = function(self)
            DelveTrackerDB.CA_StartText = self.EditBox:GetText()
            StaticPopup_Show("DT_EDIT_CA_STOP")
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }

    StaticPopupDialogs["DT_EDIT_CA_STOP"] = {
        text = "Step 2: Text when ENDING combat:",
        button1 = "Save", button2 = "Cancel",
        hasEditBox = 1,
        OnAccept = function(self)
            DelveTrackerDB.CA_StopText = self.EditBox:GetText()
            print("|cff00ff00DT:|r All texts saved.")
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }

    StaticPopupDialogs["DT_CONF_WIPE"] = { 
        text = "Are you sure you want to wipe the entire database?", 
        button1 = "Yes", button2 = "No", 
        OnAccept = function() DelveTrackerDB = {characters = {}}; ReloadUI() end,
        timeout = 0, whileDead = true 
    }
end -- This closes the main 'if DelveTracker then' block