local _, addonTable = ...

local Refresh = addonTable.Constants.RefreshReason

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
            addonTable.ReportEntry()
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

local function Prearrange(isLive, bagID, bag, bagType, isGrouping)
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
    info.bagType = bagType
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
      local location = {bagID = bagID, slotIndex = slotIndex}
      if info.itemID ~= nil and C_Item.DoesItemExist(location) then
        info.setInfo = addonTable.ItemViewCommon.GetEquipmentSetInfo(location, info.itemLink)
        info.itemLocation = location
        if info.setInfo then
          info.guid = C_Item.GetItemGUID(location)
          info.useGUID = true
        elseif info.hasLoot and not info.isBound then
          -- Ungroup lockboxes always
          local classID, subClassID = select(6, C_Item.GetItemInfoInstant(info.itemID))
          if classID == Enum.ItemClass.Miscellaneous and subClassID == 0 then
            info.guid = C_Item.GetItemGUID(location)
            info.useGUID = true
          end
        elseif not isGrouping then
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
      info.keyNoGUID = addonTable.ItemViewCommon.Utilities.GetCategoryDataKeyNoCount(info)
      info.keyGUID = info.keyNoGUID .. info.guid .. "_" .. tostring(info.refundable)
      if info.useGUID then
        info.key = info.keyGUID
      else
        info.key = info.keyNoGUID .. "_" .. tostring(info.refundable)
      end
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

  self.notShown = {}

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
  self.emptySlotsComposed = nil
  if self.dummyAdded then
    self:GetParent().refreshState[addonTable.Constants.RefreshReason.Layout] = true
  end
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

