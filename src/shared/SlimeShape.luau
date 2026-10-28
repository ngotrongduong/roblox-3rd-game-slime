--!strict
-- The slime body's shape, in numbers: how a point of its skin moves when the Root-Base-Top-Left-Right-Front-Back
-- rig is pulled, so a face drawn on the front can ride the skin exactly (a Decal or SurfaceGui on a skinned
-- MeshPart does NOT follow the bones; the face parts are separate plates that SlimeFace places with this).
--
-- Mesh space (the imported SlimeBody MeshPart, feet at y = 0, one body height = 1): the front is -Z, the slime's
-- own left is -X (the viewer's right when looking at its face). A vertex is pulled by its weights toward the bones
-- (art/models/slime_body/rounds.md): Top by y / K, Left by max(-x, 0) / K, Right by max(x, 0) / K, Front by
-- max(-z, 0) / K, Back by max(z, 0) / K, Base takes the rest and never moves. K is Config.Slime.BoneK.
-- Pure numbers, no Roblox datatypes, so Lune tests it.

local Config = if script then require(script.Parent.Config) else require("./Config")

local C = Config.Slime

local SlimeShape = {}

-- Radius of the body at a height (the body is a surface of revolution), sampled from
-- art/models/slime_body/uv_profile.json every 0.05 of the height.
local PROFILE_STEP = 0.05
local PROFILE: { number } = {
	0.1164,
	0.3466,
	0.4251,
	0.4704,
	0.4995,
	0.5171,
	0.5258,
	0.5269,
	0.5221,
	0.5131,
	0.4997,
	0.4811,
	0.4568,
	0.4248,
	0.3822,
	0.3253,
	0.2417,
	0.1508,
	0.0997,
	0.0671,
	0.0,
}

export type Pose = {
	sy: number, -- height factor
	sx: number, -- width factor (both across and front to back)
	leanFwd: number, -- the tip leans toward the front by this many body heights
	leanSide: number, -- the tip leans toward the slime's own left (the viewer's right) by this much
}

export type Vec = { x: number, y: number, z: number }
export type Bones = { top: Vec, left: Vec, right: Vec, front: Vec, back: Vec }

