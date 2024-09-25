local _, addonTable = ...

addonTable.ItemButtonUtil = {}

local equipmentSetBorder = CreateColor(198/255, 166/255, 0/255)

local itemCallbacks = {}
local iconSettings = {}

local QueueWidget
do
  local widgetsQueued = {}
  local RetryWidgets = CreateFrame("Frame")
  QueueWidget = function(callback)
    table.insert(widgetsQueued, callback)
    if RetryWidgets:GetScript("OnUpdate") == nil then
      RetryWidgets:SetScript("OnUpdate", function()
        local queue = widgetsQueued
        widgetsQueued = {}
        for _, callback in ipairs(queue) do
          callback()
        end
        if #widgetsQueued == 0 then
          RetryWidgets:SetScript("OnUpdate", nil)
        end
      end)
    end
  end
end

local registered = false
function addonTable.ItemButtonUtil.UpdateSettings()
  if not registered  then
    registered = true
    addonTable.CallbackRegistry:RegisterCallback("SettingChangedEarly", function()
      addonTable.ItemButtonUtil.UpdateSettings()
    end)
    addonTable.CallbackRegistry:RegisterCallback("PluginsUpdated", function()
      addonTable.ItemButtonUtil.UpdateSettings()
      Baganator.API.RequestItemButtonsRefresh()
    end)
  end
  itemCallbacks = {}
  iconSettings = {
    markJunk = addonTable.Config.Get("icon_grey_junk"),
    equipmentSetBorder = addonTable.Config.Get("icon_equipment_set_border"),
  }

  local junkPluginID = addonTable.Config.Get("junk_plugin")
  local junkPlugin = addonTable.API.JunkPlugins[junkPluginID]
  if junkPlugin and junkPluginID ~= "poor_quality" then
    iconSettings.usingJunkPlugin = true
    table.insert(itemCallbacks, function(self)
      if self.JunkIcon then
        local _, junkStatus = pcall(junkPlugin.callback, self:GetParent():GetID(), self:GetID(), self.BGR.itemID, self.BGR.itemLink)
        self.BGR.isJunk = junkStatus == true
        if iconSettings.markJunk and self.BGR.isJunk then
          self.BGR.persistIconGrey = true
          self.icon:SetDesaturated(true)
        end
      end
    end)
  end

  local upgradePluginID = addonTable.Config.Get("upgrade_plugin")
  local upgradePlugin = addonTable.API.UpgradePlugins[upgradePluginID]
  if upgradePlugin and upgradePluginID ~= "poor_quality" then
    iconSettings.usingUpgradePlugin = true
    table.insert(itemCallbacks, function(self)
      if self:GetID() ~= 0 then
        local _, upgradeStatus = pcall(upgradePlugin.callback, self.BGR.itemLink)
        self.BGR.isUpgrade = upgradeStatus == true
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
    local array = CopyTable(addonTable.Config.Get(key))
    local callbacks = {}
    local plugins = {}
    for _, plugin in ipairs(array) do
      if addonTable.API.IconCornerPlugins[plugin] then
        table.insert(callbacks, addonTable.API.IconCornerPlugins[plugin].onUpdate)
        table.insert(plugins, plugin)
      end
    end
    if #callbacks > 0 then
      local function Callback(itemButton)
        local toShow = nil
        local queued = false
        for index = 1, #callbacks do
          local cb = callbacks[index]
          local widget = itemButton.cornerPlugins[plugins[index]]
          if widget then
            local show = cb(widget, itemButton.BGR)
            if show == nil then
              local BGR = itemButton.BGR
              if not queued then
                QueueWidget(function()
                  if itemButton.BGR == BGR then
                    -- Hide any widgets shown immediately because the widget
                    -- wasn't available
                    for i = 1, #callbacks do
                      local widget = itemButton.cornerPlugins[plugins[i]]
                      if widget then
                        widget:Hide()
                      end
                    end
                    Callback(itemButton)
                  end
                end)
                queued = true
              end
            elseif show then
              widget:Show()
              break
            end
          end
        end
      end
      table.insert(itemCallbacks, Callback)
    end
  end
end

local function WidgetsOnly(self)
  for plugin, widget in pairs(self.cornerPlugins) do
    widget:Hide()
  end

  if self.BGR.itemID == nil then
    return
  end

  if not iconSettings.usingJunkPlugin and self.JunkIcon then
    self.BGR.isJunk = not self.BGR.hasNoValue and self.BGR.quality == Enum.ItemQuality.Poor
    self.BGR.persistIconGrey = iconSettings.markJunk and self.BGR.isJunk
    self.icon:SetDesaturated(self.BGR.persistIconGrey)
  end

  local info = self.BGR

  local function OnCached()
    if self.BGR ~= info then -- Check that the item button hasn't been refreshed
      return
    end
    for _, callback in ipairs(itemCallbacks) do
      callback(self)
    end
  end
  if C_Item.IsItemDataCachedByID(self.BGR.itemID) then
    OnCached()
  else
    addonTable.Utilities.LoadItemData(self.BGR.itemID, function()
      OnCached()
    end)
  end
end

local function GetInfo(self, cacheData, earlyCallback, finalCallback)
  local info = Syndicator.Search.GetBaseInfo(cacheData)
  self.BGR = info

  self.BGR.earlyCallback = earlyCallback or function() end
  self.BGR.finalCallback = finalCallback or function() end

  self.BGR.earlyCallback()

  WidgetsOnly(self)

  if self.BaganatorBagHighlight then
    self.BaganatorBagHighlight:Hide()
  end

  if self.BGR.itemID == nil then
    return
  end

  local function OnCached()
    if self.BGR ~= info then -- Check that the item button hasn't been refreshed
      return
    end
    if C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(self.BGR.itemLink) then
      self.IconOverlay:SetAtlas("CosmeticIconFrame")
      self.IconOverlay:Show();
    end
    self.BGR.finalCallback()
  end

  if C_Item.IsItemDataCachedByID(self.BGR.itemID) then
    OnCached()
  else
    addonTable.Utilities.LoadItemData(self.BGR.itemID, function()
      OnCached()
    end)
  end
end

-- Called to reset searched state, widgets, and tooltip data cache
function addonTable.ItemButtonUtil.ResetCache(self, cacheData)
  GetInfo(self, cacheData, self.BGR.earlyCallback, self.BGR.finalCallback)
end

local function SetStaticInfo(self)
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

  return Syndicator.Search.CheckItem(self.BGR, text)
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
  local newSize = addonTable.Config.Get("icon_text_font_size")

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
    for _, plugin in ipairs(addonTable.Config.Get(key)) do
      local setup = addonTable.API.IconCornerPlugins[plugin]
      if setup and not button.cornerPlugins[plugin] then
        button.cornerPlugins[plugin] = setup.onInit(button)
        if button.cornerPlugins[plugin] then
          addonTable.Skins.AddFrame("CornerWidget", button.cornerPlugins[plugin], {plugin})
          button.cornerPlugins[plugin]:Hide()
        end
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

  button.SlotBackground:SetShown(not addonTable.Config.Get(addonTable.Config.Options.EMPTY_SLOT_BACKGROUND))

  ApplyItemDetailSettings(button)
end

-- Scale button and set visuals as appropriate
local function AdjustClassicButton(button)
  if addonTable.Config.Get(addonTable.Config.Options.EMPTY_SLOT_BACKGROUND) then
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

local function ApplyNewItemAnimation(self, quality)
  -- Modified code from Blizzard for classic
  local isNewItem = addonTable.NewItems:IsNewItem(self:GetParent():GetID(), self:GetID());

  local newItemTexture = self.NewItemTexture;
  local battlepayItemTexture = self.BattlepayItemTexture;
  local flash = self.flashAnim;
  local newItemAnim = self.newitemglowAnim;

  if ( isNewItem ) then
    if C_Container.IsBattlePayItem and C_Container.IsBattlePayItem(self:GetBagID(), self:GetID()) then
      self.NewItemTexture:Hide();
      self.BattlepayItemTexture:Show();
    else
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

BaganatorRetailCachedItemButtonMixin = {}

function BaganatorRetailCachedItemButtonMixin:UpdateTextures()
  AdjustRetailButton(self)
end

function BaganatorRetailCachedItemButtonMixin:SetItemDetails(details)
  self:SetItemButtonTexture(details.iconTexture)
  self:SetItemButtonQuality(details.quality, details.itemLink, false, details.isBound)
  self:SetItemButtonCount(details.itemCount)
  SetItemCraftingQualityOverlay(self, details.itemLink)
  SetItemButtonDesaturated(self, false);
  ReparentOverlays(self)

  GetInfo(self, details, nil, function()
    self:SetItemButtonQuality(details.quality, details.itemLink, false, details.isBound)
  end)
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
  elseif IsModifiedClick("DRESSUP") then
    DressUpLink(self.BGR.itemLink)
  elseif IsAltKeyDown() then
    addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
  end
end

function BaganatorRetailCachedItemButtonMixin:OnEnter()
  self:UpdateTooltip()
end

function BaganatorRetailCachedItemButtonMixin:UpdateTooltip()
  local itemLink = self.BGR.itemLink

  if itemLink == nil then
    return
  end

  if IsModifiedClick("DRESSUP") then
    ShowInspectCursor();
  else
    ResetCursor()
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
  ResetCursor()
  BattlePetTooltip:Hide()
  GameTooltip:Hide()
end

BaganatorRetailLiveContainerItemButtonMixin = {}

function BaganatorRetailLiveContainerItemButtonMixin:MyOnLoad()
  self:HookScript("OnClick", function()
    if not self.BGR or not self.BGR.itemID then
      return
    end

    if IsAltKeyDown() then
      addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
    end
  end)
  -- Automatically use the reagent bank when at the bank transferring crafting
  -- reagents if there is space
  self:HookScript("PreClick", function()
    if BankFrame:IsShown() and self.BGR and self.BGR.itemID and BankFrame.activeTabIndex ~= addonTable.Constants.BlizzardBankTabConstants.Warband then
      local _
      self.BGR.stackLimit, _, _, _, _, _, _, _, _, self.BGR.isReagent = select(8, C_Item.GetItemInfo(self.BGR.itemID))
      if self.BGR.isReagent then
        local reagentBank = Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).bank[tIndexOf(Syndicator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)]
        for _, item in ipairs(reagentBank) do
          if item.itemID == nil or (item.itemID == self.BGR.itemID and self.BGR.stackLimit - item.itemCount >= self.BGR.itemCount) then
            BankFrame.selectedTab = 2
            return
          end
        end
      end
      BankFrame.selectedTab = 1
    end
  end)
  self:HookScript("PostClick", function()
    if BankFrame:IsShown() and self.BGR and BankFrame.activeTabIndex ~= addonTable.Constants.BlizzardBankTabConstants.Warband then
      BankFrame.selectedTab = 1
    end
  end)

  hooksecurefunc(self, "UpdateItemContextMatching", function()
    if self.widgetContainer then
      if self.ItemContextOverlay:IsShown() then
        SetWidgetsAlpha(self, false)
      else
        SetWidgetsAlpha(self, self.BGR == nil or self.BGR.matchesSearch ~= false)
      end
    end
  end)
