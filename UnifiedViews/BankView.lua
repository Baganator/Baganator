BaganatorBankViewMixin = {}

local _, addonTable = ...

function BaganatorBankViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.unallocatedItemButtonPool = Baganator.UnifiedViews.GetLiveItemButtonPool(self)
  self.CollapsingBagSectionsPool = Baganator.UnifiedViews.GetCollapsingBagSectionsPool(self)
  self.CollapsingBankBags = {}
  self.bagDetailsForComparison = {}

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

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if character == self.lastCharacter and self:IsVisible() then
        self:UpdateForCharacter(character, self.liveBankActive, updatedBags)
    end
    self:NotifyBagUpdate(updatedBags)
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
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
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    elseif settingName == Baganator.Config.Options.SHOW_BUTTONS_ON_ALT then
      self:UpdateAllButtons()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if self:IsVisible() and character ~= self.lastCharacter then
      self:UpdateForCharacter(character, self.liveCharacter == character and self.liveBankActive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self.tabsSetup = false
    if self.lastCharacter == character then
      self:UpdateForCharacter(self.liveCharacter, true)
    else
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  self:CreateBagSlots()

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

function BaganatorBankViewMixin:CreateBagSlots()
  local function GetLiveBankBagButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBankButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBankButtonTemplate")
    end
  end

  self.liveBankBagSlots = {}
  for index = 1, Syndicator.Constants.BankBagSlotsCount do
    local bb = GetLiveBankBagButton()
    table.insert(self.liveBankBagSlots, bb)
    bb:SetID(index)
    if #self.liveBankBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.SearchBox, "LEFT", -12, 0)
    else
      bb:SetPoint("TOPLEFT", self.liveBankBagSlots[#self.liveBankBagSlots - 1], "TOPRIGHT")
    end
  end

  local cachedBankBagSlotCounter = 0
  local function GetCachedBankBagSlotButton()
    -- Use cached item buttons from cached layout views
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailCachedItemButtonTemplate")
    else
      cachedBankBagSlotCounter = cachedBankBagSlotCounter + 1
      return CreateFrame("Button", "BGRCachedBankBagSlotItemButton" .. cachedBankBagSlotCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end
  end

  self.cachedBankBagSlots = {}
  for index = 1, Syndicator.Constants.BankBagSlotsCount do
    local bb = GetCachedBankBagSlotButton()
    bb:UpdateTextures()
    bb.isBag = true
    table.insert(self.cachedBankBagSlots, bb)
    bb:SetID(index)
    bb:HookScript("OnEnter", function(self)
      Baganator.CallbackRegistry:TriggerEvent("HighlightBagItems", {[Syndicator.Constants.AllBankIndexes[self:GetID()+1]] = true})
    end)
    bb:HookScript("OnLeave", function(self)
      Baganator.CallbackRegistry:TriggerEvent("ClearHighlightBag")
    end)
    if #self.cachedBankBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.SearchBox, "LEFT", -12, 0)
    else
      bb:SetPoint("TOPLEFT", self.cachedBankBagSlots[#self.cachedBankBagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorBankViewMixin:UpdateTransferButton()
  if not self.isLive then
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

function BaganatorBankViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorBankViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION, {point, x, y})
end

function BaganatorBankViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorBankViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
end

function BaganatorBankViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsVisible() then
    return
  end

  if self.BankLive:IsShown() then
    self.BankLive:ApplySearch(text)
    for _, layouts in ipairs(self.CollapsingBankBags) do
      layouts.live:ApplySearch(text)
    end
  elseif self.BankCached:IsShown() then
    self.BankCached:ApplySearch(text)
    for _, layouts in ipairs(self.CollapsingBankBags) do
      layouts.cached:ApplySearch(text)
    end
  end
end

function BaganatorBankViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self:Show()
    self.liveBankActive = true
    if self.liveCharacter then
      self:UpdateForCharacter(self.liveCharacter, true)
    end
  elseif eventName == "BANKFRAME_CLOSED" then
    self.liveBankActive = false
    self:Hide()
  elseif eventName == "PLAYERBANKBAGSLOTS_CHANGED" then
    if self:IsVisible() then
      self:UpdateBagSlots()
    end
  elseif eventName == "PLAYER_REGEN_DISABLED" then
    if not self.liveBankBagSlots then
      return
    end
    -- Disable bank bag slots buttons in combat as pickup/drop doesn't work
    for _, button in ipairs(self.liveBankBagSlots) do
      SetItemButtonDesaturated(button, true)
      button:Disable()
    end
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    if not self.liveBankBagSlots then
      return
    end
    for _, button in ipairs(self.liveBankBagSlots) do
      SetItemButtonDesaturated(button, false)
      button:Enable()
    end
  elseif eventName == "MODIFIER_STATE_CHANGED" then
    self:UpdateAllButtons()
  end
end

function BaganatorBankViewMixin:UpdateBagSlots()
  local show = self.isLive and Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.liveBankBagSlots) do
    bb:Init()
    bb:SetShown(show)
  end

  -- Show cached bag slots when viewing cached bank bags for other characters
  local containerInfo = Syndicator.API.GetCharacter(self.lastCharacter).containerInfo
  if not self.isLive and containerInfo and containerInfo.bank then
    local show = Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS)
    for index, bb in ipairs(self.cachedBankBagSlots) do
      local details = CopyTable(containerInfo.bank[index] or {})
      details.itemCount = Baganator.Utilities.CountEmptySlots(Syndicator.API.GetCharacter(self.lastCharacter).bank[index + 1])
      bb:SetItemDetails(details)
      if not details.iconTexture and not Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND) then
        local _, texture = GetInventorySlotInfo("Bag1")
        SetItemButtonTexture(bb, texture)
      end
      bb:SetShown(show)
    end
  else
    for _, bb in ipairs(self.cachedBankBagSlots) do
      bb:Hide()
    end
  end
end

function BaganatorBankViewMixin:OnShow()
  self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
  self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function BaganatorBankViewMixin:OnHide(eventName)
  if C_Bank then
    C_Bank.CloseBankFrame()
  else
    CloseBankFrame()
  end

  self:UnregisterEvent("MODIFIER_STATE_CHANGED")
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Syndicator.Search.ClearCache()
end

function BaganatorBankViewMixin:AllocateBankBags(character)
  -- Copied from UnifiedViews/BagView.lua
  local newDetails = Baganator.UnifiedViews.GetCollapsingBagDetails(character, "bank", Syndicator.Constants.AllBankIndexes, Syndicator.Constants.BankBagSlotsCount)
  if self.bagDetailsForComparison.bank == nil or not tCompare(self.bagDetailsForComparison.bank, newDetails, 15) then
    self.bagDetailsForComparison.bank = CopyTable(newDetails)
    self.CollapsingBankBags = Baganator.UnifiedViews.AllocateCollapsingSections(
      character, "bank", Syndicator.Constants.AllBankIndexes,
      newDetails, self.CollapsingBankBags,
      self.CollapsingBagSectionsPool, self.unallocatedItemButtonPool,
      function() self:UpdateForCharacter(self.lastCharacter, self.isLive) end)
    self.lastBankBagDetails = newDetails
  end
end

function BaganatorBankViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorBankViewMixin:UpdateForCharacter(character, isLive, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}
  Baganator.Utilities.ApplyVisuals(self)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  if oldLast ~= self.lastCharacter then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end
  self.isLive = isLive

  self:AllocateBankBags(character)
  self:UpdateBagSlots()

  self.BankLive:SetShown(self.isLive)
  self.BankCached:SetShown(not self.isLive)

  for _, layouts in ipairs(self.CollapsingBankBags) do
    layouts.live:SetShown(self.isLive)
    layouts.cached:SetShown(not self.isLive)
  end

  self.SortButton:SetShown(self.isLive and Baganator.Utilities.ShouldShowSortButton())
  self:UpdateTransferButton()

  self:NotifyBagUpdate(updatedBags)

  local activeBank, activeBankBagCollapsibles = nil, {}

  if self.BankLive:IsShown() then
    activeBank = self.BankLive
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankBagCollapsibles, layouts.live)
    end
  else
    activeBank = self.BankCached
    for _, layouts in ipairs(self.CollapsingBankBags) do
      table.insert(activeBankBagCollapsibles, layouts.cached)
    end
  end

  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

  activeBank:ShowCharacter(character, "bank", Syndicator.Constants.AllBankIndexes, self.lastBankBagDetails.mainIndexesToUse, bankWidth)

  for index, layout in ipairs(activeBankBagCollapsibles) do
    layout:ShowCharacter(character, "bank", Syndicator.Constants.AllBankIndexes, self.CollapsingBankBags[index].indexesToUse, bankWidth)
  end

  local characterData = Syndicator.API.GetCharacter(character)
  if not characterData then
    self:SetTitle("")
  else
    self:SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end

  self.BankMissingHint:SetShown(#activeBank.buttons == 0)
  self.SearchBox:SetShown(#activeBank.buttons ~= 0)

  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  local searchText = self.SearchBox:GetText()

  self:ApplySearch(searchText)

  self.DepositIntoReagentsBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and IsReagentBankUnlocked())
  self.BuyReagentBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and not IsReagentBankUnlocked())

  -- Copied from UnifiedViews/BagView.lua
  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  local bankHeight = activeBank:GetHeight() + topSpacing / 2

  -- Copied from UnifiedViews/BagView.lua
  bankHeight = bankHeight + Baganator.UnifiedViews.ArrangeCollapsibles(activeBankBagCollapsibles, activeBank, self.CollapsingBankBags)

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
      button:ClearAllPoints()
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBank, -2, 0)
      end
      table.insert(self.AllButtons, button)
      lastButton = button
    end
  end

  if self.BuyReagentBankButton:IsShown() then
    anyButtonsOnBottom = true
    table.insert(self.AllButtons, self.BuyReagentBankButton)
    self.BuyReagentBankButton:ClearAllPoints()
    if lastButton then
      self.BuyReagentBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
    else
      self.BuyReagentBankButton:SetPoint("LEFT", activeBank, -2, 0)
      self.BuyReagentBankButton:SetPoint("BOTTOM", 0, 6)
    end
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

  activeBank:ClearAllPoints()
  activeBank:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset - 2, -50)
  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", -sideSpacing, 0, 0)
  self.SearchBox:SetPoint("BOTTOMLEFT", activeBank, "TOPLEFT", 5, 3)

  self:SetSize(
    activeBank:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    bankHeight + 54
  )
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

