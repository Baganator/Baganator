local _, addonTable = ...

local linkMap = {}
local stackable = {}

local function CheckStackable(allBags, callback)
  local waiting, loopComplete = 0, false
  for _, bag in ipairs(allBags) do
    for _, slot in ipairs(bag) do
      if slot.itemID ~= nil and stackable[slot.itemID] == nil then
        if C_Item.IsItemDataCachedByID(slot.itemID) then
          stackable[slot.itemID] = C_Item.GetItemMaxStackSizeByID(slot.itemID) > 1
        else
          waiting = waiting + 1
          addonTable.Utilities.LoadItemData(slot.itemID, function()
            stackable[slot.itemID] = C_Item.GetItemMaxStackSizeByID(slot.itemID) > 1
            waiting = waiting - 1
            if waiting == 0 and loopComplete then
              callback()
            end
          end)
        end
      end
    end
  end
  loopComplete = true
  if waiting == 0 then
    callback()
  end
end

local function Prearrange(isLive, bagID, bag, bagType)
  local junkPluginID = addonTable.Config.Get("junk_plugin")
  local junkPlugin = addonTable.API.JunkPlugins[junkPluginID] and addonTable.API.JunkPlugins[junkPluginID].callback
  if junkPluginID == "poor_quality" then
    junkPlugin = nil
  end
  local upgradePluginID = addonTable.Config.Get("upgrade_plugin")
  local upgradePlugin = addonTable.API.UpgradePlugins[upgradePluginID] and addonTable.API.UpgradePlugins[upgradePluginID].callback

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
      info.isUpgradeGetter = upgradePlugin and function() local _, result = pcall(upgradePlugin, info.itemLink); return result == true end
      info.iconTexture = slot.iconTexture
      info.keyLink = linkMap[info.itemLink]
      if not info.keyLink then
        if stackable[info.itemID] then
          info.keyLink = "item:" .. info.itemID
        else
          info.keyLink = info.itemLink:gsub("(item:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)%d+:", "%1:")
        end
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
  self.labelsPool = CreateFramePool("Button", self:GetParent().Container, "BaganatorCategoryViewsCategoryButtonTemplate")
  self.sectionButtonPool = addonTable.CategoryViews.GetSectionButtonPool(self:GetParent().Container)
  self.dividerPool = CreateFramePool("Button", self:GetParent().Container, "BaganatorBagDividerTemplate")

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
  self.CategorySort:SetScript("OnHide", self.CategorySort.OnHide)

  self.CategoryGrouping = CreateFrame("Frame", nil, self)
  Mixin(self.CategoryGrouping, BaganatorCategoryViewsCategoryGroupingMixin)
  self.CategoryGrouping:SetScript("OnHide", self.CategoryGrouping.OnHide)
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
    table.insert(container.LiveLayouts, CreateFrame("Frame", nil, container.Container, "BaganatorLiveCategoryLayoutTemplate"))
    if container.liveItemButtonPool then
      container.LiveLayouts[#container.LiveLayouts]:SetPool(container.liveItemButtonPool)
    end
    table.insert(container.CachedLayouts, CreateFrame("Frame", nil, container.Container, "BaganatorCachedCategoryLayoutTemplate"))
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
  self.showAddButtons = container.addToCategoryMode and addonTable.CategoryViews.Utilities.GetAddButtonsState()

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
      if container.isLive and self.showAddButtons and not details.auto then
        if container.addToCategoryMode ~= details.source then
          table.insert(entries, {isDummy = true, label = BAGANATOR_L_ADD_TO_CATEGORY, dummyType = "add"})
        else
          if container.addedToFromCategory then
            table.insert(entries, {isDummy = true, label = BAGANATOR_L_REMOVE_FROM_CATEGORY, dummyType = "remove"})
          end
        end
      end
      details.results = entries
      details.any = #entries > 0 and not hidden[details.source] -- used to determine showing section headers
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

  local sourceKeysInUse = {}

  for _, details in ipairs(composed.details) do
    if details.results then
      details.sourceKey = details.source .. "_" .. details.label .. "_" .. (details.groupLabel or "")
      if #details.results > 0 then
        sourceKeysInUse[details.sourceKey] = true
      end
    end
  end

  local activeLayouts

  if container.isLive then
    -- Ensure we don't overflow the preallocated buttons by returning all
    -- buttons no longer needed by a particular group
    for index, details in pairs(composed.details) do
      if details.results and #details.results > 0 then
        local layout = FindValueInTableIf(container.LiveLayouts, function(a) return a.sourceKey == details.sourceKey end)
        if layout then
          layout:DeallocateUnusedButtons(details.results)
        end
      end
    end
    for _, layout in ipairs(container.LiveLayouts) do
      if not sourceKeysInUse[layout.sourceKey] then
        layout:DeallocateUnusedButtons({})
        layout:Hide()
      end
    end
    for _, layout in ipairs(container.CachedLayouts) do
      layout:Hide()
    end
    activeLayouts = container.LiveLayouts
  else
    for _, layout in ipairs(container.CachedLayouts) do
      if not sourceKeysInUse[layout.sourceKey] then
        layout:Hide()
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
      if #details.results > 0 then
        local searchResults = details.results
        local layout = FindValueInTableIf(activeLayouts, function(a) return a.sourceKey == details.sourceKey end)
        if not layout then
          layout = FindValueInTableIf(activeLayouts, function(a) return not sourceKeysInUse[a.sourceKey] end)
        end
        layout:ShowGroup(details.results, math.min(bagWidth, #details.results), details.source)
        table.insert(layoutsShown, layout)
        layout.section = details.section
        layout.sourceKey = details.sourceKey
        local label = self.labelsPool:Acquire()
        addonTable.Skins.AddFrame("CategoryLabel", label)
        label:SetText(details.label)
        label.categorySearch = index
        label.source = details.source
        label.groupLabel = details.groupLabel
        activeLabels[index] = label
        layout.type = details.type
      else
        table.insert(layoutsShown, {})
      end
    else
      error("unrecognised layout type")
    end
  end
  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("category group show", debugprofilestop() - start2)
  end

  return addonTable.CategoryViews.PackSimple(layoutsShown, activeLabels, 0, 0, bagWidth, addonTable.CategoryViews.Constants.MinWidth)
end

function addonTable.CategoryViews.BagLayoutMixin:Layout(allBags, bagWidth, bagTypes, bagIndexes, sideSpacing, topSpacing, callback)
  -- Just in case the rendering takes so long there's another bag update ready
  -- that triggers a conflicting render.
  self.CategoryFilter:Cancel()
  self.CategoryGrouping:Cancel()
  self.CategorySort:Cancel()
  self.state = {}
  local state = self.state
  local s0 = debugprofilestop()
  CheckStackable(allBags, function()
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("stackables", debugprofilestop() - s0)
    end
    if state ~= self.state then
      return
    end

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
      if state ~= self.state then
        return
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
  end)
end
