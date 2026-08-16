--[[
    ZIZU 月 — UI.lua
    All user interface rendering, animations, components.
    Created by zizu
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera

local UI = {}

local Core
local Config
local Features

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(24, 24, 30),
    SurfaceLight = Color3.fromRGB(32, 32, 40),
    SurfaceHover = Color3.fromRGB(38, 38, 48),
    Card = Color3.fromRGB(28, 28, 36),
    CardHover = Color3.fromRGB(34, 34, 44),
    Border = Color3.fromRGB(50, 50, 62),
    BorderLight = Color3.fromRGB(60, 60, 72),
    Text = Color3.fromRGB(230, 230, 235),
    TextSecondary = Color3.fromRGB(140, 140, 155),
    TextMuted = Color3.fromRGB(90, 90, 105),
    Accent = Color3.fromRGB(130, 140, 255),
    AccentDim = Color3.fromRGB(80, 90, 180),
    AccentGlow = Color3.fromRGB(100, 110, 220),
    ToggleOn = Color3.fromRGB(100, 120, 255),
    ToggleOff = Color3.fromRGB(55, 55, 68),
    ToggleKnob = Color3.fromRGB(240, 240, 245),
    Danger = Color3.fromRGB(255, 70, 70),
    Success = Color3.fromRGB(70, 200, 120),
    Warning = Color3.fromRGB(255, 180, 50),
    Transparent = Color3.fromRGB(0, 0, 0),
}

local FONTS = {
    Title = Enum.Font.GothamBold,
    Heading = Enum.Font.GothamSemibold,
    Body = Enum.Font.GothamMedium,
    Caption = Enum.Font.Gotham,
    Mono = Enum.Font.Code,
    Icon = Enum.Font.GothamBlack,
}

function UI:Init(core, config, features)
    Core = core
    Config = config
    Features = features
    self._screenGui = nil
    self._mainFrame = nil
    self._floatingIcon = nil
    self._sidebar = nil
    self._contentArea = nil
    self._tabs = {}
    self._activeTab = "HOME"
    self._isOpen = false
    self._notifContainer = nil
    self._searchResults = {}
    return self
end

-- ═══════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════
function UI:CreateScreenGui()
    if self._screenGui then
        self._screenGui:Destroy()
    end

    local parent = Core.State.Player:FindFirstChild("PlayerGui")
    if not parent then
        parent = game:GetService("CoreGui")
    end

    self._screenGui = Core:Create("ScreenGui", {
        Name = "ZIZU_Framework",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = parent,
    })

    Core.State.GUI = self._screenGui
    return self._screenGui
end

-- ═══════════════════════════════════
-- LOADING SCREEN
-- ═══════════════════════════════════
function UI:ShowLoadingScreen(initCallback)
    local sg = self._screenGui

    local bg = Core:Create("Frame", {
        Name = "LoadingBG",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(8, 8, 12),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = sg,
    })

    local center = Core:Create("Frame", {
        Name = "Center",
        Size = UDim2.new(0, 400, 0, 340),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 201,
        Parent = bg,
    })

    local moonIcon = Core:Create("TextLabel", {
        Name = "MoonIcon",
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0.5, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = "\230\156\136",
        TextColor3 = COLORS.Accent,
        TextTransparency = 1,
        Font = FONTS.Icon,
        TextSize = 52,
        TextScaled = false,
        ZIndex = 202,
        Parent = center,
    })

    local titleLabel = Core:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 110),
        BackgroundTransparency = 1,
        Text = "ZIZU",
        TextColor3 = COLORS.Text,
        TextTransparency = 1,
        Font = FONTS.Title,
        TextSize = 32,
        ZIndex = 202,
        Parent = center,
    })

    local subtitleLabel = Core:Create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 150),
        BackgroundTransparency = 1,
        Text = "A modern Roblox client framework",
        TextColor3 = COLORS.TextSecondary,
        TextTransparency = 1,
        Font = FONTS.Caption,
        TextSize = 14,
        ZIndex = 202,
        Parent = center,
    })

    local creatorLabel = Core:Create("TextLabel", {
        Name = "Creator",
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 175),
        BackgroundTransparency = 1,
        Text = "Created by zizu",
        TextColor3 = COLORS.TextMuted,
        TextTransparency = 1,
        Font = FONTS.Caption,
        TextSize = 12,
        ZIndex = 202,
        Parent = center,
    })

    local progressBG = Core:Create("Frame", {
        Name = "ProgressBG",
        Size = UDim2.new(0.7, 0, 0, 3),
        Position = UDim2.new(0.15, 0, 0, 220),
        BackgroundColor3 = COLORS.SurfaceLight,
        BackgroundTransparency = 1,
        ZIndex = 202,
        Parent = center,
    })
    Core:ApplyCorner(progressBG, 2)

    local progressFill = Core:Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        ZIndex = 203,
        Parent = progressBG,
    })
    Core:ApplyCorner(progressFill, 2)

    local statusLabel = Core:Create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 235),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = COLORS.TextMuted,
        TextTransparency = 1,
        Font = FONTS.Mono,
        TextSize = 11,
        ZIndex = 202,
        Parent = center,
    })

    local percentLabel = Core:Create("TextLabel", {
        Name = "Percent",
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 255),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = COLORS.TextMuted,
        TextTransparency = 1,
        Font = FONTS.Mono,
        TextSize = 11,
        ZIndex = 202,
        Parent = center,
    })

    local steps = {
        {text = "Initializing Core...", label = "CORE", progress = 0.2},
        {text = "Loading Configuration...", label = "CONFIGURATION", progress = 0.4},
        {text = "Initializing Features...", label = "FEATURES", progress = 0.65},
        {text = "Preparing Interface...", label = "INTERFACE", progress = 0.85},
        {text = "Ready.", label = "READY", progress = 1.0},
    }

    local function setProgress(pct)
        Core:Tween(progressFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.4)
        percentLabel.Text = math.floor(pct * 100) .. "%"
    end

    -- Fade in background
    Core:Tween(bg, {BackgroundTransparency = 0}, 0.6)
    task.wait(0.4)

    -- Moon scale in
    moonIcon.TextTransparency = 1
    Core:Tween(moonIcon, {TextTransparency = 0}, 0.6, Enum.EasingStyle.Back)
    task.wait(0.5)

    -- Moon subtle float
    task.spawn(function()
        while bg.Parent do
            Core:Tween(moonIcon, {Position = UDim2.new(0.5, 0, 0, 16)}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
            Core:Tween(moonIcon, {Position = UDim2.new(0.5, 0, 0, 24)}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
        end
    end)

    -- Title fade
    Core:Tween(titleLabel, {TextTransparency = 0}, 0.5)
    task.wait(0.3)

    -- Subtitle fade
    Core:Tween(subtitleLabel, {TextTransparency = 0}, 0.4)
    task.wait(0.2)

    -- Creator fade
    Core:Tween(creatorLabel, {TextTransparency = 0}, 0.4)
    task.wait(0.3)

    -- Progress bar appear
    Core:Tween(progressBG, {BackgroundTransparency = 0}, 0.3)
    Core:Tween(progressFill, {BackgroundTransparency = 0}, 0.3)
    Core:Tween(statusLabel, {TextTransparency = 0}, 0.3)
    Core:Tween(percentLabel, {TextTransparency = 0}, 0.3)
    task.wait(0.2)

    -- Run real initialization steps
    local results = {}
    for i, step in ipairs(steps) do
        statusLabel.Text = step.text
        setProgress(step.progress)

        if initCallback then
            local ok, res = pcall(initCallback, i, step.label)
            results[step.label] = ok
        end

        local waitTime = (i == #steps) and 0.3 or 0.35
        task.wait(waitTime)
    end

    -- Done
    statusLabel.Text = "Ready."
    setProgress(1)
    task.wait(0.6)

    -- Fade out loading
    Core:Tween(bg, {BackgroundTransparency = 1}, 0.5)
    Core:Tween(moonIcon, {TextTransparency = 1}, 0.4)
    Core:Tween(titleLabel, {TextTransparency = 1}, 0.4)
    Core:Tween(subtitleLabel, {TextTransparency = 1}, 0.4)
    Core:Tween(creatorLabel, {TextTransparency = 1}, 0.4)
    Core:Tween(progressBG, {BackgroundTransparency = 1}, 0.4)
    Core:Tween(progressFill, {BackgroundTransparency = 1}, 0.4)
    Core:Tween(statusLabel, {TextTransparency = 1}, 0.4)
    Core:Tween(percentLabel, {TextTransparency = 1}, 0.4)
    task.wait(0.6)

    bg:Destroy()
    return results
end

-- ═══════════════════════════════════
-- FLOATING ICON
-- ═══════════════════════════════════
function UI:CreateFloatingIcon()
    local savedPos = Config:Get("IconPosition")
    local xPos = (savedPos and savedPos.X) or 50
    local yPos = (savedPos and savedPos.Y) or 50

    local icon = Core:Create("TextButton", {
        Name = "ZIZU_Icon",
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, xPos, 0, yPos),
        BackgroundTransparency = 1,
        Text = "\230\156\136",
        TextColor3 = COLORS.Accent,
        Font = FONTS.Icon,
        TextSize = 28,
        ZIndex = 150,
        AutoButtonColor = false,
        Parent = self._screenGui,
    })

    self._floatingIcon = icon

    -- Drag
    local dragging = false
    local dragStart, startPos

    icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = icon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Config:Set("IconPosition", {X = icon.Position.X.Offset, Y = icon.Position.Y.Offset})
                end
            end)
        end
    end)

    icon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                local newPos = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
                icon.Position = newPos
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            icon.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Click to toggle GUI
    local clickStart = 0
    local clickPos = Vector2.new()
    icon.MouseButton1Down:Connect(function()
        clickStart = tick()
        clickPos = icon.Position
    end)
    icon.MouseButton1Up:Connect(function()
        local elapsed = tick() - clickStart
        if elapsed < 0.3 then
            local currentPos = icon.Position
            local moved = math.abs(currentPos.X.Offset - clickPos.X.Offset) + math.abs(currentPos.Y.Offset - clickPos.Y.Offset)
            if moved < 10 then
                Core:Tween(icon, {TextSize = 22}, 0.1)
                task.delay(0.1, function()
                    Core:Tween(icon, {TextSize = 28}, 0.15, Enum.EasingStyle.Back)
                end)
                self:ToggleMainGUI()
            end
        end
    end)

    -- Hover
    icon.MouseEnter:Connect(function()
        Core:Tween(icon, {TextSize = 32}, 0.2, Enum.EasingStyle.Back)
    end)
    icon.MouseLeave:Connect(function()
        if not dragging then
            Core:Tween(icon, {TextSize = 28}, 0.2)
        end
    end)

    -- Idle subtle animation
    task.spawn(function()
        while icon.Parent do
            Core:Tween(icon, {TextTransparency = 0.15}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(2)
            Core:Tween(icon, {TextTransparency = 0}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(2)
        end
    end)
end

-- ═══════════════════════════════════
-- MAIN GUI
-- ═══════════════════════════════════
function UI:CreateMainGUI()
    local isMobile = Core:IsMobile()
    local isSmall = Core:IsSmallScreen()
    local panelWidth = isMobile and math.min(Camera.ViewportSize.X - 20, 420) or 520
    local panelHeight = isMobile and math.min(Camera.ViewportSize.Y - 80, 500) or 440
    local sidebarWidth = isMobile and 100 or 130

    local main = Core:Create("Frame", {
        Name = "MainPanel",
        Size = UDim2.new(0, panelWidth, 0, panelHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 50,
        Parent = self._screenGui,
    })
    Core:ApplyCorner(main, 12)
    Core:ApplyStroke(main, COLORS.Border, 1, 0.4)

    self._mainFrame = main

    -- Header
    local header = Core:Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.3,
        ZIndex = 51,
        Parent = main,
    })
    Core:ApplyCorner(header, 12)

    -- Fix corner for header bottom
    local headerFix = Core:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 51,
        Parent = header,
    })

    local headerTitle = Core:Create("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = "ZIZU \230\156\136",
        TextColor3 = COLORS.Text,
        Font = FONTS.Title,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
        Parent = header,
    })

    -- Search
    local searchFrame = Core:Create("Frame", {
        Name = "Search",
        Size = UDim2.new(0, 160, 0, 26),
        Position = UDim2.new(1, -170, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLORS.SurfaceLight,
        ZIndex = 52,
        Parent = header,
    })
    Core:ApplyCorner(searchFrame, 6)

    local searchBox = Core:Create("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = COLORS.TextMuted,
        TextColor3 = COLORS.Text,
        Font = FONTS.Caption,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 53,
        Parent = searchFrame,
    })

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:HandleSearch(searchBox.Text)
    end)

    -- Body
    local body = Core:Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = main,
    })

    -- Sidebar
    local sidebar = Core:Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.2,
        ZIndex = 51,
        Parent = body,
    })
    self._sidebar = sidebar

    local sideCorner = Core:Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 51,
        Parent = sidebar,
    })
    local sideCorner2 = Core:Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 51,
        Parent = sidebar,
    })

    local sideScroll = Core:Create("ScrollingFrame", {
        Name = "SideScroll",
        Size = UDim2.new(1, -8, 1, -16),
        Position = UDim2.new(0, 4, 0, 8),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 52,
        Parent = sidebar,
    })
    Core:ApplyListLayout(sideScroll, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Center)

    local tabs = {"HOME", "VISUAL", "MOVEMENT", "GAMEPLAY", "CONFIG", "ABOUT"}
    for i, tabName in ipairs(tabs) do
        self:CreateSidebarTab(sideScroll, tabName, i)
    end

    -- Content
    local content = Core:Create("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -sidebarWidth - 4, 1, -8),
        Position = UDim2.new(0, sidebarWidth + 4, 0, 4),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.BorderLight,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 51,
        Parent = body,
    })
    Core:ApplyListLayout(content, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)
    Core:ApplyPadding(content, 8, 8, 8, 8)

    self._contentArea = content

    -- Notification container
    local notifContainer = Core:Create("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 260, 1, -60),
        Position = UDim2.new(1, -270, 0, 50),
        BackgroundTransparency = 1,
        ZIndex = 180,
        Parent = self._screenGui,
    })
    Core:ApplyListLayout(notifContainer, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
    self._notifContainer = notifContainer

    -- Notification listener
    Core:On("Notification", function(title, message, duration)
        self:ShowNotification(title, message, duration)
    end)

    -- Set initial tab
    self:SwitchTab(Config:Get("ActiveTab") or "HOME")

    -- Header drag
    self:MakeDraggable(header, main)
end

function UI:MakeDraggable(handle, frame)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════
-- SIDEBAR TAB
-- ═══════════════════════════════════
function UI:CreateSidebarTab(parent, name, order)
    local btn = Core:Create("TextButton", {
        Name = "Tab_" .. name,
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundColor3 = COLORS.SurfaceLight,
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = COLORS.TextSecondary,
        Font = FONTS.Heading,
        TextSize = 11,
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 53,
        Parent = parent,
    })
    Core:ApplyCorner(btn, 6)

    local indicator = Core:Create("Frame", {
        Name = "Indicator",
        Size = UDim2.new(0, 3, 0, 18),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        ZIndex = 54,
        Parent = btn,
    })
    Core:ApplyCorner(indicator, 2)

    btn.MouseEnter:Connect(function()
        if self._activeTab ~= name then
            Core:Tween(btn, {BackgroundTransparency = 0.6}, 0.2)
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= name then
            Core:Tween(btn, {BackgroundTransparency = 1}, 0.2)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
    end)

    self._tabs[name] = {Button = btn, Indicator = indicator}
end

function UI:SwitchTab(name)
    local old = self._activeTab
    self._activeTab = name
    Config:Set("ActiveTab", name)

    for tabName, tabData in pairs(self._tabs) do
        if tabName == name then
            Core:Tween(tabData.Button, {BackgroundTransparency = 0.4, TextColor3 = COLORS.Text}, 0.2)
            Core:Tween(tabData.Indicator, {BackgroundTransparency = 0}, 0.2)
            tabData.Button.Font = FONTS.Title
        else
            Core:Tween(tabData.Button, {BackgroundTransparency = 1, TextColor3 = COLORS.TextSecondary}, 0.2)
            Core:Tween(tabData.Indicator, {BackgroundTransparency = 1}, 0.2)
            tabData.Button.Font = FONTS.Heading
        end
    end

    self:RenderTab(name)
end

-- ═══════════════════════════════════
-- RENDER TAB
-- ═══════════════════════════════════
function UI:RenderTab(name)
    local content = self._contentArea
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    if name == "HOME" then self:RenderHome(content)
    elseif name == "VISUAL" then self:RenderVisual(content)
    elseif name == "MOVEMENT" then self:RenderMovement(content)
    elseif name == "GAMEPLAY" then self:RenderGameplay(content)
    elseif name == "CONFIG" then self:RenderConfig(content)
    elseif name == "ABOUT" then self:RenderAbout(content)
    end
end

-- ═══════════════════════════════════
-- COMPONENTS
-- ═══════════════════════════════════
function UI:CreateCard(parent, title, order)
    local card = Core:Create("Frame", {
        Name = "Card_" .. (title or ""),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = COLORS.Card,
        BackgroundTransparency = 0.15,
        LayoutOrder = order or 0,
        ZIndex = 52,
        Parent = parent,
    })
    Core:ApplyCorner(card, 10)
    Core:ApplyStroke(card, COLORS.Border, 1, 0.6)
    Core:ApplyPadding(card, 12, 12, 14, 14)
    Core:ApplyListLayout(card, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left)

    if title then
        Core:Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = COLORS.Text,
            Font = FONTS.Heading,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            ZIndex = 53,
            Parent = card,
        })
    end

    return card
