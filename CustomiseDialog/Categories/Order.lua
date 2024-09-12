local _, addonTable = ...
local exportDialog = "Baganator_Export_Dialog"
StaticPopupDialogs[exportDialog] = {
  text = BAGANATOR_L_CTRL_C_TO_COPY,
  button1 = DONE,
  hasEditBox = 1,
  OnShow = function(self, data)
    self.editBox:SetText(data)
    self.editBox:HighlightText()
  end,
  EditBoxOnEnterPressed = function(self)
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  editBoxWidth = 230,
  maxLetters = 0,
  timeout = 0,
  hideOnEscape = 1,
}

local importDialog = "Baganator_Import_Dialog"
StaticPopupDialogs[importDialog] = {
  text = BAGANATOR_L_PASTE_YOUR_IMPORT_STRING_HERE,
  button1 = BAGANATOR_L_IMPORT,
  button2 = CANCEL,
  hasEditBox = 1,
  OnShow = function(self, data)
    self.editBox:SetText("")
  end,
  OnAccept = function(self)
    addonTable.CustomiseDialog.CategoriesImport(self.editBox:GetText())
  end,
  EditBoxOnEnterPressed = function(self)
    addonTable.CustomiseDialog.CategoriesImport(self:GetText())
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  editBoxWidth = 230,
  maxLetters = 0,
  timeout = 0,
  hideOnEscape = 1,
}

local function PopulateCategoryOrder(container)
  local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)

  local elements = {}
  local dataProviderElements = {}
  local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
  local indent = ""
  for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local color = WHITE_FONT_COLOR
    if hidden[source] then
      color = GRAY_FONT_COLOR
    end

    local category = addonTable.CategoryViews.Constants.SourceToCategory[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = indent .. color:WrapTextInColorCode(category.name)})
      table.insert(elements, source)
    end
    category = customCategories[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = indent .. color:WrapTextInColorCode(category.name .. " (*)")})
      table.insert(elements, source)
    end
    if source == addonTable.CategoryViews.Constants.DividerName then
      table.insert(dataProviderElements, {value = source, label = indent .. addonTable.CategoryViews.Constants.DividerLabel})
      table.insert(elements, source)
    end
    if source:match("^_") then
      local name
      if source == addonTable.CategoryViews.Constants.SectionEnd then
        indent = ""
        name = " "
      else
        indent = "      "
        local section = source:match("^_(.*)")
        name = CreateAtlasMarkup("AnimCreate_Icon_Folder") .. " " .. (_G["BAGANATOR_L_SECTION_" .. section] or section)
      end
      table.insert(dataProviderElements, {value = source, label = name})
      table.insert(elements, source)
    end
  end

  if container.dataProviderElements and tCompare(dataProviderElements, container.dataProviderElements, 4) then
    return
  end

  container.elements = elements
  container.dataProviderElements = dataProviderElements
  container.ScrollBox:SetDataProvider(CreateDataProvider(dataProviderElements), true)
end

