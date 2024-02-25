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
  info.itemCount = cacheData.itemCount
  info.isBound = cacheData.isBound

  if C_TooltipInfo then
    info.tooltipGetter = function() return C_TooltipInfo.GetHyperlink(info.itemLink) end
  else
    info.tooltipGetter = function() return Baganator.Utilities.DumpClassicTooltip(function(t) t:SetHyperlink(info.itemLink) end) end
  end

  earlyCallback(info)

  if info.itemLink == nil then
    return
  end

  info.itemName = ""

  if cacheData.itemLink:find("keystone:", nil, true) then
    info.itemLink = "item:" .. cacheData.itemID
  end

  if cacheData.itemLink:find("battlepet:", nil, true) then
    info.itemInfoWaiting = false
    local petID, level = cacheData.itemLink:match("battlepet:(%d+):(%d*)")

    info.itemName = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
    info.isCraftingReagent = false
    info.classID = Enum.ItemClass.Battlepet
    info.isCosmetic = false
    if level and level ~= "" then
      info.itemLevel = tonumber(level)
    end
    callback(info)

  elseif C_Item.IsItemDataCachedByID(cacheData.itemID) then
    info.itemInfoWaiting = false
    local itemInfo = {GetItemInfo(cacheData.itemLink)}
    info.itemName = itemInfo[1]
    info.isCraftingReagent = itemInfo[17]
    info.classID = itemInfo[12]
    info.subClassID = itemInfo[13]
    info.invType = itemInfo[9]
    info.isCosmetic = IsCosmeticItem and IsCosmeticItem(cacheData.itemLink)
    info.expacID = GetExpansion(info, itemInfo)
    callback(info)
  else
    local item = Item:CreateFromItemLink(cacheData.itemLink)
    info.itemInfoWaiting = true
    item:ContinueOnItemLoad(function()
      info.itemInfoWaiting = false
      local itemInfo = {GetItemInfo(cacheData.itemLink)}
      info.itemName = itemInfo[1]
      info.isCraftingReagent = itemInfo[17]
      info.classID = itemInfo[12]
      info.subClassID = itemInfo[13]
      info.invType = itemInfo[9]
      info.isCosmetic = IsCosmeticItem and IsCosmeticItem(cacheData.itemLink)
      info.expacID = GetExpansion(info, itemInfo)
      callback(info)
    end)
  end

  return info
end
