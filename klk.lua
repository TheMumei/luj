--[[
WhiteRose - V4.5 (Fully Fixed)
- Fixed syntax error (De fault -> Default) and all trailing-space bugs
- Accessories re-attach after death (retry + fallback attachments)
- Minecraft Textures no longer breaks Terrain (Terrain skipped, no global material override)
- R6 rigs: custom animation packs/overrides disabled (fixes broken jump)
- Safer resets, unload, anonymizer, emotes, and face restoration
]]

if getgenv().WhiteRoseLoaded then return end

-- // Services \ --
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- // Library Loading \ --
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local success, Library = pcall(function()
    return loadstring(game:HttpGet(repo .. "Library.lua"))()
end)

if not success or not Library then
    warn("WhiteRose: Library failed to load.")
    return
end

local sT, ThemeManager = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
end)

local sS, SaveManager = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)

ThemeManager = sT and ThemeManager or nil
SaveManager = sS and SaveManager or nil

getgenv().WhiteRoseLoaded = true

local Player = Players.LocalPlayer

-- // UI Setup \ --
local Window = Library:CreateWindow({
    Name = "WhiteRose",
    Title = "WhiteRose",
    SubTitle = "Optimized by MrOG & AI",
    Draggable = true,
    Footer = "Made By gemini & Thank him | v1.2.0"
})

-- // Configuration & Constants \ --
local CONFIG = {
    RenderName = "WhiteRose_SkyUpdate",
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
        RightLeg = { "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }
    },

    Clothing = {
        Shirt = {
            ["None"] = false,
            ["Remove"] = false,
            ["Yuno Gasai Mirai Nikki"] = 6412908981
        },
        Pants = {
            ["None"] = false,
            ["Remove"] = false,
            ["Yuno Gasai Mirai Nikki"] = 6412913951,
            ["Yuno Gasai Anime Black Dress V2"] = 14696725708
        },
        TShirt = {
            ["None"] = false,
            ["Remove"] = false,
            ["Oh Noez!"] = "http://www.roblox.com/asset/?id=1641286",
            ["Spread The Lulz!"] = "http://www.roblox.com/asset/?id=24774765"
        }
    },

    Animations = {
        ["None"] = {},
        ["Vampire"] = {
            idle = { "rbxassetid://1083445855", "rbxassetid://1083450166" },
            walk = "rbxassetid://1083473930",
            run = "rbxassetid://1083462077",
            jump = "rbxassetid://1083455352",
            fall = "rbxassetid://1083443587",
            climb = "rbxassetid://1083439238",
            swim = "rbxassetid://1083222527",
            swimidle = "rbxassetid://1083225406"
        }
    },

    AnimationOverrides = {
        ["Robot Swim"] = {
            key = "RobotSwim",
            values = {
                swim = "rbxassetid://10921253142",
                swimidle = "rbxassetid://10921253767"
            }
        },
        ["Mage Fall"] = {
            key = "MageFall",
            values = {
                fall = "rbxassetid://10921148939"
            }
        },
        ["Elder Jump"] = {
            key = "ElderJump",
            values = {
                jump = "rbxassetid://10921107367"
            }
        },
        ["Toy Run"] = {
            key = "ToyRun",
            values = {
                run = "rbxassetid://10921306285"
            }
        }
    },

    Emotes = {
        ["None"] = false,
        ["Dance 1"] = "rbxassetid://507771019",
        ["Dance 2"] = "rbxassetid://507771955",
        ["Dance 3"] = "rbxassetid://507772104",
        ["Wave / Hello"] = "rbxassetid://507770239",
        ["Point"] = "rbxassetid://507770453",
        ["Cheer"] = "rbxassetid://507770677",
        ["Laugh"] = "rbxassetid://507770818"
    }
}

-- // Client State Management \ --
local allActions

local ClientState = {
    Originals = {
        LimbColors = {},
        FaceTexture = nil,
        FaceTransparency = nil,
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
        OriginalAnimations = {},
        ClothingTemplates = {},
        AccessoryTemplates = {},
        AccessorySignature = nil,
        AccessoryCharacter = nil,
        AppliedActions = {},
        R6AnimWarned = nil
    }
}

-- // Utility Functions \ --
local function getKeys(t)
    local k = {}
    for i in pairs(t) do
        table.insert(k, i)
    end
    table.sort(k)
    return k
end

local function getOptionValue(name, defaultValue)
    local option = Library.Options[name]
    if option and option.Value ~= nil then
        return option.Value
    end
    return defaultValue
end

local function getToggleValue(name)
    local toggle = Library.Toggles[name]
    return toggle and toggle.Value or false
end

local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function()
            obj:SetAttribute("WhiteRoseDestroying", true)
            for _, d in ipairs(obj:GetDescendants()) do
                d:SetAttribute("WhiteRoseDestroying", true)
            end
        end)
        obj:Destroy()
    end
end

-- // Rig Detection (R6 animation fix) \ --
local function getRigType(char)
    if not char then return nil end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.RigType
    end

    if char:FindFirstChild("UpperTorso") then
        return Enum.HumanoidRigType.R15
    elseif char:FindFirstChild("Torso") then
        return Enum.HumanoidRigType.R6
    end

    return nil
end

local function isR6Rig(char)
    return getRigType(char) == Enum.HumanoidRigType.R6
end

-- // Accessory Manager (respawn retry + fallback attachments) \ --
local SCRIPTED_ACCESSORY_ATTRIBUTE = "WhiteRoseScriptedAccessory"
local AccessoryManager = {}

local FALLBACK_ATTACHMENT_CFRAMES = {
    HairAttachment = CFrame.new(0, 0.6, 0),
    HatAttachment = CFrame.new(0, 0.6, 0),
    FaceFrontAttachment = CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0),
    FaceCenterAttachment = CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0),
    NeckAttachment = CFrame.new(0, 1, 0),
    LeftShoulderAttachment = CFrame.new(-1, 0.8, 0),
    RightShoulderAttachment = CFrame.new(1, 0.8, 0),
    WaistAttachment = CFrame.new(0, -0.8, 0),
}

local function weldAccessory(character, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end

    local handleAttachment, characterAttachment

    for _, att in ipairs(handle:GetChildren()) do
        if att:IsA("Attachment") then
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("Attachment") and descendant.Name == att.Name then
                    local part = descendant.Parent
                    if part and part:IsA("BasePart") then
                        handleAttachment = att
                        characterAttachment = descendant
                        break
                    end
                end
            end
            if handleAttachment then break end
        end
    end

    if not handleAttachment then
        handleAttachment = handle:FindFirstChildWhichIsA("Attachment")
    end

    if not characterAttachment then
        local head = character:FindFirstChild("Head")
        if not head then return false end

        if handleAttachment then
            local fallbackName = handleAttachment.Name .. "_WhiteRoseFallback"
            characterAttachment = head:FindFirstChild(fallbackName)
            if not characterAttachment then
                characterAttachment = Instance.new("Attachment")
                characterAttachment.Name = fallbackName
                characterAttachment.CFrame = FALLBACK_ATTACHMENT_CFRAMES[handleAttachment.Name] or CFrame.new(0, 0.6, 0)
                characterAttachment.Parent = head
            end
        else
            handleAttachment = Instance.new("Attachment")
            handleAttachment.Name = "WhiteRoseHandleAttachment"
            handleAttachment.Parent = handle

            characterAttachment = head:FindFirstChild("WhiteRoseFallback")
            if not characterAttachment then
                characterAttachment = Instance.new("Attachment")
                characterAttachment.Name = "WhiteRoseFallback"
                characterAttachment.CFrame = CFrame.new(0, 0.6, 0)
                characterAttachment.Parent = head
            end
        end
    end

    local targetPart = characterAttachment.Parent
    if not targetPart or not targetPart:IsA("BasePart") then return false end

    accessory.Parent = character
    handle.CFrame = targetPart.CFrame * characterAttachment.CFrame * handleAttachment.CFrame:Inverse()

    local weld = Instance.new("Weld")
    weld.Name = "WhiteRoseAccessoryWeld"
    weld.Part0 = targetPart
    weld.Part1 = handle
    weld.C0 = characterAttachment.CFrame
    weld.C1 = handleAttachment.CFrame
    weld.Parent = targetPart

    local weldReference = Instance.new("ObjectValue")
    weldReference.Name = "WhiteRoseAccessoryWeld"
    weldReference.Value = weld
    weldReference.Parent = accessory

    return true
end

function AccessoryManager:Clear(character)
    if not character then return end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") and child:GetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE) then
            local weldReference = child:FindFirstChild("WhiteRoseAccessoryWeld")
            if weldReference and weldReference:IsA("ObjectValue") then
                safeDestroy(weldReference.Value)
            end
            safeDestroy(child)
        end
    end
end

function AccessoryManager:LoadTemplate(assetId)
    local template = ClientState.Cache.AccessoryTemplates[assetId]
    if template and template:FindFirstChild("Handle") then
        return template
    end

    local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. tostring(assetId))
    local asset = ok and objects and objects[1]
    template = asset and (asset:IsA("Accessory") and asset or asset:FindFirstChildWhichIsA("Accessory", true))

    if template then
        ClientState.Cache.AccessoryTemplates[assetId] = template
    end

    return template
end

