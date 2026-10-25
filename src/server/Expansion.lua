local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage").Garage
local Config = require(Shared.Config)
local AdvancedRules = require(Shared.AdvancedRules)
local RateLimiter = require(Shared.RateLimiter)
local ExpansionWorld = require(script.Parent.ExpansionWorld)
local Vehicles = require(script.Parent.Vehicles)
local Night = require(script.Parent.Night)
local Commerce = require(script.Parent.Commerce)
local Telemetry = require(script.Parent.Telemetry)
local Expansion = {}
Expansion.__index = Expansion

function Expansion.start(context)
	local self = setmetatable({ context = context, cooldowns = {}, activeRobots = {} }, Expansion)
	self.advanced = AdvancedRules.new(Config, context.rules)
	ExpansionWorld:build(context.world)
	self.map = ExpansionWorld
	self.telemetry = Telemetry.new(context.profiles, function(player, data)
		return context.rules:capacity(data, self.commerce:owns(player, "storage"))
	end)
	self.vehicles = Vehicles.new(context.world, function(player)
		return context.cargo[player] or {}
	end)
	self.vehicles.onStopped = function(player)
		if player.Parent == Players then
			context.notice:FireClient(player, "vehicle_stopped")
		end
	end
	self.commerce = Commerce.new(Config, function(player)
		local data = context.profiles:get(player)
		if data then
			context.world:applyAppearance(player, data, self.commerce:owns(player, "decor"))
		end
		context.push(player)
	end)
	self.night = Night.new(context.world, self.map, context.profiles, function(player)
		context.cargo[player] = {}
		self.vehicles:stop(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
		end
		local garage = context.world:getGarage(player)
		task.delay(0.15, function()
			if garage and player.Character == character then
				character:PivotTo(CFrame.new(garage.origin + Vector3.new(0, 5, -10)))
			end
		end)
		context.notice:FireClient(player, "captured")
		self.telemetry:emit(player, "CaughtAtNight")
		context.push(player)
	end)
	self.vehicles.onNoise = function(player, position)
		self.night:noise(position, 80, player.UserId)
	end
	self.signal = Instance.new("RemoteEvent")
	self.signal.Name = "Signal"
	self.signal.Parent = context.remotes
	local drive = Instance.new("RemoteEvent")
	drive.Name = "Drive"
	drive.Parent = context.remotes
	local driveLimit = RateLimiter.new(12, 16)
	drive.OnServerEvent:Connect(function(player, throttle, steer)
		if not driveLimit:allow(player, os.clock()) then
			return
		end
		if
			type(throttle) ~= "number"
			or type(steer) ~= "number"
			or throttle ~= throttle
			or steer ~= steer
			or math.abs(throttle) > 1
			or math.abs(steer) > 1
		then
			return
		end
		self.vehicles:drive(player, throttle, steer)
	end)
	self.driveLimit = driveLimit
	for key, box in pairs(self.map.caches) do
		context.world.prompt(box, "Cache", "ТАЙНИК / CACHE", function(player)
			if not context.allowRequest(player) then
				return
			end
			if not context.world:near(player, box) then
				return
			end
			self:result(
				player,
				context.profiles:mutate(player, function(data)
					return self.advanced:cache(data, key)
				end, true)
			)
		end)
	end
	for key, port in pairs(self.map.switches) do
		context.world.prompt(port.console, "Robot", "РОБОТ / ROBOT", function(player)
			self:robot(player, key)
		end)
	end
	context.world.prompt(
		self.map.beacons[1],
		"NightTask",
		"НОЧНАЯ ВЫЛАЗКА / NIGHT TASK",
		function(player)
			if not context.allowRequest(player) then
				return
			end
			if not context.world:near(player, self.map.beacons[1]) then
				return
			end
			local night, remaining = self.night:clock()
			if not night or remaining < 90 then
				self:result(player, false, "night_wait")
				return
			end
			self:result(
				player,
				context.profiles:mutate(player, function(data)
					if not data.quests.soldLamp then
						return false, "quest_not_ready"
					end
					if data.quests.nightDone then
						return false, "already_claimed"
					end
					data.quests.nightStarted = true
					return true
				end, true)
			)
		end
	)
	task.spawn(function()
		local tickCount = 0
		while true do
			task.wait(1)
			tickCount += 1
			for _, player in ipairs(Players:GetPlayers()) do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local data = context.profiles:get(player)
				if root and root.AssemblyLinearVelocity.Magnitude > 1 then
					self.telemetry:touch(player)
				end
				if
					data
					and data.quests.nightStarted
					and not data.quests.nightVisited
					and self.night.night
					and root
					and (root.Position - self.map.beacons[2].Position).Magnitude <= 13
				then
					context.profiles:mutate(player, function(draft)
						draft.quests.nightVisited = true
						return true
					end, true)
				end
				if tickCount % 30 == 0 then
					self.telemetry:tick(player)
					task.spawn(function()
						self.commerce:refresh(player)
					end)
				end
			end
			for _, port in pairs(self.map.switches) do
				if port.openUntil > 0 and os.clock() > port.openUntil then
					port.openUntil = 0
					port.gate.CanCollide = true
					port.gate.Transparency = 0
				end
			end
		end
	end)
	return self
end

function Expansion:result(player, ok, reason)
	if not ok then
		self.context.notice:FireClient(player, reason or "invalid_action")
	end
	self.context.push(player)
	return ok
end

function Expansion:decorateState(player, payload)
	payload.prototype = false
	payload.capacity = self.context.rules:capacity(payload, self.commerce:owns(player, "storage"))
	payload.cargoCapacity = self.vehicles:capacity(player)
	local vehicle = self.vehicles.states[player]
	payload.activeVehicle = vehicle and vehicle.kind or nil
	payload.passes = self.commerce:products(player)
end

function Expansion:onChanged(player)
	local data = self.context.profiles:get(player)
	if not data then
		return
	end
	self.telemetry:update(
		player,
		data,
		self.context.rules:capacity(data, self.commerce:owns(player, "storage"))
	)
	self.context.world:applyAppearance(player, data, self.commerce:owns(player, "decor"))
end

function Expansion:touch(player)
	self.telemetry:touch(player)
end

function Expansion:delivered(player, data, amount)
	local vehicle = self.vehicles.states[player]
	if vehicle and vehicle.kind == "cart" and amount >= 3 then
		data.quests.cartDelivered = (data.quests.cartDelivered or 0) + amount
	end
	if data.quests.nightVisited and not data.quests.nightDone then
		data.quests.nightDone = true
	end
end

function Expansion:atGarage(player, key)
	local garage = self.context.world:getGarage(player)
	return garage and self.context.world:near(player, garage[key or "bench"])
end

function Expansion:robot(player, key)
	if not self.context.allowRequest(player) then
		return
	end
	local port = self.map.switches[key]
	local data = self.context.profiles:get(player)
	if not port or not self.context.world:near(player, port.console) then
		return self:result(player, false, "too_far")
	end
	if not data or data.equipment.robot ~= true then
		return self:result(player, false, "needs_robot")
	end
	if
		self.activeRobots[player]
		or os.clock() - (self.cooldowns[tostring(player.UserId) .. ":robot"] or -100) < 30
	then
		return self:result(player, false, "robot_busy")
	end
	self.activeRobots[player] = true
	self.cooldowns[tostring(player.UserId) .. ":robot"] = os.clock()
	local bot = self.context.world:itemVisual(
		"robot",
		port.console.Position + Vector3.new(0, 2, 3),
		Color3.fromRGB(213, 174, 109)
	)
	bot.Parent = self.context.world.root
	local marker = Instance.new("CFrameValue")
	marker.Value = bot:GetPivot()
	local connection = marker.Changed:Connect(function(value)
		if bot.Parent then
			bot:PivotTo(value)
		end
	end)
	local tween =
		TweenService:Create(marker, TweenInfo.new(3), { Value = marker.Value + Vector3.new(0, 0, -9) })
	tween:Play()
	task.delay(3, function()
		connection:Disconnect()
		marker:Destroy()
		bot:Destroy()
		self.activeRobots[player] = nil
		if player.Parent ~= Players then
			return
		end
		if not self.context.world:near(player, port.console) then
			self:result(player, false, "too_far")
			return
		end
		local ok, reason = self.context.profiles:mutate(player, function(draft)
			return self.advanced:switch(draft, key)
		end, true)
		if ok then
			port.openUntil = os.clock() + 60
			port.gate.CanCollide = false
			port.gate.Transparency = 0.8
		end
		self:result(player, ok, reason)
	end)
end

function Expansion:handle(player, action, args)
	local context = self.context
	local data = context.profiles:get(player)
	if not data then
		return false
	end
	if action == "OpenWorkbench" or action == "OpenShop" then
		local which = action == "OpenWorkbench" and "bench" or "shop"
		if not self:atGarage(player, which) then
			self:result(player, false, "too_far")
			return true
		end
		context.remotes.Open:FireClient(player, which == "bench" and "workbench" or "shop")
		return true
	elseif action == "Queue" then
		if not self:atGarage(player) or type(args.id) ~= "string" or #args.id > 64 then
			self:result(player, false, "too_far")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				return self.advanced:queue(draft, args.id)
			end)
		)
		return true
	elseif action == "Display" then
		if not self:atGarage(player) or type(args.id) ~= "string" then
			self:result(player, false, "too_far")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				local item, index = context.rules:find(draft, args.id)
				if not item or not index or item.stage ~= 3 then
					return false, "invalid_item"
				end
				local count = 0
				for _, entry in ipairs(draft.items) do
					if entry.display then
						count += 1
					end
				end
				if not item.display and count >= 3 then
					return false, "display_full"
				end
				item.display = not item.display
				return true
			end, true)
		)
		return true
	elseif action == "Advance" and data.quests.step >= 6 then
		if not self:atGarage(player) then
			self:result(player, false, "too_far")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				return self.advanced:advance(draft)
			end, true)
		)
		return true
	elseif action == "VehicleProject" then
		if not self:atGarage(player) or (args.key ~= "cart" and args.key ~= "buggy") then
			self:result(player, false, "too_far")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				return self.advanced:vehicle(draft, args.key, workspace:GetServerTimeNow())
			end, true)
		)
		return true
	elseif action == "SpawnVehicle" then
		if not self:atGarage(player) then
			self:result(player, false, "too_far")
			return true
		end
		if (args.key ~= "cart" and args.key ~= "buggy") or data.vehicles[args.key] ~= true then
			self:result(player, false, "not_available")
			return true
		end
		local ok, reason = self.vehicles:spawn(
			player,
			args.key,
			self.commerce:owns(player, "paint") and data.cosmetics.vehiclePaint or nil
		)
		if ok and args.key == "cart" then
			context.notice:FireClient(player, "cart_waiting")
		end
		self:result(player, ok, reason)
		return true
	elseif action == "RecallVehicle" then
		self:result(player, self.vehicles:recall(player))
		return true
	elseif action == "ResetVehicle" then
		self:result(player, self.vehicles:reset(player))
		return true
	elseif action == "Install" then
		if not self:atGarage(player) or type(args.id) ~= "string" or #args.id > 64 then
			self:result(player, false, "too_far")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				return self.advanced:install(draft, args.id)
			end, true)
		)
		return true
	elseif action == "Order" then
		if not self:atGarage(player, "shop") or not Config.Orders[args.key] then
			self:result(player, false, "too_far")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				return self.advanced:order(draft, args.key, workspace:GetServerTimeNow())
			end, true)
		)
		return true
	elseif action == "Scan" then
		if data.equipment.radio ~= true then
			self:result(player, false, "needs_radio")
			return true
		end
		local key = tostring(player.UserId) .. ":scan"
		if os.clock() - (self.cooldowns[key] or -100) < 10 then
			self:result(player, false, "too_soon")
			return true
		end
		self.cooldowns[key] = os.clock()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local chosen, distance
		for cacheKey, box in pairs(self.map.caches) do
			local d = root and (root.Position - box.Position).Magnitude or math.huge
			if not data.caches[cacheKey] and d <= 60 and (not distance or d < distance) then
				chosen = box
				distance = d
			end
		end
		if chosen then
			self.signal:FireClient(player, chosen.Position)
			context.notice:FireClient(player, "signal_found")
		else
			context.notice:FireClient(player, "signal_none")
		end
		return true
	elseif action == "Sprint" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = args.enabled == true and 22 or 16
		end
		return true
	elseif action == "Theme" then
		if not self:atGarage(player) then
			self:result(player, false, "too_far")
			return true
		end
		if
			args.key ~= "default"
			and not (
				type(args.key) == "string"
				and (Config.Themes[args.key] or args.key == "mint")
				and data.cosmetics[args.key]
			)
		then
			self:result(player, false, "not_available")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				draft.theme = args.key
				return true
			end, true)
		)
		return true
	elseif action == "Paint" then
		if
			not self:atGarage(player)
			or not self.commerce:owns(player, "paint")
			or not Vehicles.Paints[args.key]
		then
			self:result(player, false, "not_available")
			return true
		end
		self:result(
			player,
			context.profiles:mutate(player, function(draft)
				draft.cosmetics.vehiclePaint = args.key
				return true
			end, true)
		)
		return true
	elseif action == "BuyPass" then
		if not self:atGarage(player, "shop") or context.profiles.critical then
			self:result(player, false, "too_far")
			return true
		end
		self:result(player, self.commerce:prompt(player, args.key))
		return true
	end
	return false
end

function Expansion:release(player)
	self.night:release(player)
	self.vehicles:release(player)
	self.commerce:release(player)
	self.telemetry:release(player)
	self.driveLimit:remove(player)
	for key in pairs(self.cooldowns) do
		if string.sub(key, 1, #tostring(player.UserId) + 1) == tostring(player.UserId) .. ":" then
			self.cooldowns[key] = nil
		end
	end
	self.activeRobots[player] = nil
end

return Expansion
