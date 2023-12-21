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

local function SetCheck(details)
  return details.setInfo ~= nil
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
  if not details.itemLink or not details.itemLink:find("item:", nil, true) then
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
  [BAGANATOR_L_KEYWORD_SET] = SetCheck,
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
  ["tbc"] = 1,
  ["wrath"] = 2,
  ["wotlk"] = 2,
  ["cataclysm"] = 3,
  ["mop"] = 4,
  ["mists of pandaria"] = 4,
  ["wod"] = 5,
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
    KEYWORDS_TO_CHECK[key] = function(details) return details.expacID == expansionID end
    KEYWORDS_TO_CHECK["-" .. key] = function(details) return details.expacID ~= expansionID end
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

  local allKeywords = {}
  while startIndex <= #sortedKeywords and sortedKeywords[startIndex]:sub(1, #text) == text do
    table.insert(allKeywords, sortedKeywords[startIndex])
    startIndex = startIndex + 1
  end
  return allKeywords
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

-- Previously found search terms checks by keyword or pattern
local matches = {}
-- Search terms with no keyword or pattern match
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
      local keywords = BinarySmartSearch(searchString)
      if #keywords > 0 then
        -- Work through each keyword that matches the search string and check if
        -- the details match the keyword's criteria
        local check = function(details)
          -- Cache results for each keyword to speed up continuing searches
          if not details.matchInfo then
            details.matchInfo = {}
          end
          local miss = false
          for _, k in ipairs(keywords) do
            if details.matchInfo[k] == nil then
              -- Keyword results not cached yet
              local result = KEYWORDS_TO_CHECK[k](details)
              if result then
                details.matchInfo[k] = true
                return true
              elseif result ~= nil then
                details.matchInfo[k] = false
              else
                miss = true
              end
            elseif details.matchInfo[k] then
              -- got a positive result cached, we're done
              return true
            end
          end
          if miss then
            return nil
          else
            return false
          end
        end
        matches[searchString] = check
        return check(details, searchString)
      end

      -- See if a pattern matches, e.g. item level range
      local patternChecker = PatternSearch(searchString)
      if patternChecker then
        matches[searchString] = patternChecker
        return patternChecker(details, searchString)
      end

      -- Couldn't find anything that matched
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

  local tradeGoodsToCheck = {
    5, -- cloth
    6, -- leather
    7, -- metal and stone
    8, -- cooking
    9, -- herb
    10, -- elemental
  }
  for _, subClass in ipairs(tradeGoodsToCheck) do
    local keyword = GetItemSubClassInfo(7, subClass)
    if keyword ~= nil then
      KEYWORDS_TO_CHECK[keyword:lower()] = function(details)
        return details.classID == 7 and details.subClassID == subClass
      end
    end
  end

  for key in pairs(KEYWORDS_TO_CHECK) do
    table.insert(sortedKeywords, key)
  end
  table.sort(sortedKeywords)
end
