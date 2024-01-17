-- Prioritise items in special bags
local function SortChecksFirst(bagChecks, items)
  local indexes = {}
  for i = 1, #items do
    indexes[i] = i
  end

  table.sort(indexes, function(a, b)
    local aCheck = bagChecks[items[a].bagID]
    local bCheck = bagChecks[items[b].bagID]
    if aCheck and not bCheck then
      return true
    elseif bCheck and not aCheck then
      return false
    else
      return a < b
    end
  end)

  local result = {}
  for i, index in ipairs(indexes) do
    result[i] = items[index]
  end
  return result
end

-- Check source can be contained in target when its available
local function CheckFromTo(bagChecks, source, target)
  return not bagChecks[target.bagID] or bagChecks[target.bagID](source)
end

local function IsLocked(item)
  if item.itemID == nil then
    return false
  end
  local itemLocation = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
  return C_Item.DoesItemExist(itemLocation) and C_Item.IsLocked(itemLocation)
end

local function GetSwap(bagChecks, source, targets)
  if IsLocked(source) then
    return nil, nil, true
  end

  for index, item in ipairs(targets) do
    if IsLocked(item) then
      table.remove(targets, index)
      return nil, nil, true
    else
      local outgoing = CheckFromTo(bagChecks, source, item)
      if outgoing then
        table.remove(targets, index)
        if item.itemID == nil then
          return source, item, false
        else
          local incoming = CheckFromTo(bagChecks, item, source)
          if incoming then
            return source, item, false
          end
        end
      end
    end
  end

  return nil, nil, false
end

-- Runs one step of the transfer operation. Returns a value indicating if this
-- needs to be run again on a later frame.
-- bagIDs: The IDs of bags involved with taking or receiving items
-- toMove: Items requested to move {itemID: number, bagID: number, slotID: number}
-- targets: Slots for the items to move to (empty or not)
function Baganator.Sorting.Transfer(bagIDs, toMove, targets)
  if InCombatLockdown() then -- Transfers breaks during combat due to Blizzard restrictions
    return Baganator.Constants.SortStatus.Complete
  end

  local bagChecks = Baganator.Sorting.GetBagUsageChecks(bagIDs)

  -- Prioritise special bags
  targets = SortChecksFirst(bagChecks, targets)

  local locked, moved = false, false
  -- Move items if possible
  for _, item in ipairs(toMove) do
    local source, target, swapLocked = GetSwap(bagChecks, item, targets)
    if source and target then
      C_Container.PickupContainerItem(source.bagID, source.slotID)
      C_Container.PickupContainerItem(target.bagID, target.slotID)
      ClearCursor()
      moved = true
    elseif swapLocked then
      locked = true
    end
  end

  if moved then
    return Baganator.Constants.SortStatus.WaitingMove
  elseif locked then
    return Baganator.Constants.SortStatus.WaitingUnlock
  else
    return Baganator.Constants.SortStatus.Complete
  end
end
