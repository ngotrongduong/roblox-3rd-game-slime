--!strict
-- The owner's fence sections and entrance gates, one of each an era (his two prop sheets, 2026-11-18:
-- docs/areas/village-v2/props/fence-sheet.jpg and gate-sheet.jpg, hard-pieces.md "Fences and gates"), worn by the
-- yards of the areas: BreedingHouse, Garden and TrainingHall lay their fence runs and stand their gates with them,
-- the kitchen's entrance arch (GateArch) is the gate alone. Every function answers nil while the meshes are not in
-- the kit, and the module then builds its own parts as before.
local LibraryKit = require(script.Parent.LibraryKit)

local YardKit = {}

local FENCES = { "PropFenceRail", "PropFencePicket", "PropFenceStone", "PropFenceIron", "PropFenceRoyal" }
local GATES = { "PropGateThatch", "PropGateTiled", "PropGateVine", "PropGateTech", "PropGateRoyal" }
-- measured on the gate models (shares of their width or height): the way through at the foot, the middle of each
-- post or pier, and the arch's underside at 0, 0.3, 0.6 and 0.9 of the way through's half
local OPEN = { 0.40, 0.40, 0.36, 0.38, 0.28 }
local PIER = { 0.27, 0.28, 0.31, 0.29, 0.31 }
local SOFFIT = {
	{ 0.65, 0.65, 0.52, 0.52 },
	{ 0.62, 0.61, 0.58, 0.55 },
	{ 0.7, 0.69, 0.64, 0.58 },
	{ 0.6, 0.6, 0.58, 0.48 },
	{ 0.51, 0.51, 0.51, 0.45 },
}
-- (the owner's meshes wear their own picture: white and plain, whatever the module's skins say)
local WHITE = Color3.new(1, 1, 1)
local PLAIN = Enum.Material.SmoothPlastic

local function kit(name: string): (Model?, BasePart?)
	local m = LibraryKit.find(name)
	local p = m and m:FindFirstChildWhichIsA("BasePart")
	if m and p then
		return m, p
	end
	return nil, nil
end

-- An unseen box to walk against: the meshes are never solid.
local function stop(b: any, name: string, size: Vector3, cf: CFrame)
	local p = b.box(name, size.X, size.Y, size.Z, cf, WHITE, PLAIN)
	p.Transparency = 1
	p.CastShadow = false
end

-- One run of the era's fence from `a` to `c` (points in the builder's frame at the ground's top), its inside on the
-- run's own +Z as every landmark lays its runs round a yard, the fronts out. The sections are stretched a little so a
-- whole number of them fills the run. Each is the section with its start post cut off (tools/blender/fence_open.py),
-- so a run has a post at its end and none at its start, and each corner gets one from the run that ends there; a run
-- that ends at a gate (`toGate`) ends with the section without posts, the gate's own end post closing it as it closes
-- the run that starts there. Answers the posts' height.
function YardKit.fence(b: any, era: number, a: Vector3, c: Vector3, toGate: boolean): number?
	local open, openPart = kit(FENCES[era] .. "Open")
	local bare, barePart = kit(FENCES[era] .. "Bare")
	if not (open and openPart and bare and barePart) then
		return nil
	end
	local run = c - a
	local len = run.Magnitude
	local dir = run.Unit
	local along = CFrame.Angles(0, math.atan2(-dir.Z, dir.X), 0)
	local tail = if toGate then barePart.Size.X else openPart.Size.X
	local n = math.max(1, math.floor((len - tail) / openPart.Size.X + 0.5) + 1)
	local k = len / (tail + (n - 1) * openPart.Size.X)
	local d = 0
	for i = 1, n do
		local last = i == n and toGate
		local w = (if last then barePart.Size.X else openPart.Size.X) * k
		local p = a + dir * (d + w / 2)
		b.mesh(if last then bare else open, b.at(p.X, p.Y, p.Z) * along, Vector3.new(k, 1, 1), WHITE, PLAIN)
		d += w
	end
	local mid = a + run / 2
	local tall = openPart.Size.Y
	stop(b, "FenceStop", Vector3.new(len, tall * 0.8, 0.6), b.at(mid.X, mid.Y + tall * 0.4, mid.Z) * along)
	return tall
end

-- The era's gate's half width (where the fence meets it, at the gate's own end posts), or nil.
function YardKit.gateHalf(era: number): number?
	local _, part = kit(GATES[era])
	return if part then part.Size.X / 2 else nil
end

-- The era's gate on `foot` (the middle of the way through at the ground, the front to the foot's -Z), and unseen
-- piers either side of the way through to walk against. Answers whether it stands.
function YardKit.gate(b: any, era: number, foot: CFrame): boolean
	local g, part = kit(GATES[era])
	if not (g and part) then
		return false
	end
	b.mesh(g, foot, Vector3.one, WHITE, PLAIN)
	local half = part.Size.X / 2
	local open = part.Size.X * OPEN[era] / 2
	for _, s in { -1, 1 } do
		local size = Vector3.new(half - open, part.Size.Y * 0.55, part.Size.Z * 0.5)
		stop(b, "GateStop", size, foot * CFrame.new(s * (half + open) / 2, size.Y / 2, 0))
	end
	return true
end

-- Where the era's gate's two posts or piers stand (their middle, studs from the way through's middle) and how far its
-- front reaches out of its middle line, for what hangs on them.
function YardKit.pier(era: number): (number, number)
	local _, part = kit(GATES[era])
	if not part then
		return 0, 0
	end
	return part.Size.X * PIER[era], part.Size.Z * 0.3
end

-- The height of the era's gate's arch underside `x` studs from the way through's middle (for what hangs in it).
function YardKit.underArch(era: number, x: number): number
	local _, part = kit(GATES[era])
	if not part then
		return 0
	end
	local t = math.clamp(math.abs(x) / (part.Size.X * OPEN[era] / 2) / 0.3, 0, 3)
	local row = SOFFIT[era]
	local i = math.min(math.floor(t), 2)
	return part.Size.Y * (row[i + 1] + (row[i + 2] - row[i + 1]) * (t - i))
end

return YardKit
