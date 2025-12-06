-- modulescript
local RS = game:GetService("ReplicatedStorage")
local DataFolder = RS:WaitForChild("Data")
local AxeLogos = DataFolder:WaitForChild("AxeLogos")

local AxeData = {
	WoodenAxe = {
		damage = 3,
		cost = 1,
		logo = AxeLogos:WaitForChild("WoodenAxe"),
		name = "Wooden Axe",
	},

	StoneAxe = {
		damage = 5,
		cost = 20,
		logo = AxeLogos:WaitForChild("StoneAxe"),
		name = "Stone Axe",
	},

	CopperAxe = {
		damage = 8,
		cost = 75,
		logo = AxeLogos:WaitForChild("CopperAxe"),
		name = "Copper Axe",
	},

	IronAxe = {
		damage = 12,
		cost = 200,
		logo = AxeLogos:WaitForChild("IronAxe"),
		name = "Iron Axe",
	},

	GoldenAxe = {
		damage = 15,
		cost = 500,
		logo = AxeLogos:WaitForChild("GoldenAxe"),
		name = "Golden Axe",
	},

	DiamondAxe = {
		damage = 20,
		cost = 1200,
		logo = AxeLogos:WaitForChild("DiamondAxe"),
		name = "Diamond Axe",
	},

	SapphireAxe = {
		damage = 25,
		cost = 2500,
		logo = AxeLogos:WaitForChild("SapphireAxe"),
		name = "Sapphire Axe",
	},

	RubyAxe = {
		damage = 30,
		cost = 5000,
		logo = AxeLogos:WaitForChild("RubyAxe"),
		name = "Ruby Axe",
	},

	EmeraldAxe = {
		damage = 40,
		cost = 9000,
		logo = AxeLogos:WaitForChild("EmeraldAxe"),
		name = "Emerald Axe",
	},

	ObsidianAxe = {
		damage = 55,
		cost = 15000,
		logo = AxeLogos:WaitForChild("ObsidianAxe"),
		name = "Obsidian Axe",
	},

	StellarAxe = { -- White/bright diorite-like
		damage = 75,
		cost = 25000,
		logo = AxeLogos:WaitForChild("StellarAxe"),
		name = "Stellar Axe",
	},

	MultiVerseAxe = { -- Galaxy-themed final axe
		damage = 100,
		cost = 50000,
		logo = AxeLogos:WaitForChild("MultiverseAxe"),
		name = "MultiVerse Axe",
	},
}

return AxeData
