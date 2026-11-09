-- Where on a host a piece is born, as an offset from the middle of the host's box, in the box's own frame (its front is
-- -Z, as a character's). Every anchor is a share of the host's size, so one effect fits a slime, a pet, a player and a
-- giant alike.
--   body    the middle (its emitters are born anywhere in a box `box` times the host's size, default 0.8)
--   feet    just over the ground        waist  a third up        chest  two thirds up        head  the top
--   above   a little over the top (snow falls from here)         crown  over the head (a halo)
--   ground  on the ground (flat pictures: sigils, rings)          back   behind the body      front  before it
--   origin  the very point a one-shot was played at
local Anchors = {}

-- { height share from the bottom, depth: -1 front / 0 middle / 1 back, outside: studs beyond the box }
Anchors.Points = {
	body = { 0.5, 0 },
	origin = { 0.5, 0 },
	feet = { 0.055, 0 },
	waist = { 0.35, 0 },
	chest = { 0.65, 0 },
	head = { 0.98, 0 },
	above = { 1.12, 0 },
	crown = { 1.2, 0 },
	ground = { 0, 0, 0.04 },
	back = { 0.5, 1 },
	front = { 0.5, -1 },
}

-- Trails lay their particles just behind the runner's back (TrailBuilder's BACK, studs).
Anchors.Behind = 0.1

function Anchors.exists(name)
	return Anchors.Points[name] ~= nil
end

-- The offset (a Vector3) of anchor `name` on a host box of `size`; `behind` puts it just behind the back.
function Anchors.offset(name, size, behind)
	local point = Anchors.Points[name] or Anchors.Points.body
	local y = -size.Y / 2 + size.Y * point[1] + (point[3] or 0)
	local z = point[2] * size.Z / 2
	if behind then
		z = size.Z / 2 + Anchors.Behind
	end
	return Vector3.new(0, y, z)
end

return Anchors
