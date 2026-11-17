--!strict
-- The fishing pond's stage for AreaUpgrade, in the same shape as the other areas' (build(area, frame, level)): the
-- pier and the banks' life (PondStages) with the Dock landmark on them (Boathouse: the boathouse, the lighthouse, the
-- fence, the boat). The two meet here and not in PondStages because Architecture, which Boathouse builds on, reads
-- PondStages' stud look.
local Boathouse = require(script.Parent.Boathouse)
local PondStages = require(script.Parent.PondStages)

local DockStages = {}

local DOCK_X = -3 -- the pier's line in the pond's frame (AreaUpgrade's DOCK_X)

function DockStages.build(area: Instance, frame: CFrame, level: number): Model
	local stage = PondStages.build(level, frame * CFrame.new(DOCK_X, 0, 0))
	-- where the landmark stands, any tree or bush goes
	local x0, x1, z0, z1 = Boathouse.footprint(level)
	for _, d in (area.Parent or area):GetDescendants() do
		if d:IsA("Model") and d.Parent and d.Parent.Name == "Nature" then
			local p = frame:PointToObjectSpace(d:GetPivot().Position)
			if p.X > x0 and p.X < x1 and p.Z > z0 and p.Z < z1 then
				d.Parent = nil
			end
		end
	end
	Boathouse.build(stage, frame, level)
	return stage
end

return DockStages
