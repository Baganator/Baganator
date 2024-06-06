local _, addonTable = ...

BaganatorItemViewCommonBankViewCharacterViewMixin = {}

function BaganatorItemViewCommonBankViewCharacterViewMixin:OnLoad()
  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    if self:IsVisible() then
      self:ApplySearch(text)
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self.searchToApply = true
    self:NotifyBagUpdate(updatedBags)
    if character == self.liveCharacter and self:IsVisible() then
      self:GetParent():UpdateView()
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

  Baganator.Skins.AddFrame("Button", self.DepositIntoReagentsBankButton)
  Baganator.Skins.AddFrame("Button", self.BuyReagentBankButton)

  self.BagSlots:SetPoint("BOTTOMLEFT", self, "TOPLEFT", Baganator.Constants.ButtonFrameOffset, 0)
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
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

function BaganatorItemViewCommonBankViewCharacterViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bank, Syndicator.Constants.AllBankIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:CombineStacksAndSort(isReverse)
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

function BaganatorItemViewCommonBankViewCharacterViewMixin:RemoveSearchMatches(getItems)
  local matches = (getItems and getItems()) or self:GetSearchMatches()

  local emptyBagSlots = Baganator.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes)

  local status = Baganator.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, emptyBagSlots)

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches(getItems)
  end, function() end)
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:ResetToLive()
  self.lastCharacter = self.liveCharacter
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:SetupBlizzardFramesForTab()
  if self.isLive and Syndicator.Constants.WarbandBankActive then
    BankFrame.activeTabIndex = Baganator.Constants.BlizzardBankTabConstants.Character
  end
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:UpdateView()
  self:UpdateForCharacter(self.lastCharacter, self:GetParent().liveBankActive and self.lastCharacter == self.liveCharacter)
end

function BaganatorItemViewCommonBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
  local characterData = Syndicator.API.GetCharacter(character)
  if not characterData then
    self:GetParent():SetTitle("")
    return
  else
    self:GetParent():SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  if oldLast ~= self.lastCharacter then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end
  self.isLive = isLive

  self.BagSlots:Update(character, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bank))

  self.BankMissingHint:SetShown(characterData.bank[1] == nil or #characterData.bank[1] == 0)
  self:GetParent().SearchWidget:SetShown(characterData.bank[1] and #characterData.bank[1] ~= 0)

  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  local searchText = self:GetParent().SearchWidget.SearchBox:GetText()

  self.DepositIntoReagentsBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and IsReagentBankUnlocked())
  self.BuyReagentBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and not IsReagentBankUnlocked())

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end

  self:SetupBlizzardFramesForTab()
end
