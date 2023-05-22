wait(.1)
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
workspace.CurrentCamera.CameraSubject = humanoid
game.Lighting.Sharingan.Enabled = false
local mouse = player:GetMouse()
humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)


local resetBindable = Instance.new("BindableEvent")

resetBindable.Event:connect(function()
	if game.ReplicatedStorage.laala == true then return end
	if character.Effects:FindFirstChild("Combat") then return end
	if (os.time() - game.ReplicatedStorage.Remotes.GetStat:InvokeServer("LastTimeRespawned")) < 1800 then return end
	if character.Effects:FindFirstChild("Ragdolled") then return end
	if character:FindFirstChild("Carrying") then return end
	if character.Effects:FindFirstChild("Executable") then return end
	if character.Effects:FindFirstChild("FreezeInput") then return end

	game.ReplicatedStorage.Remotes.RespawnEvent:FireServer("RespawnPassword")

end)

game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)

local Root = character:WaitForChild("HumanoidRootPart")
local effects = character:WaitForChild("Effects")
local animator = humanoid:WaitForChild("Animator")
local UserInputService = game:GetService("UserInputService")

local shared = require(game.ReplicatedStorage:WaitForChild("Shared"))
local w = false
local a = false	
local s = false
local d = false

local dashCD = false
local jumpCD = false

local sprintSpeedBoost = Instance.new("IntValue")
sprintSpeedBoost.Name = "Speed"
sprintSpeedBoost.Value = 9
local sprintTick = 0
local sprinting = false

local animfolder = character:WaitForChild("Anims")
local sprintAnim = animator:LoadAnimation(animfolder:WaitForChild("Run"))
local jinSprintAnim = animator:LoadAnimation(animfolder:WaitForChild("JinRun"))
local kunaiSprint = animator:LoadAnimation(animfolder:WaitForChild("KunaiRun"))
local swordSprint = animator:LoadAnimation(animfolder:WaitForChild("SwordRun"))
local bigSwordSprint = animator:LoadAnimation(animfolder:WaitForChild("BigSwordRun"))
local fanSprint = animator:LoadAnimation(animfolder:WaitForChild("FanRun"))
local doubleSprint = animator:LoadAnimation(animfolder:WaitForChild("SameRun"))
local chakraBladesSprint = animator:LoadAnimation(animfolder:WaitForChild("ChakraBladesRun"))
local kibaBladesSprint = animator:LoadAnimation(animfolder:WaitForChild("KibaBladesRun"))
local slideAnim = humanoid:LoadAnimation(animfolder:WaitForChild("Slide"))

local sprintAnims = {
	["Kunai"] = kunaiSprint,
	["Tanto"] = kunaiSprint,
	["Katana"] = swordSprint,
	["Samehada"] = bigSwordSprint,
	["Release Samehada"] = bigSwordSprint,
	["w"] = bigSwordSprint,
	["Kiba Blades"] = kibaBladesSprint,
	["Spiraling Strike"] = kibaBladesSprint,
	["Sixfold"] = kibaBladesSprint,
	["Mortal Blades"] = kibaBladesSprint,
	["Hiramekarei"] = swordSprint,
	["Release Hiramekarei"] = swordSprint,
	["Thrust"] = swordSprint,
	["Chakra Scalpel"] = kunaiSprint,
	["Black Rod"] = swordSprint,
	["Scythe"] = swordSprint,
	["Lick"] = swordSprint,
	["Flash Cut"] = swordSprint,
	["Ice Sword"] = swordSprint,
	["Bone Sword"] = swordSprint,
	["Flashing Strikes"] = swordSprint,
	["Executioner Combo"] = bigSwordSprint,
	["Kabutowari"] = swordSprint,
	["Air Cutter"] = swordSprint,
	["Soaring Dragon Flash"] = swordSprint,
	["Tornado Dance"] = swordSprint,
	["Flying Shallow"] = chakraBladesSprint,
	["Chakra Blades"] = chakraBladesSprint
}

local keyBinds = {
	["Dash"] = Enum.KeyCode.Q,
	["Crouch"] = Enum.KeyCode.C,
	["Jump"] = Enum.KeyCode.Space,
	["W"] = Enum.KeyCode.W,
	["A"] = Enum.KeyCode.A,
	["S"] = Enum.KeyCode.S,
	["D"] = Enum.KeyCode.D,
	["Toggle"] = Enum.KeyCode.T
}

--kunaiSprint:AdjustSpeed(99999)
--swordSprint:AdjustSpeed(99999)

local wallJump = 1
local wallJumpCD = false
local lastWall = nil

local crouched = false

local crouchSpeedBoost = Instance.new("IntValue")
crouchSpeedBoost.Name = "Speed"
crouchSpeedBoost.Value = -6

local crouchJumpBoost = Instance.new("IntValue")
crouchJumpBoost.Name = "Jump"
crouchJumpBoost.Value = -666666666

local treeSpeedBoost = Instance.new("IntValue")
treeSpeedBoost.Name = "Speed"
treeSpeedBoost.Value = -999999999

local crouchAnim = animator:LoadAnimation(animfolder.Crouch)

for i,v in pairs(animfolder:GetChildren()) do
	animator:LoadAnimation(v)
end

local inAir = humanoid.FloorMaterial == Enum.Material.Air
local canDouble = true
local canDash = true
local firstWall = true
local treeJumping = false
local lastTreeJump = 0

game:GetService("UserInputService").InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if inputObject.KeyCode == Enum.KeyCode.W and player.Character.Effects:FindFirstChild("FreezeInput") then
		script.Walk:FireServer(true)
	end
end)

local Sprint = function(state)
	if state then
		if not shared.CanAttack(character, {"Hydrification","Carryingg"}) and not effects:FindFirstChild("CanMove") then return end
		if effects:FindFirstChild("TrackPuppet") or effects:FindFirstChild("NoSprint") then return end
		if effects:FindFirstChild("HellSwamp") then return end
		sprintSpeedBoost.Parent = character.Effects
		sprinting = true

		if not inAir then
			if not effects:FindFirstChild("JinCloak2") then
				sprintAnim:Play()
				fanSprint:Play()
			else
				jinSprintAnim:Play()
			end
		end

	else
		sprintSpeedBoost:Remove()
		sprinting = false
		sprintAnim:Stop()
		fanSprint:Stop()
		jinSprintAnim:Stop()
	end
end

local latestVel = character.HumanoidRootPart.Velocity.Y
local lowestVel = character.HumanoidRootPart.Velocity.Y


local function drawRay(startPos, lookAt, distance, ignoreList)
	local ray = Ray.new(startPos, (lookAt - startPos).unit * distance)
	local hitPart, hitPos, hitNormal = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList, false, true)
	return hitPart, hitPos, hitNormal
end
local function rayCast(origin, direction)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {workspace.Projectiles,workspace.Alive}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local rayResult = workspace:Raycast(origin, direction, rayParams)
	return rayResult
end

-- open source function used for ledge detection
function distanceToSegment(v,a, b)
	--Returns the distance from the point v to the line segment between the points a and b
	local ab = b - a
	local av = v - a

	if (av:Dot(ab) <= 0) then -- Point is lagging behind start of the segment, so
		--return av.Magnitude -- Use distance to start of segment instead.
	end

	local bv = v - b

	if (bv:Dot(ab) >= 0 ) then -- Point is advanced past the end of the segment, so
		--return bv.Magnitude -- Use distance to end of the segment instead
	end

	return (ab:Cross(av)).Magnitude / ab.Magnitude -- Perpendicular distance of point to segment
end

