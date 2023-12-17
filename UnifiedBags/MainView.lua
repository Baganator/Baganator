local classicTabObjectCounter = 0

BaganatorMainViewMixin = {}

function BaganatorMainViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  if Baganator.Constants.IsClassic then
    self.BagLive:PreallocateButtons(Baganator.Constants.MaxBagSize * 6) -- bags and keyring
  else
    self.BagLive:PreallocateButtons(Baganator.Constants.MaxBagSize * 5) -- bags and backpack
    self.ReagentBagLive:PreallocateButtons(Baganator.Constants.MaxBagSize) -- reagent bag only
  end

  self.sortManager = CreateFrame("Frame", nil, self)

  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })

  self.blizzardBankOpen = false
  self.viewBankShown = false

  if Baganator.Constants.IsRetail then
    self.tabsPool = CreateFramePool("Button", self, "BaganatorRetailTabButtonTemplate")
  else
    self.tabsPool = CreateObjectPool(function(pool)
      classicTabObjectCounter = classicTabObjectCounter + 1
      return CreateFrame("Button", "BGRMainViewTabButton" .. classicTabObjectCounter, self, "BaganatorClassicTabButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end

  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
  end)
  self.SearchBox.clearButton:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end)

  Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsShown() then
      self:UpdateForCharacter(character, true, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate",  function(_, character)
    if self:IsShown() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    self.settingChanged = true
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
    elseif settingName == Baganator.Config.Options.SHOW_RECENTS_TABS then
      local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
      for _, tab in ipairs(self.Tabs) do
        tab:SetShown(isShown)
      end
    elseif settingName == Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    self:AddNewRecent(character)
    self:UpdateForCharacter(character, self.liveCharacter == character)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self.tabsSetup = false
    if self.lastCharacter == character then
      self:UpdateForCharacter(self.liveCharacter, true)
    else
      self:UpdateForCharacter(self.lastCharacter, true)
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
    if self:IsShown() then
      self:UpdateCurrencies(self.lastCharacter)
    end
  end)
end

function BaganatorMainViewMixin:OnShow()
  if Baganator.Config.Get(Baganator.Config.Options.AUTO_SORT_ON_OPEN) then
    C_Timer.After(0, function()
      self:CombineStacksAndSort()
    end)
  end

  PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
end

function BaganatorMainViewMixin:OnHide()
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Baganator.UnifiedBags.Search.ClearCache()
  self.CharacterSelect:Hide()
  Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self.sortManager)

  PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
end

function BaganatorMainViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsShown() then
    return
  end

  if self.isLive then
    self.BagLive:ApplySearch(text)
    self.ReagentBagLive:ApplySearch(text)
  else
    self.BagCached:ApplySearch(text)
    self.ReagentBagCached:ApplySearch(text)
  end

  if self.BankLive:IsShown() then
    self.BankLive:ApplySearch(text)
    self.ReagentBankLive:ApplySearch(text)
  elseif self.BankCached:IsShown() then
    self.BankCached:ApplySearch(text)
    self.ReagentBankCached:ApplySearch(text)
  end
end

function BaganatorMainViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorMainViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self.blizzardBankOpen = true
    if self:IsVisible() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, true)
    end
  elseif eventName == "BANKFRAME_CLOSED" then
    self.blizzardBankOpen = false
    if self:IsVisible() and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, true)
    end
  end
end

