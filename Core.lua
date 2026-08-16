--[[
    ZIZU 月 — Core.lua
    Foundation: utilities, managers, detection, helpers.
    Created by zizu
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local Camera = Workspace.CurrentCamera

local Core = {}

-- ═══════════════════════════════════
-- STATE MANAGER
-- ═══════════════════════════════════
Core.State = {
    Initialized = false,
    Running = false,
    Player = Players.LocalPlayer,
    Character = nil,
    Humanoid = nil,
    RootPart = nil,
    GUI = nil,
    Features = {},
    LoadingProgress = 0,
    LoadingStatus = "",
    Platform = "PC",
}

-- ═══════════════════════════════════
-- CONNECTION MANAGER
-- ═══════════════════════════════════
Core.Connections = {}
Core._connectionId = 0

function Core:Connect(signal, callback, tag)
    self._connectionId = self._connectionId + 1
    local id = tag or ("conn_" .. self._connectionId)
    local conn = signal:Connect(callback)
    if not self.Connections[id] then
        self.Connections[id] = {}
    end
    table.insert(self.Connections[id], conn)
    return conn
end

function Core:DisconnectTag(tag)
    if self.Connections[tag] then
        for _, conn in ipairs(self.Connections[tag]) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        self.Connections[tag] = nil
    end
end

function Core:DisconnectAll()
    for tag, conns in pairs(self.Connections) do
        for _, conn in ipairs(conns) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
    end
    self.Connections = {}
end

-- ═══════════════════════════════════
-- EVENT MANAGER
-- ═══════════════════════════════════
Core.Events = {}
Core._listeners = {}

function Core:On(event, callback)
    if not self._listeners[event] then
        self._listeners[event] = {}
    end
    table.insert(self._listeners[event], callback)
    return {
        Disconnect = function()
            local list = self._listeners[event]
            if list then
                for i, cb in ipairs(list) do
                    if cb == callback then
                        table.remove(list, i)
                        break
                    end
                end
            end
        end
    }
end

function Core:Fire(event, ...)
    if self._listeners[event] then
        for _, cb in ipairs(self._listeners[event]) do
            task.spawn(function(...)
                local s, e = pcall(cb, ...)
                if not s then
                    warn("[ZIZU Event Error]", event, e)
                end
            end, ...)
        end
    end
end

-- ═══════════════════════════════════
-- CLEANUP MANAGER
-- ═══════════════════════════════════
Core._cleanupTasks = {}

function Core:AddCleanup(fn)
    table.insert(self._cleanupTasks, fn)
end

function Core:RunCleanup()
    for _, fn in ipairs(self._cleanupTasks) do
        pcall(fn)
    end
    self._cleanupTasks = {}
    self:DisconnectAll()
end

-- ═══════════════════════════════════
-- ENVIRONMENT DETECTION
-- ═══════════════════════════════════
function Core:DetectPlatform()
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local isTablet = UserInputService.TouchEnabled and (Camera.ViewportSize.X > 1000)
    if isMobile then
        self.State.Platform = isTablet and "TABLET" or "MOBILE"
    else
        self.State.Platform = "PC"
    end
    return self.State.Platform
end

function Core:IsMobile()
    return self.State.Platform == "MOBILE" or self.State.Platform == "TABLET"
end

function Core:IsPC()
    return self.State.Platform == "PC"
end

function Core:ValidateEnvironment()
    local checks = {
        Player = self.State.Player ~= nil,
        PlayerGui = self.State.Player and self.State.Player:FindFirstChild("PlayerGui") ~= nil,
    }
    for name, passed in pairs(checks) do
        if not passed then
            warn("[ZIZU] Environment check failed:", name)
            return false
        end
    end
    return true
end

-- ═══════════════════════════════════
-- PLAYER / CHARACTER MANAGER
-- ═══════════════════════════════════
function Core:SetupCharacter()
    local player = self.State.Player
    local function onCharacter(char)
        self.State.Character = char
        local humanoid = char:WaitForChild("Humanoid", 10)
        self.State.Humanoid = humanoid
        self.State.RootPart = char:WaitForChild("HumanoidRootPart", 10)
        self:Fire("CharacterAdded", char)

        if humanoid then
            self:Connect(humanoid.Died:Once(function()
                self:Fire("CharacterDied")
            end), nil, "character_died")
        end
    end

    if player.Character then
        onCharacter(player.Character)
    end
    self:Connect(player.CharacterAdded, onCharacter, "character_added")
    self:Connect(player.CharacterRemoving, function()
        self.State.Character = nil
        self.State.Humanoid = nil
        self.State.RootPart = nil
        self:Fire("CharacterRemoving")
    end, "character_removing")
end

function Core:GetCharacter()
    return self.State.Character or self.State.Player.Character
end

function Core:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Core:GetRootPart()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════
-- OBJECT DETECTION
-- ═══════════════════════════════════
Core._objectCache = {}

function Core:FindObjectsByMapping(mapping)
    local results = {}
    local found = {}

    if mapping.Tags then
        for _, tag in ipairs(mapping.Tags) do
            local tagged = CollectionService:GetTagged(tag)
            for _, obj in ipairs(tagged) do
                if not found[obj] then
                    found[obj] = true
                    table.insert(results, obj)
                end
            end
        end
    end

    if mapping.Attributes then
        for _, attrName in ipairs(mapping.Attributes) do
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:GetAttribute(attrName) and not found[desc] then
                    found[desc] = true
                    table.insert(results, desc)
                end
            end
        end
    end

    if mapping.Names and #results == 0 then
        for _, name in ipairs(mapping.Names) do
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc.Name == name and (desc:IsA("Model") or desc:IsA("BasePart")) and not found[desc] then
                    found[desc] = true
                    table.insert(results, desc)
                end
            end
        end
    end

    return results
end

function Core:WatchTagged(tag, onAdded, onRemoved)
    local existing = CollectionService:GetTagged(tag)
    for _, obj in ipairs(existing) do
        task.spawn(onAdded, obj)
    end
    self:Connect(CollectionService:GetInstanceAddedSignal(tag), onAdded, "tag_" .. tag)
    if onRemoved then
        self:Connect(CollectionService:GetInstanceRemovedSignal(tag), onRemoved, "tag_" .. tag)
    end
end

-- ═══════════════════════════════════
-- REMOTE FINDER
-- ═══════════════════════════════════
function Core:FindRemote(names, classType)
    classType = classType or "RemoteEvent"
    if type(names) == "string" then names = {names} end
    for _, name in ipairs(names) do
        local remote = ReplicatedStorage:FindFirstChild(name, true)
        if remote and remote:IsA(classType) then
            return remote
        end
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == name and desc:IsA(classType) then
                return desc
            end
        end
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == name and desc:IsA(classType) then
                return desc
            end
        end
    end
    return nil
end

function Core:FindRemoteFunction(names)
    return self:FindRemote(names, "RemoteFunction")
end

-- ═══════════════════════════════════
-- DISTANCE CALCULATION
-- ═══════════════════════════════════
function Core:GetDistance(a, b)
    local posA, posB
    if typeof(a) == "Vector3" then
        posA = a
    elseif typeof(a) == "Instance" then
        if a:IsA("Model") then
            posA = a:GetPivot().Position
        elseif a:IsA("BasePart") then
            posA = a.Position
        end
    end

    if typeof(b) == "Vector3" then
        posB = b
    elseif typeof(b) == "Instance" then
        if b:IsA("Model") then
            posB = b:GetPivot().Position
        elseif b:IsA("BasePart") then
            posB = b.Position
        end
    end

    if posA and posB then
        return (posA - posB).Magnitude
    end
    return math.huge
end

function Core:GetDistanceFromPlayer(target)
    local root = self:GetRootPart()
    if not root then return math.huge end
    return self:GetDistance(root, target)
end

function Core:GetObjectPosition(obj)
    if obj:IsA("Model") then
        local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return primary and primary.Position or obj:GetPivot().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
    return nil
end

-- ═══════════════════════════════════
-- TWEEN HELPER
-- ═══════════════════════════════════
function Core:Tween(instance, props, duration, style, direction)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

function Core:TweenSequence(tweens)
    task.spawn(function()
        for _, t in ipairs(tweens) do
            local tween = self:Tween(t.Instance, t.Props, t.Duration, t.Style, t.Direction)
            if t.Wait ~= false then
                tween.Completed:Wait()
            end
            if t.Delay then
                task.wait(t.Delay)
            end
        end
    end)
end

-- ═══════════════════════════════════
-- UI HELPER
-- ═══════════════════════════════════
function Core:Create(className, properties, children)
    local inst = Instance.new(className)
    if properties then
        for k, v in pairs(properties) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if properties and properties.Parent then
        inst.Parent = properties.Parent
    end
    return inst
end

function Core:ApplyCorner(instance, radius)
    return self:Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = instance,
    })
