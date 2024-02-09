function Baganator.Transfers.GetEmptySlots(bags, bagIDs)
  local emptySlots = {}
  for index, contents in ipairs(bags) do
    local bagID = bagIDs[index]
    for slotID, item in ipairs(contents) do
      if item.itemID == nil then
        table.insert(emptySlots, {
          bagID = bagID,
          slotID = slotID,
          itemID = nil,
        })
      end
    end
  end
  return emptySlots
end
