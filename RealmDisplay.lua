-- ============================================================
-- RealmDisplay — Crafting Compatibility (Chat First)
-- WoW Retail / Midnight 12.x
-- ============================================================

local ADDON, RD = ...

RD.ACCENT = "4FC3F7"
RD.PFX = "|cff" .. RD.ACCENT .. "RealmDisplay:|r "


-- ------------------------------------------------------------
-- Shared styled UI (close + scrollbar) — matches premium panels
-- ------------------------------------------------------------

local function Solid(tex, r, g, b, a)
    tex:SetColorTexture(r, g, b, a or 1)
end

function RD.CreateCloseButton(parent, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(24, 24)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.12, 0.13, 0.16, 1)
    btn:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)

    local x = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    x:SetPoint("CENTER", 0, 1)
    x:SetText("×")
    x:SetTextColor(0.70, 0.72, 0.76)
    btn.label = x

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.31, 0.76, 0.97, 0.25)
        self:SetBackdropBorderColor(0.31, 0.76, 0.97, 0.8)
        self.label:SetTextColor(0.31, 0.76, 0.97)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.13, 0.16, 1)
        self:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
        self.label:SetTextColor(0.70, 0.72, 0.76)
    end)
    btn:SetScript("OnClick", function()
        PlaySound(624)
        if onClick then onClick() end
    end)
    return btn
end

-- Returns scrollFrame, scrollChild. Optional onChildSize for width sync.
function RD.CreateScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)

    local track = CreateFrame("Frame", nil, scroll, "BackdropTemplate")
    track:SetWidth(6)
    track:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    track:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    track:SetBackdropColor(0.08, 0.09, 0.11, 1)
    track:SetBackdropBorderColor(0.18, 0.20, 0.24, 1)

    local thumb = CreateFrame("Button", nil, track, "BackdropTemplate")
    thumb:SetWidth(6)
    thumb:SetHeight(40)
    thumb:SetPoint("TOP", track, "TOP", 0, 0)
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(0.31, 0.76, 0.97, 0.45)
    thumb:SetBackdropBorderColor(0.31, 0.76, 0.97, 0.7)
    thumb:RegisterForDrag("LeftButton")
    thumb:SetMovable(true)
    thumb:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.31, 0.76, 0.97, 0.7)
    end)
    thumb:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.31, 0.76, 0.97, 0.45)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)

    local function UpdateThumb()
        local viewH = scroll:GetHeight() or 1
        local childH = child:GetHeight() or 1
        local maxScroll = math.max(childH - viewH, 0)
        if maxScroll <= 0 then
            track:Hide()
            scroll:SetVerticalScroll(0)
            return
        end
        track:Show()
        local ratio = viewH / childH
        local thumbH = math.max(24, viewH * ratio)
        thumb:SetHeight(thumbH)
        local cur = scroll:GetVerticalScroll() or 0
        local trackH = track:GetHeight() or 1
        local y = 0
        if maxScroll > 0 then
            y = -(cur / maxScroll) * (trackH - thumbH)
        end
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, y)
    end

    scroll:SetScript("OnVerticalScroll", function(self, offset)
        UpdateThumb()
    end)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local viewH = self:GetHeight() or 1
        local childH = child:GetHeight() or 1
        local maxScroll = math.max(childH - viewH, 0)
        local cur = self:GetVerticalScroll() or 0
        local step = 28
        local new = math.min(maxScroll, math.max(0, cur - delta * step))
        self:SetVerticalScroll(new)
        UpdateThumb()
    end)

    thumb:SetScript("OnDragStart", function(self)
        self.dragging = true
    end)
    thumb:SetScript("OnDragStop", function(self)
        self.dragging = false
    end)
    thumb:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local scale = self:GetEffectiveScale()
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / scale
        local top = track:GetTop() or 0
        local trackH = track:GetHeight() or 1
        local thumbH = self:GetHeight() or 24
        local rel = top - cursorY - thumbH / 2
        rel = math.min(math.max(rel, 0), trackH - thumbH)
        local viewH = scroll:GetHeight() or 1
        local childH = child:GetHeight() or 1
        local maxScroll = math.max(childH - viewH, 0)
        local offset = 0
        if trackH > thumbH then
            offset = (rel / (trackH - thumbH)) * maxScroll
        end
        scroll:SetVerticalScroll(offset)
        self:ClearAllPoints()
        self:SetPoint("TOP", track, "TOP", 0, -rel)
    end)

    scroll.UpdateThumb = UpdateThumb
    scroll.track = track
    scroll.thumb = thumb

    -- Content sits inset so it doesn't sit under the track
    scroll:SetScript("OnSizeChanged", function(self)
        UpdateThumb()
    end)

    return scroll, child
