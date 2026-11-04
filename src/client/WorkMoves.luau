--!strict
-- What a cook and a trainee visibly do at their work places (the owner, 2026-11-04: cooks work a pan at the stove,
-- trainees hit the dummy). Client only, drawn from what the server publishes (the slime's Working and ClockKind, the
-- village's Work slots); nothing here changes the game.
--   cook     a frying pan held in front, steaming; every Cook.TossSeconds the pan flicks and one of the dish's
--            ingredients flies up, turns over and lands back in it
--   trainee  every Train.BeatSeconds a windup, a lunge to the skin of the nearest dummy or punching bag and back, a
--            mark in the style of the stat it trains (FightFx, the owner's battle art); the target rocks from its
--            foot. A target out of reach (the archery target) is spat at with goo instead.
-- The pan is built from parts like the rod and the hoe (src/server/WorkProps.luau); the steam is Roblox's own smoke
-- picture. Each slime's beat is offset by its name so a row of workers does not move in step.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local FightFx = require(script.Parent.FightFx)
local SlimeActor = require(script.Parent.SlimeActor)

local VC = Config.VillageClient
local K = VC.Cook
local T = VC.Train

local WorkMoves = {}

type Target = {
	parts: { BasePart },
	homes: { CFrame },
	pivot: CFrame, -- the foot it rocks from
	centre: Vector3, -- where blows land
	radius: number, -- flat, from the centre to its skin
	hitAt: number,
	power: number,
	axis: Vector3,
	moved: boolean,
}

export type State = {
	seed: number,
	food: Model?,
	foodId: string,
	toss: number,
	beat: number,
	hopBeat: number,
	hitBeat: number,
	target: Target?,
	targetKey: string,
}

local rocking: { Target } = {}
local rockLoop: RBXScriptConnection? = nil

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function WorkMoves.new(name: string): State
	local seed = 0
	for i = 1, #name do
		seed = (seed * 31 + string.byte(name, i)) % 997
	end
	return {
		seed = seed / 997,
		food = nil,
		foodId = "",
		toss = -1,
		beat = -1,
		hopBeat = -1,
		hitBeat = -1,
		target = nil,
		targetKey = "",
	}
end

-- ===== The cook =====

local IRON = Color3.fromRGB(62, 64, 72)
local DARK = Color3.fromRGB(38, 38, 44)
local HONEY = Color3.fromRGB(214, 150, 70)
local WOOD = Color3.fromRGB(150, 98, 52)

local function piece(m: Model, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = m
	return p
end

-- A frying pan: a honey wooden handle from the pivot (its end) toward -Z, an iron neck, a round iron pan with a
-- raised rim and a dark cooking face, steam rising off it. About 2.4 studs long.
function WorkMoves.pan(): Model
	local m = Instance.new("Model")
	m.Name = "FryingPan"
	piece(m, "Handle", Vector3.new(0.22, 0.2, 0.8), CFrame.new(0, 0, -0.4), HONEY, Enum.Material.Wood)
	piece(m, "HandleEnd", Vector3.new(0.26, 0.24, 0.12), CFrame.new(0, 0, -0.02), WOOD, Enum.Material.Wood)
	piece(m, "Neck", Vector3.new(0.16, 0.14, 0.3), CFrame.new(0, 0.04, -0.92), IRON, Enum.Material.Metal)
	local up = CFrame.Angles(0, 0, math.rad(90))
	local bowl = piece(m, "Bowl", Vector3.new(0.3, 1.5, 1.5), CFrame.new(0, 0.05, -1.8) * up, IRON, Enum.Material.Metal)
	bowl.Shape = Enum.PartType.Cylinder
	local face =
		piece(m, "Surface", Vector3.new(0.03, 1.25, 1.25), CFrame.new(0, 0.215, -1.8) * up, DARK, Enum.Material.Metal)
	face.Shape = Enum.PartType.Cylinder
	local steam = Instance.new("Attachment")
	steam.Name = "Steam"
	steam.Position = Vector3.new(0.3, 0, 0) -- (the face's +X is up)
	steam.Parent = face
	local puff = Instance.new("ParticleEmitter")
	puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
	puff.Rate = K.SteamRate
	puff.Lifetime = NumberRange.new(1, 1.6)
	puff.Speed = NumberRange.new(1.2, 2)
	puff.SpreadAngle = Vector2.new(15, 15)
	puff.EmissionDirection = Enum.NormalId.Right
	puff.Acceleration = Vector3.new(0, 0.6, 0)
	puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1.2) })
	puff.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	puff.Rotation = NumberRange.new(0, 359)
	puff.RotSpeed = NumberRange.new(-30, 30)
	puff.LightInfluence = 0.5
	puff.Parent = steam
	m.WorldPivot = CFrame.new()
	return m
end

local function tossClock(state: State, now: number): (number, number)
	local x = now / K.TossSeconds + state.seed
	return math.floor(x), x - math.floor(x)
end

-- Where the pan's handle end sits in the feet frame (front = -Z): it flicks up at the start of each toss and jiggles
-- over the heat in between.
function WorkMoves.panPose(state: State, now: number): CFrame
	local _, u = tossClock(state, now)
	local tilt = K.JiggleDegrees * math.sin(now * K.JiggleHz * math.pi * 2)
	if u < K.FlickShare then
		tilt += K.FlickDegrees * math.sin(math.pi * u / K.FlickShare)
	end
	return CFrame.new(0, K.PanUp, -K.PanForward) * CFrame.Angles(math.rad(tilt), 0, 0)
end

-- A work place's slot as the village publishes it (its Work attribute: worker, stat, recipe, ...).
local parsed: { [Instance]: { text: string, work: any } } = setmetatable({}, { __mode = "k" }) :: any
local function slotOf(root: Instance, area: string, slot: number): { [string]: any }?
	local text = root:GetAttribute("Work")
	if type(text) ~= "string" then
		return nil
	end
	local cache = parsed[root]
	if not cache or cache.text ~= text then
		local ok, work = pcall(HttpService.JSONDecode, HttpService, text)
		local fresh = { text = text :: string, work = (if ok and type(work) == "table" then work else {}) :: any }
		parsed[root] = fresh
		cache = fresh
	end
	local slots = (cache :: any).work[area]
	local saved = if type(slots) == "table" then slots[slot] else nil
	return if type(saved) == "table" then saved else nil
end

-- The stat a training place trains ("" while none is set).
function WorkMoves.trainStat(root: Instance, slot: number): string
	local saved = slotOf(root, "training", slot)
	return if saved and type(saved.stat) == "string" then saved.stat else ""
end

-- The dish's ingredients, one after another.
local function ingredients(root: Instance, slot: number): { string }
	local saved = slotOf(root, "kitchen", slot)
	local recipe = if saved
			and type(saved.recipe) == "string"
			and saved.recipe ~= ""
		then saved.recipe
		else Config.Food.DefaultRecipe
	local dish = (Config.Food.Dishes :: any)[recipe]
	local list: { string } = {}
	if dish then
		for item in dish.ingredients do
			table.insert(list, item)
		end
		table.sort(list)
	end
	return list
end

local function dropFood(state: State)
	if state.food then
		state.food:Destroy()
		state.food = nil
	end
	state.foodId = ""
end

-- One frame of the cook: at each toss the next ingredient and a kick of the jelly; the ingredient flies over the pan.
function WorkMoves.cook(
	state: State,
	actor: SlimeActor.Slime,
	pan: Model,
	root: Instance,
	slot: number,
	now: number,
	make: (string) -> Model,
	parent: Instance
)
	local index, u = tossClock(state, now)
	if index ~= state.toss then
		state.toss = index
		SlimeActor.kick(actor, "lean", K.TossLeanKick)
		SlimeActor.kick(actor, "squash", K.TossSquashKick)
		local list = ingredients(root, slot)
		local id = if #list > 0 then list[index % #list + 1] else ""
		if id ~= state.foodId then
			dropFood(state)
			if id ~= "" then
				local food = make(id)
				local extents = food:GetExtentsSize()
				local size = K.FoodStuds * actor.scale / VC.BodyHeight
				food:ScaleTo(food:GetScale() * size / math.max(extents.X, extents.Y, extents.Z, 1e-3))
				food.Parent = parent
				state.food, state.foodId = food, id
			end
		end
	end
	local food = state.food
	local face = pan:FindFirstChild("Surface")
	if not food or not face or not face:IsA("BasePart") then
		return
	end
	local rest = face.Position + Vector3.new(0, food:GetExtentsSize().Y / 2, 0)
	local s = (u - K.FlickShare * 0.6) / K.TossAirShare
	local height, flip = 0, 0
	if s > 0 and s < 1 then
		height = K.TossStuds * actor.scale / VC.BodyHeight * 4 * s * (1 - s)
		flip = math.pi * 2 * smooth(s)
	end
	food:PivotTo(CFrame.new(rest + Vector3.new(0, height, 0)) * actor.root.Rotation * CFrame.Angles(flip, 0, 0))
end

function WorkMoves.stopCook(state: State)
	dropFood(state)
	state.toss = -1
end

-- ===== The trainee =====

local FOOT_NAMES = { DummyFoot = true, DummyPlinth = true, PlinthCap = true, DummyBase = true, BaseGlow = true }

local function stepRock()
	local now = os.clock()
	local moves: { BasePart } = {}
	local cfs: { CFrame } = {}
	for index = #rocking, 1, -1 do
		local target = rocking[index]
		local age = now - target.hitAt
		local done = age >= T.RockSeconds
		local angle = if done
			then 0
			else math.rad(T.RockDegrees * target.power) * math.exp(-age * T.RockDamp) * math.sin(
				age * T.RockHz * math.pi * 2
			)
		local turn = target.pivot * CFrame.fromAxisAngle(target.axis, angle) * target.pivot:Inverse()
		for i, part in target.parts do
			if part.Parent then
				table.insert(moves, part)
				table.insert(cfs, turn * target.homes[i])
			end
		end
		if done then
			target.moved = false
			table.remove(rocking, index)
		end
	end
	if #moves > 0 then
		workspace:BulkMoveTo(moves, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
	if #rocking == 0 and rockLoop then
		rockLoop:Disconnect()
		rockLoop = nil
	end
end

local function rock(target: Target, from: Vector3, heavy: boolean)
	local dir = flat(target.centre - from)
	if dir.Magnitude < 1e-3 then
		return
	end
	-- (a target hit while it still rocks keeps its first resting pose)
	if not target.moved then
		for i, part in target.parts do
			target.homes[i] = part.CFrame
		end
		target.moved = true
		table.insert(rocking, target)
	end
	-- (up x the blow's direction: the top tips away from the one who struck)
	local unit = dir.Unit
	target.axis = Vector3.new(unit.Z, 0, -unit.X)
	target.hitAt = os.clock()
	target.power = if heavy then T.HeavyRock else 1
	if not rockLoop then
		rockLoop = RunService.RenderStepped:Connect(stepRock)
	end
end

-- The dummy's rocking pieces (the post and what it holds; never the foot or the floor round it), or a kit model's.
local function dummyTarget(body: BasePart): Target?
	local stage = body.Parent
	local post = if stage then stage:FindFirstChild("DummyPost") else nil
	if not stage or not post or not post:IsA("BasePart") then
		return nil
	end
	local foot = post.Position - Vector3.new(0, post.Size.Y / 2, 0)
	local parts: { BasePart } = {}
	for _, child in stage:GetChildren() do
		if
			child:IsA("BasePart")
			and not FOOT_NAMES[child.Name]
			and flat(child.Position - foot).Magnitude <= T.DummyRadius
			and child.Position.Y - foot.Y > T.DummyFootClear
		then
			table.insert(parts, child)
		end
	end
	return {
		parts = parts,
		homes = {},
		pivot = CFrame.new(foot),
		centre = body.Position,
		radius = math.max(body.Size.X, body.Size.Z) / 2,
		hitAt = 0,
		power = 1,
		axis = Vector3.zAxis,
		moved = false,
	}
end

local function modelTarget(model: Model): Target
	local box, size = model:GetBoundingBox()
	local parts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	return {
		parts = parts,
		homes = {},
		pivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0)),
		centre = box.Position,
		radius = math.min(size.X, size.Z) / 2,
		hitAt = 0,
		power = 1,
		axis = Vector3.zAxis,
		moved = false,
	}
end

-- The nearest of the training ground's dummy, punching bag and archery target to `home` (kept while its pieces stand).
local function findTarget(state: State, area: Instance, home: Vector3): Target?
	local key = string.format("%s|%d|%d", area:GetFullName(), math.floor(home.X), math.floor(home.Z))
	local kept = state.target
	if kept and state.targetKey == key and kept.parts[1] and kept.parts[1].Parent then
		return kept
	end
	local best: Instance? = nil
	local bestDistance = math.huge
	for _, d in area:GetDescendants() do
		local candidate = (d.Name == "DummyBody" and d:IsA("BasePart"))
			or ((d.Name == "PunchingBag" or d.Name == "ArcheryTarget") and d:IsA("Model"))
		if candidate then
			local at = if d:IsA("Model") then d:GetBoundingBox().Position else (d :: BasePart).Position
			local distance = flat(at - home).Magnitude
			if distance < bestDistance then
				best, bestDistance = d, distance
			end
		end
	end
	local target = if best and best:IsA("BasePart")
		then dummyTarget(best)
		elseif best and best:IsA("Model") then modelTarget(best)
		else nil
	state.target, state.targetKey = target, key
	return target
end

-- One frame of the trainee standing at `home`: returns how far to draw it from there (the lunge) and the point it
-- faces. `stat` is the stat its place trains (its style of blow).
function WorkMoves.train(
	state: State,
	actor: SlimeActor.Slime,
	area: Instance?,
	home: Vector3,
	stat: string,
	now: number
): (Vector3, Vector3?)
	local target = if area then findTarget(state, area, home) else nil
	if not target then
		return Vector3.zero, nil
	end
	local line = flat(target.centre - home)
	if line.Magnitude < 1e-3 then
		return Vector3.zero, target.centre
	end
	local dir = line.Unit
	local s = actor.scale / VC.BodyHeight
	local reach = line.Magnitude - target.radius - T.SlimeRadius * s
	local x = now / T.BeatSeconds + state.seed
	local index, u = math.floor(x), x - math.floor(x)
	local style = FightFx.style(if stat ~= "" then stat else "attack")
	local heavy = index % T.HeavyEvery == 0
	if index ~= state.beat then
		state.beat = index
		SlimeActor.kick(actor, "squash", T.WindupSquash * (if heavy then 1.5 else 1))
	end
	local function land(from: Vector3)
		local skin = target.centre - dir * target.radius
		FightFx.mark(style, skin, skin - dir * 3, heavy)
		rock(target, from, heavy)
	end
	if reach > T.MaxLungeStuds then
		-- out of reach: spit goo at it
		if u >= T.WindupShare and state.hitBeat ~= index then
			state.hitBeat = index
			SlimeActor.kick(actor, "lean", 1.5)
			local mouth = home + dir * T.SlimeRadius * s + Vector3.new(0, actor.body.Size.Y * 0.6, 0)
			FightFx.shot(T.Shot, mouth, target.centre - dir * target.radius, function()
				land(home)
			end)
		end
		return Vector3.zero, target.centre
	end
	reach = math.max(0, reach)
	local out: number
	if u < T.WindupShare then
		out = -T.WindupStuds * s * smooth(u / T.WindupShare)
	elseif u < T.ContactShare then
		if state.hopBeat ~= index then
			state.hopBeat = index
			SlimeActor.hop(actor, T.LungeHop)
		end
		local k = smooth((u - T.WindupShare) / (T.ContactShare - T.WindupShare))
		out = -T.WindupStuds * s + (reach + T.WindupStuds * s) * k
	elseif u < T.HoldShare then
		out = reach
	elseif u < T.BackShare then
		out = reach * (1 - smooth((u - T.HoldShare) / (T.BackShare - T.HoldShare)))
	else
		out = 0
	end
	if u >= T.ContactShare and state.hitBeat ~= index then
		state.hitBeat = index
		land(home + dir * reach)
	end
	return dir * out, target.centre
end

function WorkMoves.stopTrain(state: State)
	state.beat, state.hopBeat, state.hitBeat = -1, -1, -1
end

function WorkMoves.drop(state: State)
	WorkMoves.stopCook(state)
	WorkMoves.stopTrain(state)
	state.target, state.targetKey = nil, ""
end

return WorkMoves
