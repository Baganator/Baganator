Baganator.Utilities.OnAddonLoaded("Pawn", function()
  -- Equip/unequip
  Baganator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
    Baganator.CallbackRegistry:TriggerEvent("ContentRefreshRequired")
  end)
  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    Baganator.CallbackRegistry:TriggerEvent("ContentRefreshRequired")
  end)
end)
