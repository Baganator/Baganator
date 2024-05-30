local addonName, addonTable = ...

local linkMap = {}
local activeLayoutOffset = 1

function Baganator.CategoryViews.LayoutContainers(self, character, containerType, bagIndexes, sideSpacing, topSpacing, callback)
  local s1 = debugprofilestop()

  local searches, searchLabels, priority = {}, {}, {}

  local customSearches = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  local attachedItems = {}
  local categoryKeys = {}
  for index, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      table.insert(searches, category.search)
      table.insert(searchLabels, category.name)
      priority[category.search] = category.searchPriority
      customSearches[category.search] = false
      categoryKeys[category.search] = categoryKeys[category.search] or category.source
    end
    category = customCategories[source]
    if category then
      local search = category.search:lower()
      if search == "" then
        search = "________" .. index
      end
      table.insert(searches, search)
      table.insert(searchLabels, category.name)
      priority[search] = category.searchPriority
      customSearches[search] = customSearches[search] == nil
      categoryKeys[search] = categoryKeys[search] or category.name
      if category.addedItems and next(category.addedItems) then
        attachedItems[search] = {}
        for _, details in ipairs(category.addedItems) do
          if details.itemID then
            attachedItems[search]["i:" .. details.itemID] = true
          elseif details.petID then
            attachedItems[search]["p:" .. details.petID] = true
          end
        end
      end
    end
  end

  while #self.LiveLayouts < #searches + activeLayoutOffset do -- +1 for the extra category added when removing a category item
    table.insert(self.LiveLayouts, CreateFrame("Frame", nil, self, "BaganatorLiveCategoryLayoutTemplate"))
    table.insert(self.CachedLayouts, CreateFrame("Frame", nil, self, "BaganatorCachedCategoryLayoutTemplate"))
  end

  if not self.setupEmptyLayouts then
    self.setupEmptyLayouts = true

    self.LiveLayouts[1]:ShowGroup({{bagID = 1, slotID = 0}}, 1)
    self.LiveLayouts[1].buttons[1]:HookScript("OnEnter", function(self)
      local cursorType, itemID = GetCursorInfo()
      if cursorType == "item" then
        local usageChecks = Baganator.Sorting.GetBagUsageChecks(bagIndexes)
        local sortedBagIDs = CopyTable(bagIndexes)
        table.sort(sortedBagIDs, function(a, b) return usageChecks.sortOrder[a] < usageChecks.sortOrder[b] end)
        local any = false
        for _, bagID in ipairs(sortedBagIDs) do
          if self.emptySlots[bagID] and (not usageChecks.checks[bagID] or usageChecks.checks[bagID]({itemID = itemID})) then
            any = true
            self:GetParent():SetID(bagID)
            self:SetID(self.emptySlots[bagID])
          end
        end
        if not any then
          local bagID, slotID = next(self.emptySlots)
          self:GetParent():SetID(bagID)
          self:SetID(slotID)
        end
      end
    end)
    self.CachedLayouts[1]:ShowGroup({{bagID = 1, slotID = 0}}, 1)
  end

  local prioritisedSearches = CopyTable(searches)
  table.sort(prioritisedSearches, function(a, b) return priority[a] > priority[b] end)

  local characterData = Syndicator.API.GetCharacter(character)

  local junkPluginID = Baganator.Config.Get("junk_plugin")
  local junkPlugin = addonTable.JunkPlugins[junkPluginID] and addonTable.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end

  local emptySlots = {}
  local emptySlotCount = 0
  local everything = {}
  for bagIndex, bag in ipairs(characterData[containerType]) do
    local bagID = bagIndexes[bagIndex]
    if not bagID then -- Avoid errors from bags removed from the possible indexes
      break
    end
    for slotIndex, slot in ipairs(bag) do
      local info = Syndicator.Search.GetBaseInfo(slot)
      if self.isLive then
        if Baganator.Constants.IsClassic then
          info.tooltipGetter = function() return Syndicator.Search.DumpClassicTooltip(function(tooltip) tooltip:SetBagItem(bagID, slotIndex) end) end
        else
          info.tooltipGetter = function() return C_TooltipInfo.GetBagItem(bagID, slotIndex) end
        end
        info.isJunkGetter = function() return junkPlugin and junkPlugin(bagID, slotIndex, info.itemID, info.itemLink) == true end
        if info.itemID ~= nil then
          local location = {bagID = bagID, slotIndex = slotIndex}
          info.setInfo = Baganator.ItemViewCommon.GetEquipmentSetInfo(location)
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
        table.insert(everything, info)
      else
        if not emptySlots[bagID] then
          emptySlots[bagID] = slotIndex
        end
        emptySlotCount = emptySlotCount + 1
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("prearrange", debugprofilestop() - s1)
  end

  self.MultiSearch:ApplySearches(prioritisedSearches, attachedItems, everything, function(results)
    self.labelsPool:ReleaseAll()

    local start2 = debugprofilestop()
    local bagWidth
    if containerType == "bags" then
      bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)
    else
      bagWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)
    end

    local anyResults = false
    for searchTerm, details in pairs(results) do
      local entries = {}
      if self.isGrouping then
        local entriesByKey = {}
        for _, item in ipairs(details) do
          anyResults = true
          local groupingKey = Baganator.ItemViewCommon.Utilities.GetCategoryDataKeyNoCount(item)
          if entriesByKey[groupingKey] then
            entriesByKey[groupingKey].itemCount = entriesByKey[groupingKey].itemCount + item.itemCount
          else
            entriesByKey[groupingKey] = item
            table.insert(entries, item)
          end
        end
      else
        anyResults = anyResults or #details > 0
        entries = details
      end
      if self.isLive and self.addToCategoryMode and customSearches[searchTerm] then
        if self.addToCategoryMode ~= categoryKeys[searchTerm] then
          table.insert(entries, {isDummy = true, label = BAGANATOR_L_ADD_TO_CATEGORY, dummyType = "add"})
        else
          table.insert(entries, {isDummy = true, label = BAGANATOR_L_REMOVE_FROM_CATEGORY, dummyType = "remove"})
        end
      end
      results[searchTerm] = {all = entries, index = tIndexOf(searches, searchTerm)}
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
      activeLayouts = self.CachedLayouts
    end

    local layoutsShown = {}
    for searchTerm, details in pairs(results) do
      activeLayouts[details.index + activeLayoutOffset]:ShowGroup(details.all, math.min(bagWidth, #details.all), categoryKeys[searchTerm])
      layoutsShown[details.index] = activeLayouts[details.index + activeLayoutOffset]
    end
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("category group show", debugprofilestop() - start2)
    end

    if emptySlotCount ~= 0 then
      local bagID, slotID = next(emptySlots)
      table.insert(layoutsShown, activeLayouts[1])
      activeLayouts[1].buttons[1]:GetParent():SetID(bagID)
      activeLayouts[1].buttons[1]:SetID(slotID)
      activeLayouts[1].buttons[1].emptySlots = emptySlots
      SetItemButtonCount(activeLayouts[1].buttons[1], emptySlotCount)
      table.insert(searchLabels, BAGANATOR_L_EMPTY)
    end

    local maxWidth, maxHeight = Baganator.CategoryViews.PackSimple(layoutsShown, self.labelsPool, searchLabels, sideSpacing + Baganator.Constants.ButtonFrameOffset, -50 - topSpacing / 4, bagWidth)

    callback(maxWidth, maxHeight)

    Baganator.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
