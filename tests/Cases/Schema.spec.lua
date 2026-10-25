return function()
	local Schema = require(game:GetService("ReplicatedStorage").Garage.Schema)
	describe("Profile schema", function()
		it("rejects malformed equipment and project timers", function()
			local data = Schema.new()
			data.equipment.robot = { id = "wrong", kind = "robot", stage = 0, bound = true }
			expect(Schema.migrate(data)).to.equal(nil)
			data = Schema.new()
			data.vehicles.cart = { readyAt = math.huge }
			expect(Schema.migrate(data)).to.equal(nil)
		end)
		it("keeps gear and currency while removing stale queue references", function()
			local data = Schema.new()
			data.equipment.radio = { id = "equipment_radio", kind = "radio", stage = 1, bound = true }
			data.quests.repairQueue = { "missing", "equipment_radio", "equipment_radio" }
			local migrated = Schema.migrate(data)
			expect(#migrated.quests.repairQueue).to.equal(1)
			expect(migrated.quests.repairQueue[1]).to.equal("equipment_radio")
			expect(migrated.coins).to.equal(50)
		end)
		it("preserves currency and items during migration", function()
			local old = Schema.new()
			old.schemaVersion = nil
			old.coins = 123
			old.parts = 9
			local migrated = Schema.migrate(old)
			expect(migrated.coins).to.equal(123)
			expect(migrated.schemaVersion).to.equal(1)
			expect(old.schemaVersion).to.equal(nil)
		end)
		it("is repeatable without giving additional starter rewards", function()
			local data = Schema.new()
			data.coins = 0
			local migrated = Schema.migrate(Schema.migrate(data))
			expect(migrated.coins).to.equal(0)
		end)
		it("rejects a future version without overwriting it", function()
			local data = Schema.new()
			data.schemaVersion = 999
			expect(Schema.migrate(data)).to.equal(nil)
			expect(data.schemaVersion).to.equal(999)
		end)
		it("rejects invalid currency, capacity and duplicate IDs", function()
			for _, value in ipairs({ -1, math.huge, 0.5 }) do
				local data = Schema.new()
				data.coins = value
				expect(Schema.migrate(data)).to.equal(nil)
			end
			local data = Schema.new()
			data.items = { { id = "a", kind = "fan", stage = 0 }, { id = "a", kind = "lamp", stage = 0 } }
			expect(Schema.migrate(data)).to.equal(nil)
		end)
	end)
end
