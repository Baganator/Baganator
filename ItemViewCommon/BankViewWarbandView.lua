local _, addonTable = ...

BaganatorItemViewCommonBankViewWarbandViewMixin = {}

function BaganatorItemViewCommonBankViewWarbandViewMixin:OnLoad()
  self.tabsPool = addonTable.ItemViewCommon.GetSideTabButtonPool(self)
  self.currentTab = addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB)
  self.updateTabs = true

  addonTable.Utilities.AddBagSortManager(self) -- self.sortManager
  addonTable.Utilities.AddBagTransferManager(self) -- self.transferManager

  addonTable.Utilities.AddScrollBar(self)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
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

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(addonTable.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Container.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    end
  end)

  addonTable.Skins.AddFrame("Button", self.DepositItemsButton)
  addonTable.Skins.AddFrame("Button", self.WithdrawMoneyButton)
  addonTable.Skins.AddFrame("Button", self.DepositMoneyButton)

  self.purchaseButton = CreateFrame("Button", nil, self, "BaganatorSecureRightSideTabButtonTemplate")
  self.purchaseButton:SetAttribute("type", "click")
  self.purchaseButton:SetAttribute("clickbutton", AccountBankPanel.PurchasePrompt.TabCostFrame.PurchaseButton)
  self.purchaseButton:HookScript("OnClick", function()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
  end)
  self.purchaseButton:RegisterForClicks("AnyUp", "AnyDown")
end

local function GetUnifiedSortData()
  local bagData = {}
  for _, tab in ipairs(Syndicator.API.GetWarband(1).bank) do
    table.insert(bagData, tab.slots)
  end
  local indexesToUse, sortOrder = {}, {}
  for index, bagID in ipairs(Syndicator.Constants.AllWarbandIndexes) do
    indexesToUse[index] = true
    sortOrder[bagID] = 250
  end

  return bagData, indexesToUse, sortOrder
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:DoSort(isReverse)
  if self.currentTab > 0 then
    local tab = self.currentTab
    local bagID = Syndicator.Constants.AllWarbandIndexes[self.currentTab]
    local function DoSortInternal()
      local status = addonTable.Sorting.ApplyBagOrdering(
        { Syndicator.API.GetWarband(1).bank[tab].slots },
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
  else
    local function DoSortInternal()
      local bagData, indexesToUse, sortOrder = GetUnifiedSortData()
      local status = addonTable.Sorting.ApplyBagOrdering(
        bagData,
        Syndicator.Constants.AllWarbandIndexes,
        indexesToUse,
        { checks = {}, sortOrder = sortOrder, },
        isReverse,
        false,
        0
      )
      self.sortManager:Apply(status, DoSortInternal, function() end)
    end
    DoSortInternal()
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:OnShow()
  self.transferState = {}
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:CombineStacks(callback)
  local bagData = GetUnifiedSortData()
  addonTable.Sorting.CombineStacks(
    bagData,
    Syndicator.Constants.AllWarbandIndexes,
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
  if not Syndicator.API.GetWarband(1).bank[self.currentTab] and self.currentTab ~= 0 then
    return
  end

  local sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)

  if not addonTable.Sorting.IsModeAvailable(sortMethod) then
    addonTable.Config.ResetOne(addonTable.Config.Options.SORT_METHOD)
    sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)
  end

  if addonTable.API.ExternalContainerSorts[sortMethod] then
    addonTable.API.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.WarbandBank)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:RemoveSearchMatches(getItems)
  local matches = (getItems and getItems()) or self:GetSearchMatches()

  -- Limit to the first 5 items (avoids slots locking up)
  local newMatches = {}
  for i = 1, 5 do
    table.insert(newMatches, matches[i])
  end
  matches = newMatches

  local emptyBagSlots = addonTable.Transfers.GetEmptyBagsSlots(
    Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bags,
    Syndicator.Constants.AllBagIndexes
  )

  local status
  -- Only move more items if the last set moved in, or the last transfer
  -- completed.
  if #emptyBagSlots ~= self.transferState.emptyBagSlots then
    self.transferState.emptyBagSlots = #emptyBagSlots
    status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, emptyBagSlots)
  else
    status = addonTable.Constants.SortStatus.WaitingMove
  end

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches(getItems)
  end, function()
    self.transferState = {}
  end)
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:ResetToLive()
  self.lastCharacter = self.liveCharacter
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:SetupBlizzardFramesForTab()
  if self.isLive then

    BankFrame.activeTabIndex = addonTable.Constants.BlizzardBankTabConstants.Warband
    BankFrame.selectedTab = 1

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
  self.Money:SetText(addonTable.Utilities.GetMoneyString(warbandData.money, true))

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
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    tabScaleFactor = 40
  end
  local tabScale = math.min(1, addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE) / tabScaleFactor)

  self.tabsPool:ReleaseAll()
  self.purchaseButton:Hide()

  local warbandData = Syndicator.API.GetWarband(1)

  local lastTab = nil
  local tabs = {}

  local tabButton = self.tabsPool:Acquire()
  addonTable.Skins.AddFrame("SideTabButton", tabButton)
  tabButton:RegisterForClicks("LeftButtonUp")
  tabButton.Icon:SetTexture("Interface\\AddOns\\Baganator\\Assets\\Everything.png")
  tabButton:SetScript("OnClick", function(_, button)
    self:SetCurrentTab(0)
    self:GetParent():UpdateView()
  end)
  tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, -20)
  tabButton.SelectedTexture:Hide()
  tabButton:SetScale(tabScale)
  tabButton:Show()
  tabButton.tabName = BAGANATOR_L_EVERYTHING
  lastTab = tabButton
  table.insert(tabs, tabButton)

  for index, tabInfo in ipairs(warbandData.bank) do
    local tabButton = self.tabsPool:Acquire()
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tabButton.Icon:SetTexture(tabInfo.iconTexture)
    tabButton:SetScript("OnClick", function(_, button)
      self:SetCurrentTab(index)
      self:GetParent():UpdateView()

      if self.isLive and button == "RightButton" then
        self.TabSettingsMenu:OnOpenTabSettingsRequested(Syndicator.Constants.AllWarbandIndexes[index])
      end
    end)
    tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton.tabName = tabInfo.name
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end

  if self.isLive and C_Bank.CanPurchaseBankTab(Enum.BankType.Account) and not C_Bank.HasMaxBankTabs(Enum.BankType.Account) then
    local tabButton = self.purchaseButton
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton.Icon:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
    if not lastTab then
      tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, -20)
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
  addonTable.CallbackRegistry:TriggerEvent("TransferCancel")
  self.currentTab = index
  addonTable.Config.Set(addonTable.Config.Options.WARBAND_CURRENT_TAB, self.currentTab)
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:HighlightCurrentTab()
  if not self.Tabs then
    return
  end
  for tabIndex, tab in ipairs(self.Tabs) do
    tab.SelectedTexture:SetShown(tabIndex == self.currentTab + 1)
  end
