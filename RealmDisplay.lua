-- ============================================================
--  RealmDisplay  —  Crafting Compatibility Checker
--  Styled to match AlterArena / WeeklyKnowledge (LiqUI look):
--    • neutral dark background, subtle 4px border
--    • SystemFont_* overlay fonts
--    • flat low-contrast buttons
--    • muted teal accent
--  Data source: GetAutoCompleteRealms() (live Blizzard API)
--  No static realm database required.
-- ============================================================

-- ---- Accent (used across the addon) ------------------------
local ACCENT_HEX  = "4FC3F7"
local ACCENT_RGB  = { 0.31, 0.76, 0.97 }
local PFX         = "|cff" .. ACCENT_HEX .. "RealmDisplay:|r "

local DEFAULTS = {
    showPanel          = true,
    point              = nil,
    relPoint           = nil,
    xOfs               = nil,
    yOfs               = nil,
    minimap            = { hide = false },
    customerRealm      = nil,
    customerInGuild    = false,
    autoFillOnWhisper  = true,
    announceOnWhisper  = false,
}

local db

-- ============================================================
-- 1. REALM HELPERS
-- ============================================================
local function GetNormalizedName(name)
    if not name then return "" end
    return name:gsub("[%s'%-]", ""):lower()
end

local function GetProperRealmName(name)
    if not name then return "" end
    local norm = GetNormalizedName(name)
    local playerRealm = GetRealmName and GetRealmName()
    if playerRealm and GetNormalizedName(playerRealm) == norm then
        return playerRealm
    end
    return name:gsub("(%l)(%u)", "%1 %2")
end

-- Returns a flat list of realm names in the player's connected cluster.
-- Uses the live Blizzard API. Always accurate, no maintenance needed.
local function GetMyCluster()
    local realms = { GetRealmName() }
    local auto = GetAutoCompleteRealms() or {}
    for _, r in ipairs(auto) do
        realms[#realms + 1] = r
    end
    return realms
end

-- ============================================================
-- 1b. GUILD ROSTER CACHE  (lazy — built on first lookup)
-- ============================================================
local guildRosterSet     = nil   -- nil = not built yet
local guildRosterNameSet = nil

local function BuildGuildRosterCache()
    guildRosterSet     = {}
    guildRosterNameSet = {}
    if not IsInGuild() then return end

    local num = GetNumGuildMembers() or 0
    for i = 1, num do
        local fullName = GetGuildRosterInfo(i)
        if fullName and fullName ~= "" then
            guildRosterSet[GetNormalizedName(fullName)] = true
            local nameOnly = fullName:match("^([^%-]+)") or fullName
            guildRosterNameSet[GetNormalizedName(nameOnly)] = true
        end
    end
end

local function InvalidateGuildRosterCache()
    guildRosterSet     = nil
    guildRosterNameSet = nil
end

local function IsInMyGuild(fullName)
    if not fullName then return false end

    -- Build lazily the first time it's needed
    if not guildRosterSet then BuildGuildRosterCache() end

    -- Try full "Name-Realm"
    if guildRosterSet[GetNormalizedName(fullName)] then return true end

    -- Fall back to name-only match
    local nameOnly = fullName:match("^([^%-]+)") or fullName
    return guildRosterNameSet[GetNormalizedName(nameOnly)] == true
end

-- ============================================================
-- 2. COMPATIBILITY LOGIC
-- ============================================================
local VERDICT = {
    PERSONAL = {
        text = "PERSONAL ORDER AVAILABLE",
        sub  = "Same connected realm — send a personal crafting order.",
        r = 0.30, g = 0.90, b = 0.40,
    },
    GUILD = {
        text = "GUILD ORDER AVAILABLE",
        sub  = "Different realm, but you're in the same guild — they can place a guild order.",
        r = 0.30, g = 0.90, b = 0.40,
    },
    NONE = {
        text = "INCOMPATIBLE",
        sub  = "Different realm, no shared guild. You cannot serve them.",
        r = 1.00, g = 0.30, b = 0.30,
    },
}

local function GetVerdict(customerRealm, customerInGuild)
    if not customerRealm or customerRealm == "" then return nil end

    local customerNorm = GetNormalizedName(customerRealm)
    local cluster = GetMyCluster()
    for _, r in ipairs(cluster) do
        if GetNormalizedName(r) == customerNorm then
            return "PERSONAL"
        end
    end

    if customerInGuild then return "GUILD" end
    return "NONE"
end

-- ============================================================
-- 3. LAYOUT
-- ============================================================
local PANEL_W = 300
local PANEL_H = 272

-- Shared UI colors (LiqUI-inspired neutral dark palette) ----
local C_BG        = { 0.06, 0.06, 0.08, 0.92 }
local C_BORDER    = { 0.18, 0.18, 0.20, 1.00 }
local C_ELEMENT   = { 0.10, 0.10, 0.12, 1.00 }
local C_ELEMENT_B = { 0.22, 0.22, 0.25, 1.00 }
local C_ELEM_HOV  = { 0.15, 0.15, 0.18, 1.00 }
local C_ELEM_HOVB = { 0.35, 0.35, 0.38, 1.00 }
local C_TEXT      = { 0.85, 0.85, 0.85 }
local C_TEXT_DIM  = { 0.55, 0.55, 0.55 }

local function ApplyFlatBackdrop(f, bg, border, edgeSize)
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = edgeSize or 1,
    })
    if bg     then f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4]) end
    if border then f:SetBackdropBorderColor(border[1], border[2], border[3], border[4]) end