end

function UI:CreateToggle(parent, label, default, callback, order)
    local row = Core:Create("Frame", {
        Name = "Toggle_" .. label,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
        ZIndex = 53,
        Parent = parent,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(1, -56, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.TextSecondary,
        Font = FONTS.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 54,
        Parent = row,
    })

    local toggleBG = Core:Create("Frame", {
        Name = "ToggleBG",
        Size = UDim2.new(0, 42, 0, 22),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = default and COLORS.ToggleOn or COLORS.ToggleOff,
        ZIndex = 54,
        Parent = row,
    })
    Core:ApplyCorner(toggleBG, 11)

    local knob = Core:Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLORS.ToggleKnob,
        ZIndex = 55,
        Parent = toggleBG,
    })
    Core:ApplyCorner(knob, 8)

    local state = default or false

    local toggleBtn = Core:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 56,
        Parent = row,
    })

    local function updateVisual()
        if state then
            Core:Tween(toggleBG, {BackgroundColor3 = COLORS.ToggleOn}, 0.25)
            Core:Tween(knob, {Position = UDim2.new(1, -19, 0.5, 0)}, 0.25, Enum.EasingStyle.Back)
        else
            Core:Tween(toggleBG, {BackgroundColor3 = COLORS.ToggleOff}, 0.25)
            Core:Tween(knob, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.25, Enum.EasingStyle.Back)
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        if callback then
            Core:SafeSpawn(callback, state)
        end
    end)

    return {
        SetState = function(_, newState)
            state = newState
            updateVisual()
        end,
        GetState = function()
            return state
        end,
        Row = row,
    }
