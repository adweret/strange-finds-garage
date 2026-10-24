-- An operation is committed only if it finishes synchronously on an active session.
local Atomic = {}

function Atomic.apply(profile, clone, operation, critical)
	if critical then
		return false, "save_unavailable"
	end
	if not profile or not profile:IsActive() then
		return false, "profile_unavailable"
	end
	local draft = clone(profile.Data)
	local thread = coroutine.create(function()
		return operation(draft)
	end)
	local resumed, success, reason = coroutine.resume(thread)
	if coroutine.status(thread) ~= "dead" then
		coroutine.close(thread)
		return false, "yielding_transaction"
	end
	if not resumed then
		return false, "transaction_error"
	end
	if not success then
		return false, reason
	end
	if not profile:IsActive() then
		return false, "profile_unavailable"
	end
	draft.revision += 1
	profile.Data = draft
	return true, reason
end

return Atomic
