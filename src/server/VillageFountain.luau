--!strict
-- The fountain at the heart of the village plaza, one for each era from the painted era on (era 1
-- keeps the kit well), the village's showpiece (the owner, 2026-10-28: "the highest quality
-- possible, moving water if it can"). Built from parts in the plaza's material tier; the water moves
-- through the engine itself, so no script runs for it:
--   * jets      ParticleEmitters of water drops (a droplet texture, stretched along their flight)
--   * curtains  Beams of falling water from every bowl's rim to the water below, their streak
--               texture scrolling (TextureSpeed)
--   * splashes  where curtains and jets land, small white bursts
--   * ripples   rings that open and fade on every pool
--   * shimmer   each pool is a still blue disc under a thin ForceField-material film, which the engine
--               animates as moving light
-- The textures are free Creator Store images (no scripts, credited in docs/kit/README.md).
--   era 2  a stone village fountain: a round basin with pilasters, a pedestal and one bowl, a jet
--   era 3  two tiers over a wider basin, four fish spouts on the rim arcing water to the centre
--   era 4  a modern basin, eight arcing jets from its rim, a glass sculpture of three lit discs
--   era 5  a grand three-tier fountain on a stepped plinth, gold rosettes, shell spouts, the golden
--          slime statue on top, jets arching out from the middle tier
-- Footprints (diameter) 9, 11, 12.5, 13.5; heights about 5, 8, 9.5, 11 (the player is 5 studs).
local PantryStages = require(script.Parent.PantryStages)

local VillageFountain = {}

local TIERS = PantryStages.Tiers
local part, place = PantryStages.part, PantryStages.place

-- the water art (Creator Store images)
local TEX = {
	drop = "rbxassetid://113689065664958", -- a water droplet, recolourable (decal 111709169217539)
	splash = "rbxassetid://243457340", -- a white splash (decal 243457341)
	ripple = "rbxassetid://101873502982973", -- a cartoon ripple ring (decal 95861972723548)
	curtain = "rbxassetid://1610017834", -- falling water streaks (decal 1610017853)
}
VillageFountain.Textures = TEX

local WATER = Color3.fromRGB(86, 176, 226)
local WATER_LIGHT = Color3.fromRGB(190, 236, 255)
local FOAM = Color3.fromRGB(240, 250, 255)

