Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

Baganator.Utilities.OnAddonLoaded("Baganator", function()
  Baganator.Config.InitializeData()
  Baganator.SlashCmd.Initialize()

  Baganator.InventoryTracking.Initialize()
  if Baganator.Config.Get(Baganator.Config.Options.ENABLE_UNIFIED_BAGS) then
    Baganator.UnifiedBags.Initialize()
  end
  Baganator.CustomiseDialog.Initialize()
end)