end


RD.DEFAULTS = {
    enabled = true,
    annotationPosition = "AFTER",
    annotationStyle = "SYMBOL",
    showPersonal = true,
    showGuild = true,
    showNone = true,
    showUnknown = true,
    -- Preset keys: check, cross, wait, diamond, star, circle, triangle, moon, square, skull
    symbols = {
        PERSONAL = "check",
        GUILD = "diamond",
        NONE = "cross",
        UNKNOWN = "wait",
    },
    channels = {
        whisper = true, trade = true, public = true,
        say = true, yell = true,
        party = true, raid = true, instance = true,
        guild = false, officer = false,
    },
    minimap = { hide = false },
    debugEnabled = false,
}

-- Icon preset library (texture escapes that always render in WoW fonts).
RD.SYMBOL_PRESETS = {
    check    = { label = "Check",    tex = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t" },
    cross    = { label = "Cross",    tex = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t" },
    wait     = { label = "Waiting",  tex = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14:14:0:0|t" },
    star     = { label = "Star",     tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14:0:0|t" },
    circle   = { label = "Circle",   tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:14:14:0:0|t" },
    diamond  = { label = "Diamond",  tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:14:14:0:0|t" },
    triangle = { label = "Triangle", tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:14:14:0:0|t" },
    moon     = { label = "Moon",     tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:14:14:0:0|t" },
    square   = { label = "Square",   tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:14:14:0:0|t" },
    cross2   = { label = "X Mark",   tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:14:14:0:0|t" },
    skull    = { label = "Skull",    tex = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14:0:0|t" },
}

function RD.GetSymbolTex(verdict)
    local d = RD.db
    local key = d and d.symbols and d.symbols[verdict]
    local preset = key and RD.SYMBOL_PRESETS[key]
    if preset then return preset.tex end
    local info = RD.VERDICT[verdict]
    return info and info.symbol or ""
end


-- Texture icons (Unicode symbols often render as [] in WoW fonts).
RD.VERDICT = {
    PERSONAL = {
        symbol = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t",
        short = "Personal", text = "PERSONAL ORDER AVAILABLE",
        r = 0.30, g = 0.90, b = 0.40,
    },
    GUILD = {
        symbol = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:14:14:0:0|t",
        short = "Guild", text = "GUILD ORDER AVAILABLE",
        r = 0.30, g = 0.90, b = 0.40,
    },
    NONE = {
        symbol = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t",
        short = "Incompatible", text = "INCOMPATIBLE",
        r = 1.00, g = 0.30, b = 0.30,
    },
    UNKNOWN = {
        symbol = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14:14:0:0|t",
        short = "Unknown", text = "UNKNOWN",
        r = 0.70, g = 0.70, b = 0.70,
    },
}

local db
local guildRosterSet, guildRosterNameSet
local compatibilityCache = {}

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function Normalize(name)
    return (name or ""):gsub("[%s'%-%_]", ""):lower()
end

local function ProperRealm(name)
    if not name or name == "" then return "" end
    local mine = GetRealmName and GetRealmName()
    if mine and Normalize(mine) == Normalize(name) then return mine end
    return name:gsub("(%l)(%u)", "%1 %2")
end

function RD.SplitPlayerName(fullName)
    if not fullName or fullName == "" then return nil, nil end
    local name, realm = fullName:match("^(.+)%-(.+)$")
    if name and realm then return name, ProperRealm(realm) end
    return fullName, nil
end

local function MyCluster()
    local realms = {}
    local mine = GetRealmName()
    if mine and mine ~= "" then realms[#realms + 1] = mine end
    for _, realm in ipairs(GetAutoCompleteRealms and GetAutoCompleteRealms() or {}) do
        if realm and realm ~= "" then realms[#realms + 1] = realm end
    end
    return realms
end

function RD.GetMyCluster()
    return MyCluster()
end

local function SameConnectedRealm(realm)
    if not realm or realm == "" then return false end
    local n = Normalize(realm)
    for _, r in ipairs(MyCluster()) do
        if Normalize(r) == n then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- Guild roster cache
-- ------------------------------------------------------------

function RD.InvalidateGuildRosterCache()
    guildRosterSet, guildRosterNameSet = nil, nil
end

local function BuildGuildRosterCache()
    guildRosterSet, guildRosterNameSet = {}, {}
    if not IsInGuild() then return end
    for i = 1, (GetNumGuildMembers() or 0) do
        local fullName = GetGuildRosterInfo(i)
        if fullName and fullName ~= "" then
            guildRosterSet[Normalize(fullName)] = true
            local nameOnly = fullName:match("^([^%-]+)") or fullName
            guildRosterNameSet[Normalize(nameOnly)] = true
        end
    end
end

local function IsInMyGuild(fullName)
    if not fullName or fullName == "" then return false end
    if not guildRosterSet then BuildGuildRosterCache() end
    if guildRosterSet[Normalize(fullName)] then return true end
    local nameOnly = fullName:match("^([^%-]+)") or fullName
    return guildRosterNameSet[Normalize(nameOnly)] == true
end

-- ------------------------------------------------------------
-- Compatibility engine
-- ------------------------------------------------------------

function RD.ClearCompatibilityCache()
    wipe(compatibilityCache)
end

function RD.GetCompatibility(name, realm)
    if not name or name == "" then return "UNKNOWN" end

    local hasRealm = realm and realm ~= ""
    local fullName = hasRealm and (name .. "-" .. realm) or name
    local inGuild = IsInMyGuild(fullName)
    local key = table.concat({ Normalize(name), Normalize(realm or ""), inGuild and "1" or "0" }, "|")

    if compatibilityCache[key] then return compatibilityCache[key] end

    local verdict
    if hasRealm then
        if SameConnectedRealm(realm) then
            verdict = "PERSONAL"
        elseif inGuild then
            verdict = "GUILD"
        else
            verdict = "NONE"
        end
    else
        -- Same-realm chat often omits the realm tag.
        if SameConnectedRealm(GetRealmName()) then
            verdict = "PERSONAL"
        elseif inGuild then
            verdict = "GUILD"
        else
            verdict = "UNKNOWN"
        end
    end

    compatibilityCache[key] = verdict
    return verdict
end

-- ------------------------------------------------------------
-- Annotation
-- ------------------------------------------------------------

local CHANNEL_MAP = {
    CHAT_MSG_WHISPER = "whisper",
    CHAT_MSG_CHANNEL = "public",
    CHAT_MSG_SAY = "say",
    CHAT_MSG_YELL = "yell",
    CHAT_MSG_PARTY = "party",
    CHAT_MSG_PARTY_LEADER = "party",
    CHAT_MSG_RAID = "raid",
    CHAT_MSG_RAID_LEADER = "raid",
    CHAT_MSG_INSTANCE_CHAT = "instance",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "instance",
    CHAT_MSG_GUILD = "guild",
    CHAT_MSG_OFFICER = "officer",
}

local VERDICT_FLAG = {
    PERSONAL = "showPersonal",
    GUILD = "showGuild",
    NONE = "showNone",
    UNKNOWN = "showUnknown",
}

local function IsEventEnabled(event)
    if not db or not db.enabled then return false end
    local channel = CHANNEL_MAP[event]
    return channel and db.channels[channel] == true
end

local function GetAnnotation(verdict)
    local info = RD.VERDICT[verdict]
    if not info then return "" end

    local color = string.format(
        "|cff%02x%02x%02x",
        math.floor(info.r * 255),
        math.floor(info.g * 255),
        math.floor(info.b * 255)
    )
    local symbol = RD.GetSymbolTex(verdict)

    if db.annotationStyle == "TEXT" then
        return string.format(" %s[%s]|r", color, info.short)
    end
    if db.annotationStyle == "SYMBOL_TEXT" then
        return string.format(" %s %s[%s]|r", symbol, color, info.short)
    end
    return " " .. symbol
end


-- Detailed evaluation for debug / self-test (same rules as GetCompatibility).
function RD.ExplainCompatibility(name, realm)
    local result = {
        name = name,
        realm = realm,
        hasRealm = (realm and realm ~= "") and true or false,
        inGuild = false,
        sameCluster = false,
        cacheHit = false,
        verdict = "UNKNOWN",
        annotation = "",
        fullName = "",
        myRealm = GetRealmName() or "",
        cluster = MyCluster(),
    }

    if not name or name == "" then
        return result
    end

    result.fullName = result.hasRealm and (name .. "-" .. realm) or name
    result.inGuild = IsInMyGuild(result.fullName)

    local key = table.concat({
        Normalize(name),
        Normalize(realm or ""),
        result.inGuild and "1" or "0",
    }, "|")
    result.cacheHit = compatibilityCache[key] ~= nil

    if result.hasRealm then
        result.sameCluster = SameConnectedRealm(realm) and true or false
        if result.sameCluster then
            result.verdict = "PERSONAL"
        elseif result.inGuild then
            result.verdict = "GUILD"
        else
            result.verdict = "NONE"
        end
    else
        result.sameCluster = SameConnectedRealm(result.myRealm) and true or false
        if result.sameCluster then
            result.verdict = "PERSONAL"
        elseif result.inGuild then
            result.verdict = "GUILD"
        else
            result.verdict = "UNKNOWN"
        end
    end

    compatibilityCache[key] = result.verdict
    result.annotation = GetAnnotation(result.verdict)
    return result
end

local function IsPlayerSelf(sender, guid)
    if guid and UnitGUID("player") == guid then return true end
    if not sender then return false end
    local senderName = sender:match("^([^%-]+)") or sender
    return senderName == UnitName("player")
end

-- Annotation goes into the message body only — never into `sender`.
-- Touching sender breaks Blizzard's player hyperlink parser.
local function ChatFilter(_, event, message, sender, ...)
    if not IsEventEnabled(event) or not sender or sender == "" then return end
    if IsPlayerSelf(sender, select(10, ...)) then return end  -- guid

    local name, realm = RD.SplitPlayerName(sender)
    if not name then return end

    local verdict = RD.GetCompatibility(name, realm)
    local flag = VERDICT_FLAG[verdict]
    if not flag or not db[flag] then
        if RD.DebugIsEnabled and RD.DebugIsEnabled() then
            RD.DebugLog(string.format("skip %s (%s) verdict=%s hidden",
                sender, event, tostring(verdict)))
        end
        return
    end

    local annotation = GetAnnotation(verdict)
    if annotation == "" then return end

    if RD.DebugIsEnabled and RD.DebugIsEnabled() then
        RD.DebugLog(string.format("%s | %s | %s | %s",
            event, sender, verdict, (realm or "(no realm)")))
    end

    local newMessage
    if db.annotationPosition == "BEFORE" then
        newMessage = annotation:gsub("^%s+", "") .. " " .. message
    else
        newMessage = message .. annotation
    end

    return false, newMessage, sender, ...
end

local CHAT_EVENTS = {
    "CHAT_MSG_WHISPER", "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
}

-- ------------------------------------------------------------
-- Minimap
-- ------------------------------------------------------------

local function SetupMinimapButton()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not LDB or not Icon then return end

    local broker = LDB:NewDataObject("RealmDisplay", {
        type = "launcher",
        icon = "Interface\\Icons\\Trade_blacksmithing",
        label = "Realm Display",
        OnClick = function()
            if RD.OpenSettings then RD.OpenSettings() end
        end,
        OnTooltipShow = function(tip)
            tip:AddLine("|cff" .. RD.ACCENT .. "Realm Display|r")
            tip:AddLine("Crafting compatibility is displayed directly in chat.", 1, 1, 1, true)
            tip:AddLine(" ")
            tip:AddLine("|cff888888Click|r open settings")
        end,
    })

    Icon:Register("RealmDisplay", broker, db.minimap)
    if db.minimap.hide then Icon:Hide("RealmDisplay") end
end

function RD.ToggleMinimap()
    db.minimap.hide = not db.minimap.hide
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if Icon then
        if db.minimap.hide then Icon:Hide("RealmDisplay") else Icon:Show("RealmDisplay") end
    end
    return not db.minimap.hide
end

-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

SLASH_REALMDISPLAY1 = "/rd"
SLASH_REALMDISPLAY2 = "/realmdisplay"

SlashCmdList["REALMDISPLAY"] = function(msg)
    if not db then
        print(RD.PFX .. "Still loading.")
        return
    end

    local raw = strtrim(msg or "")
    local cmd, rest = raw:match("^%s*(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "config" or cmd == "settings" then
        if RD.OpenSettings then RD.OpenSettings() end

    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        print(RD.PFX .. "Chat annotations " .. (db.enabled and "|cff44ff44enabled|r" or "|cffff4444disabled|r"))

    elseif cmd == "status" then
        print(RD.PFX .. "Chat annotations: " .. (db.enabled and "|cff44ff44enabled|r" or "|cffff4444disabled|r"))
        print(RD.PFX .. "Position: " .. tostring(db.annotationPosition))
        print(RD.PFX .. "Style: " .. tostring(db.annotationStyle))

    elseif cmd == "check" then
        if rest == "" then
            print(RD.PFX .. "Usage: /rd check <name-Realm>")
            return
        end
        local name, realm = RD.SplitPlayerName(rest)
        if not name then
            print(RD.PFX .. "Invalid player name.")
            return
        end
        local info = RD.VERDICT[RD.GetCompatibility(name, realm)]
        if not info then
            print(RD.PFX .. "Unknown compatibility.")
            return
        end
        print(RD.PFX .. rest .. " -> " .. string.format(
            "|cff%02x%02x%02x%s|r",
            math.floor(info.r * 255), math.floor(info.g * 255), math.floor(info.b * 255),
            info.text
        ))

    elseif cmd == "clearcache" then
        RD.ClearCompatibilityCache()
        RD.InvalidateGuildRosterCache()
        print(RD.PFX .. "Compatibility and guild caches cleared.")

    elseif cmd == "minimap" then
        local shown = RD.ToggleMinimap()
        print(RD.PFX .. "Minimap button " .. (shown and "|cff44ff44shown|r" or "|cffff4444hidden|r"))

    elseif cmd == "debug" then
        if RD.ToggleDebugWindow then
            RD.ToggleDebugWindow()
        else
            print(RD.PFX .. "Debug UI not loaded.")
        end

    elseif cmd == "test" then
        if RD.RunSelfTest then
            RD.RunSelfTest(rest ~= "" and rest or nil)
        else
            print(RD.PFX .. "Debug self-test not loaded.")
        end

    else
        print(RD.PFX .. "Commands:")
        print("  /rd                  — open settings")
        print("  /rd config           — open settings")
        print("  /rd toggle           — enable/disable annotations")
        print("  /rd status           — show current settings")
        print("  /rd check <player>   — check a player")
        print("  /rd clearcache       — clear detection caches")
        print("  /rd minimap          — toggle minimap button")
        print("  /rd debug            — open debug window")
        print("  /rd test [player]    — run self-test cases")
    end
end

-- ------------------------------------------------------------
-- Init
-- ------------------------------------------------------------

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        RealmDisplayDB = RealmDisplayDB or {}
        CopyDefaults(RealmDisplayDB, RD.DEFAULTS)
        db = RealmDisplayDB
        RD.db = db

        for _, ev in ipairs(CHAT_EVENTS) do
            ChatFrame_AddMessageEventFilter(ev, ChatFilter)
        end

        if RD.InitSettings then RD.InitSettings() end
        if RD.InitDebug then RD.InitDebug() end
        SetupMinimapButton()

    elseif event == "PLAYER_LOGIN"
        or event == "GUILD_ROSTER_UPDATE"
        or event == "PLAYER_GUILD_UPDATE"
    then
        RD.InvalidateGuildRosterCache()
        RD.ClearCompatibilityCache()
    end
end)