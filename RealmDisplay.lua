-- ============================================================
--  RealmDisplay  —  Redesigned v2
-- ============================================================

-- ============================================================
-- 1. SAVED VARIABLES & DEFAULTS
-- ============================================================
local DEFAULTS = {
    showPanel    = true,
    showPing     = true,
    activeRealm  = nil,
    minimap      = { hide = false },
    point        = nil,
    relPoint     = nil,
    xOfs         = nil,
    yOfs         = nil,
}

local optionsCategory
local db  -- assigned in ADDON_LOADED
local snapBtn
local snapTex

-- Lookup table to map normalized lowercased names back to their proper display names
local NORMALIZED_TO_PROPER = {}

-- Helper to normalize realm names (removing spaces, apostrophes, hyphens, and converting to lowercase)
local function GetNormalizedName(name)
    if not name then return "" end
    return name:gsub("[%s'%-]", ""):lower()
end

-- Helper to convert any realm name (proper or normalized) to its proper display name
local function GetProperRealmName(name)
    if not name then return "" end
    local norm = GetNormalizedName(name)

    -- Check if it matches player's own realm
    local playerRealm = GetRealmName and GetRealmName()
    if playerRealm and GetNormalizedName(playerRealm) == norm then
        return playerRealm
    end

    -- Check static lookup table
    if NORMALIZED_TO_PROPER[norm] then
        return NORMALIZED_TO_PROPER[norm]
    end

    -- Fallback: split CamelCase (e.g. ShatteredHand -> Shattered Hand)
    return name:gsub("(%l)(%u)", "%1 %2")
end