end

function BaganatorRetailLiveContainerItemButtonMixin:UpdateTextures()
  AdjustRetailButton(self)
end

function BaganatorRetailLiveContainerItemButtonMixin:SetItemDetails(cacheData)
  -- Copied code from Blizzard Container Frame logic
  local info = C_Container.GetContainerItemInfo(self:GetBagID(), self:GetID())

  -- Keep cache and display in sync
  if info and not cacheData.itemLink then
    info = nil
  end

  local texture = cacheData.iconTexture or (info and info.iconFileID);
  local itemCount = cacheData.itemCount;
  local locked = info and info.isLocked;
  local quality = cacheData.quality or (info and info.quality);
  local readable = info and info.isReadable;
  local itemLink = info and info.hyperlink;
  local noValue = info and info.hasNoValue;
  local itemID = info and info.itemID;
  local isBound = info and info.isBound;

  ClearItemButtonOverlay(self);

  self:SetHasItem(texture);
  self:SetItemButtonTexture(texture);

  self:SetItemButtonQuality(quality, nil, true, isBound);

  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);

  self:UpdateExtended();
  self:UpdateJunkItem(quality, noValue);
  self:UpdateCooldown(texture);
  self:SetReadable(readable);
  self:SetMatchesSearch(true)

  if GameTooltip:IsOwned(self) then
    GameTooltip:Hide()
    BattlePetTooltip:Hide()
  end

  if self:IsMouseOver() then
    self:OnEnter()
  end

  SetWidgetsAlpha(self, true)
  ReparentOverlays(self)

  GetInfo(self, cacheData, function()
    self.BGR.tooltipGetter = function() return C_TooltipInfo.GetBagItem(self:GetBagID(), self:GetID()) end
    local itemLocation = ItemLocation:CreateFromBagAndSlot(self:GetParent():GetID(), self:GetID())
    self.BGR.setInfo = addonTable.ItemViewCommon.GetEquipmentSetInfo(itemLocation, self.BGR.itemLink)
    self.BGR.itemLocation = itemLocation

    self.BGR.hasNoValue = noValue
    self:BGRUpdateQuests()
    ApplyNewItemAnimation(self, quality);
  end, function()
    self:BGRUpdateQuests()
    self:UpdateItemContextMatching();
    local doNotSuppressOverlays = false
    self:SetItemButtonQuality(quality, itemLink, doNotSuppressOverlays, isBound);
  end)

  if not self.BGR.itemID then
    self:UpdateItemContextMatching();
  end
