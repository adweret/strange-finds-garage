return function()
	local World = require(game:GetService("ServerScriptService").GarageServer.World)
	describe("Server distance allowance", function()
		local function actor(distance, health)
			local root = { Position = Vector3.new(distance, 0, 0) }
			local humanoid = { Health = health or 100 }
			return {
				Character = {
					FindFirstChild = function()
						return root
					end,
					FindFirstChildOfClass = function()
						return humanoid
					end,
				},
			}
		end
		it("accepts the mobile latency margin up to thirteen studs", function()
			expect(World:near(actor(13), { Position = Vector3.zero })).to.equal(true)
		end)
		it("rejects distant and dead players", function()
			expect(World:near(actor(13.1), { Position = Vector3.zero })).to.equal(false)
			expect(World:near(actor(5, 0), { Position = Vector3.zero })).to.equal(false)
		end)
	end)
end
