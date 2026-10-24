return function()
	local shared = game:GetService("ReplicatedStorage").Garage
	local Config = require(shared.Config)
	local Schema = require(shared.Schema)
	local rules = require(shared.Rules).new(Config)
	local function item(data, id, kind, stage)
		table.insert(data.items, { id = id, kind = kind, stage = stage or 0 })
	end
	local function restore(data, id)
		for stage = 1, 3 do
			expect(rules:beginRepair(data, id, stage * 100)).to.equal(true)
			expect(rules:finishRepair(data, id, stage * 100 + 30)).to.equal(true)
		end
	end

	describe("Economy and ownership", function()
		it("rejects duplicate IDs within a deposit", function()
			local data = Schema.new()
			expect(
				rules:deposit(
					data,
					{ { id = "same", kind = "lamp" }, { id = "same", kind = "radio" } },
					false
				)
			).to.equal(false)
			expect(#data.items).to.equal(0)
		end)
		it("rejects depositing an item already in storage", function()
			local data = Schema.new()
			item(data, "a", "lamp")
			expect(rules:deposit(data, { { id = "a", kind = "lamp" } }, false)).to.equal(false)
		end)
		it("rejects a full warehouse without consuming cargo", function()
			local data = Schema.new()
			for index = 1, 12 do
				item(data, tostring(index), "lamp")
			end
			expect(rules:deposit(data, { { id = "extra", kind = "lamp" } }, false)).to.equal(false)
			expect(#data.items).to.equal(12)
		end)
		it("never grants coins for selling the same ID twice", function()
			local data = Schema.new()
			item(data, "a", "lamp", 3)
			expect(rules:sell(data, "a")).to.equal(true)
			expect(rules:sell(data, "a")).to.equal(false)
			expect(data.coins).to.equal(95)
		end)
		it("does not register a dismantled fan", function()
			local data = Schema.new()
			item(data, "a", "fan")
			expect(rules:dismantle(data, "a")).to.equal(true)
			expect(data.parts).to.equal(10)
			expect(data.collection.fan).to.equal(nil)
		end)
		it("only registers an item after all three timed stages", function()
			local data = Schema.new()
			item(data, "a", "toycar")
			expect(rules:beginRepair(data, "a", 100)).to.equal(true)
			expect(rules:finishRepair(data, "a", 101)).to.equal(false)
			expect(data.collection.toycar).to.equal(nil)
			expect(rules:finishRepair(data, "a", 105)).to.equal(true)
			for stage = 2, 3 do
				expect(rules:beginRepair(data, "a", stage * 100)).to.equal(true)
				expect(rules:finishRepair(data, "a", stage * 100 + 5)).to.equal(true)
			end
			expect(data.parts).to.equal(7)
			expect(data.collection.toycar).to.equal(true)
		end)
		it("rejects repairs without parts and never makes parts negative", function()
			local data = Schema.new()
			data.parts = 0
			item(data, "a", "radio", 1)
			expect(rules:beginRepair(data, "a", 0)).to.equal(false)
			expect(data.parts).to.equal(0)
		end)
		it("does not spend coins for an unaffordable upgrade", function()
			local data = Schema.new()
			expect(rules:upgrade(data, "storage")).to.equal(false)
			expect(data.coins).to.equal(50)
			expect(data.storageLevel).to.equal(1)
		end)
		it("caps the warehouse at 60 with its pass", function()
			local data = Schema.new()
			data.storageLevel = 3
			expect(rules:capacity(data, true)).to.equal(60)
		end)
	end)

	describe("Guaranteed tutorial", function()
		it("restores all four distinct kinds without relying on drops", function()
			local data = Schema.new()
			item(data, "car", "toycar")
			restore(data, "car")
			expect(rules:advance(data, "lamp")).to.equal(true)
			restore(data, "lamp")
			rules:sell(data, "lamp")
			expect(rules:advance(data, "fan1")).to.equal(true)
			rules:dismantle(data, "fan1")
			expect(data.collection.fan).to.equal(nil)
			expect(rules:advance(data, "unused")).to.equal(true)
			rules:buyPart(data)
			expect(rules:advance(data, "fan2")).to.equal(true)
			restore(data, "fan2")
			expect(rules:advance(data, "radio")).to.equal(true)
			restore(data, "radio")
			expect(rules:advance(data, "unused2")).to.equal(true)
			expect(data.quests.step).to.equal(6)
			expect(data.cosmetics.shelf).to.equal(true)
		end)
		it("issues a tutorial item once", function()
			local data = Schema.new()
			expect(rules:issue(data, "lamp", "lamp", "a")).to.equal(true)
			expect(rules:issue(data, "lamp", "lamp", "b")).to.equal(false)
			expect(#data.items).to.equal(1)
		end)
	end)

	describe("Storage pass gate", function()
		it("remains disabled with insufficient data", function()
			expect(rules:storageGate({ eligible = 29, fullTwice = 20, blocked = 20, quitAfterBlock = 0 })).to.equal(
				false
			)
		end)
		it("requires the fullness and churn thresholds", function()
			expect(rules:storageGate({ eligible = 40, fullTwice = 14, blocked = 20, quitAfterBlock = 2 })).to.equal(
				true
			)
			expect(rules:storageGate({ eligible = 40, fullTwice = 14, blocked = 20, quitAfterBlock = 3 })).to.equal(
				false
			)
		end)
	end)
end
