local addonName, addonTable = ...

local classicTabObjectCounter = 0

BaganatorSingleViewBackpackViewMixin = {}

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

function BaganatorSingleViewBackpackViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.liveItemButtonPool = Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  self.BagLive:SetPool(self.liveItemButtonPool)
  self.CollapsingBagSectionsPool = Baganator.SingleViews.GetCollapsingBagSectionsPool(self)
  self.CollapsingBags = {}
  self.bagDetailsForComparison = {}

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  -- 6 is bags + reagent bag (retail) or bags + keyring (wrath)
  PreallocateItemButtons(self.liveItemButtonPool, Syndicator.Constants.MaxBagSize * 6)

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  self.tabsPool = Baganator.ItemViewCommon.GetTabButtonPool(self)

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self.searchToApply = true
    self:NotifyBagUpdate(updatedBags)
    if self:IsVisible() then
      self:UpdateForCharacter(character, true)
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
      for index, tab in ipairs(self.Tabs) do
        tab:SetShown(isShown)
        if tab.details == self.lastCharacter then
          PanelTemplates_SetTab(self, index)
        end
      end
    elseif settingName == Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS then
      self.BagSlots:Update(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.searchToApply = true
    self:ApplySearch(text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if character ~= self.lastCharacter then
      self:AddNewRecent(character)
      self:UpdateForCharacter(character, self.liveCharacter == character)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
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

  if Baganator.Constants.IsEra or not Baganator.Config.Get(Baganator.Config.Options.SHOW_GUILD_BANK_BUTTON) then
    local index = tIndexOf(self.TopButtons, self.ToggleGuildBankButton)
    table.remove(self.TopButtons, index)
    self.ToggleGuildBankButton:Hide()
  end

  for index = 2, #self.TopButtons do
    local button = self.TopButtons[index]
    button:SetPoint("TOPLEFT", self.TopButtons[index-1], "TOPRIGHT")
  end

  self.BagSlots:SetPoint("BOTTOMLEFT", self, "TOPLEFT", Baganator.Constants.ButtonFrameOffset, 0)
end

function BaganatorSingleViewBackpackViewMixin:OnShow()
  if Baganator.Config.Get(Baganator.Config.Options.AUTO_SORT_ON_OPEN) then
    C_Timer.After(0, function()
      self:CombineStacksAndSort()
    end)
  end
  PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
end

function BaganatorSingleViewBackpackViewMixin:OnHide()
  PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
end

function BaganatorSingleViewBackpackViewMixin:AllocateBags(character)
  local newDetails = Baganator.SingleViews.GetCollapsingBagDetails(character, "bags", Syndicator.Constants.AllBagIndexes, Syndicator.Constants.BagSlotsCount)
  if self.bagDetailsForComparison.bags == nil or not tCompare(self.bagDetailsForComparison.bags, newDetails, 15) then
    self.bagDetailsForComparison.bags = CopyTable(newDetails)
    self.CollapsingBags = Baganator.SingleViews.AllocateCollapsingSections(
      character, "bags", Syndicator.Constants.AllBagIndexes,
      newDetails, self.CollapsingBags,
      self.CollapsingBagSectionsPool, self.liveItemButtonPool)
    self.lastBagDetails = newDetails
  end
end

function BaganatorSingleViewBackpackViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end
  self.searchToApply = false

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
end

function BaganatorSingleViewBackpackViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorSingleViewBackpackViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorSingleViewBackpackViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_POSITION, {point, x, y})
end

function BaganatorSingleViewBackpackViewMixin:ToggleBank()
  Baganator.CallbackRegistry:TriggerEvent("BankToggle", self.lastCharacter)
  self:Raise()
end

function BaganatorSingleViewBackpackViewMixin:ToggleGuildBank()
  Baganator.CallbackRegistry:TriggerEvent("GuildToggle", Syndicator.API.GetCharacter(self.lastCharacter).details.guild)
end

function BaganatorSingleViewBackpackViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorSingleViewBackpackViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS))
end


function BaganatorSingleViewBackpackViewMixin:SelectTab(character)
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
    if Syndicator.API.GetCharacter(character) and not seen[character] and #newRecents < Baganator.Constants.MaxRecents then
      table.insert(newRecents, character)
    end
    seen[character] = true
  end
  Baganator.Config.Set(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW, newRecents)
end

function BaganatorSingleViewBackpackViewMixin:FillRecents(characters)
  local characters = Syndicator.API.GetAllCharacters()

  table.sort(characters, function(a, b) return a < b end)

  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  table.insert(recents, 1, self.liveCharacter)

  for _, char in ipairs(characters) do
    table.insert(recents, char)
  end

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorSingleViewBackpackViewMixin:AddNewRecent(character)
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local data = Syndicator.API.GetCharacter(character)
  if not data then
    return
  end

  table.insert(recents, 2, character)

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorSingleViewBackpackViewMixin:RefreshTabs()
  self.tabsPool:ReleaseAll()

  local characters = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  local sameConnected = {}
  for _, realmNormalized in ipairs(Syndicator.Utilities.GetConnectedRealms()) do
    sameConnected[realmNormalized] = true
  end

  local lastTab
  local tabs = {}
  local index = 1
  while #tabs < Baganator.Constants.MaxRecentsTabs and index <= #characters do
    local char = characters[index]
    local details = Syndicator.API.GetCharacter(char).details
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

