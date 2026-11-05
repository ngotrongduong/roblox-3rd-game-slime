-- Checks the Arena built by tools/map/build_arena.luau: the names the code finds and how they face, the pit's free circle,
-- the arch's clearance, a free walk for a 5-stud player from the Landing through the arch and the orange gate to the sand
-- centre, nothing of it on the Market or a plot, flat ground under it, the light / glow / shadow limits and a part tally.
-- Ends ARENA OK, or lists what is wrong. Run in Edit mode:
--   node tools/studio_mcp.js run tools/map/check_arena.luau <studio_id> Edit
-- (Config/Layout cannot always be required from an MCP script, so the few numbers used have a fallback.)
local okC, Config = pcall(function()
	return require(game:GetService("ReplicatedStorage").Shared.Config)
end)
local G = if okC then Config.Map.GroundY else 2
local FLOOR_R = 690 -- the flat floor behind the Market ends here (radius from the world origin)
local arena = workspace.Map.Arena
local wrong = {}
local notes = {}
local function fail(text: string)
	table.insert(wrong, text)
end

-- the names, directly under Arena
local function named(name: string): BasePart?
	local p = arena:FindFirstChild(name)
	if not p or not p:IsA("BasePart") then
		fail("no BasePart " .. name .. " directly in Arena")
		return nil
	end
	return p
end
local pit = named("Pit")
local blue = named("BlueSpot")
local orange = named("OrangeSpot")
local entrance = named("Entrance")
local landing = named("Landing")
local board = named("Board")
local podium = { named("Podium1"), named("Podium2"), named("Podium3") }
if not (pit and blue and orange and entrance and landing and board and podium[1] and podium[2] and podium[3]) then
	return "ARENA NOT OK:\n" .. table.concat(wrong, "\n")
end
for _, p in { blue, orange, entrance, landing } do
	if p.Transparency < 1 or p.CanCollide or p.CanQuery or p.CanTouch or not p.Anchored then
		fail(p.Name .. " must be invisible, anchored and not collide / query / touch")
	end
end

local C = Vector3.new(pit.Position.X, 0, pit.Position.Z)
local sandTop = pit.Position.Y + pit.Size.Y / 2
if math.abs(sandTop - (pit:GetAttribute("SurfaceY") or -1)) > 0.01 then
	fail("Pit's SurfaceY attribute is not its top")
end
table.insert(notes, string.format("pit centre (%.0f, %.0f), sand top %.1f, free radius %s", C.X, C.Z, sandTop, tostring(pit:GetAttribute("Radius"))))

-- the spots: 18 studs from the centre, on the sand, facing the centre, blue north (the back), orange south
for _, s in { { blue, -1 }, { orange, 1 } } do
	local spot, dir = s[1], s[2]
	local off = Vector3.new(spot.Position.X, 0, spot.Position.Z) - C
	if math.abs(off.Magnitude - 18) > 0.5 then
		fail(string.format("%s is %.1f from the centre, not 18", spot.Name, off.Magnitude))
	end
	if off.Z * dir < 17 then
		fail(spot.Name .. " is on the wrong side of the pit")
	end
	if math.abs(spot.Position.Y - sandTop) > 0.6 then
		fail(spot.Name .. " is not on the sand")
	end
	local toCentre = (C - Vector3.new(spot.Position.X, 0, spot.Position.Z)).Unit
	if spot.CFrame.LookVector:Dot(toCentre) < 0.98 then
		fail(spot.Name .. " does not face the pit's centre")
	end
end

-- the Landing looks at the arch, the board's face looks south and is plain, the podium steps rise 1 > 2 > 3
local toArch = Vector3.new(entrance.Position.X - landing.Position.X, 0, entrance.Position.Z - landing.Position.Z).Unit
if landing.CFrame.LookVector:Dot(toArch) < 0.98 then
	fail("the Landing does not look at the arch")
