local _, addonTable = ...

addonTable.JunkPlugins = {}

Baganator.ItemButtonUtil = {}

function Baganator.ItemButtonUtil.SetAutoSettings()
  if Baganator.Config.Get(Baganator.Config.Options.AUTO_PAWN_ARROW) then
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_PAWN_ARROW) then
      -- special check for pawn as the config SHOW_PAWN_ARROW started with the
      -- wrong state previously
      local isPawn = false
      for _, corner in ipairs({"icon_top_left_corner", "icon_top_right_corner", "icon_bottom_left_corner", "icon_bottom_right_corner"}) do
        isPawn = isPawn or Baganator.Config.Get(corner) == "pawn"
      end
      Baganator.Config.Set(Baganator.Config.Options.SHOW_PAWN_ARROW, isPawn)
    end

    Baganator.Utilities.OnAddonLoaded("Pawn", function()
      Baganator.Config.Set(Baganator.Config.Options.AUTO_PAWN_ARROW, false)
      if not Baganator.Config.Get(Baganator.Config.Options.SHOW_PAWN_ARROW) then
        Baganator.Config.Set(Baganator.Config.Options.SHOW_PAWN_ARROW, true)
        Baganator.Config.Set(Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER, "pawn")
      end
    end)
  end

  if Baganator.Config.Get(Baganator.Config.Options.AUTO_CIMI_ICON) then
    Baganator.Utilities.OnAddonLoaded("CanIMogIt", function()
      Baganator.Config.Set(Baganator.Config.Options.AUTO_CIMI_ICON, false)
      if not Baganator.Config.Get(Baganator.Config.Options.SHOW_CIMI_ICON) then
        Baganator.Config.Set(Baganator.Config.Options.SHOW_CIMI_ICON, true)
        Baganator.Config.Set(Baganator.Config.Options.ICON_TOP_RIGHT_CORNER, "can_i_mog_it")
      end
    end)
  end
end

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
local equipmentSetBorder = CreateColor(83/255, 216/255, 186/255)

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

local function IsBindOnAccount(itemLink)
  local tooltipInfo = C_TooltipInfo.GetHyperlink(itemLink)
  if tooltipInfo then
    for _, row in ipairs(tooltipInfo.lines) do
      if row.type == Enum.TooltipDataLineType.ItemBinding and row.leftText == ITEM_BIND_TO_BNETACCOUNT then
        return true
      end
    end
  end
  return false
end

local itemCallbacks = {}
local iconSettings = {}

