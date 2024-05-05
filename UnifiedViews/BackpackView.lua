local addonName, addonTable = ...

local classicTabObjectCounter = 0

BaganatorBackpackViewMixin = {}

local function PreallocateItemButtons(pool, buttonCount)
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    for i = 1, buttonCount do
      pool:Acquire()
    end
    pool:ReleaseAll()
  end)
end

function BaganatorBackpackViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  self.liveItemButtonPool = Baganator.UnifiedViews.GetLiveItemButtonPool(self)
  self.unallocatedItemButtonPool = Baganator.UnifiedViews.GetLiveItemButtonPool(self)
  self.BagLive:SetPool(self.liveItemButtonPool)
  self.CollapsingBagSectionsPool = Baganator.UnifiedViews.GetCollapsingBagSectionsPool(self)
  self.CollapsingBags = {}
  self.bagDetailsForComparison = {}

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  -- 6 is bags + reagent bag (retail) or bags + keyring (wrath)
  PreallocateItemButtons(self.liveItemButtonPool, Syndicator.Constants.MaxBagSize * 6)

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
  })

  self.tabsPool = Baganator.UnifiedViews.GetTabButtonPool(self)

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
    if self:IsVisible() then
      self:UpdateForCharacter(character, true, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
    end
  end)

  Syndicator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate",  function(_, character)
    if self:IsVisible() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
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
      if self:IsVisible() then
        Baganator.Utilities.ApplyVisuals(self)
      end
    elseif tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == Baganator.Config.Options.SHOW_RECENTS_TABS then
      local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
      for index, tab in ipairs(self.Tabs) do
        tab:SetShown(isShown)
        if tab.details == self.lastCharacter then
          PanelTemplates_SetTab(self, index)
        end
      end
    elseif settingName == Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    elseif settingName == Baganator.Config.Options.SHOW_BUTTONS_ON_ALT then
      self:UpdateAllButtons()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if character ~= self.lastCharacter then
      self:AddNewRecent(character)
      self:UpdateForCharacter(character, self.liveCharacter == character)
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

  local frame = CreateFrame("Frame")
  local function UpdateMoneyDisplay()
    if IsShiftKeyDown() then
      Baganator.ShowGoldSummaryAccount(self.Money, "ANCHOR_TOP")
    else
      Baganator.ShowGoldSummaryRealm(self.Money, "ANCHOR_TOP")
    end
  end
  self.Money:SetScript("OnEnter", function()
    UpdateMoneyDisplay()
    frame:RegisterEvent("MODIFIER_STATE_CHANGED")
    frame:SetScript("OnEvent", UpdateMoneyDisplay)
  end)

  self.Money:SetScript("OnLeave", function()
    frame:UnregisterEvent("MODIFIER_STATE_CHANGED")
    GameTooltip:Hide()
  end)

  self:CreateBagSlots()

  -- Update currencies when they are watched/unwatched in Blizz UI
  EventRegistry:RegisterCallback("TokenFrame.OnTokenWatchChanged", function()
    if self:IsVisible() then
      self:UpdateCurrencies(self.lastCharacter)
    end
  end)

  -- Needed to get currencies to load correctly on classic versions of WoW
  Baganator.Utilities.OnAddonLoaded("Blizzard_TokenUI", function()
    if self:IsVisible() then
      self:UpdateCurrencies(self.lastCharacter)
    end

    -- Wrath Classic
    if ManageBackpackTokenFrame then
      hooksecurefunc("ManageBackpackTokenFrame", function()
        if self:IsVisible() then
          self:UpdateCurrencies(self.lastCharacter)
        end
      end)
    end
  end)

  self.confirmTransferAllDialogName = "Baganator.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_BAG,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self:Transfer(true)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  addonTable.BagTransferActivationCallback = function()
    self:UpdateTransferButton()
  end

  if Baganator.Constants.IsEra or not Baganator.Config.Get(Baganator.Config.Options.SHOW_GUILD_BANK_BUTTON) then
    local index = tIndexOf(self.TopButtons, self.ToggleGuildBankButton)
    table.remove(self.TopButtons, index)
    self.ToggleGuildBankButton:Hide()
  end

  for index = 2, #self.TopButtons do
    local button = self.TopButtons[index]
    button:SetPoint("TOPLEFT", self.TopButtons[index-1], "TOPRIGHT")
  end
