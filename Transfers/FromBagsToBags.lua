---@class addonTableBaganator
local addonTable = select(2, ...)
-- Check source can be contained in target when its available
local function CheckFromTo(bagChecks, source, target)
  return not bagChecks.checks[target.bagID] or bagChecks.checks[target.bagID](source)
end

local IsBagSlotLocked = addonTable.Transfers.IsContainerItemLocked

local function GetSwap(bagChecks, source, targets, stackLimit)
  if IsBagSlotLocked(source) then
    return nil, true
  end

  local matchIndex = false
  for index, item in ipairs(targets) do
    matchIndex = matchIndex or (item.itemID == source.itemID and item.itemCount < stackLimit) and index
    if item.itemID == nil or (item.itemID == source.itemID and item.itemCount + source.itemCount <= stackLimit) then
      local outgoing = CheckFromTo(bagChecks, source, item)
      if outgoing then
        table.remove(targets, index)
        return item, false
      end
    end
  end

  -- Combine non-full stacks to maximise quantity transferred
  if matchIndex then
    local item = targets[matchIndex]
    table.remove(targets, matchIndex)
    return item, false
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
  if Syndicator.API.IsBagEventPending() then
    return addonTable.Constants.SortStatus.WaitingMove
  end

  local bagChecks = addonTable.Sorting.GetBagUsageChecks(bagIDs)

  -- Prioritise special bags
  targets = addonTable.Transfers.SortChecksFirst(bagChecks, targets)

  local locked, moved, infoPending = false, false, false
  -- Move items if possible
  for _, item in ipairs(toMove) do
    local stackLimit = C_Item.GetItemMaxStackSizeByID(item.itemID)
    if stackLimit == nil then
      infoPending = true
      C_Item.RequestLoadItemDataByID(item.itemID)
    else
      local target, swapLocked = GetSwap(bagChecks, item, targets, stackLimit)
      if target then
        C_Container.PickupContainerItem(item.bagID, item.slotID)
        C_Container.PickupContainerItem(target.bagID, target.slotID)
        ClearCursor()
        moved = true
      elseif swapLocked then
        locked = true
      end
    end
  end

  if moved then
    return addonTable.Constants.SortStatus.WaitingMove
  elseif locked then
    return addonTable.Constants.SortStatus.WaitingUnlock
  elseif infoPending then
    return addonTable.Constants.SortStatus.WaitingItemData
  else
    if #toMove > 0 then
      UIErrorsFrame:AddMessage(addonTable.Locales.CANNOT_MOVE_ITEMS_AS_NO_SPACE_LEFT, 1.0, 0.1, 0.1, 1.0)
    end
    return addonTable.Constants.SortStatus.Complete
  end
end
