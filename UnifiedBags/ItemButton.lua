local _, addonTable = ...

addonTable.JunkPlugins = {}

Baganator.ItemButtonUtil = {}

local equipmentSetBorder = CreateColor(198/255, 166/255, 0/255)

local itemCallbacks = {}
local iconSettings = {}

local registered = false
function Baganator.ItemButtonUtil.UpdateSettings()
  if not registered  then
    registered = true
    Baganator.CallbackRegistry:RegisterCallback("SettingChangedEarly", function()
      Baganator.ItemButtonUtil.UpdateSettings()
    end)
    Baganator.CallbackRegistry:RegisterCallback("PluginsUpdated", function()
      Baganator.ItemButtonUtil.UpdateSettings()
      Baganator.API.RequestItemButtonsRefresh()
    end)
  end
  itemCallbacks = {}
  iconSettings = {
    markJunk = Baganator.Config.Get("icon_grey_junk"),
    equipmentSetBorder = Baganator.Config.Get("icon_equipment_set_border"),
  }

  local junkPluginID = Baganator.Config.Get("junk_plugin")
  local junkPlugin = addonTable.JunkPlugins[junkPluginID]
  if junkPlugin and junkPluginID ~= "poor_quality" then
    iconSettings.usingJunkPlugin = true
    table.insert(itemCallbacks, function(self, data)
      if self.JunkIcon then
        self.BGR.isJunk = junkPlugin.callback(self:GetParent():GetID(), self:GetID(), data.itemID, data.itemLink)
        if iconSettings.markJunk and self.BGR.isJunk then
          self.BGR.persistIconGrey = true
          self.icon:SetDesaturated(true)
        end
      end
    end)
  end

  local positions = {
    "icon_top_left_corner_array",
    "icon_top_right_corner_array",
    "icon_bottom_left_corner_array",
    "icon_bottom_right_corner_array",
  }

  for _, key in ipairs(positions) do
    local array = CopyTable(Baganator.Config.Get(key))
    local callbacks = {}
    local plugins = {}
    for _, plugin in ipairs(array) do
      if addonTable.IconCornerPlugins[plugin] then
        table.insert(callbacks, addonTable.IconCornerPlugins[plugin].onUpdate)
        table.insert(plugins, plugin)
      end
    end
    if #callbacks > 0 then
      table.insert(itemCallbacks, function(itemButton)
        local index = 1
        local toShow = nil
        while index <= #callbacks do
          local cb = callbacks[index]
          local widget = itemButton.cornerPlugins[plugins[index]]
          if widget then
            local show = cb(widget, itemButton.BGR)
            if show then
              widget:Show()
              break
            end
          end
          index = index + 1
        end
      end)
    end
  end
end

local function GetExpansion(self, itemInfo)
  if ItemVersion then
    local details = ItemVersion.API:getItemVersion(self.BGR.itemID, true)
    if details then
      return details.major - 1
    end
  end
  return itemInfo[15]
end

-- Load item data late
local function GetExtraInfo(self, itemID, itemLink, data)
  if itemLink:find("keystone:", nil, true) then
    itemLink = "item:" .. itemID
  end

  if itemLink:find("battlepet:", nil, true) then
    self.itemInfoWaiting = false
    self.BGR.itemInfoWaiting = false
    local petID, level = itemLink:match("battlepet:(%d+):(%d*)")

    self.BGR.itemName = C_PetJournal.GetPetInfoBySpeciesID(tonumber(petID))
    self.BGR.isCraftingReagent = false
    self.BGR.classID = Enum.ItemClass.Battlepet
    self.BGR.isCosmetic = false
    if level and level ~= "" then
      self.BGR.itemLevel = tonumber(level)
    end

  elseif C_Item.IsItemDataCachedByID(itemID) then
    self.BGR.itemInfoWaiting = false
    local itemInfo = {GetItemInfo(itemLink)}
    self.BGR.itemName = itemInfo[1]
    self.BGR.isCraftingReagent = itemInfo[17]
    self.BGR.classID = itemInfo[12]
    self.BGR.subClassID = itemInfo[13]
    self.BGR.invType = itemInfo[9]
    self.BGR.isCosmetic = IsCosmeticItem and IsCosmeticItem(itemLink)
    self.BGR.expacID = GetExpansion(self, itemInfo)
    if self.BGR.isCosmetic then
      self.IconOverlay:SetAtlas("CosmeticIconFrame")
      self.IconOverlay:Show();
    end
    for _, callback in ipairs(itemCallbacks) do
      callback(self, data)
    end
    if self.BGRUpdateQuests then
      self:BGRUpdateQuests()
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
      self.BGR.expacID = GetExpansion(self, itemInfo)
      if self.BGR.isCosmetic then
        self.IconOverlay:SetAtlas("CosmeticIconFrame")
        self.IconOverlay:Show();
      end

      for _, callback in ipairs(itemCallbacks) do
        callback(self, data)
      end
      if self.BGRUpdateQuests then
        self:BGRUpdateQuests()
      end
    end)
  end