end

function BaganatorRetailLiveContainerItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorRetailLiveContainerItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorRetailLiveContainerItemButtonMixin:BGRUpdateCooldown()
  self:UpdateCooldown(self.BGR.itemLink ~= nil);
end

function BaganatorRetailLiveContainerItemButtonMixin:BGRUpdateQuests()
  local questInfo = C_Container.GetContainerItemQuestInfo(self:GetBagID(), self:GetID());
  local isQuestItem = questInfo.isQuestItem;
  self.BGR.isQuestItem = questInfo.isQuestItem or questInfo.questID
  local questID = questInfo.questID;
  local isActive = questInfo.isActive;
  self:UpdateQuestItem(isQuestItem, questID, isActive);
end

function BaganatorRetailLiveContainerItemButtonMixin:SetItemFiltered(text)
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

function BaganatorRetailLiveContainerItemButtonMixin:ClearNewItem()
  local bagID, slotID = self:GetParent():GetID(), self:GetID()
  addonTable.NewItems:ClearNewItem(bagID, slotID)
  -- Copied code from Blizzard Container Frame
  self.BattlepayItemTexture:Hide();
  self.NewItemTexture:Hide();
  if (self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying()) then
    self.flashAnim:Stop();
    self.newitemglowAnim:Stop();
  end
