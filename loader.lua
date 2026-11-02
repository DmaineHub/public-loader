ocal function LoadPandaAuth()
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

local function GetSavedKey()
    if readfile and isfile and isfile(KEY_FILE) then
        local content = readfile(KEY_FILE)
        if content and content ~= "" then
            return string.gsub(content, "%s+", "")
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
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local successCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
    local targetGui = (successCore and coreGui) or LocalPlayer:WaitForChild("PlayerGui")

    if targetGui:FindFirstChild("DmaineHubKeyPrompt") then
        targetGui.DmaineHubKeyPrompt:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DmaineHubKeyPrompt"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = targetGui

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 360, 0, 190)
    Frame.Position = UDim2.new(0.5, -180, 0.5, -95)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = Color3.fromRGB(85, 105, 255)
    Stroke.Thickness = 1.8

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ DmaineHub | Secure Access"
    Title.TextColor3 = Color3.fromRGB(240, 242, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13

    local Status = Instance.new("TextLabel", Frame)
    Status.Size = UDim2.new(1, -20, 0, 20)
    Status.Position = UDim2.new(0, 10, 0, 35)
    Status.BackgroundTransparency = 1
    Status.Text = "Enter your license key to load the script"
    Status.TextColor3 = Color3.fromRGB(160, 165, 190)
    Status.Font = Enum.Font.GothamMedium
    Status.TextSize = 11

    local KeyBox = Instance.new("TextBox", Frame)
    KeyBox.Size = UDim2.new(1, -30, 0, 36)
    KeyBox.Position = UDim2.new(0, 15, 0, 65)
    KeyBox.BackgroundColor3 = Color3.fromRGB(26, 29, 44)
    KeyBox.PlaceholderText = "Paste Key Here..."
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(110, 220, 255)
    KeyBox.Font = Enum.Font.GothamBold
    KeyBox.TextSize = 12
    Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 6)

    local SubmitBtn = Instance.new("TextButton", Frame)
    SubmitBtn.Size = UDim2.new(0.48, -10, 0, 36)
    SubmitBtn.Position = UDim2.new(0, 15, 0, 115)
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(45, 185, 110)
    SubmitBtn.Text = "Submit Key"
    SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.TextSize = 12
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

    local GetKeyBtn = Instance.new("TextButton", Frame)
    GetKeyBtn.Size = UDim2.new(0.48, -10, 0, 36)
    GetKeyBtn.Position = UDim2.new(0.52, 5, 0, 115)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(85, 105, 255)
    GetKeyBtn.Text = "Get Key Link"
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 12
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 6)

    GetKeyBtn.MouseButton1Click:Connect(function()
        local url = PUSL.getKeyUrl()
        if setclipboard then
            setclipboard(url)
            Status.Text = "Key link copied to clipboard!"
            Status.TextColor3 = Color3.fromRGB(110, 220, 255)
        else
            print("[Panda Auth URL]: " .. tostring(url))
        end
    end)

    SubmitBtn.MouseButton1Click:Connect(function()
        local cleanKey = string.gsub(KeyBox.Text, "%s+", "")
        if cleanKey == "" then
            Status.Text = "Please enter a key."
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end

        Status.Text = "Validating key with PandaAuth..."
        Status.TextColor3 = Color3.fromRGB(255, 215, 80)

        task.spawn(function()
            local result = PUSL.validate(cleanKey)
            if result and result.success then
                Status.Text = "Key valid! Loading script..."
                Status.TextColor3 = Color3.fromRGB(80, 255, 120)
                
                if writefile then pcall(writefile, KEY_FILE, cleanKey) end

                local loaded = FetchAndRunScript()
                if loaded then
                    ScreenGui:Destroy()
                else
                    Status.Text = "Gateway connection error."
                    Status.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            else
                Status.Text = "Invalid or expired license key."
                Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end)
    end)
end

-- Check cached key first
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
