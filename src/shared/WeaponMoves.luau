--!strict
-- How a held weapon moves, apart from the body (the owner's original, battle/weaponAnims.js, its numbers kept): a basic
-- attack's move and a cast's move for each family, and a gentle idle sway so a weapon never looks welded on. A sample is
-- a turn about the slime's side axis (`rot`, radians, positive = the tip forward and down), a shift forward (`dx`) and
-- down (`dy`) in body widths, and `spin`: the turn is about the weapon's own length instead (the focus's orbit). Pure
-- numbers: client/SlimeWeapon places the weapon with them, Lune tests them.
local WeaponMoves = {}

export type Sample = { rot: number, dx: number, dy: number, spin: boolean }

-- Seconds a move lasts, and the share of it at which its blow or its cast goes off (the swing's slash, the bow's
-- release, the staff held high): the client starts a move so that moment meets the blow.
WeaponMoves.Seconds = {
	swing = 0.34,
	draw = 0.42,
	raise = 0.6,
	orbit = 0.55,
	shake = 0.45,
	brace = 0.4,
	cleave = 0.5,
	volley = 0.62,
	channel = 0.85,
	surge = 0.75,
	fling = 0.58,
	bastion = 0.55,
}
WeaponMoves.Strike = {
	swing = 0.55,
	draw = 0.5,
	raise = 0.35,
	orbit = 0.5,
	shake = 0.5,
	brace = 0.25,
	cleave = 0.65,
	volley = 0.62,
	channel = 0.3,
	surge = 0.5,
	fling = 0.4,
	bastion = 0.2,
}

local REST: Sample = { rot = 0, dx = 0, dy = 0, spin = false }

local function clamp01(v: number): number
	return math.clamp(v, 0, 1)
end
local function easeOut(t: number): number
	return 1 - (1 - t) * (1 - t)
end
local function easeIn(t: number): number
	return t * t
end
-- a damped settle wobble, 1 to 0
local function settle(t: number): number
	return math.sin(t * math.pi * 3) * (1 - t) * 0.35
end

local function at(rot: number, dx: number, dy: number): Sample
	return { rot = rot, dx = dx, dy = dy, spin = false }
end

