Baganator.Sorting = {}

local QualityKeys = {
  "priority",
  "quality",
  "classID",
  "subClassID",
  "itemID",
  "itemLink",
  "itemCount",
  "index",
}

local TypeKeys = {
  "priority",
  "classID",
  "subClassID",
  "itemID",
  "quality",
  "itemID",
  "itemLink",
  "itemCount",
  "index",
}

local PriorityItems = {
  6948, -- Hearthstone
}
-- Fast lookup for items that should always be sorted to the start of the bag's
-- items
local PriorityMap = {}
for _, itemID in ipairs(PriorityItems) do
  PriorityMap[itemID] = true
end

local function ConvertToOneList(bags, indexesToUse)
  -- Get one long list of the items involved
  local newBags = CopyTable(bags)
  local list = {}
  for bagIndex, bagContents in ipairs(newBags) do
    if indexesToUse[bagIndex] then
      for slotIndex, item in ipairs(bagContents) do
        item.from = { bagIndex = bagIndex, slot = slotIndex}
        item.index = #list + 1
        if item.itemLink then
          local linkToCheck = item.itemLink
          if not linkToCheck:match("item:") then
            linkToCheck = "item:" .. item.itemID
          end
          item.classID, item.subClassID = select(6, GetItemInfoInstant(linkToCheck))
          item.priority = PriorityMap[item.itemID] and 1 or 1000
        end
        table.insert(list, item)
      end
    end
  end

  return list
end

function Baganator.Sorting.SortOneListOffline(bags, indexesToUse, isReverse)
  local start = debugprofilestop()

  local list = ConvertToOneList(bags, indexesToUse)

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("sort convert", debugprofilestop() - start)
  end

  -- We keep an index so that the order is consistent after sort application and
  -- resorting of the bag items.
  -- This part is to handle reversing the items correctly
  if isReverse then
    for _, item in ipairs(list) do
      item.index = #list + 1 - item.index
    end
  end

  list = tFilter(list, function(a) return a.itemLink ~= nil end, true)

  local sortKeys
  if Baganator.Config.Get("sort_method") == "type" then
    sortKeys = TypeKeys
  elseif Baganator.Config.Get("sort_method") == "quality" then
    sortKeys = QualityKeys
  end

  table.sort(list, function(a, b)
    for _, key in ipairs(sortKeys) do
      if a[key] ~= b[key] then
        return a[key] < b[key]
      end
    end
    return false
  end)

  return list
end

local function GetUsableBags(bagIDs, indexesToUse, bagChecks, isReverse)
  -- Arrange bag ids order so the sort applies in the right order
  local preSortedIndexes = {}
  if isReverse then
    for index = #bagIDs, 1, -1 do
      table.insert(preSortedIndexes, index)
    end
  else
    for index = 1, #bagIDs do
      table.insert(preSortedIndexes, index)
    end
  end

  local sortedBagIndexes = {}

  -- Prioritise special bags (reagent, herbalist, etc)
  for _, bagIndex in pairs(preSortedIndexes) do
    if bagChecks[bagIDs[bagIndex]] then
      table.insert(sortedBagIndexes, bagIndex)
    end
  end

  -- Any contents
  for _, bagIndex in pairs(preSortedIndexes) do
    if not bagChecks[bagIDs[bagIndex]] then
      table.insert(sortedBagIndexes, bagIndex)
    end
  end

  local bagIDsAvailable = {}
  local bagSizes = {}

  for _, index in ipairs(sortedBagIndexes) do
    if indexesToUse[index] then
      local bagID = bagIDs[index]
      local size = C_Container.GetContainerNumSlots(bagID)
      if size > 0 then
        bagSizes[bagID] = size
        table.insert(bagIDsAvailable, bagID)
      end
    end
  end

  return bagIDsAvailable, bagSizes
end

