---@class addonTableBaganator
local addonTable = select(2, ...)
local IsGuildSlotLocked = addonTable.Transfers.IsGuildItemLocked

local function CheckFromTo(bagChecks, source, target)
  return not bagChecks.checks[target.bagID] or bagChecks.checks[target.bagID](source)
end

local function GetSwap(bagChecks, source, targets, stackLimit)
  if IsGuildSlotLocked(source) then
    return nil, true
  end

  for index, item in ipairs(targets) do
    if item.itemID == nil or (item.itemID == source.itemID and item.itemCount + source.itemCount <= stackLimit) then
      local outgoing = CheckFromTo(bagChecks, source, item)
      if outgoing then
        table.remove(targets, index)
        return item, false
      end
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
-- bagTargets: Slots for the items to move to (all empty)
function addonTable.Transfers.FromGuildToBags(toMove, bagIDs, bagTargets)
  if #toMove == 0 or InCombatLockdown() then -- Transfers breaks during combat due to Blizzard restrictions
    return addonTable.Constants.SortStatus.Complete
  end
  if Syndicator.API.IsBagEventPending() or Syndicator.API.IsGuildEventPending() then
    return addonTable.Constants.SortStatus.WaitingMove, modes
  end

  local tabsThatWork = {}
  for i = 1, GetNumGuildBankTabs() do
    local _, _, _, _, _, remainingWithdrawals = GetGuildBankTabInfo(i)
    if remainingWithdrawals == -1 or remainingWithdrawals > 0 then
      tabsThatWork[i] = true
    end
  end

  toMove = tFilter(toMove, function(item) return tabsThatWork[item.tabIndex] end, true)
  if #toMove == 0 then
    UIErrorsFrame:AddMessage(addonTable.Locales.CANNOT_WITHDRAW_ANY_MORE_ITEMS_FROM_THE_GUILD_BANK, 1.0, 0.1, 0.1, 1.0)
    return addonTable.Constants.SortStatus.Complete
  end

  local bagChecks = addonTable.Sorting.GetBagUsageChecks(bagIDs)

  -- Prioritise special bags
  bagTargets = addonTable.Transfers.SortChecksFirst(bagChecks, bagTargets)

  local locked, moved, infoPending = false, false, false
  -- Move items if possible
  for _, item in ipairs(toMove) do
    local stackLimit = C_Item.GetItemMaxStackSizeByID(item.itemID)
    if stackLimit == nil then
      infoPending = true
      C_Item.RequestLoadItemDataByID(item.itemID)
    else
      local target, swapLocked = GetSwap(bagChecks, item, bagTargets, stackLimit)
      if target then
        PickupGuildBankItem(item.tabIndex, item.slotID)
        C_Container.PickupContainerItem(target.bagID, target.slotID)
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
