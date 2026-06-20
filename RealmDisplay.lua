-- ============================================================
--  RealmDisplay  —  Redesigned v2
-- ============================================================

-- ============================================================
-- 1. SAVED VARIABLES & DEFAULTS
-- ============================================================
local DEFAULTS = {
    showPanel       = true,
    showPing        = true,
    activeRealm     = nil,
    minimap         = { hide = false },
    point           = nil,
    relPoint        = nil,
    xOfs            = nil,
    yOfs            = nil,
    pinned          = false,
    bgColorR        = 0.04,
    bgColorG        = 0.04,
    bgColorB        = 0.10,
    bgColorA        = 0.92,
    fontPath        = "Fonts\\FRIZQT__.TTF",
    fontHeight      = 11,
    textColorR      = 0.80,
    textColorG      = 0.80,
    textColorB      = 0.80,
    accentColorR    = 0.25,
    accentColorG    = 0.25,
    accentColorB    = 0.45,
    accentColorA    = 1.0,
    trackCharacters = true,
    charDisplayMode = "ALL",
}

local optionsCategory
local db  -- assigned in ADDON_LOADED
local snapBtn
local snapTex
local pinBtn
local pinTex
local cfgBtn
local cfgTex
local closeBtn      -- NEW: close panel button
local closeTex      -- NEW 
local themeBtn
local themeTex


-- Reverse map: realm name -> list of its connected realms (built at ADDON_LOADED)
local REALM_CLUSTER = {}

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
-- 2. REALM REFERENCE DATA
--    (REALM_LOCALE, EU_CONNECTED_CLUSTERS, NA_CONNECTED_CLUSTERS
--    now live in Data/RealmData.lua, loaded before this file via
--    RealmDisplay.toc. They're exposed on the RealmDisplay_Data
--    global table.)
-- ============================================================
local REALM_LOCALE          = {} -- Populated dynamically based on region on load
local EU_CONNECTED_CLUSTERS = RealmDisplay_Data.euClusters
local NA_CONNECTED_CLUSTERS = RealmDisplay_Data.naClusters

local function GetRealmLocale(realmName)
    local properName = GetProperRealmName(realmName)
    return REALM_LOCALE[properName] or "EN"
end

local function GetLocaleFlag(locale)
    if locale and (locale == "EN" or locale == "FR" or locale == "DE" or locale == "ES" or locale == "RU" or locale == "PT") then
        return "|TInterface\\AddOns\\RealmDisplay\\Media\\Flags\\" .. locale .. ".png:10:14:0:1|t"
    end
    return locale and ("[" .. locale .. "]") or ""
end

local function GetRegionFlag(region)
    if region and (region == "EU" or region == "US" or region == "KR" or region == "TW" or region == "CN") then
        return "|TInterface\\AddOns\\RealmDisplay\\Media\\Flags\\" .. region .. ".png:10:14:0:1|t"
    end
    return region and ("[" .. region .. "]") or ""
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
-- 3b. ALT CHARACTERS CACHE
-- ============================================================
local function UpdateActiveCharacterCache()
    if not db or not db.trackCharacters then return end
    
    local myRealm = GetRealmName()
    local myName = UnitName("player")
    if not myRealm or not myName or myName == "Unknown" then return end
    
    db.characters = db.characters or {}
    db.characters[myRealm] = db.characters[myRealm] or {}
    
    local prof1, prof2 = "", ""
    local prof1Index, prof2Index = GetProfessions()
    if prof1Index then
        local name, _, rank = GetProfessionInfo(prof1Index)
        prof1 = string.format("%s (%d)", name, rank)
    end
    if prof2Index then
        local name, _, rank = GetProfessionInfo(prof2Index)
        prof2 = string.format("%s (%d)", name, rank)
    end
    
    local _, classEnglish = UnitClass("player")
    
    db.characters[myRealm][myName] = {
        level = UnitLevel("player"),
        class = classEnglish or "WARRIOR",
        prof1 = prof1,
        prof2 = prof2,
        money = GetMoney(),
        lastUpdated = time(),
    }
end

local function GetCharacterTooltipLine(charName, data)
    local mode = (db and db.charDisplayMode) or "ALL"

    local showName = (mode == "ALL" or mode == "NO_LEVEL" or mode == "NO_GOLD" or mode == "NO_PROF" or mode == "NAME_LVL" or mode == "NAME_GOLD" or mode == "NAME_PROF" or mode == "NAME")
    local showLvl  = (mode == "ALL" or mode == "NO_NAME" or mode == "NO_GOLD" or mode == "NO_PROF" or mode == "NAME_LVL" or mode == "LVL_GOLD" or mode == "LVL_PROF" or mode == "LVL")
    local showGold = (mode == "ALL" or mode == "NO_NAME" or mode == "NO_LEVEL" or mode == "NO_PROF" or mode == "NAME_GOLD" or mode == "LVL_GOLD" or mode == "GOLD_PROF" or mode == "GOLD")
    local showProf = (mode == "ALL" or mode == "NO_NAME" or mode == "NO_LEVEL" or mode == "NO_GOLD" or mode == "NAME_PROF" or mode == "LVL_PROF" or mode == "GOLD_PROF" or mode == "PROF")

    local parts = {}
    
    local nameStr = ""
    if showName then
        local classColor = RAID_CLASS_COLORS[data.class]
        local classColorHex = classColor and classColor.colorStr or "ffffff"
        nameStr = string.format("|c%s%s|r", classColorHex, charName)
    end
    
    local lvlStr = ""
    if showLvl then
        lvlStr = string.format("Lv %d", data.level)
    end
    
    if showName and showLvl then
        table.insert(parts, string.format("%s (%s)", nameStr, lvlStr))
    elseif showName then
        table.insert(parts, nameStr)
    elseif showLvl then
        table.insert(parts, lvlStr)
    end
    
    if showGold and data.money then
        table.insert(parts, GetCoinTextureString(data.money))
    end
    
    if showProf then
        local profs = {}
        if data.prof1 and data.prof1 ~= "" then table.insert(profs, data.prof1) end
        if data.prof2 and data.prof2 ~= "" then table.insert(profs, data.prof2) end
        if #profs > 0 then
            table.insert(parts, table.concat(profs, ", "))
        end
    end
    
    return "  " .. table.concat(parts, " - ")
end

-- ============================================================
-- 4. PING HELPER
-- ============================================================
local function GetPingColor(ms)
    if ms < 80  then return "|cff44FF44" end
    if ms < 180 then return "|cffFFD100" end
    return "|cffFF4444"
end

local function SetFontStringShadow(fs, enabled)
    if not fs then return end
    if enabled then
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
    else
        fs:SetShadowColor(0, 0, 0, 0)
        fs:SetShadowOffset(0, 0)
    end
end

-- ============================================================
-- 5. REALM DATA BUILDER
-- ============================================================
local function BuildRealmData()
    local current     = GetRealmName()
    local activeRealm = (db and db.activeRealm) or current

    -- For the player's own realm use the live API — most accurate
    if GetNormalizedName(activeRealm) == GetNormalizedName(current) then
        local seen      = { [GetNormalizedName(current)] = true }
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

    -- For any other selected realm use the static cluster table
    local cluster = REALM_CLUSTER[activeRealm] or {}
    return current, cluster
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
local DROP_H     = 22   -- dropdown button
local L_HEADER_H = 16   -- list header height ("CONNECTED TO: [REALM]")
local GAP        = 4    -- padding between sections
local SEP_H      = 1    -- separator
local FOOTER_H   = 18   -- footer row

local Y_HEADER_BOT   = -HEADER_H                          -- -22
local Y_DROP_TOP     = Y_HEADER_BOT - GAP                 -- -26
local Y_DROP_BOT     = Y_DROP_TOP - DROP_H                -- -48
local Y_SEP1         = Y_DROP_BOT - GAP                   -- -52
local Y_L_HEADER_TOP = Y_SEP1 - SEP_H - GAP               -- -57
local Y_BODY_TOP     = Y_L_HEADER_TOP - L_HEADER_H - GAP   -- -77

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

frame:SetScript("OnDragStart", function(self)
    if not db.pinned then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    if not db.pinned then
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        db.point    = point
        db.relPoint = relPoint
        db.xOfs     = x
        db.yOfs     = y
    end
end)

-- 8a. HEADER BAR
local headerBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
headerBg:SetPoint("TOPLEFT",     frame, "TOPLEFT",  0,  0)
headerBg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0,  Y_HEADER_BOT)
headerBg:SetColorTexture(0.10, 0.10, 0.22, 1)

local headerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -5)
headerLabel:SetText("|cffFFD100REALM|r|cffAAAAAA WATCH|r")

-- -------------------------------------------------------
-- HEADER BUTTONS (right to left): Close | Pin | Settings | Theme
-- -------------------------------------------------------

-- Close button [X]  — NEW, rightmost
closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(16, 16)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -3)
 
closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\close.png")
 
closeBtn:SetScript("OnClick", function()
    db.showPanel = false
    frame:Hide()
end)
closeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Close panel", 1, 1, 1)
    GameTooltip:Show()
end)
closeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- Pin button [🔒/🔓]  — second from right
pinBtn = CreateFrame("Button", nil, frame)
pinBtn:SetSize(16, 16)
pinBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -3)

pinTex = pinBtn:CreateTexture(nil, "ARTWORK")
pinTex:SetAllPoints()

pinBtn:SetScript("OnClick", function()
    db.pinned = not db.pinned
    frame:SetMovable(not db.pinned)
    RealmDisplayFrame_Update()
    if GameTooltip:GetOwner() == pinBtn then
        pinBtn:GetScript("OnEnter")(pinBtn)
    end
end)
pinBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if db.pinned then
        GameTooltip:AddLine("Unlock position", 1, 1, 1)
    else
        GameTooltip:AddLine("Lock position", 1, 1, 1)
    end
    GameTooltip:Show()