end

function UI:CreateSlider(parent, label, min, max, default, step, callback, order)
    local row = Core:Create("Frame", {
        Name = "Slider_" .. label,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
        ZIndex = 53,
        Parent = parent,
    })

    local valText = Core:Create("TextLabel", {
        Size = UDim2.new(0, 50, 0, 18),
        Position = UDim2.new(1, 0, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = COLORS.Accent,
        Font = FONTS.Mono,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 54,
        Parent = row,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(1, -56, 0, 18),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.TextSecondary,
        Font = FONTS.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 54,
        Parent = row,
    })

    local track = Core:Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundColor3 = COLORS.SurfaceLight,
        ZIndex = 54,
        Parent = row,
    })
    Core:ApplyCorner(track, 2)

    local fill = Core:Create("Frame", {
        Name = "Fill",
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        ZIndex = 55,
        Parent = track,
    })
    Core:ApplyCorner(fill, 2)

    local handle = Core:Create("Frame", {
        Name = "Handle",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = COLORS.ToggleKnob,
        ZIndex = 56,
        Parent = track,
    })
    Core:ApplyCorner(handle, 7)

    local value = default
    local sliding = false

    local function updateSlider(pct)
        pct = math.clamp(pct, 0, 1)
        local raw = min + pct * (max - min)
        if step then
            raw = math.floor(raw / step + 0.5) * step
        end
        raw = math.clamp(raw, min, max)
        value = raw
        local realPct = (raw - min) / (max - min)
        fill.Size = UDim2.new(realPct, 0, 1, 0)
        handle.Position = UDim2.new(realPct, 0, 0.5, 0)

        if label:find("Speed") or label:find("Multiplier") then
            valText.Text = string.format("%.2fx", raw)
        else
            valText.Text = tostring(math.floor(raw * 100) / 100)
        end

        if callback then
            Core:SafeSpawn(callback, raw)
        end
    end

    local function handleInput(input)
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        local mouseX = input.Position.X
        local pct = (mouseX - trackAbsPos) / trackAbsSize
        updateSlider(pct)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            handleInput(input)
        end
    end)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            handleInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    return {
        SetValue = function(_, v)
            local pct = (v - min) / (max - min)
            updateSlider(pct)
        end,
        GetValue = function() return value end,
    }
