local _, addonTable = ...

local MasqueRegistration = addonTable.Utilities.MasqueRegistration

local function GetNameFromLink(itemLink)
  return (string.match(itemLink, "h%[(.*)%]|h"):gsub(" ?|A.-|a", ""))
end

local function RegisterHighlightSimilarItems(self)
  addonTable.CallbackRegistry:RegisterCallback("HighlightSimilarItems", function(_, itemLink)
    if not addonTable.Config.Get(addonTable.Config.Options.ICON_FLASH_SIMILAR_ALT) or itemLink == "" then
      return
    end
    local itemName = GetNameFromLink(itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink and GetNameFromLink(button.BGR.itemLink) == itemName then
        button:BGRStartFlashing()
      end
    end
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("HighlightIdenticalItems", function(_, itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink == itemLink then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

-- Supplied by Syndicator
local LibBattlePetTooltipLine = LibStub("LibBattlePetTooltipLine-1-0")
-- Used to ease adding to battle pet tooltip which doesn't have AddDoubleLine
local function AddDoubleLine(tooltip, left, right, ...)
  if tooltip.AddDoubleLine then
    tooltip:AddDoubleLine(left, right, ...)
  elseif tooltip.PetType then
    LibBattlePetTooltipLine:AddDoubleLine(tooltip, left, right)
  end
end

local function AddKeywords(self)
  if not addonTable.Config.Get(addonTable.Config.Options.DEBUG_KEYWORDS) then
    return
  end

  if self.BGR == nil or self.BGR.itemLink == nil then
    return
  end

  local tooltip = self.BGR.itemLink:match("battlepet:") and BattlePetTooltip or GameTooltip

  tooltip:AddLine(" ")
  tooltip:AddLine(BAGANATOR_L_HELP_SEARCH_KEYWORDS)

  local groups = addonTable.Help.GetKeywordGroups()

  for _, key in ipairs(addonTable.Constants.KeywordGroupOrder) do
    if groups[key] then
      table.sort(groups[key])
      local matching = {}
      for _, keyword in ipairs(groups[key]) do
        if Syndicator.Search.CheckItem(self.BGR, "#" .. keyword) then
          table.insert(matching, keyword)
        end
      end
      if #matching > 0 then
        AddDoubleLine(tooltip, BLUE_FONT_COLOR:WrapTextInColorCode(key), WHITE_FONT_COLOR:WrapTextInColorCode(table.concat(matching, ", ")))
      end
    end
  end
  tooltip:Show()
end

local function AddCategories(self)
  if not addonTable.Config.Get(addonTable.Config.Options.DEBUG_CATEGORIES) then
    return
  end

  if self.BGR == nil or self.BGR.itemLink == nil then
    return
  end

  local tooltip = self.BGR.itemLink:match("battlepet:") and BattlePetTooltip or GameTooltip

  tooltip:AddLine(" ")
  tooltip:AddLine(BAGANATOR_L_CATEGORIES)

  local data = CopyTable(self.BGR, 1)
  local itemKey = addonTable.CategoryViews.Utilities.GetAddedItemData(self.BGR.itemID, self.BGR.itemLink)
  if not data.key then
    data.key = itemKey
  end
  local composed = addonTable.CategoryViews.ComposeCategories({data})

  local searchToLabel = {}
  for _, details in ipairs(composed.details) do
    if details.attachedItems and details.attachedItems[itemKey] then
      tooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(
        BAGANATOR_L_ATTACHED_DIRECTLY_TO_X:format(GREEN_FONT_COLOR:WrapTextInColorCode("**" .. details.label .. "**"))
      ))
      tooltip:Show()
      return
    end
    if details.search then
      searchToLabel[details.search] = details.label
    end
  end

  local firstMatch = true
  local entries = {}
  for index, search in ipairs(composed.prioritisedSearches) do
    local result = Syndicator.Search.CheckItem(self.BGR, search)
    if result ~= nil then
      local text = searchToLabel[search]
      if firstMatch then
        if result then
          text = GREEN_FONT_COLOR:WrapTextInColorCode("**" .. text .. "**")
          firstMatch = false
        else
          text = RED_FONT_COLOR:WrapTextInColorCode(text)
        end
      elseif result then
        text = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode("-" .. text .. "-")
      else
        text = GRAY_FONT_COLOR:WrapTextInColorCode(text)
      end
      table.insert(entries, text)
    end
  end
  tooltip:AddLine(table.concat(entries, ", "), nil, nil, nil, true)
  tooltip:Show()
end

local function TooltipAdditions(...)
  AddKeywords(...)
  AddCategories(...)
end

function addonTable.ItemButtonUtil.GetPaddingAndSize()
  local iconPadding = 4

  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    iconPadding = 1
  end

  local iconSize = addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE)

  return iconPadding, iconSize
end

local function ApplySizing(self, rowWidth, iconPadding, iconSize, flexDimension, staticDimension)
  self:SetSize(rowWidth * (iconSize + iconPadding) - iconPadding, (iconPadding + iconSize) * ((flexDimension > 0 and (staticDimension + 1) or staticDimension)))
end

local function FlowButtonsRows(self, rowWidth)
  local iconPadding, iconSize = addonTable.ItemButtonUtil.GetPaddingAndSize()

  local rows, cols = 0, 0
  if addonTable.Config.Get(addonTable.Config.Options.BAG_EMPTY_SPACE_AT_TOP) then
    cols = rowWidth - #self.buttons%rowWidth
    if cols == rowWidth then
      cols = 0
    end
  end
  local iconPaddingScaled = iconPadding * 37 / iconSize
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (37 + iconPaddingScaled), - rows * (37 + iconPaddingScaled))
    button:SetScale(iconSize / 37)
    cols = cols + 1
    if cols >= rowWidth then
      cols = 0
      rows = rows + 1
    end
  end

  ApplySizing(self, rowWidth, iconPadding, iconSize, cols, rows)
  self.oldRowWidth = rowWidth
end

local function FlowButtonsColumns(self, rowWidth)
  local iconPadding, iconSize = addonTable.ItemButtonUtil.GetPaddingAndSize()

  local columnHeight = math.ceil(#self.buttons / rowWidth)

  local rows, cols = 0, 0

  local iconPaddingScaled = iconPadding * 37 / iconSize
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (37 + iconPaddingScaled), - rows * (37 + iconPaddingScaled))
    button:SetScale(iconSize / 37)
    rows = rows + 1
    if rows >= columnHeight then
      rows = 0
      cols = cols + 1
    end
  end

  ApplySizing(self, rowWidth, iconPadding, iconSize, cols, columnHeight - 1)
  self.oldRowWidth = rowWidth
end

local function UpdateTextures(self)
  for _, button in ipairs(self.buttons) do
    button:UpdateTextures()
  end
end

local function IsDifferentCachedData(data1, data2)
  return data1 == nil or data1.itemLink ~= data2.itemLink or not data1.isBound ~= not data2.isBound or (data1.itemCount or 1) ~= (data2.itemCount or 1) or data1.quality ~= data2.quality
end

function addonTable.ItemViewCommon.Utilities.GetCategoryDataKey(data)
  return data ~= nil and (tostring(data.keyLink) .. tostring(data.isBound) .. tostring(data.itemCount or 1) .. "_" .. tostring(data.quality) .. "_" .. tostring(data.bagType)) or ""
end

function addonTable.ItemViewCommon.Utilities.GetCategoryDataKeyNoCount(data)
  return data ~= nil and (tostring(data.keyLink) .. tostring(data.isBound) .. tostring(data.quality)) or ""
end

local function UpdateQuests(self)
  for _, button in ipairs(self.buttons) do
    if button.BGR and button.BGR.isQuestItem then
      if not C_Item.IsItemDataCachedByID(button.BGR.itemID) then
        addonTable.Utilities.LoadItemData(button.BGR.itemID, function()
          button:BGRUpdateQuests()
        end)
      else
        button:BGRUpdateQuests()
      end
    end
  end
end

local function LiveBagOnEvent(self, eventName, ...)
  if eventName == "ITEM_LOCK_CHANGED" then
    local bagID, slotID = ...
    self:UpdateLockForItem(bagID, slotID)
  elseif eventName == "BAG_UPDATE_COOLDOWN" then
    self:UpdateCooldowns()
  elseif eventName == "UNIT_QUEST_LOG_CHANGED" then
    local unit = ...
    if unit == "player" then
      self:UpdateQuests()
    end
  elseif eventName == "QUEST_ACCEPTED" then
    self:UpdateQuests()
  end
end

BaganatorCachedBagLayoutMixin = {}

function BaganatorCachedBagLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.buttonsByBag = {}
  self.waitingUpdate = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
end

function BaganatorCachedBagLayoutMixin:CompareButtonIndexes(indexes, indexesToUse, newBags)
  for index in pairs(indexesToUse) do
    local bagID = indexes[index]
    if not self.buttonsByBag[bagID] or not newBags[index] or #self.buttonsByBag[bagID] ~= #newBags[index] then
      return true
    end
  end

  return false
end

function BaganatorCachedBagLayoutMixin:MarkBagsPending(section, updatedWaiting)
  for bag in pairs(updatedWaiting[section]) do
    self.waitingUpdate[bag] = true
  end
end

function BaganatorCachedBagLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorCachedBagLayoutMixin:RebuildLayout(newBags, indexes, indexesToUse, rowWidth)
  self.buttons = {}
  self.buttonsByBag = {}
  self.buttonPool:ReleaseAll()

  local iconSize = addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE)

  local rows, cols = 0, 0
  for bagIndex = 1, #newBags do
    local bagButtons = {}
    if indexesToUse[bagIndex] and indexes[bagIndex] then
      self.buttonsByBag[indexes[bagIndex]] = bagButtons
      for slotIndex = 1, #newBags[bagIndex] do
        local button = self.buttonPool:Acquire()
        addonTable.Skins.AddFrame("ItemButton", button)
        if not button.setup then
          button.setup = true
          MasqueRegistration(button)
          button:UpdateTextures()
          hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
        end
        button:Show()

        table.insert(self.buttons, button)
        bagButtons[slotIndex] = button
      end
    end
  end

  FlowButtonsRows(self, rowWidth)
