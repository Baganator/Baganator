BaganatorBankOnlyViewMixin = {}
function BaganatorBankOnlyViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "PLAYERBANKBAGSLOTS_CHANGED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
  })

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

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

  Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsShown() then
      self:UpdateForCharacter(character, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.liveCharacter then
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
        self:UpdateForCharacter(self.liveCharacter)
      end
    elseif settingName == Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.liveCharacter ~= nil then
      self:UpdateForCharacter(self.liveCharacter)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  local function GetBankBagButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBankButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBankButtonTemplate")
    end
  end

  self.bankBagSlots = {}
  for index = 1, Baganator.Constants.BankBagSlotsCount do
    local bb = GetBankBagButton()
    table.insert(self.bankBagSlots, bb)
    bb:SetID(index)
    if #self.bankBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.SearchBox, "LEFT", -12, 0)
    else
      bb:SetPoint("TOPLEFT", self.bankBagSlots[#self.bankBagSlots - 1], "TOPRIGHT")
    end
  end

  self.confirmTransferAllDialogName = "Baganator.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_BANK,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self:RemoveSearchMatches(function() end)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }
  self:UpdateTransferButton()
end

function BaganatorBankOnlyViewMixin:UpdateTransferButton()
  if not Baganator.Config.Get(Baganator.Config.Options.SHOW_TRANSFER_BUTTON) then
    self.TransferButton:Hide()
    return
  end
  self.TransferButton:Show()
  self.TransferButton:ClearAllPoints()
  if self.SortButton:IsShown() then
    self.TransferButton:SetPoint("RIGHT", self.SortButton, "LEFT")
  else
    self.TransferButton:SetPoint("RIGHT", self.CustomiseButton, "LEFT")
  end
end

function BaganatorBankOnlyViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorBankOnlyViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION, {point, x, y})
end

function BaganatorBankOnlyViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorBankOnlyViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
end

function BaganatorBankOnlyViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsShown() then
    return
  end

  self.BankLive:ApplySearch(text)
  self.ReagentBankLive:ApplySearch(text)
end

function BaganatorBankOnlyViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self:Show()
    if self.liveCharacter then
      self:UpdateForCharacter(self.liveCharacter)
    end
  elseif eventName == "BANKFRAME_CLOSED" then
    self:Hide()
  elseif eventName == "PLAYERBANKBAGSLOTS_CHANGED" then
    if self:IsVisible() then
      self:UpdateBagSlots()
    end
  elseif eventName == "PLAYER_REGEN_DISABLED" then
    if not self.liveBagSlots then
      return
    end
    -- Disable bank bag slots buttons in combat as pickup/drop doesn't work
    for _, button in ipairs(self.liveBagSlots) do
      SetItemButtonDesaturated(button, true)
      button:Disable()
    end
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    if not self.liveBagSlots then
      return
    end
    for _, button in ipairs(self.liveBagSlots) do
      SetItemButtonDesaturated(button, false)
      button:Enable()
    end
  end
end

function BaganatorBankOnlyViewMixin:UpdateBagSlots()
  local show = Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.bankBagSlots) do
    bb:Init()
    bb:SetShown(show)
  end
end

function BaganatorBankOnlyViewMixin:OnShow()
  self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
end

function BaganatorBankOnlyViewMixin:OnHide(eventName)
  CloseBankFrame()

  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Baganator.UnifiedBags.Search.ClearCache()
end

function BaganatorBankOnlyViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorBankOnlyViewMixin:UpdateForCharacter(character, updatedBags)
  self:UpdateBagSlots()

  updatedBags = updatedBags or {bags = {}, bank = {}}

  Baganator.Utilities.ApplyVisuals(self)

  local searchText = self.SearchBox:GetText()

  local bankIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true
  }
  local reagentBankIndexesToUse = {}
  if Baganator.Constants.IsRetail and IsReagentBankUnlocked() then
    reagentBankIndexesToUse = {
      [9] = true
    }
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton())
  self:UpdateTransferButton()

  self:NotifyBagUpdate(updatedBags)

  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)
  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, bankIndexesToUse, bankWidth)
  self.BankLive:ApplySearch(searchText)

  self.ReagentBankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, reagentBankIndexesToUse, bankWidth)
  self.ReagentBankLive:ApplySearch(searchText)

  self.ReagentBankLive:SetShown(self.ReagentBankLive:GetHeight() > 0 and showReagents)

  self.ToggleReagentsBankButton:SetShown(self.ReagentBankLive:GetHeight() > 0)
  self.DepositIntoReagentsBankButton:SetShown(self.ReagentBankLive:GetHeight() > 0)
  self.BuyReagentBankButton:SetShown(Baganator.Constants.IsRetail and not IsReagentBankUnlocked())
  local reagentBankHeight = self.ReagentBankLive:GetHeight()
  if reagentBankHeight > 0 then
    if self.ReagentBankLive:IsShown() then
      reagentBankHeight = reagentBankHeight + 34
    else
      reagentBankHeight = 20
    end
  elseif self.BuyReagentBankButton:IsShown() then
    reagentBankHeight = 20
  end

  local sideSpacing = 13
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
  end

  self.BankLive:ClearAllPoints()
  self.BankLive:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset - 2, -50)

  self:SetSize(
    self.BankLive:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    self.BankLive:GetHeight() + reagentBankHeight + 60
  )
  -- 300 is the default searchbox width
  self.SearchBox:SetWidth(math.min(300, self.BankLive:GetWidth() - 5))

  local characterData = BAGANATOR_DATA.Characters[character]
  if not characterData then
    self:SetTitle("")
  else
    self:SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end
