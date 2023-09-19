BaganatorMainViewMixin = {}

local classicTabObjectCounter = 0

local FRAME_SETTINGS = {
  Baganator.Config.Options.VIEW_ALPHA,
  Baganator.Config.Options.NO_FRAME_BORDERS,
}

local ITEM_BUTTON_SETTINGS = {
  Baganator.Config.Options.BAG_ICON_SIZE,
  Baganator.Config.Options.EMPTY_SLOT_BACKGROUND,
  Baganator.Config.Options.BAG_VIEW_WIDTH,
  Baganator.Config.Options.BANK_VIEW_WIDTH,
  Baganator.Config.Options.SHOW_REAGENTS,
}

function BaganatorMainViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })

  self.blizzardBankOpen = false
  self.viewBankShown = false

  if Baganator.Constants.IsRetail then
    self.tabsPool = CreateFramePool("Button", self, "BaganatorRetailTabButtonTemplate")
  else
    self.tabsPool = CreateObjectPool(function(pool)
      classicTabObjectCounter = classicTabObjectCounter + 1
      return CreateFrame("Button", "BGRMainViewTabButton" .. classicTabObjectCounter, self, "BaganatorClassicTabButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end

  self.SearchBox:HookScript("OnTextChanged", function()
    local text = self.SearchBox:GetText()
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsShown() then
      self:UpdateForCharacter(character, true, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("BagShow",  function(_, ...)
    self:Show()
  end)

  Baganator.CallbackRegistry:RegisterCallback("BagHide",  function(_, ...)
    self:Hide()
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter or not self:IsShown() then
      return
    end
    if tIndexOf(FRAME_SETTINGS, settingName) ~= nil then
      Baganator.Utilities.ApplyVisuals(self)
    elseif tIndexOf(ITEM_BUTTON_SETTINGS, settingName) ~= nil then
      if self.lastCharacter then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    if self:IsShown() then
      self:ApplySearch(text)
    end
  end)
end

function BaganatorMainViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsShown() then
    return
  end

  if self.isLive then
    self.BagLive:ApplySearch(text)
    self.ReagentBagLive:ApplySearch(text)
  else
    self.BagCached:ApplySearch(text)
    self.ReagentBagCached:ApplySearch(text)
  end

  if self.BankLive:IsShown() then
    self.BankLive:ApplySearch(text)
    self.ReagentBankLive:ApplySearch(text)
  elseif self.BankCached:IsShown() then
    self.BankCached:ApplySearch(text)
    self.ReagentBankCached:ApplySearch(text)
  end
end

function BaganatorMainViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorMainViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self.blizzardBankOpen = true
    if self:IsVisible() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, true)
    end
  elseif eventName == "BANKFRAME_CLOSED" then
    self.blizzardBankOpen = false
    if self:IsVisible() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, true)
    end
  end
end

function BaganatorMainViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
  end
end

function BaganatorMainViewMixin:OnDragStop()
  self:StopMovingOrSizing()
end

function BaganatorMainViewMixin:ToggleBank()
  self.viewBankShown = not self.viewBankShown
  self:UpdateForCharacter(self.lastCharacter, self.isLive)
end

function BaganatorMainViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorMainViewMixin:SelectTab(character)
  for index, tab in ipairs(self.Tabs) do
    if tab.details.character == character then
      PanelTemplates_SetTab(self, index)
      break
    end
  end
end

function BaganatorMainViewMixin:SetupTabs()
  if tabsSetup then
    return
  end

  self.tabsPool:ReleaseAll()

  local characters = {}
  for char, data in pairs(BAGANATOR_DATA.Characters) do
    if char ~= self.liveCharacter  then
      table.insert(characters, {character = char, nameOnly = data.details.character, isLive = false})
    end
  end
  table.sort(characters, function(a, b) return a.character < b.character end)
  for char, data in pairs(BAGANATOR_DATA.Characters) do
    if char == self.liveCharacter  then
      table.insert(characters, 1, {character = char, nameOnly = data.details.character, isLive = true})
    end
  end

  local lastTab
  tabs = {}
  for index, char in ipairs(characters) do
    local tabButton = self.tabsPool:Acquire()
    tabButton:SetText(char.nameOnly)
    tabButton:SetScript("OnClick", function()
      self:UpdateForCharacter(char.character, char.isLive) 
      PanelTemplates_SetTab(self, index)
    end)
    if not lastTab then
      tabButton:SetPoint("BOTTOM", 0, -30)
    else
      tabButton:SetPoint("TOPLEFT", lastTab, "TOPRIGHT")
    end
    tabButton.details = char
    tabButton:SetID(index)
    tabButton:Show()
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end
  self.Tabs = tabs

  PanelTemplates_SetNumTabs(self, #characters)

  self.tabsSetup = self.liveCharacter ~= nil
end

function BaganatorMainViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)

  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
    self.BankCached:MarkBagsPending("bank", updatedBags)
  end
end

function BaganatorMainViewMixin:UpdateForCharacter(character, isLive, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}
  Baganator.Utilities.ApplyVisuals(self)
  self:SetupTabs()
  self:SelectTab(character)

  self.lastCharacter = character
  self.isLive = isLive

  if self.viewBankShown then
    self:SetTitle(BAGANATOR_L_XS_BANK_AND_BAGS:format(character))
  else
    self:SetTitle(BAGANATOR_L_XS_BAGS:format(character))
  end

  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BagLive:SetShown(isLive)
  self.ReagentBagLive:SetShown(isLive and showReagents)
  self.BagCached:SetShown(not isLive)
  self.ReagentBagCached:SetShown(not isLive and showReagents)

  self.BankLive:SetShown(self.viewBankShown and (isLive and self.blizzardBankOpen))
  self.ReagentBankLive:SetShown(self.viewBankShown and showReagents and (isLive and self.blizzardBankOpen))
  self.BankCached:SetShown(self.viewBankShown and (not isLive or not self.blizzardBankOpen))
  self.ReagentBankCached:SetShown(self.viewBankShown and showReagents and (not isLive or not self.blizzardBankOpen))

  self:NotifyBagUpdate(updatedBags)

  local searchText = self.SearchBox:GetText()

  local bagIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true
  }
  local reagentBagIndexesToUse = {}
  if Baganator.Constants.IsRetail then
    reagentBagIndexesToUse = {
      [6] = true
    }
  end

  local bankIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true
  }
  local reagentBankIndexesToUse = {}
  if Baganator.Constants.IsRetail then
    reagentBankIndexesToUse = {
      [9] = true
    }
  end

  local activeBag, activeReagentBag, activeBank, activeReagentBank

  if self.BagLive:IsShown() then
    activeBag = self.BagLive
    activeReagentBag = self.ReagentBagLive
  else
    activeBag = self.BagCached
    activeReagentBag = self.ReagentBagCached
  end

  if self.BankLive:IsShown() then
    activeBank = self.BankLive
    activeReagentBank = self.ReagentBankLive
  elseif self.BankCached:IsShown() then
    activeBank = self.BankCached
    activeReagentBank = self.ReagentBankCached
  end

  local bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)

  activeBag:ShowCharacter(character, "bags", Baganator.Constants.AllBagIndexes, bagIndexesToUse, bagWidth)
  activeBag:ApplySearch(searchText)

  activeReagentBag:ShowCharacter(character, "bags", Baganator.Constants.AllBagIndexes, reagentBagIndexesToUse, bagWidth)
  activeReagentBag:ApplySearch(searchText)

  local bagHeight = activeBag:GetHeight()
  if activeReagentBag:GetHeight() > 0 then
    if showReagents then
      bagHeight = bagHeight + activeReagentBag:GetHeight() + 40
    else
      bagHeight = bagHeight + 20
    end
  else
    activeReagentBag:Hide()
  end

  local height = bagHeight

  if activeBank then
    local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

    activeBank:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, bankIndexesToUse, bankWidth)
    activeReagentBank:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, reagentBankIndexesToUse, bankWidth)
    activeBank:ApplySearch(searchText)
    activeReagentBank:ApplySearch(searchText)

    local bankHeight = activeBank:GetHeight()
    if activeReagentBank:GetHeight() > 0 then
      if showReagents then
        bankHeight = bankHeight + activeReagentBank:GetHeight() + 40
      else
        bankHeight = bankHeight + 20
      end
    else
      activeReagentBank:Hide()
    end
    height = math.max(bankHeight, height)
    activeBank:SetPoint("TOPLEFT", 13, - (height - bankHeight)/2 - 40)
  end

  self.Tabs[1]:SetPoint("LEFT", activeBag, "LEFT")

  activeBag:SetPoint("TOPRIGHT", -13, - (height - bagHeight)/2 - 50)

  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", -13, 0)
  self.SearchBox:SetPoint("BOTTOMLEFT", activeBag, "TOPLEFT", 5, 3)
  self.ToggleBankButton:ClearAllPoints()
  self.ToggleBankButton:SetPoint("TOP")
  self.ToggleBankButton:SetPoint("LEFT", activeBag, -13, 0)
  self:SetSize(
    activeBag:GetWidth() + 30 + (activeBank and activeBank:GetWidth() + 30 or 0),
    height + 68
  )

  self.ToggleReagentsButton:SetShown(activeReagentBag:GetHeight() > 0 or activeReagentBag:IsShown())
  if self.ToggleReagentsButton:IsShown() then
    self.ToggleReagentsButton:ClearAllPoints()
    self.ToggleReagentsButton:SetPoint("TOPLEFT", activeBag, "BOTTOMLEFT", -2, -5)
  end
  self.ToggleReagentsBankButton:SetShown(activeReagentBank and activeReagentBank:GetHeight() > 0)
  if self.ToggleReagentsBankButton:IsShown() then
    self.ToggleReagentsBankButton:ClearAllPoints()
    self.ToggleReagentsBankButton:SetPoint("TOPLEFT", activeBank, "BOTTOMLEFT", -2, -5)
  end

  self.Money:SetText(GetMoneyString(BAGANATOR_DATA.Characters[character].money, true))
