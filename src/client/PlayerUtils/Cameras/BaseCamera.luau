--!strict
local workspace = game:GetService("Workspace")

--- @class BaseCamera
--- A mother class that handles all the sub cameras system
local BaseCamera = {}
BaseCamera.__index = BaseCamera

-------------
-- Methods --
-------------

--- Creates a Base Camera which holds 2 attributes
--- - Enable  : Determines if we have it active or not
--- - CurrentCamera : Which is the actual camera object
function BaseCamera.new()
    local self = setmetatable({}, BaseCamera)
    self.Enabled = true 
    self.CurrentCamera = workspace.CurrentCamera
    return self
end

-------------
-- Methods --
-------------

-- Enables the Camera and sets CameraType to Scriptable
function BaseCamera:Enable()
    self.Enabled = true
    self.CurrentCamera.CameraType = Enum.CameraType.Scriptable
end

-- Disables the Camera
function BaseCamera:Disable()
    self.Enabled = false
end

--- Abstract method: Subclasses must override this to return their calculated CFrame
function BaseCamera:CalculateCFrame(dt: number): CFrame?
    return nil
end

--- Core execution loop called by CameraManager
function BaseCamera:Update(dt: number)
    if not self.Enabled then return end
    
    local newCFrame = self:CalculateCFrame(dt)
    if newCFrame then
        self.CurrentCamera.CFrame = newCFrame
    end
end

return BaseCamera
