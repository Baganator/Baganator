local _, addonTable = ...
BaganatorCustomiseDialogCategoriesEditorMixin = {}

local PRIORITY_LIST = {
  220,
  250,
  300,
  350,
  400,
}

local groupingToLabel = {
  ["expansion"] = BAGANATOR_L_EXPANSION,
  ["slot"] = BAGANATOR_L_SLOT,
  ["type"] = BAGANATOR_L_TYPE,
  ["quality"] = BAGANATOR_L_QUALITY,
}

local PRIORITY_MAP = {}

local priorityOffset = -2
for index, value in ipairs(PRIORITY_LIST) do
  PRIORITY_MAP[index + priorityOffset] = value
end

local disabledAlpha = 0.5

function BaganatorCustomiseDialogCategoriesEditorMixin:OnLoad()
  self.currentCategory = ""

  self.HelpButton:SetScript("OnClick", function()
    addonTable.Help.ShowSearchDialog()
  end)

  local function Save()
    if self.CategoryName:GetText() == "" then
      return
    end

    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    local oldMods, oldIndex
    local isNew, isDefault = self.currentCategory == "", customCategories[self.currentCategory] == nil
    if not isNew and not isDefault then
      oldIndex = tIndexOf(displayOrder, self.currentCategory)
      customCategories[self.currentCategory] = nil
      oldMods = categoryMods[self.currentCategory]
      categoryMods[self.currentCategory] = nil
    end

    local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
    local oldHidden = hidden[self.currentCategory]
    if isNew or not isDefault then
      local newName = self.CategoryName:GetText():gsub("_", " ")

      local isNewName = newName ~= self.currentCategory

      if isNewName then
        -- Check for an existing entry to an existing category with the same name
        local existingIndex = tIndexOf(displayOrder, newName)
        if existingIndex ~= nil then
          table.remove(displayOrder, existingIndex)
        end
      end

      customCategories[newName] = {
        name = newName,
        search = self.CategorySearch:GetText(),
        searchPriority = PRIORITY_MAP[self.PrioritySlider:GetValue()],
      }
      categoryMods[newName] = oldMods

      hidden[newName] = self.HiddenCheckBox:GetChecked()

      self.currentCategory = newName
      self.CategoryName:SetText(newName)

      if oldIndex then
        displayOrder[oldIndex] = self.currentCategory
      elseif isNew and tIndexOf(displayOrder, self.currentCategory) == nil then
        table.insert(displayOrder, 1, self.currentCategory)
      end
      if isNewName then
        addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
      end
    else
      hidden[self.currentCategory] = self.HiddenCheckBox:GetChecked()
    end

    if hidden[self.currentCategory] ~= oldHidden then
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
    end

    addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))
  end

  local function SetState(value)
    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    self.currentCategory = value

    for _, region in ipairs(self.ChangeAlpha) do
      region:SetAlpha(1)
    end
    self.Blocker:SetPoint("TOPLEFT", self.CategoryName)
    self.Blocker:SetPoint("BOTTOMRIGHT", self.CategorySearch)

    if value == "" then
      self.CategoryName:SetText(BAGANATOR_L_NEW_CATEGORY)
      self.CategorySearch:SetText("")
      self.PrioritySlider:SetValue(0)
      self.GroupDropDown:SetText(BAGANATOR_L_NONE)
      self.HiddenCheckBox:SetChecked(false)
      self.PrioritySlider:Enable()
      self.Blocker:Hide()
      self.DeleteButton:Enable()
      self.ExportButton:Enable()
      Save()
      return
    end

    local category
    if customCategories[value] then
      category = customCategories[value]
      self.PrioritySlider:Enable()
      self.Blocker:Hide()
      self.DeleteButton:Enable()
      self.ExportButton:Enable()
    else
      category = addonTable.CategoryViews.Constants.SourceToCategory[value]
      self.CategoryName:SetAlpha(disabledAlpha)
      self.CategorySearch:SetAlpha(disabledAlpha)
      self.HelpButton:SetAlpha(disabledAlpha)
      self.PrioritySlider:SetAlpha(disabledAlpha)
      self.PrioritySlider:Disable()
      self.Blocker:Show()
      self.DeleteButton:Disable()
      self.ExportButton:Disable()
    end
    self.HiddenCheckBox:SetChecked(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)[value])

    self.CategoryName:SetText(category.name)
    self.CategorySearch:SetText(category.search or "")
    if category.searchPriority < PRIORITY_LIST[1] then
      self.PrioritySlider:SetValue(-1)
    else
      for index, value in ipairs(PRIORITY_LIST) do
        if category.searchPriority < value then
          self.PrioritySlider:SetValue(index - 1 + priorityOffset)
          break
        end
      end
    end

    if value ~= addonTable.CategoryViews.Constants.EmptySlotsCategory then
      self.GroupDropDown:Enable()
      local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
      if categoryMods[value] and categoryMods[value].group then
        self.GroupDropDown:SetText(groupingToLabel[categoryMods[value].group])
      else
        self.GroupDropDown:SetText(BAGANATOR_L_NONE)
      end
    else
      self.GroupDropDown:SetAlpha(disabledAlpha)
      self.GroupDropDown:Disable()
    end
  end

  addonTable.CallbackRegistry:RegisterCallback("EditCategory", function(_, value)
    self:Show()
    SetState(value)
  end)

  local checkBoxWrapper = CreateFrame("Frame", nil, self)
  checkBoxWrapper:SetHeight(40)
  checkBoxWrapper:SetPoint("LEFT")
  checkBoxWrapper:SetPoint("RIGHT")
  checkBoxWrapper:SetPoint("BOTTOM", 0, 30)
  checkBoxWrapper:SetScript("OnEnter", function() self.HiddenCheckBox:OnEnter() end)
  checkBoxWrapper:SetScript("OnLeave", function() self.HiddenCheckBox:OnLeave() end)
  checkBoxWrapper:SetScript("OnMouseUp", function() self.HiddenCheckBox:Click() end)
  if DoesTemplateExist("SettingsCheckBoxTemplate") then
    self.HiddenCheckBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckBoxTemplate")
  else
    self.HiddenCheckBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckboxTemplate")
  end
  self.HiddenCheckBox:SetPoint("LEFT", checkBoxWrapper, "CENTER", 0, 0)
  self.HiddenCheckBox:SetText(BAGANATOR_L_HIDDEN)
  self.HiddenCheckBox:SetNormalFontObject(GameFontHighlight)
  self.HiddenCheckBox:GetFontString():SetPoint("RIGHT", checkBoxWrapper, "CENTER", -20, 0)
  addonTable.Skins.AddFrame("CheckBox", self.HiddenCheckBox)

  table.insert(self.ChangeAlpha, self.HiddenCheckBox)

  self.PrioritySlider = CreateFrame("Frame", nil, self, "BaganatorPrioritySliderTemplate")
  self.PrioritySlider:Init({text = BAGANATOR_L_PRIORITY, callback = Save})
  self.PrioritySlider:SetPoint("LEFT")
  self.PrioritySlider:SetPoint("RIGHT")
  self.PrioritySlider:SetPoint("TOP", 0, -160)
  self.PrioritySlider:SetValue(0)
  table.insert(self.ChangeAlpha, self.PrioritySlider)

  self.GroupDropDown = addonTable.CustomiseDialog.GetDropdown(self)
  self.GroupDropDown:SetupOptions({
    BAGANATOR_L_NONE,
    BAGANATOR_L_EXPANSION,
    BAGANATOR_L_TYPE,
    BAGANATOR_L_SLOT,
    BAGANATOR_L_QUALITY,
  }, {
    "",
    "expansion",
    "type",
    "slot",
    "quality",
  })
  hooksecurefunc(self.GroupDropDown, "OnEntryClicked", function(_, option)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    if not categoryMods[self.currentCategory] then
      categoryMods[self.currentCategory] = {}
    end
    if option.value == "" then
      categoryMods[self.currentCategory].group = nil
    else
      categoryMods[self.currentCategory].group = option.value
    end
    self.GroupDropDown:SetText(option.label)
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
  end)
  self.GroupDropDown:SetPoint("TOP", 0, -120)
  self.GroupDropDown:SetPoint("LEFT", 5, 0)
  self.GroupDropDown:SetPoint("RIGHT")
  table.insert(self.ChangeAlpha, self.GroupDropDown)

  self.Blocker = CreateFrame("Frame", nil, self)
  self.Blocker:EnableMouse(true)
  self.Blocker:SetScript("OnMouseWheel", function() end)
  self.Blocker:SetPoint("TOPLEFT", self.CategoryName)
  self.Blocker:SetFrameStrata("DIALOG")

  self.CategoryName:SetScript("OnEditFocusLost", Save)
  self.CategorySearch:SetScript("OnEditFocusLost", Save)
  self.HiddenCheckBox:SetScript("OnClick", Save)

  self.CategoryName:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      Save()
    elseif key == "TAB" then
      self.CategoryName:ClearHighlightText()
      self.CategorySearch:SetFocus()
    end
  end)
  self.CategorySearch:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      Save()
    elseif key == "TAB" then
      self.CategorySearch:ClearHighlightText()
      self.CategoryName:SetFocus()
    end
  end)

  self.ExportButton:SetScript("OnClick", function()
    if self.currentCategory == "" then
      return
    end

    StaticPopup_Show("Baganator_Export_Dialog", nil, nil, addonTable.CustomiseDialog.SingleCategoryExport(self.currentCategory))
  end)

  self.DeleteButton:SetScript("OnClick", function()
    if self.currentCategory == "" then
      return
    end

    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    local oldIndex = tIndexOf(displayOrder, self.currentCategory)
    if oldIndex then
      table.remove(displayOrder, oldIndex)
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
    end

    customCategories[self.currentCategory] = nil
    addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))

    self:OnHide()
  end)
  addonTable.Skins.AddFrame("Button", self.DeleteButton)
  addonTable.Skins.AddFrame("EditBox", self.CategoryName)
  addonTable.Skins.AddFrame("EditBox", self.CategorySearch)

  self:Disable()
end

function BaganatorCustomiseDialogCategoriesEditorMixin:Disable()
  self.CategoryName:SetText("")
  self.CategorySearch:SetText("")
  self.PrioritySlider:SetValue(0)
  self.GroupDropDown:SetText(BAGANATOR_L_NONE)
  self.HiddenCheckBox:SetChecked(false)
  self.currentCategory = ""
  self.DeleteButton:Disable()
  self.ExportButton:Disable()
  for _, region in ipairs(self.ChangeAlpha) do
    region:SetAlpha(disabledAlpha)
  end
  self.Blocker:Show()
  self.Blocker:SetPoint("TOPLEFT")
  self.Blocker:SetPoint("BOTTOMRIGHT")
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnHide()
  self:Disable()
end