local function ClosetPointOnSegment(v,a,b)
	local ab = b - a;
	local av = v - a
	local  i = av:Dot(ab) /(ab.x^2+ab.y^2)
	i = math.clamp(i, 0,1)
	return a + i*ab 
end

local function newToolSprint(child)
	if not child:IsA("Tool") then return end
	if not child:FindFirstChild("Stats") then return end
	local toolSprintAnim
	local katana = false
	local kunai = false
	local giant = false

	if sprintAnims[child.Name] then
		toolSprintAnim = sprintAnims[child.Name]
	end

	if child.Stats:FindFirstChild("Katana") then
		toolSprintAnim = toolSprintAnim or swordSprint
		katana = true
	elseif child.Stats:FindFirstChild("Kunai") then
		toolSprintAnim = toolSprintAnim or kunaiSprint
		kunai = true
	elseif child.Stats:FindFirstChild("GiantSword") then
		toolSprintAnim = toolSprintAnim or bigSwordSprint
		giant = true
	else
		return
	end

	if toolSprintAnim and sprinting then
		if not inAir then
			toolSprintAnim:Play(0)
		end
		for i,v in pairs(sprintAnims) do
			if v ~= toolSprintAnim then
				v:Stop()
			end
		end
		local gripPart
		repeat game:GetService("RunService").RenderStepped:Wait()
			--if child.Name == "Katana" or child.Name == "Thrust" or child.Name == "Flash Cut" or child.Name == "Black Rod" or child.Name == "Scythe" or child.Name == "Lick" or child.Name == "Ice Sword" or child.Name == "Hiramekarei" or child.Name == "Samehada" or child.Name == "Flashing Strikes" or child.Name == "Executioner's Blade" or child.Name == "Executioner Combo" or child.Name == "Air Cutter" or child.Name == "Soaring Dragon Flash" or child.Name == "Tornado Dance" then
			if katana or giant then
				if character:FindFirstChild("Katana") then
					for i,v in pairs(character:GetChildren()) do
						if v:IsA("BasePart") and v.Name == "Katana" and v:FindFirstChild("Wep") and v:FindFirstChild("GripWeld") or v.Name == "Katana2" then
							gripPart = v.GripWeld.Part1
						end
					end
				end
				--	elseif child.Name == "Kunai" or child.Name == "Chakra Scalpel" or child.Name == "Tanto" or child.Name == "Kabutowari" then
			elseif kunai then
				for i,v in pairs(character:GetChildren()) do
					if v:IsA("BasePart") and v.Name == "Kunai" and v:FindFirstChild("Wep") and v:FindFirstChild("GripWeld") then
						gripPart = v.GripWeld.Part1
					end
				end
			end
		until gripPart ~= nil or child.Parent ~= character or not sprinting
		--print(gripPart.Name)
		repeat game:GetService("RunService").RenderStepped:Wait()
			--print(inAir)
			if toolSprintAnim.IsPlaying and inAir then
				toolSprintAnim:Stop()
			elseif not toolSprintAnim.IsPlaying and not inAir then
				toolSprintAnim:Play(0)
			end
		until child.Parent ~= character or not sprinting
		spawn(function()
			local stopAnim
			repeat game:GetService("RunService").RenderStepped:Wait()
				--if child.Name == "Katana" or child.Name == "Thrust" or child.Name == "Flash Cut" or child.Name == "Black Rod" or child.Name == "Scythe" or child.Name == "Lick" or child.Name == "Ice Sword" or child.Name == "Hiramekarei" or child.Name == "Samehada" or child.Name == "Flashing Strikes" or child.Name == "Executioner's Blade" or child.Name == "Executioner Combo" or child.Name == "Air Cutter" or child.Name == "Soaring Dragon Flash" or child.Name == "Tornado Dance" then
				if katana or giant then
					for i,v in pairs(character:GetChildren()) do
						if v:IsA("BasePart") and v.Name == "Katana" and v:FindFirstChild("Wep") and v:FindFirstChild("GripWeld") then
							stopAnim = not v.GripWeld.Part1
						end
					end
					--	elseif child.Name == "Kunai" or child.Name == "Chakra Scalpel" or child.Name == "Tanto" or child.Name == "Kabutowari"  then
				elseif kunai then
					for i,v in pairs(character:GetChildren()) do
						if v:IsA("BasePart") and v.Name == "Kunai" and v:FindFirstChild("Wep") and v:FindFirstChild("GripWeld") then
							stopAnim = not v.GripWeld.Part1
						end
					end
				end
			until stopAnim or not sprinting
			--print("ok")
			toolSprintAnim:Stop()
		end)
	end

end

character.ChildAdded:Connect(newToolSprint)

local AimAt = false
local AimedAt 
local Camera = workspace.CurrentCamera

character.ChildAdded:Connect(function(Child)
	if Child:IsA("Tool") and Child:FindFirstChild("AutoAim") then
		print("START THE AUTO AIM THINGY PLS")
		AimAt = true
		local MaxRange,MinRange = Child:FindFirstChild("MaxRange").Value,  Child:FindFirstChild("MinRange").Value
		coroutine.wrap(function()
			while AimAt == true do 
				task.wait()
				local ToReturn = nil;
				local Dist = 0.15;
				for i, v in pairs(workspace.Alive:GetChildren()) do
					if not v.Effects:FindFirstChild("NoTarg") and v.Name ~= player.Name and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Torso") and v.Torso.Transparency ~= 1 and v.Humanoid.Health > 0 then
						local Root = v.HumanoidRootPart;
						if (CFrame.new(Camera.CFrame.p, Root.Position).lookVector - Camera.CFrame.lookVector).Magnitude < Dist then
							Dist = (CFrame.new(Camera.CFrame.p, Root.Position).lookVector - Camera.CFrame.lookVector).magnitude;
							ToReturn = v;
							AimedAt = ToReturn
						end;
					end;
				end;

				if ToReturn ~= nil then
					AimedAt = ToReturn
					print(ToReturn.Name)
					local Mag = (Root.CFrame.Position - ToReturn.HumanoidRootPart.Position).Magnitude
					if Mag > MinRange and Mag <= MaxRange then
						AimedAt = ToReturn
						
						for _,v in pairs(workspace.Alive:GetChildren()) do 
							if v:FindFirstChild("AimedAt") and ToReturn ~= v then
								v.AimedAt:Destroy()
							end
						end
						
						if not ToReturn.HumanoidRootPart:FindFirstChild("AimedAt") then
							local high = game.ReplicatedStorage.targetcircle:Clone()
							high.Name = "AimedAt"
							high.Parent = ToReturn.HumanoidRootPart
						end
					else
						AimedAt = nil 
						ToReturn = nil
						for _,v in pairs(workspace.Alive:GetChildren()) do 
							if v:FindFirstChild("AimedAt") then
								v.AimedAt:Destroy()
							end
						end
					end
				elseif ToReturn ~= nil and ToReturn ~= AimedAt then
					ToReturn = AimedAt
					for _,v in pairs(workspace.Alive:GetChildren()) do 
						if v:FindFirstChild("AimedAt") and AimedAt ~= v then
							v.AimedAt:Destroy()
						end
					end
				else
					for _,v in pairs(workspace.Alive:GetChildren()) do 
						if v:FindFirstChild("AimedAt") then
							v.AimedAt:Destroy()
						end
					end
				end


				--[[print("DOING THE AUTO AIM AAAAAAAAAAAA")
				task.wait()
				mouse.TargetFilter = workspace.Projectiles

				if mouse.Target and mouse.Target.Parent and mouse.Hit and mouse.Hit.Position then
					local Target
					--return mouse.Hit, mouse.Hit.p, mouse.Target, mouse.UnitRay, lockCenter
					if not mouse.Target.Parent:FindFirstChild("Humanoid") then
						for i,v in pairs(workspace.Alive:GetChildren()) do
							--if v ~= character then
							local mag = (mouse.Hit.Position - v.HumanoidRootPart.Position).Magnitude
							if mag < 10 then
								Target = v.HumanoidRootPart
							end
							--end
						end
					end

					if mouse.Target.Parent == character then AimedAt = nil for _,v in pairs(workspace.Alive:GetChildren()) do 
							if v:FindFirstChild("AimedAt") and AimedAt ~= v then
								v.AimedAt:Destroy()
							end
						end continue end
					if not mouse.Target.Parent:FindFirstChild("Humanoid") or mouse.Target.Parent.Parent:FindFirstChild("Humanoid") then AimedAt = nil for _,v in pairs(workspace.Alive:GetChildren()) do 
							if v:FindFirstChild("AimedAt") and AimedAt ~= v then
								v.AimedAt:Destroy()
							end
						end
						continue 
					end
					local Mag = (Root.CFrame.Position - mouse.Target.Parent.HumanoidRootPart.Position).Magnitude
					if Mag > MaxRange then AimedAt = nil for _,v in pairs(workspace.Alive:GetChildren()) do 
							if v:FindFirstChild("AimedAt") and AimedAt ~= v then
								v.AimedAt:Destroy()
							end
						end
						continue 
					end
					if Mag < MinRange then AimedAt = nil for _,v in pairs(workspace.Alive:GetChildren()) do 
							if v:FindFirstChild("AimedAt") and AimedAt ~= v then
								v.AimedAt:Destroy()
							end
						end
						continue 
					end
					print("REACHING HERE")
					AimedAt = mouse.Target.Parent
					if not mouse.Target.Parent:FindFirstChild("AimedAt") then
						local Highlight = Instance.new("Highlight")
						Highlight.Name = "AimedAt"
						Highlight.Parent = mouse.Target.Parent
					end
					
					for _,v in pairs(workspace.Alive:GetChildren()) do 
						if v:FindFirstChild("AimedAt") and AimedAt ~= v then
							v.AimedAt:Destroy()
						end
					end
				elseif mouse.Target.Parent ~= AimedAt then
					print("Delete old highlight")
					for _,v in pairs(workspace.Alive:GetChildren()) do 
						if v:FindFirstChild("AimedAt") and AimedAt ~= v then
							v.AimedAt:Destroy()
						end
					end
				else
					for _,v in pairs(workspace.Alive:GetChildren()) do 
						if v:FindFirstChild("AimedAt") then
							v.AimedAt:Destroy()
						end
					end
					AimedAt = nil
				end]]
			end
		end)()
	end
end)

