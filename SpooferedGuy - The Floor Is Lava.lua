local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "EnygmaXIT, by Enygma",
    Icon = 95163525434706,
    LoadingTitle = "EnygmaXIT",
    LoadingSubtitle = "by Enygma",
    ShowText = "⬇️",
    Theme = "Black",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {Enabled = false, FolderName = nil, FileName = "EnygmaXIT"}
})

-- Tabs
local FarmTab = Window:CreateTab("Farm🌋", 95163525434706)
local PlayerTab = Window:CreateTab("Player👤", 95163525434706)
local TrollTab = Window:CreateTab("Troll🗿", 95163525434706)
local TeleportTab = Window:CreateTab("Teleports🤷‍♀️", 95163525434706)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

--==================================================
-- AUTO COIN
--==================================================

local coinsAtivas = false
local coins = {}

local function configurarCoin(part)
    if part:IsA("BasePart") and part.Name:lower():find("coin") then
        if not coins[part] then
            coins[part] = {
                Size = part.Size,
                Transparency = part.Transparency,
                CanCollide = part.CanCollide
            }

            part.CanCollide = false
            part.Transparency = 1
        end
    end
end

FarmTab:CreateToggle({
    Name = "AutoCoin",
    CurrentValue = false,
    Flag = "CoinFarm",

    Callback = function(Value)
        coinsAtivas = Value

        if Value then
            for _, part in ipairs(Workspace:GetDescendants()) do
                configurarCoin(part)
            end
        else
            for part, dados in pairs(coins) do
                if part and part.Parent then
                    part.Size = dados.Size
                    part.Transparency = dados.Transparency
                    part.CanCollide = dados.CanCollide
                end
            end

            coins = {}
        end
    end
})

Workspace.DescendantAdded:Connect(function(part)
    if coinsAtivas then
        task.wait()
        configurarCoin(part)
    end
end)

RunService.RenderStepped:Connect(function()
    if not coinsAtivas then
        return
    end

    for part in pairs(coins) do
        if part and part.Parent then
            part.Size = part.Size + Vector3.new(50, 50, 50)
        else
            coins[part] = nil
        end
    end
end)

--==================================================
-- ANTI-TELEPORT (integração com os toggles)
--==================================================
local RunService = game:GetService("RunService")

-- Posição bloqueada
local BLOCKED_POSITION = Vector3.new(2, 67, -241)
local BLOCK_RADIUS = 5

-- Controla se o anti-TP está ativo
local antiTpAtivo = false
local antiTpConnection = nil
local ultimaPosicaoSegura = nil

local function iniciarAntiTp()
    if antiTpAtivo then
        return
    end

    antiTpAtivo = true
    ultimaPosicaoSegura = nil

    antiTpConnection = RunService.Heartbeat:Connect(function()
        if not antiTpAtivo then
            return
        end

        local character = player.Character
        if not character then
            return
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        local currentPos = root.Position
        local distancia = (currentPos - BLOCKED_POSITION).Magnitude

        if distancia <= BLOCK_RADIUS then
            -- Reverte para a última posição segura (ou empurra pra cima)
            if ultimaPosicaoSegura then
                root.CFrame = CFrame.new(ultimaPosicaoSegura)
            else
                root.CFrame = CFrame.new(
                    BLOCKED_POSITION.X,
                    BLOCKED_POSITION.Y + 50,
                    BLOCKED_POSITION.Z
                )
            end
        else
            ultimaPosicaoSegura = currentPos
        end
    end)
end

local function pararAntiTp()
    if not antiTpAtivo then
        return
    end

    antiTpAtivo = false

    if antiTpConnection then
        antiTpConnection:Disconnect()
        antiTpConnection = nil
    end

    ultimaPosicaoSegura = nil
end

--==================================================
-- AUTO PARKOUR
--==================================================

local heads = {}
local finishes = {}
local loopAtivo = false
local finishLoopAtivo = false
local toolAtual = nil
local loopId = 0

local function encontrarHeads()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Head" then
            local pertenceAoPlayer = false

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and obj:IsDescendantOf(plr.Character) then
                    pertenceAoPlayer = true
                    break
                end
            end

            if not pertenceAoPlayer and not heads[obj] then
                heads[obj] = {
                    Size = obj.Size,
                    CanCollide = obj.CanCollide,
                    Transparency = obj.Transparency
                }
            end
        end
    end
end

local function encontrarFinishes()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Finish" and not finishes[obj] then
            finishes[obj] = {
                Size = obj.Size,
                CanCollide = obj.CanCollide,
                Transparency = obj.Transparency
            }
        end
    end
end

local function encontrarPush()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name == "Push" then
            return obj
        end
    end

    return nil
end

local function darPush()
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character

    if toolAtual and toolAtual.Parent then
        return toolAtual
    end

    if character then
        local push = character:FindFirstChild("Push")

        if push and push:IsA("Tool") then
            toolAtual = push
            return push
        end
    end

    local pushNoBackpack = backpack:FindFirstChild("Push")

    if pushNoBackpack and pushNoBackpack:IsA("Tool") then
        toolAtual = pushNoBackpack
        return pushNoBackpack
    end

    local pushOriginal = encontrarPush()

    if pushOriginal then
        local copia = pushOriginal:Clone()
        copia.Parent = backpack
        toolAtual = copia
        return copia
    end

    return nil
end

local function loopDeveRodar()
    return loopAtivo or finishLoopAtivo
end

-- Atualiza o estado do anti-TP baseado nos dois toggles
local function atualizarAntiTp()
    if loopDeveRodar() then
        iniciarAntiTp()
    else
        pararAntiTp()
    end
end

local function equiparLoop()
    loopId += 1
    local meuLoop = loopId

    task.spawn(function()
        while loopDeveRodar() and meuLoop == loopId do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                local push = darPush()

                if push and push.Parent then
                    toolAtual = push

                    humanoid:EquipTool(push)

                    task.wait(0.1)

                    if not loopDeveRodar() or meuLoop ~= loopId then
                        break
                    end

                    humanoid:UnequipTools()

                    task.wait(0.1)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.5)
            end
        end
    end)
end

player.CharacterAdded:Connect(function(character)
    if not loopDeveRodar() then
        return
    end

    toolAtual = nil

    character:WaitForChild("Humanoid", 10)
    task.wait(1)

    if loopDeveRodar() then
        darPush()
    end
end)

encontrarHeads()
encontrarFinishes()

FarmTab:CreateToggle({
    Name = "Infinite Points Farm",
    CurrentValue = false,
    Flag = "AutoParkour",

    Callback = function(Value)
        loopAtivo = Value
        encontrarHeads()

        if Value then

            for obj, original in pairs(heads) do
                if obj and obj.Parent then
                    obj.Size = original.Size + Vector3.new(9999, 9999, 9999)
                    obj.CanCollide = false
                    obj.Transparency = 1
                end
            end

            toolAtual = nil
            darPush()

            if not finishLoopAtivo then
                equiparLoop()
            end

        else

            for obj, original in pairs(heads) do
                if obj and obj.Parent then
                    obj.Size = original.Size
                    obj.CanCollide = original.CanCollide
                    obj.Transparency = original.Transparency
                end
            end

            if not finishLoopAtivo then
                loopId += 1
                toolAtual = nil
            end
        end

        -- Atualiza anti-TP
        atualizarAntiTp()
    end
})

-- ================= Services =================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================= Name ESP =================
local nameESPEnabled = false
local nameESPObjects = {}

local function RemoveNameESP(Player)
    local Billboard = nameESPObjects[Player]

    if Billboard then
        Billboard:Destroy()
        nameESPObjects[Player] = nil
    end
end

