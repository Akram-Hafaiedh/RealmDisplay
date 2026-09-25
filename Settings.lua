-- ============================================================
-- RealmDisplay — Standalone Settings Panel
-- ============================================================

local ADDON, RD = ...

local function Checkbox(parent, label, tooltip, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)

    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)

    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        PlaySound(self:GetChecked() and 856 or 857)
    end)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, nil, nil, nil, nil, true)
        if tooltip then GameTooltip:AddLine(tooltip, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cb.Refresh = function(self) self:SetChecked(get() and true or false) end
    return cb
end

local function Header(parent, text)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    fs:SetText(text)
    fs:SetTextColor(1, 0.82, 0)
    return fs
end

local function Cycle(parent, label, options, get, set)
    local box = CreateFrame("Frame", nil, parent)
    box:SetSize(340, 28)

    local title = box:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("LEFT")
    title:SetWidth(120)
    title:SetJustifyH("LEFT")
    title:SetText(label)

    local btn = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    btn:SetSize(190, 24)
    btn:SetPoint("LEFT", title, "RIGHT", 8, 0)

    local function Index()
        local cur = get()
        for i, opt in ipairs(options) do
            if opt.value == cur then return i end
        end
        return 1
    end

    local function Refresh()
        local opt = options[Index()]
        btn:SetText(opt and opt.text or "?")
    end

    btn:SetScript("OnClick", function()
        local i = Index() % #options + 1
        set(options[i].value)
        Refresh()
        PlaySound(856)
    end)

    box.Refresh = Refresh
    Refresh()
    return box
end

function RD.InitSettings()
    local frame = CreateFrame("Frame", "RealmDisplaySettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()

    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)

    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetPoint("TOP", 0, 12)
    titleBg:SetSize(360, 64)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", titleBg, "TOP", 0, -14)
    title:SetText("|cff" .. RD.ACCENT .. "Realm Display|r")

    local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -18)
    subtitle:SetText("Crafting compatibility annotations for chat.")
    subtitle:SetTextColor(0.7, 0.7, 0.7)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        frame:Hide()
        PlaySound(624)
    end)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 28, -60)
    content:SetPoint("BOTTOMRIGHT", -28, 52)

    local y, left, widgets = 0, 0, {}

    local function Place(w, dy)
        w:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
        y = y - (dy or 28)
        widgets[#widgets + 1] = w
        return w
    end

    local function DB() return RD.db end

    -- General
    Place(Header(content, "General"), 28)
    Place(Checkbox(content, "Enable chat annotations",
        "Show crafting compatibility next to chat senders.",
        function() return DB().enabled end,
        function(v) DB().enabled = v end))
    Place(Checkbox(content, "Show minimap button",
        "Toggle the minimap button visibility.",
        function() return not DB().minimap.hide end,
        function(v)
            DB().minimap.hide = not v
            local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
            if Icon then
                if DB().minimap.hide then Icon:Hide("RealmDisplay") else Icon:Show("RealmDisplay") end
            end
        end), 36)

    -- Annotation
    Place(Header(content, "Annotation"), 28)
    Place(Cycle(content, "Position", {
        { value = "AFTER",  text = "After message" },
        { value = "BEFORE", text = "Before message" },
    }, function() return DB().annotationPosition end,
       function(v) DB().annotationPosition = v end))
    Place(Cycle(content, "Style", {
        { value = "SYMBOL",      text = "Symbol only" },
        { value = "TEXT",        text = "Short text" },
        { value = "SYMBOL_TEXT", text = "Symbol + text" },
    }, function() return DB().annotationStyle end,
       function(v) DB().annotationStyle = v end), 36)

    -- Verdict visibility
    Place(Header(content, "Verdict visibility"), 28)
    Place(Checkbox(content, "Show Personal",
        "Show the personal-order marker.",
        function() return DB().showPersonal end,
        function(v) DB().showPersonal = v end))
    Place(Checkbox(content, "Show Guild",
        "Show the guild-order marker.",
        function() return DB().showGuild end,
        function(v) DB().showGuild = v end))
    Place(Checkbox(content, "Show Incompatible",
        "Show the incompatible marker.",
        function() return DB().showNone end,
        function(v) DB().showNone = v end))
    Place(Checkbox(content, "Show Unknown",
        "Show a marker when realm cannot be determined.",
        function() return DB().showUnknown end,
        function(v) DB().showUnknown = v end), 36)

    -- Channels (two columns)
    Place(Header(content, "Chat channels"), 28)
    local channels = {
        { "whisper", "Whisper" }, { "trade", "Trade" },
        { "public", "Public channels" }, { "say", "Say" },
        { "yell", "Yell" }, { "party", "Party" },
        { "raid", "Raid" }, { "instance", "Instance" },
        { "guild", "Guild" }, { "officer", "Officer" },
    }
    local channelY = y
    for i, opt in ipairs(channels) do
        local key, name = opt[1], opt[2]
        local cb = Checkbox(content, name, "Annotate " .. name .. " messages.",
            function() return DB().channels[key] end,
            function(v) DB().channels[key] = v end)
        if i <= 5 then
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", left, channelY - (i - 1) * 28)
        else
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", 240, channelY - (i - 6) * 28)
        end
        widgets[#widgets + 1] = cb
    end

    local done = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    done:SetSize(100, 24)
    done:SetPoint("BOTTOM", 0, 18)
    done:SetText("Close")
    done:SetScript("OnClick", function()
        frame:Hide()
        PlaySound(624)
    end)

    frame:SetScript("OnShow", function()
        for _, w in ipairs(widgets) do
            if w.Refresh then w:Refresh() end
        end
        PlaySound(850)
    end)

    table.insert(UISpecialFrames, frame:GetName())
    RD.settingsFrame = frame
end

function RD.OpenSettings()
    local frame = RD.settingsFrame
    if not frame then
        print(RD.PFX .. "Settings panel is not ready yet.")
        return
    end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end