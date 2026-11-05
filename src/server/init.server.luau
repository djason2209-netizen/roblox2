-- Endless downward mine: fixed 12x12 cross-section, with new layers generated forever.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local upgradeRequest = ReplicatedStorage:FindFirstChild("UpgradeRequest")
if not upgradeRequest then
	upgradeRequest = Instance.new("RemoteEvent")
	upgradeRequest.Name = "UpgradeRequest"
	upgradeRequest.Parent = ReplicatedStorage
end

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
local VISIBLE_LAYERS = 16
local CENTER_X = 0
local CENTER_Z = 0
local START_SURFACE_Y = 90
-- Negative X appears on the right side of a camera looking in from -Z.
local STATION_POSITION = Vector3.new(-34, START_SURFACE_Y + 2, 0)
local topLayer = 0
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
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
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
	copper.Value = copper.Value or 0
	depth.Value = topLayer
	mineLevel.Value = math.floor(topLayer / 4) + 1
	drill.Value = drillLevel
	refinery.Value = refineryLevel
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

local miner = Instance.new("Model")
miner.Name = "Miner"
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
makeMinerPart("Body", Vector3.new(1.5, 2, 1), Vector3.new(0, 0, 0), Color3.fromRGB(227, 111, 39))
makeMinerPart("Head", Vector3.new(1.2, 1.2, 1), Vector3.new(0, 1.6, 0), Color3.fromRGB(255, 207, 159))
makeMinerPart("Helmet", Vector3.new(1.6, 0.55, 1.4), Vector3.new(0, 2.25, 0), Color3.fromRGB(255, 190, 43))
makeMinerPart("Lamp", Vector3.new(0.4, 0.35, 0.2), Vector3.new(0, 2.25, -0.75), Color3.fromRGB(255, 247, 165), Enum.Material.Neon)
makeMinerPart("Boots", Vector3.new(1.35, 0.55, 0.9), Vector3.new(0, -1.25, 0), Color3.fromRGB(47, 49, 55))

