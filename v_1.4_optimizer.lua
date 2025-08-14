-- Turbo Optimizer Panel - Modern Style: Dark, blue & purple, animated tabs/buttons, shadows, gradients

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local baseline = {Lighting = {}, Sound = {}, Guis = {}, Props = {}}
local guiMain, frame, statusLabel, blackFrame, openBtn, closeBtn, memLabel, fpsLabel, shortcutLabel, shadow
local dragEnabled = true
local avgDt, avgFps = 1/60, 60
local currentProfile = "Medio"
local autoMode = false

local FRAME_WIDTH = 520
local MIN_HEIGHT = 240
local MAX_HEIGHT = 500

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
        L.Ambient = Color3.new(0.1, 0.1, 0.15)
        L.OutdoorAmbient = Color3.new(0.1, 0.1, 0.15)
        L.Brightness = 0.5
    end
    statusLabel.Text = ("Estado: Perfil %s%s"):format(name, autoMode and " (Auto)" or "")
end

local function ultraRendimiento()
    applyProfile("Alto")
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") then
            ensureSaved(s, {"Volume", "Playing"})
            s.Volume = 0
            s.Playing = false
        end
    end
    for _, l in ipairs(Workspace:GetDescendants()) do
        if l:IsA("Light") then
            ensureSaved(l, {"Enabled", "Brightness", "Range"})
            l.Enabled = false
            l.Brightness = 0
            l.Range = 0
        end
    end
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("Smoke") or p:IsA("Sparkles") or p:IsA("Fire") then
            ensureSaved(p, {"Enabled"})
            p.Enabled = false
        end
    end
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

-- Main GUI
guiMain = Instance.new("ScreenGui")
guiMain.Name = "TurboPanel"
guiMain.ResetOnSpawn = false
guiMain.IgnoreGuiInset = false
guiMain.Parent = player:WaitForChild("PlayerGui")

-- Drop Shadow effect
shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.fromOffset(FRAME_WIDTH+28, MAX_HEIGHT+44)
shadow.Position = UDim2.fromOffset(26, 44)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(40,40,80)
shadow.ZIndex = 0
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(12,12,88,88)
shadow.Parent = guiMain

-- Main Panel
frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(FRAME_WIDTH, MIN_HEIGHT)
frame.Position = UDim2.fromOffset(40, 60)
frame.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
frame.BorderSizePixel = 0
frame.Active = true
frame.ZIndex = 1
frame.Parent = guiMain
local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 14)

local gradient = Instance.new("UIGradient", frame)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 32, 60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 36, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 22, 50))
}
gradient.Rotation = 45

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 36)
title.Position = UDim2.fromOffset(28, 2)
title.BackgroundTransparency = 1
title.Text = "⚡ Turbo Optimizer"
title.TextColor3 = Color3.fromRGB(140,180,255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = frame

closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(34, 34)
closeBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 44, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,80)
closeBtn.Text = "❌"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.ZIndex = 5
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.22), {Position = UDim2.fromOffset(-FRAME_WIDTH, frame.Position.Y.Offset)}):Play()
    TweenService:Create(shadow, TweenInfo.new(0.22), {Position = UDim2.fromOffset(-FRAME_WIDTH, shadow.Position.Y.Offset)}):Play()
    wait(0.23)
    frame.Visible = false
    shadow.Visible = false
    openBtn.Visible = true
end)

openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromOffset(40, 40)
openBtn.Position = UDim2.fromOffset(10, 10)
openBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
openBtn.Text = "≡"
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.Parent = guiMain
openBtn.Visible = false
openBtn.ZIndex = 10
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1,0)
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    shadow.Visible = true
    TweenService:Create(frame, TweenInfo.new(0.22), {Position = UDim2.fromOffset(40, frame.Position.Y.Offset)}):Play()
    TweenService:Create(shadow, TweenInfo.new(0.22), {Position = UDim2.fromOffset(26, shadow.Position.Y.Offset)}):Play()
    openBtn.Visible = false
end)

