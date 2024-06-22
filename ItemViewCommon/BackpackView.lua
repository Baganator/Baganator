local addonName, addonTable = ...

local classicTabObjectCounter = 0

BaganatorItemViewCommonBackpackViewMixin = {}

local function PreallocateItemButtons(pool, buttonCount)
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    for i = 1, buttonCount do
      local button = pool:Acquire()
      Baganator.Skins.AddFrame("ItemButton", button)
    end
    pool:ReleaseAll()
  end)
end

function BaganatorItemViewCommonBackpackViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  self:SetUserPlaced(false)

  self.liveItemButtonPool = Baganator.ItemViewCommon.GetLiveItemButtonPool(self)

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  -- 6 is bags + reagent bag (retail) or bags + keyring (wrath)
  PreallocateItemButtons(self.liveItemButtonPool, Syndicator.Constants.MaxBagSize * 6)

  Baganator.Utilities.AddBagSortManager(self) -- self.sortManager
  Baganator.Utilities.AddBagTransferManager(self) -- self.transferManager

  self.tabsPool = Baganator.ItemViewCommon.GetTabButtonPool(self)

  Baganator.CallbackRegistry:RegisterCallback("BagCacheAfterNewItemsUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self.searchToApply = true
    self:NotifyBagUpdate(updatedBags)
    if self:IsVisible() then
      self:UpdateForCharacter(character, true)
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
      self.BagSlots:Update(self.lastCharacter, self.isLive)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.searchToApply = true
    self:ApplySearch(text)
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if character ~= self.lastCharacter then
      self:AddNewRecent(character)
      if self:IsVisible() then
        self:UpdateForCharacter(character, self.liveCharacter == character)
      end
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  self.confirmTransferAllDialogName = "Baganator.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_BAG,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self:Transfer(true, self.data)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  if Baganator.Constants.IsEra then
    local index = tIndexOf(self.TopButtons, self.ToggleGuildBankButton)
    table.remove(self.TopButtons, index)
    self.ToggleGuildBankButton:Hide()
  end

  for index = 2, #self.TopButtons do
    local button = self.TopButtons[index]
    button:SetPoint("TOPLEFT", self.TopButtons[index-1], "TOPRIGHT")
  end

  self.TopButtons[1]:ClearAllPoints()
  self.TopButtons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", Baganator.Constants.ButtonFrameOffset + 2, -1)

  self.BagSlots:SetPoint("BOTTOMLEFT", self, "TOPLEFT", Baganator.Constants.ButtonFrameOffset, 0)

  Baganator.Skins.AddFrame("ButtonFrame", self, {"backpack"})
end

function BaganatorItemViewCommonBackpackViewMixin:OnShow()
  if Baganator.Config.Get(Baganator.Config.Options.AUTO_SORT_ON_OPEN) then
    C_Timer.After(0, function()
      self:CombineStacksAndSort()
    end)
  end
  PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
end

function BaganatorItemViewCommonBackpackViewMixin:OnHide()
  PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
end

function BaganatorItemViewCommonBackpackViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorItemViewCommonBackpackViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorItemViewCommonBackpackViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_POSITION, {point, x, y})
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleBank()
  Baganator.CallbackRegistry:TriggerEvent("BankToggle", self.lastCharacter)
  self:Raise()
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleGuildBank()
  Baganator.CallbackRegistry:TriggerEvent("GuildToggle", Syndicator.API.GetCharacter(self.lastCharacter).details.guild)
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS))
end


function BaganatorItemViewCommonBackpackViewMixin:SelectTab(character)
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

function BaganatorItemViewCommonBackpackViewMixin:FillRecents(characters)
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

function BaganatorItemViewCommonBackpackViewMixin:AddNewRecent(character)
  local recents = Baganator.Config.Get(Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local data = Syndicator.API.GetCharacter(character)
  if not data then
    return
  end

  table.insert(recents, 2, character)

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorItemViewCommonBackpackViewMixin:RefreshTabs()
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
      Baganator.Skins.AddFrame("TabButton", tabButton)
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

function BaganatorItemViewCommonBackpackViewMixin:SetupTabs()
  if self.tabsSetup then
    return
  end

  self:FillRecents(characters)

  self.tabsSetup = self.liveCharacter ~= nil
end

function BaganatorItemViewCommonBackpackViewMixin:HideExtraTabs()
  local isShown = Baganator.Config.Get(Baganator.Config.Options.SHOW_RECENTS_TABS)
  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(isShown and tab:GetRight() < self:GetRight())
  end
end

function BaganatorItemViewCommonBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()
  Baganator.Utilities.ApplyVisuals(self)

  local characterData = Syndicator.API.GetCharacter(character)

  if not characterData then
    self:SetTitle("")
    return true
  else
    self:SetTitle(BAGANATOR_L_XS_BAGS:format(characterData.details.character))
  end

  self:SetupTabs()
  self:SelectTab(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  self.isLive = isLive

  self.BagSlots:Update(self.lastCharacter, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bags))

  if oldLast ~= character then
    Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton() and isLive)
  self:UpdateTransferButton()

  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  if self.tabsSetup then -- Not ready immediately on PLAYER_ENTERING_WORLD
    self.Tabs[1]:SetPoint("LEFT", self, "LEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset, 0)
  end

  self.SearchWidget:SetSpacing(sideSpacing)

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end
end

function BaganatorItemViewCommonBackpackViewMixin:CombineStacks(callback)
  Baganator.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorItemViewCommonBackpackViewMixin:UpdateTransferButton()
  if not self:IsVisible() then
    return
  end

  self.TransferButton:ClearAllPoints()
  if self.SortButton:IsShown() then
    self.TransferButton:SetPoint("RIGHT", self.SortButton, "LEFT")
  else
    self.TransferButton:SetPoint("RIGHT", self.CustomiseButton, "LEFT")
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

function BaganatorItemViewCommonBackpackViewMixin:UpdateAllButtons()
  self.ButtonVisibility:Update()
  local guildName = Syndicator.API.GetCharacter(self.lastCharacter).details.guild
  self.ToggleGuildBankButton:SetEnabled(guildName ~= nil and Syndicator.API.GetGuild(guildName))
end

function BaganatorItemViewCommonBackpackViewMixin:RunAction(action, getItems)
  action((getItems and getItems()) or self:GetSearchMatches(), self.liveCharacter, function(status, modes)
    self.transferManager:Apply(status, modes or {"BagCacheUpdate"}, function()
      self:RunAction(action, getItems)
    end, function() end)
  end)
end

function BaganatorItemViewCommonBackpackViewMixin:Transfer(force, getItems)
  for _, transferDetails in ipairs(addonTable.BagTransfers) do
    if transferDetails.condition() then
      if not force and transferDetails.confirmOnAll and self.SearchWidget.SearchBox:GetText() == "" then
        StaticPopup_Show(self.confirmTransferAllDialogName, nil, nil, getItems)
        break
      else
        self:RunAction(transferDetails.action, getItems)
        break
      end
    end
  end
end

function BaganatorItemViewCommonBackpackViewMixin:DoSort(isReverse)
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

function BaganatorItemViewCommonBackpackViewMixin:CombineStacksAndSort(isReverse)
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
