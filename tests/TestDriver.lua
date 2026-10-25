-- Server-only Studio fixtures. This entire folder is absent from release builds.
local RunService = game:GetService("RunService")
return function(context)
	assert(RunService:IsStudio(), "Test fixtures are Studio-only")
	local ok, args = pcall(function()
		return game:GetService("StudioTestService"):GetTestArgs()
	end)
	if ok and args == "GarageSix" then
		require(script.Parent.SixScenario)(context)
	end
	local endpoint = Instance.new("BindableFunction")
	endpoint.Name = "GarageTestDriver"
	endpoint.Parent = game:GetService("ServerStorage")
	endpoint.OnInvoke = function(player, action, patch)
		assert(player:GetAttribute("StudioMock"), "Cannot change a real profile")
		if action == "Snapshot" then
			return context.profiles:get(player)
		end
		if action == "Critical" then
			context.profiles.critical = patch == true
			context.profiles:notify(player)
			return true
		end
		if action == "SessionEnd" then
			context.profiles.sessions[player]:EndSession()
			return true
		end
		if action == "Patch" then
			return context.profiles:mutate(player, function(data)
				for _, key in ipairs({
					"coins",
					"parts",
					"items",
					"equipment",
					"vehicles",
					"tools",
					"quests",
					"collection",
					"cosmetics",
				}) do
					if patch[key] ~= nil then
						data[key] = patch[key]
					end
				end
				return true
			end, true)
		end
		error("Unknown test fixture action")
	end
end