-- ============================================================
-- 2. LOCALE LOOKUP TABLE
-- ============================================================
local REALM_LOCALE = {
    -- EU English
    ["Aegwynn"]="EN",["Aerie Peak"]="EN",["Agamaggan"]="EN",["Aggramar"]="EN",
    ["Ahn'Qiraj"]="EN",["Al'Akir"]="EN",["Alonsus"]="EN",["Arathor"]="EN",
    ["Argent Dawn"]="EN",["Azjol-Nerub"]="EN",["Azuremyst"]="EN",["Bladefist"]="EN",
    ["Blade's Edge"]="EN",["Bloodfeather"]="EN",["Bloodhoof"]="EN",["Bloodscalp"]="EN",
    ["Bronze Dragonflight"]="EN",["Burning Blade"]="EN",["Burning Legion"]="EN",
    ["Burning Steppes"]="EN",["BurningSteppes"]="EN",["Chamber of Aspects"]="EN",
    ["Chromaggus"]="EN",["Crushridge"]="EN",["Daggerspine"]="EN",
    ["Darkspear"]="EN",["Darksorrow"]="EN",["Deathwing"]="EN",
    ["Defias Brotherhood"]="EN",["Dentarg"]="EN",["Doomhammer"]="EN",
    ["Draenor"]="EN",["Dragonblight"]="EN",["Dragonmaw"]="EN",["Dunemaul"]="EN",
    ["Earthen Ring"]="EN",["Emerald Dream"]="EN",["Emeriss"]="EN",["Eonar"]="EN",
    ["Executus"]="EN",["Frostmane"]="EN",["Frostwhisper"]="EN",["Genjuros"]="EN",
    ["Ghostlands"]="EN",["Grim Batol"]="EN",["Hakkar"]="EN",["Haomarush"]="EN",
    ["Hellfire"]="EN",["Hyjal"]="EN",["Karazhan"]="EN",["Kazzak"]="EN",
    ["Kilrogg"]="EN",["Kor'gall"]="EN",["Korgall"]="EN",["Laughing Skull"]="EN",
    ["Lightbringer"]="EN",["Lightning's Blade"]="EN",["Magtheridon"]="EN",
    ["Mazrigos"]="EN",["Medivh"]="EN",["Moonglade"]="EN",["Nagrand"]="EN",
    ["Neptulon"]="EN",["Nordrassil"]="EN",["Outland"]="EN",["Perenolde"]="EN",
    ["Proudmoore"]="EN",["Ragnaros"]="EN",["Ravencrest"]="EN",["Ravenholdt"]="EN",
    ["Runetotem"]="EN",["Saurfang"]="EN",["Shadowsong"]="EN",
    ["Shattered Hand"]="EN",["ShatteredHand"]="EN",["Silvermoon"]="EN",
    ["Skullcrusher"]="EN",["Spinebreaker"]="EN",["Sporeggar"]="EN",
    ["Steamwheedle Cartel"]="EN",["Stormrage"]="EN",["Stormreaver"]="EN",
    ["Stormscale"]="EN",["Sunstrider"]="EN",["Sylvanas"]="EN",["Talnivarr"]="EN",
    ["Tarren Mill"]="EN",["Terokkar"]="EN",["The Maelstrom"]="EN",
    ["The Sha'tar"]="EN",["The Venture Co"]="EN",["Thunderhorn"]="EN",
    ["Tichondrius"]="EN",["Trollbane"]="EN",["Turalyon"]="EN",
    ["Twilight's Hammer"]="EN",["Twisting Nether"]="EN",["Vashj"]="EN",
    ["Vek'nilash"]="EN",["Wildhammer"]="EN",["Xavius"]="EN",["Zenedar"]="EN",
    -- EU French
    ["Archimonde"]="FR",["Chants éternels"]="FR",["Cho'gall"]="FR",
    ["Confrérie du Thorium"]="FR",["Conseil des Ombres"]="FR",
    ["Culte de la Rive noire"]="FR",["Dalaran"]="FR",["Drek'Thar"]="FR",
    ["Elune"]="FR",["Illidan"]="FR",["Kael'thas"]="FR",["Khaz Modan"]="FR",
    ["Kirin Tor"]="FR",["La Croisade écarlate"]="FR",["Les Clairvoyants"]="FR",
    ["Les Sentinelles"]="FR",["Naxxramas"]="FR",["Ner'zhul"]="FR",
    ["Rashgarroth"]="FR",["Sargeras"]="FR",["Suramar"]="FR",
    ["Temple noir"]="FR",["Throk'Feroth"]="FR",["Varimathras"]="FR",["Ysondre"]="FR",
    -- EU German
    ["Anetheron"]="DE",["Antonidas"]="DE",["Anub'arak"]="DE",["Arthas"]="DE",
    ["Azshara"]="DE",["Baelgun"]="DE",["Blackhand"]="DE",["Blackmoore"]="DE",
    ["Blackrock"]="DE",["Celebras"]="DE",["Destromath"]="DE",["Dethecus"]="DE",
    ["Dun Morogh"]="DE",["Echsenkessel"]="DE",["Eredar"]="DE",["Forscherliga"]="DE",
    ["Frostwolf"]="DE",["Gorgonnash"]="DE",["Gurubashi"]="DE",["Kargath"]="DE",
    ["Kil'jaeden"]="DE",["Lordaeron"]="DE",["Madmortem"]="DE",["Mal'Ganis"]="DE",
    ["Mannoroth"]="DE",["Nathrezim"]="DE",["Nethersturm"]="DE",["Nefarian"]="DE",
    ["Nozdormu"]="DE",["Onyxia"]="DE",["Rexxar"]="DE",["Shattrath"]="DE",
    ["Taerar"]="DE",["Terrordar"]="DE",["Thrall"]="DE",["Uldaman"]="DE",
    ["Ysera"]="DE",["Zuluhed"]="DE",
    -- EU Spanish
    ["Colinas Pardas"]="ES",["C'Thun"]="ES",["Exodar"]="ES",
    ["Los Errantes"]="ES",["Malfurion"]="ES",["Minahonda"]="ES",["Sanguino"]="ES",
    ["Shen'dralar"]="ES",["Tyrande"]="ES",["Uldum"]="ES",["Zul'jin"]="ES",
    -- EU Russian (transliterated common ones)
    ["Azuregos"]="RU",["Borei'skaya Tundra"]="RU",["Galakrond"]="RU",
    -- NA Portuguese (Brazil)
    ["Azralon"]="PT",["Gallywix"]="PT",["Goldrinn"]="PT",["Nemesis"]="PT",
    ["Tol Barad"]="PT",
    -- NA Spanish (Latin America)
    ["Quel'Thalas"]="ES",
}

local function GetRealmLocale(realmName)
    local properName = GetProperRealmName(realmName)
    return REALM_LOCALE[properName] or "EN"
end

