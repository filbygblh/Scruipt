--!native
--!optimize 2
-- Experimental v3.2.0 -- compact widget edition.
-- Blox League / Turbo Soccer.
-- The policy core is the v0.2.1 model/hook layer with the typing guard.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G

if type(env.ExperimentalBotUnload) == "function" then pcall(env.ExperimentalBotUnload) end

local VERSION = "3.2.0"
local SCRIPT_URL = "https://raw.githubusercontent.com/filbygblh/Scruipt/refs/heads/main/experimental.lua"
local FOLDER = "Vunilow/Experimental"
local SETTINGS_PATH = FOLDER .. "/widget.json"

local alive, enabled, ready = false, false, false
alive = true
local connections = {}
local message = "Starting up..."
local typing = false
local reset
local startedAt = os.clock()
local bot = {}
local ui = { bindButtons = {} }
local capturing
local gui
local setEnabled
local beginCapture
local cancelCapture

local settings = {
    pauseOnType = true,
    bindMenu = "Insert",
    bindToggle = "F1",
    bindPanic = "F2",
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

local function loadSettings()
    if not hasFileApi() then
        return
    end
    local okFile, exists = pcall(isfile, SETTINGS_PATH)
    if not okFile or not exists then
        return
    end
    local okRead, content = pcall(readfile, SETTINGS_PATH)
    if not okRead or type(content) ~= "string" then
        return
    end
    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not okDecode or type(data) ~= "table" then
        return
    end
    if type(data.pauseOnType) == "boolean" then settings.pauseOnType = data.pauseOnType end
    if type(data.bindMenu) == "string" and data.bindMenu ~= "" then settings.bindMenu = data.bindMenu end
    if type(data.bindToggle) == "string" and data.bindToggle ~= "" then settings.bindToggle = data.bindToggle end
    if type(data.bindPanic) == "string" and data.bindPanic ~= "" then settings.bindPanic = data.bindPanic end
end

local function saveSettings()
    if not hasFileApi() then
        return
    end
    ensureFolder("Vunilow")
    ensureFolder(FOLDER)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode({
            pauseOnType = settings.pauseOnType,
            bindMenu = settings.bindMenu,
            bindToggle = settings.bindToggle,
            bindPanic = settings.bindPanic,
        })
    end)
    if ok then
        pcall(writefile, SETTINGS_PATH, encoded)
    end
end

loadSettings()

local BG = Color3.fromRGB(15, 17, 24)
local PANEL = Color3.fromRGB(22, 25, 36)
local CARD = Color3.fromRGB(30, 34, 48)
local STROKE = Color3.fromRGB(60, 54, 90)
local ACCENT = Color3.fromRGB(151, 111, 255)
local TEXT = Color3.fromRGB(240, 238, 255)
local MUTED = Color3.fromRGB(142, 146, 170)
local GREEN = Color3.fromRGB(74, 222, 128)
local AMBER = Color3.fromRGB(251, 191, 36)
local BLUE = Color3.fromRGB(96, 165, 250)
local RED = Color3.fromRGB(190, 70, 90)

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

local function label(parent, text, x, y, width, height, size, color, bold, wrap)
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
    item.Parent = parent
    return item
end

gui = new("ScreenGui", {
    Name = "ExperimentalWidget",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 80,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Enabled = true,
})
gui.Parent = LP:WaitForChild("PlayerGui")

local widget = new("Frame", {
    Name = "Widget",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(330, 244),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
})
widget.Parent = gui
corner(widget, 14)
local outline = new("UIStroke", { Color = STROKE, Transparency = 0.25, Thickness = 1 })
outline.Parent = widget

local accent = new("Frame", {
    Size = UDim2.fromOffset(302, 2),
    Position = UDim2.fromOffset(14, 0),
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
})
accent.Parent = widget
corner(accent, 1)

local header = new("Frame", {
    Size = UDim2.fromOffset(330, 48),
    BackgroundTransparency = 1,
    Active = true,
})
header.Parent = widget
label(header, "EXPERIMENTAL", 14, 12, 180, 18, 12, TEXT, true, false)
label(header, "widget  //  v" .. VERSION, 14, 29, 180, 12, 8, MUTED, false, false)
local autoChip = new("TextLabel", {
    Position = UDim2.fromOffset(236, 16),
    Size = UDim2.fromOffset(38, 16),
    BackgroundColor3 = Color3.fromRGB(64, 52, 96),
    Text = "AUTO",
    TextSize = 7,
    Font = Enum.Font.GothamBold,
    TextColor3 = ACCENT,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
})
autoChip.Parent = header
corner(autoChip, 5)