function BaganatorSingleViewBackpackViewMixin:SetupTabs()
  if self.tabsSetup then
    return
  end

  self:FillRecents(characters)

  self.tabsSetup = self.liveCharacter ~= nil
end

function BaganatorSingleViewBackpackViewMixin:HideExtraTabs()
  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(isShown and tab:GetRight() < self:GetRight())
  end
end

function BaganatorSingleViewBackpackViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  for _, bagGroup in ipairs(self.CollapsingBags) do
    bagGroup.live:MarkBagsPending("bags", updatedBags)
  end

  -- Update cached views with current items when live or on login
  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:MarkBagsPending("bags", updatedBags)
    end
  end
end

function BaganatorSingleViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()
  Baganator.Utilities.ApplyVisuals(self)

  local characterData = Syndicator.API.GetCharacter(character)

  if not characterData then
    self:SetTitle("")
    return
  else
    self:SetTitle(BAGANATOR_L_XS_BAGS:format(characterData.details.character))
  end

  self:SetupTabs()
  self:SelectTab(character)
  self:AllocateBags(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  self.isLive = isLive

  self.BagSlots:Update(self.lastCharacter, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bags))

  if oldLast ~= character then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton() and isLive)
  self:UpdateTransferButton()

  self.BagLive:SetShown(isLive)
  self.BagCached:SetShown(not isLive)

  local searchText = self.SearchWidget.SearchBox:GetText()

  local activeBag, activeBagCollapsibles = nil, {}

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

  local bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)

  activeBag:ShowCharacter(character, "bags", Syndicator.Constants.AllBagIndexes, self.lastBagDetails.mainIndexesToUse, bagWidth)

  for index, layout in ipairs(activeBagCollapsibles) do
    layout:ShowCharacter(character, "bags", Syndicator.Constants.AllBagIndexes, self.CollapsingBags[index].indexesToUse, bagWidth)
  end

  if self.searchToApply then
    self:ApplySearch(searchText)
  end

  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  local bagHeight = activeBag:GetHeight() + topSpacing / 2

  bagHeight = bagHeight + Baganator.SingleViews.ArrangeCollapsibles(activeBagCollapsibles, activeBag, self.CollapsingBags)

  for _, layouts in ipairs(self.CollapsingBags) do
    layouts.live:SetShown(isLive and layouts.live:IsShown())
    layouts.cached:SetShown(not isLive and layouts.cached:IsShown())
  end

  if self.tabsSetup then -- Not ready immediately on PLAYER_ENTERING_WORLD
    self.Tabs[1]:SetPoint("LEFT", activeBag, "LEFT")
  end

  activeBag:SetPoint("TOPRIGHT", -sideSpacing, -50)

  self.TopButtons[1]:ClearAllPoints()
  self.TopButtons[1]:SetPoint("TOP", self)
  self.TopButtons[1]:SetPoint("LEFT", activeBag, -sideSpacing + 2, 0)

  self:SetSize(
    activeBag:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    bagHeight + 74
  )

  self.SearchWidget:SetSpacing(sideSpacing)
  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.AllFixedButtons)
  tAppendAll(self.AllButtons, self.TopButtons)

  self:HideExtraTabs()

  local lastButton = nil
  for index, layout in ipairs(activeBagCollapsibles) do
    local button = self.CollapsingBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    button:ClearAllPoints()
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

  self:UpdateAllButtons()

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end

  Baganator.CallbackRegistry:TriggerEvent("ViewComplete")

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("-- updateforcharacter backpack", debugprofilestop() - start)
  end
end

function BaganatorSingleViewBackpackViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorSingleViewBackpackViewMixin:UpdateTransferButton()
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

function BaganatorSingleViewBackpackViewMixin:UpdateAllButtons()
  self.ButtonVisibility:Update()
  local guildName = Syndicator.API.GetCharacter(self.lastCharacter).details.guild
  self.ToggleGuildBankButton:SetEnabled(guildName ~= nil and Syndicator.API.GetGuild(guildName))
end

function BaganatorSingleViewBackpackViewMixin:GetMatches()
  local matches = {}
  tAppendAll(matches, self.BagLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorSingleViewBackpackViewMixin:RunAction(action)
  action(self:GetMatches(), self.liveCharacter, function(status, modes)
    self.transferManager:Apply(status, modes or {"BagCacheUpdate"}, function()
      self:RunAction(action)
    end, function()
    end)
  end)
end

function BaganatorSingleViewBackpackViewMixin:Transfer(force)
  for _, transferDetails in ipairs(addonTable.BagTransfers) do
    if transferDetails.condition() then
      if not force and transferDetails.confirmOnAll and self.SearchWidget.SearchBox:GetText() == "" then
        StaticPopup_Show(self.confirmTransferAllDialogName)
        break
      else
        self:RunAction(transferDetails.action)
        break
      end
    end
  end
end

function BaganatorSingleViewBackpackViewMixin:DoSort(isReverse)
  local bagsToSort = {}
  for index, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    bagsToSort[index] = true
  end
  local bagChecks = Baganator.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBagIndexes)
  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self.liveCharacter).bags,
      Syndicator.Constants.AllBagIndexes,
      bagsToSort,
      bagChecks,
      isReverse,
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end
  DoSortInternal()
end

function BaganatorSingleViewBackpackViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if addonTable.ExternalContainerSorts[sortMethod] then
    addonTable.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Backpack)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end
