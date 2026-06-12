-- ============================================================================
-- WowTracker Plugin: Mail Attach v1.0
-- Retail 12.0.5 / Build 67314 (Midnight)
-- Integreert Quick Attach panel bij het openen van de mailbox
-- Categorieen: Cloth · Leather · Metal · Herb · Enchanting · Inscription
--              Jewelcrafting · Cooking · Elemental · Optional · Parts · Other
-- ============================================================================
local addonName, addonTable = ...

if not DelveTracker then return end

local C_2002    = "Fonts\\2002.ttf"
local SA_GOLD   = "|cffccaa00"
local SA_PURPLE = "|cffa335ee"
local SA_GREY   = "|cff887799"

-- ── ITEM CATEGORIEEN ─────────────────────────────────────────────────────
local CATEGORIES = {
    {label="Cloth",        type=7,  subtype=2},
    {label="Leather",      type=7,  subtype=4},
    {label="Metal & St.",  type=7,  subtype=6},
    {label="Herb",         type=9,  subtype=0},
    {label="Enchanting",   type=12, subtype=0},
    {label="Inscription",  type=16, subtype=0},
    {label="Jewelcraft.",  type=7,  subtype=3},
    {label="Cooking",      type=15, subtype=0},
    {label="Elemental",    type=7,  subtype=5},
    {label="Optional",     type=7,  subtype=10},
    {label="Parts",        type=7,  subtype=1},
    {label="Other",        type=0,  subtype=nil},
}

-- Icoon per categorie (texture paden Midnight 12.x)
local CAT_ICONS = {
    ["Cloth"]       = "Interface\\Icons\\inv_fabric_linen_01",
    ["Leather"]     = "Interface\\Icons\\inv_misc_leatherscrap_02",
    ["Metal & St."] = "Interface\\Icons\\inv_ore_copper_01",
    ["Herb"]        = "Interface\\Icons\\inv_misc_herb_01",
    ["Enchanting"]  = "Interface\\Icons\\trade_engraving",
    ["Inscription"] = "Interface\\Icons\\inv_inscription_tarot",
    ["Jewelcraft."] = "Interface\\Icons\\inv_misc_gem_diamond_01",
    ["Cooking"]     = "Interface\\Icons\\inv_misc_food_15",
    ["Elemental"]   = "Interface\\Icons\\inv_misc_element_01",
    ["Optional"]    = "Interface\\Icons\\inv_misc_note_05",
    ["Parts"]       = "Interface\\Icons\\inv_gizmo_01",
    ["Other"]       = "Interface\\Icons\\inv_misc_bag_07",
}

-- ── MAIN FRAME ────────────────────────────────────────────────────────────
local QA = CreateFrame("Frame","DT_MailAttachFrame",UIParent,"BackdropTemplate")
QA:SetSize(220,420)
QA:SetPoint("LEFT",UIParent,"CENTER",-500,0)  -- naast mailbox
QA:SetMovable(true)
QA:EnableMouse(true)
QA:RegisterForDrag("LeftButton")
QA:SetClampedToScreen(true)
QA:SetFrameStrata("HIGH")
QA:SetToplevel(true)
QA:Hide()
QA:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Buttons\\WHITE8x8",
    edgeSize=1,
})
QA:SetBackdropColor(0.05,0.03,0.08,0.97)
QA:SetBackdropBorderColor(0.55,0.40,0.05,1)  -- goud border
    -- ── WTTHEME KOPPELING (Fase 3.2 ronde 2 · v3.2.8) ──
    if WTTheme and WTTheme.Register then
        local function _applyTheme()
            local bg  = WTTheme.bg and WTTheme.bg.main
            local bdr = WTTheme.border and WTTheme.border.main
            if bg then QA:SetBackdropColor(bg.r, bg.g, bg.b, math.max(bg.a or 0.97, 0.95)) end
            -- border blijft goud (functioneel kenmerk)
        end
        WTTheme.Register(_applyTheme)
        _applyTheme()
    end
QA:SetScript("OnDragStart",QA.StartMoving)
QA:SetScript("OnDragStop",QA.StopMovingOrSizing)

-- Header
local hdrBG = QA:CreateTexture(nil,"BACKGROUND")
hdrBG:SetHeight(32)
hdrBG:SetPoint("TOPLEFT",1,-1)
hdrBG:SetPoint("TOPRIGHT",-1,-1)
hdrBG:SetColorTexture(0.12,0.08,0.02,1)