local function AddNameESP(Player)
    -- Nunca adicionar ESP no LocalPlayer
    if Player == LocalPlayer then
        return
    end

    if not nameESPEnabled then
        return
    end

    local Character = Player.Character
    if not Character then
        return
    end

    local Head = Character:FindFirstChild("Head")
    if not Head then
        return
    end

    -- Remove qualquer ESP antigo
    RemoveNameESP(Player)

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "NameESP"
    Billboard.Adornee = Head
    Billboard.Size = UDim2.new(0, 120, 0, 25)
    Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Head

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.fromScale(1, 1)
    Text.BackgroundTransparency = 1
    Text.Text = Player.Name
    Text.TextColor3 = Color3.fromRGB(255, 0, 0)
    Text.TextStrokeTransparency = 0
    Text.TextScaled = true
    Text.Font = Enum.Font.SourceSansBold
    Text.Parent = Billboard

    nameESPObjects[Player] = Billboard
end

-- ================= Setup Player =================
local function SetupPlayer(Player)
    -- Não configurar o próprio jogador
    if Player == LocalPlayer then
        return
    end

    -- Quando o jogador nascer ou renascer
    Player.CharacterAdded:Connect(function(Character)
        if not nameESPEnabled then
            return
        end

        local Head = Character:WaitForChild("Head", 5)

        if Head and nameESPEnabled then
            task.wait(0.1)
            AddNameESP(Player)
        end
    end)

    -- Se o jogador já estiver vivo
    if Player.Character then
        task.defer(function()
            AddNameESP(Player)
        end)
    end
end

-- ================= Update ESP =================
local function UpdateNameESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if nameESPEnabled then
                AddNameESP(Player)
            else
                RemoveNameESP(Player)
            end
        end
    end
end

-- ================= Toggle =================
TrollTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = false,
    Flag = "Player_NameESP",

    Callback = function(Value)
        nameESPEnabled = Value

        if Value then
            UpdateNameESP()
        else
            for Player in pairs(nameESPObjects) do
                RemoveNameESP(Player)
            end
        end
    end
})

-- ================= Existing Players =================
for _, Player in ipairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        SetupPlayer(Player)
    end
end

-- ================= New Players =================
Players.PlayerAdded:Connect(function(Player)
    if Player ~= LocalPlayer then
        SetupPlayer(Player)
    end
end)

-- ================= Player Leaving =================
Players.PlayerRemoving:Connect(function(Player)
    RemoveNameESP(Player)
end)

--==================================================
-- FINISH EXPANDER
--==================================================

FarmTab:CreateToggle({
    Name = "Infinite Points Farm(VIP)",
    CurrentValue = false,
    Flag = "ExpandFinish",

    Callback = function(Value)
        finishLoopAtivo = Value
        encontrarFinishes()

        if Value then

            for obj, original in pairs(finishes) do
                if obj and obj.Parent then
                    obj.Size = original.Size + Vector3.new(9999, 9999, 9999)
                    obj.CanCollide = false
                    obj.Transparency = 1
                end
            end

            toolAtual = nil
            darPush()

            if not loopAtivo then
                equiparLoop()
            end

        else

            for obj, original in pairs(finishes) do
                if obj and obj.Parent then
                    obj.Size = original.Size
                    obj.CanCollide = original.CanCollide
                    obj.Transparency = original.Transparency
                end
            end

            if not loopAtivo then
                loopId += 1
                toolAtual = nil
            end
        end

        -- Atualiza anti-TP
        atualizarAntiTp()
    end
})

local NoSwim = false
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function ApplyNoSwim(character)
    local humanoid = character:WaitForChild("Humanoid")

    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, not NoSwim)

    if NoSwim then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

PlayerTab:CreateToggle({
    Name = "GodMode",
    CurrentValue = false,
    Flag = "NoSwim",
    Callback = function(Value)
        NoSwim = Value

        if player.Character then
            ApplyNoSwim(player.Character)
        end
    end
})

player.CharacterAdded:Connect(function(character)
    ApplyNoSwim(character)
end)

local aimbotRange = 100

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- VARIÁVEIS DINÂMICAS
local char, root, humanoid

-- CONNECTION
local aimConnection = nil
local aimbotEnabled = false

-- ATUALIZA PERSONAGEM
local function updateCharacter(character)
    char = character
    root = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end

-- INICIAL
updateCharacter(player.Character or player.CharacterAdded:Wait())

-- RESPAWN FIX
player.CharacterAdded:Connect(function(character)
    updateCharacter(character)
end)

-- GET CLOSEST TARGET
local function getClosestAimbotTarget()
    if not root then return nil end

    local closestPlayer = nil  
    local shortestDist = aimbotRange  
  
    for _, p in ipairs(Players:GetPlayers()) do  
        if p ~= player   
        and p.Character   
        and p.Character:FindFirstChild("HumanoidRootPart")   
        and p.Character:FindFirstChildOfClass("Humanoid")   
        and p.Character.Humanoid.Health > 0 then  
              
            local targetHRP = p.Character.HumanoidRootPart  
            local dist = (root.Position - targetHRP.Position).Magnitude  
              
            if dist < shortestDist then  
                closestPlayer = p  
                shortestDist = dist  
            end  
        end  
    end  
  
    return closestPlayer
end

-- START
local function startAimbot()
    if aimConnection then return end

    aimConnection = RunService.Heartbeat:Connect(function()  
        if not aimbotEnabled or not root then return end  

        local target = getClosestAimbotTarget()  
          
        if target and target.Character then  
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")  
              
            if targetHrp then  
                root.CFrame = CFrame.lookAt(  
                    root.Position,  
                    Vector3.new(targetHrp.Position.X, root.Position.Y, targetHrp.Position.Z)  
                )  
            end  
        end  
    end)
end

-- STOP
local function stopAimbot()
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
end

-- ADICIONAR TOGGLE PLANT SPAM
local PlantSpam = false

TrollTab:CreateToggle({
    Name = "KillAura (CHOMP PLANT)",
    CurrentValue = false,
    Flag = "PlantSpam",
    Callback = function(Value)
        PlantSpam = Value
        
        -- Ativa/desativa o aimbot junto com o KillAura
        aimbotEnabled = Value
        
        if Value then
            startAimbot()
        else
            stopAimbot()
        end

        task.spawn(function()  
            while PlantSpam do  
                local player = game.Players.LocalPlayer  
                local character = player.Character or player.CharacterAdded:Wait()  
                local humanoid = character:WaitForChild("Humanoid")  

                local tool = character:FindFirstChild("CHOMP PLANT")  
                    or player.Backpack:FindFirstChild("CHOMP PLANT")  

                if tool and tool:IsA("Tool") then  
                    humanoid:EquipTool(tool)  
                    task.wait() -- Apenas UM task.wait aqui
                    humanoid:UnequipTools()  
                end  

                task.wait() -- E outro aqui para o loop
            end  
        end)  
    end
})

local DoubleJump = false
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local canDoubleJump = false
local hasDoubleJumped = false

local function SetupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")

    canDoubleJump = false
    hasDoubleJumped = false

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            task.wait(0.1)
            canDoubleJump = true
        elseif newState == Enum.HumanoidStateType.Landed then
            canDoubleJump = false
            hasDoubleJumped = false
        end
    end)
end

if player.Character then
    SetupCharacter(player.Character)
end

player.CharacterAdded:Connect(SetupCharacter)

