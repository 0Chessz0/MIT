--!strict
-- ServerScript to initialise leaderstats for each player based on configured DataStores.
-- When a player joins, this script creates a leaderstats folder (if one does not
-- already exist) and populates it with IntValues for each stat defined in the
-- StatConfig module. It then loads the current value from the corresponding
-- DataStore and assigns it to the IntValue.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the StatConfig module. We look for it inside ReplicatedStorage/Data.
local StatConfig = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("StatConfig"))

-- Function to load a single player's stats from DataStores and set up leaderstats.
local function setupLeaderstats(player: Player)
    -- Ensure the player has a leaderstats folder. Roblox will automatically
    -- replicate anything under this folder to all clients.
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    -- Iterate over each configured stat and set up an IntValue for it.
    for _, entry in ipairs(StatConfig) do
        local statName = entry.leaderstatName or entry.datastoreName
        -- Create or locate the IntValue in leaderstats.
        local statValue = leaderstats:FindFirstChild(statName)
        if not statValue then
            statValue = Instance.new("IntValue")
            statValue.Name = statName
            statValue.Parent = leaderstats
        end
        -- Load the current value from the DataStore. Wrap in pcall to handle errors.
        local dataStore = DataStoreService:GetDataStore(entry.datastoreName)
        local success, value = pcall(function()
            return dataStore:GetAsync(tostring(player.UserId))
        end)
        if success and typeof(value) == "number" then
            statValue.Value = value
        else
            -- If there was an error or the value is not a number, default to zero.
            statValue.Value = 0
        end
    end
end

-- Connect the setup function to PlayerAdded so it runs for each new player.
Players.PlayerAdded:Connect(setupLeaderstats)

-- Also run it for any players that are already in the game when the script runs.
for _, player in ipairs(Players:GetPlayers()) do
    -- Use a protected call in case this runs at a weird time during server startup.
    local ok, err = pcall(function()
        setupLeaderstats(player)
    end)
    if not ok then
        warn("[LeaderstatsInitializer] Error initialising stats for player", player, ":", err)
    end
end