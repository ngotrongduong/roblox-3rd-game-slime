--!nocheck
-- A play-test probe (`node tools/studio_mcp.js run tools/slime/gait_probe.luau <id> Server`): one line per village slime
-- with its action, gait, needs, leg length in studs, the leg's published time and the time the shared VillagePath says
-- that leg should take for that gait, and where the leg stands now. Reading it twice a few seconds apart shows the
-- slime keeping to its leg times. (Not run yet when it was written: the Studio was in somebody's long play test.)
local RS = game:GetService("ReplicatedStorage")
local VillagePath = require(RS.Shared.VillagePath)
local Gaits = require(RS.Shared.Gaits)
local now = workspace:GetServerTimeNow()
local lines = {}
local folder = workspace:FindFirstChild("Villages")
for _, m in if folder then folder:GetDescendants() else {} do
	if m:IsA("Model") and m:GetAttribute("LegStart") ~= nil then
		local a = function(k)
			return m:GetAttribute(k)
		end
		local from = Vector3.new(a("FromX"), a("FromY"), a("FromZ"))
		local to = Vector3.new(a("ToX"), a("ToY"), a("ToZ"))
		local gait = a("Gait") or "walk"
		local length = (to - from).Magnitude
		local factor = Gaits.factor(a("Speed") or 0)
		local published = a("LegEnd") - a("LegStart")
		table.insert(
			lines,
			("%s %s gait=%s fullness=%s energy=%s baby=%s leg=%.1f studs published=%.2fs expected=%.2fs progress=%.2f"):format(
				tostring(a("Name")),
				tostring(a("Action")),
				gait,
				tostring(a("Fullness")),
				tostring(a("Energy")),
				tostring(a("Baby")),
				length,
				published,
				VillagePath.duration(length, factor, gait),
				(VillagePath.progress(a("LegStart"), a("LegEnd"), now, gait))
			)
		)
	end
end
return table.concat(lines, "\n")
