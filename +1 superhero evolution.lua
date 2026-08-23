local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/lolnothumble/Script/refs/heads/main/HumbleScriptzHub(mobile%26pc).txt"))()

local Window = Library:CreateWindow({
    Name = "HSZ HUB",
    Owner = "HumbleScriptz",
    DiscordLink = "https://discord.gg/KZAqAZZwvP",
    YoutubeLink = "https://youtube.com/@humblescript?"
})

-- ===== SERVICES & VARIABLES =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local SharedRemotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local PlayerClickRemote = SharedRemotes:WaitForChild("PlayerClick")
local RequestRebirthRF = SharedRemotes:WaitForChild("RequestRebirth")
local ClaimPlaytimeRewardRemote = SharedRemotes:WaitForChild("ClaimPlaytimeReward")

-- State Toggles
local autoClick = false
local autoRebirth = false
local autoFightNPC = false
local autoFightAllStages = false
local autoClaimRewards = false
local autoBuyBestPower = false
local autoEquipBestPower = false
local lockTrainingZone = false
local lockedTrainingCFrame = nil

-- State Selections
local selectedStage = "Stage1"
local selectedTrainingZone = ""

-- Cache Maps
local stageDataMap = {}
local trainingZoneDataMap = {}

-- ===== HELPER FUNCTIONS =====

local function parseNumber(str)
    if not str then return 0 end
    local clean = tostring(str):gsub(",", "")
    local num = tonumber(clean:match("[%d%.]+")) or 0
    local upper = clean:upper()

    if upper:find("[%d%.]%s*T") then
        return num * 1e12
    elseif upper:find("[%d%.]%s*B") then
        return num * 1e9
    elseif upper:find("[%d%.]%s*M") then
        return num * 1e6
    elseif upper:find("[%d%.]%s*K") then
        return num * 1e3
    end
    return num
end

local function formatNumber(val)
    local n = tonumber(val) or 0
    if n >= 1e12 then
        return string.format("%.2fT", n / 1e12):gsub("%.00", "")
    elseif n >= 1e9 then
        return string.format("%.2fB", n / 1e9):gsub("%.00", "")
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6):gsub("%.00", "")
    elseif n >= 1e3 then
        return string.format("%.2fK", n / 1e3):gsub("%.00", "")
    end
    return tostring(math.floor(n))
end

local function triggerPromptSafe(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local promptPart = prompt.Parent:IsA("BasePart") and prompt.Parent 
        or prompt.Parent:FindFirstChildWhichIsA("BasePart") 
        or prompt.Parent.Parent:FindFirstChildWhichIsA("BasePart", true)
    
    if hrp and promptPart then
        if (hrp.Position - promptPart.Position).Magnitude > prompt.MaxActivationDistance then
            hrp.CFrame = promptPart.CFrame + Vector3.new(0, 2, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.2)
        end
    end

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 0)
        prompt:InputHoldEnd()
    end
end

