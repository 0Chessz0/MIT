-- This script runs on each player's client. It monitors the distance
-- Client‑side script for chopping trees and displaying a health bar.
--
-- This script runs on each player's client. It monitors the distance
-- between the player's character and the available tree models in the map.
-- When the player is within a small radius of a tree's base, the script
-- automatically begins sending damage requests to the server at a fixed
-- interval (1 hit per second by default). A sleek health bar is
-- displayed on screen, showing the tree's remaining and maximum health.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
-- Wait for PlayerGui to be ready before creating UI elements.
local playerGui = player:WaitForChild("PlayerGui")

-- Require the same TreeData module used on the server to know max health values.
local TreeData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("TreeData"))

-- Remote events for communicating with the server.
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local damageEvent = remoteFolder:WaitForChild("TreeDamageEvent")
local updateEvent = remoteFolder:WaitForChild("TreeHealthUpdate")
local woodAwardEvent = remoteFolder:WaitForChild("WoodAwarded")

-- Reference to the trees folder in the workspace. All tree Models live here.
local treesFolder = workspace:WaitForChild("Map"):WaitForChild("Trees")

-- Pull the log logo asset ID from the Data/MiscLogos folder. This is
-- expected to be an IntValue containing an image id (e.g., 76732247442608).
local miscLogos = ReplicatedStorage:WaitForChild("Data"):WaitForChild("MiscLogos")
local logLogoValue = miscLogos:WaitForChild("LogLogo")

-- Formats large numbers into a human‑readable string (e.g. 12000 -> 12k).
local function formatNumber(n: number): string
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

-- Create the health bar GUI. We construct it programmatically so that
-- everything stays in one script; if you prefer a separate ScreenGui in
-- StarterGui you can move this into a .rbxl layout and adjust accordingly.
local gui = Instance.new("ScreenGui")
gui.Name = "TreeHealthGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Container for the health bar. Anchored in the middle bottom of the screen.
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

-- The inner fill bar representing current health. Its width is scaled
-- relative to the current health percentage.
local fillFrame = Instance.new("Frame")
fillFrame.Name = "Fill"
fillFrame.Size = UDim2.new(1, 0, 1, 0)
fillFrame.Position = UDim2.new(0, 0, 0, 0)
fillFrame.BackgroundColor3 = Color3.fromRGB(93, 182, 89)
fillFrame.BorderSizePixel = 0
fillFrame.Parent = barFrame

