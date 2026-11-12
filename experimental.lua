--!native
--!optimize 2
-- Experimental v4.0.0 -- Apex native interface.
-- Blox League / Turbo Soccer.
-- The model and hook layer remain the v0.2.1 core. This build adds a fully
-- native interface, saved appearance, playstyle engines, telemetry and safety
-- controls. No external UI library is used.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G

if type(env.ExperimentalBotUnload) == "function" then pcall(env.ExperimentalBotUnload) end

local VERSION = "4.0.0"
local BUILD = "APEX"
local SCRIPT_URL = "https://raw.githubusercontent.com/filbygblh/Scruipt/refs/heads/main/experimental.lua"
local MODEL_URL = "https://raw.githubusercontent.com/filbygblh/Scruipt/main/model.b64"
local FOLDER = "Vunilow/Experimental"
local CONFIG_DIR = FOLDER .. "/configs"
local AUTOSAVE_PATH = FOLDER .. "/settings.json"
local MAX_LOG = 80
local MAX_HISTORY = 8

local alive, enabled, ready = false, false, false
alive = true
local connections = {}
local message = "Booting Apex..."
local typing = false
local reset
local startedAt = os.clock()
local bot = {}
local ui = {}
local logEntries = {}
local capturing
local gui
local notify = function() end
local refreshConfigs = function() end
local syncUiFromSettings = function() end
local applyTheme = function() end
local setPage = function() end
local commandPalette = function() end
local closePalette = function() end
local setMenu = function() end
local refreshActivity = function() end
local refreshHistory = function() end
local refreshModes = function() end

local DEFAULTS = {
    autoEnable = false,
    pauseOnType = true,
    pauseOnMenu = false,
    notifications = true,
    logEvents = true,
    animations = true,
    autoStopMinutes = 0,
    fpsGuard = false,
    fpsFloor = 25,
    botMode = "Balanced",
    modeStrength = 60,
    decisionInterval = 8,
    theme = "Midnight",
    accent = "Violet",
    menuScale = 1,
    opacity = 100,
    bindToggle = "F1",
    bindPanic = "F2",
    bindMenu = "Insert",
}

local settings = {}
for key, value in pairs(DEFAULTS) do
    settings[key] = value
end

local THEMES = {
    Midnight = {
        bg = Color3.fromRGB(10, 12, 18),
        panel = Color3.fromRGB(15, 18, 27),
        card = Color3.fromRGB(21, 25, 37),
        card2 = Color3.fromRGB(30, 35, 51),
        stroke = Color3.fromRGB(55, 52, 82),
        text = Color3.fromRGB(242, 240, 255),
        muted = Color3.fromRGB(144, 148, 172),
        success = Color3.fromRGB(74, 222, 128),
        warn = Color3.fromRGB(251, 191, 36),
        danger = Color3.fromRGB(244, 94, 120),
        info = Color3.fromRGB(96, 165, 250),
    },
    Carbon = {
        bg = Color3.fromRGB(8, 8, 10),
        panel = Color3.fromRGB(14, 14, 17),
        card = Color3.fromRGB(22, 22, 26),
        card2 = Color3.fromRGB(33, 33, 39),
        stroke = Color3.fromRGB(60, 60, 70),
        text = Color3.fromRGB(245, 245, 247),
        muted = Color3.fromRGB(150, 150, 160),
        success = Color3.fromRGB(74, 222, 128),
        warn = Color3.fromRGB(250, 204, 21),
        danger = Color3.fromRGB(248, 113, 113),
        info = Color3.fromRGB(148, 163, 184),
    },
    Amethyst = {
        bg = Color3.fromRGB(16, 11, 24),
        panel = Color3.fromRGB(23, 16, 35),
        card = Color3.fromRGB(32, 22, 48),
        card2 = Color3.fromRGB(44, 30, 64),
        stroke = Color3.fromRGB(82, 60, 112),
        text = Color3.fromRGB(244, 238, 255),
        muted = Color3.fromRGB(165, 150, 190),
        success = Color3.fromRGB(134, 239, 172),
        warn = Color3.fromRGB(253, 186, 116),
        danger = Color3.fromRGB(251, 113, 133),
        info = Color3.fromRGB(192, 132, 252),
    },
    Ocean = {
        bg = Color3.fromRGB(7, 14, 22),
        panel = Color3.fromRGB(11, 23, 34),
        card = Color3.fromRGB(16, 34, 49),
        card2 = Color3.fromRGB(24, 48, 67),
        stroke = Color3.fromRGB(42, 80, 105),
        text = Color3.fromRGB(235, 247, 255),
        muted = Color3.fromRGB(137, 167, 185),
        success = Color3.fromRGB(45, 212, 191),
        warn = Color3.fromRGB(250, 204, 21),
        danger = Color3.fromRGB(251, 113, 133),
        info = Color3.fromRGB(56, 189, 248),
    },
    Ember = {
        bg = Color3.fromRGB(19, 12, 10),
        panel = Color3.fromRGB(30, 18, 14),
        card = Color3.fromRGB(42, 25, 19),
        card2 = Color3.fromRGB(56, 34, 25),
        stroke = Color3.fromRGB(95, 58, 40),
        text = Color3.fromRGB(255, 241, 232),
        muted = Color3.fromRGB(187, 153, 137),
        success = Color3.fromRGB(163, 230, 53),
        warn = Color3.fromRGB(251, 146, 60),
        danger = Color3.fromRGB(239, 68, 68),
        info = Color3.fromRGB(251, 191, 36),
    },
    Frost = {
        bg = Color3.fromRGB(235, 238, 245),
        panel = Color3.fromRGB(246, 248, 252),
        card = Color3.fromRGB(255, 255, 255),
        card2 = Color3.fromRGB(232, 236, 245),
        stroke = Color3.fromRGB(190, 198, 215),
        text = Color3.fromRGB(24, 28, 40),
        muted = Color3.fromRGB(100, 108, 126),
        success = Color3.fromRGB(22, 163, 74),
        warn = Color3.fromRGB(202, 138, 4),
        danger = Color3.fromRGB(220, 38, 38),
        info = Color3.fromRGB(37, 99, 235),
    },
}

local ACCENTS = {
    Violet = { color = Color3.fromRGB(139, 92, 246), dim = Color3.fromRGB(74, 50, 130), soft = Color3.fromRGB(45, 34, 75) },
    Cyan = { color = Color3.fromRGB(34, 211, 238), dim = Color3.fromRGB(20, 105, 120), soft = Color3.fromRGB(20, 55, 65) },
    Lime = { color = Color3.fromRGB(163, 230, 53), dim = Color3.fromRGB(80, 115, 28), soft = Color3.fromRGB(45, 60, 24) },
    Rose = { color = Color3.fromRGB(244, 114, 182), dim = Color3.fromRGB(125, 55, 92), soft = Color3.fromRGB(65, 35, 50) },
    Amber = { color = Color3.fromRGB(251, 191, 36), dim = Color3.fromRGB(125, 95, 18), soft = Color3.fromRGB(60, 48, 20) },
    Blue = { color = Color3.fromRGB(96, 165, 250), dim = Color3.fromRGB(47, 82, 125), soft = Color3.fromRGB(30, 45, 70) },
}

local function currentTheme()
    local base = THEMES[settings.theme] or THEMES.Midnight
    local accent = ACCENTS[settings.accent] or ACCENTS.Violet
    local result = {}
    for key, value in pairs(base) do
        result[key] = value
    end
    result.accent = accent.color
    result.accentDim = accent.dim
    result.accentSoft = accent.soft
    return result
end

local MODE_ORDER = { "Balanced", "Striker", "Guardian", "Aerial", "Turbo" }
local MODE_DEFS = {
    Balanced = {
        tagline = "Clean model output",
        summary = "No bias. The network's highest-confidence legal action is used exactly as trained.",
        points = { "Reference behavior", "Best all-round consistency", "Recommended starting point" },
    },
    Striker = {
        tagline = "Pressure and finish",
        summary = "Favors forward throttle, boost and aerial commits to keep play in the opponent half.",
        points = { "Rewards boost and forward drive", "Penalizes braking", "More aggressive challenges" },
    },
    Guardian = {
        tagline = "Hold the line",
        summary = "Favors braking, reverse recovery and grounded clears when the ball is threatening.",
        points = { "Rewards brake and reverse", "Cuts boost spending", "Stays planted for saves" },
    },
    Aerial = {
        tagline = "Air superiority",
        summary = "Prefers jump, flip and pitch/roll actions to contest high balls and reset possession.",
        points = { "Rewards jump and flip actions", "Favors aerial pitch and roll", "Stronger boost follow-up" },
    },
    Turbo = {
        tagline = "Maximum tempo",
        summary = "Leans hard into boost and forward throttle for fast rotations and immediate pressure.",
        points = { "Heaviest boost preference", "Fast forward commits", "Weakest brake preference" },
    },
}

bot.bias = function(action, flags)
    local mode = settings.botMode
    if mode == "Balanced" then
        return 0
    end
    local strength = (tonumber(settings.modeStrength) or 60) / 100 * 1.6
    if strength <= 0 then
        return 0
    end
    local score = 0
    local forward, steer, pitch, yaw, roll, jump, boost, brake = action[1], action[2], action[3], action[4], action[5], action[6], action[7], action[8]
    if mode == "Striker" then
        if forward == 1 then score += 0.9 end
        if boost == 1 then score += 1.1 end
        if brake == 1 then score -= 0.9 end
        if steer == 0 then score += 0.2 end
        if jump == 1 then score += 0.25 end
    elseif mode == "Guardian" then
        if forward == -1 then score += 0.8 end
        if brake == 1 then score += 0.7 end
        if boost == 1 then score -= 0.8 end
        if steer == 0 then score += 0.25 end
        if jump == 1 and flags and flags.ground then score -= 0.2 end
    elseif mode == "Aerial" then
        if jump == 1 then score += 1.1 end
        if pitch ~= 0 or roll ~= 0 then score += 0.45 end
        if boost == 1 then score += 0.25 end
    elseif mode == "Turbo" then
        if boost == 1 then score += 1.3 end
        if forward == 1 then score += 1.0 end
        if brake == 1 then score -= 1.1 end
    end
    return score * strength
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function status(value)
    message = tostring(value)
end

local function detectedGame()
    if game.PlaceId == 101880234193261 then
        return "Turbo Soccer"
    end
    return "Blox League"
end

local function uptime()
    local total = math.floor(os.clock() - startedAt)
    return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

local function hasFileApi()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function ensureFolder(path)
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok, exists = pcall(isfolder, path)
        if not ok or not exists then
            pcall(makefolder, path)
        end
    end
end

local function ensureBase()
    ensureFolder("Vunilow")
    ensureFolder(FOLDER)
end

local function readJson(path)
    if not hasFileApi() then
        return nil
    end
    local okFile, exists = pcall(isfile, path)
    if not okFile or not exists then
        return nil
    end
    local okRead, content = pcall(readfile, path)
    if not okRead or type(content) ~= "string" then
        return nil
    end
    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if okDecode and type(data) == "table" then
        return data
    end
    return nil
end

local function writeJson(path, data)
    if not hasFileApi() then
        return false
    end
    local okEncode, content = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not okEncode then
        return false
    end
    return pcall(writefile, path, content)
end

local function settingsSnapshot()
    local snapshot = {}
    for key, value in pairs(settings) do
        snapshot[key] = value
    end
    return snapshot
end

local function mergeSettings(data)
    if type(data) ~= "table" then
        return
    end
    for key, default in pairs(DEFAULTS) do
        if type(data[key]) == type(default) then
            settings[key] = data[key]
        end
    end
    settings.menuScale = math.clamp(tonumber(settings.menuScale) or 1, 0.8, 1.2)
    settings.opacity = math.clamp(tonumber(settings.opacity) or 100, 60, 100)
    settings.modeStrength = math.clamp(tonumber(settings.modeStrength) or 60, 0, 100)
    settings.decisionInterval = math.clamp(math.floor(tonumber(settings.decisionInterval) or 8), 4, 20)
    settings.fpsFloor = math.clamp(math.floor(tonumber(settings.fpsFloor) or 25), 10, 60)
    settings.autoStopMinutes = math.clamp(math.floor(tonumber(settings.autoStopMinutes) or 0), 0, 240)
    if not THEMES[settings.theme] then settings.theme = "Midnight" end
    if not ACCENTS[settings.accent] then settings.accent = "Violet" end
    if not MODE_DEFS[settings.botMode] then settings.botMode = "Balanced" end
end

local function autosave()
    if not hasFileApi() then
        return
    end
    ensureBase()
    writeJson(AUTOSAVE_PATH, settingsSnapshot())
end

mergeSettings(readJson(AUTOSAVE_PATH))
-- ============================================================ activity / profiles
local function logEvent(kind, text)
    if not settings.logEvents then
        return
    end
    table.insert(logEntries, 1, {
        time = os.date("%H:%M:%S"),
        kind = tostring(kind or "info"),
        text = tostring(text),
    })
    while #logEntries > MAX_LOG do
        table.remove(logEntries)
    end
    if refreshActivity then
        pcall(refreshActivity)
    end
end

local function listConfigs()
    if not hasFileApi() or type(listfiles) ~= "function" then
        return {}
    end
    local ok, files = pcall(listfiles, CONFIG_DIR)
    if not ok or type(files) ~= "table" then
        return {}
    end
    local names = {}
    for _, path in ipairs(files) do
        local base = tostring(path):match("([^/\\]+)$") or tostring(path)
        if base:sub(-5) == ".json" then
            names[#names + 1] = base:sub(1, -6)
        end
    end
    return names
end

local function saveNamed(rawName)
    local name = tostring(rawName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        notify("Enter a profile name first.", "warn")
        return
    end
    if #name > 32 then
        notify("Profile names are limited to 32 characters.", "warn")
        return
    end
    if name:find("[^%w%s_%-]") then
        notify("Use letters, numbers, spaces, _ or - only.", "warn")
        return
    end
    if not hasFileApi() then
        notify("This executor has no file API, so profiles cannot be saved.", "danger")
        return
    end
    ensureBase()
    ensureFolder(CONFIG_DIR)
    if writeJson(CONFIG_DIR .. "/" .. name .. ".json", settingsSnapshot()) then
        autosave()
        refreshConfigs()
        notify("Profile saved: " .. name, "success")
        logEvent("config", "Saved profile '" .. name .. "'")
    else
        notify("Could not write the profile file.", "danger")
    end
end

local function loadNamed(name)
    local data = readJson(CONFIG_DIR .. "/" .. tostring(name) .. ".json")
    if not data then
        notify("Could not read that profile.", "danger")
        return
    end
    mergeSettings(data)
    syncUiFromSettings()
    applyTheme()
    autosave()
    notify("Profile loaded: " .. tostring(name), "success")
    logEvent("config", "Loaded profile '" .. tostring(name) .. "'")
end

local function deleteNamed(name)
    if type(delfile) ~= "function" then
        notify("This executor cannot delete files.", "warn")
        return
    end
    if pcall(delfile, CONFIG_DIR .. "/" .. tostring(name) .. ".json") then
        refreshConfigs()
        notify("Profile deleted: " .. tostring(name), "info")
        logEvent("config", "Deleted profile '" .. tostring(name) .. "'")
    else
        notify("Could not delete that profile.", "danger")
    end
end

local function exportSettings()
    if type(setclipboard) ~= "function" then
        notify("This executor has no clipboard write support.", "warn")
        return
    end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(settingsSnapshot())
    end)
    if not ok or type(encoded) ~= "string" then
        notify("Could not encode the settings.", "danger")
        return
    end
    pcall(setclipboard, encoded)
    notify("Current settings copied as JSON.", "success")
    logEvent("config", "Exported settings to clipboard")
end

local function importSettings()
    if type(getclipboard) ~= "function" then
        notify("This executor has no clipboard read support.", "warn")
        return
    end
    local okText, text = pcall(getclipboard)
    if not okText or type(text) ~= "string" or text == "" then
        notify("The clipboard is empty.", "warn")
        return
    end
    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)
    if not okDecode or type(data) ~= "table" then
        notify("Clipboard does not contain valid settings JSON.", "danger")
        return
    end
    mergeSettings(data)
    syncUiFromSettings()
    applyTheme()
    autosave()
    notify("Settings imported from clipboard.", "success")
    logEvent("config", "Imported settings from clipboard")
