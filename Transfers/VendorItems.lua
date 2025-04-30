---@class addonTableBaganator
local addonTable = select(2, ...)

-- Used to delay vendoring the next set of items until they'll probably succeed
local waitingOnMoney = 0
local lastTime = 0
-- Persist Shift down status across successive vendoring for the same set of
-- items
local shiftLock = false
local shiftTime = 0

function addonTable.Transfers.VendorItems(toSell)
  if GetTimePreciseSec() - lastTime < 1 then
    shiftTime = GetTimePreciseSec()
    return addonTable.Constants.SortStatus.WaitingUnlock
  elseif GetTimePreciseSec() - shiftTime >= 1 then
    shiftLock = false
  end

  local sold = 0
  local breakIndex
  for index, item in ipairs(toSell) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) and not C_Container.GetContainerItemInfo(item.bagID, item.slotID).hasNoValue then
      ClearCursor()
      C_Container.PickupContainerItem(item.bagID, item.slotID)
      SellCursorItem()
      sold = sold + 1
      if sold >= 6 then
        breakIndex = index
        break
      end
    end
  end
  if sold == 0 then
    UIErrorsFrame:AddMessage(addonTable.Locales.THE_MERCHANT_DOESNT_WANT_ANY_OF_THOSE_ITEMS, 1.0, 0.1, 0.1, 1.0)
  end

  waitingOnMoney = sold
  lastTime = GetTimePreciseSec()
  shiftTime = GetTimePreciseSec()

  if (shiftLock or IsShiftKeyDown()) and breakIndex ~= nil and breakIndex ~= #toSell then
    shiftLock = true
    return addonTable.Constants.SortStatus.WaitingUnlock
  else
    shiftLock = false
    return addonTable.Constants.SortStatus.Complete
  end
end
