--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
	Modified: Fixed Line Disappearing + Auto-Save Memory
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
end

local MEMORY_FILE = "reach_memory.txt"
local hasFS = (isfile and readfile and writefile)
local shouldEnable = false

if hasFS then
    pcall(function()
        if isfile(MEMORY_FILE) then
            local data = readfile(MEMORY_FILE)
            if data == "true" then shouldEnable = true end
        end
    end)
end

local MenuGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui", 15)
if not MenuGui then return end

local GamepassEvents = ReplicatedStorage:WaitForChild("GamepassEvents", 10)
local MenuToys = ReplicatedStorage:WaitForChild("MenuToys", 10)
if not GamepassEvents or not MenuToys then return end

local ReachNotify = GamepassEvents:FindFirstChild("FurtherReachBoughtNotifier")
local ColorNotify = GamepassEvents:FindFirstChild("MulticolorLineBoughtNotifier")
local Activator = MenuToys:FindFirstChild("LimitedTimeToyEvent")

if not ReachNotify or not ColorNotify or not Activator then
    Notify("Namii Hub", "Ошибка: Ивенты не найдены")
    return
end

local Config = { Toggle = Enum.KeyCode.Seven, Unload = Enum.KeyCode.Eight, Working = false }
local Cooldown = false
local DiedHandle = nil
local LineLoopThread = nil -- Поток для удержания линии

local function ReloadScript()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("GrabbingScript") then
        LocalPlayer.Character.GrabbingScript.Enabled = false
        LocalPlayer.Character.GrabbingScript.Enabled = true
    end
    if MenuGui:FindFirstChild("Menu") and MenuGui.Menu:FindFirstChild("TabContents") then
        local LineFrame = MenuGui.Menu.TabContents:FindFirstChild("Settings")
        if LineFrame and LineFrame:FindFirstChild("Contents") and LineFrame.Contents:FindFirstChild("LineFrame") then
            local picker = LineFrame.Contents.LineFrame:FindFirstChild("ColorPicking")
            if picker then picker.Enabled = false; picker.Enabled = true end
        end
    end
end

-- Функция активации линии
local function ActivateLine()
    ColorNotify.Parent = ReplicatedFirst
    Activator.Parent = GamepassEvents
    Activator.Name = "MulticolorLineBoughtNotifier"
    ReloadScript()
    task.wait(0.1)
    if Activator then Activator:FireServer() end
end

local function Toggle(notify, fromLoad)
    Config.Working = not Config.Working
    local isEnabled = Config.Working

    if notify then
        Notify("Namii Hub", isEnabled and "Namii Tota Tota: ВКЛ ✅" or "Namii Tota Tota: ВЫКЛ ❌")
    end

    if isEnabled then
        local Marker = LocalPlayer:FindFirstChild("FartherReach")
        if Marker then Marker:Destroy() end
        local NewMarker = Instance.new("BoolValue"); NewMarker.Name = "FartherReach"; NewMarker.Value = true; NewMarker.Parent = LocalPlayer

        -- 1. Further Reach
        ReachNotify.Parent = ReplicatedFirst
        Activator.Parent = GamepassEvents
        Activator.Name = "FurtherReachBoughtNotifier"
        ReloadScript()
        task.wait(0.2)
        if Activator then Activator:FireServer() end
        task.wait(0.5)

        -- 2. Multicolor Line
        ActivateLine()

        -- ЦИКЛ УДЕРЖАНИЯ ЛИНИИ (чтобы не пропадала)
        if LineLoopThread then task.cancel(LineLoopThread) end
        LineLoopThread = task.spawn(function()
            while Config.Working do
                task.wait(1.5) -- Каждые 1.5 секунды проверяем/обновляем линию
                if Config.Working then
                    pcall(function()
                        ActivateLine()
                    end)
                end
            end
        end)

        if DiedHandle then DiedHandle:Disconnect() end
        DiedHandle = LocalPlayer.CharacterAdded:Connect(function(Character)
            Character:WaitForChild("GrabbingScript", 5)
            if Config.Working then 
                Toggle(false); task.wait(0.1); Toggle(false) 
            end
        end)
    else
        if LineLoopThread then task.cancel(LineLoopThread); LineLoopThread = nil end
        
        local Marker = LocalPlayer:FindFirstChild("FartherReach")
        if Marker then Marker:Destroy() end
        ReachNotify.Parent = GamepassEvents
        ColorNotify.Parent = GamepassEvents
        Activator.Name = "LimitedTimeToyEvent"
        Activator.Parent = MenuToys
        ReloadScript()
        if DiedHandle then DiedHandle:Disconnect(); DiedHandle = nil end
    end
end

-- АВТО-СОХРАНЕНИЕ КАЖДУЮ СЕКУНДУ
if hasFS then
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                writefile(MEMORY_FILE, tostring(Config.Working))
            end)
        end
    end)
end

if shouldEnable then
    Notify("Namii Hub", "Память найдена! Жду загрузку...")
    task.wait(4)
    Toggle(false, true)
    Notify("Namii Hub", "Память применена! 🧠")
else
    Notify("Namii Hub", "Нажми 7 для активации")
end

local BindHandle = UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.Toggle then
        if Cooldown then return end
        Cooldown = true; Toggle(true)
        task.delay(0.2, function() Cooldown = false end)
    elseif input.KeyCode == Config.Unload then
        Notify("Namii Hub", "Выгрузка... 👋")
        if Config.Working then Toggle(false) end
        BindHandle:Disconnect()
    end
end)
