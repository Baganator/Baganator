---@class addonTableBaganator
local addonTable = select(2, ...)

local folderMarker
if C_Texture.GetAtlasInfo("AnimCreate_Icon_Folder") then
  folderMarker = "AnimCreate_Icon_Folder"
else
  folderMarker = "FXAM-SmallSpikeyGlow"
end

local function PopulateCategoryOrder(container)
  local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)

  local elements = {}
  local dataProviderElements = {}
  local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
  local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
  local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
  local indentLevel = 0
  for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local indent = string.rep("      ", indentLevel)
    local color = WHITE_FONT_COLOR
    if hidden[source] then
      color = GRAY_FONT_COLOR
    elseif categoryMods[source] and categoryMods[source].color then
      color = CreateColorFromRGBHexString(categoryMods[source].color)
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
        indentLevel = indentLevel - 1
        name = " "
      else
        indentLevel = indentLevel + 1
        local sectionDetails = sections[source:match("^_(.*)")]
        if sectionDetails.color then
          color = CreateColorFromRGBHexString(sectionDetails.color)
        end
        name = indent .. CreateAtlasMarkup(folderMarker) .. " " .. color:WrapTextInColorCode(addonTable.Locales["SECTION_" .. sectionDetails.name] or sectionDetails.name)
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
  local selectedValue, selectedIndex = "", -1

  local container = CreateFrame("Frame", nil, parent)
  local inset = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
  inset:SetPoint("TOPLEFT")
  inset:SetPoint("BOTTOMRIGHT", -15, 0)
  addonTable.Skins.AddFrame("InsetFrame", inset)
  container.ScrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  container.ScrollBox:SetPoint("TOPLEFT", 1, -3)
  container.ScrollBox:SetPoint("BOTTOMRIGHT", -15, 3)

  local function UpdateSelected(value, index)
    selectedValue, selectedIndex = value, index
    for _, f in ipairs(container.ScrollBox:GetFrames()) do
      f.selectedTexture:SetShown(f.value == selectedValue and (f.value ~= addonTable.CategoryViews.Constants.DividerName or f.indexValue == selectedIndex))
    end
  end
  addonTable.CallbackRegistry:RegisterCallback("SetSelectedCategory", function(_, categoryName)
    UpdateSelected(categoryName, -1)
  end)
  addonTable.CallbackRegistry:RegisterCallback("ResetCategoryEditor", function()
    UpdateSelected("", -1)
  end)

  container:SetScript("OnHide", function()
    UpdateSelected("", -1)
  end)
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
      frame:SetHighlightAtlas("Options_List_Hover")
      frame.selectedTexture = frame:CreateTexture(nil, "ARTWORK")
      frame.selectedTexture:SetAllPoints(true)
      frame.selectedTexture:Hide()
      frame.selectedTexture:SetAtlas("Options_List_Active")
      frame:SetScript("OnClick", function(self, button)
        UpdateSelected(self.value, self.indexValue)
        if self.value:match("^_") then
          addonTable.CallbackRegistry:TriggerEvent("EditCategorySection", (self.value:match("^_(.*)")))
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
      frame:SetText(" ")
      frame:GetFontString():SetWordWrap(false)
      local button = CreateFrame("Button", nil, frame)
      button:SetSize(28, 22)
      local tex = button:CreateTexture(nil, "ARTWORK")
      tex:SetTexture("Interface\\PaperDollInfoFrame\\statsortarrows")
      tex:SetPoint("LEFT", 4, 0)
      tex:SetSize(14, 14)
      button:SetAlpha(0.8)
      button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT", -16, 0)
        GameTooltip:SetText(addonTable.Locales.MOVE)
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
    frame.selectedTexture:SetShown(frame.value == selectedValue and (frame.value ~= addonTable.CategoryViews.Constants.DividerName or frame.indexValue == selectedIndex))
    frame:SetText(elementData.label)
    frame:GetFontString():SetPoint("RIGHT", -8, 0)
    frame:GetFontString():SetPoint("LEFT", 40, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    local default = addonTable.CategoryViews.Constants.SourceToCategory[frame.value]
    local categoryEnd = frame.value == addonTable.CategoryViews.Constants.SectionEnd
    frame:SetEnabled(not categoryEnd)
    frame.repositionButton:SetShown(not categoryEnd)
  end)
  container.ScrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
  container.ScrollBar:SetPoint("TOPRIGHT")
  container.ScrollBar:SetPoint("BOTTOMRIGHT")
  ScrollUtil.InitScrollBoxListWithScrollBar(container.ScrollBox, container.ScrollBar, scrollView)
  addonTable.Skins.AddFrame("TrimScrollBar", container.ScrollBar)

  container:SetSize(250, 630)

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

local function SetCategoriesToDropDown(dropdown, ignore)
  dropdown:SetupMenu(function(_, rootDescription)
    local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
    local defaultOptions = {}
    for source, category in pairs(addonTable.CategoryViews.Constants.SourceToCategory) do
      local color = categoryMods[source] and categoryMods[source].color or "ffffff"
      if not ignore[source] then
        table.insert(defaultOptions, {label = "|cff" .. color .. category.name .. "|r", sortKey = category.name, value = source})
      end
    end
    table.sort(defaultOptions, function(a, b) return a.label:lower() < b.label:lower() end)

    local customOptions = {}
    local nameCount = {}
    for source, category in pairs(addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)) do
      if not ignore[source] then
        local color = categoryMods[source] and categoryMods[source].color or "ffffff"
        if not nameCount[category.name] then
          local raw = category.name .. " (*)"
          table.insert(customOptions, {label = "|cff" .. color .. raw .. "|r", sortKey = raw, value = source, isCustom = true})
          nameCount[category.name] = 1
        else
          local raw = category.name .. " (*" .. nameCount[category.name] .. ")"
          nameCount[category.name] = nameCount[category.name] + 1
          table.insert(customOptions, {label = "|cff" .. color .. raw .. "|r", sortKey = raw, value = source, isCustom = true})
        end
      end
    end
    table.sort(customOptions, function(a, b) return a.sortKey:lower() < b.sortKey:lower() end)

    local options = customOptions
    tAppendAll(options, defaultOptions)

    table.insert(options, 1, {
      value = "", label = NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.CREATE_NEW_CATEGORY)
    })
    table.insert(options, 2, {
      value = "_", label = NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.CREATE_NEW_SECTION)
    })
    table.insert(options, 3, {
      value = addonTable.CategoryViews.Constants.DividerName, label = NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.CREATE_NEW_DIVIDER)
    })

    for _, opt in ipairs(options) do
      local button = rootDescription:CreateButton(opt.label, function() dropdown:OnEntryClicked({value = opt.value, label = opt.label}) end)
      if opt.isCustom then
        button:AddInitializer(function(button, description, menu)
          local delete = MenuTemplates.AttachAutoHideButton(button, "transmog-icon-remove")
          delete:SetPoint("RIGHT")
          delete:SetSize(18, 18)
          delete.Texture:SetAtlas("transmog-icon-remove")
          delete:SetScript("OnClick", function()
            local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
            local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)

            if customCategories[opt.value] then
              customCategories[opt.value] = nil
              categoryMods[opt.value] = nil
              addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))
            end
            local scroll = menu.ScrollBox:GetScrollPercentage() * menu.ScrollBox:GetExtent()
            menu:Close()
            dropdown:OpenMenu()
            dropdown.menu.ScrollBox:SetScrollPercentage(scroll / dropdown.menu.ScrollBox:GetExtent())
          end)
          MenuUtil.HookTooltipScripts(delete, function(tooltip)
            GameTooltip_SetTitle(tooltip, DELETE);
          end);
        end)
      end
    end

    rootDescription:SetScrollMode(20 * 20)
  end)
