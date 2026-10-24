local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(rate, burst)
	return setmetatable({ rate = rate, burst = burst, buckets = {} }, RateLimiter)
end

function RateLimiter:allow(key, now)
	local bucket = self.buckets[key] or { tokens = self.burst, at = now }
	bucket.tokens = math.min(self.burst, bucket.tokens + math.max(0, now - bucket.at) * self.rate)
	bucket.at = now
	self.buckets[key] = bucket
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RateLimiter:remove(key)
	self.buckets[key] = nil
end

return RateLimiter
