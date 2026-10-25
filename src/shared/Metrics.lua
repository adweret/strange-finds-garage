-- Persistent cohort flags let closed-test results count people rather than repeated events.
local Metrics = {}
function Metrics.sample(data, capacity, now)
	local metrics = data.quests.metrics or {}
	data.quests.metrics = metrics
	local events = {}
	if #data.items >= capacity * 0.9 and (not metrics.fullAt or now - metrics.fullAt >= 300) then
		metrics.fullAt = now
		metrics.fullCount = math.min(2, (metrics.fullCount or 0) + 1)
		table.insert(events, "StorageNearFull")
	end
	if data.playSeconds >= 3600 and not metrics.eligible then
		metrics.eligible = true
		table.insert(events, "Eligible60ActiveMinutes")
	end
	if metrics.eligible and (metrics.fullCount or 0) >= 2 and not metrics.eligibleFullTwice then
		metrics.eligibleFullTwice = true
		table.insert(events, "EligibleStorageFullTwice")
	end
	return events
end
function Metrics.blocked(data, now)
	local metrics = data.quests.metrics or {}
	data.quests.metrics = metrics
	metrics.blockedAt = now
	if not metrics.blocked then
		metrics.blocked = true
		return { "TesterStorageBlocked" }
	end
	return {}
end
function Metrics.leaving(data, now)
	local metrics = data.quests.metrics
	if metrics and metrics.blockedAt and now - metrics.blockedAt <= 120 and not metrics.quitAfterBlock then
		metrics.quitAfterBlock = true
		return { "TesterQuitAfterStorageBlock" }
	end
	return {}
end
return Metrics
