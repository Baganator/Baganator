local _, addonTable = ...

local PopupMode = {
  Tab = "tab",
  Money = "money",
}
BaganatorSingleViewGuildViewMixin = {}

function BaganatorSingleViewGuildViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  addonTable.Utilities.AddScrollBar(self)

  self.Anchor = addonTable.ItemViewCommon.GetAnchorSetter(self, addonTable.Config.Options.GUILD_VIEW_POSITION)

  self.tabsPool = addonTable.ItemViewCommon.GetSideTabButtonPool(self)
  self.currentTab = addonTable.Config.Get(addonTable.Config.Options.GUILD_CURRENT_TAB)
  self.otherTabsCache = {}
  self.searchMonitors = {}

  for i = 1, MAX_GUILDBANK_TABS do
    table.insert(self.searchMonitors, CreateFrame("Frame", nil, self, "SyndicatorOfflineListSearchTemplate"))
  end

  self.refreshState = {}
  for _, value in pairs(addonTable.Constants.RefreshReason) do
    self.refreshState[value] = true
  end

  Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate",  function(_, guild, changes)
    if changes then
      for tabIndex, isChanged in pairs(changes) do
        if isChanged then
          if not self.otherTabsCache[guild] then
            self.otherTabsCache[guild] = {}
          end
          self.otherTabsCache[guild][tabIndex] = nil
          if tabIndex == self.currentTab or self.currentTab == 0 then
            for _, layout in ipairs(self.Container.Layouts) do
              layout:UpdateRefreshState({[addonTable.Constants.RefreshReason.ItemData] = true})
            end
          end
        end
      end
    end
    if self:IsVisible() and self.isLive then
      self:UpdateForGuild(guild, self.isLive)
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("GuildNameSet",  function(_, guild)
    if guild then
      self.lastGuild = guild
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange",  function(_, refreshState)
    if not self.lastGuild then
      return
    end

    self.refreshState = Mixin(self.refreshState, refreshState)

    for _, layout in ipairs(self.Container.Layouts) do
      layout:UpdateRefreshState(refreshState)
    end

    if self:IsVisible() then
      self:UpdateForGuild(self.lastGuild, self.isLive)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "GUILDBANKLOG_UPDATE",
    "GUILDBANK_UPDATE_TEXT",
    "GUILDBANK_UPDATE_WITHDRAWMONEY",
    "GUILDBANK_TEXT_CHANGED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
  })

  addonTable.Utilities.AddBagTransferManager(self) -- self.transferManager

  self.confirmTransferAllDialogName = "addonTable.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_GUILD_BANK,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self:RemoveSearchMatches(function() end)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  self.warningNotInGuildDialog = "addonTable.NotInGuild" .. self:GetName()
  StaticPopupDialogs[self.warningNotInGuildDialog] = {
    text = ERR_GUILD_PLAYER_NOT_IN_GUILD,
    button1 = OKAY,
    timeout = 0,
    hideOnEscape = 1,
  }

  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.AllFixedButtons)
  tAppendAll(self.AllButtons, self.LiveButtons)

  addonTable.Skins.AddFrame("ButtonFrame", self, {"guild"})
  addonTable.Skins.AddFrame("Button", self.DepositButton)
  addonTable.Skins.AddFrame("Button", self.WithdrawButton)
  addonTable.Skins.AddFrame("IconButton", self.ToggleTabTextButton, {"guildTabText"})
  addonTable.Skins.AddFrame("IconButton", self.ToggleTabLogsButton, {"guildTabLogs"})
  addonTable.Skins.AddFrame("IconButton", self.ToggleGoldLogsButton, {"guildGoldLogs"})
end

function BaganatorSingleViewGuildViewMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.GuildBanker then
      if GuildBankFrame:GetScript("OnHide") ~= nil then
        GuildBankFrame:SetScript("OnHide", nil)
        local hiddenFrame = CreateFrame("Frame")
        hiddenFrame:Hide()
        GuildBankFrame:SetParent(hiddenFrame)
      end
      self.lastGuild = Syndicator.API.GetCurrentGuild()
      -- Special case, classic, where Blizzard still opens the Guild Bank UI
      -- even if there's no guild
      if self.lastGuild == nil then
        StaticPopup_Show(self.warningNotInGuildDialog)
        CloseGuildBankFrame()
      else
        self.isLive = true
        self:Show()
      end
    end
  elseif eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.GuildBanker then
      self.isLive = false
      self:Hide()
    end
  elseif eventName == "GUILDBANKLOG_UPDATE" and self.LogsFrame:IsVisible() then
    if self.LogsFrame.showing == PopupMode.Tab then
      self.LogsFrame:ApplyTab()
    else
      self.LogsFrame:ApplyMoney()
    end
  elseif eventName == "GUILDBANK_UPDATE_TEXT" and self.TabTextFrame:IsVisible() then
    self.TabTextFrame:ApplyTab()
  elseif eventName == "GUILDBANK_TEXT_CHANGED" and self.TabTextFrame:IsVisible() then
    QueryGuildBankText(GetCurrentGuildBankTab());
  elseif eventName == "PLAYER_REGEN_DISABLED" then
    self.WithdrawButton:Disable()
    self.DepositButton:Disable()
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    self.WithdrawButton:SetEnabled(self.canWithdraw)
    self.DepositButton:Enable()
  elseif eventName == "GUILDBANK_UPDATE_WITHDRAWMONEY" and self:IsVisible() then
    self:UpdateForGuild(self.lastGuild, self.isLive)
  end
end

function BaganatorSingleViewGuildViewMixin:OnShow()
  -- Parent change to avoid ugly overlapping elements with main frame
  self.LogsFrame:SetParent(UIParent)
  self.TabTextFrame:SetParent(UIParent)

  self:UpdateForGuild(self.lastGuild, self.isLive)
end

function BaganatorSingleViewGuildViewMixin:OnHide()
  self:HideInfoDialogs()
  if GuildBankPopupFrame and GuildBankPopupFrame:IsShown() then
    GuildBankPopupFrame:Hide()
  end

  self.LogsFrame:SetParent(self)
  self.TabTextFrame:SetParent(self)

  self.LogsFrame:Hide()
  self.TabTextFrame:Hide()
  CloseGuildBankFrame()
end

function BaganatorSingleViewGuildViewMixin:HideInfoDialogs()
  self.LogsFrame:Hide()
  self.TabTextFrame:Hide()
end

function BaganatorSingleViewGuildViewMixin:ApplySearch(text)
  if not self:IsShown() then
    return
  end

  for _, monitor in ipairs(self.searchMonitors) do
    monitor:Stop()
  end

  if self.isLive then
    if self.currentTab == 0 then
      self.Container.GuildUnifiedLive:ApplySearch(text)
    else
      self.Container.GuildLive:ApplySearch(text)
    end
  else
    if self.currentTab == 0 then
      self.Container.GuildUnifiedCached:ApplySearch(text)
    else
      self.Container.GuildCached:ApplySearch(text)
    end
  end

  for _, tabButton in ipairs(self.Tabs) do
    tabButton.Icon:SetAlpha(1)
  end

  if text == "" then
    return
  end

  -- Highlight tabs with items that match

  local guildData = Syndicator.API.GetGuild(self.lastGuild)

  for index, tab in ipairs(guildData.bank) do
    if not self.otherTabsCache[self.lastGuild] then
      self.otherTabsCache[self.lastGuild] = {}
    end

    if self.otherTabsCache[self.lastGuild][index] == nil then
      self.otherTabsCache[self.lastGuild][index] = Syndicator.Search.GetBaseInfoFromList(tab.slots)
    end

    self.searchMonitors[index]:StartSearch(self.otherTabsCache[self.lastGuild][index], text, function(matches)
      if #matches > 0 then
        self.Tabs[index + 1].Icon:SetAlpha(1)
      else
        self.Tabs[index + 1].Icon:SetAlpha(0.2)
      end
    end)
  end
end

function BaganatorSingleViewGuildViewMixin:OnDragStart()
  if addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    return
  end

  self:StartMoving()
  self:SetUserPlaced(false)
end

function BaganatorSingleViewGuildViewMixin:OnDragStop()
  if addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    return
  end

  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local oldCorner = addonTable.Config.Get(addonTable.Config.Options.GUILD_VIEW_POSITION)[1]
  addonTable.Config.Set(addonTable.Config.Options.GUILD_VIEW_POSITION, {addonTable.Utilities.ConvertAnchorToCorner(oldCorner, self)})
