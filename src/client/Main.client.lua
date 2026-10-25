local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local Shared = ReplicatedStorage:WaitForChild("Garage")
local Config = require(Shared.Config)
local Locale = require(Shared.Locale)
local remotes = Shared:WaitForChild("Remotes")
local Request = remotes:WaitForChild("Request")
local player = Players.LocalPlayer
local data, selected, activePanel
local language = string.sub(player.LocaleId, 1, 2) == "ru" and "ru" or "en"
local colors = {
	bg = Color3.fromRGB(26, 39, 43),
	panel = Color3.fromRGB(36, 52, 56),
	muted = Color3.fromRGB(166, 184, 179),
	text = Color3.fromRGB(245, 234, 208),
	accent = Color3.fromRGB(236, 175, 103),
	teal = Color3.fromRGB(81, 145, 137),
}
local gui = Instance.new("ScreenGui")
gui.Name = "StrangeFindsHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(object, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 10)
	value.Parent = object
end
local function label(parent, name, text, size, position, textSize)
	local value = Instance.new("TextLabel")
	value.Name = name
	value.Text = text
	value.Size = size
	value.Position = position
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamMedium
	value.TextSize = textSize or 16
	value.TextColor3 = colors.text
	value.TextWrapped = true
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = parent
	return value
end
local function button(parent, text, size, position, callback, background)
	local value = Instance.new("TextButton")
	value.Text = text
	value.Size = size
	value.Position = position
	value.BackgroundColor3 = background or colors.teal
	value.TextColor3 = colors.text
	value.Font = Enum.Font.GothamMedium
	value.TextSize = 15
	value.TextWrapped = true
	value.AutoButtonColor = true
	value.Parent = parent
	corner(value, 8)
	value.Activated:Connect(callback)
	value.Activated:Connect(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/volume_slider.ogg"
		sound.Volume = 0.08
		sound.Parent = gui
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end)
	return value
end
local function t(key)
	return Locale.get(key, language)
end
local function send(action, args)
	Request:FireServer(action, args or {})
end

local top = Instance.new("Frame")
top.Size = UDim2.new(1, -32, 0, 88)
top.Position = UDim2.fromOffset(16, 12)
top.BackgroundColor3 = colors.bg
top.Parent = gui
corner(top)
local title = label(top, "Title", t("title"), UDim2.new(0.62, 0, 0, 26), UDim2.fromOffset(16, 10), 22)
local subtitle =
	label(top, "Subtitle", t("subtitle"), UDim2.new(0.65, 0, 0, 20), UDim2.fromOffset(16, 37), 11)
subtitle.TextColor3 = colors.muted
local stats = label(top, "Stats", t("loading"), UDim2.new(1, -32, 0, 22), UDim2.fromOffset(16, 60), 14)
button(top, "RU / EN", UDim2.fromOffset(88, 48), UDim2.new(1, -102, 0, 12), function()
	send("Language", { language = language == "ru" and "en" or "ru" })
end)

local quest = Instance.new("Frame")
quest.Position = UDim2.fromOffset(16, 110)
quest.Size = UDim2.new(0.42, 0, 0, 112)
quest.BackgroundColor3 = colors.bg
quest.Parent = gui
corner(quest)
local questLabel =
	label(quest, "Quest", t("loading"), UDim2.new(1, -24, 1, -20), UDim2.fromOffset(12, 10), 15)
local footer = label(gui, "Build", t("prototype"), UDim2.new(0.65, 0, 0, 34), UDim2.new(0, 16, 1, -44), 11)
footer.TextColor3 = colors.muted
local toast = label(gui, "Notice", "", UDim2.new(0.75, 0, 0, 60), UDim2.fromScale(0.125, 0.78), 17)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.BackgroundColor3 = colors.bg
toast.BackgroundTransparency = 0.08
toast.Visible = false
toast.ZIndex = 10
corner(toast)
local warning = label(gui, "Critical", "", UDim2.new(1, -32, 0, 65), UDim2.fromOffset(16, 230), 16)
warning.BackgroundColor3 = Color3.fromRGB(143, 63, 48)
warning.Visible = false
warning.ZIndex = 12
corner(warning)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.9, 0.66)
panel.Position = UDim2.fromScale(0.05, 0.25)
panel.BackgroundColor3 = colors.bg
panel.Visible = false
panel.ZIndex = 5
panel.Parent = gui
corner(panel)
local panelTitle = label(panel, "Title", "", UDim2.new(1, -120, 0, 48), UDim2.fromOffset(16, 0), 22)
button(panel, "×", UDim2.fromOffset(48, 48), UDim2.new(1, -56, 0, 4), function()
	panel.Visible = false
	activePanel = nil
end)
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -24, 1, -65)
content.Position = UDim2.fromOffset(12, 56)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 6
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = content
local progressLabel
local render
local prices = {}
local clockLabel = label(gui, "Clock", "", UDim2.new(0.46, 0, 0, 48), UDim2.new(0.47, 0, 0, 110), 15)
clockLabel.BackgroundColor3 = colors.bg
clockLabel.BackgroundTransparency = 0.12
corner(clockLabel)

