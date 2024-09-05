local _, addonTable = ...
if not Syndicator then
  return
end

addonTable.Utilities.OnAddonLoaded("Pawn", function()
  local upgradeCache = {}
  Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
    if Baganator.API.IsCornerWidgetActive("pawn") or Baganator.API.IsUpgradePluginActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
      upgradeCache = {}
    end
  end)

  function addonTable.API.ShouldPawnShow(itemLink)
    local classID = select(6, C_Item.GetItemInfoInstant(itemLink))
    return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
  end

  -- Level up
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LEVEL_UP")
  frame:SetScript("OnEvent", function()
    if Baganator.API.IsCornerWidgetActive("pawn") or Baganator.API.IsUpgradePluginActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)

  -- Spec change
  hooksecurefunc("PawnInvalidateBestItems", function()
    if Baganator.API.IsCornerWidgetActive("pawn") or Baganator.API.IsUpgradePluginActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)
  -- Settings change
  hooksecurefunc("PawnResetTooltips", function()
    if Baganator.API.IsCornerWidgetActive("pawn") or Baganator.API.IsUpgradePluginActive("pawn") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end)

  local limit = 2 / 60 / 4
  local resetInterval = 1 / 4
  local timerResetsAt = 0
  local left = 0
  local function GetPawnUpgradeStatus(itemLink)
    if upgradeCache[itemLink] ~= nil then
      return upgradeCache[itemLink]
    end

    local start = GetTimePreciseSec()

    if start >= timerResetsAt then
      timerResetsAt = start + resetInterval
      left = limit
    elseif left <= 0 then
      return nil
    end

    local result = PawnShouldItemLinkHaveUpgradeArrowUnbudgeted(itemLink)
    local elapsed = GetTimePreciseSec() - start

    left = left - elapsed
    if result ~= nil then
      upgradeCache[itemLink] = result
      return result
    end

    if C_Item.IsItemDataCachedByID(itemLink) then
      upgradeCache[itemLink] = false
      return false
    end
    return nil
  end

  local pending = {}
  local frame = CreateFrame("Frame")
  function frame:OnUpdate()
    for itemLink in pairs(pending) do
      local result = GetPawnUpgradeStatus(itemLink)
      if result ~= nil then
        pending[itemLink] = nil
      end
    end
    if next(pending) == nil then
      self:SetScript("OnUpdate", nil)
      Baganator.API.RequestItemButtonsRefresh()
    end
  end

  Baganator.API.RegisterCornerWidget(BAGANATOR_L_PAWN, "pawn", function(Arrow, details)
    return addonTable.API.ShouldPawnShow(details.itemLink) and GetPawnUpgradeStatus(details.itemLink)
  end, function(itemButton)
    local Arrow = itemButton:CreateTexture(nil, "OVERLAY")
    Arrow:SetTexture("Interface\\AddOns\\Pawn\\Textures\\UpgradeArrow")
    Arrow:SetSize(13.5, 15)
    return Arrow
  end, {corner = "top_left", priority = 1})

  Baganator.API.RegisterUpgradePlugin("Pawn", "pawn", function(itemLink)
    local result = upgradeCache[itemLink]
    if result ~= nil then
      return result
    end

    result = addonTable.API.ShouldPawnShow(itemLink) and GetPawnUpgradeStatus(itemLink)
    if result == nil then
      pending[itemLink] = true
      frame:SetScript("OnUpdate", frame.OnUpdate)
    else
      upgradeCache[itemLink] = result
    end

    return result
  end)
end)
