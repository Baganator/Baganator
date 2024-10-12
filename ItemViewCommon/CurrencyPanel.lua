local _, addonTable = ...
local sounds = {
  567422, -- SOUNDKIT.IG_CHARACTER_INFO_TAB
  567507, -- SOUNDKIT.IG_CHARACTER_INFO_OPEN
  567433, -- SOUNDKIT.IG_CHARACTER_INFO_CLOSE
}
local function Mute()
  for _, s in ipairs(sounds) do
    MuteSoundFile(s)
  end
end
local function Unmute()
  C_Timer.After(0, function()
    for _, s in ipairs(sounds) do
      UnmuteSoundFile(s)
    end
  end)
end

local transferImpossibleDialogName = "Baganator_TransferImpossible"
StaticPopupDialogs[transferImpossibleDialogName] = {
  text = CURRENCY_TRANSFER_DISABLED_NO_VALID_SOURCES,
  button1 = OKAY,
  timeout = 0,
  hideOnEscape = 1,
}

BaganatorCurrencyPanelMixin = {}

function BaganatorCurrencyPanelMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  addonTable.Skins.AddFrame("ButtonFrame", self)
  self:EnableMouse(true)
  self:SetPoint("CENTER")
  self:SetToplevel(true)
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  self:SetUserPlaced(false)

  self:SetSize(350, 500)

  self:SetTitle(BAGANATOR_L_CURRENCIES)

  self:RegisterEvent("CURSOR_CHANGED")

  self.isWarbandOnly = false
  self.categories = {}

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(addonTable.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsVisible() then
        addonTable.Utilities.ApplyVisuals(self)
      end
    end
  end)

  self.dropRegion = CreateFrame("Button", nil, self)
  self.dropRegion:SetAllPoints()
  self.dropRegion:Hide()
  self.dropRegion:EnableMouse(true)
  self.dropRegion:SetScript("OnReceiveDrag", function()
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
      self:TrackUntrackItem(itemID)
      ClearCursor()
    end
  end)
  self.dropRegion:SetScript("OnClick", function()
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
      self:TrackUntrackItem(itemID)
      ClearCursor()
    end
  end)

  self.searchBox = CreateFrame("EditBox", nil, self, "SearchBoxTemplate")
  self.searchBox:SetPoint("TOPLEFT", 40 + addonTable.Constants.ButtonFrameOffset, -32)
  self.searchBox:SetPoint("TOPRIGHT", -30, -32)
  self.searchBox:SetHeight(22)
  self.searchBox:SetAutoFocus(false)
  self.searchBox:HookScript("OnTextChanged", function() self:UpdateCurrencies() end)

  self.warbandOnlyButton = CreateFrame("Button", nil, self)
  self.warbandOnlyButton:SetSize(23, 31)
  self.warbandOnlyButton:SetPoint("TOPLEFT", 5 + addonTable.Constants.ButtonFrameOffset, -28)
  self.warbandOnlyButton:SetNormalAtlas("warbands-icon")
  self.warbandOnlyButton:GetNormalTexture():SetDesaturated(not self.isWarbandOnly)
  self.warbandOnlyButton:SetScript("OnEnter", function()
    self.warbandOnlyButton:GetNormalTexture():SetDesaturated(true)
    self.warbandOnlyButton:GetNormalTexture():SetDesaturation(0.5)
    GameTooltip:SetOwner(self.warbandOnlyButton, "ANCHOR_LEFT")
    GameTooltip:SetText(BAGANATOR_L_SHOW_TRANSFERABLE_ONLY)
    GameTooltip:Show()
  end)
  self.warbandOnlyButton:SetScript("OnLeave", function()
    self.warbandOnlyButton:GetNormalTexture():SetDesaturation(1)
    self.warbandOnlyButton:GetNormalTexture():SetDesaturated(not self.isWarbandOnly)
    GameTooltip:Hide()
  end)
  self.warbandOnlyButton:SetScript("OnClick", function()
    self.isWarbandOnly = not self.isWarbandOnly
    self.warbandOnlyButton:GetNormalTexture():SetDesaturated(not self.isWarbandOnly)
    self:UpdateCurrencies()
  end)

  self.scrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  local scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", self.scrollBox, "TOPRIGHT", 0, 0)
  scrollBar:SetPoint("BOTTOMLEFT", self.scrollBox, "BOTTOMRIGHT", 0, 0)
  local view = CreateScrollBoxListLinearView()
  self.scrollBox:SetPoint("TOPLEFT", addonTable.Constants.ButtonFrameOffset + 5, -57)
  self.scrollBox:SetPoint("BOTTOMRIGHT", -20, 8)
  view:SetElementExtentCalculator(function(index, details)
    if details.type == "currency" or details.type == "item" then
      return 25
    elseif details.type == "header" or details.type == "text" then
      return 30
    end
  end)
  view:SetElementInitializer("Button", function(row, details)
    self:SetupRow(row, details)
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, scrollBar, view)

  self.transferButton = self:GetTransferButton(self.scrollBox)
  self.transferButton:SetFrameStrata("DIALOG")

  addonTable.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    self.selectedCharacter = character
    if self:IsVisible() then
      self:UpdateCurrencies()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CURRENCIES_TRACKED and self.selectedCharacter and self:IsVisible() then
      self:UpdateCurrencies()
    end
  end)

  local function Update(_, character)
    if self.selectedCharacter and self:IsVisible() then
      self:UpdateCurrencies()
    end
  end
  Syndicator.CallbackRegistry:RegisterCallback("CurrencyCacheUpdate", Update)
  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", Update)
  Syndicator.CallbackRegistry:RegisterCallback("VoidCacheUpdate", Update)
