local Syncore = {}
Syncore.__index = Syncore
Syncore.Components = {}

-- Utility functions
local function Tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quadratic
    direction = direction or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = game:GetService("TweenService"):Create(obj, tweenInfo, props)
    tween:Play()
    return tween
end

local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = DeepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

local function Round(num, decimalPlaces)
    decimalPlaces = decimalPlaces or 0
    local mult = 10 ^ decimalPlaces
    return math.floor(num * mult + 0.5) / mult
end

local function RGBToHex(rgb)
    local hex = ""
    for i = 1, 3 do
        local val = math.floor(rgb[i] * 255)
        local h = string.format("%02X", val)
        hex = hex .. h
    end
    return hex
end

local function HexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        tonumber("0x"..hex:sub(1,2)) / 255,
        tonumber("0x"..hex:sub(3,4)) / 255,
        tonumber("0x"..hex:sub(5,6)) / 255
    }
end

-- Core UI styles and themes
Syncore.Themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 30),
        Foreground = Color3.fromRGB(45, 45, 45),
        Text = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(0, 162, 255),
        Shadow = Color3.fromRGB(20, 20, 20),
        Border = Color3.fromRGB(60, 60, 60)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Foreground = Color3.fromRGB(220, 220, 220),
        Text = Color3.fromRGB(30, 30, 30),
        Accent = Color3.fromRGB(0, 120, 215),
        Shadow = Color3.fromRGB(180, 180, 180),
        Border = Color3.fromRGB(200, 200, 200)
    }
}

Syncore.DefaultTheme = "Dark"

-- Base UI element class
local UIElement = {}
UIElement.__index = UIElement

function UIElement.new(parent, name)
    local self = setmetatable({}, UIElement)
    self.Name = name or "UIElement"
    self.Parent = parent
    self.Visible = true
    self.Active = true
    self.Instances = {}
    self.Children = {}
    return self
end

function UIElement:SetVisible(visible)
    self.Visible = visible
    for _, instance in pairs(self.Instances) do
        instance.Visible = visible
    end
    for _, child in pairs(self.Children) do
        child:SetVisible(visible)
    end
end

function UIElement:SetActive(active)
    self.Active = active
    for _, child in pairs(self.Children) do
        child:SetActive(active)
    end
end

function UIElement:Destroy()
    for _, instance in pairs(self.Instances) do
        instance:Destroy()
    end
    for _, child in pairs(self.Children) do
        child:Destroy()
    end
    setmetatable(self, nil)
end

-- Window component
function Syncore.CreateWindow(title, dimensions)
    local window = setmetatable({}, Syncore)
    window.Title = title or "Window"
    window.Dimensions = dimensions or UDim2.new(0, 400, 0, 300)
    window.Theme = Syncore.Themes[Syncore.DefaultTheme]
    window.Components = {}
    
    -- Create main frame
    window.MainFrame = Instance.new("Frame")
    window.MainFrame.Name = "Window"
    window.MainFrame.Size = window.Dimensions
    window.MainFrame.Position = UDim2.new(0.5, -window.Dimensions.X.Offset/2, 0.5, -window.Dimensions.Y.Offset/2)
    window.MainFrame.BackgroundColor3 = window.Theme.Background
    window.MainFrame.BorderColor3 = window.Theme.Border
    window.MainFrame.BorderSizePixel = 1
    window.MainFrame.ClipsDescendants = true
    window.MainFrame.ZIndex = 10
    
    -- Title bar
    window.TitleBar = Instance.new("Frame")
    window.TitleBar.Name = "TitleBar"
    window.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    window.TitleBar.Position = UDim2.new(0, 0, 0, 0)
    window.TitleBar.BackgroundColor3 = window.Theme.Foreground
    window.TitleBar.BorderSizePixel = 0
    window.TitleBar.ZIndex = 11
    window.TitleBar.Parent = window.MainFrame
    
    -- Title text
    window.TitleLabel = Instance.new("TextLabel")
    window.TitleLabel.Name = "Title"
    window.TitleLabel.Size = UDim2.new(1, -60, 1, 0)
    window.TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    window.TitleLabel.BackgroundTransparency = 1
    window.TitleLabel.Text = window.Title
    window.TitleLabel.TextColor3 = window.Theme.Text
    window.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    window.TitleLabel.Font = Enum.Font.SourceSansSemibold
    window.TitleLabel.TextSize = 16
    window.TitleLabel.ZIndex = 12
    window.TitleLabel.Parent = window.TitleBar
    
    -- Close button
    window.CloseButton = Instance.new("TextButton")
    window.CloseButton.Name = "CloseButton"
    window.CloseButton.Size = UDim2.new(0, 30, 0, 30)
    window.CloseButton.Position = UDim2.new(1, -30, 0, 0)
    window.CloseButton.BackgroundColor3 = window.Theme.Foreground
    window.CloseButton.BorderSizePixel = 0
    window.CloseButton.Text = "X"
    window.CloseButton.TextColor3 = window.Theme.Text
    window.CloseButton.Font = Enum.Font.SourceSansSemibold
    window.CloseButton.TextSize = 16
    window.CloseButton.ZIndex = 12
    window.CloseButton.Parent = window.TitleBar
    
    -- Content frame
    window.ContentFrame = Instance.new("Frame")
    window.ContentFrame.Name = "Content"
    window.ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    window.ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    window.ContentFrame.BackgroundTransparency = 1
    window.ContentFrame.ClipsDescendants = true
    window.ContentFrame.ZIndex = 10
    window.ContentFrame.Parent = window.MainFrame
    
    -- Make window draggable
    local dragging = false
    local dragInput, dragStart, startPos
    
    window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    window.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            window.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Close button functionality
    window.CloseButton.MouseButton1Click:Connect(function()
        window:Destroy()
    end)
    
    -- Window methods
    function window:AddComponent(component)
        table.insert(self.Components, component)
        component.Instance.Parent = self.ContentFrame
    end
    
    function window:SetTitle(newTitle)
        self.Title = newTitle
        self.TitleLabel.Text = newTitle
    end
    
    function window:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.MainFrame.BackgroundColor3 = theme.Background
            self.TitleBar.BackgroundColor3 = theme.Foreground
            self.TitleLabel.TextColor3 = theme.Text
            self.CloseButton.BackgroundColor3 = theme.Foreground
            self.CloseButton.TextColor3 = theme.Text
            
            for _, component in pairs(self.Components) do
                if component.SetTheme then
                    component:SetTheme(themeName)
                end
            end
        end
    end
    
    function window:Show()
        self.MainFrame.Visible = true
        self.Visible = true
    end
    
    function window:Hide()
        self.MainFrame.Visible = false
        self.Visible = false
    end
    
    function window:Destroy()
        for _, component in pairs(self.Components) do
            component:Destroy()
        end
        self.MainFrame:Destroy()
        setmetatable(self, nil)
    end
    
    window.MainFrame.Parent = game:GetService("CoreGui")
    return window
end

-- Button component
function Syncore.CreateButton(text, callback)
    local button = setmetatable({}, Syncore)
    button.Text = text or "Button"
    button.Callback = callback or function() end
    button.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create button instance
    button.Instance = Instance.new("TextButton")
    button.Instance.Name = "Button"
    button.Instance.Size = UDim2.new(0, 120, 0, 40)
    button.Instance.BackgroundColor3 = button.Theme.Foreground
    button.Instance.BorderColor3 = button.Theme.Border
    button.Instance.BorderSizePixel = 1
    button.Instance.Text = button.Text
    button.Instance.TextColor3 = button.Theme.Text
    button.Instance.Font = Enum.Font.SourceSansSemibold
    button.Instance.TextSize = 14
    button.Instance.AutoButtonColor = false
    button.Instance.ClipsDescendants = true
    
    -- Hover effect
    local hoverEffect = Instance.new("Frame")
    hoverEffect.Name = "HoverEffect"
    hoverEffect.Size = UDim2.new(1, 0, 1, 0)
    hoverEffect.Position = UDim2.new(0, 0, 0, 0)
    hoverEffect.BackgroundColor3 = Color3.new(1, 1, 1)
    hoverEffect.BackgroundTransparency = 0.9
    hoverEffect.BorderSizePixel = 0
    hoverEffect.ZIndex = 2
    hoverEffect.Visible = false
    hoverEffect.Parent = button.Instance
    
    -- Click effect
    local clickEffect = Instance.new("Frame")
    clickEffect.Name = "ClickEffect"
    clickEffect.Size = UDim2.new(0, 0, 0, 0)
    clickEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
    clickEffect.AnchorPoint = Vector2.new(0.5, 0.5)
    clickEffect.BackgroundColor3 = Color3.new(1, 1, 1)
    clickEffect.BackgroundTransparency = 0.8
    clickEffect.BorderSizePixel = 0
    clickEffect.ZIndex = 3
    clickEffect.Visible = false
    clickEffect.Parent = button.Instance
    
    -- Button interactions
    button.Instance.MouseEnter:Connect(function()
        hoverEffect.Visible = true
        Tween(button.Instance, {BackgroundColor3 = button.Theme.Foreground:lerp(Color3.new(1, 1, 1), 0.1)}, 0.2)
    end)
    
    button.Instance.MouseLeave:Connect(function()
        hoverEffect.Visible = false
        Tween(button.Instance, {BackgroundColor3 = button.Theme.Foreground}, 0.2)
    end)
    
    button.Instance.MouseButton1Down:Connect(function()
        clickEffect.Visible = true
        clickEffect.Size = UDim2.new(0, 0, 0, 0)
        clickEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
        Tween(clickEffect, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.5)
        Tween(button.Instance, {BackgroundColor3 = button.Theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)}, 0.1)
    end)
    
    button.Instance.MouseButton1Up:Connect(function()
        Tween(button.Instance, {BackgroundColor3 = button.Theme.Foreground:lerp(Color3.new(1, 1, 1), 0.1)}, 0.1)
        task.wait(0.1)
        button.Callback()
    end)
    
    -- Button methods
    function button:SetText(newText)
        self.Text = newText
        self.Instance.Text = newText
    end
    
    function button:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function button:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.Instance.TextColor3 = theme.Text
        end
    end
    
    function button:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return button
end

-- Slider component
function Syncore.CreateSlider(min, max, default, callback)
    local slider = setmetatable({}, Syncore)
    slider.Min = min or 0
    slider.Max = max or 100
    slider.Value = default or math.floor((max - min) / 2)
    slider.Callback = callback or function() end
    slider.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create slider instance
    slider.Instance = Instance.new("Frame")
    slider.Instance.Name = "Slider"
    slider.Instance.Size = UDim2.new(0, 200, 0, 40)
    slider.Instance.BackgroundTransparency = 1
    
    -- Track
    slider.Track = Instance.new("Frame")
    slider.Track.Name = "Track"
    slider.Track.Size = UDim2.new(1, 0, 0, 4)
    slider.Track.Position = UDim2.new(0, 0, 0.5, 0)
    slider.Track.AnchorPoint = Vector2.new(0, 0.5)
    slider.Track.BackgroundColor3 = slider.Theme.Foreground
    slider.Track.BorderColor3 = slider.Theme.Border
    slider.Track.BorderSizePixel = 1
    slider.Track.Parent = slider.Instance
    
    -- Fill
    slider.Fill = Instance.new("Frame")
    slider.Fill.Name = "Fill"
    slider.Fill.Size = UDim2.new(0, 0, 1, 0)
    slider.Fill.Position = UDim2.new(0, 0, 0, 0)
    slider.Fill.BackgroundColor3 = slider.Theme.Accent
    slider.Fill.BorderSizePixel = 0
    slider.Fill.Parent = slider.Track
    
    -- Thumb
    slider.Thumb = Instance.new("Frame")
    slider.Thumb.Name = "Thumb"
    slider.Thumb.Size = UDim2.new(0, 12, 0, 12)
    slider.Thumb.Position = UDim2.new(0, 0, 0.5, 0)
    slider.Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    slider.Thumb.BackgroundColor3 = slider.Theme.Accent
    slider.Thumb.BorderColor3 = slider.Theme.Border
    slider.Thumb.BorderSizePixel = 1
    slider.Thumb.ZIndex = 2
    Instance.new("UICorner", slider.Thumb).CornerRadius = UDim.new(1, 0)
    slider.Thumb.Parent = slider.Instance
    
    -- Value label
    slider.ValueLabel = Instance.new("TextLabel")
    slider.ValueLabel.Name = "ValueLabel"
    slider.ValueLabel.Size = UDim2.new(1, 0, 0, 20)
    slider.ValueLabel.Position = UDim2.new(0, 0, 0, 0)
    slider.ValueLabel.BackgroundTransparency = 1
    slider.ValueLabel.Text = tostring(slider.Value)
    slider.ValueLabel.TextColor3 = slider.Theme.Text
    slider.ValueLabel.Font = Enum.Font.SourceSans
    slider.ValueLabel.TextSize = 14
    slider.ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    slider.ValueLabel.Parent = slider.Instance
    
    -- Slider interactions
    local dragging = false
    
    local function updateSlider(value)
        local percent = (value - slider.Min) / (slider.Max - slider.Min)
        slider.Fill.Size = UDim2.new(percent, 0, 1, 0)
        slider.Thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        slider.ValueLabel.Text = tostring(math.floor(value))
        slider.Value = math.floor(value)
        slider.Callback(slider.Value)
    end
    
    slider.Thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    slider.Thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    slider.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local percent = (input.Position.X - slider.Track.AbsolutePosition.X) / slider.Track.AbsoluteSize.X
            local value = slider.Min + (slider.Max - slider.Min) * percent
            value = math.clamp(value, slider.Min, slider.Max)
            updateSlider(value)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = (input.Position.X - slider.Track.AbsolutePosition.X) / slider.Track.AbsoluteSize.X
            local value = slider.Min + (slider.Max - slider.Min) * percent
            value = math.clamp(value, slider.Min, slider.Max)
            updateSlider(value)
        end
    end)
    
    -- Initialize slider
    updateSlider(slider.Value)
    
    -- Slider methods
    function slider:SetValue(value)
        value = math.clamp(value, self.Min, self.Max)
        updateSlider(value)
    end
    
    function slider:SetRange(min, max)
        self.Min = min
        self.Max = max
        self:SetValue(self.Value) -- Reclamp value
    end
    
    function slider:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function slider:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Track.BackgroundColor3 = theme.Foreground
            self.Track.BorderColor3 = theme.Border
            self.Fill.BackgroundColor3 = theme.Accent
            self.Thumb.BackgroundColor3 = theme.Accent
            self.Thumb.BorderColor3 = theme.Border
            self.ValueLabel.TextColor3 = theme.Text
        end
    end
    
    function slider:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return slider
end

-- Toggle component
function Syncore.CreateToggle(text, state, callback)
    local toggle = setmetatable({}, Syncore)
    toggle.Text = text or "Toggle"
    toggle.State = state or false
    toggle.Callback = callback or function() end
    toggle.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create toggle instance
    toggle.Instance = Instance.new("Frame")
    toggle.Instance.Name = "Toggle"
    toggle.Instance.Size = UDim2.new(0, 200, 0, 30)
    toggle.Instance.BackgroundTransparency = 1
    
    -- Toggle switch
    toggle.Switch = Instance.new("Frame")
    toggle.Switch.Name = "Switch"
    toggle.Switch.Size = UDim2.new(0, 50, 0, 20)
    toggle.Switch.Position = UDim2.new(0, 0, 0.5, 0)
    toggle.Switch.AnchorPoint = Vector2.new(0, 0.5)
    toggle.Switch.BackgroundColor3 = toggle.Theme.Foreground
    toggle.Switch.BorderColor3 = toggle.Theme.Border
    toggle.Switch.BorderSizePixel = 1
    Instance.new("UICorner", toggle.Switch).CornerRadius = UDim.new(1, 0)
    toggle.Switch.Parent = toggle.Instance
    
    -- Toggle thumb
    toggle.Thumb = Instance.new("Frame")
    toggle.Thumb.Name = "Thumb"
    toggle.Thumb.Size = UDim2.new(0, 16, 0, 16)
    toggle.Thumb.Position = UDim2.new(0, 2, 0.5, 0)
    toggle.Thumb.AnchorPoint = Vector2.new(0, 0.5)
    toggle.Thumb.BackgroundColor3 = toggle.Theme.Text
    toggle.Thumb.BorderColor3 = toggle.Theme.Border
    toggle.Thumb.BorderSizePixel = 1
    Instance.new("UICorner", toggle.Thumb).CornerRadius = UDim.new(1, 0)
    toggle.Thumb.Parent = toggle.Switch
    
    -- Toggle label
    toggle.Label = Instance.new("TextLabel")
    toggle.Label.Name = "Label"
    toggle.Label.Size = UDim2.new(1, -60, 1, 0)
    toggle.Label.Position = UDim2.new(0, 60, 0, 0)
    toggle.Label.BackgroundTransparency = 1
    toggle.Label.Text = toggle.Text
    toggle.Label.TextColor3 = toggle.Theme.Text
    toggle.Label.Font = Enum.Font.SourceSans
    toggle.Label.TextSize = 14
    toggle.Label.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Label.Parent = toggle.Instance
    
    -- Update toggle appearance
    local function updateToggle()
        if toggle.State then
            Tween(toggle.Thumb, {Position = UDim2.new(1, -18, 0.5, 0), BackgroundColor3 = toggle.Theme.Accent}, 0.2)
            Tween(toggle.Switch, {BackgroundColor3 = toggle.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
        else
            Tween(toggle.Thumb, {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = toggle.Theme.Text}, 0.2)
            Tween(toggle.Switch, {BackgroundColor3 = toggle.Theme.Foreground}, 0.2)
        end
    end
    
    -- Toggle interactions
    toggle.Switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggle.State = not toggle.State
            updateToggle()
            toggle.Callback(toggle.State)
        end
    end)
    
    toggle.Label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggle.State = not toggle.State
            updateToggle()
            toggle.Callback(toggle.State)
        end
    end)
    
    -- Initialize toggle
    updateToggle()
    
    -- Toggle methods
    function toggle:SetState(state)
        self.State = state
        updateToggle()
    end
    
    function toggle:SetText(newText)
        self.Text = newText
        self.Label.Text = newText
    end
    
    function toggle:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function toggle:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Switch.BackgroundColor3 = self.State and theme.Accent:lerp(Color3.new(1, 1, 1), 0.3) or theme.Foreground
            self.Switch.BorderColor3 = theme.Border
            self.Thumb.BackgroundColor3 = self.State and theme.Accent or theme.Text
            self.Thumb.BorderColor3 = theme.Border
            self.Label.TextColor3 = theme.Text
        end
    end
    
    function toggle:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return toggle
end

