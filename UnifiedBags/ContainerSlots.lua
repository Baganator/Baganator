local function GetBankInventorySlot(button)
  return BankButtonIDToInvSlotID(button:GetID(), 1)
end

StaticPopupDialogs["Baganator.ConfirmBuyBankSlot"] = {
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

local function OnBankSlotClick(self)
  if not self.needPurchase then
    if IsModifiedClick("PICKUPITEM") then
      PickupBagFromSlot(GetBankInventorySlot(self))
    else
      PutItemInBag(GetBankInventorySlot(self))
    end
  else
    StaticPopup_Show("Baganator.ConfirmBuyBankSlot")
  end
end

local function ShowBankSlotTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if self.needPurchase then
    GameTooltip:SetText(BANK_BAG_PURCHASE)
    GameTooltip:AddLine(GetMoneyString(GetBankSlotCost(GetNumBankSlots()), true), 1, 1, 1)
  else
    GameTooltip:SetInventoryItem("player", GetBankInventorySlot(self))
  end
  GameTooltip:Show()
end

--[[
BaganatorRetailBagButtonMixin = {}

local function GetBagInventorySlot(button)
  return C_Container.ContainerIDToInventoryID(button:GetID())
end

function BaganatorRetailBagButtonMixin:Init()
  self:RegisterForDrag("LeftButton")
  local inventorySlot = GetBagInventorySlot(self)
  self:SetItemButtonTexture(GetInventoryItemTexture("player", inventorySlot))
  self:SetItemButtonQuality(GetInventoryItemQuality("player", inventorySlot))
  self:SetItemButtonCount(1)
end

function BaganatorRetailBagButtonMixin:OnClick()
  if IsModifiedClick("PICKUPITEM") then
    PickupBagFromSlot(GetBagInventorySlot(self))
  else
    PutItemInBag(GetBagInventorySlot(self))
  end
end

function BaganatorRetailBagButtonMixin:OnDragStart()
  PickupBagFromSlot(GetBagInventorySlot(self))
end

function BaganatorRetailBagButtonMixin:OnReceiveDrag()
  PutItemInBag(GetBagInventorySlot(self))
end

function BaganatorRetailBagButtonMixin:OnEnter()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetInventoryItem("player", GetBagInventorySlot(self))
  GameTooltip:Show()
end

function BaganatorRetailBagButtonMixin:OnLeave()
  GameTooltip:Hide()
end
]]

BaganatorRetailBankButtonMixin = {}

function BaganatorRetailBankButtonMixin:Init()
  self:RegisterForDrag("LeftButton")
  self:SetItemButtonCount(1)
  self.needPurchase = true

  local _, texture = GetInventorySlotInfo("Bag1")
  self.icon:SetTexture(texture)
  if self:GetID() > GetNumBankSlots() then
    SetItemButtonTextureVertexColor(self, 1.0,0.1,0.1)
    return
  end
  self.needPurchase = false
  SetItemButtonTextureVertexColor(self, 1.0,1.0,1.0)
  local info = C_Container.GetContainerItemInfo(Enum.BagIndex.Bankbag, self:GetID())
  if info == nil then
    return
  end
  self:SetItemButtonTexture(info.iconFileID)
  self:SetItemButtonQuality(info.quality)
end

function BaganatorRetailBankButtonMixin:OnClick()
  OnBankSlotClick(self)
end

function BaganatorRetailBankButtonMixin:OnDragStart()
  PickupBagFromSlot(GetBankInventorySlot(self))
end

function BaganatorRetailBankButtonMixin:OnReceiveDrag()
  PutItemInBag(GetBankInventorySlot(self))
end

function BaganatorRetailBankButtonMixin:OnEnter()
  ShowBankSlotTooltip(self)
end

function BaganatorRetailBankButtonMixin:OnLeave()
  GameTooltip:Hide()
end

BaganatorClassicBankButtonMixin = {}

function BaganatorClassicBankButtonMixin:Init()
  self:RegisterForDrag("LeftButton")
  self.needPurchase = true

  SetItemButtonCount(self, 1)

  local _, texture = GetInventorySlotInfo("Bag1")
  self.icon:SetTexture(texture)
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
end

function BaganatorClassicBankButtonMixin:OnClick()
  OnBankSlotClick(self)
end

function BaganatorClassicBankButtonMixin:OnDragStart()
  PickupBagFromSlot(GetBankInventorySlot(self))
end

function BaganatorClassicBankButtonMixin:OnReceiveDrag()
  PutItemInBag(GetBankInventorySlot(self))
end

function BaganatorClassicBankButtonMixin:OnEnter()
  ShowBankSlotTooltip(self)
end

function BaganatorClassicBankButtonMixin:OnLeave()
  GameTooltip:Hide()
end
