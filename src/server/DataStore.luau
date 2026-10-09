local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local DataStore2 = require(ServerStorage.Packages.DataStore2)

local DataStore = {}
DataStore.PlayerDataCache = {}

local DEFAULT_PLAYER_DATA = {
	Wins = 0,
	Deaths = 0,
	Cash = 0,
	OwnedPrests = {},
	OwnedCosmetics = {},
	EquipedPreset = "",
	EquipedCosmetic = {},
}

local function MergeDefaults(playerData, defaultData)
	for key, value in pairs(defaultData) do
		if playerData[key] == nil then
			if type(value) == "table" then
				playerData[key] = table.clone(value)
			else
				playerData[key] = value
			end
		elseif type(value) == "table" and type(playerData[key]) == "table" then
			if key == "OwnedPrests" or key == "OwnedCosmetics" then
				for _, v in ipairs(value) do
					if not table.find(playerData[key], v) then
						table.insert(playerData[key], v)
					end
				end
			else
				for subKey, subValue in pairs(value) do
					if playerData[key][subKey] == nil then
						playerData[key][subKey] = subValue
					end
				end
			end
		end
	end
end

local function GetStore(player: Player)
	return DataStore2("PlayerData", player)
end

function DataStore.Get(player: Player)
	return DataStore.PlayerDataCache[player]
end

function DataStore.LoadPlayerData(player: Player, retries: number?): { [string]: any }?
	retries = retries or 5
	local store = GetStore(player)

	for attempt = 1, retries :: number do
		local success, data = pcall(function()
			local d = store:Get({})
			MergeDefaults(d, DEFAULT_PLAYER_DATA)
			store:Set(d)
			return d
		end)

		if success and data then
			DataStore.PlayerDataCache[player] = data
			return data
		end
		task.wait(1)
	end

	player:Kick("Failed to load your data. Please rejoin.")
	return nil
end

function DataStore.SavePlayerData(player: Player)
	local data = DataStore.PlayerDataCache[player]
	if data then
		local store = GetStore(player)
		local success, err = pcall(function()
			store:Set(data)
		end)
		if not success then
			warn("Failed to save DataStore2 for " .. player.Name .. ":", err)
		end
	end
end

function DataStore.Update(player: Player, newData: { [string]: any })
	local data = DataStore.PlayerDataCache[player]
	if not data then return end
	
	for key, value in pairs(newData) do
		data[key] = value
	end
	DataStore.SavePlayerData(player)
end

function DataStore:Start()
	-- Handle Player Added
	Players.PlayerAdded:Connect(function(player)
		local data = DataStore.LoadPlayerData(player)
		if data then
			print("Loaded data for", player.Name, data)
		end
	end)

	-- Handle existing players (useful during studio testing / hot reloading)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			DataStore.LoadPlayerData(player)
		end)
	end

	-- Handle Player Leaving
	Players.PlayerRemoving:Connect(function(player)
		DataStore.SavePlayerData(player)
		DataStore.PlayerDataCache[player] = nil
	end)

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(30)
			for player in pairs(DataStore.PlayerDataCache) do
				DataStore.SavePlayerData(player)
			end
		end
	end)
end

return DataStore