end
if board.CFrame.LookVector:Dot(Vector3.new(0, 0, 1)) < 0.99 then
	fail("the Board's Front does not face south (the arch's side)")
end
if #board:GetChildren() > 0 then
	fail("the Board's face must be plain (it has children)")
end
local tops = {}
for i, p in podium do
	tops[i] = p.Position.Y + p.Size.Y / 2
	if p.Size.X < 5.5 or p.Size.Z < 5.5 then
		fail(p.Name .. " is under 5.5 studs wide")
	end
end
if not (tops[1] > tops[2] and tops[2] > tops[3]) then
	fail("the podium steps do not rise 1 > 2 > 3")
end
table.insert(notes, string.format("podium tops %.1f / %.1f / %.1f over the ground", tops[1] - G, tops[2] - G, tops[3] - G))
table.insert(notes, string.format("board %.0f x %.0f studs, centre %.1f over the ground", board.Size.X, board.Size.Y, board.Position.Y - G))

-- bodies against everything that collides
local params = OverlapParams.new()
params.RespectCanCollide = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { workspace.Terrain }
local function bodyHits(p: Vector3, floorY: number): { BasePart }
	return workspace:GetPartBoundsInBox(CFrame.new(p.X, floorY + 0.5 + 2.3, p.Z), Vector3.new(3, 4.6, 3), params)
end

-- the pit's free circle: a 5-stud body anywhere in radius 29, and the sand under every one of those points
local checked = 0
for x = -29, 29, 3 do
	for z = -29, 29, 3 do
		if x * x + z * z <= 28 * 28 then
			checked += 1
			local p = Vector3.new(C.X + x, 0, C.Z + z)
			local hit = bodyHits(p, sandTop)
			if #hit > 0 then
				fail(string.format("the pit is blocked at (%d, %d) by %s", x, z, hit[1]:GetFullName()))
				break
			end
			local ray = workspace:Raycast(Vector3.new(p.X, sandTop + 20, p.Z), Vector3.new(0, -30, 0))
			if not ray or math.abs(ray.Position.Y - sandTop) > 0.05 or not string.find(ray.Instance.Name, "Pit") then
				fail(string.format("no sand under (%d, %d)", x, z))
				break
			end
		end
	end
end
table.insert(notes, checked .. " points of the pit checked")

-- the arch: at least 15 wide and 16 high, free of anything that collides
local lawnTop = G + 0.3
local archBox = workspace:GetPartBoundsInBox(CFrame.new(entrance.Position.X, lawnTop + 0.4 + 8, entrance.Position.Z), Vector3.new(15, 16, 4), params)
for _, p in archBox do
	fail("the arch's opening (15 x 16) is blocked by " .. p:GetFullName())
	break
end

-- walks (a 3 x 4.6 x 3 body): the path to the arch, through it, across the lawn, through the orange gate onto the sand
local function walk(name: string, a: Vector3, b: Vector3, floorY: number)
	local len = (b - a).Magnitude
	for d = 0, len, 1.5 do
		local p = a:Lerp(b, d / len)
		local hit = bodyHits(p, floorY)
		if #hit > 0 then
			fail(string.format("the walk %s is blocked at (%.0f, %.0f) by %s", name, p.X, p.Z, hit[1]:GetFullName()))
			return
		end
	end
end
local ax = entrance.Position.X
walk("landing to the gate", Vector3.new(ax, 0, landing.Position.Z), Vector3.new(ax, 0, C.Z + 40), lawnTop)
walk("gate onto the sand", Vector3.new(ax, 0, C.Z + 40), Vector3.new(ax, 0, C.Z + 30), lawnTop)
walk("across the sand", Vector3.new(ax, 0, C.Z + 30), Vector3.new(ax, 0, C.Z - 30), sandTop)
local ground = workspace:Raycast(Vector3.new(landing.Position.X, landing.Position.Y + 10, landing.Position.Z), Vector3.new(0, -20, 0))
if not ground or not string.find(ground.Instance.Name, "PathTile") then
	fail("the Landing is not on the path")
