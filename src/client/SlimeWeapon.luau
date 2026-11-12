--!strict
-- A slime's weapon, the owner's own model (Config.Weapons, docs/WEAPONS.md §9). It rests across the slime's back in the
-- village and between fights (the Alchemy Kit always at its left), and in a fight it is in hand: the shield and the bow
-- in front, the sword, the focus and the staff at the right; it goes from one place to the other in DrawSeconds. It
-- rides the skin like a worn piece (SlimeActor's loop calls SlimeWeapon.pose with the jelly's bones), sways gently, and
-- plays its family's move on a blow or a cast (shared/WeaponMoves), started so that the move's strike meets the blow;
-- the move's trail, the cast's burst at the weapon's head and, at the higher tiers, the fight's aura come from the VFX
-- library (Config.Weapons.Fx; one that the library does not have yet is left out). The meshes load from Roblox once a
-- weapon (AssetService:CreateMeshPartAsync, as the worn pieces'); a slime given a weapon before it has loaded gets it
-- when it does.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SlimeShape = require(ReplicatedStorage.Shared.SlimeShape)
local VfxLib = require(ReplicatedStorage.Shared.VfxLib)
local WeaponMoves = require(ReplicatedStorage.Shared.WeaponMoves)

local W = Config.Weapons
local S = Config.Slime

type Place = { at: { number }, turn: { number } }
type Family = {
	length: number,
	grip: { number },
	muzzle: number,
	attack: string,
	cast: string,
	rest: Place,
	fight: Place,
}
type Model3 = { mesh: number, size: { number } }
-- `fight`: in hand (true) or on the back; `blend` from 0 (back) to 1 (hand) started at `blendAt` from `blendFrom`.
type Held = {
	gear: string,
	family: string,
	tier: string,
	part: BasePart?,
	scale: number,
	fight: boolean,
	blendFrom: number,
	blendAt: number,
	move: string?,
	moveStart: number,
	phase: number,
	aura: any?,
	cue: number,
}

local FAMILIES: { [string]: Family } = W.Families :: any
local MODELS: { [string]: Model3 } = W.Models :: any
local TEXTURES: { [string]: string } = W.Textures :: any
local GEAR: { [string]: any } = Config.Smithy.Gear :: any

local SlimeWeapon = {}

local templates: { [string]: BasePart } = {}
local loading: { [string]: boolean } = {}
local held: { [Model]: Held } = setmetatable({} :: any, { __mode = "k" })
local turns: { [string]: CFrame } = {}
local random = Random.new()
local warned: { [string]: boolean } = {}

local function warnOnce(key: string, ...: any)
	if not warned[key] then
		warned[key] = true
		warn(Config.LogPrefix, "weapon", key, ...)
	end
end

local function turnOf(key: string, place: Place): CFrame
	local cached = turns[key]
	if cached then
		return cached
	end
	local t = place.turn
	local cf = CFrame.Angles(math.rad(t[1]), 0, 0)
		* CFrame.Angles(0, math.rad(t[2]), 0)
		* CFrame.Angles(0, 0, math.rad(t[3]))
	turns[key] = cf
	return cf
end

-- The weapon a hand gear id stands for (its family and tier), or nil for anything else.
local function weaponOf(gear: string?): (string?, string?)
	local piece = if gear then GEAR[gear] else nil
	if not piece or piece.slot ~= "hand" or not FAMILIES[piece.family] or not MODELS[gear :: string] then
		return nil, nil
	end
	return piece.family, piece.tier
end

-- How big a weapon is on a slime `s` studs tall: the family's Common piece is `length` bodies tall, its other tiers keep
-- their size against it, a Legendary piece is LegendLength times the Common's.
local function sizeOf(gear: string, family: string, tier: string, s: number): Vector3
	local own = MODELS[gear].size
	local base = MODELS[family .. "-wood"].size
	local tall = FAMILIES[family].length * s
	local factor = if tier == "legend" then tall * W.LegendLength / own[2] else tall / base[2]
	return Vector3.new(own[1], own[2], own[3]) * factor
end

local function has(id: string): boolean
	local ok, effect = pcall(VfxLib.get, id)
	return ok and effect ~= nil
end

local function setAura(h: Held)
	local part = h.part
	local want = h.fight and part ~= nil and (W.Fx.AuraTiers :: any)[h.tier] == true
	if want and not h.aura then
		local id = W.Fx.Aura .. h.family
		if has(id) then
			local ok, handle = pcall(VfxLib.attach, part, id, { variant = h.tier, weld = true })
			h.aura = if ok then handle else nil
		end
	elseif not want and h.aura then
		pcall(VfxLib.detach, h.aura)
		h.aura = nil
	end
end

local function give(model: Model, h: Held)
	local template = templates[h.gear]
	if not template or h.part then
		return
	end
	local part = template:Clone()
	local body = model:FindFirstChild("SlimeBody")
	local s = if body and body:IsA("BasePart") then body.Size.Y / S.MeshHeight else 1
	part.Size = sizeOf(h.gear, h.family, h.tier, s)
	part.Name = "Weapon"
	part.Parent = model
	h.part = part
	h.scale = s
	setAura(h)
end

local function load(gear: string, family: string, tier: string)
	if templates[gear] or loading[gear] then
		return
	end
	loading[gear] = true
	task.spawn(function()
		local ok, part = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromAssetId(MODELS[gear].mesh))
		end)
		if not ok then
			warnOnce(gear, "mesh did not load:", part)
			return
		end
		part.TextureID = TEXTURES[if tier == "legend" then "legend" else family]
		part.Color = Color3.new(1, 1, 1)
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		templates[gear] = part
		for model, h in held do
			if h.gear == gear and model.Parent then
				give(model, h)
			end
		end
	end)
