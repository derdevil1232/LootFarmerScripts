--// Enhanced MM2 AutoFarm with Fully Integrated UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Headshot = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)

-- Farm State Variables
local farmingEnabled = false
local noclipEnabled = false
local farmSpeed = 17.6
local coinsCollected = 0
local startTime = 0
local currentTween = nil
local noclipConnection = nil

-- Colors
local MainColor = Color3.fromRGB(0, 0, 0)
local HighlightColor = Color3.fromRGB(60, 60, 60)
local ButtonClose = Color3.fromRGB(255, 95, 86)
local ButtonMin = Color3.fromRGB(255, 189, 46)
local ButtonMax = Color3.fromRGB(39, 201, 63)
local NeonColor = Color3.fromRGB(0, 200, 255)
local SuccessColor = Color3.fromRGB(39, 201, 63)
local ErrorColor = Color3.fromRGB(255, 95, 86)

local tween = function(obj, prop, time, style, direction)
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(time, style, direction), prop):Play()
end

local gui = Instance.new("ScreenGui")
gui.Name = "Cee3eeFarming"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

-- Blur Background
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = game.Lighting

tween(blur, {Size = 15}, 0.5)

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 520, 0, 350)
main.Position = UDim2.new(0.5, -260, 0.5, -175)
main.BackgroundColor3 = MainColor
main.BackgroundTransparency = 0.2
main.Parent = gui
main.ClipsDescendants = true
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0

-- Glass/Frosted effect
local glassOverlay = Instance.new("Frame")
glassOverlay.Size = UDim2.new(1, 0, 1, 0)
glassOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassOverlay.BackgroundTransparency = 0.92
glassOverlay.BorderSizePixel = 0
glassOverlay.Parent = main

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100))
}
gradient.Rotation = 45
gradient.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.95),
    NumberSequenceKeypoint.new(1, 0.98)
}
gradient.Parent = glassOverlay

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

