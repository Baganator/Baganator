local _, addonTable = ...
function addonTable.Transfers.AddToTrade(toMove)
  if #toMove == 0 then
    return
  end

  local tradeSlot = 1
  local missing = false
  local moveAttempted = false
  for _, item in ipairs(toMove) do
    while select(2, GetTradePlayerItemInfo(tradeSlot)) do
      tradeSlot = tradeSlot + 1
    end
    if tradeSlot > 6 then
      break
    end
    moveAttempted = true
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if not C_Item.DoesItemExist(location) then
      missing = true
    elseif not C_Item.IsLocked(location) then
      C_Container.PickupContainerItem(item.bagID, item.slotID)
      ClickTradeButton(tradeSlot)
      ClearCursor()
    end
  end

  if not moveAttempted then
    UIErrorsFrame:AddMessage(BAGANATOR_L_CANNOT_ADD_ANY_MORE_ITEMS_TO_THIS_TRADE, 1.0, 0.1, 0.1, 1.0)
  end

  if missing then
    return addonTable.Constants.SortStatus.WaitingMove
  else
    return addonTable.Constants.SortStatus.Complete
  end
end