end

local function resetSettings()
    for key, value in pairs(DEFAULTS) do
        settings[key] = value
    end
    syncUiFromSettings()
    applyTheme()
    autosave()
    notify("All settings restored to defaults.", "info")
    logEvent("config", "Restored default settings")
end

-- ============================================================ actions
local function setEnabled(value, silent)
    value = value and true or false
    local changed = value ~= enabled
    enabled = value
    if reset then
        reset()
        status(value and (ready and "ON - Waiting for live match" or "ON - Loading model") or "OFF - Ready")
    end
    if ui.dashboardSet then
        ui.dashboardSet(value)
    end
    if changed and not silent then
        notify(value and "Auto-play enabled." or "Auto-play disabled.", value and "success" or "info")
        logEvent("bot", value and "Auto-play enabled" or "Auto-play disabled")
    end
end

local function reloadScript()
    logEvent("system", "Reload requested")
    if type(env.ExperimentalBotUnload) == "function" then
        pcall(env.ExperimentalBotUnload)
    end
    task.defer(function()
        local ok, err = pcall(function()
            local chunk = loadstring(game:HttpGet(SCRIPT_URL))
            assert(type(chunk) == "function", "download failed")
            chunk()
        end)
        if not ok then
            warn("[Experimental] Reload failed: " .. tostring(err))
        end
    end)
end

local function unloadScript()
    logEvent("system", "Unload requested")
    if type(env.ExperimentalBotUnload) == "function" then
        env.ExperimentalBotUnload()
    end
end

local function copyDiagnostics()
    if not bot.diagnostics then
        notify("Diagnostics are not ready yet.", "warn")
        return
    end
    local text = bot.diagnostics()
    if type(setclipboard) == "function" then
        pcall(setclipboard, text)
        notify("Diagnostics copied to the clipboard.", "success")
        logEvent("system", "Copied diagnostics")
    else
        warn(text)
        notify("Clipboard unavailable; diagnostics printed to the console.", "warn")
    end
end

local function copyLogs()
    if #logEntries == 0 then
        notify("There is no activity to copy.", "warn")
        return
    end
    if type(setclipboard) ~= "function" then
        notify("This executor has no clipboard write support.", "warn")
        return
    end
    local lines = {}
    for index = #logEntries, 1, -1 do
        local entry = logEntries[index]
        lines[#lines + 1] = entry.time .. "  [" .. entry.kind .. "]  " .. entry.text
    end
    pcall(setclipboard, table.concat(lines, "\n"))
    notify("Activity log copied.", "success")
end

local function copyLoadstring()
    if type(setclipboard) ~= "function" then
        notify("This executor has no clipboard write support.", "warn")
        return
    end
    pcall(setclipboard, 'loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
    notify("Loadstring copied to the clipboard.", "success")
end

-- ============================================================ keybinds
local BIND_LABELS = {
    bindToggle = "bot toggle",
    bindPanic = "panic disable",
    bindMenu = "menu",
}

local function keyName(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return nil
    end
    local name = tostring(input.KeyCode)
    return name:match("KeyCode%.(.+)$") or name
end

beginCapture = function(kind, button)
    if capturing and capturing.button then
        capturing.button.Text = tostring(settings[capturing.kind] or "?")
        capturing.button.TextColor3 = currentTheme().text
    end
    capturing = { kind = kind, button = button }
    button.Text = "Press a key..."
    button.TextColor3 = currentTheme().accent
end

cancelCapture = function()
    if capturing then
        capturing.button.Text = tostring(settings[capturing.kind] or "?")
        capturing.button.TextColor3 = currentTheme().text
        capturing = nil
    end
end

finishCapture = function(key)
    if not capturing then
        return
    end
    local kind = capturing.kind
    local button = capturing.button
    capturing = nil
    button.TextColor3 = currentTheme().text
    if key == "Escape" then
        button.Text = tostring(settings[kind] or "?")
        return
    end
    for _, other in ipairs({ "bindToggle", "bindPanic", "bindMenu" }) do
        if other ~= kind and settings[other] == key then
            button.Text = tostring(settings[kind] or "?")
            notify("That key is already bound to " .. tostring(BIND_LABELS[other] or other) .. ".", "warn")
            return
        end
    end
    settings[kind] = key
    if ui.setters and ui.setters[kind] then
        pcall(ui.setters[kind], key)
    end
    autosave()
    if ui.refreshHints then
        pcall(ui.refreshHints)
    end
    notify("Bound " .. tostring(BIND_LABELS[kind] or kind) .. " to " .. key .. ".", "success")
    logEvent("keybind", tostring(BIND_LABELS[kind] or kind) .. " -> " .. key)
end

local function setSetting(key, value)
    settings[key] = value
    if ui.setters and ui.setters[key] then
        pcall(ui.setters[key], value)
    end
    autosave()
end
-- ============================================================ Apex shell
local function buildMenu()
local MENU_W, MENU_H = 960, 620
local HEADER_H = 86
local SIDEBAR_W = 210
local FOOTER_H = 38
local CONTENT_W = MENU_W - SIDEBAR_W
local SCROLL_W = 710
local CARD_W = 690
local CARD_INNER = 654

local theme = currentTheme()
local targets = {}
ui.setters = {}
ui.segments = {}
local function themed(object, property, role)
    object[property] = theme[role]
    table.insert(targets, { object = object, property = property, role = role })
    return object
end

local function new(className, props)
    local object = Instance.new(className)
    if props then
        for key, value in pairs(props) do
            object[key] = value
        end
    end
    return object
end

local function corner(object, radius)
    local item = new("UICorner", { CornerRadius = UDim.new(0, radius) })
    item.Parent = object
    return item
end

local function stroke(object, role, transparency, thickness)
    local item = new("UIStroke", {
        Color = theme[role or "stroke"],
        Transparency = transparency or 0.35,
        Thickness = thickness or 1,
    })
    item.Parent = object
    table.insert(targets, { object = item, property = "Color", role = role or "stroke" })
    return item
end

local function append(parent, child)
    child.LayoutOrder = #parent:GetChildren() + 1
    child.Parent = parent
    return child
end

local function label(parent, text, x, y, width, height, size, role, bold, wrap)
    local item = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        Text = text,
        TextSize = size,
        TextColor3 = theme[role or "text"],
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = wrap or false,
    })
    if parent then
        item.Parent = parent
    end
    table.insert(targets, { object = item, property = "TextColor3", role = role or "text" })
    return item
end

local function lerpColor(from, to, alpha)
    return Color3.new(
        from.R + (to.R - from.R) * alpha,
        from.G + (to.G - from.G) * alpha,
        from.B + (to.B - from.B) * alpha
    )
end

local function tween(object, info, props)
    if not settings.animations then
        for key, value in pairs(props) do
            object[key] = value
        end
        return
    end
    TweenService:Create(object, info, props):Play()
end

local function hover(buttonObject, baseRole)
    buttonObject.MouseEnter:Connect(function()
        tween(buttonObject, TweenInfo.new(0.14), {
            BackgroundColor3 = lerpColor(theme[baseRole or "card2"], Color3.fromRGB(255, 255, 255), 0.1),
            BackgroundTransparency = baseRole == "ghost" and 0.55 or buttonObject.BackgroundTransparency,
        })
    end)
    buttonObject.MouseLeave:Connect(function()
        tween(buttonObject, TweenInfo.new(0.16), {
            BackgroundColor3 = theme[baseRole or "card2"],
            BackgroundTransparency = baseRole == "ghost" and 1 or buttonObject.BackgroundTransparency,
        })
    end)
end

local function button(parent, text, x, y, width, height, role, onClick)
    local bgRole = role or "card2"
    local item = new("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme[bgRole] or theme.card2,
        BackgroundTransparency = bgRole == "ghost" and 1 or 0,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        TextColor3 = theme.text,
    })
    item.Parent = parent
    corner(item, 8)
    table.insert(targets, { object = item, property = "BackgroundColor3", role = bgRole })
    local caption = label(item, text, 0, 0, width, height, 9, (bgRole == "accent" or bgRole == "danger") and "text" or "text", true, false)
    caption.TextXAlignment = Enum.TextXAlignment.Center
    caption.TextYAlignment = Enum.TextYAlignment.Center
    caption.Size = UDim2.fromScale(1, 1)
    if bgRole == "accent" or bgRole == "danger" then
        caption.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    hover(item, bgRole)
    item.Activated:Connect(function()
        if onClick then
            onClick()
        end
    end)
    return item
end

local function chip(parent, text, x, y, width, role)
    local item = new("TextLabel", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, 20),
        BackgroundColor3 = theme[role or "accentSoft"],
        BackgroundTransparency = 0.15,
        Text = text,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        TextColor3 = role == "accent" and Color3.fromRGB(255, 255, 255) or theme.text,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    item.Parent = parent
    corner(item, 6)
    table.insert(targets, { object = item, property = "BackgroundColor3", role = role or "accentSoft" })
    return item
end

-- ============================================================ window
gui = new("ScreenGui", {
    Name = "ExperimentalApex",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 90,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Enabled = true,
})
gui.Parent = LP:WaitForChild("PlayerGui")

local toastGui = new("ScreenGui", {
    Name = "ExperimentalToasts",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 95,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
toastGui.Parent = LP:WaitForChild("PlayerGui")
gui.Destroying:Connect(function()
    if toastGui then toastGui:Destroy() end
end)

local menu = new("Frame", {
    Name = "ApexWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(MENU_W, MENU_H),
    BackgroundColor3 = theme.bg,
    BorderSizePixel = 0,
    ClipsDescendants = false,
})
menu.Parent = gui
corner(menu, 18)
stroke(menu, "stroke", 0.2, 1)
ui.menu = menu

local shadow = new("Frame", {
    Position = UDim2.fromOffset(-10, -10),
    Size = UDim2.new(1, 20, 1, 20),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ZIndex = 0,
})
shadow.Parent = menu
corner(shadow, 24)

ui.menuScale = new("UIScale", { Scale = settings.menuScale })
ui.menuScale.Parent = menu

local accentLine = new("Frame", {
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.fromOffset(MENU_W - 36, 3),
    BackgroundColor3 = theme.accent,
    BorderSizePixel = 0,
    ZIndex = 2,
})
accentLine.Parent = menu
corner(accentLine, 2)
table.insert(targets, { object = accentLine, property = "BackgroundColor3", role = "accent" })

local header = new("Frame", {
    Size = UDim2.fromOffset(MENU_W, HEADER_H),
    BackgroundTransparency = 1,
    Active = true,
})
header.Parent = menu

label(header, "EXPERIMENTAL", 24, 18, 340, 26, 21, "text", true, false)
label(header, "APEX INTERFACE  //  v" .. VERSION, 24, 48, 360, 14, 9, "muted", true, false)
chip(header, "APEX", 24, 64, 44, "accent")
label(header, "High-performance native control surface", 76, 65, 330, 14, 9, "muted", false, false)

local searchButton = new("TextButton", {
    Position = UDim2.fromOffset(MENU_W - 386, 25),
    Size = UDim2.fromOffset(244, 34),
    BackgroundColor3 = theme.card,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
})
searchButton.Parent = header
corner(searchButton, 9)
stroke(searchButton, "stroke", 0.45, 1)
table.insert(targets, { object = searchButton, property = "BackgroundColor3", role = "card" })
label(searchButton, "Search pages and actions...", 12, 10, 170, 14, 9, "muted", false, false)
local searchChip = chip(searchButton, "CTRL K", 186, 7, 48, "card2")
searchChip.TextColor3 = theme.muted
hover(searchButton, "card")
searchButton.Activated:Connect(function()
    commandPalette()
end)

local centerButton = new("TextButton", {
    Position = UDim2.fromOffset(MENU_W - 102, 25),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = theme.card,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
})
centerButton.Parent = header
corner(centerButton, 9)
table.insert(targets, { object = centerButton, property = "BackgroundColor3", role = "card" })
local centerGlyph = label(centerButton, "+", 0, 0, 34, 34, 16, "muted", true, false)
centerGlyph.TextXAlignment = Enum.TextXAlignment.Center
centerGlyph.TextYAlignment = Enum.TextYAlignment.Center
centerGlyph.Size = UDim2.fromScale(1, 1)
hover(centerButton, "card")
centerButton.Activated:Connect(function()
    menu.Position = UDim2.fromScale(0.5, 0.5)
end)

local closeButton = new("TextButton", {
    Position = UDim2.fromOffset(MENU_W - 60, 25),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = theme.card,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
})
closeButton.Parent = header
corner(closeButton, 9)
table.insert(targets, { object = closeButton, property = "BackgroundColor3", role = "card" })
local closeGlyph = label(closeButton, "X", 0, 0, 34, 34, 12, "muted", true, false)
closeGlyph.TextXAlignment = Enum.TextXAlignment.Center
closeGlyph.TextYAlignment = Enum.TextYAlignment.Center
closeGlyph.Size = UDim2.fromScale(1, 1)
hover(closeButton, "card")
closeButton.Activated:Connect(function()
    setMenu(false)
end)

local headerLine = new("Frame", {
    Position = UDim2.fromOffset(0, HEADER_H - 1),
    Size = UDim2.fromOffset(MENU_W, 1),
    BackgroundColor3 = theme.card2,
    BorderSizePixel = 0,
})
headerLine.Parent = menu
table.insert(targets, { object = headerLine, property = "BackgroundColor3", role = "card2" })

-- ============================================================ navigation
local sidebar = new("Frame", {
    Position = UDim2.fromOffset(0, HEADER_H),
    Size = UDim2.fromOffset(SIDEBAR_W, MENU_H - HEADER_H - FOOTER_H),
    BackgroundColor3 = theme.panel,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
})
sidebar.Parent = menu
corner(sidebar, 14)
table.insert(targets, { object = sidebar, property = "BackgroundColor3", role = "panel" })
ui.sidebar = sidebar

local content = new("Frame", {
    Position = UDim2.fromOffset(SIDEBAR_W, HEADER_H),
    Size = UDim2.fromOffset(CONTENT_W, MENU_H - HEADER_H - FOOTER_H),
    BackgroundTransparency = 1,
})
content.Parent = menu

ui.pageTitle = label(content, "Dashboard", 24, 14, 520, 26, 20, "text", true, false)
ui.pageSubtitle = label(content, "", 24, 42, 540, 16, 10, "muted", false, true)
ui.pageMeta = chip(content, "NATIVE", CONTENT_W - 96, 18, 70, "accentSoft")
ui.pageMeta.TextColor3 = theme.muted

local scroll = new("ScrollingFrame", {
    Position = UDim2.fromOffset(22, 68),
    Size = UDim2.fromOffset(SCROLL_W, 396),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.accentDim,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
})
scroll.Parent = content
ui.scroll = scroll
local scrollLayout = new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder })
scrollLayout.Parent = scroll

local pages = {}
local navButtons = {}
local activePage = 1
local navY = 14
local lastGroup = nil