end

function BaganatorCurrencyPanelMixin:OnDragStart()
  if not addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorCurrencyPanelMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local oldCorner = addonTable.Config.Get(addonTable.Config.Options.CURRENCY_PANEL_POSITION)[1]
  addonTable.Config.Set(addonTable.Config.Options.CURRENCY_PANEL_POSITION, {addonTable.Utilities.ConvertAnchorToCorner(oldCorner, self)})
  self:ClearAllPoints()
  self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.CURRENCY_PANEL_POSITION)))
end

function BaganatorCurrencyPanelMixin:OnEvent(eventName)
  if self:IsVisible() and eventName == "CURSOR_CHANGED" then
    self:UpdateForCursor()
  end
end

function BaganatorCurrencyPanelMixin:OnShow()
  addonTable.Utilities.ApplyVisuals(self)
  addonTable.ItemViewCommon.SyncCurrenciesTrackedWithBlizzard()
  self:UpdateCurrencies()
  self:UpdateForCursor()
  if C_CurrencyInfo.RequestCurrencyDataForAccountCharacters then
    C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
  end
end

function BaganatorCurrencyPanelMixin:UpdateForCursor()
  self.dropRegion:SetShown(GetCursorInfo() == "item")
  self.dropRegion:SetFrameStrata("DIALOG")
end