local P = 0.4 -- the plaza paving's top
-- (the jets and splashes at 60% of their design rate: the whole fountain stays near 130 live
-- particles at its biggest, within a phone's share of the scene budget)
local RATE = 0.6
local UP = CFrame.Angles(math.rad(90), 0, 0) -- (turns a frame's front, -Z, straight up)

function VillageFountain.build(m: Model, frame: CFrame, era: number, tier: number)
	if era < 2 then
		return
	end
	local t = TIERS[tier]
	-- the stone of the fountain: the tier's base stone, its walls for the tier's own colour, the
	-- trim for rims (a glowing slime-tech trim stays on rims only)
	local stone, stoneMat = t.base, t.baseMat
	local body, bodyMat = t.walls, t.wallMat
	local rim, rimMat = t.trim, t.trimMat
	if era == 2 then
		-- (the painted era's fountain is pale stone with blue rims, like its fence)
		body, bodyMat = Color3.fromRGB(226, 222, 212), Enum.Material.Slate
		stone, stoneMat = Color3.fromRGB(196, 192, 182), Enum.Material.Slate
		rim, rimMat = t.frame, Enum.Material.SmoothPlastic
	end
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, P + y, z)
	end
	local function disc(name: string, d: number, h: number, y: number, colour: Color3, material: Enum.Material?): Part
		-- a vertical cylinder `h` tall from y up, `d` across
		local p = part(
			m,
			name,
			Vector3.new(h, d, d),
			at(0, y + h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			colour,
			material
		) :: Part
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	local function bit(name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): Part
		local p = part(m, name, size, cf, colour, material or Enum.Material.SmoothPlastic) :: Part
		p.CanCollide = false
		p.CastShadow = false
		return p
	end
	-- an invisible holder for an emitter whose shape needs a part
	local function holder(name: string, size: Vector3, cf: CFrame): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Transparency = 1
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = m
		return p
	end

	-- ===== the water's moving parts =====
	-- a pool: still water and the shimmer film over it, ripples opening on it
	local function pool(d: number, y: number, ripples: number)
		local water = disc("Water", d, 0.2, y - 0.2, WATER, Enum.Material.SmoothPlastic)
		water.Transparency = 0.15
		water.CanCollide = false
		local film =
			disc("WaterShimmer", d - 0.05, 0.05, y + 0.01, Color3.fromRGB(70, 160, 230), Enum.Material.ForceField)
		film.CanCollide = false
		film.CastShadow = false
		if ripples > 0 then
			local h = holder(
				"RippleArea",
				Vector3.new(0.1, d * 0.8, d * 0.8),
				at(0, y + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
			)
			h.Shape = Enum.PartType.Cylinder
			local e = Instance.new("ParticleEmitter")
			e.Name = "Ripples"
			e.Texture = TEX.ripple
			e.Shape = Enum.ParticleEmitterShape.Disc
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.EmissionDirection = Enum.NormalId.Right -- (the disc's up)
			e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
			e.Speed = NumberRange.new(0.01)
			e.Lifetime = NumberRange.new(1.6, 2.2)
			e.Rate = ripples
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, d * 0.16) })
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.15, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.Color = ColorSequence.new(WATER_LIGHT)
			e.LightEmission = 0.3
			e.Rotation = NumberRange.new(0, 360)
			e.Parent = h
		end
	end
	-- a jet of drops from `cf` along its LookVector
	local function jet(cf: CFrame, speed: number, rate: number, size: number, spread: number?)
		local h = holder("Jet", Vector3.one * 0.15, cf)
		local e = Instance.new("ParticleEmitter")
		e.EmissionDirection = Enum.NormalId.Front
		e.Name = "WaterJet"
		e.Texture = TEX.drop
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Speed = NumberRange.new(speed * 0.92, speed)
		e.SpreadAngle = Vector2.new(spread or 3, spread or 3)
		e.Acceleration = Vector3.new(0, -32, 0)
		e.Lifetime = NumberRange.new(speed / 16 * 1.2, speed / 16 * 1.35)
		e.Rate = rate * RATE
		e.Size =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 1.8), NumberSequenceKeypoint.new(1, size * 1.4) })
		e.Squash = NumberSequence.new(0.6)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.85, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Color = ColorSequence.new(FOAM, WATER_LIGHT)
		e.LightEmission = 0.35
		e.ZOffset = 0.5
		e.Parent = h
		-- the stream's solid core near the nozzle: a narrow beam of streaks scrolling outward
		local a0 = Instance.new("Attachment")
		a0.Parent = h
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 0, -math.min(speed * 0.16, 2.2))
		a1.Parent = h
		local core = Instance.new("Beam")
		core.Name = "JetCore"
		core.Attachment0 = a0
		core.Attachment1 = a1
		core.Texture = TEX.curtain
		core.TextureMode = Enum.TextureMode.Wrap
		core.TextureLength = 1.2
		core.TextureSpeed = -2
		core.Width0 = size * 0.9
		core.Width1 = size * 0.6
		core.FaceCamera = true
		core.Color = ColorSequence.new(FOAM, WATER_LIGHT)
		core.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.9) })
		core.LightEmission = 0.3
		core.Parent = h
	end
	-- splashes on a ring of radius r at height y (r 0: a spot in the middle)
	local function splashes(r: number, y: number, rate: number)
		local h = holder(
			"SplashRing",
			Vector3.new(0.1, math.max(0.4, r * 2), math.max(0.4, r * 2)),
			at(0, y, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		h.Shape = Enum.PartType.Cylinder
		local e = Instance.new("ParticleEmitter")
		e.Name = "Splashes"
		e.Texture = TEX.splash
		e.Shape = Enum.ParticleEmitterShape.Disc
		e.ShapeStyle = if r > 0 then Enum.ParticleEmitterShapeStyle.Surface else Enum.ParticleEmitterShapeStyle.Volume
		e.EmissionDirection = Enum.NormalId.Right
		e.Speed = NumberRange.new(2, 4)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Acceleration = Vector3.new(0, -20, 0)
		e.Lifetime = NumberRange.new(0.35, 0.55)
		e.Rate = rate * RATE
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.1) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(FOAM)
		e.LightEmission = 0.2
		e.Rotation = NumberRange.new(0, 360)
		e.Parent = h
	end
	-- water falling from a bowl's rim (radius r0 at y0) to the pool below (radius r1 at y1): a ring of
	-- n curtains, each a Beam bowing outward, its streaks scrolling down
	local function curtains(r0: number, y0: number, r1: number, y1: number, n: number)
		local h = holder("Curtains", Vector3.one * 0.2, at(0, y0, 0))
		local width = 2 * math.pi * r0 / n * 1.08
		for k = 0, n - 1 do
			local ang = k * math.pi * 2 / n
			local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang))
			local a0 = Instance.new("Attachment")
			a0.Position = out * r0
			-- (Axis out from the rim: the curve bows outward; SecondaryAxis along the rim)
			a0.Axis = out
			a0.SecondaryAxis = tangent
			a0.Parent = h
			local a1 = Instance.new("Attachment")
			a1.Position = out * r1 + Vector3.new(0, y1 - y0, 0)
			a1.Axis = out
			a1.SecondaryAxis = tangent
			a1.Parent = h
			local b = Instance.new("Beam")
			b.Name = "WaterCurtain"
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Texture = TEX.curtain
			b.TextureMode = Enum.TextureMode.Wrap
			b.TextureLength = 2.5
			b.TextureSpeed = 1.2
			b.Width0 = width
			b.Width1 = width * (r1 / math.max(r0, 0.1))
			b.FaceCamera = false
			b.Segments = 10
			b.CurveSize0 = (r1 - r0) * 0.9
			b.CurveSize1 = 0
			b.Color = ColorSequence.new(WATER_LIGHT, FOAM)
			b.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(0.8, 0.45),
				NumberSequenceKeypoint.new(1, 0.85),
			})
			b.LightEmission = 0.25
			b.LightInfluence = 0.6
			b.Parent = h
		end
		splashes(r1 + 0.1, y1 + 0.05, n * 2)
	end

	-- ===== the stonework =====
	-- a flat ring from radius r0 to r1, `h` tall from y up, of short curved blocks
	local function ring(
		name: string,
		r0: number,
		r1: number,
		h: number,
		y: number,
		colour: Color3,
		material: Enum.Material
	)
		local n = math.clamp(math.floor(r1 * 5), 12, 40)
		local rm = (r0 + r1) / 2
		local len = 2 * math.pi * r1 / n + 0.08
		for k = 0, n - 1 do
			local a = (k + 0.5) * math.pi * 2 / n
			local cf = at(math.cos(a) * rm, y + h / 2, math.sin(a) * rm) * CFrame.Angles(0, -a, 0)
			local seg = part(m, name, Vector3.new(r1 - r0, h, len), cf, colour, material)
			seg.CastShadow = k % 2 == 0
		end
	end
	-- a round basin: a plinth, a wall with pilasters, a rim; its water `inset` below the rim's top
	local function basin(d: number, wallH: number, pilasters: number): number
		disc("BasinPlinth", d + 0.6, 0.35, 0, stone, stoneMat)
		disc("BasinWall", d, wallH, 0.35, body, bodyMat)
		local top = 0.35 + wallH
		-- (the rims are rings, so the water inside shows)
		ring("BasinRim", d / 2 - 0.45, d / 2 + 0.25, 0.3, top, rim, rimMat)
		ring("BasinRimTop", d / 2 - 0.4, d / 2 + 0.05, 0.15, top + 0.3, body, bodyMat)
		for k = 0, pilasters - 1 do
			local a = k * math.pi * 2 / pilasters
			local r = d / 2
			local cf = at(math.cos(a) * r, 0.35 + wallH / 2, math.sin(a) * r) * CFrame.Angles(0, -a, 0)
			bit("BasinPilaster", Vector3.new(0.4, wallH, 0.8), cf, stone, stoneMat)
			bit("PilasterCap", Vector3.new(0.5, 0.18, 0.95), cf * CFrame.new(0, wallH / 2 - 0.09, 0), rim, rimMat)
		end
		return top + 0.3 -- (the water's level, just under the rim's top)
	end
	-- a column from y0 to y1, with rings
	local function column(d: number, y0: number, y1: number, rings: { number })
		disc("Column", d, y1 - y0, y0, body, bodyMat)
		disc("ColumnFoot", d + 0.5, 0.3, y0, stone, stoneMat)
		for _, y in rings do
			disc("ColumnRing", d + 0.25, 0.18, y, rim, rimMat)
		end
	end
	-- a bowl whose rim's top is at y: a tapering underside of stacked rings, a lip, its water
	local function bowl(d: number, y: number, depth: number): number
		local steps = 3
		for j = 0, steps - 1 do
			local f = 1 - (j + 1) / (steps + 1)
			disc("BowlUnder", d * (0.4 + 0.6 * f), depth / steps, y - depth - (j + 1) * depth / steps, body, bodyMat)
		end
		disc("BowlBody", d, depth - 0.2, y - depth, body, bodyMat)
		ring("BowlLip", d / 2 - 0.2, d / 2 + 0.15, 0.25, y - 0.25, rim, rimMat)
		return y - 0.06
	end
	-- a small rosette or ornament on a basin wall, facing out
	local function ornament(r: number, y: number, a: number, colour: Color3, material: Enum.Material)
		local cf = at(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, -a + math.pi / 2, 0)
		local o = bit("Rosette", Vector3.new(0.12, 0.7, 0.7), cf * CFrame.Angles(0, math.rad(90), 0), colour, material)
		o.Shape = Enum.PartType.Cylinder
		local c = bit("RosetteHeart", Vector3.one * 0.32, cf * CFrame.new(0, 0, -0.08), colour, material)
		c.Shape = Enum.PartType.Ball
	end

	if era == 2 then
		local wl = basin(8.6, 1.4, 8)
		pool(7.8, wl, 3)
		column(1.2, wl - 0.2, 3.4, { 2.2, 3.2 })
		local bw = bowl(3.4, 4.1, 0.55)
		pool(3, bw, 0)
		disc("Finial", 0.5, 0.35, bw, rim, rimMat)
		jet(at(0, bw + 0.35, 0) * UP, 9, 45, 0.35)
		splashes(0.6, bw + 0.05, 10)
		curtains(1.75, bw, 2.6, wl, 10)
	elseif era == 3 then
		local wl = basin(10.6, 1.5, 12)
		pool(9.8, wl, 4)
		column(1.6, wl - 0.2, 3.2, { 2.2 })
		local mid = bowl(5.2, 3.9, 0.7)
		pool(4.8, mid, 2)
		column(0.9, mid - 0.1, 5.4, { 4.9 })
		local top = bowl(2.6, 5.9, 0.45)
		pool(2.2, top, 0)
		disc("Finial", 0.45, 0.35, top, rim, rimMat)
		jet(at(0, top + 0.35, 0) * UP, 10, 45, 0.33)
		splashes(0.5, top + 0.05, 10)
		curtains(1.35, top, 2.3, mid, 8)
		curtains(2.65, mid, 3.8, wl, 14)
		-- four fish spouts on the basin's rim, arcing water to the column's foot
		for k = 0, 3 do
			local a = k * math.pi / 2 + math.pi / 4
			local r = 10.6 / 2 - 0.1
			local base = at(math.cos(a) * r, wl + 0.45, math.sin(a) * r)
				* CFrame.lookAt(Vector3.zero, -Vector3.new(math.cos(a), 0, math.sin(a)))
			-- (a carved koi on the rim, its mouth to the middle; generated, in the kit)
			place(m, base * CFrame.new(0, -0.05 - P, 0.2), "KoiSpout", 0, 0, 1.7, 1.9)
			jet(base * CFrame.new(0, 0.55, -0.8) * CFrame.Angles(math.rad(32), 0, 0), 7.5, 30, 0.28)
		end
		splashes(2.2, wl + 0.05, 10)
	elseif era == 4 then
		local wl = basin(12.2, 1.2, 16)
		pool(11.4, wl, 5)
		-- lights under the water, round the sculpture
		for k = 0, 7 do
			local a = k * math.pi / 4
			local g = bit(
				"PoolLight",
				Vector3.new(0.1, 0.6, 0.6),
				at(math.cos(a) * 3.2, wl - 0.15, math.sin(a) * 3.2) * CFrame.Angles(0, 0, math.rad(90)),
				t.glass,
				Enum.Material.Neon
			)
			g.Shape = Enum.PartType.Cylinder
		end
		-- the sculpture: three glass discs on a steel spine, water falling from each
		column(0.7, wl - 0.2, 7.4, {})
		local discs = { { 4.2, 3.4 }, { 3, 5.2 }, { 1.8, 6.9 } }
		local last = wl
		for j = #discs, 1, -1 do
			local dd = discs[j]
			local g = disc("GlassDisc", dd[1], 0.3, dd[2] - 0.3, t.glass, Enum.Material.Glass)
			g.Transparency = 0.25
			disc("DiscEdge", dd[1] + 0.12, 0.08, dd[2] - 0.05, t.frame, t.frameMat)
			local glow = disc("DiscGlow", dd[1] * 0.5, 0.06, dd[2] - 0.34, t.trim, Enum.Material.Neon)
			glow.CastShadow = false
		end
		for j, dd in discs do
			local below = if j == 1 then wl else discs[j - 1][2]
			local belowR = if j == 1 then dd[1] / 2 + 1.2 else dd[1] / 2 + 0.7
			curtains(dd[1] / 2, dd[2], belowR, below, 8 + j * 2)
			last = dd[2]
		end
		jet(at(0, last + 0.2, 0) * UP, 12, 50, 0.32)
		-- eight jets arcing from the rim to the sculpture
		for k = 0, 7 do
			local a = k * math.pi / 4 + math.pi / 8
			local r = 12.2 / 2 - 0.2
			local base = at(math.cos(a) * r, wl + 0.4, math.sin(a) * r)
				* CFrame.lookAt(Vector3.zero, -Vector3.new(math.cos(a), 0, math.sin(a)))
			local n = bit("Nozzle", Vector3.new(0.3, 0.35, 0.3), base, t.frame, t.frameMat)
			n.Shape = Enum.PartType.Cylinder
			jet(base * CFrame.Angles(math.rad(48), 0, 0), 10, 28, 0.26)
		end
		splashes(3.1, wl + 0.05, 14)
	else
		-- the grand fountain on a stepped plinth
		disc("PlinthStep", 13.4, 0.25, 0, stone, stoneMat)
		local wl = basin(12.6, 1.5, 16)
		pool(11.8, wl, 5)
		for k = 0, 7 do
			ornament(12.6 / 2 + 0.05, 1.15, k * math.pi / 4, rim, rimMat)
		end
		column(2, wl - 0.2, 3.1, { 2.2 })
		local mid = bowl(6.2, 3.8, 0.75)
		pool(5.8, mid, 2)
		column(1.3, mid - 0.1, 5.6, { 5 })
		local up = bowl(3.8, 6.1, 0.55)
		pool(3.4, up, 1)
		column(0.9, up - 0.1, 7.3, { 6.9 })
		local top = bowl(2.2, 7.7, 0.4)
		pool(1.9, top, 0)
		curtains(1.15, top, 1.9, up, 8)
		curtains(1.95, up, 3.4, mid, 12)
		curtains(3.15, mid, 4.6, wl, 16)
		-- the golden slime statue on the top bowl
		local statue = Instance.new("Model")
		statue.Name = "FountainStatue"
		statue.Parent = m
		place(statue, at(0, 0, 0), "SlimeStatue", 0, 0, 2.2, 1.8, top + 0.05)
		-- jets arching out from the middle tier, and shell spouts on the basin rim
		for k = 0, 5 do
			local a = k * math.pi / 3
			local base = at(math.cos(a) * 3.05, mid + 0.15, math.sin(a) * 3.05)
				* CFrame.lookAt(Vector3.zero, Vector3.new(math.cos(a), 0, math.sin(a)))
			jet(base * CFrame.Angles(math.rad(55), 0, 0), 6.5, 22, 0.24)
		end
		for k = 0, 3 do
			local a = k * math.pi / 2 + math.pi / 4
			local r = 12.6 / 2 - 0.1
			local base = at(math.cos(a) * r, wl + 0.45, math.sin(a) * r)
				* CFrame.lookAt(Vector3.zero, -Vector3.new(math.cos(a), 0, math.sin(a)))
			local shell = bit("Shell", Vector3.new(1.1, 0.9, 0.3), base, rim, rimMat)
			shell.Shape = Enum.PartType.Ball
			local lip = bit(
				"ShellLip",
				Vector3.new(0.32, 0.5, 0.5),
				base * CFrame.new(0, -0.15, -0.3) * CFrame.Angles(0, math.rad(90), 0),
				body,
				bodyMat
			)
			lip.Shape = Enum.PartType.Cylinder
			jet(base * CFrame.new(0, -0.15, -0.5) * CFrame.Angles(math.rad(25), 0, 0), 7, 26, 0.26)
		end
		splashes(4.9, wl + 0.05, 12)
	end
end

return VillageFountain