local registered = false
function Baganator.ItemButtonUtil.UpdateSettings()
  if not registered  then
    registered = true
    Baganator.CallbackRegistry:RegisterCallback("SettingChangedEarly", function()
      Baganator.ItemButtonUtil.UpdateSettings()
    end)
  end
  itemCallbacks = {}

  iconSettings = {
    markJunk = Baganator.Config.Get("icon_grey_junk"),
    usingJunkPlugin = false,
    equipmentSetBorder = Baganator.Config.Get("icon_equipment_set_border"),
  }

  local useQualityColors = Baganator.Config.Get("icon_text_quality_colors")
  if Baganator.Config.Get("show_item_level") then
    table.insert(itemCallbacks, function(self, data)
      if IsEquipment(data.itemLink) and not self.BGR.isCosmetic then
        local itemLevel = GetDetailedItemLevelInfo(data.itemLink)
        self.ItemLevel:SetText(itemLevel)
        if useQualityColors then
          local color = qualityColors[data.quality]
          self.ItemLevel:SetTextColor(color.r, color.g, color.b)
        else
          self.ItemLevel:SetTextColor(1,1,1)
        end
      end
    end)
  end
  if Baganator.Config.Get("show_boe_status") then
    local boe_on_common = not Baganator.Config.Get("hide_boe_on_common")
    table.insert(itemCallbacks, function(self, data)
      if IsEquipment(data.itemLink) and not data.isBound and (boe_on_common or data.quality > 1) then
        self.BindingText:SetText(BAGANATOR_L_BOE)
        if useQualityColors then
          local color = qualityColors[data.quality]
          self.BindingText:SetTextColor(color.r, color.g, color.b)
        else
          self.BindingText:SetTextColor(1,1,1)
        end
      end
    end)
  end
  if Baganator.Config.Get("show_boa_status") then
    table.insert(itemCallbacks, function(self, data)
      if IsBindOnAccount(data.itemLink) then
        self.BindingText:SetText(BAGANATOR_L_BOA)
        if useQualityColors then
          local color = qualityColors[data.quality]
          self.BindingText:SetTextColor(color.r, color.g, color.b)
        else
          self.BindingText:SetTextColor(1,1,1)
        end
      end
    end)
  end
  if Baganator.Config.Get("show_expansion") then
    table.insert(itemCallbacks, function(self, data)
      if not Baganator.Constants.IsClassic then
        self.Expansion:SetText(expansionIDToText[self.BGR.expacID] or "")
      end
    end)
  end
  if Baganator.Config.Get("show_equipment_set") then
    table.insert(itemCallbacks, function(self, data)
      if data.setInfo then
        self.EquipmentSet:Show()
      end
    end)
  end
  if Baganator.Config.Get("show_pawn_arrow") and PawnShouldItemLinkHaveUpgradeArrowUnbudgeted then
    table.insert(itemCallbacks, function(self, data)
      if PawnShouldItemLinkHaveUpgradeArrowUnbudgeted(data.itemLink) then
        self.UpgradeArrow:Show()
      end
    end)
  end
  if Baganator.Config.Get("show_cimi_icon") and CIMI_AddToFrame then
    table.insert(itemCallbacks, function(self, data)
      local function CIMI_Update(self)
        if not self or not self:GetParent() then return end
        if not CIMI_CheckOverlayIconEnabled(self) then
            self.CIMIIconTexture:SetShown(false)
            self:SetScript("OnUpdate", nil)
            return
        end

        CIMI_SetIcon(self, CIMI_Update, CanIMogIt:GetTooltipText(data.itemLink))
      end
      if not self.CanIMogItOverlay then
        return
      end
      self.CanIMogItOverlay:Show()
      CIMI_SetIcon(self.CanIMogItOverlay, CIMI_Update, CanIMogIt:GetTooltipText(data.itemLink))
    end)
  end

  local junkPluginID = Baganator.Config.Get("junk_plugin")
  local junkPlugin = addonTable.JunkPlugins[junkPluginID]
  if junkPlugin and junkPluginID ~= "poor_quality" then
    iconSettings.usingJunkPlugin = true
    table.insert(itemCallbacks, function(self, data)
      if self.JunkIcon then
        local isJunk = junkPlugin.callback(self:GetParent():GetID(), self:GetID(), data.itemID, data.itemLink)
        self.JunkIcon:SetShown(isJunk)
        if iconSettings.markJunk and isJunk then
          self.BGR.persistIconGrey = true
          self.icon:SetDesaturated(true)
        end
      end
    end)
  end
end