UIS.JumpRequest:Connect(function()
    if not DoubleJump then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if canDoubleJump and not hasDoubleJumped then
        hasDoubleJumped = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

PlayerTab:CreateToggle({
    Name = "DoubleJumpGP",
    CurrentValue = false,
    Flag = "DoubleJump",
    Callback = function(Value)
        DoubleJump = Value
    end
})

local GravityCoil = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local originalGravity = workspace.Gravity

local SETTINGS = {
    JumpPower = 50,
    GravityModifier = 0.25,
    FallSpeed = 40,
}

local function GetCharacter()
    return player.Character
end

local function ApplyGravityCoil()
    if GravityCoil then
        workspace.Gravity = originalGravity * SETTINGS.GravityModifier
        humanoid.UseJumpPower = true
        humanoid.JumpPower = SETTINGS.JumpPower
    else
        workspace.Gravity = originalGravity
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50
    end
end

-- Loop para controle de velocidade de queda
task.spawn(function()
    while true do
        task.wait(0.05)
        
        local char = GetCharacter()
        if GravityCoil and char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.Parent then
                local velocity = root.AssemblyLinearVelocity
                
                if velocity.Y < -1 then
                    root.AssemblyLinearVelocity = Vector3.new(
                        velocity.X,
                        math.max(velocity.Y, -SETTINGS.FallSpeed),
                        velocity.Z
                    )
                end
            end
        end
    end
end)

-- Quando o personagem spawnar
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    if GravityCoil then
        ApplyGravityCoil()
    end
end)

-- Quando o personagem morrer
player.CharacterRemoving:Connect(function()
    workspace.Gravity = originalGravity
end)

-- Toggle do menu
PlayerTab:CreateToggle({
    Name = "Fake Gravity Coil",
    CurrentValue = false,
    Flag = "GravityCoil",
    Callback = function(Value)
        GravityCoil = Value
        ApplyGravityCoil()
    end
})

local SpeedCoil = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local speedLoop

local function ApplySpeedCoil()
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    if SpeedCoil then
        hum.WalkSpeed = 24
    else
        hum.WalkSpeed = 16
    end
end

-- Loop para manter a velocidade
local function StartSpeedLoop()
    if speedLoop then
        speedLoop:Disconnect()
        speedLoop = nil
    end
    
    speedLoop = RunService.RenderStepped:Connect(function()
        if SpeedCoil then
            local char = player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.WalkSpeed ~= 24 then
                    hum.WalkSpeed = 24
                end
            end
        end
    end)
end

-- Quando o personagem spawnar
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    
    task.wait(0.1)
    if SpeedCoil then
        ApplySpeedCoil()
        StartSpeedLoop()
    end
end)

-- Toggle do menu
PlayerTab:CreateToggle({
    Name = "Fake Speed Coil",
    CurrentValue = false,
    Flag = "SpeedCoil",
    Callback = function(Value)
        SpeedCoil = Value
        
        if SpeedCoil then
            ApplySpeedCoil()
            StartSpeedLoop()
        else
            ApplySpeedCoil()
            if speedLoop then
                speedLoop:Disconnect()
                speedLoop = nil
            end
        end
    end
})

--==================================================
-- ANTI-TELEPORT
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Posição que será bloqueada
local BLOCKED_POSITION = Vector3.new(0, 60, 4)
local BLOCK_RADIUS = 130

-- Posição segura
local SAFE_POSITION = Vector3.new(-1, 62, -263)

local antiTpAtivo = false
local ultimaPosicaoSegura = nil

--==================================================
-- LOOP DE VERIFICAÇÃO
--==================================================
RunService.Heartbeat:Connect(function()
    if not antiTpAtivo then
        return
    end

    local character = player.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local currentPos = root.Position
    local distancia = (currentPos - BLOCKED_POSITION).Magnitude

    if distancia <= BLOCK_RADIUS then
        -- Tentou entrar na área bloqueada → volta pra última posição segura
        if ultimaPosicaoSegura then
            root.CFrame = CFrame.new(ultimaPosicaoSegura)
        end
    else
        -- Fora da área → guarda como posição segura
        ultimaPosicaoSegura = currentPos
    end
end)

--==================================================
-- TOGGLE NO RAYFIELD
--==================================================
FarmTab:CreateToggle({
    Name = "AutoWin",
    CurrentValue = false,
    Flag = "AntiTeleport",

    Callback = function(Value)
        antiTpAtivo = Value

        if Value then
            -- Ao ligar: verifica se já está dentro da área bloqueada
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if root then
                local distancia = (root.Position - BLOCKED_POSITION).Magnitude

                if distancia <= BLOCK_RADIUS then
                    -- Já está dentro → teleporta pra zona segura
                    root.CFrame = CFrame.new(SAFE_POSITION)
                    ultimaPosicaoSegura = SAFE_POSITION
                else
                    -- Já está fora → só registra a posição atual
                    ultimaPosicaoSegura = root.Position
                end
            end
        else
            ultimaPosicaoSegura = nil
        end
    end
})

FarmTab:CreateButton({
    Name = "Sit",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            
            if humanoid then
                -- Apenas senta, sem freeze
                humanoid:ChangeState(Enum.HumanoidStateType.Seated)
                humanoid.Sit = true
                
                task.wait(0.1)
                
                -- Reforça o sit
                humanoid:ChangeState(Enum.HumanoidStateType.Seated)
                humanoid.Sit = true
            end
        end
    end
})

local water = workspace:WaitForChild("LavaPart")

-- Salva o tamanho original
local originalSize = water.Size
local originalMaterial = water.Material
local originalTransparency = water.Transparency
local originalCanCollide = water.CanCollide

PlayerTab:CreateToggle({
    Name = "LavaWalk",
    CurrentValue = false,
    Flag = "SolidLava",

    Callback = function(Value)
        if Value then
            water.Material = Enum.Material.SmoothPlastic
            water.Transparency = 1
            water.CanCollide = true

            -- Sempre usa o tamanho original
            water.Size = originalSize + Vector3.new(6, 2, 6)

        else
            -- Restaura o tamanho original
            water.Size = originalSize
            water.Material = originalMaterial
            water.Transparency = originalTransparency
            water.CanCollide = originalCanCollide
        end
    end,
})

local AntiKB = false
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local connection

PlayerTab:CreateToggle({
    Name = "AntiKB",
    CurrentValue = false,
    Flag = "AntiKB",
    Callback = function(Value)
        AntiKB = Value

        if connection then
            connection:Disconnect()
            connection = nil
        end

        if AntiKB then
            connection = RunService.Heartbeat:Connect(function()
                local character = Players.LocalPlayer.Character
                if not character then return end

                local root = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not root or not humanoid then return end

                -- Impede sentar
                if humanoid.Sit then
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end

                -- Remove objetos que costumam causar fling
                for _, obj in ipairs(root:GetChildren()) do
                    if obj:IsA("BodyVelocity")
                    or obj:IsA("BodyForce")
                    or obj:IsA("BodyPosition")
                    or obj:IsA("LinearVelocity")
                    or obj:IsA("VectorForce")
                    or obj:IsA("Torque")
                    or obj:IsA("AngularVelocity") then
                        obj:Destroy()
                    end
                end

                -- Limita cada eixo separadamente
                local v = root.AssemblyLinearVelocity

                local maxXZ = 24
                local maxY = 80

                local x = math.clamp(v.X, -maxXZ, maxXZ)
                local y = math.clamp(v.Y, -maxY, maxY)
                local z = math.clamp(v.Z, -maxXZ, maxXZ)

                root.AssemblyLinearVelocity = Vector3.new(x, y, z)

                -- Limita rotação exagerada
                local a = root.AssemblyAngularVelocity
                if a.Magnitude > 15 then
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        end
    end
})

-- Script Local (Client-Sided)
-- Botão Toggle Anti-Fling na PlayerTab para Rayfield

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local isEnabled = false
local characterConnections = {}
local trackedCharacters = {}

local function applyCollisionState(character, enabled)
    if not character then return end
    
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = not enabled
        end
    end
end

local function setupCharacter(character)
    if not character or character == localPlayer.Character then return end
    
    if trackedCharacters[character] then
        for _, conn in ipairs(trackedCharacters[character]) do
            conn:Disconnect()
        end
        trackedCharacters[character] = nil
    end
    
    applyCollisionState(character, isEnabled)
    
    local connections = {}
    
    local childAddedConn = character.ChildAdded:Connect(function(part)
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = not isEnabled
        end
    end)
    table.insert(connections, childAddedConn)
    
    local steppedConn = RunService.Stepped:Connect(function()
        if character and character:IsDescendantOf(workspace) then
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local shouldCollide = not isEnabled
                    if part.CanCollide ~= shouldCollide then
                        part.CanCollide = shouldCollide
                    end
                end
            end
        end
    end)
    table.insert(connections, steppedConn)
    
    local destroyingConn = character.Destroying:Connect(function()
        if trackedCharacters[character] then
            for _, conn in ipairs(trackedCharacters[character]) do
                conn:Disconnect()
            end
            trackedCharacters[character] = nil
        end
    end)
    table.insert(connections, destroyingConn)
    
    trackedCharacters[character] = connections
end

local function trackPlayer(player)
    if player == localPlayer then return end
    
    if player.Character then
        setupCharacter(player.Character)
    end
    
    local charAddedConn = player.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)
    
    characterConnections[player] = charAddedConn