end

function BaganatorCachedBagLayoutMixin:ShowBags(bagData, source, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  if not bagData then
    return
  end

  local iconSize = addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE)

  if self.prevState.source ~= source or
      self:CompareButtonIndexes(indexes, indexesToUse, bagData) then
    self:RebuildLayout(bagData, indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  elseif self.refreshState[addonTable.Constants.RefreshReason.Flow] or rowWidth ~= self.oldRowWidth then
    FlowButtonsRows(self, rowWidth)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
    self.updateTextures = false
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] then
    self.waitingUpdate = {}
    for index in pairs(indexesToUse) do
      self.waitingUpdate[indexes[index]] = true
    end
  end

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and bagData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      -- bag may be nil due to past caching error (now fixed)
      if bag ~= nil then
        for index, slotInfo in ipairs(bagData[bagIndex]) do
          local button = bag[index]
          button:SetItemDetails(slotInfo)
        end
      end
    end
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("cached bag layout took", debugprofilestop() - start)
  end

  self.waitingUpdate = {}
  self.prevState = {
    source = source,
  }
  self.refreshState = {}
end

function BaganatorCachedBagLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorCachedBagLayoutMixin:OnShow()
  addonTable.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, highlightBagIDs)
    for bagID, bag in pairs(self.buttonsByBag) do
      for slotID, button in ipairs(bag) do
        button:BGRSetHighlight(highlightBagIDs[bagID])
      end
    end
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  RegisterHighlightSimilarItems(self)
end