end

function Core:ApplyStroke(instance, color, thickness, transparency)
    return self:Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 70),
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = instance,
    })
end

function Core:ApplyPadding(instance, top, bottom, left, right)
    return self:Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft = UDim.new(0, left or 8),
        PaddingRight = UDim.new(0, right or 8),
        Parent = instance,
    })
end

function Core:ApplyListLayout(instance, direction, padding, hAlign, vAlign, sortOrder)
    return self:Create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, padding or 6),
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = instance,
    })
end

-- ═══════════════════════════════════
-- NOTIFICATION MANAGER
-- ═══════════════════════════════════
Core._notifQueue = {}

function Core:Notify(title, message, duration)
    self:Fire("Notification", title or "ZIZU", message or "", duration or 3)
end

-- ═══════════════════════════════════
-- SAFE EXECUTION
-- ═══════════════════════════════════
function Core:SafeCall(fn, ...)
    local success, result = pcall(fn, ...)
    if not success then
        warn("[ZIZU Error]", result)
        self:Notify("Error", tostring(result), 4)
    end
    return success, result
end

function Core:SafeSpawn(fn, ...)
    local args = {...}
    task.spawn(function()
        local success, result = pcall(fn, unpack(args))
        if not success then
            warn("[ZIZU Error]", result)
        end
    end)