end

BaganatorRetailLiveGuildItemButtonMixin = {}

function BaganatorRetailLiveGuildItemButtonMixin:OnLoad()
  self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self:RegisterForDrag("LeftButton")
  self.SplitStack = function(button, split)
    SplitGuildBankItem(self.tabIndex, button:GetID(), split)
  end
  self.UpdateTooltip = self.OnEnter
end

function BaganatorRetailLiveGuildItemButtonMixin:OnClick(button)
  if self.BGR and self.BGR.itemLink and IsAltKeyDown() then
    addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
    ClearCursor()
    return
  end

  if self.BGR and self.BGR.itemLink and HandleModifiedItemClick(self.BGR.itemLink) then
    return
  end

  if ( IsModifiedClick("SPLITSTACK") ) then
    if ( not CursorHasItem() ) then
      local texture, count, locked = GetGuildBankItemInfo(self.tabIndex, self:GetID())
      if ( not locked and count and count > 1) then
        StackSplitFrame:OpenStackSplitFrame(count, self, "BOTTOMLEFT", "TOPLEFT")
      end
    end
    return
  end

  local type, money = GetCursorInfo()
  if ( type == "money" ) then
    DepositGuildBankMoney(money)
    ClearCursor()
  elseif ( type == "guildbankmoney" ) then
    DropCursorMoney()
    ClearCursor()
  else
    if ( button == "RightButton" ) then
      AutoStoreGuildBankItem(self.tabIndex, self:GetID())
      self:OnLeave()
    else
      PickupGuildBankItem(self.tabIndex, self:GetID())
    end
  end
end

