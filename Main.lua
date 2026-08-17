--[[
    ██╗  ██╗██╗   ██╗ █████╗ ███╗   ██╗
    ╚██╗██╔╝╚██╗ ██╔╝██╔══██╗████╗  ██║
     ╚███╔╝  ╚████╔╝ ███████║██╔██╗ ██║
     ██╔██╗   ╚██╔╝  ██╔══██║██║╚██╗██║
    ██╔╝ ██╗   ██║   ██║  ██║██║ ╚████║
    ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝
    
    XYAN — Experimental Developer Interface
    Created by Zaki
    Status: Experimental / Testing
    
    A premium, glassmorphism-styled utility interface
    with ESP, Crosshair, Visuals, and more.
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- CONFIGURATION
-- ============================================================
local Config = {
    ESP = {
        Enabled = false,
        Distance = 1000,
        OutlineColor = Color3.fromRGB(140, 120, 255),
        FillColor = Color3.fromRGB(140, 120, 255),
        OutlineTransparency = 0,
        FillTransparency = 0.75,
    },
    Crosshair = {
        Enabled = false,
        Type = 1,
        Size = 12,
        Thickness = 2,
        Gap = 5,
        Opacity = 1,
        Color = Color3.fromRGB(255, 255, 255),
        CenterDot = false,
        CenterDotSize = 3,
    },
    Visuals = {
        NoFog = false,
        FullBright = false,
    },
    UI = {
        Blur = true,
        Animation = true,
        Scale = 1,
    },
}

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background = Color3.fromRGB(14, 14, 18),
    BackgroundTransparency = 0.08,
    Panel = Color3.fromRGB(20, 20, 26),
    PanelTransparency = 0.15,
    Card = Color3.fromRGB(26, 26, 34),
    CardTransparency = 0.25,
    CardHover = Color3.fromRGB(34, 34, 44),
    Sidebar = Color3.fromRGB(16, 16, 21),
    SidebarTransparency = 0.1,
    Header = Color3.fromRGB(16, 16, 21),
    HeaderTransparency = 0.05,
    Accent = Color3.fromRGB(140, 120, 255),
    AccentDim = Color3.fromRGB(100, 85, 180),
    AccentGlow = Color3.fromRGB(160, 140, 255),
    Text = Color3.fromRGB(230, 230, 240),
    TextSecondary = Color3.fromRGB(150, 150, 170),
    TextMuted = Color3.fromRGB(100, 100, 120),
    TextAccent = Color3.fromRGB(160, 145, 255),
    Border = Color3.fromRGB(50, 50, 65),
    BorderTransparency = 0.6,
    Toggle = {
        On = Color3.fromRGB(140, 120, 255),
        Off = Color3.fromRGB(50, 50, 65),
        Knob = Color3.fromRGB(240, 240, 250),
    },
    Notification = Color3.fromRGB(22, 22, 30),
    StatusGreen = Color3.fromRGB(80, 200, 120),
    Scrollbar = Color3.fromRGB(60, 60, 80),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontSemibold = Enum.Font.GothamSemibold,
    FontLight = Enum.Font.Gotham,
    CornerRadius = UDim.new(0, 10),
    CornerRadiusSmall = UDim.new(0, 6),
    CornerRadiusLarge = UDim.new(0, 14),
    TweenSpeed = 0.25,
    TweenSpeedFast = 0.15,
    TweenSpeedSlow = 0.35,
    EaseStyle = Enum.EasingStyle.Quint,
    EaseDir = Enum.EasingDirection.Out,
}

-- ============================================================
-- CONNECTION MANAGER
-- ============================================================
local ConnectionManager = {}
ConnectionManager._connections = {}

function ConnectionManager:Add(name, connection)
    if self._connections[name] then
        self._connections[name]:Disconnect()
    end
    self._connections[name] = connection
    return connection
end

function ConnectionManager:Remove(name)
    if self._connections[name] then
        self._connections[name]:Disconnect()
        self._connections[name] = nil
    end
end

function ConnectionManager:Clear()
    for name, conn in pairs(self._connections) do
        conn:Disconnect()
    end
    self._connections = {}
end

-- ============================================================
-- CLEANUP MANAGER
-- ============================================================
local CleanupManager = {}
CleanupManager._items = {}

function CleanupManager:Add(name, item)
    self._items[name] = item
end

function CleanupManager:Remove(name)
    local item = self._items[name]
    if item then
        if typeof(item) == "Instance" then
            item:Destroy()
        elseif typeof(item) == "RBXScriptConnection" then
            item:Disconnect()
        elseif type(item) == "function" then
            item()
        end
        self._items[name] = nil
    end
end

function CleanupManager:Clear()
    for name, item in pairs(self._items) do
        if typeof(item) == "Instance" then
            item:Destroy()
        elseif typeof(item) == "RBXScriptConnection" then
            item:Disconnect()
        elseif type(item) == "function" then
            item()
        end
    end
    self._items = {}
end

-- ============================================================
-- UTILITY
-- ============================================================
local Utility = {}

function Utility.Tween(obj, props, duration, style, dir)
    if not Config.UI.Animation then
        for k, v in pairs(props) do
            obj[k] = v
        end
        return nil
    end
    duration = duration or Theme.TweenSpeed
    style = style or Theme.EaseStyle
    dir = dir or Theme.EaseDir
    local tween = TweenService:Create(obj, TweenInfo.new(duration, style, dir), props)
    tween:Play()
    return tween
end

function Utility.Create(class, props, children)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                pcall(function() obj[k] = v end)
            end
        end
        if props.Parent then
            obj.Parent = props.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = obj
        end
    end
    return obj
end

function Utility.AddCorner(parent, radius)
    return Utility.Create("UICorner", {
        CornerRadius = radius or Theme.CornerRadius,
        Parent = parent,
    })
end

function Utility.AddStroke(parent, color, thickness, transparency)
    return Utility.Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or Theme.BorderTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

function Utility.AddPadding(parent, t, b, l, r)
    return Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft = UDim.new(0, l or 8),
        PaddingRight = UDim.new(0, r or 8),
        Parent = parent,
    })
end

function Utility.AddListLayout(parent, padding, direction, hAlign, vAlign, sortOrder)
    return Utility.Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

function Utility.IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utility.GetScale()
    local base = Config.UI.Scale or 1
    if Utility.IsMobile() then
        return base * 0.85
    end
    return base
end

-- ============================================================
-- SAVED LIGHTING STATE
-- ============================================================
local SavedLighting = {
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
}

-- ============================================================
-- ESP CACHE
-- ============================================================
local ESPCache = {}

-- ============================================================
-- GUI CLEANUP (prevent duplicates)
-- ============================================================
local GUI_NAME = "XYAN_GUI"

local function CleanExistingGUI()
    -- Try CoreGui first
    local existing = nil
    pcall(function()
        existing = CoreGui:FindFirstChild(GUI_NAME)
    end)
    if existing then existing:Destroy() end
    
    -- Also check PlayerGui
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local ex2 = playerGui:FindFirstChild(GUI_NAME)
        if ex2 then ex2:Destroy() end
    end
end

CleanExistingGUI()

-- ============================================================
-- CREATE SCREENGUI
-- ============================================================
local ScreenGui

local function CreateScreenGui()
    CleanExistingGUI()
    
    local gui = Instance.new("ScreenGui")
    gui.Name = GUI_NAME
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    
    local ok = pcall(function()
        gui.Parent = CoreGui
    end)
    if not ok then
        pcall(function()
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    
    return gui
end

ScreenGui = CreateScreenGui()

-- ============================================================
-- BLUR EFFECT
-- ============================================================
local BlurEffect = nil

local function CreateBlur()
    if BlurEffect then return end
    BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Name = "XYAN_Blur"
    BlurEffect.Size = 0
    BlurEffect.Parent = Lighting
    CleanupManager:Add("blur", BlurEffect)
end

local function ShowBlur()
    if not Config.UI.Blur then return end
    if not BlurEffect then CreateBlur() end
    Utility.Tween(BlurEffect, {Size = 10}, 0.3)
end

local function HideBlur()
    if BlurEffect then
        Utility.Tween(BlurEffect, {Size = 0}, 0.3)
    end
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotificationContainer

local function CreateNotificationContainer()
    NotificationContainer = Utility.Create("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 260, 1, 0),
        Position = UDim2.new(1, -270, 0, 0),
        BackgroundTransparency = 1,
        Parent = ScreenGui,
    })
    Utility.AddListLayout(NotificationContainer, 8, Enum.FillDirection.Vertical, 
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
    Utility.AddPadding(NotificationContainer, 0, 50, 0, 10)
end

local function Notify(text, duration)
    if not NotificationContainer then CreateNotificationContainer() end
    duration = duration or 2.5
    
    local notif = Utility.Create("Frame", {
        Name = "Notif",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Notification,
        BackgroundTransparency = 0.15,
        Parent = NotificationContainer,
    })
    Utility.AddCorner(notif, Theme.CornerRadiusSmall)
    Utility.AddStroke(notif, Theme.Border, 1, 0.7)
    
    -- Accent bar
    Utility.Create("Frame", {
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 8, 0.2, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })
    
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notif,
    })
    
    -- Animate in
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.BackgroundTransparency = 1
    Utility.Tween(notif, {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0.15}, 0.3)
    
    task.delay(duration, function()
        if notif and notif.Parent then
            local t = Utility.Tween(notif, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            if t then t.Completed:Wait() end
            if notif and notif.Parent then notif:Destroy() end
        end
    end)
end

-- ============================================================
-- MAIN GUI FRAME
-- ============================================================
local GUI_WIDTH = 620
local GUI_HEIGHT = 420
local SIDEBAR_WIDTH = 145
local HEADER_HEIGHT = 42

local MainFrame, Header, Sidebar, ContentArea, ContentPages
local CurrentPage = "HOME"
local IsOpen = true
local IsMinimized = false

-- ============================================================
-- BUILD MAIN FRAME
-- ============================================================
local function BuildMainFrame()
    local scale = Utility.GetScale()
    local w = math.floor(GUI_WIDTH * scale)
    local h = math.floor(GUI_HEIGHT * scale)
    
    -- Outer container for scaling and dragging
    MainFrame = Utility.Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Theme.BackgroundTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    Utility.AddCorner(MainFrame, Theme.CornerRadiusLarge)
    Utility.AddStroke(MainFrame, Theme.Border, 1, 0.5)
    
    -- Shadow
    local shadow = Utility.Create("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0,
        Parent = MainFrame,
    })
    
    -- ============================================
    -- HEADER
    -- ============================================
    Header = Utility.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        BackgroundColor3 = Theme.Header,
        BackgroundTransparency = Theme.HeaderTransparency,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = MainFrame,
    })
    
    -- Header bottom border
    Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = Header,
    })
    
    -- Brand: xyan
    Utility.Create("TextLabel", {
        Name = "Brand",
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = "xyan",
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
        Parent = Header,
    })
    
    -- Status: Experimental
    Utility.Create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(1, -135, 0, 0),
        BackgroundTransparency = 1,
        Text = "Experimental",
        TextColor3 = Theme.TextMuted,
        Font = Theme.FontLight,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 11,
        Parent = Header,
    })
    
    -- Minimize Button
    local minimizeBtn = Utility.Create("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -35, 0.5, -14),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = 0.5,
        Text = "-",
        TextColor3 = Theme.TextSecondary,
        Font = Theme.FontBold,
        TextSize = 18,
        ZIndex = 12,
        BorderSizePixel = 0,
        Parent = Header,
    })
    Utility.AddCorner(minimizeBtn, Theme.CornerRadiusSmall)
    
    minimizeBtn.MouseButton1Click:Connect(function()
        if IsMinimized then
            -- Restore
            IsMinimized = false
            Utility.Tween(MainFrame, {
                Size = UDim2.new(0, w, 0, h),
            }, 0.35)
            minimizeBtn.Text = "-"
        else
            -- Minimize
            IsMinimized = true
            Utility.Tween(MainFrame, {
                Size = UDim2.new(0, w, 0, HEADER_HEIGHT),
            }, 0.35)
            minimizeBtn.Text = "+"
        end
    end)
    
    -- ============================================
    -- DRAGGING
    -- ============================================
    local dragging = false
    local dragStart, startPos
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ============================================
    -- SIDEBAR
    -- ============================================
    Sidebar = Utility.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        Position = UDim2.new(0, 0, 0, HEADER_HEIGHT),
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = Theme.SidebarTransparency,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = MainFrame,
    })
    
    -- Sidebar right border
    Utility.Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = Sidebar,
    })
    
    local sidebarContent = Utility.Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -70),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    Utility.AddPadding(sidebarContent, 12, 8, 10, 10)
    Utility.AddListLayout(sidebarContent, 4)
    
    -- Sidebar footer
    local sidebarFooter = Utility.Create("Frame", {
        Name = "Footer",
        Size = UDim2.new(1, 0, 0, 65),
        Position = UDim2.new(0, 0, 1, -65),
        BackgroundTransparency = 1,
        ZIndex = 6,
        Parent = Sidebar,
    })
    Utility.AddPadding(sidebarFooter, 6, 10, 12, 12)
    
    -- Footer brand
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = "xyan",
        TextColor3 = Theme.TextMuted,
        Font = Theme.FontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = sidebarFooter,
    })
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "Created by Zaki",
        TextColor3 = Theme.TextMuted,
        Font = Theme.FontLight,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = sidebarFooter,
    })
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 0, 29),
        BackgroundTransparency = 1,
        Text = "Experimental / Testing",
        TextColor3 = Theme.TextMuted,
        Font = Theme.FontLight,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = sidebarFooter,
    })
    
    -- Status indicator
    local statusFrame = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = 7,
        Parent = sidebarFooter,
    })
    Utility.Create("Frame", {
        Size = UDim2.new(0, 5, 0, 5),
        Position = UDim2.new(0, 0, 0.5, -2),
        BackgroundColor3 = Theme.StatusGreen,
        BorderSizePixel = 0,
        ZIndex = 8,
        Parent = statusFrame,
    }):FindFirstChildOfClass("UICorner") or Utility.AddCorner(
        statusFrame:FindFirstChild("Frame") or Utility.Create("Frame", {Parent = statusFrame}), 
        UDim.new(1, 0)
    )
    -- Fix: properly add corner to status dot
    for _, child in ipairs(statusFrame:GetChildren()) do
        if child:IsA("Frame") then
            Utility.AddCorner(child, UDim.new(1, 0))
            break
        end
    end
    
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -12, 0, 12),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "SYSTEM READY",
        TextColor3 = Theme.TextMuted,
        Font = Theme.FontLight,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = statusFrame,
    })
    
    -- ============================================
    -- SIDEBAR BUTTONS
    -- ============================================
    local sidebarButtons = {}
    local pages = {"HOME", "ESP", "CROSSHAIR", "VISUALS", "SETTINGS"}
    
    for i, pageName in ipairs(pages) do
        local btn = Utility.Create("TextButton", {
            Name = pageName,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            ZIndex = 7,
            LayoutOrder = i,
            Parent = sidebarContent,
        })
        Utility.AddCorner(btn, Theme.CornerRadiusSmall)
        
        local label = Utility.Create("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Text = pageName,
            TextColor3 = Theme.TextSecondary,
            Font = Theme.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8,
            Parent = btn,
        })
        
        -- Active indicator (left bar)
        local indicator = Utility.Create("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, 3, 0.5, 0),
            Position = UDim2.new(0, 3, 0.25, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 9,
            Parent = btn,
        })
        Utility.AddCorner(indicator, UDim.new(1, 0))
        
        sidebarButtons[pageName] = {Button = btn, Label = label, Indicator = indicator}
        
        btn.MouseButton1Click:Connect(function()
            if CurrentPage ~= pageName then
                SwitchPage(pageName)
            end
        end)
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            if CurrentPage ~= pageName then
                Utility.Tween(btn, {BackgroundTransparency = 0.85}, Theme.TweenSpeedFast)
            end
        end)
        btn.MouseLeave:Connect(function()
            if CurrentPage ~= pageName then
                Utility.Tween(btn, {BackgroundTransparency = 1}, Theme.TweenSpeedFast)
            end
        end)
    end
    
    -- ============================================
    -- CONTENT AREA
    -- ============================================
    ContentArea = Utility.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        Position = UDim2.new(0, SIDEBAR_WIDTH, 0, HEADER_HEIGHT),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = MainFrame,
    })
    
    ContentPages = {}
    
    -- Update sidebar selection
    function SwitchPage(pageName)
        -- Deactivate previous
        if sidebarButtons[CurrentPage] then
            local prev = sidebarButtons[CurrentPage]
            Utility.Tween(prev.Button, {BackgroundTransparency = 1}, Theme.TweenSpeedFast)
            Utility.Tween(prev.Label, {TextColor3 = Theme.TextSecondary}, Theme.TweenSpeedFast)
            Utility.Tween(prev.Indicator, {BackgroundTransparency = 1}, Theme.TweenSpeedFast)
        end
        
        -- Hide current content
        if ContentPages[CurrentPage] then
            local cp = ContentPages[CurrentPage]
            Utility.Tween(cp, {BackgroundTransparency = 1}, Theme.TweenSpeedFast)
            task.delay(Theme.TweenSpeedFast, function()
                if cp and cp.Parent then cp.Visible = false end
            end)
        end
        
        CurrentPage = pageName
        
        -- Activate new
        local cur = sidebarButtons[CurrentPage]
        Utility.Tween(cur.Button, {BackgroundTransparency = 0.82}, Theme.TweenSpeedFast)
        Utility.Tween(cur.Label, {TextColor3 = Theme.Text}, Theme.TweenSpeedFast)
        Utility.Tween(cur.Indicator, {BackgroundTransparency = 0}, Theme.TweenSpeedFast)
        
        -- Show new content
        if ContentPages[CurrentPage] then
            local cp = ContentPages[CurrentPage]
            cp.Visible = true
            Utility.Tween(cp, {BackgroundTransparency = 1}, Theme.TweenSpeedFast)
        end
    end