end)
pinBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Settings button [⚙]  — third from right
cfgBtn = CreateFrame("Button", nil, frame)
cfgBtn:SetSize(16, 16)
cfgBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -3)

cfgTex = cfgBtn:CreateTexture(nil, "ARTWORK")
cfgTex:SetAllPoints()
cfgTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\settings.png")

cfgBtn:SetScript("OnClick", function()
    if RealmDisplayConfigFrame then
        if RealmDisplayConfigFrame:IsShown() then
            RealmDisplayConfigFrame:Hide()
        else
            RealmDisplayConfigFrame:ClearAllPoints()
            RealmDisplayConfigFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
            RealmDisplayConfigFrame:Show()
        end
    end
end)
cfgBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Appearance Settings", 1, 1, 1)
    GameTooltip:Show()
end)
cfgBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Theme Toggle Button [☀️/🌙] — fourth from right
themeBtn = CreateFrame("Button", nil, frame)
themeBtn:SetSize(16, 16)
themeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -60, -3)

themeTex = themeBtn:CreateTexture(nil, "ARTWORK")
themeTex:SetAllPoints()

themeBtn:SetScript("OnClick", function()
    if not db then return end
    if db.bgColorR < 0.5 then
        -- Switch to Light Mode
        db.bgColorR     = 0.94
        db.bgColorG     = 0.94
        db.bgColorB     = 0.96
        db.bgColorA     = 0.95
        db.textColorR   = 0.08
        db.textColorG   = 0.08
        db.textColorB   = 0.12
        db.accentColorR = 0.40
        db.accentColorG = 0.40
        db.accentColorB = 0.75
        db.accentColorA = 1.0
    else
        -- Switch to Dark Mode
        db.bgColorR     = DEFAULTS.bgColorR
        db.bgColorG     = DEFAULTS.bgColorG
        db.bgColorB     = DEFAULTS.bgColorB
        db.bgColorA     = DEFAULTS.bgColorA
        db.textColorR   = DEFAULTS.textColorR
        db.textColorG   = DEFAULTS.textColorG
        db.textColorB   = DEFAULTS.textColorB
        db.accentColorR = DEFAULTS.accentColorR
        db.accentColorG = DEFAULTS.accentColorG
        db.accentColorB = DEFAULTS.accentColorB
        db.accentColorA = DEFAULTS.accentColorA
    end
    
    if RealmDisplayConfigFrame and RealmDisplayConfigFrame:IsShown() then
        UpdateConfigPanelFields()
    end
    RealmDisplayFrame_Update()
end)

themeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if db and db.bgColorR < 0.5 then
        GameTooltip:AddLine("Switch to Light Theme", 1, 1, 1)
    else
        GameTooltip:AddLine("Switch to Dark Theme", 1, 1, 1)
    end
    GameTooltip:Show()
end)
themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- 8b. LIST HEADER ("Connected to: [REALM]")
local listHeader = CreateFrame("Button", nil, frame)
listHeader:SetSize(PANEL_W - 38, 16)
listHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, Y_L_HEADER_TOP)

local listHeaderText = listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
listHeaderText:SetPoint("LEFT", listHeader, "LEFT", 0, 0)
listHeaderText:SetJustifyH("LEFT")
listHeader.text = listHeaderText

listHeader:SetScript("OnEnter", function(self)
    -- Show a high-contrast highlight color on hover
    if db then
        listHeaderText:SetTextColor(db.accentColorR * 1.8, db.accentColorG * 1.8, db.accentColorB * 1.8, 1)
    else
        listHeaderText:SetTextColor(1, 0.82, 0)
    end
    
    local currentRealm, connected = BuildRealmData()
    local activeRealm = db.activeRealm or currentRealm
    
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cffFFD100Target Realm: " .. activeRealm .. "|r")
    
    -- Display characters on this target realm
    if db and db.characters and db.characters[activeRealm] then
        local hasChars = false
        for charName, data in pairs(db.characters[activeRealm]) do
            if not hasChars then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Your Characters:", 1, 0.82, 0)
                hasChars = true
            end
            GameTooltip:AddLine(GetCharacterTooltipLine(charName, data), 0.9, 0.9, 0.9)
        end
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click to insert selected realm name into chat.", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Shift-Click to link all connected realms.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

listHeader:SetScript("OnLeave", function(self)
    if db then
        local isLight = (db.bgColorR > 0.5)
        if isLight then
            listHeaderText:SetTextColor(db.accentColorR * 0.5, db.accentColorG * 0.5, db.accentColorB * 0.5, 1)
        else
            listHeaderText:SetTextColor(db.accentColorR * 1.6, db.accentColorG * 1.6, db.accentColorB * 1.6, 1)
        end
    else
        listHeaderText:SetTextColor(0.5, 0.5, 0.5)
    end
    GameTooltip:Hide()
end)

listHeader:SetScript("OnClick", function(self)
    local currentRealm, connected = BuildRealmData()
    local activeRealm = db.activeRealm or currentRealm
    if IsShiftKeyDown() then
        -- Insert the entire connected realm cluster
        local allRealms = { activeRealm }
        for _, r in ipairs(connected) do
            table.insert(allRealms, r)
        end
        table.sort(allRealms)
        local listStr = table.concat(allRealms, ", ")
        
        if not ChatEdit_InsertLink(listStr) then
            print("|cffFFD100Connected Realms:|r " .. listStr)
        end
    else
        -- Insert just this single realm name
        if not ChatEdit_InsertLink(activeRealm) then
            print("|cffFFD100Realm:|r " .. activeRealm)
        end
    end
end)

-- 8b2. SHARE BUTTON (links connected list excluding active realm)
local shareBtn = CreateFrame("Button", nil, frame)
shareBtn:SetSize(14, 14)
shareBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, Y_L_HEADER_TOP)
shareBtn:SetFrameLevel(listHeader:GetFrameLevel() + 2)

local shareTex = shareBtn:CreateTexture(nil, "ARTWORK")
shareTex:SetAllPoints()
shareTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\share.png")
shareBtn.tex = shareTex

shareBtn:SetScript("OnClick", function()
    local currentRealm, connected = BuildRealmData()
    local activeRealm = db.activeRealm or currentRealm
    
    local otherRealms = {}
    local activeNorm = GetNormalizedName(activeRealm)
    for _, r in ipairs(connected) do
        if GetNormalizedName(r) ~= activeNorm then
            table.insert(otherRealms, r)
        end
    end
    table.sort(otherRealms)
    
    local listStr = table.concat(otherRealms, ", ")
    local shareMsg = string.format("Connected realms to %s: %s", activeRealm, listStr)
    
    if not ChatEdit_InsertLink(shareMsg) then
        print("|cffFFD100Realm Watch:|r " .. shareMsg)
    end
end)

shareBtn:SetScript("OnEnter", function(self)
    shareTex:SetVertexColor(1, 0.82, 0, 1) -- highlight gold
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Share Connections", 1, 1, 1)
    GameTooltip:AddLine("Click to link formatted connection list in chat.", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("(Excludes '" .. (db.activeRealm or GetRealmName()) .. "' from list for clarity)", 0.5, 0.8, 0.5)
    GameTooltip:Show()
end)

shareBtn:SetScript("OnLeave", function(self)
    if db then
        shareTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
    else
        shareTex:SetVertexColor(0.8, 0.8, 0.8, 0.8)
    end
    GameTooltip:Hide()
end)

-- 8c. DROPDOWN BUTTON  (with inline snap-back button on the right)
local dropBtn = CreateFrame("Button", "RealmDisplayDropBtn", frame, "BackdropTemplate")
dropBtn:SetHeight(DROP_H)
dropBtn:SetPoint("TOPLEFT",  frame, "TOPLEFT",   6, Y_DROP_TOP)
dropBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, Y_DROP_TOP)    -- full width by default
dropBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
dropBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
dropBtn:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)

local dropLabel = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dropLabel:SetPoint("LEFT",  dropBtn, "LEFT",  6, 0)
dropLabel:SetJustifyH("LEFT")
dropLabel:SetWordWrap(false)

local dropChevron = dropBtn:CreateTexture(nil, "ARTWORK")
dropChevron:SetSize(12, 12)
dropChevron:SetPoint("RIGHT", dropBtn, "RIGHT", -6, 0)
dropChevron:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\chevron.png")

local dropSub = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dropSub:SetPoint("RIGHT", dropChevron, "LEFT", -6, 0)
dropSub:SetJustifyH("RIGHT")

-- -------------------------------------------------------
-- SNAP-BACK BUTTON — now lives beside the dropdown row
-- Shown as a small [↺] button to the right of the dropdown.
-- It appears only when browsing a non-home realm.
-- -------------------------------------------------------
snapBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
snapBtn:SetSize(DROP_H, DROP_H)   -- square, same height as dropdown
snapBtn:SetPoint("TOPLEFT", frame, "TOPRIGHT", -6 - DROP_H - 2, Y_DROP_TOP)  -- right side of frame
snapBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
snapBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
snapBtn:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
 
snapTex = snapBtn:CreateTexture(nil, "ARTWORK")
snapTex:SetPoint("CENTER")
snapTex:SetSize(14, 14)
snapTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\refresh.png")
 
snapBtn:SetScript("OnClick", function()
    db.activeRealm = nil
    RealmDisplayFrame_Update()
end)
snapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Snap back to your realm", 1, 1, 1)
    GameTooltip:Show()
end)
snapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- 8d. SEPARATOR 1 (below dropdown)
local sep1 = frame:CreateTexture(nil, "BACKGROUND")
sep1:SetHeight(SEP_H)
sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",   6, Y_SEP1)
sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  -6, Y_SEP1)
sep1:SetColorTexture(0.25, 0.25, 0.45, 0.8)

