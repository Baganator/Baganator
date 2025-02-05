local _, addonTable = ...

local function AddBankTabSettingsToTooltip(tooltip, depositFlags)
  -- Copied Blizzard function
  if not tooltip or not depositFlags then
    return;
  end

  if FlagsUtil.IsSet(depositFlags, Enum.BagSlotFlags.ExpansionCurrent) then
    GameTooltip_AddNormalLine(tooltip, BANK_TAB_EXPANSION_ASSIGNMENT:format(BANK_TAB_EXPANSION_FILTER_CURRENT));
  elseif FlagsUtil.IsSet(depositFlags, Enum.BagSlotFlags.ExpansionLegacy) then
    GameTooltip_AddNormalLine(tooltip, BANK_TAB_EXPANSION_ASSIGNMENT:format(BANK_TAB_EXPANSION_FILTER_LEGACY));
  end

  local filterList = ContainerFrameUtil_ConvertFilterFlagsToList(depositFlags);
  if filterList then
    local wrapText = true;
    GameTooltip_AddNormalLine(tooltip, BANK_TAB_DEPOSIT_ASSIGNMENTS:format(filterList), wrapText);
  end
end

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

  self.refreshState = {}
  for _, value in pairs(addonTable.Constants.RefreshReason) do
    self.refreshState[value] = true
  end

  Syndicator.CallbackRegistry:RegisterCallback("WarbandBankCacheUpdate",  function(_, index, updates)
    self:NotifyBagUpdate(updates)
    if updates.tabInfo then
      self.updateTabs = true
    end
    if self.tabsSearchCache[index] then
      for bagID in pairs(updates.bags) do
        self.tabsSearchCache[index][tIndexOf(Syndicator.Constants.AllWarbandIndexes, bagID)] = nil
      end
    end
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    if updates.tabInfo then
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
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

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange",  function(_, refreshState)
    self.refreshState = Mixin(self.refreshState, refreshState)

    for _, layout in ipairs(self.Container.Layouts) do
      layout:UpdateRefreshState(refreshState)
    end

    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)

  self.searchMonitors = {}
  self.tabsSearchCache = {}

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
  self.purchaseButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(self.purchaseButton, "ANCHOR_RIGHT")
    GameTooltip:SetText(LINK_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_BUY_WARBAND_BANK_TAB))
    local cost = C_Bank.FetchNextPurchasableBankTabCost(Enum.BankType.Account)
    if cost > GetMoney() then
      GameTooltip:AddLine(BAGANATOR_L_COST_X:format(RED_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(cost, true))))
    else
      GameTooltip:AddLine(BAGANATOR_L_COST_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(cost, true))))
    end
    GameTooltip:Show()
  end)
  self.purchaseButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  addonTable.Skins.AddFrame("SideTabButton", self.purchaseButton)
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

function BaganatorItemViewCommonBankViewWarbandViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end

  self:ApplyTabButtonSearch(text)

  for _, layout in ipairs(self.Container.Layouts) do
    if layout:IsShown() then
      layout:ApplySearch(text)
    end
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:ApplyTabButtonSearch(text)
  if not self:IsShown() then
    return
  end

  for _, tabButton in ipairs(self.Tabs) do
    tabButton.Icon:SetAlpha(1)
  end

  if text == "" then
    return
  end

  for _, monitor in ipairs(self.searchMonitors) do
    monitor:Stop()
  end

  local warbandData = Syndicator.API.GetWarband(1)

  for index, tab in ipairs(warbandData.bank) do
    if not self.tabsSearchCache[1] then
      self.tabsSearchCache[1] = {}
    end

    if self.tabsSearchCache[1][index] == nil then
      self.tabsSearchCache[1][index] = Syndicator.Search.GetBaseInfoFromList(tab.slots)
    end

    self.searchMonitors[index]:StartSearch(self.tabsSearchCache[1][index], text, function(matches)
      if #matches > 0 then
        self.Tabs[index + 1].Icon:SetAlpha(1)
      else
        self.Tabs[index + 1].Icon:SetAlpha(0.2)
      end
    end)
  end
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

  local bagSlots = addonTable.Transfers.GetBagsSlots(
    Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bags,
    Syndicator.Constants.AllBagIndexes
  )

  local status
  local counts = addonTable.Transfers.CountByItemIDs(bagSlots)
  -- Only move more items if the last set moved in, or the last transfer
  -- completed.
  if not self.transferState.counts or not tCompare(counts, self.transferState.counts, 2) then
    self.transferState.counts = counts
    status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, bagSlots)
  else
    status = addonTable.Constants.SortStatus.WaitingMove
  end

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches(getItems)
  end, function()
    self.transferState = {}
  end)
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

  if #warbandData.bank ~= 0 then
    local tabButton = self.tabsPool:Acquire()
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton:RegisterForClicks("LeftButtonUp")
    tabButton.Icon:SetTexture("Interface\\AddOns\\Baganator\\Assets\\Everything.png")
    tabButton.Icon:SetAlpha(1)
    tabButton:SetScript("OnClick", function(_, button)
      self:SetCurrentTab(0)
      self:GetParent():UpdateView()
    end)
    tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, -20)
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(tabButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(LINK_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_EVERYTHING))
      GameTooltip:Show()
    end)
    tabButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    tabButton:Show()
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end

  for index, tabInfo in ipairs(warbandData.bank) do
    local tabButton = self.tabsPool:Acquire()
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tabButton.Icon:SetTexture(tabInfo.iconTexture)
    tabButton.Icon:SetAlpha(1)
    tabButton:SetScript("OnClick", function(_, button)
      addonTable.CallbackRegistry:TriggerEvent("ClearHighlightBag")
      self:SetCurrentTab(index)
      self:GetParent():UpdateView()

      if self.isLive and button == "RightButton" then
        self.TabSettingsMenu:OnOpenTabSettingsRequested(Syndicator.Constants.AllWarbandIndexes[index])
      end
    end)
    tabButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(tabButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(tabInfo.name)
      AddBankTabSettingsToTooltip(GameTooltip, tabInfo.depositFlags)
      if self.isLive then
        GameTooltip:AddLine(BAGANATOR_L_RIGHT_CLICK_FOR_SETTINGS, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
      end
      GameTooltip:Show()
      addonTable.CallbackRegistry:TriggerEvent("HighlightBagItems", {[Syndicator.Constants.AllWarbandIndexes[index]] = true})
    end)
    tabButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      addonTable.CallbackRegistry:TriggerEvent("ClearHighlightBag")
    end)
    tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end

  while #self.searchMonitors < #warbandData.bank do
    table.insert(self.searchMonitors, CreateFrame("Frame", nil, self, "SyndicatorOfflineListSearchTemplate"))
  end

  if self.isLive and C_Bank.CanPurchaseBankTab(Enum.BankType.Account) and not C_Bank.HasMaxBankTabs(Enum.BankType.Account) then
    local tabButton = self.purchaseButton
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton.Icon:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
    tabButton.Icon:SetAlpha(1)
    if not lastTab then
      tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, -20)
    else
      tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    end
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
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
  if tabIndex ~= self.lastTab or self.isLive ~= isLive then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true
    self.refreshState[addonTable.Constants.RefreshReason.Character] = true
  end
  self.lastTab = tabIndex

  self.isLive = isLive

  self.searchToApply = self.searchToApply or self.refreshState[addonTable.Constants.RefreshReason.Searches] or self.refreshState[addonTable.Constants.RefreshReason.ItemData] or self.refreshState[addonTable.Constants.RefreshReason.ItemWidgets]

  addonTable.Utilities.AddGeneralDropSlot(self, function()
    local bagData = {}
    for index, tab in ipairs(Syndicator.API.GetWarband(1).bank) do
      if index == self.currentTab or self.currentTab == 0 then
        table.insert(bagData, tab.slots)
      -- mark tabs as unavailable for dropping into if they aren't the current
      -- one
      else
        table.insert(bagData, {})
      end
    end
    return bagData
  end, Syndicator.Constants.AllWarbandIndexes)

  self:GetParent():SetTitle(ACCOUNT_BANK_PANEL_TITLE)

  local warbandBank = Syndicator.API.GetWarband(1).bank[self.currentTab ~= 0 and self.currentTab or 1]

  self.isLocked = self.isLive and not C_PlayerInfo.HasAccountInventoryLock()
  local isWarbandData = warbandBank and #warbandBank.slots ~= 0 and not self.isLocked
  self.BankMissingHint:SetShown(not isWarbandData)
  self:GetParent().SearchWidget:SetShown(addonTable.Config.Get(addonTable.Config.Options.SHOW_SEARCH_BOX) and isWarbandData)

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

  self.IncludeReagentsCheckbox:SetShown(isWarbandData and self.isLive)
  self.DepositItemsButton:SetShown(isWarbandData and self.isLive)

  self.DepositMoneyButton:SetShown(self.isLive and C_PlayerInfo.HasAccountInventoryLock())
  self.WithdrawMoneyButton:SetShown(self.isLive and C_PlayerInfo.HasAccountInventoryLock())

  self:UpdateCurrencies()

  self:GetParent().AllButtons = {}
  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.LiveButtons)

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  if self.isLive then
    self.IncludeReagentsCheckbox:SetPoint("LEFT", self, "LEFT", addonTable.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.DepositItemsButton:SetPoint("LEFT", self, "LEFT", addonTable.Constants.ButtonFrameOffset + sideSpacing - 2, 0)

    self.DepositMoneyButton:ClearAllPoints()
    if isWarbandData then
      self.DepositMoneyButton:SetPoint("BOTTOM", self, 0, 29)
      self.DepositMoneyButton:SetPoint("RIGHT",  self,-sideSpacing, 0)
    else
      self.DepositMoneyButton:SetPoint("BOTTOM",  self, 0, 5)
      self.DepositMoneyButton:SetPoint("RIGHT", self.Money, "LEFT", -sideSpacing, 0)
    end
  end

  self:UpdateTabs()
  self:SetupBlizzardFramesForTab()
  self:HighlightCurrentTab()

  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(not self.isLive or C_PlayerInfo.HasAccountInventoryLock())
  end

  if self.BankMissingHint:IsShown() then
    -- Ensure bank missing hint has enough space to display
    local minWidth = self.BankMissingHint:GetWidth()
    local maxHeight = 30

    for _, layout in ipairs(self.Container.Layouts) do
      layout:Hide()
    end

    self:SetSize(
      math.max(400, self.BankMissingHint:GetWidth()) + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset + 40,
      80 + topSpacing / 2
    )

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end
end

function BaganatorItemViewCommonBankViewWarbandViewMixin:OnFinished(character, isLive)
  if self.BankMissingHint:IsShown() then
    return
  end

  local sideSpacing, topSpacing, searchSpacing = addonTable.Utilities.GetSpacing()

  local buttonPadding = 0
  if self.isLive then
    buttonPadding = buttonPadding + 26
  end

  self:SetSize(10, 10)
  local externalVerticalSpacing = self:GetParent().Tabs[1] and self:GetParent().Tabs[1]:IsShown() and (self:GetParent():GetBottom() - self:GetParent().Tabs[1]:GetBottom() + 5) or 0
  local tabHeight = #self.Tabs * (self.Tabs[1]:GetHeight() + 12) * self.Tabs[1]:GetScale() + 20 * self.Tabs[1]:GetScale()
  local screenHeightSpace = UIParent:GetHeight() / self:GetParent():GetScale() - externalVerticalSpacing
  local spaceOccupied = self.Container:GetHeight() + 50 + searchSpacing + topSpacing / 2 + buttonPadding

  self:SetSize(
    self.Container:GetWidth() + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2,
    math.max(tabHeight, math.min(spaceOccupied, screenHeightSpace))
  )

  self.Container:SetHeight(math.max(self.Container:GetHeight(), self:GetHeight() - spaceOccupied + self.Container:GetHeight()))

  self:UpdateScroll(50 + searchSpacing + topSpacing * 1/4 + buttonPadding + externalVerticalSpacing, self:GetParent():GetScale())
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
