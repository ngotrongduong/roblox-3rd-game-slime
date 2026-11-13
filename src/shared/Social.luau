--!strict
-- The community rewards (the owner, 2026-11-14): favorite the game and join the owner's Roblox group, each paid once per
-- player with a big gift. The last step of the tutorial (shared/Guide "social") points at them; later they wait on their
-- own tab of the rewards sheet (client/UiRewards).
--
-- Roblox's own prompts run on the client (AvatarEditorService:PromptSetFavorite, GroupService:PromptJoinAsync). The group
-- is checked again on the server (server/VillageRemotes asks Roblox whether the player is in Config.Social.GroupId) and
-- comes in here as `confirmed`. A favorite cannot be read by a server at all: the client's word is taken, once, so the most a
-- lying client gets is the one gift an honest player gets too. Group id 0 means no group yet: its reward is not offered.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Rewards = if script then require(script.Parent.Rewards) else require("./Rewards")

type Farm = typeof(FarmState.newFarm(0))

local S = Config.Social

local Social = {}

-- The kinds, in the order they are shown.
Social.Kinds = { "favorite", "group" }

local function specOf(kind: string): any
	return if kind == "favorite" then S.Favorite elseif kind == "group" then S.Group else nil
end

-- Whether this kind is offered at all (the group only once its id is set).
function Social.offered(kind: string): boolean
	if kind == "favorite" then
		return true
	elseif kind == "group" then
		return S.GroupId > 0
	end
	return false
end

function Social.taken(farm: Farm, kind: string): boolean
	return (farm.rewards.social :: any)[kind] == true
end

-- How many offered rewards are not taken yet.
function Social.waiting(farm: Farm): number
	local count = 0
	for _, kind in Social.Kinds do
		if Social.offered(kind) and not Social.taken(farm, kind) then
			count += 1
		end
	end
	return count
end

-- Pays the reward of `kind` once. `confirmed`: the server saw the player in the group, or the client said the favorite was
-- set. (ok, reason?, coins?): "NO_KIND", "NOT_OFFERED" (no group id yet), "TAKEN", "NOT_DONE".
function Social.claim(farm: Farm, kind: string, confirmed: boolean, now: number): (boolean, string?, number?)
	local spec = specOf(kind)
	if not spec then
		return false, "NO_KIND"
	elseif not Social.offered(kind) then
		return false, "NOT_OFFERED"
	elseif Social.taken(farm, kind) then
		return false, "TAKEN"
	elseif not confirmed then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant(spec, farm)
	local _, coins = Rewards.pay(farm, grant, now)
	local taken: any = farm.rewards.social
	taken[kind] = true
	return true, nil, coins
end

-- What the client draws: one row an offered kind, { kind, taken, coins, luck, spins, items } (the coins with the boosts on).
function Social.view(farm: Farm, now: number): { { any } }
	local rows: { { any } } = {}
	for _, kind in Social.Kinds do
		if Social.offered(kind) then
			local grant = Rewards.shown(specOf(kind), farm, now)
			local row: { any } =
				{ kind, Social.taken(farm, kind), grant.coins, grant.luck, grant.spins or 0, grant.items or {} }
			table.insert(rows, row)
		end
	end
	return rows
end

return Social
