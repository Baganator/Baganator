Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

EventUtil.ContinueOnAddOnLoaded("Baganator", function()
  Baganator.Config.InitializeData()
  Baganator.SlashCmd.Initialize()

  Baganator.InitializeInventoryTracking()
  if Baganator.Config.Get(Baganator.Config.Options.ENABLE_UNIFIED_BAGS) then
    Baganator.InitializeUnifiedBags()
  end
  Baganator.InitializeCustomiseDialog()
end)
