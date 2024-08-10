local _, addonTable = ...
local addonName, addonTable = ...

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
        info.tooltipGetter = function() return Syndicator.Search.DumpClassicTooltip(function(tooltip) tooltip:SetBagItem(bagID, slotIndex) end) end
      else
        info.tooltipGetter = function() return C_TooltipInfo.GetBagItem(bagID, slotIndex) end
      end
      info.isJunkGetter = function() return junkPlugin and junkPlugin(bagID, slotIndex, info.itemID, info.itemLink) == true end
      if info.itemID ~= nil then
        local location = {bagID = bagID, slotIndex = slotIndex}
        info.setInfo = addonTable.ItemViewCommon.GetEquipmentSetInfo(location, info.itemLink)
        if info.setInfo then
          info.guid = C_Item.GetItemGUID(location)
        end
      end
    end
    if info.itemID then
      info.guid = info.guid or ""
      info.iconTexture = slot.iconTexture
      info.keyLink = linkMap[info.itemLink]
      if not info.keyLink then
        info.keyLink = info.itemLink:gsub("(item:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)%d+:", "%1:")
        linkMap[info.itemLink] = info.keyLink
      end
      info.bagID = bagID
      info.slotID = slotIndex
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
end

function addonTable.CategoryViews.BagLayoutMixin:OnHide()
  for _, item in ipairs(self.notShown) do
    addonTable.NewItems:ClearNewItem(item.bagID, item.slotID)
  end
end

function addonTable.CategoryViews.BagLayoutMixin:OnShow()
  self.results = nil
end

function addonTable.CategoryViews.BagLayoutMixin:NewCharacter()
  self.results = nil
end

function addonTable.CategoryViews.BagLayoutMixin:SettingChanged(settingName)
  if tIndexOf(addonTable.CategoryViews.Constants.ClearCachesSettings, settingName) ~= nil then
    self.ItemsPreparation:ResetCaches()
    self.CategoryFilter:ResetCaches()
  end
  self.results = nil
end

function addonTable.CategoryViews.BagLayoutMixin:FullRefresh()
  self.CategoryFilter:ResetCaches()
  self.ItemsPreparation:ResetCaches()
  self.results = nil
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

