--!strict
-- The fish bin and the vegetable bin fill up in view (docs/GAMEPLAY.md §10): up to ten models of what the work
-- area's box holds, lying in the bin. The bins are built by src/server/WorkProps.luau (tag "ItemBin", attributes
-- Area and Capacity, an invisible part "BinFill" for the floor); the counts come from the "Box" attribute of
-- workspace.Villages.<UserId> ({ area = { item = count } }); the models are ClientKit.Items.<item>.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local TAG = "ItemBin"
local FISH_LENGTH = 1.5 -- the longest side of a fish in a bin, in studs
local DEFAULT_LENGTH = 1.1
local LENGTH: { [string]: number } = {}
for _, id in Config.Food.FishOrder do
	LENGTH[id] = FISH_LENGTH
end
-- where the ten sit on the floor (x, y up from it, z, turn): six round the edge, three above, one on top
local SLOTS = {}
for i = 0, 5 do
	local a = i * math.pi / 3
	table.insert(SLOTS, { math.cos(a) * 0.72, 0.1, math.sin(a) * 0.72, a + 1.2 })
end
for i = 0, 2 do
	local a = i * math.pi * 2 / 3 + 0.5
	table.insert(SLOTS, { math.cos(a) * 0.36, 0.5, math.sin(a) * 0.36, a * 2 })
end
table.insert(SLOTS, { 0, 0.85, 0, 0.7 })

type Shown = { key: string, model: Model }
type Bin = { bin: Model, fill: BasePart, folder: Folder, shown: { Shown } }

local bins: { [Model]: Bin } = {}
local boxes: { [string]: { [string]: number } } = {}
local warned: { [string]: boolean } = {}

local function item(key: string): Model?
	local kit = ReplicatedStorage:FindFirstChild("ClientKit")
	local items = if kit then kit:FindFirstChild("Items") else nil
	local original = if items then items:FindFirstChild(key) else nil
	if not original then
		if not warned[key] then
			warned[key] = true
			warn(Config.LogPrefix, "missing ClientKit/Items/" .. key .. " (bin)")
		end
		return nil
	end
	local model = Instance.new("Model")
	model.Name = key
	if original:IsA("Model") then
		for _, child in original:GetChildren() do
			child:Clone().Parent = model
		end
	elseif original:IsA("BasePart") then
		original:Clone().Parent = model
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.CastShadow = false
		end
	end
	local size = model:GetExtentsSize()
	local longest = math.max(size.X, size.Y, size.Z)
	if longest > 0 then
		model:ScaleTo(model:GetScale() * (LENGTH[key] or DEFAULT_LENGTH) / longest)
	end
	return model
end

-- the list of item keys a box shows, at most `capacity`, in a steady order
local function listOf(area: string, capacity: number): { string }
	local list: { string } = {}
	local box = boxes[area]
	if box then
		for _, key in Config.Food.RawOrder do
			for _ = 1, math.floor(box[key] or 0) do
				if #list < capacity then
					table.insert(list, key)
				end
			end
		end
	end
	return list
end

local function put(b: Bin, index: number, model: Model, drop: boolean)
	local s = SLOTS[index]
	local base = b.fill.CFrame * CFrame.new(s[1], b.fill.Size.Y / 2 + s[2], s[3])
	local box = model:GetExtentsSize()
	local rest = base
		* CFrame.Angles(0, s[4], 0)
		* CFrame.Angles(0, 0, if index % 2 == 0 then 0.25 else -0.2)
		* CFrame.new(0, box.Y / 2, 0)
	model.Parent = b.folder
	-- (the kit's pivot is at an item's foot: aim its middle, not its pivot)
	local off = model:GetPivot():ToObjectSpace((model:GetBoundingBox())).Position
	local function aim(cf: CFrame)
		model:PivotTo(cf * CFrame.new(-off))
	end
	if not drop then
		aim(rest)
		return
	end
	task.spawn(function()
		local t = 0
		while t < 0.3 and model.Parent do
			t += RunService.Heartbeat:Wait()
			local k = math.min(t / 0.3, 1)
			aim(rest * CFrame.new(0, (1 - k * k) * 1.6, 0))
		end
		if model.Parent then
			aim(rest)
		end
	end)
end

local function refresh(b: Bin, animate: boolean)
	local want = listOf(b.bin:GetAttribute("Area") :: string, (b.bin:GetAttribute("Capacity") :: number) or 10)
	-- the part that already matches stays; the rest changes
	local keep = 0
	for i, s in b.shown do
		if want[i] == s.key then
			keep = i
		else
			break
		end
	end
	for i = #b.shown, keep + 1, -1 do
		b.shown[i].model:Destroy()
		b.shown[i] = nil :: any
	end
	for i = keep + 1, #want do
		local model = item(want[i])
		if model then
			put(b, i, model, animate)
			b.shown[i] = { key = want[i], model = model }
		else
			break
		end
	end
end

local function add(inst: Instance)
	if not inst:IsA("Model") or bins[inst] then
		return
	end
	local fill = inst:WaitForChild("BinFill", 10)
	if not fill or not fill:IsA("BasePart") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Contents"
	folder.Parent = inst
	local b: Bin = { bin = inst, fill = fill, folder = folder, shown = {} }
	bins[inst] = b
	inst.Destroying:Once(function()
		bins[inst] = nil
	end)
	refresh(b, false)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
	task.spawn(add, inst)
end)
for _, inst in CollectionService:GetTagged(TAG) do
	task.spawn(add, inst)
end

task.spawn(function()
	local root = workspace:WaitForChild("Villages"):WaitForChild(tostring(Players.LocalPlayer.UserId))
	local function read()
		local raw = root:GetAttribute("Box")
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(if type(raw) == "string" then raw else "{}")
		end)
		boxes = if ok and type(decoded) == "table" then decoded else {}
		for _, b in bins do
			refresh(b, true)
		end
	end
	root:GetAttributeChangedSignal("Box"):Connect(read)
	read()
end)
