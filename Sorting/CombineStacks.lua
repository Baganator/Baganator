local _, addonTable = ...
local itemIDToStackSize = {}

local function DoMovement(stacks)
  if InCombatLockdown() then
    return false
  end

  local moved, locked = false, false
  for itemID, stacksForItem in pairs(stacks) do
    local stackSize = itemIDToStackSize[itemID]
    if stackSize > 1 then
      local total = 0
      local fullStacks = 0
      for _, details in ipairs(stacksForItem) do
        total = details.item.itemCount + total
        if details.item.itemCount == stackSize then
          fullStacks = fullStacks + 1
        end
      end

      local targetFullStacks = math.floor(total / stackSize)
      local targetStacks = math.ceil(total / stackSize)

      if #stacksForItem > targetStacks or fullStacks ~= targetFullStacks then
        -- Get incomplete stacks sorting in ascending order
        local partials = tFilter(stacksForItem, function(a) return a.item.itemCount ~= stackSize end, true)
        table.sort(partials, function(a, b) return a.item.itemCount < b.item.itemCount end)

        local source, target = partials[1], partials[#partials]

        local sourceLocation = ItemLocation:CreateFromBagAndSlot(source.bagID, source.slotID)
        local targetLocation = ItemLocation:CreateFromBagAndSlot(target.bagID, target.slotID)
        if not C_Item.IsLocked(sourceLocation) and not C_Item.IsLocked(targetLocation) then
          -- No need to split the stack as the Blizzard engine will do that
          -- for us to combine the stacks
          C_Container.PickupContainerItem(source.bagID, source.slotID)
          C_Container.PickupContainerItem(target.bagID, target.slotID)
          ClearCursor()
          moved = true
        else
          locked = true
        end
      end
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

local function GetBagStacks(bags, bagIDs, callback)
  local waiting = 0
  local loopComplete = false
  local stacks = {}

  -- Keep lists of all possible stacks to combine for each item ID
  for index, bag in ipairs(bags) do
    local bagID = bagIDs[index]
    for slot, item in ipairs(bag) do
      if item.itemLink then
        stacks[item.itemID] = stacks[item.itemID] or {}
        local location = ItemLocation:CreateFromBagAndSlot(bagID, slot)
        -- Existence check in case bag data is out of sync (e.g. for a
        -- bank-to-bag transfer)
        if C_Item.DoesItemExist(location) then
          table.insert(stacks[item.itemID], {item = item, bagID = bagID, slotID = slot})
        end

        if itemIDToStackSize[item.itemID] == nil then
          waiting = waiting + 1
          itemIDToStackSize[item.itemID] = -1
          addonTable.Utilities.LoadItemData(item.itemID, function()
            itemIDToStackSize[item.itemID] = select(8, C_Item.GetItemInfo(item.itemID))
            waiting = waiting - 1
            if waiting == 0 and loopComplete then
              callback(stacks)
            end
          end)
        end
      end
    end
  end
  loopComplete = true
  if waiting == 0 then
    callback(stacks)
  end
end

function addonTable.Sorting.CombineStacks(bags, bagIDs, callback)
  if InCombatLockdown() then -- Sorting breaks during combat due to Blizzard restrictions
    return addonTable.Constants.SortStatus.Complete
  end

  GetBagStacks(bags, bagIDs, function(stacks)
    local status = DoMovement(stacks)
    callback(status)
  end)
end
