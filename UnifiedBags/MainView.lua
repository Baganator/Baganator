local addonName, addonTable = ...

local classicTabObjectCounter = 0

BaganatorMainViewMixin = {}

local function PreallocateItemButtons(pool, buttonCount)
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    for i = 1, buttonCount do
      pool:Acquire()
    end
    pool:ReleaseAll()
  end)
end

function BaganatorMainViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.liveItemButtonPool = Baganator.UnifiedBags.GetLiveItemButtonPool(self)
  self.unallocatedItemButtonPool = Baganator.UnifiedBags.GetLiveItemButtonPool(self)
  self.BagLive:SetPool(self.liveItemButtonPool)
  self.CollapsingBagSectionsPool = Baganator.UnifiedBags.GetCollapsingBagSectionsPool(self)
  self.CollapsingBags = {}
  self.CollapsingBankBags = {}

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  -- 6 is bags + reagent bag (retail) or bags + keyring (wrath)
  PreallocateItemButtons(self.liveItemButtonPool, Baganator.Constants.MaxBagSize * 6)

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
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

  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
    if self.SearchBox:GetText() == "" then
      self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
    end
  end)
  self.SearchBox.clearButton:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end)

  Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsVisible() then
      self:UpdateForCharacter(character, true, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate",  function(_, character)
    if self:IsVisible() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    self.settingChanged = true
    if not self.lastCharacter then
      return
    end
    if tIndexOf(Baganator.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsVisible() then
        Baganator.Utilities.ApplyVisuals(self)
      end
    elseif tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == Baganator.Config.Options.SHOW_RECENTS_TABS then
      local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
      for _, tab in ipairs(self.Tabs) do
        tab:SetShown(isShown)
      end
    elseif settingName == Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    elseif settingName == Baganator.Config.Options.SHOW_BUTTONS_ON_ALT then
      self:UpdateAllButtons()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    self:AddNewRecent(character)
    self:UpdateForCharacter(character, self.liveCharacter == character)
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self.tabsSetup = false
    if self.lastCharacter == character then
      self:UpdateForCharacter(self.liveCharacter, true)
    else
      self:UpdateForCharacter(self.lastCharacter, true)
    end
  end)

  local frame = CreateFrame("Frame")
  local function UpdateMoneyDisplay()
    if IsShiftKeyDown() then
      Baganator.ShowGoldSummaryAccount(self.Money, "ANCHOR_TOP")
    else
      Baganator.ShowGoldSummaryRealm(self.Money, "ANCHOR_TOP")
    end
  end
  self.Money:SetScript("OnEnter", function()
    UpdateMoneyDisplay()
    frame:RegisterEvent("MODIFIER_STATE_CHANGED")
    frame:SetScript("OnEvent", UpdateMoneyDisplay)
  end)

  self.Money:SetScript("OnLeave", function()
    frame:UnregisterEvent("MODIFIER_STATE_CHANGED")
    GameTooltip:Hide()
  end)

  self:CreateBagSlots()

  -- Update currencies when they are watched/unwatched in Blizz UI
  EventRegistry:RegisterCallback("TokenFrame.OnTokenWatchChanged", function()
    if self:IsVisible() then
      self:UpdateCurrencies(self.lastCharacter)
    end
  end)

  self.confirmTransferAllDialogName = "Baganator.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_BAG,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self:Transfer(true)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  addonTable.BagTransferActivationCallback = function()
    self:UpdateTransferButton()
  end
end

function BaganatorMainViewMixin:OnShow()
  if Baganator.Config.Get(Baganator.Config.Options.AUTO_SORT_ON_OPEN) then
    C_Timer.After(0, function()
      self:CombineStacksAndSort()
    end)
  end
  self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
  self:RegisterEvent("MODIFIER_STATE_CHANGED")

  PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
end

function BaganatorMainViewMixin:OnHide()
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Baganator.UnifiedBags.Search.ClearCache()
  self.CharacterSelect:Hide()
  self:UnregisterEvent("MODIFIER_STATE_CHANGED")

  PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
end

function BaganatorMainViewMixin:AllocateBags(character)
  local newDetails = Baganator.UnifiedBags.GetCollapsingBagDetails(character, "bags", Baganator.Constants.AllBagIndexes, Baganator.Constants.BagSlotsCount)

  if self.lastBagDetails == nil or not tCompare(self.lastBagDetails, newDetails, 15) then
    self.CollapsingBags = Baganator.UnifiedBags.AllocateCollapsingSections(
      character, "bags", Baganator.Constants.AllBagIndexes,
      newDetails, self.CollapsingBags,
      self.CollapsingBagSectionsPool, self.liveItemButtonPool)
    self.lastBagDetails = newDetails
  end
end

function BaganatorMainViewMixin:AllocateBankBags(character)
  local newDetails = Baganator.UnifiedBags.GetCollapsingBagDetails(character, "bank", Baganator.Constants.AllBankIndexes, Baganator.Constants.BankBagSlotsCount)
  if self.lastBankBagDetails == nil or not tCompare(self.lastBankBagDetails, newDetails, 5) then
    self.CollapsingBankBags = Baganator.UnifiedBags.AllocateCollapsingSections(
      character, "bank", Baganator.Constants.AllBankIndexes,
      newDetails, self.CollapsingBankBags,
      self.CollapsingBagSectionsPool, self.unallocatedItemButtonPool)
    self.lastBankBagDetails = newDetails
  end
end

function BaganatorMainViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsVisible() then
    return
  end

  if self.isLive then
    self.BagLive:ApplySearch(text)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.live:ApplySearch(text)
    end
  else
    self.BagCached:ApplySearch(text)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:ApplySearch(text)
    end
  end

  if self.BankLive:IsShown() then
    self.BankLive:ApplySearch(text)
    for _, layouts in ipairs(self.CollapsingBankBags) do
      layouts.live:ApplySearch(text)
    end
  elseif self.BankCached:IsShown() then
    self.BankCached:ApplySearch(text)
    for _, layouts in ipairs(self.CollapsingBankBags) do
      layouts.cached:ApplySearch(text)
    end
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
  elseif eventName == "PLAYER_REGEN_DISABLED" then
    -- Disable bag bag slots buttons in combat as pickup/drop doesn't work then
    if not self.liveBagSlots then
      return
    end
    for _, button in ipairs(self.liveBagSlots) do
      SetItemButtonDesaturated(button, true)
      button:Disable()
    end
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    if not self.liveBagSlots then
      return
    end
    for _, button in ipairs(self.liveBagSlots) do
      SetItemButtonDesaturated(button, false)
      button:Enable()
    end
  elseif eventName == "MODIFIER_STATE_CHANGED" then
    self:UpdateAllButtons()
  end
end

function BaganatorMainViewMixin:CreateBagSlots()
  local function GetBagSlotButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBagSlotButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBagSlotButtonTemplate")
    end
  end

  self.liveBagSlots = {}
  for index = 1, Baganator.Constants.BagSlotsCount do
    local bb = GetBagSlotButton()
    table.insert(self.liveBagSlots, bb)
    bb:SetID(index)
    if #self.liveBagSlots ~= 1 then
      bb:SetPoint("TOPLEFT", self.liveBagSlots[#self.liveBagSlots - 1], "TOPRIGHT")
    end
  end

  local cachedBagSlotCounter = 0
  local function GetCachedBagSlotButton()
    -- Use cached item buttons from cached layout views
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailCachedItemButtonTemplate")
    else
      cachedBagSlotCounter = cachedBagSlotCounter + 1
      return CreateFrame("Button", "BGRCachedBagSlotItemButton" .. cachedBagSlotCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end
  end

  self.cachedBagSlots = {}
  for index = 1, Baganator.Constants.BagSlotsCount do
    local bb = GetCachedBagSlotButton()
    bb:UpdateTextures()
    bb.isBag = true
    table.insert(self.cachedBagSlots, bb)
    bb:SetID(index)
    bb:HookScript("OnEnter", function(self)
      Baganator.CallbackRegistry:TriggerEvent("HighlightBagItems", {[self:GetID()] = true})
    end)
    bb:HookScript("OnLeave", function(self)
      Baganator.CallbackRegistry:TriggerEvent("ClearHighlightBag")
    end)
    if #self.cachedBagSlots ~= 1 then
      bb:SetPoint("TOPLEFT", self.cachedBagSlots[#self.cachedBagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorMainViewMixin:UpdateBagSlots()
  -- Show live back slots if viewing live bags
  local show = self.isLive and Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.liveBagSlots) do
    bb:Init()
    bb:SetShown(show)
  end

  -- Show cached bag slots when viewing cached bags for other characters
  local containerInfo = BAGANATOR_DATA.Characters[self.lastCharacter].containerInfo
  if not self.isLive and containerInfo then
    local show = Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
    for index, bb in ipairs(self.cachedBagSlots) do
      local details = CopyTable(containerInfo.bags[index] or {})
      details.itemCount = Baganator.Utilities.CountEmptySlots(BAGANATOR_DATA.Characters[self.lastCharacter].bags[index + 1])
      bb:SetItemDetails(details)
      if not details.iconTexture and not Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND) then
        local _, texture = GetInventorySlotInfo("Bag1")
        SetItemButtonTexture(bb, texture)
      end
      bb:SetShown(show)
    end
  else
    for _, bb in ipairs(self.cachedBagSlots) do
      bb:Hide()
    end
  end

  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bags))
end

function BaganatorMainViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorMainViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_POSITION, {point, x, y})
end

function BaganatorMainViewMixin:ToggleBank()
  self.viewBankShown = not self.viewBankShown
  self:UpdateForCharacter(self.lastCharacter, self.isLive)
end

function BaganatorMainViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorMainViewMixin:ToggleCharacterSidebar()
  self.CharacterSelect:SetShown(not self.CharacterSelect:IsShown())
end

function BaganatorMainViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS))
end


