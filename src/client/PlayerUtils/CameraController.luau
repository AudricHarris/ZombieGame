-- src/client/Controllers/CameraController.lua
local RunService = game:GetService("RunService")

local CameraController = {}
CameraController.ActiveCamera = nil

function CameraController:Init()
    -- RenderStepped ensures smooth camera updates right before rendering each frame
    RunService.RenderStepped:Connect(function(dt)
        if self.ActiveCamera then
            self.ActiveCamera:Update(dt)
        end
    end)
end

--- Ensures ONLY ONE camera is active per player at a time
function CameraController:SwitchCamera(newCamera)
    print("Hi here", newCamera)
    if self.ActiveCamera == newCamera then return end

    -- 1. Disable the currently active camera (if any exists)
    if self.ActiveCamera then
        self.ActiveCamera:Disable()
    end

    -- 2. Switch to the new camera instance
    self.ActiveCamera = newCamera

    print(self.ActiveCamera)
    -- 3. Enable the new camera instance
    if self.ActiveCamera then
        self.ActiveCamera:Enable()
    end
end

return CameraController
