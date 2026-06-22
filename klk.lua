--[[
    OG HUB - V4.1 (Optimized Core)
    - Internal Refactor: Consolidated repetitive functions into smart handlers.
    - Centralized State: All runtime data is now managed in a single table for cleaner resets.
    - Performance: Improved event handling and memory management.
    - All previous fixes (Colors, Headless, SpongeBob, Respawn) are preserved.
]]

if getgenv().OGHubLoaded then return end

-- // Services \\ --
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- // Library Loading \\ --
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local success, Library = pcall(function() return loadstring(game:HttpGet(repo .. "Library.lua"))() end)
if not success or not Library then
    warn("OG HUB: Library failed to load.")
    return
end

local sT, ThemeManager = pcall(function() return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))() end)
local sS, SaveManager = pcall(function() return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))() end)
ThemeManager = sT and ThemeManager or nil
SaveManager = sS and SaveManager or nil

getgenv().OGHubLoaded = true
local Player = Players.LocalPlayer

-- // UI Setup \\ --
local Window = Library:CreateWindow({
    Name = "OG HUB",
    Title = "OG HUB",
    SubTitle = "Optimized by MrOG & AI",
    Draggable = true,
    Footer = "Made By gemini & Thank him | v1.2.0"
})

-- // Configuration & Constants \\ --
local CONFIG = {
    RenderName = "OG_HUB_SkyUpdate",
    RainbowSpeed = 0.5,
    AssetIDs = {
        HeadlessMesh = "http://www.roblox.com/asset/?id=134079402",
        HeadlessTex = "http://www.roblox.com/asset/?id=133940918",
        FaceTexture = "http://www.roblox.com/asset/?id=42070872",
        KorbloxLeg = "rbxassetid://902942093",
        KorbloxUpper = "rbxassetid://902942096",
        KorbloxTex = "rbxassetid://902843398",
        KorbloxFoot = "rbxassetid://902942089"
    },
    LimbMappings = {
        Head = { "Head" },
        Torso = { "UpperTorso", "LowerTorso", "Torso" },
        LeftArm = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm" },
        RightArm = { "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm" },
        LeftLeg = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg" },
        RightLeg = { "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" },
    },
    Clothing = {
        Shirt = { ["None"] = nil },
        Pants = { ["None"] = nil },
        TShirt = { ["None"] = nil, ["Oh Noez!"] = "http://www.roblox.com/asset/?id=1641286", ["Spread The Lulz!"] = "http://www.roblox.com/asset/?id=24774765" }
    },
    Animations = {
        ["None"] = {},
        ["Vampire"] = { idle = { "rbxassetid://1083445855", "rbxassetid://1083450166" }, walk = "rbxassetid://1083473930", run = "rbxassetid://1083462077", jump = "rbxassetid://1083455352", fall = "rbxassetid://1083443587", climb = "rbxassetid://1083439238", swim = "rbxassetid://1083222527", swimidle = "rbxassetid://1083225406" }
    },
    Emotes = {
        ["None"] = nil,
        ["Dance 1"] = "rbxassetid://507771019",
        ["Dance 2"] = "rbxassetid://507771955",
        ["Dance 3"] = "rbxassetid://507772104",
        ["Wave / Hello"] = "rbxassetid://507770239",
        ["Point"] = "rbxassetid://507770453",
        ["Cheer"] = "rbxassetid://507770677",
        ["Laugh"] = "rbxassetid://507770818"
    }
}

-- // Client State Management \\ --
local removedHairStorage = {}
local allActions
local ClientState = {
    Originals = {
        LimbColors = {},
        FaceTexture = nil,
        Sound = { Id = nil, Pitch = nil },
        Lighting = {},
        Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} },
        LimbData = {}
    },
    Scripted = {
        Shirt = nil,
        Pants = nil,
        TShirt = nil,
        HeadlessMesh = nil,
        SkyObject = nil,
        CurrentEmote = nil
    },
    Connections = {
        CharacterAdded = nil,
        Rainbow = nil,
        Env = {},
        Anonymizer = {},
        EmoteStop = nil
    },
    Cache = {
        OriginalAnimations = {}
    }
}

-- // Utility Functions \\ --
local function getKeys(t) local k={}; for i in pairs(t) do table.insert(k,i) end; table.sort(k); return k end

local function weld(p0, p1, c0, c1)
    local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0, w.C1 = p0, p1, c0, c1; w.Parent = p0; return w
end

local function findAtt(root, name)
    for _, d in ipairs(root:GetDescendants()) do if d:IsA("Attachment") and d.Name == name then return d end end
end

local function safeDestroy(obj)
    if obj and obj.Parent then 
        pcall(function() obj:SetAttribute("OgHubDestroying", true) end)
        obj:Destroy() 
    end
end

-- // Core Logic Functions \\ --

local function captureColors(char, force)
    if not char then return end
    if not force and next(ClientState.Originals.LimbColors) then return end
    ClientState.Originals.LimbColors = {}

    -- Strategy 1: BodyColors (Best)
    local bc = char:FindFirstChildWhichIsA("BodyColors")
    if bc then
        local m = ClientState.Originals.LimbColors
        m.Head, m.Torso = bc.HeadColor3, bc.TorsoColor3
        m.LeftArm, m.RightArm = bc.LeftArmColor3, bc.RightArmColor3
        m.LeftLeg, m.RightLeg = bc.LeftLegColor3, bc.RightLegColor3
        return
    end

    -- Strategy 2: Manual Scan
    for group, names in pairs(CONFIG.LimbMappings) do
        local found = false
        for _, name in ipairs(names) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                ClientState.Originals.LimbColors[group] = p.Color
                found = true; break
            end
        end
        if not found then ClientState.Originals.LimbColors[group] = Color3.fromRGB(245, 205, 172) end
    end
end

local function applyColor(char, group, color)
    if not char or not CONFIG.LimbMappings[group] then return end
    
    local bc = char:FindFirstChildWhichIsA("BodyColors")
    if bc then
        if group == "Head" then bc.HeadColor3 = color
        elseif group == "Torso" then bc.TorsoColor3 = color
        elseif group == "LeftArm" then bc.LeftArmColor3 = color
        elseif group == "RightArm" then bc.RightArmColor3 = color
        elseif group == "LeftLeg" then bc.LeftLegColor3 = color
        elseif group == "RightLeg" then bc.RightLegColor3 = color
        end
    end

    for _, name in ipairs(CONFIG.LimbMappings[group]) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then p.Color = color end
    end
end

local function resetColors()
    local char = Player.Character
    for group, color in pairs(ClientState.Originals.LimbColors) do
        applyColor(char, group, color)
        if Library.Options[group.."Color"] then Library.Options[group.."Color"]:SetValueRGB(color) end
    end
end

-- Unified Clothing Handler
local function applyClothingItem(char, typeStr, itemName)
    if not char then return end
    
    -- Define class and property map
    local classMap = { Shirt = "Shirt", Pants = "Pants", TShirt = "ShirtGraphic" }
    local propMap = { Shirt = "ShirtTemplate", Pants = "PantsTemplate", TShirt = "Graphic" }
    local className = classMap[typeStr]
    local propName = propMap[typeStr]
    
    -- Clean up old scripted item
    safeDestroy(ClientState.Scripted[typeStr])
    ClientState.Scripted[typeStr] = nil

    local assetId = CONFIG.Clothing[typeStr][itemName]
    
    -- Handle Original Item Logic
    if typeStr == "TShirt" then
        -- TShirts are list-based in original storage
        if assetId then
            if #ClientState.Originals.Clothing.TShirts == 0 then
                for _, c in ipairs(char:GetChildren()) do
                     if c:IsA("ShirtGraphic") and c ~= ClientState.Scripted.TShirt then
                        table.insert(ClientState.Originals.Clothing.TShirts, c)
                        c.Parent = nil
                     end
                end
            end
            local newItem = Instance.new("ShirtGraphic")
            newItem.Name = "OG_HUB_ScriptedItem"
            newItem.Graphic = assetId
            newItem.Parent = char
            ClientState.Scripted.TShirt = newItem
        else
            -- Restore originals
            for _, item in ipairs(ClientState.Originals.Clothing.TShirts) do
                if item then item.Parent = char end
            end
            ClientState.Originals.Clothing.TShirts = {}
        end
    else
        -- Shirts and Pants are single items
        if assetId then
            local original = char:FindFirstChildOfClass(className)
            if original and not ClientState.Originals.Clothing[typeStr] then
                ClientState.Originals.Clothing[typeStr] = original
            end
            if ClientState.Originals.Clothing[typeStr] then
                ClientState.Originals.Clothing[typeStr].Parent = nil
            end
            
            local newItem = Instance.new(className)
            newItem.Name = "OG_HUB_ScriptedItem"
            newItem[propName] = assetId
            newItem.Parent = char
            ClientState.Scripted[typeStr] = newItem
        else
            -- Restore original
            if ClientState.Originals.Clothing[typeStr] then
                ClientState.Originals.Clothing[typeStr].Parent = char
                ClientState.Originals.Clothing[typeStr] = nil
            end
        end
    end
