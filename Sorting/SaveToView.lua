local function GetLocationsByItemID(bags, bagIDs)
  local map = {}
  for index, bag in ipairs(bags) do
    for slotIndex, slot in ipairs(bag) do
      local itemID = slot.itemID
      if itemID ~= nil then
        if not map[itemID] then
          map[itemID] = {}
        end
        table.insert(map[itemID], {bagID = bagIDs[index], slotID = slotIndex, itemID = slot.itemID}) 
      end
    end
  end
  return map
end

function Baganator.Sorting.SaveToView(from, fromIDs, to, toIDs)
  local allFrom = GetLocationsByItemID(from, fromIDs)
  local allTo = GetLocationsByItemID(to, toIDs)

  local toMove = {}
  for itemID in pairs(allTo) do
    if allFrom[itemID] then
      for _, item in ipairs(allFrom[itemID]) do
        table.insert(toMove, item)
      end
    end
  end

  local emptyToSlots = Baganator.Sorting.GetEmptySlots(to, toIDs)

  local mergedIDs = CopyTable(fromIDs)
  tAppendAll(mergedIDs, toIDs)

  return Baganator.Sorting.Transfer(mergedIDs, toMove, emptyToSlots, {})
end
