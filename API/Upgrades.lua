local _, addonTable = ...
local IsEquipment = Syndicator and Syndicator.Utilities.IsEquipment

-- Equip/unequip
Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
  if addonTable.API.UpgradePlugins[addonTable.Config.Get("upgrade_plugin")] ~= nil then
    Baganator.API.RequestItemButtonsRefresh()
  end
end)

-- Level up
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:SetScript("OnEvent", function()
  if addonTable.API.UpgradePlugins[addonTable.Config.Get("upgrade_plugin")] ~= nil then
    Baganator.API.RequestItemButtonsRefresh()
  end
end)

addonTable.Utilities.OnAddonLoaded("SimpleItemLevel", function()
  Baganator.API.RegisterUpgradePlugin("Simple Item Levels", "simple_item_levels", function(itemLink)
    return SimpleItemLevel.API.ItemIsUpgrade(itemLink)
  end)
end)

addonTable.Utilities.OnAddonLoaded("Pawn", function()
  local upgradeCache = {}
  Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
    upgradeCache = {}
  end)
  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    if Baganator.API.IsUpgradePluginActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
  -- Settings change
  hooksecurefunc("PawnResetTooltips", function()
    if Baganator.API.IsUpgradePluginActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)

  local pending = {}
  local frame = CreateFrame("Frame")
  function frame:OnUpdate()
    for itemLink in pairs(pending) do
      local result = PawnShouldItemLinkHaveUpgradeArrow(itemLink)
      if result ~= nil then
        pending[itemLink] = nil
        upgradeCache[itemLink] = result
      end
    end
    if next(pending) == nil then
      self:SetScript("OnUpdate", nil)
      Baganator.API.RequestItemButtonsRefresh()
    end
  end

  Baganator.API.RegisterUpgradePlugin("Pawn", "pawn", function(itemLink)
    local result = upgradeCache[itemLink]
    if result ~= nil then
      return result
    end

    result = addonTable.API.ShouldPawnShow(itemLink) and PawnShouldItemLinkHaveUpgradeArrow(itemLink)
    if result == nil then
      pending[itemLink] = true
      frame:SetScript("OnUpdate", frame.OnUpdate)
    else
      upgradeCache[itemLink] = result
    end

    return result
  end)
end)
