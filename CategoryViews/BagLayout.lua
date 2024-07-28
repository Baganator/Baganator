local _, addonTable = ...
local addonName, addonTable = ...

local linkMap = {}
local activeLayoutOffset = 1

local function Prearrange(isLive, bagID, bag, bagType)
  local junkPluginID = addonTable.Config.Get("junk_plugin")
  local junkPlugin = addonTable.API.JunkPlugins[junkPluginID] and addonTable.API.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end

  local emptySlotCount = 0
  local emptySlotsOrder
  local everything = {}
  if not bagID then -- Avoid errors from bags removed from the possible indexes
    return {emptySlotCount = 0, emptySlotsOrder = nil, everything = {}, bagType = bagType}
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
      if not emptySlotsOrder then
        emptySlotsOrder = {bagID = bagID, slotID = slotIndex, bagType = bagType}
      end
      emptySlotCount = emptySlotCount + 1
    end
  end

  return {emptySlotCount = emptySlotCount, emptySlotsOrder = emptySlotsOrder, everything = everything}
end

local function GetKeySummary(byBagData)
  local summary = {}
  for _, data in pairs(byBagData) do
    for _, item in ipairs(data.everything) do
      summary[item.key] = summary[item.key] or { itemCount = 0, location = {}, items = {}}
      summary[item.key].itemCount = summary[item.key].itemCount + item.itemCount
      summary[item.key].location[item.bagID .. " " .. item.slotID] = true
      table.insert(summary[item.key].items,  item)
    end
  end

  return summary
end