end

-- where it stands: inside the flat floor, off the Market and the plots, on level ground
local others = {}
for _, c in workspace.Map:GetChildren() do
	if c ~= arena then
		table.insert(others, c)
	end
end
local only = OverlapParams.new()
only.FilterType = Enum.RaycastFilterType.Include
only.FilterDescendantsInstances = others
local parts, collide, shadows, lights, neon, emitters, tris = 0, 0, 0, 0, 0, 0, 0
local onOther, farthest = 0, 0
local lowest, highest = math.huge, -math.huge
for _, d in arena:GetDescendants() do
	if d:IsA("PointLight") or d:IsA("SpotLight") then
		lights += 1
	elseif d:IsA("ParticleEmitter") then
		emitters += 1
	elseif d:IsA("BasePart") then
		parts += 1
		if d.CanCollide then
			collide += 1
		end
		if d.CastShadow then
			shadows += 1
		end
		if d.Material == Enum.Material.Neon and d.Name ~= "LampGlass" then
			neon += 1
		end
		if d:IsA("WedgePart") then
			tris += 8
		elseif d:IsA("MeshPart") then
			tris += 600
		elseif d:IsA("Part") then
			tris += if d.Shape == Enum.PartType.Block then 12 else 100
		end
		local half = d.Size * 0.5
		for sx = -1, 1, 2 do
			for sz = -1, 1, 2 do
				local corner = d.CFrame:PointToWorldSpace(Vector3.new(sx * half.X, 0, sz * half.Z))
				farthest = math.max(farthest, Vector2.new(corner.X, corner.Z).Magnitude)
			end
		end
		lowest = math.min(lowest, d.Position.Y - half.Y)
		highest = math.max(highest, d.Position.Y + half.Y)
		if d.Transparency < 1 and #workspace:GetPartsInPart(d, only) > 0 then
			onOther += 1
			if onOther == 1 then
				fail("touching another part of the map: " .. d:GetFullName())
			end
		end
	end
end
if farthest > FLOOR_R + 3 then -- (the floor's edge rises gently over the last few studs)
	fail(string.format("reaches %.0f from the origin, past the flat floor (%d)", farthest, FLOOR_R))
end
if lights > 4 then
	fail(lights .. " lights (4 at most)")
end
if emitters > 0 then
	fail("particle emitters in the Arena")
end
if neon > 2 then
	fail(neon .. " Neon parts (the two gate glows only)")
end
for _, d in arena.Dressing:GetDescendants() do
	if d:IsA("BasePart") and d.CanCollide then
		fail("foliage collides: " .. d:GetFullName())
		break
	end
end
-- level terrain under the footprint
local bad = 0
for x = -56, 56, 14 do
	for z = -60, 66, 14 do
		local r = workspace:Raycast(Vector3.new(C.X + x, G + 40, C.Z + z), Vector3.new(0, -80, 0), (function()
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Include
			rp.FilterDescendantsInstances = { workspace.Terrain }
			return rp
		end)())
		if not r or math.abs(r.Position.Y - G) > 1.5 then
			bad += 1
		end
	end
end
if bad > 0 then
	fail(bad .. " ground samples under the footprint are not level with the floor")
end
local instances = #arena:GetDescendants()
table.insert(notes, string.format("%d parts (%d collide, %d cast shadows), %d instances, %d lights, %d Neon, about %d triangles (primitives counted high)", parts, collide, shadows, instances, lights, neon, tris))
table.insert(notes, string.format("farthest reach %.0f from the origin; height %.1f .. %.1f over the ground", farthest, lowest - G, highest - G))
table.insert(notes, if #wrong == 0 then "ARENA OK" else "ARENA NOT OK:\n" .. table.concat(wrong, "\n"))
return table.concat(notes, "\n")
