Baganator.Utilities.OnAddonLoaded("Pawn", function()
  -- Equip/unequip
  Baganator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
    if Baganator.API.IsCornerWidgetActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    if Baganator.API.IsCornerWidgetActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
end)

Baganator.Utilities.OnAddonLoaded("CanIMogIt", function()
  local function Callback()
    if Baganator.API.IsCornerWidgetActive("can_i_mog_it") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end
  CanIMogIt:RegisterMessage("OptionUpdate", function()
    pcall(Callback)
  end)
end)
