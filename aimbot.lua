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
local aimbotEnabled = false   -- bật/tắt tổng
local aimbotActive  = false   -- toggle khi bấm key
local aimbotKey     = Enum.KeyCode.Q
local bindingKey    = false   -- đang chờ config key không

-- ─── Tìm target gần chuột nhất ──────────────────────────────
local function GetTarget()
    local mousePos    = UserInputService:GetMouseLocation()
    local closest     = nil
    local closestDist = math.huge

    local function Check(char)
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
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
        if p ~= LocalPlayer then Check(p.Character) end
    end

    -- NPCs
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Health > 0 then
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == v.Parent then isPlayer = true break end
            end
            if not isPlayer then Check(v.Parent) end
        end
    end

    return closest
end

-- ─── Aimbot loop (chỉ chạy khi cần) ────────────────────────
local lastRun = 0
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled or not aimbotActive then return end

    -- Giới hạn 30fps để không lag
    local now = tick()
    if now - lastRun < 1/30 then return end
    lastRun = now

    local target = GetTarget()
    if not target then return end

    local screen, visible = Camera:WorldToViewportPoint(target.Position)
    if not visible then return end

    local mouse = UserInputService:GetMouseLocation()
    local dx = screen.X - mouse.X
    local dy = screen.Y - mouse.Y

    -- Smooth: chỉ di 30% mỗi frame để không giật
    mousemoverel(dx * 0.3, dy * 0.3)
end)

-- ─── Key bấm bật/tắt aimbot ─────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Đang config key
    if bindingKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            aimbotKey  = input.KeyCode
            bindingKey = false
            -- cập nhật label key
            if _G.KeyLabel then
                _G.KeyLabel.Text = "Phím: " .. input.KeyCode.Name
            end
        end
        return
    end

    -- Bấm key toggle aimbot
    if input.KeyCode == aimbotKey and aimbotEnabled then
        aimbotActive = not aimbotActive
        if _G.StatusLabel then
            _G.StatusLabel.Text = aimbotActive and "Aimbot: BẬT 🟢" or "Aimbot: TẮT 🔴"
        end
    end
end)

-- ─── Menu ────────────────────────────────────────────────────
local Win = CamHub.CreateWindow({
    Logo = "rbxassetid://84834480482439",
})

local AimbotTab = Win:AddTab("Aimbot")

AimbotTab:AddSection("Aimbot")

-- Toggle bật/tắt tổng
AimbotTab:AddToggle("Bật Aimbot", false, function(v)
    aimbotEnabled = v
    if not v then
        aimbotActive = false
        if _G.StatusLabel then
            _G.StatusLabel.Text = "Aimbot: TẮT 🔴"
        end
    end
end)

-- Label trạng thái
_G.StatusLabel = nil
AimbotTab:AddLabel("Aimbot: TẮT 🔴")

-- Lưu ref label (hack nhỏ để update text)
task.defer(function()
    local page = AimbotTab.Page
    for _, v in ipairs(page:GetChildren()) do
        if v:IsA("TextLabel") and v.Text == "Aimbot: TẮT 🔴" then
            _G.StatusLabel = v
            break
        end
    end
end)

-- Label phím hiện tại
_G.KeyLabel = nil
AimbotTab:AddLabel("Phím: " .. aimbotKey.Name)

task.defer(function()
    local page = AimbotTab.Page
    for _, v in ipairs(page:GetChildren()) do
        if v:IsA("TextLabel") and v.Text:find("Phím:") then
            _G.KeyLabel = v
            break
        end
    end
end)

-- Nút config key
AimbotTab:AddButton("Config Phím Kích Hoạt", function()
    bindingKey = true
    if _G.KeyLabel then
        _G.KeyLabel.Text = "Phím: Bấm phím bất kỳ..."
    end
end)

AimbotTab:AddLabel("Bật Aimbot → bấm phím để toggle")
