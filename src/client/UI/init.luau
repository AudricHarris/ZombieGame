local Players = game:GetService("Players")

local ScreenFade = require(script.Components.ScreenFade)

local LocalPlayer = Players.LocalPlayer

local UI = {}
UI.list = {}
UI.isInitialized = false

function UI.Setup()
	if UI.isInitialized then return end
	UI.isInitialized = true

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	
	local Gui = Instance.new("ScreenGui")
	Gui.IgnoreGuiInset = true
	Gui.Name = "MainGui"
	Gui.Parent = playerGui

	UI.list["Fade"] = ScreenFade.init(Gui)
end

function UI.Get(name: string): any
	if not UI.isInitialized then
		UI.Setup()
	end
	return UI.list[name]
end

return UI
