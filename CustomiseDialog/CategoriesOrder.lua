local function PopulateCategoryOrder(container)
  local elements = {}
  local dataProviderElements = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = category.name})
      table.insert(elements, source)
    end
    category = customCategories[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = category.name .. " (*)"})
      table.insert(elements, source)
    end
  end

  container.elements = elements
  container.ScrollBox:SetDataProvider(CreateDataProvider(dataProviderElements), true)
end

local function GetCategoryContainer(parent, callback)
  local container = Baganator.CustomiseDialog.GetContainerForDragAndDrop(parent, function(value, label)
    if value ~= Baganator.CategoryViews.Constants.ProtectedCategory then
      callback(value, label)
    end
  end)
  container:SetSize(250, 280)

  PopulateCategoryOrder(container)

  return container
end

local function SetCategoriesToDropDown(dropDown)
  local options = {}
  for source, category in pairs(Baganator.CategoryViews.Constants.SourceToCategory) do
    table.insert(options, {label = category.name, value = source})
  end
  for source, category in pairs(Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)) do
    table.insert(options, {label = category.name .. " (*)", value = category.name})
  end
  table.sort(options, function(a, b) return a.label < b.label end)

  local entries, values = {}, {}

  for _, opt in ipairs(options) do
    table.insert(entries, opt.label)
    table.insert(values, opt.value)
  end

  dropDown:SetupOptions(entries, values)
end

function Baganator.CustomiseDialog.GetCategoriesOrganiser(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(600, 280)
  container:SetPoint("CENTER")

  local previousOrder = CopyTable(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER))

  container:SetScript("OnShow", function()
    previousOrder = CopyTable(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER))
  end)

  local categoryOrder
  local highlightContainer = CreateFrame("Frame", nil, container)
  local highlight = highlightContainer:CreateTexture(nil, "OVERLAY", nil, 7)
  highlight:SetSize(200, 20)
  highlight:SetAtlas("128-RedButton-Highlight")
  highlight:Hide()
  local draggable
  draggable = Baganator.CustomiseDialog.GetDraggable(function()
    if categoryOrder:IsMouseOver() then
      local f, isTop = Baganator.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if not f then
        table.insert(categoryOrder.elements, draggable.value)
      else
        local index = tIndexOf(categoryOrder.elements, f.value)
        if isTop then
          table.insert(categoryOrder.elements, index, draggable.value)
        else
          table.insert(categoryOrder.elements, index + 1, draggable.value)
        end
      end
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end
    highlight:Hide()
  end, function()
    highlight:ClearAllPoints()
    highlight:Hide()
    if categoryOrder:IsMouseOver() then
      highlight:Show()
      local f, isTop = Baganator.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if f and isTop then
        highlight:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, -10)
      elseif f then
        highlight:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 10)
      else
        highlight:SetPoint("BOTTOMLEFT", categoryOrder, 0, 0)
      end
    end
  end)

  local dropDown = CreateFrame("EventButton", nil, parent, "BaganatorCustomiseGetSelectionPopoutButtonTemplate")
  SetCategoriesToDropDown(dropDown)

  local function Pickup(value, label)
    local index = tIndexOf(categoryOrder.elements, value)
    if index ~= nil then
      table.remove(categoryOrder.elements, index)
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end

    dropDown:SetText(label)
    draggable:Show()
    draggable.text:SetText(label)
    draggable.value = value
  end

  categoryOrder = GetCategoryContainer(container, Pickup)
  categoryOrder:SetPoint("TOPLEFT", 0, 10)

  local description = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  description:SetText(BAGANATOR_L_ORDER_CATEGORIES_DESCRIPTION)
  description:SetPoint("TOPLEFT", categoryOrder, "TOPRIGHT", 30, -10)
  description:SetPoint("RIGHT", -10, 0)
  description:SetTextColor(1, 1, 1)
  description:SetJustifyH("LEFT")

  dropDown:SetText(BAGANATOR_L_ALL_CATEGORIES)

  hooksecurefunc(dropDown, "OnEntryClicked", function(_, option)
    Pickup(option.value, option.label)
  end)
  draggable:SetScript("OnHide", function()
    dropDown:SetText(BAGANATOR_L_ALL_CATEGORIES)
  end)
  dropDown:SetPoint("TOPLEFT", categoryOrder, "TOPRIGHT", 10, -40)
  dropDown:SetPoint("TOPRIGHT")

  local resetOrderToDefault = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  resetOrderToDefault:SetPoint("BOTTOMLEFT", categoryOrder, "BOTTOMRIGHT", 20, 10)
  resetOrderToDefault:SetText(BAGANATOR_L_USE_DEFAULT)
  DynamicResizeButton_Resize(resetOrderToDefault)
  resetOrderToDefault:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("ResetCategoryOrder")
  end)

  local revertOrderChanges = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  revertOrderChanges:SetPoint("BOTTOMLEFT", resetOrderToDefault, "BOTTOMRIGHT", 15, 0)
  revertOrderChanges:SetText(BAGANATOR_L_REVERT_CHANGES)
  DynamicResizeButton_Resize(revertOrderChanges)
  revertOrderChanges:SetScript("OnClick", function()
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, previousOrder)
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == Baganator.Config.Options.CATEGORY_DISPLAY_ORDER then
      PopulateCategoryOrder(categoryOrder)
    elseif settingName == Baganator.Config.Options.CUSTOM_CATEGORIES then
      SetCategoriesToDropDown(dropDown)
    end
  end)

  return container
end
