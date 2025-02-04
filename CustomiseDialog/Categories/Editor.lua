local _, addonTable = ...
BaganatorCustomiseDialogCategoriesEditorMixin = {}

local groupingToLabel = {
  ["expansion"] = BAGANATOR_L_EXPANSION,
  ["slot"] = BAGANATOR_L_SLOT,
  ["type"] = BAGANATOR_L_TYPE,
  ["quality"] = BAGANATOR_L_QUALITY,
}

local disabledAlpha = 0.5

local function GetCheckBox(self)
  local checkBoxWrapper = CreateFrame("Frame", nil, self)
  checkBoxWrapper:SetHeight(40)
  checkBoxWrapper:SetPoint("LEFT")
  checkBoxWrapper:SetPoint("RIGHT")
  local checkBox
  if DoesTemplateExist("SettingsCheckBoxTemplate") then
    checkBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckBoxTemplate")
  else
    checkBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckboxTemplate")
  end
  checkBoxWrapper:SetScript("OnEnter", function() checkBox:OnEnter() end)
  checkBoxWrapper:SetScript("OnLeave", function() checkBox:OnLeave() end)
  checkBoxWrapper:SetScript("OnMouseUp", function() checkBox:Click() end)
  checkBox:SetPoint("LEFT", checkBoxWrapper, "CENTER", 0, 0)
  checkBox:SetText(" ")
  checkBox:SetNormalFontObject(GameFontHighlight)
  checkBox:GetFontString():SetPoint("RIGHT", checkBoxWrapper, "CENTER", -20, 0)
  addonTable.Skins.AddFrame("CheckBox", checkBox)

  checkBoxWrapper.checkBox = checkBox
  return checkBoxWrapper
end