end

function BaganatorBackpackViewMixin:OnShow()
  if Baganator.Config.Get(Baganator.Config.Options.AUTO_SORT_ON_OPEN) then
    C_Timer.After(0, function()
      self:CombineStacksAndSort()
    end)
  end
  self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
  self:RegisterEvent("MODIFIER_STATE_CHANGED")

  PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
end

function BaganatorBackpackViewMixin:OnHide()
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Syndicator.Search.ClearCache()
  self:UnregisterEvent("MODIFIER_STATE_CHANGED")

  PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
end

function BaganatorBackpackViewMixin:AllocateBags(character)
  local newDetails = Baganator.UnifiedViews.GetCollapsingBagDetails(character, "bags", Syndicator.Constants.AllBagIndexes, Syndicator.Constants.BagSlotsCount)
  if self.bagDetailsForComparison.bags == nil or not tCompare(self.bagDetailsForComparison.bags, newDetails, 15) then
    self.bagDetailsForComparison.bags = CopyTable(newDetails)
    self.CollapsingBags = Baganator.UnifiedViews.AllocateCollapsingSections(
      character, "bags", Syndicator.Constants.AllBagIndexes,
      newDetails, self.CollapsingBags,
      self.CollapsingBagSectionsPool, self.liveItemButtonPool)
    self.lastBagDetails = newDetails
  end
end

function BaganatorBackpackViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)
  self.GlobalSearchButton:SetEnabled(text ~= "")

  if not self:IsVisible() then
    return
  end

  if self.isLive then
    self.BagLive:ApplySearch(text)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.live:ApplySearch(text)
    end
  else
    self.BagCached:ApplySearch(text)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:ApplySearch(text)
    end
  end
end

function BaganatorBackpackViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorBackpackViewMixin:OnEvent(eventName)
  if eventName == "PLAYER_REGEN_DISABLED" then
    -- Disable bag bag slots buttons in combat as pickup/drop doesn't work then
    if not self.liveBagSlots then
      return
    end
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

function BaganatorBackpackViewMixin:CreateBagSlots()
  local function GetBagSlotButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBagSlotButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBagSlotButtonTemplate")
    end
  end

  self.liveBagSlots = {}
  for index = 1, Syndicator.Constants.BagSlotsCount do
    local bb = GetBagSlotButton()
    table.insert(self.liveBagSlots, bb)
    bb:SetID(index)
    if #self.liveBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.SearchBox, "LEFT", -12, 0)
    else
      bb:SetPoint("TOPLEFT", self.liveBagSlots[#self.liveBagSlots - 1], "TOPRIGHT")
    end
  end

  local cachedBagSlotCounter = 0
  local function GetCachedBagSlotButton()
    -- Use cached item buttons from cached layout views
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailCachedItemButtonTemplate")
    else
      cachedBagSlotCounter = cachedBagSlotCounter + 1
      return CreateFrame("Button", "BGRCachedBagSlotItemButton" .. cachedBagSlotCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end
  end

  self.cachedBagSlots = {}
  for index = 1, Syndicator.Constants.BagSlotsCount do
    local bb = GetCachedBagSlotButton()
    bb:UpdateTextures()
    bb.isBag = true
    table.insert(self.cachedBagSlots, bb)
    bb:SetID(index)
    bb:HookScript("OnEnter", function(self)
      Baganator.CallbackRegistry:TriggerEvent("HighlightBagItems", {[self:GetID()] = true})
    end)
    bb:HookScript("OnLeave", function(self)
      Baganator.CallbackRegistry:TriggerEvent("ClearHighlightBag")
    end)
    if #self.cachedBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.SearchBox, "LEFT", -12, 0)
    else
      bb:SetPoint("TOPLEFT", self.cachedBagSlots[#self.cachedBagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorBackpackViewMixin:UpdateBagSlots()
  -- Show live back slots if viewing live bags
  local show = self.isLive and Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.liveBagSlots) do
    bb:Init()
    bb:SetShown(show)
  end

  -- Show cached bag slots when viewing cached bags for other characters
  local containerInfo = Syndicator.API.GetCharacter(self.lastCharacter).containerInfo
  if not self.isLive and containerInfo then
    local show = Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
    for index, bb in ipairs(self.cachedBagSlots) do
      local details = CopyTable(containerInfo.bags[index] or {})
      details.itemCount = Baganator.Utilities.CountEmptySlots(Syndicator.API.GetCharacter(self.lastCharacter).bags[index + 1])
      bb:SetItemDetails(details)
      if not details.iconTexture and not Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND) then
        local _, texture = GetInventorySlotInfo("Bag1")
        SetItemButtonTexture(bb, texture)
      end
      bb:SetShown(show)
    end
  else
    for _, bb in ipairs(self.cachedBagSlots) do
      bb:Hide()
    end
  end

  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bags))
end

function BaganatorBackpackViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorBackpackViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_POSITION, {point, x, y})
end