local function row(height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, height)
	frame.BackgroundColor3 = colors.panel
	frame.Parent = content
	corner(frame, 8)
	return frame
end

local function actionRow(text, action, args)
	button(row(60), text, UDim2.new(1, -16, 1, -12), UDim2.fromOffset(8, 6), function()
		send(action, args)
	end)
end

local function renderPanel()
	for _, child in ipairs(content:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	progressLabel = nil
	if not data or not activePanel then
		return
	end
	panelTitle.Text = t(activePanel)
	if activePanel == "workbench" then
		local taskRow = row(64)
		button(taskRow, t("advance"), UDim2.new(1, -16, 1, -12), UDim2.fromOffset(8, 6), function()
			send("Advance")
		end, colors.teal)
		if #data.items == 0 then
			label(row(80), "Empty", t("empty"), UDim2.new(1, -20, 1, -12), UDim2.fromOffset(10, 6), 15)
		end
		local items = table.clone(data.items)
		for _, kind in ipairs({ "radio", "robot" }) do
			if type(data.equipment[kind]) == "table" then
				table.insert(items, data.equipment[kind])
			end
		end
		local queue = data.quests.repairQueue or {}
		table.sort(items, function(a, b)
			local left, right = table.find(queue, a.id) or 100, table.find(queue, b.id) or 100
			return left ~= right and left < right or (left == right and a.id < b.id)
		end)
		label(
			row(54),
			"Queue",
			t("queue") .. " " .. #queue .. "/" .. Config.BenchQueue[data.benchLevel],
			UDim2.new(1, -20, 1, 0),
			UDim2.fromOffset(10, 0),
			15
		)
		for _, item in ipairs(items) do
			local frame = row(item.id == selected and 296 or 64)
			local info = Config.Items[item.kind]
			label(
				frame,
				"Name",
				t(item.kind)
					.. "   "
					.. tostring(item.stage)
					.. "/3"
					.. (item.bound and " • " .. t("equipment") or ""),
				UDim2.new(0.64, 0, 0, 52),
				UDim2.fromOffset(12, 4),
				16
			)
			local itemId = item.id
			button(frame, t("select"), UDim2.new(0.29, 0, 0, 48), UDim2.new(0.68, 0, 0, 8), function()
				selected = itemId
				send("Select", { id = itemId })
				renderPanel()
			end)
			if item.id == selected then
				if item.stage < 3 then
					local repairing = data.repair and data.repair.id == itemId
					button(
						frame,
						repairing and t("finish") or t(({ "clean", "replace", "power" })[item.stage + 1]),
						UDim2.new(0.57, 0, 0, 48),
						UDim2.fromOffset(10, 62),
						function()
							send(repairing and "FinishRepair" or "BeginRepair", { id = itemId })
						end
					)
					progressLabel = label(
						frame,
						"Progress",
						tostring(info.parts) .. " " .. t("parts"),
						UDim2.new(0.37, 0, 0, 48),
						UDim2.new(0.61, 0, 0, 62),
						14
					)
				else
					button(
						frame,
						t("sell") .. " • " .. info.price,
						UDim2.new(0.57, 0, 0, 48),
						UDim2.fromOffset(10, 62),
						function()
							send("Sell", { id = itemId })
						end,
						colors.teal
					)
				end
				if not item.bound then
					button(
						frame,
						t("dismantle") .. " • +" .. info.parts .. " " .. t("parts"),
						UDim2.new(1, -20, 0, 48),
						UDim2.fromOffset(10, 120),
						function()
							send("Dismantle", { id = itemId })
						end,
						Color3.fromRGB(122, 82, 65)
					)
				end
				if item.stage < 3 then
					local queued = table.find(queue, itemId)
					button(
						frame,
						queued and (t("queued") .. " #" .. queued) or t("queueAdd"),
						UDim2.new(1, -20, 0, 48),
						UDim2.fromOffset(10, 178),
						function()
							send("Queue", { id = itemId })
						end
					)
				elseif
					(item.kind == "radio" or item.kind == "robot") and data.equipment[item.kind] ~= true
				then
					button(
						frame,
						t("install"),
						UDim2.new(1, -20, 0, 48),
						UDim2.fromOffset(10, 178),
						function()
							send("Install", { id = itemId })
						end
					)
				end
				if item.stage == 3 and not item.bound then
					button(
						frame,
						t("display"),
						UDim2.new(1, -20, 0, 48),
						UDim2.fromOffset(10, 236),
						function()
							send("Display", { id = itemId })
						end
					)
				end
			end
		end
	elseif activePanel == "shop" then
		local entries = {
			{ text = t("buyPart"), action = "BuyPart" },
			{
				text = t("storageUpgrade") .. " • " .. tostring(
					Config.StoragePrices[data.storageLevel] or "MAX"
				),
				action = "Upgrade",
				key = "storage",
			},
			{ text = t("toolsUpgrade"), action = "Upgrade", key = "tools" },
			{
				text = t("benchUpgrade") .. " • " .. tostring(Config.BenchPrices[data.benchLevel] or "MAX"),
				action = "Upgrade",
				key = "bench",
			},
		}
		for _, entry in ipairs(entries) do
			local value = entry
			button(row(60), value.text, UDim2.new(1, -16, 1, -12), UDim2.fromOffset(8, 6), function()
				send(value.action, { key = value.key })
			end)
		end
		for _, key in ipairs({ "rust", "workshop", "observatory" }) do
			actionRow(t(key) .. " • " .. Config.Themes[key], "Upgrade", { key = key })
		end
		if data.vehicles.buggy == true then
			for _, key in ipairs({ "lamps", "radiofan", "generator" }) do
				local seconds = math.max(0, math.ceil((data.orders[key] or 0) - workspace:GetServerTimeNow()))
				actionRow(
					t("order_" .. key)
						.. " • "
						.. Config.Orders[key].reward
						.. (seconds > 0 and (" • " .. math.ceil(seconds / 60) .. " min") or ""),
					"Order",
					{ key = key }
				)
			end
		end
		for _, pass in ipairs(data.passes or {}) do
			local info = pass
			actionRow(
				t("pass_" .. info.key)
					.. " • "
					.. (
						info.owned and "✓"
						or (prices[info.id] and (prices[info.id] .. " R$") or t("loadingPrice"))
					),
				"BuyPass",
				{ key = info.key }
			)
			if not prices[info.id] then
				prices[info.id] = t("loadingPrice")
				task.spawn(function()
					local ok, product = pcall(function()
						return MarketplaceService:GetProductInfoAsync(info.id, Enum.InfoType.GamePass)
					end)
					prices[info.id] = ok and product.PriceInRobux or t("not_available")
					if activePanel == "shop" then
						renderPanel()
					end
				end)
			end
		end
	elseif activePanel == "garage" then
		actionRow(t("workbench"), "OpenWorkbench")
		actionRow(t("shop"), "OpenShop")
		for _, kind in ipairs({ "cart", "buggy" }) do
			local info, project = Config.Vehicles[kind], data.vehicles[kind]
			if project == true then
				actionRow(t("spawn") .. " " .. t(kind), "SpawnVehicle", { key = kind })
			elseif type(project) == "table" then
				local seconds = math.max(0, math.ceil(project.readyAt - workspace:GetServerTimeNow()))
				actionRow(
					t("finish") .. " " .. t(kind) .. " • " .. seconds .. " s",
					"VehicleProject",
					{ key = kind }
				)
			else
				actionRow(
					t("build")
						.. " "
						.. t(kind)
						.. " • "
						.. info.coins
						.. " + "
						.. info.parts
						.. " "
						.. t("parts"),
					"VehicleProject",
					{ key = kind }
				)
			end
		end
		actionRow(t("recall"), "RecallVehicle")
		actionRow(t("resetVehicle"), "ResetVehicle")
		for _, key in ipairs({ "default", "mint", "rust", "workshop", "observatory" }) do
			if key == "default" or data.cosmetics[key] then
				actionRow(t("theme") .. " • " .. t(key), "Theme", { key = key })
			end
		end
		for _, pass in ipairs(data.passes or {}) do
			if pass.key == "paint" and pass.owned then
				for _, key in ipairs({ "mint", "plum", "cream" }) do
					actionRow(t("paint") .. " • " .. t(key), "Paint", { key = key })
				end
			end
		end
	elseif activePanel == "catalog" then
		local entries = table.clone(Config.CatalogOrder)
		table.insert(entries, "cart")
		table.insert(entries, "buggy")
		for _, kind in ipairs(entries) do
			local frame = row(54)
			label(
				frame,
				"Entry",
				(data.collection[kind] and "✓  " or "○  ") .. t(kind),
				UDim2.new(1, -20, 1, 0),
				UDim2.fromOffset(10, 0),
				16
			)
		end
	end
end

render = function()
	if not data then
		return
	end
	if data.language ~= "auto" then
		language = data.language
	end
	title.Text = t("title")
	subtitle.Text = t("subtitle")
	stats.Text = string.format(
		"%s  %d    •    %s  %d    •    %s  %d/%d    •    %s  %d/%d",
		t("coins"),
		data.coins,
		t("parts"),
		data.parts,
		t("storage"),
		#data.items,
		data.capacity,
		t("cargo"),
		#data.cargo,
		data.cargoCapacity or 1
	)
	questLabel.Text = t("q" .. data.quests.step)
	footer.Text = t(data.prototype and "prototype" or "alpha") .. (data.mock and "  |  " .. t("mock") or "")
	warning.Visible = data.critical
	warning.Text = t("critical")
	renderPanel()
end

local catalogButton = button(gui, "▦", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0, 110), function()
	activePanel = "catalog"
	panel.Visible = true
	renderPanel()
end)
local unloadButton = button(gui, "↓", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0, 170), function()
	send("Deposit")
