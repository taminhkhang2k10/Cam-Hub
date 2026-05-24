local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ─── FOV Circle ─────────────────────────────────────────────
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Filled    = false
fovCircle.Color     = Color3.fromRGB(255, 145, 35)
fovCircle.Thickness = 1.5
fovCircle.Radius    = 120
fovCircle.NumSides  = 64

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

-- ✅ Hook Mouse.Hit trực tiếp — Blox Fruit đọc từ đây
local targetOverride = nil

-- Liên tục ghi đè Mouse.Hit về phía target
RunService.RenderStepped:Connect(function()
    if not silentAimEnabled then
        targetOverride = nil
        return
    end

    local target = GetClosestTarget()
    if not target then
        targetOverride = nil
        return
    end

    targetOverride = target

    -- Override Mouse.Hit và Mouse.Target
    local fakeCF = CFrame.new(target.Position)
    pcall(function()
        -- Ghi đè hit position
        local mt = getrawmetatable(Mouse)
        local old = mt.__index
        setreadonly(mt, false)
        mt.__index = function(self, key)
            if key == "Hit" then
                return fakeCF
            elseif key == "Target" then
                return target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") or target
            end
            return old(self, key)
        end
        setreadonly(mt, true)
    end)
end)

-- Khi tắt silent aim thì restore lại Mouse bình thường
local function RestoreMouse()
    pcall(function()
        local mt = getrawmetatable(Mouse)
        setreadonly(mt, false)
        mt.__index = function(self, key)
            return rawget(self, key)
        end
        setreadonly(mt, true)
    end)
end

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
    if not v then
        RestoreMouse()
    end
end)
