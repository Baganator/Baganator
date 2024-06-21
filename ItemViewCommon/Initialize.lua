function Baganator.ItemViewCommon.Initialize()
  Baganator.ItemButtonUtil.UpdateSettings()

  xpcall(function()
    Baganator.InitializeOpenClose()
  end, CallErrorHandler)

  Baganator.Recents = CreateFromMixins(BaganatorItemViewCommonRecentsTrackingMixin)
  Baganator.Recents:OnLoad()
end
