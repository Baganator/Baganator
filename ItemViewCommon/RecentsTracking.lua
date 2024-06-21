BaganatorItemViewCommonRecentsTrackingMixin = {}

function BaganatorItemViewCommonRecentsTrackingMixin:OnLoad()
  self.recent = {}
  self.recentByContainer = {}
  self.seen = {}
  self.guidsByContainer = {}
  self.guidsEquipped = {}
  self.firstStart = true

  for _, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    self.recentByContainer[bagID] = {}
  end

  local function ScanBagData(bagID, bagData)
    local containerGuids = {}
    for slotID = 1, #bagData do
      local location = {bagID = bagID, slotIndex = slotID}
      if bagData[slotID].itemID and C_Item.DoesItemExist(location) then
        local guid = C_Item.GetItemGUID(location)
        local itemID = C_Item.GetItemID(location)
        containerGuids[slotID] = guid
      else
        containerGuids[slotID] = -1
      end
    end
    self.guidsByContainer[bagID] = containerGuids
  end

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", function(_, character, updatedBags)
    local characterData = Syndicator.API.GetCharacter(character)
    for bagID in pairs(updatedBags.bags) do
      local bagIndex = tIndexOf(Syndicator.Constants.AllBagIndexes, bagID)
      ScanBagData(bagID, characterData.bags[bagIndex])
    end
    for bagID in pairs(updatedBags.bank) do
      local bagIndex = tIndexOf(Syndicator.Constants.AllBankIndexes, bagID)
      ScanBagData(bagID, characterData.bank[bagIndex])
    end
    Baganator.CallbackRegistry:TriggerEvent("BagCacheAfterRecentsUpdate", character, updatedBags)
  end)
  Syndicator.CallbackRegistry:RegisterCallback("WarbandBankCacheUpdate", function(_, warband, updatedBags)
    for bagID in pairs(updatedBags.bags) do
      local tabIndex = tIndexOf(Syndicator.Constants.AllWarbandIndexes, bagID)
      ScanBagData(bagID, Syndicator.API.GetWarband(warband).bank[tabIndex].slots)
    end
  end)
  Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function(_, character)
    local characterData = Syndicator.API.GetCharacter(character)
    for slot = 1, #characterData.equipped do
      local location = ItemLocation:CreateFromEquipmentSlot(slot - Syndicator.Constants.EquippedInventorySlotOffset)
      if characterData.equipped[slot].itemID and C_Item.DoesItemExist(location) then
        local guid = C_Item.GetItemGUID(location)
        self.guidsEquipped[guid] = true
      end
    end
  end)
end

function BaganatorItemViewCommonRecentsTrackingMixin:SetTimeout(timeout)
  self.timeout = timeout
end

function BaganatorItemViewCommonRecentsTrackingMixin:ImportRecents()
  if self.firstStart then
    self.firstStart = false
    for bagID, containerGuids in pairs(self.guidsByContainer) do
      for _, guid in ipairs(containerGuids) do
        if guid ~= -1 then
          self.seen[guid] = true
        end
      end
    end
    for guid in pairs(self.guidsEquipped) do
      self.seen[guid] = true
    end
    return
  end

  local newSeen = {}
  for bagID, containerGuids in pairs(self.guidsByContainer) do
    for slotID, guid in ipairs(containerGuids) do
      if guid == -1 and self.recentByContainer[bagID][slotID] then
        self.recent[self.recentByContainer[bagID][slotID]] = nil
        self.recentByContainer[bagID][slotID] = nil
      elseif guild ~= -1 and not self.seen[guid] and self.recentByContainer[bagID] then
        self.recent[guid] = {time = GetTime(), bagID = bagID, slotID = slotID}
        self.recentByContainer[bagID][slotID] = guid
      end
      newSeen[guid] = true
    end
  end

  for guid in pairs(self.guidsEquipped) do
    newSeen[guid] = true
  end

  self.seen = newSeen
end

function BaganatorItemViewCommonRecentsTrackingMixin:ClearRecents()
  local time = GetTime()
  for guid, details in pairs(self.recent) do
    if not self.seen[guid] then
      self.recent[guid] = nil
    elseif time - details.time >= self.timeout then
      self.recent[guid] = nil
      self.recentByContainer[details.bagID][details.slotID] = nil
    end
  end
end

function BaganatorItemViewCommonRecentsTrackingMixin:IsRecent(bagID, slotID)
  return self.recentByContainer[bagID][slotID] ~= nil
end

function BaganatorItemViewCommonRecentsTrackingMixin:CheckClearRecent(bagID, slotID)
  if self.timeout == 0 and self.recentByContainer[bagID] then
    self.recentByContainer[bagID][slotID] = nil
  end
end
