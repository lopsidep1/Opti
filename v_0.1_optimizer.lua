-- MODO TURBO ULTRA+ PRO — Optimización máxima, reversible, adaptativa y con mejoras avanzadas

-- Servicios
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = dur or 5})
    end)
end

repeat task.wait() until game:IsLoaded()
local player = Players.LocalPlayer
repeat task.wait() until player and player:FindFirstChild("PlayerGui")

local baseline = {
    Lighting = {}, Sound = {}, Terrain = {}, Streaming = {},
    Guis = {}, Props = {}
}
local guiMain, frame, statusLabel, fpsLabel, memLabel, blackFrame, statsLabel, pingLabel, objectCountLabel, anticheatLabel
local dragEnabled, autoMode = true, false
local currentProfile = "Medio"
local avgDt = 1/60
local avgFps = 60
local lastAutoClean = tick()
local autoCleanInterval = 180 -- 3 min
local colorThemes = {
    ["Oscuro"] = {main = Color3.fromRGB(25,25,25), accent = Color3.fromRGB(50,50,70)},
    ["Claro"]  = {main = Color3.fromRGB(200,200,220), accent = Color3.fromRGB(170,170,220)},
    ["Neon"]   = {main = Color3.fromRGB(0,20,40), accent = Color3.fromRGB(0,255,150)},
}
local currentTheme = "Oscuro"
local ultraHideGUIs = false
local streamerMode = false
local autoRestore = true

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

local function hasHumanoidAncestor(inst)
    local a = inst
    while a do
        if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
        a = a.Parent
    end
    return false
end

local function optimizePhysicsUltraSafe()
    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not hasHumanoidAncestor(part) then
            local keepCollision = false
            if part.Name == "Baseplate" or part.Name == "baseplate" then
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

local function disableShadowsEverywhere()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            ensureSaved(part, {"CastShadow"})
            part.CastShadow = false
        end
    end
end

local function blankDecorTextures()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Decal") or d:IsA("Texture") then
            ensureSaved(d, {"Texture"})
            d.Texture = ""
        end
    end
end

local function disableSurfaceAndBillboards()
    for _, g in ipairs(Workspace:GetDescendants()) do
        if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
            ensureSaved(g, {"Enabled"})
            g.Enabled = false
        end
    end
end

local function hideAccessoriesAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, acc in ipairs(char:GetChildren()) do
                if acc:IsA("Accessory") then
                    ensureSaved(acc, {"Parent"})
                    acc.Parent = nil
                end
            end
        end
    end
end

