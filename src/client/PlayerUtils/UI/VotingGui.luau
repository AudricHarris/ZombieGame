local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VotingGui = PlayerGui:WaitForChild("VotingGui")
local VotingFrame = VotingGui:WaitForChild("VotingFrame")

local VotingText = VotingFrame:WaitForChild("VotingText")
local YesButton = VotingFrame:WaitForChild("YesButton")
local NoButton = VotingFrame:WaitForChild("NoButton")

local Networker = require(ReplicatedStorage.Shared.Networker)

local voting = {}

local isVoting = false
local hasVoted = false
local voteConnection = 0

local votingTextSound = SoundService:WaitForChild("VotingTextSound")

local originalFrameSize = VotingFrame.Size
local originalFramePosition = VotingFrame.Position

local smallerFrameSize = UDim2.new(
	originalFrameSize.X.Scale * 0.9,
	originalFrameSize.X.Offset * 0.9,
	originalFrameSize.Y.Scale * 0.9,
	originalFrameSize.Y.Offset * 0.9
)

local originalTextTransparency = VotingText.TextTransparency
local originalTextStrokeTransparency = nil

local textStroke = VotingText:FindFirstChildOfClass("UIStroke")

if textStroke then
	originalTextStrokeTransparency = textStroke.Transparency
end

local buttonData = {}

for _, button in ipairs({YesButton, NoButton}) do
	local strokeData = {}

	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("UIStroke") then
			strokeData[descendant] = descendant.Transparency
		end
	end

	buttonData[button] = {
		TextTransparency = button.TextTransparency,
		BackgroundTransparency = button.BackgroundTransparency,
		Strokes = strokeData
	}
end

local function setTextInvisible()
	VotingText.TextTransparency = 1

	if textStroke then
		textStroke.Transparency = 1
	end
end

local function setButtonsInvisible()
	for button in pairs(buttonData) do
		button.TextTransparency = 1
		button.BackgroundTransparency = 1

		for _, descendant in ipairs(button:GetDescendants()) do
			if descendant:IsA("UIStroke") then
				descendant.Transparency = 1
			end
		end
	end
end

local function tweenTextVisible(duration)
	local textTween = TweenService:Create(
		VotingText,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = originalTextTransparency
		}
	)

	textTween:Play()

	if textStroke and originalTextStrokeTransparency then
		TweenService:Create(
			textStroke,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = originalTextStrokeTransparency
			}
		):Play()
	end

	return textTween
end

local function tweenButtonsVisible(duration)
	for button, data in pairs(buttonData) do
		local properties = {
			TextTransparency = data.TextTransparency,
			BackgroundTransparency = data.BackgroundTransparency
		}

		TweenService:Create(
			button,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			properties
		):Play()

		for stroke, originalTransparency in pairs(data.Strokes) do
			stroke.Transparency = 1

			TweenService:Create(
				stroke,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Transparency = originalTransparency
				}
			):Play()
		end
	end
end

local function fadeEverythingOut(duration)
	local frameTween = TweenService:Create(
		VotingFrame,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = smallerFrameSize,
			Position = originalFramePosition + UDim2.fromOffset(0, 20)
		}
	)

	frameTween:Play()

	TweenService:Create(
		VotingText,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			TextTransparency = 1
		}
	):Play()

	if textStroke then
		TweenService:Create(
			textStroke,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Transparency = 1
			}
		):Play()
	end

	for button in pairs(buttonData) do
		TweenService:Create(
			button,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				TextTransparency = 1,
				BackgroundTransparency = 1
			}
		):Play()

		for _, descendant in ipairs(button:GetDescendants()) do
			if descendant:IsA("UIStroke") then
				TweenService:Create(
					descendant,
					TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Transparency = 1
					}
				):Play()
			end
		end
	end

	return frameTween
end

local function typeText(text, connection)
	VotingText.Text = ""

	for i = 1, #text do
		if not isVoting or connection ~= voteConnection then
			return false
		end

		VotingText.Text = string.sub(text, 1, i)

		votingTextSound:Play()

		task.wait(0.035)
	end

	return true
end

function voting:StartVoting(duration)
	voteConnection += 1
	local currentConnection = voteConnection

	isVoting = true
	hasVoted = false

	VotingFrame.Visible = true
	VotingFrame.Size = smallerFrameSize
	VotingFrame.Position = originalFramePosition + UDim2.fromOffset(0, 30)

	VotingText.Text = ""

	setTextInvisible()
	setButtonsInvisible()

	YesButton.Active = false
	NoButton.Active = false
	YesButton.AutoButtonColor = false
	NoButton.AutoButtonColor = false

	local frameTween = TweenService:Create(
		VotingFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = originalFrameSize,
			Position = originalFramePosition
		}
	)

	frameTween:Play()
	frameTween.Completed:Wait()

	if not isVoting or currentConnection ~= voteConnection then
		return
	end

	tweenTextVisible(0.2)

	task.wait(0.2)

	if not isVoting or currentConnection ~= voteConnection then
		return
	end

	local textFinished = typeText("Would you like to enter the Elevator?", currentConnection)

	if not textFinished then
		return
	end

	if not isVoting or currentConnection ~= voteConnection then
		return
	end

	tweenButtonsVisible(0.35)

	YesButton.Active = true
	NoButton.Active = true
	YesButton.AutoButtonColor = true
	NoButton.AutoButtonColor = true

	for timeLeft = duration, 0, -1 do
		if not isVoting or currentConnection ~= voteConnection then
			return
		end

		if hasVoted then
			VotingText.Text = "Would you like to enter the Elevator?"
		else
			VotingText.Text = "Would you like to enter the Elevator?\n" .. timeLeft
		end

		if timeLeft > 0 then
			task.wait(1)
		end
	end
end

function voting:EndVoting()
	if not isVoting then
		return
	end

	voteConnection += 1
	isVoting = false
	hasVoted = false

	YesButton.Active = false
	NoButton.Active = false
	YesButton.AutoButtonColor = false
	NoButton.AutoButtonColor = false

	local frameTween = fadeEverythingOut(0.35)

	frameTween.Completed:Wait()

	VotingFrame.Visible = false
	VotingFrame.Size = originalFrameSize
	VotingFrame.Position = originalFramePosition

	setTextInvisible()
	setButtonsInvisible()
end

local function castVote(vote)
	if not isVoting or hasVoted then
		return
	end

	hasVoted = true

	YesButton.Active = false
	NoButton.Active = false
	YesButton.AutoButtonColor = false
	NoButton.AutoButtonColor = false

	Networker.FireServer("ElevatorVoteCast", vote)
end

YesButton.Activated:Connect(function()
	castVote(true)
	SoundService.ClickSound:Play()
end)

NoButton.Activated:Connect(function()
	castVote(false)
	SoundService.ClickSound:Play()
end)

Networker.OnClientEvent("ElevatorVoteStart"):Connect(function(duration)
	voting:StartVoting(duration)
end)

Networker.OnClientEvent("ElevatorVoteEnd"):Connect(function()
	voting:EndVoting()
end)

return voting
