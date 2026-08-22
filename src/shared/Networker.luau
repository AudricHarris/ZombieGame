--!strict

--- @class Networker
--- A centralized networking wrapper for managing RemoteEvents and RemoteFunctions safely with strict typing.
local Networker = {}

-- Services
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")

--- Internal helper to safely locate or instantiate RemoteEvents.
--- @param name string The identifier of the remote event.
--- @return RemoteEvent
local function _get_remote_event(name: string): RemoteEvent
	local realName: string = "rev_" .. name
	local existing: RemoteEvent? = script:FindFirstChild(realName) :: RemoteEvent?

	if existing then
		return existing
	else
		if RunService:IsClient() then
			return script:WaitForChild(realName, 10) :: RemoteEvent
		else
			local i: RemoteEvent = Instance.new("RemoteEvent")
			i.Name = realName
			i.Parent = script
			return i
		end
	end
end

--- Internal helper to safely locate or instantiate RemoteFunctions.
--- @param name string The identifier of the remote function.
--- @return RemoteFunction
local function _get_remote_function(name: string): RemoteFunction
	local realName: string = "rfn_" .. name
	local existing: RemoteFunction? = script:FindFirstChild(realName) :: RemoteFunction?

	if existing then
		return existing
	else
		if RunService:IsClient() then
			return script:WaitForChild(realName, 10) :: RemoteFunction
		else
			local i: RemoteFunction = Instance.new("RemoteFunction")
			i.Name = realName
			i.Parent = script
			return i
		end
	end
end

-------------------
-- REMOTE EVENTS --
-------------------

--- Creates a new RemoteEvent with the given name if it doesn't exist, or fetches the existing instance.
--- @param name string The unique name of the RemoteEvent.
--- @return RemoteEvent The created or retrieved RemoteEvent instance.
function Networker.CreateRemote(name: string): RemoteEvent
	return _get_remote_event(name)
end

--- Sends an event from the client to the server with optional arguments.
--- @param name string The name of the target RemoteEvent.
--- @param ... any Optional payload data to send to the server.
function Networker.FireServer(name: string, ...: any)
	_get_remote_event(name):FireServer(...)
end

--- Sends an event from the server to a specific client.
--- @param name string The name of the target RemoteEvent.
--- @param client Player The target Player object to receive the event.
--- @param ... any Optional payload data to send to the client.
function Networker.FireClient(name: string, client: Player, ...: any)
	_get_remote_event(name):FireClient(client, ...)
end

--- Sends an event from the server to every connected client in the game.
--- @param name string The name of the target RemoteEvent.
--- @param ... any Optional payload data to send to all clients.
function Networker.FireAllClients(name: string, ...: any)
	Networker.FireListClients(name, Players:GetPlayers(), ...)
end

--- Sends an event from the server to a specific list of clients.
--- @param name string The name of the target RemoteEvent.
--- @param lst {Player} An array table containing target Player instances.
--- @param ... any Optional payload data to send to the specified clients.
function Networker.FireListClients(name: string, lst: { Player }, ...: any)
	local rev: RemoteEvent = _get_remote_event(name)
	for _, player: Player in ipairs(lst) do
		rev:FireClient(player, ...)
	end
end

--- Returns the `OnClientEvent` signal for the specified remote event. Used by client scripts to listen for server events.
--- @param name string The name of the RemoteEvent to listen for.
--- @return RBXScriptSignal The event signal to connect a handler callback to.
function Networker.OnClientEvent(name: string): RBXScriptSignal
	return _get_remote_event(name).OnClientEvent
end

--- Returns the `OnServerEvent` signal for the specified remote event. Used by server scripts to listen for client events.
--- @param name string The name of the RemoteEvent to listen for.
--- @return RBXScriptSignal The event signal to connect a handler callback to.
function Networker.OnServerEvent(name: string): RBXScriptSignal
	return _get_remote_event(name).OnServerEvent
end

----------------------
-- REMOTE FUNCTIONS --
----------------------

--- Creates a new RemoteFunction with the given name if it doesn't exist, or fetches the existing instance.
--- @param name string The unique name of the RemoteFunction.
--- @return RemoteFunction The created or retrieved RemoteFunction instance.
function Networker.CreateFunction(name: string): RemoteFunction
	return _get_remote_function(name)
end

--- Invokes a function on the server from the client and yields until a response is returned.
--- @param name string The name of the RemoteFunction to invoke.
--- @param ... any Arguments to pass to the server callback handler.
--- @return ...any The values returned by the server callback.
function Networker.InvokeServer(name: string, ...: any): ...any
	return _get_remote_function(name):InvokeServer(...)
end

--- Invokes a function on a specific client from the server and yields until a response is returned.
--- @param name string The name of the RemoteFunction to invoke.
--- @param client Player The target Player to invoke.
--- @param ... any Arguments to pass to the client callback handler.
--- @return ...any The values returned by the client callback.
function Networker.InvokeClient(name: string, client: Player, ...: any): ...any
	return _get_remote_function(name):InvokeClient(client, ...)
end

--- Binds a callback function on the server to handle incoming client invocations.
--- @param name string The name of the RemoteFunction to bind.
--- @param callback (player: Player, ...any) -> ...any The function executed when invoked. The invoking Player is automatically passed as the first argument.
function Networker.OnServerInvoke(name: string, callback: (player: Player, ...any) -> ...any)
	_get_remote_function(name).OnServerInvoke = callback
end

--- Binds a callback function on the client to handle incoming server invocations.
--- @param name string The name of the RemoteFunction to bind.
--- @param callback (...any) -> ...any The function executed when invoked by the server.
function Networker.OnClientInvoke(name: string, callback: (...any) -> ...any)
	_get_remote_function(name).OnClientInvoke = callback
end

return Networker
