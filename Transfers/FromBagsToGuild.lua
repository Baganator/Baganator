---@class addonTableBaganator
local addonTable = select(2, ...)
local IsBagSlotLocked = addonTable.Transfers.IsContainerItemLocked

local function GetSwap(source, targets, stackLimit)
  if IsBagSlotLocked(source) then
    return nil, true
  end

  for index, item in ipairs(targets) do
    if item.itemID == nil or (item.itemID == source.itemID and item.itemCount + source.itemCount <= stackLimit) then
      table.remove(targets, index)
      return item, false
    end
  end

  return nil, false
end

local modes = {
  "BagCacheUpdate",
  "GuildCacheUpdate",
}

-- Runs one step of the transfer operation. Returns a value indicating if this
-- needs to be run again on a later frame.
-- toMove: Items requested to move {itemID: number, tabIndex: number, slotID: number}
-- bagIDs: The IDs of bags involved with taking or receiving items
-- guildTargets: Slots for the items to move to (all empty)
function addonTable.Transfers.FromBagsToGuild(toMove, guildTargets)
  if #toMove == 0 or InCombatLockdown() then -- Transfers breaks during combat due to Blizzard restrictions
    return addonTable.Constants.SortStatus.Complete
  end
  if Syndicator.API.IsBagEventPending() or Syndicator.API.IsGuildEventPending() then
    return addonTable.Constants.SortStatus.WaitingMove, modes
  end

  local oldCount = #toMove

  toMove = tFilter(toMove, function(item) return not item.isBound end, true)
  if C_Item.IsItemBindToAccountUntilEquip then
    toMove = tFilter(toMove, function(item) return not C_Item.IsItemBindToAccountUntilEquip(item.itemLink) end, true)
  end

  if #toMove ~= oldCount then
    UIErrorsFrame:AddMessage(ERR_GUILD_BANK_BOUND_ITEM, 1.0, 0.1, 0.1, 1.0)
  end

  local locked, moved, infoPending = false, false, false
  -- Move items if possible
  for _, item in ipairs(toMove) do
    local stackLimit = C_Item.GetItemMaxStackSizeByID(item.itemID)
    if stackLimit == nil then
      infoPending = true
      C_Item.RequestLoadItemDataByID(item.itemID)
    else
      local target, swapLocked = GetSwap(item, guildTargets, stackLimit)
      if target then
        C_Container.PickupContainerItem(item.bagID, item.slotID)
        SetCurrentGuildBankTab(target.tabIndex)
        PickupGuildBankItem(target.tabIndex, target.slotID)
        ClearCursor()
        moved = true
        break
      elseif swapLocked then
        locked = true
      end
    end
  end

  if moved then
    return addonTable.Constants.SortStatus.WaitingMove, modes
  elseif locked then
    return addonTable.Constants.SortStatus.WaitingUnlock, modes
  elseif infoPending then
    return addonTable.Constants.SortStatus.WaitingItemData, modes
  else
    if #toMove > 0 then
      UIErrorsFrame:AddMessage(addonTable.Locales.CANNOT_MOVE_ITEMS_AS_NO_SPACE_LEFT, 1.0, 0.1, 0.1, 1.0)
    end
    return addonTable.Constants.SortStatus.Complete, modes
  end
end
