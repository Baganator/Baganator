BaganatorCategoryViewBankViewCharacterViewMixin = CreateFromMixins(BaganatorItemViewCommonBankViewCharacterViewMixin)

function BaganatorCategoryViewBankViewCharacterViewMixin:OnLoad()
  BaganatorItemViewCommonBankViewCharacterViewMixin.OnLoad(self)

  self.Layouts = {}
  self.LiveLayouts = {}
  self.CachedLayouts = {}

  self:RegisterEvent("CURSOR_CHANGED")

  for _, layout in ipairs(self.LiveLayouts) do
    layout:SetPool(self.liveItemButtonPool)
  end

  self.labelsPool = CreateFontStringPool(self, "BACKGROUND", 0, "GameFontNormal")

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

function BaganatorCategoryViewBankViewCharacterViewMixin:OnEvent(eventName, ...)
  if eventName == "CURSOR_CHANGED" and self.addToCategoryMode and not C_Cursor.GetCursorItem() then
    self.addToCategoryMode = nil
    if self:IsVisible() then
      self:UpdateForCharacter(self.lastCharacter, self.isLive)
    end
  end
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

  for _, layout in ipairs(self.Layouts) do
    if layout:IsVisible() then
      layout:ApplySearch(text)
    end
  end
end

function BaganatorCategoryViewBankViewCharacterViewMixin:NotifyBagUpdate(updatedBags)
end

function BaganatorCategoryViewBankViewCharacterViewMixin:UpdateForCharacter(character, isLive)
  BaganatorItemViewCommonBankViewCharacterViewMixin.UpdateForCharacter(self, character, isLive)

  self:GetParent().AllButtons = {}

  tAppendAll(self:GetParent().AllButtons, self:GetParent().AllFixedButtons)
  tAppendAll(self:GetParent().AllButtons, self.TopButtons)

  -- Copied from SingleViews/BagView.lua
  local sideSpacing, topSpacing = 13, 14
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  local buttonPadding = 0

  if self.BuyReagentBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.BuyReagentBankButton)
    self.BuyReagentBankButton:ClearAllPoints()
    self.BuyReagentBankButton:SetPoint("LEFT", self, Baganator.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.BuyReagentBankButton:SetPoint("BOTTOM", self, 0, 6)
    buttonPadding = 2
  end
  if self.DepositIntoReagentsBankButton:IsShown() then
    table.insert(self:GetParent().AllButtons, self.DepositIntoReagentsBankButton)
    self.DepositIntoReagentsBankButton:ClearAllPoints()
    self.DepositIntoReagentsBankButton:SetPoint("LEFT", self, Baganator.Constants.ButtonFrameOffset + sideSpacing - 2, 0)
    self.DepositIntoReagentsBankButton:SetPoint("BOTTOM", self, 0, 6)
    buttonPadding = 2
  end

  self.isGrouping = false--Baganator.Config.Get(Baganator.Config.Options.CATEGORY_ITEM_GROUPING)

  if self.addToCategoryMode and C_Cursor.GetCursorItem() == nil then
    self.addToCategoryMode = false
  end

  local characterData = Syndicator.API.GetCharacter(character)
  Baganator.CategoryViews.LayoutContainers(self, characterData.bank, "bank", Syndicator.Constants.AllBankIndexes, sideSpacing, topSpacing, function(maxWidth, maxHeight)
    self:SetSize(
      math.max(500, maxWidth + sideSpacing * 2 + Baganator.Constants.ButtonFrameOffset - 2),
      maxHeight + 75 + topSpacing / 2 + buttonPadding
    )

    local searchText = self:GetParent().SearchWidget.SearchBox:GetText()
    if self.searchToApply then
      self:ApplySearch(searchText)
    end

    Baganator.CallbackRegistry:TriggerEvent("ViewComplete")

    self:GetParent():OnTabFinished()
  end)
end
