local PathfindingService = game:GetService("PathfindingService")
local ContextActionService = game:GetService("ContextActionService")

--- @class MovementController
local MovementController = {}
MovementController.__index = MovementController

export type MovementType = "Free" | "Node" | "None" | "WASD"

-- Constants
local FREEZE_ACTION: string = "freezeMovement"

function MovementController.new(character: Model, defaultType: MovementType?, nodesFolder: Folder?)
	local self = setmetatable({}, MovementController)
	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.RootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	self.MovementType = defaultType or "Free"
	self._currentTask = nil :: thread?

	-- Initialize Sub-handlers
	if nodesFolder then
		local NodeMovement = require(script.Parent.Movement.NodeMovement)
		self.NodeHandler = NodeMovement.new(nodesFolder)
	end

	-- Initialize WASD Handler
	local WASDMovement = require(script.Parent.Movement.WASDMovement)
	self.WASDHandler = WASDMovement.new(character)

	-- Apply initial state
	self:SetMode(self.MovementType)

	return self
end

--- Switch active movement modes safely
function MovementController:SetMode(newMode: MovementType)
	-- Cancel active pathfinding task if switching away or starting a new action
	if self._currentTask then
		task.cancel(self._currentTask)
		self._currentTask = nil
	end

	self.MovementType = newMode

	if newMode == "WASD" then
		-- Enable standard WASD controls & unbind input sink
		ContextActionService:UnbindAction(FREEZE_ACTION)
		if self.WASDHandler and self.WASDHandler.Enable then
			self.WASDHandler:Enable(true)
		end
	elseif newMode == "None" then
		-- Disable WASD movement inputs completely
		if self.WASDHandler and self.WASDHandler.Enable then
			self.WASDHandler:Enable(false)
		end
		self:_SinkWASDInputs(true)
	else
		-- Point & Click modes ("Free" or "Node")
		if self.WASDHandler and self.WASDHandler.Enable then
			self.WASDHandler:Enable(false)
		end
		self:_SinkWASDInputs(true)
	end
end

--- Sinks standard WASD / Player movement inputs using ContextActionService
function MovementController:_SinkWASDInputs(sink: boolean)
	if sink then
		ContextActionService:BindAction(
			FREEZE_ACTION,
			function() return Enum.ContextActionResult.Sink end,
			false,
			unpack(Enum.PlayerActions:GetEnumItems())
		)
	else
		ContextActionService:UnbindAction(FREEZE_ACTION)
	end
end

--- Main function to execute movement on mouse click
function MovementController:MoveToWorldPosition(clickPosition: Vector3)
	-- Ignore mouse clicks if mode is WASD or None
	if self.MovementType == "None" or self.MovementType == "WASD" then 
		return 
	end

	local finalTargetPos: Vector3? = nil

	if self.MovementType == "Free" then
		finalTargetPos = clickPosition
	elseif self.MovementType == "Node" and self.NodeHandler then
		finalTargetPos = self.NodeHandler:GetTargetPosition(clickPosition)
	end

	if finalTargetPos then
		if self._currentTask then
			task.cancel(self._currentTask)
			self._currentTask = nil
		end
		self._currentTask = task.spawn(function()
			self:_ExecutePathfinding(finalTargetPos)
			self._currentTask = nil
		end)
	end
end

--- Executes pathfinding to destination
function MovementController:_ExecutePathfinding(destination: Vector3)
	local path: Path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false
	})

	local success: boolean, _ = pcall(function()
		path:ComputeAsync(self.RootPart.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		local waypoints: {PathWaypoint} = path:GetWaypoints()
		for _, waypoint: PathWaypoint in waypoints do
			self.Humanoid:MoveTo(waypoint.Position)
			local reached = false
			local conn: RBXScriptConnection
			conn = self.Humanoid.MoveToFinished:Connect(function()
				reached = true
				if conn then conn:Disconnect() end
			end)

			local timeout = 0
			while not reached and timeout < 8 do
				timeout += task.wait()
			end
			if conn and conn.Connected then conn:Disconnect() end
		end
	else
		self.Humanoid:MoveTo(destination)
	end
end

function MovementController:Destroy()
	if self._currentTask then
		task.cancel(self._currentTask)
	end
	self:_SinkWASDInputs(false)
	if self.WASDHandler and self.WASDHandler.Destroy then
		self.WASDHandler:Destroy()
	end
end

return MovementController
