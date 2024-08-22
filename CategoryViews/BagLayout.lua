local _, addonTable = ...

local linkMap = {}

local function Prearrange(isLive, bagID, bag, bagType)
  local junkPluginID = addonTable.Config.Get("junk_plugin")
  local junkPlugin = addonTable.API.JunkPlugins[junkPluginID] and addonTable.API.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end

  local emptySlots = {}
  local everything = {}
  if not bagID then -- Avoid errors from bags removed from the possible indexes
    return {emptySlots = emptySlots, everything = {}, bagType = bagType}
  end
  for slotIndex, slot in ipairs(bag) do
    local info = Syndicator.Search.GetBaseInfo(slot)
    if isLive then
      if addonTable.Constants.IsClassic then
        if bagID == Syndicator.Constants.AllBankIndexes[1] then
          local inventorySlot = BankButtonIDToInvSlotID(slotIndex)
          info.tooltipGetter = function() return Syndicator.Search.DumpClassicTooltip(function(tooltip) tooltip:SetInventoryItem("player", inventorySlot) end) end
        else
          info.tooltipGetter = function() return Syndicator.Search.DumpClassicTooltip(function(tooltip) tooltip:SetBagItem(bagID, slotIndex) end) end
        end
      else
        info.tooltipGetter = function() return C_TooltipInfo.GetBagItem(bagID, slotIndex) end
      end
      info.isJunkGetter = junkPlugin and function() local _, result = pcall(junkPlugin, bagID, slotIndex, info.itemID, info.itemLink); return result == true end
      if info.itemID ~= nil then
        local location = {bagID = bagID, slotIndex = slotIndex}
        info.setInfo = addonTable.ItemViewCommon.GetEquipmentSetInfo(location, info.itemLink)
        if info.setInfo then
          info.guid = C_Item.GetItemGUID(location)
        end
      end
      info.bagID = bagID
      info.slotID = slotIndex
    end
    if info.itemID then
      info.guid = info.guid or ""
      info.iconTexture = slot.iconTexture
      info.keyLink = linkMap[info.itemLink]
      if not info.keyLink then
        info.keyLink = info.itemLink:gsub("(item:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)%d+:", "%1:")
        linkMap[info.itemLink] = info.keyLink
      end
      info.key = addonTable.ItemViewCommon.Utilities.GetCategoryDataKeyNoCount(info) .. tostring(info.guid)
      table.insert(everything, info)
    else
      table.insert(emptySlots, {bagID = bagID, itemCount = 1, slotID = slotIndex, key = bagType, bagType = bagType, keyLink = bagType})
    end
  end

  return {emptySlots = emptySlots, everything = everything}
end

addonTable.CategoryViews.BagLayoutMixin = {}

function addonTable.CategoryViews.BagLayoutMixin:OnLoad()
  self.labelsPool = CreateFramePool("Button", self:GetParent(), "BaganatorCategoryViewsCategoryButtonTemplate")
  self.sectionButtonPool = addonTable.CategoryViews.GetSectionButtonPool(self:GetParent())
  self.dividerPool = CreateFramePool("Button", self:GetParent(), "BaganatorBagDividerTemplate")

  self.updatedBags = {}

  self.notShown = {}

  self:SetScript("OnShow", self.OnShow)
  self:SetScript("OnHide", self.OnHide)

  self.ItemsPreparation = CreateFrame("Frame", nil, self)
  Mixin(self.ItemsPreparation, BaganatorCategoryViewsItemsPreparationMixin)
  self.ItemsPreparation:OnLoad()

  self.CategoryFilter = CreateFrame("Frame", nil, self)
  Mixin(self.CategoryFilter, BaganatorCategoryViewsCategoryFilterMixin)
  self.CategoryFilter:OnLoad()
  self.CategoryFilter:SetScript("OnHide", self.CategoryFilter.OnHide)

  self.CategorySort = CreateFrame("Frame", nil, self)
  Mixin(self.CategorySort, BaganatorCategoryViewsCategorySortMixin)

  self.CategoryGrouping = CreateFrame("Frame", nil, self)
  Mixin(self.CategoryGrouping, BaganatorCategoryViewsCategoryGroupingMixin)
