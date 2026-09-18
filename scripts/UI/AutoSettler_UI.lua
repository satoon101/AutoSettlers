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
            CityPlotIDs[plotID] = nil
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
    local plotID = SettlerManager.FindNearestCityForSettler(unitID, iX, iY)
    if plotID ~= nil then
        local obj = SettlerManager:new(plotID, playerID)
        if obj ~= nil then
            local turnNumber = Game.GetCurrentGameTurn()
            obj:ProcessSettler(turnNumber)
        end
    end
end

Events.UnitAddedToMap.Add(ProcessNewSettler)

print("=== Auto Settlers (UI) Loaded ===")
