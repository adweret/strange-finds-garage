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
	if result.language ~= "auto" and result.language ~= "ru" and result.language ~= "en" then
		return nil, "corrupt_profile"
	end
	return result
end

return Schema