-- ============================================================
-- 3. REGION HELPER
-- ============================================================
local REGION_MAP = { "US", "KR", "EU", "TW", "CN" }
local function GetRegionTag()
    local id = GetCurrentRegion and GetCurrentRegion() or 1
    return REGION_MAP[id] or "??"
end

-- ============================================================
-- 4. PING HELPER
-- ============================================================
local function GetPingColor(ms)
    if ms < 80  then return "|cff44FF44" end
    if ms < 180 then return "|cffFFD100" end
    return "|cffFF4444"
end

-- ============================================================
-- 5. REALM DATA BUILDER
-- ============================================================
local function BuildRealmData()
    local current = GetRealmName()
    local seen    = { [GetNormalizedName(current)] = true }
    local connected = {}
    local auto = GetAutoCompleteRealms()
    if auto then
        for _, r in ipairs(auto) do
            local norm = GetNormalizedName(r)
            if not seen[norm] then
                seen[norm] = true
                connected[#connected + 1] = GetProperRealmName(r)
            end
        end
    end
    return current, connected
end

-- ============================================================
-- 6. STATIC POPUP
-- ============================================================
StaticPopupDialogs["REALMDISPLAY_RELOAD"] = {
    text      = "Realm Watch: Minimap button changes require a UI reload. Reload now?",
    button1   = "Reload",
    button2   = "Later",
    OnAccept  = function() ReloadUI() end,
    timeout   = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- ============================================================
-- 7. FRAME LAYOUT CONSTANTS
-- ============================================================
local PANEL_W    = 270
local ROW_H      = 20   -- height per realm line in body
local HEADER_H   = 22   -- header bar
local YOUR_H     = 36   -- your realm block (name + sub line)
local DROP_H     = 22   -- dropdown button
local GAP        = 4    -- padding between sections
local SEP_H      = 1    -- separator
local FOOTER_H   = 18   -- footer row

-- Fixed y-offsets (negative = downward from top)
local Y_HEADER_BOT  = -HEADER_H                          -- -22
local Y_YOUR_TOP    = Y_HEADER_BOT - GAP                 -- -26
local Y_YOUR_BOT    = Y_YOUR_TOP - YOUR_H                -- -62
local Y_DROP_TOP    = Y_YOUR_BOT - GAP                   -- -66
local Y_DROP_BOT    = Y_DROP_TOP - DROP_H                -- -88
local Y_SEP1        = Y_DROP_BOT - GAP                   -- -92
local Y_BODY_TOP    = Y_SEP1 - SEP_H - GAP               -- -97

-- ============================================================
-- 8. MAIN FRAME
-- ============================================================
local frame = CreateFrame("Frame", "RealmDisplayFrame", UIParent, "BackdropTemplate")
frame:SetSize(PANEL_W, 200)
frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 300)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
frame:SetBackdropColor(0.04, 0.04, 0.10, 0.92)
frame:SetBackdropBorderColor(0.25, 0.25, 0.45, 1)

frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    db.point    = point
    db.relPoint = relPoint
    db.xOfs     = x
    db.yOfs     = y
end)

-- 8a. HEADER BAR
local headerBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
headerBg:SetPoint("TOPLEFT",     frame, "TOPLEFT",  0,  0)
headerBg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0,  Y_HEADER_BOT)
headerBg:SetColorTexture(0.10, 0.10, 0.22, 1)

local headerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -5)
headerLabel:SetText("|cffFFD100REALM|r|cffAAAAAA WATCH|r")

-- Snap-back button [↺]
snapBtn = CreateFrame("Button", nil, frame)
snapBtn:SetSize(16, 16)
snapBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -3)

snapTex = snapBtn:CreateTexture(nil, "ARTWORK")
snapTex:SetAllPoints()
snapTex:SetTexture("Interface\\Buttons\\UI-RefreshButton")

snapBtn:SetScript("OnClick", function()
    db.activeRealm = nil
    RealmDisplayFrame_Update()
end)
snapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Snap back to your realm", 1, 1, 1)
    GameTooltip:Show()
end)
snapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- 8b. YOUR REALM BLOCK
local yourDot = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
yourDot:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, Y_YOUR_TOP)
yourDot:SetText("|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:-1|t")

local yourName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
yourName:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, Y_YOUR_TOP)

local yourPing = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
yourPing:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, Y_YOUR_TOP)
yourPing:SetJustifyH("RIGHT")

