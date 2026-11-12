--!native
--!optimize 2
-- Experimental v3.1.0 -- native full menu edition.
-- Blox League / Turbo Soccer.
-- The policy, model loader and hook layer are the v0.2.1 core, unchanged apart
-- from a real typing guard. The interface is built from Instances only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G

if type(env.ExperimentalBotUnload) == "function" then pcall(env.ExperimentalBotUnload) end

local VERSION = "3.1.0"
local SCRIPT_URL = "https://raw.githubusercontent.com/filbygblh/Scruipt/refs/heads/main/experimental.lua"
local FOLDER = "Vunilow/Experimental"
local CONFIG_DIR = FOLDER .. "/configs"
local AUTOSAVE_PATH = FOLDER .. "/settings.json"

local alive, enabled, ready = false, false, false
alive = true
local connections = {}
local message = "Starting up..."
local typing = false
local reset
local startedAt = os.clock()
local bot = {}
local ui = {}
local tabs = {}
local statValues = {}
local toastText, toastUntil = "", 0
local capturing
local gui
local notify = function() end
local refreshConfigs = function() end
local syncUiFromSettings = function() end
local updateHints = function() end
local beginCapture
local cancelCapture
local finishCapture

local settings = {
    autoEnable = false,
    pauseOnType = true,
    notifications = true,
    bindToggle = "F1",
    bindPanic = "F2",
    bindMenu = "Insert",
    menuScale = 1,
}

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
    return {
        autoEnable = settings.autoEnable,
        pauseOnType = settings.pauseOnType,
        notifications = settings.notifications,
        bindToggle = settings.bindToggle,
        bindPanic = settings.bindPanic,
        bindMenu = settings.bindMenu,
        menuScale = settings.menuScale,
    }
end

local function mergeSettings(data)
    if type(data) ~= "table" then
        return
    end
    if type(data.autoEnable) == "boolean" then settings.autoEnable = data.autoEnable end
    if type(data.pauseOnType) == "boolean" then settings.pauseOnType = data.pauseOnType end
    if type(data.notifications) == "boolean" then settings.notifications = data.notifications end
    if type(data.bindToggle) == "string" and data.bindToggle ~= "" then settings.bindToggle = data.bindToggle end
    if type(data.bindPanic) == "string" and data.bindPanic ~= "" then settings.bindPanic = data.bindPanic end
    if type(data.bindMenu) == "string" and data.bindMenu ~= "" then settings.bindMenu = data.bindMenu end
    if type(data.menuScale) == "number" then
        settings.menuScale = math.clamp(data.menuScale, 0.8, 1.15)
    end
end

local function autosave()
    if not hasFileApi() then
        return
    end
    ensureBase()
    writeJson(AUTOSAVE_PATH, settingsSnapshot())
end

mergeSettings(readJson(AUTOSAVE_PATH))

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
        notify("Enter a profile name first.")
        return
    end
    if #name > 32 then
        notify("Profile names are limited to 32 characters.")
        return
    end
    if name:find("[^%w%s_%-]") then
        notify("Use letters, numbers, spaces, _ or - only.")
        return
    end
    if not hasFileApi() then
        notify("This executor has no file API, so profiles cannot be saved.")
        return
    end
    ensureBase()
    ensureFolder(CONFIG_DIR)
    if writeJson(CONFIG_DIR .. "/" .. name .. ".json", settingsSnapshot()) then
        autosave()
        refreshConfigs()
        notify("Saved profile '" .. name .. "'.")
    else
        notify("Could not write the profile file.")
    end
end

local function loadNamed(name)
    local data = readJson(CONFIG_DIR .. "/" .. tostring(name) .. ".json")
    if not data then
        notify("Could not read that profile.")
        return
    end
    mergeSettings(data)
    syncUiFromSettings()
    autosave()
    notify("Loaded profile '" .. tostring(name) .. "'.")
end

local function deleteNamed(name)
    if type(delfile) ~= "function" then
        notify("This executor cannot delete files.")
        return
    end
    if pcall(delfile, CONFIG_DIR .. "/" .. tostring(name) .. ".json") then
        refreshConfigs()
        notify("Deleted profile '" .. tostring(name) .. "'.")
    else
        notify("Could not delete that profile.")
    end
end