-- Neon glow border
local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.Size = UDim2.new(1, 30, 1, 30)
glow.Position = UDim2.new(0.5, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundTransparency = 1
glow.Image = "rbxasset://textures/ui/Glow.png"
glow.ImageColor3 = NeonColor
glow.ImageTransparency = 0.6
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(10, 10, 118, 118)
glow.Parent = main
glow.ZIndex = 0

-- Animate glow pulsing
spawn(function()
    while gui.Parent do
        tween(glow, {ImageTransparency = 0.3}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        wait(1.5)
        tween(glow, {ImageTransparency = 0.6}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        wait(1.5)
    end
end)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = HighlightColor
topBar.BackgroundTransparency = 0.35
topBar.BorderSizePixel = 0
topBar.Parent = main

local topCorner = corner:Clone()
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Text = "Hello, "..Player.Name
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Ripple effect function
local function createRipple(button, x, y)
    local ripple = Instance.new("ImageLabel")
    ripple.Name = "Ripple"
    ripple.BackgroundTransparency = 1
    ripple.Image = "rbxasset://textures/ui/Glow.png"
    ripple.ImageColor3 = Color3.fromRGB(255, 255, 255)
    ripple.ImageTransparency = 0.5
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = 10
    ripple.Parent = button
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    tween(ripple, {Size = UDim2.new(0, size, 0, size), ImageTransparency = 1}, 0.5)
    game:GetService("Debris"):AddItem(ripple, 0.5)
end

-- macOS window buttons with animations
local function makeButton(color, offsetX, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 14, 0, 14)
    btn.Position = UDim2.new(1, offsetX, 0.5, -7)
    btn.BackgroundColor3 = color
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = topBar

    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(1, 0)
    round.Parent = btn

    local btnGlow = Instance.new("ImageLabel")
    btnGlow.Size = UDim2.new(1, 8, 1, 8)
    btnGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    btnGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    btnGlow.BackgroundTransparency = 1
    btnGlow.Image = "rbxasset://textures/ui/Glow.png"
    btnGlow.ImageColor3 = color
    btnGlow.ImageTransparency = 1
    btnGlow.Parent = btn
    btnGlow.ZIndex = 0

    btn.MouseEnter:Connect(function()
        tween(btnGlow, {ImageTransparency = 0.3}, 0.2)
        tween(btn, {Size = UDim2.new(0, 16, 0, 16)}, 0.2, Enum.EasingStyle.Back)
    end)

    btn.MouseLeave:Connect(function()
        tween(btnGlow, {ImageTransparency = 1}, 0.2)
        tween(btn, {Size = UDim2.new(0, 14, 0, 14)}, 0.2, Enum.EasingStyle.Back)
    end)

    btn.MouseButton1Click:Connect(function()
        tween(btn, {Size = UDim2.new(0, 12, 0, 12)}, 0.1)
        wait(0.1)
        tween(btn, {Size = UDim2.new(0, 14, 0, 14)}, 0.1)
        callback()
    end)
end

local minimized = false

makeButton(ButtonClose, -20, function()
    farmingEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    tween(blur, {Size = 0}, 0.3)
    tween(main, {Size = UDim2.new(0,0,0,0)}, 0.3)
    task.wait(0.3)
    gui:Destroy()
end)

makeButton(ButtonMin, -40, function()
    if minimized then return end
    minimized = true
    tween(main, {Size = UDim2.new(0,520,0,30)}, 0.35)
end)

makeButton(ButtonMax, -60, function()
    minimized = false
    tween(main, {Size = UDim2.new(0,520,0,350)}, 0.35)
end)

-- Tab column
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0, 100, 1, -30)
tabFrame.Position = UDim2.new(0, 0, 0, 30)
tabFrame.BackgroundColor3 = HighlightColor
tabFrame.BackgroundTransparency = 0.45
tabFrame.BorderSizePixel = 0
tabFrame.Parent = main

local tabCorner = corner:Clone()
tabCorner.Parent = tabFrame

local activeTab = nil

local function createTab(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
    button.Position = UDim2.new(0, 5, 0, y)
    button.Text = text
    button.BackgroundColor3 = MainColor
    button.BackgroundTransparency = 0.65
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.ClipsDescendants = true
    button.Parent = tabFrame

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 8)
    bCorner.Parent = button

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.7, 0)
    indicator.Position = UDim2.new(0, -3, 0.15, 0)
    indicator.BackgroundColor3 = NeonColor
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = button

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    local tabGlow = Instance.new("ImageLabel")
    tabGlow.Size = UDim2.new(1, 10, 1, 10)
    tabGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    tabGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    tabGlow.BackgroundTransparency = 1
    tabGlow.Image = "rbxasset://textures/ui/Glow.png"
    tabGlow.ImageColor3 = NeonColor
    tabGlow.ImageTransparency = 1
    tabGlow.Parent = button
    tabGlow.ZIndex = 0

    button.MouseEnter:Connect(function()
        if button ~= activeTab then
            tween(button, {BackgroundTransparency = 0.5}, 0.2)
        end
    end)

    button.MouseLeave:Connect(function()
        if button ~= activeTab then
            tween(button, {BackgroundTransparency = 0.65}, 0.2)
        end
    end)

    button.MouseButton1Down:Connect(function()
        local absPos = button.AbsolutePosition
        local mousePos = game:GetService("UserInputService"):GetMouseLocation()
        local relX = mousePos.X - absPos.X
        local relY = mousePos.Y - absPos.Y - 36
        createRipple(button, relX, relY)
        tween(button, {Size = UDim2.new(1, -12, 0, 38)}, 0.1)
    end)

    button.MouseButton1Up:Connect(function()
        tween(button, {Size = UDim2.new(1, -10, 0, 40)}, 0.1)
    end)

    return button, indicator, tabGlow
end

local farmingTab, farmingIndicator, farmingGlow = createTab("Farming", 10)
local settingsTab, settingsIndicator, settingsGlow = createTab("Settings", 60)

local function setActiveTab(button, indicator, glow)
    if activeTab then
        local oldData = activeTab
        tween(oldData.button, {BackgroundTransparency = 0.65}, 0.3)
        oldData.indicator.Visible = false
        tween(oldData.glow, {ImageTransparency = 1}, 0.3)
    end
    
    activeTab = {button = button, indicator = indicator, glow = glow}
    indicator.Visible = true
    tween(button, {BackgroundTransparency = 0.3}, 0.3)
    tween(glow, {ImageTransparency = 0.5}, 0.3)
end

-- Pages
local pages = Instance.new("Folder")
pages.Parent = main

local function createPage()
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -100, 1, -30)
    page.Position = UDim2.new(0, 100, 0, 30)
    page.BackgroundColor3 = MainColor
    page.BackgroundTransparency = 0.45
    page.BorderSizePixel = 0
    page.Visible = false
    page.Parent = pages

    local pageCorner = corner:Clone()
    pageCorner.Parent = page
    return page