local function killCameraEffects()
    local cam = workspace.CurrentCamera
    for _, v in ipairs(cam:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
end

local function muteMusic()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") and s.Name:lower():find("music") then
            ensureSaved(s, {"Volume", "Playing"})
            s.Volume = 0
            s.Playing = false
        end
    end
end

local function muteEffects()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") and not s.Name:lower():find("music") then
            ensureSaved(s, {"Volume", "Playing"})
            s.Volume = 0
            s.Playing = false
        end
    end
end

local function boostImportantSounds()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") and s.Name:lower():find("important") then
            ensureSaved(s, {"Volume"})
            s.Volume = 1
        end
    end
end

local function setStreamerMode(on)
    streamerMode = on
    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = on and 1 or 0
            end
        end
    end
    local chat = player.PlayerGui:FindFirstChild("Chat")
    if chat then chat.Enabled = not on end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local c = p.Character
            if c then for _, part in ipairs(c:GetDescendants()) do if part:IsA("BasePart") then part.Transparency = on and 1 or 0 end end end
        end
    end
end

local function killLocalAnticheats()
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") and tostring(v.Name):lower():find("anti") then
            pcall(function() v.Disabled = true end)
            found = found + 1
        end
    end
    notify("Modo Turbo", "Anticheats locales desactivados: "..found, 4)
end

local function showAnticheatStatus()
    local running = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") and tostring(v.Name):lower():find("anti") and v.Enabled then
            running = running + 1
        end
    end
    anticheatLabel.Text = "Anticheat local activo: " .. running
    anticheatLabel.TextColor3 = running > 0 and Color3.new(1,0.3,0.3) or Color3.new(0.3,1,0.3)
end

local function autoClean()
    clearParticles()
    blankDecorTextures()
    disableSurfaceAndBillboards()
    hideAccessoriesAllPlayers()
    optimizeMaterials()
    collectgarbage("collect")
    notify("Modo Turbo", "Auto-clean ejecutado", 2)
end

local function autoRestoreOnRespawn()
    player.CharacterAdded:Connect(function()
        if autoRestore then
            task.wait(2)
            applyProfile(currentProfile)
            if ultraHideGUIs then hideDecorGUIs() end
            statusLabel.Text = "Estado: Restaurado tras respawn"
        end
    end)
end

local function switchTheme(theme)
    if not colorThemes[theme] then return end
    currentTheme = theme
    frame.BackgroundColor3 = colorThemes[theme].main
    ultraGuiSwitch.BackgroundColor3 = colorThemes[theme].accent
    statsLabel.TextColor3 = colorThemes[theme].accent
end

local function unlockFPS(val)
    local ok, msg = pcall(function()
        if settings().Rendering.FramerateCap then
            settings().Rendering.FramerateCap = val
        end
    end)
    notify("Modo Turbo", ok and ("FPS cap: "..tostring(val)) or ("No soportado: "..msg), 3)
end

-- Ultra+ con opción para ocultar GUIs o no
local function ultraRendimiento()
    applyProfile("Alto")
    muteAll()
    optimizeLights()
    clearParticles()
    if ultraHideGUIs then
        hideDecorGUIs()
    end
    optimizeMaterials()
    optimizePhysicsUltraSafe()
    disableShadowsEverywhere()
    disableSurfaceAndBillboards()
    blankDecorTextures()
    hideAccessoriesAllPlayers()
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

-- GUI principal y pestañas dinámicas + candado/cerrar + scroll horizontal + draggable bot flotante y negro
guiMain = Instance.new("ScreenGui")
guiMain.Name = "TurboPanel"
guiMain.ResetOnSpawn = false
guiMain.IgnoreGuiInset = false
guiMain.Parent = player:WaitForChild("PlayerGui")

local FRAME_WIDTH = 460
local TITLE_HEIGHT = 28
frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(FRAME_WIDTH, 660)
frame.Position = UDim2.fromOffset(20, 60)
frame.BackgroundColor3 = colorThemes[currentTheme].main
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = guiMain
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0, TITLE_HEIGHT)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Text = "Modo Turbo Optimizer PRO"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local lockBtn = Instance.new("ImageButton")
lockBtn.Size = UDim2.fromOffset(32, 32)
lockBtn.AnchorPoint = Vector2.new(1, 0)
lockBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 44, 8)
lockBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
lockBtn.BorderSizePixel = 2
lockBtn.BorderColor3 = Color3.fromRGB(80,80,80)
lockBtn.Image = "rbxassetid://6031107728"
lockBtn.Parent = frame
lockBtn.ZIndex = 1000
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0.5,0)

local lockText = Instance.new("TextLabel")
lockText.Size = UDim2.new(1, 0, 1, 0)
lockText.BackgroundTransparency = 1
lockText.Text = "🔒"
lockText.TextScaled = true
lockText.Font = Enum.Font.GothamBold
lockText.TextColor3 = Color3.new(1,1,1)
lockText.Parent = lockBtn
lockText.ZIndex = 1001
lockText.Visible = false

lockBtn:GetPropertyChangedSignal("Image"):Connect(function()
    if lockBtn.Image == "" or lockBtn.ImageRectSize == Vector2.new(0,0) then
        lockText.Visible = true
    else
        lockText.Visible = false
    end
end)

