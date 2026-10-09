-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Requiremetns
local Networker = require(ReplicatedStorage.Shared.Networker)
local Door = require(script.Interactions.Door)
local Elevator = require(script.Interactions.Elevator)
local Interactable = require(script.Interactions.Interactable)

local World = {}

World.interactableObjects = {}

-- Local functions
local function registerInteractable(instance : Instance)
	if World.interactableObjects[instance] then return end

	local type = instance:GetAttribute("Type") or "Misc"

	if type == "Door" then
		World.interactableObjects[instance] = Door.new(instance)
	elseif type == "Elevator" then
		World.interactableObjects[instance] = Elevator.new(instance)
	else
		World.interactableObjects[instance] = Interactable.new(instance)
	end
end

local function unregisterInteractable(instance : Instance)
	World.interactableObjects[instance] = nil
end

--- This function setups the world and rendering on local side
function World.SetUp()
	World.InitInteract(CollectionService:GetTagged("Interactable"))
	CollectionService:GetInstanceAddedSignal("Interactable"):Connect(registerInteractable)
	CollectionService:GetInstanceRemovedSignal("Interactable"):Connect(unregisterInteractable)

	return World
end

function World.InitInteract(interactables : {Instance})
	for _, instance in ipairs(interactables) do
		registerInteractable(instance)
	end
end

function World.GetInteractFromInstance(hitInstance : Instance?): (Instance?, any?)
	if not hitInstance then return nil, nil end

	local current : Instance? = hitInstance
	local taggedInstance : Instance? = nil

	while current and current ~= workspace do
		if CollectionService:HasTag(current, "Interactable") then
			taggedInstance = current
		end

		current = current.Parent
	end

	if taggedInstance and World.interactableObjects[taggedInstance] then
		return taggedInstance, World.interactableObjects[taggedInstance]
	end
	return nil, nil
end

function World.Interact(taggedInst, interactObj, char)
	if interactObj:CanInteract(char) then
		interactObj:Interact(Players.LocalPlayer)
	end
end

Networker.OnClientEvent("ElevatorVoteSuccess"):Connect(function(elevator)
	local elevatorObject = World.interactableObjects[elevator]

	if elevatorObject and Players.LocalPlayer.Character then
		elevatorObject:Interact(Players.LocalPlayer)
	end
end)

return World
