local World = { garages = {}, spots = {}, root = nil }
local colors = {
	sand = Color3.fromRGB(192, 177, 141),
	grass = Color3.fromRGB(105, 131, 101),
	road = Color3.fromRGB(65, 76, 78),
	cream = Color3.fromRGB(225, 213, 184),
	teal = Color3.fromRGB(75, 126, 123),
	rust = Color3.fromRGB(166, 94, 68),
	ink = Color3.fromRGB(36, 48, 52),
	wood = Color3.fromRGB(135, 101, 75),
}

local function part(parent, name, size, position, color, material)
	local value = Instance.new("Part")
	value.Name = name
	value.Size = size
	value.Position = position
	value.Color = color
	value.Material = material or Enum.Material.SmoothPlastic
	value.Anchored = true
	value.TopSurface = Enum.SurfaceType.Smooth
	value.BottomSurface = Enum.SurfaceType.Smooth
	value.Parent = parent
	return value
end

local function sign(parent, name, position, size, text, color)
	local board = part(parent, name, size, position, color or colors.ink)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.PixelsPerStud = 35
	surface.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = colors.cream
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surface
	return board
end

function World.prompt(object, action, text, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = action
	prompt.ActionText = text
	prompt.ObjectText = object.Name
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = object
	prompt.Triggered:Connect(callback)
	return prompt
end

function World:build()
	local root = Instance.new("Folder")
	root.Name = "StrangeFindsIsland"
	root.Parent = workspace
	self.root = root
	part(
		root,
		"Ocean",
		Vector3.new(1200, 2, 1200),
		Vector3.new(0, -8, 0),
		Color3.fromRGB(77, 124, 143),
		Enum.Material.SmoothPlastic
	)
	part(
		root,
		"IslandSand",
		Vector3.new(350, 12, 300),
		Vector3.new(0, -6, 0),
		colors.sand,
		Enum.Material.Sand
	)
	part(
		root,
		"IslandGrass",
		Vector3.new(330, 1, 280),
		Vector3.new(0, 0, 0),
		colors.grass,
		Enum.Material.Grass
	)
	part(
		root,
		"MainRoad",
		Vector3.new(28, 0.3, 260),
		Vector3.new(0, 0.7, 0),
		colors.road,
		Enum.Material.Asphalt
	)
	part(
		root,
		"GarageRoad",
		Vector3.new(290, 0.3, 22),
		Vector3.new(0, 0.7, 62),
		colors.road,
		Enum.Material.Asphalt
	)
	for z = -120, 120, 20 do
		part(root, "LaneMark", Vector3.new(0.4, 0.1, 8), Vector3.new(0, 0.95, z), colors.cream)
	end
	sign(
		root,
		"IslandWelcome",
		Vector3.new(0, 13, 112),
		Vector3.new(28, 7, 1),
		"STRANGE FINDS\nГАРАЖ НАХОДОК",
		colors.teal
	)
	for _, x in ipairs({ -13, 13 }) do
		part(root, "WelcomePost", Vector3.new(0.8, 13, 0.8), Vector3.new(x, 6, 112), colors.wood)
	end
	for i = 1, 6 do
		local x = -125 + (i - 1) * 50
		local garage = Instance.new("Model")
		garage.Name = "Garage" .. i
		garage.Parent = root
		local origin = Vector3.new(x, 0, 92)
		part(
			garage,
			"Floor",
			Vector3.new(40, 1, 38),
			origin + Vector3.new(0, 1, 0),
			colors.cream,
			Enum.Material.Concrete
		)
		part(garage, "Back", Vector3.new(40, 16, 1), origin + Vector3.new(0, 9, 18.5), colors.cream)
		for _, side in ipairs({ -19.5, 19.5 }) do
			part(garage, "Side", Vector3.new(1, 16, 38), origin + Vector3.new(side, 9, 0), colors.cream)
		end
		part(
			garage,
			"Roof",
			Vector3.new(43, 1, 41),
			origin + Vector3.new(0, 17.5, 0),
			colors.teal,
			Enum.Material.Metal
		)
		local board = sign(
			garage,
			"NameBoard",
			origin + Vector3.new(0, 14, -19.1),
			Vector3.new(30, 3, 0.5),
			"ГАРАЖ / GARAGE " .. i
		)
		local bench = part(
			garage,
			"Workbench",
			Vector3.new(13, 3.5, 4),
			origin + Vector3.new(-9, 3, 13),
			colors.wood,
			Enum.Material.Wood
		)
		part(garage, "Pegboard", Vector3.new(12, 5, 0.4), origin + Vector3.new(-9, 7, 17.5), colors.teal)
		for tool = 1, 5 do
			part(
				garage,
				"Tool",
				Vector3.new(0.3, 2, 0.3),
				origin + Vector3.new(-15 + tool * 2, 7, 17),
				colors.ink,
				Enum.Material.Metal
			)
		end
		local depot =
			part(garage, "Unload", Vector3.new(13, 0.25, 10), origin + Vector3.new(0, 1.7, -10), colors.teal)
		sign(
			garage,
			"UnloadLabel",
			origin + Vector3.new(0, 3, -14),
			Vector3.new(10, 1.6, 0.4),
			"СДАТЬ / UNLOAD"
		)
		local shop =
			part(garage, "PartsShop", Vector3.new(5, 5, 4), origin + Vector3.new(14, 4, 11), colors.rust)
		sign(
			garage,
			"PartsLabel",
			origin + Vector3.new(14, 7.5, 9),
			Vector3.new(8, 2, 0.4),
			"ДЕТАЛИ / PARTS"
		)
		for shelf = 1, 3 do
			part(
				garage,
				"Shelf",
				Vector3.new(7, 0.4, 3),
				origin + Vector3.new(14, 3 + shelf * 2, 16),
				colors.wood
			)
		end
		local bulb = part(
			garage,
			"WarmLight",
			Vector3.new(3, 0.3, 1),
			origin + Vector3.new(0, 16, 2),
			Color3.fromRGB(255, 218, 151),
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Color = bulb.Color
		light.Brightness = 1.5
		light.Range = 26
		light.Parent = bulb
		self.garages[i] =
			{ model = garage, origin = origin, bench = bench, depot = depot, shop = shop, board = board }
	end
	-- Prototype exploration route: abandoned electronics shop and sorting yard.
	part(
		root,
		"ShopFloor",
		Vector3.new(65, 1, 45),
		Vector3.new(-68, 1, -40),
		colors.cream,
		Enum.Material.Concrete
	)
	part(root, "ShopBack", Vector3.new(65, 18, 1), Vector3.new(-68, 10, -62), colors.rust)
	part(root, "ShopSide", Vector3.new(1, 18, 45), Vector3.new(-100, 10, -40), colors.cream)
	sign(
		root,
		"ShopSign",
		Vector3.new(-68, 16, -62),
		Vector3.new(36, 4, 1),
		"SECOND CHANCE\nБЫВШАЯ ЭЛЕКТРОНИКА",
		colors.teal
	)
	for row = 1, 3 do
		part(root, "ShopShelf", Vector3.new(40, 3, 3), Vector3.new(-68, 3, -60 + row * 10), colors.wood)
	end
	part(
		root,
		"SortingYard",
		Vector3.new(80, 0.4, 65),
		Vector3.new(70, 1, -65),
		colors.sand,
		Enum.Material.Concrete
	)
	sign(
		root,
		"YardSign",
		Vector3.new(70, 10, -98),
		Vector3.new(35, 5, 1),
		"REPAIR • REUSE\nПУНКТ СОРТИРОВКИ",
		colors.rust
	)
	for i = 1, 12 do
		local x = i <= 6 and (-88 + (i - 1) % 3 * 20) or (48 + (i - 1) % 3 * 20)
		local z = i <= 6 and (-26 - math.floor((i - 1) / 3) * 25) or (-45 - math.floor((i - 7) / 3) * 30)
		self.spots[i] = { position = Vector3.new(x, 2.3, z), readyAt = 0 }
	end
	for i = 1, 24 do
		local angle = i / 24 * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 150, 0, math.sin(angle) * 120)
		part(
			root,
			"TreeTrunk",
			Vector3.new(2, 9, 2),
			pos + Vector3.new(0, 5, 0),
			colors.wood,
			Enum.Material.Wood
		)
		local crown =
			part(root, "TreeCrown", Vector3.new(12, 15, 12), pos + Vector3.new(0, 15, 0), colors.grass)
		crown.Shape = Enum.PartType.Ball
		crown.CanCollide = false
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "VillageSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 2, 70)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Parent = root
	return root
end

function World:assign(player)
	for index, garage in ipairs(self.garages) do
		if not garage.owner then
			garage.owner = player
			player:SetAttribute("GarageIndex", index)
			garage.board.SurfaceGui.TextLabel.Text = player.DisplayName .. "\nГАРАЖ / GARAGE " .. index
			garage.model:SetAttribute("OwnerUserId", player.UserId)
			return garage
		end
	end
	return nil
end

function World:getGarage(player)
	for _, garage in ipairs(self.garages) do
		if garage.owner == player then
			return garage
		end
	end
	return nil
end

function World:release(player)
	local garage = self:getGarage(player)
	if garage then
		garage.owner = nil
		garage.board.SurfaceGui.TextLabel.Text = "ГАРАЖ / GARAGE"
		garage.model:SetAttribute("OwnerUserId", nil)
	end
end

function World:near(player, object)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and (root.Position - object.Position).Magnitude <= 13
end

function World:container(position, category)
	local model = Instance.new("Model")
	model.Name = "Forgotten " .. category
	model.Parent = self.root
	local box = part(
		model,
		"Find",
		Vector3.new(3.8, 2.8, 3),
		position,
		category == "toy" and colors.rust or colors.teal,
		Enum.Material.Wood
	)
	for _, x in ipairs({ -1.1, 1.1 }) do
		part(model, "Strap", Vector3.new(0.22, 2.9, 3.1), position + Vector3.new(x, 0, 0), colors.sand)
	end
	sign(
		model,
		"Label",
		position + Vector3.new(0, 0, -1.55),
		Vector3.new(2.5, 1.2, 0.1),
		category == "toy" and "TOY\n?" or "TECH\n?"
	)
	model.PrimaryPart = box
	return model, box
end

function World:itemVisual(kind, position, color)
	local model = Instance.new("Model")
	model.Name = "Restoring_" .. kind
	part(model, "Body", Vector3.new(3, 1.6, 2), position, color)
	if kind == "toycar" then
		part(model, "Cab", Vector3.new(1.5, 1, 1.8), position + Vector3.new(0.2, 1, 0), color)
		for _, x in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -1.1, 1.1 }) do
				local wheel = part(
					model,
					"Wheel",
					Vector3.new(0.7, 0.7, 0.4),
					position + Vector3.new(x, -0.7, z),
					colors.ink
				)
				wheel.Shape = Enum.PartType.Ball
			end
		end
	elseif kind == "lamp" then
		part(model, "Stem", Vector3.new(0.25, 2.5, 0.25), position + Vector3.new(0, 1.6, 0), colors.ink)
		part(model, "Shade", Vector3.new(2.4, 1.2, 2.4), position + Vector3.new(0, 3.2, 0), color)
	elseif kind == "fan" then
		local fan =
			part(model, "Fan", Vector3.new(2.8, 2.8, 0.7), position + Vector3.new(0, 2, 0), colors.cream)
		fan.Shape = Enum.PartType.Ball
		part(model, "Blade", Vector3.new(2, 0.3, 0.8), position + Vector3.new(0, 2, -0.5), color)
	else
		part(model, "Dial", Vector3.new(0.7, 0.7, 0.2), position + Vector3.new(0.8, 0, -1.1), colors.cream)
		part(model, "Speaker", Vector3.new(1.2, 1, 0.2), position + Vector3.new(-0.6, 0, -1.1), colors.ink)
		part(model, "Antenna", Vector3.new(0.1, 2, 0.1), position + Vector3.new(1, 1.8, 0), colors.ink)
	end
	return model
end

return World
