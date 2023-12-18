Baganator.Utilities.OnAddonLoaded("Pawn", function()
  -- Equip/unequip
  Baganator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
end)