local function setNavState(index)
    for i, item in ipairs(navButtons) do
        local on = i == index
        item.button.BackgroundTransparency = on and 0.82 or 1
        item.bar.Visible = on
        item.label.TextColor3 = on and theme.text or theme.muted
        item.indexLabel.TextColor3 = on and theme.accent or theme.muted
    end
end

setPage = function(index)
    activePage = index
    for i, item in ipairs(pages) do
        local on = i == index
        item.page.Visible = on
        if on then
            item.page.Parent = scroll
            item.page.LayoutOrder = 1
            ui.pageTitle.Text = item.title
            ui.pageSubtitle.Text = item.subtitle
            ui.pageMeta.Text = item.meta or "NATIVE"
        else
            item.page.Parent = nil
        end
    end
    setNavState(index)
    scroll.CanvasPosition = Vector2.new(0, 0)
end
ui.setPage = setPage

local function addPage(id, navLabel, title, subtitle, group, meta)
    if group and group ~= lastGroup then
        lastGroup = group
        local groupLabel = label(sidebar, string.upper(group), 18, navY, 170, 12, 8, "muted", true, false)
        groupLabel.TextTransparency = 0.15
        navY += 20
    end
    local page = new("Frame", {
        Name = id,
        Size = UDim2.fromOffset(SCROLL_W, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    })
    local layout = new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
    layout.Parent = page

    local navButton = new("TextButton", {
        Position = UDim2.fromOffset(14, navY),
        Size = UDim2.fromOffset(182, 36),
        BackgroundColor3 = theme.accentSoft,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
    })
    navButton.Parent = sidebar
    corner(navButton, 9)
    local bar = new("Frame", {
        Position = UDim2.fromOffset(0, 10),
        Size = UDim2.fromOffset(3, 16),
        BackgroundColor3 = theme.accent,
        BorderSizePixel = 0,
        Visible = false,
    })
    bar.Parent = navButton
    corner(bar, 2)
    local indexLabel = label(navButton, string.format("%02d", #pages + 1), 12, 9, 24, 18, 8, "muted", true, false)
    local navText = label(navButton, navLabel, 36, 9, 132, 18, 10, "muted", true, false)
    local pageIndex = #pages + 1
    navButton.Activated:Connect(function()
        setPage(pageIndex)
    end)
    navY += 42

    local entry = {
        page = page,
        button = navButton,
        bar = bar,
        label = navText,
        indexLabel = indexLabel,
        title = title,
        subtitle = subtitle,
        meta = meta or "NATIVE",
    }
    table.insert(pages, entry)
    table.insert(navButtons, entry)
    ui.pages = pages
    ui.navButtons = navButtons
    return page
end
ui.addPage = addPage

local footer = new("Frame", {
    Position = UDim2.fromOffset(0, MENU_H - FOOTER_H),
    Size = UDim2.fromOffset(MENU_W, FOOTER_H),
    BackgroundColor3 = theme.panel,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
})
footer.Parent = menu
corner(footer, 12)
table.insert(targets, { object = footer, property = "BackgroundColor3", role = "panel" })
local footerLine = new("Frame", { Size = UDim2.fromOffset(MENU_W, 1), BackgroundColor3 = theme.card2, BorderSizePixel = 0 })
footerLine.Parent = footer
table.insert(targets, { object = footerLine, property = "BackgroundColor3", role = "card2" })

local footerStatus = label(footer, message, 20, 10, 530, 16, 9, "muted", false, false)
local footerHint = label(footer, "", MENU_W - 430, 10, 410, 16, 9, "muted", false, false)
footerHint.TextXAlignment = Enum.TextXAlignment.Right
ui.footerStatus = footerStatus
ui.footerHint = footerHint
ui.refreshHints = function()
    footerHint.Text = tostring(settings.bindMenu) .. " menu  |  Ctrl K search  |  " .. tostring(settings.bindToggle) .. " toggle"
end
ui.refreshHints()

-- ============================================================ drag
local drag
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = {
            input = input,
            start = input.Position,
            position = menu.AbsolutePosition,
            touch = input.UserInputType == Enum.UserInputType.Touch,
        }
    end
end)
connect(UIS.InputChanged, function(input)
    if not drag then return end
    local moving = (drag.touch and input == drag.input)
        or (not drag.touch and input.UserInputType == Enum.UserInputType.MouseMovement)
    if not moving then return end
    local delta = input.Position - drag.start
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local size = menu.AbsoluteSize
    local x = math.clamp(drag.position.X + delta.X, 0, math.max(0, viewport.X - size.X))
    local y = math.clamp(drag.position.Y + delta.Y, 0, math.max(0, viewport.Y - size.Y))
    menu.Position = UDim2.fromOffset(x + size.X * 0.5, y + size.Y * 0.5)
end)
connect(UIS.InputEnded, function(input)
    if drag and (input == drag.input or (not drag.touch and input.UserInputType == Enum.UserInputType.MouseButton1)) then
        drag = nil
    end
end)

-- ============================================================ toasts
local toastStack = new("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -20, 0, 20),
    Size = UDim2.fromOffset(310, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
})
toastStack.Parent = toastGui
local toastLayout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
toastLayout.Parent = toastStack

notify = function(text, kind, title)
    if not settings.notifications then
        return
    end
    local kind = kind or "info"
    local toastTitle = title or "APEX"
    local color = theme[kind] or theme.accent
    local toast = new("Frame", {
        Size = UDim2.fromOffset(300, 62),
        BackgroundColor3 = theme.card,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
    })
    toast.Parent = toastStack
    corner(toast, 10)
    stroke(toast, "stroke", 0.35, 1)
    local bar = new("Frame", {
        Position = UDim2.fromOffset(0, 10),
        Size = UDim2.fromOffset(3, 42),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    bar.Parent = toast
    corner(bar, 2)
    label(toast, string.upper(toastTitle), 14, 9, 230, 14, 8, "muted", true, false)
    label(toast, tostring(text), 14, 26, 270, 28, 10, "text", false, true)
    local toastCount = #toastStack:GetChildren() - 1
    if toastCount > 3 then
        for _, child in ipairs(toastStack:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
                break
            end
        end
    end
    task.delay(4, function()
        if toast.Parent then
            toast:Destroy()
        end
    end)
end

-- ============================================================ command palette
local palette = new("Frame", {
    Size = UDim2.fromOffset(MENU_W, MENU_H),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 50,
})
palette.Parent = menu
ui.palette = palette
local dim = new("TextButton", {
    Size = UDim2.fromOffset(MENU_W, MENU_H),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.42,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 50,
})
dim.Parent = palette
dim.Activated:Connect(function()
    closePalette()
end)

local palettePanel = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(620, 424),
    BackgroundColor3 = theme.card,
    BorderSizePixel = 0,
    ZIndex = 51,
})
palettePanel.Parent = palette
corner(palettePanel, 16)
stroke(palettePanel, "stroke", 0.2, 1)
table.insert(targets, { object = palettePanel, property = "BackgroundColor3", role = "card" })

label(palettePanel, "COMMAND PALETTE", 20, 16, 300, 16, 9, "muted", true, false)
label(palettePanel, "ESC to close", 520, 16, 80, 16, 9, "muted", false, false).TextXAlignment = Enum.TextXAlignment.Right

local paletteSearch = new("TextBox", {
    Position = UDim2.fromOffset(20, 40),
    Size = UDim2.fromOffset(580, 38),
    BackgroundColor3 = theme.card2,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Search pages, actions and settings...",
    PlaceholderColor3 = theme.muted,
    TextColor3 = theme.text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 52,
})
paletteSearch.Parent = palettePanel
corner(paletteSearch, 9)
table.insert(targets, { object = paletteSearch, property = "BackgroundColor3", role = "card2" })
table.insert(targets, { object = paletteSearch, property = "TextColor3", role = "text" })
local palettePad = new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
palettePad.Parent = paletteSearch
ui.paletteSearch = paletteSearch

local paletteResults = new("ScrollingFrame", {
    Position = UDim2.fromOffset(20, 92),
    Size = UDim2.fromOffset(580, 292),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = theme.accentDim,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
paletteResults.Parent = palettePanel
local resultsLayout = new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
resultsLayout.Parent = paletteResults
ui.paletteResults = paletteResults

label(palettePanel, "ENTER run  /  ARROWS navigate  /  CTRL K toggle", 20, 396, 580, 14, 8, "muted", false, false)

local commands = {}
ui.commands = commands
local paletteOpen = false
local paletteIndex = 1
local paletteButtons = {}
local paletteMatches = {}
ui.paletteMatches = paletteMatches
ui.paletteOpen = false

local function selectPalette(index)
    if #paletteButtons == 0 then return end
    paletteIndex = math.clamp(index, 1, #paletteButtons)
    ui.paletteIndex = paletteIndex
    for i, item in ipairs(paletteButtons) do
        local on = i == paletteIndex
        item.button.BackgroundColor3 = on and theme.accentSoft or theme.card
        item.button.BackgroundTransparency = on and 0.2 or 1
        item.label.TextColor3 = on and theme.text or theme.muted
    end
end

local function runCommand(command)
    closePalette()
    if command and command.action then
        pcall(command.action)
    end
end

local function refreshPalette(query)
    for _, child in ipairs(paletteResults:GetChildren()) do
        if child:IsA("TextButton") or (child:IsA("TextLabel") and child.Name == "PaletteEmpty") then
            child:Destroy()
        end
    end
    paletteButtons = {}
    ui.paletteButtons = paletteButtons
    local needle = string.lower(tostring(query or ""))
    local matches = {}
    for _, command in ipairs(commands) do
        if needle == "" or string.find(string.lower(command.label), needle, 1, true)
            or string.find(string.lower(command.hint or ""), needle, 1, true) then
            matches[#matches + 1] = command
        end
    end
    paletteMatches = matches
    ui.paletteMatches = paletteMatches
    if #matches == 0 then
        local empty = label(paletteResults, "No matching command.", 12, 12, 540, 20, 10, "muted", false, false)
        empty.Name = "PaletteEmpty"
        return
    end
    for index, command in ipairs(matches) do
        local selectedCommand = command
        local item = new("TextButton", {
            Size = UDim2.fromOffset(560, 42),
            BackgroundColor3 = theme.card,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        })
        item.Parent = paletteResults
        corner(item, 8)
        local name = label(item, command.label, 12, 6, 390, 16, 10, "text", true, false)
        local hint = label(item, command.hint or "", 12, 23, 520, 14, 8, "muted", false, false)
        item.Activated:Connect(function()
            runCommand(selectedCommand)
        end)
        table.insert(paletteButtons, { button = item, label = name, hint = hint })
        if index == 1 then
            item.BackgroundColor3 = theme.accentSoft
            item.BackgroundTransparency = 0.2
        end
    end
    paletteIndex = 1
    ui.paletteIndex = 1
    selectPalette(1)
end

closePalette = function()
    paletteOpen = false
    ui.paletteOpen = false
    palette.Visible = false
    pcall(function()
        paletteSearch:ReleaseFocus()
    end)
end
ui.closePalette = closePalette

commandPalette = function()
    if paletteOpen then
        closePalette()
        return
    end
    setMenu(true)
    paletteOpen = true
    ui.paletteOpen = true
    palette.Visible = true
    paletteSearch.Text = ""
    refreshPalette("")
    task.defer(function()
        pcall(function()
            paletteSearch:CaptureFocus()
        end)
    end)
end
ui.commandPalette = commandPalette
ui.refreshPalette = refreshPalette
ui.selectPalette = selectPalette
ui.runPaletteSelection = function()
    local item = paletteButtons[paletteIndex]
    if item then
        runCommand(paletteMatches[paletteIndex])
    end
end

paletteSearch:GetPropertyChangedSignal("Text"):Connect(function()
    refreshPalette(paletteSearch.Text)
end)

local function addCommand(commandLabel, hint, action)
    table.insert(commands, { label = commandLabel, hint = hint or "", action = action })
end
ui.addCommand = addCommand

-- ============================================================ page controls
local function makeToggle(parent, initial, onChange)
    local value = initial and true or false
    local toggle = new("TextButton", {
        Position = UDim2.new(1, -46, 0, 14),
        Size = UDim2.fromOffset(46, 24),
        BackgroundColor3 = value and theme.accent or theme.card2,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    toggle.Parent = parent
    corner(toggle, 12)
    local knob = new("Frame", {
        Position = UDim2.fromOffset(value and 25 or 3, 3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    knob.Parent = toggle
    corner(knob, 9)
    local function set(nextValue, silent)
        value = nextValue and true or false
        tween(toggle, TweenInfo.new(0.16), { BackgroundColor3 = value and theme.accent or theme.card2 })
        tween(knob, TweenInfo.new(0.16), { Position = UDim2.fromOffset(value and 25 or 3, 3) })
        if not silent and onChange then
            onChange(value)
        end
    end
    toggle.Activated:Connect(function()
        set(not value)
    end)
    return set
end

local function row(cardObject, title, desc, reserve, height)
    local item = new("Frame", {
        Size = UDim2.fromOffset(CARD_INNER, height or 52),
        BackgroundTransparency = 1,
    })
    append(cardObject, item)
    local width = CARD_INNER - (reserve or 160)
    label(item, title, 0, 2, width, 18, 11, "text", true, false)
    if desc and desc ~= "" then
        label(item, desc, 0, 22, width, height and (height - 24) or 26, 9, "muted", false, true)
    end
    return item
end
ui.row = row

local function card(page, title, subtitle)
    local cardObject = new("Frame", {
        Size = UDim2.fromOffset(CARD_W, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.card,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
    })
    corner(cardObject, 14)
    stroke(cardObject, "stroke", 0.55, 1)
    if page then
        append(page, cardObject)
    end
    local pad = new("UIPadding", {
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 18),
    })
    pad.Parent = cardObject
    local layout = new("UIListLayout", { Padding = UDim.new(0, 11), SortOrder = Enum.SortOrder.LayoutOrder })
    layout.Parent = cardObject
    if title then
        append(cardObject, label(nil, string.upper(title), 0, 0, CARD_INNER, 14, 8, "muted", true, false))
    end
    if subtitle then
        local sub = append(cardObject, label(nil, subtitle, 0, 0, CARD_INNER, 28, 9, "muted", false, true))
        sub.TextTransparency = 0.1
    end
    return cardObject
end
ui.card = card

local function toggleRow(cardObject, key, title, desc, onChange)
    local item = row(cardObject, title, desc, 160)
    local set = makeToggle(item, settings[key], function(value)
        setSetting(key, value)
        if onChange then onChange(value) end
    end)
    ui.setters[key] = function(value)
        set(value, true)
    end
    return set
end
ui.toggleRow = toggleRow

local function buttonRow(cardObject, title, desc, buttonText, onClick, role)
    local item = row(cardObject, title, desc, 160)
    return button(item, buttonText, CARD_INNER - 130, 12, 130, 30, role or "accent", onClick)
end
ui.buttonRow = buttonRow

local function keybindRow(cardObject, key, title, desc)
    local item = row(cardObject, title, desc, 160)
    local bindButton = new("TextButton", {
        Position = UDim2.new(1, -130, 0, 12),
        Size = UDim2.fromOffset(130, 30),
        BackgroundColor3 = theme.card2,
        Text = tostring(settings[key] or "?"),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = theme.text,
        AutoButtonColor = false,
    })
    bindButton.Parent = item
    corner(bindButton, 8)
    table.insert(targets, { object = bindButton, property = "BackgroundColor3", role = "card2" })
    bindButton.Activated:Connect(function()
        beginCapture(key, bindButton)
    end)
    ui.setters[key] = function(value)
        bindButton.Text = tostring(value)
    end
    return bindButton
end
ui.keybindRow = keybindRow

local function segmented(cardObject, key, title, desc, options, onChange)
    local item = row(cardObject, title, desc, 280)
    local count = #options
    local total = count * 52 + (count - 1) * 6
    local startX = CARD_INNER - total
    local buttons = {}
    local function mark(value)
        for _, entry in ipairs(buttons) do
            local on = entry.value == value
            entry.button.BackgroundColor3 = on and theme.accent or theme.card2
            entry.label.TextColor3 = on and Color3.fromRGB(255, 255, 255) or theme.muted
        end
    end
    for index, option in ipairs(options) do
        local optionLabel = option.label
        local optionValue = option.value
        local entry = new("TextButton", {
            Position = UDim2.fromOffset(startX + (index - 1) * 58, 12),
            Size = UDim2.fromOffset(52, 28),
            BackgroundColor3 = theme.card2,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        })
        entry.Parent = item
        corner(entry, 7)
        local caption = label(entry, optionLabel, 0, 0, 52, 28, 8, "muted", true, false)
        caption.TextXAlignment = Enum.TextXAlignment.Center
        caption.TextYAlignment = Enum.TextYAlignment.Center
        caption.Size = UDim2.fromScale(1, 1)
        local buttonEntry = { button = entry, label = caption, value = optionValue }
        table.insert(buttons, buttonEntry)
        entry.Activated:Connect(function()
            setSetting(key, optionValue)
            mark(optionValue)
            if onChange then onChange(optionValue) end
        end)
    end
    ui.setters[key] = function(value)
        mark(value)
    end
    mark(settings[key])
    ui.segments[key] = buttons
    return buttons
end
ui.segmented = segmented

local function divider(cardObject)
    local line = new("Frame", {
        Size = UDim2.fromOffset(CARD_INNER, 1),
        BackgroundColor3 = theme.card2,
        BorderSizePixel = 0,
    })
    append(cardObject, line)
    table.insert(targets, { object = line, property = "BackgroundColor3", role = "card2" })
    return line
end
ui.divider = divider

local function spacer(cardObject, height)
    local item = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, height or 4), BackgroundTransparency = 1 })
    append(cardObject, item)
    return item
end
ui.spacer = spacer

-- ============================================================ theme application
applyTheme = function()
    theme = currentTheme()
    for _, target in ipairs(targets) do
        pcall(function()
            target.object[target.property] = theme[target.role]
        end)
    end
    if ui.menu then
        ui.menu.BackgroundColor3 = theme.bg
        ui.menu.BackgroundTransparency = 0.02 + (100 - settings.opacity) / 100 * 0.3
    end
    if ui.sidebar then
        ui.sidebar.BackgroundColor3 = theme.panel
    end
    if ui.scroll then
        ui.scroll.ScrollBarImageColor3 = theme.accentDim
    end
    if ui.paletteResults then
        ui.paletteResults.ScrollBarImageColor3 = theme.accentDim
    end
    if ui.paletteSearch then
        ui.paletteSearch.PlaceholderColor3 = theme.muted
    end
    if ui.menuScale then
        ui.menuScale.Scale = settings.menuScale
    end
    if ui.refreshHints then
        pcall(ui.refreshHints)
    end
    if ui.refreshThemes then pcall(ui.refreshThemes) end
    if refreshConfigs then pcall(refreshConfigs) end
    if refreshActivity then pcall(refreshActivity) end
    if refreshHistory then pcall(refreshHistory) end
    if ui.refreshModes then pcall(ui.refreshModes) end
end

setMenu = function(open)
    gui.Enabled = open and true or false
    if not gui.Enabled then
        cancelCapture()
        closePalette()
    else
        if ui.refreshConfigs then pcall(ui.refreshConfigs) end
    end
end
ui.setMenu = setMenu

ui.closePalette = closePalette
ui.commandPalette = commandPalette
-- ============================================================ dashboard
local dashboard = addPage("dashboard", "Dashboard", "Dashboard", "Live control, session pulse and quick actions.", "Core", "OVERVIEW")
local heroCard = card(dashboard)
local hero = new("Frame", {
    Size = UDim2.fromOffset(CARD_INNER, 136),
    BackgroundColor3 = theme.card2,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
})
append(heroCard, hero)
corner(hero, 12)
stroke(hero, "stroke", 0.5, 1)

local heroBar = new("Frame", {
    Size = UDim2.fromOffset(3, 104),
    Position = UDim2.fromOffset(0, 16),
    BackgroundColor3 = theme.accent,
    BorderSizePixel = 0,
})
heroBar.Parent = hero
corner(heroBar, 2)
table.insert(targets, { object = heroBar, property = "BackgroundColor3", role = "accent" })

local orbGlow = new("Frame", {
    Position = UDim2.fromOffset(15, 15),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = theme.accent,
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
})
orbGlow.Parent = hero
corner(orbGlow, 29)
table.insert(targets, { object = orbGlow, property = "BackgroundColor3", role = "accent" })

local heroOrb = new("Frame", {
    Position = UDim2.fromOffset(20, 20),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = theme.card2,
    BorderSizePixel = 0,
})
heroOrb.Parent = hero
corner(heroOrb, 24)
table.insert(targets, { object = heroOrb, property = "BackgroundColor3", role = "card2" })
local orbCore = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(16, 16),
    BackgroundColor3 = theme.muted,
    BorderSizePixel = 0,
})
orbCore.Parent = heroOrb
corner(orbCore, 8)
table.insert(targets, { object = orbCore, property = "BackgroundColor3", role = "muted" })

if settings.animations then
    TweenService:Create(orbGlow, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(66, 66),
        Position = UDim2.fromOffset(11, 11),
        BackgroundTransparency = 0.9,
    }):Play()
end

ui.heroStatus = label(hero, "STANDBY", 84, 16, 360, 24, 19, "muted", true, false)
ui.heroSub = label(hero, "Policy offline", 84, 44, 360, 16, 9, "muted", false, false)
ui.heroMode = chip(hero, "BALANCED ENGINE", 84, 70, 132, "accentSoft")
ui.heroMode.TextColor3 = theme.text
table.insert(targets, { object = ui.heroMode, property = "TextColor3", role = "text" })

local heroStart = new("TextButton", {
    Position = UDim2.fromOffset(472, 16),
    Size = UDim2.fromOffset(164, 38),
    BackgroundColor3 = theme.accent,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
})
heroStart.Parent = hero
corner(heroStart, 9)
local heroStartLabel = label(heroStart, "START AUTO-PLAY", 0, 0, 164, 38, 9, "text", true, false)
heroStartLabel.TextXAlignment = Enum.TextXAlignment.Center
heroStartLabel.TextYAlignment = Enum.TextYAlignment.Center
heroStartLabel.Size = UDim2.fromScale(1, 1)
heroStartLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
heroStart.Activated:Connect(function()
    setEnabled(not enabled)
end)
ui.heroStart = heroStart
ui.heroStartLabel = heroStartLabel

local panicHero = button(hero, "PANIC STOP", 472, 64, 164, 30, "danger", function()
    setEnabled(false)
end)

ui.dashboardSet = function(value)
    value = value and true or false
    heroStartLabel.Text = value and "STOP AUTO-PLAY" or "START AUTO-PLAY"
    heroStart.BackgroundColor3 = value and theme.danger or theme.accent
    ui.heroStatus.Text = value and "AUTO-PILOT ENGAGED" or "STANDBY"
    ui.heroStatus.TextColor3 = value and theme.success or theme.muted
    heroOrb.BackgroundColor3 = value and theme.success or theme.card2
    orbCore.BackgroundColor3 = value and theme.success or theme.muted
    ui.heroMode.Text = string.upper(settings.botMode) .. " ENGINE"
end

local metricsCard = card(dashboard, "Session metrics", "Live values from the policy loop.")
ui.dashMetrics = {}
local metricRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 86), BackgroundTransparency = 1 })
append(metricsCard, metricRow)

local function metricTile(parent, key, store, title, x, y, width, height)
    local tile = new("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = theme.card2,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
    })
    tile.Parent = parent
    corner(tile, 10)
    stroke(tile, "stroke", 0.6, 1)
    label(tile, title, 12, 9, width - 24, 12, 8, "muted", true, false)
    local value = label(tile, "-", 12, 28, width - 24, 28, 19, "text", true, false)
    store[key] = value
    return value
end

metricTile(metricRow, "decisions", ui.dashMetrics, "DECISIONS", 0, 0, 150, 86)
metricTile(metricRow, "compute", ui.dashMetrics, "COMPUTE", 168, 0, 150, 86)
metricTile(metricRow, "latency", ui.dashMetrics, "LATENCY", 336, 0, 150, 86)
metricTile(metricRow, "uptime", ui.dashMetrics, "UPTIME", 504, 0, 150, 86)

local pulseCard = card(dashboard, "Session pulse", "Compute time across the most recent decisions.")
local function sparkline(parent)
    local frame = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 76), BackgroundTransparency = 1 })
    frame.Parent = parent
    local bars = {}
    for index = 1, 32 do
        local bar = new("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromOffset((index - 1) * 20, 76),
            Size = UDim2.fromOffset(12, 6),
            BackgroundColor3 = theme.accent,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        })
        bar.Parent = frame
        corner(bar, 3)
        bars[index] = bar
    end
    return frame, bars