function BaganatorCachedBagLayoutMixin:OnHide()
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

BaganatorLiveBagLayoutMixin = {}

local LIVE_LAYOUT_EVENTS = {
  "BAG_UPDATE_COOLDOWN",
  "UNIT_QUEST_LOG_CHANGED",
  "QUEST_ACCEPTED",
}

function BaganatorLiveBagLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetLiveItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByBag = {}
  self.bagSizesUsed = {}
  self.waitingUpdate = {}
  self.prevState = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

function BaganatorLiveBagLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorLiveBagLayoutMixin:SetPool(buttonPool)
  self.buttonPool = buttonPool
end

function BaganatorLiveBagLayoutMixin:UpdateCooldowns()
  for _, button in ipairs(self.buttons) do
    if button.BGR ~= nil then
      button:BGRUpdateCooldown()
    end
  end
end

BaganatorLiveBagLayoutMixin.UpdateQuests = UpdateQuests

BaganatorLiveBagLayoutMixin.OnEvent = LiveBagOnEvent

function BaganatorLiveBagLayoutMixin:OnShow()
  FrameUtil.RegisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  local start = debugprofilestop()
  self:UpdateCooldowns()
  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("update cooldowns show", debugprofilestop() - start)
  end
  self:UpdateQuests()

  addonTable.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, bagIDs)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(bagIDs[button:GetParent():GetID()])
    end
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  RegisterHighlightSimilarItems(self)

  self.refreshState = {}
end

function BaganatorLiveBagLayoutMixin:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)

  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightBagItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("ClearHighlightBag", self)

  for _, button in ipairs(self.buttons) do
    button:ClearNewItem()
  end
end

function BaganatorLiveBagLayoutMixin:UpdateLockForItem(bagID, slotID)
  if not self.buttonsByBag[bagID] then
    return
  end

  local itemButton = self.buttonsByBag[bagID][slotID]
  if itemButton then
    local info = C_Container.GetContainerItemInfo(bagID, slotID);
    local locked = info and info.isLocked;
    SetItemButtonDesaturated(itemButton, locked or itemButton.BGR.persistIconGrey)
  end
end

function BaganatorLiveBagLayoutMixin:Deallocate()
  self.indexFramesPool:ReleaseAll()
  for _, button in ipairs(self.buttons) do
    self.buttonPool:Release(button)
  end
  self.buttons = {}
  self.bagSizesUsed = {}
  self.buttonsByBag = {}
end

function BaganatorLiveBagLayoutMixin:RebuildLayout(indexes, indexesToUse, rowWidth)
  self:Deallocate()

  for index, bagID in ipairs(indexes) do
    if indexesToUse[index] then
      self.buttonsByBag[bagID] = {}
      local indexFrame = self.indexFramesPool:Acquire()
      indexFrame:SetID(indexes[index])
      indexFrame:Show()

      local size = C_Container.GetContainerNumSlots(bagID)
      for slotIndex = 1, size do
        local button = self.buttonPool:Acquire()
        addonTable.Skins.AddFrame("ItemButton", button)
        if not button.setup then
          button.setup = true
          MasqueRegistration(button)
          button:UpdateTextures()
          hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
          if button.OnUpdate then
            hooksecurefunc(button, "OnUpdate", TooltipAdditions)
          end
        end
        button:SetID(slotIndex)
        button:SetParent(indexFrame)
        button:Show()
        table.insert(self.buttons, button)

        self.buttonsByBag[bagID][slotIndex] = button
      end
      self.bagSizesUsed[index] = size
    end
  end

  FlowButtonsRows(self, rowWidth)
end

function BaganatorLiveBagLayoutMixin:CompareButtonIndexes(indexes, indexesToUse)
  for index, bagID in ipairs(indexes) do
    if indexesToUse[index] and self.bagSizesUsed[index] ~= C_Container.GetContainerNumSlots(bagID) or (self.buttonsByBag[bagID] and not indexesToUse[index]) then
      return true
    end
  end

  return false
end

function BaganatorLiveBagLayoutMixin:MarkBagsPending(section, updatedWaiting)
  for bag in pairs(updatedWaiting[section]) do
    self.waitingUpdate[bag] = true
  end
end

