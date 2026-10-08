include("AutoSettler_Config")

SettlerIconPlotIDs = {}
CityPlotIDs = {}
SettlerUnitIDs = {}
WonderPlotIDs = {}
SettlersOnIconPlots = {}

function GatherCurrentData(playerID)
    SettlerIconPlotIDs = {}
    CityPlotIDs = {}
    SettlerUnitIDs = {}
    SettlersOnIconPlots = {}
    local config = PlayerConfigurations[playerID]
    local pins = config:GetMapPins()
    for _, pin in pairs(pins) do
        local iconName = pin:GetIconName():gsub("^ICON_", "")
        local plot = Map.GetPlot(pin:GetHexX(), pin:GetHexY())
        local plotID = plot:GetIndex()
        if iconName == "UNIT_SETTLER" then
            SettlerIconPlotIDs[plotID] = true
        elseif iconName == "DISTRICT_CITY_CENTER" then
            CityPlotIDs[plotID] = true
        elseif (
            GameInfo.Buildings[iconName] ~= nil and
            GameInfo.Buildings[iconName].IsWonder
        ) then
            WonderPlotIDs[plotID] = iconName
        end
    end

    local player = Players[playerID]
    local units = player:GetUnits()
    for _, unit in units:Members() do
        if unit:GetType() == SETTLER_INDEX then
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            if plot ~= nil then
                local plotID = plot:GetIndex()
                local unitID = unit:GetID()
                if (
                    SettlerIconPlotIDs[plotID] ~= nil
                    or CityPlotIDs[plotID] ~= nil
                ) then
                    SettlersOnIconPlots[plotID] = unitID
                end
                SettlerUnitIDs[unitID] = plot:GetIndex()
            end
        end
    end
end

function FindSettlerSafePlot(plotID)
    local function IsSafePlot(checkPlot)
        if checkPlot:IsWater() then
            return false
        end

        if checkPlot:IsMountain() then
            return false
        end

        local feature = checkPlot:GetFeatureType()
        if (
            feature == FLOODPLAINS_INDEX
            or feature == WOODS_INDEX
            or feature == JUNGLE_INDEX
        ) then
            return false
        end

        return true
    end

    local plot = Map.GetPlotByIndex(plotID)
    local x = plot:GetX()
    local y = plot:GetY()
    local checkedPlots = {}
    for direction = 0, 5 do
        local adjacentPlot = Map.GetAdjacentPlot(x, y, direction)
        local adjacentPlotID = adjacentPlot:GetIndex()
        if IsSafePlot(adjacentPlot) then
            return adjacentPlotID
        end

        checkedPlots[adjacentPlotID] = true
    end

    for direction = 0, 5 do
        local adjacentPlot = Map.GetAdjacentPlot(x, y, direction)
        for direction2 = 0, 5 do
            local x2 = adjacentPlot:GetX()
            local y2 = adjacentPlot:GetY()
            local adjacentPlot2 = Map.GetAdjacentPlot(x2, y2, direction2)
            local adjacentPlotID2 = adjacentPlot2:GetIndex()
            if checkedPlots[adjacentPlotID2] == nil then
                if IsSafePlot(adjacentPlot2) then
                    return adjacentPlotID2
                end

                checkedPlots[adjacentPlotID2] = true
            end
        end
    end

    return nil
end

print("=== Auto Settlers (Helpers) Loaded ===")
