--!strict
-- The effects of a fight, all made of the owner's own battle art (docs/reference/04-vfx-animation.md §8.4-8.5): the mark
-- a blow leaves (by the attacker: a slime's role, a zombie's kind), the goo it knocks out of the one hit (glossy drops of
-- its own body), the sparks of a crit, a spit that flies, the burst and ground ring of a fall, the after-images of a dodge,
-- the stars of a fall and of a cheer. Each effect is a short-lived anchored part with a burst of particles, capped
-- (View.Fx.MaxMarks, MaxGoo) for cheap phones. Client only: nothing here changes a fight, and nothing touches the camera
-- (the owner, 2026-11-03: the player watches from outside).
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local F = Config.Zombies.View.Fx

export type Style = {
	mark: string,
	bits: string?,
	size: number,
	slash: boolean?,
	shot: string?,
	death: string?,
	ring: string?,
}

type Drop = { part: Part, velocity: Vector3, born: number, life: number, size: number }

local FightFx = {}
local marksAlive = 0
local drops: { Drop } = {}
local dropLoop: RBXScriptConnection? = nil

function FightFx.style(name: string?): Style
	local styles = F.Styles :: any
	return styles[name or ""] or styles.attack
end

local function texture(name: string): string
	return "rbxassetid://" .. tostring((F.Textures :: any)[name] or 0)
end

function FightFx.anchorAt(position: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = "FightFx"
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	return anchor
end

local function emitter(name: string, parent: Instance): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture(name)
	particles.Rate = 0
	particles.LightInfluence = 0
	particles.Speed = NumberRange.new(0)
	particles.Parent = parent
	return particles
end

-- One picture that swells and fades where it stands, facing the camera (a hit mark, a burst).
local function flash(anchor: Part, name: string, size: number, seconds: number, rotation: number?, spin: number?)
	local mark = emitter(name, anchor)
	mark.Lifetime = NumberRange.new(seconds)
	mark.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size * 0.75),
		NumberSequenceKeypoint.new(1, size * F.MarkSwell),
	})
	mark.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.12, 0.02),
		NumberSequenceKeypoint.new(0.55, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	local angle = rotation or math.random(0, 359)
	mark.Rotation = NumberRange.new(angle)
	local turn = spin or (math.random() - 0.5) * 140
	mark.RotSpeed = NumberRange.new(turn)
	mark.ZOffset = 2
	mark:Emit(1)
end

-- Small pictures thrown out of a point (motes of dust, sparks, acid drops, spores).
local function scatter(anchor: Part, name: string, count: number, size: number, speed: number, up: boolean?)
	if count <= 0 then
		return
	end
	local bits = emitter(name, anchor)
	bits.Lifetime = NumberRange.new(0.45, 0.75)
	bits.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.3) })
	bits.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	bits.Speed = NumberRange.new(speed * 0.6, speed)
	bits.SpreadAngle = Vector2.new(if up then 35 else 180, if up then 35 else 180)
	bits.EmissionDirection = Enum.NormalId.Top
	bits.Acceleration = Vector3.new(0, if up then 2 else -28, 0)
	bits.Drag = 1.5
	bits.Rotation = NumberRange.new(0, 359)
	bits.RotSpeed = NumberRange.new(-180, 180)
	bits.ZOffset = 3
	bits:Emit(count)
end