end

-- ============================================================
-- 4. MAIN FRAME
-- ============================================================
local frame = CreateFrame("Frame", "RealmDisplayFrame", UIParent, "BackdropTemplate")
frame:SetSize(PANEL_W, PANEL_H)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 4,
})
frame:SetBackdropColor(C_BG[1], C_BG[2], C_BG[3], C_BG[4])
frame:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], C_BORDER[4])

frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Convert the current screen position into an offset from UIParent's TOPLEFT corner.
    local scale   = UIParent:GetEffectiveScale()
    local frameL  = self:GetLeft()  * scale
    local frameT  = self:GetTop()   * scale
    local uiL     = UIParent:GetLeft() * scale
    local uiT     = UIParent:GetTop()  * scale

    db.point    = "TOPLEFT"
    db.relPoint = "TOPLEFT"
    db.xOfs     = frameL - uiL
    db.yOfs     = frameT - uiT
end)

-- Title ----------------------------------------------------
local title = frame:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
title:SetPoint("TOPLEFT", 12, -10)
title:SetText("|cff" .. ACCENT_HEX .. "CRAFTING|r  |cffAAAAAACOMPATIBILITY|r")
title:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])

-- Close button ---------------------------------------------
local closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(16, 16)
closeBtn:SetPoint("TOPRIGHT", -8, -8)

local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\close.png")
closeTex:SetVertexColor(0.55, 0.55, 0.58, 1)

closeBtn:SetScript("OnEnter", function(self)
    closeTex:SetVertexColor(1.00, 0.35, 0.35, 1)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Close")
    GameTooltip:Show()
end)
closeBtn:SetScript("OnLeave", function(self)
    closeTex:SetVertexColor(0.55, 0.55, 0.58, 1)
    GameTooltip:Hide()
end)
closeBtn:SetScript("OnClick", function()
    db.showPanel = false
    frame:Hide()
end)

-- Customer realm input (search box + dropdown suggestions) --
local realmLabel = frame:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
realmLabel:SetPoint("TOPLEFT", 12, -36)
realmLabel:SetText("Customer Realm:")
realmLabel:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])

local inputRow = CreateFrame("Frame", nil, frame)
inputRow:SetPoint("TOPLEFT", 12, -54)
inputRow:SetSize(PANEL_W - 24, 24)

