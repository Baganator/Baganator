function Baganator.Sorting.GetEmptySlots(bags, bagIDs)
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

function Baganator.Sorting.GetMergedBankBags(character)
  local characterData = BAGANATOR_DATA.Characters[character]

  local combined = CopyTable(characterData.bags)
  tAppendAll(combined, CopyTable(characterData.bank))
  local combinedIDs = CopyTable(Baganator.Constants.AllBagIndexes)
  tAppendAll(combinedIDs, Baganator.Constants.AllBankIndexes)

  return combined, combinedIDs
end
