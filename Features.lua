--[[
    ZIZU 月 — Features.lua
    All gameplay and visual features.
    Created by zizu
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Features = {}

local Core
local Config

function Features:Init(core, config)
    Core = core
    Config = config
    return self
end

-- ═════════════════════════════════════════════
-- FEATURE BASE
-- ═════════════════════════════════════════════
local function CreateFeature(name, configPath)
    local feature = {
        _name = name,
        _enabled = false,
        _configPath = configPath,
        _connections = {},
        _objects = {},
    }

    function feature:IsEnabled()
        return self._enabled
    end

    function feature:AddConnection(conn)
        table.insert(self._connections, conn)
    end

    function feature:ClearConnections()
        for _, c in ipairs(self._connections) do
            if c and typeof(c) == "RBXScriptConnection" and c.Connected then
                c:Disconnect()
            end
        end
        self._connections = {}
    end

    function feature:ClearObjects()
        for _, obj in ipairs(self._objects) do
            pcall(function() obj:Destroy() end)
        end
        self._objects = {}
    end

    function feature:CleanupAll()
        self:ClearConnections()
        self:ClearObjects()
    end

    function feature:Toggle()
        if self._enabled then
            self:Disable()
        else
            self:Enable()
        end
    end

    function feature:SetEnabled(state)
        if state then
            self:Enable()
        else
            self:Disable()
        end
    end

    function feature:SaveState()
        if self._configPath then
            Config:Set(self._configPath .. ".Enabled", self._enabled)
        end
    end

    return feature
end

-- ═════════════════════════════════════════════
-- ESP (PLAYER)
-- ═════════════════════════════════════════════
Features.ESP = CreateFeature("ESP", "ESP")

function Features.ESP:Initialize()
    self._highlights = {}
    self._billboards = {}
end

function Features.ESP:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local localPlayer = Core.State.Player

    local function isKiller(player)
        local char = player.Character
        if char then
            if char:GetAttribute("Role") == "Killer" then return true end
            if char:GetAttribute("IsKiller") then return true end
            if CollectionService:HasTag(player, "Killer") then return true end
            if CollectionService:HasTag(char, "Killer") then return true end
        end
        if player:GetAttribute("Role") == "Killer" then return true end
        if player:GetAttribute("IsKiller") then return true end
        return false
    end

    local function applyESP(player)
        if player == localPlayer then return end
        local char = player.Character
        if not char then return end

        local isK = isKiller(player)
        local showSurvivor = Config:Get("ESP.Survivor")
        local showKiller = Config:Get("ESP.Killer")

        if isK and not showKiller then return end
        if not isK and not showSurvivor then return end

        local color
        if isK then
            color = Config:GetColor3(Config:Get("ESP.KillerColor"))
        else
            color = Config:GetColor3(Config:Get("ESP.SurvivorColor"))
        end

        self:RemoveESP(player)

        local highlight = Core:CreateHighlight(char, color, color, 0.65, 0)
        self._highlights[player] = highlight

        if Config:Get("ESP.ShowName") or Config:Get("ESP.ShowDistance") then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
            if root then
                local billboard, label = Core:CreateBillboard(root, "", color, Vector3.new(0, 4, 0))
                billboard.Name = "ZIZU_ESP_Billboard"
                billboard.Parent = Core.State.GUI or game:GetService("CoreGui")
                self._billboards[player] = {Billboard = billboard, Label = label}
                table.insert(self._objects, billboard)
            end
        end
    end

    local function removeESP(player)
        self:RemoveESP(player)
    end

    local function updateLabels()
        for player, data in pairs(self._billboards) do
            if player.Parent and data.Label and data.Label.Parent then
                local parts = {}
                if Config:Get("ESP.ShowName") then
                    table.insert(parts, player.DisplayName or player.Name)
                end
                if Config:Get("ESP.ShowDistance") then
                    local dist = Core:GetDistanceFromPlayer(player.Character)
                    if dist < math.huge then
                        table.insert(parts, math.floor(dist) .. "m")
                    end
                end
                data.Label.Text = table.concat(parts, " | ")
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            task.spawn(applyESP, player)
        end
        self:AddConnection(player.CharacterAdded:Connect(function()
            task.wait(0.5)
            applyESP(player)
        end))
    end

    self:AddConnection(Players.PlayerAdded:Connect(function(player)
        self:AddConnection(player.CharacterAdded:Connect(function()
            task.wait(0.5)
            applyESP(player)
        end))
    end))

    self:AddConnection(Players.PlayerRemoving:Connect(removeESP))

    self:AddConnection(RunService.Heartbeat:Connect(function()
        if tick() % 0.5 < 0.03 then
            updateLabels()
        end
    end))

    Core:Notify("ZIZU", "ESP enabled")
end

function Features.ESP:RemoveESP(player)
    if self._highlights[player] then
        pcall(function() self._highlights[player]:Destroy() end)
        self._highlights[player] = nil
    end
    if self._billboards[player] then
        pcall(function() self._billboards[player].Billboard:Destroy() end)
        self._billboards[player] = nil
    end
end

function Features.ESP:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    for player, _ in pairs(self._highlights) do
        self:RemoveESP(player)
    end
    self._highlights = {}
    self._billboards = {}
    self:ClearObjects()
    Core:Notify("ZIZU", "ESP disabled")
end

function Features.ESP:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- ESP WORLD
-- ═════════════════════════════════════════════
Features.ESPWorld = CreateFeature("ESPWorld", "ESPWorld")

function Features.ESPWorld:Initialize()
    self._espObjects = {}
    self._updateConn = nil
end

function Features.ESPWorld:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()
    self:ScanAndApply()
    self:StartWatching()
    Core:Notify("ZIZU", "ESP World enabled")
end

function Features.ESPWorld:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    self:RemoveAllESP()
    Core:Notify("ZIZU", "ESP World disabled")
end

function Features.ESPWorld:SetCategory(category, enabled)
    Config:Set("ESPWorld." .. category, enabled)
    if self._enabled then
        self:RemoveAllESP()
        self:ScanAndApply()
    end
end

function Features.ESPWorld:ScanAndApply()
    local mapping = Config:Get("ObjectMapping")
    local categories = {"Pallet", "Generator", "Hook", "Gate", "Window"}

    for _, cat in ipairs(categories) do
        if Config:Get("ESPWorld." .. cat) then
            local m = mapping[cat]
            if m then
                local objects = Core:FindObjectsByMapping(m)
                for _, obj in ipairs(objects) do
                    self:ApplyESPToObject(obj, cat)
                end
            end
        end
    end
end

function Features.ESPWorld:ApplyESPToObject(obj, category)
    if self._espObjects[obj] then return end

    local colorTable = Config:Get("ESPWorld.Colors." .. category)
    local color = Config:GetColor3(colorTable)

    local target = obj
    if obj:IsA("Model") then
        target = obj
    end

    local highlight = Core:CreateHighlight(target, color, color, 0.75, 0.2)

    local billboardData = nil
    if Config:Get("ESPWorld.ShowLabel") or Config:Get("ESPWorld.ShowDistance") then
        local adornee = obj
        if obj:IsA("Model") then
            adornee = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
        if adornee then
            local billboard, label = Core:CreateBillboard(adornee, category:upper(), color, Vector3.new(0, 3.5, 0))
            billboard.Name = "ZIZU_ESPW_" .. category
            billboard.Parent = Core.State.GUI or game:GetService("CoreGui")
            billboardData = {Billboard = billboard, Label = label}
            table.insert(self._objects, billboard)
        end
    end

    self._espObjects[obj] = {
        Highlight = highlight,
        Billboard = billboardData,
        Category = category,
    }
end

function Features.ESPWorld:RemoveESPFromObject(obj)
    local data = self._espObjects[obj]
    if not data then return end
    pcall(function() data.Highlight:Destroy() end)
    if data.Billboard then
        pcall(function() data.Billboard.Billboard:Destroy() end)
    end
    self._espObjects[obj] = nil
end

function Features.ESPWorld:RemoveAllESP()
    for obj, _ in pairs(self._espObjects) do
        self:RemoveESPFromObject(obj)
    end
    self._espObjects = {}
    self:ClearObjects()
end

function Features.ESPWorld:StartWatching()
    local mapping = Config:Get("ObjectMapping")
    local categories = {"Pallet", "Generator", "Hook", "Gate", "Window"}

    for _, cat in ipairs(categories) do
        local m = mapping[cat]
        if m and m.Tags then
            for _, tag in ipairs(m.Tags) do
                self:AddConnection(CollectionService:GetInstanceAddedSignal(tag):Connect(function(obj)
                    if Config:Get("ESPWorld." .. cat) then
                        self:ApplyESPToObject(obj, cat)
                    end
                end))
                self:AddConnection(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(obj)
                    self:RemoveESPFromObject(obj)
                end))
            end
        end
    end

    self:AddConnection(Workspace.DescendantRemoving:Connect(function(obj)
        if self._espObjects[obj] then
            self:RemoveESPFromObject(obj)
        end
    end))

    self:AddConnection(RunService.Heartbeat:Connect(function()
        if tick() % 1 < 0.03 then
            self:UpdateLabels()
        end
    end))
end

function Features.ESPWorld:UpdateLabels()
    for obj, data in pairs(self._espObjects) do
        if data.Billboard and data.Billboard.Label and data.Billboard.Label.Parent then
            local parts = {}
            if Config:Get("ESPWorld.ShowLabel") then
                table.insert(parts, data.Category:upper())
            end

            if data.Category == "Generator" then
                local progress = nil
                if obj:GetAttribute("GeneratorProgress") then
                    progress = obj:GetAttribute("GeneratorProgress")
                elseif obj:GetAttribute("Progress") then
                    progress = obj:GetAttribute("Progress")
                elseif obj:FindFirstChild("Progress") and obj.Progress:IsA("NumberValue") then
                    progress = obj.Progress.Value
                end
                if progress then
                    table.insert(parts, math.floor(progress) .. "%")
                end
            end

            if data.Category == "Gate" then
                local state = obj:GetAttribute("GateState") or obj:GetAttribute("State")
                if state then
                    table.insert(parts, tostring(state):upper())
                end
            end

            if Config:Get("ESPWorld.ShowDistance") then
                local dist = Core:GetDistanceFromPlayer(obj)
                if dist < math.huge then
                    table.insert(parts, math.floor(dist) .. "m")
                end
            end

            data.Billboard.Label.Text = table.concat(parts, " | ")
        end
    end
end

function Features.ESPWorld:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- OUTLINE
-- ═════════════════════════════════════════════
Features.Outline = CreateFeature("Outline", "Outline")

function Features.Outline:Initialize()
    self._outlines = {}
end

function Features.Outline:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local localPlayer = Core.State.Player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            self:ApplyOutline(player)
        end
    end

    self:AddConnection(Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self._enabled then self:ApplyOutline(p) end
        end)
    end))

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            self:AddConnection(player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if self._enabled then self:ApplyOutline(player) end
            end))
        end
    end

    Core:Notify("ZIZU", "Outline enabled")