function BaganatorBankViewMixin:UpdateAllButtons()
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

function BaganatorBankViewMixin:NotifyBagUpdate(updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)

  for _, bagGroup in ipairs(self.CollapsingBankBags) do
    bagGroup.live:MarkBagsPending("bank", updatedBags)
  end

  -- Update cached views with current items when bank closed or on login
  if self.isLive == nil or self.isLive == true then
    for _, bagGroup in ipairs(self.CollapsingBankBags) do
      bagGroup.cached:MarkBagsPending("bank", updatedBags)
    end
    self.BankCached:MarkBagsPending("bank", updatedBags)
  end
end

function BaganatorBankViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bank, Syndicator.Constants.AllBankIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorBankViewMixin:DoSort(isReverse)
  local indexesToUse = {}
  for index in ipairs(Syndicator.Constants.AllBankIndexes) do
    indexesToUse[index] = true
  end
  -- Ignore reagent bank if it isn't purchased
  if Baganator.Constants.IsRetail and not IsReagentBankUnlocked() then
    indexesToUse[tIndexOf(Syndicator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)] = nil
  end
  local bagChecks = Baganator.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBankIndexes)

  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self.liveCharacter).bank,
      Syndicator.Constants.AllBankIndexes,
      indexesToUse,
      bagChecks,
      isReverse,
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end

  DoSortInternal()
end

function BaganatorBankViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if addonTable.ExternalContainerSorts[sortMethod] then
    addonTable.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Bank)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorBankViewMixin:RemoveSearchMatches(callback)
  local matches = {}
  tAppendAll(matches, self.BankLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBankBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end

  local emptyBagSlots = Baganator.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes)

  local status = Baganator.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBagIndexes, emptyBagSlots)

  self.transferManager:Apply(status, {"BagCacheUpdate"}, function()
    self:RemoveSearchMatches(callback)
  end, function()
    callback()
  end)
end

function BaganatorBankViewMixin:Transfer(button)
  if self.SearchBox:GetText() == "" then
    StaticPopup_Show(self.confirmTransferAllDialogName)
  else
    self:RemoveSearchMatches(function() end)
  end
end
