--!strict
-- The entrance arch of a plot area (breeding pen, kitchen, training ground), in the area's gate tier
-- (the owner, 2026-10-28: the gates were two posts and a board; build them with care and detail).
-- Each post stands on a plinth with a collar, a capital and a finial; a lantern hangs on its outer
-- face and a planter of the tier's own kind stands at its foot. Over the way through: a main beam
-- with knee braces, a lower rail with spindles between them, a low curved crown, and the area's own
-- emblem (a generated model) at the top. The way through stays 6.5+ studs clear. Glowing trim (slime
-- tech) lights only the lanterns and finials, never the long beams.
local PantryStages = require(script.Parent.PantryStages)

local GateArch = {}

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

-- the planter at a post's foot, by tier (the village's era planters)
local PLANTERS = {
	"FlowerBedWood",
	"FlowerBedWood",
	"FlowerBedBrick",
	"FlowerBedSteel2",
	"FlowerBedSteel2",
	"FlowerBedMarble",
}

-- `frame` is the area's frame at the ground; the posts stand at x = mid -/+ width / 2 on the line
-- z, the front toward -Z. `tier` is the gate's tier, `accent` the area's colour, `emblem` the kit
-- model on top.
function GateArch.build(
	m: Instance,
	frame: CFrame,
	mid: number,
	width: number,
	z: number,
	tier: number,
	accent: Color3,
	emblem: string
)
	local t = TIERS[tier]
	local function at(x: number, y: number, dz: number?): CFrame
		return frame * CFrame.new(mid + x, y, z + (dz or 0))
	end
	local soft, softMat = t.trim, t.trimMat
	if softMat == Enum.Material.Neon then
		soft, softMat = t.walls, t.wallMat
	end
	local function bit(name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): BasePart
		local p = part(m, name, size, cf, colour, material or Enum.Material.SmoothPlastic)
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	local half = width / 2
	local top = 7.4 -- the main beam's middle
	for _, s in { -1, 1 } do
		local x = s * half
		-- the post: plinth, shaft, collars, capital, finial
		local plinthH = if tier >= 3 then 1.3 else 0.8
		part(m, "GatePlinth", Vector3.new(1.7, plinthH, 1.7), at(x, plinthH / 2, 0), t.base, t.baseMat)
		part(m, "GatePlinthCap", Vector3.new(1.9, 0.2, 1.9), at(x, plinthH + 0.1, 0), soft, softMat)
		local shaftH = top - plinthH - 0.2
		part(m, "GatePost", Vector3.new(1, shaftH, 1), at(x, plinthH + 0.2 + shaftH / 2, 0), t.frame, t.frameMat)
		for _, y in { plinthH + 1.2, top - 1.4 } do
			part(m, "GateCollar", Vector3.new(1.2, 0.25, 1.2), at(x, y, 0), soft, softMat)
		end
		part(m, "GateCapital", Vector3.new(1.5, 0.4, 1.5), at(x, top + 0.6, 0), soft, softMat)
		part(m, "GateCapitalTop", Vector3.new(1.2, 0.3, 1.2), at(x, top + 0.95, 0), t.frame, t.frameMat)
		local finial = bit("GateFinial", Vector3.one * 0.7, at(x, top + 1.45, 0), t.trim, t.trimMat) :: Part
		finial.Shape = Enum.PartType.Ball
		-- a lantern on the post's outer face: a bracket, a cap, warm glass, a base
		local lx = x + s * 0.95
		bit("LanternBracket", Vector3.new(0.9, 0.15, 0.15), at(x + s * 0.7, 5.6, 0), t.frame, t.frameMat)
		bit("LanternCap", Vector3.new(0.7, 0.2, 0.7), at(lx, 5.45, 0), t.frame, t.frameMat)
		local glass = bit("LanternGlass", Vector3.new(0.5, 0.65, 0.5), at(lx, 5.0, 0), t.glass, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = t.glass
		light.Range = 9
		light.Brightness = 0.7
		light.Parent = glass
		bit("LanternBase", Vector3.new(0.6, 0.15, 0.6), at(lx, 4.6, 0), t.frame, t.frameMat)
		-- the planter at its foot, outside the way through
		place(m, frame, PLANTERS[tier], mid + s * (half + 2.4), z - 0.6, 1.7, 2.8)
		-- a knee brace under the beam's inner end
		wedge(
			m,
			"GateBrace",
			Vector3.new(0.5, 1.1, 1.1),
			at(x - s * 1.05, top - 0.95, 0) * CFrame.Angles(0, math.rad(s * 90), math.pi),
			t.frame,
			t.frameMat
		)
	end
	-- the beams: the main one, a lower rail, spindles between
	local span = width + 2.6
	part(m, "GateBeam", Vector3.new(span, 0.7, 0.9), at(0, top, 0), t.walls, t.wallMat)
	part(m, "GateBeamTrim", Vector3.new(span + 0.2, 0.15, 1.05), at(0, top + 0.42, 0), soft, softMat)
	part(m, "GateRail", Vector3.new(width - 1, 0.3, 0.5), at(0, top - 1.05, 0), t.frame, t.frameMat)
	local n = math.max(3, math.floor(width / 1.2))
	for k = 1, n do
		local x = -half + 0.5 + (width - 1) * (k - 0.5) / n
		bit("GateSpindle", Vector3.new(0.2, 0.7, 0.2), at(x, top - 0.55, 0), soft, softMat)
	end
	-- the crown: a low curve of short pieces over the beam, its ends on the capitals
	local segs = 7
	local rise = 1.1
	local prev: Vector3? = nil
	for k = 0, segs do
		local u = k / segs
		local x = -half + width * u
		local y = top + 0.75 + math.sin(math.pi * u) * rise
		local p = Vector3.new(x, y, 0)
		if prev then
			local a, b = prev, p
			local c = (a + b) / 2
			local len = (b - a).Magnitude + 0.2
			part(
				m,
				"GateCrown",
				Vector3.new(len, 0.45, 0.7),
				at(c.X, c.Y, 0) * CFrame.Angles(0, 0, math.atan2(b.Y - a.Y, b.X - a.X)),
				t.walls,
				t.wallMat
			)
		end
		prev = p
	end
	-- the area's colour along the beam's front, and the emblem at the top
	bit("GateAccent", Vector3.new(width - 0.6, 0.25, 0.1), at(0, top - 0.1, -0.5), accent)
	local holder = Instance.new("Model")
	holder.Name = "GateEmblem"
	holder.Parent = m
	place(holder, at(0, 0, -0.2), emblem, 0, 0, 2.4, 3, top + 0.9)
	if #holder:GetChildren() == 0 then
		holder:Destroy()
	end
end

return GateArch
