local CarryVisual = { models = {} }

function CarryVisual:clear(player)
	local model = self.models[player]
	if model then
		model:Destroy()
		self.models[player] = nil
	end
end

function CarryVisual:update(player, item, inVehicle)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local old = self.models[player]
	if not item or inVehicle or not root then
		self:clear(player)
		return
	end
	if old and old.Parent == character and old:GetAttribute("ItemId") == item.id then
		return
	end
	self:clear(player)
	local model = Instance.new("Model")
	model.Name = "CarriedFind"
	model:SetAttribute("ItemId", item.id)
	local function piece(name, size, offset, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = root.CFrame * CFrame.new(offset)
		part.Color = color
		part.Material = Enum.Material.Wood
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		return part
	end
	model.PrimaryPart =
		piece("Crate", Vector3.new(2.5, 1.8, 1.8), Vector3.new(0, 0, -2.1), Color3.fromRGB(143, 102, 72))
	for _, x in ipairs({ -0.7, 0.7 }) do
		piece("Strap", Vector3.new(0.15, 1.85, 1.85), Vector3.new(x, 0, -2.1), Color3.fromRGB(215, 196, 152))
	end
	model.Parent = character
	self.models[player] = model
end

return CarryVisual