function AccessoryManager:Add(character, assetId)
    if not character or not character.Parent then return nil end

    local template = self:LoadTemplate(assetId)
    if not template then return nil end

    local accessory = template:Clone()
    accessory:SetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE, true)

    if not weldAccessory(character, accessory) then
        safeDestroy(accessory)
        return nil
    end

    return accessory
end

function AccessoryManager:Sync(character, accessoryGroups)
    local assetIds = {}
    for _, ids in pairs(accessoryGroups) do
        for _, assetId in ipairs(ids) do
            table.insert(assetIds, tostring(assetId))
        end
    end
    table.sort(assetIds)
    local signature = table.concat(assetIds, ",")

    if ClientState.Cache.AccessoryCharacter == character and ClientState.Cache.AccessorySignature == signature then
        return
    end

    ClientState.Cache.AccessoryCharacter = character
    ClientState.Cache.AccessorySignature = signature

    self:Clear(character)

    for _, assetId in ipairs(assetIds) do
        task.spawn(function()
            local attached = false
            for _ = 1, 10 do
                if not character or not character.Parent then return end
                if ClientState.Cache.AccessorySignature ~= signature then return end
                if self:Add(character, assetId) then
                    attached = true
                    break
                end
                task.wait(0.5)
            end
            if not attached then
                warn("WhiteRose: Could not attach accessory " .. tostring(assetId))
            end
        end)
    end
end

local function isScriptedAccessory(instance)
    local current = instance
    while current and current ~= game do
        if current:IsA("Accessory") and current:GetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE) then
            return true
        end
        current = current.Parent
    end
    return false
end

-- // Core Logic Functions \ --
local function captureColors(char, force)
    if not char then return end
    if not force and next(ClientState.Originals.LimbColors) then return end

    ClientState.Originals.LimbColors = {}

    local bc = char:FindFirstChildWhichIsA("BodyColors")
    if bc then
        local m = ClientState.Originals.LimbColors
        m.Head = bc.HeadColor3
        m.Torso = bc.TorsoColor3
        m.LeftArm = bc.LeftArmColor3
        m.RightArm = bc.RightArmColor3
        m.LeftLeg = bc.LeftLegColor3
        m.RightLeg = bc.RightLegColor3
        return
    end

    for group, names in pairs(CONFIG.LimbMappings) do
        local found = false
        for _, name in ipairs(names) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                ClientState.Originals.LimbColors[group] = p.Color
                found = true
                break
            end
        end

        if not found then
            ClientState.Originals.LimbColors[group] = Color3.fromRGB(245, 205, 172)
        end
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
        if p and p:IsA("BasePart") then
            p.Color = color
        end
    end
end

local function resetColors()
    local char = Player.Character

    for group, color in pairs(ClientState.Originals.LimbColors) do
        applyColor(char, group, color)
        local option = Library.Options[group .. "Color"]
        if option then
            option:SetValueRGB(color)
        end
    end
end

local function resolveClothingTemplate(assetId, className, propertyName)
    if type(assetId) ~= "number" then
        return assetId
    end

    local cacheKey = className .. ":" .. assetId
    local cached = ClientState.Cache.ClothingTemplates[cacheKey]
    if cached then return cached end

    local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. assetId)
    local catalogItem = ok and objects and objects[1]
    local clothing = catalogItem and (catalogItem:IsA(className) and catalogItem or catalogItem:FindFirstChildWhichIsA(className, true))
    local template = clothing and clothing[propertyName]

    if template then
        ClientState.Cache.ClothingTemplates[cacheKey] = template
    end

    return template
end

local ClothingManager = { Hidden = {} }

local clothingTypes = {
    Shirt = { className = "Shirt", propertyName = "ShirtTemplate" },
    Pants = { className = "Pants", propertyName = "PantsTemplate" },
    TShirt = { className = "ShirtGraphic", propertyName = "Graphic" }
}

local function restoreOriginalClothing(character, typeStr)
    local originals = ClientState.Originals.Clothing

    if typeStr == "TShirt" then
        for _, item in ipairs(originals.TShirts) do
            if item then item.Parent = character end
        end
        originals.TShirts = {}
        return
    end

    local item = originals[typeStr]
    if item then item.Parent = character end
    originals[typeStr] = nil
end

local function storeOriginalClothing(character, typeStr, className)
    local originals = ClientState.Originals.Clothing

    if typeStr == "TShirt" then
        if #originals.TShirts > 0 then return end

        for _, item in ipairs(character:GetChildren()) do
            if item:IsA(className) and item ~= ClientState.Scripted.TShirt then
                table.insert(originals.TShirts, item)
                item.Parent = nil
            end
        end
        return
    end

    local original = originals[typeStr] or character:FindFirstChildOfClass(className)
    if original then
        originals[typeStr] = original
        original.Parent = nil
    end
end

function ClothingManager:Apply(character, typeStr, itemName)
    if not character then return end

    local definition = clothingTypes[typeStr]
    if not definition then return end
    if self.Hidden[typeStr] then return end

    local assetId = CONFIG.Clothing[typeStr][itemName]

    if itemName == "Remove" then
        safeDestroy(ClientState.Scripted[typeStr])
        ClientState.Scripted[typeStr] = nil
        storeOriginalClothing(character, typeStr, definition.className)
        return
    end

    local template = resolveClothingTemplate(assetId, definition.className, definition.propertyName)
    local current = ClientState.Scripted[typeStr]

    if template and current and current.Parent == character and current[definition.propertyName] == template then
        return
    end

    safeDestroy(current)
    ClientState.Scripted[typeStr] = nil

    if not template then
        if assetId and assetId ~= false then
            warn("WhiteRose: Could not load " .. typeStr .. " asset " .. tostring(assetId))
        end
        restoreOriginalClothing(character, typeStr)
        return
    end

    storeOriginalClothing(character, typeStr, definition.className)

    local item = Instance.new(definition.className)
    item.Name = "WhiteRose_ScriptedItem"
    item[definition.propertyName] = template
    item.Parent = character

    ClientState.Scripted[typeStr] = item
end

function ClothingManager:Hide(character, typeStr)
    local definition = clothingTypes[typeStr]
    if not character or not definition or self.Hidden[typeStr] then return end

    safeDestroy(ClientState.Scripted[typeStr])
    ClientState.Scripted[typeStr] = nil

    storeOriginalClothing(character, typeStr, definition.className)
    self.Hidden[typeStr] = true
end

function ClothingManager:Show(character, typeStr)
    if not self.Hidden[typeStr] then return end

    self.Hidden[typeStr] = nil
    restoreOriginalClothing(character, typeStr)
end

function ClothingManager:Restore(character)
    if not character then return end

    for typeStr in pairs(clothingTypes) do
        safeDestroy(ClientState.Scripted[typeStr])
        ClientState.Scripted[typeStr] = nil
        restoreOriginalClothing(character, typeStr)
        self.Hidden[typeStr] = nil
    end
end

local function applyClothingItem(char, typeStr, itemName)
    ClothingManager:Apply(char, typeStr, itemName)
end

local function updateRainbow(enabled)
    if ClientState.Connections.Rainbow then
        ClientState.Connections.Rainbow:Disconnect()
        ClientState.Connections.Rainbow = nil
    end

    if enabled then
        local hue = 0
        ClientState.Connections.Rainbow = RunService.Heartbeat:Connect(function(dt)
            hue = (hue + dt * CONFIG.RainbowSpeed) % 1
            local col = Color3.fromHSV(hue, 1, 1)

            if Player.Character then
                for group in pairs(CONFIG.LimbMappings) do
                    applyColor(Player.Character, group, col)
                end
            end
        end)
    else
        for group in pairs(CONFIG.LimbMappings) do
            local colorOption = Library.Options[group .. "Color"]
            if colorOption then
                applyColor(Player.Character, group, colorOption.Value)
            end
        end
    end
end

-- // Animation Apply (R6-safe) \ --
local function applyAnim(char, packName)
    packName = packName or "None"

    task.spawn(function()
        if not char then return end

        local anim = char:WaitForChild("Animate", 5)
        if not anim then return end

        -- R6 FIX: R15 packs/overrides cannot play on R6 and break jump/movement.
        local isR6 = isR6Rig(char)

        if isR6 and packName ~= "None" then
            packName = "None"

            if not ClientState.Cache.R6AnimWarned then
                ClientState.Cache.R6AnimWarned = true
                Library:Notify({
                    Title = "Animations",
                    Content = "R6 rig detected - custom animation packs are disabled (R15 animations break R6 jump).",
                    Duration = 5
                })
            end
        end

        -- Safe capture of original animation IDs (works on R6 and R15 layouts)
        if not next(ClientState.Cache.OriginalAnimations) then
            local function getID(nodeName, childName)
                local node = anim:FindFirstChild(nodeName)
                local target = node and node:FindFirstChild(childName)
                return target and target.AnimationId or nil
            end

            local o = {
                idle = { getID("idle", "Animation1"), getID("idle", "Animation2") },
                walk = getID("walk", "WalkAnim"),
                run = getID("run", "RunAnim"),
                jump = getID("jump", "JumpAnim"),
                fall = getID("fall", "FallAnim"),
                climb = getID("climb", "ClimbAnim"),
                swim = getID("swim", "Swim"),
                swimidle = getID("swimidle", "SwimIdle")
            }

            ClientState.Cache.OriginalAnimations = o
            CONFIG.Animations["None"] = o
        end

        if not next(ClientState.Cache.OriginalAnimations) then return end

        local pack = {}
        for animationName, animationId in pairs(CONFIG.Animations[packName] or {}) do
            pack[animationName] = animationId
        end

        -- Overrides are R15-only
        if not isR6 then
            for _, override in pairs(CONFIG.AnimationOverrides) do
                local toggle = Library.Toggles[override.key]
                if toggle and toggle.Value then
                    for animationName, animationId in pairs(override.values) do
                        pack[animationName] = animationId
                    end
                end
            end
        end

        task.wait(0.1)

        local function setID(nodeName, childName, value)
            if not value then return end
            local node = anim:FindFirstChild(nodeName)
            local target = node and node:FindFirstChild(childName)
            if target then
                target.AnimationId = value
            end
        end

        local orig = ClientState.Cache.OriginalAnimations

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
    if ClientState.Scripted.CurrentEmote then
        pcall(function()
            ClientState.Scripted.CurrentEmote:Stop()
        end)
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
            if speed > 0.5 then
                stopEmote()
            end
        end)
    end)
