--[[ 
    WhiteRose V7.6 - Razor Precision Crosshair & Master Suite
    (Optimized Outward Crosshair + Classic Fog + Smart Headless + 30 MC Textures + Custom Loader)
]]
if getgenv().WhiteRoseLoaded then return end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local function fetch(p) local ok, m = pcall(function() return loadstring(game:HttpGet(repo .. p))() end) return ok and m or nil end
local Library = fetch("Library.lua")
if not Library then return warn("WhiteRose: Library failed to load.") end
local ThemeManager, SaveManager = fetch("addons/ThemeManager.lua"), fetch("addons/SaveManager.lua")

getgenv().WhiteRoseLoaded = true
local Player, Toggles, Options = Players.LocalPlayer, Library.Toggles, Library.Options

local Window = Library:CreateWindow({ Name = "WhiteRose", Title = "WhiteRose", SubTitle = "Crosshair & Visuals Suite", Draggable = true, Footer = "WhiteRose & Precision Crosshair | v7.6", Center = true, AutoShow = true, Resizable = true, EnableSidebarResize = true })

-- // Configuration Data \ --
local CFG = {
    IDs = { HeadlessMesh = "http://www.roblox.com/asset/?id=134079402", FaceTexture = "http://www.roblox.com/asset/?id=42070872", KorbloxLeg = "rbxassetid://902942093", KorbloxUpper = "rbxassetid://902942096", KorbloxTex = "rbxassetid://902843398", KorbloxFoot = "rbxassetid://902942089" },
    Limbs = { Head = {"Head"}, Torso = {"UpperTorso","LowerTorso","Torso"}, LeftArm = {"LeftUpperArm","LeftLowerArm","LeftHand","Left Arm"}, RightArm = {"RightUpperArm","RightLowerArm","RightHand","Right Arm"}, LeftLeg = {"LeftUpperLeg","LeftLowerLeg","LeftFoot","Left Leg"}, RightLeg = {"RightUpperLeg","RightLowerLeg","RightFoot","Right Leg"} },
    Clothes = {
        Shirt = { ["None"] = false, ["Remove"] = false, ["Yuno Gasai Mirai Nikki"] = 6412908981, ["Sanji (+)"] = "http://www.roblox.com/asset/?id=18529496130" },
        Pants = { ["None"] = false, ["Remove"] = false, ["Yuno Gasai Mirai Nikki"] = 6412913951, ["Yuno Gasai Anime Black Dress V2"] = 14696725708, ["Sanji (-)"] = "http://www.roblox.com/asset/?id=18529553305" },
        TShirt = { ["None"] = false, ["Remove"] = false, ["Oh Noez!"] = "http://www.roblox.com/asset/?id=1641286", ["Spread The Lulz!"] = "http://www.roblox.com/asset/?id=24774765" }
    },
    Anims = {
        ["None"] = {},
        ["Vampire"] = { idle = {"rbxassetid://1083445855","rbxassetid://1083450166"}, walk = "rbxassetid://1083473930", run = "rbxassetid://1083462077", jump = "rbxassetid://1083455352", fall = "rbxassetid://1083443587", climb = "rbxassetid://1083439238", swim = "rbxassetid://1083222527", swimidle = "rbxassetid://1083225406" }
    },
    Ovr = { ["Robot Swim"] = { k = "RobotSwim", v = { swim = "rbxassetid://10921253142", swimidle = "rbxassetid://10921253767" } }, ["Mage Fall"] = { k = "MageFall", v = { fall = "rbxassetid://10921148939" } }, ["Elder Jump"] = { k = "ElderJump", v = { jump = "rbxassetid://10921107367" } }, ["Toy Run"] = { k = "ToyRun", v = { run = "rbxassetid://10921306285" } } },
    Emotes = { ["None"] = false, ["Dance 1"] = "rbxassetid://507771019", ["Dance 2"] = "rbxassetid://507771955", ["Dance 3"] = "rbxassetid://507772104", ["Wave / Hello"] = "rbxassetid://507770239", ["Point"] = "rbxassetid://507770453", ["Cheer"] = "rbxassetid://507770677", ["Laugh"] = "rbxassetid://507770818" }
}

-- 30 Full Minecraft Materials
local MC_MATERIALS = {
    [Enum.Material.Asphalt] = { "11545435992" }, [Enum.Material.Basalt] = { "11545440462", "9730055481" }, [Enum.Material.Brick] = { "11545453130" },
    [Enum.Material.Cobblestone] = { "11545460611" }, [Enum.Material.Concrete] = { "11545468983" }, [Enum.Material.CorrodedMetal] = { "11545476330" },
    [Enum.Material.CrackedLava] = { "11545484781" }, [Enum.Material.DiamondPlate] = { "11545495407" }, [Enum.Material.Fabric] = { "118776397" },
    [Enum.Material.Foil] = { "11545501473" }, [Enum.Material.Glacier] = { "11545521725" }, [Enum.Material.Granite] = { "11545524005" },
    [Enum.Material.Grass] = { "11545527424" }, [Enum.Material.Ground] = { "11545533676" }, [Enum.Material.Ice] = { "11546405701" },
    [Enum.Material.LeafyGrass] = { "11546412010" }, [Enum.Material.Limestone] = { "11546415687" }, [Enum.Material.Marble] = { "11546425898" },
    [Enum.Material.Metal] = { "11546431794" }, [Enum.Material.Mud] = { "11546437412" }, [Enum.Material.Pavement] = { "11546440685" },
    [Enum.Material.Pebble] = { "11546453485" }, [Enum.Material.Rock] = { "11546456858" }, [Enum.Material.Salt] = { "11546461451" },
    [Enum.Material.Sand] = { "11546468464" }, [Enum.Material.Sandstone] = { "11546471860" }, [Enum.Material.Slate] = { "11546474778" },
    [Enum.Material.Snow] = { "11108916253" }, [Enum.Material.Wood] = { "11546477504" }, [Enum.Material.WoodPlanks] = { "11546480686" }
}

-- // State & Memory Management \ --
local allActions = {}
local State = {
    Orig = { LimbColors = {}, Sound = {}, Lighting = {}, Clothing = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }, LimbData = {} },
    Scripted = { Shirt = nil, Pants = nil, TShirt = nil, ScarySmile = nil, CurrentEmote = nil, CustomAccs = {}, SkyObject = nil },
    Conn = { Env = {} }, Cache = { OrigAnims = {}, ClothTmpl = {}, AccTmpl = {}, Sig = nil, Char = nil, Applied = {} },
    CharGen = 0
}

local function getKeys(t) local k = {} for i in pairs(t) do table.insert(k, i) end table.sort(k) return k end
local function getOpt(n, d) return (Options[n] and Options[n].Value ~= nil) and Options[n].Value or d end
local function getTog(n) return Toggles[n] and Toggles[n].Value or false end

local function safeDestroy(o)
    if o and typeof(o) == "Instance" then
        pcall(function()
            o:SetAttribute("WR_D", true)
            for _, d in ipairs(o:GetDescendants()) do d:SetAttribute("WR_D", true) end
            o:Destroy()
        end)
    end
end

local function cleanTableInstances(tbl)
    if not tbl then return end
    for k, v in pairs(tbl) do
        if typeof(v) == "Instance" then safeDestroy(v)
        elseif type(v) == "table" then cleanTableInstances(v) end
    end
end

local function isR6(c) local h = c and c:FindFirstChildOfClass("Humanoid") return (h and h.RigType == Enum.HumanoidRigType.R6) or (c and c:FindFirstChild("Torso") and not c:FindFirstChild("UpperTorso")) end

local function isScriptedItem(inst)
    local cur = inst
    while cur and cur ~= game do
        if (cur:IsA("Accessory") and cur:GetAttribute("WR_Acc")) or cur:GetAttribute("WR_Hair") or cur.Name == "WR_Item" or cur:GetAttribute("WR_Custom") then return true end
        cur = cur.Parent
    end
    return false
end

-- // Leak-Free Tween Manager \ --
local activeTweens = setmetatable({}, { __mode = "k" })
local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function playSafeTween(inst, props)
    if not inst then return end
    local oldTw = activeTweens[inst]
    if oldTw then pcall(function() oldTw:Cancel() oldTw:Destroy() end) activeTweens[inst] = nil end
    local tw = TweenService:Create(inst, tweenInfo, props)
    activeTweens[inst] = tw
    tw.Completed:Connect(function()
        if activeTweens[inst] == tw then
            pcall(function() tw:Destroy() end)
            activeTweens[inst] = nil
        end
    end)
    tw:Play()
end

local function getEffect(cls, name)
    local e = Lighting:FindFirstChild(name)
    if not e then e = Instance.new(cls, Lighting) e.Name = name end
    return e
end

