---@class addonTableBaganator
local addonTable = select(2, ...)
-- Blizzard Equipment sets (Wrath onwards)
if not addonTable.Constants.IsEra and Syndicator then
  local BlizzardSetTracker = CreateFrame("Frame")
  local EQUIPMENT_SETS_PATTERN = EQUIPMENT_SETS:gsub("%%s", "(.*)")

  function BlizzardSetTracker:OnLoad()
    FrameUtil.RegisterFrameForEvents(self, {
      "BANKFRAME_OPENED",
      "EQUIPMENT_SETS_CHANGED",
    })
    Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate", function()
      self:QueueScan()
      Syndicator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self)
    end, self)
    self.equipmentSetInfo = {}
    self.equipmentSetNames = {}

    Baganator.API.RegisterItemSetSource(addonTable.Locales.BLIZZARD, "blizzard", function(_, guid)
      return self.equipmentSetInfo[guid]
    end, function()
      return self.equipmentSetNames
    end)
  end
  BlizzardSetTracker:OnLoad()

  function BlizzardSetTracker:QueueScan()
    self:SetScript("OnUpdate", self.OnUpdate)
  end

  BlizzardSetTracker:SetScript("OnEvent", function(self, eventName)
    self.bankScan = eventName == "BANKFRAME_OPENED"
    self:QueueScan()
  end)

  function BlizzardSetTracker:OnUpdate()
    self:SetScript("OnUpdate", nil)
    self:ScanEquipmentSets()
  end

  -- Determine the GUID of all accessible items in an equipment set
  function BlizzardSetTracker:ScanEquipmentSets()
    local start = debugprofilestop()

    local oldSetInfo = CopyTable(self.equipmentSetInfo)

    local cache = {}
    local waiting = 0
    local loopComplete = false
    self.equipmentSetNames = {}
    local namesRef = self.equipmentSetNames -- Skip if another callback was triggered

    local function Finish()
      if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
        print("equipment set tracking took", debugprofilestop() - start)
      end
      if namesRef == self.equipmentSetNames and not tCompare(oldSetInfo, cache, 15) then
        self.equipmentSetInfo = cache
        Baganator.API.RequestItemButtonsRefresh()
      end
    end

    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
      local name, iconTexture = C_EquipmentSet.GetEquipmentSetInfo(setID)
      table.insert(self.equipmentSetNames, name)
      local info = {name = name, iconTexture = iconTexture}

      -- Check for invalid items as attempting to get their locations will cause
      -- a crash on Max OS X
      local validItems = true
      if IsMacClient() then
        for _, itemID in pairs(C_EquipmentSet.GetItemIDs(setID)) do
          if not C_Item.GetItemInfoInstant(itemID) then
            validItems = false
          end
        end
      end

      if validItems then
        -- Uses or {} because a set might exist without any associated item
        -- locations
        for _, locationID in pairs(C_EquipmentSet.GetItemLocations(setID) or {}) do
          if locationID ~= -1 and locationID ~= 0 and locationID ~= 1 then
            local player, bank, bags, _, slot, bag
            if addonTable.Constants.IsClassic then
              player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(locationID)
            else
              player, bank, bags, _, slot, bag = EquipmentManager_UnpackLocation(locationID)
            end
            local location, bagID, slotID
            if (player or bank) and bags then
              bagID = bag
              slotID = slot
              location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
            elseif bank and not bags then
              bagID = Syndicator.Constants.AllBankIndexes[1]
              slotID = slot - BankButtonIDToInvSlotID(0)
              location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
            elseif player then
              location = ItemLocation:CreateFromEquipmentSlot(slot)
            end
            if location then
              local guid = C_Item.GetItemGUID(location)
              if not cache[guid] then
                cache[guid] = {}
              end
              table.insert(cache[guid], info)
            end
          end
        end
      else
        -- API will crash, so we do a much more intensive tooltip scan of all possible items
        local matchingItemIDs = {}
        for _, itemID in pairs(C_EquipmentSet.GetItemIDs(setID)) do
          matchingItemIDs[itemID] = true
        end
        local function ProcessSlot(slot, location)
          if matchingItemIDs[slot.itemID] and C_Item.DoesItemExist(location) then
            local guid = C_Item.GetItemGUID(location)
            waiting = waiting + 1
            addonTable.Utilities.LoadItemData(slot.itemID, function()
              waiting = waiting - 1
              local tooltipInfo
              if addonTable.Constants.IsRetail then
                tooltipInfo = C_TooltipInfo.GetBagItem(location.bagID, location.slotIndex)
              elseif location.bagID == Syndicator.Constants.AllBankIndexes[1] then
                tooltipInfo = Syndicator.Search.DumpClassicTooltip(function(tooltip) tooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(location.slotIndex)) end)
              else
                tooltipInfo = Syndicator.Search.DumpClassicTooltip(function(tooltip) tooltip:SetBagItem(location.bagID, location.slotIndex) end)
              end
              for _, line in ipairs(tooltipInfo.lines) do
                local match = line.leftText:match(EQUIPMENT_SETS_PATTERN)
                if match then
                  for setName in match:gmatch("%s*([^" .. LIST_DELIMITER:gsub("%s", "") .. "]+)") do
                    if setName == name then
                      if not cache[guid] then
                        cache[guid] = {}
                      end
                      table.insert(cache[guid], info)
                      break
                    end
                  end
                end
              end
              if loopComplete and waiting == 0 then
                Finish()
              end
            end)
          end
        end
        local characterData = Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter())
        for bagIndex, bag in ipairs(characterData.bags) do
          for slotIndex, slot in ipairs(bag) do
            local location = {bagID = Syndicator.Constants.AllBagIndexes[bagIndex], slotIndex = slotIndex}
            ProcessSlot(slot, location)
          end
        end
        if self.bankScan then
          for bankIndex, bag in ipairs(characterData.bank) do
            for slotIndex, slot in ipairs(bag) do
              local location = {bagID = Syndicator.Constants.AllBankIndexes[bankIndex], slotIndex = slotIndex}
              ProcessSlot(slot, location)
            end
          end
        end
      end
    end
    self.bankScan = false

    if waiting == 0 then
      Finish()
    end
    loopComplete = true
  end
