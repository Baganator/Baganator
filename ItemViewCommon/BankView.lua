BaganatorItemViewCommonBankViewMixin = {}

function BaganatorItemViewCommonBankViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  self:SetUserPlaced(false)

  self.tabPool = Baganator.ItemViewCommon.GetTabButtonPool(self)

  self.Tabs = {}

  self.Character = CreateFrame("Frame", nil, self, self.characterTemplate)
  self.Character:SetPoint("TOPLEFT")
  self:InitializeWarband(self.warbandTemplate)

  self.currentTab = self.Character

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

  Baganator.Skins.AddFrame("ButtonFrame", self, {"bank"})
end

function BaganatorItemViewCommonBankViewMixin:InitializeWarband(template)
  if Syndicator.Constants.WarbandBankActive then
    self.Warband = CreateFrame("Frame", nil, self, template)
    self.Warband:Hide()
    self.Warband:SetPoint("TOPLEFT")

    local characterTab = self.tabPool:Acquire()
    Baganator.Skins.AddFrame("TabButton", characterTab)
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
    Baganator.Skins.AddFrame("TabButton", warbandTab)

    self.Tabs[1]:SetPoint("BOTTOM", 0, -30)
    PanelTemplates_SetNumTabs(self, #self.Tabs)
  end
end

function BaganatorItemViewCommonBankViewMixin:UpdateTransferButton()
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

  self.TransferButton:Show()
end

function BaganatorItemViewCommonBankViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorItemViewCommonBankViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION, {point, x, y})
end

function BaganatorItemViewCommonBankViewMixin:OnEvent(eventName)
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

function BaganatorItemViewCommonBankViewMixin:OnShow()
  if self.Tabs[1] then
    if self.currentTab == self.Character then
      PanelTemplates_SelectTab(self.Tabs[1])
    elseif self.currentTab == self.Warband then
      PanelTemplates_SelectTab(self.Tabs[2])
    end
  end
end

function BaganatorItemViewCommonBankViewMixin:OnHide(eventName)
  if C_Bank then
    C_Bank.CloseBankFrame()
  else
    CloseBankFrame()
  end

  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
end

function BaganatorItemViewCommonBankViewMixin:UpdateViewToCharacter(characterName)
  self.Character.lastCharacter = characterName
  if not self.Character:IsShown() then
    self.Tabs[1]:Click()
  else
    self:UpdateView()
  end
end

function BaganatorItemViewCommonBankViewMixin:UpdateViewToWarband(warbandIndex, tabIndex)
  self.Warband:SetCurrentTab(tabIndex)
  if not self.Warband:IsShown() then
    self.Tabs[2]:Click()
  else
    self:UpdateView()
  end
end

function BaganatorItemViewCommonBankViewMixin:UpdateView()
  self.start = debugprofilestop()

  Baganator.Utilities.ApplyVisuals(self)

  -- Copied from ItemViewCommons/BagView.lua
  local sideSpacing = 13
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
  end

  if self.Tabs[1] then
    self.Tabs[1]:SetPoint("LEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset, 0)
  end

  self.SearchWidget:SetSpacing(sideSpacing)

  self.currentTab:UpdateView()
end


function BaganatorItemViewCommonBankViewMixin:OnTabFinished()
  self.SortButton:SetShown(self.currentTab.isLive and Baganator.Utilities.ShouldShowSortButton())
  self:UpdateTransferButton()

  self.ButtonVisibility:Update()

  self:SetSize(self.currentTab:GetSize())

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("bank", debugprofilestop() - self.start)
  end
end

function BaganatorItemViewCommonBankViewMixin:Transfer()
  if self.SearchWidget.SearchBox:GetText() == "" then
    StaticPopup_Show(self.confirmTransferAllDialogName)
  else
    self.currentTab:RemoveSearchMatches()
  end
end