end

-- ============================================================
-- REUSABLE UI COMPONENTS
-- ============================================================

-- Toggle Component
local function CreateToggle(parent, label, default, callback, layoutOrder)
    local container = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
    Utility.AddCorner(container, Theme.CornerRadiusSmall)
    Utility.AddStroke(container, Theme.Border, 1, 0.75)
    
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -65, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    
    local toggleBg = Utility.Create("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and Theme.Toggle.On or Theme.Toggle.Off,
        BorderSizePixel = 0,
        Parent = container,
    })
    Utility.AddCorner(toggleBg, UDim.new(1, 0))
    
    local knob = Utility.Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Theme.Toggle.Knob,
        BorderSizePixel = 0,
        Parent = toggleBg,
    })
    Utility.AddCorner(knob, UDim.new(1, 0))
    
    local state = default or false
    
    local btn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
        Parent = container,
    })
    
    local function updateVisual()
        if state then
            Utility.Tween(toggleBg, {BackgroundColor3 = Theme.Toggle.On}, Theme.TweenSpeedFast)
            Utility.Tween(knob, {Position = UDim2.new(1, -18, 0.5, -8)}, Theme.TweenSpeedFast)
        else
            Utility.Tween(toggleBg, {BackgroundColor3 = Theme.Toggle.Off}, Theme.TweenSpeedFast)
            Utility.Tween(knob, {Position = UDim2.new(0, 2, 0.5, -8)}, Theme.TweenSpeedFast)
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        if callback then callback(state) end
    end)
    
    return {
        Container = container,
        SetState = function(newState)
            state = newState
            updateVisual()
        end,
        GetState = function() return state end,
    }
end

-- Slider Component
local function CreateSlider(parent, label, min, max, default, callback, layoutOrder, formatFunc)
    local container = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
    Utility.AddCorner(container, Theme.CornerRadiusSmall)
    Utility.AddStroke(container, Theme.Border, 1, 0.75)
    
    local displayVal = formatFunc and formatFunc(default) or tostring(default)
    
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -80, 0, 18),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    
    local valueLabel = Utility.Create("TextLabel", {
        Size = UDim2.new(0, 60, 0, 18),
        Position = UDim2.new(1, -70, 0, 6),
        BackgroundTransparency = 1,
        Text = displayVal,
        TextColor3 = Theme.TextAccent,
        Font = Theme.FontSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container,
    })
    
    local sliderBg = Utility.Create("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 34),
        BackgroundColor3 = Theme.Toggle.Off,
        BorderSizePixel = 0,
        Parent = container,
    })
    Utility.AddCorner(sliderBg, UDim.new(1, 0))
    
    local pct = (default - min) / math.max(max - min, 1)
    
    local sliderFill = Utility.Create("Frame", {
        Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = sliderBg,
    })
    Utility.AddCorner(sliderFill, UDim.new(1, 0))
    
    local sliderKnob = Utility.Create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(math.clamp(pct, 0, 1), -7, 0.5, -7),
        BackgroundColor3 = Theme.Toggle.Knob,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = sliderBg,
    })
    Utility.AddCorner(sliderKnob, UDim.new(1, 0))
    
    local sliderBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, -9),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
        Parent = sliderBg,
    })
    
    local sliding = false
    local currentValue = default
    
    local function updateSlider(inputX)
        local absPos = sliderBg.AbsolutePosition.X
        local absSize = sliderBg.AbsoluteSize.X
        local rel = math.clamp((inputX - absPos) / absSize, 0, 1)
        currentValue = math.floor(min + rel * (max - min))
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        sliderKnob.Position = UDim2.new(rel, -7, 0.5, -7)
        valueLabel.Text = formatFunc and formatFunc(currentValue) or tostring(currentValue)
        if callback then callback(currentValue) end
    end
    
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlider(input.Position.X)
        end
    end)
    
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    
    ConnectionManager:Add("slider_" .. label, UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end))
    
    return {
        Container = container,
        GetValue = function() return currentValue end,
        SetValue = function(val)
            currentValue = val
            local p = (val - min) / math.max(max - min, 1)
            sliderFill.Size = UDim2.new(math.clamp(p, 0, 1), 0, 1, 0)
            sliderKnob.Position = UDim2.new(math.clamp(p, 0, 1), -7, 0.5, -7)
            valueLabel.Text = formatFunc and formatFunc(val) or tostring(val)
        end,
    }
end

-- Dropdown Component
local function CreateDropdown(parent, label, options, default, callback, layoutOrder)
    local isExpanded = false
    local selectedIndex = default or 1
    
    local container = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
    Utility.AddCorner(container, Theme.CornerRadiusSmall)
    Utility.AddStroke(container, Theme.Border, 1, 0.75)
    
    local headerBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
        Parent = container,
    })
    
    Utility.Create("TextLabel", {
        Size = UDim2.new(0.5, -10, 0, 38),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = container,
    })
    
    local selectedLabel = Utility.Create("TextLabel", {
        Size = UDim2.new(0.5, -20, 0, 38),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = options[selectedIndex] or "",
        TextColor3 = Theme.TextAccent,
        Font = Theme.FontSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 6,
        Parent = container,
    })
    
    -- Options list
    local optionsList = Utility.Create("ScrollingFrame", {
        Size = UDim2.new(1, -8, 0, 0),
        Position = UDim2.new(0, 4, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, #options * 28),
        ZIndex = 7,
        Visible = false,
        Parent = container,
    })
    Utility.AddListLayout(optionsList, 2)
    
    for i, opt in ipairs(options) do
        local optBtn = Utility.Create("TextButton", {
            Size = UDim2.new(1, -4, 0, 26),
            BackgroundColor3 = i == selectedIndex and Theme.Accent or Theme.Card,
            BackgroundTransparency = i == selectedIndex and 0.7 or 0.5,
            Text = opt,
            TextColor3 = i == selectedIndex and Theme.Text or Theme.TextSecondary,
            Font = Theme.Font,
            TextSize = 12,
            BorderSizePixel = 0,
            ZIndex = 8,
            LayoutOrder = i,
            Parent = optionsList,
        })
        Utility.AddCorner(optBtn, UDim.new(0, 4))
        
        optBtn.MouseButton1Click:Connect(function()
            selectedIndex = i
            selectedLabel.Text = opt
            if callback then callback(i, opt) end
            
            -- Update highlight
            for _, child in ipairs(optionsList:GetChildren()) do
                if child:IsA("TextButton") then
                    local idx = child.LayoutOrder
                    if idx == i then
                        Utility.Tween(child, {BackgroundTransparency = 0.7, BackgroundColor3 = Theme.Accent}, Theme.TweenSpeedFast)
                        child.TextColor3 = Theme.Text
                    else
                        Utility.Tween(child, {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Card}, Theme.TweenSpeedFast)
                        child.TextColor3 = Theme.TextSecondary
                    end
                end
            end
            
            -- Collapse
            isExpanded = false
            optionsList.Visible = false
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 38)}, Theme.TweenSpeedFast)
        end)
    end
    
    headerBtn.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        if isExpanded then
            local listHeight = math.min(#options * 28 + 8, 200)
            optionsList.Visible = true
            optionsList.Size = UDim2.new(1, -8, 0, listHeight)
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 38 + listHeight + 8)}, Theme.TweenSpeed)
        else
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 38)}, Theme.TweenSpeedFast)
            task.delay(Theme.TweenSpeedFast, function()
                optionsList.Visible = false
            end)
        end
    end)
    
    return {
        Container = container,
        GetSelected = function() return selectedIndex, options[selectedIndex] end,
        SetSelected = function(idx)
            selectedIndex = idx
            selectedLabel.Text = options[idx] or ""
        end,
    }
end

-- Section Header
local function CreateSectionHeader(parent, text, layoutOrder)
    return Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.TextMuted,
        Font = Theme.FontSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
end

-- Glass Card (for HOME)
local function CreateGlassCard(parent, layoutOrder)
    local card = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
    Utility.AddCorner(card, Theme.CornerRadius)
    Utility.AddStroke(card, Theme.Border, 1, 0.7)
    Utility.AddPadding(card, 16, 16, 18, 18)
    
    local content = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    })
    Utility.AddListLayout(content, 6)
    
    return card, content
end

-- Text paragraph helper for HOME
local function AddParagraph(parent, text, layoutOrder, size, color, font)
    return Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Theme.TextSecondary,
        Font = font or Theme.FontLight,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
end

local function AddHeading(parent, text, layoutOrder, size, color, font)
    return Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Theme.Text,
        Font = font or Theme.FontBold,
        TextSize = size or 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
end

-- Button Component
local function CreateButton(parent, label, callback, layoutOrder, destructive)
    local btn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = destructive and Color3.fromRGB(180, 50, 50) or Theme.Card,
        BackgroundTransparency = destructive and 0.3 or Theme.CardTransparency,
        Text = label,
        TextColor3 = destructive and Color3.fromRGB(255, 180, 180) or Theme.Text,
        Font = Theme.Font,
        TextSize = 13,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
    Utility.AddCorner(btn, Theme.CornerRadiusSmall)
    Utility.AddStroke(btn, Theme.Border, 1, 0.75)
    
    btn.MouseEnter:Connect(function()
        Utility.Tween(btn, {BackgroundTransparency = 0.1}, Theme.TweenSpeedFast)
    end)
    btn.MouseLeave:Connect(function()
        Utility.Tween(btn, {BackgroundTransparency = destructive and 0.3 or Theme.CardTransparency}, Theme.TweenSpeedFast)
    end)
    
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    
    return btn
end

