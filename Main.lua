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
-- CONFIGURATION
-- ═══════════════════════════════════

-- Base URL for loading modules via Delta executor loadstring
-- Change this to your own hosting if needed
local BASE_URL = "https://raw.githubusercontent.com/zizu-dev/ZIZU/main/"

-- Module file names
local MODULE_FILES = {
    Core = "Core.lua",
    Config = "Config.lua",
    Features = "Features.lua",
    UI = "UI.lua",
}

-- ═══════════════════════════════════
-- ENVIRONMENT VALIDATION
-- ═══════════════════════════════════
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[ZIZU] LocalPlayer not found. Aborting.")
    return
end

-- Cleanup previous instance if exists
if LocalPlayer:FindFirstChild("PlayerGui") then
    local existing = LocalPlayer.PlayerGui:FindFirstChild("ZIZU_Framework")
    if existing then
        existing:Destroy()
    end
end

-- Also check CoreGui
pcall(function()
    local coreGui = game:GetService("CoreGui")
    local existing = coreGui:FindFirstChild("ZIZU_Framework")
    if existing then existing:Destroy() end
end)

-- ═══════════════════════════════════
-- MODULE LOADER
-- ═══════════════════════════════════
local function LoadModule(name, fileName)
    -- Try loading from URL (for Delta executor / loadstring)
    local success, result = pcall(function()
        local url = BASE_URL .. fileName
        return loadstring(game:HttpGet(url))()
    end)

    if success and result then
        return result
    end

    -- Fallback: try loading from game's ReplicatedStorage or ServerScriptService
    local fallbackLocations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
    }

    for _, location in ipairs(fallbackLocations) do
        local module = location:FindFirstChild(name) or location:FindFirstChild(fileName:gsub(".lua", ""))
        if module and module:IsA("ModuleScript") then
            local s, r = pcall(require, module)
            if s then return r end
        end
    end

    warn("[ZIZU] Failed to load module:", name, "—", result)
    return nil
end

-- ═══════════════════════════════════
-- BOOT SEQUENCE
-- ═══════════════════════════════════
local function Boot()
    print("[ZIZU] Starting ZIZU framework...")
    print("[ZIZU] Created by zizu")
    print("[ZIZU] Version 1.0.0")

    -- ─── STEP 1: Load Core ───
    local Core = LoadModule("Core", MODULE_FILES.Core)
    if not Core then
        warn("[ZIZU] FATAL: Core module failed to load.")
        return
    end

    -- ─── STEP 2: Load Config ───
    local Config = LoadModule("Config", MODULE_FILES.Config)
    if not Config then
        warn("[ZIZU] FATAL: Config module failed to load.")
        return
    end

    -- ─── STEP 3: Load Features ───
    local Features = LoadModule("Features", MODULE_FILES.Features)
    if not Features then
        warn("[ZIZU] FATAL: Features module failed to load.")
        return
    end

    -- ─── STEP 4: Load UI ───
    local UI = LoadModule("UI", MODULE_FILES.UI)
    if not UI then
        warn("[ZIZU] FATAL: UI module failed to load.")
        return
    end

    -- ─── STEP 5: Environment Validation ───
    if not Core:ValidateEnvironment() then
        warn("[ZIZU] Environment validation failed.")
        return
    end

    -- ─── STEP 6: Create ScreenGui (needed for loading screen) ───
    UI:Init(Core, Config, Features)
    UI:CreateScreenGui()

    -- ─── STEP 7: Show Loading Screen with real initialization ───
    UI:ShowLoadingScreen(function(step, label)
        if step == 1 then
            -- CORE initialization
            Core:Initialize()
            print("[ZIZU] Core initialized")
            return true

        elseif step == 2 then
            -- CONFIG initialization
            Config:Initialize()
            print("[ZIZU] Config initialized")
            return true

        elseif step == 3 then
            -- FEATURES initialization
            Features:Init(Core, Config)
            Features:InitializeAll()
            print("[ZIZU] Features initialized")
            return true

        elseif step == 4 then
            -- UI build (main GUI)
            UI:CreateMainGUI()
            UI:CreateFloatingIcon()
            print("[ZIZU] UI built")
            return true

        elseif step == 5 then
            -- Load saved feature states
            Features:LoadSavedStates()
            print("[ZIZU] Saved states loaded — READY")
            return true
        end
    end)

    -- ─── STEP 8: Framework is now running ───
    print("[ZIZU] ══════════════════════════════")
    print("[ZIZU] ZIZU framework is now running.")
    print("[ZIZU] Platform: " .. Core.State.Platform)
    print("[ZIZU] ══════════════════════════════")

    -- ─── STEP 9: Register cleanup on player leaving ───
    Core:AddCleanup(function()
        Features:DestroyAll()
        UI:Destroy()
        Core:SetBlur(false)
        Core:RestoreLighting()
        print("[ZIZU] Cleanup complete.")
    end)

    -- Cleanup if player leaves
    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            Core:RunCleanup()
        end
    end)

    -- Cleanup on BindToClose (studio)
    game:BindToClose(function()
        Config:Save()
        Core:RunCleanup()
    end)

    -- ─── STEP 10: Return references for external access if needed ───
    return {
        Core = Core,
        Config = Config,
        Features = Features,
        UI = UI,
    }
end

-- ═══════════════════════════════════
-- EXECUTE
-- ═══════════════════════════════════
local success, result = pcall(Boot)

if not success then
    warn("[ZIZU] FATAL BOOT ERROR:", result)
end

return result
