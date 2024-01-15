local masqueGroup
local function MasqueRegistration(button)
  if not LibStub then
    return
  end

  if masqueGroup == nil then
    -- Establish a reference to Masque.
    local Masque, MSQ_Version = LibStub("Masque", true)
    if Masque == nil then
      return
    end
    -- Retrieve a reference to a new or existing group.
    masqueGroup = Masque:Group("Baganator", "Bag")
  end

  if masqueGroup then
    if button.masqueApplied then
      masqueGroup:ReSkin(button)
    else
      button.masqueApplied = true
      masqueGroup:AddButton(button, nil, "Item")
    end
  end
end

BaganatorCachedBagLayoutMixin = {}

local ReflowSettings = {
  Baganator.Config.Options.BAG_ICON_SIZE,
  Baganator.Config.Options.EMPTY_SLOT_BACKGROUND,
  Baganator.Config.Options.BAG_EMPTY_SPACE_AT_TOP,
  Baganator.Config.Options.ICON_TEXT_FONT_SIZE,
  Baganator.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.REDUCE_SPACING,
}

local RefreshContentSettings = {
  Baganator.Config.Options.HIDE_BOE_ON_COMMON,
  Baganator.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS,
  Baganator.Config.Options.ICON_GREY_JUNK,
  Baganator.Config.Options.JUNK_PLUGIN,
}

local classicCachedObjectCounter = 0

local function FlowButtons(self, rowWidth)
  local iconPadding = 4

  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    iconPadding = 1
  end

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  local rows, cols = 0, 0
  if Baganator.Config.Get(Baganator.Config.Options.BAG_EMPTY_SPACE_AT_TOP) then
    cols = rowWidth - #self.buttons%rowWidth
    if cols == rowWidth then
      cols = 0
    end
  end
  local iconPaddingScaled = iconPadding * 37 / iconSize
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (37 + iconPaddingScaled), - rows * (37 + iconPaddingScaled))
    button:SetScale(iconSize / 37)
    button:UpdateTextures()
    MasqueRegistration(button)
    cols = cols + 1
    if cols >= rowWidth then
      cols = 0
      rows = rows + 1
    end
  end

  self:SetSize(rowWidth * (iconSize + iconPadding) - iconPadding, (iconPadding + iconSize) * ((cols > 0 and (rows + 1) or rows)))
  self.oldRowWidth = rowWidth
end

function BaganatorCachedBagLayoutMixin:OnLoad()
  if Baganator.Constants.IsRetail then
    self.buttonPool = CreateFramePool("ItemButton", self, "BaganatorRetailCachedItemButtonTemplate")
  else
    self.buttonPool = CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRCachedItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
  self.buttons = {}
  self.prevState = {}
  self.buttonsByBag = {}
  self.waitingUpdate = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorSearchLayoutMonitorTemplate")
end

function BaganatorCachedBagLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorCachedBagLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
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

function BaganatorCachedBagLayoutMixin:RebuildLayout(newBags, indexes, indexesToUse, rowWidth)
  if self.pendingAllocations then
    error("Bag buttons not pre-allocated")
  end
  self.buttons = {}
  self.buttonsByBag = {}
  self.buttonPool:ReleaseAll()

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  local rows, cols = 0, 0
  for bagIndex = 1, #newBags do
    local bagButtons = {}
    if indexesToUse[bagIndex] and indexes[bagIndex] then
      self.buttonsByBag[indexes[bagIndex]] = bagButtons
      for slotIndex = 1, #newBags[bagIndex] do
        local button = self.buttonPool:Acquire()
        button:Show()

        table.insert(self.buttons, button)
        bagButtons[slotIndex] = button
      end
    end
  end

  FlowButtons(self, rowWidth)
end

function BaganatorCachedBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local characterData = BAGANATOR_DATA.Characters[character]

  if not characterData then
    return
  end

  local sectionData = characterData[section]

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  if self.prevState.character ~= character or self.prevState.section ~= section or
      self:CompareButtonIndexes(indexes, indexesToUse, sectionData) then
    self:RebuildLayout(sectionData, indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtons(self, rowWidth)
  end

  if self.refreshContent then
    self.refreshContent = false
    self.waitingUpdate = {}
    for index in pairs(indexesToUse) do
      self.waitingUpdate[indexes[index]] = true
    end
  end

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and sectionData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      -- bag may be nil due to past caching error (now fixed)
      if bag ~= nil then
        for index, slotInfo in ipairs(sectionData[bagIndex]) do
          local button = bag[index]
          button:SetItemDetails(slotInfo)
        end
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    local c = 0
    for _ in pairs(indexesToUse) do
      c = c+ 1
    end
    print("cached layout took", c, section, debugprofilestop() - start)
  end

  self.waitingUpdate = {}
  self.prevState = {
    character = character,
    section = section,
  }
end

function BaganatorCachedBagLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorCachedBagLayoutMixin:OnShow()
  Baganator.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, highlightBagID)
    for bagID, bag in pairs(self.buttonsByBag) do
      for slotID, button in ipairs(bag) do
        button:BGRSetHighlight(bagID == highlightBagID)
      end
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("HighlightSimilarItems", function(_, itemName)
    if not Baganator.Config.Get(Baganator.Config.Options.ICON_FLASH_SIMILAR_ALT) or itemName == "" then
      return
    end
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemName == itemName then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

function BaganatorCachedBagLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightBagItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("ClearHighlightBag", self)
end

BaganatorLiveBagLayoutMixin = {}

function BaganatorLiveBagLayoutMixin:OnLoad()
  if Baganator.Constants.IsRetail then
    self.buttonPool = CreateFramePool("ItemButton", self, "BaganatorRetailLiveItemButtonTemplate")
  else
    self.buttonPool = CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicLiveItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end

  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByBag = {}
  self.bagSizesUsed = {}
  self.waitingUpdate = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end


function BaganatorLiveBagLayoutMixin:PreallocateButtons(buttonCount)
  self.pendingAllocations = true
  -- Avoid allocating during combat
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    self.pendingAllocations = false
    for i = 1, buttonCount do
      self.buttonPool:Acquire()
    end
    self.buttonPool:ReleaseAll()
  end)
