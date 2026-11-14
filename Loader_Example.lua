-- Ganti URL ini ke link raw VYX_UI.lua lu (GitHub raw / Pastebin raw / dll)
local VYX = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4xxHub/H4xxHub/refs/heads/main/H4xx_UI.lua"))()

------------------------------------------------ ICON (asset Roblox)
-- Isi pakai ID gambar lu: "rbxassetid://123456789" atau angka ID-nya aja.
-- Kalau dikosongin (""), otomatis pakai emoji/huruf V sebagai cadangan.
local ICONS = {
    Logo     = "",   -- logo "V" di header & pill (upload logo lu ke Roblox, lalu taruh ID Image-nya)
    Main     = "",
    Player   = "",
    Teleport = "",
    Misc     = "",
    Settings = "",
}

local Window = VYX:CreateWindow({
    Title = "VYX",
    TitleAccent = "UI",
    Subtitle = "Premium • Modern • Simple",
    Logo = ICONS.Logo,          -- ganti huruf V
    LogoTint = false,           -- true = logo diwarnai sesuai Accent, false = warna asli gambar
    IconTint = true,            -- true = icon tab diwarnai putih/Text (cocok buat icon monochrome putih)
    Folder = "VYXUI",
    ToggleKey = Enum.KeyCode.RightShift,
})

------------------------------------------------ Main
local Main = Window:AddTab("Main", ICONS.Main, "🏠")

local Farm = Main:AddSection("Auto Farm")
Farm:AddToggle({ Name = "Auto Farm", Flag = "AutoFarm", Default = true, Callback = function(v)
    getgenv().AutoFarm = v
    task.spawn(function()
        while getgenv().AutoFarm do
            -- taruh logic auto farm lu di sini
            task.wait(0.5)
        end
    end)
end })
Farm:AddToggle({ Name = "Auto Collect", Flag = "AutoCollect", Callback = function(v)
    getgenv().AutoCollect = v
    task.spawn(function()
        while getgenv().AutoCollect do
            -- logic auto collect
            task.wait(0.5)
        end
    end)
end })

local Other = Main:AddSection("Other")
Other:AddButton({ Name = "Buy All", ButtonText = "Buy", Callback = function()
    -- logic buy all
end })
Other:AddSlider({ Name = "Speed", Flag = "Speed", Min = 16, Max = 100, Default = 16, Increment = 1, Callback = function(v)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end })

------------------------------------------------ Player
local Player = Window:AddTab("Player", ICONS.Player, "👤")
local P = Player:AddSection("Player")
P:AddSlider({ Name = "Jump", Flag = "Jump", Min = 50, Max = 200, Default = 50, Callback = function(v)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end })

------------------------------------------------ Teleports
local Tp = Window:AddTab("Teleports", ICONS.Teleport, "📍")
local T = Tp:AddSection("Locations")
T:AddDropdown({ Name = "Location", Flag = "TpLoc", Options = { "Spawn", "Shop", "Boss" }, Default = "Spawn" })
T:AddButton({ Name = "Teleport", ButtonText = "Go", Callback = function()
    -- teleport ke VYX.Flags.TpLoc
end })

------------------------------------------------ Misc
local Misc = Window:AddTab("Misc", ICONS.Misc, "📦")
local M = Misc:AddSection("Misc")
M:AddKeybind({ Name = "Quick Buy Key", Flag = "QuickBuy", Default = Enum.KeyCode.B, Callback = function()
    VYX:Notify("Quick buy!")
end })
M:AddTextBox({ Name = "Custom Text", Flag = "CustomText", Placeholder = "ketik..." })

------------------------------------------------ Settings (theme, shortcut, config) — taruh paling akhir
Window:BuildSettings(ICONS.Settings)

VYX:LoadAutoload()
VYX:Notify("VYX UI loaded • Klik kanan toggle/button untuk pin shortcut")
