local _, addonTable = ...

BaganatorCategoryViewBackpackViewMixin = CreateFromMixins(BaganatorItemViewCommonBackpackViewMixin)

function BaganatorCategoryViewBackpackViewMixin:OnLoad()
  BaganatorItemViewCommonBackpackViewMixin.OnLoad(self)

  self.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self.LayoutManager = CreateFrame("Frame", nil, self)
  Mixin(self.LayoutManager, addonTable.CategoryViews.BagLayoutMixin)
  self.LayoutManager:OnLoad()

  self:RegisterEvent("CURSOR_CHANGED")

  addonTable.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    self.LayoutManager:FullRefresh()
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
      self.LayoutManager:SettingChanged(settingName)
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == addonTable.Config.Options.SORT_METHOD then
      self.LayoutManager:SettingChanged(settingName)
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == addonTable.Config.Options.JUNK_PLUGIN then
      self.LayoutManager:SettingChanged(settingName)
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
end

function BaganatorCategoryViewBackpackViewMixin:NotifyBagUpdate(updatedBags)
  self.LayoutManager:NotifyBagUpdate(updatedBags.bags)
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
end

-- Clear new item status on items that are hidden as part of a stack
function BaganatorCategoryViewBackpackViewMixin:OnHide()
  BaganatorItemViewCommonBackpackViewMixin.OnHide(self)
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

function BaganatorCategoryViewBackpackViewMixin:TransferCategory(index)
  if not self.isLive or not index then
    return
  end

  self:Transfer(true, function() return self.LayoutManager.composed and tFilter(self.LayoutManager.composed.details[index].results or {}, function(a) return a.itemLink ~= nil end, true) end)
end

function BaganatorCategoryViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  if self.lastCharacter ~= character then
    self.LayoutManager:NewCharacter()
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

  self.LayoutManager:Layout(characterData.bags, bagWidth, bagTypes, Syndicator.Constants.AllBagIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
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
      addonTable.Utilities.DebugOutput("-- updateforcharacter backpack", debugprofilestop() - start)
    end

    self:UpdateAllButtons()

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