end

local function SetStaticInfo(self, details)
  self.BGR.isBound = details.isBound
  self.BGR.quality = details.quality
  self.BGR.itemCount = details.itemCount

  for plugin, widget in pairs(self.cornerPlugins) do
    widget:Hide()
  end

  if not iconSettings.usingJunkPlugin and self.JunkIcon then
    self.BGR.isJunk = not self.BGR.hasNoValue and details.quality == Enum.ItemQuality.Poor
    if iconSettings.markJunk and self.BGR.isJunk then
      self.BGR.persistIconGrey = true
      self.icon:SetDesaturated(true)
    end
  end

  if self.BaganatorBagHighlight then
    self.BaganatorBagHighlight:Hide()
  end

  if iconSettings.equipmentSetBorder and self.BGR.setInfo then
    self.IconBorder:Show()
    self.IconBorder:SetVertexColor(equipmentSetBorder.r, equipmentSetBorder.g, equipmentSetBorder.b)
  end
end

local function SearchCheck(self, text)
  if text == "" then
    return true
  end

  if self.BGR == nil or self.BGR.itemLink == nil then
    return false
  end

  if self.BGR.itemInfoWaiting then
    return
  end

  if not self.BGR.itemName then
    return
  end

  return Baganator.UnifiedBags.Search.CheckItem(self.BGR, text)
end

-- Used to fade widgets when the item doesn't match the current search/context
local function SetWidgetsAlpha(self, result)
  if not result then
    self.widgetContainer:SetAlpha(0.4)
  else
    self.widgetContainer:SetAlpha(1)
  end
end

local function ApplyItemDetailSettings(button)
  local newSize = Baganator.Config.Get("icon_text_font_size")

  local positions = {
    ["icon_top_left_corner_array"] = {"TOPLEFT", 2, -2},
    ["icon_top_right_corner_array"] = {"TOPRIGHT", -2, -2},
    ["icon_bottom_left_corner_array"] = {"BOTTOMLEFT", 2, 2},
    ["icon_bottom_right_corner_array"] = {"BOTTOMRIGHT", -2, 2},
  }

  if not button.widgetContainer then
    button.widgetContainer = CreateFrame("Frame", nil, button)
    button.widgetContainer:SetAllPoints()
    button.cornerPlugins = {}
  end

  for key, anchor in pairs(positions) do
    for _, plugin in ipairs(Baganator.Config.Get(key)) do
      local setup = addonTable.IconCornerPlugins[plugin]
      if setup and not button.cornerPlugins[plugin] then
        button.cornerPlugins[plugin] = setup.onInit(button)
      end
      local corner = button.cornerPlugins[plugin]
      if corner then
        corner:SetParent(button.widgetContainer)
        local extraScale = 1
        if corner.sizeFont then
          extraScale = newSize / 14 -- 14 is default font size
          corner:SetScale(extraScale)
        end
        local padding = 1
        if corner.padding then
          padding = corner.padding
        end
        corner:ClearAllPoints()
        corner:SetPoint(anchor[1], button, anchor[2]*padding/extraScale, anchor[3]*padding/extraScale)
      end
    end
  end
end

-- Scale button and set visuals as appropriate
local function AdjustRetailButton(button)
  if not button.SlotBackground then
    button.emptyBackgroundAtlas = nil
    button.SlotBackground = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    button.SlotBackground:SetAllPoints(button.icon)
    button.SlotBackground:SetAtlas("bags-item-slot64")
  end

  button.SlotBackground:SetShown(not Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND))

  ApplyItemDetailSettings(button)
end

-- Scale button and set visuals as appropriate
local function AdjustClassicButton(button)
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

  ApplyItemDetailSettings(button)
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

