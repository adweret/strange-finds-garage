return function()
	local TestEZ = require(game:GetService("ServerStorage").TestEZ)
	local finished, ok, results = false, false, nil
	local worker = task.spawn(function()
		ok, results = pcall(function()
			return TestEZ.TestBootstrap:run({ script.Parent.Cases })
		end)
		finished = true
	end)
	local deadline = os.clock() + 30
	while not finished and os.clock() < deadline do
		task.wait(0.05)
	end
	if not finished then
		task.cancel(worker)
		error("Test runner timed out after 30 seconds")
	end
	assert(ok, "Test runner exception: " .. tostring(results))
	assert(results.successCount + results.failureCount > 0, "No tests ran")
	assert(results.failureCount == 0, "Tests failed")
	assert(#results.errors == 0, "Test runner errors")
	return { passed = results.successCount, failed = results.failureCount, skipped = results.skippedCount }
end
