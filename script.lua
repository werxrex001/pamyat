if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalPlayer = Players.LocalPlayer

-- Загрузка уведомлений
local AkaliNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/ultraskidding/luau/refs/heads/main/AkaliNotif.lua"))()
local Notify = AkaliNotif.Notify

-- Ожидание GUI (с защитой от краша)
local MenuGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui", 10)
if not MenuGui then return end
MenuGui:WaitForChild("TopRight"):WaitForChild("CoinsFrame"):WaitForChild("CoinsDisplay"):WaitForChild("Coins")

-- Настройки
local Config = {
    Toggle = Enum.KeyCode.Seven,
    Unload = Enum.KeyCode.Eight,
    Working = false
}

local Cooldown = false
local DiedHandle = nil
local MEMORY_FILE = "further_reach_memory.txt"
local COLOR_FILE = "further_reach_color.txt"

-- Получаем папки с ивентами
local GamepassEvents = ReplicatedStorage:WaitForChild("GamepassEvents", 5)
local MenuToys = ReplicatedStorage:WaitForChild("MenuToys", 5)

if not GamepassEvents or not MenuToys then
    Notify({Title = "Ошибка", Description = "Не найдены папки GamepassEvents или MenuToys", Duration = 5})
    return
end

-- Ивенты для обоих геймпассов
local ReachNotify = GamepassEvents:WaitForChild("FurtherReachBoughtNotifier", 5)
local ColorNotify = GamepassEvents:WaitForChild("MulticolorLineBoughtNotifier", 5)
local Activator = MenuToys:WaitForChild("LimitedTimeToyEvent", 5)

if not ReachNotify or not ColorNotify or not Activator then
    Notify({Title = "Ошибка", Description = "Игра обновилась. Ивенты не найдены.", Duration = 5})
    return
end

-- Перезагрузка GUI для применения изменений
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

-- Включение / Выключение
local function Toggle(notify, fromLoad)
    Config.Working = not Config.Working
    local isEnabled = Config.Working

    if notify then
        Notify({
            Title = "Memory Script",
            Description = isEnabled and "Геймпассы активированы!" or "Выключено.",
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

        -- 1. Активация Further Reach
        ReachNotify.Parent = ReplicatedFirst
        Activator.Parent = GamepassEvents
        Activator.Name = "FurtherReachBoughtNotifier"
        ReloadScript()
        
        task.delay(0.1, function()
            if Activator then Activator:FireServer() end
        end)
        
        task.wait(0.2)

        -- 2. Активация Multicolor Line (Твой цвет)
        ColorNotify.Parent = ReplicatedFirst
        Activator.Parent = GamepassEvents
        Activator.Name = "MulticolorLineBoughtNotifier"
        ReloadScript()
        
        task.delay(0.1, function()
            if Activator then Activator:FireServer() end
        end)

        -- Обработка смерти
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

    if not fromLoad and writefile then
        writefile(MEMORY_FILE, tostring(isEnabled))
    end
end

-- Восстановление памяти
local shouldEnable = false
if isfile and readfile and isfile(MEMORY_FILE) then
    local success, data = pcall(function() return readfile(MEMORY_FILE) end)
    if success and data == "true" then shouldEnable = true end
end

if shouldEnable then
    Toggle(false, true) 
else
    print("[Memory Script] Загружен. Кнопка 7 - ВКЛ, 8 - Выгрузить.")
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
        Notify({Title = "Memory Script", Description = "Выгрузка...", Duration = 5})
        if Config.Working then Toggle(false) end
        BindHandle:Disconnect()
    end
end)
