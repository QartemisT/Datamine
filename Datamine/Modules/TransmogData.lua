local L = Datamine.Strings;

local moduleName = L.TMOG_INFO_MODULE_NAME;

local Print = function(...)
    Datamine.Print(moduleName, ...);
end;

local Dump = function(tableTitle, ...)
    Datamine.Dump(moduleName, tableTitle, ...);
end;

local TransmogInfoKeys = {
    L.TMOG_INFO_KEYS_SOURCE_TYPE,
    L.TMOG_INFO_KEYS_INVENTORY_TYPE,
    L.TMOG_INFO_KEYS_VISUALID,
    L.TMOG_INFO_KEYS_ISCOLLECTED,
    L.TMOG_INFO_KEYS_SOURCEID,
    L.TMOG_INFO_KEYS_ITEMID,
    L.TMOG_INFO_KEYS_CATEGORYID,
    L.TMOG_INFO_KEYS_ITEMMODID,
};

local DumpTableWithDisplayKeys = function(tableTitle, ...)
    Datamine.DumpTableWithDisplayKeys(moduleName, tableTitle, ...);
end;

---@class DatamineTransmog
Datamine.Transmog = {};

local LinkPrefix = "transmogData";
local TryOnPrefix = "tryOn";

function Datamine.Transmog.HandleLink(pattern)
    local prefix, itemModifiedAppearanceID = strsplit(Datamine.Links.SEPARATOR, pattern);
    if prefix == TryOnPrefix then
        Datamine.ModelView:TryOnByItemModifiedAppearanceID({itemModifiedAppearanceID})
        return;
    end
end

function Datamine.Transmog:GetItemIDLink(itemID)
    local pattern = LinkPrefix .. Datamine.Links.SEPARATOR .. itemID;
    return Datamine.Links.GenerateLinkWithCallback(pattern, itemID, Datamine.Item.HandleLink);
end

function Datamine.Transmog:GetTryOnLink(itemModifiedAppearanceID)
    local pattern = TryOnPrefix .. Datamine.Links.SEPARATOR .. itemModifiedAppearanceID;
    return Datamine.Links.GenerateLinkWithCallback(pattern, L.TMOG_INFO_TRY_ON_LINK_TEXT, Datamine.Transmog.HandleLink);
end

function Datamine.Transmog:GetModifiedAppearanceIDsFromAppearanceID(appearanceID)
    local itemModifiedAppearanceIDs = C_TransmogCollection.GetAllAppearanceSources(appearanceID);

    if not itemModifiedAppearanceIDs or #itemModifiedAppearanceIDs < 1 then
        Print(format(L.TMOG_INFO_ERR_NO_ITEMMODS, appearanceID));
        return;
    end

    local linkTable = {}
    local displayKeys = {}

    for i, v in ipairs(itemModifiedAppearanceIDs) do
        local tryOnLink = self:GetTryOnLink(v);

        displayKeys[i] = v;
        linkTable[i] = tryOnLink;
    end

    DumpTableWithDisplayKeys(format(L.TMOG_INFO_RESULT_ITEMMODS, appearanceID), displayKeys, linkTable);
end

function Datamine.Transmog:GetAppearanceSourceInfo(itemModifiedAppearanceID)
    local sourceInfo = C_TransmogCollection.GetSourceInfo(itemModifiedAppearanceID)
    sourceInfo.categoryID = Datamine.GetEnumValueName(Enum.TransmogCollectionType, sourceInfo.categoryID);
    local _, _, _, itemEquipLoc, _ = GetItemInfoInstant(sourceInfo.itemID);
    local outputTable = {};

    outputTable.Name = sourceInfo.name;
    outputTable.ItemID = self:GetItemIDLink(sourceInfo.itemID);

    if sourceInfo.quality then
        outputTable.Quality = Datamine.GetEnumValueName(Enum.ItemQuality, sourceInfo.quality);
    end

    if itemEquipLoc then
        outputTable.InventoryType = itemEquipLoc;
    else
        outputTable.InventoryType = Datamine.GetEnumValueName(Enum.InventoryType, sourceInfo.invType);
    end

    if sourceInfo.useError then
        outputTable.UseError = sourceInfo.useError;
    end

    if sourceInfo.useErrorType then
        outputTable.UseErrorType = Datamine.GetEnumValueName(Enum.TransmogUseErrorType, sourceInfo.useErrorType);
    end

    if sourceInfo.sourceType then
        outputTable.SourceType = _G["TRANSMOG_SOURCE_"..sourceInfo.sourceType];
    end

    if sourceInfo.meetsTransmogPlayerCondition == false then
        outputTable.MeetsTransmogPlayerCondition = sourceInfo.meetsTransmogPlayerCondition;
    end

    outputTable.VisualID = sourceInfo.visualID;
    outputTable.IsCollected = sourceInfo.isCollected;
    outputTable.SourceID = sourceInfo.sourceID;
    outputTable.IsHideVisual = sourceInfo.isHideVisual;
    outputTable.CategoryID = sourceInfo.categoryID;
    outputTable.ItemModID = sourceInfo.itemModID;

    DumpTableWithDisplayKeys(L.GENERIC_APPEARANCE .. itemModifiedAppearanceID .. "  >> ", nil, outputTable);

    return true;
