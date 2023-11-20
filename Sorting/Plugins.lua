function Baganator.Sorting.BlizzardBagSort(reverse)
  C_Container.SetSortBagsRightToLeft(not reverse)
  C_Container.SortBags()
end

function Baganator.Sorting.BlizzardBankSort(reverse)
  C_Container.SetSortBagsRightToLeft(not reverse)
  C_Container.SortBankBags()
  C_Timer.After(1, function()
    C_Container.SortReagentBankBags()
  end)
end

function Baganator.Sorting.ExternalSortBags(reverse)
  SetSortBagsRightToLeft(not reverse)
  SortBags()
end

function Baganator.Sorting.ExternalSortBagsBank(reverse)
  SetSortBagsRightToLeft(not reverse)
  SortBankBags()
end
