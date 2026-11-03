if not game:IsLoaded() then game.Loaded:Wait() end

game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("MenuGui"):WaitForChild("TopRight"):WaitForChild("CoinsFrame"):WaitForChild("CoinsDisplay"):WaitForChild("Coins")

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalPlayer = Players.LocalPlayer

local AkaliNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/ultraskidding/luau/refs/heads/main/AkaliNotif.lua"))();
local Notify = AkaliNotif.Notify;

local Config = {
    Toggle = Enum.KeyCode.Seven,
    Unload = Enum.KeyCode.Eight,
    Working = false
}

local Cooldown = false
local DiedHandle = nil

-- Файлы памяти для двух геймпасов
local MEMORY_FILE_1 = "further_reach_memory.txt"
local MEMORY_FILE_2 = "second_gamepass_memory.txt"
local COLOR_FILE = "further_reach_color.txt"

-- Безопасное получение объектов
local GamepassEvents = ReplicatedStorage:WaitForChild("GamepassEvents", 5)
if not GamepassEvents then
    Notify({Title = "Ошибка", Description = "Не найден GamepassEvents!", Duration = 5})
    return
end

-- Ивенты для двух геймпасов
local ScriptNotify1 = GamepassEvents:FindFirstChild("FurtherReachBoughtNotifier")
local ScriptNotify2 = GamepassEvents:FindFirstChild("SecondGamepassBoughtNotifier") -- Измени имя на реальное

if not ScriptNotify1 then
    Notify({Title = "Ошибка", Description = "Игра обновилась. FurtherReachBoughtNotifier не найден.", Duration = 5})
    return
end

-- Если второго ивента нет в GamepassEvents, создадим его (или найди правильное имя)
if not ScriptNotify2 then
    ScriptNotify2 = Instance.new("RemoteEvent")
    ScriptNotify2.Name = "SecondGamepassBoughtNotifier"
    ScriptNotify2.Parent = GamepassEvents
end

local Activator = ReplicatedStorage.MenuToys.LimitedTimeToyEvent

-- Функция перезагрузки
local function ReloadScript()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("GrabbingScript") then
        LocalPlayer.Character.GrabbingScript.Enabled = false
        LocalPlayer.Character.GrabbingScript.Enabled = true
    end
    if LocalPlayer.PlayerGui:FindFirstChild("MenuGui") and LocalPlayer.PlayerGui.MenuGui:FindFirstChild("Menu") then
        local LineFrame = LocalPlayer.PlayerGui.MenuGui.Menu.TabContents.Settings.Contents.LineFrame.ColorPicking
        LineFrame.Enabled = false
        LineFrame.Enabled = true
    end
end

-- Функция сохранения цвета
local function SaveColor()
    local MenuGui = LocalPlayer.PlayerGui:FindFirstChild("MenuGui")
    if MenuGui and MenuGui.Menu.TabContents.Settings.Contents.LineFrame then
        local ColorPicker = MenuGui.Menu.TabContents.Settings.Contents.LineFrame.ColorPicking
        if ColorPicker:FindFirstChildWhichIsA("Color3Value") then
            local currentColor = ColorPicker.Color3Value.Value
            if writefile then
                writefile(COLOR_FILE, tostring(currentColor.R) .. "," .. tostring(currentColor.G) .. "," .. tostring(currentColor.B))
                print("Цвет сохранен в память!")
            end
        end
    end
end

-- Функция активации для конкретного геймпаса
local function ActivateGamepass(gamepassNumber, notify)
    local markerName = gamepassNumber == 1 and "FartherReach" or "SecondGamepass"
    local scriptNotify = gamepassNumber == 1 and ScriptNotify1 or ScriptNotify2
    
    -- Удаляем старый маркер
    local LineTexture = LocalPlayer:FindFirstChild(markerName)
    if LineTexture then LineTexture:Destroy() end
    
    -- Создаем новый маркер
    local Marker = Instance.new("BoolValue")
    Marker.Name = markerName
    Marker.Value = true
    Marker.Parent = LocalPlayer
    
    -- Перемещаем ивент
    scriptNotify.Parent = ReplicatedFirst
    Activator.Parent = ReplicatedStorage.GamepassEvents
    Activator.Name = scriptNotify.Name
    
    ReloadScript()
    
    -- Восстановление цвета
    if isfile and readfile and isfile(COLOR_FILE) then
        local success, data = pcall(function() return readfile(COLOR_FILE) end)
        if success and data then
            local r, g, b = data:match("([^,]+),([^,]+),([^,]+)")
            if r and g and b then
                local savedColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                print("Восстановлен цвет из памяти: ", savedColor)
            end
        end
    end
    
    task.delay(0.1, function()
        if Activator then Activator:FireServer() end
    end)
    
    if DiedHandle then DiedHandle:Disconnect() end
    DiedHandle = LocalPlayer.CharacterAdded:Connect(function(Character)
        Character:WaitForChild("GrabbingScript")
        if Config.Working then
            Toggle(false); task.wait(0.1)
            Toggle(false)
        end
    end)
    
    if notify then
        Notify({
            Title = gamepassNumber == 1 and "Further Reach" or "Second Gamepass",
            Description = "Activated!",
            Duration = 5
        })
    end