end

local function untrackPlayer(player)
    if characterConnections[player] then
        characterConnections[player]:Disconnect()
        characterConnections[player] = nil
    end
    
    if player.Character and trackedCharacters[player.Character] then
        for _, conn in ipairs(trackedCharacters[player.Character]) do
            conn:Disconnect()
        end
        trackedCharacters[player.Character] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    trackPlayer(player)
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(untrackPlayer)

local Toggle = PlayerTab:CreateToggle({
    Name = "Anti-Fling",
    CurrentValue = false,
    Flag = "AntiFlingToggle",
    Callback = function(Value)
        isEnabled = Value
        
        for character, _ in pairs(trackedCharacters) do
            if character and character:IsDescendantOf(workspace) then
                applyCollisionState(character, isEnabled)
            end
        end
    end,
})

localPlayer.Chatted:Connect(function(msg)
    msg = msg:lower()
    if msg == ";af on" then
        Toggle:Set(true)
    elseif msg == ";af off" then
        Toggle:Set(false)
    end
end)

local function cleanup()
    for player, conn in pairs(characterConnections) do
        conn:Disconnect()
    end
    characterConnections = {}
    
    for character, conns in pairs(trackedCharacters) do
        for _, conn in ipairs(conns) do
            conn:Disconnect()
        end
    end
    trackedCharacters = {}
end

localPlayer.CharacterAdded:Connect(function()
    cleanup()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            trackPlayer(player)
        end
    end
end)

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local antiAFKConnection
local statusGui

FarmTab:CreateButton({
    Name = "Anti AFK",
    Callback = function()
        -- Evita ativar duas vezes
        if antiAFKConnection then
            return
        end

        -- Texto na tela
        statusGui = Instance.new("ScreenGui")
        statusGui.Name = "AntiAFKStatus"
        statusGui.ResetOnSpawn = false
        statusGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

        local label = Instance.new("TextLabel")
        label.Name = "Status"
        label.Size = UDim2.new(0, 220, 0, 40)
        label.Position = UDim2.new(0.5, -110, 0, 20)
        label.BackgroundTransparency = 0.3
        label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        label.TextColor3 = Color3.fromRGB(0, 255, 0)
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Text = "🟢 Anti AFK by Enygma"
        label.Parent = statusGui

        antiAFKConnection = Players.LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
})

-- BOTÃO: APENAS SPAM DA PLANTA (Sem aimbot)
local PlantSpamOnly = false

TrollTab:CreateToggle({
    Name = "auto chomp plant (no aimbot)",
    CurrentValue = false,
    Flag = "PlantSpamOnly",
    Callback = function(Value)
        PlantSpamOnly = Value

        task.spawn(function()  
            while PlantSpamOnly do  
                local player = game.Players.LocalPlayer  
                local character = player.Character or player.CharacterAdded:Wait()  
                local humanoid = character:WaitForChild("Humanoid")  

                local tool = character:FindFirstChild("CHOMP PLANT")  
                    or player.Backpack:FindFirstChild("CHOMP PLANT")  

                if tool and tool:IsA("Tool") then  
                    humanoid:EquipTool(tool)  
                    task.wait( )  
                    humanoid:UnequipTools()  
                end  

                task.wait( )  
            end  
        end)  
    end
})

-- ============ CONFIGURAÇÃO DO MAGNET ============
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

-- ============ NETWORK (interno, sem toggle próprio) ============
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(140.46262424, 140.46262424, 140.46262424)
    }

    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            Part.CanCollide = false
        end
    end
end

local networkConn = nil

local function StartNetwork()
    if networkConn then return end -- já tá ligado
    LocalPlayer.ReplicationFocus = Workspace
    networkConn = RunService.Heartbeat:Connect(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        for _, Part in pairs(Network.BaseParts) do
            if Part:IsDescendantOf(Workspace) then
                Part.Velocity = Network.Velocity
            end
        end
    end)
end

local function StopNetwork()
    if networkConn then
        networkConn:Disconnect()
        networkConn = nil
    end
    pcall(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", 100)
    end)
end

-- ============ CONFIGURAÇÕES AJUSTÁVEIS (controladas pelos sliders) ============
local OrbitConfig = {
    Speed = 2,       -- velocidade de rotação (rad/s)
    Distance = 15,   -- distância do player
}

-- ============ FUNÇÃO MAGNET EM LOOP CONTÍNUO ============
local magnetActive = false
local Forces = {}
local frozenParts = {}
local magnetThread = nil
local scanThread = nil

local function isValidPart(part, targetCharacter)
    if not part or not part.Parent then return false end
    if not part:IsA("BasePart") then return false end
    if part.Anchored then return false end
    if part:IsDescendantOf(targetCharacter) then return false end
    if part == Part then return false end
    if part:IsDescendantOf(Folder) then return false end
    return true
end

local function handlePart(part, targetCharacter)
    if not isValidPart(part, targetCharacter) then return end
    if table.find(frozenParts, part) then return end

    for _, c in pairs(part:GetChildren()) do
        if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
            c:Destroy()
        end
    end

    local ForceInstance = Instance.new("BodyPosition")
    ForceInstance.Parent = part
    ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    ForceInstance.Position = targetCharacter.Head.Position

    table.insert(Forces, ForceInstance)
    table.insert(frozenParts, part)
    part.CanCollide = false
end

local function StopMagnet()
    magnetActive = false
    if magnetThread then
        task.cancel(magnetThread)
        magnetThread = nil
    end
    if scanThread then
        task.cancel(scanThread)
        scanThread = nil
    end
    for _, force in pairs(Forces) do
        if force and force.Parent then
            force:Destroy()
        end
    end
    Forces = {}
    for _, part in pairs(frozenParts) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end
    frozenParts = {}

    -- 👇 só desliga o network se o Orbit também estiver off
    if not orbitActive then
        StopNetwork()
    end
end

local function StartMagnet()
    if magnetActive then return end
    magnetActive = true

    StartNetwork() -- 👈 liga o network junto

    local targetCharacter = LocalPlayer.Character
    if not targetCharacter or not targetCharacter:FindFirstChild("Head") then
        magnetActive = false
        if not orbitActive then StopNetwork() end
        return
    end

    Forces = {}
    frozenParts = {}

    for _, part in pairs(workspace:GetDescendants()) do
        handlePart(part, targetCharacter)
    end

    magnetThread = task.spawn(function()
        while magnetActive do
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Head") then break end

            for i = #Forces, 1, -1 do
                local force = Forces[i]
                if force and force.Parent then
                    force.Position = char.Head.Position
                else
                    table.remove(Forces, i)
                end
            end
            task.wait(0.1)
        end
    end)

    scanThread = task.spawn(function()
        while magnetActive do
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Head") then break end

            for _, part in pairs(workspace:GetDescendants()) do
                if not magnetActive then break end
                handlePart(part, char)
            end

            for i = #frozenParts, 1, -1 do
                local p = frozenParts[i]
                if not p or not p.Parent then
                    table.remove(frozenParts, i)
                end
            end

            task.wait(0.5)
        end
    end)