local isSyncingInput = false

local inputBox = CreateFrame("EditBox", nil, inputRow, "BackdropTemplate")
inputBox:SetAllPoints()
inputBox:SetAutoFocus(false)
inputBox:SetMaxLetters(64)
inputBox:SetTextInsets(6, 24, 0, 0)          -- increased right padding for the icon
inputBox:SetFontObject("SystemFont_Small")
ApplyFlatBackdrop(inputBox, C_ELEMENT, C_ELEMENT_B, 1)
inputBox:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])

-- Search icon
local searchIcon = inputBox:CreateTexture(nil, "OVERLAY")
searchIcon:SetSize(14, 14)
searchIcon:SetPoint("RIGHT", -6, 0)
searchIcon:SetTexture("Interface\\AddOns\\RealmDisplay\\Media\\Icons\\search.png")
searchIcon:SetVertexColor(0.45, 0.45, 0.48)

local inputHint = inputBox:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
inputHint:SetPoint("LEFT", 8, 0)
inputHint:SetText("Type or paste a realm name...")
inputHint:SetTextColor(0.45, 0.45, 0.48)

inputBox:SetScript("OnTextChanged", function(self)
    inputHint:SetShown(self:GetText() == "")
    if not db then return end
    db.customerRealm = (self:GetText() ~= "") and self:GetText() or nil
    if not isSyncingInput then
        db.customerInGuild = false
    end
    UpdateDisplay()
end)
inputBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

-- Action button rows (2 lines, full width) ------------------
local btnRow1 = CreateFrame("Frame", nil, frame)
btnRow1:SetPoint("TOPLEFT", inputRow, "BOTTOMLEFT", 0, -6)
btnRow1:SetPoint("TOPRIGHT", inputRow, "BOTTOMRIGHT", 0, -6)
btnRow1:SetHeight(20)

local btnRow2 = CreateFrame("Frame", nil, frame)
btnRow2:SetPoint("TOPLEFT", btnRow1, "BOTTOMLEFT", 0, -4)
btnRow2:SetPoint("TOPRIGHT", btnRow1, "BOTTOMRIGHT", 0, -4)
btnRow2:SetHeight(20)

local function MakeFlatButton(parent, text)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    ApplyFlatBackdrop(b, C_ELEMENT, C_ELEMENT_B, 1)
    local fs = b:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    fs:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    b.fs = fs
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C_ELEM_HOV[1], C_ELEM_HOV[2], C_ELEM_HOV[3], C_ELEM_HOV[4])
        self:SetBackdropBorderColor(C_ELEM_HOVB[1], C_ELEM_HOVB[2], C_ELEM_HOVB[3], C_ELEM_HOVB[4])
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C_ELEMENT[1], C_ELEMENT[2], C_ELEMENT[3], C_ELEMENT[4])
        self:SetBackdropBorderColor(C_ELEMENT_B[1], C_ELEMENT_B[2], C_ELEMENT_B[3], C_ELEMENT_B[4])
    end)
    return b
end

-- Row 1
local targetBtn = MakeFlatButton(btnRow1, "Use Target")
targetBtn:SetHeight(20)
targetBtn:SetPoint("LEFT", 0, 0)
targetBtn:SetPoint("RIGHT", btnRow1, "CENTER", -2, 0)

local clearBtn = MakeFlatButton(btnRow1, "Clear")
clearBtn:SetHeight(20)
clearBtn:SetPoint("LEFT", btnRow1, "CENTER", 2, 0)
clearBtn:SetPoint("RIGHT", 0, 0)

-- Row 2
local copyBtn = MakeFlatButton(btnRow2, "Copy Realm")
copyBtn:SetHeight(20)
copyBtn:SetPoint("LEFT", 0, 0)
copyBtn:SetPoint("RIGHT", btnRow2, "CENTER", -2, 0)

