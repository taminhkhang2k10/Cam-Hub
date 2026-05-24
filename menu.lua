local CamHub = {}

-- ─── Services ───────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- ─── Theme ──────────────────────────────────────────────────
local T = {
    -- Cam chủ đạo
    Accent      = Color3.fromRGB(255, 140, 30),    -- cam sáng
    AccentDark  = Color3.fromRGB(200, 100, 10),    -- cam đậm (chữ title)
    AccentDim   = Color3.fromRGB(180, 80,  5),     -- cam tối hover
    AccentGlow  = Color3.fromRGB(255, 170, 80),    -- cam nhạt glow

    -- Nền
    Background  = Color3.fromRGB(15,  15,  20),    -- nền chính
    Surface     = Color3.fromRGB(22,  22,  30),    -- card/sidebar
    SurfaceAlt  = Color3.fromRGB(28,  28,  38),    -- hover

    -- Viền
    Border      = Color3.fromRGB(45,  40,  55),
    BorderAccent= Color3.fromRGB(255, 140, 30),

    -- Chữ
    Text        = Color3.fromRGB(240, 240, 250),
    TextMuted   = Color3.fromRGB(140, 135, 155),
    TextDim     = Color3.fromRGB(75,  70,  90),

    -- Tab
    TabActive   = Color3.fromRGB(255, 140, 30),
    TabInactive = Color3.fromRGB(28,  28,  38),

    Black       = Color3.fromRGB(0, 0, 0),
}

