--[[ WhiteRose - V6.0 (Optimized & Compact Edition) ]]
if getgenv().WhiteRoseLoaded then return end

local Players, Lighting, RunService, TweenService, Workspace = 
    game:GetService("Players"), game:GetService("Lighting"), game:GetService("RunService"), game:GetService("TweenService"), game:GetService("Workspace")

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local function fetchModule(p) local ok, m = pcall(function() return loadstring(game:HttpGet(repo .. p))() end) return ok and m or nil end

local Library = fetchModule("Library.lua")
if not Library then return warn("WhiteRose: Library failed to load.") end
local ThemeManager, SaveManager = fetchModule("addons/ThemeManager.lua"), fetchModule("addons/SaveManager.lua")

getgenv().WhiteRoseLoaded = true
local Player = Players.LocalPlayer

local Window = Library:CreateWindow({ Name = "WhiteRose", Title = "WhiteRose", SubTitle = "Optimized by MrOG & AI", Draggable = true, Footer = "Made By gemini & Thank him | v1.2.0" })

-- // Configuration & Constants \ --
local CONFIG = {
    AssetIDs = {
        HeadlessMesh = "http://www.roblox.com/asset/?id=134079402", HeadlessTex = "http://www.roblox.com/asset/?id=133940918",
        FaceTexture = "http://www.roblox.com/asset/?id=42070872", KorbloxLeg = "rbxassetid://902942093",
        KorbloxUpper = "rbxassetid://902942096", KorbloxTex = "rbxassetid://902843398", KorbloxFoot = "rbxassetid://902942089"
    },
    LimbMappings = {
        Head = { "Head" }, Torso = { "UpperTorso", "LowerTorso", "Torso" },
        LeftArm = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm" },
        RightArm = { "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm" },
        LeftLeg = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg" },
        RightLeg = { "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }
    },
    Clothing = {
        Shirt = { ["None"] = false, ["Remove"] = false, ["Yuno Gasai Mirai Nikki"] = 6412908981, ["Sanji (+)"] = "http://www.roblox.com/asset/?id=18529496130" },
        Pants = { ["None"] = false, ["Remove"] = false, ["Yuno Gasai Mirai Nikki"] = 6412913951, ["Yuno Gasai Anime Black Dress V2"] = 14696725708, ["Sanji (-)"] = "http://www.roblox.com/asset/?id=18529553305" },
        TShirt = { ["None"] = false, ["Remove"] = false, ["Oh Noez!"] = "http://www.roblox.com/asset/?id=1641286", ["Spread The Lulz!"] = "http://www.roblox.com/asset/?id=24774765" }
    },
    Animations = {
        ["None"] = {},
        ["Vampire"] = {
            idle = { "rbxassetid://1083445855", "rbxassetid://1083450166" }, walk = "rbxassetid://1083473930", run = "rbxassetid://1083462077",
            jump = "rbxassetid://1083455352", fall = "rbxassetid://1083443587", climb = "rbxassetid://1083439238",
            swim = "rbxassetid://1083222527", swimidle = "rbxassetid://1083225406"
        }
    },
    AnimationOverrides = {
        ["Robot Swim"] = { key = "RobotSwim", values = { swim = "rbxassetid://10921253142", swimidle = "rbxassetid://10921253767" } },
        ["Mage Fall"] = { key = "MageFall", values = { fall = "rbxassetid://10921148939" } },
        ["Elder Jump"] = { key = "ElderJump", values = { jump = "rbxassetid://10921107367" } },
        ["Toy Run"] = { key = "ToyRun", values = { run = "rbxassetid://10921306285" } }
    },
    Emotes = {
        ["None"] = false, ["Dance 1"] = "rbxassetid://507771019", ["Dance 2"] = "rbxassetid://507771955",
        ["Dance 3"] = "rbxassetid://507772104", ["Wave / Hello"] = "rbxassetid://507770239", ["Point"] = "rbxassetid://507770453",
        ["Cheer"] = "rbxassetid://507770677", ["Laugh"] = "rbxassetid://507770818"
    }
}

-- // Client State \ --
local allActions = {}
local ClientState = {
    Originals = { LimbColors = {}, FaceTexture = nil, FaceTransparency = nil, Sound = {}, Lighting = {}, Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }, LimbData = {} },
    Scripted = { Shirt = nil, Pants = nil, TShirt = nil, HeadlessMesh = nil, SkyObject = nil, CurrentEmote = nil, ScarySmile = nil },
    Connections = { CharacterAdded = nil, Env = {}, EmoteStop = nil, AccessorySync = {} },
    Cache = { OriginalAnimations = {}, ClothingTemplates = {}, AccessoryTemplates = {}, AccessorySignature = nil, AccessoryCharacter = nil, AppliedActions = {}, R6AnimWarned = nil }
}

-- // Helpers \ --
local function getKeys(t) local k = {} for i in pairs(t) do table.insert(k, i) end table.sort(k) return k end
local function getOptionValue(n, d) local o = Library.Options[n] return (o and o.Value ~= nil) and o.Value or d end
local function getToggleValue(n) local t = Library.Toggles[n] return t and t.Value or false end
local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:SetAttribute("WhiteRoseDestroying", true) for _, d in ipairs(obj:GetDescendants()) do d:SetAttribute("WhiteRoseDestroying", true) end end)
        obj:Destroy()
    end
end
local function isR6Rig(char) local h = char and char:FindFirstChildOfClass("Humanoid") return (h and h.RigType == Enum.HumanoidRigType.R6) or (char and char:FindFirstChild("Torso") ~= nil and not char:FindFirstChild("UpperTorso")) end

-- // Accessory Manager \ --
local SCRIPTED_ACCESSORY_ATTRIBUTE, SCRIPTED_HAIR_ATTRIBUTE = "WhiteRoseScriptedAccessory", "WhiteRoseScriptedHair"
local AccessoryManager = { Connections = {} }
local FALLBACK_ATTACHMENT_CFRAMES = {
    HairAttachment = CFrame.new(0, 0.6, 0), HatAttachment = CFrame.new(0, 0.6, 0),
    FaceFrontAttachment = CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0),
    FaceCenterAttachment = CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0),
    NeckAttachment = CFrame.new(0, 1, 0), LeftShoulderAttachment = CFrame.new(-1, 0.8, 0),
    RightShoulderAttachment = CFrame.new(1, 0.8, 0), WaistAttachment = CFrame.new(0, -0.8, 0)
}

