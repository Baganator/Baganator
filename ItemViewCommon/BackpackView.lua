local _, addonTable = ...

local classicTabObjectCounter = 0

BaganatorItemViewCommonBackpackViewMixin = {}

local function PreallocateItemButtons(pool, buttonCount)
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    for i = 1, buttonCount do
      local button = pool:Acquire()
      addonTable.Skins.AddFrame("ItemButton", button)
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

  self.liveItemButtonPool = addonTable.ItemViewCommon.GetLiveItemButtonPool(self)

  self.Anchor = addonTable.ItemViewCommon.GetAnchorSetter(self, addonTable.Config.Options.MAIN_VIEW_POSITION)

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  -- 6 is bags + reagent bag (retail) or bags + keyring (wrath)
  PreallocateItemButtons(self.liveItemButtonPool, Syndicator.Constants.MaxBagSize * 6 + addonTable.Constants.ContainerTypes)

  addonTable.Utilities.AddBagSortManager(self) -- self.sortManager
  addonTable.Utilities.AddBagTransferManager(self) -- self.transferManager

  addonTable.Utilities.AddScrollBar(self)

  self.tabsPool = addonTable.ItemViewCommon.GetTabButtonPool(self)

  addonTable.CallbackRegistry:RegisterCallback("BagCacheAfterNewItemsUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self.searchToApply = true
    self:NotifyBagUpdate(updatedBags)
    if self:IsVisible() then
      self:UpdateForCharacter(character, true)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
      return
    end
    if tIndexOf(addonTable.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsVisible() then
        addonTable.Utilities.ApplyVisuals(self)
      end
    elseif tIndexOf(addonTable.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Container.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == addonTable.Config.Options.SHOW_RECENTS_TABS then
      local isShown = addonTable.Config.Get(addonTable.Config.Options.SHOW_RECENTS_TABS)
      for index, tab in ipairs(self.Tabs) do
        tab:SetShown(isShown)
        if tab.details == self.lastCharacter then
          PanelTemplates_SetTab(self, index)
        end
      end
      self:OnFinished()
    elseif settingName == addonTable.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS then
      self.BagSlots:Update(self.lastCharacter, self.isLive)
      self:OnFinished()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.searchToApply = true
    self:ApplySearch(text)
  end)

  addonTable.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if character ~= self.lastCharacter then
      self:AddNewRecent(character)
      if self:IsVisible() then
        self:UpdateForCharacter(character, self.liveCharacter == character)
      end
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  self.confirmTransferAllDialogName = "addonTable.ConfirmTransferAll_" .. self:GetName()
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

  if addonTable.Constants.IsEra then
    local index = tIndexOf(self.TopButtons, self.ToggleGuildBankButton)
    table.remove(self.TopButtons, index)
    self.ToggleGuildBankButton:Hide()
  end

  for index = 2, #self.TopButtons do
    local button = self.TopButtons[index]
    button:SetPoint("TOPLEFT", self.TopButtons[index-1], "TOPRIGHT")
  end

  self.TopButtons[1]:ClearAllPoints()
  self.TopButtons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", addonTable.Constants.ButtonFrameOffset + 2, -1)

  self.BagSlots:SetPoint("BOTTOMLEFT", self, "TOPLEFT", addonTable.Constants.ButtonFrameOffset, 0)

  addonTable.Skins.AddFrame("ButtonFrame", self, {"backpack"})
end

function BaganatorItemViewCommonBackpackViewMixin:OnShow()
  if addonTable.Config.Get(addonTable.Config.Options.AUTO_SORT_ON_OPEN) then
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
  if not addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorItemViewCommonBackpackViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local oldCorner = addonTable.Config.Get(addonTable.Config.Options.MAIN_VIEW_POSITION)[1]
  addonTable.Config.Set(addonTable.Config.Options.MAIN_VIEW_POSITION, {addonTable.Utilities.ConvertAnchorToCorner(oldCorner, self)})
  self:ClearAllPoints()
  self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.MAIN_VIEW_POSITION)))
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleBank()
  addonTable.CallbackRegistry:TriggerEvent("BankToggle", self.lastCharacter)
  self:Raise()
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleGuildBank()
  addonTable.CallbackRegistry:TriggerEvent("GuildToggle", Syndicator.API.GetCharacter(self.lastCharacter).details.guild)
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleReagents()
  addonTable.Config.Set(addonTable.Config.Options.SHOW_REAGENTS, not addonTable.Config.Get(addonTable.Config.Options.SHOW_REAGENTS))
end

