-- Checks the Market square built by tools/map/build_market.luau and build_smithy.luau: the names the code finds, the screen's face, the
-- awnings' clearance, a free walk for a 5-stud player from the Landing round the plaza to the front of every place (the portal's too, from
-- its spot), the Landing clear, nothing of the square on the ring road or on plots 1 and 8. Ends MARKET OK, or lists what is wrong.
-- Run in Edit mode: node tools/studio_mcp.js run tools/map/check_market.luau <studio_id> Edit
-- (an MCP `run` cannot require the shared modules - "Capabilities: Network" - so the numbers are kept here, EQUAL to
-- src/shared/Config.luau's Config.Map, Config.Market and Config.Dungeon.Portal.Market)
local M = { GroundY = 2, RingRoadRadius = 356, RingRoadWidth = 24, PlotSize = 228, RimRadius = 500, PlotCount = 8 }
local K = {
	Landing = { x = 0, z = -56 },
	Buyer = { x = 48, z = -28 },
	Vip = { x = -48, z = -28 },
	Board = { x = 0, z = 62 },
	Smithy = { x = 48, z = 28 },
	Portal = { x = -51, z = 30 },
}
local function slotFrame(slot: number): CFrame
	local a = math.rad(slot * 360 / (M.PlotCount + 1))
	return CFrame.new(math.sin(a) * M.RimRadius, 0, -math.cos(a) * M.RimRadius) * CFrame.Angles(0, math.pi - a, 0)
end
local F = slotFrame(0)
local G = M.GroundY
local market = workspace.Map.Market
local wrong = {}
local notes = {}
local function fail(text: string)
	table.insert(wrong, text)
end

-- the names
for _, name in { "SlimeBuyer", "VipStall", "Leaderboard", "Blacksmith" } do
	local m = market:FindFirstChild(name)
	if not m or not m:IsA("Model") then
		fail("no Model " .. name)
	end
end
local screen = market.Leaderboard:FindFirstChild("Screen")
if not screen or not screen:IsA("BasePart") then
	fail("no Part Screen in Leaderboard")
else
	-- its Front (LookVector) must look at the square, toward the frame's -Z, within a few degrees
	if screen.CFrame.LookVector:Dot(F.LookVector) < 0.99 then
		fail("the Screen's Front does not face the square")
	end
	table.insert(notes, string.format("screen %.0f x %.0f studs", screen.Size.X, screen.Size.Y))
	-- nothing stands in front of its face within 30 studs of it at its height
	local box = screen.CFrame * CFrame.new(0, 0, -16)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { market }
	for _, p in workspace:GetPartBoundsInBox(box, Vector3.new(screen.Size.X - 1, screen.Size.Y - 1, 30), params) do
		if p.Transparency < 1 and not string.find(p.Name, "Frame") and not string.find(p.Name, "Pennant") and not string.find(p.Name, "Bunting") and p.Name ~= "Screen" then
			fail("in front of the screen: " .. p:GetFullName())
			break
		end
	end
end

-- the awning's clearance over the walk in front of a stall
for _, name in { "SlimeBuyer", "VipStall" } do
	local lowest = math.huge
	for _, d in market[name]:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Scallop" or d.Name == "ScallopEdge") then
			local low = d.Position.Y - 0.5 * d.Size.Y * 0.8
			lowest = math.min(lowest, low)
		end
	end
	table.insert(notes, string.format("%s: scallops reach down to about %.1f over the ground", name, lowest - G))
	if lowest - G < 9 then
		fail(name .. "'s awning is under 9 studs")
	end
end

-- a walk: a 3 x 5 x 3 body along a line of way points, against everything that collides
local params = OverlapParams.new()
params.RespectCanCollide = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { workspace.Terrain, market:FindFirstChild("Spawn") }
local function walk(name: string, points: { { number } })
	for k = 1, #points - 1 do
		local a = Vector3.new(points[k][1], G + 3, points[k][2])
		local b = Vector3.new(points[k + 1][1], G + 3, points[k + 1][2])
		local len = (b - a).Magnitude
		for d = 0, len, 1.5 do
			local p = a:Lerp(b, d / len)
			local hit = workspace:GetPartBoundsInBox(F * CFrame.new(p), Vector3.new(3, 4.6, 3), params)
			if #hit > 0 then
				fail(string.format("the walk to %s is blocked at (%.0f, %.0f) by %s", name, p.X, p.Z, hit[1]:GetFullName()))
				return
			end
		end
	end
end
-- a point `r` from the fountain on the line to a spot, and the plaza's walking ring (radius 32, clear of the fountain's 19)
local function toward(spot: { x: number, z: number }, r: number): { number }
	local len = math.sqrt(spot.x * spot.x + spot.z * spot.z)
	return { spot.x / len * r, spot.z / len * r }