-- Load item data late
local function GetExtraInfo(self, itemID, itemLink, data)
  if itemLink:find("keystone:", nil, true) then
    itemLink = "item:" .. itemID
  end

  if itemLink:find("battlepet:", nil, true) then
    self.itemInfoWaiting = false
    self.BGR.itemInfoWaiting = false
    local petID = tonumber(itemLink:match("battlepet:(%d+)"))
    self.BGR.itemName = C_PetJournal.GetPetInfoBySpeciesID(petID)
    self.BGR.isCraftingReagent = false
    self.BGR.classID = Enum.ItemClass.Battlepet

  elseif C_Item.IsItemDataCachedByID(itemID) then
    self.BGR.itemInfoWaiting = false
    local itemInfo = {GetItemInfo(itemLink)}
    self.BGR.itemName = itemInfo[1]
    self.BGR.isCraftingReagent = itemInfo[17]
    self.BGR.classID = itemInfo[12]
    self.BGR.subClassID = itemInfo[13]
    self.BGR.invType = itemInfo[9]
    self.BGR.isCosmetic = IsCosmeticItem and IsCosmeticItem(itemLink)
    self.BGR.expacID = itemInfo[15]
    if self.BGR.isCosmetic then
      self.IconOverlay:SetAtlas("CosmeticIconFrame")
      self.IconOverlay:Show();
    end
    for _, callback in ipairs(itemCallbacks) do
      callback(self, data)
    end
  else
    local item = Item:CreateFromItemLink(itemLink)
    self.BGR.itemInfoWaiting = true
    item:ContinueOnItemLoad(function()
      self.BGR.itemInfoWaiting = false
      local itemInfo = {GetItemInfo(itemLink)}
      self.BGR.itemName = itemInfo[1]
      self.BGR.isCraftingReagent = itemInfo[17]
      self.BGR.classID = itemInfo[12]
      self.BGR.subClassID = itemInfo[13]
      self.BGR.invType = itemInfo[9]
      self.BGR.isCosmetic = IsCosmeticItem and IsCosmeticItem(itemLink)
      self.BGR.expacID = itemInfo[15]
      if self.BGR.isCosmetic then
        self.IconOverlay:SetAtlas("CosmeticIconFrame")
        self.IconOverlay:Show();
      end

      for _, callback in ipairs(itemCallbacks) do
        callback(self, data)
      end
    end)
  end
end

local function SetStaticInfo(self, details)
  self.BGR.isBound = details.isBound
  self.BGR.quality = details.quality
  self.BindingText:SetText("")
  self.ItemLevel:SetText("")
  self.Expansion:SetText("")
  self.EquipmentSet:SetTexture("Interface\\Minimap\\Minimap_Shield_Normal")
  self.EquipmentSet:Hide()

  if self.ProfessionQualityOverlay then
    local scale = self:GetWidth() / 37
    self.ProfessionQualityOverlay:SetPoint("TOPLEFT", -3 * scale, 2 * scale);
    self.ProfessionQualityOverlay:SetScale(scale);
  end

  if PawnShouldItemLinkHaveUpgradeArrowUnbudgeted then
    self.UpgradeArrow:SetTexture("Interface\\AddOns\\Pawn\\Textures\\UpgradeArrow")
    self.UpgradeArrow:Hide()
  end

  if self.CanIMogItOverlay then
    self.CanIMogItOverlay:Hide()
  end

  if not iconSettings.usingJunkPlugin and self.JunkIcon then
    self.JunkIcon:SetShown(details.quality == Enum.ItemQuality.Poor)
    if iconSettings.markJunk and details.quality == Enum.ItemQuality.Poor then
      self.BGR.persistIconGrey = true
      self.icon:SetDesaturated(true)
    end
  end

  if self.BaganatorBagHighlight then
    self.BaganatorBagHighlight:Hide()
  end

  if iconSettings.equipmentSetBorder and self.BGR.setInfo then
    self.IconBorder:SetVertexColor(equipmentSetBorder.r, equipmentSetBorder.g, equipmentSetBorder.b)
  end
end

local function SearchCheck(self, text)
  if text == "" then
    return true
  end

  if self.BGR == nil then
    return false
  end

  if self.BGR.itemInfoWaiting then
    return
  end

  if not self.BGR.itemName then
    return
  end

  if text ~= "" then
    self.BGR.itemNameLower = self.BGR.itemNameLower or self.BGR.itemName:lower()
  end
  local currentBGR = self.BGR
  return Baganator.UnifiedBags.Search.CheckItem(self.BGR, text)
end

local hidden = CreateFrame("Frame")
hidden:Hide()

