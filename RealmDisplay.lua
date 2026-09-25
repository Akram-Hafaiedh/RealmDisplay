-- ============================================================
-- RealmDisplay — Crafting Compatibility (Chat First)
-- WoW Retail / Midnight 12.x
-- ============================================================

local ADDON, RD = ...

RD.ACCENT = "4FC3F7"
RD.PFX = "|cff" .. RD.ACCENT .. "RealmDisplay:|r "

RD.DEFAULTS = {
    enabled = true,
    annotationPosition = "AFTER",
    annotationStyle = "TEXT",
    showPersonal = true,
    showGuild = true,
    showNone = true,
    showUnknown = true,
    channels = {
        whisper = true, trade = true, public = true,
        say = true, yell = true,
        party = true, raid = true, instance = true,
        guild = false, officer = false,
    },
    minimap = { hide = false },
}

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

    if db.annotationStyle == "TEXT" then
        return string.format(" %s[%s]|r", color, info.short)
    end
    if db.annotationStyle == "SYMBOL_TEXT" then
        return string.format(" %s %s[%s]|r", info.symbol, color, info.short)
    end
    return " " .. info.symbol
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
    if not flag or not db[flag] then return end

    local annotation = GetAnnotation(verdict)
    if annotation == "" then return end

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
        print(RD.PFX .. "Debug information:")
        print("  Enabled: " .. tostring(db.enabled))
        print("  Position: " .. tostring(db.annotationPosition))
        print("  Style: " .. tostring(db.annotationStyle))
        print("  Realm: " .. tostring(GetRealmName()))
        local cluster = MyCluster()
        print("  Connected realms: " .. tostring(#cluster))
        for _, realm in ipairs(cluster) do print("    " .. realm) end

    else
        print(RD.PFX .. "Commands:")
        print("  /rd                  — open settings")
        print("  /rd config           — open settings")
        print("  /rd toggle           — enable/disable annotations")
        print("  /rd status           — show current settings")
        print("  /rd check <player>   — check a player")
        print("  /rd clearcache       — clear detection caches")
        print("  /rd minimap          — toggle minimap button")
        print("  /rd debug            — debug realm information")
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
        SetupMinimapButton()

    elseif event == "PLAYER_LOGIN"
        or event == "GUILD_ROSTER_UPDATE"
        or event == "PLAYER_GUILD_UPDATE"
    then
        RD.InvalidateGuildRosterCache()
        RD.ClearCompatibilityCache()
    end
end)