local locked = false
local function updateLockIcon()
    if locked then
        lockBtn.Image = "rbxassetid://6031107735"
        lockText.Text = "🔒"
    else
        lockBtn.Image = "rbxassetid://6031107728"
        lockText.Text = "🔓"
    end
end
updateLockIcon()
lockBtn.MouseButton1Click:Connect(function()
    locked = not locked
    dragEnabled = not locked
    updateLockIcon()
end)

local closeBtn = Instance.new("ImageButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 8, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
closeBtn.BorderSizePixel = 2
closeBtn.BorderColor3 = Color3.fromRGB(80,80,80)
closeBtn.Image = "rbxassetid://6031094678"
closeBtn.Parent = frame
closeBtn.ZIndex = 1000
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5,0)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    openBtn.Visible = true
end)

local openBtn = Instance.new("ImageButton")
openBtn.Size = UDim2.fromOffset(42, 42)
openBtn.Position = UDim2.fromOffset(60, 300)
openBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
openBtn.Image = "rbxassetid://6031094678"
openBtn.Parent = guiMain
openBtn.Visible = false
openBtn.ZIndex = 10000
openBtn.Name = "OpenBtn"
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1,0)
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    openBtn.Visible = false
end)

local blackBtn = Instance.new("TextButton")
blackBtn.Size = UDim2.fromOffset(42, 42)
blackBtn.Position = UDim2.fromOffset(120, 300)
blackBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
blackBtn.Text = "🌙"
blackBtn.TextScaled = true
blackBtn.TextColor3 = Color3.new(1,1,1)
blackBtn.Font = Enum.Font.GothamBold
blackBtn.Parent = guiMain
blackBtn.Visible = true
blackBtn.ZIndex = 10000
blackBtn.Name = "BlackBtn"
Instance.new("UICorner", blackBtn).CornerRadius = UDim.new(1,0)
blackBtn.MouseButton1Click:Connect(toggleBlack)

local function makeDraggable(btn)
    local dragging = false
    local dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                local newPos = UDim2.fromOffset(
                    startPos.X.Offset + delta.X,
                    startPos.Y.Offset + delta.Y
                )
                btn.Position = newPos
            end
        end
    end)
end
makeDraggable(openBtn)
makeDraggable(blackBtn)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 24)
statusLabel.Position = UDim2.fromOffset(5, TITLE_HEIGHT+12)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Estado: Inactivo"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.Parent = frame

fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, -10, 0, 24)
fpsLabel.Position = UDim2.fromOffset(5, TITLE_HEIGHT+38)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: ..."
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.Gotham
fpsLabel.Parent = frame

memLabel = Instance.new("TextLabel")
memLabel.Size = UDim2.new(1, -10, 0, 24)
memLabel.Position = UDim2.fromOffset(5, TITLE_HEIGHT+62)
memLabel.BackgroundTransparency = 1
memLabel.Text = "Mem (Lua): ..."
memLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
memLabel.TextScaled = true
memLabel.Font = Enum.Font.Gotham
memLabel.Parent = frame

-- Panel de diagnóstico avanzado
statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1,-10,0,22)
statsLabel.Position = UDim2.fromOffset(5, TITLE_HEIGHT+86)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Ping: ... | Partes: ... | Luz: ... | Partículas: ..."
statsLabel.TextColor3 = colorThemes[currentTheme].accent
statsLabel.TextScaled = true
statsLabel.Font = Enum.Font.Gotham
statsLabel.Parent = frame

pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(0.5,-20,0,22)
pingLabel.Position = UDim2.fromOffset(5, TITLE_HEIGHT+110)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "Ping: ..."
pingLabel.TextColor3 = Color3.fromRGB(180,255,180)
pingLabel.TextScaled = true
pingLabel.Font = Enum.Font.Gotham
pingLabel.Parent = frame

