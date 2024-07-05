local function MigrateFormat()
  if Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MIGRATION) == 0 then
    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
    for key, categoryDetails in pairs(customCategories) do
      categoryMods[key] = { addedItems = categoryDetails.addedItems }
      categoryDetails.addedItems = nil
    end
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_MIGRATION, 1)
  end
end

local function SetupCategories()
  local alreadyAdded = Baganator.Config.Get(Baganator.Config.Options.AUTOMATIC_CATEGORIES_ADDED)
  local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)
  for index, category in ipairs(Baganator.CategoryViews.Constants.DefaultCategories) do
    if not alreadyAdded[category.source] and not category.doNotAdd then
      if index > #displayOrder then
        table.insert(displayOrder, category.source)
      else
        table.insert(displayOrder, index, category.source)
      end
      alreadyAdded[category.source] = true
    end
  end

  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  if #displayOrder > 0 then
    for i = #displayOrder, 1, -1 do
      local source = displayOrder[i]
      local category = Baganator.CategoryViews.Constants.SourceToCategory[source] or customCategories[source]
      if not category and source ~= Baganator.CategoryViews.Constants.DividerName and not source:match("^_") then
        table.remove(displayOrder, i)
      end
    end
  end
  for _, source in ipairs(Baganator.CategoryViews.Constants.ProtectedCategories) do
    if tIndexOf(displayOrder, source) == nil then
      table.insert(displayOrder, source)
    end
  end

  -- Trigger settings changed event
  Baganator.Config.Set(Baganator.Config.Options.AUTOMATIC_CATEGORIES_ADDED, CopyTable(alreadyAdded))
  Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
end

local function SetupAddRemoveItems()
  local activeItemID, activeItemLink

  local previousCategory

  Baganator.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink)
    activeItemID, activeItemLink = itemID, itemLink
    previousCategory = fromCategory
  end)

  -- Remove the item from its current category and add it to the new one
  Baganator.CallbackRegistry:RegisterCallback("CategoryAddItemEnd", function(_, toCategory)
    local categoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
    local details = Baganator.CategoryViews.Utilities.GetAddedItemData(activeItemID, activeItemLink)
    if categoryMods[previousCategory] and categoryMods[previousCategory].addedItems then
      local oldIndex = FindInTableIf(categoryMods[previousCategory].addedItems, function(alt)
        return alt.itemID == details.itemID and alt.petID == details.petID
      end)
      if oldIndex then
        table.remove(categoryMods[previousCategory].addedItems, oldIndex)
        if #categoryMods[previousCategory].addedItems == 0 then
          categoryMods[previousCategory].addedItems = nil
        end
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

    local existingIndex = FindInTableIf(categoryMods[toCategory].addedItems, function(alt)
      return alt.itemID == details.itemID and alt.petID == details.petID
    end)
    if existingIndex then
      return
    end
    table.insert(categoryMods[toCategory].addedItems, details)
  end)
end

function Baganator.CategoryViews.Initialize()
  MigrateFormat()

  SetupCategories()

  Baganator.CallbackRegistry:RegisterCallback("ResetCategoryOrder", function()
    -- Avoid the settings changed event firing
    table.wipe(Baganator.Config.Get(Baganator.Config.Options.AUTOMATIC_CATEGORIES_ADDED))
    table.wipe(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER))

    SetupCategories()
  end)

  SetupAddRemoveItems()
end