local function ApplyItemDetailSettings(button, size)
  local font, originalSize, fontFlags = button.ItemLevel:GetFont()
  local newSize = Baganator.Config.Get("icon_text_font_size")
  local scale = size / 37

  local positions_no_scale = {
    ["icon_top_left_corner"] = {"TOPLEFT", 2, -2},
    ["icon_top_right_corner"] = {"TOPRIGHT", -2, -2},
    ["icon_bottom_left_corner"] = {"BOTTOMLEFT", 2, 2},
    ["icon_bottom_right_corner"] = {"BOTTOMRIGHT", -2, 2},
  }
  local positions = {
    ["icon_top_left_corner"] = {"TOPLEFT", 2 * scale, -2 * scale},
    ["icon_top_right_corner"] = {"TOPRIGHT", -2 * scale, -2 * scale},
    ["icon_bottom_left_corner"] = {"BOTTOMLEFT", 2 * scale, 2 * scale},
    ["icon_bottom_right_corner"] = {"BOTTOMRIGHT", -2 * scale, 2 * scale},
  }
  local toHide = {
    ["item_level"] = button.ItemLevel,
    ["binding_type"] = button.BindingText,
    ["quantity"] = button.Count,
    ["pawn"] = button.UpgradeArrow,
    ["can_i_mog_it"] = button.CanIMogItOverlay,
    ["expansion"] = button.Expansion,
    ["equipment_set"] = button.EquipmentSet,
  }

  for config, anchor in pairs(positions) do
    local cornerType = Baganator.Config.Get(config)
    if cornerType == "item_level" then
      button.ItemLevel:SetParent(button)
      button.ItemLevel:ClearAllPoints()
      button.ItemLevel:SetPoint(unpack(anchor))
      button.ItemLevel:SetFont(font, newSize, fontFlags)
      button.ItemLevel:SetScale(scale)
    elseif cornerType == "binding_type" then
      button.BindingText:SetParent(button)
      button.BindingText:ClearAllPoints()
      button.BindingText:SetPoint(unpack(anchor))
      button.BindingText:SetFont(font, newSize, fontFlags)
      button.BindingText:SetScale(scale)
    elseif cornerType == "quantity" then
      button.Count:SetParent(button)
      button.Count:ClearAllPoints()
      button.Count:SetPoint(unpack(anchor))
      button.Count:SetFont(font, newSize, fontFlags)
      button.Count:SetScale(scale)
    elseif cornerType == "expansion" then
      button.Expansion:SetParent(button)
      button.Expansion:ClearAllPoints()
      button.Expansion:SetPoint(unpack(anchor))
      button.Expansion:SetFont(font, newSize, fontFlags)
      button.Expansion:SetScale(scale)
    elseif cornerType == "pawn" then
      button.UpgradeArrow:SetParent(button)
      button.UpgradeArrow:ClearAllPoints()
      button.UpgradeArrow:SetSize(13 * scale, 15 * scale)
      button.UpgradeArrow:SetPoint(unpack(anchor))
    elseif cornerType == "can_i_mog_it" and CIMI_AddToFrame then
      CIMI_AddToFrame(button, function() end)
      local overlay = button.CanIMogItOverlay 
      if overlay and overlay.CIMIIconTexture then
        overlay:SetParent(button)
        overlay.CIMIIconTexture:ClearAllPoints()
        local shift = math.max(1, scale)
        if shift > 1  then
          overlay.CIMIIconTexture:SetPoint(unpack(positions[config]))
        else
          overlay.CIMIIconTexture:SetPoint(unpack(positions_no_scale[config]))
        end
        overlay.CIMIIconTexture:SetSize(13 * shift, 13 * shift)
      end
    elseif cornerType == "equipment_set" then
      button.EquipmentSet:SetParent(button)
      button.EquipmentSet:ClearAllPoints()
      button.EquipmentSet:SetSize(15 * scale, 15 * scale)
      button.EquipmentSet:SetPoint(unpack(anchor))
    end
    toHide[cornerType] = nil
  end
  for key, f in pairs(toHide) do
    f:SetParent(hidden)
  end
end

-- Fix anchors and item sizes when resizing the item buttons
local function AdjustRetailButton(button, size)
  local scale = size / 37
  button.IconBorder:SetSize(size, size)
  button.IconOverlay:SetSize(size, size)
  button.IconOverlay2:SetSize(size, size)
  button.NormalTexture:SetSize(64 * scale, 64 * scale)
  button.NormalTexture:ClearAllPoints()
  button.NormalTexture:SetPoint("CENTER", 0, -1 * scale)

  if not button.SlotBackground then
    button.emptyBackgroundAtlas = nil
    button.SlotBackground = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    button.SlotBackground:SetAllPoints(button.icon)
    button.SlotBackground:SetAtlas("bags-item-slot64")
  end

  button.SlotBackground:SetShown(not Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND))

  if button.ProfessionQualityOverlay then
    local scale = size / 37
    button.ProfessionQualityOverlay:SetPoint("TOPLEFT", -2 * scale, 2 * scale);
    button.ProfessionQualityOverlay:SetScale(scale);
  end

  ApplyItemDetailSettings(button, size)