-- // Smart Accessory Manager \ --
local AM = { Conn = {} }
local ATT_CF = { HairAttachment = CFrame.new(0, 0.6, 0), HatAttachment = CFrame.new(0, 0.6, 0), FaceFrontAttachment = CFrame.new(0, 0, -0.6)*CFrame.Angles(0, 1.57, 0), FaceCenterAttachment = CFrame.new(0, 0, -0.6)*CFrame.Angles(0, 1.57, 0), NeckAttachment = CFrame.new(0, 1, 0), LeftShoulderAttachment = CFrame.new(-1, 0.8, 0), RightShoulderAttachment = CFrame.new(1, 0.8, 0), WaistAttachment = CFrame.new(0, -0.8, 0) }

local function makeCosmetic(r) for _, d in ipairs(r:GetDescendants()) do if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery, d.Massless = false, false, false, false, true end end end

local function computeAutoHairOffset(head, parts, baseCFrame)
    local inv = baseCFrame:Inverse()
    local min, max = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, part in ipairs(parts) do
        local rel, half = inv * part.CFrame, part.Size / 2
        for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
            local corner = rel:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
            min = Vector3.new(math.min(min.X, corner.X), math.min(min.Y, corner.Y), math.min(min.Z, corner.Z))
            max = Vector3.new(math.max(max.X, corner.X), math.max(max.Y, corner.Y), math.max(max.Z, corner.Z))
        end end end
    end
    return CFrame.new(-(min.X + max.X) / 2, (head.Size.Y / 2 + 0.1) - max.Y, -(min.Z + max.Z) / 2)
end

function AM:Bind(tp, c)
    if not tp or not c then return end
    local function sync()
        if not tp.Parent or not c.Parent then return end
        local char = tp.Parent:IsA("Model") and tp.Parent or (tp.Parent.Parent:IsA("Model") and tp.Parent.Parent or Player.Character)
        local trans, ltm = tp.Transparency, tp.LocalTransparencyModifier

        if getTog("Headless") and tp.Name == "Head" and char then
            local bodyPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
            if bodyPart and bodyPart.Transparency < 0.95 then
                trans = bodyPart.Transparency
                ltm = bodyPart.LocalTransparencyModifier
            end
        end

        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then d.Transparency, d.LocalTransparencyModifier = trans, ltm
            elseif d:IsA("Decal") or d:IsA("Texture") then d.Transparency = trans end
        end
        if c:IsA("BasePart") then c.Transparency, c.LocalTransparencyModifier = trans, ltm end
    end

    table.insert(self.Conn, tp:GetPropertyChangedSignal("Transparency"):Connect(sync))
    table.insert(self.Conn, tp:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(sync))

    if tp.Name == "Head" and tp.Parent then
        local char = tp.Parent
        local bodyPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if bodyPart then
            table.insert(self.Conn, bodyPart:GetPropertyChangedSignal("Transparency"):Connect(sync))
            table.insert(self.Conn, bodyPart:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(sync))
        end
    end

    sync()
end

local function weldAcc(char, acc)
    local h = acc:FindFirstChild("Handle") if not h or not h:IsA("BasePart") then return false end
    makeCosmetic(acc)
    local hAtt = h:FindFirstChildWhichIsA("Attachment") or Instance.new("Attachment", h)
    local cAtt
    for _, d in ipairs(char:GetDescendants()) do if d:IsA("Attachment") and d.Name == hAtt.Name and d.Parent:IsA("BasePart") then cAtt = d break end end
    if not cAtt then
        local head = char:FindFirstChild("Head") if not head then return false end
        cAtt = head:FindFirstChild(hAtt.Name .. "_WRF") or Instance.new("Attachment", head)
        cAtt.Name, cAtt.CFrame = hAtt.Name .. "_WRF", ATT_CF[hAtt.Name] or CFrame.new(0, 0.6, 0)
    end
    local tp = cAtt.Parent
    acc.Parent, h.CFrame = char, tp.CFrame * cAtt.CFrame * hAtt.CFrame:Inverse()
    local w = Instance.new("Weld", tp) w.Name, w.Part0, w.Part1, w.C0, w.C1 = "WRA_Weld", tp, h, cAtt.CFrame, hAtt.CFrame
    local wr = Instance.new("ObjectValue", acc) wr.Name, wr.Value = "WRA_Weld", w
    AM:Bind(tp, acc)
    return true
end

local function attachHair(char, root)
    local head = char:FindFirstChild("Head") if not head then return false end
    local parts = root:IsA("BasePart") and { root } or {}
    if #parts == 0 then for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end end
    if #parts == 0 then return false end
    local base, bCF = parts[1], parts[1].CFrame
    local attP, att
    for _, p in ipairs(parts) do local a = p:FindFirstChildWhichIsA("Attachment") if a then attP, att = p, a break end end
    local c0 = att and ((head:FindFirstChild(att.Name) or Instance.new("Attachment", head)).CFrame * att.CFrame:Inverse() * (bCF:Inverse() * attP.CFrame):Inverse()) or computeAutoHairOffset(head, parts, bCF)
    local hldr = Instance.new("Folder", char) hldr.Name = "WR_Hair" hldr:SetAttribute("WR_Hair", true)
    for _, p in ipairs(parts) do
        local rel = bCF:Inverse() * p.CFrame
        p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless, p.Parent = false, false, false, false, true, hldr
        local w = Instance.new("Weld", p) w.Name, w.Part0, w.Part1, w.C0, w.C1 = "WRH_Weld", head, p, c0, rel:Inverse()
    end
    AM:Bind(head, hldr)
    if root ~= base then pcall(function() root:Destroy() end) end
    return true
end

function AM:Clear(char)
    for _, c in ipairs(self.Conn) do pcall(function() c:Disconnect() end) end
    self.Conn = {}
    if not char then return end
    for _, c in ipairs(char:GetChildren()) do
        if (c:IsA("Accessory") and c:GetAttribute("WR_Acc")) or c:GetAttribute("WR_Hair") then
            local w = c:FindFirstChild("WRA_Weld") if w and w:IsA("ObjectValue") then safeDestroy(w.Value) end
            safeDestroy(c)
        end
    end
    for _, obj in ipairs(State.Scripted.CustomAccs) do safeDestroy(obj) end
    State.Scripted.CustomAccs = {}
end

function AM:Sync(char, groups)
    local ids = {} for _, g in pairs(groups) do for _, id in ipairs(g) do table.insert(ids, tostring(id)) end end table.sort(ids)
    local sig = table.concat(ids, ",")
    if State.Cache.Char == char and State.Cache.Sig == sig then return end
    State.Cache.Char, State.Cache.Sig = char, sig
    self:Clear(char)
    for _, id in ipairs(ids) do
        task.spawn(function()
            for _ = 1, 10 do
                if not char or not char.Parent or State.Cache.Sig ~= sig then return end
                local t = State.Cache.AccTmpl[id] or (function() local ok, o = pcall(game.GetObjects, game, "rbxassetid://" .. id) local a = ok and o and o[1] if a then State.Cache.AccTmpl[id] = a end return a end)()
                if t then
                    local cl = t:Clone() local acc = cl:IsA("Accessory") and cl or cl:FindFirstChildWhichIsA("Accessory", true)
                    if acc then acc:SetAttribute("WR_Acc", true) if weldAcc(char, acc) then break end elseif attachHair(char, cl) then break end
                    safeDestroy(cl)
                end
                task.wait(0.5)
            end
        end)
    end
end

-- // Appearance & Color Managers \ --
local function applyColor(c, g, col)
    if not c then return end local bc = c:FindFirstChildWhichIsA("BodyColors")
    if bc then pcall(function() bc[g .. "Color3"] = col end)
    elseif CFG.Limbs[g] then for _, n in ipairs(CFG.Limbs[g]) do local p = c:FindFirstChild(n) if p and p:IsA("BasePart") then p.Color = col break end end end
end

local function captureColors(c, f)
    if not c or (not f and next(State.Orig.LimbColors)) then return end State.Orig.LimbColors = {}
    local bc = c:FindFirstChildWhichIsA("BodyColors")
    for g, names in pairs(CFG.Limbs) do
        local col if bc then pcall(function() col = bc[g .. "Color3"] end) end
        if not col then for _, n in ipairs(names) do local p = c:FindFirstChild(n) if p and p:IsA("BasePart") then col = p.Color break end end end
        State.Orig.LimbColors[g] = col or Color3.fromRGB(245, 205, 172)
    end
end