end

local function updateRainbow(enabled)
    if ClientState.Connections.Rainbow then ClientState.Connections.Rainbow:Disconnect(); ClientState.Connections.Rainbow = nil end
    if enabled then
        local hue = 0
        ClientState.Connections.Rainbow = RunService.Heartbeat:Connect(function(dt)
            hue = (hue + dt * CONFIG.RainbowSpeed) % 1
            local col = Color3.fromHSV(hue, 1, 1)
            if Player.Character then
                for group, _ in pairs(CONFIG.LimbMappings) do applyColor(Player.Character, group, col) end
            end
        end)
    else
        -- Revert to UI selected colors
        for group, _ in pairs(CONFIG.LimbMappings) do
            if Library.Options[group.."Color"] then
                applyColor(Player.Character, group, Library.Options[group.."Color"].Value)
            end
        end
    end
end

local function applyAnim(char, packName)
    task.spawn(function()
        if not char then return end
        local anim = char:WaitForChild("Animate", 5)
        if not anim then return end
        
        -- Cache originals
        if not next(ClientState.Cache.OriginalAnimations) then
            local function getID(obj) return obj and obj.AnimationId end
            local o = {}
            pcall(function()
                 o.idle = {getID(anim.idle.Animation1), getID(anim.idle.Animation2)}
                 o.walk = getID(anim.walk.WalkAnim); o.run = getID(anim.run.RunAnim)
                 o.jump = getID(anim.jump.JumpAnim); o.fall = getID(anim.fall.FallAnim)
                 o.climb = getID(anim.climb.ClimbAnim); o.swim = getID(anim.swim.Swim)
                 o.swimidle = getID(anim.swimidle.SwimIdle)
            end)
            ClientState.Cache.OriginalAnimations = o
            CONFIG.Animations["None"] = o -- Ensure None reverts to captured originals
        end
        
        if not next(ClientState.Cache.OriginalAnimations) then return end -- Failed to capture
        
        local pack = CONFIG.Animations[packName]
        if not pack then return end
        
        task.wait(0.1)
        -- Apply safely
        pcall(function()
            anim.idle.Animation1.AnimationId = pack.idle and pack.idle[1] or ClientState.Cache.OriginalAnimations.idle[1]
            anim.idle.Animation2.AnimationId = pack.idle and pack.idle[2] or ClientState.Cache.OriginalAnimations.idle[2]
            anim.walk.WalkAnim.AnimationId = pack.walk or ClientState.Cache.OriginalAnimations.walk
            anim.run.RunAnim.AnimationId = pack.run or ClientState.Cache.OriginalAnimations.run
            anim.jump.JumpAnim.AnimationId = pack.jump or ClientState.Cache.OriginalAnimations.jump
            anim.fall.FallAnim.AnimationId = pack.fall or ClientState.Cache.OriginalAnimations.fall
            anim.climb.ClimbAnim.AnimationId = pack.climb or ClientState.Cache.OriginalAnimations.climb
            anim.swim.Swim.AnimationId = pack.swim or ClientState.Cache.OriginalAnimations.swim
            anim.swimidle.SwimIdle.AnimationId = pack.swimidle or ClientState.Cache.OriginalAnimations.swimidle
        end)
    end)
end

local function stopEmote()
    if ClientState.Scripted.CurrentEmote then
        pcall(function() ClientState.Scripted.CurrentEmote:Stop() end)
        ClientState.Scripted.CurrentEmote = nil
    end
    if ClientState.Connections.EmoteStop then
        ClientState.Connections.EmoteStop:Disconnect()
        ClientState.Connections.EmoteStop = nil
    end
end

local function playEmote(char, emoteName)
    stopEmote()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local emoteId = CONFIG.Emotes[emoteName]
    if not emoteId then return end
    
    task.spawn(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = emoteId
        local loaded = humanoid:LoadAnimation(anim)
        ClientState.Scripted.CurrentEmote = loaded
        loaded:Play()
        
        ClientState.Connections.EmoteStop = humanoid.Running:Connect(function(speed)
            if speed > 0.5 then stopEmote() end
        end)
    end)
end

local function addAcc(char, list)
    if not char then return end
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    
    for partName, ids in pairs(list) do
        local target = (partName == "Head") and head or torso
        if target then
            for _, id in ipairs(ids) do
                local success, result = pcall(function() return game:GetObjects("rbxassetid://"..id)[1] end)
                if success and result then
                    local tag = Instance.new("BoolValue", result); tag.Name = "DrRayScriptedAccessory"
                    result.Parent = workspace
                    local handle = result:FindFirstChild("Handle")
                    if handle then
                        local att = handle:FindFirstChildOfClass("Attachment")
                        local targetAtt = att and findAtt(target, att.Name)
                        if targetAtt then
                            weld(target, handle, targetAtt.CFrame, att.CFrame)
                        else
                            weld(target, handle, CFrame.new(), CFrame.new())
                        end
                    end
                    result.Parent = char
                end
            end
        end
    end
end

-- Master Sync Function
local function syncCharacter(char)
    if not char then return end
    
    -- 1. Cleanup
    for _, c in ipairs(char:GetChildren()) do 
        if c:IsA("Accessory") and c:FindFirstChild("DrRayScriptedAccessory") then safeDestroy(c) end 
    end
    
    -- 2. Toggles
    for name, action in pairs(allActions) do
        if Library.Toggles[name] and Library.Toggles[name].Value then
             if action.type == "Accessory" then addAcc(char, action.action) else pcall(action.action, char, true) end
        end
    end
    
    -- 3. Colors & Modes
    if Library.Toggles.RainbowMode and Library.Toggles.RainbowMode.Value then
        updateRainbow(true)
    else
        for group, _ in pairs(CONFIG.LimbMappings) do
            if Library.Options[group.."Color"] then applyColor(char, group, Library.Options[group.."Color"].Value) end
        end
    end
    
    -- 4. Clothing & Audio
    applyClothingItem(char, "Shirt", Library.Options.ShirtSelector.Value)
    applyClothingItem(char, "Pants", Library.Options.PantsSelector.Value)
    applyClothingItem(char, "TShirt", Library.Options.TShirtSelector.Value)
    applyAnim(char, Library.Options.AnimationPackSelector.Value)
end

local function fullReset(char)
    if ClientState.Connections.Rainbow then ClientState.Connections.Rainbow:Disconnect() end
    
    -- Cleanup Scripted Objects
    safeDestroy(ClientState.Scripted.Shirt)
    safeDestroy(ClientState.Scripted.Pants)
    safeDestroy(ClientState.Scripted.TShirt)
    safeDestroy(ClientState.Scripted.HeadlessMesh)
    
    if char then
        -- Restore Originals
        if ClientState.Originals.Clothing.Shirt then ClientState.Originals.Clothing.Shirt.Parent = char end
        if ClientState.Originals.Clothing.Pants then ClientState.Originals.Clothing.Pants.Parent = char end
        for _, t in ipairs(ClientState.Originals.Clothing.TShirts) do if t then t.Parent = char end end
        for _, a in ipairs(ClientState.Originals.Clothing.Accessories) do if a then a.Parent = char end end
        
        -- Clean Scripted Accessories
        for _, c in ipairs(char:GetChildren()) do 
            if c:IsA("Accessory") and c:FindFirstChild("DrRayScriptedAccessory") then c:Destroy() end 
        end
        
        -- Restore Face and Headless
        local head = char:FindFirstChild("Head")
        if head then
            if ClientState.Originals.FaceTexture then
                local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
                if not face then face = Instance.new("Decal", head); face.Name = "face" end
                face.Texture = ClientState.Originals.FaceTexture
                face.Transparency = 0
            end
            if ClientState.Originals.Headless then
                head.Transparency = ClientState.Originals.Headless.Transparency or 0
                local sm = head:FindFirstChildOfClass("SpecialMesh")
                if sm and ClientState.Originals.Headless.MeshScale then sm.Scale = ClientState.Originals.Headless.MeshScale end
            end
        end
    end
    
    ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }
    ClientState.Originals.LimbData = {}
    applyAnim(char, "None")
end

