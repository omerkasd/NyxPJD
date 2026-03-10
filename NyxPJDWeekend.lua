local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ══════════════════════════════════════════
--              STATE TABLES
-- ══════════════════════════════════════════

local AB = {
    Enabled = false, Smoothness = 0.2,
    AimKey = Enum.UserInputType.MouseButton2, _KeyName = "RightMouseButton",
    BodyPart = "Head", AimMode = "Hold", ToggleState = false,
    FOVEnabled = false, FOVSize = 100, FOVThickness = 1,
    FOVFilled = false, FOVFilledTransparency = 0.8, FOVColor = Color3.fromRGB(255,255,255),
    CrosshairEnabled = false, CrosshairStyle = "Cross", CrosshairSize = 10,
    CrosshairThickness = 1, CrosshairGap = 4, CrosshairColor = Color3.fromRGB(255,255,255),
    CrosshairOutline = true, CrosshairOutlineColor = Color3.fromRGB(0,0,0), CrosshairOpacity = 1,
}

local ESP = {
    Enabled = false,
    Skeleton = false, SkeletonThickness = 1, SkeletonColor = Color3.fromRGB(255,255,255),
    Highlight = false, HighlightTransparency = 0.5, HighlightColor = Color3.fromRGB(0,0,255),
    Box = false, BoxThickness = 2, BoxColor = Color3.fromRGB(255,255,255),
    BoxFill = false,
    HealthBar = false, HealthBarThickness = 2, HealthBarGradient = true,
    HealthText = false, HealthTextPercent = false, HealthTextColor = Color3.fromRGB(255,255,255), HealthTextSize = 16,
    ShowName = false, ShowDisplayName = true, NameColor = Color3.fromRGB(255,255,255), NameSize = 16,
    Distance = false, DistanceSize = 16, DistanceColor = Color3.fromRGB(255,255,255),
    Tracers = false, TracersThickness = 1, TracersColor = Color3.fromRGB(255,255,255), TracersTransparency = 1,
    LookDirection = false, ShowArrow = true, LookDirectionThickness = 2, LookDirectionColor = Color3.fromRGB(255,0,0),
    MaxDistance = 1000,
    ItemESP = false, ItemMaxDistance = 500, ShowItemDistance = true,
    ItemTextSize = 14,
    RareLootColor = Color3.fromRGB(255,215,0), CommonLootColor = Color3.fromRGB(255,255,255),
    LootBoxESP = false,
}

local BOT = {
    Enabled = false,
    Box = false, BoxThickness = 2, BoxColor = Color3.fromRGB(255,80,80),
    BoxFill = false,
    Skeleton = false, SkeletonThickness = 1, SkeletonColor = Color3.fromRGB(255,100,0),
    Highlight = false, HighlightTransparency = 0.5, HighlightColor = Color3.fromRGB(255,80,80),
    HealthBar = false, HealthBarThickness = 2, HealthBarGradient = true,
    HealthText = false, HealthTextPercent = false, HealthTextColor = Color3.fromRGB(255,255,255), HealthTextSize = 16,
    ShowName = false, NameColor = Color3.fromRGB(255,80,80), NameSize = 16,
    Distance = false, DistanceSize = 16, DistanceColor = Color3.fromRGB(255,255,255),
    Tracers = false, TracersThickness = 1, TracersColor = Color3.fromRGB(255,80,80), TracersTransparency = 1,
    MaxDistance = 1000,
    -- Yeni eklenen iyileştirmeler
    Skeleton_Enabled = false,
    ChamsEnabled = false,
    OffScreen = false,
    OffScreenSize = 15,
    OffScreenColor = Color3.fromRGB(255,80,80),
}

local BOTAB = {
    Enabled = false, Smoothness = 0.2,
    AimKey = Enum.UserInputType.MouseButton2, _KeyName = "RightMouseButton",
    BodyPart = "Head", AimMode = "Hold", ToggleState = false,
    FOVEnabled = false, FOVSize = 100, FOVThickness = 1,
    FOVFilled = false, FOVFilledTransparency = 0.8, FOVColor = Color3.fromRGB(255,100,0),
}

-- ══════════════════════════════════════════
--   GLOBAL DECLARATIONS (forward refs fix)
-- ══════════════════════════════════════════

-- BotObjects ve BotConns en üstte tanımlanıyor
-- pickBestBot fonksiyonunun görebilmesi için kritik!
local BotObjects = {}
local BotConns   = {}

-- ESPObjects
local ESPObjects = {}

-- ══════════════════════════════════════════
--              BONES / HELPERS
-- ══════════════════════════════════════════

local BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
}

local function newDrawing(dtype, props)
    local d = Drawing.new(dtype)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function w2s(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end
local function w2sRaw(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return sp.X, sp.Y, onScreen, sp.Z
end

local CORNER_MUL = {
    Vector3.new( 1, 1, 1), Vector3.new(-1, 1, 1),
    Vector3.new( 1,-1, 1), Vector3.new(-1,-1, 1),
    Vector3.new( 1, 1,-1), Vector3.new(-1, 1,-1),
    Vector3.new( 1,-1,-1), Vector3.new(-1,-1,-1),
}
local function getCharBounds(char)
    local minX,minY = math.huge,math.huge
    local maxX,maxY = -math.huge,-math.huge
    local any = false
    for _,part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local sx,sy,sz = part.Size.X*0.5, part.Size.Y*0.5, part.Size.Z*0.5
            local cf = part.CFrame
            for _,m in ipairs(CORNER_MUL) do
                local wp = cf:PointToWorldSpace(Vector3.new(sx*m.X, sy*m.Y, sz*m.Z))
                local sp2,on = Camera:WorldToViewportPoint(wp)
                if on and sp2.Z>0 then
                    any=true
                    if sp2.X<minX then minX=sp2.X end
                    if sp2.Y<minY then minY=sp2.Y end
                    if sp2.X>maxX then maxX=sp2.X end
                    if sp2.Y>maxY then maxY=sp2.Y end
                end
            end
        end
    end
    if not any then return nil end
    return minX,minY,maxX,maxY
end

local _hpColorCache = {}
for i=0,100 do
    local r = i/100
    _hpColorCache[i] = Color3.fromRGB(math.floor(255*(1-r)), math.floor(255*r), 0)
end
local function hpColor(r)
    return _hpColorCache[math.clamp(math.floor(r*100+0.5), 0, 100)]
end

-- ══════════════════════════════════════════
--              DRAWINGS
-- ══════════════════════════════════════════

local AimFOVCircle = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(255,255,255),Thickness=1,Filled=false,Transparency=1,NumSides=64})
local AimFOVFill   = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(255,255,255),Thickness=1,Filled=true,Transparency=0.8,NumSides=64})

local CHLines,CHOutlines = {},{}
for i=1,4 do
    CHLines[i]    = newDrawing("Line",{Visible=false,Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=1})
    CHOutlines[i] = newDrawing("Line",{Visible=false,Color=Color3.fromRGB(0,0,0),Thickness=3,Transparency=1})
end
local CHDot      = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(255,255,255),Filled=true,Thickness=1,NumSides=32,Transparency=1})
local CHDotOut   = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(0,0,0),Filled=false,Thickness=2,NumSides=32,Transparency=1})
local CHCircle   = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(255,255,255),Filled=false,Thickness=1,NumSides=64,Transparency=1})
local CHCircleOut= newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(0,0,0),Filled=false,Thickness=3,NumSides=64,Transparency=1})

local BotAimFOVCircle = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(255,100,0),Thickness=1,Filled=false,Transparency=1,NumSides=64})
local BotAimFOVFill   = newDrawing("Circle",{Visible=false,Color=Color3.fromRGB(255,100,0),Thickness=1,Filled=true,Transparency=0.8,NumSides=64})

-- ══════════════════════════════════════════
--              CROSSHAIR
-- ══════════════════════════════════════════

local function hideCH()
    for _,l in ipairs(CHLines) do l.Visible=false end
    for _,l in ipairs(CHOutlines) do l.Visible=false end
    CHDot.Visible=false; CHDotOut.Visible=false; CHCircle.Visible=false; CHCircleOut.Visible=false
end

local function drawCH(cx,cy)
    hideCH()
    if not AB.CrosshairEnabled then return end
    local sz=AB.CrosshairSize; local gap=AB.CrosshairGap
    local col=AB.CrosshairColor; local ocol=AB.CrosshairOutlineColor
    local thk=AB.CrosshairThickness; local op=AB.CrosshairOpacity
    local style=AB.CrosshairStyle
    if style=="Cross" or style=="Dynamic" then
        local pts={
            {Vector2.new(cx,cy-gap),Vector2.new(cx,cy-gap-sz)},
            {Vector2.new(cx,cy+gap),Vector2.new(cx,cy+gap+sz)},
            {Vector2.new(cx-gap,cy),Vector2.new(cx-gap-sz,cy)},
            {Vector2.new(cx+gap,cy),Vector2.new(cx+gap+sz,cy)},
        }
        for i,p in ipairs(pts) do
            if AB.CrosshairOutline then
                CHOutlines[i].Visible=true; CHOutlines[i].From=p[1]; CHOutlines[i].To=p[2]
                CHOutlines[i].Color=ocol; CHOutlines[i].Thickness=thk+2; CHOutlines[i].Transparency=op
            end
            CHLines[i].Visible=true; CHLines[i].From=p[1]; CHLines[i].To=p[2]
            CHLines[i].Color=col; CHLines[i].Thickness=thk; CHLines[i].Transparency=op
        end
    elseif style=="Dot" then
        if AB.CrosshairOutline then CHDotOut.Visible=true; CHDotOut.Position=Vector2.new(cx,cy); CHDotOut.Radius=thk+2; CHDotOut.Color=ocol; CHDotOut.Transparency=op end
        CHDot.Visible=true; CHDot.Position=Vector2.new(cx,cy); CHDot.Radius=thk; CHDot.Color=col; CHDot.Transparency=op
    elseif style=="Circle" then
        if AB.CrosshairOutline then CHCircleOut.Visible=true; CHCircleOut.Position=Vector2.new(cx,cy); CHCircleOut.Radius=sz+2; CHCircleOut.Color=ocol; CHCircleOut.Thickness=thk+2; CHCircleOut.Transparency=op end
        CHCircle.Visible=true; CHCircle.Position=Vector2.new(cx,cy); CHCircle.Radius=sz; CHCircle.Color=col; CHCircle.Thickness=thk; CHCircle.Transparency=op
    end
end

-- ══════════════════════════════════════════
--              HELPERS
-- ══════════════════════════════════════════

local function newLine(thick, color)
    local d = Drawing.new("Line"); d.Thickness=thick or 1; d.Color=color or Color3.new(1,1,1); d.Visible=false; return d
end
local function newSquare(color, filled, trans)
    local d = Drawing.new("Square"); d.Color=color or Color3.new(1,1,1); d.Filled=filled or false; d.Transparency=trans or 1; d.Visible=false; return d
end
local function newText(color, size)
    local d = Drawing.new("Text"); d.Color=color or Color3.new(1,1,1); d.Size=size or 16; d.Center=true; d.Outline=true; d.Visible=false; return d
end
local function newCircle(color, thick)
    local d = Drawing.new("Circle"); d.Color=color or Color3.new(1,1,1); d.Thickness=thick or 1; d.Filled=false; d.NumSides=32; d.Visible=false; return d
end

-- ══════════════════════════════════════════
--              PLAYER ESP
-- ══════════════════════════════════════════

local function applyHighlight(char)
    pcall(function()
        if char:FindFirstChild("NyxHL") then return end
        local h = Instance.new("Highlight")
        h.Name="NyxHL"; h.FillColor=ESP.HighlightColor
        h.OutlineColor=Color3.fromRGB(0,0,0); h.FillTransparency=ESP.HighlightTransparency
        h.OutlineTransparency=0; h.Parent=char
    end)
end

local function createCharESP(player, char)
    if ESPObjects[char] then return end
    pcall(function()
        if not char:FindFirstChild("HumanoidRootPart") then return end
        local white = Color3.fromRGB(255,255,255)
        local d = {
            top    = newLine(ESP.BoxThickness, white),
            bottom = newLine(ESP.BoxThickness, white),
            left   = newLine(ESP.BoxThickness, white),
            right  = newLine(ESP.BoxThickness, white),
            fill   = newSquare(white, true, 0.3),
            hBG    = newSquare(Color3.fromRGB(0,0,0), true, 0.5),
            hBar   = newSquare(Color3.fromRGB(0,255,0), true, 1),
            hText  = newText(ESP.HealthTextColor, ESP.HealthTextSize),
            name   = newText(ESP.NameColor, ESP.NameSize),
            dist   = newText(ESP.DistanceColor, ESP.DistanceSize),
            tracer = newLine(ESP.TracersThickness, ESP.TracersColor),
            look   = newLine(ESP.LookDirectionThickness, ESP.LookDirectionColor),
            aL     = newLine(ESP.LookDirectionThickness, ESP.LookDirectionColor),
            aR     = newLine(ESP.LookDirectionThickness, ESP.LookDirectionColor),
        }
        ESPObjects[char] = { d=d, player=player }
        char.AncestryChanged:Connect(function() cleanupCharESP(char) end)
    end)
end

local function createESP(player)
    if player == LocalPlayer then return end
    if player.Character then
        task.delay(0.5, function() createCharESP(player, player.Character) end)
    end
    player.CharacterAdded:Connect(function(char)
        task.delay(0.5, function() createCharESP(player, char) end)
    end)
end

function cleanupCharESP(char)
    local entry = ESPObjects[char]
    if entry then
        for _, dr in pairs(entry.d) do pcall(function() dr:Remove() end) end
        ESPObjects[char] = nil
    end
    pcall(function() local h=char:FindFirstChild("NyxHL"); if h then h:Destroy() end end)
end

local function cleanupAllESP()
    for char in pairs(ESPObjects) do cleanupCharESP(char) end
end

local function applyESPToAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            createCharESP(p, p.Character)
        end
    end
end

local function removeESP(player)
    if player.Character then cleanupCharESP(player.Character) end
end

