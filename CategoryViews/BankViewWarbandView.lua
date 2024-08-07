local _, addonTable = ...
BaganatorCategoryViewBankViewWarbandViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewWarbandViewMixin)

function BaganatorCategoryViewBankViewWarbandViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewWarbandViewMixin.OnLoad(self)

  self.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self.LayoutManager = CreateFrame("Frame", nil, self)
  Mixin(self.LayoutManager, addonTable.CategoryViews.BagLayoutMixin)
  self.LayoutManager:OnLoad()

  self:RegisterEvent("CURSOR_CHANGED")

  self.labelsPool = CreateFramePool("Button", self, "BaganatorCategoryViewsCategoryButtonTemplate")
  self.sectionButtonPool = addonTable.CategoryViews.GetSectionButtonPool(self)
  self.dividerPool = CreateFramePool("Button", self, "BaganatorBagDividerTemplate")

  addonTable.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    self.LayoutManager:FullRefresh()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(addonTable.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      self.searchToApply = true
      self.LayoutManager:SettingChanged(settingName)
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    elseif settingName == addonTable.Config.Options.SORT_METHOD then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      self.LayoutManager:SettingChanged(settingName)
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    elseif settingName == addonTable.Config.Options.JUNK_PLUGIN then
      self.LayoutManager:SettingChanged(settingName)
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink, addedDirectly)
    self.addToCategoryMode = fromCategory
    self.addedToFromCategory = addedDirectly == true
    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end)
end

function BaganatorCategoryViewBankViewWarbandViewMixin:OnEvent(eventName, ...)
  if eventName == "CURSOR_CHANGED" and self.addToCategoryMode and not C_Cursor.GetCursorItem() then
    self.addToCategoryMode = nil
    if self:IsVisible() then
      self:GetParent():UpdateView()
    end
  end
end

function BaganatorCategoryViewBankViewWarbandViewMixin:GetSearchMatches()
  local matches = {}
  for _, layouts in ipairs(self.LiveLayouts) do
    tAppendAll(matches, layouts.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorCategoryViewBankViewWarbandViewMixin:TransferCategory(associatedSearch)
  if not self.isLive or not associatedSearch then
    return
  end

  self:RemoveSearchMatches(function() return self.LayoutManager.results and tFilter(self.LayoutManager.results[associatedSearch].all, function(a) return a.itemLink ~= nil end, true) end)
end

function BaganatorCategoryViewBankViewWarbandViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end

  for _, layout in ipairs(self.Layouts) do
    if layout:IsVisible() then
      layout:ApplySearch(text)
    end
  end
end

function BaganatorCategoryViewBankViewWarbandViewMixin:NotifyBagUpdate(updatedBags)
  self.LayoutManager:NotifyBagUpdate(updatedBags.bags)
end

function BaganatorCategoryViewBankViewWarbandViewMixin:ShowTab(tabIndex, isLive)
  BaganatorItemViewCommonBankViewWarbandViewMixin.ShowTab(self, tabIndex, isLive)

  if tabIndex ~= self.lastTab then
    self.LayoutManager:NewCharacter()
  end
  self.lastTab = tabIndex

  if self.BankMissingHint:IsShown() then
    return
  end

  local sideSpacing, topSpacing = 13, 14
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  self.isGrouping = not self.isLive and addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING)
  self.splitStacksDueToTransfer = self.isLive

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local buttonPadding = 0
  if self.isLive then
    buttonPadding = buttonPadding + 25
  end


  local warbandData = Syndicator.API.GetWarband(1)
  local bagData, bagTypes, bagIndexes = {}, {}
  local bagWidth = addonTable.Config.Get(addonTable.Config.Options.WARBAND_BANK_VIEW_WIDTH)
  if self.currentTab > 0 then
    table.insert(bagData, warbandData.bank[tabIndex].slots)
    table.insert(bagTypes, 0)
    bagIndexes = {Syndicator.Constants.AllWarbandIndexes[tabIndex]}
  else
    for _, tab in ipairs(warbandData.bank) do
      table.insert(bagData, tab.slots)
      table.insert(bagTypes, 0)
    end
    bagWidth = bagWidth * 2
    bagIndexes = Syndicator.Constants.AllWarbandIndexes
  end
  self.LayoutManager:Layout(bagData, bagWidth, bagTypes, bagIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self:SetSize(
      math.max(addonTable.CategoryViews.Constants.MinWidth, self:GetButtonsWidth(sideSpacing), maxWidth + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2),
      maxHeight + 75 + topSpacing / 2 + buttonPadding
    )

    local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self:ApplySearch(searchText)
    end

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end)
end
