Baganator.Utilities.OnAddonLoaded("Pawn", function()
  -- Equip/unequip
  Baganator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_PAWN_ARROW) then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_PAWN_ARROW) then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
end)

Baganator.Utilities.OnAddonLoaded("CanIMogIt", function()
  local function Callback()
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_CIMI_ICON) then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end
  CanIMogIt:RegisterMessage("OptionUpdate", function()
    pcall(Callback)
  end)
end)
