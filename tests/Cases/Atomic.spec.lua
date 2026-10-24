return function()
	local shared = game:GetService("ReplicatedStorage").Garage
	local Atomic = require(shared.Atomic)
	local Schema = require(shared.Schema)
	local function profile()
		return {
			Data = Schema.new(),
			active = true,
			IsActive = function(self)
				return self.active
			end,
		}
	end
	describe("Session safety and atomic operations", function()
		it("rejects an absent or inactive profile", function()
			expect(Atomic.apply(nil, Schema.clone, function()
				error("must not execute")
			end, false)).to.equal(false)
			local p = profile()
			p.active = false
			expect(Atomic.apply(p, Schema.clone, function()
				error("must not execute")
			end, false)).to.equal(false)
		end)
		it("pauses economic changes during a persistence outage", function()
			local p = profile()
			expect(Atomic.apply(p, Schema.clone, function(data)
				data.coins = 0
				return true
			end, true)).to.equal(false)
			expect(p.Data.coins).to.equal(50)
		end)
		it("rolls back the whole operation on rejection or an exception", function()
			local p = profile()
			expect(Atomic.apply(p, Schema.clone, function(data)
				data.coins = 0
				return false
			end, false)).to.equal(false)
			expect(p.Data.coins).to.equal(50)
			expect(Atomic.apply(p, Schema.clone, function(data)
				data.coins = 0
				error("injected fault")
			end, false)).to.equal(false)
			expect(p.Data.coins).to.equal(50)
		end)
		it("rejects a yielding economic operation before committing", function()
			local p = profile()
			expect(Atomic.apply(p, Schema.clone, function(data)
				data.coins = 0
				coroutine.yield()
				return true
			end, false)).to.equal(false)
			expect(p.Data.coins).to.equal(50)
		end)
		it("does not commit after a session ends", function()
			local p = profile()
			expect(Atomic.apply(p, Schema.clone, function(data)
				data.coins = 0
				p.active = false
				return true
			end, false)).to.equal(false)
			expect(p.Data.coins).to.equal(50)
		end)
		it("commits related values together with one new revision", function()
			local p = profile()
			expect(Atomic.apply(p, Schema.clone, function(data)
				data.coins -= 10
				data.parts += 1
				return true
			end, false)).to.equal(true)
			expect(p.Data.coins).to.equal(40)
			expect(p.Data.parts).to.equal(9)
			expect(p.Data.revision).to.equal(1)
		end)
	end)
end