-- ══════════════════════════════════════════
--   PLAYER ESP LOOP
-- ══════════════════════════════════════════
-- ── Görünürlük yardımcısı — sadece değer değişince Visible set eder (flickering önler)
local function svs(dr, val)
    if dr.Visible ~= val then dr.Visible = val end
end

-- Player ESP — RenderStepped, throttling yok, svs kullanır
RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then
        for _, entry in pairs(ESPObjects) do
            for _, dr in pairs(entry.d) do if dr.Visible then dr.Visible = false end end
        end
        return
    end

    local cam    = workspace.CurrentCamera
    local vp     = cam.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local lChar  = LocalPlayer.Character
    local lRoot  = lChar and lChar:FindFirstChild("HumanoidRootPart")
    local lPos   = lRoot and lRoot.Position

    for char, entry in pairs(ESPObjects) do
        pcall(function()
            local d      = entry.d
            local player = entry.player
            local hum    = char:FindFirstChildOfClass("Humanoid")
            local root   = char:FindFirstChild("HumanoidRootPart")

            if not hum or not root or not root.Parent then cleanupCharESP(char); return end

            local dist = lPos and (root.Position - lPos).Magnitude or 999999
            if dist > ESP.MaxDistance then
                for _, dr in pairs(d) do if dr.Visible then dr.Visible=false end end; return
            end

            local rp, onScreen = cam:WorldToViewportPoint(root.Position)
            if not onScreen then
                for _, dr in pairs(d) do if dr.Visible then dr.Visible=false end end; return
            end

            if ESP.Highlight then
                if not char:FindFirstChild("NyxHL") then applyHighlight(char) end
            else
                local hl = char:FindFirstChild("NyxHL"); if hl then hl:Destroy() end
            end

            local hp2 = cam:WorldToViewportPoint(root.Position + Vector3.new(0,2.5,0))
            local lp2 = cam:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            local h   = math.abs(hp2.Y - lp2.Y)
            local w   = h / 2
            local rx, hy, ly = rp.X, hp2.Y, lp2.Y

            if ESP.Box then
                d.top.From=Vector2.new(rx-(w/2),hy);    d.top.To=Vector2.new(rx+(w/2),hy)
                d.bottom.From=Vector2.new(rx-(w/2),ly); d.bottom.To=Vector2.new(rx+(w/2),ly)
                d.left.From=Vector2.new(rx-(w/2),hy);   d.left.To=Vector2.new(rx-(w/2),ly)
                d.right.From=Vector2.new(rx+(w/2),hy);  d.right.To=Vector2.new(rx+(w/2),ly)
                d.top.Color=ESP.BoxColor; d.bottom.Color=ESP.BoxColor
                d.left.Color=ESP.BoxColor; d.right.Color=ESP.BoxColor
                d.top.Thickness=ESP.BoxThickness; d.bottom.Thickness=ESP.BoxThickness
                d.left.Thickness=ESP.BoxThickness; d.right.Thickness=ESP.BoxThickness
                svs(d.top,true); svs(d.bottom,true); svs(d.left,true); svs(d.right,true)
            else svs(d.top,false); svs(d.bottom,false); svs(d.left,false); svs(d.right,false) end

            if ESP.BoxFill then
                d.fill.Size=Vector2.new(w,h); d.fill.Position=Vector2.new(rx-(w/2),hy)
                d.fill.Color=ESP.BoxColor; svs(d.fill,true)
            else svs(d.fill,false) end

            local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
            local bt  = ESP.HealthBarThickness
            if ESP.HealthBar then
                d.hBG.Size=Vector2.new(bt,h); d.hBG.Position=Vector2.new((rx-(w/2)-bt)-2,hy); svs(d.hBG,true)
                d.hBar.Size=Vector2.new(bt,math.max(h*pct,1)); d.hBar.Position=Vector2.new((rx-(w/2)-bt)-2,ly-h*pct)
                d.hBar.Color = ESP.HealthBarGradient and Color3.fromRGB(math.floor((1-pct)*255),math.floor(pct*255),0) or Color3.fromRGB(0,255,0)
                svs(d.hBar,true)
            else svs(d.hBG,false); svs(d.hBar,false) end

            d.name.Text    = ESP.ShowDisplayName and player.DisplayName or player.Name
            d.name.Position= Vector2.new(rx, hy-30)
            d.name.Color=ESP.NameColor; d.name.Size=ESP.NameSize
            svs(d.name, ESP.ShowName)

            d.hText.Text     = ESP.HealthTextPercent and (math.floor(pct*100).."%") or tostring(math.floor(hum.Health))
            d.hText.Position = Vector2.new(rx, hy-45)
            d.hText.Color=ESP.HealthTextColor; d.hText.Size=ESP.HealthTextSize
            svs(d.hText, ESP.HealthText)

            d.dist.Text     = math.floor(dist).." studs"
            d.dist.Position = Vector2.new(rx, ly+15)
            d.dist.Color=ESP.DistanceColor; d.dist.Size=ESP.DistanceSize
            svs(d.dist, ESP.Distance)

            d.tracer.From=Vector2.new(cx,vp.Y); d.tracer.To=Vector2.new(rx,ly)
            d.tracer.Color=ESP.TracersColor; d.tracer.Thickness=ESP.TracersThickness
            d.tracer.Transparency=ESP.TracersTransparency
            svs(d.tracer, ESP.Tracers)

            local head = char:FindFirstChild("Head")
            if head then
                local hsp  = cam:WorldToViewportPoint(head.Position)
                local esp2 = cam:WorldToViewportPoint(head.Position + head.CFrame.LookVector*5)
                d.look.From=Vector2.new(hsp.X,hsp.Y); d.look.To=Vector2.new(esp2.X,esp2.Y)
                d.look.Color=ESP.LookDirectionColor; d.look.Thickness=ESP.LookDirectionThickness
                svs(d.look, ESP.LookDirection)
                if ESP.LookDirection and ESP.ShowArrow then
                    local dir  = Vector2.new(esp2.X-hsp.X, esp2.Y-hsp.Y).Unit
                    local perp = Vector2.new(-dir.Y, dir.X)
                    local ab2  = Vector2.new(esp2.X,esp2.Y) - dir*10
                    d.aL.From=Vector2.new(esp2.X,esp2.Y); d.aL.To=ab2+perp*5
                    d.aR.From=Vector2.new(esp2.X,esp2.Y); d.aR.To=ab2-perp*5
                    d.aL.Color=ESP.LookDirectionColor; d.aR.Color=ESP.LookDirectionColor
                    d.aL.Thickness=ESP.LookDirectionThickness; d.aR.Thickness=ESP.LookDirectionThickness
                    svs(d.aL,true); svs(d.aR,true)
                else svs(d.aL,false); svs(d.aR,false) end
            else svs(d.look,false); svs(d.aL,false); svs(d.aR,false) end
        end)
    end
end)

-- ══════════════════════════════════════════
--         ITEM / LOOT BOX ESP
-- ══════════════════════════════════════════

local ItemDrawings    = {}
local LootBoxDrawings = {}
local LootDescConn    = nil

local RareItems = {"EDF","Military","Armor","Helmet","Vest","AK","M4","Sniper","Rifle","Core","Parts","Medical","Stimulant","Flare"}
local function isRareItem(name)
    for _, kw in ipairs(RareItems) do
        if string.find(string.upper(name), string.upper(kw), 1, true) then return true end
    end
    return false
end

local function removeDrawings(tbl)
    for _, v in pairs(tbl) do
        if type(v) == "table" then for _, d in ipairs(v) do pcall(function() d:Remove() end) end
        else pcall(function() v:Remove() end) end
    end
end

local function createItemESP(item)
    if ItemDrawings[item] then return end
    pcall(function()
        if not (item:IsA("Model") or item:IsA("Tool") or item:IsA("Part")) then return end
        local drawings = {}
        local nameText = Drawing.new("Text")
        nameText.Text = item.Name; nameText.Size = ESP.ItemTextSize
        nameText.Center = true; nameText.Outline = true
        nameText.Color = isRareItem(item.Name) and ESP.RareLootColor or ESP.CommonLootColor
        nameText.Visible = false; table.insert(drawings, nameText)
        local distText = Drawing.new("Text")
        distText.Size = math.max(ESP.ItemTextSize-2, 10); distText.Center = true
        distText.Outline = true; distText.Color = Color3.fromRGB(200,200,200)
        distText.Visible = false; table.insert(drawings, distText)
        ItemDrawings[item] = drawings
        task.spawn(function()
            while item.Parent and ItemDrawings[item] do
                pcall(function()
                    if not ESP.ItemESP then nameText.Visible=false; distText.Visible=false; return end
                    local lRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not lRoot then return end
                    local itemPos
                    if item:IsA("Model") then
                        local pp = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                        itemPos = pp and pp.Position
                    elseif item:IsA("Tool") then
                        local handle = item:FindFirstChild("Handle"); itemPos = handle and handle.Position
                    else itemPos = item.Position end
                    if not itemPos then nameText.Visible=false; distText.Visible=false; return end
                    local distance = (itemPos - lRoot.Position).Magnitude
                    if distance > ESP.ItemMaxDistance then nameText.Visible=false; distText.Visible=false; return end
                    local sp, on = workspace.CurrentCamera:WorldToViewportPoint(itemPos)
                    if on then
                        nameText.Position = Vector2.new(sp.X, sp.Y); nameText.Visible = true
                        distText.Text = "["..math.floor(distance).."m]"
                        distText.Position = Vector2.new(sp.X, sp.Y+15); distText.Visible = ESP.ShowItemDistance
                    else nameText.Visible=false; distText.Visible=false end
                end)
                task.wait(0.05)
            end
            pcall(function() for _, d in ipairs(drawings) do d:Remove() end end)
            ItemDrawings[item] = nil
        end)
    end)
end

local function createLootBoxESP(box)
    if LootBoxDrawings[box] then return end
    pcall(function()
        if not (box:IsA("Model") or box:IsA("Part")) then return end
        local drawings = {}
        local boxText = Drawing.new("Text")
        boxText.Text = "[BOX] "..(box.Name or "Loot Box"); boxText.Size = ESP.ItemTextSize+2
        boxText.Center=true; boxText.Outline=true; boxText.Color=Color3.fromRGB(255,165,0)
        boxText.Visible=false; table.insert(drawings, boxText)
        local distText = Drawing.new("Text")
        distText.Size=math.max(ESP.ItemTextSize-2,10); distText.Center=true
        distText.Outline=true; distText.Color=Color3.fromRGB(200,200,200)
        distText.Visible=false; table.insert(drawings, distText)
        LootBoxDrawings[box] = drawings
        task.spawn(function()
            while box.Parent and LootBoxDrawings[box] do
                pcall(function()
                    if not ESP.LootBoxESP then boxText.Visible=false; distText.Visible=false; return end
                    local lRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not lRoot then return end
                    local boxPos
                    if box:IsA("Model") then
                        local pp = box.PrimaryPart or box:FindFirstChildOfClass("BasePart")
                        boxPos = pp and pp.Position
                    else boxPos = box.Position end
                    if not boxPos then boxText.Visible=false; distText.Visible=false; return end
                    local distance = (boxPos - lRoot.Position).Magnitude
                    if distance > ESP.ItemMaxDistance then boxText.Visible=false; distText.Visible=false; return end
                    local sp, on = workspace.CurrentCamera:WorldToViewportPoint(boxPos)
                    if on then
                        boxText.Position = Vector2.new(sp.X, sp.Y); boxText.Visible = true
                        distText.Text = "["..math.floor(distance).."m]"
                        distText.Position = Vector2.new(sp.X, sp.Y+18); distText.Visible = true
                    else boxText.Visible=false; distText.Visible=false end
                end)
                task.wait(0.05)
            end
            pcall(function() for _, d in ipairs(drawings) do d:Remove() end end)
            LootBoxDrawings[box] = nil
        end)
    end)
end

local function isDroppedItem(obj)
    if obj:IsA("Tool") then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then return false end
        end
        return true
    end
    if obj:IsA("Model") then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then return false end
        end
        if obj:FindFirstChild("Handle") then return true end
    end
    return false
end

local function isLootBox(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then return false end
    end
    local n = obj.Name:lower()
    return n:find("box") or n:find("crate") or n:find("chest") or n:find("container") or n:find("supply") or n:find("airdrop") or n:find("drop") or n:find("loot")
end

local LootScanActive = false
local function scanForLoot()
    if LootScanActive then return end
    LootScanActive = true
    task.spawn(function()
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if ESP.ItemESP and isDroppedItem(obj) and not ItemDrawings[obj] then createItemESP(obj) end
                if ESP.LootBoxESP and isLootBox(obj) and not LootBoxDrawings[obj] then createLootBoxESP(obj) end
            end
        end)
        if not LootDescConn then
            LootDescConn = workspace.DescendantAdded:Connect(function(obj)
                pcall(function()
                    if ESP.ItemESP and isDroppedItem(obj) and not ItemDrawings[obj] then createItemESP(obj) end
                    if ESP.LootBoxESP and isLootBox(obj) and not LootBoxDrawings[obj] then createLootBoxESP(obj) end
                end)
            end)
        end
        while ESP.ItemESP or ESP.LootBoxESP do
            task.wait(3)
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if ESP.ItemESP and isDroppedItem(obj) and not ItemDrawings[obj] then createItemESP(obj) end
                    if ESP.LootBoxESP and isLootBox(obj) and not LootBoxDrawings[obj] then createLootBoxESP(obj) end
                end
            end)
        end
        if LootDescConn then LootDescConn:Disconnect(); LootDescConn = nil end
        LootScanActive = false
    end)
end

-- ══════════════════════════════════════════
--         AIMBOT – TARGET SEÇİM FONKSİYONLARI
-- ══════════════════════════════════════════

local lockedTarget    = nil
local lockedBotTarget = nil  -- Bot için ayrı lock
local AB_Active       = false
local BotAB_Active    = false

local function getTargetPart(char, bodyPart)
    if not char then return nil end
    local part = char:FindFirstChild(bodyPart == "Head" and "Head" or "UpperTorso")
    if not part then part = char:FindFirstChild("HumanoidRootPart") end
    return part
end

