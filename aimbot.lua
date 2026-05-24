local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()

local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Filled    = false
fovCircle.Color     = Color3.fromRGB(255, 145, 35)
fovCircle.Thickness = 1.5
fovCircle.Radius    = 120
fovCircle.NumSides  = 64

local silentAimEnabled = false

local Win = CamHub.CreateWindow({
    Logo = "rbxassetid://84834480482439",
})

local AimbotTab = Win:AddTab("Aimbot")

AimbotTab:AddSection("FOV Settings")

AimbotTab:AddToggle("Hiện FOV Circle", true, function(v)
    fovCircle.Visible = v
end)

AimbotTab:AddSlider("Kích thước FOV", 50, 400, 120, function(v)
    fovCircle.Radius = v
end)

AimbotTab:AddColorPicker("Màu FOV", Color3.fromRGB(255,145,35), function(color)
    fovCircle.Color = color
end)

AimbotTab:AddSection("Silent Aim")

AimbotTab:AddToggle("Silent Aim", false, function(v)
    silentAimEnabled = v
end)
