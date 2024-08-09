local _, addonTable = ...
-- REGULAR BAGS
BaganatorRetailBagSlotButtonMixin = {}

local function GetBagInventorySlot(button)
  return C_Container.ContainerIDToInventoryID(button:GetID())
end

local function OnBagSlotClick(self, button)
  if IsModifiedClick("PICKUPITEM") then
    PickupBagFromSlot(GetBagInventorySlot(self))
  elseif button == "RightButton" then
    addonTable.ItemViewCommon.AddBlizzardBagContextMenu(self:GetID())
  else
    PutItemInBag(GetBagInventorySlot(self))
  end
end

local function ShowBagSlotTooltip(self)
  addonTable.CallbackRegistry:TriggerEvent("HighlightBagItems", {[self:GetID()] = true})
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetInventoryItem("player", GetBagInventorySlot(self))
  GameTooltip:Show()
end

local function HideBagSlotTooltip(self)
  addonTable.CallbackRegistry:TriggerEvent("ClearHighlightBag")
  GameTooltip:Hide()
end

function BaganatorRetailBagSlotButtonMixin:Init()
  self.isBag = true -- Passed into item button code to force slot count display
  self:RegisterForDrag("LeftButton")
  local inventorySlot = GetBagInventorySlot(self)
  local texture = GetInventoryItemTexture("player", inventorySlot)

  if texture == nil and not addonTable.Config.Get(addonTable.Config.Options.EMPTY_SLOT_BACKGROUND) then
    texture = select(2, GetInventorySlotInfo("Bag1"))
  end

  self:SetItemButtonTexture(texture)
  local itemID = GetInventoryItemID("player", inventorySlot)
  if itemID ~= nil then
    if C_Item.IsItemDataCachedByID(itemID) then
      -- Passs in itemID so that any skins hooking SetItemButtonQuality can use
      -- it - as a bonus if Blizzard adds any widgets to bags this will add them
      self:SetItemButtonQuality(GetInventoryItemQuality("player", inventorySlot), itemID)
    else
      Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
        self:SetItemButtonQuality(GetInventoryItemQuality("player", inventorySlot), itemID)
      end)
    end
  end
  self:SetItemButtonCount(C_Container.GetContainerNumFreeSlots(self:GetID()))
end

function BaganatorRetailBagSlotButtonMixin:OnClick(button)
  OnBagSlotClick(self, button)
end

function BaganatorRetailBagSlotButtonMixin:OnDragStart()
  if not self:IsEnabled() then
    return
  end

  PickupBagFromSlot(GetBagInventorySlot(self))
end

function BaganatorRetailBagSlotButtonMixin:OnReceiveDrag()
  if not self:IsEnabled() then
    return
  end

  PutItemInBag(GetBagInventorySlot(self))
end

function BaganatorRetailBagSlotButtonMixin:OnEnter()
  ShowBagSlotTooltip(self)
end

function BaganatorRetailBagSlotButtonMixin:OnLeave()
  HideBagSlotTooltip(self)
end

BaganatorClassicBagSlotButtonMixin = {}

function BaganatorClassicBagSlotButtonMixin:Init()
  self.isBag = true -- Passed into item button code to force slot count display
  self:RegisterForDrag("LeftButton")

  SetItemButtonCount(self, C_Container.GetContainerNumFreeSlots(self:GetID()))

  local inventorySlot = GetBagInventorySlot(self)

  local texture = GetInventoryItemTexture("player", inventorySlot)

  if texture == nil and not addonTable.Config.Get(addonTable.Config.Options.EMPTY_SLOT_BACKGROUND) then
    texture = select(2, GetInventorySlotInfo("Bag1"))
  end

  SetItemButtonTexture(self, texture)
  local itemID = GetInventoryItemID("player", inventorySlot)
  if itemID ~= nil then
    Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
      SetItemButtonQuality(self, GetInventoryItemQuality("player", inventorySlot))
    end)
  end
  SetItemButtonQuality(self, GetInventoryItemQuality("player", inventorySlot))
end

function BaganatorClassicBagSlotButtonMixin:OnClick()
  OnBagSlotClick(self)
end