end

-- ============ MAGNET ORBITAL (parts girando em volta) ============
local orbitActive = false
local OrbitForces = {}       -- {force = BodyPosition, part = BasePart, angleOffset = number, heightOffset = number}
local orbitParts = {}        -- controle de parts capturadas
local orbitMainThread = nil
local orbitScanThread = nil
local orbitAngle = 0

local function isValidOrbitPart(part, targetCharacter)
    if not part or not part.Parent then return false end
    if not part:IsA("BasePart") then return false end
    if part.Anchored then return false end
    if part:IsDescendantOf(targetCharacter) then return false end
    if part == Part then return false end
    if part:IsDescendantOf(Folder) then return false end
    return true
end

local function handleOrbitPart(part, targetCharacter)
    if not isValidOrbitPart(part, targetCharacter) then return end
    if table.find(orbitParts, part) then return end

    for _, c in pairs(part:GetChildren()) do
        if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
            c:Destroy()
        end
    end

    part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
    part.CanCollide = false

    local ForceInstance = Instance.new("BodyPosition")
    ForceInstance.Parent = part
    ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    ForceInstance.Position = targetCharacter.Head.Position

    table.insert(OrbitForces, {
        force = ForceInstance,
        part = part,
        angleOffset = math.random() * math.pi * 2,
        heightOffset = (math.random() - 0.5) * 5,
    })
    table.insert(orbitParts, part)
end

local function StopOrbit()
    orbitActive = false
    if orbitMainThread then
        task.cancel(orbitMainThread)
        orbitMainThread = nil
    end
    if orbitScanThread then
        task.cancel(orbitScanThread)
        orbitScanThread = nil
    end
    for _, data in pairs(OrbitForces) do
        if data.force and data.force.Parent then
            data.force:Destroy()
        end
        if data.part and data.part.Parent then
            data.part.CanCollide = true
        end
    end
    OrbitForces = {}
    orbitParts = {}
    orbitAngle = 0

    -- 👇 só desliga o network se o Magnet também estiver off
    if not magnetActive then
        StopNetwork()
    end
end

local function StartOrbit()
    if orbitActive then return end
    orbitActive = true

    StartNetwork() -- 👈 liga o network junto

    local targetCharacter = LocalPlayer.Character
    if not targetCharacter or not targetCharacter:FindFirstChild("Head") then
        orbitActive = false
        if not magnetActive then StopNetwork() end
        return
    end

    OrbitForces = {}
    orbitParts = {}

    for _, part in pairs(workspace:GetDescendants()) do
        handleOrbitPart(part, targetCharacter)
    end

    orbitMainThread = task.spawn(function()
        local lastTime = tick()
        while orbitActive do
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Head") then break end

            local now = tick()
            local dt = now - lastTime
            lastTime = now

            orbitAngle = orbitAngle + OrbitConfig.Speed * dt

            local center = char.Head.Position
            local radius = OrbitConfig.Distance

            for _, data in pairs(OrbitForces) do
                if data.force and data.force.Parent and data.part and data.part.Parent then
                    local angle = orbitAngle + data.angleOffset
                    local x = center.X + math.cos(angle) * radius
                    local z = center.Z + math.sin(angle) * radius
                    local y = center.Y + data.heightOffset + math.sin(angle * 2) * 2

                    data.force.Position = Vector3.new(x, y, z)
                end
            end

            RunService.Heartbeat:Wait()
        end
    end)

    orbitScanThread = task.spawn(function()
        while orbitActive do
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Head") then break end

            for _, part in pairs(workspace:GetDescendants()) do
                if not orbitActive then break end
                handleOrbitPart(part, char)
            end

            for i = #OrbitForces, 1, -1 do
                local data = OrbitForces[i]
                if not data.part or not data.part.Parent or not data.force or not data.force.Parent then
                    table.remove(OrbitForces, i)
                end
            end
            for i = #orbitParts, 1, -1 do
                local p = orbitParts[i]
                if not p or not p.Parent then
                    table.remove(orbitParts, i)
                end
            end

            task.wait(0.5)
        end
    end)
end

-- Para tudo ao morrer
LocalPlayer.CharacterAdded:Connect(function()
    StopMagnet()
    StopOrbit()
end)


-- ============ TARGET ORBIT ============
-- Usa o mesmo input "Player Name".
-- Distância fixa: 1 stud | Velocidade fixa: 20.
-- O alvo é reavaliado continuamente, permitindo trocar o jogador
-- no mesmo input enquanto o toggle continua ligado.
-- Partes novas também são detectadas continuamente.

local targetOrbitActive = false
local targetOrbitPlayer = nil
local targetOrbitParts = {}
local targetOrbitThread = nil
local targetOrbitAngle = 0

local TARGET_ORBIT_DISTANCE = 1
local TARGET_ORBIT_SPEED = 20
local TARGET_ORBIT_SCAN_INTERVAL = 0.05

local function FindTargetPlayer(name)
    name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return nil
    end

    -- Primeiro: correspondência exata por Name ou DisplayName.
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Name:lower() == name or player.DisplayName:lower() == name then
                return player
            end
        end
    end

    -- Depois: correspondência parcial por Name ou DisplayName.
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Name:lower():find(name, 1, true)
                or player.DisplayName:lower():find(name, 1, true) then
                return player
            end
        end
    end

    return nil
end

local function IsValidTargetOrbitPart(part, targetCharacter)
    if not part or not part:IsA("Part") then
        return false
    end

    if not part.Parent or part.Anchored then
        return false
    end

    if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
        return false
    end

    if targetCharacter and part:IsDescendantOf(targetCharacter) then
        return false
    end

    if part.Name == "Handle" then
        return false
    end

    local parent = part.Parent
    if parent and parent:FindFirstChildOfClass("Humanoid") then
        return false
    end

    if part:FindFirstAncestorOfClass("Model")
        and part:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") then
        return false
    end

    return true
end

local function RemoveTargetOrbitForceObjects(part)
    if not part then
        return
    end

    for _, obj in ipairs(part:GetChildren()) do
        if obj.Name == "TargetOrbitAttachment"
            or obj.Name == "TargetOrbitTorque"
            or obj.Name == "TargetOrbitAlignPosition" then
            pcall(function()
                obj:Destroy()
            end)
        end
    end
end

local function HandleTargetOrbitPart(part)
    if not IsValidTargetOrbitPart(part, targetOrbitPlayer and targetOrbitPlayer.Character) then
        return false
    end

    local attachment = part:FindFirstChild("TargetOrbitAttachment")
    local torque = part:FindFirstChild("TargetOrbitTorque")
    local align = part:FindFirstChild("TargetOrbitAlignPosition")

    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "TargetOrbitAttachment"
        attachment.Parent = part
    end

    if not torque then
        torque = Instance.new("Torque")
        torque.Name = "TargetOrbitTorque"
        torque.Attachment0 = attachment
        torque.RelativeTo = Enum.ActuatorRelativeTo.World
        torque.Torque = Vector3.new(100000, 100000, 100000)
        torque.Parent = part
    end

    if not align then
        align = Instance.new("AlignPosition")
        align.Name = "TargetOrbitAlignPosition"
        align.Mode = Enum.PositionAlignmentMode.OneAttachment
        align.Attachment0 = attachment
        align.MaxForce = 9999999999999999
        align.MaxVelocity = math.huge
        align.Responsiveness = 200
        align.RigidityEnabled = false
        align.Parent = part
    end

    part.CanCollide = false

    targetOrbitParts[part] = true
    return true
