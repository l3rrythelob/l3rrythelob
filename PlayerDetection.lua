-- April Hub Player Detection Library
-- Version: 2.1 - UserEffects Integration
-- Author: April Hub Team

local PlayerDetection = {}
PlayerDetection.__index = PlayerDetection

function PlayerDetection.new(config)
    local self = setmetatable({}, PlayerDetection)
    
    -- Use config if provided, otherwise use empty table for defaults
    config = config or {}
    
    -- Services
    self.services = {
        HttpService = game:GetService("HttpService"),
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService")
    }
    
    -- Configuration with built-in defaults
    self.config = {
        SERVER_URL = config.serverUrl or "http://92.112.125.62:3000",
        HEARTBEAT_INTERVAL = config.heartbeatInterval or 10,
        USER_POLL_INTERVAL = config.userPollInterval or 12,
        REQUEST_TIMEOUT = config.requestTimeout or 8,
        USER_EFFECTS_URL = config.userEffectsUrl or "https://raw.githubusercontent.com/l3rrythelob/AprilHUB-UI/refs/heads/main/UserEffects.lua",
        showNotifications = config.showNotifications ~= false, -- Default true
        notificationLib = config.notificationLib or nil -- Pass your notification library (Orion, etc.)
    }
    
    -- Internal state
    self.state = {
        isConnected = false,
        heartbeatConnection = nil,
        userDisplayGuis = {},
        playerScanConnection = nil,
        pendingRequests = 0,
        maxConcurrentRequests = 2,
        cleanupExecuted = false,
        knownPlayers = {},
        lastPlayerList = {},
        initialScanComplete = false,
        effectConnections = {} -- Store animation connections
    }
    
    self.player = self.services.Players.LocalPlayer
    self.placeId = tostring(game.PlaceId)
    
    -- Load UserEffects library
    self.userEffects = nil
    
    return self
end

-- Load UserEffects library from GitHub
function PlayerDetection:loadUserEffects()
    local success, result = pcall(function()
        local UserEffects = loadstring(game:HttpGet(self.config.USER_EFFECTS_URL))()
        self.userEffects = UserEffects
        print("[PlayerDetection] Loaded UserEffects library successfully!")
        
        -- Print loaded users for debugging
        local users = UserEffects.getAllUsers()
        local userNames = {}
        for _, user in ipairs(users) do
            table.insert(userNames, user.username .. " (" .. user.tag .. ")")
        end
        print("[PlayerDetection] Registered users:", table.concat(userNames, ", "))
        
        return true
    end)
    
    if not success then
        warn("[PlayerDetection] Failed to load UserEffects library:", result)
        -- Create fallback UserEffects
        self.userEffects = {
            isUser = function() return false end,
            getUserDisplayInfo = function(username)
                return {
                    displayName = "April Hub User",
                    isDeveloper = false,
                    hasAnimation = false,
                    effectName = "static",
                    color = Color3.fromRGB(52, 152, 219)
                }
            end,
            applyEffect = function() return nil end
        }
        return false
    end
    
    return success
end

function PlayerDetection:getUserDisplayInfo(username)
    -- Fallback method - should primarily use server data now
    return {
        displayName = "April Hub User",
        isDeveloper = false,
        hasAnimation = false,
        effectName = "static",
        color = Color3.fromRGB(52, 152, 219)
    }
end

