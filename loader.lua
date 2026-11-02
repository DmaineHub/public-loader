local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function LoadPandaAuth()
    local success, response = pcall(function()
        return game:HttpGet("https://secure.pandauth.com/pv4/lib")
    end)

    if not success or not response then
        warn("[DmaineHub] Failed to fetch PandaAuth library.")
        return nil
    end

    local loadFunc, compileErr = loadstring(response)
    if not loadFunc then
        warn("[DmaineHub] PandaAuth compile error: " .. tostring(compileErr))
        return nil
    end

    local runSuccess, lib = pcall(loadFunc)
    if not runSuccess or not lib then
        warn("[DmaineHub] PandaAuth execution error: " .. tostring(lib))
        return nil
    end

    return lib
end

local PUSL = LoadPandaAuth()
if not PUSL or type(PUSL.configure) ~= "function" then
    return warn("[DmaineHub] PandaAuth initialization failed.")
end

PUSL.configure({
    serviceId = "henceethic"
})

local GATEWAY_URL = "https://dmainehub-gateway.killerphilboy.workers.dev"
local GATEWAY_SECRET = "DmaineHub_SecurePass_9921!"
local KEY_FILE = "DmaineHub_Key.txt"
local DISCORD_URL = "https://discord.gg/k3ZnkD6eb"

local LOGO_LOCAL_PATH = "DmaineHub_Logo.png"
local LOGO_REMOTE_URL = "https://raw.githubusercontent.com/DmaineHub/public-loader/main/logo.png"

local function CleanKeyString(raw)
    if not raw then return "" end
    local cleaned = string.gsub(raw, '["\']', "")
    cleaned = string.gsub(cleaned, "%s+", "")
    return cleaned
end

local function ReadClipboard()
    local candidates = {
        getclipboard,
        get_clipboard,
        (syn and syn.get_clipboard),
        (clipboard and clipboard.get)
    }
    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then
            local success, result = pcall(fn)
            if success and type(result) == "string" and result ~= "" then
                return result
            end
        end
    end
    return nil
end

local function GetHubLogoAsset()
    if writefile and isfile and readfile then
        if not isfile(LOGO_LOCAL_PATH) then
            local success, rawBytes = pcall(function()
                return game:HttpGet(LOGO_REMOTE_URL)
            end)
            if success and rawBytes and #rawBytes > 0 then
                pcall(writefile, LOGO_LOCAL_PATH, rawBytes)
            end
        end
    end

    local customAssetFunc = getsynasset or getcustomasset
    if type(customAssetFunc) == "function" and isfile and isfile(LOGO_LOCAL_PATH) then
        local success, assetId = pcall(customAssetFunc, LOGO_LOCAL_PATH)
        if success and assetId then
            return assetId
        end
    end

    return ""
end

local function GetSavedKey()
    if readfile and isfile and isfile(KEY_FILE) then
        local content = readfile(KEY_FILE)
        if content and content ~= "" then
            return CleanKeyString(content)
        end
    end
    return nil
end

local function FetchAndRunScript()
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
    local code = nil

    if httpRequest then
        local response = httpRequest({
            Url = GATEWAY_URL,
            Method = "GET",
            Headers = {
                ["X-DmaineHub-Secret"] = GATEWAY_SECRET
            }
        })
        if response and response.StatusCode == 200 then
            code = response.Body
        end
    else
        local success, result = pcall(function()
            return game:HttpGet(GATEWAY_URL)
        end)
        if success then code = result end
    end

    if code and not string.find(code, "Unauthorized") then
        local func, err = loadstring(code)
        if func then
            func()
            return true
        else
            warn("[DmaineHub] Script parse error: " .. tostring(err))
        end
    else
        warn("[DmaineHub] Gateway denied access.")
    end
    return false
end