function BaganatorBackpackViewMixin:ToggleBank()
  Baganator.CallbackRegistry:TriggerEvent("BankToggle", self.lastCharacter)
  self:Raise()
end

function BaganatorBackpackViewMixin:ToggleGuildBank()
  Baganator.CallbackRegistry:TriggerEvent("GuildToggle", Syndicator.API.GetCharacter(self.lastCharacter).details.guild)
end

function BaganatorBackpackViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorBackpackViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS))
end


function BaganatorBackpackViewMixin:SelectTab(character)
  for index, tab in ipairs(self.Tabs) do
    if tab.details == character then
      PanelTemplates_SetTab(self, index)
      break
    end
  end
end

local function DeDuplicateRecents()
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local newRecents = {}
  local seen = {}
  for _, character in ipairs(recents) do
    if Syndicator.API.GetCharacter(character) and not seen[character] and #newRecents < Baganator.Constants.MaxRecents then
      table.insert(newRecents, character)
    end
    seen[character] = true
  end
  Baganator.Config.Set(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW, newRecents)
end

function BaganatorBackpackViewMixin:FillRecents(characters)
  local characters = Syndicator.API.GetAllCharacters()

  table.sort(characters, function(a, b) return a < b end)

  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  table.insert(recents, 1, self.liveCharacter)

  for _, char in ipairs(characters) do
    table.insert(recents, char)
  end

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorBackpackViewMixin:AddNewRecent(character)
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local data = Syndicator.API.GetCharacter(character)
  if not data then
    return
  end

  table.insert(recents, 2, character)

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorBackpackViewMixin:RefreshTabs()
  self.tabsPool:ReleaseAll()

  local characters = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  local sameConnected = {}
  for _, realmNormalized in ipairs(Syndicator.Utilities.GetConnectedRealms()) do
    sameConnected[realmNormalized] = true
  end

  local lastTab
  local tabs = {}
  local index = 1
  while #tabs < Baganator.Constants.MaxRecentsTabs and index <= #characters do
    local char = characters[index]
    local details = Syndicator.API.GetCharacter(char).details
    if sameConnected[details.realmNormalized] then
      local tabButton = self.tabsPool:Acquire()
      tabButton:SetText(details.character)
      tabButton:SetScript("OnClick", function()
        Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", char)
      end)
      if not lastTab then
        tabButton:SetPoint("BOTTOM", 0, -30)
      else
        tabButton:SetPoint("TOPLEFT", lastTab, "TOPRIGHT")
      end
      tabButton.details = char
      tabButton:SetID(index)
      tabButton:SetShown(isShown)
      lastTab = tabButton
      table.insert(tabs, tabButton)
    end
    index = index + 1
  end
  self.Tabs = tabs

  PanelTemplates_SetNumTabs(self, #tabs)
end

function BaganatorBackpackViewMixin:SetupTabs()
  if self.tabsSetup then
    return
  end

  self:FillRecents(characters)

  self.tabsSetup = self.liveCharacter ~= nil
end

function BaganatorBackpackViewMixin:HideExtraTabs()
  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(isShown and tab:GetRight() < self:GetRight())
  end
end

function BaganatorBackpackViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  for _, bagGroup in ipairs(self.CollapsingBags) do
    bagGroup.live:MarkBagsPending("bags", updatedBags)
  end

  -- Update cached views with current items when live or on login
  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:MarkBagsPending("bags", updatedBags)
    end
  end
end

function BaganatorBackpackViewMixin:UpdateForCharacter(character, isLive, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}
  Baganator.Utilities.ApplyVisuals(self)
  self:SetupTabs()
  self:SelectTab(character)
  self:AllocateBags(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  self.isLive = isLive

  self:UpdateBagSlots()

  if oldLast ~= character then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  local characterData = Syndicator.API.GetCharacter(character)

  if not characterData then
    self:SetTitle("")
  else
    self:SetTitle(BAGANATOR_L_XS_BAGS:format(characterData.details.character))
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton() and isLive)
  self:UpdateTransferButton()

  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BagLive:SetShown(isLive)
  self.BagCached:SetShown(not isLive)

  for _, layouts in ipairs(self.CollapsingBags) do
    layouts.live:SetShown(isLive)
    layouts.cached:SetShown(not isLive)
  end

  self:NotifyBagUpdate(updatedBags)

  local searchText = self.SearchBox:GetText()

  local activeBag, activeBagCollapsibles = nil, {}

  if self.BagLive:IsShown() then
    activeBag = self.BagLive
    for _, layouts in ipairs(self.CollapsingBags) do
      table.insert(activeBagCollapsibles, layouts.live)
    end
  else
    activeBag = self.BagCached
    for _, layouts in ipairs(self.CollapsingBags) do
      table.insert(activeBagCollapsibles, layouts.cached)
    end
  end

  local bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)

  activeBag:ShowCharacter(character, "bags", Syndicator.Constants.AllBagIndexes, self.lastBagDetails.mainIndexesToUse, bagWidth)

  for index, layout in ipairs(activeBagCollapsibles) do
    layout:ShowCharacter(character, "bags", Syndicator.Constants.AllBagIndexes, self.CollapsingBags[index].indexesToUse, bagWidth)
  end

  self:ApplySearch(searchText)

  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  local bagHeight = activeBag:GetHeight() + topSpacing / 2

  bagHeight = bagHeight + Baganator.UnifiedViews.ArrangeCollapsibles(activeBagCollapsibles, activeBag, self.CollapsingBags)
  local height = bagHeight

  self.Tabs[1]:SetPoint("LEFT", activeBag, "LEFT")

  activeBag:SetPoint("TOPRIGHT", -sideSpacing, - (height - bagHeight)/2 - 50)

  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", -sideSpacing - 36, 0)
  self.SearchBox:SetPoint("BOTTOMLEFT", activeBag, "TOPLEFT", 5, 3)
  self.GlobalSearchButton:ClearAllPoints()
  self.GlobalSearchButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 3, 0)
  self.TopButtons[1]:ClearAllPoints()
  self.TopButtons[1]:SetPoint("TOP", self)
  self.TopButtons[1]:SetPoint("LEFT", activeBag, -sideSpacing + 2, 0)

  -- Used to change the alignment of the title based on the current layout
  local titleOffset = Baganator.Constants.IsClassic and 60 or 0
  local titleText = _G[self:GetName() .. "TitleText"]

  self:SetSize(
    activeBag:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2,
    height + 74
  )

  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.AllFixedButtons)
  tAppendAll(self.AllButtons, self.TopButtons)

  self:HideExtraTabs()

  local lastButton = nil
  for index, layout in ipairs(activeBagCollapsibles) do
    local button = self.CollapsingBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    button:ClearAllPoints()
    if button:IsShown() then
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBag, -2, 0)
      end
      lastButton = button
      table.insert(self.AllButtons, button)
    end
  end

  self:UpdateAllButtons()

  self:UpdateCurrencies(character)