-- Actions Definitions (Simplified)
allActions = {
    ["Headless"] = { category = "Body", type = "Function", action = function(c, e)
        local head = c and c:FindFirstChild("Head")
        if not head then return end
        
        if not ClientState.Originals.Headless then 
            ClientState.Originals.Headless = { Transparency = head.Transparency, MeshScale = nil }
            local sm = head:FindFirstChildOfClass("SpecialMesh")
            if sm then ClientState.Originals.Headless.MeshScale = sm.Scale end
        end

        local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
        if e then
            if face then
                if not ClientState.Originals.FaceTexture then ClientState.Originals.FaceTexture = face.Texture end
                face.Transparency = 1
            end
            head.Transparency = 1
            local sm = head:FindFirstChildOfClass("SpecialMesh")
            if sm then sm.Scale = Vector3.new(0, 0, 0) end
        else
            if face and ClientState.Originals.FaceTexture then
                face.Transparency = 0
            end
            if ClientState.Originals.Headless then
                head.Transparency = ClientState.Originals.Headless.Transparency or 0
                local sm = head:FindFirstChildOfClass("SpecialMesh")
                if sm and ClientState.Originals.Headless.MeshScale then sm.Scale = ClientState.Originals.Headless.MeshScale end
            end
        end
    end},
    ["Korblox"] = { category = "Body", type = "Function", action = function(c, e)
        if not (c and c:FindFirstChild("RightLowerLeg")) then return end
        if e then
            if not ClientState.Originals.LimbData["Korblox"] then
                ClientState.Originals.LimbData["Korblox"] = {
                    LowerMesh = c.RightLowerLeg.MeshId, LowerTrans = c.RightLowerLeg.Transparency,
                    UpperMesh = c.RightUpperLeg.MeshId, UpperTex = c.RightUpperLeg.TextureID,
                    FootMesh = c.RightFoot.MeshId, FootTrans = c.RightFoot.Transparency
                }
            end
            c.RightLowerLeg.MeshId = CONFIG.AssetIDs.KorbloxLeg; c.RightLowerLeg.Transparency = 1
            c.RightUpperLeg.MeshId = CONFIG.AssetIDs.KorbloxUpper; c.RightUpperLeg.TextureID = CONFIG.AssetIDs.KorbloxTex
            c.RightFoot.MeshId = CONFIG.AssetIDs.KorbloxFoot; c.RightFoot.Transparency = 1
        else
            local orig = ClientState.Originals.LimbData["Korblox"]
            if orig then
                c.RightLowerLeg.MeshId = orig.LowerMesh; c.RightLowerLeg.Transparency = orig.LowerTrans
                c.RightUpperLeg.MeshId = orig.UpperMesh; c.RightUpperLeg.TextureID = orig.UpperTex
                c.RightFoot.MeshId = orig.FootMesh; c.RightFoot.Transparency = orig.FootTrans
            end
        end
    end},
    ["Naked"] = { category = "Body", type = "Function", action = function(c, e)
        if not c then return end
        if e then
             local s = c:FindFirstChildOfClass("Shirt"); if s then ClientState.Originals.Clothing.Shirt = s; s.Parent = nil end
             local p = c:FindFirstChildOfClass("Pants"); if p then ClientState.Originals.Clothing.Pants = p; p.Parent = nil end
             for _, item in ipairs(c:GetChildren()) do
                if item:IsA("ShirtGraphic") and item ~= ClientState.Scripted.TShirt then
                    table.insert(ClientState.Originals.Clothing.TShirts, item); item.Parent = nil
                end
             end
        else
            if ClientState.Originals.Clothing.Shirt then ClientState.Originals.Clothing.Shirt.Parent = c end
            if ClientState.Originals.Clothing.Pants then ClientState.Originals.Clothing.Pants.Parent = c end
            for _, t in ipairs(ClientState.Originals.Clothing.TShirts) do t.Parent = c end
            ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {} }
        end
    end},
    ["Remove Hair"] = { category = "Body", type = "Function", action = function(c, e)
        if not c then return end
        if e then
             for _, h in ipairs(c:GetChildren()) do
                if h:IsA("Accessory") and h.AccessoryType == Enum.AccessoryType.Hair then
                    table.insert(ClientState.Originals.Clothing.Hair, h); h.Parent = nil
                end
             end
        else
             for _, h in ipairs(ClientState.Originals.Clothing.Hair) do h.Parent = c end; ClientState.Originals.Clothing.Hair = {}
        end
    end},
    ["Epic Face"] = { category = "Faces", type = "Function", action = function(c, e)
        local head = c and c:FindFirstChild("Head"); if not head then return end
        local face = head:FindFirstChild("face"); if not face then return end
        if e then
            if not ClientState.Originals.FaceTexture then ClientState.Originals.FaceTexture = face.Texture end
            face.Texture = CONFIG.AssetIDs.FaceTexture
        else
            if ClientState.Originals.FaceTexture then face.Texture = ClientState.Originals.FaceTexture end
        end
    end},
    ["Scary Smile Outfit"] = { category = "Outfits", type = "Function", action = function(c, e)
        if not c then return end
        if e then
             local s = c:FindFirstChildOfClass("Shirt"); if s and not ClientState.Originals.Clothing.Shirt then ClientState.Originals.Clothing.Shirt = s; s.Parent = nil end
             local p = c:FindFirstChildOfClass("Pants"); if p and not ClientState.Originals.Clothing.Pants then ClientState.Originals.Clothing.Pants = p; p.Parent = nil end
             if c.Head then 
                 local face = c.Head:FindFirstChild("face") or c.Head:FindFirstChildOfClass("Decal")
                 if face then 
                     if not ClientState.Originals.FaceTexture then ClientState.Originals.FaceTexture = face.Texture end
                     face.Transparency = 1 
                 end
             end
             for _, x in ipairs(c:GetChildren()) do if x:IsA("Accessory") and x.Name=="ScarySmileAccessory" then safeDestroy(x) end end
             
             local acc = Instance.new("Accessory"); acc.Name = "ScarySmileAccessory"
             local h = Instance.new("Part", acc); h.Name="Handle"; h.Size=Vector3.one; h.Transparency=1
             local m = Instance.new("SpecialMesh", h); m.MeshType=Enum.MeshType.FileMesh; m.MeshId="rbxassetid://111022241256851"; m.Scale=Vector3.new(1.03,1.03,1.03)
             local d = Instance.new("Decal", h); d.Face=Enum.NormalId.Front; d.Texture="http://www.roblox.com/asset/?id=120935988855219"
             
             local hum = c:FindFirstChildOfClass("Humanoid")
             if hum then hum:AddAccessory(acc) else acc.Parent = c end
             
             local ns = Instance.new("Shirt"); ns.Name = "OG_HUB_ScriptedItem"; ns.ShirtTemplate="http://www.roblox.com/asset/?id=11275376793"; ns.Parent = c
             local np = Instance.new("Pants"); np.Name = "OG_HUB_ScriptedItem"; np.PantsTemplate="http://www.roblox.com/asset/?id=5043452775"; np.Parent = c
        else
             for _, x in ipairs(c:GetChildren()) do if x.Name == "OG_HUB_ScriptedItem" or x.Name == "ScarySmileAccessory" then safeDestroy(x) end end
             syncCharacter(c)
        end
    end},
    ["Remove Original Shirt"] = { category = "Outfit", type = "Function", action = function(c,e) 
        if not c then return end
        if e then 
            local s = c:FindFirstChildOfClass("Shirt")
            if s and not ClientState.Originals.Clothing.Shirt then ClientState.Originals.Clothing.Shirt = s; s.Parent = nil end
        else
            if ClientState.Originals.Clothing.Shirt then ClientState.Originals.Clothing.Shirt.Parent = c; ClientState.Originals.Clothing.Shirt = nil end
        end
    end},
    ["Remove Original Pants"] = { category = "Outfit", type = "Function", action = function(c,e)
        if not c then return end
        if e then 
            local s = c:FindFirstChildOfClass("Pants")
            if s and not ClientState.Originals.Clothing.Pants then ClientState.Originals.Clothing.Pants = s; s.Parent = nil end
        else
            if ClientState.Originals.Clothing.Pants then ClientState.Originals.Clothing.Pants.Parent = c; ClientState.Originals.Clothing.Pants = nil end
        end
    end},
    ["Remove Original T-Shirts"] = { category = "Outfit", type = "Function", action = function(c,e)
        if not c then return end
        if e then 
             for _, item in ipairs(c:GetChildren()) do
                if item:IsA("ShirtGraphic") and item ~= ClientState.Scripted.TShirt then
                    table.insert(ClientState.Originals.Clothing.TShirts, item); item.Parent = nil
                end
             end
        else
             for _, t in ipairs(ClientState.Originals.Clothing.TShirts) do t.Parent = c end; ClientState.Originals.Clothing.TShirts = {}
        end
    end},
    ["Remove Original Accessories"] = { category = "Outfit", type = "Function", action = function(c,e)
        if not c then return end
        if e then 
             for _, item in ipairs(c:GetChildren()) do
                if item:IsA("Accessory") and not item:FindFirstChild("DrRayScriptedAccessory") then
                    table.insert(ClientState.Originals.Clothing.Accessories, item); item.Parent = nil
                end
             end
        else
             for _, t in ipairs(ClientState.Originals.Clothing.Accessories) do t.Parent = c end; ClientState.Originals.Clothing.Accessories = {}
        end
    end},
    ["Valkyrie Helm"] = { category = "Accessories", type = "Accessory", action = { Head = { 1365767 } } },
    ["Wings of Duality"] = { category = "Accessories", type = "Accessory", action = { Torso = { 493489765 } } },
    ["Dominus Praefectus"] = { category = "Accessories", type = "Accessory", action = { Head = { 527365852 } } },
    ["Fiery Horns of the Netherworld"] = { category = "Accessories", type = "Accessory", action = { Head = { 215718515 } } },
    ["Blackvalk"] = { category = "Accessories", type = "Accessory", action = { Head = { 124730194 } } },
    ["Frozen Horns of the Frigid Planes"] = { category = "Accessories", type = "Accessory", action = { Head = { 74891470 } } },
    ["Silver King of the Night"] = { category = "Accessories", type = "Accessory", action = { Head = { 439945661 } } },
    ["Poisoned Horns of the Toxic Wasteland"] = { category = "Accessories", type = "Accessory", action = { Head = { 1744060292 } } }
}

