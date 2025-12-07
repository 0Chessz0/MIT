local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local TreeData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("TreeData"))

local AxeData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("AxeData"))

local leafDropChance = 0
do
	local leaf = TreeData["LeafDropChance"]
	if type(leaf) == "table" and type(leaf.chance) == "number" then
		leafDropChance = leaf.chance
	end
end

local treesFolder = Workspace:WaitForChild("Map"):WaitForChild("Trees")

local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local damageEvent = remoteFolder:FindFirstChild("TreeDamageEvent")
if not damageEvent then
	damageEvent = Instance.new("RemoteEvent")
	damageEvent.Name = "TreeDamageEvent"
	damageEvent.Parent = remoteFolder
end

local updateEvent = remoteFolder:FindFirstChild("TreeHealthUpdate")
if not updateEvent then
	updateEvent = Instance.new("RemoteEvent")
	updateEvent.Name = "TreeHealthUpdate"
	updateEvent.Parent = remoteFolder
end

local woodAwardEvent = remoteFolder:FindFirstChild("WoodAwarded")
if not woodAwardEvent then
	woodAwardEvent = Instance.new("RemoteEvent")
	woodAwardEvent.Name = "WoodAwarded"
	woodAwardEvent.Parent = remoteFolder
end

local leafAwardEvent = remoteFolder:FindFirstChild("LeafAwarded")
if not leafAwardEvent then
	leafAwardEvent = Instance.new("RemoteEvent")
	leafAwardEvent.Name = "LeafAwarded"
	leafAwardEvent.Parent = remoteFolder
end

local woodStore = DataStoreService:GetDataStore("WoodStore")
local leafStore = DataStoreService:GetDataStore("LeafStore")

local treeStates = {}
local lastHitTimes = {}

for _, treeModel in pairs(treesFolder:GetChildren()) do
	if treeModel:IsA("Model") then
		local data = TreeData[treeModel.Name]
		if data then
			treeStates[treeModel] = {
				health = data.health,
				maxHealth = data.health,
				respawnTime = data.respawnTime,
				woodAmount = data.woodAmount,
				isRegrowing = false,
			}
			treeModel:SetAttribute("IsRegrowing", false)
			updateEvent:FireAllClients(treeModel, data.health, data.health)
		end
	end
end

local function hideTree(tree)
	for _, d in pairs(tree:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CanCollide = false
		end
	end
end

local function showTree(tree)
	for _, d in pairs(tree:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 0
			d.CanCollide = true
		end
	end
end

local function awardWoodToPlayer(player, amount)
	if amount <= 0 then return end
	local userId = player.UserId
	local success, newTotal = pcall(function()
		return woodStore:IncrementAsync(tostring(userId), amount)
	end)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local woodStat = leaderstats:FindFirstChild("Wood")
	if not woodStat then
		woodStat = Instance.new("IntValue")
		woodStat.Name = "Wood"
		woodStat.Parent = leaderstats
	end
	if success and typeof(newTotal) == "number" then
		woodStat.Value = newTotal
	else
		woodStat.Value += amount
	end
	print(string.format("[TreeSystem] Awarded %d wood to %s. New total: %d", amount, player.Name, woodStat.Value))
	woodAwardEvent:FireClient(player, amount)
end

local function awardLeafToPlayer(player, amount)
	if amount <= 0 then return end
	local userId = player.UserId
	local success, newTotal = pcall(function()
		return leafStore:IncrementAsync(tostring(userId), amount)
	end)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local leafStat = leaderstats:FindFirstChild("Leaves")
	if not leafStat then
		leafStat = Instance.new("IntValue")
		leafStat.Name = "Leaves"
		leafStat.Parent = leaderstats
	end
	if success and typeof(newTotal) == "number" then
		leafStat.Value = newTotal
	else
		leafStat.Value += amount
	end
	leafAwardEvent:FireClient(player, amount)
	print(string.format("[TreeSystem] Awarded %d leaves to %s. New total: %d", amount, player.Name, leafStat.Value))
end

damageEvent.OnServerEvent:Connect(function(player, treeModel)
	if typeof(treeModel) ~= "Instance" or not treeModel:IsA("Model") then
		return
	end
	local state = treeStates[treeModel]
	if not state or state.isRegrowing then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local cf, size = treeModel:GetBoundingBox()
	local radius = math.max(size.X, size.Z) / 2
	if radius < 4 then
		radius = 4
	end
	local dx = root.Position.X - cf.Position.X
	local dz = root.Position.Z - cf.Position.Z
	local horizontalDist = math.sqrt(dx * dx + dz * dz)
	if horizontalDist > radius + 2 then
		return
	end
	local now = os.clock()
	local playerHits = lastHitTimes[player]
	if not playerHits then
		playerHits = {}
		lastHitTimes[player] = playerHits
	end
	local last = playerHits[treeModel] or 0
	if now - last < 1 then
		return
	end
	playerHits[treeModel] = now
	local damageAmount = 1
	
	-- Debug: Print all children in character
	print(string.format("[TreeSystem] Character children for %s:", player.Name))
	for _, child in pairs(character:GetChildren()) do
		print(string.format("  - %s (%s)", child.Name, child.ClassName))
	end
	
	local tool = character:FindFirstChildWhichIsA("Tool")
	if tool then
		print(string.format("[TreeSystem] Player has equipped tool: %s", tool.Name))
		local stats = AxeData[tool.Name]
		if stats and type(stats.damage) == "number" then
			damageAmount = stats.damage
			print(string.format("[TreeSystem] Using damage from AxeData: %d", damageAmount))
		else
			print(string.format("[TreeSystem] No AxeData found for tool: %s", tool.Name))
		end
	else
		print("[TreeSystem] No tool equipped, using default damage: 1")
	end
	state.health -= damageAmount
	updateEvent:FireAllClients(treeModel, state.health, state.maxHealth)
	if state.health <= 0 then
		state.isRegrowing = true
		treeModel:SetAttribute("IsRegrowing", true)
		hideTree(treeModel)
		awardWoodToPlayer(player, state.woodAmount)
		print(string.format("[TreeSystem] %s chopped down %s and gained %d wood", player.Name, treeModel.Name, state.woodAmount))
		if leafDropChance > 0 and math.random(1, 100) <= leafDropChance then
			awardLeafToPlayer(player, 1)
		end
		for _, tbl in pairs(lastHitTimes) do
			tbl[treeModel] = nil
		end
		task.delay(state.respawnTime, function()
			state.health = state.maxHealth
			state.isRegrowing = false
			showTree(treeModel)
			treeModel:SetAttribute("IsRegrowing", false)
			updateEvent:FireAllClients(treeModel, state.health, state.maxHealth)
			print(string.format("[TreeSystem] %s has respawned", treeModel.Name))
		end)
	end
end)