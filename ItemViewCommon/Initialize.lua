function Baganator.ItemViewCommon.Initialize()
  Baganator.ItemButtonUtil.UpdateSettings()

  xpcall(function()
    Baganator.InitializeOpenClose()
  end, CallErrorHandler)

  Baganator.NewItems = CreateFrame("Frame")
  Mixin(Baganator.NewItems, BaganatorItemViewCommonNewItemsTrackingMixin)
  Baganator.NewItems:OnLoad()
  Baganator.NewItems:SetScript("OnEvent", Baganator.NewItems.OnEvent)
end
