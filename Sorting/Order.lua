local _, addonTable = ...

-- Translate from a base item info to get information hidden behind further API
-- calls
local keysMapping = {}

local itemMetatable = {
  __index = function(self, key)
    if keysMapping[key] then
      local result = keysMapping[key](self)
      self[key] = result
      return result
    end
  end
}

Baganator.Sorting = {}

local allSortKeys = {
  ["quality"] = {
    "priority",
    "quality",
    "sortedClassID",
    "sortedInvSlotID",
    "sortedSubClassID",
    "itemID",
    "itemLink",
    "invertedItemCount",
  },
  ["quality-legacy"] = {
    "priority",
    "quality",
    "classID",
    "subClassID",
    "itemID",
    "itemLink",
    "itemCount",
  },
  ["type"] = {
    "priority", -- custom
    "sortedClassID", -- GetItemInfo -> itemType (https://warcraft.wiki.gg/wiki/API_GetItemInfo)
    "sortedSubClassID", -- GetItemInfo -> subclassID
    "sortedInvSlotID", -- InventorySlotId (https://warcraft.wiki.gg/wiki/InventorySlotId)
    -- "itemLevel",
    "itemID",
    "quality",
    "itemLink",
    "invertedItemCount",
  },
  ["type-legacy"] = {
    "priority",
    "classID",
    "subClassID",
    "itemID",
    "quality",
    "itemLink",
    "itemCount",
  },
  ["expansion"] = {
    "expansion",
    "sortedClassID", -- GetItemInfo -> itemType (https://warcraft.wiki.gg/wiki/API_GetItemInfo)
    "sortedSubClassID", -- GetItemInfo -> subclassID
    "sortedInvSlotID", -- InventorySlotId (https://warcraft.wiki.gg/wiki/InventorySlotId)
    -- "itemLevel",
    "itemID",
    "quality",
    "itemLink",
    "invertedItemCount",
  },
}

-- Custom ordering of classIDs, subClassIDs and inv[entory]SlotIDs. Original
-- configuration supplied by Phraxik
local sorted = {
  classID = {
    18, -- wowtoken
    0, -- consumable
    1, -- container
    5, -- reagent
    6, -- projectile (obsolete)
    2, -- weapon
    4, -- armor
    11, -- quiver (obsolete)
    3, -- gem
    8, -- item enhancement
    16, -- glyph
    7, -- tradegoods
    19, -- profession
    9, -- recipe
    10, -- money (obsolete)
    12, -- quest
    13, -- key
    14, -- permanent (obsolete)
    15, -- misc
    17, -- battle pet
  },
  weaponSubClassID = {
    0, -- 1h axe
    4, -- 1h mace
    7, -- 1h sword
    9, -- warglaives
    15, -- dagger
    13, -- fist weapons
    11, -- bear claws
    12, -- cat claws
    19, -- wands
    1, -- 2h axe
    5, -- 2h mace
    8, -- 2h sword
    6, -- polearm
    10, -- staff
    2, -- bows
    18, -- crossbows
    3, -- guns
    16, -- thrown
    17, -- spears
    14, -- misc
    20, -- fishing pole
  },
  armorSubClassID = {
    6, -- shields
    7, -- librams
    8, -- idols
    9, -- totems
    10, -- sigils
    11, -- relic
    4, -- plate
    3, -- mail
    2, -- leather
    1, -- cloth
    0, -- generic
    5, -- cosmetic
  },
  invSlotID = {
    1, -- head
    3, -- shoulder
    5, -- body
    9, -- wrist
    10, -- hands
    6, -- waist
    7, -- legs
    8, -- feet
    2, -- neck
    15, -- back
    11, -- finger1
    12, -- finger2
    13, -- trinket1
    14, -- trinket2
    4, -- shirt
    19, -- tabard
    16, -- one hand
    17, -- one hand dual/two hand
    20, -- prof tool
    23, -- prof tool
    21, -- prof gear
    22, -- prof gear
    24, -- prof gear
    25, -- prof gear
  },
}

-- Fast lookup to find ordering of a given detail
local sortedMap = {}
for key, list in pairs(sorted) do
  local map = {}
  for index, entry in ipairs(list) do
    map[entry] = index
  end
  sortedMap[key] = map
end

local PriorityItems = {
  6948, -- Hearthstone
}
-- Fast lookup for items that should always be sorted to the start of the bag's
-- items
local PriorityMap = {}
for _, itemID in ipairs(PriorityItems) do
  PriorityMap[itemID] = true
end

keysMapping["expansion"] = function(self)
  local expansion = select(15, GetItemInfo(self.itemLink))
  return expansion
end

-- Unused, but example of how item level could be safely acquired
keysMapping["itemLevel"] = function(self)
  if C_Item.IsItemDataCachedByID(self.itemID) then
    local itemLevel = GetDetailedItemLevelInfo(self.itemLink)
    return itemLevel or -1
  end
end

local function ConvertToOneList(bags, indexesToUse)
  -- Get one long list of the items involved
  local newBags = CopyTable(bags)
  local list = {}
  for bagIndex, bagContents in ipairs(newBags) do
    if indexesToUse[bagIndex] then
      for slotIndex, item in ipairs(bagContents) do
        item.from = { bagIndex = bagIndex, slot = slotIndex}
        if item.itemLink then
          setmetatable(item, itemMetatable)
          local linkToCheck = item.itemLink
          if not linkToCheck:match("item:") then
            linkToCheck = "item:" .. item.itemID
          end

          item.priority = PriorityMap[item.itemID] and 1 or 1000
          item.invertedItemCount = -item.itemCount

          item.classID, item.subClassID = select(6, GetItemInfoInstant(linkToCheck))
          item.sortedClassID = sortedMap.classID[item.classID] or (item.classID + 200)

          if item.classID == Enum.ItemClass.Weapon then
            item.sortedSubClassID = sortedMap.weaponSubClassID[item.subClassID] or (item.subClassID + 200)
          elseif item.classID == Enum.ItemClass.Armor then
            item.sortedSubClassID = sortedMap.armorSubClassID[item.subClassID] or (item.subClassID + 200)
          else
            item.sortedSubClassID = item.subClassID
          end

          local invSlotID = C_Item.GetItemInventoryTypeByID(item.itemID)
          item.sortedInvSlotID = sortedMap.invSlotID[invSlotID] or (invSlotID + 200)
        end
        table.insert(list, item)
      end
    end
  end

  return list
end

local function RemoveIgnoredSlotsFromOneList(list, bagIDs, bagChecks, isEnd, left)
  local offset = 0

  if isEnd then
    while left > 0 and #list > offset do
      local item = list[#list - offset]
      if bagChecks[bagIDs[item.from.bagIndex]] then
        offset = offset + 1
      else
        table.remove(list, #list - offset)
        left = left - 1
      end
    end
  else
    while left > 0 and #list > offset do
      local item = list[1 + offset]
      if bagChecks[bagIDs[item.from.bagIndex]] then
        offset = offset + 1
      else
        table.remove(list, 1 + offset)
        left = left - 1
      end
    end
  end
end

-- We keep an index so that the order is consistent after sort application and
-- resorting of the bag items.
local function SetIndexes(list, bagIDs)
  for index, item in ipairs(list) do
    if item.itemLink then
      local location = ItemLocation:CreateFromBagAndSlot(bagIDs[item.from.bagIndex], item.from.slot)
      item.index = C_Item.GetItemGUID(location)
    end
  end
end

function Baganator.Sorting.OrderOneListOffline(list)
  local start = debugprofilestop()

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("sort convert", debugprofilestop() - start)
  end

  local reverse = Baganator.Config.Get(Baganator.Config.Options.REVERSE_GROUPS_SORT_ORDER)

  list = tFilter(list, function(a) return a.itemLink ~= nil end, true)

  local sortKeys = allSortKeys[Baganator.Config.Get("sort_method")]

  local incomplete = false
  if reverse then
    table.sort(list, function(a, b)
      for _, key in ipairs(sortKeys) do
        if a[key] ~= nil and b[key] ~= nil then
          if a[key] ~= b[key] then
            return a[key] > b[key]
          end
        else
          incomplete = true
        end
      end
      return a.index < b.index
    end)
  else
    table.sort(list, function(a, b)
      for _, key in ipairs(sortKeys) do
        if a[key] ~= nil and b[key] ~= nil then
          if a[key] ~= b[key] then
            return a[key] > b[key]
          end
        else
          incomplete = true
        end
      end
      return a.index < b.index
    end)
  end

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

local function GetPositionStores(bagIDsAvailable, bagSizes)
  local stores = {}
  for _, bagID in ipairs(bagIDsAvailable) do
    stores[bagID] = {first = 1, last = bagSizes[bagID]}
  end

  return stores
end

local function RemoveIgnoredSlotsFromStores(bagStores, bagSizes, bagChecks, bagIDsAvailable, isEnd, left)
  local regularBags = tFilter(bagIDsAvailable, function(bagID) return not bagChecks[bagID] end, true)

  if isEnd then
    for index = #regularBags, 1, -1 do
      local bagID = regularBags[index]
      if bagSizes[bagID] > left then
        bagStores[bagID].last = bagStores[bagID].last - left
        left = 0
        break
      elseif bagSizes[bagID] == left then
        bagStores[bagID] = nil
        left = 0
        break
      else
        left = left - bagSizes[bagID]
        bagStores[bagID] = nil
      end
    end
  else
    for _, bagID in ipairs(regularBags) do
      if bagSizes[bagID] > left then
        bagStores[bagID].first = bagStores[bagID].first + left
        left = 0
        break
      elseif bagSizes[bagID] == left then
        bagStores[bagID] = nil
        left = 0
        break
      else
        left = left - bagSizes[bagID]
        bagStores[bagID] = nil
      end
    end
  end
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

function Baganator.Sorting.ApplyOrdering(bags, bagIDs, indexesToUse, bagChecks, isReverse, ignoreAtEnd, ignoreCount)
  if InCombatLockdown() then -- Sorting breaks during combat due to Blizzard restrictions
    return
  end

  if ignoreCount == nil then
    ignoreCount = 0
  end

  if Baganator.Config.Get(Baganator.Config.Options.SORT_START_AT_BOTTOM) then
    isReverse = not isReverse
  end

  local showTimers = Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS)
  local start = debugprofilestop()

  local bagIDsAvailable, bagSizes = GetUsableBags(bagIDs, indexesToUse, bagChecks, false)
  local bagIDsInverted = GetUsableBags(bagIDs, indexesToUse, bagChecks, true)

  local oneList = ConvertToOneList(bags, indexesToUse)

  if ignoreCount > 0 then
    RemoveIgnoredSlotsFromOneList(oneList, bagIDs, bagChecks, ignoreAtEnd, ignoreCount)
  end

  SetIndexes(oneList, bagIDs)

  local sortedItems, incomplete = Baganator.Sorting.OrderOneListOffline(oneList)
  if showTimers then
    print("sort initial", debugprofilestop() - start)
    start = debugprofilestop()
  end

  local moveQueue0 = {}
  local moveQueue1 = {}

  local bagStores = GetPositionStores(bagIDsAvailable, bagSizes)

  if ignoreCount > 0 then
    RemoveIgnoredSlotsFromStores(bagStores, bagSizes, bagChecks, bagIDsAvailable, ignoreAtEnd, ignoreCount)

    bagIDsAvailable = tFilter(bagIDsAvailable, function(a) return bagStores[a] ~= nil end, true)
    bagIDsInverted = tFilter(bagIDsInverted, function(a) return bagStores[a] ~= nil end, true)
  end

  if showTimers then
    print("sort gens", debugprofilestop() - start)
    start = debugprofilestop()
  end

  local junkPlugin = addonTable.JunkPlugins[Baganator.Config.Get("junk_plugin")]
  local groupA, groupB
  if junkPlugin then
    groupA, groupB = {}, {}
    for _, item in ipairs(sortedItems) do
      if junkPlugin.callback(bagIDs[item.from.bagIndex], item.from.slot, item.itemID, item.itemLink) then
        table.insert(groupB, item)
      else
        table.insert(groupA, item)
      end
    end
  else
    groupA = tFilter(sortedItems, function(item) return item.quality ~= Enum.ItemQuality.Poor end, true)
    groupB = tFilter(sortedItems, function(item) return item.quality == Enum.ItemQuality.Poor end, true)
  end

  if isReverse then
    local tmp = groupA
    groupA = groupB
    groupB = tmp
  end

  if showTimers then
    print("reverse applied", debugprofilestop() - start)
    start = debugprofilestop()
  end

  for index, item in ipairs(groupB) do
    for bagIndex, bagID in ipairs(bagIDsInverted) do
      if not bagChecks[bagID] or bagChecks[bagID](item) then
        local slot = bagStores[bagID].last
        QueueSwap(item, bagID, slot, bagIDs, moveQueue0, moveQueue1)
        bagStores[bagID].last = slot - 1
        if bagStores[bagID].first == slot then
          table.remove(bagIDsInverted, bagIndex)
        end
        break
      end
    end
  end

  bagIDsAvailable = tFilter(bagIDsAvailable, function(bagID) return tIndexOf(bagIDsInverted, bagID) ~= nil end, true)
  for index, item in ipairs(groupA) do
    for bagIndex, bagID in ipairs(bagIDsAvailable) do
      if not bagChecks[bagID] or bagChecks[bagID](item) then
        local slot = bagStores[bagID].first
        QueueSwap(item, bagID, slot, bagIDs, moveQueue0, moveQueue1)
        bagStores[bagID].first = slot + 1
        if bagStores[bagID].last == slot then
          table.remove(bagIDsAvailable, bagIndex)
        end
        break
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

  local pending = incomplete or #moveQueue0 > 0 or #moveQueue1 > 0

  if showTimers then
    print("sort items moved", debugprofilestop() - start)
  end

  return pending
end
