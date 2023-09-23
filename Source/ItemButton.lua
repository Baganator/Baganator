Baganator.ItemButtonUtil = {}
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

local registered = false
function Baganator.ItemButtonUtil.UpdateSettings()
  if not registered  then
    registered = true
    Baganator.CallbackRegistry:RegisterCallback("SettingChangedEarly", function()
      Baganator.ItemButtonUtil.UpdateSettings()
    end)
  end
  itemCallbacks = {}

  local qualityColours = Baganator.Config.Get("icon_text_quality_colors")
  if Baganator.Config.Get("show_item_level") then
    table.insert(itemCallbacks, function(self, data)
      local itemLevel = GetDetailedItemLevelInfo(data.itemLink)
      self.ItemLevel:SetText(itemLevel)
      if qualityColours then
        local color = qualityColors[data.quality]
        self.ItemLevel:SetTextColor(color.r, color.g, color.b)
      else
        self.ItemLevel:SetTextColor(1,1,1)
      end
    end)
  end
  if Baganator.Config.Get("show_boe_status") then
    table.insert(itemCallbacks, function(self, data)
      if IsEquipment(data.itemLink) and not data.isBound then
        self.BindingText:SetText(BAGANATOR_L_BOE)
        if qualityColours then
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
        if qualityColours then
          local color = qualityColors[data.quality]
          self.BindingText:SetTextColor(color.r, color.g, color.b)
        else
          self.BindingText:SetTextColor(1,1,1)
        end
      end
    end)
  end
end

-- Load item data late
local function GetExtraInfo(self, itemID, itemLink, quality, data)
  if itemLink:find("keystone:", nil, true) then
    itemLink = "item:" .. itemID
  end

  if itemLink:find("battlepet:", nil, true) then
    self.itemInfoWaiting = false
    local petID = tonumber(itemLink:match("battlepet:(%d+)"))
    self.itemName = C_PetJournal.GetPetInfoBySpeciesID(petID)
    self.isCraftingReagent = false

  elseif C_Item.IsItemDataCachedByID(itemID) then
    self.itemInfoWaiting = false
    local itemInfo = {GetItemInfo(itemLink)}
    self.itemName = itemInfo[1]
    self.isCraftingReagent = itemInfo[17]
    if self.pendingSearch then
      self:SetItemFiltered(self.pendingSearch)
    end
    for _, callback in ipairs(itemCallbacks) do
      callback(self, data)
    end
  else
    local item = Item:CreateFromItemLink(itemLink)
    self.itemInfoWaiting = true
    item:ContinueOnItemLoad(function()
      self.itemInfoWaiting = false
      local itemInfo = {GetItemInfo(itemLink)}
      self.itemName = itemInfo[1]
      self.isCraftingReagent = itemInfo[17]
      if self.pendingSearch then
        self:SetItemFiltered(self.pendingSearch)
      end

      for _, callback in ipairs(itemCallbacks) do
        callback(self, data)
      end
    end)
  end
end

local function SetStaticInfo(self, details)
  self.BindingText:SetText("")
  self.ItemLevel:SetText("")
end

local function SearchCheck(self, text)
  if self.itemInfoWaiting then
    self.pendingSearch = text
    return
  end

  self.pendingSearch = nil

  if not self.itemName then
    return
  end

  if text ~= "" then
    self.itemNameLower = self.itemNameLower or self.itemName:lower()
  end
  return text == "" or not not self.itemNameLower:match(text)
end

local function ApplyItemDetailSettings(button, size)
  local scale = size / 42
  button.ItemLevel:SetPoint("TOPLEFT", 3 * scale, -3 * scale)
  button.BindingText:SetPoint("BOTTOMLEFT", 3 * scale, 3 * scale)
end

-- Fix anchors and item sizes when resizing the item buttons
local function AdjustRetailButton(button, size)
  button.IconBorder:SetSize(size, size)
  button.IconOverlay:SetSize(size, size)
  button.IconOverlay2:SetSize(size, size)
  local scaleNormal = 64/37 * size
  button.NormalTexture:SetSize(scaleNormal, scaleNormal)

  if Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND) then
    button.emptyBackgroundAtlas = nil
    if button.icon:GetAtlas() ~= nil then
      button.icon:SetAtlas(nil)
      button.icon:Hide()
    end
  else
    button.emptyBackgroundAtlas = "bags-item-slot64"
    if not button.icon:IsShown() then
      button.icon:Show()
      button.icon:SetAtlas(button.emptyBackgroundAtlas)
    end
  end
  ApplyItemDetailSettings(button, size)
end

-- Fix anchors and item sizes when resizing the item buttons
local function AdjustClassicButton(button, size)
  button.IconBorder:SetSize(size, size)
  button.IconOverlay:SetSize(size, size)
  local scaleNormal = 64/37 * size
  _G[button:GetName() .. "NormalTexture"]:SetSize(scaleNormal, scaleNormal)

  ApplyItemDetailSettings(button, size)