character.ChildRemoved:Connect(function(Child)
	if Child:IsA("Tool") and Child:FindFirstChild("AutoAim") then
		AimAt = false
		AimedAt = nil
		task.wait(.25)
		for _,v in pairs(workspace.Alive:GetChildren()) do 
			if v:FindFirstChild("AimedAt") then
				v:FindFirstChild("AimedAt"):Destroy()
			end
		end
	end
end)
--[[
spawn(function()
	
	while true do
		game:GetService("RunService").RenderStepped:Wait()
		if sprinting and not inAir then
			local t = ""
			for i,v in pairs(character:GetChildren()) do
				if v:IsA("Tool") then
					t = v.Name
				end
			end
			if t == "Kunai" then
				delay(0.1,function()
					swordSprint:Stop(0)
					kunaiSprint:Play(0)
				end)
			else
				delay(0.1,function()
					kunaiSprint:Stop(0)
				end)
			end
			if t == "Katana" then
				delay(0.1,function()
					kunaiSprint:Stop(0)
					swordSprint:Play(0)
				end)
			else
				delay(0.1,function()
					swordSprint:Stop(0)
				end)
			end
		else
			delay(0.1,function()
				swordSprint:Stop(0)
				kunaiSprint:Stop(0)
			end)
		end
	
	end
	
end)
]]
local function floorMatChanged()
	if humanoid.FloorMaterial == Enum.Material.Air then

		latestVel = character.HumanoidRootPart.Velocity.Y
		lowestVel = character.HumanoidRootPart.Velocity.Y

		local lastPos = character.HumanoidRootPart.CFrame.p.y

		inAir = true

		if sprinting then
			jinSprintAnim:Stop()
			sprintAnim:Stop()
			fanSprint:Stop()
		end

		local dealtFall = false
		repeat wait()
			if not character:FindFirstChild("HumanoidRootPart") then return end
			local latestVel = character.HumanoidRootPart.Velocity.Y

			if latestVel < lowestVel then
				lowestVel = latestVel
			else
				if lowestVel < -135 and dealtFall == false then
					dealtFall = true
					if lowestVel > -170 then
						script.Fall:FireServer(-lowestVel - -lowestVel * 0.8)
					else
						script.Fall:FireServer(-lowestVel - -lowestVel * 0.5)
					end
				end
			end

			--print(lowestVel)

		until humanoid.FloorMaterial ~= Enum.Material.Air

		--ez fixx
		if lowestVel < -135 and dealtFall == false then
			dealtFall = true
			if lowestVel > -170 then
				script.Fall:FireServer(-lowestVel - -lowestVel * 0.8)
			else
				script.Fall:FireServer(-lowestVel - -lowestVel * 0.5)
			end
		end

		inAir = false
		firstWall = true

		if sprinting then
			if not effects:FindFirstChild("JinCloak2") then
				sprintAnim:Play()
				fanSprint:Play()
			else
				jinSprintAnim:Play()
			end
		end

		lastWall = nil

		local newPos = character.HumanoidRootPart.CFrame.p.y
		local dist = lastPos - newPos

		if lowestVel <= -60 then
			local anim = animator:LoadAnimation(animfolder.Land):Play()

			local speed = Instance.new("IntValue",effects)
			speed.Name = "Speed"
			speed.Value = -8
			game.Debris:AddItem(speed, 0.35)

		end

	end
end
floorMatChanged()
humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(floorMatChanged)

humanoid:GetPropertyChangedSignal("Jump"):Connect(function()

	if humanoid.Jump then
		repeat wait() until humanoid:GetState() == Enum.HumanoidStateType.Landed

		if effects:FindFirstChild("Combat") then

			jumpCD = true
			delay(0.5,function()
				jumpCD = false
			end)

		end

	end

end)

