local _, addonTable = ...

BaganatorItemViewCommonBankViewWarbandViewMixin = {}

function BaganatorItemViewCommonBankViewWarbandViewMixin:OnLoad()
  self.tabsPool = Baganator.ItemViewCommon.GetSideTabButtonPool(self)
  self.currentTab = 1
  self.updateTabs = true

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Syndicator.CallbackRegistry:RegisterCallback("WarbandBankCacheUpdate",  function(_, index, updates)
    self:NotifyBagUpdate(updates)
    self.searchToApply = true
    if updates.tabInfo then
      self.updateTabs = true
    end
    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("WarbandCurrencyCacheUpdate",  function(_, warbandIndex)
    if self:IsVisible() then
      self:UpdateCurrencies()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    end
  end)

  Baganator.Skins.AddFrame("Button", self.DepositItemsButton)
  Baganator.Skins.AddFrame("Button", self.WithdrawMoneyButton)
  Baganator.Skins.AddFrame("Button", self.DepositMoneyButton)
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:DoSort(isReverse)
  local bagID = Syndicator.Constants.AllWarbandIndexes[self.currentTab]
  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyBagOrdering(
      { Syndicator.API.GetWarband(1).bank[self.currentTab].slots },
      { bagID },
      { [1] = true },
      { checks = {}, sortOrder = { [bagID] = 250 }, },
      isReverse,
      false,
      0
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end

  DoSortInternal()
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(
    { Syndicator.API.GetWarband(1).bank[self.currentTab].slots },
    { Syndicator.Constants.AllWarbandIndexes[self.currentTab] },
    function(status)
      self.sortManager:Apply(status, function()
        self:CombineStacks(callback)
      end, function()
        callback()
      end)
    end
  )
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if addonTable.ExternalContainerSorts[sortMethod] then
    addonTable.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.WarbandBank)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:RemoveSearchMatches(items)
  local matches = items or self:GetSearchMatches()

  local emptyBagSlots = Baganator.Transfers.GetEmptyBagsSlots(
    Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bags,
    Syndicator.Constants.AllBagIndexes
  )

  local status = Baganator.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, emptyBagSlots)

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches()
  end, function() end)
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:ResetToLive()
  self.lastCharacter = self.liveCharacter
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:SetupBlizzardFramesForTab()
  if self.isLive then

    BankFrame.activeTabIndex = Baganator.Constants.BlizzardBankTabConstants.Warband

    local tabInfo = Syndicator.API.GetWarband(1).bank[self.currentTab]
    local bagID = Syndicator.Constants.AllWarbandIndexes[self.currentTab]

    -- Ensure right-clicking a bag item puts the item into this tab
    AccountBankPanel.selectedTabID = bagID

    -- Workaround so that the tab edit UI shows the details for the current tab
    self.TabSettingsMenu.GetBankFrame = function()
      return {
        GetTabData = function(tabID)
          return {
            ID = bagID,
            icon = tabInfo.iconTexture,
            name = tabInfo.name,
            depositFlags = tabInfo.depositFlags,
            bankType = Enum.BankType.Account,
          }
        end
      }
    end

    if self.TabSettingsMenu:IsShown() then
      self.TabSettingsMenu:OnNewBankTabSelected(bagID)
    end
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:UpdateCurrencies()
  local warbandData = Syndicator.API.GetWarband(1)
  self.Money:SetText(Baganator.Utilities.GetMoneyString(warbandData.money, true))

  if self.isLive then
    self.DepositMoneyButton:SetEnabled(C_Bank.CanDepositMoney(Enum.BankType.Account))
    self.WithdrawMoneyButton:SetEnabled(C_Bank.CanWithdrawMoney(Enum.BankType.Account))
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:UpdateTabs()
  if not self.updateTabs and (not self.purchaseTabAdded or self.isLive) then
    return
  end

  self.updateTabs = false

  local tabScaleFactor = 37
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    tabScaleFactor = 40
  end
  local tabScale = math.min(1, Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE) / tabScaleFactor)

  self.tabsPool:ReleaseAll()

  local warbandData = Syndicator.API.GetWarband(1)

  local lastTab = nil
  local tabs = {}

  for index, tabInfo in ipairs(warbandData.bank) do
    local tabButton = self.tabsPool:Acquire()
    tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tabButton.Icon:SetTexture(tabInfo.iconTexture)
    tabButton:SetScript("OnClick", function(_, button)
      self:SetCurrentTab(index)
      self:UpdateView()

      if self.isLive and button == "RightButton" then
        self.TabSettingsMenu:OnOpenTabSettingsRequested(Syndicator.Constants.AllWarbandIndexes[index])
      end
    end)
    if not lastTab then
      tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -20)
    else
      tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    end
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton.tabName = tabInfo.name
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end

  if self.isLive and C_Bank.CanPurchaseBankTab(Enum.BankType.Account) and not C_Bank.HasMaxBankTabs(Enum.BankType.Account) then
    local tabButton = self.tabsPool:Acquire()
    tabButton.Icon:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
    tabButton:SetScript("OnClick", function()
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
      StaticPopup_Show("CONFIRM_BUY_BANK_TAB", nil, nil, { bankType = Enum.BankType.Account })
    end)
    if not lastTab then
      tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -20)
    else
      tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    end
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton.tabName = BAGANATOR_L_BUY_WARBAND_BANK_TAB
    tabButton:SetEnabled(true)
    tabButton.Icon:SetDesaturated(false)
    table.insert(tabs, tabButton)
    self.purchaseTabAdded = true
  else
    self.purchaseTabAdded = false
  end

  self.Tabs = tabs
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:SetCurrentTab(index)
  Baganator.CallbackRegistry:TriggerEvent("TransferCancel")
  self.currentTab = index
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:HighlightCurrentTab()
  if not self.Tabs then
    return
  end
  for tabIndex, tab in ipairs(self.Tabs) do
    tab.SelectedTexture:SetShown(tabIndex == self.currentTab)
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:UpdateView()
  self:ShowTab(self.currentTab, self:GetParent().liveBankActive)
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:ShowTab(tabIndex, isLive)
  self.isLive = isLive

  self:GetParent():SetTitle(ACCOUNT_BANK_PANEL_TITLE)

  local warbandBank = Syndicator.API.GetWarband(1).bank[self.currentTab]

  local isWarbandData = warbandBank and #warbandBank.slots ~= 0
  self.BankMissingHint:SetShown(not isWarbandData)
  self:GetParent().SearchWidget:SetShown(isWarbandData)

  if self.BankMissingHint:IsShown() then
    if self.isLive then
      self.BankMissingHint:SetText(BAGANATOR_L_WARBAND_BANK_NOT_PURCHASED_HINT)
    else
      self.BankMissingHint:SetText(BAGANATOR_L_WARBAND_BANK_DATA_MISSING_HINT)
    end
  end

  local searchText = self:GetParent().SearchWidget.SearchBox:GetText()

  for _, button in ipairs(self.LiveButtons) do
    button:SetShown(self.isLive)
  end
  self.DepositItemsButton:SetShown(isWarbandData and self.isLive)
  self.IncludeReagentsCheckbox:SetShown(isWarbandData and self.isLive)

  self:UpdateCurrencies()

  self:GetParent().AllButtons = {}
  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.LiveButtons)

  -- Copied from ItemViewCommons/BagView.lua
  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  if self.isLive then
    self.IncludeReagentsCheckbox:SetPoint("LEFT", self, "LEFT", Baganator.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.DepositItemsButton:SetPoint("LEFT", self, "LEFT", Baganator.Constants.ButtonFrameOffset + sideSpacing - 2, 0)

    self.DepositMoneyButton:SetPoint("RIGHT", self, "RIGHT", -sideSpacing, 0)
  end

  self:UpdateTabs()
  self:SetupBlizzardFramesForTab()
  self:HighlightCurrentTab()
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:DepositMoney()
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);

  StaticPopup_Hide("BANK_MONEY_WITHDRAW");

  local alreadyShown = StaticPopup_Visible("BANK_MONEY_DEPOSIT");
  if alreadyShown then
    StaticPopup_Hide("BANK_MONEY_DEPOSIT");
    return;
  end

  StaticPopup_Show("BANK_MONEY_DEPOSIT", nil, nil, { bankType = Enum.BankType.Account });
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:WithdrawMoney()
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);

  StaticPopup_Hide("BANK_MONEY_DEPOSIT");

  local alreadyShown = StaticPopup_Visible("BANK_MONEY_WITHDRAW");
  if alreadyShown then
    StaticPopup_Hide("BANK_MONEY_WITHDRAW");
    return;
  end

  StaticPopup_Show("BANK_MONEY_WITHDRAW", textArg1, textArg2, { bankType = Enum.BankType.Account });
end