objectCountLabel = Instance.new("TextLabel")
objectCountLabel.Size = UDim2.new(0.5,-20,0,22)
objectCountLabel.Position = UDim2.fromOffset(FRAME_WIDTH/2, TITLE_HEIGHT+110)
objectCountLabel.BackgroundTransparency = 1
objectCountLabel.Text = "Objetos: ..."
objectCountLabel.TextColor3 = Color3.fromRGB(180,220,255)
objectCountLabel.TextScaled = true
objectCountLabel.Font = Enum.Font.Gotham
objectCountLabel.Parent = frame

anticheatLabel = Instance.new("TextLabel")
anticheatLabel.Size = UDim2.new(1,-10,0,20)
anticheatLabel.Position = UDim2.fromOffset(5, TITLE_HEIGHT+134)
anticheatLabel.BackgroundTransparency = 1
anticheatLabel.Text = "Anticheat local: ..."
anticheatLabel.TextColor3 = Color3.fromRGB(220,220,220)
anticheatLabel.TextScaled = true
anticheatLabel.Font = Enum.Font.Gotham
anticheatLabel.Parent = frame

-- Switch para GUIs en Ultra+
local ultraGuiSwitch = Instance.new("TextButton")
ultraGuiSwitch.Size = UDim2.new(0, 180, 0, 32)
ultraGuiSwitch.Position = UDim2.fromOffset(5, TITLE_HEIGHT+160)
ultraGuiSwitch.BackgroundColor3 = colorThemes[currentTheme].accent
ultraGuiSwitch.Text = "Ocultar GUIs en Ultra+: OFF"
ultraGuiSwitch.TextScaled = true
ultraGuiSwitch.Font = Enum.Font.GothamBold
ultraGuiSwitch.TextColor3 = Color3.fromRGB(255,255,255)
ultraGuiSwitch.Parent = frame
Instance.new("UICorner", ultraGuiSwitch).CornerRadius = UDim.new(0, 8)
ultraGuiSwitch.MouseButton1Click:Connect(function()
    ultraHideGUIs = not ultraHideGUIs
    ultraGuiSwitch.Text = "Ocultar GUIs en Ultra+: " .. (ultraHideGUIs and "ON" or "OFF")
end)

-- Selector de color/tema
local themeDropdown = Instance.new("TextButton")
themeDropdown.Size = UDim2.new(0, 180, 0, 32)
themeDropdown.Position = UDim2.fromOffset(210, TITLE_HEIGHT+160)
themeDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
themeDropdown.Text = "Tema: "..currentTheme
themeDropdown.TextScaled = true
themeDropdown.Font = Enum.Font.GothamBold
themeDropdown.TextColor3 = Color3.new(1,1,1)
themeDropdown.Parent = frame
Instance.new("UICorner", themeDropdown).CornerRadius = UDim.new(0,8)
themeDropdown.MouseButton1Click:Connect(function()
    local tnames = {}
    for k,_ in pairs(colorThemes) do table.insert(tnames, k) end
    local nextIdx = table.find(tnames, currentTheme) and (table.find(tnames, currentTheme)%#tnames + 1) or 1
    switchTheme(tnames[nextIdx])
    themeDropdown.Text = "Tema: "..tnames[nextIdx]
end)

-- Botón modo streamer
local streamerBtn = Instance.new("TextButton")
streamerBtn.Size = UDim2.new(0, 180, 0, 32)
streamerBtn.Position = UDim2.fromOffset(5, TITLE_HEIGHT+200)
streamerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
streamerBtn.Text = "Modo Streamer: OFF"
streamerBtn.TextScaled = true
streamerBtn.Font = Enum.Font.GothamBold
streamerBtn.TextColor3 = Color3.new(1,1,1)
streamerBtn.Parent = frame
Instance.new("UICorner", streamerBtn).CornerRadius = UDim.new(0,8)
streamerBtn.MouseButton1Click:Connect(function()
    streamerMode = not streamerMode
    setStreamerMode(streamerMode)
    streamerBtn.Text = "Modo Streamer: " .. (streamerMode and "ON" or "OFF")
end)

-- Botón de pánico
local panicBtn = Instance.new("TextButton")
panicBtn.Size = UDim2.new(0, 180, 0, 32)
panicBtn.Position = UDim2.fromOffset(210, TITLE_HEIGHT+200)
panicBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
panicBtn.Text = "¡Botón de Pánico!"
panicBtn.TextScaled = true
panicBtn.Font = Enum.Font.GothamBold
panicBtn.TextColor3 = Color3.new(1,1,1)
panicBtn.Parent = frame
Instance.new("UICorner", panicBtn).CornerRadius = UDim.new(0,8)
panicBtn.MouseButton1Click:Connect(function()
    restoreAll()
    guiMain.Enabled = false
    notify("Modo Turbo", "¡Restaurado y panel oculto!", 3)
end)

-- Botón kill efectos de cámara
local killCamBtn = Instance.new("TextButton")
killCamBtn.Size = UDim2.new(0, 180, 0, 32)
killCamBtn.Position = UDim2.fromOffset(5, TITLE_HEIGHT+240)
killCamBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 70)
killCamBtn.Text = "Quitar efectos de cámara"
killCamBtn.TextScaled = true
killCamBtn.Font = Enum.Font.GothamBold
killCamBtn.TextColor3 = Color3.fromRGB(255,255,255)
killCamBtn.Parent = frame
Instance.new("UICorner", killCamBtn).CornerRadius = UDim.new(0, 8)
killCamBtn.MouseButton1Click:Connect(function()
    killCameraEffects()
    notify("Turbo", "Efectos de cámara quitados", 3)
end)

