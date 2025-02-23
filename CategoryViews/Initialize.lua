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
  if addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MIGRATION) == 3 then
    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    local index = 1
    local oldCustom = CopyTable(customCategories)
    for key, category in pairs(oldCustom) do
      local displayIndex = tIndexOf(displayOrder, key)
      if displayIndex then
        displayOrder[displayIndex] = tostring(index)
      end
      customCategories[tostring(index)] = category
      categoryMods[tostring(index)] = categoryMods[key]

      customCategories[key] = nil
      categoryMods[key] = nil

      index = index + 1
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MIGRATION, 4)
  end
  if addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MIGRATION) == 4 then
    local categorySections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    local index = 1
    for displayIndex, entry in ipairs(displayOrder) do
      if entry:match("^_") and entry ~= addonTable.CategoryViews.Constants.SectionEnd then
        local name = entry:match("_(.*)")
        categorySections[tostring(index)] = { name = name }
        displayOrder[displayIndex] = "_" .. index
        index = index + 1
      end
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MIGRATION, 5)
  end
end

-- Somehow on older versions a few users have missing SectionEnds for their
-- sections, or the SectionEnd is in the wrong place, this fixes that.
function addonTable.CategoryViews.FixAnyBrokenSections()
  local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

  local level = 0
  local index = 0
  local currentSection = {}
  while index < # displayOrder do
    index = index + 1
    local source = displayOrder[index]
    if source == addonTable.CategoryViews.Constants.SectionEnd and level == 0 then
      table.remove(displayOrder, index)
      index = index - 1
    elseif source == addonTable.CategoryViews.Constants.SectionEnd then
      level = level - 1
      table.remove(currentSection)
    elseif source:match("^_") then
      level = level + 1
      table.insert(currentSection, index)
    end
  end

  if #currentSection > 0 then
    for i = #currentSection, 1, -1 do
      local insertIndex = #displayOrder + 1
      for j = currentSection[i] + 1, #displayOrder do
        if displayOrder[j]:match("^_") then
          insertIndex = j
          break
        end
      end
      table.insert(displayOrder, insertIndex, addonTable.CategoryViews.Constants.SectionEnd)
    end
  end
  addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
end

local function CompareCurrent()
  local current = addonTable.CustomiseDialog.CategoriesExport()
  local toMod = addonTable.json.decode(current)
  local defaultImport = addonTable.json.decode(
  -- math.max(1 in case the user has an old category layout from before the
  -- defaults import was added
    addonTable.CategoryViews.Constants.DefaultImport[math.max(1, addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DEFAULT_IMPORT))]
  )

  if #toMod.order ~= #defaultImport.order then
    return false
  end

  for index, toModEntry in ipairs(toMod.order) do
    local defaultEntry = defaultImport.order[index]
    -- Complicated comparison to account for change in section storage
    if defaultEntry ~= toModEntry and (defaultEntry:sub(1, 1) ~= "_" or toModEntry:sub(1, 1) ~= "_") then
      return false
    end
  end
  return true
end

local function SetupCategories()
  local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
  local oldCategoryMods = CopyTable(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS))
  local oldSections = CopyTable(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS))

  if addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DEFAULT_IMPORT) < addonTable.CategoryViews.Constants.DefaultImportVersion then
    local displayOrderForCmp = CopyTable(displayOrder)
    if displayOrderForCmp[1] == "default_auto_recents" then
      table.remove(displayOrderForCmp, 1)
    end
    -- If the layout hasn't been changed, or has only had "Recent (Auto)" added
    if tCompare(displayOrderForCmp, addonTable.CategoryViews.Constants.OldDefaults) or #displayOrder == 0 or CompareCurrent() then

      addonTable.CustomiseDialog.CategoriesImport(addonTable.CategoryViews.Constants.DefaultImport[addonTable.CategoryViews.Constants.DefaultImportVersion])
      Mixin(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS, oldSections))
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, oldCategoryMods)
      local newAdded = {}
      for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
        if addonTable.CategoryViews.Constants.SourceToCategory[source] then
          newAdded[source] = true
        end
      end
      addonTable.Config.Set(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED, newAdded)
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DEFAULT_IMPORT, addonTable.CategoryViews.Constants.DefaultImportVersion)
  end
  -- Bugfix for AUTOMATIC_CATEGORIES_ADDED being set wrong in previous versions
  if #addonTable.Config.Get(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED) > 0 then
    local newAdded = {}
    for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED)) do
      newAdded[source] = true
    end
    addonTable.Config.Set(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED, newAdded)
  end

  addonTable.CategoryViews.FixAnyBrokenSections()

  for _, source in ipairs(addonTable.CategoryViews.Constants.ProtectedCategories) do
    if tIndexOf(displayOrder, source) == nil then
      table.insert(displayOrder, source)
    end
  end
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
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
      return
    end

    if not categoryMods[toCategory] then
      categoryMods[toCategory] = {}
    end

    categoryMods[toCategory].addedItems = categoryMods[toCategory].addedItems or {}

    categoryMods[toCategory].addedItems[details] = true

    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
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