local ziplining = false
local zipCD = false
local function zipline(part, fromStartPos)
	if zipCD then return end
	if ziplining then return end
	if not fromStartPos then return end
	local startP,endP = part.CFrame * CFrame.new(0,0,part.Size.Z/2),part.CFrame * CFrame.new(0,0,-part.Size.Z/2)
	local hrtPos = character.HumanoidRootPart.CFrame
	local point = ClosetPointOnSegment(hrtPos.p,startP.p,endP.p)
	local pToCF = CFrame.new(point,endP.p)
	local offsetFromStart = CFrame.new(startP.p,endP.p):ToObjectSpace(pToCF)

	--character.HumanoidRootPart.Anchored = true
	--wait(0.4)
	--character.HumanoidRootPart.Anchored = false

	ziplining = true
	zipCD = true

	local debugP = Instance.new("Part")
	debugP.Size = Vector3.new(1,1,1)
	debugP.CanCollide = false
	debugP.Anchored = true
	debugP.Transparency = 1
	debugP.Parent = workspace

	local bodyPos = Instance.new("BodyPosition")
	bodyPos.MaxForce = Vector3.new(100000,100000,100000)
	bodyPos.D = 400
	bodyPos.Parent = Root

	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(100000,100000,100000)
	bodyGyro.D = 400
	bodyGyro.CFrame = CFrame.new(startP.p,Vector3.new(endP.p.X,startP.p.Y,endP.p.Z))
	bodyGyro.Parent = Root

	local zipStart = humanoid:LoadAnimation(animfolder.ZiplineStart)
	local zipIdle = humanoid:LoadAnimation(animfolder.ZiplineIdle)
	zipStart:Play()

	coroutine.wrap(function()
		wait(zipStart.Length)
		if bodyPos.Parent then
			zipIdle:Play()
		end
	end)()

	local newCF = startP * offsetFromStart
	repeat
		newCF = newCF * CFrame.new(0,0,-2.5)
		bodyPos.Position = newCF.p
		debugP.Position = newCF.p
		wait()
	until (newCF.p - endP.p).magnitude <= 1.5 or not ziplining

	zipIdle:Stop()
	zipStart:Stop()
	bodyPos:Destroy()
	bodyGyro:Destroy()
	ziplining = false
	coroutine.wrap(function()
		wait(2)
		zipCD = false
	end)()

end

local canDash2 = true
character:WaitForChild("HumanoidRootPart").ChildAdded:Connect(function(child)
	if child.Name == "AirComboVelocity" and canDash2 then
		canDash2 = false
		repeat wait() until humanoid.FloorMaterial ~= Enum.Material.Air
		canDash2 = true
	end
end)

local canSlide = true
local function slide()
	--if player.Name ~= "SlussBat" then return end
	if not canSlide then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	local rootVel = character.HumanoidRootPart.Velocity * Vector3.new(1,0,1)
	if rootVel.Magnitude < 15 then return end

	canSlide = false

	local toDestroy = {}

	local slideVal = Instance.new("Folder")
	slideVal.Name = "Sliding"		
	slideVal.Parent = effects
	table.insert(toDestroy,slideVal)

	local speed = Instance.new("IntValue")
	speed.Name = "Speed"
	speed.Value = -9999
	speed.Parent = effects
	table.insert(toDestroy,speed)

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(100000,100000,100000)
	bodyVel.Velocity = character.HumanoidRootPart.CFrame.lookVector*(rootVel.Magnitude)
	bodyVel.Parent = character.HumanoidRootPart
	table.insert(toDestroy,bodyVel)

	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1000000,1000000,1000000)
	bodyGyro.D = 500
	bodyGyro.P = 1000000
	bodyGyro.CFrame = character.HumanoidRootPart.CFrame
	bodyGyro.Parent = character.HumanoidRootPart
	table.insert(toDestroy,bodyGyro)


	--slideAnim.Priority = Enum.AnimationPriority.Action
	--slideAnim.Looped = true
	slideAnim:Play()
	--print("Play anim")

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	local origVel = bodyVel.Velocity.Magnitude
	local currentVel = origVel
	local startOrientation = character.HumanoidRootPart.Orientation
	local currentOrientation = startOrientation
	local wasSDE = false
	local origVelLV = (bodyVel.Velocity * Vector3.new(1,0,1)).Unit

	repeat
		local timeElapsed = game:GetService("RunService").Heartbeat:Wait()
		if effects:FindFirstChild("Sliding") then
			local hitPart,hitPos,hitNormal = drawRay(character.HumanoidRootPart.CFrame.p, (character.HumanoidRootPart.CFrame * CFrame.new(0,-5,0)).p, 5, {workspace.Projectiles,workspace.Alive})
			if hitPart and shared.CanAttack(character, {"Stunnedd"}) then
				-- sliding
				--	print(hitNormal)
				--print(ledgeAngle)
				--ledgeAngle = math.max(ledgeAngle,0)

				-- make CF pointing up from floor and rotate to point forward
				local tnewCF = character.HumanoidRootPart.CFrame
				local newVel = bodyVel.Velocity

				local hipH = character["Left Leg"].Size.Y + (0.5 * character.HumanoidRootPart.Size.Y) + humanoid.HipHeight
				local newCF = CFrame.new(hitPos, hitPos + hitNormal) * CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0)) * CFrame.new(0,hipH,0)

				local origAngles = {character.HumanoidRootPart.CFrame:ToOrientation()}
				local newAngles = {newCF:ToOrientation()}

				--[[ RETARDED SHIT FIX CUZ IT NOT IAWJFMAIDJSKRGSRJGF]]
				for i,v in pairs(origAngles) do
					if math.abs(v) < .001 then
						origAngles[i] = 0
					end
				end
				for i,v in pairs(newAngles) do
					if math.abs(v) < .001 then
						origAngles[i] = 0
					end
				end				

				local ledgeAngle = math.deg(origAngles[1])
				local slidingDownLedge = ledgeAngle < 0

				if slidingDownLedge then
					tnewCF = CFrame.new(newCF.p) * CFrame.fromOrientation(newAngles[1],newAngles[2],newAngles[3])
				else
					tnewCF = CFrame.new(newCF.p) * CFrame.fromOrientation(newAngles[1],origAngles[2],origAngles[3])
				end


				if not wasSDE and slidingDownLedge then
					currentVel += 10
				end
				wasSDE = slidingDownLedge

				if slidingDownLedge then
					local increasePerSec = 20 * math.abs(origAngles[1])
					currentVel += (increasePerSec*timeElapsed)
				else
					local decreasePerSec = 20
					currentVel -= (decreasePerSec*timeElapsed)
				end

				newVel = tnewCF.LookVector * currentVel

				local tooSharp = ((newVel * Vector3.new(1,0,1)).Unit - origVelLV).magnitude > .5

				local loweredSlight = character.HumanoidRootPart.CFrame * CFrame.new(0,-hipH * .8,0)
				local hitPart2,hitPos,hitNormal = drawRay(loweredSlight.p, (loweredSlight * CFrame.new(0,0,-5)).p, 2, {workspace.Projectiles,workspace.Alive})
				--print(hitPart2 ~= nil and hitPart2:GetFullName(),'wall')

				if currentVel < .5 or (hitPart2 and hitPart2 ~= hitPart and hitNormal.Y ~= 1) or tooSharp then
					effects.Sliding:Destroy()
				else
					character.HumanoidRootPart.CFrame = tnewCF
					bodyVel.Velocity = newVel
					bodyGyro.CFrame = character.HumanoidRootPart.CFrame
				end
			else
				effects.Sliding:Destroy()
			end
		end
	until not effects:FindFirstChild("Sliding")
	
	spawn(function()
		for i,v in pairs(toDestroy) do
			v:Destroy()
		end
	end)
	--print("stop anim")
	slideAnim:Stop()
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	task.delay(.5,function()
		canSlide = true
	end)

end

local tog = true

