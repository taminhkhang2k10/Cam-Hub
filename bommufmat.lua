local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()

local RunService  = game:GetService("RunService")
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════
local Config = {
    ESPEnabled     = false,

    -- ✅ Bật/tắt từng loại target
    PlayerESP      = true,
    NPCESP         = true,

    BoxEnabled     = true,
    NameEnabled    = true,
    HealthEnabled  = true,
    DistEnabled    = true,
    TracerEnabled  = true,

    PlayerColor    = Color3.fromRGB(255, 145, 35),
    NPCColor       = Color3.fromRGB(255, 60,  60),
    TracerColor    = Color3.fromRGB(255, 145, 35),
    TextColor      = Color3.fromRGB(255, 255, 255),

    MaxDist        = 1000,
    BoxThickness   = 1.5,
    BoxScale       = 1.0,
    BoxFillOpacity = 0,
    TracerThickness= 1,
}

-- ═══════════════════════════════════════════════
--  DRAWING HELPERS
-- ═══════════════════════════════════════════════
local function NewLine(color, thick)
    local l = Drawing.new("Line")
    l.Visible   = false
    l.Color     = color or Color3.new(1,1,1)
    l.Thickness = thick or 1
    l.ZIndex    = 4
    return l
end

local function NewText(color, size)
    local t = Drawing.new("Text")
    t.Visible      = false
    t.Color        = color or Color3.new(1,1,1)
    t.Size         = size  or 13
    t.Font         = Drawing.Fonts.UI
    t.Outline      = true
    t.OutlineColor = Color3.new(0,0,0)
    t.ZIndex       = 6
    return t
end

local function NewQuad(color)
    local q = Drawing.new("Quad")
    q.Visible      = false
    q.Filled       = true
    q.Color        = color or Color3.new(1,1,1)
    q.Transparency = 1
    q.ZIndex       = 3
    return q
end

-- ═══════════════════════════════════════════════
--  ESP OBJECT
-- ═══════════════════════════════════════════════
local function CreateESP(color)
    return {
        BoxFill  = NewQuad(color),
        BoxTop   = NewLine(color, Config.BoxThickness),
        BoxBot   = NewLine(color, Config.BoxThickness),
        BoxLeft  = NewLine(color, Config.BoxThickness),
        BoxRight = NewLine(color, Config.BoxThickness),
        Name     = NewText(Config.TextColor, 13),
        Dist     = NewText(Config.TextColor, 11),
        HPBg     = NewLine(Color3.new(0,0,0), 4),
        HPFill   = NewLine(Color3.fromRGB(80,220,80), 3),
        Tracer   = NewLine(Config.TracerColor, Config.TracerThickness),
    }
end

local function RemoveESP(esp)
    for _, v in pairs(esp) do pcall(function() v:Remove() end) end
end

local function HideESP(esp)
    for _, v in pairs(esp) do v.Visible = false end
end

-- ═══════════════════════════════════════════════
--  CACHE NPC
-- ═══════════════════════════════════════════════
local espObjects = {}
local npcList    = {}

task.spawn(function()
    while true do
        local newList = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Humanoid") and v.Health > 0 then
                local char = v.Parent
                if char and not Players:GetPlayerFromCharacter(char) then
                    if char:FindFirstChild("HumanoidRootPart") then
                        table.insert(newList, char)
                    end
                end
            end
        end
        npcList = newList
        task.wait(3)
    end
end)

-- ═══════════════════════════════════════════════
--  GET BOUNDS 2D
-- ═══════════════════════════════════════════════
local function GetBounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local head   = char:FindFirstChild("Head")
    local topPos = (head or hrp).Position + Vector3.new(0, (head or hrp).Size.Y/2 + 0.2, 0)
    local botPos = hrp.Position - Vector3.new(0, 3, 0)

    local topScreen, topVis = Camera:WorldToViewportPoint(topPos)
    local botScreen, botVis = Camera:WorldToViewportPoint(botPos)
    if not topVis and not botVis then return nil end

    local midX   = (topScreen.X + botScreen.X) / 2
    local height = (botScreen.Y - topScreen.Y) * Config.BoxScale
    local width  = math.abs(height) * 0.5
    local centerY= (topScreen.Y + botScreen.Y) / 2
    local newTop = centerY - height / 2
    local newBot = centerY + height / 2

    return {
        topY = newTop, botY = newBot,
        midX = midX,   height = height, width = width,
        tl = Vector2.new(midX - width/2, newTop),
        tr = Vector2.new(midX + width/2, newTop),
        bl = Vector2.new(midX - width/2, newBot),
        br = Vector2.new(midX + width/2, newBot),
        center = Vector2.new(midX, centerY),
    }
