-- =====================================================
-- DelveTracker Plugin: Help Guide v1.4 (ULTIMATE - EN)
-- =====================================================

if DelveTracker then
    DelveTracker:RegisterPlugin("HelpGuide", function() end)

    local opt = _G["DelveTrackerOptions"]
    if not opt then return end

    -- Color codes for scannability
    local SA_GOLD = "|cffccaa00"
    local SA_PURPLE = "|cffa335ee"
    local SA_BLUE = "|cff00ccff"
    local SA_GREEN = "|cff00ff00"
    local WHITE = "|cffffffff"

    -- 1. Create the ScrollFrame
    if not opt.scrollFrame then
        opt.scrollFrame = CreateFrame("ScrollFrame", "DTHelpScrollFrame", opt, "UIPanelScrollFrameTemplate")
        opt.scrollFrame:SetPoint("TOPLEFT", 150, -420) 
        opt.scrollFrame:SetSize(380, 200) 
        
        opt.scrollBG = opt.scrollFrame:CreateTexture(nil, "BACKGROUND")
        opt.scrollBG:SetAllPoints()
        opt.scrollBG:SetColorTexture(0, 0, 0, 0.2) 
    end

    -- 2. Create the Content Container
    if not opt.scrollContent then
        opt.scrollContent = CreateFrame("Frame", nil, opt.scrollFrame)
        opt.scrollContent:SetSize(360, 850) 
        opt.scrollFrame:SetScrollChild(opt.scrollContent)
    end

    -- 3. Full Help Text in English
    opt.helpBox = opt.helpBox or opt.scrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    opt.helpBox:ClearAllPoints()
    opt.helpBox:SetPoint("TOPLEFT", 5, -5)
    opt.helpBox:SetWidth(350) 
    opt.helpBox:SetJustifyH("LEFT")
    opt.helpBox:SetSpacing(4)

    opt.helpBox:SetText(
        SA_BLUE .. "BASIC CONTROLS:" .. WHITE .. "\n" ..
        "• Click the Murloc to open the tracker.\n" ..
        "• Right-click + drag the Murloc to reposition it.\n" ..
        "• Use the cogwheel in the main window for options.\n\n" ..
        
        SA_PURPLE .. "CHARACTER REGISTRY (XL Index):" .. WHITE .. "\n" ..
        "• Click the " .. SA_PURPLE .. "[B]" .. WHITE .. " button top-right for the full overview.\n" ..
        "• Click a name in the list to open the " .. SA_BLUE .. "Armory" .. WHITE .. ".\n" ..
        "• The Armory displays 3D models, gear, and iLvls.\n\n" ..

        SA_GOLD .. "ALL SLASH COMMANDS (/cmd):" .. WHITE .. "\n" ..
        SA_BLUE .. "/delves" .. WHITE .. " - Open/Close the main window.\n" ..
        SA_BLUE .. "/dt1" .. WHITE .. " or " .. SA_BLUE .. "/tb1" .. WHITE .. " - Jump to Guild Tab.\n" ..
        SA_BLUE .. "/dt2" .. WHITE .. " or " .. SA_BLUE .. "/tb2" .. WHITE .. " - Jump to Delves List.\n" ..
        SA_BLUE .. "/dt3" .. WHITE .. " or " .. SA_BLUE .. "/tb3" .. WHITE .. " - Jump to Bounty Overview.\n\n" ..

        SA_GREEN .. "SYSTEM & UTILITIES:" .. WHITE .. "\n" ..
        SA_BLUE .. "/dthelp" .. WHITE .. " - Displays this help guide.\n" ..
        SA_BLUE .. "/dtcombat" .. WHITE .. " - Toggle Combat Announcer ON/OFF.\n" ..
        SA_BLUE .. "/dtreload" .. WHITE .. " - Fast UI Reload.\n" ..
        SA_BLUE .. "/dtmem" .. WHITE .. " - Show addon memory usage in chat.\n\n" ..

        SA_PURPLE .. "BOUNTY TRACKER:" .. WHITE .. "\n" ..
        "• Tracks which Delves are currently 'Bountiful'.\n" ..
        "• Shows the predicted rotation for tomorrow.\n" ..
        "• Fully prepared for the " .. SA_GOLD .. "Midnight" .. WHITE .. " release.\n\n" ..

        SA_GOLD .. "DISCORD & COMMUNITY:" .. WHITE .. "\n" ..
        "• Copy the link at the bottom of the main UI to join the Slayer Alliance community!"
    )

    -- 4. Slash command to open help directly
    SLASH_DTHELP1 = "/dthelp"
    SlashCmdList["DTHELP"] = function()
        if not DelveTrackerOptions:IsShown() then
            Settings.OpenToCategory("DelveTracker")
        end
    end
end