---@class addonTableBaganator
local addonTable = select(2, ...)

addonTable.CallbackRegistry:RegisterCallback("NewItemsAcquired", function(_, items)
  local ticker
  local waiting = {}
  for _, itemLocation in ipairs(items) do
    waiting[itemLocation] = true
  end
  ticker = C_Timer.NewTicker(0.05, function()
    local refresh = false
    for itemLocation in pairs(waiting) do
      if not C_Item.DoesItemExist(itemLocation) then
        waiting[itemLocation] = nil
      elseif C_Item.CanBeRefunded(itemLocation) then
        waiting[itemLocation] = nil
        refresh = true
      end
    end
    if next(waiting) == nil then
      ticker:Cancel()
    end
    if refresh then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end, 10)
end)
