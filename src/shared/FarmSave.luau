--!strict
-- The profile hooks for the farm: what a new player gets and how a stored farm is repaired.
-- A stored farm that repair can only replace with a fresh one is a FAILED load (the error makes
-- ProfileLogic fall back to the last-good copy, or leave the save untouched and kick): a fresh farm
-- must never be written over a save that exists. That was the owner's worst experience of the web
-- game (docs/reference/05-owner-history-part1.md §3, "Saves & data loss").

local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")

local ProfileLogic = if script then require(script.Parent.ProfileLogic) else require("./ProfileLogic")

local FarmSave = {}

-- The hooks ProfileLogic.Hooks describes (its exported types cannot be read through the dual
-- require). log receives one line per repaired load (never for a clean farm).
function FarmSave.hooks(log: ((string) -> ())?)
	return {
		schemaVersion = Config.Save.SchemaVersion,
		-- One entry per shape change: { from = n, to = n + 1, migrate = function(data, now) ... }.
		migrations = {
			-- 1 -> 2: the collection book gained a material bucket. Repair would also add it; this
			-- keeps the stored version honest. Nothing else is touched.
			{
				from = 1,
				to = 2,
				migrate = function(data: any, _now: number): any
					if
						type(data) == "table"
						and type(data.discoveries) == "table"
						and data.discoveries.material == nil
					then
						local out = table.clone(data)
						out.discoveries = table.clone(data.discoveries)
						out.discoveries.material = {}
						return out
					end
					return data
				end,
			},
			{ from = 2, to = 3, migrate = ProfileLogic.migrateInheritance },
			{ from = 3, to = 4, migrate = ProfileLogic.migrateVillage },
			{ from = 4, to = 5, migrate = ProfileLogic.migrateGarden },
		},
		newData = function(now: number): any
			return FarmState.newFarm(now)
		end,
		repair = function(data: any, now: number): any
			local farm, warnings, replaced = FarmState.repair(data, now)
			if replaced then
				error("stored farm unusable: " .. table.concat(warnings, "; "))
			end
			if log and #warnings > 0 then
				log(Config.LogPrefix .. " farm repaired: " .. table.concat(warnings, "; "))
			end
			return farm
		end,
	}
end

return FarmSave