-- Botón anticheat local
local killACBtn = Instance.new("TextButton")
killACBtn.Size = UDim2.new(0, 180, 0, 32)
killACBtn.Position = UDim2.fromOffset(210, TITLE_HEIGHT+240)
killACBtn.BackgroundColor3 = Color3.fromRGB(80,60,60)
killACBtn.Text = "Desactivar Anticheats"
killACBtn.TextScaled = true
killACBtn.Font = Enum.Font.GothamBold
killACBtn.TextColor3 = Color3.new(1,1,1)
killACBtn.Parent = frame
Instance.new("UICorner", killACBtn).CornerRadius = UDim.new(0,8)
killACBtn.MouseButton1Click:Connect(killLocalAnticheats)

-- Botón FPS unlocker
local unlockFPSBtn = Instance.new("TextButton")
unlockFPSBtn.Size = UDim2.new(0, 180, 0, 32)
unlockFPSBtn.Position = UDim2.fromOffset(5, TITLE_HEIGHT+280)
unlockFPSBtn.BackgroundColor3 = Color3.fromRGB(50,100,50)
unlockFPSBtn.Text = "FPS Unlocker (120)"
unlockFPSBtn.TextScaled = true
unlockFPSBtn.Font = Enum.Font.GothamBold
unlockFPSBtn.TextColor3 = Color3.new(1,1,1)
unlockFPSBtn.Parent = frame
Instance.new("UICorner", unlockFPSBtn).CornerRadius = UDim.new(0,8)
unlockFPSBtn.MouseButton1Click:Connect(function() unlockFPS(120) end)

-- Botón auto-clean manual
local autoCleanBtn = Instance.new("TextButton")
autoCleanBtn.Size = UDim2.new(0, 180, 0, 32)
autoCleanBtn.Position = UDim2.fromOffset(210, TITLE_HEIGHT+280)
autoCleanBtn.BackgroundColor3 = Color3.fromRGB(40,100,140)
autoCleanBtn.Text = "Auto-Clean Manual"
autoCleanBtn.TextScaled = true
autoCleanBtn.Font = Enum.Font.GothamBold
autoCleanBtn.TextColor3 = Color3.new(1,1,1)
autoCleanBtn.Parent = frame
Instance.new("UICorner", autoCleanBtn).CornerRadius = UDim.new(0,8)
autoCleanBtn.MouseButton1Click:Connect(autoClean)

