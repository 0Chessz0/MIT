--!strict
-- Client-side script to display configured DataStore values above each player's head.
-- This script runs on every player's client. It listens for players joining
-- and for characters spawning, and attaches a BillboardGui to each character's
-- head. Each billboard contains a list of TextLabels, one per stat in the
-- StatConfig module, which update automatically when the corresponding
-- leaderstat values change. A small footer displays the player's name.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the stat configuration. We assume the module is placed in ReplicatedStorage/Data.
local StatConfig = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("StatConfig"))

-- Creates and attaches the overhead GUI to the given character.
local function createOverheadGui(character: Model, player: Player)
    -- Find the head of the character. If none exists, abort.
    local head = character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end
    -- Avoid adding multiple overhead GUIs to the same character.
    if head:FindFirstChild("OverheadStats") then
        return
    end
    -- Create the BillboardGui.
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OverheadStats"
    billboard.AlwaysOnTop = true
    -- Height: 20px per stat plus 16px for the user label.
    local statHeight = 20
    local usernameHeight = 16
    local statCount = #StatConfig
    local height = statHeight * statCount + usernameHeight
    billboard.Size = UDim2.new(0, 200, 0, height)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = head

    -- For each configured stat, create a TextLabel. We bind updates to the
    -- corresponding leaderstat value so the display stays in sync.
    for index, entry in ipairs(StatConfig) do
        local statName = entry.leaderstatName or entry.datastoreName
        -- Create the TextLabel for this stat.
        local label = Instance.new("TextLabel")
        label.Name = statName .. "Label"
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextScaled = true
        -- Position each label vertically based on its index.
        label.Size = UDim2.new(1, 0, 0, statHeight)
        label.Position = UDim2.new(0, 0, 0, (index - 1) * statHeight)
        label.Parent = billboard

        -- Function to update the label text from the leaderstat value.
        local function updateLabel()
            local leaderstats = player:FindFirstChild("leaderstats")
            local displayName = entry.displayName or statName:lower()
            if not leaderstats then
                label.Text = "0 " .. displayName
                return
            end
            local statValue = leaderstats:FindFirstChild(statName)
            if statValue and statValue:IsA("IntValue") then
                label.Text = tostring(statValue.Value) .. " " .. displayName
            else
                label.Text = "0 " .. displayName
            end
        end

        -- Function to connect value changed signals.
        local function connectToStat()
            local leaderstats = player:FindFirstChild("leaderstats")
            if not leaderstats then
                return
            end
            local statValue = leaderstats:FindFirstChild(statName)
            if statValue and statValue:IsA("IntValue") then
                statValue:GetPropertyChangedSignal("Value"):Connect(updateLabel)
            end
        end

        -- Update immediately and connect signals.
        updateLabel()
        connectToStat()

        -- Also listen for the leaderstats folder being added later.
        player.ChildAdded:Connect(function(child)
            if child.Name == "leaderstats" then
                updateLabel()
                connectToStat()
            end
        end)
    end

    -- Add a label for the player's display name and username.
    local userLabel = Instance.new("TextLabel")
    userLabel.Name = "UserLabel"
    userLabel.BackgroundTransparency = 1
    userLabel.TextColor3 = Color3.new(1, 1, 1)
    userLabel.TextStrokeTransparency = 0
    userLabel.Font = Enum.Font.SourceSans
    userLabel.TextScaled = false
    userLabel.TextSize = 12
    userLabel.TextXAlignment = Enum.TextXAlignment.Center
    userLabel.Size = UDim2.new(1, 0, 0, usernameHeight)
    userLabel.Position = UDim2.new(0, 0, 0, statHeight * statCount)
    userLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    userLabel.Parent = billboard
end

-- Called whenever a player's character spawns.
local function onCharacterAdded(player: Player, character: Model)
    task.defer(function()
        createOverheadGui(character, player)
    end)
end

-- Set up overhead GUIs for a single player and listen for their character spawns.
local function setupPlayer(player: Player)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end

-- Connect to existing players and to players that join in the future.
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)
