local _, addonTable = ...

BaganatorItemViewCommonBankViewCharacterViewMixin = {}

function BaganatorItemViewCommonBankViewCharacterViewMixin:OnLoad()
  addonTable.Utilities.AddBagSortManager(self) -- self.sortManager
  addonTable.Utilities.AddBagTransferManager(self) -- self.transferManager

  addonTable.Utilities.AddScrollBar(self)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    if self:IsVisible() then
      self:ApplySearch(text)
    end
  end)

  self.refreshState = {}
  for _, value in pairs(addonTable.Constants.RefreshReason) do
    self.refreshState[value] = true
  end

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self:NotifyBagUpdate(updatedBags)
    if next(updatedBags.bank) then
      self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    end
    if updatedBags.containerBags.bank then
      self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
    end
    if character == self.liveCharacter and self:IsVisible() and next(self.refreshState) ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange",  function(_, refreshState)
    self.refreshState = Mixin(self.refreshState, refreshState)

    for _, layout in ipairs(self.Container.Layouts) do
      layout:UpdateRefreshState(refreshState)
    end

    if self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self.tabsSetup = false
    if self.lastCharacter == character then
      self.lastCharacter = self.liveCharacter
    end
    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
      return
    end
    if settingName == addonTable.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS and self:IsVisible() then
      self.BagSlots:Update(self.lastCharacter, self.isLive)
      self:OnFinished()
      self:GetParent():OnTabFinished()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if character ~= self.lastCharacter then
      self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      if self:IsVisible() then
        self.lastCharacter = character
        self:GetParent():UpdateView()
      else
        self.lastCharacter = character
      end
    end
  end)

  addonTable.Skins.AddFrame("Button", self.DepositIntoReagentsBankButton)
  addonTable.Skins.AddFrame("Button", self.BuyReagentBankButton)

  self:SetLiveCharacter(Syndicator.API.GetCurrentCharacter())
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:ToggleBagSlots()
  addonTable.Config.Set(addonTable.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not addonTable.Config.Get(addonTable.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:DoSort(isReverse)
  local indexesToUse = {}
  for index in ipairs(Syndicator.Constants.AllBankIndexes) do
    indexesToUse[index] = true
  end
  -- Ignore reagent bank if it isn't purchased
  if addonTable.Constants.IsRetail and not IsReagentBankUnlocked() then
    indexesToUse[tIndexOf(Syndicator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)] = nil
  end
  local bagChecks = addonTable.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBankIndexes)

  local function DoSortInternal()
    local status = addonTable.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self.liveCharacter).bank,
      Syndicator.Constants.AllBankIndexes,
      indexesToUse,
      bagChecks,
      isReverse,
      addonTable.Config.Get(addonTable.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      addonTable.Config.Get(addonTable.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end

  DoSortInternal()
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:CombineStacks(callback)
  addonTable.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bank, Syndicator.Constants.AllBankIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)

  if not addonTable.Sorting.IsModeAvailable(sortMethod) then
    addonTable.Config.ResetOne(addonTable.Config.Options.SORT_METHOD)
    sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)
  end

  if addonTable.API.ExternalContainerSorts[sortMethod] then
    addonTable.API.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Bank)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:RemoveSearchMatches(getItems)
  local matches = (getItems and getItems()) or self:GetSearchMatches()

  local emptyBagSlots = addonTable.Transfers.GetBagsSlots(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes)

  local status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, emptyBagSlots)

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches(getItems)
  end, function() end)
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:ResetToLive()
  self.lastCharacter = self.liveCharacter
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:SetupBlizzardFramesForTab()
  if self.isLive and Syndicator.Constants.WarbandBankActive then
    BankFrame.activeTabIndex = addonTable.Constants.BlizzardBankTabConstants.Character
    BankFrame.selectedTab = 1
  end
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:UpdateView()
  self:UpdateForCharacter(self.lastCharacter, self:GetParent().liveBankActive and self.lastCharacter == self.liveCharacter and (not Syndicator.Constants.WarbandBankActive or not C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.AccountBanker)))
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
  local characterData = Syndicator.API.GetCharacter(character)
  if not characterData then
    self:GetParent():SetTitle("")
    return
  else
    self:GetParent():SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end

  self.searchToApply = self.searchToApply or self.refreshState[addonTable.Constants.RefreshReason.Searches] or self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets]

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  if oldLast ~= self.lastCharacter then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
    self.refreshState[addonTable.Constants.RefreshReason.Character] = true
    addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", character)
    return
  end

  if self.isLive ~= isLive then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
  end

  self.isLive = isLive

  addonTable.Utilities.AddGeneralDropSlot(self, function()
    return Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bank
  end, Syndicator.Constants.AllBankIndexes)

  self.BagSlots:Update(character, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bank))

  self.BankMissingHint:SetShown(characterData.bank[1] == nil or #characterData.bank[1] == 0)
  self:GetParent().SearchWidget:SetShown(addonTable.Config.Get(addonTable.Config.Options.SHOW_SEARCH_BOX) and characterData.bank[1] and #characterData.bank[1] ~= 0)

  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  local searchText = self:GetParent().SearchWidget.SearchBox:GetText()

  self.DepositIntoReagentsBankButton:SetShown(self.isLive and addonTable.Constants.IsRetail and IsReagentBankUnlocked())
  self.BuyReagentBankButton:SetShown(self.isLive and addonTable.Constants.IsRetail and not IsReagentBankUnlocked())

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end

  self.BagSlots:SetPoint("BOTTOMLEFT", self, "TOPLEFT", addonTable.Constants.ButtonFrameOffset, 0)

  self:SetupBlizzardFramesForTab()

  if self.BankMissingHint:IsShown() then
    local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()
    self:SetSize(
      math.max(400, self.BankMissingHint:GetWidth()) + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset + 40,
      80 + topSpacing / 2
    )

    for _, layout in ipairs(self.Container.Layouts) do
      layout:Hide()
    end

    self.CurrencyWidget:UpdateCurrencyTextPositions(self.BankMissingHint:GetWidth())

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:OnFinished(character, isLive)
  if self.BankMissingHint:IsShown() then
    return
  end

  if self.refreshState[addonTable.Constants.RefreshReason.Layout] then
    local sideSpacing, topSpacing, searchSpacing = addonTable.Utilities.GetSpacing()

    local buttonPadding = 5
    local additionalPadding = 0
    if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
      buttonPadding = 3
    end

    self:SetSize(10, 10)
    local externalVerticalSpacing = (self.BagSlots:GetHeight() > 0 and (self.BagSlots:GetTop() - self:GetTop()) or 0) + (self:GetParent().Tabs[1] and self:GetParent().Tabs[1]:IsShown() and (self:GetParent():GetBottom() - self:GetParent().Tabs[1]:GetBottom() + 5) or 0)

    self:SetSize(
      self.Container:GetWidth() + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2,
      math.min(self.Container:GetHeight() + 50 + searchSpacing + buttonPadding + self.CurrencyWidget:GetExtraHeight(), UIParent:GetHeight() / self:GetParent():GetScale() - externalVerticalSpacing)
    )

    self:UpdateScroll(73 + buttonPadding + externalVerticalSpacing, self:GetParent():GetScale())
  end
end