end

function BaganatorSingleViewGuildViewMixin:OpenTabEditor()
  GuildBankPopupFrame:Hide()
  if not CanEditGuildBankTabInfo(GetCurrentGuildBankTab()) then
    UIErrorsFrame:AddMessage(BAGANATOR_L_CANNOT_EDIT_GUILD_BANK_TAB_ERROR, 1.0, 0.1, 0.1, 1.0)
    return
  end
  if addonTable.Constants.IsRetail then
    GuildBankPopupFrame.mode = IconSelectorPopupFrameModes.Edit
  end
  GuildBankPopupFrame:Show()
  if not addonTable.Constants.IsRetail then
    GuildBankPopupFrame:Update()
  end
  GuildBankPopupFrame:SetParent(UIParent)
  GuildBankPopupFrame:ClearAllPoints()
  GuildBankPopupFrame:SetClampedToScreen(true)

  if TSM_API then
    GuildBankPopupFrame:SetFrameStrata("HIGH")
  end

  GuildBankPopupFrame:SetFrameLevel(999)
  GuildBankPopupFrame:SetPoint("LEFT", self, "RIGHT", self.Tabs[1]:GetWidth(), 0)
end

function BaganatorSingleViewGuildViewMixin:UpdateTabs(guildData)
  addonTable.ReportEntry()

  local tabScaleFactor = 37
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    tabScaleFactor = 40
  end
  local tabScale = math.min(1, addonTable.Config.Get(addonTable.Config.Options.BAG_ICON_SIZE) / tabScaleFactor)
  -- Prevent regenerating the tabs if the base info hasn't changed since last
  -- time. This avoids failed clicks on the tabs if done quickly.
  if
    -- Need to add/remove the purchase tab button
    ((not self.isLive and not self.purchaseTabAdded) or (self.isLive and (self.purchaseTabAdded or not IsGuildLeader() or GetNumGuildBankTabs() >= MAX_BUY_GUILDBANK_TABS))) and
    -- Changed tab visual data (name, icon or visibility)
    self.lastTabData and guildData and tCompare(guildData.bank, self.lastTabData, 2) then
    for _, tab in ipairs(self.Tabs) do
      tab:SetScale(tabScale)
    end
    return
  end

  self.tabsPool:ReleaseAll()

  if not guildData then
    return
  end

  local lastTab
  local tabs = {}

  if #guildData.bank > 0 then
    local tabButton = self.tabsPool:Acquire()
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton:RegisterForClicks("LeftButtonUp")
    tabButton.Icon:SetTexture("Interface\\AddOns\\Baganator\\Assets\\Everything.png")
    tabButton.Icon:SetAlpha(1)
    tabButton:SetScript("OnClick", function(_, button)
      self:SetCurrentTab(0)
      self:UpdateForGuild(self.lastGuild, self.isLive)
    end)
    tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, -20)
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(tabButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(LINK_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_EVERYTHING))
      GameTooltip:Show()
    end)
    tabButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end

  self.lastTabData = {}
  for index, tabInfo in ipairs(guildData.bank) do
    local tabButton = self.tabsPool:Acquire()
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tabButton.Icon:SetTexture(tabInfo.iconTexture)
    tabButton.Icon:SetAlpha(1)
    tabButton:SetScript("OnClick", function(_, button)
      addonTable.CallbackRegistry:TriggerEvent("ClearHighlightGuildTab")
      self:SetCurrentTab(index)
      self:UpdateForGuild(self.lastGuild, self.isLive)
      if self.isLive and button == "RightButton" then
        self:OpenTabEditor()
      end
    end)
    tabButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(tabButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(tabInfo.name)
      if self.isLive and IsGuildLeader() then
        GameTooltip:AddLine(BAGANATOR_L_RIGHT_CLICK_FOR_SETTINGS, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
      end
      GameTooltip:Show()
      addonTable.CallbackRegistry:TriggerEvent("HighlightGuildTabItems", {[index] = true})
    end)
    tabButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
      addonTable.CallbackRegistry:TriggerEvent("ClearHighlightGuildTab")
    end)
    tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton.tabName = tabInfo.name
    tabButton:SetEnabled(tabInfo.isViewable)
    tabButton.Icon:SetDesaturated(not tabInfo.isViewable)
    lastTab = tabButton
    table.insert(tabs, tabButton)
    table.insert(self.lastTabData, CopyTable(tabInfo, 1))
  end

  if self.isLive and GetNumGuildBankTabs() < MAX_BUY_GUILDBANK_TABS and IsGuildLeader() then
    local tabButton = self.tabsPool:Acquire()
    addonTable.Skins.AddFrame("SideTabButton", tabButton)
    tabButton.Icon:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
    tabButton.Icon:SetAlpha(1)
    tabButton:SetScript("OnClick", function()
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
      StaticPopup_Show("CONFIRM_BUY_GUILDBANK_TAB")
    end)
    if not lastTab then
      tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -20)
    else
      tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    end
    tabButton.SelectedTexture:Hide()
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton:SetScript("OnEnter", function()
      GameTooltip:SetOwner(tabButton, "ANCHOR_RIGHT")
      GameTooltip:SetText(LINK_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_BUY_GUILD_BANK_TAB))
      local cost = GetGuildBankTabCost()
      if GetMoney() < cost and (GetMoney() + GetGuildBankMoney()) < cost then
        GameTooltip:AddLine(BAGANATOR_L_COST_X:format(RED_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(cost, true))))
      else
        GameTooltip:AddLine(BAGANATOR_L_COST_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(cost, true))))
      end
      GameTooltip:Show()
    end)
    tabButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    tabButton:SetEnabled(true)
    tabButton.Icon:SetDesaturated(false)
    table.insert(tabs, tabButton)
    self.purchaseTabAdded = true
  else
    self.purchaseTabAdded = false
  end

  self.Tabs = tabs

  if self.currentTab > #guildData.bank then
    self:SetCurrentTab(math.max(1, #guildData.bank))
  end
end

function BaganatorSingleViewGuildViewMixin:HighlightCurrentTab()
  if not self.Tabs then
    return
  end
  for tabIndex, tab in ipairs(self.Tabs) do
    tab.SelectedTexture:SetShown(tabIndex == (self.currentTab + 1))
  end
end

function BaganatorSingleViewGuildViewMixin:SetCurrentTab(index)
  addonTable.CallbackRegistry:TriggerEvent("TransferCancel")
  self.currentTab = index
  addonTable.Config.Set(addonTable.Config.Options.GUILD_CURRENT_TAB, self.currentTab)
  self:HighlightCurrentTab()

  if self.isLive then
    -- Query the first guild bank tab if we're using the unified view
    SetCurrentGuildBankTab(math.max(1, self.currentTab))
    QueryGuildBankTab(math.max(1, self.currentTab))
    if GuildBankPopupFrame:IsShown() then
      self:OpenTabEditor()
    end
    if self.LogsFrame:IsShown() and self.LogsFrame.showing == PopupMode.Tab then
      local tabInfo = Syndicator.API.GetGuild(self.lastGuild).bank[index]
      if not tabInfo then
        self.LogsFrame:Hide()
      else
        self:ShowTabLogs()
      end
    end
    if self.TabTextFrame:IsShown() then
      local tabInfo = Syndicator.API.GetGuild(self.lastGuild).bank[index]
      if not tabInfo then
        self.TabTextFrame:Hide()
      else
        self:ShowTabText()
      end
    end
  else
    self.LogsFrame:Hide()
  end
end

function BaganatorSingleViewGuildViewMixin:UpdateForGuild(guild, isLive)
  guild = guild or ""

  local guildWidth = addonTable.Config.Get(addonTable.Config.Options.GUILD_VIEW_WIDTH)

  self.isLive = isLive

  self.Container.GuildCached:SetShown(not self.isLive and self.currentTab > 0)
  self.Container.GuildLive:SetShown(self.isLive and self.currentTab > 0)
  self.Container.GuildUnifiedCached:SetShown(not self.isLive and self.currentTab == 0)
  self.Container.GuildUnifiedLive:SetShown(self.isLive and self.currentTab == 0)

  local guildData = Syndicator.API.GetGuild(guild)
  if not guildData then
    self:SetTitle("")
  else
    self.lastGuild = guild
    self:SetTitle(BAGANATOR_L_XS_GUILD_BANK:format(guildData.details.guild))
  end

  if self.isLive then
    if self.currentTab ~= 0 and self.currentTab ~= GetCurrentGuildBankTab() then
      self.currentTab = GetCurrentGuildBankTab()
      addonTable.Config.Set(addonTable.Config.Options.GUILD_CURRENT_TAB, self.currentTab)
      if GuildBankPopupFrame:IsShown() then
        self:OpenTabEditor()
      end
    end
  end
  for _, button in ipairs(self.LiveButtons) do
    button:SetShown(self.isLive)
  end
  self.ToggleTabLogsButton:SetEnabled(self.currentTab ~= 0)
  self.ToggleTabTextButton:SetEnabled(self.currentTab ~= 0)

  self:UpdateTabs(guildData)
  self:HighlightCurrentTab()

  local active

  if not self.isLive then
    if self.currentTab > 0 then
      self.Container.GuildCached:ShowGuild(guild, self.currentTab, guildWidth)
      self.Container.GuildCached:SetShown(guildData and #guildData.bank > 0)
      active = self.Container.GuildCached
    else
      self.Container.GuildUnifiedCached:ShowGuild(guild, guildWidth * 2)
      self.Container.GuildUnifiedCached:SetShown(guildData and #guildData.bank > 0)
      active = self.Container.GuildUnifiedCached
    end
  else
    if self.currentTab > 0 then
      self.Container.GuildLive:ShowGuild(guild, self.currentTab, guildWidth)
      self.Container.GuildLive:SetShown(guildData and #guildData.bank > 0)
      active = self.Container.GuildLive
    else
      self.Container.GuildUnifiedLive:ShowGuild(guild, guildWidth * 2)
      self.Container.GuildUnifiedLive:SetShown(guildData and #guildData.bank > 0)
      active = self.Container.GuildUnifiedLive
    end
  end

  local searchText = self.SearchWidget.SearchBox:GetText()

  if guildData then
    self:ApplySearch(searchText)
  end

  if guildData and guildData.bank[1] then
    self.Tabs[1]:SetPoint("LEFT", active, "LEFT")
  end

  local sideSpacing, topSpacing, searchSpacing = addonTable.Utilities.GetSpacing()

  self.SearchWidget:SetSpacing(sideSpacing)

  local detailsHeight = 0
  if self.isLive then
    local _, canDeposit, remainingWithdrawals, depositText, withdrawText
    if self.currentTab > 0 then
      _, _, _, canDeposit, _, remainingWithdrawals = GetGuildBankTabInfo(self.currentTab)
      depositText = canDeposit and GREEN_FONT_COLOR:WrapTextInColorCode(YES) or RED_FONT_COLOR:WrapTextInColorCode(NO)
      if remainingWithdrawals == -1 then
        withdrawText = GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_UNLIMITED)
      elseif remainingWithdrawals == 0 then
        withdrawText = RED_FONT_COLOR:WrapTextInColorCode(NO)
      else
        withdrawText = FormatLargeNumber(remainingWithdrawals)
      end
    else
      depositText = LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_MULTIPLE_TABS)
      withdrawText = LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_MULTIPLE_TABS)
      remainingWithdrawals = -2
    end
    self.ItemsTransferInfo:SetText(BAGANATOR_L_GUILD_WITHDRAW_DEPOSIT_X_X:format(withdrawText, depositText))
    local guildMoney = GetGuildBankMoney()
    local withdrawMoney = math.min(GetGuildBankWithdrawMoney(), guildMoney)
    if not CanWithdrawGuildBankMoney() or withdrawMoney == 0 then
      self.canWithdraw = false
      withdrawMoney = 0
      self.WithdrawButton:Disable()
    else
      self.canWithdraw = true
      self.WithdrawButton:Enable()
    end
    self.Money:SetText(CURRENCY_TOTAL:format(GetMoneyString(guildMoney, true), ""))
    self.GoldTransferInfo:SetText(BAGANATOR_L_GUILD_MONEY_WITHDRAW_X:format(GetMoneyString(withdrawMoney, true)))
    self.NoTabsText:SetPoint("TOP", self, "CENTER", 0, 15)
    detailsHeight = 50

    self.wouldShowTransferButton = remainingWithdrawals == -1 or remainingWithdrawals > 0
    self.LogsFrame:ApplyTabTitle()
  else -- not live
    self.wouldShowTransferButton = false
    self.ItemsTransferInfo:SetText("")
    self.GoldTransferInfo:SetText("")
    if guildData then
      self.Money:SetText(BAGANATOR_L_GUILD_MONEY_X:format(GetMoneyString(guildData.money, true)))
    end
    self.NoTabsText:SetPoint("TOP", self, "CENTER", 0, 5)
    detailsHeight = 10

    self.LogsFrame:Hide()
  end
  self.TransferButton:SetShown(self.wouldShowTransferButton)

  self.SearchWidget:SetShown(addonTable.Config.Get(addonTable.Config.Options.SHOW_SEARCH_BOX) and active:IsShown())
  self.NotVisitedText:SetShown(not active:IsShown() and (not guildData or not guildData.details.visited))
  self.NoTabsText:SetShown(not active:IsShown() and guildData and guildData.details.visited)
  self.Money:SetShown(active:IsShown() or guildData and guildData.details.visited)

  self.ItemsTransferInfo:SetPoint("BOTTOMLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset, 50)
  self.GoldTransferInfo:SetPoint("BOTTOMLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset, 30)
  self.Money:SetPoint("BOTTOMLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset, 10)
  self.DepositButton:SetPoint("BOTTOMRIGHT", self, -sideSpacing + 1, 6)

  self.Container:SetSize(active:GetWidth(), active:GetHeight())

  if self.NotVisitedText:IsShown() or self.NoTabsText:IsShown() then
    local width = self.NotVisitedText:IsShown() and self.NotVisitedText:GetWidth() or self.NoTabsText:GetWidth()
    self:SetSize(
      math.max(400, width) + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset + 40,
      80 + topSpacing / 2
    )
  else
    local tabsHeight = #self.Tabs * (self.Tabs[1]:GetHeight() + 12) * self.Tabs[1]:GetScale() + 20 * self.Tabs[1]:GetScale()
    self:SetSize(
      self.Container:GetWidth() + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2,
      math.max(tabsHeight, math.min(self.Container:GetHeight() + 44 + searchSpacing + detailsHeight, UIParent:GetHeight() / self:GetScale()))
    )
    self:UpdateScroll(44 + searchSpacing + detailsHeight, self:GetScale())
  end

  self.ButtonVisibility:Update()

  self.refreshState = {}

  addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
end

function BaganatorSingleViewGuildViewMixin:IsTransferActive()
  return self.TransferButton:IsShown()
end

function BaganatorSingleViewGuildViewMixin:RemoveSearchMatches(callback)
  local matches = self.Container.GuildLive.SearchMonitor:GetMatches()

  local slots = addonTable.Transfers.GetBagsSlots(Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bags, Syndicator.Constants.AllBagIndexes)

  local status, modes = addonTable.Transfers.FromGuildToBags(matches, Syndicator.Constants.AllBagIndexes, slots)

  self.transferManager:Apply(status, modes or {"GuildCacheUpdate"}, function()
    self:RemoveSearchMatches(callback)
  end, function()
    callback()
  end)
end

function BaganatorSingleViewGuildViewMixin:Transfer(button)
  if self.SearchWidget.SearchBox:GetText() == "" then
    StaticPopup_Show(self.confirmTransferAllDialogName)
  else
    self:RemoveSearchMatches(function() end)
  end
end

function BaganatorSingleViewGuildViewMixin:ToggleTabText()
  if self.TabTextFrame:IsShown() then
    self.TabTextFrame:Hide()
    return
  end
  self:HideInfoDialogs()
  self.TabTextFrame:Show()
  self:ShowTabText()
end

function BaganatorSingleViewGuildViewMixin:ShowTabText()
  self.TabTextFrame:Show()
  self.TabTextFrame:ApplyTab()
  self.TabTextFrame:ApplyTabTitle()
  QueryGuildBankText(GetCurrentGuildBankTab());
end

function BaganatorSingleViewGuildViewMixin:ToggleTabLogs()
  if self.LogsFrame.showing == PopupMode.Tab and self.LogsFrame:IsShown() then
    self.LogsFrame:Hide()
    return
  end
  self:ShowTabLogs()
end

function BaganatorSingleViewGuildViewMixin:ShowTabLogs()
  self:HideInfoDialogs()
  self.LogsFrame:Show()
  self.LogsFrame:ApplyTab()
  self.LogsFrame:ApplyTabTitle()
  QueryGuildBankLog(GetCurrentGuildBankTab());
end

function BaganatorSingleViewGuildViewMixin:ToggleMoneyLogs()
  if self.LogsFrame.showing == PopupMode.Money and self.LogsFrame:IsShown() then
    self.LogsFrame:Hide()
    return
  end
  self:HideInfoDialogs()
  self.LogsFrame:Show()
  self.LogsFrame:SetTitle(BAGANATOR_L_MONEY_LOGS)
  self.LogsFrame:ApplyMoney()
  QueryGuildBankLog(MAX_GUILDBANK_TABS + 1);
end

BaganatorGuildLogsTemplateMixin = {}
function BaganatorGuildLogsTemplateMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  ScrollUtil.RegisterScrollBoxWithScrollBar(self.TextContainer:GetScrollBox(), self.ScrollBar)

  self.TextContainer.ScrollBox.FontStringContainer:HookScript("OnHyperlinkClick", function()
    self:Raise()
  end)

  addonTable.Skins.AddFrame("ButtonFrame", self)
  addonTable.Skins.AddFrame("TrimScrollBar", self.ScrollBar)

  self.parentName = self:GetParent():GetName() -- as the parent changes
end

function BaganatorGuildLogsTemplateMixin:OnShow()
  self:ClearAllPoints()
  local anchor = addonTable.Config.Get(addonTable.Config.Options.GUILD_VIEW_DIALOG_POSITION)
  if anchor[2] ~= "UIParent" then
    anchor[2] = self.parentName
  end
  self:SetPoint(unpack(anchor))
end

function BaganatorGuildLogsTemplateMixin:OnDragStart()
  if addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    return
  end

  self:StartMoving()
  self:SetUserPlaced(false)
end

function BaganatorGuildLogsTemplateMixin:OnDragStop()
  if addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    return
  end

  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  addonTable.Config.Set(addonTable.Config.Options.GUILD_VIEW_DIALOG_POSITION, {point, UIParent:GetName(), relativePoint, x, y})
end

function BaganatorGuildLogsTemplateMixin:ApplyTabTitle()
  if self.showing ~= PopupMode.Tab then return
  end

  local tabInfo = Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank[GetCurrentGuildBankTab()]
  if tabInfo ~= nil then
    self:SetTitle(BAGANATOR_L_X_LOGS:format(tabInfo.name))
  else
    self:SetTitle("")
  end
end

function BaganatorGuildLogsTemplateMixin:ApplyTab()
  self.showing = PopupMode.Tab

  if #Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank == 0 then
    self.TextContainer:SetText(BAGANATOR_L_GUILD_NO_TABS_PURCHASED)
    return
  end

  -- Code for logs copied from Blizzard lua dumps and modified
	local tab = GetCurrentGuildBankTab();
	local numTransactions = GetNumGuildBankTransactions(tab);

	local msg = "";
	for i = numTransactions, 1, -1 do
		local type, name, itemLink, count, tab1, tab2, year, month, day, hour = GetGuildBankTransaction(tab, i);
		if ( not name ) then
			name = UNKNOWN;
		end
		name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE;
		if ( type == "deposit" ) then
			msg = msg .. format(GUILDBANK_DEPOSIT_FORMAT, name, itemLink);
			if ( count > 1 ) then
				msg = msg..format(GUILDBANK_LOG_QUANTITY, count);
			end
		elseif ( type == "withdraw" ) then
			msg = msg .. format(GUILDBANK_WITHDRAW_FORMAT, name, itemLink);
			if ( count > 1 ) then
				msg = msg..format(GUILDBANK_LOG_QUANTITY, count);
			end
		elseif ( type == "move" ) then
			msg = msg .. format(GUILDBANK_MOVE_FORMAT, name, itemLink, count, GetGuildBankTabInfo(tab1), GetGuildBankTabInfo(tab2));
		end
    msg = msg..GUILD_BANK_LOG_TIME:format(RecentTimeDate(year, month, day, hour))
    msg = msg .. "\n"
	end

  if numTransactions == 0 then
    msg = BAGANATOR_L_NO_TRANSACTIONS_AVAILABLE
  end

  self.TextContainer:SetText(msg)
end

function BaganatorGuildLogsTemplateMixin:ApplyMoney()
  self.showing = PopupMode.Money
  -- Code for logs copied from Blizzard lua dumps and modified
  local numTransactions = GetNumGuildBankMoneyTransactions();
  local msg = ""
  for i=numTransactions, 1, -1 do
    local type, name, amount, year, month, day, hour = GetGuildBankMoneyTransaction(i);
    if ( not name ) then
      name = UNKNOWN;
    end
    name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE;
    local money = GetDenominationsFromCopper(amount);
    if ( type == "deposit" ) then
      msg = msg .. format(GUILDBANK_DEPOSIT_MONEY_FORMAT, name, money);
    elseif ( type == "withdraw" ) then
      msg = msg .. format(GUILDBANK_WITHDRAW_MONEY_FORMAT, name, money);
    elseif ( type == "repair" ) then
      msg = msg .. format(GUILDBANK_REPAIR_MONEY_FORMAT, name, money);
    elseif ( type == "withdrawForTab" ) then
      msg = msg .. format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, name, money);
    elseif ( type == "buyTab" ) then
      if ( amount > 0 ) then
        msg = msg .. format(GUILDBANK_BUYTAB_MONEY_FORMAT, name, money);
      else
        msg = msg .. format(GUILDBANK_UNLOCKTAB_FORMAT, name);
      end
    elseif ( type == "depositSummary" ) then
      msg = msg .. format(GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT, money);
    end
    msg = msg..GUILD_BANK_LOG_TIME:format(RecentTimeDate(year, month, day, hour))
    msg = msg .. "\n"
  end

  if numTransactions == 0 then
    msg = BAGANATOR_L_NO_TRANSACTIONS_AVAILABLE
  end

  self.TextContainer:SetText(msg)
end

BaganatorGuildTabTextTemplateMixin = {}
function BaganatorGuildTabTextTemplateMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  ScrollUtil.RegisterScrollBoxWithScrollBar(self.TextContainer:GetScrollBox(), self.ScrollBar)

  addonTable.Skins.AddFrame("ButtonFrame", self)
  addonTable.Skins.AddFrame("Button", self.SaveButton)

  self.TextContainer:GetEditBox():SetMaxLetters(500)

  addonTable.Skins.AddFrame("EditBox", self.TextContainer:GetEditBox())
  addonTable.Skins.AddFrame("TrimScrollBar", self.ScrollBar)

  self.parentName = self:GetParent():GetName() -- as the parent changes
end

function BaganatorGuildTabTextTemplateMixin:OnShow()
  self:ClearAllPoints()
  local anchor = addonTable.Config.Get(addonTable.Config.Options.GUILD_VIEW_DIALOG_POSITION)
  if anchor[2] ~= "UIParent" then
    anchor[2] = self.parentName
  end
  self:SetPoint(unpack(anchor))
end

function BaganatorGuildTabTextTemplateMixin:ApplyTab()
  local currentTab = GetCurrentGuildBankTab()

  if #Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank == 0 then
    self.TextContainer:SetText(BAGANATOR_L_GUILD_NO_TABS_PURCHASED)
    self.SaveButton:Hide()
    self.TextContainer:GetEditBox():SetEnabled(false)
    return
  end

  self.TextContainer:SetText(GetGuildBankText(currentTab))
  local canEdit = CanEditGuildTabInfo(currentTab)
  self.SaveButton:SetShown(canEdit)
  self.TextContainer:GetEditBox():SetEnabled(canEdit)
end

function BaganatorGuildTabTextTemplateMixin:ApplyTabTitle()
  local tabInfo = Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank[GetCurrentGuildBankTab()]
  if tabInfo ~= nil then
    self:SetTitle(BAGANATOR_L_X_INFORMATION:format(tabInfo.name))
  else
    self:SetTitle("")
  end
end

function BaganatorGuildTabTextTemplateMixin:OnDragStart()
  if addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    return
  end

  self:StartMoving()
  self:SetUserPlaced(false)
end

function BaganatorGuildTabTextTemplateMixin:OnDragStop()
  if addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    return
  end

  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  addonTable.Config.Set(addonTable.Config.Options.GUILD_VIEW_DIALOG_POSITION, {point, UIParent:GetName(), x, y})
end
