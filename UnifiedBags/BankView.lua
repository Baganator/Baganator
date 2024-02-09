BaganatorBankOnlyViewMixin = {}
function BaganatorBankOnlyViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.unallocatedItemButtonPool = Baganator.UnifiedBags.GetLiveItemButtonPool(self)
  self.CollapsingBagSectionsPool = Baganator.UnifiedBags.GetCollapsingBagSectionsPool(self)
  self.CollapsingBankBags = {}

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
    elseif settingName == Baganator.Config.Options.SHOW_BUTTONS_ON_ALT then
      self:UpdateAllButtons()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.liveCharacter ~= nil then
      self:UpdateForCharacter(self.liveCharacter)
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
  for _, layouts in ipairs(self.CollapsingBankBags) do
    layouts.live:ApplySearch(text)
  end
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
  elseif eventName == "MODIFIER_STATE_CHANGED" then
    self:UpdateAllButtons()
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
  self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function BaganatorBankOnlyViewMixin:OnHide(eventName)
  CloseBankFrame()

  self:UnregisterEvent("MODIFIER_STATE_CHANGED")
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Baganator.UnifiedBags.Search.ClearCache()
end

function BaganatorBankOnlyViewMixin:AllocateBankBags(character)
  -- Copied from UnifiedBags/MainView.lua
  local newDetails = Baganator.UnifiedBags.GetCollapsingBagDetails(character, "bank", Baganator.Constants.AllBankIndexes, Baganator.Constants.BankBagSlotsCount)
  if self.lastBankBagDetails == nil or not tCompare(self.lastBankBagDetails, newDetails, 5) then
    self.CollapsingBankBags = Baganator.UnifiedBags.AllocateCollapsingSections(
      character, "bank", Baganator.Constants.AllBankIndexes,
      newDetails, self.CollapsingBankBags,
      self.CollapsingBagSectionsPool, self.unallocatedItemButtonPool,
      function() self:UpdateForCharacter(self.liveCharacter, self.isLive) end)
    self.lastBankBagDetails = newDetails
  end
end

function BaganatorBankOnlyViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorBankOnlyViewMixin:UpdateForCharacter(character, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}
  Baganator.Utilities.ApplyVisuals(self)

  self:AllocateBankBags(character)
  self:UpdateBagSlots()

  for _, layouts in ipairs(self.CollapsingBankBags) do
    layouts.live:Show()
    layouts.cached:Hide()
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton())
  self:UpdateTransferButton()

  self:NotifyBagUpdate(updatedBags)

  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

  self.BankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, self.lastBankBagDetails.mainIndexesToUse, bankWidth)

  local activeBankBagCollapsibles = {}
  for _, layouts in ipairs(self.CollapsingBankBags) do
    table.insert(activeBankBagCollapsibles, layouts.live)
  end

  for index, layout in ipairs(activeBankBagCollapsibles) do
    layout:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, self.CollapsingBankBags[index].indexesToUse, bankWidth)
  end

  local searchText = self.SearchBox:GetText()

  self:ApplySearch(searchText)

  self.DepositIntoReagentsBankButton:SetShown(Baganator.Constants.IsRetail and IsReagentBankUnlocked())
  self.BuyReagentBankButton:SetShown(Baganator.Constants.IsRetail and not IsReagentBankUnlocked())

  -- Copied from UnifiedBags/MainView.lua
  local sideSpacing, topSpacing, dividerOffset, endPadding = 13, 14, 2, 0
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
    dividerOffset = 1
    endPadding = 3
  end

  local bankHeight = self.BankLive:GetHeight() + topSpacing / 2

  -- Copied from UnifiedBags/MainView.lua
  local function ArrangeCollapsibles(activeCollapsibles, originBag, originCollapsibles)
    local lastCollapsible
    local addedHeight = 0
    for index, layout in ipairs(activeCollapsibles) do
      local key = originCollapsibles[index].key
      local hidden = Baganator.Config.Get(Baganator.Config.Options.HIDE_SPECIAL_CONTAINER)[key]
      local divider = originCollapsibles[index].divider
      if hidden then
        divider:Hide()
        layout:Hide()
      else
        divider:SetPoint("BOTTOM", layout, "TOP", 0, topSpacing / 2 + dividerOffset)
        divider:SetPoint("LEFT", layout)
        divider:SetPoint("RIGHT", layout)
        divider:SetShown(layout:GetHeight() > 0)
        if layout:GetHeight() > 0 then
          addedHeight = addedHeight + layout:GetHeight() + topSpacing
          if lastCollapsible == nil then
            layout:SetPoint("TOP", originBag, "BOTTOM", 0, -topSpacing)
          else
            layout:SetPoint("TOP", lastCollapsible, "BOTTOM", 0, -topSpacing)
          end
          lastCollapsible = layout
        end
      end
    end
    return addedHeight + endPadding
  end

  bankHeight = bankHeight + ArrangeCollapsibles(activeBankBagCollapsibles, self.BankLive, self.CollapsingBankBags)

  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.AllFixedButtons)
  tAppendAll(self.AllButtons, self.TopButtons)

  local anyButtonsOnBottom = false

  local lastButton = nil
  for index, layout in ipairs(activeBankBagCollapsibles) do
    local button = self.CollapsingBankBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    if button:IsShown() then
      anyButtonsOnBottom = true
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", self.BankLive, -2, 0)
      end
      table.insert(self.AllButtons, button)
      lastButton = button
    end
  end

  if self.BuyReagentBankButton:IsShown() then
    anyButtonsOnBottom = true
    table.insert(self.AllButtons, self.BuyReagentBankButton)
  end
  if self.DepositIntoReagentsBankButton:IsShown() then
    anyButtonsOnBottom = true
    table.insert(self.AllButtons, self.DepositIntoReagentsBankButton)
    self.DepositIntoReagentsBankButton:ClearAllPoints()
    self.DepositIntoReagentsBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
  end

  if anyButtonsOnBottom then
    bankHeight = bankHeight + 20
  end

  self:UpdateAllButtons()

  local characterData = BAGANATOR_DATA.Characters[character]
  if not characterData then
    self:SetTitle("")
  else
    self:SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end

  self.BankLive:ClearAllPoints()
  self.BankLive:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset - 2, -50)

  self:SetSize(
    self.BankLive:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    bankHeight + 54
  )
  -- 300 is the default searchbox width
  self.SearchBox:SetWidth(math.min(300, self.BankLive:GetWidth() - 5))
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

function BaganatorBankOnlyViewMixin:UpdateAllButtons()
  if not self.AllButtons then
    return
  end

  local parent = self
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_BUTTONS_ON_ALT) and not IsAltKeyDown() then
    parent = hiddenParent
  end
  for _, button in ipairs(self.AllButtons) do
    button:SetParent(parent)
    button:SetFrameLevel(700)
  end
end

function BaganatorBankOnlyViewMixin:NotifyBagUpdate(updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)

  for _, bagGroup in ipairs(self.CollapsingBankBags) do
    bagGroup.live:MarkBagsPending("bank", updatedBags)
  end
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
  tAppendAll(matches, self.BankLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBankBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end

  local emptyBagSlots = Baganator.Transfers.GetEmptySlots(BAGANATOR_DATA.Characters[self.liveCharacter].bags, Baganator.Constants.AllBagIndexes)
  local combinedIDs = CopyTable(Baganator.Constants.AllBagIndexes)
  tAppendAll(combinedIDs, Baganator.Constants.AllBankIndexes)

  local status = Baganator.Transfers.MoveBetweenBags(combinedIDs, matches, emptyBagSlots)

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
