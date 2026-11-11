--!native
--!optimize 2
-- Experimental v3.0.0 -- Starlight Interface Suite edition.
-- Games: Blox League, Turbo Soccer.
--
-- The policy, model loader and hook layer below are the v0.2.1 core, unchanged.
-- Everything around them is new: Starlight interface, saved configs, keybinds,
-- live HUD, session telemetry, diagnostics and a reload/unload flow.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G

if type(env.ExperimentalBotUnload) == "function" then pcall(env.ExperimentalBotUnload) end

local VERSION = "3.0.0"
local SCRIPT_URL = "https://raw.githubusercontent.com/filbygblh/Scruipt/refs/heads/main/experimental.lua"
local STARLIGHT_URLS = {
    "https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua",
    "https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/main/Source.lua",
}

local alive, enabled, ready = false, false, false
alive = true
local connections = {}
local message = "Starting up..."
local typing = false
local reset      -- assigned by the bot core
local bot = {}   -- late-bound bridge between the interface and the core
local startedAt = os.clock()

local settings = {
    notifications = true,
    autoEnable = false,
    pauseOnType = true,
    showHud = true,
    hudLayout = "Detailed",
    hudScale = 100,
}

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function status(value)
    message = tostring(value)
end

local notify = function() end
local syncGuard = false
local booting = true

local function setEnabled(value, silent)
    value = value and true or false
    enabled = value
    if reset then
        reset()
        if value then
            status(ready and "ON - Waiting for live match" or "ON - Loading model")
        else
            status("OFF - Ready")
        end
    end
    if bot.setToggle then
        syncGuard = true
        pcall(bot.setToggle, value)
        syncGuard = false
    end
    if not silent and not booting then
        notify(
            value and "Auto-play enabled" or "Auto-play disabled",
            value and "The policy is driving your car." or "You have manual control again."
        )
    end
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

-- ============================================================ palette / HUD
local PURPLE = Color3.fromRGB(151, 111, 255)
local BG = Color3.fromRGB(17, 19, 27)
local TEXT = Color3.fromRGB(239, 237, 255)
local MUTED = Color3.fromRGB(139, 143, 165)
local GREEN = Color3.fromRGB(74, 222, 128)
local AMBER = Color3.fromRGB(251, 191, 36)

local gui = Instance.new("ScreenGui")
gui.Name = "ExperimentalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 90
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(24, 190)
panel.Size = UDim2.fromOffset(326, 172)
panel.BackgroundColor3 = BG
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(91, 76, 145)
panelStroke.Thickness = 1.2
panelStroke.Transparency = 0.25
panelStroke.Parent = panel

local hudScaleObj = Instance.new("UIScale")
hudScaleObj.Scale = 1
hudScaleObj.Parent = panel

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.Size = UDim2.new(1, -28, 0, 3)
accent.Position = UDim2.fromOffset(14, 0)
accent.BackgroundColor3 = PURPLE
accent.BorderSizePixel = 0
accent.Parent = panel
local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(1, 0)
accentCorner.Parent = accent

local function hudLabel(parent, text, x, y, w, h, size, color, bold)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position = UDim2.fromOffset(x, y)
    item.Size = UDim2.fromOffset(w, h)
    item.Text = text
    item.TextSize = size
    item.TextColor3 = color
    item.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Top
    item.Parent = parent
    return item
end

local header = hudLabel(panel, "EXPERIMENTAL", 14, 10, 190, 22, 14, TEXT, true)
header.Name = "Drag"
header.Active = true
header.Size = UDim2.new(1, -124, 0, 22)
header.TextYAlignment = Enum.TextYAlignment.Center

local versionLabel = hudLabel(panel, "v" .. VERSION, 0, 12, 80, 16, 10, MUTED, false)
versionLabel.Position = UDim2.new(1, -94, 0, 12)
versionLabel.TextXAlignment = Enum.TextXAlignment.Right