end

-- Fix anchors and item sizes when resizing the item buttons
local function AdjustClassicButton(button, size)
  button.IconBorder:SetSize(size, size)
  button.IconOverlay:SetSize(size, size)
  local scaleNormal = 64/37 * size
  _G[button:GetName() .. "NormalTexture"]:SetSize(scaleNormal, scaleNormal)

  if Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND) then
    if not button.BGR or button.BGR.itemLink == nil then
      button.icon:SetTexture(nil)
      button.icon:Hide()
    end
    button.emptySlotFilepath = nil
  else
    button.emptySlotFilepath = "Interface\\AddOns\\Baganator\\Assets\\classic-bag-slot"
    if not button.BGR or button.BGR.itemLink == nil then
      button.icon:Show()
      button.icon:SetTexture(button.emptySlotFilepath)
    end
  end

  ApplyItemDetailSettings(button, size)
end

local function FlashItemButton(self)
  if not self.BaganatorFlashAnim then
    local flash = self:CreateTexture(nil, "OVERLAY", nil)
    flash:SetPoint("CENTER", self)
    flash:SetAllPoints(self.icon)
    flash:SetAtlas("bags-glow-orange")
    flash:SetAlpha(0)
    self.BaganatorFlashAnim = self:CreateAnimationGroup()
    self.BaganatorFlashAnim:SetLooping("REPEAT")
    self.BaganatorFlashAnim:SetToFinalAlpha(false)
    local alpha = self.BaganatorFlashAnim:CreateAnimation("Alpha", nil, nil)
    alpha:SetDuration(0.3)
    alpha:SetOrder(1)
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0)
    alpha:SetSmoothing("IN_OUT")
    alpha:SetTarget(flash)
    local alpha = self.BaganatorFlashAnim:CreateAnimation("Alpha", nil, nil)
    alpha:SetDuration(0.3)
    alpha:SetOrder(2)
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetSmoothing("IN_OUT")
    alpha:SetTarget(flash)
    self:HookScript("OnHide", function()
      self.BaganatorFlashAnim:Stop()
    end)
  end
  self.BaganatorFlashAnim:Play()
  C_Timer.NewTimer(2.1, function()
    self.BaganatorFlashAnim:Stop()
  end)
end

local function SetHighlightItemButton(self, isShown)
  if not self.BaganatorBagHighlight then
    local highlight = self:CreateTexture(nil, "OVERLAY", nil)
    highlight:SetPoint("CENTER", self)
    highlight:SetAllPoints(self.icon)
    highlight:SetAtlas("bags-glow-heirloom")
    self.BaganatorBagHighlight = highlight
  end
  self.BaganatorBagHighlight:SetShown(isShown)
end

BaganatorRetailCachedItemButtonMixin = {}

function BaganatorRetailCachedItemButtonMixin:UpdateTextures(size)
  AdjustRetailButton(self, size)
end

function BaganatorRetailCachedItemButtonMixin:SetItemDetails(details)
  self.BGR = {}

  self:SetItemButtonTexture(details.iconTexture)
  self:SetItemButtonQuality(details.quality)
  self:SetItemButtonCount(details.itemCount)
  SetItemCraftingQualityOverlay(self, details.itemLink)
  SetItemButtonDesaturated(self, false);

  self.BGR.itemLink = details.itemLink
  self.BGR.itemID = details.itemID
  self.BGR.itemName = ""
  self.BGR.setInfo = details.setInfo

  SetStaticInfo(self, details)
  if details.iconTexture ~= nil then
    GetExtraInfo(self, details.itemID, self.BGR.itemLink, details)
  end
end

function BaganatorRetailCachedItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorRetailCachedItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorRetailCachedItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  self:SetMatchesSearch(result)
end

function BaganatorRetailCachedItemButtonMixin:OnClick(button)
  if IsModifiedClick("CHATLINK") then
    ChatEdit_InsertLink(self.BGR.itemLink)
  elseif IsAltKeyDown() then
    Baganator.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemName)
  end
end

function BaganatorRetailCachedItemButtonMixin:OnEnter()
  local itemLink = self.BGR.itemLink

  if itemLink == nil then
    return
  end

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

  if itemLink:match("battlepet:") then
    BattlePetToolTip_ShowLink(itemLink)
  else
    GameTooltip:SetHyperlink(itemLink)
    GameTooltip:Show()
  end
end

function BaganatorRetailCachedItemButtonMixin:OnLeave()
  local itemLink = self.BGR.itemLink

  if itemLink == nil then
    return
  end

  if itemLink:match("battlepet:") then
    BattlePetTooltip:Hide()
  else
    GameTooltip:Hide()
  end
end

BaganatorRetailLiveItemButtonMixin = {}

function BaganatorRetailLiveItemButtonMixin:MyOnLoad()
  self:HookScript("OnClick", function()
    if IsAltKeyDown() then
      Baganator.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemName)
    end
  end)
  -- Automatically use the reagent bank when at the bank transferring crafting
  -- reagents
  self:HookScript("OnEnter", function()
    if BankFrame:IsShown() then
      if self.BGR and self.BGR.isCraftingReagent and C_Container.GetContainerNumFreeSlots(Enum.BagIndex.Reagentbank) > 0 then
        BankFrame.selectedTab = 2
      else
        BankFrame.selectedTab = 1
      end
    end
  end)
  self:HookScript("OnLeave", function()
    if BankFrame:IsShown() and self.BGR.isCraftingReagent then
      BankFrame.selectedTab = 1
    end
  end)
end

function BaganatorRetailLiveItemButtonMixin:UpdateTextures(size)
  AdjustRetailButton(self, size)

  local s2 = 64 * size/37
  if self.IconQuestTexture then
    self.IconQuestTexture:SetSize(size, size)
    self.ExtendedSlot:SetSize(s2, s2)
  end

  -- Uses in-game determined atlas sizes
  local s3 = 39 * size/37
  self.NewItemTexture:SetSize(s3, s3)
  local s4 = 90 * size/37
  self.flash:SetSize(s4, s4)
end

function BaganatorRetailLiveItemButtonMixin:SetItemDetails(cacheData)
  -- Copied code from Blizzard Container Frame logic
  local tooltipOwner = GameTooltip:GetOwner()

  local info = C_Container.GetContainerItemInfo(self:GetBagID(), self:GetID())

  -- Keep cache and display in sync
  if info and not cacheData.itemLink then
    info = nil
  end

  local texture = info and info.iconFileID;
  local itemCount = info and info.stackCount;
  local locked = info and info.isLocked;
  local quality = (info and info.quality) or cacheData.quality;
  local readable = info and info.IsReadable;
  local itemLink = info and info.hyperlink;
  local noValue = info and info.hasNoValue;
  local itemID = info and info.itemID;
  local isBound = info and info.isBound;
  local questInfo = C_Container.GetContainerItemQuestInfo(self:GetBagID(), self:GetID());
  local isQuestItem = questInfo.isQuestItem;
  local questID = questInfo.questID;
  local isActive = questInfo.isActive;

  ClearItemButtonOverlay(self);

  self:SetHasItem(texture);
  self:SetItemButtonTexture(texture);

  local doNotSuppressOverlays = false;
  SetItemButtonQuality(self, quality, itemLink, doNotSuppressOverlays, isBound);

  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);

  self:UpdateExtended();
  self:UpdateQuestItem(isQuestItem, questID, isActive);
  self:UpdateNewItem(quality);
  self:UpdateJunkItem(quality, noValue);
  self:UpdateItemContextMatching();
  self:UpdateCooldown(texture);
  self:SetReadable(readable);
  self:CheckUpdateTooltip(tooltipOwner);
  self:SetMatchesSearch(true)

  -- Baganator specific stuff
  self.JunkIcon:Hide()

  self.BGR = {}
  self.BGR.itemName = ""
  self.BGR.itemLink = cacheData.itemLink
  self.BGR.itemID = cacheData.itemID
  self.BGR.itemNameLower = nil
  self.BGR.setInfo = cacheData.setInfo

  SetStaticInfo(self, cacheData)
  if texture ~= nil then
    GetExtraInfo(self, itemID, cacheData.itemLink, cacheData)
  end