local hdrIcon = QA:CreateTexture(nil,"OVERLAY")
hdrIcon:SetSize(20,20)
hdrIcon:SetPoint("TOPLEFT",6,-6)
hdrIcon:SetTexture("Interface\\Icons\\inv_letter_16")
hdrIcon:SetTexCoord(0.08,0.92,0.08,0.92)

local hdrTxt = QA:CreateFontString(nil,"OVERLAY")
hdrTxt:SetFont(C_2002,12,"OUTLINE")
hdrTxt:SetPoint("LEFT",hdrIcon,"RIGHT",6,0)
hdrTxt:SetText(SA_GOLD.."Quick Attach|r")

local closeBtn = CreateFrame("Button",nil,QA,"UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT",QA,"TOPRIGHT",2,-2)

-- ── CATEGORIE KNOPPEN (2 kolommen) ────────────────────────────────────────
local BTN_W = 96
local BTN_H = 26
local BTN_GAP = 4
local COLS = 2

QA.catBtns = {}
QA.activeCat = nil

local function ScanBagsForCategory(cat)
    local items = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local numSlots = C_Container and C_Container.GetContainerNumSlots(bag) or GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info
            if C_Container and C_Container.GetContainerItemInfo then
                info = C_Container.GetContainerItemInfo(bag,slot)
            end
            if info and info.itemID then
                local _, _, _, _, _, iType, iSubtype = GetItemInfo(info.itemID)
                local match = false
                if cat.subtype then
                    match = (iType == cat.type and iSubtype == cat.subtype)
                else
                    -- "Other": alles wat niet in andere cats past
                    match = true
                    for _,c2 in ipairs(CATEGORIES) do
                        if c2 ~= cat and c2.subtype and iType == c2.type and iSubtype == c2.subtype then
                            match = false; break
                        end
                    end
                end
                if match then
                    table.insert(items,{
                        bag=bag, slot=slot,
                        name=info.hyperlink or tostring(info.itemID),
                        count=info.stackCount or 1,
                        icon=info.iconFileID,
                        link=info.hyperlink,
                    })
                end
            end
        end
    end
    return items
end

-- Item lijst scroll
local itemScroll = CreateFrame("ScrollFrame",nil,QA,"UIPanelScrollFrameTemplate")
itemScroll:SetPoint("TOPLEFT",8,-36)
itemScroll:SetPoint("BOTTOMRIGHT",-22,-60)

local itemContent = CreateFrame("Frame",nil,itemScroll)
itemContent:SetWidth(190)
itemContent:SetHeight(1)
itemScroll:SetScrollChild(itemContent)
itemContent.rows = {}

