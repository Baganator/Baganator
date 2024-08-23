local _, addonTable = ...

if not Syndicator then
  return
end

local inventorySlots = {
  "INVTYPE_2HWEAPON", _G["INVTYPE_2HWEAPON"],
  "INVTYPE_WEAPON", _G["INVTYPE_WEAPON"],
  "INVTYPE_WEAPONMAINHAND", _G["INVTYPE_WEAPONMAINHAND"],
  "INVTYPE_WEAPONOFFHAND", _G["INVTYPE_WEAPONOFFHAND"],
  "INVTYPE_SHIELD", _G["INVTYPE_SHIELD"],
  "INVTYPE_HOLDABLE", _G["INVTYPE_SHIELD"],
  "INVTYPE_RANGED", _G["INVTYPE_RANGED"],
  "INVTYPE_RANGEDRIGHT", _G["INVTYPE_RANGEDRIGHT"],
  "INVTYPE_THROWN", _G["INVTYPE_THROWN"],
  "INVTYPE_AMMO", _G["INVTYPE_AMMO"],
  "INVTYPE_QUIVER", _G["INVTYPE_QUIVER"],
  "INVTYPE_RELIC", _G["INVTYPE_RELIC"],
  "INVTYPE_HEAD", _G["INVTYPE_HEAD"],
  "INVTYPE_SHOULDER", _G["INVTYPE_SHOULDER"],
  "INVTYPE_CLOAK", _G["INVTYPE_CLOAK"],
  "INVTYPE_CHEST", _G["INVTYPE_CHEST"],
  "INVTYPE_ROBE", _G["INVTYPE_ROBE"],
  "INVTYPE_WRIST", _G["INVTYPE_WRIST"],
  "INVTYPE_HAND", _G["INVTYPE_HAND"],
  "INVTYPE_WAIST", _G["INVTYPE_WAIST"],
  "INVTYPE_LEGS", _G["INVTYPE_LEGS"],
  "INVTYPE_FEET", _G["INVTYPE_FEET"],
  "INVTYPE_NECK", _G["INVTYPE_NECK"],
  "INVTYPE_FINGER", _G["INVTYPE_FINGER"],
  "INVTYPE_TRINKET", _G["INVTYPE_TRINKET"],
  "INVTYPE_BODY", _G["INVTYPE_BODY"],
  "INVTYPE_TABARD", _G["INVTYPE_TABARD"],
  "INVTYPE_PROFESSION_TOOL", _G["INVTYPE_PROFESSION_TOOL"],
  "INVTYPE_PROFESSION_GEAR", _G["INVTYPE_PROFESSION_GEAR"],
  "INVTYPE_BAG", _G["INVTYPE_BAG"],
}

