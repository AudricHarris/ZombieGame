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
local DEFAULT_MAX_DISTANCE = 30 -- per-camera "MaxDistance" attribute overrides this; farther than this = camera is never chosen

local TRANSPARENT_THRESHOLD = 0.5 -- parts at or above this Transparency don't block the view
local MAX_SKIPS = 20

local NEG = -math.huge
local pause = false

-- Reused every call so we don't allocate in a hot path
local viewParams = RaycastParams.new()
viewParams.FilterType = Enum.RaycastFilterType.Exclude
viewParams.IgnoreWater = true
local ignoreList: { Instance } = {}
local scores, dots, positions = {}, {}, {}

local function isViewBlocked(camPos: Vector3, targetPos: Vector3, character: Model): boolean
	table.clear(ignoreList)
	table.insert(ignoreList, character)
	viewParams.FilterDescendantsInstances = ignoreList

	for _ = 1, MAX_SKIPS do -- safety cap on how many see-through parts we skip
		local result = workspace:Raycast(camPos, targetPos - camPos, viewParams)
		if not result then
			return false -- nothing in the way
		end

		local hit = result.Instance
		local isSeeThrough = hit.Transparency >= TRANSPARENT_THRESHOLD
		local isOtherCharacter = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") ~= nil

		if isSeeThrough or isOtherCharacter then
			table.insert(ignoreList, hit) -- skip it and keep looking
			viewParams.FilterDescendantsInstances = ignoreList
		else
			return true -- opaque wall
		end
	end

	return true
end

local function takeBest(arr, n: number): number?
	local bestI, bestV = nil, NEG
	for i = 1, n do
		if arr[i] > bestV then
			bestI, bestV = i, arr[i]
		end
	end
	return bestI
end

-- Walk candidates best-first and only raycast until one is unblocked
local function resolve(arr, n: number, targetPos: Vector3, character: Model)
	while true do
		local i = takeBest(arr, n)
		if not i then return nil end
		if not isViewBlocked(positions[i], targetPos, character) then
			return camTable[i].object
		end
		-- blocked: remove from both tiers
		scores[i] = NEG
		dots[i] = NEG
	end
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

		local camData = {
			instance = camInstance,
			object = cameraObject,
			type = camType,
			priority = priority,
			maxDistance = camInstance:GetAttribute("MaxDistance") :: number? or DEFAULT_MAX_DISTANCE,
			zone = camInstance:FindFirstChild("TriggerZone"),
		}
		table.insert(camTable, camData)

		-- Keep values live if they're changed at runtime
		camInstance:GetAttributeChangedSignal("Priority"):Connect(function()
			camData.priority = camInstance:GetAttribute("Priority") :: number? or 1
		end)
		camInstance:GetAttributeChangedSignal("MaxDistance"):Connect(function()
			camData.maxDistance = camInstance:GetAttribute("MaxDistance") :: number? or DEFAULT_MAX_DISTANCE
		end)
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

	local targetPos = hrp.Position
	local n = #camTable

	-- Cheap pass: no raycasts. Fills two score arrays.
	--   scores = Tier 1: in the shot (angle + min distance)  -> weighted score
	--   dots   = Tier 2 (last resort): any camera in range    -> how much it faces the player
	for i = 1, n do
		scores[i], dots[i] = NEG, NEG

		local camData = camTable[i]
		local inst = camData.instance
		local camCFrame = inst:IsA("BasePart") and inst.CFrame or CFrame.new(inst.Position)
		local camPos = camCFrame.Position
		positions[i] = camPos

		local direction = targetPos - camPos
		local distance = direction.Magnitude
		if distance < 0.001 or distance > camData.maxDistance then continue end -- out of range = never an option

		local dot = camCFrame.LookVector:Dot(direction / distance)
		dots[i] = dot

		if dot >= MIN_COS and distance >= MIN_DISTANCE then
			local centerScore = (dot - MIN_COS) / (1 - MIN_COS)
			local distanceScore = 1 - math.clamp(math.abs(distance - IDEAL_DISTANCE) / IDEAL_DISTANCE, 0, 1)

			scores[i] = camData.priority * PRIORITY_WEIGHT
				+ centerScore * CENTER_WEIGHT
				+ distanceScore * DISTANCE_WEIGHT
		end
	end

	-- Raycast only as many candidates as needed, best first.
	-- If every camera is out of range or blocked, return nil so the caller keeps the current camera.
	return resolve(scores, n, targetPos, character) or resolve(dots, n, targetPos, character)
end

return PlayerCameraChooser
