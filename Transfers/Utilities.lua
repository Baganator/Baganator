---@class addonTableBaganator
local addonTable = select(2, ...)
function addonTable.Transfers.GetBagsSlots(bags, bagIDs)
  local filledSlots = {}
  local emptySlots = {}
  for index, contents in ipairs(bags) do
    local bagID = bagIDs[index]
    for slotID, item in ipairs(contents) do
      local newItem = {
        bagID = bagID,
        slotID = slotID,
      }
      Mixin(newItem, item)
      if newItem.itemID == nil then
        table.insert(emptySlots, newItem)
      else
        table.insert(filledSlots, newItem)
      end
    end
  end

  local slots = filledSlots
  tAppendAll(slots, emptySlots)

  return slots
end

function addonTable.Transfers.GetGuildSlots(tab, tabIndex)
  local filledSlots = {}
  local emptySlots = {}

  for slotID, item in ipairs(tab.slots) do
    local newItem = {
      tabIndex = tabIndex,
      slotID = slotID,
    }
    Mixin(newItem, item)
    if newItem.itemID == nil then
      table.insert(emptySlots, newItem)
    else
      table.insert(filledSlots, newItem)
    end
  end

  local slots = filledSlots
  tAppendAll(slots, emptySlots)

  return slots
end

-- Prioritise items in special bags
function addonTable.Transfers.SortChecksFirst(bagChecks, items)
  local indexes = {}
  for i = 1, #items do
    indexes[i] = i
  end

  table.sort(indexes, function(a, b)
    -- Group existing stacks
    if items[a].itemID and not items[b].itemID then
      return true
    elseif items[b].itemID and not items[a].itemID then
      return false
    end

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

function addonTable.Transfers.CountByItemIDs(slots)
  local result = {}
  for _, item in ipairs(slots) do
    if item.itemID then
      result[item.itemID] = (result[item.itemID] or 0) + item.itemCount
    end
  end
  return result
end
