-- Endless downward mine: fixed 12x12 cross-section, with new layers generated forever.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local randomGenerator = Random.new()

local oldMine = workspace:FindFirstChild("Mine")
if oldMine then oldMine:Destroy() end
local preview = workspace:FindFirstChild("MinePreview")
if preview then preview:Destroy() end
local floor = workspace:FindFirstChild("Baseplate")
if floor then floor:Destroy() end

local mine = Instance.new("Folder")
mine.Name = "Mine"
mine.Parent = workspace

local BLOCK = 3
local GRID = 12
local MAX_FARMERS = 10
-- Keep enough generated depth on screen that the lower end is never visible.
local VISIBLE_LAYERS = 64
local CENTER_X = 0
local CENTER_Z = 0
local START_SURFACE_Y = 90
local topLayer = 0
local farmerCount = 1
local drillLevel = 1
local refineryLevel = 1
local layers = {}
local oreColors = {
	Color3.fromRGB(128, 82, 54),
	Color3.fromRGB(94, 79, 64),
	Color3.fromRGB(74, 73, 78),
	Color3.fromRGB(59, 71, 82),
}

local function currentSurfaceY()
	return START_SURFACE_Y - topLayer * BLOCK
end

local function setPlayerStats(player)
	local stats = player:FindFirstChild("PlayerData")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "PlayerData"
		stats.Parent = player
	end
	local copper = stats:FindFirstChild("Copper") or Instance.new("IntValue")
	copper.Name = "Copper"
	copper.Parent = stats
	local depth = stats:FindFirstChild("Depth") or Instance.new("IntValue")
	depth.Name = "Depth"
	depth.Parent = stats
	local mineLevel = stats:FindFirstChild("Mine") or Instance.new("IntValue")
	mineLevel.Name = "Mine"
	mineLevel.Parent = stats
	local drill = stats:FindFirstChild("Drill") or Instance.new("IntValue")
	drill.Name = "Drill"
	drill.Parent = stats
	local refinery = stats:FindFirstChild("Refinery") or Instance.new("IntValue")
	refinery.Name = "Refinery"
	refinery.Parent = stats
	local farmers = stats:FindFirstChild("Farmers") or Instance.new("IntValue")
	farmers.Name = "Farmers"
	farmers.Parent = stats
	local stone = stats:FindFirstChild("Stone") or Instance.new("IntValue")
	stone.Name = "Stone"
	stone.Parent = stats
	local iron = stats:FindFirstChild("Iron") or Instance.new("IntValue")
	iron.Name = "Iron"
	iron.Parent = stats
	local gold = stats:FindFirstChild("Gold") or Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Parent = stats
	copper.Value = copper.Value or 0
	depth.Value = topLayer
	mineLevel.Value = math.floor(topLayer / 4) + 1
	drill.Value = drillLevel
	refinery.Value = refineryLevel
	farmers.Value = farmerCount
	stone.Value = stone.Value or 0
	iron.Value = iron.Value or 0
	gold.Value = gold.Value or 0
end

Players.PlayerAdded:Connect(setPlayerStats)
for _, player in Players:GetPlayers() do setPlayerStats(player) end

