local Expressions = require("../../src/shared/Expressions")
local FaceArt = require("../../src/shared/FaceArt")
local SlimeMotion = require("../../src/shared/SlimeMotion")

local MOUTH_ANIMS = { chew = true, talk = true, laugh = true, yawn = true, quiver = true }

return function(T)
	local function spriteOk(name)
		local s = FaceArt.Sprites[name]
		return s ~= nil and s.id > 0 and s.w > 0 and s.h > 0
	end

	T.test("there are about twenty-four emotions and the review order lists each once", function()
		T.ok(#Expressions.List >= 20, "at least twenty")
		T.eq(#Expressions.Order, #Expressions.List)
		local seen = {}
		for _, id in Expressions.Order do
			T.ok(Expressions.get(id) ~= nil, "unknown " .. id)
			T.ok(not seen[id], "twice: " .. id)
			seen[id] = true
		end
	end)

	T.test("the owner's nine are all there", function()
		for _, id in Expressions.Owners do
			T.ok(Expressions.get(id) ~= nil, id)
		end
	end)

	T.test("every picture an emotion names exists, uploaded", function()
		for _, e in Expressions.List do
			for _, name in { e.eyeL, e.eyeR, e.mouth, e.mouthAlt, e.icon } do
				T.ok(spriteOk(name), e.id .. ": " .. tostring(name))
			end
			if e.lid then
				for _, side in { "L", "R" } do
					T.ok(spriteOk("lid1_" .. side) and spriteOk("lid4_" .. side), "lids")
				end
			end
			if e.browL or e.browR then
				T.ok(spriteOk("brow_L") and spriteOk("brow_R"), e.id .. " brows")
			end
		end
		for _, name in { "blush", "sweat", "tear_drop" } do
			T.ok(spriteOk(name), name)
		end
	end)

	T.test("every emotion's body motion exists and its numbers are in range", function()
		local motions = {}
		for _, m in SlimeMotion.Motions do
			motions[m] = true
		end
		for _, e in Expressions.List do
			T.ok(motions[e.motion], e.id .. " motion " .. e.motion)
			T.ok(e.gaze >= 0 and e.gaze <= 1, e.id .. " gaze")
			T.ok(e.blink >= 0 and e.blink <= 2, e.id .. " blink")
			T.ok(e.mouthAnim == nil or MOUTH_ANIMS[e.mouthAnim], e.id .. " mouth anim")
			T.ok(e.lid == nil or (e.lid >= 0 and e.lid <= 4), e.id .. " lid")
			T.ok(e.mouthAnim ~= "chew" or e.mouthAlt ~= nil, e.id .. " chews into something")
		end
	end)

	T.test("the owner's pieces are marked as his and the drawn ones as drawn", function()
		for name, s in FaceArt.Sprites do
			T.ok(s.source == "owner" or s.source == "drawn", name)
		end
		T.eq(FaceArt.Sprites.normal_eyeL.source, "owner")
		T.eq(FaceArt.Sprites.swirl_L.source, "drawn")
	end)
end
