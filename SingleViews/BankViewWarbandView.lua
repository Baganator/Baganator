local _, addonTable = ...
BaganatorSingleViewBankViewWarbandViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewWarbandViewMixin)

function BaganatorSingleViewBankViewWarbandViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewWarbandViewMixin.OnLoad(self)

  addonTable.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Container.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)
end

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

  local activeBank

  if self.currentTab > 0 then
    if self.Container.BankTabLive:IsShown() then
      activeBank = self.Container.BankTabLive
    else
      activeBank = self.Container.BankTabCached
    end

    activeBank:ShowTab(self.currentTab, Syndicator.Constants.AllWarbandIndexes, bankWidth)
  else
    if self.Container.BankUnifiedLive:IsShown() then
      activeBank = self.Container.BankUnifiedLive
    else
      activeBank = self.Container.BankUnifiedCached
    end

    local warbandData = Syndicator.API.GetWarband(1)
    local bagData = {}
    for _, tab in ipairs(warbandData.bank) do
      table.insert(bagData, tab.slots)
    end

    activeBank:ShowBags(bagData, 1, Syndicator.Constants.AllWarbandIndexes, nil, bankWidth * 2)
  end

  local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
  self:ApplySearch(searchText)

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  local bankHeight = activeBank:GetHeight()

  activeBank:ClearAllPoints()
  activeBank:SetPoint("TOPLEFT", 0, 0)

  addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

  self.Container:SetSize(math.max(activeBank:GetWidth(), self:GetButtonsWidth(sideSpacing)), bankHeight)

  self:OnFinished()

  self:GetParent():OnTabFinished()
end

function BaganatorSingleViewBankViewWarbandViewMixin:ApplySearch(text)
  for _, layout in ipairs(self.Container.Layouts) do
    if layout:IsShown() then
      layout:ApplySearch(text)
    end
  end
end