end

BaganatorRetailCachedItemButtonMixin = {}

function BaganatorRetailCachedItemButtonMixin:UpdateTextures(size)
  AdjustRetailButton(self, size)
end

function BaganatorRetailCachedItemButtonMixin:SetItemDetails(details)
  self:SetItemButtonTexture(details.iconTexture)
  self:SetItemButtonQuality(details.quality)
  self:SetItemButtonCount(details.itemCount)
  self.itemLink = details.itemLink
  self.itemName = ""

  SetStaticInfo(self, details)
  if details.iconTexture ~= nil then
    GetExtraInfo(self, details.itemID, self.itemLink, details.quality, details)
  end
end

function BaganatorRetailCachedItemButtonMixin:SetItemFiltered(text)
  self:SetMatchesSearch(SearchCheck(self, text))
end

function BaganatorRetailCachedItemButtonMixin:OnClick(button)
  if IsModifiedClick("CHATLINK") then
    ChatEdit_InsertLink(self.itemLink)
  end
end

function BaganatorRetailCachedItemButtonMixin:OnEnter()
  local itemLink = self.itemLink

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
  local itemLink = self.itemLink

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
  -- Automatically use the reagent bank when at the bank transferring crafting
  -- reagents
  self:HookScript("OnEnter", function()
    if BankFrame:IsShown() and self.isCraftingReagent then
      BankFrame.selectedTab = 2
    end
  end)
  self:HookScript("OnLeave", function()
    if BankFrame:IsShown() and self.isCraftingReagent then
      BankFrame.selectedTab = 1
    end
  end)
end

function BaganatorRetailLiveItemButtonMixin:UpdateTextures(size)
  AdjustRetailButton(self, size)

  local s2 = 64/37 * size
  if self.IconQuestTexture then
    self.IconQuestTexture:SetSize(size, size)
    self.ExtendedSlot:SetSize(s2, s2)
  end
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

  self.itemName = ""
  self.itemNameLower = nil

  SetStaticInfo(self, cacheData)
  if texture ~= nil then
    GetExtraInfo(self, itemID, cacheData.itemLink, cacheData.quality, cacheData)
  end
end

function BaganatorRetailLiveItemButtonMixin:SetItemFiltered(text)
  self:SetMatchesSearch(SearchCheck(self, text))
end

BaganatorClassicCachedItemButtonMixin = {}

function BaganatorClassicCachedItemButtonMixin:UpdateTextures(size)
  AdjustClassicButton(self, size)
end

function BaganatorClassicCachedItemButtonMixin:SetItemDetails(details)
  self.itemLink = details.itemLink
  self.itemName = ""
  self.itemNameLower = nil
  
  SetItemButtonTexture(self, details.iconTexture);
  SetItemButtonQuality(self, details.quality); -- Doesn't do much
  SetItemButtonCount(self, details.itemCount);

  SetStaticInfo(self, details)
  if details.iconTexture ~= nil then
    GetExtraInfo(self, details.itemID, details.itemLink, details.quality, details)
  end
end

function BaganatorClassicCachedItemButtonMixin:SetItemFiltered(text)
  self.searchOverlay:SetShown(not SearchCheck(self, text))
end

function BaganatorClassicCachedItemButtonMixin:OnClick(button)
  if IsModifiedClick("CHATLINK") then
    ChatEdit_InsertLink(self.itemLink)
  end
end

function BaganatorClassicCachedItemButtonMixin:OnEnter()
  local itemLink = self.itemLink

  if itemLink == nil then
    return
  end

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetHyperlink(itemLink)
  GameTooltip:Show()
end

function BaganatorClassicCachedItemButtonMixin:OnLeave()
  local itemLink = self.itemLink

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
  local info = C_Container.GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

  if cacheData.itemLink == nil then
    info = nil
  end

  self.itemLink = cacheData.itemLink
  self.itemName = ""
  self.itemNameLower = nil

  SetStaticInfo(self, cacheData)
  if cacheData.iconTexture ~= nil then
    GetExtraInfo(self, cacheData.itemID, cacheData.itemLink, cacheData.quality)
  end

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
  
  SetItemButtonTexture(self, texture);
  SetItemButtonQuality(self, quality, itemID);
  SetItemButtonCount(self, itemCount);
  SetItemButtonDesaturated(self, locked);
  
  ContainerFrameItemButton_SetForceExtended(self, false);

  UpdateQuestItemClassic(self)

  battlepayItemTexture = self.BattlepayItemTexture;
  newItemTexture = self.NewItemTexture;
  battlepayItemTexture:Hide();
  newItemTexture:Hide();

  self.JunkIcon:SetShown(false);

  if ( texture ) then
    ContainerFrame_UpdateCooldown(self:GetID(), self);
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
end

function BaganatorClassicLiveItemButtonMixin:SetItemFiltered(text)
  self.searchOverlay:SetShown(not SearchCheck(self, text))
end
