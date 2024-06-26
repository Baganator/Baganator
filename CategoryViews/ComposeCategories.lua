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

-- Generate automatic categories
local function GetAuto(category, everything)
  local searches, searchLabels, attachedItems = {}, {}, {}
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
  elseif category.auto == "recents" then
    table.insert(searches, "")
    table.insert(searchLabels, BAGANATOR_L_CATEGORY_RECENT)
    local newItems = {}
    for _, item in ipairs(everything) do
      if Baganator.NewItems:IsNewItemTimeout(item.bagID, item.slotID) then
        newItems[item.key] = true
      end
    end
    attachedItems[1] = newItems
  else
    error("automatic category type not supported")
  end
  return {searches = searches, searchLabels = searchLabels, attachedItems = attachedItems}
end

-- Organise category data ready for display, including removing duplicate
-- searches with priority determining which gets kept.
function Baganator.CategoryViews.ComposeCategories(everything)
  local allDetails = {}
  local dividerPoints = {}

  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  local categoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
  local categoryKeys = {}
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    if source == Baganator.CategoryViews.Constants.DividerName then
      dividerPoints[#allDetails + 1] = true
    end
    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      if category.auto then
        local autoDetails = GetAuto(category, everything)
        for index = 1, #autoDetails.searches do
          local search = autoDetails.searches[index]
          if search == "" then
            search = "________" .. (#allDetails + 1)
          end
          allDetails[#allDetails + 1] = {
            source = source,
            search = search,
            searchLabel = autoDetails.searchLabels[index],
            priority = category.searchPriority,
            isCustom = false,
            index = #allDetails + 1,
            attachedItems = autoDetails.attachedItems[index],
            auto = true,
          }
        end
      else
        allDetails[#allDetails + 1] = {
          source = source,
          search = category.search,
          searchLabel = category.name,
          priority = category.searchPriority,
          isCustom = false,
          index = #allDetails + 1,
          attachedItems = nil,
        }
      end
    end
    category = customCategories[source]
    if category then
      local search = category.search:lower()
      if search == "" then
        search = "________" .. (#allDetails + 1)
      end

      allDetails[#allDetails + 1] = {
        source = source,
        search = search,
        searchLabel = category.name,
        priority = category.searchPriority,
        isCustom = true,
        index = #allDetails + 1,
        attachedItems = nil,
      }
    end

    local mods = categoryMods[source]
    if mods and mods.addedItems and next(mods.addedItems) then
      local attachedItems = {}
      for _, details in ipairs(mods.addedItems) do
        if details.itemID then
          attachedItems["i:" .. details.itemID] = true
        elseif details.petID then
          attachedItems["p:" .. details.petID] = true
        end
      end
      allDetails[#allDetails].attachedItems = attachedItems
    end
  end

  local copy = CopyTable(allDetails, 1)
  table.sort(copy, function(a, b)
    if a.priority == b.priority then
      return a.index < b.index
    else
      return a.priority > b. priority
    end
  end)

  local seenSearches = {}
  local prioritisedSearches = {}
  for _, details in ipairs(copy) do
    if seenSearches[details.search] then
      details.search = "________" .. details.index
    end
    prioritisedSearches[#prioritisedSearches + 1] = details.search
    seenSearches[details.search] = true
  end

  local result = {
    searches = {},
    searchLabels = {},
    autoSearches = {},
    attachedItems = {},
    categoryKeys = {},
    dividerPoints = dividerPoints,
    prioritisedSearches = prioritisedSearches,
  }

  for _, details in ipairs(allDetails) do
    table.insert(result.searches, details.search)
    table.insert(result.searchLabels, details.searchLabel)
    result.autoSearches[details.search] = details.auto
    result.attachedItems[details.search] = details.attachedItems
    result.categoryKeys[details.search] = details.source
  end

  return result
end
