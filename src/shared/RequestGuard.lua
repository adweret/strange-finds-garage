local RequestGuard = {}
local contracts = {}
for _, action in ipairs({
	"Sync",
	"Deposit",
	"Advance",
	"BuyPart",
	"RecallVehicle",
	"ResetVehicle",
	"Scan",
	"OpenWorkbench",
	"OpenShop",
}) do
	contracts[action] = {}
end
for _, action in ipairs({ "Upgrade", "VehicleProject", "SpawnVehicle", "Order", "Theme", "Paint", "BuyPass" }) do
	contracts[action] = { key = "string" }
end
for _, action in ipairs({
	"Queue",
	"Display",
	"Install",
	"Select",
	"BeginRepair",
	"FinishRepair",
	"Sell",
	"Dismantle",
}) do
	contracts[action] = { id = "string" }
end
contracts.Language = { language = "string" }
contracts.Sprint = { enabled = "boolean" }

function RequestGuard.valid(action, args)
	if type(action) ~= "string" or not contracts[action] or (args ~= nil and type(args) ~= "table") then
		return false
	end
	local contract = contracts[action]
	for key, value in pairs(args or {}) do
		if not contract[key] or type(value) ~= contract[key] then
			return false
		end
		if type(value) == "string" and (#value == 0 or #value > 64) then
			return false
		end
	end
	for key in pairs(contract) do
		if not args or args[key] == nil then
			return false
		end
	end
	return true
end

return RequestGuard