function BaganatorLiveBagLayoutMixin:ShowBags(bagData, source, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local iconSize = addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE)

  if self:CompareButtonIndexes(indexes, indexesToUse) or self.prevState.source ~= source then
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("rebuild")
    end
    self:RebuildLayout(indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  elseif self.refreshState[addonTable.Constants.RefreshReason.Flow] or rowWidth ~= self.oldRowWidth then
    FlowButtonsRows(self, rowWidth)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
    self.updateTextures = false
  end

  local refreshWidgets = self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets]
  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] then
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  end

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and bagData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      if #bag == #bagData[bagIndex] then
        for index, cacheData in ipairs(bagData[bagIndex]) do
          local button = bag[index]
          if IsDifferentCachedData(button.BGR, cacheData) then
            button:SetItemDetails(cacheData)
          elseif refreshWidgets then
            addonTable.ItemButtonUtil.ResetCache(button, cacheData)
          end
        end
      end
    end
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("live bag layout took", debugprofilestop() - start)
  end

  self.prevState = {
    source = source,
  }
  self.waitingUpdate = {}
end

function BaganatorLiveBagLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

local function InitializeCategoryEmptySlot(button, details)
  local count, bagType = details.itemCount, details.bagType
  SetItemButtonCount(button, bagType ~= "keyring" and count or 1)
  if not button.bagTypeIcon then
    button.bagTypeIcon = button:CreateTexture(nil, "OVERLAY")
    button.bagTypeIcon:SetSize(20, 20)
    button.bagTypeIcon:SetPoint("CENTER")
    button.bagTypeIcon:SetDesaturated(true)
    button:HookScript("OnEnter", function()
      if button.tooltipHeader then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(button.tooltipHeader)
        GameTooltip:Show()
      end
    end)
    hooksecurefunc(button, "UpdateTooltip", function()
      if button.tooltipHeader then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(button.tooltipHeader)
        GameTooltip:Show()
      end
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
    button.bagTypeIcon:SetTexture(nil)
    button.tooltipHeader = nil
  end
end

local function RestoreCategoryButtonFromEmptySlot(button)
  button.tooltipHeader = nil
  button.bagTypeIcon:SetTexture(nil)
end

BaganatorLiveCategoryLayoutMixin = {}

function BaganatorLiveCategoryLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetLiveItemButtonPool(self)
  self.dummyButtonPool = addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByKey = {}
  self.indexFrames = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
  self.refreshState = {}

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

function BaganatorLiveCategoryLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorLiveCategoryLayoutMixin:SetPool(buttonPool)
  self.buttonPool = buttonPool
end

function BaganatorLiveCategoryLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorLiveCategoryLayoutMixin:UpdateCooldowns()
  for _, button in ipairs(self.buttons) do
    if button.BGR ~= nil and button.BGRUpdateCooldown then
      button:BGRUpdateCooldown()
    end
  end
end

BaganatorLiveCategoryLayoutMixin.UpdateQuests = UpdateQuests

BaganatorLiveCategoryLayoutMixin.OnEvent = LiveBagOnEvent

function BaganatorLiveCategoryLayoutMixin:UpdateLockForItem(bagID, slotID)
  if not self.buttons then
    return
  end

  for _, itemButton in ipairs(self.buttons) do
    if itemButton:GetParent():GetID() == bagID and itemButton:GetID() == slotID then
      local info = C_Container.GetContainerItemInfo(bagID, slotID);
      local locked = info and info.isLocked;
      SetItemButtonDesaturated(itemButton, locked or itemButton.BGR.persistIconGrey)
    end
  end
end

function BaganatorLiveCategoryLayoutMixin:OnShow()
  FrameUtil.RegisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  self:UpdateCooldowns()
  self:UpdateQuests()

  RegisterHighlightSimilarItems(self)
end

function BaganatorLiveCategoryLayoutMixin:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)

  for _, button in ipairs(self.buttons) do
    if not button.isDummy then
      button:ClearNewItem()
    end
  end
end

function BaganatorLiveCategoryLayoutMixin:SetupButton(button)
  if button.setup then
    return
  end

  button.setup = true
  button:HookScript("OnClick", function(_, mouseButton)
    if not button.BGR.itemLink then
      return
    end

    if mouseButton == "LeftButton" and C_Cursor.GetCursorItem() ~= nil then
      addonTable.CallbackRegistry:TriggerEvent("CategoryAddItemStart", button.BGR.category, button.BGR.itemID, button.BGR.itemLink, button.addedDirectly)
    end
  end)
  hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
  if button.OnUpdate then
    hooksecurefunc(button, "OnUpdate", TooltipAdditions)
  end
  button:HookScript("OnDragStart", function(_)
    if C_Cursor.GetCursorItem() ~= nil then
      addonTable.CallbackRegistry:TriggerEvent("CategoryAddItemStart", button.BGR.category, button.BGR.itemID, button.BGR.itemLink, button.addedDirectly)
    end
  end)
end

