local Targets = {"All"}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local AllBool = true

local SPIN_SPEED = 1690

local function IsVRPlayer(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
end

local function IsPlayerSitting(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Sit
end

local function HasBeenFlung(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = humanoid and humanoid.RootPart
    return rootPart and rootPart.Velocity.Magnitude > 500
end

local function SkidFling(TargetPlayer)
    if IsPlayerSitting(TargetPlayer.Character) then
        return true
    end

    -- Enhanced spectating logic
    if not HasBeenFlung(TargetPlayer.Character) and TargetPlayer.Character and TargetPlayer.Character:FindFirstChildOfClass("Humanoid") then
        workspace.CurrentCamera.CameraSubject = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart

    if Character and Humanoid and RootPart then
        getgenv().OldPos = RootPart.CFrame
        
        local FPos = function(BasePart, Pos, Ang)
            local TargetCore = BasePart.Position
            local OffsetDistance = 1
            
            if IsVRPlayer(TCharacter) then
                TargetCore = BasePart.Position + Vector3.new(0, 2, 0)
            end
            
            local SpinPosition = Vector3.new(
                TargetCore.X + math.cos(math.rad(Ang)) * OffsetDistance,
                TargetCore.Y,
                TargetCore.Z + math.sin(math.rad(Ang)) * OffsetDistance
            )
            
            RootPart.CFrame = CFrame.new(SpinPosition) * CFrame.Angles(0, math.rad(Ang), 0)
            Character:SetPrimaryPartCFrame(CFrame.new(SpinPosition) * CFrame.Angles(0, math.rad(Ang), 0))
            RootPart.Velocity = Vector3.new(9e9, 9e9 * 15, 9e9)
            RootPart.RotVelocity = Vector3.new(0, 9e9, 0)
        end
        
        local attempts = 0
        local maxAttempts = 10
        
        local function AttemptFling(BasePart)
            local TimeToWait = 1.5
            local Time = tick()
            local Angle = 0
            
            repeat
                if RootPart and THumanoid then
                    Angle = Angle + SPIN_SPEED
                    FPos(BasePart, CFrame.new(0, 0, 0), Angle)
                    task.wait(0.01)
                    
                    if IsPlayerSitting(TCharacter) then
                        return true
                    end
                end
            until HasBeenFlung(TCharacter) or tick() > Time + TimeToWait
            
            return HasBeenFlung(TCharacter)
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e9, 9e9, 9e9)
        BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        repeat
            if TRootPart then
                local success = AttemptFling(TRootPart)
                if success then break end
            end
            attempts = attempts + 1
            task.wait(0.1)
        until attempts >= maxAttempts or IsPlayerSitting(TCharacter)
        
        BV:Destroy()
        
        RootPart.CFrame = getgenv().OldPos
        Character:SetPrimaryPartCFrame(getgenv().OldPos)
        
        return HasBeenFlung(TCharacter)
    end
end

local function FlingAllPlayers()
    local PlayerList = Players:GetPlayers()
    for _, Target in pairs(PlayerList) do
        if Target ~= Player then
            local success = false
            repeat
                success = SkidFling(Target)
                task.wait(0.1)
            until success or IsPlayerSitting(Target.Character)
        end
    end
    workspace.CurrentCamera.CameraSubject = Player.Character:FindFirstChildOfClass("Humanoid")
end

local function StartContinuousFling()
    local running = true
    
    local function checkAlive()
        return Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0
    end
    
    spawn(function()
        while running and checkAlive() do
            FlingAllPlayers()
            task.wait(0.1)
        end
    end)
    
    Player.CharacterRemoving:Connect(function()
        running = false
    end)
end

StartContinuousFling()
