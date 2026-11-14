--[[
    VYX UI  |  Premium • Modern • Simple
    Fitur:
      - Window + sidebar tab + minimize jadi pill (kayak di foto)
      - Section, Toggle, Button, Slider(+input angka), Dropdown, Keybind, ColorPicker, TextBox, Label
      - SHORTCUT GUI : klik kanan toggle/button mana aja -> ke-pin di panel shortcut (bisa di-drag)
      - CONFIG       : save / load / delete / autoload (butuh writefile, readfile, listfiles)
      - CUSTOMIZE    : ganti warna Accent / Background / Element / Stroke / Text, UI scale, menu key
]]

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local TS          = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris      = game:GetService("Debris")

if getgenv and getgenv().VYX_UI then pcall(function() getgenv().VYX_UI:Unload() end) end

local Library = {
    Flags = {}, Setters = {}, Pinnable = {}, Pins = {},
    ShowShortcuts = true, Listening = false,
    _conns = {}, _themed = {}, _updaters = {}, _keybinds = {},
}

local DefaultTheme = {
    Accent     = Color3.fromRGB(108, 58, 255),
    Background = Color3.fromRGB(15, 14, 22),
    Element    = Color3.fromRGB(25, 23, 36),
    Stroke     = Color3.fromRGB(52, 46, 84),
    Text       = Color3.fromRGB(255, 255, 255),
    SubText    = Color3.fromRGB(170, 160, 215),
}
Library.DefaultTheme = DefaultTheme
Library.Theme = {}
for k, v in pairs(DefaultTheme) do Library.Theme[k] = v end

local WHITE = Color3.new(1, 1, 1)
local FONT, BOLD, BLACK = Enum.Font.GothamMedium, Enum.Font.GothamBold, Enum.Font.GothamBlack
local X, Y, XY = Enum.AutomaticSize.X, Enum.AutomaticSize.Y, Enum.AutomaticSize.XY

------------------------------------------------------------------ helpers
local function new(class, props)
    local o = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else o[k] = v end
    end
    o.Parent = parent
    return o
end

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Library._conns, c)
    return c
end

local function safe(f, ...)
    if not f then return end
    task.spawn(function(...)
        local ok, err = pcall(f, ...)
        if not ok then warn("[VYX UI]", err) end
    end, ...)
end

local function theme(obj, prop, key)
    obj[prop] = Library.Theme[key]
    table.insert(Library._themed, { obj, prop, key })
    return obj
end

local function addUpdater(f) table.insert(Library._updaters, f) end

function Library:SetTheme(key, color)
    self.Theme[key] = color
    for i = #self._themed, 1, -1 do
        local t = self._themed[i]
        if not t[1]:IsDescendantOf(game) then
            table.remove(self._themed, i)
        elseif t[3] == key then
            t[1][t[2]] = color
        end
    end
    for _, f in ipairs(self._updaters) do pcall(f) end
end

local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = p }) end
local function stroke(p, key, th)
    local s = new("UIStroke", { Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
    theme(s, "Color", key)
    return s
end

local function text(parent, props)
    local key = props.ColorKey or "Text"
    props.ColorKey = nil
    props.BackgroundTransparency = 1
    props.Font = props.Font or FONT
    props.TextSize = props.TextSize or 14
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.Parent = parent
    local l = new("TextLabel", props)
    theme(l, "TextColor3", key)
    return l
end

-- Icon helper: terima rbxassetid://123 / "123" / 123 -> ImageLabel, selain itu -> teks/emoji
local function isAsset(v)
    if type(v) == "number" then return true end
    if type(v) ~= "string" then return false end
    return v:find("^rbxassetid://") ~= nil or v:find("^rbxasset://") ~= nil or v:find("^https?://") ~= nil or v:match("^%d+$") ~= nil
end
local function toAsset(v)
    if type(v) == "number" or tostring(v):match("^%d+$") then return "rbxassetid://" .. tostring(v) end
    return v
end
-- o: Position, Size, Tint (theme key / nil = warna asli gambar), TextTint, TextSize, Font, Default
local function makeIcon(parent, v, o)
    if isAsset(v) then
        local img = new("ImageLabel", { BackgroundTransparency = 1, Image = toAsset(v), ScaleType = Enum.ScaleType.Fit,
            Position = o.Position, Size = o.Size, Parent = parent })
        if o.Tint then theme(img, "ImageColor3", o.Tint) end
        return img
    end
    local s = (v ~= nil and v ~= "") and tostring(v) or o.Default or ""
    return text(parent, { Text = s, Position = o.Position, Size = o.Size, TextSize = o.TextSize or 18, Font = o.Font,
        TextXAlignment = Enum.TextXAlignment.Center, ColorKey = o.TextTint or "Text" })
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function draggable(handle, target)
    local dragging, start, origin
    connect(handle.InputBegan, function(i)
        if isPress(i) then
            dragging, start, origin = true, i.Position, target.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and isMove(i) then
            local d = i.Position - start
            target.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
end

local function getParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    ok, h = pcall(function() return game:GetService("CoreGui") end)
    if ok and h then return h end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function makeRow(parent, h, name)
    local r = new("TextButton", { Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h), Parent = parent })
    theme(r, "BackgroundColor3", "Element"); corner(r, 8); stroke(r, "Stroke", 1)
    local l
    if name then
        l = text(r, { Text = name, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.55, 0, 1, 0), TextSize = 15 })
    end
    return r, l
end

local function wrapper(sec)
    sec._n = (sec._n or 0) + 1
    local w = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1,
        LayoutOrder = sec._n, Parent = sec.Frame })
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = w })
    return w