end

function UI:CreateDropdown(parent, label, options, default, callback, order)
    local row = Core:Create("Frame", {
        Name = "Dropdown_" .. label,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
        ZIndex = 53,
        ClipsDescendants = true,
        Parent = parent,
    })

    Core:ApplyListLayout(row, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Left)

    local header = Core:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        ZIndex = 54,
        Parent = row,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.TextSecondary,
        Font = FONTS.Body,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 55,
        Parent = header,
    })

    local selected = default or options[1]

    local selBtn = Core:Create("TextButton", {
        Size = UDim2.new(0.5, 0, 0, 24),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = COLORS.SurfaceLight,
        Text = selected,
        TextColor3 = COLORS.Text,
        Font = FONTS.Body,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 55,
        Parent = header,
    })
    Core:ApplyCorner(selBtn, 6)

    local optionsFrame = Core:Create("Frame", {
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 1,
        ZIndex = 54,
        Parent = row,
    })
    Core:ApplyListLayout(optionsFrame, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Left)

    for i, opt in ipairs(options) do
        local optBtn = Core:Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = COLORS.SurfaceHover,
            BackgroundTransparency = 0.5,
            Text = opt,
            TextColor3 = COLORS.TextSecondary,
            Font = FONTS.Body,
            TextSize = 12,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 56,
            Parent = optionsFrame,
        })
        Core:ApplyCorner(optBtn, 4)

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selBtn.Text = opt
            optionsFrame.Visible = false
            if callback then
                Core:SafeSpawn(callback, opt)
            end
        end)

        optBtn.MouseEnter:Connect(function()
            Core:Tween(optBtn, {BackgroundTransparency = 0.2}, 0.15)
        end)
        optBtn.MouseLeave:Connect(function()
            Core:Tween(optBtn, {BackgroundTransparency = 0.5}, 0.15)
        end)
    end

    selBtn.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
    end)

    return {
        GetSelected = function() return selected end,
        SetSelected = function(_, v)
            selected = v
            selBtn.Text = v
        end,
    }
