local _, addonTable = ...
function addonTable.Transfers.AddToMail(toMove)
  if InCombatLockdown() then -- Transfers may not work during combat due to Blizzard restrictions
    return
  end

  SetSendMailShowing(true)

  local missing = false
  local attachmentIndex = 1

  -- Move items if possible
  for _, item in ipairs(toMove) do
    while select(2, GetSendMailItem(attachmentIndex)) do
      attachmentIndex = attachmentIndex + 1
    end
    if attachmentIndex > ATTACHMENTS_MAX_SEND then
      break
    end
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if not C_Item.DoesItemExist(location) then
      missing = true
    elseif not C_Item.IsLocked(location) then
      C_Container.UseContainerItem(item.bagID, item.slotID)
    end
  end

  if missing then
    return addonTable.Constants.SortStatus.WaitingMove
  else
    return addonTable.Constants.SortStatus.Complete
  end
end
