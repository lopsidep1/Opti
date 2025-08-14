-- Turbo Optimizer Panel - Modern Resizable, pestañas visibles, scroll, shortcuts, difuminado, bordes redondeados

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local FRAME_MIN_WIDTH = 380
local FRAME_MIN_HEIGHT = 220
local FRAME_MAX_WIDTH = 800
local FRAME_MAX_HEIGHT = 700
local frameWidth = 520
local frameHeight = 400
local resizing = false

local baseline = {Lighting = {}, Sound = {}, Guis = {}, Props = {}}
local guiMain, frame, statusLabel, blackFrame, openBtn, closeBtn, memLabel, fpsLabel, shortcutLabel, shadow
local dragEnabled = true
local avgDt, avgFps = 1/60, 60
local currentProfile = "Medio"
local autoMode = false
local panelVisible = true

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

-- GUI principal y sombra difuminada
guiMain = Instance.new("ScreenGui")
guiMain.Name = "TurboPanel"
guiMain.ResetOnSpawn = false
guiMain.IgnoreGuiInset = false
guiMain.Parent = player:WaitForChild("PlayerGui")

shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.fromOffset(frameWidth+48, frameHeight+64)
shadow.Position = UDim2.fromOffset(20, 40)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5616351187" -- sombra difuminada
shadow.ImageColor3 = Color3.fromRGB(50, 50, 80) -- más difuminado/más claro
shadow.ImageTransparency = 0.35
shadow.ZIndex = 0
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(80,80,240,240)
shadow.Parent = guiMain

frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(frameWidth, frameHeight)
frame.Position = UDim2.fromOffset(40, 60)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
frame.BorderSizePixel = 0
frame.Active = true
frame.ZIndex = 1
frame.Parent = guiMain
local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0.18, 10) -- más redondeado
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
closeBtn.Position = UDim2.fromOffset(frameWidth - 44, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,80)
closeBtn.Text = "❌"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.ZIndex = 5
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function()
    panelVisible = false
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
    panelVisible = true
    frame.Visible = true
    shadow.Visible = true
    openBtn.Visible = false
end)

-- Esquina inferior derecha para redimensionar
local handle = Instance.new("Frame")
handle.Size = UDim2.fromOffset(22, 22)
handle.Position = UDim2.new(1, -22, 1, -22)
handle.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
handle.BorderSizePixel = 0
handle.ZIndex = 20
handle.Parent = frame
Instance.new("UICorner", handle).CornerRadius = UDim.new(1,0)
local handleIcon = Instance.new("ImageLabel", handle)
handleIcon.Size = UDim2.fromScale(1, 1)
handleIcon.BackgroundTransparency = 1
handleIcon.Image = "rbxassetid://6015418713"
handleIcon.ImageColor3 = Color3.fromRGB(200, 180, 255)

handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        local startMouse = UserInputService:GetMouseLocation()
        local startSize = frame.Size
        local startPos = frame.Position
        local cam = workspace.CurrentCamera
        local viewport = cam and cam.ViewportSize or Vector2.new(1920,1080)
        local con; con = UserInputService.InputChanged:Connect(function(inp)
            if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                local delta = mouse - startMouse
                frameWidth = math.clamp(startSize.X.Offset + delta.X, FRAME_MIN_WIDTH, FRAME_MAX_WIDTH)
                frameHeight = math.clamp(startSize.Y.Offset + delta.Y, FRAME_MIN_HEIGHT, FRAME_MAX_HEIGHT)
                frame.Size = UDim2.fromOffset(frameWidth, frameHeight)
                shadow.Size = UDim2.fromOffset(frameWidth+48, frameHeight+64)
                closeBtn.Position = UDim2.fromOffset(frameWidth - 44, 8)
                handle.Position = UDim2.new(1, -22, 1, -22)
                shortcutLabel.Position = UDim2.fromOffset(10, frame.Size.Y.Offset - 28)
                tabsBar.Size = UDim2.new(1, -24, 0, tabHeight)
                for _, f in pairs(contentFrames) do
                    f.Size = UDim2.new(1, 0, 1, 0)
                end
            end
        end)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                if con then con:Disconnect() end
            end
        end)
    end
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
            shadow.Position = UDim2.fromOffset(cx-20, cy-20)
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
shortcutLabel.Text = "Atajos: U=Ultra+ | R=Restaurar | N=Negro | F1=Panel | B=Negro | Panel arrastrable/esquina"
shortcutLabel.TextScaled = true
shortcutLabel.Font = Enum.Font.Gotham
shortcutLabel.TextColor3 = Color3.fromRGB(170, 140, 255)
shortcutLabel.ZIndex = 5
shortcutLabel.Parent = frame

