local function CreateTextures(f)
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