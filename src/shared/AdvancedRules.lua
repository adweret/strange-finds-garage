local AdvancedRules = {}
AdvancedRules.__index = AdvancedRules

function AdvancedRules.new(config, base)
	return setmetatable({ config = config, base = base }, AdvancedRules)
end

function AdvancedRules:vehicle(data, kind, now)
	local info = self.config.Vehicles[kind]
	if not info then
		return false, "invalid_item"
	end
	if data.vehicles[kind] == true then
		return false, "already_owned"
	end
	if type(data.vehicles[kind]) == "table" then
		if now < data.vehicles[kind].readyAt then
			return false, "too_soon"
		end
		data.vehicles[kind] = true
		self.base:register(data, kind)
		return true
	end
	if kind == "buggy" and not data.tools then
		return false, "needs_tools"
	end
	if data.coins < info.coins then
		return false, "not_enough_coins"
	end
	if data.parts < info.parts then
		return false, "not_enough_parts"
	end
	data.coins -= info.coins
	data.parts -= info.parts
	data.vehicles[kind] = { readyAt = now + info.duration }
	return true
end

function AdvancedRules:issueEquipment(data)
	if not data.equipment.radio then
		data.equipment.radio = { id = "equipment_radio", kind = "radio", stage = 0, bound = true }
	end
	if not data.equipment.robot then
		data.equipment.robot = { id = "equipment_robot", kind = "robot", stage = 0, bound = true }
	end
	data.quests.issued.equipment = true
end

function AdvancedRules:install(data, id)
	local item, index = self.base:find(data, id)
	if not item or item.stage ~= 3 or (item.kind ~= "radio" and item.kind ~= "robot") then
		return false, "invalid_item"
	end
	if data.equipment[item.kind] == true then
		return false, "already_owned"
	end
	local bound = data.equipment[item.kind]
	if type(bound) == "table" then
		if data.repair and data.repair.id == bound.id then
			return false, "repair_busy"
		end
		local queue = data.quests.repairQueue or {}
		for queued = #queue, 1, -1 do
			if queue[queued] == bound.id then
				table.remove(queue, queued)
			end
		end
	end
	data.equipment[item.kind] = true
	if index then
		table.remove(data.items, index)
	end
	return true
end

function AdvancedRules:cache(data, key)
	if data.equipment.radio ~= true then
		return false, "needs_radio"
	end
	if data.caches[key] then
		return false, "already_claimed"
	end
	data.caches[key] = true
	data.parts += 2
	data.cosmetics[key] = true
	return true
end

function AdvancedRules:switch(data, key)
	if data.equipment.robot ~= true then
		return false, "needs_robot"
	end
	data.switches[key] = true
	local count = 0
	for _, value in pairs(data.switches) do
		if value then
			count += 1
		end
	end
	if count >= 4 then
		data.cosmetics.robotSticker = true
	end
	return true
end

function AdvancedRules:order(data, key, now)
	local info = self.config.Orders[key]
	if not info or data.vehicles.buggy ~= true then
		return false, "needs_buggy"
	end
	if data.orders[key] and now < data.orders[key] then
		return false, "order_cooldown"
	end
	local chosen = {}
	for kind, amount in pairs(info.items) do
		local count = 0
		for index, item in ipairs(data.items) do
			if item.kind == kind and item.stage == 3 and not item.bound and count < amount then
				chosen[index] = true
				count += 1
			end
		end
		if count < amount then
			return false, "order_missing"
		end
	end
	for index = #data.items, 1, -1 do
		if chosen[index] then
			table.remove(data.items, index)
		end
	end
	data.coins += info.reward
	data.orders[key] = now + 1200
	return true
end

function AdvancedRules:advance(data)
	if data.quests.step == 6 and data.vehicles.cart == true and (data.quests.cartDelivered or 0) >= 3 then
		data.quests.step = 8
		self:issueEquipment(data)
		return true
	elseif data.quests.step == 8 then
		local missing = not data.equipment.radio or not data.equipment.robot
		self:issueEquipment(data)
		if
			data.equipment.radio == true
			and data.equipment.robot == true
			and next(data.caches)
			and next(data.switches)
		then
			data.quests.step = 9
			return true
		end
		if missing then
			return true
		end
		return false, "quest_not_ready"
	elseif data.quests.step == 9 and data.vehicles.buggy == true then
		data.quests.step = 10
		return true
	end
	return false, "quest_not_ready"
end

function AdvancedRules:queue(data, id)
	local item = self.base:find(data, id)
	if not item or item.stage >= 3 then
		return false, "invalid_item"
	end
	data.quests.repairQueue = data.quests.repairQueue or {}
	local queue = data.quests.repairQueue
	for _, queued in ipairs(queue) do
		if queued == id then
			table.remove(queue, table.find(queue, id))
			return true
		end
	end
	if #queue >= self.config.BenchQueue[data.benchLevel] then
		return false, "queue_full"
	end
	table.insert(queue, id)
	return true
end

return AdvancedRules
