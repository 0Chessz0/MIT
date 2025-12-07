--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local TreeData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("TreeData"))

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

local treeStates: { [Model]: {
	health: number,
	maxHealth: number,
	respawnTime: number,
	woodAmount: number,
	isRegrowing: boolean,
} } = {}

local lastHitTimes: { [Player]: { [Model]: number } } = {}

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

local function hideTree(tree: Model)
	for _, descendant in pairs(tree:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
		end
	end
end

local function showTree(tree: Model)
	for _, descendant in pairs(tree:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 0
			descendant.CanCollide = true
		end
	end
end

local DataStoreService = game:GetService("DataStoreService")
local woodStore = DataStoreService:GetDataStore("WoodStore")

local function awardWoodToPlayer(player: Player, amount: number)
	if amount <= 0 then return end
	local userId = player.UserId
	local success, newTotalOrErr = pcall(function()
		return woodStore:IncrementAsync(tostring(userId), amount)
	end)
	local newTotal
	if success then
		newTotal = newTotalOrErr
	else
		warn("[TreeSystem] Failed to award wood to", player.Name, ":", newTotalOrErr)
	end
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

damageEvent.OnServerEvent:Connect(function(player: Player, treeModel: Instance)
	if typeof(treeModel) ~= "Instance" or not treeModel:IsA("Model") then
		return
	end
	local state = treeStates[treeModel]
	if not state or state.isRegrowing then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
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
	local byPlayer = lastHitTimes[player]
	if not byPlayer then
		byPlayer = {}
		lastHitTimes[player] = byPlayer
	end
	local last = byPlayer[treeModel] or 0
	if now - last < 1 then
		return
	end
	byPlayer[treeModel] = now
	state.health -= 1
	updateEvent:FireAllClients(treeModel, state.health, state.maxHealth)
	if state.health <= 0 then
		state.isRegrowing = true
		treeModel:SetAttribute("IsRegrowing", true)
		hideTree(treeModel)
		awardWoodToPlayer(player, state.woodAmount)
		print(string.format("[TreeSystem] %s chopped down %s and gained %d wood", player.Name, treeModel.Name, state.woodAmount))
		for _, hitTable in pairs(lastHitTimes) do
			hitTable[treeModel] = nil
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