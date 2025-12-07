local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TreeData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("TreeData"))
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local damageEvent = remoteFolder:WaitForChild("TreeDamageEvent")
local updateEvent = remoteFolder:WaitForChild("TreeHealthUpdate")
local woodAwardEvent = remoteFolder:WaitForChild("WoodAwarded")
local leafAwardEvent = remoteFolder:WaitForChild("LeafAwarded")
local treesFolder = workspace:WaitForChild("Map"):WaitForChild("Trees")
local miscLogos = ReplicatedStorage:WaitForChild("Data"):WaitForChild("MiscLogos")
local logLogoValue = miscLogos:WaitForChild("LogLogo")
local leafLogoValue = miscLogos:WaitForChild("LeafLogo")

local function formatNumber(n)
    if n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.2fk", n / 1e3)
    else
        return tostring(n)
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "TreeHealthGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local barFrame = Instance.new("Frame")
barFrame.Name = "HealthContainer"
barFrame.Size = UDim2.new(0.3, 0, 0.05, 0)
barFrame.Position = UDim2.new(0.5, 0, 0.8, 0)
barFrame.AnchorPoint = Vector2.new(0.5, 0)
barFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
barFrame.BackgroundTransparency = 0.3
barFrame.BorderSizePixel = 0
barFrame.Visible = false
barFrame.Parent = gui

local fillFrame = Instance.new("Frame")
fillFrame.Name = "Fill"
fillFrame.Size = UDim2.new(1, 0, 1, 0)
fillFrame.Position = UDim2.new(0, 0, 0, 0)
fillFrame.BackgroundColor3 = Color3.fromRGB(93, 182, 89)
fillFrame.BorderSizePixel = 0
fillFrame.Parent = barFrame

local textLabel = Instance.new("TextLabel")
textLabel.Name = "HealthText"
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.Position = UDim2.new(0, 0, 0, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.Parent = barFrame

local currentTree = nil
local damageThread = nil
local currentHealth = nil
local currentMaxHealth = nil

local function updateBar()
    if currentTree and currentHealth and currentMaxHealth and currentMaxHealth > 0 then
        local pct = math.clamp(currentHealth / currentMaxHealth, 0, 1)
        fillFrame.Size = UDim2.new(pct, 0, 1, 0)
        textLabel.Text = string.format("%s: %d/%d", currentTree.Name, currentHealth, currentMaxHealth)
    end
end

updateEvent.OnClientEvent:Connect(function(treeModel, health, maxHealth)
    if currentTree and treeModel == currentTree then
        currentHealth = health
        currentMaxHealth = maxHealth
        updateBar()
        print(string.format("[TreeClient] %s health: %d/%d", currentTree.Name, currentHealth, currentMaxHealth))
        if health <= 0 then
            barFrame.Visible = false
            currentTree = nil
            currentHealth = nil
            currentMaxHealth = nil
            damageThread = nil
        end
    end
end)

local function createNotification(amount, imageId, textColor, labelText)
    if typeof(amount) ~= "number" or amount <= 0 then
        return
    end
    local randomX = math.random(20, 80) / 100
    local randomY = math.random(20, 60) / 100
    local notif = Instance.new("Frame")
    notif.BackgroundTransparency = 1
    notif.Size = UDim2.new(0, 140, 0, 32)
    notif.Position = UDim2.new(randomX, 0, randomY, 0)
    notif.AnchorPoint = Vector2.new(0.5, 0.5)
    notif.Parent = gui
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(0, 24, 0, 24)
    img.Position = UDim2.new(0, 0, 0.5, -12)
    img.Image = "rbxassetid://" .. tostring(imageId)
    img.Parent = notif
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 32, 0, 0)
    label.Size = UDim2.new(1, -32, 1, 0)
    label.TextColor3 = textColor
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = "+" .. formatNumber(amount) .. " " .. labelText
    label.Parent = notif
    local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goalPos = notif.Position + UDim2.new(0, 0, 0.1, 0)
    TweenService:Create(notif, info, {Position = goalPos}):Play()
    TweenService:Create(img, info, {ImageTransparency = 1}):Play()
    TweenService:Create(label, info, {TextTransparency = 1}):Play()
    task.delay(1.2, function()
        notif:Destroy()
    end)
end

woodAwardEvent.OnClientEvent:Connect(function(amount)
    createNotification(amount, logLogoValue.Value, Color3.fromRGB(255, 102, 51), "logs")
    print(string.format("[TreeClient] Received %d wood", amount))
end)

leafAwardEvent.OnClientEvent:Connect(function(amount)
    createNotification(amount, leafLogoValue.Value, Color3.fromRGB(102, 204, 102), "leaves")
    print(string.format("[TreeClient] Received %d leaves", amount))
end)

local function startDamaging(tree)
    if damageThread then
        return
    end
    damageThread = task.spawn(function()
        while currentTree == tree do
            damageEvent:FireServer(tree)
            task.wait(1)
        end
    end)
    print(string.format("[TreeClient] Started chopping %s", tree.Name))
end

local function stopDamaging()
    if currentTree then
        print(string.format("[TreeClient] Stopped chopping %s", currentTree.Name))
    end
    currentTree = nil
    damageThread = nil
    barFrame.Visible = false
end

while true do
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart") or nil
    if hrp then
        local nearest = nil
        local nearestDist = math.huge
        for _, tree in pairs(treesFolder:GetChildren()) do
            if tree:IsA("Model") and TreeData[tree.Name] and not tree:GetAttribute("IsRegrowing") then
                local cf, size = tree:GetBoundingBox()
                local radius = math.max(size.X, size.Z) / 2
                if radius < 4 then
                    radius = 4
                end
                local dx = hrp.Position.X - cf.Position.X
                local dz = hrp.Position.Z - cf.Position.Z
                local horizontalDist = math.sqrt(dx * dx + dz * dz)
                local halfHeight = size.Y / 2
                local verticalDist = math.abs(hrp.Position.Y - cf.Position.Y)
                local horizontalLimit = radius + 1
                local verticalLimit = halfHeight + 3
                if horizontalDist <= horizontalLimit and verticalDist <= verticalLimit and horizontalDist < nearestDist then
                    nearestDist = horizontalDist
                    nearest = tree
                end
            end
        end
        if nearest and currentTree ~= nearest then
            currentTree = nearest
            local data = TreeData[nearest.Name]
            currentHealth = data.health
            currentMaxHealth = data.health
            updateBar()
            barFrame.Visible = true
            startDamaging(nearest)
        elseif not nearest and currentTree then
            stopDamaging()
        end
    else
        stopDamaging()
    end
    task.wait(0.2)
end