end

-- Gives the slime drawn by `model` the weapon of this hand gear id (nil, or any other gear: none); on its back until
-- SlimeWeapon.fight says otherwise.
function SlimeWeapon.wear(model: Model, gear: string?)
	local family, tier = weaponOf(gear)
	local current = held[model]
	if current and current.gear == gear then
		return
	end
	SlimeWeapon.remove(model)
	if not family or not tier or not gear then
		return
	end
	local h: Held = {
		gear = gear,
		family = family,
		tier = tier,
		part = nil,
		scale = 1,
		fight = false,
		blendFrom = 0,
		blendAt = 0,
		move = nil,
		moveStart = 0,
		phase = random:NextNumber(0, 100),
		aura = nil,
		cue = 0,
	}
	held[model] = h
	load(gear, family, tier)
	give(model, h)
end

local function blendOf(h: Held, now: number): number
	local t = math.clamp((now - h.blendAt) / W.DrawSeconds, 0, 1)
	local k = t * t * (3 - 2 * t)
	return h.blendFrom + ((if h.fight then 1 else 0) - h.blendFrom) * k
end

-- In hand for a fight (true) or back on the back (false), drawn over DrawSeconds; `now` true skips the draw.
function SlimeWeapon.fight(model: Model, on: boolean, now: boolean?)
	local h = held[model]
	if not h or (h.fight == on and not now) then
		return
	end
	local clock = os.clock()
	h.blendFrom = if now then (if on then 1 else 0) else blendOf(h, clock)
	h.blendAt = clock
	h.fight = on
	if not on then
		h.move = nil
	end
	setAura(h)
end

-- The weapon's head in the world, where its shots and casts leave from (the family's muzzle along its length), or nil.
function SlimeWeapon.headOf(model: Model): CFrame?
	local h = held[model]
	local part = if h then h.part else nil
	if not h or not part then
		return nil
	end
	return part.CFrame * CFrame.new(0, part.Size.Y * FAMILIES[h.family].muzzle, 0)
end

-- The weapon's family, or nil when the slime holds none.
function SlimeWeapon.familyOf(model: Model): string?
	local h = held[model]
	return if h then h.family else nil
end

-- A blow (`cast` false) or a cast (true) lands in `strikeIn` seconds: the family's move starts so its strike meets it,
-- with its trail while it plays and, for a cast, its burst at the head as it goes off.
function SlimeWeapon.cue(model: Model, cast: boolean, strikeIn: number)
	local h = held[model]
	if not h then
		return
	end
	if not h.fight then
		SlimeWeapon.fight(model, true, true)
	end
	local family = FAMILIES[h.family]
	local move = if cast then family.cast else family.attack
	local seconds = WeaponMoves.Seconds[move]
	local now = os.clock()
	local start = math.max(now, now + strikeIn - WeaponMoves.Strike[move] * seconds)
	h.move, h.moveStart = move, start
	h.cue += 1
	local cue = h.cue
	local trailId = W.Fx.Trail .. h.family
	if has(trailId) then
		task.delay(start - now, function()
			local part = h.part
			if h.cue ~= cue or not part or not part.Parent then
				return
			end
			-- (welded: the weapon is anchored and moved every frame, the effect must ride it)
			local ok, handle = pcall(VfxLib.attach, part, trailId, { variant = h.tier, weld = true })
			if ok and handle then
				-- (it fades out softly; a newer move that took the same trail over takes it off itself)
				task.delay(seconds, function()
					if h.cue == cue then
						pcall(VfxLib.detach, handle)
					end
				end)
			end
		end)
	end
	local castId = W.Fx.Cast .. h.family
	if cast and has(castId) then
		task.delay(math.max(0, strikeIn), function()
			local head = SlimeWeapon.headOf(model)
			if h.cue == cue and head then
				pcall(VfxLib.play, castId, head, { variant = h.tier })
			end
		end)
	end