end

local function nextOrder(sec) sec._n = (sec._n or 0) + 1; return sec._n end

local function pinnable(id, row, data)
    Library.Pinnable[id] = data
    row.MouseButton2Click:Connect(function() Library:TogglePin(id) end)
end

------------------------------------------------------------------ notify / pins
function Library:Notify(msg, dur)
    if not self.NotifyHolder then return end
    local n = new("Frame", { Size = UDim2.new(1, 0, 0, 38), Parent = self.NotifyHolder })
    theme(n, "BackgroundColor3", "Background"); corner(n, 8); stroke(n, "Accent", 1.5)
    text(n, { Text = tostring(msg), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), TextSize = 14 })
    Debris:AddItem(n, dur or 2.5)
end

function Library:RefreshPins()
    local p = self.PinPanel
    if not p then return end
    for _, c in ipairs(p:GetChildren()) do if c:GetAttribute("pin") then c:Destroy() end end
    for i = #self.Pins, 1, -1 do
        if not self.Pinnable[self.Pins[i]] then table.remove(self.Pins, i) end
    end
    for i, id in ipairs(self.Pins) do
        local it = self.Pinnable[id]
        local on = it.Type == "toggle" and it.Get()
        local b = new("TextButton", { Text = it.Name, Size = UDim2.new(1, 0, 0, 30), Font = BOLD, TextSize = 13,
            AutoButtonColor = false, LayoutOrder = i + 1, Parent = p })
        b:SetAttribute("pin", true); corner(b, 7)
        b.BackgroundColor3 = on and self.Theme.Accent or self.Theme.Element
        b.TextColor3 = self.Theme.Text
        b.MouseButton1Click:Connect(function() it.Fire() end)
        b.MouseButton2Click:Connect(function() Library:Unpin(id) end)
    end
    p.Visible = (#self.Pins > 0) and self.ShowShortcuts
end

function Library:Pin(id)
    if self.Pinnable[id] and not table.find(self.Pins, id) then
        table.insert(self.Pins, id); self:RefreshPins()
        self:Notify("📌 Pinned: " .. self.Pinnable[id].Name)
    end
end
function Library:Unpin(id)
    local i = table.find(self.Pins, id)
    if i then table.remove(self.Pins, i); self:RefreshPins() end
end
function Library:TogglePin(id)
    if table.find(self.Pins, id) then self:Unpin(id) else self:Pin(id) end
end

------------------------------------------------------------------ config
local function fsOK()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function"
        and typeof(makefolder) == "function" and typeof(listfiles) == "function" and typeof(isfile) == "function"
end
local function ser(v)
    if typeof(v) == "Color3" then
        return { __color = { math.floor(v.R * 255 + .5), math.floor(v.G * 255 + .5), math.floor(v.B * 255 + .5) } }
    end
    return v
end
local function deser(v)
    if type(v) == "table" and v.__color then return Color3.fromRGB(unpack(v.__color)) end
    return v
end

function Library:_dir()
    local f = self.Window.Folder
    if not isfolder(f) then makefolder(f) end
    if not isfolder(f .. "/configs") then makefolder(f .. "/configs") end
    return f .. "/configs"
end
function Library:ListConfigs()
    if not fsOK() then return {} end
    local out = {}
    for _, p in ipairs(listfiles(self:_dir())) do
        local n = p:match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    return out
end
function Library:SaveConfig(name)
    if not fsOK() then return false, "Executor gak support file system" end
    name = tostring(name or ""):gsub("[^%w_%- ]", "")
    if name == "" then return false, "Nama config kosong" end
    local data = { flags = {}, pins = self.Pins }
    for k, v in pairs(self.Flags) do data.flags[k] = ser(v) end
    writefile(self:_dir() .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    return true, name
end
function Library:LoadConfig(name)
    if not fsOK() then return false, "Executor gak support file system" end
    local path = self:_dir() .. "/" .. tostring(name) .. ".json"
    if not isfile(path) then return false, "Config gak ketemu" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok then return false, "Config rusak" end
    for k, v in pairs(data.flags or {}) do
        local set = self.Setters[k]
        if set then pcall(set, deser(v)) end
    end
    self.Pins = {}
    for _, id in ipairs(data.pins or {}) do table.insert(self.Pins, id) end
    self:RefreshPins()
    return true, name
end
function Library:DeleteConfig(name)
    if fsOK() and typeof(delfile) == "function" then
        local path = self:_dir() .. "/" .. tostring(name) .. ".json"
        if isfile(path) then delfile(path); return true end
    end
    return false
end
function Library:SetAutoload(name)
    if not fsOK() then return false end
    writefile(self.Window.Folder .. "/autoload.txt", tostring(name))
    return true
end
function Library:LoadAutoload()
    if not fsOK() then return end
    local p = self.Window.Folder .. "/autoload.txt"
    if isfile(p) then
        local n = readfile(p)
        local ok = self:LoadConfig(n)
        if ok then self:Notify("Autoload: " .. n) end
    end
end

function Library:Unload()
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    if self.Gui then self.Gui:Destroy() end
    if getgenv then getgenv().VYX_UI = nil end
end

------------------------------------------------------------------ elements
local Section = {}
Section.__index = Section

function Section:AddLabel(str)
    local r, l = makeRow(self.Frame, 34, str)
    r.LayoutOrder = nextOrder(self)
    l.Size = UDim2.new(1, -28, 1, 0)
    local obj = {}
    function obj:Set(s) l.Text = s end
    return obj
end

function Section:AddToggle(o)
    local r = makeRow(self.Frame, 38, o.Name); r.LayoutOrder = nextOrder(self)
    local sw = new("Frame", { Size = UDim2.fromOffset(48, 24), Position = UDim2.new(1, -60, .5, -12), Parent = r })
    corner(sw, 12)
    local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = WHITE, Parent = sw })
    corner(knob, 9)
    local obj = { Value = false }
    local function paint(anim)
        local pos = obj.Value and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3)
        if anim then TS:Create(knob, TweenInfo.new(.15), { Position = pos }):Play() else knob.Position = pos end
        sw.BackgroundColor3 = obj.Value and Library.Theme.Accent or Color3.fromRGB(62, 60, 76)
    end
    function obj:Set(v, silent)
        obj.Value = v and true or false
        if o.Flag then Library.Flags[o.Flag] = obj.Value end
        paint(true); Library:RefreshPins()
        if not silent then safe(o.Callback, obj.Value) end
    end
    r.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    addUpdater(function() paint(false) end)
    if o.Flag then Library.Setters[o.Flag] = function(v) obj:Set(v) end end
    obj.Value = o.Default or false
    if o.Flag then Library.Flags[o.Flag] = obj.Value end
    paint(false)
    if obj.Value then safe(o.Callback, true) end
    pinnable(o.Flag or o.Name, r, { Name = o.Name, Type = "toggle", Get = function() return obj.Value end,
        Fire = function() obj:Set(not obj.Value) end })
    return obj
