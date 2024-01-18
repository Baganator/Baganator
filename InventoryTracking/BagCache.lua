BaganatorBagCacheMixin = {}

local bankBags = {}
local bagBags = {}
for index, key in ipairs(Baganator.Constants.AllBagIndexes) do
  bagBags[key] = index
end
for index, key in ipairs(Baganator.Constants.AllBankIndexes) do
  bankBags[key] = index
end

local function GetEmptyPending()
  return {
    bags = {},
    bank = {},
  }
end

-- Assumed to run after PLAYER_LOGIN
function BaganatorBagCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    -- Regular bag items updating
    "BAG_UPDATE",
    -- Bag replaced
    "BAG_CONTAINER_UPDATE",

    -- Bank open/close (used to determine whether to cache or not)
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED",
  })
  if not Baganator.Constants.IsClassic then
    -- Bank items reagent bank updating
    self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
    self:RegisterEvent("REAGENTBANK_UPDATE")
  end

  self.currentCharacter = Baganator.Utilities.GetCharacterFullName()

  self:SetupPending()

  for bagID in pairs(bagBags) do
    self.pending.bags[bagID] = true
  end

  self:ScanContainerBagSlots()
  self:QueueCaching()
end

function BaganatorBagCacheMixin:QueueCaching()
  self:SetScript("OnUpdate", self.OnUpdate)
end

function BaganatorBagCacheMixin:OnEvent(eventName, ...)
  if eventName == "BAG_UPDATE" then
    local bagID = ...
    if bagBags[bagID] then
      self.pending.bags[bagID] = true
    elseif bankBags[bagID] and self.bankOpen then
      self.pending.bank[bagID] = true
    end
    self:QueueCaching()

  elseif eventName == "PLAYERBANKSLOTS_CHANGED" then
    self.pending.bank[Enum.BagIndex.Bank] = true
    self:QueueCaching()

  elseif eventName == "PLAYERREAGENTBANKSLOTS_CHANGED" then
    self.pending.bank[Enum.BagIndex.Reagentbank] = true
    self:QueueCaching()

  elseif eventName == "REAGENTBANK_UPDATE" then
    self.pending.bank[Enum.BagIndex.Reagentbank] = true
    self:QueueCaching()

  elseif eventName == "BAG_CONTAINER_UPDATE" then
    self:UpdateContainerSlots()

  elseif eventName == "BANKFRAME_OPENED" then
    self.bankOpen = true
    for bagID in pairs(bankBags) do
      self.pending.bank[bagID] = true
    end
    self:ScanContainerBagSlots()
    self:QueueCaching()
  elseif eventName == "BANKFRAME_CLOSED" then
    self.bankOpen = false
  elseif eventName == "EQUIPMENT_SETS_CHANGED" then
    for bagID in pairs(bagBags) do
      self.pending.bags[bagID] = true
    end
    if self.bankOpen then
      for bagID in pairs(bankBags) do
        self.pending.bank[bagID] = true
      end
    end
    self:QueueCaching()
  end
end

function BaganatorBagCacheMixin:SetupPending()
  -- Used to batch updates until the next OnUpdate tick
  self.pending = GetEmptyPending()
end