local hideButton = new("TextButton", {
    Position = UDim2.fromOffset(284, 12),
    Size = UDim2.fromOffset(32, 24),
    BackgroundColor3 = CARD,
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = MUTED,
    AutoButtonColor = false,
})
hideButton.Parent = header
corner(hideButton, 7)

local statusCard = new("Frame", {
    Position = UDim2.fromOffset(14, 54),
    Size = UDim2.fromOffset(302, 54),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
})
statusCard.Parent = widget
corner(statusCard, 9)

ui.dot = new("Frame", {
    Position = UDim2.fromOffset(12, 12),
    Size = UDim2.fromOffset(8, 8),
    BackgroundColor3 = MUTED,
    BorderSizePixel = 0,
})
ui.dot.Parent = statusCard
corner(ui.dot, 4)
ui.status = label(statusCard, "STANDBY", 28, 7, 250, 18, 12, TEXT, true, false)
ui.details = label(statusCard, "Waiting for startup.", 28, 26, 262, 22, 8, MUTED, false, true)

local control = new("TextButton", {
    Position = UDim2.fromOffset(14, 116),
    Size = UDim2.fromOffset(302, 34),
    BackgroundColor3 = ACCENT,
    Text = "START BOT",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    AutoButtonColor = false,
})
control.Parent = widget
corner(control, 8)
ui.control = control
control.Activated:Connect(function()
    setEnabled(not enabled)
end)

local bindCard = new("Frame", {
    Position = UDim2.fromOffset(14, 158),
    Size = UDim2.fromOffset(302, 58),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
})
bindCard.Parent = widget
corner(bindCard, 9)

label(bindCard, "Menu key", 12, 8, 140, 14, 8, MUTED, true, false)
label(bindCard, "Bot key", 12, 32, 140, 14, 8, MUTED, true, false)

local function bindButton(kind, y)
    local button = new("TextButton", {
        Position = UDim2.fromOffset(204, y),
        Size = UDim2.fromOffset(84, 22),
        BackgroundColor3 = CARD,
        Text = tostring(settings[kind] or "?"),
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = TEXT,
        AutoButtonColor = false,
    })
    button.Parent = bindCard
    corner(button, 6)
    button.Activated:Connect(function()
        beginCapture(kind, button)
    end)
    ui.bindButtons[kind] = button
    return button
end

bindButton("bindMenu", 4)
bindButton("bindToggle", 28)

ui.footer = label(widget, "", 14, 222, 302, 14, 8, MUTED, false, false)

local function updateHint()
    ui.footer.Text = tostring(settings.bindMenu) .. " hide  |  " .. tostring(settings.bindToggle) .. " toggle"
    if ui.bindButtons.bindMenu then ui.bindButtons.bindMenu.Text = tostring(settings.bindMenu) end
    if ui.bindButtons.bindToggle then ui.bindButtons.bindToggle.Text = tostring(settings.bindToggle) end
end

local function setMenu(open)
    gui.Enabled = open and true or false
    if not gui.Enabled and cancelCapture then
        cancelCapture()
    end
end
ui.setMenu = setMenu

hideButton.Activated:Connect(function()
    setMenu(false)
end)

beginCapture = function(kind, button)
    if capturing and capturing.button then
        capturing.button.Text = tostring(settings[capturing.kind] or "?")
        capturing.button.TextColor3 = TEXT
    end
    capturing = { kind = kind, button = button }
    button.Text = "Press a key..."
    button.TextColor3 = ACCENT
end
ui.beginCapture = beginCapture

cancelCapture = function()
    if capturing then
        capturing.button.Text = tostring(settings[capturing.kind] or "?")
        capturing.button.TextColor3 = TEXT
        capturing = nil
    end
end
ui.cancelCapture = cancelCapture

