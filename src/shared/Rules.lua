-- Pure, non-yielding rules. The server injects its clock and GUID generator.
local Rules = {}
Rules.__index = Rules

function Rules.new(config)
	return setmetatable({ config = config }, Rules)
end

function Rules:capacity(data, storagePass)
	return self.config.Storage[data.storageLevel] + (storagePass and 24 or 0)
end

function Rules:find(data, id)
	for index, item in ipairs(data.items) do
		if item.id == id then
			return item, index
		end
	end
	return nil
end

function Rules:register(data, kind)
	data.collection[kind] = true
	local count = 0
	for _, registered in pairs(data.collection) do
		if registered then
			count += 1
		end
	end
	if count >= 4 then
		data.cosmetics.shelf = true
	end
	if count >= 8 then
		data.cosmetics.mint = true
	end
	if count >= 12 then
		data.cosmetics.trophy = true
	end
end

function Rules:issue(data, key, kind, id)
	if data.quests.issued[key] then
		return false, "already_issued"
	end
	if #data.items >= self:capacity(data, false) then
		return false, "storage_full"
	end
	data.quests.issued[key] = true
	table.insert(data.items, { id = id, kind = kind, stage = 0, tutorial = key })
	return true
end

function Rules:deposit(data, cargo, storagePass)
	if #cargo == 0 then
		return false, "no_cargo"
	end
	if #data.items + #cargo > self:capacity(data, storagePass) then
		return false, "storage_full"
	end
	local existing = {}
	for _, item in ipairs(data.items) do
		existing[item.id] = true
	end
	for _, item in ipairs(cargo) do
		if existing[item.id] or not self.config.Items[item.kind] then
			return false, "invalid_item"
		end
		existing[item.id] = true
	end
	for _, item in ipairs(cargo) do
		table.insert(data.items, item)
	end
	return true
end

function Rules:beginRepair(data, id, now)
	local item = self:find(data, id)
	if not item or item.stage >= 3 then
		return false, "invalid_item"
	end
	if data.repair then
		return false, "repair_busy"
	end
	local info = self.config.Items[item.kind]
	if not info then
		return false, "invalid_item"
	end
	if item.stage == 1 and data.parts < info.parts then
		return false, "not_enough_parts"
	end
	data.repair = { id = id, stage = item.stage, startedAt = now, duration = info.duration / 3 }
	return true
end

function Rules:finishRepair(data, id, now)
	local item = self:find(data, id)
	local repair = data.repair
	if not item or not repair or repair.id ~= id or item.stage ~= repair.stage then
		return false, "invalid_repair"
	end
	if now - repair.startedAt < repair.duration then
		return false, "too_soon"
	end
	local info = self.config.Items[item.kind]
	if item.stage == 1 then
		if data.parts < info.parts then
			return false, "not_enough_parts"
		end
		data.parts -= info.parts
	end
	item.stage += 1
	data.repair = nil
	if item.stage == 3 then
		self:register(data, item.kind)
	end
	return true
end

function Rules:sell(data, id)
	local item, index = self:find(data, id)
	if not item or item.stage ~= 3 or item.bound then
		return false, "invalid_item"
	end
	if data.repair and data.repair.id == id then
		return false, "repair_busy"
	end
	data.coins += self.config.Items[item.kind].price
	if item.kind == "lamp" then
		data.quests.soldLamp = true
	end
	table.remove(data.items, index)
	return true
end

function Rules:dismantle(data, id)
	local item, index = self:find(data, id)
	if not item or item.bound then
		return false, "invalid_item"
	end
	if item.tutorial and item.tutorial ~= "fan_scrap" and item.stage < 3 then
		return false, "tutorial_restore_first"
	end
	if data.repair and data.repair.id == id then
		return false, "repair_busy"
	end
	data.parts += self.config.Items[item.kind].parts
	if item.kind == "fan" then
		data.quests.dismantledFan = true
	end
	table.remove(data.items, index)
	return true
end

function Rules:buyPart(data)
	if data.coins < self.config.PartPrice then
		return false, "not_enough_coins"
	end
	data.coins -= self.config.PartPrice
	data.parts += 1
	data.quests.boughtPart = true
	return true
end

function Rules:upgrade(data, key)
	local price
	if key == "storage" then
		price = self.config.StoragePrices[data.storageLevel]
	elseif key == "bench" then
		price = self.config.BenchPrices[data.benchLevel]
	elseif key == "tools" and not data.tools then
		price = 250
	elseif self.config.Themes[key] and not data.cosmetics[key] then
		price = self.config.Themes[key]
	end
	if not price then
		return false, "already_owned"
	end
	if data.coins < price then
		return false, "not_enough_coins"
	end
	data.coins -= price
	if key == "storage" then
		data.storageLevel += 1
	elseif key == "bench" then
		data.benchLevel += 1
	elseif key == "tools" then
		data.tools = true
	else
		data.cosmetics[key] = true
	end
	return true
end

function Rules:advance(data, id)
	local step = data.quests.step
	if step == 1 and data.collection.toycar then
		local ok, reason = self:issue(data, "lamp", "lamp", id)
		if not ok then
			return false, reason
		end
		data.quests.step = 2
		return true
	elseif step == 2 and data.quests.soldLamp then
		local ok, reason = self:issue(data, "fan_scrap", "fan", id)
		if not ok then
			return false, reason
		end
		data.quests.step = 3
		return true
	elseif step == 3 and data.quests.dismantledFan then
		data.quests.step = 4
		return true
	elseif step == 4 and data.quests.boughtPart then
		if not data.quests.issued.fan_restore then
			return self:issue(data, "fan_restore", "fan", id)
		end
		if data.collection.fan then
			local ok, reason = self:issue(data, "radio", "radio", id)
			if not ok then
				return false, reason
			end
			data.quests.step = 5
			return true
		end
	elseif
		step == 5
		and data.collection.toycar
		and data.collection.lamp
		and data.collection.fan
		and data.collection.radio
	then
		data.quests.step = 6
		return true
	end
	return false, "quest_not_ready"
end

function Rules:storageGate(sample)
	return sample.eligible >= 30
		and sample.fullTwice / sample.eligible >= 0.35
		and sample.blocked > 0
		and sample.quitAfterBlock / sample.blocked <= 0.10
end

return Rules