end

Datamine.Transmog.ArmorSlotVisualOrder = TransmogSlotOrder;
--    INVSLOT_HEAD
--    INVSLOT_SHOULDER
--    INVSLOT_BACK
--    INVSLOT_BODY
--    INVSLOT_CHEST
--    INVSLOT_TABARD
--    INVSLOT_WRIST
--    INVSLOT_HAND
--    INVSLOT_WAIST
--    INVSLOT_LEGS
--    INVSLOT_FEET
--    INVSLOT_MAINHAND
--    INVSLOT_OFFHAND

-- generating tables for hidden appearances to be retrieved later

Datamine.Transmog.HiddenVisualItemIDs = {
    [INVSLOT_HEAD] = 134110,
    [INVSLOT_SHOULDER] = 134112,
    [INVSLOT_BACK] = 134111,
    [INVSLOT_BODY] = 142503,
    [INVSLOT_CHEST] = 168659,
    [INVSLOT_TABARD] = 142504,
    [INVSLOT_WRIST] = 168665,
    [INVSLOT_HAND] = 158329,
    [INVSLOT_WAIST] = 143539,
    [INVSLOT_FEET] = 168664,
};

Datamine.Transmog.HiddenVisualAppearanceIDs = {};
for slot, itemID in pairs(Datamine.Transmog.HiddenVisualItemIDs) do
    local _, sourceID = C_TransmogCollection.GetItemInfo(itemID);
    Datamine.Transmog.HiddenVisualAppearanceIDs[slot] = sourceID;
end

-- some utility functions

---@param itemModifiedAppearanceID number
---@return number invType
function Datamine.Transmog:GetSlotTypeForAppearanceID(itemModifiedAppearanceID)
    local sourceInfo = C_TransmogCollection.GetSourceInfo(itemModifiedAppearanceID);

    return sourceInfo.invType;
end

---@param itemModifiedAppearanceID number
---@return number invSlotID
function Datamine.Transmog:GetSlotIDForAppearanceID(itemModifiedAppearanceID)
    local invType = self:GetSlotTypeForAppearanceID(itemModifiedAppearanceID);
    local invSlot = C_Transmog.GetSlotForInventoryType(invType);

    return invSlot;
end

---@param slotID number
---@return number itemID
function Datamine.Transmog:GetHiddenAppearanceItemIDForSlotID(slotID)
    return self.HiddenVisualItemIDs[slotID];
end

---@param slotID number
---@return number itemModifiedAppearanceID
function Datamine.Transmog:GetHiddenAppearanceForSlotID(slotID)
    return self.HiddenVisualAppearanceIDs[slotID];
end

---@param itemModifiedAppearanceID number
---@return number itemModifiedAppearanceID
function Datamine.Transmog:GetHiddenAppearanceForAppearanceID(itemModifiedAppearanceID)
    local slotID = self:GetSlotIDForAppearanceID(itemModifiedAppearanceID);
    local hiddenAppearanceID = self:GetHiddenAppearanceForSlotID(slotID);

    return hiddenAppearanceID;
end

---@param itemModifiedAppearanceID number
---@return boolean
function Datamine.Transmog:IsHiddenAppearance(itemModifiedAppearanceID)
    return C_TransmogCollection.IsAppearanceHiddenVisual(itemModifiedAppearanceID);
end

---@param itemModifiedAppearanceID number
---@return boolean
function Datamine.Transmog:AppearanceCanBeHidden(itemModifiedAppearanceID)
    if self:IsHiddenAppearance(itemModifiedAppearanceID) then
        return false;
    elseif self:GetHiddenAppearanceForAppearanceID(itemModifiedAppearanceID) then
        return true;
    elseif self:GetSlotIDForAppearanceID(itemModifiedAppearanceID) == INVSLOT_MAINHAND or self:GetSlotIDForAppearanceID(itemModifiedAppearanceID) == INVSLOT_OFFHAND then
        return true;
    else
        return false;
    end
end

---@param itemModifiedAppearanceID number
---@return number itemID
function Datamine.Transmog:GetItemIDForAppearanceID(itemModifiedAppearanceID)
    local sourceInfo = C_TransmogCollection.GetSourceInfo(itemModifiedAppearanceID);
    return sourceInfo.itemID;
end

-- Registering our slash commands

do
    local helpMessage = L.SLASH_CMD_TMOG_ITEMMOD_INFO_HELP;
    local helpString = Datamine.Slash.GenerateHelpStringWithArgs("<itemModifiedAppearanceID>", helpMessage);

    Datamine.Slash:RegisterCommand("appearanceinfo", function(itemModifiedAppearanceID) Datamine.Transmog:GetAppearanceSourceInfo(itemModifiedAppearanceID) end, helpString, moduleName);
end

do
    local helpMessage = L.SLASH_CMD_TMOG_ITEMMOD_FROM_ITEMAPP_HELP;
    local helpString = Datamine.Slash.GenerateHelpStringWithArgs("<itemAppearanceID>", helpMessage);

    Datamine.Slash:RegisterCommand("appearancemods", function(appearanceID) Datamine.Transmog:GetModifiedAppearanceIDsFromAppearanceID(appearanceID) end, helpString, moduleName);
end