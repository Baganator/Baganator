local _, addonTable = ...
BaganatorItemViewCommonNewItemsTrackingMixin = {}

function BaganatorItemViewCommonNewItemsTrackingMixin:OnLoad()
  self:RegisterEvent("BANKFRAME_OPENED")
  self:RegisterEvent("BANKFRAME_CLOSED")

  self.firstStart = true
  self.timeout = addonTable.Config.Get(addonTable.Config.Options.RECENT_TIMEOUT)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.RECENT_TIMEOUT then
      self.timeout = addonTable.Config.Get(addonTable.Config.Options.RECENT_TIMEOUT)
    end
  end)

  self.recentByContainer = {}

  self.recentTimeout = {}
  self.recentByContainerTimeout = {}

  self.seen = {}

  self.guidsByContainer = {}
  self.guidsEquipped = {}

  for _, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    self.recentByContainer[bagID] = {}
    self.recentByContainerTimeout[bagID] = {}
  end

  local function ScanBagData(bagID, bagData)
    local containerGuids = {}
    for slotID = 1, #bagData do
      local location = {bagID = bagID, slotIndex = slotID}
      self.recentByContainerTimeout[bagID][slotID] = nil
      if bagData[slotID].itemID and C_Item.DoesItemExist(location) then
        local guid = C_Item.GetItemGUID(location)
        containerGuids[slotID] = guid
        if self.recentTimeout[guid] then
          -- Move bag item marker to reflect new item position
          local timeout = self.recentTimeout[guid]
          timeout.bagID, timeout.slotID = bagID, slotID
          self.recentByContainerTimeout[bagID][slotID] = guid
        end
      else
        containerGuids[slotID] = -1
      end
    end
    self.guidsByContainer[bagID] = containerGuids
    if self.bankOpen then -- Items from the character/warband bank never count as new
      for _, guid in ipairs(containerGuids) do
        self.seen[guid] = true
      end
    end
  end

  Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", function(_, character, updatedBags)
    local characterData = Syndicator.API.GetCharacter(character)
    for bagID in pairs(updatedBags.bags) do
      local bagIndex = tIndexOf(Syndicator.Constants.AllBagIndexes, bagID)
      ScanBagData(bagID, characterData.bags[bagIndex])
    end
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
    end
    addonTable.CallbackRegistry:TriggerEvent("BagCacheAfterNewItemsUpdate", character, updatedBags)
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

function BaganatorItemViewCommonNewItemsTrackingMixin:OnEvent(eventName)
  self.bankOpen = eventName == "BANKFRAME_OPENED"
end

-- Compare previous set of seen items to the current items to determine which
-- are new
function BaganatorItemViewCommonNewItemsTrackingMixin:ImportNewItems(timeout)
  local newSeen = {}
  for bagID, containerGuids in pairs(self.guidsByContainer) do
    for slotID, guid in ipairs(containerGuids) do
      if self.recentByContainer[bagID] then
        if guid == -1 then
          if self.recentByContainer[bagID][slotID] then
            self.recentByContainer[bagID][slotID] = nil
          end
          if self.recentByContainerTimeout[bagID][slotID] then
            self.recentByContainerTimeout[bagID][slotID] = nil
          end
        elseif guild ~= -1 and not self.seen[guid] and self.recentByContainer[bagID] then
          self.recentByContainer[bagID][slotID] = guid
          if timeout then
            self.recentTimeout[guid] = {time = GetTime(), bagID = bagID, slotID = slotID}
            self.recentByContainerTimeout[bagID][slotID] = guid
          end
        end
      end
      newSeen[guid] = true
    end
  end

  for guid in pairs(self.guidsEquipped) do
    newSeen[guid] = true
  end

  self.seen = newSeen
end

-- Update any recents on a timeout
function BaganatorItemViewCommonNewItemsTrackingMixin:ClearNewItemsForTimeout()
  if self.timeout < 0 then
    for guid, details in pairs(self.recentTimeout) do
      if not self.seen[guid] then
        self.recentTimeout[guid] = nil
      end
    end
  else
    local time = GetTime()
    for guid, details in pairs(self.recentTimeout) do
      if not self.seen[guid] then
        self.recentTimeout[guid] = nil
      elseif time - details.time >= self.timeout then
        self.recentTimeout[guid] = nil
        self.recentByContainerTimeout[details.bagID][details.slotID] = nil
      end
    end
  end
end

function BaganatorItemViewCommonNewItemsTrackingMixin:ForceClearNewItemsForTimeout()
  local any = next(self.recentTimeout) ~= nil
  for guid, details in pairs(self.recentTimeout) do
    self.recentTimeout[guid] = nil
    self.recentByContainerTimeout[details.bagID][details.slotID] = nil
  end
  if any then
    addonTable.CallbackRegistry:TriggerEvent("ForceClearedNewItems")
  end
end

function BaganatorItemViewCommonNewItemsTrackingMixin:IsNewItem(bagID, slotID)
  return self.recentByContainer[bagID] ~= nil and self.recentByContainer[bagID][slotID] ~= nil
end

function BaganatorItemViewCommonNewItemsTrackingMixin:IsNewItemTimeout(bagID, slotID)
  return self.recentByContainerTimeout[bagID] ~= nil and self.recentByContainerTimeout[bagID][slotID] ~= nil
end

-- Mark a given item as no longer new
function BaganatorItemViewCommonNewItemsTrackingMixin:ClearNewItem(bagID, slotID)
  if self.recentByContainer[bagID] then
    self.recentByContainer[bagID][slotID] = nil
  end
end
