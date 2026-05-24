local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ─── FOV Circle ─────────────────────────────────────────────
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Filled    = false
fovCircle.Color     = Color3.fromRGB(255, 145, 35)
fovCircle.Thickness = 1.5
fovCircle.Radius    = 120
fovCircle.NumSides  = 64

-- ✅ Fix lệch: dùng UserInputService thay Mouse
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
end)

-- ─── Silent Aim ─────────────────────────────────────────────
local silentAimEnabled = false

local function GetClosestTarget()
    local mousePos    = UserInputService:GetMouseLocation()
    local closest     = nil
    local closestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist <= fovCircle.Radius and dist < closestDist then
            closestDist = dist
            closest     = hrp
        end
    end

    return closest
end

-- ✅ Hook đúng cách cho Blox Fruit
-- Blox Fruit dùng Mouse.Hit để tính hướng chiêu
-- Ta override bằng cách redirect Camera CFrame liên tục khi giữ click
local aiming = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not silentAimEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local target = GetClosestTarget()
    if not target then return end

    aiming = true

    -- Redirect camera liên tục trong khi bấm
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not aiming then
            conn:Disconnect()
            return
        end
        local targetPos = target.Position
        local camPos    = Camera.CFrame.Position
        Camera.CFrame   = CFrame.lookAt(camPos, targetPos)
    end)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        aiming = false
    end
end)

-- ─── Menu ────────────────────────────────────────────────────
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
