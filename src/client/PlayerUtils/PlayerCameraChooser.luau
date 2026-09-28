local PlayerCameraChooser = {}

local camTable = {}
local PLR = game:GetService("Players")

local LocalPlayer = PLR.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local trackCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.TrackingCamera)
local mouseCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.MouseCamera)
local fixedCamera = require(PlayerScripts.Client.PlayerUtils.Cameras.FixedCamera)

local DISTANCE_WEIGHT = 1.5
local CENTER_WEIGHT = 2.5
local PRIORITY_WEIGHT = 10.0

function PlayerCameraChooser.Init(folder: Folder?): boolean
	if not folder then return false end
	table.clear(camTable)

	for _, camInstance in ipairs(folder:GetChildren()) do
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

function PlayerCameraChooser.getBestCamera(character: Model): any
	local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if not hrp then return nil end

	local bestCam = nil
	local highestScore = -math.huge

	-- Secondary fallback track in case ALL cameras are blocked by walls
	local fallbackCam = nil
	local fallbackHighestScore = -math.huge

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { character }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	for _, camData in ipairs(camTable) do
		local camCFrame = camData.instance:IsA("BasePart") and camData.instance.CFrame or CFrame.new(camData.instance.Position)
		local camPos = camCFrame.Position
		local targetPos = hrp.Position
		local direction = targetPos - camPos
		local distance = direction.Magnitude

		if distance < 0.001 then continue end

		local cameraToTarget = direction.Unit
		local cameraLook = camCFrame.LookVector
		local dotProduct = math.clamp(cameraLook:Dot(cameraToTarget), 0, 1)

		local distanceScore = 1 / math.max(1, distance / 10)

		local totalScore = (camData.priority * PRIORITY_WEIGHT) 
			+ (dotProduct * CENTER_WEIGHT) 
			+ (distanceScore * DISTANCE_WEIGHT)

		-- Track the best overall scoring camera regardless of line of sight as a safety backup
		if totalScore > fallbackHighestScore then
			fallbackHighestScore = totalScore
			fallbackCam = camData.object
		end

		-- Check Line of Sight
		local result = workspace:Raycast(camPos, direction, rayParams)
		local hasLineOfSight = not result or result.Instance:IsDescendantOf(character)

		if hasLineOfSight then
			if totalScore > highestScore then
				highestScore = totalScore
				bestCam = camData.object
			end
		end
	end

	-- If a clear-shot camera was found, return it. Otherwise, return the best fallback camera!
	return bestCam or fallbackCam or (camTable[1] and camTable[1].object)
end

return PlayerCameraChooser
