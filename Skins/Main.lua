---@class addonTableBaganator
local addonTable = select(2, ...)

addonTable.Skins.availableSkins = {}
addonTable.Skins.skinListeners = {}
addonTable.Skins.allFrames = {}

local currentSkinner = function() end

function addonTable.Skins.InstallOptions()
  for key, skin in pairs(addonTable.Skins.availableSkins) do
    for _, opt in ipairs(skin.options) do
      addonTable.Config.Install("skins." .. key .. "." .. opt.option, opt.default)
    end
  end
end

function addonTable.Skins.Initialize()
  addonTable.Skins.InstallOptions()

  local autoEnabled = nil
  for key, skin in pairs(addonTable.Skins.availableSkins) do
    if skin.autoEnable and not addonTable.Config.Get(addonTable.Config.Options.DISABLED_SKINS)[key] then
      autoEnabled = key
    end
  end
  if autoEnabled then
    addonTable.Config.Set(addonTable.Config.Options.CURRENT_SKIN, autoEnabled)
  end

  local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)

  local currentSkin = addonTable.Skins.availableSkins[currentSkinKey]
  if not currentSkin then
    addonTable.Config.ResetOne(addonTable.Config.Options.CURRENT_SKIN)
    currentSkin = addonTable.Skins.availableSkins[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    frame:UnregisterEvent("PLAYER_LOGIN")
    currentSkin.constants()
    xpcall(currentSkin.initializer, CallErrorHandler)
    currentSkinner = currentSkin.skinner
    addonTable.ViewManagement.GenerateFrameGroup(currentSkinKey)
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CURRENT_SKIN then
      local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
      for key, skin in pairs(addonTable.Skins.availableSkins) do
        if skin.autoEnable then
          addonTable.Config.Get(addonTable.Config.Options.DISABLED_SKINS)[key] = currentSkinKey ~= key
        end
      end
      local bagsShown = addonTable.ViewManagement.GetBackpackFrame():IsShown()
      local lastCharacter = addonTable.ViewManagement.GetBackpackFrame().lastCharacter
      currentSkin = addonTable.Skins.availableSkins[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
      currentSkinner = currentSkin.skinner
      currentSkin.constants()
      if not currentSkin.initialized then
        xpcall(currentSkin.initializer, CallErrorHandler)
        currentSkin.initialized = true
      end
      addonTable.ViewManagement.GenerateFrameGroup(currentSkinKey)
      if bagsShown then
        addonTable.CallbackRegistry:TriggerEvent("BagShow", lastCharacter)
      end
      addonTable.CallbackRegistry:TriggerEvent("ShowCustomise")
    end
  end)
end

function addonTable.Skins.AddFrame(regionType, region, tags)
  if not region.added then
    local details = {regionType = regionType, region = region, tags = tags}
    table.insert(addonTable.Skins.allFrames, details)
    xpcall(currentSkinner, CallErrorHandler, details)
    if addonTable.Skins.skinListeners then
      for _, listener in ipairs(addonTable.Skins.skinListeners) do
        xpcall(listener, CallErrorHandler, details)
      end
    end
    region.added = true
  end
end

function addonTable.Skins.RegisterSkin(label, key, initializer, skinner, constants, options, autoEnable)
  addonTable.Skins.availableSkins[key] = {
    label = label,
    key = key,
    initializer = initializer,
    skinner = skinner,
    constants = constants,
    options = options or {},
    autoEnable = autoEnable,
  }
end

Baganator.Skins = { AddFrame = addonTable.Skins.AddFrame }
