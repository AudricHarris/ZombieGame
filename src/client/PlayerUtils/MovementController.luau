local PathfindingService = game:GetService("PathfindingService")
local ContextActionService = game:GetService("ContextActionService")

--- @class MovementController : handles point and click and disable wasd by default
local MovementController = {}
MovementController.__index = MovementController

type MovementType = "Free" | "Node" | "None"

-- Constants
local FREEZE_ACTION : string = "freezeMovement"


--- This is the constructor for the MovementController this handles Point to click movement
--- by default it will disable wasd/zqsd movement
--- @param character : this is important to allow for players to move around (it can be the standard character or a random npc)
--- @param defaultType? : this has 3 types [Free, Node, None] they are self explanatory
--- @param nodesFolder? : folder containing the nodes in the room so players aproximate to those parts
function MovementController.new(character: Model, defaultType: MovementType?, nodesFolder: Folder?)
    local self = setmetatable({}, MovementController)
    self.Character = character
    self.Humanoid  = character:WaitForChild("Humanoid") :: Humanoid
    self.RootPart  = character:WaitForChild("HumanoidRootPart") :: BasePart

    self.MovementType = defaultType or "Free"
    self._currentTask = nil :: thread? -- Track the active movement thread

    -- Initialize sub-handlers
    if nodesFolder then
        local NodeMovement = require(script.Parent.Movement.NodeMovement)
        self.NodeHandler = NodeMovement.new(nodesFolder)
    end
    
    self:EnableMovement(false)

    return self
end

--- Set the modes between [Free, Node, None]
--- @param mode : this is the mode you wish to use
function MovementController:SetMode(newMode: MovementType)
    self.MovementType = newMode
end


--- EnableMovement allows to disable and enable wasd/zqsd keybinds 
--- @param enable : it takes apram enable which is a boolean duh XD.
function MovementController:EnableMovement(enable : boolean)
    if enable then
        self.MovementType = "None"
        ContextActionService:BindAction(
            FREEZE_ACTION,
            function() return Enum.ContextActionResult.Sink end,
            false,
            unpack(Enum.PlayerActions:GetEnumItems())
        )
    else
        ContextActionService:UnbindAction(FREEZE_ACTION)
        warn("!! movement type might be set to None don't forget to change it !!")
    end
end

--- Main function to execute movement on mouse click, differs between the different movement type
--- @param position : position where the mouse clicked (duh where else would it be)
function MovementController:MoveToWorldPosition(clickPosition: Vector3)
    if self.MovementType == "None" then 
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

--- Pathfinds character to final position safely
--- @param dest : Destination calculated by get position
function MovementController:_ExecutePathfinding(destination: Vector3)
    local path : Path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false
    })


    local success : boolean, _ = pcall(function()
        path:ComputeAsync(self.RootPart.Position, destination)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints : {PathWaypoint} = path:GetWaypoints()
        for _, waypoint : PathWaypoint in waypoints do
            self.Humanoid:MoveTo(waypoint.Position)
            local reached : boolean = false
            local conn : RBXScriptConnection
            conn = self.Humanoid.MoveToFinished:Connect(function()
                reached = true
                conn:Disconnect()
            end)
            
            local timeout : number = 0
            while not reached and timeout < 8 do
                timeout += task.wait()
            end
            if conn then conn:Disconnect() end
        end
    else
        self.Humanoid:MoveTo(destination)
    end
end

return MovementController
