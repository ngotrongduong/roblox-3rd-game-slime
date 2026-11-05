--!strict
-- Robux: what is sold (Config.Robux.Products, docs/MONETIZATION.md §2) reaches the save here, and only here.
--
--   * Developer products: MarketplaceService.ProcessReceipt. The good is granted inside PlayerData.update together with the
--     receipt id (farm.robux.receipts), the save is written NOW (PlayerData.saveNow), and only then does Roblox hear
--     PurchaseGranted. A receipt seen twice (Roblox asks again, a second server) is answered granted and granted once. While the
--     save is not loaded, or the write fails, the answer is NotProcessedYet and Roblox asks again.
--   * Game passes: UserOwnsGamePassAsync at joining (retried, a failed ask changes nothing); a pass prompt that ends bought
--     (the server's PromptGamePassPurchaseFinished) grants the pass at once; the answer is mirrored into farm.robux.passes so
--     the pure rules (shared/Boosts) read it with no service.
--   * The client asks for a prompt through Remotes.Purchase ({ key = "vip" } -> { ok, reason?, test? }); the server checks that
--     the key exists, that the good is on Roblox (id ~= 0), that the save is loaded, that it would do something now
--     (Products.canBuy) and how often the player asks, then opens the prompt. Paid random items (wheel spins, the Starter Pack)
--     are refused where PolicyService says they are restricted.
--   * Config.Robux.TestGrant (Studio only, off in anything committed): the same request grants the good through `deliver`, the
--     function a real receipt uses, with a "test-" receipt id, and logs it; it also needs the in-memory store (not
--     Config.Save.StudioUsesRealStore), so test goods never reach a real save.
--
-- What it publishes on each Player (attributes, set only when changed) for the screens:
--   Vip (bool)                 owns the VIP pass: the badge and the chat tag
--   Passes (string)            JSON array of the pass keys owned
--   LuckLabel, LuckReal        the luck label ("Luck x12") and the real factor the chances get ("Rare babies x2.4")
--   GoldUntil, HatchUntil      server time the Gold Potion and the Hatch Potion run out, 0 for none (the luck potion's end is the
--                              village folder's LuckUntil)
--   ExtraTeams, ExtraSlots     what the passes add: teams on top of the village's, slime slots
--   StreakSavers, QuestRerolls, BankedDrinks, BankedHatchAlls   banked goods not used yet (the last two are spent with the
--                              Village request UseBanked { key = "energyDrink" | "hatchAll" })
--   PaidRandomRestricted (bool) wheel spins and the Starter Pack must be hidden (true until PolicyService has answered)
--   ShopRefused (string)       JSON array of { key, reason } for each good that cannot be bought now (Products.canBuy reasons)
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Boosts = require(ReplicatedStorage.Shared.Boosts)
local Config = require(ReplicatedStorage.Shared.Config)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Products = require(ReplicatedStorage.Shared.Products)
local PlayerData = require(script.Parent.PlayerData)

local PREFIX = Config.LogPrefix
local R = Config.Robux

local Purchases = {}

-- os.clock of each player's last prompt request; whether PolicyService restricts paid random items (nil: not known yet).
local lastPrompt: { [Player]: number } = {}
local restricted: { [Player]: boolean } = {}
-- Receipt ids of the test grants of this server.
local testCount = 0

local function set(inst: Instance, name: string, value: any)
	if inst:GetAttribute(name) ~= value then
		inst:SetAttribute(name, value)
	end
end

-- The test grant works in Studio on the in-memory store only: test goods never reach a real save.
local function testGrantOn(): boolean
	return R.TestGrant and RunService:IsStudio() and not Config.Save.StudioUsesRealStore
end

local function isRestricted(player: Player): boolean
	return restricted[player] ~= false
end

-- ===== what the screens read =====

local function publish(player: Player)
	local farm = PlayerData.get(player)
	if not farm or not PlayerData.isReady(player) then
		return
	end
	local now = os.time()
	local passes: { string } = {}
	local refused: { { string } } = {}
	for _, product in R.Products do
		if product.kind == "pass" and Boosts.owns(farm, product.key) then
			table.insert(passes, product.key)
		end
		local ok, why = Products.canBuy(farm, product.key, now, isRestricted(player))
		if not ok then
			table.insert(refused, { product.key, why or "UNKNOWN" })
		end
	end
	local label, real = Luck.view(farm, now)
	set(player, "Vip", Boosts.isVip(farm))
	set(player, "Passes", HttpService:JSONEncode(passes))
	set(player, "LuckLabel", label)
	set(player, "LuckReal", real)
	set(player, "GoldUntil", if Boosts.active(farm, "gold", now) then Boosts.endsAt(farm, "gold") else 0)
	set(player, "HatchUntil", if Boosts.active(farm, "hatch", now) then Boosts.endsAt(farm, "hatch") else 0)
	set(player, "ExtraTeams", Boosts.extraTeams(farm))
	set(player, "ExtraSlots", Boosts.extraSlots(farm))
	set(player, "StreakSavers", farm.robux.savers)
	set(player, "QuestRerolls", farm.robux.rerolls)
	set(player, "BankedDrinks", farm.robux.drinks)
	set(player, "BankedHatchAlls", farm.robux.hatchAlls)
	set(player, "PaidRandomRestricted", isRestricted(player))
	set(player, "ShopRefused", HttpService:JSONEncode(refused))
end

local function safePublish(player: Player)
	local ok, err = pcall(function(): any
		publish(player)
		return nil
	end)
	if not ok then
		warn(PREFIX, "purchases: publishing failed for", player.Name, err)
	end
end

-- Publishes again now (after a banked good was used).
function Purchases.refresh(player: Player)
	safePublish(player)
end

-- ===== granting =====

-- Grants good `key` to the player's save under `receiptId` and writes the save now. The ONE function a real receipt and the
-- Studio test grant both use. (true, "GRANTED" | "DUPLICATE") once the grant is in the written save; (false, why): "NOT_READY"
-- (no save loaded), "UNKNOWN" (no such developer product), "NOT_SAVED" (granted in memory, the store did not take it: the
-- receipt is in the data, so asking again only writes it) or "FAILED".
function Purchases.deliver(player: Player, key: string, receiptId: string): (boolean, string)
	local now = os.time()
	local status = "FAILED"
	local detail: string? = nil
	local called, loaded = pcall(function(): boolean
		return PlayerData.update(player, function(farm: any)
			local ok, result, info = Products.redeem(farm, key, receiptId, now)
			status = if ok then result else "UNKNOWN"
			detail = info
		end)
	end)
	if not called then
		warn(PREFIX, "purchases: granting", key, "to", player.Name, "failed:", loaded)
		return false, "FAILED"
	elseif loaded ~= true then
		return false, "NOT_READY"
	elseif status ~= "GRANTED" and status ~= "DUPLICATE" then
		return false, status
	end
	PlayerData.markKeyMoment(player, "robux purchase")
	if not PlayerData.saveNow(player) then
		warn(PREFIX, "purchases:", player.Name, key, "granted but not saved yet, receipt", receiptId)
		return false, "NOT_SAVED"
	end
	print(
		PREFIX,
		"purchases:",
		player.Name,
		if status == "GRANTED" then "got" else "already had",
		key,
		"-",
		detail or "",
		"receipt",
		receiptId
	)
	safePublish(player)
	return true, status
end

-- Roblox's receipt: the decision it is told.
local function processReceipt(info: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		-- (they left: Roblox asks again when they rejoin)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = Products.byProductId(info.ProductId)
	if not product then
		warn(PREFIX, "purchases: a receipt for an unknown product", info.ProductId, "from", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local waited = 0
	while not PlayerData.isReady(player) do
		if waited >= R.ReceiptWaitSeconds or player.Parent ~= Players then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		task.wait(0.5)
		waited += 0.5
	end
	local ok = Purchases.deliver(player, product.key, tostring(info.PurchaseId))
	return if ok then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ===== game passes =====

-- Asks Roblox whether the player owns a pass, retrying; nil when every try failed (the answer is unknown, not "no").
local function ownsPass(player: Player, id: number): boolean?
	for attempt = 1, R.PassTries do
		local ok, owns = pcall(function(): boolean
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
		end)
		if ok then
			return owns
		end
		if attempt < R.PassTries then
			task.wait(R.PassRetrySeconds)
		end
	end
	return nil
end

-- Mirrors one pass into the save.
local function applyPass(player: Player, key: string, owned: boolean)
	local changed = false
	PlayerData.update(player, function(farm: any)
		changed = Products.setPass(farm, key, owned, os.time())
	end)
	if changed then
		PlayerData.markKeyMoment(player, "pass")
		print(PREFIX, "purchases:", player.Name, if owned then "owns" else "no longer owns", key)
		safePublish(player)
	end
end

-- At joining: every pass that is on Roblox is asked once; a pass whose answer could not be had keeps what the save says.
local function syncPasses(player: Player)
	for _, product in R.Products do
		if product.kind == "pass" and product.id ~= 0 and player.Parent == Players then
			local owns = ownsPass(player, product.id)
			if owns ~= nil and player.Parent == Players then
				applyPass(player, product.key, owns)
			elseif owns == nil then
				warn(PREFIX, "purchases: could not ask Roblox about", product.key, "for", player.Name)
			end
		end
	end
end

local function loadPolicy(player: Player)
	for attempt = 1, R.PassTries do
		local ok, info = pcall(function(): any
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok and type(info) == "table" then
			restricted[player] = info.ArePaidRandomItemsRestricted == true
			safePublish(player)
			return
		end
		if attempt < R.PassTries then
			task.wait(R.PassRetrySeconds)
		end
	end
	warn(PREFIX, "purchases: no policy answer for", player.Name, "- paid random items stay hidden")
end

-- A pass prompt ended on the server: if Roblox says they bought it, the pass is owned at once (a client cannot fire this
-- server event, and the join check mirrors Roblox again anyway).
local function passPromptFinished(player: Player, passId: number, wasPurchased: boolean)
	local product = Products.byPassId(passId)
	if not wasPurchased or not product or player.Parent ~= Players then
		return
	end
	applyPass(player, product.key, true)
end

-- ===== the client's request =====

local function request(player: Player, data: any): { ok: boolean, reason: string?, test: boolean? }
	if type(data) ~= "table" or type(data.key) ~= "string" then
		return { ok = false, reason = "BAD_REQUEST" }
	end
	local key: string = data.key
	local product = Products.get(key)
	if not product then
		return { ok = false, reason = "UNKNOWN" }
	end
	local farm = PlayerData.get(player)
	if not farm or not PlayerData.isReady(player) then
		return { ok = false, reason = "NOT_READY" }
	end
	local clock = os.clock()
	if clock - (lastPrompt[player] or -math.huge) < R.PromptGapSeconds then
		return { ok = false, reason = "RATE" }
	end
	lastPrompt[player] = clock
	-- (test goods never reach a real save: only with the in-memory store)
	local testing = testGrantOn()
	if product.id == 0 and not testing then
		return { ok = false, reason = "NOT_ON_SALE" }
	end
	local ok, why = Products.canBuy(farm, key, os.time(), isRestricted(player))
	if not ok then
		return { ok = false, reason = why or "UNKNOWN" }
	end
	if testing then
		testCount += 1
		local delivered, status
		if product.kind == "pass" then
			applyPass(player, key, true)
			delivered, status = true, "GRANTED"
		else
			delivered, status =
				Purchases.deliver(player, key, string.format("test-%d-%d-%d", player.UserId, os.time(), testCount))
		end
		print(PREFIX, "purchases: TEST GRANT of", key, "to", player.Name, "->", status)
		return { ok = delivered, reason = if delivered then nil else status, test = true }
	end
	local prompted = pcall(function()
		if product.kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, product.id)
		else
			MarketplaceService:PromptProductPurchase(player, product.id)
		end
	end)
	if not prompted then
		return { ok = false, reason = "PROMPT_FAILED" }
	end
	return { ok = true, reason = nil }
end

function Purchases.start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local remote = remotes:FindFirstChild("Purchase")
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "Purchase"
		remote.Parent = remotes
	end
	assert(remote:IsA("RemoteFunction"), "Purchase remote must be a RemoteFunction")
	remote.OnServerInvoke = function(player: Player, data: any)
		return request(player, data)
	end

	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(passPromptFinished)

	PlayerData.onReady(function(player: Player, _data: any)
		task.spawn(syncPasses, player)
		task.spawn(loadPolicy, player)
		safePublish(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastPrompt[player] = nil
		restricted[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(R.RefreshSeconds)
			for _, player in Players:GetPlayers() do
				safePublish(player)
			end
		end
	end)
	print(PREFIX, "purchases ready" .. (if testGrantOn() then " (TEST GRANT ON)" else ""))
end

return Purchases
