-- The village template's loose rocks become the valley's rocks, each exactly where the old one stood and never wider, so that no upgrade
-- level loses its room (tools/map/check_village_trees.luau checks it). Old names stay: stages may find scenery by name. Re-runnable: pieces
-- with attribute VillageRocks are left alone. Rocks that work (the pond's FishRock, bank stones) are not in Nature or FenceSkirt's list.
local kit = game:GetService("ServerStorage").WildKit
local plot = workspace.Map.Plot5
local rng = Random.new(5)

local OLD = { FlatBoulder = true, JaggedRocks = true, MediumRock = true, MossyBoulder = true, SmallRocks = true, StackedRocks = true, WideBoulder = true }
local ROCKS = { "QtRock_Medium_1", "QtRock_Medium_2", "QtRock_Medium_3" }
local WARM = { Color3.fromRGB(255, 232, 196), Color3.fromRGB(255, 240, 210), Color3.fromRGB(250, 226, 190) } -- build_wild_slices' ROCK_WARM
local SINK = 0.12 -- of the height: a rock sits in the ground, it does not rest on it
local NO_SHADOW_BELOW = 3 -- studs tall
local MAX_WIDE = 7.5 -- the long old pieces become a rock this wide, not a slab as long as they were

local function fitted(old: Model): Model
	local cf, size = old:GetBoundingBox()
	local rock = kit[ROCKS[rng:NextInteger(1, #ROCKS)]]:Clone()
	local _, rockSize = rock:GetBoundingBox()
	local wide = math.min(size.X, size.Z, MAX_WIDE)
	rock:ScaleTo(rock:GetScale() * wide / math.max(rockSize.X, rockSize.Z))
	local _, fit = rock:GetBoundingBox()
	local tint = WARM[rng:NextInteger(1, #WARM)]
	local collide = false
	for _, d in old:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide then
			collide = true
		end
	end
	for _, d in rock:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
			d.CanTouch = false
			d.CanQuery = collide
			d.CastShadow = fit.Y >= NO_SHADOW_BELOW
			d.Color = tint
			local look = d:FindFirstChildOfClass("SurfaceAppearance")
			if look then
				look.Color = tint
			end
		end
	end
	local foot = cf.Position - Vector3.new(0, size.Y / 2 + fit.Y * SINK, 0)
	rock:PivotTo(CFrame.new(foot) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	rock.Name = old.Name
	rock:SetAttribute("VillageRocks", true)
	-- check_village_trees then tests the rock against the upgrade levels, and not plants against rocks: a flower beside a stone is fine.
	rock:SetAttribute("Role", "small")
	return rock
end

local changed, seen = {}, 0
for _, holder in plot:GetDescendants() do
	if holder:IsA("Folder") and (holder.Name == "Nature" or holder.Name == "FenceSkirt") or holder:IsA("Model") and (holder.Name == "Nature" or holder.Name == "FenceSkirt") then
		for _, item in holder:GetChildren() do
			if item:IsA("Model") and OLD[item.Name] and item:GetAttribute("VillageRocks") == nil then
				local rock = fitted(item)
				rock.Parent = holder
				item:Destroy()
				changed[rock.Name] = (changed[rock.Name] or 0) + 1
				seen += 1
				if seen % 20 == 0 then
					task.wait()
				end
			end
		end
	end
end
-- The old rocks stood where upgrades later build, and were never checked: the walls from level 21 stand on the fence line, the gate grows
-- steps and beds, the pond and training ground spread. Skirt rocks move out past the wall; the few where an upgrade grows go.
local WALL = 116 -- the fence line, across the plot's frame
local WALL_ROOM = 3 -- studs of grass between the wall and a rock
local GATE_SIDE, GATE_HALF = -1, 28 -- the gate's side of the plot (x in the frame) and half the width its upgrades take
local GONE = { "FishingPondL1", "TrainingL1" }
local frame = plot:GetPivot()
local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Include
ground.FilterDescendantsInstances = { workspace.Terrain }
local moved, gone = 0, 0
for _, item in plot:GetDescendants() do
	if item:GetAttribute("VillageRocks") then
		if item.Parent.Name == "Nature" and table.find(GONE, item.Parent.Parent.Name) then
			item:Destroy()
			gone += 1
		elseif item.Parent.Name == "FenceSkirt" then
			local at = frame:PointToObjectSpace(item:GetPivot().Position)
			local size = item:GetExtentsSize()
			local reach = math.max(size.X, size.Z) * 0.72
			if at.X * GATE_SIDE > WALL - 6 and math.abs(at.Z) < GATE_HALF then
				item:Destroy()
				gone += 1
			else
				local need = WALL + WALL_ROOM + reach
				local x, z = at.X, at.Z
				if math.abs(x) >= math.abs(z) and math.abs(x) < need then
					x = need * math.sign(x)
				elseif math.abs(z) > math.abs(x) and math.abs(z) < need then
					z = need * math.sign(z)
				end
				if x ~= at.X or z ~= at.Z then
					local world = frame:PointToWorldSpace(Vector3.new(x, at.Y, z))
					local hit = workspace:Raycast(world + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), ground)
					local y = if hit then hit.Position.Y - size.Y * SINK else item:GetPivot().Position.Y
					local _, _, yaw = item:GetPivot():ToEulerAnglesYXZ()
					item:PivotTo(CFrame.new(world.X, y, world.Z) * CFrame.Angles(0, yaw, 0))
					moved += 1
				end
			end
		end
	end
end
print("[GooLineage] village rocks moved past the wall: " .. moved .. ", removed: " .. gone)
local out = {}
for name, count in changed do
	table.insert(out, name .. " x" .. count)
end
print("[GooLineage] village rocks: " .. seen .. " changed: " .. table.concat(out, ", "))
