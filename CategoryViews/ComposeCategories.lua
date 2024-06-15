local inventorySlots = {
  "INVTYPE_HEAD",
  "INVTYPE_NECK",
  "INVTYPE_SHOULDER",
  "INVTYPE_BODY",
  "INVTYPE_WAIST",
  "INVTYPE_LEGS",
  "INVTYPE_FEET",
  "INVTYPE_WRIST",
  "INVTYPE_HAND",
  "INVTYPE_FINGER",
  "INVTYPE_TRINKET",
  "INVTYPE_WEAPON",
  "INVTYPE_RANGED",
  "INVTYPE_CLOAK",
  "INVTYPE_2HWEAPON",
  "INVTYPE_BAG",
  "INVTYPE_TABARD",
  "INVTYPE_WEAPONMAINHAND",
  "INVTYPE_WEAPONOFFHAND",
  "INVTYPE_SHIELD",
  "INVTYPE_HOLDABLE",
  "INVTYPE_AMMO",
  "INVTYPE_THROWN",
  "INVTYPE_RANGEDRIGHT",
  "INVTYPE_QUIVER",
  "INVTYPE_RELIC",
  "INVTYPE_PROFESSION_TOOL",
  "INVTYPE_PROFESSION_GEAR",
  "INVTYPE_CHEST",
  "INVTYPE_ROBE",
}

local AllTheThingsCategories = {
  seenItemIDs = {},
  itemIDsToProcess = {},
  searches = {},
  searchLabels = {},
}
function AllTheThingsCategories:IsCollected(attData)
  if attData.g then
    for _, entry in ipairs(attData.g) do
      local collected, result = self:IsCollected(entry)
      if not collected then
        if not result then
          print("lost", result)
        end
        return collected, result
      end
    end
  elseif attData.mountID then
    return (select(11, C_MountJournal.GetMountInfoByID(attData.mountID))), attData
  elseif attData.sourceID then -- transmog
    return C_TransmogCollection.GetSourceInfo(attData.sourceID).isCollected, attData
  elseif attData.toyID then
    return PlayerHasToy(attData.toyID), attData
  elseif attData.speciesID then
    return C_PetJournal.GetNumCollectedInfo(attData.speciesID) > 0, attData
  elseif attData.recipeID then
    return IsPlayerSpell(attData.recipeID), attData
  end
  return false, attData
end

local expansionIDToText = {
  [0] = "Cla",
  [1] = "TBC",
  [2] = "Wra",
  [3] = "Cat",
  [4] = "MoP",
  [5] = "Dra",
  [6] = "Leg",
  [7] = "BfA",
  [8] = "SL",
  [9] = "DF",
}

function AllTheThingsCategories:Generate()
  local start = debugprofilestop()

  for itemID in pairs(self.itemIDsToProcess) do
    self.itemIDsToProcess[itemID] = nil
    local ATTSearch = ATTC.SearchForField("itemIDAsCost", itemID)
    local entry
    for _, attData in ipairs(ATTSearch) do
      local collected, result = self:IsCollected(attData)
      if not collected then
        entry = result
        break
      end
    end
    if entry and not Syndicator.Search.AnyDifferentATTHeaders(ATTSearch) then
      local itemSpecific = ATTC.SearchForField("itemID", itemID)[1]
      local headerText = Syndicator.Search.GetWantedATTHeader(entry) or Syndicator.Search.GetWantedATTHeader(itemSpecific)

      if itemID == 208047 then
        print("in:", headerText)
      end
      local patch = ATTC.GetRelativeValue(itemSpecific, "awp")
      if patch then
        patch = math.floor(patch / 10000)
      else
        patch = 1
      end
      local expansionText = expansionIDToText[patch - 1]
      if headerText then
        local searchText = "att:" .. headerText:lower()
        local oldIndex = tIndexOf(self.searchLabels, text)
        local patchSearch = patch .. ".&"
        if patch == 1 then
          patchSearch = ""
        end
        if oldIndex then
          self.searches[oldIndex] = self.searches[oldIndex] .. "|" .. patchSearch .. searchText
        else
          table.insert(self.searchLabels, expansionText .. ": " .. headerText)
          table.insert(self.searches, patchSearch .. searchText)
        end
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("att categories took", debugprofilestop() - start)
  end
