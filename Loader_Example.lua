--[[
    H4xxHub Loader Example
    Ganti SCRIPT_ID sesuai script lu.
    Pastikan Netlify GetKeyLink kirim scriptId yang sama.
]]

local VYX = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4xxHub/H4xxHub/main/H4xx_UI.lua"))()

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local playerId    = LocalPlayer.UserId

-- ============================================
-- KONFIGURASI
-- ============================================
local WORKER_URL  = "https://h4xx-key.h4xxhub.workers.dev"
local SCRIPT_ID   = "namascript" -- <<< GANTI
local NETLIFY_URL = "https://h4xx-key.netlify.app/?uid=" .. tostring(playerId)
                   .. "&script=" .. tostring(SCRIPT_ID)

------------------------------------------------ ICON
local ICONS = {
    Logo     = "",
    Main     = "",
    Player   = "",
    Teleport = "",
    Misc     = "",
    Settings = "",
}

-- ============================================
-- HELPER
-- ============================================
local function httpGetJSON(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res or res == "" then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 then return nil end
    return data
end

-- ============================================
-- KEY SYSTEM
-- ============================================
VYX:Notify("Memeriksa status akses...")

local function checkStatusFromCloudflare()
    local url = WORKER_URL .. "/check-status"
             .. "?userId="   .. tostring(playerId)
             .. "&scriptId=" .. tostring(SCRIPT_ID)
    local data = httpGetJSON(url)
    return data and data.hasKey == true
end

local function validateKey(inputKey)
    if not inputKey or inputKey == "" then return false end
    local url = WORKER_URL .. "/check-key"
             .. "?key="      .. inputKey
             .. "&userId="   .. tostring(playerId)
             .. "&scriptId=" .. tostring(SCRIPT_ID)
    local data = httpGetJSON(url)
    return data and data.valid == true
end

if not checkStatusFromCloudflare() then
    local keyOk = VYX:KeySystem({
        Title       = "H4xx",
        TitleAccent = "Hub",
        Subtitle    = "Key System • " .. SCRIPT_ID,
        Logo        = ICONS.Logo,
        Keys        = {},
        GetKeyLink  = NETLIFY_URL,
        SaveKey     = true,
        Folder      = "H4xxHub",
        Validate    = validateKey,
    })
    if not keyOk then return end
else
    VYX:Notify("✅ Akses diterima! Membuka UI...")
end

-- ============================================
-- MAIN UI
-- ============================================
local Window = VYX:CreateWindow({
    Title       = "H4xx",
    TitleAccent = "Hub",
    Subtitle    = "Premium • Modern • Simple",
    Logo        = ICONS.Logo,
    LogoTint    = false,
    IconTint    = true,
    Folder      = "H4xxHub",
    ToggleKey   = Enum.KeyCode.RightShift,
})

------------------------------------------------ Main
local Main = Window:AddTab("Main", ICONS.Main, "🏠")
local Farm = Main:AddSection("Auto Farm")

Farm:AddToggle({ Name = "Auto Farm", Flag = "AutoFarm", Default = false, Callback = function(v)
    getgenv().AutoFarm = v
    if v then
        local token = {}
        getgenv().AutoFarmToken = token
        task.spawn(function()
            while getgenv().AutoFarmToken == token do
                task.wait(0.5)
            end
        end)
    end
end })

Farm:AddToggle({ Name = "Auto Collect", Flag = "AutoCollect", Default = false, Callback = function(v)
    getgenv().AutoCollect = v
    if v then
        local token = {}
        getgenv().AutoCollectToken = token
        task.spawn(function()
            while getgenv().AutoCollectToken == token do
                task.wait(0.5)
            end
        end)
    end
end })

local Other = Main:AddSection("Other")
Other:AddButton({ Name = "Buy All", ButtonText = "Buy", Callback = function() end })
Other:AddSlider({ Name = "Speed", Flag = "Speed", Min = 16, Max = 100, Default = 16, Increment = 1, Callback = function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end })

------------------------------------------------ Player
local Player = Window:AddTab("Player", ICONS.Player, "👤")
local P = Player:AddSection("Player")
P:AddSlider({ Name = "Jump", Flag = "Jump", Min = 50, Max = 200, Default = 50, Callback = function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end })

------------------------------------------------ Teleports
local Tp = Window:AddTab("Teleports", ICONS.Teleport, "📍")
local T = Tp:AddSection("Locations")
T:AddDropdown({ Name = "Location", Flag = "TpLoc", Options = { "Spawn", "Shop", "Boss" }, Default = "Spawn" })
T:AddButton({ Name = "Teleport", ButtonText = "Go", Callback = function() end })

------------------------------------------------ Misc
local Misc = Window:AddTab("Misc", ICONS.Misc, "📦")
local M = Misc:AddSection("Misc")
M:AddKeybind({ Name = "Quick Buy Key", Flag = "QuickBuy", Default = Enum.KeyCode.B, Callback = function()
    VYX:Notify("Quick buy!")
end })
M:AddTextBox({ Name = "Custom Text", Flag = "CustomText", Placeholder = "ketik..." })

------------------------------------------------ Settings
Window:BuildSettings(ICONS.Settings)

VYX:LoadAutoload()
VYX:Notify("VYX UI loaded • Klik kanan toggle/button untuk pin shortcut")
