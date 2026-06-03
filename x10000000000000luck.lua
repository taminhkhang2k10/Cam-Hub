--[[ 
    Script sử dụng Rayfield UI cho Blox Fruit
    Đảm bảo bạn đã cài đặt môi trường thực thi hỗ trợ Rayfield.
]]
local CamHub = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/taminhkhang2k10/Cam-Hub/main/menu.lua"
))()
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Blox Fruit Support Menu",
    LoadingTitle = "Đang khởi tạo...",
    LoadingSubtitle = "by Gemini",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "BloxFruitConfig"
    },
    KeySystem = false
})

local Tab = Window:CreateTab("Tính năng chính", nil) -- Title, Icon

-- Tính năng 1: Tự động nhặt trái cây
Tab:CreateToggle({
    Name = "Tự động nhặt trái ác quỷ",
    CurrentValue = false,
    Flag = "AutoPick",
    Callback = function(Value)
        _G.AutoPick = Value
        if _G.AutoPick then
            print("Đã bật tính năng tự động nhặt trái ác quỷ!")
            -- Thêm logic code nhặt trái cây tại đây
        end
    end,
})

-- Tính năng 2: Chuyển server (Server Hop)
Tab:CreateButton({
    Name = "Chuyển sang Server khác",
    Callback = function()
        -- Logic chuyển server
        local HttpService = game:GetService("HttpService")
        local TPService = game:GetService("TeleportService")
        TPService:Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end,
})

-- Tính năng 3: Thông báo thời gian trái cây xuất hiện (Mockup)
Tab:CreateButton({
    Name = "Kiểm tra trái cây gần đây",
    Callback = function()
        Rayfield:Notify({
            Title = "Thông báo",
            Content = "Không tìm thấy trái cây nào trên bản đồ hiện tại.",
            Duration = 5,
            Image = nil,
        })
    end,
})

Rayfield:LoadConfiguration()
