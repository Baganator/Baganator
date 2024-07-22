local _, addonTable = ...
function addonTable.Transfers.GetEmptyBagsSlots(bags, bagIDs)
  local emptySlots = {}
  for index, contents in ipairs(bags) do
    local bagID = bagIDs[index]
    for slotID, item in ipairs(contents) do
      if item.itemID == nil then
        table.insert(emptySlots, {
          bagID = bagID,
          slotID = slotID,
          itemID = nil,
        })
      end
    end
  end
  return emptySlots
end

function addonTable.Transfers.GetEmptyGuildSlots(tab, tabIndex)
  local emptySlots = {}
  for slotID, item in ipairs(tab.slots) do
    if item.itemID == nil then
      table.insert(emptySlots, {
        tabIndex = tabIndex,
        slotID = slotID,
        itemID = nil,
      })
    end
  end
  return emptySlots
end

-- Prioritise items in special bags
function addonTable.Transfers.SortChecksFirst(bagChecks, items)
  local indexes = {}
  for i = 1, #items do
    indexes[i] = i
  end

  table.sort(indexes, function(a, b)
    local aOrder = bagChecks.sortOrder[items[a].bagID]
    local bOrder = bagChecks.sortOrder[items[b].bagID]
    if aOrder == bOrder then
      return a < b
    else
      return aOrder < bOrder
    end
  end)

  local result = {}
  for i, index in ipairs(indexes) do
    result[i] = items[index]
  end
  return result
end

function addonTable.Transfers.IsContainerItemLocked(item)
  if item.itemID == nil then
    return false
  end
  local itemLocation = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
  return C_Item.DoesItemExist(itemLocation) and C_Item.IsLocked(itemLocation)
end

function addonTable.Transfers.IsGuildItemLocked(item)
  local _, _, isLocked = GetGuildBankItemInfo(item.tabIndex, item.slotID)
  return isLocked
end
