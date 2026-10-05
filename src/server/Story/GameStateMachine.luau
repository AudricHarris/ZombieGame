local GameStateMachine = {}
GameStateMachine.__index = GameStateMachine

function GameStateMachine.new()
	local self = setmetatable({}, GameStateMachine)
	
	self.states = {}
	self.currentState = nil
	
	return self
end

function GameStateMachine:AddState(name, stateTable)
	self.states[name] = stateTable
end

function GameStateMachine:ChangeState(newStateName, ...)
	if self.currentState and self.currentState.OnExit then
		self.currentState:OnExit()
	end

	self.currentState = self.states[newStateName]

	if self.currentState and self.currentState.OnEnter then
		self.currentState:OnEnter(...)
	end
end

function GameStateMachine:Update(dt)
	if self.currentState and self.currentState.OnUpdate then
		self.currentState:OnUpdate(dt)
	end
end

return GameStateMachine