function BaganatorLiveCategoryLayoutMixin:SetupDummyButton(button)
  if button.setup then
    return
  end
  button.setup = true
  button.isDummy = true

  local function ProcessCursor()
    if C_Cursor.GetCursorItem() ~= nil and button.dummyType ~= "empty" then
      addonTable.CallbackRegistry:TriggerEvent("CategoryAddItemEnd", button.dummyType == "add" and button.BGR.category or nil)
      ClearCursor()
    end
  end
  button:SetScript("OnClick", ProcessCursor)

  button:SetScript("OnReceiveDrag", ProcessCursor)

  button:SetScript("OnEnter", function()
    if button.label then
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(button.label)
    end
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button.ModifiedIcon = button:CreateTexture(nil, "OVERLAY")
  button.ModifiedIcon:SetPoint("CENTER")
end

function BaganatorLiveCategoryLayoutMixin:ApplyDummyButtonSettings(button, cacheData)
  if button.dummyType == cacheData.dummyType then
    return
  end

  button.dummyType = cacheData.dummyType
  button.ModifiedIcon:SetDesaturated(false)
  if cacheData.dummyType == "remove" then
    button.ModifiedIcon:SetAtlas("transmog-icon-remove")
    button.ModifiedIcon:SetSize(25, 25)
  elseif cacheData.dummyType == "add" then
    button.ModifiedIcon:SetAtlas("Garr_Building-AddFollowerPlus")
    button.ModifiedIcon:SetSize(37, 37)
  elseif cacheData.dummyType == "empty" then
    button.ModifiedIcon:SetAtlas("transmog-icon-remove")
    button.ModifiedIcon:SetSize(25, 25)
    button.ModifiedIcon:SetDesaturated(true)
  end
end

function BaganatorLiveCategoryLayoutMixin:DeallocateUnusedButtons(cacheList)
  local used = {}
  local matchingSlots = {}
  for _, cacheData in ipairs(cacheList) do
    local key = addonTable.ItemViewCommon.Utilities.GetCategoryDataKey(cacheData)
    used[key] = (used[key] or 0) + 1
    matchingSlots[key] = matchingSlots[key] or {}
    if cacheData.slotID then
      matchingSlots[key][cacheData.bagID .. "_" .. cacheData.slotID] = cacheData.itemCount
    end
  end
  for key, list in pairs(self.buttonsByKey) do
    if not used[key] or used[key] < #list then
      for index = #list, 1, -1 do
        local button = list[index]
        -- We match by bag and slot to avoid redrawing (and breaking clicks) on
        -- existing items
        if matchingSlots[key] == nil or button.BGR.itemCount ~= matchingSlots[key][button:GetParent():GetID() .. "_" .. button:GetID()] then
          if not button.isDummy then
            self.buttonPool:Release(button)
          else
            self.dummyButtonPool:Release(button)
          end
          table.remove(list, index)
        end
      end
      if #list == 0 then
        self.buttonsByKey[key] = nil
      end
      self.anyRemoved = true
    end
  end
  self.buttons = {}
end

function BaganatorLiveCategoryLayoutMixin:ShowGroup(cacheList, rowWidth, category)
  local toSet = {}
  local toResetCache = {}
  self.buttons = {}
  local itemWidgetsRefresh = self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets]
  for index, cacheData in ipairs(cacheList) do
    local key = addonTable.ItemViewCommon.Utilities.GetCategoryDataKey(cacheData)
    local newButton
    if self.buttonsByKey[key] then
      newButton = self.buttonsByKey[key][1]
      table.remove(self.buttonsByKey[key], 1)
      if #self.buttonsByKey[key] == 0 then
        self.buttonsByKey[key] = nil
      end
      if itemWidgetsRefresh then
        table.insert(toResetCache, {newButton, cacheData})
      elseif newButton.BGR then
        newButton.BGR.itemLocation = {bagID = cacheData.bagID, slotIndex = cacheData.slotID}
      end
      if newButton.index ~= index then
        self.reflowRequired = true
      end
    else
      if cacheData.isDummy then
        newButton = self.dummyButtonPool:Acquire()
        addonTable.Skins.AddFrame("ItemButton", newButton)
        if not newButton.texturesSetup then
          newButton.texturesSetup = true
          MasqueRegistration(newButton)
          newButton:UpdateTextures()
        end
        newButton.label = cacheData.label
        self:SetupDummyButton(newButton)
      else
        newButton = self.buttonPool:Acquire()
        addonTable.Skins.AddFrame("ItemButton", newButton)
        if not newButton.texturesSetup then
          newButton.texturesSetup = true
          MasqueRegistration(newButton)
          newButton:UpdateTextures()
        end
        self:SetupButton(newButton)
      end
      newButton:Show()
      table.insert(toSet, {newButton, cacheData})
    end
    if cacheData.isDummy  then
      self:ApplyDummyButtonSettings(newButton, cacheData)
    elseif not self.indexFrames[cacheData.bagID] then
      local indexFrame = self.indexFramesPool:Acquire()
      indexFrame:Show()
      indexFrame:SetID(cacheData.bagID)
      self.indexFrames[cacheData.bagID] = indexFrame
    end
    newButton:SetParent(self.indexFrames[cacheData.bagID] or self)
    newButton:SetID(cacheData.slotID or 0)
    if not cacheData.isDummy then
      local itemLocation = {bagID = cacheData.bagID, slotIndex = cacheData.slotID}
      SetItemButtonDesaturated(newButton, (C_Item.DoesItemExist(itemLocation) and C_Item.IsLocked(itemLocation)) or (newButton.BGR and newButton.BGR.persistIconGrey))
    end
    table.insert(self.buttons, newButton)
  end

  self.buttonsByKey = {}
  for index, button in ipairs(self.buttons) do
    button.index = index
    local cacheData = cacheList[index]
    local key = addonTable.ItemViewCommon.Utilities.GetCategoryDataKey(cacheData)
    self.buttonsByKey[key] = self.buttonsByKey[key] or {}
    table.insert(self.buttonsByKey[key], button)
  end

  if #toSet > 0 then
    self.toSet = true
    for _, details in ipairs(toSet) do
      details[1]:SetItemDetails(details[2])
      details[1].addedDirectly = details[2].addedDirectly
      if details[2].itemLink == nil then
        InitializeCategoryEmptySlot(details[1], details[2])
      elseif details[1].bagTypeIcon then
        RestoreCategoryButtonFromEmptySlot(details[1])
      end
    end
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.Flow] then
    self.reflowRequired = true
  end

  for _, details in ipairs(toResetCache) do
    addonTable.ItemButtonUtil.ResetCache(details[1], details[2])
    if details[2].itemLink == nil then
      InitializeCategoryEmptySlot(details[1], details[2])
    end
  end

  for index, button in ipairs(self.buttons) do
    button.BGR.category = category
  end

  self.refreshState = {}
