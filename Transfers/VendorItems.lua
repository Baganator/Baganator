local _, addonTable = ...

local waitingOnMoney = 0
local lastTime = 0

local frame = CreateFrame("Frame")
-- Avoid confirmation dialogs for sales to vendors
frame:SetScript("OnEvent", function(_, eventName)
  if eventName == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
    SellCursorItem()
  elseif eventName == "PLAYER_MONEY" then
    waitingOnMoney = waitingOnMoney - 1
  end
end)

function addonTable.Transfers.VendorItems(toSell)
  if waitingOnMoney > 0 and GetTimePreciseSec() - lastTime < 1 then
    return addonTable.Constants.SortStatus.WaitingUnlock
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

  if IsShiftKeyDown() and breakIndex ~= nil and breakIndex ~= #toSell then
    return addonTable.Constants.SortStatus.WaitingUnlock
  else
    return addonTable.Constants.SortStatus.Complete
  end
end