end

local function syncCharacter(char)
    if not char then return end

    local activeAccessories = { Auto = {} }

    applyClothingItem(char, "Shirt", getOptionValue("ShirtSelector", "None"))
    applyClothingItem(char, "Pants", getOptionValue("PantsSelector", "None"))
    applyClothingItem(char, "TShirt", getOptionValue("TShirtSelector", "None"))

    for name, action in pairs(allActions) do
        if getToggleValue(name) then
            if action.type == "Accessory" then
                for _, assetIds in pairs(action.action) do
                    for _, assetId in ipairs(assetIds) do
                        table.insert(activeAccessories.Auto, assetId)
                    end
                end
            elseif not ClientState.Cache.AppliedActions[name] then
                pcall(action.action, char, true)
                ClientState.Cache.AppliedActions[name] = true
            end
        end
    end

    AccessoryManager:Sync(char, activeAccessories)

    if getToggleValue("RainbowMode") then
        updateRainbow(true)
    else
        for group in pairs(CONFIG.LimbMappings) do
            local colorOption = Library.Options[group .. "Color"]
            if colorOption then
                applyColor(char, group, colorOption.Value)
            end
        end
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
        local ok, err = pcall(syncCharacter, char)
        syncRunning = false

        if not ok then
            warn("WhiteRose Sync Error: " .. tostring(err))
        end
    end)
end

local function fullReset(char)
    if ClientState.Connections.Rainbow then
        ClientState.Connections.Rainbow:Disconnect()
        ClientState.Connections.Rainbow = nil
    end

    stopEmote()

    ClientState.Cache.AccessorySignature = nil
    ClientState.Cache.AccessoryCharacter = nil
    ClientState.Cache.AppliedActions = {}

    safeDestroy(ClientState.Scripted.HeadlessMesh)

    if char then
        ClothingManager:Restore(char)

        for _, a in ipairs(ClientState.Originals.Clothing.Accessories) do
            if a then a.Parent = char end
        end

        AccessoryManager:Clear(char)

        local head = char:FindFirstChild("Head")
        if head then
            if ClientState.Originals.FaceTexture or ClientState.Originals.FaceTransparency ~= nil then
                local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")

                if not face and ClientState.Originals.FaceTexture then
                    face = Instance.new("Decal")
                    face.Name = "face"
                    face.Parent = head
                end

                if face then
                    if ClientState.Originals.FaceTexture then
                        face.Texture = ClientState.Originals.FaceTexture
                    end
                    face.Transparency = ClientState.Originals.FaceTransparency or 0
                end
            end

            if ClientState.Originals.Headless then
                head.Transparency = ClientState.Originals.Headless.Transparency or 0
                local sm = head:FindFirstChildOfClass("SpecialMesh")
                if sm and ClientState.Originals.Headless.MeshScale then
                    sm.Scale = ClientState.Originals.Headless.MeshScale
                end
            end
        end
    end

    ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }
    ClientState.Originals.LimbData = {}

    applyAnim(char, "None")
end

