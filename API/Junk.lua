---@class addonTableBaganator
local addonTable = select(2, ...)
Baganator.API.RegisterJunkPlugin(NONE, "none", function()
  return false
end)

--[[addonTable.Utilities.OnAddonLoaded("Peddler", function()
  if not PeddlerAPI then
    return
  end

  Baganator.API.RegisterJunkPlugin(addonTable.Locales.PEDDLER, "peddler", function(bagID, slotID)
    local itemID, uniqueItemID, isSoulbound = PeddlerAPI.getUniqueItemID(bagID, slotID)

    return uniqueItemID and PeddlerAPI.itemIsToBeSold(itemID, uniqueItemID, isSoulbound)
  end)
end)]]

addonTable.Utilities.OnAddonLoaded("SellJunk", function()
  Baganator.API.RegisterJunkPlugin(addonTable.Locales.SELLJUNK, "selljunk", function(bagID, slotID, _, itemLink)
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
  Baganator.API.RegisterJunkPlugin(addonTable.Locales.SCRAP, "scrap", function(bagID, slotID, itemID, _)
    return Scrap:IsJunk(itemID, bagID, slotID)
  end)
  hooksecurefunc(Scrap, "ToggleJunk", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
end)

addonTable.Utilities.OnAddonLoaded("Vendor", function()
  Baganator.API.RegisterJunkPlugin(addonTable.Locales.VENDOR, "vendor", function(bagID, slotID, _, _)
    return Vendor.EvaluateItem(bagID, slotID) ~= 0
  end)

  local extension = {
    Addon = addonTable.Locales.BAGANATOR,
    Source = addonTable.Locales.BAGANATOR,
    Version = 1.0,
    OnRuleUpdate = function()
      Baganator.API.RequestItemButtonsRefresh()
    end,
  }
  C_Timer.After(0, function()
    Vendor.RegisterExtension(extension)
  end)
end)

addonTable.Utilities.OnAddonLoaded("Dejunk", function()
  if not DejunkApi or not DejunkApi.Events then
    return
  end

  Baganator.API.RegisterJunkPlugin("Dejunk", "dejunk", function(bagID, slotID, _, _)
    return DejunkApi:IsJunk(bagID, slotID)
  end)
  DejunkApi:AddListener(function(event)
    if event ~= DejunkApi.Events.BagsUpdated then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
end)