-- 8e. BODY ROWS POOL
local rows = {}
local function GetOrCreateRow(index)
    if rows[index] then return rows[index] end
    local rFrame = CreateFrame("Button", nil, frame)
    rFrame:SetSize(PANEL_W - 16, ROW_H)
    
    local bg = rFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:Hide()
    rFrame.bg = bg
    
    local name = rFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", rFrame, "LEFT", 4, 0)
    name:SetJustifyH("LEFT")
    rFrame.name = name
    
    local flag = rFrame:CreateTexture(nil, "ARTWORK")
    flag:SetSize(14, 10)
    rFrame.flag = flag
    
    local reg = rFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reg:SetJustifyH("RIGHT")
    rFrame.reg = reg
    
    reg:SetPoint("RIGHT", rFrame, "RIGHT", -4, 0)
    flag:SetPoint("RIGHT", reg, "LEFT", -6, 0)
    
    rFrame:SetScript("OnEnter", function(self)
        if db then
            bg:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, 0.20)
        else
            bg:SetColorTexture(0.25, 0.25, 0.45, 0.20)
        end
        bg:Show()
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cffFFD100" .. (self.realmName or "") .. "|r")
        
        -- Display characters on this realm
        if db and db.characters and db.characters[self.realmName] then
            local hasChars = false
            for charName, data in pairs(db.characters[self.realmName]) do
                if not hasChars then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Your Characters:", 1, 0.82, 0)
                    hasChars = true
                end
                GameTooltip:AddLine(GetCharacterTooltipLine(charName, data), 0.9, 0.9, 0.9)
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to insert name into chat.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift-Click to link all connected realms.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    rFrame:SetScript("OnLeave", function(self)
        bg:Hide()
        GameTooltip:Hide()
    end)
    
    rFrame:SetScript("OnClick", function(self)
        if not self.realmName then return end
        if IsShiftKeyDown() then
            -- Insert the entire connected realm cluster
            local currentRealm, connected = BuildRealmData()
            local activeRealm = db.activeRealm or currentRealm
            local allRealms = { activeRealm }
            for _, r in ipairs(connected) do
                table.insert(allRealms, r)
            end
            table.sort(allRealms)
            local listStr = table.concat(allRealms, ", ")
            
            if not ChatEdit_InsertLink(listStr) then
                print("|cffFFD100Connected Realms:|r " .. listStr)
            end
        else
            -- Insert just this single realm name
            if not ChatEdit_InsertLink(self.realmName) then
                print("|cffFFD100Realm:|r " .. self.realmName)
            end
        end
    end)
    
    rows[index] = rFrame
    return rFrame
end

-- 8f. SEPARATOR 2 (above footer) — positioned dynamically
local sep2 = frame:CreateTexture(nil, "BACKGROUND")
sep2:SetHeight(SEP_H)
sep2:SetColorTexture(0.25, 0.25, 0.45, 0.8)

-- 8g. FOOTER
local footerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
footerText:SetJustifyH("LEFT")

local footerFlags = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
footerFlags:SetJustifyH("RIGHT")

local footerBtn = CreateFrame("Button", nil, frame)
footerBtn:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 0, -2)
footerBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
footerBtn:SetScript("OnClick", function()
    if db and db.activeRealm then
        db.activeRealm = nil
        PlaySound(569651) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON / default sound
        RealmDisplayFrame_Update()
    end
end)
footerBtn:SetScript("OnEnter", function(self)
    if db and db.activeRealm then
        footerText:SetTextColor(1, 0.82, 0)
        footerFlags:SetTextColor(1, 0.82, 0)
    end
end)
footerBtn:SetScript("OnLeave", function(self)
    if db then
        footerText:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
        footerFlags:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
    end
end)

-- ============================================================
-- 9. DROPDOWN SEARCH PANEL
-- ============================================================
local dropPanel = CreateFrame("Frame", "RealmDisplayDropPanel", UIParent, "BackdropTemplate")
dropPanel:SetWidth(PANEL_W - 12)
dropPanel:SetFrameStrata("DIALOG")
dropPanel:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
dropPanel:SetBackdropColor(0.06, 0.06, 0.14, 0.98)
dropPanel:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
dropPanel:Hide()

local searchBox = CreateFrame("EditBox", nil, dropPanel, "BackdropTemplate")
searchBox:SetHeight(20)
searchBox:SetPoint("TOPLEFT",  dropPanel, "TOPLEFT",   8, -6)
searchBox:SetPoint("TOPRIGHT", dropPanel, "TOPRIGHT", -8, -6)
searchBox:SetAutoFocus(false)
searchBox:SetMaxLetters(64)
searchBox:SetTextInsets(6, 6, 0, 0)
searchBox:SetFontObject("GameFontHighlightSmall")

searchBox:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})

function UpdateSearchBoxVisuals()
    if not db then return end
    local isLight = (db.bgColorR > 0.5)
    if isLight then
        searchBox:SetBackdropColor(0.88, 0.88, 0.90, 1)
        searchBox:SetBackdropBorderColor(0.70, 0.70, 0.75, 1)
        searchBox:SetTextColor(0.1, 0.1, 0.1)
    else
        searchBox:SetBackdropColor(0.03, 0.03, 0.07, 1)
        searchBox:SetBackdropBorderColor(0.20, 0.20, 0.35, 1)
        searchBox:SetTextColor(0.9, 0.9, 0.9)
    end
end

searchBox:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
end)
searchBox:SetScript("OnEditFocusLost", function(self)
    UpdateSearchBoxVisuals()
end)

local searchHint = dropPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchHint:SetPoint("LEFT", searchBox, "LEFT", 8, 0)
searchHint:SetText("Search realms...")

searchBox:SetScript("OnTextChanged", function(self)
    searchHint:SetShown(self:GetText() == "")
    RealmDisplayDropPanel_Filter(self:GetText())
end)
searchBox:SetScript("OnEscapePressed", function() dropPanel:Hide() end)

local scrollFrame = CreateFrame("ScrollFrame", "RealmDisplayScrollFrame", dropPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",     dropPanel, "TOPLEFT",    4, -54)
scrollFrame:SetPoint("BOTTOMRIGHT", dropPanel, "BOTTOMRIGHT", -12, 4)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxVal = self:GetVerticalScrollRange()
    local newVal = cur - (delta * 18)
    newVal = math.max(0, math.min(newVal, maxVal))
    self:SetVerticalScroll(newVal)
end)

-- Skin the scrollbar
local scrollBar = _G["RealmDisplayScrollFrameScrollBar"]
if scrollBar then
    local upBtn = _G["RealmDisplayScrollFrameScrollBarScrollUpButton"]
    local downBtn = _G["RealmDisplayScrollFrameScrollBarScrollDownButton"]
    if upBtn then
        upBtn:Hide()
        upBtn.Show = function() end
    end
    if downBtn then
        downBtn:Hide()
        downBtn.Show = function() end
    end

    local thumb = _G["RealmDisplayScrollFrameScrollBarThumbTexture"] or scrollBar:GetThumbTexture()
    for _, region in ipairs({scrollBar:GetRegions()}) do
        if region:IsObjectType("Texture") and region ~= thumb then
            region:Hide()
        end
    end

    if thumb then
        thumb:SetColorTexture(0.20, 0.20, 0.40, 0.8)
        thumb:SetSize(6, 24)
    end

    local trackBg = scrollBar:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("TOPLEFT", scrollBar, "TOPLEFT", 0, 0)
    trackBg:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMRIGHT", 0, 0)
    trackBg:SetColorTexture(0.08, 0.08, 0.16, 0.4)
    scrollBar.trackBg = trackBg

    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPRIGHT", dropPanel, "TOPRIGHT", -4, -54)
    scrollBar:SetPoint("BOTTOMRIGHT", dropPanel, "BOTTOMRIGHT", -4, 4)
    scrollBar:SetWidth(6)
end

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(PANEL_W - 28)
scrollChild:SetHeight(1)
scrollFrame:SetScrollChild(scrollChild)

local realmButtons = {}

local function GetOrCreateRealmButton(index)
    if realmButtons[index] then return realmButtons[index] end
    local btn = CreateFrame("Button", nil, scrollChild)
    btn:SetHeight(20)
    
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("LEFT",  btn, "LEFT",  12, 0)
    lbl:SetJustifyH("LEFT")
    btn.label = lbl
    
    local reg = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reg:SetJustifyH("RIGHT")
    reg:Hide()
    btn.reg = reg
    
    local flag = btn:CreateTexture(nil, "ARTWORK")
    flag:SetSize(14, 10)
    flag:SetPoint("RIGHT", btn, "RIGHT", -36, 0)
    btn.flag = flag
    
    btn:SetScript("OnEnter", function(self)
        if db and db.bgColorR > 0.5 then
            lbl:SetTextColor(db.accentColorR * 0.7, db.accentColorG * 0.7, db.accentColorB * 0.7, 1)
        else
            lbl:SetTextColor(1, 0.85, 0, 1)
        end
        
        -- Show tooltip for dropdown realms if characters exist
        if db and db.characters and db.characters[self.realmName] then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cffFFD100" .. self.realmName .. "|r")
            GameTooltip:AddLine("Your Characters:", 1, 0.82, 0)
            for charName, data in pairs(db.characters[self.realmName]) do
                GameTooltip:AddLine(GetCharacterTooltipLine(charName, data), 0.9, 0.9, 0.9)
            end
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if db then
            lbl:SetTextColor(db.textColorR, db.textColorG, db.textColorB, 1)
        else
            lbl:SetTextColor(0.8, 0.8, 0.8, 1)
        end
        GameTooltip:Hide()
    end)
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

-- allDropRealms holds the full realm list for the dropdown
local allDropRealms = {}
local sortColumn = "name"
local sortAscending = true

local function SortRealmList()
    table.sort(allDropRealms, function(a, b)
        local valA, valB
        if sortColumn == "name" then
            valA, valB = a:lower(), b:lower()
        elseif sortColumn == "locale" then
            valA, valB = GetRealmLocale(a):lower(), GetRealmLocale(b):lower()
            if valA == valB then
                return a:lower() < b:lower()
            end
        end
        if sortAscending then
            return valA < valB
        else
            return valA > valB
        end
    end)