local function ShowCategoryItems(cat)
    QA.activeCat = cat
    local items = ScanBagsForCategory(cat)

    -- Verberg oude rijen
    for _,r in pairs(itemContent.rows) do r:Hide() end
    itemContent.rows = {}

    local ROW_H = 28
    for i,item in ipairs(items) do
        local r = CreateFrame("Button",nil,itemContent,"BackdropTemplate")
        r:SetSize(186, ROW_H)
        r:SetPoint("TOPLEFT",0,-(i-1)*(ROW_H+2))
        r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        r:SetBackdropColor(0.08,0.06,0.02,0.9)
        r:SetBackdropBorderColor(0.35,0.25,0.05,0.6)
        r:Show()

        -- Icoon
        r.ico = r:CreateTexture(nil,"ARTWORK")
        r.ico:SetSize(22,22)
        r.ico:SetPoint("LEFT",3,0)
        if item.icon then r.ico:SetTexture(item.icon) end
        r.ico:SetTexCoord(0.08,0.92,0.08,0.92)

        -- Naam + count
        r.nm = r:CreateFontString(nil,"OVERLAY")
        r.nm:SetFont(C_2002,10,"")
        r.nm:SetPoint("LEFT",29,4)
        r.nm:SetText(item.link or item.name)

        r.cnt = r:CreateFontString(nil,"OVERLAY")
        r.cnt:SetFont(C_2002,9,"OUTLINE")
        r.cnt:SetPoint("LEFT",29,-6)
        r.cnt:SetText(SA_GREY.."x"..item.count.."|r")

        -- Hover
        r:SetScript("OnEnter",function(self)
            self:SetBackdropBorderColor(0.85,0.70,0.10,1)
            if item.link then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(item.link)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave",function(self)
            self:SetBackdropBorderColor(0.35,0.25,0.05,0.6)
            GameTooltip:Hide()
        end)

        -- Klik: attach aan mail
        r:SetScript("OnClick",function()
            if MailFrame and MailFrame:IsShown() then
                -- Zoek lege attachment slot
                for slot=1,ATTACHMENTS_MAX_SEND or 12 do
                    if not GetSendMailItem(slot) then
                        ClickSendMailItemButton(slot)
                        -- Gebruik C_Container om item op te pakken
                        if C_Container and C_Container.PickupContainerItem then
                            C_Container.PickupContainerItem(item.bag,item.slot)
                        else
                            PickupContainerItem(item.bag,item.slot)
                        end
                        break
                    end
                end
                -- Refresh lijst
                C_Timer.After(0.1,function() ShowCategoryItems(cat) end)
            end
        end)

        table.insert(itemContent.rows,r)
    end

    if #items == 0 then
        local empty = CreateFrame("Frame",nil,itemContent)
        empty:SetSize(186,40)
        empty:SetPoint("TOPLEFT",0,0)
        local txt = empty:CreateFontString(nil,"OVERLAY")
        txt:SetFont(C_2002,11,"")
        txt:SetPoint("CENTER")
        txt:SetText(SA_GREY.."Geen items gevonden|r")
        table.insert(itemContent.rows,empty)
    end

    itemContent:SetHeight(math.max(#items*(ROW_H+2),40))
end

-- Bouw categorie knoppen
for i,cat in ipairs(CATEGORIES) do
    local col = (i-1) % COLS
    local row = math.floor((i-1) / COLS)
    local xPos = 8 + col*(BTN_W+BTN_GAP)
    local yPos = -36 - row*(BTN_H+BTN_GAP)

    -- Maar wacht — we willen de categorieën boven de itemlijst
    -- Volgorde: header → cat grid → item scroll → footer
end

-- Herbouw layout: cat knoppen bovenaan
local CAT_ROWS = math.ceil(#CATEGORIES/COLS)
local CAT_AREA_H = CAT_ROWS*(BTN_H+BTN_GAP)+BTN_GAP

-- Vergroot frame voor categorieën + items
QA:SetSize(220, CAT_AREA_H + 260)

-- Cat knoppen
for i,cat in ipairs(CATEGORIES) do
    local col = (i-1) % COLS
    local row = math.floor((i-1) / COLS)
    local xPos = 8 + col*(BTN_W+BTN_GAP)
    local yPos = -(36 + BTN_GAP + row*(BTN_H+BTN_GAP))

    local b = CreateFrame("Button",nil,QA,"BackdropTemplate")
    b:SetSize(BTN_W,BTN_H)
    b:SetPoint("TOPLEFT",xPos,yPos)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(0.08,0.06,0.02,0.9)
    b:SetBackdropBorderColor(0.40,0.30,0.05,0.8)

    -- Icoon
    b.ico = b:CreateTexture(nil,"ARTWORK")
    b.ico:SetSize(18,18)
    b.ico:SetPoint("LEFT",3,0)
    b.ico:SetTexture(CAT_ICONS[cat.label] or "Interface\\Icons\\inv_misc_bag_07")
    b.ico:SetTexCoord(0.08,0.92,0.08,0.92)

    b.lbl = b:CreateFontString(nil,"OVERLAY")
    b.lbl:SetFont(C_2002,10,"")
    b.lbl:SetPoint("LEFT",24,0)
    b.lbl:SetText(SA_GREY..cat.label.."|r")

    b:SetScript("OnClick",function(self)
        -- Reset alle knoppen
        for _,ob in ipairs(QA.catBtns) do
            ob:SetBackdropColor(0.08,0.06,0.02,0.9)
            ob:SetBackdropBorderColor(0.40,0.30,0.05,0.8)
            ob.lbl:SetText(SA_GREY..ob._cat.label.."|r")
        end
        -- Activeer deze
        self:SetBackdropColor(0.18,0.12,0.02,1)
        self:SetBackdropBorderColor(0.85,0.65,0.10,1)
        self.lbl:SetText(SA_GOLD..cat.label.."|r")
        ShowCategoryItems(cat)
    end)
    b:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(0.85,0.65,0.10,1) end)
    b:SetScript("OnLeave",function(s)
        if QA.activeCat ~= cat then s:SetBackdropBorderColor(0.40,0.30,0.05,0.8) end
    end)

    b._cat = cat
    table.insert(QA.catBtns,b)
end

-- Herpositioneer item scroll onder cat knoppen
itemScroll:ClearAllPoints()
itemScroll:SetPoint("TOPLEFT",8,-(36+CAT_AREA_H+4))
itemScroll:SetPoint("BOTTOMRIGHT",-22,-56)

-- ── FOOTER: Send to Character ─────────────────────────────────────────────
local ftrBG = QA:CreateTexture(nil,"BACKGROUND")
ftrBG:SetHeight(50)
ftrBG:SetPoint("BOTTOMLEFT",1,1)
ftrBG:SetPoint("BOTTOMRIGHT",-1,1)
ftrBG:SetColorTexture(0.08,0.05,0.01,1)

local ftrLbl = QA:CreateFontString(nil,"OVERLAY")
ftrLbl:SetFont(C_2002,9,"")
ftrLbl:SetPoint("BOTTOMLEFT",8,32)
ftrLbl:SetText(SA_GREY.."Send to Character|r")

local charSearch = CreateFrame("EditBox",nil,QA,"BackdropTemplate")
charSearch:SetSize(200,20)
charSearch:SetPoint("BOTTOMLEFT",8,8)
charSearch:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
charSearch:SetBackdropColor(0,0,0,0.9)
charSearch:SetBackdropBorderColor(0.45,0.32,0.05,0.8)
charSearch:SetFontObject("ChatFontNormal")
charSearch:SetText("Type name to search...")
charSearch:SetAutoFocus(false)
charSearch:SetScript("OnEditFocusGained",function(self)
    if self:GetText()=="Type name to search..." then self:SetText("") end
end)
charSearch:SetScript("OnEditFocusLost",function(self)
    if self:GetText()=="" then self:SetText("Type name to search...") end
end)
charSearch:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
charSearch:SetScript("OnEnterPressed",function(self)
    -- Vul "To:" veld van mailbox met de naam
    if SendMailNameEditBox then
        SendMailNameEditBox:SetText(self:GetText())
    end
    self:ClearFocus()
end)

-- ── EVENT: open bij mailbox ────────────────────────────────────────────────
local mailEvent = CreateFrame("Frame")
mailEvent:RegisterEvent("MAIL_SHOW")
mailEvent:RegisterEvent("MAIL_CLOSED")
mailEvent:SetScript("OnEvent",function(self,event)
    if event=="MAIL_SHOW" then
        -- Positioneer naast mailframe
        QA:ClearAllPoints()
        if MailFrame then
            QA:SetPoint("TOPLEFT",MailFrame,"TOPRIGHT",4,0)
        else
            QA:SetPoint("LEFT",UIParent,"CENTER",-500,0)
        end
        QA:Show()
        -- Activeer eerste categorie
        if QA.catBtns[1] then QA.catBtns[1]:Click() end
    elseif event=="MAIL_CLOSED" then
        QA:Hide()
    end
end)

-- ── SLASH COMMAND ─────────────────────────────────────────────────────────
SLASH_DTMAIL1 = "/dtmail"
SlashCmdList["DTMAIL"] = function()
    if QA:IsShown() then QA:Hide() else QA:Show() end
end

-- ── PLUGIN REGISTRATIE ────────────────────────────────────────────────────
local _dtMailReg = CreateFrame("Frame")
_dtMailReg:RegisterEvent("PLAYER_LOGIN")
_dtMailReg:SetScript("OnEvent",function(self)
    self:UnregisterAllEvents()
    if DelveTracker and DelveTracker.RegisterPlugin then
        DelveTracker:RegisterPlugin("MailAttach",function() end)
    end
end)

-- ============================================================================
-- FILE CARD — DT_MailAttach.lua | v1.0 | 2026-06-07
-- Role  : Quick Attach panel bij mailbox — MailVault integratie
-- Status: Production · Retail 12.0.5.67314 Midnight
-- ============================================================================
