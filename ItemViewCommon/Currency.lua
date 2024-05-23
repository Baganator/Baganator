BaganatorCurrencyWidgetMixin = {}

function BaganatorCurrencyWidgetMixin:OnLoad()
  Syndicator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate",  function(_, character)
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
    end
  end)

  -- Update currencies when they are watched/unwatched in Blizz UI
  EventRegistry:RegisterCallback("TokenFrame.OnTokenWatchChanged", function()
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
    end
  end)

  -- Needed to get currencies to load correctly on classic versions of WoW
  Baganator.Utilities.OnAddonLoaded("Blizzard_TokenUI", function()
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
    end

    -- Wrath Classic
    if ManageBackpackTokenFrame then
      hooksecurefunc("ManageBackpackTokenFrame", function()
        if self.lastCharacter then
          self:UpdateCurrencies(self.lastCharacter)
        end
      end)
    end
  end)

  local frame = CreateFrame("Frame", nil, self)
  local function UpdateMoneyDisplay()
    if IsShiftKeyDown() then
      Baganator.ShowGoldSummaryAccount(self.Money, "ANCHOR_TOP")
    else
      Baganator.ShowGoldSummaryRealm(self.Money, "ANCHOR_TOP")
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
  end
end

local function ShowCurrencies(self, character)
  self.Money:SetText(Baganator.Utilities.GetMoneyString(Syndicator.API.GetCharacter(character).money, true))

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

  for i = 1, Baganator.Constants.MaxPinnedCurrencies do
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
        self.Currencies[i]:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetCurrencyByID(currencyID)
        end)
      else
        -- SetCurrencyByID doesn't exist on classic, but we want to show the
        -- other characters info via the tooltip anyway
        self.Currencies[i]:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          Syndicator.Tooltips.AddCurrencyLines(GameTooltip, currencyID)
        end)
      end
      self.Currencies[i]:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    else
      self.Currencies[i]:SetScript("OnEnter", nil)
    end
    self.Currencies[i]:SetText(currencyText)
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
  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("currency update", debugprofilestop() - start)
  end
end