local yourSub = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
yourSub:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, Y_YOUR_TOP - 15)

-- 8c. DROPDOWN BUTTON
local dropBtn = CreateFrame("Button", "RealmDisplayDropBtn", frame, "BackdropTemplate")
dropBtn:SetHeight(DROP_H)
dropBtn:SetPoint("TOPLEFT",  frame, "TOPLEFT",   6, Y_DROP_TOP)
dropBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  -6, Y_DROP_TOP)
dropBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
dropBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
dropBtn:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)

local dropLabel = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dropLabel:SetPoint("LEFT",  dropBtn, "LEFT",  6, 0)
dropLabel:SetPoint("RIGHT", dropBtn, "RIGHT", -16, 0)
dropLabel:SetJustifyH("LEFT")
dropLabel:SetWordWrap(false)

local dropChevron = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dropChevron:SetPoint("RIGHT", dropBtn, "RIGHT", -4, 0)
dropChevron:SetText("|cff888888v|r")

-- 8d. SEPARATOR 1 (below dropdown)
local sep1 = frame:CreateTexture(nil, "BACKGROUND")
sep1:SetHeight(SEP_H)
sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",   6, Y_SEP1)
sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  -6, Y_SEP1)
sep1:SetColorTexture(0.25, 0.25, 0.45, 0.8)

-- 8e. BODY TEXT
local bodyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bodyText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, Y_BODY_TOP)
bodyText:SetWidth(PANEL_W - 16)
bodyText:SetHeight(0)
bodyText:SetJustifyH("LEFT")
bodyText:SetJustifyV("TOP")
bodyText:SetWordWrap(false)

-- 8f. SEPARATOR 2 (above footer) — positioned dynamically
local sep2 = frame:CreateTexture(nil, "BACKGROUND")
sep2:SetHeight(SEP_H)
sep2:SetColorTexture(0.25, 0.25, 0.45, 0.8)

-- 8g. FOOTER
local footerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
footerText:SetJustifyH("LEFT")

-- ============================================================
-- 9. DROPDOWN SEARCH PANEL
-- ============================================================
local dropPanel = CreateFrame("Frame", "RealmDisplayDropPanel", UIParent, "BackdropTemplate")
dropPanel:SetWidth(PANEL_W - 12)
dropPanel:SetFrameStrata("HIGH")
dropPanel:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
dropPanel:SetBackdropColor(0.06, 0.06, 0.14, 0.98)
dropPanel:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
dropPanel:Hide()

local searchBox = CreateFrame("EditBox", nil, dropPanel, "InputBoxTemplate")
searchBox:SetHeight(20)
searchBox:SetPoint("TOPLEFT",  dropPanel, "TOPLEFT",   8, -6)
searchBox:SetPoint("TOPRIGHT", dropPanel, "TOPRIGHT", -8, -6)
searchBox:SetAutoFocus(false)
searchBox:SetMaxLetters(64)

local searchHint = dropPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchHint:SetPoint("LEFT", searchBox, "LEFT", 4, 0)
searchHint:SetText("Search realms...")

searchBox:SetScript("OnTextChanged", function(self)
    searchHint:SetShown(self:GetText() == "")
    RealmDisplayDropPanel_Filter(self:GetText())
end)
searchBox:SetScript("OnEscapePressed", function() dropPanel:Hide() end)

local scrollFrame = CreateFrame("ScrollFrame", nil, dropPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",     dropPanel, "TOPLEFT",    4, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", dropPanel, "BOTTOMRIGHT", -26, 4)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(PANEL_W - 40)
scrollChild:SetHeight(1)
scrollFrame:SetScrollChild(scrollChild)

local realmButtons = {}

local function GetOrCreateRealmButton(index)
    if realmButtons[index] then return realmButtons[index] end
    local btn = CreateFrame("Button", nil, scrollChild)
    btn:SetHeight(20)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("LEFT",  btn, "LEFT",  4, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    lbl:SetJustifyH("LEFT")
    btn.label = lbl
    btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 0.85, 0, 1) end)
    btn:SetScript("OnLeave", function() lbl:SetTextColor(0.8, 0.8, 0.8, 1) end)
    btn:SetScript("OnClick", function(self)
        db.activeRealm = self.realmName
        dropPanel:Hide()
        searchBox:SetText("")
        searchHint:Show()
        RealmDisplayFrame_Update()
    end)
    realmButtons[index] = btn
    return btn