end

local function ScanTargetOrbitParts(targetCharacter)
    for _, part in ipairs(Workspace:GetDescendants()) do
        if IsValidTargetOrbitPart(part, targetCharacter) then
            HandleTargetOrbitPart(part)
        end
    end
end

local function CleanupTargetOrbitPart(part)
    if part then
        RemoveTargetOrbitForceObjects(part)
        pcall(function()
            part.CanCollide = true
        end)
    end
    targetOrbitParts[part] = nil
end

local function StopTargetOrbit()
    targetOrbitActive = false

    if targetOrbitThread then
        task.cancel(targetOrbitThread)
        targetOrbitThread = nil
    end

    for part in pairs(targetOrbitParts) do
        CleanupTargetOrbitPart(part)
    end

    targetOrbitParts = {}
    targetOrbitPlayer = nil
    targetOrbitAngle = 0
end

local function StartTargetOrbit()
    -- Reinicia a referência para garantir que o novo valor do input seja usado.
    if targetOrbitActive then
        StopTargetOrbit()
    end

    targetOrbitActive = true
    targetOrbitAngle = 0

    targetOrbitThread = task.spawn(function()
        local scanAccumulator = 0

        while targetOrbitActive do
            -- Reavalia o input a cada ciclo. Assim, trocar o nome
            -- muda o alvo sem precisar desligar o toggle.
            local currentName = tostring(getgenv().TargetName or "")
            local newTarget = FindTargetPlayer(currentName)

            if newTarget ~= targetOrbitPlayer then
                targetOrbitPlayer = newTarget

                -- Remove forças de partes que não devem mais seguir o novo alvo.
                for part in pairs(targetOrbitParts) do
                    if not IsValidTargetOrbitPart(
                        part,
                        targetOrbitPlayer and targetOrbitPlayer.Character
                    ) then
                        CleanupTargetOrbitPart(part)
                    end
                end
            end

            local targetCharacter = targetOrbitPlayer and targetOrbitPlayer.Character
            local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

            if targetRoot then
                scanAccumulator = scanAccumulator + TARGET_ORBIT_SCAN_INTERVAL

                -- Escaneia repetidamente para pegar Parts que surgiram depois
                -- que o Orbit foi ligado.
                if scanAccumulator >= TARGET_ORBIT_SCAN_INTERVAL then
                    scanAccumulator = 0
                    ScanTargetOrbitParts(targetCharacter)
                end

                targetOrbitAngle = targetOrbitAngle + math.rad(TARGET_ORBIT_SPEED)

                local center = targetRoot.Position
                local validCount = 0

                for part in pairs(targetOrbitParts) do
                    if not IsValidTargetOrbitPart(part, targetCharacter)
                        or not part:IsDescendantOf(Workspace) then
                        CleanupTargetOrbitPart(part)
                    else
                        validCount = validCount + 1

                        local index = validCount
                        local total = math.max(1, 0)

                        -- Distribui as partes em uma órbita circular.
                        -- Cada parte recebe uma fase própria para evitar
                        -- que todas fiquem exatamente no mesmo ponto.
                        local phase = targetOrbitAngle + (index * (math.pi * 2 / math.max(1, #targetOrbitParts)))
                        local targetPosition = center + Vector3.new(
                            math.cos(phase) * TARGET_ORBIT_DISTANCE,
                            0,
                            math.sin(phase) * TARGET_ORBIT_DISTANCE
                        )

                        local align = part:FindFirstChild("TargetOrbitAlignPosition")
                        if align then
                            align.Position = targetPosition
                        end
                    end
                end
            else
                -- Mesmo sem HumanoidRootPart, continua vivo e procurando
                -- para acompanhar respawn/troca de personagem.
                task.wait(0.05)
            end

            RunService.Heartbeat:Wait()
        end
    end)
end

-- ============ UI NO TROLLTAB ============

TrollTab:CreateToggle({
    Name = "Magnet",
    CurrentValue = false,
    Flag = "MagnetSelfToggle",
    Callback = function(value)
        if value then
            StartMagnet()
        else
            StopMagnet()
        end
    end,
})

TrollTab:CreateToggle({
    Name = "Orbit Magnet",
    CurrentValue = false,
    Flag = "OrbitMagnetToggle",
    Callback = function(value)
        if value then
            StartOrbit()
        else
            StopOrbit()
        end
    end,
})

TrollTab:CreateSlider({
    Name = "orbit velocity",
    Range = {1, 20},
    Increment = 1,
    Suffix = " speed",
    CurrentValue = 1,
    Flag = "OrbitSpeedSlider",
    Callback = function(value)
        OrbitConfig.Speed = value
    end,
})

TrollTab:CreateSlider({
    Name = "orbit distance",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "OrbitDistanceSlider",
    Callback = function(value)
        OrbitConfig.Distance = value
    end,
})

-- =================================
-- Apenas a função Touch Fling
-- Adicione isso ao seu TrollTab existente
-- =================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local TouchFlingEnabled = false
local TouchFlingThread = nil

-- Criar detector anti-cheat
if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
    local detection = Instance.new("Decal")
    detection.Name = "juisdfj0i32i0eidsuf0iok"
    detection.Parent = ReplicatedStorage
end

-- Função principal do Touch Fling
local function TouchFling()
    local c, hrp, vel, movel = nil, nil, nil, 0.1

    while TouchFlingEnabled do
        RunService.Heartbeat:Wait()
        c = Player.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")

        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * 99999999 + Vector3.new(0, 99999999, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

-- Função para iniciar/parar
local function ToggleTouchFling(Value)
    TouchFlingEnabled = Value
    
    if TouchFlingEnabled then
        if TouchFlingThread then
            TouchFlingThread = nil
        end
        TouchFlingThread = coroutine.create(TouchFling)
        coroutine.resume(TouchFlingThread)
    end
end

-- Adicione isso dentro do seu TrollTab existente
TrollTab:CreateToggle({
    Name = "Touch Fling",
    CurrentValue = false,
    Flag = "TouchFling",
    Callback = function(Value)
        ToggleTouchFling(Value)
    end,
})

-- =================================
-- Rayfield Fling Functions for TrollTab
-- =================================

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local AllBool = false

local GetPlayer = function(Name)
Name = Name:lower()
if Name == "all" or Name == "others" then
AllBool = true
return
elseif Name == "random" then
local GetPlayers = Players:GetPlayers()
if table.find(GetPlayers,Player) then
table.remove(GetPlayers,table.find(GetPlayers,Player))
end
return GetPlayers[math.random(#GetPlayers)]
elseif Name ~= "random" and Name ~= "all" and Name ~= "others" then
for _,x in next, Players:GetPlayers() do
if x ~= Player then
if x.Name:lower():match("^"..Name) then
return x;
elseif x.DisplayName:lower():match("^"..Name) then
return x;
end
end
end
else
return
end
end

local SkidFling = function(TargetPlayer)
local Character = Player.Character
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local RootPart = Humanoid and Humanoid.RootPart
local TCharacter = TargetPlayer.Character
local THumanoid
local TRootPart
local THead
local Accessory
local Handle

if TCharacter:FindFirstChildOfClass("Humanoid") then  
    THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")  
end  
if THumanoid and THumanoid.RootPart then  
    TRootPart = THumanoid.RootPart  
end  
if TCharacter:FindFirstChild("Head") then  
    THead = TCharacter.Head  
end  
if TCharacter:FindFirstChildOfClass("Accessory") then  
    Accessory = TCharacter:FindFirstChildOfClass("Accessory")  
end  
if Accessory and Accessory:FindFirstChild("Handle") then  
    Handle = Accessory.Handle  
end  

if Character and Humanoid and RootPart then  
    if RootPart.Velocity.Magnitude < 50 then  
        getgenv().OldPos = RootPart.CFrame  
    end  
    if THumanoid and THumanoid.Sit and not AllBool then  
        return  
    end  

    if THead then  
        workspace.CurrentCamera.CameraSubject = THead  
    elseif not THead and Handle then  
        workspace.CurrentCamera.CameraSubject = Handle  
    elseif THumanoid and TRootPart then  
        workspace.CurrentCamera.CameraSubject = THumanoid  
    end  

    if not TCharacter:FindFirstChildWhichIsA("BasePart") then  
        return  
    end  

    local FPos = function(BasePart, Pos, Ang)  
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang  
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)  
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)  
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)  
    end  

    local SFBasePart = function(BasePart)  
        local TimeToWait = 2  
        local Time = tick()  
        local Angle = 0  
        repeat  
            if RootPart and THumanoid then  
                if BasePart.Velocity.Magnitude < 50 then  
                    Angle = Angle + 100  
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))  
                    task.wait()  
                else  
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))  
                    task.wait()  
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))  
                    task.wait()  
                end  
            else  
                break  
            end  
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait  
    end  

    workspace.FallenPartsDestroyHeight = 0/0  
    local BV = Instance.new("BodyVelocity")  
    BV.Name = "EpixVel"  
    BV.Parent = RootPart  
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)  
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)  
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)  

    if TRootPart and THead then  
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then  
            SFBasePart(THead)  
        else  
            SFBasePart(TRootPart)  
        end  
    elseif TRootPart and not THead then  
        SFBasePart(TRootPart)  
    elseif not TRootPart and THead then  
        SFBasePart(THead)  
    elseif not TRootPart and not THead and Accessory and Handle then  
        SFBasePart(Handle)  
    else  
        return  
    end  

    BV:Destroy()  
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)  
    workspace.CurrentCamera.CameraSubject = Humanoid  

    repeat  
        RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)  
        Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))  
        Humanoid:ChangeState("GettingUp")  
        table.foreach(Character:GetChildren(), function(_, x)  
            if x:IsA("BasePart") then  
                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()  
            end  
        end)  
        task.wait()  
    until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25  
    workspace.FallenPartsDestroyHeight = getgenv().FPDH  
