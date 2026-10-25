local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Garage")
local Config = require(Shared.Config)
local Schema = require(Shared.Schema)
local Rules = require(Shared.Rules).new(Config)
local RateLimiter = require(Shared.RateLimiter)
local RequestGuard = require(Shared.RequestGuard)
local CarryVisual = require(script.Parent.CarryVisual)
local Profiles = require(script.Parent.Profiles)
local World = require(script.Parent.World)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = Shared
local request = Instance.new("RemoteEvent")
request.Name = "Request"
request.Parent = remotes
local state = Instance.new("RemoteEvent")
state.Name = "State"
state.Parent = remotes
local notice = Instance.new("RemoteEvent")
notice.Name = "Notice"
notice.Parent = remotes
local openPanel = Instance.new("RemoteEvent")
openPanel.Name = "Open"
openPanel.Parent = remotes
local limiter = RateLimiter.new(10, 16)
local actionLimiter = RateLimiter.new(2, 3)
local cargo = {}
local tutorialModels = {}
local visuals = {}
local random = Random.new()
local expansion

World:build()
workspace:SetAttribute("GarageBuild", Config.Version)
workspace:SetAttribute("Prototype", Config.Prototype)

local function id()
	return HttpService:GenerateGUID(false)
end
local function push(player)
	local data = Profiles:get(player)
	if not data or player.Parent ~= Players then
		return
	end
	local payload = Schema.clone(data)
	payload.cargo = Schema.clone(cargo[player] or {})
	payload.capacity = Rules:capacity(data, false)
	payload.critical = Profiles.critical
	payload.prototype = Config.Prototype
	payload.cargoCapacity = 1
	payload.mock = player:GetAttribute("StudioMock")
	if expansion then
		expansion:decorateState(player, payload)
	end
	CarryVisual:update(player, payload.cargo[1], expansion and expansion.vehicles:hasVehicleCargo(player))
	state:FireClient(player, payload)
end
Profiles:onChange(function(player)
	if expansion then
		expansion:onChanged(player)
	end
	push(player)
end)

if not Config.Prototype then
	expansion = require(script.Parent.Expansion).start({
		world = World,
		profiles = Profiles,
		rules = Rules,
		cargo = cargo,
		remotes = remotes,
		push = push,
		notice = notice,
		allowRequest = function(player)
			return limiter:allow(player, os.clock())
		end,
	})
end

local function report(player, ok, reason)
	if not ok then
		notice:FireClient(player, reason or "invalid_action")
		if expansion and reason == "storage_full" then
			expansion.telemetry:blocked(player)
		end
	end
	push(player)
	return ok
end

local function validString(value)
	return type(value) == "string" and #value > 0 and #value <= 64
end

local function collect(player, spot, personal)
	if not limiter:allow(player, os.clock()) then
		return
	end
	local data = Profiles:get(player)
	if not data or Profiles.critical then
		return report(player, false, "save_unavailable")
	end
	if personal and personal ~= player then
		return
	end
	if not spot.model or not spot.model.Parent or not World:near(player, spot.model.PrimaryPart) then
		return report(player, false, "too_far")
	end
	if expansion then
		local allowed, reason = expansion.vehicles:canCollect(player)
		if not allowed then
			return report(player, false, reason)
		end
		expansion.vehicles:claimCargo(player)
	elseif #cargo[player] >= 1 then
		return report(player, false, "cargo_full")
	end
	-- Claim and cargo insertion are synchronous: a second Triggered cannot claim this ID.
	local model = spot.model
	spot.model = nil
	table.insert(
		cargo[player],
		{ id = spot.id, kind = spot.kind, stage = 0, tutorial = personal and "first" or nil }
	)
	spot.readyAt = os.clock() + Config.RespawnSeconds
	model:Destroy()
	if expansion then
		expansion:touch(player)
	end
	push(player)
	notice:FireClient(player, "found_" .. spot.kind)
end

local function spawnTutorial(player)
	local data = Profiles:get(player)
	local garage = World:getGarage(player)
	if not data or not garage or data.collection.toycar then
		return
	end
	for _, item in ipairs(data.items) do
		if item.kind == "toycar" then
			return
		end
	end
	for _, item in ipairs(cargo[player] or {}) do
		if item.kind == "toycar" then
			return
		end
	end
	if tutorialModels[player] and tutorialModels[player].model and tutorialModels[player].model.Parent then
		return
	end
	local model, primary = World:container(garage.origin + Vector3.new(0, 2.8, -32), "toy")
	model.Name = "YourFirstFind_" .. player.UserId
	local spot = { model = model, id = id(), kind = "toycar" }
	tutorialModels[player] = spot
	World.prompt(primary, "Collect", "НАЙТИ / SEARCH", function(who)
		collect(who, spot, player)
	end)
