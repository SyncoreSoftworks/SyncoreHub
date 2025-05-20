local Player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Syncore = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local Close = Instance.new("TextButton")
local Content = Instance.new("Frame")
local LoadingBar = Instance.new("Frame")
local LoadingProgress = Instance.new("Frame")
local LoadingText = Instance.new("TextLabel")
local InfoFrame = Instance.new("Frame")
local PlayerInfo = Instance.new("TextLabel")
local GameInfo = Instance.new("TextLabel")
local Status = Instance.new("TextLabel")
local GameIcon = Instance.new("ImageLabel")
local Decor1 = Instance.new("Frame")
local Decor2 = Instance.new("Frame")
local Logo = Instance.new("ImageLabel")

Syncore.Name = "SyncoreLoader"
Syncore.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Syncore.DisplayOrder = 999
Syncore.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = Syncore
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 30)

Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 35, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "SYNCORE LOADER"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

Logo.Name = "Logo"
Logo.Parent = TopBar
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0, 5, 0, 2)
Logo.Size = UDim2.new(0, 25, 0, 25)
Logo.Image = "rbxassetid://129534190759406"
Logo.ImageColor3 = Color3.fromRGB(0, 120, 215)

Close.Name = "Close"
Close.Parent = TopBar
Close.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(1, -30, 0, 0)
Close.Size = UDim2.new(0, 30, 1, 0)
Close.Font = Enum.Font.GothamBold
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(200, 200, 200)
Close.TextSize = 14
Close.MouseButton1Click:Connect(function()
    Syncore:Destroy()
end)

Content.Name = "Content"
Content.Parent = MainFrame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 30)
Content.Size = UDim2.new(1, 0, 1, -30)

LoadingBar.Name = "LoadingBar"
LoadingBar.Parent = Content
LoadingBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LoadingBar.BorderColor3 = Color3.fromRGB(50, 50, 50)
LoadingBar.BorderSizePixel = 1
LoadingBar.Position = UDim2.new(0.05, 0, 0.75, 0)
LoadingBar.Size = UDim2.new(0.9, 0, 0, 15)

LoadingProgress.Name = "LoadingProgress"
LoadingProgress.Parent = LoadingBar
LoadingProgress.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
LoadingProgress.BorderSizePixel = 0
LoadingProgress.Size = UDim2.new(0, 0, 1, 0)

LoadingText.Name = "LoadingText"
LoadingText.Parent = Content
LoadingText.BackgroundTransparency = 1
LoadingText.Position = UDim2.new(0.05, 0, 0.85, 0)
LoadingText.Size = UDim2.new(0.9, 0, 0, 20)
LoadingText.Font = Enum.Font.Gotham
LoadingText.Text = "Initializing..."
LoadingText.TextColor3 = Color3.fromRGB(180, 180, 180)
LoadingText.TextSize = 12
LoadingText.TextXAlignment = Enum.TextXAlignment.Left

InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = Content
InfoFrame.BackgroundTransparency = 1
InfoFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
InfoFrame.Size = UDim2.new(0.9, 0, 0, 120)

GameIcon.Name = "GameIcon"
GameIcon.Parent = InfoFrame
GameIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
GameIcon.BorderSizePixel = 0
GameIcon.Position = UDim2.new(0, 0, 0, 0)
GameIcon.Size = UDim2.new(0, 100, 0, 100)
GameIcon.Image = MarketplaceService:GetProductInfo(game.PlaceId).IconImageAssetId

PlayerInfo.Name = "PlayerInfo"
PlayerInfo.Parent = InfoFrame
PlayerInfo.BackgroundTransparency = 1
PlayerInfo.Position = UDim2.new(0, 120, 0, 0)
PlayerInfo.Size = UDim2.new(0.6, 0, 0, 50)
PlayerInfo.Font = Enum.Font.Gotham
PlayerInfo.Text = "Player: "..Player.Name.."\nUser ID: "..Player.UserId.."\nAccount Age: "..Player.AccountAge.." days"
PlayerInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
PlayerInfo.TextSize = 12
PlayerInfo.TextXAlignment = Enum.TextXAlignment.Left
PlayerInfo.TextYAlignment = Enum.TextYAlignment.Top

