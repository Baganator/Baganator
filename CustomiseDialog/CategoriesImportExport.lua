local addonName, addonTable = ...

function Baganator.CustomiseDialog.GetCategoriesImportExport(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(300, 50)

  local input = CreateFrame("EditBox", nil, container, "InputBoxTemplate")

  input:SetPoint("TOPLEFT", 20, 0)
  input:SetPoint("TOPRIGHT", -10, 0)
  input:SetHeight(22)
  input:SetAutoFocus(false)

  local exportButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  exportButton:SetPoint("BOTTOMRIGHT", container, -15, 0)
  exportButton:SetText(BAGANATOR_L_EXPORT_ALL)
  DynamicResizeButton_Resize(exportButton)
  exportButton:SetScript("OnClick", function()
    local export = {
      version = 1,
      categories = {},
      modifications = {},
      hidden = {},
      order = CopyTable(Baganator.Config.Get("category_display_order")),
    }
    for _, category in pairs(Baganator.Config.Get("custom_categories")) do
      table.insert(export.categories, {
        name = category.name,
        priority = category.searchPriority,
        search = category.search,
      })
    end
    for key, mods in pairs(Baganator.Config.Get("category_modifications")) do
      local items, pets = {}, {}
      if mods.addedItems then
        for _, item in ipairs(mods.addedItems) do
          if item.itemID then
            table.insert(items, item.itemID)
          elseif item.petID then
            table.insert(pets, item.petID)
          else
            assert(false, "missing item type")
          end
        end
      end
      table.insert(export.modifications, {
        source = key,
        items = #items > 0 and items or nil,
        pets = #pets > 0 and pets or nil,
      })
    end
    for source, isHidden in pairs(Baganator.Config.Get("category_hidden")) do
      if isHidden then
        table.insert(export.hidden, source)
      end
    end
    input:SetText(addonTable.json.encode(export))
  end)
  Baganator.Skins.AddFrame("Button", exportButton)

  local importButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  importButton:SetPoint("BOTTOMLEFT", container, 19, 0)
  importButton:SetText(BAGANATOR_L_IMPORT)
  DynamicResizeButton_Resize(importButton)
  importButton:SetScript("OnClick", function()
    local success, import = pcall(addonTable.json.decode, input:GetText())
    if not success then
      Baganator.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
      return
    end
    local customCategories = {}
    local categoryMods = {}
    if type(import.categories) ~= "table" or type(import.order) ~= "table" or type(import.categories) ~= "table" then
      Baganator.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
      return
    end
    for _, c in ipairs(import.categories) do
      if type(c.priority) ~= "number" or type(c.search) ~= "string" or
        type(c.name) ~= "string" or c.name == "" or
        (c.items ~= nil and type(c.items) ~= "table") or
        (c.pets ~= nil and type(c.pets) ~= "table") then
        Baganator.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
        return
      end

      local newCategory = {
        name = c.name,
        search = c.search,
        searchPriority = c.priority,
      }

      customCategories[newCategory.name] = newCategory
    end

    local seenItems = {}
    -- or is for legacy exports that put the mods in the categories rather than
    -- separately
    for _, c in ipairs(import.modifications or import.categories) do
      local newMods = {}
      if c.items then
        newMods.addedItems = newMods.addedItems or {}
        for _, itemID in ipairs(c.items) do
          if type(itemID) ~= "number" then
            Baganator.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
            return
          end
          local key = "i:" .. itemID
          if not seenItems[key] then
            seenItems[key] = true
            table.insert(newMods.addedItems, {itemID = itemID})
          end
        end
      end

      if c.pets then
        newMods.addedItems = newMods.addedItems or {}
        for _, petID in ipairs(c.pets) do
          if type(petID) ~= "number" then
            Baganator.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
            return
          end
          local key = "p:" .. itemID
          if not seenItems[key] then
            seenItems[key] = true
            table.insert(newMods.addedItems, {petID = petID})
          end
        end
      end
      categoryMods[c.source] = newMods
    end
    local hidden = {}
    if import.hidden then
      if type(import.hidden) ~= "table" then
        Baganator.Utilities.Message(BAGANATOR_L_INVALID_CATEGORY_IMPORT_FORMAT)
        return
      end
      for _, source in ipairs(import.hidden) do
        hidden[source] = true
      end
    end
    local displayOrder = {}
    for _, source in ipairs(import.order) do
      local category = Baganator.CategoryViews.Constants.SourceToCategory[source] or customCategories[source]
      if category or source == Baganator.CategoryViews.Constants.DividerName then
        table.insert(displayOrder, source)
      end
    end
    if tIndexOf(displayOrder,Baganator.CategoryViews.Constants.ProtectedCategory) == nil  then
      table.insert(displayOrder, Baganator.CategoryViews.Constants.ProtectedCategory)
    end

    local currentCustomCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    for source, category in pairs(customCategories) do
      currentCustomCategories[source] = category
    end
    local currentCategoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
    -- Prevent duplicate items in multiple category modifications caused by an import
    for source, details in pairs(currentCategoryMods) do
      if categoryMods[source] == nil and details.addedItems and #details.addedItems > 0 then
        for i = #details.addedItems, 1 do
          local item = details.addedItems[i]
          if item.itemID and seenItems["i:" .. item.itemID] then
            table.remove(details.addedItems, i)
          elseif item.petID and seenItems["p:" .. item.petID] then
            table.remove(details.addedItems, i)
          end
        end
      end
    end
    for source, details in pairs(categoryMods) do
      currentCategoryMods[source] = details
    end
    Baganator.Config.Set(Baganator.Config.Options.CUSTOM_CATEGORIES, CopyTable(currentCustomCategories))
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(currentCategoryMods))
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, displayOrder)
  end)
  Baganator.Skins.AddFrame("Button", importButton)

  return container
end
