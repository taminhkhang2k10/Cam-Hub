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

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
end)

-- ─── Config ─────────────────────────────────────────────────
local silentAimEnabled = false

-- ─── Tìm target gần nhất (Player + NPC) ─────────────────────
local function GetClosestTarget()
    local mousePos    = UserInputService:GetMouseLocation()
    local closest     = nil
    local closestDist = math.huge

    -- Hàm check 1 character
    local function CheckChar(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then return end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist <= fovCircle.Radius and dist < closestDist then
            closestDist = dist
            closest     = hrp
        end
    end

    -- ✅ Check Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if player.Character then
            CheckChar(player.Character)
        end
    end

    -- ✅ Check NPCs (tất cả Humanoid trong Workspace)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local char = obj.Parent
            -- tránh check lại player
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == char then
                    isPlayer = true
                    break
                end
            end
            if not isPlayer then
                CheckChar(char)
            end
        end
    end

    return closest
end

-- ─── Lock chuột về target liên tục ──────────────────────────
RunService.RenderStepped:Connect(function()
    if not silentAimEnabled then return end

    local target = GetClosestTarget()
    if not target then return end

    -- Project vị trí target ra màn hình
    local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
    if not onScreen then return end

    -- ✅ Di chuyển con trỏ chuột về phía target
    mousemoverel(
        screenPos.X - UserInputService:GetMouseLocation().X,
        screenPos.Y - UserInputService:GetMouseLocation().Y
    )
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

AimbotTab:AddLabel("Bật Silent Aim → chuột tự hút vào target trong FOV")