end

function BaganatorBackpackViewMixin:UpdateCurrencies(character)
  self.Money:SetText(Baganator.Utilities.GetMoneyString(Syndicator.API.GetCharacter(character).money, true))

  local characterCurrencies = Syndicator.API.GetCharacter(character).currencies

  if not C_CurrencyInfo then
    return
  end

  if not characterCurrencies then
    for _, c in ipairs(self.Currencies) do
      c:SetText("")
    end
    return
  end

  for i = 1, Baganator.Constants.MaxPinnedCurrencies do
    local currencyID, icon
    if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
      local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
      if currencyInfo then
        currencyID = currencyInfo.currencyTypesID
        icon = currencyInfo.iconFileID
      end
    elseif GetBackpackCurrencyInfo then
      icon, currencyID = select(3, GetBackpackCurrencyInfo(i))
    end

    local currencyText = ""

    if currencyID ~= nil then
      local count = 0
      if characterCurrencies[currencyID] ~= nil then
        count = characterCurrencies[currencyID]
      end

      currencyText = BreakUpLargeNumbers(count)
      if strlenutf8(currencyText) > 5 then
        currencyText = AbbreviateNumbers(count)
      end
      currencyText = currencyText .. " " .. CreateSimpleTextureMarkup(icon, 12, 12)
      if GameTooltip.SetCurrencyByID then
        -- Show retail currency tooltip
        self.Currencies[i]:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetCurrencyByID(currencyID)
        end)
      else
        -- SetCurrencyByID doesn't exist on classic, but we want to show the
        -- other characters info via the tooltip anyway
        self.Currencies[i]:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          Syndicator.Tooltips.AddCurrencyLines(GameTooltip, currencyID)
        end)
      end
      self.Currencies[i]:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    else
      self.Currencies[i]:SetScript("OnEnter", nil)
    end
    self.Currencies[i]:SetText(currencyText)
  end