local function setEnabled(value, silent)
    value = value and true or false
    enabled = value
    if reset then
        reset()
        status(value and (ready and "ON - Waiting for live match" or "ON - Loading model") or "OFF - Ready")
    end
    if ui.dashboardSet then
        ui.dashboardSet(value)
    end
    if not silent then
        notify(value and "Auto-play enabled" or "Auto-play disabled")
    end
end

local function reloadScript()
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
    if type(env.ExperimentalBotUnload) == "function" then
        env.ExperimentalBotUnload()
    end
end

local function copyDiagnostics()
    if not bot.diagnostics then
        notify("Diagnostics are not ready yet.")
        return
    end
    local text = bot.diagnostics()
    if type(setclipboard) == "function" then
        pcall(setclipboard, text)
        notify("Diagnostics copied to the clipboard.")
    else
        warn(text)
        notify("Clipboard unavailable; printed diagnostics to the console.")
    end
end

local function copyLoadstring()
    if type(setclipboard) ~= "function" then
        notify("Clipboard write is unavailable.")
        return
    end
    pcall(setclipboard, 'loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
    notify("Loadstring copied to the clipboard.")
end

local function resetSettings()
    settings.autoEnable = false
    settings.pauseOnType = true
    settings.notifications = true
    settings.bindToggle = "F1"
    settings.bindPanic = "F2"
    settings.bindMenu = "Insert"
    settings.menuScale = 1
    syncUiFromSettings()
    autosave()
    notify("Settings restored to defaults.")
end

local BIND_LABELS = {
    bindToggle = "toggle bot",
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
        capturing.button.TextColor3 = Color3.fromRGB(239, 237, 255)
    end
    capturing = { kind = kind, button = button }
    button.Text = "Press a key..."
    button.TextColor3 = Color3.fromRGB(151, 111, 255)
end

cancelCapture = function()
    if capturing then
        capturing.button.Text = tostring(settings[capturing.kind] or "?")
        capturing.button.TextColor3 = Color3.fromRGB(239, 237, 255)
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
    button.TextColor3 = Color3.fromRGB(239, 237, 255)
    if key == "Escape" then
        button.Text = tostring(settings[kind] or "?")
        return
    end
    for _, other in ipairs({ "bindToggle", "bindPanic", "bindMenu" }) do
        if other ~= kind and settings[other] == key then
            button.Text = tostring(settings[kind] or "?")
            notify("That key is already bound to " .. tostring(BIND_LABELS[other] or other) .. ".")
            return
        end
    end
    settings[kind] = key
    if ui.setters[kind] then
        pcall(ui.setters[kind], key)
    end
    autosave()
    updateHints()
    notify("Bound " .. tostring(BIND_LABELS[kind] or kind) .. " to " .. key .. ".")
end

local function setSetting(key, value)
    settings[key] = value
    if ui.setters[key] then
        pcall(ui.setters[key], value)
    end
    autosave()
end
-- ============================================================ v3.1.0 native menu
local function buildMenu()
local BG = Color3.fromRGB(15, 17, 24)
local PANEL = Color3.fromRGB(20, 23, 33)
local CARD = Color3.fromRGB(26, 30, 43)
local CARD2 = Color3.fromRGB(32, 36, 52)
local STROKE = Color3.fromRGB(58, 52, 86)
local ACCENT = Color3.fromRGB(151, 111, 255)
local ACCENT_DIM = Color3.fromRGB(80, 62, 140)
local TEXT = Color3.fromRGB(239, 237, 255)
local MUTED = Color3.fromRGB(139, 143, 165)
local GREEN = Color3.fromRGB(74, 222, 128)
local AMBER = Color3.fromRGB(251, 191, 36)
local RED = Color3.fromRGB(190, 70, 90)
local OFF = Color3.fromRGB(52, 56, 74)

local MENU_W, MENU_H = 780, 540
local SIDEBAR_W = 190
local CONTENT_W = MENU_W - SIDEBAR_W
local SCROLL_W = 550
local CARD_W = 540
local CARD_INNER = 512
local FOOTER_H = 34

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

local function stroke(object, color, transparency, thickness)
    local item = new("UIStroke", {
        Color = color or STROKE,
        Transparency = transparency or 0.35,
        Thickness = thickness or 1,
    })
    item.Parent = object
    return item
end

local function append(parent, child)
    child.LayoutOrder = #parent:GetChildren() + 1
    child.Parent = parent
    return child
end

local function textLabel(parent, text, x, y, width, height, size, color, bold, wrap)
    local item = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        Text = text,
        TextSize = size,
        TextColor3 = color or TEXT,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = wrap or false,
    })
    if parent then
        item.Parent = parent
    end
    return item