end

local function showItem(player, itemId)
	local data = Profiles:get(player)
	local garage = World:getGarage(player)
	local item = data and Rules:find(data, itemId)
	if not item or not garage then
		return
	end
	if visuals[player] then
		visuals[player]:Destroy()
	end
	local rgb = Config.Items[item.kind].color
	local color = item.stage == 0 and Color3.fromRGB(100, 88, 76) or Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	local visual = World:itemVisual(item.kind, garage.bench.Position + Vector3.new(0, 3, 0), color)
	visual.Parent = garage.model
	visuals[player] = visual
end

local function at(player, key)
	local garage = World:getGarage(player)
	return garage and World:near(player, garage[key])
end

local function dispatch(player, action, args)
	if not limiter:allow(player, os.clock()) then
		return
	end
	if not RequestGuard.valid(action, args) then
		return
	end
	args = args or {}
	if action == "Sync" then
		push(player)
		return
	end
	if action == "Language" then
		if args.language ~= "ru" and args.language ~= "en" and args.language ~= "auto" then
			return
		end
		report(
			player,
			Profiles:mutate(player, function(data)
				data.language = args.language
				return true
			end, true)
		)
		return
	end
	if not actionLimiter:allow(tostring(player.UserId) .. ":" .. action, os.clock()) then
		return
	end
	if expansion then
		expansion:touch(player)
		if expansion:handle(player, action, args) then
			return
		end
	end
	if action == "Deposit" then
		if not at(player, "depot") then
			return report(player, false, "too_far")
		end
		local delivered = cargo[player]
		local storagePass = expansion and expansion.commerce:owns(player, "storage") or false
		if expansion and not expansion.vehicles:canUnload(player, World:getGarage(player).depot.Position) then
			return report(player, false, "bring_vehicle")
		end
		local ok, reason = Profiles:mutate(player, function(data)
			if #delivered == 0 and expansion and data.quests.nightVisited and not data.quests.nightDone then
				expansion:delivered(player, data, 0)
				return true
			end
			local deposited, why = Rules:deposit(data, delivered, storagePass)
			if deposited and expansion then
				expansion:delivered(player, data, #delivered)
			end
			return deposited, why
		end)
		if ok then
			cargo[player] = {}
			if expansion then
				expansion.vehicles:clearCargo(player)
			end
			notice:FireClient(player, "deposited")
		end
		report(player, ok, reason)
	elseif action == "Advance" then
		if not at(player, "bench") then
			return report(player, false, "too_far")
		end
		report(
			player,
			Profiles:mutate(player, function(data)
				return Rules:advance(data, id())
			end, true)
		)
	elseif action == "BuyPart" then
		if not at(player, "shop") then
			return report(player, false, "too_far")
		end
		report(
			player,
			Profiles:mutate(player, function(data)
				return Rules:buyPart(data)
			end)
		)
	elseif action == "Upgrade" then
		if not at(player, "shop") or not validString(args.key) then
			return report(player, false, "too_far")
		end
		report(
			player,
			Profiles:mutate(player, function(data)
				return Rules:upgrade(data, args.key)
			end, true)
		)
	elseif action == "Select" then
		if at(player, "bench") and validString(args.id) then
			showItem(player, args.id)
		end
	elseif
		action == "BeginRepair"
		or action == "FinishRepair"
		or action == "Sell"
		or action == "Dismantle"
	then
		if not at(player, "bench") then
			return report(player, false, "too_far")
		end
		if not validString(args.id) then
			return
		end
		local ok, reason = Profiles:mutate(player, function(data)
			if action == "BeginRepair" then
				return Rules:beginRepair(data, args.id, workspace:GetServerTimeNow())
			elseif action == "FinishRepair" then
				return Rules:finishRepair(data, args.id, workspace:GetServerTimeNow())
			elseif action == "Sell" then
				return Rules:sell(data, args.id)
			else
				return Rules:dismantle(data, args.id)
			end
		end, action == "FinishRepair")
		if ok then
			if expansion and action == "BeginRepair" then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					expansion.night:noise(root.Position, 45, player.UserId)
				end
			end
			if action == "Sell" or action == "Dismantle" then
				if visuals[player] then
					visuals[player]:Destroy()
					visuals[player] = nil
				end
			else
				showItem(player, args.id)
			end
		end
		report(player, ok, reason)
	end
end
request.OnServerEvent:Connect(dispatch)

local testFolder = game:GetService("ServerStorage"):FindFirstChild("GarageTests")
if game:GetService("RunService"):IsStudio() and testFolder and testFolder:FindFirstChild("TestDriver") then
	require(testFolder.TestDriver)({ profiles = Profiles, world = World, cargo = cargo })
end

for _, garage in ipairs(World.garages) do
	World.prompt(garage.depot, "Deposit", "СДАТЬ ГРУЗ / UNLOAD", function(player)
		if garage.owner == player then
			dispatch(player, "Deposit", {})
		end
	end)
	World.prompt(garage.bench, "Workbench", "ВЕРСТАК / WORKBENCH", function(player)
		if
			garage.owner == player
			and World:near(player, garage.bench)
			and limiter:allow(player, os.clock())
		then
			push(player)
			openPanel:FireClient(player, "workbench")
		end
	end)
	World.prompt(garage.shop, "Shop", "МАГАЗИН / SHOP", function(player)
		if
			garage.owner == player
			and World:near(player, garage.shop)
			and limiter:allow(player, os.clock())
		then
			push(player)
			openPanel:FireClient(player, "shop")
		end
	end)
end

local function spawnFind(spot)
	local roll = random:NextNumber()
	local kind = roll < 0.7 and Config.PrototypeItems[random:NextInteger(1, 3)] or "radio"
	if expansion then
		local first = expansion.night.night and 0.4 or 0.6
		local second = expansion.night.night and 0.8 or 0.9
		local tier = roll < first and 1 or (roll < second and 2 or 3)
		local options = {}
		for _, key in ipairs(Config.CatalogOrder) do
			if Config.Items[key].tier == tier then
				table.insert(options, key)
			end
		end
		kind = options[random:NextInteger(1, #options)]
	end
	spot.kind = kind
	spot.id = id()
	local model, primary = World:container(spot.position, Config.Items[kind].category)
	spot.model = model
	World.prompt(primary, "Collect", "НАЙТИ / SEARCH", function(player)
		collect(player, spot)
	end)
end
for _, spot in ipairs(World.spots) do
	spawnFind(spot)
end

local function characterReady(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 15)
	local garage = World:getGarage(player)
	if root and garage then
		character:PivotTo(CFrame.new(garage.origin + Vector3.new(0, 5, -10)))
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			cargo[player] = {}
			if expansion then
				expansion.vehicles:stop(player)
			end
			push(player)
			task.delay(5, function()
				spawnTutorial(player)
			end)
		end)
	end
	spawnTutorial(player)
	push(player)
end

local function joined(player)
	cargo[player] = {}
	if not Profiles:load(player) then
		return
	end
	local garage = World:assign(player)
	if not garage then
		player:Kick("Сервер заполнен. / Server full.")
		return
	end
	player.CharacterAdded:Connect(function(character)
		characterReady(player, character)
	end)
	if player.Character then
		characterReady(player, player.Character)
	end
	if expansion then
		expansion:onChanged(player)
		task.spawn(function()
			expansion.commerce:refresh(player)
		end)
	end
	push(player)
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
	if expansion then
		expansion:release(player)
	end
	cargo[player] = nil
	CarryVisual:clear(player)
	local tutorial = tutorialModels[player]
	if tutorial and tutorial.model then
		tutorial.model:Destroy()
	end
	tutorialModels[player] = nil
	if visuals[player] then
		visuals[player]:Destroy()
		visuals[player] = nil
	end
	World:release(player)
	limiter:remove(player)
	for key in pairs(actionLimiter.buckets) do
		if string.sub(key, 1, #tostring(player.UserId) + 1) == tostring(player.UserId) .. ":" then
			actionLimiter:remove(key)
		end
	end
	Profiles:release(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(joined, player)
end

task.spawn(function()
	while true do
		task.wait(1)
		for _, spot in ipairs(World.spots) do
			if not spot.model and os.clock() >= spot.readyAt then
				spawnFind(spot)
			end
		end
	end
end)

print("[Garage] " .. Config.Version .. " ready; profiles use Mock in Studio.")
