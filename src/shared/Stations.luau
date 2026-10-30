--!strict
-- Shared work-slot ownership and shift eligibility. No service or world state is consulted.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Farm = typeof(FarmState.newFarm(0))
type Slot = typeof(FarmState.newFarm(0).work.fishing.slots[1])
type Slime = typeof(FarmState.newFarm(0).slimes[1])
local Stations = {}

function Stations.slotCount(level: number): number
	return FarmState.slotCount(level)
end

-- A faster slime needs less real time for the same amount of work.
function Stations.speedTimeFactor(speed: number): number
	local bonus = math.min(
		math.max(0, speed - Config.Stats.Starter.speed) * Config.Work.SpeedBonusPerSpd,
		Config.Work.SpeedBonusMax
	)
	return 1 / (1 + bonus)
end

function Stations.cycleSeconds(areaId: string, level: number): number
	local base = (Config.Work.CycleSeconds :: any)[areaId]
	return if base then base * Config.Work.CycleLevelFactor ^ (level - Config.Village.StartLevel) else math.huge
end

function Stations.isBusy(farm: Farm, slimeId: string): boolean
	for _, id in Config.Work.Areas do
		for _, slot in ((farm.work :: any)[id] :: any).slots do
			if slot.worker == slimeId or slot.reserve == slimeId then
				return true
			end
		end
	end
	return false
end

function Stations.canAssign(
	farm: Farm,
	slimeId: string,
	areaId: string,
	slotIndex: number,
	asReserve: boolean,
	now: number
): (boolean, string?)
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime then
		return false, "MISSING_SLIME"
	end
	if
		Growth.isBaby(
			slime.createdAt,
			now,
			Stats.level(slime.stats),
			farm.areas.breeding.level - Config.Village.StartLevel
		)
	then
		return false, "BABY"
	end
	if slime.ghostUntil and slime.ghostUntil > now then
		return false, "GHOST"
	end
	if Stations.isBusy(farm, slimeId) then
		return false, "ALREADY_ASSIGNED"
	end
	for _, pair in farm.breeding.pairs do
		if pair.a == slimeId or pair.b == slimeId then
			return false, "IN_PAIR"
		end
	end
	local area = (farm.work :: any)[areaId]
	if
		not area
		or not table.find(Config.Work.Areas, areaId)
		or type(slotIndex) ~= "number"
		or slotIndex % 1 ~= 0
		or not area.slots[slotIndex]
	then
		return false, "NO_SLOT"
	end
	local slot = area.slots[slotIndex]
	if if asReserve then slot.reserve else slot.worker then
		return false, "SLOT_TAKEN"
	end
	return true, nil
end

function Stations.assign(
	farm: Farm,
	slimeId: string,
	areaId: string,
	slotIndex: number,
	asReserve: boolean,
	now: number
): (boolean, string?)
	local ok, why = Stations.canAssign(farm, slimeId, areaId, slotIndex, asReserve, now)
	if not ok then
		return false, why
	end
	local slot = (farm.work :: any)[areaId].slots[slotIndex]
	if asReserve then
		slot.reserve = slimeId
	else
		slot.worker = slimeId
	end
	-- A training place with no stat chosen would never train (the owner saw no gains): it starts on the trainee's
	-- weakest stat (hp counted per HpPerLevel, as the level formula does); the player can change it any time.
	if areaId == "training" and not slot.stat then
		local slime = FarmState.findSlime(farm, slimeId)
		if slime then
			slot.stat = Stations.weakestStat(slime)
			slot.progress = 0
		end
	end
	return true, nil
end

-- The stat a trainee starts on when none is chosen: its weakest (hp counted per HpPerLevel, as the level formula does).
function Stations.weakestStat(slime: Slime): string
	local best, bestValue = Stats.Keys[1], math.huge
	for _, key in Stats.Keys do
		local value = Stats.get(slime.stats, key)
		if key == "hp" then
			value /= Config.Stats.HpPerLevel
		end
		if value < bestValue then
			best, bestValue = key, value
		end
	end
	return best
end

function Stations.unassign(farm: Farm, areaId: string, slotIndex: number, asReserve: boolean): boolean
	local area = (farm.work :: any)[areaId]
	local slot = if area then area.slots[slotIndex] else nil
	if not slot then
		return false
	end
	if asReserve then
		slot.reserve = nil
	else
		slot.worker = nil
	end
	return true
end

function Stations.setTrainingStat(farm: Farm, slotIndex: number, statKey: string): boolean
	local slot = farm.work.training.slots[slotIndex]
	if not slot or not table.find(Stats.Keys, statKey) then
		return false
	end
	slot.stat = statKey
	slot.progress = 0
	return true
end

local function eligible(farm: Farm, id: string?, now: number): Slime?
	if not id then
		return nil
	end
	local slime = FarmState.findSlime(farm, id)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
		return nil
	end
	if
		Growth.isBaby(
			slime.createdAt,
			now,
			Stats.level(slime.stats),
			farm.areas.breeding.level - Config.Village.StartLevel
		)
	then
		return nil
	end
	if slime.sleeping or Needs.isTired(slime.needs) then
		return nil
	end
	return slime
end

-- The reserve only replaces the worker when the worker cannot sustain its shift.
function Stations.activeWorker(farm: Farm, slot: Slot, now: number): Slime?
	local worker = eligible(farm, slot.worker, now)
	if worker and not Needs.isHungry(worker.needs) then
		return worker
	end
	local reserve = eligible(farm, slot.reserve, now)
	if reserve and not Needs.isHungry(reserve.needs) then
		return reserve
	end
	-- A hungry worker still does half-speed work when no fit reserve is present.
	return worker
end

return Stations