GameInfo.Name = "GameInfo"
GameInfo.Parent = InfoFrame
GameInfo.BackgroundTransparency = 1
GameInfo.Position = UDim2.new(0, 120, 0, 60)
GameInfo.Size = UDim2.new(0.6, 0, 0, 50)
GameInfo.Font = Enum.Font.Gotham
GameInfo.Text = "Game: "..MarketplaceService:GetProductInfo(game.PlaceId).Name.."\nPlace ID: "..game.PlaceId.."\nJob ID: "..game.JobId
GameInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
GameInfo.TextSize = 12
GameInfo.TextXAlignment = Enum.TextXAlignment.Left
GameInfo.TextYAlignment = Enum.TextYAlignment.Top

Status.Name = "Status"
Status.Parent = Content
Status.BackgroundTransparency = 1
Status.Position = UDim2.new(0.05, 0, 0.6, 0)
Status.Size = UDim2.new(0.9, 0, 0, 20)
Status.Font = Enum.Font.GothamBold
Status.Text = "Status: Checking game compatibility..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.TextSize = 14
Status.TextXAlignment = Enum.TextXAlignment.Left

Decor1.Name = "Decor1"
Decor1.Parent = MainFrame
Decor1.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
Decor1.BorderSizePixel = 0
Decor1.Position = UDim2.new(0, 0, 0, 30)
Decor1.Size = UDim2.new(1, 0, 0, 1)

Decor2.Name = "Decor2"
Decor2.Parent = MainFrame
Decor2.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
Decor2.BorderSizePixel = 0
Decor2.Position = UDim2.new(0, 0, 1, -1)
Decor2.Size = UDim2.new(1, 0, 0, 1)

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
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

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local GameScripts = {
    [94647229517154] = { -- Azure Latch
        name = "Azure Latch",
        url = "https://yourwebsite.com/scripts/azurelatch.lua"
    },
    [18687417158] = { -- Forsaken
        name = "Forsaken",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [116495829188952] = { -- Dead Rails
        name = "DeadRails",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [130739873848552] = { -- BBZ
        name = "BasketBallZero",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [13076380114] = { -- HB
        name = "Heros Battlegrounds",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [15269951959] = { -- LB
        name = "Legends Battlegrounds",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [107040934010858] = { -- PE
        name = "Project Egoist",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [18687417158] = { -- Forsaken
        name = "Forsaken",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [113318245878384] = { -- Forsaken
        name = "Project Viltrumites",
        url = "https://yourwebsite.com/scripts/forsaken.lua"
    },
        [nil] = { -- OV
        name = "VBZ",
        url = "nil"
    },
}

local UniversalScript = ""

local function ExecuteScript()
    local currentPlaceID = game.PlaceId
    local gameData = MarketplaceService:GetProductInfo(currentPlaceID)
    local supportedGame = GameScripts[currentPlaceID]
    
    local steps = {
        "Checking system integrity...",
        "Verifying game compatibility...",
        "Loading dependencies...",
        "Initializing scripts...",
        "Finalizing execution..."
    }
    
    for i, step in ipairs(steps) do
        LoadingText.Text = step
        Status.Text = "Status: "..step
        local tween = TweenService:Create(
            LoadingProgress,
            TweenInfo.new(0.5, Enum.EasingStyle.Linear),
            {Size = UDim2.new(i/#steps, 0, 1, 0)}
        )
        tween:Play()
        wait(0.7)
    end
    
    if supportedGame then
        Status.Text = "Status: Success! Supported game detected ("..supportedGame.name..")"
        LoadingText.Text = "Loading optimized script..."
        LoadingProgress.BackgroundColor3 = Color3.fromRGB(0, 200, 0)

        local success, err = pcall(function()
            loadstring(game:HttpGet(supportedGame.url))()
        end)
        
        if not success then
            LoadingText.Text = "Error loading script: "..err
            LoadingProgress.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            wait(3)
        else
            LoadingText.Text = "Successfully loaded "..supportedGame.name.." script!"
        end
    else
        Status.Text = "Status: Loading universal script"
        LoadingText.Text = "No optimized script available, loading universal..."
        LoadingProgress.BackgroundColor3 = Color3.fromRGB(200, 150, 0)

        local success, err = pcall(function()
            loadstring(game:HttpGet(UniversalScript))()
        end)
        
        if not success then
            LoadingText.Text = "Error loading universal script: "..err
            LoadingProgress.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            wait(3)
        else
            LoadingText.Text = "Successfully loaded universal script!"
        end
    end

    wait(2)
    Syncore:Destroy()
end

Syncore.Parent = game:GetService("CoreGui")
ExecuteScript()