end

function BaganatorLiveCategoryLayoutMixin:Flow(rowWidth)
  if self.reflowRequired or self.toSet or self.anyRemoved or rowWidth ~= self.prevRowWidth then
    self.toSet = false
    self.reflowRequired = false
    self.anyRemoved = false
    FlowButtonsRows(self, rowWidth)
    self.prevRowWidth = rowWidth
  end
end

BaganatorCachedCategoryLayoutMixin = {}

function BaganatorCachedCategoryLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByKey = {}
  self.indexFrames = {}
  self.prevState = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
end

function BaganatorCachedCategoryLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorCachedCategoryLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorCachedCategoryLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorCachedCategoryLayoutMixin:OnHide()
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorCachedCategoryLayoutMixin:Flow(width)
  FlowButtonsRows(self, width)
end

function BaganatorCachedCategoryLayoutMixin:ShowGroup(cacheList, rowWidth)
  self.buttonPool:ReleaseAll()
  self.buttons = {}
  for _, cacheData in ipairs(cacheList) do
    local button = self.buttonPool:Acquire()
    if not button.setup then
      button.setup = true
      addonTable.Skins.AddFrame("ItemButton", button)
      MasqueRegistration(button)
      button:UpdateTextures()
      hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
    elseif self.updateTextures then
      button:UpdateTextures()
    end
    table.insert(self.buttons, button)
  end

  self.updateTextures = false

  for index, button in ipairs(self.buttons) do
    button:Show()
    button:SetItemDetails(cacheList[index])
    if cacheList[index].itemLink == nil then
      InitializeCategoryEmptySlot(button, cacheList[index])
    elseif button.bagTypeIcon then
      RestoreCategoryButtonFromEmptySlot(button)
    end
  end

  self.refreshState = {}
end

BaganatorGeneralGuildLayoutMixin = {}

function BaganatorGeneralGuildLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")
  self.layoutType = "cached"
end

function BaganatorGeneralGuildLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorGeneralGuildLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorGeneralGuildLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorGeneralGuildLayoutMixin:OnHide()
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorGeneralGuildLayoutMixin:RebuildLayout(rowWidth)
  self.buttons = {}
  self.buttonPool:ReleaseAll()

  for index = 1, Syndicator.Constants.MaxGuildBankTabItemSlots do
    local button = self.buttonPool:Acquire()
    addonTable.Skins.AddFrame("ItemButton", button)
    if not button.setup then
      button.setup = true
      MasqueRegistration(button)
      button:UpdateTextures()
      hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
    end
    button:Show()
    button:SetID(index)
    table.insert(self.buttons, button)
  end

  FlowButtonsColumns(self, rowWidth)
end

function BaganatorGeneralGuildLayoutMixin:ShowGuild(guild, tabIndex, rowWidth)
  local start = debugprofilestop()

  local guildData = Syndicator.API.GetGuild(guild)

  if #self.buttons ~= Syndicator.Constants.MaxGuildBankTabItemSlots then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    self:RebuildLayout(rowWidth)
  elseif self.refreshState[addonTable.Constants.RefreshReason.Flow] or rowWidth ~= self.oldRowWidth then
    FlowButtonsColumns(self, rowWidth)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
  end

  if not guildData then
    return
  end

  if self.prevState.guild ~= guild or self.prevState.tabIndex ~= tabIndex then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] then
    local tab = guildData.bank[tabIndex] and guildData.bank[tabIndex].slots or {}
    for index, cacheData in ipairs(tab) do
      local button = self.buttons[index]
      button:SetItemDetails(cacheData, tabIndex)
    end
    if #tab == 0 then
      for _, button in ipairs(self.buttons) do
        button:SetItemDetails({}, tabIndex)
      end
    end
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("guild layout " .. tabIndex .. " took", debugprofilestop() - start)
  end

  self.prevState = {
    guild = guild,
    tabIndex = tabIndex,
  }
  self.refreshState = {}
end

BaganatorLiveGuildLayoutMixin = CreateFromMixins(BaganatorGeneralGuildLayoutMixin)

function BaganatorLiveGuildLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetLiveGuildItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.refreshState = {}
  self.layoutType = "live"
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")

  self:RegisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")
end

function BaganatorLiveGuildLayoutMixin:OnEvent(eventName, ...)
  if eventName == "GUILDBANK_ITEM_LOCK_CHANGED" and self.prevState and self.prevState.guild ~= nil and self.prevState.guild ~= "" then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    self:ShowGuild(self.prevState.guild, self.prevState.tabIndex, self.oldRowWidth)
    self.SearchMonitor:StartSearch(self.SearchMonitor.text)
  end
end

BaganatorUnifiedGuildLayoutMixin = {}

function BaganatorUnifiedGuildLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")
  self.layoutType = "cached"
end

function BaganatorUnifiedGuildLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorUnifiedGuildLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorUnifiedGuildLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)

  addonTable.CallbackRegistry:RegisterCallback("HighlightGuildTabItems", function(_, highlightGuildTabIDs)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(highlightGuildTabIDs[button.tabIndex])
    end
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("ClearHighlightGuildTab", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)
end

function BaganatorUnifiedGuildLayoutMixin:OnHide()
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)

  addonTable.CallbackRegistry:UnregisterCallback("HighlightGuildTabItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("ClearHighlightGuildTab", self)
end

function BaganatorUnifiedGuildLayoutMixin:RebuildLayout(tabCount, rowWidth)
  self.buttons = {}
  self.buttonPool:ReleaseAll()

  for tabIndex = 1, tabCount do
    for index = 1, Syndicator.Constants.MaxGuildBankTabItemSlots  do
      local button = self.buttonPool:Acquire()
      addonTable.Skins.AddFrame("ItemButton", button)
      if not button.setup then
        button.setup = true
        MasqueRegistration(button)
        button:UpdateTextures()
        hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
      end
      button.tabIndex = tabIndex
      button:Show()
      button:SetID(index)
      table.insert(self.buttons, button)
    end
  end

  FlowButtonsRows(self, rowWidth)
end

function BaganatorUnifiedGuildLayoutMixin:ShowGuild(guild, rowWidth)
  local start = debugprofilestop()

  local guildData = Syndicator.API.GetGuild(guild)

  local availableTabs = 0
  local wantedButtonCount = 0
  for _, tabData in ipairs(guildData.bank) do
    if tabData.isViewable then
      wantedButtonCount = wantedButtonCount + #tabData.slots
      availableTabs = availableTabs + 1
    end
  end

  if #self.buttons ~= wantedButtonCount then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    self:RebuildLayout(availableTabs, rowWidth)
  elseif self.refreshState[addonTable.Constants.RefreshReason.Flow] or rowWidth ~= self.oldRowWidth then
    FlowButtonsRows(self, rowWidth)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
  end

  if not guildData then
    return
  end

  if self.prevState.guild ~= guild then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] then
    local index = 1
    for tabIndex, tabData in ipairs(guildData.bank) do
      if tabData.isViewable then
        for _, cacheData in ipairs(tabData.slots) do
          local button = self.buttons[index]
          button:SetItemDetails(cacheData, tabIndex)
          index = index + 1
        end
      end
    end
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput(self.layoutType .. " guild layout " .. 0 .. " took", debugprofilestop() - start)
  end

  self.prevState = {
    guild = guild,
  }
  self.refreshState = {}
end

BaganatorLiveUnifiedGuildLayoutMixin = CreateFromMixins(BaganatorUnifiedGuildLayoutMixin)

function BaganatorLiveUnifiedGuildLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetLiveGuildItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.refreshState = {}
  self.layoutType = "live"
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")

  self:RegisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")
end

function BaganatorLiveUnifiedGuildLayoutMixin:OnEvent(eventName, ...)
  if eventName == "GUILDBANK_ITEM_LOCK_CHANGED" and self.prevState and self.prevState.guild ~= nil and self.prevState.guild ~= "" then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    self:ShowGuild(self.prevState.guild, self.oldRowWidth)
    self.SearchMonitor:StartSearch(self.SearchMonitor.text)
  end
end

BaganatorLiveWarbandLayoutMixin = {}

function BaganatorLiveWarbandLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetLiveItemButtonPool(self)
  self.indexFrame = CreateFrame("Frame", nil, self)
  self.buttons = {}
  self.prevState = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

function BaganatorLiveWarbandLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

BaganatorLiveWarbandLayoutMixin.OnEvent = LiveBagOnEvent

function BaganatorLiveWarbandLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorLiveWarbandLayoutMixin:OnHide()
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorLiveWarbandLayoutMixin:UpdateLockForItem(bagID, slotID)
  local myBagID = self.indexFrame:GetID()
  if self.buttons[1] and bagID == myBagID then
    local itemButton = self.buttons[slotID]
    if itemButton then
      local info = C_Container.GetContainerItemInfo(bagID, slotID);
      local locked = info and info.isLocked;
      SetItemButtonDesaturated(itemButton, locked or itemButton.BGR.persistIconGrey)
    end
  end
end

function BaganatorLiveWarbandLayoutMixin:RebuildLayout(tabSize, rowWidth)
  if tabSize == 0 then
    return
  end

  for slotIndex = 1, tabSize do
    local button = self.buttonPool:Acquire()
    addonTable.Skins.AddFrame("ItemButton", button)
    if not button.setup then
      button.setup = true
      MasqueRegistration(button)
      button:UpdateTextures()
      hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
      hooksecurefunc(button, "OnUpdate", TooltipAdditions)
    end
    button:SetID(slotIndex)
    button:SetParent(self.indexFrame)
    button:Show()
    table.insert(self.buttons, button)
  end

  FlowButtonsColumns(self, rowWidth)

  self.initialized = true
end

function BaganatorLiveWarbandLayoutMixin:MarkTabsPending(updatedWaiting)
  self.refreshState[addonTable.Constants.RefreshReason.ItemData] = updatedWaiting.bags[self.prevState.bagID] == true
end