end

-- allDropRealms holds the full cluster list for the dropdown (including current realm)
local allDropRealms = {}

function RealmDisplayDropPanel_Filter(query)
    query = (query or ""):lower()
    local region = GetRegionTag()
    local y = 0
    local count = 0
    for _, r in ipairs(allDropRealms) do
        if query == "" or r:lower():find(query, 1, true) then
            count = count + 1
            local btn = GetOrCreateRealmButton(count)
            btn.realmName = r
            local locale = GetRealmLocale(r)
            btn.label:SetText(string.format(
                "|cffCCCCCC%s|r  |cff556688[%s]|r |cff445566[%s]|r",
                r, locale, region
            ))
            btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, -y)
            btn:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
            btn:Show()
            y = y + 20
        end
    end
    for i = count + 1, #realmButtons do realmButtons[i]:Hide() end
    scrollChild:SetHeight(math.max(y, 1))
    scrollFrame:SetVerticalScroll(0)
end

dropBtn:SetScript("OnClick", function()
    if dropPanel:IsShown() then
        dropPanel:Hide()
    else
        dropPanel:ClearAllPoints()
        dropPanel:SetPoint("BOTTOMLEFT",  dropBtn, "TOPLEFT",  0, 2)
        dropPanel:SetPoint("BOTTOMRIGHT", dropBtn, "TOPRIGHT", 0, 2)
        local maxRows = math.min(#allDropRealms, 8)
        dropPanel:SetHeight(34 + maxRows * 20 + 6)
        dropPanel:Show()
        searchBox:SetFocus()
        RealmDisplayDropPanel_Filter(searchBox:GetText())
    end
end)

local clickCatcher = CreateFrame("Frame", nil, UIParent)
clickCatcher:SetAllPoints()
clickCatcher:SetFrameStrata("DIALOG")
clickCatcher:Hide()
clickCatcher:SetScript("OnMouseDown", function()
    dropPanel:Hide()
    clickCatcher:Hide()
end)
dropPanel:SetScript("OnShow", function() clickCatcher:Show() end)
dropPanel:SetScript("OnHide", function() clickCatcher:Hide() end)

-- ============================================================
-- 10. FADE-IN
-- ============================================================
local fadeGroup = frame:CreateAnimationGroup()
local fadeAnim  = fadeGroup:CreateAnimation("Alpha")
fadeAnim:SetFromAlpha(0)
fadeAnim:SetToAlpha(1)
fadeAnim:SetDuration(0.4)
fadeAnim:SetSmoothing("OUT")

-- ============================================================
-- 11. MAIN UPDATE FUNCTION
-- ============================================================
function RealmDisplayFrame_Update()
    if not db then return end

    local currentRealm, connected = BuildRealmData()
    local region = GetRegionTag()

    -- Ping
    local _, _, latHome = GetNetStats()
    latHome = latHome or 0
    if db.showPing then
        yourPing:SetText(GetPingColor(latHome) .. latHome .. "ms|r")
    else
        yourPing:SetText("")
    end

    -- Your realm row
    local yourLocale = GetRealmLocale(currentRealm)
    yourName:SetText("|cffFFFFFF" .. currentRealm .. "|r")
    yourSub:SetText(string.format("|cff556688[%s]|r  |cff445566[%s]|r", yourLocale, region))

    -- Snap button visibility: show only when browsing away from home
    local activeIsHome = (not db.activeRealm) or (db.activeRealm == currentRealm)
    if snapBtn then
        snapBtn:SetShown(not activeIsHome)
    end

    -- Dropdown button label
    local activeRealm  = db.activeRealm or currentRealm
    local activeLocale = GetRealmLocale(activeRealm)
    local pfx = (activeRealm == currentRealm) and "|TInterface\\FriendsFrame\\StatusIcon-Online:10:10:0:-1|t " or "|TInterface\\FriendsFrame\\StatusIcon-Away:10:10:0:-1|t "
    dropLabel:SetText(
        pfx .. "|cffFFFFFF" .. activeRealm .. "|r  "
        .. string.format("|cff556688[%s]|r |cff445566[%s]|r", activeLocale, region)
    )

    -- Build full cluster list for dropdown (current realm first, then connected)
    allDropRealms = { currentRealm }
    for _, r in ipairs(connected) do
        allDropRealms[#allDropRealms + 1] = r
    end

    -- Body: connected realms only (NOT current realm — it has its own row)
    local lines = {}
    for _, r in ipairs(connected) do
        local locale   = GetRealmLocale(r)
        local isActive = (r == db.activeRealm)
        local namePart = isActive and ("|cffFFD100" .. r .. "|r") or ("|cffCCCCCC" .. r .. "|r")
        lines[#lines + 1] = string.format(
            "  %s  |cff556688[%s]|r |cff445566[%s]|r",
            namePart, locale, region
        )
    end

    local lineCount = #lines
    local listH     = lineCount * ROW_H

    -- Give bodyText enough height to render all lines
    bodyText:SetHeight(listH + 4)
    bodyText:SetText(table.concat(lines, "\n"))

    -- Dynamic y positions below the body
    local sep2Y   = Y_BODY_TOP - listH - GAP
    local footY   = sep2Y - SEP_H - GAP
    local totalH  = math.abs(footY) + FOOTER_H + GAP

    sep2:ClearAllPoints()
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",   6, sep2Y)
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  -6, sep2Y)

    footerText:ClearAllPoints()
    footerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, footY)
    footerText:SetText(string.format(
        "|TInterface\\FriendsFrame\\StatusIcon-Offline:10:10:0:-1|t |cff556688CONNECTED|r  |cffAAAAAA%d|r", lineCount
    ))

    frame:SetSize(PANEL_W, totalH)

    if dropPanel:IsShown() then
        RealmDisplayDropPanel_Filter(searchBox:GetText())
    end
