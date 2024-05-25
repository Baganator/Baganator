if not Syndicator then
  return
end

local CONTAINER_TYPE_TO_MESSAGE = {
  equipped = BAGANATOR_L_THAT_ITEM_IS_EQUIPPED,
  auctions = BAGANATOR_L_THAT_ITEM_IS_LISTED_ON_THE_AUCTION_HOUSE,
  mail = BAGANATOR_L_THAT_ITEM_IS_IN_A_MAILBOX,
  void = BAGANATOR_L_THAT_ITEM_IS_IN_VOID_STORAGE,
}

local dialogName = "Baganator_InventoryItemInX"
StaticPopupDialogs[dialogName] = {
  text = "",
  button1 = OKAY,
  timeout = 0,
  hideOnEscape = 1,
}

Syndicator.API.RegisterShowItemLocation(function(mode, entity, container, itemLink, searchText)
  StaticPopup_Hide(dialogName)

  local self = {}

  Baganator.CallbackRegistry:RegisterCallback("ViewComplete", function()
    Baganator.CallbackRegistry:UnregisterCallback("ViewComplete", self)
    Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  end, self)

  if mode == "character" then
    if container == "bag" then
      Baganator.CallbackRegistry:TriggerEvent("GuildHide")
      Baganator.CallbackRegistry:TriggerEvent("BankHide")
      Baganator.CallbackRegistry:TriggerEvent("BagShow", entity)
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    elseif container == "bank" then
      Baganator.CallbackRegistry:TriggerEvent("GuildHide")
      Baganator.CallbackRegistry:TriggerEvent("BagHide")
      Baganator.CallbackRegistry:TriggerEvent("BankShow", entity)
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    else
      StaticPopupDialogs[dialogName].text = CONTAINER_TYPE_TO_MESSAGE[container]
      StaticPopup_Show(dialogName)
      Baganator.CallbackRegistry:UnregisterCallback("ViewComplete", self)
      return
    end
  elseif mode == "guild" then
    Baganator.CallbackRegistry:TriggerEvent("BagHide")
    Baganator.CallbackRegistry:TriggerEvent("BankHide")
    Baganator.CallbackRegistry:TriggerEvent("GuildShow", entity, tonumber(container))
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  elseif mode == "warband" then
    Baganator.CallbackRegistry:TriggerEvent("GuildHide")
    Baganator.CallbackRegistry:TriggerEvent("BagHide")
    Baganator.CallbackRegistry:TriggerEvent("BankShow", tonumber(entity), tonumber(container))
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
  else
    Baganator.CallbackRegistry:UnregisterCallback("ViewComplete", self)
    return
  end
end)

BaganatorSearchWidgetMixin = {}

function BaganatorSearchWidgetMixin:OnLoad()
  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
    if self.SearchBox:GetText() == "" then
      self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
    end
  end)
  self.SearchBox.clearButton:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end)

  self.GlobalSearchButton:Disable()

  Baganator.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.SearchBox:SetText(text)
    self.GlobalSearchButton:SetEnabled(text ~= "")
  end)
end

function BaganatorSearchWidgetMixin:OnShow()
  self.SearchBox.Instructions:SetText(Baganator.Utilities.GetRandomSearchesText())
end

function BaganatorSearchWidgetMixin:OnHide()
  if self.SearchBox:GetText() ~= "" then
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end
  Syndicator.Search.ClearCache()
end

function BaganatorSearchWidgetMixin:SetSpacing(sideSpacing)
  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", self:GetParent(), -sideSpacing - 36, 0)
  self.SearchBox:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", sideSpacing + Baganator.Constants.ButtonFrameOffset + 5, - 28)
  self.GlobalSearchButton:ClearAllPoints()
  self.GlobalSearchButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 3, 0)
end
