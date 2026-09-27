-- ============================================================
-- RealmDisplay — Premium Standalone Settings Panel
-- ============================================================

local ADDON, RD = ...

local ACCENT = { 0.31, 0.76, 0.97 }
local BG     = { 0.06, 0.07, 0.09, 0.97 }
local BORDER = { 0.22, 0.24, 0.28, 1 }
local MUTED  = { 0.55, 0.58, 0.62 }
local TEXT   = { 0.92, 0.93, 0.95 }
local ROW_H  = 36

local function DB() return RD.db end

local function SetTextColor(fs, c)
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
end

local function Tooltip(frame, title, body)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, ACCENT[1], ACCENT[2], ACCENT[3], 1, true)
        if body then GameTooltip:AddLine(body, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ============================================================
-- Toggle switch
-- ============================================================

local function Toggle(parent, label, tooltip, get, set)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetPoint("LEFT", 0, 0)
    name:SetText(label)
    SetTextColor(name, TEXT)

    local track = CreateFrame("Button", nil, row)
    track:SetSize(44, 22)
    track:SetPoint("RIGHT", 0, 0)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()

    local knob = track:CreateTexture(nil, "OVERLAY")
    knob:SetSize(18, 18)
    knob:SetColorTexture(1, 1, 1, 1)

    local function Paint(on)
        if on then
            trackBg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.85)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", track, "RIGHT", -2, 0)
        else
            trackBg:SetColorTexture(0.18, 0.20, 0.24, 1)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", track, "LEFT", 2, 0)
        end
    end

    track:SetScript("OnClick", function()
        local on = not get()
        set(on)
        Paint(on)
        PlaySound(on and 856 or 857)
    end)

    Tooltip(track, label, tooltip)
    row.Refresh = function() Paint(get() and true or false) end
    row.Refresh()
    return row
end

-- ============================================================
-- Segmented control
-- ============================================================

local function Segmented(parent, label, options, get, set, onChange)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H + 8)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetPoint("TOPLEFT", 0, 0)
    name:SetText(label)
    SetTextColor(name, TEXT)

    local bar = CreateFrame("Frame", nil, row, "BackdropTemplate")
    bar:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
    bar:SetSize(420, 28)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0.08, 0.09, 0.11, 1)
    bar:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)

    local buttons = {}
    local w = 420 / #options

    local function Paint()
        local cur = get()
        for _, b in ipairs(buttons) do
            if b.value == cur then
                b.bg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.35)
                b.label:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
            else
                b.bg:SetColorTexture(0, 0, 0, 0)
                SetTextColor(b.label, MUTED)
            end
        end
    end

    for i, opt in ipairs(options) do
        local b = CreateFrame("Button", nil, bar)
        b:SetSize(w, 28)
        b:SetPoint("LEFT", (i - 1) * w, 0)
        b.value = opt.value
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.label:SetPoint("CENTER")
        b.label:SetText(opt.text)
        b:SetScript("OnClick", function()
            set(opt.value)
            Paint()
            PlaySound(856)
            if onChange then onChange(opt.value) end
        end)
        buttons[#buttons + 1] = b
    end

    row.Refresh = Paint
    Paint()
    return row
end

-- ============================================================
-- Compact symbol dropdown (one menu, one choice)
-- ============================================================

-- Keep the list short and meaningful — not every raid marker.
local PRESET_ORDER = { "check", "cross", "wait", "diamond", "star", "skull" }

local openMenu -- forward decl so only one menu is open at a time

local function CloseSymbolMenu()
    if openMenu then
        openMenu:Hide()
        openMenu = nil
    end
end

local function SymbolDropdown(parent, verdictKey, label)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)

    local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetPoint("LEFT", 0, 0)
    name:SetWidth(130)
    name:SetJustifyH("LEFT")
    name:SetText(label)
    SetTextColor(name, TEXT)

    local preview = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    preview:SetPoint("LEFT", name, "RIGHT", 4, 0)
    preview:SetWidth(24)

    local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
    btn:SetSize(170, 26)
    btn:SetPoint("RIGHT", 0, 0)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.12, 0.13, 0.16, 1)
    btn:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", 10, 0)

    local caret = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    caret:SetPoint("RIGHT", -8, 0)
    caret:SetText("v")
    SetTextColor(caret, MUTED)

    local function CurrentKey()
        local d = DB()
        return (d.symbols and d.symbols[verdictKey]) or RD.DEFAULTS.symbols[verdictKey]
    end

    local function Refresh()
        local key = CurrentKey()
        local preset = RD.SYMBOL_PRESETS[key]
        preview:SetText(preset and preset.tex or "")
        btnText:SetText(preset and preset.label or key)
        SetTextColor(btnText, TEXT)
    end

    -- Dropdown list (created once per row, shown on click)
    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetSize(170, #PRESET_ORDER * 26 + 8)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(0.08, 0.09, 0.11, 0.98)
    menu:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)
    menu:Hide()
    menu:EnableMouse(true)

    for i, key in ipairs(PRESET_ORDER) do
        local preset = RD.SYMBOL_PRESETS[key]
        local opt = CreateFrame("Button", nil, menu)
        opt:SetSize(162, 24)
        opt:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 26)

        local hl = opt:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.2)

        local icon = opt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        icon:SetPoint("LEFT", 6, 0)
        icon:SetText(preset and preset.tex or "")

        local lbl = opt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", 28, 0)
        lbl:SetText(preset and preset.label or key)
        SetTextColor(lbl, TEXT)

        opt:SetScript("OnClick", function()
            DB().symbols = DB().symbols or {}
            DB().symbols[verdictKey] = key
            CloseSymbolMenu()
            Refresh()
            PlaySound(856)
        end)
    end

    btn:SetScript("OnClick", function()
        if openMenu == menu and menu:IsShown() then
            CloseSymbolMenu()
            return
        end
        CloseSymbolMenu()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        menu:Show()
        openMenu = menu
        PlaySound(856)
    end)

    -- Click outside closes
    menu:SetScript("OnHide", function()
        if openMenu == menu then openMenu = nil end
    end)

    Tooltip(btn, label, "Choose the icon used for this verdict in chat.")
    row.Refresh = Refresh
    Refresh()
    row.menu = menu
    return row
