local _, addonTable = ...
-- Check the sort priority (so special bags get filled up first) and
-- corresponding bag contents checks (e.g. reagents only) if any
function addonTable.Sorting.GetBagUsageChecks(bagIDs)
  local checks = {}
  local sortOrder = {}
  if addonTable.Constants.IsRetail and tIndexOf(bagIDs, Enum.BagIndex.ReagentBag) ~= nil then
    checks[Enum.BagIndex.ReagentBag] = function(item)
      return item.itemID and (select(17, C_Item.GetItemInfo(item.itemID)))
    end
    sortOrder[Enum.BagIndex.ReagentBag] = 10 -- reagent bags go after special bags
  end
  if addonTable.Constants.IsRetail and tIndexOf(bagIDs, Enum.BagIndex.Reagentbank) ~= nil then
    checks[Enum.BagIndex.Reagentbank] = function(item)
      return (select(17, C_Item.GetItemInfo(item.itemID)))
    end
    sortOrder[Enum.BagIndex.Reagentbank] = 10 -- reagent bags go after special bags
  end
  if not addonTable.Constants.IsRetail and tIndexOf(bagIDs, Enum.BagIndex.Keyring) ~= nil then
    checks[Enum.BagIndex.Keyring] = function(item)
      local itemFamily = item.itemID and C_Item.GetItemFamily(item.itemID)
      return itemFamily == addonTable.Constants.KeyItemFamily
    end
    sortOrder[Enum.BagIndex.Keyring] = 1
  end

  for _, bagID in ipairs(bagIDs) do
    local _, family = C_Container.GetContainerNumFreeSlots(bagID)
    if family ~= nil and family ~= 0 then
      checks[bagID] = function(item)
        local itemFamily = item.itemID and C_Item.GetItemFamily(item.itemID)
        return itemFamily and item.classID ~= Enum.ItemClass.Container and item.classID ~= Enum.ItemClass.Quiver and bit.band(itemFamily, family) ~= 0
      end
      sortOrder[bagID] = 5 -- special bags go after keyrings
    elseif sortOrder[bagID] == nil then
      sortOrder[bagID] = 250 -- regular bags go last
    end
  end

  return {checks = checks, sortOrder = sortOrder}
end