function BaganatorClassicBagSlotButtonMixin:OnDragStart()
  if not self:IsEnabled() then
    return
  end

  PickupBagFromSlot(GetBagInventorySlot(self))
end

function BaganatorClassicBagSlotButtonMixin:OnReceiveDrag()
  if not self:IsEnabled() then
    return
  end

  PutItemInBag(GetBagInventorySlot(self))
end

function BaganatorClassicBagSlotButtonMixin:OnEnter()
  ShowBagSlotTooltip(self)
end

function BaganatorClassicBagSlotButtonMixin:OnLeave()
  HideBagSlotTooltip(self)
end

-- BANK

local function GetBankInventorySlot(button)
  return BankButtonIDToInvSlotID(button:GetID(), 1)
end

StaticPopupDialogs["addonTable.ConfirmBuyBankSlot"] = {
  text = CONFIRM_BUY_BANK_SLOT,
  button1 = YES,
  button2 = NO,
  OnAccept = function(self)
    PurchaseSlot()
  end,
  OnShow = function(self)
    MoneyFrame_Update(self.moneyFrame, GetBankSlotCost(GetNumBankSlots()))
  end,
  hasMoneyFrame = 1,
  timeout = 0,
  hideOnEscape = 1,
}

local function OnBankSlotClick(self, button)
  if button == "RightButton" then
    addonTable.ItemViewCommon.AddBlizzardBagContextMenu(Syndicator.Constants.AllBankIndexes[self:GetID() + 1])
  elseif not self.needPurchase then
    if IsModifiedClick("PICKUPITEM") then
      PickupBagFromSlot(GetBankInventorySlot(self))
    else
      PutItemInBag(GetBankInventorySlot(self))
    end
  else
    StaticPopup_Show("addonTable.ConfirmBuyBankSlot")
  end
end

local function ShowBankSlotTooltip(self)
  addonTable.CallbackRegistry:TriggerEvent("HighlightBagItems", {[Syndicator.Constants.AllBankIndexes[self:GetID() + 1]] = true})

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if self.needPurchase then
    GameTooltip:SetText(BANK_BAG_PURCHASE)
    GameTooltip:AddLine(addonTable.Utilities.GetMoneyString(GetBankSlotCost(GetNumBankSlots()), true), 1, 1, 1)
  else
    GameTooltip:SetInventoryItem("player", GetBankInventorySlot(self))
  end
  GameTooltip:Show()
end

local function HideBankSlotTooltip(self)
  addonTable.CallbackRegistry:TriggerEvent("ClearHighlightBag")
  GameTooltip:Hide()
end

local function GetBankBagInfo(bankBagID)
  local inventoryID = BankButtonIDToInvSlotID(bankBagID, 1)
  local texture = GetInventoryItemTexture("player", inventoryID)
  local quality = GetInventoryItemQuality("player", inventoryID)
  local itemID = GetInventoryItemID("player", inventoryID)

  return itemID, texture, quality
end

BaganatorRetailBankButtonMixin = {}

function BaganatorRetailBankButtonMixin:Init()
  self.isBag = true
  self:RegisterForDrag("LeftButton")
  self:SetItemButtonCount(C_Container.GetContainerNumFreeSlots(Syndicator.Constants.AllBankIndexes[self:GetID() + 1]))
  self.needPurchase = true

  local _, texture = GetInventorySlotInfo("Bag1")
  self:SetItemButtonTexture(texture)
  self:SetItemButtonQuality(nil)
  if self:GetID() > GetNumBankSlots() then
    SetItemButtonTextureVertexColor(self, 1.0,0.1,0.1)
    return
  end
  self.needPurchase = false
  SetItemButtonTextureVertexColor(self, 1.0,1.0,1.0)
  local itemID, texture, quality = GetBankBagInfo(self:GetID())
  if itemID == nil then
    return
  end
  self:SetItemButtonTexture(texture)
  self:SetItemButtonQuality(quality, itemID)
  Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
    self:SetItemButtonQuality(C_Item.GetItemQualityByID(itemID), itemID)
  end)
end

function BaganatorRetailBankButtonMixin:OnClick(button)
  OnBankSlotClick(self, button)
