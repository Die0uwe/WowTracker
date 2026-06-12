-- =====================================================
-- DelveTracker Plugin: Help Guide v1.5
-- Standalone frame — niet langer op opt canvas
-- =====================================================

if DelveTracker then
    DelveTracker:RegisterPlugin("HelpGuide", function() end)

    local SA_GOLD   = "|cffccaa00"
    local SA_PURPLE = "|cffa335ee"
    local SA_BLUE   = "|cff00ccff"
    local SA_GREEN  = "|cff00ff00"
    local WHITE     = "|cffffffff"
    local C_2002    = "Fonts\\2002.ttf"

    -- Standalone help frame (niet op opt canvas)
    local helpFrame = CreateFrame("Frame","DT_HelpFrame",UIParent,"BackdropTemplate")
    helpFrame:SetSize(480, 560)
    helpFrame:SetPoint("CENTER")
    helpFrame:SetMovable(true)
    helpFrame:EnableMouse(true)
    helpFrame:RegisterForDrag("LeftButton")
    helpFrame:SetClampedToScreen(true)
    helpFrame:SetFrameStrata("HIGH")
    helpFrame:SetToplevel(true)
    helpFrame:Hide()
    helpFrame:SetBackdrop({
        bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Buttons\\WHITE8x8",
        edgeSize=1,
    })
    helpFrame:SetBackdropColor(0.04,0.02,0.08,0.97)
    helpFrame:SetBackdropBorderColor(0.40,0.12,0.65,1)
        -- ── WTTHEME KOPPELING (Fase 3.2 ronde 2 · v3.2.8) ──
        if WTTheme and WTTheme.Register then
            local function _applyTheme()
                local bg  = WTTheme.bg and WTTheme.bg.main
                local bdr = WTTheme.border and WTTheme.border.main
                if bg then helpFrame:SetBackdropColor(bg.r, bg.g, bg.b, math.max(bg.a or 0.97, 0.95)) end
                if bdr then helpFrame:SetBackdropBorderColor(bdr.r, bdr.g, bdr.b, 1) end
            end
            WTTheme.Register(_applyTheme)
            _applyTheme()
        end
    helpFrame:SetScript("OnDragStart",helpFrame.StartMoving)
    helpFrame:SetScript("OnDragStop",helpFrame.StopMovingOrSizing)

    -- Header
    local hdrBG = helpFrame:CreateTexture(nil,"BACKGROUND")
    hdrBG:SetHeight(36)
    hdrBG:SetPoint("TOPLEFT",1,-1)
    hdrBG:SetPoint("TOPRIGHT",-1,-1)
    hdrBG:SetColorTexture(0.08,0.04,0.14,1)

    local hdrTxt = helpFrame:CreateFontString(nil,"OVERLAY")
    hdrTxt:SetFont(C_2002,13,"OUTLINE")
    hdrTxt:SetPoint("TOPLEFT",12,-10)
    hdrTxt:SetText(SA_PURPLE.."WowTracker|r  "..SA_GOLD.."Help Guide|r")

    local closeBtn = CreateFrame("Button",nil,helpFrame,"UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT",helpFrame,"TOPRIGHT",2,-2)

    -- Scroll
    local sf = CreateFrame("ScrollFrame",nil,helpFrame,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",8,-42)
    sf:SetPoint("BOTTOMRIGHT",-24,8)

    local sc = CreateFrame("Frame",nil,sf)
    sc:SetWidth(440)
    sc:SetHeight(1)
    sf:SetScrollChild(sc)

    local txt = sc:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    txt:SetPoint("TOPLEFT",5,-5)
    txt:SetWidth(430)
    txt:SetJustifyH("LEFT")
    txt:SetSpacing(5)
    txt:SetText(
        SA_BLUE.."BASIC CONTROLS:"..WHITE.."\n"..
        "  • Klik de Murloc om de tracker te openen.\n"..
        "  • Rechtermuisklik + sleep om te verplaatsen.\n"..
        "  • Tandwiel bovenaan voor instellingen.\n\n"..
        SA_PURPLE.."TABS:"..WHITE.."\n"..
        "  • Guild — gilde info + MOTD + online leden\n"..
        "  • Delves — warband karakter lijst + voortgang\n"..
        "  • Bounty — Nemesis/Bountiful/Normal delve tracker\n"..
        "  • Roster — karakter index (klik = Armory)\n"..
        "  • Armory — 3D model + gear + stats\n"..
        "  • Currency — alle currencies per karakter\n\n"..
        SA_GOLD.."SLASH COMMANDS:"..WHITE.."\n"..
        "  /wt  /dt  /delves     — Open/sluit tracker\n"..
        "  /wt1  /wt2  /wt3      — Tab direct openen\n"..
        "  /wt4  /wt5  /wt6      — Roster/Armory/Currency\n"..
        "  /prey  /pton  /ptoff  — Prey Tracker HUD\n"..
        "  /crew                 — Registry XL\n"..
        "  /cbud  /cloth         — ClothCounter\n"..
        "  /snr  /mt             — SkinNRare\n"..
        "  /dtlockout  /dtprof   — Lockout scanner\n"..
        "  /cbot                 — Exchange Bot\n"..
        "  /dtafk  /dtgrid       — AFK scherm\n"..
        "  /dtdebug              — Debug console\n"..
        "  /dthelp               — Dit scherm\n"..
        "  /dtmem                — Geheugengebruik\n"..
        "  /wt-reload            — UI herladen\n\n"..
        SA_GREEN.."DISCORD:"..WHITE.."\n"..
        "  https://slayeralliance.com/discord\n"..
        "  https://slayeralliance.com"
    )
    sc:SetHeight(txt:GetStringHeight() + 20)

    SLASH_DTHELP1 = "/dthelp"
    SlashCmdList["DTHELP"] = function()
        if helpFrame:IsShown() then helpFrame:Hide()
        else helpFrame:Show() end
    end
end
