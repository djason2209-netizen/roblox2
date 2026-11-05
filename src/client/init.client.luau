local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

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
panel.Size = UDim2.fromOffset(340, 94)
panel.Position = UDim2.fromOffset(20, 20)
panel.BackgroundColor3 = Color3.fromRGB(26, 34, 45)
panel.BackgroundTransparency = 0.12
panel.TextColor3 = Color3.fromRGB(245, 245, 245)
panel.Font = Enum.Font.GothamBold
panel.TextSize = 20
panel.TextWrapped = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local function update()
	local stats = player:FindFirstChild("leaderstats")
	local copper = stats and stats:FindFirstChild("Copper")
	local stage = stats and stats:FindFirstChild("Mine")
	local depth = stats and stats:FindFirstChild("Depth")
	panel.Text = "MINE " .. tostring(stage and stage.Value or 1) .. "  •  ENDLOSB\nTiefe: " .. tostring(depth and depth.Value or 0) .. "  |  Kupfer: " .. tostring(copper and copper.Value or 0)
end

local stats = player:WaitForChild("leaderstats")
stats:WaitForChild("Copper").Changed:Connect(update)
stats:WaitForChild("Mine").Changed:Connect(update)
stats:WaitForChild("Depth").Changed:Connect(update)
update()
