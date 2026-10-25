local RunService = game:GetService("RunService")
local CargoManifest = require(game:GetService("ReplicatedStorage").Garage.CargoManifest)
local Vehicles = {}
Vehicles.__index = Vehicles
Vehicles.Paints = {
	mint = Color3.fromRGB(113, 181, 156),
	plum = Color3.fromRGB(147, 118, 165),
	cream = Color3.fromRGB(224, 209, 170),
}

local function block(model, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Anchored = true
	part.CanCollide = false
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = model
	return part
end

function Vehicles.new(world, cargoFor)
	local self = setmetatable(
		{ world = world, states = {}, cargoFor = cargoFor, manifest = CargoManifest.new() },
		Vehicles
	)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.05 then
			self:update(math.min(elapsed, 0.1))
			elapsed = 0
		end
	end)
	return self
end

function Vehicles:spawn(player, kind, paint)
	if self.states[player] then
		return false, "recall_first"
	end
	if #self.cargoFor(player) > 0 then
		return false, "vehicle_busy"
	end
	local garage = self.world:getGarage(player)
	if not garage then
		return false, "invalid_action"
	end
	local position
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = player.Character and { player.Character } or {}
	overlap.RespectCanCollide = true
	for _, offset in ipairs({
		Vector3.new(8, 2.2, -30),
		Vector3.new(-8, 2.2, -30),
		Vector3.new(8, 2.2, -42),
		Vector3.new(-8, 2.2, -42),
	}) do
		local candidate = garage.origin + offset
		local clear = #workspace:GetPartBoundsInBox(
			CFrame.new(candidate + Vector3.new(0, 0.8, 0)),
			Vector3.new(8, 2.4, 11),
			overlap
		) == 0
		for _, other in pairs(self.states) do
			if (candidate - other.position).Magnitude < 12 then
				clear = false
				break
			end
		end
		if clear then
			position = candidate
			break
		end
	end
	if not position then
		return false, "spawn_blocked"
	end
	local model = Instance.new("Model")
	model.Name = kind .. "_" .. player.UserId
	local color = kind == "cart" and Color3.fromRGB(102, 154, 144) or Color3.fromRGB(213, 151, 91)
	color = Vehicles.Paints[paint] or color
	local chassis = block(
		model,
		"Chassis",
		Vector3.new(kind == "cart" and 4 or 7, 1, kind == "cart" and 5 or 10),
		Vector3.zero,
		color
	)
	model.PrimaryPart = chassis
	local seat
	if kind == "buggy" then
		seat = Instance.new("VehicleSeat")
		seat.Name = "Driver"
		seat.Anchored = true
		seat.Size = Vector3.new(2, 1, 2)
		seat.CFrame = CFrame.new(0, 1, -2)
		seat.Color = Color3.fromRGB(39, 52, 57)
		seat.Parent = model
		block(
			model,
			"Windshield",
			Vector3.new(5, 2, 0.3),
			Vector3.new(0, 2, -4),
			Color3.fromRGB(136, 181, 188)
		)
		block(model, "Hood", Vector3.new(6, 1, 2), Vector3.new(0, 0.8, -4), color)
	else
		block(model, "Handle", Vector3.new(3, 0.3, 0.3), Vector3.new(0, 2, -3), Color3.fromRGB(55, 64, 62))
	end
	for _, x in ipairs({ kind == "cart" and -2 or -3.5, kind == "cart" and 2 or 3.5 }) do
		for _, z in ipairs({ -2.7, 2.7 }) do
			local wheel = block(
				model,
				"Wheel",
				Vector3.new(1.3, 1.3, 1.1),
				Vector3.new(x, -0.6, z),
				Color3.fromRGB(36, 43, 45)
			)
			wheel.Shape = Enum.PartType.Ball
		end
	end
	local slots = {}
	for index = 1, kind == "cart" and 3 or 6 do
		local box = block(
			model,
			"Cargo" .. index,
			Vector3.new(1.5, 1.4, 1.5),
			Vector3.new((index - 1) % 3 * 1.8 - 1.8, 1.2, 1 + math.floor((index - 1) / 3) * 1.8),
			Color3.fromRGB(145, 106, 75)
		)
		box.Transparency = 1
		table.insert(slots, box)
	end
	model.Parent = self.world.root
	model:PivotTo(CFrame.new(position))
	local state = {
		model = model,
		kind = kind,
		seat = seat,
		slots = slots,
		position = position,
		yaw = 0,
		throttle = 0,
		steer = 0,
		inputAt = 0,
		resetAt = 0,
		following = false,
		awaitingOwner = kind == "cart",
		lastRoot = nil,
	}
	self.states[player] = state
	if seat then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = seat.Occupant
			if occupant and (not player.Character or occupant.Parent ~= player.Character) then
				occupant.Sit = false
			end
		end)
	end
	return true
end

function Vehicles:recall(player)
	local state = self.states[player]
	if not state then
		return false, "no_vehicle"
	end
	if #self.cargoFor(player) > 0 or (state.seat and state.seat.Occupant) then
		return false, "vehicle_busy"
	end
	state.model:Destroy()
	self.states[player] = nil
	return true
end