end

function UI:CreateButton(parent, text, callback, order)
    local btn = Core:Create("TextButton", {
        Name = "Btn_" .. text,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COLORS.SurfaceLight,
        Text = text,
        TextColor3 = COLORS.Text,
        Font = FONTS.Heading,
        TextSize = 13,
        AutoButtonColor = false,
        LayoutOrder = order or 0,
        ZIndex = 53,
        Parent = parent,
    })
    Core:ApplyCorner(btn, 8)
    Core:ApplyStroke(btn, COLORS.Border, 1, 0.7)

    btn.MouseEnter:Connect(function()
        Core:Tween(btn, {BackgroundColor3 = COLORS.SurfaceHover}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Core:Tween(btn, {BackgroundColor3 = COLORS.SurfaceLight}, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        Core:Tween(btn, {BackgroundColor3 = COLORS.Accent}, 0.1)
        task.delay(0.15, function()
            Core:Tween(btn, {BackgroundColor3 = COLORS.SurfaceLight}, 0.2)
        end)
        if callback then Core:SafeSpawn(callback) end
    end)

    return btn
end

function UI:CreateInfoRow(parent, label, value, order)
    local row = Core:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
        ZIndex = 53,
        Parent = parent,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.TextMuted,
        Font = FONTS.Caption,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 54,
        Parent = row,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = COLORS.Text,
        Font = FONTS.Body,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 54,
        Parent = row,
    })

    return row
end

function UI:CreateSeparator(parent, order)
    return Core:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = COLORS.Border,
        BackgroundTransparency = 0.5,
        LayoutOrder = order or 0,
        ZIndex = 53,
        Parent = parent,
    })
end

-- ═══════════════════════════════════
-- TAB: HOME
-- ═══════════════════════════════════
function UI:RenderHome(parent)
    local card = self:CreateCard(parent, nil, 1)

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "ZIZU \230\156\136",
        TextColor3 = COLORS.Accent,
        Font = FONTS.Title,
        TextSize = 28,
        LayoutOrder = 0,
        ZIndex = 53,
        Parent = card,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "Created by zizu",
        TextColor3 = COLORS.TextSecondary,
        Font = FONTS.Caption,
        TextSize = 12,
        LayoutOrder = 1,
        ZIndex = 53,
        Parent = card,
    })

    self:CreateSeparator(card, 2)
    self:CreateInfoRow(card, "VERSION", Config:Get("Version") or "1.0.0", 3)
    self:CreateInfoRow(card, "STATUS", Config:Get("Status") or "BETA", 4)
    self:CreateInfoRow(card, "FEATURES", "14+", 5)
    self:CreateInfoRow(card, "PLATFORM", Core.State.Platform, 6)

    self:CreateSeparator(card, 7)

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "This framework is currently under development.\n\nFeatures and interface may be updated in future versions.",
        TextColor3 = COLORS.TextMuted,
        Font = FONTS.Caption,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 8,
        ZIndex = 53,
        Parent = card,
    })
end