local function applyFace(c)
    if not c then return end local head = c:FindFirstChild("Head") local face = head and (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")) if not face then return end
    if State.Orig.FaceTrans == nil then State.Orig.FaceTrans = face.Transparency end
    if State.Orig.FaceTex == nil then State.Orig.FaceTex = face.Texture end
    face.Transparency = (getTog("Headless") or getTog("Scary Smile Outfit")) and 1 or (State.Orig.FaceTrans or 0)
    face.Texture = getTog("Epic Face") and CFG.IDs.FaceTexture or (State.Orig.FaceTex or "")
end

local CM = { Hidden = {}, Types = { Shirt = { c = "Shirt", p = "ShirtTemplate" }, Pants = { c = "Pants", p = "PantsTemplate" }, TShirt = { c = "ShirtGraphic", p = "Graphic" } } }
local function restoreClothing(char, typeStr)
    local orig = State.Orig.Clothing
    if typeStr == "TShirt" then for _, it in ipairs(orig.TShirts) do pcall(function() it.Parent = char end) end orig.TShirts = {}
    elseif orig[typeStr] then pcall(function() orig[typeStr].Parent = char end) orig[typeStr] = nil end
end
local function storeClothing(char, typeStr, cls)
    local orig = State.Orig.Clothing
    if typeStr == "TShirt" then
        if #orig.TShirts > 0 then return end
        for _, it in ipairs(char:GetChildren()) do if it:IsA(cls) and it ~= State.Scripted.TShirt and it.Name ~= "WR_Item" and pcall(function() it.Parent = nil end) then table.insert(orig.TShirts, it) end end
    elseif not orig[typeStr] then
        local it = char:FindFirstChildOfClass(cls) if it and it.Name ~= "WR_Item" and pcall(function() it.Parent = nil end) then orig[typeStr] = it end
    end
end

function CM:Apply(c, t, name)
    if not c or self.Hidden[t] then return end local def, id = self.Types[t], CFG.Clothes[t][name]
    if name == "Remove" then safeDestroy(State.Scripted[t]) State.Scripted[t] = nil storeClothing(c, t, def.c) return end
    local tmpl = id
    if type(id) == "number" then
        local k = def.c .. ":" .. id tmpl = State.Cache.ClothTmpl[k] or (function() local ok, o = pcall(game.GetObjects, game, "rbxassetid://" .. id) local it = ok and o and (o[1]:IsA(def.c) and o[1] or o[1]:FindFirstChildWhichIsA(def.c, true)) local val = it and it[def.p] if val then State.Cache.ClothTmpl[k] = val end return val end)()
    end
    safeDestroy(State.Scripted[t]) State.Scripted[t] = nil
    if not tmpl then restoreClothing(c, t) return end
    storeClothing(c, t, def.c)
    local item = Instance.new(def.c) item.Name, item[def.p], item.Parent = "WR_Item", tmpl, c State.Scripted[t] = item
end
function CM:Hide(c, t) if not c or self.Hidden[t] then return end safeDestroy(State.Scripted[t]) State.Scripted[t] = nil storeClothing(c, t, self.Types[t].c) self.Hidden[t] = true end
function CM:Show(c, t) if not self.Hidden[t] then return end self.Hidden[t] = nil restoreClothing(c, t) self:Apply(c, t, getOpt(t .. "Selector", "None")) end
function CM:Restore(c) if not c then return end for t in pairs(self.Types) do safeDestroy(State.Scripted[t]) State.Scripted[t] = nil restoreClothing(c, t) self.Hidden[t] = nil end end

-- // Animation Core \ --
local function applyAnim(c, pack)
    pack = pack or "None"
    task.spawn(function()
        if not c then return end local anim = c:WaitForChild("Animate", 5) if not anim then return end
        local is_r6 = isR6(c)
        if is_r6 and pack ~= "None" then pack = "None" if not State.Cache.R6Warn then State.Cache.R6Warn = true Library:Notify({ Title = "Anims", Content = "R6 rig detected - custom packs disabled.", Duration = 4 }) end end
        if not next(State.Cache.OrigAnims) then
            local function g(n, cn) local node = anim:FindFirstChild(n) local t = node and node:FindFirstChild(cn) return t and t.AnimationId or nil end
            local o = { idle = {g("idle","Animation1"), g("idle","Animation2")}, walk = g("walk","WalkAnim"), run = g("run","RunAnim"), jump = g("jump","JumpAnim"), fall = g("fall","FallAnim"), climb = g("climb","ClimbAnim"), swim = g("swim","Swim"), swimidle = g("swimidle","SwimIdle") }
            State.Cache.OrigAnims, CFG.Anims["None"] = o, o
        end
        local p = {} for k, v in pairs(CFG.Anims[pack] or {}) do p[k] = v end
        if not is_r6 then for _, ov in pairs(CFG.Ovr) do if getTog(ov.k) then for k, v in pairs(ov.v) do p[k] = v end end end end
        task.wait(0.1)
        local orig = State.Cache.OrigAnims
        local function s(n, cn, v) local node = anim:FindFirstChild(n) local t = node and node:FindFirstChild(cn) if t and v then t.AnimationId = v end end
        s("idle","Animation1",(p.idle and p.idle[1]) or (orig.idle and orig.idle[1])) s("idle","Animation2",(p.idle and p.idle[2]) or (orig.idle and orig.idle[2]))
        s("walk","WalkAnim",p.walk or orig.walk) s("run","RunAnim",p.run or orig.run) s("jump","JumpAnim",p.jump or orig.jump) s("fall","FallAnim",p.fall or orig.fall)
        s("climb","ClimbAnim",p.climb or orig.climb) s("swim","Swim",p.swim or orig.swim) s("swimidle","SwimIdle",p.swimidle or orig.swimidle)
    end)
end

local function stopEmote()
    if State.Scripted.CurrentEmote then
        pcall(function() State.Scripted.CurrentEmote:Stop() State.Scripted.CurrentEmote:Destroy() end)
        State.Scripted.CurrentEmote = nil
    end
    if State.Conn.EmoteStop then State.Conn.EmoteStop:Disconnect() State.Conn.EmoteStop = nil end
end

local function playEmote(c, name)
    stopEmote() local hum, id = c and c:FindFirstChildOfClass("Humanoid"), CFG.Emotes[name] if not hum or not id then return end
    task.spawn(function()
        local a = Instance.new("Animation") a.AnimationId = id
        local l = hum:LoadAnimation(a) a:Destroy() State.Scripted.CurrentEmote = l l:Play()
        State.Conn.EmoteStop = hum.Running:Connect(function(s) if s > 0.5 then stopEmote() end end)
    end)
end

local function syncChar(c)
    if not c then return end local active = { Auto = {} }
    for _, t in ipairs({"Shirt", "Pants", "TShirt"}) do CM:Apply(c, t, getOpt(t .. "Selector", "None")) end
    for name, act in pairs(allActions) do
        if getTog(name) then
            if act.type == "Accessory" then for _, ids in pairs(act.action) do for _, id in ipairs(ids) do table.insert(active.Auto, id) end end
            elseif not State.Cache.Applied[name] then pcall(act.action, c, true) State.Cache.Applied[name] = true end
        end
    end
    AM:Sync(c, active)
    for g in pairs(CFG.Limbs) do if Options[g .. "Color"] then applyColor(c, g, Options[g .. "Color"].Value) end end
    applyAnim(c, getOpt("AnimationPackSelector", "None"))
end

local function fullReset(c)
    stopEmote()
    State.Cache.Sig, State.Cache.Char, State.Cache.Applied = nil, nil, {}
    safeDestroy(State.Scripted.HeadlessMesh)
    safeDestroy(State.Scripted.SkyObject) State.Scripted.SkyObject = nil
    
    if c then
        CM:Restore(c)
        for _, a in ipairs(State.Orig.Clothing.Accessories) do if a then pcall(function() a.Parent = c end) end end
        for _, h in ipairs(State.Orig.Clothing.Hair) do if h then pcall(function() h.Parent = c end) end end
        AM:Clear(c)
        local h = c:FindFirstChild("Head")
        if h and State.Orig.Headless then h.Transparency = State.Orig.Headless.t or 0 local sm = h:FindFirstChildOfClass("SpecialMesh") if sm and State.Orig.Headless.s then sm.Scale = State.Orig.Headless.s end end
        applyFace(c)
    else
        cleanTableInstances(State.Orig.Clothing)
    end

    State.Orig.Clothing, State.Orig.LimbData = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }, {}
    applyAnim(c, "None")
end

