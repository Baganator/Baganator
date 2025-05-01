---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorCustomiseDialogCategoriesSectionEditorMixin = {}

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:OnLoad()
  local function RemoveSection(name)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)

    if sections[self.currentSection] then
      sections[self.currentSection] = nil
      table.remove(displayOrder, tIndexOf(displayOrder, "_" .. self.currentSection))
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

    local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    local isNew = false

    local refreshState = {}
    if sections[self.currentSection] then
      if sections[self.currentSection].name ~= self.SectionName:GetText() then
        refreshState[addonTable.Constants.RefreshReason.Searches] = true
      end
      sections[self.currentSection].name = self.SectionName:GetText()
    else
      isNew = true
      self.currentSection = tostring(1)
      while sections[self.currentSection] do
        self.currentSection = tostring(tonumber(self.currentSection) + 1)
      end
      sections[self.currentSection] = {name = self.SectionName:GetText()}
      table.insert(displayOrder, 1, "_" .. self.currentSection)
      table.insert(displayOrder, 2, addonTable.CategoryViews.Constants.SectionEnd)
      refreshState[addonTable.Constants.RefreshReason.Searches] = true
      refreshState[addonTable.Constants.RefreshReason.Layout] = true
    end
    if self.SectionColorSwatch.pendingColor then
      local c = self.SectionColorSwatch.pendingColor
      local oldColor = sections[self.currentSection].color
      if c.r == 1 and c.g == 1 and c.b == 1 then
        sections[self.currentSection].color = nil
      else
        sections[self.currentSection].color = c:GenerateHexColorNoAlpha()
      end
      if oldColor ~= sections[self.currentSection].color then
        refreshState[addonTable.Constants.RefreshReason.Cosmetic] = true
      end
    end

    if next(refreshState) ~= nil then
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
    end
    if isNew then
      addonTable.CallbackRegistry:TriggerEvent("SetSelectedCategory", "_" .. self.currentSection)
    end
  end

  self.DeleteButton:SetScript("OnClick", function()
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    RemoveSection(self.currentSection)

    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
  end)

  self.SectionColorSwatch = addonTable.CustomiseDialog.GetColorSwatch(self, self.NameLabel, Save)
  table.insert(self.ChangeAlpha, self.SectionColorSwatch)

  addonTable.CallbackRegistry:RegisterCallback("EditCategorySection", function(_, value)
    if not self:GetParent():IsVisible() then
      return
    end
    self.SectionColorSwatch.pendingColor = nil
    if value == "" then
      self.currentSection = "-1"
      self.SectionName:SetText(addonTable.Locales.NEW_SECTION)

      self.SectionColorSwatch.currentColor = CreateColor(1, 1, 1)
      self.SectionColorSwatch:SetColorRGB(self.SectionColorSwatch.currentColor:GetRGBA())

      Save()
    else
      self.currentSection = value
      local sectionDetails = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)[value]
      self.SectionName:SetText(addonTable.Locales["SECTION_" .. sectionDetails.name] or sectionDetails.name)

      if sectionDetails.color then
        self.SectionColorSwatch.currentColor = CreateColorFromRGBAHexString(sectionDetails.color .. "ff")
      else
        self.SectionColorSwatch.currentColor = CreateColor(1, 1, 1)
      end
      self.SectionColorSwatch:SetColorRGB(self.SectionColorSwatch.currentColor:GetRGBA())
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if not self:IsVisible() then
      return
    end

    if settingName == addonTable.Config.Options.CATEGORY_DISPLAY_ORDER then
      local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
      if sections[self.currentSection] == nil then
        self:Disable() -- Necessary to work around edit box not losing focus in classic era
        self:Return()
      end
    end
  end)

  local colorPickerFrameMonitor = CreateFrame("Frame")
  colorPickerFrameMonitor.OnUpdate = function()
    if not ColorPickerFrame:IsVisible() then
      colorPickerFrameMonitor:SetScript("OnUpdate", nil)
    end
    if colorPickerFrameMonitor.changed then
      Save()
    end
    colorPickerFrameMonitor.changed = false
  end

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
  self.SectionColorSwatch:SetColorRGB(1, 1, 1)
  self.SectionName:SetText("")
end

function BaganatorCustomiseDialogCategoriesSectionEditorMixin:OnHide()
  self:Disable()
end
