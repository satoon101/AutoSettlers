include("AutoSettler_Helpers")

SettlerManager = {}
SettlerManager.__index = SettlerManager
SettlerManager.Registry = {}

function SettlerManager:new(plotID, playerID)
    if SettlerManager.Registry[plotID] then
        return SettlerManager.Registry[plotID]
    end

    local instance = {
        plotID = plotID,
        playerID = playerID,
        settlerPlotID = nil,
        buildTurn = nil,
        unitID = nil
    }

    setmetatable(instance, self)
    SettlerManager.Registry[plotID] = instance
    return instance
end

function SettlerManager:FindBaseAttributes()
    if self.buildTurn ~= nil then
        return
    end

    local plot = Map.GetPlotByIndex(self.plotID)
    local x = plot:GetX()
    local y = plot:GetY()
    local radiusPlots = Map.GetNeighborPlots(x, y, 3)
    for i = 1, #radiusPlots do
        local checkPlot = radiusPlots[i]
        local checkPlotID = checkPlot:GetIndex()
        if WonderPlotIDs[checkPlotID] ~= nil then
            local wonderName = WonderPlotIDs[checkPlotID]
            local info = GameInfo.Buildings[wonderName]
            if info ~= nil and info.IsWonder then
                if CityFoundingTurnByName[info.BuildingType] ~= nil then
                    self.buildTurn = CityFoundingTurnByName[info.BuildingType]
                else
                    local prereq = (
                        GameInfo.Civics[info.PrereqCivic] or
                        GameInfo.Technologies[info.PrereqTech]
                    )
                    if prereq ~= nil then
                        local era = GameInfo.Eras[prereq.EraType].Index
                        self.buildTurn = CityFoundingTurnByWonderEra[era]
                    end
                end
            end
        elseif SettlerIconPlotIDs[checkPlotID] ~= nil then
            self.settlerPlotID = checkPlotID
        end
    end
end

function SettlerManager:FindNearestSettler()
    local plot = Map.GetPlotByIndex(self.plotID)
    local x = plot:GetX()
    local y = plot:GetY()
    local closestUnitID = nil
    local closestDistance = nil
    for unitID, plotID in pairs(SettlerUnitIDs) do
        local checkPlot = Map.GetPlotByIndex(plotID)
        local x2 = checkPlot:GetX()
        local y2 = checkPlot:GetY()
        local distance = Map.GetPlotDistance(x, y, x2, y2)
        if (
            closestUnitID == nil or
            distance < closestDistance
        ) then
            closestUnitID = unitID
            closestDistance = distance
        end
    end
    if closestUnitID ~= nil then
        SettlerUnitIDs[closestUnitID] = nil
        self.unitID = closestUnitID
    end
end

function SettlerManager:MoveToPlot(plotID, skipTurn)
    local unit = UnitManager.GetUnit(self.playerID, self.unitID)
    if unit == nil then
        return
    end

    local plot = Map.GetPlotByIndex(plotID)
    local params = {
        [UnitOperationTypes.PARAM_X] = plot:GetX(),
        [UnitOperationTypes.PARAM_Y] = plot:GetY(),
    }
    UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, params)
    if skipTurn then
        UnitManager.RequestOperation(unit, SKIP_TURN_HASH, {})
    end
end

function SettlerManager:ProcessSettler(turnNumber)
    local unit = UnitManager.GetUnit(self.playerID, self.unitID)
    if unit == nil then
        return
    end

    local moveToPlotID = self.settlerPlotID or self.plotID
    local unitPlotID = Map.GetPlot(unit:GetX(), unit:GetY()):GetIndex()
    if self.buildTurn <= turnNumber then
        if unitPlotID ~= self.plotID then
            self:MoveToPlot(self.plotID, false)
        elseif self.buildTurn + 1 <= turnNumber then
            UnitManager.RequestCommand(unit, UnitCommandTypes.WAKE, {})
        else
            UnitManager.RequestOperation(unit, SLEEP_HASH, {})
        end
    elseif unitPlotID ~= moveToPlotID then
        self:MoveToPlot(moveToPlotID, true)
    else
        UnitManager.RequestOperation(unit, SLEEP_HASH, {})
    end
end

function SettlerManager.ClearMapping()
    for plotID in pairs(SettlerManager.Registry) do
        local plot = Map.GetPlotByIndex(plotID)
        if plot:GetDistrictType() ~= -1 then
            SettlerManager.Registry[plotID] = nil
        end
    end
end

function SettlerManager.FindSettlersForCities()
    for _, instance in pairs(SettlerManager.Registry) do
        if instance.unitID == nil then
            instance:FindNearestSettler()
        end
    end
end

function SettlerManager.ProcessAllSettlers(turnNumber)
    for _, instance in pairs(SettlerManager.Registry) do
        if instance.unitID ~= nil then
            instance:ProcessSettler(turnNumber)
        end
    end
end

function SettlerManager.FindNearestCityForSettler(unitID, iX, iY)
    local closestPlotID = nil
    local closestDistance = nil
    for _, instance in pairs(SettlerManager.Registry) do
        if instance.unitID == nil then
            local checkPlot = Map.GetPlotByIndex(instance.plotID)
            local x2 = checkPlot:GetX()
            local y2 = checkPlot:GetY()
            local distance = Map.GetPlotDistance(iX, iY, x2, y2)
            if (
                closestPlotID == nil or
                distance < closestDistance
            ) then
                closestPlotID = instance.plotID
                closestDistance = distance
            end
        end
    end

    return closestPlotID
end

print("=== Auto Settlers (Managers) Loaded ===")
