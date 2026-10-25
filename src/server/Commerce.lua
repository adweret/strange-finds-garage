local MarketplaceService = game:GetService("MarketplaceService")
local Commerce = {}
Commerce.__index = Commerce

function Commerce.new(config, changed)
	local self = setmetatable({ config = config, changed = changed, cache = {}, pending = {} }, Commerce)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		self.pending[player] = nil
		if not purchased then
			return
		end
		for key, info in pairs(config.Passes) do
			if info.id == passId and info.enabled then
				self.cache[player] = self.cache[player] or {}
				self.cache[player][key] = { owned = true, at = os.clock() }
				changed(player)
			end
		end
	end)
	return self
end

function Commerce:owns(player, key)
	local info = self.config.Passes[key]
	if not info or not info.enabled or info.id <= 0 then
		return false
	end
	local cached = self.cache[player] and self.cache[player][key]
	return cached and cached.owned == true or false
end

function Commerce:refresh(player)
	self.cache[player] = self.cache[player] or {}
	local activeCache = self.cache[player]
	if activeCache.refreshing then
		return
	end
	activeCache.refreshing = true
	for key, info in pairs(self.config.Passes) do
		if not info.enabled or info.id <= 0 then
			continue
		end
		local cached = activeCache[key]
		if cached and (cached.owned or os.clock() - cached.at < 30) then
			continue
		end
		local ok, owned = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, info.id)
		end)
		if self.cache[player] ~= activeCache then
			return
		end
		local newer = activeCache[key]
		if ok and not (newer and newer.owned) then
			activeCache[key] = { owned = owned, at = os.clock() }
		end
	end
	activeCache.refreshing = nil
	self.changed(player)
end

function Commerce:products(player)
	local products = {}
	for key, info in pairs(self.config.Passes) do
		if info.enabled and info.id > 0 then
			table.insert(products, { key = key, id = info.id, owned = self:owns(player, key) })
		end
	end
	return products
end

function Commerce:prompt(player, key)
	local info = self.config.Passes[key]
	if not info or not info.enabled or info.id <= 0 then
		return false, "not_available"
	end
	if self:owns(player, key) then
		return false, "already_owned"
	end
	if self.pending[player] then
		return false, "purchase_pending"
	end
	self.pending[player] = true
	local ok = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, info.id)
	end)
	if not ok then
		self.pending[player] = nil
		return false, "not_available"
	end
	task.delay(60, function()
		self.pending[player] = nil
	end)
	return true
end

function Commerce:release(player)
	self.cache[player] = nil
	self.pending[player] = nil
end

return Commerce
