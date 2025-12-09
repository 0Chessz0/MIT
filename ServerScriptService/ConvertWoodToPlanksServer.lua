local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local convertEvent = remoteFolder:FindFirstChild("ConvertWoodToPlanks")
if not convertEvent then
	convertEvent = Instance.new("RemoteEvent")
	convertEvent.Name = "ConvertWoodToPlanks"
	convertEvent.Parent = remoteFolder
end

local woodStore  = DataStoreService:GetDataStore("WoodStore")
local plankStore = DataStoreService:GetDataStore("PlankStore")

local function convertWood(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local woodStat  = leaderstats:FindFirstChild("Wood")
	local plankStat = leaderstats:FindFirstChild("Planks")
	if not woodStat or not plankStat then return end

	local currentWood = woodStat.Value or 0
	if currentWood <= 0 then return end

	local planksToAdd = currentWood / 100
	local userIdStr   = tostring(player.UserId)

	pcall(function()
		woodStore:IncrementAsync(userIdStr, -currentWood)
	end)
	pcall(function()
		plankStore:IncrementAsync(userIdStr, planksToAdd)
	end)

	woodStat.Value = 0
	plankStat.Value = plankStat.Value + planksToAdd

	local leafStat = leaderstats:FindFirstChild("Leafs") or leaderstats:FindFirstChild("Leaves") or leaderstats:FindFirstChild("Leaf")
	if leafStat then
		local currentLeafs = leafStat.Value or 0
		leafStat.Value = 0

		local leafStore = DataStoreService:GetDataStore("LeafStore")
		pcall(function()
			leafStore:IncrementAsync(userIdStr, -currentLeafs)
		end)
	end
end

convertEvent.OnServerEvent:Connect(convertWood)
