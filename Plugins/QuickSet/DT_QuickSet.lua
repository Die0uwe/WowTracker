-- =====================================================
-- DelveTracker - QuickSet | Tab3
-- Midnight 12.0.05 | v7.1 - Live POI Fix
--
-- Container: 400 x 335 px (PluginArea)
-- Tab 1: Nemesis + Required Items
-- Tab 2: Bountiful Delves
-- Tab 3: Normal Delves (scrollbar only here)
--
-- Changes v7:
--   [FIX] Scrollbar: Tab 1+2 hidden, Tab 3 anchored inside frame
--   [FIX] SCROLL_W recalculated so tiles fit inside scrollbar
--   [FIX] Valeera: PlayerModel frame with SetDisplayInfo (true 3D portrait)
--   [FIX] Item count: outlined badge directly over icon bottom-right
--         "in bags" label removed
--   [NEW] Tooltip: shows every story achievement criterion (quest) individually
--         with done/not-done indicator + chest criteria
-- =====================================================

if not DelveTracker then return end

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



-- -- Color scheme -------------------------------------------------------------
local CO = {
    orange  = "|cffff6600",
    magenta = "|cffff44cc",
    blue    = "|cff33aaff",
    teal    = "|cff00eedd",
    green   = "|cff44ff88",
    gray    = "|cff99aabb",
    white   = "|cffffffff",
    red     = "|cffff5555",
    silver  = "|cffccddee",
    gold    = "|cffffcc00",
}

local VALEERA_FACTION_ID = 2744
local VALEERA_DISPLAY_ID = 26365  -- creature/NPC display ID for Valeera Sanguinar

-- -- Layout constants ----------------------------------------------------------
-- UIPanelScrollFrameTemplate places scrollbar 4px to the right of the frame,
-- scrollbar width = 16px -> total overhang = 20px.
-- To keep scrollbar inside container: right offset must be >= 20.
local CONT_W   = 400
local SF_RIGHT = 20      -- right offset for scrollframe so scrollbar stays inside
-- scroll child width = CONT_W - 1 (left border) - SF_RIGHT - 2 (padding)
local SCROLL_W = CONT_W - 1 - SF_RIGHT - 2   -- = 377
local TILE_H   = 50
local TILE_G   = 3
local TAB_H    = 26
local HDR_H    = 60      -- slightly taller for the 3D model

-- Item panel (Nemesis tab)
local ITEM_GAP = 4
local ITEM_W   = math.floor((SCROLL_W - ITEM_GAP * 2) / 3)
local ITEM_H   = 68

-- Nemesis required items
local SPECIAL_ITEMS = {
    { id = 253342, shortName = "Beacon of Hope"   },
    { id = 252415, shortName = "Trovehunter"      },
    { id = 244193, shortName = "LOOT RAID-R Mini" },
}

-- Delve data
local DELVES = {
    { name="Collegiate Calamity", uiMapID=2577, regular=8425, bountiful=8426, story=61726, chest=61894 },
    { name="Parhelion Plaza",     uiMapID=2545, regular=8427, bountiful=8428, story=61725, chest=61893 },
    { name="Sunkiller Sanctum",   uiMapID=2528, regular=8429, bountiful=8430, story=61732, chest=61899 },
    { name="Shadowguard Point",   uiMapID=2506, regular=8431, bountiful=8432, story=61733, chest=61900 },
    { name="The Grudge Pit",      uiMapID=2510, regular=8433, bountiful=8434, story=61724, chest=61897 },
    { name="Gulf of Memory",      uiMapID=2505, regular=8435, bountiful=8436, story=61731, chest=61898 },
    { name="Shadow Enclave",      uiMapID=2502, regular=8437, bountiful=8438, story=61727, chest=61892 },
    { name="The Darkway",         uiMapID=2525, regular=8439, bountiful=8440, story=61728, chest=61895 },
    { name="Twilight Crypts",     uiMapID=2503, regular=8441, bountiful=8442, story=61730, chest=61896 },
    { name="Atal'Aman",           uiMapID=2535, regular=8443, bountiful=8444, story=61729, chest=61863 },
    { name="Torment's Rise",      uiMapID=2507, regular=8445, bountiful=nil,  story=nil,   chest=nil,  nemesis=61799 },
}

-- -- Helpers -------------------------------------------------------------------
local parentCache = {}
local function ParentMap(id)
    if not id or not C_Map or not C_Map.GetMapInfo then return nil end
    if parentCache[id] then return parentCache[id] end
    local ok, i = pcall(C_Map.GetMapInfo, id)
    if ok and i and i.parentMapID then
        parentCache[id] = i.parentMapID
        return i.parentMapID
    end
end

local function NormalizeDelveName(name)
    if not name then return "" end
    name = tostring(name):lower()
    name = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    name = name:gsub("[%s%p%c]+", " ")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

-- Live delve scanner. 12.x returns the current delve POIs from the zone map.
-- Do not trust hard-coded AreaPOI IDs for bountiful/normal state: those can move
-- between builds while the name + atlas returned by the client stays reliable.
local delvePoiCache, delvePoiCacheTime
local function ScanDelvePOIs(force)
    local now = GetTime and GetTime() or 0
    if not force and delvePoiCache and delvePoiCacheTime and (now - delvePoiCacheTime) < 4 then
        return delvePoiCache
    end

    local cache = { byName = {}, byID = {}, maps = {} }
    delvePoiCache = cache
    delvePoiCacheTime = now

    if not C_AreaPoiInfo or not C_AreaPoiInfo.GetDelvesForMap or not C_AreaPoiInfo.GetAreaPOIInfo then
        return cache
    end

    local mapsToScan = {}
    local function AddMap(id)
        if id and type(id) == "number" and not mapsToScan[id] then
            mapsToScan[id] = true
        end
    end

    for _, d in ipairs(DELVES) do
        AddMap(d.uiMapID)
        local p1 = ParentMap(d.uiMapID)
        AddMap(p1)
        AddMap(ParentMap(p1))
    end

    -- Also scan child zone maps when any scanned map is an expansion/continent map.
    if C_Map and C_Map.GetMapChildrenInfo and Enum and Enum.UIMapType and Enum.UIMapType.Zone then
        local additions = {}
        for mapID in pairs(mapsToScan) do
            local ok, children = pcall(C_Map.GetMapChildrenInfo, mapID, Enum.UIMapType.Zone, true)
            if ok and type(children) == "table" then
                for _, child in ipairs(children) do
                    if child and child.mapID then additions[child.mapID] = true end
                end
            end
        end
        for mapID in pairs(additions) do AddMap(mapID) end
    end

    for mapID in pairs(mapsToScan) do
        local ok, areaPOIs = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
        if ok and type(areaPOIs) == "table" then
            cache.maps[mapID] = true
            for _, areaPoiID in ipairs(areaPOIs) do
                local okInfo, poiInfo = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, areaPoiID)
                if okInfo and poiInfo and poiInfo.name then
                    local atlas = poiInfo.atlasName or ""
                    local zoneName
                    if C_Map and C_Map.GetMapInfo then
                        local okMap, mapInfo = pcall(C_Map.GetMapInfo, mapID)
                        if okMap and mapInfo then zoneName = mapInfo.name end
                    end
                    local entry = {
                        name = poiInfo.name,
                        mapID = mapID,
                        areaPoiID = areaPoiID,
                        atlas = atlas,
                        zoneName = zoneName,
                        isBountiful = type(atlas) == "string" and atlas:lower():find("bountiful", 1, true) ~= nil,
                        isPrimaryMapForPOI = poiInfo.isPrimaryMapForPOI,
                    }
                    cache.byID[areaPoiID] = entry
                    cache.byName[NormalizeDelveName(poiInfo.name)] = entry
                end
            end
        end
    end

    return cache
end

local function GetLiveDelveInfo(d)
    if not d then return nil end
    local cache = ScanDelvePOIs(false)
    local live = cache.byName[NormalizeDelveName(d.name)]
    if not live then
        -- Fallback: sometimes locale/name text differs slightly; try contains matching both ways.
        local wanted = NormalizeDelveName(d.name)
        for key, entry in pairs(cache.byName) do
            if wanted ~= "" and (key:find(wanted, 1, true) or wanted:find(key, 1, true)) then
                live = entry
                break
            end
        end
    end
    d._livePoi = live
    return live
end

