local _, addonTable = ...

BaganatorSingleViewBankViewCharacterViewMixin = {}

function BaganatorSingleViewBankViewCharacterViewMixin:OnLoad()
  self.unallocatedItemButtonPool = Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  self.CollapsingBagSectionsPool = Baganator.SingleViews.GetCollapsingBagSectionsPool(self)
  self.CollapsingBankBags = {}
  self.bagDetailsForComparison = {}

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self:NotifyBagUpdate(updatedBags)
    if character == self.liveCharacter and self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self.tabsSetup = false
    if self.lastCharacter == character then
      self.lastCharacter = self.liveCharacter
    end
    self:GetParent():UpdateView()
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
      return
    end
    if tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    elseif settingName == Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS then
      self.BagSlots:Update(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if self:IsVisible() and character ~= self.lastCharacter then
      self.lastCharacter = character
      self:GetParent():UpdateView()
    end
  end)

  self.BagSlots:SetPoint("BOTTOMLEFT", self, "TOPLEFT", Baganator.Constants.ButtonFrameOffset, 0)
end

function BaganatorSingleViewBankViewCharacterViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
end

function BaganatorSingleViewBankViewCharacterViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
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

function BaganatorSingleViewBankViewCharacterViewMixin:AllocateBankBags(character)
  -- Copied from SingleViews/BagView.lua
  local newDetails = Baganator.SingleViews.GetCollapsingBagDetails(character, "bank", Syndicator.Constants.AllBankIndexes, Syndicator.Constants.BankBagSlotsCount)
  if self.bagDetailsForComparison.bank == nil or not tCompare(self.bagDetailsForComparison.bank, newDetails, 15) then
    self.bagDetailsForComparison.bank = CopyTable(newDetails)
    self.CollapsingBankBags = Baganator.SingleViews.AllocateCollapsingSections(
      character, "bank", Syndicator.Constants.AllBankIndexes,
      newDetails, self.CollapsingBankBags,
      self.CollapsingBagSectionsPool, self.unallocatedItemButtonPool,
      function() self:UpdateForCharacter(self.lastCharacter, self.isLive) end)
    self.lastBankBagDetails = newDetails
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorSingleViewBankViewCharacterViewMixin:DoSort(isReverse)
  local indexesToUse = {}
  for index in ipairs(Syndicator.Constants.AllBankIndexes) do
    indexesToUse[index] = true
  end
  -- Ignore reagent bank if it isn't purchased
  if Baganator.Constants.IsRetail and not IsReagentBankUnlocked() then
    indexesToUse[tIndexOf(Syndicator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)] = nil
  end
  local bagChecks = Baganator.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBankIndexes)

  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self.liveCharacter).bank,
      Syndicator.Constants.AllBankIndexes,
      indexesToUse,
      bagChecks,
      isReverse,
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end

  DoSortInternal()
end

function BaganatorSingleViewBankViewCharacterViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bank, Syndicator.Constants.AllBankIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorSingleViewBankViewCharacterViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if addonTable.ExternalContainerSorts[sortMethod] then
    addonTable.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Bank)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:RemoveSearchMatches(callback)
  local matches = {}
  tAppendAll(matches, self.BankLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBankBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end

  local emptyBagSlots = Baganator.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes)

  local status = Baganator.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, emptyBagSlots)

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches(callback)
  end, function()
    callback()
  end)
end

function BaganatorSingleViewBankViewCharacterViewMixin:NotifyBagUpdate(updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)

  for _, bagGroup in ipairs(self.CollapsingBankBags) do
    bagGroup.live:MarkBagsPending("bank", updatedBags)
  end

  -- Update cached views with current items when bank closed or on login
  if self.isLive == nil or self.isLive == true then
    for _, bagGroup in ipairs(self.CollapsingBankBags) do
      bagGroup.cached:MarkBagsPending("bank", updatedBags)
    end
    self.BankCached:MarkBagsPending("bank", updatedBags)
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:ResetToLive()
  self.lastCharacter = self.liveCharacter