end)
local garageButton = button(gui, "⚙", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0, 230), function()
	activePanel = "garage"
	panel.Visible = true
	renderPanel()
end)
local scanButton = button(gui, "◎", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0, 290), function()
	send("Scan")
end)
local sprint = false
local sprintButton = button(gui, "»", UDim2.fromOffset(52, 52), UDim2.new(1, -128, 0, 290), function()
	sprint = not sprint
	send("Sprint", { enabled = sprint })
end)

remotes:WaitForChild("State").OnClientEvent:Connect(function(payload)
	data = payload
	render()
end)
remotes:WaitForChild("Open").OnClientEvent:Connect(function(which)
	activePanel = which
	panel.Visible = true
	renderPanel()
end)
local toastSerial = 0
remotes:WaitForChild("Notice").OnClientEvent:Connect(function(key)
	toastSerial += 1
	local serial = toastSerial
	toast.Text = t(key)
	toast.Visible = true
	task.delay(4, function()
		if toastSerial == serial then
			toast.Visible = false
		end
	end)
end)
RunService.RenderStepped:Connect(function()
	top.Visible = not panel.Visible
	quest.Visible = not panel.Visible
	clockLabel.Visible = not panel.Visible
	local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
	if touchGui then
		touchGui.Enabled = not panel.Visible
	end
	local compact = workspace.CurrentCamera.ViewportSize.Y < 500
	quest.Size = UDim2.new(compact and 0.48 or 0.42, 0, 0, compact and 100 or 112)
	questLabel.TextSize = compact and 12 or 15
	title.TextSize = compact and 18 or 22
	stats.TextSize = compact and 11 or 14
	clockLabel.Position = UDim2.new(compact and 0.52 or 0.47, 0, 0, compact and 104 or 110)
	clockLabel.Size = UDim2.new(0.46, 0, 0, compact and 58 or 62)
	clockLabel.TextSize = compact and 12 or 15
	footer.Visible = not compact
	panel.Position = UDim2.fromScale(0.05, compact and 0.05 or 0.25)
	panel.Size = UDim2.fromScale(0.9, compact and 0.9 or 0.66)
	for index, control in ipairs({ catalogButton, unloadButton, garageButton, scanButton, sprintButton }) do
		control.Visible = not panel.Visible
		if compact then
			control.Position = UDim2.new(1, -68 - (index - 1) * 60, 0, 168)
		elseif index < 5 then
			control.Position = UDim2.new(1, -68, 0, 50 + index * 60)
		else
			control.Position = UDim2.new(1, -128, 0, 290)
		end
	end
	local remaining = workspace:GetAttribute("CycleRemaining") or 480
	clockLabel.Text = (workspace:GetAttribute("Night") and t("night") or t("day"))
		.. " • "
		.. string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
	if data and data.quests.soldLamp and not data.quests.nightDone then
		clockLabel.Text ..= "\n" .. t("nightTaskHint")
	end
	if data and data.repair and progressLabel and progressLabel.Parent then
		local repairRemaining =
			math.max(0, data.repair.duration - (workspace:GetServerTimeNow() - data.repair.startedAt))
		progressLabel.Text = repairRemaining > 0 and string.format("%.1f s", repairRemaining) or "✓"
	end
end)
local driveKeys, touchThrottle, touchSteer = {}, 0, 0
local heldDriveControls = {}
local function updateTouchDrive()
	touchThrottle, touchSteer = 0, 0
	for _, control in pairs(heldDriveControls) do
		touchThrottle += control[4]
		touchSteer += control[5]
	end
	touchThrottle = math.clamp(touchThrottle, -1, 1)
	touchSteer = math.clamp(touchSteer, -1, 1)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	driveKeys[input.KeyCode] = true
	if input.KeyCode == Enum.KeyCode.LeftShift then
		send("Sprint", { enabled = true })
	end
