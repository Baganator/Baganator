BaganatorGuildViewMixin = {}

function BaganatorGuildViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.tabsPool = Baganator.UnifiedBags.GetSideTabButtonPool(self)
  self.currentTab = 1

  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
    if self.SearchBox:GetText() == "" then
      self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
    end
  end)

  self.SearchBox.clearButton:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end)

  Baganator.CallbackRegistry:RegisterCallback("GuildCacheUpdate",  function(_, guild, tabIndex, anyChanges)
    if anyChanges then
      for _, layout in ipairs(self.Layouts) do
        layout:RequestContentRefresh()
      end
    end
    if self:IsShown() then
      self:UpdateForGuild(guild, true)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("GuildNameSet",  function(_, guild)
    self.lastGuild = guild
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() then
      self:UpdateForGuild(self.lastGuild, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    self.settingChanged = true
    if not self.lastGuild then
      return
    end
    if tIndexOf(Baganator.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsShown() then
        Baganator.Utilities.ApplyVisuals(self)
      end
    elseif tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsShown() then
        self:UpdateForGuild(self.lastGuild, self.isLive)
      end
    elseif settingName == Baganator.Config.Options.SHOW_BUTTONS_ON_ALT then
      self:UpdateAllButtons()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
  self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  self.confirmTransferAllDialogName = "Baganator.ConfirmTransferAll_" .. self:GetName()
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
end

function BaganatorGuildViewMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.GuildBanker then
      self.isLive = true
      self:Show()
    end
  elseif eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.GuildBanker then
      self.isLive = false
      self:Hide()
    end
  elseif eventName == "MODIFIER_STATE_CHANGED" then
    self:UpdateAllButtons()
  end
end

function BaganatorGuildViewMixin:OnShow()
  self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
  self:UpdateForGuild(self.lastGuild, self.isLive)
  self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function BaganatorGuildViewMixin:OnHide()
  self:UnregisterEvent("MODIFIER_STATE_CHANGED")
end

function BaganatorGuildViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsShown() then
    return
  end

  if self.isLive then
    self.GuildLive:ApplySearch(text)
  else
    self.GuildCached:ApplySearch(text)
  end
end

function BaganatorGuildViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorGuildViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.GUILD_VIEW_POSITION, {point, x, y})
end

function BaganatorGuildViewMixin:OpenTabEditor()
  GuildBankPopupFrame:Hide()
  if not CanEditGuildBankTabInfo(GetCurrentGuildBankTab()) then
    return
  end
  if Baganator.Constants.IsRetail then
    GuildBankPopupFrame.mode = IconSelectorPopupFrameModes.Edit
  end
  GuildBankPopupFrame:Show()
  if not Baganator.Constants.IsRetail then
    GuildBankPopupFrame:Update()
  end
  GuildBankPopupFrame:ClearAllPoints()
  GuildBankPopupFrame:SetParent(self)
  GuildBankPopupFrame:SetPoint("TOP", self)
  GuildBankPopupFrame:SetPoint("LEFT", self.Tabs[1], "RIGHT")
end

function BaganatorGuildViewMixin:UpdateTabs()
  local tabScale = math.min(1, Baganator.Config.Get(Baganator.Config.Options.BAG_ICON_SIZE) / 37)
  self.tabsPool:ReleaseAll()

  local lastTab
  local tabs = {}
  for index, tabInfo in ipairs(BAGANATOR_DATA.Guilds[self.lastGuild].bank) do
    local tabButton = self.tabsPool:Acquire()
    tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tabButton.Icon:SetTexture(tabInfo.iconTexture)
    tabButton:SetScript("OnClick", function(_, button)
      self:SetCurrentTab(index)
      self:UpdateForGuild(self.lastGuild, self.isLive)
      if self.isLive and button == "RightButton" then
        self:OpenTabEditor()
      end
    end)
    if not lastTab then
      tabButton:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -20)
    else
      tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    end
    tabButton.SelectedTexture:SetShown(index == self.currentTab)
    tabButton:SetID(index)
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton.tabName = tabInfo.name
    tabButton:SetEnabled(tabInfo.isViewable)
    tabButton.Icon:SetDesaturated(not tabInfo.isViewable)
    lastTab = tabButton
    table.insert(tabs, tabButton)
  end

  if self.isLive and GetNumGuildBankTabs() < MAX_BUY_GUILDBANK_TABS and IsGuildLeader() then
    local tabButton = self.tabsPool:Acquire()
    tabButton.Icon:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-NewTab")
    tabButton:SetScript("OnClick", function()
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
      StaticPopup_Show("CONFIRM_BUY_GUILDBANK_TAB")
    end)
    tabButton:SetPoint("TOPLEFT", lastTab, "BOTTOMLEFT", 0, -12)
    tabButton.SelectedTexture:SetShown(false)
    tabButton:SetScale(tabScale)
    tabButton:Show()
    tabButton.tabName = BUY_GUILDBANK_TAB
    tabButton:SetEnabled(true)
    tabButton.Icon:SetDesaturated(false)
    table.insert(tabs, tabButton)
  end

  self.Tabs = tabs
end

function BaganatorGuildViewMixin:SetCurrentTab(index)
  Baganator.CallbackRegistry:TriggerEvent("TransferCancel")
  self.currentTab = index
  for tabIndex, tab in ipairs(self.Tabs) do
    tab.SelectedTexture:SetShown(tabIndex == index)
  end

  if self.isLive then
    SetCurrentGuildBankTab(self.currentTab)
    QueryGuildBankTab(self.currentTab);
    if GuildBankPopupFrame:IsShown() then
      self:OpenTabEditor()
    end
  end
end

function BaganatorGuildViewMixin:UpdateForGuild(guild, isLive)
  guild = guild or ""

  local guildWidth = Baganator.Config.Get(Baganator.Config.Options.GUILD_VIEW_WIDTH)

  self.isLive = isLive

  self.GuildCached:SetShown(not self.isLive)
  self.GuildLive:SetShown(self.isLive)

  local guildData = BAGANATOR_DATA.Guilds[guild]
  if not guildData then
    self:SetTitle("")
    return
  else
    self.lastGuild = guild
    self:SetTitle(BAGANATOR_L_XS_GUILD_BANK:format(guildData.details.guild))
  end

  if self.isLive then
    if self.currentTab ~= GetCurrentGuildBankTab() then
      self.currentTab = GetCurrentGuildBankTab()
      if GuildBankPopupFrame:IsShown() then
        self:OpenTabEditor()
      end
    end
  end
  self:UpdateTabs()

  local active

  if not self.isLive then
    self.GuildCached:ShowGuild(guild, self.currentTab, guildWidth)
    active = self.GuildCached
  else
    self.GuildLive:ShowGuild(guild, self.currentTab, guildWidth)
    active = self.GuildLive
  end

  local searchText = self.SearchBox:GetText()

  self:ApplySearch(searchText)

  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("BOTTOMLEFT", active, "TOPLEFT", 5, 3)
  -- 300 is the default searchbox width
  self.SearchBox:SetWidth(math.min(300, active:GetWidth() - 5))

  self.Tabs[1]:SetPoint("LEFT", active, "LEFT")

  local sideSpacing = 13
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
  end

  local detailsHeight = 0
  if self.isLive then
    local _, _, _, canDeposit, _, remainingWithdrawals = GetGuildBankTabInfo(self.currentTab)
    local depositText = canDeposit and GREEN_FONT_COLOR:WrapTextInColorCode(YES) or RED_FONT_COLOR:WrapTextInColorCode(NO)
    local withdrawText
    if remainingWithdrawals == -1 then
      withdrawText = GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_UNLIMITED)
    elseif remainingWithdrawals == 0 then
      withdrawText = RED_FONT_COLOR:WrapTextInColorCode(NO)
    else
      withdrawText = FormatLargeNumber(remainingWithdrawals)
    end
    self.WithdrawalsInfo:SetText(BAGANATOR_L_GUILD_WITHDRAW_DEPOSIT_X_X:format(withdrawText, depositText))
    local withdrawMoney = GetGuildBankWithdrawMoney()
    if not CanWithdrawGuildBankMoney() then
      withdrawMoney = 0
    end
    local guildMoney = GetGuildBankMoney()
    self.Money:SetText(BAGANATOR_L_GUILD_MONEY_X_X:format(GetMoneyString(math.min(withdrawMoney, guildMoney), true), GetMoneyString(guildMoney, true)))
    detailsHeight = 30

    self.TransferButton:SetShown(remainingWithdrawals == -1 or remainingWithdrawals > 0)
  else
    self.WithdrawalsInfo:SetText("")
    self.Money:SetText(BAGANATOR_L_GUILD_MONEY_X:format(GetMoneyString(BAGANATOR_DATA.Guilds[guild].money, true)))
    detailsHeight = 10

    self.TransferButton:Hide()
  end

  active:ClearAllPoints()
  active:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset, -50)

  local height = active:GetHeight() + 6
  self:SetSize(
    active:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset,
    height + 60 + detailsHeight
  )

  self:UpdateAllButtons()
end

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

function BaganatorGuildViewMixin:UpdateAllButtons()
  local parent = self
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_BUTTONS_ON_ALT) and not IsAltKeyDown() then
    parent = hiddenParent
  end
  for _, button in ipairs(self.AllButtons) do
    button:SetParent(parent)
    button:SetFrameLevel(700)
  end
end

function BaganatorGuildViewMixin:RemoveSearchMatches(callback)
  local matches = self.GuildLive.SearchMonitor:GetMatches()

  local emptyBagSlots = Baganator.Transfers.GetEmptyBagsSlots(BAGANATOR_DATA.Characters[Baganator.BagCache.currentCharacter].bags, Baganator.Constants.AllBagIndexes)

  local status, modes = Baganator.Transfers.FromGuildToBags(matches, Baganator.Constants.AllBagIndexes, emptyBagSlots)

  self.transferManager:Apply(status, modes or {"GuildCacheUpdate"}, function()
    self:RemoveSearchMatches(callback)
  end, function()
    callback()
  end)
end

function BaganatorGuildViewMixin:Transfer(button)
  if self.SearchBox:GetText() == "" then
    StaticPopup_Show(self.confirmTransferAllDialogName)
  else
    self:RemoveSearchMatches(function() end)
  end
end
