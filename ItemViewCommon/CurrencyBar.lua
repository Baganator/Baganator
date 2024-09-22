local _, addonTable = ...
BaganatorCurrencyWidgetMixin = {}

function BaganatorCurrencyWidgetMixin:OnLoad()
  self.currencyPool = CreateFontStringPool(self, "BACKGROUND", 0, "GameFontHighlight")
  -- Using an (in)secure button to avoid taint of the transfer functionality
  -- when accessing currency panel
  self.currencyButtons = CreateFramePool("Button", self, nil, function(_, b)
    if b.setup then
      return
    end
    b.setup = true

    b:SetScript("OnClick", function()
      addonTable.CallbackRegistry:TriggerEvent("CurrencyPanelToggle")
    end)
  end)

  self.activeCurrencyTexts = {}

  self.cacheBackpackCurrenciesNeeded = true

  Syndicator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate",  function(_, character)
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
      self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
      self:UpdateCurrencyTextVisibility(self.lastOffsetLeft)
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
  addonTable.ItemViewCommon.SyncCurrenciesTrackedWithBlizzard()
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

  self.activeCurrencyTexts = {}
  self.currencyPool:ReleaseAll()
  self.currencyButtons:ReleaseAll()

  if not characterCurrencies then
    return
  end

  local prev = self.Money

  for _, details in ipairs(addonTable.Config.Get(addonTable.Config.Options.CURRENCIES_TRACKED, character)) do
    local fontString = self.currencyPool:Acquire()
    local count = 0
    if characterCurrencies[details.currencyID] ~= nil then
      count = characterCurrencies[details.currencyID]
    end

    local currencyText = BreakUpLargeNumbers(count)
    if strlenutf8(currencyText) > 5 then
      currencyText = AbbreviateNumbers(count)
    end
    currencyText = currencyText .. " " .. CreateSimpleTextureMarkup(C_CurrencyInfo.GetCurrencyInfo(details.currencyID).iconFileID, 12, 12)
    fontString:SetText(currencyText)

    fontString.button = self.currencyButtons:Acquire()
    if GameTooltip.SetCurrencyByID then
      -- Show retail currency tooltip
      fontString.button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetCurrencyByID(details.currencyID)
      end)
      fontString.button:SetScript("OnMouseDown", function(self)
        if IsModifiedClick("CHATLINK") then
          ChatEdit_InsertLink(C_CurrencyInfo.GetCurrencyLink(details.currencyID, count))
        end
      end)
    else
      -- SetCurrencyByID doesn't exist on classic, but we want to show the
      -- other characters info via the tooltip anyway
      fontString.button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        Syndicator.Tooltips.AddCurrencyLines(GameTooltip, details.currencyID)
      end)
    end
    fontString.button:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
    fontString.button:SetAllPoints(fontString)
    fontString:SetPoint("RIGHT", prev, "LEFT", -15, 0)
    table.insert(self.activeCurrencyTexts, fontString)
    prev = fontString
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
    local show = fs:GetLeft() > self:GetParent():GetLeft() + offsetLeft
    fs:SetShown(show)
    fs.button:SetShown(show)
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
    addonTable.Utilities.DebugOutput("currency update", debugprofilestop() - start)
  end
end