end

function Section:AddButton(o)
    local r = makeRow(self.Frame, 40, o.Name); r.LayoutOrder = nextOrder(self)
    local b = new("TextButton", { Text = o.ButtonText or "Run", Size = UDim2.fromOffset(110, 28),
        Position = UDim2.new(1, -122, .5, -14), Font = BOLD, TextSize = 15, TextColor3 = WHITE,
        AutoButtonColor = false, Parent = r })
    corner(b, 7); theme(b, "BackgroundColor3", "Accent")
    local function fire() safe(o.Callback) end
    b.MouseButton1Click:Connect(fire)
    pinnable(o.Flag or o.Name, r, { Name = o.Name, Type = "button", Fire = fire })
    return { Fire = fire }
end

function Section:AddSlider(o)
    local r = makeRow(self.Frame, 44); r.LayoutOrder = nextOrder(self)
    text(r, { Text = o.Name, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(92, 44), TextSize = 15 })
    local box = new("TextBox", { Size = UDim2.fromOffset(60, 28), Position = UDim2.new(1, -72, .5, -14), Font = FONT,
        TextSize = 15, ClearTextOnFocus = false, Parent = r })
    corner(box, 7); stroke(box, "Stroke", 1.5)
    theme(box, "BackgroundColor3", "Background"); theme(box, "TextColor3", "Text")
    local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(110, 0),
        Size = UDim2.new(1, -196, 1, 0), Parent = r })
    local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, .5, -4), BorderSizePixel = 0, Parent = hit })
    corner(bar, 4); theme(bar, "BackgroundColor3", "Stroke")
    local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = bar })
    corner(fill, 4); theme(fill, "BackgroundColor3", "Accent")
    local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, Parent = bar })
    corner(knob, 9)

    local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
    local dec = 0
    local s = tostring(inc); local dot = s:find("%.")
    if dot then dec = #s - dot end
    local obj = { Value = min }
    local function snap(v)
        v = math.clamp(math.floor((v - min) / inc + .5) * inc + min, min, max)
        return tonumber(string.format("%." .. dec .. "f", v))
    end
    local function paint()
        local a = (obj.Value - min) / (max - min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, -9, .5, -9)
        box.Text = tostring(obj.Value)
    end
    function obj:Set(v, silent)
        v = snap(tonumber(v) or min)
        local changed = v ~= obj.Value
        obj.Value = v
        if o.Flag then Library.Flags[o.Flag] = v end
        paint()
        if changed and not silent then safe(o.Callback, v) end
    end
    local function fromX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        obj:Set(min + (max - min) * a)
    end
    local dragging = false
    hit.InputBegan:Connect(function(i) if isPress(i) then dragging = true; fromX(i.Position.X) end end)
    connect(UIS.InputChanged, function(i) if dragging and isMove(i) then fromX(i.Position.X) end end)
    connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
    box.FocusLost:Connect(function() obj:Set(box.Text) end)
    if o.Flag then Library.Setters[o.Flag] = function(v) obj:Set(v) end end
    obj.Value = snap(o.Default or min)
    if o.Flag then Library.Flags[o.Flag] = obj.Value end
    paint()
    if o.Default then safe(o.Callback, obj.Value) end
    return obj