else  
    return  
end

end

-- Função para fling por nome
local function FlingByName(PlayerName)
AllBool = false

if PlayerName:lower() == "all" or PlayerName:lower() == "others" then  
    for _, pl in next, Players:GetPlayers() do  
        if pl ~= Player then  
            pcall(function()  
                SkidFling(pl)  
            end)  
        end  
    end  
    return  
end  
  
local target = GetPlayer(PlayerName)  
if target and target ~= Player then  
    pcall(function()  
        SkidFling(target)  
    end)  
end

end

-- Função para fling em todos
local function FlingAll()
for _, pl in next, Players:GetPlayers() do
if pl ~= Player then
pcall(function()
SkidFling(pl)
end)
end
end
end

-- Input para nome do jogador
TrollTab:CreateInput({
Name = "Player Name",
PlaceholderText = "user",
RemoveTextAfterFocusLost = false,
Callback = function(Text)
-- Armazena o nome para uso no botão
getgenv().TargetName = Text
end,
})

-- Botão para executar fling
TrollTab:CreateButton({
Name = "Execute Fling",
Callback = function()
if getgenv().TargetName and getgenv().TargetName ~= "" then
FlingByName(getgenv().TargetName)
end
end,
})

-- Botão para fling em todos
TrollTab:CreateButton({
Name = "Fling All Players",
Callback = function()
FlingAll()
end,
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

getgenv().TargetName = getgenv().TargetName or ""
local Teleporting = false
local TeleportAll = false

local Connection = nil
local ToolLoopRunning = false

local playersKilled = {}
local currentTarget = nil

-- ID da execução atual
local SessionId = 0

-- ==================================================
-- PREVISÃO
-- ==================================================

-- Previsão dos eixos X e Z
local Prediction = 0.12

-- Previsão exclusiva do eixo Y
local PredictionY = 0.05

-- O nome do jogador é definido pelo input único "Player Name" acima.

---

-- CHOMP PLANT

local function ChompPlantLoop(MySession)

while SessionId == MySession  
    and (Teleporting or TeleportAll) do  

    local Character = LocalPlayer.Character  
    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")  

    if Character and Backpack then  

        local Humanoid =  
            Character:FindFirstChildOfClass("Humanoid")  

        if Humanoid and Humanoid.Health > 0 then  

            local Tool =  
                Character:FindFirstChild("CHOMP PLANT")  
                or Backpack:FindFirstChild("CHOMP PLANT")  

            if Tool and Tool:IsA("Tool") then  

                if Tool.Parent == Character then  
                    Humanoid:UnequipTools()  
                    task.wait()  
                end  

                Tool = Backpack:FindFirstChild("CHOMP PLANT")  

                if Tool and SessionId == MySession then  
                    Humanoid:EquipTool(Tool)  
                end  
            end  
        end  
    end  

    task.wait()  
end

end

local function StartToolLoop(MySession)

task.spawn(function()  
    ChompPlantLoop(MySession)  
end)

end


---

-- TP PREDICTION X Z + Y SEPARADO

local function GetPredictedPosition(TargetHRP)

local Velocity = TargetHRP.AssemblyLinearVelocity  

local PredictedPosition = Vector3.new(  

    -- X usa Prediction  
    TargetHRP.Position.X  
        + (Velocity.X * Prediction),  

    -- Y usa PredictionY  
    TargetHRP.Position.Y  
        + (Velocity.Y * PredictionY),  

    -- Z usa Prediction  
    TargetHRP.Position.Z  
        + (Velocity.Z * Prediction)  

)  

return PredictedPosition

end


---

-- PARAR TUDO

local function StopTeleport()

SessionId = SessionId + 1  

Teleporting = false  
TeleportAll = false  

if Connection then  
    Connection:Disconnect()  
    Connection = nil  
end  

playersKilled = {}  
currentTarget = nil

end


---

-- TELEPORTAR PARA JOGADOR

TrollTab:CreateButton({
Name = "Kill(chomp plant)",

Callback = function()  

    StopTeleport()  

    local MySession = SessionId  

    Teleporting = true  

    StartToolLoop(MySession)  

    Connection = RunService.Heartbeat:Connect(function()  

        if SessionId ~= MySession  
            or not Teleporting then  

            return  
        end  

        local Character = LocalPlayer.Character  

        if not Character then  
            return  
        end  

        local MyHumanoid =  
            Character:FindFirstChildOfClass("Humanoid")  

        local MyHRP =  
            Character:FindFirstChild("HumanoidRootPart")  

        if not MyHumanoid  
            or not MyHRP  
            or MyHumanoid.Health <= 0 then  

            StopTeleport()  
            return  
        end  


        --------------------------------------------------  
        -- PROCURA O ALVO  
        --------------------------------------------------  

        local target = nil  

        for _, plr in ipairs(Players:GetPlayers()) do  

            if plr ~= LocalPlayer  
                and getgenv().TargetName ~= ""  
                and plr.Name:lower():sub(  
                    1,  
                    #getgenv().TargetName  
                ) == getgenv().TargetName:lower() then  

                target = plr  
                break  
            end  
        end  


        if not target then  
            StopTeleport()  
            return  
        end  


        local TargetCharacter = target.Character  

        if not TargetCharacter then  
            return  
        end  

        local TargetHumanoid =  
            TargetCharacter:FindFirstChildOfClass("Humanoid")  

        local TargetHRP =  
            TargetCharacter:FindFirstChild("HumanoidRootPart")  


        if not TargetHumanoid  
            or not TargetHRP  
            or TargetHumanoid.Health <= 0 then  

            StopTeleport()  
            return  
        end  


        --------------------------------------------------  
        -- TP PREDICTION  
        --------------------------------------------------  

        local PredictedPosition =  
            GetPredictedPosition(TargetHRP)  


        MyHRP.CFrame =  
            CFrame.new(  
                PredictedPosition  
                    + TargetHRP.CFrame.RightVector * 4.5,  

                PredictedPosition  
            )  

    end)  
end

})


---

-- TELEPORTAR EM TODOS

TrollTab:CreateButton({
Name = "Kill All(chomp plant)",

Callback = function()  

    StopTeleport()  

    local MySession = SessionId  

    TeleportAll = true  

    playersKilled = {}  
    currentTarget = nil  

    StartToolLoop(MySession)  


    Connection = RunService.Heartbeat:Connect(function()  

        if SessionId ~= MySession  
            or not TeleportAll then  

            return  
        end  


        --------------------------------------------------  
        -- PEGA TODOS OS OUTROS JOGADORES  
        --------------------------------------------------  

        local allOtherPlayers = {}  

        for _, plr in ipairs(Players:GetPlayers()) do  

            if plr ~= LocalPlayer then  
                table.insert(allOtherPlayers, plr)  
            end  

        end  


        if #allOtherPlayers == 0 then  
            StopTeleport()  
            return  
        end  


        --------------------------------------------------  
        -- VERIFICA SE TODOS JÁ MORRERAM  
        --------------------------------------------------  

        local allKilled = true  

        for _, plr in ipairs(allOtherPlayers) do  

            if not playersKilled[plr.UserId] then  
                allKilled = false  
                break  
            end  

        end  


        if allKilled then  
            StopTeleport()  
            return  
        end  


        --------------------------------------------------  
        -- VERIFICA ALVO ATUAL  
        --------------------------------------------------  

        local targetDead = false  

        if currentTarget then  

            local Character =  
                currentTarget.Character  

            if not Character then  

                targetDead = true  

            else  

                local Humanoid =  
                    Character:FindFirstChildOfClass("Humanoid")  

                if not Humanoid  
                    or Humanoid.Health <= 0 then  

                    targetDead = true  
                end  
            end  
        end  


        --------------------------------------------------  
        -- ESCOLHE NOVO ALVO  
        --------------------------------------------------  

        if not currentTarget or targetDead then  

            if currentTarget then  
                playersKilled[currentTarget.UserId] = true  
            end  

            currentTarget = nil  


            for _, plr in ipairs(allOtherPlayers) do  

                if not playersKilled[plr.UserId] then  

                    local Character = plr.Character  

                    if Character then  

                        local Humanoid =  
                            Character:FindFirstChildOfClass("Humanoid")  

                        local HRP =  
                            Character:FindFirstChild("HumanoidRootPart")  


                        if Humanoid  
                            and HRP  
                            and Humanoid.Health > 0 then  

                            currentTarget = plr  
                            break  
                        end  
                    end  
                end  
            end  
        end  


        --------------------------------------------------  
        -- NÃO TEM ALVO  
        --------------------------------------------------  

        if not currentTarget then  
            return  
        end  


        --------------------------------------------------  
        -- MEU PERSONAGEM  
        --------------------------------------------------  

        local MyCharacter =  
            LocalPlayer.Character  

        if not MyCharacter then  
            return  
        end  

        local MyHumanoid =  
            MyCharacter:FindFirstChildOfClass("Humanoid")  

        local MyHRP =  
            MyCharacter:FindFirstChild("HumanoidRootPart")  


        if not MyHumanoid or not MyHRP then  
            return  
        end  


        --------------------------------------------------  
        -- ALVO  
        --------------------------------------------------  

        local TargetCharacter =  
            currentTarget.Character  

        if not TargetCharacter then  
            return  
        end  

        local TargetHumanoid =  
            TargetCharacter:FindFirstChildOfClass("Humanoid")  

        local TargetHRP =  
            TargetCharacter:FindFirstChild("HumanoidRootPart")  


        if not TargetHumanoid  
            or not TargetHRP  
            or TargetHumanoid.Health <= 0 then  

            return  
        end  


        --------------------------------------------------  
        -- TP PREDICTION  
        --------------------------------------------------  

        local PredictedPosition =  
            GetPredictedPosition(TargetHRP)  


        MyHRP.CFrame =  
            CFrame.new(  
                PredictedPosition  
                    + TargetHRP.CFrame.RightVector * 4,  

                PredictedPosition  
            )  

    end)  
end

})


---

-- BOTÃO PARAR

TrollTab:CreateButton({
Name = "Stop Kill",

Callback = function()  
    StopTeleport()  
end

})

-- ============ ORBIT TARGET ============
-- Usa o mesmo input "Player Name" usado pelo Fling e Kill.
-- Distância fixa: 1 stud | Velocidade fixa: 20.

TrollTab:CreateToggle({
    Name = "Troll player (Magnet)",
    CurrentValue = false,
    Flag = "TargetOrbitToogle",

    Callback = function(value)
        if value then
            StartTargetOrbit()
        else
            StopTargetOrbit()
        end
    end,
})


---

-- CHARACTER ADDED

LocalPlayer.CharacterAdded:Connect(function()
    StopMagnet()
    StopOrbit()
    StopTargetOrbit()

    if not Teleporting and not TeleportAll then
        return
    end

    task.wait(0.5)
end)

TeleportTab:CreateParagraph({
    Title = "Map Teleport",
    Content = ""
})

TeleportTab:CreateButton({
    Name = "Low",
    Callback = function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = CFrame.new(3, 5, -4)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Mid",
    Callback = function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = CFrame.new(3, 110, -4)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Top",
    Callback = function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = CFrame.new(3, 220, -4)
        end
    end
})

TeleportTab:CreateParagraph({
    Title = "Lobby Teleport",
    Content = ""
})

TeleportTab:CreateButton({
    Name = "Spawn",
    Callback = function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = CFrame.new(-10, 62, -228)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Parkour",
    Callback = function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = CFrame.new(3, 64, -430)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Parkour vip",
    Callback = function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = CFrame.new(-69, 65, -477)
        end
    end
})

-- ================= Services =================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ================= Infinite Jump =================
local infiniteJumpEnabled = false

UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then
        return
    end

    local Character = LocalPlayer.Character
    if not Character then
        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "Player_InfiniteJump",

    Callback = function(Value)
        infiniteJumpEnabled = Value
    end
})

-- ================= NoClip =================
local noclipEnabled = false
local originalCollision = {}

local function SetNoClip(Character)
    for _, Part in ipairs(Character:GetDescendants()) do
        if Part:IsA("BasePart") then
            if originalCollision[Part] == nil then
                originalCollision[Part] = Part.CanCollide
            end

            Part.CanCollide = false
        end
    end
end

local function RestoreCollision()
    for Part, CanCollide in pairs(originalCollision) do
        if Part and Part.Parent then
            Part.CanCollide = CanCollide
        end

        originalCollision[Part] = nil
    end
end

PlayerTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "Player_NoClip",

    Callback = function(Value)
        noclipEnabled = Value

        if not Value then
            RestoreCollision()
        end
    end
})

RunService.Stepped:Connect(function()
    if not noclipEnabled then
        return
    end

    local Character = LocalPlayer.Character

    if Character then
        SetNoClip(Character)
    end
end)

-- Restaura a colisão quando o personagem renascer
LocalPlayer.CharacterAdded:Connect(function()
    originalCollision = {}
end)

PlayerTab:CreateButton({
    Name = "Fly gui",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/3nUwQMhR"))()
    end,
})