end

function BaganatorRetailBankButtonMixin:OnDragStart()
  if not self:IsEnabled() then
    return
  end

  PickupBagFromSlot(GetBankInventorySlot(self))
end

function BaganatorRetailBankButtonMixin:OnReceiveDrag()
  if not self:IsEnabled() then
    return
  end

  PutItemInBag(GetBankInventorySlot(self))
end

function BaganatorRetailBankButtonMixin:OnEnter()
  ShowBankSlotTooltip(self)
end

function BaganatorRetailBankButtonMixin:OnLeave()
  HideBankSlotTooltip(self)
end

BaganatorClassicBankButtonMixin = {}

function BaganatorClassicBankButtonMixin:Init()
  self.isBag = true
  self:RegisterForDrag("LeftButton")
  self.needPurchase = true

  SetItemButtonCount(self, C_Container.GetContainerNumFreeSlots(Syndicator.Constants.AllBankIndexes[self:GetID() + 1]))

  local _, texture = GetInventorySlotInfo("Bag1")
  SetItemButtonTexture(self, texture)
  SetItemButtonQuality(self, nil)
  if self:GetID() > GetNumBankSlots() then
    SetItemButtonTextureVertexColor(self, 1.0,0.1,0.1)
    return
  end
  SetItemButtonTextureVertexColor(self, 1.0,1.0,1.0)
  self.needPurchase = false
  local info = C_Container.GetContainerItemInfo(Enum.BagIndex.Bankbag, self:GetID())
  if info == nil then
    return
  end
  SetItemButtonTexture(self, info.iconFileID)
  SetItemButtonQuality(self, info.quality)
  Item:CreateFromItemID(info.itemID):ContinueOnItemLoad(function()
    SetItemButtonQuality(self, C_Item.GetItemQualityByID(info.itemID))
  end)
end

function BaganatorClassicBankButtonMixin:OnClick()
  OnBankSlotClick(self)
end

function BaganatorClassicBankButtonMixin:OnDragStart()
  if not self:IsEnabled() then
    return
  end

  PickupBagFromSlot(GetBankInventorySlot(self))
end

function BaganatorClassicBankButtonMixin:OnReceiveDrag()
  if not self:IsEnabled() then
    return
  end

  PutItemInBag(GetBankInventorySlot(self))
end

function BaganatorClassicBankButtonMixin:OnEnter()
  ShowBankSlotTooltip(self)
end

function BaganatorClassicBankButtonMixin:OnLeave()
  HideBankSlotTooltip(self)
end

BaganatorBagSlotsContainerMixin = {}

