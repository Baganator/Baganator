local always = {
  "quality",
  "quality-legacy",
  "type",
  "type-legacy",
  "combine_stacks_only",
}
function Baganator.Sorting.IsModeAvailable(mode)
  return tIndexOf(always, mode) ~= nil or
    (mode == "expansion" and (ItemVersion or Baganator.Constants.IsRetail)) or
    (mode == "blizzard" and (Baganator.Constants.IsRetail)) or
    (mode == "sortbags" and (IsAddOnLoaded("SortBags")))
end
