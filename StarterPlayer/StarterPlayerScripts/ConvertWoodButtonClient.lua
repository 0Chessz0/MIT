local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player = Players.LocalPlayer

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ConvertWoodToPlanks")

-- Helper function to safely locate the convert button in the world.
local function getButton()
	local ok, button = pcall(function()
		return workspace:WaitForChild("Map")
			:WaitForChild("Structures")
			:WaitForChild("TreeHouse")
			:WaitForChild("LightHouse")
			:WaitForChild("LeftScreen")
			:WaitForChild("WoodToPlanks")
			:WaitForChild("Main")
			:WaitForChild("Buttons")
			:WaitForChild("ConvertAllButton")
	end)
	return ok and button or nil
end

local button = getButton()
if not button then
	warn("ConvertAllButton not found in workspace")
	return
end

-- When the button is clicked, fire the server event to convert wood into planks.
if button:IsA("TextButton") then
	button.MouseButton1Click:Connect(function()
		remote:FireServer()
	end)
else
	warn("ConvertAllButton is not a TextButton")
end
