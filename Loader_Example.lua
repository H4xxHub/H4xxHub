-- Ganti URL ini ke link raw VYX_UI.lua lu (GitHub raw / Pastebin raw / dll)
local VYX = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4xxHub/H4xxHub/main/H4xx_UI.lua"))()

------------------------------------------------ ICON (asset Roblox)
-- Isi pakai ID gambar lu: "rbxassetid://123456789" atau angka ID-nya aja.
-- Kalau dikosongin (""), otomatis pakai emoji/huruf V sebagai cadangan.
local ICONS = {
    Logo     = "",   -- logo "V" di header & pill
    Main     = "",
    Player   = "",
    Teleport = "",
    Misc     = "",
    Settings = "",
}

------------------------------------------------ KEY SYSTEM
-- Taruh sebelum CreateWindow. Window baru kebuka kalau key bener.
local NAME, ACCENT = "H4xx", "Hub"   -- nama GUI lu

local keyOk = VYX:KeySystem({
    Title = NAME,
    TitleAccent = ACCENT,
    Subtitle = "Key System",
    Logo = ICONS.Logo,
    Keys = { "H4XX-FREE-KEY", "H4XX-VIP-KEY" },     -- SEMENTARA buat tes. Hapus kalau Validate ke website lu udah dipasang
    -- Validate = function(key) return key == "xxx" end,   -- (opsional) cek sendiri, misal lewat HTTP ke server lu
    GetKeyLink = "https://h4xx-key.netlify.app/",   -- tombol "Get Key" = copy link ini (web key generator lu)
    -- DiscordLink = "https://discord.gg/xxxxxx",      -- tombol "Discord" (kalau mau, hapus komentar // di depan)
    SaveKey = true,                                  -- key kesimpen, next time langsung masuk
    Folder = "H4xxHub",
})
if not keyOk then return end   -- ditutup / gagal -> script berhenti

local Window = VYX:CreateWindow({
    Title = NAME,
    TitleAccent = ACCENT,
    Subtitle = "Premium • Modern • Simple",
    Logo = ICONS.Logo,          -- ganti huruf V
    LogoTint = false,           -- true = logo diwarnai sesuai Accent, false = warna asli gambar
    IconTint = true,            -- true = icon tab diwarnai putih/Text (cocok buat icon monochrome putih)
    Folder = "H4xxHub",
    ToggleKey = Enum.KeyCode.RightShift,
})

------------------------------------------------ Main
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