end

gui = new("ScreenGui", {
    Name = "ExperimentalMenu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 80,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Enabled = true,
})
gui.Parent = LP:WaitForChild("PlayerGui")

local menu = new("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(MENU_W, MENU_H),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})
menu.Parent = gui
corner(menu, 16)
stroke(menu, STROKE, 0.25, 1)

ui.scale = new("UIScale", { Scale = settings.menuScale })
ui.scale.Parent = menu

local accentLine = new("Frame", {
    Size = UDim2.fromOffset(MENU_W - 28, 3),
    Position = UDim2.fromOffset(14, 0),
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
})
accentLine.Parent = menu
corner(accentLine, 2)

local setMenu
local header = new("Frame", {
    Size = UDim2.fromOffset(MENU_W, 76),
    BackgroundTransparency = 1,
    Active = true,
})
header.Parent = menu

textLabel(header, "EXPERIMENTAL", 24, 16, 320, 24, 18, TEXT, true, false)
textLabel(header, "Blox League / Turbo Soccer  -  v" .. VERSION, 24, 42, 460, 16, 10, MUTED, false, false)

local closeButton = new("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -48, 0, 22),
    BackgroundTransparency = 1,
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = MUTED,
    AutoButtonColor = false,
})
closeButton.Parent = header
closeButton.Activated:Connect(function()
    setMenu(false)
end)
closeButton.MouseEnter:Connect(function()
    closeButton.TextColor3 = TEXT
end)
closeButton.MouseLeave:Connect(function()
    closeButton.TextColor3 = MUTED
end)

local headerLine = new("Frame", {
    Size = UDim2.fromOffset(MENU_W, 1),
    Position = UDim2.fromOffset(0, 75),
    BackgroundColor3 = CARD2,
    BorderSizePixel = 0,
})
headerLine.Parent = menu

local sidebar = new("Frame", {
    Position = UDim2.fromOffset(0, 76),
    Size = UDim2.fromOffset(SIDEBAR_W, MENU_H - 76 - FOOTER_H),
    BackgroundColor3 = PANEL,
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
})
sidebar.Parent = menu
corner(sidebar, 12)

local sidebarLine = new("Frame", {
    Position = UDim2.fromOffset(SIDEBAR_W - 1, 76),
    Size = UDim2.fromOffset(1, MENU_H - 76 - FOOTER_H),
    BackgroundColor3 = CARD2,
    BorderSizePixel = 0,
})
sidebarLine.Parent = menu

textLabel(sidebar, "NAVIGATION", 18, 8, 150, 12, 8, MUTED, true, false)
textLabel(sidebar, "v" .. VERSION, 18, 398, 150, 14, 9, MUTED, false, false)

local content = new("Frame", {
    Position = UDim2.fromOffset(SIDEBAR_W, 76),
    Size = UDim2.fromOffset(CONTENT_W, MENU_H - 76 - FOOTER_H),
    BackgroundTransparency = 1,
})
content.Parent = menu

ui.pageTitle = textLabel(content, "Dashboard", 20, 14, 520, 24, 16, TEXT, true, false)
ui.pageSubtitle = textLabel(content, "", 20, 38, 520, 16, 9, MUTED, false, true)

local scroll = new("ScrollingFrame", {
    Position = UDim2.fromOffset(20, 62),
    Size = UDim2.fromOffset(SCROLL_W, 400),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = ACCENT_DIM,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
})
scroll.Parent = content
ui.scroll = scroll
local scrollLayout = new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder })
scrollLayout.Parent = scroll

local footer = new("Frame", {
    Position = UDim2.fromOffset(0, MENU_H - FOOTER_H),
    Size = UDim2.fromOffset(MENU_W, FOOTER_H),
    BackgroundColor3 = PANEL,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
})
footer.Parent = menu
corner(footer, 12)
local footerLine = new("Frame", { Size = UDim2.fromOffset(MENU_W, 1), BackgroundColor3 = CARD2, BorderSizePixel = 0 })
footerLine.Parent = footer

ui.footerStatus = textLabel(footer, message, 20, 9, 540, 16, 10, MUTED, false, false)
ui.footerHint = textLabel(footer, tostring(settings.bindMenu) .. "  close", MENU_W - 180, 9, 160, 16, 10, MUTED, false, false)
ui.footerHint.TextXAlignment = Enum.TextXAlignment.Right

