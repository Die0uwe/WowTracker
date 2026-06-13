-- =====================================================
-- DelveTracker Plugin: TooltipExtra v8.2
-- FIX: Syntax error (missing end) & database scan
-- =====================================================

if DelveTracker then
    -- 1. DATABASE & SETTINGS
    local function GetSettings()
        if not DelveTrackerDB then DelveTrackerDB = {} end
        if not DelveTrackerDB.MenuSettings then
            DelveTrackerDB.MenuSettings = {
                { label = "Character Roster", action = "/crew" },
                { label = "Charmory", action = "/charmory" },
                { label = "Curency", action = "/cbot" },
                { label = "Settings", action = "#" },
                { label = "-set menu", action = "/dmenu" },
                { label = "UC Panel", action = "#" },
                { label = "-Combad Announcer", action = "/cset" },
            }
        end
        return DelveTrackerDB.MenuSettings
    end

    -- 2. ACTION HANDLER
    local function ExecuteAction(action)
        if not action or action == "" or action == "#" or action == "None" then return end
        -- CloseDropDownMenus() removed: UIDropDownMenu API gone in 12.0.5
        -- MenuUtil context menus close automatically on button click

        -- Check for tabs
        if action == "Tab1" or action == "Tab2" or action == "Tab3" then
            if DelveTrackerFrame then 
                DelveTrackerFrame:Show()
                local tabNum = action:match("%d")
                local targetTab = _G["DT_Tab"..tabNum]
                if targetTab then targetTab:Click() end
            end
            return
        end

        -- FIX for Logout/Exit: use official Blizzard popup
        -- In a city this logs out immediately without a timer.
        if action == "/logout" or action == "/camp" then
            StaticPopup_Show("CAMP")
            return
        elseif action == "/exit" or action == "/quit" then
            StaticPopup_Show("QUIT")
            return
        elseif action == "ReloadUI" or action == "/rl" then
            ReloadUI()
            return
        end

        -- Other commands (via chat box method)
        if action:sub(1,1) == "/" then
            local editBox = ChatEdit_ChooseBoxForSend()
            ChatEdit_ActivateChat(editBox)
            editBox:SetText(action)
            ChatEdit_SendText(editBox)
        end
    end

    -- 3. CONFIG WINDOW
    local f = CreateFrame("Frame", "DT_SlayerConfig", UIParent, "BackdropTemplate")
    f:SetSize(720, 550); f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    f:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
    f:SetBackdropBorderColor(0.2, 0.2, 0.2, 1) 
    f:Hide(); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(140, 30); saveBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    saveBtn:SetText("Save & Reload")
    saveBtn:SetScript("OnClick", function() ReloadUI() end)

    local rows = {}
    local function RefreshRows()
        local s = GetSettings()
        for i = 1, 15 do
            if rows[i] then
                rows[i].eb1:SetText(s[i] and s[i].label or "")
                rows[i].eb2:SetText(s[i] and s[i].action or "")
            end
        end
    end

    local sf = CreateFrame("ScrollFrame", "DT_SlayerScroll", f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 15, -40); sf:SetPoint("BOTTOMRIGHT", -35, 60)
    local child = CreateFrame("Frame", nil, sf); child:SetSize(640, 950); sf:SetScrollChild(child)

    WT_MakeSAScrollbar(sf, f)

    for i = 1, 15 do
        local row = CreateFrame("Frame", nil, child, "BackdropTemplate")
        row:SetSize(620, 50); row:SetPoint("TOPLEFT", 5, -(i-1)*55)
        row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        row:SetBackdropColor(0.05, 0.05, 0.05, 0.6)
        row:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

        local eb1 = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        eb1:SetSize(190, 25); eb1:SetPoint("LEFT", 10, 0); eb1:SetAutoFocus(false)
        eb1:SetScript("OnTextChanged", function(self) 
            local s = GetSettings()
            if not s[i] then s[i] = {} end
            s[i].label = self:GetText()
            saveBtn:SetText("|cff00ff00SAVE & RELOAD|r")
        end)

        local eb2 = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        eb2:SetSize(250, 25); eb2:SetPoint("LEFT", 210, 0); eb2:SetAutoFocus(false)
        eb2:SetScript("OnTextChanged", function(self) 
            local s = GetSettings()
            if not s[i] then s[i] = {} end
            s[i].action = self:GetText()
            saveBtn:SetText("|cff00ff00SAVE & RELOAD|r")
        end)

        local up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        up:SetSize(40, 25); up:SetPoint("RIGHT", -55, 0); up:SetText("UP")
        up:SetScript("OnClick", function()
            if i > 1 then
                local s = GetSettings()
                s[i], s[i-1] = s[i-1], s[i]
                RefreshRows()
                saveBtn:SetText("|cff00ff00SAVE & RELOAD|r")
            end
        end)

        local down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        down:SetSize(40, 25); down:SetPoint("RIGHT", -10, 0); down:SetText("DN")
        down:SetScript("OnClick", function()
            if i < 15 then
                local s = GetSettings()
                s[i], s[i+1] = s[i+1], s[i]
                RefreshRows()
                saveBtn:SetText("|cff00ff00SAVE & RELOAD|r")
            end
        end)
        rows[i] = { eb1 = eb1, eb2 = eb2 }
    end
    f:SetScript("OnShow", RefreshRows)

    -- 4. SLASH COMMANDS
    SLASH_DMENU1 = "/dmenu"
    SlashCmdList["DMENU"] = function() if f:IsShown() then f:Hide() else f:Show() end end

    -- 5. RIGHT-CLICK MENU
    -- UIDropDownMenuTemplate + UIDropDownMenu_* REMOVED in TWW 12.0.5
    -- Replaced with MenuUtil.CreateContextMenu (native TWW API, supports nested submenus)
    local function BuildContextMenu(owner)
        if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
        local settings = GetSettings()
        MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
            rootDescription:CreateTitle("|cffa335eeOperations|r")
            local i = 1
            while i <= #settings do
                local cfg = settings[i]
                if cfg.label and cfg.label ~= "" and not cfg.label:match("^%-") then
                    -- Determine label colour (preserve original colouring logic)
                    local lc = "|cff00ccff"
                    if cfg.label:find("Settings") then lc = "|cffffa500" end
                    if cfg.label:find("UC")       then lc = "|cffff6666" end
                    local labelText = lc .. cfg.label .. "|r"
                    -- Check if following entry is a sub-item (starts with "-")
                    local hasSub = settings[i+1] and settings[i+1].label and settings[i+1].label:match("^%-")
                    if hasSub then
                        -- Parent entry → create submenu button
                        local sub = "|cff0000ff"
                        if cfg.label:find("Settings") then sub = "|cffffa500" end
                        if cfg.label:find("UC")       then sub = "|cffff6666" end
                        local parentBtn = rootDescription:CreateButton(labelText)
                        local j = i + 1
                        while j <= #settings and settings[j].label and settings[j].label:match("^%-") do
                            local childCfg = settings[j]
                            local cleanLabel = childCfg.label:gsub("^%-+",""):gsub("^%s*","")
                            local childAction = childCfg.action
                            parentBtn:CreateButton(sub..cleanLabel.."|r", function() ExecuteAction(childAction) end)
                            j = j + 1
                        end
                        i = j  -- skip processed children
                    else
                        local action = cfg.action
                        rootDescription:CreateButton(labelText, function() ExecuteAction(action) end)
                        i = i + 1
                    end
                else
                    i = i + 1
                end
            end
        end)
    end

    -- 6. TOOLTIP REGISTRATION
    DelveTracker:RegisterPlugin("TooltipExtra", function(eventType, data, key)
        if eventType == "Tooltip" and data then
            GameTooltip:AddLine("|cffa335eeSLAYER OVERVIEW|r")
            
            if data.delves then
                for _, v in ipairs(data.delves) do
                    local color = (v.p >= v.t) and "|cff00ff00" or "|cffff4444"
                    GameTooltip:AddDoubleLine("Tier "..v.t..":", color..v.p.." / "..v.t.."|r")
                end
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ccffAccount Keys:|r")
            
            local totalKeys = 0
            -- Check zowel 'Characters' als 'characters' (backwards compat)
            local charTable = DelveTrackerDB and (DelveTrackerDB.Characters or DelveTrackerDB.characters)
            
            if charTable then
                for charName, charData in pairs(charTable) do
                    local keys = 0
                    if charData.Currencies then
                        keys = (charData.Currencies[3028] and charData.Currencies[3028].amount) or 
                               (charData.Currencies["3028"] and charData.Currencies["3028"].amount) or 0
                    end
                    if keys > 0 then
                        local shortName = charName:match("([^-]+)") or charName
                        GameTooltip:AddDoubleLine(shortName, "|cffffffff"..keys.."|r")
                        totalKeys = totalKeys + keys
                    end
                end
            end
            
            GameTooltip:AddDoubleLine("|cff00ff00Totaal Keys:|r", "|cffffffff"..totalKeys.."|r")
            GameTooltip:Show()
        end
    end)

    -- 7. MENU INIT via MenuUtil (replaces UIDropDownMenu_Initialize + ToggleDropDownMenu)
    C_Timer.After(1.5, function()
        if DT_MurlocBtn then
            DT_MurlocBtn:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    BuildContextMenu(self)
                end
            end)
        end
    end)

end -- DIT IS DE 'END' DIE JE MISTE VOOR 'if DelveTracker then'