local function makeCosmetic(root)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery, d.Massless = false, false, false, false, true end
    end
end

function AccessoryManager:BindTransparency(targetPart, visualContainer)
    if not targetPart or not visualContainer then return end
    local function sync()
        if not targetPart.Parent or not visualContainer.Parent then return end
        local trans, ltm = targetPart.Transparency, targetPart.LocalTransparencyModifier
        for _, d in ipairs(visualContainer:GetDescendants()) do
            if d:IsA("BasePart") then d.Transparency, d.LocalTransparencyModifier = trans, ltm
            elseif d:IsA("Decal") or d:IsA("Texture") then d.Transparency = trans end
        end
        if visualContainer:IsA("BasePart") then visualContainer.Transparency, visualContainer.LocalTransparencyModifier = trans, ltm end
    end
    table.insert(self.Connections, targetPart:GetPropertyChangedSignal("Transparency"):Connect(sync))
    table.insert(self.Connections, targetPart:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(sync))
    sync()
end

local function weldAccessory(character, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end
    makeCosmetic(accessory)

    local handleAtt = handle:FindFirstChildWhichIsA("Attachment") or Instance.new("Attachment", handle)
    local charAtt
    for _, d in ipairs(character:GetDescendants()) do
        if d:IsA("Attachment") and d.Name == handleAtt.Name and d.Parent:IsA("BasePart") then charAtt = d break end
    end

    if not charAtt then
        local head = character:FindFirstChild("Head")
        if not head then return false end
        charAtt = head:FindFirstChild(handleAtt.Name .. "_WRF") or Instance.new("Attachment", head)
        charAtt.Name, charAtt.CFrame = handleAtt.Name .. "_WRF", FALLBACK_ATTACHMENT_CFRAMES[handleAtt.Name] or CFrame.new(0, 0.6, 0)
    end

    local targetPart = charAtt.Parent
    accessory.Parent = character
    handle.CFrame = targetPart.CFrame * charAtt.CFrame * handleAtt.CFrame:Inverse()

    local weld = Instance.new("Weld", targetPart)
    weld.Name, weld.Part0, weld.Part1, weld.C0, weld.C1 = "WhiteRoseAccessoryWeld", targetPart, handle, charAtt.CFrame, handleAtt.CFrame
    local wRef = Instance.new("ObjectValue", accessory)
    wRef.Name, wRef.Value = "WhiteRoseAccessoryWeld", weld

    AccessoryManager:BindTransparency(targetPart, accessory)
    return true
end

local function attachMeshHair(character, root)
    local head = character:FindFirstChild("Head")
    if not head then return false end
    local parts = root:IsA("BasePart") and { root } or {}
    if #parts == 0 then for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end end
    if #parts == 0 then return false end

    local base, baseCF = parts[1], parts[1].CFrame
    local attachPart, attachAtt
    for _, p in ipairs(parts) do
        local a = p:FindFirstChildWhichIsA("Attachment")
        if a then attachPart, attachAtt = p, a break end
    end

    local c0 = attachAtt and ((head:FindFirstChild(attachAtt.Name) or Instance.new("Attachment", head)).CFrame * attachAtt.CFrame:Inverse() * (baseCF:Inverse() * attachPart.CFrame):Inverse())
        or CFrame.new(0, (head.Size.Y / 2 + 0.1), 0)

    local holder = Instance.new("Folder", character)
    holder.Name = "WhiteRoseScriptedHair"
    holder:SetAttribute(SCRIPTED_HAIR_ATTRIBUTE, true)

    for _, p in ipairs(parts) do
        local rel = baseCF:Inverse() * p.CFrame
        p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless, p.Parent = false, false, false, false, true, holder
        local w = Instance.new("Weld", p)
        w.Name, w.Part0, w.Part1, w.C0, w.C1 = "WhiteRoseHairWeld", head, p, c0, rel:Inverse()
    end

    AccessoryManager:BindTransparency(head, holder)
    if root ~= base then pcall(function() root:Destroy() end) end
    return true
end

function AccessoryManager:Clear(character)
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    self.Connections = {}
    if not character then return end
    for _, c in ipairs(character:GetChildren()) do
        if (c:IsA("Accessory") and c:GetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE)) or c:GetAttribute(SCRIPTED_HAIR_ATTRIBUTE) then
            local w = c:FindFirstChild("WhiteRoseAccessoryWeld")
            if w and w:IsA("ObjectValue") then safeDestroy(w.Value) end
            safeDestroy(c)
        end
    end
end

function AccessoryManager:Sync(character, accessoryGroups)
    local assetIds = {}
    for _, ids in pairs(accessoryGroups) do for _, id in ipairs(ids) do table.insert(assetIds, tostring(id)) end end
    table.sort(assetIds)
    local sig = table.concat(assetIds, ",")

    if ClientState.Cache.AccessoryCharacter == character and ClientState.Cache.AccessorySignature == sig then return end
    ClientState.Cache.AccessoryCharacter, ClientState.Cache.AccessorySignature = character, sig
    self:Clear(character)

    for _, id in ipairs(assetIds) do
        task.spawn(function()
            for _ = 1, 10 do
                if not character or not character.Parent or ClientState.Cache.AccessorySignature ~= sig then return end
                local tmpl = ClientState.Cache.AccessoryTemplates[id]
                if not tmpl then
                    local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. tostring(id))
                    tmpl = ok and objs and objs[1]
                    if tmpl then ClientState.Cache.AccessoryTemplates[id] = tmpl end
                end
                if tmpl then
                    local clone = tmpl:Clone()
                    local acc = clone:IsA("Accessory") and clone or clone:FindFirstChildWhichIsA("Accessory", true)
                    if acc then
                        acc:SetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE, true)
                        if weldAccessory(character, acc) then break end
                    elseif attachMeshHair(character, clone) then break end
                    safeDestroy(clone)
                end
                task.wait(0.5)
            end
        end)
    end
end

local function isScriptedAccessory(inst)
    local cur = inst
    while cur and cur ~= game do
        if (cur:IsA("Accessory") and cur:GetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE)) or cur:GetAttribute(SCRIPTED_HAIR_ATTRIBUTE) then return true end
        cur = cur.Parent
    end
    return false
