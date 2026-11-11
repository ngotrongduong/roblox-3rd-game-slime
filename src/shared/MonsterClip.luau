--!strict
-- How a Slime Dungeon monster slime moves (docs/MONSTER-SLIMES.md): its five actions (Idle, Move, Attack, Hit, Die) were
-- made in Blender (tools/blender/monster_rig.py) and sampled frame by frame into Shared.MonsterClips.<Name>
-- (tools/blender/monster_clips.py). Each bone's move is from its rest, in the model's own axes (+Y up, front -Z): a
-- position in studs at the model's built height and a turn as axis times angle (radians). Pure: the client (ClipRig)
-- steps a player every frame and writes the moves into Bone.Transform. Idle and Move loop and are picked by whether the
-- monster walks; Attack, Hit and Die are played once when the fight says so (Die holds its last frame); every switch
-- blends over Fade seconds.
local MonsterClip = {}

export type Action = { length: number, loop: boolean, frames: number, ranges: { number }, data: string }
-- `centre` the mesh's middle and `rest` each bone's rest point ({ name, parent, x, y, z }, parents first), built studs
export type Data = {
	height: number,
	hover: number,
	peak: number,
	centre: { number },
	rest: { { any } },
	bones: { string },
	actions: { [string]: Action },
}
-- one action unpacked: per bone six channels (position x, y, z, turn x, y, z), each a list of samples or one number
export type Clip = { length: number, loop: boolean, frames: number, tracks: { any } }
export type Set = { data: Data, clips: { [string]: Clip }, bones: { string } }
export type Player = {
	set: Set,
	action: string,
	started: number,
	from: string?,
	fromStarted: number,
	fadeStarted: number,
	still: number,
	seed: number,
	pose: { number },
}

-- seconds a change of action blends over
MonsterClip.Fade = 0.15
-- a monster keeps walking this long after its last step (a pause between two hops is no stop)
MonsterClip.StillSeconds = 0.25
-- the actions played once, and which outranks which (a blow lands during a hit, nothing interrupts dying)
MonsterClip.Rank = { Attack = 1, Hit = 2, Die = 3 }
MonsterClip.Actions = { "Idle", "Move", "Attack", "Hit", "Die" }

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local STEPS = 4095
local VALUE: { [number]: number } = {}
for i = 1, #ALPHABET do
	VALUE[string.byte(ALPHABET, i)] = i - 1
end

local function unpackAction(action: Action): Clip
	local tracks: { any } = {}
	local at = 1
	local data = action.data
	for channel = 1, #action.ranges // 2 do
		local low, span = action.ranges[2 * channel - 1], action.ranges[2 * channel]
		if span == 0 then
			tracks[channel] = low
		else
			local list = table.create(action.frames)
			for frame = 1, action.frames do
				local high, small = string.byte(data, at, at + 1)
				list[frame] = low + span * (VALUE[high] * 64 + VALUE[small]) / STEPS
				at += 2
			end
			tracks[channel] = list
		end
	end
	assert(at == #data + 1, "the samples do not fill the clip")
	return { length = action.length, loop = action.loop, frames = action.frames, tracks = tracks }
end

local sets: { [Data]: Set } = {}

-- A monster's actions, unpacked once however many of it fight.
function MonsterClip.set(data: Data): Set
	local cached = sets[data]
	if cached then
		return cached
	end
	local clips = {}
	for name, action in data.actions do
		clips[name] = unpackAction(action)
	end
	local set = { data = data, clips = clips, bones = data.bones }
	sets[data] = set
	return set
end

-- Adds `weight` times the clip's moves `t` seconds into it to `out`: a loop wraps round, a one-off holds its ends.
local function add(clip: Clip, t: number, weight: number, out: { number })
	local length = clip.length
	local u = if clip.loop then t % length else math.clamp(t, 0, length)
	local at = u / length * (clip.frames - 1)
	local i = math.min(math.floor(at), clip.frames - 2)
	local w = at - i
	for channel, track in clip.tracks do
		if type(track) == "number" then
			out[channel] += track * weight
		else
			local a = track[i + 1]
			out[channel] += (a + (track[i + 2] - a) * w) * weight
		end
	end
end

-- The moves of a clip `t` seconds into it (a list of six numbers a bone).
function MonsterClip.sample(set: Set, action: string, t: number): { number }
	local out = table.create(6 * #set.bones, 0)
	add(set.clips[action], t, 1, out)
	return out
end

-- A player of one monster; `seed` 0..1 sets its loops apart from the others'.
function MonsterClip.new(set: Set, seed: number, now: number): Player
	return {
		set = set,
		action = "Idle",
		started = now - seed * set.clips.Idle.length,
		from = nil,
		fromStarted = 0,
		fadeStarted = -math.huge,
		still = math.huge,
		seed = seed,
		pose = table.create(6 * #set.bones, 0),
	}
end

local function switch(p: Player, action: string, started: number, now: number)
	p.from, p.fromStarted, p.fadeStarted = p.action, p.started, now
	p.action, p.started = action, started
end

-- Plays an action once, `into` seconds into it; its length (0 when the monster has no such action or is busy with a
-- higher one).
function MonsterClip.play(p: Player, action: string, now: number, into: number): number
	local clips = p.set.clips
	local clip = clips[action]
	local rank: { [string]: number } = MonsterClip.Rank :: any
	if not clip or not rank[action] or p.action == "Die" then
		return 0
	end
	local busy = rank[p.action]
	if busy and busy > rank[action] and now - p.started < clips[p.action].length then
		return 0
	end
	switch(p, action, now - into, now)
	return clip.length
end

-- One frame: `moving` says whether the monster stepped this frame. Returns the moves (six numbers a bone).
function MonsterClip.step(p: Player, now: number, dt: number, moving: boolean): { number }
	local clips = p.set.clips
	p.still = if moving then 0 else p.still + dt
	local base = if p.still < MonsterClip.StillSeconds then "Move" else "Idle"
	-- (a walk starts on its first hop; the idle picks up its own breath)
	local baseStart = if base == "Move" then now else now - p.seed * clips.Idle.length
	if p.action == "Idle" or p.action == "Move" then
		if p.action ~= base then
			switch(p, base, baseStart, now)
		end
	elseif p.action ~= "Die" and now - p.started >= clips[p.action].length then
		switch(p, base, baseStart, now)
	end
	local pose = p.pose
	for i = 1, 6 * #p.set.bones do
		pose[i] = 0
	end
	local w = math.clamp((now - p.fadeStarted) / MonsterClip.Fade, 0, 1)
	local from = p.from
	if from and w < 1 then
		add(clips[from], now - p.fromStarted, 1 - w, pose)
		add(clips[p.action], now - p.started, w, pose)
	else
		add(clips[p.action], now - p.started, 1, pose)
	end
	return pose
end

return MonsterClip
