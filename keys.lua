-- Serviços
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local usedKeys = {}

-- Função de validação de formato da key (exemplo com prefixo FREE_)
local function isValidKeyFormat(key)
    return string.match(key, "^FREE_%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w$") ~= nil
end

-- Notificação
local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 4
    })
end

-- Criar GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "JeffKeySystem"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 230)
Frame.Position = UDim2.new(0.5, -150, 0.5, -115)
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

-- Botão Fechar
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
TextBox.Position = UDim2.new(0.05, 0, 0.25, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TextBox.TextColor3 = Color3.new(1, 1, 1)
TextBox.Text = ""
TextBox.ClearTextOnFocus = false
TextBox.Font = Enum.Font.SourceSans
TextBox.TextSize = 18
Instance.new("UICorner", TextBox)

-- Label de mensagem
local message = Instance.new("TextLabel", Frame)
message.Size = UDim2.new(0.9, 0, 0, 30)
message.Position = UDim2.new(0.05, 0, 0.55, 0)
message.BackgroundTransparency = 1
message.TextColor3 = Color3.new(1, 1, 1)
message.Font = Enum.Font.SourceSansItalic
message.TextSize = 16
message.Text = ""

-- Botão Verificar Key
local VerifyBtn = Instance.new("TextButton", Frame)
VerifyBtn.Text = "Verificar Key"
VerifyBtn.Size = UDim2.new(0.45, 0, 0, 30)
VerifyBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
VerifyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.Font = Enum.Font.SourceSans
VerifyBtn.TextSize = 16
Instance.new("UICorner", VerifyBtn)

-- Botão Get Key
local GetBtn = Instance.new("TextButton", Frame)
GetBtn.Text = "Get Key"
GetBtn.Size = UDim2.new(0.45, 0, 0, 30)
GetBtn.Position = UDim2.new(0.5, 0, 0.75, 0)
GetBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
GetBtn.TextColor3 = Color3.new(1, 1, 1)
GetBtn.Font = Enum.Font.SourceSans
GetBtn.TextSize = 16
Instance.new("UICorner", GetBtn)

-- Arrastar janela
local dragging, dragInput, mousePos, framePos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = Frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        Frame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Ação do botão Get Key
GetBtn.MouseButton1Click:Connect(function()
    setclipboard("https://09451251-ce7c-4b85-9888-3ccad0870dd4-00-1zbdtwvn428t0.worf.replit.dev")
    notify("🔗 Link Copiado", "Acesse o site para gerar sua key.", 3)
end)

-- Ação do botão Verificar Key
VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = TextBox.Text:upper()

    if not isValidKeyFormat(inputKey) then
        message.Text = "❌ Formato de key inválido."
        notify("Erro", "Formato da key inválido!", 4)
        return
    end

    if usedKeys[inputKey] then
        message.Text = "❌ Essa key já foi usada! Use outra."
        notify("Erro", "❌ Essa key é repetida. Use outra!", 5)
        return
    end

    usedKeys[inputKey] = true
    message.Text = "✅ Key correta! Você entrou na whitelist."
    notify("Sucesso", "✅ Key correta! Dando whitelist...", 5)

    -- Aqui você executa a função liberada após validação
    -- Exemplo:
    -- print("Usuário autorizado:", player.Name)

    wait(1)
    ScreenGui:Destroy()
end)