local function ReparentOverlays(self)
  if self.ProfessionQualityOverlay then
    self.ProfessionQualityOverlay:SetParent(self.widgetContainer)
  end
end

BaganatorRetailCachedItemButtonMixin = {}

function BaganatorRetailCachedItemButtonMixin:UpdateTextures()
  AdjustRetailButton(self)
end

function BaganatorRetailCachedItemButtonMixin:SetItemDetails(details)
  self.BGR = {}

  self:SetItemButtonTexture(details.iconTexture)
  self:SetItemButtonQuality(details.quality)
  self:SetItemButtonCount(details.itemCount)
  SetItemCraftingQualityOverlay(self, details.itemLink)
  SetItemButtonDesaturated(self, false);
  ReparentOverlays(self)

  self.BGR.itemLink = details.itemLink
  self.BGR.itemID = details.itemID
  self.BGR.itemName = ""
  self.BGR.tooltipGetter = function() return C_TooltipInfo.GetHyperlink(details.itemLink) end

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
  if self.BGR ~= nil then
    self.BGR.matchesSearch = result
  end
  self:SetMatchesSearch(result)
  SetWidgetsAlpha(self, result)
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
    if BankFrame:IsShown() and self.BGR and self.BGR.isCraftingReagent then
      BankFrame.selectedTab = 1
    end
  end)

  -- Hide widgets when Blizzard highlights only a limited set of items
  -- We use hooks on "Show" and "Hide" because doing it on "OnHide" causes the
  -- client to crash on reload if a search was active.
  hooksecurefunc(self.ItemContextOverlay, "Show", function()
    if self.widgetContainer then
      SetWidgetsAlpha(self, false)
    end
  end)
  hooksecurefunc(self.ItemContextOverlay, "Hide", function()
    if self.widgetContainer then
      SetWidgetsAlpha(self, self.BGR.matchesSearch)
    end
  end)
end

function BaganatorRetailLiveItemButtonMixin:UpdateTextures()
  AdjustRetailButton(self)
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

  ClearItemButtonOverlay(self);

  self:SetHasItem(texture);
  self:SetItemButtonTexture(texture);

  local doNotSuppressOverlays = false;
  SetItemButtonQuality(self, quality, itemLink, doNotSuppressOverlays, isBound);

  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);

  self:UpdateExtended();
  self:UpdateNewItem(quality);
  self:UpdateJunkItem(quality, noValue);
  self:UpdateItemContextMatching();
  self:UpdateCooldown(texture);
  self:SetReadable(readable);
  self:CheckUpdateTooltip(tooltipOwner);
  self:SetMatchesSearch(true)

  SetWidgetsAlpha(self, true)
  ReparentOverlays(self)

  self.BGR = {}
  self.BGR.itemName = ""
  self.BGR.itemLink = cacheData.itemLink
  self.BGR.itemID = cacheData.itemID
  self.BGR.itemNameLower = nil
  self.BGR.tooltipGetter = function() return C_TooltipInfo.GetBagItem(self:GetBagID(), self:GetID()) end
  self.BGR.hasNoValue = noValue
  self.BGR.setInfo = Baganator.UnifiedBags.GetEquipmentSetInfo(ItemLocation:CreateFromBagAndSlot(self:GetBagID(), self:GetID()))

  self:BGRUpdateQuests()

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

function BaganatorRetailLiveItemButtonMixin:BGRUpdateQuests()
  local questInfo = C_Container.GetContainerItemQuestInfo(self:GetBagID(), self:GetID());
  local isQuestItem = questInfo.isQuestItem;
  self.BGR.isQuestItem = questInfo.isQuestItem or questInfo.questID
  local questID = questInfo.questID;
  local isActive = questInfo.isActive;
  self:UpdateQuestItem(isQuestItem, questID, isActive);
end

function BaganatorRetailLiveItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  if self.BGR ~= nil then
    self.BGR.matchesSearch = result
  end
  self:SetMatchesSearch(result)
  SetWidgetsAlpha(self, result and not self.ItemContextOverlay:IsShown())
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

  if quality and quality >= LE_ITEM_QUALITY_UNCOMMON and BAG_ITEM_QUALITY_COLORS[quality] then
    color = BAG_ITEM_QUALITY_COLORS[quality]
  end

  if color then
    self.IconBorder:Show()
    self.IconBorder:SetVertexColor(color.r, color.g, color.b)
  else
    self.IconBorder:Hide()
  end