end

-- Sorting Header Bar
local sortHeader = CreateFrame("Frame", nil, dropPanel)
sortHeader:SetSize(PANEL_W - 12, 16)
sortHeader:SetPoint("TOPLEFT", dropPanel, "TOPLEFT", 0, -32)

local function CreateSortHeaderButton(text, align)
    local btn = CreateFrame("Button", nil, sortHeader)
    btn:SetHeight(16)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if align == "LEFT" then
        lbl:SetPoint("LEFT", btn, "LEFT", 0, 0)
    elseif align == "RIGHT" then
        lbl:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
    else
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
    end
    btn:SetFontString(lbl)
    btn.lbl = lbl
    
    btn:SetScript("OnEnter", function()
        if db and db.bgColorR > 0.5 then
            lbl:SetTextColor(db.accentColorR * 0.7, db.accentColorG * 0.7, db.accentColorB * 0.7, 1)
        else
            lbl:SetTextColor(1, 0.85, 0, 1)
        end
    end)
    btn:SetScript("OnLeave", function()
        local isCurrent = (sortColumn == "name" and text == "Name") or 
                          (sortColumn == "locale" and text == "Lang")
        if isCurrent then
            if db then
                lbl:SetTextColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
            else
                lbl:SetTextColor(1, 0.82, 0, 1)
            end
        else
            lbl:SetTextColor(0.5, 0.5, 0.5, 1)
        end
    end)
    return btn
end

local headerName = CreateSortHeaderButton("Name", "LEFT")
headerName:SetWidth(80)
headerName:SetPoint("LEFT", sortHeader, "LEFT", 12, 0)

local headerLang = CreateSortHeaderButton("Lang", "RIGHT")
headerLang:SetWidth(60)
headerLang:SetPoint("RIGHT", sortHeader, "RIGHT", -36, 0)

local function UpdateSortHeaders()
    if not db then return end
    local isLight = (db.bgColorR > 0.5)
    
    local activeColor, inactiveColor, arrowColor
    if isLight then
        activeColor   = "|cff111122" -- Dark charcoal
        inactiveColor = "|cff888888" -- Muted grey
        arrowColor    = "|cff4444cc" -- Vibrant blue
    else
        activeColor   = "|cffffffff" -- Pure white
        inactiveColor = "|cff555566" -- Medium-dark grey
        arrowColor    = "|cffffd100" -- Bright gold
    end
    
    local nameText = "Name"
    if sortColumn == "name" then
        nameText = activeColor .. "Name|r" .. arrowColor .. (sortAscending and " ^" or " v") .. "|r"
    else
        nameText = inactiveColor .. "Name|r"
    end
    
    local langText = "Lang"
    if sortColumn == "locale" then
        langText = activeColor .. "Lang|r" .. arrowColor .. (sortAscending and " ^" or " v") .. "|r"
    else
        langText = inactiveColor .. "Lang|r"
    end
    
    headerName.lbl:SetText(nameText)
    headerLang.lbl:SetText(langText)
end

headerName:SetScript("OnClick", function()
    if sortColumn == "name" then
        sortAscending = not sortAscending
    else
        sortColumn = "name"
        sortAscending = true
    end
    SortRealmList()
    UpdateSortHeaders()
    RealmDisplayDropPanel_Filter(searchBox:GetText())
end)

headerLang:SetScript("OnClick", function()
    if sortColumn == "locale" then
        sortAscending = not sortAscending
    else
        sortColumn = "locale"
        sortAscending = true
    end
    SortRealmList()
    UpdateSortHeaders()
    RealmDisplayDropPanel_Filter(searchBox:GetText())
end)

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
            
            local isLight = (db and db.bgColorR > 0.5)
            local shadowEnabled = not isLight

            local charCount = 0
            if db and db.characters and db.characters[r] then
                for _, _ in pairs(db.characters[r]) do
                    charCount = charCount + 1
                end
            end
            if charCount > 0 then
                btn.label:SetText(r .. string.format(" |cffffd100(%d)|r", charCount))
            else
                btn.label:SetText(r)
            end
            
            if db then
                btn.label:SetTextColor(db.textColorR, db.textColorG, db.textColorB, 1)
            else
                btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
            end
            btn.flag:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Flags\\" .. locale .. ".png")
            btn.reg:SetText(GetRegionFlag(region))
            
            SetFontStringShadow(btn.label, shadowEnabled)
            SetFontStringShadow(btn.reg, shadowEnabled)
            
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
        dropPanel:SetHeight(58 + maxRows * 20 + 6)
        dropPanel:Show()
        searchBox:SetFocus()
        UpdateSortHeaders()
        RealmDisplayDropPanel_Filter(searchBox:GetText())
    end
end)

local clickCatcher = CreateFrame("Frame", nil, UIParent)
clickCatcher:SetAllPoints()
clickCatcher:SetFrameStrata("HIGH")
clickCatcher:Hide()
clickCatcher:SetScript("OnMouseDown", function()
    dropPanel:Hide()
    clickCatcher:Hide()
end)
dropPanel:SetScript("OnShow", function() clickCatcher:Show() end)
dropPanel:SetScript("OnHide", function() clickCatcher:Hide() end)

-- ============================================================
-- 9b. APPEARANCE CONFIG PANEL
-- ============================================================
local FONT_LIST = {
    { label = "Friz Quadrata",  path = "Fonts\\FRIZQT__.TTF"  },
    { label = "Arial Narrow",   path = "Fonts\\ARIALN.TTF"    },
    { label = "Morpheus",       path = "Fonts\\MORPHEUS.TTF"  },
    { label = "Skurri",         path = "Fonts\\SKURRI.TTF"    },
}

local function GetFontsList()
    local fonts = {}
    local defaultFonts = {
        { label = "Friz Quadrata",  path = "Fonts\\FRIZQT__.TTF"  },
        { label = "Arial Narrow",   path = "Fonts\\ARIALN.TTF"    },
        { label = "Morpheus",       path = "Fonts\\MORPHEUS.TTF"  },
        { label = "Skurri",         path = "Fonts\\SKURRI.TTF"    },
    }
    
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local lsmFonts = LSM:List("font")
        if lsmFonts and #lsmFonts > 0 then
            for _, name in ipairs(lsmFonts) do
                local path = LSM:Fetch("font", name)
                if path then
                    table.insert(fonts, { label = name, path = path })
                end
            end
        end
    end
    
    if #fonts == 0 then
        fonts = defaultFonts
    end
    
    table.sort(fonts, function(a, b) return a.label:lower() < b.label:lower() end)
    return fonts
end

local function OpenColorPicker(r, g, b, a, onChangeCallback, onCancelCallback)
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r           = r,
            g           = g,
            b           = b,
            opacity     = a and (1 - a) or nil,
            hasOpacity  = (a ~= nil),
            swatchFunc  = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                onChangeCallback(nr, ng, nb, na)
            end,
            cancelFunc  = function(prev)
                if onCancelCallback then onCancelCallback(prev) end
            end,
        })
    else
        ColorPickerFrame.func        = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na = 1 - OpacitySliderFrame:GetValue()
            onChangeCallback(nr, ng, nb, na)
        end
        ColorPickerFrame.cancelFunc  = function()
            if onCancelCallback then onCancelCallback(nil) end
        end
        ColorPickerFrame.hasOpacity  = (a ~= nil)
        ColorPickerFrame.opacity     = a and (1 - a) or 0
        ColorPickerFrame:SetColorRGB(r, g, b)
        ShowUIPanel(ColorPickerFrame)
    end
end

local function StyleFlatButton(btn)
    btn:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.10, 0.10, 0.18, 0.95)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.55, 0.8)
    
    local text = btn:GetFontString()
    if not text then
        text = btn:CreateFontString(nil, "OVERLAY")
        text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn:SetFontString(text)
    end
    text:SetFontObject("GameFontNormalSmall")
    text:SetTextColor(0.85, 0.85, 0.85)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.28, 1)
        if db then
            self:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.10, 0.18, 0.95)
        if db then
            self:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
        end
    end)
end

local configFrame = CreateFrame("Frame", "RealmDisplayConfigFrame", UIParent, "BackdropTemplate")
configFrame:SetSize(220, 390)
configFrame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
configFrame:SetBackdropColor(0.04, 0.04, 0.10, 0.98)
configFrame:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
configFrame:Hide()

local cfgTitle = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cfgTitle:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -8)
cfgTitle:SetText("Addon Settings")

local closeBtn2 = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
closeBtn2:SetSize(18, 18)
closeBtn2:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -8, -8)
closeBtn2:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
closeBtn2:SetBackdropColor(0.15, 0.15, 0.25, 1)

local closeText2 = closeBtn2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeText2:SetPoint("CENTER")
closeText2:SetText("X")
closeText2:SetTextColor(0.8, 0.8, 0.8)

closeBtn2:SetScript("OnEnter", function()
    closeText2:SetTextColor(1, 0.2, 0.2)
    closeBtn2:SetBackdropColor(0.25, 0.15, 0.15, 1)
end)
closeBtn2:SetScript("OnLeave", function()
    closeText2:SetTextColor(0.8, 0.8, 0.8)
    closeBtn2:SetBackdropColor(0.15, 0.15, 0.25, 1)
end)
closeBtn2:SetScript("OnClick", function() configFrame:Hide() end)

-- Font selection row
local fontLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fontLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -38)
fontLabel:SetText("Font:")

local fontDropBtn = CreateFrame("Button", "RealmDisplayFontDropBtn", configFrame, "BackdropTemplate")
fontDropBtn:SetSize(150, 20)
fontDropBtn:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)
fontDropBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
fontDropBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
fontDropBtn:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)

