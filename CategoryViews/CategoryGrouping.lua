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
    -- Consumables (0)
    0, 0, -- Explosives and Devices
    0, 1, -- Potions
    0, 2, -- Elxirs
    0, 3, -- Flasks & Phials
    0, 4, -- Scrolls (Obsolete)
    0, 5, -- Food & Drink
    0, 6, -- Item Enhancements (Obsolete)
    0, 7, -- Bandage
    0, 9, -- Vantus Runes
    0, 11, -- Combat Curio
    0, 10, -- Utility Curio
    0, 8, -- Other

    -- Key (13)
    13, 0, -- Key
    13, 1, -- Lockpick

    -- Quest (12)
    12, 0, -- Quest

    -- Containers (1)
    1, 0, -- Bag
    1, 11, -- Reagent Bag
    1, 1, -- Soul Bag	Classic
    1, 4, -- Engineering Bag
    1, 6, -- Mining Bag
    1, 7, -- Leatherworking Bag
    1, 3, -- Enchanting Bag
    1, 5, -- Gem Bag
    1, 2, -- Herb Bag
    1, 8, -- Inscription Bag
    1, 10, -- Cooking Bag
    1, 9, -- Tackle Box

    -- Weapon (2)
    2, 0, -- One-Handed Axes
    2, 4, -- One-Handed Maces
    2, 7, -- One-Handed Swords
    2, 9, -- Warglaives
    2, 15, -- Daggers
    2, 13, -- Fist Weapons
    2, 11, -- Bear Claws
    2, 12, -- Cat Claws
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

    -- Armor (4)
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

    -- Quiver (11)
    11, 0, -- Quiver (Obsolete)
    11, 1, -- Bolt (Obsolete)
    11, 2, -- Quiver
    11, 3, -- Ammo Pounch

    -- Projectile (6)
    6, 0, -- Wand (Obsolete)
    6, 1, -- Bolt (Obsolete)
    6, 2, -- Arrow (Obsolete)
    6, 3, -- Bullet (Obsolete)
    6, 4, -- Thrown (Obsolete)

    -- Gems (3)
    3, 11, -- Artifact Relic
    3, 0, -- Intellect
    3, 1, -- Agility
    3, 2, -- Strength
    3, 3, -- Stamina
    3, 4, -- Spirit
    3, 5, -- Critical Strike
    3, 6, -- Mastery
    3, 7, -- Haste
    3, 8, -- Versatility
    3, 9, -- Other
    3, 10, -- Multiple Stats

    -- Permanent (14)
    14, 0, -- Permanent (Obsolete)

    -- Item Enhancement (8)
    8, 0, -- Head
    8, 1, -- Neck
    8, 2, -- Shoulder
    8, 3, -- Cloak
    8, 4, -- Chest
    8, 5, -- Wrist
    8, 6, -- Hands
    8, 7, -- Waist
    8, 8, -- Legs
    8, 9, -- Feet
    8, 10, -- Finger
    8, 11, -- Weapon
    8, 12, -- Two-Handed Weapon
    8, 13, -- Shield/Off-hand
    8, 14, -- Misc

    -- Tradeskill (7)
    7, 19, -- Finishing Reagents
    7, 18, -- Optional Reagents
    7, 17, -- Explosives and Devices (Obsolete)
    7, 2, -- Explosives (Obsolete)
    7, 3, -- Devices (Obsolete)
    7, 13, -- Materials (Obsolete)
    7, 1, -- Parts
    7, 7, -- Metal & Stone
    7, 6, -- Leather
    7, 5, -- Cloth
    7, 12, -- Enchanting
    7, 10, -- Elemental
    7, 4, -- Jewelcrafting
    7, 16, -- Inscription
    7, 9, -- Herb
    7, 8, -- Cooking
    7, 14, -- Item Enhancement (Obsolete)
    7, 15, -- Weapon Enhancement (Obsolete)
    7, 0, -- Trade Goods (Obsolete)
    7, 11, -- Other

    -- Recipe (9)
    9, 3, -- Engineering
    9, 4, -- Blacksmithing
    9, 1, -- Leatherworking
    9, 2, -- Tailoring
    9, 8, -- Enchanting
    9, 10, -- Jewelcrafting
    9, 6, -- Alchemy
    9, 11, -- Inscription
    9, 5, -- Cooking
    9, 9, -- Fishing
    9, 7, -- First Aid
    9, 0, -- Book

    -- Profession (19)
    19, 7, -- Engineering
    19, 0, -- Blacksmithing
    19, 1, -- Leatherworking
    19, 6, -- Tailoring
    19, 8, -- Enchanting
    19, 11, -- Jewelcrafting
    19, 2, -- Alchemy
    19, 12, -- Inscription
    19, 5, -- Mining
    19, 10, -- Skinning
    19, 3, -- Herbalism
    19, 4, -- Cooking
    19, 9, -- Fishing
    19, 13, -- Archaeology

    -- Reagents (5)
    5, 0, -- Reagent
    5, 1, -- Keystone
    5, 2, -- Context Token

    -- Glyph (16)
    16, 1, -- Warrior
    16, 2, -- Paladin
    16, 3, -- Hunter
    16, 4, -- Rogue
    16, 5, -- Priest
    16, 6, -- Death Knight
    16, 7, -- Shaman
    16, 8, -- Mage
    16, 9, -- Warlock
    16, 10, -- Monk
    16, 11, -- Druid
    16, 12, -- Demon Hunter

    -- Money (10) Obsolete
    10, 0, -- Money (Obsolete)

    -- Battle Pets (17)
    17, 0, -- Humanoid
    17, 1, -- Dragonkin
    17, 2, -- Flying
    17, 3, -- Undead
    17, 4, -- Critter
    17, 5, -- Magical
    17, 6, -- Elemental
    17, 7, -- Beast
    17, 8, -- Aquatic
    17, 9, -- Mechanical

    -- Miscellaneous (15)
    15, 5, -- Mount
    15, 6, -- Mount Equipment
    15, 2, -- Companion Pets
    15, 3, -- Holiday
    15, 1, -- Reagent
    15, 0, -- Junk
    15, 4, -- Other

    -- WoW Token (18)
    18, 0, -- WoW Token
  }
  groupingsToLabels["type"] = {}
  for i = 1, #subTypes, 2 do
    local root = subTypes[i]
    local child = subTypes[i+1]
    local childLabel = C_Item.GetItemSubClassInfo(subTypes[i], subTypes[i+1])
    if childLabel then
      table.insert(groupings["type"], childLabel)
      groupingsToLabels["type"][root .. "_" ..  child] = childLabel
    end
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

function BaganatorCategoryViewsCategoryGroupingMixin:Cancel()
  self:SetScript("OnUpdate", nil)
end

function BaganatorCategoryViewsCategoryGroupingMixin:OnHide()
  self:Cancel()
end

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
        local prefix = ""
        if details.details.groupPrefix ~= false then
          prefix = details.details.label .. ": "
        end
        insertPoint = insertPoint + 1
        table.insert(self.composed.details, insertPoint, {
          type = "category",
          label = prefix .. label,
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
