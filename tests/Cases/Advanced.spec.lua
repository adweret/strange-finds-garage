return function()
	local shared = game:GetService("ReplicatedStorage").Garage
	local Config = require(shared.Config)
	local Schema = require(shared.Schema)
	local base = require(shared.Rules).new(Config)
	local advanced = require(shared.AdvancedRules).new(Config, base)
	local NightBrain = require(shared.NightBrain)
	describe("Vehicle projects and equipment", function()
		it("restores and sells every configured find with its exact materials, timers and price", function()
			for kind, info in pairs(Config.Items) do
				local data = Schema.new()
				data.items = { { id = "all_" .. kind, kind = kind, stage = 0 } }
				local id, now = data.items[1].id, 100
				for stage = 0, 2 do
					expect(data.items[1].stage).to.equal(stage)
					expect(base:beginRepair(data, id, now)).to.equal(true)
					expect(data.repair.duration).to.equal(info.duration / 3)
					expect(base:finishRepair(data, id, now + info.duration / 3 - 0.01)).to.equal(false)
					expect(base:finishRepair(data, id, now + info.duration / 3 + 0.01)).to.equal(true)
					now += info.duration / 3 + 0.02
				end
				expect(data.parts).to.equal(8 - info.parts)
				expect(data.collection[kind]).to.equal(true)
				expect(base:sell(data, id)).to.equal(true)
				expect(data.coins).to.equal(50 + info.price)
				expect(#data.items).to.equal(0)
				expect(base:sell(data, id)).to.equal(false)
			end
		end)
		it("repairs bound gear outside inventory and rejects selling it", function()
			local data = Schema.new()
			advanced:issueEquipment(data)
			expect(base:sell(data, "equipment_radio")).to.equal(false)
			expect(base:dismantle(data, "equipment_radio")).to.equal(false)
			for stage = 0, 2 do
				expect(base:beginRepair(data, "equipment_radio", stage * 20)).to.equal(true)
				expect(base:finishRepair(data, "equipment_radio", stage * 20 + 10)).to.equal(true)
			end
			expect(data.equipment.radio).to.equal(true)
			expect(#data.items).to.equal(0)
			expect(data.collection.radio).to.equal(true)
			expect(data.parts).to.equal(6)
		end)
		it("keeps ordinary gear when its bound replacement is being repaired", function()
			for _, kind in ipairs({ "radio", "robot" }) do
				local data = Schema.new()
				advanced:issueEquipment(data)
				local bound = data.equipment[kind]
				local ordinary = { id = "ordinary_" .. kind, kind = kind, stage = 3 }
				data.items = { ordinary }
				expect(advanced:queue(data, bound.id)).to.equal(true)
				expect(base:beginRepair(data, bound.id, 100)).to.equal(true)
				local repair = data.repair
				local ok, reason = advanced:install(data, ordinary.id)
				expect(ok).to.equal(false)
				expect(reason).to.equal("repair_busy")
				expect(data.equipment[kind]).to.equal(bound)
				expect(data.repair).to.equal(repair)
				expect(data.items[1]).to.equal(ordinary)
				expect(#data.items).to.equal(1)
				expect(data.quests.repairQueue[1]).to.equal(bound.id)
				expect(data.parts).to.equal(8)
				expect(base:finishRepair(data, bound.id, 100 + Config.Items[kind].duration / 3 + 0.01)).to.equal(
					true
				)
			end
		end)
		it("removes replaced bound gear from the queue while preserving other entries", function()
			for _, kind in ipairs({ "radio", "robot" }) do
				local data = Schema.new()
				advanced:issueEquipment(data)
				local bound = data.equipment[kind]
				local otherKind = kind == "radio" and "robot" or "radio"
				local otherEquipment = data.equipment[otherKind]
				data.benchLevel = 3
				data.items = {
					{ id = "first", kind = "lamp", stage = 0 },
					{ id = "ordinary_" .. kind, kind = kind, stage = 3 },
					{ id = "last", kind = "fan", stage = 0 },
				}
				expect(advanced:queue(data, "first")).to.equal(true)
				expect(advanced:queue(data, bound.id)).to.equal(true)
				expect(advanced:queue(data, "last")).to.equal(true)
				expect(advanced:install(data, "ordinary_" .. kind)).to.equal(true)
				expect(data.equipment[kind]).to.equal(true)
				expect(data.equipment[otherKind]).to.equal(otherEquipment)
				expect(#data.items).to.equal(2)
				expect(data.items[1].id).to.equal("first")
				expect(data.items[2].id).to.equal("last")
				expect(#data.quests.repairQueue).to.equal(2)
				expect(data.quests.repairQueue[1]).to.equal("first")
				expect(data.quests.repairQueue[2]).to.equal("last")
				expect(data.repair).to.equal(nil)
				expect(base:find(data, bound.id)).to.equal(nil)
				expect(base:beginRepair(data, "first", 100)).to.equal(true)
			end
		end)
		it("bounds the preparation queue and frees a completed slot", function()
			local data = Schema.new()
			data.items = { { id = "a", kind = "toycar", stage = 2 }, { id = "b", kind = "lamp", stage = 0 } }
			expect(advanced:queue(data, "a")).to.equal(true)
			expect(advanced:queue(data, "b")).to.equal(false)
			base:beginRepair(data, "a", 0)
			base:finishRepair(data, "a", 5)
			expect(#data.quests.repairQueue).to.equal(0)
			expect(advanced:queue(data, "b")).to.equal(true)
			expect(advanced:queue(data, "b")).to.equal(true)
			expect(#data.quests.repairQueue).to.equal(0)
		end)
		it("does not block equipment lessons while the shared night task is pending", function()
			local data = Schema.new()
			data.quests.step = 6
			data.vehicles.cart = true
			data.quests.cartDelivered = 3
			expect(advanced:advance(data)).to.equal(true)
			expect(data.quests.step).to.equal(8)
			expect(data.equipment.robot.bound).to.equal(true)
			expect(data.quests.nightDone).to.equal(nil)
		end)
		it("charges a cart once and only unlocks after its timer", function()
			local data = Schema.new()
			data.coins = 450
			expect(advanced:vehicle(data, "cart", 100)).to.equal(true)
			expect(data.coins).to.equal(0)
			expect(data.parts).to.equal(4)
			expect(advanced:vehicle(data, "cart", 159)).to.equal(false)
			expect(advanced:vehicle(data, "cart", 160)).to.equal(true)
			expect(data.vehicles.cart).to.equal(true)
			expect(data.collection.cart).to.equal(true)
			expect(advanced:vehicle(data, "cart", 170)).to.equal(false)
			expect(data.coins).to.equal(0)
		end)
		it("requires tools for a buggy without charging on refusal", function()
			local data = Schema.new()
			data.coins = 10000
			data.parts = 100
			expect(advanced:vehicle(data, "buggy", 0)).to.equal(false)
			expect(data.coins).to.equal(10000)
		end)
		it("guarantees bound equipment even when storage is full", function()
			local data = Schema.new()
			for index = 1, 12 do
				table.insert(data.items, { id = tostring(index), kind = "lamp", stage = 0 })
			end
			advanced:issueEquipment(data)
			expect(data.equipment.radio.bound).to.equal(true)
			expect(data.equipment.robot.bound).to.equal(true)
			advanced:issueEquipment(data)
			expect(#data.items).to.equal(12)
		end)
		it("keeps one-time cache rewards from being farmed", function()
			local data = Schema.new()
			data.equipment.radio = true
			expect(advanced:cache(data, "cache1")).to.equal(true)
			expect(advanced:cache(data, "cache1")).to.equal(false)
			expect(data.parts).to.equal(10)
		end)
		it("does not consume a partial order", function()
			local data = Schema.new()
			data.vehicles.buggy = true
			data.items = { { id = "a", kind = "lamp", stage = 3 } }
			expect(advanced:order(data, "lamps", 0)).to.equal(false)
			expect(#data.items).to.equal(1)
		end)
		it("consumes a complete order once and applies its cooldown", function()
			local data = Schema.new()
			data.vehicles.buggy = true
			for index = 1, 3 do
				table.insert(data.items, { id = tostring(index), kind = "lamp", stage = 3 })
			end
			expect(advanced:order(data, "lamps", 100)).to.equal(true)
			expect(data.coins).to.equal(220)
			expect(#data.items).to.equal(0)
			expect(advanced:order(data, "lamps", 101)).to.equal(false)
		end)
	end)

	describe("Night target selection", function()
		local function actor(id, distance, visible, eligible)
			return {
				id = id,
				distance = distance,
				visible = visible,
				eligible = eligible,
				position = Vector3.new(distance, 0, 0),
			}
		end
		it("chooses the nearest eligible visible player", function()
			local brain = NightBrain.new()
			local mode, _, id = brain:step(
				0,
				{ actor(1, 10, true, true), actor(2, 2, true, false), actor(3, 5, true, true) },
				{}
			)
			expect(mode).to.equal("Chase")
			expect(id).to.equal(3)
		end)
		it("holds a target for three seconds and then can switch", function()
			local brain = NightBrain.new()
			brain:step(0, { actor(1, 10, true, true) }, {})
			local _, _, locked = brain:step(2, { actor(1, 10, true, true), actor(2, 3, true, true) }, {})
			expect(locked).to.equal(1)
			local _, _, nextTarget = brain:step(3, { actor(1, 10, true, true), actor(2, 3, true, true) }, {})
			expect(nextTarget).to.equal(2)
		end)
		it("abandons a hidden target after eight seconds", function()
			local brain = NightBrain.new()
			brain:step(0, { actor(1, 10, true, true) }, {})
			expect(brain:step(7.9, { actor(1, 10, false, true) }, {})).to.equal("Search")
			expect(brain:step(8, { actor(1, 10, false, true) }, {})).to.equal("Patrol")
		end)
		it("extends search from the target's latest audible noise, not each polling tick", function()
			local brain = NightBrain.new()
			brain:step(0, { actor(1, 10, true, true) }, {})
			local sounds =
				{ { ownerId = 1, at = 6, distance = 12, strength = 35, position = Vector3.new(12, 0, 0) } }
			expect(brain:step(10, { actor(1, 12, false, true) }, sounds)).to.equal("Search")
			expect(brain:step(13.9, { actor(1, 12, false, true) }, {})).to.equal("Search")
			expect(brain:step(14, { actor(1, 12, false, true) }, {})).to.equal("Patrol")
		end)
		it("releases a protected or disconnected target despite its lock", function()
			local brain = NightBrain.new()
			brain:step(0, { actor(1, 2, true, true) }, {})
			local mode, _, target = brain:step(1, { actor(1, 2, true, false) }, {})
			expect(mode).to.equal("Patrol")
			expect(target).to.equal(nil)
		end)
		it("ignores old and out-of-range noises", function()
			local brain = NightBrain.new()
			expect(brain:step(10, {}, { { at = 0, distance = 1, strength = 100, position = Vector3.zero } })).to.equal(
				"Patrol"
			)
			expect(
				brain:step(10, {}, { { at = 10, distance = 81, strength = 100, position = Vector3.zero } })
			).to.equal("Patrol")
			expect(
				brain:step(10, {}, { { at = 10, distance = 10, strength = 100, position = Vector3.zero } })
			).to.equal("Investigate")
		end)
	end)
end
