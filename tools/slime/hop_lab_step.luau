--!nocheck
-- One call of tools/slime/hop_lab_shoot.ps1 (Edit mode): steps the movement lab by FRAMES steps of 1/60 s by hand.
local SPS = game:GetService("StarterPlayer").StarterPlayerScripts
local Lab = require(SPS.SlimeMotionLab.LabRun)
if #Lab.lanes == 0 then
	return "no lab: build it first (tools/slime/hop_lab.ps1)"
end
local n = tonumber(FRAMES)
for _ = 1, n do
	Lab.step(1 / 60)
end
local out = {}
for _, L in Lab.lanes do
	table.insert(out, ("%s s=%.1f y=%.2f %s"):format(L.spec.key, L.s, L.y, L.mode))
end
return table.concat(out, " | ")
