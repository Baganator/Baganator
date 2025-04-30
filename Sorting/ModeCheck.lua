---@class addonTableBaganator
local addonTable = select(2, ...)

local always = {
  "quality",
  "type",
  "name",
  "item-level",
  "combine_stacks_only",
  "manual",
}
function addonTable.Sorting.IsModeAvailable(mode)
  return tIndexOf(always, mode) ~= nil or
    (mode == "expansion" and (ItemVersion or addonTable.Constants.IsRetail)) or
    addonTable.API.ExternalContainerSorts[mode]
end