end
local _, dashBars = sparkline(pulseCard)
ui.dashBars = dashBars

local quickCard = card(dashboard, "Quick actions")
local quickRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 34), BackgroundTransparency = 1 })
append(quickCard, quickRow)
button(quickRow, "Command palette", 0, 0, 150, 34, "card2", commandPalette)
button(quickRow, "Playstyles", 168, 0, 150, 34, "card2", function() setPage(2) end)
button(quickRow, "Profiles", 336, 0, 150, 34, "card2", function() setPage(6) end)
button(quickRow, "Activity", 504, 0, 150, 34, "card2", function() setPage(8) end)

local recentCard = card(dashboard, "Recent activity")
ui.recentList = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
ui.recentList.Parent = recentCard
local recentLayout = new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder })
recentLayout.Parent = ui.recentList

-- ============================================================ playstyle engines
local modesPage = addPage("modes", "Bot Modes", "Playstyle engines", "Bias legal actions without replacing the trained model.", "Core", "ENGINES")
local modeIntro = card(modesPage, "Engine library", "Each engine adds a small preference to the policy's legal actions. The network, observation and safety filters stay identical. Bias strength controls how strongly the engine leans.")
local modeGrid = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 324), BackgroundTransparency = 1 })
append(modeIntro, modeGrid)
ui.modeButtons = {}

