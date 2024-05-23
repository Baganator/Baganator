local _, addonTable = ...

BaganatorSingleViewBankViewCharacterViewMixin = {}

function BaganatorSingleViewBankViewCharacterViewMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYERBANKBAGSLOTS_CHANGED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
  })

  self.unallocatedItemButtonPool = Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  self.CollapsingBagSectionsPool = Baganator.SingleViews.GetCollapsingBagSectionsPool(self)
  self.CollapsingBankBags = {}
  self.bagDetailsForComparison = {}

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self:NotifyBagUpdate(updatedBags)
    if character == self.liveCharacter and self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self.tabsSetup = false
    if self.lastCharacter == character then
      self.lastCharacter = self.liveCharacter
    end
    self:GetParent():UpdateView()
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
      return
    end
    if tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    elseif settingName == Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if self:IsVisible() and character ~= self.lastCharacter then
      self.lastCharacter = character
      self:GetParent():UpdateView()
    end
  end)

  self:CreateBagSlots()
end

function BaganatorSingleViewBankViewCharacterViewMixin:OnHide()
  for _, button in ipairs(self.TopButtons) do
    button:SetParent(self)
  end
  for _, button in ipairs(self.LiveButtons) do
    button:SetParent(self)
  end
  for index, details in ipairs(self.CollapsingBankBags) do
    details.button:SetParent(self)
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:OnEvent()
  if eventName == "PLAYERBANKBAGSLOTS_CHANGED" then
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
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:CreateBagSlots()
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
      bb:SetPoint("BOTTOMLEFT", self.ToggleAllCharacters, "TOPLEFT", 4, 0)
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
      bb:SetPoint("BOTTOMLEFT", self.ToggleAllCharacters, "TOPLEFT", 3, 0)
    else
      bb:SetPoint("TOPLEFT", self.cachedBankBagSlots[#self.cachedBankBagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
end

function BaganatorSingleViewBankViewCharacterViewMixin:UpdateBagSlots()
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
    self.cachedBankBagSlots[1]:SetPoint("BOTTOMLEFT", self.ToggleAllCharacters, "TOPLEFT")
  else
    for _, bb in ipairs(self.cachedBankBagSlots) do
      bb:Hide()
    end
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:ApplySearch(text)
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

function BaganatorSingleViewBankViewCharacterViewMixin:AllocateBankBags(character)
  -- Copied from SingleViews/BagView.lua
  local newDetails = Baganator.SingleViews.GetCollapsingBagDetails(character, "bank", Syndicator.Constants.AllBankIndexes, Syndicator.Constants.BankBagSlotsCount)
  if self.bagDetailsForComparison.bank == nil or not tCompare(self.bagDetailsForComparison.bank, newDetails, 15) then
    self.bagDetailsForComparison.bank = CopyTable(newDetails)
    self.CollapsingBankBags = Baganator.SingleViews.AllocateCollapsingSections(
      character, "bank", Syndicator.Constants.AllBankIndexes,
      newDetails, self.CollapsingBankBags,
      self.CollapsingBagSectionsPool, self.unallocatedItemButtonPool,
      function() self:UpdateForCharacter(self.lastCharacter, self.isLive) end)
    self.lastBankBagDetails = newDetails
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorSingleViewBankViewCharacterViewMixin:DoSort(isReverse)
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

function BaganatorSingleViewBankViewCharacterViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bank, Syndicator.Constants.AllBankIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorSingleViewBankViewCharacterViewMixin:CombineStacksAndSort(isReverse)
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

function BaganatorSingleViewBankViewCharacterViewMixin:RemoveSearchMatches(callback)
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

function BaganatorSingleViewBankViewCharacterViewMixin:NotifyBagUpdate(updatedBags)
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

function BaganatorSingleViewBankViewCharacterViewMixin:ResetToLive()
  self.lastCharacter = self.liveCharacter
end

function BaganatorSingleViewBankViewCharacterViewMixin:SetupBlizzardFramesForTab()
  if self.isLive and Syndicator.Constants.WarbandBankActive then
    BankFrame.activeTabIndex = Baganator.Constants.BlizzardBankTabConstants.Character
  end
end

function BaganatorSingleViewBankViewCharacterViewMixin:UpdateView()
  self:UpdateForCharacter(self.lastCharacter, self:GetParent().liveBankActive and self.lastCharacter == self.liveCharacter)
end

function BaganatorSingleViewBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
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
    self:GetParent():SetTitle("")
  else
    self:GetParent():SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end

  self.BankMissingHint:SetShown(#activeBank.buttons == 0)
  self:GetParent().SearchWidget:SetShown(#activeBank.buttons ~= 0)

  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  local searchText = self:GetParent().SearchWidget.SearchBox:GetText()

  self:ApplySearch(searchText)

  self.DepositIntoReagentsBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and IsReagentBankUnlocked())
  self.BuyReagentBankButton:SetShown(self.isLive and Baganator.Constants.IsRetail and not IsReagentBankUnlocked())

  -- Copied from SingleViews/BagView.lua
  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  local bankHeight = activeBank:GetHeight() + topSpacing / 2

  -- Copied from SingleViews/BagView.lua
  bankHeight = bankHeight + Baganator.SingleViews.ArrangeCollapsibles(activeBankBagCollapsibles, activeBank, self.CollapsingBankBags)

  self:GetParent().AllButtons = {}
  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.TopButtons)

  local lastButton = nil
  for index, layout in ipairs(activeBankBagCollapsibles) do
    local button = self.CollapsingBankBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    if button:IsShown() then
      button:ClearAllPoints()
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBank, -2, 0)
      end
      table.insert(self:GetParent().AllButtons, button)
      lastButton = button
    end
  end

  if self.BuyReagentBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.BuyReagentBankButton)
    self.BuyReagentBankButton:ClearAllPoints()
    if lastButton then
      self.BuyReagentBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
    else
      self.BuyReagentBankButton:SetPoint("LEFT", activeBank, -2, 0)
      self.BuyReagentBankButton:SetPoint("BOTTOM", 0, 6)
    end
  end
  if self.DepositIntoReagentsBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.DepositIntoReagentsBankButton)
    self.DepositIntoReagentsBankButton:ClearAllPoints()
    self.DepositIntoReagentsBankButton:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 5, 0)
  end

  bankHeight = bankHeight + 20

  activeBank:ClearAllPoints()
  activeBank:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset - 2, -50)

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end

  self:SetupBlizzardFramesForTab()

  Baganator.CallbackRegistry:TriggerEvent("ViewComplete")

  self:SetSize(
    activeBank:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    bankHeight + 54
  )
end