function BaganatorMainViewMixin:CreateBagSlots()
  local function GetBagSlotButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBagSlotButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBagSlotButtonTemplate")
    end
  end

  self.liveBagSlots = {}
  for index = 1, Baganator.Constants.BagSlotsCount do
    local bb = GetBagSlotButton()
    table.insert(self.liveBagSlots, bb)
    bb:SetID(index)
    if #self.liveBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.ToggleBankButton, "LEFT", 2, 0)
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
  for index = 1, Baganator.Constants.BagSlotsCount do
    local bb = GetCachedBagSlotButton()
    bb.isBag = true
    table.insert(self.cachedBagSlots, bb)
    bb:SetID(index)
    bb:HookScript("OnEnter", function(self)
      Baganator.CallbackRegistry:TriggerEvent("HighlightBagItems", self:GetID())
    end)
    bb:HookScript("OnLeave", function(self)
      Baganator.CallbackRegistry:TriggerEvent("ClearHighlightBag")
    end)
    if #self.cachedBagSlots == 1 then
      bb:SetPoint("BOTTOM", self, "TOP")
      bb:SetPoint("LEFT", self.SearchBox, "LEFT", -15, 0)
    else
      bb:SetPoint("TOPLEFT", self.cachedBagSlots[#self.cachedBagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorMainViewMixin:UpdateBagSlots()
  -- Show live back slots if viewing live bags
  local show = self.isLive and Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.liveBagSlots) do
    bb:Init()
    bb:SetShown(show)
  end

  -- Show cached bag slots when viewing cached bags for other characters
  local containerInfo = BAGANATOR_DATA.Characters[self.lastCharacter].containerInfo
  if not self.isLive and containerInfo then
    local show = Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
    for index, bb in ipairs(self.cachedBagSlots) do
      local details = CopyTable(containerInfo.bags[index])
      details.itemCount = Baganator.Utilities.CountEmptySlots(BAGANATOR_DATA.Characters[self.lastCharacter].bags[index + 1])
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

function BaganatorMainViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorMainViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_POSITION, {point, x, y})
end

function BaganatorMainViewMixin:ToggleBank()
  self.viewBankShown = not self.viewBankShown
  self:UpdateForCharacter(self.lastCharacter, self.isLive)
end

function BaganatorMainViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorMainViewMixin:ToggleCharacterSidebar()
  self.CharacterSelect:SetShown(not self.CharacterSelect:IsShown())
end

function BaganatorMainViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS))
end


function BaganatorMainViewMixin:SelectTab(character)
  for index, tab in ipairs(self.Tabs) do
    if tab.details.character == character then
      PanelTemplates_SetTab(self, index)
      break
    end
  end
end

local function DeDuplicateRecents()
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local newRecents = {}
  local seen = {}
  for _, char in ipairs(recents) do
    if BAGANATOR_DATA.Characters[char.character] and not seen[char.character] and #newRecents < Baganator.Constants.MaxRecents then
      table.insert(newRecents, char)
    end
    seen[char.character] = true
  end
  Baganator.Config.Set(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW, newRecents)
end

