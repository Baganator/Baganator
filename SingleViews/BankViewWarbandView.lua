---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorSingleViewBankViewWarbandViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewWarbandViewMixin)

function BaganatorSingleViewBankViewWarbandViewMixin:GetSearchMatches()
  if self.Container.BankTabLive:IsShown() then
    return self.Container.BankTabLive.SearchMonitor:GetMatches()
  else
    return self.Container.BankUnifiedLive.SearchMonitor:GetMatches()
  end
end

function BaganatorSingleViewBankViewWarbandViewMixin:NotifyBagUpdate(updatedBags)
  self.Container.BankTabLive:MarkTabsPending(updatedBags)
  self.Container.BankUnifiedLive:MarkBagsPending("bags", updatedBags)
end

function BaganatorSingleViewBankViewWarbandViewMixin:ShowTab(tabIndex, isLive)
  BaganatorItemViewCommonBankViewWarbandViewMixin.ShowTab(self, tabIndex, isLive)

  if self.BankMissingHint:IsShown() then
    return
  end

  self.Container.BankTabLive:SetShown(self.isLive and self.currentTab > 0)
  self.Container.BankTabCached:SetShown(not self.isLive and self.currentTab > 0)

  self.Container.BankUnifiedLive:SetShown(self.isLive and self.currentTab == 0)
  self.Container.BankUnifiedCached:SetShown(not self.isLive and self.currentTab == 0)

  local bankWidth = addonTable.Config.Get(addonTable.Config.Options.WARBAND_BANK_VIEW_WIDTH)

  local refresh = self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets] or self.refreshState[addonTable.Constants.RefreshReason.ItemTextures] or self.refreshState[addonTable.Constants.RefreshReason.Flow] or self.refreshState[addonTable.Constants.RefreshReason.Layout]

  local activeBank

  if self.currentTab > 0 then
    if self.Container.BankTabLive:IsShown() then
      activeBank = self.Container.BankTabLive
    else
      activeBank = self.Container.BankTabCached
    end

    if refresh then
      activeBank:ShowTab(self.currentTab, Syndicator.Constants.AllWarbandIndexes, bankWidth)
    end
  else
    if self.Container.BankUnifiedLive:IsShown() then
      activeBank = self.Container.BankUnifiedLive
    else
      activeBank = self.Container.BankUnifiedCached
    end

    if refresh then
      local warbandData = Syndicator.API.GetWarband(1)
      local bagData = {}
      for _, tab in ipairs(warbandData.bank) do
        table.insert(bagData, tab.slots)
      end

      activeBank:ShowBags(bagData, 1, Syndicator.Constants.AllWarbandIndexes, nil, bankWidth * 2)
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

  self:GetParent():OnTabFinished()
end