function PlayerDetection:createUserDisplay(player, displayInfo)
    if not player.Character or not player.Character:FindFirstChild("Head") then
        return nil
    end
    
    local head = player.Character.Head
    local username = player.Name
    
    -- Remove existing display
    if head:FindFirstChild("AprilHubDisplay") then
        head.AprilHubDisplay:Destroy()
    end
    
    -- Clean up any existing effect connections for this user
    if self.state.effectConnections[username] then
        self.state.effectConnections[username]:Disconnect()
        self.state.effectConnections[username] = nil
    end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "AprilHubDisplay"
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Enabled = true
    billboardGui.Parent = head
    
    local frame = Instance.new("Frame")
    frame.Name = "Background"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = billboardGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "DisplayText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = displayInfo.displayName

    if displayInfo.color then
        local r, g, b = displayInfo.color:match("(%d+),(%d+),(%d+)")
        textLabel.TextColor3 = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
    elseif displayInfo.effectName == "rainbow" or displayInfo.hasAnimation then
        textLabel.TextColor3 = Color3.new(1, 1, 1) 
    else
        textLabel.TextColor3 = Color3.fromRGB(52, 152, 219)
    end
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = frame
    
    -- Apply effects based on server response
    if displayInfo.hasRainbowAnimation or displayInfo.effectName == "rainbow" then
        local connection
        local lastUpdate = 0
        connection = self.services.RunService.Heartbeat:Connect(function()
            if not textLabel or not textLabel.Parent or not billboardGui.Parent then
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                return
            end
            
            local currentTime = tick()
            if currentTime - lastUpdate >= 0.1 then
                local hue = (currentTime * 0.5) % 1
                local color = Color3.fromHSV(hue, 1, 1)
                textLabel.TextColor3 = color
                lastUpdate = currentTime
            end
        end)
        
        self.state.effectConnections[username] = connection
        print("[PlayerDetection] Applied rainbow effect to", username)
        
    elseif displayInfo.effectName == "pulse" then
        -- Pulse effect
        local connection
        local lastUpdate = 0
        connection = self.services.RunService.Heartbeat:Connect(function()
            if not textLabel or not textLabel.Parent or not billboardGui.Parent then
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                return
            end
            
            local currentTime = tick()
            if currentTime - lastUpdate >= 0.05 then
                local pulse = math.sin(currentTime * 3) * 0.3 + 0.7
                textLabel.TextTransparency = 1 - pulse
                lastUpdate = currentTime
            end
        end)
        
        self.state.effectConnections[username] = connection
        print("[PlayerDetection] Applied pulse effect to", username)
        
    elseif displayInfo.effectName == "glow" then
        local connection
        local lastUpdate = 0
        connection = self.services.RunService.Heartbeat:Connect(function()
            if not textLabel or not textLabel.Parent or not billboardGui.Parent then
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                return
            end
            
            local currentTime = tick()
            if currentTime - lastUpdate >= 0.08 then
                local glow = math.sin(currentTime * 2) * 0.2 + 0.8
                textLabel.TextStrokeTransparency = 1 - glow
                lastUpdate = currentTime
            end
        end)
        
        self.state.effectConnections[username] = connection
        print("[PlayerDetection] Applied glow effect to", username)
        
    else
        if displayInfo.isDeveloper then
            textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for devs
        else
            textLabel.TextColor3 = Color3.fromRGB(52, 152, 219) -- Blue for users
        end
        print("[PlayerDetection] Applied static color to", username)
    end
    
    return billboardGui
end

function PlayerDetection:removeUserDisplay(username)
    if self.state.userDisplayGuis[username] then
        local gui = self.state.userDisplayGuis[username]
        gui:Destroy()
        self.state.userDisplayGuis[username] = nil
    end
    
    -- Clean up effect connection
    if self.state.effectConnections[username] then
        self.state.effectConnections[username]:Disconnect()
        self.state.effectConnections[username] = nil
    end
end

function PlayerDetection:sendToServer(endpoint, data, callback)
    if self.state.pendingRequests >= self.state.maxConcurrentRequests then
        if callback then callback(nil, "Rate limited") end
        return
    end
    
    self.state.pendingRequests = self.state.pendingRequests + 1
    
    spawn(function()
        local request = http_request or request or HttpPost or syn.request
        
        if not request then
            self.state.pendingRequests = self.state.pendingRequests - 1
            if callback then callback(nil, "No HTTP function") end
            return
        end
        
        local success, result = pcall(function()
            local requestData = {
                Url = self.config.SERVER_URL .. endpoint,
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Timeout = self.config.REQUEST_TIMEOUT
            }
            
            if endpoint == "/api/users" then
                requestData.Method = "GET"
            else
                requestData.Method = "POST"
                requestData.Body = self.services.HttpService:JSONEncode(data)
            end
            
            local response = request(requestData)
            
            if response and response.StatusCode == 200 and response.Body then
                return self.services.HttpService:JSONDecode(response.Body)
            end
            return nil
        end)
        
        self.state.pendingRequests = self.state.pendingRequests - 1
        
        if callback then
            if success and result then
                callback(result)
            else
                callback(nil, result or "Request failed")
            end
        end
    end)
