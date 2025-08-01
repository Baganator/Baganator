---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorItemViewCommonBankViewMixin = {}

function BaganatorItemViewCommonBankViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  self:SetUserPlaced(false)

  self.Anchor = addonTable.ItemViewCommon.GetAnchorSetter(self, addonTable.Config.Options.BANK_ONLY_VIEW_POSITION)

  self.tabPool = addonTable.ItemViewCommon.GetTabButtonPool(self)

  self.Tabs = {}

  if self.characterTabsTemplate and Syndicator.Constants.CharacterBankTabsActive then
    self.Character = CreateFrame("Frame", nil, self, self.characterTabsTemplate)
    self.Character:SetPoint("TOPLEFT")
  else
    self.Character = CreateFrame("Frame", nil, self, self.characterTemplate)
    self.Character:SetPoint("TOPLEFT")
  end
  self:InitializeWarband(self.warbandTemplate)

  self.currentTab = self.Character
  if addonTable.Config.Get(addonTable.Config.Options.BANK_CURRENT_TAB) == addonTable.Constants.BankTabType.Warband then
    self:SetTab(addonTable.Constants.BankTabType.Warband)
  end

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function()
    self.hasCharacter = true
  end)

  self:UpdateTransferButton()

  addonTable.Skins.AddFrame("ButtonFrame", self, {"bank"})
end

function BaganatorItemViewCommonBankViewMixin:SetTab(index)
  self.currentTab:Hide()
  addonTable.Config.Set(addonTable.Config.Options.BANK_CURRENT_TAB, index)

  if index == addonTable.Constants.BankTabType.Character then
    self.currentTab = self.Character
  elseif index == addonTable.Constants.BankTabType.Warband then
    self.currentTab = self.Warband
  end

  self.currentTab:Show()

  if self:IsVisible() then
    PanelTemplates_SetTab(self, index)
    addonTable.Config.Set(addonTable.Config.Options.BANK_CURRENT_TAB, index)
    self:UpdateView()
    addonTable.CallbackRegistry:TriggerEvent("BankViewChanged")
  end
end

function BaganatorItemViewCommonBankViewMixin:InitializeWarband(template)
  if Syndicator.Constants.WarbandBankActive then
    self.Warband = CreateFrame("Frame", nil, self, template)
    self.Warband:Hide()
    self.Warband:SetPoint("TOPLEFT")

    local characterTab = self.tabPool:Acquire()
    addonTable.Skins.AddFrame("TabButton", characterTab)
    characterTab:SetText(addonTable.Locales.CHARACTER)
    characterTab:Show()
    characterTab:SetScript("OnClick", function()
      self:SetTab(1)
    end)

    local warbandTab = self.tabPool:Acquire()
    warbandTab:SetText(addonTable.Locales.WARBAND)
    warbandTab:Show()
    warbandTab:SetScript("OnClick", function()
      self:SetTab(2)
    end)
    addonTable.Skins.AddFrame("TabButton", warbandTab)

    self.Tabs[1]:SetPoint("BOTTOM", 0, -30)
    PanelTemplates_SetNumTabs(self, #self.Tabs)
  end
end

function BaganatorItemViewCommonBankViewMixin:UpdateTransferButton()
  if not self.currentTab.isLive or self.currentTab.isLocked then
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

function BaganatorItemViewCommonBankViewMixin:IsTransferActive()
  return self.TransferButton:IsShown()
end

function BaganatorItemViewCommonBankViewMixin:OnDragStart()
  if not addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorItemViewCommonBankViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local oldCorner = addonTable.Config.Get(addonTable.Config.Options.BANK_ONLY_VIEW_POSITION)[1]
  addonTable.Config.Set(addonTable.Config.Options.BANK_ONLY_VIEW_POSITION, {addonTable.Utilities.ConvertAnchorToCorner(oldCorner, self)})
end

function BaganatorItemViewCommonBankViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self:Show()
    self.liveBankActive = true
    if self.hasCharacter then
      self.Character:ResetToLive()
      self:UpdateView()
    end
  elseif eventName == "BANKFRAME_CLOSED" then
    self.liveBankActive = false
    self:Hide()
  end
end

function BaganatorItemViewCommonBankViewMixin:OnShow()
  if Syndicator.Constants.CharacterBankTabsActive then
    BankFrame.BankPanel:Show()
  end

  if Syndicator.Constants.WarbandBankActive then
    if C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.AccountBanker) then
      self:SetTab(2)
      for _, tab in ipairs(self.Tabs) do
        tab:Hide()
      end
    else
      for _, tab in ipairs(self.Tabs) do
        tab:Show()
      end
    end
  end
  if self.Tabs[1] then
    local function Select()
      if self.currentTab == self.Character then
        PanelTemplates_SelectTab(self.Tabs[1])
      elseif self.currentTab == self.Warband then
        PanelTemplates_SelectTab(self.Tabs[2])
      end
    end
    Select()
    C_Timer.After(0, Select) -- Necessary because if the tabs were only shown this frame they won't select properly
  end
end

function BaganatorItemViewCommonBankViewMixin:OnHide()
  if C_Bank then
    C_Bank.CloseBankFrame()
  else
    CloseBankFrame()
  end

  if Syndicator.Constants.CharacterBankTabsActive then
    BankFrame.BankPanel:Hide()
  end

  addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
end

function BaganatorItemViewCommonBankViewMixin:UpdateViewToCharacter(characterName)
  addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", characterName)
  if not self.Character:IsShown() then
    self.Tabs[1]:Click()
  else
    self:UpdateView()
  end
end

function BaganatorItemViewCommonBankViewMixin:UpdateViewToWarband(_, tabIndex)
  self.Warband:SetCurrentTab(tabIndex)
  if not self.Warband:IsShown() then
    self.Tabs[2]:Click()
  else
    self:UpdateView()
  end
end

function BaganatorItemViewCommonBankViewMixin:UpdateView()
  addonTable.ReportEntry()

  self.start = debugprofilestop()

  if Syndicator.Constants.WarbandBankActive and not C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.AccountBanker) then
    self.Tabs[1]:Show()
  end

  local sideSpacing = addonTable.Utilities.GetSpacing()

  if self.Tabs[1] then
    self.Tabs[1]:SetPoint("LEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset, 0)
  end

  self.SearchWidget:SetSpacing(sideSpacing)

  self.currentTab:UpdateView()

  addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
end


function BaganatorItemViewCommonBankViewMixin:OnTabFinished()
  self.SortButton:SetShown(self.currentTab.isLive and not self.currentTab.isLocked and addonTable.Utilities.ShouldShowSortButton())
  self:UpdateTransferButton()

  self.ButtonVisibility:Update()

  self:SetSize(self.currentTab:GetSize())

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    addonTable.Utilities.DebugOutput("bank", debugprofilestop() - self.start)
  end
end

function BaganatorItemViewCommonBankViewMixin:Transfer()
  if self.SearchWidget.SearchBox:GetText() == "" then
    addonTable.Dialogs.ShowConfirm(addonTable.Locales.CONFIRM_TRANSFER_ALL_ITEMS_FROM_BANK, YES, NO, function()
      self.currentTab:RemoveSearchMatches(function() end)
    end)
  else
    self.currentTab:RemoveSearchMatches()
  end
end

function BaganatorItemViewCommonBankViewMixin:GetExternalSortMethodName()
  return addonTable.Utilities.GetExternalSortMethodName()
end
