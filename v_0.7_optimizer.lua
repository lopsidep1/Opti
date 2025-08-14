-- Turbo Optimizer Panel v2.0 - Tabs: Perfiles, Acciones, Ultra+, Restaurar
-- Servicios
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local baseline = {Lighting = {}, Sound = {}, Guis = {}, Props = {}}
local guiMain, frame, statusLabel, blackFrame, openBtn
local dragEnabled = true
local avgDt, avgFps = 1/60, 60
local currentProfile = "Medio"
local autoMode = false

-- Estado original
local function ensureSaved(obj, props)
    if not obj then return end
    baseline.Props[obj] = baseline.Props[obj] or {}
    local saved = baseline.Props[obj]
    for _, p in ipairs(props) do
        if saved[p] == nil then
            local ok, val = pcall(function() return obj[p] end)
            if ok then saved[p] = val end
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
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g:IsA("ScreenGui") then
            baseline.Guis[g] = g.Enabled
        end
    end
end

local function restoreAll()
    for k, v in pairs(baseline.Lighting) do Lighting[k] = v end
    for k, v in pairs(baseline.Sound) do SoundService[k] = v end
    for g, state in pairs(baseline.Guis) do if g then g.Enabled = state end end
    for obj, props in pairs(baseline.Props) do
        if obj then
            for propName, originalValue in pairs(props) do
                pcall(function() obj[propName] = originalValue end)
            end
        end
    end
    if blackFrame then blackFrame.Visible = false end
    statusLabel.Text = "Estado: Restaurado"
end

-- Perfiles
local function applyProfile(name)
    currentProfile = name
    local L = Lighting
    if name == "Bajo" then
        L.GlobalShadows = false
        L.FogEnd = 1e6
        L.EnvironmentDiffuseScale = 0.1
        L.EnvironmentSpecularScale = 0.1
        L.Brightness = 1
    elseif name == "Medio" then
        L.GlobalShadows = false
        L.FogEnd = 1e8
        L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0
        L.Brightness = 0.75
    elseif name == "Alto" then
        L.GlobalShadows = false
        L.FogEnd = 1e9
        L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0
        L.Ambient = Color3.new(0.1, 0.1, 0.1)
        L.OutdoorAmbient = Color3.new(0.1, 0.1, 0.1)
        L.Brightness = 0.5
    end
    statusLabel.Text = ("Estado: Perfil %s%s"):format(name, autoMode and " (Auto)" or "")
end

-- Ultra+
local function ultraRendimiento()
    applyProfile("Alto")
    -- Silenciar sonidos
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") then
            ensureSaved(s, {"Volume", "Playing"})
            s.Volume = 0
            s.Playing = false
        end
    end
    -- Optimizar luces
    for _, l in ipairs(Workspace:GetDescendants()) do
        if l:IsA("Light") then
            ensureSaved(l, {"Enabled", "Brightness", "Range"})
            l.Enabled = false
            l.Brightness = 0
            l.Range = 0
        end
    end
    -- Limpiar partículas
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Smoke") or p:IsA("Sparkles") or p:IsA("Fire") then
            ensureSaved(p, {"Enabled"})
            p.Enabled = false
        end
    end
    -- Optimizar materiales
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Material == Enum.Material.Neon or part.Material == Enum.Material.Glass then
                ensureSaved(part, {"Material"})
                part.Material = Enum.Material.SmoothPlastic
            end
        end
        if part:IsA("MeshPart") then
            ensureSaved(part, {"RenderFidelity"})
            pcall(function() part.RenderFidelity = Enum.RenderFidelity.Performance end)
        end
    end
    statusLabel.Text = "Estado: Ultra+ activado"
end

-- Acciones
local function muteAll()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") then
            ensureSaved(s, {"Volume", "Playing"})
            s.Volume = 0
            s.Playing = false
        end
    end
end

local function optimizeLights()
    for _, l in ipairs(Workspace:GetDescendants()) do
        if l:IsA("Light") then
            ensureSaved(l, {"Enabled", "Brightness", "Range"})
            l.Enabled = false
            l.Brightness = 0
            l.Range = 0
        end
    end
end

local function clearParticles()
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Smoke") or p:IsA("Sparkles") or p:IsA("Fire") then
            ensureSaved(p, {"Enabled"})
            p.Enabled = false
        end
    end
end

local function hideDecorGUIs()
    for g, _ in pairs(baseline.Guis) do
        if g and g ~= guiMain then
            ensureSaved(g, {"Enabled"})
            g.Enabled = false
        end
    end
end

local function optimizeMaterials()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Material == Enum.Material.Neon or part.Material == Enum.Material.Glass then
                ensureSaved(part, {"Material"})
                part.Material = Enum.Material.SmoothPlastic
            end
        end
        if part:IsA("MeshPart") then
            ensureSaved(part, {"RenderFidelity"})
            pcall(function() part.RenderFidelity = Enum.RenderFidelity.Performance end)
        end
    end
end

local function optimizePhysics()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            ensureSaved(part, {"Anchored", "CanCollide"})
            part.Anchored = true
            part.CanCollide = false
        end
    end
end

-- Pantalla negra
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

-- GUI principal
guiMain = Instance.new("ScreenGui")
guiMain.Name = "TurboPanel"
guiMain.ResetOnSpawn = false
guiMain.IgnoreGuiInset = false
guiMain.Parent = player:WaitForChild("PlayerGui")

local FRAME_WIDTH = 480
local FRAME_HEIGHT = 340

frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(FRAME_WIDTH, FRAME_HEIGHT)
frame.Position = UDim2.fromOffset(40, 60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = guiMain
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.fromOffset(0, 0)
title.BackgroundTransparency = 1
title.Text = "Turbo Optimizer Panel"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 24)
statusLabel.Position = UDim2.fromOffset(5, 36)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Estado: Inactivo"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.Parent = frame