local resetBtn = MakeFlatButton(btnRow2, "Reset")
resetBtn:SetHeight(20)
resetBtn:SetPoint("LEFT", btnRow2, "CENTER", 2, 0)
resetBtn:SetPoint("RIGHT", 0, 0)

-- Verdict box (clickable) ----------------------------------
local verdictBox = CreateFrame("Button", nil, frame, "BackdropTemplate")
verdictBox:SetSize(PANEL_W - 24, 66)
verdictBox:SetPoint("TOPLEFT", btnRow2, "BOTTOMLEFT", 0, -8)
ApplyFlatBackdrop(verdictBox, { 0.09, 0.09, 0.11, 1 }, C_ELEMENT_B, 1)

local verdictText = verdictBox:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
verdictText:SetPoint("TOP", 0, -12)
verdictText:SetText("")

local verdictSub = verdictBox:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
verdictSub:SetPoint("TOP", verdictText, "BOTTOM", 0, -8)
verdictSub:SetWidth(PANEL_W - 44)
verdictSub:SetJustifyH("CENTER")
verdictSub:SetText("")

local verdictCopyHint = verdictBox:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
verdictCopyHint:SetPoint("BOTTOMRIGHT", -6, 4)
verdictCopyHint:SetText("|cff555566(click to copy)|r")

-- Notify checkbox ------------------------------------------
local notifyCB = CreateFrame("CheckButton", "RealmDisplayNotifyCB", frame, "InterfaceOptionsCheckButtonTemplate")
notifyCB:SetPoint("TOPLEFT", verdictBox, "BOTTOMLEFT", 0, -8)
local notifyCBText = _G["RealmDisplayNotifyCBText"]
if notifyCBText then
    notifyCBText:SetText("Notify on whisper")
    notifyCBText:SetFontObject("SystemFont_Small")
    notifyCBText:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
end
notifyCB:SetScript("OnClick", function(self)
    db.announceOnWhisper = not not self:GetChecked()
    PlaySound(856)
end)
notifyCB:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Notify on whisper")
    GameTooltip:AddLine("Print a verdict line in chat when someone whispers you and the panel is hidden.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end)
notifyCB:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Footer ---------------------------------------------------
local footer = frame:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
footer:SetPoint("BOTTOMLEFT", 12, 8)
footer:SetPoint("BOTTOMRIGHT", -12, 8)
footer:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])
footer:SetJustifyH("LEFT")

-- ============================================================
-- 5. VERDICT STRING HELPERS
-- ============================================================
local function FormatVerdictString()
    if not db or not db.customerRealm then return nil end
    local v = GetVerdict(db.customerRealm, db.customerInGuild)
    if not v then return nil end
    return string.format("Realm check: %s vs %s - %s",
        db.customerRealm, GetRealmName(), VERDICT[v].text)
end

local WHISPER_MESSAGES = {
    PERSONAL = "can craft via personal order",
    GUILD    = "from your guild - can place a guild order",
    NONE     = "cannot craft - different realm, no shared guild",
}

-- ============================================================
-- 6. UPDATE FUNCTION
-- ============================================================
function UpdateDisplay()
    if not db then return end

    -- Sync the input box with db state (e.g. after whisper/target)
    if db.customerRealm and inputBox:GetText() ~= db.customerRealm then
        isSyncingInput = true
        inputBox:SetText(db.customerRealm)
        isSyncingInput = false
    elseif not db.customerRealm and inputBox:GetText() ~= "" then
        isSyncingInput = true
        inputBox:SetText("")
        isSyncingInput = false
    end

    local verdict = GetVerdict(db.customerRealm, db.customerInGuild)
    if verdict then
        local v = VERDICT[verdict]
        verdictText:SetText(v.text)
        verdictText:SetTextColor(v.r, v.g, v.b)
        verdictSub:SetText(v.sub)
        verdictSub:SetTextColor(0.75, 0.75, 0.75)
        verdictBox:SetBackdropBorderColor(v.r * 0.7, v.g * 0.7, v.b * 0.7, 1)
        verdictCopyHint:Show()
    else
        verdictText:SetText("AWAITING INPUT")
        verdictText:SetTextColor(0.5, 0.5, 0.5)
        verdictSub:SetText("Type a realm above to check compatibility.")
        verdictSub:SetTextColor(0.5, 0.5, 0.5)
        verdictBox:SetBackdropBorderColor(C_ELEMENT_B[1], C_ELEMENT_B[2], C_ELEMENT_B[3], C_ELEMENT_B[4])
        verdictCopyHint:Hide()
    end

    local myRealm = GetRealmName()
    local auto    = GetAutoCompleteRealms() or {}
    local clusterSize = #auto + 1
    footer:SetText(string.format("You: |cff" .. ACCENT_HEX .. "%s|r  |cff555566-|r  Cluster: %d realm%s",
        myRealm, clusterSize, clusterSize == 1 and "" or "s"))
