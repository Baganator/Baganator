EventUtil.ContinueOnAddOnLoaded("Pawn", function()
  -- Equip/unequip
  hooksecurefunc("PawnCheckInventoryForUpgrades", function()
    Baganator.CallbackRegistry:TriggerEvent("ContentRefreshRequired")
  end)
  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    Baganator.CallbackRegistry:TriggerEvent("ContentRefreshRequired")
  end)
end)
