Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

EventUtil.ContinueOnAddOnLoaded("Baganator", function()
  Baganator.Config.InitializeData()
  Baganator.SlashCmd.Initialize()

  Baganator.InitializeInventoryTracking()
  Baganator.InitializeUnifiedBags()
  Baganator.InitializeCustomiseDialog()
end)