end

-- // Colors & Face Logic \ --
local function applyColor(char, group, color)
    if not char then return end
    local bc = char:FindFirstChildWhichIsA("BodyColors")
    if bc then
        pcall(function() bc[group .. "Color3"] = color end)
    elseif CONFIG.LimbMappings[group] then
        for _, n in ipairs(CONFIG.LimbMappings[group]) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then p.Color = color break end
        end
    end
end

local function captureColors(char, force)
    if not char or (not force and next(ClientState.Originals.LimbColors)) then return end
    ClientState.Originals.LimbColors = {}
    local bc = char:FindFirstChildWhichIsA("BodyColors")
    for group, names in pairs(CONFIG.LimbMappings) do
        local c
        if bc then pcall(function() c = bc[group .. "Color3"] end) end
        if not c then
            for _, n in ipairs(names) do local p = char:FindFirstChild(n) if p and p:IsA("BasePart") then c = p.Color break end end
        end
        ClientState.Originals.LimbColors[group] = c or Color3.fromRGB(245, 205, 172)
    end
end

local function resetColors()
    local char = Player.Character
    for group, color in pairs(ClientState.Originals.LimbColors) do
        applyColor(char, group, color)
        local opt = Library.Options[group .. "Color"]
        if opt then opt:SetValueRGB(color) end
    end
end

