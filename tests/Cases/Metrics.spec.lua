return function()
	local shared = game:GetService("ReplicatedStorage").Garage
	local Metrics, Schema = require(shared.Metrics), require(shared.Schema)
	describe("Storage experiment cohort", function()
		it("requires two high-fullness observations five minutes apart", function()
			local data = Schema.new()
			data.playSeconds = 3600
			for index = 1, 11 do
				data.items[index] = {}
			end
			Metrics.sample(data, 12, 1000)
			Metrics.sample(data, 12, 1299)
			expect(data.quests.metrics.fullCount).to.equal(1)
			local events = Metrics.sample(data, 12, 1300)
			expect(data.quests.metrics.eligibleFullTwice).to.equal(true)
			expect(table.find(events, "EligibleStorageFullTwice") ~= nil).to.equal(true)
			expect(#Metrics.sample(data, 12, 1301)).to.equal(0)
		end)
		it("counts a returning player's eligibility once", function()
			local data = Schema.new()
			data.playSeconds = 3600
			expect(#Metrics.sample(data, 12, 1000)).to.equal(1)
			expect(#Metrics.sample(Schema.clone(data), 12, 2000)).to.equal(0)
		end)
		it("deduplicates storage blocks and checks the two minute exit window", function()
			local data = Schema.new()
			expect(#Metrics.blocked(data, 1000)).to.equal(1)
			expect(#Metrics.blocked(data, 1001)).to.equal(0)
			expect(#Metrics.leaving(data, 1122)).to.equal(0)
			expect(#Metrics.leaving(data, 1121)).to.equal(1)
			expect(#Metrics.leaving(data, 1121)).to.equal(0)
		end)
	end)
end
