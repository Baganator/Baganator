local _, addonTable = ...

-- Used to delay vendoring the next set of items until they'll probably succeed
local waitingOnMoney = 0
local lastTime = 0
-- Persist Shift down status across successive vendoring for the same set of
-- items
local shiftLock = false

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, eventName)
  if eventName == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
    -- Avoid confirmation dialogs for sales to vendors
    SellCursorItem()
  elseif eventName == "PLAYER_MONEY" then
    waitingOnMoney = waitingOnMoney - 1
  end
end)

function addonTable.Transfers.VendorItems(toSell)
  local timeout = GetTimePreciseSec() - lastTime >= 1
  if waitingOnMoney > 0 and not timeout then
    return addonTable.Constants.SortStatus.WaitingUnlock
  elseif timeout then
    shiftLock = false
  end

  frame:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
  local sold = 0
  local breakIndex
  for index, item in ipairs(toSell) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) and not C_Container.GetContainerItemInfo(item.bagID, item.slotID).hasNoValue then
      C_Container.UseContainerItem(item.bagID, item.slotID)
      sold = sold + 1
      if sold >= 6 then
        breakIndex = index
        break
      end
    end
  end
  if sold == 0 then
    UIErrorsFrame:AddMessage(BAGANATOR_L_THE_MERCHANT_DOESNT_WANT_ANY_OF_THOSE_ITEMS, 1.0, 0.1, 0.1, 1.0)
  end
  frame:UnregisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")

  waitingOnMoney = sold
  lastTime = GetTimePreciseSec()

  if (IsShiftKeyDown() or shiftLock) and breakIndex ~= nil and breakIndex ~= #toSell then
    shiftLock = true
    return addonTable.Constants.SortStatus.WaitingUnlock
  else
    shiftLock = false
    return addonTable.Constants.SortStatus.Complete
  end
end
