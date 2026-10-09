-- src/client/Controllers/CameraController.lua
local RunService = game:GetService("RunService")

local CameraController = {}
CameraController.isActive = true
CameraController.ActiveCamera = nil
CameraController.TransitionSpeed = 5 -- Lower = smoother, Higher = faster

function CameraController:Init()
	-- RenderStepped / PreRender is required for custom local camera positioning
	RunService.RenderStepped:Connect(function(dt)
		if self.isActive and self.ActiveCamera and self.ActiveCamera.Update then
			self.ActiveCamera:Update(dt)
		end
	end)
end

function CameraController:Active(bool)
	self.isActive = bool
end

function CameraController:SwitchCamera(newCamera)
	if self.ActiveCamera == newCamera then return end

	if self.ActiveCamera and self.ActiveCamera.Disable then
		self.ActiveCamera:Disable()
	end

	self.ActiveCamera = newCamera

	if self.ActiveCamera and self.ActiveCamera.Enable then
		self.ActiveCamera:Enable()
	end
end

return CameraController
