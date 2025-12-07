--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if RunService:IsClient() then
	warn("[LeaderstatsInitializer] This script must run on the server. Please place it in ServerScriptService.")
	return
end

local StatConfig = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("StatConfig"))

local function setupLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	for _, entry in ipairs(StatConfig) do
		local statName = entry.leaderstatName or entry.datastoreName
		local statValue = leaderstats:FindFirstChild(statName)
		if not statValue then
			statValue = Instance.new("IntValue")
			statValue.Name = statName
			statValue.Parent = leaderstats
		end
		local dataStore = DataStoreService:GetDataStore(entry.datastoreName)
		local success, value = pcall(function()
			return dataStore:GetAsync(tostring(player.UserId))
		end)
		if success and typeof(value) == "number" then
			statValue.Value = value
		else
			statValue.Value = 0
		end
	end
end

Players.PlayerAdded:Connect(setupLeaderstats)

for _, player in ipairs(Players:GetPlayers()) do
	local ok, err = pcall(function()
		setupLeaderstats(player)
	end)
	if not ok then
		warn("[LeaderstatsInitializer] Error initialising stats for player", player, ":", err)
	end
end