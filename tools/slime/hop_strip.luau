--!nocheck
-- One call of tools/slime/hop_strip.ps1 (Edit mode): FRAMES is "0" to calm the "exciting" slime of the emotion stage
-- and start one hop of 0.4 body heights, or a number of 1/60 s steps of the real SlimeActor to take it on by hand.
local SPS = game:GetService("StarterPlayer").StarterPlayerScripts
local Actor = require(SPS.SlimeFaceStage.SlimeActor)
local a = Actor.of(workspace.SlimeEmotions.exciting)
if not a then
	return "no actor: build the stage first"
end
local n = tonumber(FRAMES)
if n == 0 then
	a:playMotion("idle")
	for _ = 1, 90 do
		Actor.stepAll(1 / 60, true)
	end
	a:hop(0.4)
	return "hop started"
end
for _ = 1, n do
	Actor.stepAll(1 / 60, true)
end
return "stepped " .. n
