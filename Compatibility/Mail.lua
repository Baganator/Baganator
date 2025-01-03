local _, addonTable = ...

addonTable.Compatibility.SendMailShowing = false
hooksecurefunc("SetSendMailShowing", function(state)
  addonTable.Compatibility.SendMailShowing = state
  addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
end)