function BaganatorMainViewMixin:FillRecents(characters)
  local characters = {}
  for char, data in pairs(BAGANATOR_DATA.Characters) do
    if char ~= self.liveCharacter  then
      table.insert(characters, {character = char, nameOnly = data.details.character})
    end
  end

  table.sort(characters, function(a, b) return a.character < b.character end)
  for char, data in pairs(BAGANATOR_DATA.Characters) do
    if char == self.liveCharacter  then
      table.insert(characters, 1, {character = char, nameOnly = data.details.character})
    end
  end

  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  table.insert(recents, 1, characters[1])
  for _, char in ipairs(characters) do
    table.insert(recents, char)
  end

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorMainViewMixin:AddNewRecent(character)
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local data = BAGANATOR_DATA.Characters[character]
  if not data then
    return
  end
  local char = {
    character = character,
    nameOnly = data.details.character,
  }
  table.insert(recents, 2, char)

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorMainViewMixin:RefreshTabs()
  self.tabsPool:ReleaseAll()

  local characters = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)

  local lastTab
  local tabs = {}
  for index, char in ipairs(characters) do
    local tabButton = self.tabsPool:Acquire()
    tabButton:SetText(char.nameOnly)
    tabButton:SetScript("OnClick", function()
      Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", char.character)
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
  self.Tabs = tabs

  PanelTemplates_SetNumTabs(self, #characters)
end

function BaganatorMainViewMixin:SetupTabs()
  if self.tabsSetup then
    return
  end

  self:FillRecents(characters)

  self.tabsSetup = self.liveCharacter ~= nil
end

function BaganatorMainViewMixin:HideExtraTabs()
  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(isShown and tab:GetRight() < self:GetRight())
  end
end

function BaganatorMainViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  self.ReagentBagLive:MarkBagsPending("bags", updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)
  self.ReagentBankLive:MarkBagsPending("bank", updatedBags)

  -- Update cached views with current items when bank closed or on login
  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
    self.ReagentBagCached:MarkBagsPending("bags", updatedBags)
    self.BankCached:MarkBagsPending("bank", updatedBags)
    self.ReagentBankCached:MarkBagsPending("bank", updatedBags)
  end
end

function BaganatorMainViewMixin:UpdateForCharacter(character, isLive, updatedBags)
  updatedBags = updatedBags or {bags = {}, bank = {}}
  Baganator.Utilities.ApplyVisuals(self)
  self:SetupTabs()
  self:SelectTab(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  self.isLive = isLive

  self:UpdateBagSlots()

  if oldLast ~= character then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  local characterData = BAGANATOR_DATA.Characters[character]
  if not characterData then
    self:SetTitle("")
  elseif self.viewBankShown then
    self:SetTitle(BAGANATOR_L_XS_BANK_AND_BAGS:format(characterData.details.character))
  else
    self:SetTitle(BAGANATOR_L_XS_BAGS:format(characterData.details.character))
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton() and isLive)

  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BagLive:SetShown(isLive)
  self.ReagentBagLive:SetShown(isLive and showReagents)
  self.BagCached:SetShown(not isLive)
  self.ReagentBagCached:SetShown(not isLive and showReagents)

  self.BankLive:SetShown(self.viewBankShown and (isLive and self.blizzardBankOpen))
  self.ReagentBankLive:SetShown(self.viewBankShown and showReagents and (isLive and self.blizzardBankOpen))
  self.BankCached:SetShown(self.viewBankShown and (not isLive or not self.blizzardBankOpen))
  self.ReagentBankCached:SetShown(self.viewBankShown and showReagents and (not isLive or not self.blizzardBankOpen))

  self:NotifyBagUpdate(updatedBags)

  local searchText = self.SearchBox:GetText()

  local bagIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true
  }
  -- Works on retail for the reagent bag and on classic for the keyring
  local reagentBagIndexesToUse = {
    [6] = true
  }

  local bankIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true
  }
  local reagentBankIndexesToUse = {}
  if Baganator.Constants.IsRetail and (not isLive or IsReagentBankUnlocked()) then
    reagentBankIndexesToUse = {
      [9] = true
    }
  end

  local activeBag, activeReagentBag, activeBank, activeReagentBank

  if self.BagLive:IsShown() then
    activeBag = self.BagLive
    activeReagentBag = self.ReagentBagLive
  else
    activeBag = self.BagCached
    activeReagentBag = self.ReagentBagCached
  end

  if self.BankLive:IsShown() then
    activeBank = self.BankLive
    activeReagentBank = self.ReagentBankLive
  elseif self.BankCached:IsShown() then
    activeBank = self.BankCached
    activeReagentBank = self.ReagentBankCached
  end

  local bagWidth = Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH)

  activeBag:ShowCharacter(character, "bags", Baganator.Constants.AllBagIndexes, bagIndexesToUse, bagWidth)
  activeBag:ApplySearch(searchText)

  activeReagentBag:ShowCharacter(character, "bags", Baganator.Constants.AllBagIndexes, reagentBagIndexesToUse, bagWidth)
  activeReagentBag:ApplySearch(searchText)

  local sideSpacing = 13
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
  end

  local bagHeight = activeBag:GetHeight() + 6
  if activeReagentBag:GetHeight() > 0 then
    if showReagents then
      bagHeight = bagHeight + activeReagentBag:GetHeight() + 14
    else
      bagHeight = bagHeight
    end
  else
    activeReagentBag:Hide()
  end

  local height = bagHeight

  if activeBank then
    local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)

    activeBank:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, bankIndexesToUse, bankWidth)
    activeReagentBank:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, reagentBankIndexesToUse, bankWidth)
    activeBank:ApplySearch(searchText)
    activeReagentBank:ApplySearch(searchText)

    local bankHeight = activeBank:GetHeight() + 6
    if activeReagentBank:GetHeight() > 0 then
      if showReagents then
        bankHeight = bankHeight + activeReagentBank:GetHeight() + 14
      else
        bankHeight = bankHeight
      end
    else
      activeReagentBank:Hide()
    end
    height = math.max(bankHeight, height)
    activeBank:SetPoint("TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset, - (height - bankHeight)/2 - 50)
  end
  self.BankMissingHint:SetShown(self.viewBankShown and #activeBank.buttons == 0)
  if self.BankMissingHint:IsShown() then
    self.BankMissingHint:SetText(BAGANATOR_L_BANK_DATA_MISSING_HINT:format(characterData.details.character))
  end

  self.Tabs[1]:SetPoint("LEFT", activeBag, "LEFT")

  activeBag:SetPoint("TOPRIGHT", -sideSpacing, - (height - bagHeight)/2 - 50)

  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", -sideSpacing, 0)
  self.SearchBox:SetPoint("BOTTOMLEFT", activeBag, "TOPLEFT", 5, 3)
  self.ToggleBankButton:ClearAllPoints()
  self.ToggleBankButton:SetPoint("TOP")
  self.ToggleBankButton:SetPoint("LEFT", activeBag, -sideSpacing, 0)
  self:SetSize(
    activeBag:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset + (activeBank and (activeBank:GetWidth() + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset) or 0),
    height + 74
  )

  self:HideExtraTabs()

  self.ToggleReagentsButton:SetShown(activeReagentBag:GetHeight() > 0 or activeReagentBag:IsShown())
  if self.ToggleReagentsButton:IsShown() then
    self.ToggleReagentsButton:ClearAllPoints()
    self.ToggleReagentsButton:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
    self.ToggleReagentsButton:SetPoint("LEFT", activeBag, -2, -2)
  end
  self.ToggleReagentsBankButton:SetShown(activeReagentBank and activeReagentBank:GetHeight() > 0)
  if self.ToggleReagentsBankButton:IsShown() then
    self.ToggleReagentsBankButton:ClearAllPoints()
    self.ToggleReagentsBankButton:SetPoint("LEFT", activeBank, "LEFT", -2, -4)
    self.ToggleReagentsBankButton:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
  end

  self:UpdateCurrencies(character)
end

function BaganatorMainViewMixin:UpdateCurrencies(character)
  self.Money:SetText(GetMoneyString(BAGANATOR_DATA.Characters[character].money, true))

  local characterCurrencies = BAGANATOR_DATA.Characters[character].currencies

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
          Baganator.Tooltips.AddCurrencyLines(GameTooltip, currencyID)
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

function BaganatorMainViewMixin:CombineStacks(callback)
  local bagsToSort = {}
  for index, bagID in ipairs(Baganator.Constants.AllBagIndexes) do
    bagsToSort[index] = true
  end

  Baganator.Sorting.CombineStacks(BAGANATOR_DATA.Characters[self.liveCharacter].bags, Baganator.Constants.AllBagIndexes, bagsToSort, function(check)
    if not check then
      Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self.sortManager)
      callback()
    else
      Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
        self:CombineStacks(callback)
      end, self.sortManager)
    end
  end)