-- Dropdown component
function Syncore.CreateDropdown(options, default, callback)
    local dropdown = setmetatable({}, Syncore)
    dropdown.Options = options or {"Option 1", "Option 2", "Option 3"}
    dropdown.Selected = default or options[1]
    dropdown.Callback = callback or function() end
    dropdown.Theme = Syncore.Themes[Syncore.DefaultTheme]
    dropdown.IsOpen = false
    
    -- Create dropdown instance
    dropdown.Instance = Instance.new("Frame")
    dropdown.Instance.Name = "Dropdown"
    dropdown.Instance.Size = UDim2.new(0, 200, 0, 30)
    dropdown.Instance.BackgroundTransparency = 1
    dropdown.Instance.ClipsDescendants = true
    
    -- Main button
    dropdown.MainButton = Instance.new("TextButton")
    dropdown.MainButton.Name = "MainButton"
    dropdown.MainButton.Size = UDim2.new(1, 0, 0, 30)
    dropdown.MainButton.Position = UDim2.new(0, 0, 0, 0)
    dropdown.MainButton.BackgroundColor3 = dropdown.Theme.Foreground
    dropdown.MainButton.BorderColor3 = dropdown.Theme.Border
    dropdown.MainButton.BorderSizePixel = 1
    dropdown.MainButton.Text = tostring(dropdown.Selected)
    dropdown.MainButton.TextColor3 = dropdown.Theme.Text
    dropdown.MainButton.Font = Enum.Font.SourceSans
    dropdown.MainButton.TextSize = 14
    dropdown.MainButton.TextXAlignment = Enum.TextXAlignment.Left
    dropdown.MainButton.TextTruncate = Enum.TextTruncate.AtEnd
    dropdown.MainButton.AutoButtonColor = false
    dropdown.MainButton.Parent = dropdown.Instance
    
    -- Dropdown icon
    dropdown.Icon = Instance.new("ImageLabel")
    dropdown.Icon.Name = "Icon"
    dropdown.Icon.Size = UDim2.new(0, 20, 0, 20)
    dropdown.Icon.Position = UDim2.new(1, -25, 0.5, -10)
    dropdown.Icon.AnchorPoint = Vector2.new(1, 0.5)
    dropdown.Icon.BackgroundTransparency = 1
    dropdown.Icon.Image = "rbxassetid://3926305904"
    dropdown.Icon.ImageRectOffset = Vector2.new(364, 364)
    dropdown.Icon.ImageRectSize = Vector2.new(36, 36)
    dropdown.Icon.ImageColor3 = dropdown.Theme.Text
    dropdown.Icon.Parent = dropdown.MainButton
    
    -- Options frame
    dropdown.OptionsFrame = Instance.new("Frame")
    dropdown.OptionsFrame.Name = "Options"
    dropdown.OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
    dropdown.OptionsFrame.Position = UDim2.new(0, 0, 0, 30)
    dropdown.OptionsFrame.BackgroundColor3 = dropdown.Theme.Foreground
    dropdown.OptionsFrame.BorderColor3 = dropdown.Theme.Border
    dropdown.OptionsFrame.BorderSizePixel = 1
    dropdown.OptionsFrame.ClipsDescendants = true
    dropdown.OptionsFrame.Parent = dropdown.Instance
    
    -- Options list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 1)
    listLayout.Parent = dropdown.OptionsFrame
    
    -- Create option buttons
    dropdown.OptionButtons = {}
    
    local function createOptionButtons()
        -- Clear existing buttons
        for _, button in pairs(dropdown.OptionButtons) do
            button:Destroy()
        end
        dropdown.OptionButtons = {}
        
        -- Create new buttons
        for i, option in ipairs(dropdown.Options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option"..i
            optionButton.Size = UDim2.new(1, 0, 0, 30)
            optionButton.BackgroundColor3 = dropdown.Theme.Foreground
            optionButton.BorderSizePixel = 0
            optionButton.Text = tostring(option)
            optionButton.TextColor3 = dropdown.Theme.Text
            optionButton.Font = Enum.Font.SourceSans
            optionButton.TextSize = 14
            optionButton.TextXAlignment = Enum.TextXAlignment.Left
            optionButton.AutoButtonColor = false
            optionButton.Parent = dropdown.OptionsFrame
            
            local hoverEffect = Instance.new("Frame")
            hoverEffect.Name = "HoverEffect"
            hoverEffect.Size = UDim2.new(1, 0, 1, 0)
            hoverEffect.Position = UDim2.new(0, 0, 0, 0)
            hoverEffect.BackgroundColor3 = Color3.new(1, 1, 1)
            hoverEffect.BackgroundTransparency = 0.9
            hoverEffect.BorderSizePixel = 0
            hoverEffect.ZIndex = 2
            hoverEffect.Visible = false
            hoverEffect.Parent = optionButton
            
            optionButton.MouseEnter:Connect(function()
                hoverEffect.Visible = true
                Tween(optionButton, {BackgroundColor3 = dropdown.Theme.Foreground:lerp(Color3.new(1, 1, 1), 0.1)}, 0.2)
            end)
            
            optionButton.MouseLeave:Connect(function()
                hoverEffect.Visible = false
                Tween(optionButton, {BackgroundColor3 = dropdown.Theme.Foreground}, 0.2)
            end)
            
            optionButton.MouseButton1Click:Connect(function()
                dropdown.Selected = option
                dropdown.MainButton.Text = tostring(option)
                dropdown:Toggle()
                dropdown.Callback(option)
            end)
            
            table.insert(dropdown.OptionButtons, optionButton)
        end
    end
    
    createOptionButtons()
    
    -- Dropdown interactions
    function dropdown:Toggle()
        self.IsOpen = not self.IsOpen
        
        if self.IsOpen then
            local optionCount = #self.Options
            local totalHeight = optionCount * 31 -- 30 height + 1 padding
            self.Instance.Size = UDim2.new(self.Instance.Size.X.Scale, self.Instance.Size.X.Offset, 0, 30 + totalHeight)
            Tween(self.OptionsFrame, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.2)
            Tween(self.Icon, {Rotation = 180}, 0.2)
        else
            self.Instance.Size = UDim2.new(self.Instance.Size.X.Scale, self.Instance.Size.X.Offset, 0, 30)
            Tween(self.OptionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            Tween(self.Icon, {Rotation = 0}, 0.2)
        end
    end
    
    dropdown.MainButton.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    
    -- Close dropdown when clicking outside
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dropdown.IsOpen then
                local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                local absPos = dropdown.Instance.AbsolutePosition
                local absSize = dropdown.Instance.AbsoluteSize
                
                if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                       mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                    dropdown:Toggle()
                end
            end
        end
    end)
    
    -- Dropdown methods
    function dropdown:SetOptions(newOptions)
        self.Options = newOptions or {"Option 1", "Option 2", "Option 3"}
        createOptionButtons()
    end
    
    function dropdown:SetSelected(option)
        if table.find(self.Options, option) then
            self.Selected = option
            self.MainButton.Text = tostring(option)
        end
    end
    
    function dropdown:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function dropdown:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.MainButton.BackgroundColor3 = theme.Foreground
            self.MainButton.BorderColor3 = theme.Border
            self.MainButton.TextColor3 = theme.Text
            self.Icon.ImageColor3 = theme.Text
            self.OptionsFrame.BackgroundColor3 = theme.Foreground
            self.OptionsFrame.BorderColor3 = theme.Border
            
            for _, button in pairs(self.OptionButtons) do
                button.BackgroundColor3 = theme.Foreground
                button.TextColor3 = theme.Text
            end
        end
    end
    
    function dropdown:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return dropdown
end

-- Textbox component
function Syncore.CreateTextbox(placeholder, callback)
    local textbox = setmetatable({}, Syncore)
    textbox.Placeholder = placeholder or "Enter text..."
    textbox.Callback = callback or function() end
    textbox.Theme = Syncore.Themes[Syncore.DefaultTheme]
    textbox.Text = ""
    
    -- Create textbox instance
    textbox.Instance = Instance.new("Frame")
    textbox.Instance.Name = "Textbox"
    textbox.Instance.Size = UDim2.new(0, 200, 0, 30)
    textbox.Instance.BackgroundTransparency = 1
    
    -- Textbox background
    textbox.Background = Instance.new("Frame")
    textbox.Background.Name = "Background"
    textbox.Background.Size = UDim2.new(1, 0, 1, 0)
    textbox.Background.BackgroundColor3 = textbox.Theme.Foreground
    textbox.Background.BorderColor3 = textbox.Theme.Border
    textbox.Background.BorderSizePixel = 1
    textbox.Background.Parent = textbox.Instance
    
    -- Textbox input
    textbox.Input = Instance.new("TextBox")
    textbox.Input.Name = "Input"
    textbox.Input.Size = UDim2.new(1, -10, 1, 0)
    textbox.Input.Position = UDim2.new(0, 5, 0, 0)
    textbox.Input.BackgroundTransparency = 1
    textbox.Input.PlaceholderText = textbox.Placeholder
    textbox.Input.PlaceholderColor3 = textbox.Theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
    textbox.Input.Text = ""
    textbox.Input.TextColor3 = textbox.Theme.Text
    textbox.Input.Font = Enum.Font.SourceSans
    textbox.Input.TextSize = 14
    textbox.Input.TextXAlignment = Enum.TextXAlignment.Left
    textbox.Input.ClearTextOnFocus = false
    textbox.Input.Parent = textbox.Background
    
    -- Textbox interactions
    textbox.Input.Focused:Connect(function()
        Tween(textbox.Background, {BorderColor3 = textbox.Theme.Accent}, 0.2)
    end)
    
    textbox.Input.FocusLost:Connect(function(enterPressed)
        Tween(textbox.Background, {BorderColor3 = textbox.Theme.Border}, 0.2)
        textbox.Text = textbox.Input.Text
        textbox.Callback(textbox.Text, enterPressed)
    end)
    
    -- Textbox methods
    function textbox:SetText(newText)
        self.Text = newText or ""
        self.Input.Text = newText or ""
    end
    
    function textbox:SetPlaceholder(newPlaceholder)
        self.Placeholder = newPlaceholder or "Enter text..."
        self.Input.PlaceholderText = newPlaceholder or "Enter text..."
    end
    
    function textbox:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function textbox:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Background.BackgroundColor3 = theme.Foreground
            self.Background.BorderColor3 = theme.Border
            self.Input.TextColor3 = theme.Text
            self.Input.PlaceholderColor3 = theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
        end
    end
    
    function textbox:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return textbox
end

-- Keybind component
function Syncore.CreateKeybind(key, callback)
    local keybind = setmetatable({}, Syncore)
    keybind.Key = key or Enum.KeyCode.LeftControl
    keybind.Callback = callback or function() end
    keybind.Theme = Syncore.Themes[Syncore.DefaultTheme]
    keybind.Listening = false
    
    -- Create keybind instance
    keybind.Instance = Instance.new("Frame")
    keybind.Instance.Name = "Keybind"
    keybind.Instance.Size = UDim2.new(0, 100, 0, 30)
    keybind.Instance.BackgroundTransparency = 1
    
    -- Keybind button
    keybind.Button = Instance.new("TextButton")
    keybind.Button.Name = "Button"
    keybind.Button.Size = UDim2.new(1, 0, 1, 0)
    keybind.Button.BackgroundColor3 = keybind.Theme.Foreground
    keybind.Button.BorderColor3 = keybind.Theme.Border
    keybind.Button.BorderSizePixel = 1
    keybind.Button.Text = tostring(keybind.Key):gsub("Enum.KeyCode.", "")
    keybind.Button.TextColor3 = keybind.Theme.Text
    keybind.Button.Font = Enum.Font.SourceSans
    keybind.Button.TextSize = 14
    keybind.Button.AutoButtonColor = false
    keybind.Button.Parent = keybind.Instance
    
    -- Keybind interactions
    keybind.Button.MouseButton1Click:Connect(function()
        keybind.Listening = true
        keybind.Button.Text = "..."
        Tween(keybind.Button, {BackgroundColor3 = keybind.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
    end)
    
    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if keybind.Listening and not processed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybind.Key = input.KeyCode
                keybind.Button.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                keybind.Listening = false
                Tween(keybind.Button, {BackgroundColor3 = keybind.Theme.Foreground}, 0.2)
                keybind.Callback(keybind.Key)
                connection:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                keybind.Key = input.UserInputType
                keybind.Button.Text = "Mouse1"
                keybind.Listening = false
                Tween(keybind.Button, {BackgroundColor3 = keybind.Theme.Foreground}, 0.2)
                keybind.Callback(keybind.Key)
                connection:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                keybind.Key = input.UserInputType
                keybind.Button.Text = "Mouse2"
                keybind.Listening = false
                Tween(keybind.Button, {BackgroundColor3 = keybind.Theme.Foreground}, 0.2)
                keybind.Callback(keybind.Key)
                connection:Disconnect()
            end
        end
    end)
    
    -- Keybind methods
    function keybind:SetKey(newKey)
        self.Key = newKey or Enum.KeyCode.LeftControl
        self.Button.Text = tostring(newKey):gsub("Enum.KeyCode.", "")
    end
    
    function keybind:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function keybind:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Button.BackgroundColor3 = theme.Foreground
            self.Button.BorderColor3 = theme.Border
            self.Button.TextColor3 = theme.Text
        end
    end
    
    function keybind:Destroy()
        if connection then connection:Disconnect() end
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return keybind
end

-- Notification component
function Syncore.CreateNotification(title, message, duration)
    local notification = setmetatable({}, Syncore)
    notification.Title = title or "Notification"
    notification.Message = message or "This is a notification message."
    notification.Duration = duration or 5
    notification.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create notification instance
    notification.Instance = Instance.new("Frame")
    notification.Instance.Name = "Notification"
    notification.Instance.Size = UDim2.new(0, 300, 0, 80)
    notification.Instance.Position = UDim2.new(1, -320, 1, -100)
    notification.Instance.AnchorPoint = Vector2.new(1, 1)
    notification.Instance.BackgroundColor3 = notification.Theme.Foreground
    notification.Instance.BorderColor3 = notification.Theme.Border
    notification.Instance.BorderSizePixel = 1
    notification.Instance.ClipsDescendants = true
    notification.Instance.ZIndex = 100
    
    -- Title bar
    notification.TitleBar = Instance.new("Frame")
    notification.TitleBar.Name = "TitleBar"
    notification.TitleBar.Size = UDim2.new(1, 0, 0, 25)
    notification.TitleBar.BackgroundColor3 = notification.Theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)
    notification.TitleBar.BorderSizePixel = 0
    notification.TitleBar.ZIndex = 101
    notification.TitleBar.Parent = notification.Instance
    
    -- Title text
    notification.TitleText = Instance.new("TextLabel")
    notification.TitleText.Name = "Title"
    notification.TitleText.Size = UDim2.new(1, -30, 1, 0)
    notification.TitleText.Position = UDim2.new(0, 5, 0, 0)
    notification.TitleText.BackgroundTransparency = 1
    notification.TitleText.Text = notification.Title
    notification.TitleText.TextColor3 = notification.Theme.Text
    notification.TitleText.Font = Enum.Font.SourceSansSemibold
    notification.TitleText.TextSize = 14
    notification.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    notification.TitleText.ZIndex = 102
    notification.TitleText.Parent = notification.TitleBar
    
    -- Close button
    notification.CloseButton = Instance.new("TextButton")
    notification.CloseButton.Name = "CloseButton"
    notification.CloseButton.Size = UDim2.new(0, 25, 0, 25)
    notification.CloseButton.Position = UDim2.new(1, -25, 0, 0)
    notification.CloseButton.BackgroundTransparency = 1
    notification.CloseButton.Text = "×"
    notification.CloseButton.TextColor3 = notification.Theme.Text
    notification.CloseButton.Font = Enum.Font.SourceSansBold
    notification.CloseButton.TextSize = 18
    notification.CloseButton.ZIndex = 102
    notification.CloseButton.Parent = notification.TitleBar
    
    -- Message text
    notification.MessageText = Instance.new("TextLabel")
    notification.MessageText.Name = "Message"
    notification.MessageText.Size = UDim2.new(1, -10, 1, -30)
    notification.MessageText.Position = UDim2.new(0, 5, 0, 30)
    notification.MessageText.BackgroundTransparency = 1
    notification.MessageText.Text = notification.Message
    notification.MessageText.TextColor3 = notification.Theme.Text
    notification.MessageText.Font = Enum.Font.SourceSans
    notification.MessageText.TextSize = 14
    notification.MessageText.TextXAlignment = Enum.TextXAlignment.Left
    notification.MessageText.TextYAlignment = Enum.TextYAlignment.Top
    notification.MessageText.TextWrapped = true
    notification.MessageText.ZIndex = 101
    notification.MessageText.Parent = notification.Instance
    
    -- Progress bar
    notification.ProgressBar = Instance.new("Frame")
    notification.ProgressBar.Name = "ProgressBar"
    notification.ProgressBar.Size = UDim2.new(1, 0, 0, 2)
    notification.ProgressBar.Position = UDim2.new(0, 0, 1, -2)
    notification.ProgressBar.BackgroundColor3 = notification.Theme.Accent
    notification.ProgressBar.BorderSizePixel = 0
    notification.ProgressBar.ZIndex = 102
    notification.ProgressBar.Parent = notification.Instance
    
    -- Show animation
    notification.Instance.Position = UDim2.new(1, 320, 1, -100)
    notification.Instance.Parent = game:GetService("CoreGui")
    Tween(notification.Instance, {Position = UDim2.new(1, -320, 1, -100)}, 0.3, Enum.EasingStyle.Quadratic, Enum.EasingDirection.Out)
    
    -- Progress animation
    Tween(notification.ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, notification.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
    
    -- Close functionality
    local function close()
        Tween(notification.Instance, {Position = UDim2.new(1, 320, 1, -100)}, 0.3, Enum.EasingStyle.Quadratic, Enum.EasingDirection.In):Wait()
        notification:Destroy()
    end
    
    notification.CloseButton.MouseButton1Click:Connect(close)
    
    task.delay(notification.Duration, function()
        if notification.Instance then
            close()
        end
    end)
    
    -- Notification methods
    function notification:SetTitle(newTitle)
        self.Title = newTitle or "Notification"
        self.TitleText.Text = newTitle or "Notification"
    end
    
    function notification:SetMessage(newMessage)
        self.Message = newMessage or "This is a notification message."
        self.MessageText.Text = newMessage or "This is a notification message."
    end
    
    function notification:SetDuration(newDuration)
        self.Duration = newDuration or 5
        -- Would need to restart the progress bar animation
    end
    
    function notification:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.TitleBar.BackgroundColor3 = theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)
            self.TitleText.TextColor3 = theme.Text
            self.CloseButton.TextColor3 = theme.Text
            self.MessageText.TextColor3 = theme.Text
            self.ProgressBar.BackgroundColor3 = theme.Accent
        end
    end
    
    function notification:Destroy()
        if self.Instance then
            self.Instance:Destroy()
        end
        setmetatable(self, nil)
    end
    
    return notification
end

-- Image component
function Syncore.CreateImage(imageId)
    local image = setmetatable({}, Syncore)
    image.ImageId = imageId or "rbxassetid://0"
    image.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create image instance
    image.Instance = Instance.new("ImageLabel")
    image.Instance.Name = "Image"
    image.Instance.Size = UDim2.new(0, 100, 0, 100)
    image.Instance.BackgroundTransparency = 1
    image.Instance.Image = image.ImageId
    image.Instance.ScaleType = Enum.ScaleType.Fit
    
    -- Image methods
    function image:SetImage(newImageId)
        self.ImageId = newImageId or "rbxassetid://0"
        self.Instance.Image = newImageId or "rbxassetid://0"
    end
    
    function image:SetSize(width, height)
        self.Instance.Size = UDim2.new(0, width or 100, 0, height or 100)
    end
    
    function image:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return image
end

-- Progress bar component
function Syncore.CreateProgressBar(label, progress)
    local progressBar = setmetatable({}, Syncore)
    progressBar.Label = label or "Progress"
    progressBar.Progress = math.clamp(progress or 0, 0, 1)
    progressBar.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create progress bar instance
    progressBar.Instance = Instance.new("Frame")
    progressBar.Instance.Name = "ProgressBar"
    progressBar.Instance.Size = UDim2.new(0, 200, 0, 30)
    progressBar.Instance.BackgroundTransparency = 1
    
    -- Label
    progressBar.LabelText = Instance.new("TextLabel")
    progressBar.LabelText.Name = "Label"
    progressBar.LabelText.Size = UDim2.new(1, 0, 0, 15)
    progressBar.LabelText.Position = UDim2.new(0, 0, 0, 0)
    progressBar.LabelText.BackgroundTransparency = 1
    progressBar.LabelText.Text = progressBar.Label
    progressBar.LabelText.TextColor3 = progressBar.Theme.Text
    progressBar.LabelText.Font = Enum.Font.SourceSans
    progressBar.LabelText.TextSize = 14
    progressBar.LabelText.TextXAlignment = Enum.TextXAlignment.Left
    progressBar.LabelText.Parent = progressBar.Instance
    
    -- Track
    progressBar.Track = Instance.new("Frame")
    progressBar.Track.Name = "Track"
    progressBar.Track.Size = UDim2.new(1, 0, 0, 10)
    progressBar.Track.Position = UDim2.new(0, 0, 0, 20)
    progressBar.Track.BackgroundColor3 = progressBar.Theme.Foreground
    progressBar.Track.BorderColor3 = progressBar.Theme.Border
    progressBar.Track.BorderSizePixel = 1
    progressBar.Track.Parent = progressBar.Instance
    
    -- Fill
    progressBar.Fill = Instance.new("Frame")
    progressBar.Fill.Name = "Fill"
    progressBar.Fill.Size = UDim2.new(progressBar.Progress, 0, 1, 0)
    progressBar.Fill.Position = UDim2.new(0, 0, 0, 0)
    progressBar.Fill.BackgroundColor3 = progressBar.Theme.Accent
    progressBar.Fill.BorderSizePixel = 0
    progressBar.Fill.Parent = progressBar.Track
    
    -- Percentage text
    progressBar.PercentageText = Instance.new("TextLabel")
    progressBar.PercentageText.Name = "Percentage"
    progressBar.PercentageText.Size = UDim2.new(1, 0, 0, 10)
    progressBar.PercentageText.Position = UDim2.new(0, 0, 0, 20)
    progressBar.PercentageText.BackgroundTransparency = 1
    progressBar.PercentageText.Text = string.format("%d%%", progressBar.Progress * 100)
    progressBar.PercentageText.TextColor3 = progressBar.Theme.Text
    progressBar.PercentageText.Font = Enum.Font.SourceSans
    progressBar.PercentageText.TextSize = 12
    progressBar.PercentageText.TextXAlignment = Enum.TextXAlignment.Right
    progressBar.PercentageText.Parent = progressBar.Instance
    
    -- Progress bar methods
    function progressBar:SetProgress(progress)
        self.Progress = math.clamp(progress or 0, 0, 1)
        Tween(self.Fill, {Size = UDim2.new(self.Progress, 0, 1, 0)}, 0.3)
        self.PercentageText.Text = string.format("%d%%", self.Progress * 100)
    end
    
    function progressBar:SetLabel(newLabel)
        self.Label = newLabel or "Progress"
        self.LabelText.Text = newLabel or "Progress"
    end
    
    function progressBar:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.LabelText.TextColor3 = theme.Text
            self.Track.BackgroundColor3 = theme.Foreground
            self.Track.BorderColor3 = theme.Border
            self.Fill.BackgroundColor3 = theme.Accent
            self.PercentageText.TextColor3 = theme.Text
        end
    end
    
    function progressBar:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return progressBar
end

-- Label component
function Syncore.CreateLabel(text)
    local label = setmetatable({}, Syncore)
    label.Text = text or "Label"
    label.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create label instance
    label.Instance = Instance.new("TextLabel")
    label.Instance.Name = "Label"
    label.Instance.Size = UDim2.new(0, 100, 0, 20)
    label.Instance.BackgroundTransparency = 1
    label.Instance.Text = label.Text
    label.Instance.TextColor3 = label.Theme.Text
    label.Instance.Font = Enum.Font.SourceSans
    label.Instance.TextSize = 14
    label.Instance.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Label methods
    function label:SetText(newText)
        self.Text = newText or "Label"
        self.Instance.Text = newText or "Label"
    end
    
    function label:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.TextColor3 = theme.Text
        end
    end
    
    function label:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return label
end

-- Checkbox component
function Syncore.CreateCheckbox(label, state, callback)
    local checkbox = setmetatable({}, Syncore)
    checkbox.Label = label or "Checkbox"
    checkbox.State = state or false
    checkbox.Callback = callback or function() end
    checkbox.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create checkbox instance
    checkbox.Instance = Instance.new("Frame")
    checkbox.Instance.Name = "Checkbox"
    checkbox.Instance.Size = UDim2.new(0, 150, 0, 20)
    checkbox.Instance.BackgroundTransparency = 1
    
    -- Checkbox button
    checkbox.Button = Instance.new("Frame")
    checkbox.Button.Name = "Button"
    checkbox.Button.Size = UDim2.new(0, 20, 0, 20)
    checkbox.Button.BackgroundColor3 = checkbox.Theme.Foreground
    checkbox.Button.BorderColor3 = checkbox.Theme.Border
    checkbox.Button.BorderSizePixel = 1
    checkbox.Button.Parent = checkbox.Instance
    
    -- Checkmark
    checkbox.Checkmark = Instance.new("ImageLabel")
    checkbox.Checkmark.Name = "Checkmark"
    checkbox.Checkmark.Size = UDim2.new(0, 16, 0, 16)
    checkbox.Checkmark.Position = UDim2.new(0.5, -8, 0.5, -8)
    checkbox.Checkmark.AnchorPoint = Vector2.new(0.5, 0.5)
    checkbox.Checkmark.BackgroundTransparency = 1
    checkbox.Checkmark.Image = "rbxassetid://3926305904"
    checkbox.Checkmark.ImageRectOffset = Vector2.new(100, 100)
    checkbox.Checkmark.ImageRectSize = Vector2.new(50, 50)
    checkbox.Checkmark.ImageColor3 = checkbox.Theme.Accent
    checkbox.Checkmark.Visible = checkbox.State
    checkbox.Checkmark.Parent = checkbox.Button
    
    -- Label
    checkbox.Label = Instance.new("TextLabel")
    checkbox.Label.Name = "Label"
    checkbox.Label.Size = UDim2.new(1, -30, 1, 0)
    checkbox.Label.Position = UDim2.new(0, 30, 0, 0)
    checkbox.Label.BackgroundTransparency = 1
    checkbox.Label.Text = checkbox.Label
    checkbox.Label.TextColor3 = checkbox.Theme.Text
    checkbox.Label.Font = Enum.Font.SourceSans
    checkbox.Label.TextSize = 14
    checkbox.Label.TextXAlignment = Enum.TextXAlignment.Left
    checkbox.Label.Parent = checkbox.Instance
    
    -- Update appearance
    local function updateCheckbox()
        if checkbox.State then
            checkbox.Checkmark.Visible = true
            Tween(checkbox.Button, {BackgroundColor3 = checkbox.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
        else
            checkbox.Checkmark.Visible = false
            Tween(checkbox.Button, {BackgroundColor3 = checkbox.Theme.Foreground}, 0.2)
        end
    end
    
    -- Checkbox interactions
    checkbox.Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            checkbox.State = not checkbox.State
            updateCheckbox()
            checkbox.Callback(checkbox.State)
        end
    end)
    
    checkbox.Label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            checkbox.State = not checkbox.State
            updateCheckbox()
            checkbox.Callback(checkbox.State)
        end
    end)
    
    -- Initialize checkbox
    updateCheckbox()
    
    -- Checkbox methods
    function checkbox:SetState(state)
        self.State = state
        updateCheckbox()
    end
    
    function checkbox:SetLabel(newLabel)
        self.Label = newLabel or "Checkbox"
        self.Label.Text = newLabel or "Checkbox"
    end
    
    function checkbox:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function checkbox:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Button.BackgroundColor3 = self.State and theme.Accent:lerp(Color3.new(1, 1, 1), 0.3) or theme.Foreground
            self.Button.BorderColor3 = theme.Border
            self.Checkmark.ImageColor3 = theme.Accent
            self.Label.TextColor3 = theme.Text
        end
    end
    
    function checkbox:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return checkbox
end

-- Tab component
function Syncore.CreateTab(name)
    local tab = setmetatable({}, Syncore)
    tab.Name = name or "Tab"
    tab.Theme = Syncore.Themes[Syncore.DefaultTheme]
    tab.Components = {}
    tab.Active = false
    
    -- Create tab instance
    tab.Instance = Instance.new("TextButton")
    tab.Instance.Name = "Tab"
    tab.Instance.Size = UDim2.new(0, 80, 0, 30)
    tab.Instance.BackgroundColor3 = tab.Theme.Foreground
    tab.Instance.BorderColor3 = tab.Theme.Border
    tab.Instance.BorderSizePixel = 1
    tab.Instance.Text = tab.Name
    tab.Instance.TextColor3 = tab.Theme.Text
    tab.Instance.Font = Enum.Font.SourceSans
    tab.Instance.TextSize = 14
    tab.Instance.AutoButtonColor = false
    
    -- Tab content
    tab.Content = Instance.new("Frame")
    tab.Content.Name = "Content"
    tab.Content.Size = UDim2.new(1, 0, 1, -30)
    tab.Content.Position = UDim2.new(0, 0, 0, 30)
    tab.Content.BackgroundTransparency = 1
    tab.Content.Visible = false
    
    -- Tab methods
    function tab:SetActive(active)
        self.Active = active
        if active then
            self.Content.Visible = true
            Tween(self.Instance, {BackgroundColor3 = self.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
        else
            self.Content.Visible = false
            Tween(self.Instance, {BackgroundColor3 = self.Theme.Foreground}, 0.2)
        end
    end
    
    function tab:AddComponent(component)
        table.insert(self.Components, component)
        component.Instance.Parent = self.Content
    end
    
    function tab:SetName(newName)
        self.Name = newName or "Tab"
        self.Instance.Text = newName or "Tab"
    end
    
    function tab:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = self.Active and theme.Accent:lerp(Color3.new(1, 1, 1), 0.3) or theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.Instance.TextColor3 = theme.Text
            
            for _, component in pairs(self.Components) do
                if component.SetTheme then
                    component:SetTheme(themeName)
                end
            end
        end
    end
    
    function tab:Destroy()
        for _, component in pairs(self.Components) do
            component:Destroy()
        end
        self.Instance:Destroy()
        self.Content:Destroy()
        setmetatable(self, nil)
    end
    
    return tab
end

-- Panel component
function Syncore.CreatePanel(title)
    local panel = setmetatable({}, Syncore)
    panel.Title = title or "Panel"
    panel.Theme = Syncore.Themes[Syncore.DefaultTheme]
    panel.Components = {}
    panel.IsOpen = false
    
    -- Create panel instance
    panel.Instance = Instance.new("Frame")
    panel.Instance.Name = "Panel"
    panel.Instance.Size = UDim2.new(0, 250, 1, 0)
    panel.Instance.Position = UDim2.new(0, -250, 0, 0)
    panel.Instance.BackgroundColor3 = panel.Theme.Foreground
    panel.Instance.BorderColor3 = panel.Theme.Border
    panel.Instance.BorderSizePixel = 1
    panel.Instance.ClipsDescendants = true
    
    -- Title bar
    panel.TitleBar = Instance.new("Frame")
    panel.TitleBar.Name = "TitleBar"
    panel.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    panel.TitleBar.BackgroundColor3 = panel.Theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)
    panel.TitleBar.BorderSizePixel = 0
    panel.TitleBar.Parent = panel.Instance
    
    -- Title text
    panel.TitleText = Instance.new("TextLabel")
    panel.TitleText.Name = "Title"
    panel.TitleText.Size = UDim2.new(1, -40, 1, 0)
    panel.TitleText.Position = UDim2.new(0, 10, 0, 0)
    panel.TitleText.BackgroundTransparency = 1
    panel.TitleText.Text = panel.Title
    panel.TitleText.TextColor3 = panel.Theme.Text
    panel.TitleText.Font = Enum.Font.SourceSansSemibold
    panel.TitleText.TextSize = 16
    panel.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    panel.TitleText.Parent = panel.TitleBar
    
    -- Toggle button
    panel.ToggleButton = Instance.new("TextButton")
    panel.ToggleButton.Name = "ToggleButton"
    panel.ToggleButton.Size = UDim2.new(0, 30, 0, 30)
    panel.ToggleButton.Position = UDim2.new(1, -30, 0, 0)
    panel.ToggleButton.BackgroundTransparency = 1
    panel.ToggleButton.Text = "≡"
    panel.ToggleButton.TextColor3 = panel.Theme.Text
    panel.ToggleButton.Font = Enum.Font.SourceSansBold
    panel.ToggleButton.TextSize = 20
    panel.ToggleButton.Parent = panel.TitleBar
    
    -- Content frame
    panel.Content = Instance.new("Frame")
    panel.Content.Name = "Content"
    panel.Content.Size = UDim2.new(1, -10, 1, -40)
    panel.Content.Position = UDim2.new(0, 5, 0, 35)
    panel.Content.BackgroundTransparency = 1
    panel.Content.Parent = panel.Instance
    
    -- Scrolling frame
    panel.ScrollingFrame = Instance.new("ScrollingFrame")
    panel.ScrollingFrame.Name = "ScrollingFrame"
    panel.ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    panel.ScrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    panel.ScrollingFrame.BackgroundTransparency = 1
    panel.ScrollingFrame.BorderSizePixel = 0
    panel.ScrollingFrame.ScrollBarThickness = 5
    panel.ScrollingFrame.ScrollBarImageColor3 = panel.Theme.Border
    panel.ScrollingFrame.Parent = panel.Content
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = panel.ScrollingFrame
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        panel.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
    
    -- Panel methods
    function panel:Toggle()
        self.IsOpen = not self.IsOpen
        if self.IsOpen then
            Tween(self.Instance, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
            Tween(self.ToggleButton, {Rotation = 90}, 0.3)
        else
            Tween(self.Instance, {Position = UDim2.new(0, -250, 0, 0)}, 0.3)
            Tween(self.ToggleButton, {Rotation = 0}, 0.3)
        end
    end
    
    function panel:AddComponent(component)
        table.insert(self.Components, component)
        component.Instance.Parent = self.ScrollingFrame
    end
    
    function panel:SetTitle(newTitle)
        self.Title = newTitle or "Panel"
        self.TitleText.Text = newTitle or "Panel"
    end
    
    function panel:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.TitleBar.BackgroundColor3 = theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)
            self.TitleText.TextColor3 = theme.Text
            self.ToggleButton.TextColor3 = theme.Text
            self.ScrollingFrame.ScrollBarImageColor3 = theme.Border
            
            for _, component in pairs(self.Components) do
                if component.SetTheme then
                    component:SetTheme(themeName)
                end
            end
        end
    end
    
    function panel:Destroy()
        for _, component in pairs(self.Components) do
            component:Destroy()
        end
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    -- Toggle button functionality
    panel.ToggleButton.MouseButton1Click:Connect(function()
        panel:Toggle()
    end)
    
    return panel
end

-- Radio button component
function Syncore.CreateRadioButton(options, default, callback)
    local radio = setmetatable({}, Syncore)
    radio.Options = options or {"Option 1", "Option 2", "Option 3"}
    radio.Selected = default or options[1]
    radio.Callback = callback or function() end
    radio.Theme = Syncore.Themes[Syncore.DefaultTheme]
    radio.Buttons = {}
    
    -- Create radio instance
    radio.Instance = Instance.new("Frame")
    radio.Instance.Name = "RadioButton"
    radio.Instance.Size = UDim2.new(0, 200, 0, #options * 30)
    radio.Instance.BackgroundTransparency = 1
    
    -- Create buttons
    for i, option in ipairs(radio.Options) do
        local button = Instance.new("TextButton")
        button.Name = "Option"..i
        button.Size = UDim2.new(1, 0, 0, 30)
        button.Position = UDim2.new(0, 0, 0, (i-1)*30)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = radio.Instance
        
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Name = "ButtonFrame"
        buttonFrame.Size = UDim2.new(0, 20, 0, 20)
        buttonFrame.Position = UDim2.new(0, 0, 0.5, -10)
        buttonFrame.AnchorPoint = Vector2.new(0, 0.5)
        buttonFrame.BackgroundColor3 = radio.Theme.Foreground
        buttonFrame.BorderColor3 = radio.Theme.Border
        buttonFrame.BorderSizePixel = 1
        Instance.new("UICorner", buttonFrame).CornerRadius = UDim.new(1, 0)
        buttonFrame.Parent = button
        
        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0.5, -5, 0.5, -5)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.BackgroundColor3 = radio.Theme.Accent
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        dot.Visible = (option == radio.Selected)
        dot.Parent = buttonFrame
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 30, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = option
        label.TextColor3 = radio.Theme.Text
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = button
        
        button.MouseButton1Click:Connect(function()
            radio.Selected = option
            radio.Callback(option)
            
            for _, btn in pairs(radio.Buttons) do
                btn.Dot.Visible = (btn.Option == option)
            end
        end)
        
        table.insert(radio.Buttons, {
            Instance = button,
            Dot = dot,
            Option = option
        })
    end
    
    -- Radio methods
    function radio:SetSelected(option)
        if table.find(self.Options, option) then
            self.Selected = option
            for _, btn in pairs(self.Buttons) do
                btn.Dot.Visible = (btn.Option == option)
            end
        end
    end
    
    function radio:SetOptions(newOptions, newDefault)
        self.Options = newOptions or {"Option 1", "Option 2", "Option 3"}
        self.Selected = newDefault or self.Options[1]
        
        -- Clear existing buttons
        for _, button in pairs(self.Buttons) do
            button.Instance:Destroy()
        end
        self.Buttons = {}
        
        -- Create new buttons
        for i, option in ipairs(self.Options) do
            local button = Instance.new("TextButton")
            button.Name = "Option"..i
            button.Size = UDim2.new(1, 0, 0, 30)
            button.Position = UDim2.new(0, 0, 0, (i-1)*30)
            button.BackgroundTransparency = 1
            button.Text = ""
            button.AutoButtonColor = false
            button.Parent = self.Instance
            
            local buttonFrame = Instance.new("Frame")
            buttonFrame.Name = "ButtonFrame"
            buttonFrame.Size = UDim2.new(0, 20, 0, 20)
            buttonFrame.Position = UDim2.new(0, 0, 0.5, -10)
            buttonFrame.AnchorPoint = Vector2.new(0, 0.5)
            buttonFrame.BackgroundColor3 = self.Theme.Foreground
            buttonFrame.BorderColor3 = self.Theme.Border
            buttonFrame.BorderSizePixel = 1
            Instance.new("UICorner", buttonFrame).CornerRadius = UDim.new(1, 0)
            buttonFrame.Parent = button
            
            local dot = Instance.new("Frame")
            dot.Name = "Dot"
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0.5, -5, 0.5, -5)
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.BackgroundColor3 = self.Theme.Accent
            dot.BorderSizePixel = 0
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            dot.Visible = (option == self.Selected)
            dot.Parent = buttonFrame
            
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Position = UDim2.new(0, 30, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = option
            label.TextColor3 = self.Theme.Text
            label.Font = Enum.Font.SourceSans
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = button
            
            button.MouseButton1Click:Connect(function()
                self.Selected = option
                self.Callback(option)
                
                for _, btn in pairs(self.Buttons) do
                    btn.Dot.Visible = (btn.Option == option)
                end
            end)
            
            table.insert(self.Buttons, {
                Instance = button,
                Dot = dot,
                Option = option
            })
        end
        
        self.Instance.Size = UDim2.new(self.Instance.Size.X.Scale, self.Instance.Size.X.Offset, 0, #self.Options * 30)
    end
    
    function radio:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function radio:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            for _, btn in pairs(self.Buttons) do
                btn.Instance.ButtonFrame.BackgroundColor3 = theme.Foreground
                btn.Instance.ButtonFrame.BorderColor3 = theme.Border
                btn.Instance.Dot.BackgroundColor3 = theme.Accent
                btn.Instance.Label.TextColor3 = theme.Text
            end
        end
    end
    
    function radio:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return radio
end

-- Image button component
function Syncore.CreateImageButton(imageId, callback)
    local imageButton = setmetatable({}, Syncore)
    imageButton.ImageId = imageId or "rbxassetid://0"
    imageButton.Callback = callback or function() end
    imageButton.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create image button instance
    imageButton.Instance = Instance.new("ImageButton")
    imageButton.Instance.Name = "ImageButton"
    imageButton.Instance.Size = UDim2.new(0, 50, 0, 50)
    imageButton.Instance.BackgroundTransparency = 1
    imageButton.Instance.Image = imageButton.ImageId
    imageButton.Instance.ScaleType = Enum.ScaleType.Fit
    
    -- Hover effect
    local hoverEffect = Instance.new("Frame")
    hoverEffect.Name = "HoverEffect"
    hoverEffect.Size = UDim2.new(1, 0, 1, 0)
    hoverEffect.Position = UDim2.new(0, 0, 0, 0)
    hoverEffect.BackgroundColor3 = Color3.new(1, 1, 1)
    hoverEffect.BackgroundTransparency = 0.9
    hoverEffect.BorderSizePixel = 0
    hoverEffect.ZIndex = 2
    hoverEffect.Visible = false
    hoverEffect.Parent = imageButton.Instance
    
    -- Click effect
    local clickEffect = Instance.new("Frame")
    clickEffect.Name = "ClickEffect"
    clickEffect.Size = UDim2.new(0, 0, 0, 0)
    clickEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
    clickEffect.AnchorPoint = Vector2.new(0.5, 0.5)
    clickEffect.BackgroundColor3 = Color3.new(1, 1, 1)
    clickEffect.BackgroundTransparency = 0.8
    clickEffect.BorderSizePixel = 0
    clickEffect.ZIndex = 3
    clickEffect.Visible = false
    clickEffect.Parent = imageButton.Instance
    
    -- Button interactions
    imageButton.Instance.MouseEnter:Connect(function()
        hoverEffect.Visible = true
        Tween(imageButton.Instance, {ImageColor3 = Color3.new(0.9, 0.9, 0.9)}, 0.2)
    end)
    
    imageButton.Instance.MouseLeave:Connect(function()
        hoverEffect.Visible = false
        Tween(imageButton.Instance, {ImageColor3 = Color3.new(1, 1, 1)}, 0.2)
    end)
    
    imageButton.Instance.MouseButton1Down:Connect(function()
        clickEffect.Visible = true
        clickEffect.Size = UDim2.new(0, 0, 0, 0)
        clickEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
        Tween(clickEffect, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.5)
        Tween(imageButton.Instance, {ImageColor3 = Color3.new(0.8, 0.8, 0.8)}, 0.1)
    end)
    
    imageButton.Instance.MouseButton1Up:Connect(function()
        Tween(imageButton.Instance, {ImageColor3 = Color3.new(0.9, 0.9, 0.9)}, 0.1)
        task.wait(0.1)
        imageButton.Callback()
    end)
    
    -- Image button methods
    function imageButton:SetImage(newImageId)
        self.ImageId = newImageId or "rbxassetid://0"
        self.Instance.Image = newImageId or "rbxassetid://0"
    end
    
    function imageButton:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function imageButton:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return imageButton
end

-- Color picker component
function Syncore.CreateColorPicker(name, defaultColor, callback)
    local colorPicker = setmetatable({}, Syncore)
    colorPicker.Name = name or "Color"
    colorPicker.Color = defaultColor or Color3.new(1, 1, 1)
    colorPicker.Callback = callback or function() end
    colorPicker.Theme = Syncore.Themes[Syncore.DefaultTheme]
    colorPicker.IsOpen = false
    
    -- Create color picker instance
    colorPicker.Instance = Instance.new("Frame")
    colorPicker.Instance.Name = "ColorPicker"
    colorPicker.Instance.Size = UDim2.new(0, 200, 0, 30)
    colorPicker.Instance.BackgroundTransparency = 1
    
    -- Preview
    colorPicker.Preview = Instance.new("Frame")
    colorPicker.Preview.Name = "Preview"
    colorPicker.Preview.Size = UDim2.new(0, 30, 0, 30)
    colorPicker.Preview.BackgroundColor3 = colorPicker.Color
    colorPicker.Preview.BorderColor3 = colorPicker.Theme.Border
    colorPicker.Preview.BorderSizePixel = 1
    colorPicker.Preview.Parent = colorPicker.Instance
    
    -- Label
    colorPicker.Label = Instance.new("TextLabel")
    colorPicker.Label.Name = "Label"
    colorPicker.Label.Size = UDim2.new(1, -40, 1, 0)
    colorPicker.Label.Position = UDim2.new(0, 40, 0, 0)
    colorPicker.Label.BackgroundTransparency = 1
    colorPicker.Label.Text = colorPicker.Name
    colorPicker.Label.TextColor3 = colorPicker.Theme.Text
    colorPicker.Label.Font = Enum.Font.SourceSans
    colorPicker.Label.TextSize = 14
    colorPicker.Label.TextXAlignment = Enum.TextXAlignment.Left
    colorPicker.Label.Parent = colorPicker.Instance
    
    -- Hex value
    colorPicker.HexValue = Instance.new("TextLabel")
    colorPicker.HexValue.Name = "HexValue"
    colorPicker.HexValue.Size = UDim2.new(0, 60, 0, 30)
    colorPicker.HexValue.Position = UDim2.new(1, -60, 0, 0)
    colorPicker.HexValue.BackgroundTransparency = 1
    colorPicker.HexValue.Text = RGBToHex({colorPicker.Color.R, colorPicker.Color.G, colorPicker.Color.B})
    colorPicker.HexValue.TextColor3 = colorPicker.Theme.Text
    colorPicker.HexValue.Font = Enum.Font.SourceSans
    colorPicker.HexValue.TextSize = 14
    colorPicker.HexValue.TextXAlignment = Enum.TextXAlignment.Right
    colorPicker.HexValue.Parent = colorPicker.Instance
    
    -- Picker frame
    colorPicker.PickerFrame = Instance.new("Frame")
    colorPicker.PickerFrame.Name = "PickerFrame"
    colorPicker.PickerFrame.Size = UDim2.new(0, 200, 0, 150)
    colorPicker.PickerFrame.Position = UDim2.new(0, 0, 1, 5)
    colorPicker.PickerFrame.BackgroundColor3 = colorPicker.Theme.Foreground
    colorPicker.PickerFrame.BorderColor3 = colorPicker.Theme.Border
    colorPicker.PickerFrame.BorderSizePixel = 1
    colorPicker.PickerFrame.Visible = false
    colorPicker.PickerFrame.Parent = colorPicker.Instance
    
    -- Color spectrum
    colorPicker.Spectrum = Instance.new("ImageLabel")
    colorPicker.Spectrum.Name = "Spectrum"
    colorPicker.Spectrum.Size = UDim2.new(0, 150, 0, 150)
    colorPicker.Spectrum.Position = UDim2.new(0, 5, 0, 5)
    colorPicker.Spectrum.Image = "rbxassetid://2615689005"
    colorPicker.Spectrum.BackgroundColor3 = Color3.new(1, 1, 1)
    colorPicker.Spectrum.BorderColor3 = colorPicker.Theme.Border
    colorPicker.Spectrum.BorderSizePixel = 1
    colorPicker.Spectrum.Parent = colorPicker.PickerFrame
    
    -- Spectrum selector
    colorPicker.SpectrumSelector = Instance.new("Frame")
    colorPicker.SpectrumSelector.Name = "SpectrumSelector"
    colorPicker.SpectrumSelector.Size = UDim2.new(0, 10, 0, 10)
    colorPicker.SpectrumSelector.AnchorPoint = Vector2.new(0.5, 0.5)
    colorPicker.SpectrumSelector.BackgroundTransparency = 1
    colorPicker.SpectrumSelector.BorderColor3 = Color3.new(1, 1, 1)
    colorPicker.SpectrumSelector.BorderSizePixel = 2
    Instance.new("UICorner", colorPicker.SpectrumSelector).CornerRadius = UDim.new(1, 0)
    colorPicker.SpectrumSelector.Parent = colorPicker.Spectrum
    
    -- Hue slider
    colorPicker.HueSlider = Instance.new("Frame")
    colorPicker.HueSlider.Name = "HueSlider"
    colorPicker.HueSlider.Size = UDim2.new(0, 20, 0, 150)
    colorPicker.HueSlider.Position = UDim2.new(1, -25, 0, 5)
    colorPicker.HueSlider.BackgroundColor3 = Color3.new(1, 1, 1)
    colorPicker.HueSlider.BorderColor3 = colorPicker.Theme.Border
    colorPicker.HueSlider.BorderSizePixel = 1
    colorPicker.HueSlider.Parent = colorPicker.PickerFrame
    
    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    hueGradient.Rotation = 90
    hueGradient.Parent = colorPicker.HueSlider
    
    -- Hue selector
    colorPicker.HueSelector = Instance.new("Frame")
    colorPicker.HueSelector.Name = "HueSelector"
    colorPicker.HueSelector.Size = UDim2.new(1, 0, 0, 2)
    colorPicker.HueSelector.BackgroundColor3 = Color3.new(0, 0, 0)
    colorPicker.HueSelector.BorderColor3 = Color3.new(1, 1, 1)
    colorPicker.HueSelector.BorderSizePixel = 1
    colorPicker.HueSelector.Parent = colorPicker.HueSlider
    
    -- RGB inputs
    colorPicker.RGBInputs = Instance.new("Frame")
    colorPicker.RGBInputs.Name = "RGBInputs"
    colorPicker.RGBInputs.Size = UDim2.new(1, -10, 0, 20)
    colorPicker.RGBInputs.Position = UDim2.new(0, 5, 0, 160)
    colorPicker.RGBInputs.BackgroundTransparency = 1
    colorPicker.RGBInputs.Parent = colorPicker.PickerFrame
    
    local function createRGBInput(name, index)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.Size = UDim2.new(0.33, -5, 1, 0)
        frame.Position = UDim2.new((index-1)*0.33, 0, 0, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = colorPicker.RGBInputs
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0, 15, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = colorPicker.Theme.Text
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local textBox = Instance.new("TextBox")
        textBox.Name = "Input"
        textBox.Size = UDim2.new(1, -20, 1, 0)
        textBox.Position = UDim2.new(0, 20, 0, 0)
        textBox.BackgroundColor3 = colorPicker.Theme.Foreground
        textBox.BorderColor3 = colorPicker.Theme.Border
        textBox.BorderSizePixel = 1
        textBox.Text = "255"
        textBox.TextColor3 = colorPicker.Theme.Text
        textBox.Font = Enum.Font.SourceSans
        textBox.TextSize = 14
        textBox.Parent = frame
        
        textBox.FocusLost:Connect(function()
            local value = tonumber(textBox.Text)
            if value then
                value = math.clamp(value, 0, 255)
                textBox.Text = tostring(value)
                
                local rgb = {
                    colorPicker.Color.R * 255,
                    colorPicker.Color.G * 255,
                    colorPicker.Color.B * 255
                }
                rgb[index] = value
                
                colorPicker:SetColor(Color3.fromRGB(rgb[1], rgb[2], rgb[3]))
            else
                textBox.Text = tostring(math.floor(colorPicker.Color[index] * 255))
            end
        end)
        
        return textBox
    end
    
    colorPicker.RInput = createRGBInput("R", 1)
    colorPicker.GInput = createRGBInput("G", 2)
    colorPicker.BInput = createRGBInput("B", 3)
    
    -- Color picker interactions
    local function updateColorFromSpectrum(x, y)
        local spectrumX = math.clamp(x - colorPicker.Spectrum.AbsolutePosition.X, 0, colorPicker.Spectrum.AbsoluteSize.X)
        local spectrumY = math.clamp(y - colorPicker.Spectrum.AbsolutePosition.Y, 0, colorPicker.Spectrum.AbsoluteSize.Y)
        
        local u = spectrumX / colorPicker.Spectrum.AbsoluteSize.X
        local v = spectrumY / colorPicker.Spectrum.AbsoluteSize.Y
        
        colorPicker.SpectrumSelector.Position = UDim2.new(0, spectrumX, 0, spectrumY)
        
        local hue = colorPicker.HueSelector.Position.Y.Offset / colorPicker.HueSlider.AbsoluteSize.Y
        local color = Color3.fromHSV(hue, u, 1 - v)
        colorPicker:SetColor(color)
    end
    
    local function updateColorFromHue(y)
        local hueY = math.clamp(y - colorPicker.HueSlider.AbsolutePosition.Y, 0, colorPicker.HueSlider.AbsoluteSize.Y)
        colorPicker.HueSelector.Position = UDim2.new(0, 0, 0, hueY)
        
        local hue = hueY / colorPicker.HueSlider.AbsoluteSize.Y
        local _, s, v = colorPicker.Color:ToHSV()
        local color = Color3.fromHSV(hue, s, v)
        colorPicker:SetColor(color)
    end
    
    colorPicker.Preview.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            colorPicker.IsOpen = not colorPicker.IsOpen
            colorPicker.PickerFrame.Visible = colorPicker.IsOpen
        end
    end)
    
    colorPicker.Spectrum.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateColorFromSpectrum(input.Position.X, input.Position.Y)
            
            local connection
            connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateColorFromSpectrum(input.Position.X, input.Position.Y)
                end
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    colorPicker.HueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateColorFromHue(input.Position.Y)
            
            local connection
            connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateColorFromHue(input.Position.Y)
                end
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    -- Close picker when clicking outside
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 and colorPicker.IsOpen then
            local mousePos = input.Position
            local absPos = colorPicker.PickerFrame.AbsolutePosition
            local absSize = colorPicker.PickerFrame.AbsoluteSize
            
            if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                    mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                colorPicker.IsOpen = false
                colorPicker.PickerFrame.Visible = false
            end
        end
    end)
    
    -- Color picker methods
    function colorPicker:SetColor(color)
        self.Color = color
        self.Preview.BackgroundColor3 = color
        self.HexValue.Text = RGBToHex({color.R, color.G, color.B})
        self.RInput.Text = tostring(math.floor(color.R * 255))
        self.GInput.Text = tostring(math.floor(color.G * 255))
        self.BInput.Text = tostring(math.floor(color.B * 255))
        
        local h, s, v = color:ToHSV()
        self.HueSelector.Position = UDim2.new(0, 0, 0, h * self.HueSlider.AbsoluteSize.Y)
        self.SpectrumSelector.Position = UDim2.new(0, s * self.Spectrum.AbsoluteSize.X, 0, (1 - v) * self.Spectrum.AbsoluteSize.Y)
        
        self.Callback(color)
    end
    
    function colorPicker:SetName(newName)
        self.Name = newName or "Color"
        self.Label.Text = newName or "Color"
    end
    
    function colorPicker:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function colorPicker:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Preview.BorderColor3 = theme.Border
            self.Label.TextColor3 = theme.Text
            self.HexValue.TextColor3 = theme.Text
            self.PickerFrame.BackgroundColor3 = theme.Foreground
            self.PickerFrame.BorderColor3 = theme.Border
            self.Spectrum.BorderColor3 = theme.Border
            self.HueSlider.BorderColor3 = theme.Border
            self.RInput.BackgroundColor3 = theme.Foreground
            self.RInput.BorderColor3 = theme.Border
            self.RInput.TextColor3 = theme.Text
            self.GInput.BackgroundColor3 = theme.Foreground
            self.GInput.BorderColor3 = theme.Border
            self.GInput.TextColor3 = theme.Text
            self.BInput.BackgroundColor3 = theme.Foreground
            self.BInput.BorderColor3 = theme.Border
            self.BInput.TextColor3 = theme.Text
        end
    end
    
    function colorPicker:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    -- Initialize color picker
    colorPicker:SetColor(colorPicker.Color)
    
    return colorPicker
end

-- Tooltip component
function Syncore.CreateTooltip(text)
    local tooltip = setmetatable({}, Syncore)
    tooltip.Text = text or "Tooltip"
    tooltip.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create tooltip instance
    tooltip.Instance = Instance.new("Frame")
    tooltip.Instance.Name = "Tooltip"
    tooltip.Instance.Size = UDim2.new(0, 150, 0, 40)
    tooltip.Instance.BackgroundColor3 = tooltip.Theme.Foreground
    tooltip.Instance.BorderColor3 = tooltip.Theme.Border
    tooltip.Instance.BorderSizePixel = 1
    tooltip.Instance.ZIndex = 1000
    tooltip.Instance.Visible = false
    
    -- Tooltip text
    tooltip.TextLabel = Instance.new("TextLabel")
    tooltip.TextLabel.Name = "Text"
    tooltip.TextLabel.Size = UDim2.new(1, -10, 1, -10)
    tooltip.TextLabel.Position = UDim2.new(0, 5, 0, 5)
    tooltip.TextLabel.BackgroundTransparency = 1
    tooltip.TextLabel.Text = tooltip.Text
    tooltip.TextLabel.TextColor3 = tooltip.Theme.Text
    tooltip.TextLabel.Font = Enum.Font.SourceSans
    tooltip.TextLabel.TextSize = 14
    tooltip.TextLabel.TextWrapped = true
    tooltip.TextLabel.Parent = tooltip.Instance
    
    -- Tooltip methods
    function tooltip:Show(position)
        self.Instance.Position = UDim2.new(0, position.X, 0, position.Y + 20)
        self.Instance.Visible = true
        Tween(self.Instance, {Position = UDim2.new(0, position.X, 0, position.Y), BackgroundTransparency = 0}, 0.2)
    end
    
    function tooltip:Hide()
        Tween(self.Instance, {BackgroundTransparency = 1}, 0.2).Completed:Wait()
        self.Instance.Visible = false
    end
    
    function tooltip:SetText(newText)
        self.Text = newText or "Tooltip"
        self.TextLabel.Text = newText or "Tooltip"
    end
    
    function tooltip:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.TextLabel.TextColor3 = theme.Text
        end
    end
    
    function tooltip:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    tooltip.Instance.Parent = game:GetService("CoreGui")
    return tooltip
end

-- Tooltip hover component
function Syncore.CreateTooltipHover(element, text)
    local tooltip = Syncore.CreateTooltip(text)
    
    element.MouseEnter:Connect(function()
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        tooltip:Show(Vector2.new(mouse.X, mouse.Y))
    end)
    
    element.MouseLeave:Connect(function()
        tooltip:Hide()
    end)
    
    return tooltip
end

-- Timer component
function Syncore.CreateTimer(label, time, callback)
    local timer = setmetatable({}, Syncore)
    timer.Label = label or "Timer"
    timer.Time = time or 10
    timer.Remaining = time or 10
    timer.Callback = callback or function() end
    timer.Theme = Syncore.Themes[Syncore.DefaultTheme]
    timer.Running = false
    
    -- Create timer instance
    timer.Instance = Instance.new("Frame")
    timer.Instance.Name = "Timer"
    timer.Instance.Size = UDim2.new(0, 200, 0, 40)
    timer.Instance.BackgroundTransparency = 1
    
    -- Label
    timer.LabelText = Instance.new("TextLabel")
    timer.LabelText.Name = "Label"
    timer.LabelText.Size = UDim2.new(1, 0, 0, 20)
    timer.LabelText.Position = UDim2.new(0, 0, 0, 0)
    timer.LabelText.BackgroundTransparency = 1
    timer.LabelText.Text = timer.Label
    timer.LabelText.TextColor3 = timer.Theme.Text
    timer.LabelText.Font = Enum.Font.SourceSans
    timer.LabelText.TextSize = 14
    timer.LabelText.TextXAlignment = Enum.TextXAlignment.Left
    timer.LabelText.Parent = timer.Instance
    
    -- Progress bar
    timer.ProgressBar = Instance.new("Frame")
    timer.ProgressBar.Name = "ProgressBar"
    timer.ProgressBar.Size = UDim2.new(1, 0, 0, 10)
    timer.ProgressBar.Position = UDim2.new(0, 0, 0, 25)
    timer.ProgressBar.BackgroundColor3 = timer.Theme.Foreground
    timer.ProgressBar.BorderColor3 = timer.Theme.Border
    timer.ProgressBar.BorderSizePixel = 1
    timer.ProgressBar.Parent = timer.Instance
    
    timer.ProgressFill = Instance.new("Frame")
    timer.ProgressFill.Name = "Fill"
    timer.ProgressFill.Size = UDim2.new(1, 0, 1, 0)
    timer.ProgressFill.Position = UDim2.new(0, 0, 0, 0)
    timer.ProgressFill.BackgroundColor3 = timer.Theme.Accent
    timer.ProgressFill.BorderSizePixel = 0
    timer.ProgressFill.Parent = timer.ProgressBar
    
    -- Time text
    timer.TimeText = Instance.new("TextLabel")
    timer.TimeText.Name = "Time"
    timer.TimeText.Size = UDim2.new(1, 0, 0, 10)
    timer.TimeText.Position = UDim2.new(0, 0, 0, 25)
    timer.TimeText.BackgroundTransparency = 1
    timer.TimeText.Text = string.format("%.1f", timer.Remaining)
    timer.TimeText.TextColor3 = timer.Theme.Text
    timer.TimeText.Font = Enum.Font.SourceSans
    timer.TimeText.TextSize = 12
    timer.TimeText.TextXAlignment = Enum.TextXAlignment.Right
    timer.TimeText.Parent = timer.Instance
    
    -- Timer methods
    function timer:Start()
        if self.Running then return end
        self.Running = true
        self.Remaining = self.Time
        
        local startTime = tick()
        while self.Running and self.Remaining > 0 do
            local elapsed = tick() - startTime
            self.Remaining = math.max(0, self.Time - elapsed)
            
            local progress = self.Remaining / self.Time
            self.ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
            self.TimeText.Text = string.format("%.1f", self.Remaining)
            
            task.wait(0.1)
        end
        
        if self.Remaining <= 0 then
            self.Callback()
        end
    end
    
    function timer:Stop()
        self.Running = false
    end
    
    function timer:Reset()
        self:Stop()
        self.Remaining = self.Time
        self.ProgressFill.Size = UDim2.new(1, 0, 1, 0)
        self.TimeText.Text = string.format("%.1f", self.Remaining)
    end
    
    function timer:SetTime(newTime)
        self.Time = newTime or 10
        self:Reset()
    end
    
    function timer:SetLabel(newLabel)
        self.Label = newLabel or "Timer"
        self.LabelText.Text = newLabel or "Timer"
    end
    
    function timer:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function timer:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.LabelText.TextColor3 = theme.Text
            self.ProgressBar.BackgroundColor3 = theme.Foreground
            self.ProgressBar.BorderColor3 = theme.Border
            self.ProgressFill.BackgroundColor3 = theme.Accent
            self.TimeText.TextColor3 = theme.Text
        end
    end
    
    function timer:Destroy()
        self:Stop()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return timer
end

-- Context menu component
function Syncore.CreateContextMenu(options, callback)
    local contextMenu = setmetatable({}, Syncore)
    contextMenu.Options = options or {"Option 1", "Option 2", "Option 3"}
    contextMenu.Callback = callback or function() end
    contextMenu.Theme = Syncore.Themes[Syncore.DefaultTheme]
    contextMenu.Visible = false
    
    -- Create context menu instance
    contextMenu.Instance = Instance.new("Frame")
    contextMenu.Instance.Name = "ContextMenu"
    contextMenu.Instance.Size = UDim2.new(0, 150, 0, #options * 30)
    contextMenu.Instance.BackgroundColor3 = contextMenu.Theme.Foreground
    contextMenu.Instance.BorderColor3 = contextMenu.Theme.Border
    contextMenu.Instance.BorderSizePixel = 1
    contextMenu.Instance.Visible = false
    contextMenu.Instance.ZIndex = 1000
    
    -- Create options
    contextMenu.OptionButtons = {}
    
    for i, option in ipairs(contextMenu.Options) do
        local button = Instance.new("TextButton")
        button.Name = "Option"..i
        button.Size = UDim2.new(1, 0, 0, 30)
        button.Position = UDim2.new(0, 0, 0, (i-1)*30)
        button.BackgroundColor3 = contextMenu.Theme.Foreground
        button.BorderSizePixel = 0
        button.Text = option
        button.TextColor3 = contextMenu.Theme.Text
        button.Font = Enum.Font.SourceSans
        button.TextSize = 14
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.AutoButtonColor = false
        button.Parent = contextMenu.Instance
        
        local hoverEffect = Instance.new("Frame")
        hoverEffect.Name = "HoverEffect"
        hoverEffect.Size = UDim2.new(1, 0, 1, 0)
        hoverEffect.Position = UDim2.new(0, 0, 0, 0)
        hoverEffect.BackgroundColor3 = Color3.new(1, 1, 1)
        hoverEffect.BackgroundTransparency = 0.9
        hoverEffect.BorderSizePixel = 0
        hoverEffect.ZIndex = 1001
        hoverEffect.Visible = false
        hoverEffect.Parent = button
        
        button.MouseEnter:Connect(function()
            hoverEffect.Visible = true
            Tween(button, {BackgroundColor3 = contextMenu.Theme.Foreground:lerp(Color3.new(1, 1, 1), 0.1)}, 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            hoverEffect.Visible = false
            Tween(button, {BackgroundColor3 = contextMenu.Theme.Foreground}, 0.2)
        end)
        
        button.MouseButton1Click:Connect(function()
            contextMenu:Hide()
            contextMenu.Callback(option)
        end)
        
        table.insert(contextMenu.OptionButtons, button)
    end
    
    -- Context menu methods
    function contextMenu:Show(position)
        self.Instance.Position = UDim2.new(0, position.X, 0, position.Y)
        self.Instance.Visible = true
        self.Visible = true
    end
    
    function contextMenu:Hide()
        self.Instance.Visible = false
        self.Visible = false
    end
    
    function contextMenu:SetOptions(newOptions)
        self.Options = newOptions or {"Option 1", "Option 2", "Option 3"}
        
        -- Clear existing buttons
        for _, button in pairs(self.OptionButtons) do
            button:Destroy()
        end
        self.OptionButtons = {}
        
        -- Create new buttons
        for i, option in ipairs(self.Options) do
            local button = Instance.new("TextButton")
            button.Name = "Option"..i
            button.Size = UDim2.new(1, 0, 0, 30)
            button.Position = UDim2.new(0, 0, 0, (i-1)*30)
            button.BackgroundColor3 = self.Theme.Foreground
            button.BorderSizePixel = 0
            button.Text = option
            button.TextColor3 = self.Theme.Text
            button.Font = Enum.Font.SourceSans
            button.TextSize = 14
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.AutoButtonColor = false
            button.Parent = self.Instance
            
            local hoverEffect = Instance.new("Frame")
            hoverEffect.Name = "HoverEffect"
            hoverEffect.Size = UDim2.new(1, 0, 1, 0)
            hoverEffect.Position = UDim2.new(0, 0, 0, 0)
            hoverEffect.BackgroundColor3 = Color3.new(1, 1, 1)
            hoverEffect.BackgroundTransparency = 0.9
            hoverEffect.BorderSizePixel = 0
            hoverEffect.ZIndex = 1001
            hoverEffect.Visible = false
            hoverEffect.Parent = button
            
            button.MouseEnter:Connect(function()
                hoverEffect.Visible = true
                Tween(button, {BackgroundColor3 = self.Theme.Foreground:lerp(Color3.new(1, 1, 1), 0.1)}, 0.2)
            end)
            
            button.MouseLeave:Connect(function()
                hoverEffect.Visible = false
                Tween(button, {BackgroundColor3 = self.Theme.Foreground}, 0.2)
            end)
            
            button.MouseButton1Click:Connect(function()
                self:Hide()
                self.Callback(option)
            end)
            
            table.insert(self.OptionButtons, button)
        end
        
        self.Instance.Size = UDim2.new(self.Instance.Size.X.Scale, self.Instance.Size.X.Offset, 0, #self.Options * 30)
    end
    
    function contextMenu:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function contextMenu:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            
            for _, button in pairs(self.OptionButtons) do
                button.BackgroundColor3 = theme.Foreground
                button.TextColor3 = theme.Text
            end
        end
    end
    
    function contextMenu:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    -- Close menu when clicking outside
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 and self.Visible then
            local mousePos = input.Position
            local absPos = self.Instance.AbsolutePosition
            local absSize = self.Instance.AbsoluteSize
            
            if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                    mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                self:Hide()
            end
        end
    end)
    
    contextMenu.Instance.Parent = game:GetService("CoreGui")
    return contextMenu
end

-- Search bar component
function Syncore.CreateSearchBar(placeholder, callback)
    local searchBar = setmetatable({}, Syncore)
    searchBar.Placeholder = placeholder or "Search..."
    searchBar.Callback = callback or function() end
    searchBar.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create search bar instance
    searchBar.Instance = Instance.new("Frame")
    searchBar.Instance.Name = "SearchBar"
    searchBar.Instance.Size = UDim2.new(0, 200, 0, 30)
    searchBar.Instance.BackgroundTransparency = 1
    
    -- Background
    searchBar.Background = Instance.new("Frame")
    searchBar.Background.Name = "Background"
    searchBar.Background.Size = UDim2.new(1, 0, 1, 0)
    searchBar.Background.BackgroundColor3 = searchBar.Theme.Foreground
    searchBar.Background.BorderColor3 = searchBar.Theme.Border
    searchBar.Background.BorderSizePixel = 1
    searchBar.Background.Parent = searchBar.Instance
    
    -- Search icon
    searchBar.Icon = Instance.new("ImageLabel")
    searchBar.Icon.Name = "Icon"
    searchBar.Icon.Size = UDim2.new(0, 20, 0, 20)
    searchBar.Icon.Position = UDim2.new(0, 5, 0.5, -10)
    searchBar.Icon.AnchorPoint = Vector2.new(0, 0.5)
    searchBar.Icon.BackgroundTransparency = 1
    searchBar.Icon.Image = "rbxassetid://3926305904"
    searchBar.Icon.ImageRectOffset = Vector2.new(964, 324)
    searchBar.Icon.ImageRectSize = Vector2.new(36, 36)
    searchBar.Icon.ImageColor3 = searchBar.Theme.Text
    searchBar.Icon.Parent = searchBar.Background
    
    -- Input box
    searchBar.Input = Instance.new("TextBox")
    searchBar.Input.Name = "Input"
    searchBar.Input.Size = UDim2.new(1, -35, 1, 0)
    searchBar.Input.Position = UDim2.new(0, 30, 0, 0)
    searchBar.Input.BackgroundTransparency = 1
    searchBar.Input.PlaceholderText = searchBar.Placeholder
    searchBar.Input.PlaceholderColor3 = searchBar.Theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
    searchBar.Input.Text = ""
    searchBar.Input.TextColor3 = searchBar.Theme.Text
    searchBar.Input.Font = Enum.Font.SourceSans
    searchBar.Input.TextSize = 14
    searchBar.Input.TextXAlignment = Enum.TextXAlignment.Left
    searchBar.Input.ClearTextOnFocus = false
    searchBar.Input.Parent = searchBar.Background
    
    -- Clear button
    searchBar.ClearButton = Instance.new("ImageButton")
    searchBar.ClearButton.Name = "ClearButton"
    searchBar.ClearButton.Size = UDim2.new(0, 20, 0, 20)
    searchBar.ClearButton.Position = UDim2.new(1, -25, 0.5, -10)
    searchBar.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
    searchBar.ClearButton.BackgroundTransparency = 1
    searchBar.ClearButton.Image = "rbxassetid://3926305904"
    searchBar.ClearButton.ImageRectOffset = Vector2.new(284, 4)
    searchBar.ClearButton.ImageRectSize = Vector2.new(24, 24)
    searchBar.ClearButton.ImageColor3 = searchBar.Theme.Text
    searchBar.ClearButton.Visible = false
    searchBar.ClearButton.Parent = searchBar.Background
    
    -- Search bar interactions
    searchBar.Input:GetPropertyChangedSignal("Text"):Connect(function()
        searchBar.ClearButton.Visible = #searchBar.Input.Text > 0
        searchBar.Callback(searchBar.Input.Text)
    end)
    
    searchBar.ClearButton.MouseButton1Click:Connect(function()
        searchBar.Input.Text = ""
        searchBar.ClearButton.Visible = false
    end)
    
    searchBar.Input.Focused:Connect(function()
        Tween(searchBar.Background, {BorderColor3 = searchBar.Theme.Accent}, 0.2)
    end)
    
    searchBar.Input.FocusLost:Connect(function()
        Tween(searchBar.Background, {BorderColor3 = searchBar.Theme.Border}, 0.2)
    end)
    
    -- Search bar methods
    function searchBar:SetPlaceholder(newPlaceholder)
        self.Placeholder = newPlaceholder or "Search..."
        self.Input.PlaceholderText = newPlaceholder or "Search..."
    end
    
    function searchBar:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function searchBar:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Background.BackgroundColor3 = theme.Foreground
            self.Background.BorderColor3 = theme.Border
            self.Icon.ImageColor3 = theme.Text
            self.Input.TextColor3 = theme.Text
            self.Input.PlaceholderColor3 = theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
            self.ClearButton.ImageColor3 = theme.Text
        end
    end
    
    function searchBar:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return searchBar
end

-- Accordion menu component
function Syncore.CreateAccordionMenu(title, content)
    local accordion = setmetatable({}, Syncore)
    accordion.Title = title or "Section"
    accordion.Content = content or "Content"
    accordion.Theme = Syncore.Themes[Syncore.DefaultTheme]
    accordion.IsOpen = false
    
    -- Create accordion instance
    accordion.Instance = Instance.new("Frame")
    accordion.Instance.Name = "AccordionMenu"
    accordion.Instance.Size = UDim2.new(1, 0, 0, 30)
    accordion.Instance.BackgroundTransparency = 1
    accordion.Instance.ClipsDescendants = true
    
    -- Header
    accordion.Header = Instance.new("TextButton")
    accordion.Header.Name = "Header"
    accordion.Header.Size = UDim2.new(1, 0, 0, 30)
    accordion.Header.Position = UDim2.new(0, 0, 0, 0)
    accordion.Header.BackgroundColor3 = accordion.Theme.Foreground
    accordion.Header.BorderColor3 = accordion.Theme.Border
    accordion.Header.BorderSizePixel = 1
    accordion.Header.Text = ""
    accordion.Header.AutoButtonColor = false
    accordion.Header.Parent = accordion.Instance
    
    -- Title
    accordion.TitleText = Instance.new("TextLabel")
    accordion.TitleText.Name = "Title"
    accordion.TitleText.Size = UDim2.new(1, -30, 1, 0)
    accordion.TitleText.Position = UDim2.new(0, 10, 0, 0)
    accordion.TitleText.BackgroundTransparency = 1
    accordion.TitleText.Text = accordion.Title
    accordion.TitleText.TextColor3 = accordion.Theme.Text
    accordion.TitleText.Font = Enum.Font.SourceSansSemibold
    accordion.TitleText.TextSize = 14
    accordion.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    accordion.TitleText.Parent = accordion.Header
    
    -- Icon
    accordion.Icon = Instance.new("ImageLabel")
    accordion.Icon.Name = "Icon"
    accordion.Icon.Size = UDim2.new(0, 20, 0, 20)
    accordion.Icon.Position = UDim2.new(1, -25, 0.5, -10)
    accordion.Icon.AnchorPoint = Vector2.new(1, 0.5)
    accordion.Icon.BackgroundTransparency = 1
    accordion.Icon.Image = "rbxassetid://3926305904"
    accordion.Icon.ImageRectOffset = Vector2.new(364, 364)
    accordion.Icon.ImageRectSize = Vector2.new(36, 36)
    accordion.Icon.ImageColor3 = accordion.Theme.Text
    accordion.Icon.Rotation = 0
    accordion.Icon.Parent = accordion.Header
    
    -- Content frame
    accordion.ContentFrame = Instance.new("Frame")
    accordion.ContentFrame.Name = "Content"
    accordion.ContentFrame.Size = UDim2.new(1, 0, 0, 0)
    accordion.ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    accordion.ContentFrame.BackgroundTransparency = 1
    accordion.ContentFrame.ClipsDescendants = true
    accordion.ContentFrame.Parent = accordion.Instance
    
    -- Content layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = accordion.ContentFrame
    
    -- Add content
    if type(accordion.Content) == "string" then
        local label = Instance.new("TextLabel")
        label.Name = "ContentLabel"
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = accordion.Content
        label.TextColor3 = accordion.Theme.Text
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Parent = accordion.ContentFrame
    elseif type(accordion.Content) == "table" then
        for _, component in pairs(accordion.Content) do
            component.Instance.Parent = accordion.ContentFrame
        end
    end
    
    -- Update content size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if accordion.IsOpen then
            accordion.Instance.Size = UDim2.new(1, 0, 0, 30 + listLayout.AbsoluteContentSize.Y + 5)
        end
    end)
    
    -- Accordion interactions
    accordion.Header.MouseButton1Click:Connect(function()
        accordion.IsOpen = not accordion.IsOpen
        
        if accordion.IsOpen then
            accordion.Instance.Size = UDim2.new(1, 0, 0, 30 + listLayout.AbsoluteContentSize.Y + 5)
            Tween(accordion.ContentFrame, {Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 5)}, 0.2)
            Tween(accordion.Icon, {Rotation = 90}, 0.2)
        else
            accordion.Instance.Size = UDim2.new(1, 0, 0, 30)
            Tween(accordion.ContentFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            Tween(accordion.Icon, {Rotation = 0}, 0.2)
        end
    end)
    
    -- Accordion methods
    function accordion:SetTitle(newTitle)
        self.Title = newTitle or "Section"
        self.TitleText.Text = newTitle or "Section"
    end
    
    function accordion:SetContent(newContent)
        self.Content = newContent or "Content"
        
        -- Clear existing content
        for _, child in pairs(self.ContentFrame:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        
        -- Add new content
        if type(self.Content) == "string" then
            local label = Instance.new("TextLabel")
            label.Name = "ContentLabel"
            label.Size = UDim2.new(1, -10, 0, 20)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = self.Content
            label.TextColor3 = self.Theme.Text
            label.Font = Enum.Font.SourceSans
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextWrapped = true
            label.Parent = self.ContentFrame
        elseif type(self.Content) == "table" then
            for _, component in pairs(self.Content) do
                component.Instance.Parent = self.ContentFrame
            end
        end
    end
    
    function accordion:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Header.BackgroundColor3 = theme.Foreground
            self.Header.BorderColor3 = theme.Border
            self.TitleText.TextColor3 = theme.Text
            self.Icon.ImageColor3 = theme.Text
        end
    end
    
    function accordion:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return accordion
end

-- Circular progress bar component
function Syncore.CreateCircularProgressBar(label, value)
    local progressBar = setmetatable({}, Syncore)
    progressBar.Label = label or "Progress"
    progressBar.Value = math.clamp(value or 0, 0, 1)
    progressBar.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create circular progress bar instance
    progressBar.Instance = Instance.new("Frame")
    progressBar.Instance.Name = "CircularProgressBar"
    progressBar.Instance.Size = UDim2.new(0, 100, 0, 120)
    progressBar.Instance.BackgroundTransparency = 1
    
    -- Label
    progressBar.LabelText = Instance.new("TextLabel")
    progressBar.LabelText.Name = "Label"
    progressBar.LabelText.Size = UDim2.new(1, 0, 0, 20)
    progressBar.LabelText.Position = UDim2.new(0, 0, 0, 0)
    progressBar.LabelText.BackgroundTransparency = 1
    progressBar.LabelText.Text = progressBar.Label
    progressBar.LabelText.TextColor3 = progressBar.Theme.Text
    progressBar.LabelText.Font = Enum.Font.SourceSans
    progressBar.LabelText.TextSize = 14
    progressBar.LabelText.TextXAlignment = Enum.TextXAlignment.Center
    progressBar.LabelText.Parent = progressBar.Instance
    
    -- Circle frame
    progressBar.CircleFrame = Instance.new("Frame")
    progressBar.CircleFrame.Name = "CircleFrame"
    progressBar.CircleFrame.Size = UDim2.new(0, 80, 0, 80)
    progressBar.CircleFrame.Position = UDim2.new(0.5, -40, 0, 30)
    progressBar.CircleFrame.BackgroundTransparency = 1
    progressBar.CircleFrame.Parent = progressBar.Instance
    
    -- Background circle
    progressBar.BackgroundCircle = Instance.new("ImageLabel")
    progressBar.BackgroundCircle.Name = "BackgroundCircle"
    progressBar.BackgroundCircle.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundCircle.Image = "rbxassetid://266543268"
    progressBar.BackgroundCircle.ImageColor3 = progressBar.Theme.Foreground
    progressBar.BackgroundCircle.BackgroundTransparency = 1
    progressBar.BackgroundCircle.Parent = progressBar.CircleFrame
    
    -- Progress circle
    progressBar.ProgressCircle = Instance.new("ImageLabel")
    progressBar.ProgressCircle.Name = "ProgressCircle"
    progressBar.ProgressCircle.Size = UDim2.new(1, 0, 1, 0)
    progressBar.ProgressCircle.Image = "rbxassetid://266543268"
    progressBar.ProgressCircle.ImageColor3 = progressBar.Theme.Accent
    progressBar.ProgressCircle.BackgroundTransparency = 1
    progressBar.ProgressCircle.ImageTransparency = 0.5
    progressBar.ProgressCircle.Parent = progressBar.CircleFrame
    
    -- Percentage text
    progressBar.PercentageText = Instance.new("TextLabel")
    progressBar.PercentageText.Name = "Percentage"
    progressBar.PercentageText.Size = UDim2.new(0, 60, 0, 30)
    progressBar.PercentageText.Position = UDim2.new(0.5, -30, 0.5, -15)
    progressBar.PercentageText.AnchorPoint = Vector2.new(0.5, 0.5)
    progressBar.PercentageText.BackgroundTransparency = 1
    progressBar.PercentageText.Text = string.format("%d%%", progressBar.Value * 100)
    progressBar.PercentageText.TextColor3 = progressBar.Theme.Text
    progressBar.PercentageText.Font = Enum.Font.SourceSansSemibold
    progressBar.PercentageText.TextSize = 20
    progressBar.PercentageText.Parent = progressBar.CircleFrame
    
    -- Update progress
    local function updateProgress()
        progressBar.ProgressCircle.Rotation = -90
        Tween(progressBar.ProgressCircle, {Rotation = -90 + 360 * progressBar.Value}, 0.5)
        progressBar.PercentageText.Text = string.format("%d%%", progressBar.Value * 100)
    end
    
    updateProgress()
    
    -- Circular progress bar methods
    function progressBar:SetProgress(value)
        self.Value = math.clamp(value or 0, 0, 1)
        updateProgress()
    end
    
    function progressBar:SetLabel(newLabel)
        self.Label = newLabel or "Progress"
        self.LabelText.Text = newLabel or "Progress"
    end
    
    function progressBar:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.LabelText.TextColor3 = theme.Text
            self.BackgroundCircle.ImageColor3 = theme.Foreground
            self.ProgressCircle.ImageColor3 = theme.Accent
            self.PercentageText.TextColor3 = theme.Text
        end
    end
    
    function progressBar:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return progressBar
end

-- File picker component
function Syncore.CreateFilePicker(allowedTypes, callback)
    local filePicker = setmetatable({}, Syncore)
    filePicker.AllowedTypes = allowedTypes or {"png", "jpg", "jpeg", "txt"}
    filePicker.Callback = callback or function() end
    filePicker.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create file picker instance
    filePicker.Instance = Instance.new("Frame")
    filePicker.Instance.Name = "FilePicker"
    filePicker.Instance.Size = UDim2.new(0, 200, 0, 60)
    filePicker.Instance.BackgroundTransparency = 1
    
    -- Background
    filePicker.Background = Instance.new("Frame")
    filePicker.Background.Name = "Background"
    filePicker.Background.Size = UDim2.new(1, 0, 0, 50)
    filePicker.Background.BackgroundColor3 = filePicker.Theme.Foreground
    filePicker.Background.BorderColor3 = filePicker.Theme.Border
    filePicker.Background.BorderSizePixel = 1
    filePicker.Background.Parent = filePicker.Instance
    
    -- Icon
    filePicker.Icon = Instance.new("ImageLabel")
    filePicker.Icon.Name = "Icon"
    filePicker.Icon.Size = UDim2.new(0, 30, 0, 30)
    filePicker.Icon.Position = UDim2.new(0, 10, 0.5, -15)
    filePicker.Icon.AnchorPoint = Vector2.new(0, 0.5)
    filePicker.Icon.BackgroundTransparency = 1
    filePicker.Icon.Image = "rbxassetid://3926305904"
    filePicker.Icon.ImageRectOffset = Vector2.new(724, 204)
    filePicker.Icon.ImageRectSize = Vector2.new(36, 36)
    filePicker.Icon.ImageColor3 = filePicker.Theme.Text
    filePicker.Icon.Parent = filePicker.Background
    
    -- Label
    filePicker.Label = Instance.new("TextLabel")
    filePicker.Label.Name = "Label"
    filePicker.Label.Size = UDim2.new(1, -50, 1, 0)
    filePicker.Label.Position = UDim2.new(0, 50, 0, 0)
    filePicker.Label.BackgroundTransparency = 1
    filePicker.Label.Text = "Select a file..."
    filePicker.Label.TextColor3 = filePicker.Theme.Text
    filePicker.Label.Font = Enum.Font.SourceSans
    filePicker.Label.TextSize = 14
    filePicker.Label.TextXAlignment = Enum.TextXAlignment.Left
    filePicker.Label.TextTruncate = Enum.TextTruncate.AtEnd
    filePicker.Label.Parent = filePicker.Background
    
    -- Button
    filePicker.Button = Instance.new("TextButton")
    filePicker.Button.Name = "Button"
    filePicker.Button.Size = UDim2.new(1, 0, 1, 0)
    filePicker.Button.BackgroundTransparency = 1
    filePicker.Button.Text = ""
    filePicker.Button.Parent = filePicker.Background
    
    -- File name
    filePicker.FileName = Instance.new("TextLabel")
    filePicker.FileName.Name = "FileName"
    filePicker.FileName.Size = UDim2.new(1, 0, 0, 10)
    filePicker.FileName.Position = UDim2.new(0, 0, 1, 0)
    filePicker.FileName.BackgroundTransparency = 1
    filePicker.FileName.Text = ""
    filePicker.FileName.TextColor3 = filePicker.Theme.Text
    filePicker.FileName.Font = Enum.Font.SourceSans
    filePicker.FileName.TextSize = 12
    filePicker.FileName.TextXAlignment = Enum.TextXAlignment.Center
    filePicker.FileName.TextTruncate = Enum.TextTruncate.AtEnd
    filePicker.FileName.Parent = filePicker.Instance
    
    -- File picker interactions
    filePicker.Button.MouseButton1Click:Connect(function()
        local fileDialog = Instance.new("FileDialog")
        fileDialog.Name = "FilePickerDialog"
        fileDialog.Title = "Select a file"
        
        if #filePicker.AllowedTypes > 0 then
            fileDialog.Filters = {{"Allowed files", table.concat(filePicker.AllowedTypes, ",")}}
        end
        
        fileDialog.Parent = game:GetService("CoreGui")
        fileDialog:Show()
        
        fileDialog.FileSelected:Connect(function(path)
            local fileName = path:match("([^/\\]+)$")
            filePicker.Label.Text = "File selected"
            filePicker.FileName.Text = fileName
            filePicker.Callback(path, fileName)
        end)
    end)
    
    -- File picker methods
    function filePicker:SetAllowedTypes(newTypes)
        self.AllowedTypes = newTypes or {"png", "jpg", "jpeg", "txt"}
    end
    
    function filePicker:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function filePicker:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Background.BackgroundColor3 = theme.Foreground
            self.Background.BorderColor3 = theme.Border
            self.Icon.ImageColor3 = theme.Text
            self.Label.TextColor3 = theme.Text
            self.FileName.TextColor3 = theme.Text
        end
    end
    
    function filePicker:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return filePicker
end

-- Chat box component
function Syncore.CreateChatBox(callback)
    local chatBox = setmetatable({}, Syncore)
    chatBox.Callback = callback or function() end
    chatBox.Theme = Syncore.Themes[Syncore.DefaultTheme]
    chatBox.Messages = {}
    
    -- Create chat box instance
    chatBox.Instance = Instance.new("Frame")
    chatBox.Instance.Name = "ChatBox"
    chatBox.Instance.Size = UDim2.new(0, 300, 0, 400)
    chatBox.Instance.BackgroundColor3 = chatBox.Theme.Foreground
    chatBox.Instance.BorderColor3 = chatBox.Theme.Border
    chatBox.Instance.BorderSizePixel = 1
    
    -- Title bar
    chatBox.TitleBar = Instance.new("Frame")
    chatBox.TitleBar.Name = "TitleBar"
    chatBox.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    chatBox.TitleBar.BackgroundColor3 = chatBox.Theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)
    chatBox.TitleBar.BorderSizePixel = 0
    chatBox.TitleBar.Parent = chatBox.Instance
    
    -- Title text
    chatBox.TitleText = Instance.new("TextLabel")
    chatBox.TitleText.Name = "Title"
    chatBox.TitleText.Size = UDim2.new(1, -10, 1, 0)
    chatBox.TitleText.Position = UDim2.new(0, 5, 0, 0)
    chatBox.TitleText.BackgroundTransparency = 1
    chatBox.TitleText.Text = "Chat"
    chatBox.TitleText.TextColor3 = chatBox.Theme.Text
    chatBox.TitleText.Font = Enum.Font.SourceSansSemibold
    chatBox.TitleText.TextSize = 16
    chatBox.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    chatBox.TitleText.Parent = chatBox.TitleBar
    
    -- Messages frame
    chatBox.MessagesFrame = Instance.new("ScrollingFrame")
    chatBox.MessagesFrame.Name = "Messages"
    chatBox.MessagesFrame.Size = UDim2.new(1, -10, 1, -80)
    chatBox.MessagesFrame.Position = UDim2.new(0, 5, 0, 35)
    chatBox.MessagesFrame.BackgroundTransparency = 1
    chatBox.MessagesFrame.BorderSizePixel = 0
    chatBox.MessagesFrame.ScrollBarThickness = 5
    chatBox.MessagesFrame.ScrollBarImageColor3 = chatBox.Theme.Border
    chatBox.MessagesFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatBox.MessagesFrame.Parent = chatBox.Instance
    
    local messagesLayout = Instance.new("UIListLayout")
    messagesLayout.Padding = UDim.new(0, 5)
    messagesLayout.Parent = chatBox.MessagesFrame
    
    -- Input frame
    chatBox.InputFrame = Instance.new("Frame")
    chatBox.InputFrame.Name = "Input"
    chatBox.InputFrame.Size = UDim2.new(1, -10, 0, 40)
    chatBox.InputFrame.Position = UDim2.new(0, 5, 1, -45)
    chatBox.InputFrame.BackgroundColor3 = chatBox.Theme.Foreground
    chatBox.InputFrame.BorderColor3 = chatBox.Theme.Border
    chatBox.InputFrame.BorderSizePixel = 1
    chatBox.InputFrame.Parent = chatBox.Instance
    
    -- Input box
    chatBox.InputBox = Instance.new("TextBox")
    chatBox.InputBox.Name = "InputBox"
    chatBox.InputBox.Size = UDim2.new(1, -70, 1, -10)
    chatBox.InputBox.Position = UDim2.new(0, 5, 0, 5)
    chatBox.InputBox.BackgroundColor3 = chatBox.Theme.Foreground
    chatBox.InputBox.BorderColor3 = chatBox.Theme.Border
    chatBox.InputBox.BorderSizePixel = 1
    chatBox.InputBox.PlaceholderText = "Type a message..."
    chatBox.InputBox.PlaceholderColor3 = chatBox.Theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
    chatBox.InputBox.Text = ""
    chatBox.InputBox.TextColor3 = chatBox.Theme.Text
    chatBox.InputBox.Font = Enum.Font.SourceSans
    chatBox.InputBox.TextSize = 14
    chatBox.InputBox.TextXAlignment = Enum.TextXAlignment.Left
    chatBox.InputBox.ClearTextOnFocus = false
    chatBox.InputBox.Parent = chatBox.InputFrame
    
    -- Send button
    chatBox.SendButton = Instance.new("TextButton")
    chatBox.SendButton.Name = "SendButton"
    chatBox.SendButton.Size = UDim2.new(0, 60, 1, -10)
    chatBox.SendButton.Position = UDim2.new(1, -65, 0, 5)
    chatBox.SendButton.BackgroundColor3 = chatBox.Theme.Accent
    chatBox.SendButton.BorderColor3 = chatBox.Theme.Border
    chatBox.SendButton.BorderSizePixel = 1
    chatBox.SendButton.Text = "Send"
    chatBox.SendButton.TextColor3 = chatBox.Theme.Text
    chatBox.SendButton.Font = Enum.Font.SourceSans
    chatBox.SendButton.TextSize = 14
    chatBox.SendButton.Parent = chatBox.InputFrame
    
    -- Chat box interactions
    chatBox.InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and #chatBox.InputBox.Text > 0 then
            chatBox:AddMessage("You", chatBox.InputBox.Text)
            chatBox.Callback(chatBox.InputBox.Text)
            chatBox.InputBox.Text = ""
        end
    end)
    
    chatBox.SendButton.MouseButton1Click:Connect(function()
        if #chatBox.InputBox.Text > 0 then
            chatBox:AddMessage("You", chatBox.InputBox.Text)
            chatBox.Callback(chatBox.InputBox.Text)
            chatBox.InputBox.Text = ""
        end
    end)
    
    -- Chat box methods
    function chatBox:AddMessage(sender, message)
        local messageFrame = Instance.new("Frame")
        messageFrame.Name = "Message"
        messageFrame.Size = UDim2.new(1, 0, 0, 0)
        messageFrame.BackgroundTransparency = 1
        messageFrame.AutomaticSize = Enum.AutomaticSize.Y
        messageFrame.Parent = self.MessagesFrame
        
        local senderLabel = Instance.new("TextLabel")
        senderLabel.Name = "Sender"
        senderLabel.Size = UDim2.new(1, 0, 0, 20)
        senderLabel.BackgroundTransparency = 1
        senderLabel.Text = sender
        senderLabel.TextColor3 = self.Theme.Text
        senderLabel.Font = Enum.Font.SourceSansSemibold
        senderLabel.TextSize = 14
        senderLabel.TextXAlignment = Enum.TextXAlignment.Left
        senderLabel.Parent = messageFrame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "Text"
        messageLabel.Size = UDim2.new(1, -10, 0, 0)
        messageLabel.Position = UDim2.new(0, 10, 0, 20)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = self.Theme.Text
        messageLabel.Font = Enum.Font.SourceSans
        messageLabel.TextSize = 14
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextWrapped = true
        messageLabel.AutomaticSize = Enum.AutomaticSize.Y
        messageLabel.Parent = messageFrame
        
        table.insert(self.Messages, {
            Sender = sender,
            Message = message,
            Frame = messageFrame
        })
        
        -- Auto-scroll to bottom
        task.wait()
        self.MessagesFrame.CanvasPosition = Vector2.new(0, self.MessagesFrame.AbsoluteCanvasSize.Y)
    end
    
    function chatBox:ClearMessages()
        for _, message in pairs(self.Messages) do
            message.Frame:Destroy()
        end
        self.Messages = {}
    end
    
    function chatBox:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function chatBox:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.TitleBar.BackgroundColor3 = theme.Foreground:lerp(Color3.new(0, 0, 0), 0.1)
            self.TitleText.TextColor3 = theme.Text
            self.MessagesFrame.ScrollBarImageColor3 = theme.Border
            self.InputFrame.BackgroundColor3 = theme.Foreground
            self.InputFrame.BorderColor3 = theme.Border
            self.InputBox.BackgroundColor3 = theme.Foreground
            self.InputBox.BorderColor3 = theme.Border
            self.InputBox.TextColor3 = theme.Text
            self.InputBox.PlaceholderColor3 = theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
            self.SendButton.BackgroundColor3 = theme.Accent
            self.SendButton.BorderColor3 = theme.Border
            self.SendButton.TextColor3 = theme.Text
            
            for _, message in pairs(self.Messages) do
                message.Frame.Sender.TextColor3 = theme.Text
                message.Frame.Text.TextColor3 = theme.Text
            end
        end
    end
    
    function chatBox:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return chatBox
end

-- Breadcrumbs component
function Syncore.CreateBreadcrumbs(path)
    local breadcrumbs = setmetatable({}, Syncore)
    breadcrumbs.Path = path or {"Home"}
    breadcrumbs.Theme = Syncore.Themes[Syncore.DefaultTheme]
    breadcrumbs.Callbacks = {}
    
    -- Create breadcrumbs instance
    breadcrumbs.Instance = Instance.new("Frame")
    breadcrumbs.Instance.Name = "Breadcrumbs"
    breadcrumbs.Instance.Size = UDim2.new(1, 0, 0, 30)
    breadcrumbs.Instance.BackgroundTransparency = 1
    
    -- Breadcrumbs layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.Parent = breadcrumbs.Instance
    
    -- Create breadcrumbs
    local function updateBreadcrumbs()
        -- Clear existing breadcrumbs
        for _, child in pairs(breadcrumbs.Instance:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        
        -- Create new breadcrumbs
        for i, crumb in ipairs(breadcrumbs.Path) do
            local button = Instance.new("TextButton")
            button.Name = "Crumb"..i
            button.Size = UDim2.new(0, 0, 1, 0)
            button.AutomaticSize = Enum.AutomaticSize.X
            button.BackgroundTransparency = 1
            button.Text = crumb
            button.TextColor3 = breadcrumbs.Theme.Text
            button.Font = Enum.Font.SourceSans
            button.TextSize = 14
            button.Parent = breadcrumbs.Instance
            
            if i < #breadcrumbs.Path then
                local separator = Instance.new("TextLabel")
                separator.Name = "Separator"..i
                separator.Size = UDim2.new(0, 10, 1, 0)
                separator.BackgroundTransparency = 1
                separator.Text = ">"
                separator.TextColor3 = breadcrumbs.Theme.Text
                separator.Font = Enum.Font.SourceSans
                separator.TextSize = 14
                separator.Parent = breadcrumbs.Instance
            end
            
            button.MouseButton1Click:Connect(function()
                if breadcrumbs.Callbacks[i] then
                    breadcrumbs.Callbacks[i]()
                end
            end)
        end
    end
    
    updateBreadcrumbs()
    
    -- Breadcrumbs methods
    function breadcrumbs:SetPath(newPath, newCallbacks)
        self.Path = newPath or {"Home"}
        self.Callbacks = newCallbacks or {}
        updateBreadcrumbs()
    end
    
    function breadcrumbs:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            for _, child in pairs(self.Instance:GetChildren()) do
                if child:IsA("GuiObject") then
                    child.TextColor3 = theme.Text
                end
            end
        end
    end
    
    function breadcrumbs:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return breadcrumbs
end

-- Linear layout component
function Syncore.CreateLinearLayout(orientation, elements)
    local layout = setmetatable({}, Syncore)
    layout.Orientation = orientation or "Vertical"
    layout.Elements = elements or {}
    layout.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create layout instance
    layout.Instance = Instance.new("Frame")
    layout.Instance.Name = "LinearLayout"
    layout.Instance.Size = UDim2.new(1, 0, 1, 0)
    layout.Instance.BackgroundTransparency = 1
    
    -- Create layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = orientation == "Horizontal" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = layout.Instance
    
    -- Add elements
    for _, element in pairs(layout.Elements) do
        element.Instance.Parent = layout.Instance
    end
    
    -- Layout methods
    function layout:AddElement(element)
        table.insert(self.Elements, element)
        element.Instance.Parent = self.Instance
    end
    
    function layout:RemoveElement(element)
        for i, el in pairs(self.Elements) do
            if el == element then
                table.remove(self.Elements, i)
                element.Instance.Parent = nil
                break
            end
        end
    end
    
    function layout:Clear()
        for _, element in pairs(self.Elements) do
            element.Instance.Parent = nil
        end
        self.Elements = {}
    end
    
    function layout:SetOrientation(newOrientation)
        self.Orientation = newOrientation or "Vertical"
        listLayout.FillDirection = self.Orientation == "Horizontal" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    end
    
    function layout:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            for _, element in pairs(self.Elements) do
                if element.SetTheme then
                    element:SetTheme(themeName)
                end
            end
        end
    end
    
    function layout:Destroy()
        for _, element in pairs(self.Elements) do
            element:Destroy()
        end
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return layout
end

-- Circular menu component
function Syncore.CreateCircularMenu(options, callback)
    local menu = setmetatable({}, Syncore)
    menu.Options = options or {
        {Text = "Option 1", Icon = "rbxassetid://3926305904", IconRect = Vector2.new(124, 204)},
        {Text = "Option 2", Icon = "rbxassetid://3926305904", IconRect = Vector2.new(124, 204)},
        {Text = "Option 3", Icon = "rbxassetid://3926305904", IconRect = Vector2.new(124, 204)}
    }
    menu.Callback = callback or function() end
    menu.Theme = Syncore.Themes[Syncore.DefaultTheme]
    menu.IsOpen = false
    
    -- Create menu instance
    menu.Instance = Instance.new("Frame")
    menu.Instance.Name = "CircularMenu"
    menu.Instance.Size = UDim2.new(0, 60, 0, 60)
    menu.Instance.BackgroundTransparency = 1
    menu.Instance.ClipsDescendants = true
    
    -- Center button
    menu.CenterButton = Instance.new("ImageButton")
    menu.CenterButton.Name = "CenterButton"
    menu.CenterButton.Size = UDim2.new(1, 0, 1, 0)
    menu.CenterButton.Image = "rbxassetid://3926305904"
    menu.CenterButton.ImageRectOffset = Vector2.new(364, 364)
    menu.CenterButton.ImageRectSize = Vector2.new(36, 36)
    menu.CenterButton.ImageColor3 = menu.Theme.Accent
    menu.CenterButton.BackgroundTransparency = 1
    menu.CenterButton.Parent = menu.Instance
    
    -- Option buttons
    menu.OptionButtons = {}
    
    local function createOptionButtons()
        -- Clear existing buttons
        for _, button in pairs(menu.OptionButtons) do
            button:Destroy()
        end
        menu.OptionButtons = {}
        
        -- Create new buttons
        local angleStep = 360 / #menu.Options
        local radius = 100
        
        for i, option in ipairs(menu.Options) do
            local angle = math.rad(angleStep * (i - 1))
            local x = math.cos(angle) * radius
            local y = math.sin(angle) * radius
            
            local button = Instance.new("ImageButton")
            button.Name = "Option"..i
            button.Size = UDim2.new(0, 50, 0, 50)
            button.Position = UDim2.new(0.5, x - 25, 0.5, y - 25)
            button.AnchorPoint = Vector2.new(0.5, 0.5)
            button.Image = option.Icon or "rbxassetid://3926305904"
            button.ImageRectOffset = option.IconRect or Vector2.new(124, 204)
            button.ImageRectSize = Vector2.new(36, 36)
            button.ImageColor3 = menu.Theme.Accent
            button.BackgroundTransparency = 1
            button.Visible = false
            button.Parent = menu.Instance
            
            local tooltip = Instance.new("TextLabel")
            tooltip.Name = "Tooltip"
            tooltip.Size = UDim2.new(0, 0, 0, 20)
            tooltip.Position = UDim2.new(0.5, 0, 0.5, -40)
            tooltip.AnchorPoint = Vector2.new(0.5, 0.5)
            tooltip.BackgroundColor3 = menu.Theme.Foreground
            tooltip.BorderColor3 = menu.Theme.Border
            tooltip.BorderSizePixel = 1
            tooltip.Text = option.Text
            tooltip.TextColor3 = menu.Theme.Text
            tooltip.Font = Enum.Font.SourceSans
            tooltip.TextSize = 12
            tooltip.AutomaticSize = Enum.AutomaticSize.X
            tooltip.Visible = false
            tooltip.Parent = button
            
            button.MouseEnter:Connect(function()
                tooltip.Visible = true
                Tween(button, {ImageColor3 = menu.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
            end)
            
            button.MouseLeave:Connect(function()
                tooltip.Visible = false
                Tween(button, {ImageColor3 = menu.Theme.Accent}, 0.2)
            end)
            
            button.MouseButton1Click:Connect(function()
                menu:Toggle()
                menu.Callback(option.Text or "Option "..i)
            end)
            
            table.insert(menu.OptionButtons, button)
        end
    end
    
    createOptionButtons()
    
    -- Menu interactions
    function menu:Toggle()
        self.IsOpen = not self.IsOpen
        
        if self.IsOpen then
            Tween(self.CenterButton, {Rotation = 45, ImageColor3 = self.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
            
            for i, button in pairs(self.OptionButtons) do
                button.Visible = true
                button.Position = UDim2.new(0.5, button.Position.X.Offset, 0.5, button.Position.Y.Offset)
                button.Size = UDim2.new(0, 0, 0, 0)
                button.ImageTransparency = 1
                
                Tween(button, {
                    Size = UDim2.new(0, 50, 0, 50),
                    ImageTransparency = 0
                }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, i * 0.05)
            end
        else
            Tween(self.CenterButton, {Rotation = 0, ImageColor3 = self.Theme.Accent}, 0.2)
            
            for i, button in pairs(self.OptionButtons) do
                Tween(button, {
                    Size = UDim2.new(0, 0, 0, 0),
                    ImageTransparency = 1
                }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, (#self.OptionButtons - i) * 0.05, function()
                    button.Visible = false
                end)
            end
        end
    end
    
    menu.CenterButton.MouseButton1Click:Connect(function()
        menu:Toggle()
    end)
    
    -- Menu methods
    function menu:SetOptions(newOptions, newCallback)
        self.Options = newOptions or {
            {Text = "Option 1", Icon = "rbxassetid://3926305904", IconRect = Vector2.new(124, 204)},
            {Text = "Option 2", Icon = "rbxassetid://3926305904", IconRect = Vector2.new(124, 204)},
            {Text = "Option 3", Icon = "rbxassetid://3926305904", IconRect = Vector2.new(124, 204)}
        }
        self.Callback = newCallback or function() end
        createOptionButtons()
    end
    
    function menu:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.CenterButton.ImageColor3 = theme.Accent
            
            for _, button in pairs(self.OptionButtons) do
                button.ImageColor3 = theme.Accent
                button.Tooltip.BackgroundColor3 = theme.Foreground
                button.Tooltip.BorderColor3 = theme.Border
                button.Tooltip.TextColor3 = theme.Text
            end
        end
    end
    
    function menu:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return menu
end

-- Draggable element component
function Syncore.CreateDraggableElement(element)
    local draggable = setmetatable({}, Syncore)
    draggable.Element = element
    draggable.Dragging = false
    draggable.DragStart = nil
    draggable.StartPos = nil
    
    -- Make element draggable
    element.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggable.Dragging = true
            draggable.DragStart = input.Position
            draggable.StartPos = element.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggable.Dragging = false
                end
            end)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if draggable.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - draggable.DragStart
            element.Position = UDim2.new(draggable.StartPos.X.Scale, draggable.StartPos.X.Offset + delta.X, draggable.StartPos.Y.Scale, draggable.StartPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Draggable methods
    function draggable:Destroy()
        setmetatable(self, nil)
    end
    
    return draggable
end

-- Sound toggle component
function Syncore.CreateSoundToggle(label, soundId, callback)
    local soundToggle = setmetatable({}, Syncore)
    soundToggle.Label = label or "Sound"
    soundToggle.SoundId = soundId or "rbxassetid://0"
    soundToggle.Callback = callback or function() end
    soundToggle.Theme = Syncore.Themes[Syncore.DefaultTheme]
    soundToggle.State = false
    
    -- Create sound toggle instance
    soundToggle.Instance = Instance.new("Frame")
    soundToggle.Instance.Name = "SoundToggle"
    soundToggle.Instance.Size = UDim2.new(0, 200, 0, 30)
    soundToggle.Instance.BackgroundTransparency = 1
    
    -- Label
    soundToggle.LabelText = Instance.new("TextLabel")
    soundToggle.LabelText.Name = "Label"
    soundToggle.LabelText.Size = UDim2.new(1, -80, 1, 0)
    soundToggle.LabelText.Position = UDim2.new(0, 0, 0, 0)
    soundToggle.LabelText.BackgroundTransparency = 1
    soundToggle.LabelText.Text = soundToggle.Label
    soundToggle.LabelText.TextColor3 = soundToggle.Theme.Text
    soundToggle.LabelText.Font = Enum.Font.SourceSans
    soundToggle.LabelText.TextSize = 14
    soundToggle.LabelText.TextXAlignment = Enum.TextXAlignment.Left
    soundToggle.LabelText.Parent = soundToggle.Instance
    
    -- Toggle button
    soundToggle.ToggleButton = Instance.new("TextButton")
    soundToggle.ToggleButton.Name = "ToggleButton"
    soundToggle.ToggleButton.Size = UDim2.new(0, 30, 0, 30)
    soundToggle.ToggleButton.Position = UDim2.new(1, -30, 0, 0)
    soundToggle.ToggleButton.BackgroundColor3 = soundToggle.Theme.Foreground
    soundToggle.ToggleButton.BorderColor3 = soundToggle.Theme.Border
    soundToggle.ToggleButton.BorderSizePixel = 1
    soundToggle.ToggleButton.Text = ""
    soundToggle.ToggleButton.AutoButtonColor = false
    soundToggle.ToggleButton.Parent = soundToggle.Instance
    
    -- Icon
    soundToggle.Icon = Instance.new("ImageLabel")
    soundToggle.Icon.Name = "Icon"
    soundToggle.Icon.Size = UDim2.new(0, 20, 0, 20)
    soundToggle.Icon.Position = UDim2.new(0.5, -10, 0.5, -10)
    soundToggle.Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    soundToggle.Icon.BackgroundTransparency = 1
    soundToggle.Icon.Image = "rbxassetid://3926305904"
    soundToggle.Icon.ImageRectOffset = Vector2.new(964, 44)
    soundToggle.Icon.ImageRectSize = Vector2.new(36, 36)
    soundToggle.Icon.ImageColor3 = soundToggle.Theme.Text
    soundToggle.Icon.Parent = soundToggle.ToggleButton
    
    -- Volume slider
    soundToggle.VolumeSlider = Instance.new("Frame")
    soundToggle.VolumeSlider.Name = "VolumeSlider"
    soundToggle.VolumeSlider.Size = UDim2.new(0, 40, 0, 30)
    soundToggle.VolumeSlider.Position = UDim2.new(1, -70, 0, 0)
    soundToggle.VolumeSlider.BackgroundTransparency = 1
    soundToggle.VolumeSlider.Visible = false
    soundToggle.VolumeSlider.Parent = soundToggle.Instance
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "Track"
    sliderTrack.Size = UDim2.new(0, 5, 1, -10)
    sliderTrack.Position = UDim2.new(0.5, -2.5, 0, 5)
    sliderTrack.BackgroundColor3 = soundToggle.Theme.Foreground
    sliderTrack.BorderColor3 = soundToggle.Theme.Border
    sliderTrack.BorderSizePixel = 1
    sliderTrack.Parent = soundToggle.VolumeSlider
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new(1, 0, 0.5, 0)
    sliderFill.Position = UDim2.new(0, 0, 0.5, 0)
    sliderFill.BackgroundColor3 = soundToggle.Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack
    
    local sliderThumb = Instance.new("Frame")
    sliderThumb.Name = "Thumb"
    sliderThumb.Size = UDim2.new(0, 10, 0, 10)
    sliderThumb.Position = UDim2.new(0.5, -5, 0.5, -5)
    sliderThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderThumb.BackgroundColor3 = soundToggle.Theme.Accent
    sliderThumb.BorderColor3 = soundToggle.Theme.Border
    sliderThumb.BorderSizePixel = 1
    Instance.new("UICorner", sliderThumb).CornerRadius = UDim.new(1, 0)
    sliderThumb.Parent = soundToggle.VolumeSlider
    
    -- Volume slider interactions
    local dragging = false
    
    local function updateVolume(y)
        local percent = 1 - math.clamp((y - sliderTrack.AbsolutePosition.Y) / sliderTrack.AbsoluteSize.Y, 0, 1)
        sliderFill.Size = UDim2.new(1, 0, percent, 0)
        sliderFill.Position = UDim2.new(0, 0, 1 - percent, 0)
        sliderThumb.Position = UDim2.new(0.5, 0, 1 - percent, 0)
    end
    
    sliderThumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderThumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateVolume(input.Position.Y)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateVolume(input.Position.Y)
        end
    end)
    
    -- Sound toggle interactions
    soundToggle.ToggleButton.MouseButton1Click:Connect(function()
        soundToggle.State = not soundToggle.State
        soundToggle.VolumeSlider.Visible = soundToggle.State
        
        if soundToggle.State then
            Tween(soundToggle.ToggleButton, {BackgroundColor3 = soundToggle.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
        else
            Tween(soundToggle.ToggleButton, {BackgroundColor3 = soundToggle.Theme.Foreground}, 0.2)
        end
        
        soundToggle.Callback(soundToggle.State)
    end)
    
    -- Sound toggle methods
    function soundToggle:SetState(state)
        self.State = state
        self.VolumeSlider.Visible = state
        
        if state then
            Tween(self.ToggleButton, {BackgroundColor3 = self.Theme.Accent:lerp(Color3.new(1, 1, 1), 0.3)}, 0.2)
        else
            Tween(self.ToggleButton, {BackgroundColor3 = self.Theme.Foreground}, 0.2)
        end
    end
    
    function soundToggle:SetLabel(newLabel)
        self.Label = newLabel or "Sound"
        self.LabelText.Text = newLabel or "Sound"
    end
    
    function soundToggle:SetSoundId(newSoundId)
        self.SoundId = newSoundId or "rbxassetid://0"
    end
    
    function soundToggle:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function soundToggle:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.LabelText.TextColor3 = theme.Text
            self.ToggleButton.BackgroundColor3 = self.State and theme.Accent:lerp(Color3.new(1, 1, 1), 0.3) or theme.Foreground
            self.ToggleButton.BorderColor3 = theme.Border
            self.Icon.ImageColor3 = theme.Text
            self.VolumeSlider.Track.BackgroundColor3 = theme.Foreground
            self.VolumeSlider.Track.BorderColor3 = theme.Border
            self.VolumeSlider.Fill.BackgroundColor3 = theme.Accent
            self.VolumeSlider.Thumb.BackgroundColor3 = theme.Accent
            self.VolumeSlider.Thumb.BorderColor3 = theme.Border
        end
    end
    
    function soundToggle:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return soundToggle
end

-- Dropdown with search component
function Syncore.CreateDropdownWithSearch(options, callback)
    local dropdown = setmetatable({}, Syncore)
    dropdown.Options = options or {"Option 1", "Option 2", "Option 3"}
    dropdown.Callback = callback or function() end
    dropdown.Theme = Syncore.Themes[Syncore.DefaultTheme]
    dropdown.IsOpen = false
    dropdown.Selected = nil
    
    -- Create dropdown instance
    dropdown.Instance = Instance.new("Frame")
    dropdown.Instance.Name = "DropdownWithSearch"
    dropdown.Instance.Size = UDim2.new(0, 200, 0, 30)
    dropdown.Instance.BackgroundTransparency = 1
    
    -- Main button
    dropdown.MainButton = Instance.new("TextButton")
    dropdown.MainButton.Name = "MainButton"
    dropdown.MainButton.Size = UDim2.new(1, 0, 1, 0)
    dropdown.MainButton.BackgroundColor3 = dropdown.Theme.Foreground
    dropdown.MainButton.BorderColor3 = dropdown.Theme.Border
    dropdown.MainButton.BorderSizePixel = 1
    dropdown.MainButton.Text = dropdown.Selected or "Select an option"
    dropdown.MainButton.TextColor3 = dropdown.Theme.Text
    dropdown.MainButton.Font = Enum.Font.SourceSans
    dropdown.MainButton.TextSize = 14
    dropdown.MainButton.TextXAlignment = Enum.TextXAlignment.Left
    dropdown.MainButton.TextTruncate = Enum.TextTruncate.AtEnd
    dropdown.MainButton.AutoButtonColor = false
    dropdown.MainButton.Parent = dropdown.Instance
    
    -- Dropdown icon
    dropdown.Icon = Instance.new("ImageLabel")
    dropdown.Icon.Name = "Icon"
    dropdown.Icon.Size = UDim2.new(0, 20, 0, 20)
    dropdown.Icon.Position = UDim2.new(1, -25, 0.5, -10)
    dropdown.Icon.AnchorPoint = Vector2.new(1, 0.5)
    dropdown.Icon.BackgroundTransparency = 1
    dropdown.Icon.Image = "rbxassetid://3926305904"
    dropdown.Icon.ImageRectOffset = Vector2.new(364, 364)
    dropdown.Icon.ImageRectSize = Vector2.new(36, 36)
    dropdown.Icon.ImageColor3 = dropdown.Theme.Text
    dropdown.Icon.Parent = dropdown.MainButton
    
    -- Dropdown frame
    dropdown.DropdownFrame = Instance.new("Frame")
    dropdown.DropdownFrame.Name = "DropdownFrame"
    dropdown.DropdownFrame.Size = UDim2.new(1, 0, 0, 200)
    dropdown.DropdownFrame.Position = UDim2.new(0, 0, 1, 5)
    dropdown.DropdownFrame.BackgroundColor3 = dropdown.Theme.Foreground
    dropdown.DropdownFrame.BorderColor3 = dropdown.Theme.Border
    dropdown.DropdownFrame.BorderSizePixel = 1
    dropdown.DropdownFrame.Visible = false
    dropdown.DropdownFrame.ClipsDescendants = true
    dropdown.DropdownFrame.Parent = dropdown.Instance
    
    -- Search bar
    dropdown.SearchBar = Instance.new("TextBox")
    dropdown.SearchBar.Name = "SearchBar"
    dropdown.SearchBar.Size = UDim2.new(1, -10, 0, 30)
    dropdown.SearchBar.Position = UDim2.new(0, 5, 0, 5)
    dropdown.SearchBar.BackgroundColor3 = dropdown.Theme.Foreground
    dropdown.SearchBar.BorderColor3 = dropdown.Theme.Border
    dropdown.SearchBar.BorderSizePixel = 1
    dropdown.SearchBar.PlaceholderText = "Search..."
    dropdown.SearchBar.PlaceholderColor3 = dropdown.Theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
    dropdown.SearchBar.Text = ""
    dropdown.SearchBar.TextColor3 = dropdown.Theme.Text
    dropdown.SearchBar.Font = Enum.Font.SourceSans
    dropdown.SearchBar.TextSize = 14
    dropdown.SearchBar.ClearTextOnFocus = false
    dropdown.SearchBar.Parent = dropdown.DropdownFrame
    
    -- Search icon
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(0, 5, 0.5, -10)
    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://3926305904"
    searchIcon.ImageRectOffset = Vector2.new(964, 324)
    searchIcon.ImageRectSize = Vector2.new(36, 36)
    searchIcon.ImageColor3 = dropdown.Theme.Text
    searchIcon.Parent = dropdown.SearchBar
    
    -- Options frame
    dropdown.OptionsFrame = Instance.new("ScrollingFrame")
    dropdown.OptionsFrame.Name = "Options"
    dropdown.OptionsFrame.Size = UDim2.new(1, -10, 1, -40)
    dropdown.OptionsFrame.Position = UDim2.new(0, 5, 0, 35)
    dropdown.OptionsFrame.BackgroundTransparency = 1
    dropdown.OptionsFrame.BorderSizePixel = 0
    dropdown.OptionsFrame.ScrollBarThickness = 5
    dropdown.OptionsFrame.ScrollBarImageColor3 = dropdown.Theme.Border
    dropdown.OptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropdown.OptionsFrame.Parent = dropdown.DropdownFrame
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Padding = UDim.new(0, 1)
    optionsLayout.Parent = dropdown.OptionsFrame
    
    -- Create options
    dropdown.OptionButtons = {}
    
    local function createOptionButtons(filter)
        -- Clear existing buttons
        for _, button in pairs(dropdown.OptionButtons) do
            button:Destroy()
        end
        dropdown.OptionButtons = {}
        
        -- Create filtered options
        local filteredOptions = {}
        if filter and #filter > 0 then
            local lowerFilter = string.lower(filter)
            for _, option in ipairs(dropdown.Options) do
                if string.find(string.lower(option), lowerFilter) then
                    table.insert(filteredOptions, option)
                end
            end
        else
            filteredOptions = dropdown.Options
        end
        
        -- Create buttons
        for i, option in ipairs(filteredOptions) do
            local button = Instance.new("TextButton")
            button.Name = "Option"..i
            button.Size = UDim2.new(1, 0, 0, 30)
            button.BackgroundColor3 = dropdown.Theme.Foreground
            button.BorderSizePixel = 0
            button.Text = option
            button.TextColor3 = dropdown.Theme.Text
            button.Font = Enum.Font.SourceSans
            button.TextSize = 14
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.AutoButtonColor = false
            button.Parent = dropdown.OptionsFrame
            
            local hoverEffect = Instance.new("Frame")
            hoverEffect.Name = "HoverEffect"
            hoverEffect.Size = UDim2.new(1, 0, 1, 0)
            hoverEffect.Position = UDim2.new(0, 0, 0, 0)
            hoverEffect.BackgroundColor3 = Color3.new(1, 1, 1)
            hoverEffect.BackgroundTransparency = 0.9
            hoverEffect.BorderSizePixel = 0
            hoverEffect.ZIndex = 2
            hoverEffect.Visible = false
            hoverEffect.Parent = button
            
            button.MouseEnter:Connect(function()
                hoverEffect.Visible = true
                Tween(button, {BackgroundColor3 = dropdown.Theme.Foreground:lerp(Color3.new(1, 1, 1), 0.1)}, 0.2)
            end)
            
            button.MouseLeave:Connect(function()
                hoverEffect.Visible = false
                Tween(button, {BackgroundColor3 = dropdown.Theme.Foreground}, 0.2)
            end)
            
            button.MouseButton1Click:Connect(function()
                dropdown.Selected = option
                dropdown.MainButton.Text = option
                dropdown:Toggle()
                dropdown.Callback(option)
            end)
            
            table.insert(dropdown.OptionButtons, button)
        end
    end
    
    createOptionButtons()
    
    -- Dropdown interactions
    function dropdown:Toggle()
        self.IsOpen = not self.IsOpen
        
        if self.IsOpen then
            self.DropdownFrame.Visible = true
            Tween(self.Icon, {Rotation = 180}, 0.2)
        else
            self.DropdownFrame.Visible = false
            Tween(self.Icon, {Rotation = 0}, 0.2)
        end
    end
    
    dropdown.MainButton.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    
    dropdown.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
        createOptionButtons(dropdown.SearchBar.Text)
    end)
    
    -- Close dropdown when clicking outside
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 and dropdown.IsOpen then
            local mousePos = input.Position
            local absPos = dropdown.DropdownFrame.AbsolutePosition
            local absSize = dropdown.DropdownFrame.AbsoluteSize
            
            if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                    mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                dropdown:Toggle()
            end
        end
    end)
    
    -- Dropdown methods
    function dropdown:SetOptions(newOptions)
        self.Options = newOptions or {"Option 1", "Option 2", "Option 3"}
        createOptionButtons(self.SearchBar.Text)
    end
    
    function dropdown:SetSelected(option)
        if table.find(self.Options, option) then
            self.Selected = option
            self.MainButton.Text = option
        end
    end
    
    function dropdown:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function dropdown:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.MainButton.BackgroundColor3 = theme.Foreground
            self.MainButton.BorderColor3 = theme.Border
            self.MainButton.TextColor3 = theme.Text
            self.Icon.ImageColor3 = theme.Text
            self.DropdownFrame.BackgroundColor3 = theme.Foreground
            self.DropdownFrame.BorderColor3 = theme.Border
            self.SearchBar.BackgroundColor3 = theme.Foreground
            self.SearchBar.BorderColor3 = theme.Border
            self.SearchBar.TextColor3 = theme.Text
            self.SearchBar.PlaceholderColor3 = theme.Text:lerp(Color3.new(0.5, 0.5, 0.5), 0.5)
            self.SearchIcon.ImageColor3 = theme.Text
            self.OptionsFrame.ScrollBarImageColor3 = theme.Border
            
            for _, button in pairs(self.OptionButtons) do
                button.BackgroundColor3 = theme.Foreground
                button.TextColor3 = theme.Text
            end
        end
    end
    
    function dropdown:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return dropdown
end

-- Loading spinner component
function Syncore.CreateLoadingSpinner(text)
    local spinner = setmetatable({}, Syncore)
    spinner.Text = text or "Loading..."
    spinner.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create spinner instance
    spinner.Instance = Instance.new("Frame")
    spinner.Instance.Name = "LoadingSpinner"
    spinner.Instance.Size = UDim2.new(0, 150, 0, 50)
    spinner.Instance.BackgroundColor3 = spinner.Theme.Foreground
    spinner.Instance.BorderColor3 = spinner.Theme.Border
    spinner.Instance.BorderSizePixel = 1
    
    -- Spinner
    spinner.Spinner = Instance.new("Frame")
    spinner.Spinner.Name = "Spinner"
    spinner.Spinner.Size = UDim2.new(0, 30, 0, 30)
    spinner.Spinner.Position = UDim2.new(0, 10, 0.5, -15)
    spinner.Spinner.AnchorPoint = Vector2.new(0, 0.5)
    spinner.Spinner.BackgroundTransparency = 1
    spinner.Spinner.Parent = spinner.Instance
    
    local outerCircle = Instance.new("Frame")
    outerCircle.Name = "OuterCircle"
    outerCircle.Size = UDim2.new(1, 0, 1, 0)
    outerCircle.BackgroundTransparency = 1
    outerCircle.BorderColor3 = spinner.Theme.Accent
    outerCircle.BorderSizePixel = 2
    Instance.new("UICorner", outerCircle).CornerRadius = UDim.new(1, 0)
    outerCircle.Parent = spinner.Spinner
    
    local innerCircle = Instance.new("Frame")
    innerCircle.Name = "InnerCircle"
    innerCircle.Size = UDim2.new(0, 10, 0, 10)
    innerCircle.Position = UDim2.new(0.5, -5, 0, 0)
    innerCircle.AnchorPoint = Vector2.new(0.5, 0)
    innerCircle.BackgroundColor3 = spinner.Theme.Accent
    innerCircle.BorderSizePixel = 0
    Instance.new("UICorner", innerCircle).CornerRadius = UDim.new(1, 0)
    innerCircle.Parent = spinner.Spinner
    
    -- Animation
    local spinAnimation = Instance.new("Animation")
    spinAnimation.AnimationId = "rbxassetid://3541114300"
    
    local animator = Instance.new("Animator")
    animator.Parent = spinner.Spinner
    
    local animationTrack = animator:LoadAnimation(spinAnimation)
    animationTrack.Looped = true
    animationTrack:Play()
    
    -- Text
    spinner.TextLabel = Instance.new("TextLabel")
    spinner.TextLabel.Name = "Text"
    spinner.TextLabel.Size = UDim2.new(1, -50, 1, 0)
    spinner.TextLabel.Position = UDim2.new(0, 50, 0, 0)
    spinner.TextLabel.BackgroundTransparency = 1
    spinner.TextLabel.Text = spinner.Text
    spinner.TextLabel.TextColor3 = spinner.Theme.Text
    spinner.TextLabel.Font = Enum.Font.SourceSans
    spinner.TextLabel.TextSize = 14
    spinner.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    spinner.TextLabel.Parent = spinner.Instance
    
    -- Spinner methods
    function spinner:SetText(newText)
        self.Text = newText or "Loading..."
        self.TextLabel.Text = newText or "Loading..."
    end
    
    function spinner:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Instance.BackgroundColor3 = theme.Foreground
            self.Instance.BorderColor3 = theme.Border
            self.Spinner.OuterCircle.BorderColor3 = theme.Accent
            self.Spinner.InnerCircle.BackgroundColor3 = theme.Accent
            self.TextLabel.TextColor3 = theme.Text
        end
    end
    
    function spinner:Destroy()
        animationTrack:Stop()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return spinner
end

-- Volume slider component
function Syncore.CreateVolumeSlider(min, max, callback)
    local volumeSlider = setmetatable({}, Syncore)
    volumeSlider.Min = min or 0
    volumeSlider.Max = max or 100
    volumeSlider.Value = math.floor((max - min) / 2)
    volumeSlider.Callback = callback or function() end
    volumeSlider.Theme = Syncore.Themes[Syncore.DefaultTheme]
    
    -- Create volume slider instance
    volumeSlider.Instance = Instance.new("Frame")
    volumeSlider.Instance.Name = "VolumeSlider"
    volumeSlider.Instance.Size = UDim2.new(0, 200, 0, 40)
    volumeSlider.Instance.BackgroundTransparency = 1
    
    -- Icon
    volumeSlider.Icon = Instance.new("ImageLabel")
    volumeSlider.Icon.Name = "Icon"
    volumeSlider.Icon.Size = UDim2.new(0, 20, 0, 20)
    volumeSlider.Icon.Position = UDim2.new(0, 0, 0.5, -10)
    volumeSlider.Icon.AnchorPoint = Vector2.new(0, 0.5)
    volumeSlider.Icon.BackgroundTransparency = 1
    volumeSlider.Icon.Image = "rbxassetid://3926305904"
    volumeSlider.Icon.ImageRectOffset = Vector2.new(964, 44)
    volumeSlider.Icon.ImageRectSize = Vector2.new(36, 36)
    volumeSlider.Icon.ImageColor3 = volumeSlider.Theme.Text
    volumeSlider.Icon.Parent = volumeSlider.Instance
    
    -- Track
    volumeSlider.Track = Instance.new("Frame")
    volumeSlider.Track.Name = "Track"
    volumeSlider.Track.Size = UDim2.new(1, -30, 0, 4)
    volumeSlider.Track.Position = UDim2.new(0, 30, 0.5, -2)
    volumeSlider.Track.AnchorPoint = Vector2.new(0, 0.5)
    volumeSlider.Track.BackgroundColor3 = volumeSlider.Theme.Foreground
    volumeSlider.Track.BorderColor3 = volumeSlider.Theme.Border
    volumeSlider.Track.BorderSizePixel = 1
    volumeSlider.Track.Parent = volumeSlider.Instance
    
    -- Fill
    volumeSlider.Fill = Instance.new("Frame")
    volumeSlider.Fill.Name = "Fill"
    volumeSlider.Fill.Size = UDim2.new(0, 0, 1, 0)
    volumeSlider.Fill.Position = UDim2.new(0, 0, 0, 0)
    volumeSlider.Fill.BackgroundColor3 = volumeSlider.Theme.Accent
    volumeSlider.Fill.BorderSizePixel = 0
    volumeSlider.Fill.Parent = volumeSlider.Track
    
    -- Thumb
    volumeSlider.Thumb = Instance.new("Frame")
    volumeSlider.Thumb.Name = "Thumb"
    volumeSlider.Thumb.Size = UDim2.new(0, 12, 0, 12)
    volumeSlider.Thumb.Position = UDim2.new(0, 0, 0.5, 0)
    volumeSlider.Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    volumeSlider.Thumb.BackgroundColor3 = volumeSlider.Theme.Accent
    volumeSlider.Thumb.BorderColor3 = volumeSlider.Theme.Border
    volumeSlider.Thumb.BorderSizePixel = 1
    Instance.new("UICorner", volumeSlider.Thumb).CornerRadius = UDim.new(1, 0)
    volumeSlider.Thumb.ZIndex = 2
    volumeSlider.Thumb.Parent = volumeSlider.Instance
    
    -- Volume slider interactions
    local dragging = false
    
    local function updateSlider(value)
        local percent = (value - volumeSlider.Min) / (volumeSlider.Max - volumeSlider.Min)
        volumeSlider.Fill.Size = UDim2.new(percent, 0, 1, 0)
        volumeSlider.Thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        volumeSlider.Value = math.floor(value)
        volumeSlider.Callback(volumeSlider.Value)
    end
    
    volumeSlider.Thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    volumeSlider.Thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    volumeSlider.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local percent = (input.Position.X - volumeSlider.Track.AbsolutePosition.X) / volumeSlider.Track.AbsoluteSize.X
            local value = volumeSlider.Min + (volumeSlider.Max - volumeSlider.Min) * percent
            value = math.clamp(value, volumeSlider.Min, volumeSlider.Max)
            updateSlider(value)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = (input.Position.X - volumeSlider.Track.AbsolutePosition.X) / volumeSlider.Track.AbsoluteSize.X
            local value = volumeSlider.Min + (volumeSlider.Max - volumeSlider.Min) * percent
            value = math.clamp(value, volumeSlider.Min, volumeSlider.Max)
            updateSlider(value)
        end
    end)
    
    -- Initialize slider
    updateSlider(volumeSlider.Value)
    
    -- Volume slider methods
    function volumeSlider:SetValue(value)
        value = math.clamp(value, self.Min, self.Max)
        updateSlider(value)
    end
    
    function volumeSlider:SetRange(min, max)
        self.Min = min
        self.Max = max
        self:SetValue(self.Value) -- Reclamp value
    end
    
    function volumeSlider:SetCallback(newCallback)
        self.Callback = newCallback or function() end
    end
    
    function volumeSlider:SetTheme(themeName)
        local theme = Syncore.Themes[themeName]
        if theme then
            self.Theme = theme
            self.Icon.ImageColor3 = theme.Text
            self.Track.BackgroundColor3 = theme.Foreground
            self.Track.BorderColor3 = theme.Border
            self.Fill.BackgroundColor3 = theme.Accent
            self.Thumb.BackgroundColor3 = theme.Accent
            self.Thumb.BorderColor3 = theme.Border
        end
    end
    
    function volumeSlider:Destroy()
        self.Instance:Destroy()
        setmetatable(self, nil)
    end
    
    return volumeSlider
end

-- Finalize the Syncore library
Syncore.__index = Syncore

function Syncore:SetTheme(themeName)
    self.DefaultTheme = themeName or "Dark"
end

function Syncore:Destroy()
    for _, component in pairs(self.Components) do
        if component.Destroy then
            component:Destroy()
        end
    end
    setmetatable(self, nil)
end

return Syncore