local function GetPositionGenerators(bagIDsAvailable, bagState, bagSizes, isReverse)
  local bagLocations = {}
  if isReverse then
    for _, bagID in ipairs(bagIDsAvailable) do
      local first, last = bagSizes[bagID], 1
      bagLocations[bagID] = function(isJunk)
        if not bagState[bagID] then
          return
        end
        local out
        if isJunk then
          out = last
          last = last + 1
        else
          out = first
          first = first - 1
        end
        if first < last then
          bagState[bagID] = nil
        end
        return bagID, out
      end
    end
  else
    for _, bagID in ipairs(bagIDsAvailable) do
      local first, last = 1, bagSizes[bagID]
      bagLocations[bagID] = function(isJunk)
        if not bagState[bagID] then
          return
        end
        local out
        if isJunk then
          out = last
          last = last - 1
        else
          out = first
          first = first + 1
        end
        if first > last then
          bagState[bagID] = nil
        end
        return bagID, out
      end
    end
  end

  return bagLocations
end

local function QueueSwap(item, bagID, slotID, bagIDs, moveQueue0, moveQueue1)
  local target = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
  local fromBag, fromSlot = bagIDs[item.from.bagIndex], item.from.slot
  local source = ItemLocation:CreateFromBagAndSlot(fromBag, fromSlot)
  if fromBag ~= bagID or fromSlot ~= slotID then
    if C_Item.DoesItemExist(source) then
      if not C_Item.DoesItemExist(target) then
        table.insert(moveQueue0, {source, target, item.itemLink})
      else
        table.insert(moveQueue1, {source, target, item.itemLink})
      end
    end
  end
end

function Baganator.Sorting.ApplySort(bags, bagIDs, indexesToUse, bagChecks, isReverse)
  local showTimers = Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS)
  local start = debugprofilestop()
  local sortedItems = Baganator.Sorting.SortOneListOffline(bags, indexesToUse, isReverse)
  if showTimers then
    print("sort initial", debugprofilestop() - start)
    start = debugprofilestop()
  end

  local pending = false

  local moveQueue0 = {}
  local moveQueue1 = {}

  local bagState = {}

  local bagIDsAvailable, bagSizes = GetUsableBags(bagIDs, indexesToUse, bagChecks, isReverse)
  local bagIDsInverted = GetUsableBags(bagIDs, indexesToUse, bagChecks, not isReverse)

  local bagLocations = GetPositionGenerators(bagIDsAvailable, bagState, bagSizes, isReverse)
  if showTimers then
    print("sort gens", debugprofilestop() - start)
    start = debugprofilestop()
  end

  for _, bagID in ipairs(bagIDsAvailable) do
    bagState[bagID] = true
  end

  for itemIndex, item in ipairs(sortedItems) do
    local isJunk = item.quality == Enum.ItemQuality.Poor
    local list
    if isJunk then
      list = bagIDsInverted
    else
      list = bagIDsAvailable
    end

    for _, bagID in ipairs(list) do
      if not bagChecks[bagID] or bagChecks[bagID](item) then
        local bagID, slotID = bagLocations[bagID](isJunk)
        if slotID ~= nil then
          QueueSwap(item, bagID, slotID, bagIDs, moveQueue0, moveQueue1)
          break
        end
      end
    end
  end

  if showTimers then
    print("sort queues ready", debugprofilestop() - start)
    start = debugprofilestop()
  end

  -- Move items that have a blank slot as the target
  for _, move in ipairs(moveQueue0) do
    if not C_Item.IsLocked(move[1]) then
      C_Container.PickupContainerItem(move[1]:GetBagAndSlot())
      C_Container.PickupContainerItem(move[2]:GetBagAndSlot())
      ClearCursor()
    end
  end

  -- Move items that will replace existing items
  for _, move in ipairs(moveQueue1) do
    if not C_Item.IsLocked(move[1]) and not C_Item.IsLocked(move[2]) then
      C_Container.PickupContainerItem(move[1]:GetBagAndSlot())
      C_Container.PickupContainerItem(move[2]:GetBagAndSlot())
      ClearCursor()
    end
  end

  pending = #moveQueue0 > 0 or #moveQueue1 > 0

  if showTimers then
    print("sort items moved", debugprofilestop() - start)
  end

  return pending
end
