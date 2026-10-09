-- Services
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local MouseController = {}
MouseController.Movement = nil
MouseController.World = nil

function MouseController.Setup(movement, world)
	MouseController.Movement = movement
	MouseController.World = world
end

function MouseController.getMouseTargetInstance(): Instance?
	local mouseRay = Mouse.UnitRay
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	if LocalPlayer.Character then
		raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	end
	
 	local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	return result and result.Instance or nil
end

function MouseController.Clicked()
	local hitPart = MouseController.getMouseTargetInstance()
	local taggedInst, interactObj = MouseController.World.GetInteractFromInstance(hitPart)

	if interactObj and LocalPlayer.Character then
		MouseController.World.Interact(taggedInst, interactObj, LocalPlayer.Character)
	end

	if MouseController.Movement and Mouse.Hit then
		MouseController.Movement:MoveToWorldPosition(Mouse.Hit.Position)
	end
end

Mouse.Button1Up:Connect(MouseController.Clicked)

return MouseController
