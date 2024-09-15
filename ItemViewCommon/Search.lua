local _, addonTable = ...
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

  addonTable.CallbackRegistry:RegisterCallback("ViewComplete", function()
    addonTable.CallbackRegistry:UnregisterCallback("ViewComplete", self)
    addonTable.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  end, self)

  if mode == "character" then
    if container == "bag" then
      addonTable.CallbackRegistry:TriggerEvent("GuildHide")
      addonTable.CallbackRegistry:TriggerEvent("BankHide")
      addonTable.CallbackRegistry:TriggerEvent("BagShow", entity)
      addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    elseif container == "bank" then
      addonTable.CallbackRegistry:TriggerEvent("GuildHide")
      addonTable.CallbackRegistry:TriggerEvent("BagHide")
      addonTable.CallbackRegistry:TriggerEvent("BankShow", entity)
      addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    else
      StaticPopupDialogs[dialogName].text = CONTAINER_TYPE_TO_MESSAGE[container]
      StaticPopup_Show(dialogName)
      addonTable.CallbackRegistry:UnregisterCallback("ViewComplete", self)
      return
    end
  elseif mode == "guild" then
    addonTable.CallbackRegistry:TriggerEvent("BagHide")
    addonTable.CallbackRegistry:TriggerEvent("BankHide")
    addonTable.CallbackRegistry:TriggerEvent("GuildShow", entity, tonumber(container))
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    addonTable.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  elseif mode == "warband" then
    addonTable.CallbackRegistry:TriggerEvent("GuildHide")
    addonTable.CallbackRegistry:TriggerEvent("BagHide")
    if addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB) == 0 then
      addonTable.CallbackRegistry:TriggerEvent("BankShow", tonumber(entity), 0)
    else
      addonTable.CallbackRegistry:TriggerEvent("BankShow", tonumber(entity), tonumber(container))
    end
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
  else
    addonTable.CallbackRegistry:UnregisterCallback("ViewComplete", self)
    return
  end
end)

BaganatorSearchWidgetMixin = {}

function BaganatorSearchWidgetMixin:OnLoad()
  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
    if self.SearchBox:GetText() == "" then
      self.SearchBox.Instructions:SetText(addonTable.Utilities.GetRandomSearchesText())
    end
  end)
  self.SearchBox:HookScript("OnKeyDown", function(_, key)
    if key == "LALT" or key == "RALT" or key == "ALT" then
      addonTable.CallbackRegistry:TriggerEvent("PropagateAlt")
    end
  end)
  self.SearchBox:HookScript("OnKeyUp", function(_, key)
    if key == "LALT" or key == "RALT" or key == "ALT" then
      addonTable.CallbackRegistry:TriggerEvent("PropagateAlt")
    end
  end)
  self.SearchBox.clearButton:SetScript("OnClick", function()
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end)

  self.GlobalSearchButton:Disable()
  self.GlobalSearchButton.Icon:SetDesaturated(true)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.SearchBox:SetText(text)
    self.GlobalSearchButton:SetEnabled(text ~= "")
    self.GlobalSearchButton.Icon:SetDesaturated(not self.GlobalSearchButton:IsEnabled())
  end)

  self.HelpButton:SetScript("OnClick", function()
    addonTable.Help.ShowSearchDialog()
  end)

  addonTable.Skins.AddFrame("SearchBox", self.SearchBox)
end

function BaganatorSearchWidgetMixin:OnShow()
  self.SearchBox.Instructions:SetText(addonTable.Utilities.GetRandomSearchesText())
end

function BaganatorSearchWidgetMixin:OnHide()
  if self.SearchBox:GetText() ~= "" then
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end
  Syndicator.Search.ClearCache()
end

function BaganatorSearchWidgetMixin:SetSpacing(sideSpacing)
  self.SearchBox:ClearAllPoints()
  self.SearchBox:SetPoint("RIGHT", self:GetParent(), -sideSpacing - 71, 0)
  self.SearchBox:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset + 5, - 28)
  self.GlobalSearchButton:ClearAllPoints()
  self.GlobalSearchButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 3, 0)
  self.HelpButton:ClearAllPoints()
  self.HelpButton:SetPoint("LEFT", self.GlobalSearchButton, "RIGHT", 3, 0)
end
