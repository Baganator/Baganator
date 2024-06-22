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

function Baganator.CategoryViews.ComposeCategories(everything)
  local searches, searchLabels, priorities, dividerPoints = {}, {}, {}, {}

  local customSearches = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  local attachedItems = {}
  local categoryKeys = {}
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    if source == Baganator.CategoryViews.Constants.DividerName then
      dividerPoints[#searches + 1] = true
    end
    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      if category.auto then
        local autoDetails = GetAuto(category, everything)
        for index = 1, #autoDetails.searches do
          local search = autoDetails.searches[index]
          if search == "" then
            search = "________" .. (#searches + 1)
          end
          if not categoryKeys[search] then
            table.insert(searches, search)
            table.insert(searchLabels, autoDetails.searchLabels[index])
            priorities[search] = category.searchPriority
            customSearches[search] = false
            categoryKeys[search] = category.source .. "_" .. search
            if autoDetails.attachedItems[index] then
              attachedItems[search] = autoDetails.attachedItems[index]
            end
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