function BaganatorLiveWarbandLayoutMixin:ShowTab(tabIndex, indexes, rowWidth)
  local start = debugprofilestop()

  local warbandData = Syndicator.API.GetWarband(1).bank

  if #warbandData == 0 then
    return
  end

  local iconSize = addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE)

  if not self.initialized then
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("rebuild")
    end
    self:RebuildLayout(#warbandData[tabIndex].slots, rowWidth)
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
  elseif self.refreshState[addonTable.Constants.RefreshReason.Flow] or rowWidth ~= self.oldRowWidth then
    FlowButtonsColumns(self, rowWidth)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] or self.prevState.tabIndex ~= tabIndex then
    local bagID = indexes[tabIndex]
    self.indexFrame:SetID(bagID)
    for index, cacheData in ipairs(warbandData[tabIndex].slots) do
      local button = self.buttons[index]
      if IsDifferentCachedData(button.BGR, cacheData) then
        button:SetItemDetails(cacheData)
      elseif self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] then
        addonTable.ItemButtonUtil.ResetCache(button, cacheData)
      end
    end
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("live warband layout took", debugprofilestop() - start)
  end

  self.prevState = {
    tabIndex = tabIndex,
    bagID = indexes[tabIndex],
  }
  self.refreshState = {}
end

function BaganatorLiveWarbandLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

BaganatorCachedWarbandLayoutMixin = {}

function BaganatorCachedWarbandLayoutMixin:OnLoad()
  self.buttonPool = addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.refreshState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
end

function BaganatorCachedWarbandLayoutMixin:UpdateRefreshState(refreshState)
  Mixin(self.refreshState, refreshState)
end

function BaganatorCachedWarbandLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)
end

function BaganatorCachedWarbandLayoutMixin:OnHide()
  addonTable.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  addonTable.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorCachedWarbandLayoutMixin:RebuildLayout(tabSize, rowWidth)
  if tabSize == 0 then
    return
  end

  for slotIndex = 1, tabSize do
    local button = self.buttonPool:Acquire()
    addonTable.Skins.AddFrame("ItemButton", button)
    if not button.setup then
      button.setup = true
      MasqueRegistration(button)
      button:UpdateTextures()
      hooksecurefunc(button, "UpdateTooltip", TooltipAdditions)
    end
    button:Show()
    table.insert(self.buttons, button)
  end

  FlowButtonsColumns(self, rowWidth)

  self.initialized = true
end

function BaganatorCachedWarbandLayoutMixin:ShowTab(tabIndex, indexes, rowWidth)
  local start = debugprofilestop()

  local warbandData = Syndicator.API.GetWarband(1).bank

  if #warbandData == 0 then
    return
  end

  local iconSize = addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE)

  if not self.initialized then
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("rebuild")
    end
    self:RebuildLayout(#warbandData[tabIndex].slots, rowWidth)
  elseif self.refreshState[addonTable.Constants.RefreshReason.Flow] or rowWidth ~= self.oldRowWidth then
    FlowButtonsColumns(self, rowWidth)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] then
    UpdateTextures(self)
  end

  for index, cacheData in ipairs(warbandData[tabIndex].slots) do
    local button = self.buttons[index]
    button:SetItemDetails(cacheData)
  end

  self.refreshState = {}

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("cached warband layout took", debugprofilestop() - start)
  end
end

function BaganatorCachedWarbandLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

BaganatorSearchLayoutMonitorMixin = {}

function BaganatorSearchLayoutMonitorMixin:OnLoad()
  self.pendingItems = {}
  self.text = ""
end

function BaganatorSearchLayoutMonitorMixin:OnUpdate()
  for itemButton in pairs(self.pendingItems)do
    if not itemButton:SetItemFiltered(self.text) then
      self.pendingItems[itemButton] = nil
    end
  end
  if next(self.pendingItems) == nil then
    self:SetScript("OnUpdate", nil)
    addonTable.ItemViewCommon.NotifySearchMonitorComplete(self.text)
  end
end

function BaganatorSearchLayoutMonitorMixin:StartSearch(text)
  self.text = text
  self.pendingItems = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton:SetItemFiltered(text) then
      self.pendingItems[itemButton] = true
    end
  end
  if next(self.pendingItems) then
    self:SetScript("OnUpdate", self.OnUpdate)
  else
    addonTable.ItemViewCommon.NotifySearchMonitorComplete(self.text)
  end
end

BaganatorBagSearchLayoutMonitorMixin = CreateFromMixins(BaganatorSearchLayoutMonitorMixin)

function BaganatorBagSearchLayoutMonitorMixin:GetMatches()
  local matches = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch and itemButton.BGR.contextMatch ~= false then
      table.insert(matches, {
        bagID = itemButton:GetParent():GetID(),
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
        itemLink = itemButton.BGR.itemLink,
        hasNoValue = itemButton.BGR.hasNoValue,
        isBound = itemButton.BGR.isBound,
      })
    end
  end
  return matches
end

BaganatorGuildSearchLayoutMonitorMixin = CreateFromMixins(BaganatorSearchLayoutMonitorMixin)

function BaganatorGuildSearchLayoutMonitorMixin:GetMatches()
  local matches = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch and itemButton.BGR.contextMatch ~= false then
      table.insert(matches, {
        tabIndex = self:GetParent().prevState.tabIndex,
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
        itemLink = itemButton.BGR.itemLink,
      })
    end
  end
  return matches
end

BaganatorBagDividerMixin = {}
function BaganatorBagDividerMixin:OnLoad()
  if addonTable.Constants.IsRetail then
    self.Divider:SetAtlas("activities-divider", true)
  else
    self.Divider:SetAtlas("battlefieldminimap-border-top")
    self.Divider:SetHeight(15)
    self.Divider:ClearAllPoints()
    self.Divider:SetPoint("TOPLEFT", 0, 6)
    self.Divider:SetPoint("TOPRIGHT", 0, 6)
  end
  addonTable.Skins.AddFrame("Divider", self.Divider)
end
