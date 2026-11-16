--!strict
-- Building blocks for the village's landmark buildings (village v2; the owner, 2026-11-16: taller, more detail,
-- better finished, built sensibly): walls, roofs, towers, silos, windows, clocks and banners made of plain parts
-- in the classic stud look. Everything is placed in a building's own frame (x across, y up from the ground, z
-- from the front, -z, to the back). A "face" is a frame standing on the outside of a wall: its -Z points out of
-- the wall, its X runs along it, its Y is up.
-- Solid pieces (walls, roofs, drums) collide; trim (beams, frames, cloth, ticks) does not and casts no shadow,
-- so a building costs a phone little more than its few big blocks.
-- Real surfaces (the owner, 2026-11-16: "paste textures so the building looks more real"): `skins` names the
-- material every colour of the building stands for (the wall colour is plaster, the beam colour is wood, the
-- roof colour is clay tiles), keyed by the colour's hex, so every helper below textures its parts without being
-- told. A colour with no skin keeps the stud look. `seeThrough` is how see-through every Glass part is.
local PondStages = require(script.Parent.PondStages)

local Architecture = {}

function Architecture.new(m: Instance, frame: CFrame, skins: { [string]: Enum.Material }?, seeThrough: number?)
	local b = {}

	local function make(
		class: string,
		name: string,
		size: Vector3,
		cf: CFrame,
		colour: Color3,
		material: Enum.Material?,
		solid: boolean
	): BasePart
		local p = (Instance.new :: any)(class) :: BasePart
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = colour
		p.Anchored = true
		local skin = material or (skins and skins[colour:ToHex()])
		if skin then
			p.Material = skin
			if skin == Enum.Material.Glass and seeThrough then
				p.Transparency = seeThrough
			end
		else
			PondStages.studLook(p, nil)
		end
		p.CastShadow = solid and size.Magnitude > 4
		if not solid then
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
		p.Parent = m
		return p
	end

	function b.at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end

	-- A face at (x, y, z) on a wall; `out` is the way out of the wall in the building's frame.
	function b.face(x: number, y: number, z: number, out: Vector3): CFrame
		local p = frame * CFrame.new(x, y, z)
		return CFrame.lookAt(p.Position, p.Position + frame:VectorToWorldSpace(out))
	end

	function b.box(
		name: string,
		sx: number,
		sy: number,
		sz: number,
		cf: CFrame,
		colour: Color3,
		material: Enum.Material?
	)
		return make("Part", name, Vector3.new(sx, sy, sz), cf, colour, material, true)
	end

	function b.trim(
		name: string,
		sx: number,
		sy: number,
		sz: number,
		cf: CFrame,
		colour: Color3,
		material: Enum.Material?
	)
		return make("Part", name, Vector3.new(sx, sy, sz), cf, colour, material, false)
	end

	-- A wedge: low at its -Z, high at its +Z.
	function b.wedge(
		name: string,
		sx: number,
		sy: number,
		sz: number,
		cf: CFrame,
		colour: Color3,
		material: Enum.Material?
	)
		return make("WedgePart", name, Vector3.new(sx, sy, sz), cf, colour, material, true)
	end

	-- An upright cylinder, its middle at `cf`.
	function b.cyl(
		name: string,
		radius: number,
		height: number,
		cf: CFrame,
		colour: Color3,
		material: Enum.Material?,
		solid: boolean?
	)
		local p = make(
			"Part",
			name,
			Vector3.new(height, radius * 2, radius * 2),
			cf * CFrame.Angles(0, 0, math.pi / 2),
			colour,
			material,
			solid ~= false
		) :: Part
		p.Shape = Enum.PartType.Cylinder
		return p
	end

	-- A round plate lying on a face (a clock's dial, the head of an arched window), `thick` deep.
	function b.disc(name: string, radius: number, thick: number, face: CFrame, colour: Color3, material: Enum.Material?)
		local p = make(
			"Part",
			name,
			Vector3.new(thick, radius * 2, radius * 2),
			face * CFrame.Angles(0, math.pi / 2, 0),
			colour,
			material,
			false
		) :: Part
		p.Shape = Enum.PartType.Cylinder
		return p
	end

	function b.ball(name: string, radius: number, cf: CFrame, colour: Color3, material: Enum.Material?)
		local p = make("Part", name, Vector3.one * radius * 2, cf, colour, material, false) :: Part
		p.Shape = Enum.PartType.Ball
		return p
	end

	-- A round bar from `p1` to `p2` (points in the building's frame): poles, pipes, crane arms.
	function b.rod(name: string, radius: number, p1: Vector3, p2: Vector3, colour: Color3, material: Enum.Material?)
		local a, c = frame:PointToWorldSpace(p1), frame:PointToWorldSpace(p2)
		local up = if math.abs((c - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
		local p = make(
			"Part",
			name,
			Vector3.new((c - a).Magnitude, radius * 2, radius * 2),
			CFrame.lookAt((a + c) / 2, c, up) * CFrame.Angles(0, math.pi / 2, 0),
			colour,
			material,
			false
		) :: Part
		p.Shape = Enum.PartType.Cylinder
		return p
	end

	-- A square bar `w` wide and `t` thick from `p1` to `p2`: braces, sloping boards.
	function b.beam(
		name: string,
		w: number,
		t: number,
		p1: Vector3,
		p2: Vector3,
		colour: Color3,
		material: Enum.Material?
	)
		local a, c = frame:PointToWorldSpace(p1), frame:PointToWorldSpace(p2)
		local up = if math.abs((c - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
		return make(
			"Part",
			name,
			Vector3.new(w, t, (c - a).Magnitude),
			CFrame.lookAt((a + c) / 2, c, up),
			colour,
			material,
			false
		)
	end

	-- A gable roof over a rectangle `len` long (the ridge, along `cf`'s X) and `span` across, `cf` at the middle
	-- of the walls' top. It rises `rise` over the walls and hangs `over` past them all round; the two gable ends
	-- are filled in `gableColour`. The roof is two slabs `thick` deep, their top on the roof's line, so the gable
	-- walls stand back under a real overhang (a solid roof hid them and everything on them). `only` (-1 or 1)
	-- fills and boards that end alone: the other runs into a wall. Returns the ridge's height over `cf`.
	function b.gable(
		cf: CFrame,
		len: number,
		span: number,
		rise: number,
		over: number,
		colour: Color3,
		gableColour: Color3,
		boardColour: Color3,
		material: Enum.Material?,
		thick: number?,
		only: number?
	): number
		local half = span / 2
		local pitch = rise / half
		local depth, height = half + over, pitch * (half + over)
		local base = -pitch * over -- the eave hangs below the walls' top
		local angle = math.atan2(height, depth)
		local slope = math.sqrt(depth ^ 2 + height ^ 2)
		local t = thick or math.clamp(span * 0.035, 0.25, 0.6)
		local drop = t / math.cos(angle) -- how far the slab's underside hangs below the roof's line
		local ends: { number } = if only then { only } else { -1, 1 }
		for _, s in { -1, 1 } do
			local turn = if s < 0 then CFrame.identity else CFrame.Angles(0, math.pi, 0)
			-- (the slab's own Y is the roof's outward normal)
			local lie = cf * CFrame.new(0, base + height / 2, s * depth / 2) * CFrame.Angles(s * angle, 0, 0)
			b.trim("Roof", len + over * 2, t, slope, lie * CFrame.new(0, -t / 2, 0), colour, material).CastShadow = true
			for _, e in ends do
				b.wedge(
					"Gable",
					0.5,
					rise - drop,
					half - drop / pitch,
					cf * CFrame.new(e * (len / 2 - 0.25), (rise - drop) / 2, s * (half - drop / pitch) / 2) * turn,
					gableColour
				)
				-- a barge board along the slope at each end
				b.trim(
					"BargeBoard",
					0.25,
					t + 0.3,
					slope,
					lie * CFrame.new(e * (len / 2 + over + 0.05), -t / 2, 0),
					boardColour
				)
			end
		end
		b.trim(
			"Ridge",
			len + over * 2 + 0.4,
			0.5,
			math.max(0.8, t * 2 * math.sin(angle) + 0.3),
			cf * CFrame.new(0, rise + 0.1, 0),
			boardColour
		)
		return rise
	end

	-- A pyramid roof over a rectangle `w` by `d`, `cf` at the middle of its foot (four corner wedges; a tall
	-- `rise` makes a spire).
	function b.pyramid(cf: CFrame, w: number, d: number, rise: number, colour: Color3, material: Enum.Material?)
		-- a corner wedge's top stands over its (+X, -Z) corner
		local quads = { { 0, -1, 1 }, { 1, 1, 1 }, { 2, 1, -1 }, { 3, -1, -1 } }
		for _, q in quads do
			local odd = q[1] % 2 == 1
			make(
				"CornerWedgePart",
				"Spire",
				Vector3.new(if odd then d / 2 else w / 2, rise, if odd then w / 2 else d / 2),
				cf * CFrame.new(q[2] * w / 4, rise / 2, q[3] * d / 4) * CFrame.Angles(0, q[1] * math.pi / 2, 0),
				colour,
				material,
				true
			)
		end
	end

	-- A cone roof of `steps` rings, each smaller, `cf` at the middle of its foot; a ball on its tip.
	function b.cone(cf: CFrame, radius: number, rise: number, steps: number, colour: Color3, tip: Color3?)
		local h = rise / steps
		for i = 1, steps do
			b.cyl("Cone", radius * (1 - (i - 1) / steps), h, cf * CFrame.new(0, (i - 0.5) * h, 0), colour, nil, i == 1)
		end
		if tip then
			b.ball("Finial", math.max(0.3, radius * 0.14), cf * CFrame.new(0, rise + radius * 0.08, 0), tip)
		end
	end

	-- Timber framing on a wall `len` long and `h` high, the face at its middle: rails at the foot and the top,
	-- posts about every 3 studs, a brace in each end bay.
	function b.timber(face: CFrame, len: number, h: number, colour: Color3)
		local T, OUT = 0.4, -0.1
		for _, y in { -h / 2 + T / 2, h / 2 - T / 2 } do
			b.trim("Rail", len, T, 0.3, face * CFrame.new(0, y, OUT), colour)
		end
		local bays = math.max(1, math.round(len / 3.2))
		local step = (len - T) / bays
		for i = 0, bays do
			b.trim("Post", T, h, 0.3, face * CFrame.new(-len / 2 + T / 2 + i * step, 0, OUT), colour)
		end
		if bays >= 2 and h >= 3 then
			local run = math.sqrt(step ^ 2 + h ^ 2)
			for _, s in { -1, 1 } do
				b.trim(
					"Brace",
					T * 0.8,
					run - 0.6,
					0.24,
					face
						* CFrame.new(s * (len / 2 - T / 2 - step / 2), 0, OUT)
						* CFrame.Angles(0, 0, s * math.atan2(step, h)),
					colour
				)
			end
		end
	end

	-- A window, the face at its middle: a frame with depth, glazing bars, a sill; shutters, a round head and a
	-- flower box when asked.
	function b.window(
		face: CFrame,
		w: number,
		h: number,
		frameColour: Color3,
		glass: Color3,
		opts: { shutters: Color3?, arch: boolean?, flowers: boolean?, glow: boolean?, through: number? }?
	)
		local o: { shutters: Color3?, arch: boolean?, flowers: boolean?, glow: boolean?, through: number? } = opts or {}
		local glassMat = if o.glow then Enum.Material.Neon else nil
		-- (on a hollow building the pane goes `through` the wall and shows inside too)
		local deep = if o.through then o.through + 0.1 else 0
		-- (proud of a wall's timber, which stands 0.25 out)
		b.trim("WindowFrame", w + 0.5, h + 0.5, 0.3, face * CFrame.new(0, 0, -0.2), frameColour)
		b.trim("WindowGlass", w, h, 0.36 + deep, face * CFrame.new(0, 0, -0.21 + deep / 2), glass, glassMat)
		b.trim("WindowBar", 0.14, h, 0.42, face * CFrame.new(0, 0, -0.21), frameColour)
		b.trim("WindowBar", w, 0.14, 0.42, face * CFrame.new(0, 0, -0.21), frameColour)
		b.trim("WindowSill", w + 0.9, 0.25, 0.6, face * CFrame.new(0, -h / 2 - 0.3, -0.3), frameColour)
		if o.arch then
			b.disc("WindowHead", w / 2 + 0.25, 0.3, face * CFrame.new(0, h / 2, -0.2), frameColour)
			b.disc("WindowHeadGlass", w / 2, 0.36, face * CFrame.new(0, h / 2, -0.21), glass, glassMat)
		end
		if o.shutters then
			for _, s in { -1, 1 } do
				b.trim(
					"Shutter",
					w * 0.42,
					h + 0.2,
					0.16,
					face * CFrame.new(s * (w / 2 + 0.3 + w * 0.21), 0, -0.22),
					o.shutters
				)
			end
		end
		if o.flowers then
			b.trim(
				"FlowerBox",
				w + 0.7,
				0.5,
				0.7,
				face * CFrame.new(0, -h / 2 - 0.65, -0.4),
				Color3.fromRGB(128, 84, 50)
			)
			b.trim(
				"FlowerLeaves",
				w + 0.5,
				0.3,
				0.55,
				face * CFrame.new(0, -h / 2 - 0.32, -0.4),
				Color3.fromRGB(86, 160, 70)
			)
			local blooms = { Color3.fromRGB(255, 120, 150), Color3.fromRGB(255, 214, 80), Color3.fromRGB(240, 90, 80) }
			for i, c in blooms do
				b.ball("Flower", 0.24, face * CFrame.new((i - 2) * (w / 3 + 0.1), -h / 2 - 0.12, -0.45), c)
			end
		end
	end

	-- A clock, the face at its middle: a rim, a dial, twelve ticks (no numerals: the owner's rule on text), two
	-- hands at ten past ten.
	function b.clock(face: CFrame, r: number, rim: Color3, dial: Color3, hands: Color3)
		b.disc("ClockRim", r * 1.18, 0.4, face * CFrame.new(0, 0, -0.1), rim)
		b.disc("ClockDial", r, 0.5, face * CFrame.new(0, 0, -0.12), dial)
		for k = 0, 11 do
			local big = k % 3 == 0
			b.trim(
				"ClockTick",
				r * (if big then 0.1 else 0.06),
				r * (if big then 0.22 else 0.13),
				0.1,
				face * CFrame.Angles(0, 0, k * math.pi / 6) * CFrame.new(0, r * 0.8, -0.38),
				hands
			)
		end
		b.trim(
			"ClockHand",
			r * 0.13,
			r * 0.5,
			0.08,
			face * CFrame.Angles(0, 0, math.rad(60)) * CFrame.new(0, r * 0.25, -0.43),
			hands
		)
		b.trim(
			"ClockHand",
			r * 0.09,
			r * 0.74,
			0.08,
			face * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.new(0, r * 0.37, -0.45),
			hands
		)
		b.ball("ClockHub", r * 0.1, face * CFrame.new(0, 0, -0.45), rim)
	end

	-- A hanging banner, the face at the middle of its rod: cloth with a pointed foot, a border and a round badge.
	function b.banner(face: CFrame, w: number, h: number, cloth: Color3, gold: Color3)
		b.trim("BannerRod", w + 0.5, 0.22, 0.22, face * CFrame.new(0, 0, -0.25), gold)
		b.trim("Banner", w, h, 0.1, face * CFrame.new(0, -h / 2, -0.35), cloth, Enum.Material.Fabric)
		local side = w / math.sqrt(2)
		b.trim(
			"BannerPoint",
			side,
			side,
			0.1,
			face * CFrame.new(0, -h, -0.35) * CFrame.Angles(0, 0, math.pi / 4),
			cloth,
			Enum.Material.Fabric
		)
		b.trim("BannerBand", w, 0.2, 0.12, face * CFrame.new(0, -0.35, -0.37), gold)
		b.disc("BannerBadge", w * 0.28, 0.1, face * CFrame.new(0, -h * 0.55, -0.39), gold)
	end

	-- A flag on a pole standing at `foot` (a point in the building's frame), flying toward +x.
	function b.flag(foot: Vector3, height: number, cloth: Color3, pole: Color3)
		b.rod("FlagPole", 0.12, foot, foot + Vector3.new(0, height, 0), pole)
		b.ball("FlagKnob", 0.22, b.at(foot.X, foot.Y + height + 0.15, foot.Z), pole)
		b.trim("Flag", 1.7, 1, 0.08, b.at(foot.X + 0.95, foot.Y + height - 0.6, foot.Z), cloth, Enum.Material.Fabric)
	end

	-- A wall lantern on a bracket, the face where the bracket meets the wall; `lit` gives it a real light (keep
	-- those few).
	function b.lantern(face: CFrame, glow: Color3, iron: Color3, lit: boolean?)
		b.trim("LampBracket", 0.15, 0.15, 0.8, face * CFrame.new(0, 0.6, -0.4), iron)
		b.trim("LampCap", 0.85, 0.2, 0.85, face * CFrame.new(0, 0.55, -0.8), iron)
		local lamp = b.trim("Lantern", 0.6, 0.8, 0.6, face * CFrame.new(0, 0.05, -0.8), glow, Enum.Material.Neon)
		if lit then
			local light = Instance.new("PointLight")
			light.Color = glow
			light.Range = 14
			light.Brightness = 0.45
			light.Parent = lamp
		end
	end

	-- A striped awning sloping out from a wall, the face at the middle of its top edge.
	function b.awning(face: CFrame, w: number, depth: number, c1: Color3, c2: Color3)
		local stripes = math.max(3, math.round(w / 1.2))
		local sw = w / stripes
		local tilt = CFrame.Angles(math.rad(-22), 0, 0)
		for i = 1, stripes do
			local c = if i % 2 == 1 then c1 else c2
			local x = -w / 2 + (i - 0.5) * sw
			b.trim(
				"Awning",
				sw,
				0.16,
				depth,
				face * CFrame.new(x, 0, 0) * tilt * CFrame.new(0, 0, -depth / 2),
				c,
				Enum.Material.Fabric
			)
			b.trim(
				"AwningEdge",
				sw,
				0.5,
				0.1,
				face * CFrame.new(x, 0, 0) * tilt * CFrame.new(0, -0.3, -depth),
				c,
				Enum.Material.Fabric
			)
		end
	end

	-- A round store silo standing at (x, z) from `y0`: a foot, a drum with hoops, and a cap ("cone", "dome" or
	-- "flat"). With `goo` the drum is glass with glowing goo inside (slime tech).
	function b.silo(
		x: number,
		y0: number,
		z: number,
		r: number,
		h: number,
		drum: Color3,
		hoop: Color3,
		cap: string,
		capColour: Color3,
		goo: Color3?
	)
		b.cyl("SiloFoot", r + 0.4, 0.8, b.at(x, y0 + 0.4, z), hoop)
		if goo then
			local glass = b.cyl("SiloGlass", r, h, b.at(x, y0 + 0.8 + h / 2, z), drum, Enum.Material.Glass)
			glass.Transparency = 0.65
			b.cyl("SiloGoo", r - 0.35, h * 0.72, b.at(x, y0 + 0.8 + h * 0.36, z), goo, Enum.Material.Neon, false)
		else
			b.cyl("SiloDrum", r, h, b.at(x, y0 + 0.8 + h / 2, z), drum)
		end
		for _, t in { 0.04, 0.5, 0.96 } do
			b.cyl("SiloHoop", r + 0.14, 0.4, b.at(x, y0 + 0.8 + h * t, z), hoop, nil, false)
		end
		local top = b.at(x, y0 + 0.8 + h, z)
		if cap == "cone" then
			b.cyl("SiloEave", r + 0.6, 0.3, top * CFrame.new(0, 0.15, 0), capColour, nil, false)
			b.cone(top * CFrame.new(0, 0.3, 0), r + 0.5, r * 1.3, 5, capColour, hoop)
		elseif cap == "dome" then
			b.cyl("SiloEave", r + 0.3, 0.4, top * CFrame.new(0, 0.2, 0), hoop, nil, false)
			b.ball("SiloDome", r, top * CFrame.new(0, 0.3, 0), capColour)
			b.ball("Finial", r * 0.16, top * CFrame.new(0, r + 0.4, 0), hoop)
		else
			b.cyl("SiloLid", r + 0.3, 0.5, top * CFrame.new(0, 0.25, 0), capColour, nil, false)
		end
	end

	return b
end

return Architecture
