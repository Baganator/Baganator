local _, addonTable = ...

BaganatorCategoryViewBackpackViewMixin = CreateFromMixins(BaganatorItemViewCommonBackpackViewMixin)

function BaganatorCategoryViewBackpackViewMixin:OnLoad()
  BaganatorItemViewCommonBackpackViewMixin.OnLoad(self)

  self.Container.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self.LayoutManager = CreateFrame("Frame", nil, self)
  Mixin(self.LayoutManager, addonTable.CategoryViews.BagLayoutMixin)
  self.LayoutManager:OnLoad()

  self:RegisterEvent("CURSOR_CHANGED")
  self:RegisterEvent("MODIFIER_STATE_CHANGED")

  addonTable.CallbackRegistry:RegisterCallback("ForceClearedNewItems",  function()
    if self:IsVisible() and self.lastCharacter ~= nil and self.isLive then
      self.refreshState[addonTable.Constants.RefreshReason.Searches] = true
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink, addedDirectly)
    self.addToCategoryMode = fromCategory
    self.addedToFromCategory = addedDirectly == true
    if self:IsVisible() and addonTable.CategoryViews.Utilities.GetAddButtonsState() then
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end)

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
  --self.LayoutManager:NotifyBagUpdate(updatedBags.bags)
end

function BaganatorCategoryViewBackpackViewMixin:OnEvent(eventName)
  if eventName == "CURSOR_CHANGED" and self.addToCategoryMode and not C_Cursor.GetCursorItem() then
    self.addToCategoryMode = nil
    if self:IsVisible() then
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  elseif eventName == "MODIFIER_STATE_CHANGED" and self.addToCategoryMode and (addonTable.CategoryViews.Utilities.GetAddButtonsState() or self.LayoutManager.showAddButtons) and C_Cursor.GetCursorItem() then
    self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
    self:UpdateForCharacter(self.lastCharacter, self.isLive)
  end
end

function BaganatorCategoryViewBackpackViewMixin:OnShow()
  BaganatorItemViewCommonBackpackViewMixin.OnShow(self)
  if addonTable.NewItems:ClearNewItemsForTimeout() then
    self.refreshState[addonTable.Constants.RefreshReason.ItemData] = true -- Change to more relevant refresh state
  end
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

  for _, layout in ipairs(self.Container.Layouts) do
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

function BaganatorCategoryViewBackpackViewMixin:GetActiveLayouts()
  return self.activeLayouts
end

function BaganatorCategoryViewBackpackViewMixin:TransferCategory(sourceKey)
  if not self.isLive then
    return
  end

  self:Transfer(true, function() return self.layoutsBySourceKey[sourceKey] and self.layoutsBySourceKey[sourceKey].SearchMonitor:GetMatches() or {} end)
end

function BaganatorCategoryViewBackpackViewMixin:TransferSection(tree)
  if not self.isLive then
    return
  end

  self:Transfer(true, function()
    local matches = {}
    for _, layout in ipairs(self:GetActiveLayouts()) do
      if layout.type == "category" then
        local rootMatch = true
        for index, label in ipairs(tree) do
          rootMatch = layout.section[index] == label
          if not rootMatch then
            break
          end
        end
        if rootMatch then
          tAppendAll(matches, layout.SearchMonitor:GetMatches())
        end
      end
    end

    return matches
  end)
end

function BaganatorCategoryViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()
  BaganatorItemViewCommonBackpackViewMixin.UpdateForCharacter(self, character, isLive)

  if self.isLive then
    addonTable.NewItems:ImportNewItems(true)
  end

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  local oldIsGrouping = self.isGrouping
  self.isGrouping = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING) and (not self.splitStacksDueToTransfer or not self.isLive)
  if self.isGrouping ~= oldIsGrouping then
    self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
  end

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = nil
  end

  local characterData = Syndicator.API.GetCharacter(character)

  if not characterData then
    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
    return
  end

  local bagTypes = addonTable.CategoryViews.Utilities.GetBagTypes(characterData, "bags", Syndicator.Constants.AllBagIndexes)
  local bagWidth = addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_WIDTH)

  self.LayoutManager:Layout(characterData.bags, bagWidth, bagTypes, Syndicator.Constants.AllBagIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self.Container:SetSize(
      math.max(addonTable.CategoryViews.Utilities.GetMinWidth(bagWidth), maxWidth),
      maxHeight
    )

    self.AllButtons = {}
    tAppendAll(self.AllButtons, self.TopButtons)
    tAppendAll(self.AllButtons, self.AllFixedButtons)
    table.insert(self.AllButtons, self.CurrencyButton)

    local lastButton = self.CurrencyButton
    lastButton:ClearAllPoints()
    lastButton:SetPoint("BOTTOM", self, "BOTTOM", 0, 6)
    lastButton:SetPoint("LEFT", self.Container, -2, 0)

    local buttonsWidth = lastButton:GetWidth() + addonTable.Utilities.AddButtons(
      self.AllButtons, lastButton, self, 5, addonTable.API.customRegions["backpack"]["bottom_left"]
    )

    addonTable.Utilities.AddButtons(self.AllButtons, self.TopButtons[#self.TopButtons], self, 0, addonTable.API.customRegions["backpack"]["top_left"])

    self.CurrencyWidget:UpdateCurrencyTextPositions(self.Container:GetWidth() - buttonsWidth - 10, self.Container:GetWidth())

    self:OnFinished()

    local searchText = self.SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self.searchToApply = false
      self:ApplySearch(searchText)
    end

    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("-- updateforcharacter backpack", debugprofilestop() - start)
    end

    self.refreshState = {}

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")
  end)
end