end

function Features.Outline:ApplyOutline(player)
    if player == Core.State.Player then return end
    local char = player.Character
    if not char then return end
    self:RemoveOutline(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ZIZU_Outline"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    self._outlines[player] = highlight
end

function Features.Outline:RemoveOutline(player)
    if self._outlines[player] then
        pcall(function() self._outlines[player]:Destroy() end)
        self._outlines[player] = nil
    end
end

function Features.Outline:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    for player, _ in pairs(self._outlines) do
        self:RemoveOutline(player)
    end
    self._outlines = {}
    Core:Notify("ZIZU", "Outline disabled")
end

function Features.Outline:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- WARN KILLER
-- ═════════════════════════════════════════════
Features.WarnKiller = CreateFeature("WarnKiller", "WarnKiller")

function Features.WarnKiller:Initialize()
    self._warningGui = nil
    self._warningLabel = nil
end

function Features.WarnKiller:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local gui = Core.State.GUI
    if not gui then return end

    local frame = Core:Create("Frame", {
        Name = "ZIZU_WarnKiller",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = gui,
    })

    local label = Core:Create("TextLabel", {
        Name = "WarnLabel",
        Size = UDim2.new(0, 120, 0, 120),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "!",
        TextColor3 = Color3.fromRGB(255, 40, 40),
        TextTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 72,
        ZIndex = 101,
        Parent = frame,
    })

    local redOverlay = Core:Create("Frame", {
        Name = "RedOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 99,
        Parent = frame,
    })

    self._warningGui = frame
    self._warningLabel = label
    self._redOverlay = redOverlay

    local function findKiller()
        local localPlayer = Core.State.Player
        local closest = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local char = player.Character
                if char then
                    local isK = false
                    if char:GetAttribute("Role") == "Killer" or char:GetAttribute("IsKiller") then isK = true end
                    if CollectionService:HasTag(player, "Killer") or CollectionService:HasTag(char, "Killer") then isK = true end
                    if player:GetAttribute("Role") == "Killer" or player:GetAttribute("IsKiller") then isK = true end
                    if isK then
                        local d = Core:GetDistanceFromPlayer(char)
                        if d < closest then closest = d end
                    end
                end
            end
        end
        return closest
    end

    self:AddConnection(RunService.Heartbeat:Connect(function()
        if not self._enabled then return end
        local dist = findKiller()
        local l1 = Config:Get("WarnKiller.Level1Distance") or 60
        local l2 = Config:Get("WarnKiller.Level2Distance") or 35
        local l3 = Config:Get("WarnKiller.Level3Distance") or 15

        if dist <= l3 then
            label.TextTransparency = 0
            label.TextSize = 96
            redOverlay.BackgroundTransparency = 0.85
            local pulse = math.sin(tick() * 8) * 0.1
            label.TextTransparency = math.clamp(pulse, 0, 0.3)
            label.Position = UDim2.new(0.5, math.sin(tick() * 20) * 3, 0.5, math.cos(tick() * 20) * 3)
        elseif dist <= l2 then
            label.TextTransparency = 0.2
            label.TextSize = 72
            redOverlay.BackgroundTransparency = 0.92
            label.Position = UDim2.new(0.5, 0, 0.5, 0)
        elseif dist <= l1 then
            label.TextTransparency = 0.5
            label.TextSize = 56
            redOverlay.BackgroundTransparency = 0.96
            label.Position = UDim2.new(0.5, 0, 0.5, 0)
        else
            label.TextTransparency = 1
            redOverlay.BackgroundTransparency = 1
        end
    end))

    Core:Notify("ZIZU", "Warn Killer enabled")
end

function Features.WarnKiller:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    if self._warningGui then
        self._warningGui:Destroy()
        self._warningGui = nil
    end
    Core:Notify("ZIZU", "Warn Killer disabled")
end

function Features.WarnKiller:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- WORLD SETTINGS
-- ═════════════════════════════════════════════
Features.WorldSettings = CreateFeature("WorldSettings", "WorldSettings")

function Features.WorldSettings:Initialize() end

function Features.WorldSettings:Enable() end
function Features.WorldSettings:Disable() end

function Features.WorldSettings:SetBrightWorld(enabled)
    Config:Set("WorldSettings.BrightWorld", enabled)
    if enabled then
        Core:BackupLighting()
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    else
        Core:RestoreLighting()
    end
end

function Features.WorldSettings:SetNoFog(enabled)
    Config:Set("WorldSettings.NoFog", enabled)
    if enabled then
        Core:BackupLighting()
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 1e10
    else
        Core:RestoreLighting()
    end
end

function Features.WorldSettings:SetClearLighting(enabled)
    Config:Set("WorldSettings.ClearLighting", enabled)
    if enabled then
        Core:BackupLighting()
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    else
        Core:RestoreLighting()
    end
end

function Features.WorldSettings:SetFullbright(enabled)
    Config:Set("WorldSettings.Fullbright", enabled)
    if enabled then
        Core:BackupLighting()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
    else
        Core:RestoreLighting()
    end
end

function Features.WorldSettings:Destroy()
    Core:RestoreLighting()
end

-- ═════════════════════════════════════════════
-- DROP ALL
-- ═════════════════════════════════════════════
Features.DropAll = CreateFeature("DropAll", "DropAll")

function Features.DropAll:Initialize()
    self._dropRemote = nil
end

function Features.DropAll:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local remoteNames = Config:Get("RemoteMapping.DropPallet") or {"DropPallet", "PalletDrop", "UsePallet"}
    self._dropRemote = Core:FindRemote(remoteNames)

    if not self._dropRemote then
        local interactNames = Config:Get("RemoteMapping.Interact") or {"Interact", "PlayerInteract"}
        self._dropRemote = Core:FindRemote(interactNames)
    end

    if not self._dropRemote then
        Core:Notify("ZIZU", "Drop remote not found in this Experience")
        self._enabled = false
        self:SaveState()
        return
    end

    local palletMapping = Config:Get("ObjectMapping.Pallet")
    local pallets = Core:FindObjectsByMapping(palletMapping)

    if #pallets == 0 then
        Core:Notify("ZIZU", "No pallets found")
        self._enabled = false
        self:SaveState()
        return
    end

    for _, pallet in ipairs(pallets) do
        task.spawn(function()
            local droppable = pallet:GetAttribute("Droppable")
            local state = pallet:GetAttribute("State") or pallet:GetAttribute("PalletState")
            if droppable == false then return end
            if state and (tostring(state):lower() == "dropped" or tostring(state):lower() == "destroyed") then return end

            pcall(function()
                self._dropRemote:FireServer(pallet)
            end)
            pcall(function()
                self._dropRemote:FireServer("DropPallet", pallet)
            end)
            pcall(function()
                self._dropRemote:FireServer({Action = "Drop", Target = pallet})
            end)
        end)
    end

    Core:Notify("ZIZU", "Drop All executed on " .. #pallets .. " pallets")
    self._enabled = false
    self:SaveState()
end

function Features.DropAll:Disable()
    self._enabled = false
    self:SaveState()
end

function Features.DropAll:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- NO LOOP
-- ═════════════════════════════════════════════
Features.NoLoop = CreateFeature("NoLoop", "NoLoop")

function Features.NoLoop:Initialize()
    self._blockedConnections = {}
end

function Features.NoLoop:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local windowMapping = Config:Get("ObjectMapping.Window")
    local windows = Core:FindObjectsByMapping(windowMapping)

    for _, window in ipairs(windows) do
        local loopAttr = window:GetAttribute("LoopEnabled") or window:GetAttribute("CanLoop")
        if loopAttr ~= nil then
            window:SetAttribute("ZIZU_OriginalLoop", loopAttr)
            pcall(function() window:SetAttribute("LoopEnabled", false) end)
            pcall(function() window:SetAttribute("CanLoop", false) end)
        end

        local cd = window:FindFirstChild("Cooldown") or window:FindFirstChild("LoopCooldown")
        if cd and cd:IsA("NumberValue") then
            cd:SetAttribute("ZIZU_OriginalCD", cd.Value)
            cd.Value = 999999
        end
    end

    if #windows > 0 then
        Core:Notify("ZIZU", "No Loop enabled on " .. #windows .. " windows")
    else
        Core:Notify("ZIZU", "No loopable objects found")
    end
end

function Features.NoLoop:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()

    local windowMapping = Config:Get("ObjectMapping.Window")
    local windows = Core:FindObjectsByMapping(windowMapping)

    for _, window in ipairs(windows) do
        local origLoop = window:GetAttribute("ZIZU_OriginalLoop")
        if origLoop ~= nil then
            pcall(function() window:SetAttribute("LoopEnabled", origLoop) end)
            pcall(function() window:SetAttribute("CanLoop", origLoop) end)
            window:SetAttribute("ZIZU_OriginalLoop", nil)
        end

        local cd = window:FindFirstChild("Cooldown") or window:FindFirstChild("LoopCooldown")
        if cd and cd:IsA("NumberValue") then
            local orig = cd:GetAttribute("ZIZU_OriginalCD")
            if orig then
                cd.Value = orig
                cd:SetAttribute("ZIZU_OriginalCD", nil)
            end
        end
    end

    Core:Notify("ZIZU", "No Loop disabled")
end

function Features.NoLoop:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- FAKE HIT
-- ═════════════════════════════════════════════
Features.FakeHit = CreateFeature("FakeHit", "FakeHit")

function Features.FakeHit:Initialize()
    self._animTrack = nil
end

function Features.FakeHit:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local char = Core:GetCharacter()
    if not char then
        Core:Notify("ZIZU", "No character found")
        self._enabled = false
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        Core:Notify("ZIZU", "No humanoid found")
        self._enabled = false
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local hitAnims = {}
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Animation") and (desc.Name:lower():find("hit") or desc.Name:lower():find("attack") or desc.Name:lower():find("swing")) then
            table.insert(hitAnims, desc)
        end
    end

    if #hitAnims == 0 then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("Animation") and (desc.Name:lower():find("hit") or desc.Name:lower():find("attack")) then
                table.insert(hitAnims, desc)
                break
            end
        end
    end

    if #hitAnims > 0 then
        local anim = hitAnims[1]
        local success, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if success and track then
            track:Play()
            self._animTrack = track
            Core:Notify("ZIZU", "Fake Hit played")
        else
            Core:Notify("ZIZU", "Could not play hit animation")
        end
    else
        local existing = animator:GetPlayingAnimationTracks()
        if #existing > 0 then
            Core:Notify("ZIZU", "No hit animation found - character has " .. #existing .. " playing tracks")
        else
            Core:Notify("ZIZU", "No hit animation found in this Experience")
        end
    end

    self._enabled = false
    self:SaveState()
end

function Features.FakeHit:Disable()
    self._enabled = false
    self:SaveState()
    if self._animTrack then
        pcall(function() self._animTrack:Stop() end)
        self._animTrack = nil
    end
end

function Features.FakeHit:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- NO DROP
-- ═════════════════════════════════════════════
Features.NoDrop = CreateFeature("NoDrop", "NoDrop")

function Features.NoDrop:Initialize()
    self._originalStates = {}
end

function Features.NoDrop:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local palletMapping = Config:Get("ObjectMapping.Pallet")
    local pallets = Core:FindObjectsByMapping(palletMapping)

    for _, pallet in ipairs(pallets) do
        local droppable = pallet:GetAttribute("Droppable")
        local interactable = pallet:GetAttribute("Interactable") or pallet:GetAttribute("CanInteract")
        self._originalStates[pallet] = {
            Droppable = droppable,
            Interactable = interactable,
        }
        pcall(function() pallet:SetAttribute("Droppable", false) end)
        pcall(function() pallet:SetAttribute("Interactable", false) end)
        pcall(function() pallet:SetAttribute("CanInteract", false) end)

        local prox = pallet:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prox then
            self._originalStates[pallet].ProxEnabled = prox.Enabled
            prox.Enabled = false
        end
    end

    self:AddConnection(Workspace.DescendantAdded:Connect(function(desc)
        if not self._enabled then return end
        task.wait(0.1)
        local isPallet = false
        if palletMapping.Tags then
            for _, tag in ipairs(palletMapping.Tags) do
                if CollectionService:HasTag(desc, tag) then isPallet = true break end
            end
        end
        if not isPallet and palletMapping.Names then
            for _, n in ipairs(palletMapping.Names) do
                if desc.Name == n then isPallet = true break end
            end
        end
        if isPallet then
            self._originalStates[desc] = {Droppable = desc:GetAttribute("Droppable")}
            pcall(function() desc:SetAttribute("Droppable", false) end)
            pcall(function() desc:SetAttribute("Interactable", false) end)
        end
    end))

    if #pallets > 0 then
        Core:Notify("ZIZU", "No Drop enabled on " .. #pallets .. " pallets")
    else
        Core:Notify("ZIZU", "No pallets found")
    end
end

function Features.NoDrop:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()

    for pallet, states in pairs(self._originalStates) do
        if pallet and pallet.Parent then
            if states.Droppable ~= nil then
                pcall(function() pallet:SetAttribute("Droppable", states.Droppable) end)
            end
            if states.Interactable ~= nil then
                pcall(function() pallet:SetAttribute("Interactable", states.Interactable) end)
                pcall(function() pallet:SetAttribute("CanInteract", states.Interactable) end)
            end
            if states.ProxEnabled ~= nil then
                local prox = pallet:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prox then prox.Enabled = states.ProxEnabled end
            end
        end
    end
    self._originalStates = {}
    Core:Notify("ZIZU", "No Drop disabled")
end

function Features.NoDrop:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- HITBOX
-- ═════════════════════════════════════════════
Features.Hitbox = CreateFeature("Hitbox", "Hitbox")

function Features.Hitbox:Initialize()
    self._originalSizes = {}
end

function Features.Hitbox:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local size = Config:Get("Hitbox.Size") or 1
    self:ApplyHitbox(size)

    self:AddConnection(Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(1)
            if self._enabled then self:ApplyHitbox(Config:Get("Hitbox.Size") or 1) end
        end)
    end))

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Core.State.Player then
            self:AddConnection(p.CharacterAdded:Connect(function()
                task.wait(1)
                if self._enabled then self:ApplyHitbox(Config:Get("Hitbox.Size") or 1) end
            end))
        end
    end

    Core:Notify("ZIZU", "Hitbox enabled (Size: " .. size .. ")")
end

function Features.Hitbox:ApplyHitbox(size)
    local localPlayer = Core.State.Player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if not self._originalSizes[player] then
                    self._originalSizes[player] = root.Size
                end
                root.Size = Vector3.new(size, size, size)
                root.Transparency = size > 1 and 0.8 or 1
                root.CanCollide = false
            end
        end
    end
end

function Features.Hitbox:SetSize(size)
    Config:Set("Hitbox.Size", size)
    if self._enabled then
        self:ApplyHitbox(size)
    end
end

function Features.Hitbox:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()

    for player, origSize in pairs(self._originalSizes) do
        if player and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Size = origSize
                root.Transparency = 1
            end
        end
    end
    self._originalSizes = {}
    Core:Notify("ZIZU", "Hitbox disabled")
end

function Features.Hitbox:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- ANTI FAIL GENE
-- ═════════════════════════════════════════════
Features.AntiFailGene = CreateFeature("AntiFailGene", "AntiFailGene")

function Features.AntiFailGene:Initialize()
    self._skillCheckRemote = nil
end

function Features.AntiFailGene:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local mode = Config:Get("AntiFailGene.Mode") or "NORMAL"
    if mode == "NORMAL" then
        Core:Notify("ZIZU", "Anti Fail Gene: NORMAL (no modification)")
        return
    end

    local remoteNames = Config:Get("RemoteMapping.SkillCheck") or {"SkillCheck", "SkillCheckResult", "GeneratorSkillCheck"}
    self._skillCheckRemote = Core:FindRemote(remoteNames)

    if not self._skillCheckRemote then
        Core:Notify("ZIZU", "Skill check remote not found")
        self._enabled = false
        self:SaveState()
        return
    end

    self:AddConnection(self._skillCheckRemote.OnClientEvent:Connect(function(...)
        if not self._enabled then return end
        local currentMode = Config:Get("AntiFailGene.Mode")
        if currentMode == "PERFECT" or currentMode == "INSTANT" then
            task.wait(currentMode == "INSTANT" and 0.05 or 0.2)
            pcall(function()
                self._skillCheckRemote:FireServer(true)
            end)
            pcall(function()
                self._skillCheckRemote:FireServer("Success")
            end)
            pcall(function()
                self._skillCheckRemote:FireServer({Result = "Perfect"})
            end)
        end
    end))

    Core:Notify("ZIZU", "Anti Fail Gene: " .. mode)
end

function Features.AntiFailGene:SetMode(mode)
    Config:Set("AntiFailGene.Mode", mode)
    if self._enabled then
        self:Disable()
        self:Enable()
    end
end

function Features.AntiFailGene:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    Core:Notify("ZIZU", "Anti Fail Gene disabled")
end

function Features.AntiFailGene:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- SPEED
-- ═════════════════════════════════════════════
Features.Speed = CreateFeature("Speed", "Speed")

function Features.Speed:Initialize()
    self._originalSpeed = nil
end

function Features.Speed:Enable()
    if self._enabled then return end
    self._enabled = true

    local humanoid = Core:GetHumanoid()
    if humanoid then
        self._originalSpeed = humanoid.WalkSpeed
    end

    self:ApplySpeed()

    self:AddConnection(RunService.Heartbeat:Connect(function()
        if not self._enabled then return end
        local h = Core:GetHumanoid()
        if not h then return end

        if Config:Get("Speed.SafeSpeed") then
            local char = Core:GetCharacter()
            if char then
                local knocked = char:GetAttribute("Knocked") or char:GetAttribute("Down") or char:GetAttribute("Incapacitated")
                if knocked then
                    return
                end
            end
        end

        if Config:Get("Speed.AntiSlow") then
            local base = self._originalSpeed or 16
            if h.WalkSpeed < base then
                h.WalkSpeed = base
            end
        end

        if Config:Get("Speed.BoostEnabled") then
            local mult = Config:Get("Speed.BoostMultiplier") or 1
            local base = self._originalSpeed or 16
            h.WalkSpeed = base * mult
        end
    end))
end

function Features.Speed:ApplySpeed()
    local h = Core:GetHumanoid()
    if not h then return end
    if Config:Get("Speed.BoostEnabled") then
        local mult = Config:Get("Speed.BoostMultiplier") or 1
        local base = self._originalSpeed or h.WalkSpeed
        h.WalkSpeed = base * mult
    end
end

function Features.Speed:SetAntiSlow(enabled)
    Config:Set("Speed.AntiSlow", enabled)
end

function Features.Speed:SetBoost(enabled)
    Config:Set("Speed.BoostEnabled", enabled)
    if self._enabled then self:ApplySpeed() end
end

function Features.Speed:SetMultiplier(mult)
    Config:Set("Speed.BoostMultiplier", mult)
    if self._enabled then self:ApplySpeed() end
end

function Features.Speed:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:ClearConnections()
    local h = Core:GetHumanoid()
    if h and self._originalSpeed then
        h.WalkSpeed = self._originalSpeed
    end
    self._originalSpeed = nil
    Core:Notify("ZIZU", "Speed disabled")
end

function Features.Speed:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- BLOCK
-- ═════════════════════════════════════════════
Features.Block = CreateFeature("Block", "Block")

function Features.Block:Initialize()
    self._blockRemote = nil
end

function Features.Block:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local remoteNames = Config:Get("RemoteMapping.Block") or {"Block", "PlayerBlock", "BlockAttack"}
    self._blockRemote = Core:FindRemote(remoteNames)

    if not self._blockRemote then
        local attackNames = Config:Get("RemoteMapping.Attack") or {"Attack", "PlayerAttack", "Hit"}
        local attackRemote = Core:FindRemote(attackNames)
        if attackRemote then
            self:AddConnection(attackRemote.OnClientEvent:Connect(function(...)
                if not self._enabled then return end
                pcall(function()
                    if self._blockRemote then
                        self._blockRemote:FireServer(true)
                    end
                end)
            end))
        end
        Core:Notify("ZIZU", "Block enabled (limited - no block remote found)")
    else
        self:AddConnection(RunService.Heartbeat:Connect(function()
            if not self._enabled then return end
            if tick() % 0.2 < 0.03 then
                pcall(function()
                    self._blockRemote:FireServer(true)
                end)
            end
        end))
        Core:Notify("ZIZU", "Block enabled")
    end
end

function Features.Block:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    if self._blockRemote then
        pcall(function() self._blockRemote:FireServer(false) end)
    end
    Core:Notify("ZIZU", "Block disabled")
end

function Features.Block:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- LUCK
-- ═════════════════════════════════════════════
Features.Luck = CreateFeature("Luck", "Luck")

function Features.Luck:Initialize()
    self._reloadRemote = nil
end

function Features.Luck:Enable()
    if self._enabled then return end
    self._enabled = true
    self:SaveState()

    local char = Core:GetCharacter()
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo") or tool:FindFirstChild("Bullets")
            if ammo and ammo:IsA("IntValue") or (ammo and ammo:IsA("NumberValue")) then
                self._ammoValue = ammo
                self._originalAmmo = ammo.Value
            end

            local ammoAttr = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
            if ammoAttr then
                self._ammoTool = tool
                self._originalAmmoAttr = ammoAttr
            end
        end
    end

    self:AddConnection(RunService.Heartbeat:Connect(function()
        if not self._enabled then return end

        if Config:Get("Luck.InfiniteAmmo") then
            if self._ammoValue and self._ammoValue.Parent then
                if self._ammoValue.Value < (self._originalAmmo or 10) then
                    self._ammoValue.Value = self._originalAmmo or 10
                end
            end
            if self._ammoTool and self._ammoTool.Parent then
                local current = self._ammoTool:GetAttribute("Ammo") or self._ammoTool:GetAttribute("CurrentAmmo")
                if current and current < (self._originalAmmoAttr or 10) then
                    pcall(function() self._ammoTool:SetAttribute("Ammo", self._originalAmmoAttr or 10) end)
                    pcall(function() self._ammoTool:SetAttribute("CurrentAmmo", self._originalAmmoAttr or 10) end)
                end
            end

            local curChar = Core:GetCharacter()
            if curChar then
                local tool = curChar:FindFirstChildWhichIsA("Tool")
                if tool and tool ~= self._ammoTool then
                    local a = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo") or tool:FindFirstChild("Bullets")
                    if a and (a:IsA("IntValue") or a:IsA("NumberValue")) then
                        self._ammoValue = a
                        if not self._originalAmmo then self._originalAmmo = a.Value end
                    end
                    self._ammoTool = tool
                    local attrAmmo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
                    if attrAmmo and not self._originalAmmoAttr then
                        self._originalAmmoAttr = attrAmmo
                    end
                end
            end
        end
    end))

    Core:Notify("ZIZU", "Luck enabled")
end

function Features.Luck:SetInfiniteAmmo(enabled)
    Config:Set("Luck.InfiniteAmmo", enabled)
end

function Features.Luck:SetNoEmptyShot(enabled)
    Config:Set("Luck.NoEmptyShot", enabled)
end

function Features.Luck:Disable()
    if not self._enabled then return end
    self._enabled = false
    self:SaveState()
    self:ClearConnections()
    Core:Notify("ZIZU", "Luck disabled")
end

function Features.Luck:Destroy()
    self:Disable()
end

-- ═════════════════════════════════════════════
-- INITIALIZATION
-- ═════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function Features:InitializeAll()
    local featureList = {
        "ESP", "ESPWorld", "Outline", "WarnKiller", "WorldSettings",
        "DropAll", "NoLoop", "FakeHit", "NoDrop", "Hitbox",
        "AntiFailGene", "Speed", "Block", "Luck",
    }

    for _, name in ipairs(featureList) do
        if self[name] and self[name].Initialize then
            Core:SafeCall(function()
                self[name]:Initialize()
            end)
            Core:RegisterFeature(name, self[name])
        end
    end

    return self
end

function Features:LoadSavedStates()
    local autoEnableFeatures = {
        {name = "ESP", path = "ESP.Enabled"},
        {name = "ESPWorld", path = "ESPWorld.Enabled"},
        {name = "Outline", path = "Outline.Enabled"},
        {name = "WarnKiller", path = "WarnKiller.Enabled"},
        {name = "Hitbox", path = "Hitbox.Enabled"},
        {name = "AntiFailGene", path = "AntiFailGene.Enabled"},
        {name = "NoDrop", path = "NoDrop.Enabled"},
        {name = "NoLoop", path = "NoLoop.Enabled"},
        {name = "Block", path = "Block.Enabled"},
        {name = "Luck", path = "Luck.Enabled"},
    }

    for _, f in ipairs(autoEnableFeatures) do
        if Config:Get(f.path) == true then
            task.spawn(function()
                Core:SafeCall(function()
                    self[f.name]:Enable()
                end)
            end)
        end
    end

    if Config:Get("WorldSettings.BrightWorld") then self.WorldSettings:SetBrightWorld(true) end
    if Config:Get("WorldSettings.NoFog") then self.WorldSettings:SetNoFog(true) end
    if Config:Get("WorldSettings.ClearLighting") then self.WorldSettings:SetClearLighting(true) end
    if Config:Get("WorldSettings.Fullbright") then self.WorldSettings:SetFullbright(true) end

    if Config:Get("Speed.AntiSlow") or Config:Get("Speed.BoostEnabled") then
        self.Speed:Enable()
    end
end

function Features:DestroyAll()
    local featureList = {
        "ESP", "ESPWorld", "Outline", "WarnKiller", "WorldSettings",
        "DropAll", "NoLoop", "FakeHit", "NoDrop", "Hitbox",
        "AntiFailGene", "Speed", "Block", "Luck",
    }
    for _, name in ipairs(featureList) do
        if self[name] and self[name].Destroy then
            Core:SafeCall(function() self[name]:Destroy() end)
        end
    end
end

return Features