function BaganatorMainViewMixin:SelectTab(character)
  for index, tab in ipairs(self.Tabs) do
    if tab.details == character then
      PanelTemplates_SetTab(self, index)
      break
    end
  end
end

local function DeDuplicateRecents()
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local newRecents = {}
  local seen = {}
  for _, character in ipairs(recents) do
    if BAGANATOR_DATA.Characters[character] and not seen[character] and #newRecents < Baganator.Constants.MaxRecents then
      table.insert(newRecents, character)
    end
    seen[character] = true
  end
  Baganator.Config.Set(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW, newRecents)
end

function BaganatorMainViewMixin:FillRecents(characters)
  local characters = {}
  for char, data in pairs(BAGANATOR_DATA.Characters) do
    table.insert(characters, char)
  end

  table.sort(characters, function(a, b) return a < b end)

  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  table.insert(recents, 1, self.liveCharacter)

  for _, char in ipairs(characters) do
    table.insert(recents, char)
  end

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorMainViewMixin:AddNewRecent(character)
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local data = BAGANATOR_DATA.Characters[character]
  if not data then
    return
  end

  table.insert(recents, 2, character)

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorMainViewMixin:RefreshTabs()
  self.tabsPool:ReleaseAll()

  local characters = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  local sameConnected = {}
  for _, realmNormalized in ipairs(Baganator.Utilities.GetConnectedRealms()) do
    sameConnected[realmNormalized] = true
  end

  local lastTab
  local tabs = {}
  local index = 1
  while #tabs < Baganator.Constants.MaxRecentsTabs and index <= #characters do
    local char = characters[index]
    local details = BAGANATOR_DATA.Characters[char].details
    if sameConnected[details.realmNormalized] then
      local tabButton = self.tabsPool:Acquire()
      tabButton:SetText(details.character)
      tabButton:SetScript("OnClick", function()
        Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", char)
      end)
      if not lastTab then
        tabButton:SetPoint("BOTTOM", 0, -30)
      else
        tabButton:SetPoint("TOPLEFT", lastTab, "TOPRIGHT")
      end
      tabButton.details = char
      tabButton:SetID(index)
      tabButton:SetShown(isShown)
      lastTab = tabButton
      table.insert(tabs, tabButton)
    end
    index = index + 1
  end
  self.Tabs = tabs

  PanelTemplates_SetNumTabs(self, #tabs)
end

function BaganatorMainViewMixin:SetupTabs()
  if self.tabsSetup then
    return
  end

  self:FillRecents(characters)

  self.tabsSetup = self.liveCharacter ~= nil
end

function BaganatorMainViewMixin:HideExtraTabs()
  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(isShown and tab:GetRight() < self:GetRight())
  end
end

function BaganatorMainViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  for _, bagGroup in ipairs(self.CollapsingBags) do
    bagGroup.live:MarkBagsPending("bags", updatedBags)
  end
  for _, bagGroup in ipairs(self.CollapsingBankBags) do
    bagGroup.live:MarkBagsPending("bank", updatedBags)
  end
  self.BankLive:MarkBagsPending("bank", updatedBags)
  self.ReagentBankLive:MarkBagsPending("bank", updatedBags)

  -- Update cached views with current items when bank closed or on login
  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:MarkBagsPending("bags", updatedBags)
    end
    for _, bagGroup in ipairs(self.CollapsingBankBags) do
      bagGroup.cached:MarkBagsPending("bank", updatedBags)
    end
    self.BankCached:MarkBagsPending("bank", updatedBags)
    self.ReagentBankCached:MarkBagsPending("bank", updatedBags)
  end
end

function BaganatorMainViewMixin:UpdateForCharacter(character, isLive, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}
  Baganator.Utilities.ApplyVisuals(self)
  self:SetupTabs()
  self:SelectTab(character)
  self:AllocateBags(character)
  self:AllocateBankBags(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  self.isLive = isLive

  self:UpdateBagSlots()

  if oldLast ~= character then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  local characterData = BAGANATOR_DATA.Characters[character]

  if not characterData then
    self:SetTitle("")
  elseif self.viewBankShown then
    self:SetTitle(BAGANATOR_L_XS_BANK_AND_BAGS:format(characterData.details.character))
  else
    self:SetTitle(BAGANATOR_L_XS_BAGS:format(characterData.details.character))
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton() and isLive)
  self:UpdateTransferButton()

  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BagLive:SetShown(isLive)
  self.BagCached:SetShown(not isLive)

  for _, layouts in ipairs(self.CollapsingBags) do
    layouts.live:SetShown(isLive)
    layouts.cached:SetShown(not isLive)
  end

  self.BankLive:SetShown(self.viewBankShown and (isLive and self.blizzardBankOpen))
  self.BankCached:SetShown(self.viewBankShown and (not isLive or not self.blizzardBankOpen))

  for _, layouts in ipairs(self.CollapsingBankBags) do
    layouts.live:SetShown(self.viewBankShown and (isLive and self.blizzardBankOpen))
    layouts.cached:SetShown(self.viewBankShown and (not isLive or not self.blizzardBankOpen))
  end

  self:NotifyBagUpdate(updatedBags)

  local searchText = self.SearchBox:GetText()

  local activeBag, activeBagCollapsibles, activeBank, activeBankCollapsibles = nil, {}, nil, {}

  if self.BagLive:IsShown() then
    activeBag = self.BagLive
    for _, layouts in ipairs(self.CollapsingBags) do
      table.insert(activeBagCollapsibles, layouts.live)
    end
  else
    activeBag = self.BagCached
    for _, layouts in ipairs(self.CollapsingBags) do
      table.insert(activeBagCollapsibles, layouts.cached)
    end
  end

  if self.BankLive:IsShown() then
    activeBank = self.BankLive
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankCollapsibles, layouts.live)
    end
  elseif self.BankCached:IsShown() then
    activeBank = self.BankCached
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankCollapsibles, layouts.cached)
    end
  end

  local bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)
  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

  activeBag:ShowCharacter(character, "bags", Baganator.Constants.AllBagIndexes, self.lastBagDetails.mainIndexesToUse, bagWidth)

  for index, layout in ipairs(activeBagCollapsibles) do
    layout:ShowCharacter(character, "bags", Baganator.Constants.AllBagIndexes, self.CollapsingBags[index].indexesToUse, bagWidth)
  end

  for index, layout in ipairs(activeBankCollapsibles) do
    layout:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, self.CollapsingBankBags[index].indexesToUse, bankWidth)
  end

  self:ApplySearch(searchText)

  local sideSpacing, topSpacing, dividerOffset, endPadding = 13, 14, 2, 0
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
    dividerOffset = 1
    endPadding = 3
  end

  local bagHeight = activeBag:GetHeight() + topSpacing / 2

  local function ArrangeCollapsibles(activeCollapsibles, originBag, originCollapsibles)
    local lastCollapsible
    local addedHeight = 0
    for index, layout in ipairs(activeCollapsibles) do
      local key = originCollapsibles[index].key
      local hidden = Baganator.Config.Get(Baganator.Config.Options.HIDE_SPECIAL_CONTAINER)[key]
      local divider = originCollapsibles[index].divider
      if hidden then
        divider:Hide()
        layout:Hide()
      else
        divider:SetPoint("BOTTOM", layout, "TOP", 0, topSpacing / 2 + dividerOffset)
        divider:SetPoint("LEFT", layout)
        divider:SetPoint("RIGHT", layout)
        divider:SetShown(layout:GetHeight() > 0)
        if layout:GetHeight() > 0 then
          addedHeight = addedHeight + layout:GetHeight() + topSpacing
          if lastCollapsible == nil then
            layout:SetPoint("TOP", originBag, "BOTTOM", 0, -topSpacing)
          else
            layout:SetPoint("TOP", lastCollapsible, "BOTTOM", 0, -topSpacing)
          end
          lastCollapsible = layout
        end
      end
    end
    return addedHeight + endPadding
  end

  bagHeight = bagHeight + ArrangeCollapsibles(activeBagCollapsibles, activeBag, self.CollapsingBags)
  local height = bagHeight

  if activeBank then
    local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

    activeBank:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, self.lastBankBagDetails.mainIndexesToUse, bankWidth)
    activeBank:ApplySearch(searchText)
    for index, layout in ipairs(activeBankCollapsibles) do
      layout:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, self.CollapsingBankBags[index].indexesToUse, bankWidth)
      layout:ApplySearch(searchText)
    end

    local bankHeight = activeBank:GetHeight() + 6 + ArrangeCollapsibles(activeBankCollapsibles, activeBank, self.CollapsingBankBags)
    height = math.max(bankHeight, height)
    activeBank:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset, - (height - bankHeight)/2 - 50)
  end
  self.BankMissingHint:SetShown(self.viewBankShown and #activeBank.buttons == 0)
  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  self.Tabs[1]:SetPoint("LEFT", activeBag, "LEFT")

  activeBag:SetPoint("TOPRIGHT", -sideSpacing, - (height - bagHeight)/2 - 50)

  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", -sideSpacing, 0)
  self.SearchBox:SetPoint("BOTTOMLEFT", activeBag, "TOPLEFT", 5, 3)
  self.TopButtons[1]:ClearAllPoints()
  self.TopButtons[1]:SetPoint("TOP", self)
  self.TopButtons[1]:SetPoint("LEFT", activeBag, -sideSpacing + 2, 0)
  self.cachedBagSlots[1]:ClearAllPoints()
  self.cachedBagSlots[1]:SetPoint("BOTTOM", self, "TOP")
  self.cachedBagSlots[1]:SetPoint("LEFT", activeBag, -sideSpacing + 4, 0)
  self.liveBagSlots[1]:ClearAllPoints()
  self.liveBagSlots[1]:SetPoint("BOTTOM", self, "TOP")
  self.liveBagSlots[1]:SetPoint("LEFT", activeBag, -sideSpacing + 4, 0)


  -- Used to change the alignment of the title based on the current layout
  local titleOffset = Baganator.Constants.IsClassic and 60 or 0
  local titleText = _G[self:GetName() .. "TitleText"]

  if self.viewBankShown then
    -- Left aligned
    titleText:SetPoint("LEFT", Baganator.Constants.ButtonFrameOffset + 15 + titleOffset, 0)
    titleText:SetPoint("RIGHT", activeBag, "LEFT", -sideSpacing + 2, 0)
  else
    -- Centred
    titleText:SetPoint("LEFT", titleOffset, 0)
    titleText:SetPoint("RIGHT", -titleOffset, 0)
  end

  self:SetSize(
    activeBag:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2 + (activeBank and (activeBank:GetWidth() + sideSpacing * 1 + Baganator.Constants.ButtonFrameOffset - 2) or 0),
    height + 74
  )

  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.AllFixedButtons)
  tAppendAll(self.AllButtons, self.TopButtons)

  self:HideExtraTabs()

  local lastButton = nil
  for index, layout in ipairs(activeBagCollapsibles) do
    local button = self.CollapsingBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    if button:IsShown() then
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBag, -2, 0)
      end
      lastButton = button
      table.insert(self.AllButtons, button)
    end
  end

  local lastButton = nil
  for index, layout in ipairs(activeBankCollapsibles) do
    local button = self.CollapsingBankBags[index].button
    button:SetShown(self.viewBankShown and layout:GetHeight() > 0)
    if button:IsShown() then
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBank, -2, 0)
      end
      table.insert(self.AllButtons, button)
      lastButton = button
    end
  end

  self:UpdateAllButtons()

  self:UpdateCurrencies(character)
