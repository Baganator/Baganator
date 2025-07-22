---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorCategoryViewBankViewCharacterViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewCharacterViewMixin)

function BaganatorCategoryViewBankViewCharacterViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewCharacterViewMixin.OnLoad(self)

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

function BaganatorCategoryViewBankViewCharacterViewMixin:OnEvent(eventName, ...)
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

function BaganatorCategoryViewBankViewCharacterViewMixin:TransferCategory(sourceKey)
  if not self.isLive then
    return
  end

  self:RemoveSearchMatches(function() return self.layoutsBySourceKey[sourceKey] and self.layoutsBySourceKey[sourceKey].SearchMonitor:GetMatches() or {} end)
end

function BaganatorCategoryViewBankViewCharacterViewMixin:TransferSection(tree)
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

function BaganatorCategoryViewBankViewCharacterViewMixin:GetActiveLayouts()
  return self.activeLayouts
end

function BaganatorCategoryViewBankViewCharacterViewMixin:GetSearchMatches()
  local matches = {}
  for _, layouts in ipairs(self.LiveLayouts) do
    tAppendAll(matches, layouts.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorCategoryViewBankViewCharacterViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end

  for _, layout in ipairs(self.Container.Layouts) do
    if layout:IsVisible() then
      layout:ApplySearch(text)
    end
  end
end

function BaganatorCategoryViewBankViewCharacterViewMixin:NotifyBagUpdate(updatedBags)
  --self.LayoutManager:NotifyBagUpdate(updatedBags.bank)
end

function BaganatorCategoryViewBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
  BaganatorItemViewCommonBankViewCharacterViewMixin.UpdateForCharacter(self, character, isLive)

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  if self.BankMissingHint:IsShown() then
    self.LayoutManager:ClearVisuals()
    return
  end

  self:GetParent().AllButtons = {}

  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.TopButtons)

  local buttonPadding = 0

  local lastButton
  if self.BuyReagentBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.BuyReagentBankButton)
    self.BuyReagentBankButton:ClearAllPoints()
    self.BuyReagentBankButton:SetPoint("LEFT", self, addonTable.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.BuyReagentBankButton:SetPoint("BOTTOM", self, 0, 6)
    lastButton = self.BuyReagentBankButton
    buttonPadding = 2
  end
  if self.DepositIntoReagentsBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.DepositIntoReagentsBankButton)
    self.DepositIntoReagentsBankButton:ClearAllPoints()
    self.DepositIntoReagentsBankButton:SetPoint("LEFT", self, addonTable.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.DepositIntoReagentsBankButton:SetPoint("BOTTOM", self, 0, 6)
    lastButton = self.DepositIntoReagentsBankButton
    buttonPadding = 2
  end

  self.isGrouping = not self.isLive and addonTable.Config.Get(addonTable.Config.Options.CATEGORY_ITEM_GROUPING)
  self.splitStacksDueToTransfer = self.isLive

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local characterData = Syndicator.API.GetCharacter(character)
  local bagTypes = addonTable.CategoryViews.Utilities.GetBagTypes(characterData, "bank", Syndicator.Constants.AllBankIndexes)
  local bagWidth = addonTable.Config.Get(addonTable.Config.Options.BANK_VIEW_WIDTH)
  self.LayoutManager:Layout(characterData.bank, bagWidth, bagTypes, Syndicator.Constants.AllBankIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self.Container:SetSize(math.max(addonTable.CategoryViews.Utilities.GetMinWidth(bagWidth), maxWidth), maxHeight)

    self:OnFinished()

    self.CurrencyWidget:UpdateCurrencyTextPositions(self.Container:GetWidth() - (lastButton and lastButton:GetWidth() + 10 or 0), self.Container:GetWidth())

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
