-- Services
local Players = game:GetService("Players")

-- Variables
local LocalPlayer = Players.LocalPlayer

-- Requirements
local BaseCamera = require(LocalPlayer.PlayerScripts.Client.PlayerUtils.Cameras.BaseCamera)

--- @class tracking Camera
--- This returns the cframe of the part while looking at the local players character 
local TrackingCamera = setmetatable({}, {__index = BaseCamera})
TrackingCamera.__index = TrackingCamera

--- Method creating a tracking Camera, this tracks the local players
--- @param
function TrackingCamera.new(cameraPart: BasePart, smoothSpeed: number?)
	local self = setmetatable(BaseCamera.new() :: any, TrackingCamera)
	self.CameraPart = cameraPart
	self.SmoothSpeed = smoothSpeed or 5
	return self
end

function TrackingCamera:CalculateCFrame(dt: number): CFrame?
	if not self.CameraPart then return nil end

	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return self.CameraPart.CFrame end

	local targetCFrame = CFrame.lookAt(self.CameraPart.Position, root.Position)
	-- Smoothly interpolate towards player position
	return self.CurrentCamera.CFrame:Lerp(targetCFrame, math.clamp(dt * self.SmoothSpeed, 0, 1))
end

return TrackingCamera
