local NodeMovement = {}
NodeMovement.__index = NodeMovement

function NodeMovement.new(nodesFolder: Folder)
    local self = setmetatable({}, NodeMovement)
    self.Nodes = nodesFolder:GetChildren()
    return self
end

function NodeMovement:GetClosestNode(clickPosition: Vector3): BasePart?
    local closestNode: BasePart? = nil
    local shortestDistance = math.huge

    for _, node in self.Nodes do
        if node:IsA("BasePart") then
            local distance = (node.Position - clickPosition).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestNode = node
            end
        end
    end

    return closestNode
end

function NodeMovement:GetTargetPosition(clickPosition: Vector3): Vector3?
    local targetNode = self:GetClosestNode(clickPosition)
    return targetNode and targetNode.Position or nil
end

return NodeMovement