-- Drag panel
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
            shadow.Position = UDim2.fromOffset(cx-14, cy-16)
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

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 22)
statusLabel.Position = UDim2.fromOffset(8, 46)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Estado: Inactivo"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(210, 170, 255)
statusLabel.ZIndex = 2
statusLabel.Parent = frame

fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 90, 0, 18)
fpsLabel.Position = UDim2.fromOffset(12, 72)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: ..."
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
fpsLabel.ZIndex = 2
fpsLabel.Parent = frame

memLabel = Instance.new("TextLabel")
memLabel.Size = UDim2.new(0, 110, 0, 18)
memLabel.Position = UDim2.fromOffset(104, 72)
memLabel.BackgroundTransparency = 1
memLabel.Text = "Mem: ..."
memLabel.TextScaled = true
memLabel.Font = Enum.Font.Code
memLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
memLabel.ZIndex = 2
memLabel.Parent = frame

shortcutLabel = Instance.new("TextLabel")
shortcutLabel.Size = UDim2.new(1, -20, 0, 20)
shortcutLabel.Position = UDim2.fromOffset(10, frame.Size.Y.Offset - 28)
shortcutLabel.BackgroundTransparency = 1
shortcutLabel.Text = "Atajos: U=Ultra+ | R=Restaurar | N=Negro | Panel arrastrable"
shortcutLabel.TextScaled = true
shortcutLabel.Font = Enum.Font.Gotham
shortcutLabel.TextColor3 = Color3.fromRGB(170, 140, 255)
shortcutLabel.ZIndex = 5
shortcutLabel.Parent = frame

-- Tabs scroll horizontal + área de contenido dinámico
local tabs = {
    ["🔄 Restaurar"] = {
        {Text = "🌀 Restaurar todo", Callback = restoreAll},
        {Text = "🌑 Pantalla negra ON/OFF", Callback = toggleBlack}
    },
    ["🧩 Perfiles"] = {
        {Text = "⏬ Bajo", Callback = function() applyProfile("Bajo") end},
        {Text = "⏸ Medio", Callback = function() applyProfile("Medio") end},
        {Text = "⏫ Alto", Callback = function() applyProfile("Alto") end},
        {Text = "⚡ Auto", Callback = function()
            autoMode = not autoMode
            statusLabel.Text = "Estado: Perfil Auto " .. (autoMode and "ON" or "OFF")
        end}
    },
    ["⚙️ Acciones"] = {
        {Text = "🔇 Silenciar sonidos", Callback = muteAll},
        {Text = "💡 Optimizar luces", Callback = optimizeLights},
        {Text = "🌫 Limpiar partículas", Callback = clearParticles},
        {Text = "🖼 Ocultar GUIs decorativos", Callback = hideDecorGUIs},
        {Text = "🧱 Optimizar materiales", Callback = optimizeMaterials},
        {Text = "🛠 Optimizar físicas", Callback = optimizePhysics}
    },
    ["🚀 Ultra+"] = {
        {Text = "🚀 Ultra+ completo", Callback = ultraRendimiento}
    }
}

local tabY = 100
local tabHeight = 48
local tabSpacing = 12

local tabsBar = Instance.new("ScrollingFrame")
tabsBar.Size = UDim2.new(1, -24, 0, tabHeight)
tabsBar.Position = UDim2.fromOffset(12, tabY)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = frame
tabsBar.ScrollBarThickness = 8
tabsBar.ScrollingDirection = Enum.ScrollingDirection.X
tabsBar.BorderSizePixel = 0
tabsBar.ZIndex = 8
tabsBar.CanvasSize = UDim2.new(0, 0, 1, 0)
tabsBar.ClipsDescendants = true

local tabsList = Instance.new("UIListLayout")
tabsList.FillDirection = Enum.FillDirection.Horizontal
tabsList.Padding = UDim.new(0, tabSpacing)
tabsList.SortOrder = Enum.SortOrder.LayoutOrder
tabsList.Parent = tabsBar

local tabButtons = {}
local tabContents = {}

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -44, 1, -(tabY + tabHeight + 56))
contentArea.Position = UDim2.fromOffset(22, tabY + tabHeight + 12)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = frame
contentArea.ClipsDescendants = true
contentArea.ZIndex = 9

