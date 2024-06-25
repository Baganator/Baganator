local function PopulateCategoryOrder(container)
  local hidden = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)

  local elements = {}
  local dataProviderElements = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local color = WHITE_FONT_COLOR
    if hidden[source] then
      color = GRAY_FONT_COLOR
    end

    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = color:WrapTextInColorCode(category.name)})
      table.insert(elements, source)
    end
    category = customCategories[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = color:WrapTextInColorCode(category.name .. " (*)")})
      table.insert(elements, source)
    end
    if source == Baganator.CategoryViews.Constants.DividerName then
      table.insert(dataProviderElements, {value = source, label = Baganator.CategoryViews.Constants.DividerLabel})
      table.insert(elements, source)
    end
  end

  container.elements = elements
  container.ScrollBox:SetDataProvider(CreateDataProvider(dataProviderElements), true)
end

local function GetCategoryContainer(parent, pickupCallback, visibilityCallback)
  local container = Baganator.CustomiseDialog.GetContainerForDragAndDrop(parent, function(value, label, index)
    if value ~= Baganator.CategoryViews.Constants.ProtectedCategory then
      pickupCallback(value, label, index)
    end
  end, { {
    tooltipText = BAGANATOR_L_TOGGLE_VISIBILITY,
    callback = visibilityCallback,
    atlas = "socialqueuing-icon-eye",
  } }, Baganator.CategoryViews.Constants.ProtectedCategory)
  container:SetSize(250, 420)

  container.ScrollBox:GetView():RegisterCallback("OnAcquiredFrame", function(_, frame)
    if frame.visibilityButton then
      return
    end

    local button = CreateFrame("Button", nil, frame)
    button:SetSize(16, 16)
    button:SetNormalAtlas("socialqueuing-icon-eye")
    button:SetScript("OnEnter", function()
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      if Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)[frame.value] then
        GameTooltip:SetText(BAGANATOR_L_SHOW_CATEGORY)
      else
        GameTooltip:SetText(BAGANATOR_L_HIDE_CATEGORY)
      end
      GameTooltip:Show()
      button:SetAlpha(0.5)
    end)
    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
      button:SetAlpha(1)
    end)
    button:SetScript("OnClick", function(self)
      visibilityCallback(self:GetParent().value, self:GetParent():GetText(), self:GetParent().indexValue)
    end)
    button:SetPoint("RIGHT", -30, 1)

    frame.visibilityButton = button
  end)
  container.ScrollBox:GetView():RegisterCallback("OnInitializedFrame", function(_, frame)
    if Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)[frame.value] then
      frame.visibilityButton:GetNormalTexture():SetVertexColor(1, 0, 0)
    else
      frame.visibilityButton:GetNormalTexture():SetVertexColor(1, 1, 1)
    end
  end)

  PopulateCategoryOrder(container)

  return container
end

local function GetInsertedCategories()
  local result = {}
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    result[source] = true
  end
  return result
end

local function SetCategoriesToDropDown(dropDown, ignore)
  local options = {}
  for source, category in pairs(Baganator.CategoryViews.Constants.SourceToCategory) do
    if not ignore[source] then
      table.insert(options, {label = category.name, value = source})
    end
  end
  for source, category in pairs(Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)) do
    if not ignore[source] then
      table.insert(options, {label = category.name .. " (*)", value = category.name})
    end
  end
  table.sort(options, function(a, b) return a.label:lower() < b.label:lower() end)

  local entries, values = {BAGANATOR_L_CATEGORY_DIVIDER}, {Baganator.CategoryViews.Constants.DividerName}

  for _, opt in ipairs(options) do
    table.insert(entries, opt.label)
    table.insert(values, opt.value)
  end

  dropDown:SetupOptions(entries, values)
end

function Baganator.CustomiseDialog.GetCategoriesOrganiser(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(300, 500)
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
      local f, isTop, index = Baganator.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if not f then
        table.insert(categoryOrder.elements, draggable.value)
      else
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

  local dropDown = Baganator.CustomiseDialog.GetDropdown(container)
  SetCategoriesToDropDown(dropDown, GetInsertedCategories())

  local function Pickup(value, label, index)
    if index ~= nil then
      table.remove(categoryOrder.elements, index)
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end

    dropDown:SetText(label)
    draggable:Show()
    draggable.text:SetText(label)
    draggable.value = value
  end

  local function ToggleVisibility(value, label, index)
    local hidden = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)
    hidden[value] = not hidden[value]
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
  end

  categoryOrder = GetCategoryContainer(container, Pickup, ToggleVisibility)
  categoryOrder:SetPoint("TOPLEFT", 0, -40)

  dropDown:SetText(BAGANATOR_L_INSERT_CATEGORY)

  hooksecurefunc(dropDown, "OnEntryClicked", function(_, option)
    Pickup(option.value, option.label, option.value ~= Baganator.CategoryViews.Constants.DividerName and tIndexOf(categoryOrder.elements, option.value) or nil)
  end)
  draggable:SetScript("OnHide", function()
    dropDown:SetText(BAGANATOR_L_INSERT_CATEGORY)
  end)
  dropDown:SetPoint("TOPLEFT", 0, 0)
  dropDown:SetPoint("RIGHT", categoryOrder)

  local resetOrderToDefault = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  resetOrderToDefault:SetPoint("TOPLEFT", categoryOrder, "BOTTOMLEFT", -5, -10)
  resetOrderToDefault:SetText(BAGANATOR_L_USE_DEFAULT)
  DynamicResizeButton_Resize(resetOrderToDefault)
  resetOrderToDefault:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("ResetCategoryOrder")
  end)
  Baganator.Skins.AddFrame("Button", resetOrderToDefault)

  local revertOrderChanges = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  revertOrderChanges:SetPoint("TOPRIGHT", categoryOrder, "BOTTOMRIGHT", 5, -10)
  revertOrderChanges:SetText(BAGANATOR_L_REVERT_CHANGES)
  DynamicResizeButton_Resize(revertOrderChanges)
  revertOrderChanges:SetScript("OnClick", function()
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, previousOrder)
  end)
  Baganator.Skins.AddFrame("Button", revertOrderChanges)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == Baganator.Config.Options.CATEGORY_DISPLAY_ORDER or settingName == Baganator.Config.Options.CATEGORY_HIDDEN then
      SetCategoriesToDropDown(dropDown, GetInsertedCategories())
      PopulateCategoryOrder(categoryOrder)
    elseif settingName == Baganator.Config.Options.CUSTOM_CATEGORIES then
      SetCategoriesToDropDown(dropDown, GetInsertedCategories())
    end
  end)

  return container
end
