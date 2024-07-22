local _, addonTable = ...
-- Check source can be contained in target when its available
local function CheckFromTo(bagChecks, source, target)
  return not bagChecks.checks[target.bagID] or bagChecks.checks[target.bagID](source)
end

local IsBagSlotLocked = addonTable.Transfers.IsContainerItemLocked

local function GetSwap(bagChecks, source, targets)
  if IsBagSlotLocked(source) then
    return nil, true
  end

  for index, item in ipairs(targets) do
    assert(item.itemID == nil)
    local outgoing = CheckFromTo(bagChecks, source, item)
    if outgoing then
      table.remove(targets, index)
      return item, false
    end
  end

  return nil, false
end

-- Runs one step of the transfer operation. Returns a value indicating if this
-- needs to be run again on a later frame.
-- bagIDs: The IDs of bags involved with receiving items
-- toMove: Items requested to move {itemID: number, bagID: number, slotID: number}
-- targets: Slots for the items to move to (all empty)
function addonTable.Transfers.FromBagsToBags(toMove, bagIDs, targets)
  if InCombatLockdown() then -- Transfers breaks during combat due to Blizzard restrictions
    return addonTable.Constants.SortStatus.Complete
  end

  local bagChecks = addonTable.Sorting.GetBagUsageChecks(bagIDs)

  -- Prioritise special bags
  targets = addonTable.Transfers.SortChecksFirst(bagChecks, targets)

  local locked, moved = false, false
  -- Move items if possible
  for _, item in ipairs(toMove) do
    local target, swapLocked = GetSwap(bagChecks, item, targets)
    if target then
      C_Container.PickupContainerItem(item.bagID, item.slotID)
      C_Container.PickupContainerItem(target.bagID, target.slotID)
      ClearCursor()
      moved = true
    elseif swapLocked then
      locked = true
    end
  end

  if moved then
    return addonTable.Constants.SortStatus.WaitingMove
  elseif locked then
    return addonTable.Constants.SortStatus.WaitingUnlock
  else
    return addonTable.Constants.SortStatus.Complete
  end
end
