local _, addonTable = ...

function addonTable.CustomiseDialog.SingleCategoryExport(name)
  local export = {
    version = 1,
    categories = {},
    modifications = {},
  }
  local category = addonTable.Config.Get("custom_categories")[name]
  table.insert(export.categories, {
    name = category.name,
    search = category.search,
    source = name,
  })
  local mods = addonTable.Config.Get("category_modifications")[name]
  local items, pets = {}, {}
  if mods and mods.addedItems then
    for details in pairs(mods.addedItems) do
      local t, id = details:match("^(.):(.*)$")
      if t == "i" then
        table.insert(items, tonumber(id))
      elseif t == "p" then
        table.insert(pets, tonumber(id))
      else
        assert(false, "missing item type")
      end
    end
  end
  table.insert(export.modifications, {
    source = name,
    items = #items > 0 and items or nil,
    pets = #pets > 0 and pets or nil,
    group = mods and mods.group,
    showGroupPrefix = mods.showGroupPrefix,
    priority = mods.priority,
  })

  return addonTable.json.encode(export)
end

function addonTable.CustomiseDialog.CategoriesExport()
  local export = {
    version = 1,
    categories = {},
    modifications = {},
    hidden = {},
    order = CopyTable(addonTable.Config.Get("category_display_order")),
  }
  for source, category in pairs(addonTable.Config.Get("custom_categories")) do
    table.insert(export.categories, {
      name = category.name,
      search = category.search,
      source = source,
    })
  end
  for key, mods in pairs(addonTable.Config.Get("category_modifications")) do
    local items, pets = {}, {}
    if mods.addedItems then
      for details in pairs(mods.addedItems) do
        local t, id = details:match("^(.):(.*)$")
        if t == "i" then
          table.insert(items, tonumber(id))
        elseif t == "p" then
          table.insert(pets, tonumber(id))
        else
          assert(false, "missing item type")
        end
      end
    end
    table.insert(export.modifications, {
      source = key,
      items = #items > 0 and items or nil,
      pets = #pets > 0 and pets or nil,
      group = mods.group,
      showGroupPrefix = mods.showGroupPrefix,
      priority = mods.priority,
    })
  end
  for source, isHidden in pairs(addonTable.Config.Get("category_hidden")) do
    if isHidden then
      table.insert(export.hidden, source)
    end
  end

  return addonTable.json.encode(export)
end

local function ImportCategories(import)
  local customCategories = {}
  local categoryMods = {}
  local priorities = {}
  for _, c in ipairs(import.categories) do
    if (type(c.priority) ~= "nil" and type(c.priority) ~= "number") or type(c.search) ~= "string" or
      type(c.name) ~= "string" or c.name == "" or
      (c.items ~= nil and type(c.items) ~= "table") or
      (c.pets ~= nil and type(c.pets) ~= "table") then
      addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
      return
    end

    local newCategory = {
      name = c.name,
      search = c.search,
    }
    if c.priority then
      priorities[c.source or c.name] = addonTable.CategoryViews.Constants.OldPriorities[c.priority]
    end

    customCategories[c.source or newCategory.name] = newCategory
  end

  local seenItems = {}
  -- or is for legacy exports that put the mods in the categories rather than
  -- separately
  for _, c in ipairs(import.modifications or import.categories) do
    local newMods = {}
    if import.modifications then
      if type(c.priority) ~= "nil" and type(c.priority) ~= "number" then
        addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
        return
      end
      newMods.priority = c.priority
    end
    if c.items then
      newMods.addedItems = newMods.addedItems or {}
      for _, itemID in ipairs(c.items) do
        if type(itemID) ~= "number" then
          addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
          return
        end
        local key = "i:" .. itemID
        if not seenItems[key] then
          seenItems[key] = true
          newMods.addedItems[key] = true
        end
      end
    end

    if c.pets then
      newMods.addedItems = newMods.addedItems or {}
      for _, petID in ipairs(c.pets) do
        if type(petID) ~= "number" then
          addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
          return
        end
        local key = "p:" .. petID
        if not seenItems[key] then
          seenItems[key] = true
          newMods.addedItems[key] = true
        end
      end
    end
    if c.group then
      if type(c.group) ~= "string" then
        addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
        return
      end
      newMods.group = c.group
    end
    if c.showGroupPrefix ~= nil then
      if type(c.showGroupPrefix) ~= "boolean" then
        addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
        return
      end
      newMods.showGroupPrefix = c.showGroupPrefix
    end
    categoryMods[c.source or c.name] = newMods
  end

  for source, priority in pairs(customCategories) do
    if not categoryMods[source] then
      categoryMods[source] = {priority = priorities[source] or 0}
    elseif not categoryMods[source].priority then
      categoryMods[source].priority = priorities[source] or 0
    end
  end

  return customCategories, categoryMods, seenItems
