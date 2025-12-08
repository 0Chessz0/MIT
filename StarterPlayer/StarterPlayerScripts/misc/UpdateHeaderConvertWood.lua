local Players = game:GetService("Players")
local player = Players.LocalPlayer

local leaderstats = player:WaitForChild("leaderstats")
local woodStat = leaderstats:WaitForChild("Wood")

local structures = workspace:WaitForChild("Map"):WaitForChild("Structures")
local treehouse = structures:WaitForChild("TreeHouse")
local lighthouse = treehouse:WaitForChild("LightHouse")
local leftscreen = lighthouse:WaitForChild("LeftScreen")
local woodToPlanks = leftscreen:WaitForChild("WoodToPlanks")
local main = woodToPlanks:WaitForChild("Main")
local header = main:WaitForChild("Header")
local label = header:WaitForChild("HeaderLabel")

local function updateLabel()
	local woodCount = woodStat.Value
	local planks = math.floor(woodCount / 100)
	local convertibleWood = planks * 100

	if planks > 1 then
		label.Text = string.format("%d wood -> %d planks", convertibleWood, planks)
	elseif planks == 1 then
		label.Text = "100 wood -> 1 plank"
	else
		label.Text = "0 wood -> 0 planks"
	end
end

updateLabel()

woodStat.Changed:Connect(updateLabel)