end

local farmingPage = createPage()
local settingsPage = createPage()

-- ========== FARMING PAGE UI ==========

-- Status Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, -20, 0, 80)
statusCard.Position = UDim2.new(0, 10, 0, 10)
statusCard.BackgroundColor3 = HighlightColor
statusCard.BackgroundTransparency = 0.5
statusCard.BorderSizePixel = 0
statusCard.Parent = farmingPage

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusCard

-- Status Title
local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -20, 0, 25)
statusTitle.Position = UDim2.new(0, 10, 0, 5)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "Farm Status"
statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextSize = 16
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

-- Status Indicator
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0, 12, 0, 12)
statusIndicator.Position = UDim2.new(1, -20, 0, 12)
statusIndicator.BackgroundColor3 = ErrorColor
statusIndicator.BorderSizePixel = 0
statusIndicator.Parent = statusCard

local statusIndCorner = Instance.new("UICorner")
statusIndCorner.CornerRadius = UDim.new(1, 0)
statusIndCorner.Parent = statusIndicator

local statusGlow = Instance.new("ImageLabel")
statusGlow.Size = UDim2.new(1, 8, 1, 8)
statusGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
statusGlow.AnchorPoint = Vector2.new(0.5, 0.5)
statusGlow.BackgroundTransparency = 1
statusGlow.Image = "rbxasset://textures/ui/Glow.png"
statusGlow.ImageColor3 = ErrorColor
statusGlow.ImageTransparency = 0.3
statusGlow.Parent = statusIndicator
statusGlow.ZIndex = 0

-- Pulse animation for status
spawn(function()
    while gui.Parent do
        if farmingEnabled then
            tween(statusGlow, {ImageTransparency = 0.1}, 0.8, Enum.EasingStyle.Sine)
            wait(0.8)
            tween(statusGlow, {ImageTransparency = 0.3}, 0.8, Enum.EasingStyle.Sine)
            wait(0.8)
        else
            wait(0.1)
        end
    end
end)

-- Stats Container
local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, -20, 0, 45)
statsContainer.Position = UDim2.new(0, 10, 0, 30)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = statusCard

local function createStat(text, value, pos)
    local statLabel = Instance.new("TextLabel")
    statLabel.Size = UDim2.new(0.33, -5, 1, 0)
    statLabel.Position = UDim2.new(pos * 0.33, 0, 0, 0)
    statLabel.BackgroundTransparency = 1
    statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statLabel.Font = Enum.Font.Gotham
    statLabel.TextSize = 11
    statLabel.TextXAlignment = Enum.TextXAlignment.Left
    statLabel.Text = text
    statLabel.Parent = statsContainer
    
    local statValue = Instance.new("TextLabel")
    statValue.Size = UDim2.new(1, 0, 0, 20)
    statValue.Position = UDim2.new(0, 0, 0, 15)
    statValue.BackgroundTransparency = 1
    statValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    statValue.Font = Enum.Font.GothamBold
    statValue.TextSize = 18
    statValue.TextXAlignment = Enum.TextXAlignment.Left
    statValue.Text = value
    statValue.Parent = statLabel
    
    return statValue
end

local coinsLabel = createStat("Coins Collected", "0", 0)
local timeLabel = createStat("Time Running", "00:00", 1)
local speedLabel = createStat("Current Speed", "17.6", 2)

-- Update time display
spawn(function()
    while gui.Parent do
        if farmingEnabled and startTime > 0 then
            local elapsed = math.floor(os.clock() - startTime)
            local minutes = math.floor(elapsed / 60)
            local seconds = elapsed % 60
            timeLabel.Text = string.format("%02d:%02d", minutes, seconds)
        end
        wait(1)
    end
end)