end

function addonTable.CustomiseDialog.CategoriesImport(input)
  local success, import = pcall(addonTable.json.decode, input)
  if not success then
    addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
    return
  end
  if type(import.categories) ~= "table" or (import.modifications and type(import.modifications) ~= "table") then
    addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
    return
  end
  local customCategories, categoryMods, seenItems = ImportCategories(import)

  local sourceMap = {}
  local reverseMap = {}
  do
    local currentCustomCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local seenSources = {}
    for key in pairs(customCategories) do
      local source = tostring(1)
      while currentCustomCategories[source] or seenSources[source] do
        source = tostring(tonumber(source) + 1)
      end
      sourceMap[key] = source
      reverseMap[source] = key
      seenSources[source] = true
    end
  end

  if import.order then
    if type(import.order) ~= "table" then
      addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
      return
    end

    local hidden = {}
    if import.hidden then
      if type(import.hidden) ~= "table" then
        addonTable.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
        return
      end
      for _, source in ipairs(import.hidden) do
        hidden[source] = true
      end
    end
    local displayOrder = {}
    for _, source in ipairs(import.order) do
      local category = addonTable.CategoryViews.Constants.SourceToCategory[source] or customCategories[source]
      if category or source == addonTable.CategoryViews.Constants.DividerName or source:match("^_") then
        table.insert(displayOrder, sourceMap[source] or source)
      end
    end
    for _, source in ipairs(addonTable.CategoryViews.Constants.ProtectedCategories) do
      if tIndexOf(displayOrder, source) == nil  then
        table.insert(displayOrder, source)
      end
    end

    local currentCustomCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    for source, category in pairs(customCategories) do
      currentCustomCategories[sourceMap[source]] = category
    end
    local currentCategoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    -- Prevent duplicate items in multiple category modifications caused by an import
    for source, details in pairs(currentCategoryMods) do
      if details.addedItems then
        for key in pairs(seenItems) do
          details.addedItems[key] = nil
        end
      end
    end
    for source, details in pairs(categoryMods) do
      currentCategoryMods[sourceMap[source] or source] = details
    end
    for _, source in ipairs(displayOrder) do
      if not categoryMods[reverseMap[source] or source] then
        currentCategoryMods[source] = nil
      end
    end
    addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(currentCustomCategories))
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(currentCategoryMods))
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, displayOrder)
  else
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    for key in pairs(customCategories) do
      table.insert(displayOrder, 1, sourceMap[key])
    end
    local currentCustomCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local currentCategoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    for source, details in pairs(currentCategoryMods) do
      if categoryMods[source] == nil and details.addedItems then
        for key in pairs(seenItems) do
          details.addedItems[key] = nil
        end
      end
    end
    for key, category in pairs(customCategories) do
      currentCustomCategories[sourceMap[key]] = category
      currentCategoryMods[sourceMap[key]] = categoryMods[key]
    end
    addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(currentCustomCategories))
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(currentCategoryMods))
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
  end
end
