---@class addonTableBaganator
local addonTable = select(2, ...)

function addonTable.Skins.IsAddOnLoading(name)
  local character = UnitGUID("player")
  if C_AddOns.GetAddOnEnableState(name, character) ~= Enum.AddOnEnableState.All then
    return false
  end
  for _, dep in ipairs({C_AddOns.GetAddOnDependencies(name)}) do
    if not addonTable.Skins.IsAddOnLoading(dep) then
      return false
    end
  end
  return true
end
