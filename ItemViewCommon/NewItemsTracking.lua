local _, addonTable = ...
BaganatorItemViewCommonNewItemsTrackingMixin = {}

function BaganatorItemViewCommonNewItemsTrackingMixin:OnLoad()
  self:RegisterEvent("BANKFRAME_OPENED")
  self:RegisterEvent("BANKFRAME_CLOSED")
  self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")

  self.firstStart = true
  self.startupCooldown = false
  self.timeout = addonTable.Config.Get(addonTable.Config.Options.RECENT_TIMEOUT)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.RECENT_TIMEOUT then
      self.timeout = addonTable.Config.Get(addonTable.Config.Options.RECENT_TIMEOUT)
    end
  end)

  self.recentByContainer = {}

  self.recentTimeout = {}
  self.recentByContainerTimeout = {}

  self.seenGUIDs = {}

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
      local slotData = bagData[slotID]
      if slotData.itemID and C_Item.DoesItemExist(location) then
        local guid = C_Item.GetItemGUID(location)
        containerGuids[slotID] = guid
        if self.recentTimeout[guid] then
          -- Move bag item marker to reflect new item position
          local timeout = self.recentTimeout[guid]
          timeout.bagID, timeout.slotID = bagID, slotID
          self.recentByContainerTimeout[bagID][slotID] = guid
        end
        if self.recentByContainer[bagID][slotID] ~= guid then
          self.recentByContainer[bagID][slotID] = nil
        end
      else
        self.recentByContainer[bagID][slotID] = nil
        containerGuids[slotID] = -1
      end
    end
    self.guidsByContainer[bagID] = containerGuids
    if self.bankOpen then -- Items from the character/warband bank never count as new
      for _, guid in ipairs(containerGuids) do
        self.seenGUIDs[guid] = true
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
      if not self.startupCooldown then
        self.startupCooldown = true
        -- Cooldown for further "first start" events to fire on login
        C_Timer.After(5, function()
          self:UnregisterEvent("BAG_NEW_ITEMS_UPDATED")
          self.firstStart = false
        end)
      end
      for _, containerGuids in pairs(self.guidsByContainer) do
        for _, guid in ipairs(containerGuids) do
          self.seenGUIDs[guid] = true
        end
      end
      for guid in pairs(self.guidsEquipped) do
        self.seenGUIDs[guid] = true
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
  if eventName == "BANKFRAME_OPENED" or eventName == "BANKFRAME_CLOSED" then
    self.bankOpen = eventName == "BANKFRAME_OPENED"
  elseif eventName == "BAG_NEW_ITEMS_UPDATED" then
    self:UnregisterEvent("BAG_NEW_ITEMS_UPDATED")
    self.firstStart = false
  end
end

-- Compare previous set of seen items to the current items to determine which
-- are new
function BaganatorItemViewCommonNewItemsTrackingMixin:ImportNewItems(timeout)
  local newSeenGUIDs = {}
  local newItemLocations = {}
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
        elseif not self.seenGUIDs[guid] and self.recentByContainer[bagID] then
          table.insert(newItemLocations, {bagID = bagID, slotIndex = slotID})
          self.recentByContainer[bagID][slotID] = guid
          if timeout then
            self.recentTimeout[guid] = {time = GetTime(), bagID = bagID, slotID = slotID}
            self.recentByContainerTimeout[bagID][slotID] = guid
          end
        end
      end
      newSeenGUIDs[guid] = true
    end
  end

  for guid in pairs(self.guidsEquipped) do
    newSeenGUIDs[guid] = true
  end

  self.seenGUIDs = newSeenGUIDs

  addonTable.CallbackRegistry:TriggerEvent("NewItemsAcquired", newItemLocations)
end

-- Update any recents on a timeout
function BaganatorItemViewCommonNewItemsTrackingMixin:ClearNewItemsForTimeout()
  local anyChanges = false
  if self.timeout < 0 then
    for guid, details in pairs(self.recentTimeout) do
      if not self.seenGUIDs[guid] then
        anyChanges = true
        self.recentTimeout[guid] = nil
      end
    end
  else
    local time = GetTime()
    for guid, details in pairs(self.recentTimeout) do
      if not self.seenGUIDs[guid] or time - details.time >= self.timeout then
        anyChanges = true
        self.recentTimeout[guid] = nil
        if self.recentByContainerTimeout[details.bagID][details.slotID] == guid then
          self.recentByContainerTimeout[details.bagID][details.slotID] = nil
        end
      end
    end
  end

  return anyChanges
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

-- Mark a given item as no longer new for timeout tracking
function BaganatorItemViewCommonNewItemsTrackingMixin:ClearNewItemTimeout(bagID, slotID)
  if self.recentByContainerTimeout[bagID] then
    local guid = self.recentByContainerTimeout[bagID][slotID]
    if guid then
      self.recentTimeout[guid] = nil
      self.recentByContainerTimeout[bagID][slotID] = nil
    end
  end
end
