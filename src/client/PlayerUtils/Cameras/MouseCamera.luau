-- Services
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

-- Variables
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

-- Requirements
local BaseCamera = require(StarterPlayer.StarterPlayerScripts.Client.PlayerUtils.Cameras.BaseCamera)

--- @class MouseCamera : BaseCamera
--- Dynamic camera orientation guided by mouse movement relative to screen center while locked to a part's position.
local MouseCamera = setmetatable({}, {__index = BaseCamera})
MouseCamera.__index = MouseCamera

--- Creates a new MouseCamera module
--- @param cameraPart BasePart -- The origin part for the camera
--- @param smoothSpeed number? -- Speed of camera interpolation (Default: 5)
--- @param maxAngleDegrees number? -- Max pitch/yaw rotation angle in degrees from center (Default: 15)
function MouseCamera.new(cameraPart: BasePart, smoothSpeed: number?, maxAngleDegrees: number?)
    local self = setmetatable(BaseCamera.new() :: any, MouseCamera)
    self.CameraPart = cameraPart
    self.SmoothSpeed = smoothSpeed or 5
    self.MaxAngle = math.rad(maxAngleDegrees or 15) -- Convert max angle to radians
    return self
end

function MouseCamera:CalculateCFrame(dt: number): CFrame?
    if not self.CameraPart then return nil end

    local camera = workspace.CurrentCamera
    if not camera then return self.CameraPart.CFrame end

    local viewportSize = camera.ViewportSize
    if viewportSize.X == 0 or viewportSize.Y == 0 then return self.CameraPart.CFrame end

    local normalizedX = (mouse.X / viewportSize.X) - 0.5
    local normalizedY = (mouse.Y / viewportSize.Y) - 0.5

    local targetYaw = -normalizedX * (self.MaxAngle * 2)
    local targetPitch = -normalizedY * (self.MaxAngle * 2)

    targetYaw = math.clamp(targetYaw, -self.MaxAngle, self.MaxAngle)
    targetPitch = math.clamp(targetPitch, -self.MaxAngle, self.MaxAngle)

    local targetCFrame = CFrame.new(self.CameraPart.Position) 
        * (self.CameraPart.CFrame - self.CameraPart.Position) 
        * CFrame.Angles(targetPitch, targetYaw, 0)

    return camera.CFrame:Lerp(targetCFrame, math.clamp(dt * self.SmoothSpeed, 0, 1))
end

return MouseCamera
