-- =====================================================
-- DelveTracker Plugin: Help Guide v1.5
-- Standalone frame — niet langer op opt canvas
-- =====================================================

if DelveTracker then
    DelveTracker:RegisterPlugin("HelpGuide", function() end)

    local SA_GOLD   = "|cffccaa00"
-- v3.3.0 (i18n ronde 3): vertaal-helper
local function T(key)
    if WT_T then return WT_T(key) end
    return key
end

    local SA_PURPLE = "|cffa335ee"
    local SA_BLUE   = "|cff00ccff"
    local SA_GREEN  = "|cff00ff00"
    local WHITE     = "|cffffffff"
    local C_2002    = "Fonts\\2002.ttf"

    -- Standalone help frame (niet op opt canvas)
    local function T(k) return WT_T and WT_T(k) or k end
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
    hdrTxt:SetText(SA_PURPLE.."WowTracker|r  "..SA_GOLD..T("HG_TITLE").."|r")

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
        SA_BLUE..T("HG_BASIC")..WHITE.."\n"..
        "  • "..T("HG_B1").."\n"..
        "  • "..T("HG_B2").."\n"..
        "  • "..T("HG_B3").."\n\n"..
        SA_PURPLE..T("HG_TABS")..WHITE.."\n"..
        "  • "..T("HG_T1").."\n"..
        "  • "..T("HG_T2").."\n"..
        "  • "..T("HG_T3").."\n"..
        "  • "..T("HG_T4").."\n"..
        "  • "..T("HG_T5").."\n"..
        "  • "..T("HG_T6").."\n\n"..
        SA_GOLD..T("HG_SLASH")..WHITE.."\n"..
        "  /wt  /dt  /delves     — "..T("HG_S1").."\n"..
        "  /wt1  /wt2  /wt3      — "..T("HG_S2").."\n"..
        "  /wt4  /wt5  /wt6      — "..T("HG_S3").."\n"..
        "  /prey  /pton  /ptoff  — "..T("HG_S4").."\n"..
        "  /crew                 — "..T("HG_S5").."\n"..
        "  /cbud  /cloth         — "..T("HG_S6").."\n"..
        "  /snr  /mt             — "..T("HG_S7").."\n"..
        "  /dtlockout  /dtprof   — "..T("HG_S8").."\n"..
        "  /cbot                 — "..T("HG_S9").."\n"..
        "  /dtafk  /dtgrid       — "..T("HG_S10").."\n"..
        "  /dtdebug              — "..T("HG_S11").."\n"..
        "  /dthelp               — "..T("HG_S12").."\n"..
        "  /dtmem                — "..T("HG_S13").."\n"..
        "  /wt-reload            — "..T("HG_S14").."\n\n"..
        SA_GREEN..T("HG_DISCORD")..WHITE.."\n"..
        "  https://slayeralliance.com/discord\n"..
        "  https://slayeralliance.com"
    )
    sc:SetHeight(txt:GetStringHeight() + 20)
    -- v3.3.0: tekst herbouwen bij elk openen (actuele taal)
    helpFrame:HookScript("OnShow", function()
        txt:SetText(
            SA_BLUE..T("HG_BASIC")..WHITE.."\n"..
            "  • "..T("HG_B1").."\n"..
            "  • "..T("HG_B2").."\n"..
            "  • "..T("HG_B3").."\n\n"..
            SA_PURPLE..T("HG_TABS")..WHITE.."\n"..
            "  • "..T("HG_T1").."\n"..
            "  • "..T("HG_T2").."\n"..
            "  • "..T("HG_T3").."\n"..
            "  • "..T("HG_T4").."\n"..
            "  • "..T("HG_T5").."\n"..
            "  • "..T("HG_T6").."\n\n"..
            SA_GOLD..T("HG_SLASH")..WHITE.."\n"..
            "  /wt  /dt  /delves     — "..T("HG_S1").."\n"..
            "  /wt1  /wt2  /wt3      — "..T("HG_S2").."\n"..
            "  /wt4  /wt5  /wt6      — "..T("HG_S3").."\n"..
            "  /prey  /pton  /ptoff  — "..T("HG_S4").."\n"..
            "  /crew                 — "..T("HG_S5").."\n"..
            "  /cbud  /cloth         — "..T("HG_S6").."\n"..
            "  /snr  /mt             — "..T("HG_S7").."\n"..
            "  /dtlockout  /dtprof   — "..T("HG_S8").."\n"..
            "  /cbot                 — "..T("HG_S9").."\n"..
            "  /dtafk  /dtgrid       — "..T("HG_S10").."\n"..
            "  /dtdebug              — "..T("HG_S11").."\n"..
            "  /dthelp               — "..T("HG_S12").."\n"..
            "  /dtmem                — "..T("HG_S13").."\n"..
            "  /wt-reload            — "..T("HG_S14").."\n\n"..
            SA_GREEN..T("HG_DISCORD")..WHITE.."\n"..
            "  https://slayeralliance.com/discord\n"..
            "  https://slayeralliance.com"
        )
        sc:SetHeight(txt:GetStringHeight() + 20)
    end)

    SLASH_DTHELP1 = "/dthelp"
    SlashCmdList["DTHELP"] = function()
        if helpFrame:IsShown() then helpFrame:Hide()
        else helpFrame:Show() end
    end
end
