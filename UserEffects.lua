-- UserEffects Library - CC April Hub
-- Version: 1.1

local UserEffects = {}
UserEffects.__index = UserEffects

local users = {
    ["burrylerry"] = {
        tag = "April Hub Dev",
        effect = "rainbow"
    },
    ["burryterry"] = {
        tag = "April Hub Dev", 
        effect = "rainbow"
    },
    ["burrybeddy"] = {
        tag = "April Hub Owner",
        effect = "pulse"
    }
}

local effects = {
    ["rainbow"] = {
        color = nil, 
        animation = function(textLabel)
            local RunService = game:GetService("RunService")
            local lastUpdate = 0
            local connection = RunService.Heartbeat:Connect(function()
                if not textLabel or not textLabel.Parent then
                    connection:Disconnect()
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
            return connection
        end
    },
    
    ["pulse"] = {
        color = Color3.fromRGB(255, 165, 0), 
        animation = function(textLabel)
            local RunService = game:GetService("RunService")
            local lastUpdate = 0
            local connection = RunService.Heartbeat:Connect(function()
                if not textLabel or not textLabel.Parent then
                    connection:Disconnect()
                    return
                end
                
                local currentTime = tick()
                if currentTime - lastUpdate >= 0.05 then
                    local pulse = math.sin(currentTime * 3) * 0.3 + 0.7
                    textLabel.TextTransparency = 1 - pulse
                    lastUpdate = currentTime
                end
            end)
            return connection
        end
    },
    
    ["glow"] = {
        color = Color3.fromRGB(255, 215, 0), 
        animation = function(textLabel)
            local RunService = game:GetService("RunService")
            local lastUpdate = 0
            local connection = RunService.Heartbeat:Connect(function()
                if not textLabel or not textLabel.Parent then
                    connection:Disconnect()
                    return
                end
                
                local currentTime = tick()
                if currentTime - lastUpdate >= 0.08 then
                    local glow = math.sin(currentTime * 2) * 0.2 + 0.8
                    textLabel.TextStrokeTransparency = 1 - glow
                    lastUpdate = currentTime
                end
            end)
            return connection
        end
    },
    
    ["static"] = {
        color = Color3.fromRGB(52, 152, 219),
        animation = nil 
    },
    
    ["fade"] = {
        color = Color3.fromRGB(155, 89, 182), 
        animation = function(textLabel)
            local RunService = game:GetService("RunService")
            local lastUpdate = 0
            local connection = RunService.Heartbeat:Connect(function()
                if not textLabel or not textLabel.Parent then
                    connection:Disconnect()
                    return
                end
                
                local currentTime = tick()
                if currentTime - lastUpdate >= 0.1 then
                    local fade = math.sin(currentTime * 1.5) * 0.4 + 0.6
                    textLabel.TextTransparency = 1 - fade
                    lastUpdate = currentTime
                end
            end)
            return connection
        end
    },
    
    ["fire"] = {
        color = Color3.fromRGB(255, 69, 0), 
        animation = function(textLabel)
            local RunService = game:GetService("RunService")
            local lastUpdate = 0
            local connection = RunService.Heartbeat:Connect(function()
                if not textLabel or not textLabel.Parent then
                    connection:Disconnect()
                    return
                end
                
                local currentTime = tick()
                if currentTime - lastUpdate >= 0.06 then
                    local flicker = math.random() * 0.3 + 0.7
                    local heatHue = (math.sin(currentTime * 2) * 0.1 + 0.05) 
                    local color = Color3.fromHSV(heatHue, 1, flicker)
                    textLabel.TextColor3 = color
                    lastUpdate = currentTime
                end
            end)
            return connection
        end
    }
}

function UserEffects.new()
    local self = setmetatable({}, UserEffects)
    return self
end

function UserEffects.isUser(username)
    return users[string.lower(username)] ~= nil
end

function UserEffects.getUserConfig(username)
    return users[string.lower(username)]
end

function UserEffects.getUserDisplayInfo(username)
    local userConfig = users[string.lower(username)]
    if userConfig then
        local effect = effects[userConfig.effect]
        return {
            displayName = userConfig.tag,
            isDeveloper = userConfig.tag:find("Dev") ~= nil, 
            hasAnimation = effect and effect.animation ~= nil,
            effectName = userConfig.effect,
            color = effect and effect.color or Color3.fromRGB(255, 255, 255)
        }
    end
    
    return {
        displayName = "April Hub User",
        isDeveloper = false,
        hasAnimation = false,
        effectName = "static",
        color = Color3.fromRGB(52, 152, 219)
    }
end

function UserEffects.applyEffect(textLabel, effectName)
    local effect = effects[effectName]
    if not effect then
        warn("[UserEffects] Effect '" .. effectName .. "' not found!")
        return nil
    end
    
    if effect.color then
        textLabel.TextColor3 = effect.color
    end
    
    if effect.animation then
        return effect.animation(textLabel)
    end
    
    return nil
end

function UserEffects.getAllUsers()
    local userList = {}
    for username, config in pairs(users) do
        table.insert(userList, {
            username = username,
            tag = config.tag,
            effect = config.effect
        })
    end
    return userList
end

function UserEffects.getAllEffects()
    local effectList = {}
    for effectName, _ in pairs(effects) do
        table.insert(effectList, effectName)
    end
    return effectList
end

function UserEffects.addUser(username, tag, effect)
    if not effects[effect] then
        warn("[UserEffects] Effect '" .. effect .. "' does not exist!")
        return false
    end
    
    users[string.lower(username)] = {
        tag = tag,
        effect = effect
    }
    print("[UserEffects] Added user:", username, "with tag:", tag, "and effect:", effect)
    return true
end

function UserEffects.removeUser(username)
    if users[string.lower(username)] then
        users[string.lower(username)] = nil
        print("[UserEffects] Removed user:", username)
        return true
    end
    return false
end

function UserEffects.createEffect(name, color, animationFunction)
    effects[name] = {
        color = color,
        animation = animationFunction
    }
    print("[UserEffects] Created new effect:", name)
end

function UserEffects.debugInfo()
    print("[UserEffects] === DEBUG INFO ===")
    print("Registered Users:")
    for username, config in pairs(users) do
        print("  " .. username .. " -> " .. config.tag .. " (" .. config.effect .. ")")
    end
    print("Available Effects:")
    for effectName, _ in pairs(effects) do
        print("  " .. effectName)
    end
    print("[UserEffects] === END DEBUG ===")
end

local UserEffectsModule = {
    isUser = UserEffects.isUser,
    getUserConfig = UserEffects.getUserConfig,
    getUserDisplayInfo = UserEffects.getUserDisplayInfo,
    applyEffect = UserEffects.applyEffect,
    
    getAllUsers = UserEffects.getAllUsers,
    getAllEffects = UserEffects.getAllEffects,
    addUser = UserEffects.addUser,
    removeUser = UserEffects.removeUser,
    createEffect = UserEffects.createEffect,
    
    debugInfo = UserEffects.debugInfo,
    
    new = UserEffects.new
}

return UserEffectsModule
