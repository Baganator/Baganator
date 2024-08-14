local _, addonTable = ...
local function MigrateFormat()
  if addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MIGRATION) == 0 then
    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    for key, categoryDetails in pairs(customCategories) do
      categoryMods[key] = { addedItems = categoryDetails.addedItems }
      categoryDetails.addedItems = nil
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MIGRATION, 1)
  end
  if addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MIGRATION) == 1 then
    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    for key, categoryDetails in pairs(customCategories) do
      if not categoryMods[key] then
        categoryMods[key] = {}
      end
      categoryMods[key].priority = addonTable.CategoryViews.Constants.OldPriorities[categoryDetails.searchPriority] or 0
      categoryDetails.searchPriority = nil
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MIGRATION, 2)
  end
  if addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MIGRATION) == 2 then
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    for key, mods in pairs(categoryMods) do
      local oldAddedItems = mods.addedItems
      if oldAddedItems ~= nil then
        mods.addedItems = {}
        for _, item in ipairs(oldAddedItems) do
          if item.petID then
            mods.addedItems["p:" .. item.petID] = true
          elseif item.itemID then
            mods.addedItems["i:" .. item.itemID] = true
          end
        end
      end
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MIGRATION, 3)
  end
end

local function SetupCategories()
  local alreadyAdded = addonTable.Config.Get(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED)
  local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
  for index, category in ipairs(addonTable.CategoryViews.Constants.DefaultCategories) do
    if not alreadyAdded[category.source] and not category.doNotAdd then
      if index > #displayOrder then
        table.insert(displayOrder, category.source)
      else
        table.insert(displayOrder, index, category.source)
      end
      alreadyAdded[category.source] = true
    end
  end

  for _, source in ipairs(addonTable.CategoryViews.Constants.ProtectedCategories) do
    if tIndexOf(displayOrder, source) == nil then
      table.insert(displayOrder, source)
    end
  end

  -- Trigger settings changed event
  addonTable.Config.Set(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED, CopyTable(alreadyAdded))
  addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
end

local function SetupAddRemoveItems()
  local activeItemID, activeItemLink

  local previousCategory

  addonTable.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink)
    activeItemID, activeItemLink = itemID, itemLink
    previousCategory = fromCategory
  end)

  -- Remove the item from its current category and add it to the new one
  addonTable.CallbackRegistry:RegisterCallback("CategoryAddItemEnd", function(_, toCategory)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local details = addonTable.CategoryViews.Utilities.GetAddedItemData(activeItemID, activeItemLink)
    if categoryMods[previousCategory] and categoryMods[previousCategory].addedItems then
      categoryMods[previousCategory].addedItems[details] = nil
      if next(categoryMods[previousCategory].addedItems) == nil then
        categoryMods[previousCategory].addedItems = nil
      end
    end

    -- Either the target doesn't exist or this is a remove from category request
    if not toCategory then
      return
    end

    if not categoryMods[toCategory] then
      categoryMods[toCategory] = {}
    end

    categoryMods[toCategory].addedItems = categoryMods[toCategory].addedItems or {}

    categoryMods[toCategory].addedItems[details] = true
  end)
end

function addonTable.CategoryViews.Initialize()
  MigrateFormat()

  SetupCategories()

  addonTable.CallbackRegistry:RegisterCallback("ResetCategoryOrder", function()
    -- Avoid the settings changed event firing
    table.wipe(addonTable.Config.Get(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED))
    table.wipe(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER))

    SetupCategories()
  end)

  SetupAddRemoveItems()
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
  if not Syndicator then
    return
  end

  local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
  local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
  if #displayOrder > 0 then
    for i = #displayOrder, 1, -1 do
      local source = displayOrder[i]
      local category = addonTable.CategoryViews.Constants.SourceToCategory[source] or customCategories[source]
      if not category and source ~= addonTable.CategoryViews.Constants.DividerName and not source:match("^_") then
        table.remove(displayOrder, i)
      end
    end
  end
  addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
end)