-- // Titan Engine Logic \\ --

local activeTweens = {}
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function playSafeTween(instance, properties)
    if activeTweens[instance] then activeTweens[instance]:Cancel() end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    activeTweens[instance] = tween
    tween:Play()
end

local atmosphere, bloom, colorCorr, sunRays, blur
local function ensureEffects()
    if not atmosphere or not atmosphere.Parent then
        atmosphere = Lighting:FindFirstChild("MyRTX_Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Name = "MyRTX_Atmosphere"
    end
    if not bloom or not bloom.Parent then
        bloom = Lighting:FindFirstChild("MyRTX_Bloom") or Instance.new("BloomEffect", Lighting)
        bloom.Name = "MyRTX_Bloom"
    end
    if not sunRays or not sunRays.Parent then
        sunRays = Lighting:FindFirstChild("MyRTX_SunRays") or Instance.new("SunRaysEffect", Lighting)
        sunRays.Name = "MyRTX_SunRays"
        sunRays.Spread = 0.2
    end
    if not colorCorr or not colorCorr.Parent then
        colorCorr = Lighting:FindFirstChild("MyRTX_Color") or Instance.new("ColorCorrectionEffect", Lighting)
        colorCorr.Name = "MyRTX_Color"
    end
    if not blur or not blur.Parent then
        blur = Lighting:FindFirstChild("MyRTX_Blur") or Instance.new("BlurEffect", Lighting)
        blur.Name = "MyRTX_Blur"
    end
end

-- // NameTag Logic \\ --
local lastNameTagUpdate = 0
local function updateNameTag()
    if tick() - lastNameTagUpdate < 0.5 then return end
    lastNameTagUpdate = tick()

    local enabled = Library.Toggles.NameTagEnabled and Library.Toggles.NameTagEnabled.Value
    if not enabled then return end
    
    local tag = Library.Options.NameTagText and Library.Options.NameTagText.Value or "[VIP]"
    local col = Library.Options.NameTagColor and Library.Options.NameTagColor.Value or Color3.fromRGB(255, 215, 0)
    
    if Player.Character then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum and not _G.AnonymizerLoaded then
            local expectedName = tag .. " " .. Player.Name
            if hum.DisplayName ~= expectedName then
                hum.DisplayName = expectedName
            end
        end
    end
    
    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        local list = CoreGui:FindFirstChild("PlayerList")
        if list then
            for _, obj in ipairs(list:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local txt = obj.Text
                    if txt == Player.Name or txt == Player.DisplayName then
                        if not string.find(txt, tag, 1, true) then
                            obj.Text = tag .. " " .. txt
                            obj.TextColor3 = col
                        end
                    end
                end
            end
        end
    end)
    
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if pg then
            local mg = pg:FindFirstChild("MainGui")
            local main = mg and mg:FindFirstChild("main")
            local tos = main and main:FindFirstChild("tos")
            local s = tos and tos:FindFirstChild("scroll")
            if s then
                for _, sample in ipairs(s:GetChildren()) do
                    if sample.Name == "sample" then
                        local nl = sample:FindFirstChild("name")
                        if nl and nl:IsA("TextLabel") and string.find(nl.Text, Player.Name, 1, true) then
                            if not string.find(nl.Text, tag, 1, true) then
                                nl.Text = tag .. " " .. nl.Text
                                nl.TextColor3 = col
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function enableNameTag()
    if ClientState.Connections.Env["NameTagLoop"] then ClientState.Connections.Env["NameTagLoop"]:Disconnect() end
    ClientState.Connections.Env["NameTagLoop"] = RunService.RenderStepped:Connect(updateNameTag)
end

local function disableNameTag()
    if ClientState.Connections.Env["NameTagLoop"] then 
        ClientState.Connections.Env["NameTagLoop"]:Disconnect() 
        ClientState.Connections.Env["NameTagLoop"] = nil 
    end
    if Player.Character and not _G.AnonymizerLoaded then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.DisplayName = Player.DisplayName end
    end
end

-- // UI Construction \\ --
local Tabs = {
    Appearance = Window:AddTab("Appearance", "shirt"),
    Useful = Window:AddTab("Useful", "wrench"),
    Titan = Window:AddTab("Titan Engine", "globe"),
    Settings = Window:AddTab("UI Settings", "settings")
}

local Groups = {
    Accessories = Tabs.Appearance:AddLeftGroupbox("Accessories"),
    Body = Tabs.Appearance:AddLeftGroupbox("Body Modifications"),
    Faces = Tabs.Appearance:AddLeftGroupbox("Faces"),
    Clothing = Tabs.Appearance:AddLeftGroupbox("Clothing (Visual)"),
    Outfit = Tabs.Appearance:AddLeftGroupbox("Outfit Management (Original)"),
    Animation = Tabs.Appearance:AddLeftGroupbox("Animation"),
    Emotes = Tabs.Appearance:AddRightGroupbox("Custom Emotes & Dances"),
    NameTag = Tabs.Appearance:AddRightGroupbox("Custom NameTag"),
    Outfits = Tabs.Appearance:AddLeftGroupbox("Full Outfits"),
    Tools = Tabs.Useful:AddLeftGroupbox("Tools"),
    TitanEnv = Tabs.Titan:AddLeftGroupbox("Environment 🌍"),
    TitanVis = Tabs.Titan:AddRightGroupbox("Visuals 🎨"),
    TitanUtil = Tabs.Titan:AddLeftGroupbox("Utility ⚙️")
}

-- Populate Elements
for name, data in pairs(allActions) do
    if Groups[data.category] then
        Groups[data.category]:AddToggle(name, {Text = name, Default = false, Callback = function(v) 
            if not v and data.type == "Function" then pcall(data.action, Player.Character, false) end
            syncCharacter(Player.Character) 
        end})
    end
end

Groups.Body:AddToggle("RainbowMode", { Text = "Rainbow Body Mode", Default = false, Callback = updateRainbow })

if Player.Character then captureColors(Player.Character, false) end
local fallback = Color3.fromRGB(245, 205, 172)
for _, limb in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
    local defaultColor = ClientState.Originals.LimbColors[limb] or fallback
    Groups.Body:AddLabel(limb.." Color"):AddColorPicker(limb.."Color", { Default = defaultColor, Callback = function(c) applyColor(Player.Character, limb, c) end })
end
Groups.Body:AddButton("Reset Limb Colors", resetColors)

Groups.Clothing:AddDropdown("ShirtSelector", { Values = getKeys(CONFIG.Clothing.Shirt), Default = "None", Text = "Shirt", Callback = function(s) applyClothingItem(Player.Character, "Shirt", s) end })
Groups.Clothing:AddDropdown("PantsSelector", { Values = getKeys(CONFIG.Clothing.Pants), Default = "None", Text = "Pants", Callback = function(s) applyClothingItem(Player.Character, "Pants", s) end })
Groups.Clothing:AddDropdown("TShirtSelector", { Values = getKeys(CONFIG.Clothing.TShirt), Default = "None", Text = "T-Shirt", Callback = function(s) applyClothingItem(Player.Character, "TShirt", s) end })
Groups.Animation:AddDropdown("AnimationPackSelector", { Values = getKeys(CONFIG.Animations), Default = "None", Text = "Animation Pack", Callback = function(p) applyAnim(Player.Character, p) end })

Groups.Emotes:AddDropdown("EmoteSelector", { Values = getKeys(CONFIG.Emotes), Default = "None", Text = "Select Emote" })
Groups.Emotes:AddButton("Play Emote ▶️", function() playEmote(Player.Character, Library.Options.EmoteSelector.Value) end)
Groups.Emotes:AddButton("Stop Emote ⏹️", stopEmote)

Groups.NameTag:AddInput("NameTagText", { Default = "[VIP]", Numeric = false, Finished = false, Text = "Tag Text", Placeholder = "[VIP]" })
Groups.NameTag:AddLabel("Tag Color"):AddColorPicker("NameTagColor", { Default = Color3.fromRGB(255, 215, 0), Title = "Tag Color" })
Groups.NameTag:AddToggle("NameTagEnabled", { Text = "Enable NameTag", Default = false, Callback = function(v)
    if v then enableNameTag() else disableNameTag() end
end })

Groups.Tools:AddLabel("Toggle UI"):AddKeyPicker("ToggleUIKeybind", { Default = "RightControl", NoUI = true, Text = "Toggle UI" })
Library.ToggleKeybind = Library.Options.ToggleUIKeybind


-- // Titan Engine Buttons \\ --
-- ==========================================
-- Environment Tab (Buttons)
-- ==========================================

Groups.TitanEnv:AddToggle("RainToggle", { Text = "Enable Rain & Fog", Default = false, Callback = function(enabled)
        local Lighting = game:GetService("Lighting")
        local RunService = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")

        local RENDER_LOOP_NAME = "ExecutorRainLoop"
        local RAIN_PART_NAME = "MyExecutorRainPart"

        if not enabled then
            pcall(function() RunService:UnbindFromRenderStep(RENDER_LOOP_NAME) end)
            local oldPart = Workspace:FindFirstChild(RAIN_PART_NAME)
            if oldPart then oldPart:Destroy() end
            
            local TweenService = game:GetService("TweenService")
            local fogTween = TweenService:Create(Lighting, TweenInfo.new(2, Enum.EasingStyle.Sine), {
                FogEnd = 100000,
                FogColor = Color3.fromRGB(190, 190, 190)
            })
            fogTween:Play()
            return
        end

        pcall(function() RunService:UnbindFromRenderStep(RENDER_LOOP_NAME) end)
        local oldPart = Workspace:FindFirstChild(RAIN_PART_NAME)
        if oldPart then oldPart:Destroy() end

        task.spawn(function()
            local rainPart = Instance.new("Part")
            rainPart.Name = RAIN_PART_NAME
            rainPart.Size = Vector3.new(200, 1, 200)
            rainPart.Transparency = 1
            rainPart.CanCollide = false
            rainPart.Anchored = true
            rainPart.Parent = Workspace

            local emitter = Instance.new("ParticleEmitter")
            emitter.Name = "RainEmitter"
            emitter.Texture = "rbxassetid://241868005"
            emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 215))
            emitter.LightEmission = 1
            emitter.LightInfluence = 0
            emitter.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
            emitter.Size = NumberSequence.new(5)
            
            local intensity = Library.Options.RainIntensitySlider and Library.Options.RainIntensitySlider.Value or 50
            emitter.Rate = intensity * 40
            emitter.Speed = NumberRange.new(50 + intensity)
            
            emitter.Lifetime = NumberRange.new(1.2)
            emitter.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0.4),
                NumberSequenceKeypoint.new(0.9, 0.6),
                NumberSequenceKeypoint.new(1, 1)
            })
            emitter.Acceleration = Vector3.new(0, -10, 0)
            emitter.LockedToPart = false
            emitter.EmissionDirection = Enum.NormalId.Bottom
            emitter.Shape = Enum.ParticleEmitterShape.Box
            emitter.Parent = rainPart

            RunService:BindToRenderStep(RENDER_LOOP_NAME, Enum.RenderPriority.Camera.Value + 1, function()
                local currentCam = Workspace.CurrentCamera
                if currentCam and rainPart and rainPart.Parent then
                    local camPos = currentCam.CFrame.Position
                    rainPart.Position = Vector3.new(camPos.X, camPos.Y + 70, camPos.Z)
                end
            end)

            Lighting.FogStart = 0
            local TweenService = game:GetService("TweenService")
            local fogTween = TweenService:Create(Lighting, TweenInfo.new(2, Enum.EasingStyle.Sine), {
                FogColor = Color3.fromRGB(155, 160, 165),
                FogEnd = 700 - (intensity * 4)
            })
            fogTween:Play()
            Library:Notify({Title = "System", Content = "Rain and Fog applied!", Duration = 3})
        end)