end

-- Функция деактивации
local function DeactivateGamepass(gamepassNumber, notify)
    local markerName = gamepassNumber == 1 and "FartherReach" or "SecondGamepass"
    local LineTexture = LocalPlayer:FindFirstChild(markerName)
    if LineTexture then LineTexture:Destroy() end
    
    -- Возвращаем ивенты на место
    ScriptNotify1.Parent = ReplicatedStorage.GamepassEvents
    ScriptNotify2.Parent = ReplicatedStorage.GamepassEvents
    Activator.Name = "LimitedTimeToyEvent"
    Activator.Parent = ReplicatedStorage.MenuToys
    
    ReloadScript()
    
    if DiedHandle then
        DiedHandle:Disconnect()
        DiedHandle = nil
    end
    
    if notify then
        Notify({
            Title = gamepassNumber == 1 and "Further Reach" or "Second Gamepass",
            Description = "Disabled!",
            Duration = 5
        })
    end
end

-- Основная функция переключения
local function Toggle(gamepassNumber, notify, fromLoad)
    local memoryFile = gamepassNumber == 1 and MEMORY_FILE_1 or MEMORY_FILE_2
    
    -- Читаем текущее состояние из памяти
    local isEnabled = false
    if isfile and readfile and isfile(memoryFile) then
        local success, data = pcall(function() return readfile(memoryFile) end)
        if success and data == "true" then
            isEnabled = true
        end
    end
    
    -- Переключаем состояние
    isEnabled = not isEnabled
    
    if isEnabled then
        ActivateGamepass(gamepassNumber, notify)
    else
        DeactivateGamepass(gamepassNumber, notify)
    end
    
    -- Сохраняем состояние
    if not fromLoad and writefile then
        writefile(memoryFile, tostring(isEnabled))
    end
end

-- Загрузка памяти при старте для обоих геймпасов
local shouldEnable1 = false
local shouldEnable2 = false

if isfile and readfile and isfile(MEMORY_FILE_1) then
    local success, data = pcall(function() return readfile(MEMORY_FILE_1) end)
    if success and data == "true" then
        shouldEnable1 = true
    end
end

if isfile and readfile and isfile(MEMORY_FILE_2) then
    local success, data = pcall(function() return readfile(MEMORY_FILE_2) end)
    if success and data == "true" then
        shouldEnable2 = true
    end
end

-- Применяем сохраненные состояния
if shouldEnable1 then
    Toggle(1, false, true)
end

if shouldEnable2 then
    Toggle(2, false, true)
end

if not shouldEnable1 and not shouldEnable2 then
    print("[Script] Загружен. Нажмите 7 для активации.")
end

-- Привязка клавиш
local BindHandle = UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.Toggle then
        if Cooldown then return end
        Cooldown = true
        
        -- Переключаем первый геймпас (можно изменить логику под свои нужды)
        Toggle(1, true)
        
        task.delay(0.2, function() Cooldown = false end)
    elseif input.KeyCode == Config.Unload then
        SaveColor()
        Notify({
            Title = "Script",
            Description = "Цвет сохранен. Unloading...",
            Duration = 5
        })
        
        -- Выключаем оба геймпаса
        if isfile and readfile and isfile(MEMORY_FILE_1) then
            local success, data = pcall(function() return readfile(MEMORY_FILE_1) end)
            if success and data == "true" then
                Toggle(1, false)
            end
        end
        
        if isfile and readfile and isfile(MEMORY_FILE_2) then
            local success, data = pcall(function() return readfile(MEMORY_FILE_2) end)
            if success and data == "true" then
                Toggle(2, false)
            end
        end
        
        BindHandle:Disconnect()
    end
end)
