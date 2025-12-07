local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local axesFolder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Axes")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		
		local woodenAxe = axesFolder:FindFirstChild("WoodenAxe")
		if woodenAxe then
			local clone = woodenAxe:Clone()
			clone.Parent = player.Backpack
			print(string.format("[StarterToolGiver] Gave %s a WoodenAxe", player.Name))
		end
	end)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)

		local stoneAxe = axesFolder:FindFirstChild("StoneAxe")
		if stoneAxe then
			local clone = stoneAxe:Clone()
			clone.Parent = player.Backpack
			print(string.format("[StarterToolGiver] Gave %s a StoneAxe", player.Name))
		end
	end)
end)