end})

Groups.TitanEnv:AddSlider("RainIntensitySlider", {
    Text = "Rain & Storm Intensity",
    Default = 50,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        local rainPart = game:GetService("Workspace"):FindFirstChild("MyExecutorRainPart")
        if rainPart then
            local emitter = rainPart:FindFirstChild("RainEmitter")
            if emitter then
                emitter.Rate = Value * 40
                emitter.Speed = NumberRange.new(50 + Value)
            end
            local TweenService = game:GetService("TweenService")
            TweenService:Create(game:GetService("Lighting"), TweenInfo.new(1, Enum.EasingStyle.Sine), {
                FogEnd = 700 - (Value * 4)
            }):Play()
        end
    end
})

Groups.TitanEnv:AddButton("Apply MineCraft Textures", function()

        task.spawn(function()
            local workspace = workspace
            local MaterialService = game:GetService("MaterialService")
            local CollectionService = game:GetService("CollectionService")

            local MATERIAL_CONFIG = {
                [Enum.Material.Asphalt]={"11545435992"},
                [Enum.Material.Basalt]={"11545440462","9730055481","7263615718","7263618080"},
                [Enum.Material.Brick]={"11545453130","9888913739"},
                [Enum.Material.Cobblestone]={"11545460611","9730055481"},
                [Enum.Material.Concrete]={"11545468983","7800894670","9406005008","8868470905"},
                [Enum.Material.CorrodedMetal]={"11545476330","6920910334"},
                [Enum.Material.CrackedLava]={"11545484781","2842360263"},
                [Enum.Material.DiamondPlate]={"11545495407","152572134"},
                [Enum.Material.Fabric]={"118776397"},
                [Enum.Material.Foil]={"11545501473","6928057336"},
                [Enum.Material.Glacier]={"11545521725","2167946571"},
                [Enum.Material.Granite]={"11545524005","151776555"},
                [Enum.Material.Grass]={"11545527424"}, 
                [Enum.Material.Ground]={"11545533676","7069953551"},
                [Enum.Material.Ice]={"11546405701","152528023"},
                [Enum.Material.LeafyGrass]={"11546412010","7069955228"},
                [Enum.Material.Limestone]={"11546415687","10180605826"},
                [Enum.Material.Marble]={"11546425898","7247387416"},
                [Enum.Material.Metal]={"11546431794","152572134"},
                [Enum.Material.Mud]={"11546437412","7263622044"},
                [Enum.Material.Pavement]={"11546440685","8139086777"},
                [Enum.Material.Pebble]={"11546453485","151776533"},
                [Enum.Material.Rock]={"11545456858"},
                [Enum.Material.Salt]={"11546461451","6756014847"},
                [Enum.Material.Sand]={"11546468464","5873998034"},
                [Enum.Material.Sandstone]={"11546471860","152572221"},
                [Enum.Material.Slate]={"11546474778"},
                [Enum.Material.Snow]={"11108916253"},
                [Enum.Material.Wood]={"11546477504"},
                [Enum.Material.WoodPlanks]={"11546480686","8676581022"}
            }

            for _, child in ipairs(MaterialService:GetChildren()) do
                if child:IsA("MaterialVariant") and string.sub(child.Name, 1, 4) == "abs_" then 
                    MaterialService:SetBaseMaterialOverride(child.BaseMaterial, "") 
                    task.defer(function() child:Destroy() end)
                end
            end

            local ActiveVariants = {} 
            for matEnum, idList in pairs(MATERIAL_CONFIG) do
                local rawId = idList[math.random(1, #idList)]
                local formattedId = string.find(rawId, "rbxassetid://") and rawId or ("rbxassetid://" .. rawId)

                local variantName = "abs_" .. matEnum.Name
                local v = Instance.new("MaterialVariant")
                v.Name = variantName
                v.BaseMaterial = matEnum
                v.ColorMap = formattedId
                v.StudsPerTile = 4
                v.Parent = MaterialService
                
                ActiveVariants[matEnum] = variantName
                MaterialService:SetBaseMaterialOverride(matEnum, variantName)
            end

            local humanoidCache = setmetatable({}, {__mode = "k"})
            local function IsHumanoidPart(part)
                local parent = part.Parent
                if not parent then return false end
                if humanoidCache[parent] ~= nil then return humanoidCache[parent] end
                if CollectionService:HasTag(parent, "Titan_Character") then
                    humanoidCache[parent] = true
                    return true
                end
                local isCharacter = parent:FindFirstChildOfClass("Humanoid") ~= nil
                humanoidCache[parent] = isCharacter
                if isCharacter then CollectionService:AddTag(parent, "Titan_Character") end
                return isCharacter
            end

            local partQueue = {}
            local processingQueue = false

            local function ProcessPartLogic(part, variantName)
                if not part.Parent or IsHumanoidPart(part) then return end
                part.MaterialVariant = variantName
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Texture") or child:IsA("Decal") then
                        child.Transparency = 1
                    end
                end
            end

            local function ProcessQueue()
                if processingQueue then return end
                processingQueue = true
                task.spawn(function()
                    while #partQueue > 0 do
                        local chunkCount = math.min(500, #partQueue)
                        for i = 1, chunkCount do
                            local item = table.remove(partQueue, #partQueue)
                            if item and item.part and item.part.Parent then
                                ProcessPartLogic(item.part, item.variantName)
                            end
                        end
                        if #partQueue > 0 then task.wait() end
                    end
                    processingQueue = false
                end)
            end

            local function ProcessPart(part, isImmediate)
                if not part:IsA("BasePart") then return end
                local variantName = ActiveVariants[part.Material]
                if not variantName then return end
                if part.MaterialVariant == variantName then return end

                if isImmediate then
                    ProcessPartLogic(part, variantName)
                else
                    table.insert(partQueue, {part = part, variantName = variantName})
                    ProcessQueue()
                end
            end

            if ClientState.Connections.Env["MinecraftTextures"] then ClientState.Connections.Env["MinecraftTextures"]:Disconnect() end
            ClientState.Connections.Env["MinecraftTextures"] = workspace.DescendantAdded:Connect(function(part) ProcessPart(part, false) end)

            task.spawn(function()
                local allDescendants = workspace:GetDescendants()
                local CHUNK_SIZE = 1500 
                for i = 1, #allDescendants do
                    ProcessPart(allDescendants[i], true)
                    if i % CHUNK_SIZE == 0 then task.wait() end
                end
                Library:Notify({Title = "System", Content = "MineCraft Textures applied!", Duration = 3})
            end)
        end)
end)

Groups.TitanEnv:AddButton("Enforce Universal Sky", function()

        local Lighting = game:GetService("Lighting")
        local skyObject = nil
        
        local UNIVERSAL_DAYLIGHT_PROFILE = {
            ClockTime = 14,
            Brightness = 2.0,
            Ambient = Color3.fromRGB(135, 140, 150),
            OutdoorAmbient = Color3.fromRGB(135, 140, 150)
        }
        
        local SPRING_SKYBOX = {
            SkyboxBk = "rbxassetid://12216109205", SkyboxDn = "rbxassetid://12216109875",
            SkyboxFt = "rbxassetid://12216109489", SkyboxLf = "rbxassetid://12216110170",
            SkyboxRt = "rbxassetid://12216110471", SkyboxUp = "rbxassetid://12216108877"
        }

        local RunService = game:GetService("RunService")

        local function enforceSky()
            if not skyObject or not skyObject.Parent then
                skyObject = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
            end
            for prop, val in pairs(SPRING_SKYBOX) do 
                if skyObject[prop] ~= val then skyObject[prop] = val end 
            end
            for prop, val in pairs(UNIVERSAL_DAYLIGHT_PROFILE) do 
                if Lighting[prop] ~= val then Lighting[prop] = val end 
            end
        end

        local function clearEffects()
            for _, child in ipairs(Lighting:GetChildren()) do
                if (child:IsA("Atmosphere") or child:IsA("Bloom") or child:IsA("ColorCorrection") or child:IsA("SunRays")) and not string.match(child.Name, "^MyRTX_") then
                    child:Destroy()
                end
            end
        end

        clearEffects()
        enforceSky()
        if ClientState.Connections.Env["Sky1"] then ClientState.Connections.Env["Sky1"]:Disconnect() end
        if ClientState.Connections.Env["Sky2"] then ClientState.Connections.Env["Sky2"]:Disconnect() end
        
        local lightingSpamCount = 0
        local lastLightingSpam = tick()
        ClientState.Connections.Env["Sky1"] = Lighting.ChildAdded:Connect(function(child)
            if tick() - lastLightingSpam > 1 then lightingSpamCount = 0 end
            lastLightingSpam = tick()
            if lightingSpamCount > 10 then return end
            
            if (child:IsA("Atmosphere") or child:IsA("Bloom") or child:IsA("ColorCorrection") or child:IsA("SunRays")) and not string.match(child.Name, "^MyRTX_") then
                lightingSpamCount = lightingSpamCount + 1
                task.defer(function() pcall(function() child:Destroy() end) end)
            end
        end)
        
        ClientState.Connections.Env["Sky2"] = RunService.RenderStepped:Connect(enforceSky)
        Library:Notify({Title = "System", Content = "Universal Sky applied!", Duration = 3})
end)

-- ==========================================
-- Visuals Tab (Buttons)
-- ==========================================
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local currentCamera = Workspace.CurrentCamera
local renderTarget = currentCamera

local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)


Groups.TitanVis:AddButton("Activate RTX Day Mode ☀️", function()

        ensureEffects()
        playSafeTween(Lighting, {
            ClockTime = 14, Brightness = 3,
            Ambient = Color3.fromRGB(170, 170, 170), OutdoorAmbient = Color3.fromRGB(210, 210, 210),
            FogColor = Color3.fromRGB(255, 245, 230), FogStart = 300, FogEnd = 1000, ExposureCompensation = 0 
        })
        playSafeTween(atmosphere, {Color = Color3.fromRGB(199, 199, 199), Decay = Color3.fromRGB(106, 112, 125)})
        playSafeTween(sunRays, {Intensity = 0.1})
        playSafeTween(bloom, {Intensity = 1.0, Threshold = 0.8, Size = 24})
        playSafeTween(colorCorr, {Saturation = 0, Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255)})
        playSafeTween(blur, {Size = 0})
        Library:Notify({Title = "Visuals", Content = "RTX Day Mode Applied!", Duration = 3})
end)

Groups.TitanVis:AddButton("Activate RTX Night Mode 🌙", function()

        ensureEffects()
        playSafeTween(Lighting, {
            ClockTime = 0, Brightness = 2,
            Ambient = Color3.fromRGB(50, 50, 80), OutdoorAmbient = Color3.fromRGB(30, 30, 60),
            FogColor = Color3.fromRGB(15, 15, 30), FogStart = 200, FogEnd = 800, ExposureCompensation = -0.3 
        })
        playSafeTween(atmosphere, {Color = Color3.fromRGB(40, 40, 60), Decay = Color3.fromRGB(20, 20, 30)})
        playSafeTween(sunRays, {Intensity = 0})
        playSafeTween(bloom, {Intensity = 1.5, Threshold = 0.8, Size = 64})
        playSafeTween(colorCorr, {Saturation = 0, Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255)})
        playSafeTween(blur, {Size = 0})
        Library:Notify({Title = "Visuals", Content = "RTX Night Mode Applied!", Duration = 3})
end)

Groups.TitanVis:AddButton("Activate Silent Hill Horror Mode 📼", function()

        ensureEffects()
        playSafeTween(Lighting, {
            ClockTime = 0, Brightness = 0.5,
            Ambient = Color3.fromRGB(30, 30, 30), OutdoorAmbient = Color3.fromRGB(20, 20, 20),
            FogColor = Color3.fromRGB(80, 80, 80), FogStart = 0, FogEnd = 120, ExposureCompensation = -0.5 
        })
        playSafeTween(atmosphere, {Color = Color3.fromRGB(40, 40, 40), Decay = Color3.fromRGB(20, 20, 20)})
        playSafeTween(sunRays, {Intensity = 0})
        playSafeTween(bloom, {Intensity = 0.2, Threshold = 0.5, Size = 10})
        playSafeTween(colorCorr, {Saturation = -0.85, Contrast = 0.5, TintColor = Color3.fromRGB(140, 155, 140)})
        playSafeTween(blur, {Size = 4})
        Library:Notify({Title = "Visuals", Content = "Horror Mode Applied!", Duration = 3})
end)

-- ==========================================
-- Utility Tab (Buttons)
-- ==========================================
Groups.TitanUtil:AddButton("Activate Anonymizer (Hide Names)", function()

        if _G.AnonymizerLoaded then
            Library:Notify({Title = "System", Content = "Anonymizer is already active!", Duration = 3})
            return
        end
        _G.AnonymizerLoaded = true
        
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local CoreGui = game:GetService("CoreGui")
        local success, TextChatService = pcall(function() return game:GetService("TextChatService") end)
        if not success then TextChatService = nil end
        local LocalPlayer = Players.LocalPlayer

        local Config = {
            AnonymousPrefix = "Player",
            HideLocalPlayer = true, 
            IgnoredUINames = {"Health", "Stamina", "Money", "Ammo", "Cash", "Credit", "Title", "Description", "Time"}
        }

        local ACTIVE_GUARDS = setmetatable({}, {__mode = "k"})
        local REPLACEMENT_MAP = {}
        local SORTED_REPLACEMENT_ORDER = {}
        local sortedIndexMap = {}
        local ESCAPED_NAME_MAP = {}
        local playerNumberMap = {}
        local availableNumbers = {}
        local playerCounter = 0
        local playerKnownNames = {}
        local dirtyObjects = {} 
        local IGNORED_NAMES_LOOKUP = {}
        for _, name in ipairs(Config.IgnoredUINames) do IGNORED_NAMES_LOOKUP[name] = true end

        local function escapePattern(text) return text:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") end

        local Anonymizer = {}
        function Anonymizer.replaceText(text)
            if type(text) ~= "string" or #text == 0 then return text end
            for _, o in ipairs(SORTED_REPLACEMENT_ORDER) do
                local a = REPLACEMENT_MAP[o]
                if a then text = text:gsub(ESCAPED_NAME_MAP[o], a) end
            end
            return text
        end

        local NameManager = {}
        local function getNameVariants(p, d, u) return {[p.Name]=d,["@"..p.Name]=u,[p.DisplayName]=d,["@"..p.DisplayName]=u} end

        function NameManager.insertSorted(n)
            ESCAPED_NAME_MAP[n] = escapePattern(n)
            local l = #n
            for i = 1, #SORTED_REPLACEMENT_ORDER + 1 do
                if i > #SORTED_REPLACEMENT_ORDER or l > #SORTED_REPLACEMENT_ORDER[i] then
                    table.insert(SORTED_REPLACEMENT_ORDER, i, n)
                    sortedIndexMap[n] = i
                    for j = i + 1, #SORTED_REPLACEMENT_ORDER do sortedIndexMap[SORTED_REPLACEMENT_ORDER[j]] = j end
                    return
                end
            end
        end

        local function removeNameFromSortedList(n)
            local i = sortedIndexMap[n]
            if i then
                table.remove(SORTED_REPLACEMENT_ORDER, i)
                sortedIndexMap[n] = nil
                ESCAPED_NAME_MAP[n] = nil
                for j = i, #SORTED_REPLACEMENT_ORDER do sortedIndexMap[SORTED_REPLACEMENT_ORDER[j]] = j end
            end
        end

        local function removeNamesFromSystem(t) 
            for _, n in ipairs(t) do REPLACEMENT_MAP[n] = nil; removeNameFromSortedList(n) end 
        end

        function NameManager.addPlayer(p)
            if not Config.HideLocalPlayer and p == LocalPlayer then return end
            if playerNumberMap[p.UserId] then return end
            local n = table.remove(availableNumbers) or (function() playerCounter += 1; return playerCounter end)()
            playerNumberMap[p.UserId] = n
            local d, u = Config.AnonymousPrefix .. n, "@" .. Config.AnonymousPrefix .. n
            local r = getNameVariants(p, d, u)
            for o, rp in pairs(r) do REPLACEMENT_MAP[o] = rp; NameManager.insertSorted(o) end
            playerKnownNames[p.UserId] = {Name = p.Name, DisplayName = p.DisplayName}
        end

        function NameManager.removePlayer(p)
            local n = playerNumberMap[p.UserId]
            if not n then return end
            table.insert(availableNumbers, n)
            local k = playerKnownNames[p.UserId]
            if k then removeNamesFromSystem({k.Name, "@" .. k.Name, k.DisplayName, "@" .. k.DisplayName}) end
            playerNumberMap[p.UserId] = nil
            playerKnownNames[p.UserId] = nil
        end

        function NameManager.updatePlayer(p)
            if not Config.HideLocalPlayer and p == LocalPlayer then return end 
            if not playerNumberMap[p.UserId] then return NameManager.addPlayer(p) end
            local o = playerKnownNames[p.UserId]
            if o then removeNamesFromSystem({o.Name, "@" .. o.Name, o.DisplayName, "@" .. o.DisplayName}) end
            local n = playerNumberMap[p.UserId]
            local d, u = Config.AnonymousPrefix .. n, "@" .. Config.AnonymousPrefix .. n
            local a = getNameVariants(p, d, u)
            for ori, rep in pairs(a) do REPLACEMENT_MAP[ori] = rep; NameManager.insertSorted(ori) end
            playerKnownNames[p.UserId] = {Name = p.Name, DisplayName = p.DisplayName}
        end

        local UIProcessor = {}
        local UI_HANDLERS, UPDATE_LOGIC = {}, {}
        local function markAsDirty(obj) dirtyObjects[obj] = true end

        UPDATE_LOGIC.TextLabel = function(o) o.Text = Anonymizer.replaceText(o.Text) end
        UPDATE_LOGIC.TextButton, UPDATE_LOGIC.TextBox = UPDATE_LOGIC.TextLabel, UPDATE_LOGIC.TextLabel
        UPDATE_LOGIC.ProximityPrompt = function(o) o.ObjectText, o.ActionText = Anonymizer.replaceText(o.ObjectText), Anonymizer.replaceText(o.ActionText) end

        local function setupDestruction(obj, key)
            key = key or obj
            obj.Destroying:Connect(function()
                local c = ACTIVE_GUARDS[key]
                if c then for _, v in ipairs(c) do v:Disconnect() end; ACTIVE_GUARDS[key] = nil end
            end)
        end

        local function isWhitelisted(obj)
            if obj:GetAttribute("IgnoreAnonymizer") == true then return true end
            if IGNORED_NAMES_LOOKUP[obj.Name] then return true end
            return false
        end

        UI_HANDLERS.TextLabel = function(obj)
            if ACTIVE_GUARDS[obj] or isWhitelisted(obj) then return end
            markAsDirty(obj)
            local c = obj:GetPropertyChangedSignal("Text"):Connect(function() markAsDirty(obj) end)
            local c2 = obj:GetAttributeChangedSignal("IgnoreAnonymizer"):Connect(function() if not isWhitelisted(obj) then markAsDirty(obj) end end)
            ACTIVE_GUARDS[obj] = {c, c2}
            setupDestruction(obj)
        end
        UI_HANDLERS.TextButton, UI_HANDLERS.TextBox = UI_HANDLERS.TextLabel, UI_HANDLERS.TextLabel

        UI_HANDLERS.BillboardGui = function(obj)
            if ACTIVE_GUARDS[obj] or isWhitelisted(obj) then return end
            for _, c in ipairs(obj:GetDescendants()) do UIProcessor.guardTextObject(c) end
            local d = obj.DescendantAdded:Connect(UIProcessor.guardTextObject)
            ACTIVE_GUARDS[obj] = {d}
            setupDestruction(obj)
        end

        UI_HANDLERS.ProximityPrompt = function(obj)
            if ACTIVE_GUARDS[obj] or isWhitelisted(obj) then return end
            markAsDirty(obj)
            local c1 = obj:GetPropertyChangedSignal("ObjectText"):Connect(function() markAsDirty(obj) end)
            local c2 = obj:GetPropertyChangedSignal("ActionText"):Connect(function() markAsDirty(obj) end)
            ACTIVE_GUARDS[obj] = {c1, c2}
            setupDestruction(obj)
        end

        function UIProcessor.guardTextObject(o) 
            local h = UI_HANDLERS[o.ClassName]; 
            if h then h(o) end 
        end

        function UIProcessor.scanAndTrackContainer(c)
            if not c then return end
            for _, d in ipairs(c:GetDescendants()) do UIProcessor.guardTextObject(d) end
            local co = c.DescendantAdded:Connect(UIProcessor.guardTextObject)
            ACTIVE_GUARDS[c] = {co}
        end

        local DisplayNameGuardian = {}
        function DisplayNameGuardian.setupCharacter(character)
            local player = Players:GetPlayerFromCharacter(character)
            if not player then return end
            if not Config.HideLocalPlayer and player == LocalPlayer then return end

            local function guardHumanoid(humanoid)
                if not humanoid or ACTIVE_GUARDS[humanoid] then return end
                local isUpdating = false
                local function update()
                    if isUpdating then return end
                    local n = playerNumberMap[player.UserId]
                    local t = n and (Config.AnonymousPrefix .. n) or player.DisplayName
                    if humanoid.DisplayName ~= t then
                        isUpdating = true; humanoid.DisplayName = t; isUpdating = false
                    end
                end
                update()
                local c1 = humanoid:GetPropertyChangedSignal("DisplayName"):Connect(update)
                local c2 = player:GetPropertyChangedSignal("DisplayName"):Connect(update)
                ACTIVE_GUARDS[humanoid] = {c1, c2}
                setupDestruction(character, humanoid)
            end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then guardHumanoid(humanoid) 
            else
                local conn; conn = character.ChildAdded:Connect(function(c) if c:IsA("Humanoid") then conn:Disconnect(); guardHumanoid(c) end end)
                character.Destroying:Connect(function() if conn then conn:Disconnect() end end)
            end
        end

        function DisplayNameGuardian.setupForPlayer(p)
            if p.Character then DisplayNameGuardian.setupCharacter(p.Character) end
            p.CharacterAdded:Connect(DisplayNameGuardian.setupCharacter)
            p:GetPropertyChangedSignal("DisplayName"):Connect(function() NameManager.updatePlayer(p) end)
        end

        local ChatHandler = {}
        function ChatHandler.setupTextChatServiceFilter()
            if not TextChatService then return end
            pcall(function()
                TextChatService.OnIncomingMessage = function(m)
                    local p = Instance.new("TextChatMessageProperties")
                    pcall(function() p.Text = Anonymizer.replaceText(m.Text) end)
                    return p
                end
            end)
        end

        function ChatHandler.setupSystemMessageFilter() 
            if not TextChatService then return end 
            local function s(c) 
                if c.Name == "RBXSystem" then 
                    c.OnIncomingMessage = function(m) m.Text = Anonymizer.replaceText(m.Text) return end 
                end 
            end; 
            for _, c in ipairs(TextChatService:GetChildren()) do 
                if c:IsA("TextChannel") then pcall(s, c) end 
            end; 
            TextChatService.ChildAdded:Connect(function(c) 
                if c:IsA("TextChannel") then pcall(s, c) end 
            end) 
        end

        function ChatHandler.setupLegacyChatScanner()
            if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then return end
            pcall(function()
                local c = CoreGui:WaitForChild("Chat", 10)
                if c then 
                    local m = c:FindFirstChild("Frame.ChatChannelParentFrame.Frame_MessageLogDisplay", true); 
                    if m then UIProcessor.scanAndTrackContainer(m) end 
                end
            end)
        end

        local function onPlayerAdded(p) 
            NameManager.addPlayer(p); 
            DisplayNameGuardian.setupForPlayer(p) 
        end
        local function onPlayerRemoving(p) NameManager.removePlayer(p) end

        ChatHandler.setupTextChatServiceFilter()
        ChatHandler.setupSystemMessageFilter()
        task.spawn(ChatHandler.setupLegacyChatScanner)

        for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
        table.insert(ClientState.Connections.Anonymizer, Players.PlayerAdded:Connect(onPlayerAdded))
        table.insert(ClientState.Connections.Anonymizer, Players.PlayerRemoving:Connect(onPlayerRemoving))

        local function startTargetedScanning()
            task.spawn(function()
                if LocalPlayer then
                    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
                    if pg then UIProcessor.scanAndTrackContainer(pg) end
                end
                UIProcessor.scanAndTrackContainer(CoreGui)
            end)
            
            local function w(c)
                for _, d in ipairs(c:GetDescendants()) do UIProcessor.guardTextObject(d) end
                local co = c.DescendantAdded:Connect(UIProcessor.guardTextObject)
                ACTIVE_GUARDS[c] = {co}
                setupDestruction(c)
            end
            
            for _, p in ipairs(Players:GetPlayers()) do 
                if p.Character then w(p.Character) end; 
                table.insert(ClientState.Connections.Anonymizer, p.CharacterAdded:Connect(w))
            end
            table.insert(ClientState.Connections.Anonymizer, Players.PlayerAdded:Connect(function(p) 
                table.insert(ClientState.Connections.Anonymizer, p.CharacterAdded:Connect(w)); 
                if p.Character then w(p.Character) end 
            end))
        end
        startTargetedScanning()

        table.insert(ClientState.Connections.Anonymizer, RunService.RenderStepped:Connect(function()
            if next(dirtyObjects) == nil then return end
            for o, _ in pairs(dirtyObjects) do 
                local u = UPDATE_LOGIC[o.ClassName]; 
                if u then u(o) end 
            end
            table.clear(dirtyObjects)
        end))
        
        Library:Notify({Title = "System", Content = "Anonymizer activated successfully!", Duration = 3})
end)


local function resetAllUI()
    for name, _ in pairs(allActions) do if Library.Toggles[name] then Library.Toggles[name]:SetValue(false) end end
    if Library.Toggles.NameTagEnabled then Library.Toggles.NameTagEnabled:SetValue(false) end
    Library.Options.ShirtSelector:SetValue("None")
    Library.Options.PantsSelector:SetValue("None")
    Library.Options.TShirtSelector:SetValue("None")
    Library.Options.AnimationPackSelector:SetValue("None")
    Library.Options.EmoteSelector:SetValue("None")
    stopEmote()
    Library.Toggles.RainbowMode:SetValue(false)
    resetColors()
end

Groups.Tools:AddButton("Reset All", function() fullReset(Player.Character); resetAllUI() end)
Groups.Tools:AddButton("Unload Script", { Text = "Unload Script", DoubleClick = false, Risky = true, Func = function() 
    if ClientState.Connections.Rainbow then ClientState.Connections.Rainbow:Disconnect() end
    for _, c in pairs(ClientState.Connections.Env or {}) do if c then c:Disconnect() end end
    for _, c in ipairs(ClientState.Connections.Anonymizer or {}) do if c then c:Disconnect() end end
    
    local rainPart = game:GetService("Workspace"):FindFirstChild("MyExecutorRainPart")
    if rainPart then rainPart:Destroy() end
    pcall(function() game:GetService("RunService"):UnbindFromRenderStep("ExecutorRainLoop") end)
    
    local MaterialService = game:GetService("MaterialService")
    for _, child in ipairs(MaterialService:GetChildren()) do
        if child:IsA("MaterialVariant") and string.sub(child.Name, 1, 4) == "abs_" then 
            MaterialService:SetBaseMaterialOverride(child.BaseMaterial, "") 
            task.defer(function() child:Destroy() end)
        end
    end
    
    _G.AnonymizerLoaded = false
    fullReset(Player.Character)
    if ClientState.Connections.CharacterAdded then ClientState.Connections.CharacterAdded:Disconnect() end
    getgenv().OGHubLoaded = nil
    Library:Unload()
end })

-- // Initialization \\ --
ClientState.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(c)
    task.spawn(function()
        c:WaitForChild("Humanoid", 3)
        local t = tick()
        while tick() - t < 2 do
            local success, loaded = pcall(function() return Player:HasAppearanceLoaded() end)
            if success and loaded then break end
            task.wait(0.1)
        end
        
        if not c.Parent then return end

        ClientState.Scripted = { Shirt=nil, Pants=nil, TShirt=nil, HeadlessMesh=nil, SkyObject=nil }
        ClientState.Originals.LimbColors = {}
        ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }
        ClientState.Originals.LimbData = {}
        ClientState.Originals.FaceTexture = nil
        ClientState.Originals.Sound = { Id = nil, Pitch = nil }
        ClientState.Originals.Headless = nil
        
        captureColors(c, true)
        local success, err = pcall(function() syncCharacter(c) end)
        if not success then warn("OgHub Sync Error: " .. tostring(err)) end

        if ClientState.Connections.Env["AppearanceEnforcer"] then ClientState.Connections.Env["AppearanceEnforcer"]:Disconnect() end
        ClientState.Connections.Env["AppearanceEnforcer"] = c.DescendantAdded:Connect(function(child)
            if not child.Parent then return end
            if child.Name == "OG_HUB_ScriptedItem" or child.Name == "DrRayScriptedAccessory" or child:FindFirstChild("DrRayScriptedAccessory") then return end
            
            local p = child.Parent
            while p and p ~= game do
                if p.Name == "OG_HUB_ScriptedItem" or p:FindFirstChild("DrRayScriptedAccessory") then return end
                p = p.Parent
            end
            
            task.wait()
            if not child.Parent then return end
            
            if child:IsA("Clothing") or child:IsA("ShirtGraphic") or child:IsA("Accessory") or child:IsA("BodyColors") or child:IsA("Decal") or child:IsA("SpecialMesh") then
                pcall(function() syncCharacter(c) end)
            end
        end)
        
        if ClientState.Connections.Env["AppearanceEnforcer2"] then ClientState.Connections.Env["AppearanceEnforcer2"]:Disconnect() end
        ClientState.Connections.Env["AppearanceEnforcer2"] = c.DescendantRemoving:Connect(function(child)
            if child:GetAttribute("OgHubDestroying") then return end
            if child.Name == "OG_HUB_ScriptedItem" or child.Name == "DrRayScriptedAccessory" or child:FindFirstChild("DrRayScriptedAccessory") then
                task.defer(function()
                    if c.Parent then pcall(function() syncCharacter(c) end) end
                end)
            end
        end)
    end)
end)

if Player.Character then captureColors(Player.Character, true) end

if ThemeManager and SaveManager then
    ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({ "ToggleUIKeybind" })
    ThemeManager:SetFolder("OG_HUB_Settings"); SaveManager:SetFolder("OG_HUB_Settings")
    ThemeManager:ApplyToTab(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)
    
    local oldLoad = SaveManager.Load
    function SaveManager:Load(...)
        fullReset(Player.Character); resetAllUI()
        local s, e = oldLoad(self, ...)
        if s then task.wait(0.2); syncCharacter(Player.Character) end
        return s, e
    end
    SaveManager:LoadAutoloadConfig()
end
