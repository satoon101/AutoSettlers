-- ===========================================================================
--  Auto Settler - UI Script
--  Provides Auto Settler UI scripts.
-- ===========================================================================

print("=== Auto Settlers (UI) Loading ===")

include("AutoSettler_Managers")

MovementEnabled = false

function LoadProcessAllSettlers()
    local playerID = Game.GetLocalPlayer()
    ProcessAllSettlers(playerID)
end

function ProcessAllSettlers(playerID)
    local player = Players[playerID]
    if player == nil or not player:IsHuman() then
        return
    end

    MovementEnabled = true
    SettlerManager.ClearMapping()
    GatherCurrentData(playerID)

    -- Remove any city/settler pairs already created
    for plotID in pairs(CityPlotIDs) do
        local obj = SettlerManager:new(plotID)
        obj:FindBaseAttributes()
        if obj.unitID ~= nil then
            SettlerUnitIDs[obj.unitID] = nil
        end
    end

    SettlerManager.FindSettlersForCities()
    local turnNumber = Game.GetCurrentGameTurn()
    SettlerManager.ProcessAllSettlers(turnNumber)
end

Events.LoadGameViewStateDone.Add(LoadProcessAllSettlers)
Events.PlayerTurnActivated.Add(ProcessAllSettlers)

function DisableMovement()
    MovementEnabled = false
end

Events.PlayerTurnDeactivated.Add(DisableMovement)

function ProcessNewSettler(playerID, unitID, iX, iY)
    if not MovementEnabled then
        return
    end

    local player = Players[playerID]
    if player == nil or not player:IsHuman() then
        return
    end

    local unit = UnitManager.GetUnit(playerID, unitID)
    if unit == nil or unit:GetType() ~= SETTLER_INDEX then
        return
    end

    local plot = Map.GetPlot(iX, iY)
    SettlerUnitIDs[unitID] = plot:GetIndex()
    local plotID = SettlerManager.FindNearestCityForSettler(iX, iY)
    if plotID ~= nil then
        local obj = SettlerManager:new(plotID, playerID)
        if obj ~= nil and obj.unitID == nil then
            obj.unitID = unitID
            local turnNumber = Game.GetCurrentGameTurn()
            obj:ProcessSettler(turnNumber)
        end
    end
end

Events.UnitAddedToMap.Add(ProcessNewSettler)

function RemoveMapPins(playerID, _, iX, iY)
    if not MovementEnabled then
        return
    end

    local player = Players[playerID]
    if player == nil or not player:IsHuman() then
        return
    end

    local config = PlayerConfigurations[playerID]
    if config == nil then
        return
    end

    local safePinID = nil
    local cityPinID = nil
    local pins = config:GetMapPins()
    for pinID, pin in pairs(pins) do
        local iconName = pin:GetIconName():gsub("^ICON_", "")
        local x = pin:GetHexX()
        local y = pin:GetHexY()
        if (
            iconName == CITY_PLOT_ICON_NAME and
            x == iX and y == iY
        ) then
            cityPinID = pinID
        elseif iconName == SETTLER_PLOT_ICON_NAME then
            local distance = Map.GetPlotDistance(iX, iY, x, y)
            if distance <= 2 then
                safePinID = pinID
            end
        end

        if cityPinID ~= nil and safePinID ~= nil then
            break
        end
    end

    local values = {
        [safePinID] = SETTLER_PLOT_ICON_NAME,
        [cityPinID] = CITY_PLOT_ICON_NAME,
    }
    for pinID, iconName in pairs(values) do
        iconName = "ICON_" .. iconName
        local pin = pins[pinID]
        local x = pin:GetHexX()
        local y = pin:GetHexY()
        config:DeleteMapPin(pinID)
        Network.BroadcastPlayerInfo()
        LuaEvents.MapPinPopup_OnDelete(playerID, pinID, iconName, x, y)
    end
end

Events.CityInitialized.Add(RemoveMapPins)

local function UpdateSettlerMapPin(playerID, pinID, iconName, iX, iY)
    if not MovementEnabled then
        return
    end

    iconName = iconName:gsub("^ICON_", "")
    if iconName ~= CITY_PLOT_ICON_NAME then
        return
    end

    local plot = Map.GetPlot(iX, iY)
    local feature = plot:GetFeatureType()
    if (
        feature ~= FLOODPLAINS_INDEX
        and feature ~= WOODS_INDEX
        and feature ~= JUNGLE_INDEX
    ) then
        return
    end

    local config = PlayerConfigurations[playerID]
    if config == nil then
        return
    end

    local plotID = FindSettlerSafePlot(plot:GetIndex())
    if plotID == nil then
        local pins = config:GetMapPins()
        local pin = pins[pinID]
        pin:SetIconName("ICON_" .. NEEDS_SAFE_PLOT_ICON_NAME)
        pin:SetName(NEEDS_SAFE_PLOT_NAME)
    else
        local safePlot = Map.GetPlotByIndex(plotID)
        local x = safePlot:GetX()
        local y = safePlot:GetY()
        local pin = config:GetMapPin(x, y)
        pin:SetIconName("ICON_" .. SETTLER_PLOT_ICON_NAME)
        pin:SetName(SETTLER_PLOT_NAME)
    end

    Network.BroadcastPlayerInfo()
end

LuaEvents.MapPinPopup_OnAdd.Add(UpdateSettlerMapPin)

function UpdateMapPinsForSafePlot(playerID, pinID, iconName, iX, iY)
    if not MovementEnabled then
        return
    end

    iconName = iconName:gsub("^ICON_", "")
    if iconName ~= "MAP_PIN_DISTRICT" then
        return
    end

    local config = PlayerConfigurations[playerID]
    if config == nil then
        return
    end

    local pins = config:GetMapPins()
    if pins == nil then
        return
    end

    local pin = pins[pinID]
    if pin == nil then
        return
    end

    pin:SetIconName("ICON_" .. SETTLER_PLOT_ICON_NAME)
    pin:SetName(SETTLER_PLOT_NAME)
    Network.BroadcastPlayerInfo()

    local barbPin = nil
    for _, checkPin in pairs(pins) do
        if (
            checkPin:GetName() == NEEDS_SAFE_PLOT_NAME and
            checkPin:GetIconName() == "ICON_" .. NEEDS_SAFE_PLOT_ICON_NAME
        ) then
            local x = checkPin:GetHexX()
            local y = checkPin:GetHexY()
            local distance = Map.GetPlotDistance(iX, iY, x, y)
            if distance <= 3 then
                barbPin = checkPin
                break
            end
        end
    end

    if barbPin == nil then
        return
    end

    barbPin:SetIconName("ICON_" .. SETTLER_PLOT_ICON_NAME)
    barbPin:SetName(SETTLER_PLOT_NAME)
    Network.BroadcastPlayerInfo()
end

LuaEvents.MapPinPopup_OnAdd.Add(UpdateMapPinsForSafePlot)

print("=== Auto Settlers (UI) Loaded ===")
