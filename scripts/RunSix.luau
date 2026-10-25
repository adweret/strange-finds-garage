-- Execute in the Studio Command Bar in Edit mode with the test build loaded.
local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(6, "GarageSix")
assert(type(result) == "table" and result.ok, type(result) == "table" and result.error or "No result")
print("[Garage Six Result]", result.ok, result.clients)
