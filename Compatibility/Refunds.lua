local _, addonTable = ...
addonTable.CallbackRegistry:RegisterCallback("NewItemsAcquired", function(_, items)
  local ticker
  ticker = C_Timer.NewTicker(0.05, function()
    for _, itemLocation in ipairs(items) do
      if C_Item.DoesItemExist(itemLocation) and C_Item.CanBeRefunded(itemLocation) then
        ticker:Cancel()
        Baganator.API.RequestItemButtonsRefresh()
      end
    end
  end, 10)
end)