local function IsBountiful(d)
    local live = GetLiveDelveInfo(d)
    if live then return live.isBountiful end

    -- Last-resort legacy fallback for old saved tables/builds.
    if not d or not d.bountiful then return false end
    local pid = ParentMap(d.uiMapID); if not pid then return false end
    local ok, list = pcall(C_AreaPoiInfo.GetDelvesForMap, pid)
    return ok and type(list) == "table" and tContains(list, d.bountiful)
end

local function OpenLiveDelve(d)
    local live = GetLiveDelveInfo(d)
    if not live or not live.mapID or not live.areaPoiID then
        print(CO.red .. "DelveTracker: live delve POI not found for " .. (d and d.name or "?") .. ".|r")
        return
    end

    if not WorldMapFrame then return end
    if not WorldMapFrame:IsShown() then
        if WorldMapFrame.HandleUserActionOpenSelf then
            WorldMapFrame:HandleUserActionOpenSelf()
        elseif ToggleWorldMap then
            ToggleWorldMap()
        end
    end

    if WorldMapFrame.SetMapID then
        WorldMapFrame:SetMapID(live.mapID)
    end

    if not C_Timer or not C_Timer.After then return end
    C_Timer.After(0.05, function()
        if not WorldMapFrame or not WorldMapFrame.EnumeratePinsByTemplate then return end
        for pin in WorldMapFrame:EnumeratePinsByTemplate("DelveEntrancePinTemplate") do
            local pinID = pin.areaPoiID or (pin.poiInfo and pin.poiInfo.areaPoiID)
            if pinID == live.areaPoiID then
                if pin.OnClick then pcall(pin.OnClick, pin, "LeftButton", false) end
                break
            end
        end
    end)
end

local function AchInfo(achID)
    if not achID then return nil, nil, nil, nil, nil end
    local ok, _, name, _, completed = pcall(GetAchievementInfo, achID)
    if not ok then return nil, nil, nil, nil, nil end
    local icon  = select(10, GetAchievementInfo(achID))
    local total = GetAchievementNumCriteria(achID) or 0
    local done  = 0
    for i = 1, total do
        local _, _, c = GetAchievementCriteriaInfo(achID, i)
        if c then done = done + 1 end
    end
    return name, done, total, completed, icon
end

-- Returns table of { desc, done } for every criterion of an achievement
local function AchCriteria(achID)
    if not achID then return {} end
    local results = {}
    local ok, total = pcall(GetAchievementNumCriteria, achID)
    if not ok or not total then return results end
    for i = 1, total do
        local pok, desc, _, critDone = pcall(GetAchievementCriteriaInfo, achID, i)
        if pok and desc and desc ~= "" then
            table.insert(results, { desc = desc, done = critDone })
        end
    end
    return results
end

local function ValeeraData()
    local ok1, rank = pcall(C_GossipInfo.GetFriendshipReputationRanks, VALEERA_FACTION_ID)
    local ok2, rep  = pcall(C_GossipInfo.GetFriendshipReputation,      VALEERA_FACTION_ID)
    if ok1 and ok2 and rank and rep then return rank, rep end
    local ok3, fd = pcall(C_Reputation.GetFactionDataByID, VALEERA_FACTION_ID)
    if ok3 and fd then return nil, fd end
    return nil, nil
end

local function BD(t, b)
    return {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = t or 0, right = t or 0, top = b or t or 0, bottom = b or t or 0 },
    }
end

-- -- Tile factory --------------------------------------------------------------
local function NewTile(parent, idx)
    local t = CreateFrame("Button", nil, parent, "BackdropTemplate")
    -- 2-naast-2: oneven links, even rechts
    local col = (idx - 1) % 2        -- 0=links, 1=rechts
    local row = math.floor((idx - 1) / 2)
    local tileW = math.floor((SCROLL_W - TILE_G) / 2)
    local tileH = math.floor(TILE_H * 1.4)  -- hoger dan voor, meer ruimte voor info
    t:SetSize(tileW, tileH)
    -- T04d: 2 tiles gecentreerd in scroll area (berekend vanuit SCROLL_W)
    local totalTileW = 2 * tileW + TILE_G
    local xPad = math.max(0, math.floor((SCROLL_W - totalTileW) / 2))
    t:SetPoint("TOPLEFT", xPad + col * (tileW + TILE_G), -(row * (tileH + TILE_G)))
    t:SetBackdrop(BD(1))

    -- Art background - alpha 0.50: images are clear, no haze
    t.artBg = t:CreateTexture(nil, "BACKGROUND", nil, -2)
    t.artBg:SetPoint("TOPLEFT",     2,  -1)
    t.artBg:SetPoint("BOTTOMRIGHT", -2,  1)
    t.artBg:SetTexCoord(0.0, 0.60, 0.08, 0.82)
    t.artBg:SetAlpha(0.50)

    -- Left color stripe
    t.stripe = t:CreateTexture(nil, "ARTWORK")
    t.stripe:SetSize(4, TILE_H - 2)
    t.stripe:SetPoint("LEFT", 1, 0)

    -- Icon - clean, no color overlay
    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetSize(38, 38)
    t.icon:SetPoint("LEFT", 9, 0)
    t.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

    -- Icon rim - kept fully transparent (no tint)
    t.iconRim = t:CreateTexture(nil, "OVERLAY")
    t.iconRim:SetSize(40, 40)
    t.iconRim:SetPoint("CENTER", t.icon, "CENTER", 0, 0)
    t.iconRim:SetColorTexture(1, 1, 1, 0)

    -- Glow: top-edge bar (hidden until hover)
    t.glowBar = t:CreateTexture(nil, "OVERLAY", nil, 2)
    t.glowBar:SetHeight(2)
    t.glowBar:SetPoint("TOPLEFT",  2, -1)
    t.glowBar:SetPoint("TOPRIGHT", -2, -1)
    t.glowBar:SetAlpha(0)

    -- Glow: left-edge accent (hidden until hover)
    t.glowLeft = t:CreateTexture(nil, "OVERLAY", nil, 2)
    t.glowLeft:SetWidth(4)
    t.glowLeft:SetPoint("TOPLEFT",    1, -1)
    t.glowLeft:SetPoint("BOTTOMLEFT", 1,  1)
    t.glowLeft:SetAlpha(0)

    -- Right badge (Bountiful label)
    t.badge = t:CreateTexture(nil, "ARTWORK")
    t.badge:SetSize(56, TILE_H - 2)
    t.badge:SetPoint("RIGHT", -1, 0)

    t.badgeTxt = t:CreateFontString(nil, "OVERLAY")
    t.badgeTxt:SetPoint("CENTER", t.badge, "CENTER", 0, 0)
    t.badgeTxt:SetJustifyH("CENTER")

    -- Delve name
    t.nameTxt = t:CreateFontString(nil, "OVERLAY")
    t.nameTxt:SetFont("Fonts\\2002.ttf", 12, "")
    t.nameTxt:SetTextColor(0.85, 0.85, 0.85, 1)
    t.nameTxt:SetPoint("TOPLEFT",  t.icon,  "TOPRIGHT", 8, -5)
    t.nameTxt:SetPoint("RIGHT",    t.badge, "LEFT",     -4,  0)
    t.nameTxt:SetJustifyH("LEFT")

    -- Story progress (e.g. "Story: 2/4")
    t.storyTxt = t:CreateFontString(nil, "OVERLAY")
    t.storyTxt:SetFont("Fonts\\2002.ttf", 10, "")
    t.storyTxt:SetTextColor(0.85, 0.85, 0.85, 1)
    t.storyTxt:SetPoint("BOTTOMLEFT", t.icon,  "BOTTOMRIGHT", 8, 12)
    t.storyTxt:SetPoint("RIGHT",      t.badge, "LEFT",        -4,  0)
    t.storyTxt:SetJustifyH("LEFT")

    -- Delve type label
    t.typeTxt = t:CreateFontString(nil, "OVERLAY")
    t.typeTxt:SetPoint("BOTTOMLEFT", t.icon,  "BOTTOMRIGHT", 8,  3)
    t.typeTxt:SetPoint("RIGHT",      t.badge, "LEFT",        -4,  0)
    t.typeTxt:SetJustifyH("LEFT")

    return t
end