end
local function ring(fromAngle: number, toAngle: number): { { number } }
	local out = {}
	local steps = math.max(1, math.ceil(math.abs(toAngle - fromAngle) / math.rad(15)))
	for k = 0, steps do
		local a = fromAngle + (toAngle - fromAngle) * k / steps
		table.insert(out, { math.sin(a) * 32, -math.cos(a) * 32 })
	end
	return out
end
local function walkTo(name: string, spot: { x: number, z: number }, stopAt: number)
	local points = { { K.Landing.x, K.Landing.z } }
	for _, p in ring(0, math.atan2(spot.x, -spot.z)) do
		table.insert(points, p)
	end
	table.insert(points, toward(spot, stopAt))
	walk(name, points)
end
-- to the front of each counter (9 short of its spot), the smithy's anvil (8 short), the portal's opening and the board
walkTo("the buyer", K.Buyer, math.sqrt(K.Buyer.x ^ 2 + K.Buyer.z ^ 2) - 9)
walkTo("the VIP counter", K.Vip, math.sqrt(K.Vip.x ^ 2 + K.Vip.z ^ 2) - 9)
walkTo("the Blacksmith", K.Smithy, math.sqrt(K.Smithy.x ^ 2 + K.Smithy.z ^ 2) - 8)
-- (the portal's platform comes to about 14 short of its spot: the walk ends at its first step)
walkTo("the portal", K.Portal, math.sqrt(K.Portal.x ^ 2 + K.Portal.z ^ 2) - 16)
walkTo("the board", K.Board, 50)
walk("in from the ring road", { { 0, -122 }, { K.Landing.x, K.Landing.z } })

-- nothing on the Landing
local clear = workspace:GetPartBoundsInBox(F * CFrame.new(K.Landing.x, G + 3, K.Landing.z), Vector3.new(16, 5, 16), params)
if #clear > 0 then
	fail("the Landing is not clear: " .. clear[1]:GetFullName())
end

-- what stands where it may not: every part's foot, in plan
local plots = { slotFrame(1), slotFrame(8) }
local parts, shadows, collide = 0, 0, 0
local onRoad, onPlot = 0, 0
for _, d in market:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
		if d.CastShadow then
			shadows += 1
		end
		if d.CanCollide then
			collide += 1
		end
		local r = Vector2.new(d.Position.X, d.Position.Z).Magnitude
		if math.abs(r - M.RingRoadRadius) < M.RingRoadWidth / 2 + 1 then
			onRoad += 1
			if onRoad == 1 then
				fail("on the ring road: " .. d:GetFullName())
			end
		end
		for _, plot in plots do
			local p = plot:PointToObjectSpace(d.Position)
			if math.abs(p.X) < M.PlotSize / 2 + 4 and math.abs(p.Z) < M.PlotSize / 2 + 4 then
				onPlot += 1
				if onPlot == 1 then
					fail("on a plot: " .. d:GetFullName())
				end
			end
		end
	end
end
table.insert(notes, string.format("%d parts, %d collide, %d cast shadows", parts, collide, shadows))
table.insert(notes, if #wrong == 0 then "MARKET OK" else "MARKET NOT OK:\n" .. table.concat(wrong, "\n"))
return table.concat(notes, "\n")
