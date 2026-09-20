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
-- 2. COMPATIBILITY LOGIC
-- ============================================================
local VERDICT = {
    PERSONAL = {
        text = "PERSONAL ORDER AVAILABLE",
        sub  = "Same connected realm — send a personal crafting order.",
        r = 0.30, g = 0.90, b = 0.40,
    },
    GUILD = {
        text = "GUILD ORDER REQUIRED",
        sub  = "Different realm, but you share a guild.",
        r = 1.00, g = 0.80, b = 0.20,
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
local PANEL_H = 250

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
    local point, _, relPoint, x, y = self:GetPoint()
    db.point, db.relPoint, db.xOfs, db.yOfs = point, relPoint, x, y
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

local inputBox = CreateFrame("EditBox", nil, inputRow, "BackdropTemplate")
inputBox:SetAllPoints()
inputBox:SetAutoFocus(false)
inputBox:SetMaxLetters(64)
inputBox:SetTextInsets(6, 6, 0, 0)
inputBox:SetFontObject("SystemFont_Small")
ApplyFlatBackdrop(inputBox, C_ELEMENT, C_ELEMENT_B, 1)
inputBox:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])

local inputHint = inputBox:CreateFontString(nil, "OVERLAY", "SystemFont_Small")
inputHint:SetPoint("LEFT", 8, 0)
inputHint:SetText("Type or paste a realm name...")
inputHint:SetTextColor(0.45, 0.45, 0.48)

inputBox:SetScript("OnTextChanged", function(self)
    inputHint:SetShown(self:GetText() == "")
    db.customerRealm = (self:GetText() ~= "") and self:GetText() or nil
    UpdateDisplay()
end)
inputBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

-- Action button row ----------------------------------------
local btnRow = CreateFrame("Frame", nil, frame)
btnRow:SetPoint("TOPLEFT", inputRow, "BOTTOMLEFT", 0, -6)
btnRow:SetPoint("TOPRIGHT", inputRow, "BOTTOMRIGHT", 0, -6)
btnRow:SetHeight(20)

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

local targetBtn = MakeFlatButton(btnRow, "Use Target")
targetBtn:SetSize(90, 20)
targetBtn:SetPoint("LEFT", 0, 0)

local clearBtn = MakeFlatButton(btnRow, "Clear")
clearBtn:SetSize(60, 20)
clearBtn:SetPoint("LEFT", targetBtn, "RIGHT", 4, 0)

local copyBtn = MakeFlatButton(btnRow, "Copy Realm")
copyBtn:SetSize(80, 20)
copyBtn:SetPoint("LEFT", clearBtn, "RIGHT", 4, 0)

-- Verdict box (clickable) ----------------------------------
local verdictBox = CreateFrame("Button", nil, frame, "BackdropTemplate")
verdictBox:SetSize(PANEL_W - 24, 66)
verdictBox:SetPoint("TOPLEFT", btnRow, "BOTTOMLEFT", 0, -8)
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

-- Guild checkbox -------------------------------------------
local guildCB = CreateFrame("CheckButton", "RealmDisplayGuildCB", frame, "InterfaceOptionsCheckButtonTemplate")
guildCB:SetPoint("TOPLEFT", verdictBox, "BOTTOMLEFT", 0, -8)
local guildCBText = _G["RealmDisplayGuildCBText"]
if guildCBText then
    guildCBText:SetText("Customer is in my guild")
    guildCBText:SetFontObject("SystemFont_Small")
    guildCBText:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
end
guildCB:SetScript("OnClick", function(self)
    db.customerInGuild = not not self:GetChecked()
    UpdateDisplay()
    PlaySound(856)
end)

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

local function AnnounceWhisperVerdict(sender, realm)
    local v = GetVerdict(realm, db.customerInGuild)
    if not v then return end
    local info = VERDICT[v]
    print(string.format(PFX .. "%s (%s) -> |cff%02x%02x%02x%s|r",
        sender, realm or "same realm",
        math.floor(info.r * 255), math.floor(info.g * 255), math.floor(info.b * 255),
        info.text))
end

-- ============================================================
-- 6. UPDATE FUNCTION
-- ============================================================
function UpdateDisplay()
    if not db then return end

    -- Sync the input box with db state (e.g. after whisper/target)
    if db.customerRealm and inputBox:GetText() ~= db.customerRealm then
        inputBox:SetText(db.customerRealm)
    elseif not db.customerRealm and inputBox:GetText() ~= "" then
        inputBox:SetText("")
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

    local _, myGuild = GetGuildInfo("player")
    local _, tGuild  = GetGuildInfo("target")
    local sameGuild  = (myGuild and tGuild and myGuild == tGuild) and true or false
    db.customerInGuild = sameGuild
    guildCB:SetChecked(sameGuild)

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
    guildCB:SetChecked(false)
    inputBox:SetText("")
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
    local raw = strtrim(msg)
    local cmd, rest = raw:match("^(%S+)%s*(.*)$")
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

    else
        print(PFX .. "commands:")
        print("  /rd                     — toggle panel")
        print("  /rd check <realm>       — verdict for a realm in chat")
        print("  /rd target              — use current target")
        print("  /rd clear               — clear customer")
        print("  /rd copy                — copy verdict to chat")
        print("  /rd whisper             — toggle whisper auto-fill")
        print("  /rd reset               — reset panel position")
        print("  /rd minimap             — toggle minimap button")
        print("  /rd debug               — print debug info")
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
        icon  = "Interface\\Icons\\INV_Misc_Map_01",
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

    db.customerRealm = realm
    UpdateDisplay()

    if not frame:IsShown() then
        AnnounceWhisperVerdict(name, realm)
    end
end

-- ============================================================
-- 11. EVENTS
-- ============================================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_WHISPER")

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
            frame:SetPoint(db.point, UIParent, db.relPoint, db.xOfs, db.yOfs)
        end

        guildCB:SetChecked(db.customerInGuild)
        frame:SetShown(db.showPanel)
        UpdateDisplay()

    elseif event == "CHAT_MSG_WHISPER" then
        HandleWhisper(arg1, arg2)
    end
end)