end

function Section:AddDropdown(o)
    local w = wrapper(self)
    local r = makeRow(w, 38, o.Name); r.LayoutOrder = 1
    local sel = text(r, { Size = UDim2.new(0, 150, 1, 0), Position = UDim2.new(1, -176, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right, ColorKey = "SubText", TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd })
    text(r, { Text = "▼", Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -26, 0, 0), TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center, ColorKey = "SubText" })
    local list = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Visible = false, LayoutOrder = 2, Parent = w })
    theme(list, "BackgroundColor3", "Element"); corner(list, 8); stroke(list, "Stroke", 1)
    new("UIListLayout", { Padding = UDim.new(0, 2), Parent = list })
    new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = list })

    local obj = { Value = nil, Options = {} }
    function obj:Set(v, silent)
        obj.Value = v
        sel.Text = v and tostring(v) or "None"
        if o.Flag then Library.Flags[o.Flag] = v end
        if not silent then safe(o.Callback, v) end
    end
    function obj:Refresh(opts)
        obj.Options = opts or {}
        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, opt in ipairs(obj.Options) do
            local b = new("TextButton", { Text = tostring(opt), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
                Font = FONT, TextSize = 14, AutoButtonColor = false, Parent = list })
            theme(b, "TextColor3", "Text"); corner(b, 6)
            b.MouseEnter:Connect(function() b.BackgroundTransparency = 0; b.BackgroundColor3 = Library.Theme.Stroke end)
            b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
            b.MouseButton1Click:Connect(function() obj:Set(opt); list.Visible = false end)
        end
    end
    r.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    if o.Flag then Library.Setters[o.Flag] = function(v) obj:Set(v) end end
    obj:Refresh(o.Options)
    obj:Set(o.Default, true)
    if o.Default then safe(o.Callback, o.Default) end
    return obj
end

local function kname(k) if typeof(k) == "EnumItem" then return k.Name end return k or "None" end