-- -- Apply tile style ----------------------------------------------------------
local function StyleTile(t, d, isBountiful, isNemesis)
    local live = GetLiveDelveInfo(d)
    -- Icon from achievement, fallback to generic
    local _, _, _, _, icon = AchInfo(d.story)
    if icon and icon ~= 0 then
        t.icon:SetTexture(icon)
    elseif isBountiful then
        pcall(function() t.icon:SetAtlas((live and live.atlas and live.atlas ~= "" and live.atlas) or "delves-bountiful") end)
    elseif isNemesis then
        t.icon:SetTexture("Interface\\Icons\\Ability_Rogue_MasterOfSubtlety")
    else
        t.icon:SetTexture("Interface\\Icons\\INV_Misc_Dungeon_01")
    end

    if d.art then
        pcall(function() t.artBg:SetAtlas(d.art) end)
    else
        t.artBg:SetColorTexture(0, 0, 0, 0)
    end

    t.iconRim:SetColorTexture(1, 1, 1, 0)  -- always transparent

    if isBountiful then
        -- T06: Bountiful -> SA gold-purple tint (was te oranje)
        t:SetBackdropColor(0.08, 0.04, 0.12, 0.95)
        t:SetBackdropBorderColor(0.65, 0.45, 0.0, 0.85)
        t.stripe:SetColorTexture(0.80, 0.67, 0.0, 1)
        t.badge:SetColorTexture(0.55, 0.38, 0.0, 0.92)
        t.glowBar:SetColorTexture(0.80, 0.67, 0.0, 1)
        t.glowLeft:SetColorTexture(0.80, 0.67, 0.0, 1)
        t.badgeTxt:SetText("|cff100800BOUNTY|r")
        t.typeTxt:SetText("|cffccaa00Bountiful Delve|r")
        t._gr, t._gg, t._gb = 0.80, 0.67, 0.00
        t._br, t._bg, t._bb, t._ba = 0.65, 0.45, 0.0, 0.85

    elseif isNemesis then
        t:SetBackdropColor(0.08, 0.00, 0.12, 0.95)
        t:SetBackdropBorderColor(1.0, 0.20, 0.90, 0.85)
        t.stripe:SetColorTexture(1.0, 0.20, 0.90, 1)
        t.badge:SetColorTexture(0, 0, 0, 0)
        t.glowBar:SetColorTexture(1.0, 0.30, 1.0, 1)
        t.glowLeft:SetColorTexture(1.0, 0.30, 1.0, 1)
        t.badgeTxt:SetText("")
        t.typeTxt:SetText(CO.magenta .. "Nemesis Delve")
        t._gr, t._gg, t._gb = 1.0, 0.30, 1.0
        t._br, t._bg, t._bb, t._ba = 1.0, 0.20, 0.90, 0.85

    else
        t:SetBackdropColor(0.02, 0.06, 0.14, 0.94)
        t:SetBackdropBorderColor(0.20, 0.55, 1.0, 0.75)
        t.stripe:SetColorTexture(0.20, 0.55, 1.0, 1)
        t.badge:SetColorTexture(0, 0, 0, 0)
        t.glowBar:SetColorTexture(0.30, 0.70, 1.0, 1)
        t.glowLeft:SetColorTexture(0.30, 0.70, 1.0, 1)
        t.badgeTxt:SetText("")
        t.typeTxt:SetText(CO.gray .. "Delve")
        t._gr, t._gg, t._gb = 0.30, 0.75, 1.0
        t._br, t._bg, t._bb, t._ba = 0.20, 0.55, 1.0, 0.75
    end
end

-- -- Rich tooltip: shows every story criterion (quest) individually -------------
local function SetTooltip(t, d, isBountiful, isNemesis)
    t:RegisterForClicks("LeftButtonUp")
    t:SetScript("OnClick", function() OpenLiveDelve(d) end)

    t:SetScript("OnEnter", function(self)
        -- Glow effect: border + rim bar only, NO backdrop tint
        self:SetBackdropBorderColor(self._gr, self._gg, self._gb, 1.0)
        self.glowBar:SetAlpha(0.90)
        self.glowLeft:SetAlpha(0.70)

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        -- Header
        local prefix = isBountiful and "[BOUNTY] " or (isNemesis and "[NEMESIS] " or "")
        GameTooltip:AddLine(CO.white .. prefix .. d.name .. "|r")
        if isBountiful then
            GameTooltip:AddLine("|cffccaa00Bountiful Delve|r")
        elseif isNemesis then
            GameTooltip:AddLine(CO.magenta .. "Nemesis Delve|r")
        else
            GameTooltip:AddLine(CO.gray .. "Delve|r")
        end

        local live = GetLiveDelveInfo(d)
        if live then
            GameTooltip:AddLine(CO.gray .. "Live POI: " .. live.areaPoiID .. "  Map: " .. live.mapID .. "|r")
            if live.atlas and live.atlas ~= "" then
                GameTooltip:AddLine(CO.gray .. "Atlas: " .. live.atlas .. "|r")
            end
            GameTooltip:AddLine(CO.teal .. "open world map with pin.|r")
        else
            GameTooltip:AddLine(CO.red .. "Live delve POI not found; using ID fallback.|r")
        end

        -- -- Story achievement with per-quest criteria --
        if d.story then
            local achName, done, total, compl = AchInfo(d.story)
            if achName then
                GameTooltip:AddLine(" ")
                local col = compl and CO.green or CO.teal
                GameTooltip:AddLine(col .. "Story: " .. CO.silver .. achName .. "|r")

                -- Show all individual criteria (quests)
                local criteria = AchCriteria(d.story)
                for _, c in ipairs(criteria) do
                    if c.done then
                        GameTooltip:AddLine(CO.green .. " + " .. CO.white .. c.desc .. "|r", 1, 1, 1, true)
                    else
                        GameTooltip:AddLine(CO.gray  .. " - " .. c.desc .. "|r", 1, 1, 1, true)
                    end
                end

                if total and total > 0 then
                    GameTooltip:AddLine(col .. done .. "/" .. total .. " completed|r")
                end
                if compl then
                    GameTooltip:AddLine(CO.green .. "Achievement completed!|r")
                end
            end
        end

        -- -- Chest / coffer achievement --
        if d.chest then
            local achName, done, total, compl = AchInfo(d.chest)
            if total then
                GameTooltip:AddLine(" ")
                local col = compl and CO.green or CO.gold
                GameTooltip:AddLine(col .. "Coffers: " .. CO.silver .. (achName or "") .. "|r")

                local criteria = AchCriteria(d.chest)
                for _, c in ipairs(criteria) do
                    if c.done then
                        GameTooltip:AddLine(CO.green .. " + " .. CO.white .. c.desc .. "|r", 1, 1, 1, true)
                    else
                        GameTooltip:AddLine(CO.gray  .. " - " .. c.desc .. "|r", 1, 1, 1, true)
                    end
                end

                GameTooltip:AddLine(col .. done .. "/" .. total .. " opened|r")
            end
        end

        -- -- Nemesis achievement --
        if isNemesis and d.nemesis then
            local _, _, _, compl = AchInfo(d.nemesis)
            GameTooltip:AddLine(" ")
            if compl then
                GameTooltip:AddLine(CO.green .. "Nemesis defeated!|r")
            else
                GameTooltip:AddLine(CO.magenta .. "Nemesis active|r")
                GameTooltip:AddLine(CO.gray .. "Beacon of Hope required|r")
            end
        end

        -- -- Bountiful tip --
        if isBountiful then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(CO.orange .. "Bountiful benefits:|r")
            GameTooltip:AddLine(CO.white  .. " + Bountiful Coffer (extra loot)|r")
            GameTooltip:AddLine(CO.white  .. " + Extra Valeera XP|r")
        end

        GameTooltip:Show()
    end)

    t:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self._br, self._bg, self._bb, self._ba)
        self.glowBar:SetAlpha(0)
        self.glowLeft:SetAlpha(0)
        GameTooltip:Hide()
    end)
end

-- Story progress label on the tile
local function FillStory(t, d)
    local _, done, total, compl = AchInfo(d.story)
    if total and total > 0 then
        if compl then
            t.storyTxt:SetText(CO.green .. "Story: Done|r")
        else
            t.storyTxt:SetText(CO.gray .. "Story: " .. done .. "/" .. total .. "|r")
        end
    else
        t.storyTxt:SetText("")
    end
end