end

function addonTable.CategoryViews.BagLayoutMixin:OnHide()
  for _, item in ipairs(self.notShown) do
    if item.bagID ~= nil then
      addonTable.NewItems:ClearNewItem(item.bagID, item.slotID)
    end
  end
end

function addonTable.CategoryViews.BagLayoutMixin:OnShow()
  self.composed = nil
end

function addonTable.CategoryViews.BagLayoutMixin:NewCharacter()
  self.composed = nil
end

function addonTable.CategoryViews.BagLayoutMixin:SettingChanged(settingName)
  if tIndexOf(addonTable.CategoryViews.Constants.ClearCachesSettings, settingName) ~= nil then
    self.ItemsPreparation:ResetCaches()
    self.CategoryFilter:ResetCaches()
  end
  self.composed = nil
end

-- Called in response to the ContentRefreshRequired event triggered when items
-- need updated. NOT in reponse to categories being updated.
function addonTable.CategoryViews.BagLayoutMixin:FullRefresh()
  self.CategoryFilter:ResetCaches()
  self.ItemsPreparation:ResetCaches()
end

function addonTable.CategoryViews.BagLayoutMixin:ClearVisuals()
  self.labelsPool:ReleaseAll()
  self.sectionButtonPool:ReleaseAll()
  self.dividerPool:ReleaseAll()
end

function addonTable.CategoryViews.BagLayoutMixin:NotifyBagUpdate(updatedBags)
  for bagID, state in pairs(updatedBags) do
    if state then
      self.updatedBags[bagID] = true
    end
  end
end