end

-- ============================================================
-- 12. PING REFRESH TIMER
-- ============================================================
local pingElapsed = 0
local pingTimer   = CreateFrame("Frame")
pingTimer:SetScript("OnUpdate", function(_, dt)
    pingElapsed = pingElapsed + dt
    if pingElapsed >= 5 then
        pingElapsed = 0
        if db and db.showPing then
            local _, _, lat = GetNetStats()
            yourPing:SetText(GetPingColor(lat or 0) .. (lat or 0) .. "ms|r")
        end
    end
end)

-- ============================================================
-- 13. MINIMAP BUTTON
-- ============================================================
local function SetupMinimapButton()
    local LDB  = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not LDB or not Icon then return end

    local broker = LDB:NewDataObject("RealmDisplay", {
        type  = "launcher",
        icon  = "Interface\\Icons\\INV_Misc_Map_01",
        label = "Realm Watch",
        OnClick = function(_, btn)
            if btn == "RightButton" then
                Settings.OpenToCategory(optionsCategory.ID)
            else
                db.showPanel = not db.showPanel
                frame:SetShown(db.showPanel)
            end
        end,
        OnTooltipShow = function(tip)
            tip:AddLine("|cffFFD100Realm Watch|r")
            tip:AddLine(" ")
            local cur, conn = BuildRealmData()
            tip:AddLine("|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:-1|t |cff44FF44" .. cur .. "|r  |cff888888(your realm)|r")
            for _, r in ipairs(conn) do
                tip:AddLine("|cffCCCCCC  " .. r .. "|r")
            end
            tip:AddLine(" ")
            tip:AddLine("|cff888888Left-click|r to toggle panel")
            tip:AddLine("|cff888888Right-click|r to open settings")
        end,
    })

    Icon:Register("RealmDisplay", broker, db.minimap)
    if db.minimap.hide then Icon:Hide("RealmDisplay") end
end

-- ============================================================
-- 14. SLASH COMMANDS
-- ============================================================
SLASH_REALMDISPLAY1 = "/rd"
SLASH_REALMDISPLAY2 = "/realmdisplay"

