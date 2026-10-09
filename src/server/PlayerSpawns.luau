
local spawns = {}
--[[
local Room1Spawn = workspace.Interactables.Zones.Room1
local Room2Spawn = workspace.Interactables.Zones.Room2
local Room3Spawn = workspace.Interactables.Zones.Room3
local Room4Spawn = workspace.Interactables.Zones.Room4
local BathroomSpawn = workspace.Interactables.Zones.Bathroom


local availableRooms = {
	Room1Spawn,
	Room2Spawn,
	Room3Spawn,
	Room4Spawn
}

local playerSpawns = {}

function spawns:GetSpawnLocation(character: Model, player: Player)
	if playerSpawns[player.Name] then return end

	local spawnLocation

	if math.random(1, 1000) == 1 then
		spawnLocation = BathroomSpawn
		workspace.Interactables.Doors.BathroomDoor:SetAttribute("Locked", false)
	else
		if #availableRooms == 0 then return end

		local index = math.random(1, #availableRooms)
		spawnLocation = table.remove(availableRooms, index)
	end

	playerSpawns[player.Name] = spawnLocation

	if character.PrimaryPart then
		character.PrimaryPart.CFrame = spawnLocation.CFrame
	end

	print("Spawned ", player.Name, " at ", spawnLocation)

	return spawnLocation
end

]]
return spawns