local _, addonTable = ...
local addonName, addonTable = ...

BaganatorCategoryViewBackpackViewMixin = CreateFromMixins(BaganatorItemViewCommonBackpackViewMixin)

function BaganatorCategoryViewBackpackViewMixin:OnLoad()
  BaganatorItemViewCommonBackpackViewMixin.OnLoad(self)

  self.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self:RegisterEvent("CURSOR_CHANGED")

  self.labelsPool = CreateFramePool("Button", self, "BaganatorCategoryViewsCategoryButtonTemplate")
  self.sectionButtonPool = addonTable.CategoryViews.GetSectionButtonPool(self)
  self.dividerPool = CreateFramePool("Button", self, "BaganatorBagDividerTemplate")

  self.recentItems = {}

  addonTable.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    self.MultiSearch:ResetCaches()
    self.results = nil
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("ForceClearedNewItems",  function()
    if self:IsVisible() and self.lastCharacter ~= nil and self.isLive then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
      return
    end
    if tIndexOf(addonTable.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      self.searchToApply = true
      self.results = nil
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == addonTable.Config.Options.SORT_METHOD then
      self.results = nil
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == addonTable.Config.Options.JUNK_PLUGIN then
      self.results = nil
      self.MultiSearch:ResetCaches()
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink, addedDirectly)
    self.addToCategoryMode = fromCategory
    self.addedToFromCategory = addedDirectly == true
    if self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.TopButtons)
  tAppendAll(self.AllButtons, self.AllFixedButtons)

  addonTable.AddBagTransferActivationCallback(function()
    self:UpdateTransferButton()
    local oldState = self.splitStacksDueToTransfer
    self.splitStacksDueToTransfer = false
    for _, info in ipairs(addonTable.BagTransfers) do
      if info.condition() then
        self.splitStacksDueToTransfer = true
      end
    end
    if oldState ~= self.splitStacksDueToTransfer and self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  self.notShown = {}
end

function BaganatorCategoryViewBackpackViewMixin:NotifyBagUpdate(updatedBags)
end

function BaganatorCategoryViewBackpackViewMixin:OnEvent(eventName)
  if eventName == "CURSOR_CHANGED" and self.addToCategoryMode and not C_Cursor.GetCursorItem() then
    self.addToCategoryMode = nil
    if self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end
end

function BaganatorCategoryViewBackpackViewMixin:OnShow()
  BaganatorItemViewCommonBackpackViewMixin.OnShow(self)
  addonTable.NewItems:ClearNewItemsForTimeout()
  self.results = nil
end

-- Clear new item status on items that are hidden as part of a stack
function BaganatorCategoryViewBackpackViewMixin:OnHide()
  BaganatorItemViewCommonBackpackViewMixin.OnHide(self)
  for _, item in ipairs(self.notShown) do
    addonTable.NewItems:ClearNewItem(item.bagID, item.slotID)
  end
end

function BaganatorCategoryViewBackpackViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end
  self.searchToApply = false

  for _, layout in ipairs(self.Layouts) do
    if layout:IsVisible() then
      layout:ApplySearch(text)
    end
  end
end

function BaganatorCategoryViewBackpackViewMixin:GetSearchMatches()
  local matches = {}
  for _, layouts in ipairs(self.LiveLayouts) do
    tAppendAll(matches, layouts.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorCategoryViewBackpackViewMixin:TransferCategory(associatedSearch)
  if not self.isLive or not associatedSearch then
    return
  end

  self:Transfer(true, function() return self.results and tFilter(self.results[associatedSearch].all, function(a) return a.itemLink ~= nil end, true) end)
end

function BaganatorCategoryViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  if character ~= self.lastCharacter then
    self.results = nil
  end

  local start = debugprofilestop()
  BaganatorItemViewCommonBackpackViewMixin.UpdateForCharacter(self, character, isLive)

  if self.isLive then
    addonTable.NewItems:ImportNewItems(true)
  end

  local sideSpacing, topSpacing = 13, 14
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  self.isGrouping = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING) and (not self.splitStacksDueToTransfer or not self.isLive)

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local characterData = Syndicator.API.GetCharacter(character)
  local bagTypes = addonTable.CategoryViews.Utilities.GetBagTypes(characterData, "bags", Syndicator.Constants.AllBagIndexes)
  local bagWidth = addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_WIDTH)
  addonTable.CategoryViews.LayoutContainers(self, characterData.bags, bagWidth, bagTypes, Syndicator.Constants.AllBagIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self:SetSize(
      math.max(addonTable.CategoryViews.Constants.MinWidth, maxWidth + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2),
      maxHeight + 75 + topSpacing / 2
    )
    self.CurrencyWidget:UpdateCurrencyTextVisibility(sideSpacing + addonTable.Constants.ButtonFrameOffset)

    local searchText = self.SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self:ApplySearch(searchText)
    end

    self:HideExtraTabs()

    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      print("-- updateforcharacter backpack", debugprofilestop() - start)
    end

    self:UpdateAllButtons()

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