local function PromptKeyUI()
    local successCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
    local targetGui = (successCore and coreGui) or LocalPlayer:WaitForChild("PlayerGui")

    if targetGui:FindFirstChild("DmaineHubKeyPrompt") then
        targetGui.DmaineHubKeyPrompt:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DmaineHubKeyPrompt"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 430, 0, 275)
    MainFrame.Position = UDim2.new(0.5, -215, 0.5, -137)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 16)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.8
    MainStroke.Color = Color3.fromRGB(235, 30, 60)
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = MainFrame

    local StrokeGradient = Instance.new("UIGradient")
    StrokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 70, 95)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(220, 20, 50)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(100, 10, 25))
    })
    StrokeGradient.Rotation = 45
    StrokeGradient.Parent = MainStroke

    local dragging = false
    local dragInput, dragStart, startPos

    local HeaderHitbox = Instance.new("Frame")
    HeaderHitbox.Name = "HeaderHitbox"
    HeaderHitbox.Size = UDim2.new(1, -60, 0, 48)
    HeaderHitbox.Position = UDim2.new(0, 0, 0, 0)
    HeaderHitbox.BackgroundTransparency = 1
    HeaderHitbox.Parent = MainFrame

    HeaderHitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    HeaderHitbox.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local logoAsset = GetHubLogoAsset()

    local BrandIcon = Instance.new("ImageLabel")
    BrandIcon.Name = "BrandIcon"
    BrandIcon.Size = UDim2.new(0, 24, 0, 24)
    BrandIcon.Position = UDim2.new(0, 22, 0, 19)
    BrandIcon.BackgroundTransparency = 1
    BrandIcon.Image = logoAsset
    BrandIcon.ScaleType = Enum.ScaleType.Fit
    BrandIcon.Parent = MainFrame

    local IconGlow = Instance.new("ImageLabel")
    IconGlow.Name = "IconGlow"
    IconGlow.Size = UDim2.new(1, 4, 1, 4)
    IconGlow.Position = UDim2.new(0, -2, 0, -2)
    IconGlow.BackgroundTransparency = 1
    IconGlow.Image = logoAsset
    IconGlow.ImageColor3 = Color3.fromRGB(235, 30, 60)
    IconGlow.ImageTransparency = 0.6
    IconGlow.ScaleType = Enum.ScaleType.Fit
    IconGlow.ZIndex = BrandIcon.ZIndex - 1
    IconGlow.Parent = BrandIcon

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0, 180, 0, 32)
    TitleLabel.Position = UDim2.new(0, 52, 0, 16)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "DmaineHub"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 235, 240)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 21
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = MainFrame

    local Badge = Instance.new("Frame")
    Badge.Name = "Badge"
    Badge.Size = UDim2.new(0, 88, 0, 22)
    Badge.Position = UDim2.new(1, -142, 0, 18)
    Badge.BackgroundColor3 = Color3.fromRGB(22, 15, 20)
    Badge.BorderSizePixel = 0
    Badge.Parent = MainFrame

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 6)
    BadgeCorner.Parent = Badge

    local BadgeStroke = Instance.new("UIStroke")
    BadgeStroke.Thickness = 1
    BadgeStroke.Color = Color3.fromRGB(65, 22, 30)
    BadgeStroke.Parent = Badge

    local BadgeText = Instance.new("TextLabel")
    BadgeText.Size = UDim2.new(1, 0, 1, 0)
    BadgeText.BackgroundTransparency = 1
    BadgeText.Text = "v1.2 [ SECURE ]"
    BadgeText.TextColor3 = Color3.fromRGB(210, 180, 190)
    BadgeText.Font = Enum.Font.GothamMedium
    BadgeText.TextSize = 9
    BadgeText.Parent = Badge

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -44, 0, 16)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(26, 12, 16)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "[X]"
    CloseBtn.TextColor3 = Color3.fromRGB(235, 95, 115)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 11
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = MainFrame

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    local CloseStroke = Instance.new("UIStroke")
    CloseStroke.Thickness = 1
    CloseStroke.Color = Color3.fromRGB(120, 20, 35)
    CloseStroke.Parent = CloseBtn

    local function UnloadUI()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local frameTween = TweenService:Create(MainFrame, tweenInfo, {
            Size = UDim2.new(0, 380, 0, 240),
            Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 25, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 17),
            BackgroundTransparency = 1
        })
        frameTween:Play()
        task.delay(0.2, function()
            ScreenGui:Destroy()
            print("[DmaineHub] Authentication dismissed by user.")
        end)
    end

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(217, 4, 41),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(26, 12, 16),
            TextColor3 = Color3.fromRGB(235, 95, 115)
        }):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(UnloadUI)

    local Plate = Instance.new("Frame")
    Plate.Name = "Plate"
    Plate.Size = UDim2.new(0, 310, 0, 150)
    Plate.Position = UDim2.new(0.5, -155, 0, 60)
    Plate.BackgroundColor3 = Color3.fromRGB(28, 11, 16)
    Plate.BackgroundTransparency = 0.4
    Plate.BorderSizePixel = 0
    Plate.Parent = MainFrame

    local PlateCorner = Instance.new("UICorner")
    PlateCorner.CornerRadius = UDim.new(0, 12)
    PlateCorner.Parent = Plate

    local PlateStroke = Instance.new("UIStroke")
    PlateStroke.Thickness = 1.2
    PlateStroke.Color = Color3.fromRGB(90, 18, 30)
    PlateStroke.Parent = Plate

    local function ShakePlate()
        local origPos = UDim2.new(0.5, -155, 0, 60)
        task.spawn(function()
            for _ = 1, 3 do
                Plate.Position = origPos + UDim2.new(0, -6, 0, 0)
                task.wait(0.04)
                Plate.Position = origPos + UDim2.new(0, 6, 0, 0)
                task.wait(0.04)
            end
            Plate.Position = origPos
        end)
    end

    local KeyInputContainer = Instance.new("Frame")
    KeyInputContainer.Name = "KeyInputContainer"
    KeyInputContainer.Size = UDim2.new(1, -24, 0, 38)
    KeyInputContainer.Position = UDim2.new(0, 12, 0, 11)
    KeyInputContainer.BackgroundColor3 = Color3.fromRGB(16, 9, 13)
    KeyInputContainer.BackgroundTransparency = 0.2
    KeyInputContainer.BorderSizePixel = 0
    KeyInputContainer.Parent = Plate

    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 8)
    ContainerCorner.Parent = KeyInputContainer

    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Thickness = 1
    ContainerStroke.Color = Color3.fromRGB(70, 20, 28)
    ContainerStroke.Parent = KeyInputContainer

    local KeyBox = Instance.new("TextBox")
    KeyBox.Name = "KeyBox"
    KeyBox.Size = UDim2.new(1, -62, 1, 0)
    KeyBox.Position = UDim2.new(0, 10, 0, 0)
    KeyBox.BackgroundTransparency = 1
    KeyBox.PlaceholderText = "Paste Key Here..."
    KeyBox.PlaceholderColor3 = Color3.fromRGB(115, 80, 90)
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(255, 225, 235)
    KeyBox.Font = Enum.Font.GothamMedium
    KeyBox.TextSize = 12
    KeyBox.TextXAlignment = Enum.TextXAlignment.Left
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = KeyInputContainer

    -- Auto-Paste Button
    local PasteBtn = Instance.new("TextButton")
    PasteBtn.Name = "PasteBtn"
    PasteBtn.Size = UDim2.new(0, 48, 0, 24)
    PasteBtn.Position = UDim2.new(1, -54, 0.5, -12)
    PasteBtn.BackgroundColor3 = Color3.fromRGB(36, 14, 20)
    PasteBtn.BorderSizePixel = 0
    PasteBtn.Text = "Paste"
    PasteBtn.TextColor3 = Color3.fromRGB(240, 100, 120)
    PasteBtn.Font = Enum.Font.GothamBold
    PasteBtn.TextSize = 10
    PasteBtn.AutoButtonColor = false
    PasteBtn.Parent = KeyInputContainer

    local PasteCorner = Instance.new("UICorner")
    PasteCorner.CornerRadius = UDim.new(0, 5)
    PasteCorner.Parent = PasteBtn

    local PasteStroke = Instance.new("UIStroke")
    PasteStroke.Thickness = 1
    PasteStroke.Color = Color3.fromRGB(90, 25, 35)
    PasteStroke.Parent = PasteBtn

    PasteBtn.MouseEnter:Connect(function()
        TweenService:Create(PasteBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(217, 4, 41),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    PasteBtn.MouseLeave:Connect(function()
        TweenService:Create(PasteBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(36, 14, 20),
            TextColor3 = Color3.fromRGB(240, 100, 120)
        }):Play()
    end)

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -40, 0, 18)
    StatusLabel.Position = UDim2.new(0, 20, 0, 218)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Enter your license key to load the script"
    StatusLabel.TextColor3 = Color3.fromRGB(175, 45, 60)
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextSize = 10
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = MainFrame

    PasteBtn.MouseButton1Click:Connect(function()
        local clip = ReadClipboard()
        if clip and clip ~= "" then
            KeyBox.Text = CleanKeyString(clip)
            PasteBtn.Text = "✓"
            PasteBtn.TextColor3 = Color3.fromRGB(80, 255, 130)
            task.delay(1.2, function()
                PasteBtn.Text = "Paste"
                PasteBtn.TextColor3 = Color3.fromRGB(240, 100, 120)
            end)
        else
            StatusLabel.Text = "Clipboard is empty or inaccessible."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
            task.delay(2.5, function()
                if StatusLabel.Text == "Clipboard is empty or inaccessible." then
                    StatusLabel.Text = "Enter your license key to load the script"
                    StatusLabel.TextColor3 = Color3.fromRGB(175, 45, 60)
                end
            end)
        end
    end)

    local SubmitBtn = Instance.new("TextButton")
    SubmitBtn.Name = "SubmitBtn"
    SubmitBtn.Size = UDim2.new(1, -24, 0, 38)
    SubmitBtn.Position = UDim2.new(0, 12, 0, 56)
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(235, 30, 60)
    SubmitBtn.BorderSizePixel = 0
    SubmitBtn.Text = ""
    SubmitBtn.AutoButtonColor = false
    SubmitBtn.Parent = Plate

    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 8)
    SubmitCorner.Parent = SubmitBtn

    local SubmitGradient = Instance.new("UIGradient")
    SubmitGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 75, 105)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(195, 15, 45))
    })
    SubmitGradient.Rotation = 90
    SubmitGradient.Parent = SubmitBtn

    local SubmitLabel = Instance.new("TextLabel")
    SubmitLabel.Name = "SubmitLabel"
    SubmitLabel.Size = UDim2.new(1, 0, 1, 0)
    SubmitLabel.BackgroundTransparency = 1
    SubmitLabel.Text = "Submit Key"
    SubmitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitLabel.Font = Enum.Font.GothamBold
    SubmitLabel.TextSize = 13
    SubmitLabel.TextStrokeColor3 = Color3.fromRGB(60, 0, 15)
    SubmitLabel.TextStrokeTransparency = 0.5
    SubmitLabel.Parent = SubmitBtn

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Name = "GetKeyBtn"
    GetKeyBtn.Size = UDim2.new(1, -24, 0, 38)
    GetKeyBtn.Position = UDim2.new(0, 12, 0, 101)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 24)
    GetKeyBtn.BorderSizePixel = 0
    GetKeyBtn.Text = "Get Key Link"
    GetKeyBtn.TextColor3 = Color3.fromRGB(215, 200, 205)
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 12
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.Parent = Plate

    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 8)
    GetKeyCorner.Parent = GetKeyBtn

    local GetKeyStroke = Instance.new("UIStroke")
    GetKeyStroke.Thickness = 1
    GetKeyStroke.Color = Color3.fromRGB(60, 24, 32)
    GetKeyStroke.Parent = GetKeyBtn

    GetKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(GetKeyStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(235, 30, 60) }):Play()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
    end)
    GetKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(GetKeyStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(60, 24, 32) }):Play()
        TweenService:Create(GetKeyBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(215, 200, 205) }):Play()
    end)

    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Name = "DiscordBtn"
    DiscordBtn.Size = UDim2.new(0, 110, 0, 18)
    DiscordBtn.Position = UDim2.new(1, -125, 0, 248)
    DiscordBtn.BackgroundTransparency = 1
    DiscordBtn.Text = "💬 Join Server"
    DiscordBtn.TextColor3 = Color3.fromRGB(150, 130, 140)
    DiscordBtn.Font = Enum.Font.GothamMedium
    DiscordBtn.TextSize = 10
    DiscordBtn.TextXAlignment = Enum.TextXAlignment.Right
    DiscordBtn.Parent = MainFrame

    DiscordBtn.MouseEnter:Connect(function()
        TweenService:Create(DiscordBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 80, 110) }):Play()
    end)
    DiscordBtn.MouseLeave:Connect(function()
        TweenService:Create(DiscordBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(150, 130, 140) }):Play()
    end)
    DiscordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(DISCORD_URL)
            DiscordBtn.Text = "✓ Copied!"
            DiscordBtn.TextColor3 = Color3.fromRGB(80, 255, 130)
            task.delay(1.8, function()
                DiscordBtn.Text = "💬 Join Server"
                DiscordBtn.TextColor3 = Color3.fromRGB(150, 130, 140)
            end)
        else
            print("[DmaineHub Discord]: " .. DISCORD_URL)
        end
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        local url = PUSL.getKeyUrl()
        if setclipboard then
            setclipboard(url)
            StatusLabel.Text = "Key link copied to clipboard!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 110, 140)
        else
            print("[DmaineHub Key URL]: " .. tostring(url))
        end
    end)

    SubmitBtn.MouseButton1Click:Connect(function()
        local cleanKey = CleanKeyString(KeyBox.Text)
        if cleanKey == "" then
            StatusLabel.Text = "Please enter a key."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            ShakePlate()
            return
        end

        StatusLabel.Text = "Validating key with PandaAuth..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

        task.spawn(function()
            local result = PUSL.validate(cleanKey)
            if result and result.success then
                StatusLabel.Text = "Key valid! Loading DmaineHub..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 130)

                if writefile then pcall(writefile, KEY_FILE, cleanKey) end

                local loaded = FetchAndRunScript()
                if loaded then
                    UnloadUI()
                else
                    StatusLabel.Text = "Gateway connection error."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    ShakePlate()
                end
            else
                StatusLabel.Text = "Invalid or expired license key."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                ShakePlate()
            end
        end)
    end)
end

local cached = GetSavedKey()
if cached then
    task.spawn(function()
        local result = PUSL.validate(cached)
        if result and result.success then
            FetchAndRunScript()
        else
            PromptKeyUI()
        end
    end)
else
    PromptKeyUI()
end
