local _, addonTable = ...
Baganator.API.RegisterJunkPlugin(NONE, "none", function(bagID, slotID, ...)
  return false
end)

addonTable.Utilities.OnAddonLoaded("Peddler", function()
  if not PeddlerAPI then
    return
  end

  Baganator.API.RegisterJunkPlugin(BAGANATOR_L_PEDDLER, "peddler", function(bagID, slotID, ...)
    local itemID, uniqueItemID, isSoulbound, itemLink = PeddlerAPI.getUniqueItemID(bagID, slotID)

    return uniqueItemID and PeddlerAPI.itemIsToBeSold(itemID, uniqueItemID, isSoulbound)
  end)
end)

addonTable.Utilities.OnAddonLoaded("SellJunk", function()
  Baganator.API.RegisterJunkPlugin(BAGANATOR_L_SELLJUNK, "selljunk", function(bagID, slotID, itemID, itemLink)
    return SellJunk:CheckItemIsJunk(itemLink, bagID, slotID)
  end)
  hooksecurefunc(SellJunk, "Add", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
  hooksecurefunc(SellJunk, "Rem", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
end)

addonTable.Utilities.OnAddonLoaded("Scrap", function()
  Baganator.API.RegisterJunkPlugin(BAGANATOR_L_SCRAP, "scrap", function(bagID, slotID, itemID, itemLink)
    return Scrap:IsJunk(itemID, bagID, slotID)
  end)
  hooksecurefunc(Scrap, "ToggleJunk", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
end)

if addonTable.Constants.IsRetail then
  addonTable.Utilities.OnAddonLoaded("Vendor", function()
    Baganator.API.RegisterJunkPlugin(BAGANATOR_L_VENDOR, "vendor", function(bagID, slotID, itemID, itemLink)
      return Vendor.EvaluateItem(bagID, slotID) ~= 0
    end)

    local extension = {
      Addon = BAGANATOR_L_BAGANATOR,
      Source = BAGANATOR_L_BAGANATOR,
      Version = 1.0,
      OnRuleUpdate = function()
        Baganator.API.RequestItemButtonsRefresh()
      end,
    }
    C_Timer.After(0, function()
      Vendor.RegisterExtension(extension)
    end)
  end)
end

addonTable.Utilities.OnAddonLoaded("Dejunk", function()
  if not DejunkApi or not DejunkApi.Events then
    return
  end

  Baganator.API.RegisterJunkPlugin("Dejunk", "dejunk", function(bagID, slotID, itemID, itemLink)
    return DejunkApi:IsJunk(bagID, slotID)
  end)
  DejunkApi:AddListener(function(event)
    if event ~= DejunkApi.Events.BagsUpdated then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
end)
