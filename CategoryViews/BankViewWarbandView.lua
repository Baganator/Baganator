local _, addonTable = ...
BaganatorCategoryViewBankViewWarbandViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewWarbandViewMixin)

function BaganatorCategoryViewBankViewWarbandViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewWarbandViewMixin.OnLoad(self)

  self.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self:RegisterEvent("CURSOR_CHANGED")

  for _, layout in ipairs(self.LiveLayouts) do
    layout:SetPool(self.liveItemButtonPool)
  end

  self.labelsPool = CreateFramePool("Button", self, "BaganatorCategoryViewsCategoryButtonTemplate")
  self.sectionButtonPool = addonTable.CategoryViews.GetSectionButtonPool(self)
  self.dividerPool = CreateFramePool("Button", self, "BaganatorBagDividerTemplate")

  addonTable.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    self.MultiSearch:ResetCaches()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:GetParent():UpdateView()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(addonTable.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    elseif settingName == addonTable.Config.Options.SORT_METHOD then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == addonTable.Config.Options.JUNK_PLUGIN then
      self.MultiSearch:ResetCaches()
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

function BaganatorCategoryViewBankViewCharacterViewMixin:TransferCategory(associatedSearch)
  if not self.isLive or not associatedSearch then
    return
  end

  self:RemoveSearchMatches(function() return self.results[associatedSearch].all end)
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
end

function BaganatorCategoryViewBankViewWarbandViewMixin:ShowTab(tabIndex, isLive)
  BaganatorItemViewCommonBankViewWarbandViewMixin.ShowTab(self, tabIndex, isLive)

  -- Copied from WarbandViews/BagView.lua
  local sideSpacing, topSpacing = 13, 14
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  self.isGrouping = not self.isLive and addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING)

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local buttonPadding = 0
  if self.isLive then
    buttonPadding = buttonPadding + 25
  end
  

  local warbandData = Syndicator.API.GetWarband(1)
  if warbandData.bank[tabIndex] then
    addonTable.CategoryViews.LayoutContainers(self, {warbandData.bank[tabIndex].slots}, "bank", {0}, {Syndicator.Constants.AllWarbandIndexes[tabIndex]}, sideSpacing, topSpacing, function(maxWidth, maxHeight)
      -- Ensure bank missing hint has enough space to display
      local minWidth = 0
      if self.BankMissingHint:IsShown() then
        minWidth = self.BankMissingHint:GetWidth() + 40
        maxHeight = maxHeight + 30
      end

      self:SetSize(
        math.max(minWidth, addonTable.CategoryViews.Constants.MinWidth, maxWidth + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2),
        maxHeight + 75 + topSpacing / 2 + buttonPadding
      )

      local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
      if self.searchToApply then
        self:ApplySearch(searchText)
      end

      addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

      self:GetParent():OnTabFinished()
    end)
  else
    -- Ensure bank missing hint has enough space to display
    local minWidth = self.BankMissingHint:GetWidth() + 40
    local maxHeight = 30

    self:SetSize(
      math.max(minWidth, addonTable.CategoryViews.Constants.MinWidth),
      maxHeight + 75 + topSpacing / 2 + buttonPadding
    )

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end

  self:GetParent():OnTabFinished()
end