-- The player's avatar is not the miner. Keep it still and out of the sky view.
local function parkCharacter(character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local function hideDescendant(descendant)
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.LocalTransparencyModifier = 1
			descendant.CanCollide = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
	character.DescendantAdded:Connect(hideDescendant)
	for _, descendant in character:GetDescendants() do hideDescendant(descendant) end
	if root then
		root.Anchored = true
		root.CFrame = CFrame.new(0, 500, 0)
	end
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(parkCharacter)
	if player.Character then task.spawn(parkCharacter, player.Character) end
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(parkCharacter)
	if player.Character then task.spawn(parkCharacter, player.Character) end
end

local function createMiner(name)
	local miner = Instance.new("Model")
	miner.Name = name
	miner.Parent = mine
	local function makeMinerPart(name, size, offset, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Anchored = true
		part.CanCollide = false
		part.Material = material or Enum.Material.SmoothPlastic
		part.Color = color
		part.CFrame = CFrame.new(offset)
		part.Parent = miner
		return part
	end
	local body = makeMinerPart("Body", Vector3.new(1.5, 2, 1), Vector3.new(0, 0, 0), Color3.fromRGB(227, 111, 39))
	miner.PrimaryPart = body
	makeMinerPart("Head", Vector3.new(1.2, 1.2, 1), Vector3.new(0, 1.6, 0), Color3.fromRGB(255, 207, 159))
	makeMinerPart("Helmet", Vector3.new(1.6, 0.55, 1.4), Vector3.new(0, 2.25, 0), Color3.fromRGB(255, 190, 43))
	makeMinerPart("Lamp", Vector3.new(0.4, 0.35, 0.2), Vector3.new(0, 2.25, -0.75), Color3.fromRGB(255, 247, 165), Enum.Material.Neon)
	makeMinerPart("Boots", Vector3.new(1.35, 0.55, 0.9), Vector3.new(0, -1.25, 0), Color3.fromRGB(47, 49, 55))
	makeMinerPart("RightArm", Vector3.new(0.45, 1.35, 0.45), Vector3.new(0.98, 0.12, 0), Color3.fromRGB(227, 111, 39))
	makeMinerPart("LeftArm", Vector3.new(0.45, 1.35, 0.45), Vector3.new(-0.98, 0.12, 0), Color3.fromRGB(227, 111, 39))

	local pickaxe = Instance.new("Model")
	pickaxe.Name = "Pickaxe"
	pickaxe.Parent = miner
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.22, 1.5, 0.22)
	handle.Anchored = true
	handle.CanCollide = false
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(111, 72, 42)
	handle.CFrame = CFrame.new(1.08, 0.72, -0.12) * CFrame.Angles(0, 0, math.rad(-18))
	handle.Parent = pickaxe
	local pickaxeHead = Instance.new("Part")
	pickaxeHead.Name = "Head"
	pickaxeHead.Size = Vector3.new(1.1, 0.32, 0.42)
	pickaxeHead.Anchored = true
	pickaxeHead.CanCollide = false
	pickaxeHead.Material = Enum.Material.Metal
	pickaxeHead.Color = Color3.fromRGB(185, 193, 197)
	pickaxeHead.CFrame = CFrame.new(1.08, 1.35, -0.12) * CFrame.Angles(0, 0, math.rad(-18))
	pickaxeHead.Parent = pickaxe
	return miner
end

local miners = { createMiner("Miner") }
local activeMiner = Instance.new("ObjectValue")
activeMiner.Name = "ActiveMiner"
activeMiner.Value = miners[1]
activeMiner.Parent = mine

local buyFarmer = Instance.new("RemoteFunction")
buyFarmer.Name = "BuyFarmer"
buyFarmer.Parent = ReplicatedStorage
local searchOriginX, searchOriginZ
local startMinerWork

local function updateStats()
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("PlayerData")
		if stats then
			local depth = stats:FindFirstChild("Depth")
			local level = stats:FindFirstChild("Mine")
			local drill = stats:FindFirstChild("Drill")
			local refinery = stats:FindFirstChild("Refinery")
			local farmers = stats:FindFirstChild("Farmers")
			if depth then depth.Value = topLayer end
			if level then level.Value = math.floor(topLayer / 4) + 1 end
			if drill then drill.Value = drillLevel end
			if refinery then refinery.Value = refineryLevel end
			if farmers then farmers.Value = farmerCount end
		end
	end
end

local function farmerPrice()
	return 25 * #miners
end

buyFarmer.OnServerInvoke = function(player, action)
	if typeof(searchOriginX) ~= "number" or typeof(searchOriginZ) ~= "number" then
		return false, "Mine is loading.", nil, MAX_FARMERS
	end
	if action == "price" then
		return true, #miners, farmerPrice(), MAX_FARMERS
	end
	if #miners >= MAX_FARMERS then
		return false, "Maximum number of farmers reached.", nil, MAX_FARMERS
	end
	local stats = player:FindFirstChild("PlayerData")
	local copper = stats and stats:FindFirstChild("Copper")
	local price = farmerPrice()
	if not copper or copper.Value < price then
		return false, "Not enough copper.", price
	end

	copper.Value -= price
	local newMiner = createMiner("Farmer" .. tostring(#miners + 1))
	local offsets = {
		Vector2.new(-BLOCK, 0), Vector2.new(BLOCK, 0),
		Vector2.new(0, -BLOCK), Vector2.new(0, BLOCK),
		Vector2.new(-BLOCK, -BLOCK), Vector2.new(BLOCK, -BLOCK),
		Vector2.new(-BLOCK, BLOCK), Vector2.new(BLOCK, BLOCK),
	}
	local offset = offsets[#miners] or Vector2.zero
	newMiner:PivotTo(CFrame.new(searchOriginX + offset.X, currentSurfaceY() + 2, searchOriginZ + offset.Y))
	table.insert(miners, newMiner)
	farmerCount = #miners
	updateStats()
	startMinerWork(newMiner)
	return true, #miners, farmerPrice(), MAX_FARMERS
end

local function makeLayer(layerNumber)
	local layerBlocks = {}
	layers[layerNumber] = layerBlocks
	local y = START_SURFACE_Y - layerNumber * BLOCK - BLOCK / 2
	local colorIndex = math.floor(layerNumber / 4) % #oreColors + 1
	for x = 0, GRID - 1 do
		for z = 0, GRID - 1 do
			local block = Instance.new("Part")
			block.Name = "OreBlock"
			-- Touching faces make the terrain read as one continuous block.
			block.Size = Vector3.new(BLOCK, BLOCK, BLOCK)
			block.Position = Vector3.new(CENTER_X + (x - (GRID - 1) / 2) * BLOCK, y, CENTER_Z + (z - (GRID - 1) / 2) * BLOCK)
			block.Anchored = true
			block.CanCollide = false
			block.CastShadow = false
			block.Material = Enum.Material.SmoothPlastic
			local roll = (x * 37 + z * 17 + layerNumber * 13) % 100 + 1
			local resourceType = "Stone"
			if layerNumber >= 12 and roll <= 2 then
				resourceType = "Gold"
			elseif layerNumber >= 4 and roll <= 9 then
				resourceType = "Iron"
			elseif layerNumber >= 4 and roll <= 15 then
				resourceType = "Copper"
			elseif layerNumber < 4 and roll <= 6 then
				resourceType = "Copper"
			end
			if layerNumber == topLayer then
				block.Color = if resourceType == "Stone" then Color3.fromRGB(91, 178, 91)
					elseif resourceType == "Copper" then Color3.fromRGB(220, 116, 48)
					elseif resourceType == "Iron" then Color3.fromRGB(190, 196, 199)
					else Color3.fromRGB(255, 202, 60)
			else
				block.Color = if resourceType == "Copper" then Color3.fromRGB(220, 116, 48)
					elseif resourceType == "Iron" then Color3.fromRGB(190, 196, 199)
					elseif resourceType == "Gold" then Color3.fromRGB(255, 202, 60)
					else oreColors[colorIndex]
			end
			block:SetAttribute("DepthLayer", layerNumber)
			block:SetAttribute("ResourceType", resourceType)
			block.Parent = mine
			layerBlocks[#layerBlocks + 1] = block
		end
	end
end

-- Keep a deep slice of the mine rendered below the miners; append new rock at the bottom forever.
for layer = 0, VISIBLE_LAYERS - 1 do makeLayer(layer) end
local spawnGridIndex = math.floor((GRID - 1) / 2)
searchOriginX = CENTER_X + (spawnGridIndex - (GRID - 1) / 2) * BLOCK
searchOriginZ = CENTER_Z + (spawnGridIndex - (GRID - 1) / 2) * BLOCK
local searchRadius = 3
miners[1]:PivotTo(CFrame.new(searchOriginX, currentSurfaceY() + 2, searchOriginZ))

local function moveMinerTo(miner, position)
	local start = miner:GetPivot()
	local offset = position - start.Position
	local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
	local goal = if horizontalOffset.Magnitude > 0.01
		then CFrame.lookAt(position, position + horizontalOffset.Unit)
		else CFrame.new(position)
	local driver = Instance.new("CFrameValue")
	driver.Value = start
	local movement = driver:GetPropertyChangedSignal("Value"):Connect(function()
		if miner.Parent then miner:PivotTo(driver.Value) end
	end)
	local duration = math.max(0.08, offset.Magnitude / 12)
	local tween = TweenService:Create(driver, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = goal })
	tween:Play()
	tween.Completed:Wait()
	movement:Disconnect()
	driver:Destroy()
end

local function collectResources(block)
	local resourceType = block:GetAttribute("ResourceType") or "Stone"
	local resourceReward = if resourceType == "Copper" then 5 else 1
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("PlayerData")
		local stone = stats and stats:FindFirstChild("Stone")
		local resource = stats and stats:FindFirstChild(resourceType)
		if stone then stone.Value += 1 end
		if resourceType ~= "Stone" and resource then resource.Value += resourceReward end
	end
end

local function breakBlock(block)
	local color = block.Color
	local position = block.Position
	for index = 1, 3 do
		local chip = Instance.new("Part")
		chip.Name = "RockChip"
		chip.Size = Vector3.new(0.7, 0.7, 0.7)
		chip.Position = position + Vector3.new(math.random(-8, 8) / 10, math.random(-4, 4) / 10, math.random(-8, 8) / 10)
		chip.Anchored = false
		chip.CanCollide = false
		chip.Material = Enum.Material.SmoothPlastic
		chip.Color = color
		chip.Parent = workspace
		chip.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), math.random(3, 9), math.random(-8, 8))
		Debris:AddItem(chip, 2)
	end
	local crumble = TweenService:Create(block, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(0.15, 0.15, 0.15),
		Transparency = 1,
	})
	crumble:Play()
	crumble.Completed:Wait()
	block:Destroy()
end

local function swingPickaxe(miner)
	local pickaxe = miner:FindFirstChild("Pickaxe")
	if not pickaxe then return end
	local start = pickaxe:GetPivot()
	local driver = Instance.new("CFrameValue")
	driver.Value = start
	local movement = driver:GetPropertyChangedSignal("Value"):Connect(function()
		if pickaxe.Parent then pickaxe:PivotTo(driver.Value) end
	end)
	local function swingTo(pivot, duration)
		local tween = TweenService:Create(driver, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Value = pivot,
		})
		tween:Play()
		tween.Completed:Wait()
	end
	swingTo(start * CFrame.Angles(0, 0, math.rad(-55)), 0.12)
	swingTo(start * CFrame.Angles(0, 0, math.rad(65)), 0.1)
	swingTo(start, 0.08)
	movement:Disconnect()
	driver:Destroy()