end

function PlayerDetection:showUserNotification(username, displayInfo, isJoining)
    if not self.config.showNotifications or not self.config.notificationLib then return end
    
    local action = isJoining and "joined" or "left"
    local message = username .. " " .. action .. " with " .. displayInfo.displayName
    
    -- Support different notification libraries
    if self.config.notificationLib.MakeNotification then
        -- Orion Library
        self.config.notificationLib:MakeNotification({
            Name = isJoining and "User Joined" or "User Left",
            Content = message,
            Image = "rbxassetid://4483345998",
            Time = 4
        })
    elseif self.config.notificationLib.Notification then
        -- Other libraries
        self.config.notificationLib:Notification({
            Title = isJoining and "User Joined" or "User Left",
            Content = message,
            Duration = 4
        })
    else
        -- Fallback to print
        print("[PlayerDetection]", message)
    end
end

function PlayerDetection:pollServerForNewUsers()
    if not self.state.isConnected then return end
    
    self:sendToServer("/api/users", {}, function(response, error)
        if response and type(response) == "table" then
            local usersInThisPlace = {}
            
            -- Filter users in the same place
            for _, user in pairs(response) do
                if user.placeId == self.placeId and user.username ~= self.player.Name then
                    usersInThisPlace[user.username] = user
                end
            end
            
            -- Check for new users
            for username, userData in pairs(usersInThisPlace) do
                local player = self.services.Players:FindFirstChild(username)
                if player and not self.state.knownPlayers[username] then
                    self.state.knownPlayers[username] = true
                    
                    if player.Character and player.Character:FindFirstChild("Head") then
                        local displayInfo = userData.displayInfo or self:getUserDisplayInfo(username)
                        self.state.userDisplayGuis[username] = self:createUserDisplay(player, displayInfo)
                        self:showUserNotification(username, displayInfo, true)
                    end
                end
            end
            
            -- Check for users who left
            local currentKnownUsers = {}
            for username, _ in pairs(self.state.knownPlayers) do
                if username ~= self.player.Name then
                    currentKnownUsers[username] = true
                end
            end
            
            for username, _ in pairs(currentKnownUsers) do
                if not usersInThisPlace[username] then
                    local displayInfo = self:getUserDisplayInfo(username)
                    self:showUserNotification(username, displayInfo, false)
                    self:removeUserDisplay(username)
                    self.state.knownPlayers[username] = nil
                end
            end
        end
    end)
end

function PlayerDetection:startHeartbeat()
    if self.state.heartbeatConnection then
        self.state.heartbeatConnection:Disconnect()
    end
    
    local lastHeartbeat = 0
    local lastUserPoll = 0
    
    self.state.heartbeatConnection = self.services.RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Send heartbeat
        if currentTime - lastHeartbeat >= self.config.HEARTBEAT_INTERVAL then
            lastHeartbeat = currentTime
            
            self:sendToServer("/api/heartbeat", {
                username = self.player.Name,
                placeId = self.placeId
            })
        end
        
        -- Poll for new users
        if currentTime - lastUserPoll >= self.config.USER_POLL_INTERVAL then
            lastUserPoll = currentTime
            self:pollServerForNewUsers()
        end
    end)
end