end

function addonTable.CustomiseDialog.GetCategoriesOrganiser(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(300, 700)
  container:SetPoint("CENTER")

  local previousOrder = CopyTable(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER))

  container:SetScript("OnShow", function()
    previousOrder = CopyTable(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER))
  end)

  local categoryOrder
  local highlightContainer = CreateFrame("Frame", nil, container)
  local highlight = highlightContainer:CreateTexture(nil, "OVERLAY", nil, 7)
  highlight:SetSize(235, 20)
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
      if insertIndex == 0 then
        insertIndex = 1
      end

      if draggable.value:match("^_") then
        local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
        sections[draggable.value:gsub("^_", "")] = draggable.sectionDetails
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
    for _, frame in categoryOrder.ScrollBox:EnumerateFrames() do
      frame:UnlockHighlight()
    end
    highlight:Hide()
  end, function()
    highlight:ClearAllPoints()
    highlight:Hide()
    for _, frame in categoryOrder.ScrollBox:EnumerateFrames() do
      frame:UnlockHighlight()
    end
    if categoryOrder:IsMouseOver() then
      highlight:Show()
      local hoverFrame, isTop, hoverIndex = addonTable.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if hoverFrame and ((categoryOrder.elements[hoverIndex] == addonTable.CategoryViews.Constants.SectionEnd and isTop) or (categoryOrder.elements[hoverIndex + 1] == addonTable.CategoryViews.Constants.SectionEnd and not isTop)) then
        local level = 1
        local startIndex = 1
        for i = isTop and hoverIndex - 1 or hoverIndex, 1, -1 do
          local value = categoryOrder.elements[i]
          if value == addonTable.CategoryViews.Constants.SectionEnd then
            level = level + 1
          elseif value:match("^_") then
            level = level - 1
          end
          if level == 0 then
            startIndex = i
            break
          end
        end
        for _, frame in categoryOrder.ScrollBox:EnumerateFrames() do
          if frame.indexValue <= hoverIndex and frame.indexValue >= startIndex then
            frame:LockHighlight()
          end
        end
      end
      if hoverFrame and isTop then
        highlight:SetPoint("BOTTOMLEFT", hoverFrame, "TOPLEFT", 0, -10)
      elseif hoverFrame then
        highlight:SetPoint("TOPLEFT", hoverFrame, "BOTTOMLEFT", 0, 10)
      elseif #categoryOrder.elements > 0 then
        highlight:SetPoint("BOTTOMLEFT", categoryOrder, 0, 0)
      else
        highlight:SetPoint("TOPLEFT", categoryOrder, 0, 0)
      end
    end
  end)

  local dropdown = CreateFrame("DropdownButton", nil, container, "WowStyle1DropdownTemplate")
  addonTable.Skins.AddFrame("Dropdown", dropdown)
  dropdown.disableSelectionText = true
  SetCategoriesToDropDown(dropdown, GetInsertedCategories())

  local function Pickup(value, label, index)
    draggable.value = value
    draggable.sectionDetails = nil
    draggable.sectionValues = {}
    if index ~= nil then
      table.remove(categoryOrder.elements, index)
      if value:match("^_") then -- section
        local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
        local key = value:match("^_(.*)")
        draggable.sectionDetails = sections[key]
        sections[key] = nil

        local level = 1
        while level ~= 0 and #categoryOrder.elements > 0 do
          local tmp = categoryOrder.elements[index]
          table.insert(draggable.sectionValues, tmp)
          table.remove(categoryOrder.elements, index)
          if tmp == addonTable.CategoryViews.Constants.SectionEnd then
            level = level - 1
          elseif tmp:match("^_") then
            level = level + 1
          end
        end
      end
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end

    dropdown:SetText(label)
    draggable:Show()
    draggable.text:SetText(label)
  end

  categoryOrder = GetCategoryContainer(container, Pickup)
  categoryOrder:SetPoint("TOPLEFT", 0, -40)

  dropdown:SetText(addonTable.Locales.INSERT_OR_CREATE)

  dropdown.OnEntryClicked = function(_, option)
    if option.value == "_" then
      addonTable.CallbackRegistry:TriggerEvent("EditCategorySection", (option.value:match("^_(.*)")))
    elseif option.value == addonTable.CategoryViews.Constants.DividerName then
      Pickup(option.value, addonTable.CategoryViews.Constants.DividerLabel, nil)
    elseif option.value ~= "" then
      Pickup(option.value, option.label, tIndexOf(categoryOrder.elements, option.value))
    else
      addonTable.CallbackRegistry:TriggerEvent("EditCategory", option.value)
    end
  end
  draggable:SetScript("OnHide", function()
    dropdown:SetText(addonTable.Locales.INSERT_OR_CREATE)
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
    for _, source in ipairs(addonTable.CategoryViews.Constants.ProtectedCategories) do
      if tIndexOf(displayOrder, source) == nil then
        table.insert(displayOrder, source)
        addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
      end
    end
  end)
  dropdown:SetPoint("BOTTOMLEFT", categoryOrder, "TOPLEFT", 0, 8)
  dropdown:SetPoint("RIGHT", categoryOrder.ScrollBar, 5, 0)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
    if refreshState[addonTable.Constants.RefreshReason.Cosmetic] or refreshState[addonTable.Constants.RefreshReason.Searches] then
      SetCategoriesToDropDown(dropdown, GetInsertedCategories())
      PopulateCategoryOrder(categoryOrder)
    end
  end)
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CATEGORY_DISPLAY_ORDER or settingName == addonTable.Config.Options.CATEGORY_HIDDEN or settingName == addonTable.Config.Options.CUSTOM_CATEGORIES then
      SetCategoriesToDropDown(dropdown, GetInsertedCategories())
      PopulateCategoryOrder(categoryOrder)
    end
  end)

  local exportButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  exportButton:SetPoint("RIGHT", container, -17, 0)
  exportButton:SetPoint("BOTTOM", container)
  exportButton:SetText(addonTable.Locales.EXPORT)
  DynamicResizeButton_Resize(exportButton)
  exportButton:SetScript("OnClick", function()
    addonTable.Dialogs.ShowCopy(addonTable.CustomiseDialog.CategoriesExport():gsub("|n", "||n"):gsub("|([kK])", "||%1"))
  end)
  addonTable.Skins.AddFrame("Button", exportButton)

  local importButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  importButton:SetPoint("LEFT", categoryOrder, 0, 0)
  importButton:SetPoint("BOTTOM", container)
  importButton:SetText(addonTable.Locales.IMPORT)
  DynamicResizeButton_Resize(importButton)
  importButton:SetScript("OnClick", function()
    addonTable.CustomiseDialog.ShowCategoriesImportDialog(function(text)
      addonTable.CustomiseDialog.CategoriesImport(text)
    end)
  end)
  addonTable.Skins.AddFrame("Button", importButton)

  return container
end