-- ─── Utility ────────────────────────────────────────────────
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.25,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function Corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function Stroke(col, thick, p)
    local s = Instance.new("UIStroke")
    s.Color     = col   or T.Border
    s.Thickness = thick or 1
    s.Parent    = p
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
--   CamHub.CreateWindow({ Logo = "rbxassetid://..." })
-- ════════════════════════════════════════════════════════════
function CamHub.CreateWindow(cfg)
    cfg = cfg or {}
    local logoId = cfg.Logo or nil

    -- ── ScreenGui ───────────────────────────────
    local Gui = New("ScreenGui", {
        Name            = "CamHub",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset  = true,
    })
    pcall(function() Gui.Parent = game:GetService("CoreGui") end)
    if not Gui.Parent then
        Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Shadow ──────────────────────────────────
    local Shadow = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint  = Vector2.new(0.5, 0.5),
        Position     = UDim2.new(0.5, 0, 0.5, 8),
        Size         = UDim2.new(0, 620, 0, 450),
        Image        = "rbxassetid://6015897843",
        ImageColor3  = T.Black,
        ImageTransparency = 0.45,
        ScaleType    = Enum.ScaleType.Slice,
        SliceCenter  = Rect.new(49, 49, 450, 450),
    }, Gui)

    -- ── Main Frame ──────────────────────────────
    local Main = New("Frame", {
        Name             = "Main",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, 580, 0, 410),
        ClipsDescendants = true,
    }, Gui)
    Corner(14, Main)
    Stroke(T.Border, 1.2, Main)

    -- sync shadow position saat drag
    RunService.RenderStepped:Connect(function()
        Shadow.Position = UDim2.new(
            Main.Position.X.Scale, Main.Position.X.Offset,
            Main.Position.Y.Scale, Main.Position.Y.Offset + 8
        )
    end)

    -- ── Top Bar ─────────────────────────────────
    local TopBar = New("Frame", {
        Name             = "TopBar",
        BackgroundColor3 = T.Surface,
        Size             = UDim2.new(1, 0, 0, 52),
    }, Main)
    -- round only top corners
    Corner(14, TopBar)
    New("Frame", {
        BackgroundColor3 = T.Surface,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
    }, TopBar)

    -- glow line bawah topbar
    local GlowLine = New("Frame", {
        BackgroundColor3 = T.Accent,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0,
    }, TopBar)
    -- gradient fade ke tepi
    local lg = Instance.new("UIGradient")
    lg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.15, T.Accent),
        ColorSequenceKeypoint.new(0.85, T.Accent),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
    })
    lg.Rotation = 0
    lg.Parent   = GlowLine

    -- ── Logo (kiri atas) ────────────────────────
    local LogoContainer = New("Frame", {
        BackgroundColor3 = T.SurfaceAlt,
        Position         = UDim2.new(0, 12, 0.5, -16),
        Size             = UDim2.new(0, 32, 0, 32),
    }, TopBar)
    Corner(8, LogoContainer)
    Stroke(T.Accent, 1.5, LogoContainer)

    if logoId and logoId ~= "" then
        New("ImageLabel", {
            BackgroundTransparency = 1,
            Size  = UDim2.new(1, -4, 1, -4),
            Position = UDim2.new(0, 2, 0, 2),
            Image = logoId,
            ScaleType = Enum.ScaleType.Fit,
        }, LogoContainer)
    else
        -- default monogram "C" warna cam
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size  = UDim2.new(1, 0, 1, 0),
            Font  = Enum.Font.GothamBold,
            Text  = "C",
            TextColor3 = T.Accent,
            TextSize   = 18,
        }, LogoContainer)
    end

    -- ── Title "Cam Hub" (tengah) ─────────────────
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size  = UDim2.new(1, 0, 1, 0),
        Font  = Enum.Font.GothamBold,
        Text  = "Cam Hub",
        TextColor3 = T.AccentDark,
        TextSize   = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, TopBar)

    -- ── Nút điều khiển (phải) ───────────────────
    -- Close
    local CloseBtn = New("TextButton", {
        BackgroundColor3 = Color3.fromRGB(255, 65, 65),
        AnchorPoint = Vector2.new(1, 0.5),
        Position    = UDim2.new(1, -14, 0.5, 0),
        Size        = UDim2.new(0, 14, 0, 14),
        Text        = "",
        AutoButtonColor = false,
    }, TopBar)
    Corner(50, CloseBtn)

    -- Minimize
    local MinBtn = New("TextButton", {
        BackgroundColor3 = Color3.fromRGB(255, 190, 40),
        AnchorPoint = Vector2.new(1, 0.5),
        Position    = UDim2.new(1, -34, 0.5, 0),
        Size        = UDim2.new(0, 14, 0, 14),
        Text        = "",
        AutoButtonColor = false,
    }, TopBar)
    Corner(50, MinBtn)

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 65, 65)}, 0.15)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, {Size = UDim2.new(0, 580, 0, 0)}, 0.3)
        task.delay(0.32, function() Gui:Destroy() end)
    end)

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(Main, {
            Size = minimized
                and UDim2.new(0, 580, 0, 52)
                or  UDim2.new(0, 580, 0, 410)
        }, 0.3, Enum.EasingStyle.Quart)
    end)

    -- ── Drag ────────────────────────────────────
    Drag(TopBar, Main)

    -- ── Sidebar ─────────────────────────────────
    local Sidebar = New("Frame", {
        Name             = "Sidebar",
        BackgroundColor3 = T.Surface,
        Position         = UDim2.new(0, 0, 0, 52),
        Size             = UDim2.new(0, 148, 1, -52),
    }, Main)
    -- garis kanan sidebar
    New("Frame", {
        BackgroundColor3 = T.Border,
        Position         = UDim2.new(1, -1, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
    }, Sidebar)

    New("UIListLayout", {
        SortOrder         = Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, 3),
    }, Sidebar)
    Pad(10, 10, 8, 8, Sidebar)

    -- Separator label ở sidebar bawah
    local VersionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint  = Vector2.new(0, 1),
        Position     = UDim2.new(0, 0, 1, -8),
        Size         = UDim2.new(1, 0, 0, 16),
        Font         = Enum.Font.Gotham,
        Text         = "v1.0  •  Cam Hub",
        TextColor3   = T.TextDim,
        TextSize     = 10,
        Parent       = Sidebar,
    })

    -- ── Content Area ────────────────────────────
    local Content = New("Frame", {
        Name             = "Content",
        BackgroundColor3 = T.Background,
        Position         = UDim2.new(0, 148, 0, 52),
        Size             = UDim2.new(1, -148, 1, -52),
        ClipsDescendants = true,
    }, Main)

    -- subtle dot pattern background
    New("ImageLabel", {
        BackgroundTransparency = 1,
        Size  = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://3570695787",
        ImageTransparency = 0.97,
        ImageColor3 = T.Accent,
        ScaleType   = Enum.ScaleType.Tile,
        TileSize    = UDim2.new(0, 40, 0, 40),
    }, Content)

    -- ════════════════════════════════════════════
    --   Window Object
    -- ════════════════════════════════════════════
    local Window    = {}
    local tabs      = {}
    local tabBtns   = {}
    local activeTab = nil

    local function ActivateTab(tab)
        if activeTab == tab then return end
        -- deactivate old
        if activeTab then
            activeTab.Page.Visible = false
            local oldBtn = tabBtns[activeTab]
            if oldBtn then
                Tween(oldBtn.BG, {BackgroundColor3 = T.TabInactive}, 0.2)
                Tween(oldBtn.Label, {TextColor3 = T.TextMuted}, 0.2)
                Tween(oldBtn.Bar, {BackgroundTransparency = 1}, 0.2)
                Tween(oldBtn.Icon, {ImageColor3 = T.TextMuted}, 0.2)
            end
        end
        activeTab = tab
        tab.Page.Visible = true
        local btn = tabBtns[tab]
        if btn then
            Tween(btn.BG,    {BackgroundColor3 = Color3.fromRGB(255,140,30)}, 0.2)
            Tween(btn.Label, {TextColor3 = T.Text}, 0.2)
            Tween(btn.Bar,   {BackgroundTransparency = 0}, 0.2)
            Tween(btn.Icon,  {ImageColor3 = T.Text}, 0.2)
        end
    end

    -- ── Window:AddTab(name, icon) ────────────────
    function Window:AddTab(name, iconId)
        -- ─ Tab Button ─────────────────────────
        local BtnFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 38),
            LayoutOrder = #tabs + 1,
        }, Sidebar)

        local BtnBG = New("Frame", {
            Name             = "BG",
            BackgroundColor3 = T.TabInactive,
            Size             = UDim2.new(1, 0, 1, 0),
        }, BtnFrame)
        Corner(8, BtnBG)

        -- accent bar kiri
        local AccBar = New("Frame", {
            Name             = "Bar",
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.15, 0),
            Size     = UDim2.new(0, 3, 0.7, 0),
        }, BtnBG)
        Corner(4, AccBar)

        -- icon
        local IconImg = New("ImageLabel", {
            Name             = "Icon",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, -8),
            Size     = UDim2.new(0, 16, 0, 16),
            Image    = iconId or "rbxassetid://3926305904",
            ImageColor3 = T.TextMuted,
        }, BtnBG)

        -- label
        local BtnLabel = New("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 34, 0, 0),
            Size     = UDim2.new(1, -40, 1, 0),
            Font     = Enum.Font.GothamSemibold,
            Text     = name,
            TextColor3 = T.TextMuted,
            TextSize   = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, BtnBG)

        -- click area
        local ClickArea = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
        }, BtnFrame)

        -- ─ Content Page ───────────────────────
        local Page = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            ScrollBarThickness     = 2,
            ScrollBarImageColor3   = T.Accent,
            ScrollBarImageTransparency = 0.3,
            Visible                = false,
        }, Content)
        Pad(12, 12, 16, 16, Page)
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 6),
        }, Page)

        local Tab = { Page = Page }
        tabBtns[Tab] = {
            BG    = BtnBG,
            Label = BtnLabel,
            Bar   = AccBar,
            Icon  = IconImg,
        }
        table.insert(tabs, Tab)

        ClickArea.MouseEnter:Connect(function()
            if activeTab ~= Tab then
                Tween(BtnBG, {BackgroundColor3 = T.SurfaceAlt}, 0.15)
            end
        end)
        ClickArea.MouseLeave:Connect(function()
            if activeTab ~= Tab then
                Tween(BtnBG, {BackgroundColor3 = T.TabInactive}, 0.15)
            end
        end)
        ClickArea.MouseButton1Click:Connect(function()
            ActivateTab(Tab)
        end)

        if #tabs == 1 then ActivateTab(Tab) end

        -- ── Element helpers ────────────────────
        local function Order()
            return #Page:GetChildren()
        end

        function Tab:AddSection(title)
            local S = New("Frame", {
                BackgroundTransparency = 1,
                Size        = UDim2.new(1, 0, 0, 28),
                LayoutOrder = Order(),
            }, Page)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = title:upper(),
                TextColor3 = T.Accent,
                TextSize   = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, S)
            local line = New("Frame", {
                BackgroundColor3 = T.Border,
                AnchorPoint = Vector2.new(1, 0.5),
                Position    = UDim2.new(1, 0, 0.5, 0),
                Size        = UDim2.new(0.48, 0, 0, 1),
            }, S)
        end

        function Tab:AddButton(text, callback)
            local Btn = New("TextButton", {
                BackgroundColor3 = T.Surface,
                Size        = UDim2.new(1, 0, 0, 38),
                Text        = "",
                AutoButtonColor = false,
                LayoutOrder = Order(),
            }, Page)
            Corner(8, Btn)
            Stroke(T.Border, 1, Btn)

            New("Frame", {
                BackgroundColor3 = T.Accent,
                Position = UDim2.new(0, 0, 0.2, 0),
                Size     = UDim2.new(0, 3, 0.6, 0),
            }, Btn)

            New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size     = UDim2.new(1, -20, 1, 0),
                Font     = Enum.Font.GothamSemibold,
                Text     = text,
                TextColor3 = T.Text,
                TextSize   = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Btn)

            Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundColor3 = T.SurfaceAlt}, 0.15)
            end)
            Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundColor3 = T.Surface}, 0.15)
            end)
            Btn.MouseButton1Down:Connect(function()
                Tween(Btn, {BackgroundColor3 = T.AccentDim}, 0.1)
            end)
            Btn.MouseButton1Up:Connect(function()
                Tween(Btn, {BackgroundColor3 = T.SurfaceAlt}, 0.1)
                if callback then callback() end
            end)
        end

        function Tab:AddToggle(text, default, callback)
            local state = default or false
            local Row = New("Frame", {
                BackgroundColor3 = T.Surface,
                Size        = UDim2.new(1, 0, 0, 38),
                LayoutOrder = Order(),
            }, Page)
            Corner(8, Row)
            Stroke(T.Border, 1, Row)

            New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size     = UDim2.new(1, -65, 1, 0),
                Font     = Enum.Font.Gotham,
                Text     = text,
                TextColor3 = T.Text,
                TextSize   = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Row)

            local Track = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = state and Color3.fromRGB(255,140,30) or T.TabInactive,
                Position    = UDim2.new(1, -14, 0.5, 0),
                Size        = UDim2.new(0, 40, 0, 20),
            }, Row)
            Corner(50, Track)

            local Knob = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = T.Text,
                Position = state and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0),
                Size     = UDim2.new(0, 17, 0, 17),
            }, Track)
            Corner(50, Knob)

            local function Update()
                Tween(Track, {BackgroundColor3 = state and Color3.fromRGB(255,140,30) or T.TabInactive}, 0.2)
                Tween(Knob,  {Position = state and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0)}, 0.2)
            end

            New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0), Text = "",
            }, Row).MouseButton1Click:Connect(function()
                state = not state
                Update()
                if callback then callback(state) end
            end)
        end

        function Tab:AddSlider(text, min, max, default, callback)
            min = min or 0; max = max or 100
            local val = math.clamp(default or min, min, max)

            local Wrap = New("Frame", {
                BackgroundColor3 = T.Surface,
                Size        = UDim2.new(1, 0, 0, 54),
                LayoutOrder = Order(),
            }, Page)
            Corner(8, Wrap)
            Stroke(T.Border, 1, Wrap)
            Pad(8, 8, 14, 14, Wrap)

            local Top = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
            }, Wrap)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.65, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text, TextColor3 = T.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Top)
            local ValLbl = New("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position    = UDim2.new(1, 0, 0, 0),
                Size        = UDim2.new(0.35, 0, 1, 0),
                Font        = Enum.Font.GothamBold,
                Text        = tostring(val),
                TextColor3  = T.Accent,
                TextSize    = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, Top)

            local Track = New("Frame", {
                BackgroundColor3 = Color3.fromRGB(28, 28, 40),
                Position = UDim2.new(0, 0, 1, -8),
                Size     = UDim2.new(1, 0, 0, 6),
            }, Wrap)
            Corner(50, Track)

            local Fill = New("Frame", {
                BackgroundColor3 = T.Accent,
                Size = UDim2.new((val-min)/(max-min), 0, 1, 0),
            }, Track)
            Corner(50, Fill)

            local Thumb = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = T.Text,
                Position = UDim2.new((val-min)/(max-min), 0, 0.5, 0),
                Size     = UDim2.new(0, 14, 0, 14),
            }, Track)
            Corner(50, Thumb)
            Stroke(T.Accent, 2, Thumb)

            local sliding = false
            local function Set(xRatio)
                xRatio = math.clamp(xRatio, 0, 1)
                val = math.round(min + (max-min)*xRatio)
                Tween(Fill,  {Size     = UDim2.new(xRatio, 0, 1, 0)}, 0.05)
                Tween(Thumb, {Position = UDim2.new(xRatio, 0, 0.5, 0)}, 0.05)
                ValLbl.Text = tostring(val)
                if callback then callback(val) end
            end

            Track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    Set((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
                             or i.UserInputType == Enum.UserInputType.Touch) then
                    Set((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
        end

        function Tab:AddLabel(text)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size        = UDim2.new(1, 0, 0, 22),
                Font        = Enum.Font.Gotham,
                Text        = text,
                TextColor3  = T.TextMuted,
                TextSize    = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped    = true,
                LayoutOrder = Order(),
            }, Page)
        end

        return Tab
    end

    -- animate open
    Main.Size = UDim2.new(0, 580, 0, 0)
    Tween(Main, {Size = UDim2.new(0, 580, 0, 410)}, 0.45,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return Window
end

return CamHub

