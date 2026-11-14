--!strict
-- The teams as the server publishes them (Teams/<n> under workspace.Villages.<userId>, src/server/ZombieFights.luau), read in
-- one place for the screens (UiTeams, UiSquad), the march (ZombieMarch) and the fight (ZombieFight). Reads only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local VillagePath = require(ReplicatedStorage.Shared.VillagePath)

export type Team = {
	index: number,
	node: Configuration,
	state: string,
	target: string,
	repeatOn: boolean,
	waiting: string,
	-- the saved line-up, and who went on this trip
	members: { string },
	marching: { string },
	-- the row each member starts a fight in (parallel to `members`) and the team's tactic (Config.Classes.Rows, Tactics)
	rows: { string },
	tactic: string,
	-- the published leg: flat studs (y is 0) and server times
	from: Vector3,
	to: Vector3,
	legStart: number,
	legEnd: number,
}

local ZombieTeams = {}

local function text(inst: Instance, name: string): string
	local value = inst:GetAttribute(name)
	return if type(value) == "string" then value else ""
end

local function number(inst: Instance, name: string): number
	local value = inst:GetAttribute(name)
	return if type(value) == "number" and value == value then value else 0
end

-- "a,b,c" -> { "a", "b", "c" }
function ZombieTeams.split(list: string): { string }
	local found: { string } = {}
	for id in string.gmatch(list, "[^,]+") do
		table.insert(found, id)
	end
	return found
end

-- The village folder of a player (by UserId), nil while it is not there.
function ZombieTeams.rootOf(userId: number): Folder?
	local villages = workspace:FindFirstChild("Villages")
	local found = if villages then villages:FindFirstChild(tostring(userId)) else nil
	return if found and found:IsA("Folder") then found else nil
end

-- The player's own village folder, nil while it is not there.
function ZombieTeams.root(): Folder?
	return ZombieTeams.rootOf(Players.LocalPlayer.UserId)
end

-- The plot this player holds (the Plot attribute of their village folder), nil until the server has handed it out.
function ZombieTeams.plot(): number?
	local root = ZombieTeams.root()
	local plot = if root then root:GetAttribute("Plot") else nil
	return if type(plot) == "number" and plot >= 1 then plot else nil
end

-- The level this player's slice is filled by (published as PlayerLevel); the group markers are coloured by it.
function ZombieTeams.level(): number
	local root = ZombieTeams.root()
	local level = if root then root:GetAttribute("PlayerLevel") else nil
	return if type(level) == "number" then level else 0
end

-- How many teams the Extra Team passes add on top of the village's own (the Player attribute ExtraTeams the server publishes;
-- Zombies.teamsOpen takes it as its second argument).
function ZombieTeams.extra(): number
	local value = Players.LocalPlayer:GetAttribute("ExtraTeams")
	return if type(value) == "number" then math.max(0, math.floor(value)) else 0
end

-- One team of a village: the player's own unless another village folder is given.
function ZombieTeams.get(index: number, village: Folder?): Team?
	local root = village or ZombieTeams.root()
	local folder = if root then root:FindFirstChild("Teams") else nil
	local node = if folder then folder:FindFirstChild(tostring(index)) else nil
	if not node or not node:IsA("Configuration") then
		return nil
	end
	return {
		index = index,
		node = node,
		state = if text(node, "State") ~= "" then text(node, "State") else "home",
		target = text(node, "Target"),
		repeatOn = node:GetAttribute("Repeat") == true,
		waiting = text(node, "Waiting"),
		members = ZombieTeams.split(text(node, "Members")),
		marching = ZombieTeams.split(text(node, "Marching")),
		rows = ZombieTeams.split(text(node, "Rows")),
		tactic = if text(node, "Tactic") ~= "" then text(node, "Tactic") else Config.Classes.Tactics.Order[1],
		from = Vector3.new(number(node, "FromX"), 0, number(node, "FromZ")),
		to = Vector3.new(number(node, "ToX"), 0, number(node, "ToZ")),
		legStart = number(node, "LegStart"),
		legEnd = number(node, "LegEnd"),
	}
end

-- Every team that is published, by its number (a team not published yet leaves a gap: iterate, never count).
function ZombieTeams.all(village: Folder?): { Team }
	local found: { Team } = {}
	for index = 1, Config.Zombies.Teams do
		found[index] = ZombieTeams.get(index, village) :: Team
	end
	return found
end

-- The number of the team whose saved line-up holds this slime.
function ZombieTeams.teamOf(slimeId: string, teams: { Team }): number?
	for _, team in teams do
		if table.find(team.members, slimeId) then
			return team.index
		end
	end
	return nil
end

-- How far along its leg a marching team is (0 to 1), by the village's own hop timing.
function ZombieTeams.progress(team: Team, now: number): number
	if team.state == "fighting" then
		return 1
	elseif team.state ~= "going" and team.state ~= "returning" then
		return 0
	end
	return (VillagePath.progress(team.legStart, team.legEnd, now, Config.Zombies.MarchGait))
end

-- Where a marching team is now (flat, y 0), nil at home.
function ZombieTeams.position(team: Team, now: number): Vector3?
	if team.state == "home" then
		return nil
	elseif team.state == "fighting" then
		return team.to
	end
	return team.from:Lerp(team.to, ZombieTeams.progress(team, now))
end

return ZombieTeams