UserInputService.InputBegan:connect(function(input,gameProcessed)

	if gameProcessed == true then return end

	local key = input.KeyCode

	if key == keyBinds["Toggle"] then
		if not effects:FindFirstChild("Rej") then return end
		local backpack = player.Backpack
		if tog then
		else
			script.Toggle:FireServer(true)
		end
		tog = not tog
	end

	if key == keyBinds["Jump"] then
		--WallJumpz d:
		if ziplining then
			ziplining = false
		end

		if humanoid.FloorMaterial == Enum.Material.Air then
			if not shared.CanAttack(character, {"Hydrification","Carryingg"}) and not effects:FindFirstChild("CanMove") then return end
			if wallJumpCD then return end
			if treeJumping then return end

			local ignore = {game.Workspace.Alive, game.Workspace.Projectiles}
			local wallRay = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.lookVector * 3)
			--local wallHit, wallPos = workspace:FindPartOnRay(wallRay, character)
			local wallHit, wallPos = game.Workspace:FindPartOnRayWithIgnoreList(wallRay,ignore)

			local treeHit,treePos

			if not effects:FindFirstChild("Combat2") and not effects:FindFirstChild("SteelProc") and not effects:FindFirstChild("Hydrification") then
				for i=0,60,1 do
					local rotatedCF = Root.CFrame * CFrame.Angles(math.rad(-i),0,0)
					local treeRay = Ray.new(Root.CFrame.p,rotatedCF.LookVector * 20)
					local tempHit,tempPos = workspace:FindPartOnRayWithIgnoreList(treeRay,{workspace.Alive,workspace.Projectiles})
					if tempHit 
						and tempHit.Anchored 
						and (tempHit.Name == "Leaves" or tempHit.Name == "Branch" or tempHit.Name == "BranchPart" or tempHit.Name == "Leafs") 
						and tempHit.Transparency < 1 then

						treeHit,treePos = tempHit,tempPos
						break
					end
				end
			end

			local zipHit,zipPos

			for i=-60,60,1 do
				local rotatedCF = Root.CFrame * CFrame.Angles(math.rad(i),0,0)
				local zipRay = Ray.new(Root.CFrame.p,rotatedCF.LookVector * 5)
				local tempHit,tempPos = workspace:FindPartOnRayWithWhitelist(zipRay,{workspace.Ziplines})
				if tempHit and tempHit.Anchored and tempHit.Transparency < 1 then
					zipHit,zipPos = tempHit,tempPos
					break
				end
			end

			if treeHit then
				treeSpeedBoost.Parent = effects
				local recentTreeJump = tick() - lastTreeJump < .8
				--print(tick() - lastTreeJump)
				treeJumping = true
				treePos = treePos + Vector3.new(0,3,0) -- to account for char's size so it actually looks like they are on the tree
				local treeJumpAnim = animator:LoadAnimation(animfolder.TreeJump)
				treeJumpAnim:Play()
				script.TreeJump:FireServer(recentTreeJump)

				local tween = game:GetService("TweenService"):Create(Root,TweenInfo.new(0.3),{CFrame = CFrame.new(treePos,treePos + Root.CFrame.LookVector)})
				tween:Play()
				treeJumpAnim:Play(.1,1,0) -- fadeTime,weight,speed

				local velCon
				velCon = game:GetService("RunService").RenderStepped:Connect(function() -- basically anchored, 
					-- but roblox doesn't replicate physics of locally anchored parts so gotta do this
					if Root then
						Root.Velocity = Vector3.new(0,0,0)
						Root.RotVelocity = Vector3.new(0,0,0)
					end
				end)
				wait(0.3)

				treeJumpAnim:AdjustSpeed(1)
				if recentTreeJump then
					treeJumpAnim.TimePosition = 0.3
					wait(.1)
				else
					treeJumpAnim.TimePosition = 0.2
					wait(.2)
				end

				velCon:Disconnect()
				treeSpeedBoost:Remove()

				local tickThing = tick()
				local moveDirAdd = humanoid.MoveDirection
				local bodyVel = Instance.new("BodyVelocity")
				bodyVel.MaxForce = Vector3.new(100000,100000,100000)
				bodyVel.P = 3000
				bodyVel.Velocity = moveDirAdd * 70 + Vector3.new(0,25,0)
				bodyVel.Parent = Root
				game:GetService("Debris"):AddItem(bodyVel,0.4)
				local rCon
				rCon = game:GetService("RunService").RenderStepped:Connect(function()
					if bodyVel and bodyVel.Parent ~= nil then
						moveDirAdd = moveDirAdd:lerp(humanoid.MoveDirection,0.1)
						local velToSet = moveDirAdd * 70
						if tick() - tickThing < .2 then
							velToSet = velToSet + Vector3.new(0,45,0)
						else
							velToSet = (velToSet + Vector3.new(0,45,0)):lerp(velToSet,math.clamp(((tick() - tickThing)-.2) * 5,0,1))
						end
						bodyVel.Velocity = velToSet
					else
						rCon:Disconnect()
					end
				end)
				wait(0.4)
				treeJumping = false
				lastTreeJump = tick()
				canDouble = true
				local speed = Instance.new("IntValue",effects)
				speed.Name = "Speed"
				speed.Value = 15

				local land
				land = game["Run Service"].RenderStepped:connect(function()
					if humanoid.FloorMaterial ~= Enum.Material.Air then
						--	print("LANDDE")
						speed:Destroy()
						land:Disconnect()
					end
				end)
				spawn(function()
					wait(1)
					speed:Destroy()
					land:Disconnect()
				end)

			elseif zipHit and not ziplining and not zipCD then
				zipline(zipHit)
			elseif wallHit and wallHit.Name ~= "NoClimb" and wallHit.Name ~= "No_Climb" and not effects:FindFirstChild("Hydrification") then
				-- WallJump
				if wallHit.Anchored and wallHit.CanCollide and not effects:FindFirstChild("SteelProc") then

					latestVel = 0
					lowestVel = 0

					local top = false

					-- old
					--[[
					if (wallHit.Position.Y + (wallHit.Size.Y / 2)) - character.HumanoidRootPart.Position.Y <= 4 then
						top = (wallHit.Position.Y + (wallHit.Size.Y / 2)) - character.HumanoidRootPart.Position.Y
					end
					]]
					local edges = { -- Info on edge/corner vectors

						-- "Top"
						{
							Vector3.new(1,1,1),
							Vector3.new(-1,1,1),
						},
						{
							Vector3.new(1,1,1),
							Vector3.new(1,1,-1),
						},
						{
							Vector3.new(-1,1,-1),
							Vector3.new(1,1,-1),
						},
						{
							Vector3.new(-1,1,-1),
							Vector3.new(-1,1,1),
						},

						-- "Bottom"
						{
							Vector3.new(1,-1,1),
							Vector3.new(-1,-1,1),
						},
						{
							Vector3.new(1,-1,1),
							Vector3.new(1,-1,-1),
						},
						{
							Vector3.new(-1,-1,-1),
							Vector3.new(1,-1,-1),
						},
						{
							Vector3.new(-1,-1,-1),
							Vector3.new(-1,-1,1),
						},

						-- "Middle"
						{
							Vector3.new(1,1,1),
							Vector3.new(1,-1,1),
						},
						{
							Vector3.new(1,1,-1),
							Vector3.new(1,-1,-1),
						},
						{
							Vector3.new(-1,1,-1),
							Vector3.new(-1,-1,-1),
						},
						{
							Vector3.new(-1,1,1),
							Vector3.new(-1,-1,1),
						},
					}

					local closestEdge = math.huge

					for i,v in pairs(edges) do
						local point1 = (wallHit.CFrame * CFrame.new(wallHit.Size * (v[1]/2))).p
						local point2 = (wallHit.CFrame * CFrame.new(wallHit.Size * (v[2]/2))).p
						local v = (point1 - point2)
						local centerPoint = CFrame.new(point2 + 0.5*v, point1).Position
						local partCenter = (wallHit.CFrame + Vector3.new(0,1,0)).Position
						if centerPoint.Y > partCenter.Y then
							local edgeMag = distanceToSegment(Root.CFrame.p,point1,point2)
							--[[
							local visualPart = Instance.new("Part")
							local v = (point1 - point2)
							visualPart.CFrame = CFrame.new(point2 + 0.5*v, point1)
							visualPart.Size = Vector3.new(1, 1,v.Magnitude)
							visualPart.Parent = workspace
							visualPart.Color = Color3.fromRGB(255, 0, 4)
							visualPart.Transparency = 0.5
							visualPart.CanCollide = false
							visualPart.Anchored = true
							game:GetService("Debris"):AddItem(visualPart,2)
							]]
							if edgeMag < closestEdge then
								closestEdge = edgeMag
							end
						end
					end

					if closestEdge <= 9 then
						top = closestEdge
					end

					if lastWall == wallHit and not top then return end

					if not top then
						lastWall = wallHit
					end

					wallJumpCD = true

					if not top then
						if not firstWall then
							if wallJump == 1 then
								local anim = animator:LoadAnimation(animfolder.WallJump1):Play()
								wallJump = 2
							else
								local anim = animator:LoadAnimation(animfolder.WallJump2):Play()
								wallJump = 1
							end
						else
							local anim = animator:LoadAnimation(animfolder.WallStart):Play()
							firstWall = false
						end
					else
						local anim = animator:LoadAnimation(animfolder.Top):Play()
					end

					spawn(function()
						script.WallJump:FireServer(top)
					end)

					local bvel = Instance.new("BodyVelocity",character.HumanoidRootPart)
					bvel.MaxForce = Vector3.new(100000,100000,100000)
					local bpos = Instance.new("BodyPosition")
					bpos.MaxForce = Vector3.new(100000,100000,100000)
					bpos.D = 400
					if not top then
						bvel.Velocity = Vector3.new(0,0,0)
					else
						bvel.Velocity = Vector3.new(0,0,0)
						bvel:Remove()
						bpos.Position = (Root.CFrame + Vector3.new(0,top - 1,0)).p
						bpos.Parent = Root
					end
					wait(0.2)
					bpos:Destroy()
					bvel.Parent = Root

					if not top then
						local newVector = character.HumanoidRootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection) * Vector3.new(1,0,1)
						bvel.Velocity = (-character.HumanoidRootPart.CFrame.lookVector * 50) + Vector3.new(0,45,0)-- + (character.HumanoidRootPart.CFrame.rightVector * (newVector.X * 20)) + Vector3.new(0,45,0)
						game.Debris:AddItem(bvel, 0.01)
					else
						bvel.Velocity = Vector3.new(0,40,0)
						game.Debris:AddItem(bvel, 0.01)
					end

					wait(0.2)

					wallJumpCD = false

				end

			else
				-- Double Jump
				if canDouble then
					if not shared.CanAttack(character,{"Hydrification","Carryingg"}) and not effects:FindFirstChild("CanMove") then return end 
					--print("Double")

					local anim = humanoid:LoadAnimation(character.Anims.Double):Play()

					local bvel = Instance.new("BodyVelocity",character.HumanoidRootPart)
					bvel.MaxForce = Vector3.new(0,100000,0)
					bvel.Velocity = Vector3.new(0,40,0)
					game.Debris:AddItem(bvel, 0.1)

					canDouble = false
					canDash = true
					repeat wait() until inAir == false
					canDouble = true
					--canDash = true
				end

			end

		end	

		local d = false
	elseif key == Enum.KeyCode.Minus and not d then	
		d = true
		spawn(function()
			wait(10)
			d = false
		end)
		script.ToggleHandsignTraining:FireServer()
	end	

	if key == keyBinds["Crouch"] then

		if crouched == false then

			if sprinting then
				slide()
				return
			end

			crouched = true

			crouchAnim:Play()
			crouchAnim:AdjustSpeed(0)

			crouchJumpBoost.Parent = effects
			crouchSpeedBoost.Parent = effects

			Sprint(false)
			script.Crouch:FireServer(true)

			local c
			c = game["Run Service"].RenderStepped:connect(function()

				if w or a or s or d then
					crouchAnim:AdjustSpeed(1)
				else
					crouchAnim:AdjustSpeed(0)
				end

			end)

			repeat wait() until not crouched

			c:Disconnect()

		else

			crouched = false
			crouchAnim:Stop()

			crouchJumpBoost.Parent = nil
			crouchSpeedBoost.Parent = nil

			script.Crouch:FireServer(false)

		end

	end

	effects.ChildAdded:Connect(function(addedObj)
		if addedObj.Name == "TrackPuppet" or addedObj.Name == "NoSprint" then
			Sprint(false)
		end
	end)

	if key == keyBinds["W"] then
		w = true

		if tick() - sprintTick < 0.5 then
			Sprint(true)
			local charTool = character:FindFirstChildOfClass("Tool")
			if charTool then
				newToolSprint(charTool)
			end
			if crouched == true then
				crouched = false
				crouchAnim:Stop()

				crouchJumpBoost.Parent = nil
				crouchSpeedBoost.Parent = nil

				script.Crouch:FireServer(false)
			end
		end
		sprintTick = tick()

	end

	if key == keyBinds["A"] then
		a = true
	end

	if key == keyBinds["S"] then
		s = true
		Sprint(false)
	end

	if key == keyBinds["D"] then
		d = true
	end

	if key == keyBinds["Dash"] then

		if not w and not a and not s and not d then return end
		if dashCD then return end
		if not shared.CanAttack(character,{"Hydrification","Carryingg"}) 
			and not effects:FindFirstChild("CanMove") then return end
		if effects:FindFirstChild("HellSwamp") then return end
		if not canDash then return end
		if not canDash2 then return end
		if effects:FindFirstChild("SteelProc") then return end
		--if humanoid.FloorMaterial == Enum.Material.Air and effects:FindFirstChild("SteelProc") then return end --DASH IN AIR?
		if effects:FindFirstChild("Monster") then return end
		if effects:FindFirstChild("JinBerserk") then return end
		if effects:FindFirstChild("Carrying") then return end
		if Root:FindFirstChildOfClass("BodyVelocity") then return end
		dashCD = true

		if effects:FindFirstChild("Afterimage") 
			or effects:FindFirstChild("Flicker") 
			or effects:FindFirstChild("LC") 
			or effects:FindFirstChild("Gates") 
			or effects:FindFirstChild("CurseMark2") 
			or effects:FindFirstChild("Tailwind")  then

			local cd = 0.5

			local step = 0
			if effects:FindFirstChild("CurseMark2") then
				step = 6
				cd = 1.25
			elseif effects:FindFirstChild("LC") then
				local LC = effects:FindFirstChild("LC").Value
				if LC == 1 then
					step = 5
					cd = 1.7 -- 1.25
				end
				if LC == 2 then
					step = 7 --6 (pre lc update )
					cd = 1 -- 1.25
				end
				if LC == 3 then
					step = 7
					cd = 0.8 -- 0.3
				end
				if LC == 4 then
					step = 12
					cd = 0.8 -- 0.1
				end
			elseif effects:FindFirstChild("Flicker") then
				step = 15
				cd = 1 -- 0.35
			elseif effects:FindFirstChild("Tailwind") then
				step = 15
				cd = 1
			elseif effects:findFirstChild("Afterimage") then
				step = 10
				cd = 0.9
			elseif effects:FindFirstChild("Gates") then
				local gate = effects:FindFirstChild("Gates").Value
				if gate == 1 then
					step = 3
					cd = 1.2 -- 0.8
				end
				if gate == 2 then
					step = 4
					cd = 1 -- 0.7
				end
				if gate == 3 then
					step = 5
					cd = 0.8 -- 0.6
				end
				if gate == 4 then
					step = 6
					cd = 0.8 -- 0.6
				end
				if gate == 5 then
					step = 7
					cd = 0.6 -- 0.5
				end
				if gate == 6 then
					step = 7
					cd = 0.4 -- 0.4
				end
				if gate == 7 then
					step = 7
					cd = 0.3 -- 0.3
				end
				if gate == 8 then
					step = 7
					cd = 0.1 -- 0.1
				end
			end

			local dashed = false
			if effects.Chakra.Value < 4 then dashCD = false return end
			if w and not dashed  and not effects:FindFirstChild("InvisiblePrison")   then
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.lookVector * step)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if not hit then
					dashed = true
					if humanoid.FloorMaterial ~= Enum.Material.Air then
						script.Dash:FireServer(true,character.HumanoidRootPart.CFrame,character.HumanoidRootPart.CFrame * CFrame.new(0,0,-step - 4))
						character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0,0,-step)
					else
						script.Dash:FireServer(true,character.HumanoidRootPart.CFrame,character.HumanoidRootPart.CFrame * CFrame.new(0,8,-8))
						character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0,5,-5)
					end
				end	
			end
			if a and not dashed and not effects:FindFirstChild("InvisiblePrison")   then
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.rightVector * -step)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if not hit then
					dashed = true
					script.Dash:FireServer(true,character.HumanoidRootPart.CFrame,character.HumanoidRootPart.CFrame * CFrame.new(-step - 4,0,0))
					character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(-step,0,0)
				end
			end
			if s and not dashed and not effects:FindFirstChild("InvisiblePrison")  then
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.lookVector * -step)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if not hit then
					dashed = true
					script.Dash:FireServer(true,character.HumanoidRootPart.CFrame,character.HumanoidRootPart.CFrame * CFrame.new(0,0,step + 4))
					character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0,0,step)
				end
			end
			if d and not dashed and not effects:FindFirstChild("InvisiblePrison")  then
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.rightVector * step)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if not hit then
					dashed = true
					script.Dash:FireServer(true,character.HumanoidRootPart.CFrame,character.HumanoidRootPart.CFrame * CFrame.new(step + 4,0,0))
					character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(step,0,0)
				end
			end
			wait(cd)
			dashCD = false
			return
		end

		canDash = false
		canDouble = false

		spawn(function()
			repeat wait() until inAir == false
			--print("yes")
			canDash = true
			canDouble = true
		end)

		local dashing = true

		local cf
		local check

		local bvel = Instance.new("BodyVelocity",character.HumanoidRootPart)
		bvel.Name = "DashVelocity"

		if inAir then
			bvel.MaxForce = Vector3.new(100000,100000,100000)
		else
			bvel.MaxForce = Vector3.new(100000,0,100000)	
		end

		local truew = false
		local truea = false
		local trues = false
		local trued = false

		local wannaAir = false
		if humanoid.FloorMaterial == Enum.Material.Air then
			wannaAir = true
		end
		local e
		spawn(function()
			wait(0.4)
			dashing = false
			bvel:Destroy()
			check:Disconnect()
			e:Disconnect()
			wait(1)
			dashCD = false
		end)

		e = Root.ChildAdded:connect(function(c)
			if c:IsA("BodyVelocity") then
				bvel:Destroy()
				dashing = false
				check:Disconnect()
				wait(1)
				dashCD = false
			end
		end)

		script.Dash:FireServer(wannaAir)

		local anim
		if w then
			anim = animator:LoadAnimation(animfolder.DashW)
			truew = true
		elseif a then
			anim = animator:LoadAnimation(animfolder.DashA)
			truea = true
		elseif s then
			anim = animator:LoadAnimation(animfolder.DashS)
			trues = true
		elseif d then
			anim = animator:LoadAnimation(animfolder.DashD)
			trued = true
		end

		anim:Play()

		local chakra = false

		if effects:FindFirstChild("Sub") then
			chakra = true
		end

		local stepp
		if not chakra then
			stepp = 40
		else
			stepp = 55
		end

		check = game["Run Service"].RenderStepped:connect(function()

			if effects:FindFirstChild("Stunned") or effects:FindFirstChild("NoDash") or dashing == false then
				anim:Stop()
				check:Disconnect()
				bvel:Destroy()
				dashing = false
				--print("de_stroyed")
			end

			local aim = false
			if truew then
				if not wannaAir then
					cf = character.HumanoidRootPart.CFrame * CFrame.new(0,0,-5)
					local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.lookVector * 3)
					local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
					local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
					if hit then
						--print("why u dash into wall")
						bvel.MaxForce = Vector3.new(10000,0,10000)
					end
				else
					aim = true
					if truew then
						cf = CFrame.new(character.HumanoidRootPart.CFrame.p + -workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1,1,1))
					end
				end
			elseif trues then
				cf = character.HumanoidRootPart.CFrame * CFrame.new(0,0,5)
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.lookVector * -3)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if hit then
					--print("why u dash into wall")
					bvel.MaxForce = Vector3.new(10000,0,10000)
				end
			elseif truea then
				cf = character.HumanoidRootPart.CFrame * CFrame.new(-5,0,0)
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.rightVector * -3)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if hit then
					--print("why u dash into wall")
					bvel.MaxForce = Vector3.new(10000,0,10000)
				end
			elseif trued then
				cf = character.HumanoidRootPart.CFrame * CFrame.new(5,0,0)
				local ray = Ray.new(character.HumanoidRootPart.CFrame.p, character.HumanoidRootPart.CFrame.rightVector * 3)
				local ignore = {game.Workspace.Alive,game.Workspace.Projectiles}
				local hit = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				if hit then
					--print("why u dash into wall")
					bvel.MaxForce = Vector3.new(10000,0,10000)
				end
			end

			--stepp = stepp - 0.2
			--print(stepp)

			if not chakra then
				if not aim then
					bvel.Velocity = CFrame.new(character.HumanoidRootPart.Position, cf.Position).lookVector * stepp
				else
					bvel.Velocity = CFrame.new(character.HumanoidRootPart.Position, cf.Position).lookVector * -stepp	
				end
			else
				if not aim then
					bvel.Velocity = CFrame.new(character.HumanoidRootPart.Position, cf.Position).lookVector * stepp
				else
					bvel.Velocity = CFrame.new(character.HumanoidRootPart.Position, cf.Position).lookVector * -stepp
				end
			end

		end)

	end

