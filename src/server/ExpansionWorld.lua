local ExpansionWorld = { caches = {}, switches = {}, beacons = {} }

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

function ExpansionWorld:build(world)
	local root = world.root
	local teal = Color3.fromRGB(74, 125, 122)
	local rust = Color3.fromRGB(149, 91, 68)
	local cream = Color3.fromRGB(223, 206, 169)
	-- A compact village forms the transition between the garages and salvage yard.
	for index, x in ipairs({ -110, -65, 65, 110 }) do
		local house = Instance.new("Model")
		house.Name = "VillageWorkshop" .. index
		house.Parent = root
		local origin = Vector3.new(x, 0, 28)
		part(house, "Floor", Vector3.new(30, 0.6, 25), origin + Vector3.new(0, 0.8, 0), cream)
		part(
			house,
			"Back",
			Vector3.new(30, 12, 1),
			origin + Vector3.new(0, 6, 12),
			index % 2 == 0 and rust or teal
		)
		for _, side in ipairs({ -15, 15 }) do
			part(house, "Side", Vector3.new(1, 12, 25), origin + Vector3.new(side, 6, 0), cream)
		end
		part(house, "Roof", Vector3.new(33, 1, 28), origin + Vector3.new(0, 12.5, 0), teal)
		for _, side in ipairs({ -10, 10 }) do
			part(house, "Doorway", Vector3.new(10, 12, 1), origin + Vector3.new(side, 6, -12), rust)
		end
		part(house, "Lintel", Vector3.new(10, 4, 1), origin + Vector3.new(0, 10, -12), rust)
		part(house, "Worktable", Vector3.new(10, 3, 3), origin + Vector3.new(-5, 2.5, 8), cream)
		part(
			house,
			"Window",
			Vector3.new(8, 4, 0.2),
			origin + Vector3.new(9, 7, -12.6),
			Color3.fromRGB(143, 181, 183),
			Enum.Material.Glass
		)
	end
	for _, x in ipairs({ -32, 32 }) do
		local shelter = Instance.new("Model")
		shelter.Name = "HidingShelter"
		shelter.Parent = root
		part(shelter, "Back", Vector3.new(12, 8, 1), Vector3.new(x, 4, -5), rust)
		part(shelter, "Side", Vector3.new(1, 8, 10), Vector3.new(x - 6, 4, -10), teal)
		part(shelter, "Roof", Vector3.new(13, 1, 11), Vector3.new(x, 8.5, -10), cream)
	end
	world.spots = {}
	for row = 0, 5 do
		for column = 0, 5 do
			local x, z = -125 + column * 50, -115 + row * 26
			if row == 5 then
				z = 5
			end
			if column == 1 and row == 0 then
				z = -120
			end
			if (column == 1 or column == 4) and row == 2 then
				z = -56
			end
			if column == 3 and row == 4 then
				x = 18
			end
			table.insert(world.spots, { position = Vector3.new(x, 2.8, z), readyAt = 0 })
		end
	end
	local cachePositions = {
		Vector3.new(-115, 3, -85),
		Vector3.new(-75, 3, -108),
		Vector3.new(110, 3, -110),
		Vector3.new(120, 3, -25),
		Vector3.new(-55, 3, 8),
		Vector3.new(60, 3, -8),
	}
	for index, position in ipairs(cachePositions) do
		local box = part(root, "Cache" .. index, Vector3.new(3, 2, 2.5), position, cream, Enum.Material.Wood)
		part(root, "CacheStrap", Vector3.new(3.1, 0.3, 2.6), position, teal)
		self.caches["cache" .. index] = box
	end
	local switchPositions = {
		Vector3.new(-105, 2, -45),
		Vector3.new(110, 2, -65),
		Vector3.new(-85, 2, -105),
		Vector3.new(65, 2, -118),
	}
	for index, position in ipairs(switchPositions) do
		local console =
			part(root, "RobotPort" .. index, Vector3.new(3, 3, 3), position, teal, Enum.Material.Metal)
		local gate = part(
			root,
			"RobotGate" .. index,
			Vector3.new(12, 7, 1),
			position + Vector3.new(0, 2, -9),
			rust,
			Enum.Material.Metal
		)
		for _, x in ipairs({ -7, 7 }) do
			part(root, "GatePillar", Vector3.new(1, 9, 2), position + Vector3.new(x, 2, -9), cream)
		end
		for _, x in ipairs({ -18, 18 }) do
			part(
				root,
				"ShortcutFence",
				Vector3.new(22, 7, 1),
				position + Vector3.new(x, 2, -9),
				rust,
				Enum.Material.WoodPlanks
			)
		end
		-- The robot travels through this low opening; players must use the gate or detour.
		part(root, "RobotTunnelRoof", Vector3.new(5, 1, 8), position + Vector3.new(-9, 1.5, -4), teal)
		self.switches["switch" .. index] = { console = console, gate = gate, openUntil = 0 }
	end
	for index, position in ipairs({ Vector3.new(10, 1, 25), Vector3.new(10, 1, -15) }) do
		local floor = part(root, "SafeBeacon" .. index, Vector3.new(17, 0.3, 17), position, teal)
		part(root, "BeaconPost", Vector3.new(1, 13, 1), position + Vector3.new(0, 6.5, 0), rust)
		local bulb = part(
			root,
			"BeaconLight",
			Vector3.new(2, 1, 2),
			position + Vector3.new(0, 13, 0),
			Color3.fromRGB(255, 218, 141),
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Range = 28
		light.Brightness = 2
		light.Color = bulb.Color
		light.Parent = bulb
		table.insert(self.beacons, floor)
	end
	-- Low-cost sorting yard scenery, all original Parts.
	for index = 1, 12 do
		local x = 35 + (index % 4) * 20
		local z = -100 + math.floor(index / 4) * 17
		local pile = part(
			root,
			"ScrapPile",
			Vector3.new(7, 3 + index % 3, 5),
			Vector3.new(x, 2.5, z),
			index % 2 == 0 and rust or teal,
			Enum.Material.CorrodedMetal
		)
		pile.CFrame *= CFrame.Angles(0, math.rad(index * 21), math.rad(7))
	end
	for index = 1, 8 do
		local lamp = part(
			root,
			"RoadLamp",
			Vector3.new(0.6, 12, 0.6),
			Vector3.new(index % 2 == 0 and 18 or -18, 6, -120 + index * 24),
			rust
		)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 205, 136)
		light.Range = 22
		light.Brightness = 0.8
		light.Parent = lamp
	end
	-- Navigation costs cover safe regions, so a route goes around them instead of
	-- repeatedly stopping at the boundary while trying to follow an invalid path.
	local safeAreas = { { Vector3.new(0, 6, 100), Vector3.new(350, 12, 96) } }
	for _, beacon in ipairs(self.beacons) do
		table.insert(safeAreas, { beacon.Position + Vector3.new(0, 5, 0), Vector3.new(26, 12, 26) })
	end
	for _, area in ipairs(safeAreas) do
		local volume = part(root, "CaretakerExcludedArea", area[2], area[1], teal)
		volume.Transparency = 1
		volume.CanCollide = false
		volume.CanQuery = false
		volume.CanTouch = false
		local modifier = Instance.new("PathfindingModifier")
		modifier.Label = "NoCaretaker"
		modifier.Parent = volume
	end
end

function ExpansionWorld:isSafe(position)
	if position.Z >= 52 then
		return true
	end
	for _, beacon in ipairs(self.beacons) do
		if
			(Vector3.new(position.X, 0, position.Z) - Vector3.new(beacon.Position.X, 0, beacon.Position.Z)).Magnitude
			<= 13
		then
			return true
		end
	end
	return false
end

return ExpansionWorld
