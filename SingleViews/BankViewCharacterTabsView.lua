---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorSingleViewBankViewCharacterTabsViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewCharacterTabsViewMixin)

function BaganatorSingleViewBankViewCharacterTabsViewMixin:GetSearchMatches()
  if self.Container.BankTabLive:IsShown() then
    return self.Container.BankTabLive.SearchMonitor:GetMatches()
  else
    return self.Container.BankUnifiedLive.SearchMonitor:GetMatches()
  end
end

function BaganatorSingleViewBankViewCharacterTabsViewMixin:NotifyBagUpdate(updatedBags)
  self.Container.BankTabLive:MarkTabsPending("bank", updatedBags)
  self.Container.BankUnifiedLive:MarkBagsPending("bank", updatedBags)
end

function BaganatorSingleViewBankViewCharacterTabsViewMixin:ShowTab(character, tabIndex, isLive)
  BaganatorItemViewCommonBankViewCharacterTabsViewMixin.ShowTab(self, character, tabIndex, isLive)

  if self.BankMissingHint:IsShown() then
    return
  end

  self.Container.BankTabLive:SetShown(self.isLive and self.currentTab > 0)
  self.Container.BankTabCached:SetShown(not self.isLive and self.currentTab > 0)

  self.Container.BankUnifiedLive:SetShown(self.isLive and self.currentTab == 0)
  self.Container.BankUnifiedCached:SetShown(not self.isLive and self.currentTab == 0)

  local bankWidth = addonTable.Config.Get(addonTable.Config.Options.CHARACTER_BANK_VIEW_WIDTH)

  local refresh = self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] or self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] or self.refreshState[addonTable.Constants.RefreshReason.Flow] or self.refreshState[addonTable.Constants.RefreshReason.Layout]

  local activeBank

  if self.currentTab > 0 then
    if self.Container.BankTabLive:IsShown() then
      activeBank = self.Container.BankTabLive
    else
      activeBank = self.Container.BankTabCached
    end

    if refresh then
      activeBank:ShowTab(Syndicator.API.GetCharacter(character).bankTabs, self.currentTab, Syndicator.Constants.AllBankIndexes, bankWidth)
    end
  else
    if self.Container.BankUnifiedLive:IsShown() then
      activeBank = self.Container.BankUnifiedLive
    else
      activeBank = self.Container.BankUnifiedCached
    end

    if refresh then
      local characterData = Syndicator.API.GetCharacter(self.lastCharacter)
      local bagData = {}
      for _, tab in ipairs(characterData.bankTabs) do
        table.insert(bagData, tab.slots)
      end

      activeBank:ShowBags(bagData, self.lastCharacter, Syndicator.Constants.AllBankIndexes, nil, bankWidth * 2)
    end
  end

  self.searchToApply = self.searchToApply or refresh
  if self.searchToApply then
    local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
    self:ApplySearch(searchText)
  end

  if self.refreshState[addonTable.Constants.RefreshReason.Layout] then
    local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

    self.bankHeight = activeBank:GetHeight()

    activeBank:ClearAllPoints()
    activeBank:SetPoint("TOPLEFT", 0, 0)

    self.Container:SetSize(math.max(activeBank:GetWidth(), self:GetButtonsWidth(sideSpacing)), self.bankHeight)
  end

  addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

  self:OnFinished()

  if self.refreshState[addonTable.Constants.RefreshReason.Layout] then
    self.CurrencyWidget:UpdateCurrencyTextPositions(self.Container:GetWidth() - self.buttonsWidth - 5, self.Container:GetWidth())
  end

  self:GetParent():OnTabFinished()
end