local function applyFaceState(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    local face = head and (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal"))
    if not face then return end

    if ClientState.Originals.FaceTransparency == nil then ClientState.Originals.FaceTransparency = face.Transparency end
    if ClientState.Originals.FaceTexture == nil then ClientState.Originals.FaceTexture = face.Texture end

    local hide = getToggleValue("Headless") or getToggleValue("Scary Smile Outfit")
    face.Transparency = hide and 1 or (ClientState.Originals.FaceTransparency or 0)
    face.Texture = getToggleValue("Epic Face") and CONFIG.AssetIDs.FaceTexture or (ClientState.Originals.FaceTexture or "")
end

-- // Clothing Logic \ --
local ClothingManager = { Hidden = {} }
local clothingTypes = { Shirt = { className = "Shirt", prop = "ShirtTemplate" }, Pants = { className = "Pants", prop = "PantsTemplate" }, TShirt = { className = "ShirtGraphic", prop = "Graphic" } }

local function restoreClothing(char, typeStr)
    local orig = ClientState.Originals.Clothing
    if typeStr == "TShirt" then
        for _, it in ipairs(orig.TShirts) do pcall(function() it.Parent = char end) end
        orig.TShirts = {}
    elseif orig[typeStr] then
        pcall(function() orig[typeStr].Parent = char end)
        orig[typeStr] = nil
    end
end

local function storeClothing(char, typeStr, cls)
    local orig = ClientState.Originals.Clothing
    if typeStr == "TShirt" then
        if #orig.TShirts > 0 then return end
        for _, it in ipairs(char:GetChildren()) do
            if it:IsA(cls) and it ~= ClientState.Scripted.TShirt and it.Name ~= "WhiteRose_ScriptedItem" and pcall(function() it.Parent = nil end) then table.insert(orig.TShirts, it) end
        end
    elseif not orig[typeStr] then
        local it = char:FindFirstChildOfClass(cls)
        if it and it.Name ~= "WhiteRose_ScriptedItem" and pcall(function() it.Parent = nil end) then orig[typeStr] = it end
    end
end

function ClothingManager:Apply(char, typeStr, itemName)
    if not char or self.Hidden[typeStr] then return end
    local def, assetId = clothingTypes[typeStr], CONFIG.Clothing[typeStr][itemName]
    if itemName == "Remove" then
        safeDestroy(ClientState.Scripted[typeStr])
        ClientState.Scripted[typeStr] = nil
        storeClothing(char, typeStr, def.className)
        return
    end

    local tmpl = assetId
    if type(assetId) == "number" then
        local k = def.className .. ":" .. assetId
        tmpl = ClientState.Cache.ClothingTemplates[k]
        if not tmpl then
            local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. assetId)
            local item = ok and objs and (objs[1]:IsA(def.className) and objs[1] or objs[1]:FindFirstChildWhichIsA(def.className, true))
            tmpl = item and item[def.prop]
            if tmpl then ClientState.Cache.ClothingTemplates[k] = tmpl end
        end
    end

    safeDestroy(ClientState.Scripted[typeStr])
    ClientState.Scripted[typeStr] = nil
    if not tmpl then restoreClothing(char, typeStr) return end

    storeClothing(char, typeStr, def.className)
    local it = Instance.new(def.className)
    it.Name, it[def.prop], it.Parent = "WhiteRose_ScriptedItem", tmpl, char
    ClientState.Scripted[typeStr] = it
end

function ClothingManager:Hide(char, typeStr)
    if not char or self.Hidden[typeStr] then return end
    safeDestroy(ClientState.Scripted[typeStr])
    ClientState.Scripted[typeStr] = nil
    storeClothing(char, typeStr, clothingTypes[typeStr].className)
    self.Hidden[typeStr] = true
end

function ClothingManager:Show(char, typeStr)
    if not self.Hidden[typeStr] then return end
    self.Hidden[typeStr] = nil
    restoreClothing(char, typeStr)
end

function ClothingManager:Restore(char)
    if not char then return end
    for t in pairs(clothingTypes) do safeDestroy(ClientState.Scripted[t]) ClientState.Scripted[t] = nil restoreClothing(char, t) self.Hidden[t] = nil end
end

-- // Animation & Emotes \ --
local function applyAnim(char, packName)
    packName = packName or "None"
    task.spawn(function()
        if not char then return end
        local anim = char:WaitForChild("Animate", 5)
        if not anim then return end
        local isR6 = isR6Rig(char)
        if isR6 and packName ~= "None" then
            packName = "None"
            if not ClientState.Cache.R6AnimWarned then
                ClientState.Cache.R6AnimWarned = true
                Library:Notify({ Title = "Animations", Content = "R6 rig detected - custom packs disabled.", Duration = 5 })
            end
        end

        if not next(ClientState.Cache.OriginalAnimations) then
            local function getID(n, c) local node = anim:FindFirstChild(n) local t = node and node:FindFirstChild(c) return t and t.AnimationId or nil end
            local o = { idle = { getID("idle", "Animation1"), getID("idle", "Animation2") }, walk = getID("walk", "WalkAnim"), run = getID("run", "RunAnim"), jump = getID("jump", "JumpAnim"), fall = getID("fall", "FallAnim"), climb = getID("climb", "ClimbAnim"), swim = getID("swim", "Swim"), swimidle = getID("swimidle", "SwimIdle") }
            ClientState.Cache.OriginalAnimations, CONFIG.Animations["None"] = o, o
        end

        local pack = {}
        for k, v in pairs(CONFIG.Animations[packName] or {}) do pack[k] = v end
        if not isR6 then
            for _, ovr in pairs(CONFIG.AnimationOverrides) do
                if getToggleValue(ovr.key) then for k, v in pairs(ovr.values) do pack[k] = v end end
            end
        end

        task.wait(0.1)
        local orig = ClientState.Cache.OriginalAnimations
        local function setID(n, c, v) local node = anim:FindFirstChild(n) local t = node and node:FindFirstChild(c) if t and v then t.AnimationId = v end end

        setID("idle", "Animation1", (pack.idle and pack.idle[1]) or (orig.idle and orig.idle[1]))
        setID("idle", "Animation2", (pack.idle and pack.idle[2]) or (orig.idle and orig.idle[2]))
        setID("walk", "WalkAnim", pack.walk or orig.walk)
        setID("run", "RunAnim", pack.run or orig.run)
        setID("jump", "JumpAnim", pack.jump or orig.jump)
        setID("fall", "FallAnim", pack.fall or orig.fall)
        setID("climb", "ClimbAnim", pack.climb or orig.climb)
        setID("swim", "Swim", pack.swim or orig.swim)
        setID("swimidle", "SwimIdle", pack.swimidle or orig.swimidle)
    end)
end

local function stopEmote()
    if ClientState.Scripted.CurrentEmote then pcall(function() ClientState.Scripted.CurrentEmote:Stop() end) ClientState.Scripted.CurrentEmote = nil end
    if ClientState.Connections.EmoteStop then ClientState.Connections.EmoteStop:Disconnect() ClientState.Connections.EmoteStop = nil end
end

local function playEmote(char, emoteName)
    stopEmote()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local id = CONFIG.Emotes[emoteName]
    if not hum or not id then return end
    task.spawn(function()
        local anim = Instance.new("Animation") anim.AnimationId = id
        local loaded = hum:LoadAnimation(anim) anim:Destroy()
        ClientState.Scripted.CurrentEmote = loaded
        loaded:Play()
        ClientState.Connections.EmoteStop = hum.Running:Connect(function(spd) if spd > 0.5 then stopEmote() end end)
    end)
end

-- // Sync Core \ --
local function syncCharacter(char)
    if not char then return end
    local activeAccs = { Auto = {} }
    for _, t in ipairs({ "Shirt", "Pants", "TShirt" }) do ClothingManager:Apply(char, t, getOptionValue(t .. "Selector", "None")) end

    for name, action in pairs(allActions) do
        if getToggleValue(name) then
            if action.type == "Accessory" then
                for _, ids in pairs(action.action) do for _, id in ipairs(ids) do table.insert(activeAccs.Auto, id) end end
            elseif not ClientState.Cache.AppliedActions[name] then
                pcall(action.action, char, true)
                ClientState.Cache.AppliedActions[name] = true
            end
        end
    end

    AccessoryManager:Sync(char, activeAccs)
    for group in pairs(CONFIG.LimbMappings) do
        local opt = Library.Options[group .. "Color"]
        if opt then applyColor(char, group, opt.Value) end
    end
    applyAnim(char, getOptionValue("AnimationPackSelector", "None"))
end

local syncPending, syncRunning = false, false
local function requestSync(char)
    if syncPending or syncRunning or not char then return end
    syncPending = true
    task.defer(function()
        syncPending = false
        if not char.Parent then return end
        syncRunning = true
        pcall(syncCharacter, char)
        syncRunning = false
    end)
end

local function fullReset(char)
    stopEmote()
    ClientState.Cache.AccessorySignature, ClientState.Cache.AccessoryCharacter, ClientState.Cache.AppliedActions = nil, nil, {}
    safeDestroy(ClientState.Scripted.HeadlessMesh)

    if char then
        ClothingManager:Restore(char)
        for _, a in ipairs(ClientState.Originals.Clothing.Accessories) do if a then pcall(function() a.Parent = char end) end end
        AccessoryManager:Clear(char)

        local head = char:FindFirstChild("Head")
        if head and ClientState.Originals.Headless then
            head.Transparency = ClientState.Originals.Headless.Transparency or 0
            local sm = head:FindFirstChildOfClass("SpecialMesh")
            if sm and ClientState.Originals.Headless.MeshScale then sm.Scale = ClientState.Originals.Headless.MeshScale end
        end
        applyFaceState(char)
    end
    ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }
    ClientState.Originals.LimbData = {}
    applyAnim(char, "None")
end

