if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local guiMain = Instance.new("ScreenGui")
guiMain.Name = "TurboPanel"
guiMain.ResetOnSpawn = false
guiMain.IgnoreGuiInset = false
guiMain.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(460, 500)
frame.Position = UDim2.fromOffset(20, 60)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = guiMain
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = dur or 5})
    end)
end

local baseline = {Lighting = {}, Sound = {}, Terrain = {}, Streaming = {}, Guis = {}, Props = {}}
local function ensureSaved(obj, props)
    if not obj then return end
    baseline.Props[obj] = baseline.Props[obj] or {}
    for _, p in ipairs(props) do
        if baseline.Props[obj][p] == nil then
            local ok, val = pcall(function() return obj[p] end)
            if ok then baseline.Props[obj][p] = val end
        end
    end
end

local function snapshotAll()
    local L = Lighting
    baseline.Lighting = {
        GlobalShadows = L.GlobalShadows,
        FogEnd = L.FogEnd,
        EnvironmentDiffuseScale = L.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = L.EnvironmentSpecularScale,
        Ambient = L.Ambient,
        OutdoorAmbient = L.OutdoorAmbient,
        Brightness = L.Brightness,
        Technology = L.Technology,
        ShadowSoftness = L.ShadowSoftness,
        ColorShift_Bottom = L.ColorShift_Bottom,
        ColorShift_Top = L.ColorShift_Top
    }
    baseline.Sound = {
        AmbientReverb = SoundService.AmbientReverb,
        DistanceFactor = SoundService.DistanceFactor,
        DopplerScale = SoundService.DopplerScale,
        RespectFilteringEnabled = SoundService.RespectFilteringEnabled
    }
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then
        baseline.Terrain = {
            WaterReflectance = t.WaterReflectance,
            WaterTransparency = t.WaterTransparency,
            WaterWaveSize = t.WaterWaveSize,
            WaterWaveSpeed = t.WaterWaveSpeed,
        }
    end
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g:IsA("ScreenGui") then
            baseline.Guis[g] = g.Enabled
        end
    end
end
local function optimizePhysicsUltraSafe()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Model") then
            if not part.Anchored and part.AssemblyLinearVelocity.Magnitude < 0.01 then
                ensureSaved(part, {"Anchored", "CanCollide"})
                part.Anchored = true
                part.CanCollide = false
            end
        end
    end
end

local function toggleBlack()
    if not blackFrame then
        blackFrame = Instance.new("Frame")
        blackFrame.Size = UDim2.fromScale(1, 1)
        blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = 9999
        blackFrame.Parent = guiMain
    end
    blackFrame.Visible = not blackFrame.Visible
end

local function ultraRendimiento()
    applyProfile("Alto")
    muteAll()
    optimizeLights()
    clearParticles()
    if ultraHideGUIs then hideDecorGUIs() end
    optimizeMaterials()
    optimizePhysicsUltraSafe()
    Lighting.Technology = Enum.Technology.Compatibility
    Lighting.ShadowSoftness = 0
    Lighting.ColorShift_Bottom = Color3.new(0,0,0)
    Lighting.ColorShift_Top = Color3.new(0,0,0)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSpeed = 0
        terrain.WaterWaveSize = 0
        terrain.WaterTransparency = 1
        terrain.WaterReflectance = 0
    end
    SoundService.RespectFilteringEnabled = false
    SoundService.AmbientReverb = Enum.ReverbType.Off
    statusLabel.Text = "Estado: Ultra+ activado"
    notify("Modo Turbo", "Ultra+ activado", 4)
end
-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0, 28)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Text = "Modo Turbo Optimizer PRO"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Indicadores
statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 24)
statusLabel.Position = UDim2.fromOffset(5, 36)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Estado: Inactivo"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.Parent = frame

fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, -10, 0, 24)
fpsLabel.Position = UDim2.fromOffset(5, 60)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: ..."
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.Gotham
fpsLabel.Parent = frame

memLabel = Instance.new("TextLabel")
memLabel.Size = UDim2.new(1, -10, 0, 24)
memLabel.Position = UDim2.fromOffset(5, 84)
memLabel.BackgroundTransparency = 1
memLabel.Text = "Mem (Lua): ..."
memLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
memLabel.TextScaled = true
memLabel.Font = Enum.Font.Gotham
memLabel.Parent = frame

-- Diagnóstico avanzado
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1,-10,0,22)
statsLabel.Position = UDim2.fromOffset(5, 108)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Ping: ... | Partes: ... | Luz: ... | Partículas: ..."
statsLabel.TextColor3 = Color3.fromRGB(170,170,220)
statsLabel.TextScaled = true
statsLabel.Font = Enum.Font.Gotham
statsLabel.Parent = frame