local function teleportPlayer(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    else
        char:PivotTo(targetCFrame)
    end
end

local function getMyPower()
    local power = 0
    pcall(function()
        local label = LocalPlayer.PlayerGui.ScreenGui.Bottom.Holder.BarContainer.StatDisplay.Value
        if label and label:IsA("TextLabel") and label.Text ~= "" then
            power = parseNumber(label.Text)
        end
    end)
    if power == 0 then
        pcall(function()
            local bottom = LocalPlayer.PlayerGui.ScreenGui:FindFirstChild("Bottom", true)
            for _, d in ipairs(bottom:GetDescendants()) do
                if d:IsA("TextLabel") and (d.Name == "Value" or d.Name == "StatDisplay") then
                    local p = parseNumber(d.Text)
                    if p > power then power = p end
                end
            end
        end)
    end
    return power
end

local function getWins()
    local wins = 0
    pcall(function()
        local label = LocalPlayer.PlayerGui.ScreenGui.BottomLeft.Container.WinsDisplay.Value
        if label and label:IsA("TextLabel") then
            wins = parseNumber(label.Text)
        end
    end)
    return wins
end

local function getRebirths()
    local rebirths = 0
    pcall(function()
        local label = LocalPlayer.PlayerGui.ScreenGui.BottomLeft.Container.RebirthDisplay.Value
        if label and label:IsA("TextLabel") then
            rebirths = parseNumber(label.Text)
        end
    end)
    return rebirths
end

local function getStageRecommendation(stage)
    if not stage then return "0 Power", 0 end
    local gate = stage:FindFirstChild("Gate")
    local infoGui = gate and gate:FindFirstChild("InfoGui")
    local rec = infoGui and infoGui:FindFirstChild("Recommendation")
    if rec and rec:IsA("TextLabel") and rec.Text ~= "" then
        local raw = rec.Text
        local num = parseNumber(raw)
        if not raw:lower():find("power") then
            return raw .. " Power", num
        end
        return raw, num
    end
    return "0 Power", 0
end

local function getDirectPartPosition(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then
        return instance.Position
    end
    local hitbox = instance:FindFirstChild("Hitbox") or instance:FindFirstChild("Part") or instance:FindFirstChildWhichIsA("BasePart")
    if hitbox then
        return hitbox.Position
    end
    return nil
end

local function getExactStageMidpoint(stage)
    if not stage then return nil end

    local gate = stage:FindFirstChild("Gate")
    local barrier = stage:FindFirstChild("Barrier")

    local gatePos = getDirectPartPosition(gate)
    local barrierPos = getDirectPartPosition(barrier)

    if gatePos and barrierPos then
        local mid = (gatePos + barrierPos) / 2
        return CFrame.new(mid + Vector3.new(0, 15, 0))
    elseif barrierPos then
        return CFrame.new(barrierPos + Vector3.new(0, 15, 0))
    elseif gatePos then
        return CFrame.new(gatePos + Vector3.new(0, 15, 0))
    end

    return nil
end

local function isBarrierCleared(stage)
    if not stage then return true end
    local barrier = stage:FindFirstChild("Barrier")
    if barrier and barrier:IsA("BasePart") then
        return barrier.Transparency >= 0.95
    end
    return true
end

local function claimStageWinPad(stage)
    if not stage then return end
    local padPart = stage:FindFirstChild("Pad")
        and stage.Pad:FindFirstChild("Free")
        and stage.Pad.Free:FindFirstChild("Pad")

    if padPart then
        teleportPlayer(padPart.CFrame + Vector3.new(0, 2.5, 0))
        task.wait(0.35)
        PlayerClickRemote:FireServer()
    end
end

local function fightStageUntilClear(stage, isTargetFinalStage)
    if not stage then return false end
    local midCFrame = getExactStageMidpoint(stage)
    if not midCFrame then return false end

    local timeout = 0
    while (autoFightNPC or autoFightAllStages) and timeout < 25 do
        teleportPlayer(midCFrame)
        PlayerClickRemote:FireServer()
        task.wait(0.05)
        timeout = timeout + 0.05

        if timeout >= 1.5 and isBarrierCleared(stage) then
            break
        end
    end

    if isTargetFinalStage then
        claimStageWinPad(stage)
    end

    return true
end

local function getLiveMaxStages()
    local stagesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Stages")
    local count = 0
    if stagesFolder then
        for _, child in ipairs(stagesFolder:GetChildren()) do
            local num = tonumber(child.Name:match("^Stage(%d+)$"))
            if num and num > count then
                count = num
            end
        end
    end
    return count > 0 and count or 10
end

local function updateLockedTrainingZone(zoneDisplayName)
    local data = trainingZoneDataMap[zoneDisplayName]
    local lobbyDecor = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Lobby") and Workspace.Map.Lobby:FindFirstChild("Decor") and Workspace.Map.Lobby.Decor:FindFirstChild("Extra")
    local hitbox = data and data.Hitbox or (lobbyDecor and lobbyDecor:FindFirstChild(zoneDisplayName:match("^(%S+)")) and lobbyDecor[zoneDisplayName:match("^(%S+)")]:FindFirstChild("Hitbox"))
    
    if hitbox and hitbox:IsA("BasePart") then
        lockedTrainingCFrame = hitbox.CFrame + Vector3.new(0, 2.5, 0)
        teleportPlayer(lockedTrainingCFrame)
    end
end

-- Scans FoodDisplay stands: excludes Robux stands (SpecialItemBillboard / LimitedItemBillboard)
local function getAllFoodStands()
    local stands = {}
    local foodDisplay = Workspace:FindFirstChild("Map")
        and Workspace.Map:FindFirstChild("Lobby")
        and Workspace.Map.Lobby:FindFirstChild("FoodDisplay")
    
    if foodDisplay then
        for _, stand in ipairs(foodDisplay:GetChildren()) do
            local anchor = stand:FindFirstChild("Anchor")
            if anchor then
                -- Strict Robux check: SpecialItemBillboard, LimitedItemBillboard, or Robux symbols
                local isRobux = anchor:FindFirstChild("SpecialItemBillboard") ~= nil 
                    or anchor:FindFirstChild("LimitedItemBillboard") ~= nil

                if not isRobux then
                    for _, d in ipairs(anchor:GetDescendants()) do
                        if d:IsA("TextLabel") and (string.find(d.Text:lower(), "r%$") or string.find(d.Text:lower(), "robux")) then
                            isRobux = true
                            break
                        end
                    end
                end

                if not isRobux then
                    local billboard = anchor:FindFirstChild("ItemBillboard")
                    local gainLabel = billboard and billboard:FindFirstChild("GainLabel")
                    local gainVal = (gainLabel and gainLabel:IsA("TextLabel")) and parseNumber(gainLabel.Text) or 0

                    local statusLabel = billboard and billboard:FindFirstChild("StatusLabel")
                    local statusRaw = (statusLabel and statusLabel:IsA("TextLabel")) and statusLabel.Text:lower() or ""

                    local isEquipped = (statusRaw == "equipped") or (statusRaw:find("equipped") ~= nil)
                    local isEquipAvailable = not isEquipped and (statusRaw == "equip" or statusRaw:find("equip") ~= nil)
                    local isBuy = statusRaw:find("buy") ~= nil or statusRaw == ""

                    local winReq = billboard and billboard:FindFirstChild("WinRequirement")
                    local winLabel = winReq and winReq:FindFirstChild("WinLabel")
                    local winCost = (winLabel and winLabel:IsA("TextLabel")) and parseNumber(winLabel.Text) or 0

                    local prompt = anchor:FindFirstChildWhichIsA("ProximityPrompt", true)

                    table.insert(stands, {
                        Stand = stand,
                        Anchor = anchor,
                        Gain = gainVal,
                        IsEquipped = isEquipped,
                        IsEquipAvailable = isEquipAvailable,
                        IsBuy = isBuy,
                        Cost = winCost,
                        Prompt = prompt,
                        Index = tonumber(stand.Name:match("%d+")) or 0
                    })
                end
            end
        end
    end
    return stands
end

-- Auto Equip: Only swaps if an unequipped owned power has a HIGHER gain than the currently equipped power
local function equipBestOwnedPower()
    local stands = getAllFoodStands()

    local currentEquippedGain = -1
    for _, data in ipairs(stands) do
        if data.IsEquipped then
            if data.Gain > currentEquippedGain then
                currentEquippedGain = data.Gain
            end
        end
    end

    local bestPromptToEquip = nil
    local bestAvailableGain = currentEquippedGain

    for _, data in ipairs(stands) do
        if data.IsEquipAvailable and data.Prompt then
            if data.Gain > bestAvailableGain then
                bestAvailableGain = data.Gain
                bestPromptToEquip = data.Prompt
            end
        end
    end

    if bestPromptToEquip then
        triggerPromptSafe(bestPromptToEquip)
    end
end

-- Auto Buy Best Affordable Power (Excludes SpecialItemBillboard & LimitedItemBillboard)
local function buyBestAffordablePower(myWins)
    local stands = getAllFoodStands()
    local highestGain = -1
    local bestPrompt = nil

    for _, data in ipairs(stands) do
        if data.IsBuy and myWins >= data.Cost and data.Prompt then
            if data.Gain >= highestGain then
                highestGain = data.Gain
                bestPrompt = data.Prompt
            end
        end
    end

    if bestPrompt then
        triggerPromptSafe(bestPrompt)
    end
end

-- ===== DYNAMIC SCANNERS =====

local function getAvailableStages()
    local list = {}
    stageDataMap = {}

    local stagesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Stages")
    local maxCount = getLiveMaxStages()

    for sIndex = 1, maxCount do
        local stage = stagesFolder and stagesFolder:FindFirstChild("Stage" .. sIndex)
        if stage then
            local recText, reqPower = getStageRecommendation(stage)

            local padPart = stage:FindFirstChild("Pad")
                and stage.Pad:FindFirstChild("Free")
                and stage.Pad.Free:FindFirstChild("Pad")
            
            local winText = "+Wins"
            if padPart then
                local bb = padPart:FindFirstChild("PadBillboard")
                local amountLabel = bb and bb:FindFirstChild("Win") and bb.Win:FindFirstChild("AmountLabel")
                if amountLabel and amountLabel:IsA("TextLabel") and amountLabel.Text ~= "" then
                    winText = amountLabel.Text
                end
            end

            local displayName = "Stage" .. sIndex .. " [Rec: " .. recText .. "] [" .. winText .. "]"

            stageDataMap[displayName] = {
                StageName = "Stage" .. sIndex,
                StageInstance = stage,
                ReqPower = reqPower,
                StageNumber = sIndex
            }
            table.insert(list, displayName)
        end
    end

    if #list == 0 then
        for i = 1, 10 do
            local fallback = "Stage" .. i .. " [Rec: " .. (i * 10) .. " Power] [+" .. (i * 5) .. " Wins]"
            stageDataMap[fallback] = {
                StageName = "Stage" .. i,
                StageNumber = i,
                ReqPower = i * 10
            }
            table.insert(list, fallback)
        end
    end

    return list
end

local function getAvailableTrainingZones()
    local zones = {}
    trainingZoneDataMap = {}

    pcall(function()
        local extraFolder = Workspace:FindFirstChild("Map")
            and Workspace.Map:FindFirstChild("Lobby")
            and Workspace.Map.Lobby:FindFirstChild("Decor")
            and Workspace.Map.Lobby.Decor:FindFirstChild("Extra")

        if extraFolder then
            for _, zone in ipairs(extraFolder:GetChildren()) do
                local hitbox = zone:FindFirstChild("Hitbox")
                if hitbox then
                    local isRobux = false
                    for _, d in ipairs(zone:GetDescendants()) do
                        if d:IsA("TextLabel") and (string.find(d.Text:lower(), "r%$") or string.find(d.Text:lower(), "robux")) then
                            isRobux = true
                            break
                        end
                    end

                    local multText = "1x"
                    local reqRebirths = 0

                    local bb = hitbox:FindFirstChild("TrainingZoneBillboard")
                    if bb then
                        local multLabel = bb:FindFirstChild("MultiplierLabel")
                        if multLabel and multLabel:IsA("TextLabel") and multLabel.Text ~= "" then
                            multText = multLabel.Text
                        end

                        local rebirthReq = bb:FindFirstChild("RebirthRequirement")
                        local rebLabel = rebirthReq and rebirthReq:FindFirstChild("RebirthLabel")
                        if rebLabel and rebLabel:IsA("TextLabel") and rebLabel.Text ~= "" then
                            reqRebirths = parseNumber(rebLabel.Text)
                        end
                    end

                    local tag = isRobux and " [ROBUX]" or (" [" .. reqRebirths .. " Rebirths]")
                    local displayName = zone.Name .. " [" .. multText .. "]" .. tag

                    trainingZoneDataMap[displayName] = {
                        ZoneName = zone.Name,
                        Hitbox = hitbox,
                        MultiplierText = multText,
                        ReqRebirths = reqRebirths,
                        IsRobux = isRobux,
                        Number = tonumber(zone.Name:match("%d+")) or 1
                    }
                    table.insert(zones, displayName)
                end
            end
        end
    end)

    if #zones == 0 then
        local fallback1 = "TrainingZone1 [2x] [0 Rebirths]"
        trainingZoneDataMap[fallback1] = { ZoneName = "TrainingZone1", ReqRebirths = 0, Number = 1 }
        table.insert(zones, fallback1)
    end

    table.sort(zones, function(a, b)
        local numA = trainingZoneDataMap[a] and trainingZoneDataMap[a].Number or 0
        local numB = trainingZoneDataMap[b] and trainingZoneDataMap[b].Number or 0
        return numA < numB
    end)

    return zones
end

-- ===== BACKGROUND LOOPS =====

-- 1. Auto Clicker
task.spawn(function()
    while true do
        if autoClick then
            pcall(function()
                PlayerClickRemote:FireServer()
            end)
        end
        task.wait(0.05)
    end
end)

-- 2. Auto Rebirth (At 100%)
task.spawn(function()
    while true do
        if autoRebirth then
            pcall(function()
                local label = LocalPlayer.PlayerGui.ScreenGui.LeftSide.Container.MenuButtons.Rebirth.Progress
                if label and label:IsA("TextLabel") and string.find(label.Text, "100%%") then
                    RequestRebirthRF:InvokeServer()
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- 3. Auto Claim Playtime Rewards (1-12)
task.spawn(function()
    while true do
        if autoClaimRewards then
            pcall(function()
                for i = 1, 12 do
                    ClaimPlaytimeRewardRemote:FireServer(i)
                    task.wait(0.1)
                end
            end)
        end
        task.wait(5)
    end
end)

-- 4. Auto Fight Selected Stage
task.spawn(function()
    while true do
        if autoFightNPC and selectedStage ~= "" then
            local targetStageNum = tonumber(selectedStage:match("Stage(%d+)")) or 1
            local stagesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Stages")

            if stagesFolder then
                for sIndex = 1, targetStageNum do
                    if not autoFightNPC then break end
                    local stage = stagesFolder:FindFirstChild("Stage" .. sIndex)

                    if stage then
                        local isTargetFinal = (sIndex == targetStageNum)
                        fightStageUntilClear(stage, isTargetFinal)
                        task.wait(0.3)
                    end
                end
     