local function GetCategoryContainer(parent, pickupCallback)
  local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  addonTable.Skins.AddFrame("InsetFrame", container)
  container.ScrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  container.ScrollBox:SetPoint("TOPLEFT", 1, -3)
  container.ScrollBox:SetPoint("BOTTOMRIGHT", -1, 3)
  local scrollView = CreateScrollBoxListLinearView()
  scrollView:SetElementExtentCalculator(function(index, elementData)
    if elementData.value ~= addonTable.CategoryViews.Constants.SectionEnd then
      return 20
    else
      return 8
    end
  end)
  scrollView:SetElementInitializer("Button", function(frame, elementData)
    if not frame.initialized then
      frame.initialized = true
      frame:SetNormalFontObject(GameFontHighlight)
      frame:SetHighlightAtlas("auctionhouse-ui-row-highlight")
      frame:SetScript("OnClick", function(self, button)
        if self.value:match("^_") then
          addonTable.CallbackRegistry:TriggerEvent("EditCategorySection", self.value)
        elseif self.value == "default_auto_recents" then
          addonTable.CallbackRegistry:TriggerEvent("EditCategoryRecent")
        elseif self.value == addonTable.CategoryViews.Constants.EmptySlotsCategory then
          addonTable.CallbackRegistry:TriggerEvent("EditCategoryEmpty")
        elseif self.value == addonTable.CategoryViews.Constants.DividerName then
          addonTable.CallbackRegistry:TriggerEvent("EditCategoryDivider", frame.indexValue)
        else
          addonTable.CallbackRegistry:TriggerEvent("EditCategory", self.value)
        end
      end)
      local button = CreateFrame("Button", nil, frame)
      button:SetSize(28, 22)
      local tex = button:CreateTexture(nil, "ARTWORK")
      tex:SetTexture("Interface\\PaperDollInfoFrame\\statsortarrows")
      tex:SetPoint("LEFT", 4, 0)
      tex:SetSize(14, 14)
      button:SetAlpha(0.8)
      button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT", -16, 0)
        GameTooltip:SetText(BAGANATOR_L_MOVE)
        GameTooltip:Show()
        button:SetAlpha(0.4)
      end)
      button:SetScript("OnLeave", function()
        GameTooltip:Hide()
        button:SetAlpha(0.8)
      end)
      button:SetScript("OnClick", function(self)
        pickupCallback(self:GetParent().value, self:GetParent():GetText(), self:GetParent().indexValue)
      end)
      button:SetPoint("LEFT", 4, 1)

      frame.repositionButton = button
    end
    frame.indexValue = container.ScrollBox:GetDataProvider():FindIndex(elementData)
    frame.value = elementData.value
    frame:SetText(elementData.label)
    frame:GetFontString():SetPoint("RIGHT", -8, 0)
    frame:GetFontString():SetPoint("LEFT", 40, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    local default = addonTable.CategoryViews.Constants.SourceToCategory[frame.value]
    local categoryEnd = frame.value == addonTable.CategoryViews.Constants.SectionEnd
    frame:SetEnabled(not categoryEnd)
    frame.repositionButton:SetShown(not categoryEnd)
  end)
  container.ScrollBar = CreateFrame("EventFrame", nil, container, "WowTrimScrollBar")
  container.ScrollBar:SetPoint("TOPRIGHT")
  container.ScrollBar:SetPoint("BOTTOMRIGHT")
  ScrollUtil.InitScrollBoxListWithScrollBar(container.ScrollBox, container.ScrollBar, scrollView)
  addonTable.Skins.AddFrame("TrimScrollBar", container.ScrollBar)

  container:SetSize(250, 600)

  PopulateCategoryOrder(container)

  return container
end

local function GetInsertedCategories()
  local result = {}
  for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    result[source] = true
  end
  return result
end

local function SetCategoriesToDropDown(dropDown, ignore)
  local options = {}
  for source, category in pairs(addonTable.CategoryViews.Constants.SourceToCategory) do
    if not ignore[source] then
      table.insert(options, {label = category.name, value = source})
    end
  end
  local nameCount = {}
  for source, category in pairs(addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)) do
    if not ignore[source] then
      if not nameCount[category.name] then
        table.insert(options, {label = category.name .. " (*)", value = source})
        nameCount[category.name] = 1
      else
        nameCount[category.name] = nameCount[category.name] + 1
        table.insert(options, {label = category.name .. " (*" .. nameCount[category.name] .. ")", value = source})
      end
    end
  end
  table.sort(options, function(a, b) return a.label:lower() < b.label:lower() end)

  local entries, values = {
    NORMAL_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_CREATE_NEW_CATEGORY),
    NORMAL_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_CREATE_NEW_SECTION),
    NORMAL_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_CREATE_NEW_DIVIDER),
  }, {
    "",
    "_",
    addonTable.CategoryViews.Constants.DividerName,
  }

  for _, opt in ipairs(options) do
    table.insert(entries, opt.label)
    table.insert(values, opt.value)
  end

  dropDown:SetupOptions(entries, values)
end

