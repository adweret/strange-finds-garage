return function()
	local TestEZ = require(game:GetService("ServerStorage").TestEZ)
	local results = TestEZ.TestBootstrap:run({ script.Parent.Cases })
	assert(results.successCount + results.failureCount > 0, "No tests ran")
	assert(results.failureCount == 0, "Tests failed")
	assert(#results.errors == 0, "Test runner errors")
	return { passed = results.successCount, failed = results.failureCount, skipped = results.skippedCount }
end