end
function AllTheThingsCategories:AddItems(items)
  local anyNew = false
  for _, item in ipairs(items) do
    if not self.seenItemIDs[item.itemID] then
      self.seenItemIDs[item.itemID] = true
      self.itemIDsToProcess[item.itemID] = true
    end
  end

  if next(self.itemIDsToProcess) then
    self:Generate()
  end
end

function Baganator.CategoryViews.GenerateATTCategories(items)
  AllTheThingsCategories:AddItems(items)
end

-- Generate automatic categories, currently only equipment sets
local function GetAuto(category, everything)
  local searches, searchLabels = {}, {}
  if category.auto == "equipment_sets" then
    local names = Baganator.ItemViewCommon.GetEquipmentSetNames()
    if #names == 0 then
      table.insert(searchLabels, BAGANATOR_L_CATEGORY_EQUIPMENT_SET)
      table.insert(searches, SYNDICATOR_L_KEYWORD_EQUIPMENT_SET)
    else
      for _, name in ipairs(names) do
        table.insert(searchLabels, name)
        table.insert(searches, SYNDICATOR_L_KEYWORD_EQUIPMENT_SET .. "&" .. name:lower())
      end
    end
  elseif category.auto == "inventory_slots" then
    for _, slot in ipairs(inventorySlots) do
      local name = _G[slot]
      if name then
        table.insert(searchLabels, name)
        table.insert(searches, SYNDICATOR_L_KEYWORD_GEAR .. "&" .. name:lower())
      end
    end
  elseif category.auto == "all_the_things" then
    AllTheThingsCategories:AddItems(everything)
    searches, searchLabels = AllTheThingsCategories.searches, AllTheThingsCategories.searchLabels
  else
    error("automatic category type not supported")
  end
  return {searches = searches, searchLabels = searchLabels}
end

function Baganator.CategoryViews.ComposeCategories(everything)
  local searches, searchLabels, priorities, dividerPoints = {}, {}, {}, {}

  local customSearches = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  local attachedItems = {}
  local categoryKeys = {}
  for index, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    if source == Baganator.CategoryViews.Constants.DividerName then
      dividerPoints[#searches + 1] = true
    end
    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      if category.auto then
        local autoDetails = GetAuto(category, everything)
        for index = 1, #autoDetails.searches do
          local search = autoDetails.searches[index]
          if not categoryKeys[search] then
            table.insert(searches, search)
            table.insert(searchLabels, autoDetails.searchLabels[index])
            priorities[search] = category.searchPriority
            customSearches[search] = false
            categoryKeys[search] = category.source .. "_" .. search
          end
        end
      elseif not categoryKeys[search] then
        table.insert(searches, category.search)
        table.insert(searchLabels, category.name)
        priorities[category.search] = category.searchPriority
        customSearches[category.search] = false
        categoryKeys[category.search] = category.source
      end
    end
    category = customCategories[source]
    if category then
      local search = category.search:lower()
      if search == "" then
        search = "________" .. (#searches + 1)
      end
      if not categoryKeys[search] then
        table.insert(searches, search)
        table.insert(searchLabels, category.name)
        priorities[search] = category.searchPriority
        customSearches[search] = customSearches[search] == nil
        categoryKeys[search] = categoryKeys[search] or category.name
        if category.addedItems and next(category.addedItems) then
          attachedItems[search] = {}
          for _, details in ipairs(category.addedItems) do
            if details.itemID then
              attachedItems[search]["i:" .. details.itemID] = true
            elseif details.petID then
              attachedItems[search]["p:" .. details.petID] = true
            end
          end
        end
      end
    end
  end

  return {
    searches = searches,
    searchLabels = searchLabels,
    priorities = priorities,
    attachedItems = attachedItems,
    categoryKeys = categoryKeys,
    customSearches = customSearches,
    customCategories = customCategories,
    dividerPoints = dividerPoints,
  }
end