local fontDropLabel = fontDropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fontDropLabel:SetPoint("LEFT", fontDropBtn, "LEFT", 6, 0)
fontDropLabel:SetPoint("RIGHT", fontDropBtn, "RIGHT", -16, 0)
fontDropLabel:SetJustifyH("LEFT")
fontDropLabel:SetWordWrap(false)

local fontDropChevron = fontDropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fontDropChevron:SetPoint("RIGHT", fontDropBtn, "RIGHT", -4, 0)
fontDropChevron:SetText("|cff888888v|r")

-- Font Dropdown Search Panel
local fontDropPanel = CreateFrame("Frame", "RealmDisplayFontDropPanel", UIParent, "BackdropTemplate")
fontDropPanel:SetSize(180, 200)
fontDropPanel:SetFrameStrata("DIALOG")
fontDropPanel:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
fontDropPanel:SetBackdropColor(0.06, 0.06, 0.14, 0.98)
fontDropPanel:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
fontDropPanel:Hide()

local fontSearchBox = CreateFrame("EditBox", nil, fontDropPanel, "InputBoxTemplate")
fontSearchBox:SetHeight(20)
fontSearchBox:SetPoint("TOPLEFT",  fontDropPanel, "TOPLEFT",   8, -6)
fontSearchBox:SetPoint("TOPRIGHT", fontDropPanel, "TOPRIGHT", -8, -6)
fontSearchBox:SetAutoFocus(false)
fontSearchBox:SetMaxLetters(64)

local fontSearchHint = fontDropPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
fontSearchHint:SetPoint("LEFT", fontSearchBox, "LEFT", 4, 0)
fontSearchHint:SetText("Search fonts...")

fontSearchBox:SetScript("OnTextChanged", function(self)
    fontSearchHint:SetShown(self:GetText() == "")
    RealmDisplayFontDropPanel_Filter(self:GetText())
end)
fontSearchBox:SetScript("OnEscapePressed", function() fontDropPanel:Hide() end)

local fontScrollFrame = CreateFrame("ScrollFrame", "RealmDisplayFontScrollFrame", fontDropPanel, "UIPanelScrollFrameTemplate")
fontScrollFrame:SetPoint("TOPLEFT",     fontDropPanel, "TOPLEFT",    4, -30)
fontScrollFrame:SetPoint("BOTTOMRIGHT", fontDropPanel, "BOTTOMRIGHT", -12, 4)
fontScrollFrame:EnableMouseWheel(true)
fontScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxVal = self:GetVerticalScrollRange()
    local newVal = cur - (delta * 18)
    newVal = math.max(0, math.min(newVal, maxVal))
    self:SetVerticalScroll(newVal)
end)

-- Skin scrollbar
local fontScrollBar = _G["RealmDisplayFontScrollFrameScrollBar"]
if fontScrollBar then
    local upBtn = _G["RealmDisplayFontScrollFrameScrollBarScrollUpButton"]
    local downBtn = _G["RealmDisplayFontScrollFrameScrollBarScrollDownButton"]
    if upBtn then
        upBtn:Hide()
        upBtn.Show = function() end
    end
    if downBtn then
        downBtn:Hide()
        downBtn.Show = function() end
    end
    local thumb = _G["RealmDisplayFontScrollFrameScrollBarThumbTexture"] or fontScrollBar:GetThumbTexture()
    for _, r in ipairs({fontScrollBar:GetRegions()}) do
        if r:IsObjectType("Texture") and r ~= thumb then r:Hide() end
    end
    if thumb then
        thumb:SetColorTexture(0.20, 0.20, 0.40, 0.8)
        thumb:SetSize(6, 24)
    end
    fontScrollBar:ClearAllPoints()
    fontScrollBar:SetPoint("TOPRIGHT", fontDropPanel, "TOPRIGHT", -4, -30)
    fontScrollBar:SetPoint("BOTTOMRIGHT", fontDropPanel, "BOTTOMRIGHT", -4, 4)
    fontScrollBar:SetWidth(6)
end

local fontScrollChild = CreateFrame("Frame", nil, fontScrollFrame)
fontScrollChild:SetWidth(160)
fontScrollChild:SetHeight(1)
fontScrollFrame:SetScrollChild(fontScrollChild)

local fontButtons = {}
local function GetOrCreateFontButton(index)
    if fontButtons[index] then return fontButtons[index] end
    local btn = CreateFrame("Button", nil, fontScrollChild)
    btn:SetHeight(20)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("LEFT",  btn, "LEFT",  4, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    lbl:SetJustifyH("LEFT")
    btn.label = lbl
    btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 0.85, 0, 1) end)
    btn:SetScript("OnLeave", function() lbl:SetTextColor(0.8, 0.8, 0.8, 1) end)
    btn:SetScript("OnClick", function(self)
        db.fontPath = self.fontPath
        fontDropPanel:Hide()
        fontSearchBox:SetText("")
        fontSearchHint:Show()
        UpdateConfigPanelFields()
        RealmDisplayFrame_Update()
    end)
    fontButtons[index] = btn
    return btn
end

function RealmDisplayFontDropPanel_Filter(query)
    query = (query or ""):lower()
    local list = GetFontsList()
    local y = 0
    local count = 0
    for _, f in ipairs(list) do
        if query == "" or f.label:lower():find(query, 1, true) then
            count = count + 1
            local btn = GetOrCreateFontButton(count)
            btn.fontPath = f.path
            btn.label:SetText(f.label)
            btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
            btn.label:SetFont(f.path, 11, "")
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT",  fontScrollChild, "TOPLEFT",  0, -y)
            btn:SetPoint("TOPRIGHT", fontScrollChild, "TOPRIGHT", 0, -y)
            btn:Show()
            y = y + 20
        end
    end
    for i = count + 1, #fontButtons do fontButtons[i]:Hide() end
    fontScrollChild:SetHeight(math.max(y, 1))
    fontScrollFrame:SetVerticalScroll(0)
end

fontDropBtn:SetScript("OnClick", function()
    if fontDropPanel:IsShown() then
        fontDropPanel:Hide()
    else
        fontDropPanel:ClearAllPoints()
        fontDropPanel:SetPoint("TOPLEFT", fontDropBtn, "BOTTOMLEFT", 0, -2)
        fontDropPanel:SetPoint("TOPRIGHT", fontDropBtn, "BOTTOMRIGHT", 0, -2)
        fontDropPanel:Show()
        fontSearchBox:SetFocus()
        fontSearchBox:SetText("")
        RealmDisplayFontDropPanel_Filter("")
    end
end)

-- Font Size row (Custom Flat Slider)
local sizeSlider = CreateFrame("Slider", "RealmDisplaySizeSlider", configFrame, "BackdropTemplate")
sizeSlider:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -75)
sizeSlider:SetSize(190, 8)
sizeSlider:SetOrientation("HORIZONTAL")
sizeSlider:SetMinMaxValues(8, 20)
sizeSlider:SetValueStep(1)
sizeSlider:SetObeyStepOnDrag(true)

sizeSlider:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
sizeSlider:SetBackdropColor(0.08, 0.08, 0.16, 1)
sizeSlider:SetBackdropBorderColor(0.2, 0.2, 0.3, 0.8)

local sizeThumb = sizeSlider:CreateTexture(nil, "ARTWORK")
sizeThumb:SetSize(12, 16)
sizeThumb:SetColorTexture(0.3, 0.3, 0.55, 1)
sizeSlider:SetThumbTexture(sizeThumb)

local sizeText = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sizeText:SetPoint("BOTTOMLEFT", sizeSlider, "TOPLEFT", 0, 4)

-- Background Color row (with border)
local bgBorder = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
bgBorder:SetSize(18, 18)
bgBorder:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -115)
bgBorder:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1 })
bgBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

local bgSwatch = bgBorder:CreateTexture(nil, "ARTWORK")
bgSwatch:SetSize(16, 16)
bgSwatch:SetPoint("CENTER")

local bgBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
bgBtn:SetSize(166, 22)
bgBtn:SetPoint("LEFT", bgBorder, "RIGHT", 8, 0)
StyleFlatButton(bgBtn)
bgBtn:SetText("Background Color")

-- Text Color row (with border)
local textBorder = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
textBorder:SetSize(18, 18)
textBorder:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -150)
textBorder:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1 })
textBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

local textSwatch = textBorder:CreateTexture(nil, "ARTWORK")
textSwatch:SetSize(16, 16)
textSwatch:SetPoint("CENTER")

local textBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
textBtn:SetSize(166, 22)
textBtn:SetPoint("LEFT", textBorder, "RIGHT", 8, 0)
StyleFlatButton(textBtn)
textBtn:SetText("Text Color")

-- Accent/Theme Color row (with border)
local accentBorder = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
accentBorder:SetSize(18, 18)
accentBorder:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -185)
accentBorder:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1 })
accentBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

local accentSwatch = accentBorder:CreateTexture(nil, "ARTWORK")
accentSwatch:SetSize(16, 16)
accentSwatch:SetPoint("CENTER")

local accentBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
accentBtn:SetSize(166, 22)
accentBtn:SetPoint("LEFT", accentBorder, "RIGHT", 8, 0)
StyleFlatButton(accentBtn)
accentBtn:SetText("Accent/Theme Color")

local DISPLAY_MODE_LABELS = {
    ALL       = "Name, Level, Gold, Profession",
    NO_NAME   = "Level, Gold, Profession",
    NO_LEVEL  = "Name, Gold, Profession",
    NO_GOLD   = "Name, Level, Profession",
    NO_PROF   = "Name, Level, Gold",
    NAME_LVL  = "Name, Level",
    NAME_GOLD = "Name, Gold",
    NAME_PROF = "Name, Profession",
    LVL_GOLD  = "Level, Gold",
    LVL_PROF  = "Level, Profession",
    GOLD_PROF = "Gold, Profession",
    NAME      = "Name Only",
    LVL       = "Level Only",
    GOLD      = "Gold Only",
    PROF      = "Profession Only",
}

