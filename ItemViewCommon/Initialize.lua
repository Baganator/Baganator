function Baganator.ItemViewCommon.Initialize()
  Baganator.ItemButtonUtil.UpdateSettings()

  xpcall(function()
    Baganator.InitializeOpenClose()
  end, CallErrorHandler)

  Baganator.NewItems = CreateFromMixins(BaganatorItemViewCommonNewItemsTrackingMixin)
  Baganator.NewItems:OnLoad()
end
