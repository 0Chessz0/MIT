--!strict
-- Server-side script to manage chopping trees, respawning them and awarding wood.
--
-- This script wires up a RemoteEvent that clients can use to damage trees.
-- It reads per‑tree stats from the `TreeData` module in ReplicatedStorage and
-- maintains the current health and respawn state for each tree in the workspace.
-- When a tree's health reaches zero it becomes invisible for a period defined
-- in the module, drops a simple log part as a placeholder for wood, and is
-- respawned with full health after the respawn timer elapses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Reference the TreeData module which defines health and respawn times
local TreeData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("TreeData"))

-- Folder containing our tree models. Each child of this folder is expected to be
-- a Model whose name matches a key in TreeData. A "Base" part should be
-- located near the bottom of each tree and will be used to measure chopping
-- distance.
local treesFolder = Workspace:WaitForChild("Map"):WaitForChild("Trees")

-- Create RemoteEvents on the fly if they don't already exist. These events
-- will live in ReplicatedStorage so both server and client can access them.
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "Remotes"
    remoteFolder.Parent = ReplicatedStorage
end

-- Client fires this to damage a tree.
local damageEvent = remoteFolder:FindFirstChild("TreeDamageEvent")
if not damageEvent then
    damageEvent = Instance.new("RemoteEvent")
    damageEvent.Name = "TreeDamageEvent"
    damageEvent.Parent = remoteFolder
end

-- Server fires this to notify clients of a tree's current and maximum health.
local updateEvent = remoteFolder:FindFirstChild("TreeHealthUpdate")
if not updateEvent then
    updateEvent = Instance.new("RemoteEvent")
    updateEvent.Name = "TreeHealthUpdate"
    updateEvent.Parent = remoteFolder
end

-- We keep track of state for each tree model here. The key is the Model
-- instance; the value contains current and max health, respawn time and a
-- boolean to denote if the tree is currently respawning.
local treeStates: { [Model]: {
    health: number,
    maxHealth: number,
    respawnTime: number,
    woodAmount: number,
    isRegrowing: boolean,
} } = {}

-- Initialise tree state based off of TreeData. Only models present in the
-- folder and defined in the module will be tracked.
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
            -- Set an attribute on the tree to indicate whether it is regrowing.
            treeModel:SetAttribute("IsRegrowing", false)
            -- Fire an initial update to clients so the health bar shows full.
            updateEvent:FireAllClients(treeModel, data.health, data.health)
        end
    end
end

-- Helper function to hide a tree by setting transparency and disabling
-- collisions. We leave the model itself in place so our state table keys
-- remain valid.
local function hideTree(tree: Model)
    for _, descendant in pairs(tree:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Transparency = 1
            descendant.CanCollide = false
        end
    end
end

-- Helper function to show a tree (reverse of hideTree).
local function showTree(tree: Model)
    for _, descendant in pairs(tree:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Transparency = 0
            descendant.CanCollide = true
        end
    end
end

-- Instead of spawning physical logs when a tree is felled, we award
-- wood directly to the player via a DataStore. This function increments
-- the player's stored wood count by the specified amount. A leaderstats
-- folder can also be used to show the current wood amount in the UI.
-- For debugging, we print the new wood total after each increment.
local DataStoreService = game:GetService("DataStoreService")
local woodStore = DataStoreService:GetDataStore("WoodStore")

local function awardWoodToPlayer(player: Player, amount: number)
    if amount <= 0 then return end
    local userId = player.UserId
    -- Increment the player's wood total in the DataStore. We wrap the
    -- call in pcall to handle possible errors without crashing.
    local success, newTotalOrErr = pcall(function()
        return woodStore:IncrementAsync(tostring(userId), amount)
    end)
    local newTotal
    if success then
        newTotal = newTotalOrErr
    else
        warn("[TreeSystem] Failed to award wood to", player.Name, ":", newTotalOrErr)
    end
    -- Update a leaderstats folder on the player if present. This allows
    -- players to see their current wood in-game.
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
    -- If DataStore update succeeded, set leaderstat to new total. Otherwise,
    -- fall back to adding to leaderstat locally.
    if success and typeof(newTotal) == "number" then
        woodStat.Value = newTotal
    else
        woodStat.Value += amount
    end
    print(string.format("[TreeSystem] Awarded %d wood to %s. New total: %d", amount, player.Name, woodStat.Value))
end

-- Called when a client requests to damage a tree. We validate the player and
-- ensure they are within a reasonable distance of the tree's base before
-- applying damage. This protects against exploits where a player might
-- attempt to chop trees from across the map.
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
    -- Determine whether the player is close enough to damage the tree. We
    -- compute this using the tree's bounding box rather than relying on a
    -- specific "Base" part, which may not always exist. We take only
    -- horizontal distance into account to avoid issues when the tree is tall.
    local cf, size = treeModel:GetBoundingBox()
    -- Compute a radius based on the larger of the X/Z extents plus a small
    -- buffer so the player doesn't have to stand exactly at the centre. If
    -- bounding boxes are unexpectedly small, fall back to a default radius.
    local radius = math.max(size.X, size.Z) / 2
    if radius < 4 then
        radius = 4 -- a sane minimum radius so tiny trees can still be hit
    end
    -- Horizontal (XZ) distance between player and tree.
    local dx = root.Position.X - cf.Position.X
    local dz = root.Position.Z - cf.Position.Z
    local horizontalDist = math.sqrt(dx * dx + dz * dz)
    if horizontalDist > radius + 2 then -- add extra buffer of 2 studs
        return
    end
    -- Subtract one health point. Feel free to adjust this value in the
    -- client (e.g. axes could send different damage amounts).
    state.health -= 1
    -- Inform all clients about the new health value.
    updateEvent:FireAllClients(treeModel, state.health, state.maxHealth)
    -- If the tree's health has depleted, handle felling and respawn logic.
    if state.health <= 0 then
        state.isRegrowing = true
        -- Mark this tree as regrowing so clients skip it during detection.
        treeModel:SetAttribute("IsRegrowing", true)
        hideTree(treeModel)
        -- Award wood directly to the player instead of spawning physical logs.
        awardWoodToPlayer(player, state.woodAmount)
        -- Log for debugging
        print(string.format("[TreeSystem] %s chopped down %s and gained %d wood", player.Name, treeModel.Name, state.woodAmount))
        -- Use task.delay to schedule the respawn without blocking the event
        task.delay(state.respawnTime, function()
            state.health = state.maxHealth
            state.isRegrowing = false
            showTree(treeModel)
            -- Clear the regrowing attribute so clients can detect the tree again
            treeModel:SetAttribute("IsRegrowing", false)
            updateEvent:FireAllClients(treeModel, state.health, state.maxHealth)
            print(string.format("[TreeSystem] %s has respawned", treeModel.Name))
        end)
    end
end)