local function makeModeButton(id, x, y)
    local def = MODE_DEFS[id]
    local cardButton = new("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(318, 96),
        BackgroundColor3 = theme.card2,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    cardButton.Parent = modeGrid
    corner(cardButton, 10)
    local modeStroke = stroke(cardButton, "stroke", 0.45, 1)
    label(cardButton, id, 14, 9, 280, 18, 12, "text", true, false)
    label(cardButton, def.tagline, 14, 28, 280, 14, 8, "muted", true, false)
    label(cardButton, def.summary, 14, 45, 286, 38, 8, "muted", false, true)
    cardButton.Activated:Connect(function()
        setSetting("botMode", id)
        if ui.refreshModes then ui.refreshModes() end
        notify("Playstyle switched to " .. id .. ".", "success")
        logEvent("mode", "Selected " .. id .. " engine")
    end)
    ui.modeButtons[id] = { button = cardButton, stroke = modeStroke }
end

makeModeButton("Balanced", 0, 0)
makeModeButton("Striker", 336, 0)
makeModeButton("Guardian", 0, 108)
makeModeButton("Aerial", 336, 108)
makeModeButton("Turbo", 0, 216)

local modeSummaryPanel = new("Frame", {
    Position = UDim2.fromOffset(336, 216),
    Size = UDim2.fromOffset(318, 96),
    BackgroundColor3 = theme.card2,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
})
modeSummaryPanel.Parent = modeGrid
corner(modeSummaryPanel, 10)
label(modeSummaryPanel, "ACTIVE ENGINE", 14, 10, 180, 12, 8, "muted", true, false)
ui.modeSummary = label(modeSummaryPanel, "", 14, 26, 286, 58, 9, "text", false, true)

local strengthCard = card(modesPage, "Engine tuning")
segmented(strengthCard, "modeStrength", "Bias strength", "How far the engine is allowed to push the action ranking.", {
    { label = "25%", value = 25 },
    { label = "50%", value = 50 },
    { label = "75%", value = 75 },
    { label = "100%", value = 100 },
})
segmented(strengthCard, "decisionInterval", "Decision rate", "Frames between policy decisions. Lower is faster and heavier.", {
    { label = "Fast", value = 6 },
    { label = "Normal", value = 8 },
    { label = "Relaxed", value = 12 },
}, function()
    logEvent("mode", "Decision interval set to " .. tostring(settings.decisionInterval))
end)

local modeNote = card(modesPage, "What changes?")
append(modeNote, label(nil, "Only the ranking of legal actions changes. The model weights, observation builder, hook signatures and safety gates are untouched. If an engine feels wrong, lower the bias strength instead of switching the model.", 0, 0, CARD_INNER, 52, 9, "muted", false, true))

-- ============================================================ automation
local automationPage = addPage("automation", "Automation", "Automation", "Startup behavior, typing safety and session guards.", "Control", "SAFETY")
local behaviorCard = card(automationPage, "Behavior")
toggleRow(behaviorCard, "autoEnable", "Enable on inject", "Start the policy automatically after this script runs.", function(value)
    logEvent("automation", value and "Auto-start enabled" or "Auto-start disabled")
end)
toggleRow(behaviorCard, "pauseOnType", "Pause while typing", "Release control while the chat or any text box is focused.", function(value)
    logEvent("automation", value and "Typing pause enabled" or "Typing pause disabled")
end)
toggleRow(behaviorCard, "pauseOnMenu", "Pause while menu is open", "Hold the bot whenever this window is visible.", function(value)
    logEvent("automation", value and "Menu pause enabled" or "Menu pause disabled")
end)
toggleRow(behaviorCard, "notifications", "Toast notifications", "Show transient status cards in the top-right corner.")
toggleRow(behaviorCard, "logEvents", "Activity logging", "Record menu actions, mode changes and session events.")

local guardCard = card(automationPage, "Session guards", "Automatic safety rails. Guards only disable the bot; they never retry or change policy actions.")
toggleRow(guardCard, "fpsGuard", "FPS guard", "Disable the bot if the frame rate stays below the floor.", function(value)
    logEvent("safety", value and "FPS guard armed" or "FPS guard disarmed")
end)
segmented(guardCard, "fpsFloor", "FPS floor", "Sustained frame rate below this value trips the guard.", {
    { label = "20", value = 20 },
    { label = "25", value = 25 },
    { label = "30", value = 30 },
    { label = "40", value = 40 },
})
segmented(guardCard, "autoStopMinutes", "Session limit", "Automatically stop after this much continuous runtime.", {
    { label = "Off", value = 0 },
    { label = "15m", value = 15 },
    { label = "30m", value = 30 },
    { label = "1h", value = 60 },
})

local panicCard = card(automationPage, "Emergency control")
buttonRow(panicCard, "Panic disable", "Immediately stop auto-play and release the current action.", "PANIC", function()
    setEnabled(false)
end, "danger")
buttonRow(panicCard, "Reset session stats", "Clear counters and saved run history for this session.", "RESET", function()
    if bot.resetStats then bot.resetStats() end
    refreshHistory()
    notify("Session stats reset.", "info")
end, "card2")

-- ============================================================ keybinds
local keybindPage = addPage("keybinds", "Keybinds", "Keybinds", "Global controls and key capture.", "Control", "INPUT")
local bindCard = card(keybindPage, "Global keys", "These keys work anywhere except while typing in a text field.")
keybindRow(bindCard, "bindMenu", "Toggle menu", "Show or hide the Apex window.")
keybindRow(bindCard, "bindToggle", "Toggle auto-play", "Start or stop the policy.")
keybindRow(bindCard, "bindPanic", "Panic disable", "Stop instantly and release input.")
divider(bindCard)
buttonRow(bindCard, "Restore defaults", "Return all global keys to Insert, F1 and F2.", "RESTORE", function()
    settings.bindMenu = "Insert"
    settings.bindToggle = "F1"
    settings.bindPanic = "F2"
    for _, key in ipairs({ "bindMenu", "bindToggle", "bindPanic" }) do
        if ui.setters[key] then pcall(ui.setters[key], settings[key]) end
    end
    autosave()
    ui.refreshHints()
    notify("Keybinds restored to defaults.", "success")
    logEvent("keybind", "Restored default keybinds")
end, "card2")

local bindInfo = card(keybindPage, "Palette shortcuts")
append(bindInfo, label(nil, "Ctrl+K opens the command palette from anywhere in the menu. Escape closes it. Arrow keys move the selection and Enter runs the highlighted command.", 0, 0, CARD_INNER, 42, 9, "muted", false, true))

-- ============================================================ appearance
local appearancePage = addPage("appearance", "Appearance", "Appearance", "Theme, accent, scale and motion.", "System", "STYLE")
local themeCard = card(appearancePage, "Theme library", "Six complete palettes. Every card and control updates immediately.")
local themeGrid = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 158), BackgroundTransparency = 1 })
append(themeCard, themeGrid)
local THEME_ORDER = { "Midnight", "Carbon", "Amethyst", "Ocean", "Ember", "Frost" }
ui.themeButtons = {}
local function makeThemeButton(name, index)
    local data = THEMES[name]
    local x = ((index - 1) % 3) * 220
    local y = math.floor((index - 1) / 3) * 80
    local themeButton = new("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(210, 68),
        BackgroundColor3 = data.card,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    themeButton.Parent = themeGrid
    corner(themeButton, 9)
    local themeStroke = stroke(themeButton, "stroke", 0.5, 1)
    for swatchIndex, color in ipairs({ data.bg, data.card2, data.text }) do
        local swatch = new("Frame", {
            Position = UDim2.fromOffset(12 + (swatchIndex - 1) * 18, 12),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        })
        swatch.Parent = themeButton
        corner(swatch, 4)
    end
    local nameLabel = label(themeButton, name, 12, 34, 180, 16, 10, "text", true, false)
    nameLabel.TextColor3 = data.text
    local tagLabel = label(themeButton, "PALETTE", 12, 50, 180, 12, 7, "muted", true, false)
    tagLabel.TextColor3 = data.muted
    themeButton.Activated:Connect(function()
        setSetting("theme", name)
        applyTheme()
        notify("Theme changed to " .. name .. ".", "info")
        logEvent("appearance", "Theme -> " .. name)
    end)
    ui.themeButtons[name] = { button = themeButton, stroke = themeStroke, nameLabel = nameLabel, tagLabel = tagLabel }
end
for index, name in ipairs(THEME_ORDER) do
    makeThemeButton(name, index)
end

local accentCard = card(appearancePage, "Accent", "The accent drives active tabs, bars, toggles and highlights.")
local accentRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 36), BackgroundTransparency = 1 })
append(accentCard, accentRow)
local ACCENT_ORDER = { "Violet", "Cyan", "Lime", "Rose", "Amber", "Blue" }
ui.accentButtons = {}
for index, name in ipairs(ACCENT_ORDER) do
    local accentName = name
    local swatchButton = new("TextButton", {
        Position = UDim2.fromOffset((index - 1) * 44, 4),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = ACCENTS[name].color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    swatchButton.Parent = accentRow
    corner(swatchButton, 14)
    local swatchStroke = stroke(swatchButton, "stroke", 0.8, 2)
    swatchButton.Activated:Connect(function()
        setSetting("accent", accentName)
        applyTheme()
        notify("Accent changed to " .. accentName .. ".", "info")
        logEvent("appearance", "Accent -> " .. accentName)
    end)
    ui.accentButtons[accentName] = { button = swatchButton, stroke = swatchStroke }
end

local layoutCard = card(appearancePage, "Layout and motion")
segmented(layoutCard, "menuScale", "Menu scale", "Resize the entire interface.", {
    { label = "80%", value = 0.8 },
    { label = "90%", value = 0.9 },
    { label = "100%", value = 1.0 },
    { label = "110%", value = 1.1 },
    { label = "120%", value = 1.2 },
}, function()
    applyTheme()
end)
segmented(layoutCard, "opacity", "Window opacity", "Make the background more transparent.", {
    { label = "70%", value = 70 },
    { label = "85%", value = 85 },
    { label = "100%", value = 100 },
}, function()
    applyTheme()
end)
toggleRow(layoutCard, "animations", "Animations", "Enable tweened toggles, hover states and the status pulse.")
divider(layoutCard)
buttonRow(layoutCard, "Reset appearance", "Restore Midnight, Violet, 100% scale and animations.", "RESET", function()
    settings.theme = "Midnight"
    settings.accent = "Violet"
    settings.menuScale = 1
    settings.opacity = 100
    settings.animations = true
    syncUiFromSettings()
    applyTheme()
    notify("Appearance restored to defaults.", "success")
    logEvent("appearance", "Reset appearance")
end, "card2")

local function refreshThemes()
    for name, entry in pairs(ui.themeButtons) do
        local on = settings.theme == name
        entry.button.BackgroundTransparency = on and 0 or 0.05
        entry.stroke.Color = on and theme.accent or theme.stroke
        entry.stroke.Thickness = on and 2 or 1
        entry.nameLabel.TextColor3 = THEMES[name].text
        entry.tagLabel.TextColor3 = THEMES[name].muted
    end
    for name, entry in pairs(ui.accentButtons) do
        local on = settings.accent == name
        entry.stroke.Color = on and theme.text or theme.stroke
        entry.stroke.Transparency = on and 0.1 or 0.8
        entry.stroke.Thickness = on and 2 or 1
    end
end
ui.refreshThemes = refreshThemes

local function refreshModes()
    for id, entry in pairs(ui.modeButtons) do
        local on = settings.botMode == id
        entry.button.BackgroundColor3 = on and theme.accentSoft or theme.card2
        entry.button.BackgroundTransparency = on and 0.1 or 0.16
        entry.stroke.Color = on and theme.accent or theme.stroke
        entry.stroke.Thickness = on and 2 or 1
    end
    if ui.modeSummary then
        local def = MODE_DEFS[settings.botMode] or MODE_DEFS.Balanced
        ui.modeSummary.Text = def.summary
    end
    if ui.heroMode then
        ui.heroMode.Text = string.upper(settings.botMode) .. " ENGINE"
    end
end
ui.refreshModes = refreshModes
refreshModes()
refreshThemes()
-- ============================================================ configs
local configsPage = addPage("configs", "Configs", "Configs", "Profiles, transfer and storage.", "System", "STORAGE")
local saveCard = card(configsPage, "Save current settings", "Profiles are JSON files under Vunilow/Experimental/configs.")
local nameRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 44), BackgroundTransparency = 1 })
append(saveCard, nameRow)
ui.nameBox = new("TextBox", {
    Position = UDim2.fromOffset(0, 7),
    Size = UDim2.fromOffset(384, 30),
    BackgroundColor3 = theme.card2,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Profile name",
    PlaceholderColor3 = theme.muted,
    TextColor3 = theme.text,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
})
ui.nameBox.Parent = nameRow
corner(ui.nameBox, 8)
local namePad = new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
namePad.Parent = ui.nameBox
local saveProfileButton = button(nameRow, "Save profile", CARD_INNER - 130, 7, 130, 30, "accent", function()
    saveNamed(ui.nameBox.Text)
end)
ui.saveProfileButton = saveProfileButton

ui.configList = card(configsPage, "Saved profiles", "Load, overwrite or delete a saved configuration.")
refreshConfigs = function()
    if not ui.configList then
        return
    end
    for _, child in ipairs(ui.configList:GetChildren()) do
        if (child:IsA("Frame") and child.Name == "ProfileRow")
            or (child:IsA("TextLabel") and child.Name == "ProfileEmpty") then
            child:Destroy()
        end
    end
    local names = listConfigs()
    table.sort(names)
    if #names == 0 then
        local empty = append(ui.configList, label(nil, "No profiles yet. Save the current setup above to create one.", 0, 0, CARD_INNER, 28, 9, "muted", false, true))
        empty.Name = "ProfileEmpty"
        return
    end
    for _, name in ipairs(names) do
        local profileName = name
        local profileRow = new("Frame", {
            Size = UDim2.fromOffset(CARD_INNER, 42),
            BackgroundColor3 = theme.card2,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        })
        profileRow.Name = "ProfileRow"
        append(ui.configList, profileRow)
        corner(profileRow, 8)
        label(profileRow, profileName, 12, 12, 360, 18, 10, "text", true, false)
        button(profileRow, "Load", CARD_INNER - 190, 8, 58, 26, "accent", function()
            loadNamed(profileName)
        end)
        button(profileRow, "Save", CARD_INNER - 126, 8, 58, 26, "card2", function()
            saveNamed(profileName)
        end)
        button(profileRow, "Del", CARD_INNER - 62, 8, 58, 26, "card2", function()
            deleteNamed(profileName)
        end)
    end
end
ui.refreshConfigs = refreshConfigs

local transferCard = card(configsPage, "Transfer", "Move a full settings package between executors with the clipboard.")
local transferRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 34), BackgroundTransparency = 1 })
append(transferCard, transferRow)
button(transferRow, "Export JSON", 0, 0, 150, 34, "card2", exportSettings)
button(transferRow, "Import JSON", 168, 0, 150, 34, "card2", importSettings)
button(transferRow, "Copy folder path", 336, 0, 150, 34, "card2", function()
    if type(setclipboard) == "function" then
        pcall(setclipboard, CONFIG_DIR)
        notify("Config folder path copied.", "success")
    else
        notify("Clipboard write is unavailable.", "warn")
    end
end)
label(transferCard, CONFIG_DIR, 0, 0, CARD_INNER, 14, 8, "muted", false, false)

-- ============================================================ stats
local statsPage = addPage("stats", "Stats", "Session stats", "Counters, run history and compute trends.", "System", "TELEMETRY")
ui.statMetrics = {}
local statsRows = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 190), BackgroundTransparency = 1 })
local statsCard = card(statsPage, "Lifetime counters", "Values exposed by the live policy loop.")
append(statsCard, statsRows)
metricTile(statsRows, "decisions", ui.statMetrics, "DECISIONS", 0, 0, 206, 86)
metricTile(statsRows, "loads", ui.statMetrics, "POLICY LOADS", 224, 0, 206, 86)
metricTile(statsRows, "runs", ui.statMetrics, "BOT RUNS", 448, 0, 206, 86)
metricTile(statsRows, "compute", ui.statMetrics, "COMPUTE", 0, 104, 206, 86)
metricTile(statsRows, "latency", ui.statMetrics, "LATENCY", 224, 104, 206, 86)
metricTile(statsRows, "hooks", ui.statMetrics, "HOOKS", 448, 104, 206, 86)

local statPulseCard = card(statsPage, "Compute trend", "One bar per sampled decision.")
local _, statBars = sparkline(statPulseCard)
ui.statBars = statBars

local runCard = card(statsPage, "Current run", "The active session is recorded when auto-play is disabled.")
ui.currentRun = label(runCard, "No active run.", 0, 0, CARD_INNER, 20, 10, "muted", false, true)

local historyCard = card(statsPage, "Run history", "The last eight bot runs with mode, duration and decisions.")
ui.historyList = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
ui.historyList.Parent = historyCard
local historyLayout = new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
historyLayout.Parent = ui.historyList

local function copyStats()
    if type(setclipboard) ~= "function" then
        notify("Clipboard write is unavailable.", "warn")
        return
    end
    local lines = { "Experimental Apex v" .. VERSION .. " - session stats" }
    for _, entry in ipairs(bot.history or {}) do
        lines[#lines + 1] = string.format("%s | %s | %d decisions | %.1fms | %.1fs", entry.mode, entry.time, entry.decisions, entry.compute, entry.duration)
    end
    pcall(setclipboard, table.concat(lines, "\n"))
    notify("Stats copied to the clipboard.", "success")
end

refreshHistory = function()
    if not ui.historyList then
        return
    end
    for _, child in ipairs(ui.historyList:GetChildren()) do
        if (child:IsA("Frame") and child.Name == "HistoryRow")
            or (child:IsA("TextLabel") and child.Name == "HistoryEmpty") then
            child:Destroy()
        end
    end
    local history = bot.history or {}
    if #history == 0 then
        local empty = append(ui.historyList, label(nil, "No completed runs yet. Enable, then disable auto-play to record one.", 0, 0, CARD_INNER, 28, 9, "muted", false, true))
        empty.Name = "HistoryEmpty"
        return
    end
    for index = 1, math.min(#history, MAX_HISTORY) do
        local entry = history[index]
        local historyRow = new("Frame", {
            Size = UDim2.fromOffset(CARD_INNER, 34),
            BackgroundColor3 = theme.card2,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
        })
        historyRow.Name = "HistoryRow"
        append(ui.historyList, historyRow)
        corner(historyRow, 7)
        label(historyRow, entry.mode or "Balanced", 10, 9, 90, 16, 9, "text", true, false)
        label(historyRow, entry.time or "-", 108, 9, 92, 16, 8, "muted", false, false)
        label(historyRow, tostring(entry.decisions or 0) .. " decisions", 210, 9, 130, 16, 8, "muted", false, false)
        label(historyRow, string.format("%.1f ms", entry.compute or 0), 350, 9, 100, 16, 8, "muted", false, false)
        label(historyRow, string.format("%.1f s", entry.duration or 0), 470, 9, 80, 16, 8, "muted", false, false)
    end
end
ui.refreshHistory = refreshHistory

local statsActions = card(statsPage, "Data")
buttonRow(statsActions, "Reset stats", "Clear counters and run history for this session.", "RESET", function()
    if bot.resetStats then bot.resetStats() end
    refreshHistory()
    notify("Stats cleared.", "info")
end, "card2")
buttonRow(statsActions, "Copy stats", "Copy a compact text summary of the recorded runs.", "COPY", copyStats, "card2")

-- ============================================================ activity
local activityPage = addPage("activity", "Activity", "Activity", "A timestamped stream of menu and session events.", "System", "FEED")
ui.activityList = card(activityPage, "Event stream", "Newest first. Logging can be disabled in Automation.")
refreshActivity = function()
    if not ui.activityList then
        return
    end
    for _, child in ipairs(ui.activityList:GetChildren()) do
        if (child:IsA("Frame") and child.Name == "ActivityRow")
            or (child:IsA("TextLabel") and child.Name == "ActivityEmpty") then
            child:Destroy()
        end
    end
    if #logEntries == 0 then
        local empty = append(ui.activityList, label(nil, "No activity yet. Actions, mode changes and session events appear here.", 0, 0, CARD_INNER, 28, 9, "muted", false, true))
        empty.Name = "ActivityEmpty"
    else
        for index = 1, math.min(#logEntries, 12) do
            local entry = logEntries[index]
            local activityRow = new("Frame", {
                Size = UDim2.fromOffset(CARD_INNER, 30),
                BackgroundColor3 = theme.card2,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
            })
            activityRow.Name = "ActivityRow"
            append(ui.activityList, activityRow)
            corner(activityRow, 7)
            label(activityRow, entry.time, 10, 7, 58, 16, 8, "muted", false, false)
            local kindLabel = label(activityRow, string.upper(entry.kind), 74, 7, 64, 16, 7, "muted", true, false)
            if entry.kind == "danger" or entry.kind == "warn" then
                kindLabel.TextColor3 = entry.kind == "danger" and theme.danger or theme.warn
            elseif entry.kind == "success" or entry.kind == "bot" then
                kindLabel.TextColor3 = theme.success
            else
                kindLabel.TextColor3 = theme.accent
            end
            label(activityRow, entry.text, 146, 7, 494, 18, 9, "text", false, true)
        end
    end
    if not ui.recentList then
        return
    end
    for _, child in ipairs(ui.recentList:GetChildren()) do
        if (child:IsA("Frame") and child.Name == "RecentRow")
            or (child:IsA("TextLabel") and child.Name == "RecentEmpty") then
            child:Destroy()
        end
    end
    if #logEntries == 0 then
        local empty = append(ui.recentList, label(nil, "Nothing yet. Actions will appear here.", 0, 0, CARD_INNER, 16, 9, "muted", false, false))
        empty.Name = "RecentEmpty"
    else
        for index = 1, math.min(#logEntries, 4) do
            local entry = logEntries[index]
            local recentRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 18), BackgroundTransparency = 1 })
            recentRow.Name = "RecentRow"
            append(ui.recentList, recentRow)
            label(recentRow, entry.time, 0, 0, 58, 16, 8, "muted", false, false)
            label(recentRow, entry.text, 64, 0, CARD_INNER - 64, 16, 9, "text", false, false)
        end
    end
end
ui.refreshActivity = refreshActivity

local activityActions = card(activityPage, "Log controls")
buttonRow(activityActions, "Copy activity", "Copy the current event stream to the clipboard.", "COPY", copyLogs, "card2")
buttonRow(activityActions, "Clear activity", "Remove every recorded event from this session.", "CLEAR", function()
    logEntries = {}
    refreshActivity()
    notify("Activity cleared.", "info")
end, "card2")

-- ============================================================ about
local aboutPage = addPage("about", "About", "About Apex", "Build details, runtime state and diagnostics.", "Info", "INFO")
local aboutCard = card(aboutPage, "Apex build", "v" .. VERSION .. " // native Roblox Instances only. No external UI library, no model swap.")
local aboutRows = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 144), BackgroundTransparency = 1 })
append(aboutCard, aboutRows)
ui.about = {}
local function aboutRow(title, key, x, y)
    local item = new("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(204, 40),
        BackgroundColor3 = theme.card2,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
    })
    item.Parent = aboutRows
    corner(item, 8)
    label(item, title, 10, 6, 190, 12, 7, "muted", true, false)
    local value = label(item, "-", 10, 20, 190, 14, 9, "text", true, false)
    ui.about[key] = value
