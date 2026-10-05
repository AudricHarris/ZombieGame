--!strict
local InsertService = game:GetService("InsertService")
local PhysicsService = game:GetService("PhysicsService")
local CustomCharacter = require(script.Parent.CustomCharacter)

local CharacterHandler = {}

-- Outfit slots that load an Accessory
local ACCESSORY_SLOTS = {
	Hat = true, Hair = true, FaceAccessory = true, Neck = true,
	Shoulders = true, Front = true, Back = true, Waist = true,
}

local function extractAssetId(asset: any): number?
	if type(asset) == "number" then return asset end
	if type(asset) ~= "string" then return nil end
	local id = string.match(asset, "%d+")
	return id and tonumber(id) or nil
end

-- Loads an asset and returns the first child of the given class
local function loadItem(assetId: number, className: string): Instance?
	local ok, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		warn(`[CH] LoadAsset failed for {assetId}: {result}`)
		return nil
	end

	local model = result :: Model
	local item = model:FindFirstChildWhichIsA(className, true)
	if not item then
		warn(`[CH] Asset {assetId} contains no {className} (wrong asset type for this slot)`)
		model:Destroy()
		return nil
	end

	item.Parent = nil
	model:Destroy()
	return item
end

local function toList(value: any): { any }
	return if type(value) == "table" then value else { value }
end

local function applyClothing(character: Model, className: string, value: any)
	local id = extractAssetId(value)
	if not id then
		warn(`[CH] Bad {className} asset:`, value)
		return
	end

	local item = loadItem(id, className)
	if not item then return end

	for _, old in character:GetChildren() do
		if old:IsA(className) then old:Destroy() end
	end
	item.Parent = character
	print(`[CH] Applied {className} {id}`)
end

local function applyAccessories(humanoid: Humanoid, slot: string, value: any)
	for _, asset in toList(value) do
		local id = extractAssetId(asset)
		if not id then
			warn(`[CH] Bad asset in {slot}:`, asset)
			continue
		end

		local accessory = loadItem(id, "Accessory")
		if accessory then
			humanoid:AddAccessory(accessory :: Accessory)
			print(`[CH] Applied {slot} {id}`)
		end
	end
end

local function applyFace(character: Model, value: any)
	local id = extractAssetId(value)
	local head = character:FindFirstChild("Head")
	if not id or not head then return end

	local decal = loadItem(id, "Decal")
	if not decal then return end

	local old = head:FindFirstChild("face")
	if old then old:Destroy() end
	decal.Name = "face"
	decal.Parent = head
end

local function applySkinColor(character: Model, color: Color3)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	local bc = bodyColors :: BodyColors
	bc.HeadColor3 = color
	bc.TorsoColor3 = color
	bc.LeftArmColor3 = color
	bc.RightArmColor3 = color
	bc.LeftLegColor3 = color
	bc.RightLegColor3 = color
end

local function setCollisionGroup(character: Model)
	if not PhysicsService:IsCollisionGroupRegistered("Character") then return end
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Character"
		end
	end
end

function CharacterHandler.SetupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then return end

	local outfit = CustomCharacter.GetRandomOutfit()
	if not outfit then return end

	-- Clear what the player's own avatar loaded
	humanoid:RemoveAccessories()

	for slot, value in outfit :: any do
		if slot == "SkinColor" then
			applySkinColor(character, value)
		elseif slot == "Shirt" then
			applyClothing(character, "Shirt", value)
		elseif slot == "Pants" then
			applyClothing(character, "Pants", value)
		elseif slot == "TShirt" then
			applyClothing(character, "ShirtGraphic", value)
		elseif slot == "Face" then
			applyFace(character, value)
		elseif ACCESSORY_SLOTS[slot] then
			applyAccessories(humanoid, slot, value)
		else
			warn("[CH] Unknown or unsupported slot:", slot)
		end
	end
end

function CharacterHandler.OnCharacterAdded(character: Model)
	CharacterHandler.SetupCharacter(character)
	setCollisionGroup(character)
end

return CharacterHandler
