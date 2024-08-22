local _, addonTable = ...

-- Translate from a base item info to get information hidden behind further API
-- calls
-- Function stored on the sort key's corresponding field returns nil if the item
-- information isn't ready yet - which will cause the sort to try again later
-- when the information is hopefully ready
local keysMapping = {}
addonTable.sortItemFieldMap = keysMapping

-- Custom ordering of classIDs, subClassIDs and inv[entory]SlotIDs. Original
-- configuration supplied by Phraxik
local sorted = {
  classID = {
    18, -- wowtoken
    0, -- consumable
    5, -- reagent
    6, -- projectile (obsolete)
    2, -- weapon
    4, -- armor
    11, -- quiver (obsolete)
    3, -- gem
    8, -- item enhancement
    16, -- glyph
    1, -- container
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
    17, -- 2h weapon
    13, -- weapon
    21, -- weapon main
    14, -- shield
    23, -- holdable
    26, -- ranged right
    22, -- weapon off
    15, -- ranged
    25, -- thrown
    24, -- ammo
    27, -- quiver
    28, -- relic
    1, -- head
    3, -- shoulder
    16, -- cloak
    5, -- chest
    20, -- robe
    9, -- wrist
    10, -- hand
    6, -- waist
    7, -- legs
    8, -- feet
    2, -- neck
    11, -- finger
    12, -- trinket
    4, -- body/shirt
    19, -- tabard
    29, -- prof tool
    30, -- prof gear
    18, -- bag
    31, -- spell offensive
    32, -- spell utility
    33, -- spell defensive
    34, -- spell weapon
    0, -- non equipable
  },
  tradegoodSubClassID = {
    18, -- optional reagents
    1, -- parts
    4, -- jewelcrafting
    7, -- metal and stone
    6, -- leather
    5, -- cloth
    12, -- enchanting
    16, -- inscription
    10, -- elemental
    9, -- herb
    8, -- cooking
    11, -- other
    0, -- trade goods (obsolete)
    2, -- explosives (obsolete)
    3, -- devices (obsolete)
    13, -- materials (obsolete)
    14, -- item enchantment (obsolete)
    15, -- weapon enchantment (obsolete)
    17, -- explosives and devices (obsolete)
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

local petCageID = addonTable.Constants.BattlePetCageID

keysMapping["expansion"] = function(self)
  return Syndicator.Search.GetExpansion(self) or nil
end

keysMapping["invertedExpansion"] = function(self)
  return self.expansion and -self.expansion
end

keysMapping["itemLevelRaw"] = function(self)
  if C_Item.IsItemDataCachedByID(self.itemID) then
    local itemLevel = C_Item.GetDetailedItemLevelInfo(self.itemLink)
    return itemLevel or -1
  else
    C_Item.RequestLoadItemDataByID(self.itemID)
  end
end

keysMapping["invertedItemLevelRaw"] = function(self)
  return self.itemLevelRaw and -self.itemLevelRaw
end

keysMapping["invertedItemLevelEquipment"] = function(self)
  if Syndicator.Utilities.IsEquipment(self.itemLink) then
    return self.itemLevelRaw and -self.itemLevelRaw
  else
    return 0
  end
end

-- Dragonflight crafting reagent quality
if C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
  keysMapping["craftingQuality"] = function(self)
    return C_TradeSkillUI.GetItemReagentQualityByItemInfo(self.itemID) or -1
  end

  keysMapping["invertedCraftingQuality"] = function(self)
    return self.craftingQuality and -self.craftingQuality
  end
else
  keysMapping["craftingQuality"] = function(self)
    return -1
  end

  keysMapping["invertedCraftingQuality"] = function(self)
    return -self.craftingQuality
  end
end

keysMapping["itemName"] = function(self)
  if C_Item.IsItemDataCachedByID(self.itemID) then
    return C_Item.GetItemNameByID(self.itemID) or ""
  else
    C_Item.RequestLoadItemDataByID(self.itemID)
  end
end

keysMapping["invertedQuality"] = function(self)
  return -self.quality
end

keysMapping["invertedItemID"] = function(self)
  return -self.itemID
end

keysMapping["invertedItemCount"] = function(self)
  return -self.itemCount
end

keysMapping["sortedClassID"] = function(self)
  return sortedMap.classID[self.classID] or (self.classID + 200)
end

keysMapping["sortedSubClassID"] = function(self)
  -- Reorder some subclass items so that the order makes more sense
  if self.classID == Enum.ItemClass.Weapon then
    return sortedMap.weaponSubClassID[self.subClassID] or (self.subClassID + 200)
  elseif self.classID == Enum.ItemClass.Armor then
    return sortedMap.armorSubClassID[self.subClassID] or (self.subClassID + 200)
  elseif self.classID == Enum.ItemClass.Tradegoods then
    return sortedMap.tradegoodSubClassID[self.subClassID] or (self.subClassID + 200)
  else
    return self.subClassID
  end
end

keysMapping["sortedInvSlotID"] = function(self)
  return sortedMap.invSlotID[self.invSlotID] or (self.invSlotID + 200)
end
