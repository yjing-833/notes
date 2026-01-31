-- Yjing Hub Full GUI
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- GUI
local yjing = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextLabel = Instance.new("TextLabel")
local MinBtn = Instance.new("TextButton")
local CloseBtn = Instance.new("TextButton")
local Sidebar = Instance.new("Frame")
local MainBtn = Instance.new("TextButton")
local PlayerBtn = Instance.new("TextButton")
local Frame_3 = Instance.new("Frame")

yjing.Name = "yjing"
yjing.Parent = player:WaitForChild("PlayerGui")
yjing.ResetOnSpawn = false

Frame.Parent = yjing
Frame.Active = true
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Draggable = true
Frame.Position = UDim2.new(0.5, -291, 0.5, -164)
Frame.Size = UDim2.new(0, 295, 0, 220)

TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1
TextLabel.Position = UDim2.new(0, 10, 0, 0)
TextLabel.Size = UDim2.new(0.5, -10, 0, 30)
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Text = "Yjing Hub"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 18
TextLabel.TextXAlignment = Enum.TextXAlignment.Left

MinBtn.Parent = Frame
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 18

CloseBtn.Parent = Frame
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 18

Sidebar.Parent = Frame
Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 0, 0, 30)
Sidebar.Size = UDim2.new(0, 90, 1, -30)

MainBtn.Parent = Sidebar
MainBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
MainBtn.Position = UDim2.new(0, 5, 0, 10)
MainBtn.Size = UDim2.new(1, -10, 0, 30)
MainBtn.Font = Enum.Font.GothamBold
MainBtn.Text = "Main"
MainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MainBtn.TextSize = 14

PlayerBtn.Parent = Sidebar
PlayerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PlayerBtn.Position = UDim2.new(0, 5, 0, 55)
PlayerBtn.Size = UDim2.new(1, -10, 0, 30)
PlayerBtn.Font = Enum.Font.GothamBold
PlayerBtn.Text = "Player"
PlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerBtn.TextSize = 14

Frame_3.Parent = Frame
Frame_3.BackgroundTransparency = 1
Frame_3.Position = UDim2.new(0.3, 0, 0.15, 0)
Frame_3.Size = UDim2.new(0.7, 0, 0.8, 0)

-- === States ===
local autoChest = false
local chestThread = nil
local flightEnabled = false
local flyConnection = nil
local flightSpeed = 200
local hopEnabled = false

-- chỉ lưu AutoChest và Hop
local States = {
	AutoChest = false,
	Hop = false,
}

