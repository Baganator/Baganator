local classicTabObjectCounter = 0

BaganatorMainViewMixin = {}

function BaganatorMainViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

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

  Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsShown() then
      self:UpdateForCharacter(character, true, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
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

  local function GetBagSlotButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBagSlotButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBagSlotButtonTemplate")
    end
  end

  self.bagSlots = {}
  for index = 1, Baganator.Constants.BagSlotsCount do
    local bb = GetBagSlotButton()
    table.insert(self.bagSlots, bb)
    bb:SetID(index)
    if #self.bagSlots == 1 then
      bb:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
    else
      bb:SetPoint("TOPLEFT", self.bagSlots[#self.bagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorMainViewMixin:OnHide()
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Baganator.Search.ClearCache()
  self.CharacterSelect:Hide()
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

function BaganatorMainViewMixin:UpdateBagSlots()
  self.ToggleBagSlotsButton:SetShown(self.isLive)
  local show = self.isLive and Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.bagSlots) do
    bb:Init()
    bb:SetShown(show)
  end
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

local maxRecents = 5
local function DeDuplicateRecents()
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local newRecents = {}
  local seen = {}
  for _, char in ipairs(recents) do
    if not seen[char.character] and #newRecents < Baganator.Constants.MaxRecents then
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
  tabs = {}
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

function BaganatorMainViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  self.ReagentBagLive:MarkBagsPending("bags", updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)
  self.ReagentBankLive:MarkBagsPending("bank", updatedBags)

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
  local reagentBagIndexesToUse = {}
  if Baganator.Constants.IsRetail then
    reagentBagIndexesToUse = {
      [6] = true
    }
  end

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

  local bagHeight = activeBag:GetHeight()
  if activeReagentBag:GetHeight() > 0 then
    if showReagents then
      bagHeight = bagHeight + activeReagentBag:GetHeight() + 40
    else
      bagHeight = bagHeight + 20
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

    local bankHeight = activeBank:GetHeight()
    if activeReagentBank:GetHeight() > 0 then
      if showReagents then
        bankHeight = bankHeight + activeReagentBank:GetHeight() + 40
      else
        bankHeight = bankHeight + 20
      end
    else
      activeReagentBank:Hide()
    end
    height = math.max(bankHeight, height)
    activeBank:SetPoint("TOPLEFT", 13, - (height - bankHeight)/2 - 40)
  end

  self.Tabs[1]:SetPoint("LEFT", activeBag, "LEFT")

  activeBag:SetPoint("TOPRIGHT", -13, - (height - bagHeight)/2 - 50)

  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", -13, 0)
  self.SearchBox:SetPoint("BOTTOMLEFT", activeBag, "TOPLEFT", 5, 3)
  self.ToggleBankButton:ClearAllPoints()
  self.ToggleBankButton:SetPoint("TOP")
  self.ToggleBankButton:SetPoint("LEFT", activeBag, -13, 0)
  self:SetSize(
    activeBag:GetWidth() + 30 + (activeBank and activeBank:GetWidth() + 30 or 0),
    height + 68
  )

  self.ToggleReagentsButton:SetShown(activeReagentBag:GetHeight() > 0 or activeReagentBag:IsShown())
  if self.ToggleReagentsButton:IsShown() then
    self.ToggleReagentsButton:ClearAllPoints()
    self.ToggleReagentsButton:SetPoint("TOPLEFT", activeBag, "BOTTOMLEFT", -2, -5)
  end
  self.ToggleReagentsBankButton:SetShown(activeReagentBank and activeReagentBank:GetHeight() > 0)
  if self.ToggleReagentsBankButton:IsShown() then
    self.ToggleReagentsBankButton:ClearAllPoints()
    self.ToggleReagentsBankButton:SetPoint("TOPLEFT", activeBank, "BOTTOMLEFT", -2, -5)
  end

  self.ToggleAllCharacters:ClearAllPoints()
  self.ToggleAllCharacters:SetPoint("CENTER", activeBag)
  self.ToggleAllCharacters:SetPoint("BOTTOM", 0, 2)

  self.Money:SetText(GetMoneyString(BAGANATOR_DATA.Characters[character].money, true))
end