end

local function findBlocksInRange(blocks, originX, originZ, radius)
	local candidates = {}
	local distance = radius * BLOCK
	for _, block in blocks do
		if block.Parent
			and not block:GetAttribute("Claimed")
			and math.abs(block.Position.X - originX) <= distance
			and math.abs(block.Position.Z - originZ) <= distance
		then
			table.insert(candidates, block)
		end
	end
	return candidates
end

local function countClaimedInRange(blocks, originX, originZ, radius)
	local distance = radius * BLOCK
	local claimedCount = 0
	for _, block in blocks do
		if block.Parent
			and block:GetAttribute("Claimed")
			and math.abs(block.Position.X - originX) <= distance
			and math.abs(block.Position.Z - originZ) <= distance
		then
			claimedCount += 1
		end
	end
	return claimedCount
end

local activeWorkers = 0
local layerChanging = false

local function claimNextBlock()
	local topBlocks = layers[topLayer] or {}
	local edge = (GRID - 1) / 2 * BLOCK
	local farthestRadius = math.ceil(math.max(
		math.abs(searchOriginX - (CENTER_X - edge)),
		math.abs(searchOriginX - (CENTER_X + edge)),
		math.abs(searchOriginZ - (CENTER_Z - edge)),
		math.abs(searchOriginZ - (CENTER_Z + edge))
	) / BLOCK)
	local availableBlocks = findBlocksInRange(topBlocks, searchOriginX, searchOriginZ, searchRadius)
	while #availableBlocks == 0 and searchRadius < farthestRadius do
		if countClaimedInRange(topBlocks, searchOriginX, searchOriginZ, searchRadius) > 0 then
			return nil
		end
		searchRadius = math.min(searchRadius + 3, farthestRadius)
		availableBlocks = findBlocksInRange(topBlocks, searchOriginX, searchOriginZ, searchRadius)
	end
	local chosen = if #availableBlocks > 0
		then availableBlocks[randomGenerator:NextInteger(1, #availableBlocks)]
		else nil
	if chosen then chosen:SetAttribute("Claimed", true) end
	return chosen
end

local function advanceLayer()
	layerChanging = true
	layers[topLayer] = nil
	topLayer += 1
	makeLayer(topLayer + VISIBLE_LAYERS - 1)
	local minerPosition = activeMiner.Value:GetPivot().Position
	searchOriginX = minerPosition.X
	searchOriginZ = minerPosition.Z
	searchRadius = 3
	for _, miner in miners do
		local position = miner:GetPivot().Position
		miner:PivotTo(CFrame.new(position.X, currentSurfaceY() + 2, position.Z))
	end
	updateStats()
	print("Reached depth layer " .. topLayer)
	layerChanging = false
end

startMinerWork = function(miner)
	task.spawn(function()
		while miner.Parent do
			if layerChanging then
				task.wait(0.05)
			else
				local chosen = claimNextBlock()
				if chosen then
					activeWorkers += 1
					activeMiner.Value = miner
					moveMinerTo(miner, Vector3.new(chosen.Position.X, currentSurfaceY() + 2, chosen.Position.Z))
					chosen.Color = Color3.fromRGB(255, 194, 81)
					swingPickaxe(miner)
					task.wait(math.max(0.04, 0.12 - (drillLevel - 1) * 0.01))
					breakBlock(chosen)
					collectResources(chosen)
					activeWorkers -= 1
				elseif activeWorkers == 0 then
					advanceLayer()
				else
					task.wait(0.05)
				end
			end
		end
	end)
end

for _, miner in miners do startMinerWork(miner) end
