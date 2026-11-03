--!strict
-- Runs the tutorial and the intros (rules in shared/Guide): once a second it moves each player's step on from the real
-- farm and from where the character stands, saves only when something changed, and publishes what the client draws on the
-- player's village folder (GuideId, GuideKind, GuideLine, GuideTarget, GuideNext; "" when nothing is shown).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GuideRules = require(ReplicatedStorage.Shared.Guide)
local Layout = require(ReplicatedStorage.Shared.Layout)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Village = require(script.Parent.Village)
local ZombieFights = require(script.Parent.ZombieFights)

local Guide = {}

local function set(inst: Instance, name: string, value: any)
	if inst:GetAttribute(name) ~= value then
		inst:SetAttribute(name, value)
	end
end

-- Home and the Market are each a rim slot of the valley: the character is "there" within that share of a plot's side of
-- the slot's centre (quick travel lands at the Market's edge, well away from the buyer).
local function envOf(player: Player): GuideRules.Env
	local reach = Config.Map.PlotSize * Config.Guide.HomeShare
	local plot = Plots.of(player)
	return {
		atMarket = ZombieFights.near(player, Layout.marketFrame().Position, reach),
		atHome = plot ~= nil and ZombieFights.near(player, Layout.plotFrame(plot).Position, reach),
	}
end

-- Moves the player's step on if the farm allows it, then publishes it. Safe to call at any time.
function Guide.refresh(player: Player)
	local root = Village.rootOf(player)
	local farm = PlayerData.get(player)
	if not root or not farm or not PlayerData.isReady(player) then
		return
	end
	local now = os.time()
	local env = envOf(player)
	if GuideRules.pending(farm, now, env) then
		local before = farm.guide.step
		PlayerData.update(player, function(live: any)
			GuideRules.update(live, now, env)
		end)
		farm = PlayerData.get(player)
		if not farm then
			return
		end
		if farm.guide.step ~= before then
			print(Config.LogPrefix, "guide:", player.Name, before, "->", farm.guide.step)
			if farm.guide.step == GuideRules.Done then
				PlayerData.markKeyMoment(player, "tutorial")
			end
		end
	end
	local view = GuideRules.view(farm, now)
	set(root, "GuideId", if view then view.id else "")
	set(root, "GuideKind", if view then view.kind else "")
	set(root, "GuideLine", if view then view.line else "")
	set(root, "GuideTarget", if view then view.target else "")
	set(root, "GuideNext", if view then view.next else false)
end

function Guide.start()
	task.spawn(function()
		while true do
			task.wait(Config.Guide.CheckSeconds)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function(): any
					Guide.refresh(player)
					return nil
				end)
				if not ok then
					warn(Config.LogPrefix, "guide failed for", player.Name, err)
				end
			end
		end
	end)
end

return Guide
