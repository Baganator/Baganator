local MasqueRegistration = function() end

if LibStub then
  -- Establish a reference to Masque.
  local Masque, MSQ_Version = LibStub("Masque", true)
  if Masque ~= nil then
    -- Retrieve a reference to a new or existing group.
    local masqueGroup = Masque:Group("Baganator", "Bag")

    MasqueRegistration = function(button)
      if button.masqueApplied then
        masqueGroup:ReSkin(button)
      else
        button.masqueApplied = true
        masqueGroup:AddButton(button, nil, "Item")
      end
    end
  end
end

local function GetNameFromLink(itemLink)
  return (string.match(itemLink, "h%[(.*)%]|h"):gsub(" ?|A.-|a", ""))
end

local function RegisterHighlightSimilarItems(self)
  Baganator.CallbackRegistry:RegisterCallback("HighlightSimilarItems", function(_, itemLink)
    if not Baganator.Config.Get(Baganator.Config.Options.ICON_FLASH_SIMILAR_ALT) or itemLink == "" then
      return
    end
    local itemName = GetNameFromLink(itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink and GetNameFromLink(button.BGR.itemLink) == itemName then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

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

local function GetPaddingAndSize()
  local iconPadding = 4

  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    iconPadding = 1
  end

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)

  return iconPadding, iconSize
end

local function ApplySizing(self, rowWidth, iconPadding, iconSize, flexDimension, staticDimension)
  self:SetSize(rowWidth * (iconSize + iconPadding) - iconPadding, (iconPadding + iconSize) * ((flexDimension > 0 and (staticDimension + 1) or staticDimension)))
end

local function FlowButtonsRows(self, rowWidth)
  local iconPadding, iconSize = GetPaddingAndSize()

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

  ApplySizing(self, rowWidth, iconPadding, iconSize, cols, rows)
  self.oldRowWidth = rowWidth
end

local function FlowButtonsColumns(self, rowWidth)
  local iconPadding, iconSize = GetPaddingAndSize()

  local columnHeight = math.ceil(#self.buttons / rowWidth)

  local rows, cols = 0, 0

  local iconPaddingScaled = iconPadding * 37 / iconSize
  for _, button in ipairs(self.buttons) do
    button:SetPoint("TOPLEFT", self, cols * (37 + iconPaddingScaled), - rows * (37 + iconPaddingScaled))
    button:SetScale(iconSize / 37)
    button:UpdateTextures()
    MasqueRegistration(button)
    rows = rows + 1
    if rows >= columnHeight then
      rows = 0
      cols = cols + 1
    end
  end

  ApplySizing(self, rowWidth, iconPadding, iconSize, cols, columnHeight - 1)
  self.oldRowWidth = rowWidth
end

BaganatorCachedBagLayoutMixin = {}

function BaganatorCachedBagLayoutMixin:OnLoad()
  self.buttonPool = Baganator.UnifiedViews.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.buttonsByBag = {}
  self.waitingUpdate = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")
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

  FlowButtonsRows(self, rowWidth)
end

function BaganatorCachedBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local characterData = Syndicator.API.GetCharacter(character)

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
    FlowButtonsRows(self, rowWidth)
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
    print("cached bag layout took", c, section, debugprofilestop() - start)
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
  Baganator.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, highlightBagIDs)
    for bagID, bag in pairs(self.buttonsByBag) do
      for slotID, button in ipairs(bag) do
        button:BGRSetHighlight(highlightBagIDs[bagID])
      end
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  RegisterHighlightSimilarItems(self)

  Baganator.CallbackRegistry:RegisterCallback("HighlightIdenticalItems", function(_, itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink == itemLink then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

function BaganatorCachedBagLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightBagItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("ClearHighlightBag", self)
end

BaganatorLiveBagLayoutMixin = {}

local LIVE_LAYOUT_EVENTS = {
  "BAG_UPDATE_COOLDOWN",
  "UNIT_QUEST_LOG_CHANGED",
  "QUEST_ACCEPTED",
}

function BaganatorLiveBagLayoutMixin:OnLoad()
  self.buttonPool = Baganator.UnifiedViews.GetLiveItemButtonPool(self)
  self.indexFramesPool = CreateFramePool("Frame", self)
  self.buttons = {}
  self.buttonsByBag = {}
  self.bagSizesUsed = {}
  self.waitingUpdate = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorBagSearchLayoutMonitorTemplate")

  self:RegisterEvent("ITEM_LOCK_CHANGED")
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

function BaganatorLiveBagLayoutMixin:UpdateQuests()
  for _, button in ipairs(self.buttons) do
    if button.BGR and button.BGR.isQuestItem then
      local item = Item:CreateFromItemID(button.BGR.itemID)
      item:ContinueOnItemLoad(function()
        button:BGRUpdateQuests()
      end)
    end
  end
end

function BaganatorLiveBagLayoutMixin:OnEvent(eventName, ...)
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

function BaganatorLiveBagLayoutMixin:OnShow()
  FrameUtil.RegisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  local start = debugprofilestop()
  self:UpdateCooldowns()
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("update cooldowns show", debugprofilestop() - start)
  end
  self:UpdateQuests()

  Baganator.CallbackRegistry:RegisterCallback("HighlightBagItems", function(_, bagIDs)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(bagIDs[button:GetParent():GetID()])
    end
  end, self)

  Baganator.CallbackRegistry:RegisterCallback("ClearHighlightBag", function(_, itemName)
    for _, button in ipairs(self.buttons) do
      button:BGRSetHighlight(false)
    end
  end, self)

  RegisterHighlightSimilarItems(self)

  Baganator.CallbackRegistry:RegisterCallback("HighlightIdenticalItems", function(_, itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink == itemLink then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

function BaganatorLiveBagLayoutMixin:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, LIVE_LAYOUT_EVENTS)
  local start = debugprofilestop()
  for _, button in ipairs(self.buttons) do
    button:ClearNewItem()
  end
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("remove new item", debugprofilestop() - start)
  end

  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
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

function BaganatorLiveBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end

  local start = debugprofilestop()

  local characterData = Syndicator.API.GetCharacter(character)

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
    FlowButtonsRows(self, rowWidth)
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
    print("live bag layout took", section, debugprofilestop() - start)
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

BaganatorGeneralGuildLayoutMixin = {}

function BaganatorGeneralGuildLayoutMixin:OnLoad()
  self.buttonPool = Baganator.UnifiedViews.GetCachedItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")
  self.layoutType = "cached"
end

function BaganatorGeneralGuildLayoutMixin:ApplySearch(text)
  self.SearchMonitor:StartSearch(text)
end

function BaganatorGeneralGuildLayoutMixin:OnShow()
  RegisterHighlightSimilarItems(self)

  Baganator.CallbackRegistry:RegisterCallback("HighlightIdenticalItems", function(_, itemLink)
    for _, button in ipairs(self.buttons) do
      if button.BGR.itemLink == itemLink then
        button:BGRStartFlashing()
      end
    end
  end, self)
end

function BaganatorGeneralGuildLayoutMixin:OnHide()
  Baganator.CallbackRegistry:UnregisterCallback("HighlightSimilarItems", self)
  Baganator.CallbackRegistry:UnregisterCallback("HighlightIdenticalItems", self)
end

function BaganatorGeneralGuildLayoutMixin:InformSettingChanged(setting)
  if tIndexOf(ReflowSettings, setting) ~= nil then
    self.reflow = true
  elseif tIndexOf(RefreshContentSettings, setting) ~= nil then
    self.refreshContent = true
  end
end

function BaganatorGeneralGuildLayoutMixin:RequestContentRefresh()
  self.refreshContent = true
end

function BaganatorGeneralGuildLayoutMixin:RebuildLayout(rowWidth)
  self.buttons = {}
  self.buttonPool:ReleaseAll()

  for index = 1, Syndicator.Constants.MaxGuildBankTabItemSlots do
    local button = self.buttonPool:Acquire()
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
    self.refreshContent = true
    self:RebuildLayout(rowWidth)
  elseif self.reflow or rowWidth ~= self.oldRowWidth then
    self.reflow = false
    FlowButtonsColumns(self, rowWidth)
  end

  if not guildData then
    return
  end

  if self.prevState.guild ~= guild or self.prevState.tabIndex ~= tabIndex then
    self.refreshContent = true
  end

  if self.refreshContent then
    self.refreshContent = false

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

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print(self.layoutType .. " guild layout took", tabIndex, debugprofilestop() - start)
  end

  self.prevState = {
    guild = guild,
    tabIndex = tabIndex,
  }
end

BaganatorLiveGuildLayoutMixin = CreateFromMixins(BaganatorGeneralGuildLayoutMixin)

function BaganatorLiveGuildLayoutMixin:OnLoad()
  self.buttonPool = Baganator.UnifiedViews.GetLiveGuildItemButtonPool(self)
  self.buttons = {}
  self.prevState = {}
  self.SearchMonitor = CreateFrame("Frame", nil, self, "BaganatorGuildSearchLayoutMonitorTemplate")
  self.layoutType = "live"

  self:RegisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")
end

function BaganatorLiveGuildLayoutMixin:OnEvent(eventName, ...)
  if eventName == "GUILDBANK_ITEM_LOCK_CHANGED" and self.prevState and self.prevState.guild ~= nil and self.prevState.guild ~= "" then
    self.refreshContent = true
    self:ShowGuild(self.prevState.guild, self.prevState.tabIndex, self.oldRowWidth)
    self.SearchMonitor:StartSearch(self.SearchMonitor.text)
  end
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

BaganatorBagSearchLayoutMonitorMixin = CreateFromMixins(BaganatorSearchLayoutMonitorMixin)

function BaganatorBagSearchLayoutMonitorMixin:GetMatches()
  local matches = {}
  for _, itemButton in ipairs(self:GetParent().buttons) do
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch then
      table.insert(matches, {
        bagID = itemButton:GetParent():GetID(),
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
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
    if itemButton.BGR and itemButton.BGR.itemID and itemButton.BGR.matchesSearch then
      table.insert(matches, {
        tabIndex = self:GetParent().prevState.tabIndex,
        slotID = itemButton:GetID(),
        itemCount = itemButton.BGR.itemCount,
        itemID = itemButton.BGR.itemID,
      })
    end
  end
  return matches
end
