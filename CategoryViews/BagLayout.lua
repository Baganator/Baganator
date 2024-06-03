local addonName, addonTable = ...

local linkMap = {}
local activeLayoutOffset = 1

function Baganator.CategoryViews.LayoutContainers(self, allBags, containerType, bagIndexes, sideSpacing, topSpacing, callback)
  local s1 = debugprofilestop()

  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)

  local composed = Baganator.CategoryViews.ComposeCategories()

  local searches, searchLabels, priority, customSearches, customCategories, attachedItems, categoryKeys =
    composed.searches, composed.searchLabels, composed.priorities, composed.customSearches, composed.customCategories, composed.attachedItems, composed.categoryKeys

  while #self.LiveLayouts < #searches + activeLayoutOffset do -- +1 for the extra category added when removing a category item
    table.insert(self.LiveLayouts, CreateFrame("Frame", nil, self, "BaganatorLiveCategoryLayoutTemplate"))
    if self.liveItemButtonPool then
      self.LiveLayouts[#self.LiveLayouts]:SetPool(self.liveItemButtonPool)
    end
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
    self.LiveLayouts[1].buttons[1].isBag = true
    self.CachedLayouts[1]:ShowGroup({{bagID = 1, slotID = 0}}, 1)
    self.CachedLayouts[1].buttons[1].isBag = true
  end

  local prioritisedSearches = CopyTable(searches)
  table.sort(prioritisedSearches, function(a, b) return priority[a] > priority[b] end)

  local junkPluginID = Baganator.Config.Get("junk_plugin")
  local junkPlugin = addonTable.JunkPlugins[junkPluginID] and addonTable.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end

  local emptySlots = {}
  local emptySlotCount = 0
  local everything = {}
  for bagIndex, bag in ipairs(allBags) do
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
          info.setInfo = Baganator.ItemViewCommon.GetEquipmentSetInfo(location, info.itemLink)
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
        info.key = Baganator.ItemViewCommon.Utilities.GetCategoryDataKeyNoCount(info) .. tostring(info.guid)
        table.insert(everything, info)
      else
        if bagID ~= Enum.BagIndex.Keyring then
          emptySlotCount = emptySlotCount + 1
        end
        if not emptySlots[bagID] then
          emptySlots[bagID] = slotIndex
        end
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("prearrange", debugprofilestop() - s1)
  end

  self.MultiSearch:ApplySearches(prioritisedSearches, attachedItems, everything, function(results)
    self.labelsPool:ReleaseAll()
    self.dividerPool:ReleaseAll()
    self.results = results

    local start2 = debugprofilestop()
    local bagWidth
    if containerType == "bags" then
      bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)
    elseif containerType == "bank" then
      bagWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)
    elseif containerType == "warband" then
      bagWidth = Baganator.Config.Get(Baganator.Config.Options.WARBAND_BANK_VIEW_WIDTH)
    end

    self.notShown = {}
    local anyResults = false
    for searchTerm, details in pairs(results) do
      local entries = {}
      if self.isGrouping then
        local entriesByKey = {}
        for _, item in ipairs(details) do
          anyResults = true
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
      activeLayouts = self.CachedLayouts
    end

    local layoutsShown, activeLabels = {}, {}
    for searchTerm, details in pairs(results) do
      activeLayouts[details.index + activeLayoutOffset]:ShowGroup(details.all, math.min(bagWidth, #details.all), categoryKeys[searchTerm])
      layoutsShown[details.index] = activeLayouts[details.index + activeLayoutOffset]
      local label = self.labelsPool:Acquire()
      label:SetText(searchLabels[details.index])
      label.categorySearch = searches[details.index]
      activeLabels[details.index] = label
    end
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("category group show", debugprofilestop() - start2)
    end

    if emptySlotCount ~= 0 or Baganator.Constants.IsEra then
      local bagID, slotID = next(emptySlots)
      table.insert(layoutsShown, activeLayouts[1])
      activeLayouts[1].buttons[1]:GetParent():SetID(bagID)
      activeLayouts[1].buttons[1]:SetID(slotID)
      activeLayouts[1].buttons[1].emptySlots = emptySlots
      SetItemButtonCount(activeLayouts[1].buttons[1], emptySlotCount)
      if emptySlotCount == 0 then -- Keyring
        activeLayouts[1].buttons[1].Count:SetText(CreateTextureMarkup(Baganator.Constants.ContainerKeyToInfo.keyring.value, 16, 16, 12, 16, 0, 1, 0, 1))
        activeLayouts[1].buttons[1].Count:Show()
      end
      local label = self.labelsPool:Acquire()
      label.categorySearch = nil
      label:SetText(BAGANATOR_L_EMPTY)
      table.insert(activeLabels, label)
    else
      activeLayouts[1]:Hide()
    end

    local maxWidth, maxHeight = Baganator.CategoryViews.PackSimple(layoutsShown, activeLabels, sideSpacing + Baganator.Constants.ButtonFrameOffset - 2, -50 - topSpacing / 4, bagWidth, composed.dividerPoints, self.dividerPool)

    callback(maxWidth, maxHeight)

    Baganator.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