-- // Action Definitions \ --
allActions = {
    ["Headless"] = { category = "Body", type = "Function", action = function(c, e)
        local head = c and c:FindFirstChild("Head")
        if not head then return end
        if not ClientState.Originals.Headless then
            local sm = head:FindFirstChildOfClass("SpecialMesh")
            ClientState.Originals.Headless = { Transparency = head.Transparency, MeshScale = sm and sm.Scale }
        end
        head.Transparency = e and 1 or (ClientState.Originals.Headless.Transparency or 0)
        local sm = head:FindFirstChildOfClass("SpecialMesh")
        if sm then sm.Scale = e and Vector3.zero or (ClientState.Originals.Headless.MeshScale or Vector3.one) end
        applyFaceState(c)
    end },
    ["Korblox"] = { category = "Body", type = "Function", action = function(c, e)
        if not (c and c:FindFirstChild("RightLowerLeg")) then return end
        if e then
            if not ClientState.Originals.LimbData["Korblox"] then
                ClientState.Originals.LimbData["Korblox"] = { LowerMesh = c.RightLowerLeg.MeshId, LowerTrans = c.RightLowerLeg.Transparency, UpperMesh = c.RightUpperLeg.MeshId, UpperTex = c.RightUpperLeg.TextureID, FootMesh = c.RightFoot.MeshId, FootTrans = c.RightFoot.Transparency }
            end
            c.RightLowerLeg.MeshId, c.RightLowerLeg.Transparency = CONFIG.AssetIDs.KorbloxLeg, 1
            c.RightUpperLeg.MeshId, c.RightUpperLeg.TextureID = CONFIG.AssetIDs.KorbloxUpper, CONFIG.AssetIDs.KorbloxTex
            c.RightFoot.MeshId, c.RightFoot.Transparency = CONFIG.AssetIDs.KorbloxFoot, 1
        else
            local o = ClientState.Originals.LimbData["Korblox"]
            if o then
                c.RightLowerLeg.MeshId, c.RightLowerLeg.Transparency = o.LowerMesh, o.LowerTrans
                c.RightUpperLeg.MeshId, c.RightUpperLeg.TextureID = o.UpperMesh, o.UpperTex
                c.RightFoot.MeshId, c.RightFoot.Transparency = o.FootMesh, o.FootTrans
            end
        end
    end },
    ["Naked"] = { category = "Body", type = "Function", action = function(c, e) for _, t in ipairs({ "Shirt", "Pants", "TShirt" }) do if e then ClothingManager:Hide(c, t) else ClothingManager:Show(c, t) end end end },
    ["Remove Hair"] = { category = "Body", type = "Function", action = function(c, e)
        if not c then return end
        if e then
            for _, h in ipairs(c:GetChildren()) do
                if h:IsA("Accessory") and pcall(function() return h.AccessoryType end) and h.AccessoryType == Enum.AccessoryType.Hair then
                    table.insert(ClientState.Originals.Clothing.Hair, h) h.Parent = nil
                end
            end
        else
            for _, h in ipairs(ClientState.Originals.Clothing.Hair) do h.Parent = c end
            ClientState.Originals.Clothing.Hair = {}
        end
    end },
    ["Epic Face"] = { category = "Faces", type = "Function", action = function(c) applyFaceState(c) end },
    ["Scary Smile Outfit"] = { category = "Outfits", type = "Function", action = function(c, e)
        if not c then return end
        if e then
            if not ClientState.Scripted.ScarySmile then
                local acc = Instance.new("Accessory") acc.Name = "ScarySmileAccessory"
                local h = Instance.new("Part", acc) h.Name, h.Size, h.Transparency = "Handle", Vector3.one, 1
                local m = Instance.new("SpecialMesh", h) m.MeshType, m.MeshId, m.Scale = Enum.MeshType.FileMesh, "rbxassetid://111022241256851", Vector3.new(1.03, 1.03, 1.03)
                local d = Instance.new("Decal", h) d.Face, d.Texture = Enum.NormalId.Front, "http://www.roblox.com/asset/?id=120935988855219"
                local ns = Instance.new("Shirt") ns.Name, ns.ShirtTemplate = "WhiteRose_ScriptedItem", "http://www.roblox.com/asset/?id=11275376793"
                local np = Instance.new("Pants") np.Name, np.PantsTemplate = "WhiteRose_ScriptedItem", "http://www.roblox.com/asset/?id=5043452775"
                ClientState.Scripted.ScarySmile = { acc = acc, shirt = ns, pants = np }
            end
            local it = ClientState.Scripted.ScarySmile
            ClothingManager:Hide(c, "Shirt") ClothingManager:Hide(c, "Pants")
            it.shirt.Parent, it.pants.Parent = c, c
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then hum:AddAccessory(it.acc) else it.acc.Parent = c end
            local head = c:FindFirstChild("Head") if head then AccessoryManager:BindTransparency(head, it.acc) end
            applyFaceState(c)
        else
            local it = ClientState.Scripted.ScarySmile
            if it then safeDestroy(it.acc) safeDestroy(it.shirt) safeDestroy(it.pants) ClientState.Scripted.ScarySmile = nil end
            ClothingManager:Show(c, "Shirt") ClothingManager:Show(c, "Pants")
            applyFaceState(c)
        end
    end },
    ["Remove Original Shirt"] = { category = "Outfit", type = "Function", action = function(c, e) if e then ClothingManager:Hide(c, "Shirt") else ClothingManager:Show(c, "Shirt") end end },
    ["Remove Original Pants"] = { category = "Outfit", type = "Function", action = function(c, e) if e then ClothingManager:Hide(c, "Pants") else ClothingManager:Show(c, "Pants") end end },
    ["Remove Original T-Shirts"] = { category = "Outfit", type = "Function", action = function(c, e) if e then ClothingManager:Hide(c, "TShirt") else ClothingManager:Show(c, "TShirt") end end },
    ["Remove Original Accessories"] = { category = "Outfit", type = "Function", action = function(c, e)
        if not c then return end
        if e then
            for _, it in ipairs(c:GetChildren()) do if it:IsA("Accessory") and not it:GetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE) then table.insert(ClientState.Originals.Clothing.Accessories, it) it.Parent = nil end end
        else
            for _, it in ipairs(ClientState.Originals.Clothing.Accessories) do pcall(function() it.Parent = c end) end
            ClientState.Originals.Clothing.Accessories = {}
        end
    end }
}

-- Compact Batch Registration for Accessories
local accList = {
    { "Vinsmoke Blonde TS Boy Hair", "Body", "Hair", 16990001265 }, { "Sanji (✔)", "Body", "Hair", 86494218909624 },
    { "Valkyrie Helm", "Accessories", "Head", 1365767 }, { "Wings of Duality", "Accessories", "Torso", 493489765 },
    { "Lowered Hair Ear Tufts (Pink)", "Accessories", "Head", 8275341781 }, { "Y2K Long Wavy Pigtails in Pink", "Accessories", "Head", 11364071979 },
    { "Middle Swept Spiky Bangs in Pink", "Accessories", "Head", 9008209306 }, { "Wispy Willow Pigtails in Pink", "Accessories", "Head", 12394572381 },
    { "Straight Bangs (Pink)", "Accessories", "Head", 12850356248 }, { "Black Cutesy Side Ruffles 3.0", "Accessories", "Torso", 12366756122 },
    { "Fiery Horns of the Netherworld", "Accessories", "Head", 215718515 }, { "Blackvalk", "Accessories", "Head", 124730194 },
    { "Frozen Horns of the Frigid Planes", "Accessories", "Head", 74891470 }, { "Silver King of the Night", "Accessories", "Head", 439945661 },
    { "Poisoned Horns of the Toxic Wasteland", "Accessories", "Head", 1744060292 }, { "Sanji Ears (PTS)", "Accessories", "Face", 81759542155072 },
    { "Sanji", "Accessories", "Face", 93768783006575 }, { "Black Folded Collar with Buttons", "Accessories", "Neck", 80756618475441 },
    { "Tailcoat Addon", "Accessories", "Waist", 114813132263944 }
}
for _, it in ipairs(accList) do allActions[it[1]] = { category = it[2], type = "Accessory", action = { [it[3]] = { it[4] } } } end

