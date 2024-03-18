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
  if mode == "character" then
    if container == "bag" then
      Baganator.CallbackRegistry:TriggerEvent("GuildHide")
      Baganator.CallbackRegistry:TriggerEvent("BankHide")
      Baganator.CallbackRegistry:TriggerEvent("BagShow", entity)
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
      Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
    elseif container == "bank" then
      Baganator.CallbackRegistry:TriggerEvent("GuildHide")
      Baganator.CallbackRegistry:TriggerEvent("BagHide")
      Baganator.CallbackRegistry:TriggerEvent("BankShow", entity)
      Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
      Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
    else
      StaticPopupDialogs[dialogName].text = CONTAINER_TYPE_TO_MESSAGE[container]
      StaticPopup_Show(dialogName)
      return
    end
  elseif mode == "guild" then
    Baganator.CallbackRegistry:TriggerEvent("BagHide")
    Baganator.CallbackRegistry:TriggerEvent("BankHide")
    Baganator.CallbackRegistry:TriggerEvent("GuildShow", entity)
    Baganator.CallbackRegistry:TriggerEvent("GuildSetTab", tonumber(container))
    Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  end
end)
