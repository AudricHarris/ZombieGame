local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local BaseCamera = require(StarterPlayer.StarterPlayerScripts.Client.PlayerUtils.Cameras.BaseCamera)

local LocalPlayer = Players.LocalPlayer

export type TopDownCamera = typeof(BaseCamera.new()) & {
	Offset: Vector3,
	LerpSpeed: number,
}

--- @class TopDownCamera
--- A camera subclass that smoothly follows the local player's character based on a Vector3 offset.
local TopDownCamera = setmetatable({}, {__index = BaseCamera})
TopDownCamera.__index = TopDownCamera

--- Creates a new instance of TopDownCamera
--- @param offset Vector3? -- The positional offset relative to the target (Default: Vector3.new(0, 30, 15))
function TopDownCamera.new(offset: Vector3?): TopDownCamera
	local self = setmetatable(BaseCamera.new() :: any, TopDownCamera)
	
	self.Offset = offset or Vector3.new(0, 30, 15)
	self.LerpSpeed = 10 -- Controls camera smoothing speed
	
	return self
end

--- Override of BaseCamera's CalculateCFrame to position the camera relative to the player
--- @param dt number -- Delta time passed from the render step
function TopDownCamera:CalculateCFrame(dt: number): CFrame?
	local character = LocalPlayer.Character
	if not character then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then return nil end

	local targetPosition = rootPart.Position
	local cameraPosition = targetPosition + self.Offset

	-- Look directly at the target character from the offset position
	local targetCFrame = CFrame.lookAt(cameraPosition, targetPosition)

	-- Smooth transition if previous frame CFrame exists
	if self.CurrentCamera and self.CurrentCamera.CFrame then
		local alpha = math.clamp(dt * self.LerpSpeed, 0, 1)
		return self.CurrentCamera.CFrame:Lerp(targetCFrame, alpha)
	end

	return targetCFrame
end

return TopDownCamera
