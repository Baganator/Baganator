-- Generate automatic categories, currently only equipment sets
local function GetAuto(category)
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
    return {searches = searches, searchLabels = searchLabels}
  else
    error("automatic category type not supported")
  end
end

function Baganator.CategoryViews.ComposeCategories()
  local searches, searchLabels, priorities = {}, {}, {}

  local customSearches = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  local attachedItems = {}
  local categoryKeys = {}
  for index, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      if category.auto then
        local autoDetails = GetAuto(category)
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
  }
end
