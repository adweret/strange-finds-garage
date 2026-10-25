return function()
	local SessionStart = require(game:GetService("ReplicatedStorage").Garage.SessionStart)
	describe("Profile startup failure boundary", function()
		local function playerFixture()
			local players = {}
			local player = { Parent = players }
			function player:Kick(message)
				self.kicked = message
			end
			return player, players
		end
		it("disconnects a connected player after an error or nil session", function()
			for _, throws in ipairs({ false, true }) do
				local player, players = playerFixture()
				local store = {
					StartSessionAsync = function()
						if throws then
							error("simulated DataStore outage")
						end
						return nil
					end,
				}
				expect(SessionStart.run(store, "alpha:1", player, players)).to.equal(nil)
				expect(type(player.kicked)).to.equal("string")
			end
		end)
		it("cancels and releases a session if the player leaves during loading", function()
			local player, players = playerFixture()
			local ended = false
			local profile = {
				IsActive = function()
					return true
				end,
				EndSession = function()
					ended = true
				end,
			}
			local store = {
				StartSessionAsync = function(_, _, params)
					player.Parent = nil
					expect(params.Cancel()).to.equal(true)
					return profile
				end,
			}
			expect(SessionStart.run(store, "alpha:1", player, players)).to.equal(nil)
			expect(ended).to.equal(true)
			expect(player.kicked).to.equal(nil)
		end)
		it("never exposes an inactive session as a writable profile", function()
			local player, players = playerFixture()
			local ended = false
			local profile = {
				IsActive = function()
					return false
				end,
				EndSession = function()
					ended = true
				end,
			}
			local store = {
				StartSessionAsync = function()
					return profile
				end,
			}
			expect(SessionStart.run(store, "alpha:1", player, players)).to.equal(nil)
			expect(ended).to.equal(true)
			expect(type(player.kicked)).to.equal("string")
		end)
	end)
end