-- === Helper ===
local function ClearContent()
	for _,c in ipairs(Frame_3:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

-- === teleportWithSave (chỉ nhớ AutoChest + Hop) ===
local function teleportWithSave(callback)
	local HttpService = game:GetService("HttpService")

	-- chỉ lưu AutoChest và Hop
	local SavedMinimal = {
		AutoChest = States.AutoChest,
		Hop = States.Hop,
	}

	getgenv().SavedStates = SavedMinimal
	getgenv().SavedStatesJSON = HttpService:JSONEncode(SavedMinimal)

	local savedStr = getgenv().SavedStatesJSON and
		(string.format("game:GetService('HttpService'):JSONDecode([[%s]])", getgenv().SavedStatesJSON))
		or "nil"

	queue_on_teleport([[
        getgenv().SavedStates = ]]..savedStr..[[

        loadstring(game:HttpGet("https://raw.githubusercontent.com/OkamuraYuji/note/refs/heads/main/opm.lua"))()

        if getgenv().SavedStates then
            States.AutoChest = getgenv().SavedStates.AutoChest
            States.Hop = getgenv().SavedStates.Hop

            -- Nếu AutoChest true thì bật lại loop
            if States.AutoChest then
                task.spawn(function()
                    local btn = Frame:FindFirstChild("AutoChestBtn", true)
                    if btn and btn:IsA("TextButton") then
                        btn:Activate()
                    end
                end)
            end
        end
    ]])

	callback()
end


-- === MAIN TAB ===
local function LoadMain()
	ClearContent()

	-- Auto Chest
	local chestBtn = Instance.new("TextButton", Frame_3)
	chestBtn.Size = UDim2.new(1, -20, 0, 40)
	chestBtn.Position = UDim2.new(0, 10, 0, 10)
	chestBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	chestBtn.Text = "Auto Chest: OFF"
	chestBtn.Font = Enum.Font.GothamBold
	chestBtn.TextColor3 = Color3.new(1,1,1)
	chestBtn.TextSize = 16

	chestBtn.MouseButton1Click:Connect(function()
		autoChest = not autoChest
		States.AutoChest = autoChest
		chestBtn.Text = "Auto Chest: " .. (autoChest and "ON" or "OFF")
		chestBtn.BackgroundColor3 = autoChest and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
		if autoChest then
			if chestThread then task.cancel(chestThread) end
			chestThread = task.spawn(function()
				while autoChest do
					local chests = workspace:FindFirstChild("Chests")
					local found = false
					if chests and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						for _, chest in ipairs(chests:GetChildren()) do
							if not autoChest then break end
							if chest:IsA("Model") and chest.PrimaryPart then
								found = true
								player.Character.HumanoidRootPart.CFrame = chest.PrimaryPart.CFrame + Vector3.new(0,3,0)
								task.wait(0.1)
							end
						end
					end

					-- Nếu không có chest nào và hopEnabled thì hop
					if not found and hopEnabled then
						teleportWithSave(function()
							local servers = HttpService:JSONDecode(game:HttpGet(
								"https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
								))
							for _,srv in ipairs(servers.data) do
								if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
									TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player)
									break
								end
							end
						end)
					end

					task.wait(0.3)
				end
			end)
		else
			if chestThread then task.cancel(chestThread) chestThread = nil end
		end
	end)

	-- Server Hop
	local hopBtn = Instance.new("TextButton", Frame_3)
	hopBtn.Size = UDim2.new(1, -20, 0, 40)
	hopBtn.Position = UDim2.new(0, 10, 0, 60)
	hopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	hopBtn.Text = "Server Hop: OFF"
	hopBtn.Font = Enum.Font.GothamBold
	hopBtn.TextColor3 = Color3.new(1,1,1)
	hopBtn.TextSize = 16

	hopBtn.MouseButton1Click:Connect(function()
		hopEnabled = not hopEnabled
		States.Hop = hopEnabled
		hopBtn.Text = "Server Hop: " .. (hopEnabled and "ON" or "OFF")
		hopBtn.BackgroundColor3 = hopEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
	end)
end