end

-- ═══════════════════════════════════════════════
--  UPDATE ESP
-- ═══════════════════════════════════════════════
local function UpdateESP(esp, char, color, label)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then HideESP(esp); return end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist  = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
    if dist > Config.MaxDist then HideESP(esp); return end

    local b = GetBounds(char)
    if not b then HideESP(esp); return end

    local showBox = Config.ESPEnabled and Config.BoxEnabled

    -- Fill
    esp.BoxFill.Visible = showBox and Config.BoxFillOpacity > 0
    if showBox and Config.BoxFillOpacity > 0 then
        esp.BoxFill.PointA     = b.tl
        esp.BoxFill.PointB     = b.tr
        esp.BoxFill.PointC     = b.br
        esp.BoxFill.PointD     = b.bl
        esp.BoxFill.Color      = color
        esp.BoxFill.Transparency = 1 - Config.BoxFillOpacity
    end

    -- Box lines
    esp.BoxTop.Visible   = showBox
    esp.BoxBot.Visible   = showBox
    esp.BoxLeft.Visible  = showBox
    esp.BoxRight.Visible = showBox
    if showBox then
        esp.BoxTop.From    = b.tl; esp.BoxTop.To    = b.tr; esp.BoxTop.Color    = color
        esp.BoxBot.From    = b.bl; esp.BoxBot.To    = b.br; esp.BoxBot.Color    = color
        esp.BoxLeft.From   = b.tl; esp.BoxLeft.To   = b.bl; esp.BoxLeft.Color   = color
        esp.BoxRight.From  = b.tr; esp.BoxRight.To  = b.br; esp.BoxRight.Color  = color
    end

    -- Name
    local showName = Config.ESPEnabled and Config.NameEnabled
    esp.Name.Visible = showName
    if showName then
        esp.Name.Text     = label
        esp.Name.Color    = color
        esp.Name.Position = Vector2.new(b.midX, b.topY - 16)
        esp.Name.Center   = true
    end

    -- Distance
    local showDist = Config.ESPEnabled and Config.DistEnabled
    esp.Dist.Visible = showDist
    if showDist then
        esp.Dist.Text     = "[" .. dist .. "m]"
        esp.Dist.Color    = Config.TextColor
        esp.Dist.Position = Vector2.new(b.midX, b.botY + 2)
        esp.Dist.Center   = true
        esp.Dist.Size     = math.clamp(11 - dist/150, 7, 11)
    end

    -- HP Bar
    local showHP = Config.ESPEnabled and Config.HealthEnabled
    esp.HPBg.Visible   = showHP
    esp.HPFill.Visible = showHP
    if showHP then
        local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barX    = b.tl.X - 5
        esp.HPBg.From    = Vector2.new(barX, b.topY)
        esp.HPBg.To      = Vector2.new(barX, b.botY)
        esp.HPBg.Color   = Color3.new(0,0,0)
        esp.HPFill.From  = Vector2.new(barX, b.botY - b.height * hpRatio)
        esp.HPFill.To    = Vector2.new(barX, b.botY)
        local r = math.clamp(2*(1-hpRatio), 0, 1)
        local g = math.clamp(2*hpRatio, 0, 1)
        esp.HPFill.Color = Color3.new(r, g, 0)
    end

    -- Tracer
    local showTracer = Config.ESPEnabled and Config.TracerEnabled
    esp.Tracer.Visible = showTracer
    if showTracer then
        local vp = Camera.ViewportSize
        esp.Tracer.From  = Vector2.new(vp.X/2, vp.Y)
        esp.Tracer.To    = Vector2.new(b.midX, b.botY)
        esp.Tracer.Color = Config.TracerColor
    end
