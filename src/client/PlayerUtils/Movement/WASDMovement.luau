local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--- @class WASDMovement
local WASDMovement = {}
WASDMovement.__index = WASDMovement

function WASDMovement.new(character: Model)
	local self = setmetatable({}, WASDMovement)

	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.RootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	self.Enabled = false
	self.TurnSpeed = 20 -- Speed at which character rotates toward mouse

	self.KeysHeld = {
		Forward = false,
	}

	return self
end

--- Calculates forward-only movement relative to the character's current facing direction
function WASDMovement:_GetMoveVector(): Vector3
	if not self.RootPart or not self.KeysHeld.Forward then 
		return Vector3.zero 
	end

	-- Extract forward direction vector on horizontal plane
	local rootCFrame = self.RootPart.CFrame
	local forward = Vector3.new(rootCFrame.LookVector.X, 0, rootCFrame.LookVector.Z)

	return if forward.Magnitude > 0 then forward.Unit else Vector3.zero
end

--- Aim character towards mouse cursor
function WASDMovement:_UpdateAim(dt: number)
	if not Mouse.Hit then return end

	local mousePos = Mouse.Hit.Position
	local rootPos = self.RootPart.Position

	if (mousePos - rootPos).Magnitude < 4 then return end
	-- Target on the horizontal XZ plane
	local targetPos = Vector3.new(mousePos.X, rootPos.Y, mousePos.Z)

	if (targetPos - rootPos).Magnitude > 0.1 then
		local targetCFrame = CFrame.lookAt(rootPos, targetPos)
		self.RootPart.CFrame = self.RootPart.CFrame:Lerp(targetCFrame, math.clamp(dt * self.TurnSpeed, 0, 1))
	end
end

--- Key input tracking (ONLY checks forward key: W / Z)
function WASDMovement:_OnInput(input: InputObject, isProcessed: boolean, isKeyDown: boolean)
	if isProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	local keyCode = input.KeyCode

	-- Only track Forward key (W for QWERTY, Z for AZERTY)
	if keyCode == Enum.KeyCode.W or keyCode == Enum.KeyCode.Z then
		self.KeysHeld.Forward = isKeyDown
	end
end

--- Enable or disable movement & mouse aim
function WASDMovement:Enable(enable: boolean)
	if self.Enabled == enable then return end
	self.Enabled = enable

	if enable then
		self.Humanoid.AutoRotate = false
		self.KeysHeld.Forward = false

		self._inputBeganConn = UserInputService.InputBegan:Connect(function(input, processed)
			self:_OnInput(input, processed, true)
		end)

		self._inputEndedConn = UserInputService.InputEnded:Connect(function(input, processed)
			self:_OnInput(input, processed, false)
		end)

		-- Aim towards mouse, then move forward if W is held
		self._renderConnection = RunService.RenderStepped:Connect(function(dt)
			self:_UpdateAim(dt)

			local moveVector = self:_GetMoveVector()
			if self.Humanoid and self.Humanoid.Parent then
				self.Humanoid:Move(moveVector, false)
			end
		end)
	else
		if self.Humanoid then
			self.Humanoid.AutoRotate = true
		end

		if self._inputBeganConn then self._inputBeganConn:Disconnect() end
		if self._inputEndedConn then self._inputEndedConn:Disconnect() end
		if self._renderConnection then self._renderConnection:Disconnect() end

		if self.Humanoid and self.Humanoid.Parent then
			self.Humanoid:Move(Vector3.zero, false)
		end
	end
end

function WASDMovement:Destroy()
	self:Enable(false)
end

return WASDMovement
