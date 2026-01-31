local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

getgenv().auto = getgenv().auto or true
local chestThread

local function teleportWithSave(callback)
    local SavedMinimal = { Auto = getgenv().auto }
    getgenv().SavedStatesJSON = HttpService:JSONEncode(SavedMinimal)

    local savedStr = getgenv().SavedStatesJSON and
        (string.format("game:GetService('HttpService'):JSONDecode([[%s]])", getgenv().SavedStatesJSON))
        or "nil"

    queue_on_teleport([[ 
        getgenv().SavedStates = ]]..savedStr..[[

        loadstring(game:HttpGet("https://raw.githubusercontent.com/OkamuraYuji/note/refs/heads/main/auto.lua"))()

        if getgenv().SavedStates and getgenv().SavedStates.Auto then
            getgenv().auto = true
        end
    ]])

    callback()
end

if getgenv().auto then
    if chestThread then task.cancel(chestThread) end
    chestThread = task.spawn(function()
        while getgenv().auto do
            local chests = workspace:FindFirstChild("Chests")
            local found = false

            if chests and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                for _, chest in ipairs(chests:GetChildren()) do
                    if not getgenv().auto then break end
                    if chest:IsA("Model") and chest.PrimaryPart then
                        found = true
                        print("[⚡ AutoChest] Teleporting to chest:", chest.Name)
                        player.Character.HumanoidRootPart.CFrame = chest.PrimaryPart.CFrame + Vector3.new(0,3,0)
                        task.wait(0.1)
                    end
                end
            end

            if not found then
                print("[⚡ AutoHop] Không tìm thấy chest, đang tìm server mới...")
                teleportWithSave(function()
                    local ok, servers = pcall(function()
                        return HttpService:JSONDecode(game:HttpGet(
                            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
                        ))
                    end)

                    if ok and servers and servers.data then
                        local hopped = false
                        for _,srv in ipairs(servers.data) do
                            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                                print("[⚡ AutoHop] Đang chuyển tới server:", srv.id, "Players:", srv.playing.."/"..srv.maxPlayers)
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player)
                                hopped = true
                                break
                            end
                        end
                        if not hopped then
                            print("[⚠️ AutoHop] Không tìm thấy server khả dụng.")
                        end
                    else
                        warn("[❌ AutoHop] Lỗi khi lấy danh sách server.")
                    end
                end)
            end

            task.wait(0.3)
        end
        print("[⏹️ AutoChest] Đã dừng.")
    end)
end