-- ============================================================
-- COLOR PICKER COMPONENT
-- ============================================================
local function CreateColorPicker(parent, label, defaultColor, callback, layoutOrder)
    local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
    local isOpen = false
    
    local container = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = layoutOrder or 0,
        Parent = parent,
    })
    Utility.AddCorner(container, Theme.CornerRadiusSmall)
    Utility.AddStroke(container, Theme.Border, 1, 0.75)
    
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 38),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Text,
        Font = Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = container,
    })
    
    local preview = Utility.Create("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -36, 0, 8),
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = container,
    })
    Utility.AddCorner(preview, UDim.new(0, 4))
    Utility.AddStroke(preview, Theme.Border, 1, 0.5)
    
    local headerBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
        Parent = container,
    })
    
    -- Color picker area
    local pickerFrame = Utility.Create("Frame", {
        Size = UDim2.new(1, -16, 0, 120),
        Position = UDim2.new(0, 8, 0, 42),
        BackgroundTransparency = 1,
        ZIndex = 6,
        Visible = false,
        Parent = container,
    })
    
    -- Hue bar
    local hueBar = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 7,
        Parent = pickerFrame,
    })
    Utility.AddCorner(hueBar, UDim.new(0, 4))
    
    -- Hue gradient
    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
    })
    hueGradient.Parent = hueBar
    
    -- Saturation/Value field
    local svField = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 7,
        Parent = pickerFrame,
    })
    Utility.AddCorner(svField, UDim.new(0, 4))
    
    -- White overlay
    local whiteOverlay = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 8,
        Parent = svField,
    })
    Utility.AddCorner(whiteOverlay, UDim.new(0, 4))
    local whiteGrad = Instance.new("UIGradient")
    whiteGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    whiteGrad.Transparency = NumberSequence.new(0, 1)
    whiteGrad.Parent = whiteOverlay
    
    -- Black overlay
    local blackOverlay = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 9,
        Parent = svField,
    })
    Utility.AddCorner(blackOverlay, UDim.new(0, 4))
    local blackGrad = Instance.new("UIGradient")
    blackGrad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
    blackGrad.Transparency = NumberSequence.new(1, 0)
    blackGrad.Rotation = 90
    blackGrad.Parent = blackOverlay
    
    -- Presets
    local presetFrame = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 97),
        BackgroundTransparency = 1,
        ZIndex = 7,
        Parent = pickerFrame,
    })
    local presetLayout = Utility.AddListLayout(presetFrame, 4, Enum.FillDirection.Horizontal)
    
    local presets = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(140, 120, 255),
        Color3.fromRGB(255, 80, 80),
        Color3.fromRGB(80, 255, 120),
        Color3.fromRGB(80, 200, 255),
        Color3.fromRGB(255, 200, 80),
        Color3.fromRGB(255, 120, 200),
        Color3.fromRGB(200, 200, 200),
    }
    
    local h, s, v = Color3.toHSV(currentColor)
    
    local function updateColor()
        currentColor = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = currentColor
        svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        if callback then callback(currentColor) end
    end
    
    for _, preset in ipairs(presets) do
        local pBtn = Utility.Create("TextButton", {
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundColor3 = preset,
            Text = "",
            BorderSizePixel = 0,
            ZIndex = 8,
            Parent = presetFrame,
        })
        Utility.AddCorner(pBtn, UDim.new(0, 3))
        
        pBtn.MouseButton1Click:Connect(function()
            h, s, v = Color3.toHSV(preset)
            updateColor()
        end)
    end
    
    -- Hue interaction
    local hueDragging = false
    local hueBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10,
        Parent = hueBar,
    })
    
    local function updateHue(inputX)
        local rel = math.clamp((inputX - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
        h = rel
        updateColor()
    end
    
    hueBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            updateHue(input.Position.X)
        end
    end)
    hueBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)
    
    -- SV interaction
    local svDragging = false
    local svBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10,
        Parent = svField,
    })
    
    local function updateSV(inputX, inputY)
        s = math.clamp((inputX - svField.AbsolutePosition.X) / svField.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp((inputY - svField.AbsolutePosition.Y) / svField.AbsoluteSize.Y, 0, 1)
        updateColor()
    end
    
    svBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
            updateSV(input.Position.X, input.Position.Y)
        end
    end)
    svBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)
    
    ConnectionManager:Add("colorpicker_" .. label, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if hueDragging then updateHue(input.Position.X) end
            if svDragging then updateSV(input.Position.X, input.Position.Y) end
        end
    end))
    
    headerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            pickerFrame.Visible = true
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 170)}, Theme.TweenSpeed)
        else
            Utility.Tween(container, {Size = UDim2.new(1, 0, 0, 38)}, Theme.TweenSpeedFast)
            task.delay(Theme.TweenSpeedFast, function()
                pickerFrame.Visible = false
            end)
        end
    end)
    
    return {
        Container = container,
        GetColor = function() return currentColor end,
        SetColor = function(c)
            h, s, v = Color3.toHSV(c)
            updateColor()
        end,
    }
end

-- ============================================================
-- BUILD PAGES
-- ============================================================

