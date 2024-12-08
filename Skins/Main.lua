local _, addonTable = ...

addonTable.Skins.allFrames = {}
addonTable.Skins.availableSkins = {}
addonTable.Skins.currentOptions = {}
addonTable.Skins.skinListeners = {}

function addonTable.Skins.Initialize()
  local autoEnabled = nil
  local chooseSkinValues = {}
  for key, skin in pairs(addonTable.Skins.availableSkins) do
    table.insert(chooseSkinValues, skin.key)
    for _, opt in ipairs(skin.options) do
      addonTable.Config.Install("skins." .. key .. "." .. opt.option, opt.default)
    end
    if skin.autoEnable and not addonTable.Config.Get(addonTable.Config.Options.DISABLED_SKINS)[key] then
      autoEnabled = key
    end
  end
  if autoEnabled then
    addonTable.Config.Set(addonTable.Config.Options.CURRENT_SKIN, autoEnabled)
  end

  table.sort(chooseSkinValues)
  local chooseSkinEntries = {}
  for _, key in ipairs(chooseSkinValues) do
    table.insert(chooseSkinEntries, addonTable.Skins.availableSkins[key].label)
  end

  table.insert(addonTable.Skins.currentOptions, {
    type = "dropdown",
    text = BAGANATOR_L_THEME_RELOAD_REQUIRED,
    option = "current_skin",
    entries = chooseSkinEntries,
    values = chooseSkinValues,
  })

  local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
  if addonTable.WagoAnalytics then
    addonTable.WagoAnalytics:Switch("UsingSkin", currentSkinKey ~= "default")
  end

  local currentSkin = addonTable.Skins.availableSkins[currentSkinKey]
  if not currentSkin then
    addonTable.Config.ResetOne(addonTable.Config.Options.CURRENT_SKIN)
    currentSkin = addonTable.Skins.availableSkins[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
  end
  xpcall(currentSkin.initializer, CallErrorHandler)

  for _, opt in ipairs(currentSkin.options) do
    if opt.option then
      opt.option = "skins." .. currentSkin.key .. "." .. opt.option
    end
    table.insert(addonTable.Skins.currentOptions, opt)
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CURRENT_SKIN then
      local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
      for key, skin in pairs(addonTable.Skins.availableSkins) do
        if skin.autoEnable then
          addonTable.Config.Get(addonTable.Config.Options.DISABLED_SKINS)[key] = currentSkinKey ~= key
        end
      end
    end
  end)
end

function addonTable.Skins.AddFrame(regionType, region, tags)
  if not region.added then
    local details = {regionType = regionType, region = region, tags = tags}
    table.insert(addonTable.Skins.allFrames, details)
    if addonTable.Skins.skinListeners then
      for _, listener in ipairs(addonTable.Skins.skinListeners) do
        xpcall(listener, CallErrorHandler, details)
      end
    end
    region.added = true
  end
end

function addonTable.Skins.RegisterSkin(label, key, initializer, options, autoEnable)
  addonTable.Skins.availableSkins[key] = {
    label = label,
    key = key,
    initializer = initializer,
    options = options or {},
    autoEnable = autoEnable,
  }
end

function addonTable.Skins.RegisterListener(callback)
  table.insert(addonTable.Skins.skinListeners, callback)
  if addonTable.WagoAnalytics then
    addonTable.WagoAnalytics:Switch("UsingSkin", true)
  end
end

function addonTable.Skins.GetAllFrames()
  return addonTable.Skins.allFrames
end

Baganator.Skins = { AddFrame = addonTable.Skins.AddFrame }