function BaganatorRetailLiveGuildItemButtonMixin:OnEnter()
  if self.BGR and self.BGR.itemLink and IsModifiedClick("DRESSUP") then
    ShowInspectCursor();
  else
    ResetCursor()
  end
  if self.tabIndex ~= GetCurrentGuildBankTab() then
    SetCurrentGuildBankTab(self.tabIndex)
  end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetGuildBankItem(self.tabIndex, self:GetID())
end

function BaganatorRetailLiveGuildItemButtonMixin:OnLeave()
  self.updateTooltipTimer = nil
  GameTooltip_Hide()
  ResetCursor()
end

function BaganatorRetailLiveGuildItemButtonMixin:OnHide()
  if ( self.hasStackSplit and (self.hasStackSplit == 1) ) then
    StackSplitFrame:Hide()
  end
end

function BaganatorRetailLiveGuildItemButtonMixin:OnReceiveDrag()
  PickupGuildBankItem(self.tabIndex, self:GetID())
end

function BaganatorRetailLiveGuildItemButtonMixin:UpdateTextures()
  AdjustRetailButton(self)
end

function BaganatorRetailLiveGuildItemButtonMixin:SetItemDetails(cacheData, tabIndex)
  GetInfo(self, cacheData)

  self.tabIndex = tabIndex

  local texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(tabIndex, self:GetID());
  if cacheData.itemLink == nil then
    texture, itemCount, locked, isFiltered, quality = nil, nil, nil, nil, nil
  end
  texture = cacheData.iconTexture or texture
  itemCount = cacheData.itemCount
  quality = cacheData.quality or quality

  self.BGR.tooltipGetter = function() return C_TooltipInfo.GetGuildBankItem(tabIndex, self:GetID()) end

  SetItemButtonTexture(self, texture);
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);

  self:SetMatchesSearch(true);

  SetItemButtonQuality(self, quality, self.BGR.itemLink or GetGuildBankItemLink(tabIndex, self:GetID()));

  if GameTooltip:IsOwned(self) then
    GameTooltip:Hide()
  end
  if self:IsMouseOver() then
    self:OnEnter()
  end
end

function BaganatorRetailLiveGuildItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorRetailLiveGuildItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorRetailLiveGuildItemButtonMixin:ClearNewItem()
end

function BaganatorRetailLiveGuildItemButtonMixin:SetItemFiltered(text)
  local result = SearchCheck(self, text)
  if result == nil then
    return true
  end
  if self.BGR ~= nil then
    self.BGR.matchesSearch = result
  end
  self:SetMatchesSearch(result);
  SetWidgetsAlpha(self, result)
end

BaganatorRetailLiveWarbandItemButtonMixin = {}

function BaganatorRetailLiveWarbandItemButtonMixin:MyOnLoad()
  self:HookScript("OnClick", function()
    if not self.BGR or not self.BGR.itemID then
      return
    end

    if IsAltKeyDown() then
      addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
    end
  end)

  hooksecurefunc(self, "UpdateItemContextMatching", function()
    if self.widgetContainer then
      if self.ItemContextOverlay:IsShown() then
        SetWidgetsAlpha(self, false)
      else
        SetWidgetsAlpha(self, self.BGR == nil or self.BGR.matchesSearch ~= false)
      end
    end
  end)
end

function BaganatorRetailLiveWarbandItemButtonMixin:UpdateTextures()
  AdjustRetailButton(self)
end