end

function BaganatorMainViewMixin:UpdateCurrencies(character)
  self.Money:SetText(Baganator.Utilities.GetMoneyString(BAGANATOR_DATA.Characters[character].money, true))

  local characterCurrencies = BAGANATOR_DATA.Characters[character].currencies

  if not C_CurrencyInfo then
    return
  end

  if not characterCurrencies then
    for _, c in ipairs(self.Currencies) do
      c:SetText("")
    end
    return
  end

  for i = 1, Baganator.Constants.MaxPinnedCurrencies do
    local currencyID, icon
    if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
      local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
      if currencyInfo then
        currencyID = currencyInfo.currencyTypesID
        icon = currencyInfo.iconFileID
      end
    elseif GetBackpackCurrencyInfo then
      icon, currencyID = select(3, GetBackpackCurrencyInfo(i))
    end

    local currencyText = ""

    if currencyID ~= nil then
      local count = 0
      if characterCurrencies[currencyID] ~= nil then
        count = characterCurrencies[currencyID]
      end

      currencyText = BreakUpLargeNumbers(count)
      if strlenutf8(currencyText) > 5 then
        currencyText = AbbreviateNumbers(count)
      end
      currencyText = currencyText .. " " .. CreateSimpleTextureMarkup(icon, 12, 12)
      if GameTooltip.SetCurrencyByID then
        -- Show retail currency tooltip
        self.Currencies[i]:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetCurrencyByID(currencyID)
        end)
      else
        -- SetCurrencyByID doesn't exist on classic, but we want to show the
        -- other characters info via the tooltip anyway
        self.Currencies[i]:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          Baganator.Tooltips.AddCurrencyLines(GameTooltip, currencyID)
        end)
      end
      self.Currencies[i]:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    else
      self.Currencies[i]:SetScript("OnEnter", nil)
    end
    self.Currencies[i]:SetText(currencyText)
  end
