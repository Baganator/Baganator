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
  return not details.isBound and Baganator.Utilities.IsEquipment(details.itemLink) == true
end

local function EquipmentCheck(details)
  return details.classID == Enum.ItemClass.Armor or details.classID == Enum.ItemClass.Weapon
end

local function FoodCheck(details)
  return details.classID == Enum.ItemClass.Consumable and details.subClassID == 5
end

local function PotionCheck(details)
  return details.classID == Enum.ItemClass.Consumable and (details.subClassID == 1 or details.subClassID == 2)
end

local function JunkCheck(details)
  return details.isJunk
end

local function CosmeticCheck(details)
  return details.isCosmetic
end

local function GetQualityCheck(quality)
  return function(details)
    return details.quality == quality
  end
end

local function AxeCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Axe2H or details.subClassID == Enum.ItemWeaponSubclass.Axe1H)
end

local function MaceCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Mace2H or details.subClassID == Enum.ItemWeaponSubclass.Mace1H)
end

local function SwordCheck(details)
  return details.classID == Enum.ItemClass.Weapon and (details.subClassID == Enum.ItemWeaponSubclass.Sword2H or details.subClassID == Enum.ItemWeaponSubclass.Sword1H)
end

local function GetTooltipInfoSpell(details)
  if details.tooltipInfoSpell then
    return
  end

  local _, spellID = GetItemSpell(details.itemID)
  if spellID and not C_Spell.IsSpellDataCached(spellID) then
    C_Spell.RequestLoadSpellData(spellID)
    return
  end
  details.tooltipInfoSpell = details.tooltipGetter()
end

local function ReputationCheck(details)
  if not details.itemLink:find("item:", nil, true) then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, lineData in ipairs(details.tooltipInfoSpell.lines) do
      if lineData.leftText:match(BAGANATOR_L_KEYWORD_REPUTATION) then
        return true
      end
    end
    return false
  else
    return nil
  end
end

local function BindOnAccountCheck(details)
  if not details.isBound or not details.itemLink:find("item:", nil, true) then
    return false
  end

  GetTooltipInfoSpell(details)

  if details.tooltipInfoSpell then
    for _, row in ipairs(details.tooltipInfoSpell.lines) do
      if tIndexOf(Baganator.Constants.AccountBoundTooltipLines, row.leftText) ~= nil then
        return true
      end
    end
    return false
  end
end

local function SaveBaseStats(details)
  if not Baganator.Utilities.IsEquipment(details.itemLink) then
    details.baseItemStats = {}
    return
  end

  local cleanedLink = details.itemLink:gsub("item:(%d+):(%d*):(%d*):(%d*):(%d*):", "item:%1:::::")
  details.baseItemStats = GetItemStats(cleanedLink)
end

local function SocketCheck(details)
  SaveBaseStats(details)
  if not details.baseItemStats then
    return nil
  end
  for key in pairs(details.baseItemStats) do
    if key:find("EMPTY_SOCKET", nil, true) then
      return true
    end
  end
  return false
end

local KEYWORDS_TO_CHECK = {
  [BAGANATOR_L_KEYWORD_PET] = PetCheck,
  [BAGANATOR_L_KEYWORD_BATTLE_PET] = PetCheck,
  [BAGANATOR_L_KEYWORD_SOULBOUND] = BindCheck,
  [BAGANATOR_L_KEYWORD_BOE] = BindOnEquipCheck,
  [BAGANATOR_L_KEYWORD_EQUIPMENT] = EquipmentCheck,
  [BAGANATOR_L_KEYWORD_GEAR] = EquipmentCheck,
  [BAGANATOR_L_KEYWORD_AXE] = AxeCheck,
  [BAGANATOR_L_KEYWORD_MACE] = MaceCheck,
  [BAGANATOR_L_KEYWORD_SWORD] = SwordCheck,
  [BAGANATOR_L_KEYWORD_REAGENT] = ReagentCheck,
  [BAGANATOR_L_KEYWORD_FOOD] = FoodCheck,
  [BAGANATOR_L_KEYWORD_DRINK] = FoodCheck,
  [BAGANATOR_L_KEYWORD_POTION] = PotionCheck,
  [BAGANATOR_L_KEYWORD_SET] = SetCheck,
  [BAGANATOR_L_KEYWORD_SOCKET] = SocketCheck,
  [BAGANATOR_L_KEYWORD_JUNK] = JunkCheck,
  [BAGANATOR_L_KEYWORD_TRASH] = JunkCheck,
  [BAGANATOR_L_KEYWORD_REPUTATION] = ReputationCheck,
  [BAGANATOR_L_KEYWORD_BOA] = BindOnAccountCheck,
}