function addonTable.CategoryViews.BagLayoutMixin:Display(bagWidth, bagIndexes, bagTypes, composed, emptySlotsOrder, emptySlotsByType, bagWidth, sideSpacing, topSpacing)
  local container = self:GetParent()
  self.dummyAdded = false

  local function AllocateLayout()
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
      if not details.emptySlots and container.isGrouping then
        local entriesByKey = {}
        for _, item in ipairs(details.results) do
          local groupingKey = item.key
          local existingItem = entriesByKey[groupingKey]
          if existingItem then
            existingItem.itemCount = existingItem.itemCount + item.itemCount
            if existingItem.bagType ~= item.bagType then
              existingItem.bagType = "?"
            end

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
          self.dummyAdded = true
        else
          if container.addedToFromCategory then
            table.insert(entries, {isDummy = true, label = BAGANATOR_L_REMOVE_FROM_CATEGORY, dummyType = "remove"})
            self.dummyAdded = true
          end
        end
      end
      details.results = entries
      if hidden[details.source] then
        for _, entry in ipairs(details.results) do
          table.insert(self.notShown, entry)
        end
      end
    end
  end

  local oldComposed = self.emptySlotsComposed
  self.emptySlotsComposed = composed
  if oldComposed and self.wasGrouping == container.isGrouping then
    local anyNew = #composed.details ~= #oldComposed.details
    for index, old in ipairs(oldComposed.details) do
      local current = composed.details[index]
      if current.source ~= old.source then
        anyNew = true
        break
      elseif current.results and (current.source and (current.source ~= addonTable.CategoryViews.Constants.RecentItemsCategory)
          and not old.emptySlots and (old.oldLength or #old.results) < #current.results) then
        for _, item in ipairs(current.results) do -- Put returning items back where they were before
          -- Check if the exact item existed before, or at least a similar one
          -- (for warband transfers)
          if not old.keysGUID or (not old.keysGUID[item.keyGUID] and (not old.keysNoGUID[item.keyNoGUID] or old.keysNoGUID[item.keyNoGUID] <= 0)) then
            anyNew = true
            break
          elseif old.keysNoGUID and old.keysNoGUID[item.keyNoGUID] then
            old.keysNoGUID[item.keyNoGUID] = old.keysNoGUID[item.keyNoGUID] - 1
          end
        end
        if anyNew then
          break
        end
      end
    end
    if not anyNew and not container.addToCategoryMode then
      local typeMap = {}
      for index, old in ipairs(oldComposed.details) do
        if old.results then
          local current = composed.details[index]
          current.oldLength = #current.results
          if #old.results > #current.results and not old.emptySlots and (#current.results > 0 or current.source ~= addonTable.CategoryViews.Constants.RecentItemsCategory) then
            for index2, info in ipairs(old.results) do
              if #current.results >= #old.results then
                break
              end
              local currentInfo = current.results[index2]
              -- Check for missing items, and persist slot location/holes in the list
              if info.bagID and info.slotID and (
                  not currentInfo or
                  (
                  -- Admittedly if the keyNoGUID is the only thing that matches
                  -- (warband bank) the position may not be exact, but it'll be
                  -- close enough
                    (currentInfo.keyGUID ~= info.keyGUID and currentInfo.keyGUID ~= info.oldKeyGUID and
                      (
                        (currentInfo.keyNoGUID ~= info.keyNoGUID and currentInfo.keyNoGUID ~= info.oldKeyNoGUID) or -- not the same item/binding
                        (old.keysGUID and old.keysGUID[currentInfo.keyGUID]) -- doesn't appear later
                      )
                    )
                  )
                )
                then
                table.insert(current.results, index2, {bagID = info.bagID, slotID = info.slotID, isDummy = true, dummyType = "empty", oldKeyGUID = info.keyGUID or info.oldKeyGUID, oldKeyNoGUID = info.keyNoGUID or info.oldKeyNoGUID})
                self.dummyAdded = true
              end
            end
          end
        end
      end
    end
  end
  if container.splitStacksDueToTransfer then
    for _, current in ipairs(composed.details) do
      if current.results then
        current.keysGUID = {}
        -- We use keyNoGUID as a backup because the guid shifts when moving items
        -- in-and-out of the warband bank
        current.keysNoGUID = {}
        for _, item in ipairs(current.results) do
          if item.bagID and item.slotID and (item.keyGUID or item.oldKeyGUID) and (item.keyNoGUID or item.oldKeyNoGUID) then
            current.keysGUID[item.keyGUID or item.oldKeyGUID] = true
            current.keysNoGUID[item.keyNoGUID or item.oldKeyNoGUID] = (current.keysNoGUID[item.keyNoGUID or item.oldKeyNoGUID] or 0) + 1
          end
        end
      end
    end
  end

  local sourceKeysInUse = {}

  for _, details in ipairs(composed.details) do
    if details.results then
      details.sourceKey = details.source .. "_" .. details.label .. "_" .. (details.groupLabel or "") .. "_" .. (details.autoIndex or "")
      if #details.results > 0 then
        sourceKeysInUse[details.sourceKey] = details
      end
    end
  end

  local activeLayouts

  local function IsSectionToggled(section)
    for i = 1, #section do
      if sectionToggled[section[i]] then
        return true
      end
    end
    return false
  end

  local layoutsBySource = {}
  local unusedLayouts = {}

  if container.isLive then
    for _, layout in ipairs(container.LiveLayouts) do
      local existing = sourceKeysInUse[layout.sourceKey]
      if existing and not hidden[existing.source] then
        layoutsBySource[layout.sourceKey] = layout
        layout:DeallocateUnusedButtons(existing.results)
      else
        table.insert(unusedLayouts, layout)
        -- Ensure we don't overflow the preallocated buttons by returning all
        -- buttons no longer needed by a particular group
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
      if sourceKeysInUse[layout.sourceKey] then
        layoutsBySource[layout.sourceKey] = layout
      else
        table.insert(unusedLayouts, layout)
        layout:Hide()
      end
    end
    for _, layout in ipairs(container.LiveLayouts) do
      layout:Hide()
    end
    activeLayouts = container.CachedLayouts
  end

  container.layoutsBySourceKey = {}

  local layoutsShown, activeLabels = {}, {}

  local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
  local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)

  for index, details in ipairs(composed.details) do
    if details.type == "divider" then
      local divider = self.dividerPool:Acquire()
      table.insert(layoutsShown, divider)
      divider.type = details.type
      divider.section = details.section
    elseif details.type == "section" then
      -- Check whether the section has any non-empty items in it
      local itemCount = 0
      local any = false
      local level = #details.section + 1
      if index < #composed.details then
        for i = index + 1, #composed.details do
          local d = composed.details[i]
          if d.section[level] ~= details.source then
            break
          elseif d.type == "category" and #d.results > 0 and not hidden[d.source] then
            itemCount = itemCount + (d.oldLength or #d.results)
            any = true -- keep section active if blank slots in it
          end
        end
      end
      if itemCount > 0 or any then
        local button = self.sectionButtonPool:Acquire()
        local label = details.label
        local mods = categoryMods[details.color] or sections[details.source]
        if mods and mods.color then
          label = "|cff" .. mods.color .. label .. "|r"
        end
        if sectionToggled[details.source] then
          button:SetText(label .. " " .. LIGHTGRAY_FONT_COLOR:WrapTextInColorCode("(" .. itemCount .. ")"))
          button:SetCollapsed()
        else
          button:SetText(label)
          button:SetExpanded()
        end
        button.assignedLayouts = {}
        button.source = details.source
        button.section = details.section
        button.moveOffscreen = IsSectionToggled(details.section)
        table.insert(layoutsShown, button)
        button.type = details.type
      else
        table.insert(layoutsShown, {}) -- {} causes the packing code to ignore this
      end
    elseif details.type == "category" then
      if #details.results > 0 and not hidden[details.source] then
        local searchResults = details.results
        local layout = layoutsBySource[details.sourceKey]
        if not layout then
          layout = table.remove(unusedLayouts)
        end
        if not layout then
          AllocateLayout()
          layout = activeLayouts[#activeLayouts]
        end
        layout:ShowGroup(details.results, math.min(bagWidth, #details.results), details.source)
        layout.moveOffscreen = IsSectionToggled(details.section)
        table.insert(layoutsShown, layout)
        layout.section = details.section
        layout.sourceKey = details.sourceKey
        local label = self.labelsPool:Acquire()
        addonTable.Skins.AddFrame("CategoryLabel", label)
        local mods = categoryMods[details.color or details.source]
        if mods and mods.color then
          label:SetText("|cff" .. mods.color .. details.label .. "|r")
        else
          label:SetText(details.label)
        end
        label.index = index
        label.source = details.source
        label.sourceKey = details.sourceKey
        container.layoutsBySourceKey[details.sourceKey] = layout
        activeLabels[index] = label
        layout.type = details.type
      else
        table.insert(layoutsShown, {})
      end
    else
      error("unrecognised layout type")
    end
  end

  container.activeLayouts = layoutsShown

  self.wasGrouping = container.isGrouping

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("category group show", debugprofilestop() - start2)
  end

  return addonTable.CategoryViews.PackSimple(layoutsShown, activeLabels, 0, 0, bagWidth, addonTable.CategoryViews.Utilities.GetMinWidth(bagWidth))
end

function addonTable.CategoryViews.BagLayoutMixin:Layout(allBags, bagWidth, bagTypes, bagIndexes, sideSpacing, topSpacing, callback)
  local refreshState = self:GetParent().refreshState

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] then
    refreshState[Refresh.Layout] = true
  end

  if refreshState[Refresh.Searches] then
    self.ItemsPreparation:ResetCaches()
    self.CategoryFilter:ResetCaches()
  end
  if refreshState[Refresh.Sorts] or refreshState[Refresh.Character] then
    self.emptySlotsComposed = nil
    self.wasGrouping = nil
  end

  -- Just in case the rendering takes so long there's another bag update ready
  -- that triggers a conflicting render.
  self.CategoryFilter:Cancel()
  self.CategoryGrouping:Cancel()
  self.CategorySort:Cancel()

  if refreshState[Refresh.ItemData] or not self.state then
    self.state = {}
  end

  local iterationIndex = (self.iterationIndex or 0) + 1
  self.iterationIndex = iterationIndex

  local calls = {}

  local index = 1
  local function Next()
    if index > #calls then
      if #calls > 0 or refreshState[addonTable.Constants.RefreshReason.Cosmetic] or refreshState[addonTable.Constants.RefreshReason.ItemWidgets] or refreshState[addonTable.Constants.RefreshReason.ItemTextures] or refreshState[addonTable.Constants.RefreshReason.Layout] then
        self.state.maxWidth, self.state.maxHeight = self:Display(bagWidth, bagIndexes, bagTypes, CopyTable(self.state.composed), self.state.emptySlotsOrder, self.state.emptySlotsByType, bagWidth, sideSpacing, topSpacing)
      end
      callback(self.state.maxWidth, self.state.maxHeight)
    else
      index = index + 1
      calls[index - 1]()
    end
  end

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] then
    table.insert(calls, function()
      local s0 = debugprofilestop()
      CheckStackable(allBags, function()
        if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
          addonTable.Utilities.DebugOutput("stackables", debugprofilestop() - s0)
        end
        if iterationIndex ~= self.iterationIndex then
          return
        end

        local container = self:GetParent()
        local s1 = debugprofilestop()

        local emptySlotsByType, emptySlotsOrder, everything = {}, {}, {}
        for index, bagID in ipairs(bagIndexes) do
          if allBags[index] then
            local result = Prearrange(container.isLive, bagID, allBags[index], bagTypes[index], container.isGrouping)
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

        self.state.emptySlotsByType = emptySlotsByType
        self.state.emptySlotsOrder = emptySlotsOrder
        self.state.everything = everything

        if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
          addonTable.Utilities.DebugOutput("prearrange", debugprofilestop() - s1)
        end
        Next()
      end)
    end)
  end

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] then
    table.insert(calls, function()
      self.state.composed = addonTable.CategoryViews.ComposeCategories(self.state.everything)
      Next()
    end)
  end

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] or refreshState[Refresh.Sorts] then
    table.insert(calls, function()
      local s2 = debugprofilestop()
      self.ItemsPreparation:PrepareItems(self.state.everything, function()
        if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
          addonTable.Utilities.DebugOutput("prep", debugprofilestop() - s2)
        end
        if iterationIndex ~= self.iterationIndex then
          return
        end
        Next()
      end)
    end)
  end

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] then
    table.insert(calls, function()
      self.CategoryFilter:ApplySearches(self.state.composed, self.state.everything, function()
        self.CategoryGrouping:ApplyGroupings(self.state.composed, function()
          Next()
        end)
      end)
    end)
  end

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] or refreshState[Refresh.Sorts] then
    table.insert(calls, function()
      self.CategorySort:ApplySorts(self.state.composed, function()
        Next()
      end)
    end)
  end

  if refreshState[Refresh.ItemData] or refreshState[Refresh.Searches] or refreshState[Refresh.Sorts] then
    table.insert(calls, function()
      local s3 = debugprofilestop()
      self.ItemsPreparation:CleanItems(self.state.everything)
      if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
        addonTable.Utilities.DebugOutput("clean", debugprofilestop() - s3)
      end
      Next()
    end)
  end

  Next()
end
