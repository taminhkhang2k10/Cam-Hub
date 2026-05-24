--[[
    CAM HUB UI Library v1.2
    Tab 1: Aimbot — FOV Circle + Silent Aim (Blox Fruit)
--]]

local CamHub = {}

-- ─── Services ───────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = Workspace.CurrentCamera

-- ─── Theme ──────────────────────────────────────────────────
local T = {
    Accent       = Color3.fromRGB(255, 145, 35),
    AccentDark   = Color3.fromRGB(210, 105, 10),
    AccentLight  = Color3.fromRGB(255, 175, 90),
    Background   = Color3.fromRGB(14,  13,  18),
    Surface      = Color3.fromRGB(20,  19,  26),
    SurfaceAlt   = Color3.fromRGB(26,  25,  34),
    SidebarBG    = Color3.fromRGB(30,  22,  14),
    SidebarHover = Color3.fromRGB(45,  30,  12),
    TabActive    = Color3.fromRGB(60,  35,  10),
    Border       = Color3.fromRGB(70,  45,  15),
    Text         = Color3.fromRGB(245, 240, 230),
    TextMuted    = Color3.fromRGB(180, 155, 115),
    TextDim      = Color3.fromRGB(100, 80,  50),
    Black        = Color3.fromRGB(0,   0,   0),
}

-- ─── Utility ────────────────────────────────────────────────
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.22,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function Corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function Pad(t, b, l, r, p)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.Parent = p
end

local function Stroke(col, thick, p)
    local s = Instance.new("UIStroke")
    s.Color     = col   or T.Border
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent    = p
    return s
end

-- ─── Drag ───────────────────────────────────────────────────
local function Drag(handle, target)
    local dragging, startMouse, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            startMouse = i.Position
            startPos   = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (
            i.UserInputType == Enum.UserInputType.MouseMovement or
            i.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = i.Position - startMouse
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  FOV CIRCLE (vẽ bằng Drawing API)
-- ════════════════════════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Filled    = false
fovCircle.Color     = Color3.fromRGB(255, 145, 35)  -- cam mặc định
fovCircle.Thickness = 1.5
fovCircle.Radius    = 120
fovCircle.NumSides  = 64

-- Cập nhật vị trí FOV theo chuột liên tục
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
end)

-- ════════════════════════════════════════════════════════════
--  SILENT AIM (Blox Fruit — lock HumanoidRootPart)
-- ════════════════════════════════════════════════════════════
local silentAimEnabled = false
local fovEnabled       = true

-- Tìm target gần nhất trong FOV
local function GetClosestTarget()
    local closest    = nil
    local closestDist = math.huge
    local mousePos   = Vector2.new(Mouse.X, Mouse.Y)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local hum = player.Character:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        -- project ke layar
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

-- Hook Mouse1Click untuk silent aim
-- Cara kerja: redirect ray cast ke arah target
local originalRaycastTarget = nil

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not silentAimEnabled then return end

    local target = GetClosestTarget()
    if not target then return end

    -- Paksa kamera lihat ke target selama klik
    local originalCFrame = Camera.CFrame
    local targetCFrame   = CFrame.lookAt(Camera.CFrame.Position, target.Position)
    Camera.CFrame        = targetCFrame

    -- Kembalikan setelah 1 frame
    task.defer(function()
        Camera.CFrame = originalCFrame
    end)
end)

