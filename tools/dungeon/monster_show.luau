-- Play test, Client datamodel: a showroom of the 28 monster slimes for the owner. One region at a time (Meadow, Grove,
-- Lava, Ice; Config.Dungeon.Maps order) stands on a plain stage high above the farm, side by side with room to move,
-- each with its name above it and the camera held in front of the row. A region plays its moves twice (stand, walk
-- forward, attack, take a hit, walk back), then they all fall (Die) and the next region comes, round and round. With
-- `_G.MonsterShowOnly = "<map id>"` set first (in the same datamodel) only that region is shown; `_G.MonsterShow.clear()`
-- takes it all away and gives the camera back, `_G.MonsterShow.focus("<monster id>")` looks at one up close (nil: all).
-- `_G.MonsterShow.special("<monster id>", "<special key>", [freeze at])` plays that special's art as the fight does
-- (Config.Dungeon.Fx.Monsters): its wind-up on the monster, then its release on it or on a spot in front of it, seen
-- from the side; given a time, every particle stops then for a picture (before 1.2 s: the wind-up alone), and
-- `_G.MonsterShow.thaw()` lets them go on.
--   node tools/studio_mcp.js run tools/dungeon/monster_show.luau <studio_id> Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local ClipRig = require(client:WaitForChild("ClipRig"))
local MonsterLook = require(client:WaitForChild("MonsterLook"))
local SlimeActor = require(client:WaitForChild("SlimeActor"))
local Config = require(ReplicatedStorage.Shared.Config)
local D = Config.Dungeon

local GAP = 6 -- studs between two monsters
local STEP = 5 -- how far they walk towards the camera

if _G.MonsterShow then
	_G.MonsterShow.clear()
end
if _G.MonsterLineup then
	_G.MonsterLineup.clear()
end

local character = Players.LocalPlayer.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
if not root then
	return "no character"
end
local centre = Vector3.new(root.Position.X, root.Position.Y + 250, root.Position.Z)
local regions = if _G.MonsterShowOnly then { _G.MonsterShowOnly } else { "meadow", "mushroom", "lava", "ice" }
local ids = {}
for _, mapId in regions do
	for _, entry in D.Maps[mapId].monsters do
		table.insert(ids, (entry :: any).id)
	end
end
MonsterLook.prepare(ids)
-- (their meshes load from Roblox the first time: wait for them, up to 20 seconds, so no stand-in shows)
for _ = 1, 40 do
	local missing = 0
	for _, id in ids do
		local spec = (D.Looks :: any)[id]
		local part = if spec and spec.clips then ClipRig.mesh(spec) else nil
		if part then
			part:Destroy()
		elseif spec and spec.clips then
			missing += 1
		end
	end
	if missing == 0 then
		break
	end
	task.wait(0.5)
end

local folder = Instance.new("Folder")
folder.Name = "MonsterShow"
folder.Parent = workspace
local stage = Instance.new("Part")
stage.Name = "Stage"
stage.Anchored = true
stage.Size = Vector3.new(220, 2, 90)
stage.CFrame = CFrame.new(centre - Vector3.new(0, 1, 0))
stage.Color = Color3.fromRGB(126, 196, 92)
stage.Material = Enum.Material.Plastic
stage.TopSurface = Enum.SurfaceType.Studs
stage.Parent = folder

local gui = Instance.new("ScreenGui")
gui.Name = "MonsterShow"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0, 140)
title.Size = UDim2.fromOffset(600, 48)
title.BackgroundTransparency = 1
title.Font = Enum.Font.FredokaOne
title.TextSize = 40
title.TextColor3 = Color3.new(1, 1, 1)
title.TextStrokeTransparency = 0.3
title.Parent = gui

local camera = workspace.CurrentCamera
local view: CFrame? = nil
local alive = true
local actors = {}
local row = Instance.new("Folder")
row.Parent = folder

local function clearRow()
	for _, a in actors do
		SlimeActor.destroy(a.actor)
	end
	table.clear(actors)
	row:ClearAllChildren()
end