end)

UserInputService.InputEnded:connect(function(input)

	local key = input.KeyCode

	if key == keyBinds["W"] then
		w = false
		Sprint(false)
	end

	if key == keyBinds["A"] then
		a = false
	end

	if key == keyBinds["S"] then
		s = false
	end

	if key == keyBinds["D"] then
		d = false
	end

end)

local con

local Gyro = Instance.new("BodyGyro")
Gyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
Gyro.D = 100
Gyro.P = 10000
local Cam = workspace.CurrentCamera
local v129 = tick();
local u38 = nil;
local u39 = 1;
local u40 = 0;
local u41 = nil;
local u42 = false;

con = game:GetService("RunService").RenderStepped:Connect(function()
	local v131 = false
	--	for i,v in pairs(game.Players:GetChildren()) do
	--if v ~= player then
	--		v:Destroy()
	--end
	--	end

	if effects:FindFirstChild("Stunned") or effects:FindFirstChild("Attacking") or effects:FindFirstChild("Block") then
		Sprint(false)
	end

	local speed = 16
	local jump = 50 --* (1 - (humanoid.Health / humanoid.MaxHealth))

	if effects:FindFirstChild("CameraLook")then
		Gyro.Parent = Root
		Gyro.CFrame = Cam.CFrame
	else
		Gyro.Parent = nil
	end

	for i,v in pairs(effects:GetChildren()) do
		if v.Name == "Speed" then
			speed = speed + v.Value
		end
		if v.Name == "IceSlow" then
			speed = speed - 6
		end
		if v.Name == "Jump" then
			jump = jump + v.Value
		end
	end

	if sprinting then
		speed = speed + (11 + (5 * (humanoid.Health / humanoid.MaxHealth)))
	end

	if jumpCD then
		jump = 0
	end

	if effects:FindFirstChild("Ragdolled") then
		speed = 0
		jump = 0
	end

	if Root:FindFirstChild("ForwardVel") then
		Root.ForwardVel.Velocity = Root.CFrame.lookVector * Root.ForwardVel.Velocity.magnitude
	end

	for i,v in pairs(effects:GetChildren()) do
		if v.Name == "SpeedSet" then
			speed = v.Value
			--print("SPeedset"..v.Value)
		end
		if v.Name == "JumpSet" then
			jump = v.Value
		end
	end

	for i,v in pairs(effects:GetChildren()) do
		if v.Name == "Speed" and v.Value <= -100 then
			speed = 0
		end
		if v.Name == "SpeedSet" and v.Value <= 0 then
			speed = 0		
		end
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.PlatformStanding or state == Enum.HumanoidStateType.Physics then
		if not effects:FindFirstChild("Executable") and not effects:FindFirstChild("Ragdolled") then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	if sprinting and  (not game.ReplicatedStorage.roamcooldowns:FindFirstChild(tostring(player.UserId)) and not effects:FindFirstChild("Carrying") and not effects:FindFirstChild("Stunned") and not effects:FindFirstChild("NoRoam") and not effects:FindFirstChild("Attacking") and not effects:FindFirstChild("Block") and not effects:FindFirstChild("Combat") and not effects:FindFirstChild("Casting")) then
		v131 = true
		if u38 == nil then
			u38 = tick()
		end
		if tick() - u38 >= 5 and humanoid.FloorMaterial ~= Enum.Material.Air then
			local v150 = (16 + (11 + 5 * (humanoid.Health / humanoid.MaxHealth))) * u39;
		end

	end
	if v131 and tick() - u38 >= 5 then
		u39 = math.min(1.75, u39 + 0.0004)
	else
		u39 = math.max(1, u39 - 0.0003);
	end
	if not v131 and u38 ~= nil then
		u38 = nil;
	end
	if tick() - u40 >= 0.5 and not game.ReplicatedStorage.roamcooldowns:FindFirstChild(tostring(player.UserId)) and (not (not effects:FindFirstChild("Carrying")) or not (not effects:FindFirstChild("Combat")) or effects:FindFirstChild("Casting")) then
		u40 = tick();
	end;
	if character:WaitForChild("HumanoidRootPart"):FindFirstChild("ForwardVel") then
		character:WaitForChild("HumanoidRootPart").ForwardVel.Velocity = character:WaitForChild("HumanoidRootPart").CFrame.lookVector * character:WaitForChild("HumanoidRootPart").ForwardVel.Velocity.magnitude;
	end;
	if v131 and u38 and tick() - u38 >= 5 and humanoid.FloorMaterial ~= Enum.Material.Air and game.ReplicatedStorage:FindFirstChild("roampart") then
		if not u41 or u41.Parent == nil then
			u41 = game.ReplicatedStorage.roampart:Clone();
			u41.Parent = character;
		end;
	elseif u41 and u41.Parent ~= nil then
		u41:Destroy();
		if u42 == true then
			u42 = false;
			print("sp[rintgin?1")
			sprintSpeedBoost.Value = 9 + effects:WaitForChild("Rank").Value / 10;
		end;
	end;
	if u41 and u41.Parent ~= nil then
		if u42 == false then
			u42 = true;
			print("sp[rintgin?")
			sprintSpeedBoost.Value = sprintSpeedBoost.Value + 15;
		end;
		u41.CFrame = CFrame.new(character.Torso.Position, character.Torso.Position + character.HumanoidRootPart.CFrame.lookVector)
		if u39 == 1.75 and not u41.loop.IsPlaying then
			print("yessir")
			u41.loop:Play();
		elseif u39 < 1.75 and u41.loop.IsPlaying then
			print("ahahahah")
			u41.loop:Stop();
		end
	end
	humanoid.WalkSpeed = speed
	humanoid.JumpPower = jump

end)