function addonTable.CategoryViews.BagLayoutMixin:Display(bagWidth, bagIndexes, bagTypes, composed, emptySlotsOrder, emptySlotsByType, bagWidth, sideSpacing, topSpacing)

  local container = self:GetParent()

  local layoutCount = 0
  for _, details in ipairs(composed.details) do
    if details.type == "category" then
      layoutCount = layoutCount + 1
    end
  end
  while #container.LiveLayouts < layoutCount do
    table.insert(container.LiveLayouts, CreateFrame("Frame", nil, container, "BaganatorLiveCategoryLayoutTemplate"))
    if container.liveItemButtonPool then
      container.LiveLayouts[#container.LiveLayouts]:SetPool(container.liveItemButtonPool)
    end
    table.insert(container.CachedLayouts, CreateFrame("Frame", nil, container, "BaganatorCachedCategoryLayoutTemplate"))
  end

  local start2 = debugprofilestop()

  self.labelsPool:ReleaseAll()
  self.dividerPool:ReleaseAll()
  self.sectionButtonPool:ReleaseAll()

  local emptyDetails = FindValueInTableIf(composed.details, function(a) return a.emptySlots end)
  local splitEmpty = nil
  if emptyDetails then
    local slots = {}
    if not addonTable.Config.Get(addonTable.Config.Options.CATEGORY_GROUP_EMPTY_SLOTS) then
      splitEmpty = slots
      for _, bagType in ipairs(emptySlotsOrder) do
        if bagType ~= "keyring" then
          tAppendAll(slots, emptySlotsByType[bagType])
        else
          table.insert(slots, emptySlotsByType[bagType][1])
        end
      end
    else
      for _, bagType in ipairs(emptySlotsOrder) do
        local entry = CopyTable(emptySlotsByType[bagType][1])
        entry.itemCount = #emptySlotsByType[bagType]
        table.insert(slots, entry)
      end
    end
    emptyDetails.results = slots
  end

  local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
  local sectionToggled = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)

  self.notShown = {}
  for _, details in pairs(composed.details) do
    if details.results then
      local entries = {}
      if container.isGrouping and not details.emptySlots then
        local entriesByKey = {}
        for _, item in ipairs(details.results) do
          local groupingKey = item.key
          if entriesByKey[groupingKey] then
            entriesByKey[groupingKey].itemCount = entriesByKey[groupingKey].itemCount + item.itemCount
            -- Used to clear new item status on items that are hidden in a stack
            table.insert(self.notShown, {bagID = item.bagID, slotID = item.slotID})
          else
            entriesByKey[groupingKey] = item
            table.insert(entries, item)
          end
        end
      else
        entries = details.results
      end
      if container.isLive and container.addToCategoryMode and addonTable.Config.Get(addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS) and not details.auto then
        if container.addToCategoryMode ~= details.source then
          table.insert(entries, {isDummy = true, label = BAGANATOR_L_ADD_TO_CATEGORY, dummyType = "add"})
        else
          if container.addedToFromCategory then
            table.insert(entries, {isDummy = true, label = BAGANATOR_L_REMOVE_FROM_CATEGORY, dummyType = "remove"})
          end
        end
      end
      details.results = entries
      details.any = #entries > 0
      if hidden[details.source] or sectionToggled[details.section] then
        for _, entry in ipairs(details.results) do
          table.insert(self.notShown, entry)
        end
        details.results = {}
      end
    end
  end

  local oldComposed = self.composed
  self.composed = composed
  if oldComposed then
    local anyNew = false
    for index, old in ipairs(oldComposed.details) do
      local current = composed.details[index]
      if current == nil or old.source ~= current.source or (current.source and not old.emptySlots and old.oldLength and old.oldLength < #current.results) then
        anyNew = true
        break
      end
    end
    if not anyNew and not container.addToCategoryMode then
      local typeMap = {}
      for index, bagType in ipairs(bagTypes) do
        typeMap[bagIndexes[index]] = bagType
      end
      for index, old in ipairs(oldComposed.details) do
        if old.results then
          local current = composed.details[index]
          current.oldLength = #current.results
          if #old.results > #current.results and not old.emptySlots then
            for index, info in ipairs(old.results) do
              if #current.results >= #old.results then
                break
              end
              if info.bagID and info.slotID and not C_Item.DoesItemExist({bagID = info.bagID, slotIndex = info.slotID}) then
                if not info.key or not old.isGrouping or not FindInTableIf(current.results, function(a) return a.key == info.key end) then
                  table.insert(current.results, index, {bagID = info.bagID, slotID = info.slotID, itemCount = 0, keyLink = typeMap[info.bagID], bagType = typeMap[info.bagID]})
                  if splitEmpty then
                    table.remove(splitEmpty, (FindInTableIf(splitEmpty, function(a) return a.bagID == info.bagID and a.slotID == info.slotID end)))
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  local activeLayouts

  if container.isLive then
    local layoutIndex = 1
    -- Ensure we don't overflow the preallocated buttons by returning all
    -- buttons no longer needed by a particular group
    for index, details in pairs(composed.details) do
      if details.results then
        container.LiveLayouts[layoutIndex]:DeallocateUnusedButtons(details.results)
        layoutIndex = layoutIndex + 1
      end
    end
    if #container.LiveLayouts > layoutCount then
      for index = layoutCount + 1, #container.LiveLayouts do
        container.LiveLayouts[index]:DeallocateUnusedButtons({})
        container.LiveLayouts[index]:Hide()
      end
    end
    for _, layout in ipairs(container.CachedLayouts) do
      layout:Hide()
    end
    activeLayouts = container.LiveLayouts
  else
    if #container.CachedLayouts > layoutCount then
      for index = layoutCount + 1, #container.CachedLayouts do
        container.CachedLayouts[index]:Hide()
      end
    end
    for _, layout in ipairs(container.LiveLayouts) do
      layout:Hide()
    end
    activeLayouts = container.CachedLayouts
  end

  local layoutsShown, activeLabels = {}, {}
  local inactiveSections = {}
  local layoutOffset = 0
  for index, details in ipairs(composed.details) do
    layoutOffset = layoutOffset - 1
    if details.type == "divider" then
      if inactiveSections[details.section] then
        table.insert(layoutsShown, {}) -- {} causes the packing code to ignore this
      else
        table.insert(layoutsShown, (self.dividerPool:Acquire()))
        layoutsShown[#layoutsShown].type = details.type
      end
    elseif details.type == "section" then
      -- Check whether the section has any non-empty items in it
      local any = false
      if index < #composed.details then
        for i = index + 1, #composed.details do
          local d = composed.details[i]
          if d.section ~= details.label then
            break
          elseif d.type == "category" and d.any then
            any = true
            break
          end
        end
      end
      inactiveSections[details.label] = not any -- saved to hide any inside dividers
      if any then
        local button = self.sectionButtonPool:Acquire()
        button:SetText(details.label)
        if sectionToggled[details.label] then
          button:SetCollapsed()
        else
          button:SetExpanded()
        end
        button:SetScript("OnClick", function()
          local sectionToggled = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)
          sectionToggled[details.label] = not sectionToggled[details.label]
          addonTable.Config.Set(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED, CopyTable(sectionToggled))
        end)
        table.insert(layoutsShown, button)
        button.type = details.type
      else
        table.insert(layoutsShown, {}) -- {} causes the packing code to ignore this
      end
    elseif details.type == "category" then
      layoutOffset = layoutOffset + 1
      local searchResults = details.results
      local layout = activeLayouts[index + layoutOffset]
      layout:ShowGroup(details.results, math.min(bagWidth, #details.results), details.source)
      table.insert(layoutsShown, layout)
      layout.section = details.section
      local label = self.labelsPool:Acquire()
      addonTable.Skins.AddFrame("CategoryLabel", label)
      label:SetText(details.label)
      label.categorySearch = index
      activeLabels[index] = label
      layout.type = details.type
    else
      error("unrecognised layout type")
    end
  end
  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("category group show", debugprofilestop() - start2)
  end

  local left = sideSpacing + addonTable.Constants.ButtonFrameOffset - 2
  local right = sideSpacing
  return addonTable.CategoryViews.PackSimple(layoutsShown, activeLabels, left, -50 - topSpacing / 4, bagWidth, addonTable.CategoryViews.Constants.MinWidth - left - right)
end

function addonTable.CategoryViews.BagLayoutMixin:Layout(allBags, bagWidth, bagTypes, bagIndexes, sideSpacing, topSpacing, callback)
  local container = self:GetParent()
  local s1 = debugprofilestop()

  local emptySlotsByType, emptySlotsOrder, everything = {}, {}, {}
  for index, bagID in ipairs(bagIndexes) do
    if allBags[index] then
      local result = Prearrange(container.isLive, bagID, allBags[index], bagTypes[index])
      -- Optimisations
      local everythingIndex = #everything + 1
      for _, item in ipairs(result.everything) do
        everything[everythingIndex] = item
        everythingIndex = everythingIndex + 1
      end
      if #result.emptySlots > 0 then
        if not emptySlotsByType[bagTypes[index]] then
          emptySlotsByType[bagTypes[index]] = {}
          table.insert(emptySlotsOrder, bagTypes[index])
        end
        -- Optimisations
        local emptySlotsTyped = emptySlotsByType[bagTypes[index]]
        local emptySlotIndex = #emptySlotsTyped + 1
        for _, item in ipairs(result.emptySlots) do
          emptySlotsTyped[emptySlotIndex] = item
          emptySlotIndex = emptySlotIndex + 1
        end
      end
    end
  end
  self.updatedBags = {}

  local composed = addonTable.CategoryViews.ComposeCategories(everything)

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("prearrange", debugprofilestop() - s1)
  end

  local s2 = debugprofilestop()
  self.ItemsPreparation:PrepareItems(everything, function()
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("prep", debugprofilestop() - s2)
    end
    self.CategoryFilter:ApplySearches(composed, everything, function()
      self.CategoryGrouping:ApplyGroupings(composed, function()
        self.CategorySort:ApplySorts(composed, function()
          local s3 = debugprofilestop()
          self.ItemsPreparation:CleanItems(everything)
          if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
            addonTable.Utilities.DebugOutput("clean", debugprofilestop() - s3)
          end
          local s4 = debugprofilestop()
          local maxWidth, maxHeight = self:Display(bagWidth, bagIndexes, bagTypes, composed, emptySlotsOrder, emptySlotsByType, bagWidth, sideSpacing, topSpacing)

          callback(maxWidth, maxHeight)
        end)
      end)
    end)
  end)
end