local function isValidPlayer(p)
    if p == LocalPlayer then return false end
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- isValidBot: BotObjects tablosundaki modellerle çalışır
local function isValidBot(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local _center2 = Vector2.new(0,0)
local function screenDist(part)
    if not part or not part.Parent then return nil, nil end
    local sp, on, z = w2s(part.Position)
    if not on or z <= 0 then return nil, nil end
    return (sp - _center2).Magnitude, sp
end

local function pickBestPlayer(fovSize)
    local best, bestDist = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if not isValidPlayer(p) then continue end
        local part = getTargetPart(p.Character, AB.BodyPart)
        if not part then continue end
        local dist = screenDist(part)
        if dist and dist <= fovSize and dist < bestDist then
            bestDist = dist; best = part
        end
    end
    return best
end

-- FİX: BotObjects artık en üstte tanımlı, pickBestBot doğru çalışır
local function pickBestBot(fovSize)
    local best, bestDist = nil, math.huge
    for model, d in pairs(BotObjects) do
        if not isValidBot(model) then continue end
        local part = getTargetPart(model, BOTAB.BodyPart)
        if not part then continue end
        local dist = screenDist(part)
        if dist and dist <= fovSize and dist < bestDist then
            bestDist = dist; best = part
        end
    end
    return best
end

-- ══════════════════════════════════════════
--              AIMBOT INPUT
-- ══════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Player Aimbot
    if AB.Enabled then
        local match = (input.UserInputType == AB.AimKey) or (input.KeyCode == AB.AimKey)
        if match then
            if AB.AimMode == "Hold" then
                AB_Active = true
                lockedTarget = nil
            elseif AB.AimMode == "Toggle" then
                AB_Active = not AB_Active
                lockedTarget = nil
            end
        end
    end

    -- Bot Aimbot — Toggle modu da destekleniyor (eski kodda eksikti)
    if BOTAB.Enabled then
        local match = (input.UserInputType == BOTAB.AimKey) or (input.KeyCode == BOTAB.AimKey)
        if match then
            if BOTAB.AimMode == "Hold" then
                BotAB_Active = true
                lockedBotTarget = nil
            elseif BOTAB.AimMode == "Toggle" then
                BotAB_Active = not BotAB_Active
                lockedBotTarget = nil
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    -- Player aimbot hold release
    if AB.AimMode == "Hold" then
        local match = (input.UserInputType == AB.AimKey) or (input.KeyCode == AB.AimKey)
        if match then AB_Active = false; lockedTarget = nil end
    end
    -- Bot aimbot hold release
    if BOTAB.AimMode == "Hold" then
        local match = (input.UserInputType == BOTAB.AimKey) or (input.KeyCode == BOTAB.AimKey)
        if match then BotAB_Active = false; lockedBotTarget = nil end
    end
end)

-- ══════════════════════════════════════════
--              BOT ESP
-- ══════════════════════════════════════════

-- Off-screen arrow drawings (bot için)
local BotOffScreenArrows = {}

local function isNPC(model)
    if not model:IsA("Model") then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return false end
    end
    return true
end

local function applyBotHighlight(model)
    pcall(function()
        if model:FindFirstChild("BotHighlight") then return end
        local h = Instance.new("Highlight")
        h.Name = "BotHighlight"; h.FillColor = BOT.HighlightColor
        h.OutlineColor = Color3.fromRGB(80,0,0); h.FillTransparency = BOT.HighlightTransparency
        h.OutlineTransparency = 0; h.Parent = model
    end)
end

-- Skeleton drawing helpers
local BOT_SKELETON_PARTS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
}

local function createBotESP(model)
    if BotObjects[model] then return end
    pcall(function()
        local root = model:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum  = model:FindFirstChildOfClass("Humanoid"); if not hum then return end

        -- Temel çizimler
        local d = {
            top    = newLine(BOT.BoxThickness, BOT.BoxColor),
            bottom = newLine(BOT.BoxThickness, BOT.BoxColor),
            left   = newLine(BOT.BoxThickness, BOT.BoxColor),
            right  = newLine(BOT.BoxThickness, BOT.BoxColor),
            fill   = newSquare(BOT.BoxColor, true, 0.3),
            hBG    = newSquare(Color3.fromRGB(0,0,0), true, 0.5),
            hBar   = newSquare(Color3.fromRGB(0,255,0), true, 1),
            hText  = newText(BOT.HealthTextColor, BOT.HealthTextSize),
            name   = newText(BOT.NameColor, BOT.NameSize),
            dist   = newText(BOT.DistanceColor, BOT.DistanceSize),
            tracer = newLine(BOT.TracersThickness, BOT.TracersColor),
            -- Off-screen ok
            arrow  = newLine(BOT.BoxThickness, BOT.OffScreenColor),
            arrowL = newLine(BOT.BoxThickness, BOT.OffScreenColor),
            arrowR = newLine(BOT.BoxThickness, BOT.OffScreenColor),
            -- Skeleton lines (14 kemik)
            bones  = {},
            -- Cache
            _hum   = hum,
            _root  = root,
            _model = model,
        }

        -- Skeleton lines oluştur
        for i = 1, #BOT_SKELETON_PARTS do
            d.bones[i] = newLine(BOT.SkeletonThickness, BOT.SkeletonColor)
        end

        BotObjects[model] = d
        BotConns[model] = {}
        local ancConn = model.AncestryChanged:Connect(function() cleanupBotESP(model) end)
        table.insert(BotConns[model], ancConn)
    end)
end

function cleanupBotESP(model)
    if BotObjects[model] then
        local d = BotObjects[model]
        for k, dr in pairs(d) do
            if k ~= "_hum" and k ~= "_root" and k ~= "_model" and k ~= "bones" then
                pcall(function() dr:Remove() end)
            end
        end
        if d.bones then
            for _, bone in ipairs(d.bones) do pcall(function() bone:Remove() end) end
        end
        BotObjects[model] = nil
    end
    if BotConns[model] then
        for _, c in ipairs(BotConns[model]) do pcall(function() c:Disconnect() end) end
        BotConns[model] = nil
    end
    pcall(function() local h = model:FindFirstChild("BotHighlight"); if h then h:Destroy() end end)
end

local BotScanConn = nil
local function startBotScan()
    -- Önce mevcut workspace'i tara
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isNPC(obj) then createBotESP(obj) end
        end
    end)
    if BotScanConn then return end
    BotScanConn = workspace.DescendantAdded:Connect(function(obj)
        pcall(function()
            if obj:IsA("Model") then
                task.delay(0.2, function()
                    if isNPC(obj) then createBotESP(obj) end
                end)
            end
        end)
    end)
end

local function stopBotScan()
    if BotScanConn then BotScanConn:Disconnect(); BotScanConn = nil end
    for model in pairs(BotObjects) do cleanupBotESP(model) end
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local h = obj:FindFirstChild("BotHighlight"); if h then h:Destroy() end
        end
    end)
end

-- ══════════════════════════════════════════
--              LIGHTING
-- ══════════════════════════════════════════

local Lighting = game:GetService("Lighting")
local OrigLighting = {
    Brightness     = Lighting.Brightness,
    GlobalShadows  = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient        = Lighting.Ambient,
    FogEnd         = Lighting.FogEnd,
    FogStart       = Lighting.FogStart,
    AtmDensity     = (function()
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        return atm and atm.Density or 0.3
    end)(),
}

local function getLightingFX(class)
    return Lighting:FindFirstChildOfClass(class)
end

for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("ColorCorrectionEffect") and v.Name == "NyxCC" then v:Destroy() end
end
local CC = Instance.new("ColorCorrectionEffect")
CC.Name = "NyxCC"; CC.Parent = Lighting

local CCState = { Contrast=0, Saturation=0, Brightness=0, TintColor=Color3.fromRGB(255,255,255) }
local FourKActive = false
local origFX = {}

-- ══════════════════════════════════════════
--   RENDER LOOP (Aimbot / FOV / Crosshair)
-- ══════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    local cx, cy = vp.X*0.5, vp.Y*0.5
    _center2 = Vector2.new(cx, cy)

    -- Player aimbot FOV
    if AB.Enabled and AB.FOVEnabled then
        AimFOVCircle.Visible=true; AimFOVCircle.Position=Vector2.new(cx,cy)
        AimFOVCircle.Radius=AB.FOVSize; AimFOVCircle.Color=AB.FOVColor; AimFOVCircle.Thickness=AB.FOVThickness
        if AB.FOVFilled then
            AimFOVFill.Visible=true; AimFOVFill.Position=Vector2.new(cx,cy)
            AimFOVFill.Radius=AB.FOVSize; AimFOVFill.Color=AB.FOVColor; AimFOVFill.Transparency=AB.FOVFilledTransparency
        else AimFOVFill.Visible=false end
    else AimFOVCircle.Visible=false; AimFOVFill.Visible=false end

    -- Bot aimbot FOV
    if BOTAB.Enabled and BOTAB.FOVEnabled then
        BotAimFOVCircle.Visible=true; BotAimFOVCircle.Position=Vector2.new(cx,cy)
        BotAimFOVCircle.Radius=BOTAB.FOVSize; BotAimFOVCircle.Color=BOTAB.FOVColor; BotAimFOVCircle.Thickness=BOTAB.FOVThickness
        if BOTAB.FOVFilled then
            BotAimFOVFill.Visible=true; BotAimFOVFill.Position=Vector2.new(cx,cy)
            BotAimFOVFill.Radius=BOTAB.FOVSize; BotAimFOVFill.Color=BOTAB.FOVColor; BotAimFOVFill.Transparency=BOTAB.FOVFilledTransparency
        else BotAimFOVFill.Visible=false end
    else BotAimFOVCircle.Visible=false; BotAimFOVFill.Visible=false end

    drawCH(cx, cy)

    -- Player Aimbot — target lock sistemi
    if AB.Enabled and AB_Active then
        -- Mevcut lock geçerli mi kontrol et
        if lockedTarget then
            local hum = lockedTarget.Parent and lockedTarget.Parent:FindFirstChildOfClass("Humanoid")
            local dist = screenDist(lockedTarget)
            if not hum or hum.Health <= 0 or not dist or dist > AB.FOVSize then
                lockedTarget = nil
            end
        end
        if not lockedTarget then lockedTarget = pickBestPlayer(AB.FOVSize) end
        if lockedTarget then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, lockedTarget.Position), AB.Smoothness)
        end
    else
        lockedTarget = nil
    end

    -- Bot Aimbot — FİX + target lock sistemi
    if BOTAB.Enabled and BotAB_Active then
        -- Mevcut bot lock geçerli mi?
        if lockedBotTarget then
            local hum = lockedBotTarget.Parent and lockedBotTarget.Parent:FindFirstChildOfClass("Humanoid")
            local dist = screenDist(lockedBotTarget)
            if not hum or hum.Health <= 0 or not dist or dist > BOTAB.FOVSize then
                lockedBotTarget = nil
            end
        end
        -- Bot scan aktif değilse otomatik başlat
        if not BotScanConn then startBotScan() end
        if not lockedBotTarget then lockedBotTarget = pickBestBot(BOTAB.FOVSize) end
        if lockedBotTarget then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, lockedBotTarget.Position), BOTAB.Smoothness)
        end
    else
        lockedBotTarget = nil
    end
end)

-- ══════════════════════════════════════════
--   BOT ESP LOOP — geliştirilmiş versiyon
-- ══════════════════════════════════════════

-- ══════════════════════════════════════════
--   BOT ESP LOOP — flickering fix
--   RenderStepped kullanılıyor (Heartbeat değil)
--   Throttling kaldırıldı — her frame güncellenir
--   svs() helper yukarıda tanımlı (satır ~306)
-- ══════════════════════════════════════════

local function hideAllBotDrawings(d)
    svs(d.top, false); svs(d.bottom, false)
    svs(d.left, false); svs(d.right, false)
    svs(d.fill, false); svs(d.hBG, false); svs(d.hBar, false)
    svs(d.hText, false); svs(d.name, false)
    svs(d.dist, false); svs(d.tracer, false)
    svs(d.arrow, false); svs(d.arrowL, false); svs(d.arrowR, false)
    if d.bones then for _, b in ipairs(d.bones) do svs(b, false) end end
end

