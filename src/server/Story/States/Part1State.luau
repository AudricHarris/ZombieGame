local Part1State = {}

function Part1State:OnEnter()
	print("Start of the Act 1 : Find the key")
	self.keyFound = false

	-- Futur me define how you find key
end

function Part1State:OnExit()
	print("Part 1 of Act 1 is finished")
end

-- you would also have OnUpdate()

return Part1State