function BaganatorCurrencyPanelMixin:UpdateCurrencies()
  local entries = {}
  local search = self.searchBox:GetText():lower()

  if not self.selectedCharacter then
    self.selectedCharacter = Syndicator.API.GetCurrentCharacter()
  end

  local currencies = Syndicator.API.GetCharacter(self.selectedCharacter).currencies
  local currencyByHeader = Syndicator.API.GetCharacter(self.selectedCharacter).currencyByHeader
  local isLive = self.selectedCharacter == Syndicator.API.GetCurrentCharacter()
  if currencyByHeader then
    local currencyByHeaderDisplay = {}

    for _, headerDetails in ipairs(currencyByHeader) do
      for _, currencyID in ipairs(headerDetails.currencies) do
        self.categories[currencyID] = headerDetails.header
      end
    end

    local function AddCurrencyToItems(items, currencyID)
      local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
      local name = info.name
      local amount = FormatLargeNumber(currencies[currencyID])
      if amount == "0" then
        name = GRAY_FONT_COLOR:WrapTextInColorCode(name)
        amount = GRAY_FONT_COLOR:WrapTextInColorCode(amount)
      end
      if info.name:lower():match(search) and (not self.isWarbandOnly or info.isAccountTransferable) then
        table.insert(items, {type = "currency", name = name, currencyID = currencyID, amount = amount, icon = info.iconFileID, isWarband = info.isAccountWide, isWarbandTransfer = info.isAccountTransferable, isLive = isLive})
      end
    end

    local tracked = {}
    local items = {}
    for _, details in ipairs(addonTable.Config.Get(addonTable.Config.Options.CURRENCIES_TRACKED, self.selectedCharacter)) do
      if details.currencyID then
        tracked[details.currencyID] = true
        AddCurrencyToItems(items, details.currencyID)
      elseif details.itemID then
        local itemName = C_Item.GetItemNameByID(details.itemID) or " "
        if itemName:lower():match(search) and not self.isWarbandOnly then
          table.insert(items, {type = "item", name = itemName, itemID = details.itemID, amount = addonTable.ItemViewCommon.GetTrackedItemCount(details.itemID, self.selectedCharacter), icon = select(5, C_Item.GetItemInfoInstant(details.itemID)), isLive = isLive})
        end
      end
    end
    table.insert(currencyByHeaderDisplay, {header = BAGANATOR_L_TRACKED, items = items})

    if isLive then
      table.insert(currencyByHeaderDisplay[#currencyByHeaderDisplay].items, {
        type = "text",
        name = LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_ACTION_TO_TRACK_TEXT),
        disabled = true,
      })
    end

    for _, headerDetails in pairs(currencyByHeader) do
      local items = {}
      for _, currencyID in ipairs(headerDetails.currencies) do
        if not tracked[currencyID] then
          AddCurrencyToItems(items, currencyID)
        end
      end
      if #items > 0 then
        table.insert(currencyByHeaderDisplay, {header = headerDetails.header, items = items})
      end
    end

    local collapsedState = addonTable.Config.Get(addonTable.Config.Options.CURRENCY_HEADERS_COLLAPSED)
    for _, headerDetails in ipairs(currencyByHeaderDisplay) do
      if #headerDetails.items > 0 then
        table.insert(entries, {type = "header", name = headerDetails.header, collapsed = collapsedState[headerDetails.header], isLive = false})
      end
      if not collapsedState[headerDetails.header] then
        tAppendAll(entries, headerDetails.items)
      end
    end
  else
    for currencyID, amount in pairs(currencies) do
      local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
      local amount = FormatLargeNumber(amount)
      if info.name:match(search) then
        table.insert(entries, {type = "currency", name = info.name, currencyID = currencyID, amount = amount, icon = info.iconFileID, isWarband = info.isAccountWide, isWarbandTransfer = info.isAccountTransferable})
      end
    end
    table.sort(entries, function(a, b) return a.name < b.name end)
    if #entries > 0 then
      table.insert(entries, 1, {type = "header", name = UNKNOWN})
    end
  end

  self.scrollBox:SetDataProvider(CreateDataProvider(entries), true)
end

function BaganatorCurrencyPanelMixin:TrackUntrackCurrency(currencyID)
  local tracked = addonTable.Config.Get(addonTable.Config.Options.CURRENCIES_TRACKED)
  local index = FindInTableIf(tracked, function(a) return a.currencyID == currencyID end)
  if index == nil then
    table.insert(tracked, {currencyID = currencyID})
    addonTable.ItemViewCommon.SetCurrencyTrackedBlizzard(currencyID, true)
  else
    table.remove(tracked, index)
    addonTable.ItemViewCommon.SetCurrencyTrackedBlizzard(currencyID, false)
  end
  addonTable.Config.Set(addonTable.Config.Options.CURRENCIES_TRACKED, CopyTable(tracked))
end

