---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorCategoryViewBankViewCharacterTabsViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewCharacterTabsViewMixin)

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewCharacterTabsViewMixin.OnLoad(self)

  self.Container.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self.LayoutManager = CreateFrame("Frame", nil, self)
  Mixin(self.LayoutManager, addonTable.CategoryViews.BagLayoutMixin)
  self.LayoutManager:OnLoad()
  self.location = "character_bank"

  self:RegisterEvent("CURSOR_CHANGED")
  self:RegisterEvent("MODIFIER_STATE_CHANGED")

  addonTable.CallbackRegistry:RegisterCallback("CategoryAddItemStart", function(_, fromCategory, itemID, itemLink, addedDirectly)
    self.addToCategoryMode = fromCategory
    self.addedToFromCategory = addedDirectly == true
    if self:IsVisible() and addonTable.CategoryViews.Utilities.GetAddButtonsState() then
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      self:GetParent():UpdateView()
    end
  end)
end

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:OnEvent(eventName, ...)
  if eventName == "CURSOR_CHANGED" and self.addToCategoryMode and not C_Cursor.GetCursorItem() then
    self.addToCategoryMode = nil
    if self:IsVisible() then
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      self:GetParent():UpdateView()
    end
  elseif eventName == "MODIFIER_STATE_CHANGED" and self.addToCategoryMode and (addonTable.CategoryViews.Utilities.GetAddButtonsState() or self.LayoutManager.showAddButtons) and C_Cursor.GetCursorItem() then
    if self:IsVisible() then
      self.refreshState[addonTable.Constants.RefreshReason.Layout] = true
      self:GetParent():UpdateView()
    end
  end
end

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:TransferCategory(sourceKey)
  if not self.isLive then
    return
  end

  self:RemoveSearchMatches(function() return self.layoutsBySourceKey[sourceKey] and self.layoutsBySourceKey[sourceKey].SearchMonitor:GetMatches() or {} end)
end

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:TransferSection(tree)
  if not self.isLive then
    return
  end

  self:RemoveSearchMatches(function()
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

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:GetActiveLayouts()
  return self.activeLayouts
end

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:GetSearchMatches()
  local matches = {}
  for _, layouts in ipairs(self.LiveLayouts) do
    tAppendAll(matches, layouts.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:NotifyBagUpdate(updatedBags)
  --self.LayoutManager:NotifyBagUpdate(updatedBags.bank)
end

function BaganatorCategoryViewBankViewCharacterTabsViewMixin:ShowTab(character, tabIndex, isLive)
  BaganatorItemViewCommonBankViewCharacterTabsViewMixin.ShowTab(self, character, tabIndex, isLive)

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  if self.BankMissingHint:IsShown() then
    self.LayoutManager:ClearVisuals()
    return
  end

  local buttonPadding = 0

  local lastButton

  self.isGrouping = not self.isLive and addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING)
  self.splitStacksDueToTransfer = self.isLive

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local characterData = Syndicator.API.GetCharacter(character)
  local bagTypes = addonTable.CategoryViews.Utilities.GetBagTypes(characterData, "bank", Syndicator.Constants.AllBankIndexes)
  local bagWidth = addonTable.Config.Get(addonTable.Config.Options.CHARACTER_BANK_VIEW_WIDTH)
  local bagData = {}
  if self.currentTab > 0 then
    table.insert(bagData, characterData.bankTabs[tabIndex].slots)
    table.insert(bagTypes, 0)
    bagIndexes = {Syndicator.Constants.AllBankIndexes[tabIndex]}
  else
    for _, tab in ipairs(characterData.bankTabs) do
      table.insert(bagData, tab.slots)
      table.insert(bagTypes, 0)
    end
    bagWidth = bagWidth * 2
    bagIndexes = Syndicator.Constants.AllBankIndexes
  end
  self.LayoutManager:Layout(bagData, bagWidth, bagTypes, bagIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self.Container:SetSize(
      math.max(addonTable.CategoryViews.Utilities.GetMinWidth(bagWidth), self:GetButtonsWidth(sideSpacing), maxWidth),
      maxHeight
    )
    self:OnFinished()

    self.CurrencyWidget:UpdateCurrencyTextPositions(self.Container:GetWidth() - self.buttonsWidth - 5, self.Container:GetWidth())

    local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self.searchToApply = false
      self:ApplySearch(searchText)
    end

    self.refreshState = {}

    addonTable.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end)
end