function Section:AddKeybind(o)
    local r = makeRow(self.Frame, 38, o.Name); r.LayoutOrder = nextOrder(self)
    local btn = new("TextButton", { Size = UDim2.fromOffset(100, 26), Position = UDim2.new(1, -112, .5, -13), Font = BOLD,
        TextSize = 13, AutoButtonColor = false, Parent = r })
    corner(btn, 7); stroke(btn, "Stroke", 1.5)
    theme(btn, "BackgroundColor3", "Background"); theme(btn, "TextColor3", "Text")
    local obj = { Value = "None" }
    function obj:Set(v, silent)
        obj.Value = kname(v); btn.Text = obj.Value
        if o.Flag then Library.Flags[o.Flag] = obj.Value end
        if not silent then safe(o.Changed, obj.Value) end
    end
    btn.MouseButton1Click:Connect(function()
        if Library.Listening then return end
        Library.Listening = true; btn.Text = "..."
        local c
        c = UIS.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                c:Disconnect()
                task.delay(.15, function() Library.Listening = false end)
                if i.KeyCode == Enum.KeyCode.Escape then obj:Set("None") else obj:Set(i.KeyCode) end
            end
        end)
    end)
    table.insert(Library._keybinds, { obj = obj, cb = o.Callback })
    if o.Flag then Library.Setters[o.Flag] = function(v) obj:Set(v) end end
    obj:Set(o.Default, true)
    return obj
end

function Section:AddTextBox(o)
    local r = makeRow(self.Frame, 38, o.Name); r.LayoutOrder = nextOrder(self)
    local box = new("TextBox", { Size = UDim2.fromOffset(150, 26), Position = UDim2.new(1, -162, .5, -13), Font = FONT,
        TextSize = 14, ClearTextOnFocus = false, PlaceholderText = o.Placeholder or "", Text = o.Default or "", Parent = r })
    corner(box, 7); stroke(box, "Stroke", 1.5)
    theme(box, "BackgroundColor3", "Background"); theme(box, "TextColor3", "Text")
    local obj = { Value = box.Text }
    function obj:Set(v, silent)
        obj.Value = tostring(v or ""); box.Text = obj.Value
        if o.Flag then Library.Flags[o.Flag] = obj.Value end
        if not silent then safe(o.Callback, obj.Value) end
    end
    box.FocusLost:Connect(function() obj:Set(box.Text) end)
    if o.Flag then Library.Setters[o.Flag] = function(v) obj:Set(v) end; Library.Flags[o.Flag] = obj.Value end
    return obj
end

function Section:AddColorPicker(o)
    local w = wrapper(self)
    local r = makeRow(w, 38, o.Name); r.LayoutOrder = 1
    local sw = new("Frame", { Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -56, .5, -11), Parent = r })
    corner(sw, 6); stroke(sw, "Stroke", 1)
    local panel = new("Frame", { Size = UDim2.new(1, 0, 0, 130), Visible = false, LayoutOrder = 2, Parent = w })
    theme(panel, "BackgroundColor3", "Element"); corner(panel, 8); stroke(panel, "Stroke", 1)

    local sv = new("Frame", { Size = UDim2.new(1, -62, 1, -20), Position = UDim2.fromOffset(10, 10), BorderSizePixel = 0, Parent = panel })
    corner(sv, 6)
    local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = sv })
    corner(white, 6); new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv })
    corner(black, 6); new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
    local svCur = new("Frame", { Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 4, Parent = sv })
    corner(svCur, 6); new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Parent = svCur })
    local svHit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = sv })

    local hue = new("Frame", { Size = UDim2.new(0, 24, 1, -20), Position = UDim2.new(1, -36, 0, 10), BorderSizePixel = 0,
        BackgroundColor3 = WHITE, Parent = panel })
    corner(hue, 6)
    new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }), Parent = hue })
    local hueCur = new("Frame", { Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = WHITE, ZIndex = 4, Parent = hue })
    corner(hueCur, 2); new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCur })
    local hueHit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = hue })

    local h, s, v = 0, 1, 1
    local obj = { Value = Color3.new(1, 1, 1) }
    local function paint()
        sw.BackgroundColor3 = Color3.fromHSV(h, s, v)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCur.Position = UDim2.new(s, -6, 1 - v, -6)
        hueCur.Position = UDim2.new(0, -2, h, -2)
    end
    local function apply(silent)
        obj.Value = Color3.fromHSV(h, s, v)
        if o.Flag then Library.Flags[o.Flag] = obj.Value end
        paint()
        if not silent then safe(o.Callback, obj.Value) end
    end
    function obj:Set(c, silent)
        if type(c) == "table" then c = deser(c) end
        if typeof(c) ~= "Color3" then return end
        h, s, v = c:ToHSV()
        apply(silent)
    end
    local mode
    svHit.InputBegan:Connect(function(i) if isPress(i) then mode = "sv" end end)
    hueHit.InputBegan:Connect(function(i) if isPress(i) then mode = "hue" end end)
    local function update(pos)
        if mode == "sv" then
            s = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
            apply()
        elseif mode == "hue" then
            h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
            apply()
        end
    end
    connect(UIS.InputBegan, function(i) if mode and isPress(i) then update(i.Position) end end)
    svHit.InputBegan:Connect(function(i) if isPress(i) then update(i.Position) end end)
    hueHit.InputBegan:Connect(function(i) if isPress(i) then update(i.Position) end end)
    connect(UIS.InputChanged, function(i) if mode and isMove(i) then update(i.Position) end end)
    connect(UIS.InputEnded, function(i) if isPress(i) then mode = nil end end)

    r.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
    if o.Flag then Library.Setters[o.Flag] = function(c) obj:Set(c) end end
    obj:Set(o.Default or Color3.new(1, 1, 1), true)
    if o.Default then safe(o.Callback, obj.Value) end
    return obj
