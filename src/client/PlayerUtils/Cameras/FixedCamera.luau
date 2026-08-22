local StarterPlayer = game:GetService("StarterPlayer")
local BaseCamera = require(StarterPlayer.StarterPlayerScripts.Client.PlayerUtils.Cameras.BaseCamera)

export type FixedCamera = typeof(BaseCamera.new()) & {
    CameraPart: BasePart,
}
--- @class Fixed Camera
--- This is a sub class of base camera which allows to position a camera on the cframe of a part (One of the most common cameras)
local FixedCamera = setmetatable({}, {__index = BaseCamera})
FixedCamera.__index = FixedCamera


--- Creation function of the subclass Fixed Camera
--- @param cameraPart : This is the part where the camera part locks on to
function FixedCamera.new(cameraPart: BasePart)
    local self = setmetatable(BaseCamera.new() :: any , FixedCamera)
    self.CameraPart = cameraPart
    return self
end

-- Method overwritten that will return the cameraPart cframe if it exist
-- @param dt : Not used in this system
function FixedCamera:CalculateCFrame(dt: number): CFrame?
    if not self.CameraPart then return nil end
    return self.CameraPart.CFrame
end

return FixedCamera