RunService.RenderStepped:Connect(function()
    if not BOT.Enabled then
        for _, d in pairs(BotObjects) do hideAllBotDrawings(d) end
        return
    end

    local cam    = workspace.CurrentCamera
    local vp     = cam.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local lChar  = LocalPlayer.Character
    local lRoot  = lChar and lChar:FindFirstChild("HumanoidRootPart")
    local lPos   = lRoot and lRoot.Position

    for model, d in pairs(BotObjects) do
        pcall(function()
            local hum = d._hum
            local rt  = d._root

            if not model.Parent or not rt.Parent then cleanupBotESP(model); return end

            -- Ölü / uzak botları gizle
            if hum.Health <= 0 then hideAllBotDrawings(d); return end

            local dist = lPos and (rt.Position - lPos).Magnitude or 999999
            if dist > BOT.MaxDistance then hideAllBotDrawings(d); return end

            local rp, onScreen = cam:WorldToViewportPoint(rt.Position)

            -- OFF-SCREEN ARROW
            if BOT.OffScreen and not onScreen then
                local screenCenter = Vector2.new(cx, cy)
                local dir = Vector2.new(rp.X, rp.Y) - screenCenter
                if dir.Magnitude > 0 then dir = dir.Unit end
                local arrowDist = math.min(vp.X, vp.Y) * 0.42
                local arrowPos  = screenCenter + dir * arrowDist
                local arrowTip  = arrowPos + dir * BOT.OffScreenSize
                local perp      = Vector2.new(-dir.Y, dir.X)

                d.arrow.From      = arrowPos - dir * BOT.OffScreenSize
                d.arrow.To        = arrowTip
                d.arrow.Color     = BOT.OffScreenColor
                d.arrow.Thickness = BOT.BoxThickness
                svs(d.arrow, true)

                d.arrowL.From      = arrowTip
                d.arrowL.To        = arrowTip - dir * 8 + perp * 5
                d.arrowL.Color     = BOT.OffScreenColor
                d.arrowL.Thickness = BOT.BoxThickness
                svs(d.arrowL, true)

                d.arrowR.From      = arrowTip
                d.arrowR.To        = arrowTip - dir * 8 - perp * 5
                d.arrowR.Color     = BOT.OffScreenColor
                d.arrowR.Thickness = BOT.BoxThickness
                svs(d.arrowR, true)

                -- Diğer çizimleri gizle
                svs(d.top, false); svs(d.bottom, false)
                svs(d.left, false); svs(d.right, false)
                svs(d.fill, false); svs(d.hBG, false); svs(d.hBar, false)
                svs(d.hText, false); svs(d.name, false)
                svs(d.dist, false); svs(d.tracer, false)
                if d.bones then for _, b in ipairs(d.bones) do svs(b, false) end end
                return
            else
                svs(d.arrow, false); svs(d.arrowL, false); svs(d.arrowR, false)
            end

            if not onScreen then hideAllBotDrawings(d); return end

            -- Highlight (sadece state farklıysa değiştir)
            if BOT.Highlight then
                if not model:FindFirstChild("BotHighlight") then applyBotHighlight(model) end
            else
                local h = model:FindFirstChild("BotHighlight"); if h then h:Destroy() end
            end

            -- Box koordinatları
            local hp2 = cam:WorldToViewportPoint(rt.Position + Vector3.new(0,2.5,0))
            local lp2 = cam:WorldToViewportPoint(rt.Position - Vector3.new(0,3,0))
            local h2  = math.abs(hp2.Y - lp2.Y)
            local w2  = h2 / 2
            local rx, hy, ly = rp.X, hp2.Y, lp2.Y

            -- Box
            if BOT.Box then
                d.top.From=Vector2.new(rx-(w2/2),hy);    d.top.To=Vector2.new(rx+(w2/2),hy)
                d.bottom.From=Vector2.new(rx-(w2/2),ly); d.bottom.To=Vector2.new(rx+(w2/2),ly)
                d.left.From=Vector2.new(rx-(w2/2),hy);   d.left.To=Vector2.new(rx-(w2/2),ly)
                d.right.From=Vector2.new(rx+(w2/2),hy);  d.right.To=Vector2.new(rx+(w2/2),ly)
                d.top.Color=BOT.BoxColor;    d.bottom.Color=BOT.BoxColor
                d.left.Color=BOT.BoxColor;   d.right.Color=BOT.BoxColor
                d.top.Thickness=BOT.BoxThickness;    d.bottom.Thickness=BOT.BoxThickness
                d.left.Thickness=BOT.BoxThickness;   d.right.Thickness=BOT.BoxThickness
                svs(d.top, true); svs(d.bottom, true)
                svs(d.left, true); svs(d.right, true)
            else
                svs(d.top, false); svs(d.bottom, false)
                svs(d.left, false); svs(d.right, false)
            end

            -- Box Fill
            if BOT.BoxFill then
                d.fill.Size=Vector2.new(w2,h2); d.fill.Position=Vector2.new(rx-(w2/2),hy)
                d.fill.Color=BOT.BoxColor; svs(d.fill, true)
            else svs(d.fill, false) end

            -- Health Bar
            local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
            local bt  = BOT.HealthBarThickness
            if BOT.HealthBar then
                d.hBG.Size=Vector2.new(bt,h2)
                d.hBG.Position=Vector2.new((rx-(w2/2)-bt)-2, hy)
                svs(d.hBG, true)
                d.hBar.Size=Vector2.new(bt, math.max(h2*pct,1))
                d.hBar.Position=Vector2.new((rx-(w2/2)-bt)-2, ly-h2*pct)
                d.hBar.Color = BOT.HealthBarGradient
                    and Color3.fromRGB(math.floor((1-pct)*255), math.floor(pct*255), 0)
                    or Color3.fromRGB(0,255,0)
                svs(d.hBar, true)
            else svs(d.hBG, false); svs(d.hBar, false) end

            -- Name
            d.name.Text     = model.Name
            d.name.Position = Vector2.new(rx, hy-18)
            d.name.Color    = BOT.NameColor
            d.name.Size     = BOT.NameSize
            svs(d.name, BOT.ShowName)

            -- Health Text
            d.hText.Text     = BOT.HealthTextPercent and (math.floor(pct*100).."%") or tostring(math.floor(hum.Health))
            d.hText.Position = Vector2.new(rx, hy-34)
            d.hText.Color    = BOT.HealthTextColor
            d.hText.Size     = BOT.HealthTextSize
            svs(d.hText, BOT.HealthText)

            -- Distance
            d.dist.Text     = math.floor(dist).." studs"
            d.dist.Position = Vector2.new(rx, ly+5)
            d.dist.Color    = BOT.DistanceColor
            d.dist.Size     = BOT.DistanceSize
            svs(d.dist, BOT.Distance)

            -- Tracer
            d.tracer.From        = Vector2.new(cx, vp.Y)
            d.tracer.To          = Vector2.new(rx, ly)
            d.tracer.Color       = BOT.TracersColor
            d.tracer.Thickness   = BOT.TracersThickness
            d.tracer.Transparency= BOT.TracersTransparency
            svs(d.tracer, BOT.Tracers)

            -- Skeleton
            if BOT.Skeleton then
                for i, pair in ipairs(BOT_SKELETON_PARTS) do
                    local p1 = model:FindFirstChild(pair[1])
                    local p2 = model:FindFirstChild(pair[2])
                    if p1 and p2 and d.bones[i] then
                        local sp1, on1 = cam:WorldToViewportPoint(p1.Position)
                        local sp2, on2 = cam:WorldToViewportPoint(p2.Position)
                        if on1 and on2 then
                            d.bones[i].From      = Vector2.new(sp1.X, sp1.Y)
                            d.bones[i].To        = Vector2.new(sp2.X, sp2.Y)
                            d.bones[i].Color     = BOT.SkeletonColor
                            d.bones[i].Thickness = BOT.SkeletonThickness
                            svs(d.bones[i], true)
                        else
                            svs(d.bones[i], false)
                        end
                    elseif d.bones[i] then
                        svs(d.bones[i], false)
                    end
                end
            else
                if d.bones then for _, b in ipairs(d.bones) do svs(b, false) end end
            end
        end)
    end
end)

-- ══════════════════════════════════════════
--              PLAYER EVENTS
-- ══════════════════════════════════════════

Players.PlayerAdded:Connect(function(p) createESP(p) end)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then cleanupCharESP(p.Character) end
end)
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

-- ══════════════════════════════════════════
--              RAYFIELD UI
-- ══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "NyxDevs | Project Delta",
    LoadingTitle = "NyxDevs | Project Delta",
    LoadingSubtitle = "V1.1",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ── NyxInfo Tab ──────────────────────────
local NyxInfoTab = Window:CreateTab("NyxInfo", 4483362458)
NyxInfoTab:CreateSection("Script Information")
NyxInfoTab:CreateLabel("Script Name: NyxPJD")
NyxInfoTab:CreateLabel("Version: V1.1 (Fixed)")
NyxInfoTab:CreateLabel("Last Update: 01.03.2026")
NyxInfoTab:CreateLabel("Join Discord!!")
NyxInfoTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/hz9sq2jg3t")
        Rayfield:Notify({Title="Copied!", Content="Discord link copied to clipboard.", Duration=3})
    end,
})

-- ── Visual Tab ───────────────────────────
local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({Name="Enable ESP", CurrentValue=false, Flag="ESPEnable", Callback=function(v)
    ESP.Enabled = v
    if v then applyESPToAll() else cleanupAllESP() end
end})

VisualTab:CreateSection("Highlight")
VisualTab:CreateToggle({Name="Highlight", CurrentValue=false, Flag="Highlight", Callback=function(v)
    ESP.Highlight = v
    if v and ESP.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then applyHighlight(p.Character) end
        end
    elseif not v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then local h=p.Character:FindFirstChild("NyxHL"); if h then h:Destroy() end end
        end
    end
end})
VisualTab:CreateSlider({Name="Highlight Transparency", Range={1,10}, Increment=1, CurrentValue=5, Flag="HighlightTransparency", Callback=function(v)
    ESP.HighlightTransparency = v/10
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then local h=p.Character:FindFirstChild("NyxHL"); if h then h.FillTransparency=v/10 end end
    end
end})
VisualTab:CreateColorPicker({Name="Highlight Color", Color=Color3.fromRGB(0,0,255), Flag="HighlightColor", Callback=function(v)
    ESP.HighlightColor = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then local h=p.Character:FindFirstChild("NyxHL"); if h then h.FillColor=v end end
    end
end})

VisualTab:CreateSection("Box")
VisualTab:CreateToggle({Name="Box ESP", CurrentValue=false, Flag="Box", Callback=function(v) ESP.Box=v end})
VisualTab:CreateToggle({Name="Box Fill", CurrentValue=false, Flag="BoxFill", Callback=function(v) ESP.BoxFill=v end})
VisualTab:CreateSlider({Name="Box Thickness", Range={1,5}, Increment=1, CurrentValue=2, Flag="BoxThickness", Callback=function(v) ESP.BoxThickness=v end})
VisualTab:CreateColorPicker({Name="Box Color", Color=Color3.fromRGB(255,255,255), Flag="BoxColor", Callback=function(v) ESP.BoxColor=v end})

VisualTab:CreateSection("Health Bar")
VisualTab:CreateToggle({Name="Health Bar", CurrentValue=false, Flag="HealthBar", Callback=function(v) ESP.HealthBar=v end})
VisualTab:CreateToggle({Name="Health Gradient", CurrentValue=true, Flag="HealthGradient", Callback=function(v) ESP.HealthBarGradient=v end})
VisualTab:CreateSlider({Name="Bar Thickness", Range={1,10}, Increment=1, CurrentValue=2, Flag="HealthBarThickness", Callback=function(v) ESP.HealthBarThickness=v end})

VisualTab:CreateSection("Health Text")
VisualTab:CreateToggle({Name="Health Text", CurrentValue=false, Flag="HealthText", Callback=function(v) ESP.HealthText=v end})
VisualTab:CreateToggle({Name="Show as Percent", CurrentValue=false, Flag="HealthTextPercent", Callback=function(v) ESP.HealthTextPercent=v end})
VisualTab:CreateColorPicker({Name="Text Color", Color=Color3.fromRGB(255,255,255), Flag="HealthTextColor", Callback=function(v) ESP.HealthTextColor=v end})
VisualTab:CreateSlider({Name="Text Size", Range={8,36}, Increment=1, CurrentValue=16, Flag="HealthTextSize", Callback=function(v) ESP.HealthTextSize=v end})

VisualTab:CreateSection("Name")
VisualTab:CreateToggle({Name="Name ESP", CurrentValue=false, Flag="NameESP", Callback=function(v) ESP.ShowName=v end})
VisualTab:CreateToggle({Name="Show Display Name", CurrentValue=true, Flag="ShowDisplayName", Callback=function(v) ESP.ShowDisplayName=v end})
VisualTab:CreateColorPicker({Name="Text Color", Color=Color3.fromRGB(255,255,255), Flag="NameColor", Callback=function(v) ESP.NameColor=v end})
VisualTab:CreateSlider({Name="Text Size", Range={8,36}, Increment=1, CurrentValue=16, Flag="NameSize", Callback=function(v) ESP.NameSize=v end})

VisualTab:CreateSection("Distance")
VisualTab:CreateToggle({Name="Distance", CurrentValue=false, Flag="Distance", Callback=function(v) ESP.Distance=v end})
VisualTab:CreateSlider({Name="Max Distance", Range={100,5000}, Increment=50, CurrentValue=1000, Flag="MaxDistance", Callback=function(v) ESP.MaxDistance=v end})
VisualTab:CreateColorPicker({Name="Text Color", Color=Color3.fromRGB(255,255,255), Flag="DistanceColor", Callback=function(v) ESP.DistanceColor=v end})
VisualTab:CreateSlider({Name="Text Size", Range={8,36}, Increment=1, CurrentValue=16, Flag="DistanceSize", Callback=function(v) ESP.DistanceSize=v end})

VisualTab:CreateSection("Tracers")
VisualTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="Tracers", Callback=function(v) ESP.Tracers=v end})
VisualTab:CreateSlider({Name="Thickness", Range={1,10}, Increment=1, CurrentValue=1, Flag="TracersThickness", Callback=function(v) ESP.TracersThickness=v end})
VisualTab:CreateSlider({Name="Transparency", Range={0,10}, Increment=1, CurrentValue=10, Flag="TracersTransparency", Callback=function(v) ESP.TracersTransparency=v/10 end})
VisualTab:CreateColorPicker({Name="Color", Color=Color3.fromRGB(255,255,255), Flag="TracersColor", Callback=function(v) ESP.TracersColor=v end})

VisualTab:CreateSection("Look Direction")
VisualTab:CreateToggle({Name="Look Direction", CurrentValue=false, Flag="LookDirection", Callback=function(v) ESP.LookDirection=v end})
VisualTab:CreateToggle({Name="Show Arrow", CurrentValue=true, Flag="ShowArrow", Callback=function(v) ESP.ShowArrow=v end})
VisualTab:CreateSlider({Name="Thickness", Range={1,10}, Increment=1, CurrentValue=2, Flag="LookDirectionThickness", Callback=function(v) ESP.LookDirectionThickness=v end})
VisualTab:CreateColorPicker({Name="Color", Color=Color3.fromRGB(255,0,0), Flag="LookDirectionColor", Callback=function(v) ESP.LookDirectionColor=v end})

