--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatConfig = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("StatConfig"))

local function createOverheadGui(character: Model, player: Player)
    local head = character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end
    if head:FindFirstChild("OverheadStats") then
        return
    end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OverheadStats"
    billboard.AlwaysOnTop = true
    local statHeight = 20
    local usernameHeight = 16
    local statCount = #StatConfig
    local height = statHeight * statCount + usernameHeight
    billboard.Size = UDim2.new(0, 200, 0, height)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = head
    for index, entry in ipairs(StatConfig) do
        local statName = entry.leaderstatName or entry.datastoreName
        local label = Instance.new("TextLabel")
        label.Name = statName .. "Label"
        label.BackgroundTransparency = 1
        local color = entry.color or Color3.new(1, 1, 1)
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextScaled = true
        label.Size = UDim2.new(1, 0, 0, statHeight)
        label.Position = UDim2.new(0, 0, 0, (index - 1) * statHeight)
        label.Parent = billboard
        local function updateLabel()
            local leaderstats = player:FindFirstChild("leaderstats")
            local displayName = entry.displayName or string.lower(statName)
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
        updateLabel()
        connectToStat()
        player.ChildAdded:Connect(function(child)
            if child.Name == "leaderstats" then
                updateLabel()
                connectToStat()
            end
        end)
    end
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

local function onCharacterAdded(player: Player, character: Model)
    task.defer(function()
        createOverheadGui(character, player)
    end)
end

local function setupPlayer(player: Player)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end
Players.PlayerAdded:Connect(setupPlayer)