--!strict
-- The home plot's tall fence and its main gate, era by era, built with care and detail (the owner,
-- 2026-10-28: "the main gate and the fence, like the area gates: a careful, detailed, finished
-- design"). Era 1 keeps the kit palisade and the kit gate; from era 2 this layer stands in for them:
--   era 2  painted timber estate fence: a kick board, board-and-batten panels, a mid rail, a lattice
--          band and a capped top rail; posts with sunk panels, a capped top, a finial and lanterns;
--          flower boxes along the inside. The gatehouse: stone-footed timber towers with corner posts,
--          a lit shuttered window with a flower box, a gable roof with its ridge and finial, a beam
--          with knee braces under a little shingled roof, hanging baskets
--   era 3  brick wall on a stone plinth: string courses, a corbelled coping and capped merlons, ivy;
--          stone towers with quoins, a corbel band, capped merlons and torches. The gatehouse: big
--          towers with quoins, arrow slits, banners and torches, an arch of voussoirs under a
--          battlemented bridge with machicolations
--   era 4  steel and glass: a concrete base, glass panes between steel mullions, a lit top rail,
--          I-beam posts with light boxes. The portal: framed glass towers with ribbons of light, a
--          finned glass canopy, bollards on the landing
--   era 5  marble: a stepped plinth, a wall with framed sunk panels, a two-layer cornice, a
--          balustrade of vase balusters; columns with bases, capitals and urns. The arch: paired
--          columns on plinths with tori and capitals, an architrave, a gold frieze, a cornice, a
--          pediment edged in gold, the golden slime crest, urns, golden lamps and marble steps
-- The way through stays clear (18 studs wide, 12+ high); no name sign over it (the owner,
-- 2026-10-28). Small pieces do not collide or cast shadows.
local PantryStages = require(script.Parent.PantryStages)

local VillageWalls = {}

local TIERS = PantryStages.Tiers
local part, wedge, place = PantryStages.part, PantryStages.wedge, PantryStages.place

local HALF = require(game:GetService("ReplicatedStorage").Shared.Config).Map.PlotSize / 2 -- the fence line
local GATE_X = 11.5 -- the gate towers' middle, either side
local FENCE_END = 14.5 -- where the front fence runs stop beside the gate

export type Hooks = {
	glow: (name: string, size: Vector3, cf: CFrame, colour: Color3, range: number?) -> BasePart,
	ivy: (parent: Instance, face: CFrame, height: number, seed: number) -> (),
}