local drag
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = { input = input, start = input.Position, position = menu.AbsolutePosition, touch = input.UserInputType == Enum.UserInputType.Touch }
    end
end)
connect(UIS.InputChanged, function(input)
    if not drag then return end
    local moving = (drag.touch and input == drag.input) or (not drag.touch and input.UserInputType == Enum.UserInputType.MouseMovement)
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

notify = function(text, duration)
    if not settings.notifications then
        return
    end
    toastText = tostring(text)
    toastUntil = os.clock() + (duration or 3)
    ui.footerStatus.Text = toastText
end

local selectTab
local activeTab = 1
local pageSubtitles = {
    "Live control and session overview.",
    "Startup behavior and input safety.",
    "Appearance, keybinds and defaults.",
    "Saved settings profiles.",
    "Session counters from the policy loop.",
    "Build details and diagnostics.",
}

local function addTab(name, title)
    local index = #tabs + 1
    local page = new("Frame", {
        Size = UDim2.fromOffset(SCROLL_W, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    })
    local layout = new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
    layout.Parent = page
    tabs[index] = { page = page, title = title, button = nil }
    local button = new("TextButton", {
        Size = UDim2.fromOffset(166, 38),
        Position = UDim2.fromOffset(12, 26 + (index - 1) * 46),
        BackgroundColor3 = ACCENT_DIM,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
    })
    button.Parent = sidebar
    corner(button, 9)
    local bar = new("Frame", {
        Size = UDim2.fromOffset(3, 16),
        Position = UDim2.fromOffset(0, 11),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        Visible = false,
    })
    bar.Parent = button
    corner(bar, 2)
    local label = textLabel(button, name, 16, 9, 140, 20, 11, MUTED, true, false)
    tabs[index].button = button
    tabs[index].bar = bar
    tabs[index].label = label
    button.Activated:Connect(function()
        selectTab(index)
    end)
    return page
end

selectTab = function(index)
    activeTab = index
    for i, tab in ipairs(tabs) do
        local on = i == index
        tab.page.Visible = on
        if on then
            tab.page.Parent = scroll
            tab.page.LayoutOrder = 1
            ui.pageTitle.Text = tab.title
            ui.pageSubtitle.Text = pageSubtitles[index] or ""
        else
            tab.page.Parent = nil
        end
        tab.bar.Visible = on
        tab.button.BackgroundTransparency = on and 0.82 or 1
        tab.label.TextColor3 = on and TEXT or MUTED
    end
    scroll.CanvasPosition = Vector2.new(0, 0)
    if index == 4 then
        refreshConfigs()
    end
end

setMenu = function(open)
    gui.Enabled = open and true or false
    if not gui.Enabled then
        cancelCapture()
    else
        if ui.refreshConfigs then pcall(ui.refreshConfigs) end
    end
end
ui.setMenu = setMenu

local function row(parent, title, desc, reserve, height)
    local item = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, height or 52), BackgroundTransparency = 1 })
    if parent then
        append(parent, item)
    end
    local width = CARD_INNER - (reserve or 150)
    textLabel(item, title, 0, 2, width, 18, 11, TEXT, true, false)
    if desc and desc ~= "" then
        textLabel(item, desc, 0, 22, width, 26, 9, MUTED, false, true)
    end
    return item
end

