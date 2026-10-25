local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Garage
local Config = require(Shared.Config)
local NightBrain = require(Shared.NightBrain)
local Night = {}
Night.__index = Night

function Night.new(world, expansion, profiles, captured)
	local self = setmetatable({
		world = world,
		expansion = expansion,
		profiles = profiles,
		captured = captured,
		brain = NightBrain.new(),
		sounds = {},
		startAt = workspace:GetServerTimeNow(),
		night = false,
		patrolIndex = 1,
		waypoints = {},
		nextPathAt = 0,
		noiseAt = {},
		captureAt = {},
		lastTick = os.clock(),
	}, Night)
	local model = Instance.new("Model")
	model.Name = "NightCaretaker"
	local function block(name, size, position, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = position
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = model
		return p
	end
	local root = block("Root", Vector3.new(2.3, 3, 1.6), Vector3.new(0, 4.8, -80), Color3.fromRGB(38, 53, 58))
	model.PrimaryPart = root
	local footsteps = Instance.new("Sound")
	footsteps.Name = "CaretakerSteps"
	footsteps.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
	footsteps.Volume = 0.18
	footsteps.PlaybackSpeed = 0.7
	footsteps.Looped = true
	footsteps.RollOffMaxDistance = 45
	footsteps.Parent = root
	self.footsteps = footsteps
	block(
		"Head",
		Vector3.new(2.4, 2, 1.9),
		root.Position + Vector3.new(0, 2.6, 0),
		Color3.fromRGB(57, 73, 77)
	)
	for _, x in ipairs({ -0.55, 0.55 }) do
		local eye = block(
			"Eye",
			Vector3.new(0.35, 0.25, 0.15),
			root.Position + Vector3.new(x, 2.8, -1),
			Color3.fromRGB(242, 181, 91)
		)
		eye.Material = Enum.Material.Neon
	end
	for _, x in ipairs({ -1.65, 1.65 }) do
		block("Arm", Vector3.new(0.6, 3.7, 0.7), root.Position + Vector3.new(x, -0.1, 0), root.Color)
	end
	for _, x in ipairs({ -0.65, 0.65 }) do
		block("Leg", Vector3.new(0.65, 3, 0.75), root.Position + Vector3.new(x, -2.8, 0), root.Color)
	end
	self.model = model
	self.position = Vector3.new(0, 4.8, -80)
	self.atmosphere = Instance.new("Atmosphere")
	self.atmosphere.Density = 0.18
	self.atmosphere.Color = Color3.fromRGB(190, 207, 203)
	self.atmosphere.Parent = Lighting
	task.spawn(function()
		while self.model do
			self:tick()
			task.wait(0.15)
		end
	end)
	return self
end

function Night:noise(position, strength, ownerId)
	if self.night and not self.expansion:isSafe(position) then
		table.insert(
			self.sounds,
			{ position = position, strength = strength, at = os.clock(), ownerId = ownerId }
		)
	end
end

function Night:release(player)
	self.noiseAt[player] = nil
	self.captureAt[player] = nil
	for index = #self.sounds, 1, -1 do
		if self.sounds[index].ownerId == player.UserId then
			table.remove(self.sounds, index)
		end
	end
end

function Night:clock()
	local offset = RunService:IsStudio() and (workspace:GetAttribute("QATimeOffset") or 0) or 0
	local cycle = (workspace:GetServerTimeNow() - self.startAt + offset)
		% (Config.DaySeconds + Config.NightSeconds)
	local night = cycle >= Config.DaySeconds
	return night,
		math.floor((night and (Config.DaySeconds + Config.NightSeconds) or Config.DaySeconds) - cycle),
		cycle
end

function Night:visible(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.model }
	local ray = workspace:Raycast(
		self.position + Vector3.new(0, 2, 0),
		root.Position - self.position - Vector3.new(0, 2, 0),
		params
	)
	return not ray or ray.Instance:IsDescendantOf(player.Character)
end

function Night:tick()
	local tickAt = os.clock()
	local dt = math.min(0.3, tickAt - self.lastTick)
	self.lastTick = tickAt
	local night, remaining, cycle = self:clock()
	self.night = night
	workspace:SetAttribute("Night", night)
	workspace:SetAttribute("CycleRemaining", remaining)
	Lighting.ClockTime = night and (18 + (cycle - Config.DaySeconds) / Config.NightSeconds * 12) % 24
		or 6 + cycle / Config.DaySeconds * 12
	Lighting.Brightness = night and 1 or 2
	self.atmosphere.Density = night and 0.32 or 0.18
	if not night then
		self.footsteps:Stop()
		self.model.Parent = nil
		if self.wasNight then
			self.brain = NightBrain.new()
			self.waypoints = {}
			self.sounds = {}
		end
		self.wasNight = false
		return
	end
	self.wasNight = true
	self.model.Parent = self.world.root
	if not self.footsteps.IsPlaying then
		self.footsteps:Play()
	end
	local actors = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local data = self.profiles:get(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if data and root and humanoid then
			local eligible = humanoid.Health > 0
				and data.quests.soldLamp
				and not self.expansion:isSafe(root.Position)
			table.insert(actors, {
				id = player.UserId,
				position = root.Position,
				distance = (root.Position - self.position).Magnitude,
				visible = eligible and self:visible(player),
				eligible = eligible,
			})
			if
				eligible
				and root.AssemblyLinearVelocity.Magnitude > 18
				and os.clock() - (self.noiseAt[player] or 0) > 1
			then
				self.noiseAt[player] = os.clock()
				self:noise(root.Position, humanoid.SeatPart and 80 or 35, player.UserId)
			end
		end
	end
	for index = #self.sounds, 1, -1 do
		local sound = self.sounds[index]
		if os.clock() - sound.at > 5 then
			table.remove(self.sounds, index)
		else
			sound.distance = (sound.position - self.position).Magnitude
		end
	end
	local mode, goal, targetId = self.brain:step(os.clock(), actors, self.sounds)
	self.model:SetAttribute("Mode", mode)
	self.model:SetAttribute("TargetUserId", targetId)
	local patrol = {
		Vector3.new(-30, 2, -80),
		Vector3.new(35, 2, -110),
		Vector3.new(95, 2, -40),
		Vector3.new(-65, 2, -20),
	}
	if not goal then
		goal = patrol[self.patrolIndex]
		if (self.position - goal).Magnitude < 7 then
			self.patrolIndex = self.patrolIndex % #patrol + 1
		end
	end
	if os.clock() >= self.nextPathAt then
		self.nextPathAt = os.clock() + 2
		local path = PathfindingService:CreatePath({
			AgentRadius = 2.5,
			AgentHeight = 8,
			AgentCanJump = false,
			Costs = { NoCaretaker = math.huge },
		})
		local ok = pcall(function()
			path:ComputeAsync(self.position, goal)
		end)
		self.waypoints = ok and path.Status == Enum.PathStatus.Success and path:GetWaypoints() or {}
		self.waypointIndex = 2
	end
	local waypoint = self.waypoints[self.waypointIndex or 2]
	local nextPoint = waypoint and waypoint.Position or goal
	local delta = Vector3.new(nextPoint.X - self.position.X, 0, nextPoint.Z - self.position.Z)
	if delta.Magnitude < 2 then
		self.waypointIndex = (self.waypointIndex or 2) + 1
	end
	if delta.Magnitude > 0.1 then
		local speed = mode == "Chase" and 13 or 8
		local nextPosition = self.position + delta.Unit * math.min(delta.Magnitude, speed * dt)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { self.model }
		params.RespectCanCollide = true
		local obstacle = workspace:Blockcast(
			CFrame.new(self.position),
			Vector3.new(2.6, 5.5, 1.8),
			nextPosition - self.position,
			params
		)
		if not obstacle and not self.expansion:isSafe(nextPosition) then
			self.position = Vector3.new(nextPosition.X, 4.8, nextPosition.Z)
			self.model:PivotTo(CFrame.lookAt(self.position, self.position + delta.Unit))
		end
	end
	if targetId then
		local player = Players:GetPlayerByUserId(targetId)
		local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if
			root
			and humanoid
			and humanoid.Health > 0
			and self.profiles:get(player)
			and self:visible(player)
			and not self.expansion:isSafe(root.Position)
			and (root.Position - self.position).Magnitude < 4
			and os.clock() - (self.captureAt[player] or 0) > 10
		then
			self.captureAt[player] = os.clock()
			self.captured(player)
		end
	end
end

return Night