-- `tiers` are the village's build tiers (3 the fence walls, 4 its pillars, 5 the gate)
function VillageWalls.build(m: Model, frame: CFrame, era: number, tiers: { number }, hooks: Hooks)
	local tw, tp, tg = TIERS[tiers[3]], TIERS[tiers[4]], TIERS[tiers[5]]
	local glow = hooks.glow
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local function bit(name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): Part
		local p = part(m, name, size, cf, colour, material or Enum.Material.SmoothPlastic) :: Part
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	local function ball(name: string, d: number, cf: CFrame, colour: Color3, material: Enum.Material?): Part
		local p = bit(name, Vector3.one * d, cf, colour, material)
		p.Shape = Enum.PartType.Ball
		return p
	end
	-- a vertical cylinder of height `h` and diameter `d` standing centred on `cf`
	local function column(name: string, h: number, d: number, cf: CFrame, colour: Color3, material: Enum.Material): Part
		local p = part(m, name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), colour, material) :: Part
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	-- glow kept off the long runs: slime tech trims glow, so long pieces take the walls instead
	local function calm(t: any): (Color3, Enum.Material)
		if t.trimMat == Enum.Material.Neon then
			return t.frame, t.frameMat -- (dark teal: the slime-tech pieces keep their contrast)
		end
		return t.trim, t.trimMat
	end
	-- a hanging flower basket under `hook` (built: the generator made a lump of it twice; the owner,
	-- 2026-10-28: the first built one was crude): three chains from a ring to a woven bowl of stacked
	-- bands that narrow toward its bottom, a rolled rim, a dome of leaves, petunias with pale hearts
	-- round it, and vines of small leaves trailing over the rim
	local function basket(hook: CFrame)
		local iron = Color3.fromRGB(56, 56, 62)
		local wicker = { Color3.fromRGB(190, 138, 80), Color3.fromRGB(168, 118, 66) }
		local leaves = { Color3.fromRGB(96, 168, 72), Color3.fromRGB(74, 142, 58), Color3.fromRGB(120, 188, 86) }
		local petals = { Color3.fromRGB(240, 112, 168), Color3.fromRGB(255, 238, 246), Color3.fromRGB(206, 84, 150) }
		column("BasketHook", 0.12, 0.45, hook * CFrame.new(0, -0.1, 0), iron, Enum.Material.Metal)
		ball("BasketRing", 0.3, hook * CFrame.new(0, -0.35, 0), iron, Enum.Material.Metal)
		local top = hook * CFrame.new(0, -2.3, 0) -- the rim's middle
		for k = 0, 2 do
			local a = k * math.pi * 2 / 3 + 0.3
			local from = Vector3.new(0, -0.45, 0)
			local to = Vector3.new(math.cos(a) * 0.95, -2.25, math.sin(a) * 0.95)
			bit(
				"BasketChain",
				Vector3.new(0.06, 0.06, (to - from).Magnitude),
				hook * CFrame.lookAt((from + to) / 2, to),
				iron,
				Enum.Material.Metal
			)
		end
		-- the bowl: woven bands, wide at the rim, narrow at the foot
		for j, band in { { 2.1, -0.2 }, { 1.85, -0.5 }, { 1.5, -0.78 }, { 1.05, -1.02 } } do
			column(
				"BasketWeave",
				0.32,
				band[1],
				top * CFrame.new(0, band[2], 0),
				wicker[j % 2 + 1],
				Enum.Material.Fabric
			)
		end
		column("BasketRim", 0.18, 2.3, top * CFrame.new(0, 0.02, 0), Color3.fromRGB(140, 96, 54), Enum.Material.Wood)
		-- the leaves: a low dome and clumps round it
		ball("BasketLeaves", 1, top * CFrame.new(0, 0.3, 0), leaves[1]).Size = Vector3.new(2, 0.9, 2)
		for k = 0, 5 do
			local a = k * math.pi / 3
			ball("BasketClump", 0.7, top * CFrame.new(math.cos(a) * 0.85, 0.25, math.sin(a) * 0.85), leaves[k % 3 + 1])
		end
		-- petunias: a ring of six and one on top, each a disc of petals with a pale heart
		for k = 0, 6 do
			local a = k * math.pi / 3 + 0.5
			local r = if k == 6 then 0 else 0.62
			local at0 = top * CFrame.new(math.cos(a) * r, if k == 6 then 0.85 else 0.62, math.sin(a) * r)
			ball("Petunia", 0.5, at0, petals[k % 3 + 1]).Size = Vector3.new(0.55, 0.28, 0.55)
			ball("PetuniaHeart", 0.16, at0 * CFrame.new(0, 0.12, 0), Color3.fromRGB(255, 236, 160))
		end
		-- vines trailing over the rim, each a chain of small leaves getting smaller
		for k = 0, 4 do
			local a = k * math.pi * 2 / 5 + 0.2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			for j = 0, 3 do
				local at0 = out * (1.12 + j * 0.06) + Vector3.new(0, -0.1 - j * 0.42, 0)
				local leafBall = ball("BasketVine", 0.42 - j * 0.06, top * CFrame.new(at0), leaves[(k + j) % 3 + 1])
				leafBall.Size = Vector3.new(0.42 - j * 0.06, 0.32, 0.42 - j * 0.06)
			end
		end
	end
	-- a wall lantern fixed to a wall face: `face` stands on the face, its front out from the wall. A
	-- back plate, a scrolled arm, a lantern hanging from it (cap, finial, four corner posts round warm
	-- glass, a base and a drop) (the owner, 2026-10-28: centred on the post, the same on every one)
	local function wallLantern(face: CFrame, lit: boolean)
		local iron = Color3.fromRGB(40, 40, 46)
		bit("LanternPlate", Vector3.new(0.7, 1.3, 0.12), face * CFrame.new(0, 0, -0.06), iron, Enum.Material.Metal)
		bit("LanternArm", Vector3.new(0.12, 0.12, 0.95), face * CFrame.new(0, 0.45, -0.55), iron, Enum.Material.Metal)
		ball("LanternScroll", 0.26, face * CFrame.new(0, 0.25, -0.2), iron, Enum.Material.Metal)
		local box = face * CFrame.new(0, -0.35, -1)
		bit("LanternHook", Vector3.new(0.08, 0.3, 0.08), box * CFrame.new(0, 0.75, 0), iron, Enum.Material.Metal)
		bit("LanternCap", Vector3.new(0.75, 0.15, 0.75), box * CFrame.new(0, 0.48, 0), iron, Enum.Material.Metal)
		bit("LanternRoof", Vector3.new(0.5, 0.18, 0.5), box * CFrame.new(0, 0.62, 0), iron, Enum.Material.Metal)
		for _, o in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
			bit(
				"LanternPost",
				Vector3.new(0.08, 0.75, 0.08),
				box * CFrame.new(o.X * 0.27, 0, o.Z * 0.27),
				iron,
				Enum.Material.Metal
			)
		end
		local glass =
			bit("LanternGlass", Vector3.new(0.48, 0.68, 0.48), box, Color3.fromRGB(255, 214, 140), Enum.Material.Neon)
		bit("LanternBase", Vector3.new(0.7, 0.12, 0.7), box * CFrame.new(0, -0.42, 0), iron, Enum.Material.Metal)
		ball("LanternDrop", 0.2, box * CFrame.new(0, -0.56, 0), iron, Enum.Material.Metal)
		if lit then
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 206, 140)
			light.Range = 10
			light.Brightness = 0.8
			light.Parent = glass
		end
	end
	-- a torch fixed to a wall face (`face` as above): a plate, a ring bracket, a wrapped handle leaning
	-- out a little, a flame of an orange body and a yellow heart
	local function wallTorch(face: CFrame, lit: boolean)
		local iron = Color3.fromRGB(46, 42, 42)
		bit("TorchPlate", Vector3.new(0.6, 1.1, 0.12), face * CFrame.new(0, 0, -0.06), iron, Enum.Material.Metal)
		bit("TorchStrut", Vector3.new(0.12, 0.12, 0.5), face * CFrame.new(0, -0.2, -0.3), iron, Enum.Material.Metal)
		column("TorchRing", 0.12, 0.42, face * CFrame.new(0, 0, -0.55), iron, Enum.Material.Metal)
		local lean = face * CFrame.new(0, 0, -0.55) * CFrame.Angles(math.rad(-15), 0, 0)
		column("TorchHandle", 1.9, 0.28, lean * CFrame.new(0, 0.25, 0), Color3.fromRGB(120, 78, 44), Enum.Material.Wood)
		column(
			"TorchWrap",
			0.45,
			0.42,
			lean * CFrame.new(0, 1.05, 0),
			Color3.fromRGB(196, 168, 120),
			Enum.Material.Fabric
		)
		local flame =
			ball("TorchFlame", 0.6, lean * CFrame.new(0, 1.6, 0), Color3.fromRGB(255, 130, 40), Enum.Material.Neon)
		flame.Size = Vector3.new(0.8, 1.2, 0.8)
		ball("TorchHeart", 0.3, lean * CFrame.new(0, 1.55, 0), Color3.fromRGB(255, 226, 110), Enum.Material.Neon).Size =
			Vector3.new(0.45, 0.75, 0.45)
		if lit then
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 160, 80)
			light.Range = 10
			light.Brightness = 0.9
			light.Parent = flame
		end
	end
	-- a generated decoration from the kit, its foot on `cf` (front to cf's -Z), `h` tall
	local function deco(key: string, cf: CFrame, h: number, foot: number)
		place(m, cf, key, 0, 0, h, foot)
	end

	-- ===== the fence =====
	if era >= 2 then
		local runs = {
			{ Vector3.new(-HALF, 0, HALF), Vector3.new(HALF, 0, HALF) },
			{ Vector3.new(-HALF, 0, -HALF), Vector3.new(-HALF, 0, HALF) },
			{ Vector3.new(HALF, 0, -HALF), Vector3.new(HALF, 0, HALF) },
			{ Vector3.new(-HALF, 0, -HALF), Vector3.new(-FENCE_END, 0, -HALF) },
			{ Vector3.new(HALF, 0, -HALF), Vector3.new(FENCE_END, 0, -HALF) },
		}
		local pillarAt: { { at: Vector3, inward: Vector3, runs: number } } = {}
		local soft, softMat = calm(tw)
		for _, run in runs do
			local a, b = run[1], run[2]
			local len = (b - a).Magnitude
			local dir = (b - a).Unit
			local turn = CFrame.lookAt(Vector3.zero, dir) -- local -Z along the run, X across it
			local n = math.max(1, math.round(len / 24))
			part(
				m,
				"FenceFooting",
				Vector3.new(2.6, 1.4, len + 2.6),
				frame * CFrame.new((a + b) / 2 + Vector3.new(0, 0.5, 0)) * turn,
				tw.base,
				tw.baseMat
			)
			for k = 0, n do
				local p = a:Lerp(b, k / n)
				local seen = false
				for _, q in pillarAt do
					if (p - q.at).Magnitude < 1 then
						seen = true
						q.runs += 1 -- (a corner: two runs meet at it)
					end
				end
				if not seen then
					-- (square to its run, facing into the plot)
					local across = Vector3.new(dir.Z, 0, -dir.X)
					local mid0 = (a + b) / 2
					local inward = if (mid0 + across).Magnitude < mid0.Magnitude then across else -across
					table.insert(pillarAt, { at = p, inward = inward, runs = 1 })
				end
				if k < n then
					local mid = a:Lerp(b, (k + 0.5) / n)
					local w = len / n - 2.4
					local seg = frame * CFrame.new(mid) * turn
					-- +1 or -1: which way across the run (seg's X) is inside the plot
					local inX = frame:VectorToObjectSpace(seg.RightVector)
					local sgn = if (mid + inX).Magnitude < mid.Magnitude then 1 else -1
					if era == 2 then
						-- painted timber estate fence
						part(
							m,
							"KickBoard",
							Vector3.new(0.9, 1.2, w),
							seg * CFrame.new(0, 1.8, 0),
							tw.frame,
							tw.frameMat
						)
						part(
							m,
							"FencePanel",
							Vector3.new(0.5, 4.6, w),
							seg * CFrame.new(0, 4.7, 0),
							tw.walls,
							tw.wallMat
						)
						local battens = math.max(3, math.floor(w / 3))
						for j = 1, battens do
							local zj = -w / 2 + j * w / (battens + 1)
							bit("Batten", Vector3.new(0.7, 4.6, 0.35), seg * CFrame.new(0, 4.7, zj), soft, softMat)
						end
						part(m, "MidRail", Vector3.new(0.9, 0.5, w), seg * CFrame.new(0, 7.2, 0), tw.frame, tw.frameMat)
						-- the lattice band: an X in every cell
						local cells = math.max(2, math.floor(w / 2.4))
						local cw = w / cells
						local diag = math.sqrt(cw * cw + 2.4 * 2.4)
						local ang = math.atan2(2.4, cw)
						for j = 1, cells do
							local zj = -w / 2 + (j - 0.5) * cw
							for _, s in { -1, 1 } do
								bit(
									"Lattice",
									Vector3.new(0.25, 0.22, diag),
									seg * CFrame.new(0, 8.65, zj) * CFrame.Angles(s * ang, 0, 0),
									soft,
									softMat
								)
							end
						end
						part(m, "TopRail", Vector3.new(1, 0.5, w), seg * CFrame.new(0, 10.1, 0), tw.frame, tw.frameMat)
						bit("RailCap", Vector3.new(1.3, 0.25, w), seg * CFrame.new(0, 10.45, 0), soft, softMat)
						if k % 2 == 0 then
							place(
								m,
								seg * CFrame.new(sgn * 1.6, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
								"FlowerBedWood",
								0,
								0,
								1.7,
								math.min(6, w * 0.4)
							)
						end
					elseif era == 3 then
						-- brick wall on a stone plinth, string courses, a corbelled coping, merlons
						bit("PlinthCourse", Vector3.new(2.3, 0.35, w), seg * CFrame.new(0, 1.35, 0), soft, softMat)
						part(m, "FenceWall", Vector3.new(2, 8.6, w), seg * CFrame.new(0, 5.8, 0), tw.walls, tw.wallMat)
						bit("StringCourse", Vector3.new(2.25, 0.3, w), seg * CFrame.new(0, 8.4, 0), soft, softMat)
						local corbels = math.max(3, math.floor(w / 2))
						for j = 1, corbels do
							local zj = -w / 2 + (j - 0.5) * w / corbels
							bit(
								"Corbel",
								Vector3.new(2.5, 0.35, 0.7),
								seg * CFrame.new(0, 9.85, zj),
								tw.base,
								tw.baseMat
							)
						end
						part(m, "FenceCoping", Vector3.new(2.7, 0.5, w), seg * CFrame.new(0, 10.3, 0), soft, softMat)
						local merlons = math.max(1, math.floor(w / 4))
						for j = 1, merlons do
							local zj = -w / 2 + (j - 0.5) * w / merlons
							part(
								m,
								"Merlon",
								Vector3.new(2, 1.5, 1.8),
								seg * CFrame.new(0, 11.3, zj),
								tw.walls,
								tw.wallMat
							)
							bit("MerlonCap", Vector3.new(2.3, 0.25, 2.1), seg * CFrame.new(0, 12.15, zj), soft, softMat)
						end
						-- ivy on every bay, inside and outside by turns; a bed at the foot of those inside
						local side = if k % 2 == 1 then -sgn else sgn
						local away = seg.RightVector * side
						local base = seg.Position + away * 1.02 + seg.LookVector * ((k % 3 - 1) * w * 0.18)
						hooks.ivy(m, CFrame.lookAt(base, base + away), 8 + k % 3, k)
						if k % 2 == 0 then
							part(
								m,
								"WallBed",
								Vector3.new(1.6, 0.7, w * 0.6),
								seg * CFrame.new(side * 2.3, 0.35, 0),
								tw.base,
								tw.baseMat
							)
						end
					elseif era == 4 then
						-- steel and glass: a concrete base, glass between mullions, a lit top rail
						part(m, "FenceBase", Vector3.new(1.6, 2.4, w), seg * CFrame.new(0, 2.4, 0), tw.base, tw.baseMat)
						bit("BaseEdge", Vector3.new(1.8, 0.2, w), seg * CFrame.new(0, 3.7, 0), tw.frame, tw.frameMat)
						local glass = part(
							m,
							"FenceGlass",
							Vector3.new(0.25, 6.4, w),
							seg * CFrame.new(0, 7, 0),
							tw.glass,
							Enum.Material.Glass
						)
						glass.Transparency = 0.5
						glass.CastShadow = false
						for j = 1, 2 do
							local zj = -w / 2 + j * w / 3
							part(
								m,
								"Mullion",
								Vector3.new(0.45, 6.4, 0.45),
								seg * CFrame.new(0, 7, zj),
								tw.frame,
								tw.frameMat
							)
						end
						bit("Transom", Vector3.new(0.4, 0.25, w), seg * CFrame.new(0, 7, 0), tw.frame, tw.frameMat)
						part(
							m,
							"TopRail",
							Vector3.new(0.9, 0.5, w),
							seg * CFrame.new(0, 10.45, 0),
							tw.frame,
							tw.frameMat
						)
						glow("RailLight", Vector3.new(0.3, 0.12, w), seg * CFrame.new(0, 10.15, 0), tw.trim)
						glow(
							"FootLight",
							Vector3.new(0.12, 0.15, w * 0.9),
							seg * CFrame.new(sgn * 0.85, 1.6, 0),
							tw.trim
						)
					else
						-- marble: a stepped plinth, a wall with framed sunk panels, a cornice, balusters
						part(
							m,
							"PlinthStep",
							Vector3.new(2.4, 0.5, w),
							seg * CFrame.new(0, 1.45, 0),
							tw.base,
							tw.baseMat
						)
						part(
							m,
							"FenceWall",
							Vector3.new(1.8, 5.8, w),
							seg * CFrame.new(0, 4.6, 0),
							tw.walls,
							tw.wallMat
						)
						local panels = math.max(1, math.floor(w / 6))
						local pw = w / panels - 1
						for j = 1, panels do
							local zj = -w / 2 + (j - 0.5) * w / panels
							for _, s in { -1, 1 } do
								local face = seg * CFrame.new(s * 0.92, 4.6, zj)
								bit("PanelTop", Vector3.new(0.08, 0.2, pw), face * CFrame.new(0, 1.9, 0), soft, softMat)
								bit(
									"PanelFoot",
									Vector3.new(0.08, 0.2, pw),
									face * CFrame.new(0, -1.9, 0),
									soft,
									softMat
								)
								bit(
									"PanelSide",
									Vector3.new(0.08, 3.8, 0.2),
									face * CFrame.new(0, 0, -pw / 2),
									soft,
									softMat
								)
								bit(
									"PanelSide",
									Vector3.new(0.08, 3.8, 0.2),
									face * CFrame.new(0, 0, pw / 2),
									soft,
									softMat
								)
							end
						end
						part(
							m,
							"Cornice",
							Vector3.new(2.4, 0.35, w),
							seg * CFrame.new(0, 7.65, 0),
							tw.walls,
							tw.wallMat
						)
						bit("CorniceLip", Vector3.new(2.7, 0.25, w), seg * CFrame.new(0, 7.95, 0), soft, softMat)
						part(
							m,
							"BaseRail",
							Vector3.new(1.6, 0.35, w),
							seg * CFrame.new(0, 8.25, 0),
							tw.walls,
							tw.wallMat
						)
						local posts = math.max(3, math.floor(w / 2))
						for j = 1, posts do
							local zj = -w / 2 + (j - 0.5) * w / posts
							column("Baluster", 1.8, 0.45, seg * CFrame.new(0, 9.3, zj), tw.walls, tw.wallMat)
							ball("BalusterBelly", 0.8, seg * CFrame.new(0, 9.05, zj), tw.walls, tw.wallMat)
						end
						part(
							m,
							"Handrail",
							Vector3.new(1.2, 0.45, w),
							seg * CFrame.new(0, 10.4, 0),
							tw.walls,
							tw.wallMat
						)
						bit("HandrailTrim", Vector3.new(1.3, 0.12, w), seg * CFrame.new(0, 10.68, 0), soft, softMat)
					end
				end
			end
		end

		-- the pillars
		local psoft, psoftMat = calm(tp)
		for k, pa in pillarAt do
			local p = pa.at
			-- (each pillar faces into the plot)
			local c = frame * CFrame.new(p) * CFrame.lookAt(Vector3.zero, pa.inward)
			-- (the fence's end posts stand against the gate towers, which carry their own lamps)
			local atGate = math.abs(p.X) < FENCE_END + 1 and p.Z < -HALF + 1
			if era == 2 then
				part(m, "PillarFoot", Vector3.new(3.2, 1.6, 3.2), c * CFrame.new(0, 0.8, 0), tp.base, tp.baseMat)
				part(m, "FencePillar", Vector3.new(2.4, 9.8, 2.4), c * CFrame.new(0, 6.5, 0), tp.walls, tp.wallMat)
				for _, f in { CFrame.new(0, 0, 0), CFrame.Angles(0, math.rad(90), 0) } do
					for _, s in { -1, 1 } do
						bit(
							"SunkPanel",
							Vector3.new(1.3, 6.4, 0.1),
							c * f * CFrame.new(0, 6.4, s * 1.22),
							tp.frame,
							tp.frameMat
						)
					end
				end
				part(m, "PillarBand", Vector3.new(2.8, 0.5, 2.8), c * CFrame.new(0, 11.5, 0), tp.frame, tp.frameMat)
				part(m, "PillarCap", Vector3.new(3.3, 0.45, 3.3), c * CFrame.new(0, 12, 0), psoft, psoftMat)
				part(m, "CapStep", Vector3.new(2.3, 0.45, 2.3), c * CFrame.new(0, 12.45, 0), tp.frame, tp.frameMat)
				ball("Finial", 1.1, c * CFrame.new(0, 13.2, 0), psoft, psoftMat)
				-- a lantern centred on both faces of every post but the corners; every other one lit
				if pa.runs == 1 and not atGate then
					for _, side in { -1, 1 } do
						wallLantern(
							c * CFrame.new(0, 8.2, side * 1.22) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
							side < 0 and k % 2 == 0
						)
					end
				end
			elseif era == 3 then
				part(m, "TowerFoot", Vector3.new(4.8, 1.8, 4.8), c * CFrame.new(0, 0.9, 0), tp.base, tp.baseMat)
				part(m, "FenceTower", Vector3.new(4, 12.6, 4), c * CFrame.new(0, 8.1, 0), tp.walls, tp.wallMat)
				-- quoins: corner stones up the tower, long and short by turns
				for j = 0, 2 do
					local y = 3.6 + j * 3.6
					for _, o in
						{ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }
					do
						local long = (j + (if o.X * o.Z > 0 then 0 else 1)) % 2 == 0
						bit(
							"Quoin",
							if long then Vector3.new(1.3, 0.9, 0.7) else Vector3.new(0.7, 0.9, 1.3),
							c
								* CFrame.new(
									o.X * (2.08 - (if long then 0.65 else 0.35)),
									y,
									o.Z * (2.08 - (if long then 0.35 else 0.65))
								),
							tp.base,
							tp.baseMat
						)
					end
				end
				part(m, "CorbelBand", Vector3.new(4.6, 0.6, 4.6), c * CFrame.new(0, 14.7, 0), psoft, psoftMat)
				for _, o in
					{
						Vector3.new(1.5, 0, 1.5),
						Vector3.new(-1.5, 0, 1.5),
						Vector3.new(1.5, 0, -1.5),
						Vector3.new(-1.5, 0, -1.5),
					}
				do
					part(
						m,
						"TowerMerlon",
						Vector3.new(1.3, 1.5, 1.3),
						c * CFrame.new(o + Vector3.new(0, 15.75, 0)),
						tp.walls,
						tp.wallMat
					)
					bit(
						"MerlonCap",
						Vector3.new(1.5, 0.25, 1.5),
						c * CFrame.new(o + Vector3.new(0, 16.6, 0)),
						psoft,
						psoftMat
					)
				end
				-- a torch centred on both faces of every tower but the corners; every other one lit
				if pa.runs == 1 and not atGate then
					for _, side in { -1, 1 } do
						wallTorch(
							c * CFrame.new(0, 7.2, side * 2) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
							side < 0 and k % 2 == 0
						)
					end
				end
			elseif era == 4 then
				part(m, "PillarPlate", Vector3.new(2.6, 0.5, 2.6), c * CFrame.new(0, 1.45, 0), tp.base, tp.baseMat)
				part(m, "PillarWeb", Vector3.new(0.6, 9.4, 1.6), c * CFrame.new(0, 6.4, 0), tp.frame, tp.frameMat)
				for _, s in { -1, 1 } do
					part(
						m,
						"PillarFlange",
						Vector3.new(1.8, 9.4, 0.3),
						c * CFrame.new(0, 6.4, s * 0.95),
						tp.frame,
						tp.frameMat
					)
				end
				glow("PillarLight", Vector3.new(1.7, 1.4, 1.7), c * CFrame.new(0, 11.8, 0), tp.trim)
				part(m, "PillarCap", Vector3.new(2.3, 0.4, 2.3), c * CFrame.new(0, 12.7, 0), tp.frame, tp.frameMat)
			else
				part(m, "ColumnPlinth", Vector3.new(3.2, 1.2, 3.2), c * CFrame.new(0, 1.8, 0), tp.base, tp.baseMat)
				column("ColumnTorus", 0.5, 2.9, c * CFrame.new(0, 2.65, 0), psoft, psoftMat)
				column("FenceColumn", 7.6, 2.3, c * CFrame.new(0, 6.7, 0), tp.walls, tp.wallMat)
				column("ColumnNeck", 0.4, 2.6, c * CFrame.new(0, 10.6, 0), psoft, psoftMat)
				part(m, "ColumnCap", Vector3.new(3.1, 0.6, 3.1), c * CFrame.new(0, 11.1, 0), tp.walls, tp.wallMat)
				bit("CapTrim", Vector3.new(3.3, 0.15, 3.3), c * CFrame.new(0, 11.45, 0), psoft, psoftMat)
				if k % 2 == 0 then
					deco("MarbleUrn", c * CFrame.new(0, 11.5, 0), 3, 2.6)
				else
					ball("ColumnBall", 1.4, c * CFrame.new(0, 12.2, 0), psoft, psoftMat)
				end
			end
		end
	end

	-- ===== the main gate =====
	part(m, "GateLanding", Vector3.new(GATE_X * 2 + 4, 0.4, 7), at(0, 0.2, -HALF - 4.5), tg.base, tg.baseMat)
	if era < 2 then
		return
	end
	local gsoft, gsoftMat = calm(tg)
	if era == 2 then
		-- the timber gatehouse
		for _, sx in { -1, 1 } do
			local tower = at(sx * GATE_X, 0, -HALF)
			part(m, "TowerFoot", Vector3.new(5.2, 2.4, 5.2), tower * CFrame.new(0, 1.2, 0), tg.base, tg.baseMat)
			part(m, "GateTower", Vector3.new(4.4, 11.6, 4.4), tower * CFrame.new(0, 8.2, 0), tg.walls, tg.wallMat)
			for _, o in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
				part(
					m,
					"CornerPost",
					Vector3.new(0.7, 11.6, 0.7),
					tower * CFrame.new(o.X * 2.2, 8.2, o.Z * 2.2),
					tg.frame,
					tg.frameMat
				)
			end
			part(m, "TowerBand", Vector3.new(4.8, 0.4, 4.8), tower * CFrame.new(0, 6.6, 0), tg.frame, tg.frameMat)
			part(m, "TowerTopBand", Vector3.new(4.9, 0.5, 4.9), tower * CFrame.new(0, 14.25, 0), tg.frame, tg.frameMat)
			-- a lit window with its shutters and a flower box, on the front
			local win = tower * CFrame.new(0, 10.4, -2.25)
			bit("WindowFrame", Vector3.new(2.2, 2.8, 0.2), win, tg.frame, tg.frameMat)
			glow("WindowGlass", Vector3.new(1.7, 2.3, 0.1), win * CFrame.new(0, 0, -0.06), tg.glass)
			bit("WindowBar", Vector3.new(0.15, 2.3, 0.08), win * CFrame.new(0, 0, -0.14), tg.frame, tg.frameMat)
			bit("WindowBar", Vector3.new(1.7, 0.15, 0.08), win * CFrame.new(0, 0, -0.14), tg.frame, tg.frameMat)
			for _, s in { -1, 1 } do
				bit(
					"Shutter",
					Vector3.new(0.9, 2.6, 0.15),
					win * CFrame.new(s * 1.6, 0, -0.25) * CFrame.Angles(0, math.rad(s * 25), 0),
					gsoft,
					gsoftMat
				)
			end
			place(m, win * CFrame.new(0, -1.7, -0.5), "FlowerBedWood", 0, 0, 1.2, 2.4)
			-- the gable roof with eaves, a ridge and a finial
			for _, sz in { -1, 1 } do
				wedge(
					m,
					"TowerRoof",
					Vector3.new(5.8, 3, 3),
					tower * CFrame.new(0, 16, sz * 1.5) * CFrame.Angles(0, if sz < 0 then 0 else math.pi, 0),
					tg.roof,
					tg.roofMat
				)
			end
			part(m, "RoofRidge", Vector3.new(6, 0.35, 0.5), tower * CFrame.new(0, 17.6, 0), tg.frame, tg.frameMat)
			ball("RoofFinial", 0.8, tower * CFrame.new(0, 18.1, 0), gsoft, gsoftMat)
			-- a lantern centred under the window on the front face, and one on the back; a planter at its
			-- outer foot
			wallLantern(tower * CFrame.new(0, 6.6, -2.2), true)
			wallLantern(tower * CFrame.new(0, 6.6, 2.2) * CFrame.Angles(0, math.pi, 0), false)
			place(m, tower * CFrame.new(sx * 4.6, 0, -2.6), "FlowerBedWood", 0, 0, 1.8, 3.2)
		end
		-- the beam across, its knee braces, the little shingled roof over it
		part(m, "GateBeam", Vector3.new(GATE_X * 2, 1.2, 1.2), at(0, 13.6, -HALF), tg.frame, tg.frameMat)
		for _, sx in { -1, 1 } do
			wedge(
				m,
				"KneeBrace",
				Vector3.new(0.6, 1.6, 1.6),
				at(sx * (GATE_X - 3), 12.2, -HALF) * CFrame.Angles(0, math.rad(sx * 90), math.pi),
				tg.frame,
				tg.frameMat
			)
			-- a hanging flower basket either side of the way through
			basket(at(sx * 7.2, 13, -HALF - 0.9))
		end
		for _, sz in { -1, 1 } do
			wedge(
				m,
				"BeamRoof",
				Vector3.new(GATE_X * 2 - 4, 1.2, 1.4),
				at(0, 14.8, -HALF + sz * 0.7) * CFrame.Angles(0, if sz < 0 then 0 else math.pi, 0),
				tg.roof,
				tg.roofMat
			)
		end
	elseif era == 3 then
		-- the stone gatehouse
		local banner = Color3.fromRGB(176, 52, 52)
		for _, sx in { -1, 1 } do
			local tower = at(sx * (GATE_X + 0.5), 0, -HALF)
			part(m, "TowerFoot", Vector3.new(6.8, 2, 6.8), tower * CFrame.new(0, 1, 0), tg.base, tg.baseMat)
			part(m, "GateTower", Vector3.new(6, 15.4, 6), tower * CFrame.new(0, 9.7, 0), tg.walls, tg.wallMat)
			for j = 0, 3 do
				local y = 3.5 + j * 3.4
				for _, o in
					{ Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) }
				do
					local long = (j + (if o.X * o.Z > 0 then 0 else 1)) % 2 == 0
					bit(
						"Quoin",
						if long then Vector3.new(1.6, 1, 0.8) else Vector3.new(0.8, 1, 1.6),
						tower
							* CFrame.new(
								o.X * (3.08 - (if long then 0.8 else 0.4)),
								y,
								o.Z * (3.08 - (if long then 0.4 else 0.8))
							),
						tg.base,
						tg.baseMat
					)
				end
			end
			-- arrow slits on the outer side (the front carries the banner and the torch)
			for _, y in { 8, 12.5 } do
				bit(
					"ArrowSlit",
					Vector3.new(0.12, 2, 0.4),
					tower * CFrame.new(sx * 3.02, y, 0),
					Color3.fromRGB(34, 30, 30)
				)
			end
			part(m, "CorbelBand", Vector3.new(6.8, 0.7, 6.8), tower * CFrame.new(0, 17.7, 0), gsoft, gsoftMat)
			for _, o in
				{
					Vector3.new(2.3, 0, 2.3),
					Vector3.new(-2.3, 0, 2.3),
					Vector3.new(2.3, 0, -2.3),
					Vector3.new(-2.3, 0, -2.3),
				}
			do
				part(
					m,
					"TowerMerlon",
					Vector3.new(1.8, 2, 1.8),
					tower * CFrame.new(o + Vector3.new(0, 19, 0)),
					tg.walls,
					tg.wallMat
				)
				bit(
					"MerlonCap",
					Vector3.new(2, 0.3, 2),
					tower * CFrame.new(o + Vector3.new(0, 20.15, 0)),
					gsoft,
					gsoftMat
				)
			end
			-- a banner on the front: a rod, the cloth, a swallowtail, a gold disc and stripe
			local bn = tower * CFrame.new(0, 0, -3.15)
			bit("BannerRod", Vector3.new(3.4, 0.25, 0.25), bn * CFrame.new(0, 15.6, -0.1), tg.frame, tg.frameMat)
			bit("BannerCloth", Vector3.new(2.6, 4.6, 0.12), bn * CFrame.new(0, 13.2, 0), banner)
			for _, s in { -1, 1 } do
				local tail = Instance.new("WedgePart")
				tail.Name = "BannerTail"
				tail.Size = Vector3.new(0.12, 1.2, 1.3)
				tail.CFrame = bn * CFrame.new(s * 0.65, 10.3, 0) * CFrame.Angles(0, math.rad(90), math.pi)
				tail.Color = banner
				tail.Material = Enum.Material.SmoothPlastic
				tail.Anchored = true
				tail.CanCollide = false
				tail.CastShadow = false
				tail.Parent = m
			end
			bit(
				"BannerStripe",
				Vector3.new(2.6, 0.3, 0.14),
				bn * CFrame.new(0, 14.9, -0.02),
				Color3.fromRGB(230, 190, 80)
			)
			local disc = bit(
				"BannerDisc",
				Vector3.new(0.14, 1.4, 1.4),
				bn * CFrame.new(0, 13, -0.05) * CFrame.Angles(0, math.rad(90), 0),
				Color3.fromRGB(230, 190, 80)
			)
			disc.Shape = Enum.PartType.Cylinder
			-- a torch centred under the banner on the front face, and one on the back; a planter at
			-- the outer foot
			wallTorch(tower * CFrame.new(0, 7.2, -3), true)
			wallTorch(tower * CFrame.new(0, 7.2, 3) * CFrame.Angles(0, math.pi, 0), false)
			place(m, tower * CFrame.new(sx * 5.4, 0, -2.4), "FlowerBedBrick", 0, 0, 2, 3.4)
		end
		-- the arch under the bridge: voussoirs in the trim, the spandrels filled
		local half, spring, rise = 9, 11.6, 2.8
		local segs = 11
		for j = 0, segs - 1 do
			local u0, u1 = j / segs, (j + 1) / segs
			local function pt(u: number): Vector3
				local a = math.pi * (1 - u)
				return Vector3.new(math.cos(a) * half, spring + math.sin(a) * rise, 0)
			end
			local p0, p1 = pt(u0), pt(u1)
			local c = (p0 + p1) / 2
			local len = (p1 - p0).Magnitude + 0.1
			part(
				m,
				"Voussoir",
				Vector3.new(len, 0.9, 4.2),
				at(c.X, c.Y, -HALF) * CFrame.Angles(0, 0, math.atan2(p1.Y - p0.Y, p1.X - p0.X)),
				if j == 5 then tg.trim else tg.base,
				if j == 5 then tg.trimMat else tg.baseMat
			)
			local top = math.max(p0.Y, p1.Y) + 0.4
			if top < 14.6 then
				part(
					m,
					"Spandrel",
					Vector3.new(math.abs(p1.X - p0.X), 14.6 - top, 4),
					at(c.X, (top + 14.6) / 2, -HALF),
					tg.walls,
					tg.wallMat
				)
			end
		end
		part(m, "GateBridge", Vector3.new(GATE_X * 2, 3.4, 4.4), at(0, 16.3, -HALF), tg.walls, tg.wallMat)
		bit("BridgeCourse", Vector3.new(GATE_X * 2, 0.4, 4.8), at(0, 14.75, -HALF), gsoft, gsoftMat)
		-- machicolations: corbels under the parapet's front
		for j = -4, 4 do
			bit("Machicolation", Vector3.new(0.7, 0.9, 0.7), at(j * 2.2, 17.4, -HALF - 2.4), tg.base, tg.baseMat)
		end
		part(m, "Parapet", Vector3.new(GATE_X * 2, 0.6, 5), at(0, 18.2, -HALF), gsoft, gsoftMat)
		for j = -2, 2 do
			part(m, "BridgeMerlon", Vector3.new(1.8, 1.6, 4.4), at(j * 3.6, 19.3, -HALF), tg.walls, tg.wallMat)
			bit("MerlonCap", Vector3.new(2, 0.25, 4.6), at(j * 3.6, 20.2, -HALF), gsoft, gsoftMat)
		end
	elseif era == 4 then
		-- the steel and glass portal
		for _, sx in { -1, 1 } do
			local tower = at(sx * GATE_X, 0, -HALF)
			part(m, "TowerPlate", Vector3.new(4.2, 0.6, 4.2), tower * CFrame.new(0, 0.7, 0), tg.base, tg.baseMat)
			local glass = part(
				m,
				"GateGlass",
				Vector3.new(3.2, 15.4, 3.2),
				tower * CFrame.new(0, 8.7, 0),
				tg.glass,
				Enum.Material.Glass
			)
			glass.Transparency = 0.4
			glass.CastShadow = false
			for _, o in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
				part(
					m,
					"GateFrame",
					Vector3.new(0.5, 15.4, 0.5),
					tower * CFrame.new(o.X * 1.6, 8.7, o.Z * 1.6),
					tg.frame,
					tg.frameMat
				)
			end
			for j = 1, 4 do
				local y = 1 + j * 3.1
				for _, s in { -1, 1 } do
					bit(
						"GateMullion",
						Vector3.new(3.2, 0.25, 0.3),
						tower * CFrame.new(0, y, s * 1.6),
						tg.frame,
						tg.frameMat
					)
				end
			end
			glow("GateLight", Vector3.new(0.3, 14.4, 0.3), tower * CFrame.new(-sx * 1.65, 8.7, -1.65), tg.trim, 12)
			part(m, "TowerCap", Vector3.new(3.9, 0.6, 3.9), tower * CFrame.new(0, 16.7, 0), tg.frame, tg.frameMat)
			place(m, tower * CFrame.new(sx * 4.2, 0, -2.2), "FlowerBedSteel2", 0, 0, 1.8, 3.6)
		end
		local canopy = part(
			m,
			"GateCanopy",
			Vector3.new(GATE_X * 2 + 6, 0.5, 7),
			at(0, 17.3, -HALF - 1),
			tg.glass,
			Enum.Material.Glass
		)
		canopy.Transparency = 0.35
		canopy.CastShadow = false
		part(m, "CanopyBeam", Vector3.new(GATE_X * 2 + 6, 0.9, 0.9), at(0, 17.3, -HALF - 4.5), tg.frame, tg.frameMat)
		part(m, "CanopyBack", Vector3.new(GATE_X * 2 + 6, 0.9, 0.9), at(0, 17.3, -HALF + 2.5), tg.frame, tg.frameMat)
		for j = -5, 5 do
			bit("CanopyFin", Vector3.new(0.25, 0.7, 7), at(j * 2.4, 16.75, -HALF - 1), tg.frame, tg.frameMat)
		end
		glow("CanopyLight", Vector3.new(GATE_X * 2 + 5, 0.15, 0.3), at(0, 16.8, -HALF - 4.5), tg.trim)
		-- bollards on the landing
		for _, sx in { -1, 1 } do
			for _, dz in { -2.5, -6.5 } do
				local bc = at(sx * 8.4, 0, -HALF + dz)
				column("Bollard", 1.6, 0.7, bc * CFrame.new(0, 1.2, 0), tg.frame, tg.frameMat)
				glow("BollardLight", Vector3.new(0.75, 0.25, 0.75), bc * CFrame.new(0, 2.1, 0), tg.trim)
			end
		end
	else
		-- the marble arch
		for _, sx in { -1, 1 } do
			part(m, "ColumnBase", Vector3.new(4.4, 1.2, 7), at(sx * GATE_X, 0.6, -HALF), tg.base, tg.baseMat)
			for _, dz in { -1.6, 1.6 } do
				local cc = at(sx * GATE_X, 0, -HALF + dz)
				part(m, "ColumnPlinth", Vector3.new(3, 0.8, 3), cc * CFrame.new(0, 1.6, 0), tg.walls, tg.wallMat)
				column("ColumnTorus", 0.5, 2.9, cc * CFrame.new(0, 2.25, 0), gsoft, gsoftMat)
				column("GateColumn", 12.6, 2.4, cc * CFrame.new(0, 8.8, 0), tg.walls, tg.wallMat)
				-- flutes: four thin grooves round the shaft
				for f = 0, 3 do
					local a = f * math.pi / 2 + math.pi / 4
					bit(
						"Flute",
						Vector3.new(0.15, 11.4, 0.15),
						cc * CFrame.new(math.cos(a) * 1.18, 8.8, math.sin(a) * 1.18),
						tg.base,
						tg.baseMat
					)
				end
				column("ColumnNeck", 0.4, 2.7, cc * CFrame.new(0, 15.3, 0), gsoft, gsoftMat)
				part(m, "Capital", Vector3.new(3.2, 0.8, 3.2), cc * CFrame.new(0, 15.9, 0), tg.walls, tg.wallMat)
				for _, s in { -1, 1 } do
					local v = bit(
						"Volute",
						Vector3.new(0.6, 0.9, 0.9),
						cc * CFrame.new(s * 1.45, 15.75, -0.9) * CFrame.Angles(0, 0, 0),
						gsoft,
						gsoftMat
					)
					v.Shape = Enum.PartType.Cylinder
				end
			end
			-- a golden lamp on the landing beside each base
			place(m, at(sx * (GATE_X + 3.6), 0, -HALF - 5), "GoldenLampPost", 0, 0, 9.2, 2.6)
			place(m, at(sx * (GATE_X + 4.4), 0, -HALF - 1.6), "FlowerBedMarble", 0, 0, 2, 3.6)
		end
		local span = GATE_X * 2 + 5
		part(m, "Architrave", Vector3.new(span, 1.2, 6.6), at(0, 16.9, -HALF), tg.walls, tg.wallMat)
		bit("Frieze", Vector3.new(span, 0.5, 6.8), at(0, 17.6, -HALF), gsoft, gsoftMat)
		part(m, "Entablature", Vector3.new(span, 1, 6.6), at(0, 18.35, -HALF), tg.walls, tg.wallMat)
		part(m, "Cornice", Vector3.new(span + 0.8, 0.5, 7.4), at(0, 19.1, -HALF), tg.walls, tg.wallMat)
		bit("CorniceTrim", Vector3.new(span + 0.9, 0.15, 7.5), at(0, 19.4, -HALF), gsoft, gsoftMat)
		for _, sx in { -1, 1 } do
			wedge(
				m,
				"Pediment",
				Vector3.new(6.2, 3.4, span / 2),
				at(sx * span / 4, 21.15, -HALF) * CFrame.Angles(0, math.rad(-sx * 90), 0),
				tg.walls,
				tg.wallMat
			)
			-- gold edging along the pediment's slope
			local slope = math.atan2(3.4, span / 2)
			bit(
				"PedimentTrim",
				Vector3.new(math.sqrt((span / 2) ^ 2 + 3.4 ^ 2), 0.3, 6.4),
				at(sx * span / 4, 21.25, -HALF) * CFrame.Angles(0, 0, -sx * slope),
				gsoft,
				gsoftMat
			)
			deco("MarbleUrn", at(sx * (span / 2 - 1.2), 19.45, -HALF), 3.2, 2.6)
		end
		-- the golden slime crest in the pediment, and marble steps on the landing
		local crest = Instance.new("Model")
		crest.Name = "GateCrest"
		crest.Parent = m
		place(crest, at(0, 0, -HALF - 3.4), "GoldCrest", 0, 0, 3.2, 3.6, 19.8)
		for j = 1, 2 do
			part(
				m,
				"Step",
				Vector3.new(16, 0.3, 1.4),
				at(0, 0.4 + (j - 1) * 0.3, -HALF - 7.2 + j * 1.4),
				tg.walls,
				tg.wallMat
			)
		end
	end
end

return VillageWalls
