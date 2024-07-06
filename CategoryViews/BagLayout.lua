local addonName, addonTable = ...

local linkMap = {}
local activeLayoutOffset = 1

local function PrearrangeEverything(self, allBags, bagIndexes, bagTypes)
  local junkPluginID = Baganator.Config.Get("junk_plugin")
  local junkPlugin = addonTable.JunkPlugins[junkPluginID] and addonTable.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end

  local emptySlotCount = {}
  local emptySlotsOrder = {}
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
        if not emptySlotCount[bagTypes[bagIndex]] then
          emptySlotCount[bagTypes[bagIndex]] =  0
          table.insert(emptySlotsOrder, {bagID = bagID, slotID = slotIndex, key = bagTypes[bagIndex]})
        end
        emptySlotCount[bagTypes[bagIndex]] = emptySlotCount[bagTypes[bagIndex]] + 1
      end
    end
  end

  return emptySlotCount, emptySlotsOrder, everything
end

function Baganator.CategoryViews.LayoutContainers(self, allBags, containerType, bagTypes, bagIndexes, sideSpacing, topSpacing, callback)
  local s1 = debugprofilestop()

  local emptySlotCount, emptySlotsOrder, everything = PrearrangeEverything(self, allBags, bagIndexes, bagTypes)

  local composed = Baganator.CategoryViews.ComposeCategories(everything)

  local searches, searchLabels, priority, autoSearches, attachedItems, categoryKeys, prioritisedSearches =
    composed.searches, composed.searchLabels, composed.priorities, composed.autoSearches, composed.attachedItems, composed.categoryKeys, composed.prioritisedSearches

  while #self.LiveLayouts < #searches + activeLayoutOffset do -- +1 for the extra category added when removing a category item
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

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("prearrange", debugprofilestop() - s1)
  end

  self.MultiSearch:ApplySearches(prioritisedSearches, attachedItems, everything, function(results)
    self.labelsPool:ReleaseAll()
    self.dividerPool:ReleaseAll()
    self.sectionButtonPool:ReleaseAll()
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

    local hidden = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)
    local sectionToggled = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_SECTION_TOGGLED)

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
      if self.isLive and self.addToCategoryMode and not autoSearches[searchTerm] then
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
            local sectionToggled = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_SECTION_TOGGLED)
            sectionToggled[details.label] = not sectionToggled[details.label]
            Baganator.Config.Set(Baganator.Config.Options.CATEGORY_SECTION_TOGGLED, CopyTable(sectionToggled))
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
        Baganator.Skins.AddFrame("CategoryLabel", label)
        label:SetText(details.label)
        label.categorySearch = details.search
        activeLabels[details.index] = label
        layout.type = details.type
      elseif details.type == "empty slots category" then
        table.insert(layoutsShown, activeLayouts[1])
        if #emptySlotsOrder == 0 or hidden[Baganator.CategoryViews.Constants.EmptySlotsCategory] or sectionToggled[details.section] then
          activeLayouts[1]:ShowGroup({}, 1)
        else
          activeLayouts[1]:ShowGroup(emptySlotsOrder, math.min(#emptySlotsOrder, bagWidth))
        end
        activeLayouts[1].section = details.section
        activeLayouts[1].type = "category"
        for index, button in ipairs(activeLayouts[1].buttons) do
          local bagType = emptySlotsOrder[index].key
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
          local details = Baganator.Constants.ContainerKeyToInfo[bagType]
          if details then
            if details.type == "atlas" then
              button.bagTypeIcon:SetAtlas(details.value)
            else
              button.bagTypeIcon:SetTexture(details.value)
            end
            button.tooltipHeader = details.tooltipHeader
          else
            button.bagTypeIcon:SetTexture(nil)
            button.tooltipHeader = nil
          end
        end
        local label = self.labelsPool:Acquire()
        Baganator.Skins.AddFrame("CategoryLabel", label)
        label.categorySearch = nil
        label:SetText(BAGANATOR_L_EMPTY)
        activeLabels[details.index] = label
        activeLayouts[1]:Show()
      else
        error("unrecognised layout type")
      end
    end
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("category group show", debugprofilestop() - start2)
    end

    local left = sideSpacing + Baganator.Constants.ButtonFrameOffset - 2
    local right = sideSpacing
    local maxWidth, maxHeight = Baganator.CategoryViews.PackSimple(layoutsShown, activeLabels, left, -50 - topSpacing / 4, bagWidth, Baganator.CategoryViews.Constants.MinWidth - left - right)

    callback(maxWidth, maxHeight)

    Baganator.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
