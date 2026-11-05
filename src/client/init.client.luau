local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest")

local function frameMine()
	task.wait(1)
	local camera = workspace.CurrentCamera
	local mine = workspace:WaitForChild("Mine")
	local miner = mine:WaitForChild("Miner")
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 50
	RunService:UnbindFromRenderStep("FollowMiner")
	RunService:BindToRenderStep("FollowMiner", Enum.RenderPriority.Camera.Value + 1, function()
		if not miner.Parent then return end
		local minerPosition = miner:GetPivot().Position
		-- Keep the 12x12 shaft square to the screen; only a small tilt reveals its top.
		local viewTarget = minerPosition + Vector3.new(0, -3, 0)
		camera.CFrame = CFrame.lookAt(minerPosition + Vector3.new(0, 10, -92), viewTarget)
	end)
end

player.CharacterAdded:Connect(frameMine)
if player.Character then task.spawn(frameMine) end

local gui = Instance.new("ScreenGui")
gui.Name = "MiningHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("TextLabel")
panel.Name = "Status"
panel.Size = UDim2.fromOffset(360, 118)
panel.Position = UDim2.fromOffset(20, 20)
panel.BackgroundColor3 = Color3.fromRGB(26, 34, 45)
panel.BackgroundTransparency = 0.12
panel.TextColor3 = Color3.fromRGB(245, 245, 245)
panel.Font = Enum.Font.GothamBold
panel.TextSize = 17
panel.TextWrapped = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local upgrades = Instance.new("Frame")
upgrades.Name = "WorkshopUpgrades"
upgrades.Size = UDim2.fromOffset(360, 158)
upgrades.Position = UDim2.fromOffset(20, 148)
upgrades.BackgroundColor3 = Color3.fromRGB(26, 34, 45)
upgrades.BackgroundTransparency = 0.12
upgrades.Parent = gui
Instance.new("UICorner", upgrades).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.fromOffset(12, 5)
title.BackgroundTransparency = 1
title.Text = "WERKSTATT  •  VERBESSERUNGEN"
title.TextColor3 = Color3.fromRGB(210, 226, 238)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = upgrades

local function makeUpgradeButton(name, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -16, 0, 54)
	button.Position = UDim2.fromOffset(8, y)
	button.BackgroundColor3 = Color3.fromRGB(53, 64, 77)
	button.TextColor3 = Color3.fromRGB(245, 248, 250)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextWrapped = true
	button.AutoButtonColor = true
	button.Parent = upgrades
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
	return button
end

local drillButton = makeUpgradeButton("DrillUpgrade", 34)
local refineryButton = makeUpgradeButton("RefineryUpgrade", 94)
drillButton.Activated:Connect(function() upgradeRequest:FireServer("Drill") end)
refineryButton.Activated:Connect(function() upgradeRequest:FireServer("Refinery") end)

local function nextDrillCost(level)
	return math.floor(25 * 1.65 ^ (level - 1))
end

local function nextRefineryCost(level)
	return math.floor(40 * 1.7 ^ (level - 1))
end

local function update()
	local stats = player:FindFirstChild("leaderstats")
	local copper = stats and stats:FindFirstChild("Copper")
	local stage = stats and stats:FindFirstChild("Mine")
	local depth = stats and stats:FindFirstChild("Depth")
	local drill = stats and stats:FindFirstChild("Drill")
	local refinery = stats and stats:FindFirstChild("Refinery")
	local copperValue = copper and copper.Value or 0
	local drillLevel = drill and drill.Value or 1
	local refineryLevel = refinery and refinery.Value or 1
	panel.Text = "MINE " .. tostring(stage and stage.Value or 1) .. "  •  ENDLOSB\nTiefe: " .. tostring(depth and depth.Value or 0) .. "  |  Kupfer: " .. tostring(copperValue) .. "\nBohrer Lvl " .. tostring(drillLevel) .. "  |  Schmelzer Lvl " .. tostring(refineryLevel)
	local drillCost = nextDrillCost(drillLevel)
	local refineryCost = nextRefineryCost(refineryLevel)
	drillButton.Text = "BOHRER  " .. drillLevel .. " → " .. (drillLevel + 1) .. "   |   " .. drillCost .. " Kupfer\nDer Abbau wird schneller"
	refineryButton.Text = "SCHMELZER  " .. refineryLevel .. " → " .. (refineryLevel + 1) .. "   |   " .. refineryCost .. " Kupfer\n+25% Kupfer pro Erz"
	drillButton.BackgroundColor3 = if copperValue >= drillCost then Color3.fromRGB(49, 126, 94) else Color3.fromRGB(53, 64, 77)
	refineryButton.BackgroundColor3 = if copperValue >= refineryCost then Color3.fromRGB(49, 126, 94) else Color3.fromRGB(53, 64, 77)
end

local stats = player:WaitForChild("leaderstats")
stats:WaitForChild("Copper").Changed:Connect(update)
stats:WaitForChild("Mine").Changed:Connect(update)
stats:WaitForChild("Depth").Changed:Connect(update)
stats:WaitForChild("Drill").Changed:Connect(update)
stats:WaitForChild("Refinery").Changed:Connect(update)
update()