VisualTab:CreateSection("Item ESP")
VisualTab:CreateToggle({Name="Item ESP", CurrentValue=false, Flag="ItemESP", Callback=function(v)
    ESP.ItemESP = v
    if v then scanForLoot()
    else removeDrawings(ItemDrawings); ItemDrawings = {} end
end})
VisualTab:CreateToggle({Name="Show Item Distance", CurrentValue=true, Flag="ShowItemDist", Callback=function(v) ESP.ShowItemDistance=v end})
VisualTab:CreateSlider({Name="Item Max Distance", Range={100,1000}, Increment=50, CurrentValue=500, Flag="ItemMaxDist", Callback=function(v) ESP.ItemMaxDistance=v end})
VisualTab:CreateSlider({Name="Item Text Size", Range={8,30}, Increment=1, CurrentValue=14, Flag="ItemTextSize", Callback=function(v) ESP.ItemTextSize=v end})
VisualTab:CreateColorPicker({Name="Rare Color", Color=Color3.fromRGB(255,215,0), Flag="RareLootColor", Callback=function(v) ESP.RareLootColor=v end})
VisualTab:CreateColorPicker({Name="Common Color", Color=Color3.fromRGB(255,255,255), Flag="CommonLootColor", Callback=function(v) ESP.CommonLootColor=v end})

VisualTab:CreateSection("Loot Box ESP")
VisualTab:CreateToggle({Name="Loot Box ESP", CurrentValue=false, Flag="LootBoxESP", Callback=function(v)
    ESP.LootBoxESP = v
    if v then scanForLoot()
    else removeDrawings(LootBoxDrawings); LootBoxDrawings = {} end
end})

-- ── Aimbot Tab ───────────────────────────
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)

AimbotTab:CreateSection("Aimbot")
AimbotTab:CreateToggle({Name="Aimbot Enable", CurrentValue=false, Flag="AimbotEnable", Callback=function(v)
    AB.Enabled = v
    if not v then lockedTarget=nil; AB_Active=false end
end})
AimbotTab:CreateSlider({Name="Smoothness", Range={1,10}, Increment=1, CurrentValue=2, Flag="AimbotSmooth", Callback=function(v) AB.Smoothness=v/10 end})
AimbotTab:CreateDropdown({Name="Aim Key", Options={"RightMouseButton","LeftMouseButton","E","Q","F","Z","X","C","V","LeftShift","LeftControl","LeftAlt"}, CurrentOption={"RightMouseButton"}, Flag="AimbotKey", Callback=function(v)
    local m={RightMouseButton=Enum.UserInputType.MouseButton2,LeftMouseButton=Enum.UserInputType.MouseButton1,E=Enum.KeyCode.E,Q=Enum.KeyCode.Q,F=Enum.KeyCode.F,Z=Enum.KeyCode.Z,X=Enum.KeyCode.X,C=Enum.KeyCode.C,V=Enum.KeyCode.V,LeftShift=Enum.KeyCode.LeftShift,LeftControl=Enum.KeyCode.LeftControl,LeftAlt=Enum.KeyCode.LeftAlt}
    AB._KeyName = v[1]; AB.AimKey = m[v[1]] or Enum.UserInputType.MouseButton2
end})
AimbotTab:CreateDropdown({Name="Body Part", Options={"Head","UpperTorso"}, CurrentOption={"Head"}, Flag="AimbotBodyPart", Callback=function(v) AB.BodyPart=v[1] end})
AimbotTab:CreateDropdown({Name="Aim Mode", Options={"Hold","Toggle"}, CurrentOption={"Hold"}, Flag="AimbotMode", Callback=function(v) AB.AimMode=v[1]; AB_Active=false; lockedTarget=nil end})

AimbotTab:CreateSection("FOV")
AimbotTab:CreateToggle({Name="FOV Enable", CurrentValue=false, Flag="AimFOVEnable", Callback=function(v) AB.FOVEnabled=v end})
AimbotTab:CreateSlider({Name="FOV Size", Range={10,600}, Increment=1, CurrentValue=100, Flag="AimFOVSize", Callback=function(v) AB.FOVSize=v end})
AimbotTab:CreateSlider({Name="FOV Thickness", Range={1,10}, Increment=1, CurrentValue=1, Flag="AimFOVThick", Callback=function(v) AB.FOVThickness=v; AimFOVCircle.Thickness=v end})
AimbotTab:CreateToggle({Name="FOV Filled", CurrentValue=false, Flag="AimFOVFilled", Callback=function(v) AB.FOVFilled=v end})
AimbotTab:CreateSlider({Name="Filled Transparency", Range={0,10}, Increment=1, CurrentValue=8, Flag="AimFOVFillTrans", Callback=function(v) AB.FOVFilledTransparency=v/10; AimFOVFill.Transparency=v/10 end})
AimbotTab:CreateColorPicker({Name="FOV Color", Color=Color3.fromRGB(255,255,255), Flag="AimFOVColor", Callback=function(v) AB.FOVColor=v; AimFOVCircle.Color=v; AimFOVFill.Color=v end})

AimbotTab:CreateSection("Crosshair")
AimbotTab:CreateToggle({Name="Crosshair Enable", CurrentValue=false, Flag="CHEnable", Callback=function(v) AB.CrosshairEnabled=v; if not v then hideCH() end end})
AimbotTab:CreateDropdown({Name="Style", Options={"Cross","Dot","Circle","Dynamic"}, CurrentOption={"Cross"}, Flag="CHStyle", Callback=function(v) AB.CrosshairStyle=v[1] end})
AimbotTab:CreateSlider({Name="Size", Range={2,50}, Increment=1, CurrentValue=10, Flag="CHSize", Callback=function(v) AB.CrosshairSize=v end})
AimbotTab:CreateSlider({Name="Thickness", Range={1,10}, Increment=1, CurrentValue=1, Flag="CHThickness", Callback=function(v) AB.CrosshairThickness=v end})
AimbotTab:CreateSlider({Name="Gap", Range={0,20}, Increment=1, CurrentValue=4, Flag="CHGap", Callback=function(v) AB.CrosshairGap=v end})
AimbotTab:CreateColorPicker({Name="Color", Color=Color3.fromRGB(255,255,255), Flag="CHColor", Callback=function(v) AB.CrosshairColor=v end})
AimbotTab:CreateToggle({Name="Outline", CurrentValue=true, Flag="CHOutline", Callback=function(v) AB.CrosshairOutline=v end})
AimbotTab:CreateColorPicker({Name="Outline Color", Color=Color3.fromRGB(0,0,0), Flag="CHOutlineColor", Callback=function(v) AB.CrosshairOutlineColor=v end})
AimbotTab:CreateSlider({Name="Opacity", Range={0,10}, Increment=1, CurrentValue=10, Flag="CHOpacity", Callback=function(v) AB.CrosshairOpacity=v/10 end})

-- ── Bot Visual Tab ───────────────────────
local BotVisualTab = Window:CreateTab("Bot Visual", 4483362458)

BotVisualTab:CreateSection("ESP")
BotVisualTab:CreateToggle({Name="Enable Bot ESP", CurrentValue=false, Flag="BotESPEnable", Callback=function(v)
    BOT.Enabled = v
    if v then startBotScan() else stopBotScan() end
end})

BotVisualTab:CreateSection("Highlight")
BotVisualTab:CreateToggle({Name="Highlight", CurrentValue=false, Flag="BotHighlight", Callback=function(v)
    BOT.Highlight = v
    if v and BOT.Enabled then
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and isNPC(obj) then applyBotHighlight(obj) end
            end
        end)
    elseif not v then
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                local h = obj:FindFirstChild("BotHighlight"); if h then h:Destroy() end
            end
        end)
    end
end})
BotVisualTab:CreateSlider({Name="Highlight Transparency", Range={1,10}, Increment=1, CurrentValue=5, Flag="BotHighlightTransparency", Callback=function(v)
    BOT.HighlightTransparency = v/10
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local h = obj:FindFirstChild("BotHighlight"); if h then h.FillTransparency=v/10 end
        end
    end)
end})
BotVisualTab:CreateColorPicker({Name="Highlight Color", Color=Color3.fromRGB(255,80,80), Flag="BotHighlightColor", Callback=function(v) BOT.HighlightColor=v end})

BotVisualTab:CreateSection("Box")
BotVisualTab:CreateToggle({Name="Box ESP", CurrentValue=false, Flag="BotBox", Callback=function(v) BOT.Box=v end})
BotVisualTab:CreateToggle({Name="Box Fill", CurrentValue=false, Flag="BotBoxFill", Callback=function(v) BOT.BoxFill=v end})
BotVisualTab:CreateSlider({Name="Box Thickness", Range={1,5}, Increment=1, CurrentValue=2, Flag="BotBoxThickness", Callback=function(v)
    BOT.BoxThickness=v
    for _, d in pairs(BotObjects) do
        for _, key in ipairs({"top","bottom","left","right"}) do if d[key] then d[key].Thickness=v end end
    end
end})
BotVisualTab:CreateColorPicker({Name="Box Color", Color=Color3.fromRGB(255,80,80), Flag="BotBoxColor", Callback=function(v) BOT.BoxColor=v end})

BotVisualTab:CreateSection("Skeleton")
BotVisualTab:CreateToggle({Name="Skeleton", CurrentValue=false, Flag="BotSkeleton", Callback=function(v) BOT.Skeleton=v end})
BotVisualTab:CreateSlider({Name="Skeleton Thickness", Range={1,5}, Increment=1, CurrentValue=1, Flag="BotSkeletonThickness", Callback=function(v) BOT.SkeletonThickness=v end})
BotVisualTab:CreateColorPicker({Name="Skeleton Color", Color=Color3.fromRGB(255,100,0), Flag="BotSkeletonColor", Callback=function(v) BOT.SkeletonColor=v end})

BotVisualTab:CreateSection("Health Bar")
BotVisualTab:CreateToggle({Name="Health Bar", CurrentValue=false, Flag="BotHealthBar", Callback=function(v) BOT.HealthBar=v end})
BotVisualTab:CreateToggle({Name="Health Gradient", CurrentValue=true, Flag="BotHealthGradient", Callback=function(v) BOT.HealthBarGradient=v end})
BotVisualTab:CreateSlider({Name="Bar Thickness", Range={1,10}, Increment=1, CurrentValue=2, Flag="BotHealthBarThickness", Callback=function(v) BOT.HealthBarThickness=v end})

BotVisualTab:CreateSection("Health Text")
BotVisualTab:CreateToggle({Name="Health Text", CurrentValue=false, Flag="BotHealthText", Callback=function(v) BOT.HealthText=v end})
BotVisualTab:CreateToggle({Name="Show as Percent", CurrentValue=false, Flag="BotHealthTextPercent", Callback=function(v) BOT.HealthTextPercent=v end})
BotVisualTab:CreateColorPicker({Name="Text Color", Color=Color3.fromRGB(255,255,255), Flag="BotHealthTextColor", Callback=function(v) BOT.HealthTextColor=v end})
BotVisualTab:CreateSlider({Name="Text Size", Range={8,36}, Increment=1, CurrentValue=16, Flag="BotHealthTextSize", Callback=function(v) BOT.HealthTextSize=v end})

BotVisualTab:CreateSection("Name")
BotVisualTab:CreateToggle({Name="Name ESP", CurrentValue=false, Flag="BotName", Callback=function(v) BOT.ShowName=v end})
BotVisualTab:CreateColorPicker({Name="Text Color", Color=Color3.fromRGB(255,80,80), Flag="BotNameColor", Callback=function(v) BOT.NameColor=v end})
BotVisualTab:CreateSlider({Name="Text Size", Range={8,36}, Increment=1, CurrentValue=16, Flag="BotNameSize", Callback=function(v) BOT.NameSize=v end})

BotVisualTab:CreateSection("Distance")
BotVisualTab:CreateToggle({Name="Distance", CurrentValue=false, Flag="BotDistance", Callback=function(v) BOT.Distance=v end})
BotVisualTab:CreateSlider({Name="Max Distance", Range={100,5000}, Increment=50, CurrentValue=1000, Flag="BotMaxDistance", Callback=function(v) BOT.MaxDistance=v end})
BotVisualTab:CreateColorPicker({Name="Text Color", Color=Color3.fromRGB(255,255,255), Flag="BotDistanceColor", Callback=function(v) BOT.DistanceColor=v end})
BotVisualTab:CreateSlider({Name="Text Size", Range={8,36}, Increment=1, CurrentValue=16, Flag="BotDistanceSize", Callback=function(v) BOT.DistanceSize=v end})

BotVisualTab:CreateSection("Tracers")
BotVisualTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="BotTracers", Callback=function(v) BOT.Tracers=v end})
BotVisualTab:CreateSlider({Name="Thickness", Range={1,10}, Increment=1, CurrentValue=1, Flag="BotTracersThickness", Callback=function(v) BOT.TracersThickness=v end})
BotVisualTab:CreateSlider({Name="Transparency", Range={0,10}, Increment=1, CurrentValue=10, Flag="BotTracersTransparency", Callback=function(v) BOT.TracersTransparency=v/10 end})
BotVisualTab:CreateColorPicker({Name="Color", Color=Color3.fromRGB(255,80,80), Flag="BotTracersColor", Callback=function(v) BOT.TracersColor=v end})

BotVisualTab:CreateSection("Off-Screen Indicator")
BotVisualTab:CreateToggle({Name="Off-Screen Arrow", CurrentValue=false, Flag="BotOffScreen", Callback=function(v) BOT.OffScreen=v end})
BotVisualTab:CreateSlider({Name="Arrow Size", Range={5,40}, Increment=1, CurrentValue=15, Flag="BotOffScreenSize", Callback=function(v) BOT.OffScreenSize=v end})
BotVisualTab:CreateColorPicker({Name="Arrow Color", Color=Color3.fromRGB(255,80,80), Flag="BotOffScreenColor", Callback=function(v) BOT.OffScreenColor=v end})

-- ── Bot Aimbot Tab ───────────────────────
local BotAimbotTab = Window:CreateTab("Bot Aimbot", 4483362458)