end
aboutRow("GAME", "game", 0, 0)
aboutRow("MODEL", "model", 224, 0)
aboutRow("CORE", "core", 448, 0)
aboutRow("UI", "ui", 0, 48)
aboutRow("THEME", "theme", 224, 48)
aboutRow("ENGINE", "engine", 448, 48)
aboutRow("UPTIME", "uptime", 0, 96)
aboutRow("HOOKS", "hooks", 224, 96)
aboutRow("VERSION", "version", 448, 96)

local changelog = card(aboutPage, "v4.0.0 changelog", "The Apex rebuild.")
for _, line in ipairs({
    "Native 960x620 window with draggable chrome and instant command palette.",
    "Six themes, six accents, scale and opacity controls with live updates.",
    "Four playstyle engines plus balanced reference mode, with bias strength.",
    "Session metrics, compute sparkline, run history and activity stream.",
    "FPS guard, session limit, profile transfer and full diagnostics.",
}) do
    local row = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 20), BackgroundTransparency = 1 })
    append(changelog, row)
    label(row, "-", 0, 0, 14, 18, 10, "accent", true, false)
    label(row, line, 16, 0, CARD_INNER - 16, 18, 9, "muted", false, true)
end

local diagnosticsCard = card(aboutPage, "Diagnostics")
local diagnosticsRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 34), BackgroundTransparency = 1 })
append(diagnosticsCard, diagnosticsRow)
button(diagnosticsRow, "Copy diagnostics", 0, 0, 150, 34, "card2", copyDiagnostics)
button(diagnosticsRow, "Reload script", 168, 0, 150, 34, "card2", reloadScript)
button(diagnosticsRow, "Copy loadstring", 336, 0, 150, 34, "card2", copyLoadstring)
button(diagnosticsRow, "Unload", 504, 0, 150, 34, "danger", unloadScript)
divider(diagnosticsCard)
buttonRow(diagnosticsCard, "Reset everything", "Restore defaults, including appearance and keybinds.", "RESET", function()
    resetSettings()
    refreshHistory()
end, "card2")

local credits = card(aboutPage, "Credits")
append(credits, label(nil, "Built for Blox League and Turbo Soccer. Policy core retained from the v0.2.1 experimental model. Interface, telemetry and playstyle engines are native additions.", 0, 0, CARD_INNER, 36, 9, "muted", false, true))

-- ============================================================ finalization
syncUiFromSettings = function()
    for key, setter in pairs(ui.setters) do
        if settings[key] ~= nil then
            pcall(setter, settings[key])
        end
    end
    if ui.menuScale then
        ui.menuScale.Scale = settings.menuScale
    end
    if ui.refreshHints then pcall(ui.refreshHints) end
    if ui.refreshModes then pcall(ui.refreshModes) end
    if ui.refreshThemes then pcall(ui.refreshThemes) end
    if ui.refreshConfigs then pcall(ui.refreshConfigs) end
    if ui.refreshActivity then pcall(ui.refreshActivity) end
    if ui.refreshHistory then pcall(ui.refreshHistory) end
end
ui.syncUiFromSettings = syncUiFromSettings

for index, item in ipairs(ui.pages) do
    local pageIndex = index
    addCommand("Go to " .. item.title, item.subtitle, function()
        setPage(pageIndex)
    end)