function BaganatorBagCacheMixin:UpdateContainerSlots()
  if not self.currentCharacter then
    return
  end

  local bags = BAGANATOR_DATA.Characters[self.currentCharacter].bags
  for index, bagID in ipairs(Baganator.Constants.AllBagIndexes) do
    local numSlots = C_Container.GetContainerNumSlots(bagID)
    if (bags[index] and numSlots ~= #bags[index]) or (bags[index] == nil and numSlots > 0) then
      self.pending.bags[bagID] = true
    end
  end

  if self.bankOpen then
    local bank = BAGANATOR_DATA.Characters[self.currentCharacter].bank
    for index, bagID in ipairs(Baganator.Constants.AllBankIndexes) do
      local numSlots = C_Container.GetContainerNumSlots(bagID)
      if (bank[index] and numSlots ~= #bank[index]) or (bank[index] == nil and numSlots > 0) then
        self.pending.bank[bagID] = true
      end
    end
  end

  self:ScanContainerBagSlots()
  self:QueueCaching()
end

function BaganatorBagCacheMixin:ScanContainerBagSlots()
  local function DoBagSlot(inventorySlot)
    local location = ItemLocation:CreateFromEquipmentSlot(inventorySlot)
    local itemID = GetInventoryItemID("player", inventorySlot)
    if not itemID then
      return {}
    else
      return {
        itemID = itemID,
        itemCount = 1,
        iconTexture = GetInventoryItemTexture("player", inventorySlot),
        itemLink = GetInventoryItemLink("player", inventorySlot),
        quality = GetInventoryItemQuality("player", inventorySlot),
        isBound = C_Item.IsBound(location),
      }
    end
  end
  local containerInfo = BAGANATOR_DATA.Characters[self.currentCharacter].containerInfo
  do
    containerInfo.bags = {}
    for index = 1, Baganator.Constants.BagSlotsCount do
      local inventorySlot = C_Container.ContainerIDToInventoryID(index)
      local itemID = GetInventoryItemID("player", inventorySlot)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          containerInfo.bags[index] = DoBagSlot(inventorySlot)
        else
          local item = Item:CreateFromItemID(itemID)
          item:ContinueOnItemLoad(function()
            containerInfo.bags[index] = DoBagSlot(inventorySlot)
          end)
        end
      else
        containerInfo.bags[index] = {}
      end
    end
  end

  if self.bankOpen then
    containerInfo.bank = {}
    for index = 1, Baganator.Constants.BankBagSlotsCount do
      local inventorySlot = BankButtonIDToInvSlotID(index, 1)
      local itemID = GetInventoryItemID("player", inventorySlot)
      if itemID ~= nil then
        if C_Item.IsItemDataCachedByID(itemID) then
          containerInfo.bank[index] = DoBagSlot(inventorySlot)
        else
          local item = Item:CreateFromItemID(itemID)
          item:ContinueOnItemLoad(function()
            containerInfo.bank[index] = DoBagSlot(inventorySlot)
          end)
        end
      else
        containerInfo.bank[index] = {}
      end
    end
  end
end

function BaganatorBagCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)
  if self.currentCharacter == nil then
    return
  end

  local start = debugprofilestop()

  local pendingCopy = CopyTable(self.pending)

  local function FireBagChange()
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("caching took", debugprofilestop() - start)
    end
    Baganator.CallbackRegistry:TriggerEvent("BagCacheUpdate", self.currentCharacter, pendingCopy)
  end

  local waiting = 0
  local loopsFinished = false

  local function GetInfo(slotInfo, itemGUID)
    return {
      itemID = slotInfo.itemID,
      itemCount = slotInfo.stackCount,
      iconTexture = slotInfo.iconFileID,
      itemLink = slotInfo.hyperlink,
      quality = slotInfo.quality,
      isBound = slotInfo.isBound,
      hasNoValue = slotInfo.hasNoValue or nil,
    }
  end


  local function DoBag(bagID, bag)
    for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
      local location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
      local itemID = C_Item.DoesItemExist(location) and C_Item.GetItemID(location)
      bag[slotID] = {}
      if itemID then
        local itemGUID = C_Item.GetItemGUID(location)
        if C_Item.IsItemDataCachedByID(itemID) then
          local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)
          if slotInfo then
            bag[slotID] = GetInfo(slotInfo, itemGUID)
          end
        else
          waiting = waiting + 1
          local item = Item:CreateFromItemID(itemID)
          item:ContinueOnItemLoad(function()
            local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            if slotInfo and slotInfo.itemID == itemID then
              bag[slotID] = GetInfo(slotInfo, itemGUID)
            end
            waiting = waiting - 1
            if loopsFinished and waiting == 0 then
              FireBagChange()
            end
          end)
        end
      end
    end
  end

  local bags = BAGANATOR_DATA.Characters[self.currentCharacter].bags

  for bagID in pairs(self.pending.bags) do
    local bagIndex = bagBags[bagID]
    bags[bagIndex] = {}
    DoBag(bagID, bags[bagIndex])
  end

  local bank = BAGANATOR_DATA.Characters[self.currentCharacter].bank

  for bagID in pairs(self.pending.bank) do
    local bagIndex = bankBags[bagID]
    bank[bagIndex] = {}
    if bagID ~= Enum.BagIndex.Reagentbank or IsReagentBankUnlocked() then
      DoBag(bagID, bank[bagIndex])
    end
  end

  loopsFinished = true

  self:SetupPending()

  if waiting == 0 then
    FireBagChange()
  end
end