BotAimbotTab:CreateSection("Aimbot")
BotAimbotTab:CreateToggle({Name="Bot Aimbot Enable", CurrentValue=false, Flag="BotAimbotEnable", Callback=function(v)
    BOTAB.Enabled = v
    if not v then BotAB_Active=false; lockedBotTarget=nil end
    -- Bot Aimbot açıldığında otomatik scan başlatır
    if v and not BotScanConn then startBotScan() end
end})
BotAimbotTab:CreateSlider({Name="Smoothness", Range={1,10}, Increment=1, CurrentValue=2, Flag="BotAimbotSmooth", Callback=function(v) BOTAB.Smoothness=v/10 end})
BotAimbotTab:CreateDropdown({Name="Aim Key", Options={"RightMouseButton","LeftMouseButton","E","Q","F","Z","X","C","V","LeftShift","LeftControl","LeftAlt"}, CurrentOption={"RightMouseButton"}, Flag="BotAimbotKey", Callback=function(v)
    local m={RightMouseButton=Enum.UserInputType.MouseButton2,LeftMouseButton=Enum.UserInputType.MouseButton1,E=Enum.KeyCode.E,Q=Enum.KeyCode.Q,F=Enum.KeyCode.F,Z=Enum.KeyCode.Z,X=Enum.KeyCode.X,C=Enum.KeyCode.C,V=Enum.KeyCode.V,LeftShift=Enum.KeyCode.LeftShift,LeftControl=Enum.KeyCode.LeftControl,LeftAlt=Enum.KeyCode.LeftAlt}
    BOTAB._KeyName = v[1]; BOTAB.AimKey = m[v[1]] or Enum.UserInputType.MouseButton2
end})
BotAimbotTab:CreateDropdown({Name="Body Part", Options={"Head","UpperTorso"}, CurrentOption={"Head"}, Flag="BotAimbotBodyPart", Callback=function(v) BOTAB.BodyPart=v[1] end})
BotAimbotTab:CreateDropdown({Name="Aim Mode", Options={"Hold","Toggle"}, CurrentOption={"Hold"}, Flag="BotAimbotMode", Callback=function(v) BOTAB.AimMode=v[1]; BotAB_Active=false; lockedBotTarget=nil end})

BotAimbotTab:CreateSection("FOV")
BotAimbotTab:CreateToggle({Name="FOV Enable", CurrentValue=false, Flag="BotAimFOVEnable", Callback=function(v) BOTAB.FOVEnabled=v end})
BotAimbotTab:CreateSlider({Name="FOV Size", Range={10,600}, Increment=1, CurrentValue=100, Flag="BotAimFOVSize", Callback=function(v) BOTAB.FOVSize=v end})
BotAimbotTab:CreateSlider({Name="FOV Thickness", Range={1,10}, Increment=1, CurrentValue=1, Flag="BotAimFOVThick", Callback=function(v) BOTAB.FOVThickness=v; BotAimFOVCircle.Thickness=v end})
BotAimbotTab:CreateToggle({Name="FOV Filled", CurrentValue=false, Flag="BotAimFOVFilled", Callback=function(v) BOTAB.FOVFilled=v end})
BotAimbotTab:CreateSlider({Name="Filled Transparency", Range={0,10}, Increment=1, CurrentValue=8, Flag="BotAimFOVFillTrans", Callback=function(v) BOTAB.FOVFilledTransparency=v/10; BotAimFOVFill.Transparency=v/10 end})
BotAimbotTab:CreateColorPicker({Name="FOV Color", Color=Color3.fromRGB(255,100,0), Flag="BotAimFOVColor", Callback=function(v) BOTAB.FOVColor=v; BotAimFOVCircle.Color=v; BotAimFOVFill.Color=v end})

-- ══════════════════════════════════════════
--              FPS BOOST
-- ══════════════════════════════════════════

local FPSBoost_Active = false
local FPSBoost_OrigSettings = {}

local function applyFPSBoost(enable)
    FPSBoost_Active = enable
    if enable then
        FPSBoost_OrigSettings.GlobalShadows  = Lighting.GlobalShadows
        FPSBoost_OrigSettings.Brightness     = Lighting.Brightness
        FPSBoost_OrigSettings.FogEnd         = Lighting.FogEnd
        FPSBoost_OrigSettings.FogStart       = Lighting.FogStart
        Lighting.GlobalShadows = false
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("BloomEffect")
            or fx:IsA("ColorCorrectionEffect") and fx.Name ~= "NyxCC" then
                FPSBoost_OrigSettings[fx] = fx.Enabled
                fx.Enabled = false
            end
        end
        local atm = getLightingFX("Atmosphere")
        if atm then
            FPSBoost_OrigSettings.AtmDensity    = atm.Density
            FPSBoost_OrigSettings.AtmHaze       = atm.Haze
            FPSBoost_OrigSettings.AtmGlare      = atm.Glare
            FPSBoost_OrigSettings.AtmOffset     = atm.Offset
            atm.Density = 0; atm.Haze = 0; atm.Glare = 0; atm.Offset = 0
        end
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        Rayfield:Notify({Title="FPS Boost", Content="FPS Boost enabled! Settings optimized.", Duration=3})
    else
        Lighting.GlobalShadows = FPSBoost_OrigSettings.GlobalShadows ~= nil and FPSBoost_OrigSettings.GlobalShadows or true
        Lighting.Brightness    = FPSBoost_OrigSettings.Brightness    or OrigLighting.Brightness
        Lighting.FogEnd        = FPSBoost_OrigSettings.FogEnd        or OrigLighting.FogEnd
        Lighting.FogStart      = FPSBoost_OrigSettings.FogStart      or OrigLighting.FogStart
        for k, v in pairs(FPSBoost_OrigSettings) do
            if type(k) == "userdata" and k:IsA("Instance") then
                pcall(function() k.Enabled = v end)
            end
        end
        local atm = getLightingFX("Atmosphere")
        if atm and FPSBoost_OrigSettings.AtmDensity ~= nil then
            atm.Density = FPSBoost_OrigSettings.AtmDensity
            atm.Haze    = FPSBoost_OrigSettings.AtmHaze
            atm.Glare   = FPSBoost_OrigSettings.AtmGlare
            atm.Offset  = FPSBoost_OrigSettings.AtmOffset
        end
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)
        FPSBoost_OrigSettings = {}
        Rayfield:Notify({Title="FPS Boost", Content="FPS Boost disabled. Settings restored.", Duration=3})
    end
end

-- ── Misc Tab ─────────────────────────────
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("FPS Boost")
MiscTab:CreateToggle({Name="FPS Boost", CurrentValue=false, Flag="FPSBoost", Callback=function(v)
    applyFPSBoost(v)
end})
MiscTab:CreateLabel("Disables shadows, atmosphere and heavy effects.")
MiscTab:CreateLabel("Recommended for maximum FPS gain.")

MiscTab:CreateSection("Fullbright")
MiscTab:CreateToggle({Name="Fullbright", CurrentValue=false, Flag="Fullbright", Callback=function(v)
    if v then
        Lighting.Brightness = 10; Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.Ambient = Color3.fromRGB(128,128,128)
    else
        Lighting.Brightness     = OrigLighting.Brightness
        Lighting.GlobalShadows  = OrigLighting.GlobalShadows
        Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient
        Lighting.Ambient        = OrigLighting.Ambient
    end
end})
MiscTab:CreateSlider({Name="Brightness", Range={1,10}, Increment=1, CurrentValue=5, Flag="BrightnessSlider", Callback=function(v)
    Lighting.Brightness = v
end})

MiscTab:CreateSection("No Fog")
MiscTab:CreateToggle({Name="No Fog", CurrentValue=false, Flag="NoFog", Callback=function(v)
    if v then
        Lighting.FogEnd = 100000; Lighting.FogStart = 100000
        local atm = getLightingFX("Atmosphere")
        if atm then atm.Density = 0 end
    else
        Lighting.FogEnd   = OrigLighting.FogEnd
        Lighting.FogStart = OrigLighting.FogStart
        local atm = getLightingFX("Atmosphere")
        if atm then atm.Density = OrigLighting.AtmDensity end
    end
end})
MiscTab:CreateSlider({Name="Fog Density", Range={1,10}, Increment=1, CurrentValue=5, Flag="FogDensity", Callback=function(v)
    local atm = getLightingFX("Atmosphere")
    if atm then atm.Density = v/10 end
    Lighting.FogEnd = 10000 / v
end})

MiscTab:CreateSection("Color Correction")
MiscTab:CreateSlider({Name="Contrast", Range={1,10}, Increment=1, CurrentValue=5, Flag="CCContrast", Callback=function(v)
    local val = (v-5)/5; CC.Contrast=val; CCState.Contrast=val
end})
MiscTab:CreateSlider({Name="Saturation", Range={1,10}, Increment=1, CurrentValue=5, Flag="CCSaturation", Callback=function(v)
    local val = (v-5)/5; CC.Saturation=val; CCState.Saturation=val
end})
MiscTab:CreateSlider({Name="Brightness", Range={1,10}, Increment=1, CurrentValue=5, Flag="CCBrightness", Callback=function(v)
    local val = (v-5)/10; CC.Brightness=val; CCState.Brightness=val
end})
MiscTab:CreateColorPicker({Name="Tint Color", Color=Color3.fromRGB(255,255,255), Flag="CCTint", Callback=function(v)
    CC.TintColor=v; CCState.TintColor=v
end})

MiscTab:CreateSection("4K Viewer")
MiscTab:CreateToggle({Name="4K Viewer", CurrentValue=false, Flag="FourKViewer", Callback=function(v)
    FourKActive = v
    if v then
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect") then
                origFX[fx] = fx.Enabled; fx.Enabled = false
            end
        end
        CC.Contrast=0.3; CC.Saturation=0.4; CC.Brightness=0.05
        Lighting.GlobalShadows = true
        local sunrays = getLightingFX("SunRaysEffect")
        if sunrays then sunrays.Enabled = true end
        local bloom = getLightingFX("BloomEffect")
        if bloom then bloom.Enabled=true; bloom.Intensity=0.3; bloom.Size=24; bloom.Threshold=0.95 end
    else
        for fx, state in pairs(origFX) do pcall(function() fx.Enabled=state end) end
        origFX = {}
        CC.Contrast   = CCState.Contrast
        CC.Saturation = CCState.Saturation
        CC.Brightness = CCState.Brightness
        CC.TintColor  = CCState.TintColor
    end
end})

-- ── Settings Tab ─────────────────────────
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- ══════════════════════════════════════════
--              WATERMARK
-- ══════════════════════════════════════════

local WM_Enabled    = false
local WM_Color      = Color3.fromRGB(255, 255, 255)
local WM_POS        = Vector2.new(10, 10)
local WM_PAD_X      = 12
local WM_PAD_Y      = 6
local WM_FONT_SIZE  = 14

local WM_BG = Drawing.new("Square")
WM_BG.Visible=false; WM_BG.Filled=true; WM_BG.Color=Color3.fromRGB(20,20,20); WM_BG.Transparency=0.45; WM_BG.Thickness=0

local WM_BORDER = Drawing.new("Square")
WM_BORDER.Visible=false; WM_BORDER.Filled=false; WM_BORDER.Color=Color3.fromRGB(80,80,80); WM_BORDER.Transparency=0.6; WM_BORDER.Thickness=1

local WM_Text = Drawing.new("Text")
WM_Text.Visible=false; WM_Text.Color=Color3.fromRGB(255,255,255); WM_Text.Size=WM_FONT_SIZE
WM_Text.Outline=false; WM_Text.Center=false; WM_Text.Font=Drawing.Fonts.UI

local WM_Dragging   = false
local WM_DragOffset = Vector2.new(0, 0)

local WM_GameName = "..."
task.spawn(function()
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then
        WM_GameName = info.Name
    else
        WM_GameName = "Unknown Game"
    end
end)

local _fpsCounter = 0
local _fpsDisplay = 0
local _fpsClock   = 0

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not WM_Enabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local mp = UserInputService:GetMouseLocation()
    local bw = WM_BG.Size and WM_BG.Size.X or 300
    local bh = WM_FONT_SIZE + WM_PAD_Y * 2
    if mp.X >= WM_POS.X and mp.X <= WM_POS.X + bw and
       mp.Y >= WM_POS.Y and mp.Y <= WM_POS.Y + bh then
        WM_Dragging   = true
        WM_DragOffset = mp - WM_POS
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        WM_Dragging = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    _fpsCounter = _fpsCounter + 1
    _fpsClock   = _fpsClock + dt
    if _fpsClock >= 0.5 then
        _fpsDisplay = math.floor(_fpsCounter / _fpsClock)
        _fpsCounter = 0; _fpsClock = 0
    end

    if WM_Dragging then
        WM_POS = UserInputService:GetMouseLocation() - WM_DragOffset
    end

    if not WM_Enabled then
        WM_BG.Visible=false; WM_BORDER.Visible=false; WM_Text.Visible=false
        return
    end

    local ping        = math.floor(LocalPlayer:GetNetworkPing() * 1000)
    local playerCount = #Players:GetPlayers()
    local segments    = { WM_GameName, playerCount.." players", ping.." ms", _fpsDisplay.." FPS" }
    local fullText    = table.concat(segments, "   |   ")

    WM_Text.Text = fullText
    local textW  = WM_Text.TextBounds.X
    local barW   = textW + WM_PAD_X * 2
    local barH   = WM_FONT_SIZE + WM_PAD_Y * 2
    local bx, by = WM_POS.X, WM_POS.Y

    WM_BG.Visible=true; WM_BG.Position=Vector2.new(bx,by); WM_BG.Size=Vector2.new(barW,barH)
    WM_BORDER.Visible=true; WM_BORDER.Position=Vector2.new(bx,by); WM_BORDER.Size=Vector2.new(barW,barH)
    WM_Text.Visible=true; WM_Text.Color=WM_Color; WM_Text.Position=Vector2.new(bx+WM_PAD_X, by+WM_PAD_Y)
end)

-- ══════════════════════════════════════════
--              ANTI-AFK
-- ══════════════════════════════════════════

local _afkIdleConn = nil
local function startAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    if _afkIdleConn then _afkIdleConn:Disconnect() end
    _afkIdleConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if _afkIdleConn then _afkIdleConn:Disconnect(); _afkIdleConn = nil end
end

-- ══════════════════════════════════════════
--              FPS UNLOCKER
-- ══════════════════════════════════════════

local FPS_Supported = type(setfpscap)=="function" or (type(syn)=="table" and type(syn.set_fps_cap)=="function")

local function unlockFPS(cap)
    if type(setfpscap) == "function" then
        setfpscap(cap)
    elseif type(syn) == "table" and type(syn.set_fps_cap) == "function" then
        syn.set_fps_cap(cap)
    else
        Rayfield:Notify({Title="FPS Unlocker", Content="This executor does not support FPS cap.", Duration=4})
    end
