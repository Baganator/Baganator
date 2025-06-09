---@class addonTableBaganator
local addonTable = select(2, ...)
BaganatorCurrencyWidgetMixin = {}

function addonTable.ItemViewCommon.GetTrackedItemCount(itemID, character)
  for _, info in ipairs(Syndicator.API.GetInventoryInfoByItemID(itemID, false, false).characters) do
    if info.character .. "-" .. info.realmNormalized == character then
      return info.bags + info.bank + info.void
    end
  end

  return 0
end

function BaganatorCurrencyWidgetMixin:OnLoad()
  self.currencyPool = CreateFontStringPool(self, "BACKGROUND", 0, "GameFontHighlight")
  -- Using an (in)secure button to avoid taint of the transfer functionality
  -- when accessing currency panel
  self.currencyButtons = CreateFramePool("Button", self, nil, nil, false, function(b)
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

  local function Update(_, _)
    if self.lastCharacter then
      self:UpdateCurrencies(self.lastCharacter)
      self:UpdateCurrencyTextPositions(self.allowedWidth, self.nextRowWidth)
    end
  end
  Syndicator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate", Update)
  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", Update)
  Syndicator.CallbackRegistry:RegisterCallback("VoidCacheUpdate", Update)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CURRENCIES_TRACKED then
      if self.lastCharacter then
        self:UpdateCurrencies(self.lastCharacter)
        self:UpdateCurrencyTextPositions(self.allowedWidth, self.nextRowWidth)
      end
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
    self:UpdateCurrencyTextPositions(self.allowedWidth, self.nextRowWidth)
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

  for _, details in ipairs(addonTable.Config.Get(addonTable.Config.Options.CURRENCIES_TRACKED, character)) do
    local fontString = self.currencyPool:Acquire()
    fontString.button = self.currencyButtons:Acquire()
    fontString.button:SetAllPoints(fontString)
    if details.currencyID then
      local count = 0
      if characterCurrencies[details.currencyID] ~= nil then
        count = characterCurrencies[details.currencyID]
      end

      local currencyText = BreakUpLargeNumbers(count)
      if strlenutf8(currencyText) > 5 then
        currencyText = AbbreviateNumbers(count)
      end
      currencyText = currencyText .. " " .. CreateTextureMarkup(C_CurrencyInfo.GetCurrencyInfo(details.currencyID).iconFileID, 14, 14, 12, 12, 0.08, 0.96, 0.08, 0.96)
      fontString:SetText(currencyText)

      if GameTooltip.SetCurrencyByID then
        -- Show retail currency tooltip
        fontString.button:SetScript("OnEnter", function()
          GameTooltip:SetOwner(fontString, "ANCHOR_RIGHT")
          GameTooltip:SetCurrencyByID(details.currencyID)
        end)
        fontString.button:SetScript("OnMouseDown", function()
          local GetCurrencyLink = C_CurrencyInfo.GetCurrencyLink or GetCurrencyLink
          if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(GetCurrencyLink(details.currencyID, count))
          end
        end)
      else
        -- SetCurrencyByID doesn't exist on classic, but we want to show the
        -- other characters info via the tooltip anyway
        fontString.button:SetScript("OnEnter", function()
          GameTooltip:SetOwner(fontString, "ANCHOR_RIGHT")
          Syndicator.Tooltips.AddCurrencyLines(GameTooltip, details.currencyID)
        end)
      end
    elseif details.itemID then
      local count = addonTable.ItemViewCommon.GetTrackedItemCount(details.itemID, character)
      local currencyText = BreakUpLargeNumbers(count)

      if strlenutf8(currencyText) > 5 then
        currencyText = AbbreviateNumbers(count)
      end
      local _, _, _, _, icon = C_Item.GetItemInfoInstant(details.itemID)
      currencyText = currencyText .. " " .. CreateTextureMarkup(icon, 14, 14, 12, 12, 0.08, 0.96, 0.08, 0.96)
      fontString:SetText(currencyText)

      fontString.button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(fontString, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(details.itemID)
      end)
    end
    fontString.button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    table.insert(self.activeCurrencyTexts, fontString)
  end
end

function BaganatorCurrencyWidgetMixin:UpdateCurrencyTextPositions(allowedWidth, nextRowWidth)
  if not allowedWidth then
    return
  end
  nextRowWidth = nextRowWidth or allowedWidth

  self.allowedWidth = allowedWidth
  self.nextRowWidth = nextRowWidth

  local baseX, baseY = -10, 10
  local xDiff, yDiff = -15, 20
  local root = self:GetParent()
  local offsetX, offsetY = -self.Money:GetWidth() + xDiff, 0

  if self.allowedWidth < self.Money:GetWidth() then
    offsetY = offsetY + yDiff
    allowedWidth = nextRowWidth
    self.Money:SetPoint("BOTTOMRIGHT", root, 0 + baseX, offsetY + baseY)
  else
    self.Money:SetPoint("BOTTOMRIGHT", root, -10, 10)
  end

  for _, fs in ipairs(self.activeCurrencyTexts) do
    if math.abs(offsetX - fs:GetWidth()) > allowedWidth then
      offsetY = offsetY + yDiff
      offsetX = 0
      allowedWidth = nextRowWidth
    end
    fs:SetPoint("BOTTOMRIGHT", root, offsetX + baseX, offsetY + baseY)
    offsetX = offsetX + xDiff - fs:GetWidth()
    fs:Show()
    fs.button:Show()
  end

  local old = self.lastOffsetY
  self.lastOffsetY = offsetY
  if old ~= offsetY then
    self:GetParent():OnFinished()
  end
end

function BaganatorCurrencyWidgetMixin:GetExtraHeight()
  return self.lastOffsetY or 0
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
