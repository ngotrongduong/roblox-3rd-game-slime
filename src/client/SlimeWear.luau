--!strict
-- A Secret slime's own worn pieces (Config.Wear; the first: Tempest Dragon's horns, wings and tail). SlimeLook puts them on
-- the model it builds, where they rest on the body; SlimeActor's loop then makes them ride the skin (SlimeWear.pose) as the
-- jelly squashes, hops and leans, and swings what flaps. The meshes load from Roblox once per kit
-- (AssetService:CreateMeshPartAsync, as the flag's); a slime built before they arrive is dressed when they do.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)

local W = Config.Wear
local S = Config.Slime

type FlapSpec = { axis: { number }, degrees: number, hz: number, bias: number? }
type TwitchSpec = { axis: { number }, degrees: number, every: number }
type LagSpec = { axis: { number }, degrees: number }
type WriggleSpec = { axis: { number }, degrees: number, hz: number, lag: number, curl: number, curlHz: number }
type PieceSpec = {
	name: string,
	mesh: number,
	size: { number },
	at: { number },
	anchor: { number },
	flap: FlapSpec?,
	twitch: TwitchSpec?,
	lag: LagSpec?,
	bones: { { number } }?,
	wriggle: WriggleSpec?,
	clear: number?,
	turn: { number }?,
	texture: string?,
}
type KitSpec = { texture: string, pieces: { PieceSpec } }

-- `anchor` and `offset` (from the anchor to the piece's middle) are in mesh units, times the slime's scale in studs.
-- `bend`/`bendSpeed`: the lag spring's angle (radians) and its speed. `bones`: a tentacle's, root to tip, built on its
-- part; `boneAxes` the wriggle's axis in each bone's own frame; `wave`/`curl` radians, their speeds radians a second.
-- `turn`: the piece turned about its own middle (the owner's hand in the ear editor).
type Piece = {
	part: BasePart,
	anchor: Vector3,
	offset: Vector3,
	turn: CFrame,
	axis: Vector3?,
	swing: number,
	swingMid: number,
	speed: number,
	twitchAxis: Vector3?,
	twitchAngle: number,
	twitchEvery: number,
	lagAxis: Vector3?,
	lagAngle: number,
	phase: number,
	bend: number,
	bendSpeed: number,
	bones: { Bone },
	boneAxes: { Vector3 },
	wave: number,
	waveSpeed: number,
	waveLag: number,
	curl: number,
	curlSpeed: number,
}
-- `lastY`/`lastAt`: the feet's height (in bodies) and the clock at the last pose
type Worn = { pieces: { Piece }, phase: number, lastY: number?, lastAt: number }

local KITS: { [string]: KitSpec } = W.Kits :: any
local SECRETS: { [string]: string } = W.Secrets :: any

local SlimeWear = {}

-- kit -> its loaded pieces in Config order (a Studio check may fill a kit by hand before its meshes are uploaded)
local templates: { [string]: { BasePart } } = {}
SlimeWear.templates = templates
local waiting: { [string]: { Model } } = {}
local failed: { [string]: boolean } = {}
local worn: { [Model]: Worn } = setmetatable({} :: any, { __mode = "k" })
local random = Random.new()

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

-- Every mesh of a kit at once; nil if one did not load (the slime is then shown without its pieces).
local function load(name: string): { BasePart }?
	local kit = KITS[name]
	local parts: { BasePart } = {}
	local pending = #kit.pieces
	local ok = true
	for i, spec in kit.pieces do
		task.spawn(function()
			local loaded, part = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromAssetId(spec.mesh))
			end)
			if loaded then
				part.Name = spec.name
				part.Size = v3(spec.size)
				part.TextureID = spec.texture or kit.texture
				part.Color = Color3.new(1, 1, 1)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				parts[i] = part
			else
				ok = false
				warn(Config.LogPrefix, "wear", name, spec.name, "mesh did not load:", part)
			end
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
	return if ok then parts else nil
end

-- Clones the kit's pieces into the model where they rest on its body (a still model keeps them there).
local function dress(model: Model, name: string)
	local body = model:FindFirstChild("SlimeBody")
	if worn[model] or not (body and body:IsA("BasePart")) then
		return
	end
	local s = body.Size.Y / S.MeshHeight
	local feet = body.CFrame * CFrame.new(0, -S.MeshCentre * s, 0)
	local pieces: { Piece } = {}
	for i, spec in KITS[name].pieces do
		local part = templates[name][i]:Clone()
		part.Size = v3(spec.size) * s
		local t = spec.turn
		local turn = if t
			then CFrame.fromEulerAnglesXYZ(math.rad(t[1]), math.rad(t[2]), math.rad(t[3]))
			else CFrame.identity
		part.CFrame = feet * CFrame.new(v3(spec.at) * s) * turn
		-- (a ghost's pieces fade as its body does; a `clear` piece, an insect's wing, lets that share of the light through)
		part.Transparency = 1 - (1 - body.Transparency) * (1 - (spec.clear or 0))
		local flap = spec.flap
		local twitch = spec.twitch
		local lag = spec.lag
		local wriggle = spec.wriggle
		-- a tentacle's bones, by the names its skin was made with, at their rest frames (the part's own frame is its
		-- middle, unturned), scaled with it
		local bones: { Bone } = {}
		local boneAxes: { Vector3 } = {}
		if spec.bones then
			local axis = if wriggle then v3(wriggle.axis).Unit else Vector3.xAxis
			local parent: Instance = part
			local rest = CFrame.new(v3(spec.at))
			for k, b in spec.bones do
				local frame = CFrame.fromMatrix(
					Vector3.new(b[1], b[2], b[3]),
					Vector3.new(b[4], b[5], b[6]),
					Vector3.new(b[7], b[8], b[9])
				)
				local rel = rest:Inverse() * frame
				local bone = Instance.new("Bone")
				bone.Name = spec.name .. "_" .. (k - 1)
				bone.CFrame = rel.Rotation + rel.Position * s
				bone.Parent = parent
				table.insert(bones, bone)
				table.insert(boneAxes, frame:VectorToObjectSpace(axis))
				parent, rest = bone, frame
			end
		end
		table.insert(pieces, {
			part = part,
			anchor = v3(spec.anchor),
			offset = v3(spec.at) - v3(spec.anchor),
			turn = turn,
			axis = if flap then v3(flap.axis).Unit else nil,
			swing = if flap then math.rad(flap.degrees) else 0,
			swingMid = if flap then math.rad(flap.bias or 0) else 0,
			speed = if flap then flap.hz * 2 * math.pi else 0,
			twitchAxis = if twitch then v3(twitch.axis).Unit else nil,
			twitchAngle = if twitch then math.rad(twitch.degrees) else 0,
			twitchEvery = if twitch then twitch.every else 1,
			lagAxis = if lag then v3(lag.axis).Unit else nil,
			lagAngle = if lag then math.rad(lag.degrees) else 0,
			-- (each ear twitches on its own clock)
			phase = random:NextNumber(0, 100),
			bend = 0,
			bendSpeed = 0,
			bones = bones,
			boneAxes = boneAxes,
			wave = if wriggle then math.rad(wriggle.degrees) else 0,
			waveSpeed = if wriggle then wriggle.hz * 2 * math.pi else 0,
			waveLag = if wriggle then wriggle.lag else 0,
			curl = if wriggle then math.rad(wriggle.curl) else 0,
			curlSpeed = if wriggle then wriggle.curlHz * 2 * math.pi else 0,
		})
		-- (a model taken away while the meshes loaded cannot be dressed)
		if not pcall(function()
			part.Parent = model
		end) then
			return
		end
	end
	worn[model] = { pieces = pieces, phase = random:NextNumber(0, 10), lastAt = 0 }
end

-- Moves a piece's lag bend toward `goal` by a critically damped spring (D. Holden, "Spring-Roll-Call"): the same at any
-- frame rate, no overshoot.
local function settle(p: Piece, goal: number, dt: number)
	local y = 2 * math.log(2) / W.Lag.HalfLife
	local j0 = p.bend - goal
	local j1 = p.bendSpeed + j0 * y
	local e = math.exp(-y * dt)
	p.bend = e * (j0 + j1 * dt) + goal
	p.bendSpeed = e * (p.bendSpeed - j1 * y * dt)
end

-- An ear's flick now and then: back fast, home slower (0 to 1 over T.Length seconds), at a moment in each `every`
-- seconds that its own clock picks.
local function twitchAt(now: number, every: number, phase: number): number
	local T = W.Twitch
	local clock = now + phase
	local round = math.floor(clock / every)
	-- (a fixed moment in each round, different every round)
	local at = (math.sin(round * 12.9898 + phase) * 43758.5453) % 1 * math.max(every - T.Length, 0)
	local t = clock - round * every - at
	if t < 0 or t >= T.Length then
		return 0
	elseif t < T.Out then
		return math.sin(t / T.Out * math.pi / 2)
	end
	local back = (t - T.Out) / (T.Length - T.Out)
	return 1 - back * back * (3 - 2 * back)
end

-- Puts a Secret slime's pieces on its freshly built model (nothing for a slime without any).
function SlimeWear.put(model: Model, secretId: string?)
	local name = if secretId then SECRETS[secretId] else nil
	if not name or not KITS[name] or failed[name] then
		return
	end
	if templates[name] then
		dress(model, name)
		return
	end
	if KITS[name].pieces[1].mesh == 0 then
		return
	end
	local list = waiting[name]
	if list then
		table.insert(list, model)
		return
	end
	waiting[name] = { model }
	task.spawn(function()
		local parts = load(name)
		local models = waiting[name]
		waiting[name] = nil
		if not parts then
			failed[name] = true
			return
		end
		templates[name] = parts
		for _, m in models do
			if m.Parent then
				dress(m, name)
			end
		end
	end)
end

-- Adds the model's pieces to SlimeActor's move list for this frame: each rides the skin at its anchor (the body's bones
-- `b`, mesh units; `feet` the slime's feet with its hop and turn), leans as the skin there does, swings what flaps or
-- wags, flicks what twitches and trails the hop with what lags. Returns the new count.
function SlimeWear.pose(
	model: Model,
	feet: CFrame,
	b: SlimeShape.Bones,
	s: number,
	now: number,
	parts: { BasePart },
	cfs: { CFrame },
	n: number
): number
	local w = worn[model]
	if not w then
		return n
	end
	-- the skin's upright line under the jelly's lean and squash (SlimeShape.deform's slope up the body)
	local up = Vector3.new(b.top.x / S.BoneK, 1 + b.top.y / S.BoneK, b.top.z / S.BoneK).Unit
	local tilt = CFrame.fromMatrix(Vector3.zero, (Vector3.xAxis - up * up.X).Unit, up)
	-- the feet's climb in bodies a second (after a long pause, a far or sleeping slime, it starts over)
	local L = W.Lag
	local height = feet.Position.Y / s
	local elapsed = now - w.lastAt
	local lastY = w.lastY
	local rise = if lastY and elapsed > 0 and elapsed < L.Gap then (height - lastY) / elapsed else 0
	local climb = math.clamp(rise / L.Rise, -1, 1)
	local dt = math.clamp(elapsed, 0, L.Gap)
	w.lastY, w.lastAt = height, now
	for _, p in w.pieces do
		local x, y, z = SlimeShape.deform(p.anchor.X, p.anchor.Y, p.anchor.Z, b)
		local cf = feet * CFrame.new(x * s, y * s, z * s) * tilt
		local axis = p.axis
		if axis then
			cf *= CFrame.fromAxisAngle(axis, p.swingMid + p.swing * math.sin((now + w.phase) * p.speed))
		end
		local twitchAxis = p.twitchAxis
		if twitchAxis then
			cf *= CFrame.fromAxisAngle(twitchAxis, p.twitchAngle * twitchAt(now, p.twitchEvery, p.phase))
		end
		local lagAxis = p.lagAxis
		if lagAxis then
			settle(p, climb * p.lagAngle, dt)
			cf *= CFrame.fromAxisAngle(lagAxis, p.bend)
		end
		-- a tentacle wriggles: a wave runs out to its tip while it slowly curls and uncurls, more toward the tip
		local bones = p.bones
		local count = #bones
		if count > 0 then
			local clock = now + p.phase
			local curl = p.curl * (0.5 - 0.5 * math.cos(clock * p.curlSpeed))
			for k, bone in bones do
				local wave = p.wave * math.sin(clock * p.waveSpeed - (k - 1) * p.waveLag)
				bone.Transform = CFrame.fromAxisAngle(p.boneAxes[k], k / count * (wave + curl))
			end
		end
		n += 1
		parts[n] = p.part
		cfs[n] = cf * CFrame.new(p.offset * s) * p.turn
	end
	return n
end

return SlimeWear