local function DisplayResults(self, toRefresh, containerType, composed, emptySlotCount, emptySlotsOrder, sideSpacing, topSpacing)
  self.labelsPool:ReleaseAll()
  self.dividerPool:ReleaseAll()
  self.sectionButtonPool:ReleaseAll()
  local oldRenderResults = self.oldRenderResults
  local results = {}
  self.oldRenderResults = results

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
  for searchTerm in pairs(toRefresh) do
    local details = CopyTable(self.results[searchTerm], 2)
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
          entriesByKey[groupingKey] = Syndicator.Search.GetBaseInfo(item)
          table.insert(entries, item)
        end
      end
    else
      entries = details
    end
    if self.isLive and self.addToCategoryMode and addonTable.Config.Get(addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS) and not composed.autoSearches[searchTerm] then
      if self.addToCategoryMode ~= composed.categoryKeys[searchTerm] then
        table.insert(entries, {isDummy = true, label = BAGANATOR_L_ADD_TO_CATEGORY, dummyType = "add"})
      else
        if self.addedToFromCategory then
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
    results[searchTerm].oldLength = #results[searchTerm].all
  end

  for search, details in pairs(oldRenderResults or {}) do
    if not results[search] then
      results[search] = details
    end
  end

  if self.splitStacksDueToTransfer and oldRenderResults then
    local anyNew = false
    for search, r in pairs(oldRenderResults) do
      if r.oldLength and r.oldLength < #results[search].all then
        anyNew = true
      end
    end
    if not anyNew and not self.addToCategoryMode then
      for search, r in pairs(oldRenderResults) do
        if #r.all > #results[search].all then
          for index, info in ipairs(r.all) do
            if info.bagID and info.slotID and not C_Item.DoesItemExist({bagID = info.bagID, slotIndex = info.slotID}) then
              table.insert(results[search].all, index, {bagID = info.bagID, slotID = info.slotID, key = ""})
            end
          end
        end
      end
    elseif anyNew then
      for search, r in pairs(results) do
        if #r.all > 0 then
          for i = #r.all, 1, -1 do
            if r.all[i].itemLink == nil then
              table.remove(r.all, i)
            end
          end
        end
      end
    end
  end

  local activeLayouts

  if self.isLive then
    -- Ensure we don't overflow the preallocated buttons by returning all
    -- buttons no longer needed by a particular group
    for searchTerm, details in pairs(results) do
      self.LiveLayouts[details.index + activeLayoutOffset]:DeallocateUnusedButtons(details.all)
    end
    if #self.LiveLayouts > #composed.searches + activeLayoutOffset then
      for index = #composed.searches + activeLayoutOffset + 1, #self.LiveLayouts do
        self.LiveLayouts[index]:DeallocateUnusedButtons({})
        self.LiveLayouts[index]:Hide()
      end
    end
    self.LiveLayouts[1]:DeallocateUnusedButtons(emptySlotsOrder)
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
          elseif (d.type == "category" and results[d.search].any) or (d.type == "empty slots category" and #emptySlotsOrder > 0) then
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
    elseif details.type == "empty slots category" then
      table.insert(layoutsShown, activeLayouts[1])
      if #emptySlotsOrder == 0 or hidden[addonTable.CategoryViews.Constants.EmptySlotsCategory] or sectionToggled[details.section] then
        activeLayouts[1]:ShowGroup({}, 1)
      else
        activeLayouts[1]:ShowGroup(emptySlotsOrder, math.min(#emptySlotsOrder, bagWidth))
      end
      activeLayouts[1].section = details.section
      activeLayouts[1].type = "category"
      for index, button in ipairs(activeLayouts[1].buttons) do
        local bagType = emptySlotsOrder[index].bagType
        button.isBag = true -- Ensure even counts of 1 are shown
        SetItemButtonCount(button, emptySlotCount[bagType])
        button.Count:SetShown(bagType ~= "keyring") -- Keyrings have unlimited size
        if not button.bagTypeIcon then
          button.bagTypeIcon = button:CreateTexture(nil, "OVERLAY")
          button.bagTypeIcon:SetSize(20, 20)
          button.bagTypeIcon:SetPoint("CENTER")
          button.bagTypeIcon:SetDesaturated(true)
          button.UpdateTooltip = nil -- Prevents the tooltip hiding immediately
          button:SetScript("OnEnter", function()
            if button.tooltipHeader then
              GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
              GameTooltip:SetText(button.tooltipHeader)
            end
          end)
          button:SetScript("OnLeave", function()
            GameTooltip:Hide()
          end)
        end
        local details = addonTable.Constants.ContainerKeyToInfo[bagType]
        if details then
          if details.type == "atlas" then
            button.bagTypeIcon:SetAtlas(details.value)
          else
            button.bagTypeIcon:SetTexture(details.value)
          end
          button.tooltipHeader = details.tooltipHeader
        else
          print("missing")
          button.bagTypeIcon:SetTexture(nil)
          button.tooltipHeader = nil
        end
      end
      local label = self.labelsPool:Acquire()
      addonTable.Skins.AddFrame("CategoryLabel", label)
      label.categorySearch = nil
      label:SetText(BAGANATOR_L_EMPTY)
      activeLabels[details.index] = label
      activeLayouts[1]:Show()
    else
      error("unrecognised layout type")
    end
  end
  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    print("category group show", debugprofilestop() - start2)
  end

  local left = sideSpacing + addonTable.Constants.ButtonFrameOffset - 2
  local right = sideSpacing
  return addonTable.CategoryViews.PackSimple(layoutsShown, activeLabels, left, -50 - topSpacing / 4, bagWidth, addonTable.CategoryViews.Constants.MinWidth - left - right)
end

function addonTable.CategoryViews.LayoutContainers(self, allBags, containerType, bagTypes, bagIndexes, sideSpacing, topSpacing, callback)
  local s1 = debugprofilestop()

  self.byBagData = self.byBagData or {}

  for index, bagID in ipairs(bagIndexes) do
    if self.updatedBags[bagID] or not self.byBagData[bagID] then
      self.byBagData[bagID] = Prearrange(self.isLive, bagID, allBags[index], bagTypes[index])
    end
  end
  self.updatedBags = {}

  local everything = {}
  for _, data in pairs(self.byBagData) do
    tAppendAll(everything, data.everything)
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    print("prearrange", debugprofilestop() - s1)
    s1 = debugprofilestop()
  end

  local composed = addonTable.CategoryViews.ComposeCategories(everything)

  local summary = GetKeySummary(self.byBagData)
  local toProcess = {}
  local reshowSearches = {}
  if self.results then
    for search, results in pairs(self.results) do
      local attachments = composed.attachedItems[search]
      local oldAttachments = self.oldComposed.attachedItems[search]
      for i = #results, 1, -1 do
        local item = results[i]
        local match = attachments and (attachments["i:" .. tostring(item.itemID)] or attachments["p:" .. tostring(item.petID)] or attachments[key])
        local oldMatch = oldAttachments and (oldAttachments["i:" .. tostring(item.itemID)] or oldAttachments["p:" .. tostring(item.petID)] or oldAttachments[key])
        if not summary[item.key] or not self.oldSummary[item.key] or summary[item.key].itemCount ~= self.oldSummary[item.key].itemCount or not summary[item.key].location[item.bagID .. " " .. item.slotID] or (oldMatch and not match) or item.isDummy then
          reshowSearches[search] = true
          self.oldSummary[item.key] = nil
          table.remove(results, i)
        end
      end
    end

    for key, details in pairs(summary) do
      if not self.oldSummary[key] or self.oldSummary[key].itemCount ~= summary[key].itemCount then
        tAppendAll(toProcess, details.items)
      end
    end
  else
    self.results = {}
    toProcess = everything
  end

  self.oldComposed = composed
  self.oldSummary = summary

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    print("shuffle", debugprofilestop() - s1)
    s1 = debugprofilestop()
  end

  while #self.LiveLayouts < #composed.searches + activeLayoutOffset do -- +1 for the extra category added when removing a category item
    table.insert(self.LiveLayouts, CreateFrame("Frame", nil, self, "BaganatorLiveCategoryLayoutTemplate"))
    if self.liveItemButtonPool then
      self.LiveLayouts[#self.LiveLayouts]:SetPool(self.liveItemButtonPool)
    end
    table.insert(self.CachedLayouts, CreateFrame("Frame", nil, self, "BaganatorCachedCategoryLayoutTemplate"))
  end

  if not self.setupEmptyLayouts then
    self.setupEmptyLayouts = true

    if self.liveEmptySlotsPool then
      self.LiveLayouts[1]:SetPool(self.liveEmptySlotsPool)
    end
  end

  self.CategoryFilter:ApplySearches(composed.prioritisedSearches, composed.attachedItems, toProcess, function(results)
    local altered = {}
    for search, r in pairs(results) do
      if not self.results[search] then
        self.results[search] = r
      else
        tAppendAll(self.results[search], r)
      end
      if #r > 0 then
        altered[search] = self.results[search]
      end
    end
    self.CategorySort:ApplySorts(altered, function(results)
      for search, r in pairs(results) do
        self.results[search] = r
      end
      local emptySlotCount, emptySlotsOrder = {}, {}
      local seenTypes = {}
      for _, bagID in ipairs(bagIndexes) do
        local data = self.byBagData[bagID]
        if data.emptySlotsOrder then
          if not seenTypes[data.emptySlotsOrder.bagType] then
            table.insert(emptySlotsOrder, data.emptySlotsOrder)
            seenTypes[data.emptySlotsOrder.bagType] = true
          end
          emptySlotCount[data.emptySlotsOrder.bagType] = (emptySlotCount[data.emptySlotsOrder.bagType] or 0) + data.emptySlotCount
        end
      end
      local toRefresh = {}
      for search in pairs(results) do
        toRefresh[search] = true
      end
      if not self.oldRenderResults then
        toRefresh = self.results
      end
      Mixin(toRefresh, reshowSearches)
      local maxWidth, maxHeight = DisplayResults(self, toRefresh, containerType, composed, emptySlotCount, emptySlotsOrder, sideSpacing, topSpacing)

      callback(maxWidth, maxHeight)

      addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
    end)
  end)
end
