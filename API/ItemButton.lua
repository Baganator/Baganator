local iconSettings = {}

local IsEquipment = Baganator.Utilities.IsEquipment

local qualityColors = {
  [0] = CreateColor(157/255, 157/255, 157/255), -- Poor
  [1] = CreateColor(240/255, 240/255, 240/255), -- Common
  [2] = CreateColor(30/255, 178/255, 0/255), -- Uncommon
  [3] = CreateColor(0/255, 112/255, 221/255), -- Rare
  [4] = CreateColor(163/255, 53/255, 238/255), -- Epic
  [5] = CreateColor(225/255, 96/255, 0/255), -- Legendary
  [6] = CreateColor(229/255, 204/255, 127/255), -- Artifact
  [7] = CreateColor(79/255, 196/255, 225/255), -- Heirloom
  [8] = CreateColor(79/255, 196/255, 225/255), -- Blizzard
}

local expansionIDToText = {
  [0] = "Cla",
  [1] = "BC",
  [2] = "W",
  [3] = "Cata",
  [4] = "MoP",
  [5] = "Dra",
  [6] = "Leg",
  [7] = "BfA",
  [8] = "SL",
  [9] = "DF",
}

Baganator.CallbackRegistry:RegisterCallback("SettingChangedEarly", function()
  iconSettings = {
    markJunk = Baganator.Config.Get("icon_grey_junk"),
    junkPlugin = Baganator.Config.Get("junk_plugin"),
    useQualityColors = Baganator.Config.Get("icon_text_quality_colors"),
    boe_on_common = not Baganator.Config.Get("hide_boe_on_common"),
  }
  if iconSettings.junkPlugin == "poor_quality" then
    iconSettings.junkPlugin = nil
  end
end)

local function textInit(itemButton)
  local text = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  text.sizeFont = true
  return text
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_ITEM_LEVEL, "item_level", function(ItemLevel, details)
  if IsEquipment(details.itemLink) and not details.isCosmetic then
    if not details.itemLevel then
      details.itemLevel = GetDetailedItemLevelInfo(details.itemLink)
    end
    ItemLevel:SetText(details.itemLevel)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      ItemLevel:SetTextColor(color.r, color.g, color.b)
    else
      ItemLevel:SetTextColor(1,1,1)
    end
    return true
  end
end, textInit)
Baganator.API.RegisterCornerWidget(BAGANATOR_L_BOE, "boe", function(BindingText, details)
  if IsEquipment(details.itemLink) and not details.isBound and (iconSettings.boe_on_common or details.quality > 1) then
      BindingText:SetText(BAGANATOR_L_BOE)
      if iconSettings.useQualityColors then
        local color = qualityColors[details.quality]
        BindingText:SetTextColor(color.r, color.g, color.b)
      else
        BindingText:SetTextColor(1,1,1)
      end
    return true
  end
end, textInit)

local function IsBindOnAccount(details)
  if not details.isBound then
    return false
  end
  if not details.tooltipInfo then
    details.tooltipInfo = details.tooltipGetter()
  end
  if details.tooltipInfo then
    for _, row in ipairs(details.tooltipInfo.lines) do
      if tIndexOf(Baganator.Constants.AccountBoundTooltipLines, row.leftText) ~= nil then
        return true
      end
    end
  end
  return false
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_BOA, "boa", function(BindingText, details)
  if IsBindOnAccount(details) then
    BindingText:SetText(BAGANATOR_L_BOA)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      BindingText:SetTextColor(color.r, color.g, color.b)
    else
      BindingText:SetTextColor(1,1,1)
    end
    return true
  end
end, textInit)

Baganator.API.RegisterCornerWidget(BAGANATOR_L_QUANTITY, "quantity", function(_, details)
  return details.itemCount > 1
end, function(itemButton)
  itemButton.Count.sizeFont = true
  return itemButton.Count
end)

Baganator.API.RegisterCornerWidget(BAGANATOR_L_JUNK, "junk", function(JunkIcon, details)
  return details.isJunk
end,
function(itemButton)
  if itemButton.JunkIcon then
    itemButton.JunkIcon.padding = 0
    return itemButton.JunkIcon
  end
end)

if Baganator.Constants.IsRetail then
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_EXPANSION, "expansion", function(Expansion, details)
    local xpacText = expansionIDToText[details.expacID]
    Expansion:SetText(xpacText or "")
    return xpacText ~= nil
  end, textInit)
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_EQUIPMENT_SET, "equipment_set", function(EquipmentSet, details)
  return details.setInfo ~= nil
end, function(itemButton)
  local EquipmentSet = itemButton:CreateTexture(nil, "ARTWORK")
  EquipmentSet:SetTexture("interface\\groupframe\\ui-group-maintankicon")
  EquipmentSet:SetSize(15, 15)
  return EquipmentSet
end)

Baganator.Utilities.OnAddonLoaded("Pawn", function()
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_PAWN, "pawn", function(Arrow, details)
    return PawnShouldItemLinkHaveUpgradeArrowUnbudgeted(details.itemLink)
  end, function(itemButton)
    local Arrow = itemButton:CreateTexture(nil, "OVERLAY")
    Arrow:SetTexture("Interface\\AddOns\\Pawn\\Textures\\UpgradeArrow")
    Arrow:SetSize(13.5, 15)
    return Arrow
  end, {corner = "top_left", priority = 1})
end)

Baganator.Utilities.OnAddonLoaded("CanIMogIt", function()
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_CAN_I_MOG_IT, "can_i_mog_it", function(CIMIOverlay, details)
    local function CIMI_Update(self)
      if not self or not self:GetParent() then return end
      if not CIMI_CheckOverlayIconEnabled(self) then
          self.CIMIIconTexture:SetShown(false)
          self:SetScript("OnUpdate", nil)
          return
      end

      CIMI_SetIcon(self, CIMI_Update, CanIMogIt:GetTooltipText(details.itemLink))
    end
    CIMI_SetIcon(CIMIOverlay, CIMI_Update, CanIMogIt:GetTooltipText(details.itemLink))
    return IsEquipment(details.itemLink)
  end,
  function(itemButton)
    CIMI_AddToFrame(itemButton, function() end)
    itemButton.CanIMogItOverlay:SetSize(13, 13)
    itemButton.CanIMogItOverlay.CIMIIconTexture:SetPoint("TOPRIGHT")
    return itemButton.CanIMogItOverlay
  end, {corner = "top_right", priority = 1})
end)