end

------------------------------------------------------------------ window
local function makeTitle(parent, pos, size, title, accent)
    local h = new("Frame", { BackgroundTransparency = 1, Position = pos, Size = UDim2.fromOffset(200, size + 6), Parent = parent })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
        VerticalAlignment = Enum.VerticalAlignment.Center, Parent = h })
    text(h, { Text = title, Font = BLACK, TextSize = size, AutomaticSize = XY, Size = UDim2.new() })
    text(h, { Text = accent, Font = BLACK, TextSize = size, AutomaticSize = XY, Size = UDim2.new(), ColorKey = "Accent" })
    return h
end

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local Window = { Tabs = {}, Folder = cfg.Folder or "VYXUI", ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
        Minimized = false, Hidden = false, IconTint = (cfg.IconTint ~= false) }
    Library.Window = Window

    local parent = getParent()
    local old = parent:FindFirstChild("VYXUI"); if old then old:Destroy() end
    local gui = new("ScreenGui", { Name = "VYXUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = parent
    Library.Gui = gui
    if getgenv then getgenv().VYX_UI = Library end

    -- notifications
    local nh = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(240, 400), Position = UDim2.new(1, -250, 1, -410), Parent = gui })
    new("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = nh })
    Library.NotifyHolder = nh

    -- main
    local main = new("Frame", { Size = UDim2.fromOffset(560, 340), Position = UDim2.new(.5, -280, .5, -170), Parent = gui })
    theme(main, "BackgroundColor3", "Background"); corner(main, 14); stroke(main, "Accent", 2)
    local scale = new("UIScale", { Parent = main })
    Window.Scale = scale

    local header = new("Frame", { Size = UDim2.new(1, -12, 0, 58), Position = UDim2.fromOffset(6, 6), ClipsDescendants = true, Parent = main })
    theme(header, "BackgroundColor3", "Element"); corner(header, 12); stroke(header, "Stroke", 1)
    for _, d in ipairs({ { .66, 26, .35 }, { .72, 12, .6 } }) do
        local f = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(d[1], .5), Size = UDim2.fromOffset(d[2], 140),
            Rotation = 38, BackgroundTransparency = d[3], BorderSizePixel = 0, Parent = header })
        theme(f, "BackgroundColor3", "Accent")
    end
    local logoTint = nil
    if cfg.LogoTint then logoTint = "Accent" end   -- LogoTint = true -> gambar di-tint warna Accent
    makeIcon(header, cfg.Logo, { Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(46, 46), Tint = logoTint,
        TextTint = "Accent", TextSize = 36, Font = BLACK, Default = "V" })
    makeTitle(header, UDim2.fromOffset(62, 6), 24, cfg.Title or "VYX", cfg.TitleAccent or "UI")
    text(header, { Text = cfg.Subtitle or "Premium • Modern • Simple", Position = UDim2.fromOffset(62, 34), Size = UDim2.fromOffset(250, 16),
        TextSize = 13, ColorKey = "SubText" })

    local function hbtn(txt, x)
        local b = new("TextButton", { Text = txt, Size = UDim2.fromOffset(38, 38), Position = UDim2.new(1, x, .5, -19), Font = BLACK,
            TextSize = 20, AutoButtonColor = false, Parent = header })
        theme(b, "BackgroundColor3", "Background"); theme(b, "TextColor3", "Text"); corner(b, 9); stroke(b, "Accent", 1.5)
        return b
    end
    local minBtn, closeBtn = hbtn("–", -92), hbtn("✕", -48)
    draggable(header, main)

    -- pill (minimized)
    local pill = new("Frame", { Size = UDim2.fromOffset(204, 46), Position = main.Position, Visible = false, Parent = gui })
    theme(pill, "BackgroundColor3", "Background"); corner(pill, 12); stroke(pill, "Accent", 2)
    local pscale = new("UIScale", { Parent = pill })
    makeIcon(pill, cfg.Logo, { Position = UDim2.fromOffset(36, 5), Size = UDim2.fromOffset(36, 36), Tint = logoTint,
        TextTint = "Accent", TextSize = 26, Font = BLACK, Default = "V" })
    makeTitle(pill, UDim2.fromOffset(78, 8), 18, cfg.Title or "VYX", cfg.TitleAccent or "UI")
    local arrow = new("TextButton", { Text = "^", Font = BLACK, TextSize = 24, Size = UDim2.new(0, 44, 1, 0),
        Position = UDim2.new(1, -44, 0, 0), BackgroundTransparency = 1, Parent = pill })
    theme(arrow, "TextColor3", "Text")
    -- handle drag (⋮⋮): pill cuma bisa digeser lewat handle ini, klik tempat lain gak bakal ke-drag
    local grip = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(26, 34), Position = UDim2.fromOffset(5, 6), Parent = pill })
    theme(grip, "BackgroundColor3", "Element"); corner(grip, 7); stroke(grip, "Stroke", 1)
    for cx = 0, 1 do
        for cy = 0, 2 do
            local dot = new("Frame", { Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(6 + cx * 8, 7 + cy * 8),
                BorderSizePixel = 0, Parent = grip })
            corner(dot, 2); theme(dot, "BackgroundColor3", "SubText")
        end
    end
    draggable(grip, pill)

    local function vis()
        main.Visible = not Window.Hidden and not Window.Minimized
        pill.Visible = not Window.Hidden and Window.Minimized
    end
    minBtn.MouseButton1Click:Connect(function() pill.Position = main.Position; Window.Minimized = true; vis() end)
    arrow.MouseButton1Click:Connect(function() main.Position = pill.Position; Window.Minimized = false; vis() end)
    closeBtn.MouseButton1Click:Connect(function() Library:Unload() end)

    connect(UIS.InputBegan, function(i, gp)
        if gp or Library.Listening or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if i.KeyCode.Name == Window.ToggleKey.Name then Window.Hidden = not Window.Hidden; vis(); return end
        for _, k in ipairs(Library._keybinds) do
            if k.cb and k.obj.Value ~= "None" and i.KeyCode.Name == k.obj.Value then safe(k.cb) end
        end
    end)

    -- body
    local side = new("ScrollingFrame", { Size = UDim2.fromOffset(142, 264), Position = UDim2.fromOffset(10, 70), BackgroundTransparency = 1,
        ScrollBarThickness = 0, AutomaticCanvasSize = Y, CanvasSize = UDim2.new(), BorderSizePixel = 0, Parent = main })
    new("UIListLayout", { Padding = UDim.new(0, 6), Parent = side })
    local content = new("Frame", { Size = UDim2.fromOffset(392, 264), Position = UDim2.fromOffset(158, 70), BackgroundTransparency = 1, Parent = main })

    -- shortcut panel
    local panel = new("Frame", { Size = UDim2.fromOffset(150, 0), AutomaticSize = Y, Position = UDim2.new(0, 20, .4, 0), Visible = false, Parent = gui })
    theme(panel, "BackgroundColor3", "Background"); corner(panel, 10); stroke(panel, "Accent", 1.5)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
    new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = panel })
    local ph = text(panel, { Text = "📌 Shortcuts", Font = BOLD, TextSize = 13, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, ColorKey = "SubText" })
    draggable(ph, panel)
    Library.PinPanel = panel
    addUpdater(function() Library:RefreshPins() end)

    ---------------------------------------------------------------- tabs
    function Window:AddTab(name, tabIcon, fallback)
        local Tab = { Active = false }
        local btn = new("TextButton", { Text = "", Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false, Parent = side })
        corner(btn, 9); stroke(btn, "Stroke", 1)
        makeIcon(btn, tabIcon, { Position = UDim2.fromOffset(14, 7), Size = UDim2.fromOffset(26, 26), Tint = Window.IconTint and "Text" or nil,
            TextSize = 18, Default = fallback or "•" })
        text(btn, { Text = name, Font = BOLD, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -54, 1, 0), TextSize = 16 })
        local page = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, AutomaticCanvasSize = Y, CanvasSize = UDim2.new(), Visible = false, Parent = content })
        theme(page, "ScrollBarImageColor3", "Accent")
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
        new("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = page })
        Tab.Page = page

        local function paint() btn.BackgroundColor3 = Tab.Active and Library.Theme.Accent or Library.Theme.Element end
        addUpdater(paint)
        Tab.Paint = paint
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(Window.Tabs) do t.Active = (t == Tab); t.Page.Visible = t.Active; t.Paint() end
        end)
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Tab.Active = true; page.Visible = true end
        paint()

        local order = 0
        function Tab:AddSection(title)
            order += 1
            local f = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = page })
            new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
            local hd = new("Frame", { Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 0, Parent = f })
            theme(hd, "BackgroundColor3", "Element"); corner(hd, 8)
            local bar = new("Frame", { Size = UDim2.fromOffset(4, 18), Position = UDim2.new(0, 8, .5, -9), BorderSizePixel = 0, Parent = hd })
            corner(bar, 2); theme(bar, "BackgroundColor3", "Accent")
            text(hd, { Text = title, Font = BOLD, TextSize = 17, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -30, 1, 0) })
            return setmetatable({ Frame = f }, Section)
        end
        return Tab
    end

    ---------------------------------------------------------------- settings tab
    function Window:BuildSettings(iconAsset)
        local tab = Window:AddTab("Settings", iconAsset, "⚙")

        local th = tab:AddSection("Theme")
        local names = { "Accent", "Background", "Element", "Stroke", "Text" }
        for _, key in ipairs(names) do
            th:AddColorPicker({ Name = key, Flag = "Theme_" .. key, Default = Library.Theme[key],
                Callback = function(c) Library:SetTheme(key, c) end })
        end
        th:AddButton({ Name = "Reset Theme", ButtonText = "Reset", Callback = function()
            for _, key in ipairs(names) do
                local set = Library.Setters["Theme_" .. key]
                if set then set(DefaultTheme[key]) end
            end
        end })

        local ui = tab:AddSection("Interface")
        ui:AddKeybind({ Name = "Menu Key", Flag = "MenuKey", Default = Window.ToggleKey,
            Changed = function(k) if k ~= "None" then Window.ToggleKey = Enum.KeyCode[k] end end })
        ui:AddToggle({ Name = "Show Shortcuts", Flag = "ShowShortcuts", Default = true,
            Callback = function(v) Library.ShowShortcuts = v; Library:RefreshPins() end })
        ui:AddSlider({ Name = "UI Scale", Flag = "UIScale", Min = 60, Max = 130, Default = 100, Increment = 5,
            Callback = function(v) Window.Scale.Scale = v / 100; pscale.Scale = v / 100 end })
        ui:AddButton({ Name = "Clear Shortcuts", ButtonText = "Clear", Callback = function()
            Library.Pins = {}; Library:RefreshPins()
        end })
        ui:AddButton({ Name = "Unload UI", ButtonText = "Unload", Callback = function() Library:Unload() end })

        local cf = tab:AddSection("Config")
        if not fsOK() then
            cf:AddLabel("Executor lu gak support file system")
            return tab
        end
        local cname = cf:AddTextBox({ Name = "Config Name", Placeholder = "my config" })
        local dd = cf:AddDropdown({ Name = "Configs", Options = Library:ListConfigs() })
        local function refresh() dd:Refresh(Library:ListConfigs()) end
        cf:AddButton({ Name = "Save Config", ButtonText = "Save", Callback = function()
            local ok, r = Library:SaveConfig(cname.Value ~= "" and cname.Value or dd.Value)
            Library:Notify(ok and ("Saved: " .. r) or tostring(r)); refresh()
        end })
        cf:AddButton({ Name = "Load Config", ButtonText = "Load", Callback = function()
            local ok, r = Library:LoadConfig(dd.Value)
            Library:Notify(ok and ("Loaded: " .. r) or tostring(r))
        end })
        cf:AddButton({ Name = "Delete Config", ButtonText = "Delete", Callback = function()
            Library:Notify(Library:DeleteConfig(dd.Value) and "Deleted" or "Gagal delete"); dd:Set(nil, true); refresh()
        end })
        cf:AddButton({ Name = "Set Autoload", ButtonText = "Autoload", Callback = function()
            if dd.Value then Library:SetAutoload(dd.Value); Library:Notify("Autoload: " .. dd.Value) end
        end })
        cf:AddButton({ Name = "Refresh List", ButtonText = "Refresh", Callback = refresh })
        return tab
    end

    return Window
end

return Library