-- A text label that overlays the bar, showing the tree's name and health
-- values. It scales with the container size to remain legible.
local textLabel = Instance.new("TextLabel")
textLabel.Name = "HealthText"
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.Position = UDim2.new(0, 0, 0, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.Text = ""
textLabel.Parent = barFrame

-- Variables tracking the currently chopped tree and damage coroutine. We do not
-- declare explicit types here because they can interfere with runtime in
-- environments that do not support Luau type annotations.
local currentTree = nil --[[@as Model?]]
local damageThread = nil
local currentHealth = nil
local currentMaxHealth = nil

-- Utility to update the UI's fill bar and label.
local function updateBar()
    if currentTree and currentHealth and currentMaxHealth and currentMaxHealth > 0 then
        local pct = math.clamp(currentHealth / currentMaxHealth, 0, 1)
        fillFrame.Size = UDim2.new(pct, 0, 1, 0)
        textLabel.Text = string.format("%s: %d/%d", currentTree.Name, currentHealth, currentMaxHealth)
    end
end

-- Server notifies the client whenever a tree's health has changed. If
-- we are currently chopping that tree, update our local values and UI.
updateEvent.OnClientEvent:Connect(function(treeModel: Instance, health: number, maxHealth: number)
    if currentTree and treeModel == currentTree then
        currentHealth = health
        currentMaxHealth = maxHealth
        updateBar()
        print(string.format("[TreeClient] %s health: %d/%d", currentTree.Name, currentHealth, currentMaxHealth))
        -- When health drops to zero, hide the UI and stop the damage loop.
        if health <= 0 then
            barFrame.Visible = false
            currentTree = nil
            currentHealth = nil
            currentMaxHealth = nil
            damageThread = nil
        end
    end
end)

-- When the server awards wood to this client, display a brief pickup
-- notification. A small logo and text showing how many logs were earned
-- appear on the screen for a short time, then fade away. Multiple
-- notifications can appear concurrently.
woodAwardEvent.OnClientEvent:Connect(function(amount: number)
    -- Guard against non-number amounts
    if typeof(amount) ~= "number" or amount <= 0 then
        return
    end
    -- Compute a random starting position within the screen bounds (20% to 80%).
    local randomX = math.random(20, 80) / 100
    local randomY = math.random(20, 60) / 100
    -- Create a transparent container for the notification
    local notif = Instance.new("Frame")
    notif.Name = "WoodNotif"
    notif.BackgroundTransparency = 1
    notif.Size = UDim2.new(0, 0, 0, 0)
    notif.Position = UDim2.new(randomX, 0, randomY, 0)
    notif.AnchorPoint = Vector2.new(0.5, 0.5)
    notif.Parent = gui
    -- Icon
    local img = Instance.new("ImageLabel")
    img.Name = "Icon"
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(0, 24, 0, 24)
    img.Position = UDim2.new(0, 0, 0, 0)
    -- Convert IntValue to a rbxassetid string
    img.Image = "rbxassetid://" .. tostring(logLogoValue.Value)
    img.ImageTransparency = 0
    img.Parent = notif
    -- Text
    local label = Instance.new("TextLabel")
    label.Name = "Amount"
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(0, 0, 0, 0)
    label.TextColor3 = Color3.fromRGB(255, 102, 51)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextTransparency = 0
    label.Text = "+" .. formatNumber(amount) .. " logs"
    label.Parent = notif
    -- Define the initial and final sizes/positions for the tween
    -- Set fixed sizes so we don't rely on TextBounds (which may not be
    -- computed immediately). The container is wide enough to hold the
    -- icon and text; the text label fills the remaining space.
    notif.Size = UDim2.new(0, 140, 0, 32)
    img.Size = UDim2.new(0, 24, 0, 24)
    img.Position = UDim2.new(0, 0, 0.5, -12)
    label.Size = UDim2.new(1, -32, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    -- Animate the notification: it quickly pops in, moves downward and fades out
    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goalPos = notif.Position + UDim2.new(0, 0, 0.1, 0)
    -- Create tweens for position and transparency
    TweenService:Create(notif, tweenInfo, {Position = goalPos}):Play()
    TweenService:Create(img, tweenInfo, {ImageTransparency = 1}):Play()
    TweenService:Create(label, tweenInfo, {TextTransparency = 1}):Play()
    -- Cleanup after tween completion
    task.delay(1.2, function()
        notif:Destroy()
    end)
    print(string.format("[TreeClient] Received %d wood", amount))
end)

-- Start a coroutine that repeatedly signals the server to damage the current
-- tree once per second. The loop terminates automatically when
-- currentTree is changed to something else.
local function startDamaging(tree: Model)
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

-- Stops the current damaging coroutine by clearing state. The coroutine
-- checks the currentTree condition and will end itself shortly after.
local function stopDamaging()
    if currentTree then
        print(string.format("[TreeClient] Stopped chopping %s", currentTree.Name))
    end
    currentTree = nil
    damageThread = nil
    barFrame.Visible = false
end

-- Periodically scan the player's surroundings for the nearest tree within a
-- defined range. If a tree is found and we aren't already chopping it, begin
-- chopping and show the UI. If no tree is near, stop chopping.
while true do
    -- Ensure character and humanoid root part references are valid. The
    -- character may respawn, so we fetch these fresh each iteration.
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart") or nil
    if hrp then
        local nearest = nil
        local nearestDist = math.huge
        -- Iterate through all children in the Trees folder. Only consider
        -- models that have corresponding entries in TreeData.
        for _, tree in pairs(treesFolder:GetChildren()) do
            -- Only consider models that are defined in TreeData and not currently
            -- regrowing. We use an attribute "IsRegrowing" that the server sets
            -- when the tree is invisible.
            if tree:IsA("Model") and TreeData[tree.Name] and not tree:GetAttribute("IsRegrowing") then
                local cf, size = tree:GetBoundingBox()
                -- Determine horizontal radius based on the larger dimension of
                -- the tree footprint. Enforce a minimum radius of 4 studs.
                local radius = math.max(size.X, size.Z) / 2
                if radius < 4 then
                    radius = 4
                end
                -- Compute horizontal and vertical distances to the player.
                local dx = hrp.Position.X - cf.Position.X
                local dz = hrp.Position.Z - cf.Position.Z
                local horizontalDist = math.sqrt(dx * dx + dz * dz)
                local halfHeight = size.Y / 2
                local verticalDist = math.abs(hrp.Position.Y - cf.Position.Y)
                -- The player must be horizontally inside the radius plus a small
                -- buffer (1 stud) and vertically within the tree's height plus
                -- a buffer of 3 studs to account for uneven terrain.
                local horizontalLimit = radius + 1
                local verticalLimit = halfHeight + 3
                if horizontalDist <= horizontalLimit and verticalDist <= verticalLimit and horizontalDist < nearestDist then
                    nearestDist = horizontalDist
                    nearest = tree
                end
            end
        end
        if nearest and currentTree ~= nearest then
            -- Enter the radius of a new tree. Start chopping and show UI.
            currentTree = nearest
            local data = TreeData[nearest.Name]
            currentHealth = data.health
            currentMaxHealth = data.health
            updateBar()
            barFrame.Visible = true
            startDamaging(nearest)
        elseif not nearest and currentTree then
            -- Moved out of range of any tree. Stop chopping.
            stopDamaging()
        end
    else
        -- Character or HRP not available (e.g. during respawn). Hide UI and
        -- reset state.
        stopDamaging()
    end
    task.wait(0.2)
end