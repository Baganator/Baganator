local _, addonTable = ...

function addonTable.ItemViewCommon.GetEquipmentSetInfo(location, itemLink)
  local guid = C_Item.DoesItemExist(location) and C_Item.GetItemGUID(location) or nil

  local results = {}
  for _, source in ipairs(addonTable.API.ItemSetSources) do
    local new = source.getItemSetInfo(location, guid, itemLink)
    if new and #new > 0 then
      tAppendAll(results, new)
    end
  end

  if #results > 0 then
    return results
  else
    return nil
  end
end

function addonTable.ItemViewCommon.GetEquipmentSetNames()
  local results = {}
  for _, source in ipairs(addonTable.API.ItemSetSources) do
    local names = source.getAllSetNames and source.getAllSetNames()
    if names and #names > 0 then
      tAppendAll(results, names)
    end
  end

  return results
end
