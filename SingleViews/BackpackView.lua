local _, addonTable = ...
local addonName, addonTable = ...

BaganatorSingleViewBackpackViewMixin = CreateFromMixins(BaganatorItemViewCommonBackpackViewMixin)

function BaganatorSingleViewBackpackViewMixin:OnLoad()
  BaganatorItemViewCommonBackpackViewMixin.OnLoad(self)

  self.BagLive:SetPool(self.liveItemButtonPool)
  self.CollapsingBagSectionsPool = addonTable.SingleViews.GetCollapsingBagSectionsPool(self)
  self.CollapsingBags = {}
  self.bagDetailsForComparison = {}

  addonTable.CallbackRegistry:RegisterCallback("ContentRefreshRequired",  function()
    for _, layout in ipairs(self.Layouts) do
      layout:RequestContentRefresh()
    end
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SpecialBagToggled", function(_, character)
    if self:IsVisible() and self.lastCharacter ~= nil then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  addonTable.AddBagTransferActivationCallback(function()
    self:UpdateTransferButton()
  end)
end

function BaganatorSingleViewBackpackViewMixin:AllocateBags(character)
  local newDetails = addonTable.SingleViews.GetCollapsingBagDetails(character, "bags", Syndicator.Constants.AllBagIndexes, Syndicator.Constants.BagSlotsCount)
  if self.bagDetailsForComparison.bags == nil or not tCompare(self.bagDetailsForComparison.bags, newDetails, 15) then
    self.bagDetailsForComparison.bags = CopyTable(newDetails)
    self.CollapsingBags = addonTable.SingleViews.AllocateCollapsingSections(
      character, "bags", Syndicator.Constants.AllBagIndexes,
      newDetails, self.CollapsingBags,
      self.CollapsingBagSectionsPool, self.liveItemButtonPool)
    self.lastBagDetails = newDetails
  end
end

function BaganatorSingleViewBackpackViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end
  self.searchToApply = false

  if self.isLive then
    self.BagLive:ApplySearch(text)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.live:ApplySearch(text)
    end
  else
    self.BagCached:ApplySearch(text)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:ApplySearch(text)
    end
  end
end

function BaganatorSingleViewBackpackViewMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)
  for _, bagGroup in ipairs(self.CollapsingBags) do
    bagGroup.live:MarkBagsPending("bags", updatedBags)
  end

  -- Update cached views with current items when live or on login
  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
    for _, bagGroup in ipairs(self.CollapsingBags) do
      bagGroup.cached:MarkBagsPending("bags", updatedBags)
    end
  end
end

function BaganatorSingleViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()
  BaganatorItemViewCommonBackpackViewMixin.UpdateForCharacter(self, character, isLive)

  if self.isLive then
    addonTable.NewItems:ImportNewItems()
  end

  self:AllocateBags(character)

  self.BagLive:SetShown(isLive)
  self.BagCached:SetShown(not isLive)

  local searchText = self.SearchWidget.SearchBox:GetText()

  local activeBag, activeBagCollapsibles = nil, {}

  if self.BagLive:IsShown() then
    activeBag = self.BagLive
    for _, layouts in ipairs(self.CollapsingBags) do
      table.insert(activeBagCollapsibles, layouts.live)
    end
  else
    activeBag = self.BagCached
    for _, layouts in ipairs(self.CollapsingBags) do
      table.insert(activeBagCollapsibles, layouts.cached)
    end
  end

  local bagWidth = addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_WIDTH)

  local characterData = Syndicator.API.GetCharacter(character) 
  local bagData = characterData and characterData.bags

  activeBag:ShowBags(bagData, character, Syndicator.Constants.AllBagIndexes, self.lastBagDetails.mainIndexesToUse, bagWidth)

  for index, layout in ipairs(activeBagCollapsibles) do
    layout:ShowBags(bagData, character, Syndicator.Constants.AllBagIndexes, self.CollapsingBags[index].indexesToUse, bagWidth)
  end

  if self.searchToApply then
    self:ApplySearch(searchText)
  end

  local sideSpacing, topSpacing = 13, 14
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    if (IsAddOnLoaded or C_AddOns.IsAddOnLoaded)("Baganator-ElvUI") then
      sideSpacing = 6.5
    else
      sideSpacing = 8
    end
    topSpacing = 7
  end

  local bagHeight = activeBag:GetHeight() + topSpacing / 2

  bagHeight = bagHeight + addonTable.SingleViews.ArrangeCollapsibles(activeBagCollapsibles, activeBag, self.CollapsingBags)

  for _, layouts in ipairs(self.CollapsingBags) do
    layouts.live:SetShown(isLive and layouts.live:IsShown())
    layouts.cached:SetShown(not isLive and layouts.cached:IsShown())
  end

  activeBag:SetPoint("TOPRIGHT", -sideSpacing, -50 - topSpacing / 4)

  self:SetSize(
    activeBag:GetWidth() + sideSpacing * 2 + addonTable.Constants.ButtonFrameOffset - 2,
    bagHeight + 75
  )

  self.AllButtons = {}
  tAppendAll(self.AllButtons, self.AllFixedButtons)
  tAppendAll(self.AllButtons, self.TopButtons)

  self:HideExtraTabs()

  local lastButton = nil
  for index, layout in ipairs(activeBagCollapsibles) do
    local button = self.CollapsingBags[index].button
    button:SetShown(layout:GetHeight() > 0)
    button:ClearAllPoints()
    if button:IsShown() then
      if lastButton then
        button:SetPoint("LEFT", lastButton, "RIGHT", 5, 0)
      else
        button:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
        button:SetPoint("LEFT", activeBag, -2, 0)
      end
      lastButton = button
      table.insert(self.AllButtons, button)
    end
  end

  self:UpdateAllButtons()

  self.CurrencyWidget:UpdateCurrencyTextVisibility(lastButton and lastButton:GetRight() - self:GetLeft() + 10 or sideSpacing + addonTable.Constants.ButtonFrameOffset)

  addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    print("-- updateforcharacter backpack", debugprofilestop() - start)
  end
end

function BaganatorSingleViewBackpackViewMixin:GetSearchMatches()
  local matches = {}
  tAppendAll(matches, self.BagLive.SearchMonitor:GetMatches())
  for _, layouts in ipairs(self.CollapsingBags) do
    tAppendAll(matches, layouts.live.SearchMonitor:GetMatches())
  end
  return matches
end