end

-- ═══════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not Config.ESPEnabled then
        for _, esp in pairs(espObjects) do HideESP(esp) end
        return
    end

    local seen = {}

    -- ✅ Players (chỉ chạy nếu PlayerESP bật)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        seen[char] = true
        if Config.PlayerESP then
            if not espObjects[char] then espObjects[char] = CreateESP(Config.PlayerColor) end
            UpdateESP(espObjects[char], char, Config.PlayerColor, player.DisplayName)
        else
            if espObjects[char] then HideESP(espObjects[char]) end
        end
    end

    -- ✅ NPCs (chỉ chạy nếu NPCESP bật)
    for _, char in ipairs(npcList) do
        if not char or not char.Parent then continue end
        seen[char] = true
        if Config.NPCESP then
            if not espObjects[char] then espObjects[char] = CreateESP(Config.NPCColor) end
            UpdateESP(espObjects[char], char, Config.NPCColor, char.Name)
        else
            if espObjects[char] then HideESP(espObjects[char]) end
        end
    end

    -- Cleanup
    for char, esp in pairs(espObjects) do
        if not seen[char] then
            RemoveESP(esp)
            espObjects[char] = nil
        end
    end
end)

-- ═══════════════════════════════════════════════
--  MENU
-- ═══════════════════════════════════════════════
local Win = CamHub.CreateWindow({
    Logo = "rbxassetid://84834480482439",
})

local VisualTab = Win:AddTab("Visual")

VisualTab:AddSection("ESP Settings")

VisualTab:AddToggle("Bật ESP", false, function(v)
    Config.ESPEnabled = v
    if not v then for _, esp in pairs(espObjects) do HideESP(esp) end end
end)

-- ✅ Bật/tắt Player và NPC riêng
VisualTab:AddToggle("Enable Player ESP", true, function(v)
    Config.PlayerESP = v
end)

VisualTab:AddToggle("Enable NPC ESP", true, function(v)
    Config.NPCESP = v
end)

VisualTab:AddSection("Loại ESP")

VisualTab:AddToggle("Box", true, function(v)
    Config.BoxEnabled = v
end)

VisualTab:AddToggle("Tên (Name)", true, function(v)
    Config.NameEnabled = v
end)

VisualTab:AddToggle("Thanh máu (HP)", true, function(v)
    Config.HealthEnabled = v
end)

VisualTab:AddToggle("Khoảng cách", true, function(v)
    Config.DistEnabled = v
end)

VisualTab:AddToggle("Tracer", true, function(v)
    Config.TracerEnabled = v
end)

VisualTab:AddSection("Màu sắc")

VisualTab:AddColorPicker("Màu Player", Config.PlayerColor, function(c)
    Config.PlayerColor = c
end)

VisualTab:AddColorPicker("Màu NPC", Config.NPCColor, function(c)
    Config.NPCColor = c
end)

VisualTab:AddColorPicker("Màu Tracer", Config.TracerColor, function(c)
    Config.TracerColor = c
    for _, esp in pairs(espObjects) do esp.Tracer.Color = c end
end)

VisualTab:AddSection("Cài đặt khác")

VisualTab:AddSlider("Tầm nhìn tối đa (m)", 100, 2000, 1000, function(v)
    Config.MaxDist = v
end)

VisualTab:AddSlider("Kích thước Box", 50, 200, 100, function(v)
    Config.BoxScale = v / 100
end)

VisualTab:AddSlider("Độ dày viền Box", 1, 5, 2, function(v)
    Config.BoxThickness = v
    for _, esp in pairs(espObjects) do
        esp.BoxTop.Thickness   = v
        esp.BoxBot.Thickness   = v
        esp.BoxLeft.Thickness  = v
        esp.BoxRight.Thickness = v
    end
end)

VisualTab:AddSlider("Độ tô kín Box (0-10)", 0, 10, 0, function(v)
    Config.BoxFillOpacity = v / 10
end)