end

-- ============================================================
-- 7. ACTION BUTTONS
-- ============================================================
targetBtn:SetScript("OnClick", function()
    local name, realm = UnitFullName("target")
    if not name then
        print(PFX .. "No target selected.")
        return
    end
    if not realm or realm == "" then
        realm = GetRealmName()
    end
    db.customerRealm = GetProperRealmName(realm)

    -- Auto-detect guild membership from target
    local _, myGuild = GetGuildInfo("player")
    local _, tGuild  = GetGuildInfo("target")
    db.customerInGuild = (myGuild and tGuild and myGuild == tGuild) and true or false

    UpdateDisplay()
end)
targetBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(C_ELEM_HOV[1], C_ELEM_HOV[2], C_ELEM_HOV[3], C_ELEM_HOV[4])
    self:SetBackdropBorderColor(C_ELEM_HOVB[1], C_ELEM_HOVB[2], C_ELEM_HOVB[3], C_ELEM_HOVB[4])
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Use Current Target")
    GameTooltip:AddLine("Fills in the realm and guild status of your target.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
targetBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(C_ELEMENT[1], C_ELEMENT[2], C_ELEMENT[3], C_ELEMENT[4])
    self:SetBackdropBorderColor(C_ELEMENT_B[1], C_ELEMENT_B[2], C_ELEMENT_B[3], C_ELEMENT_B[4])
    GameTooltip:Hide()
end)

clearBtn:SetScript("OnClick", function()
    db.customerRealm   = nil
    db.customerInGuild = false
    isSyncingInput     = true
    inputBox:SetText("")
    isSyncingInput     = false
    UpdateDisplay()
end)

copyBtn:SetScript("OnClick", function()
    if not db.customerRealm then return end
    if not ChatEdit_InsertLink(db.customerRealm) then
        print(PFX .. db.customerRealm)
    end
end)
copyBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(C_ELEM_HOV[1], C_ELEM_HOV[2], C_ELEM_HOV[3], C_ELEM_HOV[4])
    self:SetBackdropBorderColor(C_ELEM_HOVB[1], C_ELEM_HOVB[2], C_ELEM_HOVB[3], C_ELEM_HOVB[4])
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Copy Realm Name")
    GameTooltip:AddLine("Inserts the realm name into your chat edit box.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
copyBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(C_ELEMENT[1], C_ELEMENT[2], C_ELEMENT[3], C_ELEMENT[4])
    self:SetBackdropBorderColor(C_ELEMENT_B[1], C_ELEMENT_B[2], C_ELEMENT_B[3], C_ELEMENT_B[4])
    GameTooltip:Hide()
end)