-- TABS y contenido
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
        {Text = "🛠 Optimizar físicas", Callback = optimizePhysics},
        -- Puedes agregar más opciones aquí si lo deseas
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
local contentFrames = {}

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, 0, 1, -(tabY + tabHeight + 44))
contentArea.Position = UDim2.fromOffset(0, tabY + tabHeight + 12)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = frame
contentArea.ClipsDescendants = true
contentArea.ZIndex = 12

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
    corner.CornerRadius = UDim.new(0.18, 10)
    local grad = Instance.new("UIGradient", tabBtn)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 50, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 36, 122)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 18, 80))
    }
    grad.Rotation = 90
    tabBtn.MouseEnter:Connect(function()
        if tabBtn.BackgroundColor3 ~= Color3.fromRGB(180, 100, 255) then
            TweenService:Create(tabBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(80, 90, 210)}):Play()
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if tabBtn.BackgroundColor3 ~= Color3.fromRGB(180, 100, 255) then
            TweenService:Create(tabBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(42, 50, 130)}):Play()
        end
    end)
    table.insert(tabButtons, tabBtn)

    local contentFrame
    if tabName == "⚙️ Acciones" then
        contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.Position = UDim2.new(0,0,0,0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.ScrollBarThickness = 10
        contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        contentFrame.Visible = false
        contentFrame.ZIndex = 13
        contentFrame.Parent = contentArea
        local list = Instance.new("UIListLayout", contentFrame)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 12)
        tabContents[tabName] = {}
        contentFrames[tabName] = contentFrame
        for _, action in ipairs(actions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 44)
            btn.BackgroundColor3 = Color3.fromRGB(38, 22, 80)
            btn.Text = action.Text
            btn.TextColor3 = Color3.fromRGB(205, 215, 255)
            btn.TextScaled = true
            btn.Font = Enum.Font.GothamBold
            btn.Parent = contentFrame
            btn.ZIndex = 14
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0.18, 10)
            local btnGrad = Instance.new("UIGradient", btn)
            btnGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 32, 120)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(96, 38, 122)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 18, 80))
            }
            btnGrad.Rotation = 70
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
            table.insert(tabContents[tabName], btn)
        end
    else
        contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.Position = UDim2.new(0, 0, 0, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.Visible = false
        contentFrame.ZIndex = 13
        contentFrame.Parent = contentArea
        local list = Instance.new("UIListLayout", contentFrame)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 12)
        tabContents[tabName] = {}
        contentFrames[tabName] = contentFrame
        for _, action in ipairs(actions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 44)
            btn.BackgroundColor3 = Color3.fromRGB(38, 22, 80)
            btn.Text = action.Text
            btn.TextColor3 = Color3.fromRGB(205, 215, 255)
            btn.TextScaled = true
            btn.Font = Enum.Font.GothamBold
            btn.Parent = contentFrame
            btn.ZIndex = 14
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0.18, 10)
            local btnGrad = Instance.new("UIGradient", btn)
            btnGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 32, 120)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(96, 38, 122)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 18, 80))
            }
            btnGrad.Rotation = 70
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
            table.insert(tabContents[tabName], btn)
        end
    end
end

tabsBar.CanvasSize = UDim2.new(0, tabsList.AbsoluteContentSize.X, 1, 0)

local activeTab = nil
local function showTab(tabName)
    for name, frameObj in pairs(contentFrames) do
        frameObj.Visible = (name == tabName)
    end
    activeTab = tabName
    for _, btn in ipairs(tabButtons) do
        if btn.Text == tabName then
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(180, 100, 255)}):Play()
            btn.TextColor3 = Color3.fromRGB(255,255,255)
        else
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(42, 50, 130)}):Play()
            btn.TextColor3 = Color3.fromRGB(190, 210, 255)
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
    elseif input.KeyCode == Enum.KeyCode.N or input.KeyCode == Enum.KeyCode.B then
        toggleBlack()
    elseif input.KeyCode == Enum.KeyCode.F1 then
        if panelVisible then
            panelVisible = false
            frame.Visible = false
            shadow.Visible = false
            openBtn.Visible = true
        else
            panelVisible = true
            frame.Visible = true
            shadow.Visible = true
            openBtn.Visible = false
        end
    end
end)

snapshotAll()
statusLabel.Text = "Estado: Inactivo — elige un perfil"
print("[TurboOptimizer] Panel Modern + Scroll/Resize + Atajos OK")
