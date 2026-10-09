local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local UI = require(LocalPlayer.PlayerScripts.Client.UI)
local Networker = require(ReplicatedStorage.Shared.Networker)
local CameraController = require(LocalPlayer.PlayerScripts.Client.PlayerUtils.Cameras)
local PlayerCameraChooser = require(LocalPlayer.PlayerScripts.Client.PlayerUtils.Controllers.CameraChooserController)
local Interactable = require(script.Parent.Interactable)

local transition = workspace.Transitions.Elevator

local Elevator = setmetatable({}, { __index = Interactable })
Elevator.__index = Elevator

function Elevator.new(instance: Instance)
	local self = setmetatable(Interactable.new(instance), Elevator)
	return self
end

function Elevator:CheckIfLocked()
	local isLocked = Networker.InvokeServer("CheckDoor", self.Instance)
	print(isLocked)
	return isLocked
end

function Elevator:Interact(player: Player)
	Networker.FireServer("ElevatorVoteRequest", self.Instance)
end

function Elevator:Enter(player: Player)
	if self.IsBusy then return end
	self.IsBusy = true

	local character = player.Character
	if not character then 
		self.IsBusy = false 
		return 
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera

	-- if elevator is locked
	if self:CheckIfLocked() then
		self.Instance.Locked:Play()
		self.IsBusy = false
		return
	end

	-- Disable Movement
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Disable Camera Controller & Snap to Transition Camera
	CameraController:Active(false)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = transition.TransitionCamera.CFrame

	local elevator = transition.Elevator
	local door1 = elevator.Doors.Door1
	local door2 = elevator.Doors.Door2

	if elevator:FindFirstChild("DoorOpen") then
		elevator.DoorOpen:Play()
		print(elevator.DoorOpen.IsPlaying)
	end

	-- Tween door opening (+90 degrees around Y axis)
	local door1TweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local door1TargetCFrame = CFrame.new(16.362, 4.257, 48.174) * CFrame.Angles(0, math.rad(90), 0)
	local door1Tween = TweenService:Create(door1, door1TweenInfo, { CFrame = door1TargetCFrame })

	local door2TweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local door2TargetCFrame = CFrame.new(22.889, 4.257, 48.208) * CFrame.Angles(0, math.rad(-90), 0)
	local door2Tween = TweenService:Create(door2, door2TweenInfo, { CFrame = door2TargetCFrame })

	door1Tween:Play()
	door2Tween:Play()

	task.wait(2)

	-- Move camera forward through the doorway for 1 second
	local cameraForwardCFrame = camera.CFrame * CFrame.new(0, 0, -8) -- Moves 8 studs forward
	local camTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local cameraTween = TweenService:Create(camera, camTweenInfo, { CFrame = cameraForwardCFrame })
	cameraTween:Play()

	task.wait(1)
	local fadeFrame = UI.Get("Fade")
	if not fadeFrame then return end
	
	local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local prop = fadeFrame:IsA("CanvasGroup") and "GroupTransparency" or "BackgroundTransparency"

	-- Tween to full black
	local fadeToBlack = TweenService:Create(fadeFrame, fadeInfo, { [prop] = 0 })
	fadeToBlack:Play()
	fadeToBlack.Completed:Wait()

	local rawDestination: InstanceHandle = self.Instance:GetAttribute("TargetDestination")
	local targetDestination: Instance? = rawDestination and rawDestination:Get()

	if targetDestination then
		if targetDestination:IsA("BasePart") then
			character:PivotTo(targetDestination.CFrame)
		elseif targetDestination:IsA("Model") then
			character:PivotTo(targetDestination:GetPivot())
		end
	end

	door1.CFrame = CFrame.new(18.492, 4.257, 48.174) * CFrame.Angles(0, math.rad(90), 0)
	door2.CFrame = CFrame.new(20.689, 4.257, 48.208) * CFrame.Angles(0, math.rad(-90), 0)

	CameraController:Active(true)
	local newBestCam = PlayerCameraChooser.getBestCamera(character)
	if newBestCam then
		CameraController:SwitchCamera(newBestCam)
	end
	task.wait(1)

	task.wait()

	-- Fade screen back to normal transparent
	local fadeToClear = TweenService:Create(fadeFrame, fadeInfo, { [prop] = 1 })
	fadeToClear:Play()

	-- Restore Movement
	if humanoid then
		humanoid.WalkSpeed = 8
		humanoid.JumpPower = 50
	end

	self.IsBusy = false
end

return Elevator