-- // Action Handlers \ --
allActions = {
    ["Headless"] = { category = "Body", type = "Function", action = function(c, e)
        local h = c and c:FindFirstChild("Head") if not h then return end
        if not State.Orig.Headless then local sm = h:FindFirstChildOfClass("SpecialMesh") State.Orig.Headless = { t = h.Transparency, s = sm and sm.Scale } end
        h.Transparency = e and 1 or (State.Orig.Headless.t or 0)
        local sm = h:FindFirstChildOfClass("SpecialMesh")
        if sm then sm.Scale = e and Vector3.zero or (State.Orig.Headless.s or Vector3.one) end
        applyFace(c)
        for _, child in ipairs(c:GetChildren()) do
            if child:IsA("Accessory") or child:GetAttribute("WR_Hair") then
                local b = child:FindFirstChildWhichIsA("BasePart") or child:FindFirstChild("Handle")
                if b then b.Transparency = 0 b.LocalTransparencyModifier = 0 end
            end
        end
    end },
    ["Korblox"] = { category = "Body", type = "Function", action = function(c, e)
        if not (c and c:FindFirstChild("RightLowerLeg")) then return end
        if e then
            if not State.Orig.LimbData["Korblox"] then State.Orig.LimbData["Korblox"] = { lm = c.RightLowerLeg.MeshId, lt = c.RightLowerLeg.Transparency, um = c.RightUpperLeg.MeshId, ut = c.RightUpperLeg.TextureID, fm = c.RightFoot.MeshId, ft = c.RightFoot.Transparency } end
            c.RightLowerLeg.MeshId, c.RightLowerLeg.Transparency, c.RightUpperLeg.MeshId, c.RightUpperLeg.TextureID, c.RightFoot.MeshId, c.RightFoot.Transparency = CFG.IDs.KorbloxLeg, 1, CFG.IDs.KorbloxUpper, CFG.IDs.KorbloxTex, CFG.IDs.KorbloxFoot, 1
        else
            local o = State.Orig.LimbData["Korblox"] if o then c.RightLowerLeg.MeshId, c.RightLowerLeg.Transparency, c.RightUpperLeg.MeshId, c.RightUpperLeg.TextureID, c.RightFoot.MeshId, c.RightFoot.Transparency = o.lm, o.lt, o.um, o.ut, o.fm, o.ft end
        end
    end },
    ["Naked"] = { category = "Body", type = "Function", action = function(c, e) for _, t in ipairs({"Shirt", "Pants", "TShirt"}) do if e then CM:Hide(c, t) else CM:Show(c, t) end end end },
    ["Remove Hair"] = { category = "Body", type = "Function", action = function(c, e)
        if not c then return end
        if e then for _, h in ipairs(c:GetChildren()) do if h:IsA("Accessory") and pcall(function() return h.AccessoryType end) and h.AccessoryType == Enum.AccessoryType.Hair then table.insert(State.Orig.Clothing.Hair, h) h.Parent = nil end end
        else for _, h in ipairs(State.Orig.Clothing.Hair) do h.Parent = c end State.Orig.Clothing.Hair = {} end
    end },
    ["Epic Face"] = { category = "Faces", type = "Function", action = function(c) applyFace(c) end },
    ["Scary Smile Outfit"] = { category = "Outfits", type = "Function", action = function(c, e)
        if not c then return end
        if e then
            if not State.Scripted.ScarySmile then
                local acc = Instance.new("Accessory") acc.Name = "ScarySmileAccessory"
                local h = Instance.new("Part", acc) h.Name, h.Size, h.Transparency = "Handle", Vector3.one, 1
                local m = Instance.new("SpecialMesh", h) m.MeshType, m.MeshId, m.Scale = Enum.MeshType.FileMesh, "rbxassetid://111022241256851", Vector3.new(1.03, 1.03, 1.03)
                local d = Instance.new("Decal", h) d.Face, d.Texture = Enum.NormalId.Front, "http://www.roblox.com/asset/?id=120935988855219"
                local ns = Instance.new("Shirt") ns.Name, ns.ShirtTemplate = "WR_Item", "http://www.roblox.com/asset/?id=11275376793"
                local np = Instance.new("Pants") np.Name, np.PantsTemplate = "WR_Item", "http://www.roblox.com/asset/?id=5043452775"
                State.Scripted.ScarySmile = { acc = acc, shirt = ns, pants = np }
            end
            local it = State.Scripted.ScarySmile CM:Hide(c, "Shirt") CM:Hide(c, "Pants") it.shirt.Parent, it.pants.Parent = c, c
            local hum = c:FindFirstChildOfClass("Humanoid") if hum then hum:AddAccessory(it.acc) else it.acc.Parent = c end
            local head = c:FindFirstChild("Head") if head then AM:Bind(head, it.acc) end
            applyFace(c)
        else
            local it = State.Scripted.ScarySmile if it then safeDestroy(it.acc) safeDestroy(it.shirt) safeDestroy(it.pants) State.Scripted.ScarySmile = nil end
            CM:Show(c, "Shirt") CM:Show(c, "Pants") applyFace(c)
        end
    end },
    ["Remove Original Shirt"] = { category = "Outfit", type = "Function", action = function(c, e) if e then CM:Hide(c, "Shirt") else CM:Show(c, "Shirt") end end },
    ["Remove Original Pants"] = { category = "Outfit", type = "Function", action = function(c, e) if e then CM:Hide(c, "Pants") else CM:Show(c, "Pants") end end },
    ["Remove Original T-Shirts"] = { category = "Outfit", type = "Function", action = function(c, e) if e then CM:Hide(c, "TShirt") else CM:Show(c, "TShirt") end end },
    ["Remove Original Accessories"] = { category = "Outfit", type = "Function", action = function(c, e)
        if not c then return end
        if e then for _, it in ipairs(c:GetChildren()) do if it:IsA("Accessory") and not it:GetAttribute("WR_Acc") then table.insert(State.Orig.Clothing.Accessories, it) it.Parent = nil end end
        else for _, it in ipairs(State.Orig.Clothing.Accessories) do pcall(function() it.Parent = c end) end State.Orig.Clothing.Accessories = {} end
    end }
}

local accDefs = {
    {"Vinsmoke Blonde TS Boy Hair","Body","Hair",16990001265}, {"Sanji (✔)","Body","Hair",86494218909624}, {"Valkyrie Helm","Accessories","Head",1365767}, {"Wings of Duality","Accessories","Torso",493489765},
    {"Lowered Hair Ear Tufts (Pink)","Accessories","Head",8275341781}, {"Y2K Long Wavy Pigtails in Pink","Accessories","Head",11364071979}, {"Middle Swept Spiky Bangs in Pink","Accessories","Head",9008209306},
    {"Wispy Willow Pigtails in Pink","Accessories","Head",12394572381}, {"Straight Bangs (Pink)","Accessories","Head",12850356248}, {"Black Cutesy Side Ruffles 3.0","Accessories","Torso",12366756122},
    {"Fiery Horns of the Netherworld","Accessories","Head",215718515}, {"Blackvalk","Accessories","Head",124730194}, {"Frozen Horns of the Frigid Planes","Accessories","Head",74891470},
    {"Silver King of the Night","Accessories","Head",439945661}, {"Poisoned Horns of the Toxic Wasteland","Accessories","Head",1744060292}, {"Sanji Ears (PTS)","Accessories","Face",81759542155072},
    {"Sanji","Accessories","Face",93768783006575}, {"Black Folded Collar with Buttons","Accessories","Neck",80756618475441}, {"Tailcoat Addon","Accessories","Waist",114813132263944}
}
for _, it in ipairs(accDefs) do allActions[it[1]] = { category = it[2], type = "Accessory", action = { [it[3]] = { it[4] } } } end

-- // UI Tabs & Sections Construction \ --
local Tabs = { Appearance = Window:AddTab("Appearance", "shirt"), Crosshair = Window:AddTab("Crosshair", "crosshair"), Watermark = Window:AddTab("Watermark", "type"), Useful = Window:AddTab("Useful", "wrench"), Titan = Window:AddTab("Titan Engine", "globe"), Settings = Window:AddTab("UI Settings", "settings") }
local G = {
    Acc = Tabs.Appearance:AddLeftGroupbox("Accessories"), Body = Tabs.Appearance:AddLeftGroupbox("Body Modifications"), Faces = Tabs.Appearance:AddLeftGroupbox("Faces"),
    Cloth = Tabs.Appearance:AddLeftGroupbox("Clothing (Visual)"), Outfit = Tabs.Appearance:AddLeftGroupbox("Outfit Management"), Anim = Tabs.Appearance:AddLeftGroupbox("Animation"),
    Custom = Tabs.Appearance:AddRightGroupbox("Custom Asset Loader 📦"), Emotes = Tabs.Appearance:AddRightGroupbox("Custom Emotes"), NameTag = Tabs.Appearance:AddRightGroupbox("Custom NameTag"), Outfits = Tabs.Appearance:AddLeftGroupbox("Full Outfits"),
    Tools = Tabs.Useful:AddLeftGroupbox("Tools"), TitanEnv = Tabs.Titan:AddLeftGroupbox("Environment 🌍"), TitanVis = Tabs.Titan:AddRightGroupbox("RTX & Visuals 🎨"),
    CH_Gen = Tabs.Crosshair:AddLeftGroupbox("General"), CH_Col = Tabs.Crosshair:AddLeftGroupbox("Color"), CH_Out = Tabs.Crosshair:AddRightGroupbox("Outline"), CH_Anim = Tabs.Crosshair:AddRightGroupbox("Animation"),
    WM_Gen = Tabs.Watermark:AddLeftGroupbox("General"), WM_Pos = Tabs.Watermark:AddLeftGroupbox("Position"), WM_Out = Tabs.Watermark:AddRightGroupbox("Outline")
}

