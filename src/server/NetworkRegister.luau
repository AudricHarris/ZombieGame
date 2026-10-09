local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Shared.Networker)

local NetworkRegister = {}

function NetworkRegister:Start()
	Networker.CreateFunction("CheckDoor")

	Networker.OnServerInvoke("CheckDoor", function(player, door)
		return NetworkRegister.CheckDoor(player, door)
	end)
end

function NetworkRegister.CheckDoor(player: Player, door: Model)
	if not door then
		return true
	end

	print(player.Name .. " checked door: " .. door.Name)

	local isLocked = door:GetAttribute("Locked")
	if isLocked == nil then
		return false
	end
	
	return isLocked
end

return NetworkRegister