-- // Titan Engine / Visuals \ --
local activeTweens = setmetatable({}, { __mode = "k" })
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local function playSafeTween(inst, props)
    if not inst then return end
    if activeTweens[inst] then activeTweens[inst]:Cancel() end
    local tw = TweenService:Create(inst, tweenInfo, props)
    activeTweens[inst] = tw
    tw.Completed:Connect(function() if activeTweens[inst] == tw then activeTweens[inst] = nil end end)
    tw:Play()
end

local function getEffect(cls, name)
    local eff = Lighting:FindFirstChild(name)
    if not eff then eff = Instance.new(cls, Lighting) eff.Name = name end
    return eff
end

-- // NameTag Logic \ --
local lastNameTagUpdate = 0
local function updateNameTag()
    if _G.AnonymizerLoaded or tick() - lastNameTagUpdate < 0.5 then return end
    lastNameTagUpdate = tick()
    if not getToggleValue("NameTagEnabled") then return end

    local tag = getOptionValue("NameTagText", "[VIP]")
    local col = (Library.Options.NameTagColor and Library.Options.NameTagColor.Value) or Color3.fromRGB(255, 215, 0)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.DisplayName ~= tag .. " " .. Player.Name then hum.DisplayName = tag .. " " .. Player.Name end

    pcall(function()
        local scroll = Player.PlayerGui.MainGui.main.tos.scroll
        for _, s in ipairs(scroll:GetChildren()) do
            local nl = s.Name == "sample" and s:FindFirstChild("name")
            if nl and nl:IsA("TextLabel") and string.find(nl.Text, Player.Name, 1, true) and not string.find(nl.Text, tag, 1, true) then
                nl.Text, nl.TextColor3 = tag .. " " .. nl.Text, col
            end
        end
    end)
end

-- // Build UI \ --
local Tabs = { Appearance = Window:AddTab("Appearance", "shirt"), Useful = Window:AddTab("Useful", "wrench"), Titan = Window:AddTab("Titan Engine", "globe"), Settings = Window:AddTab("UI Settings", "settings") }
local Groups = {
    Accessories = Tabs.Appearance:AddLeftGroupbox("Accessories"), Body = Tabs.Appearance:AddLeftGroupbox("Body Modifications"),
    Faces = Tabs.Appearance:AddLeftGroupbox("Faces"), Clothing = Tabs.Appearance:AddLeftGroupbox("Clothing (Visual)"),
    Outfit = Tabs.Appearance:AddLeftGroupbox("Outfit Management (Original)"), Animation = Tabs.Appearance:AddLeftGroupbox("Animation"),
    Emotes = Tabs.Appearance:AddRightGroupbox("Custom Emotes & Dances"), NameTag = Tabs.Appearance:AddRightGroupbox("Custom NameTag"),
    Outfits = Tabs.Appearance:AddLeftGroupbox("Full Outfits"), Tools = Tabs.Useful:AddLeftGroupbox("Tools"),
    TitanEnv = Tabs.Titan:AddLeftGroupbox("Environment 🌍"), TitanVis = Tabs.Titan:AddRightGroupbox("Visuals 🎨")
}

for name, data in pairs(allActions) do
    if Groups[data.category] then
        Groups[data.category]:AddToggle(name, { Text = name, Default = false, Callback = function(v)
            ClientState.Cache.AppliedActions[name] = nil
            if not v and data.type == "Function" then pcall(data.action, Player.Character, false) end
            syncCharacter(Player.Character)
        end })
    end
end