end

local function Section(parent, text)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(28)

    local fs = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("LEFT", 0, 0)
    fs:SetText(text:upper())
    fs:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    line:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.8)

    return row
end

-- ============================================================
-- Build panel
-- ============================================================

function RD.InitSettings()
    local frame = CreateFrame("Frame", "RealmDisplaySettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(520, 640)
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
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(BG[1], BG[2], BG[3], BG[4])
    frame:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)

    local topBar = frame:CreateTexture(nil, "ARTWORK")
    topBar:SetHeight(3)
    topBar:SetPoint("TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", -1, -1)
    topBar:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 24, -18)
    title:SetText("Realm Display")
    SetTextColor(title, TEXT)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetText("Crafting compatibility annotations")
    SetTextColor(subtitle, MUTED)

    local close = RD.CreateCloseButton(frame, function()
        CloseSymbolMenu()
        frame:Hide()
    end)
    close:SetPoint("TOPRIGHT", -10, -12)

    local scroll, content = RD.CreateScrollFrame(frame)
    scroll:SetPoint("TOPLEFT", 20, -56)
    scroll:SetPoint("BOTTOMRIGHT", -18, 52)
    content:SetWidth(440)

    local widgets = {}
    local symbolBlock = {} -- rows that only matter when style uses symbols

    local function Relayout()
        local y = 0
        local style = DB().annotationStyle
        local showSymbols = (style == "SYMBOL" or style == "SYMBOL_TEXT")

        for _, w in ipairs(widgets) do
            local isSymbol = w._symbolBlock
            if isSymbol and not showSymbols then
                w:Hide()
            else
                w:Show()
                w:ClearAllPoints()
                w:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
                w:SetPoint("RIGHT", content, "RIGHT", 0, 0)
                y = y - w:GetHeight() - (w._gap or 6)
            end
        end
        content:SetHeight(math.abs(y) + 20)
        if scroll.UpdateThumb then scroll:UpdateThumb() end
    end

    local function Place(w, gap, symbolOnly)
        w._gap = gap or 6
        w._symbolBlock = symbolOnly and true or false
        widgets[#widgets + 1] = w
        if symbolOnly then symbolBlock[#symbolBlock + 1] = w end
        return w
    end

    -- General
    Place(Section(content, "General"), 10)
    Place(Toggle(content, "Enable chat annotations",
        "Show crafting compatibility next to chat senders.",
        function() return DB().enabled end,
        function(v) DB().enabled = v end))
    Place(Toggle(content, "Show minimap button",
        "Toggle the minimap button visibility.",
        function() return not DB().minimap.hide end,
        function(v)
            DB().minimap.hide = not v
            local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
            if Icon then
                if DB().minimap.hide then Icon:Hide("RealmDisplay") else Icon:Show("RealmDisplay") end
            end
        end), 14)

    -- Annotation
    Place(Section(content, "Annotation"), 10)
    Place(Segmented(content, "Position", {
        { value = "BEFORE", text = "Before message" },
        { value = "AFTER",  text = "After message" },
    }, function() return DB().annotationPosition end,
       function(v) DB().annotationPosition = v end), 8)

    Place(Segmented(content, "Style", {
        { value = "SYMBOL",      text = "Symbol" },
        { value = "TEXT",        text = "Text" },
        { value = "SYMBOL_TEXT", text = "Both" },
    }, function() return DB().annotationStyle end,
       function(v) DB().annotationStyle = v end,
       function() Relayout() end), 14)

    -- Symbols (only when Style is Symbol or Both)
    Place(Section(content, "Symbols"), 10, true)
    Place(SymbolDropdown(content, "PERSONAL", "Personal"), 6, true)
    Place(SymbolDropdown(content, "GUILD", "Guild"), 6, true)
    Place(SymbolDropdown(content, "NONE", "Incompatible"), 6, true)
    Place(SymbolDropdown(content, "UNKNOWN", "Unknown"), 14, true)

    -- Verdict visibility
    Place(Section(content, "Verdict visibility"), 10)
    Place(Toggle(content, "Show Personal",
        "Show the personal-order marker.",
        function() return DB().showPersonal end,
        function(v) DB().showPersonal = v end))
    Place(Toggle(content, "Show Guild",
        "Show the guild-order marker.",
        function() return DB().showGuild end,
        function(v) DB().showGuild = v end))
    Place(Toggle(content, "Show Incompatible",
        "Show the incompatible marker.",
        function() return DB().showNone end,
        function(v) DB().showNone = v end))
    Place(Toggle(content, "Show Unknown",
        "Show a marker when realm cannot be determined.",
        function() return DB().showUnknown end,
        function(v) DB().showUnknown = v end), 14)

    -- Channels
    Place(Section(content, "Chat channels"), 10)
    local channels = {
        { "whisper", "Whisper" }, { "trade", "Trade" },
        { "public", "Public channels" }, { "say", "Say" },
        { "yell", "Yell" }, { "party", "Party" },
        { "raid", "Raid" }, { "instance", "Instance" },
        { "guild", "Guild" }, { "officer", "Officer" },
    }
    for _, opt in ipairs(channels) do
        local key, name = opt[1], opt[2]
        Place(Toggle(content, name, "Annotate " .. name .. " messages.",
            function() return DB().channels[key] end,
            function(v) DB().channels[key] = v end))
    end

    Relayout()

    local done = CreateFrame("Button", nil, frame, "BackdropTemplate")
    done:SetSize(120, 28)
    done:SetPoint("BOTTOM", 0, 14)
    done:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    done:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.25)
    done:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.7)

    local doneText = done:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    doneText:SetPoint("CENTER")
    doneText:SetText("Close")
    doneText:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

    done:SetScript("OnEnter", function(self)
        self:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.45)
    end)
    done:SetScript("OnLeave", function(self)
        self:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.25)
    end)
    done:SetScript("OnClick", function()
        CloseSymbolMenu()
        frame:Hide()
        PlaySound(624)
    end)

    frame:SetScript("OnShow", function()
        CloseSymbolMenu()
        for _, w in ipairs(widgets) do
            if w.Refresh then w:Refresh() end
        end
        Relayout()
        PlaySound(850)
    end)

    frame:SetScript("OnHide", CloseSymbolMenu)

    table.insert(UISpecialFrames, frame:GetName())
    RD.settingsFrame = frame
end

function RD.OpenSettings()
    local f = RD.settingsFrame
    if not f then
        print(RD.PFX .. "Settings panel is not ready yet.")
        return
    end
    if f:IsShown() then f:Hide() else f:Show() end
end