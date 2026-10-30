-- Where a slime sits on a bench, a log or a stump, from rays dropped across it.
local Config = require("../../src/shared/Config")
local SeatShape = require("../../src/shared/SeatShape")

-- A grid of rays 0.5 apart over x in [-2.5, 2.5], z in [-1, 1]; `height(x, z)` is the hit (nil = ground).
local function grid(height: (number, number) -> number?): { SeatShape.Sample }
	local samples = {}
	for x = -2.5, 2.5, 0.5 do
		for z = -1, 1, 0.5 do
			local h = height(x, z)
			if h then
				table.insert(samples, { x = x, z = z, h = h })
			end
		end
	end
	return samples
end

return function(T)
	T.test("a backed bench: sit on the seat, face away from the back", function()
		-- seat at 1.3 over z < 0.6, the backrest (2.4 high) along z = 1
		local fit = SeatShape.fit(
			grid(function(_, z)
				return if z >= 0.75 then 2.4 else 1.3
			end),
			0.5
		)
		T.ok(fit ~= nil)
		T.ok(math.abs(fit.height - 1.3) < 0.01, "on the seat, not the backrest")
		T.ok(fit.z < 0.5, "the place is in front of the back")
		T.ok(fit.faceZ ~= nil and fit.faceZ < -0.9, "faces away from the back")
		T.ok(#fit.places >= 1 and #fit.places <= Config.Village.SeatMaxPlaces)
		for _, place in fit.places do
			T.ok(math.abs(place.z - fit.z) < 0.01, "places lie along the seat")
		end
	end)
	T.test("a log bench without a back seats several along its length and leaves facing to the caller", function()
		local fit = SeatShape.fit(
			grid(function()
				return 1.6
			end),
			0.5
		)
		T.ok(fit ~= nil)
		T.eq(fit.faceX, nil)
		T.eq(#fit.places, 2)
		T.ok(fit.places[1].x < fit.places[2].x, "spread along the long side")
	end)
	T.test("a stump seats one", function()
		local fit = SeatShape.fit(
			grid(function(x, z)
				return if math.abs(x) <= 0.5 and math.abs(z) <= 0.5 then 1 else nil
			end),
			0.5
		)
		T.ok(fit ~= nil)
		T.eq(#fit.places, 1)
	end)
	T.test("nothing low and flat is not a seat", function()
		T.eq(
			SeatShape.fit(
				grid(function()
					return 6
				end),
				0.5
			),
			nil
		)
	end)
end
