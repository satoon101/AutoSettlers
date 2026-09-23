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
        if iconName == "MAP_PIN_DISTRICT" then
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

print("=== Auto Settlers (Helpers) Loaded ===")