end

function SlimeWeapon.remove(model: Model)
	local h = held[model]
	if not h then
		return
	end
	held[model] = nil
	if h.part then
		-- (its aura and any trail go at once)
		pcall(VfxLib.detach, h.part, nil, 0)
		h.part:Destroy()
	end
end

-- Where the weapon is at one place for this frame: the place on the skin (riding the squash and the lean), shifted and
-- turned by `sample` about the slime's side axis (or spun about its own length), then the part's centre from the point
-- that sits there (its grip in a hand, its middle on the back).
local function placed(
	h: Held,
	key: string,
	place: Place,
	feet: CFrame,
	b: SlimeShape.Bones,
	s: number,
	tilt: CFrame,
	sample: WeaponMoves.Sample,
	grip: Vector3
): CFrame
	local at = place.at
	local x, y, z = SlimeShape.deform(at[1], at[2], at[3], b)
	local u = W.BodyWidth * s
	local frame = feet * CFrame.new(x * s, y * s, z * s) * tilt * CFrame.new(0, -sample.dy * u, -sample.dx * u)
	local turn = turnOf(h.family .. key, place)
	local cf = if sample.spin
		then frame * turn * CFrame.Angles(0, sample.rot, 0)
		else frame * CFrame.Angles(-sample.rot, 0, 0) * turn
	return cf * CFrame.new(-grip)
end

local function scaled(sample: WeaponMoves.Sample, by: number): WeaponMoves.Sample
	return { rot = sample.rot * by, dx = sample.dx * by, dy = sample.dy * by, spin = sample.spin }
end

-- Called from SlimeActor's loop for every slime it moves (as SlimeWear.pose): adds the weapon's part and frame.
function SlimeWeapon.pose(
	model: Model,
	feet: CFrame,
	b: SlimeShape.Bones,
	s: number,
	now: number,
	parts: { BasePart },
	cfs: { CFrame },
	n: number
): number
	local h = held[model]
	local part = if h then h.part else nil
	if not h or not part then
		return n
	end
	if math.abs(h.scale - s) > 1e-3 then
		-- (a slime that grew)
		part.Size = sizeOf(h.gear, h.family, h.tier, s)
		h.scale = s
	end
	local family = FAMILIES[h.family]
	-- the skin's upright line under the jelly's lean and squash (as SlimeWear)
	local up = Vector3.new(b.top.x / S.BoneK, 1 + b.top.y / S.BoneK, b.top.z / S.BoneK).Unit
	local tilt = CFrame.fromMatrix(Vector3.zero, (Vector3.xAxis - up * up.X).Unit, up)
	local v = blendOf(h, now)
	local idle = WeaponMoves.idle(h.family, now + h.phase)
	local cf: CFrame
	local restCf: CFrame? = nil
	if v < 1 then
		restCf = placed(h, "rest", family.rest, feet, b, s, tilt, scaled(idle, W.RestSway), Vector3.zero)
	end
	if v > 0 then
		local move = h.move
		local sample = idle
		if move then
			local t = now - h.moveStart
			if t >= WeaponMoves.Seconds[move] then
				h.move = nil
			elseif t >= 0 then
				sample = WeaponMoves.sample(move, t)
			end
		end
		local g = family.grip
		local grip = Vector3.new(g[1] * part.Size.X, g[2] * part.Size.Y, g[3] * part.Size.Z)
		local fightCf = placed(h, "fight", family.fight, feet, b, s, tilt, sample, grip)
		cf = if restCf then restCf:Lerp(fightCf, v) else fightCf
	else
		cf = restCf :: CFrame
	end
	n += 1
	parts[n] = part
	cfs[n] = cf
	return n
end

return SlimeWeapon
