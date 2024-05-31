local addonName, addonTable = ...

BaganatorCategoryViewBackpackViewMixin = CreateFromMixins(BaganatorItemViewCommonBackpackViewMixin)

function BaganatorCategoryViewBackpackViewMixin:OnLoad()
  BaganatorItemViewCommonBackpackViewMixin.OnLoad(self)

  self.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self:RegisterEvent("CURSOR_CHANGED")

  self.labelsPool = CreateFontStringPool(self, "BACKGROUND", 0, "GameFontNormal")

  Baganator.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    self.MultiSearch:ResetCaches()
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
    if tIndexOf(Baganator.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    elseif settingName == Baganator.Config.Options.JUNK_PLUGIN then
      self.MultiSearch:ResetCaches()
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink)
    self.addToCategoryMode = fromCategory
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
end

function BaganatorCategoryViewBackpackViewMixin:OnEvent(eventName)
  if eventName == "CURSOR_CHANGED" and self.addToCategoryMode and not C_Cursor.GetCursorItem() then
    self.addToCategoryMode = nil
    if self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
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

function BaganatorCategoryViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()
  BaganatorItemViewCommonBackpackViewMixin.UpdateForCharacter(self, character, isLive)

  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  self.isGrouping = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_ITEM_GROUPING) and not self.splitStacksDueToTransfer

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local characterData = Syndicator.API.GetCharacter(character)
  Baganator.CategoryViews.LayoutContainers(self, characterData.bags, "bags", Syndicator.Constants.AllBagIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self:SetSize(
      math.max(500, maxWidth + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2),
      maxHeight + 75 + topSpacing / 2
    )

    local searchText = self.SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self:ApplySearch(searchText)
    end

    self:HideExtraTabs()

    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("-- updateforcharacter backpack", debugprofilestop() - start)
    end
    Baganator.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