end)
UserInputService.InputEnded:Connect(function(input)
	heldDriveControls[input] = nil
	updateTouchDrive()
	driveKeys[input.KeyCode] = nil
	if input.KeyCode == Enum.KeyCode.LeftShift then
		send("Sprint", { enabled = false })
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	table.clear(driveKeys)
	table.clear(heldDriveControls)
	updateTouchDrive()
	send("Sprint", { enabled = false })
end)
local driveFrame = Instance.new("Frame")
driveFrame.Name = "Driving"
driveFrame.BackgroundTransparency = 1
driveFrame.Size = UDim2.fromOffset(172, 112)
driveFrame.Position = UDim2.new(1, -190, 1, -220)
driveFrame.Visible = false
driveFrame.Parent = gui
for _, control in ipairs({
	{ "▲", 60, 0, 1, 0 },
	{ "▼", 60, 60, -1, 0 },
	{ "◀", 0, 60, 0, -1 },
	{ "▶", 120, 60, 0, 1 },
}) do
	local b = button(
		driveFrame,
		control[1],
		UDim2.fromOffset(52, 52),
		UDim2.fromOffset(control[2], control[3]),
		function() end
	)
	b.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			heldDriveControls[input] = control
			updateTouchDrive()
		end
	end)
	b.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			heldDriveControls[input] = nil
			updateTouchDrive()
		end
	end)
