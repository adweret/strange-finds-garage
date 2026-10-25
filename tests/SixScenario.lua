return function(context)
	local Players = game:GetService("Players")
	local service = game:GetService("StudioTestService")
	local channel = Instance.new("RemoteEvent")
	channel.Name = "SixQA"
	channel.Parent = game.ReplicatedStorage.Garage.Remotes
	local ready = {}
	local completed = {}
	channel.OnServerEvent:Connect(function(player, action)
		if action == "Ready" then
			ready[player] = true
		end
	end)
	channel.OnServerEvent:Connect(function(player, action, phase)
		if action == "Done" and type(phase) == "string" then
			completed[phase] = completed[phase] or {}
			completed[phase][player] = true
		end
	end)
	local function waitForClients(phase, targets)
		local deadline = os.clock() + 20
		repeat
			local all = true
			for _, player in ipairs(targets) do
				if not (completed[phase] and completed[phase][player]) then
					all = false
				end
			end
			if all then
				return
			end
			task.wait(0.1)
		until os.clock() >= deadline
		error("Client phase timed out: " .. phase)
	end
	task.spawn(function()
		local ok, result = pcall(function()
			local deadline = os.clock() + 75
			local cloned = {}
			repeat
				for _, player in ipairs(Players:GetPlayers()) do
					if
						context.profiles:get(player)
						and context.world:getGarage(player)
						and not cloned[player]
					then
						cloned[player] = true
						local client = script.Parent.SixClient:Clone()
						client.Parent = player:WaitForChild("PlayerGui")
					end
				end
				local count = 0
				for player in pairs(ready) do
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						count += 1
					end
				end
				if count == 6 then
					break
				end
				task.wait(0.25)
			until os.clock() >= deadline
			assert(#Players:GetPlayers() == 6, "Six clients did not join")
			local players = Players:GetPlayers()
			table.sort(players, function(a, b)
				return a.UserId < b.UserId
			end)
			local plots = {}
			for _, player in ipairs(players) do
				assert(ready[player], "A client fixture did not initialize")
				local garage = context.world:getGarage(player)
				assert(garage and not plots[garage], "Garage ownership collision")
				plots[garage] = true
				assert(player:GetAttribute("StudioMock"), "Must use Mock profiles")
			end
			local owner = players[1]
			local bench = context.world:getGarage(owner).bench
			assert(context.profiles:mutate(owner, function(data)
				data.items = { { id = "six_owned", kind = "lamp", stage = 3 } }
				return true
			end))
			for index, player in ipairs(players) do
				player.Character:PivotTo(CFrame.new(bench.Position + Vector3.new((index - 3) * 1.5, 3, -6)))
			end
			task.wait(2)
			channel:FireAllClients("Sell")
			waitForClients("Sell", players)
			task.wait(1)
			for _, player in ipairs(players) do
				local actual = context.profiles:get(player).coins
				local expected = player == owner and 95 or 50
				assert(
					actual == expected,
					string.format(
						"Sale mismatch: user=%d actual=%d expected=%d distance=%.2f",
						player.UserId,
						actual,
						expected,
						(player.Character.HumanoidRootPart.Position - bench.Position).Magnitude
					)
				)
			end
			local spot = context.world.spots[1]
			local primary = spot.model.PrimaryPart
			for index, player in ipairs(players) do
				player.Character:PivotTo(CFrame.new(primary.Position + Vector3.new((index - 3) * 1.4, 3, -5)))
			end
			task.wait(3)
			channel:FireAllClients("Collect", primary)
			waitForClients("Collect", players)
			task.wait(1)
			local total, winner = 0, nil
			for _, player in ipairs(players) do
				total += #context.cargo[player]
				if #context.cargo[player] > 0 then
					winner = player
				end
			end
			assert(total == 1 and winner, "Shared find was duplicated or never claimed: " .. total)
			local before = #context.profiles:get(winner).items
			winner.Character:PivotTo(
				CFrame.new(context.world:getGarage(winner).depot.Position + Vector3.new(0, 3, -4))
			)
			task.wait(1)
			channel:FireClient(winner, "Deposit")
			waitForClients("Deposit", { winner })
			task.wait(1)
			assert(
				#context.cargo[winner] == 0 and #context.profiles:get(winner).items == before + 1,
				"Deposit duplicated or lost cargo"
			)
			return {
				ok = true,
				clients = 6,
				checks = {
					"Unique garages",
					"Mock profile per client",
					"Foreign and repeated sales rejected",
					"One winner for shared find",
					"Deposit exactly once",
				},
				unit = require(script.Parent.Run)(),
			}
		end)
		local outcome = ok and result or { ok = false, error = tostring(result) }
		print("[Garage Six QA] " .. game:GetService("HttpService"):JSONEncode(outcome))
		service:EndTest(outcome)
	end)
end