function BaganatorCurrencyPanelMixin:TrackUntrackItem(itemID)
  local tracked = addonTable.Config.Get(addonTable.Config.Options.CURRENCIES_TRACKED)
  local index = FindInTableIf(tracked, function(a) return a.itemID == itemID end)
  if index == nil then
    table.insert(tracked, {itemID = itemID})
  else
    table.remove(tracked, index)
  end
  addonTable.Config.Set(addonTable.Config.Options.CURRENCIES_TRACKED, CopyTable(tracked))
end

function BaganatorCurrencyPanelMixin:SetupRow(row, details)
  if not row.setup then
    row.setup = true
    row:SetPushedTextOffset(0, 0)
    row:SetHighlightAtlas("search-highlight")
    row.rightText = row:CreateFontString(nil, nil, "GameFontHighlight")
    row.rightText:SetPoint("RIGHT", -35, 0)
    row.rightIcon = row:CreateTexture(nil, "ARTWORK")
    row.rightIcon:SetSize(20, 20)
    row.rightIcon:SetPoint("RIGHT", -10, 0)
    row.arrowIcon = row:CreateTexture(nil, "ARTWORK")
    row.arrowIcon:SetSize(14, 14)
    row.arrowIcon:SetPoint("LEFT", 5, 0)
    row.arrowIcon:SetAtlas("bag-arrow")
    row.warbandIcon = row:CreateTexture(nil, "ARTWORK")
    row.warbandIcon:SetSize(20, 28)
    row.warbandIcon:SetPoint("LEFT", 2, 0)
    row.warbandIcon:SetScript("OnEnter", function()
      GameTooltip:SetOwner(row.warbandIcon, "ANCHOR_RIGHT")
      GameTooltip:SetText(row.warbandIcon.text)
      row.warbandIcon:Show()
      GameTooltip:Show()
    end)
    row.warbandIcon:SetScript("OnLeave", function()
      row.warbandIcon:Hide()
      GameTooltip:Hide()
    end)
  end
  row.rightText:Hide()
  row.rightIcon:Hide()
  row.arrowIcon:Hide()
  row.warbandIcon:Hide()
  row:SetEnabled(not details.disabled)
  self.transferButton:Hide()
  self.transferButton.currencyID = nil
  row.UpdateTooltip = nil

  row:SetText(details.name)
  row:GetFontString():SetPoint("LEFT", 25, 0)
  row:GetFontString():SetPoint("RIGHT")
  if details.type == "header" then
    row:GetFontString():SetJustifyH("LEFT")
    row.arrowIcon:Show()
    row:SetNormalFontObject(GameFontNormalMed2)
    row:SetScript("OnEnter", nil)
    row:SetScript("OnLeave", nil)
    row:SetScript("OnClick", function()
      local collapsedState = addonTable.Config.Get(addonTable.Config.Options.CURRENCY_HEADERS_COLLAPSED)
      collapsedState[details.name] = not collapsedState[details.name]
      self:UpdateCurrencies()
    end)
    if details.collapsed then
      row.arrowIcon:SetRotation(-math.pi)
    else
      row.arrowIcon:SetRotation(math.pi/2)
    end
  elseif details.type == "currency" then
    row:GetFontString():SetJustifyH("LEFT")
    row.currencyID = details.currencyID
    row.rightText:Show()
    row.rightIcon:Show()
    if details.isWarband then
      row.warbandIcon:SetAtlas("warbands-icon")
      row.warbandIcon.text = ACCOUNT_LEVEL_CURRENCY
    elseif details.isWarbandTransfer then
      row.warbandIcon:SetAtlas("warbands-transferable-icon")
      row.warbandIcon.text = ACCOUNT_TRANSFERRABLE_CURRENCY
    end
    row:SetNormalFontObject(GameFontHighlight)
    row.rightText:SetText(details.amount)
    row.rightIcon:SetTexture(details.icon)
    row.rightIcon:SetTexCoord(0.08, 0.96, 0.08, 0.96)
    if GameTooltip.SetCurrencyByID then
      -- Show retail currency tooltip
      row:SetScript("OnEnter", function()
        row.warbandIcon:SetShown(details.isWarband or details.isWarbandTransfer)
        row.UpdateTooltip = function()
          GameTooltip:SetOwner(row, "ANCHOR_LEFT")
          GameTooltip:SetCurrencyByID(details.currencyID)
          if self.categories[details.currencyID] or details.isLive then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
          end
          if self.categories[details.currencyID] then
            GameTooltip:AddLine(LINK_FONT_COLOR:WrapTextInColorCode(self.categories[details.currencyID]))
          end
          if details.isLive then
            GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_SHIFT_CLICK_TO_TRACK_UNTRACK))
            if details.isWarbandTransfer and not InCombatLockdown() then
              GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_CTRL_CLICK_TO_TRANSFER))
            end
          end
          GameTooltip:Show()
        end
        row.UpdateTooltip()
        if details.isWarbandTransfer then
          self.transferButton.currencyID = details.currencyID
          self.transferButton:SetAllPoints(row)
          self.transferButton:SetShown(IsControlKeyDown() and not self.transferButton.clicked)
        end
      end)
      row:SetScript("OnClick", function()
        if IsModifiedClick("CHATLINK") and ChatEdit_InsertLink(C_CurrencyInfo.GetCurrencyLink(details.currencyID, 1)) then
          return
        end
        if details.isLive and IsShiftKeyDown() then
          self:TrackUntrackCurrency(details.currencyID)
        end
      end)
    else
      -- SetCurrencyByID doesn't exist on classic, but we want to show the
      -- other characters info via the tooltip anyway
      row:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row, "ANCHOR_LEFT")
        GameTooltip:SetText(details.name, 1, 1, 1)
        Syndicator.Tooltips.AddCurrencyLines(GameTooltip, details.currencyID)
        GameTooltip_AddBlankLineToTooltip(GameTooltip)
        GameTooltip:AddLine(LINK_FONT_COLOR:WrapTextInColorCode(self.categories[details.currencyID]))
        GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_SHIFT_CLICK_TO_TRACK_UNTRACK))
        GameTooltip:Show()
      end)
      row:SetScript("OnClick", function()
        if details.isLive and IsShiftKeyDown() then
          self:TrackUntrackCurrency(details.currencyID)
        end
      end)
    end
    row:SetScript("OnLeave", function()
      row.warbandIcon:Hide()
      GameTooltip:Hide()
    end)
  elseif details.type == "item" then
    row:GetFontString():SetJustifyH("LEFT")
    row:SetNormalFontObject(GameFontHighlight)
    row.rightText:Show()
    row.rightIcon:Show()
    row.rightIcon:SetTexture(details.icon)
    row.rightIcon:SetTexCoord(0.08, 0.96, 0.08, 0.96)
    row.rightText:SetText(details.amount)
    row:SetScript("OnEnter", function()
      GameTooltip:SetOwner(row, "ANCHOR_LEFT")
      GameTooltip:SetItemByID(details.itemID)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
      if details.isLive and IsShiftKeyDown() then
        self:TrackUntrackItem(details.itemID)
      end
    end)
  elseif details.type == "text" then
    row:SetNormalFontObject(GameFontNormalMed2)
    row:SetDisabledFontObject(GameFontNormalMed2)
    row:GetFontString():SetPoint("LEFT")
    row:GetFontString():SetJustifyH("CENTER")
  end