end

function BaganatorRetailLiveItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorRetailLiveItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorRetailLiveItemButtonMixin:BGRUpdateCooldown()
  self:UpdateCooldown(self.BGR.itemLink);
end

function BaganatorRetailLiveItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  self:SetMatchesSearch(result)
end

function BaganatorRetailLiveItemButtonMixin:ClearNewItem()
  C_NewItems.RemoveNewItem(self:GetParent():GetID(), self:GetID())
  -- Copied code from Blizzard Container Frame
  self.BattlepayItemTexture:Hide();
  self.NewItemTexture:Hide();
  if (self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying()) then
    self.flashAnim:Stop();
    self.newitemglowAnim:Stop();
  end
end

local function ApplyQualityBorderClassic(self, quality)
  local color

  if quality and quality >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[quality] then
    color = BAG_ITEM_QUALITY_COLORS[quality]
  end

  if color then
    self.IconBorder:Show()
    self.IconBorder:SetVertexColor(color.r, color.g, color.b)
  else
    self.IconBorder:Hide()
  end
end

BaganatorClassicCachedItemButtonMixin = {}

function BaganatorClassicCachedItemButtonMixin:UpdateTextures(size)
  AdjustClassicButton(self, size)
end

function BaganatorClassicCachedItemButtonMixin:SetItemDetails(details)
  self.BGR = {}
  self.BGR.itemLink = details.itemLink
  self.BGR.itemID = details.itemID
  self.BGR.itemName = ""
  self.BGR.itemNameLower = nil
  self.BGR.setInfo = details.setInfo
  
  SetItemButtonTexture(self, details.iconTexture or self.emptySlotFilepath);
  SetItemButtonQuality(self, details.quality); -- Doesn't do much
  ApplyQualityBorderClassic(self, details.quality)
  SetItemButtonCount(self, details.itemCount);
  SetItemButtonDesaturated(self, false)

  SetStaticInfo(self, details)
  if details.iconTexture ~= nil then
    GetExtraInfo(self, details.itemID, details.itemLink, details)
  end
end

function BaganatorClassicCachedItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorClassicCachedItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorClassicCachedItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  self.searchOverlay:SetShown(not result)
end

function BaganatorClassicCachedItemButtonMixin:OnClick(button)
  if IsModifiedClick("CHATLINK") then
    ChatEdit_InsertLink(self.BGR.itemLink)
  elseif IsAltKeyDown() then
    Baganator.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemName)
  end
end

function BaganatorClassicCachedItemButtonMixin:OnEnter()
  local itemLink = self.BGR.itemLink

  if itemLink == nil then
    return
  end

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetHyperlink(itemLink)
  GameTooltip:Show()
end

function BaganatorClassicCachedItemButtonMixin:OnLeave()
  local itemLink = self.BGR.itemLink

  if itemLink == nil then
    return
  end
  GameTooltip:Hide()
end

local UpdateQuestItemClassic
if Baganator.Constants.IsVanilla then
  UpdateQuestItemClassic = function(self)
    local questTexture = _G[self:GetName().."IconQuestTexture"]
    if questTexture then
      questTexture:Hide()
    end
  end
else
  UpdateQuestItemClassic = function(self)
    local questInfo = C_Container.GetContainerItemQuestInfo(self:GetParent():GetID(), self:GetID());

    questTexture = _G[self:GetName().."IconQuestTexture"];

    if ( questInfo.questId and not questInfo.isActive ) then
      questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG);
      questTexture:Show();
    elseif ( questInfo.questId or questInfo.isQuestItem ) then
      questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
      questTexture:Show();
    else
      questTexture:Hide();
    end
  end
