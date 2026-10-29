--!strict
-- Which gait a slime walks a leg in (the owner's choice from the movement lab, docs/GAMEPLAY.md 10.1) and the speed
-- stat's factor. Pure, so Lune tests it; VillagePath times a leg from the gait, SlimeActor plays it.
local Config = if script then require(script.Parent.Config) else require("./Config")

local Gaits = {}

export type Info = {
	kind: string, -- the action's kind (Brain)
	emotion: string, -- the action's emotion
	baby: boolean,
	tired: boolean, -- Needs.isTired
	hungry: boolean, -- Needs.isHungry
}

-- Only a pair courting in the breeding area strolls (the owner, 2026-10-29: "the strolling pace is only inside the
-- breeding area, not outside"); everywhere else, sightseeing included, slimes walk at the normal pace.
local STROLL: { [string]: boolean } = {
	court = true,
}
-- A baby that hurries: following an adult on a walk, or playing.
local BABY_QUICK: { [string]: boolean } = { walkBaby = true, playBaby = true }
-- The sad feelings that fit a glide.
local SAD: { [string]: boolean } = { sad = true, sulking = true, crying = true, bored = true }

function Gaits.choose(info: Info): string
	if info.baby then
		return if BABY_QUICK[info.kind] then "babyQuick" else "baby"
	end
	if info.tired or info.hungry or SAD[info.emotion] then
		return "glide"
	end
	if STROLL[info.kind] then
		return "stroll"
	end
	return "walk"
end

-- The numbers of a gait by name (an unknown name walks).
function Gaits.get(name: string?): any
	local gaits = Config.Gaits :: any
	return gaits[name or "walk"] or gaits.walk
end

function Gaits.isGlide(name: string?): boolean
	return Gaits.get(name).GlideSpeed ~= nil
end

-- The speed stat's effect: every gait's hop distance or glide speed is multiplied by this.
function Gaits.factor(speedStat: number): number
	return 1 + (speedStat - Config.Stats.Starter.speed) * Config.Village.WalkPerSpeed
end

return Gaits