function PlayerDetection:joinServer()
    self:sendToServer("/api/join", {
        username = self.player.Name,
        placeId = self.placeId
    }, function(response, error)
        if response and response.success then
            self.state.isConnected = true
            print("[PlayerDetection] Connected to server successfully!")
            
            -- Use the server's displayInfo instead of generating our own
            local serverDisplayInfo = response.userInfo.displayInfo
            self.state.knownPlayers[self.player.Name] = true
            
            if self.player.Character and self.player.Character:FindFirstChild("Head") then
                self.state.userDisplayGuis[self.player.Name] = self:createUserDisplay(self.player, serverDisplayInfo)
            end
            
            -- Display existing users with their server-provided display info
            if response.usersInPlace then
                for _, user in pairs(response.usersInPlace) do
                    local existingPlayer = self.services.Players:FindFirstChild(user.username)
                    if existingPlayer and existingPlayer ~= self.player then
                        self.state.knownPlayers[user.username] = true
                        -- Use the server-provided displayInfo
                        self.state.userDisplayGuis[user.username] = self:createUserDisplay(existingPlayer, user.displayInfo)
                    end
                end
            end
            
            self:startHeartbeat()
            
        else
            warn("[PlayerDetection] Failed to connect to server, retrying in 10 seconds...")
            wait(10)
            if not self.state.isConnected then
                self:joinServer()
            end
        end
    end)
end

function PlayerDetection:disconnect()
    if self.state.cleanupExecuted then return end
    self.state.cleanupExecuted = true
    
    print("[PlayerDetection] Disconnecting...")
    
    -- Stop heartbeat
    if self.state.heartbeatConnection then
        self.state.heartbeatConnection:Disconnect()
        self.state.heartbeatConnection = nil
    end
    
    -- Clean up displays and effect connections
    for username, gui in pairs(self.state.userDisplayGuis) do
        if gui and gui.Parent then
            gui:Destroy()
        end
        if self.state.effectConnections[username] then
            self.state.effectConnections[username]:Disconnect()
        end
    end
    self.state.userDisplayGuis = {}
    self.state.effectConnections = {}
    
    self.state.isConnected = false
    
    -- Send disconnect signal
    spawn(function()
        local httpRequest = http_request or request or HttpPost or syn.request
        if httpRequest and self.player then
            pcall(function()
                httpRequest({
                    Url = self.config.SERVER_URL .. "/api/disconnect",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = self.services.HttpService:JSONEncode({
                        username = self.player.Name,
                        placeId = self.placeId
                    }),
                    Timeout = 5
                })
            end)
        end
    end)
end

function PlayerDetection:setupDisconnectHandlers()
    -- Handle player leaving
    self.services.Players.PlayerRemoving:Connect(function(player)
        if player == self.player then
            self:disconnect()
        end
    end)
    
    -- Handle character removal
    self.player.CharacterRemoving:Connect(function()
        spawn(function()
            wait(3)
            if not self.player.Character then
                self:disconnect()
            end
        end)
    end)
end

function PlayerDetection:initialize()
    print("[PlayerDetection] Initializing player detection system...")
    
    -- Remove this line - don't load UserEffects client-side anymore
    -- if not self:loadUserEffects() then
    --     warn("[PlayerDetection] Failed to load UserEffects, using fallback system")
    -- end
    
    -- Wait for character
    local character = self.player.Character or self.player.CharacterAdded:Wait()
    if not character:FindFirstChild("Head") then
        character:WaitForChild("Head")
    end
    
    -- Setup disconnect handlers
    self:setupDisconnectHandlers()
    
    -- Join server
    self:joinServer()
    
    print("[PlayerDetection] Player detection system initialized!")
end

-- Public API methods
function PlayerDetection:getKnownPlayers()
    return self.state.knownPlayers
end

function PlayerDetection:isUserRegistered(username)
    return self.userEffects and self.userEffects.isUser(username)
end

function PlayerDetection:getPlayerDisplayInfo(username)
    return self:getUserDisplayInfo(username)
end

-- Admin functions (if needed)
function PlayerDetection:getAllRegisteredUsers()
    if self.userEffects and self.userEffects.getAllUsers then
        return self.userEffects.getAllUsers()
    end
    return {}
end

function PlayerDetection:getAllAvailableEffects()
    if self.userEffects and self.userEffects.getAllEffects then
        return self.userEffects.getAllEffects()
    end
    return {}
end

return PlayerDetection
