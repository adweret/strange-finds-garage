local NightBrain = {}
NightBrain.__index = NightBrain

function NightBrain.new()
	return setmetatable({ mode = "Patrol", target = nil, lockUntil = 0, lastSeen = -math.huge }, NightBrain)
end

function NightBrain:step(now, actors, sounds)
	local current, nearest
	for _, actor in ipairs(actors) do
		if actor.eligible then
			if actor.id == self.target then
				current = actor
			end
			if
				actor.visible
				and actor.distance <= 25
				and (not nearest or actor.distance < nearest.distance)
			then
				nearest = actor
			end
		end
	end
	if nearest and (not current or now >= self.lockUntil or current.id == nearest.id) then
		if self.target ~= nearest.id then
			self.lockUntil = now + 3
			self.lastHeard = -math.huge
		end
		self.target = nearest.id
		current = nearest
	end
	for _, sound in ipairs(sounds) do
		if current and sound.ownerId == current.id and now - sound.at <= 5 and sound.distance <= 80 then
			if sound.at > (self.lastHeard or -math.huge) then
				self.lastHeard = sound.at
				self.goal = sound.position
			end
		end
	end
	if current and current.visible and current.distance <= 80 then
		self.lastSeen = now
		self.goal = current.position
		self.mode = "Chase"
		return self.mode, self.goal, self.target
	elseif self.target and current and now - math.max(self.lastSeen, self.lastHeard or -math.huge) < 8 then
		self.mode = "Search"
		return self.mode, self.goal, self.target
	end
	self.target = nil
	local chosen, score
	for _, sound in ipairs(sounds) do
		if now - sound.at <= 5 and sound.distance <= 80 then
			local value = sound.strength / math.max(1, sound.distance)
			if not score or value > score then
				chosen = sound
				score = value
			end
		end
	end
	if chosen then
		self.mode = "Investigate"
		self.goal = chosen.position
	else
		self.mode = "Patrol"
		self.goal = nil
	end
	return self.mode, self.goal, nil
end

return NightBrain