end

BaganatorBankOnlyViewMixin = {}
function BaganatorBankOnlyViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })

  self.SearchBox:HookScript("OnTextChanged", function()
    local text = self.SearchBox:GetText()
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsShown() then
      self:UpdateForCharacter(character, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.liveCharacter or not self:IsShown() then
      return
    end
    if tIndexOf(FRAME_SETTINGS, settingName) ~= nil then
      Baganator.Utilities.ApplyVisuals(self)
    elseif tIndexOf(ITEM_BUTTON_SETTINGS, settingName) ~= nil then
      if self.liveCharacter then
        self:UpdateForCharacter(self.liveCharacter)
      end
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    if self:IsShown() then
      self:ApplySearch(text)
    end
  end)
end

function BaganatorBankOnlyViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
  end
end

function BaganatorBankOnlyViewMixin:OnDragStop()
  self:StopMovingOrSizing()
end

function BaganatorBankOnlyViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorBankOnlyViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsShown() then
    return
  end

  self.BankLive:ApplySearch(text)
  self.ReagentBankLive:ApplySearch(text)
end

function BaganatorBankOnlyViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self:Show()
    if self.liveCharacter then
      self:UpdateForCharacter(self.liveCharacter)
    end
  else
    self:Hide()
  end
end

function BaganatorBankOnlyViewMixin:OnShow()
  Baganator.CallbackRegistry:TriggerEvent("BagShow", "bankOnly")
end

function BaganatorBankOnlyViewMixin:OnHide(eventName)
  Baganator.CallbackRegistry:TriggerEvent("BagHide", "bankOnly")
  CloseBankFrame()
end

function BaganatorBankOnlyViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorBankOnlyViewMixin:UpdateForCharacter(character, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}

  Baganator.Utilities.ApplyVisuals(self)

  local searchText = self.SearchBox:GetText()

  local bankIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true
  }
  local reagentBankIndexesToUse = {}
  if Baganator.Constants.IsRetail then
    reagentBankIndexesToUse = {
      [9] = true
    }
  end

  self:NotifyBagUpdate(updatedBags)

  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)
  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, bankIndexesToUse, bankWidth)
  self.BankLive:ApplySearch(searchText)

  self.ReagentBankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, reagentBankIndexesToUse, bankWidth)
  self.ReagentBankLive:ApplySearch(searchText)

  self.ReagentBankLive:SetShown(self.ReagentBankLive:GetHeight() > 0 and showReagents)

  self.ToggleReagentsBankButton:SetShown(self.ReagentBankLive:GetHeight() > 0)
  local reagentBankHeight = self.ReagentBankLive:GetHeight()
  if reagentBankHeight > 0 then
    if self.ReagentBankLive:IsShown() then
      reagentBankHeight = reagentBankHeight + 40
    else
      reagentBankHeight = 30
    end
  end

  self:SetSize(
    self.BankLive:GetWidth() + 30,
    self.BankLive:GetHeight() + reagentBankHeight + 55
  )

  self:SetTitle(BAGANATOR_L_XS_BANK:format(character))