if Player.Character then captureColors(Player.Character, false) end
for _, limb in ipairs({ "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }) do
    Groups.Body:AddLabel(limb .. " Color"):AddColorPicker(limb .. "Color", {
        Default = ClientState.Originals.LimbColors[limb] or Color3.fromRGB(245, 205, 172),
        Callback = function(c) applyColor(Player.Character, limb, c) end
    })
end
Groups.Body:AddButton("Reset Limb Colors", resetColors)

for _, typeStr in ipairs({ "Shirt", "Pants", "TShirt" }) do
    Groups.Clothing:AddDropdown(typeStr .. "Selector", {
        Values = getKeys(CONFIG.Clothing[typeStr]), Default = "None", Text = (typeStr == "TShirt" and "T-Shirt" or typeStr),
        Callback = function(s) ClothingManager:Apply(Player.Character, typeStr, s) end
    })
end

Groups.Animation:AddDropdown("AnimationPackSelector", { Values = getKeys(CONFIG.Animations), Default = "None", Text = "Animation Pack", Callback = function(p) applyAnim(Player.Character, p) end })
for name, override in pairs(CONFIG.AnimationOverrides) do
    Groups.Animation:AddToggle(override.key, { Text = name, Default = false, Callback = function() applyAnim(Player.Character, getOptionValue("AnimationPackSelector", "None")) end })
end

Groups.Emotes:AddDropdown("EmoteSelector", { Values = getKeys(CONFIG.Emotes), Default = "None", Text = "Select Emote" })
Groups.Emotes:AddButton("Play Emote ▶️", function() playEmote(Player.Character, getOptionValue("EmoteSelector", "None")) end)
Groups.Emotes:AddButton("Stop Emote ⏹️", stopEmote)

Groups.NameTag:AddInput("NameTagText", { Default = "[VIP]", Text = "Tag Text", Placeholder = "[VIP]" })
Groups.NameTag:AddLabel("Tag Color"):AddColorPicker("NameTagColor", { Default = Color3.fromRGB(255, 215, 0), Title = "Tag Color" })
Groups.NameTag:AddToggle("NameTagEnabled", { Text = "Enable NameTag", Default = false, Callback = function(v)
    if ClientState.Connections.Env["NameTagLoop"] then ClientState.Connections.Env["NameTagLoop"]:Disconnect() ClientState.Connections.Env["NameTagLoop"] = nil end
    if v then ClientState.Connections.Env["NameTagLoop"] = RunService.RenderStepped:Connect(updateNameTag)
    elseif Player.Character and not _G.AnonymizerLoaded then local h = Player.Character:FindFirstChildOfClass("Humanoid") if h then h.DisplayName = Player.DisplayName end end
end })

Groups.Tools:AddLabel("Toggle UI"):AddKeyPicker("ToggleUIKeybind", { Default = "RightControl", NoUI = true, Text = "Toggle UI" })
Library.ToggleKeybind = Library.Options.ToggleUIKeybind

-- // Titan Engine Tools \ --
Groups.TitanEnv:AddToggle("RainToggle", {
    Text = "Enable Rain & Fog", Default = false,
    Callback = function(enabled)
        pcall(function() RunService:UnbindFromRenderStep("ExecutorRainLoop") end)
        local old = Workspace:FindFirstChild("MyExecutorRainPart") if old then old:Destroy() end
        if not enabled then
            Lighting.FogStart = 0 playSafeTween(Lighting, { FogEnd = 100000, FogColor = Color3.fromRGB(190, 190, 190) }) return
        end
        task.spawn(function()
            local p = Instance.new("Part", Workspace) p.Name, p.Size, p.Transparency, p.CanCollide, p.Anchored = "MyExecutorRainPart", Vector3.new(200, 1, 200), 1, false, true
            local em = Instance.new("ParticleEmitter", p) em.Name, em.Texture, em.Color = "RainEmitter", "rbxassetid://241868005", ColorSequence.new(Color3.fromRGB(200, 200, 215))
            em.LightEmission, em.Orientation, em.Size, em.EmissionDirection = 1, Enum.ParticleOrientation.FacingCameraWorldUp, NumberSequence.new(5), Enum.NormalId.Bottom
            local int = getOptionValue("RainIntensitySlider", 50)
            em.Rate, em.Speed, em.Lifetime = int * 40, NumberRange.new(50 + int), NumberRange.new(1.2)
            RunService:BindToRenderStep("ExecutorRainLoop", Enum.RenderPriority.Camera.Value + 1, function()
                local cam = Workspace.CurrentCamera if cam and p.Parent then p.Position = cam.CFrame.Position + Vector3.new(0, 70, 0) end
            end)
            Lighting.FogStart = 0
            playSafeTween(Lighting, { FogColor = Color3.fromRGB(155, 160, 165), FogEnd = 700 - (int * 4) })
        end)
    end
})

Groups.TitanEnv:AddSlider("RainIntensitySlider", {
    Text = "Rain & Storm Intensity", Default = 50, Min = 10, Max = 100, Rounding = 0,
    Callback = function(val)
        local p = Workspace:FindFirstChild("MyExecutorRainPart")
        local em = p and p:FindFirstChild("RainEmitter")
        if em then em.Rate, em.Speed = val * 40, NumberRange.new(50 + val) playSafeTween(Lighting, { FogEnd = 700 - (val * 4) }) end
    end
})

Groups.TitanEnv:AddButton("Apply MineCraft Textures", function()
    task.spawn(function()
        local MS, CS = game:GetService("MaterialService"), game:GetService("CollectionService")
        local mats = {
            [Enum.Material.Asphalt]={"11545435992"}, [Enum.Material.Basalt]={"11545440462","9730055481"}, [Enum.Material.Brick]={"11545453130","9888913739"},
            [Enum.Material.Cobblestone]={"11545460611"}, [Enum.Material.Concrete]={"11545468983"}, [Enum.Material.CorrodedMetal]={"11545476330"},
            [Enum.Material.DiamondPlate]={"11545495407"}, [Enum.Material.Fabric]={"118776397"}, [Enum.Material.Foil]={"11545501473"},
            [Enum.Material.Grass]={"11545527424"}, [Enum.Material.Ground]={"11545533676"}, [Enum.Material.Ice]={"11546405701"},
            [Enum.Material.LeafyGrass]={"11546412010"}, [Enum.Material.Marble]={"11546425898"}, [Enum.Material.Metal]={"11546431794"},
            [Enum.Material.Sand]={"11546468464"}, [Enum.Material.Wood]={"11546477504"}, [Enum.Material.WoodPlanks]={"11546480686"}
        }
        for _, c in ipairs(MS:GetChildren()) do if c:IsA("MaterialVariant") and string.sub(c.Name, 1, 4) == "abs_" then pcall(function() MS:SetBaseMaterialOverride(c.BaseMaterial, "") end) c:Destroy() end end
        local active = {}
        for m, ids in pairs(mats) do
            local id = ids[math.random(1, #ids)]
            local v = Instance.new("MaterialVariant", MS) v.Name, v.BaseMaterial, v.ColorMap, v.StudsPerTile = "abs_" .. m.Name, m, string.find(id, "rbxassetid://") and id or ("rbxassetid://" .. id), 4
            active[m] = v.Name
        end
        local function proc(p)
            if not p:IsA("BasePart") or p:IsA("Terrain") or (p.Parent and p.Parent:FindFirstChildOfClass("Humanoid")) then return end
            local var = active[p.Material]
            if var and p.MaterialVariant ~= var then
                if p:IsA("MeshPart") then p.TextureID = "" end
                p.MaterialVariant = var
                for _, d in ipairs(p:GetChildren()) do if d:IsA("Texture") or d:IsA("Decal") then d.Transparency = 1 elseif d:IsA("SurfaceAppearance") then d:Destroy() end end
            end
        end
        if ClientState.Connections.Env["MinecraftTextures"] then ClientState.Connections.Env["MinecraftTextures"]:Disconnect() end
        ClientState.Connections.Env["MinecraftTextures"] = Workspace.DescendantAdded:Connect(proc)
        for _, d in ipairs(Workspace:GetDescendants()) do proc(d) end
        Library:Notify({ Title = "System", Content = "MineCraft Textures applied!", Duration = 3 })
    end)
end)

Groups.TitanEnv:AddButton("Enforce Universal Sky", function()
    local skyBox = { SkyboxBk = "rbxassetid://12216109205", SkyboxDn = "rbxassetid://12216109875", SkyboxFt = "rbxassetid://12216109489", SkyboxLf = "rbxassetid://12216110170", SkyboxRt = "rbxassetid://12216110471", SkyboxUp = "rbxassetid://12216108877" }
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    for p, v in pairs(skyBox) do sky[p] = v end
    Lighting.ClockTime, Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = 14, 2.0, Color3.fromRGB(135, 140, 150), Color3.fromRGB(135, 140, 150)
    for _, d in ipairs(Lighting:GetChildren()) do if (d:IsA("Atmosphere") or d:IsA("BloomEffect") or d:IsA("ColorCorrectionEffect") or d:IsA("SunRaysEffect")) and not string.match(d.Name, "^MyRTX_") then d:Destroy() end end
    Library:Notify({ Title = "System", Content = "Universal Sky applied!", Duration = 3 })
end)

Groups.TitanVis:AddButton("Activate RTX Day Mode ☀️", function()
    local atm, blm = getEffect("Atmosphere", "MyRTX_Atmosphere"), getEffect("BloomEffect", "MyRTX_Bloom")
    local sun, col = getEffect("SunRaysEffect", "MyRTX_SunRays"), getEffect("ColorCorrectionEffect", "MyRTX_Color")
    local blr = getEffect("BlurEffect", "MyRTX_Blur")
    sun.Spread = 0.2
    playSafeTween(Lighting, { ClockTime = 14, Brightness = 3, Ambient = Color3.fromRGB(170, 170, 170), OutdoorAmbient = Color3.fromRGB(210, 210, 210), FogColor = Color3.fromRGB(255, 245, 230), FogStart = 300, FogEnd = 1000, ExposureCompensation = 0 })
    playSafeTween(atm, { Color = Color3.fromRGB(199, 199, 199), Decay = Color3.fromRGB(106, 112, 125) })
    playSafeTween(sun, { Intensity = 0.1 })
    playSafeTween(blm, { Intensity = 1.0, Threshold = 0.8, Size = 24 })
    playSafeTween(col, { Saturation = 0, Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255) })
    playSafeTween(blr, { Size = 0 })
    Library:Notify({ Title = "Visuals", Content = "RTX Day Mode Applied!", Duration = 3 })
end)

-- // Reset & Unload Logic \ --
local function resetAllUI()
    for n in pairs(allActions) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(false) end end
    if Library.Toggles["NameTagEnabled"] then Library.Toggles["NameTagEnabled"]:SetValue(false) end
    for _, t in ipairs({ "Shirt", "Pants", "TShirt" }) do if Library.Options[t .. "Selector"] then Library.Options[t .. "Selector"]:SetValue("None") end end
    if Library.Options["AnimationPackSelector"] then Library.Options["AnimationPackSelector"]:SetValue("None") end
    for _, ovr in pairs(CONFIG.AnimationOverrides) do if Library.Toggles[ovr.key] then Library.Toggles[ovr.key]:SetValue(false) end end
    if Library.Options["EmoteSelector"] then Library.Options["EmoteSelector"]:SetValue("None") end
    stopEmote() resetColors()
end

Groups.Tools:AddButton("Reset All", function() resetAllUI() fullReset(Player.Character) end)
Groups.Tools:AddButton("Unload Script", function()
    for _, c in pairs(ClientState.Connections.Env or {}) do if c then pcall(function() c:Disconnect() end) end end
    local rPart = Workspace:FindFirstChild("MyExecutorRainPart") if rPart then rPart:Destroy() end
    pcall(function() RunService:UnbindFromRenderStep("ExecutorRainLoop") end)
    resetAllUI() fullReset(Player.Character)
    if ClientState.Connections.CharacterAdded then ClientState.Connections.CharacterAdded:Disconnect() end
    getgenv().WhiteRoseLoaded = nil
    Library:Unload()
end)

-- // Character LifeCycle \ --
ClientState.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(c)
    task.spawn(function()
        c:WaitForChild("Humanoid", 3) c:WaitForChild("Head", 5)
        local t0 = tick() while tick() - t0 < 2 and not Player:HasAppearanceLoaded() do task.wait(0.1) end
        if not c.Parent then return end

        stopEmote()
        ClientState.Scripted = { Shirt = nil, Pants = nil, TShirt = nil, HeadlessMesh = nil, SkyObject = nil, CurrentEmote = nil, ScarySmile = nil }
        ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }
        ClientState.Originals.LimbColors, ClientState.Originals.LimbData, ClientState.Cache.AppliedActions = {}, {}, {}
        ClientState.Originals.FaceTexture, ClientState.Originals.FaceTransparency, ClientState.Originals.Headless = nil, nil, nil

        captureColors(c, true)
        pcall(syncCharacter, c)

        if ClientState.Connections.Env["AppearanceEnforcer"] then ClientState.Connections.Env["AppearanceEnforcer"]:Disconnect() end
        ClientState.Connections.Env["AppearanceEnforcer"] = c.DescendantAdded:Connect(function(d)
            if not d.Parent or d:GetAttribute("WhiteRoseRefreshing") or d:IsA("Tool") or d:FindFirstAncestorWhichIsA("Tool") or isScriptedAccessory(d) or d.Name == "WhiteRose_ScriptedItem" then return end
            task.wait()
            if d.Parent and (d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("Accessory") or d:IsA("BodyColors") or d:IsA("Decal") or d:IsA("SpecialMesh")) then requestSync(c) end
        end)
    end)
end)

if Player.Character then captureColors(Player.Character, true) end

-- // Save/Theme Config \ --
if ThemeManager and SaveManager then
    ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({ "ToggleUIKeybind" })
    ThemeManager:SetFolder("WhiteRose_Settings") SaveManager:SetFolder("WhiteRose_Settings")
    ThemeManager:ApplyToTab(Tabs.Settings) SaveManager:BuildConfigSection(Tabs.Settings)
    local oldLoad = SaveManager.Load
    if oldLoad then
        function SaveManager:Load(...)
            resetAllUI() fullReset(Player.Character)
            local ok, err = oldLoad(self, ...)
            if ok then task.wait(0.2) syncCharacter(Player.Character) end
            return ok, err
        end
    end
    SaveManager:LoadAutoloadConfig()
end
