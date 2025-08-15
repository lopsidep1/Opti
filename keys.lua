-- SERVIDOR: Sistema de Key con reporte de errores a Discord (poner en ServerScriptService)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Cambia esto a tu Webhook real de Discord
local webhookUrl = "https://discord.com/api/webhooks/1405789222249431191/bx9Dga9EjAFYH6vYXtm8T9sxj2r21hpn-GL5blCxS0u9SVOJ59qoYaYLT4t9lyTa_Zlb"

local usedKeys = {}

-- Validación de key (prefijo FREE_)
local function isValidKeyFormat(key)
    return string.match(key, "^FREE_%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w$") ~= nil
end

-- Reporte de error a Discord
local function sendDiscordErrorLog(playerName, key, motivo)
    local content = string.format("🚨 [KeySystem] Error:\nJugador: **%s**\nKey: `%s`\nMotivo: %s", playerName, key, motivo)
    local data = {["content"] = content}
    local body = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        HttpService:PostAsync(webhookUrl, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if not success then
        warn("No se pudo enviar el error a Discord: " .. tostring(err))
    end
end

-- Evento remoto para validación de key
local remote = Instance.new("RemoteFunction")
remote.Name = "CheckKeyRemote"
remote.Parent = game.ReplicatedStorage

remote.OnServerInvoke = function(player, key)
    if not isValidKeyFormat(key) then
        sendDiscordErrorLog(player.Name, key, "Formato inválido")
        return false, "Formato da key incorreto."
    end
    if usedKeys[key] then
        sendDiscordErrorLog(player.Name, key, "Key ya usada")
        return false, "Essa key já foi usada."
    end

    usedKeys[key] = true
    return true, "Key aceita! Bem-vindo."
end

-- CLIENTE: Interfaz gráfica para ingresar la key (poner en StarterPlayerScripts como LocalScript)

--[[

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local remote = ReplicatedStorage:WaitForChild("CheckKeyRemote")

-- Crear GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JeffKeySystem"
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Instance.new("UICorner", Frame)

-- Título
local Title = Instance.new("TextLabel", Frame)
Title.Text = "Sistema de Key"
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Botón Fechar
local CloseBtn = Instance.new("TextButton", Frame)
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 18
Instance.new("UICorner", CloseBtn)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Caixa de texto da key
local TextBox = Instance.new("TextBox", Frame)
TextBox.PlaceholderText = "Digite sua key aqui..."
TextBox.Size = UDim2.new(0.9, 0, 0, 40)
TextBox.Position = UDim2.new(0.05, 0, 0.3, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TextBox.TextColor3 = Color3.new(1, 1, 1)
TextBox.Font = Enum.Font.SourceSans
TextBox.TextSize = 18
Instance.new("UICorner", TextBox)

-- Botão de enviar
local SendBtn = Instance.new("TextButton", Frame)
SendBtn.Text = "Enviar"
SendBtn.Size = UDim2.new(0.5, -10, 0, 35)
SendBtn.Position = UDim2.new(0.25, 0, 0.65, 0)
SendBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
SendBtn.TextColor3 = Color3.new(1, 1, 1)
SendBtn.Font = Enum.Font.SourceSansBold
SendBtn.TextSize = 18
Instance.new("UICorner", SendBtn)

local function notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 4
    })
end

SendBtn.MouseButton1Click:Connect(function()
    local key = TextBox.Text
    local success, msg = remote:InvokeServer(key)
    if success then
        notify("Sucesso", msg, 4)
        ScreenGui:Destroy()
    else
        notify("Erro", msg, 4)
    end
end)

]]

-- Fin del script completo
