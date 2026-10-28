local Config = require("../../src/shared/Config")
local SlimeShape = require("../../src/shared/SlimeShape")

local K = Config.Slime.BoneK

local function pose(sy, sx, fwd, side)
	return { sy = sy, sx = sx, leanFwd = fwd or 0, leanSide = side or 0 }
end

return function(T)
	T.test("a body at rest does not move any point of its skin", function()
		local b = SlimeShape.bones(pose(1, 1))
		for _, p in { { 0, 1, 0 }, { -0.5, 0.33, 0 }, { 0.2, 0.5, -0.4 }, { 0, 0.1, 0.3 } } do
			local x, y, z = SlimeShape.deform(p[1], p[2], p[3], b)
			T.near(x, p[1], 1e-9)
			T.near(y, p[2], 1e-9)
			T.near(z, p[3], 1e-9)
		end
	end)

	T.test("sy scales every height about the feet and sx every width about the axis", function()
		local b = SlimeShape.bones(pose(1.3, 0.8))
		local x, y, z = SlimeShape.deform(0, 1, 0, b)
		T.near(y, 1.3, 1e-9, "the tip")
		T.near(x, 0, 1e-9)
		T.near(z, 0, 1e-9)
		local r = SlimeShape.radius(0.35)
		local wx, wy = SlimeShape.deform(-r, 0.35, 0, b)
		T.near(wx, -r * 0.8, 1e-9, "the widest ring, left")
		T.near(wy, 0.35 * 1.3, 1e-9)
		local _, _, fz = SlimeShape.deform(0, 0.35, -r, b)
		T.near(fz, -r * 0.8, 1e-9, "the widest ring, front")
		-- the contact point stays on the ground
		local _, fy = SlimeShape.deform(0.1, 0, 0.05, b)
		T.near(fy, 0, 1e-9)
	end)

	T.test("a lean shears the body about the feet: the tip moves, the base does not", function()
		local b = SlimeShape.bones(pose(1, 1, 0.2, -0.1))
		local tx, ty, tz = SlimeShape.deform(0, 1, 0, b)
		T.near(tz, -0.2, 1e-9, "toward the front (-Z)")
		T.near(tx, 0.1, 1e-9, "-0.1 toward the slime's left means +X")
		T.near(ty, 1, 1e-9)
		local mx, _, mz = SlimeShape.deform(0, 0.5, 0, b)
		T.near(mz, -0.1, 1e-9, "half way up leans half as far")
		T.near(mx, 0.05, 1e-9)
		T.near(K, 1.5, 1e-9, "the weights the model was skinned with")
	end)

	T.test("the face point lies on the body, in front", function()
		for _, uv in { { 0, 0 }, { 0.2, 0.1 }, { -0.3, -0.15 }, { 0.5, 0.3 } } do
			local x, y, z = SlimeShape.frontPoint(uv[1], uv[2])
			T.ok(z < 0, "front is -Z")
			T.near(math.sqrt(x * x + z * z), math.min(SlimeShape.radius(y), math.sqrt(x * x + z * z)), 1e-9)
			T.ok(math.sqrt(x * x + z * z) <= SlimeShape.radius(y) + 1e-9, "inside the body radius")
		end
		-- +u is the viewer's right = -X of the mesh
		local x = SlimeShape.frontPoint(0.2, 0)
		T.ok(x < 0)
	end)

	T.test("a face plate faces out, with +u toward the viewer's right and +v up", function()
		local rest = SlimeShape.bones(pose(1, 1))
		for _, uv in { { 0, 0 }, { -0.215, 0 }, { 0.215, 0 }, { 0, -0.1 } } do
			local p = SlimeShape.plate(uv[1], uv[2], rest)
			T.ok(p.nz < -0.5, "out of the front")
			T.ok(p.rx < -0.5, "+u is -X")
			T.ok(p.uy > 0.5, "+v is up")
			T.near(p.scaleU, 1, 1e-6, "no stretch at rest")
			T.near(p.scaleV, 1, 1e-6)
		end
		-- the right eye's plate turns toward the right: its normal has a component toward -X
		local right = SlimeShape.plate(0.3, 0, rest)
		T.ok(right.nx < 0, "the plate at the viewer's right looks a little to the right")
	end)

	T.test("a squash drops the face and stretches the plate", function()
		local rest = SlimeShape.plate(0, 0, SlimeShape.bones(pose(1, 1)))
		local squat = SlimeShape.plate(0, 0, SlimeShape.bones(pose(0.6, 1.25)))
		T.ok(squat.py < rest.py * 0.7, "the face sits lower")
		T.ok(squat.scaleU > 1.1, "wider across")
		T.ok(squat.scaleV < 0.9, "shorter up")
	end)
end
