local PlayerCameraChooser = {}

local camTable = {}
local PLR = game:GetService("Players")

local LocalPlayer = PLR.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local trackCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.TrackingCamera)
local mouseCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.MouseCamera)
local fixedCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.FixedCamera)

local PRIORITY_WEIGHT = 2.0   -- tiebreaker between similar cameras
local CENTER_WEIGHT = 10.0    -- how centered the player is in the shot
local DISTANCE_WEIGHT = 2.0   -- prefers cameras near IDEAL_DISTANCE

local MAX_ANGLE = 10          -- degrees off the camera's look direction before the player counts as "out of shot"
local MIN_COS = math.cos(math.rad(MAX_ANGLE))
local IDEAL_DISTANCE = 10
local MIN_DISTANCE = 6        -- closer than this is never chosen (unless nothing else works)

local TRANSPARENT_THRESHOLD = 0.5 -- parts at or above this Transparency don't block the view

local pause = false

local function isViewBlocked(camPos: Vector3, targetPos: Vector3, character: Model): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local ignore: { Instance } = { character }
	local origin = camPos

	for _ = 1, 20 do -- safety cap on how many see-through parts we skip
		params.FilterDescendantsInstances = ignore
		local result = workspace:Raycast(origin, targetPos - origin, params)
		if not result then
			return false -- nothing in the way
		end

		local hit = result.Instance
		local isSeeThrough = hit.Transparency >= TRANSPARENT_THRESHOLD
		local isOtherCharacter = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") ~= nil

		if isSeeThrough or isOtherCharacter then
			table.insert(ignore, hit) -- skip it and keep looking
		else
			return true -- opaque wall
		end
	end

	return true
end

function PlayerCameraChooser.Init(folder: Folder?): boolean
	if not folder then return false end
	table.clear(camTable)

	for _, camInstance in ipairs(folder:GetChildren()) do
		camInstance.Transparency = 1
		local camType: string = camInstance:GetAttribute("CameraType") :: string? or "Fixed"
		local priority: number = camInstance:GetAttribute("Priority") :: number? or 1
		local cameraObject

		print("Camera : ", camType)
		if camType == "Fixed" then
			cameraObject = fixedCamera.new(camInstance)
		elseif camType == "Tracking" then
			cameraObject = trackCamera.new(camInstance, 5)
		elseif camType == "Mouse" then
			cameraObject = mouseCamera.new(camInstance)
		end

		table.insert(camTable, {
			instance = camInstance,
			object = cameraObject,
			type = camType,
			priority = priority,
			zone = camInstance:FindFirstChild("TriggerZone")
		})
	end

	return true
end

function PlayerCameraChooser.pause(bool)
	pause = bool
end

function PlayerCameraChooser.getBestCamera(character: Model): any
	local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if not hrp then return nil end
	if pause then return nil end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { character }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	-- Tier 1: in the shot AND nothing opaque in the way
	local bestCam, bestScore = nil, -math.huge
	-- Tier 2 (last resort): whichever unblocked camera faces the player the most
	local facingCam, facingDot = nil, -math.huge

	for _, camData in ipairs(camTable) do
		local camCFrame = camData.instance:IsA("BasePart") and camData.instance.CFrame or CFrame.new(camData.instance.Position)
		local camPos = camCFrame.Position
		local direction = hrp.Position - camPos
		local distance = direction.Magnitude
		if distance < 0.001 then continue end

		-- Opaque wall in the way: this camera is never an option
		if isViewBlocked(camPos, hrp.Position, character) then continue end

		local dot = camCFrame.LookVector:Dot(direction.Unit)

		if dot > facingDot then
			facingDot = dot
			facingCam = camData.object
		end

		if dot < MIN_COS or distance < MIN_DISTANCE then continue end

		local centerScore = (dot - MIN_COS) / (1 - MIN_COS)
		local distanceScore = 1 - math.clamp(math.abs(distance - IDEAL_DISTANCE) / IDEAL_DISTANCE, 0, 1)

		local score = camData.priority * PRIORITY_WEIGHT
			+ centerScore * CENTER_WEIGHT
			+ distanceScore * DISTANCE_WEIGHT

		if score > bestScore then
			bestScore = score
			bestCam = camData.object
		end
	end

	-- If every camera is blocked, return nil so the caller keeps the current camera
	return bestCam or facingCam
end

return PlayerCameraChooser