function BaganatorItemViewCommonBackpackViewMixin:ToggleBagSlots()
  addonTable.Config.Set(addonTable.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS, not addonTable.Config.Get(addonTable.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS))
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
  local recents = addonTable.Config.Get(addonTable.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
  local newRecents = {}
  local seen = {}
  for _, character in ipairs(recents) do
    if Syndicator.API.GetCharacter(character) and not seen[character] and #newRecents < addonTable.Constants.MaxRecents then
      table.insert(newRecents, character)
    end
    seen[character] = true
  end
  addonTable.Config.Set(addonTable.Config.Options.RECENT_CHARACTERS_MAIN_VIEW, newRecents)
end

function BaganatorItemViewCommonBackpackViewMixin:FillRecents(characters)
  local characters = Syndicator.API.GetAllCharacters()

  table.sort(characters, function(a, b) return a < b end)

  local recents = addonTable.Config.Get(addonTable.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  table.insert(recents, 1, self.liveCharacter)

  for _, char in ipairs(characters) do
    table.insert(recents, char)
  end

  DeDuplicateRecents()

  self:RefreshTabs()
end

function BaganatorItemViewCommonBackpackViewMixin:AddNewRecent(character)
  local recents = addonTable.Config.Get(addonTable.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)
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

  local characters = addonTable.Config.Get(addonTable.Config.Options.RECENT_CHARACTERS_MAIN_VIEW)

  local isShown = addonTable.Config.Get(addonTable.Config.Options.SHOW_RECENTS_TABS)
  local sameConnected = {}
  for _, realmNormalized in ipairs(Syndicator.Utilities.GetConnectedRealms()) do
    sameConnected[realmNormalized] = true
  end

  local lastTab
  local tabs = {}
  local index = 1
  while #tabs < addonTable.Constants.MaxRecentsTabs and index <= #characters do
    local char = characters[index]
    local details = Syndicator.API.GetCharacter(char).details
    if sameConnected[details.realmNormalized] then
      local tabButton = self.tabsPool:Acquire()
      addonTable.Skins.AddFrame("TabButton", tabButton)
      tabButton:SetText(details.character)
      tabButton:SetScript("OnClick", function()
        addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", char)
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
  local isShown = addonTable.Config.Get(addonTable.Config.Options.SHOW_RECENTS_TABS)
  for _, tab in ipairs(self.Tabs) do
    tab:SetShown(isShown and tab:GetRight() < self:GetRight())
  end
end

function BaganatorItemViewCommonBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()
  addonTable.Utilities.ApplyVisuals(self)

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

  addonTable.Utilities.AddGeneralDropSlot(self, function()
    return Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bags
  end, Syndicator.Constants.AllBagIndexes)

  self.BagSlots:Update(self.lastCharacter, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bags))

  if oldLast ~= character then
    addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  self.SortButton:SetShown(addonTable.Utilities.ShouldShowSortButton() and isLive)
  self:UpdateTransferButton()

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  if self.tabsSetup then -- Not ready immediately on PLAYER_ENTERING_WORLD
    self.Tabs[1]:SetPoint("LEFT", self, "LEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset, 0)
  end

  self.SearchWidget:SetSpacing(sideSpacing)

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end
end

function BaganatorItemViewCommonBackpackViewMixin:OnFinished(character, isLive)
  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  local externalVerticalSpacing = (self.BagSlots:GetHeight() > 0 and (self.BagSlots:GetTop() - self:GetTop()) or 0) + (self.Tabs[1] and self.Tabs[1]:IsShown() and (self:GetBottom() - self.Tabs[1]:GetBottom() + 5) or 0)

  local additionalPadding = 0
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    additionalPadding = 1
  end

  self:SetSize(
    self.Container:GetWidth() + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2,
    math.min(self.Container:GetHeight() + 74 + additionalPadding + topSpacing / 2 + self.CurrencyWidget:GetExtraHeight(), UIParent:GetHeight() / self:GetScale() - externalVerticalSpacing)
  )

  self:UpdateScroll(74 + additionalPadding + topSpacing / 2 + externalVerticalSpacing, self:GetScale())

  self:HideExtraTabs()

  self:UpdateAllButtons()
end

function BaganatorItemViewCommonBackpackViewMixin:CombineStacks(callback)
  addonTable.Sorting.CombineStacks(Syndicator.API.GetCharacter(self.liveCharacter).bags, Syndicator.Constants.AllBagIndexes, function(status)
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
  self.ToggleGuildBankButton.Icon:SetDesaturated(not self.ToggleGuildBankButton:IsEnabled())
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
  local bagChecks = addonTable.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBagIndexes)
  local function DoSortInternal()
    local status = addonTable.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self.liveCharacter).bags,
      Syndicator.Constants.AllBagIndexes,
      bagsToSort,
      bagChecks,
      isReverse,
      addonTable.Config.Get(addonTable.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      addonTable.Config.Get(addonTable.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end
  DoSortInternal()
end

function BaganatorItemViewCommonBackpackViewMixin:CombineStacksAndSort(isReverse)
  local sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)

  if not addonTable.Sorting.IsModeAvailable(sortMethod) then
    addonTable.Config.ResetOne(addonTable.Config.Options.SORT_METHOD)
    sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)
  end

  if addonTable.API.ExternalContainerSorts[sortMethod] then
    addonTable.API.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Backpack)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorItemViewCommonBackpackViewMixin:GetExternalSortMethodName()
  return addonTable.Utilities.GetExternalSortMethodName()
end
