--!strict
-- The pick-up and deposit prompts of a village (src/server/Village.luau, tag "OwnedPrompt", attribute OwnerUserId) belong to
-- the player whose plot it is: here every other player's prompt is switched to a custom style that nothing draws, so a
-- visitor standing in a neighbour's village sees no "Pick up" over their bins (the server would refuse them anyway). This
-- changes the prompt on this client only; the server's own settings (text, enabled) still arrive as they are.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG = "OwnedPrompt"

local function hideUnlessOwn(inst: Instance)
	if inst:IsA("ProximityPrompt") and inst:GetAttribute("OwnerUserId") ~= Players.LocalPlayer.UserId then
		inst.Style = Enum.ProximityPromptStyle.Custom
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(hideUnlessOwn)
for _, inst in CollectionService:GetTagged(TAG) do
	hideUnlessOwn(inst)
end
