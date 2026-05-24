local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ─── Config ─────────────────────────────────────────────────
local aimbotEnabled = false
local aimbotActive  = false
local aimbotKey     = Enum.KeyCode.Y
local bindingKey    = false
local SMOOTH        = 0.15  -- độ mượt (nhỏ = mượt hơn)

-- ─── Cache NPC mỗi 2 giây để không lag ──────────────────────
local npcCache = {}
local lastCache = 0

local function UpdateNPCCache()
    npcCache = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Humanoid") then
            local char = v.Parent
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- kiểm tra không phải player
                local isPlayer = Players:GetPlayerFromCharacter(char)
                if not isPlayer then
                    table.insert(npcCache, hrp)
                end
            end
        end
    end
end

-- Update cache mỗi 2 giây
task.spawn(function()
    while true do
        UpdateNPCCache()
        task.wait(2)
    end
end)

-- ─── Tìm target gần chuột nhất ──────────────────────────────
local function GetTarget()
    local mousePos    = UserInputService:GetMouseLocation()
    local closest     = nil
    local closestDist = math.huge

    local function Check(hrp)
        if not hrp or not hrp.Parent then return end
        local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local screen, visible = Camera:WorldToViewportPoint(hrp.Position)
        if not visible then return end
        local dist = (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = hrp
        end
    end

    -- Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then Check(hrp) end
        end
    end

    -- NPCs từ cache
    for _, hrp in ipairs(npcCache) do
        Check(hrp)
    end

    return closest
end

-- ─── Aimbot — dùng Camera lock (hoạt động mọi executor) ─────
-- Cách này: lock camera nhìn về target → Blox Fruit tính
-- hướng chiêu dựa vào camera → chiêu tự trúng target
local currentTarget = nil

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled or not aimbotActive then
        currentTarget = nil
        return
    end

    -- Cập nhật target mỗi 3 frame để nhẹ hơn
    currentTarget = GetTarget()
    if not currentTarget then return end

    -- Lock camera smooth về phía target
    local camPos = Camera.CFrame.Position
    local goal   = CFrame.lookAt(camPos, currentTarget.Position)
    Camera.CFrame = Camera.CFrame:Lerp(goal, SMOOTH)
end)

-- ─── Keybind toggle ─────────────────────────────────────────
local keyLabel    = nil
local statusLabel = nil

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Đang config key
    if bindingKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            aimbotKey  = input.KeyCode
            bindingKey = false
            if keyLabel then
                keyLabel.Text = "Phím kích hoạt: [" .. input.KeyCode.Name .. "]"
            end
        end
        return
    end

    -- Toggle aimbot bằng key
    if input.KeyCode == aimbotKey and aimbotEnabled then
        aimbotActive = not aimbotActive
        if statusLabel then
            statusLabel.Text = aimbotActive
                and "Trạng thái: BẬT 🟢"
                or  "Trạng thái: TẮT 🔴"
        end
    end
end)

-- ─── Menu ────────────────────────────────────────────────────
local Win = CamHub.CreateWindow({
    Logo = "rbxassetid://84834480482439",
})

local AimbotTab = Win:AddTab("Aimbot")

AimbotTab:AddSection("Aimbot")

AimbotTab:AddToggle("Bật Aimbot", false, function(v)
    aimbotEnabled = v
    if not v then
        aimbotActive = false
        if statusLabel then
            statusLabel.Text = "Trạng thái: TẮT 🔴"
        end
    end
end)

-- Status label
do
    local ref = AimbotTab:AddLabel("Trạng thái: TẮT 🔴")
    task.defer(function()
        -- tìm TextLabel trong page
        for _, v in ipairs(AimbotTab.Page:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Trạng thái: TẮT 🔴" then
                statusLabel = v
                break
            end
        end
    end)
end

-- Key label
do
    AimbotTab:AddLabel("Phím kích hoạt: [" .. aimbotKey.Name .. "]")
    task.defer(function()
        for _, v in ipairs(AimbotTab.Page:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text:find("Phím kích hoạt") then
                keyLabel = v
                break
            end
        end
    end)
end

-- Nút config phím
AimbotTab:AddButton("⚙ Config Phím Kích Hoạt", function()
    bindingKey = true
    if keyLabel then
        keyLabel.Text = "Phím kích hoạt: [Bấm phím bất kỳ...]"
    end
end)

AimbotTab:AddSlider("Độ mượt", 1, 10, 2, function(v)
    SMOOTH = v / 10
end)

AimbotTab:AddLabel("Bật Aimbot → bấm phím để kích hoạt/tắt")
