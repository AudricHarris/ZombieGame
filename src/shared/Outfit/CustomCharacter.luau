--!strict

-- An asset can be a number, "rbxassetid://123", or a catalog/asset URL.
export type Asset = number | string
-- Accessory slots can take one asset or a list of them.
export type Assets = Asset | { Asset }

export type Outfit = {
	SkinColor: Color3?,

	-- Accessories (one or many each)
	Hat: Assets?,
	Hair: Assets?,
	FaceAccessory: Assets?,
	Neck: Assets?,
	Shoulders: Assets?,
	Front: Assets?,
	Back: Assets?,
	Waist: Assets?,

	-- Clothing / body (single asset each)
	Shirt: Asset?,
	Pants: Asset?,
	TShirt: Asset?,
	Head: Asset?,
	Face: Asset?, -- the face decal
	Torso: Asset?,
	LeftArm: Asset?,
	RightArm: Asset?,
	LeftLeg: Asset?,
	RightLeg: Asset?,
}

local CustomCharacter = {}

CustomCharacter.Outfits = {
	Outfit1 = {
		SkinColor = Color3.fromRGB(227, 164, 118),
		Head = "https://www.roblox.com/catalog/948/",
		Shirt = "rbxassetid://1711669722",
		Pants = "rbxassetid://1711671059",
		Hair = "https://www.roblox.com/asset/?id=16332156529",
		-- Hat = 123456,
		-- Shoulders = { 111111, 222222 },
		-- Back = 333333,
	},

	-- Outfit2 = { ... },
} :: { [string]: Outfit }

function CustomCharacter.GetRandomOutfit(): Outfit?
	local list: { Outfit } = {}
	for _, outfit in CustomCharacter.Outfits do
		table.insert(list, outfit)
	end
	if #list == 0 then return nil end
	return list[math.random(#list)]
end

return CustomCharacter