local function keyName(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return nil
    end
    local name = tostring(input.KeyCode)
    return name:match("KeyCode%.(.+)$") or name
end

local function finishCapture(key)
    if not capturing then
        return
    end
    local kind = capturing.kind
    local button = capturing.button
    capturing = nil
    button.TextColor3 = TEXT
    if key == "Escape" then
        button.Text = tostring(settings[kind] or "?")
        return
    end
    for _, other in ipairs({ "bindMenu", "bindToggle", "bindPanic" }) do
        if other ~= kind and settings[other] == key then
            button.Text = tostring(settings[kind] or "?")
            status("That key is already in use.")
            return
        end
    end
    settings[kind] = key
    button.Text = key
    saveSettings()
    updateHint()
    status("Bound " .. (kind == "bindMenu" and "menu" or kind == "bindToggle" and "bot toggle" or "panic") .. " to " .. key .. ".")
end
ui.finishCapture = finishCapture

setEnabled = function(value, silent)
    value = value and true or false
    enabled = value
    if reset then
        reset()
        status(value and (ready and "ON - Waiting for live match" or "ON - Loading model") or "OFF - Ready")
    end
    control.Text = value and "STOP BOT" or "START BOT"
    control.BackgroundColor3 = value and RED or ACCENT
end
ui.setEnabled = setEnabled

updateHint()

local drag
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = { input = input, start = input.Position, position = widget.AbsolutePosition, touch = input.UserInputType == Enum.UserInputType.Touch }
    end
end)
connect(UIS.InputChanged, function(input)
    if not drag then return end
    local moving = (drag.touch and input == drag.input) or (not drag.touch and input.UserInputType == Enum.UserInputType.MouseMovement)
    if not moving then return end
    local delta = input.Position - drag.start
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local size = widget.AbsoluteSize
    local x = math.clamp(drag.position.X + delta.X, 0, math.max(0, viewport.X - size.X))
    local y = math.clamp(drag.position.Y + delta.Y, 0, math.max(0, viewport.Y - size.Y))
    widget.Position = UDim2.fromOffset(x + size.X * 0.5, y + size.Y * 0.5)
end)
connect(UIS.InputEnded, function(input)
    if drag and (input == drag.input or (not drag.touch and input.UserInputType == Enum.UserInputType.MouseButton1)) then
        drag = nil
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
-- ============================================================ widget runtime
local lastUi = 0

local function refreshTyping()
    local focused = UIS:GetFocusedTextBox() ~= nil
    local nextTyping = settings.pauseOnType and focused or false
    if nextTyping == typing then
        return
    end
    typing = nextTyping
    if enabled then
        status(typing and "ON - Paused (typing)" or (ready and "ON - Playing" or "ON - Loading model"))
    end
end

local function updateWidget()
    if not ui.status then
        return
    end
    if enabled then
        if typing then
            ui.status.Text = "PAUSED"
            ui.status.TextColor3 = AMBER
            ui.dot.BackgroundColor3 = AMBER
            ui.details.Text = "Typing detected. Inputs are released."
        elseif ready then
            ui.status.Text = "ACTIVE"
            ui.status.TextColor3 = GREEN
            ui.dot.BackgroundColor3 = GREEN
            ui.details.Text = detectedGame() .. "  //  " .. uptime() .. "  //  " .. message
        else
            ui.status.Text = "STARTING"
            ui.status.TextColor3 = BLUE
            ui.dot.BackgroundColor3 = BLUE
            ui.details.Text = "Loading model  //  " .. uptime()
        end
    else
        ui.status.Text = "STANDBY"
        ui.status.TextColor3 = MUTED
        ui.dot.BackgroundColor3 = MUTED
        ui.details.Text = "Stopped  //  " .. tostring(settings.bindToggle) .. " to start"
    end
    if ui.control then
        ui.control.Text = enabled and "STOP BOT" or "START BOT"
        ui.control.BackgroundColor3 = enabled and RED or ACCENT
    end
end

connect(RunService.Heartbeat, function()
    if not alive then
        return
    end
    local now = os.clock()
    if now - lastUi < 0.2 then
        return
    end
    lastUi = now
    refreshTyping()
    updateWidget()
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
        setMenu(not gui.Enabled)
    elseif key == settings.bindToggle then
        setEnabled(not enabled)
    elseif key == settings.bindPanic then
        setEnabled(false)
    end
end)

task.defer(function()
    task.wait(0.4)
    if alive and not enabled then
        setEnabled(true, true)
        status("ON - Auto-start waiting for model")
    end
end)
