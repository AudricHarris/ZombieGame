print("Hello world, from client!")
local PLR = game:GetService("Players")

local LocalPlayer = PLR.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Mouse = LocalPlayer:GetMouse()

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local PlayerLinker = require(script.PlayerUtils.PlayerLinker)
local UI = require(script.UI)

UI.Setup()
PlayerLinker.Setup()
