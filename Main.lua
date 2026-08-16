--[[
    ══════════════════════════════════════════
         ZIZU 月
         A modern Roblox client framework
         Created by zizu
         Version 1.0.0
    ══════════════════════════════════════════
    
    ENTRY POINT — Main.lua
    User only executes this file.
    All other modules are loaded automatically.
]]

-- ═══════════════════════════════════
-- BASE CONFIGURATION
-- ═══════════════════════════════════

local BASE_URL = "https://raw.githubusercontent.com/zizuusynasy/zizyus/main/"

local MODULE_FILES = {
    Core     = "Core.lua",
    Config   = "Config.lua",
    Features = "Features.lua",
    UI       = "UI.lua",
}

-- ═══════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════

local Players        = game:GetService("Players")
local HttpService    = game:GetService("HttpService")
local LocalPlayer    = Players.LocalPlayer

-- ═══════════════════════════════════
-- CLEANUP PREVIOUS INSTANCE
-- ═══════════════════════════════════

if LocalPlayer then
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local old = pg:FindFirstChild("ZIZU_Framework")
            if old then old:Destroy() end
        end
    end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        local old = cg:FindFirstChild("ZIZU_Framework")
        if old then old:Destroy() end
    end)
end

-- ═══════════════════════════════════
-- MODULE LOADER
-- ═══════════════════════════════════

local LoadedModules = {}

local function LoadModule(name, fileName)
    if LoadedModules[name] then
        return LoadedModules[name]
    end

    local url = BASE_URL .. fileName

    local success, result = pcall(function()
        local source = game:HttpGet(url, true)
        if not source or source == "" then
            error("Empty response from: " .. url)
        end
        local fn, err = loadstring(source)
        if not fn then
            error("Loadstring failed: " .. tostring(err))
        end
        return fn()
    end)

    if success and result then
        LoadedModules[name] = result
        print("[ZIZU] Loaded: " .. name)
        return result
    end

    warn("[ZIZU] Failed to load module [" .. name .. "]: " .. tostring(result))
    return nil
end

-- ═══════════════════════════════════
-- VALIDATION
-- ═══════════════════════════════════

local function ValidateEnvironment()
    if not LocalPlayer then
        warn("[ZIZU] LocalPlayer not found.")
        return false
    end
    if not LocalPlayer:FindFirstChild("PlayerGui") then
        warn("[ZIZU] PlayerGui not found.")
        return false
    end
    return true
end

-- ═══════════════════════════════════
-- BOOT SEQUENCE
-- ═══════════════════════════════════

local function Boot()
    print("══════════════════════════════════")
    print("  ZIZU 月  |  Created by zizu    ")
    print("  Version 1.0.0  |  BETA          ")
    print("══════════════════════════════════")

    -- Environment check
    if not ValidateEnvironment() then
        warn("[ZIZU] Environment validation failed. Aborting.")
        return nil
    end

    -- ── Step 1: Load Core ──────────────
    local Core = LoadModule("Core", MODULE_FILES.Core)
    if not Core then
        warn("[ZIZU] FATAL: Core failed to load.")
        return nil
    end

    -- ── Step 2: Load Config ────────────
    local Config = LoadModule("Config", MODULE_FILES.Config)
    if not Config then
        warn("[ZIZU] FATAL: Config failed to load.")
        return nil
    end

    -- ── Step 3: Load Features ──────────
    local Features = LoadModule("Features", MODULE_FILES.Features)
    if not Features then
        warn("[ZIZU] FATAL: Features failed to load.")
        return nil
    end

    -- ── Step 4: Load UI ────────────────
    local UI = LoadModule("UI", MODULE_FILES.UI)
    if not UI then
        warn("[ZIZU] FATAL: UI failed to load.")
        return nil
    end

    -- ── Step 5: Init UI & ScreenGui ────
    UI:Init(Core, Config, Features)
    UI:CreateScreenGui()

    -- ── Step 6: Loading Screen ─────────
    -- Real initialization happens inside loading screen callbacks
    UI:ShowLoadingScreen(function(step, label)

        if step == 1 then
            -- CORE
            Core:Initialize()
            print("[ZIZU] Core initialized.")
            return true

        elseif step == 2 then
            -- CONFIG
            Config:Initialize()
            print("[ZIZU] Config initialized.")
            return true

        elseif step == 3 then
            -- FEATURES
            Features:Init(Core, Config)
            Features:InitializeAll()
            print("[ZIZU] Features initialized.")
            return true

        elseif step == 4 then
            -- INTERFACE
            UI:CreateMainGUI()
            UI:CreateFloatingIcon()
            print("[ZIZU] Interface built.")
            return true

        elseif step == 5 then
            -- READY
            Features:LoadSavedStates()
            print("[ZIZU] Saved states loaded.")
            return true
        end

    end)

    -- ── Step 7: Cleanup Hooks ──────────
    Core:AddCleanup(function()
        pcall(function() Features:DestroyAll() end)
        pcall(function() UI:Destroy() end)
        pcall(function() Core:SetBlur(false) end)
        pcall(function() Core:RestoreLighting() end)
        print("[ZIZU] Cleanup complete.")
    end)

    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            Config:Save()
            Core:RunCleanup()
        end
    end)

    game:BindToClose(function()
        pcall(function() Config:Save() end)
        pcall(function() Core:RunCleanup() end)
    end)

    -- ── Done ───────────────────────────
    print("[ZIZU] Framework running on platform: " .. (Core.State.Platform or "UNKNOWN"))
    print("══════════════════════════════════")

    return {
        Core     = Core,
        Config   = Config,
        Features = Features,
        UI       = UI,
    }
end

-- ═══════════════════════════════════
-- EXECUTE
-- ═══════════════════════════════════

local ok, err = pcall(Boot)

if not ok then
    warn("[ZIZU] FATAL BOOT ERROR: " .. tostring(err))
end
