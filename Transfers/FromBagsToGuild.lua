local _, addonTable = ...
local IsBagSlotLocked = addonTable.Transfers.IsContainerItemLocked

local function GetSwap(source, targets)
  if IsBagSlotLocked(source) then
    return nil, true
  end

  for index, item in ipairs(targets) do
    assert(item.itemID == nil)
    table.remove(targets, index)
    return item, false
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

  local oldCount = #toMove

  toMove = tFilter(toMove, function(item) return not item.isBound end, true)

  if #toMove ~= oldCount then
    UIErrorsFrame:AddMessage(ERR_GUILD_BANK_BOUND_ITEM, 1.0, 0.1, 0.1, 1.0)
  end

  local locked, moved = false, false
  -- Move items if possible
  for _, item in ipairs(toMove) do
    local target, swapLocked = GetSwap(item, guildTargets)
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

  if moved then
    return addonTable.Constants.SortStatus.WaitingMove, modes
  elseif locked then
    return addonTable.Constants.SortStatus.WaitingUnlock, modes
  else
    return addonTable.Constants.SortStatus.Complete, modes
  end
end