local catMap = { Accessories = G.Acc, Body = G.Body, Faces = G.Faces, Clothing = G.Cloth, Outfit = G.Outfit, Outfits = G.Outfits }
for name, data in pairs(allActions) do
    if catMap[data.category] then
        catMap[data.category]:AddToggle(name, { Text = name, Default = false, Callback = function(v)
            State.Cache.Applied[name] = nil if not v and data.type == "Function" then pcall(data.action, Player.Character, false) end syncChar(Player.Character)
        end })
    end
end

if Player.Character then captureColors(Player.Character, false) end
for _, limb in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
    G.Body:AddLabel(limb .. " Color"):AddColorPicker(limb .. "Color", { Default = State.Orig.LimbColors[limb] or Color3.fromRGB(245, 205, 172), Callback = function(c) applyColor(Player.Character, limb, c) end })
end
G.Body:AddButton("Reset Limb Colors", function() for g, col in pairs(State.Orig.LimbColors) do applyColor(Player.Character, g, col) if Options[g .. "Color"] then Options[g .. "Color"]:SetValueRGB(col) end end end)

for _, t in ipairs({"Shirt", "Pants", "TShirt"}) do
    G.Cloth:AddDropdown(t .. "Selector", { Values = getKeys(CFG.Clothes[t]), Default = "None", Text = (t == "TShirt" and "T-Shirt" or t), Callback = function(s) CM:Apply(Player.Character, t, s) end })
end

-- // Custom Asset Loader \ --
G.Custom:AddInput("CustomAssetID", { Text = "Roblox Asset ID", Placeholder = "Enter Catalog ID..." })
G.Custom:AddDropdown("CustomAssetType", { Text = "Asset Type", Values = { "Accessory / Hair", "Shirt", "Pants", "T-Shirt" }, Default = "Accessory / Hair" })
G.Custom:AddButton("Load Asset 🚀", function()
    local idStr = getOpt("CustomAssetID", "")
    local cleanId = tonumber(string.match(idStr, "%d+"))
    if not cleanId then return Library:Notify({ Title = "Loader", Content = "Please enter a valid numeric ID!", Duration = 3 }) end
    local aType, char = getOpt("CustomAssetType", "Accessory / Hair"), Player.Character
    if not char then return end

    if aType == "Accessory / Hair" then
        task.spawn(function()
            local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. cleanId)
            local item = ok and objs and objs[1]
            if item then
                local clone = item:Clone()
                local acc = clone:IsA("Accessory") and clone or clone:FindFirstChildWhichIsA("Accessory", true)
                if acc then
                    acc:SetAttribute("WR_Acc", true)
                    acc:SetAttribute("WR_Custom", true)
                    if weldAcc(char, acc) then table.insert(State.Scripted.CustomAccs, acc) end
                elseif attachHair(char, clone) then
                    clone:SetAttribute("WR_Custom", true)
                    table.insert(State.Scripted.CustomAccs, clone)
                end
                Library:Notify({ Title = "Asset Loader", Content = "Custom item attached!", Duration = 3 })
            else
                Library:Notify({ Title = "Asset Loader", Content = "Could not fetch accessory.", Duration = 3 })
            end
        end)
    else
        local typeMap = { ["Shirt"] = "Shirt", ["Pants"] = "Pants", ["T-Shirt"] = "TShirt" }
        local tStr = typeMap[aType]
        local def = CM.Types[tStr]
        task.spawn(function()
            local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. cleanId)
            local it = ok and objs and (objs[1]:IsA(def.c) and objs[1] or objs[1]:FindFirstChildWhichIsA(def.c, true))
            local val = it and it[def.p]
            if val then
                safeDestroy(State.Scripted[tStr])
                local item = Instance.new(def.c) item.Name, item[def.p], item.Parent = "WR_Item", val, char
                State.Scripted[tStr] = item
                Library:Notify({ Title = "Asset Loader", Content = aType .. " applied!", Duration = 3 })
            else
                Library:Notify({ Title = "Asset Loader", Content = "Invalid clothing ID!", Duration = 3 })
            end
        end)
    end
end)
G.Custom:AddButton("Clear Custom Items 🗑️", function()
    for _, obj in ipairs(State.Scripted.CustomAccs) do safeDestroy(obj) end
    State.Scripted.CustomAccs = {}
    for _, t in ipairs({"Shirt", "Pants", "TShirt"}) do safeDestroy(State.Scripted[t]) State.Scripted[t] = nil CM:Apply(Player.Character, t, getOpt(t .. "Selector", "None")) end
    Library:Notify({ Title = "Asset Loader", Content = "Custom items cleared!", Duration = 3 })
end)

G.Anim:AddDropdown("AnimationPackSelector", { Values = getKeys(CFG.Anims), Default = "None", Text = "Animation Pack", Callback = function(p) applyAnim(Player.Character, p) end })
for name, ov in pairs(CFG.Ovr) do G.Anim:AddToggle(ov.k, { Text = name, Default = false, Callback = function() applyAnim(Player.Character, getOpt("AnimationPackSelector", "None")) end }) end

G.Emotes:AddDropdown("EmoteSelector", { Values = getKeys(CFG.Emotes), Default = "None", Text = "Select Emote" })
G.Emotes:AddButton("Play Emote ▶️", function() playEmote(Player.Character, getOpt("EmoteSelector", "None")) end)
G.Emotes:AddButton("Stop Emote ⏹️", stopEmote)

-- // Throttled NameTag \ --
G.NameTag:AddInput("NameTagText", { Default = "[VIP]", Text = "Tag Text" })
G.NameTag:AddLabel("Tag Color"):AddColorPicker("NameTagColor", { Default = Color3.fromRGB(255, 215, 0) })
G.NameTag:AddToggle("NameTagEnabled", { Text = "Enable NameTag", Default = false, Callback = function(v)
    if State.Conn.Env["NTLoop"] then State.Conn.Env["NTLoop"]:Disconnect() State.Conn.Env["NTLoop"] = nil end
    if v then
        local lastNTUpdate = 0
        State.Conn.Env["NTLoop"] = RunService.RenderStepped:Connect(function()
            if not getTog("NameTagEnabled") or tick() - lastNTUpdate < 0.5 then return end
            lastNTUpdate = tick()
            local tag, col = getOpt("NameTagText", "[VIP]"), (Options.NameTagColor and Options.NameTagColor.Value) or Color3.fromRGB(255, 215, 0)
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.DisplayName ~= tag .. " " .. Player.Name then hum.DisplayName = tag .. " " .. Player.Name end
            pcall(function()
                local s = Player.PlayerGui.MainGui.main.tos.scroll
                for _, sample in ipairs(s:GetChildren()) do
                    local nl = sample.Name == "sample" and sample:FindFirstChild("name")
                    if nl and string.find(nl.Text, Player.Name, 1, true) and not string.find(nl.Text, tag, 1, true) then
                        nl.Text, nl.TextColor3 = tag .. " " .. nl.Text, col
                    end
                end
            end)
        end)
    elseif Player.Character then local h = Player.Character:FindFirstChildOfClass("Humanoid") if h then h.DisplayName = Player.DisplayName end end
end })

-- // Crosshair & Watermark Controls \ --
G.CH_Gen:AddToggle("CrosshairEnable", { Text = "Enable Crosshair", Default = true })
G.CH_Gen:AddSlider("CrosshairLines", { Text = "Lines", Default = 4, Min = 0, Max = 16, Rounding = 0 })
G.CH_Gen:AddSlider("CrosshairWidth", { Text = "Width", Default = 2, Min = 1, Max = 50, Rounding = 0 })
G.CH_Gen:AddSlider("CrosshairRadius", { Text = "Radius (Gap)", Default = 85, Min = 0, Max = 200, Rounding = 0 })

G.CH_Col:AddToggle("CrosshairRainbow", { Text = "Rainbow Mode", Default = true })
G.CH_Col:AddSlider("CrosshairRainbowSpeed", { Text = "Rainbow Speed", Default = 0.3, Min = 0.1, Max = 2, Rounding = 2 })
G.CH_Col:AddLabel("Base Color"):AddColorPicker("CrosshairColor", { Default = Color3.fromRGB(255, 255, 255) })

G.CH_Out:AddToggle("CrosshairOutlineEnable", { Text = "Enable Outline", Default = true })
G.CH_Out:AddSlider("CrosshairOutlineThickness", { Text = "Thickness", Default = 1, Min = 0, Max = 10, Rounding = 1 })
G.CH_Out:AddLabel("Outline Color"):AddColorPicker("CrosshairOutlineColor", { Default = Color3.new(0, 0, 0) })