-- -- Main build ----------------------------------------------------------------
local function BuildGrid(container)
    if container._dtBuilt then return end
    container._dtBuilt = true
    -- Gebruik container breedte - wacht tot frame gelayout is
    C_Timer.After(0.05, function()
        local cw = container:GetWidth()
        if cw and cw > 200 then
            CONT_W   = math.floor(cw)
            SF_RIGHT = 20
            SCROLL_W = CONT_W - 1 - SF_RIGHT - 2
        end
    end)
    local cw = container:GetWidth()
    if cw and cw > 200 then
        CONT_W   = math.floor(cw)
        SF_RIGHT = 20
        SCROLL_W = CONT_W - 1 - SF_RIGHT - 2
    end

    -- ================================================
    -- 1. VALEERA HEADER
    --    Uses PlayerModel with SetDisplayInfo for true
    --    3D NPC portrait (Valeera Sanguinar).
    -- ================================================
    local hdr = CreateFrame("Frame", nil, container, "BackdropTemplate")
    -- hdr breed als container, gecentreerd
    hdr:SetSize(CONT_W - 2, HDR_H)
    hdr:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
    hdr:SetPoint("TOPRIGHT", container, "TOPRIGHT", -1, -1)
    hdr:SetBackdrop(BD(1))
    hdr:SetBackdropColor(0.02, 0.05, 0.12, 0.98)
    hdr:SetBackdropBorderColor(0.0, 0.75, 0.70, 1)

    -- Teal top accent line
    local topLine = hdr:CreateTexture(nil, "OVERLAY")
    topLine:SetHeight(2)
    topLine:SetPoint("TOPLEFT",  1, -1)
    topLine:SetPoint("TOPRIGHT", -1, -1)
    topLine:SetColorTexture(0.0, 0.95, 0.85, 1)

    -- -- 3D Model portrait --------------------------
    -- PlayerModel with SetDisplayInfo renders the NPC in a portrait-style
    -- close-up. SetPortraitZoom(1) zooms to face/bust.
    hdr.model = CreateFrame("PlayerModel", nil, hdr)
    hdr.model:SetSize(54, 54)
    hdr.model:SetPoint("LEFT", 3, 0)
    -- SetDisplayInfo: load the NPC's visual appearance by displayID
    local modelOk = pcall(function()
        hdr.model:SetDisplayInfo(VALEERA_DISPLAY_ID)
        hdr.model:SetPortraitZoom(1)
        -- SetCamera(0) gives the standard portrait camera angle
        hdr.model:SetCamera(0)
    end)
    if not modelOk then
        -- Fallback: static texture if model fails to load
        hdr.model:Hide()
        hdr.modelFallback = hdr:CreateTexture(nil, "ARTWORK")
        hdr.modelFallback:SetSize(48, 48)
        hdr.modelFallback:SetPoint("LEFT", 4, 0)
        hdr.modelFallback:SetTexture("Interface\\Icons\\Achievement_Character_Bloodelf_Female")
        hdr.modelFallback:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    -- Model clip mask (optional: hides model outside the header frame)
    hdr.model:SetClipsChildren(true)

    -- Teal border ring around the model frame
    local modelBorder = hdr:CreateTexture(nil, "OVERLAY")
    modelBorder:SetSize(56, 56)
    modelBorder:SetPoint("CENTER", hdr.model, "CENTER", 0, 0)
    modelBorder:SetColorTexture(0.0, 0.75, 0.70, 0)  -- invisible fill
    -- We draw the ring with a separate frame using backdrop
    local modelRing = CreateFrame("Frame", nil, hdr, "BackdropTemplate")
    modelRing:SetSize(56, 56)
    modelRing:SetPoint("CENTER", hdr.model, "CENTER", 0, 0)
    modelRing:SetBackdrop({
        bgFile   = nil,
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left=1, right=1, top=1, bottom=1 },
    })
    modelRing:SetBackdropBorderColor(0.0, 0.90, 0.80, 0.80)
    modelRing:SetFrameLevel(hdr:GetFrameLevel() + 5)

    -- Name
    local textAnchor = hdr.model
    hdr.nameTxt = hdr:CreateFontString(nil, "OVERLAY")
    hdr.nameTxt:SetFont("Fonts\\2002.ttf", 12, "")
    hdr.nameTxt:SetTextColor(0.85, 0.85, 0.85, 1)
    hdr.nameTxt:SetPoint("TOPLEFT", textAnchor, "TOPRIGHT", 8, -4)
    hdr.nameTxt:SetText(CO.teal .. "Valeera Sanguinar|r")

    -- Level / rep
    hdr.levelTxt = hdr:CreateFontString(nil, "OVERLAY")
    hdr.levelTxt:SetFont("Fonts\\2002.ttf", 10, "")
    hdr.levelTxt:SetTextColor(0.85, 0.85, 0.85, 1)
    hdr.levelTxt:SetPoint("TOPLEFT", textAnchor, "TOPRIGHT", 8, -18)
    hdr.levelTxt:SetText(CO.gray .. "Loading...")

    -- XP bar background
    local barBG = hdr:CreateTexture(nil, "BORDER")
    barBG:SetSize(CONT_W - 84, 10)
    barBG:SetPoint("BOTTOMLEFT", textAnchor, "BOTTOMRIGHT", 8, 8)
    barBG:SetColorTexture(0.04, 0.04, 0.10, 1)

    -- XP bar
    hdr.bar = CreateFrame("StatusBar", nil, hdr)
    hdr.bar:SetSize(CONT_W - 84, 10)
    hdr.bar:SetPoint("BOTTOMLEFT", textAnchor, "BOTTOMRIGHT", 8, 8)
    hdr.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hdr.bar:SetStatusBarColor(0.0, 0.90, 0.80)
    hdr.bar:SetMinMaxValues(0, 1); hdr.bar:SetValue(0)

    hdr.xpTxt = hdr.bar:CreateFontString(nil, "OVERLAY")
