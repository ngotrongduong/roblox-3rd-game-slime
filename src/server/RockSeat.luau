--!strict
-- Seats a rock or boulder on the ground (the owner, 2026-10-29: "this rock is floating; only a tiny part touches
-- the bank"). Under the edge of its footprint every sample must find the ground (or the water's surface) no
-- lower than the rock's base: the rock sinks a little into the ground, and if the ground falls away more
-- than it may sink (a bank over the pond), it moves toward the side where the ground is high. Used by the
-- stage builders for the rocks they place and by tools/map/fix_rocks.luau for the rocks saved in the place.
-- The model must be in the world while it is seated (rays only see the world).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local RockSeat = {}

local SAMPLES = {
	{ 0.7, 0 },
	{ -0.7, 0 },
	{ 0, 0.7 },
	{ 0, -0.7 },
	{ 0.5, 0.5 },
	{ -0.5, 0.5 },
	{ 0.5, -0.5 },
	{ -0.5, -0.5 },
}

local function box(rock: PVInstance): (CFrame, Vector3)
	if rock:IsA("Model") then
		return rock:GetBoundingBox()
	end
	local part = rock :: BasePart
	return part.CFrame, part.Size
end

-- How far the rock's base is above the lowest ground under its edge (0 or less: it rests everywhere).
function RockSeat.gap(rock: PVInstance, ignore: { Instance }?): number
	local cf, size = box(rock)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list: { Instance } = { rock }
	if ignore then
		for _, inst in ignore do
			table.insert(list, inst)
		end
	end
	params.FilterDescendantsInstances = list
	params.RespectCanCollide = false
	local bottom = cf.Position.Y - size.Y / 2
	local worst = -math.huge
	for _, s in SAMPLES do
		local p = cf:PointToWorldSpace(Vector3.new(s[1] * size.X / 2, 0, s[2] * size.Z / 2))
		local hit = workspace:Raycast(
			-- (from above the rock's top: a ray started under the ground, beside a buried rock, finds nothing)
			Vector3.new(p.X, bottom + size.Y + Config.Map.RockProbeUp, p.Z),
			Vector3.new(0, -(size.Y + Config.Map.RockProbeUp + Config.Map.RockProbeDown), 0),
			params
		)
		local ground = if hit then hit.Position.Y else bottom - Config.Map.RockProbeDown
		worst = math.max(worst, bottom - ground)
	end
	return worst
end

-- Sink the rock onto the ground, moving it toward higher ground when sinking alone would bury too much.
-- Returns the gap left (at most RockSeatTolerance when it worked).
function RockSeat.seat(rock: PVInstance, ignore: { Instance }?): number
	local M = Config.Map
	local start = rock:GetPivot()
	local best: CFrame = start
	local bestGap = math.huge
	local function try(shift: Vector3): number
		rock:PivotTo(start + shift)
		local gap = RockSeat.gap(rock, ignore)
		-- (a rock buried deeper than RockMaxBuried rises back to a light burial; a lightly buried one stays)
		local sink = math.min(gap + M.RockBury, M.RockMaxSink)
		if sink < 0 and -gap <= M.RockMaxBuried then
			sink = 0
		end
		rock:PivotTo(start + shift - Vector3.new(0, sink, 0))
		return gap - sink
	end
	for ring = 0, M.RockShiftSteps do
		local count = if ring == 0 then 1 else 8
		for k = 1, count do
			local angle = (k - 1) * math.pi / 4
			local shift = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (ring * M.RockShiftStep)
			local left = try(shift)
			if left < bestGap then
				bestGap, best = left, rock:GetPivot()
			end
		end
		if bestGap <= M.RockSeatTolerance then
			break
		end
	end
	rock:PivotTo(best)
	rock:SetAttribute("Seated", true)
	return bestGap
end

local NAMES = { "rock", "boulder", "pebble" }
local function isRock(inst: Instance): boolean
	if not (inst:IsA("Model") or inst:IsA("MeshPart")) then
		return false
	end
	local name = string.lower(inst.Name)
	for _, k in NAMES do
		if string.find(name, k, 1, true) then
			return true
		end
	end
	return false
end

-- The outermost rocks under `root` (a rock's own pieces are part of it).
function RockSeat.rocks(root: Instance): { PVInstance }
	local list: { PVInstance } = {}
	for _, d in root:GetDescendants() do
		if isRock(d) then
			local parent = d.Parent
			local nested = false
			while parent and parent ~= root do
				if isRock(parent) then
					nested = true
					break
				end
				parent = parent.Parent
			end
			if not nested then
				table.insert(list, d :: PVInstance)
			end
		end
	end
	return list
end

-- Seat every rock under `root` again (the ground may have changed: an upgrade digs the pond wider). What
-- stands on a rock (a fishing place's marker, its rod stand: siblings whose foot is over the rock's footprint
-- and above its middle) moves with it. Returns how many rocks moved.
function RockSeat.seatAll(root: Instance): number
	local moved = 0
	for _, rock in RockSeat.rocks(root) do
		local before = rock:GetPivot()
		local cf, size = box(rock)
		local riders: { PVInstance } = {}
		local parent = rock.Parent
		if parent then
			for _, sibling in parent:GetChildren() do
				if sibling ~= rock and sibling:IsA("PVInstance") then
					local rel = cf:PointToObjectSpace(sibling:GetPivot().Position)
					if math.abs(rel.X) <= size.X / 2 and math.abs(rel.Z) <= size.Z / 2 and rel.Y > 0 then
						table.insert(riders, sibling)
					end
				end
			end
		end
		RockSeat.seat(rock)
		local delta = rock:GetPivot().Position - before.Position
		if delta.Magnitude > 1e-3 then
			moved += 1
			for _, rider in riders do
				rider:PivotTo(rider:GetPivot() + delta)
			end
		end
	end
	return moved
end

return RockSeat