allActions = {
    ["Headless"] = {
        category = "Body",
        type = "Function",
        action = function(c, e)
            local head = c and c:FindFirstChild("Head")
            if not head then return end

            if not ClientState.Originals.Headless then
                ClientState.Originals.Headless = { Transparency = head.Transparency, MeshScale = nil }
                local sm = head:FindFirstChildOfClass("SpecialMesh")
                if sm then
                    ClientState.Originals.Headless.MeshScale = sm.Scale
                end
            end

            local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")

            if e then
                if face then
                    if ClientState.Originals.FaceTexture == nil then
                        ClientState.Originals.FaceTexture = face.Texture
                    end
                    if ClientState.Originals.FaceTransparency == nil then
                        ClientState.Originals.FaceTransparency = face.Transparency
                    end
                    face.Transparency = 1
                end

                head.Transparency = 1

                local sm = head:FindFirstChildOfClass("SpecialMesh")
                if sm then
                    sm.Scale = Vector3.new(0, 0, 0)
                end
            else
                if face then
                    face.Transparency = ClientState.Originals.FaceTransparency or 0
                end

                if ClientState.Originals.Headless then
                    head.Transparency = ClientState.Originals.Headless.Transparency or 0
                    local sm = head:FindFirstChildOfClass("SpecialMesh")
                    if sm and ClientState.Originals.Headless.MeshScale then
                        sm.Scale = ClientState.Originals.Headless.MeshScale
                    end
                end
            end
        end
    },

    ["Korblox"] = {
        category = "Body",
        type = "Function",
        action = function(c, e)
            if not (c and c:FindFirstChild("RightLowerLeg")) then return end

            if e then
                if not ClientState.Originals.LimbData["Korblox"] then
                    ClientState.Originals.LimbData["Korblox"] = {
                        LowerMesh = c.RightLowerLeg.MeshId,
                        LowerTrans = c.RightLowerLeg.Transparency,
                        UpperMesh = c.RightUpperLeg.MeshId,
                        UpperTex = c.RightUpperLeg.TextureID,
                        FootMesh = c.RightFoot.MeshId,
                        FootTrans = c.RightFoot.Transparency
                    }
                end

                c.RightLowerLeg.MeshId = CONFIG.AssetIDs.KorbloxLeg
                c.RightLowerLeg.Transparency = 1

                c.RightUpperLeg.MeshId = CONFIG.AssetIDs.KorbloxUpper
                c.RightUpperLeg.TextureID = CONFIG.AssetIDs.KorbloxTex

                c.RightFoot.MeshId = CONFIG.AssetIDs.KorbloxFoot
                c.RightFoot.Transparency = 1
            else
                local orig = ClientState.Originals.LimbData["Korblox"]
                if orig then
                    c.RightLowerLeg.MeshId = orig.LowerMesh
                    c.RightLowerLeg.Transparency = orig.LowerTrans

                    c.RightUpperLeg.MeshId = orig.UpperMesh
                    c.RightUpperLeg.TextureID = orig.UpperTex

                    c.RightFoot.MeshId = orig.FootMesh
                    c.RightFoot.Transparency = orig.FootTrans
                end
            end
        end
    },

    ["Naked"] = {
        category = "Body",
        type = "Function",
        action = function(c, e)
            if not c then return end

            if e then
                ClothingManager:Hide(c, "Shirt")
                ClothingManager:Hide(c, "Pants")
                ClothingManager:Hide(c, "TShirt")
            else
                ClothingManager:Show(c, "Shirt")
                ClothingManager:Show(c, "Pants")
                ClothingManager:Show(c, "TShirt")
            end
        end
    },

    ["Remove Hair"] = {
        category = "Body",
        type = "Function",
        action = function(c, e)
            if not c then return end

            if e then
                for _, h in ipairs(c:GetChildren()) do
                    if h:IsA("Accessory") then
                        local ok, accessoryType = pcall(function()
                            return h.AccessoryType
                        end)

                        if ok and accessoryType == Enum.AccessoryType.Hair then
                            table.insert(ClientState.Originals.Clothing.Hair, h)
                            h.Parent = nil
                        end
                    end
                end
            else
                for _, h in ipairs(ClientState.Originals.Clothing.Hair) do
                    h.Parent = c
                end
                ClientState.Originals.Clothing.Hair = {}
            end
        end
    },

    ["Epic Face"] = {
        category = "Faces",
        type = "Function",
        action = function(c, e)
            local head = c and c:FindFirstChild("Head")
            if not head then return end

            local face = head:FindFirstChild("face")
            if not face then return end

            if e then
                if ClientState.Originals.FaceTexture == nil then
                    ClientState.Originals.FaceTexture = face.Texture
                end
                face.Texture = CONFIG.AssetIDs.FaceTexture
            else
                if ClientState.Originals.FaceTexture then
                    face.Texture = ClientState.Originals.FaceTexture
                end
            end
        end
    },

    ["Scary Smile Outfit"] = {
        category = "Outfits",
        type = "Function",
        action = function(c, e)
            if not c then return end

            if e then
                local s = c:FindFirstChildOfClass("Shirt")
                if s and not ClientState.Originals.Clothing.Shirt then
                    ClientState.Originals.Clothing.Shirt = s
                    s.Parent = nil
                end

                local p = c:FindFirstChildOfClass("Pants")
                if p and not ClientState.Originals.Clothing.Pants then
                    ClientState.Originals.Clothing.Pants = p
                    p.Parent = nil
                end

                if c.Head then
                    local face = c.Head:FindFirstChild("face") or c.Head:FindFirstChildOfClass("Decal")
                    if face then
                        if ClientState.Originals.FaceTexture == nil then
                            ClientState.Originals.FaceTexture = face.Texture
                        end
                        if ClientState.Originals.FaceTransparency == nil then
                            ClientState.Originals.FaceTransparency = face.Transparency
                        end
                        face.Transparency = 1
                    end
                end

                for _, x in ipairs(c:GetChildren()) do
                    if x:IsA("Accessory") and x.Name == "ScarySmileAccessory" then
                        safeDestroy(x)
                    end
                end

                local acc = Instance.new("Accessory")
                acc.Name = "ScarySmileAccessory"

                local h = Instance.new("Part")
                h.Name = "Handle"
                h.Size = Vector3.one
                h.Transparency = 1
                h.Parent = acc

                local m = Instance.new("SpecialMesh")
                m.MeshType = Enum.MeshType.FileMesh
                m.MeshId = "rbxassetid://111022241256851"
                m.Scale = Vector3.new(1.03, 1.03, 1.03)
                m.Parent = h

                local d = Instance.new("Decal")
                d.Face = Enum.NormalId.Front
                d.Texture = "http://www.roblox.com/asset/?id=120935988855219"
                d.Parent = h

                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:AddAccessory(acc)
                else
                    acc.Parent = c
                end

                local ns = Instance.new("Shirt")
                ns.Name = "WhiteRose_ScriptedItem"
                ns.ShirtTemplate = "http://www.roblox.com/asset/?id=11275376793"
                ns.Parent = c

                local np = Instance.new("Pants")
                np.Name = "WhiteRose_ScriptedItem"
                np.PantsTemplate = "http://www.roblox.com/asset/?id=5043452775"
                np.Parent = c
            else
                for _, x in ipairs(c:GetChildren()) do
                    if x.Name == "WhiteRose_ScriptedItem" or x.Name == "ScarySmileAccessory" then
                        safeDestroy(x)
                    end
                end

                local head = c:FindFirstChild("Head")
                if head then
                    local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
                    if face then
                        face.Transparency = ClientState.Originals.FaceTransparency or 0
                        if ClientState.Originals.FaceTexture then
                            face.Texture = ClientState.Originals.FaceTexture
                        end
                    end
                end

                syncCharacter(c)
            end
        end
    },

    ["Remove Original Shirt"] = {
        category = "Outfit",
        type = "Function",
        action = function(c, e)
            if not c then return end
            if e then
                ClothingManager:Hide(c, "Shirt")
            else
                ClothingManager:Show(c, "Shirt")
            end
        end
    },

    ["Remove Original Pants"] = {
        category = "Outfit",
        type = "Function",
        action = function(c, e)
            if not c then return end
            if e then
                ClothingManager:Hide(c, "Pants")
            else
                ClothingManager:Show(c, "Pants")
            end
        end
    },

    ["Remove Original T-Shirts"] = {
        category = "Outfit",
        type = "Function",
        action = function(c, e)
            if not c then return end
            if e then
                ClothingManager:Hide(c, "TShirt")
            else
                ClothingManager:Show(c, "TShirt")
            end
        end
    },

    ["Remove Original Accessories"] = {
        category = "Outfit",
        type = "Function",
        action = function(c, e)
            if not c then return end

            if e then
                for _, item in ipairs(c:GetChildren()) do
                    if item:IsA("Accessory") and not item:GetAttribute(SCRIPTED_ACCESSORY_ATTRIBUTE) then
                        table.insert(ClientState.Originals.Clothing.Accessories, item)
                        item.Parent = nil
                    end
                end
            else
                for _, item in ipairs(ClientState.Originals.Clothing.Accessories) do
                    item.Parent = c
                end
                ClientState.Originals.Clothing.Accessories = {}
            end
        end
    },

    ["Valkyrie Helm"] = { category = "Accessories", type = "Accessory", action = { Head = { 1365767 } } },
    ["Wings of Duality"] = { category = "Accessories", type = "Accessory", action = { Torso = { 493489765 } } },
    ["Lowered Hair Ear Tufts (Pink)"] = { category = "Accessories", type = "Accessory", action = { Head = { 8275341781 } } },
    ["Y2K Long Wavy Pigtails in Pink"] = { category = "Accessories", type = "Accessory", action = { Head = { 11364071979 } } },
    ["Middle Swept Spiky Bangs in Pink"] = { category = "Accessories", type = "Accessory", action = { Head = { 9008209306 } } },
    ["Celebrity Bling"] = { category = "Accessories", type = "Accessory", action = { Head = { 6239323549 } } },
    ["Red Angry Anime Hitmarker Filter"] = { category = "Accessories", type = "Accessory", action = { Head = { 9922633567 } } },
    ["Red Goth Axe"] = { category = "Accessories", type = "Accessory", action = { Torso = { 11386880969 } } },
    ["Katana [Handheld]"] = { category = "Accessories", type = "Accessory", action = { Auto = { 12380877175 } } },
    ["Wispy Willow Pigtails in Pink"] = { category = "Accessories", type = "Accessory", action = { Head = { 12394572381 } } },
    ["Straight Bangs (Pink)"] = { category = "Accessories", type = "Accessory", action = { Head = { 12850356248 } } },
    ["Black Cutesy Side Ruffles 3.0"] = { category = "Accessories", type = "Accessory", action = { Torso = { 12366756122 } } },
    ["Fiery Horns of the Netherworld"] = { category = "Accessories", type = "Accessory", action = { Head = { 215718515 } } },
    ["Blackvalk"] = { category = "Accessories", type = "Accessory", action = { Head = { 124730194 } } },
    ["Frozen Horns of the Frigid Planes"] = { category = "Accessories", type = "Accessory", action = { Head = { 74891470 } } },
    ["Silver King of the Night"] = { category = "Accessories", type = "Accessory", action = { Head = { 439945661 } } },
    ["Poisoned Horns of the Toxic Wasteland"] = { category = "Accessories", type = "Accessory", action = { Head = { 1744060292 } } }
}

-- // Titan Engine Logic \ --
local activeTweens = {}
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function playSafeTween(instance, properties)
    if not instance then return end

    if activeTweens[instance] then
        activeTweens[instance]:Cancel()
    end

    local tween = TweenService:Create(instance, tweenInfo, properties)
    activeTweens[instance] = tween
    tween:Play()
end

local atmosphere, bloom, colorCorr, sunRays, blur

local function ensureEffects()
    if not atmosphere or not atmosphere.Parent then
        atmosphere = Lighting:FindFirstChild("MyRTX_Atmosphere")
        if not atmosphere then
            atmosphere = Instance.new("Atmosphere")
            atmosphere.Name = "MyRTX_Atmosphere"
            atmosphere.Parent = Lighting
        end
    end

    if not bloom or not bloom.Parent then
        bloom = Lighting:FindFirstChild("MyRTX_Bloom")
        if not bloom then
            bloom = Instance.new("BloomEffect")
            bloom.Name = "MyRTX_Bloom"
            bloom.Parent = Lighting
        end
    end

    if not sunRays or not sunRays.Parent then
        sunRays = Lighting:FindFirstChild("MyRTX_SunRays")
        if not sunRays then
            sunRays = Instance.new("SunRaysEffect")
            sunRays.Name = "MyRTX_SunRays"
            sunRays.Parent = Lighting
        end
    end

    if not colorCorr or not colorCorr.Parent then
        colorCorr = Lighting:FindFirstChild("MyRTX_Color")
        if not colorCorr then
            colorCorr = Instance.new("ColorCorrectionEffect")
            colorCorr.Name = "MyRTX_Color"
            colorCorr.Parent = Lighting
        end
    end

    if not blur or not blur.Parent then
        blur = Lighting:FindFirstChild("MyRTX_Blur")
        if not blur then
            blur = Instance.new("BlurEffect")
            blur.Name = "MyRTX_Blur"
            blur.Parent = Lighting
        end
    end

    if sunRays then
        sunRays.Spread = 0.2
    end
end

-- // NameTag Logic \ --
local lastNameTagUpdate = 0

local function updateNameTag()
    if _G.AnonymizerLoaded then return end
    if tick() - lastNameTagUpdate < 0.5 then return end

    lastNameTagUpdate = tick()

    local enabled = getToggleValue("NameTagEnabled")
    if not enabled then return end

    local tag = getOptionValue("NameTagText", "[VIP]")
    local colorOption = Library.Options.NameTagColor
    local col = colorOption and colorOption.Value or Color3.fromRGB(255, 215, 0)

    if Player.Character then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
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
    if ClientState.Connections.Env["NameTagLoop"] then
        ClientState.Connections.Env["NameTagLoop"]:Disconnect()
    end

    ClientState.Connections.Env["NameTagLoop"] = RunService.RenderStepped:Connect(updateNameTag)
end

local function disableNameTag()
    if ClientState.Connections.Env["NameTagLoop"] then
        ClientState.Connections.Env["NameTagLoop"]:Disconnect()
        ClientState.Connections.Env["NameTagLoop"] = nil
    end

    if Player.Character and not _G.AnonymizerLoaded then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayName = Player.DisplayName
        end
    end
end

