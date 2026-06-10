local function CreateTextures(f)

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

    local sw = GetScreenWidth()
    local headHeight, footHeight = 140, 100
    if not f.OverlayCanvas then
        f.OverlayCanvas = CreateFrame("Frame", nil, f)
        f.OverlayCanvas:SetAllPoints(f)
        f.OverlayCanvas:SetFrameLevel(f:GetFrameLevel() - 1) 
    end
    if not f.topBg then
        f.topBg = f.OverlayCanvas:CreateTexture(nil, "BACKGROUND")
        f.topBg:SetSize(sw, headHeight)
        f.topBg:SetPoint("TOPLEFT", 0, 0)
        f.topBg:SetColorTexture(0, 0, 0, 0.8)
    end
    if not f.bottomBg then
        f.bottomBg = f.OverlayCanvas:CreateTexture(nil, "BACKGROUND")
        f.bottomBg:SetSize(sw, footHeight)
        f.bottomBg:SetPoint("BOTTOMLEFT", 0, 0)
        f.bottomBg:SetColorTexture(0, 0, 0, 0.8)
    end
end

local function InitOverlay()
    if DT_CustomAFK_Frame then 
        CreateTextures(DT_CustomAFK_Frame) 
    else 
        C_Timer.After(0.5, InitOverlay) 
    end
end
InitOverlay()