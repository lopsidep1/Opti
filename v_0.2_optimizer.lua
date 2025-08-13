-- Servicios
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
repeat task.wait() until player and player:FindFirstChild("PlayerGui")

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = dur or 5})
    end)
end

-- Estado inicial
local baseline = {
    Lighting = {}, Sound = {}, Terrain = {}, Streaming = {},
    Guis = {}, Props = {}
}
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
    local okE, enabled = pcall(function() return Workspace.StreamingEnabled end)
    if okE then baseline.Streaming.Enabled = enabled end
    local okM, minR = pcall(function() return Workspace.StreamingMinRadius end)
    if okM then baseline.Streaming.Min = minR end
    local okT, tgtR = pcall(function() return Workspace.StreamingTargetRadius end)
    if okT then baseline.Streaming.Target = tgtR end
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

-- Variables de estado
local guiMain, frame, statusLabel, fpsLabel, memLabel, blackFrame
local dragEnabled, autoMode = true, false
local currentProfile = "Medio"
local avgDt = 1/60
local avgFps = 60
local lastAutoClean = tick()
local autoCleanInterval = 180
local ultraHideGUIs = false
local streamerMode = false
local autoRestore = true

-- Funciones de optimización
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
    statusLabel.Text = ("Estado: Activo (%s%s)"):format(name, autoMode and " - Auto" or "")
end

local function restoreAll()
    for k, v in pairs(baseline.Lighting) do Lighting[k] = v end
    for k, v in pairs(baseline.Sound) do SoundService[k] = v end
    if baseline.Streaming.Enabled ~= nil then pcall(function() Workspace.StreamingEnabled = baseline.Streaming.Enabled end) end
    if baseline.Streaming.Min ~= nil then pcall(function() Workspace.StreamingMinRadius = baseline.Streaming.Min end) end
    if baseline.Streaming.Target ~= nil then pcall(function() Workspace.StreamingTargetRadius = baseline.Streaming.Target end) end
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then for k, v in pairs(baseline.Terrain) do t[k] = v end end
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
        if g then
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

local function hasHumanoidAncestor(inst)
    local a = inst
    while a do
        if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
        a = a.Parent
    end
    return false
end

local function optimizePhysicsUltraSafe()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not hasHumanoidAncestor(part) then
            local keepCollision = false
            if part.Name:lower() == "baseplate" then
                keepCollision = true
            end
            if root and (part.Position.Y < root.Position.Y) and ((root.Position - part.Position).Magnitude < 20) then
                keepCollision = true
            end
            if not keepCollision and part.AssemblyLinearVelocity.Magnitude < 0.01 then
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

-- Snapshot inicial
snapshotAll()
statusLabel.Text = "Estado: Inactivo — elige un perfil o usa Auto"
notify("Modo Turbo", "Panel PRO listo (F1 oculta/muestra)", 4)
