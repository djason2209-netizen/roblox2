local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

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
