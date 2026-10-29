--!strict
-- The persistent vegetable plot state machine; all mutations are deterministic and usable in Lune.
local Config = if script then require(script.Parent.Config) else require("./Config")

export type Plot = { crop: string, stage: number, progress: number, watered: boolean }
local GardenPlots = {}

function GardenPlots.new(count: number): { Plot }
	local plots: { Plot } = {}
	for _ = 1, count do
		table.insert(plots, { crop = "", stage = 0, progress = 0, watered = false })
	end
	return plots
end

function GardenPlots.repair(raw: any, count: number): { Plot }
	local plots = GardenPlots.new(count)
	if type(raw) ~= "table" then
		return plots
	end
	for index, plot in plots do
		local old = raw[index]
		if type(old) == "table" then
			local crop = if old.crop == "carrot" or old.crop == "cabbage" then old.crop else ""
			local stage = if type(old.stage) == "number" and old.stage == old.stage
				then math.clamp(math.floor(old.stage), -1, 4)
				else 0
			if crop == "" and stage > 0 then
				stage = 0
			elseif crop ~= "" and stage < 1 then
				stage = 1
			end
			plot.crop = crop
			plot.stage = stage
			plot.progress = if crop ~= "" and stage < 4 and type(old.progress) == "number"
				and old.progress == old.progress and old.progress >= 0
				then math.min(old.progress, Config.Work.GardenStageSeconds)
				else 0
			plot.watered = crop ~= "" and old.watered == true
		end
	end
	return plots
end

function GardenPlots.grow(plots: { Plot }, seconds: number)
	for _, plot in plots do
		if plot.crop ~= "" and plot.stage < 4 then
			local speed = if plot.watered then 1 else Config.Work.GardenDryGrowthFactor
			plot.progress += math.max(0, seconds) * speed
			while plot.progress >= Config.Work.GardenStageSeconds and plot.stage < 4 do
				plot.progress -= Config.Work.GardenStageSeconds
				plot.stage += 1
				-- Every new leaf stage asks for another watering, but dry plants still grow.
				plot.watered = false
			end
			if plot.stage == 4 then
				plot.progress = 0
			end
		end
	end
end

function GardenPlots.choose(plots: { Plot }, reserved: { [number]: boolean }?): (number?, string?)
	-- Harvest first to release a ripe plot; tending thirsty shoots has priority over new planting.
	for _, stage in { 4, 1, 2, 3, -1, 0 } do
		for index, plot in plots do
			if plot.stage == stage and (not reserved or not reserved[index]) then
				if stage == 4 then
					return index, "harvest"
				elseif stage == -1 then
					return index, "plant"
				elseif stage == 0 then
					return index, "hoe"
				elseif not plot.watered then
					return index, "water"
				end
			end
		end
	end
	return nil, nil
end

function GardenPlots.apply(plots: { Plot }, index: number, action: string, carrot: boolean): string?
	local plot = plots[index]
	if not plot then
		return nil
	end
	if action == "hoe" and plot.crop == "" and plot.stage == 0 then
		plot.stage = -1
	elseif action == "plant" and plot.crop == "" and plot.stage == -1 then
		plot.crop = if carrot then "carrot" else "cabbage"
		plot.stage = 1
		plot.progress = 0
		plot.watered = false
	elseif action == "water" and plot.crop ~= "" and plot.stage >= 1 and plot.stage < 4 and not plot.watered then
		plot.watered = true
		plot.progress += Config.Work.GardenWaterBoostSeconds
	elseif action == "harvest" and plot.stage == 4 then
		local picked = plot.crop
		plot.crop = ""
		plot.stage = 0
		plot.progress = 0
		plot.watered = false
		return picked
	end
	return nil
end

return GardenPlots
