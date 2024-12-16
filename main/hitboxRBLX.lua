
export type Hit = {
	hitHumanoid: Humanoid,
	hitCharacter: Model,
}

export type Hitbox = {
	player: Player,
	character: Model,
	connection: RBXScriptConnection | nil,
	detectedHits: {},
	position: CFrame,
	size: Vector3,
	continuousDetection: boolean,
	hitFunction: (Hit) -> (),
	overlapParams: OverlapParams,
}

local Hitbox = {}
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Packages = ReplicatedStorage.Packages

function Hitbox._detectHits(hitbox: Hitbox)
	
	if not Hitbox then return end
	
	local humanoidRootPart = hitbox.character:FindFirstChild("HumanoidRootPart")
	
	local hits = workspace:GetPartBoundsInBox(
		humanoidRootPart.CFrame * hitbox.position,
		hitbox.size,
		hitbox.overlapParams
	)

	for _, hit in hits do
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character or not character:FindFirstChildOfClass("Humanoid") then
			continue
		end

		if table.find(hitbox.detectedHits, character) then
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			table.insert(hitbox.detectedHits, character)
			hitbox.hitFunction({
				hitHumanoid = humanoid,
				hitCharacter = character
			})
		end
	end

	if #hitbox.detectedHits > 50 then
		table.clear(hitbox.detectedHits)
	end
end

function Hitbox.Start(hitbox: Hitbox)
	hitbox.overlapParams = OverlapParams.new()
	hitbox.overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	hitbox.overlapParams.FilterDescendantsInstances = {hitbox.character}

	if hitbox.continuousDetection then
		hitbox.connection = RunService.Heartbeat:Connect(function()
			Hitbox._detectHits(hitbox)
		end)
	else
		Hitbox._detectHits(hitbox)
	end

	Hitbox[hitbox.player] = hitbox
end

function Hitbox.Stop(hitbox: Hitbox)
	if hitbox.connection then
		hitbox.connection:Disconnect()
		hitbox.connection = nil
	end
	hitbox.detectedHits = {}
	Hitbox[hitbox.player] = nil

end

Players.PlayerRemoving:Connect(function(player)
	local hitbox = Hitbox[player]
	if hitbox then
		Hitbox.Stop(hitbox)
	end
end)

return Hitbox