G.CH_Anim:AddToggle("CrosshairRotateEnable", { Text = "Rotation", Default = true })
G.CH_Anim:AddSlider("CrosshairRotateSpeed", { Text = "Rotation Speed", Default = 150, Min = 0, Max = 500, Rounding = 0 })
G.CH_Anim:AddToggle("CrosshairPulseEnable", { Text = "Pulse", Default = true })
G.CH_Anim:AddSlider("CrosshairPulseSpeed", { Text = "Pulse Speed", Default = 150, Min = 0, Max = 500, Rounding = 0 })
G.CH_Anim:AddSlider("CrosshairBaseLength", { Text = "Base Length", Default = 55, Min = 1, Max = 200, Rounding = 0 })
G.CH_Anim:AddSlider("CrosshairPulseMin", { Text = "Pulse Min Length", Default = 30, Min = 1, Max = 200, Rounding = 0 })
G.CH_Anim:AddSlider("CrosshairPulseMax", { Text = "Pulse Max Length", Default = 55, Min = 1, Max = 200, Rounding = 0 })

Toggles.CrosshairPulseEnable:OnChanged(function()
    local isP = Toggles.CrosshairPulseEnable.Value
    if Options.CrosshairBaseLength and Options.CrosshairBaseLength.Holder then Options.CrosshairBaseLength.Holder.Visible = not isP end
    if Options.CrosshairPulseMin and Options.CrosshairPulseMin.Holder then Options.CrosshairPulseMin.Holder.Visible = isP end
    if Options.CrosshairPulseMax and Options.CrosshairPulseMax.Holder then Options.CrosshairPulseMax.Holder.Visible = isP end
end)
task.defer(function() Toggles.CrosshairPulseEnable:SetValue(Toggles.CrosshairPulseEnable.Value) end)

G.WM_Gen:AddToggle("WatermarkEnable", { Text = "Enable Watermark", Default = true })
G.WM_Gen:AddInput("WatermarkText", { Text = "Watermark Text", Default = "Talkingband", Placeholder = "Enter text..." })
G.WM_Gen:AddSlider("WatermarkSize", { Text = "Text Size", Default = 16, Min = 8, Max = 48, Rounding = 0 })
G.WM_Gen:AddDropdown("WatermarkFont", { Text = "Font Face", Values = { "SourceSansBold", "GothamBold", "Code", "Antique", "ArialBold", "Fantasy" }, Default = "SourceSansBold" })
G.WM_Pos:AddSlider("WatermarkOffsetX", { Text = "Offset X", Default = 0, Min = -100, Max = 100, Rounding = 0 })
G.WM_Pos:AddSlider("WatermarkOffsetY", { Text = "Offset Y", Default = 30, Min = -100, Max = 100, Rounding = 0 })
G.WM_Out:AddToggle("WatermarkOutlineEnable", { Text = "Enable Outline", Default = true })
G.WM_Out:AddLabel("Outline Color"):AddColorPicker("WatermarkOutlineColor", { Default = Color3.new(0, 0, 0) })

-- // High-Precision Cached Crosshair & Watermark Elements \ --
local ScreenGui = Library.ScreenGui or game:GetService("CoreGui"):FindFirstChild("Obsidian") or Instance.new("ScreenGui", game:GetService("CoreGui"))
local chContainer = Instance.new("Frame", ScreenGui)
chContainer.Name, chContainer.BackgroundTransparency, chContainer.Size = "CHContainer", 1, UDim2.new(1, 0, 1, 0)

local wmObject = Instance.new("TextLabel", ScreenGui)
wmObject.Name, wmObject.AnchorPoint, wmObject.BackgroundTransparency, wmObject.ZIndex = "WMObject", Vector2.new(0.5, 0.5), 1, 2

local chElements = {}
for i = 1, 16 do
    local f = Instance.new("Frame", chContainer)
    f.AnchorPoint = Vector2.new(0.5, 1) -- Fixed Outward Expansion Pivot
    f.Visible = false
    local st = Instance.new("UIStroke", f)
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.LineJoinMode = Enum.LineJoinMode.Miter
    table.insert(chElements, { frame = f, stroke = st })
end

-- // High-Performance & Sharp Render Loop \ --
State.Conn.CrosshairRender = RunService.RenderStepped:Connect(function()
    if not Options.CrosshairRadius then return end
    local _t, mLoc, gIns = tick(), UserInputService:GetMouseLocation(), GuiService:GetGuiInset()
    local finalM = mLoc - gIns
    local chEn, wmEn = getTog("CrosshairEnable"), getTog("WatermarkEnable")
    chContainer.Visible, wmObject.Visible = chEn, wmEn
    local col = getTog("CrosshairRainbow") and Color3.fromHSV((_t * getOpt("CrosshairRainbowSpeed", 0.3)) % 1, 1, 1) or (Options.CrosshairColor and Options.CrosshairColor.Value or Color3.new(1, 1, 1))

    if chEn then
        local lines = getOpt("CrosshairLines", 4)
        local rad = getOpt("CrosshairRadius", 85)
        local width = getOpt("CrosshairWidth", 2)
        local rotEn = getTog("CrosshairRotateEnable")
        local rotSpeed = getOpt("CrosshairRotateSpeed", 150)
        local pulseEn = getTog("CrosshairPulseEnable")
        local pulseSpeed = getOpt("CrosshairPulseSpeed", 150)
        local baseLen = getOpt("CrosshairBaseLength", 55)
        local pulseMin = getOpt("CrosshairPulseMin", 30)
        local pulseMax = getOpt("CrosshairPulseMax", 55)
        local outEn = getTog("CrosshairOutlineEnable")
        local outThick = getOpt("CrosshairOutlineThickness", 1)
        local outCol = (Options.CrosshairOutlineColor and Options.CrosshairOutlineColor.Value) or Color3.new(0, 0, 0)

        local len = pulseEn and (pulseMin + ((pulseMax - pulseMin) * ((math.sin(math.rad(_t * pulseSpeed)) + 1) / 2))) or baseLen
        local rotOffset = rotEn and (_t * rotSpeed % 360) or 0

        for idx = 1, 16 do
            local el = chElements[idx]
            local f, st = el.frame, el.stroke
            if idx <= lines then
                f.Visible = true
                local ang = (idx - 1) * (360 / lines) + rotOffset
                local rAng = math.rad(ang)
                local px = math.round(finalM.X + math.sin(rAng) * rad)
                local py = math.round(finalM.Y + math.cos(rAng) * rad)

                f.Position = UDim2.fromOffset(px, py)
                f.Size = UDim2.fromOffset(math.round(width), math.round(len))
                f.Rotation = -ang
                f.BackgroundColor3 = col

                st.Enabled = outEn
                st.Thickness = outThick
                st.Color = outCol
            else
                f.Visible = false
            end
        end
    end

    if wmEn then
        wmObject.Text = getOpt("WatermarkText", "Talkingband")
        wmObject.TextSize = getOpt("WatermarkSize", 16)
        wmObject.Font = Enum.Font[getOpt("WatermarkFont", "SourceSansBold")] or Enum.Font.SourceSansBold
        wmObject.TextColor3 = col
        wmObject.TextStrokeColor3 = (Options.WatermarkOutlineColor and Options.WatermarkOutlineColor.Value) or Color3.new(0, 0, 0)
        wmObject.TextStrokeTransparency = getTog("WatermarkOutlineEnable") and 0 or 1
        wmObject.Position = UDim2.fromOffset(math.round(finalM.X + getOpt("WatermarkOffsetX", 0)), math.round(finalM.Y + getOpt("WatermarkOffsetY", 30)))
    end
end)