-- Botón mute música
local muteMusicBtn = Instance.new("TextButton")
muteMusicBtn.Size = UDim2.new(0, 180, 0, 32)
muteMusicBtn.Position = UDim2.fromOffset(5, TITLE_HEIGHT+320)
muteMusicBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 90)
muteMusicBtn.Text = "Mute Música"
muteMusicBtn.TextScaled = true
muteMusicBtn.Font = Enum.Font.GothamBold
muteMusicBtn.TextColor3 = Color3.new(1,1,1)
muteMusicBtn.Parent = frame
Instance.new("UICorner", muteMusicBtn).CornerRadius = UDim.new(0,8)
muteMusicBtn.MouseButton1Click:Connect(muteMusic)

local muteEffectsBtn = Instance.new("TextButton")
muteEffectsBtn.Size = UDim2.new(0, 180, 0, 32)
muteEffectsBtn.Position = UDim2.fromOffset(210, TITLE_HEIGHT+320)
muteEffectsBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
muteEffectsBtn.Text = "Mute Efectos"
muteEffectsBtn.TextScaled = true
muteEffectsBtn.Font = Enum.Font.GothamBold
muteEffectsBtn.TextColor3 = Color3.new(1,1,1)
muteEffectsBtn.Parent = frame
Instance.new("UICorner", muteEffectsBtn).CornerRadius = UDim.new(0,8)
muteEffectsBtn.MouseButton1Click:Connect(muteEffects)

-- Botón boost sonidos importantes
local boostSoundsBtn = Instance.new("TextButton")
boostSoundsBtn.Size = UDim2.new(0, 180, 0, 32)
boostSoundsBtn.Position = UDim2.fromOffset(5, TITLE_HEIGHT+360)
boostSoundsBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 255)
boostSoundsBtn.Text = "Boost Sonidos Importantes"
boostSoundsBtn.TextScaled = true
boostSoundsBtn.Font = Enum.Font.GothamBold
boostSoundsBtn.TextColor3 = Color3.new(1,1,1)
boostSoundsBtn.Parent = frame
Instance.new("UICorner", boostSoundsBtn).CornerRadius = UDim.new(0,8)
boostSoundsBtn.MouseButton1Click:Connect(boostImportantSounds)

-- Botón auto-restore
local autoRestoreBtn = Instance.new("TextButton")
autoRestoreBtn.Size = UDim2.new(0, 180, 0, 32)
autoRestoreBtn.Position = UDim2.fromOffset(210, TITLE_HEIGHT+360)
autoRestoreBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
autoRestoreBtn.Text = "Auto-Restore al respawn: ON"
autoRestoreBtn.TextScaled = true
autoRestoreBtn.Font = Enum.Font.GothamBold
autoRestoreBtn.TextColor3 = Color3.new(1,1,1)
autoRestoreBtn.Parent = frame
Instance.new("UICorner", autoRestoreBtn).CornerRadius = UDim.new(0,8)
autoRestoreBtn.MouseButton1Click:Connect(function()
    autoRestore = not autoRestore
    autoRestoreBtn.Text = "Auto-Restore al respawn: " .. (autoRestore and "ON" or "OFF")
end)
autoRestoreOnRespawn()

-- Sistema de pestañas (simplificado: solo sección Ultra+ y restaurar)
local tabs = {
    ["🚀 Ultra+"] = {
        {Text = "Ultra+ activado", Callback = ultraRendimiento}
    },
    ["🔄 Restaurar"] = {
        {Text = "Restaurar todo", Callback = restoreAll}
    }
}
local tabButtons, tabFrames, tabHeights = {}, {}, {}
local tabY = TITLE_HEIGHT+410
local tabHeight = 30
local tabSpacing = 5
local contentY = tabY + tabHeight + 10
local minHeight = 180

local tabsBar = Instance.new("Frame")
tabsBar.Size = UDim2.new(1, -20, 0, tabHeight + 10)
tabsBar.Position = UDim2.fromOffset(10, tabY)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = frame
tabsBar.ClipsDescendants = true