end

-- Used to ensure translated button text doesn't cause buttons to overlap
function BaganatorItemViewCommonBankViewWarbandViewMixin:GetButtonsWidth(sideSpacing)
  return self.DepositItemsButton:GetWidth() + addonTable.Constants.ButtonFrameOffset + sideSpacing - 2 + self.WithdrawMoneyButton:GetWidth() + self.DepositMoneyButton:GetWidth() + sideSpacing + 15
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:UpdateView()
  self:ShowTab(self.currentTab, self:GetParent().liveBankActive)
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:ShowTab(tabIndex, isLive)
  self.isLive = isLive

  addonTable.Utilities.AddGeneralDropSlot(self, function()
    local bagData = {}
    for _, tab in ipairs(Syndicator.API.GetWarband(1).bank) do
      table.insert(bagData, tab.slots)
    end
    return bagData
  end, Syndicator.Constants.AllWarbandIndexes)

  self:GetParent():SetTitle(ACCOUNT_BANK_PANEL_TITLE)

  local warbandBank = Syndicator.API.GetWarband(1).bank[self.currentTab ~= 0 and self.currentTab or 1]

  local isWarbandData = warbandBank and #warbandBank.slots ~= 0 and (not self.isLive or C_PlayerInfo.HasAccountInventoryLock())
  self.BankMissingHint:SetShown(not isWarbandData)
  self:GetParent().SearchWidget:SetShown(isWarbandData)

  if self.BankMissingHint:IsShown() then
    if self.isLive and C_Bank.CanPurchaseBankTab(Enum.BankType.Account) then
      self.BankMissingHint:SetText(BAGANATOR_L_WARBAND_BANK_NOT_PURCHASED_HINT)
    elseif self.isLive and not C_PlayerInfo.HasAccountInventoryLock() then
      self.BankMissingHint:SetText(ACCOUNT_BANK_LOCKED_PROMPT)
    elseif self.isLive then
      self.BankMissingHint:SetText(BAGANATOR_L_WARBAND_BANK_TEMPORARILY_DISABLED_HINT)
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

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  if self.isLive then
    self.IncludeReagentsCheckbox:SetPoint("LEFT", self, "LEFT", addonTable.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.DepositItemsButton:SetPoint("LEFT", self, "LEFT", addonTable.Constants.ButtonFrameOffset + sideSpacing - 2, 0)

    self.DepositMoneyButton:SetPoint("RIGHT", self, "RIGHT", -sideSpacing, 0)
  end

  self:UpdateTabs()
  self:SetupBlizzardFramesForTab()
  self:HighlightCurrentTab()

  if self.BankMissingHint:IsShown() then
    -- Ensure bank missing hint has enough space to display
    local minWidth = self.BankMissingHint:GetWidth() + 40
    local maxHeight = 30

    for _, layout in ipairs(self.Container.Layouts) do
      layout:Hide()
    end

    self:SetSize(
      math.max(minWidth, addonTable.CategoryViews.Constants.MinWidth),
      maxHeight + 75 + topSpacing / 2
    )

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:OnFinished(character, isLive)
  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  local buttonPadding = 0
  if self.isLive then
    buttonPadding = buttonPadding + 26
  end

  self:SetSize(10, 10)
  local externalVerticalSpacing = self:GetParent().Tabs[1] and self:GetParent().Tabs[1]:IsShown() and (self:GetParent():GetBottom() - self:GetParent().Tabs[1]:GetBottom() + 5) or 0

  self:SetSize(
    self.Container:GetWidth() + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2,
    math.min(self.Container:GetHeight() + 75 + topSpacing / 2 + buttonPadding, UIParent:GetHeight() / self:GetParent():GetScale() - externalVerticalSpacing)
  )

  self:UpdateScroll(75 + topSpacing * 1/4 + buttonPadding + externalVerticalSpacing, self:GetParent():GetScale())
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