end

function BaganatorBankOnlyViewMixin:NotifyBagUpdate(updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)
  self.ReagentBankLive:MarkBagsPending("bank", updatedBags)
end

function BaganatorBankOnlyViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(BAGANATOR_DATA.Characters[self.liveCharacter].bank, Baganator.Constants.AllBankIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorBankOnlyViewMixin:DoSort(isReverse)
  local indexesToUse = {}
  for index in ipairs(Baganator.Constants.AllBankIndexes) do
    indexesToUse[index] = true
  end
  -- Ignore reagent bank if it isn't purchased
  if Baganator.Constants.IsRetail and not IsReagentBankUnlocked() then
    indexesToUse[tIndexOf(Baganator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)] = nil
  end
  local bagChecks = Baganator.Sorting.GetBagUsageChecks(Baganator.Constants.AllBankIndexes)

  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyOrdering(
      BAGANATOR_DATA.Characters[self.liveCharacter].bank,
      Baganator.Constants.AllBankIndexes,
      indexesToUse,
      bagChecks,
      isReverse
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end

  DoSortInternal()
end

function BaganatorBankOnlyViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if sortMethod == "blizzard" then
    Baganator.Sorting.BlizzardBankSort(isReverse)
  elseif sortMethod == "sortbags" then
    Baganator.Sorting.ExternalSortBagsBank(isReverse)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorBankOnlyViewMixin:RemoveSearchMatches(callback)
  local matches = {}
  for _, layout in ipairs({self.BankLive, self.ReagentBankLive}) do
    tAppendAll(matches, layout.SearchMonitor:GetMatches())
  end
  local emptyBagSlots = Baganator.Sorting.GetEmptySlots(BAGANATOR_DATA.Characters[self.liveCharacter].bags, Baganator.Constants.AllBagIndexes)
  local combinedIDs = CopyTable(Baganator.Constants.AllBagIndexes)
  tAppendAll(combinedIDs, Baganator.Constants.AllBankIndexes)

  local status = Baganator.Sorting.Transfer(combinedIDs, matches, emptyBagSlots)

  self.transferManager:Apply(status, function()
    self:RemoveSearchMatches(callback)
  end, function()
    callback()
  end)
end

function BaganatorBankOnlyViewMixin:Transfer(button)
  if self.SearchBox:GetText() == "" then
    StaticPopup_Show(self.confirmTransferAllDialogName)
  else
    self:RemoveSearchMatches(function() end)
  end
end