end

-- ═══════════════════════════════════
-- FEATURE REGISTRY
-- ═══════════════════════════════════
Core.Registry = {}

function Core:RegisterFeature(name, feature)
    self.Registry[name] = feature
    self:Fire("FeatureRegistered", name, feature)
end

function Core:GetFeature(name)
    return self.Registry[name]
end

function Core:IsFeatureEnabled(name)
    local f = self.Registry[name]
    return f and f._enabled == true
end

-- ═══════════════════════════════════
-- LIGHTING STATE BACKUP
-- ═══════════════════════════════════
Core._lightingBackup = nil

function Core:BackupLighting()
    if self._lightingBackup then return end
    self._lightingBackup = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        FogColor = Lighting.FogColor,
        GlobalShadows = Lighting.GlobalShadows,
        ClockTime = Lighting.ClockTime,
    }
end

function Core:RestoreLighting()
    if not self._lightingBackup then return end
    for k, v in pairs(self._lightingBackup) do
        pcall(function() Lighting[k] = v end)
    end
    self._lightingBackup = nil
end

-- ═══════════════════════════════════
-- BILLBOARD GUI CREATOR
-- ═══════════════════════════════════
function Core:CreateBillboard(adornee, text, color, studOffset)
    local billboard = self:Create("BillboardGui", {
        Adornee = adornee,
        Size = UDim2.new(0, 200, 0, 50),
        StudsOffset = studOffset or Vector3.new(0, 3, 0),
        AlwaysOnTop = true,
        LightInfluence = 0,
        MaxDistance = 500,
    })

    local label = self:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = color or Color3.fromRGB(255, 255, 255),
        Text = text or "",
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = billboard,
    })

    return billboard, label
end

-- ═══════════════════════════════════
-- HIGHLIGHT CREATOR
-- ═══════════════════════════════════
function Core:CreateHighlight(adornee, fillColor, outlineColor, fillTransparency, outlineTransparency)
    local existing = adornee:FindFirstChildWhichIsA("Highlight")
    if existing and existing.Name == "ZIZU_Highlight" then
        existing.FillColor = fillColor or Color3.fromRGB(255, 255, 255)
        existing.OutlineColor = outlineColor or fillColor or Color3.fromRGB(255, 255, 255)
        existing.FillTransparency = fillTransparency or 0.7
        existing.OutlineTransparency = outlineTransparency or 0
        return existing
    end
    return self:Create("Highlight", {
        Name = "ZIZU_Highlight",
        Adornee = adornee,
        FillColor = fillColor or Color3.fromRGB(255, 255, 255),
        OutlineColor = outlineColor or fillColor or Color3.fromRGB(255, 255, 255),
        FillTransparency = fillTransparency or 0.7,
        OutlineTransparency = outlineTransparency or 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        Parent = adornee,
    })
end

function Core:RemoveHighlight(adornee)
    if adornee then
        local h = adornee:FindFirstChild("ZIZU_Highlight")
        if h then h:Destroy() end
    end
end

-- ═══════════════════════════════════
-- BLUR MANAGER
-- ═══════════════════════════════════
Core._blur = nil

function Core:SetBlur(enabled, size)
    if enabled then
        if not self._blur then
            self._blur = Instance.new("BlurEffect")
            self._blur.Name = "ZIZU_Blur"
            self._blur.Size = 0
            self._blur.Parent = Lighting
        end
        self:Tween(self._blur, {Size = size or 12}, 0.4)
    else
        if self._blur then
            local blur = self._blur
            local t = self:Tween(blur, {Size = 0}, 0.3)
            t.Completed:Connect(function()
                blur:Destroy()
            end)
            self._blur = nil
        end
    end
end

-- ═══════════════════════════════════
-- SCREEN SIZE
-- ═══════════════════════════════════
function Core:GetScreenSize()
    return Camera.ViewportSize
end

function Core:IsSmallScreen()
    return Camera.ViewportSize.X < 700
end

-- ═══════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════
function Core:Initialize()
    self:DetectPlatform()
    self:SetupCharacter()
    self.State.Initialized = true
    self.State.Running = true
    return self
end

function Core:Destroy()
    self.State.Running = false
    self:SetBlur(false)
    self:RestoreLighting()
    self:RunCleanup()
    if self.State.GUI then
        self.State.GUI:Destroy()
        self.State.GUI = nil
    end
end

return Core
