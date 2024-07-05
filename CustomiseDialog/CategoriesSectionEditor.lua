BaganatorCustomiseDialogCategoriesSectionEditorMixin = {}

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:OnLoad()
  local function Save()
    if self.SectionName:GetText() == "" then
      return
    end

    local newValue = "_" .. self.SectionName:GetText():gsub("_", " ")

    local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)

    local oldIndex = tIndexOf(displayOrder, self.currentSection)
    if oldIndex then
      self.currentSection = newValue
      displayOrder[oldIndex] = newValue
    else
      table.insert(displayOrder, 1, newValue)
      table.insert(displayOrder, 2, Baganator.CategoryViews.Constants.SectionEnd)
    end
    Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
  end

  Baganator.CallbackRegistry:RegisterCallback("EditCategorySection", function(_, value)
    self:Show()
    if value == "_" then
      self.currentSection = "_" .. BAGANATOR_L_NEW_SECTION
      self.SectionName:SetText(BAGANATOR_L_NEW_SECTION)
      Save()
    else
      self.currentSection = value
      self.SectionName:SetText((value:match("^_(.*)")))
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if not self:IsVisible() then
      return
    end

    if settingName == Baganator.Config.Options.CATEGORY_DISPLAY_ORDER then
      local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)
      if not tIndexOf(displayOrder, self.currentSection) then
        self:Hide()
      end
    end
  end)

  self.SectionName:SetScript("OnEditFocusLost", Save)
  self.SectionName:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      Save()
    end
  end)

  Baganator.Skins.AddFrame("EditBox", self.SectionName)
end

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:Disable()
  self.SectionName:SetText("")
end

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:OnHide()
  self:Disable()
end
