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

function BaganatorCustomiseDialogCategoriesEditorMixin:OnLoad()
  self.currentCategory = "-1"

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
    local oldMods = categoryMods[self.currentCategory]
    local oldIndex
    local isNew, isDefault = self.currentCategory == "-1", customCategories[self.currentCategory] == nil
    if not isNew and not isDefault then
      oldIndex = tIndexOf(displayOrder, self.currentCategory)
    end
    if not oldMods then
      oldMods = {}
    end
    if isNew then
      self.currentCategory = tostring(1)
      while customCategories[self.currentCategory] do
        self.currentCategory = tostring(tonumber(self.currentCategory) + 1)
      end
    end
    oldMods.priority = self.PrioritySlider:GetValue()
    oldMods.showGroupPrefix = self.PrefixCheckBox:GetChecked()

    local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
    local oldHidden = hidden[self.currentCategory] == true
    if isNew or not isDefault then
      local newName = self.CategoryName:GetText():gsub("_", " ")

      customCategories[self.currentCategory] = {
        name = newName,
        search = self.CategorySearch:GetText(),
      }
      categoryMods[self.currentCategory] = oldMods

      hidden[self.currentCategory] = self.HiddenCheckBox:GetChecked()

      self.CategoryName:SetText(newName)

      if isNew and tIndexOf(displayOrder, self.currentCategory) == nil then
        table.insert(displayOrder, 1, self.currentCategory)
        addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
      end
    else
      hidden[self.currentCategory] = self.HiddenCheckBox:GetChecked()
      categoryMods[self.currentCategory] = oldMods
    end

    if hidden[self.currentCategory] ~= oldHidden then
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
    end

    addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))
  end

  local function SetState(value)
    local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)

    for _, region in ipairs(self.ChangeAlpha) do
      region:SetAlpha(1)
    end
    self.Blocker:SetPoint("TOPLEFT", self.CategoryName)
    self.Blocker:SetPoint("BOTTOMRIGHT", self.CategorySearch)
    self.DeleteButton:Enable()

    if value == "" then
      self.currentCategory = "-1"
      self.CategoryName:SetText(BAGANATOR_L_NEW_CATEGORY)
      self.CategorySearch:SetText("")
      self.PrioritySlider:SetValue(0)
      self.GroupDropDown:SetText(BAGANATOR_L_NONE)
      self.PrefixCheckBox:SetChecked(true)
      self.HiddenCheckBox:SetChecked(false)
      self.PrioritySlider:Enable()
      self.Blocker:Hide()
      self.ExportButton:Enable()
      Save()
      return
    end

    self.currentCategory = value

    local category
    if customCategories[value] then
      category = customCategories[value]
      self.Blocker:Hide()
      self.ExportButton:Enable()
    else
      category = addonTable.CategoryViews.Constants.SourceToCategory[value]
      self.CategoryName:SetAlpha(disabledAlpha)
      self.CategorySearch:SetAlpha(disabledAlpha)
      self.HelpButton:SetAlpha(disabledAlpha)
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
    if categoryMods[value] and categoryMods[value].addedItems then
      self.ItemsEditor:SetupItems()
    else
      self.ItemsEditor:SetupItems({})
    end
    if categoryMods[value] and categoryMods[value].showGroupPrefix == false then
      self.PrefixCheckBox:SetChecked(false)
    else
      self.PrefixCheckBox:SetChecked(true)
    end
  end

  addonTable.CallbackRegistry:RegisterCallback("EditCategory", function(_, value)
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
  self.PrefixCheckBox:SetScript("OnClick", Save)

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
  addonTable.Skins.AddFrame("EditBox", self.CategorySearch)

  self:Disable()
end

function BaganatorCustomiseDialogCategoriesEditorMixin:Disable()
  self.CategoryName:SetText("")
  self.CategorySearch:SetText("")
  self.PrioritySlider:SetValue(0)
  self.GroupDropDown:SetText(BAGANATOR_L_NONE)
  self.HiddenCheckBox:SetChecked(false)
  self.PrefixCheckBox:GetParent():Hide()
  self.currentCategory = "-1"
  self.DeleteButton:Disable()
  self.ExportButton:Disable()
  self.ItemsEditor:SetupItems()
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

function BaganatorCustomiseDialogCategoriesEditorMixin:MakeItemsEditor()
  local container = CreateFrame("Frame", nil, self)
  table.insert(self.ChangeAlpha, container)
  container:SetSize(242, 260)
  local itemText = container:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  itemText:SetText(BAGANATOR_L_ITEMS)
  itemText:SetPoint("TOPLEFT", 0, -5)

  self:MakeItemsGrid(container)

  container.ItemsScrollBox:SetPoint("TOPLEFT", 0, -25)

  local addItemsEditBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
  addItemsEditBox:SetSize(70, 22)
  addItemsEditBox:SetPoint("BOTTOMLEFT", 3, 0)
  addItemsEditBox:SetAutoFocus(false)
  addonTable.Skins.AddFrame("EditBox", addItemsEditBox)
  local addButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  addonTable.Skins.AddFrame("Button", addButton)
  addButton:SetPoint("LEFT", addItemsEditBox, "RIGHT", 1, 0)
  addButton:SetText(BAGANATOR_L_ADD_IDS)
  DynamicResizeButton_Resize(addButton)

  addItemsEditBox:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      addButton:Click()
    end
  end)
  addItemsEditBox:SetScript("OnEnter", function()
    GameTooltip:SetOwner(addItemsEditBox, "ANCHOR_TOP")
    GameTooltip:SetText(BAGANATOR_L_ADD_ITEM_IDS_MESSAGE)
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

  if ATTC then
    local addFromATTButton = self:MakeATTImportButton(container)
    addFromATTButton:SetPoint("BOTTOMRIGHT")
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
    scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately);
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