-- Controls Card
local controlsCard = Instance.new("Frame")
controlsCard.Size = UDim2.new(1, -20, 0, 140)
controlsCard.Position = UDim2.new(0, 10, 0, 100)
controlsCard.BackgroundColor3 = HighlightColor
controlsCard.BackgroundTransparency = 0.5
controlsCard.BorderSizePixel = 0
controlsCard.Parent = farmingPage

local controlsCorner = Instance.new("UICorner")
controlsCorner.CornerRadius = UDim.new(0, 10)
controlsCorner.Parent = controlsCard

-- Controls Title
local controlsTitle = Instance.new("TextLabel")
controlsTitle.Size = UDim2.new(1, -20, 0, 25)
controlsTitle.Position = UDim2.new(0, 10, 0, 5)
controlsTitle.BackgroundTransparency = 1
controlsTitle.Text = "Controls"
controlsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
controlsTitle.Font = Enum.Font.GothamBold
controlsTitle.TextSize = 16
controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
controlsTitle.Parent = controlsCard

-- Toggle switch function
local function createToggle(text, yPos, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 30)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = controlsCard
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(1, -60, 1, 0)
    toggleLabel.Position = UDim2.new(0, 0, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextSize = 13
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 24)
    toggleButton.Position = UDim2.new(1, -50, 0.5, -12)
    toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleButton.Text = ""
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Size = UDim2.new(0, 18, 0, 18)
    toggleKnob.Position = UDim2.new(0, 3, 0.5, -9)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Parent = toggleButton
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    local knobGlow = Instance.new("ImageLabel")
    knobGlow.Size = UDim2.new(1, 8, 1, 8)
    knobGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    knobGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    knobGlow.BackgroundTransparency = 1
    knobGlow.Image = "rbxasset://textures/ui/Glow.png"
    knobGlow.ImageColor3 = NeonColor
    knobGlow.ImageTransparency = 1
    knobGlow.Parent = toggleKnob
    knobGlow.ZIndex = 0
    
    local isOn = false
    
    toggleButton.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        if isOn then
            tween(toggleKnob, {Position = UDim2.new(1, -21, 0.5, -9), BackgroundColor3 = NeonColor}, 0.3, Enum.EasingStyle.Back)
            tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(20, 80, 100)}, 0.3)
            tween(knobGlow, {ImageTransparency = 0.3}, 0.3)
        else
            tween(toggleKnob, {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.3, Enum.EasingStyle.Back)
            tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.3)
            tween(knobGlow, {ImageTransparency = 1}, 0.3)
        end
        
        callback(isOn)
    end)
    
    return {button = toggleButton, setOn = function(state)
        isOn = state
        if isOn then
            toggleKnob.Position = UDim2.new(1, -21, 0.5, -9)
            toggleKnob.BackgroundColor3 = NeonColor
            toggleButton.BackgroundColor3 = Color3.fromRGB(20, 80, 100)
            knobGlow.ImageTransparency = 0.3
        else
            toggleKnob.Position = UDim2.new(0, 3, 0.5, -9)
            toggleKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            knobGlow.ImageTransparency = 1
        end
    end}
end

-- Start/Stop Farm Toggle
local farmToggle = createToggle("Auto Farm", 35, function(enabled)
    farmingEnabled = enabled
    if enabled then
        coinsCollected = 0
        startTime = os.clock()
        coinsLabel.Text = "0"
        statusIndicator.BackgroundColor3 = SuccessColor
        statusGlow.ImageColor3 = SuccessColor
    else
        statusIndicator.BackgroundColor3 = ErrorColor
        statusGlow.ImageColor3 = ErrorColor
        if currentTween then
            currentTween:Cancel()
        end
    end
end)

-- Noclip Toggle
local noclipToggle = createToggle("Noclip", 70, function(enabled)
    noclipEnabled = enabled
    if enabled then
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = Player.Character
            if char and noclipEnabled then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end)

-- Speed Slider
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -20, 0, 30)
speedFrame.Position = UDim2.new(0, 10, 0, 105)
speedFrame.BackgroundTransparency = 1
speedFrame.Parent = controlsCard

