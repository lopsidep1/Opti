-- ReplicatedStorage > ModuleScript (nombre: OptimizadorModule)

local Optimizador = {}
local player = game:GetService("Players").LocalPlayer
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local guiMain
local statusLabel, blackFrame
local autoMode = false
local currentProfile = "Medio"
local ultraHideGUIs = false

-- Estados originales para reversión
local baseline = {
    Lighting = {}, Sound = {}, Terrain = {}, Guis = {}, Props = {}
}

-- 🔔 Notificación en pantalla
local function notify(t, m, d)
    StarterGui:SetCore("SendNotification", {Title = t, Text = m, Duration = d or 4})
end

-- Guardar propiedades originales de un objeto
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

-- Capturar estado inicial de Lighting, Sound, Terrain y GUIs
local function snapshotAll()
    for k, v in pairs(Lighting:GetProperties()) do baseline.Lighting[k] = Lighting[k] end
    for k, v in pairs(SoundService:GetProperties()) do baseline.Sound[k] = SoundService[k] end
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then for k, v in pairs(t:GetProperties()) do baseline.Terrain[k] = t[k] end end
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g:IsA("ScreenGui") then baseline.Guis[g] = g.Enabled end
    end
end
-- ===== FUNCIONES PRINCIPALES =====

-- Aplicar perfil gráfico
function Optimizador.applyProfile(name)
    currentProfile = name
    local L = Lighting
    if name == "Bajo" then
        L.GlobalShadows = false; L.FogEnd = 1e6; L.EnvironmentDiffuseScale = 0.1
        L.EnvironmentSpecularScale = 0.1; L.Brightness = 1
    elseif name == "Medio" then
        L.GlobalShadows = false; L.FogEnd = 1e8; L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0; L.Brightness = 0.75
    elseif name == "Alto" then
        L.GlobalShadows = false; L.FogEnd = 1e9; L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0; L.Ambient = Color3.new(0.1,0.1,0.1)
        L.OutdoorAmbient = Color3.new(0.1,0.1,0.1); L.Brightness = 0.5
    end
    if statusLabel then
        statusLabel.Text = ("Estado: Activo (%s%s)"):format(name, autoMode and " - Auto" or "")
    end
end

-- Restaurar todo a como estaba
function Optimizador.restoreAll()
    for k, v in pairs(baseline.Lighting) do Lighting[k] = v end
    for k, v in pairs(baseline.Sound) do SoundService[k] = v end
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then for k, v in pairs(baseline.Terrain) do t[k] = v end end
    for g, state in pairs(baseline.Guis) do if g then g.Enabled = state end end
    for obj, props in pairs(baseline.Props) do
        if obj then
            for prop, val in pairs(props) do
                pcall(function() obj[prop] = val end)
            end
        end
    end
    if blackFrame then blackFrame.Visible = false end
    if statusLabel then statusLabel.Text = "Estado: Restaurado" end
end

-- Silenciar todos los sonidos
function Optimizador.muteAll()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") then
            ensureSaved(s, {"Volume", "Playing"})
            s.Volume = 0
            s.Playing = false
        end
    end
end

-- Optimizar luces
function Optimizador.optimizeLights()
    for _, l in ipairs(Workspace:GetDescendants()) do
        if l:IsA("Light") then
            ensureSaved(l, {"Enabled", "Brightness", "Range"})
            l.Enabled = false
            l.Brightness = 0
            l.Range = 0
        end
    end
end

-- Limpiar partículas
function Optimizador.clearParticles()
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or
           p:IsA("Smoke") or p:IsA("Sparkles") or p:IsA("Fire") then
            ensureSaved(p, {"Enabled"})
            p.Enabled = false
        end
    end
end

-- Ocultar GUIs decorativos
function Optimizador.hideDecorGUIs()
    for g, _ in pairs(baseline.Guis) do
        if g then
            ensureSaved(g, {"Enabled"})
            g.Enabled = false
        end
    end
end

-- Optimizar materiales
function Optimizador.optimizeMaterials()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (part.Material == Enum.Material.Neon or part.Material == Enum.Material.Glass) then
            ensureSaved(part, {"Material"})
            part.Material = Enum.Material.SmoothPlastic
        elseif part:IsA("MeshPart") then
            ensureSaved(part, {"RenderFidelity"})
            pcall(function() part.RenderFidelity = Enum.RenderFidelity.Performance end)
        end
    end
end

-- Optimizar física de forma segura
function Optimizador.optimizePhysicsUltraSafe()
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

-- Pantalla negra ON/OFF
function Optimizador.toggleBlack()
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