local hudDot = Instance.new("Frame")
hudDot.Name = "StateDot"
hudDot.Size = UDim2.fromOffset(7, 7)
hudDot.Position = UDim2.fromOffset(14, 40)
hudDot.BackgroundColor3 = MUTED
hudDot.BorderSizePixel = 0
hudDot.Parent = panel
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = hudDot

local hudState = hudLabel(panel, "IDLE", 27, 35, 90, 16, 10, MUTED, true)

local hudStatus = hudLabel(panel, "Starting up...", 14, 52, 298, 32, 11, Color3.fromRGB(181, 184, 204), false)
hudStatus.TextWrapped = true

local statsFrame = Instance.new("Frame")
statsFrame.Name = "Stats"
statsFrame.BackgroundTransparency = 1
statsFrame.Position = UDim2.fromOffset(14, 92)
statsFrame.Size = UDim2.fromOffset(298, 38)
statsFrame.Parent = panel

local statCaptions = { "FPS", "DECISIONS", "INFERENCE", "LATENCY" }
local statValues = {}
for i = 1, 4 do
    local x = (i - 1) * 74
    hudLabel(statsFrame, statCaptions[i], x, 0, 70, 11, 9, MUTED, false)
    statValues[i] = hudLabel(statsFrame, "0", x, 13, 70, 20, 15, TEXT, true)
end
local hudFps, hudDec, hudInf, hudLat = statValues[1], statValues[2], statValues[3], statValues[4]

local hudGame = hudLabel(panel, detectedGame(), 14, 144, 170, 16, 10, MUTED, false)

local function hudButton(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(52, 20)
    b.Position = UDim2.new(1, x, 1, -32)
    b.BackgroundColor3 = Color3.fromRGB(53, 47, 76)
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = TEXT
    b.Parent = panel
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b
    return b
end

local hudMenuHint = hudLabel(panel, "K MENU", 0, 0, 52, 20, 9, MUTED, false)
hudMenuHint.Position = UDim2.new(1, -166, 1, -32)
hudMenuHint.Size = UDim2.fromOffset(96, 20)
hudMenuHint.TextXAlignment = Enum.TextXAlignment.Right
hudMenuHint.TextYAlignment = Enum.TextYAlignment.Center
local botButton = hudButton("BOT", -64)

local function applyHud()
    local compact = settings.hudLayout == "Compact"
    panel.Size = UDim2.fromOffset(compact and 270 or 326, compact and 104 or 172)
    panel.Visible = settings.showHud
    statsFrame.Visible = not compact
    hudStatus.Size = UDim2.fromOffset(compact and 246 or 298, compact and 16 or 32)
    hudStatus.TextWrapped = not compact
    hudStatus.TextTruncate = compact and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
    hudGame.Position = UDim2.new(0, 14, 1, compact and -26 or -28)
    hudGame.Size = UDim2.fromOffset(compact and 88 or 140, 16)
    hudScaleObj.Scale = math.clamp(settings.hudScale, 60, 160) / 100
end

local function resetHud()
    panel.Position = UDim2.fromOffset(24, 190)
end

local function placeHud(x, y)
    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        x = math.clamp(x, 0, math.max(0, viewport.X - panel.AbsoluteSize.X))
        y = math.clamp(y, 0, math.max(0, viewport.Y - panel.AbsoluteSize.Y))
    end
    panel.Position = UDim2.fromOffset(x, y)
end

local drag
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = {
            input = input,
            start = input.Position,
            position = panel.AbsolutePosition,
            touch = input.UserInputType == Enum.UserInputType.Touch,
        }
    end
end)
connect(UIS.InputChanged, function(input)
    if not drag then
        return
    end
    if drag.touch and input == drag.input then
        local delta = input.Position - drag.start
        placeHud(drag.position.X + delta.X, drag.position.Y + delta.Y)
    elseif not drag.touch and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - drag.start
        placeHud(drag.position.X + delta.X, drag.position.Y + delta.Y)
    end
end)
connect(UIS.InputEnded, function(input)
    if not drag then
        return
    end
    if input == drag.input or (not drag.touch and input.UserInputType == Enum.UserInputType.MouseButton1) then
        drag = nil
    end
end)