local contentLayout = Instance.new("UIListLayout")
contentLayout.Parent = contentArea
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 12)

for tabName, actions in pairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 154, 0, tabHeight - 8)
    tabBtn.BackgroundColor3 = Color3.fromRGB(42, 50, 130)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(190, 210, 255)
    tabBtn.TextScaled = true
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.Parent = tabsBar
    tabBtn.AutoButtonColor = true
    tabBtn.BorderSizePixel = 0
    tabBtn.ZIndex = 10
    local corner = Instance.new("UICorner", tabBtn)
    corner.CornerRadius = UDim.new(0, 14)
    local grad = Instance.new("UIGradient", tabBtn)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 50, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 36, 122)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 18, 80))
    }
    grad.Rotation = 90
    -- Hover effect
    tabBtn.MouseEnter:Connect(function()
        TweenService:Create(tabBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(80, 90, 210)}):Play()
    end)
    tabBtn.MouseLeave:Connect(function()
        if tabBtn.BackgroundColor3 ~= Color3.fromRGB(180, 100, 255) then
            TweenService:Create(tabBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(42, 50, 130)}):Play()
        end
    end)
    table.insert(tabButtons, tabBtn)

    local btns = {}
    for i, action in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3 = Color3.fromRGB(38, 22, 80)
        btn.Text = action.Text
        btn.TextColor3 = Color3.fromRGB(205, 215, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = contentArea
        btn.Visible = false
        btn.ZIndex = 10
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 12)
        local btnGrad = Instance.new("UIGradient", btn)
        btnGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 32, 120)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(96, 38, 122)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 18, 80))
        }
        btnGrad.Rotation = 70
        -- Hover effect
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(120, 60, 170)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(38, 22, 80)}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(function() action.Callback(btn) end)
            if not ok then
                warn("[TurboOptimizer] Error en botón:", err)
            end
        end)
        table.insert(btns, btn)
    end
    tabContents[tabName] = btns
end

tabsBar.CanvasSize = UDim2.new(0, tabsList.AbsoluteContentSize.X, 1, 0)

local function showTab(tabName)
    for t, btns in pairs(tabContents) do
        for _, b in ipairs(btns) do
            b.Visible = (t == tabName)
        end
    end
    local count = #tabContents[tabName]
    local newHeight = math.clamp(tabY + tabHeight + 12 + count * (44+12) + 56, MIN_HEIGHT, MAX_HEIGHT)
    frame.Size = UDim2.fromOffset(FRAME_WIDTH, newHeight)
    shadow.Size = UDim2.fromOffset(FRAME_WIDTH+28, newHeight+44)
    closeBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 44, 8)
    shortcutLabel.Position = UDim2.fromOffset(10, frame.Size.Y.Offset - 28)
    for _, btn in ipairs(tabButtons) do
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(42, 50, 130)}):Play()
    end
    for i, btn in ipairs(tabButtons) do
        if btn.Text == tabName then
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(180, 100, 255)}):Play()
        end
    end
end

for i, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        showTab(btn.Text)
    end)
end
showTab(tabButtons[1].Text)

RunService.RenderStepped:Connect(function(dt)
    if fpsLabel and memLabel then
        avgDt = avgDt + (dt - avgDt) * 0.15
        avgFps = math.max(1, math.floor(1/avgDt + 0.5))
        fpsLabel.Text = "FPS: " .. avgFps
        fpsLabel.TextColor3 = (avgFps >= 50 and Color3.fromRGB(100,255,200)) or (avgFps >= 30 and Color3.fromRGB(255,230,90)) or Color3.fromRGB(255,100,120)
        local luaMB = math.floor((collectgarbage("count")/1024) * 10 + 0.5)/10
        memLabel.Text = ("Mem: %.1f MB"):format(luaMB)
    end
end)

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

snapshotAll()
statusLabel.Text = "Estado: Inactivo — elige un perfil"
print("[TurboOptimizer] Panel Modern Cargado. Atajos: U, R, N")
