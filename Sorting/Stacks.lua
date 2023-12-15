local itemIDToStackSize = {}

function Baganator.Sorting.CombineStacks(bags, bagIDs, indexesToUse, callback)
  if InCombatLockdown() then -- Sorting breaks during combat due to Blizzard restrictions
    return
  end

  local waiting = 0
  local loopComplete = false
  local stacks = {}

  local function Continue()
    if InCombatLockdown() then
      callback(false)
      return
    end

    local anySwaps = false
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
          end

          anySwaps = true
        end
      end
    end
    callback(anySwaps)
  end

  -- Keep lists of all possible stacks to combine for each item ID
  for index, bag in ipairs(bags) do
    local bagID = bagIDs[index]
    for slot, item in ipairs(bag) do
      if item.itemLink then
        stacks[item.itemID] = stacks[item.itemID] or {}
        table.insert(stacks[item.itemID], {item = item, bagID = bagID, slotID = slot})

        if itemIDToStackSize[item.itemID] == nil then
          waiting = waiting + 1
          itemIDToStackSize[item.itemID] = -1
          local item = Item:CreateFromItemID(item.itemID)
          item:ContinueOnItemLoad(function()
            itemIDToStackSize[item.itemID] = select(8, GetItemInfo(item.itemID))
            waiting = waiting - 1
            if waiting == 0 and loopComplete then
              Continue()
            end
          end)
        end
      end
    end
  end
  loopComplete = true
  if waiting == 0 then
    Continue()
  end
end