-- Ultra+ (modo turbo)
function Optimizador.ultraRendimiento()
    Optimizador.applyProfile("Alto")
    Optimizador.muteAll()
    Optimizador.optimizeLights()
    Optimizador.clearParticles()
    if ultraHideGUIs then Optimizador.hideDecorGUIs() end
    Optimizador.optimizeMaterials()
    Optimizador.optimizePhysicsUltraSafe()

    Lighting.Technology = Enum.Technology.Compatibility
    Lighting.ShadowSoftness = 0
    Lighting.ColorShift_Bottom = Color3.new(0,0,0)
    Lighting.ColorShift_Top = Color3.new(0,0,0)
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSpeed = 0; terrain.WaterWaveSize = 0
        terrain.WaterTransparency = 1; terrain.WaterReflectance = 0
    end

    SoundService.RespectFilteringEnabled = false
    SoundService.AmbientReverb = Enum.ReverbType.Off

    if statusLabel then statusLabel.Text = "Estado: Ultra+ activado" end
    notify("Modo Turbo", "Ultra+ activado", 4)
end
-- ===== INTERFAZ GRÁFICA =====
function Optimizador.initGUI()
    snapshotAll() -- Guardar estado inicial al iniciar el GUI

    guiMain = Instance.new("ScreenGui")
    guiMain.Name = "OptimizadorGUI"
    guiMain.ResetOnSpawn = false
    guiMain.IgnoreGuiInset = true
    guiMain.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 320, 0, 240)
    panel.Position = UDim2.new(0.5, -160, 0.5, -120)
    panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    panel.BorderSizePixel = 0
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Parent = guiMain

    -- Barra de pestañas
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = panel

    local tabButtons, tabPages = {}, {}

    local function createTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 16
        btn.Text = name
        btn.Parent = tabBar
        table.insert(tabButtons, btn)

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 1, -30)
        page.Position = UDim2.new(0, 0, 0, 30)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = panel
        tabPages[name] = page

        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(tabPages) do p.Visible = false end
            for _, b in pairs(tabButtons) do b.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end
            page.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end)

        return page
    end

    local function createButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 30)
        btn.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 35)
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.Text = text
        btn.Parent = parent
        btn.MouseButton1Click:Connect(callback)
    end

    -- Pestaña: Optimizar
    local tabOpt = createTab("Optimizar")
    createButton(tabOpt, "Ultra+", Optimizador.ultraRendimiento)
    createButton(tabOpt, "Perfil: Bajo", function() Optimizador.applyProfile("Bajo") end)
    createButton(tabOpt, "Perfil: Medio", function() Optimizador.applyProfile("Medio") end)
    createButton(tabOpt, "Perfil: Alto", function() Optimizador.applyProfile("Alto") end)

    -- Pestaña: Reversión
    local tabRev = createTab("Reversión")
    createButton(tabRev, "Restaurar Todo", Optimizador.restoreAll)
    createButton(tabRev, "Mostrar/Ocultar Negro", Optimizador.toggleBlack)

    -- Pestaña: Avanzado
    local tabAdv = createTab("Avanzado")
    createButton(tabAdv, "Ocultar GUIs decorativos", Optimizador.hideDecorGUIs)
    createButton(tabAdv, "Optimizar materiales", Optimizador.optimizeMaterials)
    createButton(tabAdv, "Optimizar luces", Optimizador.optimizeLights)
    createButton(tabAdv, "Limpiar partículas", Optimizador.clearParticles)
    createButton(tabAdv, "Silenciar sonidos", Optimizador.muteAll)

    -- Activar la primera pestaña por defecto
    tabButtons[1].MouseButton1Click:Fire()
end
-- ===== FUNCIONES AVANZADAS =====

-- 🖱️ Arrastre libre del panel
function Optimizador.enableDrag(frame)
    local dragging, offset
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            offset = input.Position - frame.AbsolutePosition
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            frame.Position = UDim2.new(
                0,
                input.Position.X - offset.X,
                0,
                input.Position.Y - offset.Y
            )
        end
    end)
end

-- ⌨️ Atajos de teclado
function Optimizador.enableHotkeys()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.U then Optimizador.ultraRendimiento()
        elseif input.KeyCode == Enum.KeyCode.R then Optimizador.restoreAll()
        elseif input.KeyCode == Enum.KeyCode.N then Optimizador.toggleBlack() end
    end)
end

-- 🧠 Perfiles personalizados
Optimizador.customProfiles = {
    ["MiPerfil"] = function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e7
        Lighting.Brightness = 0.6
        Optimizador.optimizeMaterials()
        Optimizador.clearParticles()
    end
}

function Optimizador.applyCustomProfile(name)
    local profileFunc = Optimizador.customProfiles[name]
    if profileFunc then
        profileFunc()
        if statusLabel then
            statusLabel.Text = "Estado: " .. name
        end
    end
end

-- 🧪 Modo Auto inteligente
function Optimizador.enableAutoMode()
    local fpsBuffer = {}
    local lastCheck = tick()

    RunService.RenderStepped:Connect(function(dt)
        table.insert(fpsBuffer, 1/dt)
        if #fpsBuffer > 30 then table.remove(fpsBuffer, 1) end

        if tick() - lastCheck > 5 then
            local avgFps = 0
            for _, f in ipairs(fpsBuffer) do avgFps += f end
            avgFps /= #fpsBuffer
            if avgFps < 25 then
                Optimizador.ultraRendimiento()
            end
            lastCheck = tick()
        end
    end)
end

-- ===== CIERRE DEL MÓDULO =====
return Optimizador
