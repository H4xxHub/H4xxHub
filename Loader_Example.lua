-- Ganti URL ini ke link raw VYX_UI.lua lu
local VYX = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4xxHub/H4xxHub/main/H4xx_UI.lua"))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local playerId = LocalPlayer.UserId

local WORKER_URL = "https://h4xx-key.h4xxhub.workers.dev"
local NETLIFY_URL = "https://h4xx-key.netlify.app/?uid=" .. tostring(playerId)

------------------------------------------------ ICON (asset Roblox)
local ICONS = {
    Logo     = "",   
    Main     = "",
    Player   = "",
    Teleport = "",
    Misc     = "",
    Settings = "",
}

------------------------------------------------ KEY SYSTEM (AUTO CHECK CLOUDFLARE)
VYX:Notify("Memeriksa status akses...")

-- Fungsi buat nanya ke Cloudflare: "Orang ini udah punya key belum?"
local function checkStatusFromCloudflare()
    local success, res = pcall(function()
        local url = WORKER_URL .. "/check-status?userId=" .. tostring(playerId)
        local response = HttpService:GetAsync(url)
        return HttpService:JSONDecode(response)
    end)
    if success and res then
        return res.hasKey
    end
    return false
end

local hasKey = checkStatusFromCloudflare()

if not hasKey then
    -- KALAU BELUM PUNYA KEY, MUNCULIN UI MINTA KEY
    local keyOk = VYX:KeySystem({
        Title = "H4xx",
        TitleAccent = "Hub",
        Subtitle = "Key System",
        Logo = ICONS.Logo,
        Keys = {}, -- Kosongin, validasi pakai Cloudflare
        
        GetKeyLink = NETLIFY_URL, 
        SaveKey = true,
        Folder = "H4xxHub",
        
        -- Validasi kalau user ngetik key manual
        Validate = function(inputKey)
            local success, res = pcall(function()
                local url = WORKER_URL .. "/check-key?key=" .. inputKey .. "&userId=" .. tostring(playerId)
                local response = HttpService:GetAsync(url)
                return HttpService:JSONDecode(response)
            end)
            if success and res then
                return res.valid == true
            end
            return false
        end
    })

    if not keyOk then return end -- Kalau user close/nge-bypass, script berhenti
else
    VYX:Notify("✅ Akses diterima! Membuka UI...")
end

------------------------------------------------ MAIN UI
local Window = VYX:CreateWindow({
    Title = "H4xx",
    TitleAccent = "Hub",
    Subtitle = "Premium • Modern • Simple",
    Logo = ICONS.Logo,          
    LogoTint = false,           
    IconTint = true,            
    Folder = "H4xxHub",
    ToggleKey = Enum.KeyCode.RightShift,
})

------------------------------------------------ Main Tab
local Main = Window:AddTab("Main", ICONS.Main, "🏠")

local Farm = Main:AddSection("Auto Farm")
Farm:AddToggle({ Name = "Auto Farm", Flag = "AutoFarm", Default = false, Callback = function(v)
    getgenv().AutoFarm = v
    if v then
        local myToken = {}
        getgenv().AutoFarmToken = myToken
        task.spawn(function()
            while getgenv().AutoFarmToken == myToken do
                -- taruh logic auto farm lu di sini
                task.wait(0.5)
            end
        end)
    end
end })

Farm:AddToggle({ Name = "Auto Collect", Flag = "AutoCollect", Default = false, Callback = function(v)
    getgenv().AutoCollect = v
    if v then
        local myToken = {}
        getgenv().AutoCollectToken = myToken
        task.spawn(function()
            while getgenv().AutoCollectToken == myToken do
                -- logic auto collect
                task.wait(0.5)
            end
        end)
    end
end })

local Other = Main:AddSection("Other")
Other:AddButton({ Name = "Buy All", ButtonText = "Buy", Callback = function()
    -- logic buy all
end })

Other:AddSlider({ Name = "Speed", Flag = "Speed", Min = 16, Max = 100, Default = 16, Increment = 1, Callback = function(v)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end })

------------------------------------------------ Player Tab
local Player = Window:AddTab("Player", ICONS.Player, "👤")
local P = Player:AddSection("Player")
P:AddSlider({ Name = "Jump", Flag = "Jump", Min = 50, Max = 200, Default = 50, Callback = function(v)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end })

------------------------------------------------ Teleports Tab
local Tp = Window:AddTab("Teleports", ICONS.Teleport, "📍")
local T = Tp:AddSection("Locations")
T:AddDropdown({ Name = "Location", Flag = "TpLoc", Options = { "Spawn", "Shop", "Boss" }, Default = "Spawn" })
T:AddButton({ Name = "Teleport", ButtonText = "Go", Callback = function()
    -- teleport ke VYX.Flags.TpLoc
end })

------------------------------------------------ Misc Tab
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
