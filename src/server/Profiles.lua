local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Garage")
local Config = require(Shared.Config)
local Schema = require(Shared.Schema)
local Atomic = require(Shared.Atomic)
local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)

local Profiles = { sessions = {}, critical = false, listeners = {}, saveQueued = {} }
ProfileStore.SetConstant("AUTO_SAVE_PERIOD", 120)
ProfileStore.SetConstant("START_SESSION_TIMEOUT", 30)
local store = ProfileStore.New("StrangeFindsProfiles", Schema.new())
if RunService:IsStudio() then
	store = store.Mock
end

function Profiles:notify(player)
	for _, callback in ipairs(self.listeners) do
		callback(player)
	end
end

function Profiles:onChange(callback)
	table.insert(self.listeners, callback)
end

function Profiles:get(player)
	local profile = self.sessions[player]
	return profile and profile:IsActive() and profile.Data or nil
end

function Profiles:mutate(player, operation, important)
	local profile = self.sessions[player]
	local success, reason =
		Atomic.apply(profile, Schema.clone, operation, self.critical or ProfileStore.IsCriticalState)
	if not success then
		return false, reason
	end
	if important and not self.saveQueued[profile] then
		self.saveQueued[profile] = true
		task.defer(function()
			if profile:IsActive() then
				profile:Save()
			end
			task.delay(5, function()
				self.saveQueued[profile] = nil
			end)
		end)
	end
	self:notify(player)
	return true, reason
end

function Profiles:load(player)
	local ok, profile = pcall(function()
		return store:StartSessionAsync(Config.Environment .. ":" .. tostring(player.UserId), {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)
	if not ok or not profile then
		if player.Parent == Players then
			player:Kick(
				"Не удалось загрузить прогресс. Пожалуйста, войди снова. / Could not load progress. Please rejoin."
			)
		end
		return false
	end
	local data, reason = Schema.migrate(profile.Data, Config.Items)
	if not data then
		profile:EndSession()
		player:Kick(
			"Профиль требует восстановления: "
				.. tostring(reason)
				.. " / Profile could not be loaded safely."
		)
		return false
	end
	-- Repair timers are transient. Materials are only charged when a stage completes.
	data.repair = nil
	profile.Data = data
	profile:AddUserId(player.UserId)
	profile.OnSessionEnd:Connect(function()
		self.sessions[player] = nil
		if player.Parent == Players then
			player:Kick(
				"Сессия прогресса завершена. Войди снова. / Progress session ended. Please rejoin."
			)
		end
	end)
	profile.OnAfterSave:Connect(function(saved)
		if player.Parent == Players then
			player:SetAttribute("SavedRevision", saved.revision or 0)
		end
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return false
	end
	self.sessions[player] = profile
	player:SetAttribute("StudioMock", RunService:IsStudio())
	self:notify(player)
	return true
end

function Profiles:release(player)
	local profile = self.sessions[player]
	self.sessions[player] = nil
	if profile then
		self.saveQueued[profile] = nil
	end
	if profile and profile:IsActive() then
		profile:EndSession()
	end
end

ProfileStore.OnCriticalToggle:Connect(function(critical)
	Profiles.critical = critical
	for _, player in ipairs(Players:GetPlayers()) do
		Profiles:notify(player)
	end
end)

ProfileStore.OnError:Connect(function(message)
	warn("[Garage persistence] " .. tostring(message))
end)

return Profiles