end

function BaganatorMainViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(BAGANATOR_DATA.Characters[self.liveCharacter].bags, Baganator.Constants.AllBagIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorMainViewMixin:UpdateTransferButton()
  self.TransferButton:ClearAllPoints()
  if self.SortButton:IsShown() then
    self.TransferButton:SetPoint("RIGHT", self.SortButton, "LEFT")
  else
    self.TransferButton:SetPoint("RIGHT", self.CustomiseButton, "LEFT")
  end

  if not Baganator.Config.Get(Baganator.Config.Options.SHOW_TRANSFER_BUTTON) then
    self.TransferButton:Hide()
    return
  end

  for _, info in ipairs(addonTable.BagTransfers) do
    if info.condition() then
      self.TransferButton:Show()
      self.TransferButton.tooltipText = info.tooltipText
      return
    end
  end
  self.TransferButton:Hide()
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

function BaganatorMainViewMixin:UpdateAllButtons()
  if not self.AllButtons then
    return
  end

  local parent = self
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_BUTTONS_ON_ALT) and not IsAltKeyDown() then
    parent = hiddenParent
  end
  for _, button in ipairs(self.AllButtons) do
    button:SetParent(parent)
    button:SetFrameLevel(700)
  end
end

function BaganatorMainViewMixin:GetMatches()
  local matches = {}
  tAppendAll(matches, self.BagLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorMainViewMixin:RunAction(action)
  action(self:GetMatches(), self.liveCharacter, function(status)
    self.transferManager:Apply(status, function()
      self:RunAction(action)
    end, function()
    end)
  end)
end

function BaganatorMainViewMixin:Transfer(force)
  for _, transferDetails in ipairs(addonTable.BagTransfers) do
    if transferDetails.condition() then
      if not force and transferDetails.confirmOnAll and self.SearchBox:GetText() == "" then
        StaticPopup_Show(self.confirmTransferAllDialogName)
        break
      else
        self:RunAction(transferDetails.action)
        break
      end
    end
  end
end

function BaganatorMainViewMixin:DoSort(isReverse)
  local bagsToSort = {}
  for index, bagID in ipairs(Baganator.Constants.AllBagIndexes) do
    bagsToSort[index] = true
  end
  local bagChecks = Baganator.Sorting.GetBagUsageChecks(Baganator.Constants.AllBagIndexes)
  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyOrdering(
      BAGANATOR_DATA.Characters[self.liveCharacter].bags,
      Baganator.Constants.AllBagIndexes,
      bagsToSort,
      bagChecks,
      isReverse,
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end
  DoSortInternal()
end

function BaganatorMainViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if sortMethod == "blizzard" then
    Baganator.Sorting.BlizzardBagSort(isReverse)
  elseif sortMethod == "sortbags" then
    Baganator.Sorting.ExternalSortBags(isReverse)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end
