print("Hello world, from client!")

local RPS = game:GetService("ReplicatedStorage")
local PLR = game:GetService("Players")

local LocalPlayer = PLR.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Mouse = LocalPlayer:GetMouse()

-- Requirements
local _networker = require(RPS.Shared.Networker)
local cameraController = require(PlayerScripts.Client.PlayerUtils.CameraController)
local trackCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.TrackingCamera)
local movementController = require(PlayerScripts.Client.PlayerUtils.MovementController)

-- Game Execution
task.wait(10)
cameraController:Init()

-- Initiallize Camera
local camFolder = workspace:FindFirstChild("CameraFolder")
local testCamera = camFolder and camFolder:WaitForChild("TestCamera")

task.wait(5)
print("Testing camera : ", testCamera)
if testCamera then
	local cam = trackCamera.new(testCamera)
	cameraController:SwitchCamera(cam)
	
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local move = movementController.new(character, "Free", workspace.Nodes)
	
	Mouse.Button1Up:Connect(function()
		move:MoveToWorldPosition(Mouse.Hit.Position)
	end)
end