-- The angle on screen of the line from `a` to `b` (degrees, as a particle's Rotation turns), for marks that lie across
-- a blow.
local function screenAngle(a: Vector3, b: Vector3): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 0
	end
	local pa = camera:WorldToViewportPoint(a)
	local pb = camera:WorldToViewportPoint(b)
	return math.deg(math.atan2(pb.Y - pa.Y, pb.X - pa.X))
end

-- The mark of a blow at `at`, struck from `from`: the attacker's picture, what flies off it, and on a crit a bigger mark
-- and a shower of stars.
function FightFx.mark(style: Style, at: Vector3, from: Vector3, crit: boolean)
	if marksAlive >= F.MaxMarks then
		return
	end
	marksAlive += 1
	local anchor = FightFx.anchorAt(at)
	local size = style.size * (if crit then F.CritScale else 1)
	if style.slash then
		-- across the blow, sweeping through it
		local across = screenAngle(from, at) + 90
		flash(anchor, style.mark, size, F.MarkSeconds, across - 40, 260)
	else
		flash(anchor, style.mark, size, F.MarkSeconds)
	end
	if style.bits then
		scatter(anchor, style.bits, F.Bits, size * 0.18, 14)
	end
	if crit then
		scatter(anchor, "sparkStar", F.CritSparks, size * 0.2, 18)
	end
	Debris:AddItem(anchor, 1)
	task.delay(1, function()
		marksAlive -= 1
	end)
end

-- A burst over a point (a fall), with motes.
function FightFx.burst(name: string, at: Vector3, size: number, bits: string?)
	local anchor = FightFx.anchorAt(at)
	flash(anchor, name, size, 0.45)
	if bits then
		scatter(anchor, bits, F.Bits + 3, size * 0.12, 16)
	end
	Debris:AddItem(anchor, 1.2)
end

-- Stars rising over a head (a slime that falls dizzy, a slime that cheers).
function FightFx.stars(at: Vector3, size: number)
	local anchor = FightFx.anchorAt(at)
	scatter(anchor, "sparkStar", F.Stars, size, 6, true)
	Debris:AddItem(anchor, 1.2)
end

-- A ring on the ground that spreads and fades (flat at the feet, under the bodies).
function FightFx.ring(name: string, at: Vector3, diameter: number)
	local disc = Instance.new("Part")
	disc.Name = "FightRing"
	disc.Size = Vector3.new(diameter * 0.25, 0.05, diameter * 0.25)
	disc.Transparency = 1
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanTouch = false
	disc.CanQuery = false
	disc.CastShadow = false
	disc.CFrame = CFrame.new(at + Vector3.new(0, 0.08, 0))
	local decal = Instance.new("Decal")
	decal.Texture = texture(name)
	decal.Face = Enum.NormalId.Top
	decal.Transparency = 0.05
	decal.Parent = disc
	disc.Parent = workspace
	local info = TweenInfo.new(F.RingSeconds, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	TweenService:Create(disc, info, { Size = Vector3.new(diameter, 0.05, diameter) }):Play()
	TweenService:Create(decal, TweenInfo.new(F.RingSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1,
	}):Play()
	Debris:AddItem(disc, F.RingSeconds + 0.1)
end

-- ===== Goo drops: glossy bits of the body itself, thrown off and falling =====

local function stepDrops(dt: number)
	local now = os.clock()
	for index = #drops, 1, -1 do
		local drop = drops[index]
		local age = now - drop.born
		if age >= drop.life or not drop.part.Parent then
			drop.part:Destroy()
			table.remove(drops, index)
		else
			drop.velocity -= Vector3.new(0, F.Goo.gravity * dt, 0)
			local k = age / drop.life
			local size = drop.size * (if k > 0.6 then 1 - (k - 0.6) / 0.4 else 1)
			drop.part.Size = Vector3.one * math.max(size, 0.02)
			drop.part.CFrame = drop.part.CFrame + drop.velocity * dt
		end
	end
	if #drops == 0 and dropLoop then
		dropLoop:Disconnect()
		dropLoop = nil
	end
end

-- `count` drops of `body` thrown from `at`, mostly along `direction` (flat), and up.
function FightFx.goo(body: BasePart, at: Vector3, direction: Vector3, count: number)
	local G = F.Goo
	local flatDir = Vector3.new(direction.X, 0, direction.Z)
	flatDir = if flatDir.Magnitude > 1e-3 then flatDir.Unit else Vector3.zAxis
	for _ = 1, math.min(count, F.MaxGoo - #drops) do
		local part = Instance.new("Part")
		part.Name = "Goo"
		part.Shape = Enum.PartType.Ball
		part.Color = body.Color
		part.Material = body.Material
		part.Reflectance = body.Reflectance
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		local size = G.size * (0.6 + math.random() * 0.8)
		part.Size = Vector3.one * size
		part.CFrame = CFrame.new(at)
		part.Parent = workspace
		local spread = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 1.2
		local speed = G.speedMin + math.random() * (G.speedMax - G.speedMin)
		local velocity = (flatDir + spread).Unit * speed + Vector3.new(0, G.up * (0.5 + math.random() * 0.7), 0)
		table.insert(drops, { part = part, velocity = velocity, born = os.clock(), life = G.life, size = size })
	end
	if #drops > 0 and not dropLoop then
		dropLoop = RunService.RenderStepped:Connect(stepDrops)
	end
end

-- ===== A spit that flies =====

-- The picture flies from `from` to `to` in a low arc, turned along its path on screen, then `arrive` runs.
function FightFx.shot(name: string, from: Vector3, to: Vector3, arrive: () -> ())
	local anchor = FightFx.anchorAt(from)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(F.ShotSize, F.ShotSize)
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = texture(name)
	image.Parent = gui
	local start = os.clock()
	local connection: RBXScriptConnection? = nil
	local last = from
	connection = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - start) / F.ShotSeconds, 0, 1)
		local point = from:Lerp(to, t) + Vector3.new(0, math.sin(math.pi * t) * F.ShotArc, 0)
		anchor.CFrame = CFrame.new(point)
		if (point - last).Magnitude > 1e-3 then
			image.Rotation = screenAngle(last, point)
		end
		last = point
		if t >= 1 then
			if connection then
				connection:Disconnect()
			end
			anchor:Destroy()
			arrive()
		end
	end)
	-- (never left behind, even if a frame never comes)
	Debris:AddItem(anchor, F.ShotSeconds + 1)
end

-- ===== After-images of a dodge =====

-- Fading copies of the body along the side-step it is about to make (`step`, studs).
function FightFx.afterImages(body: MeshPart, step: Vector3)
	local count = F.AfterImages
	local start = body.CFrame
	for index = 1, count do
		local copy = body:Clone()
		copy:ClearAllChildren()
		copy.Anchored = true
		copy.CanCollide = false
		copy.CanTouch = false
		copy.CanQuery = false
		copy.CastShadow = false
		copy.Transparency = F.AfterImageTransparency
		local k = (index - 1) / count
		copy.CFrame = start + step * k
		copy.Parent = workspace
		local seconds = F.AfterImageSeconds * (0.5 + 0.5 * k)
		TweenService:Create(copy, TweenInfo.new(seconds), { Transparency = 1 }):Play()
		Debris:AddItem(copy, seconds + 0.05)
	end
end

return FightFx
