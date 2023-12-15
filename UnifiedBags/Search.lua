Baganator.UnifiedBags.Search = {}

local function PetCheck(details)
  return details.classID == Enum.ItemClass.Battlepet or (details.classID == Enum.ItemClass.Miscellaneous and details.subClassID == Enum.ItemMiscellaneousSubclass.CompanionPet)
end

local function ReagentCheck(details)
  return details.isCraftingReagent
end

local function BindCheck(details)
  return details.isBound
end

local function BindOnEquipCheck(details)
  return not details.isBound and details.itemLink and Baganator.Utilities.IsEquipment(details.itemLink)
end

local function EquipmentCheck(details)
  return details.itemLink and Baganator.Utilities.IsEquipment(details.itemLink)
end

local function FoodCheck(details)
  return details.classID == Enum.ItemClass.Consumable and details.subClassID == 5
end

local function PotionCheck(details)
  return details.classID == Enum.ItemClass.Consumable and (details.subClassID == 1 or details.subClassID == 2)
end

local function GetTooltipInfo(details)
  if details.tooltipInfo then
    return
  end

  local _, spellID = GetItemSpell(details.itemID)
  if spellID and not C_Spell.IsSpellDataCached(spellID) then
    C_Spell.RequestLoadSpellData(spellID)
    return
  end
  details.tooltipInfo = C_TooltipInfo.GetHyperlink(details.itemLink)
end

local function ReputationCheck(details)
  if not details.itemLink then
    return false
  end

  GetTooltipInfo(details)

  if details.tooltipInfo then
    for _, lineData in ipairs(details.tooltipInfo.lines) do
      if lineData.leftText:match(BAGANATOR_L_KEYWORD_REPUTATION) then
        return true
      end
    end
    return false
  else
    return nil
  end
end

local KEYWORDS_TO_CHECK = {
  [BAGANATOR_L_KEYWORD_PET] = PetCheck,
  [BAGANATOR_L_KEYWORD_BATTLE_PET] = PetCheck,
  [BAGANATOR_L_KEYWORD_SOULBOUND] = BindCheck,
  [BAGANATOR_L_KEYWORD_BOE] = BindOnEquipCheck,
  [BAGANATOR_L_KEYWORD_EQUIPMENT] = EquipmentCheck,
  [BAGANATOR_L_KEYWORD_GEAR] = EquipmentCheck,
  [BAGANATOR_L_KEYWORD_REAGENT] = ReagentCheck,
  [BAGANATOR_L_KEYWORD_FOOD] = FoodCheck,
  [BAGANATOR_L_KEYWORD_DRINK] = FoodCheck,
  [BAGANATOR_L_KEYWORD_POTION] = PotionCheck,
}

if Baganator.Constants.IsRetail then
  KEYWORDS_TO_CHECK[BAGANATOR_L_KEYWORD_REPUTATION] = ReputationCheck
end

local inventorySlots = {
  "INVTYPE_HEAD",
  "INVTYPE_NECK",
  "INVTYPE_SHOULDER",
  "INVTYPE_BODY",
  "INVTYPE_CHEST",
  "INVTYPE_WAIST",
  "INVTYPE_LEGS",
  "INVTYPE_FEET",
  "INVTYPE_WRIST",
  "INVTYPE_HAND",
  "INVTYPE_FINGER",
  "INVTYPE_TRINKET",
  "INVTYPE_WEAPON",
  "INVTYPE_SHIELD",
  "INVTYPE_RANGED",
  "INVTYPE_CLOAK",
  "INVTYPE_2HWEAPON",
  "INVTYPE_BAG",
  "INVTYPE_TABARD",
  "INVTYPE_ROBE",
  "INVTYPE_WEAPONMAINHAND",
  "INVTYPE_WEAPONOFFHAND",
  "INVTYPE_HOLDABLE",
  "INVTYPE_AMMO",
  "INVTYPE_THROWN",
  "INVTYPE_RANGEDRIGHT",
  "INVTYPE_QUIVER",
  "INVTYPE_RELIC",
  "INVTYPE_PROFESSION_TOOL",
  "INVTYPE_PROFESSION_GEAR",
}
for _, slot in ipairs(inventorySlots) do
  local text = _G[slot]
  if text ~= nil then
    KEYWORDS_TO_CHECK[text:lower()] = function(details) return details.invType == slot end
  end
