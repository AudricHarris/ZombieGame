local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local BaseCamera = require(StarterPlayer.StarterPlayerScripts.Client.PlayerUtils.Cameras.BaseCamera)
local LocalPlayer = Players.LocalPlayer

export type FirstPersonCamera = typeof(BaseCamera.new())

local FirstPersonCamera = setmetatable({}, {__index = BaseCamera})
FirstPersonCamera.__index = FirstPersonCamera

function FirstPersonCamera.new()
    local self = setmetatable(BaseCamera.new() :: any, FirstPersonCamera)
    return self
end

--- Recursively hides accessories and head parts locally
function FirstPersonCamera:SetCharacterHeadVisibility(visible: boolean)
    local character = LocalPlayer.Character
    if not character then return end

    local transparency = visible and 0 or 1

    -- 1. Hide the Head itself
    local head = character:FindFirstChild("Head")
    if head then
        head.LocalTransparencyModifier = transparency
    end

    -- 2. Hide all accessories attached to the Head/Face
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                -- Check if accessory is attached to head/face attachment points
                local attachment = handle:FindFirstChildOfClass("Attachment")
                if attachment and (
                    string.find(attachment.Name, "Hat") or 
                    string.find(attachment.Name, "Hair") or 
                    string.find(attachment.Name, "Face") or 
                    string.find(attachment.Name, "Head")
                ) then
                    handle.LocalTransparencyModifier = transparency
                end
            end
        end
    end
end

function FirstPersonCamera:Enable()
    BaseCamera.Enable(self)
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    -- Hide head and head accessories when entering first person
    self:SetCharacterHeadVisibility(false)
end

function FirstPersonCamera:Disable()
    BaseCamera.Disable(self)
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    -- Restore head and accessories when exiting first person
    self:SetCharacterHeadVisibility(true)
end

function FirstPersonCamera:CalculateCFrame(dt: number): CFrame?
    local character = LocalPlayer.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Re-apply LocalTransparencyModifier every frame in case animations/Roblox engine resets it
    head.LocalTransparencyModifier = 1
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                handle.LocalTransparencyModifier = 1
            end
        end
    end

    return head.CFrame
end

return FirstPersonCamera