local groupings = {}
local groupingsToLabels = {}
local groupingGetters = {}
do
  groupings["expansion"] = {
    "The War Within",
    "Dragonflight",
    "Shadowlands",
    "Battle for Azeroth",
    "Legion",
    "Warlords of Draenor",
    "Mists of Pandaria",
    "Cataclysm",
    "Wrath of the Lich King",
    "The Burning Crusade",
    "Classic",
  }
  groupingsToLabels["expansion"] = {}
  for index, label in ipairs(groupings["expansion"]) do
    groupingsToLabels["expansion"][11 - index] = label
  end
  groupingGetters["expansion"] = function(item)
    if item.expansion then
      return true
    end
    item.expansion = item.expacID or Syndicator.Search.GetExpansion(item) or nil
    return item.expansion ~= nil
  end

  groupings["type"] = {}

  local subTypes = {
    -- Weapon
    2, 0, -- One-Handed Axes
    2, 4, -- One-Handed Maces
    2, 7, -- One-Handed Swords
    2, 9, -- Warglaives
    2, 15, -- Daggers
    2, 13, -- Fist Weapons
    2, 11, -- bear claws
    2, 12, -- cat claws
    2, 19, -- Wands
    2, 1, -- Two-Handed Axes
    2, 5, -- Two-Handed Maces
    2, 8, -- Two-Handed Swords
    2, 6, -- Polearms
    2, 10, -- Staves
    2, 2, -- Bows
    2, 18, -- Crossbows
    2, 3, -- Guns
    2, 16, -- Thrown
    2, 20, -- Fishing Poles

    -- Armor
    4, 1, -- Cloth
    4, 2, -- Leather
    4, 3, -- Mail
    4, 4, -- Plate
    4, 6, -- Shield
    4, 7, -- Libram
    4, 8, -- Idol
    4, 9, -- Totem
    4, 10, -- Sigil
    4, 11, -- Relic
    4, 5, -- Cosmetic
    4, 0, -- Generic

    -- Tradeskill
    7, 18, -- Optional Reagents
    7, 1, -- Parts
    7, 4, -- Jewelcrafting
    7, 7, -- Metal & Stone
    7, 6, -- Leather
    7, 5, -- Cloth
    7, 12, -- Enchanting
    7, 16, -- Inscription
    7, 10, -- Elemental
    7, 9, -- Herb
    7, 8, -- Cooking
    7, 11, -- Other

     -- Profession
    16, 7, -- Engineering
    16, 0, -- Blacksmithing
    16, 1, -- Leatherworking
    16, 6, -- Tailoring
    16, 8, -- Enchanting
    16, 11, -- Jewelcrafting
    16, 2, -- Alchemy
    16, 12, -- Inscription
    16, 5, -- Mining
    16, 10, -- Skinning
    16, 3, -- Herbalism
    16, 4, -- Cooking
    16, 9, -- Fishing
    16, 13, -- Archaeology

    -- Recipe
    9, 3, -- Engineering
    9, 4, -- Blacksmithing
    9, 1, -- Leatherworking
    9, 2, -- Tailoring
    9, 8, -- Enchanting
    9, 10, -- Jewelcrafting
    9, 6, -- Alchemy
    9, 11, -- Inscription
    9, 5, -- Cooking
    9, 8, -- Fishing
    9, 7, -- First Aid
    9, 0, -- Book

    -- Battle Pets
    17, 0, -- Humanoid
    17, 1, -- Dragonkin
    17, 2, -- Flying
    17, 3, -- Undead
    17, 4, -- Critter
    17, 5, -- Magic
    17, 6, -- Elemental
    17, 7, -- Beast
    17, 8, -- Aquatic
    17, 9, -- Mechanical
  }
  groupingsToLabels["type"] = {}
  for i = 1, #subTypes, 2 do
    local root = subTypes[i]
    local child = subTypes[i+1]
    local childLabel = C_Item.GetItemSubClassInfo(subTypes[i], subTypes[i+1])
    table.insert(groupings["type"], childLabel)
    groupingsToLabels["type"][root .. "_" ..  child] = childLabel
  end

  groupingGetters["type"] = function(item)
    if item.type then
      return true
    end

    if not item.classID then
      if item.itemID == Syndicator.Constants.BattlePetCageID then
        local petID = item.itemLink:match("battlepet:(%d+)")
        local itemName, _, petType = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
        item.classID = Enum.ItemClass.Battlepet
        item.subClassID = petType - 1
      else
        local classID, subClassID = select(6, C_Item.GetItemInfoInstant(item.itemID))
        item.classID = classID
        item.subClassID = subClassID
      end
    end
    item.type = item.classID .. "_" .. item.subClassID
    return true
  end

  local qualities = {}
  groupingsToLabels["quality"] = {}
  for quality = 10, 1, -1 do
    local term = _G["ITEM_QUALITY" .. quality .. "_DESC"]
    if term then
      table.insert(qualities, term)
      groupingsToLabels["quality"][quality] = term
    end
  end
  groupings["quality"] = qualities
  groupingGetters["quality"] = function(item)
    return true
  end

  local inventorySlotsForGroupings = {}
  groupingsToLabels["slot"] = {}
  for i = 1, #inventorySlots, 2 do
    local slot = inventorySlots[i]
    local name = inventorySlots[i+1]
    if name then
      table.insert(inventorySlotsForGroupings, name)
      groupingsToLabels["slot"][slot] = name
    end
  end
  groupings["slot"] = inventorySlotsForGroupings
  groupingGetters["slot"] = function(item)
    if item.slot then
      return true
    end
    item.slot = (select(4, C_Item.GetItemInfoInstant(item.itemID))) or "NONE"
    return true
  end
end

BaganatorCategoryViewsCategoryGroupingMixin = {}

function BaganatorCategoryViewsCategoryGroupingMixin:ApplyGroupings(composed, callback)
  self.start = debugprofilestop()
  self.callback = callback
  self.composed = composed
  self.pending = {}
  for index, details in ipairs(composed.details) do
    if details.group then
      self.pending[index] = {grouping = details.group, items = details.results, details = details}
    end
  end

  self:GroupingResults()
end

function BaganatorCategoryViewsCategoryGroupingMixin:GroupingResults()
  for index, details in pairs(self.pending) do
    local complete = true
    for _, item in ipairs(details.items) do
      complete = complete and groupingGetters[details.grouping](item)
    end
    if complete then
      self.pending[index] = nil
      local insertPoint = tIndexOf(self.composed.details, details.details)
      local nonResults = {}
      local groups = {}
      self.composed.details[insertPoint].results = nonResults
      for _, label in ipairs(groupings[details.grouping]) do
        insertPoint = insertPoint + 1
        table.insert(self.composed.details, insertPoint, {
          type = "category",
          label = details.details.label .. ": " .. label,
          section = details.details.section,
          source = details.details.source,
          groupLabel = label,
          auto = true,
          results = {}
        })
        groups[label] = self.composed.details[insertPoint].results
      end
      local map = groupingsToLabels[details.grouping]
      local key = details.grouping
      for _, item in ipairs(details.items) do
        local location = map[item[key]]
        if groups[location] then
          table.insert(groups[location], item)
        else
          table.insert(nonResults, item)
        end
      end
    end
  end

  if next(self.pending) == nil then
    self:SetScript("OnUpdate", nil)
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("grouping took", debugprofilestop() - self.start)
    end
    self.callback()
  else
    self:SetScript("OnUpdate", self.GroupingResults)
  end
end
