local addonName, addonTable = ...

function Baganator.CustomiseDialog.GetCategoriesImportExport(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(300, 100)

  local input = CreateFrame("EditBox", nil, container, "InputBoxTemplate")

  input:SetPoint("TOPLEFT", 20, 0)
  input:SetPoint("TOPRIGHT", -10, 0)
  input:SetHeight(22)
  input:SetAutoFocus(false)

  local exportButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  exportButton:SetPoint("BOTTOMLEFT", container, 19, 0)
  exportButton:SetText(BAGANATOR_L_EXPORT_ALL)
  DynamicResizeButton_Resize(exportButton)
  exportButton:SetScript("OnClick", function()
    local export = {
      version = 1,
      categories = {},
      order = CopyTable(Baganator.Config.Get("category_display_order")),
    }
    for _, category in pairs(Baganator.Config.Get("custom_categories")) do
      local items, pets = {}, {}
      if category.addedItems then
        for _, item in ipairs(category.addedItems) do
          if item.itemID then
            table.insert(items, item.itemID)
          elseif item.petID then
            table.insert(pets, item.petID)
          else
            assert(false, "missing item type")
          end
        end
      end
      table.insert(export.categories, {
        name = category.name,
        priority = category.searchPriority,
        search = category.search,
        items = #items > 0 and items or nil,
        pets = #pets > 0 and pets or nil,
      })
    end
    input:SetText(addonTable.json.encode(export))
  end)
  Baganator.Skins.AddFrame("Button", exportButton)

  local importButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  importButton:SetPoint("BOTTOMRIGHT", container, -15, 0)
  importButton:SetText(BAGANATOR_L_IMPORT)
  DynamicResizeButton_Resize(importButton)
  importButton:SetScript("OnClick", function()
    local import = addonTable.json.decode(input:GetText())
    local customCategories = {}
    assert(type(import.categories) == "table")
    assert(type(import.order) == "table")
    for _, c in ipairs(import.categories) do
      assert(type(c.priority) == "number")
      assert(type(c.search) == "string")
      assert(type(c.name) == "string" and c.name ~= "")
      assert(c.items == nil or type(c.items) == "table")
      assert(c.pets == nil or type(c.pets) == "table")

      local newCategory = {
        name = c.name,
        search = c.search,
        searchPriority = c.priority,
      }

      if c.items then
        newCategory.addedItems = newCategory.addedItems or {}
        for _, itemID in ipairs(c.items) do
          assert(type(itemID) == "number")
          table.insert(newCategory.addedItems, {itemID = itemID})
        end
      end

      if c.pets then
        newCategory.addedItems = newCategory.addedItems or {}
        for _, petID in ipairs(c.pets) do
          assert(type(petID) == "number")
          table.insert(newCategory.addedItems, {petID = petID})
        end
      end

      customCategories[newCategory.name] = newCategory
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
    Baganator.Config.Set(Baganator.Config.Options.CUSTOM_CATEGORIES, CopyTable(currentCustomCategories))
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, displayOrder)
  end)
  Baganator.Skins.AddFrame("Button", importButton)

  return container
end
