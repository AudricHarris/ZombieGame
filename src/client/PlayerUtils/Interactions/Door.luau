local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local Networker = require(ReplicatedStorage.Shared.Networker)
local CameraController = require(PlayerScripts.Client.PlayerUtils.CameraController)
local PlayerCameraChooser = require(script.Parent.Parent.PlayerCameraChooser)
local Interactable = require(script.Parent.Interactable)

local transition = workspace.Transition

-- Locate Screen Fade GUI elements
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local fadeGui = playerGui:WaitForChild("ScreenFadeGui")
local fadeFrame = fadeGui:WaitForChild("FadeFrame")

local Door = setmetatable({}, { __index = Interactable })
Door.__index = Door

function Door.new(instance: Instance)
	local self = setmetatable(Interactable.new(instance), Door)
	return self
end

function Door:CheckIfLocked()
	local isLocked = Networker.InvokeServer("CheckDoor", self.Instance)
	print(isLocked)
	return isLocked
end

function Door:Interact(player: Player)
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

	-- if door is locked
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

	local door = transition.Door
	local hinge = door.Hinge

	-- setup door color
	door.Door.Color = self.Instance:GetAttribute("Color") or Color3.fromRGB(90,76,66)
	door.Frame.Color = self.Instance:GetAttribute("Outline") or Color3.fromRGB(86,66,54)

	if hinge:FindFirstChild("DoorOpen") then
		hinge.DoorOpen:Play()
	end

	-- Tween door opening (+90 degrees around Y axis)
	local doorTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local doorTargetCFrame = hinge.CFrame * CFrame.Angles(0, math.rad(90), 0)
	local doorTween = TweenService:Create(hinge, doorTweenInfo, { CFrame = doorTargetCFrame })
	doorTween:Play()

	task.wait(1.5)

	-- Move camera forward through the doorway for 1 second
	local cameraForwardCFrame = camera.CFrame * CFrame.new(0, 0, -8) -- Moves 8 studs forward
	local camTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local cameraTween = TweenService:Create(camera, camTweenInfo, { CFrame = cameraForwardCFrame })
	cameraTween:Play()

	task.wait(1)

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

	hinge.CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(-90), 0)
	door.Door.Color = Color3.fromRGB(90,76,66)
	door.Frame.Color = Color3.fromRGB(86,66,54)

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

return Door
