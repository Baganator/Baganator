local _, addonTable = ...

BaganatorSplitViewBackpackViewMixin = {}

function BaganatorSplitViewBackpackViewMixin:OnLoad()
  self.bags = {}
  for _, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    local b = CreateFrame("Frame", self:GetName() .. "Bag" .. bagID, self, "BaganatorSplitViewBagTemplate")
    b:SetID(bagID)
    table.insert(self.bags, b)
  end

  addonTable.CallbackRegistry:RegisterCallback("BagCacheAfterNewItemsUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    self.searchToApply = true
    for _, b in ipairs(self.bags) do
      b:NotifyBagUpdate(updatedBags)
    end
    if self:IsVisible() then
      self:UpdateForCharacter(character, true)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    if character ~= self.lastCharacter then
      if self:IsVisible() then
        self:UpdateForCharacter(character, self.liveCharacter == character)
      end
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.searchToApply = true
    self:ApplySearch(text)
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.lastCharacter then
      return
    end
    if tIndexOf(addonTable.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsVisible() then
        addonTable.Utilities.ApplyVisuals(self)
      end
    elseif tIndexOf(addonTable.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, b in ipairs(self.bags) do
        for _, layout in ipairs(b.Layouts) do
          layout:InformSettingChanged(settingName)
        end
      end
      if self:IsVisible() then
        self:UpdateForCharacter(self.lastCharacter, self.isLive)
      end
    end
  end)
end

function BaganatorSplitViewBackpackViewMixin:ApplySearch(text)
  if not self:IsVisible() then
    return
  end
  self.searchToApply = false

  for _, b in ipairs(self.bags) do
    b:ApplySearch(text)
  end
end

function BaganatorSplitViewBackpackViewMixin:GetSearchMatches()
  local matches = {}
  for _, bag in ipairs(self.bags) do
    tAppendAll(matches, bag.BagLive.SearchMonitor:GetMatches())
  end
  return matches
end

function BaganatorSplitViewBackpackViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorSplitViewBackpackViewMixin:UpdateForCharacter(character, isLive)
  local start = debugprofilestop()

  local characterData = Syndicator.API.GetCharacter(character)

  local oldLast = self.lastCharacter
  self.lastCharacter = character
  self.isLive = isLive

  --[[self.BagSlots:Update(self.lastCharacter, self.isLive)
  local containerInfo = characterData.containerInfo
  self.ToggleBagSlotsButton:SetShown(self.isLive or (containerInfo and containerInfo.bags))
  ]]

  if oldLast ~= character then
    addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", character)
  end

  --[[
  self.SortButton:SetShown(addonTable.Utilities.ShouldShowSortButton() and isLive)
  self:UpdateTransferButton()

  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  self.SearchWidget:SetSpacing(sideSpacing)

  if self.CurrencyWidget.lastCharacter ~= self.lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(character)
  end
  ]]
  self.Hotbar:SetPoint("TOPLEFT", self.bags[1], "TOPRIGHT")
  self.Hotbar:UpdateAll()

  local maxY, minY, minX, maxX = 0, 0, 0, 0
  local prevB
  for _, b in ipairs(self.bags) do
    b:UpdateForCharacter(character, isLive)

    if b:IsShown() then
      if prevB then
        b:SetPoint("BOTTOMRIGHT", prevB, "TOPRIGHT", 0, 20)
        if b:GetTop() >= (UIParent:GetTop() - 200) then
          b:SetPoint("BOTTOM", self.bags[1], "BOTTOM")
          b:SetPoint("RIGHT", prevB, "LEFT", -20, 0)
        end
        maxY = math.max(maxY, b:GetTop())
      else
        b:SetPoint("BOTTOMRIGHT", UIParent, -100, 90)
        maxY = b:GetTop()
        minY = b:GetBottom()
        maxX = b:GetRight()
      end
      prevB = b
    end
  end
  minX = prevB:GetLeft()
  self.Hotbar:UpdateAll()
  self.Hotbar:Show()

  self:SetSize(maxX - minX + self.Hotbar:GetWidth() + 20, maxY - minY + 20)
  self:ClearAllPoints()
  self:SetPoint("BOTTOMRIGHT", UIParent, -50, 90)

  if self.searchToApply then
    --self:ApplySearch(self.Hotbar.SearchWidget.SearchBox:GetText())
  end
end
