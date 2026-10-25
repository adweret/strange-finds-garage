local Schema = {}
Schema.Version = 1

function Schema.new()
	return {
		schemaVersion = 1,
		revision = 0,
		coins = 50,
		parts = 8,
		items = {},
		equipment = {},
		collection = {},
		vehicles = {},
		storageLevel = 1,
		benchLevel = 1,
		tools = false,
		quests = { step = 1, issued = {}, soldLamp = false, boughtPart = false, dismantledFan = false },
		caches = {},
		switches = {},
		orders = {},
		cosmetics = {},
		language = "auto",
		theme = "default",
		playSeconds = 0,
	}
end

function Schema.clone(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = Schema.clone(child)
	end
	return result
end

local function integer(value, minimum, maximum)
	return type(value) == "number"
		and value == value
		and value % 1 == 0
		and value >= minimum
		and value <= maximum
end

local function finiteTime(value)
	return type(value) == "number" and value == value and value >= 0 and value < 100000000000
end

function Schema.migrate(data, catalog)
	if type(data) ~= "table" then
		return nil, "corrupt_profile"
	end
	local version = data.schemaVersion or 0
	if not integer(version, 0, Schema.Version) then
		return nil, "unsupported_schema"
	end
	local result = Schema.clone(data)
	if version == 0 then
		local template = Schema.new()
		for key, value in pairs(template) do
			if result[key] == nil then
				result[key] = value
			end
		end
		result.schemaVersion = 1
	end
	for _, key in ipairs({
		"items",
		"equipment",
		"collection",
		"vehicles",
		"quests",
		"caches",
		"switches",
		"orders",
		"cosmetics",
	}) do
		if type(result[key]) ~= "table" then
			return nil, "corrupt_profile"
		end
	end
	if
		not integer(result.coins, 0, 1000000000)
		or not integer(result.parts, 0, 1000000)
		or not integer(result.revision, 0, 1000000000000)
		or not integer(result.storageLevel, 1, 3)
		or not integer(result.benchLevel, 1, 3)
		or not integer(result.quests.step, 1, 10)
		or type(result.quests.issued) ~= "table"
		or #result.items > 60
	then
		return nil, "corrupt_profile"
	end
	local ids = {}
	for _, item in ipairs(result.items) do
		if
			type(item) ~= "table"
			or type(item.id) ~= "string"
			or #item.id > 64
			or ids[item.id]
			or type(item.kind) ~= "string"
			or (catalog and not catalog[item.kind])
			or not integer(item.stage, 0, 3)
		then
			return nil, "corrupt_profile"
		end
		ids[item.id] = true
	end
	if
		not integer(result.playSeconds, 0, 1000000000)
		or type(result.tools) ~= "boolean"
		or type(result.theme) ~= "string"
	then
		return nil, "corrupt_profile"
	end
	for _, kind in ipairs({ "radio", "robot" }) do
		local value = result.equipment[kind]
		if value ~= nil and value ~= true then
			if
				type(value) ~= "table"
				or value.id ~= "equipment_" .. kind
				or value.kind ~= kind
				or value.bound ~= true
				or not integer(value.stage, 0, 2)
			then
				return nil, "corrupt_profile"
			end
			ids[value.id] = true
		end
	end
	for key, value in pairs(result.vehicles) do
		if
			(key ~= "cart" and key ~= "buggy")
			or (value ~= true and (type(value) ~= "table" or not finiteTime(value.readyAt)))
		then
			return nil, "corrupt_profile"
		end
	end
	for key, value in pairs(result.orders) do
		if (key ~= "lamps" and key ~= "radiofan" and key ~= "generator") or not finiteTime(value) then
			return nil, "corrupt_profile"
		end
	end
	for key, value in pairs(result.collection) do
		if
			type(key) ~= "string"
			or value ~= true
			or (catalog and not catalog[key] and key ~= "cart" and key ~= "buggy")
		then
			return nil, "corrupt_profile"
		end
	end
	if result.quests.repairQueue ~= nil then
		if type(result.quests.repairQueue) ~= "table" or #result.quests.repairQueue > 4 then
			return nil, "corrupt_profile"
		end
		-- Stale preparation references can safely be rebuilt; they grant no assets.
		local queue, queued = {}, {}
		for _, id in ipairs(result.quests.repairQueue) do
			if type(id) ~= "string" then
				return nil, "corrupt_profile"
			end
			if ids[id] and not queued[id] then
				table.insert(queue, id)
				queued[id] = true
			end
		end
		result.quests.repairQueue = queue
	end
	if result.quests.metrics ~= nil then
		local metrics = result.quests.metrics
		if type(metrics) ~= "table" then
			return nil, "corrupt_profile"
		end
		for _, key in ipairs({ "fullAt", "blockedAt", "fullCount" }) do
			if metrics[key] ~= nil and not finiteTime(metrics[key]) then
				return nil, "corrupt_profile"
			end
		end
	end
	if result.language ~= "auto" and result.language ~= "ru" and result.language ~= "en" then
		return nil, "corrupt_profile"
	end
	return result
end

return Schema