if Baganator.Constants.IsRetail then
  KEYWORDS_TO_CHECK[BAGANATOR_L_KEYWORD_COSMETIC] = CosmeticCheck
end

local sockets = {
  "EMPTY_SOCKET_BLUE",
  "EMPTY_SOCKET_COGWHEEL",
  "EMPTY_SOCKET_CYPHER",
  "EMPTY_SOCKET_DOMINATION",
  "EMPTY_SOCKET_HYDRAULIC",
  "EMPTY_SOCKET_META",
  "EMPTY_SOCKET_NO_COLOR",
  "EMPTY_SOCKET_PRIMORDIAL",
  "EMPTY_SOCKET_PRISMATIC",
  "EMPTY_SOCKET_PUNCHCARDBLUE",
  "EMPTY_SOCKET_PUNCHCARDRED",
  "EMPTY_SOCKET_PUNCHCARDYELLOW",
  "EMPTY_SOCKET_RED",
  "EMPTY_SOCKET_TINKER",
  "EMPTY_SOCKET_YELLOW",
}

for _, key in ipairs(sockets) do
  local global = _G[key]
  if global then
    KEYWORDS_TO_CHECK[global:lower()] = function(details)
      SaveBaseStats(details)
      if details.baseItemStats then
        return details.baseItemStats[key] ~= nil
      end
      return nil
    end
  end
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

for key, quality in pairs(Enum.ItemQuality) do
  local term = _G["ITEM_QUALITY" .. quality .. "_DESC"]
  if term then
    KEYWORDS_TO_CHECK[term:lower()] = function(details) return details.quality == quality end
  end
end

if Baganator.Constants.IsRetail then
  for key, expansionID in pairs(TextToExpansion) do
    KEYWORDS_TO_CHECK[key] = function(details) return details.expacID == expansionID end
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
  if not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local wantedItemLevel = tonumber(text)
  return details.itemLevel and details.itemLevel == wantedItemLevel
end

local function ItemLevelRangePatternCheck(details, text)
  if not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local minText, maxText = text:match("(%d+)%-(%d+)")
  return details.itemLevel and details.itemLevel >= tonumber(minText) and details.itemLevel <= tonumber(maxText)
end

local function ItemLevelMinPatternCheck(details, text)
  if not Baganator.Utilities.IsEquipment(details.itemLink) then
    return false
  end
  details.itemLevel = details.itemLevel or GetDetailedItemLevelInfo(details.itemLink)

  local minText = text:match("%d+")
  return details.itemLevel and details.itemLevel <= tonumber(minText)
end

local function ItemLevelMaxPatternCheck(details, text)
  if not Baganator.Utilities.IsEquipment(details.itemLink) then
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

local function MatchesText(details, searchString)
  return details.itemNameLower:find(searchString, nil, true) ~= nil
end

local function PatternSearch(searchString)
  for pat, check in pairs(patterns) do
    if searchString:match(pat) then
      return function(...)
        return MatchesText(...) or check(...)
      end
    end
  end
end

-- Previously found search terms checks by keyword or pattern
local matches = {}
-- Search terms with no keyword or pattern match
local rejects = {}

