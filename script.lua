--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
	Modified: Fixed Memory System + Added Notifications
	Credits: locality (Further Reach), divo (Multi Color Line)
]]

-- Ожидание полной загрузки игры
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalPlayer = Players.LocalPlayer

-- Проверка поддержки функций файловой системы
local hasFileSystem = (isfile and readfile and writefile)
local MEMORY_FILE = "memory_further_reach.json"
local CachedData = { Enabled = false }

-- Загрузка памяти
if hasFileSystem and isfile(MEMORY_FILE) then
    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(MEMORY_FILE))
    end)
    if success and type(result) == "table" and result.Enabled ~= nil then
        CachedData.Enabled = result.Enabled
    end
end

-- Загрузка уведомлений
local AkaliNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/ultraskidding/luau/refs/heads/main/AkaliNotif.lua"))()
local Notify = AkaliNotif.Notify

-- Уведомление о загрузке
Notify({
    Title = "Namii Hub",
    Description = "Скрипт успешно загружен!",
    Duration = 5
})

-- Ожидание GUI
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MenuGui = PlayerGui:WaitForChild("MenuGui", 15)
if not MenuGui then return end

-- Получаем папки
local GamepassEvents = ReplicatedStorage:WaitForChild("GamepassEvents", 10)
local MenuToys = ReplicatedStorage:WaitForChild("MenuToys", 10)
if not GamepassEvents or not MenuToys then return end

local ReachNotify = GamepassEvents:WaitForChild("FurtherReachBoughtNotifier", 5)
local ColorNotify = GamepassEvents:WaitForChild("MulticolorLineBoughtNotifier", 5)
local Activator = MenuToys:WaitForChild("LimitedTimeToyEvent", 5)
if not ReachNotify or not ColorNotify or not Activator then return end

local Config = {
    Toggle = Enum.KeyCode.Seven,
    Unload = Enum.KeyCode.Eight,
    Working = false
}

local Cooldown = false
local DiedHandle = nil

-- Функция перезагрузки
local function ReloadScript()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("GrabbingScript") then
        LocalPlayer.Character.GrabbingScript.Enabled = false
        LocalPlayer.Character.GrabbingScript.Enabled = true
    end
    if MenuGui:FindFirstChild("Menu") and MenuGui.Menu:FindFirstChild("TabContents") then
        local LineFrame = MenuGui.Menu.TabContents:FindFirstChild("Settings")
        if LineFrame and LineFrame:FindFirstChild("Contents") and LineFrame.Contents:FindFirstChild("LineFrame") then
            local picker = LineFrame.Contents.LineFrame:FindFirstChild("ColorPicking")
            if picker then
                picker.Enabled = false
                picker.Enabled = true
            end
        end
    end
end

-- Основная функция
local function Toggle(notify, fromLoad)
    Config.Working = not Config.Working
    local isEnabled = Config.Working

    if notify then
        Notify({
            Title = "Namii Hub",
            Description = isEnabled and "Namii Tota Tota: ВКЛЮЧЕНО! ✅" or "Namii Tota Tota: ВЫКЛЮЧЕНО! ❌",
            Duration = 5
        })
    end

    if isEnabled then
        local Marker = LocalPlayer:FindFirstChild("FartherReach")
        if Marker then Marker:Destroy() end
        
        local NewMarker = Instance.new("BoolValue")
        NewMarker.Name = "FartherReach"
        NewMarker.Value = true
        NewMarker.Parent = LocalPlayer

        -- 1. Further Reach
        ReachNotify.Parent = ReplicatedFirst
        Activator.Parent = GamepassEvents
        Activator.Name = "FurtherReachBoughtNotifier"
        ReloadScript()
        task.delay(0.1, function() if Activator then Activator:FireServer() end end)
        task.wait(0.2)

        -- 2. Multicolor Line
        ColorNotify.Parent = ReplicatedFirst
        Activator.Parent = GamepassEvents
        Activator.Name = "MulticolorLineBoughtNotifier"
        ReloadScript()
        task.delay(0.1, function() if Activator then Activator:FireServer() end end)

        if DiedHandle then DiedHandle:Disconnect() end
        DiedHandle = LocalPlayer.CharacterAdded:Connect(function(Character)
            Character:WaitForChild("GrabbingScript", 5)
            if Config.Working then
                Toggle(false); task.wait(0.1)
                Toggle(false)
            end
        end)
    else
        local Marker = LocalPlayer:FindFirstChild("FartherReach")
        if Marker then Marker:Destroy() end

        ReachNotify.Parent = GamepassEvents
        ColorNotify.Parent = GamepassEvents
        Activator.Name = "LimitedTimeToyEvent"
        Activator.Parent = MenuToys
        ReloadScript()
        
        if DiedHandle then
            DiedHandle:Disconnect()
            DiedHandle = nil
        end
    end

    -- СОХРАНЕНИЕ В ПАМЯТЬ
    if not fromLoad and hasFileSystem then
        CachedData.Enabled = isEnabled
        pcall(function()
            writefile(MEMORY_FILE, game:GetService("HttpService"):JSONEncode(CachedData))
        end)
    end
end

-- АВТО-АКТИВАЦИЯ ПРИ ВХОДЕ В ИГРУ
if CachedData.Enabled then
    Notify({
        Title = "Namii Hub",
        Description = "Namii Tota Tota: Загружаю память... ⏳",
        Duration = 4
    })
    task.wait(2)
    Toggle(false, true) 
    Notify({
        Title = "Namii Hub",
        Description = "Namii Tota Tota: Память применена! 🧠",
        Duration = 5
    })
else
    Notify({
        Title = "Namii Hub",
        Description = "Namii Tota Tota: Нажми 7 для активации! 🎮",
        Duration = 5
    })
end

-- Привязка клавиш
local BindHandle = UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Config.Toggle then
        if Cooldown then return end
        Cooldown = true
        Toggle(true)
        task.delay(0.2, function() Cooldown = false end)

    elseif input.KeyCode == Config.Unload then
        Notify({Title = "Namii Hub", Description = "Namii Tota Tota: Выгружаю скрипт... 👋", Duration = 5})
        if Config.Working then Toggle(false) end
        BindHandle:Disconnect()
    end
end)
