local ticker
local pending = {}

local function RerequestItemData()
  for info in pairs(pending) do
    if C_Item.IsItemDataCachedByID(info.itemID) then
      pending[info] = nil
    else
      C_Item.RequestLoadItemDataByID(info.itemID)
    end
  end
  if not next(pending) then
    ticker:Cancel()
    ticker = nil
  end
end

local function GetExpansion(info, itemInfo)
  if ItemVersion then
    local details = ItemVersion.API:getItemVersion(info.itemID, true)
    if details then
      return details.major - 1
    end
  end
  return itemInfo[15]
end

function Baganator.Search.GetBaseInfo(cacheData, earlyCallback, callback)
  earlyCallback = earlyCallback or function() end

  local info = {}

  info.itemLink = cacheData.itemLink
  info.itemID = cacheData.itemID
  info.quality = cacheData.quality
  info.itemCount = cacheData.itemCount or 1
  info.isBound = cacheData.isBound or false

  if C_TooltipInfo then
    info.tooltipGetter = function() return C_TooltipInfo.GetHyperlink(cacheData.itemLink) end
  else
    info.tooltipGetter = function() return Baganator.Utilities.DumpClassicTooltip(function(t) t:SetHyperlink(cacheData.itemLink) end) end
  end

  earlyCallback(info)

  if info.itemLink == nil then
    callback(info)
    return
  end

  info.itemName = ""

  if info.itemLink:find("keystone:", nil, true) then
    info.itemLink = "item:" .. info.itemID
  end

  if info.itemLink:find("battlepet:", nil, true) then
    info.itemInfoWaiting = false
    local petID, level = info.itemLink:match("battlepet:(%d+):(%d*)")

    local itemName, _, petType = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
    info.itemName = itemName
    info.isCraftingReagent = false
    info.classID = Enum.ItemClass.Battlepet
    info.subClassID = petType - 1
    info.isCosmetic = false
    info.isStackable = false
    if level and level ~= "" then
      info.itemLevel = tonumber(level)
    end
    callback(info)

  elseif C_Item.IsItemDataCachedByID(info.itemID) then
    info.itemInfoWaiting = false
    local itemInfo = {GetItemInfo(info.itemLink)}
    info.itemName = itemInfo[1]
    info.isCraftingReagent = itemInfo[17]
    info.classID = itemInfo[12]
    info.subClassID = itemInfo[13]
    info.invType = itemInfo[9]
    info.isCosmetic = IsCosmeticItem and IsCosmeticItem(info.itemLink)
    info.expacID = GetExpansion(info, itemInfo)
    info.isStackable = itemInfo[8] > 1
    callback(info)
  else
    local item = Item:CreateFromItemLink(info.itemLink)
    info.itemInfoWaiting = true
    pending[info] = true
    item:ContinueOnItemLoad(function()
      info.itemInfoWaiting = false
      pending[info] = nil
      local itemInfo = {GetItemInfo(info.itemLink)}
      info.itemName = itemInfo[1]
      info.isCraftingReagent = itemInfo[17]
      info.classID = itemInfo[12]
      info.subClassID = itemInfo[13]
      info.invType = itemInfo[9]
      info.isCosmetic = IsCosmeticItem and IsCosmeticItem(info.itemLink)
      info.expacID = GetExpansion(info, itemInfo)
      info.isStackable = itemInfo[8] > 1
      callback(info)
    end)
  end

  if info.itemInfoWaiting then
    if not ticker then
      ticker = C_Timer.NewTicker(0.1, RerequestItemData)
    end
  end

  return info
end
