BaganatorCustomiseDialogCategoriesEditorMixin = {}

local function SetCategoriesToDropDown(dropDown)
  local options = {}
  for source, category in pairs(Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)) do
    table.insert(options, {label = category.name, value = category.name})
  end
  table.sort(options, function(a, b) return a.label < b.label end)

  local entries, values = {BAGANATOR_L_CREATE_NEW_CATEGORY}, {""}

  for _, opt in ipairs(options) do
    table.insert(entries, opt.label)
    table.insert(values, opt.value)
  end

  dropDown:SetupOptions(entries, values)
end

local PRIORITY_LIST = {
  220,
  250,
  300,
  350,
  400,
}

local PRIORITY_MAP = {
  [-1] = 220,
  [0] = 250,
  [1] = 300,
  [2] = 350,
  [3] = 400,
}

local priorityOffset = -2
for index, value in ipairs(PRIORITY_LIST) do
  PRIORITY_MAP[index + priorityOffset] = value
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnLoad()
  self.DropDown = Baganator.CustomiseDialog.GetDropdown(self)
  self.DropDown:SetPoint("TOPRIGHT", -10, 0)
  self.DropDown:SetPoint("LEFT", 15, 0)
  self.DropDown:SetText(BAGANATOR_L_CREATE_OR_EDIT)
  self.currentCategory = ""
  SetCategoriesToDropDown(self.DropDown)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == Baganator.Config.Options.CUSTOM_CATEGORIES then
      SetCategoriesToDropDown(self.DropDown)
    end
  end)

  hooksecurefunc(self.DropDown, "OnEntryClicked", function(_, option)
    self.currentCategory = option.value
    if option.value == "" then
      self.CategoryName:SetText(BAGANATOR_L_NEW_CATEGORY)
      self.CategorySearch:SetText("")
      self.PrioritySlider:SetValue(0)
      self.DropDown:SetText(BAGANATOR_L_CREATE_NEW_CATEGORY)
    else
      local category = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)[option.value]
      self.DropDown:SetText(category.name)
      self.CategoryName:SetText(category.name)
      self.CategorySearch:SetText(category.search)
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
    end
  end)

  self.PrioritySlider = CreateFrame("Frame", nil, self, "BaganatorPrioritySliderTemplate")
  self.PrioritySlider:Init({valuePattern = BAGANATOR_L_X_SEARCH_PRIORITY})
  self.PrioritySlider:SetPoint("LEFT")
  self.PrioritySlider:SetPoint("RIGHT")
  self.PrioritySlider:SetPoint("TOP", 0, -130)
  self.PrioritySlider:SetValue(0)

  self.ApplyChangesButton:SetScript("OnClick", function()
    if self.CategoryName:GetText() == "" then
      return
    end

    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)
    local oldAddedItems, oldIndex
    local isNew = self.currentCategory == ""
    if not isNew then
      oldIndex = tIndexOf(displayOrder, self.currentCategory)
      oldAddedItems = customCategories[self.currentCategory].addedItems
      customCategories[self.currentCategory] = nil
    end

    customCategories[self.CategoryName:GetText()] = {
      name = self.CategoryName:GetText(),
      search = self.CategorySearch:GetText(),
      searchPriority = PRIORITY_MAP[self.PrioritySlider:GetValue()],
      addedItems = oldAddedItems
    }

    self.currentCategory = self.CategoryName:GetText()
    self.DropDown:SetText(self.currentCategory)

    Baganator.Config.Set(Baganator.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))

    if oldIndex then
      displayOrder[oldIndex] = self.currentCategory
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
    elseif isNew then
      table.insert(displayOrder, 1, self.currentCategory)
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
    end
  end)
  Baganator.Skins.AddFrame("Button", self.ApplyChangesButton)

  self.DeleteButton:SetScript("OnClick", function()
    if self.currentCategory == "" then
      return
    end

    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)

    local oldIndex = tIndexOf(displayOrder, self.currentCategory)
    if oldIndex then
      table.remove(displayOrder, oldIndex)
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
    end

    customCategories[self.currentCategory] = nil
    Baganator.Config.Set(Baganator.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))

    self:OnHide()
  end)
  Baganator.Skins.AddFrame("Button", self.DeleteButton)
  Baganator.Skins.AddFrame("EditBox", self.CategoryName)
  Baganator.Skins.AddFrame("EditBox", self.CategorySearch)
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnHide()
  self.DropDown:SetText(BAGANATOR_L_CREATE_OR_EDIT)
  self.CategoryName:SetText("")
  self.CategorySearch:SetText("")
  self.PrioritySlider:SetValue(0)
  self.currentCategory = ""
end