function addonTable.CategoryViews.BagLayoutMixin:Display(bagWidth, bagIndexes, bagTypes, composed, results, emptySlotsOrder, emptySlotsByType, bagWidth, sideSpacing, topSpacing)
  local container = self:GetParent()

  local start2 = debugprofilestop()

  self.labelsPool:ReleaseAll()
  self.dividerPool:ReleaseAll()
  self.sectionButtonPool:ReleaseAll()

  local emptyDetails = FindValueInTableIf(composed.details, function(a) return a.emptySlots end)
  local splitEmpty, emptySearch = nil, nil
  if emptyDetails then
    emptySearch = emptyDetails.search
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
    results[emptyDetails.search] = slots
  end

  local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
  local sectionToggled = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)

  self.notShown = {}
  for searchTerm, details in pairs(results) do
    local entries = {}
    if container.isGrouping and searchTerm ~= emptySearch then
      local entriesByKey = {}
      for _, item in ipairs(details) do
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
      entries = details
    end
    if container.isLive and container.addToCategoryMode and addonTable.Config.Get(addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS) and not composed.autoSearches[searchTerm] then
      if container.addToCategoryMode ~= composed.categoryKeys[searchTerm] then
        table.insert(entries, {isDummy = true, label = BAGANATOR_L_ADD_TO_CATEGORY, dummyType = "add"})
      else
        if container.addedToFromCategory then
          table.insert(entries, {isDummy = true, label = BAGANATOR_L_REMOVE_FROM_CATEGORY, dummyType = "remove"})
        end
      end
    end
    local index = tIndexOf(composed.searches, searchTerm)
    results[searchTerm] = {all = entries, index = index, any = #entries > 0 }
    if hidden[composed.categoryKeys[searchTerm]] or sectionToggled[composed.section[index]] then
      for _, entry in ipairs(results[searchTerm].all) do
        table.insert(self.notShown, entry)
      end
      results[searchTerm].all = {}
    end
  end

  local oldResults = self.results
  self.results = results
  if oldResults then
    local anyNew = false
    for search, r in pairs(oldResults) do
      if search ~= emptySearch and r.oldLength and r.oldLength < #results[search].all then
        anyNew = true
      end
    end
    if not anyNew and not container.addToCategoryMode then
      local typeMap = {}
      for index, bagType in ipairs(bagTypes) do
        typeMap[bagIndexes[index]] = bagType
      end
      for search, r in pairs(oldResults) do
        results[search].oldLength = #results[search].all
        if #r.all > #results[search].all and search ~= emptySearch then
          for index, info in ipairs(r.all) do
            if info.bagID and info.slotID and not C_Item.DoesItemExist({bagID = info.bagID, slotIndex = info.slotID}) then
              table.insert(results[search].all, index, {bagID = info.bagID, slotID = info.slotID, itemCount = 0, keyLink = typeMap[info.bagID], bagType = typeMap[info.bagID]})
              if splitEmpty then
                table.remove(splitEmpty, (FindInTableIf(splitEmpty, function(a) return a.bagID == info.bagID and a.slotID == info.slotID end)))
              end
            end
          end
        end
      end
    end
  end

  local activeLayouts

  if container.isLive then
    -- Ensure we don't overflow the preallocated buttons by returning all
    -- buttons no longer needed by a particular group
    for searchTerm, details in pairs(results) do
      container.LiveLayouts[details.index]:DeallocateUnusedButtons(details.all)
    end
    if #container.LiveLayouts > #composed.searches then
      for index = #composed.searches + 1, #container.LiveLayouts do
        container.LiveLayouts[index]:DeallocateUnusedButtons({})
        container.LiveLayouts[index]:Hide()
      end
    end
    for _, layout in ipairs(container.CachedLayouts) do
      layout:Hide()
    end
    activeLayouts = container.LiveLayouts
  else
    if #container.CachedLayouts > #composed.searches then
      for index = #composed.searches + 1, #container.CachedLayouts do
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
  for index, details in ipairs(composed.details) do
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
          elseif (d.type == "category" and results[d.search].any) then
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
      local searchResults = results[details.search]
      local layout = activeLayouts[searchResults.index]
      layout:ShowGroup(searchResults.all, math.min(bagWidth, #searchResults.all), details.source)
      table.insert(layoutsShown, layout)
      layout.section = details.section
      local label = self.labelsPool:Acquire()
      addonTable.Skins.AddFrame("CategoryLabel", label)
      label:SetText(details.label)
      label.categorySearch = details.search
      activeLabels[details.index] = label
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

  while #container.LiveLayouts < #composed.searches do
    table.insert(container.LiveLayouts, CreateFrame("Frame", nil, container, "BaganatorLiveCategoryLayoutTemplate"))
    if container.liveItemButtonPool then
      container.LiveLayouts[#container.LiveLayouts]:SetPool(container.liveItemButtonPool)
    end
    table.insert(container.CachedLayouts, CreateFrame("Frame", nil, container, "BaganatorCachedCategoryLayoutTemplate"))
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("prearrange", debugprofilestop() - s1)
  end

  local s2 = debugprofilestop()
  self.ItemsPreparation:PrepareItems(everything, function()
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("prep", debugprofilestop() - s2)
    end
    self.CategoryFilter:ApplySearches(composed.prioritisedSearches, composed.attachedItems, everything, function(results)
      self.CategorySort:ApplySorts(results, function(results)
        local s3 = debugprofilestop()
        self.ItemsPreparation:CleanItems(everything)
        if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
          addonTable.Utilities.DebugOutput("clean", debugprofilestop() - s3)
        end
        local s4 = debugprofilestop()
        local maxWidth, maxHeight = self:Display(bagWidth, bagIndexes, bagTypes, composed, results, emptySlotsOrder, emptySlotsByType, bagWidth, sideSpacing, topSpacing)

        callback(maxWidth, maxHeight)
      end)
    end)
  end)
end
