local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

local function row(height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, height)
	frame.BackgroundColor3 = colors.panel
	frame.Parent = content
	corner(frame, 8)
	return frame
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
		for _, item in ipairs(data.items) do
			local frame = row(item.id == selected and 180 or 64)
			local info = Config.Items[item.kind]
			label(
				frame,
				"Name",
				t(item.kind) .. "   " .. tostring(item.stage) .. "/3",
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
		}
		for _, entry in ipairs(entries) do
			local value = entry
			button(row(60), value.text, UDim2.new(1, -16, 1, -12), UDim2.fromOffset(8, 6), function()
				send(value.action, { key = value.key })
			end)
		end
	elseif activePanel == "catalog" then
		for _, kind in ipairs(Config.CatalogOrder) do
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
		"%s  %d    •    %s  %d    •    %s  %d/%d    •    %s  %d/1",
		t("coins"),
		data.coins,
		t("parts"),
		data.parts,
		t("storage"),
		#data.items,
		data.capacity,
		t("cargo"),
		#data.cargo
	)
	questLabel.Text = t("q" .. math.min(data.quests.step, 6))
	footer.Text = t("prototype") .. (data.mock and "  |  " .. t("mock") or "")
	warning.Visible = data.critical
	warning.Text = t("critical")
	renderPanel()
end

button(gui, "▦", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0, 110), function()
	activePanel = "catalog"
	panel.Visible = true
	renderPanel()
end)
button(gui, "↓", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0, 170), function()
	send("Deposit")
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
	if data and data.repair and progressLabel and progressLabel.Parent then
		local remaining =
			math.max(0, data.repair.duration - (workspace:GetServerTimeNow() - data.repair.startedAt))
		progressLabel.Text = remaining > 0 and string.format("%.1f s", remaining) or "✓"
	end
end)
send("Sync")
task.spawn(function()
	while true do
		task.wait(5)
		send("Sync")
	end
end)