local DISPLAY_MODE_KEYS = {
    "ALL", "NO_NAME", "NO_LEVEL", "NO_GOLD", "NO_PROF",
    "NAME_LVL", "NAME_GOLD", "NAME_PROF", "LVL_GOLD", "LVL_PROF", "GOLD_PROF",
    "NAME", "LVL", "GOLD", "PROF"
}

local function CreateConfigCheckbox(name, labelText, parent, y, dbKey, onClickCallback)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, y)
    
    local text = _G[name .. "Text"]
    if text then
        text:SetText(labelText)
        text:SetFontObject("GameFontNormalSmall")
    end
    
    cb:SetScript("OnClick", function(self)
        local checked = not not self:GetChecked()
        if db then
            db[dbKey] = checked
        end
        if onClickCallback then
            onClickCallback(checked)
        end
        PlaySound(856) -- sound
    end)
    return cb
end

local trackCB = CreateConfigCheckbox("RealmDisplayTrackCB", "Track Characters (Alts)", configFrame, -220, "trackCharacters", function(val)
    if val then
        UpdateActiveCharacterCache()
    end
    UpdateConfigPanelFields()
end)

local charLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
charLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -252)
charLabel:SetText("Details:")

local charDropBtn = CreateFrame("Button", "RealmDisplayCharDropBtn", configFrame, "BackdropTemplate")
charDropBtn:SetSize(140, 20)
charDropBtn:SetPoint("LEFT", charLabel, "RIGHT", 10, 0)
charDropBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
charDropBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
charDropBtn:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)

local charDropLabel = charDropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
charDropLabel:SetPoint("LEFT", charDropBtn, "LEFT", 6, 0)
charDropLabel:SetPoint("RIGHT", charDropBtn, "RIGHT", -16, 0)
charDropLabel:SetJustifyH("LEFT")
charDropLabel:SetWordWrap(false)

local charDropChevron = charDropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
charDropChevron:SetPoint("RIGHT", charDropBtn, "RIGHT", -4, 0)
charDropChevron:SetText("|cff888888v|r")

local charDropPanel = CreateFrame("Frame", "RealmDisplayCharDropPanel", UIParent, "BackdropTemplate")
charDropPanel:SetSize(185, 220)
charDropPanel:SetFrameStrata("DIALOG")
charDropPanel:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
})
charDropPanel:SetBackdropColor(0.06, 0.06, 0.14, 0.98)
charDropPanel:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
charDropPanel:Hide()

local charScrollFrame = CreateFrame("ScrollFrame", "RealmDisplayCharScrollFrame", charDropPanel, "UIPanelScrollFrameTemplate")
charScrollFrame:SetPoint("TOPLEFT",     charDropPanel, "TOPLEFT",    4, -4)
charScrollFrame:SetPoint("BOTTOMRIGHT", charDropPanel, "BOTTOMRIGHT", -12, 4)
charScrollFrame:EnableMouseWheel(true)
charScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxVal = self:GetVerticalScrollRange()
    local newVal = cur - (delta * 18)
    newVal = math.max(0, math.min(newVal, maxVal))
    self:SetVerticalScroll(newVal)
end)

local charScrollBar = _G["RealmDisplayCharScrollFrameScrollBar"]
if charScrollBar then
    local upBtn = _G["RealmDisplayCharScrollFrameScrollBarScrollUpButton"]
    local downBtn = _G["RealmDisplayCharScrollFrameScrollBarScrollDownButton"]
    if upBtn then upBtn:Hide(); upBtn.Show = function() end end
    if downBtn then downBtn:Hide(); downBtn.Show = function() end end
    local thumb = _G["RealmDisplayCharScrollFrameScrollBarThumbTexture"] or charScrollBar:GetThumbTexture()
    for _, r in ipairs({charScrollBar:GetRegions()}) do
        if r:IsObjectType("Texture") and r ~= thumb then r:Hide() end
    end
    if thumb then
        thumb:SetColorTexture(0.20, 0.20, 0.40, 0.8)
        thumb:SetSize(6, 24)
    end
    charScrollBar:ClearAllPoints()
    charScrollBar:SetPoint("TOPRIGHT", charDropPanel, "TOPRIGHT", -4, -4)
    charScrollBar:SetPoint("BOTTOMRIGHT", charDropPanel, "BOTTOMRIGHT", -4, 4)
    charScrollBar:SetWidth(6)
end

local charScrollChild = CreateFrame("Frame", nil, charScrollFrame)
charScrollChild:SetWidth(165)
charScrollChild:SetHeight(1)
charScrollFrame:SetScrollChild(charScrollChild)

local charButtons = {}
local function GetOrCreateCharButton(index)
    if charButtons[index] then return charButtons[index] end
    local btn = CreateFrame("Button", nil, charScrollChild)
    btn:SetHeight(20)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("LEFT",  btn, "LEFT",  4, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)
    btn.label = lbl
    btn:SetScript("OnEnter", function() lbl:SetTextColor(1, 0.85, 0, 1) end)
    btn:SetScript("OnLeave", function() lbl:SetTextColor(0.8, 0.8, 0.8, 1) end)
    btn:SetScript("OnClick", function(self)
        db.charDisplayMode = self.modeValue
        charDropPanel:Hide()
        UpdateConfigPanelFields()
        RealmDisplayFrame_Update()
    end)
    charButtons[index] = btn
    return btn
end

local function PopulateCharDropPanel()
    local y = 0
    for idx, key in ipairs(DISPLAY_MODE_KEYS) do
        local btn = GetOrCreateCharButton(idx)
        btn.modeValue = key
        btn.label:SetText(DISPLAY_MODE_LABELS[key])
        btn.label:SetTextColor(0.8, 0.8, 0.8, 1)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT",  charScrollChild, "TOPLEFT",  0, -y)
        btn:SetPoint("TOPRIGHT", charScrollChild, "TOPRIGHT", 0, -y)
        btn:Show()
        y = y + 20
    end
    charScrollChild:SetHeight(y)
end

charDropBtn:SetScript("OnClick", function()
    if not db.trackCharacters then return end
    if charDropPanel:IsShown() then
        charDropPanel:Hide()
    else
        charDropPanel:ClearAllPoints()
        charDropPanel:SetPoint("TOPLEFT", charDropBtn, "BOTTOMLEFT", 0, -2)
        charDropPanel:SetPoint("TOPRIGHT", charDropBtn, "BOTTOMRIGHT", 0, -2)
        charDropPanel:Show()
        PopulateCharDropPanel()
    end
end)

charDropBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if db and not db.trackCharacters then
        GameTooltip:AddLine("Smart Details Dropdown", 1, 1, 1)
        GameTooltip:AddLine("Disabled because 'Track Characters' is unchecked.", 1, 0.2, 0.2)
        GameTooltip:AddLine("Check 'Track Characters (Alts)' above to customize display combinations.", 0.8, 0.8, 0.8)
    else
        GameTooltip:AddLine("Smart Details Dropdown", 1, 1, 1)
        GameTooltip:AddLine("Select which combination of details to show for your characters in hover tooltips.", 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
end)
charDropBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Reset Button
local resetBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
resetBtn:SetSize(190, 22)
resetBtn:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -300)
StyleFlatButton(resetBtn)
resetBtn:SetText("Reset to Defaults")

function UpdateConfigPanelFields()
    if not db then return end
    bgSwatch:SetColorTexture(db.bgColorR, db.bgColorG, db.bgColorB, db.bgColorA)
    textSwatch:SetColorTexture(db.textColorR, db.textColorG, db.textColorB, 1)
    accentSwatch:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, db.accentColorA)
    sizeSlider:SetValue(db.fontHeight)
    sizeText:SetText("Font Size: " .. db.fontHeight)
    if sizeThumb then
        sizeThumb:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end
    
    local fontName = "Friz Quadrata"
    local list = GetFontsList()
    for _, f in ipairs(list) do
        if f.path == db.fontPath then
            fontName = f.label
            break
        end
    end
    fontDropLabel:SetText(fontName)

    if RealmDisplayTrackCB then RealmDisplayTrackCB:SetChecked(db.trackCharacters) end
    
    local isLight = (db.bgColorR > 0.5)
    
    if db.trackCharacters then
        charDropBtn:Enable()
        if isLight then
            charDropBtn:SetBackdropColor(0.88, 0.88, 0.90, 1)
            charDropBtn:SetBackdropBorderColor(0.70, 0.70, 0.75, 1)
            charDropLabel:SetTextColor(0.1, 0.1, 0.1)
        else
            charDropBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
            charDropBtn:SetBackdropBorderColor(0.30, 0.30, 0.55, 1)
            charDropLabel:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
        end
        charDropChevron:SetTextColor(0.5, 0.5, 0.5)
        charLabel:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
    else
        charDropBtn:Disable()
        charDropPanel:Hide()
        if isLight then
            charDropBtn:SetBackdropColor(0.95, 0.95, 0.95, 0.6)
            charDropBtn:SetBackdropBorderColor(0.85, 0.85, 0.85, 0.5)
        else
            charDropBtn:SetBackdropColor(0.05, 0.05, 0.10, 0.5)
            charDropBtn:SetBackdropBorderColor(0.15, 0.15, 0.25, 0.5)
        end
        charDropLabel:SetTextColor(0.4, 0.4, 0.4)
        charDropChevron:SetTextColor(0.3, 0.3, 0.3)
        charLabel:SetTextColor(0.4, 0.4, 0.4)
    end
    
    charDropLabel:SetText(DISPLAY_MODE_LABELS[db.charDisplayMode] or "Name, Level, Gold, Profession")

    if charDropPanel then
        charDropPanel:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
        if isLight then
            charDropPanel:SetBackdropColor(0.92, 0.92, 0.94, 0.98)
        else
            charDropPanel:SetBackdropColor(0.06, 0.06, 0.14, 0.98)
        end
    end

    local charScrollThumb = _G["RealmDisplayCharScrollFrameScrollBarThumbTexture"]
    if charScrollThumb then
        if isLight then
            charScrollThumb:SetColorTexture(0.70, 0.70, 0.80, 0.8)
        else
            charScrollThumb:SetColorTexture(0.20, 0.20, 0.40, 0.8)
        end
    end
    
    local text = _G["RealmDisplayTrackCBText"]
    if text then
        text:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
    end
