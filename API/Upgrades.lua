local _, addonTable = ...

if not Syndicator then
  return
end

local IsEquipment = Syndicator and Syndicator.Utilities.IsEquipment

-- Equip/unequip
Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
  if addonTable.API.UpgradePlugins[addonTable.Config.Get("upgrade_plugin")] ~= nil then
    Baganator.API.RequestItemButtonsRefresh()
  end
end)

addonTable.Utilities.OnAddonLoaded("SimpleItemLevel", function()
  Baganator.API.RegisterUpgradePlugin("Simple Item Levels", "simple_item_levels", function(itemLink)
    return SimpleItemLevel.API.ItemIsUpgrade(itemLink)
  end)

  -- Level up
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LEVEL_UP")
  frame:SetScript("OnEvent", function()
    if Baganator.API.IsUpgradePluginActive("simple_item_levels") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
end)
