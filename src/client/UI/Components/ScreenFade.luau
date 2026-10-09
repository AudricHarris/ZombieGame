local ScreenFade = {}

function ScreenFade.init(gui)
	local Frame = Instance.new("Frame")
	Frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
	Frame.Size = UDim2.new(1,0,1,0)
	Frame.Parent = gui
	Frame.BackgroundTransparency = 1
	Frame.Name = "Fade"

	return Frame
end

return ScreenFade