hdr.xpTxt:SetFont("Fonts\\2002.ttf",10,"")
hdr.xpTxt:SetTextColor(0.85,0.85,0.85,1)
    hdr.xpTxt:SetPoint("CENTER", hdr.bar, "CENTER", 0, 0)
    hdr.xpTxt:SetText("")

    -- Header tooltip (hover Valeera for rep detail)
    hdr:EnableMouse(true)
    hdr:SetScript("OnEnter", function(self)
        local rank, rep = ValeeraData()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(CO.teal .. "Valeera Sanguinar|r")
        GameTooltip:AddLine(CO.gray .. "Warband Reputation|r")
        if rank and rep then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(
                CO.white .. "Level:|r",
                string.format(CO.teal .. "%d / %d|r", rank.currentLevel or 0, rank.maxLevel or 60),
                1, 1, 1, 1, 1, 1)
            if rep.nextThreshold then
                local c = (rep.standing or 0) - (rep.reactionThreshold or 0)
                local n = (rep.nextThreshold or 1) - (rep.reactionThreshold or 0)
                GameTooltip:AddDoubleLine(
                    CO.white .. "XP:|r",
                    string.format(CO.teal .. "%d / %d|r", c, n),
                    1, 1, 1, 1, 1, 1)
            else
                GameTooltip:AddLine(CO.gold .. "MAX level reached!|r")
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(CO.orange .. "Tip: Bountiful Delves give bonus Valeera XP!|r")
        GameTooltip:Show()
    end)
    hdr:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ================================================
    -- 2. THREE TABS (bottom of container)
    -- ================================================
    local tabW = math.floor((CONT_W - 2) / 3)

    local function MakeTabBtn(label, offsetX)
        local tb = CreateFrame("Button", nil, container, "BackdropTemplate")
        tb:SetSize(tabW, TAB_H)
        tb:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 1 + offsetX, 2)
        tb:SetBackdrop(BD(1))
        local lbl = tb:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\2002.ttf", 12, "")
        lbl:SetTextColor(0.85, 0.85, 0.85, 1)
        lbl:SetPoint("CENTER", tb, "CENTER", 0, 0)
        lbl:SetText(label)
        tb.lbl = lbl
        -- Top glow bar (hidden by default)
        tb.glowBar = tb:CreateTexture(nil, "OVERLAY", nil, 2)
        tb.glowBar:SetHeight(1)
        tb.glowBar:SetPoint("TOPLEFT",  1, -1)
        tb.glowBar:SetPoint("TOPRIGHT", -1, -1)
        tb.glowBar:SetAlpha(0)
        return tb
    end

    local tabNem  = MakeTabBtn(CO.magenta .. "Nemesis|r",   0)
    local tabBoun = MakeTabBtn("|cffccaa00" .. "Bountiful|r", tabW)
    local tabNorm = MakeTabBtn(CO.blue    .. "Normal|r",    tabW * 2)

    tabNem.glowBar:SetColorTexture(1.0, 0.30, 1.0, 1)
    tabBoun.glowBar:SetColorTexture(0.80, 0.67, 0.0, 1)  -- T06: gold ipv oranje
    tabNorm.glowBar:SetColorTexture(0.30, 0.70, 1.0, 1)

    -- ================================================
    -- 3. THREE SCROLL AREAS
    --    SF_RIGHT = 20: scroll frame right edge is 20px
    --    from container right, so the 16px scrollbar
    --    (offset 4px) lands at container right - 0px.
    --    Tabs N and B: scrollbar hidden entirely.
    --    Tab Nr: scrollbar visible and inside frame.
    -- ================================================
    local function MakeScrollArea()
        local sf = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     hdr,       "BOTTOMLEFT",  0,             -2)
        sf:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -SF_RIGHT,  TAB_H + 4)
        local sc = CreateFrame("Frame", nil, sf)
        sc:SetWidth(SCROLL_W)
        sc:SetHeight(1)
        sf:SetScrollChild(sc)
        return sf, sc
    end

    local sfN,  scN  = MakeScrollArea()   -- Nemesis
    local sfB,  scB  = MakeScrollArea()   -- Bountiful
    local sfNr, scNr = MakeScrollArea()   -- Normal (scrollbar stays)

    -- Hide scrollbar on tabs N and B (content rarely needs it,
    -- and it looks cleaner without the visible bar)
    if sfN.ScrollBar  then sfN.ScrollBar:Hide()  end
    if sfB.ScrollBar  then sfB.ScrollBar:Hide()  end
    sfN:EnableMouseWheel(false)
    sfB:EnableMouseWheel(false)

    -- ================================================
    -- 4. TAB ACTIVATION
    -- ================================================
    local activeTab = 1

    local function ActivateTab(n)
        activeTab = n
        sfN:SetShown(n == 1); sfB:SetShown(n == 2); sfNr:SetShown(n == 3)

        -- Reset all tabs to inactive
        tabNem:SetBackdropColor(0.04, 0.01, 0.07, 1)
        tabNem:SetBackdropBorderColor(0.35, 0.10, 0.35, 1)
        tabNem.glowBar:SetAlpha(0)
        tabBoun:SetBackdropColor(0.06, 0.03, 0.09, 1)  -- T06: neutral dark
        tabBoun:SetBackdropBorderColor(0.25, 0.18, 0.30, 1)  -- subtle border
        tabBoun.glowBar:SetAlpha(0)
        tabNorm:SetBackdropColor(0.02, 0.04, 0.10, 1)
        tabNorm:SetBackdropBorderColor(0.10, 0.20, 0.35, 1)
        tabNorm.glowBar:SetAlpha(0)

        -- Highlight active tab
        if n == 1 then
            tabNem:SetBackdropColor(0.12, 0.02, 0.18, 1)
            tabNem:SetBackdropBorderColor(1.0, 0.20, 0.90, 1)
            tabNem.glowBar:SetAlpha(1)
        elseif n == 2 then
            tabBoun:SetBackdropColor(0.10, 0.06, 0.14, 1)  -- T06: purple tint
            tabBoun:SetBackdropBorderColor(0.65, 0.45, 0.00, 1)  -- gold border
            tabBoun.glowBar:SetAlpha(1)
        else
            tabNorm:SetBackdropColor(0.03, 0.07, 0.18, 1)
            tabNorm:SetBackdropBorderColor(0.20, 0.55, 1.0, 1)
            tabNorm.glowBar:SetAlpha(1)
        end
    end

    tabNem:SetScript("OnClick",  function() ActivateTab(1) end)
    tabBoun:SetScript("OnClick", function() ActivateTab(2) end)
    tabNorm:SetScript("OnClick", function() ActivateTab(3) end)

    -- Inactive tab hover: glow border + glow bar, no background tint
    local function AddTabHover(tb, idx)
        tb:SetScript("OnEnter", function(self)
            if activeTab ~= idx then
                local gr, gg, gb = self.glowBar:GetVertexColor()
                self:SetBackdropBorderColor(gr, gg, gb, 0.80)
                self.glowBar:SetAlpha(0.60)
            end
        end)
        tb:SetScript("OnLeave", function() ActivateTab(activeTab) end)
    end
    AddTabHover(tabNem,  1)
    AddTabHover(tabBoun, 2)
    AddTabHover(tabNorm, 3)

    -- ================================================
    -- 5. TILE POOLS
    -- ================================================
    local poolN, poolB, poolNr = {}, {}, {}

    local function GetTile(pool, parent, idx)
        if not pool[idx] then
            pool[idx] = NewTile(parent, idx)
        else
            -- 2-naast-2 layout
        local col2 = (idx - 1) % 2
        local row2 = math.floor((idx - 1) / 2)
        local tileW2 = math.floor((SCROLL_W - TILE_G) / 2)
        local tileH2 = math.floor(TILE_H * 1.4)
        -- T04d: gecentreerd
        local totalW2 = 2 * tileW2 + TILE_G
        local xPad2 = math.max(0, math.floor((SCROLL_W - totalW2) / 2))
        pool[idx]:SetPoint("TOPLEFT", xPad2 + col2 * (tileW2 + TILE_G), -(row2 * (tileH2 + TILE_G)))
            pool[idx]:SetSize(tileW2, tileH2)
        end
        return pool[idx]
    end

    -- ================================================
    -- 6. ITEM BOXES (Nemesis tab - Required Items)
    --
    --   Layout per box  (~ ITEM_W x ITEM_H px):
    --   +-------------------------------┐
    --   |▌  [ICON 40x40]  Item Name    |
    --   |▌       +--┐                  |
    --   |▌       │x2│ <- badge on icon  |
    --   |▌       +--┘                  |
    --   +-------------------------------┘
    --
    --   Count badge: outlined white text with dark bg,
    --   positioned bottom-right corner of the icon.
    --   "in bags" label removed entirely.
    -- ================================================
    local itemBoxes = {}

    local function MakeItemBox(parent, item, idx)
        local xOffset = (idx - 1) * (ITEM_W + ITEM_GAP)

        local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
        box:SetSize(ITEM_W, ITEM_H)
        box:SetBackdrop(BD(1))
        box:SetBackdropColor(0.05, 0.00, 0.10, 0.97)
        box:SetBackdropBorderColor(0.55, 0.10, 0.70, 0.80)

        -- Left magenta stripe
        box.stripe = box:CreateTexture(nil, "ARTWORK")
        box.stripe:SetSize(3, ITEM_H - 2)
        box.stripe:SetPoint("LEFT", 1, 0)
        box.stripe:SetColorTexture(0.90, 0.15, 0.90, 1)

        -- Top glow (hover)
        box.glowBar = box:CreateTexture(nil, "OVERLAY", nil, 2)
        box.glowBar:SetHeight(2)
        box.glowBar:SetPoint("TOPLEFT",  1, -1)
        box.glowBar:SetPoint("TOPRIGHT", -1, -1)
        box.glowBar:SetColorTexture(1.0, 0.35, 1.0, 1)
        box.glowBar:SetAlpha(0)

        -- Left glow (hover)
        box.glowLeft = box:CreateTexture(nil, "OVERLAY", nil, 2)
        box.glowLeft:SetWidth(3)
        box.glowLeft:SetPoint("TOPLEFT",    1, -1)
        box.glowLeft:SetPoint("BOTTOMLEFT", 1,  1)
        box.glowLeft:SetColorTexture(1.0, 0.35, 1.0, 1)
        box.glowLeft:SetAlpha(0)

        -- Icon: centered vertically, left-aligned after stripe
        box.icon = box:CreateTexture(nil, "ARTWORK")
        box.icon:SetSize(40, 40)
        box.icon:SetPoint("LEFT", 7, 0)
        box.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

        -- Count badge background (dark pill on icon bottom-right corner)
        box.countBg = box:CreateTexture(nil, "OVERLAY", nil, 1)
        box.countBg:SetSize(26, 15)
        box.countBg:SetPoint("BOTTOMRIGHT", box.icon, "BOTTOMRIGHT", 4, -2)
        box.countBg:SetColorTexture(0, 0, 0, 0.80)

        -- Count text: outlined, sits on top of the icon corner badge
        box.countTxt = box:CreateFontString(nil, "OVERLAY", nil, 2)
        box.countTxt:SetFont("Fonts\\2002.ttf", 12, "OUTLINE")
        box.countTxt:SetPoint("CENTER", box.countBg, "CENTER", 0, 0)
        box.countTxt:SetJustifyH("CENTER")
        box.countTxt:SetText("|cffffffff?|r")

        -- Item name: right of icon, up to 2 lines
        box.nameTxt = box:CreateFontString(nil, "OVERLAY")
        box.nameTxt:SetPoint("TOPLEFT",  box.icon, "TOPRIGHT",  5, -3)
        box.nameTxt:SetPoint("TOPRIGHT", box,      "TOPRIGHT", -4, -3)
        box.nameTxt:SetJustifyH("LEFT")
        box.nameTxt:SetWordWrap(true)
        box.nameTxt:SetMaxLines(2)
        box.nameTxt:SetText(CO.gray .. item.shortName .. "|r")

        -- Hover: glow + item tooltip (no background tint)
        box:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1.0, 0.50, 1.0, 1.0)
            self.glowBar:SetAlpha(0.90)
            self.glowLeft:SetAlpha(0.65)
            local _, itemLink = GetItemInfo(item.id)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if itemLink then
                GameTooltip:SetHyperlink(itemLink)
            else
                GameTooltip:ClearLines()
                GameTooltip:AddLine(CO.gray .. item.shortName)
                GameTooltip:AddLine(CO.gray .. "ID: " .. item.id)
            end
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.55, 0.10, 0.70, 0.80)
            self.glowBar:SetAlpha(0)
            self.glowLeft:SetAlpha(0)
            GameTooltip:Hide()
        end)

        box.xOffset    = xOffset
        itemBoxes[idx] = box
        return box
    end

    -- ================================================
    -- 7. VALEERA REFRESH
    -- ================================================
    local function RefreshValeera()
        local rank, rep = ValeeraData()
        if rank and rep then
            local cur, max = rank.currentLevel or 0, rank.maxLevel or 60
            hdr.levelTxt:SetText(string.format(CO.white .. "Level %d / %d|r", cur, max))
            if cur < max and rep.nextThreshold then
                local c = (rep.standing or 0) - (rep.reactionThreshold or 0)
                local n = (rep.nextThreshold or 1) - (rep.reactionThreshold or 0)
                if n > 0 then
                    hdr.bar:SetMinMaxValues(0, n)
                    hdr.bar:SetValue(math.max(0, c))
                    hdr.xpTxt:SetText(c .. " / " .. n)
                    hdr.bar:SetStatusBarColor(0.0, 0.90, 0.80)
                else
                    hdr.bar:SetMinMaxValues(0, 1); hdr.bar:SetValue(1)
                    hdr.xpTxt:SetText(CO.gold .. "MAX")
                    hdr.bar:SetStatusBarColor(1.0, 0.55, 0.0)
                end
            else
                hdr.bar:SetMinMaxValues(0, 1); hdr.bar:SetValue(1)
                hdr.xpTxt:SetText(CO.gold .. "MAX")
                hdr.bar:SetStatusBarColor(1.0, 0.55, 0.0)
            end
        else
            hdr.levelTxt:SetText(CO.gray .. "Not available")
            hdr.bar:SetMinMaxValues(0, 1); hdr.bar:SetValue(0)
            hdr.xpTxt:SetText("")
        end
    end

    -- ================================================
    -- 8. DELVES REFRESH
    -- ================================================
    local function RefreshDelves()
        local bountiful, normal, nemesis = {}, {}, {}
        for _, d in ipairs(DELVES) do
            if d.bountiful == nil then
                table.insert(nemesis, d)
            elseif IsBountiful(d) then
                table.insert(bountiful, d)
            else
                table.insert(normal, d)
            end
        end
        table.sort(bountiful, function(a, b) return a.name < b.name end)
        table.sort(normal,    function(a, b) return a.name < b.name end)

        local bc = #bountiful
        tabBoun.lbl:SetText(bc > 0
            and ("|cff00ccff" .. "Bountiful (" .. bc .. ")|r")
            or  (CO.gray   .. "Bountiful|r"))
        tabNorm.lbl:SetText(CO.blue .. "Normal (" .. #normal .. ")|r")

        for _, p in ipairs(poolN)    do p:Hide() end
        for _, p in ipairs(poolB)    do p:Hide() end
        for _, p in ipairs(poolNr)   do p:Hide() end
        for _, b in ipairs(itemBoxes) do b:Hide() end

        -- -- TAB 1: NEMESIS -----------------------------
        local iN = 0
        for _, d in ipairs(nemesis) do
            iN = iN + 1
            local t = GetTile(poolN, scN, iN)
            StyleTile(t, d, false, true)
            t.nameTxt:SetText(CO.magenta .. d.name)
            FillStory(t, d)
            SetTooltip(t, d, false, true)
            t:Show()
        end

        -- S3-03: Required Items header VERWIJDERD (niet correct)
        -- Items direct onder tiles, gecentreerd
        local ITEMS_Y = iN * (TILE_H + TILE_G) + 8

        -- Verberg itemHeaderFrame als die al bestaat van vorige versie
        if scN.itemHeaderFrame then scN.itemHeaderFrame:Hide() end

        -- Item boxes (3 side by side)
        for i, item in ipairs(SPECIAL_ITEMS) do
            if not itemBoxes[i] then MakeItemBox(scN, item, i) end
            local box = itemBoxes[i]
            box:SetParent(scN)
            -- S3-03: gecentreerd - berekend vanuit SCROLL_W
            local totalItemW = 3 * ITEM_W + 2 * ITEM_GAP
            local itemPad = math.max(0, math.floor((SCROLL_W - totalItemW) / 2))
            box:SetPoint("TOPLEFT", itemPad + box.xOffset, -ITEMS_Y)
            box:Show()

            local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(item.id)
            if name then
                box.icon:SetTexture(texture)
                box.nameTxt:SetText(CO.silver .. name .. "|r")
                local owned = GetItemCount(item.id, true)
                -- Count badge: teal if owned, red if zero
                local countCol = owned > 0 and "|cff00eedd" or "|cffff5555"
                box.countTxt:SetText(countCol .. "x" .. owned .. "|r")
            else
                box.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                box.nameTxt:SetText(CO.gray .. item.shortName .. "|r")
                box.countTxt:SetText("|cff99aabb?|r")
                -- Retry after item cache is populated
                C_Timer.After(1.5, function()
                    if box:IsVisible() then
                        local n2, _, _, _, _, _, _, _, _, tex2 = GetItemInfo(item.id)
                        if n2 then
                            box.icon:SetTexture(tex2)
                            box.nameTxt:SetText(CO.silver .. n2 .. "|r")
                            local owned2 = GetItemCount(item.id, true)
                            local c2 = owned2 > 0 and "|cff00eedd" or "|cffff5555"
                            box.countTxt:SetText(c2 .. "x" .. owned2 .. "|r")
                        end
                    end
                end)
            end
        end

        -- -- S3-04: BOSS TACTICS KNOP --------------------------------
        local BOSS_Y = ITEMS_Y + ITEM_H + 8

        if not scN.bossTacticsBtn then
            local bossBtn = CreateFrame("Button",nil,scN,"BackdropTemplate")
            bossBtn:SetSize(SCROLL_W, 28)
            bossBtn:SetBackdrop(BD(1))
            bossBtn:SetBackdropColor(0.08,0.00,0.14,0.97)
            bossBtn:SetBackdropBorderColor(0.65,0.10,0.85,0.9)

            -- Magenta stripe links
            local bs = bossBtn:CreateTexture(nil,"ARTWORK")
            bs:SetSize(4,26); bs:SetPoint("LEFT",1,0)
            bs:SetColorTexture(1.0,0.20,0.90,1)

            -- Top glow
            local bg = bossBtn:CreateTexture(nil,"OVERLAY",nil,2)
            bg:SetHeight(1); bg:SetPoint("TOPLEFT",1,-1); bg:SetPoint("TOPRIGHT",-1,-1)
            bg:SetColorTexture(1.0,0.30,1.0,0.8); bg:SetAlpha(0)

            local btxt = bossBtn:CreateFontString(nil,"OVERLAY")
            btxt:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
            btxt:SetPoint("LEFT",12,0)
            btxt:SetText(CO.magenta.."Boss Tactics: Nullaeus|r  "..CO.gray.."(klik voor strat)|r")

            local barrow = bossBtn:CreateFontString(nil,"OVERLAY")
            barrow:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
            barrow:SetPoint("RIGHT",-8,0)
            barrow:SetText(CO.gray.."[+]|r")

            bossBtn:SetScript("OnEnter",function(s)
                bg:SetAlpha(1)
                s:SetBackdropBorderColor(1.0,0.40,1.0,1)
            end)
            bossBtn:SetScript("OnLeave",function(s)
                bg:SetAlpha(0)
                s:SetBackdropBorderColor(0.65,0.10,0.85,0.9)
            end)

            -- Boss Tactics Toast popup - persistent upvalue (niet lokaal in closure)
            -- scN.bossToast zodat het overleeft tussen RefreshDelves calls
            local function BuildBossToast()
                if scN.bossToast then return scN.bossToast end
                local bt = CreateFrame("Frame","DT_BossTacticsToast",UIParent,"BackdropTemplate")
                bt:SetSize(520,340)
                bt:SetPoint("CENTER",UIParent,"CENTER",0,50)
                bt:SetFrameStrata("DIALOG")
                bt:SetMovable(true); bt:EnableMouse(true)
                bt:RegisterForDrag("LeftButton")
                bt:SetClampedToScreen(true)
                bt:SetScript("OnDragStart",bt.StartMoving)
                bt:SetScript("OnDragStop",bt.StopMovingOrSizing)
                bt:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
                bt:SetBackdropColor(0.04,0.01,0.08,0.98)
                bt:SetBackdropBorderColor(0.65,0.10,0.85,1)
                bt:Hide()

                -- Header
                local bh = bt:CreateFontString(nil,"OVERLAY")
                bh:SetFont("Fonts\\2002.ttf",13,"OUTLINE")
                bh:SetPoint("TOPLEFT",10,-10)
                bh:SetText(CO.magenta.."NULLAEUS - Torment's Rise (Nemesis Delve)|r")

                -- Sluit
                local xb = CreateFrame("Button",nil,bt,"UIPanelCloseButton")
                xb:SetSize(22,22); xb:SetPoint("TOPRIGHT",0,0)
                xb:SetScript("OnClick",function() bt:Hide() end)

                -- Scheidingslijn
                local bl = bt:CreateTexture(nil,"OVERLAY")
                bl:SetHeight(1); bl:SetPoint("TOPLEFT",8,-28); bl:SetPoint("TOPRIGHT",-8,-28)
                bl:SetColorTexture(0.50,0.08,0.70,0.8)

                -- Tab knoppen T8 / T11
                local tabT8 = CreateFrame("Button",nil,bt,"BackdropTemplate")
                tabT8:SetSize(80,20); tabT8:SetPoint("TOPLEFT",10,-34)
                tabT8:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})

                local tabT11 = CreateFrame("Button",nil,bt,"BackdropTemplate")
                tabT11:SetSize(80,20); tabT11:SetPoint("LEFT",tabT8,"RIGHT",4,0)
                tabT11:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})

                local t8lbl = tabT8:CreateFontString(nil,"OVERLAY"); t8lbl:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); t8lbl:SetPoint("CENTER"); t8lbl:SetText("Tier 8 (?)")
                local t11lbl = tabT11:CreateFontString(nil,"OVERLAY"); t11lbl:SetFont("Fonts\\2002.ttf",10,"OUTLINE"); t11lbl:SetPoint("CENTER"); t11lbl:SetText("Tier 11 (??)")

                -- Strat tekst scroll
                local sf = CreateFrame("ScrollFrame",nil,bt,"UIPanelScrollFrameTemplate")
                sf:SetPoint("TOPLEFT",8,-60); sf:SetPoint("BOTTOMRIGHT",-28,-8)
                local sc = CreateFrame("Frame",nil,sf)
                sc:SetWidth(480); sf:SetScrollChild(sc)

                local txt = sc:CreateFontString(nil,"OVERLAY")
                txt:SetFont("Fonts\\2002.ttf",11,"")
                txt:SetPoint("TOPLEFT",4,-4)
                txt:SetWidth(476)
                txt:SetJustifyH("LEFT")
                txt:SetWordWrap(true)

                local STRAT_T8 =
                    "|cffff88ccNULLAEUS - TIER 8 STRAT|r" ..
                    "\n\n|cffccaa00VALEERA ROL:|r Healer (dispelt DoT + Ravager bleeds)" ..
                    "\n\n|cffff4444KRITIEK:|r |cffffffff[Emptiness of the Void]|r - ALTIJD interruppen!" ..
                    "\nAoE one-shot als het doorgaat. Bouw je interrupt rotation hier omheen." ..
                    "\n\n|cffbf00ffFASE 1 (100-75%):|r" ..
                    "\n- Interrupt Emptiness of the Void (letale AoE)" ..
                    "\n- Dispel/vermijd Devouring Essence DoT (shadow, 18 sec)" ..
                    "\n- Valeera Healer dispelt automatisch" ..
                    "\n\n|cffbf00ffINTERMISSION 75%:|r (~30 sec)" ..
                    "\n- Nullaeus untargetable, kanalized Void Orb" ..
                    "\n- Kill 2x Razorshell Ravager snel!" ..
                    "\n- Spiny Leap = cirkel op verste speler - ga DICHTERBIJ staan" ..
                    "\n- Spiny Thorns = bleed DoT, Valeera Healer cleant dit" ..
                    "\n\n|cffbf00ffFASE 2 (75-50%):|r" ..
                    "\n- Zelfde als Fase 1 + Void Zone (1/3 kamer) - roteer weg" ..
                    "\n- Interrupt prio boven alles" ..
                    "\n\n|cffbf00ffINTERMISSION 50%:|r" ..
                    "\n- AoE + CC 7x Spitting Ticks DIRECT" ..
                    "\n- Beweeg weg van Black Hole (trekt je in van alles)" ..
                    "\n\n|cffbf00ffFASE 3 (50-0%):|r" ..
                    "\n- Boss + Void Zone + Black Hole tegelijk" ..
                    "\n- Interrupt blijft #1 prio, roteer constant" ..
                    "\n- Cooldowns nu gebruiken - niet sparen"

                local STRAT_T11 =
                    "|cffff88ccNULLAEUS - TIER 11 STRAT (??)|r" ..
                    "\n\n|cffccaa00VEREIST:|r Tier 10 gecleared met 1+ leven over" ..
                    "\n|cffccaa00SOLO KILL:|r = |cffccaa00Arcanovoid Construct mount|r" ..
                    "\n\n|cffffffff[Let Me Solo Him: Nullaeus]|r vereist solo T11 kill." ..
                    "\n\n|cffff4444KRITIEK (zwaarder dan T8):|r" ..
                    "\n- Emptiness of the Void = instant wipe als gemist" ..
                    "\n- Alle mechanics sneller/harder dan T8" ..
                    "\n- Razorshell Ravagers doen meer schade" ..
                    "\n\n|cffbf00ffSTRATEGIE:|r Zelfde fasestructuur als T8, maar:" ..
                    "\n- Interrupt CD management = kritiek (gebruik alt interrupts)" ..
                    "\n- Black Hole + Void Zone overlap = meest dodelijk moment" ..
                    "\n- Als Healer: Valeera DPS voor interrupt hulp" ..
                    "\n- Als DPS/Tank: Valeera Healer (dispelt DoT + bleeds)" ..
                    "\n\n|cff44ff88iLvl aanbevolen:|r 274+" ..
                    "\n|cff44ff88Valeera T11:|r DPS als healer/lange CD, anders Healer"

                local currentTier = "T8"
                local function ShowTier(tier)
                    currentTier = tier
                    txt:SetText(tier == "T8" and STRAT_T8 or STRAT_T11)
                    sc:SetHeight(txt:GetStringHeight() + 20)
                    sf:SetVerticalScroll(0)
                    tabT8:SetBackdropColor(tier=="T8" and 0.12 or 0.04, tier=="T8" and 0.02 or 0.01, tier=="T8" and 0.20 or 0.07, 1)
                    tabT8:SetBackdropBorderColor(tier=="T8" and 0.65 or 0.20, 0.05, tier=="T8" and 0.90 or 0.30, 1)
                    tabT11:SetBackdropColor(tier=="T11" and 0.12 or 0.04, tier=="T11" and 0.02 or 0.01, tier=="T11" and 0.20 or 0.07, 1)
                    tabT11:SetBackdropBorderColor(tier=="T11" and 0.65 or 0.20, 0.05, tier=="T11" and 0.90 or 0.30, 1)
                end

                tabT8:SetScript("OnClick",function() ShowTier("T8") end)
                tabT11:SetScript("OnClick",function() ShowTier("T11") end)
                bt:SetScript("OnShow",function() ShowTier(currentTier) end)

                scN.bossToast = bt
                return bt
            end

            bossBtn:SetScript("OnClick",function()
                local toast = BuildBossToast()
                if toast:IsShown() then toast:Hide()
                else toast:Show() end
            end)

            scN.bossTacticsBtn = bossBtn
        end
        scN.bossTacticsBtn:SetPoint("TOPLEFT",0,-BOSS_Y)
        scN.bossTacticsBtn:Show()

        -- -- ABUNDANCE BLOK onder Boss Tactics ----------------------------
        local AB_Y = BOSS_Y + 28 + 8
        if not scN.abundanceFrame then
            -- S3-07: compact abundance blok (52px)
            local abf = CreateFrame("Frame", nil, scN, "BackdropTemplate")
            abf:SetSize(SCROLL_W, 52)
            abf:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
            abf:SetBackdropColor(0.03, 0.07, 0.03, 0.96)
            abf:SetBackdropBorderColor(0.20, 0.55, 0.20, 0.85)
            -- Groene stripe links
            local abStripe = abf:CreateTexture(nil,"ARTWORK")
            abStripe:SetSize(4,50); abStripe:SetPoint("LEFT",1,0)
            abStripe:SetColorTexture(0.10,0.80,0.10,1)
            -- Rij 1: cave naam links, timer rechts
            abf.title = abf:CreateFontString(nil,"OVERLAY")
            abf.title:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
            abf.title:SetPoint("TOPLEFT",10,-7)
            abf.title:SetText("|cff44cc66* Abundance|r")
            abf.timer = abf:CreateFontString(nil,"OVERLAY")
            abf.timer:SetFont("Fonts\\2002.ttf",11,"OUTLINE")
            abf.timer:SetPoint("TOPRIGHT",-8,-7)
            abf.timer:SetText("")
            -- Rij 2: shards links (prominent), info rechts
            abf.shards = abf:CreateFontString(nil,"OVERLAY")
            abf.shards:SetFont("Fonts\\2002.ttf",10,"")
            abf.shards:SetPoint("BOTTOMLEFT",10,7)
            abf.shards:SetText("")
            abf.info = abf:CreateFontString(nil,"OVERLAY")
            abf.info:SetFont("Fonts\\2002.ttf",10,"")
            abf.info:SetPoint("BOTTOMRIGHT",-8,7)
            abf.info:SetJustifyH("RIGHT")
            abf.info:SetWidth(SCROLL_W * 0.65)
            abf.info:SetText("|cff887799Laden...|r")
            scN.abundanceFrame = abf
        end
        scN.abundanceFrame:SetPoint("TOPLEFT",0,-AB_Y)
        -- Vul abundance data
        local abData = DT_GetAbundanceData and DT_GetAbundanceData()
        if abData and abData.active then
            scN.abundanceFrame:SetBackdropBorderColor(0.20,0.85,0.20,1)
            local ABCAVE_NAMES = {
                [2393]="Watha'nan Crypts", [2395]="Watha'nan Crypts",
                [2437]="Loaknit Den", [2413]="Floaret Grotto",
                [2405]="Abundant Voidburrow",
            }
            local ABCAVE_ZONES = {
                [2393]="Eversong", [2395]="Eversong",
                [2437]="Zul'Aman", [2413]="Harandar", [2405]="Voidstorm",
            }
            local caveName = (abData.mapID and ABCAVE_NAMES[abData.mapID]) or abData.zone or "?"
            local zoneShort = (abData.mapID and ABCAVE_ZONES[abData.mapID]) or ""
            -- Rij 1: cave naam + zone (links), timer (rechts)
            scN.abundanceFrame.title:SetText("|cff44cc66* |r|cffffffff"..caveName.."|r  |cff887799"..zoneShort.."|r")
            local timeStr = ""
            if abData.secondsLeft and abData.secondsLeft > 0 then
                local h=math.floor(abData.secondsLeft/3600)
                local m=math.floor((abData.secondsLeft%3600)/60)
                timeStr = h>0 and string.format("|cff44cc66%dh %dm|r",h,m) or string.format("|cff44cc66%dm|r",m)
            end
            scN.abundanceFrame.timer:SetText(timeStr)
            -- Rij 2: shards prominent links, status rechts
            local shards = abData.shards or 0
            local dundunCol = shards > 0 and "|cff44cc66" or "|cffff5555"
            scN.abundanceFrame.shards:SetText("|cff887799Dundun: |r"..dundunCol..shards.." shards|r")
            scN.abundanceFrame.info:SetText("|cff887799Harvest actief . roteert elke 8u|r")
        else
            scN.abundanceFrame:SetBackdropBorderColor(0.15,0.30,0.15,0.6)
            scN.abundanceFrame.title:SetText("|cff556655* Abundance|r  |cff334433geen actieve harvest|r")
            scN.abundanceFrame.timer:SetText("")
            scN.abundanceFrame.shards:SetText("")
            scN.abundanceFrame.info:SetText("|cff445544Eversong . Zul'Aman . Harandar . Voidstorm|r")
        end
        scN.abundanceFrame:Show()

        scN:SetHeight(math.max(AB_Y + 62, 10))  -- S3-07: compacter blok

        -- -- TAB 2: BOUNTIFUL ---------------------------
        local iB = 0
        if bc == 0 then
            iB = 1
            local t = GetTile(poolB, scB, 1)
            t.artBg:SetColorTexture(0, 0, 0, 0)
            t:SetBackdropColor(0.03, 0.05, 0.12, 0.94)
            t:SetBackdropBorderColor(0.20, 0.50, 0.90, 0.5)
            t.stripe:SetColorTexture(0.20, 0.55, 1.0, 0.5)
            t.badge:SetColorTexture(0, 0, 0, 0)
            t.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            t.iconRim:SetColorTexture(1, 1, 1, 0)
            t.glowBar:SetAlpha(0); t.glowLeft:SetAlpha(0)
            t.nameTxt:SetText(CO.gray .. "No Bountiful Delves active")
            t.storyTxt:SetText(CO.gray .. "Check back later")
            t.typeTxt:SetText(""); t.badgeTxt:SetText("")
            t:SetScript("OnEnter", nil); t:SetScript("OnLeave", nil); t:SetScript("OnClick", nil)
            t:Show()
        else
            for _, d in ipairs(bountiful) do
                iB = iB + 1
                local t = GetTile(poolB, scB, iB)
                StyleTile(t, d, true, false)
                t.nameTxt:SetText(CO.orange .. d.name)
                FillStory(t, d)
                SetTooltip(t, d, true, false)
                t:Show()
            end
        end
        scB:SetHeight(math.max(iB * (TILE_H + TILE_G) - TILE_G, 10))

        -- -- TAB 3: NORMAL (scrollbar visible) ----------
        local iNr = 0
        for _, d in ipairs(normal) do
            iNr = iNr + 1
            local t = GetTile(poolNr, scNr, iNr)
            StyleTile(t, d, false, false)
            t.nameTxt:SetText(CO.blue .. d.name)
            FillStory(t, d)
            SetTooltip(t, d, false, false)
            t:Show()
        end
        if iNr == 0 then
            iNr = 1
            local t = GetTile(poolNr, scNr, 1)
            t.artBg:SetColorTexture(0, 0, 0, 0)
            t:SetBackdropColor(0.03, 0.05, 0.12, 0.94)
            t:SetBackdropBorderColor(0.20, 0.50, 0.90, 0.5)
            t.stripe:SetColorTexture(0, 0, 0, 0)
            t.badge:SetColorTexture(0, 0, 0, 0)
            t.icon:SetTexture(nil); t.iconRim:SetColorTexture(1, 1, 1, 0)
            t.glowBar:SetAlpha(0); t.glowLeft:SetAlpha(0)
            t.nameTxt:SetText(CO.gray .. "All Delves are Bountiful!")
            t.storyTxt:SetText(""); t.typeTxt:SetText(""); t.badgeTxt:SetText("")
            t:SetScript("OnEnter", nil); t:SetScript("OnLeave", nil); t:SetScript("OnClick", nil)
            t:Show()
        end
        scNr:SetHeight(math.max(iNr * (TILE_H + TILE_G) - TILE_G, 10))
    end

    local function RefreshAll()
        RefreshValeera()
        RefreshDelves()
    end

    -- ================================================
    -- 9. TIMER (every 5 seconds while visible)
    -- ================================================
    local function StartTimer()
        if container._dtTicker then return end
        container._dtTicker = C_Timer.NewTicker(5, RefreshAll)
    end
    local function StopTimer()
        if container._dtTicker then
            container._dtTicker:Cancel()
            container._dtTicker = nil
        end
    end

    container:SetScript("OnShow", function() RefreshAll(); StartTimer() end)
    container:SetScript("OnHide", function() StopTimer() end)

    ActivateTab(1)
    C_Timer.After(0.3, RefreshAll)
    StartTimer()
end

DelveTracker:RegisterPlugin("QuickSet", function(mode, container)
    if mode == "Tab3" and container then BuildGrid(container) end
end)