end

-- ItemRack Classic
if not addonTable.Constants.IsRetail then
  addonTable.Utilities.OnAddonLoaded("ItemRack", function()
    local equipmentSetInfo = {}
    local equipmentSetNames = {}
    local bankOpen, updatePending = false, false
    local function ItemRackUpdated()
      equipmentSetInfo = {}
      equipmentSetNames = {}
      for name, details in pairs(ItemRackUser.Sets) do
        if name:sub(1, 1) ~= "~" then
          table.insert(equipmentSetNames, name)
          local setInfo = {name = name, iconTexture = details.icon}
          local seenRefs = {}
          for _, itemRef in pairs(details.equip) do
            if itemRef ~= 0 then
              if seenRefs[itemRef] then -- Some sets use 2 trinkets/rings, this adds a special key for that
                itemRef = ";" .. itemRef
              end
              if not equipmentSetInfo[itemRef] then
                equipmentSetInfo[itemRef] = {}
              end
              table.insert(equipmentSetInfo[itemRef], setInfo)
              seenRefs[itemRef] = true
            end
          end
        end
      end
      table.sort(equipmentSetNames)
      updatePending = true

      Baganator.API.RequestItemButtonsRefresh()
    end
    ItemRackUpdated()

    ItemRack:RegisterExternalEventListener("ITEMRACK_SET_SAVED", ItemRackUpdated)
    ItemRack:RegisterExternalEventListener("ITEMRACK_SET_DELETED", ItemRackUpdated)

    local monitor = CreateFrame("Frame")
    local firstBankOpen = true
    monitor:RegisterEvent("BANKFRAME_OPENED")
    monitor:RegisterEvent("BANKFRAME_CLOSED")
    monitor:RegisterEvent("BAG_UPDATE")
    monitor:SetScript("OnEvent", function(_, eventName)
      if eventName == "BAG_UPDATE" then
        updatePending = true
      else
        bankOpen = eventName == "BANKFRAME_OPENED"
        updatePending = true
        if bankOpen and firstBankOpen then
          firstBankOpen = false
          Baganator.API.RequestItemButtonsRefresh()
        end
      end
    end)

    local guidToItemRef = {}
    -- Elaborate routine to mimic ItemRack's selection of items that match the
    -- set. Checks exact matches first, then inexact by item ID.
    local function RefreshSetItems()
      local start = debugprofilestop()
      local oldConversion = guidToItemRef
      guidToItemRef = {}
      local missing = {}
      local itemIDToGUID = {}
      for key in pairs(equipmentSetInfo) do
        missing[key] = true
      end
      local characterData = Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter())
      local function DoLocation(location, slotInfo)
        -- We check by inventory slot because some classic era trinkets are Trade Goods -> Devices
        if slotInfo.itemLink and select(4, C_Item.GetItemInfoInstant(slotInfo.itemLink)) ~= "INVTYPE_NON_EQUIP_IGNORE" and C_Item.DoesItemExist(location) then
          local runeSuffix = ""
          if ItemRack.AppendRuneID then
            local info
            if location.equipmentSlotIndex then
              info = C_Engraving.GetRuneForEquipmentSlot(location.equipmentSlotIndex)
            elseif location.bagID >= 0 then
              info = C_Engraving.GetRuneForInventorySlot(location.bagID, location.slotIndex)
            end
            if info then
              runeSuffix = ":runeid:"..tostring(info.skillLineAbilityID)
            else
              runeSuffix = ":runeid:0"
            end
          end
          local itemRackID = ItemRack.GetIRString(slotInfo.itemLink) .. runeSuffix
          local guid = C_Item.GetItemGUID(location)
          if missing[itemRackID] then
            missing[itemRackID] = nil
            guidToItemRef[guid] = itemRackID
          elseif missing[";" .. itemRackID] then
            guidToItemRef[guid] = ";" .. itemRackID
          end
          itemIDToGUID[slotInfo.itemID] = itemIDToGUID[slotInfo.itemID] or {}
          table.insert(itemIDToGUID[slotInfo.itemID], guid)
        end
      end
      local function DoBag(bagID, bagData)
        for slotID, slotInfo in ipairs(bagData) do
          local location = {bagID = bagID, slotIndex = slotID}
          DoLocation(location, slotInfo)
        end
      end
      for index, slotInfo in ipairs(characterData.equipped) do
        local location = {equipmentSlotIndex = index - Syndicator.Constants.EquippedInventorySlotOffset}
        DoLocation(location, slotInfo)
      end
      for index, bagData in ipairs(characterData.bags) do
        local bagID = Syndicator.Constants.AllBagIndexes[index]
        DoBag(bagID, bagData)
      end
      if bankOpen then
        for index, bagData in ipairs(characterData.bank) do
          local bagID = Syndicator.Constants.AllBankIndexes[index]
          DoBag(bagID, bagData)
        end
      end
      if next(missing) then
        for key in pairs(missing) do
          local itemID = tonumber((key:match("^;?%-?(%d+)")))
          if itemIDToGUID[itemID] and #itemIDToGUID[itemID] > 0 then
            local guid = table.remove(itemIDToGUID[itemID])
            if guid then
              guidToItemRef[guid] = key
            end
          end
        end
      end
      if not tCompare(guidToItemRef, oldConversion, 2) then
        Baganator.API.RequestItemButtonsRefresh()
      end
      if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
        print("item rack refresh took", debugprofilestop() - start)
      end
    end

    Baganator.API.RegisterItemSetSource("ItemRack", "item_rack_classic", function(_, guid, _)
      if updatePending then
        updatePending = false
        RefreshSetItems()
      end

      return equipmentSetInfo[guidToItemRef[guid]]
    end, function()
      return equipmentSetNames
    end)
  end)