end

function BaganatorCurrencyPanelMixin:GetTransferButton(parent)
  local button = CreateFrame("Button", nil, parent, "InsecureActionButtonTemplate")
  button:RegisterForClicks("AnyUp", "AnyDown")
  button:SetAttribute("downbutton", "startup")
  button:SetAttribute("typerelease", "click")
  button:SetAttribute("type", "click")
  button:SetAttribute("pressAndHoldAction", true)
  button:SetAttribute("clickbutton", TokenFramePopup.CurrencyTransferToggleButton)

  button:HookScript("OnClick", function()
    button.clicked = true
    GameTooltip:Hide()
    TokenFramePopup:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 3, -28)
    if not TokenFramePopup.CurrencyTransferToggleButton:IsEnabled() then
      StaticPopup_Show(transferImpossibleDialogName)
    end
  end)

  local unusedState = {}
  if button.SetPropagateMouseMotion then
    button:SetPropagateMouseMotion(true)
  end
  button:SetScript("OnEnter", function()
    if InCombatLockdown() or button.clicked or not button.currencyID then
      return
    end

    Mute()
    local characterVisible = CharacterFrame:IsVisible()
    local tokenVisible = TokenFrame:IsVisible()
    HideUIPanel(TokenFrame)
    Unmute()

    local function Handler()
      local index = 0
      local missing = false
      while index < C_CurrencyInfo.GetCurrencyListSize() do
        index = index + 1
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info.isHeader then
          if not info.isHeaderExpanded then
            C_CurrencyInfo.ExpandCurrencyList(index, true)
          end
        else
          local link = C_CurrencyInfo.GetCurrencyListLink(index)
          if link ~= nil then
            local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
            if currencyID == button.currencyID then
              break
            end
          end
        end
      end
      TokenFrame.ScrollBox:ClearAllPoints()
      -- 30 is slightly larger than the tallest possible row in the currency
      -- panel
      TokenFrame.ScrollBox:SetHeight(30 * C_CurrencyInfo.GetCurrencyListSize())
      TokenFrame.ScrollBox:SetWidth(200)
      TokenFrame.ScrollBox:SetPoint("TOPLEFT", UIParent)

      TokenFrame.ScrollBox:RegisterCallback(BaseScrollBoxEvents.OnLayout, function()
        TokenFrame.ScrollBox:UnregisterCallback(BaseScrollBoxEvents.OnLayout, button)
        button:SetAttribute("ctrl-clickbutton-startup", TokenFrame.ScrollBox:GetFrames()[index])
        Mute()
        HideUIPanel(TokenFrame)
        if tokenVisible then
          HideUIPanel(TokenFrame)
          ShowUIPanel(TokenFrame)
        end
        if not characterVisible then
          HideUIPanel(CharacterFrame)
        end
        Unmute()
        TokenFrame.ScrollBox:ClearAllPoints()
        TokenFrame.ScrollBox:SetPoint("TOPLEFT", CharacterFrame.Inset, 4, -4)
        TokenFrame.ScrollBox:SetPoint("BOTTOMRIGHT", CharacterFrame.Inset, -22, 2)
      end, button)

      Mute()
      ShowUIPanel(CharacterFrame)
      ShowUIPanel(TokenFrame)
      Unmute()

      button:SetScript("OnUpdate", nil)
    end
    button:SetScript("OnUpdate", Handler)
    Handler()
  end)

  local function TidyUp()
    button:SetScript("OnUpdate", nil)
  end
  button:SetScript("OnLeave", TidyUp)
  button:SetScript("OnHide", TidyUp)
  button:SetScript("OnShow", function()
    button:SetFrameStrata("DIALOG")
  end)

  local handler = CreateFrame("Frame")
  handler:RegisterEvent("MODIFIER_STATE_CHANGED")
  handler:SetScript("OnEvent", function()
    button.clicked = false
    button:SetShown(IsControlKeyDown() and button.currencyID ~= nil)
  end)
  button:Hide()

  return button
end

function addonTable.ItemViewCommon.GetCurrencyPanel(frameName)
  local frame = CreateFrame("Frame", frameName, UIParent, "ButtonFrameTemplate")
  Mixin(frame, BaganatorCurrencyPanelMixin)
  frame:Hide()
  frame:OnLoad()
  frame:SetScript("OnShow", frame.OnShow)
  frame:SetScript("OnDragStart", frame.OnDragStart)
  frame:SetScript("OnDragStop", frame.OnDragStop)
  frame:SetScript("OnEvent", frame.OnEvent)
  return frame
end
