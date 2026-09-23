-- ===========================================================================
--  Auto Settler - UI Script
--  Provides Auto Settler UI scripts.
-- ===========================================================================

print("=== Auto Settlers (UI) Loading ===")

include("AutoSettler_Managers")

FinishedInitialization = false

function LoadProcessAllSettlers()
    FinishedInitialization = true
    ProcessAllSettlers()
end

function ProcessAllSettlers(playerID)
    if playerID == nil then
        playerID = Game.GetLocalPlayer()
    end

    local player = Players[playerID]
    if player == nil or not player:IsHuman() then
        return
    end

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

function ProcessNewSettler(playerID, unitID, iX, iY)
    if not FinishedInitialization then
        return
    end

    local plot = Map.GetPlot(iX, iY)
    SettlerUnitIDs[unitID] = plot:GetIndex()
    local plotID = SettlerManager.FindNearestCityForSettler(iX, iY)
    if plotID ~= nil then
        local obj = SettlerManager:new(plotID, playerID)
        if obj ~= nil then
            local turnNumber = Game.GetCurrentGameTurn()
            obj:ProcessSettler(turnNumber)
        end
    end
end

Events.UnitAddedToMap.Add(ProcessNewSettler)

function RemoveSafePlotMapPin(playerID, _, x1, y1)
    local player = Players[playerID]
    if player == nil or not player:IsHuman() then
        return
    end

    local config = PlayerConfigurations[playerID]
    if config == nil then
        return
    end

    local foundPinID = nil
    local iconName = "ICON_MAP_PIN_DISTRICT"
    local pins = config:GetMapPins()
    for pinID, pin in pairs(pins) do
        if pin:GetIconName() == iconName then
            local x2 = pin:GetHexX()
            local y2 = pin:GetHexY()
            local distance = Map.GetPlotDistance(x1, y1, x2, y2)
            if distance <= 2 then
                foundPinID = pinID
                break
            end
        end
    end

    local pin = pins[foundPinID]
    local x = pin:GetHexX()
    local y = pin:GetHexY()
    config:DeleteMapPin(foundPinID)
    Network.BroadcastPlayerInfo()
    LuaEvents.MapPinPopup_OnDelete(playerID, foundPinID, iconName, x, y)
end

Events.CityInitialized.Add(RemoveSafePlotMapPin)

print("=== Auto Settlers (UI) Loaded ===")
