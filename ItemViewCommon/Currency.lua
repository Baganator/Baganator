local _, addonTable = ...
BaganatorCurrencyWidgetMixin = {}

function BaganatorCurrencyWidgetMixin:OnLoad()
  self.currencyPool = CreateFontStringPool(self, "BACKGROUND", 0, "GameFontHighlight")

  Syndicator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate",  function(_, character)
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
      self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
    end
  end)

  -- Update currencies when they are watched/unwatched in Blizz UI
  EventRegistry:RegisterCallback("TokenFrame.OnTokenWatchChanged", function()
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
      self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
    end
  end)

  -- Needed to get currencies to load correctly on classic versions of WoW
  addonTable.Utilities.OnAddonLoaded("Blizzard_TokenUI", function()
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
      self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
    end

    -- Wrath Classic
    if ManageBackpackTokenFrame then
      hooksecurefunc("ManageBackpackTokenFrame", function()
        if self.lastCharacter then
          self:UpdateCurrencies(self.lastCharacter)
          self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
        end
      end)
    end
  end)

  local frame = CreateFrame("Frame", nil, self)
  local function UpdateMoneyDisplay()
    if IsShiftKeyDown() then
      addonTable.ShowGoldSummaryAccount(self.Money, "ANCHOR_TOP")
    else
      addonTable.ShowGoldSummaryRealm(self.Money, "ANCHOR_TOP")
    end
  end
  self.Money:SetScript("OnEnter", function()
    UpdateMoneyDisplay()
    frame:RegisterEvent("MODIFIER_STATE_CHANGED")
    frame:SetScript("OnEvent", UpdateMoneyDisplay)
  end)

  self.Money:SetScript("OnLeave", function()
    frame:UnregisterEvent("MODIFIER_STATE_CHANGED")
    GameTooltip:Hide()
  end)
end

function BaganatorCurrencyWidgetMixin:OnShow()
  if self.currencyUpdateNeeded and self.lastCharacter then
    self:UpdateCurrencies(self.lastCharacter)
    self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
  end
end

local function ShowCurrencies(self, character)
  self.Money:SetText(addonTable.Utilities.GetMoneyString(Syndicator.API.GetCharacter(character).money, true))

  local characterCurrencies = Syndicator.API.GetCharacter(character).currencies

  if not C_CurrencyInfo then
    return
  end

  if not characterCurrencies then
    for _, c in ipairs(self.Currencies) do
      c:SetText("")
    end
    return
  end

  self.currencyPool:ReleaseAll()

  self.activeCurrencyTexts = {}

  local prev = self.Money
  for i = 1, addonTable.Constants.MaxPinnedCurrencies do
    local currencyID, icon
    if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
      local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
      if currencyInfo then
        currencyID = currencyInfo.currencyTypesID
        icon = currencyInfo.iconFileID
      end
    elseif GetBackpackCurrencyInfo then
      icon, currencyID = select(3, GetBackpackCurrencyInfo(i))
    end

    local currencyText = ""

    if currencyID ~= nil then
      local fontString = self.currencyPool:Acquire()
      local count = 0
      if characterCurrencies[currencyID] ~= nil then
        count = characterCurrencies[currencyID]
      end

      currencyText = BreakUpLargeNumbers(count)
      if strlenutf8(currencyText) > 5 then
        currencyText = AbbreviateNumbers(count)
      end
      currencyText = currencyText .. " " .. CreateSimpleTextureMarkup(icon, 12, 12)
      if GameTooltip.SetCurrencyByID then
        -- Show retail currency tooltip
        fontString:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetCurrencyByID(currencyID)
        end)
        fontString:SetScript("OnMouseDown", function(self)
          if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(C_CurrencyInfo.GetCurrencyLink(currencyID, count))
          end
        end)
      else
        -- SetCurrencyByID doesn't exist on classic, but we want to show the
        -- other characters info via the tooltip anyway
        fontString:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          Syndicator.Tooltips.AddCurrencyLines(GameTooltip, currencyID)
        end)
      end
      fontString:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
      fontString:SetText(currencyText)
      fontString:SetPoint("RIGHT", prev, "LEFT", -15, 0)
      table.insert(self.activeCurrencyTexts, fontString)
      prev = fontString
    end
  end
end

function BaganatorCurrencyWidgetMixin:UpdateCurrencyTextVisibility(offsetLeft)
  if not offsetLeft then
    return
  end

  self.lastOffsetLeft = offsetLeft

  if self:GetParent():GetLeft() == nil then
    return
  end

  for _, fs in ipairs(self.activeCurrencyTexts) do
    fs:SetShown(fs:GetLeft() > self:GetParent():GetLeft() + offsetLeft)
  end
end

function BaganatorCurrencyWidgetMixin:UpdateCurrencies(character)
  self.lastCharacter = character
  local start = debugprofilestop()
  if self:IsVisible() then
    self.currencyUpdateNeeded = false
    ShowCurrencies(self, character)
  else
    self.currencyUpdateNeeded = true
  end
  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
    print("currency update", debugprofilestop() - start)
  end
end