end

configFrame:SetScript("OnShow", UpdateConfigPanelFields)
configFrame:HookScript("OnHide", function()
    fontDropPanel:Hide()
    charDropPanel:Hide()
end)

sizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    db.fontHeight = value
    sizeText:SetText("Font Size: " .. value)
    RealmDisplayFrame_Update()
end)

bgBtn:SetScript("OnClick", function()
    local prevR, prevG, prevB, prevA = db.bgColorR, db.bgColorG, db.bgColorB, db.bgColorA

    OpenColorPicker(
        prevR, prevG, prevB, prevA,
        function(r, g, b, a)
            db.bgColorR = r
            db.bgColorG = g
            db.bgColorB = b
            if a ~= nil then db.bgColorA = 1 - a end
            bgSwatch:SetColorTexture(db.bgColorR, db.bgColorG, db.bgColorB, db.bgColorA)
            RealmDisplayFrame_Update()
        end,
        function()
            db.bgColorR, db.bgColorG, db.bgColorB, db.bgColorA = prevR, prevG, prevB, prevA
            bgSwatch:SetColorTexture(db.bgColorR, db.bgColorG, db.bgColorB, db.bgColorA)
            RealmDisplayFrame_Update()
        end
    )
end)

textBtn:SetScript("OnClick", function()
    local prevR, prevG, prevB = db.textColorR, db.textColorG, db.textColorB
    OpenColorPicker(
        prevR, prevG, prevB, nil,
        function(r, g, b)
            db.textColorR = r
            db.textColorG = g
            db.textColorB = b
            textSwatch:SetColorTexture(db.textColorR, db.textColorG, db.textColorB, 1)
            RealmDisplayFrame_Update()
        end,
        function()
            db.textColorR, db.textColorG, db.textColorB = prevR, prevG, prevB
            textSwatch:SetColorTexture(db.textColorR, db.textColorG, db.textColorB, 1)
            RealmDisplayFrame_Update()
        end
    )
end)

accentBtn:SetScript("OnClick", function()
    local prevR, prevG, prevB, prevA = db.accentColorR, db.accentColorG, db.accentColorB, db.accentColorA
    OpenColorPicker(
        prevR, prevG, prevB, prevA,
        function(r, g, b, a)
            db.accentColorR = r
            db.accentColorG = g
            db.accentColorB = b
            if a ~= nil then db.accentColorA = 1 - a end
            accentSwatch:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, db.accentColorA)
            RealmDisplayFrame_Update()
        end,
        function()
            db.accentColorR, db.accentColorG, db.accentColorB, db.accentColorA = prevR, prevG, prevB, prevA
            accentSwatch:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, db.accentColorA)
            RealmDisplayFrame_Update()
        end
    )
end)