connect(botButton.Activated, function()
    setEnabled(not enabled)
end)

applyHud()

-- ============================================================ Starlight load
local Starlight
do
    for _, url in ipairs(STARLIGHT_URLS) do
        local fetched, source = pcall(function()
            return game:HttpGet(url)
        end)
        if fetched and type(source) == "string" and #source > 1000 then
            local compiled, chunk = pcall(loadstring, source)
            if compiled and type(chunk) == "function" then
                local loaded, library = pcall(chunk)
                if loaded and type(library) == "table" then
                    Starlight = library
                    break
                end
            end
        end
    end
    if not Starlight then
        warn("[Experimental] Starlight Interface Suite could not be loaded. HUD and hotkeys remain active.")
    end
end

-- ============================================================ default binds
local enableBind, panicBind, menuBind
local statusPara, statsPara, modelPara

if Starlight then
    local okWindow, win = pcall(function()
        return Starlight:CreateWindow({
            Name = "EXPERIMENTAL",
            Subtitle = "Blox League / Turbo Soccer  -  v" .. VERSION,
            LoadingEnabled = false,
            BuildWarnings = false,
            InterfaceAdvertisingPrompts = false,
            NotifyOnCallbackError = true,
            DefaultSize = UDim2.fromOffset(640, 430),
            FileSettings = {
                RootFolder = "Vunilow",
                ConfigFolder = "Experimental",
                ThemeFolder = "Themes",
            },
        })
    end)

    if not okWindow or not win then
        warn("[Experimental] Starlight window failed: " .. tostring(win))
        Starlight = nil
    end

    if Starlight then
        local okUi, uiError = pcall(function()
        notify = function(title, content)
            if not settings.notifications then
                return
            end
            pcall(function()
                Starlight:Notification({
                    Title = title,
                    Content = content,
                    Duration = 4,
                })
            end)
        end

        local mainSection = win:CreateTabSection("MAIN")
        local dash = mainSection:CreateTab({ Name = "Dashboard", Columns = 2 }, "dashboard")
        local session = dash:CreateGroupbox({ Name = "Session", Column = 1 }, "session")

        local enableToggle = session:CreateToggle({
            Name = "Auto-play bot",
            CurrentValue = false,
            Style = 2,
            Tooltip = "Runs the trained policy in supported matches",
            Callback = function(value)
                if syncGuard then
                    return
                end
                setEnabled(value)
            end,
        }, "enable")

        session:CreateButton({
            Name = "Reset session",
            Style = 2,
            Tooltip = "Clears the current policy buffer without disabling the bot",
            Callback = function()
                if reset then
                    reset()
                end
                notify("Session", "Policy buffer and action history cleared.")
            end,
        }, "reset")

        statusPara = session:CreateParagraph({
            Name = "Status",
            Content = "Starting up...",
        }, "status")

        local diagnostics = dash:CreateGroupbox({ Name = "Diagnostics", Column = 2 }, "diagnostics")
        modelPara = diagnostics:CreateParagraph({
            Name = "Runtime",
            Content = "Model loading...",
        }, "runtime")

        diagnostics:CreateButton({
            Name = "Copy diagnostics",
            Style = 2,
            Callback = function()
                if not bot.diagnostics then
                    return
                end
                local text = bot.diagnostics()
                if type(setclipboard) == "function" then
                    setclipboard(text)
                    notify("Diagnostics", "Session report copied to the clipboard.")
                else
                    warn(text)
                end
            end,
        }, "copy")

        diagnostics:CreateButton({
            Name = "Reload script",
            Style = 2,
            Callback = reloadScript,
        }, "reload")

        diagnostics:CreateButton({
            Name = "Unload",
            Style = 1,
            Callback = function()
                if type(env.ExperimentalBotUnload) == "function" then
                    env.ExperimentalBotUnload()
                end
            end,
        }, "unload")

        local automation = mainSection:CreateTab({ Name = "Automation", Columns = 2 }, "automation")
        local behaviour = automation:CreateGroupbox({ Name = "Behaviour", Column = 1 }, "behaviour")

        behaviour:CreateToggle({
            Name = "Auto-enable when ready",
            CurrentValue = false,
            Style = 2,
            Tooltip = "Starts the bot once the model finishes loading",
            Callback = function(value)
                settings.autoEnable = value
                if value and bot.armAutoEnable then
                    bot.armAutoEnable()
                end
            end,
        }, "auto_enable")

        behaviour:CreateToggle({
            Name = "Pause while typing",
            CurrentValue = true,
            Style = 2,
            Tooltip = "Stops control output while a text box is focused",
            Callback = function(value)
                settings.pauseOnType = value
                typing = false
            end,
        }, "pause_typing")

        local hudGroup = automation:CreateGroupbox({ Name = "HUD", Column = 2 }, "hud_group")

        hudGroup:CreateToggle({
            Name = "Show HUD",
            CurrentValue = true,
            Style = 2,
            Callback = function(value)
                settings.showHud = value
                applyHud()
            end,
        }, "hud_visible")

        hudGroup:CreateDropdown({
            Name = "HUD layout",
            Options = { "Detailed", "Compact" },
            CurrentOption = { "Detailed" },
            Callback = function(selection)
                local value = type(selection) == "table" and selection[1] or selection
                if value then
                    settings.hudLayout = value
                    applyHud()
                end
            end,
        }, "hud_layout")

        hudGroup:CreateSlider({
            Name = "HUD scale",
            Range = { 80, 140 },
            CurrentValue = 100,
            Increment = 5,
            Suffix = "%",
            Callback = function(value)
                settings.hudScale = value
                applyHud()
            end,
        }, "hud_scale")

        hudGroup:CreateButton({
            Name = "Reset HUD position",
            Style = 2,
            Callback = function()
                resetHud()
                notify("HUD", "Position reset.")
            end,
        }, "hud_reset")

        local statsTab = mainSection:CreateTab({ Name = "Stats", Columns = 1 }, "stats")
        local telemetry = statsTab:CreateGroupbox({ Name = "Live telemetry", Column = 1 }, "telemetry")

        statsPara = telemetry:CreateParagraph({
            Name = "Session",
            Content = "Waiting for telemetry...",
        }, "stats")

        telemetry:CreateButton({
            Name = "Reset counters",
            Style = 2,
            Callback = function()
                if bot.resetStats then
                    bot.resetStats()
                    notify("Stats", "Counters reset.")
                end
            end,
        }, "stats_reset")

        local settingsTab = mainSection:CreateTab({ Name = "Settings", Columns = 2 }, "settings")
        local keys = settingsTab:CreateGroupbox({ Name = "Keybinds", Column = 1 }, "keys")

        keys:CreateParagraph({
            Name = "How to rebind",
            Content = "Click a key field, then press the new key. Changes apply immediately and are saved with your config.",
        }, "keys_note")

        enableBind = keys:CreateBind({
            Name = "Toggle bot",
            CurrentValue = "F1",
            Callback = function() end,
        }, "bind_enable")

        panicBind = keys:CreateBind({
            Name = "Panic (disable)",
            CurrentValue = "F2",
            Callback = function() end,
        }, "bind_panic")

        menuBind = keys:CreateBind({
            Name = "Menu key",
            CurrentValue = Starlight.WindowKeybind or "K",
            Callback = function() end,
            ChangedCallback = function(key)
                local okKey, keyCode = pcall(function()
                    return Enum.KeyCode[key]
                end)
                if type(key) ~= "string" or not okKey or not keyCode then
                    notify("Keybind", "Pick a keyboard key for the menu.")
                    return
                end
                if enableBind and key == enableBind.Values.CurrentValue then
                    notify("Keybind", "That key already toggles the bot.")
                    return
                end
                if panicBind and key == panicBind.Values.CurrentValue then
                    notify("Keybind", "That key is the panic key.")
                    return
                end
                Starlight.WindowKeybind = key
            end,
        }, "bind_menu")

        local interfaceGroup = settingsTab:CreateGroupbox({ Name = "Interface", Column = 2 }, "interface")

        interfaceGroup:CreateToggle({
            Name = "Notifications",
            CurrentValue = true,
            Style = 2,
            Callback = function(value)
                settings.notifications = value
            end,
        }, "notifications")

        interfaceGroup:CreateParagraph({
            Name = "Window",
            Content = "Use the minimize control in the top bar, or press the menu key shown on the HUD.",
        }, "window_note")

        local lookSection = win:CreateTabSection("INTERFACE")
        local themes = lookSection:CreateTab({ Name = "Themes", Columns = 1 }, "themes")
        themes:BuildThemeGroupbox(1)

        local configs = lookSection:CreateTab({ Name = "Configs", Columns = 1 }, "configs")
        configs:BuildConfigGroupbox(1)

        local helpSection = win:CreateTabSection("ABOUT")
        local about = helpSection:CreateTab({ Name = "Information", Columns = 1 }, "about")
        local aboutGroup = about:CreateGroupbox({ Name = "Experimental " .. VERSION, Column = 1 }, "about_group")

        aboutGroup:CreateParagraph({
            Name = "What this is",
            Content = "Neural auto-play for Blox League and Turbo Soccer. The policy is a 10-layer MLP with 90 actions and a 10.45 MB weight set.",
        }, "about_text")

        aboutGroup:CreateParagraph({
            Name = "Hotkeys",
            Content = "F1  toggle bot\nF2  panic disable\nK   open / hide menu (default)",
        }, "about_keys")

        aboutGroup:CreateButton({
            Name = "Reload script",
            Style = 2,
            Callback = reloadScript,
        }, "about_reload")

        aboutGroup:CreateParagraph({
            Name = "Note",
            Content = "Automation can violate a game's rules. Use on accounts you are willing to risk.",
        }, "about_note")

        bot.setToggle = function(value)
            if enableToggle then
                enableToggle:Set({ CurrentValue = value })
            end
        end

        pcall(function()
            Starlight:LoadAutoloadConfig()
        end)

        if menuBind and menuBind.Values and type(menuBind.Values.CurrentValue) == "string" then
            local okKey, keyCode = pcall(function()
                return Enum.KeyCode[menuBind.Values.CurrentValue]
            end)
            if okKey and keyCode then
                Starlight.WindowKeybind = menuBind.Values.CurrentValue
            end
        end

        notify("Experimental " .. VERSION, "Interface loaded. Model is downloading in the background.")
        end)
        if not okUi then
            warn("[Experimental] Interface build failed: " .. tostring(uiError))
            pcall(function()
                Starlight:Destroy()
            end)
            Starlight = nil
        end
    end
