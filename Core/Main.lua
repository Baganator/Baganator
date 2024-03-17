Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

local syndicatorEnableDialog = "BaganatorSyndicatorRequiredInstalledDialog"
StaticPopupDialogs[syndicatorEnableDialog] = {
  text = BAGANATOR_L_SYNDICATOR_ENABLE_MESSAGE,
  button1 = ENABLE,
  button2 = CANCEL,
  OnAccept = function()
    if C_AddOns.DoesAddOnExist("Syndicator") then
      C_AddOns.EnableAddOn("Syndicator")
      C_UI.Reload()
    end
  end,
  timeout = 0,
  hideOnEscape = 1,
}

local syndicatorInstallDialog = "BaganatorSyndicatorRequiredMissingDialog"
StaticPopupDialogs[syndicatorInstallDialog] = {
  text = BAGANATOR_L_SYNDICATOR_INSTALL_MESSAGE,
  button1 = OKAY,
  timeout = 0,
  hideOnEscape = 1,
}

Baganator.Utilities.OnAddonLoaded("Baganator", function()
  if not C_AddOns.IsAddOnLoaded("Syndicator") then
    if C_AddOns.DoesAddOnExist("Syndicator") then
      Baganator.Utilities.Message(BAGANATOR_L_SYNDICATOR_ENABLE_MESSAGE)
      StaticPopup_Show(syndicatorEnableDialog)
    else
      Baganator.Utilities.Message(BAGANATOR_L_SYNDICATOR_INSTALL_MESSAGE)
      StaticPopup_Show(syndicatorInstallDialog)
    end
    return
  end

  Baganator.Config.InitializeData()
  Baganator.SlashCmd.Initialize()

  Baganator.UnifiedViews.Initialize()

  Baganator.CustomiseDialog.Initialize()
end)
