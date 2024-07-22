local _, addonTable = ...
function addonTable.ItemViewCommon.Initialize()
  addonTable.ItemButtonUtil.UpdateSettings()

  xpcall(function()
    addonTable.InitializeOpenClose()
  end, CallErrorHandler)

  addonTable.NewItems = CreateFrame("Frame")
  Mixin(addonTable.NewItems, BaganatorItemViewCommonNewItemsTrackingMixin)
  addonTable.NewItems:OnLoad()
  addonTable.NewItems:SetScript("OnEvent", addonTable.NewItems.OnEvent)
end