else
    notify = function() end
    status("Starlight unavailable - HUD and default binds are active")
end

booting = false

-- ============================================================ keybinds
local function keyName(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        return "MB1"
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        return "MB2"
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local name = tostring(input.KeyCode)
        return name:match("KeyCode%.(.+)$") or name
    end
    return nil
end

local function bindValue(bind, fallback)
    if bind and bind.Values and type(bind.Values.CurrentValue) == "string" then
        return bind.Values.CurrentValue
    end
    return fallback
end

connect(UIS.InputBegan, function(input, processed)
    if processed then
        return
    end
    local key = keyName(input)
    if not key then
        return
    end
    if key == bindValue(enableBind, "F1") then
        setEnabled(not enabled)
    elseif key == bindValue(panicBind, "F2") then
        setEnabled(false)
    end
end)
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
    if Starlight and Starlight.Instance then pcall(function() Starlight:Destroy() end) end
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
-- ============================================================ telemetry / HUD
local autoEnabled = false
local readyAnnounced = false
local lastUi = 0
local lastParagraph = 0
local fpsSmooth = 1 / 60

bot.resetStats = function()
    decisions = 0
    computeMs = 0
    latencyMs = 0
end

bot.armAutoEnable = function()
    autoEnabled = false
end

bot.diagnostics = function()
    local executor = "unknown"
    local okName, name = pcall(function()
        if type(identifyexecutor) == "function" then
            return identifyexecutor()
        end
        return "unknown"
    end)
    if okName and type(name) == "string" then
        executor = name
    end
    return table.concat({
        "Experimental " .. VERSION,
        "Game: " .. detectedGame() .. " (" .. tostring(game.PlaceId) .. ")",
        "Enabled: " .. tostring(enabled),
        "Model ready: " .. tostring(ready),
        "Status: " .. tostring(message),
        "Decisions: " .. tostring(decisions),
        "Inference: " .. string.format("%.2f ms", computeMs),
        "Latency: " .. string.format("%.1f ms", latencyMs),
        "Uptime: " .. uptime(),
        "HUD: " .. settings.hudLayout .. " @ " .. tostring(settings.hudScale) .. "%",
        "Pause on type: " .. tostring(settings.pauseOnType),
        "Executor: " .. executor,
    }, "\n")
end

local function setHudState(text, color)
    hudState.Text = text
    hudState.TextColor3 = color
    hudDot.BackgroundColor3 = color
end

connect(RunService.Heartbeat, function(dt)
    typing = settings.pauseOnType and (UIS:GetFocusedTextBox() ~= nil) or false
    if not alive then
        return
    end

    fpsSmooth = fpsSmooth * 0.92 + math.min(dt, 0.1) * 0.08

    if settings.autoEnable and ready and not autoEnabled then
        autoEnabled = true
        if not enabled then
            setEnabled(true, true)
            notify("Auto-play", "Model ready - bot enabled automatically.")
        end
    end

    if ready and not readyAnnounced then
        readyAnnounced = true
        notify("Model ready", "The policy is loaded. Join a supported match to start.")
    end

    local now = os.clock()
    if now - lastUi < 0.15 then
        return
    end
    lastUi = now

    local fps = math.floor(1 / math.max(fpsSmooth, 0.0001) + 0.5)
    local statusText = message
    if typing and enabled then
        statusText = "PAUSED - text box focused"
    end
    hudStatus.Text = statusText

    hudFps.Text = tostring(fps)
    hudDec.Text = tostring(decisions)
    hudInf.Text = string.format("%.1f", computeMs)
    hudLat.Text = string.format("%.0f", latencyMs)
    hudGame.Text = detectedGame()
    hudMenuHint.Text = tostring((Starlight and Starlight.WindowKeybind) or "K") .. " MENU"

    if not enabled then
        setHudState("IDLE", MUTED)
    elseif typing then
        setHudState("PAUSED", AMBER)
    elseif blocked then
        setHudState("PAUSED", AMBER)
    elseif ready then
        setHudState("LIVE", GREEN)
    else
        setHudState("LOADING", AMBER)
    end

    if now - lastParagraph < 0.5 then
        return
    end
    lastParagraph = now

    local paragraphStatus = message
    if typing and enabled then
        paragraphStatus = "PAUSED - text box focused"
    end

    if statusPara then
        pcall(function()
            statusPara:Set({ Content = paragraphStatus })
        end)
    end

    if statsPara then
        pcall(function()
            statsPara:Set({
                Content = string.format(
                    "Status      %s\nEnabled     %s\nFPS         %d\nDecisions   %d\nInference   %.2f ms\nLatency     %.1f ms\nUptime      %s",
                    paragraphStatus,
                    enabled and "yes" or "no",
                    fps,
                    decisions,
                    computeMs,
                    latencyMs,
                    uptime()
                ),
            })
        end)
    end

    if modelPara then
        local pauseReason = "no"
        if typing and enabled then
            pauseReason = "yes (typing)"
        elseif blocked then
            pauseReason = "yes (game)"
        end
        pcall(function()
            modelPara:Set({
                Content = string.format(
                    "Game        %s\nPlaceId     %d\nModel       %s\nPolicy      10-layer MLP / 90 actions\nPaused      %s\nGame mode   %s",
                    detectedGame(),
                    game.PlaceId,
                    ready and "ready - 10.45 MB" or "loading...",
                    pauseReason,
                    enabled and "auto-play" or "manual"
                ),
            })
        end)
    end
end)
