Baganator.Utilities.OnAddonLoaded("Peddler", function()
  if not PeddlerAPI then
    return
  end

  Baganator.API.RegisterJunkPlugin(BAGANATOR_L_PEDDLER, "peddler", function(itemLink, itemID, isBound, quality)
    local _, itemID, _, _, _, _, _, suffixID = strsplit(":", itemLink)
    itemID = tonumber(itemID)
    suffixID = tonumber(suffixID)

    if not itemID then
      return false
    end

    local uniqueItemID = itemID
    if suffixID and suffixID ~= 0 then
      uniqueItemID = itemID .. suffixID
    end

    return PeddlerAPI.itemIsToBeSold(itemID, uniqueItemID, isBound)
  end)
end)

Baganator.Utilities.OnAddonLoaded("SellJunk", function()
  Baganator.API.RegisterJunkPlugin(BAGANATOR_L_SELLJUNK, "selljunk", function(itemLink, itemID, isBound, quality)
    -- is it grey quality item?
    local grey = quality == Enum.ItemQuality.Poor

    -- is it an armor or weapon?
    local _, _, _, _, _, sType, _, _ = GetItemInfo(itemLink);
    local armor_weapon = ((sType == "Armor") or (sType == "Weapon"));

    -- ignore soulbound configuration
    local ignoreSoulbound = SellJunk.db.char.ignoreSoulbound

    if grey and (not SellJunk:isException(itemLink)) then
      if (not armor_weapon) or (armor_weapon and isBound) or (ignoreSoulbound) then
        return true
      end
    end

    if (not grey) and (SellJunk:isException(itemLink)) then
      return true
    end

    return false
  end)
  hooksecurefunc(SellJunk, "Add", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
  hooksecurefunc(SellJunk, "Rem", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
end)

Baganator.Utilities.OnAddonLoaded("Scrap", function()
  Baganator.API.RegisterJunkPlugin(BAGANATOR_L_SCRAP, "scrap", function(itemLink, itemID, isBound, quality)
    return Scrap:IsJunk(itemID)
  end)
  hooksecurefunc(Scrap, "ToggleJunk", function()
    Baganator.API.RequestItemButtonsRefresh()
  end)
end)