end

function BaganatorSingleViewBankViewCharacterViewMixin:SetupBlizzardFramesForTab()
  if self.isLive and Syndicator.Constants.WarbandBankActive then
    BankFrame.activeTabIndex = Baganator.Constants.BlizzardBankTabConstants.Character
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:UpdateView()
  self:UpdateForCharacter(self.lastCharacter, self:GetParent().liveBankActive and self.lastCharacter == self.liveCharacter)
end

function BaganatorSingleViewBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
  local characterData = Syndicator.API.GetCharacter(character)
  if not characterData then
    self:GetParent():SetTitle("")
    return
  else
    self:GetParent():SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end

  self:AllocateBankBags(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  if oldLast ~= self.lastCharacter then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end
  self.isLive = isLive

  self.BagSlots:Update(character, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bank))

  self.BankLive:SetShown(self.isLive)
  self.BankCached:SetShown(not self.isLive)

  for _, layouts in ipairs(self.CollapsingBankBags) do
    layouts.live:SetShown(self.isLive)
    layouts.cached:SetShown(not self.isLive)
  end

  local activeBank, activeBankBagCollapsibles = nil, {}

  if self.BankLive:IsShown() then
    activeBank = self.BankLive
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankBagCollapsibles, layouts.live)
    end
  else
    activeBank = self.BankCached
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankBagCollapsibles, layouts.cached)
    end
  end

  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

  activeBank:ShowCharacter(character, "bank", Syndicator.Constants.AllBankIndexes, self.lastBankBagDetails.mainIndexesToUse, bankWidth)

  for index, layout in ipairs(activeBankBagCollapsibles) do
    layout:ShowCharacter(character, "bank", Syndicator.Constants.AllBankIndexes, self.CollapsingBankBags[index].indexesToUse, bankWidth)
  end

  self.BankMissingHint:SetShown(#activeBank.buttons == 0)
  self:GetParent().SearchWidget:SetShown(#activeBank.buttons ~= 0)

  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  local searchText = self:GetParent().SearchWidget.SearchBox:GetText()

  self:ApplySearch(searchText)

  self.DepositIntoReagentsBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and IsReagentBankUnlocked())
  self.BuyReagentBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and not IsReagentBankUnlocked())

  -- Copied from SingleViews/BagView.lua
  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  local bankHeight = activeBank:GetHeight() + topSpacing / 2

  -- Copied from SingleViews/BagView.lua
  bankHeight = bankHeight + Baganator.SingleViews.ArrangeCollapsibles(activeBankBagCollapsibles, activeBank, self.CollapsingBankBags)

  self:GetParent().AllButtons = {}
  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.TopButtons)

  local lastButton = nil
  for index, layout in ipairs(activeBankBagCollapsibles) do
    local button = self.CollapsingBankBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    if button:IsShown() then
      button:ClearAllPoints()
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBank, -2, 0)
      end
      table.insert(self:GetParent().AllButtons, button)
      lastButton = button
    end
  end

  if self.BuyReagentBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.BuyReagentBankButton)
    self.BuyReagentBankButton:ClearAllPoints()
    if lastButton then
      self.BuyReagentBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
    else
      self.BuyReagentBankButton:SetPoint("LEFT", activeBank, -2, 0)
      self.BuyReagentBankButton:SetPoint("BOTTOM", 0, 6)
    end
  end
  if self.DepositIntoReagentsBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.DepositIntoReagentsBankButton)
    self.DepositIntoReagentsBankButton:ClearAllPoints()
    self.DepositIntoReagentsBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
  end

  bankHeight = bankHeight + 20

  activeBank:ClearAllPoints()
  activeBank:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset - 2, -50)

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end

  self:SetupBlizzardFramesForTab()

  Baganator.CallbackRegistry:TriggerEvent("ViewComplete")

  self:SetSize(
    activeBank:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    bankHeight + 54
  )
end