local function GetVisualSearch(parent)
  local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBox")
  local view = CreateScrollBoxLinearView()
  view:SetHorizontal(true)
  local CategorySearch = Syndicator.Search.GetSearchBuilder(scrollBox)
  CategorySearch:RegisterCallback("OnSkin", function(_, regionType, region, tags)
    addonTable.Skins.AddFrame(regionType, region, tags)
  end)
  CategorySearch:RegisterCallback("OnResize", function()
    scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
  end)
  CategorySearch.scrollable = true
  CategorySearch:SetPoint("TOPLEFT")
  CategorySearch:SetHeight(30)
  scrollBox:SetPoint("TOPLEFT", 20, -65)
  scrollBox:SetPoint("RIGHT", -10, 0)
  scrollBox:SetHeight(30)
  scrollBox:Init(view)
  do
    local function Scroll(frame, direction)
      local elapsed = 0
      local delay = 0.1
      local stepCount = 0
      frame:SetScript("OnUpdate", function(tbl, dt)
        elapsed = elapsed + dt
        if elapsed > delay then
          elapsed = 0

          local visibleExtentPercentage = scrollBox:GetVisibleExtentPercentage();
          if visibleExtentPercentage > 0 then
            local pages = 1 / visibleExtentPercentage;
            local magnitude = .8;
            local span = pages - 1;
            if span > 0 then
              scrollBox:ScrollInDirection((1 / span) * magnitude, direction)
            end
          end
        end
      end)
    end
    local leftButton = CreateFrame("Button", nil, parent)
    leftButton:SetSize(9, 15)
    leftButton:SetPoint("RIGHT", scrollBox, "LEFT", -5, 0)
    leftButton:SetScript("OnEnter", function()
      leftButton:SetAlpha(1)
    end)
    leftButton:SetScript("OnLeave", function()
      leftButton:SetAlpha(0.8)
    end)
    leftButton:SetAlpha(0.8)
    leftButton:SetScript("OnMouseDown", function()
      Scroll(leftButton, ScrollControllerMixin.Directions.Decrease)
    end)
    leftButton:SetScript("OnMouseUp", function()
      leftButton:SetScript("OnUpdate", nil)
    end)
    leftButton:SetScript("OnHide", function()
      leftButton:SetScript("OnUpdate", nil)
    end)
    leftButton:SetNormalAtlas("Minimal_SliderBar_Button_Left")
    local rightButton = CreateFrame("Button", nil, parent)
    rightButton:SetSize(9, 15)
    rightButton:SetPoint("LEFT", scrollBox, "RIGHT", 5, 0)
    rightButton:SetScript("OnMouseDown", function()
      Scroll(rightButton, ScrollControllerMixin.Directions.Increase)
    end)
    rightButton:SetScript("OnMouseUp", function()
      rightButton:SetScript("OnUpdate", nil)
    end)
    rightButton:SetScript("OnHide", function()
      rightButton:SetScript("OnUpdate", nil)
    end)
    rightButton:SetScript("OnEnter", function()
      rightButton:SetAlpha(1)
    end)
    rightButton:SetScript("OnLeave", function()
      rightButton:SetAlpha(0.8)
    end)
    rightButton:SetAlpha(0.8)
    rightButton:SetNormalAtlas("Minimal_SliderBar_Button_Right")
    local function Update(scrollPercentage, visibleExtentPercentage)
      if visibleExtentPercentage < 1 then
        leftButton:SetShown(scrollPercentage > 0)
        rightButton:SetShown(scrollPercentage < 1)
      else
        leftButton:Hide()
        rightButton:Hide()
      end
    end
    scrollBox:RegisterCallback(BaseScrollBoxEvents.OnScroll, function(_, scrollPercentage, visibleExtentPercentage)
      Update(scrollPercentage, visibleExtentPercentage)
    end)
    scrollBox:RegisterCallback(BaseScrollBoxEvents.OnSizeChanged, function(_, visibleExtentPercentage)
      if visibleExtentPercentage >= 1 then
        leftButton:Hide()
        rightButton:Hide()
      end
    end)
    scrollBox:RegisterCallback(BaseScrollBoxEvents.OnAllowScrollChanged, function(_, allowScroll)
      if not allowScroll then
        leftButton:Hide()
        rightButton:Hide()
      else
        Update(scrollBox:GetScrollPercentage(), scrollBox:GetVisibleExtentPercentage())
      end
    end)
  end

  return CategorySearch
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnLoad()
  self.currentCategory = "-1"

  self.HelpButton:SetScript("OnClick", function()
    addonTable.Help.ShowSearchDialog()
  end)

  local operationInProgress = false

  local function Save()
    if self.CategoryName:GetText() == "" or operationInProgress then
      return
    end
    operationInProgress = true

    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    local mods = categoryMods[self.currentCategory]
    local oldIndex
    local isNew, isDefault = self.currentCategory == "-1", customCategories[self.currentCategory] == nil
    if not isNew and not isDefault then
      oldIndex = tIndexOf(displayOrder, self.currentCategory)
    end
    if not mods then
      mods = {}
    end
    local oldMods = CopyTable(mods)
    local oldCat = customCategories[self.currentCategory] or {}
    if isNew then
      self.currentCategory = tostring(1)
      while customCategories[self.currentCategory] do
        self.currentCategory = tostring(tonumber(self.currentCategory) + 1)
      end
    end
    mods.priority = self.PrioritySlider:GetValue()
    mods.showGroupPrefix = self.PrefixCheckBox:GetChecked()
    if self.CategoryColorSwatch.pendingColor then
      local c = self.CategoryColorSwatch.pendingColor
      if c.r == 1 and c.g == 1 and c.b == 1 then
        mods.color = nil
      else
        mods.color = c:GenerateHexColorNoAlpha()
      end
    end

    local refreshState = {}

    local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
    local oldHidden = hidden[self.currentCategory] == true
    if isNew or not isDefault then
      local newName = self.CategoryName:GetText():gsub("_", " ")

      customCategories[self.currentCategory] = {
        name = newName,
        search = self.CategorySearch:GetText(),
      }
      categoryMods[self.currentCategory] = mods

      hidden[self.currentCategory] = self.HiddenCheckBox:GetChecked()

      self.CategoryName:SetText(newName)

      if isNew and tIndexOf(displayOrder, self.currentCategory) == nil then
        refreshState[addonTable.Constants.RefreshReason.Searches] = true
        refreshState[addonTable.Constants.RefreshReason.Layout] = true
        table.insert(displayOrder, 1, self.currentCategory)
      end

      if not tCompare(oldCat, customCategories[self.currentCategory]) then
        refreshState[addonTable.Constants.RefreshReason.Searches] = true
        refreshState[addonTable.Constants.RefreshReason.Layout] = true
      end
    else
      hidden[self.currentCategory] = self.HiddenCheckBox:GetChecked()
      categoryMods[self.currentCategory] = mods
    end

    if hidden[self.currentCategory] ~= oldHidden then
      refreshState[addonTable.Constants.RefreshReason.Layout] = true
    end

    for key, value in pairs(mods) do
      if value ~= oldMods[key] and key ~= "color" and key ~= "addedItems" then
        refreshState[addonTable.Constants.RefreshReason.Searches] = true
        refreshState[addonTable.Constants.RefreshReason.Layout] = true
      elseif value ~= oldMods[key] and key == "color" then
        refreshState[addonTable.Constants.RefreshReason.Cosmetic] = true
      end
    end

    for key, value in pairs(oldMods) do
      if value ~= mods[key] and key ~= "color" and key ~= "addedItems" then
        refreshState[addonTable.Constants.RefreshReason.Searches] = true
        refreshState[addonTable.Constants.RefreshReason.Layout] = true
      elseif value ~= mods[key] and key == "color" then
        refreshState[addonTable.Constants.RefreshReason.Cosmetic] = true
      end
    end

    if next(refreshState) ~= nil then
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
    end
    operationInProgress = false
  end

  local function SetState(value)
    operationInProgress = true
    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)

    for _, region in ipairs(self.ChangeAlpha) do
      region:SetAlpha(1)
    end
    self.Blocker:SetPoint("TOPLEFT", self.CategoryName)
    self.Blocker:SetPoint("BOTTOMRIGHT", self.CategorySearch)
    self.DeleteButton:SetEnabled(tIndexOf(addonTable.CategoryViews.Constants.ProtectedCategories, value) == nil)
    self.ItemsEditor:Enable()
    self.CategoryColorSwatch:Enable()
    self.CategoryColorSwatch.pendingColor = nil

    if value == "" then
      self.currentCategory = "-1"
      self.CategoryName:SetText(BAGANATOR_L_NEW_CATEGORY)
      self.CategorySearch:SetText("")
      self.CategorySearch:Enable()
      self.PrioritySlider:SetValue(0)
      self.GroupDropDown:SetText(BAGANATOR_L_NONE)
      self.PrefixCheckBox:SetChecked(true)
      self.HiddenCheckBox:SetChecked(false)
      self.PrioritySlider:Enable()
      self.Blocker:Hide()
      self.ExportButton:Enable()
      self.ItemsEditor:SetupItems()
      self.HelpButton:Enable()
      self.ChangeSearchModeButton:Enable()
      self.CategoryColorSwatch.lastColor = CreateColor(1, 1, 1)
      self.CategoryColorSwatch:SetColorRGB(self.CategoryColorSwatch.lastColor:GetRGBA())
      operationInProgress = false
      Save()
      return
    end

    self.currentCategory = value

    local category
    if customCategories[value] then
      category = customCategories[value]
      self.Blocker:Hide()
      self.ExportButton:Enable()
      self.HelpButton:Enable()
      self.CategorySearch:Enable()
      self.ChangeSearchModeButton:Enable()
    else
      category = addonTable.CategoryViews.Constants.SourceToCategory[value]
      self.ItemsEditor:SetEnabled(not category.auto)
      if category.auto then
        self.ItemsEditor:SetAlpha(disabledAlpha)
      end
      self.CategoryName:SetAlpha(disabledAlpha)
      self.CategorySearch:SetAlpha(disabledAlpha)
      self.CategorySearch:Disable()
      self.ChangeSearchModeButton:SetAlpha(disabledAlpha)
      self.ChangeSearchModeButton:Disable()
      self.HelpButton:SetAlpha(disabledAlpha)
      self.HelpButton:Disable()
      self.Blocker:Show()
      self.ExportButton:Disable()
    end
    self.HiddenCheckBox:SetChecked(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)[value])

    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)

    self.CategoryName:SetText(category.name)
    self.CategorySearch:SetText(category.search or "")
    self.PrioritySlider:SetValue(categoryMods[value] and categoryMods[value].priority or -1)

    self.GroupDropDown:Enable()
    if categoryMods[value] and categoryMods[value].group then
      self.GroupDropDown:SetText(groupingToLabel[categoryMods[value].group])
      self.PrefixCheckBox:GetParent():Show()
    else
      self.PrefixCheckBox:GetParent():Hide()
      self.GroupDropDown:SetText(BAGANATOR_L_NONE)
    end
    self.ItemsEditor:SetupItems()
    if categoryMods[value] and categoryMods[value].showGroupPrefix == false then
      self.PrefixCheckBox:SetChecked(false)
    else
      self.PrefixCheckBox:SetChecked(true)
    end
    if categoryMods[value] and categoryMods[value].color then
      self.CategoryColorSwatch.lastColor = CreateColorFromRGBAHexString(categoryMods[value].color .. "ff")
    else
      self.CategoryColorSwatch.lastColor = CreateColor(1, 1, 1)
    end
    self.CategoryColorSwatch:SetColorRGB(self.CategoryColorSwatch.lastColor:GetRGBA())

    operationInProgress = false
  end

  addonTable.CallbackRegistry:RegisterCallback("EditCategory", function(_, value)
    if not self:GetParent():IsVisible() then
      return
    end
    SetState(value)
  end)

  local hiddenCheckBoxWrapper = GetCheckBox(self)
  hiddenCheckBoxWrapper:SetPoint("TOP", 0, -200)
  self.HiddenCheckBox = hiddenCheckBoxWrapper.checkBox
  self.HiddenCheckBox:SetText(BAGANATOR_L_HIDDEN)

  table.insert(self.ChangeAlpha, self.HiddenCheckBox)

  local prefixCheckBoxWrapper = GetCheckBox(self)
  prefixCheckBoxWrapper:SetPoint("TOP", 0, -240)
  self.PrefixCheckBox = prefixCheckBoxWrapper.checkBox
  self.PrefixCheckBox:SetText(BAGANATOR_L_SHOW_NAME_PREFIX)

  table.insert(self.ChangeAlpha, self.PrefixCheckBox)

  self.PrioritySlider = CreateFrame("Frame", nil, self, "BaganatorCustomSliderTemplate")
  self.PrioritySlider:Init({
    text = BAGANATOR_L_PRIORITY,
    callback = Save,
    min = -1,
    max = 3,
    valueToText = {
      [-1] = BAGANATOR_L_LOW,
      [0] = BAGANATOR_L_NORMAL,
      [1] = BAGANATOR_L_HIGH,
      [2] = BAGANATOR_L_HIGHER,
      [3] = BAGANATOR_L_HIGHEST,
    }
  })
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
    self.PrefixCheckBox:GetParent():SetShown(option.value ~= "")
    self.GroupDropDown:SetText(option.label)
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
  end)
  self.GroupDropDown:SetPoint("TOP", 0, -120)
  self.GroupDropDown:SetPoint("LEFT", 15, 0)
  self.GroupDropDown:SetPoint("RIGHT", -10, 0)
  table.insert(self.ChangeAlpha, self.GroupDropDown)

  self.Blocker = CreateFrame("Frame", nil, self)
  self.Blocker:EnableMouse(true)
  self.Blocker:SetScript("OnMouseWheel", function() end)
  self.Blocker:SetPoint("TOPLEFT", self.CategoryName)
  self.Blocker:SetFrameStrata("DIALOG")
  self.Blocker:SetFrameLevel(10000)

  self.CategoryName:SetScript("OnEditFocusLost", Save)
  self.CategoryName:SetScript("OnEnterPressed", Save)
  self.CategoryName:SetScript("OnTabPressed", function()
    if self.TextCategorySearch:IsVisible() then
      self.CategoryName:ClearHighlightText()
      self.TextCategorySearch:SetFocus()
    end
  end)

  self.CategoryColorSwatch = addonTable.CustomiseDialog.GetColorSwatch(self, self.NameLabel, Save)
  table.insert(self.ChangeAlpha, self.CategoryColorSwatch)

  self.CategorySearchOptions = {
    text = {holder = self.TextCategorySearch, widget = self.TextCategorySearch, changeText = BAGANATOR_L_VISUAL_MODE},
  }

  if Syndicator.Search.GetSearchBuilder then
    self.VisualCategorySearchHolder = CreateFrame("Frame", nil, self)
    self.VisualCategorySearchHolder:SetAllPoints()
    self.VisualCategorySearch = GetVisualSearch(self.VisualCategorySearchHolder)
    self.VisualCategorySearch:RegisterCallback("OnChange", Save)
    table.insert(self.ChangeAlpha, self.VisualCategorySearch)

    self.CategorySearchOptions["visual"] = {holder = self.VisualCategorySearchHolder, widget = self.VisualCategorySearch, changeText = BAGANATOR_L_RAW_MODE}
  end

  self.TextCategorySearch:SetScript("OnEnterPressed", Save)
  addonTable.Skins.AddFrame("IconButton", self.ChangeSearchModeButton, {"changeSearchMode"})

  local function ApplySearchMode()
    local mode = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_EDIT_SEARCH_MODE)
    if not self.VisualCategorySearch then
      mode = "text"
      self.ChangeSearchModeButton:Hide()
    end
    self.ChangeSearchModeButton.tooltipHeader = self.CategorySearchOptions[mode].changeText

    if GameTooltip:GetOwner() == self.ChangeSearchModeButton then
      self.ChangeSearchModeButton:GetScript("OnEnter")(self.ChangeSearchModeButton)
    end

    local oldSearch = self.CategorySearch
    self.CategorySearch = self.CategorySearchOptions[mode].widget
    self.CategorySearchOptions[mode].holder:Show()
    for altMode, details in pairs(self.CategorySearchOptions) do
      if altMode ~= mode then
        details.holder:Hide()
      end
    end

    if self.currentCategory ~= "-1" and oldSearch then
      self.CategorySearch:SetText(oldSearch:GetText())
    end
    if oldSearch then
      if oldSearch.IsEnabled then
        self.CategorySearch:SetEnabled(oldSearch:IsEnabled())
      elseif oldSearch.enabled ~= nil then
        self.CategorySearch:SetEnabled(oldSearch.enabled)
      end
    end
  end

  ApplySearchMode()

  self.ChangeSearchModeButton:SetScript("OnClick", function()
    local mode = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_EDIT_SEARCH_MODE)
    if mode == "visual" then
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_EDIT_SEARCH_MODE, "text")
    else
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_EDIT_SEARCH_MODE, "visual")
    end
    ApplySearchMode()
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CATEGORY_SEARCH_EDIT_MODE then
      ApplySearchMode()
    end
  end)

  self.HiddenCheckBox:SetScript("OnClick", Save)
  self.PrefixCheckBox:SetScript("OnClick", Save)

  self.ItemsEditor = self:MakeItemsEditor()
  self.ItemsEditor:SetPoint("TOP", 0, -290)

  self.ExportButton:SetScript("OnClick", function()
    if self.currentCategory == "-1" then
      return
    end

    StaticPopup_Show("Baganator_Export_Dialog", nil, nil, addonTable.CustomiseDialog.SingleCategoryExport(self.currentCategory))
  end)

  self.DeleteButton:SetScript("OnClick", function()
    if self.currentCategory == "-1" then
      return
    end

    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    local oldIndex = tIndexOf(displayOrder, self.currentCategory)
    if oldIndex then
      table.remove(displayOrder, oldIndex)
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
    end

    if customCategories[self.currentCategory] then
      customCategories[self.currentCategory] = nil
      categoryMods[self.currentCategory] = nil
      addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))
    end

    self:OnHide()
  end)
  addonTable.Skins.AddFrame("Button", self.DeleteButton)
  addonTable.Skins.AddFrame("Button", self.ExportButton)
  addonTable.Skins.AddFrame("EditBox", self.CategoryName)

  self:Disable()
