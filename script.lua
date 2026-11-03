--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
	Modified: Fixed Memory, Added Roblox Notifications
	Credits: locality (Further Reach), divo (Multi Color Line)
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Функция обычной роблоксовской нотификации
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- Проверка поддержки файловой системы
local hasFileSystem = (isfile and readfile and writefile)
local MEMORY_FILE = "memory_further_reach.json"
local CachedData = { Enabled = false }

-- Загрузка памяти
if hasFileSystem and isfile(MEMORY_FILE) then
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(MEMORY_FILE))
    end)
    if success and type(result) == "table" and result.Enabled ~= nil then
        CachedData.Enabled = result.Enabled
    end
end

-- Ожидание GUI игры
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MenuGui = PlayerGui:WaitForChild("MenuGui", 15)
if not MenuGui then return end

-- Получаем папки и ивенты
local GamepassEvents = ReplicatedStorage:WaitForChild("GamepassEvents", 10)
local MenuToys = ReplicatedStorage:WaitForChild("MenuToys", 10)
if not GamepassEvents or not MenuToys then return end

local ReachNotify = GamepassEvents:WaitForChild("FurtherReachBoughtNotifier", 5)
local ColorNotify = GamepassEvents:WaitForChild("MulticolorLineBoughtNotifier", 5)
local Activator = MenuToys:WaitForChild("LimitedTimeToyEvent", 5)

if not ReachNotify or not ColorNotify or not Activator then
    Notify("Namii Hub", "Ошибка: Игра обновилась, ивенты не найдены.", 5)
    return
end

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
        Notify("Namii Hub", isEnabled and "Namii Tota Tota: ВКЛЮЧЕНО! ✅" or "Namii Tota Tota: ВЫКЛЮЧЕНО! ❌", 3)
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

    -- Сохранение в память
    if not fromLoad and hasFileSystem then
        CachedData.Enabled = isEnabled
        pcall(function()
            writefile(MEMORY_FILE, HttpService:JSONEncode(CachedData))
        end)
    end
end

-- Авто-активация при входе
if CachedData.Enabled then
    Notify("Namii Hub", "Namii Tota Tota: Загружаю память... ⏳", 3)
    task.wait(2.5) -- Ждем, чтобы игра точно загрузилась
    Toggle(false, true) 
    Notify("Namii Hub", "Namii Tota Tota: Память применена! 🧠", 3)
else
    Notify("Namii Hub", "Namii Tota Tota: Нажми 7 для активации! 🎮", 3)
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
        Notify("Namii Hub", "Namii Tota Tota: Выгружаю... 👋", 3)
        if Config.Working then Toggle(false) end
        BindHandle:Disconnect()
    end
end)
