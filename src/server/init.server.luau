--!native
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkRegister = require(script.NetworkRegister)
local Voting = require(script.ElevatorVoteManager)
local DataStore = require(script.DataStore)
local CharacterHandler = require(ReplicatedStorage.Shared.Outfit.CharacterHandler)
--local Spawns = require(script.PlayerSpawns)

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		print("Hello")
		CharacterHandler.OnCharacterAdded(character)
		--Spawns:GetSpawnLocation(character, player)
	end)

	-- In case the appearance already loaded before we connected
	if player.Character and player:HasAppearanceLoaded() then
		task.spawn(CharacterHandler.OnCharacterAdded, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Lighting.Brightness = 2
Lighting.TimeOfDay = 14

NetworkRegister:Start()
Voting:Start()
DataStore:Start()