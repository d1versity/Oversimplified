-- Oversimplified by Vhyse | v2.3

local Oversimplified = {
    Theme = {
        Bg = Color3.fromRGB(12, 12, 14),
        Border = Color3.fromRGB(45, 45, 50),
        Text = Color3.fromRGB(220, 220, 225),
        Active = Color3.fromRGB(255, 255, 255),
        Inactive = Color3.fromRGB(20, 20, 24),
        SliderBg = Color3.fromRGB(24, 24, 28),
        DarkerBg = Color3.fromRGB(8, 8, 10)
    },
    BackgroundVisible = true,
    HubSettingsCreated = false
}

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local function GetCoreGui()
    local success, result = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if success and result then return result end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local CG = GetCoreGui()

local function MakeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local dragConn = UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    frame.Destroying:Connect(function()
        if dragConn then
            dragConn:Disconnect()
        end
    end)
end

local function FadeUI(element, isVisible, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    
    local function tweenObject(obj)
        if not obj:GetAttribute("OS") then
            obj:SetAttribute("OS", true)
            if obj:IsA("GuiObject") then obj:SetAttribute("OBg", obj.BackgroundTransparency) end
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then obj:SetAttribute("OTx", obj.TextTransparency) end
            if obj:IsA("UIStroke") then obj:SetAttribute("OSt", obj.Transparency) end
            if obj:IsA("ScrollingFrame") then obj:SetAttribute("OSc", obj.ScrollBarImageTransparency) end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then obj:SetAttribute("OIm", obj.ImageTransparency) end
        end
        
        local props = {}
        if obj:GetAttribute("OBg") then props.BackgroundTransparency = isVisible and obj:GetAttribute("OBg") or 1 end
        if obj:GetAttribute("OTx") then props.TextTransparency = isVisible and obj:GetAttribute("OTx") or 1 end
        if obj:GetAttribute("OSt") then props.Transparency = isVisible and obj:GetAttribute("OSt") or 1 end
        if obj:GetAttribute("OSc") then props.ScrollBarImageTransparency = isVisible and obj:GetAttribute("OSc") or 1 end
        if obj:GetAttribute("OIm") then props.ImageTransparency = isVisible and obj:GetAttribute("OIm") or 1 end
        
        if next(props) then
            if duration == 0 then
                for k, v in pairs(props) do obj[k] = v end
            else
                TS:Create(obj, tweenInfo, props):Play()
            end
        end
    end
    
    tweenObject(element)
    for _, child in ipairs(element:GetDescendants()) do tweenObject(child) end
end

function Oversimplified:CreateWindow(titleText, keyString)
    if CG:FindFirstChild("OS_UI") then
        CG.OS_UI:Destroy()
    end

    local SG = Instance.new("ScreenGui", CG)
    SG.Name = "OS_UI"
    SG.ResetOnSpawn = false
    SG.Enabled = false
    SG.IgnoreGuiInset = true
    
    local Theme = self.Theme

    local WO = {}
    WO.CT = nil
    WO.Registry = {} 
    WO.Connections = {}
    
    local isSwitchingTab = false

    local Backdrop = Instance.new("Frame", SG)
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Backdrop.BackgroundTransparency = 1 
    Backdrop.BorderSizePixel = 0
    Backdrop.ZIndex = -1
    Backdrop.Visible = false
    
    local fadeVal = Instance.new("NumberValue", Backdrop)
    fadeVal.Value = 1

    local particles = {}
    local comets = {}
    local maxParticles = 200 
    local isUIVisible = false
    local cam = Workspace.CurrentCamera
    local camSize = cam.ViewportSize

    table.insert(WO.Connections, cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        camSize = cam.ViewportSize
    end))

    local function SpawnParticle(startY)
        local size = math.random(3, 6) 
        local p = Instance.new("Frame", Backdrop)
        p.Size = UDim2.new(0, size, 0, size)
        
        local startX = math.random()
        if not startY then startY = -20 end
        
        p.Position = UDim2.new(startX, 0, 0, startY)
        p.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        p.BorderSizePixel = 0
        
        local baseTrans = math.random(30, 90) / 100
        p.BackgroundTransparency = baseTrans + fadeVal.Value
        
        local corner = Instance.new("UICorner", p)
        corner.CornerRadius = UDim.new(1, 0)
        
        table.insert(particles, {
            obj = p, speed = math.random(100, 250), drift = math.random(-35, 35) / 1000, 
            sinOff = math.random(0, 100), xBase = startX, y = startY, baseTrans = baseTrans
        })
    end

    local function SpawnComet()
        local p = Instance.new("Frame", Backdrop)
        local length = math.random(150, 350)
        p.Size = UDim2.new(0, length, 0, 2)
        p.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        p.BorderSizePixel = 0
        p.AnchorPoint = Vector2.new(1, 0.5) 
        p.BackgroundTransparency = fadeVal.Value
        
        local startX = math.random(-400, camSize.X / 2)
        local startY = math.random(-300, 100)
        p.Position = UDim2.new(0, startX, 0, startY)
        
        local grad = Instance.new("UIGradient", p)
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.8, 0.8),
            NumberSequenceKeypoint.new(1, 0)
        })

        table.insert(comets, {
            obj = p, x = startX, y = startY,
            speedX = math.random(1200, 2000), speedY = math.random(200, 500), gravity = math.random(400, 900)
        })
    end

    for i = 1, maxParticles do SpawnParticle(math.random(-100, math.max(camSize.Y, 1000))) end

    local renderConnection = RS.RenderStepped:Connect(function(dt)
        if not isUIVisible then return end
        
        local curClock = os.clock()
        local limitY = camSize.Y + 50
        local limitX = camSize.X + 300
        local currentFade = fadeVal.Value
        
        for i = #particles, 1, -1 do
            local data = particles[i]
            if data.obj.Parent then
                data.y = data.y + (data.speed * dt)
                local newX = data.xBase + (math.sin(curClock + data.sinOff) * data.drift)
                
                data.obj.Position = UDim2.new(newX, 0, 0, data.y)
                data.obj.BackgroundTransparency = data.baseTrans + currentFade
                
                if data.y > limitY then
                    data.obj:Destroy()
                    table.remove(particles, i)
                end
            else
                table.remove(particles, i)
            end
        end
        
        if self.BackgroundVisible and #particles < maxParticles then 
            local randomSpawnCount = math.random(1, 3)
            for _ = 1, randomSpawnCount do SpawnParticle(-20) end
        end

        for i = #comets, 1, -1 do
            local data = comets[i]
            if data.obj.Parent then
                data.speedY = data.speedY + (data.gravity * dt)
                data.x = data.x + (data.speedX * dt)
                data.y = data.y + (data.speedY * dt)
                
                data.obj.Position = UDim2.new(0, data.x, 0, data.y)
                data.obj.Rotation = math.deg(math.atan2(data.speedY, data.speedX))
                data.obj.BackgroundTransparency = currentFade
                
                if data.y > limitY + 250 or data.x > limitX then
                    data.obj:Destroy()
                    table.remove(comets, i)
                end
            else
                table.remove(comets, i)
            end
        end

        if self.BackgroundVisible and math.random(1, 100) == 1 then SpawnComet() end
    end)
    table.insert(WO.Connections, renderConnection)

    local MF = Instance.new("Frame", SG)
    MF.Size = UDim2.new(0, 520, 0, 380)
    MF.Position = UDim2.new(0.5, -260, 0.5, -190)
    MF.BackgroundColor3 = Theme.Bg
    MF.Visible = false
    MF.ClipsDescendants = true
    
    local mfCorner = Instance.new("UICorner", MF)
    mfCorner.CornerRadius = UDim.new(0, 6)
    
    local mfStroke = Instance.new("UIStroke", MF)
    mfStroke.Color = Theme.Border
    mfStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    MakeDraggable(MF)
    
    local Ti = Instance.new("TextLabel", MF)
    Ti.Size = UDim2.new(1, -64, 0, 30)
    Ti.Position = UDim2.new(0, 3, 0, 0)
    Ti.BackgroundTransparency = 1
    Ti.Text = "  " .. titleText
    Ti.TextColor3 = Theme.Active
    Ti.Font = Enum.Font.GothamBold
    Ti.TextSize = 14
    Ti.TextXAlignment = Enum.TextXAlignment.Left
    
    local D = Instance.new("Frame", MF)
    D.Size = UDim2.new(1, 0, 0, 1)
    D.Position = UDim2.new(0, 0, 0, 30)
    D.BackgroundColor3 = Theme.Border
    D.BorderSizePixel = 0
    
    local VD = Instance.new("Frame", MF)
    VD.Size = UDim2.new(0, 1, 0, 350)
    VD.Position = UDim2.new(0, 130, 0, 30)
    VD.BackgroundColor3 = Theme.Border
    VD.BorderSizePixel = 0
    
    local TC = Instance.new("ScrollingFrame", MF)
    TC.Size = UDim2.new(0, 130, 0, 305)
    TC.Position = UDim2.new(0, 0, 0, 35)
    TC.BackgroundTransparency = 1
    TC.ScrollBarThickness = 0
    TC.CanvasSize = UDim2.new(0, 0, 0, 0)
    TC.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local TL = Instance.new("UIListLayout")
    TL.Padding = UDim.new(0, 5)
    TL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TL.SortOrder = Enum.SortOrder.LayoutOrder
    TL.Parent = TC
    
    local TabContainerPadding = Instance.new("UIPadding")
    TabContainerPadding.PaddingTop = UDim.new(0, 2)
    TabContainerPadding.PaddingBottom = UDim.new(0, 2)
    TabContainerPadding.Parent = TC
    
    local ProfFrame = Instance.new("Frame", MF)
    ProfFrame.Size = UDim2.new(0, 130, 0, 40)
    ProfFrame.Position = UDim2.new(0, 0, 0, 340)
    ProfFrame.BackgroundTransparency = 1
    
    local PDiv = Instance.new("Frame", ProfFrame)
    PDiv.Size = UDim2.new(1, 0, 0, 1)
    PDiv.Position = UDim2.new(0, 0, 0, 0)
    PDiv.BackgroundColor3 = Theme.Border
    PDiv.BorderSizePixel = 0
    
    local Avatar = Instance.new("ImageLabel", ProfFrame)
    Avatar.Size = UDim2.new(0, 24, 0, 24)
    Avatar.Position = UDim2.new(0, 8, 0.5, -12)
    Avatar.BackgroundColor3 = Theme.DarkerBg
    Avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..Players.LocalPlayer.UserId.."&w=150&h=150"
    
    local AvatarCorner = Instance.new("UICorner", Avatar)
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    
    local AvatarStroke = Instance.new("UIStroke", Avatar)
    AvatarStroke.Color = Theme.Border
    
    local NameLbl = Instance.new("TextLabel", ProfFrame)
    NameLbl.Size = UDim2.new(1, -44, 1, 0)
    NameLbl.Position = UDim2.new(0, 38, 0, 0)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Text = Players.LocalPlayer.DisplayName
    NameLbl.TextColor3 = Theme.Text
    NameLbl.Font = Enum.Font.GothamBold
    NameLbl.TextSize = 11
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left
    NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    local CC = Instance.new("Frame", MF)
    CC.Size = UDim2.new(1, -135, 0, 340)
    CC.Position = UDim2.new(0, 130, 0, 35)
    CC.BackgroundTransparency = 1
    
    local NC = Instance.new("ScreenGui", CG)
    NC.Name = "OS_Notifications"
    NC.ResetOnSpawn = false
    NC.IgnoreGuiInset = true
    
    local NCHolder = Instance.new("Frame", NC)
    NCHolder.Size = UDim2.new(0, 250, 1, -40)
    NCHolder.Position = UDim2.new(1, -270, 0, 20)
    NCHolder.BackgroundTransparency = 1
    
    local NL = Instance.new("UIListLayout")
    NL.Padding = UDim.new(0, 10)
    NL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NL.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NL.Parent = NCHolder
    
    local isVisibleState = true
    local isTweening = false
    local KeyFrame = nil

    local function SetUIVisible(state)
        if isTweening then return end
        isTweening = true
        isVisibleState = state
        
        local activeUI = MF
        if KeyFrame and KeyFrame.Parent then
            activeUI = KeyFrame
        end
        
        if isVisibleState then 
            isUIVisible = true
            if self.BackgroundVisible then
                Backdrop.Visible = true
                TS:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 0.35}):Play()
                TS:Create(fadeVal, TweenInfo.new(0.3), {Value = 0}):Play()
            end
            FadeUI(activeUI, false, 0)
            activeUI.Visible = true
            FadeUI(activeUI, true, 0.3)
        else 
            if self.BackgroundVisible then
                TS:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
                TS:Create(fadeVal, TweenInfo.new(0.3), {Value = 1}):Play()
            end
            FadeUI(activeUI, false, 0.3)
            task.delay(0.3, function() 
                activeUI.Visible = false
                Backdrop.Visible = false 
                isUIVisible = false 
            end) 
        end
        
        task.delay(0.3, function() isTweening = false end)
    end

    local function mkMac(parentFrame, color, xPos, callback) 
        local btn = Instance.new("TextButton", parentFrame)
        btn.Size = UDim2.new(0, 12, 0, 12)
        btn.Position = UDim2.new(1, xPos, 0, 9)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(1, 0)
        
        btn.MouseButton1Click:Connect(callback) 
    end

    if keyString and keyString ~= "" then
        KeyFrame = Instance.new("Frame", SG)
        KeyFrame.Size = UDim2.new(0, 350, 0, 150)
        KeyFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
        KeyFrame.BackgroundColor3 = Theme.Bg
        KeyFrame.Visible = false
        KeyFrame.ClipsDescendants = true
        
        local kfCorner = Instance.new("UICorner", KeyFrame)
        kfCorner.CornerRadius = UDim.new(0, 6)
        
        local kfStroke = Instance.new("UIStroke", KeyFrame)
        kfStroke.Color = Theme.Border
        
        MakeDraggable(KeyFrame)
        
        local KTitle = Instance.new("TextLabel", KeyFrame)
        KTitle.Size = UDim2.new(1, -64, 0, 30)
        KTitle.Position = UDim2.new(0, 3, 0, 0)
        KTitle.BackgroundTransparency = 1
        KTitle.Text = "  " .. titleText .. " - Key System"
        KTitle.TextColor3 = Theme.Active
        KTitle.Font = Enum.Font.GothamBold
        KTitle.TextSize = 14
        KTitle.TextXAlignment = Enum.TextXAlignment.Left
        
        local KD = Instance.new("Frame", KeyFrame)
        KD.Size = UDim2.new(1, 0, 0, 1)
        KD.Position = UDim2.new(0, 0, 0, 30)
        KD.BackgroundColor3 = Theme.Border
        KD.BorderSizePixel = 0
        
        local KInfo = Instance.new("TextLabel", KeyFrame)
        KInfo.Size = UDim2.new(1, -20, 0, 20)
        KInfo.Position = UDim2.new(0, 10, 0, 45)
        KInfo.BackgroundTransparency = 1
        KInfo.Text = "Please enter the access key to continue."
        KInfo.TextColor3 = Theme.Text
        KInfo.Font = Enum.Font.Gotham
        KInfo.TextSize = 12
        
        local KInput = Instance.new("TextBox", KeyFrame)
        KInput.Size = UDim2.new(1, -20, 0, 30)
        KInput.Position = UDim2.new(0, 10, 0, 70)
        KInput.BackgroundColor3 = Theme.DarkerBg
        KInput.TextColor3 = Theme.Text
        KInput.Text = ""
        KInput.PlaceholderText = "Enter Key Here..."
        KInput.Font = Enum.Font.Gotham
        KInput.TextSize = 12
        KInput.ClearTextOnFocus = false
        
        local kiCorner = Instance.new("UICorner", KInput)
        kiCorner.CornerRadius = UDim.new(0, 4)
        
        local kiStroke = Instance.new("UIStroke", KInput)
        kiStroke.Color = Theme.Border
        
        local KBtn = Instance.new("TextButton", KeyFrame)
        KBtn.Size = UDim2.new(1, -20, 0, 30)
        KBtn.Position = UDim2.new(0, 10, 0, 110)
        KBtn.BackgroundColor3 = Theme.Inactive
        KBtn.Text = ""
        KBtn.AutoButtonColor = false
        
        local kbCorner = Instance.new("UICorner", KBtn)
        kbCorner.CornerRadius = UDim.new(0, 4)
        
        local kbStroke = Instance.new("UIStroke", KBtn)
        kbStroke.Color = Theme.Border
        
        local KBtnTxt = Instance.new("TextLabel", KBtn)
        KBtnTxt.Size = UDim2.new(1, 0, 1, 0)
        KBtnTxt.BackgroundTransparency = 1
        KBtnTxt.Text = "Submit Key"
        KBtnTxt.TextColor3 = Theme.Text
        KBtnTxt.Font = Enum.Font.GothamBold
        KBtnTxt.TextSize = 13
        
        KBtn.MouseButton1Click:Connect(function()
            TS:Create(KBtn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Active}):Play()
            TS:Create(KBtnTxt, TweenInfo.new(0.1), {TextColor3 = Theme.Bg}):Play()
            task.wait(0.1)
            TS:Create(KBtn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Inactive}):Play()
            TS:Create(KBtnTxt, TweenInfo.new(0.1), {TextColor3 = Theme.Text}):Play()
            
            if KInput.Text == keyString then 
                FadeUI(KeyFrame, false, 0.2)
                task.wait(0.2)
                KeyFrame:Destroy()
                KeyFrame = nil
                
                FadeUI(MF, false, 0)
                MF.Visible = true
                FadeUI(MF, true, 0.4)
            else 
                KInput.Text = ""
                KInput.PlaceholderText = "Incorrect Key!"
                TS:Create(KInput, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 40, 40)}):Play()
                task.delay(0.2, function() TS:Create(KInput, TweenInfo.new(0.2), {BackgroundColor3 = Theme.DarkerBg}):Play() end)
                task.delay(1.5, function() if KInput then KInput.PlaceholderText = "Enter Key Here..." end end) 
            end
        end)

        local isKeyMin = false
        mkMac(KeyFrame, Color3.fromRGB(0, 202, 78), -62, function() end)
        mkMac(KeyFrame, Color3.fromRGB(255, 189, 68), -41, function()
            isKeyMin = not isKeyMin
            local targetSize = isKeyMin and UDim2.new(0, 350, 0, 30) or UDim2.new(0, 350, 0, 150)
            TS:Create(KeyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        end)
        mkMac(KeyFrame, Color3.fromRGB(255, 96, 92), -20, function() SetUIVisible(false) end)
    end

    local isHubMin = false
    mkMac(MF, Color3.fromRGB(0, 202, 78), -62, function() end)
    mkMac(MF, Color3.fromRGB(255, 189, 68), -41, function()
        isHubMin = not isHubMin
        local targetSize = isHubMin and UDim2.new(0, 520, 0, 30) or UDim2.new(0, 520, 0, 380)
        TS:Create(MF, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        
        if isHubMin then 
            TS:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TS:Create(fadeVal, TweenInfo.new(0.3), {Value = 1}):Play()
            task.delay(0.3, function() Backdrop.Visible = false; isUIVisible = false end)
        else
            if self.BackgroundVisible then
                Backdrop.Visible = true
                isUIVisible = true
                TS:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 0.35}):Play()
                TS:Create(fadeVal, TweenInfo.new(0.3), {Value = 0}):Play()
            end
        end
    end)
    mkMac(MF, Color3.fromRGB(255, 96, 92), -20, function() SetUIVisible(false) end)

    task.delay(0.15, function() 
        SG.Enabled = true
        local activeUI = MF
        if KeyFrame then activeUI = KeyFrame end
        
        isUIVisible = true
        if self.BackgroundVisible then
            Backdrop.Visible = true
            TS:Create(Backdrop, TweenInfo.new(0.4), {BackgroundTransparency = 0.35}):Play()
            TS:Create(fadeVal, TweenInfo.new(0.4), {Value = 0}):Play()
        end
        
        FadeUI(activeUI, false, 0)
        activeUI.Visible = true
        FadeUI(activeUI, true, 0.4) 
    end)
    
    local toggleConnection = UIS.InputBegan:Connect(function(input, gameProcessed) 
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then 
            SetUIVisible(not isVisibleState) 
        end 
    end)
    table.insert(WO.Connections, toggleConnection)
    
    function WO:Unload()
        for _, conn in ipairs(WO.Connections) do
            if typeof(conn) == "RBXScriptConnection" and conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(WO.Connections)
        
        local activeUI = MF
        if KeyFrame and KeyFrame.Parent then activeUI = KeyFrame end
        
        TS:Create(Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TS:Create(fadeVal, TweenInfo.new(0.3), {Value = 1}):Play()
        FadeUI(activeUI, false, 0.3)
        
        task.delay(0.3, function()
            if SG then SG:Destroy() end
            if NC then NC:Destroy() end
        end)
    end

    function WO:Notify(titleText, descText, duration) 
        if not duration then duration = 3 end
        
        local NW = Instance.new("Frame", NCHolder)
        NW.Size = UDim2.new(1, 0, 0, 60)
        NW.BackgroundTransparency = 1
        
        local NM = Instance.new("Frame", NW)
        NM.Size = UDim2.new(1, 0, 1, 0)
        NM.Position = UDim2.new(1, 270, 0, 0)
        NM.BackgroundColor3 = Theme.Bg
        
        local nmCorner = Instance.new("UICorner", NM)
        nmCorner.CornerRadius = UDim.new(0, 6)
        
        local nmStroke = Instance.new("UIStroke", NM)
        nmStroke.Color = Theme.Border
        nmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local NT = Instance.new("TextLabel", NM)
        NT.Size = UDim2.new(1, -20, 0, 20)
        NT.Position = UDim2.new(0, 10, 0, 5)
        NT.BackgroundTransparency = 1
        NT.Text = titleText
        NT.TextColor3 = Theme.Active
        NT.Font = Enum.Font.GothamBold
        NT.TextSize = 13
        NT.TextXAlignment = Enum.TextXAlignment.Left
        
        local ND = Instance.new("TextLabel", NM)
        ND.Size = UDim2.new(1, -20, 0, 25)
        ND.Position = UDim2.new(0, 10, 0, 25)
        ND.BackgroundTransparency = 1
        ND.Text = descText
        ND.TextColor3 = Theme.Text
        ND.Font = Enum.Font.Gotham
        ND.TextSize = 12
        ND.TextXAlignment = Enum.TextXAlignment.Left
        ND.TextWrapped = true
        
        TS:Create(NM, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        
        task.delay(duration, function() 
            local fadeOut = TS:Create(NM, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(1, 270, 0, 0)})
            fadeOut:Play()
            fadeOut.Completed:Wait()
            NW:Destroy() 
        end) 
    end
    
    function WO:CreateTab(tabName)
        local TB = Instance.new("TextButton", TC)
        TB.Size = UDim2.new(1, -16, 0, 30)
        
        if self.CT == tabName then
            TB.BackgroundColor3 = Theme.Active
            TB.TextColor3 = Theme.Bg
        else
            TB.BackgroundColor3 = Theme.Inactive
            TB.TextColor3 = Theme.Text
        end
        
        TB.Font = Enum.Font.GothamBold
        TB.TextSize = 13
        TB.Text = tabName
        TB.AutoButtonColor = false
        
        local tbCorner = Instance.new("UICorner", TB)
        tbCorner.CornerRadius = UDim.new(0, 4)
        
        local tbStroke = Instance.new("UIStroke", TB)
        tbStroke.Color = Theme.Border
        tbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local TSc = Instance.new("ScrollingFrame", CC)
        TSc.Size = UDim2.new(1, 0, 1, 0)
        TSc.BackgroundTransparency = 1
        TSc.ScrollBarThickness = 2
        TSc.Visible = false
        TSc.CanvasSize = UDim2.new(0, 0, 0, 0)
        TSc.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local L = Instance.new("UIListLayout")
        L.Padding = UDim.new(0, 6)
        L.HorizontalAlignment = Enum.HorizontalAlignment.Center
        L.SortOrder = Enum.SortOrder.LayoutOrder
        L.Parent = TSc
        
        local ScrollContentPadding = Instance.new("UIPadding")
        ScrollContentPadding.PaddingTop = UDim.new(0, 2)
        ScrollContentPadding.PaddingBottom = UDim.new(0, 2)
        ScrollContentPadding.Parent = TSc
        
        TB.MouseButton1Click:Connect(function() 
            if WO.CT == tabName or isSwitchingTab then return end
            isSwitchingTab = true
            
            for _, btn in ipairs(TC:GetChildren()) do 
                if btn:IsA("TextButton") then 
                    TS:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Inactive, TextColor3 = Theme.Text}):Play() 
                end 
            end
            TS:Create(TB, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Active, TextColor3 = Theme.Bg}):Play()
            
            local activeScroll = nil
            for _, frame in ipairs(CC:GetChildren()) do 
                if frame:IsA("ScrollingFrame") and frame.Visible then 
                    activeScroll = frame
                    break 
                end 
            end
            
            if activeScroll then 
                FadeUI(activeScroll, false, 0.15)
                task.wait(0.15)
                activeScroll.Visible = false 
            end
            
            TSc.Visible = true
            WO.CT = tabName
            FadeUI(TSc, false, 0)
            FadeUI(TSc, true, 0.15)
            
            task.wait(0.15)
            isSwitchingTab = false 
        end)
        
        if not self.CT then 
            TSc.Visible = true
            TB.BackgroundColor3 = Theme.Active
            TB.TextColor3 = Theme.Bg
            self.CT = tabName 
        end
        
        local E = {}
        local orderIndex = 0
        
        function E:CreateParagraph(titleText, descText)
            orderIndex = orderIndex + 1
            local C = Instance.new("Frame", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 0)
            C.AutomaticSize = Enum.AutomaticSize.Y
            C.BackgroundColor3 = Theme.Bg
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local cLayout = Instance.new("UIListLayout")
            cLayout.SortOrder = Enum.SortOrder.LayoutOrder
            cLayout.Padding = UDim.new(0, 2)
            cLayout.Parent = C
            
            local ParagraphPadding = Instance.new("UIPadding")
            ParagraphPadding.PaddingTop = UDim.new(0, 5)
            ParagraphPadding.PaddingBottom = UDim.new(0, 5)
            ParagraphPadding.PaddingLeft = UDim.new(0, 10)
            ParagraphPadding.PaddingRight = UDim.new(0, 10)
            ParagraphPadding.Parent = C
            
            local LT = Instance.new("TextLabel", C)
            LT.LayoutOrder = 1
            LT.Size = UDim2.new(1, 0, 0, 20)
            LT.BackgroundTransparency = 1
            LT.Text = titleText
            LT.TextColor3 = Theme.Active
            LT.Font = Enum.Font.GothamBold
            LT.TextSize = 13
            LT.TextXAlignment = Enum.TextXAlignment.Left
            
            local LD = Instance.new("TextLabel", C)
            LD.LayoutOrder = 2
            LD.Size = UDim2.new(1, 0, 0, 0)
            LD.AutomaticSize = Enum.AutomaticSize.Y
            LD.BackgroundTransparency = 1
            LD.Text = descText
            LD.TextColor3 = Theme.Text
            LD.Font = Enum.Font.Gotham
            LD.TextSize = 12
            LD.TextXAlignment = Enum.TextXAlignment.Left
            LD.TextWrapped = true
            
            local PO = {}
            function PO:Set(newTitle, newDesc) 
                if newTitle then LT.Text = newTitle end
                if newDesc then LD.Text = newDesc end 
            end
            return PO
        end
        
        function E:CreateLabel(labelText)
            orderIndex = orderIndex + 1
            local Lb = Instance.new("TextLabel", TSc)
            Lb.LayoutOrder = orderIndex
            Lb.Size = UDim2.new(1, -14, 0, 25)
            Lb.BackgroundTransparency = 1
            Lb.TextColor3 = Theme.Active
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            Lb.Text = labelText
            
            local LO = {}
            function LO:Set(newText) 
                if newText then Lb.Text = newText end 
            end
            return LO
        end
        
        function E:CreateButton(btnText, callback)
            orderIndex = orderIndex + 1
            local B = Instance.new("TextButton", TSc)
            B.LayoutOrder = orderIndex
            B.Size = UDim2.new(1, -14, 0, 34)
            B.BackgroundColor3 = Theme.Inactive
            B.Text = ""
            B.AutoButtonColor = false
            
            local bCorner = Instance.new("UICorner", B)
            bCorner.CornerRadius = UDim.new(0, 4)
            
            local bStroke = Instance.new("UIStroke", B)
            bStroke.Color = Theme.Border
            bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local Lb = Instance.new("TextLabel", B)
            Lb.Size = UDim2.new(1, 0, 1, 0)
            Lb.BackgroundTransparency = 1
            Lb.Text = btnText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            
            B.MouseButton1Click:Connect(function() 
                TS:Create(B, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Active}):Play()
                TS:Create(Lb, TweenInfo.new(0.1), {TextColor3 = Theme.Bg}):Play()
                task.wait(0.1)
                TS:Create(B, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Inactive}):Play()
                TS:Create(Lb, TweenInfo.new(0.1), {TextColor3 = Theme.Text}):Play()
                callback() 
            end)
            
            local BO = {}
            function BO:Set(newText) 
                if newText then Lb.Text = newText end
            end
            return BO
        end
        
        function E:CreateToggle(toggleText, defaultState, callback)
            orderIndex = orderIndex + 1
            local id = tabName .. "_" .. toggleText
            
            local C = Instance.new("TextButton", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 34)
            C.BackgroundColor3 = Theme.Bg
            C.Text = ""
            C.AutoButtonColor = false
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local Lb = Instance.new("TextLabel", C)
            Lb.Size = UDim2.new(1, -60, 1, 0)
            Lb.Position = UDim2.new(0, 10, 0, 0)
            Lb.BackgroundTransparency = 1
            Lb.Text = toggleText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            
            local Tr = Instance.new("Frame", C)
            Tr.Size = UDim2.new(0, 36, 0, 18)
            Tr.Position = UDim2.new(1, -46, 0.5, -9)
            Tr.BackgroundColor3 = defaultState and Theme.Active or Theme.Inactive
            
            local trCorner = Instance.new("UICorner", Tr)
            trCorner.CornerRadius = UDim.new(1, 0)
            
            local Ci = Instance.new("Frame", Tr)
            Ci.Size = UDim2.new(0, 14, 0, 14)
            if defaultState then
                Ci.Position = UDim2.new(1, -16, 0.5, -7)
                Ci.BackgroundColor3 = Theme.Bg
            else
                Ci.Position = UDim2.new(0, 2, 0.5, -7)
                Ci.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end
            
            local ciCorner = Instance.new("UICorner", Ci)
            ciCorner.CornerRadius = UDim.new(1, 0)
            
            local currentState = defaultState
            
            local function updateToggle(newState) 
                currentState = newState
                if WO.Registry[id] then WO.Registry[id].Value = newState end
                callback(currentState)
                
                local targetColor = currentState and Theme.Active or Theme.Inactive
                local targetPos = currentState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                local targetDotColor = currentState and Theme.Bg or Color3.fromRGB(255, 255, 255)
                
                TS:Create(Tr, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                TS:Create(Ci, TweenInfo.new(0.2), {Position = targetPos, BackgroundColor3 = targetDotColor}):Play() 
            end
            
            C.MouseButton1Click:Connect(function() updateToggle(not currentState) end)
            
            local TO = {}
            function TO:Set(newState, newTitle) 
                if newTitle then Lb.Text = newTitle end
                if newState ~= nil and newState ~= currentState then updateToggle(newState) end 
            end
            
            WO.Registry[id] = { Type = "Toggle", Value = defaultState, Set = function(v) TO:Set(v) end }
            return TO
        end
        
        function E:CreateSlider(sliderText, minVal, maxVal, defaultVal, callback)
            orderIndex = orderIndex + 1
            local id = tabName .. "_" .. sliderText
            
            local C = Instance.new("Frame", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 50)
            C.BackgroundColor3 = Theme.Bg
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local Lb = Instance.new("TextLabel", C)
            Lb.Size = UDim2.new(1, -20, 0, 20)
            Lb.Position = UDim2.new(0, 10, 0, 5)
            Lb.BackgroundTransparency = 1
            Lb.Text = sliderText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            
            local VL = Instance.new("TextLabel", C)
            VL.Size = UDim2.new(0, 50, 0, 20)
            VL.Position = UDim2.new(1, -60, 0, 5)
            VL.BackgroundTransparency = 1
            VL.Text = tostring(defaultVal)
            VL.TextColor3 = Theme.Text
            VL.Font = Enum.Font.GothamBold
            VL.TextSize = 13
            VL.TextXAlignment = Enum.TextXAlignment.Right
            
            local SB = Instance.new("TextButton", C)
            SB.Size = UDim2.new(1, -20, 0, 8)
            SB.Position = UDim2.new(0, 10, 0, 30)
            SB.BackgroundColor3 = Theme.SliderBg
            SB.Text = ""
            SB.AutoButtonColor = false
            
            local sbCorner = Instance.new("UICorner", SB)
            sbCorner.CornerRadius = UDim.new(1, 0)
            
            local SF = Instance.new("Frame", SB)
            local startingScale = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
            SF.Size = UDim2.new(startingScale, 0, 1, 0)
            SF.BackgroundColor3 = Theme.Active
            
            local sfCorner = Instance.new("UICorner", SF)
            sfCorner.CornerRadius = UDim.new(1, 0)
            
            local isDragging = false
            
            local function updateSliderValue(val) 
                val = math.clamp(val, minVal, maxVal)
                local percentage = (val - minVal) / (maxVal - minVal)
                TS:Create(SF, TweenInfo.new(0.05), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
                VL.Text = tostring(val)
                if WO.Registry[id] then WO.Registry[id].Value = val end
                callback(val) 
            end
            
            local function handleInput(input) 
                local percentage = math.clamp((input.Position.X - SB.AbsolutePosition.X) / SB.AbsoluteSize.X, 0, 1)
                local val = math.floor(minVal + (maxVal - minVal) * percentage)
                updateSliderValue(val) 
            end
            
            SB.InputBegan:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    isDragging = true; handleInput(input) 
                end 
            end)
            
            table.insert(WO.Connections, UIS.InputEnded:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end 
            end))
            
            table.insert(WO.Connections, UIS.InputChanged:Connect(function(input) 
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then handleInput(input) end 
            end))
            
            local SO = {}
            function SO:Set(val) if val then updateSliderValue(val) end end
            
            WO.Registry[id] = { Type = "Slider", Value = defaultVal, Set = function(v) SO:Set(v) end }
            return SO
        end
        
        function E:CreateInput(inputText, placeholderText, clearOnLeave, callback)
            orderIndex = orderIndex + 1
            local id = tabName .. "_" .. inputText
            
            local C = Instance.new("Frame", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 34)
            C.BackgroundColor3 = Theme.Bg
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local Lb = Instance.new("TextLabel", C)
            Lb.Size = UDim2.new(0.5, 0, 1, 0)
            Lb.Position = UDim2.new(0, 10, 0, 0)
            Lb.BackgroundTransparency = 1
            Lb.Text = inputText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            
            local IB = Instance.new("TextBox", C)
            IB.Size = UDim2.new(0.5, -20, 0, 24)
            IB.Position = UDim2.new(0.5, 10, 0.5, -12)
            IB.BackgroundColor3 = Theme.DarkerBg
            IB.TextColor3 = Theme.Text
            IB.Text = ""
            IB.PlaceholderText = placeholderText
            IB.Font = Enum.Font.Gotham
            IB.TextSize = 12
            IB.ClearTextOnFocus = false
            
            local ibCorner = Instance.new("UICorner", IB)
            ibCorner.CornerRadius = UDim.new(0, 4)
            
            local ibStroke = Instance.new("UIStroke", IB)
            ibStroke.Color = Theme.Border
            ibStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            IB.FocusLost:Connect(function() 
                if WO.Registry[id] then WO.Registry[id].Value = IB.Text end
                callback(IB.Text)
                if clearOnLeave then IB.Text = "" end
            end)
            
            local IO = {}
            function IO:Set(newText, newTitle) 
                if newTitle then Lb.Text = newTitle end
                if newText then 
                    IB.Text = newText
                    if WO.Registry[id] then WO.Registry[id].Value = newText end
                    callback(newText) 
                end 
            end
            
            WO.Registry[id] = { Type = "Input", Value = "", Set = function(v) IO:Set(v) end }
            return IO
        end
        
        function E:CreateKeybind(keybindText, defaultKey, callback)
            orderIndex = orderIndex + 1
            local id = tabName .. "_" .. keybindText
            
            local C = Instance.new("Frame", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 34)
            C.BackgroundColor3 = Theme.Bg
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local Lb = Instance.new("TextLabel", C)
            Lb.Size = UDim2.new(0.5, 0, 1, 0)
            Lb.Position = UDim2.new(0, 10, 0, 0)
            Lb.BackgroundTransparency = 1
            Lb.Text = keybindText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            
            local function getKeyName(keyObj)
                if not keyObj then return "None" end
                if keyObj == Enum.UserInputType.MouseButton1 then return "MB1" end
                if keyObj == Enum.UserInputType.MouseButton2 then return "MB2" end
                if keyObj.Name then return keyObj.Name end
                return "Unknown"
            end

            local function serializeKey(k)
                if not k then return "None" end
                if typeof(k) == "EnumItem" then return tostring(k) end
                return "None"
            end

            local function deserializeKey(s)
                if s == "None" or not s then return nil end
                local parts = string.split(s, ".")
                if parts[1] == "Enum" then
                    if parts[2] == "KeyCode" then return Enum.KeyCode[parts[3]] end
                    if parts[2] == "UserInputType" then return Enum.UserInputType[parts[3]] end
                end
                return nil
            end
            
            local BB = Instance.new("TextButton", C)
            BB.Size = UDim2.new(0, 80, 0, 24)
            BB.Position = UDim2.new(1, -90, 0.5, -12)
            BB.BackgroundColor3 = Theme.DarkerBg
            BB.Text = ""
            BB.AutoButtonColor = false
            
            local bbCorner = Instance.new("UICorner", BB)
            bbCorner.CornerRadius = UDim.new(0, 4)
            
            local bbStroke = Instance.new("UIStroke", BB)
            bbStroke.Color = Theme.Border
            bbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local currentKey = defaultKey
            local listening = false 
            
            local Txt = Instance.new("TextLabel", BB)
            Txt.Size = UDim2.new(1, 0, 1, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = getKeyName(defaultKey)
            Txt.TextColor3 = Theme.Active
            Txt.Font = Enum.Font.GothamBold
            Txt.TextSize = 12
            
            BB.MouseButton1Click:Connect(function() 
                task.wait() 
                listening = true
                Txt.Text = "..."
                local connection
                connection = UIS.InputBegan:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.Keyboard then 
                        listening = false
                        if input.KeyCode == Enum.KeyCode.Backspace then 
                            currentKey = nil
                            Txt.Text = "None" 
                        else 
                            currentKey = input.KeyCode
                            Txt.Text = getKeyName(currentKey) 
                        end
                        if WO.Registry[id] then WO.Registry[id].Value = serializeKey(currentKey) end
                        
                        callback(currentKey) 
                        connection:Disconnect() 
                        
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                        listening = false
                        currentKey = input.UserInputType
                        Txt.Text = getKeyName(currentKey)
                        if WO.Registry[id] then WO.Registry[id].Value = serializeKey(currentKey) end
                        
                        callback(currentKey) 
                        connection:Disconnect()
                    end 
                end)
            end)
            
            table.insert(WO.Connections, UIS.InputBegan:Connect(function(input, gameProcessed) 
                if not listening and not gameProcessed and currentKey then
                    if input.KeyCode == currentKey or input.UserInputType == currentKey then 
                        callback(currentKey) 
                    end
                end 
            end))
            
            local KO = {}
            function KO:Set(newKey) 
                currentKey = newKey
                Txt.Text = getKeyName(newKey)
                if WO.Registry[id] then WO.Registry[id].Value = serializeKey(newKey) end
                callback(newKey)
            end
            
            WO.Registry[id] = { Type = "Keybind", Value = serializeKey(defaultKey), Set = function(v) KO:Set(deserializeKey(v)) end }
            return KO
        end
        
        function E:CreateDropdown(dropdownText, optionsArray, defaultOption, callback)
            orderIndex = orderIndex + 1
            local id = tabName .. "_" .. dropdownText
            
            local C = Instance.new("Frame", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 34)
            C.BackgroundColor3 = Theme.Bg
            C.ClipsDescendants = true
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local DB = Instance.new("TextButton", C)
            DB.Size = UDim2.new(1, 0, 0, 34)
            DB.BackgroundTransparency = 1
            DB.Text = ""
            DB.AutoButtonColor = false
            
            local Lb = Instance.new("TextLabel", DB)
            Lb.Size = UDim2.new(0.5, 0, 1, 0)
            Lb.Position = UDim2.new(0, 10, 0, 0)
            Lb.BackgroundTransparency = 1
            Lb.Text = dropdownText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            
            local SL = Instance.new("TextLabel", DB)
            SL.Size = UDim2.new(0.5, -30, 1, 0)
            SL.Position = UDim2.new(0.5, 0, 0, 0)
            SL.BackgroundTransparency = 1
            SL.Text = defaultOption
            SL.TextColor3 = Theme.Active
            SL.Font = Enum.Font.GothamBold
            SL.TextSize = 12
            SL.TextXAlignment = Enum.TextXAlignment.Right
            
            local Ic = Instance.new("TextLabel", DB)
            Ic.Size = UDim2.new(0, 20, 1, 0)
            Ic.Position = UDim2.new(1, -20, 0, 0)
            Ic.BackgroundTransparency = 1
            Ic.Text = "+"
            Ic.TextColor3 = Theme.Text
            Ic.Font = Enum.Font.GothamBold
            Ic.TextSize = 14
            
            local OC = Instance.new("Frame", C)
            OC.Size = UDim2.new(1, -20, 0, 0)
            OC.Position = UDim2.new(0, 10, 0, 34)
            OC.BackgroundTransparency = 1
            
            local ocLayout = Instance.new("UIListLayout")
            ocLayout.Padding = UDim.new(0, 2)
            ocLayout.Parent = OC
            
            local isOpen = false
            
            local function toggleDropdown() 
                isOpen = not isOpen
                Ic.Text = isOpen and "-" or "+"
                local targetHeight = isOpen and (34 + (#optionsArray * 26) + 5) or 34
                TS:Create(C, TweenInfo.new(0.2), {Size = UDim2.new(1, -14, 0, targetHeight)}):Play() 
            end
            
            DB.MouseButton1Click:Connect(toggleDropdown)
            
            local function buildOptions(arr) 
                for _, child in ipairs(OC:GetChildren()) do 
                    if child:IsA("TextButton") then child:Destroy() end 
                end
                
                for _, optionStr in ipairs(arr) do 
                    local OB = Instance.new("TextButton", OC)
                    OB.Size = UDim2.new(1, 0, 0, 24)
                    OB.BackgroundColor3 = Theme.DarkerBg
                    OB.TextColor3 = Theme.Text
                    OB.Font = Enum.Font.Gotham
                    OB.TextSize = 12
                    OB.Text = optionStr
                    OB.AutoButtonColor = false
                    
                    local obCorner = Instance.new("UICorner", OB)
                    obCorner.CornerRadius = UDim.new(0, 4)
                    
                    OB.MouseButton1Click:Connect(function() 
                        SL.Text = optionStr
                        if WO.Registry[id] then WO.Registry[id].Value = optionStr end
                        toggleDropdown()
                        callback(optionStr) 
                    end) 
                end 
            end
            
            buildOptions(optionsArray)
            
            local DO = {}
            function DO:Set(newSelection) 
                if newSelection then 
                    SL.Text = newSelection
                    if WO.Registry[id] then WO.Registry[id].Value = newSelection end
                    callback(newSelection) 
                end
            end
            function DO:Refresh(newArray, newDefault) 
                optionsArray = newArray
                buildOptions(optionsArray)
                if newDefault then DO:Set(newDefault) end
                if isOpen then 
                    local targetHeight = 34 + (#optionsArray * 26) + 5
                    TS:Create(C, TweenInfo.new(0.2), {Size = UDim2.new(1, -14, 0, targetHeight)}):Play() 
                end 
            end
            
            WO.Registry[id] = { Type = "Dropdown", Value = defaultOption, Set = function(v) DO:Set(v) end }
            return DO
        end
        
        function E:CreateColorPicker(pickerText, defaultColor, callback)
            orderIndex = orderIndex + 1
            local id = tabName .. "_" .. pickerText
            
            local C = Instance.new("Frame", TSc)
            C.LayoutOrder = orderIndex
            C.Size = UDim2.new(1, -14, 0, 34)
            C.BackgroundColor3 = Theme.Bg
            C.ClipsDescendants = true
            
            local cCorner = Instance.new("UICorner", C)
            cCorner.CornerRadius = UDim.new(0, 4)
            
            local cStroke = Instance.new("UIStroke", C)
            cStroke.Color = Theme.Border
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local PB = Instance.new("TextButton", C)
            PB.Size = UDim2.new(1, 0, 0, 34)
            PB.BackgroundTransparency = 1
            PB.Text = ""
            PB.AutoButtonColor = false
            
            local Lb = Instance.new("TextLabel", PB)
            Lb.Size = UDim2.new(0.5, 0, 1, 0)
            Lb.Position = UDim2.new(0, 10, 0, 0)
            Lb.BackgroundTransparency = 1
            Lb.Text = pickerText
            Lb.TextColor3 = Theme.Text
            Lb.Font = Enum.Font.GothamBold
            Lb.TextSize = 13
            Lb.TextXAlignment = Enum.TextXAlignment.Left
            
            local CP = Instance.new("Frame", PB)
            CP.Size = UDim2.new(0, 40, 0, 16)
            CP.Position = UDim2.new(1, -50, 0.5, -8)
            CP.BackgroundColor3 = defaultColor
            
            local cpCorner = Instance.new("UICorner", CP)
            cpCorner.CornerRadius = UDim.new(0, 4)
            
            local cpStroke = Instance.new("UIStroke", CP)
            cpStroke.Color = Theme.Border
            cpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local SF = Instance.new("Frame", C)
            SF.Size = UDim2.new(1, -20, 0, 80)
            SF.Position = UDim2.new(0, 10, 0, 34)
            SF.BackgroundTransparency = 1
            
            local sfLayout = Instance.new("UIListLayout")
            sfLayout.Padding = UDim.new(0, 5)
            sfLayout.Parent = SF
            
            local isOpen = false
            PB.MouseButton1Click:Connect(function() 
                isOpen = not isOpen
                TS:Create(C, TweenInfo.new(0.2), {Size = UDim2.new(1, -14, 0, isOpen and 120 or 34)}):Play() 
            end)
            
            local valR = defaultColor.R * 255
            local valG = defaultColor.G * 255
            local valB = defaultColor.B * 255
            
            local function serializeColor(c) return {R = c.R, G = c.G, B = c.B} end
            
            local function updateColor() 
                local newC = Color3.fromRGB(valR, valG, valB)
                CP.BackgroundColor3 = newC
                if WO.Registry[id] then WO.Registry[id].Value = serializeColor(newC) end
                callback(newC) 
            end
            
            local sliderUpdaters = {}
            
            local function createColorSlider(colorName, startValue, themeColor)
                local sliderFrame = Instance.new("Frame", SF)
                sliderFrame.Size = UDim2.new(1, 0, 0, 20)
                sliderFrame.BackgroundTransparency = 1
                
                local sliderBtn = Instance.new("TextButton", sliderFrame)
                sliderBtn.Size = UDim2.new(1, -30, 0, 6)
                sliderBtn.Position = UDim2.new(0, 0, 0.5, -3)
                sliderBtn.BackgroundColor3 = Theme.SliderBg
                sliderBtn.Text = ""
                sliderBtn.AutoButtonColor = false
                
                local sbCorner = Instance.new("UICorner", sliderBtn)
                sbCorner.CornerRadius = UDim.new(1, 0)
                
                local sliderFill = Instance.new("Frame", sliderBtn)
                sliderFill.Size = UDim2.new(startValue / 255, 0, 1, 0)
                sliderFill.BackgroundColor3 = themeColor
                
                local sfCorner = Instance.new("UICorner", sliderFill)
                sfCorner.CornerRadius = UDim.new(1, 0)
                
                local sliderValText = Instance.new("TextLabel", sliderFrame)
                sliderValText.Size = UDim2.new(0, 25, 1, 0)
                sliderValText.Position = UDim2.new(1, -25, 0, 0)
                sliderValText.BackgroundTransparency = 1
                sliderValText.Text = tostring(math.floor(startValue))
                sliderValText.TextColor3 = Theme.Text
                sliderValText.Font = Enum.Font.Gotham
                sliderValText.TextSize = 11
                
                sliderUpdaters[colorName] = function(newValue) 
                    local percentage = newValue / 255
                    TS:Create(sliderFill, TweenInfo.new(0.05), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
                    sliderValText.Text = tostring(math.floor(newValue))
                    
                    if colorName == "R" then valR = newValue elseif colorName == "G" then valG = newValue else valB = newValue end 
                end
                
                local isDragging = false
                local function handleInput(input) 
                    local percentage = math.clamp((input.Position.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
                    local newValue = math.floor(percentage * 255)
                    sliderUpdaters[colorName](newValue)
                    updateColor() 
                end
                
                sliderBtn.InputBegan:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        isDragging = true; handleInput(input) 
                    end 
                end)
                table.insert(WO.Connections, UIS.InputEnded:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        isDragging = false 
                    end 
                end))
                table.insert(WO.Connections, UIS.InputChanged:Connect(function(input) 
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                        handleInput(input) 
                    end 
                end))
            end
            
            createColorSlider("R", valR, Color3.fromRGB(255, 75, 75))
            createColorSlider("G", valG, Color3.fromRGB(75, 255, 75))
            createColorSlider("B", valB, Color3.fromRGB(75, 75, 255))
            
            local CPO = {}
            function CPO:Set(newColor, newTitle) 
                if newTitle then Lb.Text = newTitle end
                if newColor then
                    sliderUpdaters["R"](newColor.R * 255)
                    sliderUpdaters["G"](newColor.G * 255)
                    sliderUpdaters["B"](newColor.B * 255)
                    updateColor() 
                end
            end
            
            WO.Registry[id] = { Type = "ColorPicker", Value = serializeColor(defaultColor), Set = function(v) CPO:Set(Color3.new(v.R, v.G, v.B)) end }
            return CPO
        end
        return E
    end

    function WO:AddHubSettingsTab()
        if Oversimplified.HubSettingsCreated then
            return nil
        end
        Oversimplified.HubSettingsCreated = true

        local HT = self:CreateTab("Hub Settings")

        for _, btn in ipairs(TC:GetChildren()) do
            if btn:IsA("TextButton") and btn.Text == "Hub Settings" then
                btn.LayoutOrder = 99999
                break
            end
        end

        HT:CreateLabel("Hub Settings")

        HT:CreateToggle("Hub Background", Oversimplified.BackgroundVisible, function(state)
            Oversimplified.BackgroundVisible = state
            if state then
                if SG.Enabled and Backdrop.Parent then
                    Backdrop.Visible = true
                    TS:Create(Backdrop, TweenInfo.new(0.5), {BackgroundTransparency = 0.35}):Play()
                    TS:Create(fadeVal, TweenInfo.new(0.5), {Value = 0}):Play()
                end
            else
                TS:Create(Backdrop, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                TS:Create(fadeVal, TweenInfo.new(0.5), {Value = 1}):Play()
                task.delay(0.5, function() 
                    if not Oversimplified.BackgroundVisible then Backdrop.Visible = false end 
                end)
            end
        end)

        HT:CreateToggle("Hide Identity", false, function(state)
            if state then
                NameLbl.Text = "Unknown"
                Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150"
            else
                NameLbl.Text = Players.LocalPlayer.DisplayName
                Avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..Players.LocalPlayer.UserId.."&w=150&h=150"
            end
        end)
        
        HT:CreateLabel("Save Configuration")
        
        local configInputText = ""
        local selectedDropdownConfig = "None"
        
        local ConfigInput 
        local ConfigDropdown 
        
        ConfigInput = HT:CreateInput("Config Name", "Enter name...", false, function(txt)
            configInputText = txt
        end)
        
        local function getConfigs()
            local configs = {"None"}
            if isfolder and listfiles and isfolder("Oversimplified_Configs") then
                local success, files = pcall(function() return listfiles("Oversimplified_Configs") end)
                if success and files then
                    for _, file in ipairs(files) do
                        local name = file:match("([^/%\\]+)%.json$")
                        if name then table.insert(configs, name) end
                    end
                end
            end
            return configs
        end
        
        local function refreshDropdown()
            if ConfigDropdown then
                ConfigDropdown:Refresh(getConfigs(), selectedDropdownConfig)
            end
        end

        HT:CreateButton("Save Config", function()
            if configInputText == "" then
                WO:Notify("Save Failed", "Please enter a config name.", 3)
                return
            end
            
            local data = {}
            for id, info in pairs(WO.Registry) do
                data[id] = info.Value
            end
            
            if makefolder and not isfolder("Oversimplified_Configs") then 
                pcall(function() makefolder("Oversimplified_Configs") end)
            end
            
            if writefile then
                local path = "Oversimplified_Configs/" .. configInputText .. ".json"
                
                if delfile then pcall(function() delfile(path) end) end
                
                local encoded = HttpService:JSONEncode(data) .. string.rep(" ", 1000)
                
                local success, err = pcall(function()
                    writefile(path, encoded)
                end)
                
                if success then
                    selectedDropdownConfig = configInputText
                    refreshDropdown()
                    WO:Notify("Saved", "Config '" .. configInputText .. "' has been saved.", 3)
                    
                    configInputText = ""
                    if ConfigInput then ConfigInput:Set("") end
                else
                    WO:Notify("Error", "Failed to save file.", 3)
                end
            else
                WO:Notify("Error", "Your executor does not support saving files.", 3)
            end
        end)

        HT:CreateButton("Overwrite Config", function()
            if selectedDropdownConfig == "None" then
                WO:Notify("Error", "Please select a config from the dropdown to overwrite.", 3)
                return
            end
            
            local data = {}
            for id, info in pairs(WO.Registry) do
                data[id] = info.Value
            end
            
            if writefile then
                local path = "Oversimplified_Configs/" .. selectedDropdownConfig .. ".json"
                
                if delfile then pcall(function() delfile(path) end) end
                
                local encoded = HttpService:JSONEncode(data) .. string.rep(" ", 1000)
                
                local success, err = pcall(function()
                    writefile(path, encoded)
                end)
                
                if success then
                    refreshDropdown()
                    WO:Notify("Overwritten", "Config '" .. selectedDropdownConfig .. "' has been updated.", 3)
                    
                    configInputText = ""
                    if ConfigInput then ConfigInput:Set("") end
                else
                    WO:Notify("Error", "Failed to write file.", 3)
                end
            else
                WO:Notify("Error", "Your executor does not support writing/deleting files.", 3)
            end
        end)

        HT:CreateButton("Delete Config", function()
            if selectedDropdownConfig == "None" then
                WO:Notify("Error", "Please select a config from the dropdown to delete.", 3)
                return
            end
            if delfile then
                local path = "Oversimplified_Configs/" .. selectedDropdownConfig .. ".json"
                local success, err = pcall(function() delfile(path) end)
                if success then
                    WO:Notify("Deleted", "Config '" .. selectedDropdownConfig .. "' deleted.", 3)
                    selectedDropdownConfig = "None"
                    refreshDropdown()
                else
                    WO:Notify("Error", "Failed to delete file.", 3)
                end
            else
                WO:Notify("Error", "Your executor does not support deleting files.", 3)
            end
        end)

        HT:CreateLabel("Load Configuration")

        ConfigDropdown = HT:CreateDropdown("Saved Configs", getConfigs(), "None", function(sel)
            selectedDropdownConfig = sel
        end)

        HT:CreateButton("Load Config", function()
            if selectedDropdownConfig == "None" then
                WO:Notify("Error", "Please select a config to load.", 3)
                return
            end
            if readfile then
                local path = "Oversimplified_Configs/" .. selectedDropdownConfig .. ".json"
                local readSuccess, json = pcall(function() return readfile(path) end)
                
                if readSuccess and json then
                    local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(json) end)
                    
                    if decodeSuccess and type(data) == "table" then
                        for id, val in pairs(data) do
                            if WO.Registry[id] then
                                pcall(function() WO.Registry[id].Set(val) end)
                            end
                        end
                        WO:Notify("Loaded", "Config '" .. selectedDropdownConfig .. "' loaded successfully.", 3)
                    else
                        WO:Notify("Error", "Config file is corrupted or invalid.", 3)
                    end
                else
                    WO:Notify("Error", "Failed to read config file.", 3)
                end
            else
                WO:Notify("Error", "Your executor does not support reading files.", 3)
            end
        end)

        return HT
    end

    return WO
end

return Oversimplified