end
task.spawn(function()
	local drive = remotes:WaitForChild("Drive", 15)
	if not drive then
		return
	end
	while true do
		task.wait(0.1)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local seated = humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat")
		driveFrame.Visible = seated and UserInputService.TouchEnabled and not panel.Visible or false
		if seated then
			local throttle = touchThrottle
				+ (driveKeys[Enum.KeyCode.W] and 1 or 0)
				- (driveKeys[Enum.KeyCode.S] and 1 or 0)
			local steer = touchSteer
				+ (driveKeys[Enum.KeyCode.D] and 1 or 0)
				- (driveKeys[Enum.KeyCode.A] and 1 or 0)
			drive:FireServer(
				panel.Visible and 0 or math.clamp(throttle, -1, 1),
				panel.Visible and 0 or math.clamp(steer, -1, 1)
			)
		else
			table.clear(heldDriveControls)
			touchThrottle, touchSteer = 0, 0
		end
	end
end)
task.spawn(function()
	local signal = remotes:WaitForChild("Signal", 15)
	if not signal then
		return
	end
	signal.OnClientEvent:Connect(function(position)
		local marker = Instance.new("Part")
		marker.Name = "RadioSignal"
		marker.Size = Vector3.new(1, 18, 1)
		marker.Position = position + Vector3.new(0, 9, 0)
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.Material = Enum.Material.Neon
		marker.Color = colors.accent
		marker.Transparency = 0.3
		marker.Parent = workspace
		game:GetService("Debris"):AddItem(marker, 8)
	end)
end)
send("Sync")
task.spawn(function()
	while true do
		task.wait(5)
		send("Sync")
	end
end)
