local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local stats = player:WaitForChild("PlayerData")
	local copper = stats:WaitForChild("Copper")
	local farmers = stats:WaitForChild("Farmers")
	local stone = stats:WaitForChild("Stone")
	local iron = stats:WaitForChild("Iron")
	local gold = stats:WaitForChild("Gold")
	local buyFarmerRemote = ReplicatedStorage:WaitForChild("BuyFarmer")

	local gui = Instance.new("ScreenGui")
	gui.Name = "FarmerHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "ResourcePanel"
	panel.Position = UDim2.fromOffset(18, 18)
	panel.Size = UDim2.fromOffset(288, 188)
	panel.BackgroundColor3 = Color3.fromRGB(35, 42, 49)
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	addCorner(panel, 14)

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(91, 111, 91)
	outline.Thickness = 2
	outline.Parent = panel

	local function makeCounter(name, title, x, tint)
		local card = Instance.new("Frame")
		card.Name = name
		card.Position = UDim2.fromOffset(x, 10)
		card.Size = UDim2.fromOffset(62, 48)
		card.BackgroundColor3 = Color3.fromRGB(50, 59, 63)
		card.Parent = panel
		addCorner(card, 9)

		local heading = Instance.new("TextLabel")
		heading.BackgroundTransparency = 1
		heading.Position = UDim2.fromOffset(9, 4)
		heading.Size = UDim2.new(1, -18, 0, 14)
		heading.Font = Enum.Font.GothamBold
		heading.Text = title
		heading.TextColor3 = tint
		heading.TextSize = 8
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.Parent = card

		local amount = Instance.new("TextLabel")
		amount.Name = "Amount"
		amount.BackgroundTransparency = 1
		amount.Position = UDim2.fromOffset(9, 18)
		amount.Size = UDim2.new(1, -18, 0, 25)
		amount.Font = Enum.Font.GothamBold
		amount.TextColor3 = Color3.fromRGB(255, 255, 255)
		amount.TextSize = 16
		amount.TextXAlignment = Enum.TextXAlignment.Left
		amount.Parent = card
		return amount
	end

	local copperAmount = makeCounter("CopperCounter", "KUPFER", 10, Color3.fromRGB(255, 193, 71))
	local ironAmount = makeCounter("IronCounter", "EISEN", 76, Color3.fromRGB(215, 220, 222))
	local goldAmount = makeCounter("GoldCounter", "GOLD", 142, Color3.fromRGB(255, 211, 76))
	local stoneAmount = makeCounter("StoneCounter", "STEIN", 208, Color3.fromRGB(190, 199, 199))

	local farmerCard = Instance.new("Frame")
	farmerCard.Name = "FarmerCounter"
	farmerCard.Position = UDim2.fromOffset(10, 66)
	farmerCard.Size = UDim2.fromOffset(268, 31)
	farmerCard.BackgroundColor3 = Color3.fromRGB(50, 59, 63)
	farmerCard.Parent = panel
	addCorner(farmerCard, 9)

	local farmerTitle = Instance.new("TextLabel")
	farmerTitle.BackgroundTransparency = 1
	farmerTitle.Position = UDim2.fromOffset(10, 0)
	farmerTitle.Size = UDim2.new(1, -20, 1, 0)
	farmerTitle.Font = Enum.Font.GothamBold
	farmerTitle.Text = "FARMER"
	farmerTitle.TextColor3 = Color3.fromRGB(153, 226, 127)
	farmerTitle.TextSize = 11
	farmerTitle.TextXAlignment = Enum.TextXAlignment.Left
	farmerTitle.Parent = farmerCard

	local farmerAmount = Instance.new("TextLabel")
	farmerAmount.BackgroundTransparency = 1
	farmerAmount.Position = UDim2.new(1, -74, 0, 0)
	farmerAmount.Size = UDim2.fromOffset(64, 31)
	farmerAmount.Font = Enum.Font.GothamBold
	farmerAmount.TextColor3 = Color3.fromRGB(255, 255, 255)
	farmerAmount.TextSize = 14
	farmerAmount.TextXAlignment = Enum.TextXAlignment.Right
	farmerAmount.Parent = farmerCard

	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyFarmerButton"
	buyButton.Position = UDim2.fromOffset(10, 105)
	buyButton.Size = UDim2.new(1, -20, 0, 40)
	buyButton.BackgroundColor3 = Color3.fromRGB(142, 190, 68)
	buyButton.AutoButtonColor = false
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextColor3 = Color3.fromRGB(28, 37, 28)
	buyButton.TextSize = 12
	buyButton.Parent = panel
	addCorner(buyButton, 10)

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(10, 150)
	status.Size = UDim2.new(1, -20, 0, 28)
	status.Font = Enum.Font.Gotham
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(228, 231, 224)
	status.TextSize = 11
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = panel

	local nextPrice
	local maxFarmers = 10
	local busy = false
	local function refresh()
		copperAmount.Text = tostring(copper.Value)
		ironAmount.Text = tostring(iron.Value)
		goldAmount.Text = tostring(gold.Value)
		stoneAmount.Text = tostring(stone.Value)
		farmerAmount.Text = string.format("%d / %d", farmers.Value, maxFarmers)
		if farmers.Value >= maxFarmers then
			buyButton.Text = "MAXIMALE ANZAHL"
			buyButton.BackgroundColor3 = Color3.fromRGB(91, 101, 89)
		elseif nextPrice then
			buyButton.Text = string.format("FARMER EINSTELLEN  ·  %d KUPFER", nextPrice)
			buyButton.BackgroundColor3 = if copper.Value >= nextPrice
				then Color3.fromRGB(166, 218, 79)
				else Color3.fromRGB(112, 135, 78)
		else
			buyButton.Text = "KOSTEN WERDEN GELADEN …"
			buyButton.BackgroundColor3 = Color3.fromRGB(91, 101, 89)
		end
	end

	copper.Changed:Connect(refresh)
	iron.Changed:Connect(refresh)
	gold.Changed:Connect(refresh)
	stone.Changed:Connect(refresh)
	farmers.Changed:Connect(refresh)
	refresh()

	task.spawn(function()
		while gui.Parent do
			local ok, result, _, price, serverMax = pcall(function()
				return buyFarmerRemote:InvokeServer("price")
			end)
			if ok and result then
				nextPrice = price
				maxFarmers = serverMax or maxFarmers
				refresh()
				break
			end
			task.wait(1)
		end
	end)

	buyButton.Activated:Connect(function()
		if busy or not nextPrice then return end
		if farmers.Value >= maxFarmers then
			status.Text = "Du hast schon alle Farmer."
			return
		end
		if copper.Value < nextPrice then
			status.Text = string.format("Es fehlen noch %d Kupfer.", nextPrice - copper.Value)
			return
		end

		busy = true
		status.Text = "Farmer wird eingestellt …"
		local ok, purchased, message, price, serverMax = pcall(function()
			return buyFarmerRemote:InvokeServer("buy")
		end)
		if ok and purchased then
			nextPrice = price
			maxFarmers = serverMax or maxFarmers
			status.Text = "Neuer Farmer eingestellt!"
		elseif ok then
			nextPrice = price or nextPrice
			status.Text = message or "Der Kauf hat nicht geklappt."
		else
			status.Text = "Verbindung fehlgeschlagen. Versuch es noch einmal."
		end
		busy = false
		refresh()
	end)
end

task.spawn(makeHud)

local function frameMine()
	task.wait(1)
	local camera = workspace.CurrentCamera
	local mine = workspace:WaitForChild("Mine")
	local activeMiner = mine:WaitForChild("ActiveMiner")
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 50
	RunService:UnbindFromRenderStep("FollowMiner")
	RunService:BindToRenderStep("FollowMiner", Enum.RenderPriority.Camera.Value + 1, function()
		local miner = activeMiner.Value
		if not miner or not miner.Parent then return end
		local minerPosition = miner:GetPivot().Position
		-- Look down across the field from a little farther back, like a diorama view.
		-- The horizontal focus stays on the mine while it follows the worker downwards.
		local viewTarget = Vector3.new(0, minerPosition.Y - 18, 0)
		local cameraPosition = Vector3.new(0, minerPosition.Y + 70, -110)
		camera.CFrame = CFrame.lookAt(cameraPosition, viewTarget)
	end)
end

player.CharacterAdded:Connect(frameMine)
if player.Character then task.spawn(frameMine) end