end

function BaganatorLiveBagLayoutMixin:UpdateCooldowns()
  for _, button in ipairs(self.buttons) do
    if button.BGR ~= nil then
      button:BGRUpdateCooldown()
    end
  end
end

function BaganatorLiveBagLayoutMixin:OnEvent(eventName, ...)
  if eventName == "ITEM_LOCK_CHANGED" then
    local bagID, slotID = ...
    self:UpdateLockForItem(bagID, slotID)
  elseif eventName == "BAG_UPDATE_COOLDOWN" then
    self:UpdateCooldowns()
  end
end

function BaganatorLiveBagLayoutMixin:OnShow()
  self:RegisterEvent("BAG_UPDATE_COOLDOWN")
  local start = debugprofilestop()
  self:UpdateCooldowns()
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("update cooldowns show", debugprofilestop() - start)
  end

  Baganator.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, bagID)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(button:GetParent():GetID() == bagID)
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("HighlightSimilarItems", function(_, itemName)
    if not Baganator.Config.Get(Baganator.Config.Options.ICON_FLASH_SIMILAR_ALT) or itemName == "" then
      return
    end
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemName == itemName then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

function BaganatorLiveBagLayoutMixin:OnHide()
  self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
  local start = debugprofilestop()
  for _, button in ipairs(self.buttons) do
    button:ClearNewItem()
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("remove new item", debugprofilestop() - start)
  end

  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightBagItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("ClearHighlightBag", self)
end

function BaganatorLiveBagLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  end
  if tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorLiveBagLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
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

function BaganatorLiveBagLayoutMixin:RebuildLayout(indexes, indexesToUse, rowWidth)
  self.buttonPool:ReleaseAll()
  self.indexFramesPool:ReleaseAll()

  self.bagSizesUsed = {}
  self.buttons = {}

  for index, bagID in ipairs(indexes) do
    if indexesToUse[index] then
      self.buttonsByBag[bagID] = {}
      local indexFrame = self.indexFramesPool:Acquire()
      indexFrame:SetID(indexes[index])
      indexFrame:Show()

      local size = C_Container.GetContainerNumSlots(bagID)
      for slotIndex = 1, size do
        local b = self.buttonPool:Acquire()
        b:SetID(slotIndex)
        b:SetParent(indexFrame)
        b:Show()
        table.insert(self.buttons, b)

        self.buttonsByBag[bagID][slotIndex] = b
      end
      self.bagSizesUsed[index] = size
    end
  end

  FlowButtons(self, rowWidth)
end

function BaganatorLiveBagLayoutMixin:CompareButtonIndexes(indexes, indexesToUse)
  for index, bagID in ipairs(indexes) do
    if indexesToUse[index] and self.bagSizesUsed[index] ~= C_Container.GetContainerNumSlots(bagID) then
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

function BaganatorLiveBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local characterData = BAGANATOR_DATA.Characters[character]

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  if self:CompareButtonIndexes(indexes, indexesToUse) or self.prevState.character ~= character or self.prevState.section ~= section then
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("rebuild")
    end
    self:RebuildLayout(indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtons(self, rowWidth)
  end

  if self.refreshContent then
    self.refreshContent = false
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  end

  local sectionData = characterData[section]

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and sectionData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      if #bag == #sectionData[bagIndex] then
        for index, cacheData in ipairs(sectionData[bagIndex]) do
          local button = bag[index]
          button:SetItemDetails(cacheData)
        end
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    local c = 0
    for _ in pairs(indexesToUse) do
      c = c+ 1
    end
    print("live layout took", c, section, debugprofilestop() - start)
  end

  self.prevState = {
    character = character,
    section = section,
  }
  self.waitingUpdate = {}
end

function BaganatorLiveBagLayoutMixin:ApplySearch(text)
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
  end
end

function BaganatorSearchLayoutMonitorMixin:StartSearch(text)
  local start = debugprofilestop()
  self.text = text
  self.pendingItems = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton:SetItemFiltered(text) then
      self.pendingItems[itemButton] = true
    end
  end
  if next(self.pendingItems) then
    self:SetScript("OnUpdate", self.OnUpdate)
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("search monitor start", debugprofilestop() - start)
  end
end

function BaganatorSearchLayoutMonitorMixin:GetMatches()
  local matches = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch then
      table.insert(matches, {
        bagID = itemButton:GetParent():GetID(),
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
      })
    end
  end
  return matches
end

function BaganatorSearchLayoutMonitorMixin:ClearSearch()
end