-- // UI Construction \ --
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

for name, data in pairs(allActions) do
    if Groups[data.category] then
        Groups[data.category]:AddToggle(name, {
            Text = name,
            Default = false,
            Callback = function(v)
                ClientState.Cache.AppliedActions[name] = nil

                if not v and data.type == "Function" then
                    pcall(data.action, Player.Character, false)
                end

                syncCharacter(Player.Character)
            end
        })
    end
end

Groups.Body:AddToggle("RainbowMode", {
    Text = "Rainbow Body Mode",
    Default = false,
    Callback = updateRainbow
})

if Player.Character then
    captureColors(Player.Character, false)
end

local fallback = Color3.fromRGB(245, 205, 172)

for _, limb in ipairs({ "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }) do
    local defaultColor = ClientState.Originals.LimbColors[limb] or fallback

    Groups.Body:AddLabel(limb .. " Color"):AddColorPicker(limb .. "Color", {
        Default = defaultColor,
        Callback = function(c)
            applyColor(Player.Character, limb, c)
        end
    })
end

Groups.Body:AddButton("Reset Limb Colors", resetColors)

Groups.Clothing:AddDropdown("ShirtSelector", {
    Values = getKeys(CONFIG.Clothing.Shirt),
    Default = "None",
    Text = "Shirt",
    Callback = function(s)
        applyClothingItem(Player.Character, "Shirt", s)
    end
})

Groups.Clothing:AddDropdown("PantsSelector", {
    Values = getKeys(CONFIG.Clothing.Pants),
    Default = "None",
    Text = "Pants",
    Callback = function(s)
        applyClothingItem(Player.Character, "Pants", s)
    end
})

Groups.Clothing:AddDropdown("TShirtSelector", {
    Values = getKeys(CONFIG.Clothing.TShirt),
    Default = "None",
    Text = "T-Shirt",
    Callback = function(s)
        applyClothingItem(Player.Character, "TShirt", s)
    end
})

Groups.Animation:AddDropdown("AnimationPackSelector", {
    Values = getKeys(CONFIG.Animations),
    Default = "None",
    Text = "Animation Pack",
    Callback = function(p)
        applyAnim(Player.Character, p)
    end
})

for name, override in pairs(CONFIG.AnimationOverrides) do
    Groups.Animation:AddToggle(override.key, {
        Text = name,
        Default = false,
        Callback = function()
            local packOption = Library.Options.AnimationPackSelector
            applyAnim(Player.Character, packOption and packOption.Value or "None")
        end
    })
end

Groups.Emotes:AddDropdown("EmoteSelector", {
    Values = getKeys(CONFIG.Emotes),
    Default = "None",
    Text = "Select Emote"
})

Groups.Emotes:AddButton("Play Emote ▶️", function()
    playEmote(Player.Character, getOptionValue("EmoteSelector", "None"))
end)

Groups.Emotes:AddButton("Stop Emote ⏹️", stopEmote)

Groups.NameTag:AddInput("NameTagText", {
    Default = "[VIP]",
    Numeric = false,
    Finished = false,
    Text = "Tag Text",
    Placeholder = "[VIP]"
})

Groups.NameTag:AddLabel("Tag Color"):AddColorPicker("NameTagColor", {
    Default = Color3.fromRGB(255, 215, 0),
    Title = "Tag Color"
})

Groups.NameTag:AddToggle("NameTagEnabled", {
    Text = "Enable NameTag",
    Default = false,
    Callback = function(v)
        if v then
            enableNameTag()
        else
            disableNameTag()
        end
    end
})

Groups.Tools:AddLabel("Toggle UI"):AddKeyPicker("ToggleUIKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Toggle UI"
})

Library.ToggleKeybind = Library.Options.ToggleUIKeybind

-- // Titan Engine Buttons \ --
Groups.TitanEnv:AddToggle("RainToggle", {
    Text = "Enable Rain & Fog",
    Default = false,
    Callback = function(enabled)
        local LightingService = game:GetService("Lighting")
        local RunServiceLocal = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")

        local RENDER_LOOP_NAME = "ExecutorRainLoop"
        local RAIN_PART_NAME = "MyExecutorRainPart"

        if not enabled then
            pcall(function()
                RunServiceLocal:UnbindFromRenderStep(RENDER_LOOP_NAME)
            end)

            local oldPart = Workspace:FindFirstChild(RAIN_PART_NAME)
            if oldPart then oldPart:Destroy() end

            LightingService.FogStart = 0

            local fogTween = TweenService:Create(LightingService, TweenInfo.new(2, Enum.EasingStyle.Sine), {
                FogEnd = 100000,
                FogColor = Color3.fromRGB(190, 190, 190)
            })
            fogTween:Play()

            return
        end

        pcall(function()
            RunServiceLocal:UnbindFromRenderStep(RENDER_LOOP_NAME)
        end)

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

            local intensity = getOptionValue("RainIntensitySlider", 50)

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

            RunServiceLocal:BindToRenderStep(RENDER_LOOP_NAME, Enum.RenderPriority.Camera.Value + 1, function()
                local currentCam = Workspace.CurrentCamera
                if currentCam and rainPart and rainPart.Parent then
                    local camPos = currentCam.CFrame.Position
                    rainPart.Position = Vector3.new(camPos.X, camPos.Y + 70, camPos.Z)
                end
            end)

            LightingService.FogStart = 0

            local fogTween = TweenService:Create(LightingService, TweenInfo.new(2, Enum.EasingStyle.Sine), {
                FogColor = Color3.fromRGB(155, 160, 165),
                FogEnd = 700 - (intensity * 4)
            })
            fogTween:Play()

            Library:Notify({
                Title = "System",
                Content = "Rain and Fog applied!",
                Duration = 3
            })
        end)
    end
})

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

            TweenService:Create(game:GetService("Lighting"), TweenInfo.new(1, Enum.EasingStyle.Sine), {
                FogEnd = 700 - (Value * 4)
            }):Play()
        end
    end
})

