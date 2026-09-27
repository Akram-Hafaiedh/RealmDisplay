-- ============================================================
-- RealmDisplay — Debug window, log, self-test
-- Pattern inspired by CraftBell: real APIs + synthetic cases
-- ============================================================

local ADDON, RD = ...

local MAX_LOG = 200
local logBuffer = {} -- { t=, text= }, newest last

local ACCENT = { 0.31, 0.76, 0.97 }
local BG     = { 0.06, 0.07, 0.09, 0.97 }
local BORDER = { 0.22, 0.24, 0.28, 1 }
local MUTED  = { 0.55, 0.58, 0.62 }
local TEXT   = { 0.92, 0.93, 0.95 }

-- Pipeline step template for a single evaluation
local STEP_ORDER = {
    { key = "db",        label = "Database ready" },
    { key = "enabled",   label = "Annotations enabled" },
    { key = "parse",     label = "Name / realm parsed" },
    { key = "cluster",   label = "Connected-realm check" },
    { key = "guild",     label = "Guild membership check" },
    { key = "verdict",   label = "Verdict chosen" },
    { key = "visible",   label = "Verdict visible in settings" },
    { key = "annotate",  label = "Annotation string built" },
}

RD.debugLastRun = nil
RD.debugCurrentRun = nil

local debugFrame

----------------------------------------------------------------------
-- Enable flag
----------------------------------------------------------------------

function RD.DebugIsEnabled()
    if RD.debugEnabled then return true end
    local d = RD.db
    return d and d.debugEnabled == true
end

function RD.SetDebugEnabled(on)
    RD.debugEnabled = on and true or false
    if RD.db then RD.db.debugEnabled = RD.debugEnabled end
end

----------------------------------------------------------------------
-- Log buffer
----------------------------------------------------------------------

