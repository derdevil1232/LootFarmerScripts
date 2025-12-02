--// MM2 AutoFarm with Fluent UI Library
--// GitHub: https://github.com/dawid-scripts/Fluent

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Farm State Variables
local farmingEnabled = false
local noclipEnabled = false
local farmSpeed = 17.6
local coinsCollected = 0
local startTime = 0
local currentTween = nil
local noclipConnection = nil

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "MM2 AutoFarm " .. Fluent.Version,
    SubTitle = "by " .. player.Name,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    Farming = Window:AddTab({ Title = "Auto Farm", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ========== FARMING TAB ==========

-- Stats Display
local StatsDisplay = Tabs.Farming:AddParagraph({
    Title = "📊 Farm Statistics",
    Content = "Status: Inactive\nCoins Collected: 0\nTime Running: 00:00\nCurrent Speed: 17.6 studs/sec"
})

-- Update stats display
local function updateStatsDisplay()
    local status = farmingEnabled and "🟢 Active" or "🔴 Inactive"
    local elapsed = farmingEnabled and (os.clock() - startTime) or 0
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    local timeStr = string.format("%02d:%02d", minutes, seconds)
    
    StatsDisplay:SetDesc(
        string.format(
            "Status: %s\nCoins Collected: %d\nTime Running: %s\nCurrent Speed: %.1f studs/sec",
            status, coinsCollected, timeStr, farmSpeed
        )
    )
end

-- Live stats updater
task.spawn(function()
    while true do
        if farmingEnabled then
            updateStatsDisplay()
        end
        task.wait(1)
    end
end)

Tabs.Farming:AddParagraph({
    Title = "⚙️ Controls",
    Content = "Configure your auto farm settings below."
})

-- Auto Farm Toggle
local FarmToggle = Tabs.Farming:AddToggle("AutoFarm", {
    Title = "🚀 Auto Farm",
    Description = "Automatically collect coins from the map",
    Default = false
})

FarmToggle:OnChanged(function(value)
    farmingEnabled = value
    
    if value then
        coinsCollected = 0
        startTime = os.clock()
        updateStatsDisplay()
        
        Fluent:Notify({
            Title = "Auto Farm Started",
            Content = "Now collecting coins automatically!",
            Duration = 3
        })
    else
        updateStatsDisplay()
        
        if currentTween then
            currentTween:Cancel()
        end
        
        Fluent:Notify({
            Title = "Auto Farm Stopped",
            Content = string.format("Collected %d coins in total.", coinsCollected),
            Duration = 5
        })
    end
end)

-- Noclip Toggle
local NoclipToggle = Tabs.Farming:AddToggle("Noclip", {
    Title = "👻 Noclip",
    Description = "Walk through walls and objects",
    Default = false
})

NoclipToggle:OnChanged(function(value)
    noclipEnabled = value
    
    if value then
        -- Enable noclip
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        
        noclipConnection = RunService.Stepped:Connect(function()
            local char = player.Character
            if char and noclipEnabled then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        Fluent:Notify({
            Title = "Noclip Enabled",
            Content = "You can now walk through walls!",
            Duration = 3
        })
    else
        -- Disable noclip
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        -- Re-enable collisions
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        
        Fluent:Notify({
            Title = "Noclip Disabled",
            Content = "Collisions restored to normal.",
            Duration = 3
        })
    end
end)

-- Speed Slider
local SpeedSlider = Tabs.Farming:AddSlider("FarmSpeed", {
    Title = "⚡ Movement Speed",
    Description = "Adjust how fast you move to coins (10-40 studs/sec)",
    Default = 17.6,
    Min = 10,
    Max = 40,
    Rounding = 1,
    Callback = function(value)
        farmSpeed = value
        updateStatsDisplay()
    end
})

SpeedSlider:OnChanged(function(value)
    farmSpeed = value
    updateStatsDisplay()
end)

Tabs.Farming:AddParagraph({
    Title = "💡 Tips",
    Content = "• Enable Noclip for faster coin collection\n• Higher speeds may look suspicious\n• The farm will automatically detect new rounds"
})

-- Reset Stats Button
Tabs.Farming:AddButton({
    Title = "🔄 Reset Statistics",
    Description = "Reset coin counter and timer",
    Callback = function()
        coinsCollected = 0
        startTime = os.clock()
        updateStatsDisplay()
        
        Fluent:Notify({
            Title = "Stats Reset",
            Content = "All statistics have been reset.",
            Duration = 3
        })
    end
})

-- ========== SETTINGS TAB ==========

Tabs.Settings:AddParagraph({
    Title = "⚙️ Application Settings",
    Content = "Manage your UI preferences and configurations."
})

-- Auto-start option
local AutoStartToggle = Tabs.Settings:AddToggle("AutoStart", {
    Title = "🔄 Auto-Start Farm",
    Description = "Automatically start farming when script loads",
    Default = false
})

AutoStartToggle:OnChanged(function(value)
    if value then
        Fluent:Notify({
            Title = "Auto-Start Enabled",
            Content = "Farm will start automatically on next load.",
            Duration = 3
        })
    end
end)

-- Notification settings
local NotificationsToggle = Tabs.Settings:AddToggle("Notifications", {
    Title = "🔔 Enable Notifications",
    Description = "Show notifications for important events",
    Default = true
})

-- Keybind for toggling farm
local FarmKeybind = Tabs.Settings:AddKeybind("FarmKeybind", {
    Title = "⌨️ Toggle Farm Keybind",
    Mode = "Toggle",
    Default = "F",
    Callback = function(value)
        Options.AutoFarm:SetValue(value)
    end
})

FarmKeybind:OnClick(function()
    local newState = not Options.AutoFarm.Value
    Options.AutoFarm:SetValue(newState)
end)

-- Theme Selector
local ThemeDropdown = Tabs.Settings:AddDropdown("Theme", {
    Title = "🎨 UI Theme",
    Description = "Change the interface appearance",
    Values = {"Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose"},
    Multi = false,
    Default = "Dark",
})

ThemeDropdown:OnChanged(function(value)
    Fluent:SetTheme(value)
    
    if Options.Notifications.Value then
        Fluent:Notify({
            Title = "Theme Changed",
            Content = "UI theme set to " .. value,
            Duration = 2
        })
    end
end)

-- Transparency Slider
local TransparencySlider = Tabs.Settings:AddSlider("Transparency", {
    Title = "👁️ UI Transparency",
    Description = "Adjust interface transparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        Window:SetTransparency(value / 100)
    end
})

Tabs.Settings:AddParagraph({
    Title = "ℹ️ Information",
    Content = "MM2 AutoFarm Script\nVersion: 1.0.0\n\nFeatures:\n• Automatic coin collection\n• Noclip support\n• Adjustable speed\n• Real-time statistics\n\nMade with Fluent UI Library"
})

-- ========== FARMING LOGIC ==========

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function smoothMoveTo(hrp, targetPart)
    local distance = (hrp.Position - targetPart.Position).Magnitude
    local time = distance / farmSpeed
    currentTween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame})
    currentTween:Play()
    return currentTween
end

local function findActiveMap()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("CoinContainer") then
            return child
        end
    end
    return nil
end

local function getNearestCoin(coins, hrp, visited)
    local nearest, shortestDist
    for _, coin in ipairs(coins) do
        if coin:IsA("BasePart") and not visited[coin] then
            local dist = (hrp.Position - coin.Position).Magnitude
            if not shortestDist or dist < shortestDist then
                nearest = coin
                shortestDist = dist
            end
        end
    end
    return nearest
end

-- Main farming loop
task.spawn(function()
    while true do
        if farmingEnabled then
            local success, err = pcall(function()
                local hrp = getHRP()
                local map = findActiveMap()
                
                if not map then
                    task.wait(1)
                    return
                end

                local coinContainer = map:FindFirstChild("CoinContainer")
                if not coinContainer then
                    task.wait(1)
                    return
                end

                local visited = {}
                local roundCoins = 0

                while map and map.Parent == workspace and farmingEnabled do
                    local coins = coinContainer:GetChildren()
                    local coin = getNearestCoin(coins, hrp, visited)

                    if not coin then
                        -- Round complete
                        if roundCoins > 0 and Options.Notifications.Value then
                            Fluent:Notify({
                                Title = "Round Complete",
                                Content = string.format("Collected %d coins this round!", roundCoins),
                                Duration = 4
                            })
                            roundCoins = 0
                        end
                        visited = {}
                        task.wait(0.5)
                        continue
                    end

                    local tween = smoothMoveTo(hrp, coin)

                    local touched = false
                    local connection
                    connection = hrp.Touched:Connect(function(hit)
                        if hit == coin and not visited[hit] then
                            touched = true
                            visited[hit] = true
                            coinsCollected = coinsCollected + 1
                            roundCoins = roundCoins + 1
                            updateStatsDisplay()
                            connection:Disconnect()
                        end
                    end)

                    while not touched and coin.Parent and farmingEnabled do
                        task.wait(0.1)
                    end

                    if tween then
                        tween:Cancel()
                    end
                    
                    if not farmingEnabled then
                        break
                    end
                    
                    task.wait(0.1)
                end
            end)
            
            if not success and Options.Notifications.Value then
                warn("Farming error: " .. tostring(err))
                Fluent:Notify({
                    Title = "Error",
                    Content = "An error occurred while farming. Check console.",
                    Duration = 5
                })
            end
        end
        task.wait(0.5)
    end
end)

-- ========== CONFIG MANAGEMENT ==========

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore theme settings in saves
SaveManager:IgnoreThemeSettings()

-- Set folders for configs
InterfaceManager:SetFolder("MM2_AutoFarm")
SaveManager:SetFolder("MM2_AutoFarm/configs")

-- Build interface sections
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Select default tab
Window:SelectTab(1)

-- Initial notification
Fluent:Notify({
    Title = "MM2 AutoFarm Loaded",
    Content = "Welcome back, " .. player.Name .. "! Configure your settings and toggle Auto Farm to begin.",
    Duration = 6
})

-- Auto-load config
SaveManager:LoadAutoloadConfig()

-- Auto-start if enabled
task.wait(1)
if Options.AutoStart and Options.AutoStart.Value then
    Options.AutoFarm:SetValue(true)
end

-- Cleanup on unload
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Fluent" then
        farmingEnabled = false
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        if currentTween then
            currentTween:Cancel()
        end
    end
end)
