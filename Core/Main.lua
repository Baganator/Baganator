---@class addonTableBaganator
local addonTable = select(2, ...)
addonTable.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addonTable.CallbackRegistry:OnLoad()
addonTable.CallbackRegistry:GenerateCallbackEvents(addonTable.Constants.Events)

Baganator.CallbackRegistry = addonTable.CallbackRegistry

function addonTable.Core.MigrateSettings()
  if addonTable.Config.Get(addonTable.Config.Options.GLOBAL_VIEW_TYPE) ~= "unset" then
    addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, addonTable.Config.Get(addonTable.Config.Options.GLOBAL_VIEW_TYPE))
    addonTable.Config.Set(addonTable.Config.Options.BANK_VIEW_TYPE, addonTable.Config.Get(addonTable.Config.Options.GLOBAL_VIEW_TYPE))
    addonTable.Config.Set(addonTable.Config.Options.GLOBAL_VIEW_TYPE, "unset")
  end
  if not addonTable.Config.Get(addonTable.Config.Options.MIGRATED_SORT_METHOD) then
    local sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)
    if sortMethod ~= "combine_stacks_only" and not addonTable.API.ExternalContainerSorts[sortMethod] then
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_SORT_METHOD, sortMethod)
    end
    addonTable.Config.Set(addonTable.Config.Options.MIGRATED_SORT_METHOD, true)
  end

  addonTable.CategoryViews.SetupData()

  addonTable.Skins.InstallOptions()

  addonTable.API.ApplyJunkPluginsInitial()
  addonTable.API.ApplyUpgradePluginsInitial()
  addonTable.API.ApplyCornerPluginsInitial()
end

addonTable.Utilities.OnAddonLoaded("Baganator", function()
  if not C_AddOns.IsAddOnLoaded("Syndicator") then
    if C_AddOns.DoesAddOnExist("Syndicator") then
      addonTable.Utilities.Message(addonTable.Locales.SYNDICATOR_ENABLE_MESSAGE)
      C_Timer.After(1, function()
        addonTable.Dialogs.ShowConfirm(addonTable.Locales.SYNDICATOR_ENABLE_MESSAGE, ENABLE, CANCEL, function()
          C_AddOns.EnableAddOn("Syndicator")
          C_UI.Reload()
        end)
      end)
      error(addonTable.Locales.SYNDICATOR_ENABLE_MESSAGE)
    else
      addonTable.Utilities.Message(addonTable.Locales.SYNDICATOR_INSTALL_MESSAGE)
      C_Timer.After(1, function()
        addonTable.Dialogs.ShowAcknowledge(addonTable.Locales.SYNDICATOR_INSTALL_MESSAGE)
      end)
      error(addonTable.Locales.SYNDICATOR_INSTALL_MESSAGE)
    end
    return
  end

  if SYNDICATOR_DATA then
    BAGANATOR_DATA = nil
  end

  addonTable.Config.InitializeData()
  addonTable.SlashCmd.Initialize()

  addonTable.ItemViewCommon.Initialize()

  addonTable.CategoryViews.Initialize()

  addonTable.ViewManagement.Initialize()

  addonTable.CustomiseDialog.Initialize()

  addonTable.Skins.Initialize()

  if addonTable.Config.Get(addonTable.Config.Options.SEEN_WELCOME) < 1 then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function()
      frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
      -- Show after Syndicator has started
      C_Timer.After(0, function()
        C_Timer.After(0, function()
          addonTable.ShowWelcome()
        end)
      end)
    end)
  end

  addonTable.Core.MigrateSettings()

  addonTable.Core.RunAnalytics()
end)

function addonTable.ReportEntry()
  addonTable.lastEntryTime = GetTimePreciseSec()
end

function addonTable.CheckTimeout()
  return GetTimePreciseSec() - addonTable.lastEntryTime > 0.1
end
