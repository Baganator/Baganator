local IsEquipment = Baganator.Utilities.IsEquipment

-- Load item data late
local function GetExtraInfo(frame, itemID, itemLink)
  if itemLink:match("keystone:") then
    itemLink = "item:" .. itemID
  end

  if itemLink:match("battlepet:") then
    frame.itemInfoWaiting = false
    local petID = tonumber(itemLink:match("battlepet:(%d+)"))
    frame.itemName = C_PetJournal.GetPetInfoBySpeciesID(petID)
    frame.isCraftingReagent = false

  elseif C_Item.IsItemDataCachedByID(itemID) then
    frame.itemInfoWaiting = false
    local itemInfo = {GetItemInfo(itemLink)}
    frame.itemName = itemInfo[1]
    frame.isCraftingReagent = itemInfo[17]
    if frame.pendingSearch then
      frame:SetItemFiltered(frame.pendingSearch)
    end

    if IsEquipment(itemLink) then
      local itemLevel = GetDetailedItemLevelInfo(itemLink)
      frame.ItemLevel:SetText(itemLevel)
      frame.ItemLevel:Show()
    end

  else
    local item = Item:CreateFromItemLink(itemLink)
    frame.itemInfoWaiting = true
    item:ContinueOnItemLoad(function()
      frame.itemInfoWaiting = false
      local itemInfo = {GetItemInfo(itemLink)}
      frame.itemName = itemInfo[1]
      frame.isCraftingReagent = itemInfo[17]
      if frame.pendingSearch then
        frame:SetItemFiltered(frame.pendingSearch)
      end

      if IsEquipment(itemLink) then
        local itemLevel = GetDetailedItemLevelInfo(itemLink)
        frame.ItemLevel:SetText(itemLevel)
        frame.ItemLevel:Show()
      end
    end)
  end
end

local function SearchCheck(self, text)
  if self.itemInfoWaiting then
    self.pendingSearch = text
    return
  end
  self.pendingSearch = nil
  if text ~= "" then
    self.itemNameLower = self.itemNameLower or self.itemName:lower()
  end
  return text == "" or not not self.itemNameLower:match(text)
end

-- Fix anchors and item sizes when resizing the item buttons
local function AdjustRetailButton(button, size)
  button.IconBorder:SetSize(size, size)
  button.IconOverlay:SetSize(size, size)
  button.IconOverlay2:SetSize(size, size)
  local s2 = 64/37 * size
  button.NormalTexture:SetSize(s2, s2)

  button.ItemLevel:SetPoint("TOPLEFT", 3, -5)
  if Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND) then
    button.emptyBackgroundAtlas = nil
  else
    button.emptyBackgroundAtlas = "bags-item-slot64"
  end
end

-- Fix anchors and item sizes when resizing the item buttons
local function AdjustClassicButton(button, size)
  button.IconBorder:SetSize(size, size)
  button.IconOverlay:SetSize(size, size)
  local s2 = 64/37 * size
  _G[button:GetName() .. "NormalTexture"]:SetSize(s2, s2)

  button.ItemLevel:SetPoint("TOPLEFT", 3, -5)
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
  self.ItemLevel:Hide()

  if details.iconTexture ~= nil then
    GetExtraInfo(self, details.itemID, self.itemLink)
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
  self.ItemLevel:Hide()

  if texture ~= nil then
    GetExtraInfo(self, itemID, cacheData.itemLink)
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
  self.ItemLevel:Hide()

  if details.iconTexture ~= nil then
    GetExtraInfo(self, details.itemID, details.itemLink)
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
  self.itemLink = cacheData.itemLink
  self.itemName = ""
  self.itemNameLower = nil
  self.ItemLevel:Hide()

  if cacheData.iconTexture ~= nil then
    GetExtraInfo(self, cacheData.itemID, cacheData.itemLink)
  end

  -- Copied code from Blizzard Container Frame logic
  local tooltipOwner = GameTooltip:GetOwner()

  local info = C_Container.GetContainerItemInfo(self:GetParent():GetID(), self:GetID())
  
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