-- ═══════════════════════════════════
-- TAB: VISUAL
-- ═══════════════════════════════════
function UI:RenderVisual(parent)
    -- ESP Player
    local espCard = self:CreateCard(parent, "PLAYER ESP", 1)
    self:CreateToggle(espCard, "ESP", Config:Get("ESP.Enabled"), function(state)
        Features.ESP:SetEnabled(state)
    end, 1)
    self:CreateToggle(espCard, "Survivor", Config:Get("ESP.Survivor"), function(state)
        Config:Set("ESP.Survivor", state)
        if Features.ESP:IsEnabled() then Features.ESP:Disable() Features.ESP:Enable() end
    end, 2)
    self:CreateToggle(espCard, "Killer", Config:Get("ESP.Killer"), function(state)
        Config:Set("ESP.Killer", state)
        if Features.ESP:IsEnabled() then Features.ESP:Disable() Features.ESP:Enable() end
    end, 3)
    self:CreateToggle(espCard, "Show Name", Config:Get("ESP.ShowName"), function(state)
        Config:Set("ESP.ShowName", state)
    end, 4)
    self:CreateToggle(espCard, "Show Distance", Config:Get("ESP.ShowDistance"), function(state)
        Config:Set("ESP.ShowDistance", state)
    end, 5)

    -- ESP World
    local espwCard = self:CreateCard(parent, "ESP WORLD", 2)
    self:CreateToggle(espwCard, "ESP World", Config:Get("ESPWorld.Enabled"), function(state)
        Features.ESPWorld:SetEnabled(state)
    end, 1)
    self:CreateToggle(espwCard, "Pallet", Config:Get("ESPWorld.Pallet"), function(state)
        Features.ESPWorld:SetCategory("Pallet", state)
    end, 2)
    self:CreateToggle(espwCard, "Generator", Config:Get("ESPWorld.Generator"), function(state)
        Features.ESPWorld:SetCategory("Generator", state)
    end, 3)
    self:CreateToggle(espwCard, "Hook", Config:Get("ESPWorld.Hook"), function(state)
        Features.ESPWorld:SetCategory("Hook", state)
    end, 4)
    self:CreateToggle(espwCard, "Gate", Config:Get("ESPWorld.Gate"), function(state)
        Features.ESPWorld:SetCategory("Gate", state)
    end, 5)
    self:CreateToggle(espwCard, "Window", Config:Get("ESPWorld.Window"), function(state)
        Features.ESPWorld:SetCategory("Window", state)
    end, 6)
    self:CreateSeparator(espwCard, 7)
    self:CreateToggle(espwCard, "Show Label", Config:Get("ESPWorld.ShowLabel"), function(state)
        Config:Set("ESPWorld.ShowLabel", state)
    end, 8)
    self:CreateToggle(espwCard, "Show Distance", Config:Get("ESPWorld.ShowDistance"), function(state)
        Config:Set("ESPWorld.ShowDistance", state)
    end, 9)

    -- Outline
    local outlineCard = self:CreateCard(parent, "OUTLINE", 3)
    self:CreateToggle(outlineCard, "Outline", Config:Get("Outline.Enabled"), function(state)
        Features.Outline:SetEnabled(state)
    end, 1)

    -- Warn Killer
    local warnCard = self:CreateCard(parent, "WARN KILLER", 4)
    self:CreateToggle(warnCard, "Warn Killer", Config:Get("WarnKiller.Enabled"), function(state)
        Features.WarnKiller:SetEnabled(state)
    end, 1)

    -- World Settings
    local wsCard = self:CreateCard(parent, "WORLD SETTINGS", 5)
    self:CreateToggle(wsCard, "Bright World", Config:Get("WorldSettings.BrightWorld"), function(state)
        Features.WorldSettings:SetBrightWorld(state)
    end, 1)
    self:CreateToggle(wsCard, "No Fog", Config:Get("WorldSettings.NoFog"), function(state)
        Features.WorldSettings:SetNoFog(state)
    end, 2)
    self:CreateToggle(wsCard, "Clear Lighting", Config:Get("WorldSettings.ClearLighting"), function(state)
        Features.WorldSettings:SetClearLighting(state)
    end, 3)
    self:CreateToggle(wsCard, "Fullbright", Config:Get("WorldSettings.Fullbright"), function(state)
        Features.WorldSettings:SetFullbright(state)
    end, 4)
end

-- ═══════════════════════════════════
-- TAB: MOVEMENT
-- ═══════════════════════════════════
function UI:RenderMovement(parent)
    local speedCard = self:CreateCard(parent, "SPEED", 1)
    self:CreateToggle(speedCard, "Anti Slow", Config:Get("Speed.AntiSlow"), function(state)
        Features.Speed:SetAntiSlow(state)
        if state and not Features.Speed:IsEnabled() then Features.Speed:Enable() end
    end, 1)
    self:CreateToggle(speedCard, "Speed Boost", Config:Get("Speed.BoostEnabled"), function(state)
        Features.Speed:SetBoost(state)
        if state and not Features.Speed:IsEnabled() then Features.Speed:Enable() end
    end, 2)
    self:CreateSlider(speedCard, "Multiplier", 1, 2, Config:Get("Speed.BoostMultiplier") or 1, 0.05, function(val)
        Features.Speed:SetMultiplier(val)
    end, 3)
    self:CreateToggle(speedCard, "Safe Speed", Config:Get("Speed.SafeSpeed"), function(state)
        Config:Set("Speed.SafeSpeed", state)
    end, 4)
end

