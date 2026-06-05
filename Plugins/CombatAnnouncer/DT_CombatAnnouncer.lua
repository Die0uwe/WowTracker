-- =====================================================
-- DelveTracker Plugin: Combat Announcer v12.8 (English)
-- =====================================================

if DelveTracker then
    -- 1. DATABASE
    local function CheckDB()
        DelveTrackerDB = DelveTrackerDB or {}
        local defaults = {
            enableCombatAlert = true, 
            enableCombatSound = true,
            CA_Speed = 1, 
            CA_Size = 1,
            CA_StartText = "ENGAGE!", 
            CA_StopText = "COMBAT ENDED"
        }
        for k, v in pairs(defaults) do
            if DelveTrackerDB[k] == nil then DelveTrackerDB[k] = v end
        end
    end

    -- 2. MAIN FRAME & LOGIC
    local CA_Frame = CreateFrame("Frame", "DT_CombatAlertFrame", UIParent, "BackdropTemplate")
    CA_Frame:SetSize(250, 250)
    CA_Frame:SetMovable(true)
    CA_Frame:EnableMouse(false)
    CA_Frame:SetClampedToScreen(true)
    CA_Frame:SetScript("OnDragStart", CA_Frame.StartMoving)
    CA_Frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        DelveTrackerDB.CA_Anchor = {point, relPoint, x, y}
    end)
    CA_Frame:Hide()

    local function LoadPosition()
        if DelveTrackerDB and DelveTrackerDB.CA_Anchor then
            local p = DelveTrackerDB.CA_Anchor
            CA_Frame:ClearAllPoints()
            CA_Frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        else
            CA_Frame:SetPoint("CENTER", 0, 150)
        end
    end

    local function CreateArtContainer(tex, flip)
        local f = CreateFrame("Frame", nil, CA_Frame)
        f:SetSize(180, 180)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\AddOns\\DelveTracker\\Media\\"..tex)
        t:SetAllPoints()
        if flip then t:SetTexCoord(1, 0, 0, 1) end
        f:SetAlpha(0)
        return f
    end

    local swordL = CreateArtContainer("sword", false)
    local swordR = CreateArtContainer("sword", true)
    local shield = CreateArtContainer("shield", false)
    shield:SetFrameLevel(swordL:GetFrameLevel() + 5)

    -- Text on foreground
    local TextFrame = CreateFrame("Frame", nil, CA_Frame)
    TextFrame:SetSize(400, 60)
    TextFrame:SetFrameLevel(shield:GetFrameLevel() + 10) 
    local CA_Text = TextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    CA_Text:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
    CA_Text:SetPoint("CENTER", TextFrame, "CENTER")
    TextFrame:SetAlpha(0)

    -- 3. ANIMATION LOGIC
    CA_Frame.PlayAnim = function(isStart)
        CheckDB()
        if not DelveTrackerDB.enableCombatAlert then return end
        LoadPosition()

        local scale = DelveTrackerDB.CA_Size or 1
        local speed = 1 / (DelveTrackerDB.CA_Speed or 1)

        CA_Frame:SetAlpha(1); CA_Frame:Show()
        UIFrameFadeRemoveFrame(CA_Frame)
        swordL:SetAlpha(0); swordR:SetAlpha(0); shield:SetAlpha(0); TextFrame:SetAlpha(0)

        if isStart then
            swordL:SetPoint("CENTER", 0, 0); swordR:SetPoint("CENTER", 0, 0); shield:SetPoint("CENTER", 0, 0)
            TextFrame:SetPoint("CENTER", CA_Frame, "CENTER", 0, -35 * scale)

            local gL = swordL:CreateAnimationGroup()
            local aL1 = gL:CreateAnimation("Translation"); aL1:SetOffset(-130 * scale, -130 * scale); aL1:SetDuration(0); aL1:SetOrder(1)
            local aL2 = gL:CreateAnimation("Translation"); aL2:SetOffset(130 * scale, 130 * scale); aL2:SetDuration(0.4 * speed); aL2:SetSmoothing("OUT"); aL2:SetOrder(2)
            
            local gR = swordR:CreateAnimationGroup()
            local aR1 = gR:CreateAnimation("Translation"); aR1:SetOffset(130 * scale, -130 * scale); aR1:SetDuration(0); aR1:SetOrder(1)
            local aR2 = gR:CreateAnimation("Translation"); aR2:SetOffset(-130 * scale, 130 * scale); aR2:SetDuration(0.4 * speed); aR2:SetSmoothing("OUT"); aR2:SetOrder(2)

            CA_Text:SetText(DelveTrackerDB.CA_StartText); CA_Text:SetTextColor(1, 0.1, 0.1)
            local gT = TextFrame:CreateAnimationGroup()
            local t1 = gT:CreateAnimation("Translation"); t1:SetOffset(0, -20 * scale); t1:SetDuration(0); t1:SetOrder(1)
            local t2 = gT:CreateAnimation("Translation"); t2:SetOffset(0, 40 * scale); t2:SetDuration(0.4 * speed); t2:SetOrder(2)

            swordL:SetAlpha(1); swordR:SetAlpha(1); TextFrame:SetAlpha(1)
            gL:Play(); gR:Play(); gT:Play()

            C_Timer.After(0.4 * speed, function()
                shield:SetAlpha(1)
                local gS = shield:CreateAnimationGroup()
                local s1 = gS:CreateAnimation("Scale"); s1:SetScale(1.4, 1.4); s1:SetDuration(0.1 * speed); s1:SetOrder(1)
                gS:Play()
                if DelveTrackerDB.enableCombatSound then PlaySound(3175, "Master") end
            end)
            C_Timer.After(2.5 * speed, function() UIFrameFadeOut(CA_Frame, 0.8 * speed, 1, 0) end)
        else
            shield:SetAlpha(1); shield:Show()
            CA_Text:SetText(DelveTrackerDB.CA_StopText); CA_Text:SetTextColor(0.1, 1, 0.1)
            TextFrame:SetPoint("CENTER", CA_Frame, "CENTER", 0, -35 * scale)
            TextFrame:SetAlpha(1)
            if DelveTrackerDB.enableCombatSound then PlaySound(11467, "Master") end
            C_Timer.After(1.5 * speed, function() UIFrameFadeOut(CA_Frame, 0.5 * speed, 1, 0) end)
        end
    end

    -- 4. SETTINGS MENU (SYSTEM STYLE)
    local function CreateSettingsMenu()
        local frame = CreateFrame("Frame", "DT_CombatSettingsFrame", UIParent, "BackdropTemplate")
        frame:SetSize(350, 520); frame:SetPoint("CENTER")
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        frame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15); title:SetText("SLAYER ALLIANCE"); title:SetTextColor(0.6, 0.4, 1)

        local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -2, -2)

        local function CreateSlayerBtn(label, y, func)
            local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
            btn:SetSize(220, 28); btn:SetPoint("TOP", 0, y)
            btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
            btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            btn.t = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.t:SetPoint("CENTER"); btn.t:SetText(label)
            btn:SetScript("OnClick", func)
            return btn
        end

        local alertBtn = CreateSlayerBtn("Combat Alert: ", -60, function(self)
            DelveTrackerDB.enableCombatAlert = not DelveTrackerDB.enableCombatAlert
            self.t:SetText("Combat Alert: "..(DelveTrackerDB.enableCombatAlert and "ON" or "OFF"))
        end)
        alertBtn.t:SetText("Combat Alert: "..(DelveTrackerDB.enableCombatAlert and "ON" or "OFF"))

        local soundBtn = CreateSlayerBtn("Combat Sound: ", -95, function(self)
            DelveTrackerDB.enableCombatSound = not DelveTrackerDB.enableCombatSound
            self.t:SetText("Combat Sound: "..(DelveTrackerDB.enableCombatSound and "ON" or "OFF"))
        end)
        soundBtn.t:SetText("Combat Sound: "..(DelveTrackerDB.enableCombatSound and "ON" or "OFF"))

        local function CreateSld(label, dbKey, y, minVal, maxVal)
            -- OptionsSliderTemplate deprecated in 10.0 → manual slider, preserves s.Text API
            local s = CreateFrame("Slider", nil, frame)
            s:SetPoint("TOP", 0, y); s:SetSize(200,16); s:SetOrientation("HORIZONTAL")
            s:SetMinMaxValues(minVal, maxVal); s:SetValueStep(0.1); s:SetObeyStepOnDrag(true)
            s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
            local bg=s:CreateTexture(nil,"BACKGROUND"); bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background"); bg:SetAllPoints()
            s.Text = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            s.Text:SetPoint("BOTTOM", s, "TOP", 0, 2); s:SetValue(DelveTrackerDB[dbKey] or 1)
            s:SetScript("OnValueChanged", function(self, v) DelveTrackerDB[dbKey] = v; self.Text:SetText(label .. " (" .. string.format("%.1f", v) .. ")") end)
            s.Text:SetText(label .. " (" .. string.format("%.1f", s:GetValue()) .. ")")
        end

        CreateSld("Speed", "CA_Speed", -160, 0.5, 3.0)
        CreateSld("Scale", "CA_Size", -210, 0.5, 2.5)

        local function CreateEB(label, dbKey, y)
            local t = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            t:SetPoint("TOP", 0, y); t:SetText(label); t:SetTextColor(0.8, 0.8, 0.8)
            local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
            eb:SetSize(220, 22); eb:SetPoint("TOP", 0, y-18); eb:SetAutoFocus(false)
            eb:SetText(DelveTrackerDB[dbKey] or ""); eb:SetScript("OnTextChanged", function(self) DelveTrackerDB[dbKey] = self:GetText() end)
        end

        CreateEB("Start Text:", "CA_StartText", -270)
        CreateEB("End Text:", "CA_StopText", -320)

        local unlockBtn = CreateSlayerBtn("Adjust Position", -380, function(self)
            if CA_Frame:IsMouseEnabled() then 
                CA_Frame:EnableMouse(false); CA_Frame:RegisterForDrag(); if CA_Frame.bg then CA_Frame.bg:Hide() end; self.t:SetText("Adjust Position")
            else 
                CA_Frame:EnableMouse(true); CA_Frame:RegisterForDrag("LeftButton"); CA_Frame.bg = CA_Frame.bg or CA_Frame:CreateTexture(nil, "BACKGROUND")
                CA_Frame.bg:SetAllPoints(); CA_Frame.bg:SetColorTexture(0, 0.5, 1, 0.3); CA_Frame.bg:Show()
                CA_Frame:Show(); CA_Frame:SetAlpha(1); self.t:SetText("LOCK POSITION") 
            end
        end)

        CreateSlayerBtn("TEST", -450, function() CA_Frame.PlayAnim(true) end)
        
        return frame
    end

    -- SLASH COMMAND LOGIC
    local menu
    SLASH_CSET1 = "/cset"
    SlashCmdList["CSET"] = function()
        CheckDB()
        if not menu then 
            menu = CreateSettingsMenu()
            menu:Show() 
        else
            if menu:IsShown() then 
                menu:Hide() 
            else 
                menu:Show() 
            end
        end
    end

    local eF = CreateFrame("Frame")
    eF:RegisterEvent("PLAYER_REGEN_DISABLED"); eF:RegisterEvent("PLAYER_REGEN_ENABLED"); eF:RegisterEvent("PLAYER_LOGIN")
    eF:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then CheckDB(); LoadPosition()
        else CA_Frame.PlayAnim(event == "PLAYER_REGEN_DISABLED") end
    end)

    DelveTracker:RegisterPlugin("CombatAnnounce", function() end)
end