function addonTable.CustomiseDialog.GetCategoriesOrganiser(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(300, 670)
  container:SetPoint("CENTER")

  local previousOrder = CopyTable(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER))

  container:SetScript("OnShow", function()
    previousOrder = CopyTable(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER))
  end)

  local categoryOrder
  local highlightContainer = CreateFrame("Frame", nil, container)
  local highlight = highlightContainer:CreateTexture(nil, "OVERLAY", nil, 7)
  highlight:SetSize(200, 20)
  highlight:SetAtlas("128-RedButton-Highlight")
  highlight:Hide()
  local draggable
  draggable = addonTable.CustomiseDialog.GetDraggable(function()
    if categoryOrder:IsMouseOver() then
      local f, isTop, index = addonTable.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      local insertIndex = #categoryOrder.elements
      if f then
        if isTop then
          insertIndex = index
        else
          insertIndex = index + 1
        end
      end

      if draggable.value:match("^_") or draggable.value == addonTable.CategoryViews.Constants.DividerName then
        for i = insertIndex, #categoryOrder.elements do
          local element = categoryOrder.elements[i]
          if element == addonTable.CategoryViews.Constants.SectionEnd then
            insertIndex = i + 1
            break
          elseif element:match("^_") then
            break
          end
        end
      end

      if draggable.value:match("^_") then
        table.insert(categoryOrder.elements, insertIndex, draggable.value)
        for _, value in ipairs(draggable.sectionValues) do
          insertIndex = insertIndex + 1
          table.insert(categoryOrder.elements, insertIndex, value)
        end
      else
        table.insert(categoryOrder.elements, insertIndex, draggable.value)
      end
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end
    highlight:Hide()
  end, function()
    highlight:ClearAllPoints()
    highlight:Hide()
    if categoryOrder:IsMouseOver() then
      highlight:Show()
      local f, isTop = addonTable.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if f and isTop then
        highlight:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, -10)
      elseif f then
        highlight:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 10)
      else
        highlight:SetPoint("BOTTOMLEFT", categoryOrder, 0, 0)
      end
    end
  end)

  local dropDown = addonTable.CustomiseDialog.GetDropdown(container)
  SetCategoriesToDropDown(dropDown, GetInsertedCategories())

  local function Pickup(value, label, index)
    draggable.value = value
    draggable.sectionValues = {}
    if index ~= nil then
      table.remove(categoryOrder.elements, index)
      if value:match("^_") then -- section
        local tmp
        while tmp ~= addonTable.CategoryViews.Constants.SectionEnd do
          tmp = categoryOrder.elements[index]
          table.insert(draggable.sectionValues, tmp)
          table.remove(categoryOrder.elements, index)
        end
      end
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end

    dropDown:SetText(label)
    draggable:Show()
    draggable.text:SetText(label)
  end

  categoryOrder = GetCategoryContainer(container, Pickup)
  categoryOrder:SetPoint("TOPLEFT", 0, -40)

  dropDown:SetText(BAGANATOR_L_INSERT_OR_CREATE)

  hooksecurefunc(dropDown, "OnEntryClicked", function(_, option)
    if option.value == "_" then
      addonTable.CallbackRegistry:TriggerEvent("EditCategorySection", option.value)
    elseif option.value == addonTable.CategoryViews.Constants.DividerName then
      Pickup(option.value, addonTable.CategoryViews.Constants.DividerLabel, nil)
    elseif option.value ~= "" then
      Pickup(option.value, option.label, tIndexOf(categoryOrder.elements, option.value))
    else
      addonTable.CallbackRegistry:TriggerEvent("EditCategory", option.value)
    end
  end)
  draggable:SetScript("OnHide", function()
    dropDown:SetText(BAGANATOR_L_INSERT_OR_CREATE)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    for _, source in ipairs(addonTable.CategoryViews.Constants.ProtectedCategories) do
      if tIndexOf(displayOrder, source) == nil then
        table.insert(displayOrder, source)
        addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
      end
    end
  end)
  dropDown:SetPoint("TOPLEFT", 0, 0)
  dropDown:SetPoint("RIGHT", categoryOrder)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CATEGORY_DISPLAY_ORDER or settingName == addonTable.Config.Options.CATEGORY_HIDDEN or settingName == addonTable.Config.Options.CUSTOM_CATEGORIES then
      SetCategoriesToDropDown(dropDown, GetInsertedCategories())
      PopulateCategoryOrder(categoryOrder)
    end
  end)

  local exportButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  exportButton:SetPoint("RIGHT", categoryOrder, 0, 0)
  exportButton:SetPoint("BOTTOM", container)
  exportButton:SetText(BAGANATOR_L_EXPORT)
  DynamicResizeButton_Resize(exportButton)
  exportButton:SetScript("OnClick", function()
    StaticPopup_Show(exportDialog, nil, nil, addonTable.CustomiseDialog.CategoriesExport())
  end)
  addonTable.Skins.AddFrame("Button", exportButton)

  local importButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  importButton:SetPoint("LEFT", categoryOrder, 0, 0)
  importButton:SetPoint("BOTTOM", container)
  importButton:SetText(BAGANATOR_L_IMPORT)
  DynamicResizeButton_Resize(importButton)
  importButton:SetScript("OnClick", function()
    StaticPopup_Show(importDialog)
  end)
  addonTable.Skins.AddFrame("Button", importButton)

  return container
end