end

function BaganatorBackpackViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorBackpackViewMixin:UpdateTransferButton()
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

  for _, info in ipairs(addonTable.BagTransfers) do
    if info.condition() then
      self.TransferButton:Show()
      self.TransferButton.tooltipText = info.tooltipText
      return
    end
  end
  self.TransferButton:Hide()
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

function BaganatorBackpackViewMixin:UpdateAllButtons()
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
  local guildName = Syndicator.API.GetCharacter(self.lastCharacter).details.guild
  self.ToggleGuildBankButton:SetEnabled(guildName ~= nil and Syndicator.API.GetGuild(guildName))
end

function BaganatorBackpackViewMixin:GetMatches()
  local matches = {}
  tAppendAll(matches, self.BagLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorBackpackViewMixin:RunAction(action)
  action(self:GetMatches(), self.liveCharacter, function(status, modes)
    self.transferManager:Apply(status, modes or {"BagCacheUpdate"}, function()
      self:RunAction(action)
    end, function()
    end)
  end)
end

function BaganatorBackpackViewMixin:Transfer(force)
  for _, transferDetails in ipairs(addonTable.BagTransfers) do
    if transferDetails.condition() then
      if not force and transferDetails.confirmOnAll and self.SearchBox:GetText() == "" then
        StaticPopup_Show(self.confirmTransferAllDialogName)
        break
      else
        self:RunAction(transferDetails.action)
        break
      end
    end
  end
end

function BaganatorBackpackViewMixin:DoSort(isReverse)
  local bagsToSort = {}
  for index, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    bagsToSort[index] = true
  end
  local bagChecks = Baganator.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBagIndexes)
  local function DoSortInternal()
    local status = Baganator.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self.liveCharacter).bags,
      Syndicator.Constants.AllBagIndexes,
      bagsToSort,
      bagChecks,
      isReverse,
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end
  DoSortInternal()
end

function BaganatorBackpackViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if not Baganator.Sorting.IsModeAvailable(sortMethod) then
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  if addonTable.ExternalContainerSorts[sortMethod] then
    addonTable.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Backpack)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end
