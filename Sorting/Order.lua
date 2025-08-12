---@class addonTableBaganator
local addonTable = select(2, ...)

-- See comment in Sorting/ItemFields.lua.
-- Values generated are cached across the current sort iteration.
local keysMapping = addonTable.sortItemFieldMap

local itemMetatable = {
  __index = function(self, key)
    if keysMapping[key] then
      local result = keysMapping[key](self)
      self[key] = result
      return result
    end
  end
}

-- Different sort modes, with different sorting criteria based on item data keys
local allSortKeys = {
  ["quality"] = {
    "priority",
    "quality",
    "sortedClassID",
    "sortedInvSlotID",
    "sortedSubClassID",
    "itemLevelRaw",
    "invertedExpansion", -- table.remove removes this on classic
    "itemName",
    "craftingQuality",
    "invertedItemID",
    "invertedItemCount",
    "itemLink",
    "specialSplitting",
  },
  ["type"] = {
    "priority",
    "sortedClassID",
    "sortedInvSlotID",
    "sortedSubClassID",
    "invertedItemLevelRaw",
    "invertedExpansion", -- table.remove removes this on classic
    "invertedQuality",
    "itemName",
    "invertedCraftingQuality",
    "invertedItemID",
    "invertedItemCount",
    "itemLink",
    "specialSplitting",
  },
  ["name"] = {
    "priority",
    "sortedClassID",
    "sortedInvSlotID",
    "sortedSubClassID",
    "invertedExpansion", -- table.remove removes this on classic
    "itemName",
    "invertedItemLevelRaw",
    "invertedQuality",
    "invertedCraftingQuality",
    "invertedItemID",
    "invertedItemCount",
    "itemLink",
    "specialSplitting",
  },
  ["item-level"] = {
    "priority",
    "invertedItemLevelEquipment",
    "sortedClassID",
    "sortedInvSlotID",
    "sortedSubClassID",
    "invertedExpansion", -- table.remove removes this on classic
    "invertedQuality",
    "invertedItemLevelRaw",
    "itemName",
    "invertedCraftingQuality",
    "invertedItemID",
    "invertedItemCount",
    "itemLink",
    "specialSplitting",
  },
  ["expansion"] = {
    "invertedExpansion",
    "sortedClassID",
    "sortedInvSlotID",
    "sortedSubClassID",
    "invertedItemLevelRaw",
    "invertedQuality",
    "itemName",
    "invertedCraftingQuality",
    "invertedItemID",
    "invertedItemCount",
    "itemLink",
    "specialSplitting",
  },
  ["manual"] = {
  }
}

-- Remove expansion sort criteria on classic, as there isn't much expansion
-- content to sort among
if addonTable.Constants.IsClassic then
  table.remove(allSortKeys["quality"], tIndexOf(allSortKeys["quality"], "invertedExpansion"))
  table.remove(allSortKeys["name"], tIndexOf(allSortKeys["type"], "invertedExpansion"))
  table.remove(allSortKeys["type"], tIndexOf(allSortKeys["type"], "invertedExpansion"))
  table.remove(allSortKeys["item-level"], tIndexOf(allSortKeys["item-level"], "invertedExpansion"))
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

function addonTable.Sorting.AddSortKeys(list)
  for index, item in ipairs(list) do
    if item.itemLink then
      setmetatable(item, itemMetatable)

      item.priority = PriorityMap[item.itemID] and 1 or 1000
      if Syndicator.Search.GetClassSubClass then
        Syndicator.Search.GetClassSubClass(item)
      else
        local _
        _, _, _, _, _, item.classID, item.subClassID = C_Item.GetItemInfoInstant(item.itemID)
      end
      if item.classID == nil then -- Fallback for broken items
        item.classID, item.subClassID = -1, -1
      end
      item.invSlotID = C_Item.GetItemInventoryTypeByID(item.itemID) or -1
      item.index = index
      if item.itemID == addonTable.Constants.BattlePetCageID then
        local speciesID = tonumber(item.itemLink:match("battlepet:(%d+)"))
        local petName, _, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        item.itemName = petName
        if not item.subClassID then
          item.subClassID = petType - 1
        end
      end
    end
  end
end

function addonTable.Sorting.OrderOneListOffline(list, sortMethod)
  local reverse = addonTable.Config.Get(addonTable.Config.Options.REVERSE_GROUPS_SORT_ORDER)

  list = tFilter(list, function(a) return a.itemLink ~= nil end, true)

  local sortKeys = allSortKeys[sortMethod]

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
            return a[key] < b[key]
          end
        else
          incomplete = true
        end
      end
      return a.index < b.index
    end)
  end

  return list, incomplete
end
