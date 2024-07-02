BaganatorCustomiseDialogCategoriesEditorMixin = {}

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
  self.currentCategory = ""

  Baganator.CallbackRegistry:RegisterCallback("EditCategory", function(_, value)
    self.currentCategory = value
    if value == "" then
      self.CategoryName:SetText(BAGANATOR_L_NEW_CATEGORY)
      self.CategorySearch:SetText("")
      self.PrioritySlider:SetValue(0)
    else
      local category = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)[value]
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
  self.PrioritySlider:SetPoint("TOP", 0, -90)
  self.PrioritySlider:SetValue(0)

  self.ApplyChangesButton:SetScript("OnClick", function()
    if self.CategoryName:GetText() == "" then
      return
    end

    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
    local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)
    local oldMods, oldIndex
    local isNew = self.currentCategory == ""
    if not isNew then
      oldIndex = tIndexOf(displayOrder, self.currentCategory)
      customCategories[self.currentCategory] = nil
      oldMods = categoryMods[self.currentCategory]
      categoryMods[self.currentCategory] = nil
    end
    local newName = self.CategoryName:GetText():gsub("_", " ")

    customCategories[newName] = {
      name = newName,
      search = self.CategorySearch:GetText(),
      searchPriority = PRIORITY_MAP[self.PrioritySlider:GetValue()],
    }
    categoryMods[newName] = oldMods

    self.currentCategory = newName
    self.CategoryName:SetText(newName)

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
  self.CategoryName:SetText("")
  self.CategorySearch:SetText("")
  self.PrioritySlider:SetValue(0)
  self.currentCategory = ""
end