end

local TextToExpansion = {
  ["classic"] = 0,
  ["vanilla"] = 0,
  ["bc"] = 1,
  ["burning crusade"] = 1,
  ["wrath"] = 2,
  ["wotlk"] = 2,
  ["cataclysm"] = 3,
  ["mop"] = 4,
  ["mists of pandaria"] = 4,
  ["draenor"] = 5,
  ["legion"] = 6,
  ["bfa"] = 7,
  ["battle for azeroth"] = 7,
  ["sl"] = 8,
  ["shadowlands"] = 8,
  ["df"] = 9,
  ["dragonflight"] = 9,
}

if Baganator.Constants.IsRetail then
  for key, expansionID in pairs(TextToExpansion) do
    KEYWORDS_TO_CHECK["xpac:" .. key] = function(details) return details.expacID == expansionID end
    KEYWORDS_TO_CHECK["-xpac:" .. key] = function(details) return details.expacID ~= expansionID end
  end
end

-- Sorted in initialize function later
local sortedKeywords = {}

local function BinarySmartSearch(text)
  local startIndex, endIndex = 1, #sortedKeywords
  local middle
  while startIndex < endIndex do
    local middleIndex = math.floor((endIndex + startIndex)/2)
    middle = sortedKeywords[middleIndex]
    if middle < text then
      startIndex = middleIndex + 1
    else
      endIndex = middleIndex
    end
  end
  return sortedKeywords[startIndex]
end

local function ItemLevelPatternCheck(details, text)
  if not details.itemLink or not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local wantedItemLevel = tonumber(text)
  return details.itemLevel and details.itemLevel == wantedItemLevel
end

local function ItemLevelRangePatternCheck(details, text)
  if not details.itemLink or not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local minText, maxText = text:match("(%d+)%-(%d+)")
  return details.itemLevel and details.itemLevel >= tonumber(minText) and details.itemLevel <= tonumber(maxText)
end

local function ItemLevelMinPatternCheck(details, text)
  if not details.itemLink or not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local minText = text:match("%d+")
  return details.itemLevel and details.itemLevel <= tonumber(minText)
end

local function ItemLevelMaxPatternCheck(details, text)
  if not details.itemLink or not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local maxText = text:match("%d+")
  return details.itemLevel and details.itemLevel >= tonumber(maxText)
end

local patterns = {
  ["^%d+$"] = ItemLevelPatternCheck,
  ["^%d+%-%d+$"] = ItemLevelRangePatternCheck,
  ["^%>%d+$"] = ItemLevelMaxPatternCheck,
  ["^%<%d+$"] = ItemLevelMinPatternCheck,
}

local function PatternSearch(searchString)
  for pat, check in pairs(patterns) do
    if searchString:match(pat) then
      return check
    end
  end
end

local matches = {}
local rejects = {}

function Baganator.UnifiedBags.Search.CheckItem(details, searchString)
  local itemLink = details.itemLink
  local itemName = details.itemNameLower

  if itemName:find(searchString, nil, true) ~= nil then
    return true
  else
    local check = matches[searchString]
    if check then
      return check(details, searchString)
    elseif not rejects[searchString] then
      local keyword = BinarySmartSearch(searchString)
      if keyword then
        local matchesStart = keyword:sub(1, #searchString) == searchString
        if matchesStart then
          local check = KEYWORDS_TO_CHECK[keyword]
          matches[searchString] = check
          return check(details, searchString)
        end
      end

      local patternChecker = PatternSearch(searchString)
      if patternChecker then
        matches[searchString] = patternChecker
        return patternChecker(details, searchString)
      end

      rejects[searchString] = true
    end
  end
  return false
end

function Baganator.UnifiedBags.Search.ClearCache()
  matches = {}
  rejects = {}
end

function Baganator.UnifiedBags.Search.Initialize()
  for i = 0, Enum.ItemClassMeta.NumValues-1 do
    local name = GetItemClassInfo(i)
    if name then
      if not KEYWORDS_TO_CHECK[name:lower()] then
        local classID = i
        KEYWORDS_TO_CHECK[name:lower()] = function(details)
          return details.classID == classID
        end
      end
    end
  end

  for key in pairs(KEYWORDS_TO_CHECK) do
    table.insert(sortedKeywords, key)
  end
  table.sort(sortedKeywords)
end