game.ReplicatedStorage.UpdateVelocity.OnClientEvent:Connect(function(velocity, direction, speed)
	while velocity:IsDescendantOf(character) do
		if direction == "forward" then
			velocity.Velocity = character.HumanoidRootPart.CFrame.LookVector * speed
		end
		task.wait()
	end
end)

game.ReplicatedStorage.Remotes.RemoveDashVelocities.OnClientEvent:Connect(function()
	for i,v in pairs(character.HumanoidRootPart:GetChildren()) do
		if (v.Name == "DashVelocity" or v.Name == "Dem") then
			v:Destroy()
		end
	end
end)

game.ReplicatedStorage.Remotes.Misogi.OnClientEvent:Connect(function()
	game.Lighting.Misogi.Enabled = true
	wait(0.5)
	game.Lighting.Misogi.Enabled = false
end)


local ContextActionService = game:GetService("ContextActionService")
local FREEZE_ACTION = "freezeMovement"

effects.ChildAdded:Connect(function(child)
	wait()
	if child.Name == "JinBerserk" then
		wait(120)

		if effects:FindFirstChild("JinBerserk") then
			script.JinWhisper:Play()
		end
		wait(150)
		script.Heartbeats.PlaybackSpeed = 1

		if effects:FindFirstChild("JinBerserk") then
			script.Heartbeats:Play()
			game:GetService("TweenService"):Create(script.Heartbeats, TweenInfo.new(70), {PlaybackSpeed=3}):Play()
		end		
	end

	if child.Name == "FreezeInput" then
		ContextActionService:BindAction(
			FREEZE_ACTION,
			function() return Enum.ContextActionResult.Sink end,
			false,
			unpack(Enum.PlayerActions:GetEnumItems())
		)
	end
end)

