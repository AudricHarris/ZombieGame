local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Shared.Networker)

local ElevatorVoteManager = {}

-- Constants
const VOTE_DURATION = 10
const MAX_INTERACTION_DISTANCE = 20

-- Active Vote State
local activeVote = nil
local isStarted = false


local function isValidElevator(elevator: Instance): boolean
	if typeof(elevator) ~= "Instance" then
		return false
	end

	if not elevator:IsDescendantOf(workspace) then
		return false
	end

	if not CollectionService:HasTag(elevator, "Interactable") then
		return false
	end

	if elevator:GetAttribute("Type") ~= "Elevator" then
		return false
	end

	return true
end

local function endVote(vote: table)
	if activeVote ~= vote or vote.Finished then
		return
	end

	vote.Finished = true

	local yesVotes = 0
	local noVotes = 0

	for player, voteValue in pairs(vote.Votes) do
		if vote.Eligible[player] then
			if voteValue == true then
				yesVotes += 1
			else
				noVotes += 1
			end
		end
	end

	local totalVotes = yesVotes + noVotes
	local success = totalVotes > 0 and (yesVotes / totalVotes) >= 0.5

	activeVote = nil

	Networker.FireAllClients("ElevatorVoteEnd", success, vote.Elevator)

	if success then
		Networker.FireAllClients("ElevatorVoteSuccess", vote.Elevator)
	end
end

local function checkAndFinishVote(vote: table)
	if activeVote ~= vote or vote.Finished then
		return
	end

	local eligibleCount = 0
	local votedCount = 0

	for player in pairs(vote.Eligible) do
		eligibleCount += 1

		if vote.Votes[player] ~= nil then
			votedCount += 1
		end
	end

	if eligibleCount > 0 and votedCount >= eligibleCount then
		endVote(vote)
	end
end


function ElevatorVoteManager.StartVote(player: Player, elevator: Instance)
	if activeVote then
		return
	end

	if not isValidElevator(elevator) then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local elevatorPosition = elevator:GetPivot().Position
	if (root.Position - elevatorPosition).Magnitude > MAX_INTERACTION_DISTANCE then
		return
	end

	local vote = {
		Elevator = elevator,
		Eligible = {},
		Votes = {},
		Finished = false
	}

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		vote.Eligible[targetPlayer] = true
	end

	activeVote = vote

	Networker.FireAllClients("ElevatorVoteStart", VOTE_DURATION)

	task.delay(VOTE_DURATION, function()
		if activeVote == vote then
			endVote(vote)
		end
	end)
end

function ElevatorVoteManager.CastVote(player: Player, voteValue: boolean)
	if not activeVote then
		return
	end

	if not activeVote.Eligible[player] then
		return
	end

	if activeVote.Votes[player] ~= nil then
		return
	end

	if typeof(voteValue) ~= "boolean" then
		return
	end

	activeVote.Votes[player] = voteValue
	checkAndFinishVote(activeVote)
end

function ElevatorVoteManager.HandlePlayerRemoving(player: Player)
	if not activeVote then
		return
	end

	activeVote.Eligible[player] = nil
	activeVote.Votes[player] = nil

	checkAndFinishVote(activeVote)
end

function ElevatorVoteManager.GetActiveVote()
	return activeVote
end

--- Creates network remotes and connects server event listeners.
function ElevatorVoteManager:Start()
	if isStarted then
		return
	end
	isStarted = true

	Networker.CreateRemote("ElevatorVoteRequest")
	Networker.CreateRemote("ElevatorVoteCast")
	Networker.CreateRemote("ElevatorVoteStart")
	Networker.CreateRemote("ElevatorVoteEnd")
	Networker.CreateRemote("ElevatorVoteSuccess")

	Networker.OnServerEvent("ElevatorVoteRequest"):Connect(function(player, elevator)
		ElevatorVoteManager.StartVote(player, elevator)
	end)

	Networker.OnServerEvent("ElevatorVoteCast"):Connect(function(player, voteValue)
		ElevatorVoteManager.CastVote(player, voteValue)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ElevatorVoteManager.HandlePlayerRemoving(player)
	end)
end

return ElevatorVoteManager