-- ═══════════════════════════════════
-- TAB: GAMEPLAY
-- ═══════════════════════════════════
function UI:RenderGameplay(parent)
    -- Drop All
    local dropCard = self:CreateCard(parent, "DROP ALL", 1)
    self:CreateButton(dropCard, "Execute Drop All", function()
        Features.DropAll:Enable()
    end, 1)

    -- No Loop
    local noLoopCard = self:CreateCard(parent, "NO LOOP", 2)
    self:CreateToggle(noLoopCard, "No Loop", Config:Get("NoLoop.Enabled"), function(state)
        Features.NoLoop:SetEnabled(state)
    end, 1)

    -- Fake Hit
    local fakeCard = self:CreateCard(parent, "FAKE HIT", 3)
    self:CreateButton(fakeCard, "Execute Fake Hit", function()
        Features.FakeHit:Enable()
    end, 1)

    -- No Drop
    local noDropCard = self:CreateCard(parent, "NO DROP", 4)
    self:CreateToggle(noDropCard, "No Drop", Config:Get("NoDrop.Enabled"), function(state)
        Features.NoDrop:SetEnabled(state)
    end, 1)

    -- Hitbox
    local hitCard = self:CreateCard(parent, "HITBOX", 5)
    self:CreateToggle(hitCard, "Hitbox", Config:Get("Hitbox.Enabled"), function(state)
        Features.Hitbox:SetEnabled(state)
    end, 1)
    self:CreateSlider(hitCard, "Size", 1, 10, Config:Get("Hitbox.Size") or 1, 0.5, function(val)
        Features.Hitbox:SetSize(val)
    end, 2)

    -- Anti Fail Gene
    local geneCard = self:CreateCard(parent, "ANTI FAIL GENE", 6)
    self:CreateToggle(geneCard, "Anti Fail Gene", Config:Get("AntiFailGene.Enabled"), function(state)
        Features.AntiFailGene:SetEnabled(state)
    end, 1)
    self:CreateDropdown(geneCard, "Mode", {"NORMAL", "PERFECT", "INSTANT"}, Config:Get("AntiFailGene.Mode") or "NORMAL", function(mode)
        Features.AntiFailGene:SetMode(mode)
    end, 2)

    -- Block
    local blockCard = self:CreateCard(parent, "BLOCK", 7)
    self:CreateToggle(blockCard, "Block", Config:Get("Block.Enabled"), function(state)
        Features.Block:SetEnabled(state)
    end, 1)

    -- Luck
    local luckCard = self:CreateCard(parent, "LUCK", 8)
    self:CreateToggle(luckCard, "Luck", Config:Get("Luck.Enabled"), function(state)
        Features.Luck:SetEnabled(state)
    end, 1)
    self:CreateToggle(luckCard, "Infinite Ammo", Config:Get("Luck.InfiniteAmmo"), function(state)
        Features.Luck:SetInfiniteAmmo(state)
    end, 2)
    self:CreateToggle(luckCard, "No Empty Shot", Config:Get("Luck.NoEmptyShot"), function(state)
        Features.Luck:SetNoEmptyShot(state)
    end, 3)
end

-- ═══════════════════════════════════
-- TAB: CONFIG
-- ═══════════════════════════════════
function UI:RenderConfig(parent)
    local card = self:CreateCard(parent, "CONFIGURATION", 1)

    self:CreateButton(card, "Save Configuration", function()
        Config:Save()
        Core:Notify("ZIZU", "Configuration saved")
    end, 1)

    self:CreateButton(card, "Load Configuration", function()
        Config:Load()
        Features:LoadSavedStates()
        Core:Notify("ZIZU", "Configuration loaded")
        self:SwitchTab("CONFIG")
    end, 2)

    self:CreateButton(card, "Refresh", function()
        self:SwitchTab(self._activeTab)
        Core:Notify("ZIZU", "Interface refreshed")
    end, 3)

    self:CreateButton(card, "Reset to Default", function()
        Config:Reset()
        Features:DestroyAll()
        Core:Notify("ZIZU", "Configuration reset")
        self:SwitchTab("CONFIG")
    end, 4)

    self:CreateSeparator(card, 5)

    self:CreateToggle(card, "Auto Save", Config:Get("AutoSave"), function(state)
        Config:Set("AutoSave", state)
    end, 6)
end

-- ═══════════════════════════════════
-- TAB: ABOUT
-- ═══════════════════════════════════
function UI:RenderAbout(parent)
    local card = self:CreateCard(parent, nil, 1)

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "ZIZU \230\156\136",
        TextColor3 = COLORS.Accent,
        Font = FONTS.Title,
        TextSize = 28,
        LayoutOrder = 0,
        ZIndex = 53,
        Parent = card,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "Created by",
        TextColor3 = COLORS.TextMuted,
        Font = FONTS.Caption,
        TextSize = 12,
        LayoutOrder = 1,
        ZIndex = 53,
        Parent = card,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = "zizu",
        TextColor3 = COLORS.Text,
        Font = FONTS.Title,
        TextSize = 18,
        LayoutOrder = 2,
        ZIndex = 53,
        Parent = card,
    })

    self:CreateSeparator(card, 3)
    self:CreateInfoRow(card, "Version", Config:Get("Version") or "1.0.0", 4)
    self:CreateInfoRow(card, "Status", Config:Get("Status") or "BETA", 5)

    self:CreateSeparator(card, 6)

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "ZIZU is a modern client-side framework for Roblox Experiences. It provides visual enhancements, gameplay utilities, and a premium interface.\n\nAll features integrate with real game systems using official Roblox APIs. No exploit-only APIs are used.\n\nThis project is for educational and personal use.",
        TextColor3 = COLORS.TextMuted,
        Font = FONTS.Caption,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 7,
        ZIndex = 53,
        Parent = card,
    })
end

-- ═══════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════
function UI:ShowNotification(title, message, duration)
    duration = duration or 3
    if not self._notifContainer then return end

    local notif = Core:Create("Frame", {
        Name = "Notif",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        ZIndex = 181,
        Parent = self._notifContainer,
    })
    Core:ApplyCorner(notif, 8)
    Core:ApplyStroke(notif, COLORS.Border, 1, 0.5)
    Core:ApplyPadding(notif, 8, 8, 10, 10)

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = COLORS.Accent,
        Font = FONTS.Heading,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 182,
        Parent = notif,
    })

    Core:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = COLORS.TextSecondary,
        Font = FONTS.Caption,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 182,
        Parent = notif,
    })

    -- Slide in
    notif.Position = UDim2.new(1, 20, 0, 0)
    Core:Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)

    task.delay(duration, function()
        if notif.Parent then
            local t = Core:Tween(notif, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)}, 0.3)
            t.Completed:Connect(function()
                notif:Destroy()
            end)
        end
    end)