function RD.DebugLog(msg, opts)
    opts = opts or {}
    local entry = { t = date("%H:%M:%S"), text = tostring(msg) }
    logBuffer[#logBuffer + 1] = entry
    while #logBuffer > MAX_LOG do
        table.remove(logBuffer, 1)
    end

    if not opts.silent and RD.DebugIsEnabled() then
        print("|cff888888[RD-Debug]|r " .. entry.text)
    end

    if debugFrame and debugFrame:IsShown() and debugFrame.RefreshLog then
        debugFrame:RefreshLog()
    end
end

function RD.GetDebugLogText()
    local lines = {}
    for _, e in ipairs(logBuffer) do
        lines[#lines + 1] = string.format("[%s] %s", e.t, e.text)
    end
    return table.concat(lines, "\n")
end

function RD.ClearDebugLog()
    wipe(logBuffer)
    if debugFrame and debugFrame:IsShown() and debugFrame.RefreshLog then
        debugFrame:RefreshLog()
    end
end

----------------------------------------------------------------------
-- Run / steps
----------------------------------------------------------------------

function RD.DebugBeginRun(mode, note)
    local run = {
        mode = mode or "live",
        started = time(),
        startedStr = date("%H:%M:%S"),
        note = note,
        steps = {},
        byKey = {},
    }
    RD.debugCurrentRun = run
    RD.DebugLog(string.format("── %s started%s",
        mode == "selftest" and "Self-test" or "Run",
        note and (" — " .. note) or ""), { silent = not RD.DebugIsEnabled() })
    return run
end

function RD.DebugStep(key, ok, detail)
    local run = RD.debugCurrentRun
    if not run then
        if RD.DebugIsEnabled() then
            run = RD.DebugBeginRun("live")
        else
            return
        end
    end

    local step = { key = key, ok = ok and true or false, detail = detail and tostring(detail) or nil }
    if run.byKey[key] then
        run.byKey[key].ok = step.ok
        run.byKey[key].detail = step.detail
    else
        run.steps[#run.steps + 1] = step
        run.byKey[key] = step
    end

    RD.DebugLog(string.format("  [%s] %s%s",
        step.ok and "OK" or "FAIL",
        key,
        step.detail and (" — " .. step.detail) or ""),
        { silent = not RD.DebugIsEnabled() })

    if debugFrame and debugFrame:IsShown() and debugFrame.RefreshChecklist then
        debugFrame:RefreshChecklist()
    end
end

function RD.DebugEndRun()
    local run = RD.debugCurrentRun
    if not run then return end
    RD.debugLastRun = run
    RD.debugCurrentRun = nil

    local pass, fail = 0, 0
    for _, s in ipairs(run.steps) do
        if s.ok then pass = pass + 1 else fail = fail + 1 end
    end
    RD.DebugLog(string.format("── done — %d ok, %d fail", pass, fail),
        { silent = not RD.DebugIsEnabled() })

    if debugFrame and debugFrame:IsShown() then
        if debugFrame.RefreshChecklist then debugFrame:RefreshChecklist() end
        if debugFrame.RefreshLog then debugFrame:RefreshLog() end
    end
    return run
end

function RD.GetDebugRunForDisplay()
    return RD.debugCurrentRun or RD.debugLastRun
end

local function OrderedSteps(run)
    if not run then return {} end
    local out, seen = {}, {}
    for _, def in ipairs(STEP_ORDER) do
        local s = run.byKey[def.key]
        if s then
            out[#out + 1] = { key = def.key, label = def.label, ok = s.ok, detail = s.detail }
            seen[def.key] = true
        else
            out[#out + 1] = { key = def.key, label = def.label, ok = nil, detail = "not run" }
        end
    end
    for _, s in ipairs(run.steps) do
        if not seen[s.key] then
            out[#out + 1] = { key = s.key, label = s.key, ok = s.ok, detail = s.detail }
        end
    end
    return out
end

----------------------------------------------------------------------
-- Record one evaluation into the current run
----------------------------------------------------------------------

local function RecordExplain(result, label)
    RD.DebugStep("parse", result.name and result.name ~= "",
        string.format("%s / %s",
            tostring(result.name),
            result.hasRealm and tostring(result.realm) or "(no realm)"))

    RD.DebugStep("cluster", true,
        string.format("same=%s  my=%s  cluster=%d",
            tostring(result.sameCluster),
            result.myRealm,
            result.cluster and #result.cluster or 0))

    RD.DebugStep("guild", true,
        result.inGuild and "in guild roster" or "not in guild")

    RD.DebugStep("verdict", result.verdict ~= nil,
        string.format("%s%s",
            tostring(result.verdict),
            result.cacheHit and " (cache)" or ""))

    local d = RD.db
    local flag = ({
        PERSONAL = "showPersonal",
        GUILD = "showGuild",
        NONE = "showNone",
        UNKNOWN = "showUnknown",
    })[result.verdict]
    local visible = flag and d and d[flag]
    RD.DebugStep("visible", visible and true or false,
        visible and "shown in chat" or "hidden by settings")

    local ann = result.annotation or ""
    RD.DebugStep("annotate", ann ~= "",
        ann ~= "" and ann:gsub("|T.-|t", "[icon]"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") or "empty")

    if label then
        RD.DebugLog(string.format("case %s → %s", label, tostring(result.verdict)))
    end
end

----------------------------------------------------------------------
-- Self-test: real realm/guild APIs + synthetic player cases
----------------------------------------------------------------------

function RD.RunSelfTest(optionalPlayer)
    local was = RD.debugEnabled
    RD.debugEnabled = true

    RD.DebugBeginRun("selftest", optionalPlayer or "synthetic cases")

    local d = RD.db
    RD.DebugStep("db", d ~= nil, d and "RealmDisplayDB bound" or "nil")
    RD.DebugStep("enabled", d and d.enabled,
        d and d.enabled and "annotations on" or "annotations off")

    local myRealm = GetRealmName() or "Unknown"
    local cluster = RD.GetMyCluster and RD.GetMyCluster() or { myRealm }

    -- Case list: synthetic inputs, real environment
    local cases = {}

    if optionalPlayer and optionalPlayer ~= "" then
        cases[#cases + 1] = { label = "user:" .. optionalPlayer, input = optionalPlayer }
    end

    -- Same realm, realm tag omitted (common in same-realm chat)
    cases[#cases + 1] = { label = "same-realm (no tag)", input = "RDTestLocal" }

    -- Explicit own realm → PERSONAL
    cases[#cases + 1] = {
        label = "own realm tagged",
        input = "RDTestOwn-" .. myRealm,
    }

    -- Obviously foreign realm → NONE (unless somehow guild)
    cases[#cases + 1] = {
        label = "foreign realm",
        input = "RDTestForeign-SomeFakeRealmZZZ",
    }

    -- Connected realm sibling if any
    for _, r in ipairs(cluster) do
        if r ~= myRealm then
            cases[#cases + 1] = {
                label = "connected sibling",
                input = "RDTestSibling-" .. r,
            }
            break
        end
    end

    local lastResult
    for i, c in ipairs(cases) do
        RD.DebugLog("── case: " .. c.label)
        local name, realm = RD.SplitPlayerName(c.input)
        local result = RD.ExplainCompatibility(name, realm)
        lastResult = result
        RD.DebugStep("case" .. i, result.verdict ~= nil,
            string.format("%s → %s", c.label, tostring(result.verdict)))
    end

    -- Full pipeline detail from the last case (checklist depth)
    if lastResult then
        RecordExplain(lastResult, "last case detail")
    end

    RD.DebugEndRun()
    RD.debugEnabled = was

    local last = RD.debugLastRun
    local fail = 0
    if last then
        for _, s in ipairs(last.steps) do
            if not s.ok then fail = fail + 1 end
        end
    end

    if fail == 0 then
        print(RD.PFX .. "Self-test finished — steps recorded OK. Open /rd debug for details.")
    else
        print(RD.PFX .. string.format("Self-test finished with %d failure(s). Open /rd debug.", fail))
    end

    if RD.ToggleDebugWindow then RD.ToggleDebugWindow(true) end
    return last
end

----------------------------------------------------------------------
-- Debug window UI
----------------------------------------------------------------------

local function EnsureDebugFrame()
    if debugFrame then return debugFrame end

    local f = CreateFrame("Frame", "RealmDisplayDebugFrame", UIParent, "BackdropTemplate")
    f:SetSize(560, 480)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, "RealmDisplayDebugFrame")

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(BG[1], BG[2], BG[3], BG[4])
    f:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)

    local topBar = f:CreateTexture(nil, "ARTWORK")
    topBar:SetHeight(3)
    topBar:SetPoint("TOPLEFT", 1, -1)
    topBar:SetPoint("TOPRIGHT", -1, -1)
    topBar:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
    title:SetText("Realm Display Debug")

    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.subtitle:SetPoint("LEFT", title, "RIGHT", 10, 0)
    f.subtitle:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    f.subtitle:SetText("")

    local closeBtn = RD.CreateCloseButton(f, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", -10, -12)

    -- Left: checklist
    local checkHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkHeader:SetPoint("TOPLEFT", 16, -42)
    checkHeader:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
    checkHeader:SetText("PIPELINE STEPS")

    local checkScroll, checkChild = RD.CreateScrollFrame(f)
    checkScroll:SetPoint("TOPLEFT", 12, -60)
    checkScroll:SetPoint("BOTTOMLEFT", 12, 52)
    checkScroll:SetWidth(240)
    checkChild:SetWidth(220)
    f.checkChild = checkChild
    f.checkScroll = checkScroll

    -- Right: log
    local logHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    logHeader:SetPoint("TOPLEFT", checkScroll, "TOPRIGHT", 28, 18)
    logHeader:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
    logHeader:SetText("LOG")

    local logScroll, logChild = RD.CreateScrollFrame(f)
    logScroll:SetPoint("TOPLEFT", checkScroll, "TOPRIGHT", 24, 0)
    logScroll:SetPoint("BOTTOMRIGHT", -18, 52)

    local logEdit = CreateFrame("EditBox", nil, logChild)
    logEdit:SetMultiLine(true)
    logEdit:SetFontObject(GameFontHighlightSmall)
    logEdit:SetAutoFocus(false)
    logEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    logEdit:SetPoint("TOPLEFT", 0, 0)
    logEdit:SetWidth(250)
    f.logEdit = logEdit
    f.logScroll = logScroll
    f.logChild = logChild

    local function SyncLogSize()
        local w = math.max((logScroll:GetWidth() or 260) - 10, 100)
        logEdit:SetWidth(w)
        -- Height from text: approximate via GetNumLetters is unreliable; use font height * lines
        local text = logEdit:GetText() or ""
        local lines = 1
        for _ in text:gmatch("
") do lines = lines + 1 end
        local h = math.max(lines * 14 + 8, logScroll:GetHeight() or 100)
        logEdit:SetHeight(h)
        logChild:SetSize(w, h)
        if logScroll.UpdateThumb then logScroll:UpdateThumb() end
    end

    logScroll:SetScript("OnSizeChanged", function()
        SyncLogSize()
    end)
    f.SyncLogSize = SyncLogSize

    local function MakeBtn(label, width)
        local b = CreateFrame("Button", nil, f, "BackdropTemplate")
        b:SetSize(width or 100, 26)
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        b:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.2)
        b:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.6)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("CENTER")
        fs:SetText(label)
        fs:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
        b.label = fs
        b:SetScript("OnEnter", function(self)
            self:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.4)
        end)
        b:SetScript("OnLeave", function(self)
            self:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.2)
        end)
        return b
    end

    local selftestBtn = MakeBtn("Run self-test", 120)
    selftestBtn:SetPoint("BOTTOMLEFT", 16, 14)
    selftestBtn:SetScript("OnClick", function() RD.RunSelfTest() end)

    local copyBtn = MakeBtn("Copy all", 90)
    copyBtn:SetPoint("LEFT", selftestBtn, "RIGHT", 8, 0)
    copyBtn:SetScript("OnClick", function()
        local run = RD.GetDebugRunForDisplay()
        local parts = { "=== RealmDisplay Debug ===", "" }
        if run then
            parts[#parts + 1] = string.format("Mode: %s  Started: %s",
                run.mode or "?", run.startedStr or "?")
            parts[#parts + 1] = ""
            parts[#parts + 1] = "-- Steps --"
            for _, s in ipairs(OrderedSteps(run)) do
                local mark = s.ok == true and "OK" or (s.ok == false and "FAIL" or "—")
                parts[#parts + 1] = string.format("[%s] %s%s",
                    mark, s.label or s.key,
                    s.detail and (" — " .. s.detail) or "")
            end
            parts[#parts + 1] = ""
        end
        parts[#parts + 1] = "-- Log --"
        parts[#parts + 1] = RD.GetDebugLogText()
        local text = table.concat(parts, "\n")
        if CopyToClipboard then
            CopyToClipboard(text)
            print(RD.PFX .. "Copied to clipboard.")
        else
            logEdit:SetText(text)
            logEdit:SetFocus()
            logEdit:HighlightText()
            print(RD.PFX .. "Text selected — Ctrl+C to copy.")
        end
    end)

    local clearBtn = MakeBtn("Clear log", 90)
    clearBtn:SetPoint("LEFT", copyBtn, "RIGHT", 8, 0)
    clearBtn:SetScript("OnClick", function()
        RD.ClearDebugLog()
        print(RD.PFX .. "Debug log cleared.")
    end)

    local debugToggle = MakeBtn("Debug OFF", 90)
    debugToggle:SetPoint("BOTTOMRIGHT", -16, 14)
    f.debugToggle = debugToggle

    local function RefreshToggleLabel()
        local on = RD.DebugIsEnabled()
        debugToggle.label:SetText(on and "Debug ON" or "Debug OFF")
    end

    debugToggle:SetScript("OnClick", function()
        RD.SetDebugEnabled(not RD.DebugIsEnabled())
        RefreshToggleLabel()
        print(RD.PFX .. "Debug mode: " .. (RD.DebugIsEnabled() and "|cff44ff44ON|r" or "|cffff4444OFF|r"))
    end)
    f.RefreshToggle = RefreshToggleLabel

    function f:RefreshLog()
        local text = RD.GetDebugLogText()
        if text == "" then
            text = "(empty — enable Debug and wait for chat, or run self-test)"
        end
        logEdit:SetText(text)
        if f.SyncLogSize then f.SyncLogSize() end
        C_Timer.After(0, function()
            local viewH = logScroll:GetHeight() or 1
            local childH = logChild:GetHeight() or 1
            local maxScroll = math.max(childH - viewH, 0)
            logScroll:SetVerticalScroll(maxScroll)
            if logScroll.UpdateThumb then logScroll:UpdateThumb() end
        end)
    end

    function f:RefreshChecklist()
        for _, child in ipairs({ checkChild:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local run = RD.GetDebugRunForDisplay()
        if run then
            f.subtitle:SetText(string.format("%s · %s",
                run.mode == "selftest" and "Self-test" or "Live",
                run.startedStr or ""))
        else
            f.subtitle:SetText("No run yet")
        end

        local y = 4
        local steps = OrderedSteps(run)
        if #steps == 0 then
            local empty = checkChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            empty:SetPoint("TOPLEFT", 4, -y)
            empty:SetWidth(210)
            empty:SetJustifyH("LEFT")
            empty:SetText("Run self-test or enable Debug and use chat / /rd check.")
            y = y + 40
        else
            for _, s in ipairs(steps) do
                local row = CreateFrame("Frame", nil, checkChild)
                row:SetSize(210, 28)
                row:SetPoint("TOPLEFT", 0, -y)

                local mark = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                mark:SetPoint("LEFT", 2, 0)
                if s.ok == true then
                    mark:SetText("|cff30cc50OK|r")
                elseif s.ok == false then
                    mark:SetText("|cffff4444FAIL|r")
                else
                    mark:SetText("|cff888888—|r")
                end

                local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                label:SetPoint("LEFT", 36, 6)
                label:SetPoint("RIGHT", -4, 6)
                label:SetJustifyH("LEFT")
                label:SetText(s.label or s.key)

                if s.detail then
                    local det = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                    det:SetPoint("LEFT", 36, -8)
                    det:SetPoint("RIGHT", -4, -8)
                    det:SetJustifyH("LEFT")
                    det:SetText(s.detail)
                end

                y = y + 30
            end
        end
        checkChild:SetHeight(math.max(y + 8, 1))
        if checkScroll.UpdateThumb then checkScroll:UpdateThumb() end
    end

    function f:RefreshAll()
        RefreshToggleLabel()
        self:RefreshChecklist()
        self:RefreshLog()
    end

    f:SetScript("OnShow", function(self) self:RefreshAll() end)

    debugFrame = f
    return f
end

function RD.ToggleDebugWindow(forceShow)
    local f = EnsureDebugFrame()
    if forceShow then
        f:Show()
        f:Raise()
        f:RefreshAll()
        return
    end
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        f:Raise()
        f:RefreshAll()
    end
end

function RD.InitDebug()
    -- Frame is created on first open (lazy).
    if RD.db and RD.db.debugEnabled then
        RD.debugEnabled = true
    end
end