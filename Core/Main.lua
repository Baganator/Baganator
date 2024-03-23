Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

local syndicatorEnableDialog = "BaganatorSyndicatorRequiredInstalledDialog"
StaticPopupDialogs[syndicatorEnableDialog] = {
  text = BAGANATOR_L_SYNDICATOR_ENABLE_MESSAGE,
  button1 = ENABLE,
  button2 = CANCEL,
  OnAccept = function()
    (C_AddOns and C_AddOns.EnableAddOn or EnableAddOn)("Syndicator")
    C_UI.Reload()
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

local function DoesAddOnExist(addon)
  for i = 1, GetNumAddOns() do
    if GetAddOnInfo(i) == addon then
      return true
    end
  end
  return false
end

Baganator.Utilities.OnAddonLoaded("Baganator", function()
  if not (C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded)("Syndicator") then
    if (C_AddOns and C_AddOns.DoesAddOnExist or DoesAddOnExist)("Syndicator") then
      Baganator.Utilities.Message(BAGANATOR_L_SYNDICATOR_ENABLE_MESSAGE)
      StaticPopup_Show(syndicatorEnableDialog)
      error(BAGANATOR_L_SYNDICATOR_ENABLE_MESSAGE)
    else
      Baganator.Utilities.Message(BAGANATOR_L_SYNDICATOR_INSTALL_MESSAGE)
      StaticPopup_Show(syndicatorInstallDialog)
      error(BAGANATOR_L_SYNDICATOR_INSTALL_MESSAGE)
    end
    return
  end

  if SYNDICATOR_DATA then
    BAGANATOR_DATA = nil
  end

  Baganator.Config.InitializeData()
  Baganator.SlashCmd.Initialize()

  Baganator.UnifiedViews.Initialize()

  Baganator.CustomiseDialog.Initialize()
end)