end

-- ═══════════════════════════════════
-- SEARCH
-- ═══════════════════════════════════
function UI:HandleSearch(query)
    if query == "" then
        self:RenderTab(self._activeTab)
        return
    end

    query = query:lower()

    local featureMap = {
        {name = "ESP", tab = "VISUAL", keywords = {"esp", "player", "survivor", "killer", "highlight"}},
        {name = "ESP World", tab = "VISUAL", keywords = {"esp world", "pallet", "generator", "hook", "gate", "window", "world esp"}},
        {name = "Outline", tab = "VISUAL", keywords = {"outline"}},
        {name = "Warn Killer", tab = "VISUAL", keywords = {"warn", "killer", "warning", "danger"}},
        {name = "World Settings", tab = "VISUAL", keywords = {"world", "bright", "fog", "lighting", "fullbright"}},
        {name = "Speed", tab = "MOVEMENT", keywords = {"speed", "fast", "slow", "movement", "walk"}},
        {name = "Drop All", tab = "GAMEPLAY", keywords = {"drop", "pallet", "drop all"}},
        {name = "No Loop", tab = "GAMEPLAY", keywords = {"loop", "no loop", "window"}},
        {name = "Fake Hit", tab = "GAMEPLAY", keywords = {"fake", "hit", "animation"}},
        {name = "No Drop", tab = "GAMEPLAY", keywords = {"no drop", "block drop"}},
        {name = "Hitbox", tab = "GAMEPLAY", keywords = {"hitbox", "hit", "box", "size"}},
        {name = "Anti Fail Gene", tab = "GAMEPLAY", keywords = {"anti", "fail", "gene", "generator", "skill", "check"}},
        {name = "Block", tab = "GAMEPLAY", keywords = {"block", "weapon", "gun", "dagger"}},
        {name = "Luck", tab = "GAMEPLAY", keywords = {"luck", "ammo", "infinite", "bullet"}},
        {name = "Config", tab = "CONFIG", keywords = {"config", "save", "load", "reset", "auto save"}},
    }

    local content = self._contentArea
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    local results = {}
    for _, f in ipairs(featureMap) do
        for _, kw in ipairs(f.keywords) do
            if kw:find(query) then
                table.insert(results, f)
                break
            end
        end
    end

    if #results == 0 then
        Core:Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Text = "No results found",
            TextColor3 = COLORS.TextMuted,
            Font = FONTS.Caption,
            TextSize = 13,
            ZIndex = 53,
            Parent = content,
        })
        return
    end

    for i, result in ipairs(results) do
        local card = Core:Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = COLORS.Card,
            BackgroundTransparency = 0.15,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 52,
            Parent = content,
        })
        Core:ApplyCorner(card, 8)
        Core:ApplyPadding(card, 8, 8, 12, 12)

        Core:Create("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = result.name,
            TextColor3 = COLORS.Text,
            Font = FONTS.Heading,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 53,
            Parent = card,
        })

        Core:Create("TextLabel", {
            Size = UDim2.new(0.4, 0, 0, 14),
            Position = UDim2.new(0.6, 0, 0, 1),
            BackgroundTransparency = 1,
            Text = result.tab,
            TextColor3 = COLORS.TextMuted,
            Font = FONTS.Caption,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 53,
            Parent = card,
        })

        card.MouseButton1Click:Connect(function()
            self:SwitchTab(result.tab)
        end)

        card.MouseEnter:Connect(function()
            Core:Tween(card, {BackgroundTransparency = 0}, 0.15)
        end)
        card.MouseLeave:Connect(function()
            Core:Tween(card, {BackgroundTransparency = 0.15}, 0.15)
        end)

        -- Animate in
        card.BackgroundTransparency = 1
        task.delay(i * 0.05, function()
            Core:Tween(card, {BackgroundTransparency = 0.15}, 0.3)
        end)
    end
end

-- ═══════════════════════════════════
-- TOGGLE MAIN GUI
-- ═══════════════════════════════════
function UI:ToggleMainGUI()
    if self._isOpen then
        self:HideMainGUI()
    else
        self:ShowMainGUI()
    end
end

function UI:ShowMainGUI()
    if self._isOpen then return end
    self._isOpen = true

    local main = self._mainFrame
    main.Visible = true
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1

    Core:SetBlur(true, 10)

    Core:Tween(main, {
        Size = UDim2.new(0, Core:IsMobile() and math.min(Camera.ViewportSize.X - 20, 420) or 520, 0, Core:IsMobile() and math.min(Camera.ViewportSize.Y - 80, 500) or 440),
        BackgroundTransparency = 0.05,
    }, 0.4, Enum.EasingStyle.Back)
end

function UI:HideMainGUI()
    if not self._isOpen then return end
    self._isOpen = false

    Core:SetBlur(false)

    local t = Core:Tween(self._mainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

    t.Completed:Connect(function()
        if not self._isOpen then
            self._mainFrame.Visible = false
        end
    end)
end

-- ═══════════════════════════════════
-- BUILD ALL
-- ═══════════════════════════════════
function UI:Build()
    self:CreateScreenGui()
    self:CreateMainGUI()
    self:CreateFloatingIcon()
    return self
end

function UI:Destroy()
    if self._screenGui then
        self._screenGui:Destroy()
    end
end

return UI