end

BaganatorClassicLiveItemButtonMixin = {}

-- Alter the item button so that the tooltip works both on bag items and bank
-- items
function BaganatorClassicLiveItemButtonMixin:MyOnLoad()
  self:HookScript("OnClick", function()
    if IsAltKeyDown() then
      Baganator.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemName)
    end
  end)

  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)
  self.UpdateTooltip = self.OnEnter
end

function BaganatorClassicLiveItemButtonMixin:GetInventorySlot()
  return BankButtonIDToInvSlotID(self:GetID())
end

function BaganatorClassicLiveItemButtonMixin:OnEnter()
  if self:GetParent():GetID() == -1 then
    BankFrameItemButton_OnEnter(self)
  else
    ContainerFrameItemButton_OnEnter(self)
  end
end

function BaganatorClassicLiveItemButtonMixin:BGRUpdateCooldown()
  if self.BGR.itemLink then
    ContainerFrame_UpdateCooldown(self:GetParent():GetID(), self);
  else
    _G[self:GetName().."Cooldown"]:Hide();
  end
end

function BaganatorClassicLiveItemButtonMixin:OnLeave()
  if self:GetParent():GetID() == -1 then
    GameTooltip_Hide()
    ResetCursor()
  else
    ContainerFrameItemButton_OnLeave(self)
  end
end
-- end alterations

function BaganatorClassicLiveItemButtonMixin:UpdateTextures(size)
  AdjustClassicButton(self, size)

  _G[self:GetName() .. "IconQuestTexture"]:SetSize(size, size+1)
  self.ExtendedOverlay:SetSize(size, size)
  self.ExtendedOverlay2:SetSize(size, size)
end

function BaganatorClassicLiveItemButtonMixin:SetItemDetails(cacheData)
  self.BGR = {}
  local info = C_Container.GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

  if cacheData.itemLink == nil then
    info = nil
  end

  self.BGR.itemLink = cacheData.itemLink
  self.BGR.itemID = cacheData.itemID
  self.BGR.itemName = ""
  self.BGR.itemNameLower = nil
  self.BGR.setInfo = cacheData.setInfo

  -- Copied code from Blizzard Container Frame logic
  local tooltipOwner = GameTooltip:GetOwner()
  
  texture = info and info.iconFileID;
  itemCount = info and info.stackCount;
  locked = info and info.isLocked;
  quality = info and info.quality;
  readable = info and info.isReadable;
  isFiltered = info and info.isFiltered;
  noValue = info and info.hasNoValue;
  itemID = info and info.itemID;
  
  SetItemButtonTexture(self, texture or self.emptySlotFilepath);
  SetItemButtonQuality(self, quality, itemID);
  ApplyQualityBorderClassic(self, quality)
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);
  
  ContainerFrameItemButton_SetForceExtended(self, false);

  UpdateQuestItemClassic(self)

  battlepayItemTexture = self.BattlepayItemTexture;
  newItemTexture = self.NewItemTexture;
  battlepayItemTexture:Hide();
  newItemTexture:Hide();

  self.JunkIcon:Hide();

  if ( texture ) then
    ContainerFrame_UpdateCooldown(self:GetParent():GetID(), self);
    self.hasItem = 1;
  else
    _G[self:GetName().."Cooldown"]:Hide();
    self.hasItem = nil;
  end
  self.readable = readable;
  
  if ( self == tooltipOwner ) then
    if info then
      self.UpdateTooltip(self);
    else
      GameTooltip:Hide();
    end
  end
  
  self.searchOverlay:SetShown(false);

  -- Back to Baganator stuff:
  SetStaticInfo(self, cacheData)
  if cacheData.iconTexture ~= nil then
    GetExtraInfo(self, cacheData.itemID, cacheData.itemLink, cacheData)
  end
end

function BaganatorClassicLiveItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorClassicLiveItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorClassicLiveItemButtonMixin:ClearNewItem()
end

function BaganatorClassicLiveItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  self.searchOverlay:SetShown(not result)
end