function SlimeShape.radius(y: number): number
	local f = math.clamp(y, 0, 1) / PROFILE_STEP
	local i = math.min(math.floor(f), #PROFILE - 2)
	local t = f - i
	return PROFILE[i + 1] + (PROFILE[i + 2] - PROFILE[i + 1]) * t
end

-- How far each bone moves (mesh units) for a pose. Scale the numbers by the model's scale for
-- Bone.Transform, which is in studs.
function SlimeShape.bones(pose: Pose): Bones
	local k = C.BoneK
	local d = (pose.sx - 1) * k
	return {
		top = { x = -pose.leanSide * k, y = (pose.sy - 1) * k, z = -pose.leanFwd * k },
		left = { x = -d, y = 0, z = 0 },
		right = { x = d, y = 0, z = 0 },
		front = { x = 0, y = 0, z = -d },
		back = { x = 0, y = 0, z = d },
	}
end

-- Where a rest-pose point of the skin ends up.
function SlimeShape.deform(x: number, y: number, z: number, b: Bones): (number, number, number)
	local k = C.BoneK
	local wt = math.max(y, 0) / k
	local wl, wr = math.max(-x, 0) / k, math.max(x, 0) / k
	local wf, wb = math.max(-z, 0) / k, math.max(z, 0) / k
	return x + wt * b.top.x + wl * b.left.x + wr * b.right.x + wf * b.front.x + wb * b.back.x,
		y + wt * b.top.y + wl * b.left.y + wr * b.right.y + wf * b.front.y + wb * b.back.y,
		z + wt * b.top.z + wl * b.left.z + wr * b.right.z + wf * b.front.z + wb * b.back.z
end

-- A point on the front of the skin by its place on the flat face: u across (positive toward the viewer's
-- right), v up from the face centre, both in body heights (an orthographic projection of the face onto the front).
function SlimeShape.frontPoint(u: number, v: number): (number, number, number)
	local y = math.clamp(C.FaceHeight + v, 0.05, 0.95)
	local r = SlimeShape.radius(y)
	local x = math.clamp(u, -r * 0.97, r * 0.97)
	return -x, y, -math.sqrt(math.max(r * r - x * x, 0))
end

export type Plate = {
	px: number,
	py: number,
	pz: number, -- the point on the deformed skin
	rx: number,
	ry: number,
	rz: number, -- unit direction of +u (toward the viewer's right)
	ux: number,
	uy: number,
	uz: number, -- unit direction of +v (up the face)
	nx: number,
	ny: number,
	nz: number, -- unit outward normal
	scaleU: number,
	scaleV: number, -- how much the skin there is stretched across and up, against rest
}

local function sub(ax: number, ay: number, az: number, bx: number, by: number, bz: number): (number, number, number)
	return ax - bx, ay - by, az - bz
end

local function unit(x: number, y: number, z: number): (number, number, number, number)
	local m = math.sqrt(x * x + y * y + z * z)
	if m < 1e-9 then
		return 0, 0, 0, 0
	end
	return x / m, y / m, z / m, m
end

-- The frame of the skin under the face point (u, v) once the body is deformed: where it is, which way across
-- and up the face run, which way is out, and how stretched the skin is there.
function SlimeShape.plate(u: number, v: number, b: Bones): Plate
	local h = 0.02
	local function at(du: number, dv: number): (number, number, number)
		local x, y, z = SlimeShape.frontPoint(u + du, v + dv)
		return SlimeShape.deform(x, y, z, b)
	end
	local cx, cy, cz = at(0, 0)
	local ax, ay, az = at(h, 0)
	local bx, by, bz = at(-h, 0)
	local ex, ey, ez = at(0, h)
	local fx, fy, fz = at(0, -h)
	local tux, tuy, tuz = sub(ax, ay, az, bx, by, bz)
	local tvx, tvy, tvz = sub(ex, ey, ez, fx, fy, fz)
	local rx, ry, rz, lu = unit(tux, tuy, tuz)
	local wx, wy, wz, lv = unit(tvx, tvy, tvz)
	-- normal = u x v flipped to point out of the front (-Z side): across x up, with across = viewer's right
	local nx, ny, nz = ry * wz - rz * wy, rz * wx - rx * wz, rx * wy - ry * wx
	-- viewer's right (+u) is mesh -X and up is +Y: across x up = (-1,0,0) x (0,1,0) = (0,0,-1): already outward
	local ox, oy, oz = unit(nx, ny, nz)
	-- the same two spans on the body at rest, to say how much the skin is stretched
	local r0x, r0y, r0z = SlimeShape.frontPoint(u + h, v)
	local r1x, r1y, r1z = SlimeShape.frontPoint(u - h, v)
	local v0x, v0y, v0z = SlimeShape.frontPoint(u, v + h)
	local v1x, v1y, v1z = SlimeShape.frontPoint(u, v - h)
	local restU = math.sqrt((r0x - r1x) ^ 2 + (r0y - r1y) ^ 2 + (r0z - r1z) ^ 2)
	local restV = math.sqrt((v0x - v1x) ^ 2 + (v0y - v1y) ^ 2 + (v0z - v1z) ^ 2)
	-- the second tangent made square to the first (the skin shears a little when the body leans)
	local dot = wx * rx + wy * ry + wz * rz
	local ux, uy, uz = unit(wx - rx * dot, wy - ry * dot, wz - rz * dot)
	return {
		px = cx,
		py = cy,
		pz = cz,
		rx = rx,
		ry = ry,
		rz = rz,
		ux = ux,
		uy = uy,
		uz = uz,
		nx = ox,
		ny = oy,
		nz = oz,
		scaleU = lu / math.max(restU, 1e-6),
		scaleV = lv / math.max(restV, 1e-6),
	}
end

return SlimeShape
