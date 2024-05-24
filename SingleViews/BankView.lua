BaganatorSingleViewBankViewMixin = {}

function BaganatorSingleViewBankViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.currentTab = self.Character

  self.tabPool = Baganator.ItemViewCommon.GetTabButtonPool(self)

  self.Tabs = {}

  if Syndicator.Constants.WarbandBankActive then
    self.Warband = CreateFrame("Frame", nil, self, "BaganatorSingleViewBankViewWarbandViewTemplate")
    self.Warband:Hide()
    self.Warband:SetPoint("TOPLEFT")

    local characterTab = self.tabPool:Acquire()
    characterTab:SetText(BAGANATOR_L_CHARACTER)
    characterTab:Show()
    characterTab:SetScript("OnClick", function()
      self.currentTab:Hide()
      self.currentTab = self.Character
      self.currentTab:Show()
      PanelTemplates_SetTab(self, 1)
      self:UpdateView()
    end)

    local warbandTab = self.tabPool:Acquire()
    warbandTab:SetText(BAGANATOR_L_WARBAND)
    warbandTab:Show()
    warbandTab:SetScript("OnClick", function()
      self.currentTab:Hide()
      self.currentTab = self.Warband
      self.currentTab:Show()
      PanelTemplates_SetTab(self, 2)
      self:UpdateView()
    end)

    self.Tabs[1]:SetPoint("BOTTOM", 0, -30)
    PanelTemplates_SetNumTabs(self, #self.Tabs)
  end


  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self.hasCharacter = true
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(Baganator.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsShown() then
        Baganator.Utilities.ApplyVisuals(self)
      end
    end
  end)

  self.confirmTransferAllDialogName = "Baganator.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_BANK,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self.currentTab:RemoveSearchMatches(function() end)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }
  self:UpdateTransferButton()
end

function BaganatorSingleViewBankViewMixin:UpdateTransferButton()
  if not self.currentTab.isLive then
    self.TransferButton:Hide()
    return
  end

  self.TransferButton:ClearAllPoints()
  if self.SortButton:IsShown() then
    self.TransferButton:SetPoint("RIGHT", self.SortButton, "LEFT")
  else
    self.TransferButton:SetPoint("RIGHT", self.CustomiseButton, "LEFT")
  end

  if not Baganator.Config.Get(Baganator.Config.Options.SHOW_TRANSFER_BUTTON) then
    self.TransferButton:Hide()
    return
  end
  self.TransferButton:Show()
end

function BaganatorSingleViewBankViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorSingleViewBankViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION, {point, x, y})
end

function BaganatorSingleViewBankViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self:Show()
    self.liveBankActive = true
    if self.hasCharacter then
      self.currentTab:ResetToLive()
      self:UpdateView()
    end
  elseif eventName == "BANKFRAME_CLOSED" then
    self.liveBankActive = false
    self:Hide()
  end
end

function BaganatorSingleViewBankViewMixin:OnShow()
  if self.Tabs[1] then
    if self.currentTab == self.Character then
      PanelTemplates_SelectTab(self.Tabs[1])
    elseif self.currentTab == self.Warband then
      PanelTemplates_SelectTab(self.Tabs[2])
    end
  end
end

function BaganatorSingleViewBankViewMixin:OnHide(eventName)
  if C_Bank then
    C_Bank.CloseBankFrame()
  else
    CloseBankFrame()
  end

  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
end

function BaganatorSingleViewBankViewMixin:UpdateViewToCharacter(characterName)
  self.Character.lastCharacter = characterName
  if not self.Character:IsShown() then
    self.Tabs[1]:Click()
  else
    self:UpdateView()
  end
end

function BaganatorSingleViewBankViewMixin:UpdateViewToWarband(warbandIndex, tabIndex)
  self.Warband:SetCurrentTab(tabIndex)
  if not self.Warband:IsShown() then
    self.Tabs[2]:Click()
  else
    self:UpdateView()
  end
end

function BaganatorSingleViewBankViewMixin:UpdateView()
  Baganator.Utilities.ApplyVisuals(self)

  -- Copied from SingleViews/BagView.lua
  local sideSpacing = 13
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
  end

  if self.Tabs[1] then
    self.Tabs[1]:SetPoint("LEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset, 0)
  end

  self.SearchWidget:SetSpacing(sideSpacing)

  self.currentTab:UpdateView()

  self.SortButton:SetShown(self.currentTab.isLive and Baganator.Utilities.ShouldShowSortButton())
  self:UpdateTransferButton()

  self.ButtonVisibility:Update()

  self:SetSize(self.currentTab:GetSize())
end

function BaganatorSingleViewBankViewMixin:Transfer(button)
  if self.SearchWidget.SearchBox:GetText() == "" then
    StaticPopup_Show(self.confirmTransferAllDialogName)
  else
    self.currentTab:RemoveSearchMatches(function() end)
  end
end
