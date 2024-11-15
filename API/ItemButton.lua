local _, addonTable = ...
local iconSettings = {}

local IsEquipment = Syndicator and Syndicator.Utilities.IsEquipment

local function HasItemLevel(details)
  local classID = select(6, C_Item.GetItemInfoInstant(details.itemLink))
  return
    -- Regular equipment
    classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
    -- Profession equipment (retail only)
    or classID == Enum.ItemClass.Profession
    -- Legion Artifact relics (retail only)
    or (classID == Enum.ItemClass.Gem and IsArtifactRelicItem and IsArtifactRelicItem(details.itemLink))
end

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
  [1] = "TBC",
  [2] = "Wra",
  [3] = "Cat",
  [4] = "MoP",
  [5] = "Dra",
  [6] = "Leg",
  [7] = "BfA",
  [8] = "SL",
  [9] = "DF",
}

local function CacheSettings()
  iconSettings = {
    markJunk = addonTable.Config.Get("icon_grey_junk"),
    junkPlugin = addonTable.Config.Get("junk_plugin"),
    useQualityColors = addonTable.Config.Get("icon_text_quality_colors"),
    boe_on_common = not addonTable.Config.Get("hide_boe_on_common"),
  }
  if iconSettings.junkPlugin == "poor_quality" then
    iconSettings.junkPlugin = nil
  end
end
addonTable.CallbackRegistry:RegisterCallback("SettingChangedEarly", CacheSettings)
addonTable.Utilities.OnAddonLoaded("Baganator", CacheSettings)

local function textInit(itemButton)
  local text = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  text.sizeFont = true
  return text
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_ITEM_LEVEL, "item_level", function(ItemLevel, details)
  if HasItemLevel(details) and not (C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(details.itemLink)) then
    if not details.itemLevel then
      if details.itemLocation and C_Item.DoesItemExist(details.itemLocation) then
        details.itemLevel = C_Item.GetCurrentItemLevel(details.itemLocation)
      else
        details.itemLevel = C_Item.GetDetailedItemLevelInfo(details.itemLink)
      end
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
  return false
end, textInit)

local function IsBindOnEquip(details)
  local classID = select(6, C_Item.GetItemInfoInstant(details.itemLink))
  if (IsEquipment(details.itemLink) or classID == Enum.ItemClass.Container) and not details.isBound and (iconSettings.boe_on_common or details.quality > 1) then
    if not details.tooltipInfo then
      details.tooltipInfo = details.tooltipGetter()
    end
    if details.tooltipInfo then
      for _, row in ipairs(details.tooltipInfo.lines) do
        if row.leftText == ITEM_BIND_ON_EQUIP then
          return true
        end
      end
    end
  end
  return false
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_BIND_ON_EQUIP, "boe", function(BindingText, details)
  if IsBindOnEquip(details) then
    BindingText:SetText(BAGANATOR_L_BOE)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      BindingText:SetTextColor(color.r, color.g, color.b)
    else
      BindingText:SetTextColor(1,1,1)
    end
    return true
  end
  return false
end, textInit)

local function IsBindOnAccount(details)
  if not details.tooltipInfo then
    details.tooltipInfo = details.tooltipGetter()
  end
  if details.tooltipInfo then
    for _, row in ipairs(details.tooltipInfo.lines) do
      if tIndexOf(Syndicator.Constants.AccountBoundTooltipLines, row.leftText) ~= nil then
        return true
      end
    end
  end
  return false
end

local function IsWarboundUntilEquipped(details)
  if not details.tooltipInfo then
    details.tooltipInfo = details.tooltipGetter()
  end
  if details.tooltipInfo then
    for _, row in ipairs(details.tooltipInfo.lines) do
      if row.leftText == ITEM_ACCOUNTBOUND_UNTIL_EQUIP or (not details.isBound and row.leftText == ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP) then
        return true
      end
    end
  end
  return false
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_BIND_ON_ACCOUNT, "boa", function(BindingText, details)
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
  return false
end, textInit)

