--!nocheck
-- The LocalScript the review stage runs (tools/slime/emotions.luau puts it, with SlimeFace and SlimeActor next to it,
-- in StarterPlayerScripts.SlimeFaceStage). It gives every slime of Workspace.SlimeEmotions the face rig and its
-- emotion, and turns each slime's eyes (and a curious body) toward the nearest player within range. The code that
-- draws and moves the slimes is the real src/client/SlimeActor + SlimeFace and src/shared/SlimeMotion; this file is
-- only the stage's glue and is not part of the game.
local Players = game:GetService("Players")

local stage = workspace:WaitForChild("SlimeEmotions", 10)
if not stage then
	return
end
local Actor = require(script.Parent.SlimeActor)

local RANGE = 70
local actors = {}
for _, m in stage:GetChildren() do
	local emotion = m:IsA("Model") and m:GetAttribute("Emotion")
	if emotion then
		local a = Actor.new(m, emotion)
		if a then
			actors[m] = a
		end
	end
end
print("[GooLineage] emotion stage:", #stage:GetChildren(), "slimes")

task.spawn(function()
	while stage.Parent do
		local heads = {}
		for _, p in Players:GetPlayers() do
			local head = p.Character and p.Character:FindFirstChild("Head")
			if head then
				table.insert(heads, head)
			end
		end
		for m, a in actors do
			local from = m:GetPivot().Position
			local best, bestD = nil, RANGE
			for _, h in heads do
				local d = (h.Position - from).Magnitude
				if d < bestD then
					best, bestD = h, d
				end
			end
			a:lookAt(best)
		end
		task.wait(0.2)
	end
end)