end

addonTable.Utilities.OnAddonLoaded("Outfitter", function()
  local equipmentSetNames = {}
  local equipmentSetItemIDs = {}
  local function Update()
    equipmentSetNames = {}
    equipmentSetItemIDs = {}

    local categories = Outfitter_GetCategoryOrder()
    for _, c in ipairs(categories) do
      local outfits = Outfitter_GetOutfitsByCategoryID(c)
      for _, o in ipairs(outfits) do
        table.insert(equipmentSetNames, o:GetName())
        for _, item in pairs(o:GetItems()) do
          equipmentSetItemIDs[item.Code] = equipmentSetItemIDs[item.Code] or {}
          table.insert(equipmentSetItemIDs[item.Code], o:GetName())
        end
      end
    end

    Baganator.API.RequestItemButtonsRefresh()
  end

  if Outfitter_IsInitialized() then
    Update()
  else
    Outfitter_RegisterOutfitEvent("OUTFITTER_INIT", Update)
  end
  Outfitter_RegisterOutfitEvent("ADD_OUTFIT", Update)
  Outfitter_RegisterOutfitEvent("DELETE_OUTFIT", Update)
  Outfitter_RegisterOutfitEvent("EDIT_OUTFIT", Update)
  Outfitter_RegisterOutfitEvent("DID_RENAME_OUTFIT", Update)

  Baganator.API.RegisterItemSetSource("Outfitter", "outfitter", function(_, guid, itemLink)
    if not guid or not itemLink then
      return
    end
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then
      return
    end
    local setNames = equipmentSetItemIDs[itemID]
    if not setNames then
      return
    end

    local itemInfo = Outfitter_GetItemInfoFromLink(itemLink)

    local result = {}
    for _, name in ipairs(setNames) do
      local outfit = Outfitter_FindOutfitByName(name)
      if outfit and outfit:OutfitUsesItem(itemInfo) then
        table.insert(result, {
          name = name,
          iconTexture = outfit:GetIcon(),
        })
      end
    end
    return result
  end, function()
    return equipmentSetNames
  end)
end)