-- Botón abrir/cerrar panel
openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromOffset(36, 36)
openBtn.Position = UDim2.fromOffset(10, 10)
openBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
openBtn.Text = "≡"
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.Parent = guiMain
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1,0)
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    openBtn.Visible = false
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 36, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,30)
closeBtn.Text = "✕"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    openBtn.Visible = true
end)

-- Arrastre libre del panel
local dragging, dragStart, startPos
local function clampToViewport(x, y)
    local cam = workspace.CurrentCamera
    local view = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local sz = frame.AbsoluteSize
    return math.clamp(x, 0, view.X - sz.X), math.clamp(y, 0, view.Y - sz.Y)
end
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
            local x, y = startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y
            local cx, cy = clampToViewport(x, y)
            frame.Position = UDim2.fromOffset(cx, cy)
        end
    end
end)
openBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = openBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            openBtn.Position = UDim2.fromOffset(
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- Tabs y botones - Fila superior
local tabs = {
    ["🔄 Restaurar"] = {
        {Text = "Restaurar todo", Callback = restoreAll},
        {Text = "Pantalla negra ON/OFF", Callback = toggleBlack}
    },
    ["🧩 Perfiles"] = {
        {Text = "Bajo", Callback = function() applyProfile("Bajo") end},
        {Text = "Medio", Callback = function() applyProfile("Medio") end},
        {Text = "Alto", Callback = function() applyProfile("Alto") end},
        {Text = "Auto", Callback = function()
            autoMode = not autoMode
            statusLabel.Text = "Estado: Perfil Auto " .. (autoMode and "ON" or "OFF")
        end}
    },
    ["⚙️ Acciones"] = {
        {Text = "Silenciar sonidos", Callback = muteAll},
        {Text = "Optimizar luces", Callback = optimizeLights},
        {Text = "Limpiar partículas", Callback = clearParticles},
        {Text = "Ocultar GUIs decorativos", Callback = hideDecorGUIs},
        {Text = "Optimizar materiales", Callback = optimizeMaterials},
        {Text = "Optimizar físicas", Callback = optimizePhysics}
    },
    ["🚀 Ultra+"] = {
        {Text = "Ultra+ completo", Callback = ultraRendimiento}
    }
}

local tabButtons, tabFrames = {}, {}
local tabY = 72
local tabHeight = 36
local tabSpacing = 8
local contentY = tabY + tabHeight + 10
local buttonHeight = 36

local tabsBar = Instance.new("Frame")
tabsBar.Size = UDim2.new(1, -20, 0, tabHeight + 8)
tabsBar.Position = UDim2.fromOffset(10, tabY)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = frame
tabsBar.ClipsDescendants = true

local tabsList = Instance.new("UIListLayout")
tabsList.FillDirection = Enum.FillDirection.Horizontal
tabsList.Padding = UDim.new(0, tabSpacing)
tabsList.SortOrder = Enum.SortOrder.LayoutOrder
tabsList.Parent = tabsBar

for tabName, actions in pairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 120, 1, -8)
    tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.new(1, 1, 1)
    tabBtn.TextScaled = true
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.Parent = tabsBar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
    table.insert(tabButtons, tabBtn)

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -20, 1, -(contentY + 10))
    tabFrame.Position = UDim2.fromOffset(10, contentY)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = frame
    tabFrames[tabName] = tabFrame

    for i, action in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, buttonHeight)
        btn.Position = UDim2.fromOffset(0, (i - 1) * (buttonHeight + 8))
        btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        btn.Text = action.Text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = tabFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(function() action.Callback(btn) end)
            if not ok then
                warn("[TurboOptimizer] Error en botón:", err)
            end
        end)
    end
end

local function showTab(tabName)
    for name, tab in pairs(tabFrames) do
        tab.Visible = (name == tabName)
    end
end
for _, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        showTab(btn.Text)
    end)
end
showTab(tabButtons[1].Text)

-- FPS promedio para Auto Mode
RunService.RenderStepped:Connect(function(dt)
    avgDt = avgDt + (dt - avgDt) * 0.15
    avgFps = math.max(1, math.floor(1/avgDt + 0.5))
end)

-- Auto Mode: cambia perfil según FPS cada segundo
task.spawn(function()
    local lastApplied = currentProfile
    while guiMain.Parent do
        if autoMode then
            local n = avgFps
            local target
            if n < 30 then
                target = "Alto"
            elseif n < 50 then
                target = "Medio"
            else
                target = "Bajo"
            end
            if target ~= lastApplied then
                applyProfile(target)
                lastApplied = target
            end
        end
        task.wait(1.0)
    end
end)

-- Atajos de teclado
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.U then
        ultraRendimiento()
    elseif input.KeyCode == Enum.KeyCode.R then
        restoreAll()
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleBlack()
    end
end)

-- Info de atajos
local shortcutLabel = Instance.new("TextLabel")
shortcutLabel.Size = UDim2.new(1, -20, 0, 22)
shortcutLabel.Position = UDim2.fromOffset(10, frame.Size.Y.Offset - 26)
shortcutLabel.BackgroundTransparency = 1
shortcutLabel.Text = "Atajos: U=Ultra+ | R=Restaurar | N=Negro | Panel arrastrable"
shortcutLabel.TextScaled = true
shortcutLabel.Font = Enum.Font.Gotham
shortcutLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
shortcutLabel.Parent = frame

-- Inicializar
snapshotAll()
statusLabel.Text = "Estado: Inactivo — elige un perfil"
print("[TurboOptimizer] Panel Tabs Cargado. Atajos: U, R, N")