end

local function ApplyNewItemAnimation(self, quality)
  -- Modified code from Blizzard for classic
  local isNewItem = C_NewItems.IsNewItem(self:GetParent():GetID(), self:GetID());

  local newItemTexture = self.NewItemTexture;
  local battlepayItemTexture = self.BattlepayItemTexture;
  local flash = self.flashAnim;
  local newItemAnim = self.newitemglowAnim;

  if ( isNewItem ) then
    if (quality and NEW_ITEM_ATLAS_BY_QUALITY[quality]) then
      newItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[quality]);
    else
      newItemTexture:SetAtlas("bags-glow-white");
    end
    battlepayItemTexture:Hide();
    newItemTexture:Show();
    if (not flash:IsPlaying() and not newItemAnim:IsPlaying()) then
      flash:Play();
      newItemAnim:Play();
    end
  else
    newItemTexture:Hide();
    if (flash:IsPlaying() or newItemAnim:IsPlaying()) then
      flash:Stop();
      newItemAnim:Stop();
    end
    battlepayItemTexture:Hide();
    newItemTexture:Hide();
  end
end

BaganatorClassicCachedItemButtonMixin = {}

function BaganatorClassicCachedItemButtonMixin:UpdateTextures()
  AdjustClassicButton(self)
end

function BaganatorClassicCachedItemButtonMixin:SetItemDetails(details)
  self.BGR = {}
  self.BGR.itemLink = details.itemLink
  self.BGR.itemID = details.itemID
  self.BGR.itemName = ""
  self.BGR.itemNameLower = nil
  self.BGR.tooltipGetter = function() return Baganator.Utilities.DumpClassicTooltip(function(t) t:SetHyperlink(details.itemLink) end) end
  
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
  if self.BGR ~= nil then
    self.BGR.matchesSearch = result
  end
  self.searchOverlay:SetShown(not result)
  SetWidgetsAlpha(self, result)
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
    self.BGR.isQuestItem = questInfo.isQuestItem or questInfo.questId

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
  if (self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying()) then
    self.flashAnim:Stop();
    self.newitemglowAnim:Stop();
  end

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


function BaganatorClassicLiveItemButtonMixin:BGRUpdateQuests()
  UpdateQuestItemClassic(self)
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

function BaganatorClassicLiveItemButtonMixin:UpdateTextures()
  AdjustClassicButton(self)
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
  self.BGR.tooltipGetter = function()
    return Baganator.Utilities.DumpClassicTooltip(function(tooltip)
      if self:GetParent():GetID() == -1 then
        tooltip:SetInventoryItem("player", self:GetInventorySlot())
      else
        tooltip:SetBagItem(self:GetParent():GetID(), self:GetID())
      end
    end)
  end
  self.BGR.setInfo = Baganator.UnifiedBags.GetEquipmentSetInfo(ItemLocation:CreateFromBagAndSlot(self:GetParent():GetID(), self:GetID()))

  -- Copied code from Blizzard Container Frame logic
  local tooltipOwner = GameTooltip:GetOwner()

  local texture = info and info.iconFileID;
  local itemCount = info and info.stackCount;
  local locked = info and info.isLocked;
  local quality = info and info.quality;
  local readable = info and info.isReadable;
  local isFiltered = info and info.isFiltered;
  local noValue = info and info.hasNoValue;
  local itemID = info and info.itemID;
  
  SetItemButtonTexture(self, texture or self.emptySlotFilepath);
  SetItemButtonQuality(self, quality, itemID);
  ApplyQualityBorderClassic(self, quality)
  ApplyNewItemAnimation(self, quality)
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);
  
  ContainerFrameItemButton_SetForceExtended(self, false);

  self:BGRUpdateQuests()

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
  SetWidgetsAlpha(self, true)

  self.BGR.hasNoValue = noValue
 
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
  C_NewItems.RemoveNewItem(self:GetParent():GetID(), self:GetID())
  self.NewItemTexture:Hide();
  if (self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying()) then
    self.flashAnim:Stop();
    self.newitemglowAnim:Stop();
  end
end

function BaganatorClassicLiveItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  if self.BGR ~= nil then
    self.BGR.matchesSearch = result
  end
  self.searchOverlay:SetShown(not result)
  SetWidgetsAlpha(self, result)
end
