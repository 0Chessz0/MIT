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

	local currentWood = woodStat.Value
	local planksToAdd = math.floor(currentWood / 100)
	if planksToAdd <= 0 then return end

	local woodToRemove = planksToAdd * 100
	local userIdStr    = tostring(player.UserId)

	local woodSuccess, newWoodTotal = pcall(function()
		return woodStore:IncrementAsync(userIdStr, -woodToRemove)
	end)
	local planksSuccess, newPlankTotal = pcall(function()
		return plankStore:IncrementAsync(userIdStr, planksToAdd)
	end)

	if woodSuccess and typeof(newWoodTotal) == "number" then
		woodStat.Value = newWoodTotal
	else
		woodStat.Value = woodStat.Value - woodToRemove
	end
	if planksSuccess and typeof(newPlankTotal) == "number" then
		plankStat.Value = newPlankTotal
	else
		plankStat.Value = plankStat.Value + planksToAdd
	end
end

convertEvent.OnServerEvent:Connect(convertWood)