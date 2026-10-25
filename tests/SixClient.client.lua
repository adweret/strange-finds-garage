-- Cloned only by the Studio integration fixture, never included in release.
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Garage"):WaitForChild("Remotes")
local channel = remotes:WaitForChild("SixQA")
channel.OnClientEvent:Connect(function(action, target)
	if action == "Sell" then
		remotes.Request:FireServer("Sell", { id = "six_owned" })
		task.wait(0.7)
		remotes.Request:FireServer("Sell", { id = "six_owned" })
	elseif action == "Collect" then
		local prompt = target and target:WaitForChild("Collect", 10)
		if prompt then
			prompt:InputHoldBegin()
			task.wait(0.6)
			if prompt.Parent then
				prompt:InputHoldEnd()
			end
		end
	elseif action == "Deposit" then
		remotes.Request:FireServer("Deposit")
		task.wait(0.7)
		remotes.Request:FireServer("Deposit")
	end
	channel:FireServer("Done", action)
end)
channel:FireServer("Ready")
