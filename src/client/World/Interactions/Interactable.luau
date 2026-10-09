local Interactable = {}
Interactable.__index = Interactable

function Interactable.new(instance: Instance)
	local self = setmetatable({}, Interactable)
	self.Instance = instance
	self.Type = instance:GetAttribute("Type") or "Misc"
	self.InteractDistance = instance:GetAttribute("InteractDistance") or 10
	self.IsBusy = false
	return self
end

function Interactable:CanInteract(character: Model): boolean
	if self.IsBusy then return false end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local pos = self.Instance:IsA("Model") and self.Instance:GetPivot().Position or (self.Instance :: BasePart).Position
	return (hrp.Position - pos).Magnitude <= self.InteractDistance
end

function Interactable:Interact(player: Player)
	warn("Base Interact called on: " .. self.Instance.Name)
end

return Interactable