-- The move `kind` at `t` seconds in (the rest pose before it starts and once it is over).
function WeaponMoves.sample(kind: string, t: number): Sample
	local seconds = WeaponMoves.Seconds[kind]
	if not seconds or t < 0 or t >= seconds then
		return REST
	end
	local p = clamp01(t / seconds)
	if kind == "swing" then
		-- wind back high over the shoulder, then a fast wide slash forward and down (in 3D it stops a little below level:
		-- the original's flat arc of 1.9 drove the blade into the ground)
		if p < 0.3 then
			local k = easeOut(p / 0.3)
			return at(-1.4 * k, -0.1 * k, -0.12 * k)
		elseif p < 0.6 then
			local k = easeIn((p - 0.3) / 0.3)
			return at(-1.4 + 2.55 * k, -0.1 + 0.45 * k, -0.12 + 0.22 * k)
		end
		local k = (p - 0.6) / 0.4
		local s = 1 - easeOut(k)
		return at(1.15 * s + settle(k) * 0.6, 0.35 * s, 0.1 * s)
	elseif kind == "draw" then
		-- raise and pull the bow back toward the body with a tilt, then snap it forward and up on release
		if p < 0.5 then
			local k = easeOut(p / 0.5)
			return at(-0.55 * k, -0.22 * k, -0.1 * k)
		end
		local k = (p - 0.5) / 0.5
		local s = 1 - easeOut(k)
		return at(-0.55 * s + 0.35 * (1 - s) * (1 - k) + settle(k) * 0.6, -0.22 * s + 0.2 * (1 - s) * (1 - k), -0.1 * s)
	elseif kind == "raise" then
		-- sweep the staff up in an arc over the head, hold it there, sweep it back down
		if p < 0.3 then
			local k = easeOut(p / 0.3)
			return at(-1.1 * k, -0.1 * k, -0.5 * k)
		elseif p < 0.65 then
			local k = (p - 0.3) / 0.35
			return at(-1.1 + math.sin(k * math.pi * 2) * 0.08, -0.1, -0.5)
		end
		local s = 1 - easeIn((p - 0.65) / 0.35)
		return at(-1.1 * s, -0.1 * s, -0.5 * s)
	elseif kind == "orbit" then
		-- float up and turn round once, drift back down
		return {
			rot = easeOut(p) * math.pi * 2,
			dx = 0.06 * math.sin(p * math.pi),
			dy = -math.sin(p * math.pi) * 0.3,
			spin = true,
		}
	elseif kind == "shake" then
		-- rattle, then a little toss up with a bounce
		if p < 0.5 then
			local wave = math.sin(p / 0.5 * math.pi * 6)
			return at(wave * 0.3, wave * 0.03, 0)
		end
		local k = (p - 0.5) / 0.5
		return at(0.25 * math.sin(k * math.pi), 0, -math.sin(k * math.pi) * 0.2)
	elseif kind == "brace" then
		-- thrust the shield forward and up, hold, pull back
		if p < 0.25 then
			local k = easeOut(p / 0.25)
			return at(0.2 * k, 0.22 * k, -0.05 * k)
		elseif p < 0.6 then
			return at(0.2, 0.22, -0.05)
		end
		local s = 1 - easeOut((p - 0.6) / 0.4)
		return at(0.2 * s, 0.22 * s, -0.05 * s)
	elseif kind == "cleave" then
		-- the sword's cast: a slow high wind-up over the head (the warning), then a huge overhead cut through the target
		-- (down to just above the ground, as the swing)
		if p < 0.45 then
			local k = easeOut(p / 0.45)
			return at(-1.9 * k, -0.12 * k, -0.28 * k)
		elseif p < 0.68 then
			local k = easeIn((p - 0.45) / 0.23)
			return at(-1.9 + 3.2 * k, -0.12 + 0.55 * k, -0.28 + 0.42 * k)
		end
		local k = (p - 0.68) / 0.32
		local s = 1 - easeOut(k)
		return at(1.3 * s + settle(k) * 0.6, 0.43 * s, 0.14 * s)
	elseif kind == "volley" then
		-- the bow's cast: pull to a full draw and hold it trembling, aimed high, then let go up and forward
		if p < 0.4 then
			local k = easeOut(p / 0.4)
			return at(-1.05 * k, -0.3 * k, -0.16 * k)
		elseif p < 0.62 then
			local tremble = math.sin((p - 0.4) / 0.22 * math.pi * 6) * 0.03
			return at(-1.05 + tremble, -0.3 + tremble * 0.4, -0.16)
		end
		local k = (p - 0.62) / 0.38
		local s = 1 - easeOut(k)
		return at(
			-1.05 * s + 0.5 * (1 - s) * (1 - k) + settle(k) * 0.7,
			-0.3 * s + 0.18 * (1 - s) * (1 - k),
			-0.16 * s - 0.1 * (1 - s) * (1 - k)
		)
	elseif kind == "channel" then
		-- the staff's cast: raised high overhead and held while the cast channels
		if p < 0.25 then
			local k = easeOut(p / 0.25)
			return at(-1.25 * k, -0.08 * k, -0.58 * k)
		elseif p < 0.7 then
			local k = (p - 0.25) / 0.45
			return at(-1.25 + math.sin(k * math.pi * 2) * 0.06, -0.08, -0.58)
		end
		local s = 1 - easeIn((p - 0.7) / 0.3)
		return at(-1.25 * s, -0.08 * s, -0.58 * s)
	elseif kind == "surge" then
		-- the focus's cast: it rockets up and spins one and a half turns
		return {
			rot = easeOut(p) * math.pi * 3,
			dx = 0.1 * math.sin(p * math.pi),
			dy = -math.sin(p * math.pi) * 0.42,
			spin = true,
		}
	elseif kind == "fling" then
		-- the kit's cast: wound back low, then hurled high with a full turn over (the acid lob)
		if p < 0.35 then
			local k = easeOut(p / 0.35)
			return at(0.4 * k, -0.18 * k, 0.12 * k)
		end
		local k = (p - 0.35) / 0.65
		return at(0.4 - easeOut(k) * math.pi * 2, -0.18 + 0.3 * k, 0.12 - math.sin(k * math.pi) * 0.5)
	elseif kind == "bastion" then
		-- the shield's cast: slammed forward hard and planted there (the taunt's hold), then dragged back
		if p < 0.2 then
			local k = easeIn(p / 0.2)
			return at(0.28 * k, 0.34 * k, -0.02 * k)
		elseif p < 0.68 then
			local k = (p - 0.2) / 0.48
			return at(0.28 + math.sin(k * math.pi * 4) * 0.02, 0.34, -0.02 + 0.04 * math.sin(k * math.pi))
		end
		local s = 1 - easeOut((p - 0.68) / 0.32)
		return at(0.28 * s, 0.34 * s, -0.02 * s)
	end
	return REST
end

-- The family's idle sway at clock `t` (with its own phase): staves and foci float and twirl slowly, the bow swings like
-- a pendulum, the shield heaves a little, the kit jiggles, the sword wags.
function WeaponMoves.idle(family: string, t: number): Sample
	if family == "staff" or family == "focus" then
		return at(math.sin(t * 1.1) * 0.12, 0, -0.03 + math.sin(t * 1.6) * 0.04)
	elseif family == "bow" then
		return at(math.sin(t * 1.3) * 0.1, 0, math.sin(t * 2.6) * 0.012)
	elseif family == "shield" then
		return at(math.sin(t * 0.9) * 0.05, 0, math.sin(t * 1.8) * 0.015)
	elseif family == "kit" then
		return at(math.sin(t * 2.2) * 0.07, 0, math.sin(t * 3.1) * 0.012)
	end
	return at(math.sin(t * 1.5) * 0.14, 0, math.sin(t * 2.2) * 0.015)
end

return WeaponMoves
