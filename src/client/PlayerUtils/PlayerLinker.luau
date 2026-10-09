local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local TopDownCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.TopDownCamera)
local Cameras = require(script.Parent.Cameras)
local CameraChooserController = require(PlayerScripts.Client.PlayerUtils.Controllers.CameraChooserController)
local MouseController = require(PlayerScripts.Client.PlayerUtils.Controllers.MouseController)
local World = require(PlayerScripts.Client.World)
local Movement = require(script.Parent.Movement)


local PlayerLinker = {}
PlayerLinker.Movement = nil
PlayerLinker.Highlight = nil


local function awaitGameLoaded()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	while not playerGui do
		playerGui = LocalPlayer:WaitForChild("PlayerGui")
		if playerGui:IsA("PlayerGui") then break end
	end

	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart")

	return true
end


function PlayerLinker.Setup()
	awaitGameLoaded()

	local high = Instance.new("Highlight")
	high.Name = "InteractableHoverHighlight"
	high.FillTransparency = 1
	high.OutlineColor = Color3.fromRGB(255,255,150)
	high.OutlineTransparency = 0.75
	high.Adornee = nil
	high.Parent = LocalPlayer:WaitForChild("PlayerGui")

	PlayerLinker.Highlight = high
	
	Cameras:Init()
	Cameras:SwitchCamera(TopDownCamera.new(Vector3.new(-10,30,7)))
	CameraChooserController.Init(nil)
	CameraChooserController.pause()

	PlayerLinker.OnSpawn()
end

function PlayerLinker.OnSpawn()
	local LocalPlayer = Players.LocalPlayer
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if char then
		PlayerLinker.Movement = Movement.new(char, "WASD", workspace:WaitForChild("Nodes"))
	end

	local world = World.SetUp()
	MouseController.Setup(PlayerLinker.Movement, world)
end

RunService.RenderStepped:Connect(function(dt)
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if char and char:FindFirstChild("HumanoidRootPart") then
		local bestCam = CameraChooserController.getBestCamera(char)

		if bestCam and bestCam ~= CameraChooserController.ActiveCam then
			CameraChooserController.ActiveCam = bestCam
			Cameras:SwitchCamera(bestCam)
		end
	end

	local hitPart = MouseController.getMouseTargetInstance()
	local taggedInst, _ = World.GetInteractFromInstance(hitPart)
	PlayerLinker.Highlight.Adornee = taggedInst
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
	if PlayerLinker.Movement then
		PlayerLinker.Movement:Destroy()
	end
	PlayerLinker.Movement = Movement.new(newChar, "WASD", nil)
end)

return PlayerLinker