function Vehicles:capacity(player)
	local state = self.states[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local near = state and root and (root.Position - state.position).Magnitude <= 13
	return self.manifest:capacity(player, #self.cargoFor(player), state, near)
end

function Vehicles:canCollect(player)
	local state = self.states[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local near = state and root and (root.Position - state.position).Magnitude <= 13
	return self.manifest:canTake(player, #self.cargoFor(player), state, near)
end

function Vehicles:claimCargo(player)
	local state = self.states[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	self.manifest:claim(
		player,
		#self.cargoFor(player),
		state,
		state and root and (root.Position - state.position).Magnitude <= 13
	)
end

function Vehicles:hasVehicleCargo(player)
	return self.manifest.carriers[player] ~= nil and self.manifest.carriers[player] ~= false
end

function Vehicles:clearCargo(player)
	self.manifest:clear(player)
end

function Vehicles:canUnload(player, position)
	return self.manifest:canUnload(player, self:near(player, position))
end

function Vehicles:near(player, position)
	local state = self.states[player]
	return state ~= nil and (state.position - position).Magnitude <= 13
end

function Vehicles:drive(player, throttle, steer)
	local state = self.states[player]
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if
		not humanoid
		or humanoid.Health <= 0
		or not state
		or not state.seat
		or state.seat.Occupant ~= humanoid
	then
		return
	end
	state.throttle = throttle
	state.steer = steer
	state.inputAt = os.clock()
end

function Vehicles:reset(player)
	local state = self.states[player]
	if not state then
		return false, "no_vehicle"
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if
		not root
		or not humanoid
		or humanoid.Health <= 0
		or (root.Position - state.position).Magnitude > 13
	then
		return false, "too_far"
	end
	if os.clock() - state.resetAt < 10 then
		return false, "too_soon"
	end
	state.resetAt = os.clock()
	state.throttle = 0
	state.steer = 0
	state.following = true
	state.awaitingOwner = false
	state.lastRoot = root.Position
	state.model:PivotTo(CFrame.new(state.position) * CFrame.Angles(0, state.yaw, 0))
	return true
end

function Vehicles:stop(player)
	local state = self.states[player]
	if state then
		state.throttle = 0
		state.steer = 0
		state.following = false
		state.awaitingOwner = false
	end
	self:clearCargo(player)
end

function Vehicles:release(player)
	self:clearCargo(player)
	local state = self.states[player]
	if state then
		state.model:Destroy()
		self.states[player] = nil
	end
end

function Vehicles:update(dt)
	for player, state in pairs(self.states) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			continue
		end
		local cargo = self.cargoFor(player)
		for index, box in ipairs(state.slots) do
			box.Transparency = self.manifest.carriers[player] == state and index <= #cargo and 0 or 1
		end
		if state.awaitingOwner and (root.Position - state.position).Magnitude <= 13 then
			state.awaitingOwner = false
			state.following = true
			state.lastRoot = root.Position
		end
		if state.kind == "cart" and state.following then
			local target = root.Position - root.CFrame.LookVector * 5
			local targetPosition = Vector3.new(target.X, 2.2, target.Z)
			local delta = targetPosition - state.position
			if state.lastRoot and (root.Position - state.lastRoot).Magnitude > 80 then
				state.following = false
				if self.onStopped then
					self.onStopped(player)
				end
			else
				if delta.Magnitude > 0.05 then
					local step = delta.Unit * math.min(delta.Magnitude, 24 * dt)
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = { state.model, character }
					params.RespectCanCollide = true
					local hit = workspace:Blockcast(
						CFrame.new(state.position + Vector3.new(0, 0.4, 0)),
						Vector3.new(3.5, 1.5, 4),
						step,
						params
					)
					if not hit then
						state.position += step
					else
						state.following = false
						if self.onStopped then
							self.onStopped(player)
						end
					end
				end
			end
			state.lastRoot = root.Position
			local facing = Vector3.new(root.Position.X, 2.2, root.Position.Z)
			if (facing - state.position).Magnitude > 0.05 then
				state.model:PivotTo(CFrame.lookAt(state.position, facing))
			end
		elseif state.kind == "buggy" and state.seat.Occupant then
			if state.seat.Occupant.Parent ~= character then
				state.seat.Occupant.Sit = false
				state.throttle = 0
				state.steer = 0
				continue
			end
			if os.clock() - state.inputAt > 0.5 then
				state.throttle = 0
				state.steer = 0
			end
			local nextYaw = state.yaw - state.steer * dt * 1.5 * (state.throttle < 0 and -1 or 1)
			local orientation = CFrame.Angles(0, nextYaw, 0)
			local delta = orientation.LookVector * state.throttle * 30 * dt
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { state.model, character }
			params.RespectCanCollide = true
			local hit = delta.Magnitude > 0
				and workspace:Blockcast(
					CFrame.new(state.position + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, state.yaw, 0),
					Vector3.new(7.2, 2.4, 10.2),
					delta,
					params
				)
			local target = state.position + delta
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			overlap.FilterDescendantsInstances = { state.model, character }
			overlap.RespectCanCollide = true
			local blockedTurn = #workspace:GetPartBoundsInBox(
				CFrame.new(target + Vector3.new(0, 0.8, 0)) * orientation,
				Vector3.new(7.2, 2.4, 10.2),
				overlap
			) > 0
			if not hit and not blockedTurn and math.abs(target.X) < 158 and math.abs(target.Z) < 130 then
				state.position = target
				state.yaw = nextYaw
			end
			if delta.Magnitude > 0 and os.clock() - (state.noiseAt or 0) >= 1 then
				state.noiseAt = os.clock()
				if self.onNoise then
					self.onNoise(player, state.position)
				end
			end
			state.model:PivotTo(CFrame.new(state.position) * CFrame.Angles(0, state.yaw, 0))
		end
	end
end

return Vehicles