resetBtn:SetScript("OnClick", function()
    db.fontHeight       = DEFAULTS.fontHeight
    db.fontPath         = DEFAULTS.fontPath
    db.bgColorR         = DEFAULTS.bgColorR
    db.bgColorG         = DEFAULTS.bgColorG
    db.bgColorB         = DEFAULTS.bgColorB
    db.bgColorA         = DEFAULTS.bgColorA
    db.textColorR       = DEFAULTS.textColorR
    db.textColorG       = DEFAULTS.textColorG
    db.textColorB       = DEFAULTS.textColorB
    db.accentColorR     = DEFAULTS.accentColorR
    db.accentColorG     = DEFAULTS.accentColorG
    db.accentColorB     = DEFAULTS.accentColorB
    db.accentColorA     = DEFAULTS.accentColorA
    db.trackCharacters  = DEFAULTS.trackCharacters
    db.charDisplayMode  = DEFAULTS.charDisplayMode
    UpdateConfigPanelFields()
    RealmDisplayFrame_Update()
end)

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
local function GetTextColorHex()
    if not db then return "ffffff" end
    local r = math.floor(db.textColorR * 255 + 0.5)
    local g = math.floor(db.textColorG * 255 + 0.5)
    local b = math.floor(db.textColorB * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

function RealmDisplayFrame_Update()
    if not db then return end

    -- Close button
    if closeTex then
        closeTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
    end

    -- Pin button
    if pinTex then
        if db.pinned then
            pinTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\lock.png")
            pinTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
        else
            pinTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\unlock.png")
            pinTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 0.6)
        end
    end
    -- Config button
    if cfgTex then
        cfgTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end
    -- Share button
    if shareTex then
        shareTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
    end
    -- Theme button
    if themeTex then
        if db.bgColorR < 0.5 then
            themeTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\theme_light.png")
        else
            themeTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\theme_dark.png")
        end
        themeTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end
    frame:SetMovable(not db.pinned)

    -- Dynamic styling updates
    local isLight = (db.bgColorR > 0.5)
    local shadowEnabled = not isLight

    frame:SetBackdropColor(db.bgColorR, db.bgColorG, db.bgColorB, db.bgColorA)
    frame:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    if headerBg then
        headerBg:SetColorTexture(db.accentColorR * 0.4, db.accentColorG * 0.4, db.accentColorB * 0.4, 1)
    end
    if sep1 then
        sep1:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
    end
    if sep2 then
        sep2:SetColorTexture(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
    end
    if dropBtn then
        dropBtn:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
        if isLight then
            dropBtn:SetBackdropColor(0.88, 0.88, 0.90, 1)
        else
            dropBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
        end
    end
    -- Snap button styling (matches dropdown)
    if snapBtn then
        snapBtn:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
        if isLight then
            snapBtn:SetBackdropColor(0.88, 0.88, 0.90, 1)
        else
            snapBtn:SetBackdropColor(0.10, 0.10, 0.20, 1)
        end
    end
    if snapTex then
        snapTex:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end

    if dropChevron then
        dropChevron:SetVertexColor(db.accentColorR, db.accentColorG, db.accentColorB, 0.8)
    end
    if dropPanel then
        dropPanel:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
        if isLight then
            dropPanel:SetBackdropColor(0.92, 0.92, 0.94, 0.98)
        else
            dropPanel:SetBackdropColor(0.06, 0.06, 0.14, 0.98)
        end
    end
    if RealmDisplayFontDropBtn then
        RealmDisplayFontDropBtn:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end
    if RealmDisplayFontDropPanel then
        RealmDisplayFontDropPanel:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end
    if RealmDisplayConfigFrame then
        RealmDisplayConfigFrame:SetBackdropBorderColor(db.accentColorR, db.accentColorG, db.accentColorB, 1)
    end

    local scrollThumb = _G["RealmDisplayScrollFrameScrollBarThumbTexture"]
    if scrollThumb then
        if isLight then
            scrollThumb:SetColorTexture(0.70, 0.70, 0.80, 0.8)
        else
            scrollThumb:SetColorTexture(0.20, 0.20, 0.40, 0.8)
        end
    end

    footerText:SetFont(db.fontPath, db.fontHeight - 1, "")
    footerFlags:SetFont(db.fontPath, db.fontHeight - 1, "")
    listHeader.text:SetFont(db.fontPath, db.fontHeight - 1, "")
    footerText:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
    footerFlags:SetTextColor(db.textColorR, db.textColorG, db.textColorB)
    
    local isLight = (db.bgColorR > 0.5)
    if isLight then
        listHeader.text:SetTextColor(db.accentColorR * 0.5, db.accentColorG * 0.5, db.accentColorB * 0.5, 1)
    else
        listHeader.text:SetTextColor(db.accentColorR * 1.6, db.accentColorG * 1.6, db.accentColorB * 1.6, 1)
    end

    SetFontStringShadow(dropLabel, shadowEnabled)
    SetFontStringShadow(dropSub, shadowEnabled)
    SetFontStringShadow(footerText, shadowEnabled)
    SetFontStringShadow(footerFlags, shadowEnabled)
    SetFontStringShadow(listHeader.text, shadowEnabled)

    local currentRealm, connected = BuildRealmData()
    local region = GetRegionTag()
    local activeRealm = db.activeRealm or currentRealm
    local activeIsHome = (not db.activeRealm) or (GetNormalizedName(db.activeRealm) == GetNormalizedName(currentRealm))

    -- Ping
    local _, _, latHome = GetNetStats()
    latHome = latHome or 0
    local pingText = ""
    if db.showPing then
        pingText = " |cff888888(|r" .. GetPingColor(latHome) .. latHome .. "ms|cff888888)|r"
    end

    -- List header text
    listHeader.text:SetText(string.format("Connected to: |cff%s%s|r  (|cffffd100%d|r)", GetTextColorHex(), activeRealm, #connected))

    -- ---- Snap button: shown beside dropdown only when browsing away from home ----
    if snapBtn then
        if activeIsHome then
            snapBtn:Hide()
            -- Dropdown spans full width when snap is hidden
            dropBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, Y_DROP_TOP)
        else
            snapBtn:Show()
            -- Shrink dropdown to leave room for snap button
            dropBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(6 + DROP_H + 4), Y_DROP_TOP)
        end
    end


    -- Dropdown button label (shows currently browsed realm)
    local activeLocale = GetRealmLocale(activeRealm)
    local pfx = (activeIsHome) and "|TInterface\\FriendsFrame\\StatusIcon-Online:10:10:0:-1|t " or "|TInterface\\FriendsFrame\\StatusIcon-Away:10:10:0:-1|t "
    dropLabel:SetText(pfx .. "|cff" .. GetTextColorHex() .. activeRealm .. "|r")
    if dropSub then
        dropSub:SetText(string.format("%s  %s", GetLocaleFlag(activeLocale), GetRegionFlag(region)))
    end

    -- Body: connected realms for the selected realm
    local y = Y_BODY_TOP
    for i, r in ipairs(connected) do
        local rFrame = GetOrCreateRow(i)
        rFrame.realmName = r
        rFrame:ClearAllPoints()
        rFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, y)
        
        local locale   = GetRealmLocale(r)
        local isActive = (r == db.activeRealm)

        rFrame.name:SetFont(db.fontPath, db.fontHeight, "")
        rFrame.name:SetText(r)
        rFrame.name:SetTextColor(
            isActive and 1 or db.textColorR,
            isActive and 0.82 or db.textColorG,
            isActive and 0 or db.textColorB
        )
        
        rFrame.flag:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Flags\\" .. locale .. ".png")
        
        rFrame.reg:SetFont(db.fontPath, db.fontHeight - 1, "")
        rFrame.reg:SetText(GetRegionFlag(region))

        SetFontStringShadow(rFrame.name, shadowEnabled)
        SetFontStringShadow(rFrame.reg, shadowEnabled)
        
        rFrame:Show()
        y = y - ROW_H
    end
    for i = #connected + 1, #rows do
        rows[i]:Hide()
    end

    local lineCount = #connected
    local listH     = lineCount * ROW_H

    -- Dynamic y positions below the body
    local sep2Y   = Y_BODY_TOP - listH - GAP
    local footY   = sep2Y - SEP_H - GAP
    local totalH  = math.abs(footY) + FOOTER_H + GAP

    sep2:ClearAllPoints()
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",   6, sep2Y)
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  -6, sep2Y)

    local yourLocale = GetRealmLocale(currentRealm)
    footerText:ClearAllPoints()
    footerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, footY)
    
    footerFlags:ClearAllPoints()
    footerFlags:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, footY)
    
    if activeIsHome then
        -- Home realm view
        local status = "|TInterface\\FriendsFrame\\StatusIcon-Online:10:10:0:-1|t "
        footerText:SetText(string.format("%sHome: |cff%s%s|r%s", 
            status, GetTextColorHex(), currentRealm, pingText
        ))
        footerFlags:SetText(string.format("%s %s", GetLocaleFlag(yourLocale), GetRegionFlag(region)))
        footerBtn:Disable()
    else
        -- Browsing another realm
        local snapText = "|TInterface\\Buttons\\UI-GroupLoot-Pass-Up:10:10:0:-1|t |cffFFD100Return Home|r: "
        footerText:SetText(string.format("%s%s%s", 
            snapText, currentRealm, pingText
        ))
        footerFlags:SetText(string.format("%s %s", GetLocaleFlag(yourLocale), GetRegionFlag(region)))
        footerBtn:Enable()
    end

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
            RealmDisplayFrame_Update()
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
            -- *** BUG FIX: always show the CHARACTER'S OWN realm in the tooltip,
            --     regardless of which realm is selected in the panel dropdown.
            tip:AddLine("|cffFFD100Realm Watch|r")
            tip:AddLine(" ")
            -- Use GetRealmName() directly so we always get the player's realm,
            -- never the browsed realm stored in db.activeRealm.
            local playerRealm = GetRealmName()
            tip:AddLine("|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:-1|t |cff44FF44" .. playerRealm .. "|r  |cff888888(your realm)|r")
            
            -- Pull live connected realms for the player's own realm only
            local seen = { [GetNormalizedName(playerRealm)] = true }
            local auto = GetAutoCompleteRealms()
            if auto then
                for _, r in ipairs(auto) do
                    local norm = GetNormalizedName(r)
                    if not seen[norm] then
                        seen[norm] = true
                        tip:AddLine("|cffCCCCCC  " .. GetProperRealmName(r) .. "|r")
                    end
                end
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

    else
        print("|cffFFD100RealmWatch commands:|r")
        print("  /rd toggle   — show/hide panel")
        print("  /rd reset    — reset panel position")
        print("  /rd home     — snap active realm back to yours")
        print("  /rd lock     — toggle position lock (pin)")
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
        db, Settings.VarType.Boolean, "Show Panel on Login", true
    )
    Settings.CreateCheckbox(optionsCategory, panelSetting,
        "Show the Realm Watch panel when you log in.")
    panelSetting:SetValueChangedCallback(function(_, value)
        db.showPanel = value
        frame:SetShown(value)
    end)

    local pingSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_Ping", "showPing",
        db, Settings.VarType.Boolean, "Show Ping", true
    )
    Settings.CreateCheckbox(optionsCategory, pingSetting,
        "Show network latency next to your realm name.")
    pingSetting:SetValueChangedCallback(function(_, value)
        db.showPing = value
        RealmDisplayFrame_Update()
    end)

    local pinSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_Pinned", "pinned",
        db, Settings.VarType.Boolean, "Lock Position", false
    )
    Settings.CreateCheckbox(optionsCategory, pinSetting,
        "Lock the panel's position to prevent dragging.")
    pinSetting:SetValueChangedCallback(function(_, value)
        db.pinned = value
        RealmDisplayFrame_Update()
    end)

    local minimapSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_Minimap", "hide",
        db.minimap, Settings.VarType.Boolean, "Hide Minimap Button", false
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

    local trackSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_TrackCharacters", "trackCharacters",
        db, Settings.VarType.Boolean, "Track Characters", true
    )
    Settings.CreateCheckbox(optionsCategory, trackSetting,
        "Automatically track and cache characters (alts) across realms.")
    trackSetting:SetValueChangedCallback(function(_, value)
        db.trackCharacters = value
        if value then
            UpdateActiveCharacterCache()
        end
        if RealmDisplayConfigFrame and RealmDisplayConfigFrame:IsShown() then
            UpdateConfigPanelFields()
        end
    end)

    local modeSetting = Settings.RegisterAddOnSetting(
        optionsCategory, "RealmDisplay_CharDisplayMode", "charDisplayMode",
        db, Settings.VarType.String, "Character Details", "ALL"
    )
    
    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("ALL", "Name, Level, Gold, Profession")
        container:Add("NO_NAME", "Level, Gold, Profession")
        container:Add("NO_LEVEL", "Name, Gold, Profession")
        container:Add("NO_GOLD", "Name, Level, Profession")
        container:Add("NO_PROF", "Name, Level, Gold")
        container:Add("NAME_LVL", "Name, Level")
        container:Add("NAME_GOLD", "Name, Gold")
        container:Add("NAME_PROF", "Name, Profession")
        container:Add("LVL_GOLD", "Level, Gold")
        container:Add("LVL_PROF", "Level, Profession")
        container:Add("GOLD_PROF", "Gold, Profession")
        container:Add("NAME", "Name Only")
        container:Add("LVL", "Level Only")
        container:Add("GOLD", "Gold Only")
        container:Add("PROF", "Profession Only")
        return container:GetData()
    end
    
    Settings.CreateDropdown(optionsCategory, modeSetting, GetOptions, "Choose what character details to display in tooltips.")
    modeSetting:SetValueChangedCallback(function(_, value)
        db.charDisplayMode = value
        if RealmDisplayConfigFrame and RealmDisplayConfigFrame:IsShown() then
            UpdateConfigPanelFields()
        end
    end)

    Settings.RegisterAddOnCategory(optionsCategory)
end

-- ============================================================
-- 16. EVENT CONTROLLER
-- ============================================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "RealmDisplay" then
        -- Load region-specific realms and locales
        local region = GetRegionTag()
        REALM_LOCALE = RealmDisplay_Data.realms[region] or {}

        -- Build NORMALIZED_TO_PROPER lookup
        for name, _ in pairs(REALM_LOCALE) do
            local norm = name:gsub("[%s'%-]", ""):lower()
            if not NORMALIZED_TO_PROPER[norm] or name:find(" ") then
                NORMALIZED_TO_PROPER[norm] = name
            end
        end

        -- Build REALM_CLUSTER only from the active region's clusters
        local clusters = (region == "EU") and EU_CONNECTED_CLUSTERS or NA_CONNECTED_CLUSTERS
        for _, cluster in ipairs(clusters) do
            for i, r in ipairs(cluster) do
                local others = {}
                for j, other in ipairs(cluster) do
                    if j ~= i then others[#others + 1] = other end
                end
                REALM_CLUSTER[r] = others
                local norm = GetNormalizedName(r)
                if NORMALIZED_TO_PROPER[norm] and NORMALIZED_TO_PROPER[norm] ~= r then
                    REALM_CLUSTER[NORMALIZED_TO_PROPER[norm]] = others
                end
            end
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
        if not db.charDisplayMode or not DISPLAY_MODE_LABELS[db.charDisplayMode] then
            db.charDisplayMode = "ALL"
        end

        SetupOptionsMenu()
        SetupMinimapButton()

    elseif event == "PLAYER_LOGIN" then
        if db.point then
            frame:ClearAllPoints()
            frame:SetPoint(db.point, UIParent, db.relPoint, db.xOfs, db.yOfs)
        end

        UpdateActiveCharacterCache()

        -- Build the dropdown realm list : all unique proper realm names, sorted A-Z
        local seenNorm = {}
        local rawList  = {}
        for name, _ in pairs(REALM_LOCALE) do
            local norm = GetNormalizedName(name)
            if not seenNorm[norm] then
                seenNorm[norm] = true
                rawList[#rawList + 1] = NORMALIZED_TO_PROPER[norm] or name
            end
        end
        table.sort(rawList)
        allDropRealms = rawList
        SortRealmList()

        frame:SetShown(db.showPanel)
        RealmDisplayFrame_Update()
        fadeGroup:Play()
        C_Timer.After(3, RealmDisplayFrame_Update)
    elseif event == "PLAYER_LEVEL_UP" or event == "SKILL_LINES_CHANGED" or event == "PLAYER_MONEY" then
        UpdateActiveCharacterCache()
    end
end)