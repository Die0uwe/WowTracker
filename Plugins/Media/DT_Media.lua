-- =====================================================
-- DelveTracker Plugin: DT_Media (v17 MASTER)
-- Includes: 40% Width, Dynamic Delve images, 
-- UCdieouwe Placeholder and fix for Azj-Kahet.
-- =====================================================

local function InitMedia()
    local placeholder = "Interface\\AddOns\\DelveTracker\\Media\\UCdieouwe.tga"
    
    -- Exact zone names as defined in the Core
    local zones = {"Isle of Dorn", "Ringing Deeps", "Hallowfall", "Azj-Kahet"}

    for _, zoneName in ipairs(zones) do
        -- Find the frame: Core uses gsub("%s",""), so "Isle of Dorn" becomes "IsleofDorn"
        -- But "Azj-Kahet" stays "Azj-Kahet" (hyphen has no space)
        local frameName = "DT_Tile_" .. zoneName:gsub("%s", "")
        local tile = _G[frameName]
        
        if tile and tile.active then
            -- 1. Get the current Delve name from the text (e.g. "|cff...The Sinkhole|r")
            local rawText = tile.active:GetText() or ""
            -- 2. Clean the text: strip colour codes, spaces, lowercase
            local cleanName = rawText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            cleanName = cleanName:gsub("%s", ""):gsub("'", ""):lower()
            
            -- 3. Determine the path (e.g. Media/thesinkhole.tga)
            local delveTexture = "Interface\\AddOns\\DelveTracker\\Media\\"..cleanName..".tga"

            -- Create the texture if it does not exist yet
            if not tile.bgTex then
                tile.bgTex = tile:CreateTexture(nil, "ARTWORK") -- ARTWORK voor scherpte
                tile.bgTex:SetPoint("TOPLEFT", tile, "TOPLEFT", 1, -1)
                tile.bgTex:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 1, 1)
                tile.bgTex:SetWidth(152) -- Precies 40% van 380px
            end
            
            -- Style settings for a clean image
            tile.bgTex:SetAlpha(1.0)
            tile.bgTex:SetTexCoord(0, 1, 0, 1)
            
            -- Try to load the specific Delve image
            tile.bgTex:SetTexture(delveTexture)
            
            -- If the file does not exist (empty result), use the UCdieouwe placeholder
            if not tile.bgTex:GetTexture() then
                tile.bgTex:SetTexture(placeholder)
            end

            -- Ensure Core text is always positioned right of the image
            if tile.zone then 
                tile.zone:ClearAllPoints()
                tile.zone:SetPoint("TOPLEFT", tile.bgTex, "TOPRIGHT", 15, -8) 
            end
            if tile.active then 
                tile.active:ClearAllPoints()
                tile.active:SetPoint("LEFT", tile.bgTex, "RIGHT", 15, -2) 
            end
            if tile.tomorrow then 
                tile.tomorrow:ClearAllPoints()
                tile.tomorrow:SetPoint("BOTTOMLEFT", tile.bgTex, "BOTTOMRIGHT", 15, 8) 
            end
            
            -- Background of the tile itself (text area)
            tile:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
        end
    end
end

-- Register via PLAYER_LOGIN zodat DelveTracker global zeker bestaat
local _wtMediaReg = CreateFrame("Frame")
_wtMediaReg:RegisterEvent("PLAYER_LOGIN")
_wtMediaReg:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if DelveTracker and DelveTracker.RegisterPlugin then
        DelveTracker:RegisterPlugin("Media", function(mode)
            if mode == "Init" then InitMedia() end
        end)
    end
end)

-- Events for loading and switching tabs
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    C_Timer.After(0.7, InitMedia) -- Wacht tot Core klaar is met scannen
end)

-- Refresh when the UI is opened
if DelveTrackerFrame then
    DelveTrackerFrame:HookScript("OnShow", function()
        C_Timer.After(0.1, InitMedia)
    end)
end