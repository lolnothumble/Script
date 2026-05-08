-- [[ BEERUS HUMBLE: UI LIBRARY ]] --
local BeerusLib = {}

local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

function BeerusLib:Init(hubName)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Humble_" .. math.random(100, 999)
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.Position = UDim2.new(0.5, -125, 0.4, 0)
    MainFrame.Size = UDim2.new(0, 250, 0, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TopBar.Size = UDim2.new(1, 0, 0, 35)
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

    local TitleText = Instance.new("TextLabel", TopBar)
    TitleText.Size = UDim2.new(0.5, 0, 1, 0); TitleText.Position = UDim2.new(0, 12, 0, 0); TitleText.BackgroundTransparency = 1; 
    TitleText.Text = hubName or "Beerus Hub"; TitleText.TextColor3 = Color3.fromRGB(255, 255, 255); TitleText.Font = Enum.Font.GothamBold; TitleText.TextSize = 13; TitleText.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 2); CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(200, 50, 50); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; 
    CloseBtn.Modal = true -- Fixes camera lock
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinBtn = Instance.new("TextButton", TopBar)
    MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -65, 0, 2); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "▼"; MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MinBtn.Font = Enum.Font.Gotham; MinBtn.TextSize = 12
    MinBtn.Modal = true -- Fixes camera lock

    local Container = Instance.new("Frame", MainFrame)
    Container.BackgroundTransparency = 1; Container.Position = UDim2.new(0, 0, 0, 40); Container.Size = UDim2.new(1, 0, 0, 0)
    local UIList = Instance.new("UIListLayout", Container)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder; UIList.Padding = UDim.new(0, 5); UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    ------------------------------------------------------------------------------------------
    -- THE DRAGGING ENGINE (Fixed for Camera Movement)
    ------------------------------------------------------------------------------------------
    local dragToggle, dragStart, startPos
    MainFrame.Active = true -- Important for preventing camera drag

    TopBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    ------------------------------------------------------------------------------------------
    -- SIZING LOGIC
    ------------------------------------------------------------------------------------------
    local isMinimized = false
    local function UpdateSize()
        if not isMinimized then
            MainFrame.Size = UDim2.new(0, 250, 0, UIList.AbsoluteContentSize.Y + 50)
        end
    end

    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        local targetHeight = isMinimized and 35 or (UIList.AbsoluteContentSize.Y + 50)
        MainFrame:TweenSize(UDim2.new(0, 250, 0, targetHeight), "Out", "Quart", 0.3, true)
        MinBtn.Text = isMinimized and "▲" or "▼"
    end)

    ------------------------------------------------------------------------------------------
    -- COMPONENT CREATION FUNCTIONS
    ------------------------------------------------------------------------------------------
    function BeerusLib:AddCategory(name, order)
        local CatFrame = Instance.new("Frame", Container); CatFrame.BackgroundTransparency = 1; CatFrame.Size = UDim2.new(0, 230, 0, 30); CatFrame.LayoutOrder = order
        local CatBtn = Instance.new("TextButton", CatFrame); CatBtn.Size = UDim2.new(1, 0, 0, 30); CatBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); CatBtn.Text = "  > " .. name; CatBtn.Font = Enum.Font.Gotham; CatBtn.TextColor3 = Color3.fromRGB(220, 220, 220); CatBtn.TextSize = 12; CatBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", CatBtn).CornerRadius = UDim.new(0, 4)
        local ItemContainer = Instance.new("Frame", CatFrame); ItemContainer.BackgroundTransparency = 1; ItemContainer.Position = UDim2.new(0, 0, 0, 35); ItemContainer.Size = UDim2.new(1, 0, 0, 0); ItemContainer.ClipsDescendants = true
        local ItemList = Instance.new("UIListLayout", ItemContainer); ItemList.Padding = UDim.new(0, 3); ItemList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        local expanded = false
        local function RefreshCatSize()
            if expanded then
                ItemContainer.Size = UDim2.new(1, 0, 0, ItemList.AbsoluteContentSize.Y + 5)
                CatFrame.Size = UDim2.new(1, 0, 0, 40 + ItemList.AbsoluteContentSize.Y)
            else
                ItemContainer.Size = UDim2.new(1, 0, 0, 0)
                CatFrame.Size = UDim2.new(0, 230, 0, 30)
            end
            UpdateSize()
        end
        CatBtn.MouseButton1Click:Connect(function() expanded = not expanded; RefreshCatSize() end)
        ItemList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshCatSize)
        return ItemContainer
    end

    function BeerusLib:AddButton(parent, text, func)
        local Btn = Instance.new("TextButton", parent)
        Btn.Size = UDim2.new(1, -10, 0, 30); Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Btn.Text = text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.Gotham; Btn.TextSize = 11
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseButton1Click:Connect(func)
    end

    function BeerusLib:AddToggle(parent, text, onFunc, offFunc)
        local ToggleBtn = Instance.new("TextButton", parent); local state = false
        ToggleBtn.Size = UDim2.new(1, -10, 0, 30); ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); ToggleBtn.Text = text .. " : OFF"; ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180); ToggleBtn.Font = Enum.Font.Gotham; ToggleBtn.TextSize = 11
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
        ToggleBtn.MouseButton1Click:Connect(function()
            state = not state
            ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(45, 45, 45)
            ToggleBtn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
            ToggleBtn.Text = text .. (state and " : ON" or " : OFF")
            if state and onFunc then onFunc() elseif not state and offFunc then offFunc() end
        end)
    end

    function BeerusLib:AddDropdown(parent, text, list, callback)
        local DropFrame = Instance.new("Frame", parent); DropFrame.BackgroundTransparency = 1; DropFrame.Size = UDim2.new(1, -10, 0, 30); DropFrame.ClipsDescendants = true
        local DropBtn = Instance.new("TextButton", DropFrame); DropBtn.Size = UDim2.new(1, 0, 0, 30); DropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); DropBtn.Text = text .. " : Select..."; DropBtn.TextColor3 = Color3.fromRGB(200, 200, 200); DropBtn.Font = Enum.Font.Gotham; DropBtn.TextSize = 11; DropBtn.ZIndex = 2
        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)
        local OptionContainer = Instance.new("ScrollingFrame", DropFrame); OptionContainer.BackgroundTransparency = 1; OptionContainer.Position = UDim2.new(0, 0, 0, 35); OptionContainer.Size = UDim2.new(1, 0, 0, 0); OptionContainer.CanvasSize = UDim2.new(0, 0, 0, 0); OptionContainer.ScrollBarThickness = 2; OptionContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        local OptionList = Instance.new("UIListLayout", OptionContainer); OptionList.Padding = UDim.new(0, 2)
        local selectedValue, dropExpanded = nil, false
        DropBtn.MouseButton1Click:Connect(function()
            dropExpanded = not dropExpanded
            local listSize = OptionList.AbsoluteContentSize.Y
            local targetHeight = dropExpanded and math.min(listSize + 40, 150) or 30
            DropFrame.Size = UDim2.new(1, -10, 0, targetHeight)
            OptionContainer.Size = dropExpanded and UDim2.new(1, 0, 0, targetHeight - 35) or UDim2.new(1, 0, 0, 0)
            OptionContainer.CanvasSize = UDim2.new(0, 0, 0, listSize)
        end)
        for _, v in pairs(list) do
            local Opt = Instance.new("TextButton", OptionContainer); Opt.Size = UDim2.new(1, -5, 0, 25); Opt.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Opt.Text = tostring(v); Opt.TextColor3 = Color3.fromRGB(255, 255, 255); Opt.Font = Enum.Font.Gotham; Opt.TextSize = 10; Instance.new("UICorner", Opt).CornerRadius = UDim.new(0, 4)
            Opt.MouseButton1Click:Connect(function()
                selectedValue = v; DropBtn.Text = text .. " : " .. tostring(v); dropExpanded = false
                DropFrame.Size = UDim2.new(1, -10, 0, 30); OptionContainer.Size = UDim2.new(1, 0, 0, 0)
            end)
        end
        local state = false
        local ActionBtn = Instance.new("TextButton", parent); ActionBtn.Size = UDim2.new(1, -10, 0, 30); ActionBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); ActionBtn.Text = "Auto " .. text .. " : OFF"; ActionBtn.TextColor3 = Color3.fromRGB(180, 180, 180); ActionBtn.Font = Enum.Font.Gotham; ActionBtn.TextSize = 11; Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)
        ActionBtn.MouseButton1Click:Connect(function()
            if selectedValue == nil then return end 
            state = not state; ActionBtn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(45, 45, 45); ActionBtn.Text = "Auto " .. text .. (state and " : ON" or " : OFF")
            callback(selectedValue, state)
        end)
    end

    function BeerusLib:AddSimpleDropdown(parent, text, list, callback)
        local DropFrame = Instance.new("Frame", parent); DropFrame.BackgroundTransparency = 1; DropFrame.Size = UDim2.new(1, -10, 0, 30); DropFrame.ClipsDescendants = true
        local DropBtn = Instance.new("TextButton", DropFrame); DropBtn.Size = UDim2.new(1, 0, 0, 30); DropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); DropBtn.Text = text .. " : Select..."; DropBtn.TextColor3 = Color3.fromRGB(200, 200, 200); DropBtn.Font = Enum.Font.Gotham; DropBtn.TextSize = 11; DropBtn.ZIndex = 2
        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)
        
        local OptionContainer = Instance.new("ScrollingFrame", DropFrame); OptionContainer.BackgroundTransparency = 1; OptionContainer.Position = UDim2.new(0, 0, 0, 35); OptionContainer.Size = UDim2.new(1, 0, 0, 0); OptionContainer.CanvasSize = UDim2.new(0, 0, 0, 0); OptionContainer.ScrollBarThickness = 2
        local OptionList = Instance.new("UIListLayout", OptionContainer); OptionList.Padding = UDim.new(0, 2)
        
        local dropExpanded = false
        DropBtn.MouseButton1Click:Connect(function()
            dropExpanded = not dropExpanded
            local listSize = OptionList.AbsoluteContentSize.Y
            local targetHeight = dropExpanded and math.min(listSize + 40, 150) or 30
            DropFrame.Size = UDim2.new(1, -10, 0, targetHeight)
            OptionContainer.Size = dropExpanded and UDim2.new(1, 0, 0, targetHeight - 35) or UDim2.new(1, 0, 0, 0)
            OptionContainer.CanvasSize = UDim2.new(0, 0, 0, listSize)
        end)
        
        for _, v in pairs(list) do
            local Opt = Instance.new("TextButton", OptionContainer); Opt.Size = UDim2.new(1, -5, 0, 25); Opt.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Opt.Text = tostring(v); Opt.TextColor3 = Color3.fromRGB(255, 255, 255); Opt.Font = Enum.Font.Gotham; Opt.TextSize = 10; Instance.new("UICorner", Opt).CornerRadius = UDim.new(0, 4)
            Opt.MouseButton1Click:Connect(function()
                DropBtn.Text = text .. " : " .. tostring(v); dropExpanded = false
                DropFrame.Size = UDim2.new(1, -10, 0, 30); OptionContainer.Size = UDim2.new(1, 0, 0, 0)
                callback(v)
            end)
        end
    end

    -- Trigger the initial size update to match standard spacing
    UpdateSize()

    return BeerusLib
end

--------------------------------------------------------------------
-- LOGIC HELPERS (Attached to Library)
--------------------------------------------------------------------
function BeerusLib:CleanNumber(val)
    if not val then return -1 end
    local s = tostring(val):lower():gsub(",", ""):gsub("%s", ""):gsub("%$", ""):gsub("cost:", "")
    local mult = {k = 10^3, m = 10^6, b = 10^9, t = 10^12}
    local n, suffix = s:match("([%d%.]+)(%a*)")
    return n and (tonumber(n) or 0) * (mult[suffix] or 1) or -1
end

return BeerusLib