end

function BaganatorBankOnlyViewMixin:NotifyBagUpdate(updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)
  self.ReagentBankLive:MarkBagsPending("bank", updatedBags)
end

local masqueGroup
local function MasqueRegistration(button)
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

function BaganatorCachedBagLayoutMixin:CompareButtonIndexes(indexes, indexesToUse, newBags)
  for index in pairs(indexesToUse) do
    local bagID = indexes[index]
    if not self.buttonsByBag[bagID] or #self.buttonsByBag[bagID] ~= #newBags[index] then
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
  self.oldIconSize = iconSize
end

function BaganatorCachedBagLayoutMixin:ShowCharacter(character, section, indexes, indexesToUse, rowWidth)
  if indexesToUse == nil then
    indexesToUse = {}
    for index in ipairs(indexes) do
      indexesToUse[index] = true
    end
  end
  local characterData = BAGANATOR_DATA.Characters[character]

  if not characterData then
    return
  end

  local sectionData = characterData[section]

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)
  local emptySlotBackground = Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND)

  if self.prevState.character ~= character or self.prevState.section ~= section or
      self:CompareButtonIndexes(indexes, indexesToUse, sectionData) or rowWidth ~= self.oldRowWidth or
      iconSize ~= self.oldIconSize or emptySlotBackground ~= self.oldEmptySlotBackground then
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

  self.waitingUpdate = {}
  self.prevState = {
    character = character,
    section = section,
  }
  self.oldEmptySlotBackground = emptySlotBackground
