--[[
    ZIZU 月 — Config.lua
    Single source of truth for all configuration.
    Created by zizu
]]

local HttpService = game:GetService("HttpService")

local Config = {}

Config._saveKey = "ZIZU_CONFIG_V1"
Config._dirty = false
Config._lastSave = 0
Config._debounceTime = 2

Config.Default = {
    Version = "1.0.0",
    Status = "BETA",

    IconPosition = {X = 50, Y = 50},
    UIOpen = false,
    ActiveTab = "HOME",
    AutoSave = true,

    ESP = {
        Enabled = false,
        Survivor = true,
        Killer = true,
        ShowName = true,
        ShowDistance = true,
        SurvivorColor = {R = 0, G = 170, B = 255},
        KillerColor = {R = 255, G = 60, B = 60},
    },

    ESPWorld = {
        Enabled = false,
        Pallet = false,
        Generator = false,
        Hook = false,
        Gate = false,
        Window = false,
        ShowLabel = true,
        ShowDistance = true,
        Colors = {
            Pallet = {R = 200, G = 150, B = 50},
            Generator = {R = 255, G = 220, B = 0},
            Hook = {R = 255, G = 80, B = 80},
            Gate = {R = 100, G = 200, B = 100},
            Window = {R = 150, G = 150, B = 255},
        },
    },

    Outline = {
        Enabled = false,
    },

    WarnKiller = {
        Enabled = false,
        Level1Distance = 60,
        Level2Distance = 35,
        Level3Distance = 15,
    },

    WorldSettings = {
        BrightWorld = false,
        NoFog = false,
        ClearLighting = false,
        Fullbright = false,
    },

    DropAll = {
        Enabled = false,
    },

    NoLoop = {
        Enabled = false,
    },

    FakeHit = {
        Enabled = false,
    },

    NoDrop = {
        Enabled = false,
    },

    Hitbox = {
        Enabled = false,
        Size = 1,
    },

    AntiFailGene = {
        Enabled = false,
        Mode = "NORMAL",
    },

    Speed = {
        AntiSlow = false,
        BoostEnabled = false,
        BoostMultiplier = 1.0,
        SafeSpeed = true,
    },

    Block = {
        Enabled = false,
    },

    Luck = {
        Enabled = false,
        InfiniteAmmo = false,
        NoEmptyShot = false,
    },

    ObjectMapping = {
        Pallet = {
            Tags = {"Pallet", "ZIZU_Pallet", "pallet"},
            Names = {"Pallet", "pallet", "WoodPallet", "DropPallet"},
            Attributes = {"IsPallet"},
        },
        Generator = {
            Tags = {"Generator", "ZIZU_Generator", "generator", "Gen"},
            Names = {"Generator", "generator", "Gen"},
            Attributes = {"IsGenerator", "GeneratorProgress"},
        },
        Hook = {
            Tags = {"Hook", "ZIZU_Hook", "hook"},
            Names = {"Hook", "hook", "MeatHook", "SacrificeHook"},
            Attributes = {"IsHook"},
        },
        Gate = {
            Tags = {"Gate", "ZIZU_Gate", "gate", "ExitGate"},
            Names = {"Gate", "gate", "ExitGate", "Exit"},
            Attributes = {"IsGate", "GateState"},
        },
        Window = {
            Tags = {"Window", "ZIZU_Window", "window", "Vault"},
            Names = {"Window", "window", "Vault", "vault", "WindowVault"},
            Attributes = {"IsWindow"},
        },
    },

    RemoteMapping = {
        DropPallet = {"DropPallet", "PalletDrop", "UsePallet"},
        Interact = {"Interact", "PlayerInteract", "UseObject"},
        SkillCheck = {"SkillCheck", "SkillCheckResult", "GeneratorSkillCheck"},
        Attack = {"Attack", "PlayerAttack", "Hit", "Swing"},
        Reload = {"Reload", "PlayerReload", "Ammo"},
        Block = {"Block", "PlayerBlock", "BlockAttack"},
    },
}

Config.Current = nil

function Config:DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Config:DeepMerge(base, override)
    local result = self:DeepCopy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = self:DeepMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function Config:Initialize()
    self.Current = self:DeepCopy(self.Default)
    self:Load()
    return self
end

function Config:Get(path)
    local parts = string.split(path, ".")
    local current = self.Current
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

function Config:Set(path, value)
    local parts = string.split(path, ".")
    local current = self.Current
    for i = 1, #parts - 1 do
        if type(current[parts[i]]) ~= "table" then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end
    current[parts[#parts]] = value
    self._dirty = true

    if self.Current.AutoSave then
        self:DebouncedSave()
    end
end

function Config:DebouncedSave()
    local now = tick()
    if now - self._lastSave < self._debounceTime then
        task.delay(self._debounceTime, function()
            if self._dirty then
                self:Save()
            end
        end)
        return
    end
    self:Save()
end

function Config:Save()
    local success, err = pcall(function()
        local data = HttpService:JSONEncode(self.Current)
        if writefile then
            writefile("ZIZU_Config.json", data)
        end
    end)
    if success then
        self._dirty = false
        self._lastSave = tick()
    else
        warn("[ZIZU Config] Save failed:", err)
    end
end

function Config:Load()
    local success, result = pcall(function()
        if isfile and isfile("ZIZU_Config.json") then
            local data = readfile("ZIZU_Config.json")
            local decoded = HttpService:JSONDecode(data)
            self.Current = self:DeepMerge(self.Default, decoded)
            return true
        end
        return false
    end)
    if not success then
        warn("[ZIZU Config] Load failed:", result)
        self.Current = self:DeepCopy(self.Default)
    end
end

function Config:Reset()
    self.Current = self:DeepCopy(self.Default)
    self._dirty = true
    self:Save()
end

function Config:GetColor3(colorTable)
    if type(colorTable) == "table" then
        return Color3.fromRGB(colorTable.R or 255, colorTable.G or 255, colorTable.B or 255)
    end
    return Color3.fromRGB(255, 255, 255)
end

function Config:SetColor3(path, color3)
    self:Set(path, {R = math.floor(color3.R * 255), G = math.floor(color3.G * 255), B = math.floor(color3.B * 255)})
end

return Config
