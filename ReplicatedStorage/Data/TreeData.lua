-- modulescript
local TreeData = {}

TreeData["LeafDropChance"] ={
	chance = 100,
}

TreeData["TinyTree"] = {
	health = 3,
	respawnTime = 3,
	treeName = "TinyTree",
	woodAmount = 1
}

TreeData["SmallTree"] = {
	health = 5,
	respawnTime = 3,
	treeName = "SmallTree",
	woodAmount = 2
}

TreeData["BigTree"] = {
	health = 10,
	respawnTime = 3,
	treeName = "BigTree",
	woodAmount = 3
}
return TreeData
