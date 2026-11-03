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
local MEMORY_FILE = "further_reach_memory.txt"
local COLOR_FILE = "further_reach_color.txt"

-- Безопасное получение объекта с ожиданием
local GamepassEvents = ReplicatedStorage:WaitForChild("GamepassEvents", 5)
if not GamepassEvents then
    Notify({Title = "Ошибка", Description = "Не найден GamepassEvents!", Duration = 5})
    return
end

local ScriptNotify = GamepassEvents:FindFirstChild("FurtherReachBoughtNotifier")
if not ScriptNotify then
    Notify({Title = "Ошибка", Description = "Игра обновилась. FurtherReachBoughtNotifier не найден.", Duration = 5})
    return
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

-- Функция сохранения цвета (вызывается, когда цвет меняется в игре)
local function SaveColor()
    local MenuGui = LocalPlayer.PlayerGui:FindFirstChild("MenuGui")
    if MenuGui and MenuGui.Menu.TabContents.Settings.Contents.LineFrame then
        local ColorPicker = MenuGui.Menu.TabContents.Settings.Contents.LineFrame.ColorPicking
        -- Если в игре используется Color3Value, мы берем его значение
        if ColorPicker:FindFirstChildWhichIsA("Color3Value") then
            local currentColor = ColorPicker.Color3Value.Value
            if writefile then
                writefile(COLOR_FILE, tostring(currentColor.R) .. "," .. tostring(currentColor.G) .. "," .. tostring(currentColor.B))
                print("Цвет сохранен в память!")
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
            Title = "Further Reach",
            Description = isEnabled and "Activated!" or "Disabled!",
            Duration = 5
        })
    end

    if isEnabled then
        local LineTexture = LocalPlayer:FindFirstChild("FartherReach")
        if LineTexture then LineTexture:Destroy() end
        
        local Marker = Instance.new("BoolValue")
        Marker.Name = "FartherReach"
        Marker.Value = true
        Marker.Parent = LocalPlayer

        ScriptNotify.Parent = ReplicatedFirst
        Activator.Parent = ReplicatedStorage.GamepassEvents
        Activator.Name = "FurtherReachBoughtNotifier"

        ReloadScript()
        
        -- Восстановление цвета из памяти при активации
        if isfile and readfile and isfile(COLOR_FILE) then
            local success, data = pcall(function() return readfile(COLOR_FILE) end)
            if success and data then
                local r, g, b = data:match("([^,]+),([^,]+),([^,]+)")
                if r and g and b then
                    local savedColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                    print("Восстановлен цвет из памяти: ", savedColor)
                    -- Тут можно применить цвет к линиям (если игра позволяет)
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
    else
        local LineTexture = LocalPlayer:FindFirstChild("FartherReach")
        if LineTexture then LineTexture:Destroy() end

        ScriptNotify.Parent = ReplicatedStorage.GamepassEvents
        Activator.Name = "LimitedTimeToyEvent"
        Activator.Parent = ReplicatedStorage.MenuToys

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

-- Загрузка памяти при старте
local shouldEnable = false
if isfile and readfile and isfile(MEMORY_FILE) then
    local success, data = pcall(function() return readfile(MEMORY_FILE) end)
    if success and data == "true" then
        shouldEnable = true
    end
end

if shouldEnable then
    Toggle(false, true) 
else
    print("[Further Reach] Загружен. Нажмите 7 для активации.")
end

-- Привязка клавиш (кнопка 8 — сохраняет текущий цвет в память перед выгрузкой)
local BindHandle = UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Config.Toggle then
        if Cooldown then return end
        Cooldown = true
        Toggle(true)
        task.delay(0.2, function() Cooldown = false end)

    elseif input.KeyCode == Config.Unload then
        SaveColor() -- Сохраняем цвет перед выгрузкой
        Notify({
            Title = "Further Reach",
            Description = "Цвет сохранен. Unloading...",
            Duration = 5
        })

        if Config.Working then
            Toggle(false)
        end
        BindHandle:Disconnect()
    end
end)