effects.ChildRemoved:Connect(function(child)
	if not effects:FindFirstChild("FreezeInput") then
		ContextActionService:UnbindAction(FREEZE_ACTION)
	end

	if child.Name == "JinBerserk" then
		script.JinWhisper:Stop()
	end
end)

humanoid.Died:Connect(function()
	if character:FindFirstChild("Head") then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Track
		workspace.CurrentCamera.CameraSubject = character.Head
	end
end)

local ziplinePart
for i,v in pairs(workspace.Ziplines:GetChildren()) do
	if v:IsA("BasePart") then
		v.Touched:Connect(function(hit)		
			if v.Name == "Part" then
				ziplinePart = v 
			end
			if hit.Parent == character and not ziplining then
				if v.Name == "Start" then
					zipline(ziplinePart, true) 
					print("1")
				else

				end

			end
		end)
	end
end

--[[
game.ReplicatedStorage.Remotes.FixFace.OnClientEvent:Connect(function(decals,parent)
	print("YAY")
	wait(3)
	for i=1,10 do
		print("OK")
		for i,v in pairs(decals) do
			if v then
				v.Parent = nil
			end
		end
		wait()
		for i,v in pairs(decals) do
			if v then
				v.Parent = parent
			end
		end
		wait(1)
	end
	
end)]]