end

-- ═══════════════════════════════════════
--              CONFIG SİSTEMİ
-- ═══════════════════════════════════════

local CONFIG_FOLDER = "NyxPJD"
local CONFIG_EXT    = ".cfg"
local MAX_SLOTS     = 5

-- writefile/readfile/isfolder/makefolder/listfiles desteği kontrolü
local FS_OK = type(writefile)=="function" and type(readfile)=="function"
    and type(isfolder)=="function" and type(makefolder)=="function"
    and type(listfiles)=="function"

if FS_OK and not isfolder(CONFIG_FOLDER) then
    pcall(function() makefolder(CONFIG_FOLDER) end)
end

-- Color3 <-> tablo dönüşümleri
local function c3ToT(c) return {r=c.R,g=c.G,b=c.B} end
local function tToC3(t) return Color3.fromRGB(math.floor(t.r*255),math.floor(t.g*255),math.floor(t.b*255)) end

-- Rayfield flag değerlerini oku (UI'dan güncel değerleri al)
local function getRayfieldValue(flag)
    local ok, val = pcall(function()
        return Rayfield.Flags[flag] and Rayfield.Flags[flag].Value
    end)
    return ok and val or nil
end

-- Tüm ayarları tek tabloya topla (serialize)
local function buildConfigData()
    local d = {}
    -- ESP
    d.ESP = {
        Enabled=ESP.Enabled, Highlight=ESP.Highlight,
        HighlightTransparency=ESP.HighlightTransparency,
        HighlightColor=c3ToT(ESP.HighlightColor),
        Box=ESP.Box, BoxFill=ESP.BoxFill,
        BoxThickness=ESP.BoxThickness, BoxColor=c3ToT(ESP.BoxColor),
        HealthBar=ESP.HealthBar, HealthBarGradient=ESP.HealthBarGradient,
        HealthBarThickness=ESP.HealthBarThickness,
        HealthText=ESP.HealthText, HealthTextPercent=ESP.HealthTextPercent,
        HealthTextColor=c3ToT(ESP.HealthTextColor), HealthTextSize=ESP.HealthTextSize,
        ShowName=ESP.ShowName, ShowDisplayName=ESP.ShowDisplayName,
        NameColor=c3ToT(ESP.NameColor), NameSize=ESP.NameSize,
        Distance=ESP.Distance, MaxDistance=ESP.MaxDistance,
        DistanceColor=c3ToT(ESP.DistanceColor), DistanceSize=ESP.DistanceSize,
        Tracers=ESP.Tracers, TracersThickness=ESP.TracersThickness,
        TracersTransparency=ESP.TracersTransparency,
        TracersColor=c3ToT(ESP.TracersColor),
        LookDirection=ESP.LookDirection, ShowArrow=ESP.ShowArrow,
        LookDirectionThickness=ESP.LookDirectionThickness,
        LookDirectionColor=c3ToT(ESP.LookDirectionColor),
        ItemESP=ESP.ItemESP, ItemMaxDistance=ESP.ItemMaxDistance,
        ShowItemDistance=ESP.ShowItemDistance, ItemTextSize=ESP.ItemTextSize,
        RareLootColor=c3ToT(ESP.RareLootColor),
        CommonLootColor=c3ToT(ESP.CommonLootColor),
        LootBoxESP=ESP.LootBoxESP,
    }
    -- AB
    d.AB = {
        Enabled=AB.Enabled, Smoothness=AB.Smoothness,
        _KeyName=AB._KeyName, BodyPart=AB.BodyPart, AimMode=AB.AimMode,
        FOVEnabled=AB.FOVEnabled, FOVSize=AB.FOVSize,
        FOVThickness=AB.FOVThickness, FOVFilled=AB.FOVFilled,
        FOVFilledTransparency=AB.FOVFilledTransparency,
        FOVColor=c3ToT(AB.FOVColor),
        CrosshairEnabled=AB.CrosshairEnabled, CrosshairStyle=AB.CrosshairStyle,
        CrosshairSize=AB.CrosshairSize, CrosshairThickness=AB.CrosshairThickness,
        CrosshairGap=AB.CrosshairGap, CrosshairColor=c3ToT(AB.CrosshairColor),
        CrosshairOutline=AB.CrosshairOutline,
        CrosshairOutlineColor=c3ToT(AB.CrosshairOutlineColor),
        CrosshairOpacity=AB.CrosshairOpacity,
    }
    -- BOT
    d.BOT = {
        Enabled=BOT.Enabled, Box=BOT.Box, BoxFill=BOT.BoxFill,
        BoxThickness=BOT.BoxThickness, BoxColor=c3ToT(BOT.BoxColor),
        Skeleton=BOT.Skeleton, SkeletonThickness=BOT.SkeletonThickness,
        SkeletonColor=c3ToT(BOT.SkeletonColor),
        Highlight=BOT.Highlight, HighlightTransparency=BOT.HighlightTransparency,
        HighlightColor=c3ToT(BOT.HighlightColor),
        HealthBar=BOT.HealthBar, HealthBarGradient=BOT.HealthBarGradient,
        HealthBarThickness=BOT.HealthBarThickness,
        HealthText=BOT.HealthText, HealthTextPercent=BOT.HealthTextPercent,
        HealthTextColor=c3ToT(BOT.HealthTextColor), HealthTextSize=BOT.HealthTextSize,
        ShowName=BOT.ShowName, NameColor=c3ToT(BOT.NameColor), NameSize=BOT.NameSize,
        Distance=BOT.Distance, MaxDistance=BOT.MaxDistance,
        DistanceColor=c3ToT(BOT.DistanceColor), DistanceSize=BOT.DistanceSize,
        Tracers=BOT.Tracers, TracersThickness=BOT.TracersThickness,
        TracersTransparency=BOT.TracersTransparency,
        TracersColor=c3ToT(BOT.TracersColor),
        OffScreen=BOT.OffScreen, OffScreenSize=BOT.OffScreenSize,
        OffScreenColor=c3ToT(BOT.OffScreenColor),
    }
    -- BOTAB
    d.BOTAB = {
        Enabled=BOTAB.Enabled, Smoothness=BOTAB.Smoothness,
        _KeyName=BOTAB._KeyName, BodyPart=BOTAB.BodyPart, AimMode=BOTAB.AimMode,
        FOVEnabled=BOTAB.FOVEnabled, FOVSize=BOTAB.FOVSize,
        FOVThickness=BOTAB.FOVThickness, FOVFilled=BOTAB.FOVFilled,
        FOVFilledTransparency=BOTAB.FOVFilledTransparency,
        FOVColor=c3ToT(BOTAB.FOVColor),
    }
    -- Watermark & misc
    d.WM = { Enabled=WM_Enabled, Color=c3ToT(WM_Color) }
    d._version = 2
    return d
end

-- JSON encoder (basit, nested table destekli)
local function encode(val, indent)
    indent = indent or 0
    local t = type(val)
    if t == "boolean" then return val and "true" or "false"
    elseif t == "number" then
        if val == math.floor(val) then return tostring(math.floor(val))
        else return string.format("%.6f", val) end
    elseif t == "string" then
        return '"'..val:gsub('\\','\\\\'):gsub('"','\\"')..'"'
    elseif t == "table" then
        local isArr = (#val > 0)
        local pad = string.rep("  ", indent+1)
        local endPad = string.rep("  ", indent)
        local parts = {}
        if isArr then
            for _, v in ipairs(val) do
                table.insert(parts, pad..encode(v, indent+1))
            end
            return "[\n"..table.concat(parts,",\n").."\n"..endPad.."]"
        else
            -- Sort keys for consistent output
            local keys = {}
            for k in pairs(val) do table.insert(keys, k) end
            table.sort(keys)
            for _, k in ipairs(keys) do
                table.insert(parts, pad..'"'..k..'"'.." : "..encode(val[k], indent+1))
            end
            return "{\n"..table.concat(parts,",\n").."\n"..endPad.."}"
        end
    end
    return "null"
end

-- JSON decoder (basit ama güvenli — pcall ile sarılı kullanılır)
local function decode(s)
    local pos = 1
    local function skip() while pos <= #s and s:sub(pos,pos):match("%s") do pos=pos+1 end end
    local parseVal
    local function parseStr()
        pos=pos+1 -- skip "
        local res = {}
        while pos <= #s do
            local c = s:sub(pos,pos)
            if c == '"' then pos=pos+1; return table.concat(res) end
            if c == '\\' then
                pos=pos+1; c=s:sub(pos,pos)
                if c=='n' then c='\n' elseif c=='t' then c='\t' end
            end
            table.insert(res, c); pos=pos+1
        end
    end
    local function parseNum()
        local start=pos
        s:sub(pos):gsub("^%-?%d+%.?%d*[eE]?[+-]?%d*", function(m) pos=pos+#m end)
        return tonumber(s:sub(start,pos-1))
    end
    local function parseArr()
        pos=pos+1; local arr={}
        skip()
        if s:sub(pos,pos)==']' then pos=pos+1; return arr end
        while true do
            table.insert(arr, parseVal())
            skip()
            local c=s:sub(pos,pos)
            if c==']' then pos=pos+1; break end
            pos=pos+1
        end
        return arr
    end
    local function parseObj()
        pos=pos+1; local obj={}
        skip()
        if s:sub(pos,pos)=='}' then pos=pos+1; return obj end
        while true do
            skip(); local k=parseStr(); skip()
            pos=pos+1; skip() -- skip ":"
            obj[k]=parseVal(); skip()
            local c=s:sub(pos,pos)
            if c=='}' then pos=pos+1; break end
            pos=pos+1
        end
        return obj
    end
    parseVal = function()
        skip()
        local c=s:sub(pos,pos)
        if c=='"' then return parseStr()
        elseif c=='{' then return parseObj()
        elseif c=='[' then return parseArr()
        elseif c=='t' then pos=pos+4; return true
        elseif c=='f' then pos=pos+5; return false
        elseif c=='n' then pos=pos+4; return nil
        else return parseNum() end
    end
    return parseVal()
end

-- Config kaydetme
local function saveConfig(slotName)
    if not FS_OK then
        Rayfield:Notify({Title="Config", Content="Filesystem not supported by this executor.", Duration=4})
        return false
    end
    local ok, err = pcall(function()
        local path = CONFIG_FOLDER.."/"..slotName..CONFIG_EXT
        local data = buildConfigData()
        writefile(path, encode(data))
    end)
    if ok then
        Rayfield:Notify({Title="Config Saved", Content="Slot: "..slotName, Duration=3})
        return true
    else
        Rayfield:Notify({Title="Config Error", Content="Save failed: "..(err or "?"), Duration=4})
        return false
    end
end

-- Anahtar haritası (string -> Enum)
local KEY_MAP = {
    RightMouseButton=Enum.UserInputType.MouseButton2,
    LeftMouseButton=Enum.UserInputType.MouseButton1,
    E=Enum.KeyCode.E, Q=Enum.KeyCode.Q, F=Enum.KeyCode.F,
    Z=Enum.KeyCode.Z, X=Enum.KeyCode.X, C=Enum.KeyCode.C, V=Enum.KeyCode.V,
    LeftShift=Enum.KeyCode.LeftShift, LeftControl=Enum.KeyCode.LeftControl,
    LeftAlt=Enum.KeyCode.LeftAlt,
}

-- Config yükleme — state tablolarını günceller, UI'ı yeniden çizmez
-- (UI yeniden başlatma gerekir; Rayfield flag update'i pcall ile denenir)
local function applyConfig(data)
    -- ESP
    if data.ESP then
        local e = data.ESP
        if e.Enabled ~= nil       then ESP.Enabled = e.Enabled end
        if e.Highlight ~= nil      then ESP.Highlight = e.Highlight end
        if e.HighlightTransparency then ESP.HighlightTransparency = e.HighlightTransparency end
        if e.HighlightColor        then ESP.HighlightColor = tToC3(e.HighlightColor) end
        if e.Box ~= nil            then ESP.Box = e.Box end
        if e.BoxFill ~= nil        then ESP.BoxFill = e.BoxFill end
        if e.BoxThickness          then ESP.BoxThickness = e.BoxThickness end
        if e.BoxColor              then ESP.BoxColor = tToC3(e.BoxColor) end
        if e.HealthBar ~= nil      then ESP.HealthBar = e.HealthBar end
        if e.HealthBarGradient ~= nil then ESP.HealthBarGradient = e.HealthBarGradient end
        if e.HealthBarThickness    then ESP.HealthBarThickness = e.HealthBarThickness end
        if e.HealthText ~= nil     then ESP.HealthText = e.HealthText end
        if e.HealthTextPercent ~= nil then ESP.HealthTextPercent = e.HealthTextPercent end
        if e.HealthTextColor       then ESP.HealthTextColor = tToC3(e.HealthTextColor) end
        if e.HealthTextSize        then ESP.HealthTextSize = e.HealthTextSize end
        if e.ShowName ~= nil       then ESP.ShowName = e.ShowName end
        if e.ShowDisplayName ~= nil then ESP.ShowDisplayName = e.ShowDisplayName end
        if e.NameColor             then ESP.NameColor = tToC3(e.NameColor) end
        if e.NameSize              then ESP.NameSize = e.NameSize end
        if e.Distance ~= nil       then ESP.Distance = e.Distance end
        if e.MaxDistance           then ESP.MaxDistance = e.MaxDistance end
        if e.DistanceColor         then ESP.DistanceColor = tToC3(e.DistanceColor) end
        if e.DistanceSize          then ESP.DistanceSize = e.DistanceSize end
        if e.Tracers ~= nil        then ESP.Tracers = e.Tracers end
        if e.TracersThickness      then ESP.TracersThickness = e.TracersThickness end
        if e.TracersTransparency   then ESP.TracersTransparency = e.TracersTransparency end
        if e.TracersColor          then ESP.TracersColor = tToC3(e.TracersColor) end
        if e.LookDirection ~= nil  then ESP.LookDirection = e.LookDirection end
        if e.ShowArrow ~= nil      then ESP.ShowArrow = e.ShowArrow end
        if e.LookDirectionThickness then ESP.LookDirectionThickness = e.LookDirectionThickness end
        if e.LookDirectionColor    then ESP.LookDirectionColor = tToC3(e.LookDirectionColor) end
        if e.ItemESP ~= nil        then ESP.ItemESP = e.ItemESP end
        if e.ItemMaxDistance       then ESP.ItemMaxDistance = e.ItemMaxDistance end
        if e.ShowItemDistance ~= nil then ESP.ShowItemDistance = e.ShowItemDistance end
        if e.ItemTextSize          then ESP.ItemTextSize = e.ItemTextSize end
        if e.RareLootColor         then ESP.RareLootColor = tToC3(e.RareLootColor) end
        if e.CommonLootColor       then ESP.CommonLootColor = tToC3(e.CommonLootColor) end
        if e.LootBoxESP ~= nil     then ESP.LootBoxESP = e.LootBoxESP end
        -- ESP aktifse yeniden uygula
        if ESP.Enabled then applyESPToAll() end
    end
    -- AB
    if data.AB then
        local a = data.AB
        if a.Enabled ~= nil        then AB.Enabled = a.Enabled end
        if a.Smoothness            then AB.Smoothness = a.Smoothness end
        if a._KeyName              then
            AB._KeyName = a._KeyName
            AB.AimKey = KEY_MAP[a._KeyName] or Enum.UserInputType.MouseButton2
        end
        if a.BodyPart              then AB.BodyPart = a.BodyPart end
        if a.AimMode               then AB.AimMode = a.AimMode end
        if a.FOVEnabled ~= nil     then AB.FOVEnabled = a.FOVEnabled end
        if a.FOVSize               then AB.FOVSize = a.FOVSize end
        if a.FOVThickness          then AB.FOVThickness = a.FOVThickness; AimFOVCircle.Thickness = a.FOVThickness end
        if a.FOVFilled ~= nil      then AB.FOVFilled = a.FOVFilled end
        if a.FOVFilledTransparency then AB.FOVFilledTransparency = a.FOVFilledTransparency; AimFOVFill.Transparency = a.FOVFilledTransparency end
        if a.FOVColor              then
            AB.FOVColor = tToC3(a.FOVColor)
            AimFOVCircle.Color = AB.FOVColor; AimFOVFill.Color = AB.FOVColor
        end
        if a.CrosshairEnabled ~= nil then AB.CrosshairEnabled = a.CrosshairEnabled end
        if a.CrosshairStyle        then AB.CrosshairStyle = a.CrosshairStyle end
        if a.CrosshairSize         then AB.CrosshairSize = a.CrosshairSize end
        if a.CrosshairThickness    then AB.CrosshairThickness = a.CrosshairThickness end
        if a.CrosshairGap          then AB.CrosshairGap = a.CrosshairGap end
        if a.CrosshairColor        then AB.CrosshairColor = tToC3(a.CrosshairColor) end
        if a.CrosshairOutline ~= nil then AB.CrosshairOutline = a.CrosshairOutline end
        if a.CrosshairOutlineColor then AB.CrosshairOutlineColor = tToC3(a.CrosshairOutlineColor) end
        if a.CrosshairOpacity      then AB.CrosshairOpacity = a.CrosshairOpacity end
    end
    -- BOT
    if data.BOT then
        local b = data.BOT
        if b.Enabled ~= nil        then BOT.Enabled = b.Enabled; if b.Enabled then startBotScan() else stopBotScan() end end
        if b.Box ~= nil            then BOT.Box = b.Box end
        if b.BoxFill ~= nil        then BOT.BoxFill = b.BoxFill end
        if b.BoxThickness          then BOT.BoxThickness = b.BoxThickness end
        if b.BoxColor              then BOT.BoxColor = tToC3(b.BoxColor) end
        if b.Skeleton ~= nil       then BOT.Skeleton = b.Skeleton end
        if b.SkeletonThickness     then BOT.SkeletonThickness = b.SkeletonThickness end
        if b.SkeletonColor         then BOT.SkeletonColor = tToC3(b.SkeletonColor) end
        if b.Highlight ~= nil      then BOT.Highlight = b.Highlight end
        if b.HighlightTransparency then BOT.HighlightTransparency = b.HighlightTransparency end
        if b.HighlightColor        then BOT.HighlightColor = tToC3(b.HighlightColor) end
        if b.HealthBar ~= nil      then BOT.HealthBar = b.HealthBar end
        if b.HealthBarGradient ~= nil then BOT.HealthBarGradient = b.HealthBarGradient end
        if b.HealthBarThickness    then BOT.HealthBarThickness = b.HealthBarThickness end
        if b.HealthText ~= nil     then BOT.HealthText = b.HealthText end
        if b.HealthTextPercent ~= nil then BOT.HealthTextPercent = b.HealthTextPercent end
        if b.HealthTextColor       then BOT.HealthTextColor = tToC3(b.HealthTextColor) end
        if b.HealthTextSize        then BOT.HealthTextSize = b.HealthTextSize end
        if b.ShowName ~= nil       then BOT.ShowName = b.ShowName end
        if b.NameColor             then BOT.NameColor = tToC3(b.NameColor) end
        if b.NameSize              then BOT.NameSize = b.NameSize end
        if b.Distance ~= nil       then BOT.Distance = b.Distance end
        if b.MaxDistance           then BOT.MaxDistance = b.MaxDistance end
        if b.DistanceColor         then BOT.DistanceColor = tToC3(b.DistanceColor) end
        if b.DistanceSize          then BOT.DistanceSize = b.DistanceSize end
        if b.Tracers ~= nil        then BOT.Tracers = b.Tracers end
        if b.TracersThickness      then BOT.TracersThickness = b.TracersThickness end
        if b.TracersTransparency   then BOT.TracersTransparency = b.TracersTransparency end
        if b.TracersColor          then BOT.TracersColor = tToC3(b.TracersColor) end
        if b.OffScreen ~= nil      then BOT.OffScreen = b.OffScreen end
        if b.OffScreenSize         then BOT.OffScreenSize = b.OffScreenSize end
        if b.OffScreenColor        then BOT.OffScreenColor = tToC3(b.OffScreenColor) end
    end
    -- BOTAB
    if data.BOTAB then
        local ba = data.BOTAB
        if ba.Enabled ~= nil       then BOTAB.Enabled = ba.Enabled end
        if ba.Smoothness           then BOTAB.Smoothness = ba.Smoothness end
        if ba._KeyName             then
            BOTAB._KeyName = ba._KeyName
            BOTAB.AimKey = KEY_MAP[ba._KeyName] or Enum.UserInputType.MouseButton2
        end
        if ba.BodyPart             then BOTAB.BodyPart = ba.BodyPart end
        if ba.AimMode              then BOTAB.AimMode = ba.AimMode end
        if ba.FOVEnabled ~= nil    then BOTAB.FOVEnabled = ba.FOVEnabled end
        if ba.FOVSize              then BOTAB.FOVSize = ba.FOVSize end
        if ba.FOVThickness         then BOTAB.FOVThickness = ba.FOVThickness; BotAimFOVCircle.Thickness = ba.FOVThickness end
        if ba.FOVFilled ~= nil     then BOTAB.FOVFilled = ba.FOVFilled end
        if ba.FOVFilledTransparency then BOTAB.FOVFilledTransparency = ba.FOVFilledTransparency; BotAimFOVFill.Transparency = ba.FOVFilledTransparency end
        if ba.FOVColor             then
            BOTAB.FOVColor = tToC3(ba.FOVColor)
            BotAimFOVCircle.Color = BOTAB.FOVColor; BotAimFOVFill.Color = BOTAB.FOVColor
        end
    end
    -- Watermark
    if data.WM then
        if data.WM.Enabled ~= nil then WM_Enabled = data.WM.Enabled end
        if data.WM.Color          then WM_Color = tToC3(data.WM.Color) end
    end
end

local function loadConfig(slotName)
    if not FS_OK then
        Rayfield:Notify({Title="Config", Content="Filesystem not supported by this executor.", Duration=4})
        return false
    end
    local path = CONFIG_FOLDER.."/"..slotName..CONFIG_EXT
    local ok, err = pcall(function()
        local raw = readfile(path)
        local data = decode(raw)
        if not data then error("Parse hatası") end
        applyConfig(data)
    end)
    if ok then
        Rayfield:Notify({Title="Config Loaded", Content="Slot: "..slotName.." applied. Re-run script for full UI refresh.", Duration=5})
        return true
    else
        Rayfield:Notify({Title="Config Error", Content="Load failed: "..(err or "?"), Duration=4})
        return false
    end
end

local function deleteConfig(slotName)
    if not FS_OK then return false end
    local path = CONFIG_FOLDER.."/"..slotName..CONFIG_EXT
    local ok, err = pcall(function()
        -- delfile varsa kullan, yoksa boş dosya yaz (temizleme)
        if type(delfile)=="function" then
            delfile(path)
        else
            writefile(path, "")
        end
    end)
    if ok then
        Rayfield:Notify({Title="Config Deleted", Content="Slot: "..slotName, Duration=3})
        return true
    else
        Rayfield:Notify({Title="Config Error", Content="Delete failed: "..(err or "?"), Duration=4})
        return false
    end
end

-- Kayıtlı slot listesini getir
local function getSlotList()
    if not FS_OK then return {} end
    local slots = {}
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if not ok or not files then return slots end
    for _, f in ipairs(files) do
        -- dosya adından slot adını çıkar
        local name = f:match("([^/\\]+)"..CONFIG_EXT:gsub("%.","%%.").."%s*$")
        if name then table.insert(slots, name) end
    end
    return slots
end

-- Slot adı dropdown seçenekleri
local SLOT_NAMES = {}
for i = 1, MAX_SLOTS do table.insert(SLOT_NAMES, "Slot "..i) end

local selectedSlot = SLOT_NAMES[1]

-- ─── AUTO-SAVE (isteğe bağlı) ───────────
local AutoSave_Enabled  = false
local AutoSave_Interval = 60  -- saniye
local _autoSaveClock    = 0

RunService.Heartbeat:Connect(function(dt)
    if not AutoSave_Enabled then return end
    _autoSaveClock = _autoSaveClock + dt
    if _autoSaveClock >= AutoSave_Interval then
        _autoSaveClock = 0
        saveConfig("AutoSave")
    end
end)

-- ═══════════════════════════════════════
--              SETTINGS UI
-- ═══════════════════════════════════════

-- Watermark
SettingsTab:CreateSection("Watermark")
SettingsTab:CreateToggle({Name="Watermark", CurrentValue=false, Flag="WatermarkEnable", Callback=function(v)
    WM_Enabled = v
end})
SettingsTab:CreateColorPicker({Name="Watermark Color", Color=Color3.fromRGB(255,255,255), Flag="WatermarkColor", Callback=function(v)
    WM_Color = v
end})

-- FPS
SettingsTab:CreateSection("FPS")
local FPSUnlimitedActive = false
SettingsTab:CreateToggle({Name="Unlimited FPS", CurrentValue=false, Flag="FPSUnlimited", Callback=function(v)
    FPSUnlimitedActive = v
    unlockFPS(v and 0 or 60)
end})
SettingsTab:CreateSlider({Name="FPS Cap", Range={30,360}, Increment=10, CurrentValue=60, Flag="FPSCap", Callback=function(v)
    if not FPSUnlimitedActive then unlockFPS(v) end
end})

-- Anti-AFK
SettingsTab:CreateSection("Anti-AFK")
SettingsTab:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AntiAFK", Callback=function(v)
    if v then startAntiAFK() else stopAntiAFK() end
end})

-- ─── CONFIG UI ──────────────────────────
SettingsTab:CreateSection("Config - Slot")

SettingsTab:CreateDropdown({
    Name = "Config Slot",
    Options = SLOT_NAMES,
    CurrentOption = {SLOT_NAMES[1]},
    Flag = "ConfigSlotSelect",
    Callback = function(v)
        selectedSlot = v[1]
    end,
})

SettingsTab:CreateSection("Config - Actions")

SettingsTab:CreateButton({
    Name = "Save",
    Callback = function()
        saveConfig(selectedSlot)
    end,
})

SettingsTab:CreateButton({
    Name = "Load",
    Callback = function()
        loadConfig(selectedSlot)
    end,
})

SettingsTab:CreateButton({
    Name = "Delete",
    Callback = function()
        deleteConfig(selectedSlot)
    end,
})

SettingsTab:CreateSection("Config - Quick Actions")

SettingsTab:CreateButton({
    Name = "Save to AutoSave",
    Callback = function()
        saveConfig("AutoSave")
    end,
})

SettingsTab:CreateButton({
    Name = "Load from AutoSave",
    Callback = function()
        loadConfig("AutoSave")
    end,
})

SettingsTab:CreateButton({
    Name = "Delete AutoSave",
    Callback = function()
        deleteConfig("AutoSave")
    end,
})

SettingsTab:CreateSection("Config - Auto-Save")

SettingsTab:CreateToggle({
    Name = "Auto-Save",
    CurrentValue = false,
    Flag = "AutoSaveToggle",
    Callback = function(v)
        AutoSave_Enabled = v
        if v then
            Rayfield:Notify({Title="Auto-Save Enabled", Content="Saving to 'AutoSave' slot every "..AutoSave_Interval.." seconds.", Duration=4})
        end
    end,
})

SettingsTab:CreateSlider({
    Name = "Auto-Save Interval (seconds)",
    Range = {10, 300},
    Increment = 10,
    CurrentValue = AutoSave_Interval,
    Flag = "AutoSaveInterval",
    Callback = function(v)
        AutoSave_Interval = v
        _autoSaveClock = 0
    end,
})

SettingsTab:CreateSection("Config - Info")
SettingsTab:CreateLabel("Location: NyxPJD/[SlotName].cfg")
SettingsTab:CreateLabel("After loading, UI values won't update")
SettingsTab:CreateLabel("visually but ESP/aimbot will work.")
SettingsTab:CreateLabel("Re-run the script for full UI refresh.")

-- Misc
SettingsTab:CreateSection("Misc")
SettingsTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})