local function stationPart(parent, name, size, position, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	if shape then part.Shape = shape end
	part.Parent = parent
	return part
end

local station = Instance.new("Model")
station.Name = "CloudProcessingStation"
station.Parent = mine
stationPart(station, "CloudDeck", Vector3.new(24, 1, 18), STATION_POSITION, Color3.fromRGB(235, 246, 255), Enum.Material.SmoothPlastic)
local factoryBody = stationPart(station, "FactoryBody", Vector3.new(10, 7, 8), STATION_POSITION + Vector3.new(2, 4, 0), Color3.fromRGB(208, 222, 231), Enum.Material.SmoothPlastic)
local stationWindow = stationPart(station, "Window", Vector3.new(5, 2, 0.2), STATION_POSITION + Vector3.new(2, 4.5, -4.12), Color3.fromRGB(64, 187, 218), Enum.Material.Neon)
local stationIntake = stationPart(station, "Intake", Vector3.new(5, 1, 4), STATION_POSITION + Vector3.new(-6, 1.2, -3), Color3.fromRGB(255, 171, 58), Enum.Material.Neon)
stationPart(station, "StorageBin", Vector3.new(5, 3, 5), STATION_POSITION + Vector3.new(7, 2.5, 4), Color3.fromRGB(81, 122, 147), Enum.Material.SmoothPlastic)
for _, cloudOffset in {Vector3.new(-7, -3, -5), Vector3.new(7, -3, -5), Vector3.new(-7, -3, 5), Vector3.new(7, -3, 5)} do
	stationPart(station, "Cloud", Vector3.new(5, 4, 5), STATION_POSITION + cloudOffset, Color3.fromRGB(244, 250, 255), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end
for i, offset in {Vector3.new(-8, -1, -7), Vector3.new(8, -1, -7), Vector3.new(-8, -1, 7), Vector3.new(8, -1, 7)} do
	local drone = stationPart(station, "CarrierDrone", Vector3.new(2, 0.7, 2), STATION_POSITION + offset, Color3.fromRGB(70, 204, 230), Enum.Material.Neon)
	TweenService:Create(drone, TweenInfo.new(1 + i * 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = drone.Position + Vector3.new(0, 0.8, 0)}):Play()
end

local function updateStats()
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local depth = stats:FindFirstChild("Depth")
			local level = stats:FindFirstChild("Mine")
			local drill = stats:FindFirstChild("Drill")
			local refinery = stats:FindFirstChild("Refinery")
			if depth then depth.Value = topLayer end
			if level then level.Value = math.floor(topLayer / 4) + 1 end
			if drill then drill.Value = drillLevel end
			if refinery then refinery.Value = refineryLevel end
		end
	end
end

local function upgradeCost(kind)
	if kind == "Drill" then
		return math.floor(25 * 1.65 ^ (drillLevel - 1))
	end
	return math.floor(40 * 1.7 ^ (refineryLevel - 1))
end

local function refreshStationAppearance()
	local tint = math.min(refineryLevel - 1, 6)
	factoryBody.Size = Vector3.new(10, 7 + tint * 0.5, 8)
	factoryBody.Position = STATION_POSITION + Vector3.new(2, 4 + tint * 0.25, 0)
	local glow = math.min(drillLevel - 1, 6)
	stationWindow.Color = Color3.fromRGB(64 + glow * 12, 187 + glow * 8, 218 - glow * 10)
	stationIntake.Color = Color3.fromRGB(255, 171 + tint * 10, 58 + tint * 8)
end

upgradeRequest.OnServerEvent:Connect(function(player, kind)
	if kind ~= "Drill" and kind ~= "Refinery" then return end
	local stats = player:FindFirstChild("leaderstats")
	local copper = stats and stats:FindFirstChild("Copper")
	if not copper then return end
	local cost = upgradeCost(kind)
	if copper.Value < cost then return end
	copper.Value -= cost
	if kind == "Drill" then
		drillLevel += 1
	else
		refineryLevel += 1
	end
	updateStats()
	refreshStationAppearance()
end)
refreshStationAppearance()

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
			block.Material = Enum.Material.SmoothPlastic
			local isCopper = layerNumber > 0 and (x * 7 + z * 11 + layerNumber * 3) % 19 == 0
			if layerNumber == topLayer then
				block.Color = if isCopper then Color3.fromRGB(220, 116, 48) else Color3.fromRGB(91, 178, 91)
			else
				block.Color = if isCopper then Color3.fromRGB(220, 116, 48) else oreColors[colorIndex]
			end
			block:SetAttribute("DepthLayer", layerNumber)
			block:SetAttribute("CopperVein", isCopper)
			block.Parent = mine
			layerBlocks[#layerBlocks + 1] = block
		end
	end
end

-- Use a center-out spiral so the worker visits individual neighboring blocks.
local function createMiningPath()
	local outsideIn = {}
	local left, right = 0, GRID - 1
	local top, bottom = 0, GRID - 1
	while left <= right and top <= bottom do
		for z = left, right do table.insert(outsideIn, { x = top, z = z }) end
		top += 1
		for x = top, bottom do table.insert(outsideIn, { x = x, z = right }) end
		right -= 1
		if top <= bottom then
			for z = right, left, -1 do table.insert(outsideIn, { x = bottom, z = z }) end
			bottom -= 1
		end
		if left <= right then
			for x = bottom, top, -1 do table.insert(outsideIn, { x = x, z = left }) end
			left += 1
		end
	end
	local centerOut = {}
	for index = #outsideIn, 1, -1 do table.insert(centerOut, outsideIn[index]) end
	return centerOut
end

local miningPath = createMiningPath()
local pathIndex = 1

-- Keep a deep slice of the mine rendered below the miners; append new rock at the bottom forever.
for layer = 0, VISIBLE_LAYERS - 1 do makeLayer(layer) end
local firstBlock = miningPath[1]
local firstBlockX = CENTER_X + (firstBlock.x - (GRID - 1) / 2) * BLOCK
local firstBlockZ = CENTER_Z + (firstBlock.z - (GRID - 1) / 2) * BLOCK
miner:PivotTo(CFrame.new(firstBlockX, currentSurfaceY() + 2, firstBlockZ))

local function moveMinerTo(position)
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

local function shipOre(fromPosition, reward)
	local nugget = Instance.new("Part")
	nugget.Name = "OreShipment"
	nugget.Size = Vector3.new(0.8, 0.8, 0.8)
	nugget.Position = fromPosition
	nugget.Anchored = true
	nugget.CanCollide = false
	nugget.Material = Enum.Material.Neon
	nugget.Color = Color3.fromRGB(255, 169, 54)
	nugget.Parent = workspace
	local intake = STATION_POSITION + Vector3.new(-6, 2, -3)
	local flight = TweenService:Create(nugget, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Position = intake})
	flight.Completed:Connect(function()
		for _, player in Players:GetPlayers() do
			local stats = player:FindFirstChild("leaderstats")
			local copper = stats and stats:FindFirstChild("Copper")
			if copper then copper.Value += reward end
		end
		nugget:Destroy()
	end)
	flight:Play()
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

while true do
	local topBlocks = layers[topLayer] or {}
	local chosen
	while pathIndex <= #miningPath do
		local point = miningPath[pathIndex]
		pathIndex += 1
		local blockIndex = point.x * GRID + point.z + 1
		local block = topBlocks[blockIndex]
		if block and block.Parent then
			chosen = block
			break
		end
	end
	if chosen then
		moveMinerTo(Vector3.new(chosen.Position.X, currentSurfaceY() + 2, chosen.Position.Z))
		chosen.Color = Color3.fromRGB(255, 194, 81)
		task.wait(math.max(0.12, 0.22 - (drillLevel - 1) * 0.015))
		local baseReward = if chosen:GetAttribute("CopperVein") then 5 else 1
		local copperReward = math.floor(baseReward * (1 + 0.25 * (refineryLevel - 1)))
		local shipmentOrigin = chosen.Position
		breakBlock(chosen)
		shipOre(shipmentOrigin, copperReward)
	else
		layers[topLayer] = nil
		topLayer += 1
		makeLayer(topLayer + VISIBLE_LAYERS - 1)
		pathIndex = 1
		updateStats()
		print("Reached depth layer " .. topLayer)
	end
end
