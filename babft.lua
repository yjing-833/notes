--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Clear old UI
if playerGui:FindFirstChild("FarmGui") then
    playerGui.FarmGui:Destroy()
end

--------------------------------------------------
-- UI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "FarmGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Main Frame
local main = Instance.new("Frame")
main.Size = UDim2.fromScale(0.15, 0.13)
main.Position = UDim2.fromScale(0.03, 0.83)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

local stroke = Instance.new("UIStroke", main)
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(60,60,60)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0.3,0)
titleBar.BackgroundTransparency = 1
titleBar.Parent = main

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-20,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "AUTO FARM"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Toggle Holder
local toggleHolder = Instance.new("Frame")
toggleHolder.Size = UDim2.new(1,-40,0.3,0)
toggleHolder.Position = UDim2.new(0,20,0.45,0)
toggleHolder.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleHolder.Parent = main
Instance.new("UICorner", toggleHolder).CornerRadius = UDim.new(1,0)

-- Toggle Circle
local toggleCircle = Instance.new("Frame")
toggleCircle.Size = UDim2.new(0,26,0,26)
toggleCircle.Position = UDim2.new(0,4,0.5,-13)
toggleCircle.BackgroundColor3 = Color3.fromRGB(200,60,60)
toggleCircle.Parent = toggleHolder
Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1,0)

-- Toggle Text
local toggleText = Instance.new("TextLabel")
toggleText.Size = UDim2.new(1,-50,1,0)
toggleText.Position = UDim2.new(0,0,0,0)
toggleText.BackgroundTransparency = 1
toggleText.Text = "Auto Farm: OFF"
toggleText.Font = Enum.Font.Gotham
toggleText.TextSize = 14
toggleText.TextColor3 = Color3.fromRGB(220,220,220)
toggleText.TextXAlignment = Enum.TextXAlignment.Right
toggleText.Parent = toggleHolder

-- Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1,0,1,0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.Parent = toggleHolder

--------------------------------------------------
-- DRAG UI
--------------------------------------------------

local dragging, dragStart, startPos

titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

--------------------------------------------------
-- AUTO FARM
--------------------------------------------------

local positions = {
    Vector3.new(-40,35,1371), Vector3.new(-61,33,2140),
    Vector3.new(-76,41,2909), Vector3.new(-87,42,3678),
    Vector3.new(-41,48,4450), Vector3.new(-88,54,5220),
    Vector3.new(-63,49,5990), Vector3.new(-83,63,6759),
    Vector3.new(-64,51,7530), Vector3.new(-99,49,8298),
    Vector3.new(-120,179,9132), Vector3.new(-56,-359,9496)
}

local enabled = false
local noclipConn, bv

local function noclip(on)
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            for _,v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end)
    elseif noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
end

local function antiFall(hrp, on)
    if on then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(0,math.huge,0)
        bv.Parent = hrp
    elseif bv then
        bv:Destroy()
        bv = nil
    end
end

local function startFarm()
    task.spawn(function()
        while enabled do
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            noclip(true)
            antiFall(hrp,true)

            for _,pos in ipairs(positions) do
                if not enabled then break end
                TweenService:Create(hrp, TweenInfo.new(2), {
                    CFrame = CFrame.new(pos)
                }):Play()
                task.wait(2)
            end

            noclip(false)
            antiFall(hrp,false)
            task.wait(15)
        end
    end)
end

--------------------------------------------------
-- TOGGLE LOGIC + ANIMATION
--------------------------------------------------

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled

    -- Circle
    TweenService:Create(toggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = enabled and UDim2.new(1,-30,0.5,-13) or UDim2.new(0,4,0.5,-13),
        BackgroundColor3 = enabled and Color3.fromRGB(60,200,120) or Color3.fromRGB(200,60,60)
    }):Play()

    -- Text fly
    TweenService:Create(toggleText, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = enabled and UDim2.new(0,10,0,0) or UDim2.new(0,0,0,0)
    }):Play()

    toggleText.TextXAlignment = enabled and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
    toggleText.Text = enabled and "Auto Farm: ON" or "Auto Farm: OFF"

    if enabled then
        startFarm()
    else
        noclip(false)
        antiFall(nil,false)
    end
end)
