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
  self.dividerPool = CreateFramePool("Button", self, "BaganatorBagDividerTemplate")

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    self.MultiSearch:ResetCaches()
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
    if tIndexOf(Baganator.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    elseif settingName == Baganator.Config.Options.SORT_METHOD then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == Baganator.Config.Options.JUNK_PLUGIN then
      self.MultiSearch:ResetCaches()
      if self:IsVisible() then
        self:GetParent():UpdateView()
      end
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink)
    self.addToCategoryMode = fromCategory
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
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  self.isGrouping = false--Baganator.Config.Get(Baganator.Config.Options.CATEGORY_ITEM_GROUPING)

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local buttonPadding = 0
  if self.isLive then
    buttonPadding = buttonPadding + 25
  end
  

  local warbandData = Syndicator.API.GetWarband(1)
  Baganator.CategoryViews.LayoutContainers(self, {warbandData.bank[tabIndex].slots}, "bank", {Syndicator.Constants.AllWarbandIndexes[tabIndex]}, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self:SetSize(
      math.max(400, maxWidth + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2),
      maxHeight + 75 + topSpacing / 2 + buttonPadding
    )

    local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self:ApplySearch(searchText)
    end

    Baganator.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end)

  self:GetParent():OnTabFinished()
end
