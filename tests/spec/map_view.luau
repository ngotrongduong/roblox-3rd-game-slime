local Config = require("../../src/shared/Config")
local MapView = require("../../src/shared/MapView")
local WorldPlan = require("../../src/shared/WorldPlan")

local M = Config.World.Map
local PIC = 1024

return function(T)
	T.test("uv: the picture's corners and middle", function()
		local u, v = MapView.uv(M.MinX, M.MinZ)
		T.eq(u, 0)
		T.eq(v, 0)
		u, v = MapView.uv(M.MinX + M.Size, M.MinZ + M.Size)
		T.eq(u, 1)
		T.eq(v, 1)
		u, v = MapView.uv(M.MinX + M.Size / 2, M.MinZ + M.Size / 2)
		T.eq(u, 0.5)
		T.eq(v, 0.5)
	end)

	T.test("plan: a world position is the plan's plus nothing but the origin", function()
		local x, z = MapView.plan(WorldPlan.Origin.x + 10, WorldPlan.Origin.z - 20)
		T.eq(x, 10)
		T.eq(z, -20)
	end)

	T.test("crop: the asked width, centred, and never off the picture", function()
		local studs = 600
		local side = studs / M.Size * PIC
		local cx, cy, size = MapView.crop(0, 0, studs, PIC)
		T.near(size, side, 1e-9)
		local u, v = MapView.uv(0, 0)
		T.near(cx, u * PIC - side / 2, 1e-9)
		T.near(cy, v * PIC - side / 2, 1e-9)
		-- the corners push the square back inside
		cx, cy = MapView.crop(M.MinX - 500, M.MinZ - 500, studs, PIC)
		T.eq(cx, 0)
		T.eq(cy, 0)
		cx, cy, size = MapView.crop(M.MinX + M.Size + 500, M.MinZ + M.Size + 500, studs, PIC)
		T.near(cx, PIC - size, 1e-9)
		T.near(cy, PIC - size, 1e-9)
		-- a view wider than the world shows the whole picture
		cx, cy, size = MapView.crop(0, 0, M.Size * 2, PIC)
		T.eq(size, PIC)
		T.eq(cx, 0)
		T.eq(cy, 0)
	end)

	T.test(
		"inCrop: the middle of the view is its centre; an edge pushes the point off-centre; far points fall outside",
		function()
			local cx, cy, size = MapView.crop(100, -200, 600, PIC)
			local fx, fy = MapView.inCrop(100, -200, cx, cy, size, PIC)
			T.near(fx, 0.5, 1e-9)
			T.near(fy, 0.5, 1e-9)
			cx, cy, size = MapView.crop(M.MinX, M.MinZ, 600, PIC)
			fx, fy = MapView.inCrop(M.MinX, M.MinZ, cx, cy, size, PIC)
			T.near(fx, 0, 1e-9)
			T.near(fy, 0, 1e-9)
			fx = MapView.inCrop(M.MinX + 3000, M.MinZ, cx, cy, size, PIC)
			T.ok(fx > 1, "east of the view")
		end
	)
end
