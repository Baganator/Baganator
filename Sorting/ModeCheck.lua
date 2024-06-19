local _, addonTable = ...

local always = {
  "quality",
  "type",
  "combine_stacks_only",
}
function Baganator.Sorting.IsModeAvailable(mode)
  return tIndexOf(always, mode) ~= nil or
    (mode == "expansion" and (ItemVersion or Baganator.Constants.IsRetail)) or
    addonTable.ExternalContainerSorts[mode]
end
