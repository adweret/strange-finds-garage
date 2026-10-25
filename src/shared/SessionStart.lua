local SessionStart = {}
local message =
	"Не удалось загрузить прогресс. Пожалуйста, войди снова. / Could not load progress. Please rejoin."

function SessionStart.run(store, key, player, players)
	local ok, profile = pcall(function()
		return store:StartSessionAsync(key, {
			Cancel = function()
				return player.Parent ~= players
			end,
		})
	end)
	if not ok or not profile then
		if player.Parent == players then
			player:Kick(message)
		end
		return nil
	end
	if player.Parent ~= players or not profile:IsActive() then
		profile:EndSession()
		if player.Parent == players then
			player:Kick(message)
		end
		return nil
	end
	return profile
end

return SessionStart