function BaganatorBagSlotsContainerMixin:OnLoad()
  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
    if updatedBags.containerBags == nil or updatedBags.containerBags[self.mode] or next(updatedBags[self.mode]) then
      self.updateBagSlotsNeeded = true
      if self:IsVisible() then
        self:Update(character, self.isLive)
      end
    end
  end)
  self.updateBagSlotsNeeded = true

  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
  })

  local bagSlotsCount
  local GetBagSlotButton
  local bagIndexes
  if self.mode == "bags" then
    GetBagSlotButton = function()
      if addonTable.Constants.IsRetail then
        return CreateFrame("ItemButton", nil, self, "BaganatorRetailBagSlotButtonTemplate")
      else
        return CreateFrame("Button", nil, self, "BaganatorClassicBagSlotButtonTemplate")
      end
    end
    bagSlotsCount = Syndicator.Constants.BagSlotsCount
    self.config = addonTable.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS
    bagIndexes = Syndicator.Constants.AllBagIndexes
  elseif self.mode == "bank" then
    GetBagSlotButton = function()
      if addonTable.Constants.IsRetail then
        return CreateFrame("ItemButton", nil, self, "BaganatorRetailBankButtonTemplate")
      else
        return CreateFrame("Button", nil, self, "BaganatorClassicBankButtonTemplate")
      end
    end
    bagSlotsCount = Syndicator.Constants.BankBagSlotsCount
    self.config = addonTable.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS
    bagIndexes = Syndicator.Constants.AllBankIndexes
  end

  self.liveBagSlots = {}
  for index = 1, bagSlotsCount do
    local bb = GetBagSlotButton()
    table.insert(self.liveBagSlots, bb)
    bb:SetID(index)
    if #self.liveBagSlots == 1 then
      bb:SetPoint("BOTTOMLEFT")
    else
      bb:SetPoint("TOPLEFT", self.liveBagSlots[#self.liveBagSlots - 1], "TOPRIGHT")
    end
    addonTable.Skins.AddFrame("ItemButton", bb)
  end

  local cachedBagSlotCounter = 0
  local function GetCachedBagSlotButton()
    -- Use cached item buttons from cached layout views
    if addonTable.Constants.IsRetail then
      return CreateFrame("ItemButton", nil, self, "BaganatorRetailCachedItemButtonTemplate")
    else
      cachedBagSlotCounter = cachedBagSlotCounter + 1
      return CreateFrame("Button", "BGRCachedBagSlotItemButton" .. cachedBagSlotCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end
  end

  self.cachedBagSlots = {}
  for index = 1, bagSlotsCount do
    local bb = GetCachedBagSlotButton()
    addonTable.Skins.AddFrame("ItemButton", bb)
    bb:UpdateTextures()
    bb.isBag = true
    table.insert(self.cachedBagSlots, bb)
    bb:SetID(bagIndexes[index + 1])
    bb:HookScript("OnEnter", function(self)
      addonTable.CallbackRegistry:TriggerEvent("HighlightBagItems", {[self:GetID()] = true})
    end)
    bb:HookScript("OnLeave", function(self)
      addonTable.CallbackRegistry:TriggerEvent("ClearHighlightBag")
    end)
    if #self.cachedBagSlots == 1 then
      bb:SetPoint("BOTTOMLEFT")
    else
      bb:SetPoint("TOPLEFT", self.cachedBagSlots[#self.cachedBagSlots - 1], "TOPRIGHT")
    end
    addonTable.Skins.AddFrame("ItemButton", bb)
  end
end

function BaganatorBagSlotsContainerMixin:Update(character, isLive)
  self.isLive = isLive
  if self.updateBagSlotsNeeded then
    self.updateBagSlotsNeeded = false
    for _, bb in ipairs(self.liveBagSlots) do
      bb:Init()
    end
  end

  local show = isLive and addonTable.Config.Get(self.config)
  for _, bb in ipairs(self.liveBagSlots) do
    -- Show live bag slots if viewing live bags/bank
    bb:SetShown(show)
  end

  -- Show cached bag slots when viewing cached bags for other characters
  local containerInfo = Syndicator.API.GetCharacter(character).containerInfo
  if not isLive and containerInfo and containerInfo[self.mode] then
    local show = addonTable.Config.Get(self.config)
    for index, bb in ipairs(self.cachedBagSlots) do
      local details = CopyTable(containerInfo[self.mode][index] or {})
      details.itemCount = addonTable.Utilities.CountEmptySlots(Syndicator.API.GetCharacter(character)[self.mode][index + 1])
      bb:SetItemDetails(details)
      if not details.iconTexture and not addonTable.Config.Get(addonTable.Config.Options.EMPTY_SLOT_BACKGROUND) then
        local _, texture = GetInventorySlotInfo("Bag1")
        SetItemButtonTexture(bb, texture)
      end
      bb:SetShown(show)
    end
  else
    for _, bb in ipairs(self.cachedBagSlots) do
      bb:Hide()
    end
  end
end

function BaganatorBagSlotsContainerMixin:OnEvent(eventName)
  if eventName == "PLAYER_REGEN_DISABLED" then
    -- Disable bag bag slots buttons in combat as pickup/drop doesn't work then
    if not self.liveBagSlots then
      return
    end
    for _, button in ipairs(self.liveBagSlots) do
      SetItemButtonDesaturated(button, true)
      button:Disable()
    end
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    if not self.liveBagSlots then
      return
    end
    for _, button in ipairs(self.liveBagSlots) do
      SetItemButtonDesaturated(button, false)
      button:Enable()
    end
  elseif eventName == "MODIFIER_STATE_CHANGED" then
    self:UpdateAllButtons()
  end
end