function BaganatorRetailLiveWarbandItemButtonMixin:SetItemDetails(cacheData)
  -- Mirror format used by container item buttons for compatiblity between
  -- Baganator and Blizzard functions
  self:SetBankTabID(self:GetParent():GetID())
  self:SetContainerSlotID(self:GetID())

  local info = C_Container.GetContainerItemInfo(self:GetBankTabID(), self:GetContainerSlotID())

  -- Keep cache and display in sync
  if info and not cacheData.itemLink then
    info = nil
  end

  local texture = cacheData.iconTexture or (info and info.iconFileID);
  local itemCount = cacheData.itemCount;
  local locked = info and info.isLocked;
  local quality = cacheData.quality or (info and info.quality);
  local readable = info and info.isReadable;
  local itemLink = info and info.hyperlink;
  local noValue = info and info.hasNoValue;
  local itemID = info and info.itemID;
  local isBound = info and info.isBound;


  ClearItemButtonOverlay(self);

  self.icon:SetShown(texture ~= 0);
  self:SetItemButtonTexture(texture);

  self:SetItemButtonQuality(quality, nil, true, isBound);
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);

  --self:UpdateNewItem(quality);
  --self:UpdateJunkItem(quality, noValue);
  --self:SetReadable(readable);
  self:SetMatchesSearch(true)

  if GameTooltip:IsOwned(self) then
    GameTooltip:Hide()
    BattlePetTooltip:Hide()
  end

  if self:IsMouseOver() then
    self:OnEnter()
  end

  SetWidgetsAlpha(self, true)
  ReparentOverlays(self)

  GetInfo(self, cacheData, function()
    self.BGR.tooltipGetter = function() return C_TooltipInfo.GetBagItem(self:GetBankTabID(), self:GetContainerSlotID()) end
    self.BGR.hasNoValue = noValue
    self:BGRUpdateQuests()
  end, function()
    self:BGRUpdateQuests()
    self:UpdateItemContextMatching();
    local doNotSuppressOverlays = false
    self:SetItemButtonQuality(quality, itemLink, doNotSuppressOverlays, isBound);
  end)
end

function BaganatorRetailLiveWarbandItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorRetailLiveWarbandItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorRetailLiveWarbandItemButtonMixin:BGRUpdateQuests()
  local questInfo = C_Container.GetContainerItemQuestInfo(self:GetBankTabID(), self:GetContainerSlotID());
  local isQuestItem = questInfo.isQuestItem;
  self.BGR.isQuestItem = questInfo.isQuestItem or questInfo.questID
  local questID = questInfo.questID;
  local isActive = questInfo.isActive;

  if questID and not isActive then
    self.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG);
  elseif questID or isQuestItem then
    self.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
  end
  self.IconQuestTexture:SetShown(questID or isQuestItem);
end

function BaganatorRetailLiveWarbandItemButtonMixin:SetItemFiltered(text)
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

BaganatorClassicCachedItemButtonMixin = {}

function BaganatorClassicCachedItemButtonMixin:UpdateTextures()
  AdjustClassicButton(self)
end

function BaganatorClassicCachedItemButtonMixin:SetItemDetails(details)
  GetInfo(self, details)

  SetItemButtonTexture(self, details.iconTexture or self.emptySlotFilepath);
  SetItemButtonQuality(self, details.quality); -- Doesn't do much
  ApplyQualityBorderClassic(self, details.quality)
  SetItemButtonCount(self, details.itemCount);
  SetItemButtonDesaturated(self, false)
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
  elseif IsModifiedClick("DRESSUP") then
   return DressUpItemLink(self.BGR.itemLink) or DressUpBattlePetLink(self.BGR.itemLink) or DressUpMountLink(self.BGR.itemLink)
  elseif IsAltKeyDown() then
    addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
  end
end

function BaganatorClassicCachedItemButtonMixin:OnEnter()
  self:UpdateTooltip()
end

function BaganatorClassicCachedItemButtonMixin:UpdateTooltip()
  local itemLink = self.BGR.itemLink

  if itemLink == nil then
    return
  end

  if IsModifiedClick("DRESSUP") then
    ShowInspectCursor();
  else
    ResetCursor()
  end

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetHyperlink(itemLink)
  GameTooltip:Show()
end

function BaganatorClassicCachedItemButtonMixin:OnLeave()
  ResetCursor()
  GameTooltip:Hide()
end

local UpdateQuestItemClassic
if addonTable.Constants.IsVanilla then
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

    local questTexture = _G[self:GetName().."IconQuestTexture"];

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

BaganatorClassicLiveContainerItemButtonMixin = {}

-- Alter the item button so that the tooltip works both on bag items and bank
-- items
function BaganatorClassicLiveContainerItemButtonMixin:MyOnLoad()
  self:HookScript("OnClick", function()
    if not self.BGR or not self.BGR.itemID then
      return
    end

    if IsAltKeyDown() then
      addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
    end
  end)

  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)
  self.UpdateTooltip = self.OnEnter
end

function BaganatorClassicLiveContainerItemButtonMixin:GetInventorySlot()
  return BankButtonIDToInvSlotID(self:GetID())
end