end

function BaganatorMainViewMixin:DoSort(isReverse)
  local bagsToSort = {}
  for index, bagID in ipairs(Baganator.Constants.AllBagIndexes) do
    bagsToSort[index] = true
  end
  local bagChecks = {}
  if Baganator.Constants.IsRetail then
    bagChecks[Enum.BagIndex.ReagentBag] = function(item)
      return item.itemLink and (select(17, GetItemInfo(item.itemLink)))
    end
  elseif Baganator.Constants.IsWrath then
    bagChecks[Enum.BagIndex.Keyring] = function(item)
      return item.classID == Enum.ItemClass.Key
    end
  end

  for index = 1, Baganator.Constants.BagSlotsCount do
    local _, family = C_Container.GetContainerNumFreeSlots(index)
    if family ~= nil and family ~= 0 then
      bagChecks[index] = function(item)
        local itemFamily = item.itemLink and GetItemFamily(item.itemLink)
        return itemFamily and item.classID ~= Enum.ItemClass.Container and item.classID ~= Enum.ItemClass.Quiver and bit.band(itemFamily, family) ~= 0
      end
    end
  end
  local function DoSortInternal()
    local goAgain = Baganator.Sorting.ApplyOrdering(
      BAGANATOR_DATA.Characters[self.liveCharacter].bags,
      Baganator.Constants.AllBagIndexes,
      bagsToSort,
      bagChecks,
      isReverse,
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      Baganator.Config.Get(Baganator.Config.Options.SORT_IGNORE_SLOTS_COUNT)
    )
    if not goAgain then
      Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self.sortManager)
    else
      Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
        DoSortInternal()
      end, self.sortManager)
    end
  end
  DoSortInternal()
end

function BaganatorMainViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)

  if sortMethod == "blizzard" then
    Baganator.Sorting.BlizzardBagSort(isReverse)
  elseif sortMethod == "sortbags" then
    Baganator.Sorting.ExternalSortBags(isReverse)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end