local function IsBindOnUse(details)
  if details.isBound then
    return false
  end
  if C_ToyBox and C_ToyBox.GetToyInfo(details.itemID) then
    return true
  end
  if not details.tooltipInfo then
    details.tooltipInfo = details.tooltipGetter()
  end
  if details.tooltipInfo then
    for _, row in ipairs(details.tooltipInfo.lines) do
      if row.leftText == ITEM_BIND_ON_USE then
        return true
      end
    end
  end
  return false
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_BIND_ON_USE, "bou", function(BindingText, details)
  if IsBindOnUse(details) then
    BindingText:SetText(BAGANATOR_L_BOU)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      BindingText:SetTextColor(color.r, color.g, color.b)
    else
      BindingText:SetTextColor(1,1,1)
    end
    return true
  end
  return false
end, textInit)

local TRADEABLE_LOOT_PATTERN = BIND_TRADE_TIME_REMAINING:gsub("([^%w])", "%%%1"):gsub("%%%%s", ".*")

local function IsTradeableLoot(details)
  if not details.isBound then
    return false
  end
  if not details.tooltipInfo then
    details.tooltipInfo = details.tooltipGetter()
  end
  if details.tooltipInfo then
    for _, row in ipairs(details.tooltipInfo.lines) do
      if row.leftText:match(TRADEABLE_LOOT_PATTERN) then
        return true
      end
    end
  end
  return false
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_TRADEABLE_LOOT, "tl", function(BindingText, details)
  if IsTradeableLoot(details) then
    BindingText:SetText(BAGANATOR_L_TL)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      BindingText:SetTextColor(color.r, color.g, color.b)
    else
      BindingText:SetTextColor(1,1,1)
    end
    return true
  end
  return false
end, textInit)

Baganator.API.RegisterCornerWidget(BAGANATOR_L_QUANTITY, "quantity", function(_, details)
  return details.itemCount > 1
end, function(itemButton)
  itemButton.Count.sizeFont = true
  return itemButton.Count
end)

Baganator.API.RegisterCornerWidget(BAGANATOR_L_JUNK, "junk", function(JunkIcon, details)
  return details.isJunk == true
end,
function(itemButton)
  if itemButton.JunkIcon then
    itemButton.JunkIcon.padding = 0
    return itemButton.JunkIcon
  end
end)

local function RegisterExpansionWidget()
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_EXPANSION, "expansion", function(Expansion, details)
    details.expacID = details.expacID or Syndicator.Search.GetExpansion(details)
    local xpacText = expansionIDToText[details.expacID]
    Expansion:SetText(xpacText or "")
    return xpacText ~= nil
  end, textInit)
end
if addonTable.Constants.IsRetail then
  RegisterExpansionWidget()
elseif Syndicator and Syndicator.Search.GetExpansion then
  addonTable.Utilities.OnAddonLoaded("ItemVersion", RegisterExpansionWidget)
end

Baganator.API.RegisterCornerWidget(BAGANATOR_L_EQUIPMENT_SET, "equipment_set", function(EquipmentSet, details)
  return details.setInfo ~= nil
end, function(itemButton)
  local EquipmentSet = itemButton:CreateTexture(nil, "ARTWORK")
  EquipmentSet:SetTexture("interface\\addons\\baganator\\assets\\equipment-set-shield")
  EquipmentSet:SetSize(15, 15)
  return EquipmentSet
end)

addonTable.Utilities.OnAddonLoaded("CanIMogIt", function()
  local function IsPet(itemID)
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
    return classID == Enum.ItemClass.Battlepet or classID == Enum.ItemClass.Miscellaneous and subClassID == Enum.ItemMiscellaneousSubclass.CompanionPet
  end
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
    return (IsEquipment(details.itemLink) or (C_ToyBox ~= nil and C_ToyBox.GetToyInfo(details.itemID) ~= nil) or IsPet(details.itemID) or (C_MountJournal ~= nil and C_MountJournal.GetMountFromItem(details.itemID) ~= nil))
  end,
  function(itemButton)
    CIMI_AddToFrame(itemButton, function() end)
    itemButton.CanIMogItOverlay:SetSize(13, 13)
    itemButton.CanIMogItOverlay.CIMIIconTexture:SetPoint("TOPRIGHT")
    return itemButton.CanIMogItOverlay
  end, {corner = "top_right", priority = 1})

  local function Callback()
    if Baganator.API.IsCornerWidgetActive("can_i_mog_it") then
      Baganator.API.RequestItemButtonsRefresh()
    end
  end
  CanIMogIt:RegisterMessage("OptionUpdate", function()
    pcall(Callback)
  end)

  local RefreshFrame = CreateFrame("Frame", nil)
  RefreshFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
  RefreshFrame:RegisterEvent("NEW_PET_ADDED")
  RefreshFrame:RegisterEvent("NEW_TOY_ADDED")
  RefreshFrame:RegisterEvent("NEW_MOUNT_ADDED")
  if C_EventUtils.IsEventValid("PET_JOURNAL_PET_DELETED") then
    RefreshFrame:RegisterEvent("PET_JOURNAL_PET_DELETED")
  end
  RefreshFrame:SetScript("OnEvent", function()
    Callback()
  end)
