--!native
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkRegister = require(script.NetworkRegister)
local CharacterHandler = require(ReplicatedStorage.Shared.Outfit.CharacterHandler)

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		print("Hello")
		CharacterHandler.OnCharacterAdded(character)
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

Lighting.Brightness = 0
Lighting.TimeOfDay = 0

NetworkRegister.start()
