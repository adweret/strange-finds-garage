local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")
local Metrics = require(game:GetService("ReplicatedStorage").Garage.Metrics)
local Telemetry = {}
Telemetry.__index = Telemetry

function Telemetry.new(profiles, capacityFor)
	return setmetatable({ profiles = profiles, states = {}, capacityFor = capacityFor }, Telemetry)
end

function Telemetry:emit(player, name, value)
	if RunService:IsStudio() then
		return
	end
	pcall(function()
		AnalyticsService:LogCustomEvent(player, name, value or 1)
	end)
end

function Telemetry:touch(player)
	local record = self.states[player]
	if not record then
		record = { activeAt = os.clock(), clock = os.clock(), last = {}, fullnessAt = nil }
		self.states[player] = record
	end
	record.activeAt = os.clock()
end

function Telemetry:update(player, data)
	if not self.states[player] then
		self:touch(player)
	end
	local record = self.states[player]
	local steps = {
		{ "Joined", true },
		{ "FirstDelivery", #data.items > 0 or data.quests.step > 1 },
		{ "FirstRepair", data.collection.toycar == true },
		{ "FirstSale", data.quests.soldLamp == true },
		{ "Cart", data.vehicles.cart == true },
		{ "FirstNight", data.quests.nightDone == true },
		{ "Buggy", data.vehicles.buggy == true },
	}
	for index, pair in ipairs(steps) do
		if pair[2] and not record.last[pair[1]] then
			record.last[pair[1]] = true
			if not RunService:IsStudio() then
				pcall(function()
					AnalyticsService:LogOnboardingFunnelStepEvent(player, index, pair[1])
				end)
			end
		end
	end
	local errors = self.profiles.errorCount or 0
	if errors > (record.errors or 0) then
		self:emit(player, "SaveError", errors - (record.errors or 0))
	end
	record.errors = errors
end

function Telemetry:blocked(player)
	self:touch(player)
	self.states[player].blockedAt = os.clock()
	self:emit(player, "StorageDeliveryBlocked")
	local events = {}
	local ok = self.profiles:mutate(player, function(data)
		events = Metrics.blocked(data, workspace:GetServerTimeNow())
		return true
	end)
	if ok then
		for _, event in ipairs(events) do
			self:emit(player, event)
		end
	end
end

function Telemetry:tick(player)
	local record = self.states[player]
	if not record then
		self:touch(player)
		return
	end
	local now = os.clock()
	local elapsed = math.floor(now - record.clock)
	record.clock = now
	local events = {}
	local ok = self.profiles:mutate(player, function(data)
		if now - record.activeAt <= 60 then
			data.playSeconds += elapsed
		end
		events = Metrics.sample(data, self.capacityFor(player, data), workspace:GetServerTimeNow())
		return true
	end)
	if ok then
		for _, event in ipairs(events) do
			self:emit(player, event)
		end
	end
end

function Telemetry:release(player)
	local record = self.states[player]
	if record and record.blockedAt and os.clock() - record.blockedAt <= 120 then
		self:emit(player, "ExitWithin2MinutesAfterStorageBlock")
		local events = {}
		local ok = self.profiles:mutate(player, function(data)
			events = Metrics.leaving(data, workspace:GetServerTimeNow())
			return true
		end, true)
		if ok then
			for _, event in ipairs(events) do
				self:emit(player, event)
			end
		end
	end
	self.states[player] = nil
end

return Telemetry