end
addCommand("Start auto-play", "Enable the policy", function()
    setEnabled(true)
end)
addCommand("Stop auto-play", "Disable the policy", function()
    setEnabled(false)
end)
addCommand("Panic disable", "Stop and release input", function()
    setEnabled(false)
end)
addCommand("Toggle menu", "Show or hide Apex", function()
    setMenu(not gui.Enabled)
end)
addCommand("Cycle theme", "Switch to the next palette", function()
    local order = { "Midnight", "Carbon", "Amethyst", "Ocean", "Ember", "Frost" }
    local current = 1
    for index, name in ipairs(order) do
        if name == settings.theme then
            current = index
            break
        end
    end
    setSetting("theme", order[current % #order + 1])
    applyTheme()
    notify("Theme: " .. settings.theme, "info")
end)
addCommand("Copy diagnostics", "Copy a runtime report", copyDiagnostics)
addCommand("Copy loadstring", "Copy the injection line", copyLoadstring)
addCommand("Reload script", "Re-download and re-inject", reloadScript)
addCommand("Unload script", "Remove the interface and stop", unloadScript)
addCommand("Reset stats", "Clear counters and run history", function()
    if bot.resetStats then bot.resetStats() end
    refreshHistory()
end)
addCommand("Export settings", "Copy settings JSON", exportSettings)
addCommand("Import settings", "Read settings JSON from clipboard", importSettings)

setPage(1)
syncUiFromSettings()
ui.dashboardSet(enabled)
applyTheme()
refreshConfigs()
refreshActivity()
refreshHistory()
setMenu(true)
status("Ready - press " .. tostring(settings.bindMenu) .. " to hide the menu")
notify("Apex v" .. VERSION .. " loaded.", "success")
logEvent("system", "Apex v" .. VERSION .. " loaded")

bot.toggleMenu = function()
    setMenu(not gui.Enabled)
end
bot.openSearch = commandPalette
bot.uiReady = true

end

buildMenu()
local generation=0
local action,job,pending
local nextTick,lastProgress,lastTick=0,0,nil
local lastPublished,decisions,computeMs,latencyMs=0,0,0,0
local identity,arenaIdentity,carIdentity,opponentIdentity
local centered=false
local previous={0,0,0,0,0,0,0,0}
local P,Input,Prediction,refreshGame
local Controller
local matchWaiting="Finding game interfaces"
local blocked=false
local hooked={}
local errorAt=0
reset=function()
    generation+=1;action=nil;job=nil;pending=nil;nextTick=0;lastPublished=0
    for i=1,8 do previous[i]=0 end
end
local unload
unload=function()
    if not alive then return end
    alive=false;enabled=false;reset()
    for _,c in connections do c:Disconnect()end
    for i=#hooked,1,-1 do
        local h=hooked[i]
        if h.object[h.key]==h.wrapper then h.object[h.key]=h.original end
    end
    table.clear(hooked)
    if env.ExperimentalBotUnload==unload then env.ExperimentalBotUnload=nil end
    gui:Destroy()
end
env.ExperimentalBotUnload=unload
connect(gui.Destroying,unload)
task.spawn(function()
while alive do
local connectionStart=#connections
local ok,err=xpcall(function()
    assert(type(vector)=="table" and type(vector.create)=="function","This runner needs Luau vector support")
    assert(type(buffer)=="table" and type(buffer.readf32)=="function","This runner needs Luau buffer support")
    local Policy=(function()
local Policy = {}
Policy.__index = Policy
local create, zero = vector.create, vector.zero
local specs = {{109,512},{512,512},{512,512},{512,512},{512,1024},{1024,512},{512,512},{512,512},{512,512},{512,90}}
Policy.bytes = 10955112
Policy.actions = {}
for _,throttle in {-1,0,1} do
    for _,steer in {-1,0,1} do
        for _,boost in {0,1} do
            for _,brake in {0,1} do
                if boost==0 or throttle==1 then
                    table.insert(Policy.actions,{throttle,steer,0,steer,0,0,boost,brake})
                end
            end
        end
    end
end
for _,pitch in {-1,0,1} do
    for _,yaw in {-1,0,1} do
        for _,roll in {-1,0,1} do
            for _,jump in {0,1} do
                for _,boost in {0,1} do
                    if not(jump==1 and yaw~=0) and not(pitch==0 and roll==0 and jump==0) then
                        table.insert(Policy.actions,{boost,yaw,pitch,yaw,roll,jump,boost,(jump==1 and (pitch~=0 or yaw~=0 or roll~=0)) and 1 or 0})
                    end
                end
            end
        end
    end
end
assert(#Policy.actions==90,"Invalid action table")

function Policy.decode(encoded, checkpoint, fastDecoder)
    if fastDecoder then
        local ok, decoded = pcall(fastDecoder,encoded)
        if ok and type(decoded)=="string" and #decoded==Policy.bytes then
            return buffer.fromstring(decoded)
        end
    end
    local map=table.create(256,0)
    local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    for i=1,64 do map[string.byte(alphabet,i)]=i-1 end
    local output=buffer.create(Policy.bytes)
    local at=0
    for i=1,#encoded,4 do
        local a,b,c,d=string.byte(encoded,i,i+3)
        local n=map[a]*262144+map[b]*4096+map[c]*64+map[d]
        if at<Policy.bytes then buffer.writeu8(output,at,bit32.rshift(n,16));at+=1 end
        if at<Policy.bytes then buffer.writeu8(output,at,bit32.band(bit32.rshift(n,8),255));at+=1 end
        if at<Policy.bytes then buffer.writeu8(output,at,bit32.band(n,255));at+=1 end
        if i%16384==1 and checkpoint then checkpoint("Decoding weights",i/#encoded) end
    end
    assert(at==Policy.bytes,"Incomplete model data")
    return output
end

function Policy.load(bytes,checkpoint)
    assert(buffer.len(bytes)==Policy.bytes,"Model size mismatch")
    local layers, offset = {}, 0
    local read=buffer.readf32
    for index,spec in specs do
        local inputs, outputs = spec[1],spec[2]
        local groups=math.ceil(inputs/3)
        local layer={inputs=inputs,outputs=outputs,groups=groups,w=table.create(outputs*groups),b=table.create(outputs),packed=table.create(groups),x=table.create(outputs,0)}
        for row=0,outputs-1 do
            local base=offset+row*inputs*4
            for group=0,groups-1 do
                local col=group*3
                layer.w[row*groups+group+1]=create(read(bytes,base+col*4),col+1<inputs and read(bytes,base+(col+1)*4) or 0,col+2<inputs and read(bytes,base+(col+2)*4) or 0)
            end
            if row%16==0 and checkpoint then checkpoint("Preparing layer "..index.."/10",(index-1+row/outputs)/10) end
        end
        offset+=inputs*outputs*4
        for i=1,outputs do layer.b[i]=read(bytes,offset);offset+=4 end
        if index<#specs then
            layer.g,layer.n=table.create(outputs),table.create(outputs)
            for i=1,outputs do layer.g[i]=read(bytes,offset);offset+=4 end
            for i=1,outputs do layer.n[i]=read(bytes,offset);offset+=4 end
        end
        layers[index]=layer
    end
    assert(offset==Policy.bytes,"Model layout mismatch")
    return setmetatable({layers=layers},Policy)
end

function Policy:forward(observation,checkpoint)
    assert(#observation==109,"Expected 109 observations")
    local x=observation
    for _,layer in self.layers do
        local packed, weights, groups, y = layer.packed,layer.w,layer.groups,layer.x
        for j=1,groups do
            local col=(j-1)*3
            packed[j]=create(x[col+1],col+2<=layer.inputs and x[col+2] or 0,col+3<=layer.inputs and x[col+3] or 0)
        end
        for row=0,layer.outputs-1 do
            local acc=zero
            local base=row*groups
            for j=1,groups do acc+=weights[base+j]*packed[j] end
            y[row+1]=acc.x+acc.y+acc.z+layer.b[row+1]
            if row%16==15 and checkpoint then checkpoint() end
        end
        if layer.g then
            local mean=0
            for i=1,layer.outputs do mean+=y[i] end
            mean/=layer.outputs
            local variance=0
            for i=1,layer.outputs do local d=y[i]-mean;variance+=d*d end
            local inv=1/math.sqrt(variance/layer.outputs+1e-5)
            for i=1,layer.outputs do y[i]=math.max(0,(y[i]-mean)*inv*layer.g[i]+layer.n[i]) end
        end
        x=y
        if checkpoint then checkpoint() end
    end
    return x
end

function Policy.allowed(index,flags)
    local a=Policy.actions[index]
    if not flags.boost and a[7]==1 then return false end
    if flags.turtle then
        return index>24 or (a[1]==0 and a[7]==0)
    elseif flags.ground then
        if index>24 and (a[6]==0 or a[3]~=0 or a[5]~=0) then return false end
        if not flags.jump and a[6]==1 then return false end
    else
        if index<=24 and not(a[8]==0 and a[1]==a[7]) then return false end
        if (not flags.flip or flags.flipping) and a[6]==1 then return false end
    end
    return true
end

function Policy.select(logits,flags)
    local best, value = nil,-math.huge
    for i=1,90 do
        local v=logits[i]
        local a=Policy.actions[i]
        if bot.bias then v=v+bot.bias(a,flags) end
        assert(v==v and math.abs(v)<math.huge,"Non-finite model output")
        if Policy.allowed(i,flags) and v>value then best,value=i,v end
    end
    if not best then
        for i=1,24 do if logits[i]>value then best,value=i,logits[i] end end
    end
    return best, Policy.actions[best]
end
return Policy

end)()
    Controller=(function()
-- Scheduling only. Never modifies, replaces, or reselects a policy action.
local Controller={}
function Controller.budget(dt)
    -- Match v0.1 on fast devices. Allow slightly longer slices at low FPS.
    if dt<=1/60 then return math.clamp(dt*.42,.0025,.008) end
    return math.clamp(dt*.25,.007,.010)
end
return Controller

end)()
    local Observation=(function()
local Observation={}
Observation.locations={{0,-4240,70},{-1792,-4184,70},{1792,-4184,70},{-3072,-4096,73},{3072,-4096,73},{-940,-3308,70},{940,-3308,70},{0,-2816,70},{-3584,-2484,70},{3584,-2484,70},{-1788,-2300,70},{1788,-2300,70},{-2048,-1036,70},{0,-1024,70},{2048,-1036,70},{-3584,0,73},{-1024,0,70},{1024,0,70},{3584,0,73},{-2048,1036,70},{0,1024,70},{2048,1036,70},{-1788,2300,70},{1788,2300,70},{-3584,2484,70},{3584,2484,70},{0,2816,70},{-940,3310,70},{940,3308,70},{-3072,4096,73},{3072,4096,73},{-1792,4184,70},{1792,4184,70},{0,4240,70}}
local function append(o,v,scale,invert)
    local sign=invert and -scale or scale
    o[#o+1]=v.x*sign;o[#o+1]=v.y*sign;o[#o+1]=v.z*scale
end
local function localVec(o,v,rotation,scale)
    o[#o+1]=vector.dot(v,rotation.forward)*scale
    o[#o+1]=vector.dot(v,rotation.right)*scale
    o[#o+1]=vector.dot(v,rotation.up)*scale
end
function Observation.flags(st)
    local ground=st.isOnGround==true
    local jumped=st.hasJumped==true
    local used=st.hasDoubleJumped==true or st.hasFlipped==true
    local timer=st.airTimeSinceJump
    assert(ground or not jumped or used or type(timer)=="number","Missing flip-expiry timer")
    return {ground=ground,jump=ground or not jumped,flip=not st.isDemoed and (ground or (not used and (not jumped or timer<1.25))),boost=st.boost>0,
        flipping=st.isFlipping==true or (st.hasFlipped==true and (st.flipTime or math.huge)<.65),turtle=not ground and st.pos.z<45 and st.rot.up.z<-.8}
end
local function player(o,st,ball,invert)
    append(o,st.pos,1/5000,invert);append(o,st.rot.forward,1,invert);append(o,st.rot.up,1,invert)
    append(o,st.vel,1/2300,invert);append(o,st.angVel,1/3,invert)
    localVec(o,st.angVel,st.rot,1/3)
    localVec(o,ball.pos-st.pos,st.rot,1/5000)
    localVec(o,ball.vel-st.vel,st.rot,1/2300)
    o[#o+1]=st.boost/100;o[#o+1]=st.isOnGround and 1 or 0
    o[#o+1]=Observation.flags(st).flip and 1 or 0
    o[#o+1]=st.isDemoed and 1 or 0;o[#o+1]=st.hasJumped and 1 or 0
end
function Observation.mapPads(pads)
    assert(#pads==34,"Expected the standard 34 boost pads")
    local result,used={},{}
    for i,target in Observation.locations do
        local chosen,best
        for _,pad in pads do
            if not used[pad] and pad.pos then
                local p=pad.pos
                local d=(p.x-target[1])^2+(p.y-target[2])^2+(p.z-target[3])^2
                if not best or d<best then chosen,best=pad,d end
            end
        end
        assert(chosen and best<256,"Boost-pad coordinates do not match training")
        result[i]=chosen;used[chosen]=true
    end
    return result
end
function Observation.build(ball,own,opponent,pads,previous,team)
    local o={};local invert=team==1
    append(o,ball.pos,1/5000,invert);append(o,ball.vel,1/2300,invert);append(o,ball.angVel,1/3,invert)
    for i=1,8 do o[#o+1]=previous[i] end
    for i=1,34 do
        local pad=pads[invert and 35-i or i]
        assert(type(pad.isActive)=="boolean","Boost-pad active flag unavailable")
        assert(pad.isActive or type(pad.cooldown)=="number","Boost cooldown unavailable")
        o[#o+1]=pad.isActive and 1 or 1/(1+math.max(0,pad.cooldown))
    end
    player(o,own,ball,invert)
    if opponent then player(o,opponent,ball,invert)else for _=1,29 do o[#o+1]=0 end end
    assert(#o==109,"Invalid observation layout")
    for _,v in o do assert(type(v)=="number" and v==v and math.abs(v)<math.huge,"Non-finite observation") end
    return o
end
return Observation

end)()
    local MODEL_URL="https://raw.githubusercontent.com/filbygblh/Scruipt/main/model.b64"
    local requestOk,encoded=pcall(function()
        return game:HttpGet(MODEL_URL)
    end)
    assert(requestOk and type(encoded)=="string" and #encoded>0,
        "Failed to download model data from GitHub")

    local loadSlice=os.clock()
    local function loading(stage,fraction)
        if not alive then error("Unloaded",0)end
        if os.clock()-loadSlice>=.005 then
            status(stage.." · "..math.floor(fraction*100).."%")
            task.wait();loadSlice=os.clock()
        end
    end
    local fastDecoder=type(crypt)=="table" and crypt.base64decode or nil
    local bytes=Policy.decode(encoded,loading,fastDecoder)
    encoded=nil
    local network=Policy.load(bytes,loading)
    bytes=nil
    ready=true
    status(enabled and "ON - Ready - Finding match" or "OFF - Ready - Waiting for match")

    local function warnOnce(value)
        local now=os.clock()
        if now-errorAt>3 then errorAt=now;warn("[Experimental] "..tostring(value))end
    end
    local function install(object,key,factory)
        local original=object[key]
        assert(type(original)=="function","Missing "..key.." interface")
        local wrapper=factory(original)
        object[key]=wrapper
        table.insert(hooked,{object=object,key=key,wrapper=wrapper,original=original})
    end
        local function attachTurbo(input,prediction,const)
        local function vec(value)
            if typeof(value)=="vector"then return value end
            return vector.create(value.X,value.Y,value.Z)
        end
        local proxy,sourceMatch,padSourceTurbo
        local cachedTick,cachedPrint,cachedIndex
        local numericKeys={}
        local function discover()
            if type(getgc)~="function"then return end
            for _,item in getgc(true)do
                if type(item)=="table"and rawget(item,1)=="boost"and rawget(item,7)=="supersonicTime"and #item==13 then
                    numericKeys[#numericKeys+1]=item
                end
            end
        end
        discover()
        local function timer(car,index,name)
            if type(car[name])=="number"then return car[name]end
            for _,keys in numericKeys do
                if type(car[keys[2]])=="number"and type(car[keys[3]])=="number"and type(car[keys[4]])=="number"then return car[keys[index]]end
            end
            return nil
        end
        local function refresh(self,force)
            local match=self.match
            local print=match and self.prints and self.prints[match.tick]
            if not print then P=nil;matchWaiting="Waiting for Turbo Soccer simulation";return end
            -- _remember refreshes corrected data immediately. A following step
            -- with the same print can reuse it without rebuilding every table.
            if not force and match==sourceMatch and match.tick==cachedTick
                and print==cachedPrint and self.localIndex==cachedIndex then
                P=proxy
                return
            end
            if match~=sourceMatch then
                reset();sourceMatch=match;padSourceTurbo=nil
                local arena={cars={},boostPads={},phase=print[1],ball={}}
                function arena:IsBallScored()return self.phase~="play"end
                function arena.ball:GetState()return self.state end
                proxy={arena=arena,tick=match.tick,localCarId=self.localIndex}
                function proxy:LocalCar()return self.localCarId and self.arena.cars[self.localCarId]end
            end
            proxy.tick=match.tick;proxy.localCarId=self.localIndex
            local arena=proxy.arena
            arena.phase=print[1]
            arena.ball.state={pos=vec(print[6]),vel=vec(print[7]),angVel=vec(print[8])}
            for i,record in match.cars do
                local at=9+(i-1)*7
                local car=arena.cars[i]
                if not car or car.source~=record.car then
                    car={id=i,source=record.car}
                    function car:GetState()return self.state end
                    arena.cars[i]=car
                end
                car.team=record.team
                local flags=print[at+6]
                assert(type(flags)=="number","Incomplete Turbo Soccer car snapshot")
                local function flag(bit)return bit32.band(flags,bit)~=0 end
                local forward,up=vec(print[at+3]),vec(print[at+4])
                car.state={pos=vec(print[at]),vel=vec(print[at+1]),angVel=vec(print[at+2]),
                    rot={forward=forward,up=up,right=vector.cross(up,forward)},
                    boost=print[at+5],isOnGround=flag(1),hasJumped=flag(2),hasDoubleJumped=flag(4),
                    hasFlipped=flag(8),isFlipping=flag(16),isJumping=flag(32),isDemoed=flag(2048),
                    airTimeSinceJump=timer(record.car,4,"airTimeSinceJump"),flipTime=timer(record.car,3,"flipTime")}
            end
            for i=#arena.cars,#match.cars+1,-1 do arena.cars[i]=nil end
            local rawPads=assert(match.pads and match.pads.pads,"Missing Turbo Soccer boost pads")
            if padSourceTurbo~=rawPads then
                arena.boostPads={};padSourceTurbo=rawPads
                local index=0
                for _,positions in {const.PADS_BIG,const.PADS_SMALL}do
                    for _,position in positions do index+=1;arena.boostPads[index]={pos=vec(position)}end
                end
                assert(index==34,"Unsupported Turbo Soccer boost-pad layout")
            end
            for i,pad in arena.boostPads do
                local raw=assert(rawPads[i],"Missing Turbo Soccer boost pad")
                pad.isActive=raw.isActive
                pad.cooldown=raw.cooldown or (raw.ticks and raw.ticks*(const.TICK_TIME or 1/120))
                assert(type(pad.cooldown)=="number","Missing Turbo Soccer boost-pad timer")
            end
            cachedTick,cachedPrint,cachedIndex=match.tick,print,self.localIndex
            P=proxy
            matchWaiting=proxy.localCarId and "Waiting for live match"or"Waiting for your car"
            if proxy~=identity or proxy.tick~=lastTick then lastProgress=os.clock()end
            lastTick=proxy.tick
        end
        install(input,"read",function(original)
            return function(controls,camera,allowed,...)
                if alive then
                    local nextBlocked=allowed~=true
                    if nextBlocked~=blocked then reset()end
                    blocked=nextBlocked
                end
                return original(controls,camera,allowed,...)
            end
        end)
        install(prediction,"step",function(original)
            return function(self,controls,...)
                if alive and type(self.localIndex)=="number"then
                    local good,why=pcall(refresh,self)
                    if not good then reset();P=nil;matchWaiting="Turbo data · "..tostring(why):sub(1,100);warnOnce(why)end
                    local now=os.clock()
                    local own=P and P:LocalCar()
                    if good and enabled and ready and not blocked and not typing and action and own
                        and own==carIdentity and P==identity and P.arena==arenaIdentity
                        and not own.state.isDemoed and not P.arena:IsBallScored()
                        and controls then
                        controls=table.clone(controls)
                        controls.throttle,controls.steer,controls.pitch,controls.yaw,controls.roll=action[1],action[2],action[3],action[4],action[5]
                        controls.jump,controls.boost,controls.handbrake=action[6]>0,action[7]>0,action[8]>0
                        for i=1,8 do previous[i]=action[i]end
                    end
                end
                return original(self,controls,...)
            end
        end)
        if type(prediction._remember)=="function"then install(prediction,"_remember",function(original)
            return function(self,...)
                local result=table.pack(original(self,...))
                if alive and self.localIndex then
                    local good,why=pcall(refresh,self,true)
                    if not good then reset();P=nil;matchWaiting="Turbo data · "..tostring(why):sub(1,100);warnOnce(why)end
                end
                return table.unpack(result,1,result.n)
            end
        end)end
        if type(prediction.reset)=="function"then install(prediction,"reset",function(original)
            return function(self,...)
                if alive then reset();P=nil;sourceMatch=nil;identity=nil end
                return original(self,...)
            end
        end)end
        Input,Prediction=input,prediction
        matchWaiting="Waiting for Turbo Soccer simulation"
        if type(getgc)=="function"then pcall(function()
            for _,item in getgc(true)do
                if type(item)=="table"and rawget(item,"match")and rawget(item,"prints")and type(rawget(item,"localIndex"))=="number"then
                    local mt=getmetatable(item)
                    if mt==prediction or(type(mt)=="table"and mt.__index==prediction)then
                        local good=pcall(refresh,item)
                        if good and P then break end
                    end
                end
            end
        end)end
        status(enabled and "ON · Waiting for car"or"OFF · Ready · Turbo Soccer")
    end

    local function attach(input,prediction)
        Input,Prediction=input,prediction
        install(prediction,"Step",function(original)
            return function(self,...)
                if alive then
                    P=self
                    local tick=self.tick or 0
                    if self~=identity or tick~=lastTick then lastProgress=os.clock()end
                    lastTick=tick
                end
                return original(self,...)
            end
        end)
        if type(prediction.Clear)=="function"then install(prediction,"Clear",function(original)
            return function(self,...)
                if alive and self==P then reset();P=nil;identity=nil end
                return original(self,...)
            end
        end)end
        if type(input.Gate)=="function"then install(input,"Gate",function(original)
            return function(value,...)
                if alive then
                    local nextBlocked=value==true
                    if nextBlocked~=blocked then reset()end
                    blocked=nextBlocked
                end
                return original(value,...)
            end
        end)end
        install(input,"Read",function(original)
            return function(...)
                local controls=original(...)
                if not alive or not enabled or not ready or blocked or typing or not P or not P.localCarId then return controls end
                local now=os.clock()
                local own=P:LocalCar()
                if not own or own~=carIdentity or P~=identity or P.arena~=arenaIdentity or own.state and own.state.isDemoed then return controls end
                local selected=action
                if not selected then return controls end
                local result=table.clone(controls)
                result.throttle,result.steer,result.pitch,result.yaw,result.roll=selected[1],selected[2],selected[3],selected[4],selected[5]
                -- Keep each policy action's jump duration; never add alternating jump pulses.
                result.jump,result.boost,result.handbrake=selected[6]>0,selected[7]>0,selected[8]>0
                for i=1,8 do previous[i]=selected[i]end
                return result
            end
        end)
        if type(getgc)=="function"then
            pcall(function()
                for _,item in getgc(true)do
                    if type(item)=="table" and rawget(item,"shadow") and rawget(item,"carsById") and rawget(item,"arena")then
                        local mt=getmetatable(item)
                        if mt==prediction or (type(mt)=="table" and mt.__index==prediction)then P=item;lastTick=item.tick;lastProgress=os.clock();break end
                    end
                end
            end)
        end
        status(enabled and "ON · Waiting for car" or "OFF · Ready · Blox League")
    end
    local acquisitionAt,acquiring=0,false
    local function acquire()
        if Input or acquiring or os.clock()<acquisitionAt then return end
        acquisitionAt=os.clock()+2;acquiring=true
        task.spawn(function()
            local good,why=pcall(function()
                if game.PlaceId==101880234193261 then
                    local scripts=LP:FindFirstChild("PlayerScripts")
                    local function modules(holder,clientOverride)
                        local shared=holder and holder:FindFirstChild("Shared")
                        local client=clientOverride or(holder and holder:FindFirstChild("Client"))
                        local net=shared and shared:FindFirstChild("Net")
                        local sim=shared and shared:FindFirstChild("Sim")
                        local im=client and client:FindFirstChild("Input")
                        local pm=net and net:FindFirstChild("Prediction")
                        local cm=sim and sim:FindFirstChild("Const")
                        if im and pm and cm then return im,pm,cm end
                    end
                    local im,pm,cm=modules(scripts)
                    if not im and scripts then
                        for _,holder in scripts:GetDescendants()do
                            im,pm,cm=modules(holder)
                            if im then break end
                        end
                    end
                    if not im and not(scripts and scripts:FindFirstChild("PrivateLiveHost"))then
                        im,pm,cm=modules(RS,RS:FindFirstChild("Client")or(scripts and scripts:FindFirstChild("Client")))
                    end
                    if im then
                        local input,prediction,const=require(im),require(pm),require(cm)
                        if alive and not Input then attachTurbo(input,prediction,const)end
                    end
                    return
                end
                local shared=RS:FindFirstChild("Shared")
                local playerScripts=LP:FindFirstChild("PlayerScripts")
                local client=playerScripts and playerScripts:FindFirstChild("Client")
                local net=shared and shared:FindFirstChild("Net")
                local inputModule=client and client:FindFirstChild("Input")
                local predictionModule=net and net:FindFirstChild("Prediction")
                if not(inputModule and predictionModule)then return end
                local input=require(inputModule);local prediction=require(predictionModule)
                if alive and not Input then attach(input,prediction)end
            end)
            acquiring=false
            if not good then matchWaiting="Interface unavailable · "..tostring(why):sub(1,75);status(matchWaiting);warnOnce(why)end
        end)
    end
    local padArena,padSource,pads
    local function snapshot()
        if refreshGame then refreshGame() end
        if not P or not P.tick or not P.localCarId then return nil,matchWaiting end
        local arena=P.arena
        local car=P:LocalCar()
        if not arena or not car then return nil,"Waiting for your car"end
        if blocked then return nil,"Game controls paused"end
        if arena:IsBallScored()then return nil,"Goal · Waiting for kickoff"end
        local st=car:GetState()
        if st.isDemoed then return nil,"Respawning"end
        if padArena~=arena or padSource~=arena.boostPads then
            pads=Observation.mapPads(arena.boostPads);padArena,padSource=arena,arena.boostPads
        end
        local opponent
        for _,other in arena.cars do
            if other~=car and other.team~=car.team and (not opponent or other.id<opponent.id) then opponent=other end
        end
        local ball=arena.ball:GetState()
        local isCenter=math.abs(ball.pos.x)<1 and math.abs(ball.pos.y)<1 and vector.magnitude(ball.vel)<1 and st.isOnGround and vector.magnitude(st.vel)<10 and vector.magnitude(st.pos-ball.pos)>1000
        local changed=P~=identity or arena~=arenaIdentity or car~=carIdentity or opponent~=opponentIdentity or(P.tick<(nextTick-16))
        if changed or(isCenter and not centered)then reset()end
        identity,arenaIdentity,carIdentity,opponentIdentity=P,arena,car,opponent
        centered=isCenter
        return {tick=P.tick,ball=ball,own=st,opponent=opponent and opponent:GetState(),team=car.team}
    end
    local averageFrame=1/60
    local function publish(frame)
        if not pending then return end
        local result=pending;pending=nil
        if result.generation==generation then
            local flags=Observation.flags(frame.own)
            local best,chosen=Policy.select(result.logits,flags)
            action=chosen;lastPublished=os.clock();decisions+=1
            computeMs=result.compute*1000;latencyMs=(os.clock()-result.started)*1000
            status(string.format("ON - Playing - %.0f FPS - %.0f ms",1/math.max(averageFrame,.001),latencyMs))
        end
    end
    connect(RunService.Heartbeat,function(dt)
        if not alive then return end
        averageFrame=averageFrame*.9+math.min(dt,.1)*.1
        acquire()
        if not enabled then return end
        local worked,why=pcall(function()
            local frame,waiting=snapshot()
            if not frame then
                if job or action or pending then reset()end
                centered=false
                status("ON · "..waiting)
                return
            end
            publish(frame)
            if not job and frame.tick>=nextTick then
                local obs=Observation.build(frame.ball,frame.own,frame.opponent,pads,previous,frame.team)
                local requestedGeneration,requestedTick= generation,frame.tick
                local began=os.clock()
                nextTick=frame.tick+math.clamp(tonumber(settings.decisionInterval) or 8,4,20)
                job=coroutine.create(function()
                    local sliceStart=os.clock();local compute=0
                    local function checkpoint()
                        if not alive or not enabled or generation~=requestedGeneration then error("cancelled",0)end
                        local duration=os.clock()-sliceStart
                        if duration>=Controller.budget(averageFrame)then
                            compute+=duration;coroutine.yield();sliceStart=os.clock()
                        end
                    end
                    local logits=network:forward(obs,checkpoint)
                    compute+=os.clock()-sliceStart
                    return {generation=requestedGeneration,tick=requestedTick,started=began,logits=table.clone(logits),compute=compute}
                end)
            end
            if job then
                local current=job
                local success,result=coroutine.resume(current)
                if not success then job=nil;error(result,0)end
                if coroutine.status(current)=="dead"then
                    job=nil;pending=result;publish(frame)
                        end
            end
        end)
        if not worked then
            job=nil;pending=nil;status("ON · Data error · "..tostring(why):sub(1,60));warnOnce(why)
        end
    end)
    acquire()
end,function(problem)return tostring(problem)end)
if ok then break end
if alive then
    ready=false;reset()
    for i=#connections,connectionStart+1,-1 do connections[i]:Disconnect();connections[i]=nil end
    for i=#hooked,1,-1 do
        local h=hooked[i]
        if h.object[h.key]==h.wrapper then h.object[h.key]=h.original end
        hooked[i]=nil
    end
    P,Input,Prediction,refreshGame=nil,nil,nil,nil
    status((enabled and "ON" or "OFF").." - Retrying setup - "..tostring(err):sub(1,75))
    warn("[Experimental] "..tostring(err))
    task.wait(2)
end
end
end)
-- ============================================================ live telemetry
bot.stats = { loads = 0, runs = 0 }
bot.history = {}
bot.spark = {}
bot.modelStatus = "Loading..."
bot.statsSummary = "Standby"
bot.pauseReason = nil
bot.diagnostics = function() end

local wasReady = false
local wasEnabled = false
local lastUi = 0
local lastSpark = 0
local lowFps = 0
local fpsAverage = 60
local runStart = 0
local runDecisions = 0
local runComputeSum = 0
local runComputeCount = 0
local runMode = "Balanced"
local enabledAt = 0

local function refreshTyping()
    local focused = UIS:GetFocusedTextBox() ~= nil
    local menuPause = settings.pauseOnMenu and gui.Enabled or false
    local nextTyping = (settings.pauseOnType and focused) or menuPause
    bot.pauseReason = menuPause and "menu" or (focused and "typing" or nil)
    if nextTyping == typing then
        return
    end
    typing = nextTyping
    if enabled then
        if typing then
            status(menuPause and "ON - Paused (menu open)" or "ON - Paused (typing)")
        elseif ready then
            status("ON - Playing")
        else
            status("ON - Waiting for live match")
        end
    end
end

local function metric(store, key, value)
    if store and store[key] then
        store[key].Text = tostring(value)
    end
end

local function recordRun()
    local duration = os.clock() - runStart
    if duration < 1 then
        return
    end
    local average = runComputeCount > 0 and runComputeSum / runComputeCount or 0
    table.insert(bot.history, 1, {
        mode = runMode,
        time = os.date("%H:%M:%S"),
        decisions = math.max(0, decisions - runDecisions),
        compute = average,
        duration = duration,
    })
    while #bot.history > MAX_HISTORY do
        table.remove(bot.history)
    end
    if ui.refreshHistory then
        pcall(ui.refreshHistory)
    end
    logEvent("bot", string.format("Run ended: %d decisions in %.1fs", math.max(0, decisions - runDecisions), duration))
end

bot.resetStats = function()
    bot.stats.loads = 0
    bot.stats.runs = 0
    bot.history = {}
    decisions = 0
    computeMs = 0
    latencyMs = 0
    if ui.refreshHistory then pcall(ui.refreshHistory) end
    if ui.currentRun then ui.currentRun.Text = "No active run." end
end

bot.diagnostics = function()
    return table.concat({
        "Experimental Apex v" .. VERSION .. " (" .. detectedGame() .. ")",
        "enabled=" .. tostring(enabled)
            .. " ready=" .. tostring(ready)
            .. " typing=" .. tostring(typing)
            .. " blocked=" .. tostring(blocked),
        "state=" .. tostring(matchWaiting),
        "engine=" .. tostring(settings.botMode)
            .. " strength=" .. tostring(settings.modeStrength)
            .. " interval=" .. tostring(settings.decisionInterval),
        "theme=" .. tostring(settings.theme)
            .. " accent=" .. tostring(settings.accent)
            .. " scale=" .. tostring(settings.menuScale),
        "decisions=" .. tostring(decisions)
            .. " compute=" .. string.format("%.1fms", computeMs or 0)
            .. " latency=" .. string.format("%.1fms", latencyMs or 0),
        "loads=" .. tostring(bot.stats.loads)
            .. " runs=" .. tostring(bot.stats.runs)
            .. " history=" .. tostring(#bot.history),
        "uptime=" .. uptime()
            .. " connections=" .. tostring(#connections)
            .. " hooks=" .. tostring(#hooked),
    }, "\n")
end

connect(RunService.Heartbeat, function(dt)
    if not alive then
        return
    end
    local now = os.clock()
    fpsAverage = fpsAverage * 0.9 + (1 / math.max(dt or 0.016, 0.001)) * 0.1
    if now - lastUi < 0.25 then
        return
    end
    lastUi = now

    refreshTyping()

    if ready and not wasReady then
        bot.stats.loads += 1
        logEvent("system", "Policy model ready")
    end
    wasReady = ready

    if enabled and not wasEnabled then
        runStart = now
        enabledAt = now
        runDecisions = decisions
        runComputeSum = 0
        runComputeCount = 0
        runMode = settings.botMode
        bot.stats.runs += 1
        logEvent("bot", "Run started with " .. runMode .. " engine")
    elseif not enabled and wasEnabled then
        recordRun()
    end
    wasEnabled = enabled

    if enabled and computeMs and computeMs > 0 then
        runComputeSum += computeMs
        runComputeCount += 1
    end

    if enabled and settings.fpsGuard then
        if fpsAverage < settings.fpsFloor then
            lowFps += 0.25
        else
            lowFps = 0
        end
        if lowFps >= 3 then
            lowFps = 0
            setEnabled(false)
            notify("FPS guard tripped at " .. tostring(math.floor(fpsAverage)) .. " FPS.", "danger", "Safety")
            logEvent("safety", "FPS guard disabled the bot")
        end
    else
        lowFps = 0
    end

    if enabled and settings.autoStopMinutes > 0 and now - enabledAt >= settings.autoStopMinutes * 60 then
        setEnabled(false)
        notify("Session limit reached.", "warn", "Safety")
        logEvent("safety", "Session limit disabled the bot")
    end

    metric(ui.dashMetrics, "decisions", decisions)
    metric(ui.dashMetrics, "compute", string.format("%.1f ms", computeMs or 0))
    metric(ui.dashMetrics, "latency", string.format("%.1f ms", latencyMs or 0))
    metric(ui.dashMetrics, "uptime", uptime())
    metric(ui.statMetrics, "decisions", decisions)
    metric(ui.statMetrics, "loads", bot.stats.loads)
    metric(ui.statMetrics, "runs", bot.stats.runs)
    metric(ui.statMetrics, "compute", string.format("%.1f ms", computeMs or 0))
    metric(ui.statMetrics, "latency", string.format("%.1f ms", latencyMs or 0))
    metric(ui.statMetrics, "hooks", #hooked)

    bot.modelStatus = ready and "Ready" or (blocked and "Blocked" or "Loading...")
    bot.statsSummary = string.format("%d decisions - %.1f ms compute", decisions or 0, computeMs or 0)

    if ui.heroStatus then
        if enabled then
            if typing then
                ui.heroStatus.Text = bot.pauseReason == "menu" and "PAUSED - MENU OPEN" or "PAUSED - TYPING"
                ui.heroStatus.TextColor3 = Color3.fromRGB(251, 191, 36)
            elseif ready then
                ui.heroStatus.Text = "AUTO-PILOT ENGAGED"
                ui.heroStatus.TextColor3 = Color3.fromRGB(74, 222, 128)
            else
                ui.heroStatus.Text = "WAITING FOR MODEL"
                ui.heroStatus.TextColor3 = Color3.fromRGB(96, 165, 250)
            end
        else
            ui.heroStatus.Text = "STANDBY"
            ui.heroStatus.TextColor3 = Color3.fromRGB(144, 148, 172)
        end
        ui.heroSub.Text = detectedGame()
            .. "  //  " .. (ready and "model ready" or "loading model")
            .. "  //  " .. tostring(settings.decisionInterval) .. " frame decisions"
    end

    if ui.about then
        ui.about.game.Text = detectedGame()
        ui.about.model.Text = tostring(bot.modelStatus)
        ui.about.core.Text = "v0.2.1"
        ui.about.ui.Text = "APEX v" .. VERSION
        ui.about.theme.Text = tostring(settings.theme) .. " / " .. tostring(settings.accent)
        ui.about.engine.Text = tostring(settings.botMode) .. " " .. tostring(settings.modeStrength) .. "%"
        ui.about.uptime.Text = uptime()
        ui.about.hooks.Text = tostring(#hooked)
        ui.about.version.Text = VERSION
    end

    if ui.currentRun then
        if enabled then
            ui.currentRun.Text = string.format("%s engine  //  %s  //  %d decisions  //  %.1f ms avg compute", runMode, uptime(), math.max(0, decisions - runDecisions), runComputeCount > 0 and runComputeSum / runComputeCount or 0)
        else
            ui.currentRun.Text = "No active run."
        end
    end

    if ui.footerStatus and ui.footerStatus.Text ~= message then
        ui.footerStatus.Text = message
    end

    if now - lastSpark >= 0.45 then
        lastSpark = now
        table.insert(bot.spark, 1, computeMs or 0)
        while #bot.spark > 32 do
            table.remove(bot.spark)
        end
        local peak = 1
        for _, value in ipairs(bot.spark) do
            if value > peak then peak = value end
        end
        for index = 1, 32 do
            local value = bot.spark[index] or 0
            local height = math.max(4, value / peak * 70)
            if ui.dashBars and ui.dashBars[index] then
                ui.dashBars[index].Size = UDim2.fromOffset(12, height)
            end
            if ui.statBars and ui.statBars[index] then
                ui.statBars[index].Size = UDim2.fromOffset(12, height)
            end
        end
    end
end)

connect(UIS.InputBegan, function(input, processed)
    local key = keyName(input)
    if not key then
        return
    end
    if capturing then
        if key == "Escape" then
            cancelCapture()
        else
            finishCapture(key)
        end
        return
    end
    if ui.paletteOpen then
        if key == "Escape" then
            closePalette()
        elseif key == "Return" or key == "KeypadEnter" then
            ui.runPaletteSelection()
        elseif key == "Down" then
            ui.selectPalette((ui.paletteIndex or 1) + 1)
        elseif key == "Up" then
            ui.selectPalette((ui.paletteIndex or 1) - 1)
        end
        return
    end
    local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
    if ctrl and key == "K" then
        commandPalette()
        return
    end
    if processed then
        return
    end
    if ctrl then
        local page = tonumber(key)
        if page and page >= 1 and page <= #ui.pages then
            setPage(page)
            return
        end
    end
    if key == settings.bindMenu then
        if bot.toggleMenu then bot.toggleMenu() end
    elseif key == settings.bindToggle then
        setEnabled(not enabled)
    elseif key == settings.bindPanic then
        setEnabled(false)
    end
end)

if settings.autoEnable then
    task.defer(function()
        task.wait(1)
        if alive and not enabled then
            setEnabled(true, true)
        end
    end)
end
