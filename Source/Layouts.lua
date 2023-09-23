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

local iconPadding = 2

BaganatorCachedBagLayoutMixin = {}

local ReflowSettings = {
  Baganator.Config.Options.BAG_ICON_SIZE,
  Baganator.Config.Options.EMPTY_SLOT_BACKGROUND,
}

local RefreshContentSettings = {
  Baganator.Config.Options.SHOW_ITEM_LEVEL,
  Baganator.Config.Options.SHOW_BOE_STATUS,
  Baganator.Config.Options.SHOW_BOA_STATUS,
  Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS,
}

local classicCachedObjectCounter = 0

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
end

function BaganatorCachedBagLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  elseif tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
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
        button:SetPoint("TOPLEFT", cols * (iconSize + iconPadding), - rows * (iconSize + iconPadding * 2))
        button:SetSize(iconSize, iconSize)
        button:UpdateTextures(iconSize)
        button:Show()

        table.insert(self.buttons, button)
        bagButtons[slotIndex] = button

        MasqueRegistration(button)

        cols = cols + 1
        if cols >= rowWidth then
          cols = 0
          rows = rows + 1
        end
      end
    end
  end

  self:SetSize(rowWidth * (iconSize + iconPadding), (iconPadding * 2 + iconSize) * ((cols > 0 and (rows + 1) or rows)))
  self.oldRowWidth = rowWidth
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
  local emptySlotBackground = Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND)

  if self.prevState.character ~= character or self.prevState.section ~= section or
      self:CompareButtonIndexes(indexes, indexesToUse, sectionData) or rowWidth ~= self.oldRowWidth or
      self.reflow or self.refreshContent then
    self.reflow = false
    self.refreshContent = false
    self:RebuildLayout(sectionData, indexes, indexesToUse, rowWidth)
    self.waitingUpdate = {}
    for index in pairs(indexesToUse) do
      self.waitingUpdate[indexes[index]] = true
    end
  end

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and sectionData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      for index, slotInfo in ipairs(sectionData[bagIndex]) do
        local button = bag[index]
        button:SetItemDetails(slotInfo)
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
  self.oldEmptySlotBackground = emptySlotBackground
end

function BaganatorCachedBagLayoutMixin:ApplySearch(text)
  local start = debugprofilestop()
  for _, itemButton in ipairs(self.buttons) do
    itemButton:SetItemFiltered(text)
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("cache search", debugprofilestop() - start)
  end
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

  self:RegisterEvent("ITEM_LOCK_CHANGED")
end

function BaganatorLiveBagLayoutMixin:OnEvent(eventName, ...)
  if eventName == "ITEM_LOCK_CHANGED" then
    local bagID, slotID = ...
    self:UpdateLockForItem(bagID, slotID)
  elseif event == "BAG_UPDATE_COOLDOWN" then
    for _, button in ipairs(self.buttons) do
      button:UpdateCooldown(button.itemLink ~= nil)
    end
  end
end

function BaganatorLiveBagLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  elseif tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
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
    SetItemButtonDesaturated(itemButton, locked)
  end
end

function BaganatorLiveBagLayoutMixin:FlowButtons(rowWidth)
  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  local rows, cols = 0, 0
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (iconSize + iconPadding), - rows * (iconSize + iconPadding * 2))
    button:SetSize(iconSize, iconSize)
    button:UpdateTextures(iconSize)
    MasqueRegistration(button)
    cols = cols + 1
    if cols >= rowWidth then
      cols = 0
      rows = rows + 1
    end
  end

  self:SetSize(rowWidth * (iconSize + iconPadding), (iconPadding * 2 + iconSize) * ((cols > 0 and (rows + 1) or rows)))
  self.oldRowWidth = rowWidth
end

function BaganatorLiveBagLayoutMixin:RebuildLayout(indexes, indexesToUse, rowWidth)
  self.buttonPool:ReleaseAll()
  local indexFrames = {}
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

  self:FlowButtons(rowWidth)
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
  local emptySlotBackground = Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND)

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
    self:FlowButtons(rowWidth)
  end

  if self.refreshContent then
    self.refreshContent = false
    for _, bagID in ipairs(indexes) do
      self.waitingUpdate[bagID] = true
    end
  end

  local indexesReversed = {}
  for index, bagID in ipairs(indexes) do
    indexesReversed[bagID] = index
  end

  local sectionData = characterData[section]

  for bagID in pairs(self.waitingUpdate) do
    local bagIndex = tIndexOf(indexes, bagID)
    if bagIndex ~= nil and sectionData[bagIndex] and indexesToUse[bagIndex] then
      local bag = self.buttonsByBag[bagID]
      for index, cacheData in ipairs(sectionData[bagIndex]) do
        local button = bag[index]
        button:SetItemDetails(cacheData)
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
  local start = debugprofilestop()
  for _, itemButton in ipairs(self.buttons) do
    itemButton:SetItemFiltered(text)
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("live search", debugprofilestop() - start)
  end
end
