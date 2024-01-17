
local function GetLocationsByItemID(bags, bagIDs)
  local map = {}
  for index, bag in ipairs(bags) do
    for slotIndex, slot in ipairs(bag) do
      local itemID = slot.itemID
      if itemID == nil then
        itemID = -1
      end
      if not map[itemID] then
        map[itemID] = {}
      end
      table.insert(map[itemID], {bagID = bagIDs[index], slotID = slotIndex, bagIndex = index, itemCount = slot.itemCount, itemID = slot.itemID}) 
    end
  end
  for _, list in pairs(map) do
    table.sort(list, function(a, b)
      if a.itemCount == b.itemCount then
        if a.bagIndex == b.bagIndex then
          return a.slotID < b.slotID
        else
          return a.bagIndex < b.bagIndex
        end
      else
        return a.itemCount > b.itemCount
      end
    end)
  end
  return map
end

local isBagCheck = {}
for _, bagID in pairs(Baganator.Constants.AllBagIndexes) do
  isBagCheck[bagID] = true
end
local isBankCheck = {}
for _, bankID in pairs(Baganator.Constants.AllBankIndexes) do
  isBankCheck[bankID] = true
end

local function SplitByWantedToBag(itemIDToQuantities, stackLimit)
  local toMove, unwantedBagItems, emptyBankSlots = {}, {}, {}
  if itemIDToQuantities[-1] then
    for _, item in ipairs(itemIDToQuantities[-1]) do
      if isBankCheck[item.bagID] then
        table.insert(emptyBankSlots, item)
      else
        table.insert(unwantedBagItems, item)
      end
    end
  end
  for itemID, quantities in pairs(itemIDToQuantities) do
    if itemID ~= -1 then
      local index = 1
      while index <= stackLimit do 
        local item = quantities[index]
        if isBankCheck[item.bagID] then
          table.insert(toMove, item)
        end
        index = index + 1
      end
      while index <= #quantities do
        local item = quantities[index]
        if isBagCheck[item.bagID] then
          table.insert(unwantedBagItems, item)
        end
        index = index + 1
      end
    end
  end
  return toMove, unwantedBagItems, emptyBankSlots
end

-- Set the bag to have exactly X (stackLimit) stacks of everything the player
-- possesses in the bag and bank.
function Baganator.Sorting.ApplyStackLimit(stackLimit)
  if InCombatLockdown() then -- Breaks during combat due to Blizzard restrictions
    return Baganator.Constants.SortStatus.Complete
  end

  local mergedBags, mergedIDs = Baganator.Sorting.GetMergedBankBags(Baganator.Utilities.GetCharacterFullName())
  local map = GetLocationsByItemID(mergedBags, mergedIDs)

  local toMove, unwantedInBag, emptyBankSlots = SplitByWantedToBag(map, stackLimit)

  return Baganator.Sorting.Transfer(mergedIDs, toMove, unwantedInBag, emptyBankSlots)
end
