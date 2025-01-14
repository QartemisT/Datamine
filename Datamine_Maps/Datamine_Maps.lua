local addonName, maps = ...;

---@class DatamineMapGrids
---@field MapTextures table<number>
---@field MapTexturesN table<number>
---@field MinimapTextures table<number>

---@class DatamineMapInfo
---@field MapID number
---@field Directory string | number
---@field MapName string
---@field MapDescription0 string
---@field MapDescription1 string
---@field MapType number
---@field InstanceType number
---@field ExpansionID number
---@field ParentMapID number
---@field CosmeticParentMapID number
---@field Grids DatamineMapGrids

local MAX_TILES_X = 64;
local MAX_TILES_Y = 64;
local MAX_TILES = MAX_TILES_X * MAX_TILES_Y;

---@class DatamineMaps
Datamine.Maps = {};

---@param mapName string
---@return DatamineMapInfo?
function Datamine.Maps.GetMapInfoByName(mapName)
    for map in pairs(maps) do
        if map.MapName == mapName then
            return map
        end
    end
end

---@param wdtFileDataID number
---@return DatamineMapInfo?
function Datamine.Maps.GetMapInfoByWdtID(wdtFileDataID)
    return maps[wdtFileDataID];
end

function Datamine.Maps.GetAllMaps()
    return maps;
end

function Datamine.Maps.GetMapNameByWdtID(wdtID)
    local map = maps[wdtID];
    if map then
        return map.MapName;
    end
end

function Datamine.Maps.ConvertCoordsToLookupString(x, y)
    return format("%02d,%02d", x, y);
end

---@class DatamineGridCoords
---@field X number
---@field Y number

---@class DatamineGridData
---@field X number
---@field Y number
---@field TextureID number

---@class DatamineMapCanvasSize : DatamineGridCoords

---@class DatamineMapBounds
---@field Top number
---@field Bottom number
---@field Left number
---@field Right number

---@class DatamineMapDisplayInfo
---@field Grids table<DatamineGridData>
---@field Bounds DatamineMapBounds
---@field HasContent boolean

---@param map DatamineMapInfo | number
---@return DatamineMapDisplayInfo? mapInfo
local function PreprocessMapDisplayInfo(map)
    if type(map) == "number" then
        local info = Datamine.Maps.GetMapInfoByWdtID(map);
        if not info then
            return;
        end
        map = info;
    end

    local y, x = 0, 0;
    local mapInfo = {
        Grids = {},
        Bounds = {
            Top = 0, -- x
            Bottom = 0, -- x
            Left = 0, -- y
            Right = 0, -- y
        },
        HasContent = false,
    };

    for _, grid in pairs(map.Grids.MinimapTextures) do
        local gridData = {
            Y = y,
            X = x,
            TextureID = grid,
        };

        if grid ~= 0 then
            mapInfo.HasContent = true;

            if mapInfo.Bounds.Left == 0 then
                mapInfo.Bounds.Left = y;
            end
            if mapInfo.Bounds.Top == 0 then
                mapInfo.Bounds.Top = x;
            end

            mapInfo.Bounds.Bottom = x;
            mapInfo.Bounds.Right = y;
        end

        tinsert(mapInfo.Grids, gridData);

        if y < MAX_TILES_Y then
            y = y + 1;
        else
            y = 0;
            if x < MAX_TILES_X then
                x = x + 1;
            else
                x = 0;
            end
        end
    end

    return mapInfo;
end

---@param wdtFileDataID number
---@return DatamineMapDisplayInfo?
function Datamine.Maps.GetMapDisplayInfoByWdtID(wdtFileDataID)
    local map = maps[wdtFileDataID];
    if map then
        return PreprocessMapDisplayInfo(map);
    end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    Datamine.EventRegistry:TriggerEvent(Datamine.Events.MAPVIEW_MAP_DATA_LOADED);
end);