local speedLabelText = Instance.new("TextLabel")
speedLabelText.Size = UDim2.new(0, 100, 1, 0)
speedLabelText.Position = UDim2.new(0, 0, 0, 0)
speedLabelText.BackgroundTransparency = 1
speedLabelText.Text = "Speed: 17.6"
speedLabelText.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabelText.Font = Enum.Font.Gotham
speedLabelText.TextSize = 13
speedLabelText.TextXAlignment = Enum.TextXAlignment.Left
speedLabelText.Parent = speedFrame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, -110, 0, 6)
speedSlider.Position = UDim2.new(0, 105, 0.5, -3)
speedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedSlider.BorderSizePixel = 0
speedSlider.Parent = speedFrame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = speedSlider

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
speedFill.BackgroundColor3 = NeonColor
speedFill.BorderSizePixel = 0
speedFill.Parent = speedSlider

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = speedFill

local speedKnob = Instance.new("TextButton")
speedKnob.Size = UDim2.new(0, 16, 0, 16)
speedKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
speedKnob.BackgroundColor3 = NeonColor
speedKnob.Text = ""
speedKnob.BorderSizePixel = 0
speedKnob.Parent = speedSlider

local knobCorner2 = Instance.new("UICorner")
knobCorner2.CornerRadius = UDim.new(1, 0)
knobCorner2.Parent = speedKnob

local knobGlow2 = Instance.new("ImageLabel")
knobGlow2.Size = UDim2.new(1, 12, 1, 12)
knobGlow2.Position = UDim2.new(0.5, 0, 0.5, 0)
knobGlow2.AnchorPoint = Vector2.new(0.5, 0.5)
knobGlow2.BackgroundTransparency = 1
knobGlow2.Image = "rbxasset://textures/ui/Glow.png"
knobGlow2.ImageColor3 = NeonColor
knobGlow2.ImageTransparency = 0.3
knobGlow2.Parent = speedKnob
knobGlow2.ZIndex = 0

local dragging = false
local function updateSpeed(input)
    local pos = (input.Position.X - speedSlider.AbsolutePosition.X) / speedSlider.AbsoluteSize.X
    pos = math.clamp(pos, 0, 1)
    
    farmSpeed = 10 + (pos * 30) -- Range: 10 to 40 studs/sec
    speedFill.Size = UDim2.new(pos, 0, 1, 0)
    speedKnob.Position = UDim2.new(pos, -8, 0.5, -8)
    speedLabelText.Text = string.format("Speed: %.1f", farmSpeed)
    speedLabel.Text = string.format("%.1f", farmSpeed)
end

speedKnob.MouseButton1Down:Connect(function()
    dragging = true
    tween(speedKnob, {Size = UDim2.new(0, 20, 0, 20)}, 0.2, Enum.EasingStyle.Back)
    tween(knobGlow2, {ImageTransparency = 0.1}, 0.2)
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        tween(speedKnob, {Size = UDim2.new(0, 16, 0, 16)}, 0.2, Enum.EasingStyle.Back)
        tween(knobGlow2, {ImageTransparency = 0.3}, 0.2)
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSpeed(input)
    end
end)

-- ========== SETTINGS PAGE UI ==========

local stext = Instance.new("TextLabel")
stext.Size = UDim2.new(1, -20, 0, 60)
stext.Position = UDim2.new(0, 10, 0, 10)
stext.Text = "⚙️ Settings\n\nMore options coming soon!"
stext.TextColor3 = Color3.fromRGB(255,255,255)
stext.BackgroundTransparency = 1
stext.Font = Enum.Font.Gotham
stext.TextSize = 16
stext.TextYAlignment = Enum.TextYAlignment.Top
stext.Parent = settingsPage

-- ========== FARMING LOGIC ==========

local function getHRP()
    local char = Player.Character or Player.CharacterAdded:Wait()
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

                while map and map.Parent == workspace and farmingEnabled do
                    local coins = coinContainer:GetChildren()
                    local coin = getNearestCoin(coins, hrp, visited)

                    if not coin then
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
                            coinsLabel.Text = tostring(coinsCollected)
                            
                            -- Visual feedback
                            tween(coinsLabel, {TextColor3 = NeonColor}, 0.2)
                            wait(0.2)
                            tween(coinsLabel, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                            
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
            
            if not success then
                warn("Farming error: " .. tostring(err))
            end
        end
        task.wait(0.5)
    end
end)