-- Sistema de pestañas
local pestañas = {
    ["🧩 Perfiles"] = {
        {Text = "Bajo", Callback = function() applyProfile("Bajo") end},
        {Text = "Medio", Callback = function() applyProfile("Medio") end},
        {Text = "Alto", Callback = function() applyProfile("Alto") end},
        {Text = "Auto: OFF", Callback = function(btn)
            autoMode = not autoMode
            btn.Text = "Auto: " .. (autoMode and "ON" or "OFF")
        end}
    },
    ["⚙️ Acciones"] = {
        {Text = "Silenciar todo", Callback = muteAll},
        {Text = "Apagar luces", Callback = optimizeLights},
        {Text = "Apagar partículas", Callback = clearParticles},
        {Text = "Ocultar GUIs decorativas", Callback = hideDecorGUIs},
        {Text = "Optimizar materiales", Callback = optimizeMaterials},
        {Text = "Optimizar físicas", Callback = optimizePhysicsUltraSafe}
    },
    ["🚀 Ultra+"] = {
        {Text = "Activar Ultra+", Callback = ultraRendimiento}
    },
    ["🔄 Restaurar"] = {
        {Text = "Restaurar todo", Callback = restoreAll},
        {Text = "Pantalla negra", Callback = toggleBlack}
    }
}

local tabFrames = {}
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.fromOffset(10, 140)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1, 0, 1, 0)
tabScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.ScrollBarThickness = 4
tabScroll.BackgroundTransparency = 1
tabScroll.Parent = tabBar

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 6)
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Parent = tabScroll

local function showTab(name)
    for tabName, tabFrame in pairs(tabFrames) do
        tabFrame.Visible = (tabName == name)
    end
end

for tabName, actions in pairs(pestañas) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 140, 1, -6)
    tabBtn.Text = tabName
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextScaled = true
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
    tabBtn.Parent = tabScroll
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0,6)
    tabBtn.MouseButton1Click:Connect(function() showTab(tabName) end)

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -20, 0, 240)
    tabFrame.Position = UDim2.fromOffset(10, 190)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = frame
    tabFrames[tabName] = tabFrame

    for i, action in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.Position = UDim2.fromOffset(0, (i - 1) * 36)
        btn.Text = action.Text
        btn.Font = Enum.Font.Gotham
        btn.TextScaled = true
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.Parent = tabFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(function() action.Callback(btn) end)
            if not ok then
                warn("[Modo Turbo] Error en botón:", err)
                notify("Modo Turbo", "Error en " .. action.Text, 3)
            end
        end)
    end
end

tabScroll.CanvasSize = UDim2.new(0, tabList.AbsoluteContentSize.X, 1, 0)
showTab("🧩 Perfiles")
-- Diagnóstico en tiempo real
RunService.RenderStepped:Connect(function(dt)
    avgDt = avgDt + (dt - avgDt) * 0.15
    avgFps = math.max(1, math.floor(1/avgDt + 0.5))
end)

task.spawn(function()
    while guiMain.Parent do
        fpsLabel.Text = "FPS: " .. avgFps
        fpsLabel.TextColor3 = (avgFps >= 50 and Color3.new(0,1,0)) or (avgFps >= 30 and Color3.new(1,1,0)) or Color3.new(1,0,0)
        local luaMB = math.floor((collectgarbage("count")/1024) * 10 + 0.5)/10
        memLabel.Text = ("Mem (Lua): %.1f MB"):format(luaMB)

        local ping = "?"
        pcall(function()
            local stats = workspace:FindFirstChild("Stats")
            if stats and stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerTime") then
                ping = tostring(math.floor(stats.Network.ServerTime.Value*1000))
            end
        end)

        local parts, lights, particles = 0, 0, 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then parts += 1 end
            if d:IsA("Light") then lights += 1 end
            if d:IsA("ParticleEmitter") then particles += 1 end
        end
        statsLabel.Text = ("Ping: %s | Partes: %d | Luz: %d | Partículas: %d"):format(ping, parts, lights, particles)

        if tick()-lastAutoClean > autoCleanInterval then
            clearParticles()
            optimizeMaterials()
            collectgarbage("collect")
            notify("Modo Turbo", "Auto-clean ejecutado", 2)
            lastAutoClean = tick()
        end

        task.wait(0.5)
    end
end)

-- Sistema de arrastre
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if not dragEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and dragEnabled then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
        end
    end
end)

-- Atajos de teclado
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        frame.Visible = not frame.Visible
    elseif input.KeyCode == Enum.KeyCode.B then
        toggleBlack()
    end
end)

-- Snapshot inicial y mensaje de carga
snapshotAll()
statusLabel.Text = "Estado: Inactivo — elige un perfil o usa Auto"
notify("Modo Turbo", "Panel PRO listo (F1 oculta/muestra)", 4)