end

function BaganatorCustomiseDialogCategoriesEditorMixin:Disable()
  self.CategoryName:SetText("")
  self.CategoryColorSwatch:Disable()
  self.CategoryColorSwatch:SetColorRGB(1, 1, 1)
  self.CategorySearch:SetText("")
  self.PrioritySlider:SetValue(0)
  self.GroupDropDown:SetText(BAGANATOR_L_NONE)
  self.HiddenCheckBox:SetChecked(false)
  self.PrefixCheckBox:GetParent():Hide()
  self.currentCategory = "-1"
  self.DeleteButton:Disable()
  self.ExportButton:Disable()
  self.ItemsEditor:Disable()
  self.ItemsEditor:SetupItems()
  self.TextCategorySearch:Disable()
  for _, region in ipairs(self.ChangeAlpha) do
    region:SetAlpha(disabledAlpha)
  end
  self.HelpButton:Disable()
  self.ChangeSearchModeButton:Disable()
  self.CategorySearch:Disable()
  self.Blocker:Show()
  self.Blocker:SetPoint("TOPLEFT")
  self.Blocker:SetPoint("BOTTOMRIGHT")
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnHide()
  self:Disable()
end

function BaganatorCustomiseDialogCategoriesEditorMixin:MakeItemsEditor()
  local container = CreateFrame("Frame", nil, self)
  table.insert(self.ChangeAlpha, container)
  container:SetSize(242, 260)
  local itemText = container:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  itemText:SetText(BAGANATOR_L_ITEMS)
  itemText:SetPoint("TOPLEFT", 0, -5)

  self:MakeItemsGrid(container)

  container.ItemsScrollBox:SetPoint("TOPLEFT", 0, -25)

  local dropRegion = CreateFrame("Button", nil, container)
  local dropTexture=  dropRegion:CreateTexture(nil, "ARTWORK")
  dropTexture:SetAtlas("Garr_Building-AddFollowerPlus")
  dropTexture:SetSize(100, 100)
  dropTexture:SetPoint("CENTER", dropRegion)
  dropRegion:SetAllPoints(container.ItemsScrollBox)
  dropRegion:Hide()
  local function DropCursor()
    local t, itemID, itemLink = GetCursorInfo()
    if t ~= "item" then
      return
    end
    ClearCursor()
    local details = addonTable.CategoryViews.Utilities.GetAddedItemData(itemID, itemLink)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    for _, mods in pairs(categoryMods) do
      if mods.addedItems and mods.addedItems[details] then
        mods.addedItems[details] = nil
        if next(mods.addedItems) == nil then
          mods.addedItems = nil
        end
        break
      end
    end

    if not categoryMods[self.currentCategory] then
      categoryMods[self.currentCategory] = {}
    end

    categoryMods[self.currentCategory].addedItems = categoryMods[self.currentCategory].addedItems or {}

    categoryMods[self.currentCategory].addedItems[details] = true

    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
  end
  dropRegion:SetScript("OnReceiveDrag", DropCursor)
  dropRegion:SetScript("OnClick", DropCursor)

  container:SetScript("OnShow", function()
    container:RegisterEvent("CURSOR_CHANGED")
  end)
  container:SetScript("OnHide", function()
    container:UnregisterEvent("CURSOR_CHANGED")
  end)
  local function UpdateForCursor()
    local t, itemID, itemLink = GetCursorInfo()
    dropRegion:SetShown(t == "item" and container.enabled)
  end
  container:SetScript("OnEvent", UpdateForCursor)
  hooksecurefunc(container, "SetupItems", UpdateForCursor)

  local addItemsEditBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
  addItemsEditBox:SetSize(70, 22)
  addItemsEditBox:SetPoint("BOTTOMLEFT", 3, 0)
  addItemsEditBox:SetAutoFocus(false)
  addonTable.Skins.AddFrame("EditBox", addItemsEditBox)
  local addButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  addonTable.Skins.AddFrame("Button", addButton)
  addButton:SetPoint("LEFT", addItemsEditBox, "RIGHT", 1, 1)
  addButton:SetText(BAGANATOR_L_ADD_IDS)
  DynamicResizeButton_Resize(addButton)

  addItemsEditBox:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      addButton:Click()
    end
  end)
  addItemsEditBox:SetScript("OnEnter", function()
    if container.enabled then
      GameTooltip:SetOwner(addItemsEditBox, "ANCHOR_TOP")
      GameTooltip:SetText(BAGANATOR_L_ADD_ITEM_IDS_MESSAGE)
    end
  end)
  addItemsEditBox:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  addButton:SetScript("OnClick", function()
    local text = addItemsEditBox:GetText()
    if not text:match("%d+") then
      return
    end
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    if not categoryMods[self.currentCategory] then
      categoryMods[self.currentCategory] = {}
    end
    if not categoryMods[self.currentCategory].addedItems then
      categoryMods[self.currentCategory].addedItems = {}
    end
    for itemIDString in text:gmatch("%d+") do
      local itemID = tonumber(itemIDString)
      local details = "i:" .. itemID
      for source, mods in pairs(categoryMods) do
        -- Remove the item from any categories its already in
        if mods.addedItems then
          mods.addedItems[details] = nil
        end
      end

      categoryMods[self.currentCategory].addedItems[details] = true
    end
    addItemsEditBox:SetText("")
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
  end)

  local addFromATTButton
  if ATTC then
    addFromATTButton = self:MakeATTImportButton(container)
    addFromATTButton:SetPoint("BOTTOMRIGHT")
  end

  container.Enable = function()
    container:SetEnabled(true)
  end
  container.Disable = function()
    container:SetEnabled(false)
  end
  container.SetEnabled = function(_, state)
    container.enabled = state
    addButton:SetEnabled(state)
    addItemsEditBox:SetEnabled(state)
    if addFromATTButton then
      addFromATTButton:SetEnabled(state)
    end
  end

  return container
