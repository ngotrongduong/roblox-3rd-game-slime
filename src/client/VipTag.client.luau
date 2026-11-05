--!strict
-- The gold [VIP] tag in front of a VIP's chat messages (docs/MONETIZATION.md §2). The server publishes the Player attribute
-- Vip (server/Purchases); this only draws it, with TextChatService's own message prefix. The small badge beside a name in
-- the screens reads the same attribute. No effect, no sound.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)

local TAG = Config.Robux.VipTag

TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	if not source then
		return nil
	end
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or player:GetAttribute("Vip") ~= true then
		return nil
	end
	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = string.format('<font color="#%s">%s</font> %s', TAG.Colour, TAG.Text, message.PrefixText)
	return properties
end