local tabsScroll = Instance.new("ScrollingFrame")
tabsScroll.Size = UDim2.new(1, 0, 1, 0)
tabsScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
tabsScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabsScroll.ScrollBarThickness = 5
tabsScroll.BackgroundTransparency = 1
tabsScroll.Parent = tabsBar
tabsScroll.BorderSizePixel = 0
tabsScroll.ZIndex = 20

local tabsList = Instance.new("UIListLayout")
tabsList.FillDirection = Enum.FillDirection.Horizontal
tabsList.Padding = UDim.new(0, tabSpacing)
tabsList.SortOrder = Enum.SortOrder.LayoutOrder
tabsList.Parent = tabsScroll

for tabName, actions in pairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 160, 1, -10)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.new(1, 1, 1)
    tabBtn.TextScaled = true
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.Parent = tabsScroll
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)
    table.insert(tabButtons, tabBtn)

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -20, 1, -contentY - 10)
    tabFrame.Position = UDim2.fromOffset(10, contentY)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = frame
    tabFrames[tabName] = tabFrame

    local totalBtnHeight = 0
    for i, action in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.fromOffset(0, (i - 1) * 35)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Text = action.Text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Font = Enum.Font.Gotham
        btn.Parent = tabFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            if action.Callback then
                local ok, err = pcall(function() action.Callback(btn) end)
                if not ok then
                    warn("[Modo Turbo] Error en botón:", err)
                    notify("Modo Turbo", "Error en " .. action.Text, 3)
                end
            end
        end)
        totalBtnHeight = totalBtnHeight + 35
    end
    tabHeights[tabName] = math.max(minHeight, contentY + totalBtnHeight + 20)
end

tabsScroll.CanvasSize = UDim2.new(0, tabsList.AbsoluteContentSize.X, 1, 0)

local function showTab(tabName)
    for name, tab in pairs(tabFrames) do
        tab.Visible = (name == tabName)
    end
    local newHeight = tabHeights[tabName] or minHeight
    frame.Size = UDim2.fromOffset(FRAME_WIDTH, newHeight)
    lockBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 44, 8)
    closeBtn.Position = UDim2.fromOffset(FRAME_WIDTH - 8, 8)
end

for _, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        showTab(btn.Text)
    end)
end

showTab(tabButtons[1].Text)

dragEnabled = true
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

        -- Diagnóstico avanzado
        local ping = "?"
        pcall(function()
            local stats = workspace:FindFirstChild("Stats")
            if stats and stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerTime") then
                ping = tostring(math.floor(stats.Network.ServerTime.Value*1000))
            end
        end)
        pingLabel.Text = "Ping: " .. ping .. " ms"

        local parts, lights, particles = 0, 0, 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then parts = parts + 1 end
            if d:IsA("Light") then lights = lights + 1 end
            if d:IsA("ParticleEmitter") then particles = particles + 1 end
        end
        objectCountLabel.Text = ("Objetos: %d | Luz: %d | Partículas: %d"):format(parts, lights, particles)
        statsLabel.Text = ("Ping: %s | Partes: %d | Luz: %d | Partículas: %d"):format(ping, parts, lights, particles)

        showAnticheatStatus()

        if tick()-lastAutoClean > autoCleanInterval then
            autoClean()
            lastAutoClean = tick()
        end

        task.wait(0.5)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        frame.Visible = not frame.Visible
        openBtn.Visible = not frame.Visible
    elseif input.KeyCode == Enum.KeyCode.B then
        toggleBlack()
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

snapshotAll()
statusLabel.Text = "Estado: Inactivo — elige un perfil o usa Auto"
print("[Modo Turbo] PRO Cargado. F1: mostrar/ocultar, B: pantalla negra.")
notify("Modo Turbo", "Panel PRO listo (F1 oculta/muestra)", 4)
