local _, addonTable = ...
BaganatorSingleViewBankViewCharacterViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewCharacterViewMixin)

function BaganatorSingleViewBankViewCharacterViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewCharacterViewMixin.OnLoad(self)

  self.unallocatedItemButtonPool = addonTable.ItemViewCommon.GetLiveItemButtonPool(self.Container)
  self.CollapsingBagSectionsPool = addonTable.SingleViews.GetCollapsingBagSectionsPool(self.Container)
  self.CollapsingBankBags = {}
  self.bagDetailsForComparison = {}

  addonTable.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)
end

function BaganatorSingleViewBankViewCharacterViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end

  if self.Container.BankLive:IsShown() then
    self.Container.BankLive:ApplySearch(text)
    for _, layouts in ipairs(self.CollapsingBankBags) do
      layouts.live:ApplySearch(text)
    end
  elseif self.Container.BankCached:IsShown() then
    self.Container.BankCached:ApplySearch(text)
    for _, layouts in ipairs(self.CollapsingBankBags) do
      layouts.cached:ApplySearch(text)
    end
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:AllocateBankBags(character)
  -- Copied from SingleViews/BagView.lua
  local newDetails = addonTable.SingleViews.GetCollapsingBagDetails(character, "bank", Syndicator.Constants.AllBankIndexes, Syndicator.Constants.BankBagSlotsCount)
  if self.bagDetailsForComparison.bank == nil or not tCompare(self.bagDetailsForComparison.bank, newDetails, 15) then
    self.bagDetailsForComparison.bank = CopyTable(newDetails)
    self.CollapsingBankBags = addonTable.SingleViews.AllocateCollapsingSections(
      character, "bank", Syndicator.Constants.AllBankIndexes,
      newDetails, self.CollapsingBankBags,
      self.CollapsingBagSectionsPool, self.unallocatedItemButtonPool,
      function() self:UpdateForCharacter(self.lastCharacter, self.isLive) end)
    self.lastBankBagDetails = newDetails
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:GetSearchMatches()
  local matches = {}
  tAppendAll(matches, self.Container.BankLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBankBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorSingleViewBankViewCharacterViewMixin:NotifyBagUpdate(updatedBags)
  self.Container.BankLive:MarkBagsPending("bank", updatedBags)

  for _, bagGroup in ipairs(self.CollapsingBankBags) do
    bagGroup.live:MarkBagsPending("bank", updatedBags)
  end

  -- Update cached views with current items when bank closed or on login
  if self.isLive == nil or self.isLive == true then
    for _, bagGroup in ipairs(self.CollapsingBankBags) do
      bagGroup.cached:MarkBagsPending("bank", updatedBags)
    end
    self.Container.BankCached:MarkBagsPending("bank", updatedBags)
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
  BaganatorItemViewCommonBankViewCharacterViewMixin.UpdateForCharacter(self, character, isLive)
  if self.lastCharacter ~= character then
    return
  end

  self:GetParent().AllButtons = {}
  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.TopButtons)

  if self.BankMissingHint:IsShown() then
    for _, details in ipairs(self.CollapsingBankBags) do
      details.button:Hide()
    end
    return
  end

  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] then
    self:AllocateBankBags(character)
  end

  self.Container.BankLive:SetShown(self.isLive)
  self.Container.BankCached:SetShown(not self.isLive)

  for _, layouts in ipairs(self.CollapsingBankBags) do
    layouts.live:SetShown(self.isLive)
    layouts.cached:SetShown(not self.isLive)
  end

  local activeBank, activeBankBagCollapsibles = nil, {}

  if self.Container.BankLive:IsShown() then
    activeBank = self.Container.BankLive
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankBagCollapsibles, layouts.live)
    end
  else
    activeBank = self.Container.BankCached
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankBagCollapsibles, layouts.cached)
    end
  end

  local bankWidth = addonTable.Config.Get(addonTable.Config.Options.BANK_VIEW_WIDTH)

  if self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] or self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] or self.refreshState[addonTable.Constants.RefreshReason.Flow] then
    local characterData = Syndicator.API.GetCharacter(character) 
    local bagData = characterData and characterData.bank

    activeBank:ShowBags(bagData, character, Syndicator.Constants.AllBankIndexes, self.lastBankBagDetails.mainIndexesToUse, bankWidth)

    for index, layout in ipairs(activeBankBagCollapsibles) do
      layout:ShowBags(bagData, character, Syndicator.Constants.AllBankIndexes, self.CollapsingBankBags[index].indexesToUse, bankWidth)
    end
  end

  if self.searchToApply then
    local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
    self:ApplySearch(searchText)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.Layout] then
    local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

    self.bankHeight = activeBank:GetHeight()

    -- Copied from SingleViews/BagView.lua
    self.bankHeight = self.bankHeight + addonTable.SingleViews.ArrangeCollapsibles(activeBankBagCollapsibles, activeBank, self.CollapsingBankBags)

    self.buttonsWidth = 0
    local lastButton = nil
    for index, layout in ipairs(activeBankBagCollapsibles) do
      local button = self.CollapsingBankBags[index].button
      button:SetParent(self)
      button:SetShown(layout:GetHeight() > 0)
      if button:IsShown() then
        self.buttonsWidth = button:GetWidth() + 5
        button:ClearAllPoints()
        if lastButton then
          button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
        else
          button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
          button:SetPoint("LEFT", self.Container, -2, 0)
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
      self.buttonsWidth = self.buttonsWidth + self.BuyReagentBankButton:GetWidth()
    end
    if self.DepositIntoReagentsBankButton:IsShown() then
      table.insert(self:GetParent().AllButtons, self.DepositIntoReagentsBankButton)
      self.DepositIntoReagentsBankButton:ClearAllPoints()
      self.DepositIntoReagentsBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
      self.buttonsWidth = self.buttonsWidth + self.DepositIntoReagentsBankButton:GetWidth()
    end

    activeBank:ClearAllPoints()
    activeBank:SetPoint("TOPLEFT", 0, 0)
  end

  addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

  self.Container:SetSize(activeBank:GetWidth(), self.bankHeight)

  self:OnFinished()

  if self.refreshState[addonTable.Constants.RefreshReason.Layout] then
    self.CurrencyWidget:UpdateCurrencyTextPositions(self.Container:GetWidth() - self.buttonsWidth - 5, self.Container:GetWidth())
  end

  self:GetParent():OnTabFinished()

  self.refreshState = {}
end
