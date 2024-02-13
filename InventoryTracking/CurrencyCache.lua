BaganatorCurrencyCacheMixin = {}

-- Assumed to run after PLAYER_LOGIN
function BaganatorCurrencyCacheMixin:OnLoad()
  self:RegisterEvent("PLAYER_MONEY")

  self.currentCharacter = Baganator.Utilities.GetCharacterFullName()

  BAGANATOR_DATA.Characters[self.currentCharacter].money = GetMoney()

  if not Baganator.Constants.IsEra then
    -- no currencies available on era
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:ScanAllCurrencies()
  end
end

function BaganatorCurrencyCacheMixin:OnEvent(eventName, ...)
  if eventName == "CURRENCY_DISPLAY_UPDATE" then
    -- We do not use the quantity argument in the event as it is wrong for
    -- Conquest currency changes
    local currencyID = ...
    if currencyID ~= nil then
      local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
      BAGANATOR_DATA.Characters[self.currentCharacter].currencies[currencyID] = info.quantity

      self:SetScript("OnUpdate", self.OnUpdate)
    else
      self:ScanAllCurrencies()
    end
  elseif eventName == "PLAYER_MONEY" then
    BAGANATOR_DATA.Characters[self.currentCharacter].money = GetMoney()
    Baganator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
  end
end

function BaganatorCurrencyCacheMixin:ScanAllCurrencies()
  local currencies = {}

  if Baganator.Constants.IsRetail then
    local index = 0
    local toCollapse = {}
    while index < C_CurrencyInfo.GetCurrencyListSize() do
      index = index + 1
      local info = C_CurrencyInfo.GetCurrencyListInfo(index)
      if info.isHeader then
        if not info.isHeaderExpanded then
          table.insert(toCollapse, index)
          C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
          currencies[currencyID] = info.quantity
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1 do
        C_CurrencyInfo.ExpandCurrencyList(toCollapse[index], false)
      end
    end
  else -- Only versions of classic with currency (due to checks earlier)
    local index = 0
    local toCollapse = {}
    while index < GetCurrencyListSize() do
      index = index + 1
      local _, isHeader, isHeaderExpanded, _, _, quantity = GetCurrencyListInfo(index)
      if isHeader then
        if not isHeaderExpanded then
          table.insert(toCollapse, index)
          ExpandCurrencyList(index, 1)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
          if currencyID ~= nil then
            currencies[currencyID] = quantity
          end
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1 do
        ExpandCurrencyList(toCollapse[index], 0)
      end
    end
  end

  BAGANATOR_DATA.Characters[self.currentCharacter].currencies = currencies

  self:SetScript("OnUpdate", self.OnUpdate)
end

-- Event is fired in OnUpdate to avoid multiple events per-frame
function BaganatorCurrencyCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  Baganator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
end