SlashCmdList["REALMDISPLAY"] = function(msg)
    local cmd = strtrim(msg):lower()

    if cmd == "toggle" then
        db.showPanel = not db.showPanel
        frame:SetShown(db.showPanel)

    elseif cmd == "reset" then
        db.point = nil; db.relPoint = nil; db.xOfs = nil; db.yOfs = nil
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 300)
        print("|cffFFD100RealmWatch:|r Position reset.")

    elseif cmd == "home" then
        db.activeRealm = nil
        RealmDisplayFrame_Update()
        print("|cffFFD100RealmWatch:|r Snapped back to your realm.")

    elseif cmd == "minimap" then
        db.minimap.hide = not db.minimap.hide
        local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
        if Icon then
            if db.minimap.hide then Icon:Hide("RealmDisplay")
            else Icon:Show("RealmDisplay") end
        end
        print("|cffFFD100RealmWatch:|r Minimap " .. (db.minimap.hide and "hidden" or "shown"))
        StaticPopup_Show("REALMDISPLAY_RELOAD")

    elseif cmd == "ping" then
        db.showPing = not db.showPing
        RealmDisplayFrame_Update()
        print("|cffFFD100RealmWatch:|r Ping " .. (db.showPing and "enabled" or "disabled"))

    elseif cmd == "debug" then
        local cur, conn = BuildRealmData()
        print("Your realm: [" .. cur .. "]  Active: [" .. tostring(db.activeRealm) .. "]")
        print("Connected (" .. #conn .. "):")
        for i, r in ipairs(conn) do print(i .. ": [" .. r .. "]") end
        print("Frame H: " .. frame:GetHeight() .. "  bodyText H: " .. bodyText:GetStringHeight())

    else
        print("|cffFFD100RealmWatch commands:|r")
        print("  /rd toggle   — show/hide panel")
        print("  /rd reset    — reset panel position")
        print("  /rd home     — snap active realm back to yours")
        print("  /rd minimap  — toggle minimap button")
        print("  /rd ping     — toggle ping display")
        print("  /rd debug    — print debug info")
    end
end

-- ============================================================
-- 15. SETTINGS PANEL
-- ============================================================
local function SetupOptionsMenu()
    optionsCategory = Settings.RegisterVerticalLayoutCategory("RealmDisplay")

    local panelSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_Panel", "showPanel",
        db, type(false), "Show Panel on Login", true
    )
    Settings.CreateCheckbox(optionsCategory, panelSetting,
        "Show the Realm Watch panel when you log in.")
    panelSetting:SetValueChangedCallback(function(_, value)
        db.showPanel = value
        frame:SetShown(value)
    end)

    local pingSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_Ping", "showPing",
        db, type(false), "Show Ping", true
    )
    Settings.CreateCheckbox(optionsCategory, pingSetting,
        "Show network latency next to your realm name.")
    pingSetting:SetValueChangedCallback(function(_, value)
        db.showPing = value
        RealmDisplayFrame_Update()
    end)

    local minimapSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_Minimap", "hide",
        db.minimap, type(false), "Hide Minimap Button", false
    )
    Settings.CreateCheckbox(optionsCategory, minimapSetting,
        "Hide the minimap button. Use /rd minimap to restore.")
    minimapSetting:SetValueChangedCallback(function(_, value)
        db.minimap.hide = value
        local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
        if Icon then
            if value then Icon:Hide("RealmDisplay") else Icon:Show("RealmDisplay") end
        end
        StaticPopup_Show("REALMDISPLAY_RELOAD")
    end)

    Settings.RegisterAddOnCategory(optionsCategory)
end

-- ============================================================
-- 16. EVENT CONTROLLER
-- ============================================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "RealmDisplay" then
        -- Initialize the normalized lookup table
        for name, _ in pairs(REALM_LOCALE) do
            local norm = name:gsub("[%s'%-]", ""):lower()
            NORMALIZED_TO_PROPER[norm] = name
        end

        RealmDisplayDB = RealmDisplayDB or {}
        for k, v in pairs(DEFAULTS) do
            if RealmDisplayDB[k] == nil then RealmDisplayDB[k] = v end
        end
        RealmDisplayDB.minimap = RealmDisplayDB.minimap or {}
        if RealmDisplayDB.minimap.hide == nil then
            RealmDisplayDB.minimap.hide = false
        end
        db = RealmDisplayDB

        SetupOptionsMenu()
        SetupMinimapButton()

    elseif event == "PLAYER_LOGIN" then
        if db.point then
            frame:ClearAllPoints()
            frame:SetPoint(db.point, UIParent, db.relPoint, db.xOfs, db.yOfs)
        end
        frame:SetShown(db.showPanel)
        RealmDisplayFrame_Update()
        fadeGroup:Play()
        C_Timer.After(3, RealmDisplayFrame_Update)
    end
end)