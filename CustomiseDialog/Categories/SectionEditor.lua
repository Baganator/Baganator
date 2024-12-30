local _, addonTable = ...
BaganatorCustomiseDialogCategoriesSectionEditorMixin = {}

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:OnLoad()
  local function RemoveSection(name)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    if self.currentSectionIndex then
      table.remove(displayOrder, self.currentSectionIndex)
      local level = 0
      for i = 1, #displayOrder do
        if displayOrder[i] == addonTable.CategoryViews.Constants.SectionEnd then
          if level == 0 then
            table.remove(displayOrder, i)
            break
          else
            level = level - 1
          end
        elseif displayOrder[i]:match("^_") then
          level = level + 1
        end
      end
    end
  end

  local function Save()
    if self.SectionName:GetText() == "" then
      return
    end

    local newValue = "_" .. self.SectionName:GetText():gsub("_", " ")

    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    if self.currentSectionIndex then
      self.currentSection = newValue
      displayOrder[self.currentSectionIndex] = newValue
    else
      self.currentSectionIndex = 1
      table.insert(displayOrder, self.currentSectionIndex, newValue)
      table.insert(displayOrder, self.currentSectionIndex + 1, addonTable.CategoryViews.Constants.SectionEnd)
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
  end

  self.DeleteButton:SetScript("OnClick", function()
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    RemoveSection(self.currentSection)

    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
  end)

  addonTable.CallbackRegistry:RegisterCallback("EditCategorySection", function(_, value, index)
    if value == "_" then
      self.currentSection = "_" .. BAGANATOR_L_NEW_SECTION
      self.currentSectionIndex = nil
      self.SectionName:SetText(BAGANATOR_L_NEW_SECTION)
      Save()
    else
      self.currentSection = value
      self.currentSectionIndex = index
      local section = value:match("^_(.*)")
      self.SectionName:SetText(_G["BAGANATOR_L_SECTION_" .. section] or section)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if not self:IsVisible() then
      return
    end

    if settingName == addonTable.Config.Options.CATEGORY_DISPLAY_ORDER then
      local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
      if displayOrder[self.currentSectionIndex] ~= self.currentSection then
        self:Return()
      end
    end
  end)

  self.SectionName:SetScript("OnEditFocusLost", Save)
  self.SectionName:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      Save()
    end
  end)

  addonTable.Skins.AddFrame("EditBox", self.SectionName)
  addonTable.Skins.AddFrame("Button", self.DeleteButton)
end

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:Disable()
  self.SectionName:SetText("")
end

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:OnHide()
  self:Disable()
end
