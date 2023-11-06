BaganatorBankOnlyViewMixin = {}
function BaganatorBankOnlyViewMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)

  FrameUtil.RegisterFrameForEvents(self, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })

  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    self:SetLiveCharacter(character)
    if self:IsShown() then
      self:UpdateForCharacter(character, updatedBags)
    else
      self:NotifyBagUpdate(updatedBags)
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if not self.liveCharacter then
      return
    end
    if tIndexOf(Baganator.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsShown() then
        Baganator.Utilities.ApplyVisuals(self)
      end
    elseif tIndexOf(Baganator.Config.ItemButtonsRelayoutSettings, settingName) ~= nil then
      for _, layout in ipairs(self.Layouts) do
        layout:InformSettingChanged(settingName)
      end
      if self:IsShown() then
        self:UpdateForCharacter(self.liveCharacter)
      end
    elseif settingName == Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS then
      self:UpdateBagSlots()
    end
  end)

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self:ApplySearch(text)
  end)

  local function GetBankBagButton()
    if Baganator.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailBankButtonTemplate")
    else
      return CreateFrame("Button", nil, self, "BaganatorClassicBankButtonTemplate")
    end
  end

  self.bankBagSlots = {}
  for index = 1, Baganator.Constants.BankBagsCount do
    local bb = GetBankBagButton()
    table.insert(self.bankBagSlots, bb)
    bb:SetID(index)
    if #self.bankBagSlots == 1 then
      bb:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
    else
      bb:SetPoint("TOPLEFT", self.bankBagSlots[#self.bankBagSlots - 1], "TOPRIGHT")
    end
  end
end

function BaganatorBankOnlyViewMixin:OnHide()
  Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  Baganator.Search.ClearCache()
end

function BaganatorBankOnlyViewMixin:OnDragStart()
  if not Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorBankOnlyViewMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION, {point, x, y})
end

function BaganatorBankOnlyViewMixin:ToggleReagents()
  Baganator.Config.Set(Baganator.Config.Options.SHOW_REAGENTS, not Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS))
end

function BaganatorBankOnlyViewMixin:ToggleBagSlots()
  Baganator.Config.Set(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS, not Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS))
end

function BaganatorBankOnlyViewMixin:ApplySearch(text)
  self.SearchBox:SetText(text)

  if not self:IsShown() then
    return
  end

  self.BankLive:ApplySearch(text)
  self.ReagentBankLive:ApplySearch(text)
end

function BaganatorBankOnlyViewMixin:OnEvent(eventName)
  if eventName == "BANKFRAME_OPENED" then
    self:Show()
    if self.liveCharacter then
      self:UpdateForCharacter(self.liveCharacter)
    end
  else
    self:Hide()
  end
end

function BaganatorBankOnlyViewMixin:UpdateBagSlots()
  local show = Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS)
  for _, bb in ipairs(self.bankBagSlots) do
    bb:Init()
    bb:SetShown(show)
  end
end

function BaganatorBankOnlyViewMixin:OnHide(eventName)
  CloseBankFrame()
end

function BaganatorBankOnlyViewMixin:SetLiveCharacter(character)
  self.liveCharacter = character
end

function BaganatorBankOnlyViewMixin:UpdateForCharacter(character, updatedBags)
  self:UpdateBagSlots()

  updatedBags = updatedBags or {bags = {}, bank = {}}

  Baganator.Utilities.ApplyVisuals(self)

  local searchText = self.SearchBox:GetText()

  local bankIndexesToUse = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true
  }
  local reagentBankIndexesToUse = {}
  if Baganator.Constants.IsRetail and IsReagentBankUnlocked() then
    reagentBankIndexesToUse = {
      [9] = true
    }
  end

  self.SortButton:SetShown(Baganator.Utilities.ShouldShowSortButton())

  self:NotifyBagUpdate(updatedBags)

  local bankWidth = Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH)
  local showReagents = Baganator.Config.Get(Baganator.Config.Options.SHOW_REAGENTS)

  self.BankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, bankIndexesToUse, bankWidth)
  self.BankLive:ApplySearch(searchText)

  self.ReagentBankLive:ShowCharacter(character, "bank", Baganator.Constants.AllBankIndexes, reagentBankIndexesToUse, bankWidth)
  self.ReagentBankLive:ApplySearch(searchText)

  self.ReagentBankLive:SetShown(self.ReagentBankLive:GetHeight() > 0 and showReagents)

  self.ToggleReagentsBankButton:SetShown(self.ReagentBankLive:GetHeight() > 0)
  self.DepositIntoReagentsBankButton:SetShown(self.ReagentBankLive:GetHeight() > 0)
  self.BuyReagentBankButton:SetShown(Baganator.Constants.IsRetail and not IsReagentBankUnlocked())
  local reagentBankHeight = self.ReagentBankLive:GetHeight()
  if reagentBankHeight > 0 then
    if self.ReagentBankLive:IsShown() then
      reagentBankHeight = reagentBankHeight + 40
    else
      reagentBankHeight = 30
    end
  elseif self.BuyReagentBankButton:IsShown() then
    reagentBankHeight = 30
  end

  self:SetSize(
    self.BankLive:GetWidth() + 30,
    self.BankLive:GetHeight() + reagentBankHeight + 55
  )
  -- 300 is the default searchbox width
  self.SearchBox:SetWidth(math.min(300, self.BankLive:GetWidth() - 5))

  local characterData = BAGANATOR_DATA.Characters[character]
  if not characterData then
    self:SetTitle("")
  else
    self:SetTitle(BAGANATOR_L_XS_BANK:format(characterData.details.character))
  end
end

function BaganatorBankOnlyViewMixin:NotifyBagUpdate(updatedBags)
  self.BankLive:MarkBagsPending("bank", updatedBags)
  self.ReagentBankLive:MarkBagsPending("bank", updatedBags)
end