local function section(page, title)
    local card = new("Frame", {
        Size = UDim2.fromOffset(CARD_W, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = CARD,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
    })
    corner(card, 12)
    stroke(card, STROKE, 0.5, 1)
    append(page, card)
    local pad = new("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    })
    pad.Parent = card
    local layout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    layout.Parent = card
    append(card, textLabel(nil, string.upper(title), 0, 0, CARD_INNER, 14, 9, MUTED, true, false))
    return card
end

local function makeToggle(parent, initial, onChange)
    local value = initial and true or false
    local toggle = new("TextButton", {
        Position = UDim2.new(1, -46, 0, 15),
        Size = UDim2.fromOffset(46, 24),
        BackgroundColor3 = value and ACCENT or OFF,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
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
        TweenService:Create(toggle, TweenInfo.new(0.16), { BackgroundColor3 = value and ACCENT or OFF }):Play()
        TweenService:Create(knob, TweenInfo.new(0.16), { Position = UDim2.fromOffset(value and 25 or 3, 3) }):Play()
        if not silent and onChange then
            onChange(value)
        end
    end
    toggle.Activated:Connect(function()
        set(not value)
    end)
    return set
end

local function toggleRow(card, key, title, desc, onChange)
    local item = row(card, title, desc, 150)
    local set = makeToggle(item, settings[key], function(value)
        setSetting(key, value)
        if onChange then onChange(value) end
    end)
    ui.setters[key] = function(value)
        set(value, true)
    end
    return set
end

local function buttonRow(card, title, desc, labelText, onClick, color)
    local item = row(card, title, desc, 150)
    local button = new("TextButton", {
        Size = UDim2.fromOffset(120, 28),
        Position = UDim2.new(1, -120, 0, 13),
        BackgroundColor3 = color or ACCENT,
        Text = labelText,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
    })
    button.Parent = item
    corner(button, 8)
    button.Activated:Connect(onClick)
    return button
end

local function keybindRow(card, key, title, desc)
    local item = row(card, title, desc, 160)
    local button = new("TextButton", {
        Size = UDim2.fromOffset(130, 28),
        Position = UDim2.new(1, -130, 0, 13),
        BackgroundColor3 = CARD2,
        Text = tostring(settings[key] or "?"),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = TEXT,
        AutoButtonColor = false,
    })
    button.Parent = item
    corner(button, 8)
    button.Activated:Connect(function()
        beginCapture(key, button)
    end)
    ui.setters[key] = function(value)
        button.Text = tostring(value)
    end
    return button
end

-- ============================================================ dashboard
local dashboard = addTab("Dashboard", "Dashboard")
ui.pageSubtitle.Text = "Live control and session overview."
local statusCard = section(dashboard, "Live status")
ui.dashStatus = append(statusCard, textLabel(nil, "DISABLED", 0, 0, CARD_INNER, 22, 16, MUTED, true, false))
ui.dashDetails = append(statusCard, textLabel(nil, "", 0, 0, CARD_INNER, 28, 9, MUTED, false, true))

local controlCard = section(dashboard, "Control")
local controlRow = append(controlCard, row(nil, "Auto-play", "Start or stop the policy loop.", 150))
local controlButton = new("TextButton", {
    Size = UDim2.fromOffset(120, 30),
    Position = UDim2.new(1, -120, 0, 11),
    BackgroundColor3 = ACCENT,
    Text = "Start bot",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    AutoButtonColor = false,
})
controlButton.Parent = controlRow
corner(controlButton, 8)
controlButton.Activated:Connect(function()
    setEnabled(not enabled)
end)

local panicRow = append(controlCard, row(nil, "Panic disable", "Immediately stop and release the current action.", 150))
local panicButton = new("TextButton", {
    Size = UDim2.fromOffset(120, 28),
    Position = UDim2.new(1, -120, 0, 12),
    BackgroundColor3 = RED,
    Text = "PANIC",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    AutoButtonColor = false,
})
panicButton.Parent = panicRow
corner(panicButton, 8)
panicButton.Activated:Connect(function()
    setEnabled(false)
end)

ui.dashboardSet = function(value)
    value = value and true or false
    ui.dashStatus.Text = value and "ENABLED" or "DISABLED"
    ui.dashStatus.TextColor3 = value and GREEN or MUTED
    controlButton.Text = value and "Stop bot" or "Start bot"
    controlButton.BackgroundColor3 = value and RED or ACCENT
end

local sessionCard = section(dashboard, "Session")
local sessionGame = append(sessionCard, textLabel(nil, "Game: " .. detectedGame(), 0, 0, CARD_INNER, 16, 10, TEXT, false, false))
local sessionVersion = append(sessionCard, textLabel(nil, "Build: v" .. VERSION, 0, 0, CARD_INNER, 16, 10, MUTED, false, false))
ui.sessionUptime = append(sessionCard, textLabel(nil, "Uptime: 0:00", 0, 0, CARD_INNER, 16, 10, MUTED, false, false))

-- ============================================================ automation
local automation = addTab("Automation", "Automation")
ui.pageSubtitle.Text = "Startup behavior and input safety."
local behaviorCard = section(automation, "Behavior")
toggleRow(behaviorCard, "autoEnable", "Enable on inject", "Start the bot automatically when this script runs.", function(value)
    notify(value and "Auto-start enabled." or "Auto-start disabled.")
end)
toggleRow(behaviorCard, "pauseOnType", "Pause while typing", "Stop sending inputs while the chat or a text box is focused.", function(value)
    notify(value and "Typing guard enabled." or "Typing guard disabled.")
end)
toggleRow(behaviorCard, "notifications", "Notifications", "Show short confirmations in the footer.")
buttonRow(automation, "Safety", "Panic disable", "Stop the bot and release inputs immediately.", "PANIC", function()
    setEnabled(false)
end, RED)

-- ============================================================ settings
local settingsPage = addTab("Settings", "Settings")
ui.pageSubtitle.Text = "Appearance, keybinds and defaults."
local appearanceCard = section(settingsPage, "Appearance")
local scaleRow = append(appearanceCard, row(nil, "Menu scale", "Resize the window without changing the layout.", 230))
local scaleValue = textLabel(scaleRow, tostring(math.floor(settings.menuScale * 100 + 0.5)) .. "%", 246, 18, 48, 18, 10, MUTED, true, false)
local scaleButtons = {}
local function markScale()
    for amount, button in pairs(scaleButtons) do
        button.BackgroundColor3 = math.abs(settings.menuScale - amount) < 0.001 and ACCENT or CARD2
    end
end
for _, entry in ipairs({ { "80%", 0.8 }, { "100%", 1 }, { "115%", 1.15 } }) do
    local amount = entry[2]
    local button = new("TextButton", {
        Size = UDim2.fromOffset(56, 28),
        Position = UDim2.new(1, -180 + (#scaleButtons) * 62, 0, 14),
        BackgroundColor3 = CARD2,
        Text = entry[1],
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = TEXT,
        AutoButtonColor = false,
    })
    button.Parent = scaleRow
    corner(button, 7)
    scaleButtons[amount] = button
    button.Activated:Connect(function()
        settings.menuScale = amount
        ui.scale.Scale = amount
        scaleValue.Text = tostring(math.floor(amount * 100 + 0.5)) .. "%"
        markScale()
        autosave()
    end)
end
ui.setters.menuScale = function(value)
    if ui.scale then ui.scale.Scale = value end
    if scaleValue then scaleValue.Text = tostring(math.floor(value * 100 + 0.5)) .. "%" end
    markScale()
end
markScale()

local keybindCard = section(settingsPage, "Keybinds")
keybindRow(keybindCard, "bindMenu", "Toggle menu", "Show or hide this window.")
keybindRow(keybindCard, "bindToggle", "Toggle bot", "Start or stop auto-play.")
keybindRow(keybindCard, "bindPanic", "Panic disable", "Stop the bot and release inputs.")

local defaultsCard = section(settingsPage, "Defaults")
buttonRow(defaultsCard, "Restore defaults", "Reset keybinds, appearance and behavior switches.", "RESET", function()
    resetSettings()
end, CARD2)

-- ============================================================ configs
local configs = addTab("Configs", "Configs")
ui.pageSubtitle.Text = "Saved settings profiles."
local saveCard = section(configs, "Save current settings")
local nameRow = append(saveCard, row(nil, "", "", 0, 44))
ui.nameBox = new("TextBox", {
    Position = UDim2.fromOffset(0, 7),
    Size = UDim2.fromOffset(384, 30),
    BackgroundColor3 = CARD2,
    Text = "",
    PlaceholderText = "Profile name",
    PlaceholderColor3 = MUTED,
    TextColor3 = TEXT,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
})
ui.nameBox.Parent = nameRow
corner(ui.nameBox, 8)
local namePad = new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
namePad.Parent = ui.nameBox
local saveButton = new("TextButton", {
    Size = UDim2.fromOffset(112, 30),
    Position = UDim2.new(1, -112, 0, 7),
    BackgroundColor3 = ACCENT,
    Text = "Save profile",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    AutoButtonColor = false,
})
saveButton.Parent = nameRow
corner(saveButton, 8)
saveButton.Activated:Connect(function()
    saveNamed(ui.nameBox.Text)
end)

ui.configList = section(configs, "Saved profiles")
refreshConfigs = function()
    if not ui.configList then return end
    for _, child in ipairs(ui.configList:GetChildren()) do
        if (child:IsA("Frame") and child.Name == "ProfileRow")
            or (child:IsA("TextLabel") and child.Name == "ProfileEmpty") then
            child:Destroy()
        end
    end
    local names = listConfigs()
    table.sort(names)
    if #names == 0 then
        local empty = append(ui.configList, textLabel(nil, "No profiles yet. Save the current settings above.", 0, 0, CARD_INNER, 24, 9, MUTED, false, true))
        empty.Name = "ProfileEmpty"
        return
    end
    for _, name in ipairs(names) do
        local profileName = name
        local profileRow = new("Frame", { Size = UDim2.fromOffset(CARD_INNER, 40), BackgroundColor3 = CARD2, BackgroundTransparency = 0.3, BorderSizePixel = 0 })
        profileRow.Name = "ProfileRow"
        append(ui.configList, profileRow)
        corner(profileRow, 8)
        textLabel(profileRow, profileName, 10, 11, 340, 18, 10, TEXT, true, false)
        local load = new("TextButton", { Size = UDim2.fromOffset(58, 26), Position = UDim2.new(1, -130, 0, 7), BackgroundColor3 = ACCENT, Text = "Load", Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = Color3.fromRGB(255, 255, 255), AutoButtonColor = false })
        load.Parent = profileRow
        corner(load, 7)
        load.Activated:Connect(function() loadNamed(profileName) end)
        local del = new("TextButton", { Size = UDim2.fromOffset(58, 26), Position = UDim2.new(1, -64, 0, 7), BackgroundColor3 = CARD, Text = "Del", Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = Color3.fromRGB(220, 160, 175), AutoButtonColor = false })
        del.Parent = profileRow
        corner(del, 7)
        del.Activated:Connect(function() deleteNamed(profileName) end)
    end
end
ui.refreshConfigs = refreshConfigs

-- ============================================================ stats
local stats = addTab("Stats", "Stats")
ui.pageSubtitle.Text = "Session counters from the policy loop."
local statsCard = section(stats, "This session")
local function statRow(labelText, key)
    local item = append(statsCard, row(nil, labelText, "", 0, 24))
    local value = textLabel(item, "-", CARD_INNER - 160, 3, 160, 18, 11, TEXT, true, false)
    value.TextXAlignment = Enum.TextXAlignment.Right
    statValues[key] = value
end
statRow("Policy loads", "loads")
statRow("Policy decisions", "decisions")
statRow("Last compute", "compute")
statRow("Last latency", "latency")
statRow("Hooks installed", "hooks")
statRow("Session uptime", "uptime")
buttonRow(statsCard, "Reset counters", "Clear the session values without touching settings.", "RESET", function()
    if bot.resetStats then bot.resetStats() end
    notify("Session counters reset.")
end, CARD2)

-- ============================================================ about
local about = addTab("About", "About")
ui.pageSubtitle.Text = "Build details and diagnostics."
local aboutCard = section(about, "Build")
ui.about = {}
local function aboutRow(labelText, key)
    local item = append(aboutCard, row(nil, labelText, "", 0, 24))
    local value = textLabel(item, "-", CARD_INNER - 220, 3, 220, 18, 10, TEXT, true, false)
    value.TextXAlignment = Enum.TextXAlignment.Right
    ui.about[key] = value
end
aboutRow("Game", "game")
aboutRow("Version", "version")
aboutRow("Model", "model")
aboutRow("Core", "core")
ui.about.version.Text = "v" .. VERSION
ui.about.core.Text = "v0.2.1"
local actionCard = section(about, "Diagnostics")
buttonRow(actionCard, "Copy diagnostics", "Copy a short runtime report.", "COPY", copyDiagnostics)
buttonRow(actionCard, "Copy loadstring", "Copy the injection line.", "COPY", copyLoadstring)
buttonRow(actionCard, "Reload script", "Re-download and re-inject this build.", "RELOAD", reloadScript)
buttonRow(actionCard, "Unload", "Remove the menu and stop the bot.", "UNLOAD", unloadScript, RED)

-- ============================================================ finalization
syncUiFromSettings = function()
    for key, setter in pairs(ui.setters) do
        if settings[key] ~= nil then
            pcall(setter, settings[key])
        end
    end
    if ui.scale then ui.scale.Scale = settings.menuScale end
    updateHints()
end
ui.syncUiFromSettings = syncUiFromSettings

updateHints = function()
    ui.footerHint.Text = tostring(settings.bindMenu) .. "  menu"
    ui.dashDetails.Text = detectedGame()
        .. "  -  session " .. uptime()
        .. "  -  " .. tostring(settings.bindToggle) .. " toggle"
        .. "  /  " .. tostring(settings.bindPanic) .. " panic"
    if ui.about then
        ui.about.game.Text = detectedGame()
        ui.about.model.Text = tostring(bot.modelStatus or "Loading...")
    end
end
ui.updateHints = updateHints

selectTab(1)
syncUiFromSettings()
refreshConfigs()
ui.dashboardSet(enabled)
updateHints()
setMenu(true)
status("Ready - press " .. tostring(settings.bindMenu) .. " to hide the menu")
notify("Experimental v" .. VERSION .. " loaded.", 3)

bot.toggleMenu = function()
    setMenu(not gui.Enabled)
end

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
                nextTick=frame.tick+8
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
-- ============================================================ telemetry
bot.stats = { loads = 0 }
bot.modelStatus = "Loading..."
bot.statsSummary = "Standby"

local wasReady = false
local lastUi = 0
local lastHints = 0

local function refreshTyping()
    local focused = UIS:GetFocusedTextBox() ~= nil
    local nextTyping = settings.pauseOnType and focused or false
    if nextTyping == typing then
        return
    end
    typing = nextTyping
    if enabled then
        if typing then
            status("ON - Paused (typing)")
        elseif ready then
            status("ON - Playing")
        else
            status("ON - Waiting for live match")
        end
    end
end

bot.resetStats = function()
    bot.stats.loads = 0
    decisions = 0
    computeMs = 0
    latencyMs = 0
end

bot.diagnostics = function()
    return table.concat({
        "Experimental v" .. VERSION .. " (" .. detectedGame() .. ")",
        "enabled=" .. tostring(enabled)
            .. " ready=" .. tostring(ready)
            .. " typing=" .. tostring(typing)
            .. " blocked=" .. tostring(blocked),
        "state=" .. tostring(matchWaiting),
        "decisions=" .. tostring(decisions)
            .. " compute=" .. string.format("%.1fms", computeMs or 0)
            .. " latency=" .. string.format("%.1fms", latencyMs or 0),
        "uptime=" .. uptime()
            .. " connections=" .. tostring(#connections)
            .. " hooks=" .. tostring(#hooked),
    }, "\n")
end

connect(RunService.Heartbeat, function()
    if not alive then
        return
    end
    local now = os.clock()
    if now - lastUi < 0.25 then
        return
    end
    lastUi = now

    refreshTyping()

    if ready and not wasReady then
        bot.stats.loads += 1
    end
    wasReady = ready

    if statValues.loads then statValues.loads.Text = tostring(bot.stats.loads) end
    if statValues.decisions then statValues.decisions.Text = tostring(decisions) end
    if statValues.compute then statValues.compute.Text = string.format("%.1f ms", computeMs or 0) end
    if statValues.latency then statValues.latency.Text = string.format("%.1f ms", latencyMs or 0) end
    if statValues.hooks then statValues.hooks.Text = tostring(#hooked) end
    if statValues.uptime then statValues.uptime.Text = uptime() end

    bot.modelStatus = ready and "Ready" or (blocked and "Blocked" or "Loading...")
    bot.statsSummary = string.format("%d decisions - %.1f ms compute", decisions or 0, computeMs or 0)

    if ui.sessionUptime then
        ui.sessionUptime.Text = "Uptime: " .. uptime()
    end
    if ui.about and ui.about.model then
        ui.about.model.Text = tostring(bot.modelStatus)
    end

    if ui.dashStatus then
        if enabled then
            if typing then
                ui.dashStatus.Text = "PAUSED (typing)"
                ui.dashStatus.TextColor3 = Color3.fromRGB(251, 191, 36)
            else
                ui.dashStatus.Text = ready and "ENABLED" or "ENABLED - WAITING FOR MODEL"
                ui.dashStatus.TextColor3 = Color3.fromRGB(74, 222, 128)
            end
        else
            ui.dashStatus.Text = "DISABLED"
            ui.dashStatus.TextColor3 = Color3.fromRGB(139, 143, 165)
        end
    end

    if ui.footerStatus then
        if toastText ~= "" and now < toastUntil then
            ui.footerStatus.Text = toastText
        elseif ui.footerStatus.Text ~= message then
            ui.footerStatus.Text = message
        end
    end

    if now - lastHints >= 1 then
        lastHints = now
        updateHints()
    end
end)

connect(UIS.InputBegan, function(input, processed)
    if capturing then
        local key = keyName(input)
        if key then
            if key == "Escape" then
                cancelCapture()
            else
                finishCapture(key)
            end
        end
        return
    end
    if processed then
        return
    end
    local key = keyName(input)
    if not key then
        return
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