end

function BaganatorCustomiseDialogCategoriesEditorMixin:MakeATTImportButton(container)
  local completeDialog = "Baganator_ATT_Add_Items_Complete"
  StaticPopupDialogs[completeDialog] = {
    text = "",
    button1 = DONE,
    timeout = 0,
    hideOnEscape = 1,
  }
  local addFromATTButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  addonTable.Skins.AddFrame("Button", addFromATTButton)
  addFromATTButton:SetText(BAGANATOR_L_ATT_ADDON)
  DynamicResizeButton_Resize(addFromATTButton)
  addFromATTButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(addFromATTButton, "ANCHOR_TOP")
    GameTooltip:SetText(BAGANATOR_L_ADD_FROM_ATT_MESSAGE, nil, nil, nil, nil, true)
  end)
  addFromATTButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local function GetItemsFromATTEntry(entry)
    local result = {}
    if entry.itemID then
      table.insert(result, "i:" .. entry.itemID)
    end
    if entry.petID then
      table.insert(result, "p:" .. entry.petID)
    end
    if entry.g then
      for _, val in pairs(entry.g) do
        tAppendAll(result, GetItemsFromATTEntry(val))
      end
    end
    return result
  end

  addFromATTButton:SetScript("OnClick", function()
    local activePaths = {}
    for key, frame in pairs(_G) do
      local path = key:match("^AllTheThings%-Window%-.*%|r(.*%>.*%d)$")
      if path and frame:IsVisible() then
        table.insert(activePaths, path)
      end
    end

    local items = {}
    for _, path in ipairs(activePaths) do
      local hashes = {strsplit(">", path)}
      local entry = ATTC.SearchForSourcePath(ATTC:GetDataCache().g, hashes, 2, #hashes)

      local label, value = hashes[#hashes]:match("(%a+)(%-?%d+)")

      if not entry then
        local searchResults = ATTC.SearchForField(label, tonumber(value))
        for _, result in ipairs(searchResults) do
          if ATTC.GenerateSourceHash(result) == path then
            entry = result
          end
        end
      end

      if not entry then
        entry = ATTC.GetCachedSearchResults(ATTC.SearchForLink, label .. ":" .. value);
      end

      if not entry then
        local tmp = {}
        ATTC.BuildFlatSearchResponse(ATTC:GetDataCache().g, label, tonumber(value), tmp)
        if #tmp == 1 then
          entry = tmp[1]
        end
      end
      if entry then
        tAppendAll(items, GetItemsFromATTEntry(entry))
      end
    end

    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    if not categoryMods[self.currentCategory] then
      categoryMods[self.currentCategory] = {}
    end
    if not categoryMods[self.currentCategory].addedItems then
      categoryMods[self.currentCategory].addedItems = {}
    end
    for _, item in ipairs(items) do
      categoryMods[self.currentCategory].addedItems[item] = true
    end
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))

    StaticPopupDialogs[completeDialog].text = BAGANATOR_L_ADD_FROM_ATT_POPUP_COMPLETE:format(#items, #activePaths)
    StaticPopup_Show(completeDialog)
  end)

  return addFromATTButton
end

function BaganatorCustomiseDialogCategoriesEditorMixin:MakeItemsGrid(container)
  local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  scrollBox:SetSize(242, 200)
  local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
  scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)
  addonTable.Skins.AddFrame("TrimScrollBar", scrollBar)
  local view = CreateScrollBoxListLinearView()

  local inset =  CreateFrame("Frame", nil, container, "InsetFrameTemplate")
  inset:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", -2, 2)
  inset:SetPoint("BOTTOMRIGHT", scrollBox, "BOTTOMRIGHT", 2, -2)
  inset:SetFrameLevel(scrollBox:GetFrameLevel() - 1)
  addonTable.Skins.AddFrame("InsetFrame", inset)

  local itemsPerRow = 7
  local itemSize = 31

  local cachedItemButtonCounter = 0
  local function GetCachedItemButton()
    -- Use cached item buttons from cached layout views
    if addonTable.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, container, "BaganatorRetailCachedItemButtonTemplate")
    else
      cachedItemButtonCounter = cachedItemButtonCounter + 1
      return CreateFrame("Button", "BGRCachedCustomiseCategoryItemButton" .. cachedItemButtonCounter, container, "BaganatorClassicCachedItemButtonTemplate")
    end
  end

  view:SetElementExtent(itemSize + 3)
  view:SetElementInitializer("Frame", function(row, items)
    if not row.setup then
      row.setup = true
      row.buttons = {}
      for i = 1, itemsPerRow do
        local itemButton = GetCachedItemButton()
        itemButton:SetParent(row)
        itemButton:SetScale(itemSize / 37)
        itemButton:SetPoint("LEFT", 37/itemSize * ((i - 1) * itemSize + (i - 1) * 3 + 4), 0)
        addonTable.Skins.AddFrame("ItemButton", itemButton)
        addonTable.Utilities.MasqueRegistration(itemButton)
        itemButton:UpdateTextures()
        itemButton:SetScript("OnClick", function(_, mouseButton)
          if mouseButton == "RightButton" then
            local details = addonTable.CategoryViews.Utilities.GetAddedItemData(itemButton.BGR.itemID, itemButton.BGR.itemLink)
            local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
            categoryMods[self.currentCategory].addedItems[details] = nil
            addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
          end
        end)
        hooksecurefunc(itemButton, "UpdateTooltip", function()
          if GameTooltip:IsShown() and not itemButton.BGR.invalid then
            GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_RIGHT_CLICK_TO_REMOVE))
            GameTooltip:Show()
          elseif BattlePetTooltip:IsShown() then
            BattlePetTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_RIGHT_CLICK_TO_REMOVE))
            BattlePetTooltip:Show()
          else
            itemButton.BGR.invalid = true
            GameTooltip:SetOwner(itemButton, "ANCHOR_RIGHT")
            GameTooltip:AddLine(RED_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_ITEM_INFORMATION_MISSING))
            GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_RIGHT_CLICK_TO_REMOVE))
            GameTooltip:Show()
          end
        end)
        table.insert(row.buttons, itemButton)
      end
    end
    for index, item in ipairs(items) do
      row.buttons[index]:Show()
      row.buttons[index]:SetItemDetails(item)
    end
    if #items < itemsPerRow then
      for index = #items + 1, itemsPerRow do
        row.buttons[index]:Hide()
      end
    end
  end)

  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  container.ItemsScrollBox = scrollBox

  container.SetupItems = function()
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local itemRefs = categoryMods[self.currentCategory] and categoryMods[self.currentCategory].addedItems or {}
    local keys = {}
    for ref in pairs(itemRefs) do
      table.insert(keys, ref)
    end
    table.sort(keys)
    local lastGroup = {}
    local items = {}
    for _, ref in ipairs(keys) do
      local t, id = ref:match("^(.):(%d+)$")
      id = tonumber(id)
      if t == "i" then
        table.insert(lastGroup, {
          itemID = id,
          itemLink = "item:" .. id,
          iconTexture = select(5, C_Item.GetItemInfoInstant(id)),
          quality = 1,
          itemCount = 1,
          isBound = false,
        })
      elseif t == "p" then
        table.insert(lastGroup, {
          itemID = addonTable.Constants.BattlePetCageID,
          itemLink = "|Hbattlepet:" .. id .. ":0:1:0|h|h",
          iconTexture = select(2, C_PetJournal.GetPetInfoBySpeciesID(id)),
          quality = 1,
          itemCount = 1,
          isBound = false,
        })
      end
      if #lastGroup >= itemsPerRow then
        table.insert(items, lastGroup)
        lastGroup = {}
      end
    end
    if #lastGroup > 0 then
      table.insert(items, lastGroup)
    end
    scrollBox:SetDataProvider(CreateDataProvider(items), true)
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if not self:IsVisible() then
      return
    end

    if settingName == addonTable.Config.Options.CATEGORY_MODIFICATIONS then
      container.SetupItems()
    end
  end)
end