-- ════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ════════════════════════════════════════════════════════════
function CamHub.CreateWindow(cfg)
    cfg = cfg or {}
    local logoId = cfg.Logo or nil

    local Gui = New("ScreenGui", {
        Name           = "CamHub",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    pcall(function() Gui.Parent = game:GetService("CoreGui") end)
    if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Shadow
    local Shadow = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint  = Vector2.new(0.5, 0.5),
        Position     = UDim2.new(0.5, 0, 0.5, 10),
        Size         = UDim2.new(0, 630, 0, 460),
        Image        = "rbxassetid://6015897843",
        ImageColor3  = Color3.fromRGB(10, 5, 0),
        ImageTransparency = 0.4,
        ScaleType    = Enum.ScaleType.Slice,
        SliceCenter  = Rect.new(49, 49, 450, 450),
    }, Gui)

    -- Main
    local Main = New("Frame", {
        Name             = "Main",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, 590, 0, 420),
        ClipsDescendants = true,
    }, Gui)
    Corner(14, Main)
    Stroke(T.Border, 1.5, Main)

    RunService.RenderStepped:Connect(function()
        Shadow.Position = UDim2.new(
            Main.Position.X.Scale, Main.Position.X.Offset,
            Main.Position.Y.Scale, Main.Position.Y.Offset + 10
        )
    end)

    -- TopBar
    local TopBar = New("Frame", {
        BackgroundColor3 = T.SidebarBG,
        Size = UDim2.new(1, 0, 0, 54),
        ZIndex = 2,
    }, Main)
    Corner(14, TopBar)
    New("Frame", {
        BackgroundColor3 = T.SidebarBG,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size     = UDim2.new(1, 0, 0.5, 0),
        ZIndex   = 2,
    }, TopBar)

    -- Glow line cam
    local GlowLine = New("Frame", {
        BackgroundColor3 = T.Accent,
        Position = UDim2.new(0, 0, 1, -1),
        Size     = UDim2.new(1, 0, 0, 1.5),
        ZIndex   = 3,
    }, TopBar)
    local lg = Instance.new("UIGradient")
    lg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.1, T.Accent),
        ColorSequenceKeypoint.new(0.9, T.Accent),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
    })
    lg.Parent = GlowLine

    -- Logo
    local LogoBox = New("Frame", {
        BackgroundColor3 = T.TabActive,
        Position = UDim2.new(0, 10, 0.5, -17),
        Size     = UDim2.new(0, 34, 0, 34),
        ZIndex   = 4,
    }, TopBar)
    Corner(9, LogoBox)
    Stroke(T.Accent, 1.8, LogoBox)

    if logoId and logoId ~= "" then
        New("ImageLabel", {
            BackgroundTransparency = 1,
            Position  = UDim2.new(0, 3, 0, 3),
            Size      = UDim2.new(1, -6, 1, -6),
            Image     = logoId,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex    = 5,
        }, LogoBox)
    else
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, 0, 1, 0),
            Font       = Enum.Font.GothamBold,
            Text       = "C",
            TextColor3 = T.AccentLight,
            TextSize   = 20,
            ZIndex     = 5,
        }, LogoBox)
    end

    -- Title
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size       = UDim2.new(1, 0, 1, 0),
        Font       = Enum.Font.GothamBold,
        Text       = "Cam Hub",
        TextColor3 = T.Accent,
        TextSize   = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 3,
    }, TopBar)

    -- Close / Min
    local CloseBtn = New("TextButton", {
        BackgroundColor3 = Color3.fromRGB(220, 60, 60),
        AnchorPoint  = Vector2.new(1, 0.5),
        Position     = UDim2.new(1, -12, 0.5, 0),
        Size         = UDim2.new(0, 15, 0, 15),
        Text = "", AutoButtonColor = false, ZIndex = 4,
    }, TopBar)
    Corner(50, CloseBtn)

    local MinBtn = New("TextButton", {
        BackgroundColor3 = T.Accent,
        AnchorPoint  = Vector2.new(1, 0.5),
        Position     = UDim2.new(1, -34, 0.5, 0),
        Size         = UDim2.new(0, 15, 0, 15),
        Text = "", AutoButtonColor = false, ZIndex = 4,
    }, TopBar)
    Corner(50, MinBtn)

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255,90,90)}, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220,60,60)}, 0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        fovCircle.Visible = false
        fovCircle:Remove()
        Tween(Main, {Size = UDim2.new(0,590,0,0)}, 0.28)
        task.delay(0.3, function() Gui:Destroy() end)
    end)

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(Main, {Size = minimized and UDim2.new(0,590,0,54) or UDim2.new(0,590,0,420)}, 0.3)
    end)

    Drag(TopBar, Main)

    -- Sidebar
    local Sidebar = New("Frame", {
        BackgroundColor3 = T.SidebarBG,
        Position = UDim2.new(0, 0, 0, 54),
        Size     = UDim2.new(0, 150, 1, -54),
    }, Main)
    New("Frame", {
        BackgroundColor3 = T.Border,
        Position = UDim2.new(1,-1,0,0),
        Size     = UDim2.new(0,1,1,0),
    }, Sidebar)
    New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3)}, Sidebar)
    Pad(10,10,8,8, Sidebar)

    New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0,1),
        Position    = UDim2.new(0,8,1,-8),
        Size        = UDim2.new(1,-16,0,14),
        Font        = Enum.Font.Gotham,
        Text        = "v1.2  •  Cam Hub",
        TextColor3  = T.TextDim,
        TextSize    = 10,
        Parent      = Sidebar,
    })

    -- Content
    local Content = New("Frame", {
        BackgroundColor3 = T.Background,
        Position = UDim2.new(0,150,0,54),
        Size     = UDim2.new(1,-150,1,-54),
        ClipsDescendants = true,
    }, Main)
    New("ImageLabel", {
        BackgroundTransparency = 1,
        Size      = UDim2.new(1,0,1,0),
        Image     = "rbxassetid://3570695787",
        ImageColor3 = T.Accent,
        ImageTransparency = 0.96,
        ScaleType = Enum.ScaleType.Tile,
        TileSize  = UDim2.new(0,40,0,40),
    }, Content)

    -- ════════════════════
    --  Window Object
    -- ════════════════════
    local Window  = {}
    local tabs    = {}
    local tabBtns = {}
    local activeTab = nil

    local function ActivateTab(tab)
        if activeTab == tab then return end
        if activeTab then
            activeTab.Page.Visible = false
            local old = tabBtns[activeTab]
            if old then
                Tween(old.BG,    {BackgroundColor3 = T.SidebarHover}, 0.2)
                Tween(old.Label, {TextColor3 = T.TextMuted}, 0.2)
                Tween(old.Bar,   {BackgroundTransparency = 1}, 0.2)
            end
        end
        activeTab = tab
        tab.Page.Visible = true
        local btn = tabBtns[tab]
        if btn then
            Tween(btn.BG,    {BackgroundColor3 = T.TabActive}, 0.2)
            Tween(btn.Label, {TextColor3 = T.AccentLight}, 0.2)
            Tween(btn.Bar,   {BackgroundTransparency = 0}, 0.2)
        end
    end

    function Window:AddTab(name, iconId)
        local BtnWrap = New("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1,0,0,38),
            LayoutOrder = #tabs + 1,
        }, Sidebar)

        local BtnBG = New("Frame", {
            BackgroundColor3 = T.SidebarHover,
            Size = UDim2.new(1,0,1,0),
        }, BtnWrap)
        Corner(8, BtnBG)

        local AccBar = New("Frame", {
            BackgroundColor3       = T.Accent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0,0,0.15,0),
            Size     = UDim2.new(0,3,0.7,0),
        }, BtnBG)
        Corner(4, AccBar)

        if iconId then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0,10,0.5,-8),
                Size     = UDim2.new(0,16,0,16),
                Image    = iconId,
                ImageColor3 = T.TextMuted,
            }, BtnBG)
        end

        local BtnLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, iconId and 34 or 14, 0, 0),
            Size     = UDim2.new(1,-40,1,0),
            Font     = Enum.Font.GothamSemibold,
            Text     = name,
            TextColor3     = T.TextMuted,
            TextSize       = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, BtnBG)

        local Click = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0), Text = "",
        }, BtnWrap)

        local Page = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1,0,1,0),
            CanvasSize             = UDim2.new(0,0,0,0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            ScrollBarThickness     = 2,
            ScrollBarImageColor3   = T.Accent,
            ScrollBarImageTransparency = 0.4,
            Visible                = false,
        }, Content)
        Pad(12,12,16,16, Page)
        New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)}, Page)

        local Tab = { Page = Page }
        tabBtns[Tab] = { BG = BtnBG, Label = BtnLabel, Bar = AccBar }
        table.insert(tabs, Tab)

        Click.MouseEnter:Connect(function()
            if activeTab ~= Tab then Tween(BtnBG, {BackgroundColor3 = T.TabActive}, 0.15) end
        end)
        Click.MouseLeave:Connect(function()
            if activeTab ~= Tab then Tween(BtnBG, {BackgroundColor3 = T.SidebarHover}, 0.15) end
        end)
        Click.MouseButton1Click:Connect(function() ActivateTab(Tab) end)
        if #tabs == 1 then ActivateTab(Tab) end

        local function Order() return #Page:GetChildren() end

        -- ── Elements ─────────────────────────
        function Tab:AddSection(title)
            local S = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,26), LayoutOrder = Order(),
            }, Page)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0),
                Font = Enum.Font.GothamBold,
                Text = title:upper(),
                TextColor3 = T.Accent, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, S)
            New("Frame", {
                BackgroundColor3 = T.Border,
                AnchorPoint = Vector2.new(1,0.5),
                Position    = UDim2.new(1,0,0.5,0),
                Size        = UDim2.new(0.55,0,0,1),
            }, S)
        end

        function Tab:AddLabel(text)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,22), LayoutOrder = Order(),
                Font = Enum.Font.Gotham, Text = text,
                TextColor3 = T.TextMuted, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
            }, Page)
        end

        function Tab:AddButton(text, callback)
            local Btn = New("TextButton", {
                BackgroundColor3 = T.Surface,
                Size = UDim2.new(1,0,0,38),
                Text = "", AutoButtonColor = false,
                LayoutOrder = Order(),
            }, Page)
            Corner(8, Btn); Stroke(T.Border, 1, Btn)
            local bar = New("Frame", {BackgroundColor3=T.Accent, Position=UDim2.new(0,0,0.2,0), Size=UDim2.new(0,3,0.6,0)}, Btn)
            Corner(4, bar)
            New("TextLabel", {
                BackgroundTransparency=1, Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-20,1,0),
                Font=Enum.Font.GothamSemibold, Text=text, TextColor3=T.Text, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, Btn)
            Btn.MouseEnter:Connect(function() Tween(Btn,{BackgroundColor3=T.SurfaceAlt},0.15) end)
            Btn.MouseLeave:Connect(function() Tween(Btn,{BackgroundColor3=T.Surface},0.15) end)
            Btn.MouseButton1Down:Connect(function() Tween(Btn,{BackgroundColor3=T.TabActive},0.1) end)
            Btn.MouseButton1Up:Connect(function()
                Tween(Btn,{BackgroundColor3=T.SurfaceAlt},0.1)
                if callback then callback() end
            end)
        end

        function Tab:AddToggle(text, default, callback)
            local state = default or false
            local Row = New("Frame", {
                BackgroundColor3=T.Surface, Size=UDim2.new(1,0,0,38), LayoutOrder=Order(),
            }, Page)
            Corner(8, Row); Stroke(T.Border, 1, Row)
            New("TextLabel", {
                BackgroundTransparency=1, Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-65,1,0),
                Font=Enum.Font.Gotham, Text=text, TextColor3=T.Text, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, Row)
            local Track = New("Frame", {
                AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=state and T.Accent or T.Border,
                Position=UDim2.new(1,-14,0.5,0), Size=UDim2.new(0,40,0,20),
            }, Row)
            Corner(50, Track)
            local Knob = New("Frame", {
                AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=T.Text,
                Position=state and UDim2.new(1,-21,0.5,0) or UDim2.new(0,2,0.5,0),
                Size=UDim2.new(0,17,0,17),
            }, Track)
            Corner(50, Knob)
            local function Update()
                Tween(Track,{BackgroundColor3=state and T.Accent or T.Border},0.2)
                Tween(Knob,{Position=state and UDim2.new(1,-21,0.5,0) or UDim2.new(0,2,0.5,0)},0.2)
            end
            local ref = {}
            New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text=""},Row)
                .MouseButton1Click:Connect(function()
                    state = not state; Update()
                    if callback then callback(state) end
                end)
            function ref:Set(v) state=v; Update(); if callback then callback(state) end end
            function ref:Get() return state end
            return ref
        end

        function Tab:AddSlider(text, min, max, default, callback)
            min=min or 0; max=max or 100
            local val = math.clamp(default or min, min, max)
            local Wrap = New("Frame", {
                BackgroundColor3=T.Surface, Size=UDim2.new(1,0,0,56), LayoutOrder=Order(),
            }, Page)
            Corner(8,Wrap); Stroke(T.Border,1,Wrap); Pad(8,8,14,14,Wrap)
            local Top = New("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,18)}, Wrap)
            New("TextLabel", {
                BackgroundTransparency=1, Size=UDim2.new(0.65,0,1,0),
                Font=Enum.Font.Gotham, Text=text, TextColor3=T.Text, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, Top)
            local ValLbl = New("TextLabel", {
                BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0),
                Position=UDim2.new(1,0,0,0), Size=UDim2.new(0.35,0,1,0),
                Font=Enum.Font.GothamBold, Text=tostring(val),
                TextColor3=T.Accent, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Right,
            }, Top)
            local Track = New("Frame", {
                BackgroundColor3=T.SidebarBG, Position=UDim2.new(0,0,1,-8), Size=UDim2.new(1,0,0,6),
            }, Wrap)
            Corner(50,Track)
            local Fill = New("Frame", {BackgroundColor3=T.Accent, Size=UDim2.new((val-min)/(max-min),0,1,0)}, Track)
            Corner(50,Fill)
            local Thumb = New("Frame", {
                AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=T.AccentLight,
                Position=UDim2.new((val-min)/(max-min),0,0.5,0), Size=UDim2.new(0,14,0,14),
            }, Track)
            Corner(50,Thumb)
            local sliding=false
            local function Set(xr)
                xr=math.clamp(xr,0,1); val=math.round(min+(max-min)*xr)
                Tween(Fill,{Size=UDim2.new(xr,0,1,0)},0.05)
                Tween(Thumb,{Position=UDim2.new(xr,0,0.5,0)},0.05)
                ValLbl.Text=tostring(val)
                if callback then callback(val) end
            end
            Track.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    sliding=true; Set((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                    Set((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    sliding=false
                end
            end)
            local ref={}
            function ref:Set(v) Set((math.clamp(v,min,max)-min)/(max-min)) end
            function ref:Get() return val end
            return ref
        end

        -- ── Color Picker đặc biệt cho FOV ─────
        function Tab:AddColorPicker(text, default, callback)
            local color = default or Color3.fromRGB(255,145,35)
            local r,g,b = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)

            local Wrap = New("Frame", {
                BackgroundColor3=T.Surface, Size=UDim2.new(1,0,0,130), LayoutOrder=Order(),
            }, Page)
            Corner(8,Wrap); Stroke(T.Border,1,Wrap); Pad(10,10,14,14,Wrap)

            New("TextLabel", {
                BackgroundTransparency=1, Size=UDim2.new(1,0,0,18),
                Font=Enum.Font.GothamSemibold, Text=text,
                TextColor3=T.Text, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, Wrap)

            -- Preview swatch
            local Swatch = New("Frame", {
                AnchorPoint=Vector2.new(1,0),
                Position=UDim2.new(1,0,0,0),
                BackgroundColor3=color,
                Size=UDim2.new(0,40,0,18),
            }, Wrap)
            Corner(6,Swatch); Stroke(T.Border,1,Swatch)

            local function MakeRGBSlider(label, yOffset, initVal, colorCallback)
                local SliderWrap = New("Frame", {
                    BackgroundTransparency=1,
                    Position=UDim2.new(0,0,0,yOffset),
                    Size=UDim2.new(1,0,0,24),
                }, Wrap)
                New("TextLabel", {
                    BackgroundTransparency=1,
                    Size=UDim2.new(0,16,1,0),
                    Font=Enum.Font.GothamBold,
                    Text=label, TextColor3=T.Accent, TextSize=11,
                    TextXAlignment=Enum.TextXAlignment.Left,
                }, SliderWrap)
                local ValL = New("TextLabel", {
                    BackgroundTransparency=1,
                    AnchorPoint=Vector2.new(1,0),
                    Position=UDim2.new(1,0,0,0),
                    Size=UDim2.new(0,30,1,0),
                    Font=Enum.Font.GothamBold,
                    Text=tostring(initVal), TextColor3=T.AccentLight, TextSize=11,
                    TextXAlignment=Enum.TextXAlignment.Right,
                }, SliderWrap)
                local Track = New("Frame", {
                    BackgroundColor3=T.SidebarBG,
                    Position=UDim2.new(0,20,0.5,-3),
                    Size=UDim2.new(1,-56,0,6),
                }, SliderWrap)
                Corner(50,Track)
                local Fill = New("Frame", {
                    BackgroundColor3=T.Accent,
                    Size=UDim2.new(initVal/255,0,1,0),
                }, Track)
                Corner(50,Fill)
                local Thumb = New("Frame", {
                    AnchorPoint=Vector2.new(0.5,0.5),
                    BackgroundColor3=T.AccentLight,
                    Position=UDim2.new(initVal/255,0,0.5,0),
                    Size=UDim2.new(0,11,0,11),
                }, Track)
                Corner(50,Thumb)

                local sliding=false
                local function Set(xr)
                    xr=math.clamp(xr,0,1)
                    local v=math.round(xr*255)
                    Tween(Fill,{Size=UDim2.new(xr,0,1,0)},0.05)
                    Tween(Thumb,{Position=UDim2.new(xr,0,0.5,0)},0.05)
                    ValL.Text=tostring(v)
                    colorCallback(v)
                    color=Color3.fromRGB(r,g,b)
                    Swatch.BackgroundColor3=color
                    if callback then callback(color) end
                end
                Track.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        sliding=true; Set((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
                        Set((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
                end)
            end

            MakeRGBSlider("R", 24, r, function(v) r=v end)
            MakeRGBSlider("G", 52, g, function(v) g=v end)
            MakeRGBSlider("B", 80, b, function(v) b=v end)

            local ref={}
            function ref:Get() return color end
            return ref
        end

        return Tab
    end

    -- Animate open
    Main.Size = UDim2.new(0,590,0,0)
    Tween(Main, {Size=UDim2.new(0,590,0,420)}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return Window
end

return CamHub

-- ══════════════════════════════════════════════════════
--  SCRIPT CHÍNH — paste bên dưới sau khi load library
-- ══════════════════════════════════════════════════════
--[[

local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/CamHub.lua"
))()

local Win = CamHub.CreateWindow({
    Logo = "rbxassetid://84834480482439",
})

-- ── Tab 1: Aimbot ─────────────────────────────────────
local AimbotTab = Win:AddTab("Aimbot")

AimbotTab:AddSection("FOV Settings")

-- Toggle bật/tắt FOV Circle
AimbotTab:AddToggle("Hiện FOV Circle", true, function(v)
    fovCircle.Visible = v
end)

-- Chỉnh kích thước FOV
AimbotTab:AddSlider("Kích thước FOV", 50, 400, 120, function(v)
    fovCircle.Radius = v
end)

-- Chọn màu FOV
AimbotTab:AddColorPicker("Màu FOV", Color3.fromRGB(255,145,35), function(color)
    fovCircle.Color = color
end)

AimbotTab:AddSection("Silent Aim")

-- Toggle Silent Aim
AimbotTab:AddToggle("Silent Aim", false, function(v)
    silentAimEnabled = v
end)

]]