-- The region's monsters facing the camera, each as wide as its mesh: the five small ones in front, the miniboss and
-- the boss behind them; the camera above and far enough back to see both rows whole.
local function buildRow(mapId: string)
	local rows = { { looks = {}, width = 0, depth = 0 }, { looks = {}, width = 0, depth = 0 } }
	local tallest = 0
	for _, entry in D.Maps[mapId].monsters do
		local def: any = entry
		local look = MonsterLook.build({ defId = def.id, kind = def.kind, role = def.role, name = def.name })
		local part = look.creature and look.creature.parts[1]
		local size = if part then math.max(part.Size.X, part.Size.Z) else 6
		local r = rows[if (D.Looks :: any)[def.id].shadow then 2 else 1]
		table.insert(r.looks, { look = look, def = def, part = part, width = size })
		r.width += size + (if #r.looks > 1 then GAP else 0)
		r.depth = math.max(r.depth, size)
		tallest = math.max(tallest, if look.creature then look.creature.top else 5)
	end
	local z = { 0, -(rows[1].depth / 2 + GAP + rows[2].depth / 2) }
	for i, r in rows do
		local x = -r.width / 2
		for _, l in r.looks do
			local spot = centre + Vector3.new(x + l.width / 2, 0, z[i])
			x += l.width + GAP
			l.look.model.Name = "Show_" .. l.def.id
			l.look.model:PivotTo(CFrame.lookAt(spot, spot + Vector3.zAxis))
			l.look.model.Parent = row
			local actor = SlimeActor.new(l.look.model, l.look.face)
			if actor then
				if l.look.creature then
					SlimeActor.dress(actor, l.look.creature)
				end
				-- (it turns back to the camera whenever it stands)
				SlimeActor.face(actor, spot + Vector3.zAxis * 100)
				table.insert(actors, {
					actor = actor,
					spot = spot,
					id = l.def.id,
					role = l.def.role,
					top = if l.part then l.part.Size.Y else 5,
				})
			end
			if l.part then
				local tag = Instance.new("BillboardGui")
				tag.Size = UDim2.fromOffset(220, 34)
				tag.StudsOffsetWorldSpace = Vector3.new(0, l.part.Size.Y / 2 + 1.5, 0)
				tag.AlwaysOnTop = true
				local name = Instance.new("TextLabel")
				name.Size = UDim2.fromScale(1, 1)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.FredokaOne
				name.TextSize = 24
				name.TextColor3 = Color3.new(1, 1, 1)
				name.TextStrokeTransparency = 0.3
				name.Text = l.def.name
				name.Parent = tag
				tag.Parent = l.part
			end
		end
	end
	title.Text = D.Maps[mapId].name
	-- (the stage takes the map's own floor colour: effects judged on a green stage read wrong on the Ice map's white one)
	local arena = (D.Arenas :: any)[mapId]
	stage.Color = if arena and arena.FloorColour then Color3.fromHex(arena.FloorColour) else Color3.fromRGB(126, 196, 92)
	local aspect = camera.ViewportSize.X / math.max(camera.ViewportSize.Y, 1)
	camera.FieldOfView = 50
	local halfWide = math.atan(math.tan(math.rad(25)) * aspect)
	local wide = math.max(rows[1].width, rows[2].width)
	local back = math.max((wide / 2 + 8) / math.tan(halfWide), 30)
	local aim = centre + Vector3.new(0, tallest * 0.3, (z[2] + STEP) / 2)
	view = CFrame.lookAt(aim + Vector3.new(0, back * 0.5, back), aim)
end

-- (held every frame: the player's camera takes itself back otherwise; `_G.MonsterShow.focus(id)` holds it close in
-- front of that one monster, above its walk, while its region is shown)
local focusId: string? = nil
local specialView: CFrame? = nil -- set by `special`: from the side, the monster and the spot in front of it both in view
RunService:BindToRenderStep("MonsterShow", Enum.RenderPriority.Camera.Value + 1, function()
	local held = specialView or view
	for _, a in actors do
		if a.id == focusId then
			local aim = a.spot + Vector3.new(0, a.top * 0.55, STEP / 2)
			local back = math.max(a.top * 2.2, 9)
			held = CFrame.lookAt(aim + Vector3.new(0, back * 0.35, back), aim)
		end
	end
	if held then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = held
	end
end)

local function walk(a, from: Vector3, to: Vector3, seconds: number)
	local now = workspace:GetServerTimeNow()
	SlimeActor.setTravel(a.actor, from, to, now, now + seconds, false, "walk")
end

task.spawn(function()
	while alive do
		for _, mapId in regions do
			clearRow()
			buildRow(mapId)
			task.wait(4)
			for _ = 1, 2 do
				for _, a in actors do
					walk(a, a.spot, a.spot + Vector3.zAxis * STEP, 2)
				end
				task.wait(3)
				for _, a in actors do
					SlimeActor.act(a.actor, "Attack")
				end
				task.wait(2)
				for _, a in actors do
					SlimeActor.act(a.actor, "Hit")
				end
				task.wait(2)
				for _, a in actors do
					walk(a, a.spot + Vector3.zAxis * STEP, a.spot, 2)
				end
				task.wait(4)
			end
			for _, a in actors do
				SlimeActor.act(a.actor, "Die")
			end
			task.wait(4)
			if not alive then
				return
			end
		end
	end
end)

local VfxLib = require(ReplicatedStorage.Shared.VfxLib)
local TARGET = 8 -- studs in front of the monster where a special aimed at a target lands
local frozen: { [ParticleEmitter]: number } = {}

_G.MonsterShow = {
	focus = function(id: string?)
		focusId = id
		specialView = nil
	end,
	-- (`freezeAt`: that many seconds in, every particle stops where it is, for a picture; `thaw` lets them go on)
	special = function(id: string, key: string, freezeAt: number?): string
		local art = D.Fx.Monsters[id] and D.Fx.Monsters[id].skills and D.Fx.Monsters[id].skills[key]
		if not art then
			return "no art for " .. id .. " " .. key
		end
		for _, a in actors do
			if a.id == id then
				local model = (a.actor :: any).model
				-- (as big as in a fight: client/ZombieFight's fxScale of MonsterLook's size)
				local sizes = D.StandIn.Sizes :: any
				local scale = math.clamp((sizes[a.role] or sizes.normal) / sizes.normal * D.Fx.Scale, 1, D.Fx.MaxScale)
				local mid = a.spot + Vector3.new(0, a.top * 0.45, TARGET / 2)
				local back = math.max(a.top * 3, 26)
				focusId = nil
				specialView = CFrame.lookAt(mid + Vector3.new(back * 0.75, back * 0.45, back * 0.55), mid)
				local charge = if art.windup
					then VfxLib.play(art.windup, model, { follow = true, variant = art.variant, scale = scale })
					else nil
				-- (a boss's burst, as client/ZombieFight draws it: the mark where it comes down, the body's glow, the
				-- impact; D.Fx.Burst)
				local element = D.Fx.Monsters[id].element
				local skill = (Config.Combat.Skills :: any)[key]
				local burst = if element and skill and skill.windup then element else nil
				local B = D.Fx.Burst
				local tall = (a.actor :: any).body.Size.Y
				local wide = 5 * scale
				local landing = if art.at == "target"
					then a.spot + Vector3.zAxis * TARGET + Vector3.new(0, 2.5, 0)
					else a.spot + Vector3.new(0, tall * 0.5, 0)
				local markScale = if art.at == "target" then scale else scale * B.MarkWide
				local mark, glow
				if burst then
					local box = Vector3.new(wide, if art.at == "target" then 5 else tall, wide)
					mark = VfxLib.play("skill.monster_mark", landing, { variant = burst, scale = markScale, size = box })
					glow = Instance.new("Highlight")
					glow.DepthMode = Enum.HighlightDepthMode.Occluded
					glow.FillColor = Color3.fromHex(B.Glow[burst])
					glow.FillTransparency = 1
					glow.OutlineTransparency = 1
					glow.Parent = model
					game:GetService("TweenService")
						:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
							FillTransparency = B.GlowMost,
						})
						:Play()
				end
				SlimeActor.act(a.actor, "Attack")
				if freezeAt then
					task.delay(freezeAt, function()
						-- (the library's clock too: with only the particles stopped, a wind-up was cleaned up before
						-- the shot was taken)
						VfxLib.freeze(true)
						for _, d in workspace:GetDescendants() do
							if d:IsA("ParticleEmitter") and d.TimeScale > 0 then
								frozen[d] = d.TimeScale
								d.TimeScale = 0
							end
						end
					end)
				end
				task.delay(1.2, function()
					if freezeAt and freezeAt < 1.2 then
						return -- (a picture of the wind-up: no release)
					end
					if charge then
						VfxLib.cancel(charge, D.Fx.WindupFade)
					end
					if mark then
						VfxLib.cancel(mark, D.Fx.WindupFade)
					end
					if glow then
						glow.FillColor = glow.FillColor:Lerp(Color3.new(1, 1, 1), 0.5)
						glow.FillTransparency = B.FlashFill
						game:GetService("TweenService")
							:Create(glow, TweenInfo.new(B.FlashSeconds), { FillTransparency = 1 })
							:Play()
						game:GetService("Debris"):AddItem(glow, B.FlashSeconds + 0.1)
					end
					if burst then
						local box = Vector3.new(wide, if art.at == "target" then 5 else tall, wide)
						VfxLib.play("skill.monster_impact", landing, { variant = burst, scale = markScale, size = box })
					end
					-- (placed as client/ZombieFight's `release` does: its box is the body it lands on, on the floor; the
					-- target a plain 5-stud slime)
					local body = a.spot + Vector3.new(0, tall * 0.5, 0)
					local opts: { [string]: any } = { scale = scale, variant = art.variant }
					if art.at == "target" then
						opts.from = body
						opts.size = Vector3.new(wide, 5, wide)
						VfxLib.play(art.release, a.spot + Vector3.zAxis * TARGET + Vector3.new(0, 2.5, 0), opts)
					elseif art.at == "up" then
						local base = a.spot + Vector3.new(0, tall * 0.6, 0)
						VfxLib.play(art.release, CFrame.lookAt(base, base + Vector3.yAxis), opts)
					else
						opts.size = Vector3.new(wide, tall, wide)
						VfxLib.play(art.release, body, opts)
					end
				end)
				return id .. " " .. key
			end
		end
		return id .. " is not shown"
	end,
	thaw = function()
		for emitter, timeScale in frozen do
			emitter.TimeScale = timeScale
		end
		table.clear(frozen)
		VfxLib.freeze(false)
	end,
	clear = function()
		alive = false
		RunService:UnbindFromRenderStep("MonsterShow")
		clearRow()
		folder:Destroy()
		gui:Destroy()
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		_G.MonsterShow = nil
	end,
}
return string.format("%d regions, %d monsters", #regions, #ids)