-- Circular Headshot with animated border
local headshotContainer = Instance.new("Frame")
headshotContainer.Size = UDim2.new(0, 60, 0, 60)
headshotContainer.Position = UDim2.new(0, 20, 1, -100)
headshotContainer.BackgroundTransparency = 1
headshotContainer.Parent = main

local headshotBorder = Instance.new("ImageLabel")
headshotBorder.Size = UDim2.new(1, 10, 1, 10)
headshotBorder.Position = UDim2.new(0.5, 0, 0.5, 0)
headshotBorder.AnchorPoint = Vector2.new(0.5, 0.5)
headshotBorder.BackgroundTransparency = 1
headshotBorder.Image = "rbxasset://textures/ui/Glow.png"
headshotBorder.ImageColor3 = NeonColor
headshotBorder.ImageTransparency = 0.3
headshotBorder.Parent = headshotContainer
headshotBorder.ZIndex = 0

spawn(function()
    while gui.Parent do
        tween(headshotBorder, {Size = UDim2.new(1, 15, 1, 15), ImageTransparency = 0.1}, 1, Enum.EasingStyle.Sine)
        wait(1)
        tween(headshotBorder, {Size = UDim2.new(1, 10, 1, 10), ImageTransparency = 0.3}, 1, Enum.EasingStyle.Sine)
        wait(1)
    end
end)

local head = Instance.new("ImageLabel")
head.Size = UDim2.new(1, 0, 1, 0)
head.Position = UDim2.new(0.5, 0, 0.5, 0)
head.AnchorPoint = Vector2.new(0.5, 0.5)
head.BackgroundTransparency = 1
head.Image = Headshot
head.Parent = headshotContainer

local headCorner = Instance.new("UICorner")
headCorner.CornerRadius = UDim.new(1, 0)
headCorner.Parent = head

-- Username below headshot
local uname = Instance.new("TextLabel")
uname.Size = UDim2.new(0, 100, 0, 20)
uname.Position = UDim2.new(0, 20, 1, -35)
uname.BackgroundTransparency = 1
uname.TextColor3 = Color3.fromRGB(255,255,255)
uname.Font = Enum.Font.Gotham
uname.TextSize = 12
uname.Text = Player.Name
uname.TextXAlignment = Enum.TextXAlignment.Left
uname.Parent = main

-- Tab switching with slide/fade animation
local currentPage = nil

local function switch(tab, page, button, indicator, glow)
    if currentPage == page then return end
    
    if currentPage then
        tween(currentPage, {Position = UDim2.new(0, 50, 0, 30), BackgroundTransparency = 1}, 0.3)
        task.wait(0.15)
        currentPage.Visible = false
    end
    
    page.Position = UDim2.new(0, 150, 0, 30)
    page.BackgroundTransparency = 1
    page.Visible = true
    tween(page, {Position = UDim2.new(0, 100, 0, 30), BackgroundTransparency = 0.45}, 0.3)
    
    currentPage = page
    setActiveTab(button, indicator, glow)
    
    if tab == "Farming" then
        title.Text = "Hello, "..Player.Name
    else
        title.Text = "Settings"
    end
end

farmingTab.MouseButton1Click:Connect(function() switch("Farming", farmingPage, farmingTab, farmingIndicator, farmingGlow) end)
settingsTab.MouseButton1Click:Connect(function() switch("Settings", settingsPage, settingsTab, settingsIndicator, settingsGlow) end)

-- Initial animation
main.Size = UDim2.new(0, 520, 0, 0)
main.BackgroundTransparency = 1
farmingPage.Visible = true
currentPage = farmingPage
setActiveTab(farmingTab, farmingIndicator, farmingGlow)

tween(main, {Size = UDim2.new(0,520,0,350), BackgroundTransparency = 0.2}, 0.5, Enum.EasingStyle.Back)
tween(farmingPage, {BackgroundTransparency = 0.45}, 0.5)