end)

addonTable.Utilities.OnAddonLoaded("BattlePetBreedID", function()
  if not BPBID_Internal or not BPBID_Internal.CalculateBreedID or not BPBID_Internal.RetrieveBreedName then
    return
  end

  Baganator.API.RegisterCornerWidget(BAGANATOR_L_BATTLE_PET_BREEDID, "battle_pet_breed_id", function(Breed, details)
    if not details.itemLink:find("battlepet", nil, true) then
      return false
    end
    local speciesID, level, rarity, maxHealth, power, speed = BattlePetToolTip_UnpackBattlePetLink(details.itemLink)
    local breednum = BPBID_Internal.CalculateBreedID(speciesID, rarity + 1, level, maxHealth, power, speed, false, false)
    local name = BPBID_Internal.RetrieveBreedName(breednum):gsub("/", "")
    Breed:SetText(name)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      Breed:SetTextColor(color.r, color.g, color.b)
    else
      Breed:SetTextColor(1,1,1)
    end
    return true
  end,
  textInit, {corner = "bottom_left", priority = 1})
end)

if addonTable.Constants.IsRetail then
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_BATTLE_PET_LEVEL, "battle_pet_level", function(Level, details)
    if details.itemID ~= Syndicator.Constants.BattlePetCageID then
      return false
    end
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      Level:SetTextColor(color.r, color.g, color.b)
    else
      Level:SetTextColor(1,1,1)
    end
    Level:SetText((details.itemLink:match("battlepet:.-:(%d+)")))
    return true
  end,
  textInit, {corner = "top_left", priority = 2})
end

if C_Engraving and C_Engraving.IsEngravingEnabled() then
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_ENGRAVED_RUNE, "engraved_rune", function(RuneTexture, details)
    if details.engravingInfo then
      RuneTexture:SetTexture(details.engravingInfo.iconTexture)
      return true
    else
      return false
    end
  end, function(itemButton)
    local texture = itemButton:CreateTexture(nil, "OVERLAY")
    texture:SetSize(16, 16)
    texture.padding = 0
    return texture
  end, {corner = "top_right", priority = 1})
end

if addonTable.Constants.IsRetail then
  Baganator.API.RegisterCornerWidget(BAGANATOR_L_KEYSTONE_LEVEL, "keystone_level", function(KeystoneText, details)
    local level = details.itemLink:match("keystone:[^:]*:[^:]*:(%d+)")
    if not level then
      return false
    end
    local color = C_ChallengeMode.GetKeystoneLevelRarityColor(tonumber(level))

    KeystoneText:SetText(level)
    if iconSettings.useQualityColors then
      local color = qualityColors[details.quality]
      KeystoneText:SetTextColor(color.r, color.g, color.b)
    else
      KeystoneText:SetTextColor(1,1,1)
    end
    return true
  end, textInit, {corner = "top_left", priority = 3})

  Baganator.API.RegisterCornerWidget(BAGANATOR_L_WARBOUND_UNTIL_EQUIPPED, "wue", function(BindingText, details)
    if IsWarboundUntilEquipped(details) then
      BindingText:SetText(BAGANATOR_L_WUE)
      if iconSettings.useQualityColors then
        local color = qualityColors[details.quality]
        BindingText:SetTextColor(color.r, color.g, color.b)
      else
        BindingText:SetTextColor(1,1,1)
      end
      return true
    end
    return false
  end, textInit)
end
