local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════
local Config = {
    -- Toggle tổng
    ESPEnabled     = false,

    -- Từng loại
    BoxEnabled     = true,
    NameEnabled    = true,
    HealthEnabled  = true,
    DistEnabled    = true,
    TracerEnabled  = true,

    -- Màu
    PlayerColor    = Color3.fromRGB(255, 145, 35),   -- cam
    NPCColor       = Color3.fromRGB(255, 60,  60),   -- đỏ
    TracerColor    = Color3.fromRGB(255, 145, 35),
    HealthColor    = Color3.fromRGB(80,  220, 80),
    TextColor      = Color3.fromRGB(255, 255, 255),

    -- Misc
    MaxDist        = 1000,   -- chỉ hiện trong tầm này (studs)
    BoxThickness   = 1.5,
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
    l.ZIndex    = 5
    return l
end

local function NewText(color, size)
    local t = Drawing.new("Text")
    t.Visible  = false
    t.Color    = color or Color3.new(1,1,1)
    t.Size     = size  or 13
    t.Font     = Drawing.Fonts.UI
    t.Outline  = true
    t.OutlineColor = Color3.new(0,0,0)
    t.ZIndex   = 6
    return t
end

local function NewQuad(color, thick)
    local q = Drawing.new("Quad")
    q.Visible   = false
    q.Filled    = false
    q.Color     = color or Color3.new(1,1,1)
    q.Thickness = thick or 1.5
    q.ZIndex    = 5
    return q
end

-- ═══════════════════════════════════════════════
--  ESP OBJECT (1 object = 1 character)
-- ═══════════════════════════════════════════════
local function CreateESP(color)
    return {
        -- Box (4 đường)
        BoxTop    = NewLine(color, Config.BoxThickness),
        BoxBot    = NewLine(color, Config.BoxThickness),
        BoxLeft   = NewLine(color, Config.BoxThickness),
        BoxRight  = NewLine(color, Config.BoxThickness),

        -- Name
        Name      = NewText(Config.TextColor, 13),

        -- Distance
        Dist      = NewText(Config.TextColor, 11),

        -- Health bar (2 đường: nền + fill)
        HPBg      = NewLine(Color3.new(0,0,0), 4),
        HPFill    = NewLine(Config.HealthColor, 3),

        -- Tracer
        Tracer    = NewLine(Config.TracerColor, Config.TracerThickness),
    }
end

local function RemoveESP(esp)
    for _, v in pairs(esp) do
        pcall(function() v:Remove() end)
    end
end

local function HideESP(esp)
    for _, v in pairs(esp) do
        v.Visible = false
    end
end

-- ═══════════════════════════════════════════════
--  CACHE
-- ═══════════════════════════════════════════════
local espObjects = {}   -- [character] = esp
local npcList    = {}   -- list HRP của NPC

-- Cập nhật NPC cache mỗi 3 giây
task.spawn(function()
    while true do
        local newList = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Humanoid") and v.Health > 0 then
                local char = v.Parent
                if char and not Players:GetPlayerFromCharacter(char) then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
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
--  GET BOUNDING BOX 2D từ character
-- ═══════════════════════════════════════════════
local function GetBounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- Tính top/bot từ Head và HRP
    local head = char:FindFirstChild("Head")
    local topPart = head or hrp
    local topPos  = topPart.Position + Vector3.new(0, topPart.Size.Y/2 + 0.2, 0)
    local botPos  = hrp.Position    - Vector3.new(0, 3, 0)

    local topScreen, topVis = Camera:WorldToViewportPoint(topPos)
    local botScreen, botVis = Camera:WorldToViewportPoint(botPos)

    if not topVis and not botVis then return nil end

    local topY = topScreen.Y
    local botY = botScreen.Y
    local midX = (topScreen.X + botScreen.X) / 2

    local height = botY - topY
    local width  = math.abs(height) * 0.5   -- proporsi box

    return {
        topY  = topY,
        botY  = botY,
        midX  = midX,
        height= height,
        width = width,
        -- corners
        tl = Vector2.new(midX - width/2, topY),
        tr = Vector2.new(midX + width/2, topY),
        bl = Vector2.new(midX - width/2, botY),
        br = Vector2.new(midX + width/2, botY),
        -- center screen
        center = Vector2.new(midX, (topY+botY)/2),
        -- depth
        depth  = topScreen.Z,
    }
end

-- ═══════════════════════════════════════════════
--  UPDATE 1 ESP OBJECT
-- ═══════════════════════════════════════════════
local function UpdateESP(esp, char, color, label)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum then
        HideESP(esp)
        return
    end

    -- Khoảng cách
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist  = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0

    if dist > Config.MaxDist then
        HideESP(esp)
        return
    end

    local bounds = GetBounds(char)
    if not bounds then
        HideESP(esp)
        return
    end

    local tl, tr, bl, br = bounds.tl, bounds.tr, bounds.bl, bounds.br
    local midX = bounds.midX

    -- ── Box ────────────────────────────────────
    local showBox = Config.ESPEnabled and Config.BoxEnabled
    esp.BoxTop.Visible  = showBox
    esp.BoxBot.Visible  = showBox
    esp.BoxLeft.Visible = showBox
    esp.BoxRight.Visible= showBox
    if showBox then
        esp.BoxTop.From   = tl; esp.BoxTop.To   = tr; esp.BoxTop.Color   = color
        esp.BoxBot.From   = bl; esp.BoxBot.To   = br; esp.BoxBot.Color   = color
        esp.BoxLeft.From  = tl; esp.BoxLeft.To  = bl; esp.BoxLeft.Color  = color
        esp.BoxRight.From = tr; esp.BoxRight.To = br; esp.BoxRight.Color = color
    end

    -- ── Name ───────────────────────────────────
    local showName = Config.ESPEnabled and Config.NameEnabled
    esp.Name.Visible = showName
    if showName then
        esp.Name.Text     = label
        esp.Name.Color    = color
        esp.Name.Position = Vector2.new(midX, tl.Y - 16)
        esp.Name.Center   = true
    end

    -- ── Distance ───────────────────────────────
    local showDist = Config.ESPEnabled and Config.DistEnabled
    esp.Dist.Visible = showDist
    if showDist then
        esp.Dist.Text     = dist .. "m"
        esp.Dist.Color    = Config.TextColor
        esp.Dist.Position = Vector2.new(midX, bl.Y + 2)
        esp.Dist.Center   = true
        esp.Dist.Size     = math.clamp(11 - dist/100, 8, 11)
    end

    -- ── Health Bar (kên trái box) ───────────────
    local showHP = Config.ESPEnabled and Config.HealthEnabled
    esp.HPBg.Visible   = showHP
    esp.HPFill.Visible = showHP
    if showHP then
        local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barH    = bounds.botY - bounds.topY
        local barX    = tl.X - 5

        esp.HPBg.From  = Vector2.new(barX, bounds.topY)
        esp.HPBg.To    = Vector2.new(barX, bounds.botY)
        esp.HPBg.Color = Color3.new(0,0,0)

        local fillBot = bounds.botY
        local fillTop = bounds.botY - barH * hpRatio
        esp.HPFill.From  = Vector2.new(barX, fillTop)
        esp.HPFill.To    = Vector2.new(barX, fillBot)

        -- Warna HP: hijau → kuning → merah
        local r = math.clamp(2 * (1-hpRatio), 0, 1)
        local g = math.clamp(2 * hpRatio,     0, 1)
        esp.HPFill.Color = Color3.new(r, g, 0)
    end

    -- ── Tracer (từ giữa màn hình xuống target) ──
    local showTracer = Config.ESPEnabled and Config.TracerEnabled
    esp.Tracer.Visible = showTracer
    if showTracer then
        local vp = Camera.ViewportSize
        esp.Tracer.From  = Vector2.new(vp.X/2, vp.Y)
        esp.Tracer.To    = Vector2.new(midX, bounds.botY)
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

    -- ── Players ──────────────────────────────
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end

        seen[char] = true

        if not espObjects[char] then
            espObjects[char] = CreateESP(Config.PlayerColor)
        end

        UpdateESP(espObjects[char], char, Config.PlayerColor, player.DisplayName)
    end

    -- ── NPCs ─────────────────────────────────
    for _, char in ipairs(npcList) do
        if not char or not char.Parent then continue end
        seen[char] = true

        if not espObjects[char] then
            espObjects[char] = CreateESP(Config.NPCColor)
        end

        local name = char.Name
        UpdateESP(espObjects[char], char, Config.NPCColor, name)
    end

    -- ── Cleanup character yang sudah pergi ───
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

-- ── Tổng ─────────────────────────────────────
VisualTab:AddSection("ESP Settings")

VisualTab:AddToggle("Bật ESP", false, function(v)
    Config.ESPEnabled = v
    if not v then
        for _, esp in pairs(espObjects) do HideESP(esp) end
    end
end)

-- ── Từng loại ────────────────────────────────
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

-- ── Màu ──────────────────────────────────────
VisualTab:AddSection("Màu sắc")

VisualTab:AddColorPicker("Màu Player", Config.PlayerColor, function(c)
    Config.PlayerColor = c
end)

VisualTab:AddColorPicker("Màu NPC", Config.NPCColor, function(c)
    Config.NPCColor = c
end)

VisualTab:AddColorPicker("Màu Tracer", Config.TracerColor, function(c)
    Config.TracerColor = c
    for _, esp in pairs(espObjects) do
        esp.Tracer.Color = c
    end
end)

-- ── Misc ─────────────────────────────────────
VisualTab:AddSection("Cài đặt khác")

VisualTab:AddSlider("Tầm nhìn tối đa (m)", 100, 2000, 1000, function(v)
    Config.MaxDist = v
end)

VisualTab:AddSlider("Độ dày Box", 1, 5, 2, function(v)
    Config.BoxThickness = v
    for _, esp in pairs(espObjects) do
        esp.BoxTop.Thickness    = v
        esp.BoxBot.Thickness    = v
        esp.BoxLeft.Thickness   = v
        esp.BoxRight.Thickness  = v
    end
end)
