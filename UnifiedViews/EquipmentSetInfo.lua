local _, addonTable = ...


function Baganator.UnifiedViews.GetEquipmentSetInfo(location, itemLink)
  local guid = C_Item.DoesItemExist(location) and C_Item.GetItemGUID(location) or nil

  local results = {}
  for _, source in ipairs(addonTable.ItemSetSources) do
    local new = source.getter(location, guid, itemLink)
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