-- reset button
resetBtn:SetScript("OnClick", function()
    db.point, db.relPoint, db.xOfs, db.yOfs = nil, nil, nil, nil
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
    print(PFX .. "Position reset.")
end)
resetBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(C_ELEM_HOV[1], C_ELEM_HOV[2], C_ELEM_HOV[3], C_ELEM_HOV[4])
    self:SetBackdropBorderColor(C_ELEM_HOVB[1], C_ELEM_HOVB[2], C_ELEM_HOVB[3], C_ELEM_HOVB[4])
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Reset Position")
    GameTooltip:AddLine("Resets the panel position to the center of the screen.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
resetBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(C_ELEMENT[1], C_ELEMENT[2], C_ELEMENT[3], C_ELEMENT[4])
    self:SetBackdropBorderColor(C_ELEMENT_B[1], C_ELEMENT_B[2], C_ELEMENT_B[3], C_ELEMENT_B[4])
    GameTooltip:Hide()
end)

-- Verdict box: click to copy ---------------------------------
verdictBox:SetScript("OnClick", function()
    local str = FormatVerdictString()
    if not str then return end
    if not ChatEdit_InsertLink(str) then
        print(PFX .. str)
    end
end)
verdictBox:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.11, 0.11, 0.13, 1)
    if db and db.customerRealm then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Click to copy verdict")
        GameTooltip:AddLine(FormatVerdictString() or "", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end
end)
verdictBox:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.09, 0.09, 0.11, 1)
    GameTooltip:Hide()
end)

-- ============================================================
-- 8. SLASH COMMANDS
-- ============================================================
SLASH_REALMDISPLAY1 = "/rd"
SLASH_REALMDISPLAY2 = "/realmdisplay"