-- // Titan Engine Tools (Classic Rain & Fog Engine) \ --
G.TitanEnv:AddToggle("RainToggle", { Text = "Enable Rain & Fog", Default = false, Callback = function(enabled)
    pcall(function() RunService:UnbindFromRenderStep("ExecutorRainLoop") end)
    local oldPart = Workspace:FindFirstChild("MyExecutorRainPart")
    if oldPart then safeDestroy(oldPart) end

    if not enabled then
        Lighting.FogStart = 0
        playSafeTween(Lighting, {
            FogEnd = 100000,
            FogColor = Color3.fromRGB(190, 190, 190)
        })
        local atm = Lighting:FindFirstChild("MyRTX_Atmosphere")
        if atm and atm:IsA("Atmosphere") then
            playSafeTween(atm, { Density = (Lighting.ClockTime < 6 or Lighting.ClockTime > 18) and 0.45 or 0.28, Haze = 0.5 })
        end
        return
    end

    task.spawn(function()
        local rainPart = Instance.new("Part")
        rainPart.Name = "MyExecutorRainPart"
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

        local intensity = getOpt("RainIntensitySlider", 50)
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

        RunService:BindToRenderStep("ExecutorRainLoop", Enum.RenderPriority.Camera.Value + 1, function()
            local currentCam = Workspace.CurrentCamera
            if currentCam and rainPart and rainPart.Parent then
                local camPos = currentCam.CFrame.Position
                rainPart.Position = Vector3.new(camPos.X, camPos.Y + 70, camPos.Z)
            end
        end)

        -- Classic Fog Setup
        Lighting.FogStart = 0
        playSafeTween(Lighting, {
            FogColor = Color3.fromRGB(155, 160, 165),
            FogEnd = 700 - (intensity * 4)
        })

        local atm = Lighting:FindFirstChild("MyRTX_Atmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            playSafeTween(atm, { Density = 0, Haze = 0 })
        end

        Library:Notify({ Title = "System", Content = "Rain and Fog applied!", Duration = 3 })
    end)
end })

G.TitanEnv:AddSlider("RainIntensitySlider", { Text = "Rain & Storm Intensity", Default = 50, Min = 10, Max = 100, Rounding = 0, Callback = function(Value)
    local rainPart = Workspace:FindFirstChild("MyExecutorRainPart")
    if rainPart then
        local emitter = rainPart:FindFirstChild("RainEmitter")
        if emitter then
            emitter.Rate = Value * 40
            emitter.Speed = NumberRange.new(50 + Value)
        end
        playSafeTween(Lighting, {
            FogEnd = 700 - (Value * 4)
        })
    end
end })

-- // Complete & Instant Minecraft Textures Engine \ --
G.TitanEnv:AddButton("Apply MineCraft Textures", function()
    task.spawn(function()
        local MS = game:GetService("MaterialService")
        for _, c in ipairs(MS:GetChildren()) do
            if c:IsA("MaterialVariant") and string.sub(c.Name, 1, 4) == "abs_" then
                pcall(function() MS:SetBaseMaterialOverride(c.BaseMaterial, "") end)
                safeDestroy(c)
            end
        end

        local activeVariants = {}
        for matEnum, idList in pairs(MC_MATERIALS) do
            local rawId = idList[math.random(1, #idList)]
            local formattedId = string.find(rawId, "rbxassetid://") and rawId or ("rbxassetid://" .. rawId)
            local variantName = "abs_" .. matEnum.Name

            local v = Instance.new("MaterialVariant")
            v.Name = variantName
            v.BaseMaterial = matEnum
            v.ColorMap = formattedId
            v.StudsPerTile = 4
            v.Parent = MS

            activeVariants[matEnum] = variantName
            pcall(function() MS:SetBaseMaterialOverride(matEnum, variantName) end)
        end

        local function cleanPart(p)
            if not p or not p.Parent or not p:IsA("BasePart") or p:IsA("Terrain") then return end
            if p:FindFirstAncestorWhichIsA("Tool") or p:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid") then return end

            local var = activeVariants[p.Material]
            if var then
                p.MaterialVariant = var
                if p:IsA("MeshPart") then p.TextureID = "" end
                for _, d in ipairs(p:GetChildren()) do
                    if d:IsA("Texture") or d:IsA("Decal") then d.Transparency = 1
                    elseif d:IsA("SurfaceAppearance") then safeDestroy(d) end
                end
            end
        end

        local partQueue = {}
        local isProcessing = false

        local function runQueue()
            if isProcessing then return end
            isProcessing = true
            task.spawn(function()
                while #partQueue > 0 do
                    local count = math.min(150, #partQueue)
                    for _ = 1, count do
                        local p = table.remove(partQueue)
                        if p then pcall(cleanPart, p) end
                    end
                    task.wait(0.02)
                end
                isProcessing = false
            end)
        end

        if State.Conn.Env["MC_Tex"] then State.Conn.Env["MC_Tex"]:Disconnect() end
        State.Conn.Env["MC_Tex"] = Workspace.DescendantAdded:Connect(function(p)
            if p:IsA("BasePart") then
                table.insert(partQueue, p)
                runQueue()
            end
        end)

        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then table.insert(partQueue, d) end
        end
        runQueue()

        Library:Notify({ Title = "System", Content = "MineCraft Textures applied successfully!", Duration = 3 })
    end)
end)

-- // Continuous Universal Sky Enforcement \ --
G.TitanEnv:AddButton("Enforce Universal Sky", function()
    local skyBox = { SkyboxBk = "rbxassetid://12216109205", SkyboxDn = "rbxassetid://12216109875", SkyboxFt = "rbxassetid://12216109489", SkyboxLf = "rbxassetid://12216110170", SkyboxRt = "rbxassetid://12216110471", SkyboxUp = "rbxassetid://12216108877" }

    local function enforceSky()
        if not State.Scripted.SkyObject or not State.Scripted.SkyObject.Parent then
            State.Scripted.SkyObject = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        end
        local sky = State.Scripted.SkyObject
        for p, v in pairs(skyBox) do if sky[p] ~= v then sky[p] = v end end
        if Lighting.ClockTime ~= 14 then Lighting.ClockTime = 14 end
        if Lighting.Brightness ~= 2.0 then Lighting.Brightness = 2.0 end
        Lighting.Ambient = Color3.fromRGB(135, 140, 150)
        Lighting.OutdoorAmbient = Color3.fromRGB(135, 140, 150)
    end

    for _, d in ipairs(Lighting:GetChildren()) do
        if (d:IsA("Atmosphere") or d:IsA("BloomEffect") or d:IsA("ColorCorrectionEffect") or d:IsA("SunRaysEffect")) and not string.match(d.Name, "^MyRTX_") then safeDestroy(d) end
    end
    enforceSky()

    if State.Conn.Env["Sky1"] then State.Conn.Env["Sky1"]:Disconnect() end
    if State.Conn.Env["Sky2"] then State.Conn.Env["Sky2"]:Disconnect() end

    State.Conn.Env["Sky1"] = Lighting.ChildAdded:Connect(function(d)
        if (d:IsA("Atmosphere") or d:IsA("BloomEffect") or d:IsA("ColorCorrectionEffect") or d:IsA("SunRaysEffect")) and not string.match(d.Name, "^MyRTX_") then
            task.defer(function() safeDestroy(d) end)
        end
    end)
    State.Conn.Env["Sky2"] = RunService.RenderStepped:Connect(enforceSky)

    Library:Notify({ Title = "System", Content = "Universal Sky enforced continuously!", Duration = 3 })
end)

-- // Clean RTX Engine (Compatible with Classic Fog) \ --
local function applyRTXPreset(mode)
    local atm = getEffect("Atmosphere", "MyRTX_Atmosphere")
    local blm = getEffect("BloomEffect", "MyRTX_Bloom")
    local sun = getEffect("SunRaysEffect", "MyRTX_SunRays")
    local col = getEffect("ColorCorrectionEffect", "MyRTX_Color")
    local blr = getEffect("BlurEffect", "MyRTX_Blur")

    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.2
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    pcall(function() Lighting.Technology = Enum.Technology.Future end)

    local isRain = getTog("RainToggle")

    if mode == "Day" then
        local lightingProps = {
            ClockTime = 14.5, Brightness = 2.4, GeographicLatitude = 41.7,
            Ambient = Color3.fromRGB(45, 45, 52), OutdoorAmbient = Color3.fromRGB(85, 90, 100),
            ExposureCompensation = 0.05
        }
        if not isRain then
            lightingProps.FogColor = Color3.fromRGB(215, 225, 240)
            lightingProps.FogStart = 500
            lightingProps.FogEnd = 2500
            playSafeTween(atm, { Density = 0.28, Offset = 0.25, Haze = 0.5, Glare = 0.4, Color = Color3.fromRGB(195, 210, 235), Decay = Color3.fromRGB(105, 115, 135) })
        else
            playSafeTween(atm, { Density = 0, Haze = 0 })
        end
        playSafeTween(Lighting, lightingProps)
        playSafeTween(sun, { Intensity = 0.12, Spread = 0.35 })
        playSafeTween(blm, { Intensity = getOpt("RTXBloomSlider", 0.4), Size = 16, Threshold = 0.88 })
        playSafeTween(col, { Brightness = 0.02, Contrast = getOpt("RTXContrastSlider", 0.15), Saturation = getOpt("RTXSaturationSlider", 0.18), TintColor = Color3.fromRGB(255, 252, 248) })

    elseif mode == "Night" then
        local lightingProps = {
            ClockTime = 0, Brightness = 1.2, GeographicLatitude = 41.7,
            Ambient = Color3.fromRGB(18, 20, 28), OutdoorAmbient = Color3.fromRGB(25, 30, 45),
            ExposureCompensation = 0
        }
        if not isRain then
            lightingProps.FogColor = Color3.fromRGB(15, 18, 30)
            lightingProps.FogStart = 100
            lightingProps.FogEnd = 1200
            playSafeTween(atm, { Density = 0.45, Offset = 0.1, Haze = 0.8, Glare = 0, Color = Color3.fromRGB(20, 25, 45), Decay = Color3.fromRGB(10, 15, 30) })
        else
            playSafeTween(atm, { Density = 0, Haze = 0 })
        end
        playSafeTween(Lighting, lightingProps)
        playSafeTween(sun, { Intensity = 0, Spread = 0.1 })
        playSafeTween(blm, { Intensity = getOpt("RTXBloomSlider", 1.0), Size = 24, Threshold = 0.72 })
        playSafeTween(col, { Brightness = 0, Contrast = getOpt("RTXContrastSlider", 0.22), Saturation = getOpt("RTXSaturationSlider", 0.22), TintColor = Color3.fromRGB(210, 230, 255) })
    end
    playSafeTween(blr, { Size = 0 })
end

G.TitanVis:AddButton("Activate RTX Ultra Day ☀️", function() applyRTXPreset("Day") Library:Notify({ Title = "RTX Engine", Content = "RTX Ultra Day Mode Applied!", Duration = 3 }) end)
G.TitanVis:AddButton("Activate RTX Cyberpunk Night 🌙", function() applyRTXPreset("Night") Library:Notify({ Title = "RTX Engine", Content = "RTX Cyberpunk Night Applied!", Duration = 3 }) end)

G.TitanVis:AddSlider("RTXBloomSlider", {
    Text = "Bloom Glow Intensity", Default = 0.4, Min = 0, Max = 2, Rounding = 2,
    Callback = function(v)
        local blm = Lighting:FindFirstChild("MyRTX_Bloom")
        if blm and blm:IsA("BloomEffect") then playSafeTween(blm, { Intensity = v }) end
    end
})

G.TitanVis:AddSlider("RTXSaturationSlider", {
    Text = "Color Vibrance / Saturation", Default = 0.2, Min = -0.5, Max = 1, Rounding = 2,
    Callback = function(v)
        local col = Lighting:FindFirstChild("MyRTX_Color")
        if col and col:IsA("ColorCorrectionEffect") then playSafeTween(col, { Saturation = v }) end
    end
})

G.TitanVis:AddSlider("RTXContrastSlider", {
    Text = "Dynamic Range Contrast", Default = 0.18, Min = -0.2, Max = 0.6, Rounding = 2,
    Callback = function(v)
        local col = Lighting:FindFirstChild("MyRTX_Color")
        if col and col:IsA("ColorCorrectionEffect") then playSafeTween(col, { Contrast = v }) end
    end
})

G.TitanVis:AddButton("Reset Lighting to Default 🔄", function()
    for _, d in ipairs(Lighting:GetChildren()) do
        if string.match(d.Name, "^MyRTX_") then safeDestroy(d) end
    end
    local resetProps = {
        ClockTime = 14, Brightness = 2, Ambient = Color3.fromRGB(128, 128, 128),
        OutdoorAmbient = Color3.fromRGB(128, 128, 128), ExposureCompensation = 0,
        EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0
    }
    if not getTog("RainToggle") then
        resetProps.FogEnd = 100000
        resetProps.FogStart = 0
        resetProps.FogColor = Color3.fromRGB(190, 190, 190)
    else
        local int = getOpt("RainIntensitySlider", 50)
        resetProps.FogEnd = 700 - (int * 4)
        resetProps.FogStart = 0
        resetProps.FogColor = Color3.fromRGB(155, 160, 165)
    end
    playSafeTween(Lighting, resetProps)
    Library:Notify({ Title = "RTX Engine", Content = "Lighting reset to normal.", Duration = 3 })
end)

-- // Tools & Keybinds \ --
G.Tools:AddLabel("Toggle UI"):AddKeyPicker("ToggleUIKeybind", { Default = "RightControl", NoUI = true, Text = "Toggle UI" })
Library.ToggleKeybind = Options.ToggleUIKeybind

local function resetAllUI()
    for n in pairs(allActions) do if Toggles[n] then Toggles[n]:SetValue(false) end end
    if Toggles["NameTagEnabled"] then Toggles["NameTagEnabled"]:SetValue(false) end
    for _, t in ipairs({"Shirt", "Pants", "TShirt"}) do if Options[t .. "Selector"] then Options[t .. "Selector"]:SetValue("None") end end
    if Options["AnimationPackSelector"] then Options["AnimationPackSelector"]:SetValue("None") end
    for _, ov in pairs(CFG.Ovr) do if Toggles[ov.k] then Toggles[ov.k]:SetValue(false) end end
    if Options["EmoteSelector"] then Options["EmoteSelector"]:SetValue("None") end
    for _, obj in ipairs(State.Scripted.CustomAccs) do safeDestroy(obj) end State.Scripted.CustomAccs = {}
    stopEmote()
end

G.Tools:AddButton("Reset All", function() resetAllUI() fullReset(Player.Character) end)
G.Tools:AddButton("Unload Script", function()
    if State.Conn.CrosshairRender then State.Conn.CrosshairRender:Disconnect() State.Conn.CrosshairRender = nil end
    if chContainer then safeDestroy(chContainer) end if wmObject then safeDestroy(wmObject) end
    for _, c in pairs(State.Conn.Env) do if c then pcall(function() c:Disconnect() end) end end
    local rPart = Workspace:FindFirstChild("MyExecutorRainPart") if rPart then safeDestroy(rPart) end
    pcall(function() RunService:UnbindFromRenderStep("ExecutorRainLoop") end)

    local MS = game:GetService("MaterialService")
    for _, c in ipairs(MS:GetChildren()) do
        if c:IsA("MaterialVariant") and string.sub(c.Name, 1, 4) == "abs_" then
            pcall(function() MS:SetBaseMaterialOverride(c.BaseMaterial, "") end)
            safeDestroy(c)
        end
    end

    for _, d in ipairs(Lighting:GetChildren()) do
        if string.match(d.Name, "^MyRTX_") then safeDestroy(d) end
    end

    cleanTableInstances(State.Cache.AccTmpl)
    cleanTableInstances(State.Cache.ClothTmpl)
    State.Cache.AccTmpl, State.Cache.ClothTmpl = {}, {}

    resetAllUI() fullReset(Player.Character)
    if State.Conn.CharacterAdded then State.Conn.CharacterAdded:Disconnect() State.Conn.CharacterAdded = nil end
    getgenv().WhiteRoseLoaded = nil Library:Unload()
end)

-- // Character LifeCycle \ --
State.Conn.CharacterAdded = Player.CharacterAdded:Connect(function(c)
    State.CharGen = State.CharGen + 1
    local curGen = State.CharGen

    task.spawn(function()
        c:WaitForChild("Humanoid", 3) c:WaitForChild("Head", 5)
        local t0 = tick() while tick() - t0 < 2 and not Player:HasAppearanceLoaded() do task.wait(0.1) end
        if not c.Parent or State.CharGen ~= curGen then return end

        stopEmote()
        AM:Clear(Player.Character)
        cleanTableInstances(State.Orig.Clothing)

        State.Scripted = { Shirt = nil, Pants = nil, TShirt = nil, ScarySmile = nil, CustomAccs = {}, SkyObject = nil }
        State.Orig.Clothing, State.Orig.LimbColors, State.Orig.LimbData, State.Cache.Applied = { Shirt = nil, Pants = nil, TShirts = {}, Accessories = {}, Hair = {} }, {}, {}, {}
        captureColors(c, true) pcall(syncChar, c)

        if State.Conn.Env["AppEnforce"] then State.Conn.Env["AppEnforce"]:Disconnect() end
        State.Conn.Env["AppEnforce"] = c.DescendantAdded:Connect(function(d)
            if not d.Parent or d:GetAttribute("WR_Refreshing") or d:IsA("Tool") or d:FindFirstAncestorWhichIsA("Tool") or isScriptedItem(d) then return end
            task.wait() if d.Parent and (d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("Accessory") or d:IsA("BodyColors") or d:IsA("Decal") or d:IsA("SpecialMesh")) then syncChar(c) end
        end)
    end)
end)

if ThemeManager and SaveManager then
    ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({"ToggleUIKeybind"})
    ThemeManager:SetFolder("WhiteRose_Settings") SaveManager:SetFolder("WhiteRose_Settings")
    ThemeManager:ApplyToTab(Tabs.Settings) SaveManager:BuildConfigSection(Tabs.Settings)
    local oldLoad = SaveManager.Load
    if oldLoad then
        function SaveManager:Load(...)
            resetAllUI() fullReset(Player.Character)
            local ok, err = oldLoad(self, ...) if ok then task.wait(0.2) syncChar(Player.Character) end return ok, err
        end
    end
    SaveManager:LoadAutoloadConfig()
end