-- ============================================
-- HOME PAGE
-- ============================================
local function BuildHomePage()
    local page = Utility.Create("ScrollingFrame", {
        Name = "HOME",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = true,
        Parent = ContentArea,
    })
    Utility.AddPadding(page, 20, 30, 20, 20)
    Utility.AddListLayout(page, 16)
    
    ContentPages["HOME"] = page
    
    -- ---- HERO ----
    local card1, c1 = CreateGlassCard(page, 1)
    
    AddHeading(c1, "xyan", 1, 28, Theme.Text, Theme.FontBold)
    AddParagraph(c1, "Experimental Developer  /  UI Designer  /  Creator", 2, 12, Theme.TextMuted, Theme.FontLight)
    
    Utility.Create("Frame", {
        Size = UDim2.new(0.3, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        Parent = c1,
    })
    
    AddHeading(c1, "Hey. I'm Zaki.", 4, 18, Theme.TextAccent)
    
    AddParagraph(c1, "Kalau kamu sampai masuk ke bagian HOME ini, berarti kemungkinan besar kamu sedang penasaran sebenarnya siapa orang yang membuat XYAN, kenapa project ini dibuat, dan kenapa seseorang bisa menghabiskan begitu banyak waktu hanya untuk mengurus sesuatu yang awalnya mungkin cuma sebuah ide random.", 5)
    AddParagraph(c1, "Jadi, daripada saya cuma menaruh tulisan \"Welcome to XYAN\" lalu selesai, sekalian saja saya cerita sedikit. Atau mungkin tidak sedikit. Karena kalau sudah mulai ngomong tentang project, development, desain, ide random, dan segala sesuatu yang ada di kepala saya ketika membuat sesuatu, biasanya susah berhenti.", 6)
    AddParagraph(c1, "Jadi anggap saja bagian HOME ini sebagai tempat saya sedikit yapping.", 7)
    AddParagraph(c1, "Tidak ada presentasi formal.\nTidak ada bahasa perusahaan.\nTidak ada kalimat corporate yang kaku.", 8, 13, Theme.TextMuted)
    AddParagraph(c1, "Ini cuma saya.", 9)
    AddParagraph(c1, "Zaki.", 10, 15, Theme.Text, Theme.FontSemibold)
    AddParagraph(c1, "Seorang developer yang entah kenapa bisa menghabiskan waktu berjam-jam hanya karena merasa satu tombol masih kurang enak dilihat.", 11)
    
    -- ---- WHO AM I? ----
    local card2, c2 = CreateGlassCard(page, 2)
    AddHeading(c2, "WHO AM I, ACTUALLY?", 1, 16, Theme.Text)
    AddParagraph(c2, "Nama saya Zaki.", 2)
    AddParagraph(c2, "Saya seorang developer yang suka membuat sesuatu dari ide yang kadang-kadang bahkan belum jelas bentuk akhirnya seperti apa.", 3)
    AddParagraph(c2, "Saya suka coding, tetapi kalau ditanya kenapa saya suka coding, jawabannya mungkin bukan karena saya suka duduk berjam-jam melihat kode.", 4)
    AddParagraph(c2, "Saya suka coding karena dari sesuatu yang awalnya cuma tulisan dan simbol di layar, saya bisa menghasilkan sesuatu yang benar-benar bisa dilihat, digunakan, dan dirasakan.", 5)
    AddParagraph(c2, "Ada sesuatu yang menurut saya menarik dari proses itu.", 6)
    AddParagraph(c2, "Kamu punya sebuah ide.\nIde itu awalnya cuma ada di kepala.\nKemudian kamu mulai menulis kode.\nKodenya error.\nKamu cari tahu.\nError lagi.\nKamu perbaiki.\nTiba-tiba muncul error lain.\nKamu perbaiki lagi.", 7, 13, Theme.TextMuted)
    AddParagraph(c2, "Kemudian setelah entah berapa lama, sesuatu yang tadinya cuma ada di kepala akhirnya muncul di layar.", 8)
    AddParagraph(c2, "Dan ketika akhirnya berhasil, ada rasa puas yang susah dijelaskan.", 9, 13, Theme.TextAccent)
    AddParagraph(c2, "Bahkan untuk sesuatu yang mungkin terlihat kecil bagi orang lain.\nMisalnya cuma sebuah animasi.\nCuma sebuah dropdown.\nCuma sebuah button.\nCuma sebuah sistem kecil.", 10, 13, Theme.TextMuted)
    AddParagraph(c2, "Tapi saya tahu berapa banyak proses yang terjadi di belakangnya.\nDan justru proses itulah yang membuat saya suka development.", 11)
    
    -- ---- HOW DID I GET INTO THIS? ----
    local card3, c3 = CreateGlassCard(page, 3)
    AddHeading(c3, "HOW DID I GET INTO THIS?", 1, 16, Theme.Text)
    AddParagraph(c3, "Saya tidak langsung menjadi orang yang tahu semuanya.\nBahkan sampai sekarang pun saya masih sering menemukan sesuatu yang membuat saya berpikir, \"Oh, ternyata bisa seperti ini.\"", 2)
    AddParagraph(c3, "Saya mulai dari rasa penasaran.", 3)
    AddParagraph(c3, "Penasaran bagaimana sesuatu dibuat.\nPenasaran bagaimana website bekerja.\nPenasaran bagaimana aplikasi melakukan sesuatu ketika tombol ditekan.\nPenasaran bagaimana game mengetahui posisi player.\nPenasaran bagaimana interface berubah ketika kita melakukan sesuatu.", 4, 13, Theme.TextMuted)
    AddParagraph(c3, "Dan dari rasa penasaran itu, saya mulai mencoba.\nKadang berhasil.\nKadang gagal total.\nKadang kode terlihat masuk akal tetapi ternyata tidak bekerja sama sekali.\nKadang satu kesalahan kecil bisa membuat seluruh project tidak berjalan.", 5)
    AddParagraph(c3, "Dan semakin sering mengalami hal seperti itu, saya justru semakin penasaran.", 6, 13, Theme.TextAccent)
    AddParagraph(c3, "Saya mulai sadar bahwa development bukan tentang selalu benar.\nDevelopment banyak tentang salah, mencoba lagi, mencari tahu kenapa salah, kemudian mencoba cara lain.", 7)
    
    -- ---- THE REALITY OF CODING ----
    local card4, c4 = CreateGlassCard(page, 4)
    AddHeading(c4, "THE REALITY OF CODING", 1, 16, Theme.Text)
    AddParagraph(c4, "Dari luar, coding mungkin terlihat keren.\nLaptop terbuka.\nTerminal terbuka.\nEditor terbuka.\nKode memenuhi layar.\nLalu orang berpikir, \"Wah, programmer.\"", 2, 13, Theme.TextMuted)
    AddParagraph(c4, "Kenyataannya?", 3, 14, Theme.Text, Theme.FontSemibold)
    AddParagraph(c4, "Kadang saya hanya duduk selama tiga puluh menit karena satu tanda kurung hilang.\nKadang saya sudah yakin kodenya benar, tetapi ternyata salah nama variable.\nKadang fitur yang menurut saya harusnya selesai dalam satu jam malah berubah menjadi project seharian.\nKadang saya memperbaiki satu bug lalu muncul tiga bug baru.", 4)
    AddParagraph(c4, "Kadang saya membuat sesuatu yang sebenarnya sudah bekerja dengan baik, kemudian saya berpikir:\n\"Kayaknya bisa dibuat lebih bagus.\"\nDan itu adalah awal dari masalah baru.", 5, 13, Theme.TextAccent)
    AddParagraph(c4, "Karena setelah itu saya mulai mengubah satu bagian.\nKemudian bagian lain ikut berubah.\nKemudian layout berubah.\nKemudian animasi berubah.\nKemudian saya merasa font-nya kurang cocok.\nKemudian spacing-nya terasa aneh.\nKemudian saya mengubah semuanya.", 6, 13, Theme.TextMuted)
    AddParagraph(c4, "Dan akhirnya saya melihat project tersebut beberapa jam kemudian sambil berpikir:\n\"Kenapa saya mulai ini?\"", 7)
    AddParagraph(c4, "Tapi besoknya saya buka lagi.\nKarena ternyata saya masih penasaran.", 8, 13, Theme.TextAccent)
    
    -- ---- WHY I CARE ABOUT DETAILS ----
    local card5, c5 = CreateGlassCard(page, 5)
    AddHeading(c5, "WHY I CARE ABOUT DETAILS", 1, 16, Theme.Text)
    AddParagraph(c5, "Salah satu hal yang mungkin cukup kelihatan dari project saya adalah saya cukup memperhatikan detail.", 2)
    AddParagraph(c5, "Bukan karena saya ingin semuanya terlihat sempurna.\nSaya tahu sesuatu tidak akan pernah benar-benar sempurna.\nTapi saya percaya detail kecil bisa mengubah bagaimana seseorang merasakan sebuah project.", 3, 13, Theme.TextMuted)
    AddParagraph(c5, "Contohnya animasi.\nSebuah tombol tanpa animasi tetap bisa bekerja.\nTapi ketika tombol tersebut memberikan respons kecil ketika disentuh, pengguna bisa merasa bahwa interface tersebut benar-benar merespons mereka.", 4)
    AddParagraph(c5, "Contoh lain adalah spacing.\nMungkin orang tidak akan berkata:\n\"Wow, padding card ini sangat bagus.\"\nMereka mungkin bahkan tidak sadar.\nTetapi mereka bisa merasa bahwa interface tersebut nyaman.", 5)
    AddParagraph(c5, "Itulah yang saya suka.\nDetail yang tidak selalu disadari, tetapi tetap terasa.", 6, 13, Theme.TextAccent)
    
    -- ---- MY DESIGN PHILOSOPHY ----
    local card6, c6 = CreateGlassCard(page, 6)
    AddHeading(c6, "MY DESIGN PHILOSOPHY", 1, 16, Theme.Text)
    AddParagraph(c6, "Saya suka desain modern.\nSaya suka glass effect.\nSaya suka blur.\nSaya suka typography yang bagus.\nSaya suka animasi.\nSaya suka interface yang terlihat premium.", 2)
    AddParagraph(c6, "Tetapi saya juga tidak ingin semua hal dibuat menyala-nyala hanya supaya terlihat keren.", 3, 13, Theme.TextMuted)
    AddParagraph(c6, "Menurut saya, desain yang bagus bukan tentang memasukkan sebanyak mungkin efek.\nJustru terkadang semakin sedikit yang digunakan, semakin bagus hasilnya.", 4, 13, Theme.TextAccent)
    AddParagraph(c6, "Saya ingin ketika seseorang membuka XYAN, mereka tidak langsung merasa sedang melihat kumpulan tombol yang ditempel di layar.\nSaya ingin mereka merasa bahwa semuanya memang ditempatkan di sana dengan alasan.", 5)
    AddParagraph(c6, "Warna memiliki alasan.\nSpacing memiliki alasan.\nAnimasi memiliki alasan.\nTypography memiliki alasan.\nBahkan ketika sebuah elemen tidak bergerak pun, itu juga bisa menjadi keputusan desain.", 6, 13, Theme.TextMuted)
    
    -- ---- WHY I LOVE UI ----
    local card7, c7 = CreateGlassCard(page, 7)
    AddHeading(c7, "WHY I LOVE UI", 1, 16, Theme.Text)
    AddParagraph(c7, "Saya cukup suka UI karena UI adalah tempat coding dan design bertemu.", 2)
    AddParagraph(c7, "Kamu bisa memiliki sistem yang sangat kompleks di belakang layar.\nTetapi pengguna tidak perlu tahu betapa rumitnya sistem tersebut.\nMereka hanya perlu melihat interface yang sederhana dan memahami cara menggunakannya.", 3)
    AddParagraph(c7, "Dan menurut saya, itu keren.\nMembuat sesuatu yang kompleks terasa sederhana adalah salah satu hal yang paling saya sukai.", 4, 13, Theme.TextAccent)
    AddParagraph(c7, "Saya tidak ingin pengguna harus berpikir terlalu lama hanya untuk mengetahui apa yang harus dilakukan.\nKalau ada dropdown, harus terlihat seperti dropdown.\nKalau ada toggle, harus terasa seperti toggle.\nKalau sebuah panel bisa dibuka, harus ada feedback bahwa panel tersebut memang sedang dibuka.", 5)
    AddParagraph(c7, "Hal-hal seperti itu mungkin terdengar kecil.\nTetapi ketika semuanya digabungkan, pengalaman pengguna bisa berubah banyak.", 6, 13, Theme.TextMuted)
    
    -- ---- WHY I LIKE EXPERIMENTAL PROJECTS ----
    local card8, c8 = CreateGlassCard(page, 8)
    AddHeading(c8, "WHY I LIKE EXPERIMENTAL PROJECTS", 1, 16, Theme.Text)
    AddParagraph(c8, "Saya suka project yang sifatnya experimental.\nKarena ketika sesuatu disebut experimental, saya merasa punya ruang untuk mencoba.", 2)
    AddParagraph(c8, "Tidak harus langsung sempurna.\nTidak harus langsung menjadi produk besar.\nTidak harus semuanya sudah direncanakan dari awal.", 3, 13, Theme.TextMuted)
    AddParagraph(c8, "Saya bisa mencoba sebuah ide.\nKalau bagus, saya pertahankan.\nKalau jelek, saya buang.\nKalau hampir bagus, saya perbaiki.\nKalau ternyata idenya lebih menarik dari yang saya kira, saya kembangkan.", 4)
    AddParagraph(c8, "Menurut saya, banyak hal menarik justru muncul dari eksperimen.", 5, 13, Theme.TextAccent)
    
    -- ---- SO... WHY XYAN? ----
    local card9, c9 = CreateGlassCard(page, 9)
    AddHeading(c9, "SO... WHY XYAN?", 1, 16, Theme.Text)
    AddParagraph(c9, "XYAN pada dasarnya adalah tempat untuk eksperimen.\nSaya ingin membuat sesuatu yang bukan hanya memiliki fungsi, tetapi juga memiliki identitas.", 2)
    AddParagraph(c9, "Saya tidak ingin membuka project ini dan melihat sebuah UI standar yang terasa seperti dibuat hanya untuk memenuhi kebutuhan.\nSaya ingin ada rasa.\nAda karakter.\nAda style.", 3, 13, Theme.TextMuted)
    AddParagraph(c9, "Ada sesuatu yang membuat orang melihatnya dan langsung tahu:\n\"Oh, ini XYAN.\"", 4, 13, Theme.TextAccent)
    AddParagraph(c9, "Karena itu saya cukup memperhatikan visual identity-nya.\nMulai dari nama.\nTypography.\nLayout.\nGlass effect.\nBlur.\nTransparansi.\nAnimasi.\nCara dropdown dibuka.\nCara toggle bergerak.\nCara halaman berganti.\nBahkan hal-hal yang mungkin sebenarnya tidak wajib pun tetap saya pikirkan.", 5)
    AddParagraph(c9, "Bukan karena semuanya harus rumit.\nTapi karena saya ingin project ini terasa seperti satu kesatuan.", 6, 13, Theme.TextMuted)
    
    -- ---- XYAN IS NOT FINISHED ----
    local card10, c10 = CreateGlassCard(page, 10)
    AddHeading(c10, "XYAN IS NOT FINISHED", 1, 16, Theme.Text)
    AddParagraph(c10, "Saya tidak akan bilang XYAN adalah project yang sempurna.\nKarena memang tidak.", 2)
    AddParagraph(c10, "Masih ada hal yang bisa diperbaiki.\nMasih ada hal yang mungkin bisa dibuat lebih ringan.\nMasih ada desain yang bisa dibuat lebih bagus.\nMasih ada interaction yang mungkin bisa dibuat lebih smooth.\nMasih ada fitur yang bisa dikembangkan.", 3, 13, Theme.TextMuted)
    AddParagraph(c10, "Dan mungkin suatu hari saya akan melihat versi lama XYAN lalu berpikir:\n\"Kenapa dulu saya membuatnya seperti itu?\"", 4)
    AddParagraph(c10, "Tapi menurut saya itu normal.\nProject yang terus berkembang memang akan berubah.\nKalau sebuah project tidak pernah berubah sama sekali, mungkin justru karena project tersebut sudah ditinggalkan.", 5, 13, Theme.TextMuted)
    AddParagraph(c10, "Saya lebih suka melihat XYAN sebagai sesuatu yang terus berkembang.", 6, 13, Theme.TextAccent)
    
    -- ---- THE WAY I LEARN ----
    local card11, c11 = CreateGlassCard(page, 11)
    AddHeading(c11, "THE WAY I LEARN", 1, 16, Theme.Text)
    AddParagraph(c11, "Saya bukan tipe orang yang harus selalu memahami semuanya terlebih dahulu baru mulai membuat sesuatu.\nKadang saya justru belajar ketika sedang membuatnya.", 2)
    AddParagraph(c11, "Saya punya ide.\nSaya mulai.\nKemudian saya menemukan bagian yang tidak saya pahami.\nSaya cari tahu.\nSaya coba.\nKalau gagal, saya cari cara lain.\nDari situ saya belajar.", 3, 13, Theme.TextMuted)
    AddParagraph(c11, "Saya percaya bahwa teori memang penting.\nTapi ada sesuatu yang berbeda ketika kamu benar-benar membangun sesuatu.", 4)
    AddParagraph(c11, "Karena ketika kamu membangun sesuatu, masalahnya tidak lagi abstrak.\nKamu punya masalah nyata.\nKamu punya error nyata.\nKamu punya batasan nyata.\nDan kamu harus menemukan solusi nyata.", 5, 13, Theme.TextAccent)
    
    -- ---- MY FAVORITE PART ----
    local card12, c12 = CreateGlassCard(page, 12)
    AddHeading(c12, "MY FAVORITE PART", 1, 16, Theme.Text)
    AddParagraph(c12, "Ada satu momen dalam development yang menurut saya selalu menyenangkan.", 2)
    AddParagraph(c12, "Setelah berjam-jam debugging.\nSetelah berkali-kali mencoba.\nSetelah membuka console entah berapa kali.\nSetelah mengubah kode.\nSetelah mengembalikan kode.\nSetelah mencoba cara lain.", 3, 13, Theme.TextMuted)
    AddParagraph(c12, "Tiba-tiba...\nberhasil.", 4, 15, Theme.TextAccent, Theme.FontSemibold)
    AddParagraph(c12, "Tidak ada error.\nAnimasi berjalan.\nUI muncul.\nFitur bekerja.\nSemuanya terasa benar.", 5)
    AddParagraph(c12, "Dan untuk beberapa detik saya biasanya cuma melihat layar.\nTidak melakukan apa-apa.\nCuma menikmati hasilnya.", 6, 13, Theme.TextMuted)
    AddParagraph(c12, "Mungkin bagi orang lain itu cuma sebuah fitur kecil.\nTapi bagi saya, itu adalah hasil dari proses yang panjang.", 7)
    
    -- ---- RANDOM PROJECTS ----
    local card13, c13 = CreateGlassCard(page, 13)
    AddHeading(c13, "RANDOM PROJECTS", 1, 16, Theme.Text)
    AddParagraph(c13, "Tidak semua project saya selalu punya tujuan yang sangat serius.\nKadang saya cuma ingin mencoba sesuatu.", 2)
    AddParagraph(c13, "Kadang saya melihat sebuah efek lalu berpikir:\n\"Bisa nggak ya saya bikin seperti itu?\"\nKemudian saya coba.", 3, 13, Theme.TextMuted)
    AddParagraph(c13, "Kadang saya melihat UI di suatu tempat dan berpikir:\n\"Kalau dibuat dengan style saya sendiri bakal seperti apa?\"\nSaya coba juga.", 4)
    AddParagraph(c13, "Kadang saya punya ide random ketika sedang tidak melakukan apa-apa.\nKemudian saya buka editor.\nLima menit kemudian project baru dibuat.\nDan tiba-tiba beberapa jam sudah berlalu.", 5, 13, Theme.TextMuted)
    AddParagraph(c13, "Saya rasa itu salah satu bagian dari menjadi developer yang memang suka membuat sesuatu.", 6, 13, Theme.TextAccent)
    
    -- ---- MY BIGGEST ENEMY ----
    local card14, c14 = CreateGlassCard(page, 14)
    AddHeading(c14, "MY BIGGEST ENEMY", 1, 16, Theme.Text)
    AddParagraph(c14, "Perfectionism.", 2, 15, Theme.TextAccent, Theme.FontSemibold)
    AddParagraph(c14, "Atau mungkin lebih tepatnya...\n\"Kayaknya masih bisa dibagusin.\"\nKalimat itu sangat berbahaya.", 3)
    AddParagraph(c14, "Karena satu perubahan kecil bisa berubah menjadi satu jam kerja.", 4, 13, Theme.TextMuted)
    AddParagraph(c14, "Saya bisa saja sudah selesai.\nProject sudah berjalan.\nSemua fitur sudah ada.\nTetapi kemudian saya melihat sesuatu.", 5)
    AddParagraph(c14, "\"Hmm.\"\n\"Kayaknya spacing-nya kurang.\"\nSaya ubah.\n\"Hmm, sekarang card-nya terlalu besar.\"\nSaya ubah.\n\"Font-nya kayaknya kurang cocok.\"\nSaya ganti.\n\"Animasi ini terlalu cepat.\"\nSaya ubah.\n\"Sekarang animasi yang lain jadi terasa aneh.\"\nSaya ubah lagi.", 6, 13, Theme.TextMuted)
    AddParagraph(c14, "Dan begitulah.\nSelamat datang di development.", 7, 13, Theme.TextAccent)
    
    -- ---- WHAT I WANT TO IMPROVE ----
    local card15, c15 = CreateGlassCard(page, 15)
    AddHeading(c15, "WHAT I WANT TO IMPROVE", 1, 16, Theme.Text)
    AddParagraph(c15, "Saya masih jauh dari kata ahli.\nDan saya tidak masalah mengakuinya.", 2)
    AddParagraph(c15, "Masih banyak hal yang ingin saya pelajari.\nMasih banyak konsep yang ingin saya pahami lebih dalam.\nMasih banyak teknologi yang belum saya coba.\nMasih banyak desain yang ingin saya eksplorasi.\nMasih banyak project yang ingin saya buat.", 3, 13, Theme.TextMuted)
    AddParagraph(c15, "Saya ingin menjadi developer yang bukan hanya bisa membuat sesuatu berjalan, tetapi juga memahami kenapa sesuatu tersebut bekerja.", 4)
    AddParagraph(c15, "Saya ingin terus meningkatkan kemampuan coding.\nMeningkatkan UI.\nMeningkatkan UX.\nMeningkatkan performance.\nMeningkatkan cara saya menyelesaikan masalah.", 5, 13, Theme.TextMuted)
    AddParagraph(c15, "Dan yang paling penting, saya ingin tetap penasaran.", 6, 13, Theme.TextAccent)
    
    -- ---- THE FUTURE ----
    local card16, c16 = CreateGlassCard(page, 16)
    AddHeading(c16, "THE FUTURE", 1, 16, Theme.Text)
    AddParagraph(c16, "Saya tidak benar-benar tahu.\nDan mungkin itu bagian yang menarik.", 2)
    AddParagraph(c16, "Saya punya banyak hal yang ingin saya coba.\nBanyak project yang ingin saya buat.\nBanyak ide yang belum sempat saya realisasikan.", 3, 13, Theme.TextMuted)
    AddParagraph(c16, "Mungkin suatu hari saya akan fokus ke web development lebih jauh.\nMungkin saya akan membuat aplikasi.\nMungkin saya akan membuat project yang jauh lebih besar.\nMungkin saya akan menemukan bidang lain yang ternyata saya suka.", 4)
    AddParagraph(c16, "Saya tidak ingin terlalu membatasi diri.", 5, 13, Theme.TextAccent)
    AddParagraph(c16, "Untuk sekarang, saya ingin terus membuat.\nTerus belajar.\nTerus mencoba.\nDan melihat sejauh mana saya bisa berkembang.", 6, 13, Theme.TextMuted)
    
    -- ---- WHAT XYAN MEANS TO ME ----
    local card17, c17 = CreateGlassCard(page, 17)
    AddHeading(c17, "WHAT XYAN MEANS TO ME", 1, 16, Theme.Text)
    AddParagraph(c17, "XYAN mungkin terlihat seperti sebuah interface.\nTetapi bagi saya, XYAN juga merupakan representasi dari cara saya membuat sesuatu.", 2)
    AddParagraph(c17, "Eksperimen.\nIterasi.\nMencoba.\nMemperbaiki.\nMengubah.\nMengulang.", 3, 13, Theme.TextMuted)
    AddParagraph(c17, "Saya tidak ingin project ini hanya menjadi sesuatu yang selesai lalu ditinggalkan.\nSaya ingin terus melihatnya berkembang.", 4)
    AddParagraph(c17, "Karena setiap versi baru adalah hasil dari sesuatu yang saya pelajari sebelumnya.", 5, 13, Theme.TextAccent)
    
    -- ---- BUILD. BREAK. LEARN. ----
    local card18, c18 = CreateGlassCard(page, 18)
    AddHeading(c18, "BUILD.", 1, 22, Theme.Text, Theme.FontBold)
    AddParagraph(c18, "Buat sesuatu.", 2, 13, Theme.TextMuted)
    AddHeading(c18, "BREAK.", 3, 22, Theme.Text, Theme.FontBold)
    AddParagraph(c18, "Jangan takut kalau sesuatu rusak.", 4, 13, Theme.TextMuted)
    AddHeading(c18, "LEARN.", 5, 22, Theme.Text, Theme.FontBold)
    AddParagraph(c18, "Cari tahu kenapa.", 6, 13, Theme.TextMuted)
    AddHeading(c18, "FIX.", 7, 22, Theme.Text, Theme.FontBold)
    AddParagraph(c18, "Perbaiki.", 8, 13, Theme.TextMuted)
    AddHeading(c18, "REPEAT.", 9, 22, Theme.TextAccent, Theme.FontBold)
    AddParagraph(c18, "Lakukan lagi.", 10, 13, Theme.TextMuted)
    
    Utility.Create("Frame", {
        Size = UDim2.new(0.3, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        LayoutOrder = 11,
        Parent = c18,
    })
    
    AddParagraph(c18, "Itu mungkin bukan metode development yang paling sempurna.\nTapi sejauh ini, itulah cara saya belajar paling banyak.", 12)
    
    -- ---- MESSAGE ----
    local card19, c19 = CreateGlassCard(page, 19)
    AddHeading(c19, "MESSAGE", 1, 16, Theme.Text)
    AddParagraph(c19, "Kalau kamu benar-benar membaca sampai bagian ini...", 2)
    AddParagraph(c19, "Respect.", 3, 15, Theme.TextAccent, Theme.FontSemibold)
    AddParagraph(c19, "Karena saya sendiri mungkin tidak akan membaca tulisan sepanjang ini kalau tidak ada alasan.", 4, 13, Theme.TextMuted)
    AddParagraph(c19, "Tapi kalau kamu masih di sini, berarti sekarang kamu sedikit lebih tahu siapa yang berada di balik XYAN.", 5)
    AddParagraph(c19, "Saya bukan developer yang sudah mengetahui semuanya.\nSaya masih belajar.\nMasih mencoba.\nMasih membuat kesalahan.\nMasih kadang bingung.\nMasih kadang stuck di masalah yang seharusnya sederhana.", 6, 13, Theme.TextMuted)
    AddParagraph(c19, "Tapi saya menikmati prosesnya.\nDan mungkin itu yang paling penting.", 7)
    AddParagraph(c19, "Karena saya tidak ingin hanya mengejar hasil.\nSaya juga ingin menikmati perjalanan menuju hasil tersebut.", 8, 13, Theme.TextAccent)
    
    -- ---- AND THAT'S BASICALLY ME ----
    local card20, c20 = CreateGlassCard(page, 20)
    AddHeading(c20, "AND THAT'S BASICALLY ME.", 1, 18, Theme.Text, Theme.FontBold)
    AddParagraph(c20, "Jadi...", 2)
    AddParagraph(c20, "Saya Zaki.\nSaya suka coding.\nSaya suka design.\nSaya suka UI.\nSaya suka membuat sesuatu.\nSaya suka bereksperimen.\nSaya suka mencoba hal baru.\nSaya suka memperbaiki sesuatu sampai terasa benar.", 3)
    AddParagraph(c20, "Saya suka membuat project yang mungkin awalnya terlihat random tetapi kemudian berkembang menjadi sesuatu yang jauh lebih besar dari yang saya bayangkan.", 4, 13, Theme.TextMuted)
    AddParagraph(c20, "Saya tidak selalu tahu apa yang saya lakukan.\nKadang saya cuma mencoba dan berharap berhasil.\nKadang berhasil.\nKadang tidak.\nKadang saya harus mengulang dari awal.", 5)
    AddParagraph(c20, "Tapi saya tetap lanjut.\nKarena pada akhirnya, saya rasa itulah yang membuat development menarik.", 6, 13, Theme.TextAccent)
    AddParagraph(c20, "Bukan karena semuanya mudah.\nJustru karena tidak semuanya mudah.\nKalau semuanya mudah, mungkin tidak akan terasa seseru ini.", 7, 13, Theme.TextMuted)
    AddParagraph(c20, "Saya masih punya banyak hal untuk dipelajari.\nBanyak project untuk dibuat.\nBanyak ide untuk dicoba.\nBanyak desain untuk dieksplorasi.\nBanyak kode untuk ditulis.\nDan mungkin banyak bug untuk diperbaiki.", 8)
    AddParagraph(c20, "Tapi untuk sekarang...", 9, 13, Theme.TextMuted)
    AddParagraph(c20, "Ini adalah XYAN.", 10, 15, Theme.Text, Theme.FontSemibold)
    AddParagraph(c20, "Salah satu project yang saya buat dari rasa penasaran, eksperimen, dan keinginan untuk membuat sesuatu yang punya identitas sendiri.", 11)
    AddParagraph(c20, "Mungkin project ini akan terus berubah.\nMungkin suatu hari tampilannya akan berbeda.\nMungkin fiturnya akan bertambah.\nMungkin beberapa bagian akan saya hapus dan saya buat ulang.", 12, 13, Theme.TextMuted)
    AddParagraph(c20, "Tapi satu hal yang tidak berubah adalah alasan saya membuatnya.", 13, 13, Theme.TextAccent)
    AddParagraph(c20, "Saya suka membuat sesuatu.\nSesederhana itu.", 14)
    AddParagraph(c20, "Dari ide kecil.\nMenjadi sesuatu yang nyata.", 15, 13, Theme.TextMuted)
    AddParagraph(c20, "Dan kalau kamu sedang membaca ini sambil melihat interface XYAN...\nberarti kamu sedang melihat salah satu hasil dari proses tersebut.", 16)
    
    Utility.Create("Frame", {
        Size = UDim2.new(0.3, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        LayoutOrder = 17,
        Parent = c20,
    })
    
    AddParagraph(c20, "Thanks for being here.\nThanks for checking out XYAN.", 18, 13, Theme.TextAccent)
    AddParagraph(c20, "And yeah...\nI think I've talked enough.\nFor now.", 19, 13, Theme.TextMuted)
    AddParagraph(c20, "Karena kalau saya lanjut lagi, bagian HOME ini bisa berubah menjadi buku.", 20)
    
    -- ---- FINAL FOOTER ----
    local card21, c21 = CreateGlassCard(page, 21)
    AddHeading(c21, "xyan", 1, 16, Theme.TextMuted, Theme.FontBold)
    AddParagraph(c21, "Created, designed & experimented by Zaki", 2, 12, Theme.TextMuted)
    AddParagraph(c21, "Experimental Project", 3, 11, Theme.TextMuted)
    AddParagraph(c21, "Still learning. Still building. Still experimenting.", 4, 12, Theme.TextAccent)
    
    Utility.Create("Frame", {
        Size = UDim2.new(0.2, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        LayoutOrder = 5,
        Parent = c21,
    })
    
    AddParagraph(c21, "-- Zaki", 6, 13, Theme.TextMuted, Theme.FontSemibold)
end

-- ============================================
-- ESP PAGE
-- ============================================

local function ApplyESP(player)
    if player == LocalPlayer then return end
    if ESPCache[player] then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "XYAN_ESP"
    highlight.Adornee = character
    highlight.FillColor = Config.ESP.FillColor
    highlight.OutlineColor = Config.ESP.OutlineColor
    highlight.FillTransparency = Config.ESP.FillTransparency
    highlight.OutlineTransparency = Config.ESP.OutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    ESPCache[player] = {
        Highlight = highlight,
        CharConn = nil,
    }
    
    -- Handle character respawn
    ESPCache[player].CharConn = player.CharacterAdded:Connect(function(newChar)
        if ESPCache[player] and ESPCache[player].Highlight then
            ESPCache[player].Highlight:Destroy()
        end
        task.wait(0.5)
        if Config.ESP.Enabled and player.Character then
            local newHL = Instance.new("Highlight")
            newHL.Name = "XYAN_ESP"
            newHL.Adornee = player.Character
            newHL.FillColor = Config.ESP.FillColor
            newHL.OutlineColor = Config.ESP.OutlineColor
            newHL.FillTransparency = Config.ESP.FillTransparency
            newHL.OutlineTransparency = Config.ESP.OutlineTransparency
            newHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            newHL.Parent = player.Character
            if ESPCache[player] then
                ESPCache[player].Highlight = newHL
            end
        end
    end)
end

local function RemoveESP(player)
    if ESPCache[player] then
        if ESPCache[player].Highlight then
            ESPCache[player].Highlight:Destroy()
        end
        if ESPCache[player].CharConn then
            ESPCache[player].CharConn:Disconnect()
        end
        ESPCache[player] = nil
    end
end

local function EnableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ApplyESP(player)
        end
    end
    
    ConnectionManager:Add("esp_playerAdded", Players.PlayerAdded:Connect(function(player)
        if Config.ESP.Enabled then
            player.CharacterAdded:Wait()
            task.wait(0.5)
            if Config.ESP.Enabled then
                ApplyESP(player)
            end
        end
    end))
    
    ConnectionManager:Add("esp_playerRemoving", Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end))
end

local function DisableESP()
    ConnectionManager:Remove("esp_playerAdded")
    ConnectionManager:Remove("esp_playerRemoving")
    for player, _ in pairs(ESPCache) do
        RemoveESP(player)
    end
    ESPCache = {}
end

local function UpdateESPColors()
    for player, data in pairs(ESPCache) do
        if data.Highlight and data.Highlight.Parent then
            data.Highlight.OutlineColor = Config.ESP.OutlineColor
            data.Highlight.FillColor = Config.ESP.FillColor
            data.Highlight.OutlineTransparency = Config.ESP.OutlineTransparency
            data.Highlight.FillTransparency = Config.ESP.FillTransparency
        end
    end
end

-- ESP Distance filter (heartbeat-based, debounced)
local espDistanceConn = nil

local function StartESPDistanceFilter()
    if espDistanceConn then espDistanceConn:Disconnect() end
    
    local lastCheck = 0
    espDistanceConn = RunService.Heartbeat:Connect(function()
        if not Config.ESP.Enabled then return end
        local now = tick()
        if now - lastCheck < 0.5 then return end
        lastCheck = now
        
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        
        local maxDist = Config.ESP.Distance
        
        for player, data in pairs(ESPCache) do
            if data.Highlight and data.Highlight.Parent then
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if maxDist > 0 and dist > maxDist then
                            data.Highlight.Enabled = false
                        else
                            data.Highlight.Enabled = true
                        end
                    end
                end
            end
        end
    end)
    ConnectionManager:Add("esp_distance", espDistanceConn)
end

local function BuildESPPage()
    local page = Utility.Create("ScrollingFrame", {
        Name = "ESP",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = ContentArea,
    })
    Utility.AddPadding(page, 16, 20, 16, 16)
    Utility.AddListLayout(page, 8)
    
    ContentPages["ESP"] = page
    
    -- Title
    AddHeading(page, "ESP", 0, 18, Theme.Text, Theme.FontBold)
    AddParagraph(page, "Highlight players through walls with customizable outline and fill.", 1, 12, Theme.TextMuted)
    
    -- Enable toggle
    CreateToggle(page, "Enable ESP", Config.ESP.Enabled, function(state)
        Config.ESP.Enabled = state
        if state then
            EnableESP()
            StartESPDistanceFilter()
            Notify("ESP enabled")
        else
            DisableESP()
            Notify("ESP disabled")
        end
    end, 2)
    
    -- Distance dropdown
    CreateSectionHeader(page, "DISTANCE", 3)
    
    local distOptions = {"100", "500", "1,000", "5,000", "10,000", "25,000", "50,000", "100,000", "UNLIMITED"}
    local distValues = {100, 500, 1000, 5000, 10000, 25000, 50000, 100000, 0}
    
    local defaultDistIdx = 3
    for i, v in ipairs(distValues) do
        if v == Config.ESP.Distance then defaultDistIdx = i break end
    end
    
    CreateDropdown(page, "Distance", distOptions, defaultDistIdx, function(idx)
        Config.ESP.Distance = distValues[idx]
        Notify("ESP distance: " .. distOptions[idx])
    end, 4)
    
    -- Transparency
    CreateSectionHeader(page, "APPEARANCE", 5)
    
    CreateSlider(page, "Outline Transparency", 0, 100, math.floor(Config.ESP.OutlineTransparency * 100), function(val)
        Config.ESP.OutlineTransparency = val / 100
        UpdateESPColors()
    end, 6, function(v) return v .. "%" end)
    
    CreateSlider(page, "Fill Transparency", 0, 100, math.floor(Config.ESP.FillTransparency * 100), function(val)
        Config.ESP.FillTransparency = val / 100
        UpdateESPColors()
    end, 7, function(v) return v .. "%" end)
    
    -- Colors
    CreateSectionHeader(page, "COLORS", 8)
    
    CreateColorPicker(page, "Outline Color", Config.ESP.OutlineColor, function(color)
        Config.ESP.OutlineColor = color
        UpdateESPColors()
    end, 9)
    
    CreateColorPicker(page, "Fill Color", Config.ESP.FillColor, function(color)
        Config.ESP.FillColor = color
        UpdateESPColors()
    end, 10)
end

-- ============================================
-- CROSSHAIR SYSTEM
-- ============================================

-- 70 Unique Crosshair Definitions
local CrosshairDefinitions = {
    {Name = "Classic Cross", Draw = function(f, s, t, g, c) 
        -- Four lines from center
        local half = s
        -- Top
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, half-g), Position = UDim2.new(0.5, -t/2, 0.5, -half), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        -- Bottom
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, half-g), Position = UDim2.new(0.5, -t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        -- Left
        Utility.Create("Frame", {Size = UDim2.new(0, half-g, 0, t), Position = UDim2.new(0.5, -half, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        -- Right
        Utility.Create("Frame", {Size = UDim2.new(0, half-g, 0, t), Position = UDim2.new(0.5, g, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
    end},
    {Name = "Dot", Draw = function(f, s, t, g, c)
        local d = math.max(t+2, 4)
        local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.AddCorner(dot, UDim.new(1,0))
    end},
    {Name = "Circle", Draw = function(f, s, t, g, c)
        local circle = Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, s*2), Position = UDim2.new(0.5, -s, 0.5, -s), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
        Utility.AddCorner(circle, UDim.new(1,0))
        Utility.AddStroke(circle, c, t, 0)
    end},
    {Name = "Plus", Draw = function(f, s, t, g, c)
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, s*2), Position = UDim2.new(0.5, -t/2, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, t), Position = UDim2.new(0.5, -s, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
    end},
    {Name = "X Mark", Draw = function(f, s, t, g, c)
        local line1 = Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, t), Position = UDim2.new(0.5, -s, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = 45, Parent = f})
        local line2 = Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, t), Position = UDim2.new(0.5, -s, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = -45, Parent = f})
    end},
    {Name = "Diamond", Draw = function(f, s, t, g, c)
        local d = Utility.Create("Frame", {Size = UDim2.new(0, s, 0, s), Position = UDim2.new(0.5, -s/2, 0.5, -s/2), BackgroundTransparency = 1, BorderSizePixel = 0, Rotation = 45, Parent = f})
        Utility.AddStroke(d, c, t, 0)
    end},
    {Name = "Square", Draw = function(f, s, t, g, c)
        local sq = Utility.Create("Frame", {Size = UDim2.new(0, s, 0, s), Position = UDim2.new(0.5, -s/2, 0.5, -s/2), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
        Utility.AddStroke(sq, c, t, 0)
    end},
    {Name = "Bracket Left-Right", Draw = function(f, s, t, g, c)
        -- Left bracket [
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, s), Position = UDim2.new(0.5, -s, 0.5, -s/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, g, 0, t), Position = UDim2.new(0.5, -s, 0.5, -s/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, g, 0, t), Position = UDim2.new(0.5, -s, 0.5, s/2-t), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        -- Right bracket ]
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, s), Position = UDim2.new(0.5, s-t, 0.5, -s/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, g, 0, t), Position = UDim2.new(0.5, s-g, 0.5, -s/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, g, 0, t), Position = UDim2.new(0.5, s-g, 0.5, s/2-t), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
    end},
    {Name = "Tactical Cross", Draw = function(f, s, t, g, c)
        local half = s
        -- Only outer halves
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, half/2), Position = UDim2.new(0.5, -t/2, 0.5, -half), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, t, 0, half/2), Position = UDim2.new(0.5, -t/2, 0.5, half/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, half/2, 0, t), Position = UDim2.new(0.5, -half, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, half/2, 0, t), Position = UDim2.new(0.5, half/2, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
    end},
    {Name = "Precision Dot", Draw = function(f, s, t, g, c)
        local d = 3
        local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.AddCorner(dot, UDim.new(1,0))
        -- Thin long lines
        local len = s * 1.5
        Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, len-g*2), Position = UDim2.new(0.5, 0, 0.5, -len), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, len-g*2), Position = UDim2.new(0.5, 0, 0.5, g*2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, len-g*2, 0, 1), Position = UDim2.new(0.5, -len, 0.5, 0), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        Utility.Create("Frame", {Size = UDim2.new(0, len-g*2, 0, 1), Position = UDim2.new(0.5, g*2, 0.5, 0), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
    end},
}

-- Generate remaining 60 crosshairs procedurally with meaningful variations
local extraCrosshairs = {
    "Minimal Dot",          -- 11
    "Circle Dot",           -- 12
    "Cross Dot",            -- 13
    "Hollow Circle",        -- 14
    "Thick Cross",          -- 15
    "Thin Cross",           -- 16
    "Wide Cross",           -- 17
    "Compact Cross",        -- 18
    "Four Dots",            -- 19
    "Four Lines",           -- 20
    "Split Cross",          -- 21
    "Center Ring",          -- 22
    "Double Circle",        -- 23
    "Square Dot",           -- 24
    "Diamond Dot",          -- 25
    "T Cross",              -- 26
    "Inverted T",           -- 27
    "L Brackets",           -- 28
    "Corner Brackets",      -- 29
    "Arrow Up",             -- 30
    "Arrow Cross",          -- 31
    "Chevron",              -- 32
    "Double Chevron",       -- 33
    "Tri Dot",              -- 34
    "Penta Dot",            -- 35
    "Hex Ring",             -- 36
    "Star Cross",           -- 37
    "Razor",                -- 38
    "Needle",               -- 39
    "Wedge",                -- 40
    "Gap Cross",            -- 41
    "Fat Plus",             -- 42
    "Slim Plus",            -- 43
    "Dash Cross",           -- 44
    "Dotted Cross",         -- 45
    "Ring Cross",           -- 46
    "Circle Cross",         -- 47
    "Box Cross",            -- 48
    "Diamond Cross",        -- 49
    "Dual Ring",            -- 50
    "Outer Ticks",          -- 51
    "Inner Ticks",          -- 52
    "Fence",                -- 53
    "Grid",                 -- 54
    "Triple Line",          -- 55
    "Parallel",             -- 56
    "Converge",             -- 57
    "Diverge",              -- 58
    "Pinpoint",             -- 59
    "Bullseye",             -- 60
    "Target Ring",          -- 61
    "Scope",                -- 62
    "Mil Dot",              -- 63
    "Reticle",              -- 64
    "Hybrid A",             -- 65
    "Hybrid B",             -- 66
    "Hybrid C",             -- 67
    "Minimal Arc",          -- 68
    "Clean Point",          -- 69
    "Precision Hybrid",     -- 70
}

-- Build drawing functions for all 70
local function generateExtraDraw(idx)
    return function(f, s, t, g, c)
        -- Each generates a meaningfully different pattern
        local half = s
        local th = t
        
        if idx == 11 then -- Minimal Dot
            local d = 2
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -1, 0.5, -1), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 12 then -- Circle Dot
            local circle = Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, s*2), Position = UDim2.new(0.5, -s, 0.5, -s), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(circle, UDim.new(1,0))
            Utility.AddStroke(circle, c, th, 0)
            local d = 3
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 13 then -- Cross Dot
            CrosshairDefinitions[1].Draw(f, s, t, g, c) -- cross
            local d = 3
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 14 then -- Hollow Circle
            local r = s * 1.5
            local circle = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(circle, UDim.new(1,0))
            Utility.AddStroke(circle, c, 1, 0)
        elseif idx == 15 then -- Thick Cross
            CrosshairDefinitions[1].Draw(f, s, math.max(t+2, 4), g, c)
        elseif idx == 16 then -- Thin Cross
            CrosshairDefinitions[1].Draw(f, s, 1, g, c)
        elseif idx == 17 then -- Wide Cross
            CrosshairDefinitions[1].Draw(f, math.floor(s*1.8), t, g, c)
        elseif idx == 18 then -- Compact Cross
            CrosshairDefinitions[1].Draw(f, math.max(math.floor(s*0.6), 3), t, math.max(math.floor(g*0.5), 1), c)
        elseif idx == 19 then -- Four Dots
            local d = math.max(t, 3)
            local dist = s
            for _, pos in ipairs({{0,-dist},{0,dist},{-dist,0},{dist,0}}) do
                local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, pos[1]-d/2, 0.5, pos[2]-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(dot, UDim.new(1,0))
            end
        elseif idx == 20 then -- Four Lines
            local len = math.floor(s*0.6)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, len), Position = UDim2.new(0.5, -t/2, 0.5, -(g+len)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, len), Position = UDim2.new(0.5, -t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -(g+len), 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, g, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 21 then -- Split Cross (big gap)
            CrosshairDefinitions[1].Draw(f, s, t, math.floor(g*2.5), c)
        elseif idx == 22 then -- Center Ring
            local r = math.floor(s*0.4)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, t, 0)
        elseif idx == 23 then -- Double Circle
            for _, radius in ipairs({s*0.4, s*0.8}) do
                local r = math.floor(radius)
                local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(ring, UDim.new(1,0))
                Utility.AddStroke(ring, c, 1, 0)
            end
        elseif idx == 24 then -- Square Dot
            local d = math.max(t+1, 4)
            Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 25 then -- Diamond Dot
            local d = math.max(t+2, 5)
            local dia = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = 45, Parent = f})
        elseif idx == 26 then -- T Cross (no top)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, half-g), Position = UDim2.new(0.5, -t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, half-g, 0, t), Position = UDim2.new(0.5, -half, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, half-g, 0, t), Position = UDim2.new(0.5, g, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 27 then -- Inverted T (no bottom)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, half-g), Position = UDim2.new(0.5, -t/2, 0.5, -half), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, half-g, 0, t), Position = UDim2.new(0.5, -half, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, half-g, 0, t), Position = UDim2.new(0.5, g, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 28 then -- L Brackets (top-left, bottom-right)
            local bLen = math.floor(s*0.5)
            -- TL
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, bLen), Position = UDim2.new(0.5, -s, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, bLen, 0, t), Position = UDim2.new(0.5, -s, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            -- BR
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, bLen), Position = UDim2.new(0.5, s-t, 0.5, s-bLen), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, bLen, 0, t), Position = UDim2.new(0.5, s-bLen, 0.5, s-t), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 29 then -- Corner Brackets (all 4 corners)
            local bLen = math.floor(s*0.4)
            local off = s
            for _, corner in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}}) do
                local cx = corner[1] > 0 and off-t or -off
                local cy = corner[2] > 0 and off-t or -off
                Utility.Create("Frame", {Size = UDim2.new(0, t, 0, bLen), Position = UDim2.new(0.5, cx, 0.5, corner[2]>0 and off-bLen or -off), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                Utility.Create("Frame", {Size = UDim2.new(0, bLen, 0, t), Position = UDim2.new(0.5, corner[1]>0 and off-bLen or -off, 0.5, cy), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            end
        elseif idx == 30 then -- Arrow Up (triangle-ish)
            local len = math.floor(s*0.7)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, len), Position = UDim2.new(0.5, -t/2, 0.5, -(g+len)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, len/2, 0, t), Position = UDim2.new(0.5, -t/2-len/2, 0.5, -g-t), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, len/2, 0, t), Position = UDim2.new(0.5, t/2, 0.5, -g-t), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 31 then -- Arrow Cross
            local len = math.floor(s*0.5)
            -- Cross
            CrosshairDefinitions[1].Draw(f, s, 1, g, c)
            -- Arrow tips
            Utility.Create("Frame", {Size = UDim2.new(0, len/2, 0, 1), Position = UDim2.new(0.5, -len/4, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = 0, Parent = f})
        elseif idx == 32 then -- Chevron (V shape at bottom)
            local len = math.floor(s*0.8)
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -len+t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = 30, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = -30, Parent = f})
        elseif idx == 33 then -- Double Chevron
            for yOff = 0, 1 do
                local yP = g + yOff * math.floor(s*0.4)
                local len = math.floor(s*0.6)
                Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -len+t/2, 0.5, yP), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = 25, Parent = f})
                Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -t/2, 0.5, yP), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = -25, Parent = f})
            end
        elseif idx == 34 then -- Tri Dot (3 dots triangle)
            local d = math.max(t, 3)
            local dist = math.floor(s*0.7)
            for _, pos in ipairs({{0,-dist},{-dist*0.866, dist*0.5},{dist*0.866, dist*0.5}}) do
                local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, math.floor(pos[1])-d/2, 0.5, math.floor(pos[2])-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(dot, UDim.new(1,0))
            end
        elseif idx == 35 then -- Penta Dot
            local d = math.max(t, 3)
            local dist = math.floor(s*0.7)
            for i = 0, 4 do
                local angle = (i / 5) * math.pi * 2 - math.pi/2
                local px = math.cos(angle) * dist
                local py = math.sin(angle) * dist
                local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, math.floor(px)-d/2, 0.5, math.floor(py)-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(dot, UDim.new(1,0))
            end
        elseif idx == 36 then -- Hex Ring (6 dots in circle)
            local d = math.max(t, 2)
            local dist = s
            for i = 0, 5 do
                local angle = (i / 6) * math.pi * 2
                local px = math.cos(angle) * dist
                local py = math.sin(angle) * dist
                local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, math.floor(px)-d/2, 0.5, math.floor(py)-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(dot, UDim.new(1,0))
            end
        elseif idx == 37 then -- Star Cross (8 lines)
            for i = 0, 7 do
                local angle = (i / 8) * math.pi * 2
                local len = math.floor(s * 0.8)
                local line = Utility.Create("Frame", {
                    Size = UDim2.new(0, t, 0, len),
                    Position = UDim2.new(0.5, -t/2, 0.5, -len),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = c, BorderSizePixel = 0,
                    Rotation = math.deg(angle),
                    Parent = f
                })
            end
        elseif idx == 38 then -- Razor (thin vertical + horizontal dash)
            Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, s*2), Position = UDim2.new(0.5, 0, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, s*0.6, 0, 1), Position = UDim2.new(0.5, -s*0.3, 0.5, 0), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 39 then -- Needle (single thin vertical)
            Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, s*2.5), Position = UDim2.new(0.5, 0, 0.5, -s*1.25), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 40 then -- Wedge (small V)
            local len = math.floor(s*0.5)
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -len/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = 20, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -len/2+len/3, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Rotation = -20, Parent = f})
        elseif idx == 41 then -- Gap Cross (extra large gap)
            CrosshairDefinitions[1].Draw(f, math.floor(s*1.5), t, math.floor(g*3), c)
        elseif idx == 42 then -- Fat Plus
            local th2 = math.max(t*3, 6)
            Utility.Create("Frame", {Size = UDim2.new(0, th2, 0, s*2), Position = UDim2.new(0.5, -th2/2, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, th2), Position = UDim2.new(0.5, -s, 0.5, -th2/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 43 then -- Slim Plus
            Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, s*2), Position = UDim2.new(0.5, 0, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, s*2, 0, 1), Position = UDim2.new(0.5, -s, 0.5, 0), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 44 then -- Dash Cross (dashed lines)
            local segLen = math.floor(s*0.3)
            for i = 0, 2 do
                local off = g + i * (segLen + 2)
                -- Up
                Utility.Create("Frame", {Size = UDim2.new(0, t, 0, segLen), Position = UDim2.new(0.5, -t/2, 0.5, -(off+segLen)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                -- Down
                Utility.Create("Frame", {Size = UDim2.new(0, t, 0, segLen), Position = UDim2.new(0.5, -t/2, 0.5, off), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                -- Left
                Utility.Create("Frame", {Size = UDim2.new(0, segLen, 0, t), Position = UDim2.new(0.5, -(off+segLen), 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                -- Right
                Utility.Create("Frame", {Size = UDim2.new(0, segLen, 0, t), Position = UDim2.new(0.5, off, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            end
        elseif idx == 45 then -- Dotted Cross (dots along axes)
            local d = math.max(t, 2)
            for i = 1, 4 do
                local off = g + i * math.floor(s*0.3)
                for _, dir in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
                    local px = dir[1]*off
                    local py = dir[2]*off
                    local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, math.floor(px)-d/2, 0.5, math.floor(py)-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                    Utility.AddCorner(dot, UDim.new(1,0))
                end
            end
        elseif idx == 46 then -- Ring Cross
            local r = math.floor(s*0.6)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, 1, 0)
            CrosshairDefinitions[1].Draw(f, s, 1, g, c)
        elseif idx == 47 then -- Circle Cross
            local r = s
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, t, 0)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, r*2+s), Position = UDim2.new(0.5, -t/2, 0.5, -r-s/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, r*2+s, 0, t), Position = UDim2.new(0.5, -r-s/2, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 48 then -- Box Cross
            local sq = Utility.Create("Frame", {Size = UDim2.new(0, s*1.2, 0, s*1.2), Position = UDim2.new(0.5, -s*0.6, 0.5, -s*0.6), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddStroke(sq, c, t, 0)
            CrosshairDefinitions[1].Draw(f, s, 1, g, c)
        elseif idx == 49 then -- Diamond Cross
            local d = Utility.Create("Frame", {Size = UDim2.new(0, s, 0, s), Position = UDim2.new(0.5, -s/2, 0.5, -s/2), BackgroundTransparency = 1, BorderSizePixel = 0, Rotation = 45, Parent = f})
            Utility.AddStroke(d, c, 1, 0)
            CrosshairDefinitions[1].Draw(f, math.floor(s*1.2), 1, g, c)
        elseif idx == 50 then -- Dual Ring
            for _, radius in ipairs({math.floor(s*0.5), s}) do
                local ring = Utility.Create("Frame", {Size = UDim2.new(0, radius*2, 0, radius*2), Position = UDim2.new(0.5, -radius, 0.5, -radius), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(ring, UDim.new(1,0))
                Utility.AddStroke(ring, c, 1, 0)
            end
            local d = 2
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -1, 0.5, -1), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 51 then -- Outer Ticks
            local tickLen = math.floor(s*0.3)
            local dist = math.floor(s*1.2)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, tickLen), Position = UDim2.new(0.5, -t/2, 0.5, -(dist+tickLen)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, tickLen), Position = UDim2.new(0.5, -t/2, 0.5, dist), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, tickLen, 0, t), Position = UDim2.new(0.5, -(dist+tickLen), 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, tickLen, 0, t), Position = UDim2.new(0.5, dist, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 52 then -- Inner Ticks
            local tickLen = math.floor(s*0.2)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, tickLen), Position = UDim2.new(0.5, -t/2, 0.5, -g-tickLen), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, tickLen), Position = UDim2.new(0.5, -t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, tickLen, 0, t), Position = UDim2.new(0.5, -g-tickLen, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, tickLen, 0, t), Position = UDim2.new(0.5, g, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 53 then -- Fence (parallel vertical lines)
            for i = -2, 2 do
                if i ~= 0 then
                    Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, s), Position = UDim2.new(0.5, i*math.floor(s*0.3), 0.5, -s/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                end
            end
        elseif idx == 54 then -- Grid (small grid pattern)
            local gridS = math.floor(s*0.3)
            for x = -1, 1 do
                for y = -1, 1 do
                    if not (x == 0 and y == 0) then
                        local sq = Utility.Create("Frame", {Size = UDim2.new(0, gridS, 0, gridS), Position = UDim2.new(0.5, x*gridS*1.2-gridS/2, 0.5, y*gridS*1.2-gridS/2), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
                        Utility.AddStroke(sq, c, 1, 0.3)
                    end
                end
            end
        elseif idx == 55 then -- Triple Line (3 horizontal)
            for i = -1, 1 do
                Utility.Create("Frame", {Size = UDim2.new(0, s*1.5, 0, t), Position = UDim2.new(0.5, -s*0.75, 0.5, i*math.floor(s*0.3)-t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            end
        elseif idx == 56 then -- Parallel (two vertical lines)
            local off = math.floor(s*0.25)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, s*1.5), Position = UDim2.new(0.5, -off-t/2, 0.5, -s*0.75), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, s*1.5), Position = UDim2.new(0.5, off-t/2, 0.5, -s*0.75), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 57 then -- Converge (lines pointing inward)
            local len = math.floor(s*0.6)
            -- Top pointing down
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, len), Position = UDim2.new(0.5, -t/2, 0.5, -(g+len)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            -- Bottom pointing up
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, len), Position = UDim2.new(0.5, -t/2, 0.5, g), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            -- Left pointing right (angled)
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, -(g+len), 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            -- Right pointing left
            Utility.Create("Frame", {Size = UDim2.new(0, len, 0, t), Position = UDim2.new(0.5, g, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            -- Center dot
            local d = 2
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -1, 0.5, -1), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 58 then -- Diverge (lines pointing outward from large gap)
            CrosshairDefinitions[1].Draw(f, math.floor(s*1.8), t, math.floor(s*0.8), c)
        elseif idx == 59 then -- Pinpoint (tiny dot + outer ring)
            local d = 2
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -1, 0.5, -1), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
            local r = math.floor(s*1.2)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, 1, 0.3)
        elseif idx == 60 then -- Bullseye
            for _, radius in ipairs({math.floor(s*0.3), math.floor(s*0.7), s}) do
                local ring = Utility.Create("Frame", {Size = UDim2.new(0, radius*2, 0, radius*2), Position = UDim2.new(0.5, -radius, 0.5, -radius), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(ring, UDim.new(1,0))
                Utility.AddStroke(ring, c, 1, 0)
            end
            local d = 3
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 61 then -- Target Ring
            local r = s
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, t, 0)
            -- Ticks at NESW
            local tickLen = math.floor(s*0.4)
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, tickLen), Position = UDim2.new(0.5, -t/2, 0.5, -(r+tickLen)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, tickLen), Position = UDim2.new(0.5, -t/2, 0.5, r), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, tickLen, 0, t), Position = UDim2.new(0.5, -(r+tickLen), 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, tickLen, 0, t), Position = UDim2.new(0.5, r, 0.5, -t/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 62 then -- Scope (circle + cross extending beyond)
            local r = s
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, 1, 0)
            local ext = math.floor(s*0.6)
            Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, ext), Position = UDim2.new(0.5, 0, 0.5, -(r+ext)), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, 1, 0, ext), Position = UDim2.new(0.5, 0, 0.5, r), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, ext, 0, 1), Position = UDim2.new(0.5, -(r+ext), 0.5, 0), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, ext, 0, 1), Position = UDim2.new(0.5, r, 0.5, 0), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 63 then -- Mil Dot (center dot + dots on axes)
            local d = 3
            -- Center
            local cd = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(cd, UDim.new(1,0))
            -- Axis dots
            for i = 1, 3 do
                local off = i * math.floor(s*0.4)
                for _, dir in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
                    local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, dir[1]*off-d/2, 0.5, dir[2]*off-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                    Utility.AddCorner(dot, UDim.new(1,0))
                end
            end
        elseif idx == 64 then -- Reticle (cross + circle + dot)
            local r = math.floor(s*0.6)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, 1, 0)
            CrosshairDefinitions[1].Draw(f, s, 1, r, c)
            local d = 2
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -1, 0.5, -1), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 65 then -- Hybrid A (square + cross)
            local sqS = math.floor(s*0.8)
            local sq = Utility.Create("Frame", {Size = UDim2.new(0, sqS, 0, sqS), Position = UDim2.new(0.5, -sqS/2, 0.5, -sqS/2), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddStroke(sq, c, 1, 0)
            CrosshairDefinitions[1].Draw(f, s, 1, math.floor(sqS/2)+2, c)
        elseif idx == 66 then -- Hybrid B (diamond + dot)
            local dS = math.floor(s*0.8)
            local dia = Utility.Create("Frame", {Size = UDim2.new(0, dS, 0, dS), Position = UDim2.new(0.5, -dS/2, 0.5, -dS/2), BackgroundTransparency = 1, BorderSizePixel = 0, Rotation = 45, Parent = f})
            Utility.AddStroke(dia, c, 1, 0)
            local d = 3
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        elseif idx == 67 then -- Hybrid C (circle + four dots)
            local r = math.floor(s*0.7)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, 1, 0)
            local d = 3
            for _, pos in ipairs({{0,-r-g},{0,r+g},{-r-g,0},{r+g,0}}) do
                local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, pos[1]-d/2, 0.5, pos[2]-d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
                Utility.AddCorner(dot, UDim.new(1,0))
            end
        elseif idx == 68 then -- Minimal Arc (two small arcs represented as short bracket corners)
            local bLen = math.floor(s*0.5)
            -- Top-left
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, bLen), Position = UDim2.new(0.5, -s, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, bLen, 0, t), Position = UDim2.new(0.5, -s, 0.5, -s), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            -- Bottom-right
            Utility.Create("Frame", {Size = UDim2.new(0, t, 0, bLen), Position = UDim2.new(0.5, s-t, 0.5, s-bLen), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.Create("Frame", {Size = UDim2.new(0, bLen, 0, t), Position = UDim2.new(0.5, s-bLen, 0.5, s-t), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
        elseif idx == 69 then -- Clean Point
            local d = 4
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
            -- Subtle outer thin ring
            local r = math.floor(s*1.5)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, 1, 0.5)
        elseif idx == 70 then -- Precision Hybrid
            -- Circle + cross + dot
            local r = math.floor(s*0.8)
            local ring = Utility.Create("Frame", {Size = UDim2.new(0, r*2, 0, r*2), Position = UDim2.new(0.5, -r, 0.5, -r), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(ring, UDim.new(1,0))
            Utility.AddStroke(ring, c, t, 0)
            CrosshairDefinitions[1].Draw(f, math.floor(s*1.5), 1, r+2, c)
            local d = 3
            local dot = Utility.Create("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0.5, -d/2, 0.5, -d/2), BackgroundColor3 = c, BorderSizePixel = 0, Parent = f})
            Utility.AddCorner(dot, UDim.new(1,0))
        end
    end
end

-- Add extra definitions
for i, name in ipairs(extraCrosshairs) do
    local globalIdx = i + 10
    table.insert(CrosshairDefinitions, {
        Name = name,
        Draw = generateExtraDraw(globalIdx),
    })
end

-- Crosshair Rendering
local CrosshairFrame = nil

local function ClearCrosshair()
    if CrosshairFrame then
        for _, child in ipairs(CrosshairFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
end

local function RenderCrosshair()
    if not CrosshairFrame then
        CrosshairFrame = Utility.Create("Frame", {
            Name = "CrosshairOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 100,
            Parent = ScreenGui,
        })
    end
    
    ClearCrosshair()
    
    if not Config.Crosshair.Enabled then return end
    
    local def = CrosshairDefinitions[Config.Crosshair.Type]
    if not def then return end
    
    CrosshairFrame.Visible = true
    
    -- Set transparency
    local function setChildTransparency(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Frame") and child.BackgroundTransparency < 1 then
                child.BackgroundTransparency = 1 - Config.Crosshair.Opacity
            end
            if child:IsA("UIStroke") then
                child.Transparency = 1 - Config.Crosshair.Opacity
            end
        end
    end
    
    def.Draw(
        CrosshairFrame,
        Config.Crosshair.Size,
        Config.Crosshair.Thickness,
        Config.Crosshair.Gap,
        Config.Crosshair.Color
    )
    
    -- Add center dot if enabled
    if Config.Crosshair.CenterDot then
        local d = Config.Crosshair.CenterDotSize
        local dot = Utility.Create("Frame", {
            Size = UDim2.new(0, d, 0, d),
            Position = UDim2.new(0.5, -d/2, 0.5, -d/2),
            BackgroundColor3 = Config.Crosshair.Color,
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = CrosshairFrame,
        })
        Utility.AddCorner(dot, UDim.new(1, 0))
    end
    
    -- Apply opacity
    for _, child in ipairs(CrosshairFrame:GetChildren()) do
        if child:IsA("Frame") then
            if child.BackgroundTransparency < 0.5 then
                child.BackgroundTransparency = 1 - Config.Crosshair.Opacity
            end
        end
    end
end

-- ============================================
-- CROSSHAIR PAGE
-- ============================================
local function BuildCrosshairPage()
    local page = Utility.Create("ScrollingFrame", {
        Name = "CROSSHAIR",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = ContentArea,
    })
    Utility.AddPadding(page, 16, 20, 16, 16)
    Utility.AddListLayout(page, 8)
    
    ContentPages["CROSSHAIR"] = page
    
    AddHeading(page, "CROSSHAIR", 0, 18, Theme.Text, Theme.FontBold)
    AddParagraph(page, "Choose from 70 unique crosshair styles with full customization.", 1, 12, Theme.TextMuted)
    
    -- Enable toggle
    CreateToggle(page, "Enable Crosshair", Config.Crosshair.Enabled, function(state)
        Config.Crosshair.Enabled = state
        RenderCrosshair()
        if state then
            Notify("Crosshair enabled")
        else
            Notify("Crosshair disabled")
            if CrosshairFrame then CrosshairFrame.Visible = false end
        end
    end, 2)
    
    -- Type dropdown with search
    CreateSectionHeader(page, "TYPE", 3)
    
    -- Search box
    local searchContainer = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        LayoutOrder = 4,
        Parent = page,
    })
    Utility.AddCorner(searchContainer, Theme.CornerRadiusSmall)
    Utility.AddStroke(searchContainer, Theme.Border, 1, 0.75)
    
    local searchBox = Utility.Create("TextBox", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search crosshair...",
        PlaceholderColor3 = Theme.TextMuted,
        TextColor3 = Theme.Text,
        Font = Theme.FontLight,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchContainer,
    })
    
    -- Crosshair list
    local crosshairListContainer = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = 5,
        Parent = page,
    })
    Utility.AddCorner(crosshairListContainer, Theme.CornerRadiusSmall)
    Utility.AddStroke(crosshairListContainer, Theme.Border, 1, 0.75)
    
    local crosshairScroll = Utility.Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, #CrosshairDefinitions * 30),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = crosshairListContainer,
    })
    Utility.AddPadding(crosshairScroll, 4, 4, 4, 4)
    Utility.AddListLayout(crosshairScroll, 2)
    
    local crosshairButtons = {}
    
    for i, def in ipairs(CrosshairDefinitions) do
        local num = string.format("%02d", i)
        local btn = Utility.Create("TextButton", {
            Name = "CH_" .. i,
            Size = UDim2.new(1, -4, 0, 28),
            BackgroundColor3 = i == Config.Crosshair.Type and Theme.Accent or Theme.Card,
            BackgroundTransparency = i == Config.Crosshair.Type and 0.7 or 0.5,
            Text = num .. "   " .. def.Name,
            TextColor3 = i == Config.Crosshair.Type and Theme.Text or Theme.TextSecondary,
            Font = Theme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            LayoutOrder = i,
            Parent = crosshairScroll,
        })
        Utility.AddCorner(btn, UDim.new(0, 4))
        Utility.AddPadding(btn, 0, 0, 10, 0)
        
        crosshairButtons[i] = btn
        
        btn.MouseButton1Click:Connect(function()
            Config.Crosshair.Type = i
            RenderCrosshair()
            Notify("Crosshair: " .. def.Name)
            
            for j, b in pairs(crosshairButtons) do
                if j == i then
                    Utility.Tween(b, {BackgroundTransparency = 0.7, BackgroundColor3 = Theme.Accent}, Theme.TweenSpeedFast)
                    b.TextColor3 = Theme.Text
                else
                    Utility.Tween(b, {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Card}, Theme.TweenSpeedFast)
                    b.TextColor3 = Theme.TextSecondary
                end
            end
        end)
    end
    
    -- Search functionality
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for i, def in ipairs(CrosshairDefinitions) do
            local btn = crosshairButtons[i]
            if btn then
                if query == "" or def.Name:lower():find(query, 1, true) then
                    btn.Visible = true
                else
                    btn.Visible = false
                end
            end
        end
    end)
    
    -- Settings
    CreateSectionHeader(page, "SETTINGS", 6)
    
    CreateSlider(page, "Size", 4, 40, Config.Crosshair.Size, function(val)
        Config.Crosshair.Size = val
        RenderCrosshair()
    end, 7)
    
    CreateSlider(page, "Thickness", 1, 8, Config.Crosshair.Thickness, function(val)
        Config.Crosshair.Thickness = val
        RenderCrosshair()
    end, 8)
    
    CreateSlider(page, "Gap", 0, 20, Config.Crosshair.Gap, function(val)
        Config.Crosshair.Gap = val
        RenderCrosshair()
    end, 9)
    
    CreateSlider(page, "Opacity", 0, 100, math.floor(Config.Crosshair.Opacity * 100), function(val)
        Config.Crosshair.Opacity = val / 100
        RenderCrosshair()
    end, 10, function(v) return v .. "%" end)
    
    CreateToggle(page, "Center Dot", Config.Crosshair.CenterDot, function(state)
        Config.Crosshair.CenterDot = state
        RenderCrosshair()
    end, 11)
    
    CreateSlider(page, "Center Dot Size", 1, 8, Config.Crosshair.CenterDotSize, function(val)
        Config.Crosshair.CenterDotSize = val
        RenderCrosshair()
    end, 12)
    
    CreateSectionHeader(page, "COLOR", 13)
    
    CreateColorPicker(page, "Crosshair Color", Config.Crosshair.Color, function(color)
        Config.Crosshair.Color = color
        RenderCrosshair()
    end, 14)
end

-- ============================================
-- VISUALS PAGE
-- ============================================
local function BuildVisualsPage()
    local page = Utility.Create("ScrollingFrame", {
        Name = "VISUALS",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = ContentArea,
    })
    Utility.AddPadding(page, 16, 20, 16, 16)
    Utility.AddListLayout(page, 8)
    
    ContentPages["VISUALS"] = page
    
    AddHeading(page, "VISUALS", 0, 18, Theme.Text, Theme.FontBold)
    AddParagraph(page, "Visual environment modifications.", 1, 12, Theme.TextMuted)
    
    -- No Fog
    CreateSectionHeader(page, "ENVIRONMENT", 2)
    
    CreateToggle(page, "No Fog", Config.Visuals.NoFog, function(state)
        Config.Visuals.NoFog = state
        if state then
            SavedLighting.FogEnd = Lighting.FogEnd
            SavedLighting.FogStart = Lighting.FogStart
            Lighting.FogEnd = 9999999
            Lighting.FogStart = 9999999
            Notify("No Fog enabled")
        else
            Lighting.FogEnd = SavedLighting.FogEnd
            Lighting.FogStart = SavedLighting.FogStart
            Notify("No Fog disabled")
        end
    end, 3)
    
    -- Full Bright
    CreateToggle(page, "Full Bright", Config.Visuals.FullBright, function(state)
        Config.Visuals.FullBright = state
        if state then
            SavedLighting.Brightness = Lighting.Brightness
            SavedLighting.Ambient = Lighting.Ambient
            SavedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
            SavedLighting.GlobalShadows = Lighting.GlobalShadows
            
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.GlobalShadows = false
            
            -- Remove atmosphere/color correction effects temporarily
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Atmosphere") then
                    child:SetAttribute("XYAN_Disabled", true)
                    child.Density = 0
                end
            end
            
            Notify("Full Bright enabled")
        else
            Lighting.Brightness = SavedLighting.Brightness
            Lighting.Ambient = SavedLighting.Ambient
            Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient
            Lighting.GlobalShadows = SavedLighting.GlobalShadows
            
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Atmosphere") and child:GetAttribute("XYAN_Disabled") then
                    child:SetAttribute("XYAN_Disabled", nil)
                    -- We can't restore original density, set reasonable default
                    child.Density = 0.3
                end
            end
            
            Notify("Full Bright disabled")
        end
    end, 4)
end

-- ============================================
-- SETTINGS PAGE
-- ============================================
local function BuildSettingsPage()
    local page = Utility.Create("ScrollingFrame", {
        Name = "SETTINGS",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = ContentArea,
    })
    Utility.AddPadding(page, 16, 20, 16, 16)
    Utility.AddListLayout(page, 8)
    
    ContentPages["SETTINGS"] = page
    
    AddHeading(page, "SETTINGS", 0, 18, Theme.Text, Theme.FontBold)
    AddParagraph(page, "Interface configuration and system controls.", 1, 12, Theme.TextMuted)
    
    CreateSectionHeader(page, "INTERFACE", 2)
    
    -- UI Scale
    CreateSlider(page, "UI Scale", 50, 150, math.floor(Config.UI.Scale * 100), function(val)
        Config.UI.Scale = val / 100
        -- Apply scale
        local scale = Utility.GetScale()
        local w = math.floor(GUI_WIDTH * scale)
        local h = math.floor(GUI_HEIGHT * scale)
        Utility.Tween(MainFrame, {
            Size = UDim2.new(0, w, 0, h),
        }, Theme.TweenSpeed)
    end, 3, function(v) return v .. "%" end)
    
    -- Animation toggle
    CreateToggle(page, "Animations", Config.UI.Animation, function(state)
        Config.UI.Animation = state
        Notify(state and "Animations enabled" or "Animations disabled")
    end, 4)
    
    -- Blur toggle
    CreateToggle(page, "UI Blur", Config.UI.Blur, function(state)
        Config.UI.Blur = state
        if state then
            ShowBlur()
        else
            HideBlur()
        end
        Notify(state and "Blur enabled" or "Blur disabled")
    end, 5)
    
    CreateSectionHeader(page, "ACTIONS", 6)
    
    -- Reset Config
    CreateButton(page, "Reset Configuration", function()
        Config.ESP.Enabled = false
        DisableESP()
        Config.Crosshair.Enabled = false
        Config.Crosshair.Type = 1
        if CrosshairFrame then ClearCrosshair() CrosshairFrame.Visible = false end
        Config.Visuals.NoFog = false
        Config.Visuals.FullBright = false
        Lighting.FogEnd = SavedLighting.FogEnd
        Lighting.FogStart = SavedLighting.FogStart
        Lighting.Brightness = SavedLighting.Brightness
        Lighting.Ambient = SavedLighting.Ambient
        Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient
        Lighting.GlobalShadows = SavedLighting.GlobalShadows
        Notify("Configuration reset")
    end, 7)
    
    -- Hide GUI
    CreateButton(page, "Hide GUI", function()
        if MainFrame then
            Utility.Tween(MainFrame, {
                Position = UDim2.new(0.5, -GUI_WIDTH*Config.UI.Scale/2, 1, 50),
                BackgroundTransparency = 1
            }, 0.35)
            HideBlur()
            IsOpen = false
            Notify("GUI hidden - press RightControl or tap toggle to show")
        end
    end, 8)
    
    -- Destroy GUI (with confirmation)
    local destroyState = 0
    
    CreateButton(page, "Destroy GUI (confirm)", function()
        if destroyState == 0 then
            destroyState = 1
            Notify("Press again to confirm destruction")
            task.delay(3, function() destroyState = 0 end)
        elseif destroyState == 1 then
            -- Cleanup everything
            DisableESP()
            if CrosshairFrame then CrosshairFrame:Destroy() end
            ConnectionManager:Clear()
            CleanupManager:Clear()
            
            -- Restore lighting
            pcall(function()
                Lighting.FogEnd = SavedLighting.FogEnd
                Lighting.FogStart = SavedLighting.FogStart
                Lighting.Brightness = SavedLighting.Brightness
                Lighting.Ambient = SavedLighting.Ambient
                Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient
                Lighting.GlobalShadows = SavedLighting.GlobalShadows
            end)
            
            if ScreenGui then ScreenGui:Destroy() end
        end
    end, 9, true)
end

-- ============================================================
-- TOGGLE BUTTON (for mobile / hidden state)
-- ============================================================
local function CreateToggleButton()
    local toggleBtn = Utility.Create("TextButton", {
        Name = "XYAN_Toggle",
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 12, 0.5, -21),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.2,
        Text = "X",
        TextColor3 = Theme.Accent,
        Font = Theme.FontBold,
        TextSize = 16,
        BorderSizePixel = 0,
        ZIndex = 200,
        Parent = ScreenGui,
    })
    Utility.AddCorner(toggleBtn, UDim.new(1, 0))
    Utility.AddStroke(toggleBtn, Theme.Border, 1, 0.5)
    
    toggleBtn.MouseButton1Click:Connect(function()
        if IsOpen then
            -- Hide
            local scale = Utility.GetScale()
            Utility.Tween(MainFrame, {
                Position = UDim2.new(0.5, -GUI_WIDTH*scale/2, 1, 50),
                BackgroundTransparency = 1
            }, 0.35)
            HideBlur()
            IsOpen = false
        else
            -- Show
            local scale = Utility.GetScale()
            local w = math.floor(GUI_WIDTH * scale)
            local h = math.floor(GUI_HEIGHT * scale)
            MainFrame.Visible = true
            Utility.Tween(MainFrame, {
                Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
                BackgroundTransparency = Theme.BackgroundTransparency
            }, 0.35)
            if Config.UI.Blur then ShowBlur() end
            IsOpen = true
        end
    end)
    
    return toggleBtn
end

-- ============================================================
-- KEYBOARD TOGGLE
-- ============================================================
ConnectionManager:Add("keyToggle", UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F6 then
        if IsOpen then
            local scale = Utility.GetScale()
            Utility.Tween(MainFrame, {
                Position = UDim2.new(0.5, -GUI_WIDTH*scale/2, 1, 50),
                BackgroundTransparency = 1
            }, 0.35)
            HideBlur()
            IsOpen = false
        else
            local scale = Utility.GetScale()
            local w = math.floor(GUI_WIDTH * scale)
            local h = math.floor(GUI_HEIGHT * scale)
            MainFrame.Visible = true
            Utility.Tween(MainFrame, {
                Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
                BackgroundTransparency = Theme.BackgroundTransparency
            }, 0.35)
            if Config.UI.Blur then ShowBlur() end
            IsOpen = true
        end
    end
end))

-- ============================================================
-- REFRESH MANAGER
-- ============================================================
local RefreshManager = {}

function RefreshManager:Init()
    -- Handle character respawn
    ConnectionManager:Add("charAdded", LocalPlayer.CharacterAdded:Connect(function(char)
        -- Restore ESP if enabled
        if Config.ESP.Enabled then
            task.wait(1)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and not ESPCache[player] then
                    ApplyESP(player)
                end
            end
        end
        
        -- Crosshair stays (it's on ScreenGui)
        -- Visuals stay (lighting-based)
        
        -- Re-apply fog/bright if needed
        if Config.Visuals.NoFog then
            Lighting.FogEnd = 9999999
            Lighting.FogStart = 9999999
        end
        if Config.Visuals.FullBright then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.GlobalShadows = false
        end
    end))
    
    -- Handle lighting changes
    ConnectionManager:Add("lightingChanged", Lighting.Changed:Connect(function(prop)
        if Config.Visuals.NoFog then
            if prop == "FogEnd" and Lighting.FogEnd ~= 9999999 then
                Lighting.FogEnd = 9999999
            end
            if prop == "FogStart" and Lighting.FogStart ~= 9999999 then
                Lighting.FogStart = 9999999
            end
        end
        if Config.Visuals.FullBright then
            if prop == "Brightness" and Lighting.Brightness ~= 2 then
                Lighting.Brightness = 2
            end
        end
    end))
end

-- ============================================================
-- GUI PERSISTENCE
-- ============================================================
local function EnsureGUIExists()
    if not ScreenGui or not ScreenGui.Parent then
        ScreenGui = CreateScreenGui()
        -- Rebuild would be complex; instead just re-parent if possible
    end
end

ConnectionManager:Add("guiPersist", RunService.Heartbeat:Connect(function()
    -- Lightweight check every few seconds
    -- Done via frame counter to avoid overhead
end))

-- ============================================================
-- INITIALIZATION
-- ============================================================
local function Initialize()
    -- 1. Build GUI structure
    BuildMainFrame()
    
    -- 2. Build pages
    BuildHomePage()
    BuildESPPage()
    BuildCrosshairPage()
    BuildVisualsPage()
    BuildSettingsPage()
    
    -- 3. Create notification container
    CreateNotificationContainer()
    
    -- 4. Create toggle button
    CreateToggleButton()
    
    -- 5. Create blur
    CreateBlur()
    
    -- 6. Set default page
    SwitchPage("HOME")
    
    -- 7. Initialize refresh manager
    RefreshManager:Init()
    
    -- 8. Show GUI with animation
    MainFrame.BackgroundTransparency = 1
    MainFrame.Position = UDim2.new(0.5, -GUI_WIDTH*Utility.GetScale()/2, 0.6, 0)
    
    task.wait(0.1)
    
    local scale = Utility.GetScale()
    local w = math.floor(GUI_WIDTH * scale)
    local h = math.floor(GUI_HEIGHT * scale)
    
    Utility.Tween(MainFrame, {
        BackgroundTransparency = Theme.BackgroundTransparency,
        Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
    }, 0.5)
    
    if Config.UI.Blur then ShowBlur() end
    
    -- 9. Welcome notification
    task.delay(0.8, function()
        Notify("XYAN initialized", 3)
    end)
end

-- Run
Initialize()