-- Each keyword/pattern check function returns nil if the data needed to
-- complete the check doesn't exist yet. Then the item will be queued for
-- checking again on a later frame. If the data is available either true or
-- false is returned.
local function ApplyKeyword(searchString)
  local check = matches[searchString]
  if check then
    return check
  elseif not rejects[searchString] then
    local keywords = BinarySmartSearch(searchString)
    if #keywords > 0 then
      -- Work through each keyword that matches the search string and check if
      -- the details match the keyword's criteria
      local check = function(details)
        if MatchesText(details, searchString) then
          return true
        end
        -- Cache results for each keyword to speed up continuing searches
        if not details.matchInfo then
          details.matchInfo = {}
        end
        local miss = false
        for _, k in ipairs(keywords) do
          if details.matchInfo[k] == nil then
            -- Keyword results not cached yet
            local result = KEYWORDS_TO_CHECK[k](details, searchString)
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
      return check
    end

    -- See if a pattern matches, e.g. item level range
    local patternChecker = PatternSearch(searchString)
    if patternChecker then
      matches[searchString] = patternChecker
      return function(details)
        return MatchesText(details, searchString) or patternChecker(details, searchString)
      end
    end

    -- Couldn't find anything that matched
    rejects[searchString] = true
  end
  return MatchesText
end

local function ApplyCombinedTerms(fullSearchString)
  if fullSearchString:match("[|]") then
    local checks = {}
    local checkPart = {}
    for part in fullSearchString:gmatch("[^|]+") do
      table.insert(checks, ApplyCombinedTerms(part))
      table.insert(checkPart, part)
    end
    return function(details)
      for index, check in ipairs(checks) do
        local result = check(details, checkPart[index])
        if result then
          return true
        elseif result == nil then
          return nil
        end
      end
      return false
    end
  elseif fullSearchString:match("[&]") then
    local checks = {}
    local checkPart = {}
    for part in fullSearchString:gmatch("[^&]+") do
      table.insert(checks, ApplyCombinedTerms(part))
      table.insert(checkPart, part)
    end
    return function(details)
      for index, check in ipairs(checks) do
        local result = check(details, checkPart[index])
        if result == false then
          return false
        elseif result == nil then
          return nil
        end
      end
      return true
    end
  elseif fullSearchString:match("^~") then
    local newSearchString = fullSearchString:sub(2, #fullSearchString)
    local nested = ApplyCombinedTerms(newSearchString)
    return function(details)
      local result = nested(details, newSearchString)
      if result ~= nil then
        return not result
      end
      return nil
    end
  else
    return ApplyKeyword(fullSearchString)
  end
end

function Baganator.UnifiedBags.Search.CheckItem(details, searchString)
  local check = matches[searchString]
  if not check then
    check = ApplyCombinedTerms(searchString)
    matches[searchString] = check
  end

  return check(details, searchString)
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

  local armorTypesToCheck = {
    1, -- cloth
    2, -- leather
    3, -- mail
    4, -- plate
  }
  for _, subClass in ipairs(armorTypesToCheck) do
    local keyword = GetItemSubClassInfo(Enum.ItemClass.Armor, subClass)
    if keyword ~= nil then
      KEYWORDS_TO_CHECK[keyword:lower()] = function(details)
        return details.classID == Enum.ItemClass.Armor and details.subClassID == subClass
      end
    end
  end

  -- All weapons + fishingpole
  for subClass = 0, 20 do
    local keyword = GetItemSubClassInfo(Enum.ItemClass.Weapon, subClass)
    if keyword ~= nil then
      KEYWORDS_TO_CHECK[keyword:lower()] = function(details)
        return details.classID == Enum.ItemClass.Weapon and details.subClassID == subClass
      end
    end
  end

  for key in pairs(KEYWORDS_TO_CHECK) do
    table.insert(sortedKeywords, key)
  end
  table.sort(sortedKeywords)
end