-- === PLAYER TAB ===
local function LoadPlayer()
	ClearContent()

	-- WalkSpeed
	local wsBtn = Instance.new("TextButton", Frame_3)
	wsBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	wsBtn.Position = UDim2.new(0, 10, 0, 10)
	wsBtn.Size = UDim2.new(0.7, 0, 0, 40)
	wsBtn.Text = "WalkSpeed:"
	wsBtn.Font = Enum.Font.GothamBold
	wsBtn.TextColor3 = Color3.new(1,1,1)
	wsBtn.TextSize = 18

	local wsBox = Instance.new("TextBox", wsBtn)
	wsBox.Size = UDim2.new(0, 40, 0, 35)
	wsBox.Position = UDim2.new(1, 10, 0, 0)
	wsBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	wsBox.Text = "16"
	wsBox.Font = Enum.Font.GothamBold
	wsBox.TextColor3 = Color3.new(1,1,1)
	wsBox.TextScaled = true

	wsBox.FocusLost:Connect(function(enter)
		if enter then
			local val = tonumber(wsBox.Text)
			if val and val >= 16 then
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
				end
			else
				wsBox.Text = "16"
			end
		end
	end)

	-- JumpPower
	local jpBtn = Instance.new("TextButton", Frame_3)
	jpBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	jpBtn.Position = UDim2.new(0, 10, 0, 60)
	jpBtn.Size = UDim2.new(0.7, 0, 0, 40)
	jpBtn.Text = "JumpPower:"
	jpBtn.Font = Enum.Font.GothamBold
	jpBtn.TextColor3 = Color3.new(1,1,1)
	jpBtn.TextSize = 18

	local jpBox = Instance.new("TextBox", jpBtn)
	jpBox.Size = UDim2.new(0, 40, 0, 35)
	jpBox.Position = UDim2.new(1, 10, 0, 0)
	jpBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	jpBox.Text = "50"
	jpBox.Font = Enum.Font.GothamBold
	jpBox.TextColor3 = Color3.new(1,1,1)
	jpBox.TextScaled = true

	jpBox.FocusLost:Connect(function(enter)
		if enter then
			local val = tonumber(jpBox.Text)
			if val and val >= 50 then
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
				end
			else
				jpBox.Text = "50"
			end
		end
	end)

	-- Flight
	local flyBtn = Instance.new("TextButton", Frame_3)
	flyBtn.BackgroundColor3 = Color3.fromRGB(170,0,170)
	flyBtn.Position = UDim2.new(0, 10, 0, 110)
	flyBtn.Size = UDim2.new(0.7, 0, 0, 40)
	flyBtn.Text = "Flight: OFF"
	flyBtn.Font = Enum.Font.GothamBold
	flyBtn.TextColor3 = Color3.new(1,1,1)
	flyBtn.TextSize = 18

	local flySpeedBox = Instance.new("TextBox", flyBtn)
	flySpeedBox.Size = UDim2.new(0, 50, 0, 35)
	flySpeedBox.Position = UDim2.new(1, 10, 0, 0)
	flySpeedBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	flySpeedBox.Text = tostring(flightSpeed)
	flySpeedBox.Font = Enum.Font.GothamBold
	flySpeedBox.TextColor3 = Color3.new(1,1,1)
	flySpeedBox.TextScaled = true

	flyBtn.MouseButton1Click:Connect(function()
		flightEnabled = not flightEnabled
		flyBtn.Text = "Flight: " .. (flightEnabled and "ON" or "OFF")
		flyBtn.BackgroundColor3 = flightEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,170)

		if flightEnabled then
			if flyConnection then flyConnection:Disconnect() end
			flyConnection = RunService.RenderStepped:Connect(function()
				if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
				local hrp = player.Character.HumanoidRootPart
				local camCF = workspace.CurrentCamera.CFrame
				local moveDir = Vector3.new()

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end

				if moveDir.Magnitude > 0 then
					hrp.Velocity = moveDir.Unit * flightSpeed
				else
					hrp.Velocity = Vector3.new(0,0,0)
				end
			end)
		else
			if flyConnection then flyConnection:Disconnect() flyConnection = nil end
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
			end
		end
	end)

	flySpeedBox.FocusLost:Connect(function(enter)
		if enter then
			local val = tonumber(flySpeedBox.Text)
			if val and val > 0 then
				flightSpeed = val
			else
				flySpeedBox.Text = tostring(flightSpeed)
			end
		end
	end)
end

-- === Tab switching ===
MainBtn.MouseButton1Click:Connect(function()
	MainBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
	PlayerBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	LoadMain()
end)

PlayerBtn.MouseButton1Click:Connect(function()
	PlayerBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
	MainBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	LoadPlayer()
end)

-- Close/minimize
CloseBtn.MouseButton1Click:Connect(function()
	yjing:Destroy()
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	Frame_3.Visible = not minimized
	Sidebar.Visible = not minimized
	Frame.Size = minimized and UDim2.new(0,295,0,30) or UDim2.new(0,295,0,220)
end)

-- Load mặc định
LoadMain()
