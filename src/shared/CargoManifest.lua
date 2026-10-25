-- Transient cargo is bound to its original carrier until it is unloaded or lost.
local CargoManifest = {}
CargoManifest.__index = CargoManifest

function CargoManifest.new()
	return setmetatable({ carriers = {} }, CargoManifest)
end

function CargoManifest:capacity(owner, count, vehicle, nearVehicle)
	local carrier = self.carriers[owner]
	if count == 0 then
		carrier = nearVehicle and vehicle
	end
	return carrier and carrier.kind == "buggy" and 6 or (carrier and 3 or 1)
end

function CargoManifest:canTake(owner, count, vehicle, nearVehicle)
	local carrier = self.carriers[owner]
	if count > 0 and carrier and (carrier ~= vehicle or not nearVehicle) then
		return false, "bring_vehicle"
	end
	if count >= self:capacity(owner, count, vehicle, nearVehicle) then
		return false, "cargo_full"
	end
	return true
end

function CargoManifest:claim(owner, countBefore, vehicle, nearVehicle)
	if countBefore == 0 then
		self.carriers[owner] = nearVehicle and vehicle or false
	end
end

function CargoManifest:canUnload(owner, nearVehicle)
	return not self.carriers[owner] or nearVehicle
end

function CargoManifest:clear(owner)
	self.carriers[owner] = nil
end

return CargoManifest