end

function BaganatorCachedBagLayoutMixin:ApplySearch(text)
  for _, itemButton in ipairs(self.buttons) do
    itemButton:SetItemFiltered(text)
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
  self.oldIconSize = iconSize
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
      table.insert(self.bagSizesUsed, size)
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

  local characterData = BAGANATOR_DATA.Characters[character]

  local iconSize = Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE)
  local emptySlotBackground = Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND)

  if not InCombatLockdown() then
    if self:CompareButtonIndexes(indexes, indexesToUse) or self.prevState.character ~= character or self.prevState.section ~= section or
          emptySlotBackground ~= self.oldEmptySlotBackground then
      self:RebuildLayout(indexes, indexesToUse, rowWidth)
      self.waitingUpdate = {}
      for _, bagID in ipairs(indexes) do
        self.waitingUpdate[bagID] = true
      end
    elseif rowWidth ~= self.oldRowWidth or iconSize ~= self.oldIconSize then
      self:FlowButtons(rowWidth)
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

  self.prevState = {
    character = character,
    section = section,
  }
  self.waitingUpdate = {}
  self.oldEmptySlotBackground = emptySlotBackground
end

function BaganatorLiveBagLayoutMixin:ApplySearch(text)
  for _, itemButton in ipairs(self.buttons) do
    itemButton:SetItemFiltered(text)
  end
end