function BaganatorClassicLiveContainerItemButtonMixin:OnEnter()
  self:ClearNewItem()

  if self:GetParent():GetID() == -1 then
    BankFrameItemButton_OnEnter(self)
  else
    ContainerFrameItemButton_OnEnter(self)
  end
end

function BaganatorClassicLiveContainerItemButtonMixin:BGRUpdateCooldown()
  if self.BGR.itemLink then
    ContainerFrame_UpdateCooldown(self:GetParent():GetID(), self);
  else
    _G[self:GetName().."Cooldown"]:Hide();
  end
end


function BaganatorClassicLiveContainerItemButtonMixin:BGRUpdateQuests()
  UpdateQuestItemClassic(self)
end

function BaganatorClassicLiveContainerItemButtonMixin:OnLeave()
  if self:GetParent():GetID() == -1 then
    GameTooltip_Hide()
    ResetCursor()
  else
    ContainerFrameItemButton_OnLeave(self)
  end
end
-- end alterations

function BaganatorClassicLiveContainerItemButtonMixin:UpdateTextures()
  AdjustClassicButton(self)
end

function BaganatorClassicLiveContainerItemButtonMixin:SetItemDetails(cacheData)
  local info = C_Container.GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

  if cacheData.itemLink == nil then
    info = nil
  end

  local texture = cacheData.iconTexture or (info and info.iconFileID);
  local itemCount = cacheData.itemCount
  local locked = info and info.isLocked;
  local quality = cacheData.quality or (info and info.quality);
  local readable = info and info.isReadable;
  local isFiltered = info and info.isFiltered;
  local noValue = info and info.hasNoValue;
  local itemID = info and info.itemID;

  SetItemButtonTexture(self, texture or self.emptySlotFilepath);
  SetItemButtonQuality(self, quality, itemID);
  ApplyQualityBorderClassic(self, quality)
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);

  ContainerFrameItemButton_SetForceExtended(self, false);

  if ( texture ) then
    ContainerFrame_UpdateCooldown(self:GetParent():GetID(), self);
    self.hasItem = 1;
  else
    _G[self:GetName().."Cooldown"]:Hide();
    self.hasItem = nil;
  end
  self.readable = readable;

  if GameTooltip:IsOwned(self) then
    GameTooltip:Hide()
  end

  if self:IsMouseOver() then
    self:OnEnter()
  end

  self.searchOverlay:SetShown(false);
  SetWidgetsAlpha(self, true)

  GetInfo(self, cacheData, function()
    ApplyNewItemAnimation(self, quality)
    self:BGRUpdateQuests()
    self.BGR.tooltipGetter = function()
      return Syndicator.Search.DumpClassicTooltip(function(tooltip)
        if self:GetParent():GetID() == -1 then
          tooltip:SetInventoryItem("player", self:GetInventorySlot())
        else
          tooltip:SetBagItem(self:GetParent():GetID(), self:GetID())
        end
      end)
    end
    local itemLocation = ItemLocation:CreateFromBagAndSlot(self:GetParent():GetID(), self:GetID())
    self.BGR.setInfo = addonTable.ItemViewCommon.GetEquipmentSetInfo(itemLocation, self.BGR.itemLink)
    self.BGR.itemLocation = itemLocation

    if C_Engraving and C_Engraving.IsEngravingEnabled() then
      self.BGR.isEngravable = false
      local bagID, slotID = self:GetParent():GetID(), self:GetID()
      if bagID == Enum.BagIndex.Bank then
        local invID = BankButtonIDToInvSlotID(slotID)
        self.BGR.isEngravable = C_Engraving.IsEquipmentSlotEngravable(invID)
        if self.BGR.isEngravable then
          self.BGR.engravingInfo = C_Engraving.GetRuneForEquipmentSlot(invID)
        end
      elseif bagID >= 0 and C_Engraving.IsInventorySlotEngravable(bagID, slotID) then
        self.BGR.isEngravable = true
        self.BGR.engravingInfo = C_Engraving.GetRuneForInventorySlot(bagID, slotID)
      end
    end

    self.BGR.hasNoValue = noValue
  end, function()
    self:BGRUpdateQuests()
  end)
end

function BaganatorClassicLiveContainerItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorClassicLiveContainerItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorClassicLiveContainerItemButtonMixin:ClearNewItem()
  local bagID, slotID = self:GetParent():GetID(), self:GetID()
  addonTable.NewItems:ClearNewItem(bagID, slotID)
  self.NewItemTexture:Hide();
  if (self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying()) then
    self.flashAnim:Stop();
    self.newitemglowAnim:Stop();
  end
end

function BaganatorClassicLiveContainerItemButtonMixin:SetItemFiltered(text)
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

BaganatorClassicLiveGuildItemButtonMixin = {}

function BaganatorClassicLiveGuildItemButtonMixin:OnLoad()
  self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self:RegisterForDrag("LeftButton")
  self.SplitStack = function(button, split)
    SplitGuildBankItem(button.tabIndex, button:GetID(), split)
  end
  self.UpdateTooltip = self.OnEnter
end

function BaganatorClassicLiveGuildItemButtonMixin:OnClick(button)
  if self.BGR and self.BGR.itemLink and IsAltKeyDown() then
    addonTable.CallbackRegistry:TriggerEvent("HighlightSimilarItems", self.BGR.itemLink)
    ClearCursor()
    return
  end

  if self.BGR and self.BGR.itemLink and HandleModifiedItemClick(self.BGR.itemLink) then
    return
  end

  if ( IsModifiedClick("SPLITSTACK") ) then
    if ( not CursorHasItem() ) then
      local texture, count, locked = GetGuildBankItemInfo(self.tabIndex, self:GetID())
      if ( not locked and count and count > 1) then
        OpenStackSplitFrame(count, self, "BOTTOMLEFT", "TOPLEFT")
      end
    end
    return
  end

  local type, money = GetCursorInfo()
  if ( type == "money" ) then
    DepositGuildBankMoney(money)
    ClearCursor()
  elseif ( type == "guildbankmoney" ) then
    DropCursorMoney()
    ClearCursor()
  else
    if ( button == "RightButton" ) then
      AutoStoreGuildBankItem(self.tabIndex, self:GetID())
      self:OnLeave()
    else
      PickupGuildBankItem(self.tabIndex, self:GetID())
    end
  end
end

function BaganatorClassicLiveGuildItemButtonMixin:OnEnter()
  if self.BGR and self.BGR.itemLink and IsModifiedClick("DRESSUP") then
    ShowInspectCursor();
  else
    ResetCursor()
  end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetGuildBankItem(self.tabIndex, self:GetID())
end

function BaganatorClassicLiveGuildItemButtonMixin:OnLeave()
  GameTooltip_Hide()
  ResetCursor()
end

function BaganatorClassicLiveGuildItemButtonMixin:UpdateTextures()
  AdjustClassicButton(self)
end

function BaganatorClassicLiveGuildItemButtonMixin:SetItemDetails(cacheData, tabIndex)
  self.tabIndex = tabIndex

  local texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(tabIndex, self:GetID());

  if cacheData.itemLink == nil then
    texture, itemCount, locked, isFiltered, quality = nil, nil, nil, nil, nil
  end
  texture = cacheData.iconTexture or texture
  itemCount = cacheData.itemCount
  quality = cacheData.quality or quality

  SetItemButtonTexture(self, texture or self.emptySlotFilepath);
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);
  ApplyQualityBorderClassic(self, quality)

  if GameTooltip:IsOwned(self) then
    GameTooltip:Hide()
  end

  if self:IsMouseOver() then
    self:OnEnter()
  end

  self.searchOverlay:SetShown(false);
  SetWidgetsAlpha(self, true)

  GetInfo(self, cacheData, function()
    self.BGR.tooltipGetter = function()
      return Syndicator.Search.DumpClassicTooltip(function(tooltip)
          tooltip:SetGuildBankItem(tabIndex, self:GetID())
      end)
    end
  end)
end

function BaganatorClassicLiveGuildItemButtonMixin:BGRStartFlashing()
  FlashItemButton(self)
end

function BaganatorClassicLiveGuildItemButtonMixin:BGRSetHighlight(isHighlighted)
  SetHighlightItemButton(self, isHighlighted)
end

function BaganatorClassicLiveGuildItemButtonMixin:ClearNewItem()
end

function BaganatorClassicLiveGuildItemButtonMixin:SetItemFiltered(text)
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
