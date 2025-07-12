if not Syndicator then
  return
end

Syndicator.CallbackRegistry:RegisterCallback("AuctionValueSourceChanged", function()
  Baganator.API.RequestItemButtonsRefresh({Baganator.Constants.RefreshReason.Searches})
end)
