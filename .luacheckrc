-- Luacheck config for RealmDisplay (WoW retail addon).
-- Run from the repo root: `luacheck .`

-- WoW's client Lua runtime is a 5.1 dialect (with a handful of
-- 5.2-style additions Blizzard backports); 5.1 is the closest match.
std = "lua51"

-- Addon files are loaded by the game, not required as modules.
self = false

max_line_length = 120

-- SavedVariables and addon-scoped globals this addon intentionally
-- declares at file scope (see RealmDisplay.toc).
globals = {
    "RealmDisplayDB",
    "UpdateDisplay",
    "SLASH_REALMDISPLAY1",
    "SLASH_REALMDISPLAY2",
}

-- Everything below is read-only: Blizzard API functions/objects and
-- widget templates this addon calls but never defines. Keeping this
-- list explicit (instead of `ignore`-ing undefined-global warnings
-- wholesale) means luacheck still catches real typos in our own code.
read_globals = {
    -- Frame/Widget API
    "CreateFrame",
    "UIParent",
    "GameTooltip",
    "PlaySound",

    -- Unit / player / target
    "UnitExists",
    "UnitIsPlayer",
    "UnitIsUnit",
    "UnitFullName",
    "GetRealmName",
    "GetAutoCompleteRealms",
    "GetGuildInfo",
    "IsInGuild",
    "GetNumGuildMembers",
    "GetGuildRosterInfo",

    -- Chat
    "NUM_CHAT_WINDOWS",
    "ChatFrame_AddMessageEventFilter",
    "ChatEdit_InsertLink",

    -- Menu API (retail, 10.1.5+)
    "Menu",

    -- Settings API (retail 10.0+)
    "Settings",

    -- Minimap libs (LibStub-based, optional at runtime)
    "LibStub",

    -- Misc Blizzard globals referenced indirectly via templates
    "SlashCmdList",
    "hooksecurefunc",
    "C_Timer",
    "strtrim",
    "wipe",
    "UnitGUID",
    "UnitName",
}

-- Generated/template-populated globals (e.g. RealmDisplayNotifyCBText
-- from "InterfaceOptionsCheckButtonTemplate") are read via _G[...]
-- lookups in the code, so no extra globals are needed here for those.

exclude_files = {
    "generate_icons.ps1",
}