-- // MineCraft Textures (Terrain-safe) \ --
Groups.TitanEnv:AddButton("Apply MineCraft Textures", function()
    task.spawn(function()
        local workspace = workspace
        local MaterialService = game:GetService("MaterialService")
        local CollectionService = game:GetService("CollectionService")

        local MATERIAL_CONFIG = {
            [Enum.Material.Asphalt] = { "11545435992" },
            [Enum.Material.Basalt] = { "11545440462", "9730055481", "7263615718", "7263618080" },
            [Enum.Material.Brick] = { "11545453130", "9888913739" },
            [Enum.Material.Cobblestone] = { "11545460611", "9730055481" },
            [Enum.Material.Concrete] = { "11545468983", "7800894670", "9406005008", "8868470905" },
            [Enum.Material.CorrodedMetal] = { "11545476330", "6920910334" },
            [Enum.Material.CrackedLava] = { "11545484781", "2842360263" },
            [Enum.Material.DiamondPlate] = { "11545495407", "152572134" },
            [Enum.Material.Fabric] = { "118776397" },
            [Enum.Material.Foil] = { "11545501473", "6928057336" },
            [Enum.Material.Glacier] = { "11545521725", "2167946571" },
            [Enum.Material.Granite] = { "11545524005", "151776555" },
            [Enum.Material.Grass] = { "11545527424" },
            [Enum.Material.Ground] = { "11545533676", "7069953551" },
            [Enum.Material.Ice] = { "11546405701", "152528023" },
            [Enum.Material.LeafyGrass] = { "11546412010", "7069955228" },
            [Enum.Material.Limestone] = { "11546415687", "10180605826" },
            [Enum.Material.Marble] = { "11546425898", "7247387416" },
            [Enum.Material.Metal] = { "11546431794", "152572134" },
            [Enum.Material.Mud] = { "11546437412" },
            [Enum.Material.Pavement] = { "11546440685", "8139086777" },
            [Enum.Material.Pebble] = { "11546453485", "151776533" },
            [Enum.Material.Rock] = { "11545456858" },
            [Enum.Material.Salt] = { "11546461451", "6756014847" },
            [Enum.Material.Sand] = { "11546468464" },
            [Enum.Material.Sandstone] = { "11546471860", "152572221" },
            [Enum.Material.Slate] = { "11546474778" },
            [Enum.Material.Snow] = { "11108916253" },
            [Enum.Material.Wood] = { "11546477504" },
            [Enum.Material.WoodPlanks] = { "11546480686", "8676581022" }
        }

        -- Clear old variants/overrides
        for _, child in ipairs(MaterialService:GetChildren()) do
            if child:IsA("MaterialVariant") and string.sub(child.Name, 1, 4) == "abs_" then
                pcall(function()
                    MaterialService:SetBaseMaterialOverride(child.BaseMaterial, "")
                end)
                task.defer(function()
                    child:Destroy()
                end)
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
            -- NOTE: NO global SetBaseMaterialOverride here!
            -- A global override re-skins the Terrain too.
            -- Variants are applied per-part below instead.
        end

        local humanoidCache = setmetatable({}, { __mode = "k" })

        local function IsHumanoidPart(part)
            local parent = part.Parent
            if not parent then return false end

            if humanoidCache[parent] ~= nil then
                return humanoidCache[parent]
            end

            if CollectionService:HasTag(parent, "Titan_Character") then
                humanoidCache[parent] = true
                return true
            end

            local isCharacter = parent:FindFirstChildOfClass("Humanoid") ~= nil
            humanoidCache[parent] = isCharacter

            if isCharacter then
                CollectionService:AddTag(parent, "Titan_Character")
            end

            return isCharacter
        end

        local partQueue = {}
        local processingQueue = false

        local function ProcessPartLogic(part, variantName)
            -- TERRAIN FIX: never touch the Terrain object
            if not part.Parent or part:IsA("Terrain") or IsHumanoidPart(part) then return end

            if part:IsA("MeshPart") then
                part.TextureID = ""
            end

            part.MaterialVariant = variantName

            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Texture") or child:IsA("Decal") then
                    child.Transparency = 1
                elseif child:IsA("SurfaceAppearance") then
                    child:Destroy()
                end
            end
        end

        local function ProcessQueue()
            if processingQueue then return end

            processingQueue = true

            task.spawn(function()
                while #partQueue > 0 do
                    local chunkCount = math.min(500, #partQueue)

                    for _ = 1, chunkCount do
                        local item = table.remove(partQueue, #partQueue)
                        if item and item.part and item.part.Parent then
                            pcall(ProcessPartLogic, item.part, item.variantName)
                        end
                    end

                    if #partQueue > 0 then
                        task.wait()
                    end
                end

                processingQueue = false
            end)
        end

        local function ProcessPart(part, isImmediate)
            -- TERRAIN FIX: Terrain is a BasePart, so explicitly skip it
            if not part:IsA("BasePart") or part:IsA("Terrain") then return end

            local variantName = ActiveVariants[part.Material]
            if not variantName then return end

            if part.MaterialVariant == variantName then return end

            if isImmediate then
                pcall(ProcessPartLogic, part, variantName)
            else
                table.insert(partQueue, { part = part, variantName = variantName })
                ProcessQueue()
            end
        end

        if ClientState.Connections.Env["MinecraftTextures"] then
            ClientState.Connections.Env["MinecraftTextures"]:Disconnect()
        end

        ClientState.Connections.Env["MinecraftTextures"] = workspace.DescendantAdded:Connect(function(part)
            ProcessPart(part, false)
        end)

        task.spawn(function()
            local allDescendants = workspace:GetDescendants()
            local CHUNK_SIZE = 1500

            for i = 1, #allDescendants do
                ProcessPart(allDescendants[i], true)
                if i % CHUNK_SIZE == 0 then
                    task.wait()
                end
            end

            Library:Notify({
                Title = "System",
                Content = "MineCraft Textures applied! (Terrain untouched)",
                Duration = 3
            })
        end)
    end)
end)

Groups.TitanEnv:AddButton("Enforce Universal Sky", function()
    local LightingService = game:GetService("Lighting")
    local skyObject = nil

    local UNIVERSAL_DAYLIGHT_PROFILE = {
        ClockTime = 14,
        Brightness = 2.0,
        Ambient = Color3.fromRGB(135, 140, 150),
        OutdoorAmbient = Color3.fromRGB(135, 140, 150)
    }

    local SPRING_SKYBOX = {
        SkyboxBk = "rbxassetid://12216109205",
        SkyboxDn = "rbxassetid://12216109875",
        SkyboxFt = "rbxassetid://12216109489",
        SkyboxLf = "rbxassetid://12216110170",
        SkyboxRt = "rbxassetid://12216110471",
        SkyboxUp = "rbxassetid://12216108877"
    }

    local function isConflictingEffect(child)
        return child:IsA("Atmosphere")
            or child:IsA("BloomEffect")
            or child:IsA("ColorCorrectionEffect")
            or child:IsA("SunRaysEffect")
    end

    local function enforceSky()
        if not skyObject or not skyObject.Parent then
            skyObject = LightingService:FindFirstChildOfClass("Sky") or Instance.new("Sky", LightingService)
        end

        for prop, val in pairs(SPRING_SKYBOX) do
            if skyObject[prop] ~= val then
                skyObject[prop] = val
            end
        end

        for prop, val in pairs(UNIVERSAL_DAYLIGHT_PROFILE) do
            if LightingService[prop] ~= val then
                LightingService[prop] = val
            end
        end
    end

    local function clearEffects()
        for _, child in ipairs(LightingService:GetChildren()) do
            if isConflictingEffect(child) and not string.match(child.Name, "^MyRTX_") then
                child:Destroy()
            end
        end
    end

    clearEffects()
    enforceSky()

    if ClientState.Connections.Env["Sky1"] then
        ClientState.Connections.Env["Sky1"]:Disconnect()
    end

    if ClientState.Connections.Env["Sky2"] then
        ClientState.Connections.Env["Sky2"]:Disconnect()
    end

    local lightingSpamCount = 0
    local lastLightingSpam = tick()

    ClientState.Connections.Env["Sky1"] = LightingService.ChildAdded:Connect(function(child)
        if tick() - lastLightingSpam > 1 then
            lightingSpamCount = 0
        end

        lastLightingSpam = tick()

        if lightingSpamCount > 10 then return end

        if isConflictingEffect(child) and not string.match(child.Name, "^MyRTX_") then
            lightingSpamCount = lightingSpamCount + 1
            task.defer(function()
                pcall(function()
                    child:Destroy()
                end)
            end)
        end
    end)

    ClientState.Connections.Env["Sky2"] = RunService.RenderStepped:Connect(enforceSky)

    Library:Notify({
        Title = "System",
        Content = "Universal Sky applied!",
        Duration = 3
    })
end)

Groups.TitanVis:AddButton("Activate RTX Day Mode ☀️", function()
    ensureEffects()

    playSafeTween(Lighting, {
        ClockTime = 14,
        Brightness = 3,
        Ambient = Color3.fromRGB(170, 170, 170),
        OutdoorAmbient = Color3.fromRGB(210, 210, 210),
        FogColor = Color3.fromRGB(255, 245, 230),
        FogStart = 300,
        FogEnd = 1000,
        ExposureCompensation = 0
    })

    playSafeTween(atmosphere, {
        Color = Color3.fromRGB(199, 199, 199),
        Decay = Color3.fromRGB(106, 112, 125)
    })

    playSafeTween(sunRays, { Intensity = 0.1 })

    playSafeTween(bloom, {
        Intensity = 1.0,
        Threshold = 0.8,
        Size = 24
    })

    playSafeTween(colorCorr, {
        Saturation = 0,
        Contrast = 0,
        TintColor = Color3.fromRGB(255, 255, 255)
    })

    playSafeTween(blur, { Size = 0 })

    Library:Notify({
        Title = "Visuals",
        Content = "RTX Day Mode Applied!",
        Duration = 3
    })
end)

Groups.TitanUtil:AddInput("AnonymizerPrefix", {
    Default = "Player",
    Numeric = false,
    Finished = true,
    Text = "Custom Name Prefix",
    Placeholder = "Player"
})

Groups.TitanUtil:AddButton("Activate Anonymizer (Hide Names)", function()
    if _G.AnonymizerLoaded then
        Library:Notify({
            Title = "System",
            Content = "Anonymizer is already active!",
            Duration = 3
        })
        return
    end

    _G.AnonymizerLoaded = true

    local PlayersService = game:GetService("Players")
    local RunServiceLocal = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")

    local successTextChat, TextChatService = pcall(function()
        return game:GetService("TextChatService")
    end)

    if not successTextChat then
        TextChatService = nil
    end

    local LocalPlayer = PlayersService.LocalPlayer

    local customPrefix = "Player"
    if Library.Options.AnonymizerPrefix and Library.Options.AnonymizerPrefix.Value ~= "" then
        customPrefix = Library.Options.AnonymizerPrefix.Value
    end

    local Config = {
        AnonymousPrefix = customPrefix,
        HideLocalPlayer = true
    }

    local ACTIVE_GUARDS = setmetatable({}, { __mode = "k" })
    local REPLACEMENT_MAP = {}
    local SORTED_REPLACEMENT_ORDER = {}
    local sortedIndexMap = {}
    local ESCAPED_NAME_MAP = {}
    local playerNumberMap = {}
    local availableNumbers = {}
    local playerCounter = 0
    local playerKnownNames = {}
    local dirtyObjects = {}

    local function escapePattern(text)
        return text:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    end

    local Anonymizer = {}

    function Anonymizer.replaceText(text)
        if type(text) ~= "string" or #text == 0 then
            return text
        end

        for _, original in ipairs(SORTED_REPLACEMENT_ORDER) do
            local replacement = REPLACEMENT_MAP[original]
            if replacement then
                text = text:gsub(ESCAPED_NAME_MAP[original], replacement)
            end
        end

        return text
    end

    local NameManager = {}

    local function getNameVariants(p, displayNameReplacement, atReplacement)
        return {
            [p.Name] = displayNameReplacement,
            ["@" .. p.Name] = atReplacement,
            [p.DisplayName] = displayNameReplacement,
            ["@" .. p.DisplayName] = atReplacement
        }
    end

    function NameManager.insertSorted(name)
        ESCAPED_NAME_MAP[name] = escapePattern(name)
        local length = #name

        for i = 1, #SORTED_REPLACEMENT_ORDER + 1 do
            if i > #SORTED_REPLACEMENT_ORDER or length > #SORTED_REPLACEMENT_ORDER[i] then
                table.insert(SORTED_REPLACEMENT_ORDER, i, name)
                sortedIndexMap[name] = i

                for j = i + 1, #SORTED_REPLACEMENT_ORDER do
                    sortedIndexMap[SORTED_REPLACEMENT_ORDER[j]] = j
                end

                return
            end
        end
    end

    local function removeNameFromSortedList(name)
        local index = sortedIndexMap[name]
        if index then
            table.remove(SORTED_REPLACEMENT_ORDER, index)
            sortedIndexMap[name] = nil
            ESCAPED_NAME_MAP[name] = nil

            for j = index, #SORTED_REPLACEMENT_ORDER do
                sortedIndexMap[SORTED_REPLACEMENT_ORDER[j]] = j
            end
        end
    end

    local function removeNamesFromSystem(names)
        for _, name in ipairs(names) do
            REPLACEMENT_MAP[name] = nil
            removeNameFromSortedList(name)
        end
    end

    function NameManager.addPlayer(p)
        if not Config.HideLocalPlayer and p == LocalPlayer then return end
        if playerNumberMap[p.UserId] then return end

        local number = table.remove(availableNumbers) or (function()
            playerCounter = playerCounter + 1
            return playerCounter
        end)()

        playerNumberMap[p.UserId] = number

        local displayNameReplacement = Config.AnonymousPrefix .. number
        local atReplacement = "@" .. Config.AnonymousPrefix .. number

        local variants = getNameVariants(p, displayNameReplacement, atReplacement)

        for original, replacement in pairs(variants) do
            REPLACEMENT_MAP[original] = replacement
            NameManager.insertSorted(original)
        end

        playerKnownNames[p.UserId] = {
            Name = p.Name,
            DisplayName = p.DisplayName
        }
    end

    function NameManager.removePlayer(p)
        local number = playerNumberMap[p.UserId]
        if not number then return end

        table.insert(availableNumbers, number)

        local known = playerKnownNames[p.UserId]
        if known then
            removeNamesFromSystem({ known.Name, "@" .. known.Name, known.DisplayName, "@" .. known.DisplayName })
        end

        playerNumberMap[p.UserId] = nil
        playerKnownNames[p.UserId] = nil
    end

    function NameManager.updatePlayer(p)
        if not Config.HideLocalPlayer and p == LocalPlayer then return end
        if not playerNumberMap[p.UserId] then
            return NameManager.addPlayer(p)
        end

        local old = playerKnownNames[p.UserId]
        if old then
            removeNamesFromSystem({ old.Name, "@" .. old.Name, old.DisplayName, "@" .. old.DisplayName })
        end

        local number = playerNumberMap[p.UserId]
        local displayNameReplacement = Config.AnonymousPrefix .. number
        local atReplacement = "@" .. Config.AnonymousPrefix .. number

        local variants = getNameVariants(p, displayNameReplacement, atReplacement)

        for original, replacement in pairs(variants) do
            REPLACEMENT_MAP[original] = replacement
            NameManager.insertSorted(original)
        end

        playerKnownNames[p.UserId] = {
            Name = p.Name,
            DisplayName = p.DisplayName
        }
    end

    local UIProcessor = {}
    local UI_HANDLERS, UPDATE_LOGIC = {}, {}

    local function markAsDirty(obj)
        dirtyObjects[obj] = true
    end

    UPDATE_LOGIC.TextLabel = function(o)
        o.Text = Anonymizer.replaceText(o.Text)
    end

    UPDATE_LOGIC.TextButton = UPDATE_LOGIC.TextLabel
    UPDATE_LOGIC.TextBox = UPDATE_LOGIC.TextLabel

    UPDATE_LOGIC.ProximityPrompt = function(o)
        o.ObjectText = Anonymizer.replaceText(o.ObjectText)
        o.ActionText = Anonymizer.replaceText(o.ActionText)
    end

    local function setupDestruction(obj, key)
        key = key or obj

        obj.Destroying:Connect(function()
            local connections = ACTIVE_GUARDS[key]
            if connections then
                for _, connection in ipairs(connections) do
                    connection:Disconnect()
                end
                ACTIVE_GUARDS[key] = nil
            end
        end)
    end

    local function isWhitelisted(obj)
        return obj:GetAttribute("IgnoreAnonymizer") == true
    end

    UI_HANDLERS.TextLabel = function(obj)
        if ACTIVE_GUARDS[obj] or isWhitelisted(obj) then return end

        markAsDirty(obj)

        local textConnection = obj:GetPropertyChangedSignal("Text"):Connect(function()
            markAsDirty(obj)
        end)

        local attributeConnection = obj:GetAttributeChangedSignal("IgnoreAnonymizer"):Connect(function()
            if not isWhitelisted(obj) then
                markAsDirty(obj)
            end
        end)

        ACTIVE_GUARDS[obj] = { textConnection, attributeConnection }
        setupDestruction(obj)
    end

    UI_HANDLERS.TextButton = UI_HANDLERS.TextLabel
    UI_HANDLERS.TextBox = UI_HANDLERS.TextLabel

    UI_HANDLERS.BillboardGui = function(obj)
        if ACTIVE_GUARDS[obj] or isWhitelisted(obj) then return end

        for _, child in ipairs(obj:GetDescendants()) do
            UIProcessor.guardTextObject(child)
        end

        local descendantAdded = obj.DescendantAdded:Connect(UIProcessor.guardTextObject)
        ACTIVE_GUARDS[obj] = { descendantAdded }
        setupDestruction(obj)
    end

    UI_HANDLERS.ProximityPrompt = function(obj)
        if ACTIVE_GUARDS[obj] or isWhitelisted(obj) then return end

        markAsDirty(obj)

        local objectTextConnection = obj:GetPropertyChangedSignal("ObjectText"):Connect(function()
            markAsDirty(obj)
        end)

        local actionTextConnection = obj:GetPropertyChangedSignal("ActionText"):Connect(function()
            markAsDirty(obj)
        end)

        ACTIVE_GUARDS[obj] = { objectTextConnection, actionTextConnection }
        setupDestruction(obj)
    end

    function UIProcessor.guardTextObject(o)
        local handler = UI_HANDLERS[o.ClassName]
        if handler then
            handler(o)
        end
    end

    function UIProcessor.scanAndTrackContainer(c)
        if not c then return end

        if ACTIVE_GUARDS[c] then
            for _, connection in ipairs(ACTIVE_GUARDS[c]) do
                connection:Disconnect()
            end
        end

        for _, descendant in ipairs(c:GetDescendants()) do
            UIProcessor.guardTextObject(descendant)
        end

        local descendantAdded = c.DescendantAdded:Connect(UIProcessor.guardTextObject)
        ACTIVE_GUARDS[c] = { descendantAdded }
    end

    local DisplayNameGuardian = {}

    function DisplayNameGuardian.setupCharacter(character)
        local player = PlayersService:GetPlayerFromCharacter(character)
        if not player then return end

        if not Config.HideLocalPlayer and player == LocalPlayer then return end

        local function guardHumanoid(humanoid)
            if not humanoid or ACTIVE_GUARDS[humanoid] then return end

            local isUpdating = false

            local function update()
                if isUpdating then return end

                local number = playerNumberMap[player.UserId]
                local targetName = number and (Config.AnonymousPrefix .. number) or player.DisplayName

                if humanoid.DisplayName ~= targetName then
                    isUpdating = true
                    humanoid.DisplayName = targetName
                    isUpdating = false
                end
            end

            update()

            local humanoidDisplayNameConnection = humanoid:GetPropertyChangedSignal("DisplayName"):Connect(update)
            local playerDisplayNameConnection = player:GetPropertyChangedSignal("DisplayName"):Connect(update)

            ACTIVE_GUARDS[humanoid] = { humanoidDisplayNameConnection, playerDisplayNameConnection }
            setupDestruction(character, humanoid)
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            guardHumanoid(humanoid)
        else
            local connection
            connection = character.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                    connection:Disconnect()
                    guardHumanoid(child)
                end
            end)

            character.Destroying:Connect(function()
                if connection then
                    connection:Disconnect()
                end
            end)
        end
    end

    function DisplayNameGuardian.setupForPlayer(p)
        if p.Character then
            DisplayNameGuardian.setupCharacter(p.Character)
        end

        table.insert(ClientState.Connections.Anonymizer, p.CharacterAdded:Connect(DisplayNameGuardian.setupCharacter))

        table.insert(ClientState.Connections.Anonymizer, p:GetPropertyChangedSignal("DisplayName"):Connect(function()
            NameManager.updatePlayer(p)
        end))
    end

    local ChatHandler = {}

    function ChatHandler.setupTextChatServiceFilter()
        if not TextChatService then return end

        pcall(function()
            TextChatService.OnIncomingMessage = function(message)
                local properties = Instance.new("TextChatMessageProperties")

                pcall(function()
                    properties.Text = Anonymizer.replaceText(message.Text)
                end)

                return properties
            end
        end)
    end

    function ChatHandler.setupSystemMessageFilter()
        if not TextChatService then return end

        local function setupChannel(channel)
            if channel.Name == "RBXSystem" then
                channel.OnIncomingMessage = function(message)
                    local properties = Instance.new("TextChatMessageProperties")

                    pcall(function()
                        properties.Text = Anonymizer.replaceText(message.Text)
                    end)

                    return properties
                end
            end
        end

        for _, channel in ipairs(TextChatService:GetChildren()) do
            if channel:IsA("TextChannel") then
                pcall(setupChannel, channel)
            end
        end

        TextChatService.ChildAdded:Connect(function(channel)
            if channel:IsA("TextChannel") then
                pcall(setupChannel, channel)
            end
        end)
    end

    function ChatHandler.setupLegacyChatScanner()
        if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then return end

        pcall(function()
            local chat = CoreGui:WaitForChild("Chat", 10)
            if chat then
                local messageLog = chat:FindFirstChild("Frame.ChatChannelParentFrame.Frame_MessageLogDisplay", true)
                if messageLog then
                    UIProcessor.scanAndTrackContainer(messageLog)
                end
            end
        end)
    end

    local function onPlayerAdded(p)
        NameManager.addPlayer(p)
        DisplayNameGuardian.setupForPlayer(p)
    end

    local function onPlayerRemoving(p)
        NameManager.removePlayer(p)
    end

    ChatHandler.setupTextChatServiceFilter()
    ChatHandler.setupSystemMessageFilter()
    task.spawn(ChatHandler.setupLegacyChatScanner)

    for _, p in ipairs(PlayersService:GetPlayers()) do
        task.spawn(onPlayerAdded, p)
    end

    table.insert(ClientState.Connections.Anonymizer, PlayersService.PlayerAdded:Connect(onPlayerAdded))
    table.insert(ClientState.Connections.Anonymizer, PlayersService.PlayerRemoving:Connect(onPlayerRemoving))

    local function startTargetedScanning()
        task.spawn(function()
            if LocalPlayer then
                local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
                if playerGui then
                    pcall(UIProcessor.scanAndTrackContainer, playerGui)
                end
            end

            pcall(UIProcessor.scanAndTrackContainer, CoreGui)
        end)

        local function watchCharacter(character)
            for _, descendant in ipairs(character:GetDescendants()) do
                UIProcessor.guardTextObject(descendant)
            end

            local descendantAdded = character.DescendantAdded:Connect(UIProcessor.guardTextObject)
            ACTIVE_GUARDS[character] = { descendantAdded }
            setupDestruction(character)
        end

        for _, p in ipairs(PlayersService:GetPlayers()) do
            if p.Character then
                watchCharacter(p.Character)
            end

            table.insert(ClientState.Connections.Anonymizer, p.CharacterAdded:Connect(watchCharacter))
        end

        table.insert(ClientState.Connections.Anonymizer, PlayersService.PlayerAdded:Connect(function(p)
            table.insert(ClientState.Connections.Anonymizer, p.CharacterAdded:Connect(watchCharacter))

            if p.Character then
                watchCharacter(p.Character)
            end
        end))
    end

    startTargetedScanning()

    table.insert(ClientState.Connections.Anonymizer, RunServiceLocal.RenderStepped:Connect(function()
        if next(dirtyObjects) == nil then return end

        for obj in pairs(dirtyObjects) do
            local okClass, className = pcall(function()
                return obj.ClassName
            end)

            if okClass and className then
                local updater = UPDATE_LOGIC[className]

                if updater then
                    local okParent, parent = pcall(function()
                        return obj.Parent
                    end)

                    if okParent and parent then
                        pcall(updater, obj)
                    end
                end
            end
        end

        table.clear(dirtyObjects)
    end))

    Library:Notify({
        Title = "System",
        Content = "Anonymizer activated successfully!",
        Duration = 3
    })
end)

local function resetAllUI()
    local function setToggle(name, value)
        local toggle = Library.Toggles[name]
        if toggle then
            toggle:SetValue(value)
        end
    end

    local function setOption(name, value)
        local option = Library.Options[name]
        if option then
            option:SetValue(value)
        end
    end

    for name in pairs(allActions) do
        setToggle(name, false)
    end

    setToggle("NameTagEnabled", false)

    setOption("ShirtSelector", "None")
    setOption("PantsSelector", "None")
    setOption("TShirtSelector", "None")
    setOption("AnimationPackSelector", "None")

    for _, override in pairs(CONFIG.AnimationOverrides) do
        setToggle(override.key, false)
    end

    setOption("EmoteSelector", "None")
    stopEmote()

    setToggle("RainbowMode", false)
    resetColors()
end

Groups.Tools:AddButton("Reset All", function()
    resetAllUI()
    fullReset(Player.Character)
end)

Groups.Tools:AddButton("Unload Script", function()
    if ClientState.Connections.Rainbow then
        ClientState.Connections.Rainbow:Disconnect()
    end

    for _, connection in pairs(ClientState.Connections.Env or {}) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    for _, connection in ipairs(ClientState.Connections.Anonymizer or {}) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    local rainPart = game:GetService("Workspace"):FindFirstChild("MyExecutorRainPart")
    if rainPart then
        rainPart:Destroy()
    end

    pcall(function()
        game:GetService("RunService"):UnbindFromRenderStep("ExecutorRainLoop")
    end)

    local MaterialService = game:GetService("MaterialService")

    for _, child in ipairs(MaterialService:GetChildren()) do
        if child:IsA("MaterialVariant") and string.sub(child.Name, 1, 4) == "abs_" then
            pcall(function()
                MaterialService:SetBaseMaterialOverride(child.BaseMaterial, "")
            end)

            task.defer(function()
                child:Destroy()
            end)
        end
    end

    _G.AnonymizerLoaded = false

    resetAllUI()
    fullReset(Player.Character)

    if ClientState.Connections.CharacterAdded then
        ClientState.Connections.CharacterAdded:Disconnect()
    end

    getgenv().WhiteRoseLoaded = nil
    Library:Unload()
end)

ClientState.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(c)
    task.spawn(function()
        c:WaitForChild("Humanoid", 3)
        c:WaitForChild("Head", 5)

        local startTime = tick()

        while tick() - startTime < 2 do
            local ok, loaded = pcall(function()
                return Player:HasAppearanceLoaded()
            end)

            if ok and loaded then
                break
            end

            task.wait(0.1)
        end

        if not c.Parent then return end

        stopEmote()

        ClientState.Scripted = {
            Shirt = nil,
            Pants = nil,
            TShirt = nil,
            HeadlessMesh = nil,
            SkyObject = nil,
            CurrentEmote = nil
        }

        ClientState.Originals.LimbColors = {}
        ClientState.Originals.Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }
        ClientState.Originals.LimbData = {}
        ClientState.Originals.FaceTexture = nil
        ClientState.Originals.FaceTransparency = nil
        ClientState.Originals.Sound = { Id = nil, Pitch = nil }
        ClientState.Originals.Headless = nil

        ClientState.Cache.OriginalAnimations = {}
        ClientState.Cache.AccessorySignature = nil
        ClientState.Cache.AccessoryCharacter = nil
        ClientState.Cache.AppliedActions = {}

        captureColors(c, true)

        local ok, err = pcall(function()
            syncCharacter(c)
        end)

        if not ok then
            warn("WhiteRose Sync Error: " .. tostring(err))
        end

        if ClientState.Connections.Env["AppearanceEnforcer"] then
            ClientState.Connections.Env["AppearanceEnforcer"]:Disconnect()
        end

        ClientState.Connections.Env["AppearanceEnforcer"] = c.DescendantAdded:Connect(function(child)
            if not child.Parent or child:GetAttribute("WhiteRoseRefreshing") then return end

            if child:IsA("Tool") or child:FindFirstAncestorWhichIsA("Tool") or child:FindFirstAncestorWhichIsA("Backpack") then
                return
            end

            if child.Name == "WhiteRose_ScriptedItem" or isScriptedAccessory(child) then
                return
            end

            local parent = child.Parent

            while parent and parent ~= game do
                if parent.Name == "WhiteRose_ScriptedItem" or isScriptedAccessory(parent) or parent:GetAttribute("WhiteRoseDestroying") then
                    return
                end
                parent = parent.Parent
            end

            task.wait()

            if not child.Parent then return end

            if child:IsA("Clothing") or child:IsA("ShirtGraphic") or child:IsA("Accessory") or child:IsA("BodyColors") or child:IsA("Decal") or child:IsA("SpecialMesh") then
                requestSync(c)
            end
        end)

        if ClientState.Connections.Env["AppearanceEnforcer2"] then
            ClientState.Connections.Env["AppearanceEnforcer2"]:Disconnect()
        end

        ClientState.Connections.Env["AppearanceEnforcer2"] = c.DescendantRemoving:Connect(function(child)
            if child:GetAttribute("WhiteRoseDestroying") or child:GetAttribute("WhiteRoseRefreshing") then return end
            if child.Name == "WhiteRose_ScriptedItem" or isScriptedAccessory(child) then return end
        end)
    end)
end)

if Player.Character then
    captureColors(Player.Character, true)
end

if ThemeManager and SaveManager then
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "ToggleUIKeybind" })

    ThemeManager:SetFolder("WhiteRose_Settings")
    SaveManager:SetFolder("WhiteRose_Settings")

    ThemeManager:ApplyToTab(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)

    local oldLoad = SaveManager.Load

    if oldLoad then
        function SaveManager:Load(...)
            resetAllUI()
            fullReset(Player.Character)

            local loadSuccess, loadError = oldLoad(self, ...)

            if loadSuccess then
                task.wait(0.2)
                syncCharacter(Player.Character)
            end

            return loadSuccess, loadError
        end
    end

    SaveManager:LoadAutoloadConfig()
end
