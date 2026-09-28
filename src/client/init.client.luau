print("Hello world, from client!")
local RPS = game:GetService("ReplicatedStorage")
local PLR = game:GetService("Players")
local RS = game:GetService("RunService")

local LocalPlayer = PLR.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Mouse = LocalPlayer:GetMouse()

-- Requirements
local cameraController = require(PlayerScripts.Client.PlayerUtils.CameraController)
local movementController = require(PlayerScripts.Client.PlayerUtils.MovementController)
local plrCamChooser = require(PlayerScripts.Client.PlayerUtils.PlayerCameraChooser)

-- Game Execution
cameraController:Init()

local camFolder = workspace:WaitForChild("CameraFolder")
task.wait(4)
plrCamChooser.Init(camFolder)

local currentActiveCam = nil
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local move = movementController.new(character, "Free", workspace:WaitForChild("Nodes"))

LocalPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	move = movementController.new(character, "Free", workspace:WaitForChild("Nodes"))
end)

-- Handle movement clicks
Mouse.Button1Up:Connect(function()
	if move and Mouse.Hit then
		move:MoveToWorldPosition(Mouse.Hit.Position)
	end
end)

-- Continuously evaluate best camera on every render step
RS.RenderStepped:Connect(function(dt)
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local bestCam = plrCamChooser.getBestCamera(character)

	if bestCam and bestCam ~= currentActiveCam then
		currentActiveCam = bestCam
		cameraController:SwitchCamera(bestCam)
	end
end)
