print("Hello world, from client!")
local RPS = game:GetService("ReplicatedStorage")
local PLR = game:GetService("Players")
local RS = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = PLR.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Mouse = LocalPlayer:GetMouse()

-- Requirements
local cameraController = require(PlayerScripts.Client.PlayerUtils.CameraController)
local movementController = require(PlayerScripts.Client.PlayerUtils.MovementController)
local plrCamChooser = require(PlayerScripts.Client.PlayerUtils.PlayerCameraChooser)

local Interactable = require(PlayerScripts.Client.PlayerUtils.Interactions.Interactable)
local Door = require(PlayerScripts.Client.PlayerUtils.Interactions.Door)
-- Game Execution
cameraController:Init()

local camFolder = workspace:WaitForChild("CameraFolder")
task.wait(2)
if LocalPlayer.Name == "WearWQLF" then
	task.wait(7)
end

plrCamChooser.Init(camFolder)

local currentActiveCam = nil
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local move = movementController.new(character, "Free", workspace:WaitForChild("Nodes"))

LocalPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	move = movementController.new(character, "Free", workspace:WaitForChild("Nodes"))
end)

local interactableObjects = {}

local hoverHighlight = Instance.new("Highlight")
hoverHighlight.Name = "InteractableHoverHighlight"
hoverHighlight.FillColor = Color3.fromRGB(255, 255, 255)
hoverHighlight.FillTransparency = 1
hoverHighlight.OutlineColor = Color3.fromRGB(255, 255, 150)
hoverHighlight.OutlineTransparency = 0
hoverHighlight.Adornee = nil
hoverHighlight.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function registerInteractable(instance: Instance)
	if interactableObjects[instance] then return end

	local interactType = instance:GetAttribute("Type") or "Misc"
	if interactType == "Door" then
		interactableObjects[instance] = Door.new(instance)
	else
		interactableObjects[instance] = Interactable.new(instance)
	end
end

local function unregisterInteractable(instance: Instance)
	interactableObjects[instance] = nil
end

for _, instance in ipairs(CollectionService:GetTagged("Interactable")) do
	registerInteractable(instance)
end

CollectionService:GetInstanceAddedSignal("Interactable"):Connect(registerInteractable)
CollectionService:GetInstanceRemovedSignal("Interactable"):Connect(unregisterInteractable)

local function getInteractableFromInstance(hitInstance: Instance?): (Instance?, any?)
	if not hitInstance then return nil, nil end

	local current: Instance? = hitInstance
	local taggedInstance: Instance? = nil

	while current and current ~= workspace do
		if CollectionService:HasTag(current, "Interactable") then
			taggedInstance = current
		end
		current = current.Parent
	end

	if taggedInstance and interactableObjects[taggedInstance] then
		return taggedInstance, interactableObjects[taggedInstance]
	end

	return nil, nil
end

local function getMouseTargetInstance(): Instance?
	local mouseRay = Mouse.UnitRay
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	if character then
		raycastParams.FilterDescendantsInstances = { character }
	end

	local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	return result and result.Instance or nil
end


-- Handle movement clicks or object interactions
Mouse.Button1Up:Connect(function()
	local hitPart = getMouseTargetInstance()
	local taggedInst, interactObj = getInteractableFromInstance(hitPart)

	if interactObj and character then
		if interactObj:CanInteract(character) then
			interactObj:Interact(LocalPlayer)
			return -- Skip movement if an interaction occurred
		end
	end

	-- Fallback to standard point-and-click movement
	if move and Mouse.Hit then
		move:MoveToWorldPosition(Mouse.Hit.Position)
	end
end)

-- Continuously evaluate best camera & update mouse hover highlight
RS.RenderStepped:Connect(function(dt)
	if character and character:FindFirstChild("HumanoidRootPart") then
		local bestCam = plrCamChooser.getBestCamera(character)

		if bestCam and bestCam ~= currentActiveCam then
			currentActiveCam = bestCam
			cameraController:SwitchCamera(bestCam)
		end
	end

	local hitPart = getMouseTargetInstance()
	local taggedInst, _ = getInteractableFromInstance(hitPart)

	if taggedInst then
		hoverHighlight.Adornee = taggedInst
	else
		hoverHighlight.Adornee = nil
	end
end)
