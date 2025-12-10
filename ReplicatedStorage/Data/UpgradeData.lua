-- ModuleScript
local UpgradeData = {

	Wood = {
		Name = "Wood Multiplier", -- name
		Logo = nil, -- logo

		UpgradeLimit = 1000, -- max amount of upgrades
		StartingAmount = 3, -- starting price
		PriceMulti = 1.333333, -- by how much the price should multiply everytime
		BoostMulti = 2, -- by how much the multi increases every upgrade

		GrowthBoost = true, --true or false
		GrowthMulti = 2, -- by how much it doubles the multi
		GrowthEvery = 25, -- doubles the multipler (mutli)
		
		Order = nil, -- order in gui
	},

	Damage = {
		Name = "Damage Multiplier",
		Logo = nil,

		UpgradeLimit = 1000,
		StartingAmount = 3,
		PriceMulti = 1.333333,
		BoostMulti = 2,

		GrowthBoost = true,
		GrowthMulti = 2,
		GrowthEvery = 25,
		
		Order = nil,
	},

	Leafs = {
		Name = "Leaf Multiplier",
		Logo = nil,

		UpgradeLimit = 1000,
		StartingAmount = 3,
		PriceMulti = 1.333333,
		BoostMulti = 2,

		GrowthBoost = true,
		GrowthMulti = 2,
		GrowthEvery = 25,
		
		Order = nil,
	},

	Planks = {
		Name = "Plank Multiplier",
		Logo = nil,

		UpgradeLimit = 1000,
		StartingAmount = 3,
		PriceMulti = 1.333333,
		BoostMulti = 2,

		GrowthBoost = true,
		GrowthMulti = 2,
		GrowthEvery = 25,
		
		Order = nil,
	},
}

return UpgradeData