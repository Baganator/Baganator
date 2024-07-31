local _, addonTable = ...
local addonName, addonTable = ...

local linkMap = {}
local activeLayoutOffset = 0

local function PrearrangeEverything(self, allBags, bagIndexes, bagTypes)
  local junkPluginID = addonTable.Config.Get("junk_plugin")
  local junkPlugin = addonTable.API.JunkPlugins[junkPluginID] and addonTable.API.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end

  local emptySlotsByType, emptySlotsOrder = {}, {}
  local everything = {}
  for bagIndex, bag in ipairs(allBags) do
    local bagID = bagIndexes[bagIndex]
    if not bagID then -- Avoid errors from bags removed from the possible indexes
      break
    end
    local bagType = bagTypes[bagIndex]
    for slotIndex, slot in ipairs(bag) do
      local info = Syndicator.Search.GetBaseInfo(slot)
      if self.isLive then
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
        if not emptySlotsByType[bagType] then
          emptySlotsByType[bagType] = {}
          table.insert(emptySlotsOrder, bagType)
        end
        table.insert(emptySlotsByType[bagType], {bagID = bagID, itemCount = 1, slotID = slotIndex, key = bagType, bagType = bagType, keyLink = bagType})
      end
    end
  end

  return emptySlotsByType, emptySlotsOrder, everything
end

function addonTable.CategoryViews.LayoutContainers(self, allBags, containerType, bagTypes, bagIndexes, sideSpacing, topSpacing, callback)
  local s1 = debugprofilestop()

  local emptySlotsByType, emptySlotsOrder, everything = PrearrangeEverything(self, allBags, bagIndexes, bagTypes)

  local composed = addonTable.CategoryViews.ComposeCategories(everything)

  local searches, searchLabels, priority, autoSearches, attachedItems, categoryKeys, prioritisedSearches =
    composed.searches, composed.searchLabels, composed.priorities, composed.autoSearches, composed.attachedItems, composed.categoryKeys, composed.prioritisedSearches

  while #self.LiveLayouts < #searches + activeLayoutOffset do -- +1 for the extra category added when removing a category item
    table.insert(self.LiveLayouts, CreateFrame("Frame", nil, self, "BaganatorLiveCategoryLayoutTemplate"))
    if self.liveItemButtonPool then
      self.LiveLayouts[#self.LiveLayouts]:SetPool(self.liveItemButtonPool)
    end
    table.insert(self.CachedLayouts, CreateFrame("Frame", nil, self, "BaganatorCachedCategoryLayoutTemplate"))
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    print("prearrange", debugprofilestop() - s1)
  end

  self.MultiSearch:ApplySearches(prioritisedSearches, attachedItems, everything, function(results)
    self.labelsPool:ReleaseAll()
    self.dividerPool:ReleaseAll()
    self.sectionButtonPool:ReleaseAll()

    local emptyDetails = FindValueInTableIf(composed.details, function(a) return a.emptySlots end)
    local splitEmpty, emptySearch = nil, nil
    if emptyDetails then
      emptySearch = emptyDetails.search
      local slots = {}
      if not addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING) then
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

    local start2 = debugprofilestop()
    local bagWidth
    if containerType == "bags" then
      bagWidth = addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_WIDTH)
    elseif containerType == "bank" then
      bagWidth = addonTable.Config.Get(addonTable.Config.Options.BANK_VIEW_WIDTH)
    elseif containerType == "warband" then
      bagWidth = addonTable.Config.Get(addonTable.Config.Options.WARBAND_BANK_VIEW_WIDTH)
    end

    local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
    local sectionToggled = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)

    self.notShown = {}
    for searchTerm, details in pairs(results) do
      local entries = {}
      if self.isGrouping then
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
      if self.isLive and self.addToCategoryMode and addonTable.Config.Get(addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS) and not autoSearches[searchTerm] then
        if self.addToCategoryMode ~= categoryKeys[searchTerm] then
          table.insert(entries, {isDummy = true, label = BAGANATOR_L_ADD_TO_CATEGORY, dummyType = "add"})
        else
          if self.addedToFromCategory then
            table.insert(entries, {isDummy = true, label = BAGANATOR_L_REMOVE_FROM_CATEGORY, dummyType = "remove"})
          end
        end
      end
      local index = tIndexOf(searches, searchTerm)
      results[searchTerm] = {all = entries, index = index, any = #entries > 0 }
      if hidden[categoryKeys[searchTerm]] or sectionToggled[composed.section[index]] then
        for _, entry in ipairs(results[searchTerm].all) do
          table.insert(self.notShown, entry)
        end
        results[searchTerm].all = {}
      end
    end

    local oldResults = self.results
    if self.splitStacksDueToTransfer and oldResults then
      local anyNew = false
      for search, r in pairs(oldResults) do
        if search ~= emptySearch and r.oldLength and r.oldLength < #results[search].all then
          anyNew = true
        end
      end
      if not anyNew and not self.addToCategoryMode then
        local typeMap = {}
        for index, bagType in ipairs(bagTypes) do
          typeMap[bagIndexes[index]] = bagType
        end
        for search, r in pairs(oldResults) do
          results[search].oldLength = #results[search].all
          if #r.all > #results[search].all then
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
      self.results = results
    elseif self.splitStacksDueToTransfer then
      self.results = results
    else
      self.results = nil
    end

    local activeLayouts

    if self.isLive then
      -- Ensure we don't overflow the preallocated buttons by returning all
      -- buttons no longer needed by a particular group
      for searchTerm, details in pairs(results) do
        self.LiveLayouts[details.index + activeLayoutOffset]:DeallocateUnusedButtons(details.all)
      end
      if #self.LiveLayouts > #searches + activeLayoutOffset then
        for index = #searches + activeLayoutOffset + 1, #self.LiveLayouts do
          self.LiveLayouts[index]:DeallocateUnusedButtons({})
          self.LiveLayouts[index]:Hide()
        end
      end
      for _, layout in ipairs(self.CachedLayouts) do
        layout:Hide()
      end
      activeLayouts = self.LiveLayouts
    else
      for _, layout in ipairs(self.LiveLayouts) do
        layout:Hide()
      end
      if #self.CachedLayouts > #searches + activeLayoutOffset then
        for index = #searches + activeLayoutOffset + 1, #self.CachedLayouts do
          self.CachedLayouts[index]:Hide()
        end
      end
      activeLayouts = self.CachedLayouts
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
        local layout = activeLayouts[searchResults.index + activeLayoutOffset]
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
      print("category group show", debugprofilestop() - start2)
    end

    local left = sideSpacing + addonTable.Constants.ButtonFrameOffset - 2
    local right = sideSpacing
    local maxWidth, maxHeight = addonTable.CategoryViews.PackSimple(layoutsShown, activeLabels, left, -50 - topSpacing / 4, bagWidth, addonTable.CategoryViews.Constants.MinWidth - left - right)

    callback(maxWidth, maxHeight)

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