SlashCmdList["REALMDISPLAY"] = function(msg)
    if not db then
        print("|cff4FC3F7RealmDisplay:|r Still loading, try again in a moment.")
        return
    end

    local raw = strtrim(msg)
    local cmd, rest = raw:match("^%s*(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()
    if cmd == "" or cmd == "toggle" then
        db.showPanel = not db.showPanel
        frame:SetShown(db.showPanel)

    elseif cmd == "check" then
        if rest == "" then
            print(PFX .. "Usage: /rd check <realm>")
            return
        end
        db.customerRealm = rest
        UpdateDisplay()
        local v = GetVerdict(rest, db.customerInGuild)
        if v then
            local info = VERDICT[v]
            print(string.format(PFX .. "%s -> |cff%02x%02x%02x%s|r",
                rest,
                math.floor(info.r * 255), math.floor(info.g * 255), math.floor(info.b * 255),
                info.text))
        end

    elseif cmd == "target" then
        targetBtn:GetScript("OnClick")(targetBtn)

    elseif cmd == "clear" then
        clearBtn:GetScript("OnClick")(clearBtn)

    elseif cmd == "copy" then
        local str = FormatVerdictString()
        if str then
            if not ChatEdit_InsertLink(str) then print(PFX .. str) end
        else
            print(PFX .. "Nothing to copy — no customer set.")
        end

    elseif cmd == "whisper" then
        db.autoFillOnWhisper = not db.autoFillOnWhisper
        print(PFX .. "Auto-fill on whisper " ..
              (db.autoFillOnWhisper and "|cff44FF44enabled|r" or "|cffff4444disabled|r"))

    elseif cmd == "notify" then
        db.announceOnWhisper = not db.announceOnWhisper
        notifyCB:SetChecked(db.announceOnWhisper)
        print(PFX .. "Whisper chat notifications " ..
              (db.announceOnWhisper and "|cff44FF44enabled|r" or "|cffff4444disabled|r"))

    elseif cmd == "reset" then
        db.point, db.relPoint, db.xOfs, db.yOfs = nil, nil, nil, nil
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        print(PFX .. "Position reset.")

    elseif cmd == "minimap" then
        db.minimap.hide = not db.minimap.hide
        local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
        if Icon then
            if db.minimap.hide then Icon:Hide("RealmDisplay")
            else Icon:Show("RealmDisplay") end
        end
        print(PFX .. "Minimap button " .. (db.minimap.hide and "hidden" or "shown"))

    elseif cmd == "rosterdump" then
        local num = GetNumGuildMembers() or 0
        print(PFX .. "Roster has " .. num .. " members. First 5 raw entries:")
        for i = 1, math.min(num, 5) do
            local n = GetGuildRosterInfo(i)
            print(string.format("  [%d] %q -> normalized: %q", i, tostring(n), GetNormalizedName(n)))
        end

    elseif cmd == "rosterrebuild" then
        InvalidateGuildRosterCache()
        BuildGuildRosterCache()
        local count = 0
        for _ in pairs(guildRosterSet or {}) do count = count + 1 end
        print(PFX .. "Roster cache rebuilt. Entries: " .. count)

    elseif cmd == "rostertest" then
        if rest == "" then
            print(PFX .. "Usage: /rd rostertest <name-or-name-realm>")
            return
        end
        local inGuild = IsInMyGuild(rest)
        print(PFX .. string.format("Roster check for '%s': %s",
            rest, inGuild and "|cff44FF44FOUND|r" or "|cffff4444NOT FOUND|r"))
        print("  Normalized: " .. GetNormalizedName(rest))
        local nameOnly = rest:match("^([^%-]+)") or rest
        print("  Name only:  " .. GetNormalizedName(nameOnly))
        print("  Roster size: " .. tostring(GetNumGuildMembers() or 0))

    elseif cmd == "debug" then
        local myRealm = GetRealmName()
        print(PFX .. "debug:")
        print("  Your realm: " .. myRealm)
        local cluster = GetMyCluster()
        print("  Cluster (" .. #cluster .. " realms):")
        for _, r in ipairs(cluster) do print("    " .. r) end
        print("  Customer: " .. tostring(db.customerRealm))
        print("  In guild: " .. tostring(db.customerInGuild))
        print("  Verdict:  " .. tostring(GetVerdict(db.customerRealm, db.customerInGuild)))
    elseif cmd == "posdebug" then
        print(PFX .. "Saved position:")
        print("  point:    " .. tostring(db.point))
        print("  relPoint: " .. tostring(db.relPoint))
        print("  xOfs:     " .. tostring(db.xOfs))
        print("  yOfs:     " .. tostring(db.yOfs))
        print("  Scale:    " .. tostring(UIParent:GetEffectiveScale()))
        local p, _, rp, x, y = frame:GetPoint()
        print("  Current anchor: " .. tostring(p) .. " / " .. tostring(rp) ..
              " / " .. tostring(x) .. " / " .. tostring(y))

    else
        print(PFX .. "commands:")
        print("  /rd                     — toggle panel")
        print("  /rd check <realm>       — verdict for a realm in chat")
        print("  /rd target              — use current target")
        print("  /rd clear               — clear customer")
        print("  /rd copy                — copy verdict to chat")
        print("  /rd whisper             — toggle whisper auto-fill")
        print("  /rd notify              — toggle whisper chat notifications")
        print("  /rd reset               — reset panel position")
        print("  /rd minimap             — toggle minimap button")
        print("  /rd debug               — print debug info")
        print("  /rd rostertest <name>   — test guild roster cache")
        print("  /rd rosterdump          — dump first 5 raw roster entries")
        print("  /rd rosterrebuild       — force rebuild the roster cache")
    end
end

-- ============================================================
-- 9. MINIMAP BUTTON
-- ============================================================
local function SetupMinimapButton()
    local LDB  = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not LDB or not Icon then return end

    local broker = LDB:NewDataObject("RealmDisplay", {
        type  = "launcher",
        icon  = "Interface\\Icons\\Trade_blacksmithing",
        label = "Realm Display",
        OnClick = function(_, btn)
            if btn == "RightButton" then
                db.showPanel = true
                frame:Show()
            else
                db.showPanel = not db.showPanel
                frame:SetShown(db.showPanel)
            end
        end,
        OnTooltipShow = function(tip)
            tip:AddLine("|cff" .. ACCENT_HEX .. "Realm Display|r")
            tip:AddLine(" ")
            local myRealm = GetRealmName()
            local auto = GetAutoCompleteRealms() or {}
            tip:AddLine("Your realm: |cff44FF44" .. myRealm .. "|r")
            tip:AddLine(string.format("Cluster: |cff" .. ACCENT_HEX .. "%d|r realms", #auto + 1))
            if db and db.customerRealm then
                tip:AddLine(" ")
                tip:AddLine("Checking: |cff" .. ACCENT_HEX .. db.customerRealm .. "|r")
                local v = GetVerdict(db.customerRealm, db.customerInGuild)
                if v then
                    local info = VERDICT[v]
                    tip:AddLine(info.text, info.r, info.g, info.b)
                end
            end
            tip:AddLine(" ")
            tip:AddLine("|cff888888Left-click|r toggle panel")
            tip:AddLine("|cff888888Right-click|r show panel")
        end,
    })

    Icon:Register("RealmDisplay", broker, db.minimap)
    if db.minimap.hide then Icon:Hide("RealmDisplay") end
end

-- ============================================================
-- 10. WHISPER HANDLER
-- ============================================================
local function HandleWhisper(text, sender)
    if not db or not db.autoFillOnWhisper then return end

    local name, realm = sender:match("^(.+)%-(.+)$")
    if not name then
        name  = sender
        realm = GetRealmName()
    end
    realm = GetProperRealmName(realm)

    db.customerRealm   = realm
    db.customerInGuild = IsInMyGuild(sender)   -- auto-detect from roster cache

    UpdateDisplay()
end
-- ============================================================
-- 10b. INLINE WHISPER VERDICT
--      Hooks each chat frame's OnEvent so the verdict appears
--      right after the whisper, in the same chat frame.
-- ============================================================
local function WhisperVerdictHook(self, event, ...)
    if event ~= "CHAT_MSG_WHISPER" then return end
    if not db or not db.announceOnWhisper then return end

    local text, sender = ...
    if not sender then return end

    local name, realm = sender:match("^(.+)%-(.+)$")
    if not name then
        name  = sender
        realm = GetRealmName()
    end
    realm = GetProperRealmName(realm)

    local inGuild = IsInMyGuild(sender)
    local v = GetVerdict(realm, inGuild)
    if not v then return end

    local info    = VERDICT[v]
    local summary = WHISPER_MESSAGES[v]

    self:AddMessage("  " .. summary, info.r, info.g, info.b)
end

for i = 1, NUM_CHAT_WINDOWS do
    local cf = _G["ChatFrame" .. i]
    if cf then
        cf:HookScript("OnEvent", WhisperVerdictHook)
    end
end

-- ============================================================
-- 11. EVENTS
-- ============================================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "RealmDisplay" then
        RealmDisplayDB = RealmDisplayDB or {}
        for k, v in pairs(DEFAULTS) do
            if RealmDisplayDB[k] == nil then RealmDisplayDB[k] = v end
        end
        RealmDisplayDB.minimap = RealmDisplayDB.minimap or {}
        if RealmDisplayDB.minimap.hide == nil then
            RealmDisplayDB.minimap.hide = false
        end
        db = RealmDisplayDB

        SetupMinimapButton()

    elseif event == "PLAYER_LOGIN" then
        if db.point then
            frame:ClearAllPoints()
            local currentScale = UIParent:GetEffectiveScale()
            local savedScale   = db.savedScale or currentScale
            local ratio        = savedScale / currentScale
            frame:SetPoint(db.point, UIParent, db.relPoint,
                db.xOfs * ratio, db.yOfs * ratio)
        end

        InvalidateGuildRosterCache()
        notifyCB:SetChecked(db.announceOnWhisper)
        frame:SetShown(db.showPanel)
        UpdateDisplay()

    elseif event == "CHAT_MSG_WHISPER" then
        HandleWhisper(arg1, arg2)

    elseif event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
        InvalidateGuildRosterCache()
    end
end)